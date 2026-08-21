defmodule Kati.Background.Handoff do
  @moduledoc """
  The filesystem protocol between the BEAM and the Kotlin refresh worker.

  ## Why a filesystem and not a function call

  There is no function call to make. A `WorkManager` Worker cannot boot a
  headless BEAM — the JNI symbol is name-bound to `MainActivity`, `erl_start`
  never returns and ERTS is a per-process singleton, `mob_start_beam` polls
  `Activity.hasWindowFocus()` before starting (a Worker has no window), every
  plugin bridge is Activity-typed, and a *sleeping* BEAM costs 54-143 mAh/hr
  against ~50 ms of CPU for the same fetch in Kotlin. So the Worker runs alone,
  writes what it found, and the BEAM reads it on next foreground.

  The channel is verified rather than assumed: `mob_beam.zig:277-278` sets
  `MOB_DATA_DIR` to `getFilesDir()`, so `Mob.data_dir/0` here and
  `context.filesDir` there are the same directory.

  What does **not** work as a channel, so nobody retries it: `Mob.State` is
  `:dets` and Kotlin cannot write Erlang External Term Format; there is no
  `SharedPreferences` accessor from Elixir; and writing the SQLite database
  from Kotlin is rejected outright — Ash-owned tables written from outside the
  schema, no migration awareness, and a WAL-lock race against a live BEAM.

  ## Two directions, two shapes, and only one writer each

      kati_watchlist.json     BEAM → Worker   rewritten whole, atomically
      kati_inbox/<stamp>.json Worker → BEAM   one file per run, drained here

  Neither side ever edits a file the other owns. That is what removes the need
  for a lock between two things that can be alive at once — the BEAM lives
  inside `BeamForegroundService` while a Worker runs — and it is why the inbox
  is a *directory* rather than the single appended `kati_episode_inbox.json`
  the sketch proposed. Appending means read-modify-write, which means a lost
  update or a lock; one file per run means neither.

  ## Atomic means temp-then-rename, on the same filesystem

  Every write here goes to `<name>.tmp` and is renamed into place. A reader
  therefore sees a whole file or no file, never half of one — which matters
  because the reader is a different language with a different JSON parser and
  its failure mode for a truncated file is "the user follows nothing".

  ## The Worker never decides anything

  The watchlist is *precomputed*: it carries the last season and episode Kati
  has seen and nothing about what "seen" means. Every rule — what counts as
  watching, which shows are muted, how a Shamsi date is written, what the
  notification budget is — stays in Elixir, where it is tested. A domain rule
  that appears in the Kotlin worker exists in two languages, and two
  implementations of one rule disagree eventually.
  """

  @watchlist "kati_watchlist.json"

  @inbox "kati_inbox"

  @schema 1

  @type entry :: %{
          source: String.t(),
          source_id: String.t(),
          title: String.t() | nil,
          last_season: integer() | nil,
          last_episode: integer() | nil,
          etag: String.t() | nil
        }

  @type run :: %{
          at: DateTime.t(),
          outcome: String.t(),
          checked: non_neg_integer(),
          items: [map()]
        }

  @doc "Where both files live. `:dir` overrides it; only tests should."
  @spec dir(keyword()) :: Path.t()
  def dir(opts \\ []) do
    case Keyword.get(opts, :dir) do
      nil ->
        Mob.data_dir()

      dir when is_binary(dir) ->
        File.mkdir_p!(dir)
        dir
    end
  end

  @doc "Absolute path of the watchlist file."
  @spec watchlist_path(keyword()) :: Path.t()
  def watchlist_path(opts \\ []), do: Path.join(dir(opts), @watchlist)

  @doc "Absolute path of the inbox directory. Created if missing."
  @spec inbox_dir(keyword()) :: Path.t()
  def inbox_dir(opts \\ []) do
    path = Path.join(dir(opts), @inbox)
    File.mkdir_p!(path)
    path
  end

  @doc """
  Write the whole watchlist, atomically.

  Whole rather than incremental on purpose: the Worker has no merge logic and
  must not need any, and a rewrite of a few hundred rows is bytes. Call it on
  every follow/unfollow and on `{:mob_device, :did_enter_background}` — the
  last moment before the app may stop existing.

  Returns `{:ok, count}`.
  """
  @spec put_watchlist([entry()], keyword()) :: {:ok, non_neg_integer()} | {:error, File.posix()}
  def put_watchlist(entries, opts \\ []) when is_list(entries) do
    items = Enum.map(entries, &normalize_entry/1)

    body = %{
      "schema" => @schema,
      "written_at" => now(opts) |> DateTime.to_iso8601(),
      "items" => items
    }

    case write_atomic(watchlist_path(opts), encode(body)) do
      :ok -> {:ok, length(items)}
      {:error, posix} -> {:error, posix}
    end
  end

  @doc """
  Read the watchlist back. `[]` when it has never been written or cannot be
  parsed.

  A corrupt watchlist reads as empty rather than raising: it is a cache of a
  decision the database already holds, so the recovery is to write it again,
  not to take a screen down.
  """
  @spec watchlist(keyword()) :: [entry()]
  def watchlist(opts \\ []) do
    with {:ok, body} <- File.read(watchlist_path(opts)),
         {:ok, %{"items" => items}} <- decode(body),
         true <- is_list(items) do
      Enum.map(items, &atomize_entry/1)
    else
      _ -> []
    end
  end

  @doc """
  Read every run the Worker recorded, oldest first, and delete the files.

  This is the *refresh on open* net. Call it from `on_start/0` and from
  `handle_info({:mob_device, :did_become_active}, …)`.

  Files are deleted **after** they are read and only if they parsed, so a file
  that this build cannot understand — a newer Worker's schema, a truncated
  write — stays on disk rather than being silently thrown away. `stale/1`
  reports those.

  A `.tmp` file is ignored: it is a write in flight, or one that died mid-way.
  """
  @spec drain(keyword()) :: [run()]
  def drain(opts \\ []) do
    directory = inbox_dir(opts)

    directory
    |> inbox_files()
    |> Enum.map(&{&1, read_run(Path.join(directory, &1))})
    |> Enum.flat_map(fn
      {name, {:ok, run}} ->
        _ = File.rm(Path.join(directory, name))
        [run]

      {_name, :error} ->
        []
    end)
    |> Enum.sort_by(& &1.at, DateTime)
  end

  @doc """
  Inbox files this build could not read, newest name last.

  Empty is the normal answer. Anything in it is either a Worker newer than this
  BEAM or a genuinely corrupt write, and both are worth surfacing rather than
  deleting — deleting is how "notifications stopped working after the update"
  becomes unexplainable.
  """
  @spec stale(keyword()) :: [String.t()]
  def stale(opts \\ []) do
    directory = inbox_dir(opts)

    directory
    |> inbox_files()
    |> Enum.filter(&(read_run(Path.join(directory, &1)) == :error))
  end

  @doc """
  Write a run record the way the Worker does.

  Kati's Elixir never calls this in production — the Worker is the only writer
  of the inbox. It exists so `drain/1` can be tested against the exact bytes
  Kotlin produces rather than against a shape someone believed Kotlin produces,
  which is the failure this whole module is most exposed to: the two halves are
  in different languages and only one of them is in the test suite.

  Keep it identical to `KatiHandoff.record` in
  `android/app/src/main/java/com/example/kati/KatiRefreshWorker.kt`.
  """
  @spec record_run(run(), keyword()) :: {:ok, Path.t()} | {:error, File.posix()}
  def record_run(run, opts \\ []) do
    stamp = run.at |> DateTime.to_unix(:millisecond) |> Integer.to_string()
    path = Path.join(inbox_dir(opts), stamp <> ".json")

    body = %{
      "schema" => @schema,
      "run" => %{
        "at" => DateTime.to_unix(run.at, :millisecond),
        "outcome" => run.outcome,
        "checked" => run.checked,
        "items" => Map.get(run, :items, [])
      }
    }

    case write_atomic(path, encode(body)) do
      :ok -> {:ok, path}
      {:error, posix} -> {:error, posix}
    end
  end

  # ── internals ───────────────────────────────────────────────────────────

  defp inbox_files(directory) do
    directory
    |> File.ls!()
    |> Enum.filter(&String.ends_with?(&1, ".json"))
    |> Enum.sort()
  end

  defp read_run(path) do
    with {:ok, body} <- File.read(path),
         {:ok, %{"schema" => @schema, "run" => run}} <- decode(body),
         %{"at" => at} <- run,
         true <- is_integer(at),
         {:ok, moment} <- DateTime.from_unix(at, :millisecond) do
      {:ok,
       %{
         at: moment,
         outcome: Map.get(run, "outcome", "unknown"),
         checked: Map.get(run, "checked", 0),
         items: List.wrap(Map.get(run, "items", []))
       }}
    else
      _ -> :error
    end
  end

  # Nil-valued keys are dropped rather than written, because Erlang's
  # `:json.encode/1` renders the atom `nil` as the STRING "nil" — only `:null`
  # becomes JSON null. A show with no known last episode would arrive in Kotlin
  # as `last_episode: "nil"`, which `optInt` reads as its default and
  # `optString` reads as a title. An absent key is unambiguous in both
  # languages: `optString`/`optInt` fall back, and `item["title"]` here is nil.
  defp normalize_entry(entry) do
    %{
      "source" => to_string(fetch(entry, :source)),
      "source_id" => to_string(fetch(entry, :source_id)),
      "title" => fetch(entry, :title),
      "last_season" => fetch(entry, :last_season),
      "last_episode" => fetch(entry, :last_episode),
      "etag" => fetch(entry, :etag)
    }
    |> Map.reject(fn {_key, value} -> is_nil(value) end)
  end

  defp atomize_entry(item) when is_map(item) do
    %{
      source: item["source"],
      source_id: item["source_id"],
      title: item["title"],
      last_season: item["last_season"],
      last_episode: item["last_episode"],
      etag: item["etag"]
    }
  end

  defp fetch(entry, key) when is_map(entry) do
    Map.get(entry, key, Map.get(entry, Atom.to_string(key)))
  end

  defp encode(body), do: IO.iodata_to_binary(:json.encode(body))

  defp decode(body) do
    {:ok, :json.decode(body)}
  rescue
    _ -> :error
  end

  defp now(opts), do: Keyword.get(opts, :now, DateTime.utc_now())

  # Rename is atomic within a filesystem, so a reader sees the whole file or no
  # file. The temp name sits in the same directory for exactly that reason —
  # across filesystems `File.rename/2` degrades to a copy, which is not atomic.
  defp write_atomic(path, body) do
    tmp = path <> ".tmp"

    with :ok <- File.write(tmp, body),
         :ok <- File.rename(tmp, path) do
      :ok
    else
      {:error, posix} ->
        _ = File.rm(tmp)
        {:error, posix}
    end
  end
end
