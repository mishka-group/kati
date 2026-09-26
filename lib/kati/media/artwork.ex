defmodule Kati.Media.Artwork do
  @moduledoc """
  The picture of a title, from wherever that title came from.

  ## Why this exists

  `Kati.Design.Images` holds the design's own photographs, named by **seed** —
  `hollow71` is The Long Hollow — and every screen in the app asks it for a
  poster. That was right for as long as every title on the shelf was one the
  design had drawn.

  It stopped being right the day screen 06 could add a real one. TMDB answers
  with a `poster_path` like `/kBf3g9crrADGMc2AMAMlLBgSm2h.jpg`, which is a path
  on TMDB's image CDN and not a seed; `Kati.Design.Images.path/2` looked for a
  file called `/kBf3g9crrADGMc2AMAMlLBgSm2h.jpg_400x600.jpg` in `priv/`, did not
  find it, and answered `nil`. Every screen then drew its grey placeholder. So
  **every title a user actually added was a grey rectangle, everywhere in the
  app** — Home's Continue watching, the Library grid, Up next, New releases,
  Discover, the film page's hero. Found by adding *Blade Runner* on a Pixel 9a
  and looking at the shelf.

  ## The split this module makes

  Rendering cannot do IO — `render/1` runs on every frame and a screen that
  blocks on a download is a screen that does not draw — so the two halves are
  deliberately separate:

    * `local/2` is **pure**: it answers with a file already on disk, or `nil`.
      Screens call this, through `Kati.Design.Images`, and never know the
      difference between a seed and a CDN path.
    * `cache/1` does the **network**, once, at the moment a title is added. It
      is the only function here that can be slow and the only one that can
      fail, and a failure is not an error the user should see: a poster that
      did not download is a grey card, which is exactly what the app drew
      before this module existed.

  ## Where the files go, and why not `priv/`

  `priv/` is inside the application bundle and is read-only on a device.
  Downloads go to `Mob.data_dir()/artwork`, which is the writable directory the
  database already lives in, under a name derived from the CDN path — so the
  same poster is fetched once per device and survives restarts.

  ## The size, decided once

  `w342` for posters and `w780` for the wide crops. TMDB serves a fixed ladder
  of widths and the app draws posters at 400x600 or smaller; `w342` is the
  first rung above that, so it is sharp on a 3x screen without paying for
  `original` on a phone that will never show the difference.
  """

  require Logger

  @host "https://image.tmdb.org/t/p"
  @dns_host "image.tmdb.org"
  @poster_width "w342"
  @wide_width "w780"
  @timeout 10_000

  @doc """
  Whether `value` is a CDN path rather than one of the design's seeds.

  TMDB paths start with `/` and seeds never do, which is the whole test — and
  it is a test on the SHAPE of the value rather than on a flag beside it,
  because the value arrives on `Kati.Media.CachedTitle.poster_path` from two
  sources that do not agree about what belongs in it.

      iex> Kati.Media.Artwork.remote?("/kBf3g9crrADGMc2AMAMlLBgSm2h.jpg")
      true

      iex> Kati.Media.Artwork.remote?("hollow71")
      false

      iex> Kati.Media.Artwork.remote?(nil)
      false
  """
  @spec remote?(term()) :: boolean()
  def remote?(value) when is_binary(value), do: String.starts_with?(value, "/")
  def remote?(_other), do: false

  @doc """
  The downloaded file for `path`, if this device already has it. Never fetches.

  `size` is `:poster` or `:wide`. A caller that has no business knowing about
  CDNs gets `nil` here and draws its placeholder, which is the same answer it
  got before any of this existed.
  """
  @spec local(term(), :poster | :wide) :: String.t() | nil
  def local(path, size \\ :poster)

  def local(path, size) when is_binary(path) do
    if remote?(path) do
      file = file_for(path, size)
      if File.exists?(file), do: file, else: nil
    end
  end

  def local(_other, _size), do: nil

  @doc """
  TMDB's own small thumbnail for `path`, for a row that is only being looked at.

  Screen 06's results are titles nobody has added, so `cache/1` has not run for
  them and `local/2` answers `nil` — which drew seventeen grey rectangles for
  *arrival*. Downloading each one to disk would keep files for titles the
  reader was only browsing. The bridge loads an `https` `src` itself (Coil), so
  the row points at the CDN and nothing is written.

  `w154`: the row draws 44x62, which is 132x186 at 3x, and `w154` is the first
  rung of TMDB's ladder above that.

      iex> Kati.Media.Artwork.thumbnail("/kBf3g9crrADGMc2AMAMlLBgSm2h.jpg")
      "https://image.tmdb.org/t/p/w154/kBf3g9crrADGMc2AMAMlLBgSm2h.jpg"

      iex> Kati.Media.Artwork.thumbnail("hollow71")
      nil

      iex> Kati.Media.Artwork.thumbnail(nil)
      nil
  """
  @spec thumbnail(term()) :: String.t() | nil
  def thumbnail(path) do
    if remote?(path), do: @host <> "/w154" <> path
  end

  @doc """
  Fetch and store the poster for `path`, unless this device already has it.

  Called once, when a title is added — see `Kati.Screens.AddTitle.track/2`.
  Answers `{:ok, file}` or `{:error, reason}`, and **the caller is expected to
  ignore the error**: a title with no picture is a title, and refusing to add
  one because its poster did not download would be the network deciding what is
  on somebody's shelf.

  Both sizes are fetched, because the poster and the hero crop are drawn by
  different screens and a second trip at hero time would be a blank header on
  the one screen that is mostly header.
  """
  @spec cache(term()) :: {:ok, String.t()} | {:error, term()}
  def cache(path) when is_binary(path) do
    if remote?(path) do
      _wide = download(path, :wide)
      download(path, :poster)
    else
      {:error, :not_remote}
    end
  end

  def cache(_other), do: {:error, :not_remote}

  @doc "Every artwork file this device has downloaded, for a cache-size line."
  @spec files() :: [String.t()]
  def files do
    dir() |> Path.join("*") |> Path.wildcard()
  rescue
    _error -> []
  end

  @doc "Forget every downloaded poster. Paired with the metadata cache's Clear."
  @spec clear() :: :ok
  def clear do
    Enum.each(files(), &File.rm/1)
    :ok
  rescue
    _error -> :ok
  end

  defp download(path, size) do
    file = file_for(path, size)

    if File.exists?(file) do
      {:ok, file}
    else
      with :ok <- File.mkdir_p(dir()),
           {:ok, body} <- get(url(path, size)),
           :ok <- File.write(file, body) do
        arrived(size)
        {:ok, file}
      else
        other ->
          Logger.info("artwork #{path} #{size}: #{inspect(other)}")
          {:error, other}
      end
    end
  end

  # A poster that has just landed may be the one the home-screen widget is
  # showing without a picture: the widget only ever draws a file that is on
  # the device (`Kati.Widgets.Snapshot`), and a title is tracked BEFORE its
  # poster finishes downloading, so the snapshot written for the add has none.
  defp arrived(:poster), do: Kati.Widgets.Notifier.poke()
  defp arrived(_wide), do: :ok

  # The same two preparations `Kati.Media.Tmdb.get/3` makes, and for the same
  # reasons: the pure-BEAM TLS stack needs its CA bundle wired up, and Android's
  # resolver lives behind a Java API that `:inet_res` cannot reach, so the
  # platform NIF has to seed `:inet_db` before Finch looks in it. Neither is
  # optional on a device and both are no-ops on the host.
  defp get(url) do
    Kati.Net.Tls.ensure!()
    _resolved = Kati.Net.Dns.resolve(@dns_host)

    case Req.get(url: url, receive_timeout: @timeout, max_redirects: 3) do
      {:ok, %{status: 200, body: body}} when is_binary(body) and byte_size(body) > 0 ->
        {:ok, body}

      {:ok, %{status: status}} ->
        {:error, {:status, status}}

      {:error, reason} ->
        {:error, reason}
    end
  rescue
    error -> {:error, error}
  end

  defp url(path, size), do: @host <> "/" <> width(size) <> path

  defp width(:wide), do: @wide_width
  defp width(_poster), do: @poster_width

  # `/abc123.jpg` becomes `abc123_w342.jpg`. The leading slash is dropped and
  # nothing else is: TMDB paths are already a flat namespace of opaque names, so
  # there is no directory to recreate and no name to collide with.
  defp file_for(path, size) do
    name = path |> String.trim_leading("/") |> String.replace("/", "_")
    Path.join(dir(), width(size) <> "_" <> name)
  end

  defp dir, do: Path.join(Mob.data_dir(), "artwork")
end
