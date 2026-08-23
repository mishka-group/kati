defmodule Kati.Screens.YearCards do
  @moduledoc """
  Screen 100 — Year cards, pushed under Settings.

  **The authoritative render spec**, and the design's caption says so: *four
  faces at both ratios on one board, so the generator has nothing to infer.*
  This screen is a reference sheet in screen 27's manner rather than a place in
  the app — it exists so that whatever eventually writes the PNG has one page
  to be compared against.

  ## Story re-scales, it does not crop

  The reflow question the ticket left open, answered: *the same elements, larger
  type and looser spacing to fill the taller frame. Nothing is cut, because a
  cropped chart is a wrong chart.* Crop would truncate a bar chart, and restack
  would give the generator eight layouts to maintain instead of four.

  So `face/2` takes the ratio and changes only the scale, and there is no
  branch anywhere in this file that omits an element at one ratio and draws it
  at the other.

  ## No orange on any card

  The palette rule, and it has a reason rather than a preference behind it:
  **a saved image has no "now" to point at.** Orange means new/now everywhere
  else in Kati, and an image that outlives the day it was made cannot mean now.
  The field uses the bronze ramp and the bars a four-tone ink ramp.

  ## Only the field card carries the wordmark

  Screen 98 gives the reasoning and this sheet obeys it: the field is the card
  people ask about, so it is the one that answers.
  """

  use Kati.Screens.Pushed, back: "Settings"

  alias Kati.Stats.ShareSample
  alias Kati.Theme.Palette
  alias Kati.UI.SettingsList

  # The two ratios, with the scale each multiplies the type and spacing by.
  # One number per ratio rather than a table of sizes: re-scale means exactly
  # that, and a per-element table would be the eight layouts the caption
  # rejects.
  @ratios [{"4:5 Square", 1.0}, {"9:16 Story", 1.25}]

  def load(socket), do: socket

  @doc false
  def content(_assigns) do
    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {SettingsList.chrome(nil, 44)}
        {SettingsList.title("Year cards", "FOUR FACES × TWO RATIOS")}
        {Kati.Screens.YearCards.palette_note()}
        {Kati.Screens.YearCards.boards()}
        {Kati.Screens.YearCards.rescale_note()}
      </Column>
    </Scroll>
    """
  end

  @doc "The palette sentence and the rule inside it."
  @spec palette_note() :: map()
  def palette_note do
    ~MOB"""
    <Column fill_width={true}>
      <Text
        text={Kati.Stats.ShareSample.palette_note()}
        text_size={12.5}
        line_height={1.55}
        text_color={Palette.ink_soft()}
      />
      <Spacer size={22} />
    </Column>
    """
  end

  @doc "Both ratios, each with all four faces."
  @spec boards() :: map()
  def boards do
    boards =
      @ratios
      |> Enum.map(fn {label, scale} -> Kati.Screens.YearCards.board(label, scale) end)
      |> Enum.intersperse(~MOB"<Spacer size={24} />")

    ~MOB"""
    <Column fill_width={true}>
      {boards}
      <Spacer size={20} />
    </Column>
    """
  end

  @doc false
  def board(label, scale) do
    assigns = %{
      label: label,
      faces:
        ShareSample.faces()
        |> Enum.map(&Kati.Screens.YearCards.face(&1, scale))
        |> Enum.intersperse(~MOB"<Spacer size={11} />")
    }

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.eyebrow(@label)}
      {@faces}
    </Column>
    """
  end

  @doc """
  One card face at one scale.

  Every face is drawn at both ratios — see the moduledoc. `scale` multiplies
  the type; nothing is added or removed.
  """
  @spec face(atom(), float()) :: map()
  def face(:hours, scale) do
    h = ShareSample.hours()

    assigns = %{
      label: String.upcase(h.label),
      figure: h.figure,
      change: h.change,
      year: h.year,
      figure_size: 30 * scale,
      label_size: 10 * scale
    }

    ~MOB"""
    <Column fill_width={true} background={Palette.card()} corner_radius={20} padding={17}>
      <Text
        text={@label}
        font_family="mono"
        text_size={@label_size}
        letter_spacing={0.14}
        text_color={Palette.muted()}
      />
      <Spacer size={9} />
      <Row fill_width={true} align="bottom">
        <Text
          text={@figure}
          text_size={@figure_size}
          font_weight="extrabold"
          letter_spacing={-0.035}
          text_color={:on_surface}
        />
        <Spacer size={9} />
        {Kati.UI.symbol("arrow_drop_up", size: 18, color: Palette.bar_ink())}
        <Text text={@change} font_family="mono" text_size={12} text_color={Palette.ink_soft()} />
        <Spacer weight={1.0} />
        <Text text={@year} font_family="mono" text_size={11} text_color={Palette.muted()} />
      </Row>
    </Column>
    """
  end

  def face(:top_titles, scale) do
    assigns = %{
      label_size: 10 * scale,
      posters: Kati.Screens.YearShare.posters(),
      ranks: Kati.Screens.YearShare.ranks()
    }

    ~MOB"""
    <Column fill_width={true} background={Palette.card()} corner_radius={20} padding={17}>
      <Text
        text="TOP TITLES"
        font_family="mono"
        text_size={@label_size}
        letter_spacing={0.14}
        text_color={Palette.muted()}
      />
      <Spacer size={11} />
      {@posters}
      <Spacer size={13} />
      {@ranks}
    </Column>
    """
  end

  def face(:where_hours_went, scale) do
    top = ShareSample.where_hours_went() |> Enum.map(&elem(&1, 1)) |> Enum.max()

    assigns = %{
      label_size: 10 * scale,
      bars:
        ShareSample.where_hours_went()
        |> Enum.with_index()
        |> Enum.map(fn {{genre, hours}, index} ->
          Kati.Screens.YearCards.bar(genre, hours, top, index, scale)
        end)
        |> Enum.intersperse(~MOB"<Spacer size={9} />")
    }

    ~MOB"""
    <Column fill_width={true} background={Palette.card()} corner_radius={20} padding={17}>
      <Text
        text="WHERE THE HOURS WENT"
        font_family="mono"
        text_size={@label_size}
        letter_spacing={0.14}
        text_color={Palette.muted()}
      />
      <Spacer size={12} />
      {@bars}
    </Column>
    """
  end

  def face(:field, scale) do
    f = ShareSample.field_face()

    assigns = %{
      year: f.year,
      title: f.title,
      span: f.span,
      wordmark: f.wordmark,
      title_size: 22 * scale,
      field: Kati.Screens.AlbumDetail.field_rows()
    }

    ~MOB"""
    <Column fill_width={true} background={Palette.card()} corner_radius={20} padding={17}>
      <Text
        text={@year}
        font_family="mono"
        text_size={11}
        letter_spacing={0.14}
        text_color={Palette.muted()}
      />
      <Spacer size={6} />
      <Text
        text={@title}
        text_size={@title_size}
        font_weight="extrabold"
        letter_spacing={-0.03}
        text_color={:on_surface}
      />
      <Spacer size={14} />
      {@field}
      <Spacer size={13} />
      <Row fill_width={true} align="center">
        <Text
          text={@span}
          font_family="mono"
          text_size={9.5}
          letter_spacing={0.12}
          text_color={Palette.muted()}
        />
        <Spacer weight={1.0} />
        <Text
          text={@wordmark}
          text_size={13}
          font_weight="bold"
          letter_spacing={-0.02}
          text_color={:on_surface}
        />
      </Row>
    </Column>
    """
  end

  @doc """
  One genre bar, on the four-tone ink ramp.

  A ramp rather than a hue per genre, because a saved image has no legend
  beside it — four colours meaning four genres would need one, and a card that
  needs a legend is a card that has failed.
  """
  @spec bar(String.t(), integer(), integer(), integer(), float()) :: map()
  def bar(genre, hours, top, index, scale) do
    rail =
      Kati.Components.MishkaProgress.progress(
        render: :box,
        value: hours / max(top, 1),
        max: 1,
        height: 6,
        corner_radius: 3,
        color: Kati.Screens.YearCards.tone(index),
        track_color: Palette.track()
      )

    assigns = %{
      genre: genre,
      hours: Integer.to_string(hours),
      rail: rail,
      size: 12 * scale
    }

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Text
          text={@genre}
          text_size={@size}
          font_weight="semibold"
          text_color={:on_surface}
          max_lines={1}
          weight={1.0}
        />
        <Spacer size={10} />
        <Text text={@hours} font_family="mono" text_size={@size} text_color={Palette.sub()} />
      </Row>
      <Spacer size={6} />
      {@rail}
    </Column>
    """
  end

  @doc "The four-tone ink ramp, darkest first."
  @spec tone(integer()) :: integer()
  def tone(0), do: Palette.ink()
  def tone(1), do: Palette.bar_ink()
  def tone(2), do: Palette.settled_ink()
  def tone(_rest), do: Palette.tertiary()

  @doc "The sentence that answers the reflow question."
  @spec rescale_note() :: map()
  def rescale_note do
    SettingsList.note(
      "info",
      "Story re-scales rather than crops: the same elements, larger type and looser " <>
        "spacing to fill the taller frame. Nothing is cut, because a cropped chart is a " <>
        "wrong chart. Only the field card carries the wordmark."
    )
  end

  # A reference sheet has nothing to tap, which is screen 27's arrangement
  # exactly. The clause is here so a stray tag is a quiet no-op rather than a
  # `DEAD TAP` in the log.
  @doc false
  def handle_tap(_tag, socket), do: {:noreply, socket}
end
