defmodule Kati.Screens.NothingSetUpKnockOn do
  @moduledoc """
  Screen 96 — Nothing set up, the knock-on, pushed under Settings.

  Screen 92 is where you say what you pay for. This is the sheet that draws
  what the rest of the app looks like before you have said it: the four bands
  that four different screens put in place of the section they cannot fill.
  It is a reference sheet in screen 27's manner and screen 67's — pictures of a
  state you go and look at rather than something the app puts in front of you —
  and it carries a back pill for exactly that reason, as both of those do.

  ## One sheet rather than four boards

  The design's own caption: *each band is a single replaced section of a screen
  that already exists*. None of these four screens goes blank when no service is
  set up. Screen 08 still has a film, 11 still has a Discover rail above it, 13
  still knows what time it is and 23 still has a page. What each one loses is
  **one section**, and what it puts there is the band below. Four separate
  empty-state screens would have been four claims that the app disappears, which
  is not what any of the four does.

  ## The rule the four bands share

  *An empty state should say what is missing and offer the one thing that fixes
  it — never render a plausible-looking zero.* Both halves are load-bearing, and
  band 23 is where the second half bites: the ledger says **No subscriptions
  yet** and not `£0.00 a month`. A zero total is a sentence about your spending
  and it would be false — `Kati.Services.Sample.monthly_total/0` is the figure
  that row carries once there is anything to carry, and its absence is not the
  number nought. The note at the foot says what else that decision took out with
  it: the delta badge, the per-service rows and the Worth-a-look card, all of
  which would otherwise report a change of nothing against nothing.

  Which is also why every band ends in the same button. There is exactly one
  thing that fixes all four, so all four buttons carry the tag `:my_services`
  and push `Kati.Screens.MyServices`. *All four routes lead to one place* is the
  board's line and `handle_tap/2` is one clause long because of it.

  ## Band 13 is screen 13's own card, not a copy of it

  13 is the sharpest case in the caption — *it can still size your evening, it
  just cannot fill it yet* — and the only way to draw that honestly is to draw
  the half that still works with the code that draws it. So the window is
  `Kati.Screens.WhatFits.window/1` called on `Kati.Screens.WhatFits.Sample`'s own
  evening, at full width, exactly as screen 67 calls `BookDetail.hero/1` rather
  than re-drawing a hero. A change to 13's window arrives on this sheet the next
  time it renders and the comparison cannot quietly go stale.

  That costs four disagreements with the board, and 13 wins all four for the
  reason 67 records — a sheet that redrew a band its own way would report a
  difference the app does not have:

    * **The card is cream on the screen and `#FBFAF8` on the board.** Cream is
      13's mark for the one block that is *yours* rather than the library's, and
      the window is the one block on this whole sheet that is still yours. The
      board flattens it to a plain card; the screen's own meaning is better.
    * **Five length buttons, not four.** The board draws `20m 30m 45m 1h` and 13
      draws `2h+` as well. Dropping a button here would be inventing a narrower
      control than the one that ships.
    * **The mood row comes with it**, because it is inside `window/1`. The board
      crops it. It is part of the sizing the band is claiming still works.
    * **40pt for `45 min`, not 34, and 36/12 buttons rather than 32/11.** One
      helper, one set of metrics.

  `window/1` also closes on its own 22pt tail where the board puts 11 between
  the window and the prompt under it. That is the price of the call and it is
  worth paying.

  ## The three prompt cards are hand-rolled, and `SettingsList.body/3` is why

  A prompt card is shaped like a settings row — a tile, a title, a sub-line —
  and it is not one. `Kati.UI.SettingsList.body/3` sets its second line at
  11.5pt on a 1.4 leading and truncates it, and its own comment says exactly
  when that is right: *one line is right for a setting and wrong for an
  explanation*. Every paragraph on this sheet is the explanation. So the cards
  are markup at the board's 12.5/1.55 with no line cap at all, and the tile is
  40pt rather than the 30pt every settings row leads with — the same 40pt box at
  radius 12 on paper that `Kati.Screens.MyServices.badge_tile/1` draws, since
  the two tiles are the same tile with a glyph in one and a badge letter in the
  other.

  The footnote **is** `Kati.UI.SettingsList.note/2`, which owns the border at
  the board's own 16% ink and 1.5pt, and draws it solid rather than dashed for
  the reason that function records.

  ## The subtitle sets in mono, and 92 is the precedent

  The board writes `What four screens look like on day one` at 13.5pt sans in
  `#A9A29A`, and `Kati.UI.SettingsList.title/3` sets a pushed screen's second
  line in DM Mono at 11. Screen 92's board says the same thing about *So Kati
  only shows you what you can actually watch* and `Kati.Screens.MyServices`
  takes the shared title anyway. A sheet about screen 92 that grew its own
  header would be the first place in the app where a pushed title means two
  different typefaces.

  ## One orange dash and three grey ones

  Orange means new or now and nothing else, which is the rule 27 and 67 both
  keep. Band 08 takes `Kati.UI.eyebrow/2` because it is where you meet the
  missing setup — the film in front of you, right now, that Kati cannot place.
  The other three are what that one fact knocks on to, and a consequence is not
  an event, so 11, 13 and 23 take `SettingsList.eyebrow_muted/1`. The board
  paints the dashes in exactly that pattern; this is the reading of it.

  ## Nothing here reads a store, and the gate is named rather than used

  27's argument applies unchanged: each band is a picture of a state, not a
  report that the app is in it. Gating these four on the account actually being
  empty would show the sheet on a fresh install and nothing at all on every
  other device, which is the opposite of what a reference sheet is for.

  The gate is still worth having a name, so `set_up?/0` asks
  `Kati.Screens.MyServices.listed/0` — the function 92 documents as being *for
  the empty-database gate* — and this screen deliberately does not call it. It
  is also the honest place to record that the predicate cannot answer `false`
  today: 92 falls back to `Kati.Services.Sample` when the store is empty, so the
  four screens that would ask this question need that fallback to become
  conditional before any of them can put these bands on screen.
  """

  use Kati.Screens.Pushed, back: "Settings"

  alias Kati.Screens.MyServices
  alias Kati.Screens.WhatFits
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  @impl true
  def load(socket), do: Mob.Socket.assign(socket, :tonight, WhatFits.Sample.tonight())

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
        {SettingsList.title("Nothing set up", "What four screens look like on day one", nil, :name)}
        {UI.eyebrow("08 Film detail · Where to watch")}
        {Kati.Screens.NothingSetUpKnockOn.prompt(
          "Set up your services to see where this is streaming",
          "Kati knows this film exists. It cannot say whether you can watch it tonight until it knows what you pay for.",
          :my_services_where_to_watch
        )}
        {SettingsList.eyebrow_muted("11 Discover · Leaving soon")}
        {Kati.Screens.NothingSetUpKnockOn.prompt(
          "Nothing to leave yet",
          "Leaving-soon warnings need at least one subscribed service — there is nothing to count down from.",
          :my_services_leaving_soon
        )}
        {SettingsList.eyebrow_muted("13 What fits tonight")}
        {WhatFits.window(assigns.tonight)}
        {Kati.Screens.NothingSetUpKnockOn.prompt(
          "11 episodes fit — 0 you can watch",
          "Kati can size the gap but not fill it. Set up your services and this becomes a shortlist instead of a count.",
          :my_services_what_fits
        )}
        {SettingsList.eyebrow_muted("23 Subscriptions · an empty ledger")}
        {Kati.Screens.NothingSetUpKnockOn.ledger()}
        {SettingsList.note(
          "info",
          "The empty ledger hides the delta badge, the per-service rows and the Worth-a-look card entirely — a “down 0%” chip would be noise. All four routes lead to one place."
        )}
      </Column>
    </Scroll>
    """
  end

  @doc """
  A band that replaces a section: what is missing, why it is missing, and the
  button that fixes it.

  The title is the sentence the screen would otherwise have shown a list under,
  so it carries no `max_lines` — a heading that drops its last word to fit is a
  worse failure here than a heading that runs to three lines at a large font
  scale, and the same goes for the paragraph beneath it.

  `align="top"` on the row is what keeps the 40pt tile on the *first line* of a
  three-line paragraph rather than floating to the middle of the block; it is
  the same fix `note/2` needed and got as `content_align: :top`.
  """
  @spec prompt(String.t(), String.t(), atom()) :: map()
  def prompt(title, body, tag) do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={20}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={15}
      >
        <Row fill_width={true} align="top">
          {Kati.Screens.NothingSetUpKnockOn.prompt_tile()}
          <Spacer size={12} />
          <Column weight={1.0}>
            <Text text={title} text_size={13.5} font_weight="bold" text_color={:on_surface} />
            <Spacer size={5} />
            <Text text={body} text_size={12.5} line_height={1.55} text_color={Palette.sub()} />
          </Column>
        </Row>
        <Spacer size={14} />
        {Kati.Screens.NothingSetUpKnockOn.my_services_button(40, 12.5, tag)}
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  The tile every prompt leads with: `subscriptions`, greyed, on paper.

  The box is `Kati.Screens.MyServices.badge_tile/1`'s to the point — 40 square,
  radius 12, `Palette.paper/0` — because it is the same tile screen 92 puts a
  service's badge letter in, standing here for the services that are not there.
  It cannot be that function: a badge is a `Text` in the app's own face, and a
  Material Symbol is a ligature that has to go through `Kati.Icons.glyph!/1` on
  the symbols face or it typesets as the word `subscriptions`.

  The glyph is `Palette.rail_idle/0`, the design's *present, but not now* grey —
  which is precisely what a service you have not added yet is.
  """
  @spec prompt_tile() :: map()
  def prompt_tile do
    ~MOB"""
    <Box width={40} height={40} corner_radius={12} background={Palette.paper()} align="center">
      {UI.symbol("subscriptions", size: 19, color: Palette.rail_idle())}
    </Box>
    """
  end

  @doc """
  Band 23: the ledger with nothing in it, centred rather than left-aligned.

  This is the only band on the sheet that replaces a whole page rather than a
  section, so it takes 27's centred empty-state shape — glyph, then title, then
  the sentence, then the action — instead of the tile-beside-paragraph the other
  three use. The tile grows to 48 at radius 15 and the button to the full 44pt
  primary height for the same reason: nothing is competing with it on the page
  it stands on.

  The Box is centred by a `Row` with a weighted `Spacer` either side, as
  `Kati.Screens.States.empty/1` centres its own, because a `Box` has no way to
  centre itself in a `Column`.
  """
  @spec ledger() :: map()
  def ledger do
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
          <Box width={48} height={48} corner_radius={15} background={Palette.paper()} align="center">
            {UI.symbol("payments", size: 22, color: Palette.rail_idle())}
          </Box>
          <Spacer weight={1.0} />
        </Row>
        <Spacer size={13} />
        <Text
          text="No subscriptions yet"
          text_size={14.5}
          font_weight="bold"
          letter_spacing={-0.02}
          text_color={:on_surface}
          text_align="center"
        />
        <Spacer size={7} />
        <Text
          text="An empty ledger, not £0.00 a month — there is nothing here to be zero."
          text_size={12.5}
          line_height={1.55}
          text_color={Palette.sub()}
          text_align="center"
        />
        <Spacer size={16} />
        {Kati.Screens.NothingSetUpKnockOn.my_services_button(44, 13, :my_services_ledger)}
      </Column>
      <Spacer size={11} />
    </Column>
    """
  end

  @doc """
  The one button, at whichever of its two sizes the band asks for.

  The board draws it 40 tall inside a prompt card and 44 tall on the ledger, and
  the radius is always half the height in this design, so it is computed rather
  than passed — two numbers that must agree are one number.

  Every instance used to carry the same `:my_services` tag, argued for here as
  "not a shortcut" because a per-band tag would imply the four bands went
  somewhere different. #97 is that argument's counter-example: `Mob.Renderer`
  derives an `accessibility_id` from the atom, so one tag on four buttons was
  one id on four nodes, `onNodeWithTag` threw on the second, and TalkBack read
  four identical names down the sheet. A tag is what a control *is*, not where
  it goes — all four still push `Kati.Screens.MyServices`, and `handle_tap/2`
  sends them there in one clause.
  """
  @spec my_services_button(pos_integer(), number(), atom()) :: map()
  def my_services_button(height, text_size, tag) do
    radius = div(height, 2)
    tap = {self(), tag}

    ~MOB"""
    <Row
      fill_width={true}
      height={height}
      corner_radius={radius}
      background={Palette.ink_fill()}
      align="center"
      on_tap={tap}
    >
      <Spacer weight={1.0} />
      <Text
        text="My services"
        text_size={text_size}
        font_weight="bold"
        text_color={Palette.on_ink()}
        max_lines={1}
      />
      <Spacer weight={1.0} />
    </Row>
    """
  end

  @doc """
  Whether the account has a service to work from — screen 92's own answer.

  The question the four real screens ask before they draw the bands on this
  sheet, kept here so the claim the sheet makes has a name and one definition
  rather than four. It reads `Kati.Screens.MyServices.listed/0`, which is the
  function 92 documents as being *for the empty-database gate*, so a change to
  what counts as a set-up service is made once, on the screen that owns it.

  **This screen does not call it, deliberately** — see the moduledoc: a
  reference sheet draws its states unconditionally or it is not a reference
  sheet. And it cannot answer `false` today, because `listed/0` falls back to
  `Kati.Services.Sample` for an empty store; making that fallback conditional is
  the change that has to land before any of these bands can appear in the app.
  """
  @spec set_up?() :: boolean()
  def set_up? do
    listed = MyServices.listed()

    listed.subscribed != [] or listed.free != []
  end

  @impl true
  # One clause for all four buttons. #97 gave them separate names so a device
  # test and TalkBack can tell them apart; where they go was never in question,
  # and the sheet's whole point is that one screen answers all four.
  def handle_tap(tag, socket) when tag in ~w(
        my_services_where_to_watch
        my_services_leaving_soon
        my_services_what_fits
        my_services_ledger
      )a,
    do: {:noreply, Mob.Socket.push_screen(socket, MyServices)}
end
