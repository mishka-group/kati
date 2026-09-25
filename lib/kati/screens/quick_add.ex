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
  use Gettext, backend: Kati.Gettext
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
    # Resolves the stored locale into THIS process. `Gettext.put_locale/2`
    # snapshots into the calling process exactly as `Mob.Theme.set/1` does,
    # and a screen is its own process — see `Kati.Locale.activate/0`.
    Kati.Locale.activate()

    sentence = Map.get(params || %{}, :sentence, "")

    {:ok,
     socket
     |> Mob.Socket.assign(:params, params)
     |> Mob.Socket.assign(:sentence, sentence)
     |> Mob.Socket.assign(:save_error, nil)
     # Which chip is lit, and therefore what the sentence becomes. Its own
     # assign rather than a key on the draft: `read_draft/1` rebuilds the draft
     # on every keystroke, so a choice held there would be un-made by the next
     # character typed.
     |> Mob.Socket.assign(:filed_as, :event)
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
      title: read.title || gettext("Nothing to add yet"),
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

  The capitals are in the MSGID rather than in an `String.upcase/1` around it,
  because there is no `text-transform` on that line in the drawing — the copy
  itself is typed in capitals, which is the same reading
  `Kati.Screens.QuickAdd.Sample`'s own moduledoc gives it. Persian has no case,
  so the translation carries none and nothing has to be undone at the leaf;
  `Kati.UI.eyebrow_label/1` exists for the other shape, where a sentence in
  ordinary case is upcased for display and the upcasing is a no-op in Persian
  that reads as one.
  """
  @spec kind_line(map()) :: String.t()
  def kind_line(%{date: nil}), do: gettext("NEEDS A DAY")
  def kind_line(%{time: nil}), do: gettext("ALL-DAY EVENT")
  def kind_line(_read), do: gettext("PERSONAL EVENT")

  @doc """
  The chips: the day, the hours, the alert. Each one dropped when it is not
  known, rather than guessed — the rule this app keeps everywhere a meta line
  is composed.
  """
  @spec facts(map()) :: [[{String.t(), String.t()}]]
  def facts(read) do
    [
      # `Kati.Locale.date/2`'s `:long` IS `%a %-d %b` in Latin, so the drawn
      # `Thu 20 Aug` is unchanged, and it is `پنج‌شنبه ۲۹ مرداد ۱۴۰۵` in
      # Persian — a different calendar rather than the same date translated.
      # The Persian form carries its year where the Latin one does not, which
      # is `date/2`'s own decision and is why there is no `:dated` on that
      # side: a reader knows this year in Gregorian by heart and does not in
      # Shamsi. It makes this chip the widest thing on the card in Persian, and
      # the chip's `max_lines={1}` is what that rests on.
      read.date && {"calendar_today", Kati.Locale.date(read.date, :long)},
      Kati.Screens.QuickAdd.hours(read),
      read.remind && {"notifications", Kati.Screens.QuickAdd.alert_line(read)}
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.chunk_every(2)
  end

  @doc false
  def hours(%{time: nil}), do: nil

  def hours(%{time: time, minutes: nil}),
    do: {"schedule", Kati.Locale.time(time)}

  def hours(%{time: time, minutes: minutes}) do
    ends = Time.add(time, minutes * 60)

    # The range is one msgid and not a join, so a script that puts the two
    # hours the other way round can say so. `Kati.Screens.Calendar` and
    # `Kati.Screens.EventDetail` already draw their hours through this exact
    # msgid — the catalogue keeps the en dash under `:fa` — so the three cannot
    # come out writing one range three ways.
    {"schedule",
     gettext("%{from} – %{to}", from: Kati.Locale.time(time), to: Kati.Locale.time(ends))}
  end

  @doc false
  # Both forms carry a placeholder, and both take a context: `mix gettext.merge`
  # fuzzy-matches a short msgid against any sentence resembling it, and
  # `%{n} days before` (screen 21's watcher) is already in the catalogue for
  # the first of these to be captured by.
  def alert_line(%{time: nil, remind: minutes}),
    do: pgettext("quick add alert chip", "%{n}m before", n: Kati.Locale.number(minutes))

  def alert_line(%{time: time, remind: minutes}) do
    pgettext("quick add alert chip", "%{at} alert",
      at: Kati.Locale.time(Time.add(time, -minutes * 60))
    )
  end

  @doc """
  What the commit button says: the day it will land on.

  Board 18's own `Add to Thursday`, from the day the sentence names rather
  than from the drawing's. A sentence with no day cannot be added and the
  button says what is missing instead of naming a day nobody typed.
  """
  @spec cta(map(), Date.t()) :: String.t()
  def cta(%{date: nil}, _today), do: gettext("Say when, and Kati will add it")

  def cta(%{date: date}, today) do
    cond do
      date == today -> gettext("Add to today")
      date == Date.add(today, 1) -> gettext("Add to tomorrow")
      # Three msgids rather than one with a hole and *today* poured into it:
      # Persian says به امروز and به پنج‌شنبه with no preposition change, but
      # the two near days are the ones a language is most likely to want a
      # different word for, and a hole would have decided for it.
      true -> gettext("Add to %{day}", day: Kati.Screens.QuickAdd.weekday(date))
    end
  end

  @doc false
  # A weekday NAMED, with no day of the month beside it — the one shape
  # `Kati.Locale` has no helper for: `weekday_initial/1` is a chart axis's
  # single letter and `date/2`'s `:full` carries the day and the month as well.
  # So the pick is here, over the same two tables those two read, exactly as
  # `Kati.Screens.Meal`'s own `weekday/1` does it.
  #
  # `Calendar.strftime(date, "%A")` was the English name in BOTH scripts, which
  # is what this replaces: `%A` has no locale to consult — Elixir's default
  # calendar names its days in English and nothing about `:fa` changes that —
  # so a Persian reader's commit button read `افزودن به Thursday`.
  @spec weekday(Date.t()) :: String.t()
  def weekday(%Date{} = date) do
    Kati.Locale.pick(
      Kati.Time.day_name(date),
      Kati.Calendar.Shamsi.weekday_name(Kati.Calendar.Shamsi.weekday_index(date))
    )
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
      font_family={Kati.Locale.face_prop()}
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
          {UI.eyebrow(gettext("Kati read that as"))}
          {Kati.Screens.QuickAdd.parsed(draft)}
          {UI.eyebrow(gettext("Or file it as"))}
          {Kati.Screens.QuickAdd.kinds(draft, Map.get(assigns, :filed_as, :event))}
          {Kati.Screens.QuickAdd.actions(draft)}
        </Column>
      </Scroll>
    </Box>
    """
  end

  @doc """
  The tag a kind chip sends. Six chips, six tags — MOVIES-AND-TV.md #93.

  Five of them used to answer `nil`, with the reason *these are not dead, they
  are undrawn: when each gets its own screen it gets its own tag*. Five of the
  six do not want a screen. `Kati.Calendars.Event.kind` already takes
  `:event`, `:reminder`, `:habit`, `:note` and `:money`, so four of the chips
  are one attribute on the row this screen already writes — the sentence is
  parsed the same way whichever is lit, and the chip says what the parsed thing
  IS.

  **Title** is the exception and the one the finding is named for: a film is
  not an event, so it cannot be a value of that column. It pushes screen 06
  with the parsed title as `query:`, so the add sheet opens already searching
  for what was typed — see the clause's own comment for why that is the push
  and not `Kati.Search.hand_over/1`, which screen 06 has never read.

  **Expense** keeps the push it had: screen 124 is drawn for it, and an amount
  is a parse this screen does not do.

      iex> {_pid, tag} = Kati.Screens.QuickAdd.kind_tap("Reminder")
      iex> tag
      :file_as_reminder

  The label it is handed is the ENGLISH one, always — see `kind_label/1`.
  """
  @spec kind_tap(String.t()) :: {pid(), atom()}
  def kind_tap(label), do: {self(), String.to_atom("file_as_" <> String.downcase(label))}

  @doc """
  What a kind chip is CALLED, from what it IS.

  On this screen a chip's label is its STATE as well as its copy: `kind_tap/1`
  builds `:file_as_event` out of it and `filing/1` matches on it, and
  `Kati.Screens.QuickAdd.Sample.kinds/0` is where the six words come from. So a
  chip translated at the source would send `:"file_as_رویداد"`, `filing/1`
  would fall through to `nil`, and a Persian reader tapping **Note** would
  light the chip and still file an event — the quiet failure, and one that also
  mints an atom per label per language.

  The six therefore stay English wherever they are identity and are translated
  here, once, at the one place they are read. `Kati.Screens.AddTitle.filter_label/1`
  is the same arrangement over its three filters, and the reason is the same.

  `pgettext/2` on all six rather than `gettext/1`. Each is one word, and
  `mix gettext.merge` fuzzy-matches a one-word msgid against any sentence that
  resembles it — `Event` has `Edit event` and `Delete event` waiting for it in
  the catalogue. The context also leaves **Title** free to mean *a film or a
  book* here, which is what tapping it does (it opens screen 06), while the
  bare `Title` msgid goes on meaning the field label on screen 156.

      iex> Kati.Screens.QuickAdd.kind_label("Habit")
      "Habit"

  An unrecognised label is drawn as it came, rather than raising: this row is
  lent whole to screen 124, and a seventh chip added there should appear
  untranslated instead of taking the screen down.
  """
  @spec kind_label(String.t()) :: String.t()
  def kind_label("Event"), do: pgettext("quick add chip", "Event")
  def kind_label("Reminder"), do: pgettext("quick add chip", "Reminder")
  def kind_label("Title"), do: pgettext("quick add chip", "Title")
  def kind_label("Habit"), do: pgettext("quick add chip", "Habit")
  def kind_label("Note"), do: pgettext("quick add chip", "Note")
  def kind_label("Expense"), do: pgettext("quick add chip", "Expense")
  def kind_label(other) when is_binary(other), do: other

  @doc """
  The `Kati.Calendars.Event.kind` a chip files the sentence as, or `nil`.

  `nil` for the two chips that do not write an event here: **Title** goes to
  screen 06 and **Expense** to screen 124.

      iex> Kati.Screens.QuickAdd.filing("Note")
      :note

      iex> Kati.Screens.QuickAdd.filing("Title")
      nil
  """
  @spec filing(String.t()) :: atom() | nil
  def filing("Event"), do: :event
  def filing("Reminder"), do: :reminder
  def filing("Habit"), do: :habit
  def filing("Note"), do: :note
  def filing(_elsewhere), do: nil

  def handle_info({:change, :sentence, typed}, socket) when is_binary(typed) do
    {:noreply,
     socket
     |> Mob.Socket.assign(:sentence, typed)
     |> Mob.Socket.assign(:draft, Kati.Screens.QuickAdd.draft(typed))
     |> Mob.Socket.assign(:save_error, nil)}
  end

  def handle_info({:tap, :commit}, socket) do
    case Kati.Screens.QuickAdd.commit(socket.assigns.draft, socket.assigns.filed_as) do
      {:ok, _event} ->
        {:noreply, Kati.Screens.Resume.pop(socket)}

      {:error, reason} ->
        {:noreply, Mob.Socket.assign(socket, :save_error, Kati.Write.message({:error, reason}))}
    end
  end

  def handle_info({:tap, :close}, socket), do: {:noreply, Kati.Screens.Resume.pop(socket)}

  def handle_info({:tap, :file_as_expense}, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.QuickAddExpense)}

  # A film is not an event, so this chip is a door rather than a setting. The
  # handover is what screen 19's *Look it up* makes, so the add sheet opens
  # already searching for what was typed rather than asking for it again.
  def handle_info({:tap, :file_as_title}, socket) do
    # In the PUSH, not through `Kati.Search.hand_over/1`. That key is screen
    # 19's, and screen 06 has never read it — handing over there would have
    # opened this sheet blank while quietly changing what the Library's search
    # disc opens next.
    {:noreply,
     Mob.Socket.push_screen(socket, Kati.Screens.AddTitle, %{
       query: Kati.Screens.QuickAdd.typed_title(socket)
     })}
  end

  def handle_info({:tap, tag}, socket) when is_atom(tag) do
    case Atom.to_string(tag) do
      "file_as_" <> label ->
        {:noreply, Kati.Screens.QuickAdd.file_as(socket, label)}

      _other ->
        {:noreply, socket}
    end
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  @doc """
  The words the Title chip hands over: the parsed title, or the whole sentence.

  The parse strips the day, the hour, the duration and the reminder, which is
  exactly what should not go into a title search — but a sentence it could
  make nothing of leaves `title` nil, and the raw sentence is a better search
  term than an empty one.
  """
  @spec typed_title(Mob.Socket.t()) :: String.t()
  def typed_title(socket) do
    case get_in(socket.assigns, [:draft, :read]) do
      %{title: title} when is_binary(title) and title != "" -> title
      _unparsed -> socket.assigns.sentence
    end
  end

  @doc false
  @spec file_as(Mob.Socket.t(), String.t()) :: Mob.Socket.t()
  def file_as(socket, label) do
    case Kati.Screens.QuickAdd.filing(String.capitalize(label)) do
      nil -> socket
      kind -> Mob.Socket.assign(socket, :filed_as, kind)
    end
  end

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
  def commit(draft, filed_as \\ :event)

  def commit(%{read: read}, filed_as) do
    if Kati.QuickAdd.Parse.committable?(read) do
      zone = Kati.Time.device_zone()
      time = read.time || ~T[00:00:00]
      starts = DateTime.new!(read.date, time, zone) |> DateTime.shift_zone!("Etc/UTC")

      %{
        uid: "kati-quick-" <> Integer.to_string(System.unique_integer([:positive])),
        calendar_id: Kati.Screens.QuickAdd.personal_calendar().id,
        origin: :kati,
        summary: read.title,
        # What the lit chip says this is. Four of the six chips are this one
        # attribute — see `filing/1` — so the sentence is parsed once and filed
        # under whichever the reader picked.
        kind: filed_as,
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

  def commit(_drawn, _filed_as), do: Kati.Write.note({:error, :nothing_to_save}, "quick add")

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

  **`display_name` is written in English and is not a `gettext/1` call**, even
  under `:fa`. It is a row in the database, not a string on a screen: a name
  translated at the write would freeze whichever language the reader happened
  to be in when they first quick-added, and would then disagree with itself the
  day they switched. `Kati.Screens.Calendars.copy/1` already maps this exact
  word — `copy("Personal"), do: gettext("Personal")` — so the calendar is named
  in Persian where it is READ, which is the half that follows the setting.
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

  @doc false
  # `Kati.Locale.tracking/1` rather than the flat `-0.03`: tightening by a
  # fraction of an em breaks the joins between Persian letters, which is a
  # different defect from looking wrong — افزودن سریع comes apart into
  # letterforms. `max_lines={1}` because the Persian title is the longer of the
  # two and this Row has a 44pt disc on the end of it that must not be pushed
  # off; the heading had none because `Quick add` has never needed one.
  def header do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Text
          text={gettext("Quick add")}
          text_size={26}
          font_weight="bold"
          letter_spacing={Kati.Locale.tracking(-0.03)}
          text_color={:on_surface}
          max_lines={1}
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
  # The field itself, which this screen did not have.
  #
  # MOVIES-AND-TV.md #31 — the drawn sentence was `Kati.Screens.QuickAdd.
  # Sample`'s styled pieces, so the page was a picture of somebody typing. A
  # `TextField` cannot carry styled runs on this bridge, so the highlighting
  # stays where it was — under the field, over the reader's own words, which is
  # `field/1` below and is board 18's *highlighted in place* said in the one
  # primitive there is.
  #
  # The placeholder is the board's own sentence. That is not a fallback: board
  # 18 is drawn MID-TYPING and its sentence is the clearest statement of the
  # syntax this screen has, so somebody who opens the page and types nothing is
  # looking at the example they need.
  #
  # **And it stays in Latin under `:fa`, isolated rather than translated.**
  # This placeholder is not a sentence about the screen, it is an EXECUTABLE
  # example of the one syntax the screen has, and `Kati.QuickAdd.Parse` reads
  # English tokens only — `thu`, `11am`, `for 45m`, `remind 1h before` are the
  # four regexes in that module and it has no Persian table for any of them. A
  # translated placeholder would teach a Persian reader a syntax this app
  # answers with nothing, which is worse than a foreign example that works.
  # `Kati.Locale.ltr/1` is what stops it reading as broken meanwhile: the comma
  # is a bidi neutral and resolves to the paragraph's direction, so an RTL
  # field would lay it out at the left edge — the failure `Kati.Locale.ltr/1`'s
  # own doc names on screen 83's licence notices. The day the parser learns
  # Persian, this becomes a `gettext/1` and the two land together.
  @spec input(String.t()) :: map()
  def input(sentence) do
    assigns = %{
      sentence: sentence,
      example: Kati.Locale.ltr("dentist thu 11am for 45m, remind 1h before"),
      on_change: {self(), :sentence}
    }

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
          placeholder={@example}
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
  # The kind line asks the STRING which face it wants rather than the reader —
  # `Kati.Locale.mono_face/1` and not `mono_face/0` — because this one slot
  # holds both kinds of thing. `kind_line/1` puts translated copy in it, which
  # under `:fa` is Persian and has no glyph in `kati_mono.ttf`; screen 124 puts
  # `EXPENSE · BOOKS` in it through `Kati.Screens.QuickAdd.Sample`, which is
  # pure ASCII and belongs in DM Mono in either script. Deciding by script is
  # what lets one Text serve both, and is the rule screen 80's provider list
  # states.
  #
  # The title's tracking follows `Kati.Locale.tracking/1` for the same reason
  # the header's does: the title is the reader's own typed words, so it is
  # Persian whenever they are, and -0.02em pulls the joins apart.
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
              letter_spacing={Kati.Locale.tracking(-0.02)}
              text_color={:on_surface}
              max_lines={1}
            />
            <Spacer size={3} />
            <Text
              text={draft.kind}
              font_family={Kati.Locale.mono_face(draft.kind)}
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
  # What this event would run into, or `nil`.
  #
  # Board 18 draws `Clashes with Design review — add anyway?` and the caption
  # says why it is above the button rather than after it: *the clash warning
  # appears before the save, not after.* It was `Kati.Screens.QuickAdd.Sample`'s
  # one sentence; it is the reader's own calendar now.
  #
  # An overlap, not a same-day list: two things on Thursday are not a clash and
  # saying so on every save would train somebody to ignore the line. An all-day
  # event has no hours to overlap with and clashes with nothing.
  #
  # The first one only. A sentence that collides with three things has a
  # scheduling problem this card cannot express, and naming one of the three is
  # what makes somebody go and look.
  @spec clash_for(map()) :: {String.t(), String.t(), String.t()} | nil
  def clash_for(%{date: %Date{} = date, time: %Time{} = time} = read) do
    minutes = read.minutes || 60
    from = DateTime.new!(date, time, Kati.Time.device_zone())
    to = DateTime.add(from, minutes * 60, :second)

    Kati.Calendars.Today.timed(date)
    |> Enum.find(&Kati.Screens.QuickAdd.overlaps?(&1, from, to))
    |> case do
      nil ->
        nil

      event ->
        # The sentence is already broken in three for the bolding, so each
        # piece is translated where it stands. `pgettext/2` on all of them
        # because each is two or three words, and `mix gettext.merge`
        # fuzzy-matches a short msgid against any sentence resembling it —
        # `— add anyway?` would have been captured by `No goals set — Kati
        # counts anyway`, a different screen saying a different thing.
        #
        # The middle piece is the event's OWN summary and is never translated:
        # it is what the reader wrote on their own calendar. Under `:fa` the
        # three sit in a Row the root has already mirrored, so the lead lands
        # on the right and the question mark at the far left, which is where a
        # Persian sentence ends.
        {pgettext("quick add clash", "Clashes with"),
         event.summary || pgettext("quick add clash", "another event"),
         pgettext("quick add clash", "— add anyway?")}
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
  def kinds(draft, filed_as \\ nil)

  # Screen 124 draws this same row and answers none of its tags — it has its
  # own chip lit and its own screen behind it — so it gets the picture, which
  # is the rule `Kati.Screens.Rating.scale_toggle/1` states for the toggle it
  # lends the same way.
  def kinds(draft, nil) do
    ~MOB"""
    <Column fill_width={true}>
      {draft.kinds
       |> Enum.chunk_every(3)
       |> Enum.map(fn row -> Kati.Screens.QuickAdd.kind_row(row, false) end)
       |> Enum.intersperse(Kati.Screens.QuickAdd.gap())}
      <Spacer size={22} />
    </Column>
    """
  end

  def kinds(draft, filed_as) do
    ~MOB"""
    <Column fill_width={true}>
      {draft.kinds
       |> Enum.map(fn {icon, label, _drawn} ->
         {icon, label, Kati.Screens.QuickAdd.filing(label) == filed_as}
       end)
       |> Enum.chunk_every(3)
       |> Enum.map(fn row -> Kati.Screens.QuickAdd.kind_row(row, true) end)
       |> Enum.intersperse(Kati.Screens.QuickAdd.gap())}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def kind_row(row, live?) do
    ~MOB"""
    <Row fill_width={true} align="center">
      {row
       |> Enum.map(fn kind -> Kati.Screens.QuickAdd.kind(kind, live?) end)
       |> Enum.intersperse(Kati.Screens.QuickAdd.gap())}
    </Row>
    """
  end

  # The chips are the design's real claim — *one field for the whole app* — and
  # they change what the sentence became: four of the six are one value of
  # `Kati.Calendars.Event.kind`, Title is a door onto screen 06 and Expense one
  # onto 124. See `kind_tap/1` and `filing/1`.
  #
  # `label` is the English word throughout — it is what `kind_tap/1` turns into
  # a tag and what `filing/1` matches — and `kind_label/1` is what the reader
  # is shown. The two must not be the same string, which is the whole of that
  # function's doc.
  @doc false
  def kind(chip, live? \\ true)

  def kind({icon, label, true}, live?) do
    ~MOB"""
    <Row
      height={34}
      corner_radius={17}
      background={Palette.ink_fill()}
      padding_left={13}
      padding_right={13}
      align="center"
      on_tap={if(live?, do: Kati.Screens.QuickAdd.kind_tap(label))}
    >
      {Kati.UI.symbol(icon, size: 16, color: Palette.on_ink())}
      <Spacer size={7} />
      <Text
        text={Kati.Screens.QuickAdd.kind_label(label)}
        text_size={12.5}
        font_weight="semibold"
        text_color={Palette.on_ink()}
        max_lines={1}
      />
    </Row>
    """
  end

  def kind({icon, label, false}, live?) do
    ~MOB"""
    <Row
      height={34}
      corner_radius={17}
      background={Palette.card()}
      shadow={Kati.Theme.shadow_card_soft()}
      padding_left={13}
      padding_right={13}
      align="center"
      on_tap={if(live?, do: Kati.Screens.QuickAdd.kind_tap(label))}
    >
      {Kati.UI.symbol(icon, size: 16, color: Palette.sub())}
      <Spacer size={7} />
      <Text
        text={Kati.Screens.QuickAdd.kind_label(label)}
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
