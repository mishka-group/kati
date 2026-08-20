defmodule Kati.Screens.UpNext do
  @moduledoc """
  Screen 10 — Up next, pushed under Library.

  Built to `.scratch/design/screens/10.html`. One landscape hero card for the
  thing you are closest to finishing, then a plain list of everything else that
  is ready, then a third section for the shows that have gone quiet.

  Three details from the drawing carry the whole idea and are therefore exact:

    * The hero's progress bar is **burnt into the bottom edge** of the still at
      3pt, not floated under it, so "62% through" is a property of the picture
      rather than a widget beside it.
    * The cold section's eyebrow dash is `#C4BDB3`, not `#E8823C`. Orange means
      new or now; a thread you dropped four months ago is the opposite, so
      `Kati.UI.Eyebrow.quiet/1` draws it grey.
    * The cold row sits on `#F4F1EC` with **no shadow** and offers `Drop`. It is
      the same row as the ready ones, unlifted — the design's way of saying this
      is still yours but is no longer being pushed at you.

  The frame ends at 40pt rather than 132: this screen is pushed, so there is no
  dock to clear.

  The back pill is `Kati.Screens.Pushed`'s, floating at the top left; the `tune`
  disc opposite it is this screen's own, which is the same split screen 05 uses
  for its `Mark all` button.
  """
  use Kati.Screens.Pushed, back: "Library"

  alias Kati.Components.MishkaActionIcon
  alias Kati.Components.MishkaPill
  alias Kati.Screens.UpNext.Sample
  alias Kati.UI

  @impl true
  def load(socket), do: Mob.Socket.assign(socket, :queue, Sample.queue())

  @doc false
  def content(assigns) do
    q = assigns.queue

    ~MOB"""
    <Scroll>
      <Column fill_width={true} padding_left={21} padding_right={21} padding_top={64} padding_bottom={40}>
        {Kati.Screens.UpNext.tune_row()}
        {Kati.Screens.UpNext.header(q)}
        {Kati.Screens.UpNext.hero(q)}
        {UI.eyebrow(q.ready_label)}
        {Kati.Screens.UpNext.ready(q)}
        {Kati.UI.Eyebrow.quiet(q.cold_label)}
        {Kati.Screens.UpNext.cold(q)}
      </Column>
    </Scroll>
    """
  end

  # The back pill is drawn floating by Kati.Screens.Pushed. This row reserves
  # the height the drawing gives that pill and carries the tune disc opposite
  # it, exactly as screen 05 does with Mark all.
  @doc false
  def tune_row do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} height={44} align="center">
        <Spacer weight={1.0} />
        {Kati.Screens.UpNext.tune_disc()}
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc """
  The `tune` disc — Mishka's Action Icon, now that a disc can float.

  This is the same component the two play discs below already use; what kept
  it out of this one was the shadow. `action_icon/2` painted a fill and
  stopped, and a filled circle with no lift reads as a patch of card colour on
  paper rather than as a control above it — so the one disc on this screen the
  design floats was the one that had to be drawn by hand. `shadow` takes the
  design's `Kati.Theme.shadow_button()` string untouched.

  Nothing moves: `shape: :circle` is an exact `size / 2`, so 44 rounds at 22
  as the literal did, the fill and the shadow pass through, and the glyph is
  the same `Kati.UI.symbol/2` Text inside a Row that hugs it and is centred in
  a Box of the declared size — where a hugging Row's only child lands exactly
  where a bare centred Text did.
  """
  @spec tune_disc() :: map()
  def tune_disc do
    MishkaActionIcon.action_icon(
      [
        size: 44,
        shape: :circle,
        variant: :filled,
        background: Kati.Theme.card(:light),
        shadow: Kati.Theme.shadow_button()
      ],
      [Kati.UI.symbol("tune", size: 21)]
    )
  end

  @doc false
  def header(q) do
    ~MOB"""
    <Column fill_width={true}>
      <Text text="Up next" text_size={28} font_weight="bold" letter_spacing={-0.03} text_color={:on_surface} />
      <Spacer size={5} />
      <Text text={q.subtitle} font_family="mono" text_size={11} text_color={0xFFA9A29A} max_lines={1} />
      <Spacer size={20} />
    </Column>
    """
  end

  # A 12pt white mount around a 170pt still. The three overlays are separate
  # full-height Boxes rather than one: each needs its own bottom alignment, and
  # a Box stacks its children, so the gradient, the caption row and the progress
  # bar can all sit at the bottom edge without fighting for the same slot.
  @doc false
  def hero(q) do
    h = q.hero

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Kati.Theme.card(:light)}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={12}
      >
        <Box fill_width={true} height={170} corner_radius={15} background={0xFFE4E0D9}>
          {Kati.Screens.UpNext.hero_art()}
          <Box fill_width={true} fill_height={true} align="bottom">
            <Box fill_width={true} height={70} gradient="to_top #C7141210 #00141210" />
          </Box>
          <Box fill_width={true} fill_height={true} align="bottom">
            <Row fill_width={true} align="bottom" padding_left={14} padding_right={12} padding_bottom={12}>
              <Column weight={1.0}>
                <Text text={h.title} text_size={16} font_weight="bold" letter_spacing={-0.02} text_color={0xFFFBFAF8} max_lines={1} />
                <Spacer size={4} />
                <Text text={h.meta} font_family="mono" text_size={10.5} text_color={0xBFFBFAF8} max_lines={1} />
              </Column>
              <Spacer size={8} />
              {Kati.Screens.UpNext.play_disc(44, 24, 0xFFFBFAF8)}
            </Row>
          </Box>
          <Box fill_width={true} fill_height={true} align="bottom">
            {Kati.Screens.UpNext.progress(h.progress)}
          </Box>
        </Box>
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def hero_art do
    case Sample.hero_art() do
      nil ->
        ~MOB"<Spacer size={0} />"

      src ->
        ~MOB"""
        <Image src={src} fill_width={true} height={170} content_mode="fill" />
        """
    end
  end

  @doc false
  def progress(fraction) do
    ~MOB"""
    <Box fill_width={true} height={3} background={0x40FBFAF8}>
      <Row fill_width={true}>
        <Box weight={fraction} height={3} background={0xFFE8823C} />
        <Spacer weight={1.0 - fraction} />
      </Row>
    </Box>
    """
  end

  @doc false
  def ready(q) do
    ~MOB"""
    <Column fill_width={true}>
      {Enum.map(q.ready, fn row -> Kati.Screens.UpNext.ready_row(row) end)}
      <Spacer size={13} />
    </Column>
    """
  end

  @doc false
  def ready_row(row) do
    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Kati.Theme.card(:light)}
        corner_radius={18}
        shadow={Kati.Theme.shadow_card_soft()}
        padding_left={13}
        padding_right={13}
        padding_top={10}
        padding_bottom={10}
        align="center"
      >
        {Kati.Screens.UpNext.thumb(row)}
        <Spacer size={12} />
        <Column weight={1.0}>
          <Text text={row.title} text_size={13.5} font_weight="bold" letter_spacing={-0.015} text_color={:on_surface} max_lines={1} />
          <Spacer size={4} />
          <Text text={row.meta} font_family="mono" text_size={10.5} text_color={0xFFA9A29A} max_lines={1} />
        </Column>
        <Spacer size={12} />
        {Kati.Screens.UpNext.play_disc(34, 19, 0xFFEFECE7)}
      </Row>
      <Spacer size={9} />
    </Column>
    """
  end

  @doc """
  The filled play disc — Mishka's Action Icon, which is what a round icon
  button is.

  Both play discs are shadowless; the lifted `tune` disc above is the same
  component with a `shadow`, which it did not have when these two adopted it.

  Nothing moves. `shape: :circle` is an exact `size / 2` radius — 22 at 44,
  17 at 34, the drawing's own numbers — the fill is passed straight through,
  and the glyph is the same `Kati.UI.symbol/2` Text as before, wrapped in a
  Row that hugs it (a Compose Row takes its content's size unless told to
  fill), centred in a Box of the same declared size.
  """
  @spec play_disc(number(), number(), non_neg_integer()) :: map()
  def play_disc(size, glyph, background) do
    MishkaActionIcon.action_icon(
      [size: size, shape: :circle, variant: :filled, background: background],
      [Kati.UI.symbol("play_arrow", size: glyph, fill: true)]
    )
  end

  @doc false
  def thumb(row) do
    case Sample.poster(row.seed) do
      nil ->
        ~MOB"<Box width={40} height={56} corner_radius={8} background={0xFFE4E0D9} />"

      src ->
        ~MOB"""
        <Image src={src} width={40} height={56} corner_radius={8} content_mode="fill" />
        """
    end
  end

  # Flat paper, not an elevated card. The drawing drops the shadow here and
  # tones the poster back; the row is still legible, it just stops asking.
  @doc false
  def cold(q) do
    ~MOB"""
    <Column fill_width={true}>
      {q.cold |> Enum.map(fn row -> Kati.Screens.UpNext.cold_row(row) end) |> Enum.intersperse(Kati.Screens.UpNext.cold_gap())}
    </Column>
    """
  end

  @doc false
  def cold_gap, do: ~MOB"<Box fill_width={true} height={9} />"

  @doc false
  def cold_row(row) do
    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={0xFFF4F1EC}
        corner_radius={18}
        padding_left={13}
        padding_right={13}
        padding_top={10}
        padding_bottom={10}
        align="center"
      >
        {Kati.Screens.UpNext.cold_thumb(row)}
        <Spacer size={12} />
        <Column weight={1.0}>
          <Text text={row.title} text_size={13.5} font_weight="semibold" text_color={0xFF8A8479} max_lines={1} />
          <Spacer size={4} />
          <Text text={row.meta} font_family="mono" text_size={10.5} text_color={0xFFB3ACA2} max_lines={1} />
        </Column>
        <Spacer size={12} />
        {Kati.Screens.UpNext.drop_pill(row.action)}
      </Row>
    </Column>
    """
  end

  @doc """
  The `Drop` affordance on a cold row — Mishka's Pill.

  A pill, not a chip: there is no selected state here, only the one offer the
  design makes on a thread that has gone quiet. A label on a tinted lozenge is
  what a pill is.

  The pixels are the Row's. `padding: 0` with `padding_left`/`padding_right`
  at 12 hands the bridge the same 12/0 edges, and padding is applied before
  size, so `height: 30` still measures 30. The pill's root is a `Box` that
  passes `fill_width={false}` — so it hugs (K-17) exactly as the Row did —
  wrapping a `Row` that holds the label beside an empty `Row` standing in for
  the absent ✕; both hug, the empty one is zero-wide, and `align: :center`
  centres the pair where `align="center"` centred the Text. `max_lines: 1` is
  the pill's own default and is what this Text already carried.
  """
  @spec drop_pill(String.t()) :: map()
  def drop_pill(label) do
    MishkaPill.pill(
      label: label,
      background: 0xFFE4E0D9,
      color: 0xFF5C574F,
      corner_radius: 15,
      height: 30,
      padding: 0,
      padding_left: 12,
      padding_right: 12,
      align: :center,
      text_size: 11.5,
      font_weight: :semibold
    )
  end

  # The drawing tones the cold poster back with `opacity:.6`. There is no
  # opacity prop on an Image node, so the same result is composited: 40% of the
  # row's own paper (#F4F1EC) laid over the picture is, to the pixel, the
  # picture at 60% against that paper.
  @doc false
  def cold_thumb(row) do
    case Sample.poster(row.seed) do
      nil ->
        ~MOB"<Box width={40} height={56} corner_radius={8} background={0xFFE4E0D9} />"

      src ->
        ~MOB"""
        <Box width={40} height={56} corner_radius={8} background={0xFFE4E0D9}>
          <Image src={src} width={40} height={56} corner_radius={8} content_mode="fill" />
          <Box width={40} height={56} corner_radius={8} background={0x66F4F1EC} />
        </Box>
        """
    end
  end
end
