defmodule Kati.Screens.QuickAdd do
  @moduledoc """
  Screen 18 — Quick add.

  Built to `test/design/screens/18.html`: the `64px 21px 40px` frame with
  no dock at the bottom, a focused field carrying a 2px ink ring, the cream
  card of what Kati understood, the six things the sentence could be filed as,
  and a 52pt commit row with a microphone beside it.

  ## The three ideas the drawing is making

    1. **One field for the whole app.** The chip row is not a filter — it is
       every section Kati keeps, and the sentence becomes whichever one you
       pick. That is why `Title`, `Habit` and `Expense` sit next to `Event`.
    2. **The parse is shown before it is committed.** Tokens are tinted where
       they were typed, not summarised underneath, so the user can see what was
       understood while the caret is still in the line.
    3. **The clash arrives before the save, not after.** The `info` row is
       inside the cream card, above the button, and it ends in a question.

  ## Not `Kati.Screens.Pushed`

  The drawing dismisses itself with a 44pt `close` disc in its own header. The
  pushed chrome would float a second back affordance over the title, so this
  screen owns its `mount/3` and `render/1` — the same choice screen 06 made,
  and for the same reason. #45 turns both into native sheets later.

  ## Where the drawing wraps

  Two places wrap in the browser and cannot wrap here: the typed sentence and
  the fact chips. Both are declared as lines in `Kati.Screens.QuickAdd.Sample`
  at the break the drawing shows, because `Row` does not wrap and no geometry
  comes back from `render/1`.

  ## Why this screen still reads `Kati.Screens.QuickAdd.Sample`

  Screen 03 moved onto `Kati.Media` and screens 43-48 onto `Kati.Meals`. This
  one has nothing to move onto, and the gap is neither a resource nor a
  column: **every value on this screen is the output of a parser, and `lib/`
  has none.** `Kati.Recurrence.Rule` parses an RRULE and `Kati.Sync.ICalendar`
  parses iCalendar; nothing turns *dentist thu 11am for 45m, remind 1h before*
  into a title, a kind, a start, a duration and an alarm. A store cannot
  supply what has never been computed.

  Precisely what this screen draws and nothing can currently produce:

    * **the tinted spans in the field** — which characters of the typed line
      were understood, and as what. That is a set of offsets into a string the
      user is still typing; it is the parse itself, drawn in place, and it is
      the design's whole first claim.
    * **`Dentist` and `PERSONAL EVENT`** — the title lifted out of the
      sentence and the kind inferred from it.
    * **the fact chips** — `Thu 20 Aug`, `11:00 – 11:45`, `10:00 alert`,
      `Personal`. Every one is a field of the event the parse would build. The
      event does not exist yet, and an uncommitted draft is stored nowhere:
      there is no draft resource, and `Kati.Calendars.Event` is what the user
      gets *after* tapping the button.
    * **`Add to Thursday`** — the day is the parsed start.
    * **the six kind chips' selection** — which of `Event`, `Reminder`,
      `Title`, `Habit`, `Note`, `Expense` the sentence was filed as. The list
      is fixed copy, so it is real; the tick on the first one is the parse.

  One half of one row *is* nearly reachable and is deliberately not split out.
  `Clashes with Design review` is a range query against
  `Kati.Calendars.Event`, which holds that very event —
  `Kati.Calendars.Today` already does the range arithmetic and `Kati.Seeds`
  writes Design review onto the Work calendar. It stays frozen because the
  window to test against (Thursday 11:00 to 11:45) comes out of the parse, so
  there is nothing yet to ask the calendar about. It lands the day the parser
  does, and it is the first thing on this screen that should.
  """
  use Mob.Screen
  import Mob.Sigil

  alias Kati.Components.MishkaActionIcon
  alias Kati.Components.MishkaCloseButton
  alias Kati.Components.MishkaSeparator
  alias Kati.Components.MishkaThemeIcon
  alias Kati.Screens.QuickAdd.Sample
  alias Kati.Theme.Palette
  alias Kati.UI

  # A caller may name the sentence. Screen 08's *Schedule* opens this with
  # `Watch <title>` already typed, because the verb and the subject are the
  # part a reader should not have to retype — what they came here to say is
  # WHEN.
  def mount(params, _session, socket) do
    Mob.Theme.set(Kati.Theme.current())

    sentence = Map.get(params || %{}, :sentence, "")

    {:ok,
     socket
     |> Mob.Socket.assign(:params, params)
     |> Mob.Socket.assign(:sentence, sentence)
     |> Mob.Socket.assign(:save_error, nil)
     |> Mob.Socket.assign(:draft, Kati.Screens.QuickAdd.draft(sentence))}
  end

  @doc """
  What the page draws for a typed sentence: the board's own until one is typed.

  MOVIES-AND-TV.md #31 — the field, the parse card, the clash warning and the
  commit button were all `Kati.Screens.QuickAdd.Sample.draft/0`, which is one
  sentence somebody typed into a design tool. Every one of them is read from
  what the reader typed now, through `Kati.QuickAdd.Parse`.

  An empty field keeps the board, and that is not a fallback for want of
  anything better: board 18 is drawn MID-TYPING, and its sentence is the
  clearest statement of the syntax this screen has. Somebody who opens the
  page and types nothing is looking at an example, which is exactly what they
  need.
  """
  @spec draft(String.t()) :: map()
  def draft(sentence) when is_binary(sentence) do
    case String.trim(sentence) do
      "" -> Sample.draft()
      typed -> Kati.Screens.QuickAdd.read_draft(typed)
    end
  end

  @doc false
  @spec read_draft(String.t()) :: map()
  def read_draft(typed) do
    today = Kati.Time.today()
    read = Kati.QuickAdd.Parse.read(typed, today)

    %{
      query: Kati.Screens.QuickAdd.echo(typed, read.spans),
      title: read.title || "Nothing to add yet",
      kind: Kati.Screens.QuickAdd.kind_line(read),
      facts: Kati.Screens.QuickAdd.facts(read),
      clash: Kati.Screens.QuickAdd.clash_for(read),
      kinds: Sample.kinds(),
      cta: Kati.Screens.QuickAdd.cta(read, today),
      read: read,
      # The commit button is a control only when there is something to commit.
      # A sentence with no day gets the button drawn and untappable, which is
      # `nil`'s own meaning in `Kati.ScreenSweep.tap_tags/1` — not tappable
      # rather than broken — and the button says what is missing.
      on_commit: if(Kati.QuickAdd.Parse.committable?(read), do: {self(), :commit})
    }
  end

  @doc """
  The typed sentence with the tokens Kati recognised marked in it — board 18's
  *parsed tokens are highlighted in place*, over the reader's own words.

  One line, because a `Row` does not wrap and the sentence is short; the board
  draws two because its own sentence is long enough to. The pieces are the
  same three the board uses, so the styling is unchanged and only the words
  are the reader's.
  """
  @spec echo(String.t(), [{non_neg_integer(), pos_integer()}]) :: [map()]
  def echo(typed, spans) do
    {pieces, at} =
      Enum.reduce(Enum.sort(spans), {[], 0}, fn {start, len}, {acc, at} ->
        before = binary_part(typed, at, start - at)
        token = binary_part(typed, start, len)

        {acc ++ [{:plain, String.trim(before), gap(before)}, {:token, token, gap(before)}],
         start + len}
      end)

    tail = binary_part(typed, at, byte_size(typed) - at)
    pieces = pieces ++ [{:plain, String.trim(tail), gap(tail)}]

    [%{caret: true, pieces: Enum.reject(pieces, fn {_kind, text, _gap} -> text == "" end)}]
  end

  defp gap(""), do: 0
  defp gap(_text), do: 4

  @doc """
  The mono line under the title: what Kati will make, in capitals, the way
  board 18 types it.
  """
  @spec kind_line(map()) :: String.t()
  def kind_line(%{date: nil}), do: "NEEDS A DAY"
  def kind_line(%{time: nil}), do: "ALL-DAY EVENT"
  def kind_line(_read), do: "PERSONAL EVENT"

  @doc """
  The chips: the day, the hours, the alert. Each one dropped when it is not
  known, rather than guessed — the rule this app keeps everywhere a meta line
  is composed.
  """
  @spec facts(map()) :: [[{String.t(), String.t()}]]
  def facts(read) do
    [
      read.date && {"calendar_today", Calendar.strftime(read.date, "%a %-d %b")},
      Kati.Screens.QuickAdd.hours(read),
      read.remind && {"notifications", Kati.Screens.QuickAdd.alert_line(read)}
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.chunk_every(2)
  end

  @doc false
  def hours(%{time: nil}), do: nil

  def hours(%{time: time, minutes: nil}),
    do: {"schedule", Calendar.strftime(time, "%H:%M")}

  def hours(%{time: time, minutes: minutes}) do
    ends = Time.add(time, minutes * 60)
    {"schedule", Calendar.strftime(time, "%H:%M") <> " – " <> Calendar.strftime(ends, "%H:%M")}
  end

  @doc false
  def alert_line(%{time: nil, remind: minutes}), do: "#{minutes}m before"

  def alert_line(%{time: time, remind: minutes}) do
    Calendar.strftime(Time.add(time, -minutes * 60), "%H:%M") <> " alert"
  end

  @doc """
  What the commit button says: the day it will land on.

  Board 18's own `Add to Thursday`, from the day the sentence names rather
  than from the drawing's. A sentence with no day cannot be added and the
  button says what is missing instead of naming a day nobody typed.
  """
  @spec cta(map(), Date.t()) :: String.t()
  def cta(%{date: nil}, _today), do: "Say when, and Kati will add it"

  def cta(%{date: date}, today) do
    cond do
      date == today -> "Add to today"
      date == Date.add(today, 1) -> "Add to tomorrow"
      true -> "Add to " <> Calendar.strftime(date, "%A")
    end
  end

  def render(assigns) do
    draft = assigns.draft
    sentence = Map.get(assigns, :sentence, "")
    save_error = Map.get(assigns, :save_error)

    ~MOB"""
    <Box
      fill_width={true}
      fill_height={true}
      background={:background}
      layout_direction={Kati.Locale.direction_prop()}
      accessibility_id={Kati.Screens.Identity.of(__MODULE__)}
    >
      <Scroll>
        <Column
          fill_width={true}
          padding_left={21}
          padding_right={21}
          padding_top={64}
          padding_bottom={40}
        >
          {Kati.Screens.QuickAdd.header()}
          {Kati.Screens.QuickAdd.input(sentence)}
          {Kati.Screens.QuickAdd.field(draft)}
          {Kati.Screens.QuickAdd.refusal(save_error)}
          {UI.eyebrow("Kati read that as")}
          {Kati.Screens.QuickAdd.parsed(draft)}
          {UI.eyebrow("Or file it as")}
          {Kati.Screens.QuickAdd.kinds(draft)}
          {Kati.Screens.QuickAdd.actions(draft)}
        </Column>
      </Scroll>
    </Box>
    """
  end

  @doc """
  The tag a kind chip sends, or `nil` for one with nowhere to go.

  `nil` rather than an inert tag, because a chip that sends a tag nothing
  answers is reported as a dead tap — and these five are not dead, they are
  undrawn. When each gets its own screen it gets its own tag here.
  """
  @spec kind_tap(String.t()) :: {pid(), atom()} | nil
  def kind_tap("Expense"), do: {self(), :file_as_expense}
  def kind_tap(_label), do: nil

  def handle_info({:change, :sentence, typed}, socket) when is_binary(typed) do
    {:noreply,
     socket
     |> Mob.Socket.assign(:sentence, typed)
     |> Mob.Socket.assign(:draft, Kati.Screens.QuickAdd.draft(typed))
     |> Mob.Socket.assign(:save_error, nil)}
  end

  def handle_info({:tap, :commit}, socket) do
    case Kati.Screens.QuickAdd.commit(socket.assigns.draft) do
      {:ok, _event} ->
        {:noreply, Kati.Screens.Resume.pop(socket)}

      {:error, reason} ->
        {:noreply, Mob.Socket.assign(socket, :save_error, Kati.Write.message({:error, reason}))}
    end
  end

  def handle_info({:tap, :close}, socket), do: {:noreply, Kati.Screens.Resume.pop(socket)}

  def handle_info({:tap, :file_as_expense}, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.QuickAddExpense)}

  @doc """
  Write the event the sentence describes.

  `Kati.Calendars.Event`'s own create, with the fields a typed sentence can
  fill and no others: a summary, a start, and an end when a duration was
  given. `origin: :local` because nobody synced this and `uid` is Kati's own,
  which is what the resource asks of anything it did not import.

  A sentence with no day is refused rather than filed on today —
  `Kati.QuickAdd.Parse.committable?/1` states that rule and this is the one
  place it is enforced. The drawing is refused for the same reason it refuses
  everything: there is no sentence behind it.
  """
  @spec commit(map()) :: {:ok, struct()} | {:error, term()}
  def commit(%{read: read}) do
    if Kati.QuickAdd.Parse.committable?(read) do
      zone = Kati.Time.device_zone()
      time = read.time || ~T[00:00:00]
      starts = DateTime.new!(read.date, time, zone) |> DateTime.shift_zone!("Etc/UTC")

      %{
        uid: "kati-quick-" <> Integer.to_string(System.unique_integer([:positive])),
        calendar_id: Kati.Screens.QuickAdd.personal_calendar().id,
        origin: :kati,
        summary: read.title,
        kind: :event,
        dtstart_utc: starts,
        dtstart_date: read.date,
        tzid: zone,
        is_all_day: read.time == nil,
        dtend_utc: read.minutes && DateTime.add(starts, read.minutes * 60, :second),
        duration_iso: read.minutes && "PT#{read.minutes}M"
      }
      |> then(&Ash.create(Kati.Calendars.Event, &1))
      |> Kati.Write.note("quick add")
    else
      Kati.Write.note({:error, :nothing_to_save}, "quick add")
    end
  end

  def commit(_drawn), do: Kati.Write.note({:error, :nothing_to_save}, "quick add")

  @doc """
  The calendar a quick-added event goes on: the reader's own local one.

  `Kati.Calendars.Event` requires a calendar, which is right — an event has to
  be somewhere, and *somewhere* is what the visibility switches on screen 32
  and the colours on screen 02 are about. Board 18's own parse card names it:
  `label · Personal`.

  Made if it is not there. A phone that has synced nothing has no calendar at
  all, and refusing the first quick add because of that would be refusing it
  for a reason the reader cannot act on — there is no *make a calendar* screen
  in this app. The first local calendar wins if one exists, so somebody who
  has synced keeps their own.
  """
  @spec personal_calendar() :: struct()
  def personal_calendar do
    Kati.Calendars.Calendar
    |> Ash.read!()
    |> Enum.filter(&(&1.kind == :local))
    |> List.first()
    |> case do
      nil -> Ash.create!(Kati.Calendars.Calendar, %{display_name: "Personal", kind: :local})
      calendar -> calendar
    end
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  @doc false
  def header do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Text
          text="Quick add"
          text_size={26}
          font_weight="bold"
          letter_spacing={-0.03}
          text_color={:on_surface}
        />
        <Spacer weight={1.0} />
        {Kati.Screens.QuickAdd.close_disc()}
      </Row>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  The 44pt disc that dismisses the sheet — `Kati.Components.MishkaCloseButton`.

  This screen has no back pill precisely because the drawing gives it this
  disc instead (see the moduledoc), so the one control that closes it is worth
  spelling the way the library spells closing. The close button is a thin
  preset over `Kati.Components.MishkaActionIcon` — ✕ and `shape: :circle` baked
  in — and children override the ✕, so the glyph stays the Material Symbol
  `close` at the drawn 21 rather than the component's own character.

  It could not be adopted before this round for one missing prop: `shadow`.
  The drawing's disc is `Kati.Theme.shadow_button()` floating over paper, and
  `variant: :filled` alone would have flattened it into a #FBFAF8 patch.

  **The pixels are the same node**: `<Box width={44} height={44}
  align={:center} corner_radius={22.0} background shadow on_tap>` is what this
  markup said by hand, `size / 2` being the 22 it wrote out. The port's `<Row>`
  around the children hugs the single glyph and is centred by the same Box, so
  nothing measures differently.
  """
  def close_disc do
    MishkaCloseButton.close_button(
      [
        size: 44,
        variant: :filled,
        background: Palette.card(),
        shadow: Kati.Theme.shadow_button(),
        on_tap: {self(), :close}
      ],
      [Kati.UI.symbol("close", size: 21)]
    )
  end

  # `0 0 0 2px #1A1917` is a ring, not a shadow. A shadow at zero blur and zero
  # offset draws nothing under the card's own elevation, so it is a 2px border
  # here and the drawing's second layer stays a shadow.
  @doc false
  @doc """
  The field itself, which this screen did not have.

  MOVIES-AND-TV.md #31 — the drawn sentence was `Kati.Screens.QuickAdd.
  Sample`'s styled pieces, so the page was a picture of somebody typing. A
  `TextField` cannot carry styled runs on this bridge, so the highlighting
  stays where it was — under the field, over the reader's own words, which is
  `field/1` below and is board 18's *highlighted in place* said in the one
  primitive there is.

  The placeholder is the board's own sentence. That is not a fallback: board
  18 is drawn MID-TYPING and its sentence is the clearest statement of the
  syntax this screen has, so somebody who opens the page and types nothing is
  looking at the example they need.
  """
  @spec input(String.t()) :: map()
  def input(sentence) do
    assigns = %{sentence: sentence, on_change: {self(), :sentence}}

    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        min_height={52}
        corner_radius={26}
        background={Palette.card()}
        border_width={2}
        border_color={Palette.ink()}
        shadow="0 10 22 -14 #991A1917"
        padding_left={18}
        padding_right={18}
        padding_top={6}
        padding_bottom={6}
        align="center"
      >
        <TextField
          value={@sentence}
          placeholder="dentist thu 11am for 45m, remind 1h before"
          return_key="done"
          weight={1.0}
          accessibility_id="quick_add_sentence"
          on_change={@on_change}
        />
      </Row>
      <Spacer size={12} />
    </Column>
    """
  end

  @doc false
  def refusal(nil), do: ~MOB"<Spacer size={0} />"

  def refusal(message) do
    assigns = %{message: message}

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.notice(@message)}
      <Spacer size={14} />
    </Column>
    """
  end

  def field(draft) do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={24}
        border_width={2}
        border_color={Palette.ink()}
        shadow="0 10 22 -14 #991A1917"
        padding_left={18}
        padding_right={18}
        padding_top={16}
        padding_bottom={16}
      >
        {Enum.map(draft.query, fn line -> Kati.Screens.QuickAdd.query_line(line) end)}
      </Column>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc false
  def query_line(line) do
    ~MOB"""
    <Row fill_width={true} align="center">
      {Enum.map(line.pieces, fn piece -> Kati.Screens.QuickAdd.piece(piece) end)}
      {Kati.Screens.QuickAdd.caret(line.caret)}
    </Row>
    """
  end

  @doc false
  def piece({:plain, text, gap}) do
    ~MOB"""
    <Row align="center">
      <Spacer size={gap} />
      <Text
        text={text}
        text_size={15.5}
        font_weight="medium"
        line_height={1.5}
        text_color={:on_surface}
        max_lines={1}
      />
    </Row>
    """
  end

  def piece({:token, text, gap}), do: token(text, gap, Palette.hairline_soft(), Palette.ink())

  def piece({:accent, text, gap}),
    do: token(text, gap, Palette.accent_wash(), Palette.gold_text())

  @doc false
  def token(text, gap, background, color) do
    ~MOB"""
    <Row align="center">
      <Spacer size={gap} />
      <Row
        background={background}
        corner_radius={5}
        padding_left={4}
        padding_right={4}
        padding_top={1}
        padding_bottom={1}
        align="center"
      >
        <Text
          text={text}
          text_size={15.5}
          font_weight="medium"
          line_height={1.5}
          text_color={color}
          max_lines={1}
        />
      </Row>
    </Row>
    """
  end

  @doc false
  def caret(false), do: ~MOB"<Spacer size={0} />"

  def caret(true) do
    ~MOB"""
    <Row align="center">
      <Spacer size={2} />
      <Box width={2} height={18} background={Palette.accent()} />
    </Row>
    """
  end

  @doc false
  def parsed(draft) do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.cream()}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={18}
      >
        <Row fill_width={true} align="center">
          {Kati.Screens.QuickAdd.kind_tile(Map.get(draft, :kind_icon, "event"))}
          <Spacer size={10} />
          <Column weight={1.0}>
            <Text
              text={draft.title}
              text_size={16}
              font_weight="bold"
              letter_spacing={-0.02}
              text_color={:on_surface}
              max_lines={1}
            />
            <Spacer size={3} />
            <Text
              text={draft.kind}
              font_family="mono"
              text_size={10.5}
              text_color={Palette.cream_meta()}
              max_lines={1}
            />
          </Column>
        </Row>
        <Spacer size={16} />
        {draft.facts
         |> Enum.map(fn row -> Kati.Screens.QuickAdd.fact_row(row) end)
         |> Enum.intersperse(Kati.Screens.QuickAdd.gap())}
        <Spacer size={14} />
        {Kati.Screens.QuickAdd.rule()}
        <Spacer size={14} />
        {Kati.Screens.QuickAdd.clash(draft)}
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  The ink tile that says what Kati filed the sentence as —
  `Kati.Components.MishkaThemeIcon`.

  "A themed container around exactly one glyph" is that component's own
  description of itself and it is exactly this: 34pt, radius 11, ink fill, one
  Material Symbol. It is not tappable and carries no shadow, so unlike the
  header disc it needed nothing new to be adopted — `size` and `radius` have
  always taken a raw dp number, and `variant: :filled` paints `color` as the
  fill.

  **The node is identical, prop for prop.** The port builds a bare
  `%{type: :box}` with `%{width: 34, height: 34, align: :center,
  corner_radius: 11, background: <ink>}` and the children it was handed — no
  wrapper Row, because only an `id` (for test tags) makes it wrap, and this
  has none. That is the same five props and the same single child the markup
  wrote out here.

  `icon_color` is not passed: the glyph is a child, and children are placed as
  given, so `Kati.UI.symbol/2` still supplies the drawn 18 in the drawn
  #FBFAF8. The component's own luminance guess never runs.
  """
  def kind_tile(icon \\ "event") do
    MishkaThemeIcon.theme_icon(
      %{size: 34, radius: 11, variant: :filled, color: Palette.ink_fill()},
      [UI.symbol(icon, size: 18, color: Palette.on_ink())]
    )
  end

  @doc "The drawing's 7pt flex gap, used between chips and between chip rows."
  def gap, do: ~MOB"<Spacer size={7} />"

  # The cream card's `1px solid rgba(176,154,114,.3)` divider, drawn by
  # `MishkaSeparator` — with `render: :box`, not the component's `:divider`
  # default.
  #
  # `:divider` is not the Box that was written inline here. The comment that
  # stood in this spot said Compose's `HorizontalDivider` is
  # `Box(fillMaxWidth().height(t).background(color))`; Material3 actually draws
  # it as `Canvas { drawLine(strokeWidth = t.toPx()) }`, an antialiased stroke.
  # At 2.6875x a 1dp rule gets a 3px canvas and a 2.6875px stroke, so its last
  # pixel row lands at ~69% coverage and the hairline came out softer than the
  # drawing's on one row. `render: :box` is the filled rect — the original node
  # — so the line is back to a solid 1dp of 30% bronze.
  @doc false
  def rule, do: MishkaSeparator.separator(color: Palette.cream_rule(), thickness: 1, render: :box)

  @doc false
  def fact_row(chips) do
    ~MOB"""
    <Row fill_width={true} align="center">
      {chips
       |> Enum.map(fn chip -> Kati.Screens.QuickAdd.fact(chip) end)
       |> Enum.intersperse(Kati.Screens.QuickAdd.gap())}
    </Row>
    """
  end

  @doc false
  # `0xA6FFFFFF` stays a literal: the only token carrying it is `lock_ink_65`,
  # which is a lock-screen line over a photograph and does not follow the theme.
  # The cream card's raised chip is `cream_raise`, and that is 0x99FFFFFF — a
  # different colour, so taking it would move light mode. Reported, not guessed.
  def fact({icon, label}) do
    ~MOB"""
    <Row
      height={30}
      corner_radius={15}
      background={0xA6FFFFFF}
      padding_left={11}
      padding_right={11}
      align="center"
    >
      {Kati.UI.symbol(icon, size: 14, color: Palette.gold_text())}
      <Spacer size={6} />
      <Text
        text={label}
        text_size={11.5}
        font_weight="semibold"
        text_color={Palette.ink_soft()}
        max_lines={1}
      />
    </Row>
    """
  end

  # Three Texts rather than one, because the drawing bolds the clashing event's
  # name inside the sentence and there is no inline span on this bridge.
  @doc false
  @doc """
  What this event would run into, or `nil`.

  Board 18 draws `Clashes with Design review — add anyway?` and the caption
  says why it is above the button rather than after it: *the clash warning
  appears before the save, not after.* It was `Kati.Screens.QuickAdd.Sample`'s
  one sentence; it is the reader's own calendar now.

  An overlap, not a same-day list: two things on Thursday are not a clash and
  saying so on every save would train somebody to ignore the line. An all-day
  event has no hours to overlap with and clashes with nothing.

  The first one only. A sentence that collides with three things has a
  scheduling problem this card cannot express, and naming one of the three is
  what makes somebody go and look.
  """
  @spec clash_for(map()) :: {String.t(), String.t(), String.t()} | nil
  def clash_for(%{date: %Date{} = date, time: %Time{} = time} = read) do
    minutes = read.minutes || 60
    from = DateTime.new!(date, time, Kati.Time.device_zone())
    to = DateTime.add(from, minutes * 60, :second)

    Kati.Calendars.Today.timed(date)
    |> Enum.find(&Kati.Screens.QuickAdd.overlaps?(&1, from, to))
    |> case do
      nil -> nil
      event -> {"Clashes with", event.summary || "another event", "— add anyway?"}
    end
  rescue
    _error -> nil
  end

  def clash_for(_read), do: nil

  @doc """
  Whether an event runs across the window this sentence asks for.

  An event with no end is given an hour, which is what a calendar entry with
  no duration means to everybody who has ever made one — and is the same hour
  `clash_for/1` gives a sentence that named no `for`.
  """
  @spec overlaps?(struct(), DateTime.t(), DateTime.t()) :: boolean()
  def overlaps?(event, from, to) do
    case event.dtstart_utc do
      %DateTime{} = starts ->
        ends = event.dtend_utc || DateTime.add(starts, 3600, :second)
        DateTime.compare(starts, to) == :lt and DateTime.compare(ends, from) == :gt

      _undated ->
        false
    end
  end

  def clash(%{clash: nil}), do: []

  def clash(draft) do
    {lead, subject, tail} = draft.clash

    ~MOB"""
    <Row fill_width={true} align="center">
      {Kati.UI.symbol("info", size: 15, color: Palette.cream_meta())}
      <Spacer size={7} />
      <Text text={lead} text_size={11.5} text_color={Palette.cream_sub()} max_lines={1} />
      <Spacer size={4} />
      <Text
        text={subject}
        text_size={11.5}
        font_weight="semibold"
        text_color={:on_surface}
        max_lines={1}
      />
      <Spacer size={4} />
      <Text text={tail} text_size={11.5} text_color={Palette.cream_sub()} max_lines={1} />
    </Row>
    """
  end

  @doc false
  def kinds(draft) do
    ~MOB"""
    <Column fill_width={true}>
      {draft.kinds
       |> Enum.chunk_every(3)
       |> Enum.map(fn row -> Kati.Screens.QuickAdd.kind_row(row) end)
       |> Enum.intersperse(Kati.Screens.QuickAdd.gap())}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def kind_row(row) do
    ~MOB"""
    <Row fill_width={true} align="center">
      {row
       |> Enum.map(fn kind -> Kati.Screens.QuickAdd.kind(kind) end)
       |> Enum.intersperse(Kati.Screens.QuickAdd.gap())}
    </Row>
    """
  end

  # The chips are the design's real claim — *one field for the whole app* — so
  # they have to change what the sentence became. Only `Expense` has a screen
  # drawn for it (124); the other five would each need their own parse of the
  # same sentence, and the design draws none of them.
  @doc false
  def kind({icon, label, true}) do
    ~MOB"""
    <Row
      height={34}
      corner_radius={17}
      background={Palette.ink_fill()}
      padding_left={13}
      padding_right={13}
      align="center"
      on_tap={Kati.Screens.QuickAdd.kind_tap(label)}
    >
      {Kati.UI.symbol(icon, size: 16, color: Palette.on_ink())}
      <Spacer size={7} />
      <Text
        text={label}
        text_size={12.5}
        font_weight="semibold"
        text_color={Palette.on_ink()}
        max_lines={1}
      />
    </Row>
    """
  end

  def kind({icon, label, false}) do
    ~MOB"""
    <Row
      height={34}
      corner_radius={17}
      background={Palette.card()}
      shadow={Kati.Theme.shadow_card_soft()}
      padding_left={13}
      padding_right={13}
      align="center"
      on_tap={Kati.Screens.QuickAdd.kind_tap(label)}
    >
      {Kati.UI.symbol(icon, size: 16, color: Palette.sub())}
      <Spacer size={7} />
      <Text
        text={label}
        text_size={12.5}
        font_weight="semibold"
        text_color={Palette.ink_soft()}
        max_lines={1}
      />
    </Row>
    """
  end

  # The commit button is a Box with `weight`, not a Row: it has to fill the
  # line beside the 52pt microphone, and a Row would hug the label.
  #
  # `on_commit` is optional and screen 18 does not supply one: its sentence is
  # a picture of a parse, and there is no parser behind it to commit. Screen
  # 124 does, because its sentence has already become an expense.
  @doc false
  def actions(draft) do
    tap = Map.get(draft, :on_commit)

    ~MOB"""
    <Row fill_width={true} align="center">
      <Box
        weight={1.0}
        height={52}
        corner_radius={26}
        background={Palette.ink_fill()}
        shadow="0 12 24 -12 #D91A1917"
        align="center"
        on_tap={tap}
      >
        <Text
          text={draft.cta}
          text_size={14}
          font_weight="bold"
          text_color={Palette.on_ink()}
          max_lines={1}
        />
      </Box>
      <Spacer size={10} />
      {Kati.Screens.QuickAdd.mic()}
    </Row>
    """
  end

  @doc """
  The 52pt microphone beside the commit button —
  `Kati.Components.MishkaActionIcon`.

  The same round icon target as `close_disc/0` and adopted for the same new
  prop: this one wears `Kati.Theme.shadow_card_soft()` rather than the button
  shadow, and without `shadow` the port could only have drawn it flat.

  It is wired to nothing, and that is the drawing's position rather than an
  omission — dictation is not built, and the export gives the microphone no
  destination. `on_tap` is simply not passed, so the port leaves the key off
  the node entirely; the disc renders exactly as the hand-rolled `Box` did,
  which also carried no handler.

  **The pixels are the same node**: `<Box width={52} height={52}
  align={:center} corner_radius={26.0} background shadow>` plus the port's
  `<Row>` around the glyph, which hugs it and is centred by that Box.
  """
  def mic do
    MishkaActionIcon.action_icon(
      [
        size: 52,
        shape: :circle,
        variant: :filled,
        background: Palette.card(),
        shadow: Kati.Theme.shadow_card_soft()
      ],
      [UI.symbol("mic", size: 21)]
    )
  end
end
