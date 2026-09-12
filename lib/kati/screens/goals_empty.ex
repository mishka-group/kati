defmodule Kati.Screens.GoalsEmpty do
  @moduledoc """
  Screen 105 — Goals with nothing in it, pushed under Stats.

  Screen 104 is this page carrying three goals. This is the page before any of
  them exist, and it gets a whole board rather than a band on screen 27's states
  sheet for the reason screen 93 gets one: it is the state every new user is in,
  and the only state in which the page has to argue for itself.

  ## The sentence is the screen

  *No goals. Kati will still count everything.* is verbatim from the brief and
  protected in review. It is one literal in one place — `invitation/0` — never
  interpolated, never trimmed to fit a line, and never softened into *you have
  not set any goals yet*, which says the opposite thing about whose fault the
  empty page is. The paragraph under it restates the promise as a mechanism: a
  goal only decides what gets a progress bar. Between them they say that setting
  nothing costs nothing, which is the one claim an empty Goals page has to make.

  ## The list is the evidence, and that is why it earns the board

  A card that says Kati counts everything is an assertion, and an assertion is
  where most empty states stop. The list under it is the proof — three media,
  each with a figure the app already holds — and the design's caption is
  explicit that this second half is what earns the frame. Neither half survives
  the other: without the list the claim is unsupported, and without the claim
  the list is a menu.

  Each row's noun is `Kati.Goals.Goal.unit/1` rather than a word typed here, so
  nothing can appear on the list that you could not then set a goal for. The
  rows read `34 books`, `84 films` and `418 albums`, and those three nouns are
  the same ones the chip field on screen 106 offers, because they come from the
  same table. Composing a title the drawing draws whole used to cost something:
  the old source grep reported all three as missing text, and 104's
  `52 books this year` with them, since `Kati.Goals.Goal.title/1` builds that
  one the same way and neither string is typed anywhere.
  `Kati.ScreenDesignLiteralTest` asks the rendered tree instead, where the
  interpolation has already happened and `34 books` is one `Text` like any
  other, so taking the noun from the table no longer buys a false report.

  The second line of each row is composed the same way, and that is what
  mishka-group/kati#103 moved here. `11,480 pages this year` is
  `Kati.Goals.Goal`'s own period phrase over `Goal.unit(:pages)` — the one that
  builds 104's `52 books this year` — and `312h 40m` and `61h` are the
  `%{h}h %{m}m` and `%{n}h` runtimes eight other screens already ask the
  catalogue for. So a Persian reader gets «۱۱,۴۸۰ صفحه امسال» without this
  board inventing a second word for a page or an hour, and the English renders
  the drawing's own three strings to the byte. See `detail/1` for why they
  could not stay in `@counted`.

  ## Every figure is the drawing's, and that is a compromise rather than a rule

  Worth naming as one, because a list whose whole job is to support a claim is
  the worst place on the page for an invented number. Only one of the three
  could be read today: `Kati.Screens.Stats.figures/0` gets `312h 40m` off
  `Kati.Media.Watch` whenever there is anything to count. Books and Music can
  answer no question about a **year** at all — `Kati.Books.Sample.subtitle/0`'s
  `64 books` counts a shelf, and `Kati.Music.Sample.subtitle/0`'s figures are
  themselves a fixture. One live row beside two fixtures would be worse than
  three fixtures, because no row says which it is, and screen 27's rule is all
  of it or none of it. When Books and Music can answer *this year*, all three
  rows read and this paragraph goes.

  ## Three things 104 draws that this board does not

    * **The add disc.** `Kati.Screens.Goals.chrome/0` hangs a 44pt ink disc
      opposite the back pill, and it is deliberately not called here. With no
      goals there is exactly one thing to do on this page and the 54pt pill
      inside the card is it; a second add in the corner would stand two
      primaries either side of the sentence the board exists to say.
      `Kati.UI.SettingsList.chrome/2` with no icon reserves the pill's 44pt and
      draws nothing opposite it.
    * **The count under the title.** `Kati.Screens.Goals.subtitle/0` answers a
      device with nothing stored with the fixture's `3 ACTIVE · JAN – DEC 2026`,
      so calling it — or `Kati.UI.SettingsList.title/3`, which always draws a
      second line — would head an empty page with a tally of goals that do not
      exist. See `title/0`.
    * **Repeat, and the row that says what a goal is not.** Both are properties
      of goals you already have, so `Kati.Screens.Goals.repeat_group/1` stays on
      104 and this page ends at the list.

  ## The secondary line points; it does not push

  *or see what Kati already counts* is set as a caption rather than wired as a
  control, and the reason is that the design's *leads there* has already
  happened: **there** is on this same board, directly under it. Mob reports no
  geometry back to `render/1` and has no way to scroll to a node, so the only
  tap available would be one that did nothing — which
  `Kati.Screens.Root.rescue_tap/3` would rightly report as a dead control. If
  the card ever grows past the fold this needs a scroll target, not a handler.

  ## The one property of the drawing that does not survive

  Both paragraphs in the card are `text-wrap: pretty` in the export, which asks
  the browser to avoid a short last line. Compose has no balanced-wrap mode and
  the bridge exposes no prop for one, so both wrap greedily and the heading may
  drop a word onto a line of its own. Recorded rather than worked around: the
  fix would be a hard break typed into the copy, and the copy is the one thing
  on this board that is protected.

  ## Two places this file follows the drawing rather than 104

  Both cards carry `Kati.Theme.shadow_card_soft/0`, whose second layer is the
  `.7` both boards draw. `Kati.Screens.Goals.card/1` is on `shadow_card/0` at
  `.6` against that same `.7` on its own board; that is 104's to reconcile, and
  copying it here would have put two different lifts on one page, since the list
  below is `Kati.UI.SettingsList.card/1` and is already on the softer one.

  And the chevron goes to `Kati.UI.SettingsList.row/4` bare. That function calls
  `Kati.UI.SettingsList.trailing/1` on whatever it is handed, so passing an
  already-wrapped trailing — the majority idiom, and 104's — nests two `Row`s
  and turns the drawing's 13pt gap into 24. Handed over bare it is 12.
  """

  use Kati.Screens.Pushed, back: "Stats"
  use Gettext, backend: Kati.Gettext

  alias Kati.Components.MishkaThemeIcon
  alias Kati.Goals.Goal
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  # The three media the list names, as `{kind, count, glyph, tag}`.
  #
  # The first element is a `Kati.Goals.Goal` kind rather than a label, which is
  # what makes `counted/0` able to ask for the noun instead of writing one. The
  # count is the drawing's copy — see the moduledoc for why it is not read, and
  # for what has to exist before it can be.
  #
  # The detail line USED to be a fifth element here and is `detail/1` now. It
  # had to move: a `gettext/1` inside a module attribute is evaluated once, at
  # COMPILE time, in whatever locale the compiler happened to be in, so a
  # sentence translated in place here would ship in one language whichever the
  # reader chose. `Kati.Goals.Goal.unit/1`'s doc states the same rule about
  # `@kinds`, and for the same reason keeps its English in the table and its
  # words in function clauses.
  @counted [
    {:books, "34", "menu_book", :open_books},
    {:films, "84", "movie", :open_films},
    {:albums, "418", "graphic_eq", :open_albums}
  ]

  @doc """
  The three rows, each carrying the noun its goal kind counts in.

  Public and pure, so the list can be read without a screen and asserted against
  `Kati.Goals.Goal.kinds/0` without a device. It is also the one part of this
  board that changes when Books and Music can answer *this year*, and the change
  is meant to land here rather than in the markup below it.

  Pure, but no longer locale-free: both lines of every row go through
  `Kati.Gettext` and `Kati.Locale`, so a caller asserting against this gets the
  language its own process is in. That is what `Kati.Locale.as/2` is for.
  """
  @spec counted() :: [map()]
  def counted do
    Enum.map(@counted, fn {kind, count, glyph, tag} ->
      # `Kati.Locale.number/1` because `Goal.unit/1` answers «کتاب» under `:fa`
      # and `34 کتاب` would be one word in each script.
      title = "#{Kati.Locale.number(count)} #{Goal.unit(kind)}"

      %{title: title, detail: detail(kind), glyph: glyph, tag: tag}
    end)
  end

  # A row's second line, at the drawing's own figures and in the reader's own
  # words and digits.
  #
  # Every part of every one of these is already in the catalogue, which is the
  # point — see the moduledoc. `%{count} %{unit} this year` is
  # `Kati.Goals.Goal.title/1`'s yearly phrase, so the books row says *this
  # year* in whatever way the reader's language says it (Persian puts امسال
  # where English puts two words at the end) rather than having a Latin-ordered
  # sentence translated a word at a time. `%{h}h %{m}m` and `%{n}h` are the
  # durations eight other screens ask for, and they carry the units with them:
  # `312h 40m` was two Latin letters glued to two Latin numbers, which is the
  # defect `Kati.Screens.Stats.hours_and_minutes/1` names on board 61.
  #
  # `Goal.unit(:pages)` rather than the word *pages*, for the reason the
  # moduledoc gives about the titles: nothing may appear on this list that you
  # could not then set a goal for, and `pages` is one of the ten kinds screen
  # 106 offers.
  #
  # The figures themselves are still the drawing's rather than reads — the
  # moduledoc's *Every figure is the drawing's* says which of the three could
  # be answered today and why one live row beside two fixtures would be worse
  # than three fixtures.
  defp detail(:books) do
    gettext("%{count} %{unit} this year",
      count: Kati.Locale.number("11,480"),
      unit: Goal.unit(:pages)
    )
  end

  defp detail(:films) do
    gettext("%{hours} watched",
      hours: gettext("%{h}h %{m}m", h: Kati.Locale.number(312), m: Kati.Locale.number(40))
    )
  end

  defp detail(:albums) do
    gettext("%{hours} listened", hours: gettext("%{n}h", n: Kati.Locale.number(61)))
  end

  @doc false
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
        {Kati.Screens.GoalsEmpty.title()}
        {Kati.Screens.GoalsEmpty.invitation()}
        {SettingsList.eyebrow_muted(gettext("What Kati counts anyway"))}
        {Kati.Screens.GoalsEmpty.counted_list(Kati.Screens.GoalsEmpty.counted())}
      </Column>
    </Scroll>
    """
  end

  @doc """
  `Goals`, with nothing under it.

  Written out rather than reached through `Kati.UI.SettingsList.title/3`, which
  always draws a mono second line — and there is no honest line to put there;
  see the moduledoc. Every other number is 104's exactly, `max_font_scale`
  included, because the two boards are the same page and a title that changed
  size between them would read as a different screen.

  The tracking is 104's too, by way of `Kati.UI.SettingsList.title_text/1`:
  `Kati.Locale.tracking/1` keeps the drawing's -0.03em in Latin and drops it to
  zero in Persian, where letter spacing does not tighten a heading, it breaks
  the joins between the letters of one.

  `max_lines={1}` is the one prop `title_text/1` does not carry, and it is not
  a number that could disagree with 104: it is a guard on a heading whose
  Persian is a different length from its English, so a page title can never
  become two lines and push the card under it down the board.
  """
  @spec title() :: map()
  def title do
    ~MOB"""
    <Column fill_width={true}>
      <Text
        text={gettext("Goals")}
        text_size={28}
        max_font_scale={1.6}
        font_weight="bold"
        letter_spacing={Kati.Locale.tracking(-0.03)}
        text_color={:on_surface}
        max_lines={1}
      />
      <Spacer size={20} />
    </Column>
    """
  end

  @doc """
  The card that says nothing is lost, and the one control that changes it.

  Screen 27's empty recipe — a paper tile over a centred heading, a sentence and
  a filled pill — at this board's metrics rather than through
  `Kati.Screens.States.empty/1`. That helper's card is 22/30 of padding around a
  44pt pill with an `add` glyph in it; this one is 104's card exactly, radius 22
  at 17pt of padding, around a 54pt pill with a label and no glyph. Same recipe,
  and not one number shared, so it is written here instead of the helper growing
  a second mode for one call site.

  The 14pt above the tile and below the last line is the drawing's `14px 0` on
  the inner block, and it is the reason the card stands taller than its own
  padding: the heading needs room to read as a statement rather than as a label
  on a control.

  Neither sentence in here takes a `max_lines`, unlike `title/0`'s heading and
  `set_a_goal/0`'s label. Both are meant to wrap — the card has no fixed height
  and the moduledoc's last section is about how they wrap, not whether — so a
  cap would truncate the one thing on this board that is protected. The
  paragraph's leading goes through `Kati.Locale.leading/1` for the same reason
  it wraps freely: Vazirmatn's metrics are not Plus Jakarta's, and 1.55 set
  against the Latin drawing crowds the Persian one.
  """
  @spec invitation() :: map()
  def invitation do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        padding={17}
        shadow={Kati.Theme.shadow_card_soft()}
      >
        <Spacer size={14} />
        <Row fill_width={true} align="center">
          <Spacer weight={1.0} />
          {Kati.Screens.GoalsEmpty.tile()}
          <Spacer weight={1.0} />
        </Row>
        <Spacer size={18} />
        <Text
          text={gettext("No goals. Kati will still count everything.")}
          text_size={17}
          font_weight="bold"
          letter_spacing={Kati.Locale.tracking(-0.02)}
          text_align="center"
          text_color={:on_surface}
        />
        <Spacer size={9} />
        <Text
          text={gettext("A goal only decides what gets a progress bar. Nothing is lost by not setting one.")}
          text_size={13}
          line_height={Kati.Locale.leading(1.55)}
          text_align="center"
          text_color={Palette.sub()}
        />
        <Spacer size={18} />
        {Kati.Screens.GoalsEmpty.set_a_goal()}
        <Spacer size={15} />
        <Text
          text={gettext("or see what Kati already counts")}
          text_size={12.5}
          font_weight="semibold"
          text_align="center"
          text_color={Palette.sub()}
        />
        <Spacer size={14} />
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  The 64pt paper square the card is headed by.

  `Kati.Components.MishkaThemeIcon` for the reason
  `Kati.UI.SettingsList.icon_tile/1` gives — it is a themed container around
  exactly one icon — but at 64 and radius 20 rather than a row tile's 30 and 9,
  because it illustrates the page instead of labelling a row.

  `checklist` sits in `Kati.Theme.Palette.rail_idle/0`, the faintest mark on
  paper the palette has. The glyph is a picture of the thing that is not there,
  and a tile drawn at any more weight would be competing with the sentence it
  was put above.

  The glyph goes in as a child rather than through the component's `icon`
  shorthand, which builds a `Text` with no `font_family` and would typeset the
  ligature `checklist` as the word rather than resolving it.
  """
  @spec tile() :: map()
  def tile do
    MishkaThemeIcon.theme_icon(
      %{variant: :filled, color: Palette.paper(), size: 64, radius: 20},
      [UI.symbol("checklist", size: 28, color: Palette.rail_idle())]
    )
  end

  @doc """
  The only control on the board, and the one thing this page and 104 do
  identically: both open screen 106.

  A 54pt ink pill carrying a label and no glyph. Screen 27's empty state puts an
  `add` beside its 44pt one and this board does not, because *Set a goal* is
  already the whole instruction and a plus in front of it says it twice.

  The lift is the drawing's own `0 14px 28px -12px rgba(26,25,23,.5)`, which no
  recipe in `Kati.Theme` names — `shadow_hero/0` is the closest and is gold at a
  -20 spread — so it is written out in the prop's own format rather than rounded
  to whichever token is nearest, the way `Kati.Screens.PickSections` writes the
  same pill's.
  """
  @spec set_a_goal() :: map()
  def set_a_goal do
    ~MOB"""
    <Box
      fill_width={true}
      height={54}
      corner_radius={27}
      background={Palette.ink_fill()}
      shadow="0 14 28 -12 #801A1917"
      align="center"
      on_tap={{self(), :add}}
    >
      <Text
        text={gettext("Set a goal")}
        text_size={14.5}
        font_weight="bold"
        text_color={Palette.on_ink()}
        max_lines={1}
      />
    </Box>
    """
  end

  @doc """
  The evidence, as one grouped card.

  `Kati.UI.SettingsList`'s card, row, tile, body and chevron unchanged: the
  drawing's radius 20, its `4px 15px` of padding and its 13pt rows are that
  helper's own defaults, so nothing is restated here. The last row drops its
  hairline, which is what `row/4` takes `rule:` for.

  Every row opens the shelf it counts. A list that exists to show Kati is
  already counting, and could then show you none of it, would be making the
  claim twice instead of proving it once.
  """
  @spec counted_list([map()]) :: map()
  def counted_list(rows) do
    last = length(rows) - 1

    rows =
      rows
      |> Enum.with_index()
      |> Enum.map(fn {row, index} ->
        SettingsList.row(
          SettingsList.icon_tile(row.glyph),
          SettingsList.body(row.title, row.detail),
          # Bare, not through `SettingsList.trailing/1`: `row/4` wraps whatever
          # it is handed, and wrapping it twice nests two Rows and doubles the
          # drawing's 13pt gap to 24. See the moduledoc.
          SettingsList.chevron(),
          on_tap: {self(), row.tag},
          rule: index < last
        )
      end)

    SettingsList.card(rows)
  end

  @doc false
  @spec handle_tap(atom(), term()) :: {:noreply, term()}
  # Through 104's own handler rather than past it. Both boards' primaries mean
  # the same thing — make a goal — so there is one definition of where that
  # lands, and the empty state cannot quietly start opening a different screen
  # from the disc that replaces it.
  def handle_tap(:add, socket), do: Kati.Screens.Goals.handle_tap(:add, socket)

  def handle_tap(:open_books, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Books)}

  # Screen, not Films: `Kati.Screens.Library` is the shelf that holds them, and
  # the row's own noun is `films` because that is the goal kind being counted.
  def handle_tap(:open_films, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Library)}

  def handle_tap(:open_albums, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Music)}

  # Reported, not swallowed — the catch-all `Kati.Screens.Pushed` refuses to
  # build in, written out here so a row added to `@counted` without a clause
  # names itself in the log instead of going quiet.
  def handle_tap(tag, socket), do: Kati.Screens.Root.unhandled_tap(__MODULE__, tag, socket)
end
