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

  ## Every number on this screen is derived from the habit list

  The drawing prints three counts — the header's *"4 active · 12-day best"*, a
  streak line per card, and the today tick — and the first two are functions of
  the third. So `:habits` holds only what a tap can actually change:

    * `today` — whether the round button is lit
    * `base` — the streak *before* today, which a tap never moves

  and `streak_days/1`, `streak_line/1` and `subtitle/1` compute the rest at
  render. Storing the rendered `"12 days"` alongside the tick would let a tap
  move one and not the other, and the screen would print a lit tick above a
  broken streak. `load/1` splits the sample's rendered string into that number
  once, at the seam, and nothing reads the string again.

  At rest this reproduces the export exactly: `11 + 1 = 12 days`, `4 + 1 =
  5 days`, `2 + 0 = 2 days`, `0 + 0 = broken`, and `4 active · 12-day best`.

  **The seven squares are history, not today.** The third card is ticked on its
  last square while its today button is dark, so the week strip is not a
  rolling window ending at today and there is no square a tap may flip without
  inventing a weekday mapping the drawing does not carry. A toggle therefore
  moves the button, the streak line and the header — and leaves the week alone.
  """
  use Kati.Screens.Pushed, back: "Stats"

  alias Kati.Habits.Sample
  alias Kati.UI

  @impl true
  def load(socket), do: Mob.Socket.assign(socket, :habits, Enum.map(Sample.habits(), &adopt/1))

  @doc false
  def content(assigns) do
    habits = assigns.habits

    ~MOB"""
    <Scroll>
      <Column fill_width={true} padding_left={21} padding_right={21} padding_top={64} padding_bottom={40}>
        {Kati.Screens.Habits.back_gap()}
        {Kati.Screens.Habits.header(habits)}
        {Kati.Screens.Habits.cards(habits)}
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
  def header(habits) do
    subtitle = subtitle(habits)

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        <Column weight={1.0}>
          <Text text="Habits" text_size={28} font_weight="bold" letter_spacing={-0.03} text_color={:on_surface} />
          <Spacer size={5} />
          <Text text={subtitle} font_family="mono" text_size={11} text_color={0xFFA9A29A} max_lines={1} />
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

  # Indexed, because every card's today button carries the same verb and only
  # its position tells them apart — the tag is `toggle_today_2`, not a shared
  # `:toggle_today` that four cards would all answer to.
  @doc false
  def cards(habits) do
    children =
      habits
      |> Enum.with_index()
      |> Enum.map(fn {habit, index} -> card(habit, index) end)
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
  def card(habit, index) do
    streak = streak_line(habit)

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
          <Text text={streak} font_family="mono" text_size={10.5} text_color={0xFFA9A29A} max_lines={1} />
        </Column>
        <Spacer size={12} />
        {Kati.Screens.Habits.today_button(habit.today, index)}
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
  def today_button(true, index) do
    tap = toggle_tap(index)

    ~MOB"""
    <Box width={34} height={34} corner_radius={17} background={0xFF4E9A73} align="center" on_tap={tap}>
      {Kati.UI.symbol("check", size: 19, color: 0xFFFBFAF8)}
    </Box>
    """
  end

  def today_button(false, index) do
    tap = toggle_tap(index)

    ~MOB"""
    <Box width={34} height={34} corner_radius={17} background={0xFFEFECE7} align="center" on_tap={tap}>
      {Kati.UI.symbol("check", size: 19, color: 0xFFC4BDB3)}
    </Box>
    """
  end

  defp toggle_tap(index), do: {self(), String.to_atom("toggle_today_" <> Integer.to_string(index))}

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

  # ── What a tap changes ────────────────────────────────────────────────────

  @impl true
  def handle_tap(:new_habit, socket) do
    {:noreply, Mob.Socket.update(socket, :habits, &Kati.Screens.Habits.add_habit/1)}
  end

  # One clause for every card's today button: the tag carries the row, so a
  # fifth habit is a data change rather than a code change.
  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "toggle_today_" <> index ->
        {:noreply, Mob.Socket.update(socket, :habits, &Kati.Screens.Habits.toggle_today(&1, index))}

      _ ->
        {:noreply, socket}
    end
  end

  @doc """
  Flip one habit's today tick.

  `base` is deliberately untouched — the streak before today does not change
  because you ticked today — so the card's line and the header's best both move
  by exactly one and cannot disagree. An index that is not a row leaves the
  list alone rather than raising into `Kati.Screens.Root.rescue_tap/3`.
  """
  @spec toggle_today([map()], String.t()) :: [map()]
  def toggle_today(habits, index) do
    case Integer.parse(index) do
      {i, ""} -> List.update_at(habits, i, &%{&1 | today: not &1.today})
      _ -> habits
    end
  end

  @doc """
  A new habit, at the top of the stack.

  Newest first, for the reason `Kati.Screens.Lists.add_list/1` gives: the point
  of pressing `+` is to see the thing you just made, and below four cards the
  fifth is off the bottom of the phone — a control whose result is out of frame
  reads as broken.

  It carries the card the drawing already draws, in its emptiest state: no
  streak, an unlit today button, and seven `:missed` squares. That is the
  fourth card minus its two lapsed ticks, so nothing new is drawn. Its line
  reads `broken` rather than a fresh third string, because `broken` and
  `N days` are the only two the export has and inventing a third would put a
  label on the screen the design never wrote. One tap on its today button
  makes it `1 day`.
  """
  @spec add_habit([map()]) :: [map()]
  def add_habit(habits) do
    [%{name: "New habit", base: 0, today: false, days: List.duplicate(:missed, 7)} | habits]
  end

  # ── What the screen prints, all of it derived ─────────────────────────────

  @doc "The streak a habit is on right now, today included if today is ticked."
  @spec streak_days(map()) :: non_neg_integer()
  def streak_days(%{base: base, today: true}), do: base + 1
  def streak_days(%{base: base, today: false}), do: base

  @doc "That number as the card's mono line — the export's only two forms."
  @spec streak_line(map()) :: String.t()
  def streak_line(habit) do
    case streak_days(habit) do
      0 -> "broken"
      1 -> "1 day"
      n -> Integer.to_string(n) <> " days"
    end
  end

  @doc """
  The header's mono line, counted off the list rather than written down.

  `Kati.Habits.Sample.subtitle/0` is the same string as a constant, and that is
  exactly what it cannot stay: pressing `+` moves the count and unticking the
  first card moves the best, and a constant would keep printing `4 active ·
  12-day best` over a screen showing neither.
  """
  @spec subtitle([map()]) :: String.t()
  def subtitle(habits) do
    best = habits |> Enum.map(&streak_days/1) |> Enum.max(fn -> 0 end)

    Integer.to_string(length(habits)) <>
      " active · " <> Integer.to_string(best) <> "-day best"
  end

  # The seam. `Kati.Habits.Sample` stores a habit's streak the way the drawing
  # prints it, which is fine for a still picture and useless to a tap; this
  # reads that string once, at mount, and the screen works in numbers from
  # there. `Integer.parse/1` rather than `String.to_integer/1` because "broken"
  # is one of the sample's own values and a raise here happens in `mount/3`,
  # outside the tap rescue, where it would take the whole screen down.
  defp adopt(habit) do
    today = habit.today

    %{
      name: habit.name,
      today: today,
      days: habit.days,
      base: parse_streak(habit.streak) - if(today, do: 1, else: 0)
    }
  end

  defp parse_streak(line) do
    case Integer.parse(line) do
      {n, _rest} -> n
      :error -> 0
    end
  end
end
