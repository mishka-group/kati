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
  alias Kati.Theme.Palette
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
          <Text text={subtitle} font_family="mono" text_size={11} text_color={Palette.muted()} max_lines={1} />
        </Column>
        {Kati.Screens.Habits.disc("add", :new_habit)}
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc """
  The 44pt floating disc opposite the title — here, the `+` that adds a habit.

  `Kati.Components.MishkaActionIcon`, which it could not be until the port grew
  a `shadow` prop. `today_button/2` below adopted the same component and had to
  record that this disc could not follow it, "because the port has no `shadow`
  prop to put it back" — and a floating disc is *defined* by its shadow, so that
  was the whole of the gap. It is closed.

  **The pixels are the same node.** The port builds

      <Box width={44} height={44} align={:center} corner_radius={22.0}
           background=… shadow=… on_tap=…><Row>{glyph}</Row></Box>

  where this was `<Box width={44} height={44} background corner_radius={22}
  shadow align="center" on_tap>`. Prop for prop: `shape: :circle` resolves to an
  exact `size / 2`, so 44 gives the drawing's own 22; `align={:center}` is an
  atom the renderer serialises to the same `"center"` string the markup wrote,
  and `MobBridge.boxAlignProp` reads it identically; `variant: :filled` is what
  lets `background` through, since the port paints `:transparent` on the default
  `:plain`; and `shadow` rides on the container untouched.

  The one addition is the `Row` the port wraps children in. A `Row` carrying no
  props takes no modifier and hugs its single child, so the glyph measures
  exactly as before and the Box centres the same box it centred.
  """
  def disc(icon, tag) do
    Kati.Components.MishkaActionIcon.action_icon(
      [
        size: 44,
        shape: :circle,
        variant: :filled,
        background: Palette.card(),
        shadow: Kati.Theme.shadow_button(),
        on_tap: {self(), tag}
      ],
      [Kati.UI.symbol(icon, size: 21)]
    )
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
      background={Palette.card()}
      corner_radius={20}
      shadow={Kati.Theme.shadow_card_soft()}
      padding={15}
    >
      <Row fill_width={true} align="center">
        <Column weight={1.0}>
          <Text text={habit.name} text_size={14} font_weight="bold" letter_spacing={-0.015} text_color={:on_surface} max_lines={1} />
          <Spacer size={4} />
          <Text text={streak} font_family="mono" text_size={10.5} text_color={Palette.muted()} max_lines={1} />
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
          text_color={Palette.rail_idle()}
          max_lines={1}
        />
      </Row>
    </Column>
    """
  end

  @doc """
  The 34pt round tick at the end of a habit's title row.

  Ticked today is the calendar's green with a white check; not yet is the paper
  colour with a `#C4BDB3` one — present but unlit, so the target reads as
  something you can still press rather than something that failed.

  `Kati.Components.MishkaActionIcon` rather than a hand-rolled `Box`, because a
  round tap target holding one glyph is exactly what that component is. It also
  collapses the two clauses this was: with the shape and the tap coming from the
  component, the whole difference between ticked and not is two colours, and two
  colours read better as two locals than as two copies of the same markup.

  `variant: :filled` is what lets `background` through — the port paints
  `:transparent` on the default `:plain` — and `shape: :circle` resolves to an
  exact `size / 2`, so 34 gives the drawing's own 17.

  **The pixels are the same node.** The port renders
  `<Box width height align={:center} corner_radius background on_tap>` around a
  `<Row>` holding the glyph, and a `Row` given no props hugs its one child, so
  the check measures and centres where it did before. This was for a while the
  only disc on the screen that could move, because it is the only one carrying
  no shadow and the port had no `shadow` prop to put one back; `disc/2` above
  now takes the same route, because the port has one.
  """
  def today_button(ticked?, index) do
    background = if ticked?, do: Palette.green(), else: Palette.paper()

    # `0xFFFBFAF8` LEFT AS A LITERAL. `Kati.Theme.Palette` names four meanings
    # for this value — the card, a label on an ink fill, the FAB's plus, and a
    # title over artwork — and this is none of them: it is a glyph on a HUE.
    # Green is `:hue`, so it does not move with the mode; a check that followed
    # the mode would turn to ink on a green disc that never darkened. The two
    # tokens that keep this value in dark are scoped to a photographic ground
    # (`on_media`) or to the FAB, so neither is honestly this. Left, and
    # reported: the table has no "on a hue fill" row.
    ink = if ticked?, do: 0xFFFBFAF8, else: Palette.rail_idle()

    Kati.Components.MishkaActionIcon.action_icon(
      [
        size: 34,
        shape: :circle,
        variant: :filled,
        background: background,
        on_tap: toggle_tap(index)
      ],
      [Kati.UI.symbol("check", size: 19, color: ink)]
    )
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

  # `0xFFFBFAF8` LEFT AS A LITERAL, for the reason `today_button/2` records: the
  # ground under this tick is `Kati.Habits.Sample.day_tone/1` — green, bronze or
  # the lapsed grey — and none of the three follows the mode, so the tick must
  # not either.
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
      background={Palette.cream()}
      corner_radius={22}
      shadow={Kati.Theme.shadow_card_soft()}
      padding={18}
    >
      {Enum.map(rows, fn row -> Kati.Screens.Habits.cell_row(row) end)}
      <Spacer size={8} />
      <Row fill_width={true} align="center">
        <Text text={month} font_family="mono" text_size={10} text_color={Palette.cream_meta()} max_lines={1} />
        <Spacer weight={1.0} />
        <Text text={hit} font_family="mono" text_size={10} text_color={Palette.cream_meta()} max_lines={1} />
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
