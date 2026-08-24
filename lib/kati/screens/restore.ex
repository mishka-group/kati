defmodule Kati.Screens.Restore do
  @moduledoc """
  Screen 129 — Restore from a backup, pushed under Settings.

  Built to `.scratch/design/incoming/129.html`. This is screen 37's import
  idiom moved onto a device: a file is acknowledged, the write is summarised
  as three counts, one conflict is answered at a time, and nothing is written
  until the last step. `Kati.Screens.PlanImport` is the pattern this file was
  told to follow, because it is the same idiom's second drawing already —
  five of screen 37's builders reused rather than copied, the frame re-drawn
  wherever the two designs actually differ. This is the idiom's third.

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

  The board draws one state — a file already picked, its counts known, the
  first of six conflicts open — and this screen still draws exactly that at
  rest. Everything the moved behaviour needs beyond it is drawn **only once
  the resting frame has been left**: the notice card appears when something
  has happened, the file card when `inspect_file/2` has answered, the
  passphrase field when the file it belongs to is sealed, the mode note when
  a mode other than the default has been chosen. At rest every one of them is
  a zero-height spacer, which is why `Kati.ScreenDesignLiteralTest` still
  compares this file against `129.html` and finds the board's own copy and
  nothing else.

  That is not a loophole. `130.html` — *Backup & restore — eight states* —
  draws these states as a board of their own: *Restoring*, *This file is from
  a newer Kati*, *Couldn't read this file*, *Everything came back*. The design
  has states; 129 is the resting one, and a screen that could not enter the
  others would be a picture of a restore rather than a restore.

  ## What is literally 37's or PlanImport's, and what is re-drawn

  Reused rather than copied, because both drawings put the identical node on
  screen:

    * `Kati.Screens.PlanImport.count_card/1` — the DM Mono figure over its
      letter-spaced caps label, at weight 500 and 9.5pt. This board's counts
      are set in the same face PlanImport's are, for the same reason: `384`,
      `28` and `6` are read off a document, not announced.
    * `Kati.Screens.Import.outcome_gap/0` — the 10pt between the three count
      cards, unchanged between all three drawings.
    * `Kati.Screens.PlanImport.conflict_tile/1` — the 40pt icon tile a
      conflict leads with when it has no artwork, at `poster_on_cream` under a
      `gold_icon` glyph.
    * `Kati.Screens.Import.choice/1`, `choice_gap/0` and `star_text/3` — the
      three 32pt answer pills, the 8pt gap between them, and the ★ rendered as
      the Material Symbols glyph rather than as text, because Plus Jakarta
      Sans carries no U+2605 and screen 08 already proved that renders as
      nothing.

  Everything else is re-drawn, because this board's own rhythm is tighter
  than either of its ancestors': 11pt after the file card and the count row
  rather than 22, 24pt after the scan card, the note and the conflict rather
  than 22. Those are this drawing's own numbers, kept rather than rounded to
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

  ## The three-count summary collapses when it is a reading

  `384 / 28 / 6` is `Kati.Backup.SampleRestore`'s, and it is screen 37's
  pre-write summary reused verbatim — the board says so in its own caption.
  It stays exactly that until a real file has been opened, because it is the
  drawing's illustration of a dry run and Kati has no dry run: `Kati.Backup.Restore`
  is insert-only in `:merge` and reports what it skipped **after** it has run,
  and there is no per-row conflict resolver behind those three pills at all.

  What this screen *can* read out of a real file is one number — how many
  records are in it — so once one is open the row collapses to that single
  figure, which is the move `135.html` already makes for the same reason:
  *"on an empty device 37's three-count summary is dishonest — there is
  nothing to merge or conflict — so it collapses to a single figure and says
  so in words."* Inventing a `Merged` and a `Conflicts` count for a file
  nothing has diffed would be three numbers where the app has one.

  `merge_button/1` is still handed `new_count/1`'s reading of whatever the
  count row drew rather than a fourth typed `"384"` — the same argument
  `PlanImport.title/1` makes for building its `STEP 3 OF 4` kicker out of the
  step meter's own numbers: two chances to write one figure is how a button
  and a card quietly stop agreeing.

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

  `merge_note/0` draws the same dashed-read-as-solid frame `note/2` draws —
  `Kati.Components.MishkaPill` at `border_color: Palette.border/0`, the same
  16% this board's own `rgba(26,25,23,.16)` already is — but is not a call to
  it, because three of this board's numbers are not `note/2`'s: `padding: 15`
  where that helper writes 16, an 17pt glyph where it writes 18, and a
  `1.65` line height where its own `note_text/1` is pinned to `1.55`. On top
  of that, the sentence needs a bold word — *merged* — mid-paragraph, which
  `note/2`'s single-string `text` argument cannot carry at all. `merge_note/0`
  therefore builds the same component with this board's own five numbers and
  a `Kati.UI.rich_text/1` paragraph in place of the plain string, which is the
  reason `PlanImport.footer/0` exists as a hand-built card and not a call to
  `note/2` either: a paragraph with an emphasis inside it needs the one node
  that can wrap, and `rich_text/1`'s own doc records that the emphasis is
  therefore rendered plain rather than dropped or orphaned.

  ## The conflict card is still the drawing's, and says so

  Nothing behind the three answer pills exists: `Kati.Backup.Restore` merges
  insert-only and skips a row whose id is already here, and there is no API
  that hands a screen one collision at a time. The pills therefore carry no
  tap, for the reason `Kati.Screens.PlanImport`'s own Audited section gives —
  there is nowhere to hold an answered conflict alive across two renders, and
  a control that forgets its answer the moment the screen pops is worse than
  one that is honestly still a drawing. The conflict resolver is the one part
  of `129.html` this file has not made real, and it is the one part the engine
  cannot yet answer.

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
  alias Kati.Backup.SampleRestore
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
  The screen at rest: no file, no notice, the safest mode, and the board's own
  stand-in preview.

  `load/1` reads nothing — not the database, not a file, not `Mob.State` — so a
  fresh install and an empty database render exactly this. Every fact this
  screen reports about a real backup is read out of that backup when it is
  picked, and never before.
  """
  @spec blank() :: map()
  def blank do
    %{
      file: nil,
      unlock: "",
      mode: :into_empty,
      notice: nil,
      counts: SampleRestore.counts(),
      conflict: SampleRestore.conflict(),
      replace: SampleRestore.replace()
    }
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
        {UI.eyebrow("Choose a file")}
        {Kati.Screens.Restore.file_row(Kati.Screens.Restore.file_name(job))}
        {Kati.Screens.Restore.file_card(job.file)}
        {Kati.Screens.Restore.unlock_field(job)}
        {Kati.Screens.Restore.scan_card()}
        {UI.eyebrow("What will happen")}
        {Kati.Screens.Restore.count_row(cards)}
        {Kati.Screens.Restore.merge_note()}
        {Kati.Screens.Restore.mode_note(job)}
        {UI.eyebrow("Conflicts · keep which?")}
        {Kati.Screens.Restore.conflict_card(job.conflict)}
        {Kati.Screens.Restore.merge_button(Kati.Screens.Restore.new_count(cards))}
        {Kati.Screens.Restore.divider()}
        {SettingsList.eyebrow_muted("Or start clean")}
        {Kati.Screens.Restore.replace_card(job.replace)}
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
    ~MOB"""
    <Column fill_width={true}>
      <Text
        text="Restore from a backup"
        text_size={28}
        max_font_scale={1.6}
        font_weight="bold"
        letter_spacing={-0.03}
        text_color={:on_surface}
      />
      <Spacer size={6} />
      <Text
        text="NOTHING IS WRITTEN UNTIL THE LAST STEP"
        font_family="mono"
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
  The filename the file row shows: the picked file's own, or the drawing's.

  `129.html` is drawn with a file already chosen, and `SampleRestore.file/0`
  is that name. It stands until a real one replaces it — never beside one,
  because two filenames on a row that names one file is the one thing this
  row must not do.
  """
  @spec file_name(map()) :: String.t()
  def file_name(%{file: %{name: name}}) when is_binary(name), do: name
  def file_name(_job), do: SampleRestore.file()

  @doc """
  The single-row card offering the picked file.

  `rule: false` because it is the only row a card this small holds — the last
  row in a `Kati.UI.SettingsList` card never draws the hairline under it, and
  here that is also the first and only one.
  """
  @spec file_row(String.t()) :: term()
  def file_row(name) do
    row =
      SettingsList.row(
        SettingsList.icon_tile("upload_file"),
        SettingsList.body("Pick a file", name),
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
            text="Scan from another phone"
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
    body = [text_size: 11.5, line_height: 1.6, text_color: Palette.cream_sub()]

    emphasis = [
      text_size: 11.5,
      line_height: 1.6,
      text_color: Palette.cream_ink(),
      font_weight: "semibold"
    ]

    UI.rich_text([
      {"Carries ", body},
      {"settings and plans only", emphasis},
      {" — a QR payload is small, and a library is not.", body}
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

  @doc false
  def file_headline(%{unlocked: true} = summary) do
    records = Kati.Screens.Restore.group(summary.total_records)
    tables = Kati.Screens.Restore.group(map_size(summary.record_counts))
    text = records <> " records across " <> tables <> " tables"

    Kati.Screens.Restore.headline("inventory_2", text, Palette.ink())
  end

  def file_headline(_summary) do
    Kati.Screens.Restore.headline("lock", "Encrypted — Kati cannot read it yet", Palette.ink())
  end

  @doc false
  def file_meta(file, summary) do
    made = Kati.Screens.Restore.stamp(summary.exported_at)
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
  def file_detail(%{unlocked: true, encrypted: encrypted} = summary) do
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
      Kati.Screens.Restore.paragraph(text),
      Kati.Screens.Backup.dropped_line(summary.dropped_columns || %{})
    ]
  end

  def file_detail(summary) do
    [
      ~MOB"<Spacer size={12} />",
      Kati.Screens.Restore.paragraph(
        "Kati can see that this is a Kati backup and when it was sealed. It cannot " <>
          "see how many records are inside until the passphrase opens it, and it " <>
          "will not guess at a number it has not read."
      ),
      Kati.Screens.Restore.envelope_line(summary.encryption)
    ]
  end

  @doc false
  def envelope_line(nil), do: ~MOB"<Spacer size={0} />"

  def envelope_line(encryption) do
    text =
      [
        encryption[:cipher],
        encryption[:kdf],
        Kati.Screens.Restore.rounds(encryption[:iterations])
      ]
      |> Enum.reject(&is_nil/1)
      |> Enum.join(" · ")

    Kati.Screens.Restore.mono_line(text)
  end

  @doc false
  def rounds(nil), do: nil
  def rounds(iterations), do: Kati.Screens.Restore.group(iterations) <> " rounds"

  @doc """
  The passphrase field for a locked file, drawn only while it is locked.

  On the page rather than inside a card: `MobTextField` paints Material's own
  container in `surface_raised`, which is the card colour, so a field inside a
  card would be a card-coloured box on a card-coloured card.
  """
  def unlock_field(%{file: %{summary: %{unlocked: false}}} = job) do
    Kati.Screens.Restore.field(
      job.unlock,
      "Passphrase for this file",
      :restore_passphrase,
      "A wrong passphrase and an altered file fail identically — GCM cannot tell " <>
        "a wrong key from changed bytes — so Kati will say so rather than pick one.",
      {"Unlock", :unlock_file}
    )
  end

  def unlock_field(_job), do: ~MOB"<Spacer size={0} />"

  # ── What will happen ─────────────────────────────────────────────────────────

  @doc """
  The counts the summary row draws: the drawing's three, or the one figure a
  real file actually answers. See the moduledoc.
  """
  @spec count_cards(map()) :: [map()]
  def count_cards(%{file: %{summary: %{unlocked: true, total_records: n}}}) when is_integer(n) do
    [%{value: Kati.Screens.Restore.group(n), label: "In the file", tone: :ink}]
  end

  def count_cards(job), do: job.counts

  @doc "The three count cards, gapped `Kati.Screens.Import.outcome_gap/0`'s 10pt."
  @spec count_row([map()]) :: term()
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
  The `New` count's own value, read out of the list `count_row/1` draws rather
  than typed a second time on the Merge button — see the moduledoc.
  """
  @spec new_count([map()]) :: String.t()
  def new_count(counts) do
    %{value: value} = Enum.find(counts, fn card -> card.tone == :ink end)
    value
  end

  @doc "The dashed-frame note explaining what a merge does. See the moduledoc for why this is not `Kati.UI.SettingsList.note/2`."
  @spec merge_note() :: term()
  def merge_note do
    body = [text_size: 12.5, line_height: 1.65, text_color: Palette.ink_soft()]

    emphasis = [
      text_size: 12.5,
      line_height: 1.65,
      text_color: Palette.ink(),
      font_weight: "semibold"
    ]

    paragraph =
      UI.rich_text([
        {"This device already has data, so the file is ", body},
        {"merged", emphasis},
        {" into it. Nothing is written until you finish the last conflict.", body}
      ])

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

  @doc "A mode's glyph, its name and the one line that separates it from the other two."
  @spec mode_copy(atom()) :: {String.t(), String.t(), String.t()}
  def mode_copy(:into_empty),
    do: {"shield", "Only into an empty Kati", "Refuses if anything is here"}

  def mode_copy(:merge),
    do: {"call_merge", "Merge into what is here", "Insert-only, never overwrites"}

  def mode_copy(:replace),
    do: {"delete_forever", "Replace everything", "Empties every table first"}

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
      "A row whose id is already on this device is skipped. Nothing already here " <>
        "is overwritten, updated or deleted, and Kati reports how many it passed " <>
        "over. A backup restored into the device it came from writes nothing."
    )
  end

  def mode_note(%{mode: :replace}) do
    Kati.Screens.Restore.note(
      "content_copy",
      "Every table is emptied first. Before that happens Kati writes everything " <>
        "on this device to " <>
        Path.basename(Kati.Screens.Restore.safety_path()) <>
        ", inside its own storage where nothing sweeps it away — and if that copy " <>
        "cannot be written, nothing is deleted and nothing has changed."
    )
  end

  def mode_note(_job), do: ~MOB"<Spacer size={0} />"

  # ── Conflicts · keep which? ──────────────────────────────────────────────────

  @doc """
  The open conflict, on the palette's one warm surface.

  Built from `Kati.Screens.PlanImport.conflict_tile/1` and
  `Kati.Screens.Import.choice/1`, `choice_gap/0` and `star_text/3` — see the
  moduledoc for which piece comes from which screen and why.
  """
  @spec conflict_card(map()) :: term()
  def conflict_card(c) do
    ~MOB"""
    <Column fill_width={true}>
      <Column fill_width={true} background={Palette.cream()} corner_radius={20} padding={15}>
        <Row fill_width={true} align="center">
          {Kati.Screens.PlanImport.conflict_tile(c.icon)}
          <Spacer size={12} />
          <Column weight={1.0}>
            <Text
              text={c.title}
              text_size={13}
              font_weight="bold"
              text_color={Palette.cream_ink()}
              max_lines={1}
            />
            <Spacer size={3} />
            {Kati.Screens.Import.star_text(c.line, 11.5, Palette.cream_sub())}
          </Column>
        </Row>
        <Spacer size={13} />
        <Row fill_width={true} align="center">
          {c.choices
           |> Enum.map(fn choice -> Kati.Screens.Import.choice(choice) end)
           |> Enum.intersperse(Kati.Screens.Import.choice_gap())}
        </Row>
        <Spacer size={12} />
        <Text
          text={c.progress}
          font_family="mono"
          text_size={10.5}
          text_color={Palette.cream_meta()}
          text_align="center"
          max_lines={1}
        />
      </Column>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  The single ink CTA — the safe path's only button, and the one that commits.

  See the moduledoc for why its number cannot drift from the count row's, and
  why it commits in the mode currently chosen rather than in the one its own
  label names.
  """
  @spec merge_button(String.t()) :: term()
  def merge_button(new_count) do
    label = "Merge " <> new_count <> " into this device"
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

  @doc "The destructive card naming exactly what Replace deletes, before anyone can choose it."
  @spec replace_card(map()) :: term()
  def replace_card(r) do
    body =
      "Deletes all #{r.count} #{r.noun}, every note and every session, then writes the file in their place. There is no undo once it finishes."

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
            text="Replace everything on this device"
            text_size={13.5}
            font_weight="bold"
            text_color={Palette.red()}
            max_lines={1}
          />
          <Spacer size={6} />
          <Text text={body} text_size={12.5} line_height={1.65} text_color={Palette.ink_soft()} />
        </Column>
      </Row>
    </Column>
    """
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
        text="Replace everything…"
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
      <Text text={hint} text_size={11.5} line_height={1.5} text_color={Palette.sub()} />
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
  `1,480`, never `1480`.

  Written here rather than taken from `Cldr.Number` for the reason
  `Kati.Screens.MealsToday` gives: this screen is the English one, its Persian
  mirror `Kati.Screens.RestoreFa` holds its own numerals literally, and the
  sweep renders both in both locales.
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
        title: "This build cannot open a file picker",
        body:
          "The system document picker is not bound here, so there is no way to hand " <>
            "Kati a file to restore. Nothing on the device has changed."
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
  def restore(%{assigns: %{restore: %{file: nil}}} = socket) do
    Kati.Screens.Restore.put(socket, :notice, %{
      tone: :refused,
      icon: "upload_file",
      title: "There is no file to restore",
      body:
        "The name above the picker is the drawing's, not a file on this device. " <>
          "Choose a .katibackup and Kati will read it before it writes anything."
    })
  end

  def restore(socket) do
    job = socket.assigns.restore
    opts = Kati.Screens.Restore.restore_opts(job)

    case Kati.Backup.restore_file(job.file.path, opts) do
      {:ok, report} ->
        Kati.Screens.Restore.put(socket, :notice, Kati.Screens.Restore.restored_notice(report))

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

  @doc false
  def restored_notice(report) do
    inserted = Kati.Screens.Restore.group(report.total_inserted)
    skipped = report.total_skipped

    body =
      case {report.mode, skipped} do
        {:merge, 0} ->
          inserted <> " records went in. Nothing that was already here was touched."

        {:merge, n} ->
          inserted <>
            " records went in and " <>
            Kati.Screens.Restore.group(n) <>
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
      actions: Kati.Screens.Restore.restored_actions(report.safety_export)
    }
  end

  @doc false
  def restored_actions(nil), do: []
  def restored_actions(_path), do: [{"Save that copy", :save_safety}]

  @doc "Hand the pre-replace copy to the system, so it does not only live in the app."
  def save_safety(socket) do
    path = Kati.Screens.Restore.safety_path()

    case Files.save_as(path, name: Path.basename(path)) do
      :ok ->
        Kati.Screens.Restore.put(socket, :notice, %{
          tone: :info,
          icon: "upload",
          title: "Choose where to keep the old data",
          body:
            "This is everything that was on the device before the restore. Kati keeps " <>
              "its own copy either way; this is the one you can hold.",
          meta: path
        })

      {:error, _reason} ->
        Kati.Screens.Restore.put(socket, :notice, %{
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
      meta: Kati.Screens.Restore.safety_path()
    }
  end

  def restore_notice(%Error{reason: reason} = error)
      when reason in [:bad_passphrase, :passphrase_required] do
    Kati.Screens.Restore.inspect_notice(error)
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
      title: "No file was chosen",
      body: "Nothing on this device has changed."
    })
  end

  def apply_event(:cancelled, socket) do
    Kati.Screens.Restore.put(socket, :notice, %{
      tone: :info,
      icon: "info",
      title: "The copy was not saved",
      body:
        "You closed the folder chooser, so nothing was written outside Kati. The " <>
          "copy of your old data is still on the device and saving again costs nothing."
    })
  end

  def apply_event({:saved, item}, socket) do
    Kati.Screens.Restore.put(socket, :notice, %{
      tone: :ok,
      icon: "check_circle",
      title: "Saved",
      body:
        Kati.Screens.Restore.group(item.bytes) <>
          " bytes were written where you chose. That is the copy of what was on this " <>
          "device before the restore, not a backup of what is on it now.",
      meta: item.name
    })
  end

  def apply_event({:error, reason}, socket) do
    Kati.Screens.Restore.put(socket, :notice, %{
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
