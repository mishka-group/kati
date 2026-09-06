defmodule Kati.Screens.ShelfSelection do
  @moduledoc """
  Board 146 — Shelf, selection mode.

  Built to `test/design/screens/146.html`, which is three drawings wearing
  one artboard: the shelf's **resting** header with a persisted sort named on
  it, the shelf **in selection mode** at `1 selected` and at `4 selected`, and
  what a destructive action leaves behind — screen 27's dark undo pill. This
  screen is the live thing all three are frames of, so the count header is a
  function of how many tiles are selected rather than two hardcoded bands:
  selecting or deselecting a tile walks between the board's own two header
  vignettes rather than choosing one of them forever.

  ## A still is labelled and has no `on_tap`; the live band is neither

  A live screen can only be in one moment at a time and the board holds three
  at once, so every moment this screen is *not* in is drawn the way screens 27
  and 71 draw a state they are illustrating rather than offering: under its own
  mono eyebrow, and with **no `on_tap` anywhere inside it**.

  That second half is stricter than 71's board, deliberately. 71 wired the
  stepper inside its states and then had to book three taps as inert, because a
  control drawn inside a picture of a control answers to nothing by
  construction — `Kati.ScreenTapSweepTest`'s `@inert_taps` carries the line
  saying so. A still with no tag at all cannot be mistaken for a dead button by
  a user or by that sweep, and it costs nothing: `Kati.UI.SettingsList.
  action_pill/1` and `Kati.Components.MishkaActionIcon.action_icon/2` both draw
  without a handler, so the picture is the same picture.

  Two of the three stills withdraw the moment the screen really is in them:

    * `one_selected_still/1` draws the board's `1 selected` vignette until the
      live header IS at one, and then draws nothing. Two identical cards under
      two identical labels reads as a bug rather than as a reference.
    * `undo_band/1` draws the board's own `Removed 4 titles` until a `Remove`
      actually happens, and then hands the same row its live count and its
      `Undo` tap.

  The third has no live counterpart on this screen at all, and the next section
  is why.

  ## The resting header is `Kati.Screens.Library`'s, drawn as a picture

  The board's first eyebrow is `Resting header — sort persists and says so`,
  over an ordinary Library header and a dashed note arguing that a sort which
  survives the trip has to be *named* where it can be read. That is a decision
  about **Library's** resting header, and `Kati.Screens.Library` is the module
  that owns it — so this band is a still of that header rather than a second
  implementation of it: the board's own 22pt title, its mono line, and its two
  40pt discs, none of them tapped.

  Wiring `search` and `tune` here is the thing the still exists to avoid. They
  are controls on a header this screen does not own, and a live one on a band
  whose whole subject is *what another screen's resting state says* would be
  two real controls smuggled into a caption. When 03, 20 and 21 are redrawn
  with the trailing filter disc #19 asks for, the taps land there.

  Its mono line is not typed out twice, either. `41 OF 418 · RECENTLY ADDED` is
  board 145's own filtered shelf, so `sort_line/0` reads the 418 off
  `Kati.Library.ShelfFiltersSample.total/0` and the sort's name off the first
  row of `sort_options/0` — the two boards cannot drift apart on the size of
  the shelf or on what the sort is called. The 41 is the one figure left as a
  literal, for the reason `Kati.Screens.ShelfFilters`'s own moduledoc gives at
  length: it is not the size of any bucket, nothing computes it, and it is
  meant to be shown rather than counted.

  ## What is still deliberately not here

  The board's caption states the >10-selected rule — *"the actions collapse
  behind an overflow disc"* — as a decision for **screen 147**'s 235% frame,
  not for 146. Nothing here draws an overflow disc; past ten, `actions/2` still
  lays out the two-pill row.

  ## Neither `Kati.Screens.Pushed` nor `Kati.Screens.Root`

  The drawing has no back pill and no dock — the `close` glyph is inline in
  the header card, not a floating 44pt disc, and the page ends at its own
  content rather than at a tab bar. `Kati.Screens.Rating` (screen 33) is the
  precedent for exactly this shape: *"it carries its own dismissal … not the
  pushed back pill … No dock, so the frame closes at 40 rather than 132."*
  This screen follows it — plain `use Mob.Screen`, `close` pops the screen,
  `padding_bottom={40}`.

  ## The data: `Kati.Library.Sample.selection_shelf/0`

  Screen 03's `Kati.Library.Sample.titles/0` already carries The Long Hollow,
  Salt & Iron and Nightbirds, but 146 does not print `Kati.Screens.Library.
  tile_meta/1`'s `62% watched` — it prints `S2 · 5/7`, a season and an
  episode fraction, which is a different sentence about the same shelf. A
  second sample list carries that sentence rather than teaching the first
  one two dialects; see its own doc for the two names it adds to reach the
  board's own "4 selected" past its 402pt crop.

  ## The ring is a border, because Compose has no ring

  `box-shadow: 0 0 0 2px #1A1917, 0 8px 18px -14px rgba(26,25,23,.7)` is not
  a shadow so much as a solid outline plus a lift, and the outline is a
  `border`, the same reading `Kati.Screens.Search.field/1`, `Kati.Screens.
  QuickAdd`'s field and `Kati.Screens.Onboarding`'s chosen poster all give
  the identical CSS. `border_width={2}` and `border_color={Palette.ink()}`
  on the poster's own `Box`, same as those three — not the inset wrapper
  `Kati.Screens.Onboarding` builds for its two-up grid, because that inset
  exists to keep a *ring drawn outside the box* from pushing two 50%-width
  tiles past the gutter; a three-across weighted row has no such budget
  problem and the plain border is what every non-grid ring in the app uses.
  The `0 8 18 -14 #B31A1917` lift has no name in `Kati.Theme` — it is a
  single layer where `shadow_card_soft/0` is two — so it is written out, the
  same call `Kati.Screens.Search.field/1` makes for its own custom ring.

  ## The badge

  24pt, radius 12, `#1A1917` fill, a 15pt check in `Palette.on_ink/0`, lifted
  `0 2 6 0 #661A1917` — `Kati.Components.MishkaThemeIcon.theme_icon/2`, the
  same component `Kati.Screens.Onboarding.tick/3` calls for its own poster
  badge, at this board's own numbers rather than that one's (ink, not accent;
  8pt inset, not 9; a shadow of its own, which onboarding's tick does not
  carry).

  ## The dashed note is drawn solid

  `1.5px dashed rgba(26,25,23,.16)`, the same border `Kati.Screens.
  EpisodeRatings.rating_note/0` and `Kati.Screens.AddTitle`'s `by_hand/0`
  carry: the bridge's border is `Modifier.border`, which takes a width and a
  colour and no dash pattern, so the dash is the one thing on this band that is
  not the drawing. The colour, `Palette.border/0`, is — and so is every other
  number, down to the 17pt `info` glyph in `Palette.sub/0` and the 12.5/1.65
  body in `Palette.ink_soft/0`.

  ## Three pills, and the count decides how many

  `Add to list · Status · Remove` at one selected; `Add to list · Remove` at
  more than one — the drawing drops `Status` rather than disabling it, so
  `actions/2` does too. `Add to list` and `Status` are `Kati.UI.SettingsList.
  action_pill/1` at the board's own `30/12/15/11.5` — the component was
  built to those four numbers already. `Remove` is not: its `rgba(180,85,60,
  .1)` background and `#B4553C` label are `Palette.red_wash/0` and `Palette.
  red/0`, which `action_pill/1` has no colour override to reach, so it calls
  `Kati.Components.MishkaPill.pill/2` directly at the same four numbers with
  the destructive pair instead.

  ## What each pill actually does

    * **`Add to list`** pushes `Kati.Screens.Lists` (screen 12) — a real
      destination screen 03 already opens the same way, and the closest thing
      to "add to list" this app can reach without a list-picker sheet the
      board does not draw.
    * **`Status`** flips a `done?` flag on the one selected title, toggling
      its mono line to `done` and back. The board draws no status sheet
      behind this pill — that is 148's subject, not 146's — so this is the
      smallest real state change the pill can make rather than an invented
      picker standing in for one. It reads `MapSet.to_list/1` and acts only
      when that list has exactly one member, which is also the only time the
      header offers the pill at all.
    * **`Remove`** moves the selected rows out of `titles` and into `undo`,
      which is what turns the still pill below into a live one — see below.

  ## The undo pill is screen 27's, token for token

  `Kati.Screens.States.undo/1` is the drawn reference for *"every destructive
  action leaves an undo bar behind"* — `Kati.Theme.ink()` fill, `#FBFAF8`
  icon and message, `#E8823C` action word. This screen reads those same three
  as `Palette.ink/0`, `Palette.on_ink/0` and `Palette.accent/0`, which are
  that trio's exact light values.

  27's eyebrow over that pill — `Undo — every destructive action` — is
  borrowed with it, and that is not invented copy: 146's board draws the pill
  with no label of its own, and the sibling board that *owns* the pill states
  the rule in one line. It is what makes a dark bar reading `Removed 4 titles`
  on a shelf where nothing has been removed legible as the demonstration it is
  rather than as a claim about this session. Once a `Remove` really happens the
  same row carries the real count and the `Undo` tap, which restores the
  removed rows, reselects them and clears the assign — so the whole cycle is
  reachable rather than a one-way trapdoor.

  ## The cream note is new copy, not screen 143's

  Screen 143 (`Kati.Screens.EpisodeRatings`) already carries a cream `call_
  split` note ending *"Also on 146"* — the gesture rule alone. 146's own note
  is longer: it opens with the filter-persistence rule and only then states
  the same gesture rule, closing `Also on 143`. Two different paragraphs, so
  this screen writes its own rather than calling the sibling's. `filter_
  note/0` follows 143's own `gesture_rule_note/0` exactly — `Palette.cream/0`
  ground, `Palette.gold_icon/0` glyph, `Palette.cream_body/0` body, `Kati.UI.
  rich_text/1` for the bold runs. Per that helper's own doc, the bridge has
  no `AnnotatedString`: every run renders at one style, so the four spans the
  drawing sets in `#1A1917` semibold render in the paragraph's own ink but
  not any heavier. The words survive; the emphasis does not yet.
  """

  use Mob.Screen
  import Mob.Sigil

  alias Kati.Components.MishkaActionIcon
  alias Kati.Components.MishkaPill
  alias Kati.Components.MishkaThemeIcon
  alias Kati.Library.Sample
  alias Kati.Library.ShelfFiltersSample
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  @count_words %{
    1 => "one",
    2 => "two",
    3 => "three",
    4 => "four",
    5 => "five",
    6 => "six",
    7 => "seven",
    8 => "eight",
    9 => "nine",
    10 => "ten"
  }

  # Board 145's own `showing 41 of 418`, and the only number on this screen
  # that is a literal rather than a read. See the moduledoc.
  @drawn_showing 41

  # The board's undo pill, frozen at the count its own header is selecting.
  @drawn_removed 4

  def mount(_params, _session, socket) do
    Kati.Theme.activate()
    {:ok, load(socket)}
  end

  @doc false
  def load(socket) do
    titles = Kati.Screens.ShelfSelection.shelf()
    selected = titles |> Enum.filter(& &1.selected?) |> Enum.map(& &1.id) |> MapSet.new()

    Mob.Socket.assign(socket, titles: titles, selected: selected, undo: nil, save_error: nil)
  end

  @doc """
  The shelf this screen selects from: the user's, or the drawing's.

  All-or-nothing, the same gate `Kati.Screens.Season.season/1` applies and for
  the same reason: a grid of the reader's own posters with the drawing's two
  tiles selected inside it is a page that looks entirely real and is half
  invented. On a shelf with rows, nothing starts selected — selection mode
  opens with an empty selection, which is what entering it means.

  This was MOVIES-AND-TV.md #27's first half. `Kati.Library.Sample.selection_
  shelf/0` was the ONLY thing this screen had ever read, so Remove removed
  Nightbirds from a list of nine invented titles and the user's own shelf was
  untouched behind it.
  """
  @spec shelf() :: [map()]
  def shelf do
    case Kati.Screens.ShelfSelection.tracked_shelf() do
      [] -> Sample.selection_shelf()
      rows -> rows
    end
  end

  @doc """
  The user's shelf in this screen's own shape, or `[]`.

  `Kati.Screens.Library.shelf/0` does the reading — one shelf, one reader.
  Screen 03 draws these exact rows behind this one, and two gatherings able
  to disagree is how a selection removes a title the grid under it never had.

  `source` and `source_id` come off the tracked row rather than off the shape,
  because `Kati.Screens.Library.shaped/5` does not carry them and Undo needs
  them: a destroyed row can only be put back by the pair it was keyed on.
  """
  @spec tracked_shelf() :: [map()]
  def tracked_shelf do
    by_id =
      Kati.Media.TrackedTitle
      |> Ash.read!()
      |> Map.new(&{&1.id, &1})

    Kati.Screens.Library.shelf()
    |> Enum.map(fn row ->
      tracked = Map.get(by_id, row.id)

      %{
        id: row.id,
        title: row.title,
        seed: row.seed,
        meta: row.meta || "",
        selected?: false,
        done?: row.status == :finished,
        source: tracked && tracked.source,
        source_id: tracked && tracked.source_id,
        kind: tracked && tracked.kind
      }
    end)
  rescue
    _ -> []
  catch
    :exit, _ -> []
  end

  def render(assigns) do
    ~MOB"""
    <Box
      fill_width={true}
      fill_height={true}
      background={:background}
      layout_direction={Kati.Locale.direction_prop()}
      accessibility_id={Kati.Screens.Identity.of(__MODULE__)}
    >
      <Scroll>
        <Column
          fill_width={true}
          padding_left={21}
          padding_right={21}
          padding_top={64}
          padding_bottom={40}
        >
          {Kati.Screens.ShelfSelection.refusal(Map.get(assigns, :save_error))}
          {Kati.Screens.ShelfSelection.resting_header_still()}
          {Kati.Screens.ShelfSelection.one_selected_still(MapSet.size(assigns.selected))}
          {Kati.Screens.ShelfSelection.selection_bar(MapSet.size(assigns.selected))}
          {Kati.Screens.ShelfSelection.grid(assigns.titles, assigns.selected)}
          {Kati.Screens.ShelfSelection.undo_band(assigns.undo)}
          {Kati.Screens.ShelfSelection.filter_note()}
        </Column>
      </Scroll>
    </Box>
    """
  end

  # ── The resting header, as a still (see the moduledoc) ──────────────────

  @doc """
  The board's first band: Library at rest, and the note naming its sort.

  Always drawn, because this screen is never in that moment — it is another
  screen's resting state, quoted here because 146's board quotes it.
  """
  def resting_header_still do
    ~MOB"""
    <Column fill_width={true}>
      {UI.eyebrow("Resting header — sort persists and says so")}
      {Kati.Screens.ShelfSelection.library_header()}
      <Spacer size={11} />
      {Kati.Screens.ShelfSelection.sort_note()}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def library_header do
    line = sort_line()

    ~MOB"""
    <Row
      fill_width={true}
      background={Palette.card()}
      corner_radius={22}
      shadow={Kati.Theme.shadow_card_soft()}
      padding={17}
      align="top"
    >
      <Column weight={1.0}>
        <Text
          text="Library"
          text_size={22}
          max_font_scale={1.6}
          font_weight="bold"
          letter_spacing={-0.03}
          text_color={:on_surface}
        />
        <Spacer size={5} />
        <Text
          text={line}
          font_family="mono"
          text_size={10.5}
          text_color={Palette.muted()}
          max_lines={1}
        />
      </Column>
      <Spacer size={12} />
      {Kati.Screens.ShelfSelection.still_disc("search")}
      <Spacer size={8} />
      {Kati.Screens.ShelfSelection.still_disc("tune")}
    </Row>
    """
  end

  @doc """
  `41 OF 418 · RECENTLY ADDED`, with only the 41 written out.

  The shelf's size and the sort's name come from board 145's own facets, so a
  rename there lands here rather than leaving two boards disagreeing about
  what the shelf is sorted by.
  """
  @spec sort_line() :: String.t()
  def sort_line do
    {_key, sort} = hd(ShelfFiltersSample.sort_options())

    String.upcase("#{@drawn_showing} of #{ShelfFiltersSample.total()} · #{sort}")
  end

  # 40pt where `Kati.Screens.Library.disc/2` is 44 — this board's own number —
  # and with no `on_tap` at all, which is the whole difference between a
  # control and a picture of one.
  @doc false
  def still_disc(icon) do
    MishkaActionIcon.action_icon(
      [
        size: 40,
        shape: :circle,
        variant: :filled,
        background: Palette.card(),
        shadow: Kati.Theme.shadow_button()
      ],
      [UI.symbol(icon, size: 21)]
    )
  end

  @doc false
  def sort_note do
    base = [text_size: 12.5, line_height: 1.65, text_color: Palette.ink_soft(), base: true]
    emphasis = [font_weight: "semibold", text_color: :on_surface]

    body =
      UI.rich_text([
        {"Sort ", base},
        {"persists", emphasis},
        {" between visits — resetting it every time is annoying — so the mono line names it. " <>
           "A silent persistent sort is the confusing option; a named one is not.", base}
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
      {UI.symbol("info", size: 17, color: Palette.sub())}
      <Spacer size={11} />
      <Column weight={1.0}>
        {body}
      </Column>
    </Row>
    """
  end

  # ── The header card, live and still ────────────────────────────────────

  @doc """
  The board's `One selected` vignette, frozen — until the live header is it.

  Withdrawn at exactly one selected rather than always drawn: the live card
  below already says `1 selected` then, and the same card twice under the same
  label reads as a repeat rather than as a reference.
  """
  def one_selected_still(1), do: ~MOB"<Spacer size={0} />"

  def one_selected_still(_count) do
    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.eyebrow_muted("One selected")}
      {Kati.Screens.ShelfSelection.header_card(1, false)}
      <Spacer size={14} />
    </Column>
    """
  end

  @doc """
  The live header, under the board's own eyebrow at the count it is showing.

  The board writes that eyebrow twice — `One selected` and `Four selected` —
  which is the same label at two counts, exactly as its two header cards are
  the same card at two counts. So the label is built from the count rather
  than picked from a pair.
  """
  def selection_bar(count) do
    label = selection_label(count)

    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.eyebrow_muted(label)}
      {Kati.Screens.ShelfSelection.header_card(count, true)}
      <Spacer size={14} />
    </Column>
    """
  end

  @doc """
  `Four selected` for the eyebrow, in the board's own words.

  Zero is this screen's own extrapolation and reads `Nothing selected`, not
  `0 selected`: an eyebrow is a sentence about the band under it, and a
  numeral there would be the only one in any eyebrow in the app.
  """
  @spec selection_label(non_neg_integer()) :: String.t()
  def selection_label(0), do: "Nothing selected"
  def selection_label(count), do: count_word(count) <> " selected"

  @doc false
  def header_card(count, live?) do
    ~MOB"""
    <Row
      fill_width={true}
      background={Palette.card()}
      corner_radius={22}
      shadow={Kati.Theme.shadow_card_soft()}
      padding={15}
      align="center"
    >
      {Kati.Screens.ShelfSelection.close_glyph(live?)}
      <Spacer size={12} />
      <Column weight={1.0}>
        {Kati.Screens.ShelfSelection.count_body(count)}
      </Column>
      <Spacer size={12} />
      {Kati.Screens.ShelfSelection.actions(count, live?)}
    </Row>
    """
  end

  @doc false
  def close_glyph(false), do: UI.symbol("close", size: 21)

  def close_glyph(true) do
    close_tap = {self(), :close}

    ~MOB"""
    <Row on_tap={close_tap} align="center">
      {Kati.UI.symbol("close", size: 21)}
    </Row>
    """
  end

  @doc """
  `1 selected` alone, or `N selected` over `Actions apply to all {word}`.

  The subtitle only exists above one — the board's "1 selected" vignette has
  no second line at all, and `count_word/1` is what turns the board's own
  `four` back into a word rather than leaving `4` where the drawing wrote a
  word out.
  """
  def count_body(count) when count > 1 do
    ~MOB"""
    <Column fill_width={true}>
      <Text
        text={"#{count} selected"}
        text_size={15}
        font_weight="bold"
        letter_spacing={-0.02}
        text_color={:on_surface}
        max_lines={1}
      />
      <Spacer size={3} />
      <Text
        text={"Actions apply to all #{Kati.Screens.ShelfSelection.count_word(count)}"}
        text_size={11}
        text_color={Palette.sub()}
        max_lines={1}
      />
    </Column>
    """
  end

  def count_body(count) do
    ~MOB"""
    <Text
      text={"#{count} selected"}
      text_size={15}
      font_weight="bold"
      letter_spacing={-0.02}
      text_color={:on_surface}
      max_lines={1}
    />
    """
  end

  @doc false
  @spec count_word(non_neg_integer()) :: String.t()
  def count_word(n), do: Map.get(@count_words, n, Integer.to_string(n))

  @doc """
  Three pills at one selected, two past it, none at zero.

  The drawing only ever shows the first two states; zero is this screen's own
  extrapolation for the moment a `Remove` empties the selection, and it hides
  the row rather than inventing a fourth pill layout nothing drew.

  `live?` decides whether each pill is wrapped in a tapping `Row` or is the
  bare component — a still's pills answer to nothing, so they carry no tag.
  """
  def actions(0, _live?), do: ~MOB"<Spacer size={0} />"

  def actions(1, live?) do
    ~MOB"""
    <Row align="center">
      {Kati.Screens.ShelfSelection.pill("Add to list", :add_to_list, live?)}
      <Spacer size={7} />
      {Kati.Screens.ShelfSelection.pill("Status", :change_status, live?)}
      <Spacer size={7} />
      {Kati.Screens.ShelfSelection.remove_pill(live?)}
    </Row>
    """
  end

  def actions(_count, live?) do
    ~MOB"""
    <Row align="center">
      {Kati.Screens.ShelfSelection.pill("Add to list", :add_to_list, live?)}
      <Spacer size={7} />
      {Kati.Screens.ShelfSelection.remove_pill(live?)}
    </Row>
    """
  end

  @doc false
  def pill(label, _tag, false), do: SettingsList.action_pill(label)

  def pill(label, tag, true) do
    tap = {self(), tag}

    ~MOB"""
    <Row on_tap={tap} align="center">
      {SettingsList.action_pill(label)}
    </Row>
    """
  end

  # `SettingsList.action_pill/1` has no colour override, so the destructive
  # pill calls the component underneath it directly — same four numbers
  # (30/12/15/11.5), `Palette.red_wash/0` and `Palette.red/0` instead of
  # paper and ink.
  @doc false
  def remove_pill(false), do: remove_pill_body()

  def remove_pill(true) do
    tap = {self(), :remove_selected}

    ~MOB"""
    <Row on_tap={tap} align="center">
      {Kati.Screens.ShelfSelection.remove_pill_body()}
    </Row>
    """
  end

  @doc false
  def remove_pill_body do
    MishkaPill.pill(
      label: "Remove",
      background: Palette.red_wash(),
      color: Palette.red(),
      corner_radius: 15,
      height: 30,
      padding: 0,
      padding_left: 12,
      padding_right: 12,
      text_size: 11.5,
      font_weight: :semibold,
      align: :center
    )
  end

  # ── The grid ────────────────────────────────────────────────────────────

  @doc false
  def grid(titles, selected) do
    rows = titles |> Enum.with_index() |> Enum.chunk_every(3)

    ~MOB"""
    <Column fill_width={true}>
      {Enum.map(rows, fn row -> Kati.Screens.ShelfSelection.grid_row(row, selected) end)}
    </Column>
    """
  end

  @doc false
  def grid_row(row, selected) do
    row = row ++ List.duplicate(nil, 3 - length(row))

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        {row
         |> Enum.map(&Kati.Screens.ShelfSelection.tile(&1, selected))
         |> Enum.intersperse(Kati.Screens.ShelfSelection.grid_gap())}
      </Row>
      <Spacer size={18} />
    </Column>
    """
  end

  @doc false
  def grid_gap, do: ~MOB"<Spacer size={12} />"

  @doc """
  A tile's tap tag — the third poster on the shelf is `:toggle_2`.

  An atom rather than the `{:toggle, id}` tuple this started as. `Mob.Renderer`
  emits an `accessibility_id` only for an atom tag, so a tuple-tagged poster
  fires on the device and is nameless everywhere else: absent from
  `Kati.ScreenSweep`, absent from `Kati.AppReachabilityTest`'s push graph, and
  unnamed to a screen reader. `Kati.Screens.ImportSources.tag/1` hit this first.

  The POSITION, not the id, and that is the whole of one crash. This built
  the tag by interpolating the id, off a guard of `is_atom(id)`, which is true of every id
  `Kati.Library.Sample` has and of none the store hands out — so the first
  render over a real shelf raised `FunctionClauseError` before it drew a tile,
  and the push fell back to Home. Interpolating the UUID instead would have
  worked and would have minted one permanent atom per title anybody ever put
  on a shelf; `Kati.Screens.Season` had this exact choice to make about its
  episode rows and made it the same way.

      iex> Kati.Screens.ShelfSelection.toggle_tag(2)
      :toggle_2
  """
  @spec toggle_tag(non_neg_integer()) :: atom()
  def toggle_tag(index) when is_integer(index) and index >= 0,
    do: String.to_atom("toggle_" <> Integer.to_string(index))

  @doc """
  The title a tap tag names, or `nil` when the tag is not one of the shelf's.

  Read out of the list the tag was drawn from, in the same order — the tags
  are rebuilt on every render, so a Remove that shortens the shelf renumbers
  the tiles in the same pass that redraws them.

      iex> Kati.Screens.ShelfSelection.toggled_id(:toggle_1, [%{id: "a"}, %{id: "b"}])
      "b"

      iex> Kati.Screens.ShelfSelection.toggled_id(:toggle_9, [%{id: "a"}])
      nil

      iex> Kati.Screens.ShelfSelection.toggled_id(:undo, [%{id: "a"}])
      nil
  """
  @spec toggled_id(atom(), [map()]) :: term() | nil
  def toggled_id(tag, titles) when is_atom(tag) do
    with "toggle_" <> digits <- Atom.to_string(tag),
         {index, ""} <- Integer.parse(digits),
         %{id: id} <- Enum.at(titles, index) do
      id
    else
      _not_a_tile -> nil
    end
  end

  @doc false
  def tile(nil, _selected), do: ~MOB"<Box weight={1.0} />"

  def tile({item, index}, selected) do
    tap = {self(), Kati.Screens.ShelfSelection.toggle_tag(index)}
    ring? = MapSet.member?(selected, item.id)

    ~MOB"""
    <Column weight={1.0} on_tap={tap}>
      {Kati.Screens.ShelfSelection.poster(item, ring?)}
      <Spacer size={9} />
      <Text
        text={item.title}
        text_size={12.5}
        font_weight="bold"
        letter_spacing={-0.01}
        text_color={:on_surface}
        max_lines={1}
      />
      <Spacer size={3} />
      <Text
        text={Kati.Screens.ShelfSelection.display_meta(item)}
        font_family="mono"
        text_size={10.5}
        text_color={Palette.muted()}
        max_lines={1}
      />
    </Column>
    """
  end

  @doc false
  def poster(item, true) do
    ~MOB"""
    <Box
      fill_width={true}
      height={158}
      corner_radius={13}
      background={Palette.placeholder()}
      border_width={2}
      border_color={Palette.ink()}
      shadow="0 8 18 -14 #B31A1917"
    >
      {Kati.Screens.ShelfSelection.artwork(item)}
      <Box fill_width={true} fill_height={true} align="top_trailing">
        <Column padding={8}>
          {Kati.Screens.ShelfSelection.badge()}
        </Column>
      </Box>
    </Box>
    """
  end

  def poster(item, false) do
    ~MOB"""
    <Box
      fill_width={true}
      height={158}
      corner_radius={13}
      background={Palette.placeholder()}
      shadow={Kati.Theme.shadow_card_soft()}
    >
      {Kati.Screens.ShelfSelection.artwork(item)}
    </Box>
    """
  end

  @doc false
  def artwork(item) do
    case Kati.Design.Images.poster(item.seed) do
      nil ->
        ~MOB"<Spacer size={0} />"

      src ->
        ~MOB"""
        <Image src={src} fill_width={true} height={158} corner_radius={13} content_mode="fill" />
        """
    end
  end

  @doc false
  def badge do
    MishkaThemeIcon.theme_icon(
      %{
        variant: :filled,
        color: Palette.ink(),
        size: 24,
        radius: 12,
        shadow: "0 2 6 0 #661A1917"
      },
      [UI.symbol("check", size: 15, color: Palette.on_ink())]
    )
  end

  @doc "`done` once `Status` has flipped it; the sample's own season/episode line otherwise."
  def display_meta(%{done?: true}), do: "done"
  def display_meta(%{meta: meta}), do: meta

  # ── The undo pill (screen 27's, see the moduledoc) ─────────────────────

  @doc """
  Screen 27's rule, and the pill it is about — frozen, or live.

  Nothing removed yet means the board's own `Removed 4 titles` with no tap on
  it; a real `Remove` puts the real count and the real `Undo` in the same row.
  The eyebrow is 27's own and stays over both, because the rule it states —
  every destructive action leaves an undo bar behind — is true of the still
  and of the live one alike.
  """
  def undo_band(nil) do
    drawn = @drawn_removed

    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.eyebrow_muted("Undo — every destructive action")}
      {Kati.Screens.ShelfSelection.undo_pill(drawn, false)}
      <Spacer size={14} />
    </Column>
    """
  end

  def undo_band(%{count: count}) do
    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.eyebrow_muted("Undo — every destructive action")}
      {Kati.Screens.ShelfSelection.undo_pill(count, true)}
      <Spacer size={14} />
    </Column>
    """
  end

  @doc false
  def undo_pill(count, live?) do
    message = "Removed #{count} #{title_word(count)}"

    ~MOB"""
    <Row
      fill_width={true}
      background={Palette.ink()}
      corner_radius={20}
      padding_left={16}
      padding_right={16}
      padding_top={13}
      padding_bottom={13}
      align="center"
    >
      {UI.symbol("undo", size: 19, color: Palette.on_ink())}
      <Spacer size={12} />
      <Text
        text={message}
        text_size={13}
        font_weight="semibold"
        text_color={Palette.on_ink()}
        weight={1.0}
        max_lines={1}
      />
      <Spacer size={12} />
      {Kati.Screens.ShelfSelection.undo_word(live?)}
    </Row>
    """
  end

  @doc false
  def undo_word(false) do
    ~MOB"""
    <Text
      text="Undo"
      text_size={12.5}
      font_weight="bold"
      text_color={Palette.accent()}
      max_lines={1}
    />
    """
  end

  def undo_word(true) do
    undo_tap = {self(), :undo}

    ~MOB"""
    <Row on_tap={undo_tap} align="center">
      <Text
        text="Undo"
        text_size={12.5}
        font_weight="bold"
        text_color={Palette.accent()}
        max_lines={1}
      />
    </Row>
    """
  end

  @doc false
  def title_word(1), do: "title"
  def title_word(_n), do: "titles"

  # ── The cream note (see the moduledoc for why this is not 143's) ──────

  @doc false
  def filter_note do
    base = [text_size: 12.5, line_height: 1.65, text_color: Palette.cream_body(), base: true]
    emphasis = [font_weight: "semibold", text_color: :on_surface]

    body =
      UI.rich_text([
        {"Selection survives a filter change. ", emphasis},
        {"Filter four selected titles out of view and the header keeps reading ", base},
        {"4 selected", emphasis},
        {" with a “2 hidden by filters” note — silently dropping a selection loses work the user already did. Gesture rule: long press a ",
         base},
        {"tile", emphasis},
        {" selects; long press an ", base},
        {"episode row", emphasis},
        {" rates. Also on 143.", base}
      ])

    ~MOB"""
    <Row fill_width={true} background={Palette.cream()} corner_radius={20} padding={16} align="top">
      {UI.symbol("call_split", size: 18, color: Palette.gold_icon())}
      <Spacer size={11} />
      <Column weight={1.0}>
        {body}
      </Column>
    </Row>
    """
  end

  # ── Taps ────────────────────────────────────────────────────────────────

  def handle_info({:tap, :close}, socket), do: {:noreply, Kati.Screens.Resume.pop(socket)}

  def handle_info({:tap, :add_to_list}, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Lists, %{back: "Shelf"})}

  def handle_info({:tap, :change_status}, socket) do
    case MapSet.to_list(socket.assigns.selected) do
      [id] ->
        item = Enum.find(socket.assigns.titles, &(&1.id == id))

        case Kati.Screens.ShelfSelection.write_status(item) do
          :ok ->
            socket
            |> Mob.Socket.assign(:titles, toggle_done(socket.assigns.titles, id))
            |> Mob.Socket.assign(:save_error, nil)
            |> then(&{:noreply, &1})

          {:error, reason} ->
            {:noreply, Mob.Socket.assign(socket, :save_error, Kati.Write.message({:error, reason}))}
        end

      _not_exactly_one ->
        {:noreply, socket}
    end
  end

  def handle_info({:tap, :remove_selected}, socket) do
    %{titles: titles, selected: selected} = socket.assigns
    {removed, kept} = Enum.split_with(titles, &MapSet.member?(selected, &1.id))

    case Kati.Screens.ShelfSelection.write_removals(removed) do
      :ok ->
        socket
        |> Mob.Socket.assign(:titles, kept)
        |> Mob.Socket.assign(:selected, MapSet.new())
        |> Mob.Socket.assign(:undo, %{count: length(removed), removed: removed})
        |> Mob.Socket.assign(:save_error, nil)
        |> then(&{:noreply, &1})

      {:error, reason} ->
        {:noreply, Mob.Socket.assign(socket, :save_error, Kati.Write.message({:error, reason}))}
    end
  end

  def handle_info({:tap, :undo}, socket) do
    case socket.assigns.undo do
      nil ->
        {:noreply, socket}

      %{removed: removed} ->
        case Kati.Screens.ShelfSelection.write_restorations(removed) do
          :ok ->
            # Re-read rather than push the old shapes back on. A destroyed row
            # cannot be undeleted, so Undo CREATES — and a created row has a new
            # id. Restoring the shapes this screen was holding would leave every
            # tile tagged with an id the store no longer has: they would still
            # draw, still highlight, and a second Remove would find nothing and
            # quietly succeed. So the shelf is asked again, and the restored
            # rows are found by the pair they were keyed on.
            titles = Kati.Screens.ShelfSelection.shelf()
            restored = Kati.Screens.ShelfSelection.restored_ids(titles, removed)

            socket
            |> Mob.Socket.assign(:titles, titles)
            |> Mob.Socket.assign(:selected, restored)
            |> Mob.Socket.assign(:undo, nil)
            |> Mob.Socket.assign(:save_error, nil)
            |> then(&{:noreply, &1})

          {:error, reason} ->
            {:noreply, Mob.Socket.assign(socket, :save_error, Kati.Write.message({:error, reason}))}
        end
    end
  end

  # Last, and deliberately so. This is the only clause here that matches a
  # *shape* rather than one named atom, so anywhere earlier it would swallow
  # `:add_to_list`, `:change_status`, `:remove_selected` and `:undo` on the way
  # past. The tags are built from `titles`, which is read at mount, so they
  # cannot be a compile-time guard list the way `Kati.Screens.DropSheet`'s six
  # reasons can — the tag is matched against the shelf instead.
  def handle_info({:tap, tag}, socket) when is_atom(tag) do
    case Kati.Screens.ShelfSelection.toggled_id(tag, socket.assigns.titles) do
      nil ->
        {:noreply, socket}

      id ->
        selected = socket.assigns.selected

        updated =
          if MapSet.member?(selected, id),
            do: MapSet.delete(selected, id),
            else: MapSet.put(selected, id)

        {:noreply, Mob.Socket.assign(socket, :selected, updated)}
    end
  end

  def handle_info(_msg, socket), do: {:noreply, socket}

  @doc """
  The line that says the store refused, or nothing.

  Every write on this screen goes through it, because before this one nothing
  on this screen wrote at all and a silent refusal would have been the same
  defect wearing a different hat.
  """
  @spec refusal(String.t() | nil) :: map()
  def refusal(nil), do: ~MOB"<Spacer size={0} />"

  def refusal(message) do
    assigns = %{message: message}

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.notice(@message)}
      <Spacer size={14} />
    </Column>
    """
  end

  @doc """
  Flip one title between finished and watching, in the store.

  `nil` and a drawn row both answer `:ok` and write nothing: the board's nine
  titles have atom ids and no tracked row behind them, so *Status* on the
  drawing moves the caption and nothing else — which is what a picture's
  button should do. Every real row goes through `Kati.Media.TrackedTitle`'s
  own `:update`, so `Kati.Media.Changes.Touch` bumps `last_touched_at` and the
  shelf re-sorts the way it does after every other status change in the app.
  """
  @spec write_status(map() | nil) :: :ok | {:error, term()}
  def write_status(nil), do: :ok
  def write_status(%{id: id}) when not is_binary(id), do: :ok

  def write_status(%{id: id, done?: done?}) do
    status = if done?, do: :watching, else: :finished

    case Ash.get(Kati.Media.TrackedTitle, id) do
      {:ok, row} ->
        row
        |> Ash.Changeset.for_update(:update, %{status: status})
        |> Ash.update()
        |> Kati.Write.note("change status from the shelf")
        |> case do
          {:ok, _row} -> :ok
          error -> error
        end

      _gone ->
        {:error, :nothing_to_save}
    end
  rescue
    error -> {:error, error}
  end

  @doc """
  Take the selected titles off the shelf, for real.

  `Ash.destroy/1` on the tracked row and nothing else — the same removal
  screen 06's `untrack/1` performs, and deliberately not a cascade: the
  cached title, its episodes and every logged watch stay, so an Undo a second
  later puts the row back over history that was never lost.

  `:ok` on a drawn row, for `write_status/1`'s reason.
  """
  @spec write_removals([map()]) :: :ok | {:error, term()}
  def write_removals(removed) do
    removed
    |> Enum.filter(&is_binary(&1.id))
    |> Enum.reduce_while(:ok, fn item, :ok ->
      case Ash.get(Kati.Media.TrackedTitle, item.id) do
        {:ok, row} ->
          case Ash.destroy(row) do
            :ok -> {:cont, :ok}
            {:ok, _row} -> {:cont, :ok}
            error -> {:halt, Kati.Write.note(error, "remove from the shelf")}
          end

        # Already gone is the outcome the tap asked for.
        _gone ->
          {:cont, :ok}
      end
    end)
  rescue
    error -> {:error, error}
  end

  @doc """
  Put the removed titles back.

  A create rather than an undelete, because a destroyed row is gone: the
  `{source, source_id, kind}` triple `tracked_shelf/0` carried off the tracked
  row is exactly what is needed to key a new one to the same cached title, so
  the poster, the episodes and the ticks are all still there to be found.

  The new row is `:watching` unless it was finished, and its `last_touched_at`
  is now — an undo is a thing you just did.
  """
  @spec write_restorations([map()]) :: :ok | {:error, term()}
  def write_restorations(removed) do
    removed
    |> Enum.filter(&(is_binary(&1.id) and &1.source != nil and &1.source_id != nil))
    |> Enum.reduce_while(:ok, fn item, :ok ->
      %{
        source: item.source,
        source_id: item.source_id,
        kind: item.kind,
        status: if(item.done?, do: :finished, else: :watching)
      }
      |> then(&Ash.create(Kati.Media.TrackedTitle, &1))
      |> case do
        {:ok, _row} -> {:cont, :ok}
        error -> {:halt, Kati.Write.note(error, "undo a shelf removal")}
      end
    end)
  rescue
    error -> {:error, error}
  end

  @doc """
  The ids the re-read shelf gives the titles that were just put back.

  By `{source, source_id}` — the pair a tracked row is keyed on everywhere in
  this app — and never by id, which is the one thing a destroy-then-create
  does not preserve. A drawn row has neither, so the drawing's Undo selects
  by id and keeps working exactly as the board draws it.
  """
  @spec restored_ids([map()], [map()]) :: MapSet.t()
  def restored_ids(titles, removed) do
    keys = MapSet.new(removed, &{&1[:source], &1[:source_id]})

    titles
    |> Enum.filter(fn row ->
      MapSet.member?(keys, {row[:source], row[:source_id]}) or
        Enum.any?(removed, &(&1.id == row.id))
    end)
    |> MapSet.new(& &1.id)
  end

  defp toggle_done(titles, id) do
    Enum.map(titles, fn
      %{id: ^id} = item -> Map.update!(item, :done?, &(not &1))
      item -> item
    end)
  end
end
