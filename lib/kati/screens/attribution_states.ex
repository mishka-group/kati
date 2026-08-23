defmodule Kati.Screens.AttributionStates do
  @moduledoc """
  Screen 84 — the three states of screen 83, on one sheet pushed under Settings.

  Screen 83 discharges every attribution obligation once, at one size, with the
  network up. This is the board that asks what happens to it when a sixth source
  appears, when the radio is off, and when the text is at 235%. It is a
  reference sheet in screen 27's manner — three pictures of a screen you go and
  look at rather than something the app puts in front of you — so it carries a
  back pill for the reason 27 does.

  ## The state that matters is the third

  A notice that truncates has not been given. That is the whole claim, and the
  only way to check a claim like that is to draw it: the TMDB sentence wraps to
  four lines at 235% and the card grows to hold them, rather than the sentence
  being clipped to fit a card that did not.

  The band is not decoration. `Kati.Screens.Attribution.source_card/1` puts
  `max_lines={1}` on exactly one `Text` — the site line, so `themoviedb.org`
  cannot push the chevron off the row — and at 235% that is the single element
  on 83's card that *can* clip. So the third band replaces the mark-beside-text
  row with a stack and splits the link row into two lines, which is 41's rule
  applied to this card: the URL gets a line of its own and *Opens in your
  browser* gets the line under it, and neither has anything to be truncated
  against. Everything else on the card already wraps, because 83 gave the notice
  no `max_lines` in the first place.

  ## Offline is annotated rather than styled

  The second band is `Kati.Screens.Attribution.source_card/1` drawing 83's own
  TMDB entry, unchanged — no `cloud_off` badge, no cream alert, nothing 27 would
  recognise as an offline treatment. That is the state, not a gap in it: **the
  correct offline behaviour on an attribution screen is no visible difference at
  all.** Every mark, every notice and every URL on screen 83 is a literal in
  `Kati.Screens.Attribution.sources/0` or a file in `priv/`, so there is nothing
  for the radio to fail to fetch. A screen that needed the network to render its
  notices would be a compliance failure rather than a loading state, and a
  badge drawn here would be this sheet inventing the very difference it exists
  to say does not happen.

  Only the first eyebrow keeps the orange dash. A connected account is something
  that just happened; offline and 235% are conditions the app is in, and orange
  means new/now and nothing else — 27's rule, spelled out again because this
  sheet has three chances to get it wrong.

  ## What is reused, and the one band that is not

  The first two cards are 83's card, whole: `source_card/1` for the frame and
  the tap, `mark/1` for the slot, `licence_tag/1` for `CC0`, and
  `Kati.UI.SettingsList.chevron/0` inside it. Nothing here re-implements any of
  them, so a change to 83's card arrives on this sheet the next time it renders
  and the comparison cannot quietly go stale. `tmdb/0` reaches into
  `Kati.Screens.Attribution.sources/0` for the second card rather than restating
  it, which matters more here than anywhere: the sentence on that card is quoted
  verbatim under TMDB's terms, and a second copy of a legal literal is a second
  copy that can drift out of licence.

  `dynamic_type/1` is the exception, and it is the exception for a structural
  reason rather than a stylistic one: every number in `source_card/1` is a
  constant, there is no size to pass it, and the row it draws is the row that
  has to stop being a row. So the third band is drawn here — at 83's corner
  radius, 83's padding and 83's shadow, so that the *only* thing separating it
  from the band above it is the scale.

  ## Where the board and screen 83 disagree, and which one wins

  83 wins in all three, because a sheet that redrew a band its own way would
  report a difference the app does not have:

    * **`CC0` is grey mono text on the board and a gold pill on 83.**
      `licence_tag/1` paints `Palette.accent_wash/0` under `Palette.gold_text/0`
      at eleven points of horizontal padding; the board sets the same three
      letters as a bare eyebrow-coloured token. The tag lives inside
      `source_card/1` where nothing can be passed to it, and promoting the
      licence from a pill to plain text is a change 83 would have to make first.
    * **The sentence beside the mark is 13.5 semibold ink on 83 and 13 regular
      body grey on the board.** Again inside the card, and again 83's.
    * **The TMDB mark is 96x40 on the board and 40x40 here.** `mark/1` draws one
      paper square with the source's initial for every source, because the real
      brand assets are not in `priv/` yet and most of these licences forbid
      modifying a mark. The board's wide slot is the shape TMDB's actual
      wordmark will want when the file lands; until it does, a lozenge is the
      honest placeholder and `mark/1` is where that decision belongs.

  The third band is the one place the board wins, and only because the band is
  the board's own drawing rather than 83's. It sets both sentences at 22 and 21
  in `Palette.ink_soft/0` where 83 would set the first bold and dark: at that
  size the two are no longer a heading and a footnote, they are two paragraphs
  of comparable weight, and the legal one is not the smaller.

  ## The scale is drawn, not asked for

  The third band is typeset at the sizes 235% produces rather than by turning
  the scale on, for the reason `Kati.Screens.Accessibility` records: a reference
  sheet has to show all three states at once, on one device, and a scale is a
  property of the device. The point of drawing it is that
  `.scratch/design/audit/` can be compared by eye. No `max_lines` appears
  anywhere in that card — the entire demonstration is that text wraps and the
  card grows.

  ## Nothing here reads a store, and the function that would is named

  27's argument applies unchanged. `Kati.Sources.connected?/1` exists, answers
  truthfully, and is deliberately not called: it asks `Kati.SecureStore` whether
  a ListenBrainz token is on **this** device, and gating the first band on it
  would draw two cards on a phone with no token and three on a phone with one.
  A reference sheet that shows a different number of states per device is the
  opposite of a reference. The same goes for the radio — the second band is
  drawn whether or not anything is offline.

  ## The taps come in with the band, so this sheet answers them

  Screen 67 could leave `handle_tap/2` undefined because nothing it reused was
  tappable. Here it is not optional: `source_card/1` wires every card to
  `open_<id>`, and the tag is built from `self()` at render time, so both cards
  address **this** process. Answering them keeps 83's own reason — each card
  opens a URL and Kati has no in-app browser, so what the control would open is
  the platform's browser through a fence that does not exist yet — rather than
  letting `Kati.Screens.Root.rescue_tap/3` report a dead tag that is not this
  screen's to fix.

  No dock — pushed screen — so the frame closes at 40, not 132.
  """

  use Kati.Screens.Pushed, back: "Settings"

  alias Kati.Screens.Attribution
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  # The sixth source, in the shape `Kati.Screens.Attribution.source_card/1`
  # reads: `id`, `name`, `takes`, `notice`, `licence`, `site`.
  #
  # `notice` is legal text and is a literal here for the reason 83 gives for its
  # five — editing one for tone is a licence change. ListenBrainz publishes its
  # listen data under CC0, which is why the tag is shown at all: a public-domain
  # dedication still gets named, so that a reader can tell it apart from the
  # sources whose terms actually bind.
  @listenbrainz %{
    id: :listenbrainz,
    name: "ListenBrainz",
    takes: "Your listening history, synced to your own account.",
    notice: "Listening data from ListenBrainz, a MetaBrainz project.",
    licence: "CC0",
    site: "listenbrainz.org"
  }

  @impl true
  def load(socket) do
    Mob.Socket.assign(socket, :states, %{
      connected: Kati.Screens.AttributionStates.connected_source(),
      tmdb: Kati.Screens.AttributionStates.tmdb()
    })
  end

  @doc """
  The source that only exists once an account has been connected.

  `Kati.Screens.Attribution.sources/0` lists the five that work out of the box.
  This is the sixth, and it is a different kind of obligation: the other five
  are read with Kati's own access, this one is read with the user's token and
  writes back to the user's account. `Kati.Sources.tier2/0` is where that
  distinction is defined and where ListenBrainz is offered; this map is what the
  attribution screen owes once the offer has been taken up.

  It is a map here rather than a sixth entry in 83's list because 83's list is
  unconditional — every one of those five is credited on a fresh install, and a
  source credited before it has ever been contacted is a notice for something
  that did not happen.
  """
  @spec connected_source() :: map()
  def connected_source, do: @listenbrainz

  @doc """
  83's own TMDB entry, fetched rather than copied.

  Matched on `:id` instead of taken by position, so reordering
  `Kati.Screens.Attribution.sources/0` cannot silently swap this sheet onto
  JustWatch. Both the second and the third band read from this one map, which is
  the point of the comparison: they are one source at two sizes rather than two
  fixtures that happen to agree about a sentence.
  """
  @spec tmdb() :: map()
  def tmdb, do: Enum.find(Attribution.sources(), fn source -> source.id == :tmdb end)

  @doc false
  @spec content(map()) :: map()
  def content(assigns) do
    s = assigns.states

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
        {SettingsList.title("Attribution", "three states")}
        {UI.eyebrow("With a connected account — a sixth card appears")}
        {Attribution.source_card(s.connected)}
        <Spacer size={24} />
        {SettingsList.eyebrow_muted("Offline — identical, from bundled assets")}
        {Attribution.source_card(s.tmdb)}
        <Spacer size={11} />
        {Kati.Screens.AttributionStates.bundled_note()}
        <Spacer size={24} />
        {SettingsList.eyebrow_muted("Dynamic Type 235% — nothing truncates")}
        {Kati.Screens.AttributionStates.dynamic_type(s.tmdb)}
        <Spacer size={22} />
        {Kati.Screens.AttributionStates.footnote()}
      </Column>
    </Scroll>
    """
  end

  @doc """
  The cream note that explains what the offline band is showing.

  Hand-rolled rather than `Kati.UI.SettingsList.note/2`, which draws the
  outlined footnote frame and is what `footnote/0` below uses. This one is a
  cream card: the note above the fold on a states sheet is the one carrying the
  reason the band looks the way it does, and cream is the design's ground for a
  thing said in the app's own voice rather than a caption in the margin.

  `align="top"` on the row, because the glyph belongs on the first line of a
  three-line paragraph and a `Row` centres its children by default — the same
  correction `Kati.UI.SettingsList.note/2` had to make in the pill.
  """
  @spec bundled_note() :: map()
  def bundled_note do
    ~MOB"""
    <Row fill_width={true} background={Palette.cream()} corner_radius={20} padding={16} align="top">
      {UI.symbol("info", size: 18, color: Palette.gold_icon())}
      <Spacer size={11} />
      <Text
        text="Every mark on this screen ships inside the app. An attribution screen that needs the network to render its notices is a compliance failure, not a loading state."
        text_size={12.5}
        line_height={1.6}
        text_color={Palette.cream_body()}
        weight={1.0}
      />
    </Row>
    """
  end

  @doc """
  83's card at 235%, with the two rows that cannot survive the scale unpicked.

  Same card, same corner radius, same padding, same shadow — the only things
  that grow are the type and the mark, which is what *the card simply grows*
  has to mean if it is to be checkable. Two rows become stacks:

    * **The mark beside the sentence.** At 22pt the sentence needs the full
      width of the card, and a 130pt mark beside it would leave it a column
      barely wider than one word.
    * **The link row.** This is the load-bearing one. 83 draws licence, site and
      chevron on one line with `max_lines={1}` holding the URL to it; here the
      URL takes a line and *Opens in your browser* takes the line under it, with
      the `ios_share` glyph saying where the tap goes. The chevron is dropped
      rather than shrunk: a disclosure arrow at the end of a two-line stack
      points at nothing in particular, and the stack already says what tapping
      does in words.

  Nothing in this function carries `max_lines`. The verbatim TMDB sentence wraps
  to four lines and the card takes the height, because a legal sentence is the
  one thing on this screen that may never be ellipsised — an ellipsis in a
  required notice is a notice that was not given.
  """
  @spec dynamic_type(map()) :: map()
  def dynamic_type(source) do
    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={20}
      padding={17}
      shadow={Kati.Theme.shadow_card()}
    >
      {Kati.Screens.AttributionStates.large_mark(source.name)}
      <Spacer size={14} />
      <Text text={source.takes} text_size={22} line_height={1.4} text_color={Palette.ink_soft()} />
      <Spacer size={14} />
      {SettingsList.hairline(true)}
      <Spacer size={14} />
      <Text text={source.notice} text_size={21} line_height={1.45} text_color={Palette.ink_soft()} />
      <Spacer size={14} />
      {SettingsList.hairline(true)}
      <Spacer size={14} />
      {Kati.Screens.AttributionStates.link_stack(source.site)}
    </Column>
    """
  end

  @doc """
  The brand slot at 235%, which is `Kati.Screens.Attribution.mark/1` grown.

  `mark/1` is pinned at 40x40 and takes only a name, so this is the one place
  the sheet has to restate it. What it restates is deliberately only the
  geometry: the same paper ground and the same single initial, at 130x54 with
  the initial holding the same share of the tile it holds at 40 — 15 in 40 is 20
  in 54. A mark that stayed 40pt tall beside 22pt text would be the one element
  on this card that did not grow, which is precisely the failure the band exists
  to rule out.

  The board draws a wordmark 130 wide because that is what TMDB's real asset
  needs. The initial stands in until the file is in `priv/`, unrecoloured and
  unmodified, for the reason `mark/1` gives.
  """
  @spec large_mark(String.t()) :: map()
  def large_mark(name) do
    initial = name |> String.first() |> String.upcase()

    ~MOB"""
    <Box width={130} height={54} corner_radius={8} background={Palette.paper()} align="center">
      <Text
        text={initial}
        text_size={20}
        font_weight="bold"
        text_align="center"
        text_color={Palette.sub()}
      />
    </Box>
    """
  end

  @doc """
  The link row, split into the two lines 41's rule asks for at this size.

  The URL keeps the mono face 83 gives it and drops the `max_lines={1}` with
  it — it is on its own line now, so there is nothing beside it to crowd and
  nothing to clip against. It also takes ink rather than
  `Palette.muted/0`: alone at the head of a stack it is the subject of the
  block, where on 83's row it is one of three things sharing a line.

  The second line is the affordance the chevron used to carry, said out loud.
  `ios_share` rather than `chevron_right`, because what happens is a departure
  from the app and not a push within it — and at 235% the difference between
  those two is worth a word rather than a glyph.
  """
  @spec link_stack(String.t()) :: map()
  def link_stack(site) do
    ~MOB"""
    <Column fill_width={true}>
      <Text text={site} font_family="mono" text_size={17} text_color={:on_surface} />
      <Spacer size={9} />
      <Row align="center">
        {UI.symbol("ios_share", size: 20, color: Palette.sub())}
        <Spacer size={7} />
        <Text
          text="Opens in your browser"
          text_size={17}
          font_weight="semibold"
          text_color={Palette.sub()}
        />
      </Row>
    </Column>
    """
  end

  @doc """
  The outlined footnote under the third band, stating what it demonstrates.

  `Kati.UI.SettingsList.note/2` — the frame in the margin rather than a card in
  the flow, which is the distinction between this note and `bundled_note/0`
  above. Solid where the board draws it dashed, for the reason that module
  records: `Modifier.border` takes a width and a colour and no `PathEffect`.
  """
  @spec footnote() :: map()
  def footnote do
    SettingsList.note(
      "info",
      "At 235% the mark-beside-text row becomes a stack and the link row splits into two " <>
        "lines, per 41’s rule. The verbatim notice wraps in full — a legal sentence is the " <>
        "one thing that may never be ellipsised."
    )
  end

  # Both cards on this sheet are 83's card, and 83's card is tappable: each one
  # is wired to `open_<id>` inside `source_card/1`, with the tag addressed to
  # this process. So the tags arrive here and are answered here, with 83's own
  # reason — the control is drawn, it is reachable, and what it would open is
  # the platform's browser through a fence that does not exist yet. Leaving it
  # out would have `Kati.Screens.Root.rescue_tap/3` report a dead tap against
  # this module for a control this module did not draw.
  @impl true
  @spec handle_tap(atom(), term()) :: {:noreply, term()}
  def handle_tap(_tag, socket), do: {:noreply, socket}
end
