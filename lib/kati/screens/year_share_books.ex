defmodule Kati.Screens.YearShareBooks do
  @moduledoc """
  Screen 99 — Your year, shared, with the Books scope selected.

  Screen 98 is this page with `Screen` lit. This is the same page with `Books`
  lit, and the design's caption calls it *the second required state* — the board
  that proves the section chip does what 98 says it does.

  ## One template per card, not one per section

  The caption states the rule the whole board turns on: *every card keeps its
  geometry, so the generator has one template per card rather than one per
  section*. So almost nothing here is new. The chrome, the title, the six scope
  chips, the `Aspect` eyebrow with its segmented control, the privacy switch and
  the actions are `Kati.Screens.YearShare`'s own functions called through —
  `scopes/1` with `"Books"`, `aspects/0`, `privacy_row/1`, `actions/0` — so a
  chip that grows a count on 98 grows it here in the same commit.

  Two things are written out, and they are the two the caption says change: the
  face labels and figures, which are the **unit**, and the artwork, which is the
  **shape**. The card frame around them is restated rather than called only
  because `Kati.Screens.YearShare.card/0` takes no arguments and reads
  `Kati.Stats.ShareSample` directly. Every number in that frame is copied here
  deliberately — radius 22, 19pt of padding, `Kati.Theme.shadow_card/0`, the 9pt
  gap under the face label, the 20pt gap between the two faces. If the two ever
  disagree it is a bug in this file, and the fix is a `card/1` on 98 that takes
  a face rather than a second frame on this side.

  ## A book cover is not a poster ratio

  `Kati.Screens.YearShare.poster/1` is the one builder this board calls past
  rather than through, and the caption is the reason. That tile is
  `weight={1.0}` over a declared height of 92: three of them across a full-width
  card measure roughly 101 by 92, which is a poster cropped to a landscape
  strip. A cover is 52x78 — 2:3, declared on both axes — because with a book the
  ratio is part of the object rather than a crop of it.

  The fan is screen 12's construction, for the reason `Kati.Screens.Lists`
  gives: Mob has no negative margin, so the drawing's `margin-left:-16px` is
  reproduced from the other side as three `Row`s with `padding_left` of 0, 36
  and 72 inside a `Box` of declared width — 52 + 36 + 36 = 124, exactly the
  width the three overlapped covers occupy. Each cover's 2pt `#FBFAF8` ring is a
  centred 48x74 image inside a card-coloured 52x78 box rather than `padding={2}`,
  because `nodeModifier` applies padding *outside* an explicit size and a padded
  tile would measure 56 and break the fan.

  ## The unit swap costs one line, and the line stays inside the frame

  `Across 34 books` is on this face and has no twin on 98's. `312h 40m` says
  what it is; `11,480` does not, and a page count with no denominator is a
  number nobody can place. It sets at the 12.5pt `Palette.sub/0` this design
  gives every second line, in the same column, so the template absorbs it as one
  more `Text` rather than as a second layout.

  ## The Books face lists no titles

  98's second face puts three ranked titles under its posters. This drawing puts
  three covers under `Top books` and stops, so `ranks/0` and `rank_row/1` are
  the two public builders on 98 that this board deliberately does not call. A
  cover is a title page — the name is set into the artwork — and a rank list
  under three of them would print every title twice. On a card whose whole
  purpose is to be saved as an image, the second printing is the one that goes.

  ## Three places the drawing and screen 98 disagree, and 98 wins

  A state that redrew its own template would report a difference the app does
  not have, so where this artboard and the built screen differ, the built screen
  is what is reproduced:

    * **The carousel and its pager.** Both artboards draw two 252pt cards side
      by side, the second at half opacity, over four dots. 98 collapsed that to
      one full-width card holding both faces, and this board follows it. Four
      dots over one card would be a pager pointing at three cards this screen
      does not have — `Kati.Stats.ShareSample.faces/0` names four faces, and
      screen 100 is the board that draws all four, at both ratios.
    * **The figure.** The drawing sets it in mono at 28, with a green wash
      behind the change and a 34pt `2026` watermark at the card's foot. 98 sets
      it sans at 34, puts the change beside it unwashed, and rides `2026` at the
      end of the same row in mono 12. The face label goes with it —
      `Palette.muted/0`, where both drawings say `#A0998F`. Reproduced as 98
      renders it, in all four.
    * **The switch.** Both artboards draw `Hide titles I marked private` on;
      98's `load/1` starts it off, and so does this one. Which position a
      control opens in belongs to the screen, and this is the same screen —
      starting it on here would say the scope chip had changed a privacy
      default.

  ## The chips are drawn, and none of the six moves the card

  `scopes/1` wires all six to a `scope_…` tag, and every one of those tags lands
  on a clause here that does nothing. This board holds one section's numbers.
  Screen 98 answers the same tags by relighting the chip over a card that does
  not follow it; that is a small untruth there and would be the entire subject
  here, so it is not repeated — and `Music would read minutes listened` is in
  the conditional because those numbers do not exist yet.

  Every other tag is `Kati.Screens.YearShare.handle_tap/2` verbatim, so the
  switch, the two aspect segments and `Save image` behave identically on both
  boards, `Save image` included: it opens screen 100, which is where the aspect
  the segmented control picks is actually drawn. A tag that is neither goes to
  `Kati.Screens.Root.unhandled_tap/3` rather than being swallowed.

  ## Where the Books figures live

  In this file, not in `Kati.Stats.ShareSample`. That module's own doc says what
  it is for: 98 and 100 draw the same four faces twice, and a second copy would
  let 4:5 and 9:16 drift apart. These figures are drawn once, on this board. The
  day a Books row appears on 100 they move there for exactly that reason, and
  `pages_face/0` already answers `Kati.Stats.ShareSample.hours/0`'s shape plus
  the denominator, so the move is a call site that does not change.

  ## The note is an outline here, and `note/2` already drew one

  `Kati.UI.SettingsList.note/2` draws what this artboard asks for — 18pt radius,
  a 1.5pt `Palette.border/0` frame, no fill — where 98's artboard put the same
  kind of paragraph on cream and 98 called `note/2` regardless. The dashed
  stroke is solid, for the reason that module records: `Modifier.border` takes a
  width and a colour and no `PathEffect`.
  """

  use Kati.Screens.Pushed, back: "Stats"

  alias Kati.Design.Images
  alias Kati.Screens.YearShare
  alias Kati.Stats.ShareSample
  alias Kati.Theme.Palette
  alias Kati.UI.SettingsList

  # The tags `Kati.Screens.YearShare.handle_tap/2` answers that mean the same
  # thing on both boards. Listed rather than caught, so a fourth control added
  # to 98's markup arrives here as a DEAD TAP report instead of a delegation
  # that quietly does the wrong thing.
  @borrowed [:toggle_private, :save_image, :aspect_square, :aspect_story]

  @impl true
  def load(socket) do
    socket
    |> Mob.Socket.assign(:scope, "Books")
    |> Mob.Socket.assign(:aspect, :aspect_square)
    |> Mob.Socket.assign(:hide_private, false)
  end

  @doc false
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
        {SettingsList.title("Your year, shared", ShareSample.subtitle())}
        {Kati.Screens.YearShare.scopes(assigns.scope)}
        {Kati.Screens.YearShareBooks.card()}
        {Kati.UI.eyebrow("Aspect")}
        {Kati.UI.Segmented.plain(Kati.Screens.YearShare.aspects(), assigns.aspect)}
        <Spacer size={16} />
        {Kati.Screens.YearShare.privacy_row(assigns.hide_private)}
        <Spacer size={16} />
        {Kati.Screens.YearShare.actions()}
        <Spacer size={16} />
        {Kati.Screens.YearShareBooks.unit_note()}
      </Column>
    </Scroll>
    """
  end

  @doc """
  The pages face, in `Kati.Stats.ShareSample.hours/0`'s shape.

  `:direction` is carried and unread, exactly as it is on the hours face — the
  frame draws `arrow_drop_up` outright — so that these figures are the same map
  the moment they move into `ShareSample`, rather than a map that has to be
  reshaped on the way. `:denominator` is the one key the hours face has no use
  for; see the moduledoc on why a page count needs one and an hour count does
  not.
  """
  @spec pages_face() :: map()
  def pages_face do
    %{
      label: "Pages read",
      figure: "11,480",
      direction: :up,
      change: "31%",
      denominator: "Across 34 books",
      year: "2026"
    }
  end

  @doc """
  The three covers the Books face fans, as design seeds.

  The seeds are the export's own — `bookaa1`, `bookbb2`, `bookcc3` — so the
  board shows the three books the drawing shows rather than three books that
  merely stand for them. `Kati.Design.Images` resolves each at 400x600.
  """
  @spec cover_seeds() :: [String.t()]
  def cover_seeds, do: ~w(bookaa1 bookbb2 bookcc3)

  @doc """
  The card preview, in screen 98's frame with the Books unit in it.

  Every measurement is 98's `card/0` — see the moduledoc for why the frame is
  restated rather than called, and for the one shape that is not shared. The
  second face ends at the covers because the drawing does, so 98's `ranks/0`
  never appears here.
  """
  @spec card() :: map()
  def card do
    assigns = %{face: pages_face()}

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        padding={19}
        shadow={Kati.Theme.shadow_card()}
      >
        <Text
          text={String.upcase(@face.label)}
          font_family="mono"
          text_size={10}
          letter_spacing={0.14}
          text_color={Palette.muted()}
        />
        <Spacer size={9} />
        <Row fill_width={true} align="bottom">
          <Text
            text={@face.figure}
            text_size={34}
            font_weight="extrabold"
            letter_spacing={-0.035}
            text_color={:on_surface}
          />
          <Spacer size={10} />
          {Kati.UI.symbol("arrow_drop_up", size: 20, color: Palette.green_text())}
          <Text
            text={@face.change}
            font_family="mono"
            text_size={13}
            text_color={Palette.green_text()}
          />
          <Spacer weight={1.0} />
          <Text text={@face.year} font_family="mono" text_size={12} text_color={Palette.muted()} />
        </Row>
        <Spacer size={9} />
        <Text text={@face.denominator} text_size={12.5} text_color={Palette.sub()} />
        <Spacer size={20} />
        <Text
          text="Top books"
          font_family="mono"
          text_size={10}
          letter_spacing={0.14}
          text_color={Palette.muted()}
        />
        <Spacer size={11} />
        {Kati.Screens.YearShareBooks.covers()}
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  The fanned covers: three tiles overlapped by 16pt.

  52 + 36 + 36 = 124, which is the width the drawing's three overlapped covers
  occupy, and the `Box` declares it so the fan cannot be stretched by whatever
  is beside it. A `Box` stacks its children at the top-start corner and a `Row`
  hugs, so `padding_left` on each `Row` is the only thing that moves — screen
  12's answer to a design that overlaps with a negative margin.
  """
  @spec covers() :: map()
  def covers do
    tiles =
      cover_seeds()
      |> Enum.with_index()
      |> Enum.map(fn {seed, i} -> Kati.Screens.YearShareBooks.cover(seed, i * 36) end)

    ~MOB"""
    <Box width={124} height={78}>
      {tiles}
    </Box>
    """
  end

  @doc """
  One cover: a 52x78 card-coloured tile, pushed in by `offset`.

  The shadow is written out rather than taken from `Kati.Theme.shadow_poster/0`.
  The geometry is that recipe's exactly — `0 4 10 -4` at 45% — but its colour is
  the warm `#503714` a poster rail is drawn with, and the cover shadows on this
  board are plain ink. Same shape, different hue, so it is the hue that is
  typed and not the shape.
  """
  @spec cover(String.t(), non_neg_integer()) :: map()
  def cover(seed, offset) do
    ~MOB"""
    <Row padding_left={offset}>
      <Box
        width={52}
        height={78}
        corner_radius={5}
        background={Palette.card()}
        shadow="0 4 10 -4 #731A1917"
        align="center"
      >
        {Kati.Screens.YearShareBooks.cover_art(seed)}
      </Box>
    </Row>
    """
  end

  @doc """
  The artwork inside a cover, or the grey the design stands in with.

  Centred at 48x74 inside the 52x78 tile, which is the 2pt ring: the artwork is
  clipped by the inner radius and the ring stays crisp where the covers overlap,
  where a border would be drawn inward on a tile that had already been measured.
  """
  @spec cover_art(String.t()) :: map()
  def cover_art(seed) do
    case Images.poster(seed) do
      nil ->
        ~MOB"<Box width={48} height={74} corner_radius={3} background={Palette.placeholder()} />"

      src ->
        ~MOB"""
        <Image src={src} width={48} height={74} corner_radius={3} content_mode="fill" />
        """
    end
  end

  @doc """
  The sentence this board exists to demonstrate.

  It is about the chip above it rather than about privacy, which is why it is
  not 98's `no_server_note/0`: that one answers *where does the image go*, and
  the answer has not changed. This one answers *what did the chip just do*, and
  is only true on a board where the chip has been moved.
  """
  @spec unit_note() :: map()
  def unit_note do
    SettingsList.note(
      "info",
      "The section chip changes the unit, not the layout: hours become pages, " <>
        "posters become covers, and the aspect ratio holds. Music would read " <>
        "minutes listened; Meals, meals cooked."
    )
  end

  @impl true
  def handle_tap(tag, socket) when tag in @borrowed, do: YearShare.handle_tap(tag, socket)

  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      # Answered, not forgotten. The chips are drawn from 98's builder and so
      # arrive wired; this board has one section's figures and cannot follow
      # them anywhere. See the moduledoc — relighting a chip over a card that
      # did not move is the one thing the board is here to argue against.
      "scope_" <> _section ->
        {:noreply, socket}

      _other ->
        Kati.Screens.Root.unhandled_tap(__MODULE__, tag, socket)
    end
  end
end
