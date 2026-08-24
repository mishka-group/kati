defmodule Kati.Screens.AlbumDetail do
  @moduledoc """
  Screen 74 — an album, pushed under Library.

  Screen 66 is a book and this is its shape again rather than a third detail
  idiom — hero, ratings, the user's own words on cream, a history band, one ink
  button. What differs is what an album has that a book does not: a **tracklist
  that is itself a set of counts**, and a listening history dense enough to draw
  as a field rather than as rows.

  ## Drawn with no artwork, on purpose

  The design's own caption: *drawn in its default state: no art, since Cover Art
  Archive coverage is patchy — a paper square carrying the album initial and the
  "Art" placeholder rather than a broken image.* So the square is the default
  rendering and not a fallback, and `Kati.Music.Album.initial/1` fills it. An
  album that does have art draws it in the same 86pt tile.

  ## The dot

  One recency signal on the whole page, and the caption names it: *the dot marks
  a track played today.* Not "recently", not "this week" — today, compared
  against the device's date, which is why `Kati.Music.Track.played_today?/2`
  takes the date as an argument.

  ## No connection state here

  Screen 74 shows no ListenBrainz badge, and the caption says why: *connection
  state belongs to 80*. A per-album scrobble indicator would put the same fact
  in as many places as there are albums, each able to disagree with the others.

  ## Where the data comes from

  `Kati.Music`, through `album/0`. Four reads and never one per band — the
  album, its artist, its tracklist and its listens — for the reason
  `Kati.Screens.Film` takes three. Nothing hands this screen an id, so the
  referent is the shelf's first, and with nothing shelved `Kati.Music.Sample`
  is drawn: the values `test/design/screens/74.html` was captured from.
  """

  use Kati.Screens.Pushed, back: "Library"

  alias Kati.Music.Album
  alias Kati.Music.Artist
  alias Kati.Music.Listen
  alias Kati.Music.Sample
  alias Kati.Music.Track
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  @secondary [{"star", "Rate", :rate}, {"bookmarks", "Add to list", :add_to_list}]

  def load(socket), do: Mob.Socket.assign(socket, :album, album())

  @doc "The album this screen is about: the shelf's first, or the drawing's."
  @spec album() :: map()
  def album, do: shelved_album() || Sample.album()

  @doc "The drawing's values, unconditionally."
  @spec drawn_album() :: map()
  def drawn_album, do: Sample.album()

  @doc "The tracklist: the shelved album's, or the drawing's five."
  @spec tracks() :: [map()]
  def tracks do
    case shelved() do
      nil -> Sample.tracks()
      %Album{} = album -> Enum.map(tracks_of(album), &shape_track/1)
    end
  end

  @doc "The tracklist eyebrow, which carries the real count."
  @spec tracklist_label() :: String.t()
  def tracklist_label do
    case shelved() do
      nil ->
        Sample.tracklist_label()

      %Album{} = album ->
        count = length(tracks_of(album))
        "Tracklist · #{count} #{if count == 1, do: "track", else: "tracks"}"
    end
  end

  @doc "The shaped album, or `nil` when nothing is shelved."
  @spec shelved_album() :: map() | nil
  def shelved_album do
    case shelved() do
      nil -> nil
      %Album{} = album -> shaped(album, artist_of(album), tracks_of(album), listens_of(album))
    end
  end

  defp shelved do
    case Ash.read(Album, action: :shelf) do
      {:ok, [album | _rest]} -> album
      _other -> nil
    end
  rescue
    _error -> nil
  end

  defp artist_of(%Album{artist_id: nil}), do: nil

  defp artist_of(%Album{artist_id: id}) do
    case Ash.get(Artist, id) do
      {:ok, artist} -> artist
      _other -> nil
    end
  rescue
    _error -> nil
  end

  @doc false
  def tracks_of(%Album{id: id}) do
    Track
    |> Ash.Query.for_read(:for_album, %{album_id: id})
    |> Ash.read()
    |> case do
      {:ok, tracks} -> tracks
      _other -> []
    end
  rescue
    _error -> []
  end

  defp listens_of(%Album{id: id}) do
    Listen
    |> Ash.Query.for_read(:for_album, %{album_id: id})
    |> Ash.read()
    |> case do
      {:ok, listens} -> listens
      _other -> []
    end
  rescue
    _error -> []
  end

  @doc "One album plus what it needs, as the render wants it. Pure, so it is testable."
  @spec shaped(Album.t(), Artist.t() | nil, [Track.t()], [Listen.t()]) :: map()
  def shaped(%Album{} = album, artist, tracks, listens) do
    today = Kati.Time.today()

    %{
      title: album.title,
      initial: Album.initial(album),
      artist: artist && artist.name,
      byline: Album.byline(album, artist),
      art_seed: album.art_seed,
      artist_line: artist_line(artist, listens),
      first_heard: date_line(album.first_heard_on),
      last_played: last_played_line(album.last_played_on, today),
      rating: album.rating,
      rating_label: rating_label(album.rating),
      note: album.note,
      note_on: album.note_on && String.upcase(date_line(album.note_on)),
      plays_line: plays_line(tracks, listens, today)
    }
  end

  defp shape_track(%Track{} = track) do
    %{
      position: track.position,
      title: track.title,
      duration: Track.duration(track),
      plays: track.plays,
      today?: Track.played_today?(track, Kati.Time.today()),
      counted?: Kati.Screens.AlbumDetail.counted_this_month?(track, Kati.Time.today())
    }
  end

  @doc """
  Whether this track has been played in the calendar month `today` is in.

  Screen 73 draws these rows pre-ticked and in the watched fill, so a second
  tick reads as a second tick rather than as the first. `last_played_on` is the
  only column that could answer it, which means a track played twice this month
  and once last month answers the same as one played once — true either way,
  and the row says *already counted*, not *how many times*.
  """
  @spec counted_this_month?(Track.t(), Date.t()) :: boolean()
  def counted_this_month?(%Track{last_played_on: %Date{} = on}, %Date{} = today),
    do: on.year == today.year and on.month == today.month

  def counted_this_month?(%Track{}, %Date{}), do: false

  # `4 albums · 61h listened`, and each half is dropped rather than zeroed when
  # it has nothing behind it — an artist row that says `0 albums · 0h listened`
  # about somebody you have four records by is worse than no row.
  defp artist_line(nil, _listens), do: nil

  defp artist_line(%Artist{id: id}, listens) do
    albums =
      Album
      |> Ash.Query.for_read(:for_artist, %{artist_id: id})
      |> Ash.read()
      |> case do
        {:ok, list} -> length(list)
        _other -> 0
      end

    hours = Listen.hours_label(Listen.total_minutes(listens))
    "#{albums} #{if albums == 1, do: "album", else: "albums"} · #{hours} listened"
  rescue
    _error -> nil
  end

  defp date_line(nil), do: nil
  defp date_line(%Date{} = date), do: Calendar.strftime(date, "%-d %b %Y")

  # `yesterday` is a word the drawing uses, and it is the only relative form
  # here: two days ago is a date. A relative phrase is only kinder than a date
  # while it is shorter to read, and "3 days ago" is not.
  defp last_played_line(nil, _today), do: nil

  defp last_played_line(%Date{} = on, today) do
    case Date.diff(today, on) do
      0 -> "today"
      1 -> "yesterday"
      _older -> date_line(on)
    end
  end

  defp rating_label(nil), do: nil

  defp rating_label(rating) when is_integer(rating) do
    case rem(rating, 2) do
      0 -> Integer.to_string(div(rating, 2))
      _odd -> "#{div(rating, 2)}.5"
    end
  end

  # `41 plays · 4 this month`. The total is the tracklist's, the month is the
  # listens' — two different sources for two different facts, which is the
  # domain's own split and is why neither is derived from the other.
  defp plays_line(tracks, listens, today) do
    total = Album.plays(tracks)
    month = Listen.this_month(listens, today)
    "#{total} #{if total == 1, do: "play", else: "plays"} · #{month} this month"
  end

  @doc false
  def content(assigns) do
    a = assigns.album

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
        {Kati.Screens.AlbumDetail.hero(a)}
        {Kati.Screens.AlbumDetail.artist_row(a)}
        {Kati.Screens.AlbumDetail.dates(a)}
        {UI.eyebrow(Kati.Screens.AlbumDetail.tracklist_label())}
        {Kati.Screens.AlbumDetail.tracklist()}
        {Kati.Screens.AlbumDetail.dot_note()}
        {UI.eyebrow("Listen history · 13 weeks")}
        {Kati.Screens.AlbumDetail.history(a)}
        {Kati.Screens.AlbumDetail.note(a)}
        {Kati.Screens.AlbumDetail.actions()}
      </Column>
    </Scroll>
    """
  end

  @doc "The art tile beside the title and byline."
  @spec hero(map()) :: map()
  def hero(a) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        {Kati.Screens.AlbumDetail.art(a)}
        <Spacer size={15} />
        <Column weight={1.0}>
          <Text
            text={a.title}
            text_size={26}
            font_weight="bold"
            letter_spacing={-0.03}
            text_color={:on_surface}
            max_lines={2}
          />
          <Spacer size={6} />
          <Text text={a.byline || ""} text_size={13.5} text_color={Palette.muted()} max_lines={1} />
        </Column>
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc """
  The paper square with the album's initial, or the artwork when there is any.

  Two clauses, and the first is the default — see the moduledoc. The `Art`
  label under the letter is the drawing's own placeholder text and it stays:
  it is what tells the reader the square is standing in for a cover rather than
  being one.
  """
  @spec art(map()) :: map()
  def art(%{art_seed: nil} = a) do
    ~MOB"""
    <Column
      width={86}
      height={86}
      corner_radius={10}
      background={Palette.placeholder()}
      align="center"
    >
      <Spacer weight={1.0} />
      <Text
        text={a.initial}
        text_size={30}
        font_weight="bold"
        text_align="center"
        text_color={Palette.sub()}
      />
      <Spacer size={2} />
      <Text
        text="Art"
        font_family="mono"
        text_size={9.5}
        letter_spacing={0.12}
        text_align="center"
        text_color={Palette.tertiary()}
      />
      <Spacer weight={1.0} />
    </Column>
    """
  end

  def art(a) do
    case Kati.Design.Images.poster(a.art_seed) do
      nil ->
        art(%{a | art_seed: nil})

      src ->
        ~MOB"""
        <Image src={src} width={86} height={86} corner_radius={10} content_mode="fill" />
        """
    end
  end

  @doc "The artist row, which pushes screen 77, or nothing when the album has no artist."
  @spec artist_row(map()) :: map() | []
  def artist_row(%{artist: nil}), do: []

  def artist_row(a) do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.card([
        Kati.UI.SettingsList.row(
          Kati.UI.SettingsList.icon_tile("person"),
          Kati.UI.SettingsList.body(a.artist, a.artist_line),
          Kati.UI.SettingsList.trailing(Kati.UI.SettingsList.chevron()),
          on_tap: {self(), :open_artist}
        )
      ])}
      <Spacer size={20} />
    </Column>
    """
  end

  @doc """
  Two dates and a rating, in screen 07's stat-trio typography with two tiles.

  The caption asks for exactly that: *two dates take the stat-trio typography
  with two tiles, alignment kept*. Keeping the alignment is why the rating sits
  beside them in a third tile rather than in its own band — three tiles is the
  arrangement the typography was drawn for.
  """
  @spec dates(map()) :: map()
  def dates(a) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        <Column weight={1.0}>
          {Kati.Screens.AlbumDetail.stat_tile("First heard", a.first_heard || "—")}
        </Column>
        <Spacer size={10} />
        <Column weight={1.0}>
          {Kati.Screens.AlbumDetail.stat_tile("Last played", a.last_played || "—")}
        </Column>
      </Row>
      <Spacer size={10} />
      {Kati.Screens.AlbumDetail.rating_tile(a)}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def stat_tile(label, value) do
    assigns = %{label: label, value: value}

    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={18}
      padding={14}
      shadow={Kati.Theme.shadow_card()}
    >
      <Text
        text={String.upcase(@label)}
        font_family="mono"
        text_size={9.5}
        letter_spacing={0.12}
        text_color={Palette.muted()}
      />
      <Spacer size={9} />
      <Text text={@value} text_size={15} font_weight="bold" text_color={:on_surface} max_lines={1} />
    </Column>
    """
  end

  @doc false
  def rating_tile(a) do
    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={18}
      padding={14}
      shadow={Kati.Theme.shadow_card()}
    >
      <Text
        text="YOUR RATING"
        font_family="mono"
        text_size={9.5}
        letter_spacing={0.12}
        text_color={Palette.muted()}
      />
      <Spacer size={9} />
      <Row fill_width={true} align="center">
        {Kati.Screens.BookDetail.stars(a.rating)}
        <Spacer size={9} />
        <Text
          text={a.rating_label || "—"}
          font_family="mono"
          text_size={13}
          text_color={:on_surface}
          max_lines={1}
        />
      </Row>
    </Column>
    """
  end

  @doc "The tracklist, in running order."
  @spec tracklist() :: map()
  def tracklist do
    rows = Enum.map(Kati.Screens.AlbumDetail.tracks(), &Kati.Screens.AlbumDetail.track_row/1)

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.card(rows)}
      <Spacer size={10} />
    </Column>
    """
  end

  @doc false
  def track_row(t) do
    SettingsList.row(
      ~MOB"""
      <Text
        text={Integer.to_string(t.position)}
        font_family="mono"
        text_size={11.5}
        text_color={Kati.Theme.Palette.tertiary()}
        width={22}
      />
      """,
      ~MOB"""
      <Row fill_width={true} align="center">
        <Text
          text={t.title}
          text_size={13.5}
          font_weight="semibold"
          text_color={:on_surface}
          max_lines={1}
          weight={1.0}
        />
        <Spacer size={10} />
        <Text
          text={t.duration || ""}
          font_family="mono"
          text_size={11.5}
          text_color={Kati.Theme.Palette.muted()}
        />
      </Row>
      """,
      SettingsList.trailing(Kati.Screens.AlbumDetail.track_trailing(t))
    )
  end

  @doc false
  def track_trailing(t) do
    assigns = %{plays: Integer.to_string(t.plays), today?: t.today?}

    ~MOB"""
    <Row align="center">
      {Kati.Screens.AlbumDetail.dot(@today?)}
      <Text
        text={@plays}
        font_family="mono"
        text_size={12}
        text_color={Kati.Theme.Palette.sub()}
        width={22}
        text_align="right"
      />
    </Row>
    """
  end

  @doc false
  def dot(false), do: ~MOB"<Spacer size={0} />"

  def dot(true) do
    ~MOB"""
    <Row align="center">
      <Box width={5} height={5} corner_radius={3} background={Kati.Theme.Palette.accent()} />
      <Spacer size={7} />
    </Row>
    """
  end

  @doc """
  The line that explains the dot.

  Drawn because the dot is the page's only recency signal and an unexplained
  coloured dot beside a number reads as an alert. `Kati.UI.SettingsList.note/2`
  is the same `info` row screen 27 uses.
  """
  @spec dot_note() :: map()
  def dot_note do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.note("info", "The dot marks a track played today — the only recency signal here")}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  The 13-week pixel field, matching screens 22 and 47.

  Thirteen weeks because that is what those two draw and the caption pins it —
  a field that is one length on the habits page and another here would be two
  different units of "recently" in one app.
  """
  @spec history(map()) :: map()
  def history(a) do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={20}
        padding={15}
        shadow={Kati.Theme.shadow_card()}
      >
        {Kati.Screens.AlbumDetail.field_rows()}
        <Spacer size={11} />
        <Row fill_width={true} align="center">
          <Text
            text="MAY"
            font_family="mono"
            text_size={9.5}
            letter_spacing={0.12}
            text_color={Palette.muted()}
          />
          <Spacer weight={1.0} />
          <Text
            text={a.plays_line}
            font_family="mono"
            text_size={11}
            text_color={Palette.sub()}
            max_lines={1}
          />
        </Row>
      </Column>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  The field's intensities, one per day over thirteen weeks.

  Read from the listens where there are any: a day with a sitting is lit at a
  strength that follows its minutes, so a long evening reads darker than a
  passing play. With nothing stored the drawing's own field is used, which is
  what `Kati.Music.Sample` is for.
  """
  @spec field() :: [non_neg_integer()]
  def field do
    case shelved() do
      nil ->
        Sample.listen_field()

      %Album{} = album ->
        today = Kati.Time.today()
        by_day = Map.new(listens_of(album), &{&1.listened_on, &1.minutes || 0})

        for offset <- 90..0//-1 do
          case Map.get(by_day, Date.add(today, -offset)) do
            nil -> 0
            minutes when minutes >= 45 -> 3
            minutes when minutes >= 20 -> 2
            _short -> 1
          end
        end
    end
  end

  @doc """
  The cream card, or nothing.

  Same rule as screens 08 and 66: cream marks the user's own words, so an album
  nobody has written about has no warm rectangle waiting for one.
  """
  @spec note(map()) :: map() | []
  def note(%{note: nil}), do: []

  def note(a) do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.eyebrow("Your note")}
      <Column fill_width={true} background={Palette.cream()} corner_radius={22} padding={17}>
        <Text text={a.note} text_size={14} line_height={1.45} text_color={Palette.cream_body()} />
        <Spacer size={8} />
        <Text
          text={a.note_on || ""}
          font_family="mono"
          text_size={10.5}
          letter_spacing={0.12}
          text_color={Palette.cream_meta()}
        />
      </Column>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc "One ink button and two circular seconds — screen 66's row with one fewer."
  @spec actions() :: map()
  def actions do
    seconds =
      @secondary
      |> Enum.map(fn {icon, label, tag} -> Kati.Screens.BookDetail.second(icon, label, tag) end)
      |> Enum.intersperse(~MOB"<Spacer size={10} />")

    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        height={52}
        corner_radius={26}
        background={Palette.ink_fill()}
        align="center"
        on_tap={{self(), :log_listen}}
      >
        <Spacer weight={1.0} />
        <Text
          text="Log a listen"
          text_size={15}
          font_weight="bold"
          letter_spacing={-0.01}
          text_color={Palette.on_ink()}
        />
        <Spacer weight={1.0} />
      </Row>
      <Spacer size={12} />
      <Row fill_width={true}>
        {seconds}
      </Row>
    </Column>
    """
  end

  @doc """
  The field itself: ninety-one 8pt cells, chunked at 27 to the row.

  Twenty-seven because that is what fits between the card's own padding at
  8 + 4, and it is the same chunk screen 47 uses — two fields drawn the same
  size in one app that wrapped at different counts would read as two units.

  `Kati.UI.pixel_field/2` is the wrong recipe here and deliberately not reused:
  its cells are 15pt on a 3pt gap with a four-step ramp, which is screen 07's
  contribution grid. This is a five-step ramp at 8pt on 4. Same idea, different
  drawing.
  """
  @spec field_rows() :: map()
  def field_rows do
    rows = Enum.chunk_every(Kati.Screens.AlbumDetail.field(), 27)

    ~MOB"""
    <Column fill_width={true}>
      {Enum.map(rows, fn row -> Kati.Screens.AlbumDetail.field_row(row) end)}
    </Column>
    """
  end

  @doc false
  def field_row(row) do
    ~MOB"""
    <Column>
      <Row>
        {row |> Enum.map(&Kati.Screens.AlbumDetail.cell/1) |> Enum.intersperse(~MOB"<Spacer size={4} />")}
      </Row>
      <Spacer size={4} />
    </Column>
    """
  end

  @doc false
  def cell(level) do
    tone = Sample.tone(level)

    ~MOB"""
    <Box width={8} height={8} corner_radius={2} background={tone} />
    """
  end

  @doc false
  def handle_tap(:log_listen, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.LogListen)}

  def handle_tap(:open_artist, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.ArtistDetail)}

  def handle_tap(:rate, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Rating)}

  def handle_tap(:add_to_list, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Lists)}

  def handle_tap(_tag, socket), do: {:noreply, socket}
end
