defmodule Kati.Screens.ArtistDetail do
  @moduledoc """
  Screen 77 — an artist, pushed under an album.

  ## The `Following` toggle is the page

  Everything else here is a report; this is the one control, and the design's
  caption is unusually precise about what it may and may not do:

  > The `Following` toggle is the single source of truth for 21's new-releases
  > band and, of 25's six alert types, drives `People you follow` only —
  > premieres stay a separate opt-in so following an artist cannot silently turn
  > on push.

  That last clause is a rule about consent, not about wiring. Following somebody
  is a statement about a shelf. A premiere alert is a statement about a
  notification. Joining them would make a tap on this toggle quietly arm push,
  and the row's own sub-line says which of the two it is doing so the user is
  never guessing.

  ## Four albums, twice, and both cap at four

  The rail and the chart show the same albums, and the caption caps both: *the
  rail and chart both cap at four albums; beyond that the rail scrolls and the
  chart truncates with a count*. A chart that grows without limit stops being a
  comparison, so the truncation is the feature.

  ## Orange appears once

  On the unheard-release card, and nowhere else on the page. That is the
  palette's own rule — one accent per screen — and here it is doing real work:
  the card is the only thing on the page that is *new*.
  """

  use Kati.Screens.Pushed, back: "Album"

  alias Kati.Music.Album
  alias Kati.Music.Artist
  alias Kati.Music.Listen
  alias Kati.Music.Sample
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  # The cap the caption names, applied in one place so the rail and the chart
  # cannot disagree about it.
  @cap 4

  def load(socket) do
    id = Map.get(socket.assigns.params || %{}, :artist_id)

    socket
    |> Mob.Socket.assign(:artist_id, id)
    |> Mob.Socket.assign(:artist, artist(id))
    |> Mob.Socket.assign(:dismissed?, false)
  end

  @doc """
  The params that name an artist to this screen, built from a shaped album.

  Here rather than at each caller so the key is spelled once — screens 74 and 76
  both open this page off an album row, exactly as
  `Kati.Screens.LogListen.params_for/1` spells `:album_id` for the sheet on the
  other side of this page. `Kati.Screens.AlbumDetail.shaped/4` carries
  `:artist_id`; the drawing does not, and an album with no artist — or no album
  at all — yields `%{}`, which is the no-id mount every sweep renders.

  Not the artist's NAME, which is the other thing screen 74 has in hand: two
  people can share one, and a page routed on a name would be right until the
  day it was silently wrong.
  """
  @spec params_for(map() | nil) :: map()
  def params_for(%{artist_id: id}) when is_binary(id), do: %{artist_id: id}
  def params_for(_album), do: %{}

  @doc """
  The artist a write on this screen must act on.

  The id the push NAMED, when it named one, and otherwise the id of the artist
  that was resolved — the shelf album's, which is who a page opened from
  nowhere in particular is about. `Map.get/2` on both, because the Persian twin
  builds its own socket and need not carry `:artist_id`.

  Copied from `Kati.Screens.BookDetail.target/1`. `artist/1` collapses two
  facts into one value — *nobody named an artist* and *the named artist is
  gone* both answer `Kati.Music.Sample.artist/0`, which has no id — so a write
  recovering its subject from the drawn map would get `nil` for both, and `nil`
  down at `stored/1` means *the shelf album's artist*. `Following` is one tap
  and it is a statement about a shelf and an alert type, so a page drawing the
  fixture would have followed, or unfollowed, a real person the reader is not
  looking at.

  It also pins the resolved case to the RENDER. This used to read
  `stored(assigns[:artist_id])` at tap time, which re-ran the shelf query: with
  no id named, the artist written to was whoever headed the shelf when the
  finger landed rather than whoever the page had drawn. Screen 20's
  `open_book/2` states the same rule for the same reason.
  """
  @spec target(map()) :: String.t() | nil
  def target(assigns) do
    Map.get(assigns, :artist_id) || Map.get(assigns, :artist, %{})[:id]
  end

  @doc "The artist this screen is about: the shelf album's, or the drawing's."
  @spec artist() :: map()
  def artist, do: artist(nil)

  @doc """
  One artist by id, shaped — the shelf album's artist when no id is named.

  `Kati.Screens.AlbumDetail.album/1`'s shape, on the other side of the artist
  row. An id that names no row answers the drawing rather than somebody else,
  which is `Kati.Screens.AlbumDetail.shelved_album/1`'s rule and is the half of
  it that matters.
  """
  @spec artist(String.t() | nil) :: map()
  def artist(id), do: stored_artist(id) || Sample.artist()

  @doc "The drawing's values, unconditionally."
  @spec drawn_artist() :: map()
  def drawn_artist, do: Sample.artist()

  @doc "The albums, capped — see the moduledoc. The no-id answer."
  @spec albums() :: [map()]
  def albums, do: albums(nil)

  @doc "One artist's albums, capped."
  @spec albums(String.t() | nil) :: [map()]
  def albums(id) do
    case stored(id) do
      nil -> Enum.take(Sample.artist_albums(), @cap)
      %Artist{} = artist -> artist |> stored_albums() |> Enum.take(@cap)
    end
  end

  @doc "How many albums were left out of the cap. Zero when none were."
  @spec truncated() :: non_neg_integer()
  def truncated, do: truncated(nil)

  @doc """
  The same count, about the named artist.

  It takes the id for a reason worth stating: this number and `albums/1` are two
  reads of one list, and a page that showed one artist's three tiles over
  another artist's *and 1 more* would be a new defect introduced by half-fixing
  the old one.
  """
  @spec truncated(String.t() | nil) :: non_neg_integer()
  def truncated(id) do
    total =
      case stored(id) do
        nil -> length(Sample.artist_albums())
        %Artist{} = artist -> length(stored_albums(artist))
      end

    max(total - @cap, 0)
  end

  @doc "The shaped artist, or `nil` when nothing is stored."
  @spec stored_artist() :: map() | nil
  def stored_artist, do: stored_artist(nil)

  @doc """
  One shaped artist by id, or `nil` — the shelf album's when no id is named.

  An id that names no row answers `nil` rather than the shelf's artist, exactly
  as `Kati.Screens.AlbumDetail.shelved_album/1` does: a record deleted under
  you is not the same fact as an empty shelf.
  """
  @spec stored_artist(String.t() | nil) :: map() | nil
  def stored_artist(id) do
    case stored(id) do
      nil -> nil
      %Artist{} = artist -> shaped(artist, stored_albums(artist))
    end
  end

  # The artist this page is about. Handed nothing, the artist of the shelf's
  # first album, which is the artist you would have arrived here from. Not
  # "the first artist in the table": this screen is pushed from screen 74 and
  # must be about the same record.
  #
  # Two clauses, in `Kati.Screens.AlbumDetail.shelved/1`'s order and for its
  # reason: an id that names no row answers `nil` rather than falling back to
  # the shelf's head, because substituting a different person is precisely the
  # swap the id was added to stop.
  defp stored(nil) do
    with {:ok, [%Album{artist_id: id} | _rest]} when not is_nil(id) <-
           Ash.read(Album, action: :shelf),
         {:ok, artist} <- Ash.get(Artist, id) do
      artist
    else
      _other -> nil
    end
  rescue
    _error -> nil
  end

  defp stored(id) when is_binary(id) do
    case Ash.get(Artist, id) do
      {:ok, %Artist{} = artist} -> artist
      _other -> nil
    end
  rescue
    _error -> nil
  end

  defp stored_albums(%Artist{id: id}) do
    Album
    |> Ash.Query.for_read(:for_artist, %{artist_id: id})
    |> Ash.read()
    |> case do
      {:ok, albums} -> Enum.map(albums, &shape_album/1)
      _other -> []
    end
  rescue
    _error -> []
  end

  @doc "One artist plus their albums, as the render wants them. Pure."
  @spec shaped(Artist.t(), [map()]) :: map()
  def shaped(%Artist{} = artist, albums) do
    minutes = Enum.sum(Enum.map(albums, & &1.minutes))

    %{
      # The row's own id, so `target/1` can name the person this page drew
      # without asking the shelf a second time. `Kati.Music.Sample.artist/0` has
      # no id and is not given a `nil` one, so `artist[:id]` reads `nil` by
      # absence and a write on a drawn page has nothing to reach.
      id: artist.id,
      name: artist.name,
      subtitle: Artist.subtitle(artist),
      photo_seed: artist.photo_seed,
      following: artist.following,
      following_note: "Feeds 21’s new-releases band and 25’s alerts",
      hours: Listen.hours_label(minutes),
      first_heard: artist.first_heard_on && Integer.to_string(artist.first_heard_on.year),
      album_count: Integer.to_string(length(albums))
    }
  end

  defp shape_album(%Album{} = album) do
    # Screen 74's own count, not a second sum here — see
    # `Kati.Screens.AlbumDetail.play_count/1`. The rail, the page it opens and
    # screen 21's tile all print this number, one tap apart.
    tracks = Kati.Screens.AlbumDetail.tracks_of(album)
    plays = Album.plays(tracks)

    %{
      # The row's own id, so a rail row can name the record it draws instead of
      # leaving screen 74 to re-read the shelf and take its head. The rail's TAG
      # cannot do it: `album_tag/1` is built from title and year because the
      # drawing's four rows carry `seed: nil`, and that makes it an
      # accessibility identity, not a database one. `Kati.Music.Sample`'s rows
      # have no id and are not given a `nil` one, so `row[:id]` reads `nil` by
      # absence and screen 74 falls back.
      id: album.id,
      title: album.title,
      year: album.released_year,
      plays: plays,
      line: album_line(album.released_year, plays),
      seed: album.art_seed,
      # Not drawn. `unheard_albums/1` reads it to tell *nobody has played this*
      # from *the app knows no tracks to play* — a hand-typed album sums to zero
      # plays for the second reason and is not unheard. See there.
      track_count: length(tracks),
      minutes: 0
    }
  end

  # `2025 · 41 plays`, or the one word the drawing uses for a record you have
  # never played: `Unheard`. Not `0 plays` — the count is not the point, the
  # fact that you have not heard it is, and it is the fact the unheard card
  # further down acts on.
  defp album_line(_year, 0), do: "Unheard"

  defp album_line(nil, plays), do: "#{plays} #{if plays == 1, do: "play", else: "plays"}"

  defp album_line(year, plays),
    do: "#{year} · #{plays} #{if plays == 1, do: "play", else: "plays"}"

  @doc false
  def content(assigns) do
    a = assigns.artist
    # The NAMED artist, for the reason `Kati.Screens.AlbumDetail.content/1`
    # keeps `:album_id`: an id whose row has been deleted draws the drawing,
    # which has no id, and re-deriving from `a` there would send the rail back
    # to the shelf head's discography under this page's title.
    id = assigns.artist_id

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {SettingsList.chrome(nil, 44)}
        {Kati.Screens.ArtistDetail.hero(a)}
        {Kati.Screens.ArtistDetail.following_row(a)}
        {UI.eyebrow(Kati.Screens.ArtistDetail.albums_label(id))}
        {Kati.Screens.ArtistDetail.rail(id)}
        {UI.eyebrow("Plays by album")}
        {Kati.Screens.ArtistDetail.chart(id)}
        {Kati.Screens.ArtistDetail.unheard(assigns.dismissed?, id)}
        {UI.eyebrow("Totals")}
        {Kati.Screens.ArtistDetail.totals(a)}
      </Column>
    </Scroll>
    """
  end

  @doc "The photograph, the name, and the one line under it."
  @spec hero(map()) :: map()
  def hero(a) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        {Kati.Screens.ArtistDetail.photo(a)}
        <Spacer size={15} />
        <Column weight={1.0}>
          <Text
            text={a.name}
            text_size={26}
            font_weight="bold"
            letter_spacing={-0.03}
            text_color={:on_surface}
            max_lines={2}
          />
          <Spacer size={6} />
          <Text text={a.subtitle || ""} text_size={13.5} text_color={Palette.muted()} max_lines={1} />
        </Column>
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc false
  def photo(a) do
    case Kati.Design.Images.poster(a.photo_seed) do
      nil ->
        ~MOB"""
        <Box width={76} height={76} corner_radius={38} background={Palette.placeholder()} />
        """

      src ->
        ~MOB"""
        <Image src={src} width={76} height={76} corner_radius={38} content_mode="fill" />
        """
    end
  end

  @doc """
  The one control, with the sentence that says exactly what it turns on.

  The sub-line is not decoration. A switch whose consequence is invisible is a
  switch the user has to test to understand, and the thing being tested here is
  a notification.
  """
  @spec following_row(map()) :: map()
  def following_row(a) do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.card([
        Kati.UI.SettingsList.row(
          Kati.UI.SettingsList.icon_tile("notifications"),
          Kati.UI.SettingsList.body("Following", a.following_note, lines: 2),
          Kati.UI.SettingsList.trailing(Kati.UI.SettingsList.switch(a.following)),
          on_tap: {self(), :toggle_following}
        )
      ])}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc "The albums eyebrow, carrying the real count. The no-id answer."
  @spec albums_label() :: String.t()
  def albums_label, do: albums_label(nil)

  @doc "One artist's albums eyebrow, carrying the real count."
  @spec albums_label(String.t() | nil) :: String.t()
  def albums_label(id) do
    count =
      case stored(id) do
        nil -> length(Sample.artist_albums())
        %Artist{} = artist -> length(stored_albums(artist))
      end

    "Albums · #{count}"
  end

  @doc "The album rail: art, title, and the line that says whether you have heard it."
  @spec rail() :: map()
  def rail, do: rail(nil)

  @doc "One artist's album rail."
  @spec rail(String.t() | nil) :: map()
  def rail(id) do
    rows =
      id
      |> Kati.Screens.ArtistDetail.albums()
      |> Enum.map(&Kati.Screens.ArtistDetail.rail_row/1)

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.card(rows)}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  One rail row's tag, built from the album's title and year.

  Every row in the discography rail shared `:open_album`, so the rail was one
  `accessibility_id` repeated and `onNodeWithTag` throws on the second match
  (#97).

  **Not the seed**, which is the obvious choice and the wrong one: every row of
  `Kati.Music.Sample.artist_albums/0` carries `seed: nil`, so a seed-derived
  tag collapses all four back onto `:open_album` and the rail collides exactly
  as before. `Kati.Screens.Music` can key on the seed because its rows have
  one; this rail cannot. Caught by the sweep, not by reading.

  Title *and* year for #97's first trap — a name that is not unique is not an
  identity — and both shapes carry the pair: `shape_album/1` maps it off
  `Kati.Music.Album` and the sample rows spell it out. A record with no year
  keeps its title alone, which is what the drawing's *Unheard* row is.

      iex> Kati.Screens.ArtistDetail.album_tag(%{title: "Low Country", year: 2023})
      :"open_album_Low_Country_2023"

      iex> Kati.Screens.ArtistDetail.album_tag(%{title: "Estuary Tapes", year: nil})
      :"open_album_Estuary_Tapes"

      iex> Kati.Screens.ArtistDetail.album_tag(%{})
      :open_album
  """
  @spec album_tag(map()) :: atom()
  def album_tag(album) do
    title =
      album |> Map.get(:title, "") |> to_string() |> String.trim() |> String.replace(" ", "_")

    year = album |> Map.get(:year) |> to_string() |> String.trim()

    case {title, year} do
      {"", ""} -> :open_album
      {"", y} -> String.to_atom("open_album_" <> y)
      {t, ""} -> String.to_atom("open_album_" <> t)
      {t, y} -> String.to_atom("open_album_" <> t <> "_" <> y)
    end
  end

  @doc false
  def rail_row(album) do
    SettingsList.row(
      Kati.Screens.ArtistDetail.rail_art(album),
      SettingsList.body(album.title, album.line),
      SettingsList.trailing(nil),
      on_tap: {self(), Kati.Screens.ArtistDetail.album_tag(album)}
    )
  end

  @doc false
  def rail_art(album) do
    case album.seed && Kati.Design.Images.poster(album.seed) do
      nil ->
        assigns = %{initial: album.title |> String.first() |> String.upcase()}

        ~MOB"""
        <Box
          width={40}
          height={40}
          corner_radius={8}
          background={Kati.Theme.Palette.placeholder()}
          align="center"
        >
          <Text
            text={@initial}
            text_size={15}
            font_weight="bold"
            text_align="center"
            text_color={Kati.Theme.Palette.sub()}
          />
        </Box>
        """

      src ->
        ~MOB"""
        <Image src={src} width={40} height={40} corner_radius={8} content_mode="fill" />
        """
    end
  end

  @doc """
  Plays by album, as bars.

  Scaled against the loudest album rather than against a round number, because
  the question the chart answers is *which of these did I actually play* and a
  fixed axis would flatten four similar records into four similar bars.
  """
  @spec chart() :: map()
  def chart, do: chart(nil)

  @doc "One artist's plays-by-album chart."
  @spec chart(String.t() | nil) :: map()
  def chart(id) do
    albums = Kati.Screens.ArtistDetail.albums(id)
    top = albums |> Enum.map(& &1.plays) |> Enum.max(fn -> 0 end)

    bars =
      albums
      |> Enum.map(&Kati.Screens.ArtistDetail.bar(&1, top))
      |> Enum.intersperse(~MOB"<Spacer size={11} />")

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={20}
        padding={17}
        shadow={Kati.Theme.shadow_card()}
      >
        {bars}
        {Kati.Screens.ArtistDetail.truncation(id)}
      </Column>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def bar(album, top) do
    fraction = if top > 0, do: album.plays / top, else: 0.0

    rail =
      Kati.Components.MishkaProgress.progress(
        render: :box,
        value: fraction,
        max: 1,
        height: 6,
        corner_radius: 3,
        color: Palette.bar_ink(),
        track_color: Palette.track()
      )

    assigns = %{title: album.title, plays: Integer.to_string(album.plays), rail: rail}

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Text
          text={@title}
          text_size={12.5}
          font_weight="semibold"
          text_color={:on_surface}
          max_lines={1}
          weight={1.0}
        />
        <Spacer size={10} />
        <Text text={@plays} font_family="mono" text_size={12} text_color={Palette.sub()} />
      </Row>
      <Spacer size={7} />
      {@rail}
    </Column>
    """
  end

  @doc """
  The line that says a chart is not the whole story, or nothing.

  Drawn only when albums were actually left out. A chart captioned *and 0 more*
  is worse than an uncaptioned one.
  """
  @spec truncation() :: map() | []
  def truncation, do: truncation(nil)

  @doc "The same line for one artist by id."
  @spec truncation(String.t() | nil) :: map() | []
  def truncation(id) do
    case Kati.Screens.ArtistDetail.truncated(id) do
      0 ->
        []

      more ->
        assigns = %{label: "and #{more} more"}

        ~MOB"""
        <Column fill_width={true}>
          <Spacer size={11} />
          <Text
            text={@label}
            font_family="mono"
            text_size={10.5}
            letter_spacing={0.1}
            text_color={Kati.Theme.Palette.tertiary()}
          />
        </Column>
        """
    end
  end

  @doc """
  The unheard-release card — the one orange thing on the page.

  Two controls of different weight, as the drawing ranks them: `Remind me` arms
  something and takes the ink; `Dismiss` takes the card away and is plain text.
  """
  @spec unheard(boolean()) :: map() | []
  def unheard(dismissed?), do: unheard(dismissed?, nil)

  @doc "The same card for one artist by id."
  @spec unheard(boolean(), String.t() | nil) :: map() | []
  def unheard(true, _id), do: []

  def unheard(false, id) do
    case Kati.Screens.ArtistDetail.unheard_release(id) do
      nil ->
        []

      release ->
        assigns = %{title: release.title, line: release.line}

        ~MOB"""
        <Column fill_width={true}>
          {Kati.UI.eyebrow("New from this artist")}
          <Column fill_width={true} background={Palette.cream()} corner_radius={22} padding={17}>
            <Text
              text={@title}
              text_size={17}
              font_weight="bold"
              letter_spacing={-0.02}
              text_color={Palette.cream_ink()}
              max_lines={1}
            />
            <Spacer size={6} />
            <Text text={@line} text_size={12.5} text_color={Palette.cream_sub()} max_lines={1} />
            <Spacer size={14} />
            <Row fill_width={true} align="center">
              <Row
                height={36}
                corner_radius={18}
                background={Palette.ink_fill()}
                padding_left={16}
                padding_right={16}
                align="center"
                on_tap={{self(), :remind_me}}
              >
                <Text
                  text="Remind me"
                  text_size={12.5}
                  font_weight="bold"
                  text_color={Palette.on_ink()}
                  max_lines={1}
                />
              </Row>
              <Spacer size={14} />
              <Text
                text="Dismiss"
                text_size={12.5}
                font_weight="semibold"
                text_color={Palette.cream_sub()}
                on_tap={{self(), :dismiss_release}}
              />
              <Spacer weight={1.0} />
            </Row>
          </Column>
          <Spacer size={24} />
        </Column>
        """
    end
  end

  @doc """
  The release the card is about: the first album with no plays, or the drawing's.

  Derived rather than stored, because *unheard* is not a state somebody sets —
  it is the absence of a play, and a column recording it would need updating the
  first time one arrived.
  """
  @spec unheard_release() :: map() | nil
  def unheard_release, do: unheard_release(nil)

  @doc "The same release for one artist by id."
  @spec unheard_release(String.t() | nil) :: map() | nil
  def unheard_release(id) do
    case stored(id) do
      nil ->
        Sample.unheard()

      %Artist{} = artist ->
        case unheard_albums(artist) do
          [] -> nil
          [album | _rest] -> %{title: album.title, line: String.capitalize(unheard_line())}
        end
    end
  end

  @doc """
  Every record by this artist that has never been played, newest release first.

  *Unheard* means no track on it has a play, which is `Kati.Music.Track.plays`
  through `Kati.Screens.AlbumDetail.play_count/1` and not the absence of a
  `Kati.Music.Listen` — a scrobble import supplies counts with no sittings
  behind them, so the two questions have different answers on a real shelf.

  Public because screen 21's **New from artists you follow** band is this list,
  for every artist you follow, and it must not be a second definition: a record
  this band called new and this page's own card did not would be one journey
  disagreeing with itself in two taps. Takes the row rather than an id, because
  that band already holds the artists it read.

  `Kati.Screens.ArtistDetail.albums/1`'s cap does not apply here. The cap is
  the drawing's, on a rail and a chart that compare four things; whether a
  record has been heard is not a comparison and truncating it would hide one.
  """
  @spec unheard_albums(Artist.t() | String.t() | nil) :: [map()]
  def unheard_albums(%Artist{} = artist) do
    # `plays == 0`, and that is the whole rule. `Unheard` is the drawing's own
    # word for a record with no plays and it is true of one you typed in
    # yourself: you have not played it.
    #
    # Left open deliberately. Screen 21 reads this list for its band, and that
    # band is titled **New from artists you follow** — which an album you typed
    # in is not: it is not new and it is not from anyone. Narrowing the filter
    # to albums that have a tracklist was tried and is the wrong instrument: it
    # would also drop a real release whose tracks have not been fetched yet,
    # and it changes what screen 77's card says in order to fix what screen 21's
    # heading claims. The two readings want different things from one list, and
    # which one gives is a decision for the board rather than for a filter.
    artist |> stored_albums() |> Enum.filter(&(&1.plays == 0))
  end

  def unheard_albums(id) do
    case stored(id) do
      nil -> []
      %Artist{} = artist -> unheard_albums(artist)
    end
  end

  @doc """
  The words this app uses for a record you have never played.

  One phrase, two screens: this page's card writes it as a sentence and screen
  21's band writes it after the record's title. Spelled once so the two cannot
  drift into saying the same thing differently on either side of one tap.

      iex> Kati.Screens.ArtistDetail.unheard_line()
      "you have not heard it"
  """
  @spec unheard_line() :: String.t()
  def unheard_line, do: "you have not heard it"

  @doc "Three figures, in screen 07's stat typography."
  @spec totals(map()) :: map()
  def totals(a) do
    ~MOB"""
    <Row fill_width={true} align="top">
      <Column weight={1.0}>
        {Kati.Screens.AlbumDetail.stat_tile("Listened", a.hours)}
      </Column>
      <Spacer size={9} />
      <Column weight={1.0}>
        {Kati.Screens.AlbumDetail.stat_tile("First heard", a.first_heard || "—")}
      </Column>
      <Spacer size={9} />
      <Column weight={1.0}>
        {Kati.Screens.AlbumDetail.stat_tile("Albums", a.album_count)}
      </Column>
    </Row>
    """
  end

  @doc """
  Following, flipped — and written through, so the shelf agrees.

  The assign is updated from the row rather than re-read, because the write may
  have nothing to write to: with nothing stored the page is the drawing's and
  the toggle still has to move, or the control would look broken on exactly the
  device where nothing else is wrong.
  """
  def handle_tap(:toggle_following, socket) do
    artist = socket.assigns.artist
    now = not artist.following

    # `target/1` and then a NIL CHECK, rather than handing nil to `stored/1`.
    # `stored(nil)` re-reads the shelf and answers its head, which is right when
    # the page is DRAWING that head and wrong the moment it is not: screen 79
    # opened bare draws `Kati.Music.SampleFa`'s artist, and this write then
    # followed whoever happened to lead the shelf at the instant the finger
    # landed — a person the reader had never seen. Screen 66's wrong-row write
    # was the same shape one domain over.
    #
    # A page that resolved a real artist carries its id (`shaped/2` puts it
    # there), so `target/1` is non-nil and this writes to the artist on screen.
    # A page drawing a fixture has no id and writes nothing — and the switch
    # still moves, because a control that looked broken on a device with
    # nothing shelved would be the least explicable thing here.
    with id when is_binary(id) <- Kati.Screens.ArtistDetail.target(socket.assigns),
         %Artist{} = stored <- stored(id) do
      Ash.update(stored, %{following: now})
    end

    {:noreply, Mob.Socket.assign(socket, :artist, %{artist | following: now})}
  rescue
    _error -> {:noreply, Mob.Socket.assign(socket, :artist, socket.assigns.artist)}
  end

  def handle_tap(:open_album, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.AlbumDetail)}

  def handle_tap(:remind_me, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.ReleaseWatcher)}

  # `Dismiss` takes the card off this render and writes nothing, because
  # *unheard* is derived from a play count and there is nothing to set. A
  # dismissal that outlived the session would need a column of its own, and one
  # release dismissed on one page does not earn one — the card comes back next
  # time, which is correct: the record is still unheard.
  def handle_tap(:dismiss_release, socket),
    do: {:noreply, Mob.Socket.assign(socket, :dismissed?, true)}

  # Every rail row, by its own title and year — see `album_tag/1` — and now for
  # routing as well as for being addressable.
  #
  # The tag is not the id and cannot become one: `album_tag/1` is built from
  # title and year precisely because the drawing's four rows carry `seed: nil`,
  # and a title is a label rather than an identity. So the row is found back in
  # the list this page drew and the row's own id is what travels.
  #
  # A tag matching nothing, and every `Kati.Music.Sample` row, both answer `%{}`
  # through `params_for/1` — screen 74's shelf-first-then-drawing path,
  # unchanged.
  #
  # Below the named clauses, above the catch-all: a prefix match placed before
  # them makes every one of them unreachable, silently.
  def handle_tap(tag, socket) when is_atom(tag) do
    if String.starts_with?(Atom.to_string(tag), "open_album_") do
      row =
        socket.assigns
        |> Map.get(:artist_id)
        |> albums()
        |> Enum.find(&(album_tag(&1) == tag))

      {:noreply,
       Mob.Socket.push_screen(
         socket,
         Kati.Screens.AlbumDetail,
         Kati.Screens.AlbumDetail.params_for(row)
       )}
    else
      {:noreply, socket}
    end
  end

  def handle_tap(_tag, socket), do: {:noreply, socket}
end
