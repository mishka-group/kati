defmodule Kati.UI.Destructive do
  @moduledoc """
  The confirmation a write shows before it destroys something, and the bar it
  shows after.

  ## The confirmation

  Board 269's recipe, and board 330 is what widened it: *"269's recipe, widened
  — not a new one. It was scoped to 267, 268 and 80; a cascading delete is
  exactly what it was built for, and it already leads with what survives."*

  Two labelled halves — **Changes:** and **Does not change:** — because the
  question a reader actually has is *what happens to my things*, and a single
  paragraph lets the reassuring half be skimmed past. `Kati.Screens.Currency`
  drew this first for a currency switch and its own doc states the rule; this
  module is that drawing, lifted so a second caller does not redraw it.

  ## The bar

  Board 146's undo bar, widened by 330 for the same reason. A remove takes no
  confirmation — *"one title, one tap, undo below. A dialog for one row is the
  thing 146 declined"* — so the bar is what makes it recoverable, and a delete
  gets both.
  """

  use Gettext, backend: Kati.Gettext

  import Mob.Sigil

  alias Kati.Theme.Palette

  @doc """
  The two-clause confirmation card.

  `changes` and `keeps` are the halves; `confirm` and `keep` are `{label, tag}`
  pairs. The eyebrow is the caller's, because what is being changed is the
  caller's word for it.
  """
  @spec confirm(keyword()) :: map()
  def confirm(opts) do
    assigns = %{
      eyebrow: Keyword.fetch!(opts, :eyebrow),
      title: Keyword.fetch!(opts, :title),
      changes: Keyword.fetch!(opts, :changes),
      keeps: Keyword.fetch!(opts, :keeps),
      confirm_label: opts |> Keyword.fetch!(:confirm) |> elem(0),
      confirm_tap: {self(), opts |> Keyword.fetch!(:confirm) |> elem(1)},
      keep_label: opts |> Keyword.fetch!(:keep) |> elem(0),
      keep_tap: {self(), opts |> Keyword.fetch!(:keep) |> elem(1)}
    }

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.eyebrow(@eyebrow, dash: Kati.Theme.Palette.bronze())}
      <Column fill_width={true} background={Palette.cream()} corner_radius={22} padding={17}>
        <Row fill_width={true} align="center">
          {Kati.UI.symbol("error", size: 18, color: Palette.gold_icon())}
          <Spacer size={11} />
          <Text
            text={@title}
            text_size={15}
            font_weight="bold"
            text_color={Palette.cream_ink()}
            max_lines={2}
          />
        </Row>
        <Spacer size={13} />
        {Kati.UI.Destructive.clause(gettext("Changes:"), @changes)}
        <Spacer size={9} />
        {Kati.UI.Destructive.clause(gettext("Does not change:"), @keeps)}
        <Spacer size={15} />
        <Row fill_width={true} align="center">
          <Row
            height={38}
            corner_radius={19}
            background={Palette.ink_fill()}
            padding_left={16}
            padding_right={16}
            align="center"
            on_tap={@confirm_tap}
          >
            <Text
              text={@confirm_label}
              text_size={12.5}
              font_weight="bold"
              text_color={Palette.on_ink()}
              max_lines={1}
            />
          </Row>
          <Spacer size={14} />
          <Text
            text={@keep_label}
            text_size={12.5}
            font_weight="semibold"
            text_color={Palette.cream_sub()}
            on_tap={@keep_tap}
          />
          <Spacer weight={1.0} />
        </Row>
      </Column>
    </Column>
    """
  end

  @doc false
  @spec clause(String.t(), String.t()) :: map()
  def clause(label, body) do
    assigns = %{label: label, body: body}

    ~MOB"""
    <Column fill_width={true}>
      <Text text={@label} text_size={13} font_weight="semibold" text_color={Palette.cream_ink()} />
      <Spacer size={4} />
      <Text text={@body} text_size={13} line_height={1.5} text_color={Palette.cream_body()} />
    </Column>
    """
  end

  @doc """
  Board 146's undo bar: what happened, and the one word that takes it back.

  `nil` draws nothing at all rather than an empty bar — a bar with no sentence
  is a control with nothing behind it, which is the rule the whole ledger was
  closed against.
  """
  @spec undo_bar(String.t() | nil, atom()) :: map()
  def undo_bar(nil, _tag), do: ~MOB"<Spacer size={0} />"

  def undo_bar(sentence, tag) do
    assigns = %{sentence: sentence, tap: {self(), tag}}

    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={14} />
      <Row
        fill_width={true}
        height={46}
        corner_radius={23}
        background={Palette.ink_fill()}
        padding_left={16}
        padding_right={16}
        align="center"
      >
        {Kati.UI.symbol("undo", size: 17, color: Kati.Theme.Palette.on_ink())}
        <Spacer size={11} />
        <Text
          text={@sentence}
          text_size={12.5}
          font_weight="semibold"
          text_color={Palette.on_ink()}
          max_lines={1}
          weight={1.0}
        />
        <Spacer size={11} />
        <Text
          text={gettext("Undo")}
          text_size={12.5}
          font_weight="bold"
          text_color={Palette.on_ink()}
          max_lines={1}
          on_tap={@tap}
        />
      </Row>
    </Column>
    """
  end
end
