defmodule Kati.Screens.EpisodeRatings do
  @moduledoc """
  Screen 04, Edit 1 — the episode row gains a trailing rating column.

  Built to `.scratch/design/incoming/143.html`. Not a change to
  `Kati.Screens.Series` — the board draws three specimen bands under one back
  pill labelled `Library`, in the manner of `Kati.Screens.SearchResultStates`:
  a sheet you go and look at to settle what an edit looks like in every state
  it has, rather than something the app puts in front of you on its own. So
  this is its own module, pushed the same way, rather than a patch to the
  screen it is an edit of.

  ## The column is a numeral and ONE star, never five

  The board's own caption: *"A numeral plus one star, in DM Mono, so the
  column aligns — nobody reads five small stars, they read a shape."* Five
  glyphs at this size (E1's row is 12px DM Mono) would not read as a rating;
  they would read as a smear of dots, and the column would stop aligning
  because a half-lit fifth star is a different width than a lit one. One
  filled `star` glyph beside the number is the whole of it —
  `Kati.UI.symbol("star", size: 11, color: Palette.accent(), fill: true)` —
  and the numeral carries the precision the glyph cannot: `4.5`, `5`, `3.5`.
  `rating_label/1` is the one place that turns a half-integer into that
  numeral, dropping the trailing `.0` a whole rating would otherwise carry
  (`5.0` reads as a typo; `5` reads as five).

  ## An unrated watched episode draws nothing, not five hollow stars

  The board's other half of the same caption: *"An unrated watched episode
  shows nothing at all, not five hollow stars, which is what lets the ratings
  stand out."* `rating_node/1` answers `[]` for `nil`, the same
  list-flattening move `Kati.Screens.Series.next_air/1` makes for a series
  with nothing announced — the sigil flattens an interpolated list into its
  parent, so an unrated row gets the same two nodes (title column, check) in
  the same 13pt gap the rated rows put a rating between, rather than a hollow
  placeholder holding a gap open. E2 and E5 in the first band exercise this
  inside a band that is mostly rated, which is the harder case: the column
  has to stay aligned on the rows that DO carry a numeral while contributing
  nothing on the rows that do not, and a `Row`'s children space themselves by
  what is actually there, not by a reserved slot.

  ## `None rated` has no column at all, band-wide

  The second band is not the first band with every rating blanked — it is
  the case where NOTHING in the season has been rated yet, stated as its own
  eyebrow: *"no column at all."* Both of its rows call `rating_node(nil)`,
  the identical function the first band's blank rows call; the distinction
  the board is making is about the season, not the row, and one function
  answering `[]` twice is what keeps that true rather than asserted.

  ## Where a rating actually lives, and why this sheet does not read it

  `Kati.Media.Watch.rating` is the resource this column will eventually
  read — a ten-point integer, the same scale screen 33 already halves for its
  own stars (*"Ten-point scale, as on TrackedTitle: screen 33's 4.5 stars is
  9"*) and per-episode via `episode_source_id`. But this board, like
  `Kati.Screens.SearchResultStates` before it, is a picture of a state rather
  than a report that the app is in one: every number on it is the specimen
  the design was captured with, not a query. Wiring the column to
  `Watch.for_episode/2` belongs to `Kati.Screens.Series` itself, on the day
  the rating column ships there — this sheet exists to settle what it looks
  like first.

  ## Where this disagrees with `Kati.Screens.Series.check/2` and `episode/1`,
  and why the board wins

  `Kati.Screens.Series` already draws three episode states, and this board's
  up-next row (E6, not watched, not yet aired) does not match either of the
  two it would fall into there:

    * **The title.** `Series.episode/1` mutes a not-yet-aired title to
      `Palette.sub/0`, same as a watched one. This board's E6 is full ink
      (`#1A1917`) — the row that is coming up next reads as the loudest title
      in the list, not a quiet one, and its five watched siblings take a
      different mute, `Palette.settled_ink/0` (`#9C958B`), a token
      `Series.episode/1` does not use at all. Two greys where the canon has
      one; the board's own colours win here rather than the canon's, because
      the whole reason this board exists is to be looked at pixel for pixel.
    * **The check.** `Series.check/2`'s not-yet-aired state is `check(false,
      false)` — a bare `Spacer`, no ring drawn. The board draws a ring:
      `border: 1.5px solid rgba(26,25,23,.16)` around a `check` glyph painted
      at alpha 0. `Palette.border/0` is that exact 16%-ink token (already the
      dashed-note border below, and `add_title.ex`'s `by_hand/0` before it)
      and `Palette.ink_invisible/0` is that exact "drawn, but at zero alpha"
      token — both already named for precisely this, so nothing here is
      invented to reach it. Visually the two states are close to
      indistinguishable (a hairline ring and an invisible glyph read as
      nothing, the same as nothing at all), which is likely why the drift
      went unnoticed; this sheet reproduces the board's own construction
      rather than silently reusing `Series.check/2`'s, and records the gap
      here instead of resolving it — that fix, if the two are meant to
      converge, belongs to `Kati.Screens.Series`.

  Both of the states this board exercises are `check(true)` and
  `check(false)` here — there is no third, `Series`'s aired-but-unwatched
  ring, because nothing on this board is in that state to draw.

  ## The dashed note, solid

  `1.5px dashed rgba(26,25,23,.16)` in the design, same as `add_title.ex`'s
  `by_hand/0`: the bridge draws only solid borders, so the dash is the one
  thing here that is not the drawing — the colour, `Palette.border/0`, is.

  Its body carries two bold spans — `one` and `nothing at all` — which is
  the same shape `Kati.UI.rich_text/1` exists for and the same reason
  `Kati.Screens.SearchResultStates.hit_title/1` reaches for it over a plain
  `Text`: the runs record which two words the design means to land hardest,
  even though `Kati.UI`'s own doc is explicit that the bridge has no
  `AnnotatedString` and renders every run at one style today. The semantics
  survive in the source; the emphasis does not yet survive on the device.

  ## The long-press hint dismisses for the session, not for good

  The board's own line: *"Shown once, then dismissed for good."* `Got it`
  here sets `:hint_visible?` to `false` on this screen's assigns, which is
  real — the card leaves the layout, its 14pt of trailing space with it,
  exactly the way `Kati.Screens.Money`'s advice card and
  `Kati.Screens.ArtistDetail`'s unheard-release card dismiss. It is not,
  per `Kati.Screens.MoneyFa`'s own note on the same shape, *"a stored
  preference"*: there is nowhere in `Kati.Media` yet for "has this user seen
  the long-press hint" to live, so reopening this screen shows it again. That
  is the honest half of "shown once" this sheet can do without inventing a
  column nothing else reads.

  Nothing else on the board is a tap. Mob has no long-press primitive at
  all — a screen-wide grep for `long_press` finds nothing — so the gesture
  the hint describes, and the gesture the closing note names on shelf tiles,
  are both a documented intention rather than a wired affordance anywhere in
  the app yet. Recording that here is better than a `Row` with an `on_tap`
  standing in for a gesture it cannot perform.

  ## The gesture rule, recorded verbatim

  The closing cream card is the board's own memo to itself, not a control: a
  long press means one thing on a shelf tile (screen 03's selection) and a
  different thing on an episode row (this board's rating), and the two
  surfaces are unmistakably different shapes — a grid of artwork against a
  list of rows — which is the whole argument for why one gesture is safe to
  overload twice. `Also on 146` is the board's own cross-reference and is
  drawn as text, not as a link: there is nothing this screen can push to for
  a board number, and a `Row` wrapping it in an `on_tap` that goes nowhere is
  exactly the dead tap `Kati.Screens.Pushed`'s sweep exists to catch.
  """

  use Kati.Screens.Pushed, back: "Library"

  alias Kati.Theme
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  @impl true
  def load(socket), do: Mob.Socket.assign(socket, :hint_visible?, true)

  @doc """
  The first band: six episodes, ratings on three of them, none on two, and
  the up-next row carrying no rating and no watch at all.

  Literal specimen values captured from the board — see the moduledoc on why
  this sheet does not read `Kati.Media.Watch` for them.
  """
  @spec rated_episodes() :: [map()]
  def rated_episodes do
    [
      %{n: 1, title: "Low Water", sub: "54m · 9 Jul", rating: 4.5, watched: true},
      %{n: 2, title: "The Cull", sub: "49m · 16 Jul", rating: nil, watched: true},
      %{n: 3, title: "Blackthorn", sub: "52m · 23 Jul", rating: 5.0, watched: true},
      %{n: 4, title: "What the Tide Left", sub: "51m · 30 Jul", rating: 3.5, watched: true},
      %{n: 5, title: "Hollow Season", sub: "47m · 6 Aug", rating: nil, watched: true},
      %{n: 6, title: "The Undertow", sub: "55m · airs 20 Aug", rating: nil, watched: false}
    ]
  end

  @doc "The second band: two watched episodes, neither one rated, no column drawn for either."
  @spec unrated_episodes() :: [map()]
  def unrated_episodes do
    [
      %{n: 1, title: "Low Water", sub: "54m · 9 Jul", rating: nil, watched: true},
      %{n: 2, title: "The Cull", sub: "49m · 16 Jul", rating: nil, watched: true}
    ]
  end

  @doc false
  @spec content(map()) :: map()
  def content(assigns) do
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
        {Kati.Screens.EpisodeRatings.header()}
        {UI.eyebrow("Some rated — the normal case")}
        {Kati.Screens.EpisodeRatings.episode_list(Kati.Screens.EpisodeRatings.rated_episodes())}
        <Spacer size={14} />
        {Kati.Screens.EpisodeRatings.rating_note()}
        <Spacer size={24} />
        {SettingsList.eyebrow_muted("None rated — no column at all")}
        {Kati.Screens.EpisodeRatings.episode_list(Kati.Screens.EpisodeRatings.unrated_episodes())}
        <Spacer size={24} />
        {SettingsList.eyebrow_muted("The long-press hint — shown once")}
        {Kati.Screens.EpisodeRatings.hint(assigns.hint_visible?)}
        {Kati.Screens.EpisodeRatings.gesture_rule_note()}
      </Column>
    </Scroll>
    """
  end

  @doc false
  def header do
    ~MOB"""
    <Column fill_width={true}>
      <Text
        text="The Long Hollow"
        text_size={28}
        max_font_scale={1.6}
        font_weight="bold"
        letter_spacing={-0.03}
        text_color={:on_surface}
      />
      <Spacer size={6} />
      <Text
        text="SEASON 2 · 5 OF 7 WATCHED"
        font_family="mono"
        text_size={11.5}
        text_color={Palette.muted()}
        max_lines={1}
      />
      <Spacer size={20} />
    </Column>
    """
  end

  @doc false
  def episode_list(rows) do
    ~MOB"""
    <Column fill_width={true}>
      {rows
       |> Enum.map(fn ep -> Kati.Screens.EpisodeRatings.episode_row(ep) end)
       |> Enum.intersperse(Kati.Screens.EpisodeRatings.episode_gap())}
    </Column>
    """
  end

  @doc false
  def episode_gap, do: ~MOB"<Spacer size={8} />"

  # `E1`..`E6`, not `1`..`6` — this board's own leading numeral, unlike
  # `Kati.Screens.Series.episode/1`'s bare number. `watched` alone decides
  # background, shadow and title colour: the only row here that is not
  # watched is E6, and it is also the only one not yet aired, so the board
  # never asks this function to tell the two apart.
  @doc false
  def episode_row(ep) do
    bg = if ep.watched, do: Palette.card_settled(), else: Palette.card()
    shadow = if ep.watched, do: nil, else: Theme.shadow_card_soft()
    title_color = if ep.watched, do: Palette.settled_ink(), else: :on_surface

    ~MOB"""
    <Row
      fill_width={true}
      background={bg}
      shadow={shadow}
      corner_radius={17}
      padding_left={15}
      padding_right={15}
      padding_top={13}
      padding_bottom={13}
      align="center"
    >
      <Column width={22}>
        <Text
          text={"E#{ep.n}"}
          font_family="mono"
          text_size={12}
          text_color={Palette.tertiary()}
          max_lines={1}
        />
      </Column>
      <Spacer size={13} />
      <Column weight={1.0}>
        <Text
          text={ep.title}
          text_size={14}
          font_weight="semibold"
          letter_spacing={-0.01}
          text_color={title_color}
          max_lines={1}
        />
        <Spacer size={4} />
        <Text
          text={ep.sub}
          font_family="mono"
          text_size={10.5}
          text_color={Palette.tertiary()}
          max_lines={1}
        />
      </Column>
      {Kati.Screens.EpisodeRatings.rating_node(ep.rating)}
      <Spacer size={13} />
      {Kati.Screens.EpisodeRatings.check(ep.watched)}
    </Row>
    """
  end

  @doc """
  The rating column itself: a numeral and one star, or nothing at all.

  A list, not a `Column`, for the same reason `Kati.Screens.Series.next_air/1`
  is one — the sigil flattens an interpolated list into its parent, so a
  `nil` rating contributes zero nodes and the row's own 13pt gap closes
  straight from the title column to the check, rather than a spacer holding a
  gap open for a numeral that never comes.
  """
  @spec rating_node(float() | nil) :: [map()]
  def rating_node(nil), do: []

  def rating_node(rating) do
    [
      ~MOB"<Spacer size={13} />",
      ~MOB"""
      <Row align="center">
        <Text
          text={Kati.Screens.EpisodeRatings.rating_label(rating)}
          font_family="mono"
          text_size={12}
          text_color={Palette.meta()}
          max_lines={1}
        />
        <Spacer size={3} />
        {Kati.UI.symbol("star", size: 11, color: Palette.accent(), fill: true)}
      </Row>
      """
    ]
  end

  @doc """
  `4.5`, `5`, `3.5` — never `5.0`. Every rating on this board is a whole or a
  half, so the only question is whether the fraction is worth printing.
  """
  @spec rating_label(float()) :: String.t()
  def rating_label(rating) do
    whole = trunc(rating)

    if rating - whole == 0.5 do
      "#{whole}.5"
    else
      "#{whole}"
    end
  end

  @doc """
  The 27pt check: ink-filled when watched, or a hairline ring around an
  invisible glyph otherwise. See the moduledoc for why the second state is
  not `Kati.Screens.Series.check/2`'s.
  """
  @spec check(boolean()) :: map()
  def check(true) do
    ~MOB"""
    <Box width={27} height={27} corner_radius={14} background={Palette.ink_fill()} align="center">
      {Kati.UI.symbol("check", size: 16, color: Palette.on_ink())}
    </Box>
    """
  end

  def check(false) do
    ~MOB"""
    <Box
      width={27}
      height={27}
      corner_radius={14}
      border_width={1.5}
      border_color={Palette.border()}
      align="center"
    >
      {Kati.UI.symbol("check", size: 16, color: Palette.ink_invisible())}
    </Box>
    """
  end

  @doc false
  def rating_note do
    base = [text_size: 12.5, line_height: 1.65, text_color: Palette.ink_soft(), base: true]
    emphasis = [font_weight: "semibold", text_color: :on_surface]

    body =
      UI.rich_text([
        {"A numeral plus ", base},
        {"one", emphasis},
        {" star, in DM Mono, so the column aligns — nobody reads five small stars, " <>
           "they read a shape. An unrated watched episode shows ", base},
        {"nothing at all", emphasis},
        {", not five hollow stars, which is what lets the ratings stand out.", base}
      ])

    ~MOB"""
    <Row
      fill_width={true}
      border_width={1.5}
      border_color={Palette.border()}
      corner_radius={18}
      padding={15}
      align="top"
    >
      {Kati.UI.symbol("info", size: 17, color: Palette.sub())}
      <Spacer size={11} />
      <Column weight={1.0}>
        {body}
      </Column>
    </Row>
    """
  end

  @doc """
  The hint card and its 14pt of trailing space, or neither once dismissed.

  A list, the same move as `rating_node/1` and `Kati.Screens.Series.next_air/1`:
  dismissing the hint has to close the 14pt gap along with the card, not leave
  it standing open above the gesture-rule note.
  """
  @spec hint(boolean()) :: [map()]
  def hint(false), do: []

  def hint(true) do
    tap = {self(), :dismiss_hint}

    [
      ~MOB"""
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        shadow={Theme.shadow_card_soft()}
        padding={17}
      >
        <Row fill_width={true} align="top">
          {Kati.UI.symbol("touch_app", size: 19, color: Palette.accent())}
          <Spacer size={12} />
          <Column weight={1.0}>
            <Text
              text="Hold a row to rate it"
              text_size={13.5}
              font_weight="bold"
              text_color={:on_surface}
            />
            <Spacer size={6} />
            <Text
              text="The only long press in the app besides selecting on a shelf. Shown once, then dismissed for good."
              text_size={12.5}
              line_height={1.65}
              text_color={Palette.ink_soft()}
            />
          </Column>
          <Spacer size={12} />
          <Row on_tap={tap} align="center">
            {SettingsList.action_pill("Got it")}
          </Row>
        </Row>
      </Column>
      """,
      ~MOB"<Spacer size={14} />"
    ]
  end

  @doc false
  def gesture_rule_note do
    base = [text_size: 12.5, line_height: 1.65, text_color: Palette.cream_body(), base: true]
    emphasis = [font_weight: "semibold", text_color: :on_surface]

    body =
      UI.rich_text([
        {"The gesture rule, recorded: ", emphasis},
        {"long press on a ", base},
        {"shelf tile", emphasis},
        {" selects; long press on an ", base},
        {"episode row", emphasis},
        {" rates. Two meanings, two unmistakably different surfaces — a grid of " <>
           "artwork against a list of rows. Also on 146.", base}
      ])

    ~MOB"""
    <Row fill_width={true} background={Palette.cream()} corner_radius={20} padding={16} align="top">
      {Kati.UI.symbol("call_split", size: 18, color: Palette.gold_icon())}
      <Spacer size={11} />
      <Column weight={1.0}>
        {body}
      </Column>
    </Row>
    """
  end

  @impl true
  def handle_tap(:dismiss_hint, socket) do
    {:noreply, Mob.Socket.assign(socket, :hint_visible?, false)}
  end
end
