defmodule Kati.Screens.MealLibraryEmpty do
  @moduledoc """
  Screen 117 — Meal library, empty and mirrored, on one board pushed under Meals.

  Screen 116 draws a library. This board draws the two ways that library is not
  the one 116 draws: the one with nothing in it, and the one read right to left.
  It is a reference board in screen 27's manner and screen 67's — two pictures of
  a screen you go and look at, rather than something the app puts in front of you
  — and it carries a back pill for the same reason both of those do.

  The first eyebrow keeps the orange dash and the second takes 27's grey one.
  *Empty* is the state a fresh install is in right now, which is what orange
  means and is the dash 27 gives its own `Empty` band; *RTL* is a property of a
  reader, not an event, so it takes the grey.

  ## Both routes out, and only one of them is a button

  The caption's decision: *a new user with no meals is exactly who receives a
  shared plan.* So the card names two ways forward instead of one — `Create a
  meal`, and `or import a shared plan`, which is `Kati.Screens.PlanShare`'s half
  of screen 50.

  They are not drawn as equals, and that is the whole of the design here. Create
  is a 54pt ink pill; import is a line of 12.5pt type under it. Two pills would
  make the person with no meals choose between two unfamiliar things before they
  have seen one meal; a pill and a sentence say *do this, unless someone has
  already sent you something*, which is the actual shape of the situation. It is
  the arrangement `Kati.Screens.GoalsEmpty.invitation/0` draws for the same
  reason, at that board's own numbers.

  ## Why 116 cannot draw this state itself

  `Kati.Screens.MealLibrary.meals/0` falls back to
  `Kati.Meals.SampleLibrary.meals/0` when nothing is stored, so 116 shows six
  meals on a fresh install and has no empty branch to reach. That is deliberate
  on 116's side — a drawing needs its fixture — and it is exactly why the empty
  card lives here instead: the board can draw a state the screen cannot get into,
  which is what a reference board is for.

  ## The mirror is mirrored by hand, because direction belongs to the root node

  `MainActivity.kt:285` reads `layout_direction` off `root.props` and provides
  `LocalLayoutDirection` once for the whole tree. A nested `layout_direction`
  prop compiles, renders and does nothing —
  `Kati.Screens.AttributionFa.quoted/1` records the same finding from the other
  side. `Kati.Screens.Fa.pushed_frame/1` is no use either: it would turn the
  English half of this board round with the Persian half.

  So the panel is mirrored by hand, and there are exactly two moves in it:

    * **Every `Row` inside the panel emits its children in reverse visual
      order** — the count before the chip label, the `APPROX` mark before the
      kcal figure, the no-photo tile before the salmon one — so that laid out
      left to right they land where an RTL reader expects them.
    * **Every Persian line that has to sit against the right edge carries
      `text_align="absolute_right"`**, which `textAlignProp`
      (`MobBridge.kt:4633`) maps to `TextAlign.Right`: an *absolute* alignment
      that never consults the layout direction, so it stays right on an LTR
      root.

  Two things the hand mirror cannot reach, both named rather than hidden:

    * **A horizontal `Scroll` rests at its start edge.** 116 puts its chips in
      one. Here the start edge is the wrong end of the mirror — the reader would
      open on میان‌وعده instead of on همه — so the chips are a plain Row pushed
      to the right instead, and the fifth chip is the one the board's own
      `overflow:hidden` cuts off. `میان‌وعده · ۳` is what is missing, and it is
      missing on the board too.
    * **Text shaping is not affected and did not need to be.** Bidi runs are
      resolved by the text layout rather than by layout direction, so
      `~۳۸۰ کالری` shapes correctly inside a single `Text` either way.

  ## Persian type, and the one artboard literal this board does not reproduce

  Every Persian `Text` goes through `Kati.Screens.BookDetailFa.fa/4`. Screen 69
  wrote that helper for the reason `Kati.Screens.Fa`'s moduledoc checked and
  states: Plus Jakarta Sans carries no Arabic-script glyphs, so a Persian label
  without `font_family="fa"` is a row of empty boxes rather than a fallback.
  Re-checked against the shipped subsets this round: `kati_sans_400.ttf` and
  `kati_mono.ttf` each carry **0** of U+0600–U+06FF, `kati_fa_400.ttf` carries
  142 of them and all ten of U+06F0–U+06F9.

  That second figure is the literal this board cannot render. The caption asks
  that *the kcal figure keeps DM Mono with Persian digits*, and DM Mono has no
  Persian digits and no کالری either, so the line would be five empty boxes. It
  is set in `fa` at the design's size and colour instead — `Kati.Screens.Fa`'s
  standing trade, *the face is wrong and the glyphs are right* — and it goes away
  the day the mono subset is regenerated with U+06F0–U+06F9 in it. The chip
  counts are the same case and take the same answer.

  The `APPROX` mark, by contrast, does what the caption asks: it translates.
  `تقریبی` is a word about the number rather than part of it, and screen 118's
  own reason for the mark — *a total built from partial data that pretends to be
  exact makes every number downstream a lie* — is a sentence, and sentences
  translate.

  ## The numbers and the words come from one place each

  The two meals, their kcal figures and the chip counts are 116's own fixture,
  read through `Kati.Screens.MealLibrary.drawn_meals/0` and
  `Kati.Meals.SampleLibrary.chips/0` and folded to Persian digits by
  `Kati.I18n.Digits.to_persian/1`. A mirror that disagreed with its original
  about how many meals are in the library would be a bug in the mirror rather
  than a translation of it. Only the *words* are this file's, and they are
  proposals — screen 72's rule for all Persian copy on these mirrors. A native
  reader correcting one corrects it once, in `words/0`.

  ## Where the two drawings and 116's module disagree, and which wins

  The panel exists to show what changes under RTL, so anything in it that
  differs from 116 for a reason other than direction or language would report a
  difference the app does not have. Five places, and in all five the *drawings*
  win, because `.scratch/design/screens/116.html` and this board agree with each
  other and it is 116's module that departs from both:

    * **The search field is 46 tall at radius 23** with 16pt sides, a 10pt gap
      and `Kati.Theme.shadow_card_soft/0`, and its glyph and placeholder are
      `Kati.Theme.Palette.muted/0`. `Kati.Screens.MealLibrary.search_field/0`
      renders 48 at radius 24 with 17 and 11, `shadow_search/0` and
      `tertiary/0`.
    * **The slot word sits on its own line** 3pt under the kcal figure, where
      `Kati.Screens.MealLibrary.tile/1` puts it at the trailing end of the kcal
      row. This is the one that could not be reused rather than merely
      re-numbered, and it is why there is a `tile/1` here at all.
    * **An unselected chip carries the card shadow** and a selected one carries
      none. `Kati.UI.chip/2` gives neither one a shadow, because
      `Kati.Components.MishkaChip` had no shadow to give until this round.
    * **The tile title is one line in both drawings** (`white-space:nowrap`) and
      two in 116's module. Two is kept, since it is 116's, and both Persian
      titles fit on one line anyway — so the departure is invisible here and
      stays 116's to settle where it shows.
    * **The `APPROX` mark sits on a 14% gold pill** at radius 10 in both
      drawings, and on nothing at all in
      `Kati.Screens.MealLibrary.approx_badge/1`. Here the module wins, and only
      because it has to: `Kati.Theme.Palette` has no gold wash — `red_wash_strong`
      is the same 14% alpha at the wrong hue — and no colour on this screen may
      be a hex literal. A `gold_wash` token is the thing that would have to land
      before either screen can draw the pill.

  ## Nothing on this board taps

  67's rule, for 67's reason: each card is a picture of a state, not a report
  that the app is in it. `Create a meal`, the search field and the four chips are
  drawn rather than wired, and `Kati.Screens.Pushed` defines no `handle_tap/2`,
  so none of them reports a dead tag. Tapping `Create a meal` on a board that is
  also showing a Persian grid would be pushing screen 118 out of a picture.
  """

  use Kati.Screens.Pushed, back: "Meals"

  alias Kati.I18n.Digits
  alias Kati.Meals.SampleLibrary
  alias Kati.Screens.BookDetailFa
  alias Kati.Screens.MealLibrary
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  # The Persian half of the two tiles the board draws, keyed by the English
  # title rather than by position: `drawn_meals/0` is a fixture and fixtures get
  # reordered, and a mirror that renamed the wrong meal would be worse than one
  # that dropped it. A title with no entry here is not drawn — see `meals/0`.
  @titles %{
    "Miso salmon, greens & rice" => "سالمون میسو و برنج",
    "Leftover dal" => "دال باقی‌مانده"
  }

  # Every slot name the fixture uses, not only the two the board prints, so a
  # different pair of tiles fails on a missing title rather than on a missing
  # slot. `برانچ` is the transliteration Persian actually uses for brunch;
  # there is no native word and inventing one would be worse than borrowing.
  @slots %{
    "All" => "همه",
    "Breakfast" => "صبحانه",
    "Brunch" => "برانچ",
    "Lunch" => "ناهار",
    "Dinner" => "شام",
    "Snack" => "میان‌وعده"
  }

  @words %{
    search: "جست‌وجوی وعده‌ها",
    kcal: "کالری",
    approx: "تقریبی"
  }

  # `Kati.Meals.SampleLibrary` seeds the salmon `meal-miso`, and no file of that
  # name was ever exported: `Kati.Design.Images.poster/1` answers `nil` for it
  # and 116's salmon tile therefore draws the no-photo placeholder on device.
  # Both drawings show a photograph, and this board's caption is *about* the
  # photograph — that it does not mirror — so the mirror uses the seed the
  # drawing itself names, `mealsalmon`, which is the file that shipped. The
  # fixture's spelling is `Kati.Meals.SampleLibrary`'s to correct.
  @exported %{"meal-miso" => "mealsalmon"}

  @doc """
  The board: the empty card, then the mirror, under 116's own title.

  `TWO STATES` rather than a count, because nothing here is a report of how many
  of anything there are — the subtitle names what the board holds.
  """
  @spec content(map()) :: map()
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
        {SettingsList.title("Meal library", "TWO STATES")}
        {UI.eyebrow("Empty — no meals at all")}
        {Kati.Screens.MealLibraryEmpty.empty_card()}
        {SettingsList.eyebrow_muted("RTL")}
        {Kati.Screens.MealLibraryEmpty.mirror()}
      </Column>
    </Scroll>
    """
  end

  @doc """
  The card a library with nothing in it shows.

  27's empty recipe — a paper tile over a centred heading, a sentence and a
  filled pill — at this board's metrics rather than through
  `Kati.Screens.States.empty/1`, for the reason
  `Kati.Screens.GoalsEmpty.invitation/0` gives at the same fork: that helper's
  card is 22/30 of padding around a 44pt pill with an `add` glyph in it, and this
  one is 17pt of padding around a 54pt pill with a label and no glyph. Same
  recipe, not one number shared.

  The 12pt above the tile and below the last line is the drawing's `12px 0` on
  the inner block, and it is what keeps the heading reading as a statement rather
  than as a caption on the control under it.

  116's own header hangs a create disc off the back-pill row and this board does
  not: `Create a meal` is already the card's whole point, and a second create
  control 200pt above it would be the same offer made twice.
  """
  @spec empty_card() :: map()
  def empty_card do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        padding={17}
        shadow={Kati.Theme.shadow_card_soft()}
      >
        <Spacer size={12} />
        <Row fill_width={true} align="center">
          <Spacer weight={1.0} />
          {Kati.Screens.MealLibraryEmpty.empty_tile()}
          <Spacer weight={1.0} />
        </Row>
        <Spacer size={16} />
        <Text
          text="No meals yet"
          text_size={16}
          font_weight="bold"
          letter_spacing={-0.02}
          text_align="center"
          text_color={:on_surface}
        />
        <Spacer size={8} />
        <Text
          text="A meal is a name, a few ingredients and its numbers. One is enough to start a plan."
          text_size={12.5}
          line_height={1.55}
          text_align="center"
          text_color={Palette.sub()}
        />
        <Spacer size={18} />
        {Kati.Screens.MealLibraryEmpty.create_button()}
        <Spacer size={15} />
        <Text
          text="or import a shared plan"
          text_size={12.5}
          font_weight="semibold"
          text_align="center"
          text_color={Palette.sub()}
        />
        <Spacer size={12} />
      </Column>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  The 60pt paper square the empty card is headed by.

  `Kati.Components.MishkaThemeIcon` for the reason
  `Kati.UI.SettingsList.icon_tile/1` gives — it is a themed container around
  exactly one icon — but at 60 and radius 19 rather than a row tile's 30 and 9,
  because it illustrates the card instead of labelling a row.

  The glyph is `restaurant`, the same one
  `Kati.Screens.MealLibrary.photo/1` puts in a tile with no picture, so *no meal*
  and *no photograph of this meal* read as the same kind of absence rather than
  as two unrelated marks. It sits in `Kati.Theme.Palette.rail_idle/0`, the
  faintest mark on paper the palette has, which is the right weight for a picture
  of something that is not there.

  The symbol goes in as a **child** rather than through the component's `icon`
  prop: that shorthand builds a `Text` with no `font_family`, so the ligature
  `"restaurant"` would be typeset as the word instead of resolving to the glyph.
  """
  @spec empty_tile() :: map()
  def empty_tile do
    Kati.Components.MishkaThemeIcon.theme_icon(
      %{variant: :filled, color: Palette.paper(), size: 60, radius: 19},
      [UI.symbol("restaurant", size: 27, color: Palette.rail_idle())]
    )
  end

  @doc """
  The one primary on the board: a 54pt ink pill carrying a label and no glyph.

  27's empty state puts an `add` beside its 44pt pill; this one does not, for the
  reason `Kati.Screens.GoalsEmpty.set_a_goal/0` states about its own — *Create a
  meal* is already the whole instruction and a plus in front of it says it twice.

  The lift is the drawing's `0 14px 28px -12px rgba(26,25,23,.5)`, which no
  recipe in `Kati.Theme` names — `shadow_hero/0` is the closest and is gold at a
  -20 spread — so it is written out in the prop's own format rather than rounded
  to whichever token is nearest, exactly as `Kati.Screens.GoalsEmpty` and
  `Kati.Screens.PickSections` write the same pill's.

  No `on_tap`: see the moduledoc on why nothing on a reference board taps.
  """
  @spec create_button() :: map()
  def create_button do
    ~MOB"""
    <Box
      fill_width={true}
      height={54}
      corner_radius={27}
      background={Palette.ink_fill()}
      shadow="0 14 28 -12 #801A1917"
      align="center"
    >
      <Text
        text="Create a meal"
        text_size={14.5}
        font_weight="bold"
        text_color={Palette.on_ink()}
        max_lines={1}
      />
    </Box>
    """
  end

  @doc """
  116's library read right to left, inset on the page's own colour.

  The panel is `Kati.Theme.Palette.paper/0` on paper, which sounds like a
  mistake and is the drawing's: the block has no fill of its own and only its
  16pt of padding to mark it out, so it reads as a *region* of the board rather
  than as a card sitting on it. A card here would claim the mirror is an object
  the app contains, and it is a second reading of the same screen.
  """
  @spec mirror() :: map()
  def mirror do
    ~MOB"""
    <Column fill_width={true} background={Palette.paper()} corner_radius={22} padding={16}>
      {Kati.Screens.MealLibraryEmpty.search()}
      {Kati.Screens.MealLibraryEmpty.chips()}
      {Kati.Screens.MealLibraryEmpty.grid(Kati.Screens.MealLibraryEmpty.meals())}
    </Column>
    """
  end

  @doc """
  The search field, mirrored: the glyph at the right, the placeholder beside it.

  The glyph is emitted **last** so it lands at the right edge — the hand mirror,
  in the smallest example of it there is.

  The placeholder is wrapped in a weighted `Column` rather than given a weight of
  its own, because `Kati.Screens.BookDetailFa.fa/4` takes no weight and does not
  need to: setting any `text_align` makes the bridge fill the `Text`'s width
  (`MobBridge.kt:3385`), so the text fills whatever the Column claims and
  right-aligns inside it.
  """
  @spec search() :: map()
  def search do
    placeholder = @words.search

    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        height={46}
        corner_radius={23}
        background={Palette.card()}
        shadow={Kati.Theme.shadow_card_soft()}
        padding_left={16}
        padding_right={16}
        align="center"
      >
        <Column weight={1.0}>
          {BookDetailFa.fa(placeholder, 13.5, Palette.muted(), align: "absolute_right")}
        </Column>
        <Spacer size={10} />
        {UI.symbol("search", size: 19, color: Palette.muted())}
      </Row>
      <Spacer size={14} />
    </Column>
    """
  end

  @doc """
  The four filter chips, reversed and pushed to the right edge.

  `Kati.UI.chip/2` cannot draw these — `Kati.Components.MishkaChip` takes its
  label as a prop and paints it in the chip's own family, and `expand/3` discards
  children, so a Persian label through that door is a row of boxes.
  `Kati.Screens.Fa`'s moduledoc names a content slot on that component as the
  single upstream ask; until it lands the chips here are hand-rolled with the
  drawing's geometry, which is 116's chip geometry too.

  `Snack` is rejected by name rather than dropped by a `take`, so the code says
  which chip is missing: it is the one the board's own `overflow:hidden` cuts off
  at the panel's edge, and a horizontal `Scroll` cannot get it back here — see
  the moduledoc.

  The counts are the library's rather than the grid's — 24 meals behind two
  tiles — which is the asymmetry `Kati.Meals.SampleLibrary.chips/0` exists to
  record and the mirror has no business re-deciding.
  """
  @spec chips() :: map()
  def chips do
    chips =
      SampleLibrary.chips()
      |> Enum.reject(fn {label, _count} -> label == "Snack" end)
      |> Enum.map(fn {label, count} ->
        Kati.Screens.MealLibraryEmpty.chip(
          @slots[label],
          Digits.to_persian(count),
          label == "All"
        )
      end)
      |> Enum.reverse()
      |> Enum.intersperse(~MOB"<Spacer size={7} />")

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Spacer weight={1.0} />
        {chips}
      </Row>
      <Spacer size={18} />
    </Column>
    """
  end

  @doc """
  One chip: the count first, then the label, which is the mirror of both.

  Both strings pass `align: nil` to `Kati.Screens.BookDetailFa.fa/4`. That
  helper defaults to `text_align="start"`, and any alignment makes the bridge
  fill the `Text`'s width (`MobBridge.kt:3385`) — inside a Row that hugs its
  content, a filling child takes the whole incoming width and the pill stops
  being a pill. Nothing needs aligning here anyway: the Row is the width of what
  is in it.

  The colour pairs are `Kati.UI.chip/2`'s, so the Persian chip and the Latin one
  cannot drift: `ink_fill` under `on_ink` selected, the card under `ink_soft`
  idle, and the count a step back from its label in either state. Both weights
  are semibold, which is what both drawings set — the fill is what marks the
  selected chip, not the weight.
  """
  @spec chip(String.t(), String.t(), boolean()) :: map()
  def chip(label, count, on?) do
    background = if on?, do: Palette.ink_fill(), else: Palette.card()
    colour = if on?, do: Palette.on_ink(), else: Palette.ink_soft()
    count_colour = if on?, do: Palette.on_ink_muted(), else: Palette.eyebrow()
    # An idle chip is a card lifted off the panel and a selected one is a mark
    # burnt into it, so only the idle chip takes a shadow. A `nil` prop reaches
    # the bridge as JSON null and `props["shadow"] as? String` answers null for
    # it (`MobBridge.kt:4714`), which is the same as not sending the key.
    shadow = if on?, do: nil, else: Kati.Theme.shadow_card_soft()

    ~MOB"""
    <Row
      height={32}
      corner_radius={16}
      background={background}
      shadow={shadow}
      padding_left={15}
      padding_right={15}
      align="center"
    >
      {BookDetailFa.fa(count, 10, count_colour, align: nil)}
      <Spacer size={6} />
      {BookDetailFa.fa(label, 12, colour, weight: "semibold", align: nil)}
    </Row>
    """
  end

  @doc """
  The grid, two across and reversed, so the first meal lands at the right.

  `Enum.reverse/1` on the tiles is the whole of the mirror here. Nothing inside a
  tile is reversed by this function — the tile does its own — and nothing sorts
  or re-picks the meals, so the pair is the fixture's pair in the fixture's
  order, read from the other end.
  """
  @spec grid([map()]) :: map()
  def grid(meals) do
    tiles =
      meals
      |> Enum.map(&Kati.Screens.MealLibraryEmpty.tile/1)
      |> Enum.reverse()
      |> Enum.intersperse(~MOB"<Spacer size={12} />")

    ~MOB"""
    <Row fill_width={true} align="top">
      {tiles}
    </Row>
    """
  end

  @doc """
  One mirrored tile: the photograph unchanged, everything under it turned round.

  `Kati.Screens.MealLibrary.photo/1` is called verbatim, and that is the
  caption's own point — *the grid mirrors but the photo does not*. A photograph
  has a left and a right of its own and mirroring it would be mirroring the
  world, which is the rule `Kati.Screens.BookDetailFa` records for a cover and
  `Kati.Screens.AlbumDetailFa` for album art. The no-photo case comes back with
  its `Meal photo` caption still in DM Mono and still in Latin, which is what
  both drawings print: it is a note about a missing file, addressed to whoever
  will supply one.

  The three lines under it are the mirror. The title and the slot word carry
  `absolute_right`; the kcal row is emitted mark-then-figure behind a weighted
  spacer, so the figure sits against the right edge with the `تقریبی` mark to its
  left, which is where an RTL reader meets it second.

  The slot word is on its own line here, 3pt down, because that is where both
  drawings put it — see the moduledoc for why the drawings win over
  `Kati.Screens.MealLibrary.tile/1`, which puts it at the end of the kcal row.
  """
  @spec tile(map()) :: map()
  def tile(meal) do
    ~MOB"""
    <Column weight={1.0}>
      {MealLibrary.photo(meal)}
      <Spacer size={9} />
      {BookDetailFa.fa(meal.title, 12.5, :on_surface,
        weight: "bold",
        lines: 2,
        align: "absolute_right"
      )}
      <Spacer size={4} />
      <Row fill_width={true} align="center">
        <Spacer weight={1.0} />
        {Kati.Screens.MealLibraryEmpty.approx(meal.approximate?)}
        {BookDetailFa.fa(meal.kcal, 10.5, Palette.muted(), align: nil)}
      </Row>
      <Spacer size={3} />
      {BookDetailFa.fa(meal.slot, 10, Palette.rail_idle(), align: "absolute_right")}
    </Column>
    """
  end

  @doc """
  The translated `APPROX` mark, or nothing.

  `Kati.Screens.MealLibrary.approx_badge/1`'s glyph, colours and 3pt gap, with
  the word translated and the pair reversed: the label first so the `help` glyph
  lands to its right, against the kcal figure it qualifies. The trailing 6pt is
  the gap to that figure, carried here rather than in the row, so a tile with no
  mark has no stray spacer in it — the same arrangement the badge it mirrors
  uses, pointing the other way.

  Set at 10pt rather than that function's 8.5, and with no tracking. Vazirmatn at
  8.5 is not readable and Arabic script does not take letter-spacing at all;
  10 is the size this drawing sets for the Persian mark, which is the whole
  reason it sets a second size.
  """
  @spec approx(boolean()) :: map() | []
  def approx(false), do: []

  def approx(true) do
    label = @words.approx

    ~MOB"""
    <Row align="center">
      {BookDetailFa.fa(label, 10, Palette.gold_text(), align: nil)}
      <Spacer size={3} />
      {UI.symbol("help", size: 13, color: Palette.gold_icon())}
      <Spacer size={6} />
    </Row>
    """
  end

  @doc """
  The two meals the panel draws, in Persian.

  116's fixture is the source for everything that is not a word: the titles it
  keys on, the kcal figures, the approximate flag and the slot. Only the words
  and the digits are this file's, so the mirror cannot come to disagree with 116
  about the library — which is the one thing a mirror must not do.

  Meals with no entry in the title table are dropped rather than passed through,
  because a Latin title in the middle of a Persian grid is not a fallback, it is
  a hole in the translation pretending to be data.
  """
  @spec meals() :: [map()]
  def meals do
    MealLibrary.drawn_meals()
    |> Enum.filter(&Map.has_key?(@titles, &1.title))
    |> Enum.map(fn meal ->
      %{
        meal
        | title: @titles[meal.title],
          kcal: kcal(meal.kcal),
          slot: Map.fetch!(@slots, meal.slot),
          seed: Map.get(@exported, meal.seed, meal.seed)
      }
    end)
  end

  @doc "The Persian copy this file proposes, for a reader who wants to correct it."
  @spec words() :: %{titles: map(), slots: map(), labels: map()}
  def words, do: %{titles: @titles, slots: @slots, labels: @words}

  # `"~380 kcal"` becomes `"~۳۸۰ کالری"`. The unit is replaced before the digits
  # are folded so `to_persian/1` never sees the Latin word, and the tilde is left
  # alone: it is the drawing's own mark for an approximate figure and Persian
  # writes it the same way.
  defp kcal(text) do
    text
    |> String.replace("kcal", @words.kcal)
    |> Digits.to_persian()
  end
end
