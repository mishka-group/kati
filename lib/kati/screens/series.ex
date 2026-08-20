defmodule Kati.Screens.Series do
  @moduledoc """
  Screen 04 — a series, pushed under Library.

  Built to `.scratch/design/screens/04.html`. The shape is a 330pt artwork
  block with a 190pt gradient lifting the paper back over it, floating chrome
  at 60pt, and the title sitting on the gradient rather than in a bar.

  The chrome here is the screen's own, not `Kati.Screens.Pushed`'s: this back
  pill floats over artwork at `rgba(251,250,248,.82)` and carries the label
  inline, where the standard pushed chrome sits on paper. Matching the drawing
  matters more than sharing a helper.

  Three episode states are drawn and all three are exercised by the sample:
  watched (muted title, filled check), unwatched (ink title, hollow check),
  and not yet aired (muted, no check).
  """
  use Mob.Screen
  import Mob.Sigil

  alias Kati.Components.MishkaActionIcon
  alias Kati.Components.MishkaProgress
  alias Kati.Library.Sample
  alias Kati.Theme

  def mount(_params, _session, socket) do
    Mob.Theme.set(Kati.Theme.light())
    {:ok, Mob.Socket.assign(socket, :series, Sample.series())}
  end

  # The counter and the ring are DERIVED, never stored. Storing "5 of 7" beside
  # a list of episodes means two places can disagree, and the first tap that
  # marks an episode watched is the one that makes them.
  defp recount(s) do
    %{s | watched: Enum.count(s.episodes, & &1.watched), total: length(s.episodes)}
  end

  def render(assigns) do
    s = assigns.series
    pct = s.watched / s.total

    ~MOB"""
    <Box fill_width={true} fill_height={true} background={:background} layout_direction={Kati.Locale.direction_prop()}>
      <Scroll>
        <Column fill_width={true}>
          {Kati.Screens.Series.artwork(s)}
          <Column fill_width={true} padding_left={21} padding_right={21} padding_top={16} padding_bottom={40}>
            {Kati.Screens.Series.season_card(s, pct)}
            {Kati.Screens.Series.actions()}
            {Kati.Screens.Series.episodes_header(s)}
            {Kati.Screens.Series.episodes(s)}
          </Column>
        </Column>
      </Scroll>
      {Kati.Screens.Series.chrome()}
    </Box>
    """
  end

  @doc false
  def artwork(s) do
    ~MOB"""
    <Box fill_width={true} height={330} background={0xFFDCD7CF}>
      {Kati.Screens.Series.hero_art()}
      <Box fill_width={true} fill_height={true} align="bottom">
        {Kati.UI.paper_fade(190)}
      </Box>
      <Box fill_width={true} fill_height={true} align="bottom">
        <Column fill_width={true} padding_left={21} padding_right={21} padding_bottom={6}>
          <Text
            text={s.title}
            text_size={30}
            font_weight="extrabold"
            letter_spacing={-0.035}
            line_height={1.05}
            text_color={:on_surface}
          />
          <Spacer size={9} />
          <Text text={s.meta} font_family="mono" text_size={11.5} text_color={0xFF6E6860} max_lines={1} />
        </Column>
      </Box>
    </Box>
    """
  end

  @doc false
  def hero_art do
    case Kati.Library.Sample.art("hollow71") do
      nil -> ~MOB"<Spacer size={0} />"
      src -> ~MOB"""
        <Image src={src} fill_width={true} height={330} content_mode="fill" />
        """
    end
  end

  # The floating chrome. `arrow_back_ios_new` rather than a chevron, because
  # that is the glyph the drawing names.
  @doc false
  def chrome do
    back = {self(), :back}
    fill = 0xD1FBFAF8
    lift = "0 6 16 -8 #991A1917"

    ~MOB"""
    <Box fill_width={true} fill_height={true} align="top">
      <Row fill_width={true} padding_left={21} padding_right={21} padding_top={60} align="center">
        <Row height={42} corner_radius={21} background={fill} shadow={lift} padding_left={12} padding_right={16} align="center" on_tap={back}>
          {Kati.UI.symbol("arrow_back_ios_new", size: 17)}
          <Spacer size={6} />
          <Text text="Library" text_size={13.5} font_weight="semibold" letter_spacing={-0.01} text_color={:on_surface} />
        </Row>
        <Spacer weight={1.0} />
        {Kati.Screens.Series.more_disc(fill, lift)}
      </Row>
    </Box>
    """
  end

  # The ⋯ half of the floating chrome, as Chelekom's headless Action Icon — the
  # component's own example of what it is for. Both of the props that made it
  # possible are non-theme values this screen invents: a 0xD1 translucent paper
  # fill and a one-layer lift that is not in `Kati.Theme` at all, because this
  # is chrome over artwork rather than a card on paper. `background` and
  # `shadow` take them verbatim.
  #
  # `shape: :circle` computes `42 / 2` = 21.0 against the Box's stated 21.
  #
  # The back pill beside it stays hand-rolled: it is a Row of glyph + label,
  # and an Action Icon is by definition icon-only — its children go into a Row
  # inside a SQUARE `size x size` box, so a 42-tall pill 100-odd wide has no
  # shape to be built out of.
  @doc false
  def more_disc(fill, lift) do
    MishkaActionIcon.action_icon(
      [
        size: 42,
        shape: :circle,
        variant: :filled,
        background: fill,
        shadow: lift,
        on_tap: :open_settings
      ],
      [Kati.UI.symbol("more_horiz", size: 21)]
    )
  end

  @doc false
  def season_card(s, pct) do
    ~MOB"""
    <Column fill_width={true}>
    <Column
      fill_width={true}
      background={Kati.Theme.card(:light)}
      corner_radius={22}
      shadow={Kati.Theme.shadow_card()}
      padding={17}
    >
      <Row fill_width={true} align="center">
        <Text text={s.season} text_size={15} font_weight="bold" letter_spacing={-0.02} text_color={:on_surface} />
        <Spacer weight={1.0} />
        <Text
          text={"#{s.watched} of #{s.total} watched"}
          font_family="mono"
          text_size={11.5}
          text_color={0xFF8A8479}
          max_lines={1}
        />
      </Row>
      <Spacer size={12} />
      {Kati.Screens.Series.season_bar(pct)}
      <Spacer size={14} />
      <Row fill_width={true} align="center">
        <Box width={6} height={6} corner_radius={3} background={0xFFE8823C} />
        <Spacer size={8} />
        <Text text="Next episode airs " text_size={12.5} text_color={0xFF5C574F} max_lines={1} />
        <Text text={s.next_air} text_size={12.5} font_weight="semibold" text_color={:on_surface} max_lines={1} />
      </Row>
    </Column>
    <Spacer size={14} />
    </Column>
    """
  end

  @doc """
  The season rail — 6pt, radius 3, ink on `#E7E3DC` — as Chelekom's headless
  Progress in its drawn mode.

  It was two weighted Boxes because `<Progress>` is Material's
  `LinearProgressIndicator`: it fills its parent, paints its own track in
  `ProgressIndicatorDefaults.linearTrackColor`, and carries the material3
  version of the day's thickness and caps. None of the drawing's three numbers
  were reachable through it. `render: :box` draws the same track-Box-with-a-
  fill-Box this file hand-rolled, with the arithmetic in one place.

  ## Why this one, and not just any bar

  The end this screen actually reaches is **100%**: the sample's S1 is 5 of 5,
  and every tap on a watched episode can put any season there. The hand-rolled
  shape emitted `<Spacer weight={1.0 - pct} />` unguarded, so a finished season
  handed Compose a literal `weight: 0.0` — `"invalid weight 0.0; must be
  greater than zero"`, which is a crash, not a warning. `0%` is equally
  ordinary (a season with nothing watched) and produced the same zero on the
  fill. The component omits the node at either end rather than weighting it
  zero, which draws the same nothing without the throw.

  `max: 1` because `pct` is already a fraction; `render/1` keeps owning the
  `watched / total` division so the number reaching the bar is unchanged.
  """
  @spec season_bar(float()) :: map()
  def season_bar(pct) do
    MishkaProgress.progress(
      render: :box,
      value: pct,
      max: 1,
      height: 6,
      corner_radius: 3,
      color: Theme.ink(),
      track_color: 0xFFE7E3DC
    )
  end

  @doc false
  def actions do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Box weight={1.0}>
          <Row fill_width={true} height={50} corner_radius={25} background={Kati.Theme.ink()} align="center">
            <Spacer weight={1.0} />
            {Kati.UI.symbol("check", size: 19, color: 0xFFFBFAF8)}
            <Spacer size={8} />
            <Text text="Mark next watched" text_size={14} font_weight="bold" text_color={0xFFFBFAF8} max_lines={1} />
            <Spacer weight={1.0} />
          </Row>
        </Box>
        <Spacer size={10} />
        {Kati.Screens.Series.action_disc("bookmark")}
        <Spacer size={10} />
        {Kati.Screens.Series.action_disc("star")}
      </Row>
    </Column>
    """
  end

  # Chelekom's headless Action Icon. `shadow` is the prop that made it usable:
  # these two discs sit beside a 50pt ink button on paper, and with a flat fill
  # they read as holes in the row rather than as buttons next to it. The lift is
  # the design's own `shadow_card_soft()`.
  #
  # `shape: :circle` computes `50 / 2` = 25.0 where the Box stated 25;
  # `floatProp` reads both as 25.0f. No handler is passed and none is wanted —
  # bookmark and rate are not built — and the component omits the key entirely
  # rather than sending a null, so no `clickable` is attached and the disc is as
  # inert as the Box was.
  @doc false
  def action_disc(icon) do
    MishkaActionIcon.action_icon(
      [
        size: 50,
        shape: :circle,
        variant: :filled,
        background: Theme.card(:light),
        shadow: Theme.shadow_card_soft()
      ],
      [Kati.UI.symbol(icon, size: 21)]
    )
  end

  @doc false
  def episodes_header(s) do
    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={26} />
      <Row fill_width={true} align="center" padding_left={2} padding_right={2}>
        <Box width={13} height={2} corner_radius={1} background={0xFFE8823C} />
        <Spacer size={9} />
        <Text text="EPISODES" font_family="mono" text_size={10.5} letter_spacing={0.16} text_color={0xFFA0998F} />
        <Spacer weight={1.0} />
        {s.seasons |> Enum.map(fn n -> Kati.Screens.Series.season_pill(n, n == s.current_season) end) |> Enum.intersperse(Kati.Screens.Series.pill_gap())}
      </Row>
      <Spacer size={12} />
    </Column>
    """
  end

  @doc false
  def pill_gap, do: ~MOB"<Spacer size={5} />"

  # NOT Chelekom's Chip, though this is a chip in every other respect — S1 / S2
  # / S3, exactly one checked, tapping replaces the selection. It has the size,
  # the radius, both fills and both inks now.
  #
  # What it lacks is one prop: **`font_family` on the label.** The component
  # builds its own `<Text text text_size text_color />` and merges only
  # `font_weight` and `max_lines` onto it, so a label can be sized, weighted and
  # clipped but not set in another face. These pills are DM Mono at 11.5, and a
  # season number in Plus Jakarta beside a mono episode list is a visible
  # change, not a rounding error.
  #
  # `trailing` is the escape hatch on screen 03 — its count goes in as a node,
  # which keeps its own family — but there is no such slot for the LABEL, which
  # is the only content here. Upstream ask: `font_family`, alongside the
  # `text_size` / `font_weight` / `max_lines` the label already takes. Kati sets
  # mono on every count, clock time, season number and meta line in the design,
  # so this is the prop that decides how many chips the component can draw.
  @doc false
  def season_pill(label, on?) do
    bg = if on?, do: Theme.ink(), else: 0xFFE4E0D9
    fg = if on?, do: 0xFFFBFAF8, else: 0xFF6E6860
    tap = {self(), String.to_atom("season_" <> label)}

    ~MOB"""
    <Box width={30} height={28} corner_radius={10} background={bg} align="center" on_tap={tap}>
      <Text text={label} font_family="mono" text_size={11.5} text_color={fg} max_lines={1} />
    </Box>
    """
  end

  @doc false
  def episodes(s) do
    ~MOB"""
    <Column fill_width={true}>
      {s.episodes
       |> Enum.map(fn ep -> Kati.Screens.Series.episode(ep) end)
       |> Enum.intersperse(Kati.Screens.Series.episode_gap())}
    </Column>
    """
  end

  @doc false
  def episode(ep) do
    aired? = Map.get(ep, :aired, true)
    bg = if ep.watched, do: 0xFFF4F1EC, else: Theme.card(:light)
    title_color = if ep.watched or not aired?, do: 0xFF8A8479, else: Theme.ink()
    # An episode that has not aired cannot be marked watched, so it gets no tap
    # at all rather than a tap that silently does nothing.
    tap = if aired?, do: {self(), String.to_atom("episode_#{ep.n}")}, else: nil

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} on_tap={tap} background={bg} corner_radius={17} padding_left={15} padding_right={15} padding_top={13} padding_bottom={13} align="center">
        <Column width={22}>
          <Text text={"#{ep.n}"} font_family="mono" text_size={12} text_color={0xFFB3ACA2} max_lines={1} />
        </Column>
        <Spacer size={13} />
        <Column weight={1.0}>
          <Text text={ep.title} text_size={14} font_weight="semibold" letter_spacing={-0.01} text_color={title_color} max_lines={1} />
          <Spacer size={4} />
          <Text text={ep.sub} font_family="mono" text_size={10.5} text_color={0xFFB3ACA2} max_lines={1} />
        </Column>
        <Spacer size={13} />
        {Kati.Screens.Series.check(ep.watched, aired?)}
      </Row>
    </Column>
    """
  end

  @doc false
  def episode_gap, do: ~MOB"<Spacer size={8} />"

  @doc false
  def check(true, _aired?) do
    ~MOB"""
    <Box width={27} height={27} corner_radius={14} background={Kati.Theme.ink()} align="center">
      {Kati.UI.symbol("check", size: 16, color: 0xFFFBFAF8)}
    </Box>
    """
  end

  def check(false, true) do
    ~MOB"""
    <Box width={27} height={27} corner_radius={14} border_width={1} border_color={0xFFD8D2C8} align="center">
      {Kati.UI.symbol("check", size: 16, color: 0xFFD8D2C8)}
    </Box>
    """
  end

  # Not aired yet: no affordance at all, because there is nothing to mark.
  def check(false, false), do: ~MOB"<Spacer size={27} />"

  def handle_info({:tap, :back}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}

  def handle_info({:tap, :open_settings}, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.SeriesSettings)}

  def handle_info({:tap, tag}, socket) do
    case Atom.to_string(tag) do
      "season_" <> label ->
        s = socket.assigns.series
        episodes = Sample.season_episodes(label)
        series = recount(%{s | current_season: label, season: "Season " <> String.trim_leading(label, "S"), episodes: episodes})
        {:noreply, Mob.Socket.assign(socket, :series, series)}

      "episode_" <> n ->
        n = String.to_integer(n)
        s = socket.assigns.series

        episodes =
          Enum.map(s.episodes, fn ep ->
            if ep.n == n, do: %{ep | watched: not ep.watched}, else: ep
          end)

        {:noreply, Mob.Socket.assign(socket, :series, recount(%{s | episodes: episodes}))}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_info(_msg, socket), do: {:noreply, socket}
end
