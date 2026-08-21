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
  alias Kati.Components.MishkaThemeIcon
  alias Kati.Screens.Fa
  alias Kati.Screens.SeriesFa.Sample
  alias Kati.Theme.Palette
  alias Kati.UI

  # `current` is read off the sample's own pills rather than written as 1, so
  # the lit pill is whichever one the sample says is lit. `saved` is the
  # bookmark's knob, and false is the unfilled glyph the drawing shows.
  def mount(_params, _session, socket) do
    Kati.Theme.activate()
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
    # The three-stop scrim, built out here rather than written into the markup.
    # ~MOB is an uppercase sigil, so #{} inside it is literal text, and the page
    # colour went in as `#AARRGGBB` rather than as an `0x` literal — which is why
    # a grep for `0x` never found it and it stayed light while everything round it
    # followed the mode. `Kati.Screens.SeriesMeta.artwork/1` builds its own the
    # same way, and `Kati.UI.paper_fade/3` the two-stop one.
    #
    # Every stop is the SAME rgb at a different alpha, the invisible one included:
    # Compose interpolates in straight RGBA, so fading to `#00FFFFFF` would tint
    # the middle of the band. `rem/2` rather than a Bitwise import — the low 24
    # bits of an 0xAARRGGBB integer are the RGB.
    rgb =
      Palette.paper()
      |> rem(0x1000000)
      |> Integer.to_string(16)
      |> String.pad_leading(6, "0")

    fade = "to_top #FF#{rgb} 4% #B8#{rgb} 42% #00#{rgb}"

    ~MOB"""
    <Box fill_width={true} height={300} background={Palette.track_off()}>
      {Kati.Screens.SeriesFa.hero_art(series.seed)}
      <Box fill_width={true} fill_height={true} align="bottom">
        <Box fill_width={true} height={170} gradient={fade} />
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
          <Text text={series.meta} font_family="fa" text_size={11.5} text_color={Palette.meta()} max_lines={1} />
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
          background={Palette.card()}
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

  A round icon disc on a raised fill is exactly what that component draws. It
  used to be the *only* disc in the Persian set it could draw — every other one
  carries `Kati.Theme.shadow_button/0` or `shadow_card_soft/0`, and no
  component in the vendored set took a `shadow` prop. It does now, so the back
  pill's neighbours on 57, 59, 60, 61 and 62 are `Kati.Screens.Fa.disc/2` and
  the bookmark below is `save/1`, both on this same component. This disc still
  carries no shadow, so nothing about it changed.

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
      %{size: 42, shape: :circle, variant: :filled, background: Palette.chrome_disc()},
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
        background={Palette.card()}
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
            text_color={Palette.sub()}
            max_lines={1}
          />
        </Row>
        <Spacer size={12} />
        {Kati.Screens.SeriesFa.season_bar(progress)}
        <Spacer size={14} />
        <Row fill_width={true} align="center">
          <Box width={6} height={6} corner_radius={3} background={Palette.accent()} />
          <Spacer size={8} />
          <Text text={series.next_air} font_family="fa" text_size={12} text_color={Palette.ink_soft()} max_lines={1} />
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
    ~MOB"<Box fill_width={true} height={6} corner_radius={3} background={Palette.track()} />"
  end

  def season_bar(progress) when progress >= 1.0 do
    ~MOB"""
    <Box fill_width={true} height={6} corner_radius={3} background={Palette.track()}>
      <Box fill_width={true} height={6} corner_radius={3} background={Palette.ink()} />
    </Box>
    """
  end

  def season_bar(progress) do
    ~MOB"""
    <Box fill_width={true} height={6} corner_radius={3} background={Palette.track()}>
      <Row fill_width={true}>
        <Box weight={progress} height={6} corner_radius={3} background={Palette.ink()} />
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

    ~MOB"""
    <Row fill_width={true} align="center">
      <Box weight={1.0}>
        <Row
          fill_width={true}
          height={50}
          corner_radius={25}
          background={Palette.ink_fill()}
          align="center"
          on_tap={mark}
        >
          <Spacer weight={1.0} />
          {UI.symbol("check", size: 19, color: Palette.on_ink())}
          <Spacer size={8} />
          <Text
            text={series.action}
            font_family="fa"
            font_weight="bold"
            text_size={13.5}
            text_color={Palette.on_ink()}
            max_lines={1}
          />
          <Spacer weight={1.0} />
        </Row>
      </Box>
      <Spacer size={10} />
      {Kati.Screens.SeriesFa.save(series.saved)}
    </Row>
    """
  end

  @doc """
  The bookmark disc, as `Kati.Components.MishkaActionIcon`.

  The same component `more/0` uses, reached for the same reason and unblocked
  by the same new prop: this disc is a 50pt circle on card white carrying
  `Kati.Theme.shadow_card_soft/0`, and the shadow was the one thing about it
  the component could not say. `:circle` gives an exact 25.0 where the markup
  said 25, and `corner_radius` is read with `floatProp` (`MobBridge.kt:3887`),
  so the two are the same number.

  Node for node the component builds `Box{width: 50, height: 50,
  align: :center, corner_radius: 25.0, background: 0xFFFBFAF8, shadow: …,
  on_tap: {pid, :toggle_save}}` around `Row{} > Text{glyph}`, against the
  markup's identical Box around `Text{glyph}` — the difference is the bare
  `Row`, which carries no width, no padding and no background, and which
  `more/0` has been drawing against the captured frames since the last pass.

  `saved` keeps filling the glyph, because the glyph is a **child**: the
  component's own `icon` path would build a plain `Text` in Plus Jakarta Sans,
  and a Material Symbol exists only in the `symbols` face.
  """
  def save(saved?) do
    MishkaActionIcon.action_icon(
      %{
        size: 50,
        shape: :circle,
        variant: :filled,
        background: Palette.card(),
        shadow: Kati.Theme.shadow_card_soft(),
        on_tap: :toggle_save
      },
      [UI.symbol("bookmark", size: 21, fill: saved?)]
    )
  end

  @doc false
  def episodes_header(series) do
    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={26} />
      <Row fill_width={true} align="center" padding_left={2} padding_right={2}>
        <Box width={13} height={2} corner_radius={1} background={Palette.accent()} />
        <Spacer size={9} />
        <Text text="قسمت‌ها" font_family="fa" font_weight="semibold" text_size={11} text_color={Palette.eyebrow()} />
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
  # ## Still not `Kati.Components.MishkaChip`, and the gap has narrowed to one
  # thing
  #
  # Re-checked this round. The shape wall is **gone**: `MishkaChip` now takes
  # `width`, `height`, `corner_radius`, `padding_x` / `padding_y`, `text_size`
  # and `align`, so a declared 32x28 on a radius of 10 is sayable, and
  # `padding_y: 0` keeps the 28 from becoming 44.
  #
  # What is left is the label, and it is the same wall it always was: these
  # pills read ۱, ۲, ۳ — U+06F1..U+06F3, **Persian** digits, not ASCII — and
  # `MishkaChip` builds its own `Text` out of `label`, with no `font_family` to
  # put on it. `kati_sans_400.ttf` carries zero code points in U+0600-U+06FF,
  # so each pill would draw a blank box rather than fall back.
  #
  # The fix is not `font_family` on the chip. It is the **content slot** its
  # siblings already have: `MishkaPill.pill/2` and `MishkaToggle.toggle/2` both
  # take children that replace `label`, and `MishkaThemeIcon` and
  # `MishkaActionIcon` take children that replace `icon` — which is exactly why
  # `check/1`, `save/1` and `more/0` above are components and this is not.
  # `MishkaChip.expand/3` is `def expand(props, _children, _ctx)`: it discards
  # them. One slot would close this, 57's chips and 62's theme segments at
  # once, and it needs no new typography prop at all.
  #
  # Not `MishkaPill` either, and not because it cannot: it takes children, and
  # `pill(%{width: 32, height: 28, corner_radius: 10, padding: 0, align:
  # :center, background: bg, on_tap: tag}, [persian_text])` draws this pill.
  # It is the wrong component. Its own moduledoc draws the line — "a Chip is
  # selected, a Pill is removed… If you find yourself giving a pill a checked
  # state, you want MishkaChip" — and these three pills are a selection: one is
  # lit, tapping another moves the light, none of them can be dismissed.
  # Reaching for the removable-token component to dodge a missing slot in the
  # selectable one would hide the upstream signal in the one place it is worth
  # reading.
  @doc false
  def season_pill(label, index, on?) do
    tap = {self(), String.to_atom("season_" <> Integer.to_string(index))}
    bg = if on?, do: Palette.ink_fill(), else: Palette.placeholder()
    fg = if on?, do: Palette.on_ink(), else: Palette.meta()

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
    bg = if ep.watched, do: Palette.card_settled(), else: Palette.card()
    shadow = if ep.watched, do: nil, else: Kati.Theme.shadow_card_soft()
    title_color = if ep.watched, do: Palette.settled_ink(), else: Palette.ink()

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
          <Text text={ep.n} font_family="fa" text_size={12} text_color={Palette.tertiary()} max_lines={1} />
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
          <Text text={ep.sub} font_family="fa" text_size={11} text_color={Palette.tertiary()} max_lines={1} />
        </Column>
        <Spacer size={13} />
        {Kati.Screens.SeriesFa.check(ep.watched)}
      </Row>
      <Spacer size={8} />
    </Column>
    """
  end

  @doc """
  The episode ring, as `Kati.Components.MishkaThemeIcon`.

  Both states are one 27pt container, one 14pt radius, one 1.5pt ring and one
  glyph — which is the component's own definition of itself, "a themed
  container around exactly one icon". Two props that did not exist before this
  round make it reachable: `radius` takes a **number**, so 14 is sayable where
  a two-value `shape` enum could only offer `:radius_md` or `size / 2`; and
  `border_color` / `border_width` override the variant's choice, which is the
  whole of what distinguishes the empty ring from the filled one.

  Given no `id` the component adds no wrapper — `markers(nil, …)` returns the
  icon untouched — so `theme_icon/2` builds the *same map* the sigil did:

      %{type: :box,
        props: %{width: 27, height: 27, align: :center, corner_radius: 14,
                 background: 0xFF1A1917, border_color: 0xFF1A1917,
                 border_width: 1.5},
        children: [check_glyph]}

  `align` is the atom `:center` rather than the string, and `:json.encode/1`
  renders an atom as a JSON string, which is what `boxAlignProp`
  (`MobBridge.kt:4298`) reads.

  The empty ring takes `variant: :subtle`, whose skin is `background: nil`, and
  `put_some/3` drops a `nil` rather than writing it — so that node carries no
  `background` key at all, exactly as the markup carried none. A `:filled`
  variant with a transparent colour would have written one.
  """
  def check(true) do
    MishkaThemeIcon.theme_icon(
      %{
        variant: :filled,
        color: Palette.ink_fill(),
        size: 27,
        radius: 14,
        border_color: Palette.ink_fill(),
        border_width: 1.5
      },
      [UI.symbol("check", size: 16, color: Palette.on_ink())]
    )
  end

  # The empty ring, with the drawing's own zero-alpha glyph inside it so the
  # ring's inner box measures the same as the filled one. It stays a child, so
  # the zero alpha is preserved verbatim — the component's `icon` shorthand
  # would have retinted it from the variant.
  def check(false) do
    MishkaThemeIcon.theme_icon(
      %{
        variant: :subtle,
        size: 27,
        radius: 14,
        border_color: Palette.border(),
        border_width: 1.5
      },
      [UI.symbol("check", size: 16, color: Palette.ink_invisible())]
    )
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
