defmodule Kati.Screens.LogListen do
  @moduledoc """
  Screen 73 — Log a listen, a sheet over the album you are playing.

  Screen 70's sheet again — same chrome, same segmented control, same cream
  confirmation line — and the caption says so by name. What is different is
  what a record is: **there is no finished shortcut**, because an album has no
  equivalent of closing a book. So this sheet has one commit and screen 70 has
  two.

  ## Three things the ticket left open, and where each landed

    * **The title.** `Log a listen`, not `Log listen` or `Add a play`. It is the
      verb phrase screen 70 uses one word away from, and the two sheets are
      siblings.
    * **The started-at row stays**, for parity with 70. A listen has a clock
      even though nothing on this sheet computes with it — dropping the row
      because the value goes unused would make two sibling sheets differ for a
      reason the reader cannot see.
    * **No `finished`.** See above.

  ## The sheet opens on `Selected tracks`, and the ticks are not empty

  The drawing raises `Selected tracks`, and the reason is in its own `info`
  line: *ticked rows are already counted this month*. So the ticks arrive
  populated — every track this album has been played on since the first of the
  month — and what you are doing is adjusting a set, not building one from
  nothing.

  That is why opening on `Whole album` would have been the wrong call even
  though it is one tap fewer: it would hide the fact that four of these five
  tracks are already counted, and a play logged in ignorance of that is the
  double-count the `info` line exists to prevent. `Whole album` remains one tap
  away for the case where you did play the whole thing.

  The rows reuse screen 04's episode-row recipe, already-counted ones in the
  watched fill, so a second tick is visibly a second tick.

  ## What one save touches

  Two tables, and this screen owns the order: the `Kati.Music.Listen` first,
  then the per-track counts. A failure between them leaves a sitting that
  happened rather than counts with nothing behind them — the same ordering
  argument `Kati.Screens.LogProgress.save_session/1` makes.
  """

  use Mob.Screen
  import Mob.Sigil

  alias Kati.Music.Album
  alias Kati.Music.Listen
  alias Kati.Music.Track
  alias Kati.Theme.Palette
  alias Kati.UI.Segmented
  alias Kati.UI.Sheet

  @scopes [
    {"Whole album", :scope_album},
    {"Selected tracks", :scope_selected},
    {"Minutes", :scope_minutes}
  ]

  def mount(_params, _session, socket) do
    Kati.Theme.activate()

    {:ok,
     socket
     |> Mob.Socket.assign(:album, album())
     |> Mob.Socket.assign(:tracks, Kati.Screens.AlbumDetail.tracks())
     |> Mob.Socket.assign(:scope, :scope_selected)
     |> Mob.Socket.assign(:ticked, counted_this_month())}
  end

  @doc """
  The album being logged against: the shelf's first, or the drawing's.

  Through screen 74's own reader, not a second one — a sheet aimed at a
  different album from the screen that opened it would write a play against the
  wrong record. Same rule, same reason, as screen 70.
  """
  @spec album() :: map()
  def album, do: Kati.Screens.AlbumDetail.album()

  def render(assigns), do: Sheet.sheet("Log a listen", body(assigns))

  @doc false
  def body(assigns) do
    a = assigns.album
    scope = assigns.scope

    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.LogListen.album_row(a)}
      {Segmented.plain(Kati.Screens.LogListen.scopes(), scope)}
      <Spacer size={16} />
      {Kati.Screens.LogListen.tracklist(assigns)}
      {Kati.Screens.LogListen.started_row()}
      <Spacer size={14} />
      {Kati.Screens.LogListen.insight(assigns)}
      <Spacer size={14} />
      {Sheet.commit("Save listen", :save)}
    </Column>
    """
  end

  @doc false
  def scopes, do: @scopes

  @doc "The album at 52pt, with its byline in the drawing's capitals."
  @spec album_row(map()) :: map()
  def album_row(a) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        {Kati.Screens.LogListen.art(a)}
        <Spacer size={13} />
        <Column weight={1.0}>
          <Text
            text={a.title}
            text_size={14.5}
            font_weight="bold"
            letter_spacing={-0.015}
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={5} />
          <Text
            text={String.upcase(a.byline || "")}
            font_family="mono"
            text_size={10.5}
            text_color={Palette.muted()}
            max_lines={1}
          />
        </Column>
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc false
  def art(%{art_seed: nil} = a) do
    assigns = %{initial: a.initial}

    ~MOB"""
    <Box width={52} height={52} corner_radius={7} background={Palette.placeholder()} align="center">
      <Text
        text={@initial}
        text_size={19}
        font_weight="bold"
        text_align="center"
        text_color={Palette.sub()}
      />
    </Box>
    """
  end

  def art(a) do
    case Kati.Design.Images.poster(a.art_seed) do
      nil ->
        Kati.Screens.LogListen.art(%{a | art_seed: nil})

      src ->
        ~MOB"""
        <Image src={src} width={52} height={52} corner_radius={7} content_mode="fill" />
        """
    end
  end

  @doc """
  The tracklist, or nothing at all.

  Drawn only under `Selected tracks`. Under `Whole album` there is nothing to
  choose, and a list of ticks nobody needs to touch is a list that makes the
  common case look like work.
  """
  @spec tracklist(map()) :: map() | []
  def tracklist(%{scope: scope}) when scope != :scope_selected, do: []

  def tracklist(assigns) do
    rows =
      assigns.tracks
      |> Enum.map(fn track ->
        Kati.Screens.LogListen.track_row(track, MapSet.member?(assigns.ticked, track.position))
      end)
      |> Enum.intersperse(~MOB"<Spacer size={7} />")

    ~MOB"""
    <Column fill_width={true}>
      {rows}
      <Spacer size={14} />
      {Kati.UI.SettingsList.note("info", "Ticked rows are already counted this month")}
      <Spacer size={14} />
    </Column>
    """
  end

  @doc """
  One track, with a tick that fills when it is chosen.

  Each row is its own 15pt lozenge rather than a line in a card, because the
  two states need different grounds: a track already counted this month sits on
  the settled fill with its title in the muted ink, and one that is not sits on
  card white. A `Kati.UI.SettingsList` card paints one ground behind every row
  in it and could not draw that distinction at all.

  The tick is screen 04's episode ring: a filled circle with an ink `check` when
  on, and the same ring with the glyph at zero alpha when off — the invisible
  glyph holds the ring's inner metrics identical so the column does not shift.
  Reproduced literally rather than tidied away, exactly as
  `Kati.Screens.SeriesFa` reproduces it.
  """
  @spec track_row(map(), boolean()) :: map()
  def track_row(track, on?) do
    counted? = Map.get(track, :counted?, false)

    assigns = %{
      position: Integer.to_string(track.position),
      title: track.title,
      duration: track.duration || "",
      on?: on?,
      background: Kati.Screens.LogListen.row_fill(counted?),
      title_color: Kati.Screens.LogListen.title_colour(counted?),
      tap: {self(), String.to_atom("track_#{track.position}")}
    }

    ~MOB"""
    <Row
      fill_width={true}
      background={@background}
      corner_radius={15}
      padding_left={13}
      padding_right={13}
      padding_top={10}
      padding_bottom={10}
      align="center"
      on_tap={@tap}
    >
      <Text
        text={@position}
        font_family="mono"
        text_size={11}
        text_color={Palette.tertiary()}
        width={16}
      />
      <Spacer size={12} />
      <Text
        text={@title}
        text_size={12.5}
        font_weight="semibold"
        text_color={@title_color}
        max_lines={1}
        weight={1.0}
      />
      <Spacer size={12} />
      <Text text={@duration} font_family="mono" text_size={10.5} text_color={Palette.tertiary()} />
      <Spacer size={12} />
      {Kati.Screens.LogListen.tick(@on?)}
    </Row>
    """
  end

  @doc "The settled fill for a track already counted, card white for one that is not."
  @spec row_fill(boolean()) :: integer()
  def row_fill(true), do: Palette.card_settled()
  def row_fill(false), do: Palette.card()

  @doc "Muted ink for a track already counted; full ink for one still to choose."
  @spec title_colour(boolean()) :: integer()
  def title_colour(true), do: Palette.settled_ink()
  def title_colour(false), do: Palette.ink()

  @doc false
  def tick(true) do
    ~MOB"""
    <Box
      width={24}
      height={24}
      corner_radius={12}
      background={Kati.Theme.Palette.ink_fill()}
      align="center"
    >
      {Kati.UI.symbol("check", size: 14, color: Kati.Theme.Palette.on_ink())}
    </Box>
    """
  end

  def tick(false) do
    ~MOB"""
    <Box
      width={24}
      height={24}
      corner_radius={12}
      background={Kati.Theme.Palette.transparent()}
      border_width={1.5}
      border_color={Kati.Theme.Palette.border()}
      align="center"
    >
      {Kati.UI.symbol("check", size: 14, color: Kati.Theme.Palette.ink_invisible())}
    </Box>
    """
  end

  @doc "Started-at, in the same card shape screen 70 gives it."
  @spec started_row() :: map()
  def started_row do
    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={20}
      padding_left={15}
      padding_right={15}
      shadow={Kati.Theme.shadow_card()}
    >
      <Row fill_width={true} padding_top={13} padding_bottom={13} align="center">
        <Box width={30} height={30} corner_radius={9} background={Palette.paper()} align="center">
          {Kati.UI.symbol("schedule", size: 17, color: Palette.ink_soft())}
        </Box>
        <Spacer size={13} />
        <Text
          text="Started at"
          text_size={13.5}
          font_weight="semibold"
          text_color={:on_surface}
          weight={1.0}
        />
        <Text
          text={Kati.Screens.LogProgress.started_at()}
          font_family="mono"
          text_size={12.5}
          text_color={Palette.ink_soft()}
          max_lines={1}
        />
      </Row>
    </Column>
    """
  end

  @doc """
  The cream line: how many tracks, how long, and how many times this month.

  The third clause is an ordinal — `4th time this month` — because it is a
  count of occasions and not a quantity. It is also the only figure on this
  sheet that is read rather than derived from the controls above it.
  """
  @spec insight(map()) :: map()
  def insight(assigns) do
    body = [text_size: 13, line_height: 1.55, text_color: Palette.cream_body()]
    strong = [font_weight: "semibold", text_color: Palette.cream_ink(), text_size: 13]

    tracks = Kati.Screens.LogListen.chosen_count(assigns)
    minutes = Kati.Screens.LogListen.chosen_minutes(assigns)

    Sheet.insight("insights", [
      {"That’s ", body},
      {"#{tracks} #{if tracks == 1, do: "track", else: "tracks"}", strong},
      {" · ", body},
      {"#{minutes} minutes", strong},
      {" · #{Kati.Screens.LogListen.ordinal(Kati.Screens.LogListen.times_this_month() + 1)} time this month",
       body}
    ])
  end

  @doc """
  The tracks this album has already been played on this calendar month.

  What the sheet opens with ticked, and what makes the `info` line under the
  list literally true. Read rather than assumed: the set is a fact about the
  month, not a default somebody chose.
  """
  @spec counted_this_month() :: MapSet.t(pos_integer())
  def counted_this_month do
    Kati.Screens.AlbumDetail.tracks()
    |> Enum.filter(& &1.counted?)
    |> MapSet.new(& &1.position)
  end

  @doc """
  How many tracks the sitting was: the album's, always.

  This is the one place the drawing forced a decision rather than describing
  one. Screen 73's confirmation reads `That's 11 tracks · 47 minutes` while its
  tracklist shows four ticked rows, and four is not eleven — so the line cannot
  be reporting the ticks.

  Reading it as the album resolves it and is the better design anyway: the
  sentence is about the **sitting**, which is a record and a length of time,
  and the ticks are about **credit** — which of the album's tracks this play
  counted towards. Those are genuinely different questions, and a confirmation
  that changed its length every time you toggled a track would be reporting the
  second one under the first one's wording.

  `Minutes` is the scope where the length is yours to state rather than the
  album's, and it is the only one where this figure is not the answer.
  """
  @spec chosen_count(map()) :: non_neg_integer()
  def chosen_count(%{tracks: tracks}), do: length(tracks)

  @doc """
  How long the sitting was, in whole minutes — the album's running time.

  Summed from the tracks' own durations and rounded once at the end, so eleven
  tracks of 4:12 do not accumulate eleven roundings.
  """
  @spec chosen_minutes(map()) :: non_neg_integer()
  def chosen_minutes(%{tracks: tracks}) do
    tracks
    |> Enum.map(&Kati.Screens.LogListen.seconds/1)
    |> Enum.sum()
    |> div(60)
  end

  @doc """
  The tracks this listen credits.

  Under `Selected tracks` that is the ticked set; under the other two it is
  every track, because neither of them offers a way to say otherwise.
  """
  @spec credited(map()) :: [map()]
  def credited(%{scope: :scope_selected, tracks: tracks, ticked: ticked}),
    do: Enum.filter(tracks, &MapSet.member?(ticked, &1.position))

  def credited(%{tracks: tracks}), do: tracks

  # The shaped track carries `4:12` rather than seconds, because that is what
  # the tracklist prints. Parsing it back is cheaper than threading a second
  # representation through the shape for one caller.
  @doc false
  def seconds(%{duration: nil}), do: 0

  def seconds(%{duration: duration}) do
    case String.split(duration, ":") do
      [m, s] -> String.to_integer(m) * 60 + String.to_integer(s)
      _other -> 0
    end
  end

  @doc "How many listens this album already has this calendar month."
  @spec times_this_month() :: non_neg_integer()
  def times_this_month do
    case shelved() do
      nil ->
        3

      %Album{id: id} ->
        Listen
        |> Ash.Query.for_read(:for_album, %{album_id: id})
        |> Ash.read()
        |> case do
          {:ok, listens} -> Listen.this_month(listens, Kati.Time.today())
          _other -> 0
        end
    end
  rescue
    _error -> 0
  end

  @doc """
  `1st`, `2nd`, `3rd`, `4th` — and `11th`, `12th`, `13th`.

  The teens are the whole reason this is a function: 11, 12 and 13 end in 1, 2
  and 3 and take `th` anyway, and every naive implementation gets them wrong.
  """
  @spec ordinal(pos_integer()) :: String.t()
  def ordinal(n) when rem(n, 100) in 11..13, do: "#{n}th"
  def ordinal(n) when rem(n, 10) == 1, do: "#{n}st"
  def ordinal(n) when rem(n, 10) == 2, do: "#{n}nd"
  def ordinal(n) when rem(n, 10) == 3, do: "#{n}rd"
  def ordinal(n), do: "#{n}th"

  defp shelved do
    case Ash.read(Album, action: :shelf) do
      {:ok, [album | _rest]} -> album
      _other -> nil
    end
  rescue
    _error -> nil
  end

  def handle_info({:tap, :close}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}

  def handle_info({:tap, scope}, socket)
      when scope in [:scope_album, :scope_selected, :scope_minutes],
      do: {:noreply, Mob.Socket.assign(socket, :scope, scope)}

  def handle_info({:tap, :save}, socket) do
    save_listen(socket.assigns)
    {:noreply, Mob.Socket.pop_screen(socket)}
  end

  def handle_info({:tap, tag}, socket) do
    case Atom.to_string(tag) do
      "track_" <> position ->
        at = String.to_integer(position)
        ticked = socket.assigns.ticked

        toggled =
          if MapSet.member?(ticked, at),
            do: MapSet.delete(ticked, at),
            else: MapSet.put(ticked, at)

        {:noreply, Mob.Socket.assign(socket, :ticked, toggled)}

      _other ->
        {:noreply, socket}
    end
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  @doc """
  Write the listen, then the per-track counts, then the album's last-played.

  Three writes in that order and all of them best-effort, for the reason the
  moduledoc gives: a sitting that happened is a better partial state than counts
  with nothing behind them, and a sheet that refuses to close because the disk
  is full is a worse failure than a lost play.
  """
  @spec save_listen(map()) :: :ok
  def save_listen(assigns) do
    with %Album{} = album <- shelved() do
      Ash.create(Listen, %{
        album_id: album.id,
        listened_on: Kati.Time.today(),
        tracks: Kati.Screens.LogListen.chosen_count(assigns),
        minutes: Kati.Screens.LogListen.chosen_minutes(assigns),
        scope: scope_value(assigns.scope)
      })

      bump_tracks(album, assigns)
      Ash.update(album, %{last_played_on: Kati.Time.today()})
    end

    :ok
  rescue
    _error -> :ok
  end

  defp scope_value(:scope_selected), do: :selected
  defp scope_value(:scope_minutes), do: :minutes
  defp scope_value(_album), do: :album

  # Under `Minutes` nothing names a track, so nothing is counted: the listen
  # holds the time and the tracklist is untouched. That is the honest answer —
  # forty minutes of a record is not a claim about which forty.
  defp bump_tracks(_album, %{scope: :scope_minutes}), do: :ok

  defp bump_tracks(album, assigns) do
    chosen = MapSet.new(Kati.Screens.LogListen.credited(assigns), & &1.position)
    today = Kati.Time.today()

    album
    |> Kati.Screens.AlbumDetail.tracks_of()
    |> Enum.filter(&MapSet.member?(chosen, &1.position))
    |> Enum.each(fn %Track{} = track ->
      Ash.update(track, %{plays: track.plays + 1, last_played_on: today})
    end)
  end
end
