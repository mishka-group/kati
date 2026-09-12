defmodule Kati.Screens.MedicationEmpty do
  @moduledoc """
  Screen 190 — Medication, empty and annotated.

  Built to `test/design/screens/190.html`. Board 190 is the D-43 edit to
  screen 112 drawn as its own artboard: **the empty frame nobody had ever
  drawn**, plus the two destinations named, the reminder caption, and the
  failure line `Kati.Screens.Medication.save_notice/1` renders and no board
  showed. It is screen 27's kind of sheet — a picture of situations rather
  than a situation the app can be in — which is why it is on
  `Kati.AppReachabilityTest`'s `@no_route` beside every other states board.

  ## The empty frame is the point

  `D-19-medication.md` asked for it in 2026 and nothing drew it, so screen
  112 has printed four tablets belonging to nobody on every fresh install and
  `Kati.ScreenEmptyDatabaseTest` has held it to its own fixture. Screen 139's
  house recipe — *glyph tile, sentence, one ink action, one quiet
  alternative* — with the medication noun, and its own subtitle literal:
  `SUNDAY 16 AUGUST · NO DOSES`, because `Kati.Health.WeightSample.doses_subtitle/0`
  says `4 DOSES` and an empty page cannot print that.

  **Screen 112 itself still falls back**, and that is deliberately not changed
  here: moving it off `Kati.ScreenEmptyDatabaseTest`'s `fallbacks/0` is a
  change to the gate a live page answers to, and this commit's job was to draw
  the frame that change will be compared against. The board now exists; the
  swap is one edit away and is not this one.

  D-59 later changed WHICH question that gate asks — the medications and the
  day together, rather than the dose alone — and deliberately did not move 112
  off `fallbacks/0`: with nothing stored `Kati.Screens.Medication.doses/0` still
  answers `drawn_doses/0` term for term, so this board and the frame it is a
  picture of are untouched. `subtitle/0`'s `NO DOSES` moved in the other
  direction. Screen 112 quotes it now — through
  `Kati.Screens.Medication.count_clause/1` — for the day when medications are
  stored and none is due, so the word this board had to invent for an empty
  page is the word the live page uses for a quiet one.

  ## Both destinations are live, on this board too

  The header `add` disc and the empty card's ink pill both open
  `Kati.Screens.AddMedication`, with distinct tags because `Mob.Renderer`
  emits an `accessibility_id` from every atom tag and two controls sharing one
  is a node `onNodeWithTag` throws on. *or restore a backup* pushes
  `Kati.Screens.Restore`, which is `Kati.Screens.HomeEmpty.restore_link/0`'s
  own decision and true for the same reason: restore is the only writer of
  `health_medications` that existed before screen 188.

  ## The reminder caption counts clock times, not medications

  `SET ON EACH MEDICATION · 3 OF 4 CLOCK TIMES ARMED`, and the count is the
  one the board argues for: two tablets sharing 08:00 is **one** notification,
  because `Kati.Notifications.Sources.Health` aggregates by clock time. A
  page-level switch is deliberately absent — the switch is screen 189's, one
  per medication, and a fifth control able to disagree with four is what the
  caption exists instead of.
  """

  use Kati.Screens.Pushed, back: "Health"
  use Gettext, backend: Kati.Gettext

  alias Kati.Components.MishkaThemeIcon
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  @doc """
  The subtitle an empty medication page prints.

  Not `Kati.Health.WeightSample.doses_subtitle/0`, which is the fixture's
  `SUNDAY 16 AUGUST · 4 DOSES`: a page with nothing stored cannot count four
  doses, and a sweep cannot check a string nobody drew.

  ## Composed rather than written out — mishka-group/kati#103

  It was one literal, and a literal is the one thing this line cannot be once
  the page has a second script: `SUNDAY` is a weekday, `16 AUGUST` is a
  Gregorian date a Persian reader does not use, and `NO DOSES` is a phrase
  screen 112 now quotes. Written out again here it would have been a second
  English string to fold and, worse, a second Persian wording free to disagree
  with the live page's.

  Both halves already existed as catalogue entries, so neither is a new word.
  The date half is `Kati.Health.WeightSample.doses_subtitle/0`'s own
  *Sunday 16 August* — the DRAWING's day, not the device's, for the reason
  `Kati.Screens.Medication.subtitle/1` gives at length: dating a drawing with
  today would put a real date on a fixture. The count half is
  `Kati.Screens.Medication.count_clause/1` at zero, which is where `NO DOSES`
  moved under D-59 and is the whole point of the moduledoc's *the word this
  board had to invent for an empty page is the word the live page uses for a
  quiet one*. `Kati.UI.eyebrow_label/1` rather than `String.upcase/1` because
  Persian has no case and upcasing it is a no-op that reads as one.

  English is unchanged to the byte, which is what `medication_write_test.exs`
  compares this against.
  """
  @spec subtitle() :: String.t()
  def subtitle do
    UI.eyebrow_label(gettext("Sunday 16 August")) <>
      " · " <> Kati.Screens.Medication.count_clause(0)
  end

  @doc false
  def content(_assigns) do
    Kati.Screens.Pushed.page(
      ~MOB"""
      <Column fill_width={true}>
        {Kati.Screens.Goals.chrome()}
        {Kati.Screens.MedicationDetail.heading(gettext("Medication"), Kati.Screens.MedicationEmpty.subtitle())}
        {Kati.Screens.MedicationEmpty.empty_card()}
        {Kati.Screens.MedicationEmpty.subtitle_note()}
        {Kati.UI.eyebrow(gettext("The two destinations, named"))}
        {Kati.Screens.MedicationEmpty.destinations()}
        {Kati.Screens.MedicationEmpty.destinations_note()}
        {Kati.UI.Eyebrow.quiet(gettext("The reminder caption"))}
        {Kati.Screens.MedicationEmpty.reminder_caption()}
        {Kati.Screens.MedicationEmpty.caption_note()}
        {Kati.UI.Eyebrow.quiet(gettext("The failure line, where it renders"))}
        {Kati.Screens.MedicationEmpty.failure_line()}
      </Column>
      """,
      # 64, not `content_top/0`: this page opens with screen 104's chrome row
      # exactly as screen 112 does, and 112 has always started at the board's
      # own 64 with the floating pill overlapping the right-aligned disc's
      # empty half. A board that is a redraw of 112 starts where 112 starts.
      64
    )
  end

  @doc "Screen 139's recipe with the medication noun: tile, sentence, one ink action, one quiet alternative."
  @spec empty_card() :: map()
  def empty_card do
    # The heading's `-.02em` and the sentence's 1.55 leading both go through
    # `Kati.Locale` rather than staying pinned. Tracking is a Latin effect —
    # `Kati.Locale.tracking/1` carries the argument — and on Persian it does
    # worse than nothing: it pulls apart the joins between letters that are
    # supposed to be joined. Leading goes the other way, because Vazirmatn's
    # ascenders and its dots need more room than DM Sans at the same size, and
    # `Kati.UI.SettingsList.note/2` right below this card already asks for
    # `Kati.Locale.leading/1` — two paragraphs of the same page set at two
    # different leadings is the visible half of the defect.
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={17}
        align="center"
      >
        <Spacer size={12} />
        {Kati.Screens.MedicationEmpty.tile()}
        <Spacer size={16} />
        <Text
          text={gettext("No medications yet")}
          text_size={16}
          font_weight="bold"
          letter_spacing={Kati.Locale.tracking(-0.02)}
          text_align="center"
          text_color={:on_surface}
        />
        <Spacer size={8} />
        <Text
          text={gettext("Add one and its doses appear here each day, in clock order.")}
          text_size={12.5}
          line_height={Kati.Locale.leading(1.55)}
          text_align="center"
          text_color={Palette.sub()}
        />
        <Spacer size={18} />
        {Kati.Screens.MedicationEmpty.add_pill()}
        <Spacer size={15} />
        {Kati.Screens.MedicationEmpty.restore_link()}
        <Spacer size={12} />
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc "The 60pt paper square, at `Kati.Screens.HomeEmpty.tile/0`'s own recipe."
  @spec tile() :: map()
  def tile do
    MishkaThemeIcon.theme_icon(
      %{variant: :filled, color: Palette.paper(), size: 60, radius: 19},
      [UI.symbol("medication", size: 27, color: Palette.rail_idle())]
    )
  end

  @doc "The one ink action on the board. `:add_first`, so it does not share the header disc's name."
  @spec add_pill() :: map()
  def add_pill do
    ~MOB"""
    <Box
      fill_width={true}
      height={44}
      corner_radius={22}
      background={Palette.ink_fill()}
      align="center"
      on_tap={{self(), :add_first}}
    >
      <Text
        text={gettext("Add a medication")}
        text_size={13}
        font_weight="bold"
        text_color={Palette.on_ink()}
        max_lines={1}
      />
    </Box>
    """
  end

  @doc "The quiet alternative, wired the way `Kati.Screens.HomeEmpty.restore_link/0` is."
  @spec restore_link() :: map()
  def restore_link do
    ~MOB"""
    <Column fill_width={true} on_tap={{self(), :restore_backup}}>
      <Text
        text={gettext("or restore a backup")}
        text_size={12.5}
        font_weight="semibold"
        text_align="center"
        text_color={Palette.sub()}
      />
    </Column>
    """
  end

  @doc false
  def subtitle_note do
    # The three phrases this note QUOTES — the subtitle, the fixture's count and
    # the quiet link — are translated inside the Persian rather than
    # interpolated from `subtitle/0` and `restore_link/0`. That is
    # `Kati.Screens.MedicationDetail.reminder/1`'s rule and its reason: a figure
    # the page READ is converted, a figure the copy QUOTES is translated with
    # the copy. Interpolating here would also make the note's Persian depend on
    # a word order Persian does not have — the sentence has to be able to put
    # the quotation where Persian wants it.
    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.note("info", gettext("SUNDAY 16 AUGUST · NO DOSES is a literal that has to be drawn — the fallback prints 4 DOSES from a fixture, and an empty page cannot say that. or restore a backup is true: restore is the only writer that exists today."))}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc "The two controls screen 112 has drawn and inert since it shipped, and where each now goes."
  @spec destinations() :: map()
  def destinations do
    rows = [
      SettingsList.row(
        # `add` is a plus and a plus is symmetric, so it is the same glyph in
        # both scripts and stays written out.
        SettingsList.icon_tile("add"),
        SettingsList.body(
          gettext("Header add disc"),
          gettext("Opens 188 — drawn and inert since the page shipped"),
          lines: 2
        ),
        nil
      ),
      SettingsList.row(
        # The chevron in this tile is not a control, it is a PICTURE of the one
        # on screen 112's Schedules row — and that one is
        # `Kati.UI.SettingsList.chevron/0`, which has asked
        # `Kati.Locale.forward_chevron/0` since #103 and therefore points left
        # under `:fa`. Pinned to `chevron_right` this row would name a glyph
        # facing the other way from the glyph it is naming, on a page whose own
        # sub-line says *the chevron was always honest*.
        SettingsList.icon_tile(Kati.Locale.forward_chevron()),
        SettingsList.body(
          gettext("Each Schedules row"),
          gettext("Opens 189 — the chevron was always honest"),
          lines: 2
        ),
        nil,
        rule: false
      )
    ]

    assigns = %{rows: rows}

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.card(@rows)}
      <Spacer size={11} />
    </Column>
    """
  end

  @doc false
  def destinations_note do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.note("info", gettext("Not new affordances — both are drawn, reachable and inert today, and the tap sweep lists all five by name. This brief gives them somewhere to go."))}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  Screen 112's reminder picture with the caption it lacked.

  The bubble is `Kati.Health.WeightSample.reminder/0`'s own two lines, drawn
  and inert here as they are there, and the DM Mono line under it is the new
  copy: a statement of where the switch lives, not a switch.

  ## The two lines inside the bubble are not this file's to word

  `@title` and `@body` come back from `Kati.Health.WeightSample.reminder/0`,
  and they stay that module's literals for exactly
  `Kati.Screens.MedicationDetail.preview/1`'s reason: a preview that worded its
  own sentence would be a second sentence able to disagree with the one screen
  112 draws beside it. The consequence under `:fa` is that *Magnesium — 200 mg*
  and *With water, before bed* arrive in English until that module folds.
  Wording them again here to make this page read is the exact duplication the
  arrangement exists to prevent, and `caption_note/0` quotes the second of them
  by name, so the two would then disagree in print as well.
  """
  @spec reminder_caption() :: map()
  def reminder_caption do
    r = Kati.Health.WeightSample.reminder()

    # **KATI** is the app's name and stays Latin in both scripts — board 127
    # draws `Lumen+` in Latin on a Persian page for the same reason — and the
    # clock beside it converts, because it is a time the card DRAWS rather than
    # one the copy quotes. That is the split
    # `Kati.Screens.MedicationDetail.preview/1` makes on this very line, and the
    # consequence is the same: the string changes script with the reader, so its
    # face has to ask the STRING rather than be pinned. `KATI · 08:00` is DM
    # Mono and `KATI · ۰۸:۰۰` is not, because `kati_mono.ttf` carries no
    # U+06F0–U+06F9 and Android would substitute a face that is not Kati's.
    #
    # 08:00 and not `r.app`'s 21:00: this board's whole caption argues about two
    # tablets sharing 08:00, and a bubble stamped 21:00 over it would be the
    # picture disagreeing with the sentence under it.
    eyebrow = "KATI · " <> Kati.Locale.number("08:00")

    # The caption's two figures go through `Kati.Locale.number/1` rather than
    # being written into the sentence, because they are what the caption COUNTS
    # — the board's own 3 clock times of 4 — and a reader counting Latin digits
    # in a Persian sentence is reading someone else's page. The noun after a
    # numeral does not inflect in Persian, so there is no plural to agree with.
    #
    # `Kati.UI.eyebrow_label/1` rather than writing the line out in capitals:
    # this is an eyebrow, English wants it upcased, and Persian has no case, so
    # `String.upcase/1` on Vazirmatn is a no-op that reads as one.
    caption =
      UI.eyebrow_label(
        gettext("Set on each medication · %{armed} of %{total} clock times armed",
          armed: Kati.Locale.number(3),
          total: Kati.Locale.number(4)
        )
      )

    assigns = %{title: r.title, body: r.body, eyebrow: eyebrow, caption: caption}

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={17}
      >
        <Column fill_width={true} background={Palette.card_settled()} corner_radius={20} padding={14}>
          <Text
            text={@eyebrow}
            font_family={Kati.Locale.mono_face(@eyebrow)}
            text_size={9.5}
            letter_spacing={Kati.Locale.tracking(0.1)}
            text_color={Palette.eyebrow()}
            max_lines={1}
          />
          <Spacer size={9} />
          <Text
            text={@title}
            text_size={13.5}
            font_weight="bold"
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={5} />
          <Text text={@body} text_size={12.5} text_color={Palette.sub()} max_lines={1} />
        </Column>
        <Spacer size={12} />
        <Text
          text={@caption}
          font_family={Kati.Locale.mono_face(@caption)}
          text_size={10}
          letter_spacing={Kati.Locale.tracking(0.1)}
          text_color={Palette.muted()}
        />
      </Column>
      <Spacer size={11} />
    </Column>
    """
  end

  @doc false
  def caption_note do
    # *With water, before bed* is quoted here in the reader's own script even
    # though the bubble above still draws it in English — see
    # `reminder_caption/0` for why that line is not this file's to word. The
    # note is an ARGUMENT about the copy, and an argument a Persian reader
    # cannot read is not an argument; `Kati.Screens.MedicationDetail`'s
    # aggregation note made the same call for `3 doses` and says so. The two
    # agree again the moment `Kati.Health.WeightSample` folds.
    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.note("info", gettext("Not a switch — the switch is on 189, one per medication, and a page-level one would be a fifth thing that can disagree with the four. The count is clock times armed, not medications with times, because two tablets sharing 08:00 is one notification. And the caption resolves the body mismatch: 112’s drawn With water, before bed is the caption to redraw — the composed dose · instruction is the target."))}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  Where `Kati.Screens.Medication.save_notice/1` renders, drawn at last.

  Between the list it failed to change and the two verbs that were just
  pressed. The pair below it carry no `on_tap`: this is a picture of screen
  112's controls, and tapping a picture of a verb is not recording a dose.

  All three literals here are the LIVE ones' own msgids and not new copy:
  *Nothing to save yet.* is `Kati.Write.message/1`'s and *Taken* / *Skip* are
  `Kati.Screens.Medication`'s. A picture of a control has to say what the
  control says, so the picture asks the catalogue the same question rather than
  minting a second entry able to drift from it — which is the same argument
  `reminder_caption/0` makes for NOT wording the bubble, read from the other
  end: there the sentence belongs to another module, here the msgid does.
  """
  @spec failure_line() :: map()
  def failure_line do
    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={22}
      shadow={Kati.Theme.shadow_card_soft()}
      padding={17}
    >
      <Text
        text={gettext("Nothing to save yet.")}
        text_size={12.5}
        font_weight="semibold"
        text_color={Palette.red()}
      />
      <Spacer size={13} />
      <Row fill_width={true} align="center">
        <Row
          weight={1.0}
          height={36}
          corner_radius={18}
          background={Palette.ink_fill()}
          align="center"
        >
          <Spacer weight={1.0} />
          <Text
            text={gettext("Taken")}
            text_size={12.5}
            font_weight="semibold"
            text_color={Palette.on_ink()}
            max_lines={1}
          />
          <Spacer weight={1.0} />
        </Row>
        <Spacer size={9} />
        <Row weight={1.0} height={36} corner_radius={18} background={Palette.paper()} align="center">
          <Spacer weight={1.0} />
          <Text
            text={gettext("Skip")}
            text_size={12.5}
            font_weight="semibold"
            text_color={Palette.ink_soft()}
            max_lines={1}
          />
          <Spacer weight={1.0} />
        </Row>
      </Row>
    </Column>
    """
  end

  @impl true
  def handle_tap(tag, socket) when tag in [:add, :add_first],
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.AddMedication)}

  def handle_tap(:restore_backup, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Restore)}

  def handle_tap(_tag, socket), do: {:noreply, socket}
end
