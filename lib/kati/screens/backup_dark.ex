defmodule Kati.Screens.BackupDark do
  @moduledoc """
  Screen 128's "Back up everything" summary, in the dark colourway.

  Built to `.scratch/design/incoming/131.html`, which sits beside
  `.scratch/design/incoming/128.html` — the same page, the same copy, the same
  frame, only the palette moved. That is `Kati.Screens.YearShareDark`'s
  relationship to `Kati.Screens.YearShare` and `Kati.Screens.BookDetailDark`'s
  to `Kati.Screens.BookDetail`: a dark board is a separate screen because
  `Mob.Theme.set/1` is global and a screen cannot ask for "this card, dark" —
  it can only ask for the whole app to turn dark, render, and hand the switch
  back. See either of those two moduledocs for the fuller argument; it is not
  repeated here.

  ## Why this file owns its content, and the other two do not

  `Kati.Screens.YearShareDark` and `Kati.Screens.BookDetailDark` both read
  their copy and their state machine from an existing **light** screen —
  `YearShare`/`BookDetail` — and repaint. There is no `Kati.Screens.Backup128`
  to read from: `128.html` has no built screen behind it yet, only the
  Settings row that will one day open it
  (`Kati.Settings.Sample.data/0`'s "Back up everything", `sub: "Last backup 14
  Aug · 214 MB"` — the same figures 128 and 131 both draw). So this module is
  not a repaint of a sibling; it is the first screen built against `128.html`,
  drawn straight in the dark palette because dark is the board this task was
  given. `Kati.Screens.Backup` — the export/restore engine screen reached from
  Settings' `Export everything` row — is a different screen with a different
  board-less history (see its own moduledoc); it is not this screen's light
  twin and nothing here delegates to it.

  ## Two components this board exposed as wrong in the dark palette

  Both `.scratch/design/pending/68.html` (screen 68, `BookDetailDark`'s own
  board) and `.scratch/design/pending/102.html` (screen 102, `YearShareDark`'s)
  draw the same two literals this board draws, and neither of the two shipped
  screens noticed, because a component call that renders *some* colour reads
  as correct until someone puts the pixel next to the drawing:

    * **`Kati.UI.SettingsList.icon_tile/1`'s dark background was the page, not
      a tile.** Its background was `Kati.Theme.paper(Palette.mode())`, which in
      dark is `Kati.Theme`'s `@paper_dark` — `#121110`, the same value as the
      page underneath the card the tile sits on. All three boards (68, 102,
      131) draw `#2A2826`, which is `Kati.Theme.Palette.placeholder/0`'s dark
      value exactly. The glyph was off too: `icon_tile/1` hardcoded
      `Palette.ink_soft()` (`#CBC7C1` in dark); all three boards draw
      `#A8A29A`, six units below `Kati.Theme.Palette.bar_ink/0`'s dark value
      (`#A29C94`) on every channel — the closest named step, for the same
      reason screen 77's dark chart took a token two units out over a hex
      literal nobody else could follow.
    * **`Kati.UI.SettingsList.title/3`'s dark subtitle was the wrong ramp
      step.** Its mono line was `Palette.muted()`, whose dark value is
      `#6A6560`. Boards 68, 102 and 131 all draw `#8A837B` for the same line —
      `Palette.sub()`'s value, not `muted()`'s.

  **Both are fixed in the shared component now**, in
  `Kati.UI.SettingsList.icon_tile_ink/1` and
  `Kati.UI.SettingsList.subtitle_ink/0`, each branching on `Palette.mode()`
  and each leaving the light values exactly where they were — those are what
  62 pinned frames check pixel for pixel. `format_icon/1` is gone from this
  module; `icon_tile/1` now renders the node it used to build by hand. Only
  four screens render in dark at all, and of those only this one, 68 and 102
  call either helper, so the change reaches precisely the three renders it
  was written for.

  `title/0` below survives the fix, for a reason that has nothing to do with
  colour: `title/3` draws the subtitle at 11 and this board draws it at 11.5.
  See that function's own doc.

  ## Two glyphs the board keeps at their light shade on purpose

  The check glyph on every "travels" row is `#3E8460` on both 128 and 131 —
  `Kati.Theme.Palette.green_text/0`'s **light** value, not its dark one
  (`#4E9A73`, which is what the summary card's own `cloud_done` glyph draws,
  correctly unshaded, on both boards too). The block glyph on both
  "does not travel" rows is `#8A8479` on both boards — `Palette.sub/0`'s light
  value. Both are pinned with the explicit-mode form the module itself
  documents as legitimate (`Palette.green_text(:light)`, `Palette.sub(:light)`
  — see screen 29's lock preview for the same move) rather than read as
  `#3E8460`/`#8A8479` literals nothing else could follow into a future
  palette change.

  This is not the same situation as `icon_tile/1` above. Those two tokens
  computed a colour the boards never drew, in either mode; these two draw a
  colour the palette already has a name for, just not the one `mode/0` would
  pick on this page. A small check mark and a block glyph reading one shade
  softer than the headline glyph is plausibly the point — they are the least
  important marks on the row — so the drawn value is taken as the design
  rather than corrected toward the unshaded hue the summary card's own
  `cloud_done` uses.

  ## The one control that inverts, and the one that does not

  The selected format's mark — a filled disc with a check — goes from
  `#1A1917` filled with `#FBFAF8` on 128 to `#F5F2EE` filled with `#16150F` on
  131. That is not the mechanical inversion `ink_fill`/`on_ink` would give in
  dark (`#F7EFE4` on `#1A1917` — the cream CTA screen 28 draws for the Home
  hero). It is `Kati.Theme.Palette.fab_fill/0` under `fab_glyph/0`, the exact
  pair `Kati.Screens.BookDetailDark`'s selected chip and `Kati.Screens.YearShareDark`'s
  "Save image" pill both take for the same reason: paper on near-black reads,
  ink-on-cream-in-name-only does not. `Save a backup` takes the same pair, for
  the same reason — it is this board's only other filled control.

  The unselected format ring (`border:1.5px solid rgba(245,242,238,.18)`) is
  `Kati.Theme.Palette.border_strong/0` exactly (18% ink-on-dark). The card
  hairline every container on this page lifts with (`inset 0 0 0 1px
  rgba(245,242,238,.06)`) is `card_hairline/0` exactly, for `YearShareDark`'s
  reason: a shadow this near-black on a ground this near-black has nothing to
  show, so every card here — the summary, the two grouped lists — trades
  `Kati.Theme.shadow_card_soft/0` for the hairline border pair, geometry
  otherwise untouched.

  ## The last-backup figures are sample data, named as such

  `14 Aug`, `214 MB` and `2 WEEKS AGO` are not read from
  `Kati.Screens.Settings.last_backup/0` — that ledger stores a bare
  `DateTime`, with no byte count and no relative-time phrasing, and growing it
  to carry both is a bigger change than a dark-colourway screen should make on
  its own. They are the same literal figures `Kati.Settings.Sample.data/0`
  already gives the "Back up everything" row on screen 24, restated here
  because both boards draw them character for character. `last_backup_meta/0`
  names this plainly rather than pretending the card reads a live ledger it
  does not.

  ## What is real: the format choice and the save

  Everything a person can tap answers with a real change. The three format
  rows set `assigns.format`, and the chosen row draws no `on_tap` at all —
  `Kati.Screens.Backup.mode_tap/2` gives the reason: a control that answers a
  tap by setting the value it already holds is indistinguishable from a dead
  one. `Save a backup` reaches `Kati.Backup.Transport.save/1` — the same
  engine `Kati.Screens.Backup`'s `Save a file` row calls — when `Everything
  (JSON)` is chosen, because that is the one format an exporter actually
  writes; `Per-section CSV` and `Calendar (.ics)` are drawn because both
  boards draw them, but nothing under `lib/kati/backup/` builds either file
  yet, so choosing one and tapping Save answers with a notice saying so rather
  than silently writing the JSON file the tap did not ask for. A completed
  save is only known once `Kati.Native.Files`' asynchronous reply names it —
  `handle_info/2` below is the same `{:saved, item}` branch
  `Kati.Screens.Backup.apply_event/2` uses, calling
  `Kati.Screens.Settings.record_backup/0` for the same reason: that is the
  only signal in the app that a copy of the backup reached somewhere the user
  can get it back from.

  ## Pinning the theme, and what it costs

  `load/1` calls `Mob.Theme.set(Kati.Theme.dark())`, the same single switch
  screens 28, 29, 68 and 102 make, because `Kati.Screens.Pushed`'s `mount/3`
  resolves the user's Auto / Light / Dark preference and this screen is the
  reference for what this page looks like in a light-mode app. The cost is
  the one those four screens already carry: `Mob.Theme.set/1` is global, so
  the app stays dark until the next screen mounts and activates the
  preference again. That closes when dark stops being a separate page and
  becomes a mode `Kati.Shell` carries, at which point this module folds back
  into whatever screen `128.html` becomes.
  """

  use Kati.Screens.Pushed, back: "Settings"

  alias Kati.Backup.Error
  alias Kati.Backup.Transport
  alias Kati.Native.Files
  alias Kati.Screens.Settings
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  # LEFT AS A LITERAL: `rgba(78,154,115,.14)`, a background wash with no named
  # token. Both boards draw this exact ARGB value in both light and dark, so
  # it takes no mode. `Kati.Theme.Palette.green_wash/0` is the nearest named
  # token and is a different alpha — 16%, for a status pill's ground, not this
  # 24pt disc's.

  @travels [
    {"Every section", "Screen, Books, Music, Health"},
    {"Ratings, reviews, notes", "With their dates"},
    {"Sessions and habits", "Every tick, every streak"},
    {"Meals and plans", "With their ingredients"},
    {"Calendar events Kati owns", "Not your connected calendars"},
    {"Settings", "Language, units, sections"}
  ]

  @not_travels [
    {"Cached provider metadata", "Re-fetchable, and capped at six months by TMDB’s terms anyway"},
    {"Connected tokens", "Revocable, and meant to be re-entered on the new device"}
  ]

  @formats [
    {"description", :json, "Everything (JSON)", "The one that restores"},
    {"upload_file", :csv, "Per-section CSV",
     "For a spreadsheet or another app — does not restore"},
    {"calendar_month", :ics, "Calendar (.ics)",
     "Because Kati owns a calendar and .ics is what a calendar is"}
  ]

  @doc """
  The board's two assigns, over a theme pinned dark.

  `Mob.Theme.set/1` before the assigns rather than after — every token below
  resolves through `Kati.Theme.Palette.mode/0`, which reads the theme that is
  actually installed, so the switch has to be in place before the first
  render asks it anything.
  """
  @impl true
  @spec load(Mob.Socket.t()) :: Mob.Socket.t()
  def load(socket) do
    Mob.Theme.set(Kati.Theme.dark())

    socket
    |> Mob.Socket.assign(:format, :json)
    |> Mob.Socket.assign(:notice, nil)
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
        {Kati.Screens.BackupDark.title()}
        {Kati.Screens.BackupDark.notice_block(assigns.notice)}
        {Kati.Screens.BackupDark.summary_card()}
        {Kati.Screens.BackupDark.section_label(Palette.accent(), "What travels with it")}
        {Kati.Screens.BackupDark.travels_card()}
        {Kati.Screens.BackupDark.section_label(Palette.rail_idle(), "Format")}
        {Kati.Screens.BackupDark.format_card(assigns.format)}
        {Kati.Screens.BackupDark.save_button()}
        <Spacer size={16} />
        {Kati.Screens.BackupDark.no_server_note()}
      </Column>
    </Scroll>
    """
  end

  # ── Title ────────────────────────────────────────────────────────────────

  @doc """
  `Kati.UI.SettingsList.title/3`'s markup at board 131's subtitle size.

  This was written because that helper drew the mono line in
  `Kati.Theme.Palette.muted/0`, which is `#6A6560` in dark where the board draws
  `#8A837B`. That half is fixed at the source now —
  `Kati.UI.SettingsList.subtitle_ink/0` branches on mode — and this no longer
  differs from the helper by any colour.

  It stays for a reason the colour fix does not touch: `title/3` draws the
  subtitle at **11**, and `131.html` draws it at **11.5**, as do `102.html`,
  `100.html` and `128.html`. Only `24.html` draws 11, and that is the size
  `title/3` is pinned to across the light baseline frames. Calling the helper
  here would trade a fixed colour for a wrong size, and no test would catch it —
  `Kati.ScreenDesignLiteralTest` reads the words, not the type scale.

  The board also puts 6pt under the title where this puts 5. That one is left
  alone rather than quietly corrected; it is the same measurement question as
  the size and belongs in whatever settles `title/3`'s two subtitle shapes.
  """
  @spec title() :: map()
  def title do
    ~MOB"""
    <Column fill_width={true}>
      <Text
        text="Back up everything"
        text_size={28}
        max_font_scale={1.6}
        font_weight="bold"
        letter_spacing={-0.03}
        text_color={Palette.ink()}
      />
      <Spacer size={5} />
      <Text
        text="ONE FILE, KEPT WHEREVER YOU LIKE"
        font_family="mono"
        text_size={11.5}
        text_color={Palette.sub()}
        max_lines={1}
      />
      <Spacer size={20} />
    </Column>
    """
  end

  # ── The summary card ────────────────────────────────────────────────────

  @doc "The figures a backup would carry — sample data; see the moduledoc."
  @spec last_backup_meta() :: String.t()
  def last_backup_meta, do: "2 WEEKS AGO · 214 MB"

  @doc """
  The `Last backup` card: label, date, meta, and the done glyph — lifted with
  the hairline pair rather than `Kati.Theme.shadow_card/0`, radius and padding
  the board's own (22, 17) rather than any shared card recipe's.
  """
  @spec summary_card() :: map()
  def summary_card do
    assigns = %{meta: Kati.Screens.BackupDark.last_backup_meta()}

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        border_width={1}
        border_color={Palette.card_hairline()}
        padding={17}
      >
        <Row fill_width={true} align="top">
          <Column weight={1.0}>
            <Text
              text={String.upcase("Last backup")}
              font_family="mono"
              text_size={10}
              letter_spacing={0.14}
              text_color={Palette.muted()}
              max_lines={1}
            />
            <Spacer size={9} />
            <Text
              text="14 Aug"
              font_family="mono"
              text_size={22}
              font_weight="medium"
              letter_spacing={-0.02}
              text_color={Palette.ink()}
              max_lines={1}
            />
            <Spacer size={6} />
            <Text
              text={@meta}
              font_family="mono"
              text_size={11}
              text_color={Palette.sub()}
              max_lines={1}
            />
          </Column>
          <Spacer size={12} />
          {UI.symbol("cloud_done", size: 22, color: Palette.green())}
        </Row>
      </Column>
      <Spacer size={24} />
    </Column>
    """
  end

  # ── Section labels ──────────────────────────────────────────────────────

  @doc """
  `Kati.UI.eyebrow/2` and `Kati.UI.SettingsList.eyebrow_muted/1`'s shape —
  dash, 9pt gap, 10.5pt mono caps, 11pt trailing gap — with `Palette.muted/0`
  for the label in place of whichever of those two helpers' own text tokens
  would otherwise apply.

  Both text tokens are wrong here for the same reason `icon_tile/1`'s are:
  neither `Palette.eyebrow/0` (`#746F69` dark) nor a plain reuse of either
  helper reproduces what both boards draw, `#6A6560`, which is
  `Palette.muted/0`'s dark value exactly — on `What travels with it`, on
  `Format`, and on `Does not travel` inside the card below. Three
  independent labels agreeing on one value that is not the token the shared
  helpers would pick is a pattern, not a rounding error, so it is taken as
  this board's actual colour rather than approximated toward `eyebrow/0`.
  """
  @spec section_label(pos_integer(), String.t()) :: map()
  def section_label(dash_color, label) do
    assigns = %{dash: dash_color, label: String.upcase(label)}

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_left={2} padding_right={2}>
        <Box width={13} height={2} corner_radius={1} background={@dash} />
        <Spacer size={9} />
        <Text
          text={@label}
          font_family="mono"
          text_size={10.5}
          letter_spacing={0.16}
          text_color={Palette.muted()}
        />
      </Row>
      <Spacer size={11} />
    </Column>
    """
  end

  # ── What travels with it ────────────────────────────────────────────────

  @doc """
  The 24×8×14 disc a `What travels with it` / `Does not travel` row leads
  with. Green wash and the light-pinned `green_text` for a travelling row;
  `placeholder` and the light-pinned `sub` for one that does not — see the
  moduledoc's "two glyphs the board keeps at their light shade" section.
  """
  @spec travel_icon(String.t(), boolean()) :: map()
  def travel_icon(icon, checked?) do
    {bg, glyph} =
      if checked?,
        do: {Palette.green_wash_soft(), Palette.green_text(:light)},
        else: {Palette.placeholder(), Palette.sub(:light)}

    assigns = %{bg: bg, glyph: UI.symbol(icon, size: 14, color: glyph)}

    ~MOB"""
    <Box width={24} height={24} corner_radius={8} background={@bg} align="center">
      {@glyph}
    </Box>
    """
  end

  @doc false
  @spec travel_row(String.t(), boolean(), String.t(), String.t(), keyword()) :: map()
  def travel_row(icon, checked?, title, sub, opts) do
    rule? = Keyword.fetch!(opts, :rule?)
    lines = Keyword.get(opts, :lines, 1)
    title_color = if checked?, do: Palette.ink(), else: Palette.sub()
    sub_color = if checked?, do: Palette.sub(), else: Palette.muted()

    assigns = %{
      leading: Kati.Screens.BackupDark.travel_icon(icon, checked?),
      title: title,
      title_color: title_color,
      sub: sub,
      sub_color: sub_color,
      lines: lines,
      rule: SettingsList.hairline(rule?)
    }

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top" padding_top={11} padding_bottom={11}>
        {@leading}
        <Spacer size={12} />
        <Column weight={1.0}>
          <Text
            text={@title}
            text_size={13}
            font_weight="semibold"
            text_color={@title_color}
            max_lines={1}
          />
          <Spacer size={3} />
          <Text
            text={@sub}
            text_size={11}
            line_height={1.5}
            text_color={@sub_color}
            max_lines={@lines}
          />
        </Column>
      </Row>
      {@rule}
    </Column>
    """
  end

  @doc """
  Every section this device backs up, then the two things a backup
  deliberately leaves out — one card, one manual divider, lifted with
  `Kati.Screens.BookDetailDark.card/1`'s hairline geometry rather than
  `Kati.UI.SettingsList.card/1`'s unconditional shadow.
  """
  @spec travels_card() :: map()
  def travels_card do
    last_travel = length(@travels) - 1

    travel_rows =
      @travels
      |> Enum.with_index()
      |> Enum.map(fn {{title, sub}, i} ->
        Kati.Screens.BackupDark.travel_row("check", true, title, sub, rule?: i < last_travel)
      end)

    last_blocked = length(@not_travels) - 1

    blocked_rows =
      @not_travels
      |> Enum.with_index()
      |> Enum.map(fn {{title, sub}, i} ->
        Kati.Screens.BackupDark.travel_row("block", false, title, sub,
          rule?: i < last_blocked,
          lines: 2
        )
      end)

    assigns = %{
      travels: travel_rows,
      divider: Kati.Screens.BackupDark.divider(),
      label: Kati.Screens.BackupDark.does_not_travel_label(),
      blocked: blocked_rows
    }

    inner = ~MOB"""
    <Column fill_width={true}>
      {@travels}
      {@divider}
      {@label}
      {@blocked}
    </Column>
    """

    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.BookDetailDark.card([inner])}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  @spec divider() :: map()
  def divider do
    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={13} />
      <Box fill_width={true} height={1} background={Palette.hairline_strong()} />
      <Spacer size={13} />
    </Column>
    """
  end

  @doc false
  @spec does_not_travel_label() :: map()
  def does_not_travel_label do
    ~MOB"""
    <Column fill_width={true}>
      <Text
        text={String.upcase("Does not travel")}
        font_family="mono"
        text_size={10}
        letter_spacing={0.14}
        text_color={Palette.muted()}
        max_lines={1}
      />
      <Spacer size={4} />
    </Column>
    """
  end

  # ── Format ───────────────────────────────────────────────────────────────

  @doc "The filled, checked mark or the empty ring — `fab_fill`/`fab_glyph` or `border_strong`."
  @spec format_mark(boolean()) :: map()
  def format_mark(true) do
    ~MOB"""
    <Box width={24} height={24} corner_radius={12} background={Palette.fab_fill()} align="center">
      {UI.symbol("check", size: 15, color: Palette.fab_glyph())}
    </Box>
    """
  end

  def format_mark(false) do
    ~MOB"""
    <Box
      width={24}
      height={24}
      corner_radius={12}
      border_width={1.5}
      border_color={Palette.border_strong()}
    />
    """
  end

  @doc "The tap tag for a format choice."
  @spec format_tag(atom()) :: atom()
  def format_tag(:json), do: :format_json
  def format_tag(:csv), do: :format_csv
  def format_tag(:ics), do: :format_ics

  @doc """
  The three format rows. `Kati.UI.SettingsList.body/2`'s 13.5/11.5pt pair
  matches this card's own sizes exactly, unlike the 13/11pt pair the travels
  list draws, so this list reuses it rather than repeating `travel_row/5`'s
  hand-rolled text. The chosen row carries no `on_tap` — see the moduledoc.
  """
  @spec format_card(atom()) :: map()
  def format_card(current) do
    last = length(@formats) - 1

    rows =
      @formats
      |> Enum.with_index()
      |> Enum.map(fn {{icon, format, title, sub}, i} ->
        Kati.Screens.BackupDark.format_row(icon, format, title, sub, current, i < last)
      end)

    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.BookDetailDark.card(rows)}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  @spec format_row(String.t(), atom(), String.t(), String.t(), atom(), boolean()) :: map()
  def format_row(icon, format, title, sub, current, rule?) do
    selected? = format == current
    tap = if selected?, do: nil, else: {self(), Kati.Screens.BackupDark.format_tag(format)}

    SettingsList.row(
      SettingsList.icon_tile(icon),
      SettingsList.body(title, sub),
      Kati.Screens.BackupDark.format_mark(selected?),
      padding: 13,
      rule: rule?,
      on_tap: tap
    )
  end

  # ── Save, and the footnote ──────────────────────────────────────────────

  @doc "`Save a backup`: paper on near-black, `fab_fill`/`fab_glyph`, no shadow — see the moduledoc."
  @spec save_button() :: map()
  def save_button do
    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        height={54}
        corner_radius={27}
        background={Palette.fab_fill()}
        align="center"
        on_tap={{self(), :save_backup}}
      >
        <Spacer weight={1.0} />
        <Text
          text="Save a backup"
          text_size={14.5}
          font_weight="bold"
          text_color={Palette.fab_glyph()}
        />
        <Spacer weight={1.0} />
      </Row>
    </Column>
    """
  end

  @doc """
  The closing note, dashed frame drawn solid at `Palette.border/0` for
  `Kati.UI.SettingsList.note/2`'s reason. Not that helper itself: the board's
  icon sits at 17pt and its padding at 15, both one off `note/2`'s own 18/16,
  and the sentence carries one bold run `note/2` cannot typeset — its `label`
  path is one line only. `Kati.UI.rich_text/1` builds the paragraph; the
  `weight` a `Row` reads off a child's own props is set on the finished node
  afterwards, the way `Kati.Screens.Backup.panel/1` sets `shadow` on one.

  131 stops the sentence at the full stop where 128 goes on to argue the
  point — the same one-clause cut `Kati.Screens.YearShareDark.no_server_note/0`
  makes for the same reason: a board whose whole subject is the colourway does
  not need to make the argument twice.
  """
  @spec no_server_note() :: map()
  def no_server_note do
    body_style = [text_size: 12.5, line_height: 1.65, text_color: Palette.bar_ink()]

    paragraph =
      UI.rich_text([
        {"Kati has no server, so a backup is ", body_style},
        {"a file you keep", [font_weight: "semibold", text_color: Palette.ink()]},
        {" — not something stored for you. Put it somewhere that is not only this phone.",
         body_style}
      ])

    assigns = %{paragraph: %{paragraph | props: Map.put(paragraph.props, :weight, 1.0)}}

    ~MOB"""
    <Row
      fill_width={true}
      corner_radius={18}
      border_color={Palette.border()}
      border_width={1.5}
      padding={15}
      align="top"
    >
      {UI.symbol("info", size: 17, color: Palette.sub())}
      <Spacer size={11} />
      {@paragraph}
    </Row>
    """
  end

  # ── Notices from a tap that could not do what it was asked ─────────────

  @doc false
  @spec notice_block(String.t() | nil) :: map()
  def notice_block(nil), do: ~MOB"<Spacer size={0} />"

  def notice_block(text) do
    inner = SettingsList.note("info", text)

    ~MOB"""
    <Column fill_width={true}>
      {inner}
      <Spacer size={16} />
    </Column>
    """
  end

  # ── Taps ─────────────────────────────────────────────────────────────────

  @impl true
  @spec handle_tap(atom(), Mob.Socket.t()) :: {:noreply, Mob.Socket.t()}
  def handle_tap(:format_json, socket),
    do: {:noreply, Kati.Screens.BackupDark.set_format(socket, :json)}

  def handle_tap(:format_csv, socket),
    do: {:noreply, Kati.Screens.BackupDark.set_format(socket, :csv)}

  def handle_tap(:format_ics, socket),
    do: {:noreply, Kati.Screens.BackupDark.set_format(socket, :ics)}

  def handle_tap(:save_backup, socket), do: {:noreply, Kati.Screens.BackupDark.save(socket)}

  def handle_tap(tag, socket), do: Kati.Screens.Root.unhandled_tap(__MODULE__, tag, socket)

  @doc false
  def set_format(socket, format), do: Mob.Socket.assign(socket, :format, format)

  @doc """
  `Everything (JSON)` reaches the real exporter; the other two answer with a
  notice rather than writing a file the tap did not ask for — see the
  moduledoc.
  """
  @spec save(Mob.Socket.t()) :: Mob.Socket.t()
  def save(%{assigns: %{format: :json}} = socket) do
    case Transport.save([]) do
      {:ok, _summary} -> Kati.Screens.BackupDark.put_notice(socket, nil)
      {:error, %Error{} = error} -> Kati.Screens.BackupDark.put_notice(socket, error.message)
    end
  end

  def save(%{assigns: %{format: other}} = socket) do
    Kati.Screens.BackupDark.put_notice(
      socket,
      Kati.Screens.BackupDark.format_unavailable_notice(other)
    )
  end

  @doc false
  def format_unavailable_notice(:csv),
    do: "Per-section CSV has no exporter yet. Nothing was written."

  def format_unavailable_notice(:ics),
    do: "Calendar (.ics) has no exporter yet. Nothing was written."

  @doc false
  def put_notice(socket, notice), do: Mob.Socket.assign(socket, :notice, notice)

  # ── Messages from the device ────────────────────────────────────────────

  @doc """
  The one message this screen listens for: `Kati.Native.Files`' answer to the
  save it started. `{:saved, item}` is the only branch that means anything —
  `Kati.Screens.Backup.apply_event/2`'s doc has the full reasoning for why a
  share or a dismissed sheet must not stamp the ledger, and this screen offers
  no share, so those branches never arise from its own taps.
  """
  @impl true
  def handle_info(message, socket) do
    case Files.decode(message) do
      {:saved, _item} ->
        :ok = Settings.record_backup()
        {:noreply, socket}

      :ignore ->
        super(message, socket)

      _other ->
        {:noreply, socket}
    end
  end
end
