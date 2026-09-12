defmodule Kati.Screens.SearchResultStates do
  @moduledoc """
  Screen 89 — the four result states screen 19 cannot draw, on one sheet pushed
  under Settings.

  Screen 19 is the canonical mixed view: one query, four kinds of answer, every
  group holding something. That is the only shape it has, and it is the shape
  that hides these four. A scope with nothing in it, a query that matches
  nowhere at all, a hit that turns out to be in some *other* scope, and a device
  with no radio are answers the mixed view has no room to be wrong about,
  because it only ever draws what matched. So they are drawn here, as a
  reference sheet in screen 27's manner — four pictures of a screen you go and
  look at rather than something the app puts in front of you — which is why it
  carries a back pill, as 27 and 67 do.

  ## Seven zeroes are the answer, and it takes three count colours to say so

  The first band is the delicate one. `quinoa` matches three meals and nothing
  else, so seven of the eight chips carry a `0`, and seven zeroes in a row is
  exactly what a broken index looks like. Screen 86 refused to draw even eight
  *blank* chips on open for the same reason — *eight zeroes on open would read
  as an empty app* — and withheld the counts until a query existed. This is the
  other half of that decision: once a query exists the counts go on, zeroes
  included, because a scope the query genuinely did not reach is a fact the user
  asked for. The chips are the receipt for the seven counted queries
  `Kati.Search.Sample.counts_note/0` says every fire costs.

  What keeps that from reading as failure is `count_color/2`, and it needs three
  values where screen 19's chip has two:

    * **a zero takes `Palette.rail_idle/0`** — the hairline grey the design uses
      for a mark that is present but not addressed. A zero is a completed
      measurement of nothing, so it is drawn at the weight of punctuation.
    * **a live count on an unlit chip takes `Palette.muted/0`** — `#A9A29A`,
      one step up, so `All 3` and `Screen 3` are the only figures on the row
      that resolve into numbers when you scan it.
    * **any count on the lit chip takes `Palette.on_ink_count_soft/0`**, because
      it is on ink and has to invert with its pill; the ink fill is what says
      *selected*, not the figure inside it.

  The board's caption calls the middle one *tertiary*, and the token named
  `Palette.tertiary/0` is `#B3ACA2` — a different grey eleven units away. The
  design draws two faint greys and the caption's word is the role rather than
  the token, so the value wins and this paragraph carries the discrepancy, the
  way `Kati.UI.SettingsList.chevron/0` carries its own.

  **The active chip is `Meals`, the one with results.** Landing on a scope that
  has nothing would make the page argue with itself — an ink pill over an empty
  list — and the third band is where that reading is drawn on purpose.

  The zeroes stay where they are because `Kati.Search.chip_keys/0` fixes the
  order: screen 88's own rule is that relevance-sorted groups move the target
  every keystroke. Only the numbers live here, so a ninth scope arrives on this
  sheet from the domain module rather than from a literal typed into it.

  ## The third band is the first band's opposite

  `Calendar` is lit with a `0` while `Screen` holds three, and the card under it
  offers the move rather than describing the emptiness. That is why the empty
  scope is not simply an empty list: the sheet's claim is that Kati knows where
  the answer went, and the only band on the page that can prove it is one where
  the lit chip is the wrong chip.

  ## Two eyebrows' worth of colour, and one of them is orange

  The first band takes `Kati.UI.eyebrow/2`'s accent dash and the other three
  take 27's grey. That follows 19's positional rule rather than 27's — on a
  search page orange marks *this is the hit*, and the first band is the one the
  sheet was drawn to argue about. Nothing else here is new or now.

  ## What is reused, and the three places the board and 19 disagree

  The field is `Kati.Screens.Search.field/2` at `live?: false`, called twice with two different
  queries. The ink ring, the 2pt orange caret and the filled `cancel` glyph are
  19's own, so a change to the field arrives on this sheet the next time it
  renders and the comparison cannot quietly go stale — which is the whole reason
  a states sheet is worth having. The count figure is
  `Kati.Screens.Search.chip_count/2`, whose colour was already the caller's to
  decide, which is precisely the axis this screen varies.

  Where the two differ, 19 wins, for 67's reason — a sheet that redrew a shared
  node its own way would report a difference the app does not have:

    * **the field carries its own 18pt tail** where the board writes 11, twice.
    * **the count sets at 10.5** where the board writes 10. Half a point on a
      mono figure, against one definition of a counted chip everywhere.
    * **the subtitle sets in mono at 11** where the board writes 13.5 sans,
      because `Kati.UI.SettingsList.title/3` is what every pushed screen's
      header is. Screen 67 has the same disagreement and resolves it the same
      way.

  ## The chip is markup rather than a component call, and the pill is why

  `Kati.UI.chip/2` and `Kati.Screens.Search.chip/3` both resolve the count
  colour themselves, in two states, so neither can express the third — and both
  build on `Kati.Components.MishkaChip`, which has no `shadow` prop. This
  board's unlit chips are lifted off the page with `Kati.Theme.shadow_card_soft/0`
  and the lit one is not, which is a distinction the component cannot draw at
  all. So the pill is a `Row` here, at the board's 30/15/13 rather than 19's
  32/16/14, and the count node is still 19's.

  ## Two things this sheet had stopped being able to say in Persian

  Both arrived with `mishka-group/kati#103`, both were invisible in English,
  and both are the same shape: a fact about the English *sentence* standing in
  for a fact about the *screen*.

    * **Which chip is lit** was `label == active` against the literal `Meals`.
      `Kati.Search.scope_label/1` answers `وعده‌ها` under `:fa`, so the
      comparison failed on all eight chips and the page drew no ink pill at
      all — which is the one reading neither the first band nor the third
      survives, since both of them are arguments about *where the pill is*.
      `chips/2` takes the scope KEY now, which is what
      `Kati.Screens.Search.chip/4` identifies a chip by and what does not
      translate.
    * **Where the matched word sits inside a hit** was three runs typed out.
      `Quinoa bowl` matches at the head of its title and `کاسهٔ کینوا` matches
      at the tail, so a typed split sets the wrong half of the Persian row in
      bold — it reports that the query found `کاسهٔ`. `split_match/2` finds the
      word in whichever sentence it is handed.

  ## Nothing here reads a store, and nothing here taps

  27's argument applies unchanged: each band is a picture of a state, not a
  report that the app is in it. `Offline` is a condition of the radio and is
  drawn whether or not it is true. The counts are counts of a query nothing can
  run — `Kati.Screens.Search`'s moduledoc sets out at length why there is no
  index yet, and a sheet about what a *result* looks like is even further from
  one than the mixed view is.

  No control carries a tap, so `Kati.Screens.Pushed` defines no `handle_tap/2`
  here and none of the sixteen chips, the two hits, `Search TMDB` or the
  cross-scope card reports a dead tag.
  """

  use Kati.Screens.Pushed, back: "Settings"
  use Gettext, backend: Kati.Gettext

  alias Kati.Screens.Search, as: SearchScreen
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  @impl true
  def load(socket) do
    Mob.Socket.assign(socket, :states, %{
      in_scope: in_scope(),
      elsewhere: elsewhere_chips(),
      hits: hits()
    })
  end

  @doc """
  Every scope chip, in `Kati.Search`'s fixed order, with the counts this sheet
  gives them.

  A scope absent from `counts` is a zero rather than a missing chip, which is
  the whole subject of the first band: the eight chips are the same eight chips
  whatever the query matched, and a scope that did not answer says so by
  carrying a number. Reading the labels from `Kati.Search.scope_label/1` rather
  than typing them keeps screen 88's order — Screen, Books, Music, Calendar,
  Meals, Money, Notes — as the one place it is written down, and it is also the
  one place they are translated: every label here is a `pgettext/2` off
  `Kati.Search.scopes/0`.

  The KEY travels beside the label, in `Kati.Screens.Search.chip/4`'s shape.
  `chips/2` lights a chip by comparing it, and a chip cannot be identified by a
  word that changes with the reader's language — see there.
  """
  @spec counted(%{optional(atom()) => non_neg_integer()}) ::
          [{atom(), String.t(), non_neg_integer()}]
  def counted(counts) do
    Enum.map(Kati.Search.chip_keys(), fn key ->
      {key, Kati.Search.scope_label(key), Map.get(counts, key, 0)}
    end)
  end

  @doc """
  The first band's chips: `quinoa` found three meals and reached nowhere else.

  `All` and `Meals` agree at 3 because there is one scope holding anything —
  `All` is the sum, and a sum with one non-zero term is that term.
  """
  @spec in_scope() :: [{atom(), String.t(), non_neg_integer()}]
  def in_scope, do: counted(%{all: 3, meals: 3})

  @doc """
  The third band's chips: the lit scope is empty and `Screen` holds the three.

  The same eight chips and the same total as `in_scope/0`, moved one scope
  along, so the two rows differ in exactly the thing the band is about.
  """
  @spec elsewhere_chips() :: [{atom(), String.t(), non_neg_integer()}]
  def elsewhere_chips, do: counted(%{all: 3, screen: 3})

  @doc """
  The query the first two bands are drawn over.

  One function rather than the word typed in three places, because it is drawn
  in three: the field above the rows, and the marked run inside each of them.
  Three literals would let a translator move one of them, and a hit whose bold
  run is not the word in the field above it is a picture of a search that did
  not happen.

  `pgettext/2` at one word. `quinoa` is short enough for `mix gettext.merge` to
  fuzzy-match onto a neighbour, and `Chicken, quinoa, slaw` is sitting in the
  catalogue for it to reach.
  """
  @spec query() :: String.t()
  def query, do: pgettext("search query", "quinoa")

  @doc """
  The two meal hits, split at the matched run.

  `lead`, `match` and `tail` rather than a finished title, because the board
  sets the matched word in bold inside the line and the two rows match it in
  different places — mid-sentence in one, at the head of the title in the other.
  Storing the split is what lets `hit_title/1` name which word matched even
  though the bridge cannot draw it; see there.

  The three runs are SPLIT OUT of the translated title rather than typed, which
  `split_match/2` is the argument for: which of the three a word falls in is a
  fact about the sentence, and the sentence changes with the language.

  The meal is `Kati.Meals.SampleToday`'s own lunch and carries its msgid, so
  the sheet draws the app's lunch rather than a second one worded differently;
  its two meta lines are built from `Lunch` and `Cutting v3`, which are in the
  catalogue for the same reason. `%{n} meals` is `ngettext/4` even though the
  figure is fixed at 6 — English inflects the noun after a numeral and Persian
  does not, so the plural is the app's shared answer rather than this sheet's.
  """
  @spec hits() :: [
          %{
            icon: String.t(),
            lead: String.t(),
            match: String.t(),
            tail: String.t(),
            sub: String.t()
          }
        ]
  def hits do
    matched = Kati.Screens.SearchResultStates.query()

    [
      Map.merge(
        %{icon: "restaurant", sub: gettext("Lunch") <> " · " <> gettext("Cutting v3")},
        split_match(gettext("Chicken, quinoa, slaw"), matched)
      ),
      Map.merge(
        %{
          icon: "restaurant",
          sub:
            pgettext("meal search result", "Ingredient") <>
              " · " <> ngettext("%{n} meal", "%{n} meals", 6, n: Kati.Locale.number(6))
        },
        split_match(gettext("Quinoa bowl"), matched)
      )
    ]
  end

  # Where the matched word sits inside a title, as `hit_title/1`'s three runs.
  #
  # Derived rather than typed, and that is a fix rather than a tidy-up. The
  # board writes the two rows as `Chicken, |quinoa|, slaw` and `|Quinoa| bowl`
  # — the match mid-sentence in one and at the head of the other — and those
  # two positions are a fact about ENGLISH. `کاسهٔ کینوا` matches at the tail,
  # so the typed split set `کاسهٔ` in bold and left the word the query actually
  # found in plain weight: the one fact `hit_title/1` says a result row exists
  # to carry, reported wrongly, on the band drawn to show a correct one.
  #
  # Deriving also keeps each title as ONE msgid. `Chicken, quinoa, slaw` is
  # already in the catalogue off `Kati.Meals.SampleToday`, where `"Chicken, "`
  # and `", slaw"` would be two new fragments — short enough for
  # `gettext.merge` to fuzzy-match onto somebody else's sentence, and neither
  # of them a phrase a translator could do anything with.
  #
  # Case-insensitively, because the query is `quinoa` and the second title
  # opens with `Quinoa`; Persian has no case, so it costs nothing there and
  # this is what a real highlighter would do anyway. A title whose translation
  # does not contain the word at all draws in one weight rather than raising: a
  # missing emphasis is a smaller failure than a sheet that will not render.
  @spec split_match(String.t(), String.t()) :: %{
          lead: String.t(),
          match: String.t(),
          tail: String.t()
        }
  defp split_match(title, match) do
    lowered = String.downcase(title)

    # The offsets come off the downcased copy and are applied to the original,
    # so a string that changes LENGTH when downcased would be sliced
    # mid-character. Guarding on the byte size is cheaper than mapping the
    # offsets back, and the answer when it fails is the no-emphasis one either
    # way.
    case match != "" and byte_size(lowered) == byte_size(title) and
           :binary.match(lowered, String.downcase(match)) do
      {at, length} ->
        %{
          lead: binary_part(title, 0, at),
          match: binary_part(title, at, length),
          tail: binary_part(title, at + length, byte_size(title) - at - length)
        }

      _unmatched ->
        %{lead: title, match: "", tail: ""}
    end
  end

  @doc false
  @spec content(map()) :: map()
  def content(assigns) do
    s = assigns.states

    # The page's whole copy resolved above the sigil, which is how
    # `Kati.Screens.States.content/1` arranges its own five bands and for the
    # same reason: the four eyebrows are read against each other, and a ~MOB
    # block is the wrong place to compare four labels.
    #
    # Two of them take a context, and both would have gone wrong quietly.
    # `Search results` is two words with a bare `Search` and a `%{n} results`
    # plural already in the catalogue for `gettext.merge` to fuzzy-match it
    # onto; `four edge states` sits beside `Two states`, `Eight states` and
    # `Five states, three media`, every one of them another reference sheet's
    # subtitle. Nothing on this screen is asserted against a string, so a sheet
    # headed **هشت حالت** is a wrong word no test here would catch.
    title = pgettext("screen title", "Search results")
    subtitle = pgettext("screen subtitle", "four edge states")
    first_band = gettext("One scope only — seven zeroes are not a fault")

    # Not a typed `Meals · 3`. The word is the chip's own, so the eyebrow and
    # the lit pill under it cannot come out in two vocabularies, and the figure
    # goes through `Kati.Locale.number/1`, which is what
    # `Kati.Screens.Search.chip_count/2` puts the eight figures under the
    # eyebrow through. It is the same 3 `in_scope/0` gives the Meals chip, and
    # the audit could not see it: a bare numeral carries no Latin letters.
    found_band = Kati.Search.scope_label(:meals) <> " · " <> Kati.Locale.number(3)

    nothing_band = gettext("No results anywhere")
    elsewhere_band = gettext("Nothing in this scope, something elsewhere")

    # The eyebrow over a badge that opens with the same word. `pgettext/2`
    # because a bare `Offline` is one word, and this is the entry screens 70
    # and 80 have already put in the catalogue for their own copies of it.
    offline_band = pgettext("the device has no network", "Offline")

    matched = Kati.Screens.SearchResultStates.query()

    # The query that matched nowhere. A Persian word rather than a
    # transliteration of `vellichor`: the band's claim is that a real query
    # reached eight scopes and came back with nothing, and a reader cannot read
    # a string of Latin letters they would never type as the query they just
    # ran. It goes to the field and to both of `nothing/2`'s sentences from one
    # place, because those three are one query.
    missing = pgettext("search query", "vellichor")

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
        {SettingsList.title(title, subtitle, nil, :name)}
        {UI.eyebrow(first_band)}
        {SearchScreen.field(matched, false)}
        {Kati.Screens.SearchResultStates.chips(s.in_scope, :meals)}
        {SettingsList.eyebrow_muted(found_band)}
        {Kati.Screens.SearchResultStates.found(s.hits)}
        {SettingsList.eyebrow_muted(nothing_band)}
        {SearchScreen.field(missing, false)}
        {Kati.Screens.SearchResultStates.nothing(missing)}
        {SettingsList.eyebrow_muted(elsewhere_band)}
        {Kati.Screens.SearchResultStates.chips(s.elsewhere, :calendar)}
        {Kati.Screens.SearchResultStates.cross_scope()}
        {SettingsList.eyebrow_muted(offline_band)}
        {Kati.Screens.SearchResultStates.offline()}
      </Column>
    </Scroll>
    """
  end

  @doc """
  The eight counted chips, in one horizontally scrolling row.

  The board clips the row at the frame's edge rather than scrolling it, because
  a drawing cannot scroll; screen 86 renders the same row as a horizontal
  `Scroll` and this follows it, so `Notes` is reachable rather than merely
  drawn. Nothing wraps to a second line — there is no wrapping primitive on this
  bridge, and eight chips broken across two rows would stop reading as one
  answer to one query.

  `active` is passed rather than carried on the chips: which scope is lit is the
  thing each band varies, and a fixture that stated it would let the two rows
  disagree about how many chips can be lit at once.

  It is a scope KEY and not a label, and that is a fix rather than a rename.
  This was `label == active` against the literal `"Meals"` — the word
  `Kati.Search.scope_label/1` answers in English and `وعده‌ها` in Persian — so
  under `:fa` the comparison failed on all eight chips and the page drew no ink
  pill at all. Both bands that use this row are arguments about where the pill
  is: the first says it sits on the scope with the results, the third that it
  sits on a scope without them, and neither survives a row with nothing lit.
  `Kati.Screens.Search.chip/4` takes the key beside the label for the same
  reason, and `Kati.Search.built?/1`'s note is the long form of it — the key is
  what identifies a scope, the label is what draws it.
  """
  @spec chips([{atom(), String.t(), non_neg_integer()}], atom()) :: map()
  def chips(chips, active) do
    row =
      chips
      |> Enum.map(fn {key, label, count} ->
        Kati.Screens.SearchResultStates.chip(label, count, key == active)
      end)
      |> Enum.intersperse(SearchScreen.gap())

    ~MOB"""
    <Column fill_width={true}>
      <Scroll axis="horizontal">
        <Row align="center">
          {row}
        </Row>
      </Scroll>
      <Spacer size={11} />
    </Column>
    """
  end

  @doc """
  One counted scope chip: 30 tall, radius 15, label then a 6pt gap then the
  figure.

  A `Row` rather than `Kati.Components.MishkaChip`, for a reason the moduledoc
  sets out and this is the short form of: the component takes no `shadow`, and
  on this board the unlit chips are lifted off the page while the lit one sits
  flat on its own ink. The lift is what makes seven quiet chips read as seven
  *objects* rather than as a grey smear behind the one that is selected, so it
  is not decoration that could be dropped to keep the component call.

  The count node is `Kati.Screens.Search.chip_count/2` — the same mono figure
  screen 19 draws, taking the same caller-supplied colour. Only `count_color/2`
  is this screen's.
  """
  @spec chip(String.t(), non_neg_integer(), boolean()) :: map()
  def chip(label, count, on?) do
    background = if on?, do: Palette.ink_fill(), else: Palette.card()
    ink = if on?, do: Palette.on_ink(), else: Palette.ink_soft()
    # A lit chip is flat: its ink fill already lifts it off paper, and a shadow
    # under it would read as a second, heavier object on a row of eight.
    shadow = if on?, do: nil, else: Kati.Theme.shadow_card_soft()

    ~MOB"""
    <Row
      height={30}
      corner_radius={15}
      background={background}
      shadow={shadow}
      padding_left={13}
      padding_right={13}
      align="center"
    >
      <Text text={label} text_size={12.5} font_weight="semibold" text_color={ink} max_lines={1} />
      <Spacer size={6} />
      {SearchScreen.chip_count(count, Kati.Screens.SearchResultStates.count_color(count, on?))}
    </Row>
    """
  end

  @doc """
  Which of the three greys a chip's figure takes.

  The one rule this whole sheet was drawn to fix, so it is a function with a
  name rather than two `if`s inside the chip:

    * on the lit chip the figure is on ink and inverts with it, whatever it
      says — the pill carries the selection, not the number;
    * a zero on an unlit chip is a finished measurement of nothing, drawn at
      `Palette.rail_idle/0`, the weight the design gives punctuation;
    * anything else is `Palette.muted/0`, one step up, so the figures that
      resolve into numbers on a scan are the ones you can act on.

  Deriving the zero case from the count rather than from a flag is deliberate:
  there is no state in which a chip should claim `0` at full strength, so there
  is nowhere for a caller to get it wrong.
  """
  @spec count_color(non_neg_integer(), boolean()) :: pos_integer()
  def count_color(_count, true), do: Palette.on_ink_count_soft()
  def count_color(0, false), do: Palette.rail_idle()
  def count_color(_count, false), do: Palette.muted()

  @doc """
  The two hits the lit scope holds.

  Each row carries its own trailing 9pt rather than the list interspersing one —
  27's skeleton arrangement, and screen 19's for the same rows — so the 13 added
  here lands on the last row's 9 and makes the board's 22 under the group.
  """
  @spec found([map()]) :: map()
  def found(hits) do
    ~MOB"""
    <Column fill_width={true}>
      {Enum.map(hits, fn hit -> Kati.Screens.SearchResultStates.hit(hit) end)}
      <Spacer size={13} />
    </Column>
    """
  end

  @doc """
  One result row: the scope's glyph on a paper tile, the hit, and a chevron.

  Not `Kati.Screens.Search.title_row/1`, and the difference is the leading
  slot. A Screen hit leads with its own artwork, so 19 draws a 36x51 poster; a
  meal has no poster and never will, so the board gives it the 40pt paper tile
  the settings lists use for a glyph. Swapping one for the other would have
  meant either a poster-shaped hole beside every meal or 19's titles losing
  their covers.

  The second line is `Palette.muted/0` where 19's is `Palette.sub/0` — one step
  lighter, because on this row the meta is a location (`Lunch · Cutting v3`)
  rather than a description, and the board draws it as the quieter of the two.
  """
  @spec hit(map()) :: map()
  def hit(hit) do
    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Palette.card()}
        corner_radius={18}
        shadow={Kati.Theme.shadow_card_soft()}
        padding_left={13}
        padding_right={13}
        padding_top={11}
        padding_bottom={11}
        align="center"
      >
        <Box width={40} height={40} corner_radius={12} background={Palette.paper()} align="center">
          {UI.symbol(hit.icon, size: 19, color: Palette.ink_soft())}
        </Box>
        <Spacer size={12} />
        <Column weight={1.0}>
          {Kati.Screens.SearchResultStates.hit_title(hit)}
          <Spacer size={4} />
          <Text text={hit.sub} text_size={11.5} text_color={Palette.muted()} max_lines={1} />
        </Column>
        <Spacer size={12} />
        {SettingsList.chevron()}
      </Row>
      <Spacer size={9} />
    </Column>
    """
  end

  @doc """
  The hit's title with the matched word marked, through `Kati.UI.rich_text/1`.

  The board sets the match in bold inside the running title, and this bridge has
  no `AnnotatedString` — `Kati.UI.rich_text/1` is the shared answer to exactly
  that, and it concatenates the runs and applies one style, so the emphasis is
  dropped rather than orphaned onto a line of its own. It is used here anyway,
  rather than a plain `Text` over the joined string, because the runs record
  **which word matched** in the source. That is the one fact a search result row
  exists to carry, and the day the bridge grows a `runs` prop this row starts
  drawing it without anybody having to find it again.

  The lead run is the base even when it is empty — `Quinoa bowl` matches at the
  head — so the row's own 13.5pt semibold is what the whole line takes, not the
  bold of the match.
  """
  @spec hit_title(map()) :: map()
  def hit_title(hit) do
    base = [
      text_size: 13.5,
      font_weight: "semibold",
      text_color: :on_surface,
      base: true
    ]

    UI.rich_text([{hit.lead, base}, {hit.match, :bold}, {hit.tail, base}])
  end

  @doc """
  The query that matched nowhere, and the one thing left to offer.

  Screen 27's empty card at this screen's metrics — a 52pt tile rather than 64,
  a 14.5pt headline rather than 17, 17 of padding rather than 22 and 30 — the
  same relationship screen 67's alert pair has to 27's. Calling
  `Kati.Screens.States.empty/1` would have drawn a card a third taller than the
  board's between two search fields, which is a states sheet reporting a
  difference the app does not have in the opposite direction.

  The copy is the part that had to be this screen's own, and it is the reason
  the band exists. `Kati.Search`'s scopes are all things you keep, so an empty
  result is not a failure to find — it is a correct report that you do not have
  it, and the sentence says so before offering the lookup. The `add` pill goes
  outward to TMDB and the line under it goes to the manual path, in that order,
  because a title Kati has never heard of is likelier to be findable than to be
  worth typing out.
  """
  @spec nothing(String.t(), keyword()) :: map()
  def nothing(query, taps \\ []) do
    # The sigil is uppercase, so `#{}` inside it is literal text and both
    # sentences have to be built out here — as bindings now rather than as
    # `<>`, which is the difference that matters. The quotation marks stay
    # INSIDE the msgid, and `Kati.Screens.AddTitle.found_nothing/1` is where
    # that was decided at length: a Persian translator swaps `“…”` for the
    # guillemets `«…»` in the same edit that writes the words, and cannot if
    # the marks are concatenated out here. The first sentence is that screen's
    # own msgid character for character — two sheets that say one thing in
    # English may not say two things in Persian — so this band arrives already
    # translated.
    #
    # `query` is deliberately NOT wrapped in `Kati.Locale.ltr/1`, for the
    # reason that call site gives. The live caller is
    # `Kati.Screens.Search.no_matches/1` and the value is then the reader's own
    # text, which can be in either script; isolating a Persian query as a
    # left-to-right run would mirror the exact defect that helper exists to
    # fix. A Latin query needs no isolate here anyway — the sentence's own
    # quotation marks bound it on both sides, so it strands no trailing neutral
    # at the wrong edge.
    #
    # `TMDB` stays Latin inside the Persian sentence: it is the service's name
    # for itself, and board 127's `Lumen+` is the standing rule.
    title = gettext("Nothing here for “%{query}”", query: query)
    action = gettext("Search TMDB for “%{query}”", query: query)

    body =
      gettext(
        "Kati only searches what you keep. If it is a title you have not added yet, look it up."
      )

    by_hand = gettext("or add it by hand")

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding_left={17}
        padding_right={17}
        padding_top={23}
        padding_bottom={23}
      >
        <Row fill_width={true} align="center">
          <Spacer weight={1.0} />
          <Box width={52} height={52} corner_radius={16} background={Palette.paper()} align="center">
            {UI.symbol("search", size: 24, color: Palette.rail_idle())}
          </Box>
          <Spacer weight={1.0} />
        </Row>
        <Spacer size={14} />
        <Text
          text={title}
          text_size={14.5}
          font_weight="bold"
          letter_spacing={Kati.Locale.tracking(-0.02)}
          text_color={:on_surface}
          text_align="center"
        />
        <Spacer size={7} />
        <Text
          text={body}
          text_size={12.5}
          line_height={Kati.Locale.leading(1.55)}
          text_color={Palette.sub()}
          text_align="center"
        />
        <Spacer size={16} />
        <Row
          fill_width={true}
          height={44}
          corner_radius={22}
          background={Palette.ink_fill()}
          align="center"
          on_tap={taps[:lookup]}
        >
          <Spacer weight={1.0} />
          {UI.symbol("add", size: 18, color: Palette.on_ink())}
          <Spacer size={7} />
          <Text
            text={action}
            text_size={13}
            font_weight="bold"
            text_color={Palette.on_ink()}
            max_lines={1}
          />
          <Spacer weight={1.0} />
        </Row>
        <Spacer size={13} />
        <Box fill_width={true} on_tap={taps[:by_hand]}>
          <Text
            text={by_hand}
            text_size={12.5}
            font_weight="semibold"
            text_color={Palette.sub()}
            text_align="center"
          />
        </Box>
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  Nothing in the lit scope, three matches in another — and the way over.

  One row rather than an empty state, and that is the argument the band makes:
  the page already knows where the answer is, so telling the user their scope is
  empty and stopping would be withholding it. `swap_horiz` leads because the
  offer is a change of scope rather than a new query, and the forward arrow
  closes it because tapping moves you rather than expanding anything in place —
  `Kati.Locale.forward_glyph/0`'s arrow, which points the way the reader is
  going in either script rather than the way the glyph is drawn.

  Both halves of the sentence are `Kati.Screens.Search.cross_scope/2`'s own
  msgids, with the two scopes named through `Kati.Search.scope_label/1` and the
  figure through `Kati.Locale.number/1`. The wired row and its picture may not
  word this differently, which is the whole reason a states sheet is worth
  having — and the trailing space in `Nothing in %{scope}. ` is that msgid's,
  not a typo here: `Kati.UI.rich_text/1` concatenates the runs and something
  has to hold the gap between the two.
  """
  @spec cross_scope() :: map()
  def cross_scope do
    # `Kati.Locale.forward_glyph/0` rather than the literal. The glyph closes a
    # row that MOVES you, and an arrow is a picture: `layout_direction` mirrors
    # the row and leaves the arrow pointing back the way the reader came.
    # `Kati.Screens.Search.cross_scope/2` still writes `arrow_forward` and
    # should follow — it is one line, and it is that screen's to change.
    assigns = %{
      lead: gettext("Nothing in %{scope}. ", scope: Kati.Search.scope_label(:calendar)),
      over:
        ngettext("%{n} match in %{scope}", "%{n} matches in %{scope}", 3,
          n: Kati.Locale.number(3),
          scope: Kati.Search.scope_label(:screen)
        ),
      forward: Kati.Locale.forward_glyph()
    }

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
        {UI.symbol("swap_horiz", size: 19, color: Palette.ink_soft())}
        <Spacer size={12} />
        <Column weight={1.0}>
          {UI.rich_text([
            {@lead, [text_size: 13, text_color: :on_surface, base: true]},
            {@over, :bold}
          ])}
        </Column>
        <Spacer size={12} />
        {UI.symbol(@forward, size: 17)}
      </Row>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  Offline, and searching anyway.

  27's cream badge at 67's metrics — radius 20 and 15 of padding — and with no
  shadow, which is 27's own distinction: a condition the app is in is not an
  object lifted off the page.

  The sentence is this screen's because the promise is. Every scope
  `Kati.Search` lists is local, so losing the radio costs nothing a search can
  see; the one thing it does cost is the TMDB lookup the band above offers, and
  the second line names that rather than reassuring in general. Two lines is the
  measured wrap for it at 11.5pt across this card and three is Persian's, which
  `Kati.Locale.pick/2` is for — Vazirmatn is wider than Plus Jakarta at a size
  and the sentence is a claim rather than a label, so cut short it stops being
  the promise it is here to make. `Kati.Screens.LogProgressStates.offline_undo/0`
  found the same thing on the same badge and its comment is the long form.
  """
  @spec offline() :: map()
  def offline do
    # The title and the eyebrow above it are two msgids and not one, which is
    # the opposite of screen 70's arrangement and is right here: 70's eyebrow
    # and badge say the same word about the same condition, and these two do
    # not — the eyebrow names the state and the badge says what survives it.
    assigns = %{
      title: gettext("Offline — still searching"),
      line: gettext("Everything you keep is on this device. Only looking up new titles waits."),
      lines: Kati.Locale.pick(2, 3)
    }

    ~MOB"""
    <Row
      fill_width={true}
      background={Palette.cream()}
      corner_radius={20}
      padding={15}
      align="center"
    >
      {UI.symbol("cloud_off", size: 20, color: Palette.gold_icon())}
      <Spacer size={12} />
      <Column weight={1.0}>
        <Text
          text={@title}
          text_size={13}
          font_weight="bold"
          text_color={:on_surface}
          max_lines={1}
        />
        <Spacer size={3} />
        <Text text={@line} text_size={11.5} text_color={Palette.cream_sub()} max_lines={@lines} />
      </Column>
    </Row>
    """
  end
end
