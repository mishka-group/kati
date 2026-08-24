defmodule Kati.Screens.BackupLarge do
  @moduledoc """
  Screen 133 — backup at 235% Dynamic Type, a reference sheet pushed under
  Settings.

  `Kati.Screens.Backup` (board 128) draws the same screen at 100%: a status
  card naming the last backup, a "What travels with it" checklist, a
  three-format choice, a save button, a footnote. 133 re-types a smaller slice
  of that screen at the largest size Android offers, so the claim *nothing
  here clips* can be checked by looking rather than asserted — the same job
  screen 91 does for search, and this file follows its shape line for line.

  ## This is a frozen specimen, not 128 re-run at a bigger scale

  Every literal below is typed, the way `Kati.Screens.SearchLarge`'s `@query`
  and `@counts` are typed: this sheet exists to show one scenario — a backup
  fourteen days old — at one text size, and it has to render that scenario
  every time it is opened, on a fresh install with an empty ledger and all.
  Reading `Kati.Screens.Settings.last_backup/0` the way 128's own
  `status_card/0` does would make that impossible: an empty ledger answers
  `nil`, and 128 already has an opinion about what `nil` draws — the cream
  `Never` card, not `14 Aug`. A specimen that sometimes shows the thing it
  exists to specimen and sometimes shows a different card entirely is not a
  reference sheet, so this file does not call it.

  What 133 does reuse is the copy that has a real, shared home: the two
  formats are read off `Kati.Backup.Sample.formats/0` — the exact source
  `Kati.Screens.Backup.format_card/1` reads — filtered to the two rows the
  board draws, rather than retyped, so a wording change to that source
  reaches both screens without this file drifting from it.

  ## What 133 draws that 128 does not, and the reverse

  133 is not 128 zoomed in. Three things are true of one board and not the
  other, on purpose:

    * **133 skips "What travels with it" entirely** and 128's third format,
      Calendar (.ics). The board's own caption — quoted below — talks about
      the status card, the format rows and the footnote, and never mentions
      the checklist or a third row; it is not the board running out of frame
      the way search 91 ran out of chip width, it is a smaller specimen by
      design. `Kati.Backup.Sample.travels/0`, `.stays/0` and the `:ics` row
      all exist and are real, so nothing here is missing for want of data —
      only for want of the board asking for it.
    * **133's status card ends in a fourth stacked line that 128 does not
      draw at all.** 128 puts the `cloud_done` glyph beside a three-line
      block (label, date, caption) in one `Row`; it never spells out "Up to
      date" as a word. 133 draws that word, behind a hairline, on its own
      row. That is the board pushing "the row becomes a stack" one step
      further than 128 needed to — a fourth fact earns a fourth line instead
      of riding shotgun on the icon.
    * **133's footnote is shorter than 128's.** 128: *"…not something stored
      for you. Put it on a cloud drive, a computer, anywhere that is not only
      this phone. A backup that lives on the phone it is backing up is not a
      backup."* 133: *"…Put it somewhere that is not only this phone."* Two
      sentences become one; this file keeps 133's own, not 128's.

  ## The row becomes a stack, exactly as the board's own caption says

  Board 133 carries a caption Claude Design does not render into the frame —
  read it, it is not decoration:

  > "Every row becomes a stack: the status card's three figures break to
  > their own lines, format rows grow a glyph tile above wrapping copy, and
  > the footnote's glyph moves above its sentence. Nothing truncates — the
  > cards simply get taller, per 41's rule. The **does not restore** clause
  > wraps in full, since that is the one line a user must not miss."

  Three moves follow it: `status_card/0` gives the date, the age and the size
  three independent `Text` nodes rather than one two-line block; `format_row/1`
  puts the glyph tile in its own header strip above the title and the
  wrapping sub-line, with the selection mark beside it; `footnote/0` puts the
  `info` glyph on its own line above the paragraph. No `Text` below carries
  `max_lines` except the atomic ones — a date, a status word, a button label —
  that were never going to wrap regardless of scale. The CSV row's sub-line —
  *"For a spreadsheet or another app — does not restore"* — is the paragraph
  the caption calls out by name, and it is exactly as unbounded as every
  other one here.

  ## What K-29 caps here, and what it deliberately does not

  `max_font_scale` (fence K-29, `MobBridge.kt`) hands a subtree a
  `LocalDensity` whose `fontScale` is clamped, leaving `density` untouched —
  a capped label keeps its own padding and corner radii, only its `sp` stops
  growing. The rule is `Kati.Screens.Calendar.day_strip/1`'s and
  `Kati.Screens.SearchLarge`'s: **content grows, chrome whose size carries
  structure caps instead.**

    * **Uncapped**: the title, the status card's four figures and its "Up to
      date" line, both format rows' title and sub-line, and the footnote's
      paragraph — none sits inside a container whose *height* is fixed, so
      none needs protecting from a real device's own 235%.
    * **Capped at `cap/0`**: the save button (a 64pt stadium holding one
      line) and each format row's header strip (a 40pt tile and a 28pt
      selection mark, both glyphs in fixed-size boxes). Growing either past
      this board's own size does not make it more legible, it makes the
      button stop being one line and the glyphs stop fitting the shapes
      drawn around them.

  `cap/0` is **1.0** — every `sp` here is already the board's largest-setting
  size, typed out, so 1.0 reads as "do not scale this twice," not "do not
  scale this." At an ordinary system scale it costs nothing: K-29 overrides
  `LocalDensity` only where `density.fontScale > cap`.

  The cap sits on the header strip inside `format_row/1`, not on the card
  around it — `max_font_scale` on a node reaches every `Text` in its subtree,
  and capping the whole card would have frozen the title and sub-line it
  exists to let grow. `Kati.Screens.Calendar.day_strip/1` makes the identical
  point about the weekday label and the day cell: "a cap on the Text does not
  reach its sibling."

  ## What is reused, what is hand-rolled, and why

  `Kati.UI.SettingsList.chrome/2` reserves the strip the back pill floats in;
  `Kati.UI.SettingsList.hairline/1` draws the rule inside the status card;
  `Kati.Backup.Sample.formats/0` and `.default_format/0` are the same source
  `Kati.Screens.Backup.format_card/1` reads. `Kati.Components.MishkaThemeIcon`
  builds both the format tile and the filled selection mark — the same
  component `Kati.Screens.Backup.format_mark/1` and
  `Kati.UI.SettingsList.icon_tile/1` already call — parameterised at this
  board's own 40pt/radius-12 tile and 28pt/radius-14 mark rather than either
  of theirs (30/9 and 24/12).

  Three things could not come from a shared call at all:

    * **`title_block/0`.** `Kati.UI.SettingsList.title/3` is fixed at 28pt
      with `max_font_scale: 1.6` and a one-line mono sub. 133 draws 34pt,
      uncapped, over a two-line caption — a different size on a different
      cap with a different line count is not this component with different
      arguments.
    * **The selection mark's outline state.** `Kati.Screens.Backup.format_mark/1`
      already hand-rolls this half itself — a themed filled circle has no
      "outlined and empty" variant to ask for — so this file's `false` clause
      mirrors that `Box` at 133's own 28pt/1.5pt numbers rather than
      inventing a second way to draw a ring.
    * **`footnote/0`.** `Kati.UI.SettingsList.note/2`, and
      `Kati.Screens.Backup.footnote/0` which calls the same
      `Kati.Components.MishkaPill` in the same mode, both put the icon in
      `leading` beside the paragraph in one row. 133 puts the `info` glyph on
      its own line above the paragraph, which no `leading` slot can do, so
      this is a bordered `Column` instead. The border is solid rather than
      dashed for the reason every dashed frame in this app is: `Modifier.border`
      takes no `PathEffect`.

  ## The one thing the board draws that this file cannot

  *"a file you keep"* is one weight step above the sentence around it.
  `Kati.Screens.Backup.footnote/0` already names the trade for the same
  clause at 128's size: `Kati.UI.rich_text/1` concatenates its runs and
  applies the longest run's own style to the lot, because `MobText` reads
  `text` as a plain `String` with one `fontWeight` and there is no
  `AnnotatedString` anywhere in the bridge. This file passes the same three
  runs through the same function at 133's own 17pt — the words survive, the
  emphasis does not, and that is the trade `rich_text/1`'s own moduledoc
  argues for over an orphaned bold word.

  ## What K-29 does not reach: the back pill

  The drawing grows the back pill to 56pt with a 19pt label;
  `Kati.Screens.Pushed.back_pill/1` is 44 with a 13.5 and no cap, and at a
  real 235% that label wants more room than a fixed 44pt pill gives it. That
  is the one clipping this board documents and this file must not fix: the
  pill is shared by roughly sixty screens, and the fix is one number in
  `Kati.Screens.Pushed`, once. `SettingsList.chrome(nil, 44)` reserves what
  the pill actually occupies rather than what the drawing wishes it did. The
  pill says **Settings**, matching both boards — this sheet is a picture of
  the screen a user reaches from Settings, at a system text size.

  ## Nothing here taps

  The format rows read as a choice — one filled mark, one outline — because
  that is what the board draws and what `Sample.default_format/0` answers,
  not because either is wired: this is a still frame of a screen whose real
  taps live on `Kati.Screens.Backup`. `Kati.Screens.Pushed` defines no
  `handle_tap/2` on purpose, so drawing the mark without an `on_tap` reports
  no dead tag.
  """

  use Kati.Screens.Pushed, back: "Settings"

  alias Kati.Backup.Sample
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  # The scenario this specimen freezes. Typed rather than read off
  # `Kati.Screens.Settings.last_backup/0` — see the moduledoc on why a
  # reference sheet cannot answer "it depends on the ledger".
  @title "Back up everything"
  @caption_lines ["ONE FILE, KEPT", "WHEREVER YOU LIKE"]

  @last_backup %{
    label: "Last backup",
    date: "14 Aug",
    age: "2 WEEKS AGO",
    size: "214 MB",
    status: "Up to date"
  }

  @save_label "Save a backup"

  @doc """
  The sheet, top to bottom: title, status, format, save, footnote.

  The two format rows are `Kati.Backup.Sample.formats/0`'s first two —
  `:json` and `:csv` — not the module's own list: see the moduledoc on why
  133 leaves `:ics` and the travels checklist out on purpose.
  """
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
        {Kati.Screens.BackupLarge.title_block()}
        {Kati.Screens.BackupLarge.status_card()}
        {UI.eyebrow("Format", gap: 14)}
        {Kati.Screens.BackupLarge.formats()}
        {Kati.Screens.BackupLarge.save_button()}
        {Kati.Screens.BackupLarge.footnote()}
      </Column>
    </Scroll>
    """
  end

  @doc """
  The ceiling on how far this screen's structural chrome may grow, as a
  `fontScale`.

  1.0, because every `sp` here is already the drawing's 235% size, typed out
  — see the moduledoc. It reads as "do not scale this twice" rather than "do
  not scale this", and it is inert on a device at ordinary size: fence K-29
  overrides `LocalDensity` only where `density.fontScale > cap`.
  """
  @spec cap() :: float()
  def cap, do: 1.0

  @doc "The 34pt title over its two-line mono caption. Uncapped — see the moduledoc."
  @spec title_block() :: map()
  def title_block do
    title = @title
    [first, second] = @caption_lines

    ~MOB"""
    <Column fill_width={true}>
      <Text
        text={title}
        text_size={34}
        font_weight="bold"
        letter_spacing={-0.03}
        line_height={1.2}
        text_color={:on_surface}
      />
      <Spacer size={9} />
      <Column fill_width={true}>
        <Text
          text={first}
          font_family="mono"
          text_size={14}
          text_color={Palette.muted()}
          max_lines={1}
        />
        <Text
          text={second}
          font_family="mono"
          text_size={14}
          text_color={Palette.muted()}
          max_lines={1}
        />
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  The status card: label, three broken-apart figures, then "Up to date"
  behind a rule — the fourth stacked line 128 never draws. See the
  moduledoc.
  """
  @spec status_card() :: map()
  def status_card do
    s = @last_backup
    label = String.upcase(s.label)

    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={22}
      shadow={Kati.Theme.shadow_card_soft()}
      padding={18}
    >
      <Text
        text={label}
        font_family="mono"
        text_size={13}
        letter_spacing={0.12}
        text_color={Palette.eyebrow()}
        max_lines={1}
      />
      <Spacer size={12} />
      <Text
        text={s.date}
        font_family="mono"
        text_size={30}
        font_weight="medium"
        letter_spacing={-0.02}
        text_color={:on_surface}
        max_lines={1}
      />
      <Spacer size={9} />
      <Text
        text={s.age}
        font_family="mono"
        text_size={15}
        text_color={Palette.muted()}
        max_lines={1}
      />
      <Spacer size={4} />
      <Text
        text={s.size}
        font_family="mono"
        text_size={15}
        text_color={Palette.muted()}
        max_lines={1}
      />
      <Spacer size={14} />
      {SettingsList.hairline(true)}
      <Spacer size={14} />
      <Row fill_width={true} align="center">
        {UI.symbol("cloud_done", size: 22, color: Palette.green())}
        <Spacer size={9} />
        <Text
          text={s.status}
          text_size={17}
          font_weight="semibold"
          text_color={Palette.green_text()}
          max_lines={1}
        />
      </Row>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  The two format rows this board draws — `Kati.Backup.Sample.formats/0`'s
  `:json` and `:csv`, at the board's own 11pt gap.
  """
  @spec formats() :: map()
  def formats do
    chosen = Sample.default_format()

    rows =
      Sample.formats()
      |> Enum.filter(&(&1.tag in [:json, :csv]))
      |> Enum.map(&Kati.Screens.BackupLarge.format_row(&1, &1.tag == chosen))
      |> Enum.intersperse(~MOB"<Spacer size={11} />")

    ~MOB"""
    <Column fill_width={true}>
      {rows}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  One format as a card: a header strip (tile, then the selection mark), the
  title, then the wrapping sub-line.

  The header strip alone carries `cap/0` — the tile and the mark are fixed
  40pt and 28pt shapes, and the title and sub-line below them are not, so
  capping the whole card would have frozen the very text this board exists
  to let grow. See "What K-29 caps here" in the moduledoc.
  """
  @spec format_row(map(), boolean()) :: map()
  def format_row(format, selected?) do
    tile = Kati.Screens.BackupLarge.format_tile(format.icon)
    mark = Kati.Screens.BackupLarge.format_mark(selected?)
    title = format.title
    sub = format.sub

    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={20}
      shadow={Kati.Theme.shadow_card_soft()}
      padding={16}
    >
      <Row fill_width={true} align="center" max_font_scale={Kati.Screens.BackupLarge.cap()}>
        {tile}
        <Spacer weight={1.0} />
        {mark}
      </Row>
      <Spacer size={14} />
      <Text
        text={title}
        text_size={20}
        font_weight="semibold"
        line_height={1.35}
        text_color={:on_surface}
      />
      <Spacer size={8} />
      <Text text={sub} text_size={16} line_height={1.5} text_color={Palette.sub()} />
    </Column>
    """
  end

  @doc """
  The 40pt glyph tile a format row leads with.

  `Kati.Components.MishkaThemeIcon` at this board's own 40pt/radius-12,
  rather than `Kati.UI.SettingsList.icon_tile/1`'s fixed 30/9 — the same
  component, this board's numbers.
  """
  @spec format_tile(String.t()) :: map()
  def format_tile(icon) do
    Kati.Components.MishkaThemeIcon.theme_icon(
      %{variant: :filled, color: Palette.paper(), size: 40, radius: 12},
      [UI.symbol(icon, size: 21, color: Palette.ink_soft())]
    )
  end

  @doc """
  The 28pt selection mark: filled ink with a check for the chosen format,
  outlined and empty for the other — `Kati.Screens.Backup.format_mark/1`'s
  own two clauses, at this board's own 28pt/radius-14 rather than its 24/12.
  """
  @spec format_mark(boolean()) :: map()
  def format_mark(true) do
    Kati.Components.MishkaThemeIcon.theme_icon(
      %{variant: :filled, color: Palette.ink_fill(), size: 28, radius: 14},
      [UI.symbol("check", size: 17, color: Palette.on_ink())]
    )
  end

  def format_mark(false) do
    ~MOB"""
    <Box
      width={28}
      height={28}
      corner_radius={14}
      border_color={Palette.border()}
      border_width={1.5}
    />
    """
  end

  @doc """
  The save button, at the board's own 64pt stadium and 19pt label.

  Capped — a single-line label in a fixed-height stadium is exactly the
  chrome `cap/0` exists for.

  The shadow is written out rather than taken from `Kati.Theme.shadow_button/0`
  — this board's is a single layer at `0 14 28 -12`, matching the literal
  `Kati.Screens.Backup.save_button/0` already writes for its own 100% button
  rather than a shared token that describes a different blur and spread.
  """
  @spec save_button() :: map()
  def save_button do
    label = @save_label

    ~MOB"""
    <Column fill_width={true} max_font_scale={Kati.Screens.BackupLarge.cap()}>
      <Box
        fill_width={true}
        height={64}
        corner_radius={32}
        background={Palette.ink_fill()}
        shadow="0 14 28 -12 #801A1917"
        align="center"
      >
        <Text
          text={label}
          text_size={19}
          font_weight="bold"
          text_color={Palette.on_ink()}
          max_lines={1}
        />
      </Box>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc """
  The footnote: the `info` glyph on its own line, then the paragraph, its
  one bold run passed through `Kati.UI.rich_text/1` the way
  `Kati.Screens.Backup.footnote/0` already does for the same clause. See the
  moduledoc on why the emphasis still does not survive.

  Uncapped and carrying no `max_lines` — this is body copy, and the
  caption's *"does not restore"* rule for the CSV row is really a rule for
  every paragraph here.
  """
  @spec footnote() :: map()
  def footnote do
    body = [text_size: 17, line_height: 1.55, text_color: Palette.ink_soft(), font_family: "sans"]

    strong = [
      font_weight: "semibold",
      text_color: Palette.ink(),
      text_size: 17,
      line_height: 1.55,
      font_family: "sans"
    ]

    paragraph =
      UI.rich_text([
        {"Kati has no server, so a backup is ", body},
        {"a file you keep", strong},
        {". Put it somewhere that is not only this phone.", body}
      ])

    ~MOB"""
    <Column
      fill_width={true}
      corner_radius={20}
      border_width={1.5}
      border_color={Palette.border()}
      padding={17}
    >
      {UI.symbol("info", size: 22, color: Palette.sub())}
      <Spacer size={12} />
      {paragraph}
    </Column>
    """
  end
end
