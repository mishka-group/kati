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
    skip: "رد کن"
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
  # word: the suffix is composed the way `Kati.Screens.Medication.dose_row/1`
  # composes it, so both pages spell "missed" in one place each.
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

  def render(assigns), do: Fa.pushed_frame(content(assigns))

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

  `Kati.Screens.Medication.doses/0` answers the store and falls back to
  `drawn_doses/0`, so comparing the two is how this screen asks *did anything
  come back?* without running the query again. When something did, the name and
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
        %{
          time: persian(dose.time),
          name: dose.name,
          line: persian(dose.line),
          state: dose.state
        }
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
        {Kati.Screens.HealthFa.chart()}
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
        <Row fill_width={true} align="bottom">
          <Column>
            {BookDetailFa.fa(reading.label, 11, Palette.eyebrow(), weight: "semibold")}
            <Spacer size={8} />
            <Row align="bottom">
              {Kati.Screens.HealthFa.figure(reading.figure)}
              <Spacer size={6} />
              {BookDetailFa.fa(reading.unit, 14, Palette.sub())}
            </Row>
          </Column>
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

  `Kati.Screens.BookDetailFa.fa/4` fixes `line_height` at 1.4 and takes no
  tracking, and the board sets this one numeral at −0.03. It is the only figure
  on the page big enough for tracking to read at all.
  """
  @spec figure(String.t()) :: map()
  def figure(text) do
    ~MOB"""
    <Text
      text={text}
      font_family="fa"
      text_size={32}
      font_weight="medium"
      letter_spacing={-0.03}
      text_color={:on_surface}
      max_lines={1}
    />
    """
  end

  @doc """
  The change, as a washed pill with an arrow through it.

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

    ~MOB"""
    <Row
      height={26}
      corner_radius={13}
      background={ground}
      padding_left={10}
      padding_right={10}
      align="center"
    >
      {Kati.UI.symbol(icon, size: 15, color: colour, fill: true)}
      <Spacer size={5} />
      {BookDetailFa.fa(reading.change, 11.5, colour)}
    </Row>
    """
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
  """
  @spec chart() :: map()
  def chart do
    {oldest, newest} = @axis
    bars = Kati.Screens.HealthFa.bars()
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

  `Kati.Screens.Weight.bars/0` supplies the fractions and
  `Kati.Screens.Weight.bar/1` draws all but the last, so this chart and 109's
  are the same chart and not two series that happen to agree. The last one is
  by position rather than by value: the newest reading is the newest whatever
  it weighed.
  """
  @spec bars() :: [map()]
  def bars do
    fractions = Weight.bars()
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

  @doc "Today's doses, each in its own time gutter."
  @spec dose_list([map()]) :: map()
  def dose_list(doses) do
    rows = Enum.map(doses, &Kati.Screens.HealthFa.dose_row/1)

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
  def dose_row(dose) do
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
          {Kati.Screens.HealthFa.dose_card(dose)}
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
  def dose_card(%{state: :due} = dose) do
    line = Kati.Screens.HealthFa.line(dose)
    rail = @rail

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
          <Spacer size={4} />
          {BookDetailFa.fa(line, 10.5, Palette.muted())}
        </Column>
        <Spacer size={12} />
        {Kati.Screens.HealthFa.ring(:due)}
      </Row>
      <Spacer size={13} />
      {Kati.Screens.HealthFa.actions()}
    </Column>
    """
  end

  def dose_card(dose) do
    line = Kati.Screens.HealthFa.line(dose)

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
        <Spacer size={4} />
        {BookDetailFa.fa(line, 10.5, Palette.muted())}
      </Column>
      <Spacer size={12} />
      {Kati.Screens.HealthFa.ring(dose.state)}
    </Row>
    """
  end

  @doc """
  A dose's line with its state word after it, composed as 112 composes it.

  `Kati.Screens.Medication.dose_row/1` appends `Kati.Health.Dose.state_suffix/1`
  behind a middot, and this appends the Persian of the same two words behind the
  same middot — so the shape of the line is written once and only the vocabulary
  is mirrored.
  """
  @spec line(map()) :: String.t()
  def line(dose) do
    case Map.get(@suffixes, dose.state) do
      nil -> dose.line
      suffix -> dose.line <> " · " <> suffix
    end
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
  The two verbs a dose takes, inside the card that is due.

  112 puts them under the whole list as two full-width buttons and answers
  *which dose* with the next one you have not decided about; this frame puts
  them in the card, which answers it by sitting there. The write is still 112's
  — see `handle_info/2` — so both pages mark a dose the same way.
  """
  @spec actions() :: map()
  def actions do
    taken = @labels.taken
    skip = @labels.skip

    ~MOB"""
    <Row fill_width={true} align="center" padding_left={15}>
      {Kati.Screens.HealthFa.pill(taken, Palette.ink_fill(), Palette.on_ink(), :mark_taken)}
      <Spacer size={8} />
      {Kati.Screens.HealthFa.pill(skip, Palette.paper(), Palette.ink_soft(), :mark_skipped)}
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
  def handle_info({:tap, tag}, socket) when tag in [:mark_taken, :mark_skipped] do
    {:noreply, written} = Medication.handle_tap(tag, socket)
    {:noreply, Mob.Socket.assign(written, :doses, doses())}
  end

  def handle_info({:tap, _tag}, socket), do: {:noreply, socket}
  def handle_info(_message, socket), do: {:noreply, socket}
end
