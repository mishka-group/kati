defmodule Kati.Screens.Restore do
  use Gettext, backend: Kati.Gettext

  @moduledoc """
  Screen 129 — Restore from a backup, pushed under Settings.

  Built to `test/design/reference/129.html`. The board is screen 37's import
  idiom moved onto a device: a file is acknowledged, the write is summarised
  as counts, and nothing is written until the last step.
  `Kati.Screens.PlanImport` is the pattern this file was told to follow,
  because it is the same idiom's second drawing already — screen 37's builders
  reused rather than copied, the frame re-drawn wherever the two designs
  actually differ. This is the idiom's third.

  ## Everything on this page is this device's or the picked file's

  The board is drawn mid-preview, over a file on the designer's desk:
  `kati-backup-2026-08-14.json`, `384 / 28 / 6`, a `Blue Hour` conflict at
  `1 of 6`, and a Replace card threatening `418 titles`. Every one of those is
  a claim about somebody's data, and until 25 September this screen drew all
  of them on every phone, out of a `Kati.Backup.SampleRestore` fixture. None
  of them is drawn now:

    * **The file row** names the picked file, or says no file has been
      chosen — `file_label/1`.
    * **The count row** draws the one figure an opened file answers, or a
      sentence saying nothing has been read — `count_cards/1`, `count_row/1`.
    * **The merge note and the Replace card** read `records_on_device/0` —
      `Kati.Backup.occupied/0`, the engine's own `:into_empty` question — so
      *this device already has data* is only said when it is true and Replace
      names the number of records it would delete, or says there is nothing
      to delete.
    * **The conflict card and its eyebrow are gone.** `Kati.Backup.Restore`
      merges insert-only and skips a row whose id is already here; there is no
      API that hands a screen one collision at a time, and a card naming a
      film the reader may never have logged, with ratings nobody gave, was the
      board's example standing in for the reader's library. The day the
      engine can answer a collision, the card comes back reading it.

  That is the reason `load/1` reads the store at all: two sentences on this
  page are about the device, and a device's state is not the drawing's.

  ## This screen owns the restore half of #25, and the split is the design's

  Until 24 August there was one screen for both halves. `Kati.Screens.Backup`
  was written with no drawing to work from — issue #64's answer to *`Kati.Backup`
  is finished and nothing calls it* — so it grew until it held everything the
  engine could do: an export, a passphrase, a file picker, `inspect_file/2`,
  three collision modes and a restore. Nothing constrained its shape because
  nothing had drawn it.

  #25's artboards landed and drew **two** screens, not one: 128 *Back up
  everything* and 129 *Restore from a backup*. That is the reason for the
  split, and it is the whole reason — not file length, not a module boundary
  someone preferred. A backup and a restore are two errands a person is on at
  two different moments, and the boards say so by being two boards. So the
  export half stayed on 128 and **every restore behaviour moved here**:
  `choose/1` and the `{:files, …}` door, `Kati.Backup.inspect_file/2`, the
  passphrase that opens a sealed file, `:mode` and its three values,
  `restore_opts/1`, `safety_path/0`, and every notice about a picked file.
  `Kati.Screens.Backup` keeps exactly one thing that touches a file coming
  *in*: nothing. It writes; this reads.

  ### What that behaviour is allowed to draw

  The board draws one state — a file already picked, its counts known — and
  this screen draws that frame's copy at rest: the headings, the scan card,
  the merge and replace paths. The board's figures are not copy and are
  retired in `Kati.DesignLiterals.retired_lines/0` with this reason.
  Everything the moved behaviour needs beyond it is drawn **only once the
  resting frame has been left**: the notice card appears when something has
  happened, the file card when `inspect_file/2` has answered, the passphrase
  field when the file it belongs to is sealed, the mode note when a mode other
  than the default has been chosen. At rest every one of them is a
  zero-height spacer.

  That is not a loophole. `130.html` — *Backup & restore — eight states* —
  draws these states as a board of their own: *Restoring*, *This file is from
  a newer Kati*, *Couldn't read this file*, *Everything came back*. The design
  has states; 129 is the resting one, and a screen that could not enter the
  others would be a picture of a restore rather than a restore.

  ## What is literally 37's or PlanImport's, and what is re-drawn

  Reused rather than copied, because both drawings put the identical node on
  screen:

    * `Kati.Screens.PlanImport.count_card/1` — the DM Mono figure over its
      letter-spaced caps label, at weight 500 and 9.5pt. This board's count is
      set in the same face PlanImport's are, for the same reason: it is read
      off a document, not announced.
    * `Kati.Screens.Import.outcome_gap/0` — the 10pt between count cards,
      unchanged between all three drawings.

  Everything else is re-drawn, because this board's own rhythm is tighter
  than either of its ancestors': 11pt after the file card and the count row
  rather than 22, 24pt after the scan card and the note rather than 22. Those are this drawing's own numbers, kept rather than rounded to
  match a sibling screen that draws a different gap on purpose.

  ## Two things the brief asked to be decided, and where they landed

  The caption on `129.html` names them directly:

    * **The QR path carries `settings and plans only`**, said on its own
      card rather than folded into a caveat — a QR payload is small and a
      library is not, so `scan_card/0`'s second line states the limit before
      anyone taps the tile expecting the whole archive.
    * **Merge and Replace are never two buttons of equal weight.** Merge is
      the single ink pill at the bottom of the safe path; Replace sits below
      a full-width rule, under its own `Or start clean` eyebrow, as an
      outlined red row — the destructive action is reachable, never beside
      the recommended one.

  ## The three modes are a choice, and this board draws two of them

  `Kati.Backup.Restore` has three collision modes and `:into_empty` is the
  default: it **refuses** when anything is stored, naming what it found. All
  three still live here — `modes/0`, `mode_tag/1`, `mode_copy/1` — because
  the engine has three and a screen that knew about two would be lying about
  what a restore can do. What changed is how they are *chosen*.

  The old screen drew them as a card of three equal rows. This board rejects
  exactly that: *"merge takes the single ink button while replace sits below
  a full-width rule as an outlined red row, so they are never two buttons of
  equal weight."* Three equal rows is the shape the drawing refused. So:

    * **The ink button commits**, in whatever mode is currently chosen, and
      the chosen mode starts as `:into_empty` — the only one that cannot lose
      anything. On a device with data that first tap **refuses**, names what
      it found in the engine's own sentence, and offers `Merge instead` and
      `Replace instead` as pills on the notice. The board's own copy says the
      file *is* merged into a device that already has data; the refusal is
      how the person says yes to that, and it costs one tap and no data.
    * **`Replace everything…` selects, it does not commit.** The ellipsis is
      the board's own, and it means what an ellipsis has always meant: more
      is coming. Tapping it sets `:replace` and draws `mode_note/1`, which
      names the safety export Kati writes first and states that if that write
      fails, nothing is deleted. `Kati.Backup.Restore` refuses `:replace`
      without a `:safety_sink` and `Kati.Backup` refuses it without a
      `:safety_export_path`, so a screen that let a person discover that by
      being refused would be turning a designed precondition into an error
      message. The file is named before it is needed.

  That copy does **not** go in `Kati.Backup.Transport.staging_dir/1`. Staging
  is swept hourly by `Transport.sweep/1`, and the safety export is the only
  remaining copy of data the user has just replaced — an hour later it would
  be gone. `safety_path/0` names a directory nothing sweeps, and the notice
  carries that path so the copy can be handed to the system afterwards.

  ## `inspect_file/2`'s answer is what the file card draws, and nothing else

  A picked file goes through `Kati.Backup.Transport.accept/1` — which refuses
  by extension, because SAF cannot filter on one — and then through
  `Kati.Backup.inspect_file/2`, which opens and verifies the archive **without
  touching the database**. Its answer is what `file_card/1` draws: when it was
  made, how many records across how many tables, which app version wrote it,
  the columns the format left out on purpose, and whether it is encrypted.
  That function exists precisely so a screen can never print counts a restore
  would then reject, so this screen never prints a count it has not read out
  of the file itself.

  The one builder this file borrows back from the export screen is
  `Kati.Screens.Backup.dropped_line/1`. `dropped_columns` is one manifest key
  and one fact — the columns the format leaves out on purpose — and it is
  worth saying at both ends of the same file: on the way out, so nobody thinks
  the backup is a byte copy, and here, so nobody is surprised by what did not
  come back. Two copies of that sentence is how the two ends would quietly
  stop agreeing.

  An encrypted file answers without the passphrase — `encrypted: true`,
  `unlocked: false`, the envelope's cipher and iterations, `nil` for everything
  inside the ciphertext. The card says exactly that and offers the passphrase
  field, because "this is encrypted" and "this is unreadable" are different
  sentences and a person holding their only backup needs the first one.

  ## The count row is a reading or a sentence, never three numbers

  The board's `384 / 28 / 6` is screen 37's pre-write summary — `New`,
  `Merged`, `Conflicts` — and Kati has no dry run that could produce it:
  `Kati.Backup.Restore` is insert-only in `:merge` and reports what it skipped
  **after** it has run. What this screen *can* read out of a real file is one
  number — how many records are in it — so once one is open the row is that
  single figure, which is the move `135.html` already makes for the same
  reason: *"on an empty device 37's three-count summary is dishonest — there
  is nothing to merge or conflict — so it collapses to a single figure and
  says so in words."* With no file read the row is a sentence saying so.

  `merge_button/1` is handed `new_count/1`'s reading of whatever the count
  row drew rather than a figure typed a second time — the same argument
  `PlanImport.title/1` makes for building its `STEP 3 OF 4` kicker out of the
  step meter's own numbers: two chances to write one figure is how a button
  and a card quietly stop agreeing. With nothing read, the button names no
  number at all.

  ## A wrong passphrase gets the engine's sentence, unedited

  `Kati.Backup.Envelope` answers a failed unseal with: *that passphrase does not
  open this backup; either it is not the one it was made with or the file has
  been altered since — Kati cannot tell those apart, and it will not guess.*
  Every failure notice here renders `%Kati.Backup.Error{}.message` verbatim,
  so the screen cannot drift from what the engine actually decided, and cannot
  soften a refusal into a shrug.

  ## The safety copy does not stamp the backup ledger

  `save_safety/1` hands the pre-replace copy to the system, and the system
  answers `{:kati_files, :saved, …}` — the identical message a completed
  export answers with. `apply_event/2` below reports it and stops there.
  `Kati.Screens.Settings`'s moduledoc names `Kati.Screens.Backup.apply_event/2`
  as the **only** writer of `Last backup`, and `Kati.SettingsBackupLineTest`
  pins it; a safety dump written on the way into a replace is not a backup
  the person chose to make, and a date written here would promise one to
  someone who has none.

  ## Three numbers this board draws that no palette token quite reaches

  Each is kept as this screen's own literal rather than promoted to
  `Kati.Theme.Palette`, and each is recorded here so the gap is a decision
  and not an oversight:

    * **The rule under Merge is `rgba(26,25,23,.12)`.** The nearest token is
      `Palette.hairline_strong/0` at 10%, two points light — `Palette.border_soft/0`
      at 14% overshoots by the same margin the other way, and this rule plays
      `hairline_strong/0`'s own role: a thematic break between two sections
      (screen 09's onboarding draws the identical shape at `.10`), not a row
      hairline. Same job, adjacent value, so the named token wins over a raw
      int that could not follow the theme into dark mode.
    * **The scan tile's shadow is `0 6px 16px -8px rgba(120,80,30,.45)`.**
      `Kati.Theme.shadow_hero/0` and `Kati.Screens.PlanShare.qr_plate/1`'s own
      literal both already carry this exact warm brown — `#78 50 1E`, RGB
      `120,80,30` — at 50% rather than 45%. Five points of alpha was not worth
      a fourth near-duplicate shadow string, so `scan_tile/0` writes its own
      `"0 6 16 -8 #7378501E"` at the drawing's own 45.
    * **The outlined Replace border is `rgba(180,85,60,.4)`.** `Palette.red_ring/0`
      — "the ring around a destructive control", the exact right *meaning* —
      is 30%, and nothing else in the red family reaches 40%. `replace_button/0`
      keeps `Palette.red_ring_strong/0` rather than borrow a token whose own
      name promises the wrong strength.

  ## The scan tile is a glyph, not a code

  `scan_tile/0` draws the same 7-module-row idiom `Kati.Screens.PlanShare.qr_plate/1`
  draws — a `Column` of `Row`s of 1px-radius squares, gapped and intersepersed
  the same way — but is not that function reused, for two reasons neither of
  which is geometry:

    * **It does not follow `:light`.** `PlanShare`'s plate is pinned because
      it is meant to be scanned, and a scanned code that inverted with the
      theme would stop decoding. This tile is 74pt with modules under 6pt —
      unreadable by any scanner regardless of theme — so it is *iconography*
      for "this action involves a QR", and iconography follows the mode like
      every other glyph on the screen. `Palette.card/0` and `Palette.ink/0`,
      not `Palette.card(:light)` and `Palette.ink(:light)`.
    * **The module size is this drawing's own arithmetic, not `PlanShare`'s.**
      7 modules of `5.71pt` with `2pt` gaps is `51.97pt`, centred inside a
      74pt tile — `(52 - 6·2) / 7`, the board's own `width:52px` divided the
      way its `gap:2px` demands, kept to two decimals rather than rounded to
      a cleaner number that would drift the pattern off-centre.

  The 49-cell pattern in `qr_pattern/0` is read off the drawing cell for cell,
  not invented — the board draws no real payload here, only the shape of one.

  ## The note that cannot be `Kati.UI.SettingsList.note/2`

  `merge_note/1` draws the same dashed-read-as-solid frame `note/2` draws —
  `Kati.Components.MishkaPill` at `border_color: Palette.border/0`, the same
  16% this board's own `rgba(26,25,23,.16)` already is — but is not a call to
  it, because three of this board's numbers are not `note/2`'s: `padding: 15`
  where that helper writes 16, an 17pt glyph where it writes 18, and a
  `1.65` line height where its own `note_text/1` is pinned to `1.55`. On top
  of that, the sentence needs a bold word — *merged* — mid-paragraph, which
  `note/2`'s single-string `text` argument cannot carry at all. `merge_note/1`
  therefore builds the same component with this board's own five numbers and
  a `Kati.UI.rich_text/1` paragraph in place of the plain string, which is the
  reason `PlanImport.footer/0` exists as a hand-built card and not a call to
  `note/2` either: a paragraph with an emphasis inside it needs the one node
  that can wrap, and `rich_text/1`'s own doc records that the emphasis is
  therefore rendered plain rather than dropped or orphaned.

  ## Nothing here is persisted

  `Kati.Screens.Pushed` expands to `use Mob.Screen` with no `:vsn` and no
  `persist: true`, so `Mob.Screen.__mob_persist__/0` is false and this screen's
  assigns are never written to `mob_screen_states`. That matters more here than
  anywhere else in the app: the assigns hold a typed passphrase, and a screen
  that dumped it to SQLite would defeat the envelope it was helping to open.

  No dock, so the frame's bottom inset is 40 rather than 132.
  """
  use Kati.Screens.Pushed, back: "Settings"

  alias Kati.Backup.Error
  alias Kati.Backup.Transport
  alias Kati.Components.MishkaPill
  alias Kati.Components.MishkaSeparator
  alias Kati.Native.Files
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  @modes [:into_empty, :merge, :replace]

  @impl true
  def load(socket), do: Mob.Socket.assign(socket, :restore, Kati.Screens.Restore.blank())

  @doc """
  The screen at rest: no file, no notice, the safest mode, and how much is on
  this device right now.

  `here` is the one reading taken at mount — `records_on_device/0`, the count
  `Kati.Backup.Restore`'s own `:into_empty` check refuses over — because two
  things on this page are claims about the device rather than about a file:
  whether a restore would merge into something, and what Replace would delete.
  Every fact about a backup is read out of that backup when it is picked, and
  never before, so a fresh install renders no file, no count and no conflict.
  """
  @spec blank() :: map()
  def blank do
    %{
      file: nil,
      unlock: "",
      mode: :into_empty,
      notice: nil,
      here: Kati.Screens.Restore.records_on_device()
    }
  end

  @doc """
  How many records this device holds across every backed-up table.

  The sum of `Kati.Backup.occupied/0`, which is the engine's own answer to
  *is anything here?* — so the merge note and the Replace card can never say
  something different from what the restore then does. `0` on a fresh install.
  """
  @spec records_on_device() :: non_neg_integer()
  def records_on_device do
    Kati.Backup.occupied() |> Enum.map(&elem(&1, 1)) |> Enum.sum()
  end

  @doc "Every collision mode, in the order safest first — the engine's own three."
  @spec modes() :: [atom()]
  def modes, do: @modes

  @doc "The page, in the order the board lays it out."
  @spec content(map()) :: term()
  def content(assigns) do
    job = assigns.restore
    cards = Kati.Screens.Restore.count_cards(job)

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
        {Kati.Screens.Restore.title()}
        {Kati.Screens.Restore.notice_block(job.notice)}
        {UI.eyebrow(gettext("Choose a file"))}
        {Kati.Screens.Restore.file_row(Kati.Screens.Restore.file_label(job))}
        {Kati.Screens.Restore.file_card(job.file)}
        {Kati.Screens.Restore.unlock_field(job)}
        {Kati.Screens.Restore.scan_card()}
        {UI.eyebrow(gettext("What will happen"))}
        {Kati.Screens.Restore.count_row(cards)}
        {Kati.Screens.Restore.merge_note(job.here)}
        {Kati.Screens.Restore.mode_note(job)}
        {Kati.Screens.Restore.merge_button(Kati.Screens.Restore.new_count(cards))}
        {Kati.Screens.Restore.divider()}
        {SettingsList.eyebrow_muted(gettext("Or start clean"))}
        {Kati.Screens.Restore.replace_card(job.here)}
        <Spacer size={14} />
        {Kati.Screens.Restore.replace_button()}
      </Column>
    </Scroll>
    """
  end

  # ── The headline ────────────────────────────────────────────────────────────

  @doc """
  The 28pt headline and the mono warning under it.

  Not `Kati.UI.SettingsList.title/3`: that helper's second line is a
  subtitle naming what is open, spaced 5pt below the headline at 11pt. This
  line is a warning naming what has not happened yet, and the board sets it
  6pt below the headline at 11.5pt — one size up, because the sentence it
  carries is doing more work than a subtitle ever does.
  """
  @spec title() :: term()
  def title do
    # `Kati.Locale.tracking/1` rather than the raw `-0.03`, and `max_lines={1}`
    # where the drawing needed neither. Tracking is a Latin tightening: Arabic
    # script JOINS, and a fraction of an em inserted between two letters of
    # بازگردانی breaks the joins and sets the word as loose glyphs.
    # `Kati.UI.SettingsList.title_text/1` — the helper this function is
    # deliberately not, for the reason the doc above gives — already made the
    # identical call for every other 28pt heading in Settings, and
    # `Kati.Screens.RestoreFirstRun.headline_line/1` added the `max_lines` for
    # the same reason this one does: at `max_font_scale={1.6}` a heading that
    # wraps pushes the file row off the fold, and this is the one board where
    # the row under the fold is the whole errand.
    ~MOB"""
    <Column fill_width={true}>
      <Text
        text={gettext("Restore from a backup")}
        text_size={28}
        max_font_scale={1.6}
        font_weight="bold"
        letter_spacing={Kati.Locale.tracking(-0.03)}
        text_color={:on_surface}
        max_lines={1}
      />
      <Spacer size={6} />
      <Text
        text={gettext("NOTHING IS WRITTEN UNTIL THE LAST STEP")}
        font_family={Kati.Locale.mono_face()}
        text_size={11.5}
        text_color={Palette.muted()}
        max_lines={1}
      />
      <Spacer size={20} />
    </Column>
    """
  end

  # ── Choose a file ────────────────────────────────────────────────────────────

  @doc """
  The file row's second line: the picked file's own name, or a plain
  statement that nothing has been picked.

  `129.html` is drawn with a file already chosen and names it
  `kati-backup-2026-08-14.json`. That is a file on the designer's desk, not on
  this device, so the row never shows it: until a real file arrives the row
  says there is none.

  The NAME is not copy and is not translated — it is what the file is called,
  and a reader comparing this row against their file manager has to see the
  same word — but it is a Latin run on a right-to-left row, and
  `kati-backup-2026-09-12.katibackup` is hyphens and dots between digit
  groups: all bidi NEUTRALS, which resolve against the paragraph rather than
  against the run and put the extension at the wrong end of the name.
  `Kati.Locale.ltr/1` isolates it, exactly as
  `Kati.Screens.Backup.dropped_line/1` isolates a column path. The sentence for
  no file is copy and takes no isolate.
  """
  @spec file_label(map()) :: String.t()
  def file_label(%{file: %{name: name}}) when is_binary(name), do: Kati.Locale.ltr(name)
  def file_label(_job), do: gettext("No file chosen yet")

  @doc """
  The single-row card offering the picked file.

  `rule: false` because it is the only row a card this small holds — the last
  row in a `Kati.UI.SettingsList` card never draws the hairline under it, and
  here that is also the first and only one. `SettingsList.chevron/0` already
  asks `Kati.Locale.forward_chevron/0`, so the row that OPENS the picker points
  the way the reader reads.
  """
  @spec file_row(String.t()) :: term()
  def file_row(label) do
    row =
      SettingsList.row(
        SettingsList.icon_tile("upload_file"),
        SettingsList.body(gettext("Pick a file"), label),
        SettingsList.chevron(),
        rule: false,
        on_tap: {self(), :choose_file}
      )

    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.card([row])}
      <Spacer size={11} />
    </Column>
    """
  end

  @doc "The cream card offering a QR handoff from another phone."
  @spec scan_card() :: term()
  def scan_card do
    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Palette.cream()}
        corner_radius={20}
        padding={16}
        align="center"
      >
        {Kati.Screens.Restore.scan_tile()}
        <Spacer size={14} />
        <Column weight={1.0}>
          <Text
            text={gettext("Scan from another phone")}
            text_size={13.5}
            font_weight="bold"
            text_color={Palette.cream_ink()}
            max_lines={1}
          />
          <Spacer size={5} />
          {Kati.Screens.Restore.scan_sub()}
        </Column>
      </Row>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc "The `Carries settings and plans only …` line, with its one bold run."
  @spec scan_sub() :: term()
  def scan_sub do
    body = [
      text_size: 11.5,
      line_height: Kati.Locale.leading(1.6),
      text_color: Palette.cream_sub()
    ]

    emphasis = [
      text_size: 11.5,
      line_height: Kati.Locale.leading(1.6),
      text_color: Palette.cream_ink(),
      font_weight: "semibold"
    ]

    UI.rich_text([
      {gettext("Carries "), body},
      {gettext("settings and plans only"), emphasis},
      {gettext(" — a QR payload is small, and a library is not."), body}
    ])
  end

  @doc "The 74pt QR-shaped tile — iconography, not a scannable code. See the moduledoc."
  @spec scan_tile() :: term()
  def scan_tile do
    rows =
      Kati.Screens.Restore.qr_pattern()
      |> Enum.map(fn row -> Kati.Screens.Restore.qr_row(row) end)
      |> Enum.intersperse(Kati.Screens.Restore.qr_gap())

    ~MOB"""
    <Box
      width={74}
      height={74}
      corner_radius={14}
      background={Palette.card()}
      shadow="0 6 16 -8 #7378501E"
      align="center"
    >
      <Column>
        {rows}
      </Column>
    </Box>
    """
  end

  @doc "The 7x7 pattern read off the board, one row per string, `1` for a filled cell."
  @spec qr_pattern() :: [String.t()]
  def qr_pattern do
    [
      "0010111",
      "1001001",
      "1110010",
      "1100001",
      "1011001",
      "1001100",
      "1100110"
    ]
  end

  @doc false
  def qr_gap, do: ~MOB"<Spacer size={2} />"

  @doc false
  def qr_row(row) do
    ~MOB"""
    <Row>
      {row
       |> String.graphemes()
       |> Enum.map(fn cell -> Kati.Screens.Restore.qr_module(cell) end)
       |> Enum.intersperse(Kati.Screens.Restore.qr_gap())}
    </Row>
    """
  end

  @doc false
  def qr_module("1"),
    do: ~MOB"<Box width={5.71} height={5.71} corner_radius={1} background={Palette.ink()} />"

  def qr_module(_off), do: ~MOB"<Box width={5.71} height={5.71} />"

  # ── What the picked file actually holds ─────────────────────────────────────

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
        Kati.Screens.Restore.file_headline(summary),
        ~MOB"<Spacer size={10} />",
        Kati.Screens.Restore.file_meta(file, summary)
      ] ++ Kati.Screens.Restore.file_detail(summary)

    inner = Kati.Screens.Restore.panel(body)

    ~MOB"""
    <Column fill_width={true}>
      {inner}
      <Spacer size={11} />
    </Column>
    """
  end

  # Two INTERPOLATIONS rather than a four-part `<>` chain. Persian puts neither
  # figure where English puts it — a `<>` chain has nowhere for a translator to
  # say so, and `gettext/1` will not take a concatenation as a msgid anyway.
  # `group/1` converts the digits with the grouping now, so ۱,۴۸۰ arrives here
  # already in the reader's numerals — Persian digits around the Latin comma
  # board 59 draws, which is `Kati.Locale.number/1`'s own documented choice.
  #
  # The msgid is `Kati.Screens.Backup.preview_sub/1`'s, to the byte, and that
  # is the point rather than a coincidence: it is the same sentence about the
  # same file, said on the way out and on the way in, and one entry in the
  # catalogue is how the two ends of it cannot drift — the argument the
  # moduledoc already makes for borrowing `dropped_line/1` rather than copying
  # it. `preview_sub/1`'s own doc carries the reason neither of us reaches for
  # `ngettext/4`: there are TWO counts in one sentence and that macro inflects
  # against one.
  @doc false
  def file_headline(%{unlocked: true} = summary) do
    text =
      gettext("%{records} records across %{tables} tables",
        records: Kati.Screens.Restore.group(summary.total_records),
        tables: Kati.Screens.Restore.group(map_size(summary.record_counts))
      )

    Kati.Screens.Restore.headline("inventory_2", text, Palette.ink())
  end

  def file_headline(_summary) do
    Kati.Screens.Restore.headline(
      "lock",
      gettext("Encrypted — Kati cannot read it yet"),
      Palette.ink()
    )
  end

  # The filename and the app version are IDENTIFIERS and stay exactly as the
  # file spells them — but both are Latin runs full of bidi neutrals (a dot
  # between digit groups, the dots in `0.4.1`), so each is isolated with
  # `Kati.Locale.ltr/1` or the run's own punctuation resolves against the
  # Persian page and lands at the wrong edge. A no-op in English.
  #
  # `Kati.Locale.mono_face/1` is asked about the RESULT rather than about the
  # reader, the way `Kati.Screens.Backup.notice_meta/1` asks about its own: the
  # line is pure ASCII under `:en` and keeps the drawing's DM Mono, and once it
  # carries `ساخته‌شده` there is no glyph for it in `kati_mono.ttf` at all.
  @doc false
  def file_meta(file, summary) do
    version =
      case summary.app_version do
        recorded when is_binary(recorded) -> Kati.Locale.ltr(recorded)
        _unrecorded -> pgettext("an app version a backup did not record", "unknown")
      end

    text =
      gettext("%{file} · made %{made} · Kati %{version}",
        file: Kati.Locale.ltr(file.name),
        made: Kati.Screens.Restore.stamp(summary.exported_at),
        version: version
      )

    ~MOB"""
    <Text
      text={text}
      font_family={Kati.Locale.mono_face(text)}
      text_size={10.5}
      line_height={Kati.Locale.leading(1.5)}
      text_color={Palette.muted()}
    />
    """
  end

  # Two whole sentences rather than one with a wrapped clause: the `if` picks
  # between two DIFFERENT paragraphs, not between two endings, so each is its
  # own msgid and a translator never has to reassemble one out of fragments.
  #
  # `Kati.Screens.Backup.dropped_line/1` is the export screen's and is left to
  # it — it is already folded, it isolates the column path it names, and the
  # whole reason this screen borrows the sentence rather than copying it is
  # that two copies is how the two ends of one file quietly stop agreeing.
  @doc false
  def file_detail(%{unlocked: true, encrypted: encrypted} = summary) do
    text =
      if encrypted do
        gettext(
          "Opened with the passphrase you entered. These counts were read out of " <>
            "the file itself, so a restore cannot refuse numbers this card has shown."
        )
      else
        gettext(
          "Not encrypted. Anyone holding this file can read everything in it, which " <>
            "is why it is worth keeping somewhere you would keep a passport."
        )
      end

    [
      ~MOB"<Spacer size={12} />",
      Kati.Screens.Restore.paragraph(text),
      Kati.Screens.Backup.dropped_line(summary.dropped_columns || %{})
    ]
  end

  def file_detail(summary) do
    [
      ~MOB"<Spacer size={12} />",
      Kati.Screens.Restore.paragraph(
        gettext(
          "Kati can see that this is a Kati backup and when it was sealed. It cannot " <>
            "see how many records are inside until the passphrase opens it, and it " <>
            "will not guess at a number it has not read."
        )
      ),
      Kati.Screens.Restore.envelope_line(summary.encryption)
    ]
  end

  # `cipher` and `kdf` are the envelope's own header values — `AES-256-GCM`,
  # `PBKDF2` — and are NOT copy: a reader checking this line against the file's
  # header has to see them spelled the same way, which is the argument
  # `Kati.Screens.Backup.table_line/2` makes for a catalog table name. They are
  # therefore Latin runs on a Persian line, with hyphens and digits between
  # them, and each is isolated so its own punctuation stays inside it.
  #
  # The ` · ` separator is the design's mark in both scripts — the po already
  # carries `%{index} از %{total} · برای همه` — so it is not `Kati.Locale.pick/2`'d
  # into a comma the way a prose list is.
  @doc false
  def envelope_line(nil), do: ~MOB"<Spacer size={0} />"

  def envelope_line(encryption) do
    text =
      [
        encryption[:cipher] && Kati.Locale.ltr(encryption[:cipher]),
        encryption[:kdf] && Kati.Locale.ltr(encryption[:kdf]),
        Kati.Screens.Restore.rounds(encryption[:iterations])
      ]
      |> Enum.reject(&is_nil/1)
      |> Enum.join(" · ")

    Kati.Screens.Restore.mono_line(text)
  end

  # `ngettext/4` rather than a hardcoded plural `s`, for the reason
  # `Kati.Screens.Backup.empty_line/1` gives: English needs `1 round` the day an
  # envelope reports one, and Persian does not inflect a noun after a numeral,
  # so both its forms read the same. The figure goes through `group/1`, which
  # converts the digits with the grouping.
  @doc false
  def rounds(nil), do: nil

  def rounds(iterations) do
    ngettext("%{n} round", "%{n} rounds", iterations, n: Kati.Screens.Restore.group(iterations))
  end

  @doc """
  The passphrase field for a locked file, drawn only while it is locked.

  On the page rather than inside a card: `MobTextField` paints Material's own
  container in `surface_raised`, which is the card colour, so a field inside a
  card would be a card-coloured box on a card-coloured card.
  """
  def unlock_field(%{file: %{summary: %{unlocked: false}}} = job) do
    Kati.Screens.Restore.field(
      job.unlock,
      gettext("Passphrase for this file"),
      :restore_passphrase,
      gettext(
        "A wrong passphrase and an altered file fail identically — GCM cannot tell " <>
          "a wrong key from changed bytes — so Kati will say so rather than pick one."
      ),
      {gettext("Unlock"), :unlock_file}
    )
  end

  def unlock_field(_job), do: ~MOB"<Spacer size={0} />"

  # ── What will happen ─────────────────────────────────────────────────────────

  @doc """
  The counts the summary row draws: the one figure a real, opened file
  answers, or nothing at all. See the moduledoc.
  """
  @spec count_cards(map()) :: [map()]
  def count_cards(%{file: %{summary: %{unlocked: true, total_records: n}}}) when is_integer(n) do
    # `key` as well as `label`: screen 132's old mirror matched on the English
    # WORD with no catch-all and raised mid-render the moment a card said
    # anything else — and once the label is a `gettext/1` it says something else
    # in every locale but one. Nothing reads this key yet; the point is that the
    # next thing to need one finds it rather than reaching for the label.
    [
      %{
        key: :in_file,
        value: Kati.Screens.Restore.group(n),
        label: gettext("In the file"),
        tone: :ink
      }
    ]
  end

  def count_cards(_job), do: []

  @doc """
  The count cards, gapped `Kati.Screens.Import.outcome_gap/0`'s 10pt — or, with
  no file read, the sentence that says there is nothing to count yet.
  """
  @spec count_row([map()]) :: term()
  def count_row([]) do
    text =
      gettext(
        "No file has been read yet, so there is nothing to count. Kati shows what a " <>
          "backup holds before it writes any of it."
      )

    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.Restore.paragraph(text)}
      <Spacer size={11} />
    </Column>
    """
  end

  def count_row(cards) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        {cards
         |> Enum.map(fn card -> Kati.Screens.PlanImport.count_card(card) end)
         |> Enum.intersperse(Kati.Screens.Import.outcome_gap())}
      </Row>
      <Spacer size={11} />
    </Column>
    """
  end

  @doc """
  The ink count's own value, read out of the list `count_row/1` draws rather
  than typed a second time on the Merge button — see the moduledoc. `nil` when
  no file has been read and the row drew no count.
  """
  @spec new_count([map()]) :: String.t() | nil
  def new_count(counts) do
    case Enum.find(counts, fn card -> card.tone == :ink end) do
      %{value: value} -> value
      nil -> nil
    end
  end

  @doc """
  The dashed-frame note saying what a restore would do to this device, given
  how many records `records_on_device/0` found on it.

  The board's sentence — *this device already has data, so the file is merged
  into it* — is a claim about the device, so it is only drawn when it is true.
  An empty device is told the file goes straight in. See the moduledoc for why
  this is not `Kati.UI.SettingsList.note/2`.
  """
  @spec merge_note(non_neg_integer()) :: term()
  def merge_note(here) do
    # The `1.65` the moduledoc argues for stays the LATIN value and is now the
    # argument to `Kati.Locale.leading/1` rather than the number itself:
    # Vazirmatn's metrics are not Plus Jakarta's, and `Kati.Theme.fa_line_height/0`
    # is one constant for every Persian paragraph in the app precisely so a
    # fixed-height row measured against the Latin screen does not break on the
    # Persian one. Both numbers stay visible here, which is the whole argument
    # for `leading/1` taking the design's own value as its argument.
    body = [
      text_size: 12.5,
      line_height: Kati.Locale.leading(1.65),
      text_color: Palette.ink_soft()
    ]

    emphasis = [
      text_size: 12.5,
      line_height: Kati.Locale.leading(1.65),
      text_color: Palette.ink(),
      font_weight: "semibold"
    ]

    paragraph = Kati.Screens.Restore.merge_sentence(here, body, emphasis)

    card =
      MishkaPill.pill(
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

    ~MOB"""
    <Column fill_width={true}>
      {card}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def merge_sentence(0, body, _emphasis) do
    UI.rich_text([
      {gettext(
         "Nothing is stored on this device yet, so the file goes in as it is — there " <>
           "is nothing here for it to be merged with."
       ), body}
    ])
  end

  def merge_sentence(_here, body, emphasis) do
    UI.rich_text([
      {gettext("This device already has data, so the file is "), body},
      {gettext("merged"), emphasis},
      {gettext(" into it: a row already here is kept, and the file’s copy of it is skipped."),
       body}
    ])
  end

  # ── The three modes ─────────────────────────────────────────────────────────

  @doc "The tap tag for a mode. One atom per mode, all of them already existing."
  @spec mode_tag(atom()) :: atom()
  def mode_tag(:into_empty), do: :mode_into_empty
  def mode_tag(:merge), do: :mode_merge
  def mode_tag(:replace), do: :mode_replace

  @doc "The mode a tag names, or `nil` for a tag no control offers."
  @spec mode_for(atom()) :: atom() | nil
  def mode_for(tag),
    do: Enum.find(@modes, fn mode -> Kati.Screens.Restore.mode_tag(mode) == tag end)

  @doc """
  A mode's glyph, its name and the one line that separates it from the other two.

  `pgettext/2` on all six strings rather than `gettext/1`, and the context is
  not decoration. This board draws two near-identical sentences already —
  `Replace everything…` on the outlined row and `Replace everything on this
  device` on the card above it — and a seventh bare `Replace everything` is
  exactly the short msgid `mix gettext.merge` fuzzy-matches against a
  neighbour, which would hand a rendered control a translation written for
  this one. A `msgctxt` makes each its own entry.

  **Nothing on 129 renders these yet**, and the moduledoc says why: the board
  refused the card of three equal rows that used to draw them, and the two
  modes a person can reach are now a button and an outlined row with their own
  copy. They are translated anyway because they are the engine's three modes
  named in a person's words, and the day a screen draws them it must not be
  the day they are first thought about.
  """
  @spec mode_copy(atom()) :: {String.t(), String.t(), String.t()}
  def mode_copy(:into_empty),
    do:
      {"shield", pgettext("a collision mode", "Only into an empty Kati"),
       pgettext("a collision mode", "Refuses if anything is here")}

  def mode_copy(:merge),
    do:
      {"call_merge", pgettext("a collision mode", "Merge into what is here"),
       pgettext("a collision mode", "Insert-only, never overwrites")}

  def mode_copy(:replace),
    do:
      {"delete_forever", pgettext("a collision mode", "Replace everything"),
       pgettext("a collision mode", "Empties every table first")}

  @doc """
  The chosen mode, argued at length — and only once it is a choice.

  `:into_empty` is the resting mode and draws **nothing**: it is what the ink
  button already does, and `129.html` draws no note under the count row. The
  other two are chosen deliberately — one off the refusal notice, one off the
  outlined Replace row — and each gets the paragraph that says what choosing
  it means. Two unchosen paragraphs would be noise; the chosen one is the
  only thing on the page that has changed.

  `:replace`'s note is the one that has to be here rather than nice to have.
  `Kati.Backup.Restore` refuses `:replace` without a `:safety_sink` and
  `Kati.Backup` refuses it without a `:safety_export_path`, so a screen that let
  the user discover that by being refused would be turning a designed
  precondition into an error message. The file is named before it is needed.
  """
  def mode_note(%{mode: :merge}) do
    Kati.Screens.Restore.note(
      "call_merge",
      gettext(
        "A row whose id is already on this device is skipped. Nothing already here " <>
          "is overwritten, updated or deleted, and Kati reports how many it passed " <>
          "over. A backup restored into the device it came from writes nothing."
      )
    )
  end

  # The filename moves from the middle of a `<>` chain into an interpolation,
  # which is not a style change: a msgid must be a literal at the call site, so
  # the sentence could not be translated at all while the name was concatenated
  # into it — and Persian does not put the name where English does. It goes
  # through `Kati.Locale.ltr/1` on the way, because
  # `kati-before-restore-2026-09-12.katibackup` is hyphens and dots all the way
  # down and every one of them is a bidi neutral that would resolve against the
  # page rather than against the name.
  def mode_note(%{mode: :replace}) do
    Kati.Screens.Restore.note(
      "content_copy",
      gettext(
        "Every table is emptied first. Before that happens Kati writes everything " <>
          "on this device to %{file}, inside its own storage where nothing sweeps " <>
          "it away — and if that copy cannot be written, nothing is deleted and " <>
          "nothing has changed.",
        file: Kati.Locale.ltr(Path.basename(Kati.Screens.Restore.safety_path()))
      )
    )
  end

  def mode_note(_job), do: ~MOB"<Spacer size={0} />"

  @doc """
  The single ink CTA — the safe path's only button, and the one that commits.

  See the moduledoc for why its number cannot drift from the count row's, and
  why it commits in the mode currently chosen rather than in the one its own
  label names.
  """
  @spec merge_button(String.t() | nil) :: term()
  def merge_button(new_count) do
    label = Kati.Screens.Restore.merge_label(new_count)
    tap = {self(), :restore_now}

    ~MOB"""
    <Column fill_width={true}>
      <Row
        on_tap={tap}
        fill_width={true}
        height={54}
        corner_radius={27}
        background={Palette.ink_fill()}
        shadow="0 14 28 -12 #801A1917"
        align="center"
      >
        <Text
          text={label}
          text_size={14.5}
          font_weight="bold"
          text_color={Palette.on_ink()}
          max_lines={1}
        />
      </Row>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  The button's words: the count read out of the file, or none when no file has
  been read — never the board's `384`.
  """
  @spec merge_label(String.t() | nil) :: String.t()
  def merge_label(nil), do: pgettext("restore button, no file read yet", "Merge into this device")
  def merge_label(count), do: gettext("Merge %{count} into this device", count: count)

  # ── Or start clean ───────────────────────────────────────────────────────────

  @doc "The full-width rule separating the safe path from the destructive one. See the moduledoc for the token this settles on."
  @spec divider() :: term()
  def divider do
    rule = MishkaSeparator.separator(color: Palette.hairline_strong(), thickness: 1, render: :box)

    ~MOB"""
    <Column fill_width={true}>
      {rule}
      <Spacer size={20} />
    </Column>
    """
  end

  @doc """
  The destructive card naming exactly what Replace deletes, before anyone can
  choose it — `records_on_device/0`'s count, not the board's `418 titles`.

  On an empty device there is nothing to delete, and the card says so rather
  than threatening a loss that cannot happen.
  """
  @spec replace_card(non_neg_integer()) :: term()
  def replace_card(here) do
    body = Kati.Screens.Restore.replace_body(here)

    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={22}
      shadow={Kati.Theme.shadow_card_soft()}
      padding={17}
    >
      <Row fill_width={true} align="top">
        {UI.symbol("error", size: 19, color: Palette.red())}
        <Spacer size={11} />
        <Column weight={1.0}>
          <Text
            text={gettext("Replace everything on this device")}
            text_size={13.5}
            font_weight="bold"
            text_color={Palette.red()}
            max_lines={1}
          />
          <Spacer size={6} />
          <Text
            text={body}
            text_size={12.5}
            line_height={Kati.Locale.leading(1.65)}
            text_color={Palette.ink_soft()}
          />
        </Column>
      </Row>
    </Column>
    """
  end

  @doc false
  def replace_body(0) do
    gettext(
      "Nothing is stored on this device yet, so a replace has nothing to delete — " <>
        "the file would simply go in."
    )
  end

  def replace_body(here) do
    ngettext(
      "Deletes the %{count} record on this device, then writes the file in its place. " <>
        "There is no undo once it finishes.",
      "Deletes all %{count} records on this device, then writes the file in their place. " <>
        "There is no undo once it finishes.",
      here,
      count: Kati.Screens.Restore.group(here)
    )
  end

  @doc """
  The outlined red row that reaches Replace, deliberately never Merge's equal.

  It **selects** `:replace` and draws `mode_note/1`'s safety-export paragraph;
  it does not empty a table. The board's own ellipsis is the promise that more
  comes after it, and what comes after it is the ink button. See the moduledoc
  for its border's literal.
  """
  @spec replace_button() :: term()
  def replace_button do
    tap = {self(), :mode_replace}

    ~MOB"""
    <Row
      on_tap={tap}
      fill_width={true}
      height={44}
      corner_radius={22}
      border_color={Palette.red_ring_strong()}
      border_width={1.5}
      align="center"
    >
      <Text
        text={gettext("Replace everything…")}
        text_size={12.5}
        font_weight="bold"
        text_color={Palette.red()}
        max_lines={1}
      />
    </Row>
    """
  end

  # ── Notices ─────────────────────────────────────────────────────────────────

  @doc """
  The last thing that happened, in the engine's own words.

  One shape for every outcome, with the glyph carrying the difference: a
  refusal is not painted as a failure, because `:into_empty` refusing is the
  safest thing this screen can do and it should read as a decision.
  """
  def notice_block(nil), do: ~MOB"<Spacer size={0} />"

  def notice_block(notice) do
    tint = Kati.Screens.Restore.tint(notice.tone)

    body =
      [
        Kati.Screens.Restore.notice_headline(notice, tint),
        ~MOB"<Spacer size={10} />",
        Kati.Screens.Restore.paragraph(notice.body),
        Kati.Screens.Restore.notice_meta(notice[:meta]),
        Kati.Screens.Restore.notice_actions(notice[:actions] || [])
      ]

    inner = Kati.Screens.Restore.panel(body)

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
        letter_spacing={Kati.Locale.tracking(-0.01)}
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
  def notice_meta(text), do: Kati.Screens.Restore.mono_line(text)

  @doc false
  def notice_actions([]), do: ~MOB"<Spacer size={0} />"

  def notice_actions(actions) do
    pills =
      actions
      |> Enum.map(fn {label, tag} -> Kati.Screens.Restore.pill(label, tag) end)
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

  # ── Shared pieces ───────────────────────────────────────────────────────────

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
        letter_spacing={Kati.Locale.tracking(-0.01)}
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
    <Text
      text={text}
      text_size={12.5}
      line_height={Kati.Locale.leading(1.55)}
      text_color={Palette.ink_soft()}
    />
    """
  end

  # `Kati.Locale.mono_face/1` on the STRING rather than `mono_face/0` on the
  # reader, because this one helper draws two different kinds of line and they
  # want opposite answers. `notice_meta/1` hands it a filename or a path — pure
  # ASCII in both locales, so it keeps the drawing's DM Mono, which is the
  # whole point of a meta line. `envelope_line/1` hands it a line that ends in
  # `۶۰۰,۰۰۰ تکرار`, and `kati_mono.ttf` carries neither the Persian word nor
  # U+06F0–U+06F9, so that one has to take Vazirmatn or Android substitutes a
  # face that is not Kati's. Asking the content answers both.
  @doc false
  def mono_line(text) do
    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={10} />
      <Text
        text={text}
        font_family={Kati.Locale.mono_face(text)}
        text_size={10.5}
        line_height={Kati.Locale.leading(1.5)}
        text_color={Palette.muted()}
      />
    </Column>
    """
  end

  @doc """
  `Kati.UI.card/2` with the lift every other card on this page has.

  `card/2` builds the design's most repeated recipe — the card colour at radius
  20 — and carries no `shadow`. That is right for a panel laid on a card and
  wrong for one laid on the page: `replace_card/1` and every grouped list on
  this screen add `Kati.Theme.shadow_card_soft/0`, and a summary panel without
  it reads as a flat patch beside them.
  """
  def panel(body) do
    card = UI.card(body, padding: 18, background: Palette.card())
    %{card | props: Map.put(card.props, :shadow, Kati.Theme.shadow_card_soft())}
  end

  @doc "A note in the outlined frame `Kati.UI.SettingsList` draws for one."
  def note(icon, text), do: SettingsList.note(icon, text)

  @doc """
  A secure text field with its explanation under it, and optionally a button.

  `value` is passed so the field can be cleared from this side after a
  passphrase has been used. `MobTextField` re-keys its `remember` only when the
  string actually differs, so echoing back what was just typed is a no-op and
  the caret does not move.

  The field is Material's shape and the app's colour: of the props Kati's
  inputs pass it, `MobBridge.kt`'s `MobTextField` reads only `placeholder`,
  `value`, `secure`, `keyboard`, `return_key` and the handlers, and
  `MainActivity.kt` builds its `colorScheme` from `Mob.Theme` — which is also
  why the field sits on the page rather than inside a card.
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
      <Text
        text={hint}
        text_size={11.5}
        line_height={Kati.Locale.leading(1.5)}
        text_color={Palette.sub()}
      />
      {Kati.Screens.Restore.field_action(action)}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def field_action(nil), do: ~MOB"<Spacer size={0} />"

  def field_action({label, tag}) do
    button = Kati.Screens.Restore.pill(label, tag)

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
  `1,480`, never `1480` — and `۱,۴۸۰` rather than either under `:fa`.

  Written here rather than taken from `Cldr.Number` for the reason
  `Kati.Screens.MealsToday` gives. The doc used to add *this screen is the
  English one and its Persian mirror `Kati.Screens.RestoreFa` held its own
  numerals literally*, and mishka-group/kati#103 retired that half: there is no
  mirror any more, this screen renders under both locales, and every figure it
  drew — the file card's two counts, the envelope's iterations, the restore
  report, the byte count — came out in Latin numerals under a Persian heading.

  **The two steps happen in this order and cannot be swapped.**
  `Kati.Locale.number/1` deliberately converts the decimal mark and NOT the
  group separator — its own doc gives the reason, that board 59 draws ۱,۴۸۰
  with a Latin comma while board 115 draws ۷۶٫۰ with U+066B — so a comma
  inserted after the digits had converted would be inserted by a regex that
  matches only ASCII ones and would find nothing to match.
  `Kati.Screens.Backup.group/1` is the identical pair at the other end of the
  same file.

  Every mono call site asks `Kati.Locale.mono_face/1` about the RESULT, so
  `1,480` stays in DM Mono and ۱,۴۸۰, which DM Mono cannot draw at all, takes
  Vazirmatn.
  """
  @spec group(integer()) :: String.t()
  def group(number) when is_integer(number) do
    number
    |> Integer.to_string()
    |> String.reverse()
    |> String.replace(~r/(\d{3})(?=\d)/, "\\1,")
    |> String.reverse()
    |> Kati.Locale.number()
  end

  @doc """
  A backup's timestamp, in the device's zone rather than in UTC — and in the
  reader's own calendar.

  The manifest stores UTC — the format is the same everywhere the file goes —
  and a user reads "made at 02:14" against the clock they were holding, so the
  conversion belongs at the point of display and nowhere earlier.

  **`Kati.Locale` for all four parts, where this read `local.day` and called
  `Kati.Time.month_name/1` directly.** Those answer in the Gregorian calendar
  and in Latin digits, which is the half of mishka-group/kati#103 that gettext
  cannot do: 14 August 2026 and ۲۳ مرداد ۱۴۰۵ are the same day and neither is a
  formatting of the other. A Persian reader was being told a backup was made in
  a month of a year their calendar does not have. English renders exactly the
  string it rendered before, down to the zero-padded minute `Kati.Locale.time/1`
  keeps — `pad/1` went with the last caller that needed it.

  The parts are interpolated through the msgid rather than spliced into a
  string literal because Persian sets the mark between a date and a time as
  U+060C and a translator needs somewhere to say so — and because a msgid has
  to be a literal at the call site, so a spliced string could not be one at
  all. `pgettext/2` rather than `gettext/1` because a msgid of nothing but
  placeholders and a comma is precisely what `mix gettext.merge` fuzzy-matches
  against any sentence ending in one.
  """
  @spec stamp(DateTime.t() | nil) :: String.t()
  def stamp(nil), do: gettext("at an unrecorded time")

  def stamp(%DateTime{} = at) do
    local = Kati.Time.in_zone(at, Kati.Time.device_zone())
    date = DateTime.to_date(local)

    pgettext(
      "when a backup was made",
      "%{day} %{month} %{year}, %{time}",
      day: Kati.Locale.day_of_month(date),
      month: Kati.Locale.month_name(date, :long),
      year: Kati.Locale.year_of(date),
      time: Kati.Locale.time(local)
    )
  end

  # ── Taps ────────────────────────────────────────────────────────────────────

  @impl true
  def handle_tap(tag, socket) do
    case tag do
      :choose_file -> {:noreply, Kati.Screens.Restore.choose(socket)}
      :unlock_file -> {:noreply, Kati.Screens.Restore.unlock(socket)}
      :restore_now -> {:noreply, Kati.Screens.Restore.restore(socket)}
      :save_safety -> {:noreply, Kati.Screens.Restore.save_safety(socket)}
      :dismiss_notice -> {:noreply, Kati.Screens.Restore.put(socket, :notice, nil)}
      _other -> {:noreply, Kati.Screens.Restore.choose_mode(socket, tag)}
    end
  end

  @doc """
  A mode tag sets the mode; anything else leaves the screen alone.

  The catch-all is why this is a named function rather than a clause: the tap
  sweep's `no new dead-looking taps` cannot see through a `_tag ->` arm, so the
  arm has to be the *only* thing behind it and has to be readable as such.
  """
  def choose_mode(socket, tag) do
    case Kati.Screens.Restore.mode_for(tag) do
      nil -> socket
      mode -> Kati.Screens.Restore.put(socket, :mode, mode)
    end
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
      Kati.Screens.Restore.put(socket, :notice, %{
        tone: :info,
        icon: "info",
        title: gettext("This build cannot open a file picker"),
        body:
          gettext(
            "The system document picker is not bound here, so there is no way to hand " <>
              "Kati a file to restore. Nothing on the device has changed."
          )
      })
  end

  @doc """
  Re-read a locked file with the passphrase the user typed.

  `inspect_file/2` again rather than a decrypt-and-remember: the answer a screen
  shows must come from the same verification a restore runs, and running it
  twice is the price of that guarantee.
  """
  def unlock(%{assigns: %{restore: %{file: nil}}} = socket), do: socket

  def unlock(socket) do
    job = socket.assigns.restore

    case Kati.Backup.inspect_file(job.file.path, passphrase: job.unlock) do
      {:ok, summary} ->
        file = %{job.file | summary: summary}
        Mob.Socket.assign(socket, :restore, %{job | file: file, notice: nil})

      {:error, %Error{} = error} ->
        Kati.Screens.Restore.put(socket, :notice, Kati.Screens.Restore.inspect_notice(error))
    end
  end

  @doc """
  Verify the file and write it, in the mode currently chosen.

  Every refusal below is the engine's, rendered word for word. `:not_empty` in
  particular is offered the other two modes rather than an apology: it is the
  default precisely because it is the only mode that cannot lose anything.
  """
  # The extension is interpolated rather than written into the msgid: `.katibackup`
  # is a Latin run that opens on a bidi NEUTRAL, and a leading dot inside a
  # Persian sentence resolves against the page and lands after the word instead
  # of before it — `katibackup.` — which is the exact failure
  # `Kati.Locale.ltr/1`'s own doc describes for screen 83's licence notices.
  # Interpolating it also keeps the extension out of the translator's hands,
  # which is right: it is what Android filters on, not a word.
  def restore(%{assigns: %{restore: %{file: nil}}} = socket) do
    Kati.Screens.Restore.put(socket, :notice, %{
      tone: :refused,
      icon: "upload_file",
      title: gettext("There is no file to restore"),
      body:
        gettext(
          "No file has been chosen yet. Choose a %{ext} and Kati will read it before " <>
            "it writes anything.",
          ext: Kati.Locale.ltr(".katibackup")
        )
    })
  end

  def restore(socket) do
    job = socket.assigns.restore
    opts = Kati.Screens.Restore.restore_opts(job)

    case Kati.Backup.restore_file(job.file.path, opts) do
      {:ok, report} ->
        socket
        |> Kati.Screens.Restore.put(:notice, Kati.Screens.Restore.restored_notice(report))
        |> Kati.Screens.Restore.put(:here, Kati.Screens.Restore.records_on_device())

      {:error, %Error{} = error} ->
        Kati.Screens.Restore.put(socket, :notice, Kati.Screens.Restore.restore_notice(error))
    end
  end

  @doc false
  def restore_opts(job) do
    base = [mode: job.mode] ++ Kati.Screens.Restore.passphrase_opts(job.unlock != "", job.unlock)

    if job.mode == :replace do
      base ++ [safety_export_path: Kati.Screens.Restore.safety_path()]
    else
      base
    end
  end

  @doc "A passphrase, only when there is one — an empty string is not a key."
  @spec passphrase_opts(boolean(), String.t()) :: keyword()
  def passphrase_opts(false, _passphrase), do: []
  def passphrase_opts(true, passphrase), do: [passphrase: passphrase]

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

  # Four whole sentences, each its own msgid, where this built four strings by
  # concatenating a figure onto a fragment. A msgid has to be a literal at the
  # call site, so none of these could have been translated as they stood — and
  # a leading `%{n}` is the one position Persian will not always keep, which is
  # the reason the figure moves into the sentence rather than in front of it.
  #
  # `report.safety_export` goes to `meta` unwrapped: it is a PATH, it draws in
  # the mono line, and `mono_line/1` asks `Kati.Locale.mono_face/1` about it and
  # gets `"mono"` back for exactly that reason.
  @doc false
  def restored_notice(report) do
    inserted = Kati.Screens.Restore.group(report.total_inserted)
    skipped = report.total_skipped

    body =
      case {report.mode, skipped} do
        {:merge, 0} ->
          gettext("%{n} records went in. Nothing that was already here was touched.", n: inserted)

        {:merge, n} ->
          gettext(
            "%{n} records went in and %{skipped} were skipped because their rows were " <>
              "already on this device. Nothing existing was overwritten.",
            n: inserted,
            skipped: Kati.Screens.Restore.group(n)
          )

        {:replace, _n} ->
          gettext(
            "%{n} records went in. Everything that was here first was written out to " <>
              "a file before any of it was deleted.",
            n: inserted
          )

        {_mode, _n} ->
          gettext("%{n} records went in, into tables that were empty.", n: inserted)
      end

    %{
      tone: :ok,
      icon: "check_circle",
      title: gettext("Restored"),
      body: body,
      meta: report.safety_export,
      actions: Kati.Screens.Restore.restored_actions(report.safety_export)
    }
  end

  @doc false
  def restored_actions(nil), do: []
  def restored_actions(_path), do: [{gettext("Save that copy"), :save_safety}]

  @doc "Hand the pre-replace copy to the system, so it does not only live in the app."
  def save_safety(socket) do
    path = Kati.Screens.Restore.safety_path()

    case Files.save_as(path, name: Path.basename(path)) do
      :ok ->
        Kati.Screens.Restore.put(socket, :notice, %{
          tone: :info,
          icon: "upload",
          title: gettext("Choose where to keep the old data"),
          body:
            gettext(
              "This is everything that was on the device before the restore. Kati keeps " <>
                "its own copy either way; this is the one you can hold."
            ),
          meta: path
        })

      {:error, _reason} ->
        Kati.Screens.Restore.put(socket, :notice, %{
          tone: :info,
          icon: "info",
          title: gettext("Kati cannot hand that file to the system here"),
          body: gettext("The copy of your old data is written and waiting on the device."),
          meta: path
        })
    end
  end

  # `error.message` is NOT wrapped, in any clause here or in `inspect_notice/1`
  # below. It is written by `Kati.Backup.Error`, which owns those sentences and
  # is the module that has to translate them — `gettext(error.message)` would
  # not compile, since a msgid must be a literal at the call site, and a lookup
  # table of another module's copy kept here would be a second place for it to
  # live. The moduledoc's promise is that the engine's refusal reaches the
  # screen unedited; a translation table on this side would be an edit.
  @doc false
  def restore_notice(%Error{reason: :not_empty} = error) do
    %{
      tone: :refused,
      icon: "shield",
      title: gettext("Nothing has been changed"),
      body: error.message,
      actions: [
        {gettext("Merge instead"), :mode_merge},
        {gettext("Replace instead"), :mode_replace}
      ]
    }
  end

  def restore_notice(%Error{reason: :safety_export_required} = error) do
    %{
      tone: :refused,
      icon: "shield",
      title: gettext("Nothing has been deleted"),
      body: error.message,
      meta: Kati.Screens.Restore.safety_path()
    }
  end

  def restore_notice(%Error{reason: reason} = error)
      when reason in [:bad_passphrase, :passphrase_required] do
    Kati.Screens.Restore.inspect_notice(error)
  end

  def restore_notice(%Error{} = error) do
    %{
      tone: :error,
      icon: "error",
      title: gettext("This backup was not written"),
      body: error.message
    }
  end

  @doc false
  def inspect_notice(%Error{reason: :bad_passphrase} = error) do
    %{
      tone: :error,
      icon: "lock",
      title: gettext("That passphrase did not open it"),
      body: error.message
    }
  end

  def inspect_notice(%Error{reason: :passphrase_required} = error) do
    %{
      tone: :refused,
      icon: "lock",
      title: gettext("This backup is encrypted"),
      body: error.message
    }
  end

  def inspect_notice(%Error{reason: :not_a_backup} = error) do
    %{
      tone: :refused,
      icon: "block",
      title: gettext("That is not a Kati backup"),
      body: error.message
    }
  end

  def inspect_notice(%Error{} = error) do
    %{
      tone: :error,
      icon: "error",
      title: gettext("Kati could not read that file"),
      body: error.message
    }
  end

  # ── Messages from the device ────────────────────────────────────────────────

  # Everything that is not a tap.
  #
  # One clause for the passphrase field and one that asks `event/1` whether a
  # message is a file-transport answer, with `super/2` under it for the shell's
  # own tags. The macro's `handle_info/2` clauses are `defoverridable`, so an
  # override replaces the WHOLE set — `super/2` is how `:back`, `{:kati, …}` and
  # every other tag keep working, and dropping it would take the back pill with
  # it.
  @impl true
  def handle_info({:change, tag, value}, socket) when is_atom(tag) and is_binary(value) do
    {:noreply, Kati.Screens.Restore.typed(socket, tag, value)}
  end

  def handle_info(message, socket) do
    case Kati.Screens.Restore.event(message) do
      :ignore -> super(message, socket)
      event -> {:noreply, Kati.Screens.Restore.apply_event(event, socket)}
    end
  end

  @doc """
  A device message as a value, or `:ignore`.

  Two doors report here — `Mob.Files.pick/2` answers `{:files, …}` and
  `Kati.Native.Files`'s save intent answers `{:kati_files, …}` — so both are
  read in one place. `:ignore` is what keeps an unrelated message from matching
  a transport clause by accident; Kati runs one screen process and it sees
  everything sent to it.
  """
  @spec event(term()) :: term()
  def event({:files, :picked, items}) when is_list(items), do: {:picked, items}
  def event({:files, :cancelled}), do: :picker_cancelled
  def event(message), do: Files.decode(message)

  @doc false
  def typed(socket, :restore_passphrase, value),
    do: Kati.Screens.Restore.put(socket, :unlock, value)

  def typed(socket, _tag, _value), do: socket

  @doc """
  What a device message does to the screen.

  A cancelled picker and a cancelled Save As… are **not** errors — a user who
  backs out of a folder chooser has done an ordinary thing — so both get an
  informational notice that says nothing has changed rather than a failure.

  Note what is missing: `{:saved, …}` does **not** call
  `Kati.Screens.Settings.record_backup/0`. The only file this screen ever hands
  to the system is the safety copy taken on the way into a `:replace`, and a
  dump Kati took on the user's behalf is not a backup the user made. See the
  moduledoc.
  """
  def apply_event({:picked, items}, socket) do
    case Transport.accept(items) do
      {:ok, item} ->
        Kati.Screens.Restore.inspect_picked(socket, item)

      {:error, %Error{} = error} ->
        Kati.Screens.Restore.put(socket, :notice, Kati.Screens.Restore.inspect_notice(error))
    end
  end

  def apply_event(:picker_cancelled, socket) do
    Kati.Screens.Restore.put(socket, :notice, %{
      tone: :info,
      icon: "info",
      title: gettext("No file was chosen"),
      body: gettext("Nothing on this device has changed.")
    })
  end

  def apply_event(:cancelled, socket) do
    Kati.Screens.Restore.put(socket, :notice, %{
      tone: :info,
      icon: "info",
      title: gettext("The copy was not saved"),
      body:
        gettext(
          "You closed the folder chooser, so nothing was written outside Kati. The " <>
            "copy of your old data is still on the device and saving again costs nothing."
        )
    })
  end

  def apply_event({:saved, item}, socket) do
    Kati.Screens.Restore.put(socket, :notice, %{
      tone: :ok,
      icon: "check_circle",
      title: gettext("Saved"),
      body:
        gettext(
          "%{n} bytes were written where you chose. That is the copy of what was on " <>
            "this device before the restore, not a backup of what is on it now.",
          n: Kati.Screens.Restore.group(item.bytes)
        ),
      meta: item.name
    })
  end

  # `inspect(reason)` stays as it is: it is a term the bridge handed back, not a
  # sentence, and there is no msgid for a stack of Erlang. It draws in the mono
  # meta line, which `Kati.Locale.mono_face/1` keeps in DM Mono for it — the
  # identical call `Kati.Screens.Backup.apply_event/2` makes for its own.
  def apply_event({:error, reason}, socket) do
    Kati.Screens.Restore.put(socket, :notice, %{
      tone: :error,
      icon: "error",
      title: gettext("The system dialog failed"),
      body: gettext("Nothing on this device has changed."),
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
    job = socket.assigns.restore

    case Kati.Backup.inspect_file(item.path) do
      {:ok, summary} ->
        file = %{name: item.name, path: item.path, summary: summary}
        Mob.Socket.assign(socket, :restore, %{job | file: file, unlock: "", notice: nil})

      {:error, %Error{} = error} ->
        Mob.Socket.assign(socket, :restore, %{
          job
          | file: nil,
            notice: Kati.Screens.Restore.inspect_notice(error)
        })
    end
  end

  @doc false
  def put(socket, key, value) do
    Mob.Socket.assign(socket, :restore, Map.put(socket.assigns.restore, key, value))
  end
end
