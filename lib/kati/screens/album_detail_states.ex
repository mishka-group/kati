defmodule Kati.Screens.AlbumDetailStates do
  @moduledoc """
  Screen 75 — the six states of screen 74, as one sheet under Settings.

  Screen 27 drew the four states nobody designs so that every other screen
  could quote them. This does the same job one screen down: the states that are
  *particular to an album* — the one with artwork, the one still loading, the
  one that failed, the one with nothing logged against it, and the whole page
  in dark — laid out as six specimens on a single board rather than six boards.

  ## The two decisions the ticket left open

  The caption states both and this screen is the answer to them.

  **With art is an inset, not a whole board.** An album that has artwork differs
  from `.scratch/design/screens/74.html` in the hero and nowhere else: the
  tracklist, the dates, the history field and the note are the same nodes
  reading the same values. A second full board would therefore be 90% a copy of
  the first, and a copy is a thing that can drift — the day the tracklist gains
  a row, one of the two boards gets it. So `with_art/1` draws the hero alone,
  at the 118pt tile the design gives it, and says by omission that the rest of
  the page is unchanged.

  **Zero plays keeps the field, drawn and empty.** `empty_field/0` is ninety-one
  outlined cells: the same count, the same 8pt cell on a 4pt gap and the same
  chunk of 27 that `Kati.Screens.AlbumDetail.field_rows/0` uses, with every cell
  emptied. Hiding the card would have been less code and it would have read
  wrong — an album page with no history band looks like a page that has not
  finished loading, where an album with a full grid of empty cells looks like an
  album nobody has played. The card is the sentence; `Nothing logged yet` is
  only its full stop.

  ## Nothing on this sheet is read from the shelf

  27's rule, and it applies here for 27's reason: each card is a picture of a
  state, not a report that the app is in one. `Kati.Screens.AlbumDetail.load/1`
  reads the shelf and falls back to the drawing; this one calls that screen's
  `drawn_album/0`, which is the drawing's values unconditionally, so the album
  named on the sheet is the album the frame was captured from whatever is
  shelved. `Last success 6h ago` is the line that could have been read and is
  not, for the same reason 27 does not read it: the failure above it never
  happened, and dating a real instant against an invented one reads as a live
  incident report.

  The one value that is genuinely this sheet's own is `art_seed`. Screen 74's
  album is drawn with **no** artwork on purpose — Cover Art Archive coverage is
  patchy — so `Kati.Music.Sample.album/0` carries `art_seed: nil` and the
  with-art variant has to supply the seed the export drew, `albm1`. It is the
  same album with the picture it would have had, not a second album.

  ## Nothing here is tappable, and that is the point

  `Retry` and `Log a listen` are drawn and inert, so this screen defines no
  `handle_tap/2` and `Kati.Screens.Pushed`'s dead-tap report has nothing to
  catch. A reference sheet whose Retry button retried would be showing the
  reader a state the app is not in and then acting on it.

  ## Two things the drawing does that the bridge cannot

    * **Opacity.** The three skeleton rows fade to 1, .78 and .56, and no node
      carries an opacity prop. `bar/1` composites the bar colour against the
      page instead, arriving at the same pixels arithmetically — and because it
      composites `Kati.Theme.Palette.track/0` over `paper/0` rather than baking
      the light answer into a literal, the fade is still a fade in dark.
    * **A horizontal shimmer.** Each bar is filled with
      `linear-gradient(90deg,#E7E3DC,#F1EEE9,#E7E3DC)`. The bridge's gradient
      parser is vertical only, so the bars are the flat colour the gradient
      starts and ends on — the same substitution `Kati.Screens.States` makes.

  ## The dark inset

  Drawn with the palette's explicit `:dark` arm rather than by switching the
  theme, because the other five states on the sheet are light and a screen that
  installed a dark theme to draw one card would repaint all of them. It is the
  three claims screen 28 makes, reduced to what an album page shows: paper at
  `#121110`, the field card lifting on `Kati.Theme.Palette.card_hairline/0`
  instead of a shadow, and cream warming to a lit-lamp brown. The field itself
  is `Kati.Screens.AlbumDetail.field_row/1` — the same builder, because the five
  listening tones are hues and do not move with the ground, so the dark field is
  the light field on a different card rather than a second drawing.
  """

  use Kati.Screens.Pushed, back: "Settings"

  alias Kati.Music.Sample
  alias Kati.Screens.AlbumDetail
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  # The seed the export drew the with-art variant from. Screen 74's album has
  # no art on purpose, so the seed belongs to this sheet rather than to the
  # album — see the moduledoc.
  @art_seed "albm1"

  # How much of the ninety-one-day field the dark inset shows, and how many
  # cells fit across it. The inset's card is 300pt wide inside its padding,
  # which takes 25 cells at 8 on a 4pt gap where the full-width card takes 27 —
  # the same arithmetic, a narrower card. Fifty-two cells is what the drawing
  # prints, so the last row is short, and it is short in the export too.
  @dark_cells 52
  @dark_per_row 25

  def load(socket), do: Mob.Socket.assign(socket, :album, AlbumDetail.drawn_album())

  @doc false
  def content(assigns) do
    a = assigns.album

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
        {Kati.Screens.AlbumDetailStates.title()}
        {UI.eyebrow("With art — the second variant")}
        {Kati.Screens.AlbumDetailStates.with_art(a)}
        {SettingsList.eyebrow_muted("Loading — skeleton, never a spinner")}
        {Kati.Screens.AlbumDetailStates.skeleton()}
        {SettingsList.eyebrow_muted("Error · offline")}
        {Kati.Screens.AlbumDetailStates.trouble()}
        {SettingsList.eyebrow_muted("Zero plays — the field stays, empty")}
        {Kati.Screens.AlbumDetailStates.zero_plays()}
        {Kati.Screens.AlbumDetailStates.log_button()}
        {SettingsList.eyebrow_muted("Dark")}
        {Kati.Screens.AlbumDetailStates.dark(a)}
      </Column>
    </Scroll>
    """
  end

  @doc """
  The sheet's own title, which `Kati.UI.SettingsList.title/3` cannot draw.

  That helper sets its subtitle in mono at 11pt, which is what screens 24, 27
  and 32 draw. This drawing sets `six states` in the body face at 13.5 — a
  count of what is below rather than a label for the page — so the two lines
  are written out here instead of the helper being given a second mode for one
  call site.
  """
  @spec title() :: map()
  def title do
    ~MOB"""
    <Column fill_width={true}>
      <Text
        text="Album detail"
        text_size={28}
        max_font_scale={1.6}
        font_weight="bold"
        letter_spacing={-0.03}
        text_color={:on_surface}
      />
      <Spacer size={5} />
      <Text text="six states" text_size={13.5} text_color={Palette.muted()} max_lines={1} />
      <Spacer size={20} />
    </Column>
    """
  end

  @doc """
  The hero an album with artwork gets, and the only part of 74 that changes.

  Not `Kati.Screens.AlbumDetail.hero/1`, and the difference is the whole point
  of the inset: a cover that exists is worth 118pt where the paper square is
  worth 86, so the title drops from 26 to 17 and the byline from 13.5 to 12.5
  to sit beside it. The mono line is the `first_heard` value 74 puts in a stat
  tile, moved into the hero because the tiles are not drawn here.
  """
  @spec with_art(map()) :: map()
  def with_art(a) do
    first_heard = String.upcase("First heard #{a.first_heard}")

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        {Kati.Screens.AlbumDetailStates.art(a)}
        <Spacer size={13} />
        <Column weight={1.0}>
          <Text
            text={a.title}
            text_size={17}
            font_weight="bold"
            letter_spacing={-0.025}
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={5} />
          <Text text={a.byline} text_size={12.5} text_color={Palette.muted()} max_lines={1} />
          <Spacer size={11} />
          <Text
            text={first_heard}
            font_family="mono"
            text_size={10.5}
            text_color={Palette.muted()}
            max_lines={1}
          />
        </Column>
      </Row>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  The 118pt cover tile: the artwork, ringed in paper and lifted.

  Two clauses in the same order `Kati.Screens.AlbumDetail.art/1` has them, with
  the default swapped — this is the variant where the picture is *there*, so the
  image is the first answer and the paper square with its initial and the `Art`
  placeholder is the fallback. The image is inset by the ring's 2pt on each
  side, 118 - 4 = 114, the way screen 28's poster stack insets its own.
  """
  @spec art(map()) :: map()
  def art(a) do
    case Kati.Design.Images.poster(@art_seed) do
      nil ->
        art_placeholder(a)

      src ->
        shadow = tile_shadow()

        ~MOB"""
        <Box
          width={118}
          height={118}
          corner_radius={14}
          background={Palette.placeholder()}
          border_width={2}
          border_color={Palette.card()}
          shadow={shadow}
          align="center"
        >
          <Image src={src} width={114} height={114} corner_radius={12} content_mode="fill" />
        </Box>
        """
    end
  end

  # The square 74 draws by default, at this variant's size. `Art` is the
  # drawing's own placeholder word and it stays: it is what tells the reader the
  # square stands in for a cover rather than being one.
  defp art_placeholder(a) do
    shadow = tile_shadow()

    ~MOB"""
    <Box
      width={118}
      height={118}
      corner_radius={14}
      background={Palette.placeholder()}
      border_width={2}
      border_color={Palette.card()}
      shadow={shadow}
      align="center"
    >
      <Column align="center">
        <Text
          text={a.initial}
          text_size={34}
          font_weight="bold"
          text_align="center"
          text_color={Palette.sub()}
        />
        <Spacer size={2} />
        <Text
          text="Art"
          font_family="mono"
          text_size={9.5}
          letter_spacing={0.12}
          text_align="center"
          text_color={Palette.tertiary()}
        />
      </Column>
    </Box>
    """
  end

  # `0 1px 3px rgba(26,25,23,.3)`, built the way `Kati.UI.paper_fade/3` builds
  # its gradient: the RGB is read off the palette and only the alpha is written
  # here, so no colour in this file is a hex literal. `Kati.Theme` has seven
  # shadow recipes and this is not one of them — a cover sits closer to the page
  # than a card does.
  defp tile_shadow do
    "0 1 3 0 #4D" <> rgb(Palette.ink(:light))
  end

  defp rgb(argb) do
    argb |> rem(0x1000000) |> Integer.to_string(16) |> String.pad_leading(6, "0")
  end

  @doc """
  Loading — a skeleton of the hero and three tracklist rows.

  A skeleton and never a spinner, which is 27's rule and this sheet's second
  eyebrow: a spinner says *something is happening*, where a skeleton says
  *this shape is coming*, and an album page that resolves into exactly the
  outline you were already reading does not appear to jump.

  Three rows rather than eleven because three is enough to establish the
  rhythm, and the fade down them is what says the list continues past the card.
  """
  @spec skeleton() :: map()
  def skeleton do
    rows =
      [1.0, 0.78, 0.56]
      |> Enum.map(fn opacity -> Kati.Screens.AlbumDetailStates.skeleton_row(opacity) end)
      |> Enum.intersperse(~MOB"<Spacer size={9} />")

    full = bar(1.0)

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={20}
        padding={15}
        shadow={Kati.Theme.shadow_card_soft()}
      >
        <Row fill_width={true} align="center">
          <Box width={80} height={80} corner_radius={12} background={full} />
          <Spacer size={13} />
          <Column weight={1.0}>
            <Box fill_width={true} height={13} corner_radius={6} background={full} />
            <Spacer size={10} />
            <Row fill_width={true}>
              <Box weight={0.6} height={11} corner_radius={6} background={full} />
              <Spacer weight={0.4} />
            </Row>
          </Column>
        </Row>
        <Spacer size={15} />
        {rows}
      </Column>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  One skeleton track row: position, title, play count.

  The three bars are the three columns `Kati.Screens.AlbumDetail.track_row/1`
  draws — a 22pt number, a title that takes the rest, and a right-aligned count
  — at 16 and 28 wide, which is what the drawing gives the outline rather than
  the text.
  """
  @spec skeleton_row(float()) :: map()
  def skeleton_row(opacity) do
    tone = bar(opacity)

    ~MOB"""
    <Row fill_width={true} align="center">
      <Box width={16} height={9} corner_radius={6} background={tone} />
      <Spacer size={12} />
      <Box weight={1.0} height={11} corner_radius={6} background={tone} />
      <Spacer size={12} />
      <Box width={28} height={9} corner_radius={6} background={tone} />
    </Row>
    """
  end

  @doc """
  A skeleton bar at one of the drawing's three opacities.

  The bridge has no opacity prop, so the fade is composited rather than
  applied: the bar colour over the page, at the row's own alpha. Doing the
  arithmetic here rather than storing the three answers is what keeps it true
  in dark — `#E7E3DC` over `#EFECE7` and `#312F2C` over `#121110` fade in
  opposite directions, and a baked literal only knows one of them.
  """
  @spec bar(float()) :: non_neg_integer()
  def bar(opacity) when is_float(opacity), do: blend(Palette.track(), Palette.paper(), opacity)

  # Straight-RGBA compositing, one channel at a time, rebuilt into an opaque
  # 0xAARRGGBB. The alpha byte is the result's, not the fade's — the bar is a
  # solid colour that happens to have been mixed.
  defp blend(fg, bg, alpha) do
    Enum.reduce([0x10000, 0x100, 1], 0xFF, fn unit, acc ->
      f = fg |> div(unit) |> rem(256)
      b = bg |> div(unit) |> rem(256)
      acc * 256 + round(f * alpha + b * (1 - alpha))
    end)
  end

  @doc """
  Error and offline, which are one eyebrow and two cards.

  They share a label because they are one situation read twice: the album did
  not load *because* the device is offline. Two eyebrows would have made them
  independent failures, and the second card exists precisely to say that the
  first one is not as bad as it looks.
  """
  @spec trouble() :: map()
  def trouble do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.AlbumDetailStates.error_card()}
      <Spacer size={10} />
      {Kati.Screens.AlbumDetailStates.offline_card()}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  The failed load, with the last success named and a way to try again.

  `Retry` is `Kati.UI.SettingsList.action_pill/1` — the same 30pt paper button
  every settings row carries — because a retry is an ordinary control on a card
  and not a destructive one. Naming the last success is what makes the card
  informative rather than apologetic: it says how stale the page is, which is
  the one thing the reader cannot see for themselves.
  """
  @spec error_card() :: map()
  def error_card do
    ~MOB"""
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
          text="Couldn’t load this album"
          text_size={13}
          font_weight="bold"
          text_color={:on_surface}
          max_lines={1}
        />
        <Spacer size={3} />
        <Text text="Last success 6h ago" text_size={11.5} text_color={Palette.sub()} max_lines={1} />
      </Column>
      <Spacer size={12} />
      {SettingsList.action_pill("Retry")}
    </Row>
    """
  end

  @doc """
  Offline — cream, and flat.

  The one card in this group with no shadow, which is the distinction 27 draws
  and this keeps: being offline is a condition the app is in, not an object
  lifted off the paper. The sub-line is a promise rather than an apology, and
  it is specific to an album because that is what makes it worth reading — play
  counts, ratings and notes are all local, so the only thing the network was
  ever going to add to this page is the cover.
  """
  @spec offline_card() :: map()
  def offline_card do
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
          text="Offline"
          text_size={13}
          font_weight="bold"
          text_color={Palette.cream_ink()}
          max_lines={1}
        />
        <Spacer size={3} />
        <Text
          text="Play counts, ratings and notes still render"
          text_size={11.5}
          text_color={Palette.cream_sub()}
          max_lines={1}
        />
      </Column>
    </Row>
    """
  end

  @doc """
  An album nobody has played: the history card, drawn, with every cell empty.

  The card keeps 74's shape down to the mono footer — see the moduledoc for why
  it is not simply hidden. `MAY` still names the month the field ends in,
  because the field is a window on the calendar rather than a summary of the
  album, and the window is there whether or not anything happened inside it.
  """
  @spec zero_plays() :: map()
  def zero_plays do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={20}
        padding={15}
        shadow={Kati.Theme.shadow_card_soft()}
      >
        {Kati.Screens.AlbumDetailStates.empty_field()}
        <Spacer size={12} />
        <Row fill_width={true} align="center">
          <Text text="MAY" font_family="mono" text_size={10} text_color={Palette.tertiary()} />
          <Spacer weight={1.0} />
          <Text
            text="Nothing logged yet"
            font_family="mono"
            text_size={10}
            text_color={Palette.tertiary()}
            max_lines={1}
          />
        </Row>
      </Column>
      <Spacer size={11} />
    </Column>
    """
  end

  @doc """
  Ninety-one empty cells, chunked at 27.

  The same count and the same chunk `Kati.Screens.AlbumDetail.field_rows/0`
  uses, so the empty field and the full one are the same rectangle on the page
  — a zero-plays card that came out a different size would read as a different
  card rather than as the same card with nothing in it. The rows carry their
  own trailing gap for the same reason 74's do.
  """
  @spec empty_field() :: map()
  def empty_field do
    rows = Enum.chunk_every(Sample.listen_field(), 27)

    ~MOB"""
    <Column fill_width={true}>
      {Enum.map(rows, fn row -> Kati.Screens.AlbumDetailStates.empty_row(row) end)}
    </Column>
    """
  end

  @doc "One row of the empty field. Takes the intensities and ignores them — only the count matters."
  @spec empty_row([non_neg_integer()]) :: map()
  def empty_row(row) do
    cells =
      row
      |> Enum.map(fn _level -> Kati.Screens.AlbumDetailStates.empty_cell() end)
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
  One unplayed day: an 8pt square that is a ring rather than a fill.

  The drawing's ring is ink at 9%, which falls between the palette's 8% and 10%
  rules and takes the stronger of the two. Three units either way, and the
  choice is made by what the card is for: this is the smallest mark on the
  page, and a field that faded out entirely would be the hidden card the design
  refused to draw.
  """
  @spec empty_cell() :: map()
  def empty_cell do
    ~MOB"""
    <Box
      width={8}
      height={8}
      corner_radius={2}
      background={Palette.transparent()}
      border_width={1}
      border_color={Palette.hairline_strong()}
    />
    """
  end

  @doc """
  The ink button, drawn and inert.

  54 tall at radius 27 where `Kati.Screens.AlbumDetail.actions/0` draws 52 at
  26, and without the two circular seconds beside it: this is the button as the
  states sheet prints it, one control standing for the action band rather than
  the band itself. It carries no `on_tap` — see the moduledoc.
  """
  @spec log_button() :: map()
  def log_button do
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
        <Text text="Log a listen" text_size={14.5} font_weight="bold" text_color={Palette.on_ink()} />
        <Spacer weight={1.0} />
      </Row>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  The whole page in dark, reduced to the three things that change.

  Hero, history field, note — because those are the three surfaces screen 28's
  rules actually touch. The tile inverts to a near-black square whose initial is
  barely there, the field card lifts on a hairline where light gives it a
  shadow, and cream warms rather than darkens. Every colour is taken through the
  palette's explicit `:dark` arm, so this inset draws dark on a light page
  without a theme switch that would repaint the five states above it.
  """
  @spec dark(map()) :: map()
  def dark(a) do
    ~MOB"""
    <Column fill_width={true} background={Palette.paper(:dark)} corner_radius={22} padding={16}>
      <Row fill_width={true} align="center">
        <Box
          width={64}
          height={64}
          corner_radius={12}
          background={Palette.placeholder(:dark)}
          border_width={2}
          border_color={Palette.card(:dark)}
          align="center"
        >
          <Text
            text={a.initial}
            font_family="mono"
            text_size={26}
            text_align="center"
            text_color={Palette.track_off(:dark)}
          />
        </Box>
        <Spacer size={13} />
        <Column weight={1.0}>
          <Text
            text={a.title}
            text_size={15}
            font_weight="bold"
            letter_spacing={-0.02}
            text_color={Palette.ink(:dark)}
            max_lines={1}
          />
          <Spacer size={4} />
          <Text text={a.byline} text_size={11.5} text_color={Palette.sub(:dark)} max_lines={1} />
        </Column>
      </Row>
      <Spacer size={14} />
      <Column
        fill_width={true}
        background={Palette.card(:dark)}
        corner_radius={18}
        padding={14}
        border_width={1}
        border_color={Palette.card_hairline(:dark)}
      >
        {Kati.Screens.AlbumDetailStates.dark_field()}
      </Column>
      <Spacer size={11} />
      <Column fill_width={true} background={Palette.cream(:dark)} corner_radius={18} padding={14}>
        <Text
          text="Cream warms to #2A2622 with #F7EFE4 text; cards lift on a hairline, not a shadow."
          text_size={12.5}
          line_height={1.6}
          text_color={Palette.cream_ink(:dark)}
        />
      </Column>
    </Column>
    """
  end

  @doc """
  The first fifty-two days of the field, on the inset's narrower card.

  `Kati.Screens.AlbumDetail.field_row/1` unchanged, and that is the claim worth
  making: the five listening tones are hues, so they hold at full strength on
  near-black exactly as screen 28 keeps its orange, and the dark field is the
  light field on a different card rather than a second ramp to keep in step.
  Only the chunk moves, because only the card is narrower.
  """
  @spec dark_field() :: map()
  def dark_field do
    rows =
      Sample.listen_field()
      |> Enum.take(@dark_cells)
      |> Enum.chunk_every(@dark_per_row)

    ~MOB"""
    <Column fill_width={true}>
      {Enum.map(rows, fn row -> Kati.Screens.AlbumDetail.field_row(row) end)}
    </Column>
    """
  end
end
