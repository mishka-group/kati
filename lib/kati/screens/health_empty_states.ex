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

    * **`Tapping one opens 114`, and `Tap to see why`.** Screen 114 is the
      retired-tile explainer and there is no module for it yet, so both lines are
      drawn and neither is wired. An inert tag would be reported as a dead tap,
      and a tap that pushed nothing would be the same lie in a quieter voice.
      When 114 lands, `retired_tile/1` is where the `on_tap` goes and this
      paragraph is what should be deleted.
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

  ## Smaller notes

  The subtitle is typed in capitals — `THREE VARIANTS` — because the drawing sets
  it that way and `Kati.UI.SettingsList.title/3` does not transform it, where
  both eyebrow helpers upcase what they are given. The first eyebrow keeps the
  orange dash because *nothing is set up yet* is a state you are in now; the
  other two take `eyebrow_muted/1`'s grey, since neither a section being off nor
  a section being retired is new or now.

  The empty card is `Kati.Screens.States.empty/1`'s recipe at this board's
  numbers, by way of `Kati.Screens.MyServicesEmpty.empty_group/0`, which is the
  nearest thing to it in the app: the same 48pt tile at radius 15 over paper, the
  same `Spacer weight={1.0}` either side of it, the same `text_align="center"` on
  the two paragraphs. Neither function could be called — 27's carries a call to
  action this card does not have, and both carry their own copy.

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
        {SettingsList.title("Health", "THREE VARIANTS")}
        {UI.eyebrow("Nothing in Health set up")}
        {Kati.Screens.HealthEmptyStates.empty_card()}
        {Health.sections(b.nothing_set_up)}
        {SettingsList.eyebrow_muted("Meals off — the ring and macro bar are meal-derived")}
        {Kati.Screens.HealthEmptyStates.derived_note()}
        {Health.sections(b.meals_off)}
        {SettingsList.eyebrow_muted("Built vs retired")}
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
    Enum.map(buildable(), fn tile -> %{tile | on?: false, line: "Not set up"} end)
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

    Enum.map(running, &live/1) ++
      Enum.map(meals, fn tile -> %{tile | on?: false, line: "Switched off"} end)
  end

  @doc """
  The two sections that stay on the grid and will not be built in v1.

  Their line changes from the hub's *Not set up* to *Tap to see why*, which is
  the only place the two states differ in words — the badge does the rest of the
  work, and it is the badge this band exists to introduce.
  """
  @spec retired() :: [map()]
  def retired do
    Sample.sections()
    |> Enum.filter(&(&1.icon in @retired))
    |> Enum.map(fn tile -> %{tile | line: "Tap to see why"} end)
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
          text="Nothing here yet"
          text_size={14}
          font_weight="bold"
          text_align="center"
          text_color={:on_surface}
        />
        <Spacer size={6} />
        <Text
          text="Health holds sections rather than data of its own. Switch one on and this fills in."
          text_size={12.5}
          line_height={1.55}
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
    body = [text_size: 12.5, line_height: 1.55, text_color: Palette.ink_soft()]

    # `base: true` on the opening run rather than letting the longest one win:
    # the two body runs are close enough in length that editing the copy could
    # flip which style `Kati.UI.rich_text/1` picks for the paragraph.
    text =
      UI.rich_text([
        {"No calorie ring, no macro split — both come from meals. ", [base: true] ++ body},
        {"What remains is what Health actually is", :semibold},
        {": a list of sections.", body}
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

  No `on_tap`, though the line under the name says *Tap to see why*. Screen 114
  is not built and a tag nothing answers is reported as a dead tap; see the
  moduledoc.
  """
  @spec retired_tile(map()) :: map()
  def retired_tile(section) do
    ~MOB"""
    <Column
      weight={1.0}
      corner_radius={20}
      border_width={1.5}
      border_color={Palette.border_soft()}
      padding={16}
    >
      <Row fill_width={true} align="center">
        {UI.symbol(section.icon, size: 22, color: Palette.tertiary())}
        <Spacer weight={1.0} />
        {Kati.Screens.HealthEmptyStates.badge()}
      </Row>
      <Spacer size={14} />
      <Text
        text={section.name}
        text_size={14.5}
        font_weight="bold"
        letter_spacing={-0.02}
        text_color={Palette.muted()}
        max_lines={1}
      />
      <Spacer size={4} />
      <Text text={section.line} text_size={11} text_color={Palette.rail_idle()} max_lines={1} />
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
  defp badge_label do
    ~MOB"""
    <Text
      text="NOT IN V1"
      font_family="mono"
      text_size={9}
      letter_spacing={0.08}
      text_color={Palette.sub()}
      max_lines={1}
    />
    """
  end

  @doc """
  The board's own argument, in the frame screen 42 ends with.

  It is here rather than in `Kati.Health.Sample` because it is a claim about the
  *version* rather than about Health: 42's note explains what the hub is, and
  this one explains why two of its tiles will not do anything. When 114 lands and
  the tiles become tappable, the last sentence stops being a promise and this
  becomes the ordinary caption of a built thing.

  The paragraph is wrapped in a `Column weight={1.0}` rather than carrying the
  weight itself, which is the one structural difference from 42's
  `container_note/0`: `Kati.UI.rich_text/1` builds a `Text` from a fixed set of
  typographic props and `weight` is not among them, so the width has to be given
  to it by a parent. A column with one child hands over all of it.
  """
  @spec retired_note() :: map()
  def retired_note do
    body = [text_size: 12.5, line_height: 1.55, text_color: Palette.ink_soft()]

    # `114` is a run of its own, and the closing full stop is another, so the
    # token the drawing anchors is still one token in the tree even though
    # nothing can make it a link. See the moduledoc.
    text =
      UI.rich_text([
        {"Retired tiles stay visible with a ", body},
        {"NOT IN V1", :semibold},
        {" badge rather than vanishing — a tile that disappears reads as a bug, and the badge is honest about what the version does. Tapping one opens ",
         [base: true] ++ body},
        {"114", body},
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
  def handle_tap(:open_meals, socket), do: {:noreply, socket}

  def handle_tap(:open_habits, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Habits)}

  def handle_tap(:open_weight, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Weight)}

  def handle_tap(:open_medication, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Medication)}
end
