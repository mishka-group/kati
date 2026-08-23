defmodule Kati.Screens.YearCardsStates do
  @moduledoc """
  Screen 101 — the five states of screen 100's cards, on one sheet pushed under
  Settings.

  Screen 100 is the render spec: four faces at two ratios, all of them drawn
  with the year full and every fact present. This is the board for the five
  ways that is not true — the year that has barely started, the year that is
  only part-way through, the title the user marked private, the card that has
  not finished drawing, and the save that cannot happen yet. A reference sheet
  in screen 27's manner: five pictures of a card you go and look at, rather
  than five things the app puts in front of you, which is why it carries a back
  pill exactly as 27 and 67 do.

  ## None of the five reads as a bug, and that is the whole brief

  The design's caption is the requirement: *five conditions, none of which
  should read as a bug.* Each state therefore says what is true rather than
  what is missing:

    * **Not enough data** keeps the card's own frame and fills it with a clock
      and one sentence. It does not apologise and it does not disable
      anything — `SAVE STAYS AVAILABLE` is on the card beside it, because a
      three-week year is a picture somebody may well want.
    * **Partial year** draws every cell the year has, lit or not. The unlit
      ones keep a hairline, so the field reads as *unfinished* rather than as
      *not recorded* — an absent cell would be a claim that nothing was
      measured there.
    * **A private title** keeps the slot and fills it with paper and a lock.
      Dropping the hidden title would silently reshape the collage from three
      posters to two, and the reader would have no way to know a title was
      taken out rather than never earned its place.
    * **Rendering** is the card's own silhouette, shimmering — 27's rule that
      a skeleton is never a spinner, applied to a thing whose shape is already
      known.
    * **Save not supported yet** is below.

  ## The last state names the capability, and it is not the one you would guess

  The caption calls this the honest one: *rather than a dead button, the
  failure names the missing capability and offers the thing that actually works
  today.* Both halves are load-bearing, and the first half is only honest if
  the capability named is the real one.

  It is **not** the file door. `Kati.Native.Files` has been able to hand a file
  to the platform since the `K-20 file-transport` fence landed —
  `ACTION_CREATE_DOCUMENT` to save and `ACTION_SEND` to share, both reaching
  Elixir through `{:kati_files, …}` — so `Kati.Screens.YearShare`'s line about
  there being no way to hand a file out has been overtaken by that fence.

  What is missing is one step earlier: **nothing turns a rendered node tree
  into image bytes.** `Kati.Native.Files.save_as/2` streams a file that already
  exists on disk — `:source_missing` is one of its own error reasons — and
  there is no offscreen rasteriser anywhere in the bridge to produce that file.
  So the card can be composed, laid out and painted on screen, and still not be
  written. That is exactly what the copy says, and it is why the offer under it
  is *Show me the card full-screen* rather than a retry: the pixels are real
  and already on the device's own display, so a screenshot is the same picture.
  A button that offered to try again would be offering to fail again.

  ## One eyebrow keeps the orange dash

  `Not enough data` is the only one, and the rule is 27's: orange means new or
  now and nothing else. It is the one state on this sheet that is about *this
  moment* — a year three weeks old, which stops being true as the year fills.
  The other four name a condition that does not date: a private title, a card
  mid-render, a capability that has not shipped, and a year that is partial by
  arithmetic rather than by age. Those take the grey dash through
  `Kati.UI.SettingsList.eyebrow_muted/1`.

  ## What comes from 98 and 100, and what this sheet draws itself

  The three ranked titles are `Kati.Screens.YearShare.ranks/0` — the same
  builder screen 100's `face(:top_titles, …)` calls — over the same
  `Kati.Stats.ShareSample.top_titles/0`. That is the reuse that matters most
  here: this sheet's whole claim is that one of those three is hidden, and it
  can only make that claim honestly if it is looking at the same three the card
  is. `Kati.Stats.ShareSample.field_face/0` supplies `Your year` and the `Kati`
  wordmark for the same reason, and the field's five tones are
  `Kati.Music.Sample.tone/0` through `tone/4`, which is the ramp the board
  draws cell for cell.

  Three places where the board and screen 100 disagree, and 100 wins in all
  three — 67's rule, for 67's reason: a sheet that redrew a band its own way
  would report a difference the app does not have.

    * **The card's mono label is `#A0998F` on the board and `#A9A29A` on 100.**
      `Palette.eyebrow/0` is named for the label *after an accent dash* and
      this one has no dash; 98 and 100 both give this band `Palette.muted/0`,
      so that is what it takes here.
    * **The rank gutter is 11pt wide on the board and 16 in
      `Kati.Screens.YearShare.rank_row/1`.** Reusing the builder is worth five
      points of gutter; forking it to save them would be two rank lists to keep
      in step.
    * **`Kati.Screens.YearCards.face/2` is not called at all**, for either
      card. Every one of its four faces is drawn complete by construction —
      the field is `Kati.Screens.AlbumDetail.field_rows/0`'s full ninety-one
      cells and the posters are three pictures — and those are precisely the
      two things these states change. There is no seam in `face/2` to pass a
      truncated year or a locked slot through, so the two cards here are hand
      drawn and the pieces underneath them are shared instead.

  ## The field is a third set of metrics, and that is the drawing's doing

  Kati now has three pixel fields. `Kati.UI.pixel_field/2` is 15pt cells on a
  3pt gap with a four-step ramp (screen 07); `Kati.Screens.AlbumDetail.field_rows/0`
  is 8pt on 4, chunked at 27, over five steps (screen 74); this one is 9pt on 4,
  chunked at 12. The chunk is what forces it — a `Row` does not wrap and no
  geometry comes back from `render/1`, so the count is declared, and twelve is
  what fits across a 190pt card inside 18 of padding. Neither of the other two
  fields was measured for a card that narrow.

  The board's own two numbers are kept as drawn and not reconciled: 42 cells
  lit of 104, and `34 WEEKS TO GO` under them. They do not divide into each
  other, and inventing an arithmetic that made them agree would be asserting a
  rule the app has not written — the live screen would compute that line from
  the calendar, not from the cell count, which is what *the caption counts what
  is left* means.

  ## Two things the drawing does that the bridge cannot

    * **A horizontal shimmer.** The skeleton's bars are
      `linear-gradient(90deg,#E7E3DC,#F1EEE9,#E7E3DC)`. The bridge's gradient
      parser is vertical only — `to_top` or `to_bottom` — so they are the flat
      `Palette.track/0` the gradient starts and ends on, which is 27's own
      recorded answer to the same drawing.
    * **A bold word inside a paragraph.** Two captions and the failure card set
      one emphasised run inside running copy. `Kati.UI.rich_text/1` takes them
      and drops the emphasis rather than the wrapping, because a `Row` of
      `Text` nodes orphans the emphasised words onto their own line and that
      reads as a broken layout where flat typography merely reads as flat.

  ## A fixed width and padding are not the same node

  The four tiles carry a numeric `width` and their padding lives on an inner
  `Column`. That is not decoration: `nodeModifier` applies `padding` **before**
  `width`, so a `<Column width={190} padding={18}>` measures 226 and the row
  beside it loses 36 points it never asked for. `Kati.Screens.Day.stack_tile/2`
  found the same edge and states it the same way.

  `aspect_ratio={0.8}` is the board's `aspect-ratio:4/5`, and it is the one
  place on this sheet where a hard height is right rather than a
  `min_height`: the thing being drawn is a fixed-canvas export, and a specimen
  that grew with the reader's text setting would stop being a picture of the
  file.

  ## Nothing here reads a store, and nothing here taps

  27's argument applies unchanged — each card is a picture of a state, not a
  report that the app is in it, so `3 weeks of your year`, `34 WEEKS TO GO` and
  `1 HIDDEN` are drawn beside a full library and a private-title list nobody
  hid anything from.

  No control carries an `on_tap`, so `Show me the card full-screen` is drawn
  rather than wired, and no tag reaches `Kati.Screens.Root.rescue_tap/3`. This
  module therefore defines no `handle_tap/2` at all, which is what
  `Kati.Screens.Pushed` asks for: a catch-all no-op here would silence the one
  report that catches a control wired to nothing, and there is nothing on this
  sheet for it to catch.
  """

  use Kati.Screens.Pushed, back: "Settings"

  alias Kati.Design.Images
  alias Kati.Music.Sample, as: MusicSample
  alias Kati.Screens.YearShare
  alias Kati.Stats.ShareSample
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  # The board's field: 104 cells, 12 to the row. See the moduledoc for why the
  # chunk is declared rather than measured, and why neither of Kati's two other
  # pixel fields fits a card this narrow.
  @cells 104
  @per_row 12

  # The 42 lit cells, read off the board in order and expressed as levels on
  # `Kati.Music.Sample.tone/1`'s five-step bronze ramp rather than as colours —
  # every tone the drawing uses is already a step on it, so the two fields
  # cannot drift apart.
  @lit [2, 2, 0, 0, 1, 2, 0, 4, 2, 3, 0, 0, 2, 2, 2, 3, 0, 2, 2, 1, 0] ++
         [1, 0, 0, 1, 4, 2, 2, 3, 1, 2, 1, 2, 3, 0, 0, 1, 1, 3, 3, 2, 4]

  # The board locks the middle poster. Stated as the rank rather than as an
  # index so it reads as "the second title is private" rather than as a
  # position in a list that could be reordered underneath it.
  @private_rank "2"

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
        {SettingsList.title("Year cards", "FIVE STATES")}
        {UI.eyebrow("Not enough data")}
        {Kati.Screens.YearCardsStates.not_enough_data()}
        {SettingsList.eyebrow_muted("Partial year — deliberate, not broken")}
        {Kati.Screens.YearCardsStates.partial_year()}
        {SettingsList.eyebrow_muted("A private title")}
        {Kati.Screens.YearCardsStates.private_title()}
        {SettingsList.eyebrow_muted("Rendering")}
        {Kati.Screens.YearCardsStates.rendering()}
        {SettingsList.eyebrow_muted("Save not supported yet")}
        {Kati.Screens.YearCardsStates.save_unsupported()}
      </Column>
    </Scroll>
    """
  end

  @doc """
  A year three weeks old.

  The card keeps its frame and its proportion — this is what a 4:5 export of a
  nearly-empty year looks like, not a placeholder standing where one would go —
  and the clock says the wait is time rather than failure. The card beside it
  quotes the same sentence back and adds the thing the state does not change:
  saving is still on offer, because a short year is a real picture.
  """
  @spec not_enough_data() :: map()
  def not_enough_data do
    body = ~MOB"""
    <Column fill_width={true} fill_height={true} padding={16}>
      <Spacer weight={1.0} />
      <Row fill_width={true} align="center">
        <Spacer weight={1.0} />
        {UI.symbol("schedule", size: 24, color: Palette.rail_idle())}
        <Spacer weight={1.0} />
      </Row>
      <Spacer size={12} />
      <Text
        text="Not much to show yet"
        text_size={12.5}
        line_height={1.5}
        font_weight="semibold"
        text_color={:on_surface}
        text_align="center"
      />
      <Spacer weight={1.0} />
    </Column>
    """

    caption = ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={20}
      padding={15}
      shadow={Kati.Theme.shadow_card_soft()}
    >
      <Text
        text="“Not much to show yet — Kati has 3 weeks of your year.”"
        text_size={12.5}
        line_height={1.6}
        text_color={Palette.ink_soft()}
      />
      <Spacer size={10} />
      <Text
        text="SAVE STAYS AVAILABLE"
        font_family="mono"
        text_size={10}
        letter_spacing={0.1}
        text_color={Palette.tertiary()}
        max_lines={1}
      />
    </Column>
    """

    Kati.Screens.YearCardsStates.state(Kati.Screens.YearCardsStates.tile(160, body), caption)
  end

  @doc """
  A year part-way through, drawn to its own end rather than to today.

  The card holds every cell the year has and lights the ones that happened.
  `Kati.Stats.ShareSample.field_face/0` supplies the label and the wordmark, so
  the two words on this card are the same two screens 98 and 100 print.
  """
  @spec partial_year() :: map()
  def partial_year do
    face = ShareSample.field_face()

    label = String.upcase(face.title)
    wordmark = face.wordmark

    body = ~MOB"""
    <Column fill_width={true} fill_height={true} padding={18}>
      <Text
        text={label}
        font_family="mono"
        text_size={10}
        letter_spacing={0.14}
        text_color={Palette.muted()}
        max_lines={1}
      />
      <Spacer size={15} />
      {Kati.Screens.YearCardsStates.field()}
      <Spacer weight={1.0} />
      <Row fill_width={true} align="center">
        <Text
          text="34 WEEKS TO GO"
          font_family="mono"
          text_size={10}
          text_color={Palette.muted()}
          max_lines={1}
        />
        <Spacer weight={1.0} />
        <Box width={9} height={9} corner_radius={5} background={Palette.ink()} />
        <Spacer size={6} />
        <Text
          text={wordmark}
          font_family="mono"
          text_size={10.5}
          text_color={Palette.sub()}
          max_lines={1}
        />
      </Row>
    </Column>
    """

    caption =
      Kati.Screens.YearCardsStates.caption([
        {"Empty cells keep their hairline so the year reads as ", :body},
        {"unfinished", :strong},
        {", not as missing data. The caption counts what is left.", :body}
      ])

    Kati.Screens.YearCardsStates.state(Kati.Screens.YearCardsStates.tile(190, body), caption)
  end

  @doc """
  Three titles, one of them the user's own business.

  The list is `Kati.Screens.YearShare.ranks/0` untouched, so the sheet and the
  card it is about cannot disagree about which three titles the year produced.
  The lock is in the collage above it and the count is under the list, which
  puts the fact in both registers a reader uses: the shape says a title is
  missing and `1 HIDDEN` says how many.
  """
  @spec private_title() :: map()
  def private_title do
    body = ~MOB"""
    <Column fill_width={true} fill_height={true} padding={18}>
      <Text
        text="TOP TITLES"
        font_family="mono"
        text_size={10}
        letter_spacing={0.14}
        text_color={Palette.muted()}
        max_lines={1}
      />
      <Spacer size={16} />
      {Kati.Screens.YearCardsStates.poster_stack()}
      <Spacer weight={1.0} />
      {YearShare.ranks()}
      <Spacer size={10} />
      <Text
        text="1 HIDDEN"
        font_family="mono"
        text_size={10}
        text_color={Palette.muted()}
        max_lines={1}
      />
    </Column>
    """

    caption =
      Kati.Screens.YearCardsStates.caption([
        {"The slot stays, filled with paper and a lock. Removing it would silently " <>
           "change the collage’s shape.", :body}
      ])

    Kati.Screens.YearCardsStates.state(Kati.Screens.YearCardsStates.tile(190, body), caption)
  end

  @doc """
  The card, mid-draw.

  Four bars in the places the label, the picture, the headline and the meta
  line are about to arrive, so nothing on the card moves when they do. The
  block in the middle takes the leftover height rather than a measured one,
  which is what makes it the picture's slot at either ratio.
  """
  @spec rendering() :: map()
  def rendering do
    body = ~MOB"""
    <Column fill_width={true} fill_height={true} padding={16}>
      <Box width={52} height={9} corner_radius={6} background={Palette.track()} />
      <Spacer size={11} />
      <Box fill_width={true} weight={1.0} corner_radius={10} background={Palette.track()} />
      <Spacer size={11} />
      <Box fill_width={true} height={11} corner_radius={6} background={Palette.track()} />
      <Spacer size={11} />
      <Row fill_width={true}>
        <Box weight={0.6} height={9} corner_radius={6} background={Palette.track()} />
        <Spacer weight={0.4} />
      </Row>
    </Column>
    """

    caption =
      Kati.Screens.YearCardsStates.caption([
        {"The card’s own shape, shimmering. Never a spinner — the user already " <>
           "knows what is coming.", :body}
      ])

    Kati.Screens.YearCardsStates.state(Kati.Screens.YearCardsStates.tile(190, body), caption)
  end

  @doc """
  The save that cannot happen, and the thing that can.

  Full width rather than a tile beside a caption, because there is no card to
  show: this state is about the file, not about the picture. The paragraph
  names the missing capability — see the moduledoc for which one it actually
  is — and the ink button offers the only route that works today rather than a
  retry that would fail the same way.

  The button carries no `on_tap`. Nothing on a reference sheet does, and a
  handler that swallowed the tag would make a drawn control indistinguishable
  from a wired one.
  """
  @spec save_unsupported() :: map()
  def save_unsupported do
    body =
      UI.rich_text([
        {"Saving files needs a platform capability Kati does not have on this version. " <>
           "Until it lands, a screenshot of this card is the same picture — ",
         [text_size: 12.5, line_height: 1.6, text_color: Palette.ink_soft()]},
        {"the card is drawn at full quality on screen",
         [
           text_size: 12.5,
           line_height: 1.6,
           font_weight: "semibold",
           text_color: :on_surface
         ]},
        {".", [text_size: 12.5, line_height: 1.6, text_color: Palette.ink_soft()]}
      ])

    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={20}
      padding={15}
      shadow={Kati.Theme.shadow_card_soft()}
    >
      <Row fill_width={true} align="top">
        {UI.symbol("error", size: 19, color: Palette.red())}
        <Spacer size={11} />
        <Column weight={1.0}>
          <Text
            text="Kati can’t write the image yet"
            text_size={13.5}
            font_weight="bold"
            text_color={:on_surface}
          />
          <Spacer size={6} />
          {body}
        </Column>
      </Row>
      <Spacer size={14} />
      <Row
        fill_width={true}
        height={40}
        corner_radius={20}
        background={Palette.ink_fill()}
        align="center"
      >
        <Spacer weight={1.0} />
        <Text
          text="Show me the card full-screen"
          text_size={12.5}
          font_weight="bold"
          text_color={Palette.on_ink()}
          max_lines={1}
        />
        <Spacer weight={1.0} />
      </Row>
    </Column>
    """
  end

  @doc """
  One state: the specimen on the left, what it decided on the right.

  The board's own arrangement, and the reason for it is that these are
  comparisons rather than screens — the tile is a fixed size because the export
  is, and the caption takes whatever is left so the five sit on one column of
  text down the page.
  """
  @spec state(map(), map()) :: map()
  def state(tile, caption) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        {tile}
        <Spacer size={11} />
        <Column weight={1.0}>
          {caption}
        </Column>
      </Row>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  The 4:5 frame every specimen is drawn inside.

  `width` is the board's — 160 for the first state, 190 for the other three —
  and the height follows from the ratio rather than from the content, which is
  the point: the export has a fixed canvas and a tile that grew to fit its own
  text would stop being a picture of one. `body` supplies its own padding on an
  inner node; see the moduledoc for why it cannot go here.
  """
  @spec tile(pos_integer(), map()) :: map()
  def tile(width, body) do
    shadow = Kati.Theme.shadow_card_soft()

    ~MOB"""
    <Column
      width={width}
      aspect_ratio={0.8}
      background={Palette.card()}
      corner_radius={20}
      shadow={shadow}
    >
      {body}
    </Column>
    """
  end

  @doc """
  A caption beside a specimen, with the board's emphasis carried as far as it
  goes.

  Runs are `{text, :body | :strong}`. They arrive as one wrapping `Text`
  through `Kati.UI.rich_text/1`, which is the only node that wraps — the
  emphasis is dropped rather than the paragraph broken. No run is marked
  `base: true` because in all three captions the longest run is a `:body` one,
  which is the style the paragraph should take.
  """
  @spec caption([{String.t(), :body | :strong}]) :: map()
  def caption(runs) do
    body = [text_size: 12, line_height: 1.55, text_color: Palette.ink_soft()]
    strong = Keyword.merge(body, font_weight: "semibold", text_color: :on_surface)

    runs
    |> Enum.map(fn
      {text, :body} -> {text, body}
      {text, :strong} -> {text, strong}
    end)
    |> UI.rich_text()
  end

  @doc """
  Every cell of the year, lit ones first.

  The board draws the lit run in order and then a tail of empties, which is
  what a year looks like from the inside: the past is a sequence and the future
  is a length.
  """
  @spec cells() :: [0..4 | nil]
  def cells, do: @lit ++ List.duplicate(nil, @cells - length(@lit))

  @doc "The field, chunked into rows a `Row` can hold."
  @spec field() :: map()
  def field do
    rows =
      Kati.Screens.YearCardsStates.cells()
      |> Enum.chunk_every(@per_row)
      |> Enum.map(&Kati.Screens.YearCardsStates.field_row/1)

    ~MOB"""
    <Column>
      {rows}
    </Column>
    """
  end

  @doc false
  @spec field_row([0..4 | nil]) :: map()
  def field_row(row) do
    cells =
      row
      |> Enum.map(&Kati.Screens.YearCardsStates.cell/1)
      |> Enum.intersperse(~MOB"<Spacer size={4} />")

    ~MOB"""
    <Column>
      <Row>
        {cells}
      </Row>
      <Spacer size={4} />
    </Column>
    """
  end

  @doc """
  One cell: a week that happened, or one that has not yet.

  The empty cell is the state's whole argument. It draws `Palette.transparent/0`
  — the token whose meaning is *nothing drawn, deliberately* — inside an 8% ink
  hairline, so the year's full length is visible and the unlit part reads as
  time remaining rather than as data that failed to arrive. The hairline
  follows the mode with the fill it is made of, which is what
  `Palette.hairline_soft/0` is for.
  """
  @spec cell(0..4 | nil) :: map()
  def cell(nil) do
    ~MOB"""
    <Box
      width={9}
      height={9}
      corner_radius={2}
      background={Palette.transparent()}
      border_width={1}
      border_color={Palette.hairline_soft()}
    />
    """
  end

  def cell(level) do
    tone = MusicSample.tone(level)

    ~MOB"""
    <Box width={9} height={9} corner_radius={2} background={tone} />
    """
  end

  @doc """
  The collage: three posters fanned, with the private one face down.

  A fixed 132pt box with each tile pushed in by 38, which is the board's
  `margin-left:-18px` read from the other side — a negative margin both shifts
  a poster and shrinks the box it occupies, so three 56pt tiles at -18 measure
  132 rather than 168. `Kati.Screens.Home.poster_stack/0` states the same
  arithmetic; Compose throws on negative padding and takes the activity with
  it.
  """
  @spec poster_stack() :: map()
  def poster_stack do
    tiles =
      ShareSample.top_titles()
      |> Enum.with_index()
      |> Enum.map(fn {title, index} ->
        Kati.Screens.YearCardsStates.poster_tile(title, index)
      end)

    ~MOB"""
    <Box width={132} height={80}>
      {tiles}
    </Box>
    """
  end

  @doc """
  One tile in the fan, ringed in the card's own colour so the overlap reads as
  a stack rather than a smear.

  The private title gets the same tile with a lock in it: same size, same ring,
  same shadow, same place in the fan. That is the state's claim made
  structurally — the collage is the shape it would have been either way.
  """
  @spec poster_tile(map(), non_neg_integer()) :: map()
  def poster_tile(title, index) do
    offset = index * 38
    shadow = poster_shadow()

    art =
      if title.rank == @private_rank do
        UI.symbol("lock", size: 18, color: Palette.rail_idle())
      else
        Kati.Screens.YearCardsStates.poster_art(Images.poster(title.seed))
      end

    ~MOB"""
    <Box
      width={56}
      height={80}
      offset_x={offset}
      corner_radius={8}
      background={Palette.placeholder()}
      border_width={2}
      border_color={Palette.card()}
      shadow={shadow}
      align="center"
    >
      {art}
    </Box>
    """
  end

  @doc false
  @spec poster_art(String.t() | nil) :: map()
  # Inset by the ring's 2pt on each side, the way screen 01's stack insets its
  # own. With no picture the paper square underneath is already the drawing's
  # placeholder, so nothing is drawn over it.
  def poster_art(nil), do: ~MOB"<Spacer size={0} />"

  def poster_art(src) do
    ~MOB"""
    <Image src={src} width={52} height={76} corner_radius={6} content_mode="fill" />
    """
  end

  # `0 4px 10px -4px rgba(26,25,23,.45)`, built the way
  # `Kati.Screens.AlbumDetailStates` builds its cover shadow: the RGB is read
  # off the palette and only the alpha is written here, so no colour in this
  # file is a hex literal. `Kati.Theme.shadow_poster/0` has this geometry
  # exactly and a warm brown instead of ink, which is screen 01's cream hero
  # rather than this card's paper.
  #
  # `:light` on purpose. A shadow is cast rather than painted, so it stays ink
  # in both modes — the dark value would be near-white and would draw a halo.
  defp poster_shadow do
    "0 4 10 -4 #73" <> rgb(Palette.ink(:light))
  end

  defp rgb(argb) do
    argb |> rem(0x1000000) |> Integer.to_string(16) |> String.pad_leading(6, "0")
  end
end
