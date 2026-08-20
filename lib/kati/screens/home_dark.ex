defmodule Kati.Screens.HomeDark do
  @moduledoc """
  Screen 28 — Home in dark.

  Built to `.scratch/design/screens/28.html`. Same page as screen 01, same
  `64px 21px 132px` frame, same order of parts — and deliberately **not** an
  inversion of it. The drawing's own caption states the rule this screen
  exists to prove:

    * paper becomes near-black `#121110`, not white flipped to black;
    * cards lift with an **inset hairline** — `rgba(245,242,238,.06)` — where
      light lifts them with a shadow, because a drop shadow on a dark ground
      is invisible and outlining is how depth reads there;
    * cream warms to a lit-lamp brown `#2A2622` and keeps an orange hairline,
      so "personal" still reads as warm rather than as another grey card;
    * the FAB inverts to paper-on-ink, since ink-on-ink would disappear.

  ## Why this draws its own dock instead of using `Kati.Shell`

  `Kati.Shell.render/1` takes a `mode`, but only two of its colours follow it.
  The inactive tab tint, the active tab's icon colour, the FAB's fill and its
  glyph are all light-mode literals, and the scrim is `Kati.UI.paper_fade/1`,
  which is `#EFECE7` — a light fade over a near-black page. Rendered through
  the shell, this screen's dock would be near-black icons on a near-black bar
  under a pale smear.

  So the dark dock is drawn here, from the drawing's own numbers, rather than
  the shell being bent to a mode it does not yet carry. When dark becomes a
  real mode, this dock is what `Kati.Shell` should grow — and this module
  should disappear into it.

  The tabs and the FAB are wired to the real roots and the real add sheet, so
  this is an entry point rather than a picture of one.
  """
  use Mob.Screen
  import Mob.Sigil

  alias Kati.Screens.HomeDark.Sample

  # The drawing's dark palette stays as literals at each point of use, the way
  # every other screen here writes colour. It is not lifted into `Kati.Theme`
  # because `Mob.Theme` carries one slot per role and this page needs three
  # different near-blacks — page `#121110`, card `#1E1D1B`, and the `#0E0D0C`
  # disc punched behind the active tab — plus a `rgba(245,242,238,.06)`
  # hairline standing in for the shadow the light theme uses.
  def mount(_params, _session, socket) do
    Mob.Theme.set(Kati.Theme.dark())
    {:ok, Mob.Socket.assign(socket, :moment, Sample.moment())}
  end

  def render(assigns) do
    moment = assigns.moment

    ~MOB"""
    <Box fill_width={true} fill_height={true} background={:background} layout_direction={Kati.Locale.direction_prop()}>
      <Scroll>
        <Column fill_width={true} padding_left={21} padding_right={21} padding_top={64} padding_bottom={132}>
          {Kati.Screens.HomeDark.header(moment)}
          {Kati.Screens.HomeDark.search()}
          {Kati.Screens.HomeDark.eyebrow("New this week")}
          {Kati.Screens.HomeDark.hero(moment)}
          {Kati.Screens.HomeDark.eyebrow("Continue watching")}
          {Kati.Screens.HomeDark.continue()}
          {Kati.Screens.HomeDark.eyebrow("Rest of today")}
          {Kati.Screens.HomeDark.rest_of_today()}
        </Column>
      </Scroll>
      {Kati.Screens.HomeDark.scrim()}
      {Kati.Screens.HomeDark.dock()}
    </Box>
    """
  end

  def handle_info({:tap, :inbox}, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Inbox)}

  def handle_info({:tap, :search}, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Search)}

  def handle_info({:tap, :fab}, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.AddTitle)}

  def handle_info({:tap, tag}, socket) do
    case Atom.to_string(tag) do
      "root_home" -> {:noreply, socket}
      "root_" <> id -> {:noreply, leave(socket, id)}
      _ -> {:noreply, socket}
    end
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  defp leave(socket, id) do
    target = String.to_existing_atom(id)
    Mob.Socket.reset_to(socket, Kati.Shell.screen_for(target))
  end

  @doc false
  def header(moment) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        <Column weight={1.0}>
          <Text
            text={String.upcase(moment.date)}
            font_family="mono"
            text_size={11}
            letter_spacing={0.14}
            text_color={0xFF6A6560}
          />
          <Spacer size={7} />
          <Text text={moment.greeting} text_size={28} font_weight="bold" letter_spacing={-0.03} text_color={0xFFF5F2EE} />
        </Column>
        {Kati.Screens.HomeDark.disc("notifications", :inbox)}
        <Spacer size={9} />
        {Kati.Screens.HomeDark.disc("calendar_month", :root_calendar)}
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc """
  A 44pt header disc — an inset ring, not a shadow.

  The drawing writes the lift as `inset 0 0 0 1px rgba(245,242,238,.06)`, and a
  border of that colour is the same pixel. That is why this disc waited:
  `Kati.Components.MishkaActionIcon` is exactly a round tap target holding one
  glyph, but it painted a fill and stopped, with no way to say *outlined*. It
  now takes `border_color` and `border_width`, which is the whole of what dark
  mode uses instead of a shadow.

  **The pixels are the same node.** The port builds

      <Box width={44} height={44} align={:center} corner_radius={22.0}
           background={0xFF1E1D1B} border_color={0x0FF5F2EE} border_width={1}
           on_tap=…><Row>{glyph}</Row></Box>

  which is this `Box` prop for prop: `shape: :circle` resolves to an exact
  `size / 2` so 44 gives 22, `variant: :filled` is what lets `background`
  through, and `align={:center}` serialises to the `"center"` string
  `MobBridge.boxAlignProp` reads. The border needs both keys to draw anything —
  the port omits `border_width` entirely unless `border_color` is set, which is
  the same condition the bridge applies. The added `Row` carries no props, takes
  no modifier and hugs its one child, so the glyph measures and centres as it
  did.
  """
  def disc(icon, tag) do
    Kati.Components.MishkaActionIcon.action_icon(
      [
        size: 44,
        shape: :circle,
        variant: :filled,
        background: 0xFF1E1D1B,
        border_color: 0x0FF5F2EE,
        border_width: 1,
        on_tap: {self(), tag}
      ],
      [Kati.UI.symbol(icon, size: 21, color: 0xFFF5F2EE)]
    )
  end

  @doc false
  def search do
    tap = {self(), :search}

    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        height={52}
        corner_radius={26}
        background={0xFF1E1D1B}
        border_width={1}
        border_color={0x0FF5F2EE}
        padding_left={18}
        padding_right={18}
        align="center"
        on_tap={tap}
      >
        {Kati.UI.symbol("search", size: 20, color: 0xFF6A6560)}
        <Spacer size={11} />
        <Text text="Search films, shows, events…" text_size={14.5} text_color={0xFF6A6560} weight={1.0} max_lines={1} />
        <Spacer size={11} />
        {Kati.UI.symbol("tune", size: 19, color: 0xFFF5F2EE)}
      </Row>
      <Spacer size={26} />
    </Column>
    """
  end

  # `Kati.UI.eyebrow/2` is the light one: its label is `#A0998F` against paper.
  # Dark drops the label to `#6A6560` and keeps the accent dash exactly, which
  # is the point — the dash is punctuation and does not change with the ground.
  @doc false
  def eyebrow(label) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_left={2} padding_right={2}>
        <Box width={13} height={2} corner_radius={1} background={0xFFE8823C} />
        <Spacer size={9} />
        <Text
          text={String.upcase(label)}
          font_family="mono"
          text_size={10.5}
          letter_spacing={0.16}
          text_color={0xFF6A6560}
        />
      </Row>
      <Spacer size={11} />
    </Column>
    """
  end

  # Cream, warmed rather than darkened, and ringed in 14%-alpha orange instead
  # of carrying the light card's shadow.
  @doc false
  def hero(moment) do
    inbox = Sample.inbox()
    tap = {self(), :inbox}

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={0xFF2A2622}
        corner_radius={24}
        border_width={1}
        border_color={0x24E8823C}
        padding={19}
      >
        <Row fill_width={true} align="top">
          <Column weight={1.0}>
            {Enum.map(inbox.headline, fn line -> Kati.Screens.HomeDark.headline(line) end)}
            <Spacer size={8} />
            <Text text={inbox.sub} text_size={13} line_height={1.45} text_color={0xFFA89B87} />
          </Column>
          <Spacer size={14} />
          {Kati.Screens.HomeDark.poster_stack(inbox)}
        </Row>
        <Spacer size={17} />
        <Row fill_width={true} align="center">
          <Row height={40} corner_radius={20} background={0xFFF7EFE4} padding_left={18} padding_right={18} align="center" on_tap={tap}>
            <Text text={inbox.cta} text_size={13.5} font_weight="semibold" text_color={0xFF1A1917} max_lines={1} />
            <Spacer size={7} />
            {Kati.UI.symbol("arrow_forward", size: 17, color: 0xFF1A1917)}
          </Row>
          <Spacer size={10} />
          <Text text={moment.last_check} font_family="mono" text_size={11} text_color={0xFF7A6F5E} max_lines={1} />
        </Row>
      </Column>
      <Spacer size={26} />
    </Column>
    """
  end

  @doc false
  def headline(line) do
    ~MOB"""
    <Text
      text={line}
      text_size={21}
      font_weight="bold"
      letter_spacing={-0.025}
      line_height={1.2}
      text_color={0xFFF7EFE4}
      max_lines={1}
    />
    """
  end

  # Three 46-wide posters overlapping leftward by 16 measure 106, not 138 —
  # `margin-left:-16px` shrinks the box as well as shifting the child, and
  # negative padding throws on Compose. Fixed 106 box, each poster offset 30.
  #
  # The drawing hangs the stack off a container with `padding-top:2px`, which
  # only moves the posters — the row is 96 tall and driven by the text beside
  # them — so it is reproduced as `offset_y` rather than as padding that would
  # also grow the box.
  @doc false
  def poster_stack(inbox) do
    ~MOB"""
    <Box width={106} height={64} offset_y={2}>
      {inbox.posters
       |> Enum.with_index()
       |> Enum.map(fn {seed, i} -> Kati.Screens.HomeDark.poster(seed, i) end)}
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
      background={0xFF3A342D}
      border_width={2}
      border_color={0xFF2A2622}
      shadow="0 4 10 -4 #99000000"
    >
      {Kati.Screens.HomeDark.poster_image(src)}
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
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        {Sample.continue()
         |> Enum.map(fn row -> Kati.Screens.HomeDark.watch_card(row) end)
         |> Enum.intersperse(Kati.Screens.HomeDark.card_gap())}
      </Row>
      <Spacer size={26} />
    </Column>
    """
  end

  @doc false
  def card_gap, do: ~MOB"<Spacer size={13} />"

  @doc false
  def watch_card(row) do
    ~MOB"""
    <Box weight={1.0}>
      <Column
        fill_width={true}
        background={0xFF1E1D1B}
        corner_radius={20}
        border_width={1}
        border_color={0x0FF5F2EE}
        padding={11}
      >
        {Kati.Screens.HomeDark.still(row)}
        <Spacer size={11} />
        <Text text={row.title} text_size={14.5} font_weight="bold" letter_spacing={-0.02} text_color={0xFFF5F2EE} max_lines={1} />
        <Spacer size={3} />
        <Text text={row.meta} font_family="mono" text_size={10.5} text_color={0xFF6A6560} max_lines={1} />
        <Spacer size={10} />
        <Box fill_width={true} height={4} corner_radius={2} background={0xFF312F2C}>
          <Row fill_width={true}>
            <Box weight={row.progress} height={4} corner_radius={2} background={0xFFF5F2EE} />
            <Spacer weight={1.0 - row.progress} />
          </Row>
        </Box>
      </Column>
    </Box>
    """
  end

  # The card wants the 520x384 crop, not the 400x600 poster — the design shot
  # each title at both sizes because a landscape still and a poster are
  # different photographs, not one scaled.
  @doc false
  def still(row) do
    case Kati.Design.Images.path(row.seed, {520, 384}) do
      nil ->
        ~MOB"<Box fill_width={true} height={112} corner_radius={12} background={0xFF2A2826} />"

      src ->
        ~MOB"""
        <Image src={src} fill_width={true} height={112} corner_radius={12} content_mode="fill" />
        """
    end
  end

  @doc false
  def rest_of_today do
    rows = Sample.rest_of_today()
    last = length(rows) - 1

    ~MOB"""
    <Column
      fill_width={true}
      background={0xFF1E1D1B}
      corner_radius={20}
      border_width={1}
      border_color={0x0FF5F2EE}
      padding_left={15}
      padding_right={15}
      padding_top={5}
      padding_bottom={5}
    >
      {rows
       |> Enum.with_index()
       |> Enum.map(fn {row, i} -> Kati.Screens.HomeDark.timeline_row(row, i < last) end)}
    </Column>
    """
  end

  @doc false
  def timeline_row(row, rule?) do
    rail = if row.now?, do: 0xFFE8823C, else: 0xFF4A453F

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_top={14} padding_bottom={14}>
        <Column width={40}>
          <Text text={row.time} font_family="mono" text_size={12} text_color={0xFF6A6560} max_lines={1} />
        </Column>
        <Spacer size={14} />
        <Box width={3} height={34} corner_radius={2} background={rail} />
        <Spacer size={14} />
        <Column weight={1.0}>
          <Text text={row.title} text_size={14} font_weight="semibold" text_color={0xFFF5F2EE} max_lines={1} />
          <Spacer size={3} />
          <Text text={row.meta} text_size={12} text_color={0xFF8A837B} max_lines={1} />
        </Column>
      </Row>
      {Kati.Screens.HomeDark.hairline(rule?)}
    </Column>
    """
  end

  @doc """
  The rule between two timeline rows — paper at 7% on near-black, not ink.

  `Kati.Components.MishkaSeparator` at `render: :box`, for the reason
  `Kati.Screens.Subscriptions.hairline/1` sets out at length: the port's default
  `render: :divider` emits `<Divider>`, Material 3 draws that as an antialiased
  `drawLine` inside a `height(thickness)` canvas, and at the capture device's
  2.6875x a 1dp stroke leaves the last of three device-pixel rows at 69%
  coverage where a filled `Box` gives 100%. The API always fitted this line;
  until `render: :box` existed the pixels did not.

  The node it builds is `<Box fill_width={true} height={1} background=…>` with a
  `<Spacer size={1} />` inside — the port's iOS height workaround. On Android
  `MobSpacer` is a background-less `Spacer(modifier.size(1.dp))` and the Box's
  `height(1.dp)` pins the box, so the child draws nothing and measures nothing.
  Same rule, one invisible node.
  """
  def hairline(false), do: ~MOB"<Spacer size={0} />"

  def hairline(true),
    do: Kati.Components.MishkaSeparator.separator(color: 0x12F5F2EE, render: :box)

  # A fade to the page colour, not to paper. `Kati.UI.paper_fade/1` is
  # `#EFECE7` and would draw a pale band across the bottom of a near-black page.
  @doc false
  def scrim do
    ~MOB"""
    <Box fill_width={true} fill_height={true} align="bottom">
      <Box fill_width={true} height={120} gradient="to_top #FF121110 42% #00121110" />
    </Box>
    """
  end

  @doc false
  def dock do
    ~MOB"""
    <Box fill_width={true} fill_height={true} align="bottom">
      <Row fill_width={true} align="center" padding_left={18} padding_right={18} padding_bottom={30}>
        <Box weight={1.0} height={64} background={0xEB1E1D1B} corner_radius={32} shadow={Kati.Theme.shadow_dock()} align="center">
          <Row fill_width={true} fill_height={true} align="center" padding_left={9} padding_right={9}>
            {Enum.map(Kati.Shell.roots(), fn root -> Kati.Screens.HomeDark.tab(root) end)}
          </Row>
        </Box>
        <Spacer size={11} />
        {Kati.Screens.HomeDark.fab()}
      </Row>
    </Box>
    """
  end

  @doc """
  The 64pt add button beside the dock, inverted to paper-on-ink.

  `Kati.Components.MishkaActionIcon`. The port's own docs put it plainly — *"a
  floating disc is defined by its shadow"* — and until it took a `shadow` prop
  it could draw a flat paper patch here and nothing else. `0 12 26 -10
  #CC1A1917` is what lifts the FAB off a near-black page, so it was the whole
  difference between the component and this button.

  **The pixels are the same node.** The port builds

      <Box width={64} height={64} align={:center} corner_radius={32.0}
           background={0xFFF5F2EE} shadow="0 12 26 -10 #CC1A1917"
           on_tap=…><Row>{glyph}</Row></Box>

  against the identical hand-rolled `Box`: `shape: :circle` is an exact
  `size / 2`, so 64 gives the drawing's 32; `variant: :filled` lets the paper
  fill through; `align={:center}` serialises to `"center"`; and the `shadow`
  string is handed to the container untouched, so `MobBridge`'s `shadowLayers`
  parses the same one layer. The extra `Row` has no props, hugs its one child
  and adds nothing to measure.
  """
  def fab do
    Kati.Components.MishkaActionIcon.action_icon(
      [
        size: 64,
        shape: :circle,
        variant: :filled,
        background: 0xFFF5F2EE,
        shadow: "0 12 26 -10 #CC1A1917",
        on_tap: {self(), :fab}
      ],
      [Kati.UI.symbol("add", size: 27, color: 0xFF16150F)]
    )
  end

  # The active disc is #0E0D0C — darker than the page, so it reads as a hole
  # punched through the bar rather than a highlight sitting on it. That is the
  # dark counterpart of the light dock's paper-coloured disc, and it is why the
  # shell's `Kati.Theme.paper(mode)` is not quite enough on its own.
  @doc false
  def tab(root) do
    on? = root.id == :home
    tint = if on?, do: 0xFFF5F2EE, else: 0xFF6A6560
    disc = if on?, do: 0xFF0E0D0C, else: 0x00FFFFFF
    tap = {self(), String.to_atom("root_#{root.id}")}

    ~MOB"""
    <Box weight={1.0} align="center" on_tap={tap}>
      <Box width={46} height={46} background={disc} corner_radius={23} align="center">
        {Kati.UI.symbol(root.icon, size: 22, color: tint, fill: on?)}
      </Box>
    </Box>
    """
  end
end
