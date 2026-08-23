defmodule Kati.Screens.RetiredTile do
  @moduledoc """
  Screen 114 — Retired tile explainer, a sheet over Health.

  Screen 42's grid draws six sections and builds four of them. Two tiles read
  *Not set up*, carry no dot and — because `Kati.Screens.Health.tile_tap/1`
  answers `nil` for them — go nowhere at all. This is what one of those tiles
  opens: three sentences in Kati's own voice about a gap in Kati, and a way out
  of the sheet that is not the close button.

  ## A sheet, not a pushed screen, and Health is still the parent

  The drawing leads with a `close` disc over a `rgba(26,25,23,.42)` scrim
  rather than a back pill, so this is `Kati.UI.Sheet` over `Mob.Screen` rather
  than `Kati.Screens.Pushed`. The parent does not change with the shape: the
  screen underneath is Health, and `:close` pops straight back to it. That is
  the condition `Kati.UI.Sheet`'s own moduledoc sets — a sheet's claim that
  *the page is still there* is honest only because closing returns to it — and
  it matters more here than on a sheet that collects something. You tapped a
  tile to find out why it is dark. Landing anywhere other than back on that
  grid would answer the question and lose your place in it.

  ## No date, and where a date would have had to come from

  The design's rule is *a fake "coming soon" is a promise the version cannot
  keep*, and it is worth writing down what enforces it on this side. **There is
  no resource anywhere in the app that could supply a date.** Every other
  figure Kati prints is read from something it stores — a `Kati.Health.Reading`,
  a `Kati.Meals.MealLog`, a `Kati.Calendars.Account.last_sync_at` — and there is
  no roadmap resource, no release field and no milestone on any of them. A
  quarter typed into this paragraph would be the only claim on any screen that
  nothing in the app could contradict, which is exactly why the sheet says so
  in as many words rather than going quiet about it.

  The second half of that sentence *is* answerable, and by one boolean.
  *When Kati can read the data properly, this tile turns on* is `on?` on
  `Kati.Health.Sample.sections/0` flipping — the move Weight and Medication have
  already made, on screens 109 and 112, without either of them arriving as a new
  entry on the grid. Screen 42 states the principle (*switching a section on is
  a state change, not a new screen*); this sheet is what stands in the gap
  until the state changes.

  ## Screen 113 is why this sheet exists at all

  113 draws the hub with these tiles still on it, and its caption gives the
  reason: *hiding them would make the hub look complete when it is not, and a
  user who saw Sleep in a screenshot would think the app broke.* A tile you can
  see and cannot open is a question the grid asks and cannot answer, so 114 is
  the answer. The two drawings are one decision in two halves, and neither is
  coherent alone.

  ## What is reused from screen 42, and what could not be

  Two functions carry the whole relationship, and both are about *routing*
  rather than pixels:

    * `Kati.Screens.Health.tile_tap/1` decides which tiles this sheet stands
      behind. `unbuilt/0` is exactly *the sections 42 has no destination for*,
      expressed as that question rather than as a second reading of `on?` — one
      map of where a tile goes, one definition of a tile that goes nowhere.
    * The same function routes the closing row. *Track a bedtime as a habit*
      goes to `Kati.Screens.Habits` because `tile_tap("Habits")` says so, not
      because this file knows the name of a screen. Habits is a tile on the same
      grid, so a change to where that tile leads arrives here for free.

  The row itself is `Kati.UI.SettingsList`'s — card, row, 30pt tile, body,
  chevron — which is the same call 42 makes for its *Watching* row, at the same
  four numbers the drawing gives it.

  Three of 42's builders draw something that looks like something here and are
  deliberately not called:

    * `Kati.Screens.Health.disc/2` is a 44pt disc at `Kati.Theme.shadow_button/0`
      carrying a tap. The hero glyph here is 58 at `shadow_card_soft` and is not
      a control at all — it is the tile's own icon, enlarged, so you can see
      that the sheet belongs to the thing you pressed. Same idea, four numbers
      apart, and the fourth is that one of them is pressable.
    * `Kati.Screens.Health.meal_tile/0` is 36 at radius 12 with `restaurant`
      welded in. The row here leads with `Kati.UI.SettingsList.icon_tile/1`'s
      30 at radius 9, which is what the drawing draws and what every other
      settings-shaped row in the app leads with.
    * `Kati.Screens.Health.tile/1` draws the dashed tile. This sheet does not
      draw the tile it came from; 113 does.

  ## Nothing here is wired into 42 yet, and that is one line short

  `Kati.Screens.Health.tile/1` gives an `on?: false` tile no `on_tap` at all,
  so the dashed tiles remain inert until 42 pushes this module with the
  section's name in `params`. That change belongs in screen 42's file rather
  than this one, and `unbuilt/0` is the predicate it would use to decide which
  tiles get it.

  ## The explainer card is hand-rolled, and `SettingsList.body/3` is why

  The paragraph is the entire point of the sheet, and `body/3`'s sub-line
  truncates to one line by default — its own comment says *one line is right
  for a setting and wrong for an explanation*. Passing `lines:` would keep the
  words but not the shape: the card is a paragraph at 13.5 on a 1.65 leading
  with no leading tile, not a row. `Kati.Screens.NothingSetUpKnockOn` reaches
  the same conclusion about the same helper for the same reason. The one line
  on this sheet that *is* a settings sub-line — *What Kati can do today* — takes
  `body/3` unchanged, and fits.

  ## Where the drawing wins and where the bridge does

    * **The bold run in the second paragraph is lost.** *There is no date for
      it* is 600-weight `#1A1917` inside a `#5C574F` sentence, and
      `Kati.UI.rich_text/1` concatenates runs into one `Text` because a `Row`
      does not wrap. Its own moduledoc carries the argument and the bridge
      change that would fix it (`runs` on `MobText`, built as an
      `AnnotatedString`). The emphasis is dropped; the paragraph wraps.
    * **`22` stays a numeral.** The drawing sets it as a link to screen 22,
      Habits. Nothing in the sentence can carry a tap for the same reason
      nothing in it can carry a weight, and a screen number reads as jargon on
      a device — but the drawing's sentence is the drawing's sentence, and the
      destination it points at is the row directly beneath it, tappable. The
      reference is inert and its route is not.
    * **The commit button has no shadow.** The drawing lifts it with
      `0 14px 28px -12px rgba(26,25,23,.5)`, and `Kati.UI.Sheet.commit/2` draws
      the flat pill every other sheet ends with. Adding the lift here would fork
      the one button six other sheets share to match one drawing of it; the
      shadow belongs to `Kati.UI.Sheet` or to nobody.
    * **`#4A4238` is `Palette.cream_body/0` on a card that is not cream.** It is
      the only token whose light value is that literal, and the palette's rule
      is that a token resolves in light to exactly the literal it replaces. The
      name is about the longest text the design sets, which is what this is; the
      ground is `Palette.card/0` here rather than cream. Same discrepancy
      `Kati.UI.SettingsList.chevron/0` records for `rail_idle` against
      `tertiary`, and the same resolution: the value wins and the comment
      carries it.

  ## One subject is drawn and the sheet is written for more than one

  The caption says the same sheet covers the greyed Books and Music shelves and
  screen 36's uninstalled extension row. So the subject is a parameter —
  `subject/1`, keyed by section name — and Sleep is the one the design has
  written. The name and the glyph are the tile's own, read from
  `Kati.Health.Sample.sections/0`, so a second Health subject costs nothing;
  the paragraph and the closing row are copy, and a section with neither draws
  the sheet without them rather than with something invented to fill the space.
  That is the same rule the bands on screen 96 keep: say what is missing and
  offer the one thing that fixes it, never render a plausible-looking
  substitute. Books, Music and 36's row are not Health sections at all, and
  wiring them here would need their subjects to come from somewhere other than
  that list.
  """

  use Mob.Screen
  import Mob.Sigil

  alias Kati.Health.Sample
  alias Kati.Screens.Health
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList
  alias Kati.UI.Sheet

  # The subject the design drew, and the one every other entry point falls back
  # to. Sleep is in `Kati.Health.Sample.sections/0` unconditionally, so this
  # fallback always resolves to a real tile rather than to nothing.
  @drawn "Sleep"

  # The paragraph is per-section copy in the design's own words, so it lives as
  # data rather than as markup — a second subject is an entry here, not a second
  # sheet. It would sit in `Kati.Health.Sample` beside the tiles it explains if
  # this round were allowed to touch a second file.
  @why %{
    "Sleep" =>
      "It was designed, and the design is good. It is not built because sleep " <>
        "data worth having comes from a device Kati cannot read yet, and typing " <>
        "a bedtime by hand every night is a habit, not a health record — 22 " <>
        "already does that better."
  }

  # `section` rather than a screen module: the destination is looked up through
  # `Kati.Screens.Health.tile_tap/1`, which is 42's own map of where a tile goes.
  @instead %{
    "Sleep" => %{icon: "bolt", title: "Track a bedtime as a habit", section: "Habits"}
  }

  # The label of the slot, not of the destination — it says what the row is for,
  # and it would be the same sentence above any other section's closing row.
  @today_line "What Kati can do today"

  @doc """
  Which tile the sheet is standing behind, taken from the push that opened it.

  `:section` in `params`, defaulting to the subject the design drew. A pushed
  sheet that took no parameter would be a sheet about Sleep specifically, and
  the whole argument for the shape — see the moduledoc — is that one explainer
  covers every tile that has nothing behind it.
  """
  @spec mount(map(), map(), Mob.Socket.t()) :: {:ok, Mob.Socket.t()}
  def mount(params, _session, socket) do
    Kati.Theme.activate()

    {:ok, Mob.Socket.assign(socket, :subject, subject(Map.get(params, :section, @drawn)))}
  end

  @doc """
  The sheet, titled with the section's own name.

  The title is the tile's label — `Sleep` — rather than a description of the
  sheet, because the header is the answer to *which tile did I press*. The
  headline underneath is where the sheet says what it is.
  """
  @spec render(map()) :: map()
  def render(assigns), do: Sheet.sheet(assigns.subject.name, body(assigns))

  @doc """
  The sheet's four blocks: what it is, why it is not here, what works, and out.

  Each block carries its own trailing gap — 20, 14, 16 — rather than the column
  interspersing one, because two of the three can be absent for a subject with
  no copy written, and a gap that outlives its block is how a sheet acquires an
  empty stripe.
  """
  @spec body(map()) :: map()
  def body(assigns) do
    subject = assigns.subject

    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.RetiredTile.hero(subject)}
      {Kati.Screens.RetiredTile.explainer(subject.why)}
      {Kati.Screens.RetiredTile.instead(subject.instead)}
      {Kati.UI.Sheet.commit("Fair enough", :close)}
    </Column>
    """
  end

  @doc """
  The sections screen 42 draws and has nowhere to send you.

  Asked as *which tiles does `Kati.Screens.Health.tile_tap/1` answer `nil`
  for*, rather than by reading `on?` a second time. The two questions have the
  same answer today and they are not the same question: `on?` is whether a
  section has anything to report, and a `nil` tap is whether it has a screen.
  This sheet is the second one's answer, so it asks the second one — and 42
  stays the single place that decides where a tile goes.
  """
  @spec unbuilt() :: [map()]
  def unbuilt do
    Enum.filter(Sample.sections(), fn section -> not Health.built?(section.name) end)
  end

  @doc """
  What the sheet says about one section: its glyph, its headline, its copy.

  The name and the icon are the tile's own, so the sheet cannot describe a
  section using a glyph the grid does not draw for it. The headline is a
  template around that name rather than copy, which is why a second Health
  subject needs no new sentence; `why` and `instead` are copy, and a section
  without them draws neither rather than something written to fill the gap.

  A name that is not an unbuilt section — a built one, or a typo — falls back
  to the drawn subject. The alternative is a sheet telling you that Meals is
  not in this version, and a wrong answer delivered confidently is worse here
  than the design's own example.
  """
  @spec subject(String.t()) :: map()
  def subject(name) do
    section =
      Enum.find(unbuilt(), &(&1.name == name)) ||
        Enum.find(Sample.sections(), &(&1.name == @drawn))

    %{
      name: section.name,
      icon: section.icon,
      headline: "#{section.name} isn’t in this version",
      why: Map.get(@why, section.name),
      instead: Map.get(@instead, section.name)
    }
  end

  @doc """
  The tile's own glyph at 58, and the sentence that says what happened to it.

  Centred by a `Row` with a weighted `Spacer` either side, as
  `Kati.Screens.States.empty/1` centres its own, because a `Box` has no way to
  centre itself in a `Column`.

  The headline carries no `max_lines`. It is the one sentence the sheet exists
  to deliver, and a heading that drops its last word to fit is a worse failure
  than a heading that runs to three lines at a large font scale — the same
  choice `Kati.Screens.NothingSetUpKnockOn.prompt/2` makes about its own title.
  """
  @spec hero(map()) :: map()
  def hero(subject) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Spacer weight={1.0} />
        <Box
          width={58}
          height={58}
          corner_radius={18}
          background={Palette.card()}
          shadow={Kati.Theme.shadow_card_soft()}
          align="center"
        >
          {UI.symbol(subject.icon, size: 26, color: Palette.sub())}
        </Box>
        <Spacer weight={1.0} />
      </Row>
      <Spacer size={15} />
      <Text
        text={subject.headline}
        text_size={19}
        font_weight="bold"
        letter_spacing={-0.025}
        text_color={:on_surface}
        text_align="center"
      />
      <Spacer size={20} />
    </Column>
    """
  end

  @doc """
  The card that explains itself: why it is not built, then that there is no date.

  The second paragraph is the sheet's own and is drawn for every subject — it is
  the promise the version refuses to make, and refusing it is not something one
  section does and another does not. The first is the section's, and a subject
  with none leaves the card holding the sentence that is always true.
  """
  @spec explainer(String.t() | nil) :: map()
  def explainer(why) do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={17}
      >
        {Kati.Screens.RetiredTile.why(why)}
        {Kati.Screens.RetiredTile.no_date()}
      </Column>
      <Spacer size={14} />
    </Column>
    """
  end

  @doc """
  The section's own paragraph, or nothing at all.

  The 13pt gap under it belongs to this block rather than to the card, so a
  subject with no paragraph does not open the card with a stripe of air. A
  `Spacer size={0}` rather than an empty list, which is the shape
  `Kati.Screens.Health.next_meal/1` uses for a block that has retired itself.

  No `max_lines`: this is the explanation, and the whole sheet is here to
  deliver it.
  """
  @spec why(String.t() | nil) :: map()
  def why(nil), do: ~MOB"<Spacer size={0} />"

  def why(text) do
    ~MOB"""
    <Column fill_width={true}>
      <Text text={text} text_size={13.5} line_height={1.65} text_color={Palette.cream_body()} />
      <Spacer size={13} />
    </Column>
    """
  end

  @doc """
  *There is no date for it* — the one claim the sheet makes in bold.

  Two runs through `Kati.UI.rich_text/1` rather than two `Text` nodes in a
  `Row`, because a `Row` does not wrap and the emphasised clause would orphan
  onto a line of its own. The cost is that the emphasis is not rendered at all
  — see the moduledoc — so this reads as one sentence at `Palette.ink_soft/0`.
  Written as runs anyway, so the day `MobText` learns `runs` the bold arrives
  without anyone having to find this paragraph again.

  The body run is marked `base: true` even though it is already the longer of
  the two: `rich_text/1` resolves an unmarked list by length, and the copy here
  is short enough that an edit to either clause could flip which style the
  whole paragraph takes.
  """
  @spec no_date() :: map()
  def no_date do
    UI.rich_text([
      {"There is no date for it",
       [text_size: 13, line_height: 1.65, font_weight: "semibold", text_color: Palette.ink()]},
      {". When Kati can read the data properly, this tile turns on.",
       [text_size: 13, line_height: 1.65, text_color: Palette.ink_soft(), base: true]}
    ])
  end

  @doc """
  The row that ends the sheet somewhere rather than nowhere.

  A settings row in every particular — `SettingsList.card/1` at radius 20 with
  4pt ends and 15pt sides, a 13pt row, the 30pt paper tile, the 13.5/11.5 body
  and the `#C4BDB3` chevron — so the one tappable thing on the sheet is shaped
  like every other tappable row in the app.

  `rule: false` because it is the only row in its card, and the chevron is
  passed **bare**: `SettingsList.row/4` applies `SettingsList.trailing/1`
  itself, so handing it an already-wrapped node adds a second 12pt spacer and
  doubles the gap to 24. The drawing asks for 13: bare is one point under it,
  wrapped is eleven over. (Screens 42 and 94 both hand it a wrapped node;
  `Kati.Screens.Settings`, the list every settings-shaped row in the app is
  copied from, passes it bare, and so does this.)

  The tap comes from `Kati.Screens.Health.tile_tap/1`, which answers `nil` for
  a section with no screen — so a closing row pointing at a section that is
  itself unbuilt would draw with no tap rather than reporting a dead one, which
  is the behaviour 42 documents for that `nil`.
  """
  @spec instead(map() | nil) :: map()
  def instead(nil), do: ~MOB"<Spacer size={0} />"

  def instead(row) do
    card =
      SettingsList.card([
        SettingsList.row(
          SettingsList.icon_tile(row.icon),
          SettingsList.body(row.title, @today_line),
          SettingsList.chevron(),
          on_tap: Health.tile_tap(row.section),
          rule: false
        )
      ])

    ~MOB"""
    <Column fill_width={true}>
      {card}
      <Spacer size={16} />
    </Column>
    """
  end

  @doc """
  Two ways out, and one of them is a destination.

  *Fair enough* and the close disc do the same thing, and that is the correct
  reading of the drawing rather than a shortcut. `Kati.UI.Sheet.commit/2` is
  documented as the sentence the sheet completes — `Save session`, `Add goal` —
  and this sheet completes nothing: it collects no value, writes no row, and
  has nothing to commit. Giving the button its own tag would imply otherwise.
  What it acknowledges is the paragraph above it, which is why the label is the
  design's *Fair enough* and not `Close`.

  `:open_habits` is 42's tag, arrived at through `Kati.Screens.Health.tile_tap/1`
  rather than typed here, and it pushes on top of the sheet — so back from
  Habits returns to the explainer and closing it returns to the grid.
  `Kati.Screens.LogProgress` pushes screen 33 out of a sheet the same way.
  """
  @spec handle_info(term(), Mob.Socket.t()) :: {:noreply, Mob.Socket.t()}
  def handle_info({:tap, :close}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}

  def handle_info({:tap, :open_habits}, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Habits)}

  def handle_info(_message, socket), do: {:noreply, socket}
end
