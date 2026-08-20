defmodule Kati.Screens.TodayFa do
  @moduledoc """
  Screen 59 — امروز, the Persian mirror of the meals Today screen.

  Built to `.scratch/design/screens/59.html`. Pushed under سلامت (Health), so
  there is no dock and the frame's bottom inset is **40, not 132**.

  ## Why this draws its own back pill

  `Kati.Screens.Pushed` floats a `arrow_back_ios_new` pill over the content and
  takes its direction from `Kati.Locale`. This drawing does neither: the pill is
  the first item in the scrolling column, opposite a 44pt week disc, and its
  chevron is `arrow_forward_ios` — back points the way the reader came from,
  which in Persian is rightwards. A mirrored screen that keeps the left-pointing
  chevron is the single most common RTL bug, so the glyph is part of the
  screen's own chrome rather than something inherited.

  ## Direction is a literal here, not a lookup

  `layout_direction="rtl"` is hard-coded. The copy in `Kati.Fa.SampleToday` is
  Persian, so this screen is only ever right-to-left; reading the direction from
  `Kati.Locale.current/0` would let an `:en` locale render Persian text
  left-to-left-aligned, which is worse than wrong, it is unreadable. Only
  `MainActivity` acts on the prop, and only on the root node — hence the outer
  `Box`.

  ## What `padding_left` means on this screen

  The bridge maps `padding_left` to Compose's **start** and `padding_right` to
  **end** (`MobBridge.kt:3944`), so under RTL `padding_left` is the physical
  *right* edge. Read them as leading/trailing: `padding_left` is the space
  before the first child, whichever side the reader starts on.

  ## Where this diverges from the drawing

    * The skipped meal's `1.5px dashed` border is drawn **solid** at the same
      colour. `Modifier.border` through this bridge takes a width and a colour
      and no dash pattern, and a dashed rule is not worth a `Canvas` node here.
    * The accent rule on the dinner card is `align-self: stretch` in the design
      and a declared 52 here — the card's height is set by its 52pt thumbnail,
      and nothing on this bridge reports geometry back to `render/1`.
  """
  use Mob.Screen
  import Mob.Sigil

  alias Kati.Design.Images
  alias Kati.Fa.SampleToday
  alias Kati.Theme

  def mount(_params, _session, socket) do
    Mob.Theme.set(Kati.Theme.light())
    {:ok, Mob.Socket.assign(socket, :day, SampleToday.day())}
  end

  def render(assigns) do
    day = assigns.day

    ~MOB"""
    <Box fill_width={true} fill_height={true} background={:background} layout_direction="rtl">
      <Scroll>
        <Column fill_width={true} padding_left={21} padding_right={21} padding_top={64} padding_bottom={40}>
          {Kati.Screens.TodayFa.header(day)}
          {Kati.Screens.TodayFa.title(day)}
          {Kati.Screens.TodayFa.quick(day)}
          {Kati.Screens.TodayFa.eyebrow(day.calories)}
          {Kati.Screens.TodayFa.macros(day)}
          {Kati.Screens.TodayFa.timeline(day)}
          {Kati.Screens.TodayFa.eyebrow(day.prep_label)}
          {Kati.Screens.TodayFa.prep(day)}
        </Column>
      </Scroll>
    </Box>
    """
  end

  @doc false
  def header(day) do
    back = {self(), :back}

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Row
          height={44}
          corner_radius={22}
          background={Theme.card(:light)}
          shadow={Theme.shadow_button()}
          padding_left={12}
          padding_right={16}
          align="center"
          on_tap={back}
        >
          {Kati.UI.symbol("arrow_forward_ios", size: 17)}
          <Spacer size={6} />
          <Text
            text={day.back}
            font_family="fa"
            text_size={13.5}
            font_weight="semibold"
            text_color={:on_surface}
            max_lines={1}
          />
        </Row>
        <Spacer weight={1.0} />
        <Box
          width={44}
          height={44}
          corner_radius={22}
          background={Theme.card(:light)}
          shadow={Theme.shadow_button()}
          align="center"
        >
          {Kati.UI.symbol("calendar_view_week", size: 21)}
        </Box>
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  # `align="bottom"`: the drawing aligns the plan pill with the subtitle's
  # baseline, not with the 27pt heading above it.
  @doc false
  def title(day) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="bottom">
        <Column>
          <Text
            text={day.title}
            font_family="fa"
            text_size={27}
            font_weight="bold"
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={5} />
          <Text
            text={day.subtitle}
            font_family="fa"
            text_size={11.5}
            text_color={0xFFA9A29A}
            max_lines={1}
          />
        </Column>
        <Spacer weight={1.0} />
        <Spacer size={12} />
        {Kati.Screens.TodayFa.plan_pill(day)}
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

  # Orange for the dot is legitimate here: it marks the plan that is running
  # now, which is exactly what the accent is reserved for.
  @doc false
  def plan_pill(day) do
    ~MOB"""
    <Row
      height={36}
      corner_radius={18}
      background={Theme.card(:light)}
      shadow={Theme.shadow_button()}
      padding_left={13}
      padding_right={13}
      align="center"
    >
      <Box width={7} height={7} corner_radius={4} background={Theme.accent()} />
      <Spacer size={7} />
      <Text
        text={day.plan}
        font_family="fa"
        text_size={12.5}
        font_weight="bold"
        text_color={:on_surface}
        max_lines={1}
      />
      <Spacer size={7} />
      {Kati.UI.symbol("unfold_more", size: 16, color: 0xFF8A8479)}
    </Row>
    """
  end

  @doc false
  def quick(day) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        {day.quick
         |> Enum.map(fn {icon, label} -> Kati.Screens.TodayFa.quick_tile(icon, label) end)
         |> Enum.intersperse(Kati.Screens.TodayFa.quick_gap())}
      </Row>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def quick_gap, do: ~MOB"<Spacer size={8} />"

  @doc false
  def quick_tile(icon, label) do
    ~MOB"""
    <Box weight={1.0}>
      <Column
        fill_width={true}
        background={Theme.card(:light)}
        corner_radius={16}
        shadow={Theme.shadow_card_soft()}
        padding_left={8}
        padding_right={8}
        padding_top={11}
        padding_bottom={11}
      >
        <Box fill_width={true} align="center">
          {Kati.UI.symbol(icon, size: 18)}
        </Box>
        <Spacer size={7} />
        <Text
          text={label}
          font_family="fa"
          text_size={11}
          font_weight="semibold"
          text_color={0xFF5C574F}
          text_align="center"
          max_lines={1}
        />
      </Column>
    </Box>
    """
  end

  @doc """
  The section label, in Persian.

  `Kati.UI.eyebrow/2` is DM Mono, uppercased and letter-spaced. Persian has no
  case, Vazirmatn is the face the drawing uses, and `letter-spacing:0` is
  written on every one of these labels — tracking Persian apart breaks the
  joins between letters. Same accent dash, different type.
  """
  def eyebrow(label) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_left={2} padding_right={2}>
        <Box width={13} height={2} corner_radius={1} background={Theme.accent()} />
        <Spacer size={9} />
        <Text
          text={label}
          font_family="fa"
          text_size={11}
          font_weight="semibold"
          text_color={0xFFA0998F}
        />
      </Row>
      <Spacer size={11} />
    </Column>
    """
  end

  # ## Not `Kati.Components.MishkaMeter`
  #
  # A segmented value bar looks like the meter's job, and it is not: a meter is
  # *one* fill along a track, and this is three abutting fills in three colours
  # that together span the whole 9pt trough. There is no prop for a second
  # segment, and stacking three meters would stack three tracks.
  #
  # It could not draw even one of them. `MishkaMeter` delegates to
  # `MishkaProgress`, which renders Mob's native `Progress`; `MobBridge.kt:2980`
  # hands that to Material 3 1.2.0's `LinearProgressIndicator`, whose modifier
  # chain ends `.size(240.dp, 4.dp)` — after the caller's — so the bar is
  # always 240 wide and 4 tall whatever the card's width and the design's 9 say.
  # `Kati.Screens.LibraryFa.progress/1` records the rest of it.
  @doc false
  def macros(day) do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Theme.card(:light)}
        corner_radius={20}
        shadow={Theme.shadow_card_soft()}
        padding={15}
      >
        <Box fill_width={true} height={9} corner_radius={5} background={0xFFEFECE7}>
          <Row fill_width={true}>
            {Enum.map(day.macros, fn m -> Kati.Screens.TodayFa.macro_segment(m) end)}
          </Row>
        </Box>
        <Spacer size={11} />
        <Row fill_width={true} align="center">
          {day.macros
           |> Enum.map(fn m -> Kati.Screens.TodayFa.macro_key(m) end)
           |> Enum.intersperse(Kati.Screens.TodayFa.macro_gap())}
          <Spacer weight={1.0} />
          <Text
            text={day.remaining}
            font_family="fa"
            text_size={10}
            text_color={0xFFA9A29A}
            max_lines={1}
          />
        </Row>
      </Column>
      <Spacer size={20} />
    </Column>
    """
  end

  # No corner radius on the segments: they sit inside a rounded, clipped
  # track, so the ends are shaped by the container and the joins stay square.
  @doc false
  def macro_segment(macro) do
    ~MOB"""
    <Box weight={macro.share} height={9} background={macro.color} />
    """
  end

  @doc false
  def macro_gap, do: ~MOB"<Spacer size={13} />"

  @doc false
  def macro_key(macro) do
    ~MOB"""
    <Row align="center">
      <Box width={7} height={7} corner_radius={2} background={macro.color} />
      <Spacer size={5} />
      <Text text={macro.label} font_family="fa" text_size={10} text_color={0xFFA0998F} max_lines={1} />
    </Row>
    """
  end

  @doc false
  def timeline(day) do
    ~MOB"""
    <Column fill_width={true}>
      {Enum.map(day.meals, fn meal -> Kati.Screens.TodayFa.meal(meal) end)}
    </Column>
    """
  end

  @doc false
  def meal(meal) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        <Column width={44} padding_top={Kati.Screens.TodayFa.gutter_top(meal.state)}>
          <Text
            text={meal.time}
            font_family="mono"
            text_size={12}
            font_weight={Kati.Screens.TodayFa.gutter_weight(meal.state)}
            text_color={Kati.Screens.TodayFa.gutter_color(meal.state)}
            max_lines={1}
          />
        </Column>
        <Spacer size={12} />
        <Box weight={1.0}>
          {Kati.Screens.TodayFa.meal_card(meal)}
        </Box>
      </Row>
      <Spacer size={9} />
    </Column>
    """
  end

  @doc false
  def gutter_top(:next), do: 17
  def gutter_top(_), do: 15

  @doc false
  def gutter_weight(:next), do: "medium"
  def gutter_weight(_), do: nil

  @doc false
  def gutter_color(:next), do: 0xFF1A1917
  def gutter_color(_), do: 0xFFA9A29A

  @doc false
  def meal_card(%{state: :next} = meal) do
    ~MOB"""
    <Column
      fill_width={true}
      background={Theme.card(:light)}
      corner_radius={18}
      shadow="0 1 2 0 #0D1A1917 | 0 16 30 -18 #BF1A1917"
      padding={14}
    >
      <Row fill_width={true} align="center">
        <Box width={3} height={52} corner_radius={2} background={Theme.accent()} />
        <Spacer size={12} />
        {Kati.Screens.TodayFa.thumb(meal.seed, 52, 13)}
        <Spacer size={12} />
        <Column weight={1.0}>
          <Text text={meal.label} font_family="fa" text_size={10.5} font_weight="semibold" text_color={0xFFA0998F} max_lines={1} />
          <Spacer size={4} />
          <Text text={meal.title} font_family="fa" text_size={14.5} font_weight="bold" text_color={:on_surface} max_lines={1} />
          <Spacer size={4} />
          <Text text={meal.sub} font_family="fa" text_size={11} text_color={0xFFA9A29A} max_lines={1} />
        </Column>
        <Spacer size={12} />
        <Box width={32} height={32} corner_radius={16} border_color={0x291A1917} border_width={1.5} align="center">
          {Kati.UI.symbol("check", size: 19, color: 0x381A1917)}
        </Box>
      </Row>
      <Spacer size={13} />
      <Row fill_width={true} align="center" padding_left={15}>
        <Row height={34} corner_radius={17} background={Theme.ink()} padding_left={14} padding_right={14} align="center">
          <Text text={meal.eat} font_family="fa" text_size={12} font_weight="semibold" text_color={0xFFFBFAF8} max_lines={1} />
        </Row>
        <Spacer size={8} />
        <Row height={34} corner_radius={17} background={0xFFEFECE7} padding_left={14} padding_right={14} align="center">
          <Text text={meal.swap} font_family="fa" text_size={12} font_weight="semibold" text_color={0xFF5C574F} max_lines={1} />
        </Row>
      </Row>
    </Column>
    """
  end

  def meal_card(%{state: :skipped} = meal) do
    ~MOB"""
    <Row
      fill_width={true}
      corner_radius={18}
      border_color={0x241A1917}
      border_width={1.5}
      padding_left={13}
      padding_right={13}
      padding_top={11}
      padding_bottom={11}
      align="center"
    >
      <Column weight={1.0}>
        <Text text={meal.label} font_family="fa" text_size={10.5} font_weight="semibold" text_color={0xFFC4BDB3} max_lines={1} />
        <Spacer size={4} />
        <Text text={meal.title} font_family="fa" text_size={13} font_weight="semibold" text_color={0xFFB3ACA2} max_lines={1} />
        <Spacer size={4} />
        <Text text={meal.sub} font_family="fa" text_size={11} text_color={0xFFC4BDB3} max_lines={1} />
      </Column>
      <Spacer size={12} />
      <Box width={27} height={27} corner_radius={16} border_color={0x291A1917} border_width={1.5} align="center">
        {Kati.UI.symbol("close", size: 16, color: 0xFFC4BDB3)}
      </Box>
    </Row>
    """
  end

  def meal_card(meal) do
    ~MOB"""
    <Row
      fill_width={true}
      background={0xFFF4F1EC}
      corner_radius={18}
      padding_left={13}
      padding_right={13}
      padding_top={11}
      padding_bottom={11}
      align="center"
    >
      {Kati.Screens.TodayFa.thumb(meal.seed, 40, 11)}
      <Spacer size={12} />
      <Column weight={1.0}>
        <Text text={meal.label} font_family="fa" text_size={10.5} font_weight="semibold" text_color={0xFFA0998F} max_lines={1} />
        <Spacer size={4} />
        <Text text={meal.title} font_family="fa" text_size={13} font_weight="semibold" text_color={0xFF9C958B} max_lines={1} />
        <Spacer size={4} />
        <Text text={meal.sub} font_family="fa" text_size={11} text_color={0xFFA9A29A} max_lines={1} />
      </Column>
      <Spacer size={12} />
      <Box
        width={27}
        height={27}
        corner_radius={16}
        background={Theme.green()}
        border_color={Theme.green()}
        border_width={1.5}
        align="center"
      >
        {Kati.UI.symbol("check", size: 16, color: 0xFFFBFAF8)}
      </Box>
    </Row>
    """
  end

  # The design's own photograph, not a tinted rectangle. A missing file leaves
  # the drawing's #E4E0D9 well behind, which is what the export shows before
  # its image slots resolve.
  #
  # This is `Kati.Components.MishkaAvatar`'s shape — image over a coloured
  # fallback — and `Kati.Screens.SettingsFa.avatar/1` adopts it for the round
  # face. Not here: the avatar's radius comes from `shape`, and its `:rounded`
  # is a hard-coded 10 with no prop to name one. Both call sites on this screen
  # pass a radius the component cannot say (13 for the 52pt thumb, 11 for the
  # 40pt one).
  @doc false
  def thumb(seed, size, radius) do
    case Images.poster(seed) do
      nil ->
        ~MOB"""
        <Box width={size} height={size} corner_radius={radius} background={0xFFE4E0D9} />
        """

      src ->
        ~MOB"""
        <Image src={src} width={size} height={size} corner_radius={radius} content_mode="fill" />
        """
    end
  end

  @doc false
  def prep(day) do
    ~MOB"""
    <Row fill_width={true} background={Theme.cream(:light)} corner_radius={20} padding={16} align="center">
      {Kati.UI.symbol("schedule", size: 20, color: 0xFFC98A3E)}
      <Spacer size={12} />
      <Column weight={1.0}>
        <Text text={day.prep.title} font_family="fa" text_size={13} font_weight="bold" text_color={:on_surface} />
        <Spacer size={4} />
        <Text text={day.prep.sub} font_family="fa" text_size={11.5} text_color={0xFF8A7B60} max_lines={1} />
      </Column>
    </Row>
    """
  end

  def handle_info({:tap, :back}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}
  def handle_info(_message, socket), do: {:noreply, socket}
end
