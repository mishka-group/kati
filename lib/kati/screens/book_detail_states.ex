defmodule Kati.Screens.BookDetailStates do
  @moduledoc """
  Screen 67 — the six states of screen 66, on one sheet pushed under Settings.

  Screen 66 has one drawing and six ways to look. This is the board that draws
  them at once: the skeleton it wears while the row is still being read, the
  book whose metadata arrived half-finished, the load that failed, the device
  that is offline under it, the book nobody has opened yet, and the book that
  was put down. It is a reference sheet in screen 27's manner — six pictures of
  a screen you go and look at, rather than something the app puts in front of
  you — and it carries a back pill for exactly that reason, as 27 does.

  Two eyebrows keep the orange dash. `Loading` is something happening now, and
  `Edition` is quoted from 66 where it is orange already. The other four name a
  condition rather than an event, so they take 27's grey dash: orange means
  new/now and nothing else on this sheet is either.

  ## What "no layout shift" asked for, and what it ruled out

  The obvious way to fit six states on one board is to shrink each one to a
  band. That is the reading this sheet rejects, because a band is not what any
  of these states looks like on screen 66 — the sheet would be six pictures of
  a screen instead of six versions of it, and the shift it was drawn to rule
  out would still happen on the real screen, where nobody was looking for it.

  So partial-metadata, not-started and did-not-finish are each
  `Kati.Screens.BookDetail.hero/1`, called at full width with different data.
  Nothing here re-implements the hero: the cover, the status lozenge, the meta
  line, the 2pt bar and the position line are 66's own functions, so a change to
  any of them arrives on this sheet the next time it renders and the comparison
  cannot quietly go stale. `Kati.Screens.BookDetail.drawn_book/0` is the base
  for all three, which makes them one book in three conditions rather than three
  fixtures that happen to agree about its title.

  The bar is where the requirement is load-bearing. `hero/1` draws no bar at all
  for a `nil` fraction — see `Kati.Books.Book.fraction/1` — so partial metadata
  keeps its 56% bar with no denominator under it, not-started has no bar rather
  than one pinned at zero, and did-not-finish stops its bar at 39% instead of
  striking anything through. Three heights, one band.

  ## Nothing here reads a store, and nothing here taps

  27's argument applies unchanged: each card is a picture of a state, not a
  report that the app is in it. `Last success 6h ago` is the line that could be
  read — `Kati.Calendars.Account.last_sync_at` holds exactly that instant — and
  it is still not read, because the failure above it never happened and dating a
  true figure against an invented incident is worse than the drawing. `Offline`
  is a condition of the radio. The skeleton is drawn beside three heroes that
  loaded.

  No control on this sheet carries a tap, either. `Kati.Screens.Pushed` defines
  no `handle_tap/2` on purpose, so the four status chips, the three format
  chips, `Retry` and `Start reading` are drawn rather than wired, and none of
  them reports a dead tag.

  ## Where the board and screen 66 disagree, and which one wins

  Four places, and 66 wins in all four, because a sheet that redrew a band its
  own way would report a difference the app does not have:

    * **The did-not-finish lozenge is red on the board and grey on the screen.**
      `Kati.Screens.BookDetail`'s colour table paints every stopped status from
      one grey triple, and it has no red at all; the pill lives inside `hero/1`
      where nothing can be passed to it. So the sheet shows what 66 paints, and
      the board's `#B4553C` on a 14% wash — `Palette.red/0` over
      `Palette.red_wash_strong/0` — is the change 66 would have to make first.
      The same applies, smaller, to the not-started wash: 66 gives it the
      progress track where the board gives it paper.
    * **`Not started yet` goes through the hero's position slot**, so it sets in
      DM Mono at 10.5 rather than the board's 12pt sans. It is the line that
      moves as you read, and giving it a second typeface here would be inventing
      a band 66 does not have.
    * **The format chips sit inside the edition card on the board** and outside
      it on 66, which is 66's own departure from its own drawing. Reproduced as
      66 renders it.
    * **`Add page count`** is `Kati.Screens.BookDetail.value/1` answering `nil`,
      which is a muted glyph and label rather than the board's paper pill —
      again the thing 66 would put there for a book with no extent.

  ## The two bands this sheet draws itself

  The skeleton and the error/offline pair are the only things here that are not
  66's, and neither is 27's either. The skeleton is the hero's silhouette — an
  86x112 tile beside three bars at 13, 11 and 9 — so it holds the shape the card
  is about to take, and it carries `Kati.Theme.shadow_card/0` rather than the
  softer card shadow so that it lifts off the page by exactly as much as the
  hero that replaces it. 27's own skeleton rows are list rows and would have
  stood in for the wrong thing.

  The alert pair is 27's two cards at this screen's metrics — radius 20 and 15pt
  of padding, where 27 draws 18 and 14/16 — and in the other order. The failure
  comes first because it is the thing that happened; the offline badge sits
  under it as the reassurance, and it says what this screen in particular keeps
  editable rather than repeating 27's line about ticks.

  Both bars the design fills with a horizontal shimmer are flat `#E7E3DC`, for
  the reason 27 records: the bridge's gradient parser is vertical only.
  """

  use Kati.Screens.Pushed, back: "Settings"

  alias Kati.Books.Sample
  alias Kati.Screens.BookDetail
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  @impl true
  def load(socket) do
    Mob.Socket.assign(socket, :states, %{
      partial: partial(),
      not_started: not_started(),
      did_not_finish: did_not_finish()
    })
  end

  @doc """
  Screen 66's book with the cover and the page count taken away.

  Everything the map does not name stays the fixture's, so what is missing is
  the only thing that differs. The map-update syntax is deliberate: a key
  `Kati.Screens.BookDetail.shaped/3` stops producing fails here loudly rather
  than adding a state the hero would silently ignore.
  """
  @spec partial() :: map()
  def partial do
    %{
      BookDetail.drawn_book()
      | seed: nil,
        meta: "2024 · FABER · —",
        progress_line: "p. 214 · NO PAGE COUNT",
        extent_label: nil
    }
  end

  @doc """
  The same book, unopened.

  `progress: nil` rather than `0.0`, which is the whole distinction the bar
  turns on — no bar drawn at all, against a bar drawn empty.
  """
  @spec not_started() :: map()
  def not_started do
    %{
      BookDetail.drawn_book()
      | status: :not_started,
        status_label: "Not started",
        progress: nil,
        progress_line: "Not started yet"
    }
  end

  @doc """
  The same book, put down at page 148.

  The position line states where it stopped and the bar keeps that height, which
  is the board's own instruction: captured honestly, and nothing struck through.
  """
  @spec did_not_finish() :: map()
  def did_not_finish do
    %{
      BookDetail.drawn_book()
      | status: :did_not_finish,
        status_label: "Did not finish",
        progress: 0.39,
        progress_line: "STOPPED AT p. 148 / 380 · 39%"
    }
  end

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
        {SettingsList.title("Book detail", "six states")}
        {UI.eyebrow("Loading — skeleton, never a spinner")}
        {Kati.Screens.BookDetailStates.loading()}
        {SettingsList.eyebrow_muted("Partial metadata — no cover, no page count")}
        {BookDetail.hero(s.partial)}
        {UI.eyebrow("Edition")}
        {Kati.Screens.BookDetailStates.edition(s.partial)}
        {SettingsList.eyebrow_muted("Error · offline")}
        {Kati.Screens.BookDetailStates.alerts()}
        {SettingsList.eyebrow_muted("Not started — primary reads Start reading")}
        {BookDetail.hero(s.not_started)}
        {Kati.Screens.BookDetailStates.status_chips()}
        {Kati.Screens.BookDetailStates.start_reading()}
        {SettingsList.eyebrow_muted("Did not finish — captured honestly, no strike-through")}
        {BookDetail.hero(s.did_not_finish)}
      </Column>
    </Scroll>
    """
  end

  @doc """
  The hero's silhouette, held open while the row is read.

  A skeleton and never a spinner — 27's rule, and this is the version of it that
  belongs to a detail screen: the tile and the three bars are where the cover,
  the status line, the meta line and the position line are about to arrive, so
  nothing on the card moves when they do.
  """
  @spec loading() :: map()
  def loading do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        padding={17}
        shadow={Kati.Theme.shadow_card()}
      >
        <Row fill_width={true}>
          <Box width={86} height={112} corner_radius={6} background={Palette.track()} />
          <Spacer size={15} />
          <Column weight={1.0}>
            <Box fill_width={true} height={13} corner_radius={6} background={Palette.track()} />
            <Spacer size={10} />
            <Row fill_width={true}>
              <Box weight={0.64} height={11} corner_radius={6} background={Palette.track()} />
              <Spacer weight={0.36} />
            </Row>
            <Spacer size={10} />
            <Row fill_width={true}>
              <Box weight={0.44} height={9} corner_radius={6} background={Palette.track()} />
              <Spacer weight={0.56} />
            </Row>
          </Column>
        </Row>
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  Screen 66's edition band for a book with no extent.

  The format chips and the two rows are 66's, and so is the affordance in the
  length row: `Kati.Screens.BookDetail.value/1` answers a `nil` extent with the
  `add` glyph and `Add page count`, which is the one place on this sheet where a
  missing fact is offered as something to supply rather than reported as an
  absence. The ISBN is present in the same breath, which is the point of drawing
  the band at all — partial does not mean empty.

  66's owned-edition row is not drawn. The board does not carry it, and a states
  sheet that grew a switch would be offering to change something.
  """
  @spec edition(map()) :: map()
  def edition(b) do
    chips =
      Sample.formats()
      |> Enum.map(fn {value, label} -> UI.chip(label, selected: value == b.format) end)
      |> Enum.intersperse(~MOB"<Spacer size={7} />")

    rows = [
      SettingsList.row(nil, SettingsList.body("Length", nil), BookDetail.value(b.extent_label)),
      SettingsList.row(nil, SettingsList.body("ISBN", nil), BookDetail.mono(b.isbn))
    ]

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true}>
        {chips}
      </Row>
      <Spacer size={12} />
      {SettingsList.card(rows)}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  The load that failed, and the offline badge under it.

  Two cards and one meaning between them: the first says the book could not be
  fetched, the second says that this does not stop you. Order carries that —
  27 draws offline first because offline is its subject, and here the failure is
  the event and the badge is the answer to it.

  The offline card is the one thing on this sheet with no shadow, which is 27's
  own distinction: a condition the app is in is not an object lifted off the
  page.
  """
  @spec alerts() :: map()
  def alerts do
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
        {UI.symbol("error", size: 20, color: Palette.red())}
        <Spacer size={12} />
        <Column weight={1.0}>
          <Text
            text="Couldn’t load this book"
            text_size={13}
            font_weight="bold"
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={3} />
          <Text
            text="Last success 6h ago"
            text_size={11.5}
            text_color={Palette.sub()}
            max_lines={1}
          />
        </Column>
        <Spacer size={12} />
        {SettingsList.action_pill("Retry")}
      </Row>
      <Spacer size={10} />
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
            text="Offline"
            text_size={13}
            font_weight="bold"
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={3} />
          <Text
            text="Progress, notes and status stay editable"
            text_size={11.5}
            text_color={Palette.cream_sub()}
            max_lines={2}
          />
        </Column>
      </Row>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  66's four status chips with none of them on.

  Nothing is selected because `:not_started` is not one of the four — it is the
  state a book is in before it has a status, which is why the chip row and the
  primary button below it are drawn together: the row says nothing has been
  chosen and the button says what choosing would be.

  Two rows rather than one. A `Row` does not wrap and `Did not finish` is the
  chip that does not fit beside the other three, so the break is declared here
  instead of being discovered on a narrower device.
  """
  @spec status_chips() :: map()
  def status_chips do
    rows =
      Sample.statuses()
      |> Enum.map(fn {_value, label} -> UI.chip(label, selected: false) end)
      |> Enum.chunk_every(3)
      |> Enum.map(&Kati.Screens.BookDetailStates.chip_row/1)
      |> Enum.intersperse(~MOB"<Spacer size={7} />")

    ~MOB"""
    <Column fill_width={true}>
      {rows}
      <Spacer size={11} />
    </Column>
    """
  end

  @doc false
  @spec chip_row([map()]) :: map()
  def chip_row(chips) do
    spaced = Enum.intersperse(chips, ~MOB"<Spacer size={7} />")

    ~MOB"""
    <Row fill_width={true}>
      {spaced}
    </Row>
    """
  end

  @doc """
  The ink button, relabelled.

  66's own rule drawn as its own state: the primary does not move or give way to
  another control for a book you have not started, it says `Start reading` where
  `Log progress` sits. The three circular seconds 66 puts under it are not here,
  because what this band is about is the label.
  """
  @spec start_reading() :: map()
  def start_reading do
    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        height={54}
        corner_radius={27}
        background={Palette.ink_fill()}
        align="center"
      >
        <Spacer weight={1.0} />
        <Text
          text="Start reading"
          text_size={14.5}
          font_weight="bold"
          text_color={Palette.on_ink()}
        />
        <Spacer weight={1.0} />
      </Row>
      <Spacer size={22} />
    </Column>
    """
  end
end
