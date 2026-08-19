defmodule Kati.Screens.Habits do
  @moduledoc """
  Screen 22 — Habits & streaks, pushed under Stats.

  Built to `.scratch/design/screens/22.html`. The drawing's note is the whole
  argument for the screen: *"habits reuse the calendar's green and the stats
  pixel field. A habit is just a repeating calendar item that keeps a streak —
  no new visual language needed."* Nothing here is invented; every colour and
  every shape already exists on another screen.

  Two things this file is careful about:

    * **A day square has four states, not two.** Green, bronze, grey and empty
      — see `Kati.Habits.Sample`. The third card ticks four days in bronze
      because its streak is two days old; the fourth ticks two in grey because
      its streak is broken. A boolean would flatten that into "some days are
      ticked" and lose the only thing the row is saying.
    * **The 13-week field wraps at 27, not 26.** Screen 07's contribution grid
      breaks at 26 because it sits in a card with 19pt padding; this one sits
      in a card with 18, so one more 8pt cell fits: `27*8 + 26*4 = 320`.
      Neither number is measured — Mob has no wrap primitive — so both are
      declared from the drawing's own arithmetic.

  `M T W T F S S` is a single mono string in the export, letter-spaced to line
  up with the seven squares opposite it, and it is reproduced as one string
  rather than seven labels for exactly that reason.

  No dock on a pushed screen, so the frame ends at 40 rather than 132.
  """
  use Kati.Screens.Pushed, back: "Stats"

  alias Kati.Habits.Sample
  alias Kati.UI

  @doc false
  def content(_assigns) do
    ~MOB"""
    <Scroll>
      <Column fill_width={true} padding_left={21} padding_right={21} padding_top={64} padding_bottom={40}>
        {Kati.Screens.Habits.back_gap()}
        {Kati.Screens.Habits.header()}
        {Kati.Screens.Habits.cards()}
        {UI.eyebrow("Consistency · 13 weeks")}
        {Kati.Screens.Habits.consistency()}
      </Column>
    </Scroll>
    """
  end

  # `Kati.Screens.Pushed` floats the back pill over the content, so the content
  # leaves room for it: a 42pt pill and the drawing's 16pt gap under it.
  @doc false
  def back_gap, do: ~MOB"<Spacer size={58} />"

  @doc false
  def header do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        <Column weight={1.0}>
          <Text text="Habits" text_size={28} font_weight="bold" letter_spacing={-0.03} text_color={:on_surface} />
          <Spacer size={5} />
          <Text text={Kati.Habits.Sample.subtitle()} font_family="mono" text_size={11} text_color={0xFFA9A29A} max_lines={1} />
        </Column>
        {Kati.Screens.Habits.disc("add", :new_habit)}
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc false
  def disc(icon, tag) do
    tap = {self(), tag}

    ~MOB"""
    <Box
      width={44}
      height={44}
      background={Kati.Theme.card(:light)}
      corner_radius={22}
      shadow={Kati.Theme.shadow_button()}
      align="center"
      on_tap={tap}
    >
      {Kati.UI.symbol(icon, size: 21)}
    </Box>
    """
  end

  @doc false
  def cards do
    children =
      Sample.habits()
      |> Enum.map(&card/1)
      |> Enum.intersperse(card_gap())

    ~MOB"""
    <Column fill_width={true}>
      {children}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def card_gap, do: ~MOB"<Spacer size={11} />"

  @doc false
  def card(habit) do
    ~MOB"""
    <Column
      fill_width={true}
      background={Kati.Theme.card(:light)}
      corner_radius={20}
      shadow={Kati.Theme.shadow_card_soft()}
      padding={15}
    >
      <Row fill_width={true} align="center">
        <Column weight={1.0}>
          <Text text={habit.name} text_size={14} font_weight="bold" letter_spacing={-0.015} text_color={:on_surface} max_lines={1} />
          <Spacer size={4} />
          <Text text={habit.streak} font_family="mono" text_size={10.5} text_color={0xFFA9A29A} max_lines={1} />
        </Column>
        <Spacer size={12} />
        {Kati.Screens.Habits.today_button(habit.today)}
      </Row>
      <Spacer size={13} />
      <Row fill_width={true} align="center">
        {Kati.Screens.Habits.week(habit.days)}
        <Spacer weight={1.0} />
        <Text
          text={Kati.Habits.Sample.week_ruler()}
          font_family="mono"
          text_size={9.5}
          letter_spacing={0.08}
          text_color={0xFFC4BDB3}
          max_lines={1}
        />
      </Row>
    </Column>
    """
  end

  # Ticked today is the calendar's green with a white check; not yet is the
  # paper colour with a #C4BDB3 one — present but unlit, so the target reads as
  # something you can still press rather than something that failed.
  @doc false
  def today_button(true) do
    tap = {self(), :toggle_today}

    ~MOB"""
    <Box width={34} height={34} corner_radius={17} background={0xFF4E9A73} align="center" on_tap={tap}>
      {Kati.UI.symbol("check", size: 19, color: 0xFFFBFAF8)}
    </Box>
    """
  end

  def today_button(false) do
    tap = {self(), :toggle_today}

    ~MOB"""
    <Box width={34} height={34} corner_radius={17} background={0xFFEFECE7} align="center" on_tap={tap}>
      {Kati.UI.symbol("check", size: 19, color: 0xFFC4BDB3)}
    </Box>
    """
  end

  @doc false
  def week(days) do
    children =
      days
      |> Enum.map(&day_square/1)
      |> Enum.intersperse(day_gap())

    ~MOB"""
    <Row align="center">
      {children}
    </Row>
    """
  end

  @doc false
  def day_gap, do: ~MOB"<Spacer size={5} />"

  @doc false
  def day_square(state) do
    tone = Sample.day_tone(state)

    if Sample.ticked?(state) do
      ~MOB"""
      <Box width={16} height={16} corner_radius={5} background={tone} align="center">
        {Kati.UI.symbol("check", size: 11, color: 0xFFFBFAF8)}
      </Box>
      """
    else
      ~MOB"""
      <Box width={16} height={16} corner_radius={5} background={tone} />
      """
    end
  end

  @doc false
  def consistency do
    rows = Sample.consistency() |> Enum.chunk_every(27)
    {month, hit} = Sample.consistency_caption()

    ~MOB"""
    <Column
      fill_width={true}
      background={0xFFFBF1DE}
      corner_radius={22}
      shadow={Kati.Theme.shadow_card_soft()}
      padding={18}
    >
      {Enum.map(rows, fn row -> Kati.Screens.Habits.cell_row(row) end)}
      <Spacer size={8} />
      <Row fill_width={true} align="center">
        <Text text={month} font_family="mono" text_size={10} text_color={0xFFB09A72} max_lines={1} />
        <Spacer weight={1.0} />
        <Text text={hit} font_family="mono" text_size={10} text_color={0xFFB09A72} max_lines={1} />
      </Row>
    </Column>
    """
  end

  # The 4pt gap below each row is drawn as part of the row rather than between
  # rows, which is why the caption above adds only 8 more to reach the
  # drawing's 12: the last row has already contributed 4.
  @doc false
  def cell_row(row) do
    children =
      row
      |> Enum.map(&cell/1)
      |> Enum.intersperse(cell_gap())

    ~MOB"""
    <Column>
      <Row>
        {children}
      </Row>
      <Spacer size={4} />
    </Column>
    """
  end

  @doc false
  def cell_gap, do: ~MOB"<Spacer size={4} />"

  @doc false
  def cell(state) do
    tone = Sample.cell_tone(state)

    ~MOB"""
    <Box width={8} height={8} corner_radius={2} background={tone} />
    """
  end
end
