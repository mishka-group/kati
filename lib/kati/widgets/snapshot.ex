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

  ## What the hero carries

    * `title` and `meta` — the two lines screen 10's hero card draws.
    * `poster` — the **downloaded** poster's absolute path, from
      `Kati.Media.Artwork.local/2`, and only while that file is on this
      device. Never a design seed and never a CDN URL: the widget cannot
      fetch, and a sample photograph standing in for somebody's own title is
      the fabrication the no-dummy-data rule forbids. No file, no key, no
      picture.
    * `id` and `kind` — which title a tap opens. `Kati.Widgets.Launch`
      reads them back off the tap.

  ## The empty state's words

  `empty` carries the two lines the widget draws when there is no hero, in
  the reader's own language. The widget is drawn by the launcher, which
  knows the SYSTEM locale, and Kati's language is chosen inside Kati — so the
  translation is done here, where `Kati.Locale` is, and the Kotlin string
  resources are only the fallback for a widget placed before Kati has ever
  written this file.

  ## Who writes it

  `Kati.Widgets.Refresher`, and nothing else: the writes that change the hero
  poke it (see `Kati.Widgets.Notifier`), and it is the one process that calls
  `refresh/1` — so two writers can never race on the same `.tmp` file.
  """

  use Gettext, backend: Kati.Gettext

  @snapshot_file "kati_widget.json"

  @schema 2

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
  The same holds inside the hero: a title with no downloaded poster has no
  `"poster"` key at all.
  """
  @spec put(map() | nil, keyword()) :: :ok | {:error, File.posix()}
  def put(hero, opts \\ []) do
    body =
      drop_nils(%{
        "schema" => @schema,
        "written_at" => DateTime.to_iso8601(DateTime.utc_now()),
        "hero" => hero && hero_json(hero),
        "empty" => empty_json()
      })

    write_atomic(path(opts), IO.iodata_to_binary(:json.encode(body)))
  end

  @doc """
  Recompute and write the current hero from the real shelf.

  Activates the reader's language first: gettext's locale is per process,
  and both the hero's second line — `S1 · E2`, `FILM · 2024` — and the empty
  state's words are translated.
  """
  @spec refresh(keyword()) :: :ok | {:error, File.posix()}
  def refresh(opts \\ []) do
    Kati.Locale.activate()

    hero =
      case Kati.Screens.UpNext.queue() do
        %{hero: %{} = hero} -> hero
        _no_hero -> nil
      end

    put(hero, opts)
  end

  @doc """
  The downloaded poster for a hero's `seed`, or `nil`.

  Only `Kati.Media.Artwork.local/2`: a TMDB path with a file already on this
  device. A design seed answers `nil` here on purpose — see the moduledoc.
  """
  @spec poster(term()) :: String.t() | nil
  def poster(seed), do: Kati.Media.Artwork.local(seed, :poster)

  defp hero_json(hero) do
    drop_nils(%{
      "title" => hero.title,
      "meta" => hero.meta,
      "poster" => poster(Map.get(hero, :seed)),
      "id" => Map.get(hero, :id),
      "kind" => kind(Map.get(hero, :kind))
    })
  end

  defp empty_json do
    %{"title" => gettext("Nothing queued"), "action" => gettext("Add a title")}
  end

  defp kind(kind) when is_atom(kind) and not is_nil(kind), do: Atom.to_string(kind)
  defp kind(_unknown), do: nil

  defp drop_nils(map), do: Map.reject(map, fn {_key, value} -> is_nil(value) end)

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
