defmodule Kati.Screens.YearShareDark do
  @moduledoc """
  Screen 102 — screen 98's share board, in the dark colourway.

  Built to `.scratch/design/pending/102.html`. It is the same page as
  `Kati.Screens.YearShare` in the sense screen 68 is the same page as screen
  66: the same bands in the same order, the same copy, the same writes, and
  deliberately **not** an inversion. The chrome, the title and its mono
  subtitle, the six scope labels, the `Aspect` eyebrow with its segmented
  control, the privacy sentence and the closing note are all 98's, read through
  `Kati.Stats.ShareSample` so the two boards cannot disagree about which year
  they are about.

  ## The card is the file, so the card goes dark

  The drawing's caption is the whole brief: *a saved image carries the theme it
  was made in, so the card itself goes dark — not just the chrome around it.*
  `Kati.Screens.YearShare.card/0` states the same rule from the other side —
  a preview sitting on a different colour from the file would be a preview of
  something else — and dark is where that stops being a note about padding. A
  paper card floating on `#121110` would be an accurate picture of the *light*
  export and a wrong picture of this one.

  So the preview keeps 98's frame exactly — radius 22, 19pt of padding, the
  22pt gap under it — and changes one prop: `Kati.Theme.shadow_card/0` becomes
  the `Kati.Theme.Palette.card_hairline/0` border pair, for screen 68's reason.
  On near-black a shadow is near-black on near-black and there is nothing to
  see, so dark lifts with a hairline or it does not lift at all.

  ## The bronze ramp had to be written out, and the palette already knew it

  `Kati.UI.pixel/1` carries the warning this screen walked into, in its own
  comment: the field's five tones are hex literals, four of them in no
  `Kati.Theme.Palette` row at all, and *step 0 is a pale warm grey that is a
  whole field of near-white squares on a near-black card. The field needs a
  ramp of its own in the palette before it can be converted.* This board is
  that card. `Kati.Stats.Sample.intensity/1` and `Kati.Music.Sample.tone/1` are
  the other two copies of the same problem, and neither follows the ground
  either, so `Kati.Screens.AlbumDetail.field_rows/0` — the field screen 100's
  own face draws — cannot be called here.

  `field_tone/1` is therefore the drawing's five steps named against the
  nearest token, and two of the five are exact:

    * **Level 0** is `Kati.Theme.Palette.poster_on_cream/0`, whose dark value
      *is* the drawing's `#3A342D`.
    * **Level 4** is `Kati.Theme.Palette.ink/0`, whose dark value *is* the
      drawing's `#F5F2EE` — and which is also the light ramp's own top step,
      `Kati.Music.Sample.tone(4)` being `#1A1917`. The brightest cell inverts
      because the token inverts, not because anybody chose it.
    * **Level 3** is `Kati.Theme.Palette.bronze/0`, which is
      `Kati.Music.Sample.tone(3)` exactly and takes no mode, so it is the one
      cell that is the same colour on both boards: `#B08E55` where the drawing
      writes `#9A7D4C`.
    * **Levels 1 and 2** are `on_ink_muted/0` (`#4A4238` for `#4E4437`) and
      `cream_meta/0` (`#7A6F5E` for `#6E5C42`). Both names are wrong for the
      job — one belongs on an ink fill, the other on a cream card — and both
      values are the closest warm step the table holds. Screen 77's dark chart
      took the same trade and stated it: a token two units out is a colour, and
      a hex literal here would be a colour nothing else in the app could follow
      into a future mode.

  Five steps that still read as five on `#1E1D1B`, which is what the caption
  asks for. The fix is the ramp `Kati.UI.pixel/1` names — five rows in
  `Kati.Theme.Palette` — at which point `field_tone/1` is deleted rather than
  corrected.

  ## The bar ramp inverts by itself, because every step of it is already a token

  It is not `Kati.Screens.YearCards.tone/1`, though this is 100's face. That
  ladder ends `bar_ink` → `settled_ink` → `tertiary`, and in dark its last two
  steps are `#79736D` and `#6A6560`: fifteen units apart on a near-black card,
  which is the caption's four legible steps delivered as three. `bar_tone/1`
  uses `ink` → `meta` → `settled_ink` → `rail_idle` instead — `#F5F2EE`,
  `#B6B1AB`, `#79736D`, `#4A453F` against the drawing's `#F5F2EE`, `#B8B2A8`,
  `#7C766D`, `#4A4640`. That ladder is not invented here either:
  `Kati.Screens.ArtistDetailStates` chose those four tokens for this exact set
  of drawn values, and the reasoning belongs to it.

  ## What the preview shows, and why it is one card

  The drawing's carousel holds the field face and the breakdown face where
  98's holds hours and top titles. Both pairs are members of
  `Kati.Stats.ShareSample.faces/0`, so nothing is invented — and the two this
  drawing lights are the two the caption is about, because the two ramps live
  in them. They are collapsed into one full-width card for screen 99's reason:
  both artboards draw two 252pt cards over four dots, and four dots over one
  card would be a pager pointing at three cards this screen does not have.
  Screen 100 is the board that draws all four faces, at both ratios.

  The field is `Kati.Stats.Sample.contributions/0` — 182 days, which its own
  doc counts as 26 weeks — chunked at 26 with screen 07's cell: 8pt square,
  2pt radius, and `Kati.Screens.Stats.cell_gap/0` between them in both axes, so
  there is one 4pt gap in the app and not a second one here. 26 × 8 + 25 × 4 is
  308 inside the card's 322, which is the same arithmetic 07 records. The
  drawing wraps 104 cells at sixteen to the row; that is what `flex-wrap` did
  inside a 252pt card rather than a decision, a `Row` does not wrap, and 26 is
  the number `26 WEEKS` under the field asks the reader to count. Only 07's
  geometry and 07's days cross over — never its colours, which are the orange
  ramp, and `Kati.Stats.ShareSample.palette_note/0`'s rule is that no card
  carries orange because a saved image has no *now* to point at.

  ## Where the drawing and screen 98 disagree, and 98 wins

  A colourway that re-decided behaviour would report a difference the app does
  not have, so where this artboard and the built screen differ, the built
  screen is reproduced:

    * **The lit chip.** Both artboards light `Screen`; 98's `load/1` opens on
      `All`. Which chip a page opens on belongs to the page, and this is the
      same page — opening on `Screen` here would say the colourway had changed
      what the card is about.
    * **The switch.** Both artboards draw `Hide titles I marked private` on and
      both screens start it off, for the reason screen 99 gives.
    * **The `Share…` line.** The drawing sinks it to `#4A4640` over `#3A3733`
      and drops 98's pill. 98's own doc says why it cannot: `WHEN FILE SHARING
      LANDS` is the idiom screen 119 uses for a path that is drawn and not
      built, and *designed, not built* has to look the same wherever it
      appears. The pill and its two tokens stay.
    * **The note's ground.** Both drawings put the closing sentence on cream;
      `Kati.UI.SettingsList.note/2` draws an outline, and 98 called it
      regardless — except the no-server note, which the dark board cuts short.
      98 writes *nothing about your year is uploaded to make it — Kati has no
      server that could receive it*; 102 stops at the full stop. The clause is
      an argument and the sentence is a fact, and a board whose whole subject is
      how the same page looks in the dark does not need to make the argument
      twice. `no_server_note/0` here is that shorter cut.

  ## The four things this file owns

  Everything else is a call. The card frame's lift, the two ramps above, the
  scope chips and the `Save image` pill — and the last two are one decision:
  `Kati.UI.chip/2` and `Kati.Screens.YearShare.actions/0` both hardcode
  `ink_fill` under `on_ink`, which in dark is screen 28's *cream* CTA,
  `#F7EFE4` on `#1A1917`. That pill belongs to the hero on Home; this page
  draws paper on near-black, which is `Kati.Theme.Palette.fab_fill/0` under
  `fab_glyph/0` and is exactly what the drawing writes. The chip is not copied
  a third time — `Kati.Screens.BookDetailDark.chip/3` is that pill already, and
  `Kati.Screens.BookDetailDark.card/1` is the grouped card that lifts with a
  hairline instead of the shadow `Kati.UI.SettingsList.card/1` paints
  unconditionally. Two dark containers, one definition each.

  ## Pinning the theme, and what it costs

  `load/1` calls `Mob.Theme.set(Kati.Theme.dark())`, the same single switch
  screens 28, 29 and 68 make, because `Kati.Screens.Pushed`'s `mount/3`
  resolves the user's Auto / Light / Dark preference and this screen is the
  reference for what the share board looks like in a light-mode app. The cost
  is screen 68's, restated rather than hidden: `Mob.Theme.set/1` is global, so
  the app stays dark until the next screen mounts — and `Save image` mounts one
  immediately, since it pushes screen 100, which activates the preference again
  and hands the user a light render sheet from a dark board. That closes when
  dark stops being a separate page and becomes a mode `Kati.Shell` carries, at
  which point this module folds back into `Kati.Screens.YearShare`.
  """

  use Kati.Screens.Pushed, back: "Stats"

  alias Kati.Components.MishkaProgress
  alias Kati.Screens.BookDetailDark
  alias Kati.Screens.YearShare
  alias Kati.Stats.Sample
  alias Kati.Stats.ShareSample
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  # The tags `Kati.Screens.YearShare.handle_tap/2` answers that mean the same
  # thing on both boards. Listed rather than caught, so a fifth control added to
  # 98's markup arrives here as a DEAD TAP report instead of a delegation that
  # quietly does the wrong thing.
  @borrowed [:toggle_private, :save_image, :aspect_square, :aspect_story]

  # One column per week, which is the number `26 WEEKS` under the field asks the
  # reader to count, and screen 07's own chunk. See the moduledoc for why the
  # drawing's sixteen is not a number to reproduce.
  @per_row 26

  @doc """
  The board's three assigns, over a theme pinned dark.

  `Mob.Theme.set/1` before the assigns rather than after: every token below
  resolves through `Kati.Theme.Palette.mode/0`, which reads the theme that is
  actually installed, so the switch has to be in place before the first render
  asks it anything.
  """
  @impl true
  @spec load(Mob.Socket.t()) :: Mob.Socket.t()
  def load(socket) do
    Mob.Theme.set(Kati.Theme.dark())

    socket
    |> Mob.Socket.assign(:scope, "All")
    |> Mob.Socket.assign(:aspect, :aspect_square)
    |> Mob.Socket.assign(:hide_private, false)
  end

  @doc """
  The dark board's own no-server note, cut one clause shorter than 98's.

  98 writes *nothing about your year is uploaded to make it — Kati has no server
  that could receive it*, and the clause after the dash is the proof rather than
  the claim. This board's subject is the colourway, and it stops at the fact.
  """
  @spec no_server_note() :: map()
  def no_server_note do
    Kati.UI.SettingsList.note(
      "info",
      "Every card is drawn on this device. Nothing about your year is uploaded to make it."
    )
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
        {SettingsList.title("Your year, shared", ShareSample.subtitle())}
        {Kati.Screens.YearShareDark.scopes(assigns.scope)}
        {Kati.Screens.YearShareDark.card()}
        {UI.eyebrow("Aspect")}
        {Kati.UI.Segmented.plain(Kati.Screens.YearShare.aspects(), assigns.aspect)}
        <Spacer size={16} />
        {Kati.Screens.YearShareDark.privacy_row(assigns.hide_private)}
        <Spacer size={16} />
        {Kati.Screens.YearShareDark.actions()}
        <Spacer size={16} />
        {Kati.Screens.YearShareDark.no_server_note()}
      </Column>
    </Scroll>
    """
  end

  @doc """
  The scope chips, in the one treatment dark has to change.

  `Kati.Screens.YearShare.scopes/1` is not called through, and the six labels
  it would have supplied are read from `Kati.Stats.ShareSample.scopes/0`
  directly so that the two boards still cannot disagree about them. What could
  not come across is the pill: that builder reaches `Kati.UI.chip/2`, which
  fills a selected chip with `ink_fill` under `on_ink` — cream on near-black in
  dark, where this drawing wants paper. `Kati.Screens.BookDetailDark.chip/3` is
  that inversion already, written once on screen 68 with its own reasoning, so
  it is called rather than copied.

  Every chip carries a `scope_…` tag, so the band writes and is not a picture
  of a band; the tag lands on 98's own parser at the other end.
  """
  @spec scopes(String.t()) :: map()
  def scopes(active) do
    chips =
      ShareSample.scopes()
      |> Enum.map(fn scope ->
        BookDetailDark.chip(scope, scope == active, String.to_atom("scope_" <> scope))
      end)
      |> Enum.intersperse(~MOB"<Spacer size={7} />")

    ~MOB"""
    <Column fill_width={true}>
      <Scroll axis="horizontal">
        <Row>
          {chips}
        </Row>
      </Scroll>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc """
  The card preview: the field face and the breakdown face, as they will be
  saved.

  98's frame to the point — radius 22, 19pt of padding, a 22pt gap under it —
  with the shadow swapped for the hairline, because a card that lifted the way
  the light board lifts would not lift at all here. Both faces read
  `Kati.Stats.ShareSample`, so the year, the span, the wordmark and the four
  genre figures are the same values screen 100 renders into the actual file.
  """
  @spec card() :: map()
  def card do
    face = ShareSample.field_face()

    assigns = %{
      label: String.upcase(face.title),
      span: face.span,
      wordmark: face.wordmark,
      year: ShareSample.hours().year,
      field: field(),
      bars: bars()
    }

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        border_width={1}
        border_color={Palette.card_hairline()}
        padding={19}
      >
        <Text
          text={@label}
          font_family="mono"
          text_size={10}
          letter_spacing={0.14}
          text_color={Palette.muted()}
        />
        <Spacer size={11} />
        {@field}
        <Spacer size={13} />
        <Row fill_width={true} align="center">
          <Text
            text={@span}
            font_family="mono"
            text_size={10}
            text_color={Palette.muted()}
            max_lines={1}
          />
          <Spacer weight={1.0} />
          <Box width={9} height={9} corner_radius={5} background={Palette.ink()} />
          <Spacer size={6} />
          <Text
            text={@wordmark}
            font_family="mono"
            text_size={10.5}
            text_color={Palette.sub()}
            max_lines={1}
          />
        </Row>
        <Spacer size={20} />
        <Text
          text="WHERE THE HOURS WENT"
          font_family="mono"
          text_size={10}
          letter_spacing={0.14}
          text_color={Palette.muted()}
        />
        <Spacer size={12} />
        {@bars}
        <Spacer size={16} />
        <Text
          text={@year}
          font_family="mono"
          text_size={22}
          letter_spacing={-0.03}
          text_color={Palette.track_off()}
        />
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  The field: screen 07's year, at screen 07's metric, on this board's ramp.

  The days are `Kati.Stats.Sample.contributions/0` and the cell is 07's — 8pt
  square at 2pt radius, `Kati.Screens.Stats.cell_gap/0` in both axes — because
  the caption under this face is 07's caption and a second field metric drawn
  at the same size would read as a second unit. The chunk is declared, at 26,
  since a `Row` does not wrap and no geometry comes back from `render/1`.

  Filled row-major, which is not how a contribution grid is usually filled —
  column-major would put a week in each column — and it is not made
  column-major here because `Kati.UI.pixel_field/2` and `Kati.Screens.Stats`
  both fill this data row-major already. On a card meant to be saved the field
  is a texture of a year rather than a calendar anybody points a Tuesday at.
  """
  @spec field() :: map()
  def field do
    rows = Enum.chunk_every(Sample.contributions(), @per_row)

    ~MOB"""
    <Column fill_width={true}>
      {rows
       |> Enum.map(fn row -> Kati.Screens.YearShareDark.field_row(row) end)
       |> Enum.intersperse(Kati.Screens.Stats.cell_gap())}
    </Column>
    """
  end

  @doc false
  @spec field_row([0..4]) :: map()
  def field_row(row) do
    ~MOB"""
    <Row>
      {row
       |> Enum.map(&Kati.Screens.YearShareDark.cell/1)
       |> Enum.intersperse(Kati.Screens.Stats.cell_gap())}
    </Row>
    """
  end

  @doc false
  @spec cell(0..4) :: map()
  def cell(level) do
    tone = field_tone(level)

    ~MOB"""
    <Box width={8} height={8} corner_radius={2} background={tone} />
    """
  end

  @doc """
  The bronze ramp restated against near-black, one token per step.

  The light ramp cannot come across: `Kati.Music.Sample.tone/1` is five hex
  literals ending on ink, so on `#1E1D1B` its heaviest day would be the one
  nobody can see and its emptiest a near-white square. See the moduledoc for
  which of these five are the drawing's values exactly (levels 0 and 4), which
  is the same colour in both modes (level 3, a hue), and why the two in the
  middle are named against tokens whose names belong to other jobs.
  """
  @spec field_tone(0..4) :: pos_integer()
  def field_tone(0), do: Palette.poster_on_cream()
  def field_tone(1), do: Palette.on_ink_muted()
  def field_tone(2), do: Palette.cream_meta()
  def field_tone(3), do: Palette.bronze()
  def field_tone(_lit), do: Palette.ink()

  @doc """
  Where the hours went: four genres, longest first.

  The figures and their order are `Kati.Stats.ShareSample.where_hours_went/0`,
  and the share of the rail is each genre against the longest of them — the
  same arithmetic `Kati.Screens.YearCards.bar/5` does, so a card saved from
  this board and the render spec cannot draw the same four hours at two
  lengths.
  """
  @spec bars() :: map()
  def bars do
    top = ShareSample.where_hours_went() |> Enum.map(&elem(&1, 1)) |> Enum.max()

    rows =
      ShareSample.where_hours_went()
      |> Enum.with_index()
      |> Enum.map(fn {{genre, hours}, index} ->
        Kati.Screens.YearShareDark.bar(genre, hours, top, index)
      end)
      |> Enum.intersperse(~MOB"<Spacer size={11} />")

    ~MOB"""
    <Column fill_width={true}>
      {rows}
    </Column>
    """
  end

  @doc """
  One genre bar: name, rail, hours, on one line.

  The rail is `Kati.Components.MishkaProgress.progress/1` in `:box` mode, which
  is the only bar in this app that is a shape rather than a control. Both
  gutters are declared — 78 for the name and 24 for the figure — because the
  four rows have to align down the card and nothing measures text for us; the
  name ellipsizes into its 78 rather than pushing the rail short.
  """
  @spec bar(String.t(), integer(), integer(), integer()) :: map()
  def bar(genre, hours, top, index) do
    rail =
      MishkaProgress.progress(
        render: :box,
        value: hours / max(top, 1),
        max: 1,
        height: 8,
        corner_radius: 4,
        color: Kati.Screens.YearShareDark.bar_tone(index),
        track_color: Palette.track()
      )

    assigns = %{genre: genre, hours: Integer.to_string(hours), rail: rail}

    ~MOB"""
    <Row fill_width={true} align="center">
      <Text
        text={@genre}
        width={78}
        text_size={11.5}
        font_weight="semibold"
        text_color={:on_surface}
        max_lines={1}
      />
      <Spacer size={11} />
      <Column weight={1.0}>
        {@rail}
      </Column>
      <Spacer size={11} />
      <Column width={24}>
        <Text
          text={@hours}
          font_family="mono"
          text_size={11}
          text_color={Palette.muted()}
          text_align="right"
          max_lines={1}
        />
      </Column>
    </Row>
    """
  end

  @doc """
  The four-step bar ramp, brightest first.

  A ramp rather than a hue per genre, for the reason screen 100 gives: a saved
  image has no legend beside it, and four colours meaning four genres would
  need one. Not `Kati.Screens.YearCards.tone/1` — the moduledoc has the two
  dark values that collapse there and the four tokens that do not.
  """
  @spec bar_tone(integer()) :: pos_integer()
  def bar_tone(0), do: Palette.ink()
  def bar_tone(1), do: Palette.meta()
  def bar_tone(2), do: Palette.settled_ink()
  def bar_tone(_rest), do: Palette.rail_idle()

  @doc """
  The one privacy control on the page, in the container dark can see.

  The row itself is 98's, word for word and tag for tag. Only the card around
  it moves: `Kati.UI.SettingsList.card/1` paints `Kati.Theme.shadow_card_soft/0`
  unconditionally, which on near-black is two near-black layers over a
  near-black ground — correct in light, and here a card with no edge at all.
  `Kati.Screens.BookDetailDark.card/1` is that geometry with the hairline, and
  everything inside it — the icon tile, the body and the switch — is already
  mode-aware and untouched.
  """
  @spec privacy_row(boolean()) :: map()
  def privacy_row(on?) do
    BookDetailDark.card([
      SettingsList.row(
        SettingsList.icon_tile("visibility_off"),
        SettingsList.body("Hide titles I marked private", nil),
        SettingsList.trailing(SettingsList.switch(on?)),
        on_tap: {self(), :toggle_private}
      )
    ])
  end

  @doc """
  Save, and the share that is still waiting on a fence.

  `Kati.Screens.YearShare.actions/0` with the two colours on the filled control
  changed and nothing else: paper under near-black, which is
  `Kati.Theme.Palette.fab_fill/0` under `fab_glyph/0`, because an ink fill on a
  near-black page is a button you cannot see. `Share…` keeps 98's pill and 98's
  tokens — see the moduledoc for why the drawing's dimmer, pill-less version is
  not reproduced — so *designed, not built* looks the same in both colourways.
  """
  @spec actions() :: map()
  def actions do
    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        height={52}
        corner_radius={26}
        background={Palette.fab_fill()}
        align="center"
        on_tap={{self(), :save_image}}
      >
        <Spacer weight={1.0} />
        <Text
          text="Save image"
          text_size={15}
          font_weight="bold"
          letter_spacing={-0.01}
          text_color={Palette.fab_glyph()}
        />
        <Spacer weight={1.0} />
      </Row>
      <Spacer size={11} />
      <Row fill_width={true} align="center">
        <Spacer weight={1.0} />
        <Text text="Share…" text_size={13.5} font_weight="semibold" text_color={Palette.ink_soft()} />
        <Spacer size={9} />
        <Row
          height={22}
          corner_radius={11}
          background={Palette.track()}
          padding_left={9}
          padding_right={9}
          align="center"
        >
          <Text
            text="WHEN FILE SHARING LANDS"
            font_family="mono"
            text_size={9}
            letter_spacing={0.1}
            text_color={Palette.sub()}
            max_lines={1}
          />
        </Row>
        <Spacer weight={1.0} />
      </Row>
    </Column>
    """
  end

  @doc """
  Every tap on this board is screen 98's tap, answered by screen 98.

  Including the scope chips, which relight over a card that does not follow
  them — that is 98's small untruth and a colourway does not get to settle it
  differently. A tag that is neither borrowed nor a scope goes to
  `Kati.Screens.Root.unhandled_tap/3` rather than being swallowed.
  """
  @impl true
  @spec handle_tap(atom(), Mob.Socket.t()) :: {:noreply, Mob.Socket.t()}
  def handle_tap(tag, socket) when tag in @borrowed, do: YearShare.handle_tap(tag, socket)

  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "scope_" <> _section -> YearShare.handle_tap(tag, socket)
      _other -> Kati.Screens.Root.unhandled_tap(__MODULE__, tag, socket)
    end
  end
end
