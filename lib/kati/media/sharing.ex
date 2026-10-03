defmodule Kati.Media.Sharing do
  @moduledoc """
  What *Share* sends for a film, a show or an anime (#123).

  Three things, so the app it lands in can show more than a name:

    * **the title**, with its year, and where it streams when Kati knows;
    * **a link** to the title's own page at the source it came from — TMDB,
      AniList or TVmaze — which is what Telegram, WhatsApp and the rest turn
      into a preview card with the poster;
    * **the poster**, attached as an image with the text as its caption, when
      Kati has it on the phone. Without one the text goes alone, and the link
      still brings the preview.
  """
  use Gettext, backend: Kati.Gettext

  @doc """
  The title's own page on the web, or `nil` when no source has one.

      iex> Kati.Media.Sharing.link(%{source: :tmdb, source_id: "438631", kind: :movie})
      "https://www.themoviedb.org/movie/438631"
      iex> Kati.Media.Sharing.link(%{source: :tmdb, source_id: "1399", kind: :tv})
      "https://www.themoviedb.org/tv/1399"
      iex> Kati.Media.Sharing.link(%{source: :anilist, source_id: "21", kind: :anime})
      "https://anilist.co/anime/21"
      iex> Kati.Media.Sharing.link(%{source: :tvmaze, source_id: "82", kind: :tv})
      "https://www.tvmaze.com/shows/82"
      iex> Kati.Media.Sharing.link(%{source: :manual, source_id: "Low Water", kind: :movie, tmdb_id: nil})
      nil
  """
  @spec link(map() | nil) :: String.t() | nil
  def link(%{source: :tmdb, source_id: id, kind: :movie}) when is_binary(id),
    do: "https://www.themoviedb.org/movie/" <> id

  def link(%{source: :tmdb, source_id: id}) when is_binary(id),
    do: "https://www.themoviedb.org/tv/" <> id

  def link(%{source: :anilist, source_id: id}) when is_binary(id),
    do: "https://anilist.co/anime/" <> id

  def link(%{source: :tvmaze, source_id: id}) when is_binary(id),
    do: "https://www.tvmaze.com/shows/" <> id

  def link(%{} = title), do: Kati.Media.Sharing.cross_link(title)
  def link(_none), do: nil

  @doc false
  def cross_link(%{tmdb_id: id, kind: :movie}) when is_binary(id) and id != "",
    do: "https://www.themoviedb.org/movie/" <> id

  def cross_link(%{tmdb_id: id}) when is_binary(id) and id != "",
    do: "https://www.themoviedb.org/tv/" <> id

  def cross_link(%{anilist_id: id}) when is_binary(id) and id != "",
    do: "https://anilist.co/anime/" <> id

  def cross_link(%{tvmaze_id: id}) when is_binary(id) and id != "",
    do: "https://www.tvmaze.com/shows/" <> id

  def cross_link(%{imdb_id: "tt" <> _ = id}), do: "https://www.imdb.com/title/" <> id
  def cross_link(_none), do: nil

  @doc """
  The message: a title line, where it streams, and the link — each line only
  when there is something true to put on it.

      iex> Kati.Media.Sharing.message("Dune (2021)", "On Netflix", "https://www.themoviedb.org/movie/438631")
      "Dune (2021)\\nOn Netflix\\nhttps://www.themoviedb.org/movie/438631"
      iex> Kati.Media.Sharing.message("Dark", nil, nil)
      "Dark"
  """
  @spec message(String.t(), String.t() | nil, String.t() | nil) :: String.t()
  def message(title_line, where, link) do
    [title_line, where, link]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join("\n")
  end

  @doc """
  Open the share sheet: the poster with the message as its caption when the
  poster is on the phone, the message alone otherwise.
  """
  @spec share(Mob.Socket.t(), String.t(), String.t() | nil) :: Mob.Socket.t()
  def share(socket, message, seed) do
    case Kati.Media.Sharing.poster_file(seed) do
      nil ->
        Kati.Media.Sharing.text(socket, message)

      path ->
        case Kati.Native.Files.share(path,
               mime: "image/jpeg",
               name: "kati-poster.jpg",
               subject: message |> String.split("\n") |> hd(),
               text: message
             ) do
          :ok -> socket
          {:error, _reason} -> Kati.Media.Sharing.text(socket, message)
        end
    end
  end

  @doc false
  def text(socket, message) do
    Mob.Share.text(socket, message)
  rescue
    _no_bridge -> socket
  end

  @doc """
  The message and poster for a tracked title, read from the store: its name
  and year, where it streams in the reader's region, and its link. `nil` when
  the id names no title.
  """
  @spec for_title(String.t() | nil) :: {String.t(), String.t() | nil} | nil
  def for_title(id) when is_binary(id) do
    with {:ok, tracked} <- Ash.get(Kati.Media.TrackedTitle, id) do
      cached = Kati.Media.Release.cached_for(tracked)

      name =
        case cached do
          %{title: title} when is_binary(title) and title != "" -> title
          _none -> tracked.source_id
        end

      year =
        case cached do
          %{first_release_year: y} when is_integer(y) -> " (" <> Integer.to_string(y) <> ")"
          _none -> ""
        end

      where = Kati.Screens.Film.where_line(Kati.Screens.SeriesMeta.where_rows(cached))
      link = Kati.Media.Sharing.link(cached || tracked)

      {Kati.Media.Sharing.message(name <> year, where, link), cached && cached.poster_path}
    else
      _gone -> nil
    end
  rescue
    _error -> nil
  end

  def for_title(_none), do: nil

  @doc "The poster's file on the phone, or `nil` when it is not there."
  @spec poster_file(String.t() | nil) :: Path.t() | nil
  def poster_file(seed) when is_binary(seed), do: Kati.Media.Artwork.local(seed)
  def poster_file(_none), do: nil
end
