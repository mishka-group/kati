defmodule Kati.Screens.HealthEmptyStates do
  @moduledoc """
  Screen 113 — the three empty states of the Health hub, on one sheet pushed
  under Settings.

  Screen 42 draws Health with a plan running, three sections live and two
  outlines. This is the board for the other three ways the same page can look:
  the hub with nothing switched on at all, the hub with **Meals** switched off —
  the one section whose absence takes visible furniture with it — and the two
  tiles that are on the grid and will not be built in v1. It is a reference
  sheet in the manner of screens 27 and 67, three pictures of a screen you go
  and look at rather than something the app puts in front of you, and it carries
  a `Settings` back pill for exactly that reason, as both of those do.

  The drawing letters that pill `Home`, because the frame is a picture of screen
  42 and `Home` is where 42 goes back to. Here the pill is the one control on the
  board that is not a picture of anything, and it goes where this sheet was
  opened from. A reference sheet that popped to Home would have its only working
  control lying about where you are.

  ## The decision the board states: a retired tile stays on the grid

  Hiding Sleep and Workouts would make the hub look complete when it is not, and
  somebody who saw Sleep in a screenshot and cannot find it would report the app
  as broken. So they stay, and the badge is what makes staying honest.

  Screen 42 already refuses to hide them — `Kati.Health.Sample.sections/0` keeps
  all six tiles and marks four of them `on?: false`, and `Kati.Screens.Health`
  draws that flag as an outline. What 113 adds is the **word**, and the word is
  the whole of the new information: an outline says *not set up*, which is a
  state you can change, and the first grid on this board is four tiles saying
  precisely that. `NOT IN V1` says *there is nothing to switch*, which is a
  different sentence about a tile that looks identical. `Not set up` under a
  section with no switch to find is worse than either — it sends you looking.

  That is also the one band on this sheet that screen 42 cannot draw for it. The
  badge sits in the tile's top row opposite the glyph, and `Health.tile/1`'s
  `on?: false` clause holds one child there and has no slot to pass. So
  `retired_tile/1` is written out here, from 42's numbers rather than beside
  them, and it is the only function on the board that redraws anything.

  ## Everything else is screen 42's own builders, called

  Both grids are `Kati.Screens.Health.sections/1` — the same chunk-of-two,
  the same `tile_row/1`, the same `tile/1` for the live and the outlined shape,
  the same `tile_gap/0` between the two retired tiles. Nothing here re-implements
  a tile, so a change to 42's grid arrives on this board the next time it renders
  and the comparison cannot quietly go stale.

  The tiles are fed from `Kati.Health.Sample.sections/0` and differ from 42's by
  the two keys each band is about, in the map-update syntax screen 67 uses for
  the same reason: a key that stops existing fails here loudly rather than
  drawing a state the tile would silently ignore.

  One mark does not survive that reuse. 42's live tile carries a 7pt status dot
  and this board's does not, so the three live tiles are handed
  `Kati.Theme.Palette.transparent/0`, which the palette defines as *nothing
  drawn, in either mode — an explicit absence rather than an omission*. The
  `Box` is still built; it is 7pt of nothing at the end of a row whose
  `Spacer weight={1.0}` has already taken the width, so nothing moves. Passing
  42's dots instead would have put four marks on the board that the drawing does
  not have.

  ## Nothing here reads a store, and the Meals line is where that bites

  27's rule applies unchanged: each band is a picture of a state, not a report
  that the app is in it. On screen 42 the Meals line is real —
  `Kati.Screens.Health.day/1` reads the active `Kati.Meals.MealPlan` and
  `sections_for/2` writes the plan's name and week into that tile. This board
  never calls it. A states sheet whose *Meals off* band changed wording because
  the device happens to have a plan would have stopped being the state it was
  drawn as, and the band is about Meals being off in any case: `Switched off` and
  `Not set up` are two literals of the board's own, on a tile that is an outline
  in both grids.

  ## Three taps arrive with the live tiles, and are answered

  `Health.tile/1` wires its own destinations through `tile_tap/1`, so reusing it
  brings Habits, Weight and Medication's tags onto this sheet whether or not a
  reference sheet wants them. They are answered with the three screens 42 opens,
  because the alternative is worse in both directions: swallowing them with a
  catch-all is what `Kati.Screens.Pushed` documents as the worst possible fix,
  and leaving them unanswered turns the board's own live tiles into the dead taps
  `Kati.Screens.Root.rescue_tap/3` exists to report.

  The retired tiles carry no tag at all — `tile_tap/1` already answers `nil` for
  both names — which is the one place this board cannot do what its own copy
  says. See below.

  ## Four things the drawing asks for that do not arrive

    * **`Tapping one opens 114`, and `Tap to see why`.** Both are wired as of
      7 September: `Kati.Screens.RetiredReason` IS board 114, and `retired_tile/1`
      carries the `on_tap` this paragraph said it would when the screen landed.
      A tile whose name `Kati.Retired` does not know keeps `nil` and stays
      untappable, rather than opening a page about nothing.
    * **Dashed borders are solid**, at the drawing's own 1.5pt and
      `rgba(26,25,23,.14)`. `Modifier.border` takes a width and a colour and no
      `PathEffect`; `Kati.Screens.Health` and `Kati.UI.SettingsList` both record
      the same loss, and the outline still reads as an outline against a filled
      tile without reading as *provisional*.
    * **The two bold runs are not bold.** `What remains is what Health actually
      is` and the `NOT IN V1` inside the closing note are `<strong>` spans in a
      running paragraph, and the bridge's `MobText` takes one weight for the
      whole string. `Kati.UI.rich_text/1` concatenates the runs and sets them in
      one style, which wraps correctly and drops the emphasis — the trade that
      function's own doc argues for, and the same one screens 14, 17, 23 and 33
      take.
    * **`114` cannot be a link.** It is kept as a run of its own so the token the
      drawing anchors is still the token in the tree, and it sets as body text.

  ## Which words on this board are this board's

  The sheet reads in Persian as of mishka-group/kati#103, and the line between
  what it translates and what it does not is the line the grids are built on.
  Every tile's NAME, and the three live lines in the *Meals off* band — *4
  active · 12-day best*, *76.0 kg · down 2.4*, *4 doses today* — come off
  `Kati.Health.Sample.sections/0` and are translated there or not at all. This
  board never writes them and must not wrap them: a `gettext/1` here would put
  a second msgid on the same six words and the two grids on screen 42 and this
  one could then disagree about what a section is called.

  What is this board's own is every line it OVERWRITES — *Not set up*,
  *Switched off*, *Tap to see why* — plus the chrome, the two cards and the
  badge, and those are the msgids this file owns. The badge is the exception
  that proves it: its words are `Kati.Screens.DataSources`' `Not in v1`,
  borrowed rather than restated, because *designed, not built* is one claim the
  app makes in four places and four msgids is how it would come to make four
  slightly different ones.

  ## Smaller notes

  The subtitle is typed in capitals — `THREE VARIANTS` — because the drawing sets
  it that way and `Kati.UI.SettingsList.title/3` does not transform it, where
  both eyebrow helpers upcase what they are given. The Arabic script has no
  raised form at all, so the Persian is written as the phrase it is and the
  capitals are a fact about the English msgid rather than about the slot — the
  same answer `Kati.UI.eyebrow_label/1` gives everywhere else. The first eyebrow
  keeps the orange dash because *nothing is set up yet* is a state you are in
  now; the other two take `eyebrow_muted/1`'s grey, since neither a section
  being off nor a section being retired is new or now.

  `Kati.UI.SettingsList.eyebrow_muted/1` still upcases with `String.upcase/1`
  and still tracks its label at a flat `.16em`, where `Kati.UI.eyebrow/2` next
  to it goes through `Kati.UI.eyebrow_label/1` and `Kati.Locale.tracking/1`.
  The upcase is a harmless no-op on Persian; the tracking is not — it breaks
  the joins between letters — so the two `eyebrow_muted/1` bands on this sheet
  set loose where the `eyebrow/2` band above them sets correctly. That is
  `Kati.UI.SettingsList`'s to fix and is recorded here because this board is
  where the difference is visible side by side.

  The empty card is `Kati.Screens.States.empty/1`'s recipe at this board's
  numbers, by way of `Kati.Screens.MyServicesEmpty.empty_group/0`, which is the
  nearest thing to it in the app: the same 48pt tile at radius 15 over paper, the
  same `Spacer weight={1.0}` either side of it, the same `text_align="center"` on
  the two paragraphs. Neither function could be called — 27's carries a call to
  action this card does not have, and both carry their own copy. Its body's
  leading is the one number that is not copied straight across: all three
  wrapping paragraphs on this sheet take `Kati.Locale.leading/1`, which answers
  the drawing's 1.55 in Latin and Vazirmatn's own in Persian. `derived_note/0`
  carries the argument.

  The closing note is 42's `container_note/0` shape and cannot be that function,
  which takes no text and prints `Kati.Health.Sample.container_note/0`.
  `Kati.UI.SettingsList.note/2` does take text and draws the same frame one point
  out on both the padding and the glyph, which on the band this board ends with
  is a difference somebody would have to explain later.

  No dock on a pushed screen, so the frame closes at 40 rather than 132.
  """

  # The board's own word, not the route's. These sheets are on `@no_route` —
  # `Kati.Screens.Gallery` is the only way to open one — so the pill names
  # nowhere in particular either way, and `Kati.Screens.WeightStates` already
  # set the precedent by keeping `Health` from its own board. Reproducing the
  # board is the rule; inventing a word for a pill nobody navigates by is not.
  use Kati.Screens.Pushed, back: "Home"
  use Gettext, backend: Kati.Gettext

  alias Kati.Components.MishkaPill
  alias Kati.Components.MishkaThemeIcon
  alias Kati.Health.Sample
  alias Kati.Screens.Health
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  # The two sections that are on the grid and will not be built, keyed on their
  # ICON rather than their label — the argument `Kati.Screens.Health` makes for
  # `sections_for/2`: an icon is a Material Symbols identifier and is never
  # translated, where a label one day will be, and a lookup that missed would
  # fail silently and draw the wrong band.
  @retired ~w(bedtime fitness_center)

  @impl true
  def load(socket) do
    Mob.Socket.assign(socket, :bands, %{
      nothing_set_up: nothing_set_up(),
      meals_off: meals_off(),
      retired: retired()
    })
  end

  @doc false
  @spec content(map()) :: map()
  def content(assigns) do
    b = assigns.bands

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
        {SettingsList.title(gettext("Health"), gettext("THREE VARIANTS"))}
        {UI.eyebrow(gettext("Nothing in Health set up"))}
        {Kati.Screens.HealthEmptyStates.empty_card()}
        {Health.sections(b.nothing_set_up)}
        {SettingsList.eyebrow_muted(gettext("Meals off — the ring and macro bar are meal-derived"))}
        {Kati.Screens.HealthEmptyStates.derived_note()}
        {Health.sections(b.meals_off)}
        {SettingsList.eyebrow_muted(gettext("Built vs retired"))}
        {Kati.Screens.HealthEmptyStates.retired_row(b.retired)}
        {Kati.Screens.HealthEmptyStates.retired_note()}
      </Column>
    </Scroll>
    """
  end

  @doc """
  The four buildable sections with none of them switched on.

  Sleep and Workouts are not in this grid at all, and their absence here is the
  board's own argument rather than a contradiction of it: this band is *nothing
  set up*, which is a state you can leave, and a tile you cannot switch on is not
  an example of it. They get the band of their own further down.

  Every tile keeps the icon and the name `Kati.Health.Sample.sections/0` gives
  it, so the grid is the same four sections in the same order the hub draws them
  — only their state and their line are this board's.
  """
  @spec nothing_set_up() :: [map()]
  def nothing_set_up do
    # The LINE is translated and the `:band` is not, and the two sit one after
    # the other so the difference is visible: the line is copy a reader reads,
    # and the band is the suffix `Kati.Screens.Health.tile_tap/2` builds a tag
    # out of. Translating the band would move every tag on this grid and land
    # the presses in `rescue_tap/3` — the same failure `tile_key/1` was written
    # to stop happening to a tile's NAME. mishka-group/kati#103.
    Enum.map(buildable(), fn tile ->
      tile
      |> Map.merge(%{on?: false, line: gettext("Not set up")})
      |> Map.put(:band, "nothing_set_up")
    end)
  end

  @doc """
  The hub with Meals switched off and the other three running.

  Meals moves to the end of the grid rather than staying first, which is the
  drawing's own ordering and says something the wording does not: a section that
  is off has stopped being the thing you look at first.

  The three live lines stay the fixture's — *4 active · 12-day best*,
  *76.0 kg · down 2.4*, *4 doses today* — where screen 42 would derive the Meals
  one from a real plan. See the moduledoc on why this board asks the fixture and
  never the database.
  """
  @spec meals_off() :: [map()]
  def meals_off do
    {meals, running} = Enum.split_with(buildable(), &(&1.icon == "restaurant"))

    # `pgettext/2` for two words, on the rule the fold works to: a msgid under
    # about three words is the shape `mix gettext.merge` fuzzy-matches onto
    # something else, and *Switched off* is one preposition away from the meal
    # plan's *Switching* — which is جابه‌جایی, a different sentence entirely.
    # The context says which switch and stops the match.
    off = pgettext("a Health section whose switch is off", "Switched off")

    (Enum.map(running, &live/1) ++
       Enum.map(meals, fn tile -> %{tile | on?: false, line: off} end))
    |> Enum.map(&Map.put(&1, :band, "meals_off"))
  end

  @doc """
  The two sections that stay on the grid and will not be built in v1.

  Their line changes from the hub's *Not set up* to *Tap to see why*, which is
  the only place the two states differ in words — the badge does the rest of the
  work, and it is the badge this band exists to introduce.
  """
  @spec retired() :: [map()]
  def retired do
    # The same four words screen 80 puts under a retired provider — its row
    # reads `Not set up — tap to see why` and this grid has already said *not
    # set up* with its outline, so only the tail is drawn here. One wording for
    # one promise: a reader who has met the phrase on 80 meets it again, rather
    # than a second Persian sentence for the same tap.
    Sample.sections()
    |> Enum.filter(&(&1.icon in @retired))
    |> Enum.map(fn tile -> %{tile | line: gettext("Tap to see why")} end)
  end

  # Everything Health holds that is a section rather than a decision already
  # made about a section.
  defp buildable, do: Enum.reject(Sample.sections(), &(&1.icon in @retired))

  # A tile 42 would light up, with the one mark this board's grid does not
  # carry — see the moduledoc on `transparent/0`. `on?` is forced rather than
  # assumed so the band means what its eyebrow says even if the fixture's own
  # flags move.
  defp live(tile), do: %{tile | on?: true, dot: Palette.transparent()}

  @doc """
  The card that stands where the hero and the meal row are on screen 42.

  It says what is missing and why, and it does not offer a button — which is the
  one place this card departs from `Kati.Screens.States.empty/1`, deliberately.
  Health has nothing of its own to add: *Health holds sections rather than data
  of its own* is the container claim screen 42 spends a whole note making, and a
  primary action here would have to point at a section, which is to say at one
  of the four tiles already sitting underneath it.
  """
  @spec empty_card() :: map()
  def empty_card do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={20}
        shadow={Kati.Theme.shadow_card_soft()}
        padding_left={15}
        padding_right={15}
        padding_top={21}
        padding_bottom={21}
      >
        <Row fill_width={true} align="center">
          <Spacer weight={1.0} />
          {Kati.Screens.HealthEmptyStates.empty_tile()}
          <Spacer weight={1.0} />
        </Row>
        <Spacer size={13} />
        <Text
          text={gettext("Nothing here yet")}
          text_size={14}
          font_weight="bold"
          text_align="center"
          text_color={:on_surface}
        />
        <Spacer size={6} />
        <Text
          text={gettext("Health holds sections rather than data of its own. Switch one on and this fills in.")}
          text_size={12.5}
          line_height={Kati.Locale.leading(1.55)}
          text_align="center"
          text_color={Palette.sub()}
        />
      </Column>
      <Spacer size={14} />
    </Column>
    """
  end

  @doc """
  The 48pt tile the empty card is headed by.

  `Kati.Components.MishkaThemeIcon` is "a themed container around exactly one
  icon", which is what this is, and the numbers are the drawing's: 48 square at
  radius 15 over paper, `monitor_heart` at 22 in `Palette.rail_idle/0`. Bigger
  and paler than a row's tile, for the reason
  `Kati.Screens.MyServicesEmpty.empty_tile/0` gives — it is illustrating the card
  rather than labelling a row, and the faintest mark the design draws is the
  right weight for a picture of something that is not there yet.

  The glyph goes in as a **child** rather than through the `icon` prop: that
  shorthand builds a `Text` with no `font_family`, so the ligature
  `"monitor_heart"` would be typeset as the words instead of resolving to the
  symbol.
  """
  @spec empty_tile() :: map()
  def empty_tile do
    MishkaThemeIcon.theme_icon(
      %{variant: :filled, color: Palette.paper(), size: 48, radius: 15},
      [UI.symbol("monitor_heart", size: 22, color: Palette.rail_idle())]
    )
  end

  @doc """
  Why the *Meals off* grid is missing more than a tile.

  The calorie ring and the macro bar are the two biggest objects on screen 42 and
  neither belongs to Health: both are summed from `Kati.Meals.MealLog` rows by
  `Kati.Meals.Nutrition`, so switching Meals off takes them with it. The card
  says so in place of drawing them empty, which is 27's rule — an empty state
  says what is missing rather than rendering a plausible-looking zero, and a ring
  at 0 of 2,100 kcal is a sentence about a day you have not eaten.

  What is left after they go is the grid, and the second half of the sentence is
  the point of the whole board: that grid *is* Health.
  """
  @spec derived_note() :: map()
  def derived_note do
    # `Kati.Locale.leading/1` rather than the drawing's flat 1.55. Vazirmatn's
    # ascenders and descenders are not Plus Jakarta's, so a leading set on the
    # Latin card crowds the Persian one — the argument
    # `Kati.Screens.Subscriptions.advice/2` makes at length about the one
    # paragraph on that screen which wraps, and both paragraphs on this board
    # wrap. The drawing's own number stays at the call site, which is the point
    # of that helper.
    body = [
      text_size: 12.5,
      line_height: Kati.Locale.leading(1.55),
      text_color: Palette.ink_soft()
    ]

    # `base: true` on the opening run rather than letting the longest one win:
    # the two body runs are close enough in length that editing the copy could
    # flip which style `Kati.UI.rich_text/1` picks for the paragraph. It is
    # load-bearing twice over now that the runs are translated — the Persian
    # of any run can be longer or shorter than the English it came from, so a
    # length-decided base would be decided by the catalogue.
    #
    # Three runs and not one interpolation, because the middle one is the
    # drawing's `<strong>` span: `Kati.UI.rich_text/1` drops the weight today
    # and would carry it the day `MobText` takes a `runs` prop, and a sentence
    # folded into one msgid could not get it back. The Persian is split at the
    # same seam and reads straight through it.
    text =
      UI.rich_text([
        {gettext("No calorie ring, no macro split — both come from meals. "),
         [base: true] ++ body},
        {gettext("What remains is what Health actually is"), :semibold},
        {gettext(": a list of sections."), body}
      ])

    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Palette.card()}
        corner_radius={20}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={15}
        align="center"
      >
        {UI.symbol("info", size: 19, color: Palette.sub())}
        <Spacer size={12} />
        <Column weight={1.0}>
          {text}
        </Column>
      </Row>
      <Spacer size={14} />
    </Column>
    """
  end

  @doc """
  The two retired tiles, side by side.

  `Kati.Screens.Health.tile_gap/0` between them, so the 12pt gutter this board's
  one hand-built row uses is the same value the two reused grids above it use
  rather than a second copy of the number. The row closes at 14 instead of the
  grid's 22 because the note underneath it belongs to it.
  """
  @spec retired_row([map()]) :: map()
  def retired_row(sections) do
    tiles =
      sections
      |> Enum.map(&Kati.Screens.HealthEmptyStates.retired_tile/1)
      |> Enum.intersperse(Health.tile_gap())

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        {tiles}
      </Row>
      <Spacer size={14} />
    </Column>
    """
  end

  @doc """
  A dashed tile carrying the `NOT IN V1` badge.

  The one function on this board that redraws something screen 42 already draws,
  and only because the badge has nowhere to go: `Kati.Screens.Health.tile/1`'s
  outlined clause puts a single glyph in its top row, and the badge belongs
  opposite that glyph. Every number below is copied from there deliberately —
  radius 20, a 1.5pt `border_soft` edge, 16 of padding, the glyph at 22 in
  `tertiary`, the name at 14.5 bold in `muted` and the line at 11 in
  `rail_idle` — so the two tiles are the same tile with one thing added, which is
  exactly what the grid is claiming about them.

  The `on_tap` the line under the name promises, since board 114 landed on
  7 September as `Kati.Screens.RetiredReason`. This paragraph used to say there
  was none — *screen 114 is not built and a tag nothing answers is reported as
  a dead tap* — which stopped being true when the tap went in below and is
  corrected here rather than left to be believed. A tile whose id
  `Kati.Retired` does not know still keeps `nil` and stays untappable.
  """
  @spec retired_tile(map()) :: map()
  def retired_tile(section) do
    assigns = %{
      section: section,
      # Board 114 landed on 7 September as `Kati.Screens.RetiredReason`, and
      # this is the `on_tap` the moduledoc above said would go here when it did.
      # `Kati.Retired` holds the reason; a tile whose id it does not know keeps
      # `nil` and stays untappable rather than opening a page about nothing.
      #
      # The ID and not the name. It was `section.name`, which is a drawn string
      # — so the day this grid is read in Persian the tile silently stops being
      # tappable, which is `Kati.Retired`'s own moduledoc on the subject.
      tap:
        if(Kati.Retired.known?(section.id),
          do: {self(), String.to_atom("why_" <> Atom.to_string(section.id))}
        )
    }

    ~MOB"""
    <Column
      weight={1.0}
      corner_radius={20}
      border_width={1.5}
      border_color={Palette.border_soft()}
      padding={16}
      on_tap={@tap}
    >
      <Row fill_width={true} align="center">
        {UI.symbol(@section.icon, size: 22, color: Palette.tertiary())}
        <Spacer weight={1.0} />
        {Kati.Screens.HealthEmptyStates.badge()}
      </Row>
      <Spacer size={14} />
      <Text
        text={@section.name}
        text_size={14.5}
        font_weight="bold"
        letter_spacing={Kati.Locale.tracking(-0.02)}
        text_color={Palette.muted()}
        max_lines={1}
      />
      <Spacer size={4} />
      <Text text={@section.line} text_size={11} text_color={Palette.rail_idle()} max_lines={1} />
    </Column>
    """
  end

  @doc """
  The 20pt paper badge that is the whole point of the third band.

  `Kati.Components.MishkaPill`, for the reason `Kati.Screens.Health.meals_pill/0`
  sets out at length: a compact label on its own fill is what a pill *is*, and
  the pill can be this one now that it takes a `height`, per-edge padding and an
  explicit `align`. `padding: 0` is load-bearing there and here — the pill pads
  before it sizes and its default is `:space_sm`, so without it a 20pt badge
  would measure 20 plus two paddings.

  The label goes in as a **child** rather than through `label`, and that is
  forced rather than chosen: `label/3` merges `font_weight`, `letter_spacing` and
  `line_height` onto its `Text` and has no `font_family` among them, so a mono
  label passed that way would silently set in Plus Jakarta. The badge is DM Mono
  at 9pt in the drawing, and mono is what makes it read as a version stamp rather
  than as a word.

  Being 20pt tall against a 22pt glyph, the badge does not change the tile's top
  row, so a retired tile and a plain outlined one are the same height.
  """
  @spec badge() :: map()
  def badge do
    MishkaPill.pill(
      %{
        # `paper`, not `track` or `placeholder`: the drawing fills the badge
        # `#EFECE7`, which is the page colour, so it reads as a chip punched out
        # of the ground rather than a control laid on it.
        background: Palette.paper(),
        corner_radius: 10,
        height: 20,
        padding: 0,
        padding_left: 8,
        padding_right: 8,
        align: :center
      },
      [badge_label()]
    )
  end

  # Handed over as a one-element list, which the pill drops straight into its
  # content Row — wrapping it in a Row here would only add a level.
  #
  # Worded and typeset exactly as `Kati.Screens.DataSources.not_in_v1/0` and
  # `Kati.Screens.AddIngredient.path_trailing/1` word and typeset it, and for
  # that function's own reason: *designed, not built* has to mean one thing
  # app-wide, and three badges with three msgids is how a phrase drifts into
  # three. So it is the shared `Not in v1` and not a fourth copy — the caps are
  # `Kati.UI.eyebrow_label/1`'s, which is a Latin operation the Arabic script
  # has no answer to, so Persian gets the sentence rather than a no-op.
  #
  # `Kati.Locale.mono_face/0` because `kati_mono.ttf` carries no Persian glyph
  # and Android would silently substitute its own face for the whole badge, and
  # `Kati.Locale.tracking/1` because .08em is a Latin small-caps effect that
  # breaks the joins between Persian letters. Both are no-ops in English, so the
  # drawing's DM Mono at 9pt is unchanged.
  defp badge_label do
    ~MOB"""
    <Text
      text={Kati.UI.eyebrow_label(gettext("Not in v1"))}
      font_family={Kati.Locale.mono_face()}
      text_size={9}
      letter_spacing={Kati.Locale.tracking(0.08)}
      text_color={Palette.sub()}
      max_lines={1}
    />
    """
  end

  @doc """
  The board's own argument, in the frame screen 42 ends with.

  It is here rather than in `Kati.Health.Sample` because it is a claim about the
  *version* rather than about Health: 42's note explains what the hub is, and
  this one explains why two of its tiles will not do anything. That happened on
  7 September — 114 landed, the tiles became tappable, and the last sentence
  stopped being a promise — so this is now the ordinary caption of a built
  thing, which is what the paragraph said it would become.

  The paragraph is wrapped in a `Column weight={1.0}` rather than carrying the
  weight itself, which is the one structural difference from 42's
  `container_note/0`: `Kati.UI.rich_text/1` builds a `Text` from a fixed set of
  typographic props and `weight` is not among them, so the width has to be given
  to it by a parent. A column with one child hands over all of it.
  """
  @spec retired_note() :: map()
  def retired_note do
    # `Kati.Locale.leading/1` for the reason `derived_note/0` gives one frame up.
    body = [
      text_size: 12.5,
      line_height: Kati.Locale.leading(1.55),
      text_color: Palette.ink_soft()
    ]

    # `114` is a run of its own, and the closing full stop is another, so the
    # token the drawing anchors is still one token in the tree even though
    # nothing can make it a link. See the moduledoc.
    #
    # `Kati.Locale.number/1` around it, so the board this note points at is
    # written ۱۱۴ on a Persian page. A board number is a number in a sentence
    # rather than a citation — `Kati.Locale.year/1` is the other case and the
    # opposite answer — and the three eyebrows on
    # `Kati.Screens.NothingSetUpKnockOn` already name their boards ۱۱، ۱۳، ۲۳.
    # A Latin `114` among Persian numerals would read as a different kind of
    # thing. English is unchanged: `number/1` is `Integer.to_string/1` there.
    #
    # The full stop stays a bare literal with no msgid. It is the same
    # character in both scripts, and a one-character msgid is exactly what
    # `mix gettext.merge` fuzzy-matches onto any sentence that ends in one.
    # The bidi algorithm puts it at the left edge of an RTL paragraph without
    # being asked, which is where a Persian sentence ends.
    #
    # The badge run is the same `Not in v1` the badge itself draws, so the
    # sentence and the thing it is about cannot drift apart. Persian has no
    # caps to set it off from the words around it, so the guillemets the app
    # quotes with live at the tail of the run before it and the head of the run
    # after — «…با نشانِ «در نسخه ۱ نیست» روی شبکه می‌مانند…» — which is why
    # those two msgstrs look lopsided beside their msgids.
    text =
      UI.rich_text([
        {gettext("Retired tiles stay visible with a "), body},
        {Kati.UI.eyebrow_label(gettext("Not in v1")), :semibold},
        {gettext(
           " badge rather than vanishing — a tile that disappears reads as a bug, and the badge is honest about what the version does. Tapping one opens "
         ), [base: true] ++ body},
        {Kati.Locale.number(114), body},
        {".", body}
      ])

    ~MOB"""
    <Row
      fill_width={true}
      corner_radius={18}
      border_width={1.5}
      border_color={Palette.border()}
      padding={15}
      align="top"
    >
      {UI.symbol("info", size: 17, color: Palette.sub())}
      <Spacer size={11} />
      <Column weight={1.0}>
        {text}
      </Column>
    </Row>
    """
  end

  @doc """
  The three tags the reused live tiles bring with them.

  Each one goes where screen 42 sends it, because the tile is 42's tile and the
  destination is 42's decision — this board has no business inventing a third
  answer for a control it did not draw. There is deliberately no catch-all: a
  fourth tag appearing here would mean the grid grew a control nobody wired, and
  `Kati.Screens.Root.rescue_tap/3` naming it is the only way anyone would find
  out. Meals is off in both grids, so `:open_meals` never arrives.
  """
  @impl true
  @spec handle_tap(atom(), term()) :: {:noreply, term()}
  # The board draws screen 42's Meals tile, so it draws that tile's tag. It is
  # a picture of a tile rather than a tile — 27's reason — and answering it
  # quietly is what keeps a press from raising into `rescue_tap/3`.
  # The tags arrive banded since #97 — `open_habits_nothing_set_up`,
  # `open_habits_meals_off` and so on — because this board draws the same grid
  # twice and one tag on two grids was one accessibility_id on two nodes. The
  # band is dropped here: which of the two grids a tile was pressed in changes
  # nothing about where it goes, and the moduledoc's argument for answering
  # these at all is unchanged.
  def handle_tap(tag, socket) when is_atom(tag) do
    case tag |> Atom.to_string() |> String.split("_") do
      # Board 114, built 7 September. Sleep and Workouts have said *tap to see
      # why* since this board was drawn and had nothing behind it.
      ["why", id] ->
        {:noreply,
         Mob.Socket.push_screen(socket, Kati.Screens.RetiredReason, %{
           id: String.to_existing_atom(id),
           back: "Health"
         })}

      ["open", "meals" | _band] ->
        {:noreply, socket}

      ["open", "habits" | _band] ->
        {:noreply, push(socket, Kati.Screens.Habits)}

      ["open", "weight" | _band] ->
        {:noreply, push(socket, Kati.Screens.Weight)}

      ["open", "medication" | _band] ->
        {:noreply, push(socket, Kati.Screens.Medication)}

      _other ->
        {:noreply, socket}
    end
  end

  defp push(socket, screen), do: Mob.Socket.push_screen(socket, screen)
end
