defmodule Kati.Screens.AddByHandStates do
  @moduledoc """
  Screen 155 — Add by hand, its two states and the three decisions behind them.

  A reference sheet in screen 27's manner: a picture of two situations rather
  than a situation the app can be in, which is why it has no route and says so
  on `Kati.AppReachabilityTest`'s inventory.

  ## What it settles

  **Film is the default.** The board words it *"Resting — empty, Film, nothing
  assumed"*, and that is why `Kati.Screens.AddByHand` loads as `:movie` even
  though board 154 is drawn with Series chosen — 154's own caption says it
  chose Series so the episode-count field would be visible. A form that
  defaulted to Series would be assuming the answer to its own second question.

  **The refusal names what is missing, then says nothing was written.** Screen
  95's empty-save sentence in the same shape, which is the sentence
  `Kati.Write` already produces for a refused write.

  **Add to library goes to the new title's detail screen**, with Year
  deliberately blank — a hand-typed row carries what was typed and nothing
  inferred.
  """
  use Kati.Screens.Pushed, back: "Settings"

  alias Kati.Screens.AddByHand
  alias Kati.Theme.Palette
  alias Kati.UI.SettingsList

  @doc false
  def content(_assigns) do
    # The board draws its back pill in the flow at 64; the macro floats one
    # at 54, 42 tall, so the content that follows starts at `content_top/0`
    # to clear it. Before this the column had no padding at all and the
    # form ran to the pixel with its heading under the pill.
    Kati.Screens.Pushed.page(~MOB"""
      <Column fill_width={true}>
        <Text
          text="Add by hand"
          text_size={28}
          max_font_scale={1.6}
          font_weight="bold"
          letter_spacing={-0.03}
          text_color={:on_surface}
        />
        <Spacer size={7} />
        <Text
          text="TWO STATES"
          text_size={13}
          line_height={1.55}
          text_color={Palette.sub()}
        />
        <Spacer size={20} />
        {Kati.Screens.AddByHandStates.resting()}
        {Kati.Screens.AddByHandStates.refused()}
        {Kati.Screens.AddByHandStates.destination()}
      </Column>
    """, Kati.Screens.Pushed.content_top())
  end

  @doc "The first band: the form as it opens, with nothing assumed."
  @spec resting() :: map()
  def resting do
    ~MOB"""
    <Column fill_width={true}>
      <Text
        text="Resting — empty, Film, nothing assumed"
        text_size={13.5}
        font_weight="semibold"
        text_color={:on_surface}
      />
      <Spacer size={12} />
      {AddByHand.labelled("Title", Kati.Screens.AddByHandStates.specimen("e.g. The Long Hollow"))}
      {AddByHand.labelled("Kind", Kati.Screens.AddByHandStates.drawn_kinds())}
      {AddByHand.labelled("Year", Kati.Screens.AddByHandStates.specimen("2026"))}
      {Kati.Screens.AddByHandStates.drawn_statuses()}
      <Spacer size={14} />
      {Kati.Screens.AddByHandStates.two_term_note("Film is the default", " and ", "Not started", " the default status — the commonest thing a person adds by hand is a film they have not seen yet. Year is blank, not this year: a guessed year is a wrong year.")}
      <Spacer size={26} />
    </Column>
    """
  end

  @doc """
  The second band: Save pressed with nothing typed.

  Two sentences and not one, because that is the shape screen 95 settled —
  name what is missing, then say nothing was written. A message that only says
  *A title is needed* leaves the reader wondering what happened to the rest of
  the form.
  """
  @spec refused() :: map()
  def refused do
    ~MOB"""
    <Column fill_width={true}>
      <Text
        text="The save that refuses"
        text_size={13.5}
        font_weight="semibold"
        text_color={:on_surface}
      />
      <Spacer size={12} />
      {SettingsList.note("error", "A title is needed")}
      <Spacer size={9} />
      <Text
        text="Kati cannot keep a thing with no name."
        text_size={12.5}
        line_height={1.55}
        text_color={Palette.ink_soft()}
      />
      <Spacer size={9} />
      {Kati.Screens.AddByHandStates.two_term_note("95’s empty-save sentence, same shape: name what is missing, then say", "nothing was written", "— this form is still open and your other answers are intact.", ". The field takes the red inset ring and keeps its caret; the button is never disabled, because a dead button explains nothing.")}
      <Spacer size={26} />
    </Column>
    """
  end

  @doc false
  def destination do
    ~MOB"""
    <Column fill_width={true}>
      <Text
        text="Where Add to library goes"
        text_size={13.5}
        font_weight="semibold"
        text_color={:on_surface}
      />
      <Spacer size={12} />
      <Row fill_width={true} align="center">
        {Kati.UI.symbol("arrow_forward", size: 17, color: Palette.sub())}
        <Spacer size={9} />
        <Column weight={1.0}>
          <Text text="Straight to" text_size={12.5} text_color={Palette.ink_soft()} />
          <Text
            text="the new title’s detail screen"
            text_size={12.5}
            font_weight="semibold"
            text_color={Palette.ink()}
          />
          <Text
            text=", with Year deliberately blank."
            text_size={12.5}
            text_color={Palette.ink_soft()}
          />
          <Text
            text="— 04 for a series, 08 for a film. Returning to 89 would leave the person on a search results page for a title they just finished typing; the detail screen is where the next thing they want to do lives."
            text_size={12.5}
            line_height={1.55}
            text_color={Palette.ink_soft()}
          />
        </Column>
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc """
  A note whose sentence carries two emphasised terms, not one.

  `Kati.Screens.AddByHand.split_note/3` has three parts and this board's notes
  have four — the emphasis falls twice, on the default and on what it means.
  The literal sweep compares a drawing's lines against the tree's, so four
  drawn fragments have to be four nodes.
  """
  @spec two_term_note(String.t(), String.t(), String.t(), String.t()) :: map()
  def two_term_note(lead, mid, emphasis, tail) do
    assigns = %{lead: lead, mid: mid, emphasis: emphasis, tail: tail}

    ~MOB"""
    <Row
      fill_width={true}
      background={Palette.cream()}
      corner_radius={16}
      padding={13}
      align="top"
    >
      {Kati.UI.symbol("info", size: 17, color: Palette.sub())}
      <Spacer size={9} />
      <Column weight={1.0}>
        <Text text={@lead} text_size={12} line_height={1.5} font_weight="semibold" text_color={Palette.ink()} />
        <Text text={@mid} text_size={12} line_height={1.5} text_color={Palette.ink_soft()} />
        <Text text={@emphasis} text_size={12} line_height={1.5} font_weight="semibold" text_color={Palette.ink()} />
        <Text text={@tail} text_size={12} line_height={1.5} text_color={Palette.ink_soft()} />
      </Column>
    </Row>
    """
  end

  @doc """
  The chips as pictures, with no taps on them.

  Reusing `Kati.Screens.AddByHand.kinds/1` put live `kind_Film` and
  `status_*` tags on a reference sheet that answers none of them — #97's second
  trap in as many words: *a preview is not a control*. Screen 119 is the
  precedent, where redrawing `ingredient_row/1` to show what Save would add put
  a live id on a row that answers nothing.
  """
  @spec drawn_kinds() :: map()
  def drawn_kinds do
    ~MOB"""
    <Row fill_width={true} align="center">
      {Kati.Screens.AddByHandStates.drawn_chip("movie", "Film", true)}
      <Spacer size={7} />
      {Kati.Screens.AddByHandStates.drawn_chip("live_tv", "Series", false)}
    </Row>
    """
  end

  @doc false
  @spec drawn_statuses() :: map()
  def drawn_statuses do
    ~MOB"""
    <Row fill_width={true} align="center">
      {["Not started", "Watching", "Finished"]
       |> Enum.map(fn label -> Kati.Screens.AddByHandStates.drawn_chip(nil, label, label == "Not started") end)
       |> Enum.intersperse(AddByHand.gap())}
    </Row>
    """
  end

  @doc false
  def drawn_chip(icon, label, on?) do
    assigns = %{icon: icon, label: label, on?: on?}

    ~MOB"""
    <Row
      height={if @icon, do: 38, else: 32}
      corner_radius={if @icon, do: 19, else: 16}
      background={if @on?, do: Palette.ink_fill(), else: Palette.card()}
      padding_left={15}
      padding_right={15}
      align="center"
    >
      {Kati.Screens.AddByHandStates.glyph(@icon, @on?)}
      <Text
        text={@label}
        text_size={12.5}
        font_weight="semibold"
        text_color={if @on?, do: Palette.on_ink(), else: Palette.ink_soft()}
        max_lines={1}
      />
    </Row>
    """
  end

  @doc false
  def glyph(nil, _on?), do: ~MOB"<Spacer size={0} />"

  def glyph(icon, on?) do
    assigns = %{icon: icon, on?: on?}

    ~MOB"""
    <Row align="center">
      {Kati.UI.symbol(@icon, size: 17, color: if(@on?, do: Palette.on_ink(), else: Palette.ink_soft()))}
      <Spacer size={7} />
    </Row>
    """
  end

  @doc "A field as a picture. This sheet is drawn, not typed into."
  @spec specimen(String.t()) :: map()
  def specimen(placeholder) do
    assigns = %{placeholder: placeholder}

    ~MOB"""
    <Row
      fill_width={true}
      height={48}
      corner_radius={14}
      background={Palette.card()}
      shadow={Kati.Theme.shadow_card_soft()}
      padding_left={15}
      padding_right={15}
      align="center"
    >
      <Text text={@placeholder} text_size={14} text_color={Palette.tertiary()} weight={1.0} max_lines={1} />
    </Row>
    """
  end
end
