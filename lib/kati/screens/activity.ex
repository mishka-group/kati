defmodule Kati.Screens.Activity do
  @moduledoc """
  Screen 15 — Activity, pushed under Stats.

  Built to `test/design/screens/15.html`. An append-only history — every
  tick, rating, drop and import — grouped by when it happened, with the
  per-episode rewatch counts underneath. The drawing's own note calls it the
  undo trail: *nothing in the app deletes silently*, so nothing here is a
  summary, every line is an event.

  Three things the drawing is specific about and this file follows literally:

    * **Two stamps, one gutter.** Today's rows carry a `21:12` clock at mono
      11; Earlier this month's carry `12 AUG` at mono 10 with `.06em`. Both
      sit in a 44pt column, which is what screen 19's calendar rows already
      give the same stamp. Sizing each card's gutter to its own stamp is the
      tempting move and the wrong one — the export's own 38 both truncated the
      date to `12 A…` and stepped the two cards' thumbnails out of line with
      each other. The 6 the column borrowed is given back out of the gap after
      it, so `stamp column + gap` is the drawing's 50 either way and everything
      right of the stamp sits where the export puts it — see `entry_row/5`.
      Under `:fa` the same 44 holds `۲۱:۱۲` and `۲۱ مرداد` — a Shamsi date, not
      a translated Gregorian one — set in Vazirmatn rather than DM Mono, which
      carries neither a Persian letter nor a Persian digit. The column does not
      change: `date_stamp/1` takes Shamsi's `:short`, whose numerals are already
      even-width and need none of the zero-padding `12 AUG` does.
    * **The second eyebrow is grey.** "Earlier this month" gets a `#C4BDB3`
      dash, not the accent — see `Kati.UI.Eyebrow`. Last month is neither new
      nor now.
    * **The verb is a separate run.** `Watched`, `Rated`, `Dropped` are bold
      ink inside a `#5C574F` line, and one `Text` carries one weight. The 2
      between the runs is the word space that split them, not a gap between
      two things — at 4 the line read as two phrases.

  The rating row is written `Blue Hour ★★★★` in the export. U+2605 is not in
  Plus Jakarta Sans — screen 08 discovered that by rendering an empty rating
  card — so the stars are Material Symbols `star` glyphs at the line's own
  size and colour. The checker therefore reports that one line as missing; it
  is a glyph, not a word.

  ## The chips filter the log, and a filter can empty a day

  `All` is the resting state and shows every row, which is what `15.html`
  draws. The other three name a verb, and the verb is what the row stores in
  `lead`, so the chip filters on that and nothing else.

  Both halves of that match are **English in every locale**. `lead` and the
  chip's value are keys, `filter_label/1` and `verb_label/1` are the only
  places the reader's language gets in, and they get in on the way to a `Text`.
  A screen that translated the value instead is `Kati.Screens.AddTitle`'s own
  story: its Persian mirror stored «همه», every clause of `visible/2` fell
  through to the catch-all, and four chips drew perfectly while tapping any of
  them showed everything.

  A filter that leaves a dated group with no rows takes the group's **eyebrow
  with it** — `Rated` and `Added` have nothing in Earlier this month, and a
  headed card with no rows inside it is a worse answer than no card. The
  rewatch count is not part of the log and is never filtered.

  No dock on a pushed screen, so the frame ends at 40 rather than 132.

  ## The log is `Kati.Media.Watch`, and only `Kati.Media.Watch`

  That resource's own moduledoc names this screen — it is why `media_watches`
  carries a bare `watched_at` index, *"screen 15's activity log across every
  title"* — so the rows here are read through the domain rather than off
  `Kati.Activity.Sample`. One `Ash.read!` of the user's watches, joined to the
  title they belong to and to whatever the cache still holds about it, shaped
  into the same `%{stamp, seed, lead, rest, stars}` the sample produced. The
  shaping is in this file rather than a read model beside the resource because
  every judgement in it — which verb a row gets, where the stamp changes from a
  clock to a date — is a statement about *this drawing* and belongs next to the
  markup that draws it.

  **An empty database still draws the drawing.** `log/0` falls back to
  `drawn/0` — the sample verbatim — the way `Kati.Screens.Home.rest_of_today/1`
  and `Kati.Screens.Calendar.day_rows/1` already do, because this screen is
  also the reference the frame is compared against and a fresh install has no
  watches. The gate is the whole screen, not each group: a log with rows today
  and none earlier shows its real emptiness rather than borrowing four drawn
  rows from last month.

  ### What `Kati.Media.Watch` cannot say yet

  The drawing's log is *"every tick, rating, drop and import"* and `Watch` is
  the ticks and the ratings. `Added … to Wishlist`, `Finished … Season 1`,
  `Dropped … after S1E3` and `Imported 412 titles from a CSV backup` are the
  other four rows the sample carries, and none of them has a store: a status
  moving from `:watching` to `:dropped` overwrites a column on
  `Kati.Media.TrackedTitle` and leaves nothing behind, there is no list
  resource for a wishlist to be added to, and no import ever records that it
  ran. So the `Added` chip finds nothing in a real log. That is a missing
  resource, not a missing query: a `media_events` append-only table, or a
  status-change row beside `Kati.Media.TrackedTitle`, is what those four verbs
  need, and inventing a column from a screen would be the wrong end to build it
  from. Until it exists the drawn rows carry them, which is why
  `Kati.Activity.Sample` stays.
  """
  use Kati.Screens.Pushed, back: "Stats"
  use Gettext, backend: Kati.Gettext

  require Ash.Query

  alias Kati.Activity.Sample
  alias Kati.Components.MishkaActionIcon
  alias Kati.Components.MishkaChip
  alias Kati.Components.MishkaSeparator
  alias Kati.Media.CachedTitle
  alias Kati.Media.Watch
  alias Kati.Theme.Palette
  alias Kati.UI

  @impl true
  def load(socket), do: Mob.Socket.assign(socket, filter: "All", log: log())

  @doc false
  def content(assigns) do
    filter = assigns.filter
    log = assigns.log
    today = visible(log.today, filter)
    earlier = visible(log.earlier, filter)

    # The two eyebrows are built here rather than written into the sigil.
    # `gettext/1` around the label pushes the interpolation well past the line
    # the group call already fills, and the sigil's formatter rewraps markup
    # rather than the Elixir inside a `{...}` — so the readable place for the
    # call is above the sigil, where the two section names sit side by side.
    today_eyebrow = UI.eyebrow(gettext("Today"))
    earlier_eyebrow = Kati.UI.Eyebrow.quiet(gettext("Earlier this month"))

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {Kati.Screens.Activity.back_gap()}
        {Kati.Screens.Activity.header(log.entries_line)}
        {Kati.Screens.Activity.filters(filter)}
        {Kati.Screens.Activity.group(today, today_eyebrow, 44, 11, 0.0)}
        {Kati.Screens.Activity.group(earlier, earlier_eyebrow, 44, 10, 0.06)}
        {Kati.Screens.Activity.nothing_here(log, today, earlier, filter)}
        {Kati.Screens.Activity.rewatch_section(log.rewatch)}
      </Column>
    </Scroll>
    """
  end

  @doc """
  The log this screen draws — the user's own, or the drawing's.

  Real rows whenever there are any, and `drawn/0` when there are none, which
  is the rule `Kati.Screens.Calendar.day_rows/1` states: *missing data is not
  a reason for a blank screen*. The two dated groups are what the gate reads,
  not the rewatch card — a user whose every watch is older than this month has
  an empty log and a real rewatch tally, and showing the drawing's four rows
  beside their own counts would be two different months in one frame.

  A database that cannot be read at all draws the drawing too. `Ash.read!` on
  a device mid-migration raises, and a screen that dies is strictly worse than
  a screen showing the values it was drawn from; the tests below fail loudly
  on a query that is merely wrong, because they assert the real strings.
  """
  @spec log() :: map()
  def log do
    case entries() do
      # NOTHING RECORDED, and not *nothing this month*. The gate was
      # `%{today: [], earlier: []}`, which is the state of every reader whose
      # watches are all older than the first of the month — so somebody with a
      # real history was shown `1,204 entries` over seven invented rows, and
      # the rewatch card underneath, which counts their WHOLE history, was
      # replaced by the drawing's too. MOVIES-AND-TV.md #58.
      %{count: 0} -> drawn()
      log -> log
    end
  rescue
    _ -> drawn()
  end

  @doc """
  The drawing's own log — `test/design/screens/15.html`, verbatim.

  `Kati.Activity.Sample` is kept rather than inlined here: it is the frame's
  specification and the fixture the tests compare a real render against, and
  two copies of the drawing's copy is exactly how the two drift apart.
  """
  @spec drawn() :: map()
  def drawn do
    %{
      count: 0,
      # The drawing's FIGURE — board 15 was captured at 1,204 — through this
      # screen's own sentence, rather than `Kati.Activity.Sample.entries_line/0`,
      # which is the whole line `1,204 entries` frozen as a string. Byte for
      # byte the same answer in English, and the reason it cannot stay a string
      # is the other script: a frozen Latin line drew `1,204 entries` under
      # **فعالیت**, in Latin numerals, on every Persian device with nothing
      # recorded — which is a fresh install, so it is the first thing a Persian
      # reader ever sees of this page. `entries_line/1` is where the wording and
      # the digits already live, and its own doc says one wording, one place.
      entries_line: entries_line(1204),
      today: Sample.today(),
      earlier: Sample.earlier(),
      rewatch: Sample.rewatch()
    }
  end

  @doc """
  Every watch the user has recorded, shaped into the drawing's rows.

  One read of `Kati.Media.Watch` rather than one per group. The screen needs
  the whole history anyway — the header counts it and the rewatch card groups
  it — and three filtered queries that must agree about what "this month"
  means is three chances to disagree.

  Stamps are the precision the row actually has. `watched_at` is an instant, so
  it yields the local clock Today's gutter draws; `watched_on` is a date, and
  `Kati.Media.Watch` is explicit that the two are separate because *"watched on
  12 August" is date-valued*. A date-only watch therefore cannot appear in
  Today, whose gutter is a clock — it is the row that says "I have seen this, I
  do not remember when", and giving it a manufactured 00:00 would be the same
  lie as `Kati.Media.Release` refusing to turn a bare year into 1 January.

  `today` is an argument for the same reason `Kati.Calendars.Today.rows/1`
  takes one: the two groups are *"today"* and *"earlier this month"*, and a
  function that reads the clock itself can only be tested on the day the
  fixtures were written for — or, worse, only on the days of the month where
  "earlier this month" is a non-empty range at all.
  """
  @spec entries(Date.t()) :: map()
  def entries(today \\ Kati.Time.today()) do
    zone = Kati.Time.device_zone()
    # The first of the READER's month, which is not the first of the Gregorian
    # one under `:fa` — see `month_start/1`.
    month = month_start(today)

    watches = watches()
    events = events()
    cached = cached_by_reference(watches ++ events)

    # MOVIES-AND-TV.md #112. `Added` and `Dropped` are two of the four chips
    # this screen offers and neither could ever match, because `Kati.Media.Watch`
    # is the only thing it read and a watch is never either. `Kati.Media.Event`
    # is the store screen 15's own moduledoc named as missing; both kinds of row
    # go into one stream here, because the log is one list sorted by time and
    # the reader does not think of them as two tables.
    dated =
      (Enum.map(watches, &stamped(&1, zone)) ++ Enum.map(events, &stamped(&1, zone)))
      |> Enum.reject(fn {date, _clock, _entry} -> is_nil(date) end)
      |> Enum.sort_by(fn {date, clock, entry} ->
        {Date.to_erl(date), clock || "", entry.id}
      end)
      |> Enum.reverse()

    %{
      # What `log/0` gates on. `today` and `earlier` are both month-scoped and
      # neither can answer *has this reader recorded anything at all*.
      count: length(watches) + length(events),
      entries_line: entries_line(length(watches) + length(events)),
      today:
        for {date, clock, entry} <- dated, date == today, not is_nil(clock) do
          row(entry, clock_stamp(clock), cached)
        end,
      earlier:
        for {date, _clock, entry} <- dated,
            Date.compare(date, month) != :lt,
            Date.compare(date, today) == :lt do
          row(entry, date_stamp(date), cached)
        end,
      # Watches only. The card counts *how many times have I seen this*, and an
      # add is not a viewing.
      rewatch: rewatch_counts(watches, cached)
    }
  end

  @doc """
  The rows a chip leaves visible.

  The chip names a verb and the row keeps its verb in `lead`, so the match is
  on `lead` alone. It is a *contains*, not an equality, and that is the one
  judgement here: `Watched` keeps `Rewatched` too, because a rewatch is a
  watch — the rewatch count at the bottom of this screen already counts it as
  one.

  The match is on the ENGLISH word in both halves and stays there. `filter` is
  what the socket holds and what `filter_<label>` names, `lead` is what `verb/2`
  and `event_word/1` write, and neither is ever the reader's own language —
  `filter_label/1` and `verb_label/1` are the only places that translate, and
  they translate for drawing. `Kati.Screens.AddTitle.filters/0` carries the long
  version of the argument: its Persian mirror stored «همه», every clause of its
  `visible/2` fell through to the catch-all, and four chips drew perfectly while
  tapping any of them showed everything.
  """
  @spec visible([map()], String.t()) :: [map()]
  def visible(rows, "All"), do: rows

  def visible(rows, filter) do
    verb = String.downcase(filter)
    Enum.filter(rows, fn row -> String.contains?(String.downcase(row.lead), verb) end)
  end

  @doc """
  The word a filter chip shows for the value it carries.

  A literal per clause, because a msgid has to be a literal at the call site —
  `gettext(value)` does not compile — and `pgettext/2` on every one, because a
  chip is a surface: `All` alone is three characters and `mix gettext.merge`
  will fuzzy-match a bare one-word msgid onto any sentence that opens with it.

  The chips and the rows name the same four verbs and do **not** share their
  Persian, which is the one judgement here. A chip is a CATEGORY — it answers
  *which of these*, so Persian wants the adjective: دیده‌شده, امتیازدار. A row
  is an EVENT — it answers *what happened*, so Persian wants the verb: دیده شد,
  امتیاز داده شد. English writes both with the same word and Persian cannot,
  which is exactly the case `pgettext/2` exists for. The adjectives are also the
  shorter of the two, and this row of four is measured: the comment above
  `filters/1` has it at ~285 inside the 360 the gutters leave, and the verb
  forms would have spent most of the 75 that are left.
  """
  @spec filter_label(String.t()) :: String.t()
  def filter_label("All"), do: pgettext("activity filter chip", "All")
  def filter_label("Watched"), do: pgettext("activity filter chip", "Watched")
  def filter_label("Rated"), do: pgettext("activity filter chip", "Rated")
  def filter_label("Added"), do: pgettext("activity filter chip", "Added")
  def filter_label(other), do: other

  @doc """
  The bold run at the head of a log row, in the reader's language.

  `lead` is a KEY — `visible/2` filters on it and the chips are spelled in the
  same words — so it is translated here, on the way to the `Text`, and never in
  `verb/2` or `event_word/1`. That also gets the drawn rows for free:
  `Kati.Activity.Sample`'s seven carry the same English words this file writes,
  so board 15's own fallback reads Persian without a second copy of the sample.

  `pgettext/2` throughout, for `filter_label/1`'s reason and one more: three of
  these are one Persian word in the catalogue already — `Dropped`, `Abandoned`
  and `Did not finish` are all رهاشده as a shelf STATUS — and a log has to keep
  them apart, because a row saying رهاشده three ways is a row that cannot be
  read back. As events they are رها شد, کنار گذاشته شد and ناتمام ماند.
  """
  @spec verb_label(String.t()) :: String.t()
  def verb_label("Watched"), do: pgettext("activity log verb", "Watched")
  def verb_label("Rewatched"), do: pgettext("activity log verb", "Rewatched")
  def verb_label("Rated"), do: pgettext("activity log verb", "Rated")
  def verb_label("Added"), do: pgettext("activity log verb", "Added")
  def verb_label("Dropped"), do: pgettext("activity log verb", "Dropped")
  def verb_label("Abandoned"), do: pgettext("activity log verb", "Abandoned")
  def verb_label("Did not finish"), do: pgettext("activity log verb", "Did not finish")
  def verb_label("Resumed"), do: pgettext("activity log verb", "Resumed")
  def verb_label("Finished"), do: pgettext("activity log verb", "Finished")
  def verb_label("Imported"), do: pgettext("activity log verb", "Imported")
  # `event_word/1`'s own catch-all capitalises an atom nobody has named yet.
  # It draws in English, which is the right failure: a verb this screen has not
  # been told about is a verb nobody has translated either.
  def verb_label(other), do: other

  @doc """
  One dated group — its eyebrow and its card — or nothing at all.

  Returning a list rather than a wrapper `Column` is deliberate: the sigil
  flattens an interpolated list into its parent, so an empty group leaves no
  node behind and the groups that remain keep the exact spacing they had.
  """
  @spec group([map()], map(), pos_integer(), number(), number()) :: [map()]
  def group([], _eyebrow, _stamp_width, _stamp_size, _stamp_spacing), do: []

  def group(rows, eyebrow, stamp_width, stamp_size, stamp_spacing) do
    [eyebrow, entries(rows, stamp_width, stamp_size, stamp_spacing)]
  end

  @doc """
  Which of the two empty states this is — or neither.

  MOVIES-AND-TV.md #112: pressing a chip that matches nothing left the header
  and the chips over a blank page. That is the same misreading #117 fixed on
  the search screen: *nothing under this chip* and *nothing this month* are two
  different things, and the second one's sentence — *everything you have logged
  is older than the first* — is simply false when the month is full of rows the
  chip filtered out.

  So the filter is asked first. `All` can only be the month case; any other chip
  over an unfiltered month that HAS rows is the filter case.
  """
  @spec nothing_here(map(), [map()], [map()], String.t()) :: term()
  def nothing_here(log, [], [], filter) when filter != "All" do
    Kati.Screens.Activity.no_matches(filter, Kati.Screens.Activity.month_has_rows?(log))
  end

  def nothing_here(log, today, earlier, _filter),
    do: Kati.Screens.Activity.nothing_this_month(log, today, earlier)

  @doc false
  @spec month_has_rows?(map()) :: boolean()
  def month_has_rows?(log), do: Map.get(log, :today, []) != [] or Map.get(log, :earlier, []) != []

  @doc """
  Nothing under this chip, said as that rather than as nothing at all.

  Two sentences, because the two cases differ in what the reader should do:
  a month with other rows in it wants *press All*, and a month with none wants
  the same sentence `nothing_this_month/3` gives, since the chip is not why the
  page is empty.
  """
  # `sort` rather than `filter_alt`, which is not in Kati's icon subset — the
  # subset is generated from what the drawings use, and adding a glyph for one
  # empty state would mean a font rebuild for a card.
  @spec no_matches(String.t(), boolean()) :: map()
  def no_matches(filter, month_has_rows?) do
    assigns = %{
      # The chip's own word, not the key behind it. `filter` is `Added`, and a
      # Persian card reading *No added entries this month* with one Latin word
      # in the middle of it is the chip defect one sentence later. `filter_label/1`
      # is what the chip itself drew, so the card and the control agree by
      # construction rather than by two people remembering.
      #
      # `String.downcase/1` survives the move: English wants `No added entries`
      # under an `Added` chip, and Persian has no case to fold, so it is a no-op
      # on دیده‌شده rather than a second rule to write.
      title:
        gettext("No %{verb} entries this month",
          verb: String.downcase(Kati.Screens.Activity.filter_label(filter))
        ),
      body:
        if month_has_rows? do
          # The sentence names a chip, so it takes the chip's own label rather
          # than spelling `All` a second time — the two would be «همه» and
          # `All` on one card the day only one of them is translated.
          gettext("There is other activity this month. Press %{all} to see it.",
            all: Kati.Screens.Activity.filter_label("All")
          )
        else
          gettext(
            "Everything you have logged is older than the first. " <>
              "The rewatch counts below still cover all of it."
          )
        end,
      # `:show_all`, not the `All` chip's own `filter_All`: two nodes may not
      # share an `accessibility_id` — `onNodeWithTag` throws on the second
      # match, which is what the cross-scope row on screen 19 hit first.
      tap: {self(), :show_all}
    }

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={20}
        padding={15}
        shadow={Kati.Theme.shadow_card_soft()}
        on_tap={@tap}
      >
        <Spacer size={4} />
        <Row fill_width={true} align="center">
          <Spacer weight={1.0} />
          <Box width={44} height={44} corner_radius={14} background={Palette.paper()} align="center">
            {UI.symbol("sort", size: 21, color: Palette.rail_idle())}
          </Box>
          <Spacer weight={1.0} />
        </Row>
        <Spacer size={12} />
        <Text
          text={@title}
          text_size={13.5}
          font_weight="bold"
          text_color={:on_surface}
          text_align="center"
        />
        <Spacer size={6} />
        <Text
          text={@body}
          text_size={12}
          line_height={Kati.Locale.leading(1.55)}
          text_color={Palette.sub()}
          text_align="center"
        />
        <Spacer size={4} />
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  A month with nothing in it, on a device that has a history.

  Both groups on this page are month-scoped and `group/5` draws nothing for an
  empty one, so a reader whose watches are all older than the first of the
  month used to be handed the fixture — and now, correctly, gets their own real
  count in the header over two blank gaps. The gaps are what this fills.

  Not drawn on a device with nothing recorded at all: that one is on the
  drawing, which is what `log/0` answers with, and the drawing has rows.
  """
  @spec nothing_this_month(map(), [map()], [map()]) :: term()
  def nothing_this_month(%{count: count}, [], []) when count > 0 do
    # Assigns rather than two `gettext/1` calls inside the sigil: the second
    # sentence is the same msgid `no_matches/2`'s quiet branch carries, and a
    # two-line string does not fit an interpolation. `@title`/`@body` inside a
    # `~MOB` sigil are ASSIGNS, which is why the map is built first.
    assigns = %{
      title: gettext("Nothing this month"),
      body:
        gettext(
          "Everything you have logged is older than the first. " <>
            "The rewatch counts below still cover all of it."
        )
    }

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={20}
        padding={15}
        shadow={Kati.Theme.shadow_card_soft()}
      >
        <Spacer size={4} />
        <Row fill_width={true} align="center">
          <Spacer weight={1.0} />
          <Box width={44} height={44} corner_radius={14} background={Palette.paper()} align="center">
            {UI.symbol("history", size: 21, color: Palette.rail_idle())}
          </Box>
          <Spacer weight={1.0} />
        </Row>
        <Spacer size={12} />
        <Text
          text={@title}
          text_size={13.5}
          font_weight="bold"
          text_color={:on_surface}
          text_align="center"
        />
        <Spacer size={6} />
        <Text
          text={@body}
          text_size={12}
          line_height={Kati.Locale.leading(1.55)}
          text_color={Palette.sub()}
          text_align="center"
        />
        <Spacer size={4} />
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  def nothing_this_month(_log, _today, _earlier), do: []

  # `Kati.Screens.Pushed` floats the back pill over the content, so the content
  # has to leave room for it: the drawing's pill is 42 tall with a 16 gap under
  # it, which puts the title at 122 from the top exactly as the export does.
  @doc false
  def back_gap, do: ~MOB"<Spacer size={58} />"

  # Three things the title and its line have to ask the reader about.
  #
  # The 28's `-0.03` tracking is `Kati.Locale.tracking/1`: the design tightens
  # its display sizes by a fraction of an em, Arabic script has no such
  # tradition, and tracking a Persian run apart breaks the joins between its
  # letters — فعالیت set at -0.03 is six disconnected shapes. `max_lines={1}`
  # goes with it, because the heading had none and the longest word this slot
  # can hold is no longer the eight letters of `Activity`.
  #
  # And the mono line asks the STRING rather than the reader —
  # `Kati.Locale.mono_face/1` — because `entries_line/1` answers in both
  # scripts. `1,204 entries` is pure ASCII and stays in DM Mono, which is what
  # the export draws; `۱,۲۰۴ مورد` is not, and `kati_mono.ttf` carries no
  # Persian glyph at all, so it would be handed to Android's own substitute
  # face beside sentences that are Kati's.
  @doc false
  def header(entries_line) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        <Column weight={1.0}>
          <Text
            text={gettext("Activity")}
            text_size={28}
            max_font_scale={1.6}
            font_weight="bold"
            letter_spacing={Kati.Locale.tracking(-0.03)}
            max_lines={1}
            text_color={:on_surface}
          />
          <Spacer size={5} />
          <Text
            text={entries_line}
            font_family={Kati.Locale.mono_face(entries_line)}
            text_size={11}
            text_color={Palette.muted()}
            max_lines={1}
          />
        </Column>
        {Kati.Screens.Activity.disc("search", :open_search)}
        <Spacer size={9} />
        {Kati.Screens.Activity.disc("tune", :open_filters)}
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc """
  A 44pt round tap target holding one glyph — `Kati.Components.MishkaActionIcon`.

  Hand-rolled until the port grew a `shadow`, and that prop is the whole reason
  it can move now: a floating disc is *defined* by the lift under it, and
  `variant: :filled` paints a fill and stops. Without the shadow the port drew
  a flat #FBFAF8 patch on #EFECE7 paper — a 4%-different rectangle, which is
  worse than not adopting.

  **The pixels are the same node.** The port builds
  `<Box width={44} height={44} align={:center} corner_radius={22.0}
  background shadow on_tap>` — the same seven props this wrote by hand, with
  `shape: :circle` resolving to an exact `size / 2` where the markup said 22,
  and `align={:center}` where it said `align="center"` (both serialise to the
  string the bridge matches on). The one structural difference is the `<Row>`
  the port wraps children in; a `Row` with no props hugs its single child and
  centres it vertically, so the glyph measures and lands exactly where it did.
  """
  def disc(icon, tag) do
    MishkaActionIcon.action_icon(
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

  # Four chips at 7pt gaps measure ~285 inside the 360 the gutters leave, so
  # unlike screen 03's counted chips these do not need a horizontal Scroll.
  @doc false
  def filters(active) do
    chips =
      Sample.filters()
      |> Enum.map(fn value -> filter_chip(value, value == active) end)
      |> Enum.intersperse(chip_gap())

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        {chips}
      </Row>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def chip_gap, do: ~MOB"<Spacer size={7} />"

  @doc """
  One filter chip — `Kati.Components.MishkaChip`.

  A chip that carries a `checked` state and toggles is the whole of what that
  component is, and this is the first round where it can be *this* chip: the
  port used to hardcode its size, its radius, its type and both unchecked
  colours, so a 32pt pill with a 12.5 semibold label on Kati's own two greys
  could not be expressed. `height`, `padding_x`/`padding_y`, `corner_radius`,
  `text_size`, `font_weight`, `max_lines`, `unchecked_color` and
  `unchecked_text_color` are all props now, and this passes every one.

  **Why the pixels do not move.** The chip was a `Row`; the port builds a
  `Box`. Both hug — a `Row` by nature, the `Box` because the port sends
  `fill_width={false}` and the bridge finally reads it (fence K-17) — and both
  run the same modifier chain: background on the rounded shape, then
  `padding(0, 14, 0, 14)`, then `height(32)`. Padding is applied before height
  on either node, so the chip measures 32 tall and `14 + label + 14` wide
  either way.

  Two prop-level differences, both inert:

    * `padding_y: 0` is written where the `Row` wrote nothing. The bridge
      resolves a missing edge to the uniform padding and a missing uniform to
      zero, so an absent top edge and an explicit `0` are the same number.
    * `align` moves from the `Row` to the `Box`. On a `Row` this bridge's
      default vertical alignment is already `CenterVertically`, so `align`
      was a no-op there; on a hugging `Box` it centres the label in the 32,
      which is the same position — `(32 - label height) / 2` from the top in
      both.
  """
  def filter_chip(value, on?) do
    # The tag carries the VALUE and the chip draws the LABEL, which are two
    # different strings the moment the reader is Persian: `value` is the English
    # key `visible/2` matches `lead` against and `Kati.ScreenActivityTest` taps
    # by name (`:filter_Rated`), and `filter_label/1` is the only part in the
    # reader's language. One handler still serves every chip, and a fifth verb
    # is a change to `Kati.Activity.Sample.filters/0` and `filter_label/1`.
    MishkaChip.chip(
      label: Kati.Screens.Activity.filter_label(value),
      checked: on?,
      on_toggle: {self(), String.to_atom("filter_" <> value)},
      color: Palette.ink_fill(),
      text_color: Palette.on_ink(),
      unchecked_color: Palette.card(),
      unchecked_text_color: Palette.ink_soft(),
      height: 32,
      padding_x: 14,
      padding_y: 0,
      corner_radius: 16,
      text_size: 12.5,
      font_weight: :semibold,
      max_lines: 1
    )
  end

  @doc """
  One dated group as a single card of rows.

  `stamp_size` and `stamp_spacing` are the only difference between Today and
  Earlier this month, which is why they are parameters here rather than two
  near-identical functions. `stamp_width` is 44 from both callers — it stays
  an argument so the two calls state the shared gutter side by side, where a
  disagreement is visible.
  """
  def entries(rows, stamp_width, stamp_size, stamp_spacing) do
    last = length(rows) - 1

    children =
      rows
      |> Enum.with_index()
      |> Enum.map(fn {row, i} ->
        entry_row(row, stamp_width, stamp_size, stamp_spacing, i < last)
      end)

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={20}
        shadow={Kati.Theme.shadow_card_soft()}
        padding_left={15}
        padding_right={15}
        padding_top={4}
        padding_bottom={4}
      >
        {children}
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  # The line is a Box with a weight wrapping a Row, not a Row with a weight:
  # only a Box is guaranteed to take the weighted slot on this bridge, and the
  # two text runs have to sit side by side inside it. The trailing weighted
  # Spacer is what makes the unweighted Texts ellipsize instead of overflowing.
  #
  # The stamp's gap is 6, not the drawing's 12, and that is arithmetic rather
  # than taste: the export writes a 38pt stamp column and a 12pt gap, so the
  # thumbnail starts 50 in from the card's padding. Our column is 44 (see the
  # moduledoc — 38 ellipsised `12 AUG`), so the gap carries the other 6 and the
  # thumbnail lands exactly where the export draws it. A measured capture had
  # it 6.4dp right of the drawing before this. The whitespace either side of
  # the stamp is unchanged: the text is start-aligned in its column, so what
  # the eye reads as the gap is (column − text) + gap, which is 17 for `21:12`
  # in both the drawing and here.
  #
  # The stamp asks its own string for a face rather than naming `mono`, because
  # the two gutters answer differently: a clock is `۲۱:۱۲` under `:fa` and a
  # date is `۲۱ مرداد`, and `kati_mono.ttf` carries neither the Persian digits
  # nor a single Persian letter. `Kati.Locale.mono_face/1` keeps a Latin stamp
  # in DM Mono — which is what the drawn rows still carry, and what the export
  # draws — and sends a Persian one to Vazirmatn at the same size. The 0.06
  # `letter_spacing` Earlier this month draws goes through
  # `Kati.Locale.tracking/1` for the reason the heading's does: tracking pulls
  # apart letters that are joined.
  @doc false
  def entry_row(row, stamp_width, stamp_size, stamp_spacing, rule?) do
    tap = Kati.Screens.Activity.open_tap(row)

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_top={12} padding_bottom={12} on_tap={tap}>
        <Column width={stamp_width}>
          <Text
            text={row.stamp}
            font_family={Kati.Locale.mono_face(row.stamp)}
            text_size={stamp_size}
            letter_spacing={Kati.Locale.tracking(stamp_spacing)}
            text_color={Palette.muted()}
            max_lines={1}
          />
        </Column>
        <Spacer size={6} />
        {Kati.Screens.Activity.thumb(row)}
        <Spacer size={12} />
        <Box weight={1.0}>
          <Row fill_width={true} align="center">
            <Text
              text={Kati.Screens.Activity.verb_label(row.lead)}
              text_size={12.5}
              font_weight="bold"
              text_color={:on_surface}
              max_lines={1}
            />
            <Spacer size={2} />
            <Text text={row.rest} text_size={12.5} text_color={Palette.ink_soft()} max_lines={1} />
            {Kati.Screens.Activity.stars(row[:stars])}
            <Spacer weight={1.0} />
          </Row>
        </Box>
      </Row>
      {Kati.Screens.Activity.hairline(rule?)}
    </Column>
    """
  end

  @doc false
  def thumb(row) do
    case Kati.Design.Images.poster(row.seed) do
      nil ->
        ~MOB"<Box width={26} height={37} corner_radius={5} background={Palette.placeholder()} />"

      src ->
        ~MOB"""
        <Image src={src} width={26} height={37} corner_radius={5} content_mode="fill" />
        """
    end
  end

  # The drawing writes four ★ characters straight into the line. Plus Jakarta
  # Sans has no U+2605, so those would render as nothing at all — screen 08's
  # empty rating card was exactly this bug. Material Symbols `star` at the
  # line's own size and colour is the same mark in a font that carries it.
  @doc false
  def stars(nil), do: ~MOB"<Spacer size={0} />"

  def stars(count) do
    star = Kati.UI.symbol("star", size: 11, color: Palette.ink_soft(), fill: true)
    glyphs = List.duplicate(star, count)

    ~MOB"""
    <Row align="center">
      <Spacer size={5} />
      {glyphs}
    </Row>
    """
  end

  @doc """
  The rewatch card and its eyebrow, or neither.

  Same shape as `group/5` and for the same reason: a user who has never
  rewatched anything has nothing to count, and an eyebrow over an empty card
  is the "headed card with no rows" this screen's own moduledoc rejects. A
  list rather than a wrapper, so the two nodes flatten into the page's Column
  exactly where they were written and the drawn frame is unchanged.
  """
  @spec rewatch_section([{String.t(), String.t()}]) :: [map()]
  def rewatch_section([]), do: []
  def rewatch_section(rows), do: [UI.eyebrow(gettext("Rewatch count")), rewatch(rows)]

  @doc false
  def rewatch(rows) do
    last = length(rows) - 1

    children =
      rows
      |> Enum.with_index()
      |> Enum.map(fn {{name, count}, i} -> rewatch_row(name, count, i < last) end)

    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={20}
      shadow={Kati.Theme.shadow_card_soft()}
      padding={17}
    >
      {children}
    </Column>
    """
  end

  # Orange on the count is the design's own use of accent for "again, now" —
  # a rewatch is the one number on this screen that is still happening.
  #
  # `name` is a title and is never translated — it comes off `Kati.Media.Watch`
  # through the cache, or out of `Kati.Activity.Sample` on a fresh install. The
  # count asks its own string for a face for `entry_row/5`'s reason: `3×` is
  # ASCII and stays in DM Mono, `۳×` is not.
  @doc false
  def rewatch_row(name, count, gap?) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Text
          text={name}
          text_size={12.5}
          font_weight="semibold"
          text_color={:on_surface}
          max_lines={1}
        />
        <Spacer weight={1.0} />
        <Text
          text={count}
          font_family={Kati.Locale.mono_face(count)}
          text_size={12}
          text_color={Palette.accent()}
          max_lines={1}
        />
      </Row>
      {Kati.Screens.Activity.row_gap(gap?)}
    </Column>
    """
  end

  @doc false
  def row_gap(false), do: ~MOB"<Spacer size={0} />"
  def row_gap(true), do: ~MOB"<Spacer size={12} />"

  @doc false
  def hairline(false), do: ~MOB"<Spacer size={0} />"
  # `MishkaSeparator` rather than a hand-rolled Box, and `render: :box` rather
  # than the component's `:divider` default.
  #
  # `:divider` is NOT the Box this used to be. The comment that stood here said
  # it was — that Compose's `HorizontalDivider` is
  # `Box(fillMaxWidth().height(t).background(color))` — and that is wrong:
  # Material3 draws it as `Canvas { drawLine(strokeWidth = t.toPx()) }`, an
  # ANTIALIASED stroke. At this device's 2.6875x a 1dp rule gets a 3px canvas
  # and a 2.6875px stroke centred in it, so the bottom pixel row lands at ~69%
  # coverage — a full-width row 4-5/255 lighter than the two above it. The
  # adoption softened the hairline by one pixel row and nothing said so.
  #
  # `render: :box` is the component's filled-rect primitive: `<Box fill_width
  # height={thickness} background={color}>`, which is the node that was written
  # here by hand before the adoption, so the rule goes back to three full-colour
  # rows. (Its `<Spacer size={1} />` child is an iOS height workaround — on
  # Android the Box's own `height` pins it and the background covers it.)
  #
  # `color` is passed rather than left to the component's `:border` default:
  # Kati's border token is 0x14000000 and the drawing's rule is 0x121A1917.
  def hairline(true),
    do: MishkaSeparator.separator(color: Palette.hairline(), thickness: 1, render: :box)

  @doc """
  The search disc, which drew and opened nothing.

  Screen 19 is where a query goes from everywhere else in the app — 03's disc,
  20's and 21's — and there is no second search to point this one at. It said
  *"the drawing gives neither a destination"*, which was true of the drawing
  and not of the app: 19 has existed the whole time and every other header disc
  already opened it.

  The filter disc stays on `Kati.ScreenTapSweepTest`'s backlog. No board in the
  165 draws an activity filter sheet, so it has nowhere to go that would not be
  invented here.
  """
  @impl true
  # `back: "Activity"` and not `"Stats"`: this screen is itself pushed, so
  # opening 19 from here is a second push and its back pill pops onto this page
  # rather than onto the one above it.
  def handle_tap(:open_search, socket),
    do:
      {:noreply,
       Mob.Socket.push_screen(socket, Kati.Screens.Search, %{query: "", back: "Activity"})}

  # `tune` opens the same sheet the filter chips narrow with. It reached
  # `handle_tap/2`'s catch-all and did nothing — MOVIES-AND-TV.md #91 — which
  # is the worst kind of control: alive enough to swallow the tap, dead enough
  # to answer it with silence.
  def handle_tap(:open_filters, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.ShelfFilters)}

  # One clause for all four chips: the tag carries the label. And one for the
  # rows, which open the title the entry is about.
  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "filter_" <> label -> {:noreply, Mob.Socket.assign(socket, :filter, label)}
      # The empty-state card, which offers the same move the `All` chip does.
      "show_all" -> {:noreply, Mob.Socket.assign(socket, :filter, "All")}
      "open_" <> _id -> {:noreply, Kati.Screens.Activity.open(socket, tag)}
      _ -> {:noreply, socket}
    end
  end

  @doc """
  The tap that opens a log entry's title, or `nil`.

  MOVIES-AND-TV.md #90. A history you cannot walk back into is a list; the one
  thing somebody wants from *you watched Dune on 3 March* is Dune.

  `nil` on a drawn row, which is `Kati.Activity.Sample`'s: not tappable rather
  than broken.

      iex> Kati.Screens.Activity.open_tag(%{stamp: "3 MAR"})
      nil
  """
  @spec open_tap(map()) :: {pid(), atom()} | nil
  def open_tap(row) do
    case open_tag(row) do
      nil -> nil
      tag -> {self(), tag}
    end
  end

  @doc false
  @spec open_tag(map()) :: atom() | nil
  def open_tag(%{id: id}) when is_binary(id), do: String.to_atom("open_" <> id)
  def open_tag(_drawn), do: nil

  @doc """
  Open the title a row named — the series screen for a series, the film screen
  for a film, under a pill reading `Activity`.
  """
  @spec open(Mob.Socket.t(), atom()) :: Mob.Socket.t()
  def open(socket, tag) do
    log = socket.assigns.log

    (Map.get(log, :today, []) ++ Map.get(log, :earlier, []))
    |> Enum.find(&(Kati.Screens.Activity.open_tag(&1) == tag))
    |> case do
      nil ->
        socket

      row ->
        module = if row.kind == :movie, do: Kati.Screens.Film, else: Kati.Screens.Series
        Mob.Socket.push_screen(socket, module, %{id: row.id, back: "Activity"})
    end
  end

  # ── The log, read through Kati.Media ───────────────────────────────────────

  # `tracked_title` is loaded rather than looked up per row: it carries the
  # {source, source_id} pair every other lookup here is keyed on, and a query
  # per row is what turns a 1,204-entry log into 1,204 statements.
  defp watches do
    Watch
    |> Ash.Query.load(:tracked_title)
    |> Ash.read!()
  end

  # An import has no title behind it, and its row says so — *Imported 412
  # titles from a CSV backup* is the sample's own line and needs no poster.
  # Every other kind does, and a row whose title has since been deleted is
  # dropped rather than drawn nameless: the event cascades with the title, so
  # this only ever fires mid-delete.
  defp events do
    Kati.Media.Event
    |> Ash.Query.load(:tracked_title)
    |> Ash.read!()
  rescue
    _error -> []
  end

  # The cache half, keyed by the VALUE PAIR the durable half references it by
  # — never by a foreign key, which is the split `Kati.Media.CachedTitle`
  # exists to protect. A missing entry is the evicted case and is normal: the
  # row still draws, without its title's artwork.
  defp cached_by_reference([]), do: %{}

  defp cached_by_reference(watches) do
    ids = watches |> Enum.map(& &1.tracked_title.source_id) |> Enum.uniq()

    CachedTitle
    |> Ash.Query.filter(source_id in ^ids)
    |> Ash.read!()
    |> Map.new(&{{&1.source, &1.source_id}, &1})
  end

  # {date, clock, watch}. See `entries/0` on why a date-only watch has no clock
  # and therefore never lands in Today.
  # An event always knows its hour, unlike a watch: it is something the app
  # itself observed rather than something the reader remembered.
  defp stamped(%Kati.Media.Event{at: at} = event, zone) do
    local = Kati.Time.in_zone(at, zone)
    {DateTime.to_date(local), Calendar.strftime(local, "%H:%M"), event}
  end

  defp stamped(watch, zone) do
    cond do
      watch.watched_at ->
        local = Kati.Time.in_zone(watch.watched_at, zone)
        {DateTime.to_date(local), Calendar.strftime(local, "%H:%M"), watch}

      watch.watched_on ->
        {watch.watched_on, nil, watch}

      true ->
        {nil, nil, watch}
    end
  end

  # `12 AUG`, the gutter Earlier this month draws — and `۲۱ مرداد` under `:fa`,
  # which is a different CALENDAR rather than the same date translated. Board
  # 15's *earlier this month* is the reader's own month either way, so it is
  # `Kati.Locale.date/2` and not `Calendar.strftime/2`: 12 August 2026 falls in
  # Mordad, and no formatting of the number 8 produces that.
  #
  # `:short_padded` is the style `%d %b` was — the leading zero is what makes
  # `07 AUG` and `12 AUG` line up in a 44pt mono column — and `Kati.Locale`
  # resolves it to Shamsi's `:short` on purpose, because Persian numerals are
  # already even-width and have no column to pad.
  #
  # `Kati.UI.eyebrow_label/1` rather than `String.upcase/1` for the caps. This
  # is a stamp rather than an eyebrow, but it is the same question and that is
  # the app's one place to ask it: Persian has no case, so upcasing مرداد is a
  # no-op that reads in the diff as a decision somebody made.
  defp date_stamp(date), do: Kati.UI.eyebrow_label(Kati.Locale.date(date, :short_padded))

  # The first of the reader's OWN month, and the edge `earlier` is cut at.
  #
  # Every stamp in that group is already the reader's calendar — `date_stamp/1`
  # is `Kati.Locale.date/2` precisely so that 12 August draws as ۲۱ مرداد — and
  # the eyebrow over them says *this month*. The boundary was
  # `Date.beginning_of_month/1`, so the heading and the rows underneath it were
  # counted in two different calendars, and the gap between them is not small:
  # on 21 Shahrivar 1405 the reader's month opened on 23 August and the
  # Gregorian one on 1 September, so nine days of the reader's own month were
  # neither `today` nor `earlier` and fell out of BOTH comprehensions. Those
  # rows did not move to another group, they left the page — while `count` and
  # `entries_line/1` above went on counting them, which is a header promising
  # more entries than the screen can show. MOVIES-AND-TV.md #58 is the same
  # shape of defect one scope up.
  #
  # Shaped after `Kati.Locale.year_start/1`, which answers this question a year
  # up: a Gregorian `Date` in both scripts, because everything downstream
  # compares in one calendar and names in the other.
  defp month_start(date), do: Kati.Locale.pick(Date.beginning_of_month(date), shamsi_first(date))

  # A Shamsi year the Nowruz table does not cover falls back to the Gregorian
  # first — the answer every reader got before this — rather than raising. It is
  # wrong about where the month's edge is and never about which rows are recent,
  # which is the failure `Kati.Locale.year_start/1` chooses too.
  defp shamsi_first(date) do
    {year, month, _day} = Kati.Calendar.Shamsi.from_gregorian(date)

    case Kati.Calendar.Shamsi.to_gregorian(year, month, 1) do
      {:ok, first} -> first
      {:error, _outside} -> Date.beginning_of_month(date)
    end
  end

  # `21:12`, the gutter Today draws, in the reader's own digits.
  #
  # Separate from `stamped/2`, which keeps the ASCII `%H:%M` it formats: that
  # string is also the sort key and the `is_nil` gate that decides whether a
  # row can be in Today at all, and a sort whose correctness rests on
  # U+06F0–U+06F9 being contiguous is a sort nobody can check by reading it.
  # So the digits change here, where the clock stops being a key and becomes a
  # stamp. `Kati.Locale.number/1` rather than `Kati.Locale.time/1` for the same
  # reason — the time is already formatted by the time it reaches this.
  defp clock_stamp(clock), do: Kati.Locale.number(clock)

  defp row(%Kati.Media.Event{} = event, stamp, cached) do
    {lead, rest} = event_verb(event, event.tracked_title, cached)

    event.tracked_title
    |> case do
      nil -> %{seed: nil, id: nil, kind: nil}
      tracked -> %{seed: seed_of(tracked, cached), id: tracked.id, kind: tracked.kind}
    end
    |> Map.merge(%{stamp: stamp, lead: lead, rest: rest})
  end

  defp row(watch, stamp, cached) do
    tracked = watch.tracked_title
    named = named(title_of(tracked, cached), episode_label(watch))
    {lead, rest} = verb(watch, named)

    row = %{
      stamp: stamp,
      seed: seed_of(tracked, cached),
      lead: lead,
      rest: rest,
      # The title this entry is about, so the row can open it — MOVIES-AND-TV.md
      # #90: *no row in the activity log is tappable, so the user cannot open a
      # title from their own history*, which is the one thing a history is for.
      # Absent on a drawn row, the way `:stars` is, so the two shapes stay
      # indistinguishable and the fallback stays one.
      # `tracked` cannot be nil here: `Kati.Media.Watch`'s `belongs_to` is
      # `allow_nil?: false`, and `title_of/2` has already read `tracked.source`
      # two lines up — a guard here would fire after the crash it guards.
      id: tracked.id,
      kind: tracked.kind
    }

    # The key is absent rather than nil when there is no rating, because that is
    # what `Kati.Activity.Sample` produces and `entry_row/5` reads it with
    # `row[:stars]` — a rating of nothing and no rating are the same node, and
    # the two shapes have to be indistinguishable for the fallback to be one.
    case star_count(watch.rating) do
      nil -> row
      count -> Map.put(row, :stars, count)
    end
  end

  # Which verb a watch gets. Order matters: a rewatch that was also rated reads
  # as `Rated`, because the stars are the thing the row is showing and the chip
  # that finds it is the one the user pressed. `Watched` keeps `Rewatched` too
  # — see `visible/2`, which matches on containment for exactly this.
  #
  # The verb stays ENGLISH here. It is the value `visible/2` filters on and the
  # word the chips are keyed by; `verb_label/1` is what the row is drawn with.
  defp verb(%{rating: rating}, named) when is_integer(rating), do: {"Rated", named}

  defp verb(%{rewatch_number: n}, named) when is_integer(n) and n > 1 do
    {"Rewatched", named <> " · " <> nth_time(n)}
  end

  defp verb(_watch, named), do: {"Watched", named}

  # `3rd time`, and `بار ۳ام`. A msgid rather than `ordinal(n) <> " time"`,
  # because the two halves are not in that order in Persian — the counter word
  # comes first — and a sentence assembled out of two translated fragments can
  # only ever be assembled in English's order.
  #
  # `pgettext/2` because `%{ordinal} time` is two tokens: the catalogue already
  # holds `last time` and `used %{n} time`, and `mix gettext.merge` fuzzy-matches
  # a msgid this short onto a neighbour that half-resembles it.
  defp nth_time(n),
    do: pgettext("the nth viewing, on a rewatch row", "%{ordinal} time", ordinal: ordinal(n))

  # The verb an event gets, and the sentence after it. `Dropped … after S1E3`
  # is screen 15's own drawn line and this is where it comes from; the reason,
  # where there is one, closes it — that answer had nowhere to go at all until
  # `Kati.Media.Event` existed (#111).
  defp event_verb(%{kind: :imported} = event, _tracked, _cached) do
    n = event.count || 0
    titles = ngettext("%{n} title", "%{n} titles", n, n: Kati.Locale.number(n))

    case event.source_label do
      # `Kati.Locale.ltr/1` around the label, because it is a FILE NAME — the
      # one this import was read out of — and a Latin run inside a Persian
      # sentence hands its full stop to the paragraph's direction. Without the
      # isolate, `goodreads_library_export.csv` draws with its `.csv` at the
      # wrong end of the run, which is legible enough that nobody files it.
      label when is_binary(label) and label != "" ->
        {"Imported",
         pgettext("an import row in the activity log", "%{titles} from %{source}",
           titles: titles,
           source: Kati.Locale.ltr(label)
         )}

      # An import that recorded no source. The guard was `if event.source_label`,
      # so a stored `""` drew the line as `412 titles from ` with the preposition
      # left hanging — the sentence promises a source and then does not name one.
      _none ->
        {"Imported", titles}
    end
  end

  defp event_verb(event, nil, _cached),
    do: {event_word(event.kind), gettext("Untitled")}

  defp event_verb(event, tracked, cached) do
    title = title_of(tracked, cached)

    {event_word(event.kind),
     [title, event_position(event), event_reason(event)]
     |> Enum.reject(&is_nil/1)
     |> Enum.join(" · ")}
  end

  # English, like `verb/2`'s: this is `lead`, which is a key. `verb_label/1`
  # draws it.
  defp event_word(:added), do: "Added"
  defp event_word(:dropped), do: "Dropped"
  defp event_word(:abandoned), do: "Abandoned"
  defp event_word(:dnf), do: "Did not finish"
  defp event_word(:resumed), do: "Resumed"
  defp event_word(:finished), do: "Finished"
  defp event_word(other), do: other |> to_string() |> String.capitalize()

  defp event_position(%{season_number: s, episode_number: e})
       when is_integer(s) and is_integer(e),
       do:
         pgettext("where a series was left, on an activity row", "after S%{s}E%{e}",
           s: Kati.Locale.number(s),
           e: Kati.Locale.number(e)
         )

  # A season with no episode behind it — `Finished · Season 1`, which is board
  # 15's own *Nightbirds — Season 1* row and the one drawn line `Kati.Media.Event`
  # can store and this could not print. The clause above wants BOTH numbers, so
  # a season-only event fell through to the catch-all and the row drew the bare
  # title: the reader was told a season finished and not which one.
  # `episode_label/1` has had exactly this pair of clauses all along, and
  # `Kati.Media.Event` is explicit that `episode_number` is nil "for a film, and
  # for anything that has no position" — a whole season is one of those.
  #
  # `Season %{n}` rather than a msgid of this screen's own: `Kati.Screens.Series`,
  # `Kati.Screens.Season` and `Kati.Screens.Inbox` all draw that one already, and
  # a second Persian word for a season is a season spelled two ways. Plain
  # `gettext/1` for the same reason — the shared msgid carries no context.
  defp event_position(%{season_number: s}) when is_integer(s),
    do: gettext("Season %{n}", n: Kati.Locale.number(s))

  defp event_position(_event), do: nil

  defp event_reason(%{reason: reason}) when is_binary(reason) and reason != "",
    do: String.downcase(reason)

  defp event_reason(_event), do: nil

  defp named(title, nil), do: title
  defp named(title, label), do: title <> " " <> label

  # A label snapshot, never identity — `Kati.Media.Watch` is emphatic about
  # that, and this is the one place the snapshot is for: printing it.
  #
  # `pgettext/2` on both, and not because either word is ambiguous: `S%{s}` is
  # two characters and a binding, and `mix gettext.merge`'s fuzzy matcher will
  # hand a msgid that short to any sentence it half-resembles. The Persian is
  # the abbreviation `Kati.Screens.Stats` already writes for the same pair —
  # ف for فصل and ق for قسمت — so a title reads `گودال بلند ف۲ق۵` here and on
  # every other board that names an episode.
  defp episode_label(%{season_number: s, episode_number: e})
       when is_integer(s) and is_integer(e),
       do:
         pgettext("episode label on an activity row", "S%{s}E%{e}",
           s: Kati.Locale.number(s),
           e: Kati.Locale.number(e)
         )

  defp episode_label(%{season_number: s}) when is_integer(s),
    do: pgettext("season label on an activity row", "S%{s}", s: Kati.Locale.number(s))

  defp episode_label(_watch), do: nil

  defp title_of(tracked, cached) do
    case Map.get(cached, {tracked.source, tracked.source_id}) do
      %{title: title} when is_binary(title) and title != "" -> title
      # The evicted case. The memory survived the wipe and the poster did not,
      # so the row says so rather than disappearing from the user's own history.
      _ -> gettext("Untitled")
    end
  end

  # `Kati.Seeds` writes the design seed straight into `poster_path` — "not a
  # TMDB path: the sample artwork is resolved by seed" — and `sample_source_id/1`
  # is the other half of the same convention. Either answer is a seed
  # `Kati.Design.Images.poster/1` can miss harmlessly: `thumb/1` draws the
  # placeholder tile for a nil.
  defp seed_of(tracked, cached) do
    case Map.get(cached, {tracked.source, tracked.source_id}) do
      %{poster_path: path} when is_binary(path) and path != "" -> path
      _ -> Kati.Seeds.sample_seed(tracked.source_id)
    end
  end

  # Ten-point scale to whole glyphs: `9` is four and a half stars and this row
  # draws whole ones, so it draws four. `div/2` rather than `round/1` on
  # purpose — rounding 9 up to five would claim half a star the user did not
  # give. A 1 is half a star and no whole one, which is no glyphs at all, and
  # that is the absent key rather than an empty Row.
  defp star_count(rating) when is_integer(rating) do
    case div(rating, 2) do
      0 -> nil
      count -> count
    end
  end

  defp star_count(_rating), do: nil

  # `3rd`, and `۳ام`.
  #
  # English's four suffixes are an English rule and stop at the language edge:
  # Persian forms an ordinal by suffixing ـُم to the numeral, with no exception
  # for 11 to 13 and none for the units — `۳ام` is regular where `3rd` is one
  # of four cases. So this is `Kati.Locale.pick/2` over two whole answers rather
  # than a shared skeleton with a translated suffix, which would be the English
  # rule with Persian letters in it.
  defp ordinal(n), do: Kati.Locale.pick(latin_ordinal(n), Kati.Locale.number(n) <> "ام")

  defp latin_ordinal(n) do
    suffix =
      cond do
        rem(n, 100) in 11..13 -> "th"
        rem(n, 10) == 1 -> "st"
        rem(n, 10) == 2 -> "nd"
        rem(n, 10) == 3 -> "rd"
        true -> "th"
      end

    Integer.to_string(n) <> suffix
  end

  @doc """
  `1,204 entries`, `1 entry`, or `nothing logged yet`.

  Grouped by hand rather than through `Kati.Cldr`, and that is a statement
  about the GROUPING MARK rather than about the digits. CLDR's `fa` groups with
  U+066C and the boards do not — `test/design/screens/59.html` writes ۱,۴۸۰ with
  a Latin comma — so `delimited/1` places the drawing's comma itself and hands
  the result to `Kati.Locale.number/1`, which converts the numerals and the
  decimal point and leaves the separator alone. The paragraph that stood here
  said the digits stayed ASCII because *the Persian mirrors are their own
  screens*; mishka-group/kati#103 folded the last of those away, and the line
  below it has read the reader's own numerals since.

  Public because screen 07's *More numbers* draws the same sentence about the
  same rows, and drew `Kati.Stats.Sample`'s frozen `1,204 entries` on every
  device until 6 September. One wording, one place.

      iex> Kati.Screens.Activity.entries_line(0)
      "nothing logged yet"

      iex> Kati.Screens.Activity.entries_line(1)
      "1 entry"

      iex> Kati.Screens.Activity.entries_line(1204)
      "1,204 entries"
  """
  @spec entries_line(non_neg_integer()) :: String.t()
  def entries_line(0), do: gettext("nothing logged yet")

  def entries_line(n),
    do: ngettext("%{n} entry", "%{n} entries", n, n: delimited(n))

  # Grouped thousands, in the reader's own digits. The grouping mark stays a
  # Latin comma in both scripts, which is the drawing's own choice and the
  # reason `Kati.Locale.number/1` converts the decimal point and not the
  # separator — `test/design/screens/59.html` writes ۱,۴۸۰.
  #
  # What was missing is the digits: this ended at `Integer.to_string/1`, so the
  # Persian *More numbers* row that reads this line said `1,204` in Latin
  # numerals under a Persian title.
  defp delimited(n) do
    n
    |> Integer.to_string()
    |> String.reverse()
    |> String.graphemes()
    |> Enum.chunk_every(3)
    |> Enum.map_join(",", &Enum.join/1)
    |> String.reverse()
    |> Kati.Locale.number()
  end

  # What has been watched more than once, and how many times.
  #
  # Grouped by `{tracked_title_id, episode_source_id}` — the episode's own id,
  # which is what makes a tick survive a renumbering — so a film groups under
  # its `nil` episode and each episode counts on its own.
  defp rewatch_counts(watches, cached) do
    watches
    |> Enum.group_by(&{&1.tracked_title_id, &1.episode_source_id})
    |> Enum.map(fn {_key, rows} -> rewatch_entry(rows, cached) end)
    |> Enum.reject(&is_nil/1)
    |> Enum.sort_by(fn {label, times} -> {-times, label} end)
    # The count is a figure and a symbol rather than a sentence, so the msgid is
    # mostly there to let the Persian keep or drop the `×` — it reads as a
    # multiplication sign in both scripts and the drawing writes it, but a
    # translator who wants `۳ بار` should not have to change this file. The
    # digits are the reader's own either way; `rewatch_row/3` gives the string a
    # face to match.
    |> Enum.map(fn {label, times} ->
      {label,
       pgettext("how many times a title has been watched", "%{n}×", n: Kati.Locale.number(times))}
    end)
  end

  # `rewatch_number` is the user's own count and beats the row count, because
  # `Kati.Media.Watch` says it exists precisely for the history that predates
  # Kati: someone who saw a film twice before installing and once since has one
  # row saying "3rd", and counting rows would print 1×.
  defp rewatch_entry([first | _] = rows, cached) do
    claimed =
      rows
      |> Enum.map(& &1.rewatch_number)
      |> Enum.filter(&is_integer/1)
      |> Enum.max(fn -> 0 end)

    times = max(length(rows), claimed)

    if times > 1 do
      {named(title_of(first.tracked_title, cached), episode_label(first)), times}
    end
  end
end
