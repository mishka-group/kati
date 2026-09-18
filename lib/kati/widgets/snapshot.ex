defmodule Kati.Widgets.Snapshot do
  @moduledoc """
  The BEAM-to-Kotlin handoff for the home-screen widget.

  Same reasoning as `Kati.Background.Handoff`, same channel: the widget
  runs in the launcher's process, not Kati's, and cannot boot a headless
  BEAM to ask a question live. It reads a plain JSON file the BEAM writes
  into `Mob.data_dir/0` — `context.filesDir` on the Kotlin side — atomically,
  temp-then-rename.

  What the file holds is `Kati.Screens.UpNext.queue/0`'s own hero, or
  `nil` when the reader has nothing on the go — the same honest "nothing
  queued" state screen 10 draws now rather than a specimen title. A widget
  is a smaller, more permanent version of a screen; it does not get a
  looser rule than the one just applied to the screen it mirrors.
  """

  @snapshot_file "kati_widget.json"

  @schema 1

  @doc "Absolute path of the snapshot file. `:dir` overrides it; only tests should."
  @spec path(keyword()) :: Path.t()
  def path(opts \\ []) do
    dir = Keyword.get(opts, :dir, Mob.data_dir())
    Path.join(dir, @snapshot_file)
  end

  @doc """
  Write the current "continue watching" hero, atomically.

  `nil` writes a snapshot with no `"hero"` key rather than leaving a stale
  file in place — a reader who finishes their last show should see the
  widget say so, not keep showing what they finished. The key is dropped
  rather than set to an explicit JSON null: `:json.encode/1` renders the
  atom `nil` as the string `"nil"`, the same pitfall `Kati.Background.
  Handoff` and `Kati.Notifications.Delivery.Android` already document, and
  an absent key reads identically to `null` on the Kotlin side either way.
  """
  @spec put(map() | nil, keyword()) :: :ok | {:error, File.posix()}
  def put(hero, opts \\ []) do
    body =
      %{
        "schema" => @schema,
        "written_at" => DateTime.to_iso8601(DateTime.utc_now()),
        "hero" => hero && %{"title" => hero.title, "meta" => hero.meta}
      }
      |> Map.reject(fn {_key, value} -> is_nil(value) end)

    write_atomic(path(opts), IO.iodata_to_binary(:json.encode(body)))
  end

  @doc "Recompute and write the current hero from the real shelf."
  @spec refresh(keyword()) :: :ok | {:error, File.posix()}
  def refresh(opts \\ []) do
    hero =
      case Kati.Screens.UpNext.queue() do
        %{hero: %{} = hero} -> hero
        _no_hero -> nil
      end

    put(hero, opts)
  end

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
