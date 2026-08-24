defmodule Kati.Screens.BackupStates do
  @moduledoc """
  Screen 130 — Backup & restore, eight states, in screen 27's manner.

  Eight pictures of a screen you go and look at rather than something the app
  puts in front of you: never having backed up, having backed up recently,
  the backup going stale, the export path this build cannot offer, a restore
  in progress, a restore refused because the file is newer than this Kati,
  a restore refused because the file is broken, and a restore that finished.
  It is pushed under Settings and carries a back pill for exactly the reason
  27, 67, 75, 95 and `Kati.Screens.MoneyStates` do — and here the pill's own
  word, `Settings`, is also the real route: every reference sheet in the app
  opens from Settings, and this is the one board where the drawing and the
  destination happen to agree.

  ## Never is cream and gold, not red — the day-one condition, not a fault

  Every other state describes something that has already settled: a date
  sitting in the ledger, a backup ageing past a threshold, a build missing a
  capability, a file mid-transfer, a file refused, a file broken, a restore
  done. *Never* is different — it is not a condition a device settles into,
  it is where every install starts, the same moment
  `Kati.Screens.MoneyStates.nothing_set_up/0` argues for its own first card.
  So it takes the cream card and the gold glyph the design gives a thing worth
  noticing that is not wrong, and its eyebrow keeps the accent dash — orange
  meaning new/now, per `Kati.UI.eyebrow/2` — while the other seven take
  `Kati.UI.SettingsList.eyebrow_muted/1`'s grey one, because a stale backup, a
  refused restore and a finished one are not new; they are what the app has
  already decided.

  ## The eight-week threshold is the board's own word, and it stays that way

  `Kati.Screens.Settings.last_backup/0` answers one `DateTime` or `nil`, and
  `backup_line/1` turns that into exactly two sentences: *Never backed up* or
  *Last backup 14 Aug*. Neither of them, nor anything in `Kati.Backup`, has an
  opinion about how old is too old — there is no `stale?/1`, no cutoff
  constant, nothing a third state could be computed from. So *eight weeks* is
  typed here as the board types it, reasoning included: long enough that a
  monthly habit never trips it, short enough that a lost phone costs less than
  a season. The day a real threshold lands in `Kati.Backup`, this card is the
  one that should start reading it instead of stating it.

  ## Nothing here reads a store

  27's argument, unchanged, and sharper on this board than on most: `last_backup/0`
  is a *single* setting with two answers, never or a date. Reading it here would
  draw one true state — this device's actual one — and seven invented states
  beside it as if they were all equally live. A reference sheet that read the
  one value the app actually tracks would be the least honest card on it, not
  the most.

  ## The restore percentage is a state the engine cannot yet report

  `Kati.Backup.restore_file/2` runs to completion and returns `{:ok, report}`
  or `{:error, error}` — there is no callback, no message, no partial state a
  screen could poll mid-restore. *Restoring — 214 of 384* is drawn anyway,
  because a long restore is a real thing a user will sit through one day, and
  27 already established that a state nobody has wired yet still belongs on
  this kind of sheet — its own Undo card names the same gap. The day
  `Kati.Backup.Restore` grows a progress callback, this is the card that
  becomes true instead of drawn.

  The bar itself is `Kati.Screens.HomeDark`'s own technique: a fixed-height
  track `Box` holding a `Row` of a weighted fill `Box` and a weighted `Spacer`
  that takes the rest, `0.56` and `0.44` rather than a measured width, because
  nothing here reports geometry back to `render/1`.

  ## Bold spans, and which of them survive `rich_text/1`

  `Kati.UI.rich_text/1` concatenates its runs and paints the whole result in
  ONE style, because `MobText` takes a plain `String` and the bridge has no
  `AnnotatedString`. Three of this board's four bold spans still go in as
  runs — the stale card's *34 titles, 19 sessions, 2 plans*, the export card's
  *can*, the newer-version card's *1.4* and *1.2* — because each sits inside a
  `Column` this file builds itself, so recording the run boundary costs
  nothing and is already right for the day `MobText` grows one.

  The fourth — *8 weeks* in the threshold note — does not, because that note
  is `Kati.UI.SettingsList.note/2`, which takes a plain `text` and forces one
  style on it regardless of what arrives. `Kati.Screens.DataSourcesStates`
  already made this call for its own footnote: runs there would buy nothing
  and would only hide, behind a `rich_text` call that looks load-bearing, the
  fact that nothing is bearing on anything. The sentence goes in flat.

  ## The threshold note is `SettingsList.note/2`, borrowed whole

  Every number matches: `rgba(26,25,23,.16)` at 1.5pt is exactly
  `Palette.border/0` at the width the component already draws, and the
  leading glyph is already `Palette.sub/0`. Dashed reads as solid, for the
  reason that component's own moduledoc gives — `Modifier.border` takes no
  `PathEffect` — which is the one place this sheet's geometry and the board's
  disagree, and it disagreed before this file existed.

  ## `80` is not a link

  The board makes the footer's cross-reference an anchor. Per-run styling is
  what the bridge is missing and a per-run tap is a further thing again, so
  the reference sets as the number it is — `Kati.Screens.MyServices.credit/0`
  already writes *credited on 83* the same way, and
  `Kati.Screens.MoneyStates` makes the identical call about its own `07`.

  ## Nothing on this sheet taps

  `Share a section as text` and `Retry` are drawn and inert, exactly as 27's
  own `add` button and Undo action are. `Kati.Screens.Pushed` defines no
  `handle_tap/2` here on purpose, so a tap nobody wired is reported by the
  sweep rather than swallowed by a catch-all — wiring `Retry` would mean
  reaching into `Kati.Backup.inspect_file/2` from a card whose whole subject
  is a file that does not exist.
  """

  use Kati.Screens.Pushed, back: "Settings"

  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

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
        {SettingsList.title("Backup & restore", "EIGHT STATES")}
        {UI.eyebrow("Never backed up — a warning, not an error")}
        {Kati.Screens.BackupStates.never()}
        {SettingsList.eyebrow_muted("Backed up recently")}
        {Kati.Screens.BackupStates.recent()}
        {SettingsList.eyebrow_muted("Stale — more than 8 weeks")}
        {Kati.Screens.BackupStates.stale()}
        {SettingsList.eyebrow_muted("Export not available yet")}
        {Kati.Screens.BackupStates.export_unavailable()}
        {SettingsList.eyebrow_muted("Restoring")}
        {Kati.Screens.BackupStates.restoring()}
        {SettingsList.eyebrow_muted("Backup from a newer Kati — refused wholly")}
        {Kati.Screens.BackupStates.newer_version()}
        {SettingsList.eyebrow_muted("Corrupt or partial file")}
        {Kati.Screens.BackupStates.corrupt()}
        {SettingsList.eyebrow_muted("Restore finished")}
        {Kati.Screens.BackupStates.finished()}
      </Column>
    </Scroll>
    """
  end

  # ── The shared shells ───────────────────────────────────────────────────────

  @doc """
  The card colour every state but the two cream ones sits on: `Palette.card/0`
  at radius 22, 17 of padding, the soft card shadow. Six of the eight states
  use this shell unchanged.
  """
  @spec panel(map()) :: map()
  def panel(body) do
    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={22}
      padding={17}
      shadow={Kati.Theme.shadow_card_soft()}
    >
      {body}
    </Column>
    """
  end

  @doc """
  The cream advisory card `Never` and the headline half of `Stale` share: a
  gold glyph beside a bold title, a paragraph under it. `body` arrives as a
  built node rather than a string because one caller's paragraph is plain and
  the other's carries the bold spans `rich_text/1` can still record.
  """
  @spec advisory(String.t(), String.t(), map()) :: map()
  def advisory(icon, title, body) do
    ~MOB"""
    <Column fill_width={true} background={Palette.cream()} corner_radius={20} padding={16}>
      <Row fill_width={true} align="top">
        {UI.symbol(icon, size: 18, color: Palette.gold_icon())}
        <Spacer size={11} />
        <Column weight={1.0}>
          <Text
            text={title}
            text_size={14.5}
            font_weight="bold"
            text_color={Palette.ink()}
            max_lines={2}
          />
          <Spacer size={6} />
          {body}
        </Column>
      </Row>
    </Column>
    """
  end

  # ── 1. Never backed up ───────────────────────────────────────────────────────

  @doc "Every install's first day: nothing has gone wrong, nothing has happened yet."
  @spec never() :: map()
  def never do
    body = ~MOB"""
    <Text
      text="You have not backed up yet. That is not a fault, only a thing not yet done."
      text_size={12.5}
      line_height={1.65}
      text_color={Palette.cream_sub()}
    />
    """

    card = Kati.Screens.BackupStates.advisory("cloud_off", "Never", body)

    ~MOB"""
    <Column fill_width={true}>
      {card}
      <Spacer size={22} />
    </Column>
    """
  end

  # ── 2. Backed up recently ────────────────────────────────────────────────────

  @doc "What `Kati.Screens.Settings.last_backup/0` looks like drawn as a card rather than a row line."
  @spec recent() :: map()
  def recent do
    left = ~MOB"""
    <Column weight={1.0}>
      <Text
        text="LAST BACKUP"
        font_family="mono"
        text_size={10}
        letter_spacing={0.14}
        text_color={Palette.eyebrow()}
      />
      <Spacer size={9} />
      <Text
        text="14 Aug"
        font_family="mono"
        text_size={20}
        font_weight="medium"
        letter_spacing={-0.02}
        text_color={Palette.ink()}
        max_lines={1}
      />
      <Spacer size={6} />
      <Text
        text="2 WEEKS AGO · 214 MB"
        font_family="mono"
        text_size={11}
        text_color={Palette.muted()}
        max_lines={1}
      />
    </Column>
    """

    inner = ~MOB"""
    <Row fill_width={true} align="top">
      {left}
      <Spacer size={12} />
      {UI.symbol("cloud_done", size: 22, color: Palette.green())}
    </Row>
    """

    card = Kati.Screens.BackupStates.panel(inner)

    ~MOB"""
    <Column fill_width={true}>
      {card}
      <Spacer size={22} />
    </Column>
    """
  end

  # ── 3. Stale ──────────────────────────────────────────────────────────────────

  @doc """
  Two cards, eleven points apart, for the reason `Kati.Screens.MoneyStates`
  gives its own row-and-note pairs: the second is about the character above
  it, not a section break, so the gap stays smaller than the 22 that separates
  states.
  """
  @spec stale() :: map()
  def stale do
    body_style = [text_size: 12.5, line_height: 1.65, text_color: Palette.cream_sub()]
    strong = [text_size: 12.5, font_weight: "semibold", text_color: Palette.ink()]

    message =
      UI.rich_text([
        {"Since then: ", body_style},
        {"34 titles", strong},
        {", ", body_style},
        {"19 sessions", strong},
        {" and ", body_style},
        {"2 plans", strong},
        {" that no backup has.", body_style}
      ])

    headline = Kati.Screens.BackupStates.advisory("schedule", "11 weeks ago", message)

    note =
      SettingsList.note(
        "info",
        "The threshold is 8 weeks — long enough that a monthly habit never trips it, " <>
          "short enough that a lost phone costs less than a season."
      )

    ~MOB"""
    <Column fill_width={true}>
      {headline}
      <Spacer size={11} />
      {note}
      <Spacer size={22} />
    </Column>
    """
  end

  # ── 4. Export not available yet ──────────────────────────────────────────────

  @doc "The capability this build does not have, and the one it does."
  @spec export_unavailable() :: map()
  def export_unavailable do
    body_style = [text_size: 12.5, line_height: 1.65, text_color: Palette.ink_soft()]
    strong = [text_size: 12.5, font_weight: "semibold", text_color: Palette.ink()]

    message =
      UI.rich_text([
        {"Saving files needs a platform capability this version does not have. What it ",
         body_style},
        {"can", strong},
        {" do is hand a section to any app that takes text.", body_style}
      ])

    header = ~MOB"""
    <Row fill_width={true} align="top">
      {UI.symbol("error", size: 19, color: Palette.red())}
      <Spacer size={11} />
      <Column weight={1.0}>
        <Text
          text="Kati can’t write a file yet"
          text_size={13.5}
          font_weight="bold"
          text_color={Palette.ink()}
          max_lines={2}
        />
        <Spacer size={6} />
        {message}
      </Column>
    </Row>
    """

    button = ~MOB"""
    <Row
      fill_width={true}
      height={44}
      corner_radius={22}
      background={Palette.ink_fill()}
      align="center"
    >
      <Spacer weight={1.0} />
      {UI.symbol("ios_share", size: 17, color: Palette.on_ink())}
      <Spacer size={7} />
      <Text
        text="Share a section as text"
        text_size={12.5}
        font_weight="bold"
        text_color={Palette.on_ink()}
        max_lines={1}
      />
      <Spacer weight={1.0} />
    </Row>
    """

    inner = ~MOB"""
    <Column fill_width={true}>
      {header}
      <Spacer size={14} />
      {button}
    </Column>
    """

    card = Kati.Screens.BackupStates.panel(inner)

    ~MOB"""
    <Column fill_width={true}>
      {card}
      <Spacer size={22} />
    </Column>
    """
  end

  # ── 5. Restoring ──────────────────────────────────────────────────────────────

  @doc "A state `Kati.Backup.restore_file/2` cannot yet report — see the moduledoc."
  @spec restoring() :: map()
  def restoring do
    header = ~MOB"""
    <Row fill_width={true} align="center">
      <Column weight={1.0}>
        <Text
          text="Restoring — 214 of 384"
          text_size={13.5}
          font_weight="bold"
          text_color={Palette.ink()}
          max_lines={1}
        />
        <Spacer size={4} />
        <Text
          text="BOOKS · ABOUT A MINUTE LEFT"
          font_family="mono"
          text_size={11}
          text_color={Palette.muted()}
          max_lines={1}
        />
      </Column>
      <Spacer size={12} />
      <Text text="56%" font_family="mono" text_size={15} text_color={Palette.ink()} max_lines={1} />
    </Row>
    """

    track = ~MOB"""
    <Box fill_width={true} height={4} corner_radius={2} background={Palette.paper()}>
      <Row fill_width={true}>
        <Box weight={0.56} height={4} corner_radius={2} background={Palette.accent()} />
        <Spacer weight={0.44} />
      </Row>
    </Box>
    """

    note = ~MOB"""
    <Text
      text="Leaving this screen is safe — the restore keeps running. Closing the app stops it, and it resumes from here."
      text_size={12}
      line_height={1.6}
      text_color={Palette.sub()}
    />
    """

    inner = ~MOB"""
    <Column fill_width={true}>
      {header}
      <Spacer size={13} />
      {track}
      <Spacer size={13} />
      {note}
    </Column>
    """

    card = Kati.Screens.BackupStates.panel(inner)

    ~MOB"""
    <Column fill_width={true}>
      {card}
      <Spacer size={22} />
    </Column>
    """
  end

  # ── 6. A newer Kati wrote this file ──────────────────────────────────────────

  @doc "The one refusal the board insists say both numbers, and say plainly that nothing moved."
  @spec newer_version() :: map()
  def newer_version do
    body_style = [text_size: 12.5, line_height: 1.65, text_color: Palette.ink_soft()]
    strong = [text_size: 12.5, font_weight: "semibold", text_color: Palette.ink()]

    message =
      UI.rich_text([
        {"Written by version ", body_style},
        {"1.4", strong},
        {"; this device runs ", body_style},
        {"1.2", strong},
        {". Nothing has been imported — a half-import is worse than none. Update Kati, " <>
           "then try again.", body_style}
      ])

    header = ~MOB"""
    <Row fill_width={true} align="top">
      {UI.symbol("block", size: 19, color: Palette.red())}
      <Spacer size={11} />
      <Column weight={1.0}>
        <Text
          text="This file is from a newer Kati"
          text_size={13.5}
          font_weight="bold"
          text_color={Palette.ink()}
          max_lines={2}
        />
        <Spacer size={6} />
        {message}
      </Column>
    </Row>
    """

    card = Kati.Screens.BackupStates.panel(header)

    ~MOB"""
    <Column fill_width={true}>
      {card}
      <Spacer size={22} />
    </Column>
    """
  end

  # ── 7. Corrupt or partial file ───────────────────────────────────────────────

  @doc "A file that stopped part-way through writing, named as what it is rather than as an error code."
  @spec corrupt() :: map()
  def corrupt do
    row = ~MOB"""
    <Row fill_width={true} align="center">
      {UI.symbol("error", size: 20, color: Palette.red())}
      <Spacer size={12} />
      <Column weight={1.0}>
        <Text
          text="Couldn’t read this file"
          text_size={13}
          font_weight="bold"
          text_color={Palette.ink()}
          max_lines={1}
        />
        <Spacer size={3} />
        <Text
          text="It ends part-way through — 12 MB of an expected 214"
          text_size={11.5}
          text_color={Palette.sub()}
          max_lines={1}
        />
      </Column>
      <Spacer size={12} />
      {SettingsList.action_pill("Retry")}
    </Row>
    """

    card = Kati.Screens.BackupStates.panel(row)

    ~MOB"""
    <Column fill_width={true}>
      {card}
      <Spacer size={22} />
    </Column>
    """
  end

  # ── 8. Restore finished ──────────────────────────────────────────────────────

  @doc """
  The last band, and the only one with no trailing spacer — the scroll's own
  40pt bottom padding closes it, the way every other reference sheet's last
  card in this app is left to.
  """
  @spec finished() :: map()
  def finished do
    header = ~MOB"""
    <Row fill_width={true} align="center">
      {UI.symbol("check_circle", size: 22, color: Palette.green(), fill: true)}
      <Spacer size={12} />
      <Column weight={1.0}>
        <Text
          text="Everything came back"
          text_size={14.5}
          font_weight="bold"
          letter_spacing={-0.015}
          text_color={Palette.ink()}
          max_lines={1}
        />
        <Spacer size={4} />
        <Text
          text="From 14 Aug · took 2 minutes"
          text_size={11.5}
          text_color={Palette.sub()}
          max_lines={1}
        />
      </Column>
    </Row>
    """

    counts = [
      {"418", "titles"},
      {"1,204", "history entries"},
      {"64", "books"},
      {"35", "meals"},
      {"4", "habits"}
    ]

    last = length(counts) - 1

    rows =
      counts
      |> Enum.with_index()
      |> Enum.map(fn {{number, label}, i} ->
        Kati.Screens.BackupStates.restored_row(number, label, i < last)
      end)

    footer = ~MOB"""
    <Column fill_width={true}>
      <Spacer size={13} />
      {SettingsList.hairline(true)}
      <Spacer size={12} />
      <Text
        text="Artwork will fill in as Kati re-fetches it. Your tokens need re-entering on 80."
        text_size={12}
        line_height={1.6}
        text_color={Palette.sub()}
      />
    </Column>
    """

    inner = ~MOB"""
    <Column fill_width={true}>
      {header}
      <Spacer size={14} />
      {rows}
      {footer}
    </Column>
    """

    Kati.Screens.BackupStates.panel(inner)
  end

  @doc """
  One line of the restore summary: the count, what it counted, a tick — with
  the hairline every row but the last carries.

  Hand-built rather than `Kati.UI.SettingsList.row/4`: that helper's leading
  slot is `icon_tile/1`'s 30pt square and its gap is a fixed 13, where this
  row leads with a mono figure at a fixed 44pt column and the board's own 12pt
  gap runs between all three parts evenly. The hairline is still
  `SettingsList.hairline/1` — the one piece of this row that is a component
  and not a number.
  """
  @spec restored_row(String.t(), String.t(), boolean()) :: map()
  def restored_row(number, label, rule?) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_top={9} padding_bottom={9}>
        <Box width={44}>
          <Text
            font_family="mono"
            text={number}
            text_size={13}
            text_color={Palette.ink()}
            max_lines={1}
          />
        </Box>
        <Column weight={1.0}>
          <Text text={label} text_size={12.5} text_color={Palette.ink_soft()} max_lines={1} />
        </Column>
        {UI.symbol("check", size: 15, color: Palette.green())}
      </Row>
      {SettingsList.hairline(rule?)}
    </Column>
    """
  end
end
