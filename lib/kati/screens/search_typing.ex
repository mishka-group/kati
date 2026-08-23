defmodule Kati.Screens.SearchTyping do
  @moduledoc """
  Screen 87 — the three states before results, on one board pushed under Home.

  Screen 86 is the field the moment it opens. Screen 19 is the field with hits
  under it. Everything between those two boards happens in about a fifth of a
  second and nobody had drawn it, so this is the board that does: first-run
  idle, one character under the minimum, and searching. It is a reference sheet
  in screen 27's manner — three pictures of a screen you go and look at, rather
  than something the app puts in front of you — and it carries a back pill for
  that reason, as 27 and 67 do.

  ## The caption's four claims, and where each one comes from

  The board's own caption: *the three states before results and the reason the
  field feels calm. Debounce is drawn rather than asserted: six keystrokes
  collapse into one fire at 180 ms, which matters here more than in most apps
  because every fire costs seven counted queries — one per scope chip.*

    * **The reason the field feels calm** is `Kati.Search.debounce_ms/0`, and it
      is a real constant rather than a promise about one. The screen reads it;
      it does not restate it.
    * **Six keystrokes** is `String.length/1` of `query/0`, the word the third
      field is mid-way through. `debounce/0` chunks that same word into the six
      cells, so the strip cannot come to disagree with the field above it — one
      string draws both.
    * **180 ms** is `Kati.Search.debounce_ms/0` again, printed under the bar,
      and the bar's own fill is `130` of those milliseconds rather than the
      board's bare `72%`. That makes the bar and the label one fact instead of
      two that have to be kept in step; 130/180 is 72.2%, which is the board's
      bar to within a pixel at this width.
    * **Seven counted queries** is `length(Kati.Search.scopes())`, which is also
      what fills the chip row — so the sentence and the thing it is counting are
      the same list.

  ## What "drawn rather than asserted" ruled out

  The obvious way to state a debounce is a sentence: *keystrokes are debounced
  at 180 ms.* That reading is the one this board rejects, and rightly — a
  sentence about latency is the one kind of claim a screenshot cannot check, so
  it survives being false. The strip is the check. Five paper cells and one ink
  cell say six keys went in and one fire came out; the bar underneath says the
  fire has not happened yet. A reader who disbelieves the sentence can count.

  ## The ring and the caret, which screen 86 refused

  86's moduledoc is explicit that its field is *drawn as a resting field rather
  than a focused one: the ink ring screen 18 gives a focused field is a claim
  that a caret is in it, and Mob has no caret to put there.* This board draws
  the ring and the caret on all three fields, and the disagreement is real
  rather than an oversight in one of them.

  The two boards are documenting different states. 86 is a field at rest and
  must not claim a focus it does not have. 87's entire subject is the field
  **mid-type** — a picture of typing with no caret in it is a picture of
  nothing. `Kati.Screens.Search` already settled this the same way for screen
  19, which draws *a focused field carrying its 2px ink ring and orange
  caret*, so 87 follows 19 and not 86.

  What the caret is remains what 86 said it was: a 2x19 `Box` in
  `Kati.Theme.Palette.accent/0`. It does not blink, nothing can be typed into
  the field (Mob has no text input at all, #45), and this board is
  documentation of a state rather than an offer to enter it.

  ## One builder draws all three fields, and that is the point

  `field/1` has two clauses keyed on whether anything has been typed, and the
  board's own drawing is what makes that the right key: an empty field puts the
  caret **before** the placeholder and hangs `tune` off the end, a field with
  something in it puts the caret **after** the text and offers `cancel`
  instead. The trailing glyph is not a second decision — there is nothing to
  clear until there is something to clear.

  Drawing the three from one function matters more here than on an ordinary
  screen. The board's subject is three states of ONE field; three hand-rolled
  fields that drifted by a point would report a difference the app does not
  have, which is the failure mode 67 records for its heroes.

  `Kati.Screens.Search.field/1` was the other candidate and is not called: it is
  `@doc false`, it takes a results map, and it has no idle clause, so two of the
  three states would have come from it and the third from here — and the two
  would then carry 19's hand-written shadow while the third carried this one's.

  ## Where the board and the codebase disagree, and which wins

    * **The field's shadow.** The board draws one layer at 60% —
      `0 8px 18px -14px rgba(26,25,23,.6)` — where `Kati.Theme.shadow_search/0`
      is that layer at 50% under a 4% hairline. The named recipe wins: it is
      the design's own name for this control, 86 uses it for the same field,
      and matching the board exactly would mean writing a colour literal into a
      prop. 19 made the other choice and spells the layer out.
    * **The chip row's tail.** `Kati.Screens.SearchIdle.chips/1` closes at 22
      where this board says 11. Reused anyway — see below.
    * **The skeleton's tile.** `Kati.Screens.States.skeleton/1` draws 40x56 at
      radius 8 and takes its second bar to 52%; this board draws 36x51 at radius
      7 and 54%. 27 wins, for the reason 67 gives about 66: a sheet that redrew
      a shared band its own way would report a difference the app does not have.
      The three rows also close at 24 rather than 22.
    * **`tune` is drawn, not wired.** 86 hangs it off a 44pt disc beside the
      field with a real tap; this board draws it as the focused field's own
      trailing glyph, inside the pill, with nothing to tap. That is a difference
      between the boards, not between the screens, and it is left as the board
      has it — 67's `Retry` and `Start reading` are drawn unwired for the same
      reason.

  ## What is reused, and the one thing that is wired

  `Kati.Search` supplies the minimum, the debounce, the scope list and the
  retention. `Kati.Search.Sample.placeholder/0` supplies the placeholder, so 86
  and 87 cannot come to disagree about what an empty field says.
  `Kati.Screens.SearchIdle.chips/1` supplies the chip row whole.
  `Kati.Screens.States.skeletons/1` with `Kati.Settings.StatesSample.skeletons/0`
  supplies the three fading rows — including the opacity compositing, which is
  arithmetic no node can do (no Mob node carries an `opacity` prop) and which
  would otherwise exist twice. `Kati.Screens.SearchSpec.word/1` spells the small
  numbers, downcased where they land mid-sentence.

  Reusing 86's chip row brings its eight `scope_*` taps with it, so `handle_tap/2`
  answers them rather than letting `Kati.Screens.Root.rescue_tap/3` report eight
  dead tags. Wiring them is honest here: the chip row on this board is a picture
  of the **searching** state, and moving the selection is the only thing a chip
  changes in that state anyway — the rows underneath stay a skeleton whatever
  scope is picked, because they are a skeleton until results land.

  ## The numbers this screen types rather than reads, and why the line is there

  A sentence is read from `Kati.Search` when **all** of its numbers come from
  there, and typed when only some of them do:

    * *Your last eight queries will sit here.* — one number,
      `Kati.Search.recent_kept/0`, so it is read.
    * *One more character. 2 minimum in Latin, 1 in فارسی…* — both numbers are
      `Kati.Search.minimum/1`, asked of a Latin character and a Persian word
      rather than hardcoded, so both are read.
    * *Six keystrokes, one search … would run forty-two.* — typed, all of it.
      `Kati.Screens.SearchSpec.word/1` stops at ten and says why in its own
      `@doc`, so `forty-two` cannot come from it. Spelling `six` and `seven`
      from code while typing the product would leave a sentence that
      half-updates when a scope is added, which is worse than one that does not
      update at all: it would still be wrong, and it would look maintained.

  ## The minimum card is set in Vazirmatn, and one word in it still cannot be drawn

  *One more character. 2 minimum in Latin, 1 in فارسی, العربية, 中文, 日本語.*
  is one wrapping sentence in four scripts, and a `Text` carries exactly one
  family. Plus Jakarta Sans has no Arabic-script glyphs at all, so `sans` would
  set six of those words as empty boxes — a sentence about scripts that cannot
  show the scripts it names. Vazirmatn covers Latin as well, which is why screen
  54 already sets its mixed English/Persian rows in it, so `font_family="fa"`
  costs the card's Latin its usual face and buys back both Arabic-script words.

  Neither bundled face carries CJK and no third one is coming: `kati_fa_400.ttf`
  is 126 KB and a CJK face is measured in megabytes. `中文` and `日本語`
  therefore fall to whatever the device substitutes, and there is nothing this
  file can do about it — the fix is a fourth bundled font, which is a shipping
  decision rather than a screen's.

  The board's own 1.55 line height wins over `Kati.Theme.fa_line_height/0`,
  which is documented as the default for a drawing that says nothing.

  ## Nothing here reads a store

  27's argument applies unchanged: each band is a picture of a state, not a
  report that the app is in it. The three fields are drawn at once, and the
  skeleton is drawn beside a card that says nothing has been searched — a pair
  of conditions no single device is ever in. There is also nothing to read.
  `Kati.Screens.Search` records at length that no index exists and no action
  anywhere matches a title by substring, so `hollow` in the third field is a
  query nothing can run and the skeleton under it is waiting on nothing.

  No dock — pushed screen — so the frame closes at 40, not 132.
  """

  use Kati.Screens.Pushed, back: "Home"

  alias Kati.Components.MishkaProgress
  alias Kati.Screens.SearchIdle
  alias Kati.Screens.SearchSpec
  alias Kati.Screens.States
  alias Kati.Search
  alias Kati.Settings.StatesSample
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  # The word the third field is part-way through. One string, three jobs: the
  # field's text, the six keystroke cells, and — through `first_letter/0` — the
  # single character the second field is under the minimum with. Splitting them
  # would let the strip come to spell something the field above it does not.
  @query "hollow"

  # How far into the 180 ms window the board's bar has travelled. The drawing
  # states `72%`; this states the milliseconds and divides, so the bar and the
  # `180 ms` beside it are one fact rather than two that drift apart.
  @elapsed_ms 130

  @doc """
  Starts on `All`, which is the chip the board fills and the chip 86 opens on.

  The assign exists because the reused chip row is wired — see `handle_tap/2`.
  """
  @spec load(term()) :: term()
  def load(socket), do: Mob.Socket.assign(socket, :scope, "All")

  @doc """
  The three states in the order the board stacks them, then the debounce card.

  Idle first because it is the state a first run actually opens in, then the
  under-minimum state, then searching — which is the order a user meets them in
  rather than an order of interest, so the board reads as a sequence.
  """
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
        {UI.eyebrow("First-run idle — Recent is empty by definition")}
        {Kati.Screens.SearchTyping.field(nil)}
        {Kati.Screens.SearchTyping.nothing_yet()}
        {SettingsList.eyebrow_muted("One character — under the minimum")}
        {Kati.Screens.SearchTyping.field(Kati.Screens.SearchTyping.first_letter())}
        {Kati.Screens.SearchTyping.under_minimum()}
        {SettingsList.eyebrow_muted("Searching — skeleton, never a spinner")}
        {Kati.Screens.SearchTyping.field(Kati.Screens.SearchTyping.query())}
        {SearchIdle.chips(assigns.scope)}
        {Kati.Screens.SearchTyping.skeletons()}
        {SettingsList.eyebrow_muted("Debounce")}
        {Kati.Screens.SearchTyping.debounce()}
      </Column>
    </Scroll>
    """
  end

  @doc """
  The query the third field is mid-way through typing.

  Public because three separate bands draw part of it and the board's whole
  argument is that they are the same six keystrokes.
  """
  @spec query() :: String.t()
  def query, do: @query

  @doc """
  The one character the second field sits under the minimum with.

  Taken from `query/0` rather than written out, because the board is drawing one
  person typing one word: the second state is the first keystroke of the third,
  and a different letter would quietly turn it into a different story.
  """
  @spec first_letter() :: String.t()
  def first_letter, do: String.first(@query)

  @doc """
  The focused field, empty or with something in it.

  `nil` is the empty field: the caret sits **before** the placeholder and `tune`
  hangs off the end. Anything else is the typed field: the caret sits after the
  text and `cancel` replaces `tune`, because there is nothing to clear until
  there is something to clear. That correspondence is the board's own, which is
  why one argument decides all three differences rather than three options.

  The 2px ink ring is a `border`, not a shadow — a shadow at zero blur and zero
  offset would be invisible under the card's own elevation. `Kati.Screens.AddTitle`
  and `Kati.Screens.Search` both reached that reading independently.
  """
  @spec field(String.t() | nil) :: map()
  def field(nil) do
    assigns = %{placeholder: Search.Sample.placeholder()}

    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        height={52}
        corner_radius={26}
        background={Palette.card()}
        border_width={2}
        border_color={Palette.ink()}
        shadow={Kati.Theme.shadow_search()}
        padding_left={18}
        padding_right={18}
        align="center"
      >
        {UI.symbol("search", size: 20)}
        <Spacer size={11} />
        <Row weight={1.0} align="center">
          <Box width={2} height={19} background={Palette.accent()} />
          <Spacer size={8} />
          <Text
            text={@placeholder}
            text_size={14.5}
            text_color={Palette.muted()}
            weight={1.0}
            max_lines={1}
          />
        </Row>
        <Spacer size={11} />
        {UI.symbol("tune", size: 19)}
      </Row>
      <Spacer size={11} />
    </Column>
    """
  end

  def field(typed) do
    assigns = %{typed: typed}

    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        height={52}
        corner_radius={26}
        background={Palette.card()}
        border_width={2}
        border_color={Palette.ink()}
        shadow={Kati.Theme.shadow_search()}
        padding_left={18}
        padding_right={18}
        align="center"
      >
        {UI.symbol("search", size: 20)}
        <Spacer size={11} />
        <Row weight={1.0} align="center">
          <Text
            text={@typed}
            text_size={14.5}
            font_weight="medium"
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={3} />
          <Box width={2} height={19} background={Palette.accent()} />
          <Spacer weight={1.0} />
        </Row>
        <Spacer size={11} />
        {UI.symbol("cancel", size: 19, color: Palette.rail_idle(), fill: true)}
      </Row>
      <Spacer size={11} />
    </Column>
    """
  end

  @doc """
  First-run idle: the card that says Recent is empty rather than hiding it.

  86 draws a Recent shelf and a `Clear` beside it, which is the same section on
  a device that has been used. Dropping the section entirely on a first run
  would make the shelf appear from nowhere after the first search; stating that
  it is empty *and what will fill it* keeps the shape of the screen constant and
  turns a blank into an explanation.

  The number is `Kati.Search.recent_kept/0` through `Kati.Screens.SearchSpec.word/1`,
  downcased because it lands mid-sentence and `word/1` capitalises for the
  sentence-initial case 88 needs.
  """
  @spec nothing_yet() :: map()
  def nothing_yet do
    kept = String.downcase(SearchSpec.word(Search.recent_kept()))
    assigns = %{body: "Your last " <> kept <> " queries will sit here."}

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={20}
        padding={15}
        shadow={Kati.Theme.shadow_card_soft()}
      >
        <Spacer size={4} />
        <Row fill_width={true} align="center">
          <Spacer weight={1.0} />
          <Box width={44} height={44} corner_radius={14} background={Palette.paper()} align="center">
            {UI.symbol("history", size: 21, color: Palette.rail_idle())}
          </Box>
          <Spacer weight={1.0} />
        </Row>
        <Spacer size={12} />
        <Text
          text="Nothing searched yet"
          text_size={13.5}
          font_weight="bold"
          text_color={:on_surface}
          text_align="center"
        />
        <Spacer size={6} />
        <Text
          text={@body}
          text_size={12}
          line_height={1.55}
          text_color={Palette.sub()}
          text_align="center"
        />
        <Spacer size={4} />
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  One character in: the card that says how many are needed, and in which script.

  Both numbers are `Kati.Search.minimum/1` asked of real input — the Latin
  character actually in the field above, and a Persian word — rather than
  written out. That is the whole reason `minimum/1` takes the query instead of
  the app's locale, and a screen that typed `2` and `1` would be a second copy
  of the rule that could disagree with the first.

  `Kati.UI.rich_text/1` rather than five `Text` nodes: a `Row` does not wrap, so
  each run would become its own unbreakable box and the two emphasised digits
  would orphan onto lines of their own. The bridge has no spans, so the bold is
  dropped and the sentence sets flat — the trade `rich_text/1` documents, and
  the right one here, because a bold that came out regular reads as plain
  typography while an orphaned digit reads as a broken layout.

  `font_family: "fa"` on every run, and the moduledoc says why: Plus Jakarta has
  no Arabic-script glyphs, so `فارسی` and `العربية` would be empty boxes in the
  one sentence whose subject is scripts.
  """
  @spec under_minimum() :: map()
  def under_minimum do
    body = [
      text_size: 12.5,
      line_height: 1.55,
      text_color: Palette.ink_soft(),
      font_family: "fa",
      base: true
    ]

    strong = [
      text_size: 12.5,
      font_weight: "bold",
      text_color: Palette.ink(),
      font_family: "fa"
    ]

    sentence =
      UI.rich_text([
        {"One more character. ", body},
        {to_string(Search.minimum(first_letter())), strong},
        {" minimum in Latin, ", Keyword.delete(body, :base)},
        {to_string(Search.minimum("فارسی")), strong},
        {" in فارسی, العربية, 中文, 日本語.", Keyword.delete(body, :base)}
      ])

    assigns = %{sentence: sentence}

    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Palette.card()}
        corner_radius={20}
        padding={15}
        shadow={Kati.Theme.shadow_card_soft()}
        align="center"
      >
        {UI.symbol("text_fields", size: 18, color: Palette.tertiary())}
        <Spacer size={11} />
        <Column weight={1.0}>
          {@sentence}
        </Column>
      </Row>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  Searching: 27's three fading rows, unchanged.

  A skeleton and never a spinner, which is 27's rule and the reason it holds
  here in particular — the rows about to arrive are result rows, so a shape that
  is already the right shape means nothing under the field moves when they land.
  A spinner would reserve nothing and every row would arrive as a jump.

  `Kati.Settings.StatesSample.skeletons/0` carries the opacity compositing, and
  that is the part worth not owning twice: no Mob node has an `opacity` prop, so
  1 / .76 / .52 are three sets of colours arrived at arithmetically against
  paper, with the shadow alphas scaled to match. The board's tile is 4x5pt
  smaller than 27's and its second bar 2% longer; 27 wins, and the moduledoc
  says why.
  """
  @spec skeletons() :: map()
  def skeletons, do: States.skeletons(StatesSample.skeletons())

  @doc """
  The debounce, drawn: six cells, one lit, over a bar that has not fired yet.

  The five paper cells are keystrokes that were swallowed and the ink one is the
  keystroke the timer is now counting from; the bar is how far into
  `Kati.Search.debounce_ms/0` that count has got. Read together they say six in,
  one out, and a reader who does not believe the sentence underneath can count
  the cells instead — which is the difference between drawing a debounce and
  asserting one.

  `Kati.UI.even_row/2` divides the width that is actually present rather than
  the 402dp the board was drawn at, so the strip fits a 411dp device instead of
  ending early with a dead gutter down one side.

  The bar goes inside a weighted `Column` because `render: :box` fills whatever
  width it is given and would otherwise take the whole row and squash the
  `180 ms` off the end.
  """
  @spec debounce() :: map()
  def debounce do
    letters = String.graphemes(query())
    last = length(letters) - 1

    cells =
      letters
      |> Enum.with_index()
      |> Enum.map(fn {letter, index} -> keystroke(letter, index == last) end)

    bar =
      MishkaProgress.progress(
        render: :box,
        value: @elapsed_ms / Search.debounce_ms(),
        max: 1,
        height: 4,
        corner_radius: 2,
        color: Palette.gold_icon(),
        track_color: Palette.paper()
      )

    body = [
      text_size: 12.5,
      line_height: 1.55,
      text_color: Palette.ink_soft(),
      base: true
    ]

    strong = [text_size: 12.5, font_weight: "bold", text_color: Palette.ink()]

    # Typed rather than composed — see the moduledoc. `forty-two` is `six`
    # times `seven` and `Kati.Screens.SearchSpec.word/1` will not spell it, so
    # all three words are typed together and go stale together.
    sentence =
      UI.rich_text([
        {"Six keystrokes, ", body},
        {"one", strong},
        {" search. Scope counts mean seven counted queries per fire, so an undebounced " <>
           "field would run forty-two.", Keyword.delete(body, :base)}
      ])

    assigns = %{
      strip: UI.even_row(cells, gap: 6),
      bar: bar,
      window: "#{Search.debounce_ms()} ms",
      sentence: sentence
    }

    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={22}
      padding={15}
      shadow={Kati.Theme.shadow_card_soft()}
    >
      {@strip}
      <Spacer size={13} />
      <Row fill_width={true} align="center">
        <Column weight={1.0}>
          {@bar}
        </Column>
        <Spacer size={9} />
        <Text
          text={@window}
          font_family="mono"
          text_size={11}
          text_color={Palette.sub()}
          max_lines={1}
        />
      </Row>
      <Spacer size={13} />
      {@sentence}
    </Column>
    """
  end

  @doc """
  One key in the strip: paper if it was swallowed, ink if it is the one that fires.

  `fired?` rather than an index, because what makes the last cell different is
  not where it sits but what it did — and the ink pair is the design's own for a
  filled control, `ink_fill/0` under `on_ink/0`, which inverts in dark rather
  than following the ground.
  """
  @spec keystroke(String.t(), boolean()) :: map()
  def keystroke(letter, fired?) do
    assigns = %{
      letter: letter,
      ground: if(fired?, do: Palette.ink_fill(), else: Palette.paper()),
      ink: if(fired?, do: Palette.on_ink(), else: Palette.sub())
    }

    ~MOB"""
    <Box fill_width={true} height={26} corner_radius={7} background={@ground} align="center">
      <Text text={@letter} font_family="mono" text_size={11} text_color={@ink} max_lines={1} />
    </Box>
    """
  end

  @doc """
  The reused chip row's eight taps, and nothing else.

  There is deliberately no catch-all clause. Every other control the board draws
  — `tune`, `cancel`, the skeleton rows — is drawn rather than wired, so a tag
  arriving here that is not a scope is a wiring mistake, and the match failing
  gets it logged by `Kati.Screens.Root.rescue_tap/3` instead of silently
  answered with `{:noreply, socket}`. A clause that swallowed it would leave the
  dead control dead and stop the only thing that was reporting it.
  """
  @spec handle_tap(atom(), term()) :: {:noreply, term()}
  def handle_tap(tag, socket) do
    "scope_" <> label = Atom.to_string(tag)
    {:noreply, Mob.Socket.assign(socket, :scope, label)}
  end
end
