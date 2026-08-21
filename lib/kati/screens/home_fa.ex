defmodule Kati.Screens.HomeFa do
  @moduledoc """
  Screen 55 — Home in Persian.

  Built to `.scratch/design/screens/55.html`. The same page as screen 01 and
  the same numbers — the `64px 21px 132px` frame, 44pt header discs, the 52pt
  search bar at radius 26, the cream card at radius 24, two continue-watching
  cards, three section tiles, and the rest-of-today card with its
  `rgba(26,25,23,.07)` hairline — laid out start-to-end in a root that
  declares `rtl`, so every one of them mirrors without being rewritten.

  ## What mirroring does not do on its own

  Three things in this page are decisions rather than consequences:

    * **The type changes face.** The date line is Vazirmatn 11.5/500 where 01
      sets DM Mono 11 in caps; the eyebrows are Vazirmatn 11/600 with no
      tracking where 01 sets mono at .16em. Persian has no case to raise and
      the mono face has no Persian, so uppercasing a translated eyebrow would
      have produced nothing legible. See `Kati.Screens.Fa`.
    * **The arrow turns round.** The primary button's glyph is `arrow_back` —
      the drawing names it — because forward in Persian points left.
    * **The poster stack overlaps leftward.** The drawing pulls each poster
      with `margin-right:-16px`, the mirror of 01's `margin-left`. Negative
      padding is fatal in Compose, so the stack is a fixed 106pt box with each
      poster offset 30 — and `Modifier.offset` is direction-aware, so the same
      arithmetic that stacks rightward in English stacks leftward here.

  The header disc, the hero button and the notification bell reach the English
  inbox: 05 has no Persian mirror in the export yet, and a dead button reads as
  a bug where an untranslated screen reads as unfinished, which is the truth.
  """
  use Mob.Screen
  import Mob.Sigil

  alias Kati.Components.MishkaProgress
  alias Kati.Screens.Fa
  alias Kati.Screens.HomeFa.Sample
  alias Kati.Theme
  alias Kati.Theme.Palette
  alias Kati.UI

  def mount(_params, _session, socket) do
    Kati.Theme.activate()

    socket
    |> Mob.Socket.assign(:moment, Sample.moment())
    |> Mob.Socket.assign(:inbox, Sample.inbox())
    |> then(&{:ok, &1})
  end

  def render(assigns) do
    Fa.frame(:home, Kati.Screens.HomeFa.content(assigns.moment, assigns.inbox))
  end

  @doc false
  def content(moment, inbox) do
    ~MOB"""
    <Scroll>
      <Column fill_width={true} padding_left={21} padding_right={21} padding_top={64} padding_bottom={132}>
        {Kati.Screens.HomeFa.header(moment)}
        {Kati.Screens.HomeFa.search()}
        {Fa.eyebrow("تازه‌های این هفته")}
        {Kati.Screens.HomeFa.hero(inbox)}
        {Fa.eyebrow("ادامه تماشا")}
        {Kati.Screens.HomeFa.continue()}
        {Fa.eyebrow("بخش‌ها")}
        {Kati.Screens.HomeFa.sections()}
        {Fa.eyebrow("باقی امروز")}
        {Kati.Screens.HomeFa.rest_of_today()}
      </Column>
    </Scroll>
    """
  end

  @doc false
  def header(moment) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        <Column weight={1.0}>
          <Text
            text={moment.date}
            font_family="fa"
            font_weight="medium"
            text_size={11.5}
            text_color={Palette.muted()}
            max_lines={1}
          />
          <Spacer size={7} />
          <Text
            text={moment.greeting}
            font_family="fa"
            font_weight="bold"
            text_size={27}
            text_color={:on_surface}
          />
        </Column>
        {Fa.disc("notifications", :open_inbox)}
        <Spacer size={9} />
        {Fa.disc("calendar_month", :open_calendar)}
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc false
  def search do
    tap = {self(), :open_search}

    ~MOB"""
    <Column fill_width={true}>
      <Box
        fill_width={true}
        height={52}
        background={Palette.card()}
        corner_radius={26}
        shadow={Kati.Theme.shadow_card_soft()}
        padding_left={18}
        padding_right={18}
        on_tap={tap}
      >
        <Row fill_width={true} fill_height={true} align="center">
          {UI.symbol("search", size: 20, color: Palette.muted())}
          <Spacer size={11} />
          <Text
            text="جست‌وجوی فیلم، سریال، رویداد…"
            font_family="fa"
            text_size={14}
            text_color={Palette.muted()}
            weight={1.0}
            max_lines={1}
          />
          <Spacer size={11} />
          {UI.symbol("tune", size: 19)}
        </Row>
      </Box>
      <Spacer size={26} />
    </Column>
    """
  end

  @doc false
  def hero(inbox) do
    tap = {self(), :open_inbox}

    ~MOB"""
    <Column fill_width={true}>
      <Box
        fill_width={true}
        background={Palette.cream()}
        corner_radius={24}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={19}
      >
        <Column fill_width={true}>
          <Row fill_width={true} align="top">
            <Column weight={1.0}>
              <Text
                text={inbox.headline}
                font_family="fa"
                font_weight="bold"
                text_size={20}
                line_height={1.45}
                text_color={:on_surface}
              />
              <Spacer size={8} />
              <Text
                text={inbox.line}
                font_family="fa"
                text_size={12.5}
                line_height={1.6}
                text_color={Palette.cream_sub()}
              />
            </Column>
            <Spacer size={14} />
            {Kati.Screens.HomeFa.poster_stack(inbox.seeds)}
          </Row>
          <Spacer size={17} />
          <Row align="center">
            <Row
              height={40}
              corner_radius={20}
              background={Palette.ink_fill()}
              padding_left={18}
              padding_right={18}
              align="center"
              on_tap={tap}
            >
              <Text
                text={inbox.action}
                font_family="fa"
                font_weight="semibold"
                text_size={13}
                text_color={Palette.on_ink()}
                max_lines={1}
              />
              <Spacer size={7} />
              {UI.symbol("arrow_back", size: 17, color: Palette.on_ink())}
            </Row>
            <Spacer size={10} />
            <Text text={inbox.checked} font_family="fa" text_size={11} text_color={Palette.cream_meta()} max_lines={1} />
          </Row>
        </Column>
      </Box>
      <Spacer size={26} />
    </Column>
    """
  end

  # 46*3 - 16*2 = 106 wide, whichever way the page reads.
  #
  # `align="center"` on the poster is load-bearing: `border_width` paints the
  # 2pt frame over the box's own edge without insetting its child, and a Box
  # aligns TOP-START, so the 42x60 still landed against the start edge and the
  # cream frame measured 2pt at the top-start corner and 4pt at the bottom-end
  # one. The drawing's frame is 2pt on all four sides.
  @doc false
  def poster_stack(seeds) do
    ~MOB"""
    <Box width={106} height={64}>
      {seeds |> Enum.with_index() |> Enum.map(fn {seed, i} -> Kati.Screens.HomeFa.poster(seed, i) end)}
    </Box>
    """
  end

  @doc false
  def poster(seed, index) do
    offset = index * 30
    src = Kati.Design.Images.poster(seed)

    ~MOB"""
    <Box
      width={46}
      height={64}
      offset_x={offset}
      corner_radius={9}
      background={Palette.poster_on_cream()}
      border_width={2}
      border_color={Palette.cream()}
      shadow={Kati.Theme.shadow_poster()}
      align="center"
    >
      {Kati.Screens.HomeFa.poster_image(src)}
    </Box>
    """
  end

  @doc false
  def poster_image(nil), do: ~MOB"<Spacer size={0} />"

  def poster_image(src) do
    ~MOB"""
    <Image src={src} width={42} height={60} corner_radius={7} content_mode="fill" />
    """
  end

  @doc false
  def continue do
    [first, second] = Sample.continue()

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        {Kati.Screens.HomeFa.watch_card(first)}
        <Spacer size={13} />
        {Kati.Screens.HomeFa.watch_card(second)}
      </Row>
      <Spacer size={26} />
    </Column>
    """
  end

  @doc """
  One continue-watching card, with its 4pt elapsed bar drawn by
  `Kati.Components.MishkaProgress` in `render={:box}` mode.

  ## Why the pixels do not move

  Both trees serialise to the same nodes and the same props: a `fill_width`
  track `Box` at `height: 4`, `corner_radius: 2`, `background: 0xFFE7E3DC`; a
  `fill_width` `Row`; a fill `Box` carrying `weight: 0.62`, the same height and
  radius and the ink; and `<Spacer weight={0.38} />`. The component adds one
  node the markup did not have — a trailing `<Spacer size={4} />` inside the
  track, the iOS height workaround its moduledoc explains — which carries no
  background and sits inside a Box already pinned to
  `fillMaxWidth().height(4.dp)`, so it draws nothing and moves nothing.

  `max: 1` keeps the float exact: `fraction/1` divides by a span of 1 and hands
  back the same `0.62`, where `value: progress * 100` would round-trip to
  `0.6200000000000001`.

  ## Under `rtl` it fills from the right, and that is the component's doing

  The drawn bar has **no hardcoded leading edge**. Its fill-width shape is a
  Compose `Row`, which lays children out start-to-end, and `Kati.Screens.Fa`'s
  frame provides `LocalLayoutDirection = Rtl` from the root
  (`MainActivity.kt:245`), so the fill starts at the right and the remainder
  `Spacer` takes the left. That is the same thing the hand-rolled `Row` did.
  Nothing here reverses the array to fake it, and nothing needed to: the
  fixed-`width` shape is direction-aware too, because the bridge's
  `boxAlignProp` falls through to `Alignment.TopStart` — the resolving
  alignment, not `TopLeft`.

  ## Both ends

  `0.0` and `1.0` are the two values the hand-rolled markup could not survive:
  they wrote `weight={0.0}` onto the fill and onto the remainder respectively,
  and Compose throws on a zero weight rather than warning. The component omits
  whichever node would carry the zero, so both ends draw — an empty track and a
  full one. Today's samples are `0.62` and `0.24`.
  """
  def watch_card(item) do
    progress = item.progress

    bar =
      MishkaProgress.progress(
        value: progress,
        max: 1,
        render: :box,
        height: 4,
        corner_radius: 2,
        track_color: Palette.track(),
        color: Palette.ink()
      )

    ~MOB"""
    <Box weight={1.0}>
      <Box
        fill_width={true}
        background={Palette.card()}
        corner_radius={20}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={11}
      >
        <Column fill_width={true}>
          <Box fill_width={true} height={112} corner_radius={12} background={Palette.placeholder()}>
            {Kati.Screens.HomeFa.still(item.seed)}
          </Box>
          <Spacer size={11} />
          <Text
            text={item.title}
            font_family="fa"
            font_weight="bold"
            text_size={14}
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={3} />
          <Text text={item.meta} font_family="fa" text_size={11} text_color={Palette.muted()} max_lines={1} />
          <Spacer size={10} />
          {bar}
        </Column>
      </Box>
    </Box>
    """
  end

  # The 520x384 crop, which is the photograph these cards draw — not the
  # poster of the same title scaled sideways.
  @doc false
  def still(seed) do
    case Kati.Design.Images.path(seed, {520, 384}) do
      nil ->
        ~MOB"<Spacer size={0} />"

      src ->
        ~MOB"""
        <Image src={src} fill_width={true} height={112} corner_radius={12} content_mode="fill" />
        """
    end
  end

  @doc false
  def sections do
    [meals, habits, settings] = Sample.sections()

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        {Kati.Screens.HomeFa.tile(meals)}
        <Spacer size={9} />
        {Kati.Screens.HomeFa.tile(habits)}
        <Spacer size={9} />
        {Kati.Screens.HomeFa.tile(settings)}
      </Row>
      <Spacer size={26} />
    </Column>
    """
  end

  @doc false
  def tile(section) do
    ~MOB"""
    <Box weight={1.0}>
      <Box
        fill_width={true}
        background={Palette.card()}
        corner_radius={18}
        shadow={Kati.Theme.shadow_card_soft()}
        padding_left={12}
        padding_right={12}
        padding_top={13}
        padding_bottom={13}
      >
        <Column fill_width={true}>
          <Row fill_width={true} align="center">
            {UI.symbol(section.icon, size: 19)}
            <Spacer weight={1.0} />
            {Kati.Screens.HomeFa.dot(section.dot)}
          </Row>
          <Spacer size={10} />
          <Text
            text={section.label}
            font_family="fa"
            font_weight="bold"
            text_size={12.5}
            text_color={:on_surface}
            max_lines={1}
          />
          {Kati.Screens.HomeFa.tile_meta(section.meta)}
        </Column>
      </Box>
    </Box>
    """
  end

  @doc false
  def dot(nil), do: ~MOB"<Spacer size={0} />"
  def dot(color), do: ~MOB"<Box width={6} height={6} corner_radius={3} background={color} />"

  @doc false
  def tile_meta(nil), do: ~MOB"<Spacer size={0} />"

  def tile_meta(meta) do
    ~MOB"""
    <Column>
      <Spacer size={3} />
      <Text text={meta} font_family="fa" text_size={10} text_color={Palette.muted()} max_lines={1} />
    </Column>
    """
  end

  @doc false
  def rest_of_today do
    rows = Sample.rest_of_today()
    last = length(rows) - 1

    ~MOB"""
    <Box
      fill_width={true}
      background={Palette.card()}
      corner_radius={20}
      shadow={Kati.Theme.shadow_card_soft()}
      padding_left={15}
      padding_right={15}
      padding_top={5}
      padding_bottom={5}
    >
      <Column fill_width={true}>
        {rows
         |> Enum.with_index()
         |> Enum.map(fn {row, i} -> Kati.Screens.HomeFa.timeline_row(row, i < last) end)}
      </Column>
    </Box>
    """
  end

  @doc false
  def timeline_row(row, rule?) do
    rule = if row.now?, do: Theme.accent(), else: Palette.rail_idle()

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_top={14} padding_bottom={14}>
        <Box width={42}>
          <Text text={row.time} font_family="fa" text_size={12} text_color={Palette.muted()} max_lines={1} />
        </Box>
        <Spacer size={14} />
        <Box width={3} height={34} corner_radius={2} background={rule} />
        <Spacer size={14} />
        <Column weight={1.0}>
          <Text
            text={row.title}
            font_family="fa"
            font_weight="semibold"
            text_size={13.5}
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={3} />
          <Text text={row.meta} font_family="fa" text_size={11.5} text_color={Palette.sub()} max_lines={1} />
        </Column>
      </Row>
      {Kati.Screens.HomeFa.hairline(rule?)}
    </Column>
    """
  end

  @doc """
  The `rgba(26,25,23,.07)` rule between two rows of the rest-of-today card.

  `Kati.Components.MishkaSeparator` rather than a hand-rolled `Box`: a rule
  between rows is exactly what a separator is, and here it is the same pixels
  one layer down — **with `render: :box`**, which is the whole of the
  correction below.

  ## `render: :box`, because the drawing asks for a filled rect

  55.html draws this rule as `border-bottom:1px solid rgba(26,25,23,.07)`. A
  CSS border is a filled rectangle: every pixel row it covers is the full
  colour. The separator's default `render: :divider` is not that. It emits
  `<Divider color thickness />`, which `MobBridge` hands to Material3's
  `HorizontalDivider` — a `Canvas` running an **antialiased `drawLine`**, not
  a background-filled `Box`. At this device's 2.6875x a 1dp rule gets a 3px
  canvas and a 2.6875px stroke, so the last pixel row lands at ~69% coverage:
  a full-width row 4-5/255 lighter than the two above it.

  So `:divider` was the one thing this adoption changed, and it changed it in
  the wrong direction — away from the `Box` that stood here before. `:box`
  puts that `Box` back: `separator(render: :box)` returns
  `%{type: :box, props: %{fill_width: true, height: 1, background: 0x121A1917},
  children: [%{type: :spacer, props: %{size: 1}}]}` — the node this file used
  to write out, at the drawing's own 1dp and its own alpha, plus one `Spacer`.

  That `Spacer` is an iOS workaround (`MobBox` drops a `height` on a childless
  full-width box, `IOS_TODO.md` item 1) and costs nothing on Android: it is a
  1x1 invisible child of a box whose own `height` already pins it and whose
  `background` is painted underneath it, so it can neither grow the box nor be
  seen inside it.

  Only the plain rule is adopted. The component's own docs record that the
  vertical and labelled variants are broken on iOS (`IOS_TODO.md` 11-13); this
  screen needs neither.

  Direction is not a question for it either way: a full-width horizontal rule
  is the one shape that looks the same in both directions, so the `rtl` root
  in `Kati.Screens.Fa.frame/2` passes straight through it.
  """
  def hairline(false), do: ~MOB"<Spacer size={0} />"

  def hairline(true) do
    Kati.Components.MishkaSeparator.separator(
      color: Palette.hairline(),
      thickness: 1,
      render: :box
    )
  end

  def handle_info({:tap, :open_inbox}, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Inbox)}

  def handle_info({:tap, :open_search}, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Search)}

  def handle_info({:tap, :open_calendar}, socket),
    do: {:noreply, Mob.Socket.reset_to(socket, Kati.Screens.ScheduleFa)}

  def handle_info({:tap, tag}, socket), do: Fa.dock_tap(tag, :home, socket)
  def handle_info(_message, socket), do: {:noreply, socket}
end
