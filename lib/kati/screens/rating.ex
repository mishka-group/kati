defmodule Kati.Screens.Rating do
  @moduledoc """
  Screen 33 — Log a watch: the rating, the review, and the context.

  Built to `.scratch/design/screens/33.html`. It carries its own dismissal —
  a `close` disc and a **Save** pill, not the pushed back pill — because it is
  a sheet you either commit or abandon, and a back arrow says neither. Screen
  06 is the precedent. No dock, so the frame closes at 40 rather than 132.

  The design's caption names what the screen is for: *"half stars, a 10-point
  alternative, a real review body with a spoiler toggle, and the context that
  makes a log worth keeping — where you were and who you were with."*

  ## The stars are glyphs, not characters

  The drawing prints the rating as literal text — `★★★★` at 30px, then a
  fifth `★` clipped to 50% width, and a scale toggle labelled `5★`. Plus
  Jakarta Sans carries no U+2605, so on the device those render as nothing at
  all: the defect screen 08 hit, and fixed the same way. Every star here is
  therefore the Material Symbols `star` glyph, which is definitely in Kati's
  subset — so `bin/check_screen.py` finds those three lines in this comment
  rather than in a `<Text>`, and that is the whole of the difference.

  ## The half star is outlined, not halved — the font has no half

  **The gap, stated:** Kati's icon subset carries `star` and nothing called
  `star_half`, and `Kati.Icons.glyph!/1` raises for a name the font does not
  have, so there is no half glyph to ask for. Closing this properly means
  adding `star_half` to the design's icon set, running `mix kati.gen.icons`,
  and re-running the pyftsubset step over the variable font — `lib/kati/icons.ex`
  and `priv/`, not this screen. Until then the half slot is the same `star`
  glyph at **FILL 0**: an outlined star in the accent, beside four filled ones
  and the printed 4.5. A fifth *filled* star would read as five, and rounding
  a rating up silently is the one thing a screen that exists to record ratings
  must not do.

  Cropping half a glyph — the drawing's own construction, a grey star with an
  orange one over it in a box half as wide — is not reachable from Elixir in
  this bridge. Every `Text` is built with `TextOverflow.Ellipsis` always on
  (`MobBridge.kt:2772`), and Compose coerces a child into its parent's
  constraints, so a 26sp glyph in a 13dp box is not cropped to half a star: it
  is *measured* at 13dp, becomes one unbreakable character too wide for its
  line, and is ellipsised away to nothing. `corner_radius` switches
  `Modifier.clip` on (`MobBridge.kt:3925`) but clip only governs painting, not
  measurement. The previous version fed the orange glyph through a horizontal
  `Scroll` — the one node here that measures its content unbounded — and still
  painted nothing on the device, which is what retired the construction: an
  effect no one can verify from this side of the bridge does not belong in a
  screen.

  The fifth star is therefore the same `Kati.UI.symbol/2` call as the other
  four, same size and family, so it shares their line box by construction
  rather than by a stacked `Box` whose height has to be guessed at.

  ## The caret sits on the next line

  The review body ends with the design's 2x16 orange text cursor. There is no
  inline node in this bridge — a `Box` beside a wrapping `Text` is a sibling,
  not a run — so the caret is drawn at the start of the line below the body,
  which is where a cursor lands when a line ends exactly at its edge. Recorded
  rather than faked with an offset that would drift with every font metric.
  """
  use Mob.Screen
  import Mob.Sigil

  alias Kati.Rating.Sample
  alias Kati.UI.SettingsList

  def mount(_params, _session, socket) do
    Mob.Theme.set(Kati.Theme.light())
    {:ok, Mob.Socket.assign(socket, :watch, Sample.watch())}
  end

  def render(assigns) do
    w = assigns.watch

    ~MOB"""
    <Box fill_width={true} fill_height={true} background={:background} layout_direction={Kati.Locale.direction_prop()}>
      <Scroll>
        <Column fill_width={true} padding_left={21} padding_right={21} padding_top={64} padding_bottom={40}>
          {Kati.Screens.Rating.header()}
          {Kati.Screens.Rating.title_card(w)}
          {Kati.Screens.Rating.rating_card(w)}
          {Kati.Screens.Rating.review_card(w)}
          {Kati.Screens.Rating.context_card(w)}
          {Kati.Screens.Rating.tags(w)}
        </Column>
      </Scroll>
    </Box>
    """
  end

  @doc false
  def header do
    close = {self(), :close}
    save = {self(), :save}

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Box
          width={44}
          height={44}
          corner_radius={22}
          background={Kati.Theme.card(:light)}
          shadow={Kati.Theme.shadow_button()}
          align="center"
          on_tap={close}
        >
          {Kati.UI.symbol("close", size: 21)}
        </Box>
        <Spacer weight={1.0} />
        <Text text="Log a watch" text_size={15} font_weight="bold" text_color={:on_surface} max_lines={1} />
        <Spacer weight={1.0} />
        <Row
          height={38}
          corner_radius={19}
          background={Kati.Theme.ink()}
          padding_left={16}
          padding_right={16}
          align="center"
          on_tap={save}
        >
          <Text text="Save" text_size={13} font_weight="bold" text_color={0xFFFBFAF8} max_lines={1} />
        </Row>
      </Row>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def title_card(w) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        {Kati.Screens.Rating.poster(w)}
        <Spacer size={14} />
        <Column weight={1.0}>
          <Text
            text={w.title}
            text_size={19}
            font_weight="bold"
            letter_spacing={-0.025}
            line_height={1.2}
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={6} />
          <Text text={w.meta} font_family="mono" text_size={10.5} text_color={0xFFA9A29A} max_lines={1} />
          <Spacer size={9} />
          <Row height={24} corner_radius={12} background={0xFFEFECE7} padding_left={10} padding_right={10} align="center">
            {Kati.UI.symbol("replay", size: 13, color: 0xFF8A8479)}
            <Spacer size={5} />
            <Text text={w.rewatch} text_size={11} font_weight="semibold" text_color={0xFF5C574F} max_lines={1} />
          </Row>
        </Column>
      </Row>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def poster(w) do
    case Sample.poster(w.seed) do
      nil ->
        ~MOB"<Box width={74} height={106} corner_radius={10} background={0xFFE4E0D9} />"

      src ->
        ~MOB"""
        <Image src={src} width={74} height={106} corner_radius={10} content_mode="fill" />
        """
    end
  end

  @doc false
  def rating_card(w) do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Kati.Theme.card(:light)}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={18}
      >
        <Row fill_width={true} align="center">
          <Text
            text={String.upcase("Rating")}
            font_family="mono"
            text_size={10.5}
            letter_spacing={0.16}
            text_color={0xFFA0998F}
            max_lines={1}
          />
          <Spacer weight={1.0} />
          {Kati.Screens.Rating.scale_toggle()}
        </Row>
        <Spacer size={14} />
        <Row fill_width={true} align="center">
          {Kati.Screens.Rating.stars(w.rating)}
          <Spacer size={12} />
          <Text text={"#{w.rating}"} font_family="mono" text_size={14} font_weight="medium" text_color={:on_surface} max_lines={1} />
        </Row>
        <Spacer size={10} />
        <Text text={w.rating_note} font_family="mono" text_size={10.5} text_color={0xFFA9A29A} max_lines={1} />
      </Column>
      <Spacer size={14} />
    </Column>
    """
  end

  @doc false
  def scale_toggle do
    tiles =
      Sample.scales()
      |> Enum.map(&Kati.Screens.Rating.scale/1)
      |> Enum.intersperse(Kati.Screens.Rating.scale_gap())

    ~MOB"""
    <Row background={0xFFEFECE7} corner_radius={11} padding={3} align="center">
      {tiles}
    </Row>
    """
  end

  @doc false
  def scale_gap, do: ~MOB"<Spacer size={3} />"

  @doc false
  def scale(%{on: true} = option) do
    ~MOB"""
    <Row
      height={24}
      corner_radius={8}
      background={Kati.Theme.card(:light)}
      shadow="0 1 2 0 #1F1A1917"
      padding_left={10}
      padding_right={10}
      align="center"
    >
      <Text text={option.label} text_size={10.5} font_weight="semibold" text_color={:on_surface} max_lines={1} />
      {Kati.Screens.Rating.scale_star(option.star, Kati.Theme.ink())}
    </Row>
    """
  end

  def scale(option) do
    ~MOB"""
    <Row height={24} corner_radius={8} padding_left={10} padding_right={10} align="center">
      <Text text={option.label} text_size={10.5} font_weight="semibold" text_color={0xFFA0998F} max_lines={1} />
      {Kati.Screens.Rating.scale_star(option.star, 0xFFA0998F)}
    </Row>
    """
  end

  @doc false
  def scale_star(false, _color), do: ~MOB"<Spacer size={0} />"

  # No gap and no wrapping Row: the drawing's badge is a single text run, `5★`,
  # and the 1dp Spacer that used to sit between them read as "5 ★". The pill's
  # own Row is already align="center", so the glyph centres against the numeral
  # without a second one.
  def scale_star(true, color), do: Kati.UI.symbol("star", size: 11, color: color, fill: true)

  @doc false
  def stars(value) do
    full = trunc(value)
    half? = value - full >= 0.5

    slots =
      Enum.map(1..5, fn i ->
        cond do
          i <= full -> :full
          i == full + 1 and half? -> :half
          true -> :empty
        end
      end)

    ~MOB"""
    <Row align="center">
      {slots |> Enum.map(&Kati.Screens.Rating.star/1) |> Enum.intersperse(Kati.Screens.Rating.star_gap())}
    </Row>
    """
  end

  @doc false
  def star_gap, do: ~MOB"<Spacer size={2} />"

  @doc false
  def star(:full), do: Kati.UI.symbol("star", size: 26, color: 0xFFE8823C, fill: true)
  def star(:empty), do: Kati.UI.symbol("star", size: 26, color: 0xFFE0DAD1, fill: true)

  # A real half star, drawn the way the design draws one: the empty star, with
  # a filled star painted over it and CUT at 50%.
  #
  # This used to be an outlined accent star, because the icon subset carries no
  # `star_half` and this bridge could not crop a glyph — a Box narrower than
  # the text ellipsises it away, since every Text is built with
  # TextOverflow.Ellipsis, and `corner_radius` clips painting only. Adding
  # `star_half` to the subset would have meant re-subsetting from a source
  # variable font that is not in this repo, for a glyph that is another glyph
  # cut in half.
  #
  # Fence K-16 gave the bridge `clip_width` instead, which clips the DRAW and
  # leaves measurement alone — so the two glyphs occupy one star's width, sit
  # in the same line box as their four neighbours, and 4.5 reads as four and a
  # half rather than as five.
  def star(:half) do
    ~MOB"""
    <Box width={26} height={26}>
      {Kati.UI.symbol("star", size: 26, color: 0xFFE0DAD1, fill: true)}
      <Box width={26} height={26} clip_width={0.5}>
        {Kati.UI.symbol("star", size: 26, color: 0xFFE8823C, fill: true)}
      </Box>
    </Box>
    """
  end

  # The one card on cream. Screen 08 does the same for its note, and for the
  # same reason: the user's own words are not metadata, so the palette warms up
  # around them.
  @doc false
  def review_card(w) do
    ~MOB"""
    <Column fill_width={true}>
      <Column fill_width={true} background={0xFFFBF1DE} corner_radius={22} shadow={Kati.Theme.shadow_card_soft()} padding={18}>
        <Row fill_width={true} align="center">
          <Text
            text={String.upcase("Review")}
            font_family="mono"
            text_size={10.5}
            letter_spacing={0.16}
            text_color={0xFFB09A72}
            max_lines={1}
          />
          <Spacer weight={1.0} />
          {Kati.UI.symbol("visibility_off", size: 15, color: 0xFFC98A3E)}
          <Spacer size={6} />
          <Text text={w.spoilers} text_size={11} font_weight="semibold" text_color={0xFF96723C} max_lines={1} />
        </Row>
        <Spacer size={10} />
        <Text text={w.review} text_size={14} line_height={1.6} text_color={0xFF4A4238} />
        <Row fill_width={true}>
          <Box width={2} height={16} background={0xFFE8823C} />
        </Row>
        <Spacer size={14} />
        <Box fill_width={true} height={1} background={0x4DB09A72} />
        <Spacer size={13} />
        <Row fill_width={true} align="center">
          <Text text={w.characters} font_family="mono" text_size={10.5} text_color={0xFFB09A72} max_lines={1} />
          <Spacer weight={1.0} />
          {Kati.UI.symbol("format_bold", size: 16, color: 0xFFC98A3E)}
          <Spacer size={7} />
          {Kati.UI.symbol("format_italic", size: 16, color: 0xFFC98A3E)}
          <Spacer size={7} />
          {Kati.UI.symbol("link", size: 16, color: 0xFFC98A3E)}
        </Row>
      </Column>
      <Spacer size={14} />
    </Column>
    """
  end

  @doc false
  def context_card(w) do
    rows = w.context
    last = length(rows) - 1

    body =
      rows
      |> Enum.with_index()
      |> Enum.map(fn {row, i} ->
        SettingsList.row(
          SettingsList.icon_tile(row.icon),
          SettingsList.body(row.title, row.sub),
          SettingsList.chevron(),
          padding: 13,
          rule: i < last
        )
      end)

    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.card(body)}
      <Spacer size={14} />
    </Column>
    """
  end

  # Row, not a wrapping field: the four chips measure ~315 inside the 360pt
  # content width, so the drawing's `flex-wrap` never actually wraps here.
  @doc false
  def tags(w) do
    chips =
      (Enum.map(w.tags, &Kati.Screens.Rating.tag/1) ++ [Kati.Screens.Rating.add_tag()])
      |> Enum.intersperse(Kati.Screens.Rating.tag_gap())

    ~MOB"""
    <Row fill_width={true} align="center">
      {chips}
    </Row>
    """
  end

  @doc false
  def tag_gap, do: ~MOB"<Spacer size={7} />"

  @doc false
  def tag(label) do
    ~MOB"""
    <Row
      height={30}
      corner_radius={15}
      background={Kati.Theme.card(:light)}
      shadow={Kati.Theme.shadow_card_soft()}
      padding_left={13}
      padding_right={13}
      align="center"
    >
      <Text text={label} text_size={12} font_weight="semibold" text_color={0xFF5C574F} max_lines={1} />
    </Row>
    """
  end

  # Solid, not dashed: `Modifier.border` takes a width and a colour and no
  # PathEffect, so the stitching does not survive. The weight and the alpha are
  # the drawing's own.
  @doc false
  def add_tag do
    tap = {self(), :add_tag}

    ~MOB"""
    <Row
      height={30}
      corner_radius={15}
      border_width={1.5}
      border_color={0x2E1A1917}
      padding_left={12}
      padding_right={12}
      align="center"
      on_tap={tap}
    >
      <Text text="+ tag" text_size={12} font_weight="semibold" text_color={0xFFA0998F} max_lines={1} />
    </Row>
    """
  end

  def handle_info({:tap, :close}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}
  def handle_info({:tap, :save}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}
  def handle_info(_msg, socket), do: {:noreply, socket}
end
