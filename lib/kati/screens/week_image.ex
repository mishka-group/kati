defmodule Kati.Screens.WeekImage do
  @moduledoc """
  Screen 121 — the week as one page, pushed under Plans.

  Built to `.scratch/design/pending/121.html`. The caption states what this is
  for: *the recommended replacement for a PDF that has no implementation path.
  Paper and ink only, legible at arm's length, and the one thing a page can do
  that the app screen cannot: put a meal's name in the cell.*

  So this screen is not a second meal matrix. It is screen 44's week printed —
  the same plan, the same five slots, the same seven days — with every decision
  reversed that a screen makes because it is a screen:

    * **Cells carry names, not state.** 44's own moduledoc says why it cannot:
      *"too narrow for names, so cells carry state only and the tapped day lists
      underneath"*. A page has no tapped day and no list underneath, so the name
      has to be in the cell or it is nowhere. That buys the width by spending
      the pip, the row's clock time and the whole day list below.
    * **There is no today.** 44 inks one column because it is now.
      `Kati.Meals.MealPlanSlot` is explicit that today is a fact about the
      calendar rather than about the plan, and a page has left the calendar the
      moment it is saved. The `Today` key is gone from the legend and `Approx`
      has its place.
    * **Free slots stay outlined** so a gap reads as a choice rather than as a
      cell someone forgot to fill, and the `~` mark rides along, because an
      approximate plan printed as exact is the same lie on paper.
    * **The Kati mark sits in the footer beside the legend**, since a fridge
      page is the most likely thing anyone else sees. It is `Kati` in the mono
      face on both pages: a wordmark is not translated, which is the rule
      `Kati.Screens.AlbumDetailFa` records for the Latin word on an album cover.

  ## The Persian page restarts the week — mirroring it would not be enough

  The frame's own note says it: *mirroring alone would put Monday on the right
  and still be wrong.* Two separate things have to happen, and this file keeps
  them in two separate functions so that neither can be mistaken for the other:

    * `restart_at_saturday/1` is the **calendar** fact. The same seven cells,
      rotated so that Saturday leads, which is the correction screen 60 makes —
      `Kati.Fa.SampleWeek`'s moduledoc states it as *a property of the calendar*
      and that is where the seven Persian day initials come from here.
    * `order/2` is the **rendering** fact, and it is the ugly one. This is the
      only file in the app that reverses a row by hand.

  ## Why the second page is mirrored by hand, which nothing else here does

  Every Persian screen in the app declares `layout_direction="rtl"` and then
  reverses nothing: `Kati.Screens.Fa`'s frame puts the prop on the root and the
  bridge does the rest. It cannot work here. Fence `K-12 rtl-root`
  (`android/app/src/main/java/com/example/kati/MainActivity.kt`) reads
  `layout_direction` from the **root node only** — `s.node?.let { root -> …
  root.props["layout_direction"] }` — and provides one `LocalLayoutDirection`
  for the whole tree. This screen's root is `Kati.Screens.Pushed`'s frame, and
  it is left-to-right because the screen *is* English: an English back pill, an
  English title, and one Persian specimen inside it. A nested `rtl` Box would
  be read by nothing at all.

  So `order/2` reverses the children of the four rows that make up a page — the
  head, the day initials, each meal row and the footer — and every mirrored
  detail falls out of that one list: the label column lands at the right, the
  swatch lands to the right of its key, the Kati mark lands at the left. Where a
  `Text` has to be told which way it is set, `row_label/2` passes `right`
  instead of `start`; nothing else on the page is direction-aware.

  The honest way to read this is that `order/2` is a **workaround with a
  ticket**: the day `layout_direction` is honoured on any node rather than only
  on the root, both calls collapse to `order(children, :ltr)` and the Persian
  page is drawn by the same eight functions as the English one, unreversed.

  ## What comes from screen 44 and screen 60, and why it is read rather than typed

  The two pages must not be able to disagree with the app they print, so
  everything either of them says twice is read from one place:

    * `Kati.Screens.MealPlan.title/1` draws the screen's own heading — 28pt
      bold over a mono line — because it is the same heading recipe, and 44 is
      the screen this varies.
    * `Kati.Meals.SamplePlan.title/0` names the plan, and the five row labels
      are `matrix/0`'s names. Print a week called something other than what 44
      calls it and the page is about a different plan.
    * `Kati.Fa.SampleWeek.days/0`, `rows/0` and `legend/0` supply the Persian
      day initials, the five Persian slot names and two of the three Persian
      legend words, so this page and screen 60 cannot disagree about what a row
      is called or which end of the week a Saturday is.
    * `Kati.UI.SettingsList.chrome/1` reserves the floating pill's height and
      `note/2` draws the dashed footnote.

  What is deliberately **not** reused is `Kati.Screens.MealPlan.matrix/1` and
  everything under it. 44's cell is a 37pt square holding a pip; this one is a
  34pt tile holding a word, its label column is 52 rather than 62, its card is
  radius 16 rather than 22, and its legend swatch is a 9pt square cut from the
  cell rather than a 7pt dot. None of that is the same drawing, and a shared
  builder with a flag for each would be two drawings wearing one coat.

  ## Where the week's cells come from, and why the fixture is bilingual

  `week/0` is one week, Monday first, written once. The Persian page is that
  same list rotated — which is checkable against the drawing, and it checks:
  Saturday's `Steak` leads the Persian dinner row as استیک, Sunday's `Dal ~`
  falls in the second column as دال ~, and every one of the thirty-five cells
  lands where the artboard prints it.

  A cell names a dish rather than a string, and the two dish tables give that
  dish its name on each page. **On a device there would be one name, not two.**
  A real cell points at a `Kati.Meals.Recipe` through
  `Kati.Meals.MealPlanSlot`, and a recipe title is the user's own text —
  `Kati.Screens.AlbumDetailFa`'s rule, that nothing in Kati translates what a
  user typed. The fixture carries both languages only because the artboard
  prints both languages, and the day this reads a stored plan the Persian page
  will print the same recipe titles the English one does.

  ## Where this diverges from the drawing

    * **The card's head row is `align="bottom"`, not baseline.** The drawing
      sets `align-items:baseline` on a 16pt title beside a 10pt dateline;
      `rowAlignProp` (`MobBridge.kt`) offers top, bottom and centre and nothing
      else. Bottom is the closest of the three — it lands the small line about a
      point below its drawn baseline, where centre would lift it by two.
    * **Both dashed frames are solid.** `Modifier.border` takes no dash
      pattern, which `Kati.UI.SettingsList.note/2` and screen 60 both record.
      The 1.5pt weight and the 16% alpha are the drawing's, so the line has the
      right weight and the wrong rhythm.
    * **The bold runs inside both notes are dropped.** `Kati.UI.rich_text/1`
      has the finding: `MobText` takes one `color`, one `fontWeight` and one
      `fontFamily`, and there is no `AnnotatedString` anywhere in the bridge. A
      paragraph is one `Text` or it does not wrap, so the emphasis goes.
    * **`Kati.UI.SettingsList.note/2` pads 16 where the drawing pads 15, and
      sets its glyph at 18 where the drawing sets 17.** Two points of a shared
      component against two points of a screen-local copy of it; the component
      wins, and the note is the same object it is on thirty-two other screens.
    * **The mono heading gap is 5, not 6.** `Kati.Screens.MealPlan.title/1` is
      44's spacing, and one point is not worth a second title builder.

  ## Two type rules, both forced by the fonts that ship

  `Kati.Screens.Fa`'s moduledoc has both findings, and this screen meets them
  in one place each rather than throughout, because only one of its two pages
  is Persian:

    * Every Persian `Text` carries `font_family="fa"`. `kati_sans_400.ttf`
      holds no code point in U+0600–U+06FF, so a Persian label without it is a
      row of empty boxes rather than a fallback.
    * The Persian dateline is Persian **digits**, which `kati_mono.ttf` does not
      carry either, so it is set in `fa` at the drawing's size and colour. The
      face is wrong and the glyphs are right, which is the better half of an
      unwinnable trade.

  The drawing asks for no chip and no segmented control — 44's Week / Day / Shop
  strip is a screen's control and a page has nothing to switch — which is
  fortunate, because the Persian page could not have used ours. `Kati.UI.chip/2`
  builds `Text(label, 12, ink, max_lines: 1)` and `Kati.UI.Segmented.plain/2`
  builds its own `Text` at 12.5, neither with a `font_family`, so a Persian
  label handed to either is not degraded but absent. That is the blocker
  `Kati.Screens.Fa` records against the whole vendored set, and the reason
  screens 69 and 76 hand-roll what they cannot pass a face to.

  No dock on a pushed screen, so the frame closes at 40 rather than 132.
  """
  use Kati.Screens.Pushed, back: "Plans"

  alias Kati.Components.MishkaSeparator
  alias Kati.Fa.SampleWeek
  alias Kati.Meals.SamplePlan
  alias Kati.Screens.MealPlan
  alias Kati.Theme
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  # One week, Monday first, exactly as the artboard prints the English page. A
  # cell is a dish, `{dish, :approx}` a dish the plan is not sure of, and `nil`
  # a slot the plan leaves open.
  @week [
    [:oats, :oats, :oats, :oats, :oats, :eggs, :eggs],
    [:yoghurt, :yoghurt, nil, :yoghurt, nil, :apple, :apple],
    [:chicken, :chicken, :dal, :chicken, {:dal, :approx}, :soup, :soup],
    [:apple, :apple, :apple, :apple, nil, nil, :apple],
    [:salmon, {:dal, :approx}, :salmon, :cod, :salmon, :steak, {:dal, :approx}]
  ]

  @dishes_en %{
    apple: "Apple",
    chicken: "Chicken",
    cod: "Cod",
    dal: "Dal",
    eggs: "Eggs",
    oats: "Oats",
    salmon: "Salmon",
    soup: "Soup",
    steak: "Steak",
    yoghurt: "Yoghurt"
  }

  @dishes_fa %{
    apple: "سیب",
    chicken: "مرغ",
    cod: "کاد",
    dal: "دال",
    eggs: "تخم‌مرغ",
    oats: "جو",
    salmon: "سالمون",
    soup: "سوپ",
    steak: "استیک",
    yoghurt: "ماست"
  }

  @impl true
  def load(socket) do
    Mob.Socket.assign(socket, :pages, %{en: page_en(), fa: page_fa()})
  end

  @doc false
  @spec content(map()) :: map()
  def content(assigns) do
    pages = assigns.pages

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {SettingsList.chrome(nil)}
        {MealPlan.title(Kati.Screens.WeekImage.heading())}
        {Kati.Screens.WeekImage.page(pages.en)}
        {Kati.Screens.WeekImage.save_button()}
        {Kati.Screens.WeekImage.rtl_eyebrow()}
        {Kati.Screens.WeekImage.page(pages.fa)}
        {Kati.Screens.WeekImage.restart_note()}
        {Kati.Screens.WeekImage.page_note()}
      </Column>
    </Scroll>
    """
  end

  @doc """
  The screen's own heading, in the shape `Kati.Screens.MealPlan.title/1` takes.

  A map rather than two arguments because that is 44's signature, and 44's
  builder is what draws it: the same 28pt bold title over the same mono line in
  the same `muted`, which is the recipe every pushed screen in this family
  opens with. The mono line is stored already upper-cased, since it is a fixed
  mark on this one screen rather than a label that is also read as a sentence
  somewhere else.
  """
  @spec heading() :: map()
  def heading, do: %{title: "The week as an image", subtitle: "ONE PAGE, FRIDGE-SIZED"}

  @doc """
  The English page: the plan as screen 44 knows it, printed Monday first.

  The plan's name and the five row labels are read from
  `Kati.Meals.SamplePlan` rather than typed, so a page and the matrix it was
  printed from cannot end up describing different weeks.

  The day initials are the one thing here that 44's fixture cannot supply.
  `Kati.Meals.SamplePlan.columns/0` is `M T W T F S S`, which is all a 37pt
  cell can carry; this page has three letters of room and needs them, because a
  bare `T` on a fridge is not a day.
  """
  @spec page_en() :: map()
  def page_en do
    %{
      dir: :ltr,
      face: "sans",
      title: SamplePlan.title(),
      title_size: 16,
      title_tracking: -0.02,
      dateline: "WEEK OF 17 AUG",
      dateline_face: "mono",
      dateline_tracking: 0.08,
      days: ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"],
      days_face: "mono",
      days_size: 8.5,
      days_weight: nil,
      days_tracking: 0.06,
      rows: rows(labels(SamplePlan.matrix(), :name), @week, @dishes_en),
      legend: [{:planned, "PLANNED"}, {:free, "FREE"}, {:approx, "APPROX"}],
      legend_face: "mono",
      legend_size: 8.5,
      legend_tracking: 0.06,
      mark: "Kati"
    }
  end

  @doc """
  The Persian page: the same week, restarted at شنبه and set in Vazirmatn.

  Everything that is a *word* here belongs to screen 60 — the plan's name, the
  five slot names, the seven day initials, and two of the three legend keys —
  so the two Persian weeks in the app cannot disagree about any of them. تقریبی
  is this page's own, because 60 has no `~` to gloss: an approximation is
  something only a printed plan has to admit to.

  Three type values differ from the English page, and all three are the
  drawing's rather than a preference. The two scripts do not measure the same
  at the same point size: a lone Persian initial is a letterform with its dots,
  so ش needs 9.5 where `MON` reads at 8.5, and the title's ascenders and
  descenders are taller, so کاهش وزن ۳ holds the head row's height at 15 where
  `Cutting v3` needs 16. Every `letter_spacing` is 0, because tracking Arabic
  script pulls the joins apart — the rule `Kati.Screens.Fa.eyebrow/1` states
  for the same reason.
  """
  @spec page_fa() :: map()
  def page_fa do
    fa_legend = Map.new(SampleWeek.legend())

    %{
      dir: :rtl,
      face: "fa",
      title: SampleWeek.plan().title,
      title_size: 15,
      title_tracking: 0,
      dateline: "هفته ۲۶ مرداد",
      # `fa`, not `mono`, for the dateline and nothing else on this page: the
      # drawing sets it in DM Mono and `kati_mono.ttf` carries none of
      # U+06F0–U+06F9, so ۲۶ would be two empty boxes. See the moduledoc.
      dateline_face: "fa",
      dateline_tracking: 0,
      days: SampleWeek.days(),
      days_face: "fa",
      days_size: 9.5,
      days_weight: "semibold",
      days_tracking: 0,
      rows:
        rows(
          labels(SampleWeek.rows(), :label),
          Enum.map(@week, &restart_at_saturday/1),
          @dishes_fa
        ),
      legend: [
        {:planned, fa_legend.planned},
        {:free, fa_legend.open},
        {:approx, "تقریبی"}
      ],
      legend_face: "fa",
      legend_size: 9,
      legend_tracking: 0,
      mark: "Kati"
    }
  end

  @doc """
  The week both pages print, Monday first.

  One list, printed twice, which is the whole claim the screen makes: a fridge
  page that disagreed with the app about which evening is free would be a bug
  in the page. The values are the artboard's own — five slots of seven cells,
  and `Kati.Meals.SamplePlan.matrix/0`'s states are deliberately not consulted,
  because 44's fixture leaves Sunday's afternoon snack open where this drawing
  leaves Saturday's. The drawing is what this file reproduces; reconciling the
  two is `Kati.Meals.SamplePlan`'s to do once a stored plan feeds both.
  """
  @spec week() :: [[atom() | {atom(), :approx} | nil]]
  def week, do: @week

  @doc """
  Seven cells, rotated so the week begins on Saturday.

  A *calendar* operation, and the reason it is not a mirror: reversing the row
  would run Sunday backwards to Monday, which is a week no one has. Saturday
  through Friday is the sequence, and `order/2` afterwards decides which end of
  the page it starts from. `Kati.Fa.SampleWeek` states the same split for the
  in-app matrix on screen 60, and holds the day initials this rotation lines up
  with.

  The split is at five because Saturday is the sixth day of a Monday-first
  week: the two days that trail it lead the Persian one.
  """
  @spec restart_at_saturday([term()]) :: [term()]
  def restart_at_saturday(cells) do
    {head, tail} = Enum.split(cells, 5)
    tail ++ head
  end

  @doc """
  The children of one row, in the order this page has to emit them.

  The single hand-mirroring in the app, and it is here because the bridge gives
  no alternative: fence `K-12 rtl-root` reads `layout_direction` off the **root
  node** and this screen's root is an English pushed frame. Reversing the
  children of each row is what a right-to-left container would have done for
  free — the label column moves to the right end, the swatch moves to the right
  of its key, the Kati mark moves to the left — and doing it in one function
  means the four rows of a page cannot fall out of step with each other.

  It is not a translation of the drawing, it is a substitute for a container
  attribute, and it should be deleted rather than extended: see the moduledoc.
  """
  @spec order([map()], :ltr | :rtl) :: [map()]
  def order(children, :rtl), do: Enum.reverse(children)
  def order(children, _ltr), do: children

  @doc """
  One page: a card, the head, seven day initials, five rows and the footer.

  Both pages are this function. Everything either of them does differently is a
  value in the map it is handed, so the only structural difference between the
  English page and the Persian one is which way `order/2` lays each row out.

  ## Why the whole card caps at 1.0 when nothing around it does

  `max_font_scale` (fence `K-29`) clamps the `LocalDensity` font scale for a
  subtree and leaves `density` alone, so a capped card keeps its own padding
  and radii. The rule for where it goes is `Kati.Screens.Calendar.day_strip/1`'s
  — *content grows, chrome whose size carries structure caps instead* — and a
  page is the case that rule does not quite reach, because the card is neither.
  It is a **picture of a document**: 8.5pt in a 34pt cell is a measurement on
  paper, not a phone's idea of small text, and the reader's system font size is
  a setting about this app's interface rather than about the size of a page
  they are going to print and stick on a fridge. Left uncapped, the first thing
  a larger scale does is ellipsise the meal names, which is the one thing this
  page exists to carry.

  Everything outside the card — the screen title, the button, the eyebrow and
  both notes — grows to the full 235%.
  """
  @spec page(map()) :: map()
  def page(p) do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        max_font_scale={1.0}
        background={Palette.card()}
        corner_radius={16}
        shadow={Theme.shadow_card_soft()}
        padding_left={13}
        padding_right={13}
        padding_top={15}
        padding_bottom={15}
      >
        {Kati.Screens.WeekImage.head_row(p)}
        {Kati.Screens.WeekImage.day_head_row(p)}
        {Enum.map(p.rows, fn row -> Kati.Screens.WeekImage.meal_row(row, p) end)}
        {Kati.Screens.WeekImage.footer(p)}
      </Column>
      <Spacer size={14} />
    </Column>
    """
  end

  @doc """
  The plan's name at one end of the card, the week it covers at the other.

  `align="bottom"` stands in for the drawing's `align-items:baseline`, which is
  the nearest of the three verticals `rowAlignProp` offers — see the moduledoc.
  The weighted `Spacer` between the two is what makes this a space-between row,
  and it is why `order/2` can mirror the pair without any alignment prop
  changing: a spring reversed is still a spring.
  """
  @spec head_row(map()) :: map()
  def head_row(p) do
    title =
      ~MOB"""
      <Text
        text={p.title}
        font_family={p.face}
        text_size={p.title_size}
        font_weight="bold"
        letter_spacing={p.title_tracking}
        text_color={:on_surface}
        max_lines={1}
      />
      """

    dateline =
      ~MOB"""
      <Text
        text={p.dateline}
        font_family={p.dateline_face}
        text_size={10}
        letter_spacing={p.dateline_tracking}
        text_color={Palette.sub()}
        max_lines={1}
      />
      """

    ends = Kati.Screens.WeekImage.order([title, Kati.Screens.WeekImage.spring(), dateline], p.dir)

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="bottom" padding_left={2} padding_right={2}>
        {ends}
      </Row>
      <Spacer size={14} />
    </Column>
    """
  end

  @doc """
  The seven day initials, over an empty slot the width of the label column.

  The lead is a `Box` with a `width` rather than a `Spacer` with a `size`, for
  the reason `Kati.Screens.MealPlan.column_heads/1` gives: `size` sets both
  axes, and a 52pt-tall lead would give this row 52pt of height for an 8.5pt
  letter.
  """
  @spec day_head_row(map()) :: map()
  def day_head_row(p) do
    lead = ~MOB"<Box width={52} height={11} />"
    heads = Enum.map(p.days, fn day -> Kati.Screens.WeekImage.day_head(day, p) end)

    band =
      [lead | heads]
      |> Kati.Screens.WeekImage.order(p.dir)
      |> Enum.intersperse(Kati.Screens.WeekImage.gap())

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        {band}
      </Row>
      <Spacer size={5} />
    </Column>
    """
  end

  @doc """
  One day's initial, centred over its column.

  The `Text` is centred by `text_align` rather than by a pair of weighted
  spacers, because `MobText` fills the width it is given whenever an alignment
  is set — so the letter centres over exactly the column the cells below it
  occupy, at any font scale.

  The English page passes no weight, and passing none means passing `nil`,
  which reaches the wire as the **string** `"nil"` — the trap
  `Kati.UI.SettingsList.note/2` records. It is harmless in this one prop and
  only in this one: `fontWeightProp` matches six names and falls through
  everything else to Compose's Normal, which is the 400 the drawing sets on
  `MON`. The same nil in `font_family` would resolve a system typeface called
  "nil", which is why every `Text` on this screen names its face.
  """
  @spec day_head(String.t(), map()) :: map()
  def day_head(day, p) do
    ~MOB"""
    <Box weight={1.0}>
      <Text
        text={day}
        font_family={p.days_face}
        text_size={p.days_size}
        font_weight={p.days_weight}
        letter_spacing={p.days_tracking}
        text_color={Palette.sub()}
        text_align="center"
        max_lines={1}
      />
    </Box>
    """
  end

  @doc """
  One meal slot across seven days: the label, then the week.

  The 2pt gutters are interspersed between the row's children rather than
  ridden inside each cell, which is what `display:flex;gap:2px` does over eight
  children — and it is also what keeps `order/2` honest, since a gap that lived
  on a cell's leading edge would end up on the wrong side of the mirrored row.
  """
  @spec meal_row(map(), map()) :: map()
  def meal_row(row, p) do
    label = Kati.Screens.WeekImage.row_label(row.label, p)
    cells = Enum.map(row.cells, fn cell -> Kati.Screens.WeekImage.cell(cell, p) end)

    band =
      [label | cells]
      |> Kati.Screens.WeekImage.order(p.dir)
      |> Enum.intersperse(Kati.Screens.WeekImage.gap())

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        {band}
      </Row>
      <Spacer size={2} />
    </Column>
    """
  end

  @doc """
  The slot's name, in the fixed column the seven cells are measured against.

  52pt is declared rather than measured, and it is the only fixed width on the
  page: the seven cells are weighted shares of what is left, so the label
  column is what decides how wide a cell is, and the day initials above are
  measured against the same number. `text_align` is the one direction-aware
  prop on the page — `right` under the mirrored order, `start` otherwise —
  because a reversed list moves the box but not the type inside it.
  """
  @spec row_label(String.t(), map()) :: map()
  def row_label(label, p) do
    align = if p.dir == :rtl, do: "right", else: "start"

    ~MOB"""
    <Box width={52}>
      <Text
        text={label}
        font_family={p.face}
        text_size={9.5}
        font_weight="bold"
        text_color={:on_surface}
        text_align={align}
        max_lines={1}
      />
    </Box>
    """
  end

  @doc """
  One cell: a meal's name, or the outline of a slot the plan leaves open.

  `nil` is the open slot, and it is drawn as a ring with nothing in it —
  `background:transparent` with `box-shadow: inset 0 0 0 1px` in the drawing,
  which is a border by another name and solid rather than dashed here.

  The ring is `Palette.hairline_soft/0`, which is `rgba(26,25,23,.08)` in light
  and the only token in the table carrying that value. The NAME is the part of
  it that is off — the palette calls an 8% ink tint a rule between grouped rows,
  and this is an outline — but the alternative is `border_soft` at 14%, which
  would draw the empty cells nearly twice as dark as the drawing and make a gap
  look like a mark. The value is the drawing's; the missing 8% border token is
  the palette's to add.

  `padding_left`/`padding_right` and no vertical padding, because `nodeModifier`
  applies padding before size: an all-round 2 would make this cell 38 tall
  rather than 34 and unpick the grid.
  """
  @spec cell(map() | nil, map()) :: map()
  def cell(nil, _p) do
    ~MOB"""
    <Box
      weight={1.0}
      height={34}
      corner_radius={5}
      border_width={1}
      border_color={Palette.hairline_soft()}
    />
    """
  end

  def cell(meal, p) do
    ~MOB"""
    <Box
      weight={1.0}
      height={34}
      corner_radius={5}
      background={Palette.paper()}
      align="center"
      padding_left={2}
      padding_right={2}
    >
      <Column fill_width={true}>
        <Text
          text={meal.name}
          font_family={p.face}
          text_size={8.5}
          font_weight="semibold"
          text_color={:on_surface}
          text_align="center"
          max_lines={1}
        />
        {Kati.Screens.WeekImage.approx(meal.approx)}
      </Column>
    </Box>
    """
  end

  @doc """
  The `~` under a meal the plan is not sure of.

  Gold, because `Palette.gold_icon/0` is the note-and-annotation hue and this
  is an annotation on the cell rather than a state of it — a planned meal that
  happens to be approximate is still planned, so the tray keeps its fill. The
  mark stays in the mono face on both pages: it is an ASCII tilde, and the one
  Persian glyph rule that could have bitten here does not reach it.
  """
  @spec approx(boolean()) :: map()
  def approx(false), do: ~MOB"<Spacer size={0} />"

  def approx(true) do
    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={1} />
      <Text
        text="~"
        font_family="mono"
        text_size={6.5}
        text_color={Palette.gold_icon()}
        text_align="center"
        max_lines={1}
      />
    </Column>
    """
  end

  @doc """
  The rule, the three keys and the Kati mark that close a page.

  The keys are a hugging `Row` inside the outer one rather than three loose
  children, so `order/2` can move the whole group to the other end of the
  footer as one thing while still mirroring the keys inside it.
  """
  @spec footer(map()) :: map()
  def footer(p) do
    keys =
      p.legend
      |> Enum.map(fn {state, label} -> Kati.Screens.WeekImage.legend_key(state, label, p) end)
      |> Kati.Screens.WeekImage.order(p.dir)
      |> Enum.intersperse(Kati.Screens.WeekImage.key_gap())

    group =
      ~MOB"""
      <Row align="center">
        {keys}
      </Row>
      """

    ends =
      Kati.Screens.WeekImage.order(
        [group, Kati.Screens.WeekImage.spring(), Kati.Screens.WeekImage.mark(p)],
        p.dir
      )

    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={13} />
      {Kati.Screens.WeekImage.hairline()}
      <Spacer size={11} />
      <Row fill_width={true} align="center">
        {ends}
      </Row>
    </Column>
    """
  end

  @doc """
  One key: the mark a cell makes, then the word for it.

  Mirrored as a list like every other row on the page, so the swatch ends up on
  the right of its label in Persian without this function knowing which page it
  is drawing.
  """
  @spec legend_key(atom(), String.t(), map()) :: map()
  def legend_key(state, label, p) do
    word =
      ~MOB"""
      <Text
        text={label}
        font_family={p.legend_face}
        text_size={p.legend_size}
        letter_spacing={p.legend_tracking}
        text_color={Palette.eyebrow()}
        max_lines={1}
      />
      """

    parts =
      Kati.Screens.WeekImage.order(
        [Kati.Screens.WeekImage.legend_swatch(state), Kati.Screens.WeekImage.swatch_gap(), word],
        p.dir
      )

    ~MOB"""
    <Row align="center">
      {parts}
    </Row>
    """
  end

  @doc """
  The three marks a cell can carry, at legend size.

  A 9pt square at radius 2 rather than screen 44's 7pt dot, and the difference
  is the point: this key is a chip cut out of the grid above it, so a reader
  matches it against a cell by shape. `:approx` has no swatch at all — its mark
  *is* the glyph, so the key shows the glyph.
  """
  @spec legend_swatch(atom()) :: map()
  def legend_swatch(:planned) do
    ~MOB"<Box width={9} height={9} corner_radius={2} background={Palette.paper()} />"
  end

  def legend_swatch(:approx) do
    ~MOB"""
    <Text text="~" font_family="mono" text_size={10} text_color={Palette.gold_icon()} max_lines={1} />
    """
  end

  def legend_swatch(_free) do
    ~MOB"""
    <Box
      width={9}
      height={9}
      corner_radius={2}
      border_width={1}
      border_color={Palette.border_soft()}
    />
    """
  end

  @doc """
  The Kati mark, in the footer where the caption asks for it.

  A fridge page is the most likely thing anyone else sees, so the one place the
  app names itself is the page it hands over. `Kati` is not translated on the
  Persian page and stays in the mono face there: a wordmark is a mark, which is
  the rule `Kati.Screens.AlbumDetailFa` records for the Latin word printed on an
  album cover.
  """
  @spec mark(map()) :: map()
  def mark(p) do
    dot = ~MOB"<Box width={8} height={8} corner_radius={4} background={Palette.ink()} />"

    word =
      ~MOB"""
      <Text text={p.mark} font_family="mono" text_size={9.5} text_color={Palette.sub()} max_lines={1} />
      """

    parts =
      Kati.Screens.WeekImage.order([dot, Kati.Screens.WeekImage.swatch_gap(), word], p.dir)

    ~MOB"""
    <Row align="center">
      {parts}
    </Row>
    """
  end

  @doc """
  The rule above the footer.

  `Kati.Components.MishkaSeparator` with `render: :box` for the reason
  `Kati.Screens.MealPlan.hairline/1` sets out at length: `MobDivider` renders
  Material3's `HorizontalDivider`, an antialiased `drawLine` that cannot put a
  full-strength 1px rule on a 2.6875x device, and `:box` swaps the primitive
  back to a filled rect.

  44's builder is not called here only because of the colour. It pins
  `Palette.hairline/0` — 7%, which is what 44's drawing asks for — and this
  drawing rules its footer at 8%, `hairline_soft`. One alpha step, and it is
  the drawing's own step rather than a rounding of it.
  """
  @spec hairline() :: map()
  def hairline do
    MishkaSeparator.separator(color: Palette.hairline_soft(), thickness: 1, render: :box)
  end

  @doc """
  The 2pt gutter between two columns of the grid.

  Its own function because it is interspersed rather than nested: a `Spacer`
  with no weight measures exactly 2 and the weighted cells divide what is left,
  so the seven columns stay equal however many gutters sit between them.
  """
  @spec gap() :: map()
  def gap, do: ~MOB"<Spacer size={2} />"

  @doc "The 12pt gutter between two legend keys, which the drawing sets wider than the grid's."
  @spec key_gap() :: map()
  def key_gap, do: ~MOB"<Spacer size={12} />"

  @doc "The 5pt gap between a mark and the word for it, in both the legend and the Kati mark."
  @spec swatch_gap() :: map()
  def swatch_gap, do: ~MOB"<Spacer size={5} />"

  @doc """
  The weighted spacer that makes a row space-between.

  Named because both ends of the head row and both ends of the footer are laid
  out by it, and because `order/2` reverses the list it sits in: a spring is the
  one child of those rows that means the same thing either way round.
  """
  @spec spring() :: map()
  def spring, do: ~MOB"<Spacer weight={1.0} />"

  @doc """
  `Save image`, the one control on the screen.

  The ink pill, its label and the drawing's own lift — `0 14 28 -12` at 50%,
  the same CTA shadow `Kati.Screens.GoalsEmpty` draws, which is a string rather
  than a palette token because the bridge parses shadows as CSS layers.

  It is wired even though nothing happens yet: `handle_tap/2` says why, and a
  control that draws correctly and is not wired at all is the failure
  `Kati.Screens.Pushed`'s DEAD TAP report exists to catch.
  """
  @spec save_button() :: map()
  def save_button do
    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        height={54}
        corner_radius={27}
        background={Palette.ink_fill()}
        shadow="0 14 28 -12 #801A1917"
        align="center"
        on_tap={{self(), :save_image}}
      >
        <Spacer weight={1.0} />
        <Text
          text="Save image"
          text_size={14.5}
          font_weight="bold"
          text_color={Palette.on_ink()}
          max_lines={1}
        />
        <Spacer weight={1.0} />
      </Row>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  The label over the second page, and the one line on the screen set in two
  faces.

  `Kati.Screens.MealPlan.muted_eyebrow/1` draws exactly this eyebrow — the same
  13x2 `rail_idle` dash, the same 9pt gap, the same tracked mono at 10.5 in
  `eyebrow` — and it cannot be called, for one reason: its label is a single
  mono `Text`, and the last word of this label is شنبه. `kati_mono.ttf` carries
  no Arabic-script code point, so 44's builder would draw four empty boxes at
  the end of the line.

  So the Latin run keeps the mono face and the drawing's `.16em`, and the
  Persian word is a second `Text` in `fa` with no tracking. A `Row` can hold
  two runs where a paragraph cannot — see `restart_note/0` — because this line
  never wraps. The cost is a hair of baseline difference between two faces at
  one size, which is smaller than the cost of the word being unreadable.
  """
  @spec rtl_eyebrow() :: map()
  def rtl_eyebrow do
    latin = String.upcase("RTL — the week restarts at ")

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_left={2} padding_right={2}>
        <Box width={13} height={2} corner_radius={1} background={Palette.rail_idle()} />
        <Spacer size={9} />
        <Text
          text={latin}
          font_family="mono"
          text_size={10.5}
          letter_spacing={0.16}
          text_color={Palette.eyebrow()}
          max_lines={1}
        />
        <Text
          text="شنبه"
          font_family="fa"
          text_size={10.5}
          text_color={Palette.eyebrow()}
          max_lines={1}
        />
      </Row>
      <Spacer size={11} />
    </Column>
    """
  end

  @doc """
  The cream note under the Persian page: why a mirror is not a translation.

  Cream because the palette's one warm surface is where a note goes, and gold
  for the glyph for the same reason.

  The whole paragraph is set in `fa` although most of it is English, and that
  is forced rather than chosen. It contains شنبه, and a paragraph cannot be
  split into two runs the way `rtl_eyebrow/0`'s single line is: a `Row` does
  not wrap, so each run would become an unbreakable box and the emphasised
  words would orphan onto a line of their own, which is
  `Kati.UI.rich_text/1`'s finding. One `Text` then, in the one face that can
  draw the whole sentence — Vazirmatn carries Latin, and Plus Jakarta Sans
  carries no Arabic at all.

  The drawing bolds *restarts the sequence at شنبه*; `MobText` takes one weight
  for the whole string, so the emphasis is dropped rather than orphaned.
  """
  @spec restart_note() :: map()
  def restart_note do
    text =
      "Mirroring alone would put Monday on the right and still be wrong. " <>
        "The Persian page restarts the sequence at شنبه — the same correction " <>
        "60 makes for the in-app matrix."

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} background={Palette.cream()} corner_radius={20} padding={16} align="top">
        {UI.symbol("info", size: 18, color: Palette.gold_icon())}
        <Spacer size={11} />
        <Text
          text={text}
          font_family="fa"
          text_size={12.5}
          line_height={1.85}
          text_color={Palette.cream_body()}
          weight={1.0}
        />
      </Row>
      <Spacer size={14} />
    </Column>
    """
  end

  @doc """
  The footnote in a dashed frame: what a page can say that a screen cannot.

  `Kati.UI.SettingsList.note/2` unchanged. Thirty-two other screens draw this
  same frame, which is the reason its two-point disagreements with this drawing
  are left alone — see the moduledoc. Its two bold runs go the way
  `restart_note/0`'s does.
  """
  @spec page_note() :: map()
  def page_note do
    SettingsList.note(
      "info",
      "A page, not a screen, so cells carry names rather than state dots — " <>
        "44’s matrix could not, at 48px a column. Free slots stay outlined so a " <>
        "gap reads as a choice. The ~ mark rides along, because an approximate " <>
        "plan printed as exact is the same lie on paper."
    )
  end

  # Five rows of seven, from one week and one dish table. The labels come from
  # somewhere else entirely — 44's fixture in English, 60's in Persian — so a
  # row here is a slot name this app already uses rather than a word this
  # screen invented for a picture of it.
  defp rows(labels, week, dishes) do
    Enum.zip_with(labels, week, fn label, cells ->
      %{label: label, cells: Enum.map(cells, fn cell -> named(cell, dishes) end)}
    end)
  end

  defp labels(rows, key), do: Enum.map(rows, &Map.fetch!(&1, key))

  # `Map.fetch!` rather than `Map.get`: a dish with no name in one of the two
  # tables is a cell that would print blank on one page and correctly on the
  # other, which is the kind of asymmetry a screenshot comparison does not
  # catch until someone reads the Persian one.
  defp named(nil, _dishes), do: nil
  defp named({dish, :approx}, dishes), do: %{name: Map.fetch!(dishes, dish), approx: true}
  defp named(dish, dishes), do: %{name: Map.fetch!(dishes, dish), approx: false}

  # Drawing the page is all this screen can do, and saying so here is the point.
  #
  # `Save image` needs a node tree rasterised to a file, and nothing on this
  # bridge can do it: there is no snapshot, no `PixelCopy`, no canvas readback
  # anywhere in `MobBridge.kt`, and no Elixir side to receive bytes if there
  # were. So the tap is matched and answered with the socket unchanged, which
  # is a wired control with nothing to do rather than an unwired one — the
  # distinction `Kati.Screens.Pushed`'s DEAD TAP report exists to keep, and the
  # reason there is no catch-all clause under this one.
  @impl true
  def handle_tap(:save_image, socket), do: {:noreply, socket}
end
