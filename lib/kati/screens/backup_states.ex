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

  ## Under `:fa` this is one screen and not two, and four choices follow

  mishka-group/kati#103 folded the 33 Persian mirrors away, so every sentence
  here reaches a Persian reader through `Kati.Gettext` and every figure through
  `Kati.Locale`. Four of those are decisions rather than mechanics:

    * **`14 Aug` is a `Date` and not a string.** `Kati.Locale.date/2` answers
      ۲۳ مرداد under `:fa`, and that is a different CALENDAR rather than the
      same date translated. The date itself is `Kati.Settings.Sample.data/0`'s
      own `~D[2026-08-14]`, the *Last backup* row this card is a picture of, so
      the two cannot drift apart — and its 214 MB is the same fixture's figure.
    * **Every mono line asks `Kati.Locale.mono_face/0` or `/1`.**
      `kati_mono.ttf` carries no Persian glyph and none of U+06F0–U+06F9, so a
      Persian line left in `mono` is handed to Android's own substitute face
      and renders, correctly shaped, in a typeface that is not Kati's. The
      restore summary's figures ask the STRING — `mono_face/1` — because `418`
      is ASCII and ۴۱۸ is not, and the answer should follow the digits rather
      than a second decision.
    * **`80` stays inside its msgid.** `Kati.Screens.MyServices.credit/0`
      writes *credited on 83* the same way and gives the reason: a board number
      inside a sentence is part of the sentence, and interpolating it would
      make one number two things to keep in step. Every other figure on the
      sheet — 214 MB, 384, 56%, the eight-week threshold — is a MEASUREMENT and
      does go through `Kati.Locale.number/1`.
    * **`1.4` and `1.2` keep Latin digits.** A version is not a decimal, and
      `Kati.Locale.number/1` rewrites `.` as U+066B ARABIC DECIMAL SEPARATOR —
      the right mark for ۷۶٫۰ and the wrong one for a release number. They go
      through `Kati.Locale.ltr/1` instead, which isolates each run so the
      semicolon and the full stop beside them resolve against the number rather
      than against the page.
  """

  use Kati.Screens.Pushed, back: "Settings"
  use Gettext, backend: Kati.Gettext

  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  @doc false
  @spec content(map()) :: map()
  def content(_assigns) do
    # `Kati.UI.eyebrow_label/1` rather than a second all-caps msgid. The Latin
    # line is EIGHT STATES because the design upcases it, and `String.upcase/1`
    # is a Latin operation the Arabic script has no answer to — that function's
    # own doc carries the long version. English is byte-identical either way.
    subtitle = UI.eyebrow_label(gettext("Eight states"))

    # Eight weeks is the board's own threshold, typed here for the reason the
    # moduledoc gives, and it is a measurement rather than a board number — so
    # it is interpolated and reads ۸ under `:fa`. The note under the stale card
    # states the same figure and takes it the same way.
    stale_label = gettext("Stale — more than %{n} weeks", n: Kati.Locale.number(8))

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
        {SettingsList.title(gettext("Backup & restore"), subtitle)}
        {UI.eyebrow(gettext("Never backed up — a warning, not an error"))}
        {Kati.Screens.BackupStates.never()}
        {SettingsList.eyebrow_muted(gettext("Backed up recently"))}
        {Kati.Screens.BackupStates.recent()}
        {SettingsList.eyebrow_muted(stale_label)}
        {Kati.Screens.BackupStates.stale()}
        {SettingsList.eyebrow_muted(gettext("Export not available yet"))}
        {Kati.Screens.BackupStates.export_unavailable()}
        {SettingsList.eyebrow_muted(pgettext("eyebrow", "Restoring"))}
        {Kati.Screens.BackupStates.restoring()}
        {SettingsList.eyebrow_muted(gettext("Backup from a newer Kati — refused wholly"))}
        {Kati.Screens.BackupStates.newer_version()}
        {SettingsList.eyebrow_muted(gettext("Corrupt or partial file"))}
        {Kati.Screens.BackupStates.corrupt()}
        {SettingsList.eyebrow_muted(gettext("Restore finished"))}
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
    sentence =
      gettext("You have not backed up yet. That is not a fault, only a thing not yet done.")

    body = ~MOB"""
    <Text
      text={sentence}
      text_size={12.5}
      line_height={Kati.Locale.leading(1.65)}
      text_color={Palette.cream_sub()}
    />
    """

    # `pgettext/2` for a one-word title: the catalogue already holds *Never
    # backed up*, *never checked* and *never invitee names*, and a bare `Never`
    # is exactly the size `mix gettext.merge` fuzzy-matches against any of them.
    # The context says which never this is — the answer to *when was the last
    # backup*, which is the question the card above it asks.
    card =
      Kati.Screens.BackupStates.advisory("cloud_off", pgettext("last backup", "Never"), body)

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
    label = UI.eyebrow_label(gettext("Last backup"))

    # `Kati.Settings.Sample.data/0`'s own backup row, to the day and to the
    # megabyte — that row is the thing this card is a picture of, and a second
    # date typed here would be a second answer to one question. `:short` sets
    # `14 Aug` in Latin and ۲۳ مرداد in Shamsi.
    date = Kati.Locale.date(~D[2026-08-14], :short)

    # One msgid rather than two joined by a literal `·`: the separator sits
    # between two translated runs, and a Persian reader meets the whole line as
    # one phrase. The age reuses the catalogue's existing weeks-ago plural, so
    # this sheet and screen 07's *More numbers* say it with the same words.
    meta =
      UI.eyebrow_label(
        gettext("%{ago} · %{n} MB",
          ago: ngettext("%{n} week ago", "%{n} weeks ago", 2, n: Kati.Locale.number(2)),
          n: Kati.Locale.number(214)
        )
      )

    left = ~MOB"""
    <Column weight={1.0}>
      <Text
        text={label}
        font_family={Kati.Locale.mono_face()}
        text_size={10}
        letter_spacing={Kati.Locale.tracking(0.14)}
        text_color={Palette.eyebrow()}
      />
      <Spacer size={9} />
      <Text
        text={date}
        font_family={Kati.Locale.mono_face()}
        text_size={20}
        font_weight="medium"
        letter_spacing={Kati.Locale.tracking(-0.02)}
        text_color={Palette.ink()}
        max_lines={1}
      />
      <Spacer size={6} />
      <Text
        text={meta}
        font_family={Kati.Locale.mono_face()}
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
    body_style = [
      text_size: 12.5,
      line_height: Kati.Locale.leading(1.65),
      text_color: Palette.cream_sub()
    ]

    strong = [text_size: 12.5, font_weight: "semibold", text_color: Palette.ink()]

    message =
      UI.rich_text([
        {gettext("Since then: "), body_style},
        {ngettext("%{n} title", "%{n} titles", 34, n: Kati.Locale.number(34)), strong},
        # The comma is a GLYPH rather than a word — Persian's is U+060C — and a
        # msgid of `", "` is exactly the two-character kind `mix gettext.merge`
        # fuzzy-matches against any sentence ending in one. `Kati.Locale.pick/2`
        # is what this codebase already uses where a drawing and its mirror
        # differ by a mark rather than by a phrase.
        {Kati.Locale.pick(", ", "، "), body_style},
        {ngettext("%{n} session", "%{n} sessions", 19, n: Kati.Locale.number(19)), strong},
        {pgettext("between the last two of three counts", " and "), body_style},
        {ngettext("%{n} plan", "%{n} plans", 2, n: Kati.Locale.number(2)), strong},
        {gettext(" that no backup has."), body_style}
      ])

    headline =
      Kati.Screens.BackupStates.advisory(
        "schedule",
        ngettext("%{n} week ago", "%{n} weeks ago", 11, n: Kati.Locale.number(11)),
        message
      )

    note =
      SettingsList.note(
        "info",
        gettext(
          "The threshold is %{n} weeks — long enough that a monthly habit never trips it, short enough that a lost phone costs less than a season.",
          n: Kati.Locale.number(8)
        )
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
    body_style = [
      text_size: 12.5,
      line_height: Kati.Locale.leading(1.65),
      text_color: Palette.ink_soft()
    ]

    strong = [text_size: 12.5, font_weight: "semibold", text_color: Palette.ink()]

    message =
      UI.rich_text([
        {gettext("Saving files needs a platform capability this version does not have. What it "),
         body_style},
        # Three letters, and a bare verb: the smallest msgid on the sheet and
        # the one `mix gettext.merge` would fuzzy-match against anything. The
        # context names the sentence it is emphasised inside, which is what
        # `Kati.Screens.AddByHandBook` does with its own one-word bold runs.
        # Persian carries the emphasis on می‌تواند, in the same position.
        {pgettext("emphasis in “what it can do”", "can"), strong},
        {gettext(" do is hand a section to any app that takes text."), body_style}
      ])

    header = ~MOB"""
    <Row fill_width={true} align="top">
      {UI.symbol("error", size: 19, color: Palette.red())}
      <Spacer size={11} />
      <Column weight={1.0}>
        <Text
          text={gettext("Kati can’t write a file yet")}
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
        text={gettext("Share a section as text")}
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
    progress =
      gettext("Restoring — %{done} of %{total}",
        done: Kati.Locale.number(214),
        total: Kati.Locale.number(384)
      )

    # `Books` is the section the restore is working through, and it is one msgid
    # with the estimate rather than two: `BOOKS · ABOUT A MINUTE LEFT` is a
    # single mono line, and `Kati.UI.eyebrow_label/1` supplies the caps the
    # design wants in Latin and the Arabic script has no answer to.
    section = UI.eyebrow_label(gettext("Books · about a minute left"))

    # 214 of 384 is 56%, which is the track's own 0.56 weight — see the
    # moduledoc. `Kati.Locale.number/1` for the figure and the catalogue's `%`
    # for the sign, because Persian's is U+066A ٪ and not the ASCII one; the
    # face then follows the RESULT rather than the reader, so `56%` stays in DM
    # Mono and ۵۶٪ — which DM Mono cannot draw at all — takes Vazirmatn.
    share = Kati.Locale.number(56) <> gettext("%")

    header = ~MOB"""
    <Row fill_width={true} align="center">
      <Column weight={1.0}>
        <Text
          text={progress}
          text_size={13.5}
          font_weight="bold"
          text_color={Palette.ink()}
          max_lines={1}
        />
        <Spacer size={4} />
        <Text
          text={section}
          font_family={Kati.Locale.mono_face()}
          text_size={11}
          text_color={Palette.muted()}
          max_lines={1}
        />
      </Column>
      <Spacer size={12} />
      <Text
        text={share}
        font_family={Kati.Locale.mono_face(share)}
        text_size={15}
        text_color={Palette.ink()}
        max_lines={1}
      />
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

    reassurance =
      gettext(
        "Leaving this screen is safe — the restore keeps running. Closing the app stops it, and it resumes from here."
      )

    note = ~MOB"""
    <Text
      text={reassurance}
      text_size={12}
      line_height={Kati.Locale.leading(1.6)}
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
    body_style = [
      text_size: 12.5,
      line_height: Kati.Locale.leading(1.65),
      text_color: Palette.ink_soft()
    ]

    strong = [text_size: 12.5, font_weight: "semibold", text_color: Palette.ink()]

    message =
      UI.rich_text([
        {gettext("Written by version "), body_style},
        # Neither a msgid nor `Kati.Locale.number/1`. A version is not a
        # decimal, and that function rewrites `.` as U+066B ARABIC DECIMAL
        # SEPARATOR — correct for ۷۶٫۰ and wrong for a release, which is a
        # number the reader will compare against a store listing in Latin.
        # `Kati.Locale.ltr/1` isolates each run so the `;` and the `.` that
        # follow them resolve against the number rather than against an RTL
        # page and jump to the wrong edge.
        {Kati.Locale.ltr("1.4"), strong},
        {gettext("; this device runs "), body_style},
        {Kati.Locale.ltr("1.2"), strong},
        {gettext(
           ". Nothing has been imported — a half-import is worse than none. Update Kati, then try again."
         ), body_style}
      ])

    header = ~MOB"""
    <Row fill_width={true} align="top">
      {UI.symbol("block", size: 19, color: Palette.red())}
      <Spacer size={11} />
      <Column weight={1.0}>
        <Text
          text={gettext("This file is from a newer Kati")}
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
    # 214 is the whole backup — `Kati.Settings.Sample.data/0`'s figure and the
    # one the second card prints — so the truncation is stated against the size
    # the file should have been rather than against a number of its own.
    detail =
      gettext("It ends part-way through — %{got} MB of an expected %{expected}",
        got: Kati.Locale.number(12),
        expected: Kati.Locale.number(214)
      )

    # `max_lines` differs by script, which `Kati.Locale.pick/2` exists for. This
    # is the longest second line on the sheet and it shares its row with a
    # 20pt glyph and the Retry pill; the Latin sentence just fits at 11.5pt and
    # its Persian is longer, so one line there would ellipsise away the half of
    # the sentence carrying both figures. The Latin value is untouched.
    row = ~MOB"""
    <Row fill_width={true} align="center">
      {UI.symbol("error", size: 20, color: Palette.red())}
      <Spacer size={12} />
      <Column weight={1.0}>
        <Text
          text={gettext("Couldn’t read this file")}
          text_size={13}
          font_weight="bold"
          text_color={Palette.ink()}
          max_lines={1}
        />
        <Spacer size={3} />
        <Text
          text={detail}
          text_size={11.5}
          text_color={Palette.sub()}
          max_lines={Kati.Locale.pick(1, 2)}
        />
      </Column>
      <Spacer size={12} />
      {SettingsList.action_pill(gettext("Retry"))}
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
    # The same `~D[2026-08-14]` the *Backed up recently* card draws, because
    # this is the restore OF that backup. `ngettext/4` rather than one msgid
    # with a `%{n}` in it: Persian does not inflect a noun after a numeral, so
    # both forms read the same there, and English keeps the plural it needs the
    # day a real `Kati.Backup.Restore` report supplies the figure.
    provenance =
      ngettext(
        "From %{date} · took %{n} minute",
        "From %{date} · took %{n} minutes",
        2,
        date: Kati.Locale.date(~D[2026-08-14], :short),
        n: Kati.Locale.number(2)
      )

    header = ~MOB"""
    <Row fill_width={true} align="center">
      {UI.symbol("check_circle", size: 22, color: Palette.green(), fill: true)}
      <Spacer size={12} />
      <Column weight={1.0}>
        <Text
          text={gettext("Everything came back")}
          text_size={14.5}
          font_weight="bold"
          letter_spacing={Kati.Locale.tracking(-0.015)}
          text_color={Palette.ink()}
          max_lines={1}
        />
        <Spacer size={4} />
        <Text text={provenance} text_size={11.5} text_color={Palette.sub()} max_lines={1} />
      </Column>
    </Row>
    """

    # The figures are integers now rather than strings, so the grouping and the
    # digits are one decision taken in one place — see `grouped/1`. The nouns
    # are bare because the count sits in its own 44pt column beside them, which
    # is why these are not the `%{n} title` shape the stale card uses; `titles`
    # is the catalogue's existing word, off `Kati.Backup.SampleRestore`.
    counts = [
      {grouped(418), gettext("titles")},
      {grouped(1204), gettext("history entries")},
      {grouped(64), gettext("books")},
      {grouped(35), gettext("meals")},
      {grouped(4), gettext("habits")}
    ]

    last = length(counts) - 1

    rows =
      counts
      |> Enum.with_index()
      |> Enum.map(fn {{number, label}, i} ->
        Kati.Screens.BackupStates.restored_row(number, label, i < last)
      end)

    # `80` stays inside the msgid and is written into each translation, which is
    # the call `Kati.Screens.MyServices.credit/0` already made for its own *83*:
    # a board number inside a sentence is part of the sentence, and pulling it
    # through `Kati.Locale.number/1` would leave one number written two ways to
    # keep in step. The catalogue already sets board numbers in Persian digits.
    cross_reference =
      gettext("Artwork will fill in as Kati re-fetches it. Your tokens need re-entering on 80.")

    footer = ~MOB"""
    <Column fill_width={true}>
      <Spacer size={13} />
      {SettingsList.hairline(true)}
      <Spacer size={12} />
      <Text
        text={cross_reference}
        text_size={12}
        line_height={Kati.Locale.leading(1.6)}
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
            font_family={Kati.Locale.mono_face(number)}
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

  # `1,204`, never `1204`, and ۱,۲۰۴ rather than either under `:fa`.
  #
  # Two steps that have to happen in this order. The grouping first, because
  # `Kati.Locale.number/1` deliberately converts the decimal mark and NOT the
  # group separator — its own doc gives the reason, that board 59 draws ۱,۴۸۰
  # with a Latin comma while board 115 draws ۷۶٫۰ with U+066B — so a comma
  # inserted after the digits converted would be inserted into Persian numerals
  # by a regex that only matches ASCII ones. The digits second, because that is
  # the half `Kati.Screens.Activity.entries_line/1` was missing until its own
  # fix: the line grouped correctly and then printed `1,204` in Latin numerals
  # under a Persian title.
  #
  # Written here rather than borrowed: the two existing copies —
  # `Kati.Screens.Activity`'s `delimited/1` and `Kati.Screens.Backup.group/1`
  # — are private and English-only respectively, and a reference sheet reaching
  # into another screen for a formatter would be the wrong dependency to add.
  defp grouped(n) when is_integer(n) do
    n
    |> Integer.to_string()
    |> String.reverse()
    |> String.replace(~r/(\d{3})(?=\d)/, "\\1,")
    |> String.reverse()
    |> Kati.Locale.number()
  end
end
