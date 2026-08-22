defmodule Kati.Screens.Backup do
  @moduledoc """
  Backup — export and restore, pushed under Settings.

  ## There is no drawing for this screen, and it was not improvised

  `.scratch/design/screens/` stops at 62 and none of those 62 is a backup
  screen. Issue #25 asks for one; it does not exist. So this screen is **not**
  built to a frame — and it does not invent a look either. Every node below is
  `Kati.UI.SettingsList`'s: the `#FBFAF8` card at radius 20 with 15pt sides, the
  30x30 paper icon tile, the 13.5pt semibold title over its 11.5pt second line,
  the 7% hairline that the last row of a card does not get, the paper action
  pill, the 46x28 switch, and the outlined note. They are arranged in **screen
  24's** rhythm — title, eyebrow, grouped card, eyebrow, grouped card, muted
  eyebrow, notes — because `Kati.Screens.Settings` is this screen's closest
  sibling and the one to read beside it. Where the two differ, it is because
  this screen has states 24 has none of, never because a different idiom was
  preferred.

  Two consequences follow from having no drawing, and both are recorded rather
  than left to be rediscovered:

    * It is **not** in `Kati.Screens.Gallery`'s numbered registry. That list is
      keyed by design number and `Kati.ScreenDesignLiteralTest` checks every
      entry against `.scratch/design/screens/NN.html`, so an entry there would
      be a claim that a frame exists. It is named in that file's `@undesigned`
      instead — the same fact from the other end. The gallery still *opens* it,
      off its unnumbered `@undrawn` list, because "every screen in one list,
      each one tappable" is that page's other job and does not need a number.
    * It is **not** in `Kati.ScreenEmptyDatabaseTest`'s `@migrated`, which is
      also keyed by number and asks "does this screen still draw its drawing".
      There is no drawing to still draw. It is in that file's `@undrawn`, which
      asks the half of the question that does apply: *does it render at all
      against an empty database* — and it does, because `load/1` reads nothing.

  ## What this screen is for

  `Kati.Backup` was finished and proven on the device — an 8,736-byte export, a
  default restore that refused and named the 13 rows it found, a merge that
  succeeded, an encrypted export, a wrong passphrase, a right one — and
  **nothing in the app called any of it**. An engine no screen reaches is not
  insurance; it is a file in a repository. A user could not back up, could not
  restore, and could not be told why a restore was refused. This is the missing
  half of #64.

  It is reached from screen 24's Data group: `Kati.Screens.Settings`'s
  `@destinations` maps `Export everything` here, and `Kati.Screens.SettingsFa`
  names the same destination off the same row. That row was always drawn as a
  link and was one of the two in the group that went nowhere. Nothing in this
  file depends on that entry — the screen mounts and renders on its own, which
  is what lets its own suite drive it — but an engine reachable only from a
  test would be the same defect one level up.

  ## Counting before saving is the design, not a step in the way

  The export group leads with **Count what a backup would hold**, and the Save
  and Share rows do not exist until it has been answered. That is deliberate:
  a backup is the one thing in this app a user has to be able to trust without
  being able to check, so the screen shows `Kati.Backup.export/0`'s own
  `record_counts` — *"2,481 records across 14 tables"*, with the per-table
  breakdown under it — before it offers a button that claims to have saved
  them. A button alone asks for faith; a number is a reading.

  The count is a **reading, not a staged file**. `export/0` is called again by
  `Kati.Backup.Transport.stage/1` when the user actually saves, so the bytes
  that reach the Save As… dialog are read at the moment of saving and can never
  be a stale snapshot from whenever the user last tapped Count.

  ## Save is the backup; Share is not

  `Kati.Native.Files` is explicit that Android returns `RESULT_CANCELED` from a
  chooser whether the user completed a send or abandoned it, so a finished
  share **cannot be detected** — and that a settings screen therefore must not
  offer Share as the way to make a backup. Both rows are here, and they say
  which is which: Save names where the file goes, Share says in its own second
  line that Android will not confirm it. `{:dismissed, …}` is reported as "the
  sheet closed and the system did not say what happened", never as success.

  ## Restore shows `inspect_file/1`'s answer before it does anything

  A picked file is passed through `Kati.Backup.Transport.accept/1` — which
  refuses by extension, because SAF cannot filter on one — and then through
  `Kati.Backup.inspect_file/2`, which opens and verifies the archive **without
  touching the database**. Its answer is what the card draws: when it was made,
  how many records across how many tables, which app version wrote it, and
  whether it is encrypted. That function exists precisely so a screen can never
  print counts that a restore would then reject, so this screen never prints a
  count it has not read out of the file itself.

  An encrypted file answers without the passphrase — `encrypted: true`,
  `unlocked: false`, the envelope's cipher and iterations, `nil` for everything
  inside the ciphertext. The card says exactly that and offers the passphrase
  field, because "this is encrypted" and "this is unreadable" are different
  sentences and a user holding their only backup needs the first one.

  ## The three modes are a choice, and the refusal is one of the three

  `:into_empty` is the default and it **refuses** when anything is stored,
  naming what it found. This screen does not bury that behind a generic error.
  It is drawn as the safest of three deliberate choices under its own eyebrow —
  *If Kati already has data* — with `:merge` and `:replace` beside it, and when
  the refusal fires the notice carries the engine's own sentence and offers the
  other two as pills. Nothing has been changed is the headline, because nothing
  has been.

  `:replace` needs a safety export or the engine refuses it, so the requirement
  is **surfaced rather than tripped over**: choosing Replace draws the note
  naming the file Kati will write first and stating that if that write fails,
  nothing is deleted.

  That copy does **not** go in `Kati.Backup.Transport.staging_dir/1`. Staging
  is swept hourly by `Transport.sweep/1`, and the safety export is the only
  remaining copy of data the user has just replaced — an hour later it would be
  gone. `safety_path/0` below names a directory nothing sweeps, and the notice
  carries that path so the copy can be handed to the system afterwards.

  ## A wrong passphrase gets the engine's sentence, unedited

  `Kati.Backup.Envelope` answers a failed unseal with: *that passphrase does not
  open this backup; either it is not the one it was made with or the file has
  been altered since — Kati cannot tell those apart, and it will not guess.*
  Every failure notice here renders `%Kati.Backup.Error{}.message` verbatim,
  so the screen cannot drift from what the engine actually decided, and cannot
  soften a refusal into a shrug.

  ## Two departures worth writing down

    * **The passphrase fields are Material's.** The design has no drawing of a
      text field anywhere, and `MobBridge.kt`'s `MobTextField` is a Material 3
      `TextField` that paints its own container: of the props the vendored
      Chelekom inputs pass it, only `placeholder`, `value`, `secure`,
      `keyboard`, `return_key` and the event handlers are read — `underline`,
      `enabled`, `text_align` and `max_length` are not. So the box is Material's
      shape. It is not Material's *colour*: `MainActivity.kt` builds its
      `colorScheme` from `Mob.Theme`, so the field's container is
      `surface_raised` (the card colour) and its text is `on_surface`, both of
      which move with the app's palette. That is also why the fields sit on the
      page rather than inside a card — the container and the card are the same
      colour, and a field inside one would be invisible.
    * **The count is the whole export.** `Kati.Backup.export/0` reads and
      serialises every table; there is no cheaper "how many rows" call that
      goes through the same code the file goes through, and a count taken from
      a different path could disagree with the file. The screen pays for the
      honest number rather than printing a cheaper one.

  ## Nothing here is persisted

  `Kati.Screens.Pushed` expands to `use Mob.Screen` with no `:vsn` and no
  `persist: true`, so `Mob.Screen.__mob_persist__/0` is false and this screen's
  assigns are never written to `mob_screen_states`. That matters more here than
  anywhere else in the app: the assigns hold typed passphrases, and a screen
  that dumped them to SQLite would defeat the envelope it was helping to make.
  """
  use Kati.Screens.Pushed, back: "Settings"

  alias Kati.Backup.Error
  alias Kati.Backup.Transport
  alias Kati.Native.Files
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  @modes [:into_empty, :merge, :replace]

  @impl true
  def load(socket), do: Mob.Socket.assign(socket, :backup, Kati.Screens.Backup.blank())

  @doc """
  The screen at rest.

  `load/1` reads nothing — not the database, not a file, not `Mob.State` — so a
  fresh install and an empty database render exactly this, and
  `Kati.ScreenEmptyDatabaseTest` has nothing to catch. Every number this screen
  shows is fetched by a tap and is a reading of the thing it names.
  """
  @spec blank() :: map()
  def blank do
    %{
      preview: nil,
      encrypt?: false,
      passphrase: "",
      mode: :into_empty,
      file: nil,
      unlock: "",
      notice: nil
    }
  end

  @doc "Every collision mode, in the order the rows draw them: safest first."
  @spec modes() :: [atom()]
  def modes, do: @modes

  # ── The frame ───────────────────────────────────────────────────────────────

  @doc false
  def content(assigns) do
    s = assigns.backup

    # Bound to a local: the sigil is UPPERCASE, so `#{}` inside it is literal
    # text, and `@name` inside it would mean `assigns.name`.
    tables = "#{length(Kati.Backup.Catalog.tables())} TABLES · A ZIP OF JSON"

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {SettingsList.chrome(nil, 42)}
        {SettingsList.title("Backup", tables, "archive")}
        {Kati.Screens.Backup.notice_block(s.notice)}
        {UI.eyebrow("Export")}
        {Kati.Screens.Backup.export_card(s)}
        {Kati.Screens.Backup.passphrase_field(s)}
        {Kati.Screens.Backup.preview_card(s.preview)}
        {UI.eyebrow("Restore")}
        {Kati.Screens.Backup.restore_card(s)}
        {Kati.Screens.Backup.file_card(s.file)}
        {Kati.Screens.Backup.unlock_field(s)}
        {SettingsList.eyebrow_muted("If Kati already has data")}
        {Kati.Screens.Backup.mode_card(s)}
        {Kati.Screens.Backup.mode_note(s)}
        {Kati.Screens.Backup.restore_action(s)}
        {SettingsList.eyebrow_muted("About backups")}
        {Kati.Screens.Backup.footnotes()}
      </Column>
    </Scroll>
    """
  end

  # ── Export ──────────────────────────────────────────────────────────────────

  @doc """
  The export group: what a backup holds, the passphrase switch, and — only once
  the first has been answered — the two ways out of the app.

  See the moduledoc on why Save and Share are not drawn before the count.
  """
  def export_card(s) do
    rows =
      [
        %{
          icon: "inventory_2",
          title: "What a backup holds",
          sub: Kati.Screens.Backup.preview_sub(s.preview),
          control: SettingsList.action_pill(Kati.Screens.Backup.count_label(s.preview)),
          tap: :count_records
        },
        %{
          icon: "lock",
          title: "Protect with a passphrase",
          sub: "Nobody can reset it",
          control: SettingsList.switch(s.encrypt?),
          tap: :toggle_encrypt
        }
      ] ++ Kati.Screens.Backup.export_actions(s.preview)

    Kati.Screens.Backup.card(rows)
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
  def count_label(nil), do: "Count"
  def count_label(_preview), do: "Again"

  @doc false
  def preview_sub(nil), do: "Every table, totalled"

  def preview_sub(preview) do
    records = Kati.Screens.Backup.group(preview.total)
    tables = Kati.Screens.Backup.group(preview.tables)

    records <> " records across " <> tables <> " tables"
  end

  @doc """
  The per-table breakdown, drawn once the count has been taken.

  Tables holding nothing are counted rather than listed: fourteen zeroes is not
  a report. An empty database says so in a sentence instead, because an empty
  export is a real, restorable, empty file and not an error.
  """
  def preview_card(nil), do: ~MOB"<Spacer size={0} />"

  def preview_card(preview) do
    filled = Enum.reject(preview.rows, fn {_table, count} -> count == 0 end)
    empty = length(preview.rows) - length(filled)

    body =
      if filled == [] do
        [
          Kati.Screens.Backup.paragraph(
            "Nothing is stored on this device yet. A backup taken now would be a real " <>
              "file with real structure and no rows in it — it would restore, and it " <>
              "would restore nothing."
          )
        ]
      else
        [
          Kati.Screens.Backup.total_line(preview.total),
          ~MOB"<Spacer size={14} />",
          Kati.Screens.Backup.table_lines(filled),
          Kati.Screens.Backup.empty_line(empty),
          Kati.Screens.Backup.dropped_line(preview.dropped)
        ]
      end

    inner = Kati.Screens.Backup.panel(body)

    ~MOB"""
    <Column fill_width={true}>
      {inner}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def total_line(total) do
    text = Kati.Screens.Backup.group(total)

    number = ~MOB"""
    <Text
      text={text}
      text_size={34}
      font_weight="bold"
      letter_spacing={-0.03}
      text_color={:on_surface}
      max_lines={1}
    />
    """

    unit = ~MOB"""
    <Text
      text="records"
      text_size={13}
      font_weight="semibold"
      text_color={Palette.sub()}
      max_lines={1}
    />
    """

    row = UI.number_with_unit(number, unit, 6)

    ~MOB"""
    <Row fill_width={true} align="bottom">
      {row}
    </Row>
    """
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

  @doc """
  The export passphrase field.

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

  # ── Restore ─────────────────────────────────────────────────────────────────

  @doc "Picking a file, and letting go of one."
  def restore_card(s) do
    rows =
      [
        %{
          icon: "download",
          title: "Choose a backup file",
          sub: Kati.Screens.Backup.file_sub(s.file),
          control: SettingsList.action_pill(Kati.Screens.Backup.choose_label(s.file)),
          tap: :choose_file
        }
      ] ++ Kati.Screens.Backup.forget_row(s.file)

    Kati.Screens.Backup.card(rows)
  end

  @doc false
  def forget_row(nil), do: []

  def forget_row(_file) do
    [
      %{
        icon: "close",
        title: "Forget this file",
        sub: "Nothing on the device changes",
        control: SettingsList.action_pill("Forget"),
        tap: :forget_file
      }
    ]
  end

  @doc false
  def choose_label(nil), do: "Choose"
  def choose_label(_file), do: "Change"

  @doc false
  def file_sub(nil), do: ".katibackup, from anywhere"
  def file_sub(file), do: file.name

  @doc """
  What `Kati.Backup.inspect_file/2` said about the picked file — and nothing
  this screen worked out for itself.

  A locked envelope answers with its own header and `nil` for everything inside
  the ciphertext, so the unlocked and locked cards are two different sets of
  facts rather than one set with holes punched in it.
  """
  def file_card(nil), do: ~MOB"<Spacer size={0} />"

  def file_card(%{summary: nil}), do: ~MOB"<Spacer size={0} />"

  def file_card(file) do
    summary = file.summary

    body =
      [
        Kati.Screens.Backup.file_headline(summary),
        ~MOB"<Spacer size={10} />",
        Kati.Screens.Backup.file_meta(file, summary)
      ] ++ Kati.Screens.Backup.file_detail(summary)

    inner = Kati.Screens.Backup.panel(body)

    ~MOB"""
    <Column fill_width={true}>
      {inner}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def file_headline(%{unlocked: true} = summary) do
    records = Kati.Screens.Backup.group(summary.total_records)
    tables = Kati.Screens.Backup.group(map_size(summary.record_counts))
    text = records <> " records across " <> tables <> " tables"

    Kati.Screens.Backup.headline("inventory_2", text, Palette.ink())
  end

  def file_headline(_summary) do
    Kati.Screens.Backup.headline("lock", "Encrypted — Kati cannot read it yet", Palette.ink())
  end

  @doc false
  def file_meta(file, summary) do
    made = Kati.Screens.Backup.stamp(summary.exported_at)
    app = summary.app_version || "unknown"
    text = file.name <> " · made " <> made <> " · Kati " <> app

    ~MOB"""
    <Text
      text={text}
      font_family="mono"
      text_size={10.5}
      line_height={1.5}
      text_color={Palette.muted()}
    />
    """
  end

  @doc false
  def file_detail(%{unlocked: true, encrypted: encrypted}) do
    text =
      if encrypted do
        "Opened with the passphrase you entered. These counts were read out of " <>
          "the file itself, so a restore cannot refuse numbers this card has shown."
      else
        "Not encrypted. Anyone holding this file can read everything in it, which " <>
          "is why it is worth keeping somewhere you would keep a passport."
      end

    [
      ~MOB"<Spacer size={12} />",
      Kati.Screens.Backup.paragraph(text)
    ]
  end

  def file_detail(summary) do
    [
      ~MOB"<Spacer size={12} />",
      Kati.Screens.Backup.paragraph(
        "Kati can see that this is a Kati backup and when it was sealed. It cannot " <>
          "see how many records are inside until the passphrase opens it, and it " <>
          "will not guess at a number it has not read."
      ),
      Kati.Screens.Backup.envelope_line(summary.encryption)
    ]
  end

  @doc false
  def envelope_line(nil), do: ~MOB"<Spacer size={0} />"

  def envelope_line(encryption) do
    text =
      [
        encryption[:cipher],
        encryption[:kdf],
        Kati.Screens.Backup.rounds(encryption[:iterations])
      ]
      |> Enum.reject(&is_nil/1)
      |> Enum.join(" · ")

    Kati.Screens.Backup.mono_line(text)
  end

  @doc false
  def rounds(nil), do: nil
  def rounds(iterations), do: Kati.Screens.Backup.group(iterations) <> " rounds"

  @doc "The passphrase field for a locked file, drawn only while it is locked."
  def unlock_field(%{file: %{summary: %{unlocked: false}}} = s) do
    Kati.Screens.Backup.field(
      s.unlock,
      "Passphrase for this file",
      :restore_passphrase,
      "A wrong passphrase and an altered file fail identically — GCM cannot tell " <>
        "a wrong key from changed bytes — so Kati will say so rather than pick one.",
      {"Unlock", :unlock_file}
    )
  end

  def unlock_field(_s), do: ~MOB"<Spacer size={0} />"

  # ── The three modes ─────────────────────────────────────────────────────────

  @doc """
  The collision modes, safest first, exactly one of them raised.

  The chosen row carries **no** `on_tap`, for the reason
  `Kati.Screens.Settings.segment/2` gives about the theme trough: the tags a
  screen draws are the choices it can still make, and a control that answers a
  tap by setting the value it already has is indistinguishable from a dead one.
  """
  def mode_card(s) do
    last = length(@modes) - 1

    rows =
      @modes
      |> Enum.with_index()
      |> Enum.map(fn {mode, i} ->
        Kati.Screens.Backup.mode_row(mode, s.mode, i < last)
      end)

    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.card(rows)}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def mode_row(mode, chosen, rule?) do
    {icon, title, sub} = Kati.Screens.Backup.mode_copy(mode)
    chosen? = mode == chosen

    SettingsList.row(
      SettingsList.icon_tile(icon),
      SettingsList.body(title, sub),
      Kati.Screens.Backup.mode_mark(chosen?),
      padding: 14,
      rule: rule?,
      on_tap: Kati.Screens.Backup.mode_tap(mode, chosen?)
    )
  end

  @doc false
  def mode_tap(_mode, true), do: nil
  def mode_tap(mode, false), do: {self(), Kati.Screens.Backup.mode_tag(mode)}

  @doc "The tap tag for a mode. One atom per mode, all of them already existing."
  @spec mode_tag(atom()) :: atom()
  def mode_tag(:into_empty), do: :mode_into_empty
  def mode_tag(:merge), do: :mode_merge
  def mode_tag(:replace), do: :mode_replace

  @doc "The mode a tag names, or `nil` for a tag no row draws."
  @spec mode_for(atom()) :: atom() | nil
  def mode_for(tag),
    do: Enum.find(@modes, fn mode -> Kati.Screens.Backup.mode_tag(mode) == tag end)

  @doc false
  def mode_copy(:into_empty),
    do: {"shield", "Only into an empty Kati", "Refuses if anything is here"}

  def mode_copy(:merge),
    do: {"call_merge", "Merge into what is here", "Insert-only, never overwrites"}

  def mode_copy(:replace),
    do: {"delete_forever", "Replace everything", "Empties every table first"}

  # Two glyphs, not two colours: the raised row has to be legible to someone who
  # cannot tell the tints apart, which is the same argument the Chelekom
  # checkbox makes for drawing a dash rather than only tinting.
  @doc false
  def mode_mark(true), do: UI.symbol("check_circle", size: 20, color: Palette.green())

  def mode_mark(false),
    do: UI.symbol("radio_button_unchecked", size: 20, color: Palette.rail_idle())

  @doc """
  The chosen mode, argued at length under the card that names the three.

  The rows themselves cannot carry this: `Kati.UI.SettingsList.body/2` pins a
  row's second line to `max_lines: 1`, which is what keeps a settings list a
  list, and every one of these three arguments is a paragraph. So the row says
  which mode it is and the note says what choosing it means — and only for the
  one actually chosen, because two unchosen paragraphs are noise.

  `:replace`'s note is the one that has to be here rather than nice to have.
  `Kati.Backup.Restore` refuses `:replace` without a `:safety_sink` and
  `Kati.Backup` refuses it without a `:safety_export_path`, so a screen that let
  the user discover that by being refused would be turning a designed
  precondition into an error message. The file is named before it is needed.
  """
  def mode_note(%{mode: :into_empty}) do
    Kati.Screens.Backup.note(
      "shield",
      "Nothing can be lost in this mode. If any backed-up table holds a single " <>
        "row, Kati refuses, names what it found, and does not touch the database. " <>
        "It is the default because it is the only one with no way to go wrong."
    )
  end

  def mode_note(%{mode: :merge}) do
    Kati.Screens.Backup.note(
      "call_merge",
      "A row whose id is already on this device is skipped. Nothing already here " <>
        "is overwritten, updated or deleted, and Kati reports how many it passed " <>
        "over. A backup restored into the device it came from writes nothing."
    )
  end

  def mode_note(%{mode: :replace}) do
    Kati.Screens.Backup.note(
      "content_copy",
      "Every table is emptied first. Before that happens Kati writes everything " <>
        "on this device to " <>
        Path.basename(Kati.Screens.Backup.safety_path()) <>
        ", inside its own storage where nothing sweeps it away — and if that copy " <>
        "cannot be written, nothing is deleted and nothing has changed."
    )
  end

  @doc "The restore button — drawn only once there is a verified file to restore."
  def restore_action(%{file: %{summary: %{unlocked: true}}} = s) do
    {_icon, title, _sub} = Kati.Screens.Backup.mode_copy(s.mode)

    rows = [
      %{
        icon: "history",
        title: "Restore this backup",
        sub: title,
        control: SettingsList.action_pill("Restore"),
        tap: :restore_now
      }
    ]

    Kati.Screens.Backup.card(rows)
  end

  def restore_action(_s), do: ~MOB"<Spacer size={0} />"

  # ── Notices ─────────────────────────────────────────────────────────────────

  @doc """
  The last thing that happened, in the engine's own words.

  One shape for every outcome, with the glyph carrying the difference: a
  refusal is not painted as a failure, because `:into_empty` refusing is the
  safest thing this screen can do and it should read as a decision.
  """
  def notice_block(nil), do: ~MOB"<Spacer size={0} />"

  def notice_block(notice) do
    tint = Kati.Screens.Backup.tint(notice.tone)

    body =
      [
        Kati.Screens.Backup.notice_headline(notice, tint),
        ~MOB"<Spacer size={10} />",
        Kati.Screens.Backup.paragraph(notice.body),
        Kati.Screens.Backup.notice_meta(notice[:meta]),
        Kati.Screens.Backup.notice_actions(notice[:actions] || [])
      ]

    inner = Kati.Screens.Backup.panel(body)

    ~MOB"""
    <Column fill_width={true}>
      {inner}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  The notice's own headline row, which the file card's does not need: a notice
  is transient and has to be dismissible, so it hangs a close glyph opposite
  its title.
  """
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

  @doc false
  def tint(:ok), do: Palette.green_text()
  def tint(:error), do: Palette.red()
  def tint(:refused), do: Palette.ink()
  def tint(:info), do: Palette.ink_soft()

  @doc false
  def notice_meta(nil), do: ~MOB"<Spacer size={0} />"
  def notice_meta(text), do: Kati.Screens.Backup.mono_line(text)

  @doc false
  def notice_actions([]), do: ~MOB"<Spacer size={0} />"

  def notice_actions(actions) do
    pills =
      actions
      |> Enum.map(fn {label, tag} -> Kati.Screens.Backup.pill(label, tag) end)
      |> Enum.intersperse(~MOB"<Spacer size={9} />")

    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={14} />
      <Row fill_width={true} align="center">
        {pills}
      </Row>
    </Column>
    """
  end

  @doc false
  def pill(label, tag) do
    tap = {self(), tag}
    inner = SettingsList.action_pill(label)

    ~MOB"""
    <Row on_tap={tap}>
      {inner}
    </Row>
    """
  end

  # ── Footnotes ───────────────────────────────────────────────────────────────

  @doc "The three things a user reading this screen after losing a phone needs."
  def footnotes do
    first =
      Kati.Screens.Backup.note(
        "description",
        "A .katibackup is a zip of JSON, never a copy of the database. Open it on any " <>
          "computer and the rows are readable, greppable and repairable by hand. " <>
          "docs/backup-format.md is published so the data outlives the app."
      )

    second =
      Kati.Screens.Backup.note(
        "ios_share",
        "Share sends a copy; it does not make one. Android returns the same answer " <>
          "whether a share finished or the sheet was dismissed, so Kati never reports " <>
          "a share as a backup. Save a file is the one that counts."
      )

    third =
      Kati.Screens.Backup.note(
        "shield",
        "Kati has no server and no account, keeps its database where no file browser " <>
          "can reach it, and tells Android not to back it up. That is why this screen " <>
          "exists: a lost phone is total loss unless a file left it first."
      )

    ~MOB"""
    <Column fill_width={true}>
      {first}
      <Spacer size={11} />
      {second}
      <Spacer size={11} />
      {third}
    </Column>
    """
  end

  # ── Shared pieces ───────────────────────────────────────────────────────────

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

  @doc false
  def paragraph(text) do
    ~MOB"""
    <Text text={text} text_size={12.5} line_height={1.55} text_color={Palette.ink_soft()} />
    """
  end

  @doc false
  def mono_line(text) do
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

  @doc """
  `Kati.UI.card/2` with the lift every other card on this page has.

  `card/2` builds the design's most repeated recipe — the card colour at radius
  20 — and carries no `shadow`. That is right for a panel laid on a card and
  wrong for one laid on the page: `Kati.UI.SettingsList.card/1`, which every
  grouped list on this screen uses, adds `Kati.Theme.shadow_card_soft/0`, and a
  summary panel without it reads as a flat patch beside them.

  Set on the finished node rather than passed in, because `card/2` takes no
  shadow option and giving it one would change a helper whose pixels other
  screens are signed off against. `Kati.Components.MishkaMaskInput` sets a prop
  on a built node the same way and for the same reason.
  """
  def panel(body) do
    card = UI.card(body, padding: 18, background: Palette.card())
    %{card | props: Map.put(card.props, :shadow, Kati.Theme.shadow_card_soft())}
  end

  @doc "A footnote in the outlined frame `Kati.UI.SettingsList` draws for one."
  def note(icon, text), do: SettingsList.note(icon, text)

  @doc """
  A secure text field with its explanation under it, and optionally a button.

  `value` is passed so the field can be cleared from this side after a
  passphrase has been used. `MobTextField` re-keys its `remember` only when the
  string actually differs, so echoing back what was just typed is a no-op and
  the caret does not move.
  """
  def field(value, placeholder, tag, hint, action \\ nil) do
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
      {Kati.Screens.Backup.field_action(action)}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def field_action(nil), do: ~MOB"<Spacer size={0} />"

  def field_action({label, tag}) do
    button = Kati.Screens.Backup.pill(label, tag)

    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={11} />
      <Row fill_width={true} align="center">
        {button}
      </Row>
    </Column>
    """
  end

  # ── Formatting ──────────────────────────────────────────────────────────────

  @doc """
  `1,480`, never `1480`.

  Written here rather than taken from `Cldr.Number` for the reason
  `Kati.Screens.MealsToday` gives: this screen is the English one, its Persian
  mirror does not exist, and the sweep renders it in both locales.
  """
  @spec group(integer()) :: String.t()
  def group(number) when is_integer(number) do
    number
    |> Integer.to_string()
    |> String.reverse()
    |> String.replace(~r/(\d{3})(?=\d)/, "\\1,")
    |> String.reverse()
  end

  @doc """
  A backup's timestamp, in the device's zone rather than in UTC.

  The manifest stores UTC — the format is the same everywhere the file goes —
  and a user reads "made at 02:14" against the clock they were holding, so the
  conversion belongs at the point of display and nowhere earlier.
  """
  @spec stamp(DateTime.t() | nil) :: String.t()
  def stamp(nil), do: "at an unrecorded time"

  def stamp(%DateTime{} = at) do
    local = Kati.Time.in_zone(at, Kati.Time.device_zone())
    month = Kati.Time.month_name(local.month)

    "#{local.day} #{month} #{local.year}, #{pad(local.hour)}:#{pad(local.minute)}"
  end

  defp pad(n), do: n |> Integer.to_string() |> String.pad_leading(2, "0")

  # ── Taps ────────────────────────────────────────────────────────────────────

  @impl true
  def handle_tap(tag, socket) do
    case tag do
      :count_records -> {:noreply, Kati.Screens.Backup.count(socket)}
      :toggle_encrypt -> {:noreply, Kati.Screens.Backup.toggle_encrypt(socket)}
      :save_file -> {:noreply, Kati.Screens.Backup.hand_off(:save, socket)}
      :share_file -> {:noreply, Kati.Screens.Backup.hand_off(:share, socket)}
      :choose_file -> {:noreply, Kati.Screens.Backup.choose(socket)}
      :forget_file -> {:noreply, Kati.Screens.Backup.forget(socket)}
      :unlock_file -> {:noreply, Kati.Screens.Backup.unlock(socket)}
      :restore_now -> {:noreply, Kati.Screens.Backup.restore(socket)}
      :save_safety -> {:noreply, Kati.Screens.Backup.save_safety(socket)}
      :dismiss_notice -> {:noreply, Kati.Screens.Backup.put(socket, :notice, nil)}
      _other -> {:noreply, Kati.Screens.Backup.choose_mode(socket, tag)}
    end
  end

  @doc """
  A mode tag sets the mode; anything else leaves the screen alone.

  The catch-all is why this is a named function rather than a clause: the tap
  sweep's `no new dead-looking taps` cannot see through a `_tag ->` arm, so the
  arm has to be the *only* thing behind it and has to be readable as such.
  """
  def choose_mode(socket, tag) do
    case Kati.Screens.Backup.mode_for(tag) do
      nil -> socket
      mode -> Kati.Screens.Backup.put(socket, :mode, mode)
    end
  end

  @doc false
  def toggle_encrypt(socket) do
    s = socket.assigns.backup
    Mob.Socket.assign(socket, :backup, %{s | encrypt?: not s.encrypt?})
  end

  @doc """
  Read every table and total it — `Kati.Backup.export/0`'s own manifest, not a
  cheaper count taken from somewhere else.

  A count from a different query could disagree with the file, and a screen that
  printed one number while the file held another would be worse than a screen
  with no number at all.
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

    Kati.Screens.Backup.put(socket, :preview, preview)
  end

  @doc """
  Stage an export and hand it to the system.

  An empty passphrase is refused **here**, before the export runs: the envelope
  refuses it too, but only after every table has been read and serialised, and
  making the user wait for a file to be built before being told the field is
  empty is a worse answer than the same sentence immediately.
  """
  def hand_off(call, socket) do
    s = socket.assigns.backup

    cond do
      s.encrypt? and String.trim(s.passphrase) == "" ->
        Kati.Screens.Backup.put(socket, :notice, %{
          tone: :refused,
          icon: "lock",
          title: "There is no passphrase to seal it with",
          body:
            "The passphrase switch is on and the field is empty. Kati will not write a " <>
              "file that claims to be encrypted and is not, and it will not quietly " <>
              "write one in the clear either. Nothing has been exported."
        })

      true ->
        hand_off_now(call, socket, s)
    end
  end

  defp hand_off_now(call, socket, s) do
    opts = Kati.Screens.Backup.passphrase_opts(s.encrypt?, s.passphrase)

    result =
      case call do
        :save -> Transport.save(opts)
        :share -> Transport.share(opts)
      end

    Kati.Screens.Backup.put(socket, :notice, Kati.Screens.Backup.hand_off_notice(call, result))
  end

  @doc false
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
          "dismissed, so Kati cannot tell you this arrived anywhere. Use Save a file " <>
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

  @doc """
  Open the system document picker.

  Rescued for the reason `Kati.Native.Bridge` gives about the whole native
  boundary: Kati runs one screen process, `Mob.Files.pick/2` reaches
  `:mob_nif.files_pick/1` directly, and an unbound NIF raising here would take
  the screen down rather than fail a button. A platform with no picker is told
  as much.
  """
  def choose(socket) do
    Files.pick(socket, types: ["katibackup"])
  rescue
    _exception ->
      Kati.Screens.Backup.put(socket, :notice, %{
        tone: :info,
        icon: "info",
        title: "This build cannot open a file picker",
        body:
          "The system document picker is not bound here, so there is no way to hand " <>
            "Kati a file to restore. Nothing on the device has changed."
      })
  end

  @doc false
  def forget(socket) do
    s = socket.assigns.backup
    Mob.Socket.assign(socket, :backup, %{s | file: nil, unlock: "", notice: nil})
  end

  @doc """
  Re-read a locked file with the passphrase the user typed.

  `inspect_file/2` again rather than a decrypt-and-remember: the answer a screen
  shows must come from the same verification a restore runs, and running it
  twice is the price of that guarantee.
  """
  def unlock(%{assigns: %{backup: %{file: nil}}} = socket), do: socket

  def unlock(socket) do
    s = socket.assigns.backup

    case Kati.Backup.inspect_file(s.file.path, passphrase: s.unlock) do
      {:ok, summary} ->
        file = %{s.file | summary: summary}
        Mob.Socket.assign(socket, :backup, %{s | file: file, notice: nil})

      {:error, %Error{} = error} ->
        Kati.Screens.Backup.put(socket, :notice, Kati.Screens.Backup.inspect_notice(error))
    end
  end

  @doc """
  Verify the file and write it, in the mode the user chose.

  Every refusal below is the engine's, rendered word for word. `:not_empty` in
  particular is offered the other two modes rather than an apology: it is the
  default precisely because it is the only mode that cannot lose anything.
  """
  def restore(%{assigns: %{backup: %{file: nil}}} = socket), do: socket

  def restore(socket) do
    s = socket.assigns.backup
    opts = Kati.Screens.Backup.restore_opts(s)

    case Kati.Backup.restore_file(s.file.path, opts) do
      {:ok, report} ->
        Mob.Socket.assign(socket, :backup, %{
          s
          | notice: Kati.Screens.Backup.restored_notice(report),
            preview: nil
        })

      {:error, %Error{} = error} ->
        Kati.Screens.Backup.put(socket, :notice, Kati.Screens.Backup.restore_notice(error))
    end
  end

  @doc false
  def restore_opts(s) do
    base = [mode: s.mode] ++ Kati.Screens.Backup.passphrase_opts(s.unlock != "", s.unlock)

    if s.mode == :replace do
      base ++ [safety_export_path: Kati.Screens.Backup.safety_path()]
    else
      base
    end
  end

  @doc """
  Where the pre-replace copy of the current data goes.

  **Not** `Kati.Backup.Transport.staging_dir/1`. Staging is swept hourly by
  `Transport.sweep/1`, which is right for a file the user is in the middle of
  saving and catastrophic for this one: after a `:replace`, this file is the
  only remaining copy of everything that was on the device, and an hour later it
  would be gone.
  """
  @spec safety_path() :: Path.t()
  def safety_path do
    name = "kati-before-restore-" <> Date.to_iso8601(Kati.Time.today()) <> ".katibackup"
    Path.join(Mob.data_dir("backup_safety"), name)
  end

  @doc false
  def restored_notice(report) do
    inserted = Kati.Screens.Backup.group(report.total_inserted)
    skipped = report.total_skipped

    body =
      case {report.mode, skipped} do
        {:merge, 0} ->
          inserted <> " records went in. Nothing that was already here was touched."

        {:merge, n} ->
          inserted <>
            " records went in and " <>
            Kati.Screens.Backup.group(n) <>
            " were skipped because their rows were already on this device. " <>
            "Nothing existing was overwritten."

        {:replace, _n} ->
          inserted <>
            " records went in. Everything that was here first was written out to " <>
            "a file before any of it was deleted."

        {_mode, _n} ->
          inserted <> " records went in, into tables that were empty."
      end

    %{
      tone: :ok,
      icon: "check_circle",
      title: "Restored",
      body: body,
      meta: report.safety_export,
      actions: Kati.Screens.Backup.restored_actions(report.safety_export)
    }
  end

  @doc false
  def restored_actions(nil), do: []
  def restored_actions(_path), do: [{"Save that copy", :save_safety}]

  @doc "Hand the pre-replace copy to the system, so it does not only live in the app."
  def save_safety(socket) do
    path = Kati.Screens.Backup.safety_path()

    case Files.save_as(path, name: Path.basename(path)) do
      :ok ->
        Kati.Screens.Backup.put(socket, :notice, %{
          tone: :info,
          icon: "upload",
          title: "Choose where to keep the old data",
          body:
            "This is everything that was on the device before the restore. Kati keeps " <>
              "its own copy either way; this is the one you can hold.",
          meta: path
        })

      {:error, _reason} ->
        Kati.Screens.Backup.put(socket, :notice, %{
          tone: :info,
          icon: "info",
          title: "Kati cannot hand that file to the system here",
          body: "The copy of your old data is written and waiting on the device.",
          meta: path
        })
    end
  end

  @doc false
  def restore_notice(%Error{reason: :not_empty} = error) do
    %{
      tone: :refused,
      icon: "shield",
      title: "Nothing has been changed",
      body: error.message,
      actions: [{"Merge instead", :mode_merge}, {"Replace instead", :mode_replace}]
    }
  end

  def restore_notice(%Error{reason: :safety_export_required} = error) do
    %{
      tone: :refused,
      icon: "shield",
      title: "Nothing has been deleted",
      body: error.message,
      meta: Kati.Screens.Backup.safety_path()
    }
  end

  def restore_notice(%Error{reason: reason} = error)
      when reason in [:bad_passphrase, :passphrase_required] do
    Kati.Screens.Backup.inspect_notice(error)
  end

  def restore_notice(%Error{} = error) do
    %{tone: :error, icon: "error", title: "This backup was not written", body: error.message}
  end

  @doc false
  def inspect_notice(%Error{reason: :bad_passphrase} = error) do
    %{tone: :error, icon: "lock", title: "That passphrase did not open it", body: error.message}
  end

  def inspect_notice(%Error{reason: :passphrase_required} = error) do
    %{tone: :refused, icon: "lock", title: "This backup is encrypted", body: error.message}
  end

  def inspect_notice(%Error{reason: :not_a_backup} = error) do
    %{tone: :refused, icon: "block", title: "That is not a Kati backup", body: error.message}
  end

  def inspect_notice(%Error{} = error) do
    %{tone: :error, icon: "error", title: "Kati could not read that file", body: error.message}
  end

  # ── Messages from the device ────────────────────────────────────────────────

  # Everything that is not a tap.
  #
  # One clause for the text fields and one that asks `event/1` whether a message
  # is a file-transport answer, with `super/2` under it for the shell's own
  # tags. The macro's `handle_info/2` clauses are `defoverridable`, so an
  # override replaces the WHOLE set — `super/2` is how `:back`, `{:kati, …}` and
  # every other tag keep working, and dropping it would take the back pill with
  # it.
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

  @doc """
  A device message as a value, or `:ignore`.

  Two doors report here — `Mob.Files.pick/2` answers `{:files, …}` and
  `Kati.Native.Files`'s save/share intents answer `{:kati_files, …}` — so both
  are read in one place. `:ignore` is what keeps an unrelated message from
  matching a transport clause by accident; Kati runs one screen process and it
  sees everything sent to it.
  """
  @spec event(term()) :: term()
  def event({:files, :picked, items}) when is_list(items), do: {:picked, items}
  def event({:files, :cancelled}), do: :picker_cancelled
  def event(message), do: Files.decode(message)

  @doc false
  def typed(socket, :export_passphrase, value),
    do: Kati.Screens.Backup.put(socket, :passphrase, value)

  def typed(socket, :restore_passphrase, value),
    do: Kati.Screens.Backup.put(socket, :unlock, value)

  def typed(socket, _tag, _value), do: socket

  @doc """
  What a device message does to the screen.

  A cancelled picker and a cancelled Save As… are **not** errors — a user who
  backs out of a folder chooser has done an ordinary thing — so both get an
  informational notice that says nothing has changed rather than a failure.
  """
  def apply_event({:picked, items}, socket) do
    case Transport.accept(items) do
      {:ok, item} ->
        Kati.Screens.Backup.inspect_picked(socket, item)

      {:error, %Error{} = error} ->
        Kati.Screens.Backup.put(socket, :notice, Kati.Screens.Backup.inspect_notice(error))
    end
  end

  def apply_event(:picker_cancelled, socket) do
    Kati.Screens.Backup.put(socket, :notice, %{
      tone: :info,
      icon: "info",
      title: "No file was chosen",
      body: "Nothing on this device has changed."
    })
  end

  def apply_event(:cancelled, socket) do
    Kati.Screens.Backup.put(socket, :notice, %{
      tone: :info,
      icon: "info",
      title: "The backup was not saved",
      body:
        "You closed the folder chooser, so nothing was written outside Kati. The " <>
          "export is still staged on the device and saving again costs nothing."
    })
  end

  def apply_event({:saved, item}, socket) do
    # The one place in the app that stamps the backup ledger, and the reason
    # screen 24's Export row can say anything but *Never backed up*.
    # `Kati.Screens.Settings`' moduledoc names this exact branch as the only
    # caller: `{:saved, …}` is `ACTION_CREATE_DOCUMENT` reporting that the bytes
    # reached the `content://` URI the user picked, which is the app's only
    # signal that a copy exists somewhere a user can get it back from.
    # `{:shared, …}` and `{:dismissed, …}` below deliberately do not stamp it —
    # Android answers a chooser with `RESULT_CANCELED` whether the send
    # completed or the sheet was dismissed, so a date written there would
    # promise a backup to someone who has none.
    :ok = Kati.Screens.Settings.record_backup()

    Kati.Screens.Backup.put(socket, :notice, %{
      tone: :ok,
      icon: "check_circle",
      title: "Saved",
      body:
        Kati.Screens.Backup.group(item.bytes) <>
          " bytes were written where you chose. That file is the backup — Kati does " <>
          "not need to be installed for it to be readable.",
      meta: item.name
    })
  end

  def apply_event({:shared, item}, socket) do
    Kati.Screens.Backup.put(socket, :notice, %{
      tone: :ok,
      icon: "check_circle",
      title: "The receiving app took it",
      body:
        "One of the few apps that report back said it accepted the file. Most do not, " <>
          "which is why a share is never counted as a backup here.",
      meta: item.name
    })
  end

  def apply_event({:dismissed, item}, socket) do
    Kati.Screens.Backup.put(socket, :notice, %{
      tone: :info,
      icon: "info",
      title: "The share sheet closed",
      body:
        "Android does not say whether the file was sent or the sheet was dismissed, " <>
          "so Kati will not claim either. If this was meant to be your backup, use " <>
          "Save a file.",
      meta: item.name
    })
  end

  def apply_event({:error, reason}, socket) do
    Kati.Screens.Backup.put(socket, :notice, %{
      tone: :error,
      icon: "error",
      title: "The system dialog failed",
      body: "Nothing on this device has changed.",
      meta: inspect(reason)
    })
  end

  def apply_event(_other, socket), do: socket

  @doc """
  Ask `inspect_file/1` what a picked file holds, before anything is written.

  An encrypted file answers without the passphrase and the card says so; it does
  not become an error, because "this is encrypted" is a fact about the file and
  not a failure to read it.
  """
  def inspect_picked(socket, item) do
    s = socket.assigns.backup

    case Kati.Backup.inspect_file(item.path) do
      {:ok, summary} ->
        file = %{name: item.name, path: item.path, summary: summary}
        Mob.Socket.assign(socket, :backup, %{s | file: file, unlock: "", notice: nil})

      {:error, %Error{} = error} ->
        Mob.Socket.assign(socket, :backup, %{
          s
          | file: nil,
            notice: Kati.Screens.Backup.inspect_notice(error)
        })
    end
  end

  @doc false
  def put(socket, key, value) do
    Mob.Socket.assign(socket, :backup, Map.put(socket.assigns.backup, key, value))
  end
end
