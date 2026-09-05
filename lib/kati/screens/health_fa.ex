defmodule Kati.Screens.HealthFa do
  @moduledoc """
  Screen 115 — سلامت, weight and today's doses in the mirror, pushed under خانه.

  Screens 109 and 112 on one page, turned round. The caption pins three things
  and all three are about direction, type or geometry rather than about words.

  ## The chart mirrors for free, and the ink bar is the proof

  *The chart's time axis reads right-to-left, so time advances leftward: today's
  ink bar sits at the leading left edge and the oldest reading at the right.*
  Nothing here reverses a list to get that. `Kati.Screens.Weight.bars/0` returns
  its fractions **oldest first**, a `Row` lays out start-to-end, and
  `Kati.Screens.Fa.pushed_frame/1` declares `rtl` on the root — so the first
  fraction lands at the right and the newest at the left, which is the same
  mechanism that puts the Persian dock's home tab on the right and screen 76's
  pixel field's first day in the top-right corner. The two axis labels follow
  the same rule: `۱۴ اردیبهشت` is written first and lands under the oldest bar.

  Only the last bar is painted here. `Kati.Screens.Weight.bar/1` draws the other
  thirteen, because a bar is a bar in both languages and the day 109's bar
  changes shape this chart changes with it.

  ## Where this frame and 109's module disagree, and which one wins

  Screen 76's rule, unchanged: *the frame is the thing being reproduced*, so the
  frame wins — but only where the palette can reach what it draws.

    * **The thirteen older bars are grey, not gold.** The board paints them
      `#D3B98A`, which is in no `Kati.Theme.Palette` row at all;
      `Kati.Screens.WeightStates` found the same thing on screen 110's board and
      drew 109's `Kati.Theme.Palette.bar_ink/0` instead. Reaching around the
      palette for a hex literal would put a colour on this page that no other
      screen could ever match.
    * **The newest bar *is* tipped in ink**, where 110 declined to tip it. The
      two departures have different causes and only one of them is forced:
      `Kati.Theme.Palette.ink/0` is a token and the gold is not. And 110 is a
      states sheet, whose job is to report what 109 draws; this is a mirror,
      whose job is to draw its own frame — and on this frame the tip is the
      evidence for the caption's whole claim about which end is today.
    * **The track is 96 tall with 3pt gaps at radius 2**, where the board draws
      88 with 5pt gaps at radius 4. `bar/1` scales its fraction by 96 and a
      96-scaled height inside an 88-tall row clips, so the metrics are 109's
      and the three gridlines are 110's `gridlines/1`, whose 47/46 spacers are
      cut for that same 96.
    * **A missed dose is ringed red.** `Kati.Screens.Medication.mark/1` tints it
      `gold_icon` and draws no ring at all; this frame draws 59's ring in
      `Kati.Theme.Palette.red/0`, which is its `#B4553C` exactly. Both are
      reachable, so the frame's wins here.
    * **The ۲۱:۰۰ dose is due, and there are three doses rather than four.**
      `Kati.Health.WeightSample.doses/0` has Magnesium taken and lists a
      ۱۳:۰۰ Vitamin D the frame does not print. The frame is drawn whole or not
      at all, so with nothing stored this page draws the frame's three.

  ## DM Mono is the one thing the caption asks for that cannot be given

  *Weight keeps DM Mono with Persian digits and the Persian decimal separator
  (۷۶٫۰).* Half of that ships. `Kati.Screens.Fa`'s moduledoc has the finding:
  `kati_mono.ttf` carries **none** of U+06F0–U+06F9 and Vazirmatn carries all
  ten, so anything the design sets in mono is set here in `fa` at the design's
  size and colour — the face is wrong and the glyphs are right, which is the
  better half of an unwinnable trade, and it goes away the day the mono subset
  is regenerated. Every numeral on this page is in that position: the hero
  figure, the change pill, the three dose times and the two axis labels.

  The separator half is honoured exactly. `Kati.I18n.Digits.to_persian/1`
  deliberately leaves separators alone — its own doc says which separator a
  number wants is a formatting decision and not a character map's business — so
  `persian/1` makes that decision once, in one place, and `76.0` becomes
  `۷۶٫۰` with U+066B rather than an ASCII dot.

  ## The doses are 59's meal cards, down to the indent

  *Dose cards inherit 59's mirrored meal-card geometry, including the action row
  indenting from the right.* Taken, missed and due are eaten, skipped and next,
  and `Kati.Screens.Medication`'s own moduledoc already says the two vocabularies
  are deliberately parallel — so `ring/1` here maps the three dose states onto
  the three meal states and calls `Kati.Screens.TodayFa.ring/1`, and the time
  gutter calls `Kati.Screens.TodayFa.gutter_weight/1` and `gutter_color/1`.

  The indent is `padding_left={15}` on the action row, which is 59's number. The
  bridge maps `padding_left` to Compose's **start** (`MobBridge.kt:3944`), so
  under `rtl` it is the physical right edge — read the two paddings as
  leading/trailing and the caption's "from the right" needs no second
  arrangement.

  ## The back pill says سلامت, which is the board's word and not a parent

  The artboard's pill reads سلامت, and so does this screen. It is worth saying
  why, because the Persian shell has no Health root — `Kati.Screens.Fa.roots/0`
  is خانه, تقویم, کتابخانه and آمار — and this page *is* the Persian health
  page, pushed from خانه's سلامت tile.

  `Kati.Screens.Pushed`'s `back:` is a drawn label, not a parent lookup: the
  pill pops whatever pushed it whatever the label says. Every board in the app
  is reproduced with the word it draws, and screen 110 is the nearest case —
  `Kati.Screens.WeightStates` keeps `back: "Health"` from its own board while
  the route that reaches it comes from somewhere else entirely. Substituting
  خانه here would be inventing copy the design does not have, to fix something
  that is not broken.

  ## The one word changed inside the board's own note

  The board's cream note reads *…و ستون امروز در سمت راست است* — today's column
  is on the right. Its own bars say otherwise: the ink bar is the last child of
  an `rtl` row and lands at the left, the axis prints امروز at the left, and the
  caption under the frame says *today's ink bar sits at the leading left edge*.
  So the note is rendered with چپ where the board wrote راست. Everything else in
  it is the board's, including the DM Mono clause the section above says the
  shipped fonts cannot honour yet: that one is a claim about a font subset,
  which no reader can check from the screen, where a direction note that points
  at the wrong end of the chart is wrong to everyone who reads it.

  The board bolds `U+066B` inside that sentence. It is one `Text` here.
  `Kati.UI.rich_text/1` merges its runs into a single node and drops the per-run
  font — on a Persian screen one run would then decide the face for all of them
  — and a `Row` of separate runs does not wrap, which this is the only
  paragraph on the page that has to do.

  ## Two halves, two stores, asked separately

  `Kati.Screens.Weight.latest/0` and `Kati.Screens.Medication.doses/0` each fall
  back to the drawing when their own resource is empty, and this page asks each
  one on its own: a device with weight readings and no medications shows real
  weight beside the drawn doses, because that is the truth about that device.
  The identity check against `drawn_doses/0` is how the question is asked
  without a second query.

  D-59 made the medication half honest and this page got the fix for free.
  `Kati.Screens.Medication.doses/0` used to gate on `Kati.Health.Dose` alone,
  so a device with a medication and no dose row answered with the English
  page's four drawn tablets — the check below then matched, and this page drew
  its own three Persian fixtures beside a real weight. That was the same defect
  one locale over. The gate is the medication and the day together now, and the
  check does not change a character; what it has to survive is two new answers.
  `doses/0` can come back **derived** — rows composed from a medication's
  `times`, with no id, which is why the tap tags travel with a row rather than
  being rebuilt from an id it may not have — and it can come back `[]`, which
  is medications stored and nothing due. `dose_list/1` words that state.

  Dates are Solar Hijri and `Kati.Calendar.Shamsi` can actually say them, so the
  line under وزن is a real date the moment anything is stored. With nothing
  stored it stays the drawing's یکشنبه ۲۵ مرداد, for screen 112's reason:
  *dating the drawing's doses with the device's today would put a real date on a
  fixture.*

  ## The Persian copy is a proposal

  Screen 72's caption sets the rule for all of it. `labels/0`, `drawn_doses/0`
  and `note_text/0` hold every string in one place so a native reader correcting
  one corrects it once. پوند and استون are the least settled of them — neither
  unit is drawn anywhere in the 127.
  """

  use Mob.Screen
  import Mob.Sigil

  alias Kati.Calendar.Shamsi
  alias Kati.Components.MishkaActionIcon
  alias Kati.Components.MishkaThemeIcon
  alias Kati.Health.Reading
  alias Kati.Health.WeightSample
  alias Kati.I18n.Digits
  alias Kati.Screens.BookDetailFa
  alias Kati.Screens.Fa
  alias Kati.Screens.LogProgressFa
  alias Kati.Screens.Medication
  alias Kati.Screens.TodayFa
  alias Kati.Screens.Weight
  alias Kati.Screens.WeightStates
  alias Kati.Theme
  alias Kati.Theme.Palette
  alias Kati.UI

  # Every word the frame prints that is chrome rather than a fact about a
  # reading or a dose. Facts come through `Kati.Screens.Weight` and
  # `Kati.Screens.Medication` so the mirror and the English pages cannot
  # disagree about what was weighed or what was taken.
  @labels %{
    back: "سلامت",
    title: "وزن",
    date: "یکشنبه ۲۵ مرداد",
    latest: "آخرین · امروز",
    yesterday: "آخرین · دیروز",
    latest_prefix: "آخرین · ",
    doses: "داروهای امروز",
    taken: "خوردم",
    skip: "رد کن",
    # D-59. `Kati.Screens.Medication.doses/0` gates on the medication now as
    # well as on the dose, so it can answer `[]` — you have medications and
    # none is due today — and this page inherits that state through the
    # identity check in `doses/0` below.
    #
    # The words are `Kati.Screens.HomeFa.empty_day/0`'s first clause verbatim:
    # چیزی برای امروز نیست. Its «— هر چیزی را با + اضافه کنید» tail is dropped,
    # for the reason that function's own doc gives for having written a tail at
    # all — *the control it names is real*. Neither pointer the English
    # sentence takes is true here: this page draws no Schedules group (see
    # `content/1`) and its `+` opens `Kati.Screens.LogWeight`, a weight sheet.
    # So Persian says the half that is true and stops, and the asymmetry with
    # `Kati.Screens.Medication.nothing_due/1` is the rule being followed rather
    # than a gap in the translation.
    #
    # Here rather than in a function of its own because this file's moduledoc
    # requires it: *`labels/0`, `drawn_doses/0` and `note_text/0` hold every
    # string in one place so a native reader correcting one corrects it once* —
    # and `labels/0` is public, so a test points at `labels().nothing_due` as
    # readily as at a function.
    nothing_due: "چیزی برای امروز نیست"
  }

  # Keyed by `Kati.Screens.Weight.ranges/0`'s own tags rather than listed in
  # order, so a fourth range added to 109 raises here instead of quietly
  # drawing a segment with no label.
  @ranges %{range_week: "هفته", range_month: "ماه", range_all: "همه"}

  # The unit word beside the hero figure. کیلوگرم is the board's; the other two
  # are proposals — see the moduledoc.
  @units %{kg: "کیلوگرم", lb: "پوند", st: "استون"}

  # The two axis labels, which are the drawing's on 109 as well:
  # `Kati.Screens.Weight.chart/0` reads `Kati.Health.WeightSample.axis/0`
  # unconditionally, stored readings or not. Oldest first, so `rtl` lands it at
  # the right under the oldest bar.
  @axis {"۱۴ اردیبهشت", "امروز"}

  # The three doses the frame prints, in clock order. `line` carries no state
  # word: the suffix is composed the way `Kati.Screens.Medication.state_line/1`
  # composes it — rejected when empty, joined with a middot — so both pages
  # spell "missed" in one place each.
  @doses [
    %{time: "۰۸:۰۰", name: "لووتیروکسین", line: "۵۰ میکروگرم", state: :taken},
    %{time: "۱۴:۰۰", name: "آهن", line: "۶۵ میلی‌گرم", state: :missed},
    %{time: "۲۱:۰۰", name: "منیزیم", line: "۲۰۰ میلی‌گرم", state: :due}
  ]

  # `Kati.Health.Dose.state_suffix/1` in Persian. Same two states carry a
  # suffix, and `:taken` and `:due` carry none, because a dose that happened on
  # time has nothing to add to its own line.
  @suffixes %{missed: "جا افتاد", skipped: "رد شد"}

  # The Persian decimal separator is U+066B, not the ASCII dot.
  @decimal "٫"

  # 109's chart track. `Kati.Screens.Weight.bar/1` scales by it and
  # `Kati.Screens.WeightStates.gridlines/1`'s spacers are cut for it.
  @track 96

  # The accent rail on the due card. The board stretches it to the card's
  # content box; nothing on this bridge reports geometry back to `render/1`, so
  # it is declared — screen 59 declares 52 for a card whose height is set by a
  # 52pt thumbnail, and this card's height is two text lines and a 32pt ring.
  @rail 36

  def mount(_params, _session, socket) do
    Kati.Theme.activate()

    {:ok,
     socket
     |> Mob.Socket.assign(:latest, latest())
     |> Mob.Socket.assign(:subtitle, subtitle())
     |> Mob.Socket.assign(:doses, doses())
     |> Mob.Socket.assign(:range, :range_month)}
  end

  def render(assigns), do: Fa.pushed_frame(content(assigns), Kati.Screens.Identity.of(__MODULE__))

  @doc "Every Persian string this screen owns, in one map — see the moduledoc."
  @spec labels() :: map()
  def labels, do: @labels

  @doc "The board's cream note, with the one word the moduledoc argues for."
  @spec note_text() :: String.t()
  def note_text do
    "نمودار از راست به چپ خوانده می‌شود و ستون امروز در سمت چپ است. " <>
      "اعداد وزن در DM Mono با ارقام فارسی و جداکننده اعشار U+066B می‌مانند " <>
      "تا ستون هم‌تراز بماند."
  end

  @doc "The frame's three doses, unconditionally."
  @spec drawn_doses() :: [map()]
  def drawn_doses, do: @doses

  @doc """
  Persian digits, and the separator the digits want.

  `Kati.I18n.Digits.to_persian/1` maps the digit range and leaves separators
  alone on purpose, so the one place that decides a Persian number writes its
  decimal point as U+066B rather than as `.` is here. Every numeral on the page
  goes through it, which is why the hero figure and a dose line cannot disagree
  about what a decimal point looks like.
  """
  @spec persian(String.t()) :: String.t()
  def persian(text), do: text |> Digits.to_persian() |> String.replace(".", @decimal)

  @doc """
  The hero's reading: 109's, in Persian numerals and with a Persian unit word.

  `Kati.Screens.Weight.latest/0` does the reading — it answers the store and
  falls back to the drawing — and what this adds is the three things that are
  words rather than facts: the label, the unit and the separator. `direction` is
  passed through untouched, because which way a body moved is not a translation.
  """
  @spec latest() :: map()
  def latest do
    reading = Weight.latest()

    %{
      label: Kati.Screens.HealthFa.latest_label(reading.label),
      figure: persian(reading.figure),
      unit: Map.fetch!(@units, Kati.Health.unit()),
      direction: reading.direction,
      change: persian(Kati.Screens.HealthFa.bare(reading.change))
    }
  end

  @doc """
  `Kati.Screens.Weight.latest/0`'s label, said in Persian.

  109 composes it as `"Latest · " <> when_label(date)` and returns the sentence
  rather than the date, so the two day words are matched here and anything else
  keeps the date 109 formatted with its digits folded. That last arm is the one
  line on this page that cannot be said in Persian: `Kati.Calendar.Shamsi` needs
  a `Date` and there is none to hand it. The smallest fix is upstream — `latest/0`
  returning the date it dated — and until then the arm is a Gregorian month name
  in a Persian sentence, which is named here rather than hidden.
  """
  @spec latest_label(String.t()) :: String.t()
  def latest_label(label) do
    case String.split(label, " · ", parts: 2) do
      [_latest, "today"] -> @labels.latest
      [_latest, "yesterday"] -> @labels.yesterday
      [_latest, on] -> @labels.latest_prefix <> persian(on)
      _other -> @labels.latest
    end
  end

  @doc """
  A change with its unit taken off, because the hero already carries the unit.

  109's own argument about its `since` line: *the unit is already on the hero
  above it, and repeating it inside a mono caption reads as a second measurement
  rather than the same one.* `Kati.Health.Reading.display/2` is the only thing
  that formats a change and it always appends the unit, so it comes off here
  rather than being computed a second way.

  Stones are the case this leaves whole. `display/2` spells them `11st 13.6`,
  with the unit inside the figure rather than after it — the spelling
  `Kati.Screens.WeightStates` also had to record — so `String.replace_suffix/3`
  finds nothing and the pill keeps the `st`. Losing the pounds would be worse
  than a wide pill.
  """
  @spec bare(String.t()) :: String.t()
  def bare(change) do
    String.replace_suffix(change, " " <> Reading.unit_label(Kati.Health.unit()), "")
  end

  @doc """
  Today's doses: what is stored, or the frame's three.

  `Kati.Screens.Medication.doses/0` answers the reader and falls back to
  `drawn_doses/0`, so comparing the two is how this screen asks *did anything
  come back?* without running the query again. What comes back may be composed
  from a medication's `times` rather than read from `health_doses` — see the
  moduledoc and D-59 — so a row on this page can be one that does not exist
  yet, and `[]` is a real answer meaning *medications, nothing due today*. When
  something did come back, the name and
  the dose line are left exactly as they are: those are the user's own and
  nothing in `Kati.Health` translates anything — screen 69's rule for a shelved
  book, applied to a prescription. Only the digits inside them move.
  """
  @spec doses() :: [map()]
  def doses do
    stored = Medication.doses()

    if stored == Medication.drawn_doses() do
      @doses
    else
      Enum.map(stored, fn dose ->
        # `:id` and screen 112's three tap tags travel with the row.
        #
        # They used to be dropped, and `Kati.Screens.Medication`'s moduledoc
        # spelled out the consequence: *its chips have no row in them to act
        # on, and they come through `handle_tap/2` here to reach
        # `next_undecided/1`* — so pressing **خورده شد** on the 21:00 dose
        # recorded whichever dose the day had not decided about yet, which on
        # any day with more than one is a different tablet. The same moduledoc
        # named the fix: *wiring them properly means giving 115's own list ids,
        # which is 115's change.* This is that change.
        #
        # The tags are TAKEN from 112's row rather than rebuilt from its id, and
        # D-59 is why. They used to be `Medication.tags(dose.id)` here, which
        # was a claim that two builders agree; carrying them is the same claim
        # by construction, and it is the only version that works at all now
        # that a dose can be DERIVED from a medication's `times` and have no id
        # to rebuild from. `Medication.tags/1` guards on `is_binary(key)`, so
        # the first derived row on a Persian device was a FunctionClauseError
        # inside `mount/3` — screen 115 failing to open for anybody with a
        # medication.
        #
        # `:time` is Persian digits for the eye and `:due_at` is the ASCII
        # clock the write stores, which is why both travel. One field would put
        # ۰۸:۰۰ into `health_doses.due_at`, where neither
        # `Kati.Health.Dose.resolve/2` nor `:for_day`'s sort can read it —
        # rule 10 of this file's own type rules, arriving in the store.
        #
        # `:medication_id` and `:due_on` travel for the same reason: this page
        # can materialise a dose now, and a write has to carry the row it was
        # drawn for. The drawing's three rows keep none of these — `@doses`
        # above has no `:id` key — so a page drawing the fixture still reaches
        # `next_undecided/1`, which is the honest answer when nothing is stored.
        dose
        |> Map.take([:id, :medication_id, :due_on, :due_at, :tap, :taken, :skip])
        |> Map.merge(%{
          time: persian(dose.time),
          name: dose.name,
          line: persian(dose.line),
          state: dose.state
        })
      end)
    end
  end

  @doc """
  The date under the title, in the Solar Hijri calendar.

  `Kati.Calendar.Shamsi.format/2` has no style that drops the year, and the
  board's line does, so the weekday and the short form are composed from the
  module's own parts rather than a fourth style being invented for one screen.

  With nothing stored it is the drawing's date. Screen 112's reasoning, in as
  many words: *dating the drawing's doses with the device's today would put a
  real date on a fixture* — and the fixture's یکشنبه ۲۵ مرداد is the day its
  doses and its readings both belong to.
  """
  @spec subtitle() :: String.t()
  def subtitle do
    if Weight.latest() == WeightSample.latest() do
      @labels.date
    else
      today = Kati.Time.today()
      Shamsi.weekday_name(Shamsi.weekday_index(today)) <> " " <> Shamsi.format(today, :short)
    end
  end

  @doc """
  The three range segments, carrying 109's tags under Persian labels.

  The tags are `Kati.Screens.Weight.ranges/0`'s, so the two pages mean the same
  thing by *month*; only the labels are this file's.
  """
  @spec ranges() :: [{String.t(), atom()}]
  def ranges do
    Enum.map(Weight.ranges(), fn {_english, tag} -> {Map.fetch!(@ranges, tag), tag} end)
  end

  @doc false
  @spec content(map()) :: map()
  def content(assigns) do
    reading = assigns.latest
    subtitle = assigns.subtitle
    doses = assigns.doses
    range = assigns.range
    eyebrow = @labels.doses

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {Kati.Screens.HealthFa.chrome()}
        {Kati.Screens.HealthFa.title(subtitle)}
        {Kati.Screens.HealthFa.hero(reading)}
        {Kati.Screens.HealthFa.range_row(range)}
        {Kati.Screens.HealthFa.chart(range)}
        {Kati.Screens.Fa.eyebrow(eyebrow)}
        {Kati.Screens.HealthFa.dose_list(doses)}
        {Kati.Screens.HealthFa.note()}
      </Column>
    </Scroll>
    """
  end

  @doc """
  The back pill and the add disc.

  `arrow_forward_ios`, because back is the way the reader came from and in
  Persian that is the right edge — screens 58, 59, 69 and 76 all record it as
  the commonest RTL bug there is. `Kati.Screens.BookDetailFa.chrome/0` is this
  pill already but its label is frozen at کتابخانه, so the geometry is repeated
  and the label is not.
  """
  @spec chrome() :: map()
  def chrome do
    back = @labels.back

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Row
          height={44}
          corner_radius={22}
          background={Palette.card()}
          shadow={Theme.shadow_button()}
          padding_left={12}
          padding_right={16}
          align="center"
          on_tap={{self(), :back}}
        >
          {Kati.UI.symbol("arrow_forward_ios", size: 17)}
          <Spacer size={6} />
          {BookDetailFa.fa(back, 13.5, :on_surface, weight: "semibold")}
        </Row>
        <Spacer weight={1.0} />
        {Kati.Screens.HealthFa.add_disc()}
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc """
  The 44pt disc that logs a reading, in ink rather than card white.

  `Kati.Screens.Fa.disc/2`'s component and metrics — `Kati.Components.MishkaActionIcon`,
  44 at `:circle`, a 21pt glyph — with the one thing that differs on this frame:
  the fill. Every other Persian header disc is a floating chrome control and
  carries `Kati.Theme.shadow_button/0` with it; this one is the page's call to
  action, so it takes `ink_fill` and `on_ink` (the pair that inverts in dark)
  and no shadow, which is what the board draws.
  """
  @spec add_disc() :: map()
  def add_disc do
    MishkaActionIcon.action_icon(
      %{
        size: 44,
        shape: :circle,
        variant: :filled,
        background: Palette.ink_fill(),
        on_tap: :add
      },
      [UI.symbol("add", size: 21, color: Palette.on_ink())]
    )
  end

  @doc "The heading and the Solar Hijri date under it."
  @spec title(String.t()) :: map()
  def title(subtitle) do
    heading = @labels.title

    ~MOB"""
    <Column fill_width={true}>
      {BookDetailFa.fa(heading, 25, :on_surface, weight: "bold")}
      <Spacer size={6} />
      {BookDetailFa.fa(subtitle, 12.5, Palette.muted())}
      <Spacer size={20} />
    </Column>
    """
  end

  @doc """
  The hero card: the latest figure, its unit beside it, and the change as a pill.

  109 sets the change on a line of its own under the figure and follows it with
  the arc since the first reading; this frame lifts it into a washed pill at the
  trailing end of the same row and drops the arc. The unit still sits on the
  baseline of the numeral rather than under it, which is 109's rule and screen
  111's: *the unit sits inside the numeral rather than as a separate label, so
  the hero reads as one value.*

  ## There is no nested `Column` here, and there was, twice

  The label, the figure and the pill were once a `Column` holding the first two
  and the pill beside it. On a Pixel 9a that card lost both ends of itself: the
  32pt figure drew `۷۶…`, ellipsised after two glyphs with two thirds of the
  card empty beside it, and the pill did not draw at all. Putting `weight={1.0}`
  on the `Column` did not fix it — it inverted it, and the pill took the whole
  width while the label, the figure and the unit vanished. Nothing was ever
  wrong in the tree: `Kati.ScreenEmptyDatabaseTest` finds every one of those
  strings in it on both attempts.

  What works is `Kati.Screens.Weight.hero/1`'s own shape — 109, the screen this
  mirrors — which has no nested container at all: the label is a sibling of the
  row, and the row is figure, unit, a weighted `Spacer`, then the pill. Two
  containers competing for one row's width is the thing to avoid, and the board
  draws the label on its own line anyway.

  Only visible on a device. The sweeps assert what is in the tree, and every
  string was in it every time.
  """
  @spec hero(map()) :: map()
  def hero(reading) do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        padding={17}
        shadow={Theme.shadow_card()}
      >
        {BookDetailFa.fa(reading.label, 11, Palette.eyebrow(), weight: "semibold")}
        <Spacer size={8} />
        <Row fill_width={true} align="bottom">
          {Kati.Screens.HealthFa.figure(reading.figure)}
          <Spacer size={6} />
          {BookDetailFa.fa(reading.unit, 14, Palette.sub())}
          <Spacer weight={1.0} />
          {Kati.Screens.HealthFa.change_pill(reading)}
        </Row>
      </Column>
      <Spacer size={14} />
    </Column>
    """
  end

  @doc """
  The 32pt numeral, written out rather than passed to the shared Persian `Text`.

  `Kati.Screens.BookDetailFa.fa/4` fixes `line_height` at 1.4, which this
  figure does not want, so the `Text` is spelled here.

  ## The board's −0.03 tracking is not applied, and a device is why

  It was, and this numeral drew `۷۶…` — the separator and the zero ellipsised
  away, on a card two thirds empty. With `max_lines` removed to see what was
  happening it wrapped instead, `۷۶٫` over `۰`, which says the `Text` was
  measured at three glyphs rather than four. Three probes on a Pixel 9a
  separate the cause cleanly: `۷۶٫۰` at 32 in `fa` renders whole; at 32 with
  `font_weight="medium"` it renders whole; with `letter_spacing` set — at
  either weight — it loses its last glyph. `K-10 letter-spacing-em` applies
  tracking as `.em`, and an em value on this font measures short.

  The app already had the rule and this line had simply not been held to it.
  `Kati.Screens.Fa.eyebrow/1` states it — *no tracking, which the drawings set
  to 0 on every Persian line* — and `Kati.Screens.WeekImage.page_fa/0` gives
  the typographic reason: tracking Arabic script pulls the joins apart. The
  board's −0.03 is a hair under a pixel per glyph at this size; the last glyph
  of the number is the whole hero.

  `Kati.Screens.DataSourcesFa` is the one Persian line still carrying tracking
  — screen 82's pairing code at +0.14 — and it is a different case in two ways:
  the value is positive, so it widens rather than narrows, and the `Text` is
  centred and therefore fills its width rather than hugging.
  """
  @spec figure(String.t()) :: map()
  def figure(text) do
    ~MOB"""
    <Text
      text={text}
      font_family="fa"
      text_size={32}
      font_weight="medium"
      text_color={:on_surface}
      max_lines={1}
    />
    """
  end

  @doc """
  The change, as a washed pill with an arrow through it.

  ## `Kati.Components.MishkaPill`, and not a hand-rolled `Row`

  This was a `Row` with a `height`, a `corner_radius` and two side paddings —
  the drawing's geometry, spelled directly — and on device it swallowed the
  whole hero. `MobBridge.kt` fills width for any container whose `width` is not
  a number (its own comment at `MobBridge.kt:2673` says so about `Text`; the
  containers read the same prop the same way), so a bare `Row` beside a
  weighted `Column` takes everything and leaves the figure and its label with
  nothing. It did exactly that: the card drew a full-width green pill and no
  weight at all.

  `MishkaPill` is the component every other pill in the app goes through —
  `Kati.UI.SettingsList.status_pill/3` is the same shape, a glyph then a label
  handed in as content — and it hugs. Its own `Row` carries no `align`, which
  is `CenterVertically` (`rowAlignProp`), so `align: :center` here is the pill
  box's alignment and the content stays centred either way.

  Moving to it was not enough on its own, and the second half is the reason the
  first half looked like it had not worked. A pill hugs its CONTENT, and the
  content here is `Kati.Screens.BookDetailFa.fa/4`, which used to default to
  `align: "start"` and so always wrote a `text_align`. `MobText` reads a
  present `text_align` as *this text is wider than its glyphs* and applies
  `fillMaxWidth()` — so the label filled and the pill dutifully hugged a
  full-width label. That default is `nil` now, for the reason `fa/4`'s own doc
  gives, and both this label and the unit beside the figure hug because of it.

  The glyph and the two text colours are 109's two lines exactly —
  `arrow_downward` in `green_text` for a loss and `arrow_drop_up` in `gold_text`
  for a gain — so the mirror cannot come to a different opinion about which
  direction is which. Only the ground is this frame's: the board washes the
  down pill in `green_wash`, and the up pill takes `cream`, which is the ground
  the palette pairs gold with everywhere else.
  """
  @spec change_pill(map()) :: map()
  def change_pill(reading) do
    down? = reading.direction == :down
    icon = if down?, do: "arrow_downward", else: "arrow_drop_up"
    colour = if down?, do: Palette.green_text(), else: Palette.gold_text()
    ground = if down?, do: Palette.green_wash(), else: Palette.cream()

    Kati.Components.MishkaPill.pill(
      %{
        background: ground,
        corner_radius: 13,
        height: 26,
        padding: 0,
        padding_left: 10,
        padding_right: 10,
        align: :center
      },
      [
        Kati.UI.symbol(icon, size: 15, color: colour, fill: true),
        ~MOB"<Spacer size={5} />",
        BookDetailFa.fa(reading.change, 11.5, colour)
      ]
    )
  end

  @doc """
  The three ranges, hand-rolled rather than `Kati.UI.Segmented`.

  `Kati.UI.Segmented` paints its own label, so a Persian string handed to it is
  a row of empty boxes rather than a fallback — `Kati.Screens.Fa`'s moduledoc
  checked the font and names the missing content slot as an upstream ask.
  Screen 72 has already hand-rolled the control at 69's geometry, so this calls
  `Kati.Screens.LogProgressFa.segments/2` rather than typing a third copy of
  the same well, the same 34pt segments and the same 1pt shadow. 72 sets its
  label at 12.5 where this board sets 12, which is not half a point's worth of
  a second control.
  """
  @spec range_row(atom()) :: map()
  def range_row(selected) do
    segments = Kati.Screens.HealthFa.ranges()

    ~MOB"""
    <Column fill_width={true}>
      {LogProgressFa.segments(segments, selected)}
      <Spacer size={16} />
    </Column>
    """
  end

  @doc """
  The chart card: three rules, one bar per reading, and two axis labels.

  See the moduledoc for why nothing here is reversed by hand and why the track
  is 96 rather than the board's 88. The rules are
  `Kati.Screens.WeightStates.gridlines/1`, which is where 109's chart's rules
  are written down; the `Box` stacks them behind the bars, which is the same
  thing `Kati.Screens.Pushed.chrome/2` relies on to float a back pill.

  The segment is the one the range row above the card is lighting. 115 and 109
  are the same chart, so a chip means the same thing on both boards or the
  mirror is a second opinion rather than a translation.
  """
  @spec chart(atom()) :: map()
  def chart(range) do
    {oldest, newest} = @axis
    bars = Kati.Screens.HealthFa.bars(range)
    rules = WeightStates.gridlines(Palette.mode())
    track = @track

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        padding={17}
        shadow={Theme.shadow_card()}
      >
        <Box fill_width={true} height={track}>
          {rules}
          <Row fill_width={true} height={track} align="bottom">
            {bars}
          </Row>
        </Box>
        <Spacer size={11} />
        <Row fill_width={true} align="center">
          {BookDetailFa.fa(oldest, 9.5, Palette.tertiary())}
          <Spacer weight={1.0} />
          {BookDetailFa.fa(newest, 9.5, Palette.tertiary())}
        </Row>
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  One bar per reading, oldest first, with the newest tipped in ink.

  `Kati.Screens.Weight.bars/1` supplies the fractions — for the segment this
  board is lighting, so the narrowing is 109's and not a second one — and
  `Kati.Screens.Weight.bar/1` draws all but the last, so this chart and 109's
  are the same chart and not two series that happen to agree. The last one is
  by position rather than by value: the newest reading is the newest whatever
  it weighed. An empty window leaves `last` at `-1`, which no bar's index can
  equal, and the row draws nothing rather than tipping something.
  """
  @spec bars(atom()) :: [map()]
  def bars(range) do
    fractions = Weight.bars(range)
    last = length(fractions) - 1

    fractions
    |> Enum.with_index()
    |> Enum.map(fn {fraction, index} ->
      if index == last do
        Kati.Screens.HealthFa.today_bar(fraction)
      else
        Weight.bar(fraction)
      end
    end)
    |> Enum.intersperse(~MOB"<Spacer size={3} />")
  end

  @doc """
  Today's bar, in ink.

  `Kati.Screens.Weight.bar/1`'s node with one colour changed, and the height
  through `Kati.Screens.WeightStates.bar_height/1` — which is where the
  arithmetic `bar/1` bakes in alongside its fill is already written down, floor
  of 4 included. Copying the multiplication a third time is how two charts start
  disagreeing about what a fraction is.
  """
  @spec today_bar(float()) :: map()
  def today_bar(fraction) do
    height = WeightStates.bar_height(fraction)

    ~MOB"""
    <Column weight={1.0} align="bottom">
      <Box fill_width={true} height={height} corner_radius={2} background={Palette.ink()} />
    </Column>
    """
  end

  @doc """
  Today's doses, each in its own time gutter — or the sentence a quiet day gets.

  D-59. `Kati.Screens.Medication.doses/0` gates on the medication as well as on
  the dose now, so it can answer `[]`, and `doses/0` above passes that straight
  through: `[]` is not `drawn_doses/0` and never could be, so the mapping runs
  over nothing and this list arrives empty. Left alone that drew داروهای امروز
  over an empty column, which is D-58's defect in Persian.

  The eyebrow stays and the sentence is drawn — screen 112's decision, on board
  160's argument, which 160 made in this language: *یک ردیف خالی می‌گوید چیزی
  خراب است؛ نبودن ردیف می‌گوید هنوز شروع نکرده‌اید*. Somebody with prescriptions
  has started, so the section that quietly disappeared would be the lie.

  Full width rather than inside a row's 44pt gutter: `dose_row/1` puts a clock
  time out there, which is screen 59's geometry, and a sentence about a whole
  day has no clock time to put in it. The card is `dose_card/1`'s non-due
  treatment, so it belongs to the set of rows it stands in for.
  """
  @spec dose_list([map()]) :: map()
  def dose_list([]) do
    text = @labels.nothing_due

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={18}
        padding={14}
        shadow={Theme.shadow_card()}
      >
        {Kati.Screens.BookDetailFa.fa(text, 12.5, Palette.sub(), lines: 2)}
      </Column>
    </Column>
    """
  end

  # The two verbs are drawn ONCE, against the day's first undecided dose, and
  # `Kati.Screens.Medication.undecided/1` is what picks it — the same function,
  # asked the same question, so this mirror and screen 112 cannot come to
  # disagree about which tablet the pair is about.
  #
  # Once, rather than per card, because they are tagged `mark_taken` and
  # `mark_skipped` with no row in them: two undecided doses each drawing a pair
  # gives one `accessibility_id` to two nodes, `onNodeWithTag` throws on the
  # second match, and `Kati.ScreenTapSweepTest` says so. Screen 112 draws its
  # pair once under the whole list for the same reason; 115 draws it inside the
  # one card it belongs to, which is what board 115 draws.
  def dose_list(doses) do
    verbs = Kati.Screens.Medication.undecided(doses)

    rows =
      Enum.map(doses, fn dose ->
        # Compared as whole rows rather than on a key: `undecided/1` answers
        # with an element of this very list, and the drawing's rows carry
        # neither `:tap` nor `:id` to compare on.
        Kati.Screens.HealthFa.dose_row(dose, dose == verbs)
      end)

    ~MOB"""
    <Column fill_width={true}>
      {rows}
    </Column>
    """
  end

  @doc """
  One dose: the time in a 44pt gutter, then the card.

  59's arrangement, which puts the time outside the card where
  `Kati.Screens.Medication.dose_row/1` puts it inside — the caption asks for
  59's geometry and this is the first thing that means. The gutter's weight and
  colour are `Kati.Screens.TodayFa`'s own functions, through `meal_state/1`; its
  top padding is not, because a card that pads 12 needs its time one point
  higher than 59's card that pads 11.
  """
  @spec dose_row(map()) :: map()
  def dose_row(dose, verbs? \\ false) do
    state = Kati.Screens.HealthFa.meal_state(dose.state)

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        <Column width={44} padding_top={Kati.Screens.HealthFa.gutter_top(dose.state)}>
          <Text
            text={dose.time}
            font_family="fa"
            text_size={12}
            font_weight={Kati.Screens.TodayFa.gutter_weight(state)}
            text_color={Kati.Screens.TodayFa.gutter_color(state)}
            max_lines={1}
          />
        </Column>
        <Spacer size={12} />
        <Box weight={1.0}>
          {Kati.Screens.HealthFa.dose_card(dose, verbs?)}
        </Box>
      </Row>
      <Spacer size={9} />
    </Column>
    """
  end

  @doc """
  A dose state as the meal state 59 draws it.

  `Kati.Screens.Medication`'s moduledoc says the two vocabularies are
  deliberately parallel — *taken, missed and skipped are the same three states
  as eaten, skipped and upcoming* — so the mapping is a translation between two
  domains that already agree rather than a lookup table this screen invented.
  """
  @spec meal_state(atom()) :: atom()
  def meal_state(:taken), do: :eaten
  def meal_state(:due), do: :next
  def meal_state(_missed_or_skipped), do: :skipped

  @doc "The gutter's top padding: the due card pads 14, so its time starts lower."
  @spec gutter_top(atom()) :: pos_integer()
  def gutter_top(:due), do: 17
  def gutter_top(_other), do: 14

  @doc """
  The due dose: an accent rail, the two lines, the open ring and the two verbs.

  59's `:next` meal card without the thumbnail, down to the shadow — the board's
  `.05` and `.75` are that card's two stops exactly. The action row is the
  caption's *indenting from the right*: `padding_left` is the leading edge under
  `rtl`, so 59's 15 needs no second arrangement here.
  """
  @spec dose_card(map()) :: map()
  # `:missed` takes this card too, not the settled one below it. The two verbs
  # are drawn from here and from nowhere else on screen 115 — there is no
  # page-level pair the way screen 112 has one — so a dose that reached its
  # clock time untouched had no control at all and a Persian reader could not
  # record a tablet once its minute had passed. Before D-59 no real dose could
  # reach `:missed` on this page, because nothing in `lib/` created a
  # `Kati.Health.Dose` at all; the first medication anybody adds reaches it the
  # same afternoon.
  #
  # `undecided/1` on screen 112 already draws exactly this line — `state in
  # [:due, :missed]` — and says why: *a page opened at 21:00 with an untouched
  # 14:00 tablet on it has one thing left to answer and it is that one.* One
  # question, asked the same way on both pages.
  def dose_card(dose, verbs? \\ false)

  def dose_card(%{state: state} = dose, verbs?) when state in [:due, :missed] do
    second = second_line(Kati.Screens.HealthFa.line(dose))
    rail = @rail
    verbs = Kati.Screens.HealthFa.verbs_band(dose, verbs?)

    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={18}
      padding={14}
      shadow="0 1 2 0 #0D1A1917 | 0 16 30 -18 #BF1A1917"
    >
      <Row fill_width={true} align="center">
        <Box width={3} height={rail} corner_radius={2} background={Palette.accent()} />
        <Spacer size={12} />
        <Column weight={1.0}>
          {BookDetailFa.fa(dose.name, 13, :on_surface, weight: "bold")}
          {second}
        </Column>
        <Spacer size={12} />
        {Kati.Screens.HealthFa.ring(dose.state)}
      </Row>
      {verbs}
    </Column>
    """
  end

  def dose_card(dose, _verbs?) do
    second = second_line(Kati.Screens.HealthFa.line(dose))

    ~MOB"""
    <Row
      fill_width={true}
      background={Kati.Screens.Medication.fill(dose.state)}
      shadow={Kati.Screens.HealthFa.shadow(dose.state)}
      corner_radius={18}
      padding_left={13}
      padding_right={13}
      padding_top={12}
      padding_bottom={12}
      align="center"
    >
      <Column weight={1.0}>
        {BookDetailFa.fa(dose.name, 13, Kati.Screens.HealthFa.name_colour(dose.state), weight: "semibold")}
        {second}
      </Column>
      <Spacer size={12} />
      {Kati.Screens.HealthFa.ring(dose.state)}
    </Row>
    """
  end

  # The gap and the second line, or neither — `Kati.Screens.Medication.dose_line_nodes/1`
  # in Persian, and the same rule for the same reason: a medication typed on
  # board 188 with a name and nothing else has nothing to say on this line, and
  # `Kati.Screens.BookDetailFa.title/1` is this file's own precedent for a page
  # with nothing to say under its title saying nothing. `Kati.ScreenNilTextTest`
  # cannot see the difference, because `""` is not the word `nil`.
  defp second_line(""), do: []

  defp second_line(line) do
    [~MOB"<Spacer size={4} />", BookDetailFa.fa(line, 10.5, Palette.muted())]
  end

  @doc """
  A dose's line with its state word after it, composed as 112 composes it.

  `Kati.Screens.Medication.state_line/1` rejects the empty parts and joins what
  is left with a middot, and this does the same with the Persian of the same two
  words — so the shape of the line is written once and only the vocabulary is
  mirrored.

  It appended rather than joined until D-59, which was invisible for as long as
  every dose on this page came from `@doses`. A medication saved on board 188
  with a name and nothing else has no dose line at all
  (`Kati.Health.Medication.dose_line/1` answers `""` for it), so the Persian
  card printed ` · جا افتاد` — a leading middot with nothing before it — the
  moment that dose's time passed. `dose_card/1` draws no second line for `""`.
  """
  @spec line(map()) :: String.t()
  def line(dose) do
    [dose.line, Map.get(@suffixes, dose.state)]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join(" · ")
  end

  @doc "The taken card sits flat on the settled fill; the rest lift on 109's card shadow."
  @spec shadow(atom()) :: String.t() | nil
  def shadow(:taken), do: nil
  def shadow(_other), do: Theme.shadow_card()

  @doc "A taken dose's name recedes to the settled ink; a missed one to the tertiary grey."
  @spec name_colour(atom()) :: integer()
  def name_colour(:taken), do: Palette.settled_ink()
  def name_colour(_other), do: Palette.tertiary()

  @doc """
  A dose's state ring — 59's, except for the one this frame paints red.

  Three of the four are `Kati.Screens.TodayFa.ring/1` unchanged: the sizes,
  radii, borders and glyph tints all match this board to the point, which is
  what the caption means by inheriting 59's geometry. Missed is the exception —
  `Kati.Screens.Medication.mark/1` tints it gold and draws no ring at all, and
  this board rings it in `Kati.Theme.Palette.red/0`, its `#B4553C` exactly. Same
  component and the same two numbers as its siblings, so it is a fourth ring in
  the set rather than a shape of its own.
  """
  @spec ring(atom()) :: map()
  def ring(:taken), do: TodayFa.ring(:eaten)
  def ring(:due), do: TodayFa.ring(:next)
  def ring(:skipped), do: TodayFa.ring(:skipped)

  def ring(_missed) do
    MishkaThemeIcon.theme_icon(
      %{
        variant: :subtle,
        size: 27,
        radius: 16,
        border_color: Palette.red(),
        border_width: 1.5
      },
      [UI.symbol("close", size: 16, color: Palette.red())]
    )
  end

  @doc """
  The two verbs and the gap above them, or neither.

  112 puts the pair under the whole list as two full-width buttons and answers
  *which dose* with the next one you have not decided about; this frame puts
  them in the card, which answers it by sitting there. The write is still 112's
  — see `handle_info/2` — so both pages mark a dose the same way.

  Drawn for ONE card per page, the one `Kati.Screens.Medication.undecided/1`
  picks, because the pair is tagged `mark_taken` and `mark_skipped` with no row
  in it: two cards each drawing a pair gives one `accessibility_id` to two
  nodes and `onNodeWithTag` throws on the second match.

  The 13pt gap comes with them rather than sitting in the card, so a settled
  card closes on its ring instead of on empty space.
  """
  @spec verbs_band(map(), boolean()) :: map() | []
  def verbs_band(_dose, false), do: []

  def verbs_band(dose, true) do
    assigns = %{verbs: Kati.Screens.HealthFa.actions(dose)}

    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={13} />
      {@verbs}
    </Column>
    """
  end

  @spec actions(map()) :: map()
  def actions(dose \\ %{}) do
    taken = @labels.taken
    skip = @labels.skip

    # The dose's own two tags when the row has them, and screen 115's old pair
    # when it does not — which is the drawing, whose three rows carry no id.
    #
    # The pair used to be unconditional, so both verbs named the CARD rather
    # than the dose in it and `Kati.Screens.Medication.handle_tap/2` fell
    # through to `next_undecided/1`: pressing *taken* on the 21:00 tablet
    # recorded whichever dose the day had not decided about. `doses/0` carries
    # `Medication.tags/1` now, so these are the same atoms screen 112 draws and
    # the same `decision/2` clause answers them.
    yes = Map.get(dose, :taken, :mark_taken)
    no = Map.get(dose, :skip, :mark_skipped)

    ~MOB"""
    <Row fill_width={true} align="center" padding_left={15}>
      {Kati.Screens.HealthFa.pill(taken, Palette.ink_fill(), Palette.on_ink(), yes)}
      <Spacer size={8} />
      {Kati.Screens.HealthFa.pill(skip, Palette.paper(), Palette.ink_soft(), no)}
    </Row>
    """
  end

  @doc "One 34pt action pill, at 59's geometry."
  @spec pill(String.t(), integer(), integer(), atom()) :: map()
  def pill(label, ground, colour, tag) do
    tap = {self(), tag}

    ~MOB"""
    <Row
      height={34}
      corner_radius={17}
      background={ground}
      padding_left={14}
      padding_right={14}
      align="center"
      on_tap={tap}
    >
      {BookDetailFa.fa(label, 12, colour, weight: "semibold")}
    </Row>
    """
  end

  @doc """
  The cream note, and the only wrapping paragraph on the page.

  One `Text` rather than runs, and one word changed inside it — both argued in
  the moduledoc. `Kati.UI.SettingsList.note/2` is this card in Latin and builds
  its own unstyled `Text`, which on a Persian screen is a row of empty boxes, so
  the geometry is repeated here and the string is not handed to it.
  """
  @spec note() :: map()
  def note do
    body = Kati.Screens.HealthFa.note_text()

    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={22} />
      <Row fill_width={true} background={Palette.cream()} corner_radius={20} padding={16} align="top">
        {Kati.UI.symbol("info", size: 18, color: Palette.gold_icon())}
        <Spacer size={11} />
        <Column weight={1.0}>
          <Text
            text={body}
            font_family="fa"
            text_size={12.5}
            line_height={1.85}
            text_color={Palette.cream_body()}
            max_lines={4}
          />
        </Column>
      </Row>
    </Column>
    """
  end

  def handle_info({:tap, :back}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}

  # 111 has no Persian mirror in the 127, so the disc opens the English sheet
  # rather than going nowhere — which is what `Kati.Screens.Fa.dock_tap/3` does
  # with the FAB and `Kati.Screens.BookDetailFa` does with its rating sheet.
  def handle_info({:tap, :add}, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.LogWeight)}

  def handle_info({:tap, range}, socket) when range in [:range_week, :range_month, :range_all],
    do: {:noreply, Mob.Socket.assign(socket, :range, range)}

  # The write is `Kati.Screens.Medication.handle_tap/2`'s — one dose resolved,
  # one Ash update, one rescue — and then the list is read back through this
  # screen's own reader, because 112 leaves English doses on the socket behind
  # it. Marking a dose from the mirror and marking it from 112 must be the same
  # act, and this is the only way to say that without a second copy of it.
  # `dose_<id>_taken` and `dose_<id>_skip` as well as the two old bare tags: the
  # first pair is what a real dose draws now, the second what the drawing still
  # draws. Both go to screen 112's writer, which finds the row by tag in
  # `socket.assigns.doses` — this screen's own list, in Persian, with ids.
  def handle_info({:tap, tag}, socket) when is_atom(tag) do
    if tag in [:mark_taken, :mark_skipped] or dose_verb?(socket, tag) do
      {:noreply, written} = Medication.handle_tap(tag, socket)
      {:noreply, Mob.Socket.assign(written, :doses, doses())}
    else
      {:noreply, socket}
    end
  end

  def handle_info({:tap, _tag}, socket), do: {:noreply, socket}
  def handle_info(_message, socket), do: {:noreply, socket}

  defp dose_verb?(socket, tag) do
    Enum.any?(Map.get(socket.assigns, :doses, []), fn dose ->
      Map.get(dose, :taken) == tag or Map.get(dose, :skip) == tag
    end)
  end
end
