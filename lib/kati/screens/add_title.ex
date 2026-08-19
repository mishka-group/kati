defmodule Kati.Screens.AddTitle do
  @moduledoc """
  Screen 06 — Add a title, reached from the `+` button.

  Built to `.scratch/design/screens/06.html`, drawn mid-query on "quiet": the
  field carries a 2px ink ring and an orange caret, because the design shows
  the focused state rather than the resting one, and a screen that only draws
  its resting state is untested where it matters.

  The design's note says this is one sheet that will later add a book, an
  album or an event — "the type is inferred from what you pick". So the search
  and the result row are the parts to keep general; the chips are the part
  that will grow.

  **This should eventually be a native bottom sheet**, not a pushed screen:
  #45 settled that screens 06, 18 and 46 become Android sheets via a new
  `:sheet` node type. Until that lands it pushes, which is the same
  information in a different container.
  """
  # Not `Kati.Screens.Pushed`: this screen has its own close button in the
  # header, and the pushed chrome would draw a second back affordance over the
  # title. The drawing has one dismissal, so the build has one.
  use Mob.Screen
  import Mob.Sigil

  alias Kati.Library.Sample
  alias Kati.Theme
  alias Kati.UI

  def mount(_params, _session, socket) do
    Mob.Theme.set(Kati.Theme.light())
    {:ok, Mob.Socket.assign(socket, :results, Sample.search_results())}
  end

  def render(assigns) do
    results = assigns.results

    ~MOB"""
    <Box fill_width={true} fill_height={true} background={:background} layout_direction={Kati.Locale.direction_prop()}>
    <Scroll>
      <Column fill_width={true} padding_left={21} padding_right={21} padding_top={64} padding_bottom={132}>
        {Kati.Screens.AddTitle.header()}
        {Kati.Screens.AddTitle.field()}
        {Kati.Screens.AddTitle.chips()}
        {UI.eyebrow("#{length(results)} results")}
        {Kati.Screens.AddTitle.results(results)}
        {Kati.Screens.AddTitle.by_hand()}
      </Column>
    </Scroll>
    </Box>
    """
  end

  def handle_info({:tap, :back}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}
  def handle_info(_msg, socket), do: {:noreply, socket}

  @doc false
  def header do
    close = {self(), :back}

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} vertical_align="center">
        <Text text="Add a title" text_size={26} font_weight="bold" letter_spacing={-0.03} text_color={:on_surface} />
        <Spacer weight={1.0} />
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
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

  # The focused field. `0 0 0 2px #1A1917` in the drawing is a ring, not a
  # shadow, so it is a 2px border here — a shadow at zero blur and zero offset
  # would be invisible under the card's own elevation.
  @doc false
  def field do
    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        height={52}
        corner_radius={26}
        background={Kati.Theme.card(:light)}
        border_width={2}
        border_color={0xFF1A1917}
        shadow={Kati.Theme.shadow_search()}
        padding_left={18}
        padding_right={18}
        vertical_align="center"
      >
        {Kati.UI.symbol("search", size: 20)}
        <Spacer size={11} />
        <Text text="quiet" text_size={14.5} font_weight="medium" text_color={:on_surface} max_lines={1} />
        <Spacer size={2} />
        <Box width={2} height={19} background={0xFFE8823C} />
        <Spacer weight={1.0} />
        {Kati.UI.symbol("cancel", size: 19, color: 0xFFC4BDB3, fill: true)}
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc false
  def chips do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true}>
        {["Everything", "Films", "Series"]
         |> Enum.with_index()
         |> Enum.map(fn {label, i} -> Kati.Screens.AddTitle.chip(label, i == 0) end)}
      </Row>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def chip(label, on?) do
    bg = if on?, do: Theme.ink(), else: Theme.card(:light)
    fg = if on?, do: 0xFFFBFAF8, else: 0xFF5C574F

    ~MOB"""
    <Row height={32} corner_radius={16} background={bg} padding_left={15} padding_right={15} vertical_align="center">
      <Text text={label} text_size={12.5} font_weight="semibold" text_color={fg} max_lines={1} />
      <Spacer size={7} />
    </Row>
    """
  end

  @doc false
  def results(results) do
    ~MOB"""
    <Column fill_width={true}>
      {Enum.map(results, fn r -> Kati.Screens.AddTitle.result_row(r) end)}
      <Spacer size={26} />
    </Column>
    """
  end

  @doc false
  def result_row(r) do
    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Kati.Theme.card(:light)}
        corner_radius={18}
        shadow={Kati.Theme.shadow_card_soft()}
        padding_left={13}
        padding_right={13}
        padding_top={11}
        padding_bottom={11}
        vertical_align="center"
      >
        {Kati.Screens.AddTitle.thumb(r)}
        <Spacer size={13} />
        <Column weight={1.0}>
          <Text text={r.title} text_size={14} font_weight="bold" letter_spacing={-0.015} text_color={:on_surface} max_lines={1} />
          <Spacer size={5} />
          <Text text={r.meta} font_family="mono" text_size={10.5} text_color={0xFFA9A29A} max_lines={1} />
          <Spacer size={5} />
          <Text text={r.note} text_size={11.5} text_color={0xFF8A8479} max_lines={1} />
        </Column>
        <Spacer size={11} />
        {Kati.Screens.AddTitle.add_button(r.added)}
      </Row>
      <Spacer size={9} />
    </Column>
    """
  end

  @doc false
  def thumb(r) do
    case Kati.Library.Sample.poster(r[:slug]) do
      nil -> ~MOB"<Box width={44} height={62} corner_radius={9} background={0xFFE4E0D9} />"
      src -> ~MOB"""
        <Image src={src} width={44} height={62} corner_radius={9} content_mode="fill" />
        """
    end
  end

  # Added is muted, not celebratory: the design keeps ink for the action still
  # available and greys the one already taken.
  @doc false
  def add_button(false) do
    ~MOB"""
    <Box width={34} height={34} corner_radius={17} background={Kati.Theme.ink()} align="center">
      {Kati.UI.symbol("add", size: 19, color: 0xFFFBFAF8)}
    </Box>
    """
  end

  def add_button(true) do
    ~MOB"""
    <Box width={34} height={34} corner_radius={17} background={0xFFE4E0D9} align="center">
      {Kati.UI.symbol("check", size: 19, color: 0xFF8A8479)}
    </Box>
    """
  end

  @doc false
  def by_hand do
    ~MOB"""
    <Row
      fill_width={true}
      corner_radius={18}
      border_width={1.5}
      border_color={0xFFD8D2C8}
      padding_top={14}
      padding_bottom={14}
      vertical_align="center"
      horizontal_align="center"
    >
      {Kati.UI.symbol("edit_note", size: 18, color: 0xFF8A8479)}
      <Spacer size={7} />
      <Text text="Can’t find it? Add it by hand" text_size={13} font_weight="semibold" text_color={0xFF5C574F} max_lines={1} />
    </Row>
    """
  end
end
