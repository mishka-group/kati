defmodule Kati.Screens.Backup do
  @moduledoc """
  Screen 128 — Back up everything, pushed under Settings.

  Built to `.scratch/design/incoming/128.html`, ticket `D-22`'s Screen A. That
  ticket is explicit about what this screen is and is not: *"a backup is a
  file you keep"*, one format that actually restores, and — deliberately — no
  restore flow on this board at all. Screen 129, *Restore from a backup*, is
  the other half of `D-22` and is `Kati.Screens.Restore`. Nothing here reaches
  into that half: this screen writes a file, and reading one back is not a
  thing it can do.

  ## This screen was split, and the drawings are the reason

  `Kati.Screens.Backup` existed before this board did — issue #64's answer to
  *`Kati.Backup` is finished and nothing calls it*, built with no drawing to
  work from, and it grew a passphrase field, three collision modes and a full
  restore flow because nothing constrained its shape. `128.html` and `129.html`
  are that constraint, and there are **two** of them. So the file became two
  files, and the cut runs exactly where the boards do:

    * **Everything about writing a file stayed here.** The format choice and
      the status card are this board's own; the count, the passphrase seal and
      the hand-off to Save and Share are the old screen's export half, kept
      working rather than dropped — an export that could not be sealed would be
      a smaller feature, not a smaller screen.
    * **Everything about reading one moved to `Kati.Screens.Restore`.**
      `choose/1` and the `{:files, …}` door, `Kati.Backup.inspect_file/2`, the
      passphrase that opens a sealed file, `:mode` and its three values,
      `restore_opts/1` and `safety_path/0`. That screen owns them now, and this
      one does not name any of them.

  The one function the two still share is `dropped_line/1`, which lives here
  and is called from `Kati.Screens.Restore.file_detail/1`: the columns the
  format leaves out are one fact, read off one manifest key, and it is worth
  saying at both ends of the same file.

  One contract survives untouched: **`Kati.Screens.Settings`'s ledger.** Its
  own moduledoc names `Kati.Screens.Backup.apply_event/2`'s `{:saved, …}`
  branch as the *only* writer of `Last backup`, and `Kati.SettingsBackupLineTest`
  drives that exact branch with a raw `{:kati_files, :saved, …}` message. This
  file keeps that branch, unchanged in effect: a completed Save As still, and
  only, calls `Kati.Screens.Settings.record_backup/0`. `Kati.Screens.Restore`
  hears the identical message when it hands out a pre-replace safety copy and
  deliberately does **not** stamp the ledger from it.

  ## What the board draws, and what this screen says after the button

  `128.html` draws one state: a status card, what travels, three formats, one
  button, one footnote. That is the resting frame and this file holds it
  exactly — `preview_card/1`, `passphrase_field/1` and `export_actions_card/1`
  are all zero-height spacers until something has happened, so the drawing and
  the screen agree at rest and `Kati.ScreenDesignLiteralTest` finds the board's
  copy and nothing else.

  What the board does not settle is what the screen says *after* its one
  button. `130.html` — *Backup & restore — eight states* — settles that a
  backup screen has states at all, and the answer this file keeps from the
  screen it replaced is the honest one: `Save a backup` takes
  `Kati.Backup.export/0`'s own count first, hands the file over through
  `hand_off/2`, and then shows what was actually in it. A button alone asks for
  faith; a number is a reading. Share and the passphrase seal live in that same
  opened surface, past the count, for the reasons `export_actions_card/1` and
  `passphrase_field/1` each give.

  ## The status card reads the same ledger, and adds one number of its own

  `128.html` draws `14 Aug · 2 WEEKS AGO · 214 MB`. The date is
  `Kati.Screens.Settings.last_backup/0` — the same fact Settings' own Export
  row reads, so the two screens cannot disagree about when the last backup
  was. The relative phrase is `Kati.Screens.UpNext.age/1`, which already
  renders exactly this vocabulary (`4 MONTHS AGO`) for a different screen's
  different timestamp; a second copy of that case ladder here would be a
  second place for the two to drift.

  The byte count has no home to read from — `Kati.Screens.Settings` tracks
  only the moment, never the size — and `Kati.Native.Files.decode/1`'s
  `{:saved, item}` already carries `item.bytes`, a real count of what was
  actually written, at the exact instant this screen is already calling
  `record_backup/0`. So `record_bytes/1` stamps a second, small ledger of its
  own — `Mob.State` under `:last_backup_bytes`, beside `:last_backup_at` for
  the same reason `Kati.Theme.Mode` and the backup ledger sit beside each
  other there: a screen process dies on the next root switch and a fact worth
  keeping outlives it. When the byte ledger is empty — an install that has a
  date from a build before this key existed — the size clause is dropped
  rather than guessed at; a wrong number is worse than a short line.

  ## `Never` is real, and it is not what the board draws

  `128.html` draws the *has-backed-up* state; ticket `D-22` draws the other
  one in words — *"the empty value is the word 'Never', and it is drawn as a
  gentle warning (cream ground, bronze mark) rather than as an error in red"*
  — because Never is the resting state of every install that has not yet, not
  a fault to redden. `Kati.Screens.Settings` already made this exact call for
  its own Export row, replacing its board's frozen `14 Aug` with the ledger's
  real answer; this screen makes the same call for the same reason; a fresh
  install renders `Never`, not the board's literal date.

  The warning card is `Palette.cream()` under `Palette.cream_ink()` and
  `Palette.gold_icon()` — the same three tokens `Kati.Screens.Money`'s hero
  card uses for a claim on a warm ground, and `gold_icon`'s own light value,
  `#C98A3E`, is the ticket's "bronze mark" to the pixel. Nothing new is
  invented; the existing warm-card vocabulary already says exactly this.

  ## Format is three rows with one selection, not a segmented control

  `D-22` leaves this open — *"whether Everything (JSON) and Per-section CSV
  are one control with three values or two separate rows"* — and `128.html`
  answers it: three list rows, each carrying its own trailing mark, exactly
  the shape `Kati.Screens.Settings`' theme trough and the old backup screen's
  collision modes both already use for *"choose one of several named things,
  each with its own sentence."* The chosen row draws no `on_tap`, for the
  reason both of those give: the tags a screen draws are the choices it can
  still make, and a control that answers a tap by setting the value it
  already has is a dead control wearing a live one's clothes.

  Only `:json` is real. `Kati.Backup.Sample.formats/0` says so in its own
  moduledoc — there is no per-section CSV writer and no `.ics` writer
  anywhere in `Kati.Backup` or `Kati.Calendars` — so choosing CSV or ICS is a
  real, live selection (the row's mark moves, which is what makes the tap
  alive rather than a catch-all) and *saving* under either answers honestly
  that the format is not built yet, rather than writing a JSON file while
  claiming to have written something else. That is this screen's own version
  of `D-22` Screen C's *"Export not available yet"* state, aimed at a format
  gap instead of a platform gap.

  ## Two literals with no token, left as literals

  `128.html`'s check tile is `rgba(78,154,115,.14)` — 14% green — and
  `Kati.Theme.Palette`'s nearest named wash, `green_wash`, is 16%. Taking the
  named token would move this row two points off the drawing, so the tile
  stays `0x244E9A73`, a literal, the same way `Kati.UI.timeline_row/4`'s dot
  and `Kati.UI.chip/2`'s disabled count colour do for the identical reason.
  The `Does not travel` divider is `rgba(26,25,23,.12)` — 12% ink — and sits
  between `hairline_strong` (10%) and `border_soft` (14%) with no token
  matching either; it stays `0x1F1A1917`.

  ## The footnote is hand-built, not `Kati.UI.SettingsList.note/2`

  `note/2` is the right *component* — `Kati.Components.MishkaPill` in its
  outlined, top-aligned mode — but it is pinned to one screen's numbers:
  16pt padding, an 18pt icon, `line_height: 1.55`. `128.html`'s footnote is
  15pt padding, a 17pt icon, `1.65` leading, and a bold run inside the
  paragraph — `**a file you keep**` — which `note/2`'s plain-text child cannot
  carry at all. So `footnote/0` calls the same component `note/2` calls, with
  this board's own numbers and `Kati.UI.rich_text/1` in place of the fixed
  paragraph. `rich_text/1`'s own moduledoc is direct about what that buys and
  what it does not: the bridge has no per-run styling, so the emphasis
  collapses to the paragraph's one style and the words survive; four other
  screens already make this exact trade.

  ## Where the tests for each half went

  `test/kati/screen_backup_test.exs` was written against the pre-board screen
  and drove both halves. It still drives both, from the two modules that now
  hold them: the export describes mount `Kati.Screens.Backup`, the restore
  describes mount `Kati.Screens.Restore` and say so in their own names. Two
  assertions could not follow, and each is argued in the test that lost it —
  the per-table refutation is now asked of the breakdown panel rather than of
  the page, because `128.html`'s own *Not your connected calendars* contains a
  table name as a substring; and the 38-character row rule exempts the board's
  three format sentences, which are the drawing's own and which `133.html`
  draws wrapping in full.

  `test/kati/settings_backup_line_test.exs` is different: its contract is the
  ledger, not this screen's shape, and it is untouched — `record_backup/0`
  still fires from, and only from, a decoded `{:saved, …}`, and `Saved` is
  still a literal this screen draws when it does.
  """
  use Kati.Screens.Pushed, back: "Settings"

  alias Kati.Backup.Error
  alias Kati.Backup.Sample
  alias Kati.Backup.Transport
  alias Kati.Native.Files
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  # The drawing's own 14% green — see the moduledoc on why no named token
  # stands in for it.

  # The drawing's own 12% ink — between `hairline_strong` (10%) and
  # `border_soft` (14%), matching neither.

  @bytes_key :last_backup_bytes

  @impl true
  def load(socket), do: Mob.Socket.assign(socket, :backup, Kati.Screens.Backup.blank())

  @doc """
  The screen at rest: the drawing's own default format, nothing counted, no
  passphrase and no notice showing.

  `load/1` reads nothing — not the database, not a file — so a fresh install
  and an empty database render exactly this. `preview`, `encrypt?` and
  `passphrase` are the export half's own state and every one of them is empty
  here: the count is a reading taken when it is asked for, and a passphrase
  Kati has not been given is not a passphrase it may assume.
  """
  @spec blank() :: map()
  def blank do
    %{
      format: Sample.default_format(),
      notice: nil,
      preview: nil,
      encrypt?: false,
      passphrase: ""
    }
  end

  # ── The frame ───────────────────────────────────────────────────────────────

  @doc false
  def content(assigns) do
    s = assigns.backup

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {SettingsList.chrome(nil)}
        {SettingsList.title("Back up everything", "ONE FILE, KEPT WHEREVER YOU LIKE")}
        {Kati.Screens.Backup.notice_block(s.notice)}
        {Kati.Screens.Backup.status_card()}
        {UI.eyebrow("What travels with it")}
        {Kati.Screens.Backup.travels_card()}
        {SettingsList.eyebrow_muted("Format")}
        {Kati.Screens.Backup.format_card(s.format)}
        {Kati.Screens.Backup.save_button()}
        {Kati.Screens.Backup.preview_card(s.preview)}
        {Kati.Screens.Backup.passphrase_field(s)}
        {Kati.Screens.Backup.export_actions_card(s.preview)}
        {Kati.Screens.Backup.footnote()}
      </Column>
    </Scroll>
    """
  end

  # ── Status card ─────────────────────────────────────────────────────────────

  @doc """
  `Last backup`, read off `Kati.Screens.Settings.last_backup/0` — the same
  ledger Settings' own Export row reads, so the two screens can never disagree
  about when the last backup was.

  See the moduledoc on why the resting state is `Never`, drawn as a gentle
  warning, rather than the board's own frozen `14 Aug`.
  """
  def status_card do
    case Kati.Screens.Settings.last_backup() do
      nil -> Kati.Screens.Backup.status_frame(false)
      %DateTime{} = at -> Kati.Screens.Backup.status_frame(true, at)
    end
  end

  @doc false
  def status_frame(made?, at \\ nil)

  def status_frame(false, nil) do
    Kati.Screens.Backup.status_frame(
      Palette.cream(),
      Palette.cream_meta(),
      Palette.cream_ink(),
      Palette.cream_sub(),
      "cloud_off",
      Palette.gold_icon(),
      "Never",
      "STILL ONLY ON THIS PHONE"
    )
  end

  def status_frame(true, at) do
    Kati.Screens.Backup.status_frame(
      Palette.card(),
      Palette.eyebrow(),
      :on_surface,
      Palette.muted(),
      "cloud_done",
      Palette.green(),
      Kati.Screens.Backup.date_text(at),
      Kati.Screens.Backup.caption(at)
    )
  end

  @doc false
  def status_frame(bg, meta_color, value_color, caption_color, icon, icon_color, value, caption) do
    body = ~MOB"""
    <Column weight={1.0}>
      <Text
        text={String.upcase("Last backup")}
        font_family="mono"
        text_size={10}
        letter_spacing={0.14}
        text_color={meta_color}
        max_lines={1}
      />
      <Spacer size={9} />
      <Text
        text={value}
        font_family="mono"
        text_size={22}
        font_weight="medium"
        letter_spacing={-0.02}
        text_color={value_color}
        max_lines={1}
      />
      <Spacer size={6} />
      <Text
        text={caption}
        font_family="mono"
        text_size={11}
        text_color={caption_color}
        max_lines={1}
      />
    </Column>
    """

    glyph = UI.symbol(icon, size: 22, color: icon_color)

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={bg}
        corner_radius={22}
        padding={17}
        shadow={Kati.Theme.shadow_card_soft()}
      >
        <Row fill_width={true} align="top">
          {body}
          <Spacer size={12} />
          {glyph}
        </Row>
      </Column>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc "`14 Aug` — day then short month, `Kati.Screens.Settings.backup_line/1`'s own form."
  @spec date_text(DateTime.t()) :: String.t()
  def date_text(%DateTime{} = at) do
    date = DateTime.to_date(at)
    "#{date.day} #{String.slice(Kati.Time.month_name(date.month), 0, 3)}"
  end

  @doc """
  `2 WEEKS AGO · 214 MB` — or just the relative half, when there is no byte
  ledger to read a size from.
  """
  @spec caption(DateTime.t()) :: String.t()
  def caption(%DateTime{} = at) do
    relative = Kati.Screens.UpNext.age(at)

    case Kati.Screens.Backup.format_size(Kati.Screens.Backup.last_backup_bytes()) do
      nil -> relative
      size -> relative <> " · " <> size
    end
  end

  @doc "Bytes to `214 MB` or `8 KB` — decimal, rounded, and `nil` stays `nil`."
  @spec format_size(non_neg_integer() | nil) :: String.t() | nil
  def format_size(nil), do: nil

  def format_size(bytes) when bytes < 1_000_000 do
    "#{max(div(bytes, 1000), 1)} KB"
  end

  def format_size(bytes), do: "#{round(bytes / 1_000_000)} MB"

  @doc "The byte count from the last completed Save As, or `nil` — see the moduledoc."
  @spec last_backup_bytes() :: non_neg_integer() | nil
  def last_backup_bytes do
    case Mob.State.get(@bytes_key) do
      n when is_integer(n) and n >= 0 -> n
      _ -> nil
    end
  end

  @doc false
  def record_bytes(bytes) when is_integer(bytes) and bytes >= 0 do
    Mob.State.put(@bytes_key, bytes)
    :ok
  end

  def record_bytes(_bytes), do: :ok

  # ── What travels, and what does not ─────────────────────────────────────────

  @doc "The one card holding both lists — `128.html`'s own divider between them."
  def travels_card do
    travels = Kati.Screens.Backup.card_rows(Sample.travels(), &Kati.Screens.Backup.travel_row/2)
    stays = Kati.Screens.Backup.card_rows(Sample.stays(), &Kati.Screens.Backup.stay_row/2)

    children =
      travels ++
        [Kati.Screens.Backup.travels_divider(), Kati.Screens.Backup.stays_label()] ++ stays

    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.card(children)}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def card_rows(rows, builder) do
    last = length(rows) - 1
    rows |> Enum.with_index() |> Enum.map(fn {row, i} -> builder.(row, i < last) end)
  end

  @doc """
  A row of what travels: the 14% green tile, the design's own tile size.

  Not `Kati.UI.SettingsList.icon_tile/1` and `body/2` — this row is a
  genuinely different recipe (24pt tile at radius 8, 13/11pt text, 11pt
  padding) from the canonical 30pt settings row, so reusing those two would
  move every one of those numbers rather than honour them.
  """
  def travel_row(row, rule?) do
    Kati.Screens.Backup.feature_row(
      row.icon,
      Palette.green_wash_soft(),
      Palette.green_text(),
      :on_surface,
      Palette.sub(),
      row.title,
      row.sub,
      1,
      rule?
    )
  end

  @doc "A row of what does not: the paper tile, and the title itself reads muted."
  def stay_row(row, rule?) do
    Kati.Screens.Backup.feature_row(
      row.icon,
      Palette.paper(),
      Palette.sub(),
      Palette.sub(),
      Palette.muted(),
      row.title,
      row.sub,
      2,
      rule?
    )
  end

  @doc false
  def feature_row(icon, tile_bg, icon_color, title_color, sub_color, title, sub, sub_lines, rule?) do
    tile =
      Kati.Components.MishkaThemeIcon.theme_icon(
        %{variant: :filled, color: tile_bg, size: 24, radius: 8},
        [UI.symbol(icon, size: 14, color: icon_color)]
      )

    body = ~MOB"""
    <Column weight={1.0}>
      <Text
        text={title}
        text_size={13}
        font_weight="semibold"
        text_color={title_color}
        max_lines={1}
      />
      <Spacer size={3} />
      <Text
        text={sub}
        text_size={11}
        line_height={1.5}
        text_color={sub_color}
        max_lines={sub_lines}
      />
    </Column>
    """

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_top={11} padding_bottom={11}>
        {tile}
        <Spacer size={12} />
        {body}
      </Row>
      {SettingsList.hairline(rule?)}
    </Column>
    """
  end

  @doc false
  def travels_divider do
    rule =
      Kati.Components.MishkaSeparator.separator(
        color: Palette.rule_full(),
        thickness: 1,
        render: :box
      )

    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={13} />
      {rule}
      <Spacer size={13} />
    </Column>
    """
  end

  @doc false
  def stays_label do
    ~MOB"""
    <Column fill_width={true}>
      <Text
        text={String.upcase("Does not travel")}
        font_family="mono"
        text_size={10}
        letter_spacing={0.14}
        text_color={Palette.eyebrow()}
        max_lines={1}
      />
      <Spacer size={4} />
    </Column>
    """
  end

  # ── Format ──────────────────────────────────────────────────────────────────

  @doc "The three formats, one chosen mark — full `Kati.UI.SettingsList.row/4` reuse."
  def format_card(chosen) do
    rows =
      Kati.Screens.Backup.card_rows(Sample.formats(), fn row, rule? ->
        Kati.Screens.Backup.format_row(row, chosen, rule?)
      end)

    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.card(rows)}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def format_row(row, chosen, rule?) do
    chosen? = row.tag == chosen

    SettingsList.row(
      SettingsList.icon_tile(row.icon),
      SettingsList.body(row.title, row.sub),
      Kati.Screens.Backup.format_mark(chosen?),
      padding: 13,
      rule: rule?,
      on_tap: Kati.Screens.Backup.format_tap(row.tag, chosen?)
    )
  end

  @doc false
  def format_tap(_tag, true), do: nil
  def format_tap(tag, false), do: {self(), Kati.Screens.Backup.format_tag(tag)}

  @doc "The tap tag for a format. One atom per format, all of them already existing."
  @spec format_tag(atom()) :: atom()
  def format_tag(tag), do: String.to_atom("format_" <> Atom.to_string(tag))

  @doc "The format a tag names, or `nil` for a tag no row draws."
  @spec format_for(atom()) :: atom() | nil
  def format_for(tag) do
    Enum.find_value(Sample.formats(), fn row ->
      if Kati.Screens.Backup.format_tag(row.tag) == tag, do: row.tag
    end)
  end

  @doc "The ink disc with a white check, or the plain 16% ring — 24pt either way."
  def format_mark(true) do
    Kati.Components.MishkaThemeIcon.theme_icon(
      %{variant: :filled, color: Palette.ink_fill(), size: 24, radius: 12},
      [UI.symbol("check", size: 15, color: Palette.on_ink())]
    )
  end

  def format_mark(false) do
    ~MOB"""
    <Box
      width={24}
      height={24}
      corner_radius={12}
      border_color={Palette.border()}
      border_width={1.5}
    />
    """
  end

  # ── Save ────────────────────────────────────────────────────────────────────

  @doc "The one ink primary button — `128.html`'s own 54pt / radius 27 / 14px shadow."
  def save_button do
    tap = {self(), :save_backup}

    ~MOB"""
    <Column fill_width={true}>
      <Box
        on_tap={tap}
        fill_width={true}
        height={54}
        corner_radius={27}
        background={Palette.ink_fill()}
        shadow="0 14 28 -12 #801A1917"
        align="center"
      >
        <Text
          text="Save a backup"
          text_size={14.5}
          font_weight="bold"
          text_color={Palette.on_ink()}
          max_lines={1}
        />
      </Box>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc """
  The footnote — `Kati.Components.MishkaPill` in `Kati.UI.SettingsList.note/2`'s
  own outlined, top-aligned mode, at `128.html`'s own numbers, with
  `Kati.UI.rich_text/1` carrying the one bold run `note/2`'s plain child
  cannot. See the moduledoc.
  """
  def footnote do
    body = [
      text_size: 12.5,
      line_height: 1.65,
      text_color: Palette.ink_soft(),
      font_family: "sans"
    ]

    strong = [
      font_weight: "semibold",
      text_color: Palette.ink(),
      text_size: 12.5,
      line_height: 1.65,
      font_family: "sans"
    ]

    paragraph =
      UI.rich_text([
        {"Kati has no server, so a backup is ", body},
        {"a file you keep", strong},
        {" — not something stored for you. Put it on a cloud drive, a computer, " <>
           "anywhere that is not only this phone. A backup that lives on the phone " <>
           "it is backing up is not a backup.", body}
      ])

    Kati.Components.MishkaPill.pill(
      %{
        background: :none,
        corner_radius: 18,
        border_color: Palette.border(),
        border_width: 1.5,
        padding: 15,
        fill_width: true,
        content_align: :top,
        content_fill_width: true,
        leading: UI.symbol("info", size: 17, color: Palette.sub()),
        leading_gap: 11
      },
      [paragraph]
    )
  end

  # ── What the export actually held ───────────────────────────────────────────

  @doc """
  Read every table and total it — `Kati.Backup.export/0`'s own manifest, not a
  cheaper count taken from somewhere else.

  A count from a different query could disagree with the file, and a screen that
  printed one number while the file held another would be worse than a screen
  with no number at all. `Kati.Backup.export/0` reads and serialises every
  table; there is no cheaper *how many rows* call that goes through the same
  code the file goes through, so this screen pays for the honest number rather
  than printing a cheaper one.

  The count is a **reading, not a staged file**. `export/0` is called again by
  `Kati.Backup.Transport.stage/1` when the file is actually written, so the
  bytes that reach the Save As… dialog are read at the moment of saving and can
  never be a stale snapshot from whenever the count was taken.
  """
  def count(socket) do
    bundle = Kati.Backup.export()
    counts = Map.fetch!(bundle.manifest, "record_counts")

    preview = %{
      rows: counts |> Enum.sort_by(&elem(&1, 0)),
      total: counts |> Map.values() |> Enum.sum(),
      tables: map_size(counts),
      dropped: Map.get(bundle.manifest, "dropped_columns", %{})
    }

    Kati.Screens.Backup.put_preview(socket, preview)
  end

  @doc "`2,481 records across 29 tables` — one sentence for the whole manifest."
  @spec preview_sub(map() | nil) :: String.t()
  def preview_sub(nil), do: "Every table, totalled"

  def preview_sub(preview) do
    records = Kati.Screens.Backup.group(preview.total)
    tables = Kati.Screens.Backup.group(preview.tables)

    records <> " records across " <> tables <> " tables"
  end

  @doc """
  The per-table breakdown of what a Save just wrote — drawn once, and only
  once, a count has been taken.

  `128.html` draws the resting frame and this is not on it, which is exactly
  why it is behind `nil`: at rest this is a zero-height spacer and the board
  is the board. What the drawing does not settle is what the screen says
  *after* the one button on it has been pressed, and the answer this file
  keeps from the screen it replaced is the honest one — a backup is the one
  thing in this app a person has to trust without being able to check, so the
  screen shows `Kati.Backup.export/0`'s own `record_counts` rather than only a
  button that claims to have saved them. A button alone asks for faith; a
  number is a reading.

  Tables holding nothing are counted rather than listed: twenty-nine zeroes is
  not a report. An empty database says so in a sentence instead, because an
  empty export is a real, restorable, empty file and not an error.
  """
  def preview_card(nil), do: ~MOB"<Spacer size={0} />"

  def preview_card(preview) do
    filled = Enum.reject(preview.rows, fn {_table, count} -> count == 0 end)
    empty = length(preview.rows) - length(filled)

    body =
      [
        Kati.Screens.Backup.headline(
          "inventory_2",
          Kati.Screens.Backup.preview_sub(preview),
          Palette.ink()
        ),
        ~MOB"<Spacer size={14} />"
      ] ++ Kati.Screens.Backup.preview_body(filled, empty, preview.dropped)

    inner = Kati.Screens.Backup.panel(body)

    ~MOB"""
    <Column fill_width={true}>
      {inner}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def preview_body([], _empty, _dropped) do
    [
      Kati.Screens.Backup.paragraph(
        "Nothing is stored on this device yet. A backup taken now would be a real " <>
          "file with real structure and no rows in it — it would restore, and it " <>
          "would restore nothing."
      )
    ]
  end

  def preview_body(filled, empty, dropped) do
    [
      Kati.Screens.Backup.table_lines(filled),
      Kati.Screens.Backup.empty_line(empty),
      Kati.Screens.Backup.dropped_line(dropped)
    ]
  end

  @doc false
  def table_lines(filled) do
    lines =
      Enum.map(filled, fn {table, count} -> Kati.Screens.Backup.table_line(table, count) end)

    ~MOB"""
    <Column fill_width={true}>
      {lines}
    </Column>
    """
  end

  @doc false
  def table_line(table, count) do
    number = Kati.Screens.Backup.group(count)

    ~MOB"""
    <Row fill_width={true} align="center" padding_top={4} padding_bottom={4}>
      <Text
        text={table}
        font_family="mono"
        text_size={11}
        text_color={Palette.meta()}
        max_lines={1}
        weight={1.0}
      />
      <Spacer size={12} />
      <Text
        text={number}
        font_family="mono"
        text_size={11}
        font_weight="semibold"
        text_color={:on_surface}
        max_lines={1}
      />
    </Row>
    """
  end

  @doc false
  def empty_line(0), do: ~MOB"<Spacer size={0} />"

  def empty_line(count) do
    tables = if count == 1, do: " table is empty", else: " tables are empty"
    text = Kati.Screens.Backup.group(count) <> tables

    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={10} />
      <Text
        text={text}
        font_family="mono"
        text_size={10.5}
        text_color={Palette.muted()}
        max_lines={1}
      />
    </Column>
    """
  end

  @doc """
  The columns the format deliberately leaves out, when this database has any.

  `Kati.Backup.Catalog` marks `calendar_accounts.credentials_ref` `:device_bound`
  — an opaque handle into this phone's keystore that would not open on another —
  and the manifest reports how many rows had one. Saying so is the difference
  between a backup that is honest about its edges and one that quietly loses a
  column.

  It lives on the export screen and `Kati.Screens.Restore.file_detail/1` calls
  it for the file it is about to write, because the two are the same fact read
  off the same manifest key from two ends. `128.html`'s own *Does not travel*
  block makes the same argument at the level of whole sections; this is that
  argument at the level of one column, with a real count behind it.
  """
  def dropped_line(dropped) when map_size(dropped) == 0, do: ~MOB"<Spacer size={0} />"

  def dropped_line(dropped) do
    names = dropped |> Map.keys() |> Enum.sort() |> Enum.join(", ")

    text =
      "Left out on purpose: " <>
        names <>
        ". These are handles into this phone and would not open on another one."

    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={12} />
      <Text text={text} text_size={11.5} line_height={1.5} text_color={Palette.sub()} />
    </Column>
    """
  end

  # ── The seal, and the two ways out ──────────────────────────────────────────

  @doc """
  The export passphrase field, drawn only while the seal is on.

  On the page rather than inside the card: `MobTextField` paints Material's own
  container in `surface_raised`, which is the card colour, so a field inside a
  card would be a card-coloured box on a card-coloured card.
  """
  def passphrase_field(%{encrypt?: false}), do: ~MOB"<Spacer size={0} />"

  def passphrase_field(s) do
    Kati.Screens.Backup.field(
      s.passphrase,
      "Passphrase",
      :export_passphrase,
      "The key comes from this passphrase and nothing else — never from the phone — " <>
        "so the file opens on the next one. There is no recovery: a forgotten " <>
        "passphrase loses the backup as completely as losing the phone did."
    )
  end

  @doc """
  The two ways a written export leaves the app, offered once there is a count
  to leave with.

  `128.html` draws one button, `Save a backup`, and it is the right one to
  draw: `Kati.Native.Files` is explicit that Android returns `RESULT_CANCELED`
  from a chooser whether the user completed a send or abandoned it, so a
  finished share **cannot be detected**, and a settings screen must not offer
  Share as the way to make a backup. That is why Share is not on the board and
  is not on the resting frame here either.

  It is still on the *screen*, past the count, because the engine can share and
  a person who has just been shown what is in the file is the one person who
  can be told the difference honestly: Save names where the file goes, Share
  says in its own second line that Android will not confirm it, and
  `{:dismissed, …}` is reported as *the sheet closed and the system did not say
  what happened*, never as success.
  """
  def export_actions_card(nil), do: ~MOB"<Spacer size={0} />"

  def export_actions_card(preview) do
    Kati.Screens.Backup.card(Kati.Screens.Backup.export_actions(preview))
  end

  @doc false
  def export_actions(nil), do: []

  def export_actions(_preview) do
    [
      %{
        icon: "upload",
        title: "Save a file",
        sub: "You choose where it goes",
        control: SettingsList.action_pill("Save"),
        tap: :save_file
      },
      %{
        icon: "ios_share",
        title: "Share a copy",
        sub: "Android cannot confirm it arrived",
        control: SettingsList.action_pill("Share"),
        tap: :share_file
      }
    ]
  end

  @doc false
  def card(rows) do
    last = length(rows) - 1

    body =
      rows
      |> Enum.with_index()
      |> Enum.map(fn {row, i} -> Kati.Screens.Backup.row(row, i < last) end)

    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.card(body)}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def row(row, rule?) do
    SettingsList.row(
      SettingsList.icon_tile(row.icon),
      SettingsList.body(row.title, row.sub),
      row.control,
      padding: 14,
      rule: rule?,
      on_tap: {self(), row.tap}
    )
  end

  @doc """
  A secure text field with its explanation under it.

  `value` is passed so the field can be cleared from this side after a
  passphrase has been used. `MobTextField` re-keys its `remember` only when the
  string actually differs, so echoing back what was just typed is a no-op and
  the caret does not move.
  """
  def field(value, placeholder, tag, hint) do
    change = {self(), tag}

    input = ~MOB"""
    <TextField
      value={value}
      placeholder={placeholder}
      secure={true}
      return_key="done"
      fill_width={true}
      on_change={change}
    />
    """

    ~MOB"""
    <Column fill_width={true}>
      {input}
      <Spacer size={9} />
      <Text text={hint} text_size={11.5} line_height={1.5} text_color={Palette.sub()} />
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def headline(icon, text, tint) do
    glyph = UI.symbol(icon, size: 18, color: tint)

    ~MOB"""
    <Row fill_width={true} align="center">
      {glyph}
      <Spacer size={9} />
      <Text
        text={text}
        text_size={13.5}
        font_weight="bold"
        letter_spacing={-0.01}
        text_color={tint}
        max_lines={2}
        weight={1.0}
      />
    </Row>
    """
  end

  # ── Notices ─────────────────────────────────────────────────────────────────

  @doc "The last thing Save did, in one card — dismissible, and gone when `nil`."
  def notice_block(nil), do: ~MOB"<Spacer size={0} />"

  def notice_block(notice) do
    tint = Kati.Screens.Backup.tint(notice.tone)

    body = [
      Kati.Screens.Backup.notice_headline(notice, tint),
      ~MOB"<Spacer size={10} />",
      Kati.Screens.Backup.paragraph(notice.body),
      Kati.Screens.Backup.notice_meta(notice[:meta])
    ]

    inner = Kati.Screens.Backup.panel(body)

    ~MOB"""
    <Column fill_width={true}>
      {inner}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def notice_headline(notice, tint) do
    glyph = UI.symbol(notice.icon, size: 18, color: tint)
    close = UI.symbol("close", size: 17, color: Palette.rail_idle())
    tap = {self(), :dismiss_notice}

    ~MOB"""
    <Row fill_width={true} align="center">
      {glyph}
      <Spacer size={9} />
      <Text
        text={notice.title}
        text_size={13.5}
        font_weight="bold"
        letter_spacing={-0.01}
        text_color={tint}
        max_lines={2}
        weight={1.0}
      />
      <Spacer size={12} />
      <Row align="center" on_tap={tap}>
        {close}
      </Row>
    </Row>
    """
  end

  # A refusal is not a failure and is not painted as one: an empty passphrase
  # field stopping an export is the screen doing its job, and it reads as a
  # decision rather than as something that went wrong.
  @doc false
  def tint(:ok), do: Palette.green_text()
  def tint(:error), do: Palette.red()
  def tint(:refused), do: Palette.ink()
  def tint(:info), do: Palette.ink_soft()

  @doc false
  def notice_meta(nil), do: ~MOB"<Spacer size={0} />"

  def notice_meta(text) do
    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={10} />
      <Text
        text={text}
        font_family="mono"
        text_size={10.5}
        line_height={1.5}
        text_color={Palette.muted()}
      />
    </Column>
    """
  end

  @doc false
  def paragraph(text) do
    ~MOB"""
    <Text text={text} text_size={12.5} line_height={1.55} text_color={Palette.ink_soft()} />
    """
  end

  @doc """
  `Kati.UI.card/2` with the lift every other card on this page has — see
  `Kati.Screens.Backup`'s panel-vs-`SettingsList.card/1` split, unchanged from
  the old file: a summary panel sits on the page, not on a card, and needs the
  shadow `card/2` itself does not carry.
  """
  def panel(body) do
    card = UI.card(body, padding: 18, background: Palette.card())
    %{card | props: Map.put(card.props, :shadow, Kati.Theme.shadow_card_soft())}
  end

  # ── Taps ────────────────────────────────────────────────────────────────────

  @impl true
  def handle_tap(:save_backup, socket), do: {:noreply, Kati.Screens.Backup.save(socket)}

  def handle_tap(:count_records, socket), do: {:noreply, Kati.Screens.Backup.count(socket)}

  def handle_tap(:toggle_encrypt, socket),
    do: {:noreply, Kati.Screens.Backup.toggle_encrypt(socket)}

  def handle_tap(:save_file, socket), do: {:noreply, Kati.Screens.Backup.hand_off(:save, socket)}

  def handle_tap(:share_file, socket),
    do: {:noreply, Kati.Screens.Backup.hand_off(:share, socket)}

  def handle_tap(:dismiss_notice, socket),
    do: {:noreply, Kati.Screens.Backup.put_notice(socket, nil)}

  def handle_tap(tag, socket), do: {:noreply, Kati.Screens.Backup.choose_format(socket, tag)}

  @doc """
  A format tag sets the format; anything else leaves the screen alone.

  Named rather than folded into the case above for the reason
  `Kati.Screens.Settings.choose_mode/2` gives its own twin: the tap sweep's
  "no new dead-looking taps" check cannot see through a bare `_tag ->` arm, so
  this has to be the only thing behind it.
  """
  def choose_format(socket, tag) do
    case Kati.Screens.Backup.format_for(tag) do
      nil -> socket
      format -> Kati.Screens.Backup.put_format(socket, format)
    end
  end

  @doc false
  def put_format(socket, format) do
    s = socket.assigns.backup
    Mob.Socket.assign(socket, :backup, %{s | format: format})
  end

  @doc false
  def put_notice(socket, notice) do
    s = socket.assigns.backup
    Mob.Socket.assign(socket, :backup, %{s | notice: notice})
  end

  @doc false
  def put_preview(socket, preview) do
    s = socket.assigns.backup
    Mob.Socket.assign(socket, :backup, %{s | preview: preview})
  end

  @doc "Turn the passphrase seal on or off. See `hand_off/2` for what it then costs."
  def toggle_encrypt(socket) do
    s = socket.assigns.backup
    Mob.Socket.assign(socket, :backup, %{s | encrypt?: not s.encrypt?})
  end

  @doc """
  Save, in the chosen format.

  `:json` is the only one `Kati.Backup` can write, so it is the only one that
  opens the system dialog; the other two answer honestly that they are not
  built rather than writing a JSON file under a different row's name. See the
  moduledoc.

  The count is taken first, so what the screen shows afterwards is a reading of
  the same tables the file was built from rather than a claim about them, and
  the hand-off goes through `hand_off/2` so the passphrase seal is checked on
  the one path a person can actually reach.
  """
  def save(socket) do
    Kati.Screens.Backup.save_as(socket.assigns.backup.format, socket)
  end

  @doc false
  def save_as(:json, socket) do
    Kati.Screens.Backup.hand_off(:save, Kati.Screens.Backup.count(socket))
  end

  def save_as(format, socket) do
    row = Enum.find(Sample.formats(), &(&1.tag == format))

    Kati.Screens.Backup.put_notice(socket, %{
      tone: :info,
      icon: "info",
      title: "#{row.title} is not built yet",
      body:
        "Kati can only write the full Everything (JSON) file today — the one that " <>
          "restores. Choose it above and Save a backup again."
    })
  end

  @doc """
  Stage an export and hand it to the system, by whichever door was asked for.

  An empty passphrase is refused **here**, before the export runs: the envelope
  refuses it too, but only after every table has been read and serialised, and
  making the user wait for a file to be built before being told the field is
  empty is a worse answer than the same sentence immediately.
  """
  def hand_off(call, socket) do
    s = socket.assigns.backup

    if s.encrypt? and String.trim(s.passphrase) == "" do
      Kati.Screens.Backup.put_notice(socket, %{
        tone: :refused,
        icon: "lock",
        title: "There is no passphrase to seal it with",
        body:
          "The passphrase switch is on and the field is empty. Kati will not write a " <>
            "file that claims to be encrypted and is not, and it will not quietly " <>
            "write one in the clear either. Nothing has been exported."
      })
    else
      Kati.Screens.Backup.hand_off_now(call, socket, s)
    end
  end

  @doc false
  def hand_off_now(call, socket, s) do
    opts = Kati.Screens.Backup.passphrase_opts(s.encrypt?, s.passphrase)

    result =
      case call do
        :save -> Transport.save(opts)
        :share -> Transport.share(opts)
      end

    Kati.Screens.Backup.put_notice(socket, Kati.Screens.Backup.hand_off_notice(call, result))
  end

  @doc "A passphrase, only when the seal is on — an empty option list is not a key."
  @spec passphrase_opts(boolean(), String.t()) :: keyword()
  def passphrase_opts(false, _passphrase), do: []
  def passphrase_opts(true, passphrase), do: [passphrase: passphrase]

  @doc false
  def hand_off_notice(:save, {:ok, summary}) do
    %{
      tone: :info,
      icon: "upload",
      title: "Choose where to keep it",
      body:
        "Kati has written " <>
          Kati.Screens.Backup.group(summary.total_records) <>
          " records and the system dialog is open. The backup exists once you have " <>
          "picked a folder — until then nothing has left the app.",
      meta: summary.filename
    }
  end

  def hand_off_notice(:share, {:ok, summary}) do
    %{
      tone: :info,
      icon: "ios_share",
      title: "The sheet is open — this is not a backup",
      body:
        "Android returns the same answer whether a share completes or the sheet is " <>
          "dismissed, so Kati cannot tell you this arrived anywhere. Use Save a backup " <>
          "for the copy you are relying on.",
      meta: summary.filename
    }
  end

  def hand_off_notice(_call, {:error, %Error{reason: :no_transport} = error}) do
    %{
      tone: :info,
      icon: "info",
      title: "The file is written and waiting",
      body: error.message,
      meta: error.details[:path]
    }
  end

  def hand_off_notice(_call, {:error, %Error{} = error}) do
    %{tone: :error, icon: "error", title: "Kati could not make the backup", body: error.message}
  end

  # ── Messages from the device ────────────────────────────────────────────────

  # Everything that is not a tap. One clause for the passphrase field and one
  # that asks `event/1` whether a message is a file-transport answer, with
  # `super/2` under it for the shell's own tags. The macro's `handle_info/2`
  # clauses are `defoverridable`, so an override replaces the WHOLE set —
  # `super/2` is how `:back` and every other tag keep working, and dropping it
  # would take the back pill with it.
  @impl true
  def handle_info({:change, tag, value}, socket) when is_atom(tag) and is_binary(value) do
    {:noreply, Kati.Screens.Backup.typed(socket, tag, value)}
  end

  def handle_info(message, socket) do
    case Kati.Screens.Backup.event(message) do
      :ignore -> super(message, socket)
      event -> {:noreply, Kati.Screens.Backup.apply_event(event, socket)}
    end
  end

  @doc false
  def typed(socket, :export_passphrase, value) do
    s = socket.assigns.backup
    Mob.Socket.assign(socket, :backup, %{s | passphrase: value})
  end

  def typed(socket, _tag, _value), do: socket

  @doc "A device message as a value, or `:ignore` — `Kati.Native.Files.decode/1`'s own answer."
  @spec event(term()) :: term()
  def event(message), do: Files.decode(message)

  @doc """
  What a device message does to the screen.

  `{:saved, item}` is the one branch `Kati.Screens.Settings`' moduledoc names
  as the only writer of the backup ledger, and it still is: this is the one
  place `record_backup/0` and `record_bytes/1` are called, and the only place
  either is called from.
  """
  def apply_event({:saved, item}, socket) do
    :ok = Kati.Screens.Settings.record_backup()
    :ok = Kati.Screens.Backup.record_bytes(item.bytes)

    Kati.Screens.Backup.put_notice(socket, %{
      tone: :ok,
      icon: "check_circle",
      title: "Saved",
      body:
        "#{Kati.Screens.Backup.group(item.bytes)} bytes were written where you chose. " <>
          "That file is the backup — keep it somewhere that is not only this phone.",
      meta: item.name
    })
  end

  def apply_event(:cancelled, socket) do
    Kati.Screens.Backup.put_notice(socket, %{
      tone: :info,
      icon: "info",
      title: "The backup was not saved",
      body: "You closed the folder chooser, so nothing was written outside Kati."
    })
  end

  # Neither branch touches the ledger. `128.html` offers no Share row, but
  # `Kati.Native.Files.decode/1` still recognises a share outcome from any
  # door, and `record_backup/0` firing only from `{:saved, …}` has to hold no
  # matter which message reaches this screen — `Kati.SettingsBackupLineTest`
  # asserts exactly that.
  def apply_event({:shared, item}, socket) do
    Kati.Screens.Backup.put_notice(socket, %{
      tone: :info,
      icon: "info",
      title: "The receiving app took it",
      body: "That is not the same as a backup — Save a backup is the one that counts.",
      meta: item.name
    })
  end

  def apply_event({:dismissed, item}, socket) do
    Kati.Screens.Backup.put_notice(socket, %{
      tone: :info,
      icon: "info",
      title: "The share sheet closed",
      body: "Android does not say whether the file was sent or the sheet was dismissed.",
      meta: item.name
    })
  end

  def apply_event({:error, reason}, socket) do
    Kati.Screens.Backup.put_notice(socket, %{
      tone: :error,
      icon: "error",
      title: "The system dialog failed",
      body: "Nothing on this device has changed.",
      meta: inspect(reason)
    })
  end

  def apply_event(_other, socket), do: socket

  @doc """
  `1,480`, never `1480`. Written here rather than taken from `Cldr.Number` for
  the reason `Kati.Screens.MealsToday` gives: this screen is the English one
  and the sweep renders it directly.
  """
  @spec group(integer()) :: String.t()
  def group(number) when is_integer(number) do
    number
    |> Integer.to_string()
    |> String.reverse()
    |> String.replace(~r/(\d{3})(?=\d)/, "\\1,")
    |> String.reverse()
  end
end
