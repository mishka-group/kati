defmodule Kati.Screens.MealSwap do
  @moduledoc """
  Screen 46 — swap a meal.

  Built to `.scratch/design/screens/46.html`. The screen is an argument in
  three parts, top to bottom: what is being replaced, what could replace it
  and by how much it differs, and what the day looks like afterwards. The
  design's caption puts it plainly — *"A swap is only useful if it tells you
  what it costs"* — so the delta is never buried: it sits at the end of every
  candidate row, in green or red, before anything is committed.

  Its own close button rather than `Kati.Screens.Pushed`, for the same reason
  screen 06 has one: the drawing gives this screen a single dismissal, and the
  pushed chrome would draw a second one over the centred title. #45 has this
  becoming a native bottom sheet along with 06 and 18; until then it pushes,
  which is the same information in a different container.

  ## Where this diverges from the drawing

    * **The selected candidate's `outline: 2px solid` is a 2pt border.** It is
      `outline-offset:-2px` in the drawing, which is a border drawn inside the
      box — the same thing, said in CSS that does not disturb layout.
    * **The two footer buttons are sized by weight, not by content.** `Swap
      just today` is `flex:1` and `Every week` hugs its text at `padding:0
      18px`; nothing measures text here, so the hugging one is a Row with that
      padding and the flexible one takes the rest.

  No dock, so the frame ends at 40 rather than 132.
  """
  # Not `Kati.Screens.Pushed`: this screen dismisses with its own close
  # button, and the drawing has exactly one dismissal.
  use Mob.Screen
  import Mob.Sigil

  alias Kati.Components.MishkaActionIcon
  alias Kati.Components.MishkaPill
  alias Kati.Meals.SampleSwap, as: Sample
  alias Kati.Theme

  def mount(_params, _session, socket) do
    Mob.Theme.set(Kati.Theme.light())
    {:ok, Mob.Socket.assign(socket, :candidates, Sample.candidates())}
  end

  def render(assigns) do
    candidates = assigns.candidates

    ~MOB"""
    <Box fill_width={true} fill_height={true} background={:background} layout_direction={Kati.Locale.direction_prop()}>
      <Scroll>
        <Column fill_width={true} padding_left={21} padding_right={21} padding_top={64} padding_bottom={40}>
          {Kati.Screens.MealSwap.header()}
          {Kati.Screens.MealSwap.replacing()}
          {Kati.Screens.MealSwap.arrow()}
          {Kati.Screens.MealSwap.filters()}
          {Kati.Screens.MealSwap.candidates(candidates)}
          {Kati.Screens.MealSwap.muted_eyebrow("Effect on today")}
          {Kati.Screens.MealSwap.effect()}
          {Kati.Screens.MealSwap.commit()}
        </Column>
      </Scroll>
    </Box>
    """
  end

  # A 44pt spacer opposite the close button, so the title is centred against
  # the frame rather than against what is left of it.
  @doc false
  def header do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        {Kati.Screens.MealSwap.close_button()}
        <Spacer weight={1.0} />
        <Text text={Kati.Meals.SampleSwap.heading()} text_size={15} font_weight="bold" text_color={:on_surface} max_lines={1} />
        <Spacer weight={1.0} />
        <Spacer size={44} />
      </Row>
      <Spacer size={22} />
    </Column>
    """
  end

  # The screen's single dismissal, and `Kati.Components.MishkaActionIcon` is
  # the name for it: an icon-only button on a raised surface. It could not be
  # one until the component took a `shadow` — a floating disc is defined by its
  # shadow, and `#FBFAF8` on `#EFECE7` without one is nearly no disc at all.
  #
  # `shape: :circle` computes 44 / 2 = 22.0, the radius written here before,
  # and `variant: :filled` paints `background` and nothing more. The glyph is a
  # child rather than `icon:` because Kati's icons are Material Symbols through
  # `Kati.UI.symbol/2` — a `Text` in the `symbols` family — and a child is
  # wrapped in a `<Row>` that hugs it, inside a Box that already centred it.
  @doc false
  def close_button do
    MishkaActionIcon.action_icon(
      [
        size: 44,
        shape: :circle,
        variant: :filled,
        background: Theme.card(:light),
        shadow: Theme.shadow_button(),
        on_tap: :back
      ],
      [Kati.UI.symbol("close", size: 21)]
    )
  end

  @doc false
  def replacing do
    from = Sample.replacing()

    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Kati.Theme.card(:light)}
        corner_radius={20}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={14}
        align="center"
      >
        {Kati.Screens.MealSwap.thumb(from.seed)}
        <Spacer size={13} />
        <Column weight={1.0}>
          <Text
            text={String.upcase(from.label)}
            font_family="mono"
            text_size={9.5}
            letter_spacing={0.14}
            text_color={0xFFA0998F}
            max_lines={1}
          />
          <Spacer size={4} />
          <Text text={from.title} text_size={14} font_weight="bold" text_color={:on_surface} max_lines={1} />
          <Spacer size={4} />
          <Text text={from.macros} font_family="mono" text_size={10.5} text_color={0xFFA9A29A} max_lines={1} />
        </Column>
      </Row>
      <Spacer size={8} />
    </Column>
    """
  end

  @doc false
  def arrow do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Spacer weight={1.0} />
        {Kati.UI.symbol("arrow_downward", size: 20, color: 0xFFC4BDB3)}
        <Spacer weight={1.0} />
      </Row>
      <Spacer size={8} />
    </Column>
    """
  end

  @doc false
  def filters do
    [first | rest] = Sample.filters()

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        {Kati.Screens.MealSwap.filter(first, true)}
        {Enum.map(rest, fn label -> Kati.Screens.MealSwap.filter(label, false) end)}
      </Row>
      <Spacer size={18} />
    </Column>
    """
  end

  # NOT `Kati.Components.MishkaChip`, and the reason is one prop.
  #
  # Everything else about these three now exists on the chip: `height: 32`,
  # `padding_x: 14` with `padding_y: 0`, `corner_radius: 16`, `text_size: 12.5`,
  # `font_weight: :semibold`, `max_lines: 1`, and — new this round, and the
  # thing that used to block it — `unchecked_color` and `unchecked_text_color`,
  # so the idle chip can be `#FBFAF8` on `#5C574F` rather than the theme's
  # `:surface_raised` on `:on_surface`.
  #
  # What the chip has no way to draw is the **shadow the idle chip carries**.
  # The drawing gives the unchosen two `0 1px 2px rgba(26,25,23,.04), 0 12px
  # 24px -18px rgba(26,25,23,.7)` — `Kati.Theme.shadow_card_soft/0` — and gives
  # the chosen one none, because ink on paper needs no lift. `chip/1` builds a
  # Box and puts `width`, `height`, `align` and `on_tap` on it; there is no
  # `shadow` among them and no slot to reach the root node through, so an
  # adopted chip would drop the lift from two of the three and flatten the row.
  # `MishkaPill` has `shadow` and `MishkaActionIcon` has `shadow`; the chip is
  # the one member of the family without it.
  #
  # That is the whole gap. `shadow` on `MishkaChip`, passed to the root Box the
  # way the pill passes it, and these become one call.
  @doc false
  def filter(label, on?) do
    background = if on?, do: Theme.ink(), else: Theme.card(:light)
    color = if on?, do: 0xFFFBFAF8, else: 0xFF5C574F
    shadow = if on?, do: nil, else: Theme.shadow_card_soft()

    ~MOB"""
    <Row align="center">
      <Row height={32} corner_radius={16} background={background} shadow={shadow} padding_left={14} padding_right={14} align="center">
        <Text text={label} text_size={12.5} font_weight="semibold" text_color={color} max_lines={1} />
      </Row>
      <Spacer size={7} />
    </Row>
    """
  end

  @doc false
  def candidates(candidates) do
    ~MOB"""
    <Column fill_width={true}>
      {Enum.map(candidates, fn row -> Kati.Screens.MealSwap.candidate(row) end)}
      <Spacer size={12} />
    </Column>
    """
  end

  @doc false
  def candidate(row) do
    border = if row.selected?, do: 2, else: 0

    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Kati.Theme.card(:light)}
        corner_radius={18}
        shadow={Kati.Theme.shadow_card_soft()}
        border_width={border}
        border_color={Kati.Theme.ink()}
        padding_left={13}
        padding_right={13}
        padding_top={12}
        padding_bottom={12}
        align="center"
      >
        {Kati.Screens.MealSwap.thumb(row.seed)}
        <Spacer size={13} />
        <Column weight={1.0}>
          <Row fill_width={true} align="center">
            <Text text={row.title} text_size={13.5} font_weight="bold" text_color={:on_surface} max_lines={1} />
            {Kati.Screens.MealSwap.badge(row.badge)}
          </Row>
          <Spacer size={4} />
          <Text text={row.macros} font_family="mono" text_size={10.5} text_color={0xFFA9A29A} max_lines={1} />
        </Column>
        <Spacer size={13} />
        <Text text={row.delta} font_family="mono" text_size={11} font_weight="medium" text_color={row.delta_color} max_lines={1} />
      </Row>
      <Spacer size={10} />
    </Column>
    """
  end

  # `BEST` is the drawing's own capitalisation — there is no text-transform on
  # it — so it is content rather than styling, and stays as written.
  #
  # The token itself is `Kati.Components.MishkaPill`, which is precisely what a
  # pill is in this port: a compact label, no selected state, no tap. (The
  # filter chips above it are the other thing — see the note on `filter/2`.)
  #
  # Same pixels, one wrapper deeper. The hugging `Row` that carried the ink
  # fill, the 9 radius, 7 of horizontal padding and an 18 height becomes the
  # pill's root `Box fill_width={false}` carrying all four, around a `Row`
  # holding the `Text` and the empty `Row` its unused remove slot leaves — a
  # 0x0 node that adds nothing to the line.
  #
  # All four padding edges are named, so the component's `:space_sm` default
  # never reads: `nodeModifier/1` falls back to the uniform value only for a
  # missing edge. The vertical zeros pin the outer height at 18, because the
  # bridge pads before it sizes. `align: :center` stands in for the Row's
  # `align="center"` — horizontally the content box is exactly the Text's
  # width, so only the vertical half of it has anything to do.
  @doc false
  def badge(nil), do: ~MOB"<Spacer size={0} />"

  def badge(label) do
    ~MOB"""
    <Row align="center">
      <Spacer size={7} />
      {Kati.Screens.MealSwap.badge_pill(label)}
    </Row>
    """
  end

  @doc false
  def badge_pill(label) do
    MishkaPill.pill(
      label: label,
      background: Theme.ink(),
      color: 0xFFFBFAF8,
      corner_radius: 9,
      height: 18,
      padding_left: 7,
      padding_right: 7,
      padding_top: 0,
      padding_bottom: 0,
      text_size: 9,
      font_weight: :bold,
      align: :center
    )
  end

  @doc false
  def thumb(seed) do
    case Kati.Design.Images.poster(seed) do
      nil ->
        ~MOB"<Box width={48} height={48} corner_radius={13} background={0xFFE4E0D9} />"

      src ->
        ~MOB"""
        <Image src={src} width={48} height={48} corner_radius={13} content_mode="fill" />
        """
    end
  end

  # Kati.UI.eyebrow's dash is always the accent, and orange means new or now.
  # The effect on today is a consequence, not an event, so it takes #C4BDB3.
  @doc false
  def muted_eyebrow(label) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_left={2} padding_right={2}>
        <Box width={13} height={2} corner_radius={1} background={0xFFC4BDB3} />
        <Spacer size={9} />
        <Text
          text={String.upcase(label)}
          font_family="mono"
          text_size={10.5}
          letter_spacing={0.16}
          text_color={0xFFA0998F}
        />
      </Row>
      <Spacer size={11} />
    </Column>
    """
  end

  @doc false
  def effect do
    effect = Sample.effect()

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Kati.Theme.card(:light)}
        corner_radius={20}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={16}
      >
        <Row fill_width={true} align="center">
          <Text text={effect.label} text_size={13} font_weight="semibold" text_color={:on_surface} max_lines={1} />
          <Spacer weight={1.0} />
          <Text text={effect.total} font_family="mono" text_size={12} text_color={0xFF5C574F} max_lines={1} />
          <Text text={effect.target} font_family="mono" text_size={12} text_color={0xFFC4BDB3} max_lines={1} />
        </Row>
        <Spacer size={12} />
        <Box fill_width={true} height={9} corner_radius={4.5} background={0xFFEFECE7}>
          <Row fill_width={true}>
            {Enum.map(effect.macros, fn {share, tone} -> Kati.Screens.MealSwap.segment(share, tone) end)}
          </Row>
        </Box>
        <Spacer size={12} />
        <Row fill_width={true} align="center">
          {Kati.UI.symbol("check_circle", size: 15, color: 0xFF4E9A73, fill: true)}
          <Spacer size={7} />
          <Text text={effect.verdict} text_size={11.5} text_color={0xFF5C574F} weight={1.0} max_lines={1} />
        </Row>
      </Column>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc false
  def segment(share, tone) do
    ~MOB"""
    <Box weight={share} height={9} background={tone} />
    """
  end

  @doc false
  def commit do
    {once, forever} = Sample.commit()
    once_tap = {self(), :swap_once}
    forever_tap = {self(), :swap_forever}

    ~MOB"""
    <Row fill_width={true} align="center">
      <Box weight={1.0}>
        <Box fill_width={true} height={50} corner_radius={25} background={Kati.Theme.ink()} align="center" on_tap={once_tap}>
          <Row fill_width={true} align="center">
            <Spacer weight={1.0} />
            <Text text={once} text_size={14} font_weight="bold" text_color={0xFFFBFAF8} max_lines={1} />
            <Spacer weight={1.0} />
          </Row>
        </Box>
      </Box>
      <Spacer size={10} />
      <Row
        height={50}
        corner_radius={25}
        background={Kati.Theme.card(:light)}
        shadow={Kati.Theme.shadow_card_soft()}
        padding_left={18}
        padding_right={18}
        align="center"
        on_tap={forever_tap}
      >
        <Text text={forever} text_size={13} font_weight="semibold" text_color={0xFF5C574F} max_lines={1} />
      </Row>
    </Row>
    """
  end

  def handle_info({:tap, :back}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}
  def handle_info(_message, socket), do: {:noreply, socket}
end
