defmodule Kati.Screens.SeriesFa do
  @moduledoc """
  Screen 58 — سریال, the Persian episode tracker, pushed under کتابخانه.

  Built to `.scratch/design/screens/58.html`. Screen 04's page in Persian, and
  smaller in two ways that are easy to miss: the artwork is **300** tall, not
  330, and the frame's bottom inset is **40, not 132**, because a pushed
  screen has no dock to clear.

  ## Its own chrome, like screen 04 — and one glyph different

  `Kati.Screens.Pushed` puts an `arrow_back_ios_new` pill on paper. This page
  floats its own over the photograph, and the chevron is **`arrow_forward_ios`**:
  back is the way the reader came from, and in Persian that is the right edge.
  A mirrored screen that keeps the left-pointing chevron is the commonest RTL
  bug there is, so the drawing names the other glyph and this screen uses it.

  ## The gradient is what makes the title readable

  170pt of `rgba(239,236,231,1) 4% → .72 42% → transparent` lifted back over
  the bottom of the photograph. Without it "گودال بلند" is near-black type on
  a dark picture. Three stops, not two — the bridge's gradient parser takes as
  many colour/stop pairs as the design writes.

  ## Three episode states

  Watched rows sit flat on `#F4F1EC` with a filled ink check and a muted
  title; the two unaired rows are lifted on card white with an ink title and
  an empty `rgba(26,25,23,.16)` ring. The drawing puts a `check` glyph inside
  that ring at **zero alpha** — invisible, but it holds the ring's inner
  metrics identical to the filled one, so the column does not shift. That is
  reproduced literally rather than tidied away.

  ## The rows and the pills are real, and what that costs

  Tapping an episode toggles its ring, and the ۱/۲/۳ pills swap the season
  under them. Both go through the same rule the English screen keeps: the
  counter, the bar and the button's label are **derived** from the episode
  list on the way out of a tap, never stored beside it, because two places
  that can disagree eventually do — and the first tap that marks an episode
  watched is the tap that makes them.

  But they are derived *only in a handler*. `Sample.series/0`'s own
  `watched_line`, `progress` and `action` are what the drawing shows, and they
  are the resting values verbatim: ۵ از ۷ and .71 and قسمت ۶ را دیده‌ام. The
  derivation would produce the same three strings and 5/7 = .714, which is a
  third of a device pixel wider than the drawing's bar. Not worth spending on
  a frame that is compared pixel by pixel, so nothing recomputes until the
  reader touches something.

  A tag carries an **index**, never a label — `Kati.Screens.MealsMatrixFa`'s
  rule, for its reason: an atom that has to survive the tap registry and the
  accessibility id should be ASCII, and every label on this screen is Persian.
  """
  use Mob.Screen
  import Mob.Sigil

  alias Kati.Components.MishkaActionIcon
  alias Kati.Screens.Fa
  alias Kati.Screens.SeriesFa.Sample
  alias Kati.UI

  # `current` is read off the sample's own pills rather than written as 1, so
  # the lit pill is whichever one the sample says is lit. `saved` is the
  # bookmark's knob, and false is the unfilled glyph the drawing shows.
  def mount(_params, _session, socket) do
    Mob.Theme.set(Kati.Theme.light())
    sample = Sample.series()
    current = Enum.find_index(sample.seasons, fn {_label, on?} -> on? end) || 0
    series = sample |> Map.put(:current, current) |> Map.put(:saved, false)

    {:ok, Mob.Socket.assign(socket, :series, series)}
  end

  def render(assigns) do
    Fa.pushed_frame(Kati.Screens.SeriesFa.page(assigns.series))
  end

  @doc false
  def page(series) do
    ~MOB"""
    <Box fill_width={true} fill_height={true}>
      <Scroll>
        <Column fill_width={true}>
          {Kati.Screens.SeriesFa.artwork(series)}
          <Column fill_width={true} padding_left={21} padding_right={21} padding_top={16} padding_bottom={40}>
            {Kati.Screens.SeriesFa.season_card(series)}
            {Kati.Screens.SeriesFa.actions(series)}
            {Kati.Screens.SeriesFa.episodes_header(series)}
            {Kati.Screens.SeriesFa.episodes(series)}
          </Column>
        </Column>
      </Scroll>
      {Kati.Screens.SeriesFa.chrome(series)}
    </Box>
    """
  end

  @doc false
  def artwork(series) do
    ~MOB"""
    <Box fill_width={true} height={300} background={0xFFDCD7CF}>
      {Kati.Screens.SeriesFa.hero_art(series.seed)}
      <Box fill_width={true} fill_height={true} align="bottom">
        <Box fill_width={true} height={170} gradient="to_top #FFEFECE7 4% #B8EFECE7 42% #00EFECE7" />
      </Box>
      <Box fill_width={true} fill_height={true} align="bottom">
        <Column fill_width={true} padding_left={21} padding_right={21} padding_bottom={6}>
          <Text
            text={series.title}
            font_family="fa"
            font_weight="extrabold"
            text_size={28}
            line_height={1.35}
            text_color={:on_surface}
          />
          <Spacer size={8} />
          <Text text={series.meta} font_family="fa" text_size={11.5} text_color={0xFF6E6860} max_lines={1} />
        </Column>
      </Box>
    </Box>
    """
  end

  # The 900x700 crop, which is the one the drawing names — not the 900x740
  # `Kati.Design.Images.hero/1` reaches for first.
  @doc false
  def hero_art(seed) do
    case Kati.Design.Images.path(seed, {900, 700}) do
      nil ->
        ~MOB"<Spacer size={0} />"

      src ->
        ~MOB"""
        <Image src={src} fill_width={true} height={300} content_mode="fill" />
        """
    end
  end

  @doc false
  def chrome(series) do
    back = {self(), :back}

    ~MOB"""
    <Box fill_width={true} fill_height={true} align="top">
      <Row fill_width={true} padding_left={21} padding_right={21} padding_top={60} align="center">
        <Row
          height={44}
          corner_radius={22}
          background={0xFFFBFAF8}
          shadow={Kati.Theme.shadow_button()}
          padding_left={12}
          padding_right={16}
          align="center"
          on_tap={back}
        >
          {UI.symbol("arrow_forward_ios", size: 17)}
          <Spacer size={6} />
          <Text
            text={series.back}
            font_family="fa"
            font_weight="semibold"
            text_size={13.5}
            text_color={:on_surface}
            max_lines={1}
          />
        </Row>
        <Spacer weight={1.0} />
        {Kati.Screens.SeriesFa.more()}
      </Row>
    </Box>
    """
  end

  @doc """
  The ⋯ disc, as `Kati.Components.MishkaActionIcon`.

  A round icon disc on a raised fill is exactly what that component draws, and
  this is the one disc in the Persian set it can draw: every other one — the
  back pill's neighbours on 57, 59, 60, 61, 62 and the bookmark beside the
  primary button below — carries `Kati.Theme.shadow_button/0` or
  `shadow_card_soft/0`, and **no** component in the vendored set takes a
  `shadow` prop. This disc carries none, so nothing is lost.

  `:circle` resolves to an exact `size / 2`, so 42 still rounds at 21, and
  `variant: :filled` paints the drawing's own `rgba(251,250,248,.82)`.

  The glyph goes in as a **child**, not as `icon`: the component's `icon` path
  builds a plain `Text`, which lands in Plus Jakarta Sans, and a Material
  Symbol only exists in the `symbols` face. A child is wrapped in a bare `Row`
  that hugs its single `Text` and is centred by the same `align: :center` box,
  so the drawn result is the glyph in the middle of a 42pt circle — the node
  this function replaced, plus one `Row` that has no size of its own.
  """
  def more do
    MishkaActionIcon.action_icon(
      %{size: 42, shape: :circle, variant: :filled, background: 0xD1FBFAF8},
      [UI.symbol("more_horiz", size: 21)]
    )
  end

  @doc false
  def season_card(series) do
    progress = series.progress

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={0xFFFBFAF8}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={17}
      >
        <Row fill_width={true} align="bottom">
          <Text
            text={series.season}
            font_family="fa"
            font_weight="bold"
            text_size={14.5}
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer weight={1.0} />
          <Text
            text={series.watched_line}
            font_family="fa"
            text_size={11.5}
            text_color={0xFF8A8479}
            max_lines={1}
          />
        </Row>
        <Spacer size={12} />
        {Kati.Screens.SeriesFa.season_bar(progress)}
        <Spacer size={14} />
        <Row fill_width={true} align="center">
          <Box width={6} height={6} corner_radius={3} background={0xFFE8823C} />
          <Spacer size={8} />
          <Text text={series.next_air} font_family="fa" text_size={12} text_color={0xFF5C574F} max_lines={1} />
        </Row>
      </Column>
      <Spacer size={14} />
    </Column>
    """
  end

  # Not `Kati.Components.MishkaProgress`: it renders the native `Progress`
  # widget, which is Material 3 1.2.0's `LinearProgressIndicator` — fixed at
  # 240dp by 4dp by a `.size(...)` applied after the caller's modifier, with no
  # track colour forwarded and a `Butt` stroke cap. This bar is the card's full
  # width, 6 tall, `#E7E3DC` behind ink, and rounded at 3.
  # `Kati.Screens.LibraryFa.progress/1` sets the case out in full.
  #
  # A Compose weight must be greater than zero, so an empty season and a
  # finished one are their own clauses rather than a weight of 0.0 — the same
  # shape `Kati.Screens.LibraryFa.progress/1` has. The drawing's .71 goes down
  # the middle clause and is untouched; the two ends are what the bar needs the
  # moment the rows below it can be tapped, since marking the last episode
  # watched would otherwise hand Compose a zero weight and take the activity
  # down with it — and فصل ۳ starts at zero for the same reason.
  @doc false
  def season_bar(progress) when progress <= 0.0 do
    ~MOB"<Box fill_width={true} height={6} corner_radius={3} background={0xFFE7E3DC} />"
  end

  def season_bar(progress) when progress >= 1.0 do
    ~MOB"""
    <Box fill_width={true} height={6} corner_radius={3} background={0xFFE7E3DC}>
      <Box fill_width={true} height={6} corner_radius={3} background={Kati.Theme.ink()} />
    </Box>
    """
  end

  def season_bar(progress) do
    ~MOB"""
    <Box fill_width={true} height={6} corner_radius={3} background={0xFFE7E3DC}>
      <Row fill_width={true}>
        <Box weight={progress} height={6} corner_radius={3} background={Kati.Theme.ink()} />
        <Spacer weight={1.0 - progress} />
      </Row>
    </Box>
    """
  end

  # One disc beside the primary button, not two: this drawing keeps `bookmark`
  # and drops screen 04's `star`.
  #
  # The button marks the next unwatched episode, which is what its own label
  # says out loud — قسمت ۶ را دیده‌ام — so the row below it fills its ring and
  # the counter above it moves. The disc is the bookmark's knob: `saved` fills
  # the glyph, and false is the outline the drawing shows.
  @doc false
  def actions(series) do
    mark = {self(), :mark_next}
    save = {self(), :toggle_save}
    saved = series.saved

    ~MOB"""
    <Row fill_width={true} align="center">
      <Box weight={1.0}>
        <Row
          fill_width={true}
          height={50}
          corner_radius={25}
          background={Kati.Theme.ink()}
          align="center"
          on_tap={mark}
        >
          <Spacer weight={1.0} />
          {UI.symbol("check", size: 19, color: 0xFFFBFAF8)}
          <Spacer size={8} />
          <Text
            text={series.action}
            font_family="fa"
            font_weight="bold"
            text_size={13.5}
            text_color={0xFFFBFAF8}
            max_lines={1}
          />
          <Spacer weight={1.0} />
        </Row>
      </Box>
      <Spacer size={10} />
      <Box
        width={50}
        height={50}
        corner_radius={25}
        background={0xFFFBFAF8}
        shadow={Kati.Theme.shadow_card_soft()}
        align="center"
        on_tap={save}
      >
        {UI.symbol("bookmark", size: 21, fill: saved)}
      </Box>
    </Row>
    """
  end

  @doc false
  def episodes_header(series) do
    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={26} />
      <Row fill_width={true} align="center" padding_left={2} padding_right={2}>
        <Box width={13} height={2} corner_radius={1} background={0xFFE8823C} />
        <Spacer size={9} />
        <Text text="قسمت‌ها" font_family="fa" font_weight="semibold" text_size={11} text_color={0xFFA0998F} />
        <Spacer weight={1.0} />
        {series.seasons
         |> Enum.with_index()
         |> Enum.map(fn {{label, _on?}, i} ->
           Kati.Screens.SeriesFa.season_pill(label, i, i == series.current)
         end)
         |> Enum.intersperse(Kati.Screens.SeriesFa.pill_gap())}
      </Row>
      <Spacer size={12} />
    </Column>
    """
  end

  @doc false
  def pill_gap, do: ~MOB"<Spacer size={5} />"

  # The sample's own `on?` is ignored in favour of `series.current`, which
  # `mount/3` reads *out of* those same flags — one place owns which pill is
  # lit once the pill is a control, and it starts where the sample put it.
  #
  # Not `Kati.Components.MishkaChip`, and not `MishkaPill`. The pills' labels
  # are ۱, ۲, ۳ — U+06F1..U+06F3, **Persian** digits, not ASCII — and neither
  # component takes `font_family`, so each would draw a blank box in Plus
  # Jakarta Sans (checked: `kati_sans_400.ttf` has zero code points in
  # U+0600-U+06FF). Shape is the second wall: both hard-code
  # `corner_radius={:radius_pill}` and one uniform `padding={:space_sm}`, where
  # the drawing gives these a declared 32x28 on a radius of 10.
  @doc false
  def season_pill(label, index, on?) do
    tap = {self(), String.to_atom("season_" <> Integer.to_string(index))}
    bg = if on?, do: Kati.Theme.ink(), else: 0xFFE4E0D9
    fg = if on?, do: 0xFFFBFAF8, else: 0xFF6E6860

    ~MOB"""
    <Box width={32} height={28} corner_radius={10} background={bg} align="center" on_tap={tap}>
      <Text text={label} font_family="fa" text_size={11.5} text_color={fg} max_lines={1} />
    </Box>
    """
  end

  @doc """
  The seasons the drawing never shows.

  58 draws فصل ۲ and only فصل ۲, so `Sample.series/0` carries that one
  verbatim and the captured frame is untouched. The ۱/۲/۳ pills are a real
  control though, and a control that changes nothing is a lie told in pixels,
  so the other two need episodes to switch to. These are dummy and shaped like
  the drawing's own rows: a finished season whose sub-lines are runtimes, and
  one that has not started whose sub-lines are air dates — which is exactly
  the two sub-line shapes فصل ۲ already mixes.
  """
  @spec season(non_neg_integer()) :: map()
  def season(0) do
    %{
      season: "فصل ۱",
      next_air: "پخش این فصل تمام شده است",
      episodes: [
        %{n: "۱", title: "آب فرودست", sub: "۴۶ دقیقه", watched: true},
        %{n: "۲", title: "جاده‌ی گدار", sub: "۴۴ دقیقه", watched: true},
        %{n: "۳", title: "خار ساحل", sub: "۴۹ دقیقه", watched: true},
        %{n: "۴", title: "هر چیز خاموش", sub: "۴۵ دقیقه", watched: true},
        %{n: "۵", title: "گودال بلند", sub: "۵۸ دقیقه", watched: true}
      ]
    }
  end

  def season(2) do
    %{
      season: "فصل ۳",
      next_air: "قسمت اول پنجشنبه ۱۲ شهریور، ساعت ۲۰:۰۰",
      episodes: [
        %{n: "۱", title: "زنگ شناور", sub: "پخش ۱۲ شهریور", watched: false},
        %{n: "۲", title: "شوره‌زار", sub: "پخش ۱۹ شهریور", watched: false},
        %{n: "۳", title: "خط جزر", sub: "پخش ۲۶ شهریور", watched: false}
      ]
    }
  end

  def season(_two) do
    sample = Sample.series()
    %{season: sample.season, next_air: sample.next_air, episodes: sample.episodes}
  end

  @doc false
  def episodes(series) do
    ~MOB"""
    <Column fill_width={true}>
      {series.episodes
       |> Enum.with_index()
       |> Enum.map(fn {ep, i} -> Kati.Screens.SeriesFa.episode(ep, i) end)}
    </Column>
    """
  end

  # The tag carries the episode's position in the list, not its ۱..۷ — those
  # are Persian digits held as copy, and folding them back to an integer to
  # name a tap is work the index does for free.
  @doc false
  def episode(ep, index) do
    tap = {self(), String.to_atom("episode_" <> Integer.to_string(index))}
    bg = if ep.watched, do: 0xFFF4F1EC, else: 0xFFFBFAF8
    shadow = if ep.watched, do: nil, else: Kati.Theme.shadow_card_soft()
    title_color = if ep.watched, do: 0xFF9C958B, else: Kati.Theme.ink()

    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={bg}
        corner_radius={17}
        shadow={shadow}
        padding_left={15}
        padding_right={15}
        padding_top={13}
        padding_bottom={13}
        align="center"
        on_tap={tap}
      >
        <Column width={24}>
          <Text text={ep.n} font_family="fa" text_size={12} text_color={0xFFB3ACA2} max_lines={1} />
        </Column>
        <Spacer size={13} />
        <Column weight={1.0}>
          <Text
            text={ep.title}
            font_family="fa"
            font_weight="semibold"
            text_size={13.5}
            text_color={title_color}
            max_lines={1}
          />
          <Spacer size={4} />
          <Text text={ep.sub} font_family="fa" text_size={11} text_color={0xFFB3ACA2} max_lines={1} />
        </Column>
        <Spacer size={13} />
        {Kati.Screens.SeriesFa.check(ep.watched)}
      </Row>
      <Spacer size={8} />
    </Column>
    """
  end

  @doc false
  def check(true) do
    ~MOB"""
    <Box
      width={27}
      height={27}
      corner_radius={14}
      background={Kati.Theme.ink()}
      border_width={1.5}
      border_color={0xFF1A1917}
      align="center"
    >
      {Kati.UI.symbol("check", size: 16, color: 0xFFFBFAF8)}
    </Box>
    """
  end

  # The empty ring, with the drawing's own zero-alpha glyph inside it so the
  # ring's inner box measures the same as the filled one.
  def check(false) do
    ~MOB"""
    <Box
      width={27}
      height={27}
      corner_radius={14}
      border_width={1.5}
      border_color={0x291A1917}
      align="center"
    >
      {Kati.UI.symbol("check", size: 16, color: 0x001A1917)}
    </Box>
    """
  end

  def handle_info({:tap, :back}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}

  def handle_info({:tap, :toggle_save}, socket) do
    series = socket.assigns.series
    {:noreply, Mob.Socket.assign(socket, :series, %{series | saved: not series.saved})}
  end

  # The button says which episode it will mark, so it marks that one: the first
  # still unwatched. With none left there is nothing to do and the label has
  # already said so.
  def handle_info({:tap, :mark_next}, socket) do
    series = socket.assigns.series

    case Enum.find_index(series.episodes, &(not &1.watched)) do
      nil -> {:noreply, socket}
      i -> {:noreply, Mob.Socket.assign(socket, :series, toggle(series, i))}
    end
  end

  def handle_info({:tap, tag}, socket) when is_atom(tag) do
    case Atom.to_string(tag) do
      "season_" <> index ->
        i = String.to_integer(index)
        series = socket.assigns.series
        data = Kati.Screens.SeriesFa.season(i)

        series =
          recount(%{
            series
            | current: i,
              season: data.season,
              next_air: data.next_air,
              episodes: data.episodes
          })

        {:noreply, Mob.Socket.assign(socket, :series, series)}

      "episode_" <> index ->
        series = socket.assigns.series
        {:noreply, Mob.Socket.assign(socket, :series, toggle(series, String.to_integer(index)))}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  defp toggle(series, index) do
    flip = fn ep -> %{ep | watched: not ep.watched} end
    recount(%{series | episodes: List.update_at(series.episodes, index, flip)})
  end

  # Everything the episode list implies, recomputed from the episode list.
  # `action/1` regenerates the drawing's own قسمت ۶ را دیده‌ام when the sample's
  # five-of-seven is what it is handed, which is the check that the sentence
  # here and the sentence in the sample are the same sentence.
  defp recount(series) do
    watched = Enum.count(series.episodes, & &1.watched)
    total = length(series.episodes)
    fraction = if total > 0, do: watched / total, else: 0.0
    fa = &Kati.Calendar.Shamsi.fa/1

    %{
      series
      | watched_line: "#{fa.(watched)} از #{fa.(total)} دیده شده",
        progress: fraction,
        action: action(series.episodes)
    }
  end

  defp action(episodes) do
    case Enum.find(episodes, &(not &1.watched)) do
      nil -> "همه‌ی قسمت‌ها دیده شده"
      ep -> "قسمت " <> ep.n <> " را دیده‌ام"
    end
  end
end
