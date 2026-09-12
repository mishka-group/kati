defmodule Kati.Screens.AddMedication do
  @moduledoc """
  Screen 188 — Add a medication, a sheet over screen 112.

  Built to `test/design/screens/188.html`, and it is the first thing in this
  app that can put a row in `health_medications`. `Kati.Health.Medication` has
  had `create: :*` since it was written and nothing in `lib/` called it: the
  only writer that has ever existed is `Kati.Backup.Catalog`'s restore, which
  is why screen 112 draws four tablets belonging to nobody on every fresh
  install and why screen 115's dose verbs — fixed one commit ago — could not
  be checked by a person.

  ## Board 119's chassis, with one change

  Scrim, bottom sheet, close disc, centred title, DM Mono field labels, 44pt
  inset troughs, and above all **the preview band**: 119's line is *"This is
  how the row will look in the meal"* and this one's is the same sentence
  about the Schedules row. The one change is the commit: board 188 puts a 34pt
  ink **Save** pill in the header where `Kati.UI.Sheet.header/1` puts a 36pt
  hole, and draws no 54pt primary at the foot. So the header is composed here
  rather than borrowed, the way `Kati.Screens.DropSheet` and
  `Kati.Screens.RateEpisode` compose theirs — `Kati.UI.Sheet.scrim/0` and
  `Kati.UI.Sheet.close_disc/0` are still the shared pieces.

  ## The sheet scrolls, because it is taller than a phone

  Five fields, the no-times note, the preview band, the method note and the
  refusal do not fit on a 2424px screen. Bottom-anchored and unscrolled, the
  overflow goes off the TOP: on a Pixel 9a the header — the close disc, the
  title and the only Save in the sheet — was drawn half under the status bar
  and the sheet could be neither committed nor abandoned. `Kati.Screens.
  RateEpisode`'s shell is copied here and its sheet is short, so the shape was
  right for the screen it came from and wrong for this one. `<Scroll>` inside
  the bottom-aligned box is `Kati.Screens.RateAlbum`'s answer to the same
  thing, in the same round, and this is that answer.

  Found on a device and only on a device: every host check renders a tree and
  a tree has no viewport, so nothing on the host can see a sheet leave the
  screen.

  The top padding is **64 rather than the board's 18** for the same reason and
  it is the same number every pushed page in the app uses. Board 188 puts the
  header 18 below the sheet's rounded top edge, which is right while the sheet
  rests at the bottom with scrim above it. A sheet taller than the screen has
  no scrim above it: its top edge IS the top of the screen, and 18 puts the
  close disc under the status bar. `Kati.Screens.Pushed.page/2` defaults to 64
  for exactly this clearance — 18 of the board's own padding and the rest of
  the system's chrome — so this borrows the house number rather than inventing
  one.

  ## The sheet opens on a draft, and the preview is why

  `Kati.Screens.AddIngredient` opens on `Kati.Meals.SampleLibrary.draft/0` for
  a reason that applies here exactly: the bottom half of the sheet is a
  picture of the row this becomes, and a preview of nothing is not a preview.
  So `draft/0` is board 188's own values, the fields are real `<TextField>`s
  over them, and what Save writes is what the fields hold — typed or drawn.

  ## Times is a chip row and a stepper, not a clock picker

  The board decides this in as many words and the reason is #45: Mob has no
  time input, so a picker is undrawable today. `common_times/0` is the row —
  `08:00`, `13:00`, `21:00` — the dashed disc adds the next one that is not
  already set, and tapping a chip takes it off again. That is buildable now
  and a picker is not.

  ## What is translated here, and what is not

  mishka-group/kati#103. Every sentence on the sheet carries a msgid and two
  things deliberately do not: `Levothyroxine`, because a medication's name is
  what the pharmacy printed and no msgid ever reaches a stored row — see
  `draft/0` — and the clock times, because they are the write target and the
  chip tags rather than copy, so they are converted where they are DRAWN and
  nowhere else — see `@common_times` and `time_chip/2`. Board 188's own field
  labels are `Kati.Screens.MedicationDetail`'s msgids, under the same
  `medication field` context, because 188 and 189 are one brief.

  ## What Save writes, and what it refuses

  One `Kati.Health.Medication`, with `times` as set and `active: true`.
  **No dose rows**: a dose is what a day did with a prescription and
  `Kati.Health.Dose.resolve/2` is what decides it, so inventing four of them
  at create time would be the app answering *did I take it* on the user's
  behalf — the one question screen 112's own moduledoc says a wrong answer
  costs the most.

  D-59 is what makes that refusal cost nothing on the page. Screen 112 composes
  today's list from `times` — `Kati.Health.Dose.derive/2` — so a medication
  saved here appears under TODAY at its own clock times immediately, with no
  row written anywhere, and a row is created the first time somebody marks one.
  A medication saved with no times draws no dose and the page says so rather
  than falling back to a fixture, which is `Kati.Screens.Medication.nothing_due/1`.

  Save with no name refuses in words and writes nothing, which is
  `Kati.Write`'s contract and what `Kati.WriteContractTest` enforces. The
  sheet stays open and Save stays live, because a dead button explains
  nothing. `refusal/0` is that sentence, in one place, so the card the board
  draws and the message a refusal sets cannot disagree.

  ## Why the refusal card is only drawn when there is one

  The board draws the sheet in two states at once — resting, with a value in
  every trough, and refused. `Kati.ScreenDesignLiteralTest.drawn_state/0` puts
  this screen in the second for the comparison, exactly as it does for screen
  154, and `Kati.ScreenEmptyDatabaseTest` compares the resting band. Drawing
  the refusal at rest would be a sheet that opens by telling someone their
  save failed before they pressed anything.
  """

  use Mob.Screen
  use Gettext, backend: Kati.Gettext
  import Mob.Sigil

  alias Kati.Health.Medication
  alias Kati.Theme.Palette
  alias Kati.Write

  # The three clock times the stepper offers. Not a picker and not a
  # vocabulary of medicine — three times a day is what a prescription with
  # clock times in it usually says, and anything else is typed into Schedule.
  #
  # STRUCTURED, not copy, so no msgid reaches it and it stays a module
  # attribute: `add_time/1` rejects against it, `Kati.Notifications.Sources.
  # Health` arms from what it appends and `time_chip/2` builds its tag out of
  # the same string. It is converted to the reader's digits where it is DRAWN
  # — `time_chip/2` and `preview/1` — which is the rule
  # `Kati.Screens.MedicationDetail` states for `times` and screen 112's
  # `dose_row/1` applies to the clock beside a dose.
  @common_times ["08:00", "13:00", "21:00"]

  @doc """
  Board 188's own values: the draft this sheet opens on.

  THE NAME STAYS LATIN AND THE SENTENCES FOLD, which is
  `Kati.Screens.MedicationDetail.drawn_medication/0`'s split exactly and is
  made here rather than decided twice: a medication's name is whatever the
  pharmacy printed and the reader typed into `Kati.Health.Medication.name`, no
  msgid ever reaches a stored row, and a draft that transliterated would spell
  one drug two ways — Persian in the trough, Latin the moment a real row is
  read back. `dose`, `schedule` and `instruction` are the other half: they are
  the BOARD's own sentences, drawn where a row would be, and an English
  sentence is the thing mishka-group/kati#103 exists to remove.

  A function and not a `@draft` attribute, because `gettext/1` inside a module
  attribute is evaluated at COMPILE time and would freeze the sheet in
  whichever locale the compiler happened to be in.
  """
  @spec draft() :: map()
  def draft do
    %{
      name: "Levothyroxine",
      dose: gettext("50 mcg"),
      schedule: gettext("every morning, 08:00"),
      times: ["08:00"],
      instruction: gettext("before food")
    }
  end

  @doc "The clock times the dashed disc steps through."
  @spec common_times() :: [String.t()]
  def common_times, do: @common_times

  @doc """
  The sentence a nameless save is refused with.

  One function rather than two literals, because the card board 188 draws and
  the message the tap sets are the same sentence, and a second copy is a
  second thing to keep in step.
  """
  @spec refusal() :: String.t()
  def refusal, do: gettext("A medication needs a name")

  def mount(_params, _session, socket) do
    Kati.Theme.activate()
    Kati.Locale.activate()

    # AFTER `activate/0`, and that order is now load-bearing: `draft/0`'s three
    # sentences go through `gettext/1`, so resolving them into this process
    # before the locale is in it would open the sheet on English troughs for a
    # Persian reader — and Save writes what the troughs hold.
    d = draft()

    {:ok,
     socket
     |> Mob.Socket.assign(:name, d.name)
     |> Mob.Socket.assign(:dose, d.dose)
     |> Mob.Socket.assign(:schedule, d.schedule)
     |> Mob.Socket.assign(:times, d.times)
     |> Mob.Socket.assign(:instruction, d.instruction)
     |> Mob.Socket.assign(:save_error, nil)}
  end

  def render(assigns) do
    ~MOB"""
    <Box
      fill_width={true}
      fill_height={true}
      background={:background}
      layout_direction={Kati.Locale.direction_prop()}
      font_family={Kati.Locale.face_prop()}
      accessibility_id={Kati.Screens.Identity.of(__MODULE__)}
    >
      <Box fill_width={true} fill_height={true} background={Kati.UI.Sheet.scrim()} />
      <Box fill_width={true} fill_height={true} align="bottom">
        <Scroll>
          <Column
            fill_width={true}
            background={Kati.Theme.Palette.paper()}
            corner_radius={26}
            padding_left={21}
            padding_right={21}
            padding_top={64}
            padding_bottom={34}
          >
            {Kati.Screens.AddMedication.header()}
            {Kati.Screens.AddMedication.fields(assigns)}
            {Kati.Screens.AddMedication.no_times_note()}
            {Kati.UI.Eyebrow.quiet(gettext("This is how it will look"))}
            {Kati.Screens.AddMedication.preview(assigns)}
            {Kati.Screens.AddMedication.method_note()}
            {Kati.Screens.AddMedication.error(assigns[:save_error])}
          </Column>
        </Scroll>
      </Box>
    </Box>
    """
  end

  @doc """
  Close disc, centred title, Save pill.

  `Kati.UI.Sheet.header/1`'s arrangement with the 36pt hole filled in: the
  title still takes the weight between two edges, so it is centred in the
  sheet rather than in the space left beside the disc.
  """
  @spec header() :: map()
  def header do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        {Kati.UI.Sheet.close_disc()}
        <Text
          text={gettext("Add a medication")}
          weight={1.0}
          text_size={15}
          font_weight="bold"
          text_align="center"
          text_color={:on_surface}
          max_lines={1}
        />
        {Kati.Screens.AddMedication.save_pill()}
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc "The only commit on this sheet: 34pt ink, in the header where 119 keeps a hole."
  @spec save_pill() :: map()
  def save_pill do
    ~MOB"""
    <Row
      height={34}
      corner_radius={17}
      background={Palette.ink_fill()}
      padding_left={14}
      padding_right={14}
      align="center"
      on_tap={{self(), :save}}
    >
      <Text
        text={gettext("Save")}
        text_size={12.5}
        font_weight="bold"
        text_color={Palette.on_ink()}
        max_lines={1}
      />
    </Row>
    """
  end

  @doc """
  The five fields, in the order the board draws them and never another.

  The vertical order is the one thing the RTL spec pins as *not* mirroring —
  Name before Dose before Schedule before Times before Instruction, in Persian
  exactly as in English — so it is written once, here.

  The five labels carry `pgettext/2`'s `medication field` context, which is
  `Kati.Screens.MedicationDetail.prescription/1`'s: board 188 and board 189 are
  one brief and the same five words label the same five columns, so one msgid
  each rather than two that can drift. The context is what keeps them out of
  `mix gettext.merge`'s fuzzy matcher — `Name`, `Dose` and `Times` are each a
  single common word, and a bare one gets paired with any sentence that happens
  to contain it.
  """
  @spec fields(map()) :: map()
  def fields(assigns) do
    assigns = %{
      name: assigns.name,
      dose: assigns.dose,
      schedule: assigns.schedule,
      times: assigns.times,
      instruction: assigns.instruction
    }

    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.AddMedication.labelled(pgettext("medication field", "Name"), Kati.Screens.AddMedication.trough(:name, @name, "Levothyroxine"))}
      {Kati.Screens.AddMedication.labelled(pgettext("medication field", "Dose"), Kati.Screens.AddMedication.trough(:dose, @dose, gettext("50 mcg")))}
      {Kati.Screens.AddMedication.labelled(pgettext("medication field", "Schedule"), Kati.Screens.AddMedication.trough(:schedule, @schedule, gettext("every morning, 08:00")))}
      {Kati.Screens.AddMedication.labelled(pgettext("medication field", "Times"), Kati.Screens.AddMedication.time_chips(@times, :add_time, "time_"))}
      {Kati.Screens.AddMedication.labelled(pgettext("medication field", "Instruction"), Kati.Screens.AddMedication.trough(:instruction, @instruction, gettext("before food")))}
    </Column>
    """
  end

  @doc "A field under its DM Mono label, at board 119's spacing."
  @spec labelled(String.t(), map()) :: map()
  def labelled(label, body) do
    assigns = %{label: label, body: body}

    ~MOB"""
    <Column fill_width={true}>
      <Text
        text={@label}
        font_family={Kati.Locale.mono_face(@label)}
        text_size={10}
        letter_spacing={Kati.Locale.tracking(0.1)}
        text_color={Palette.muted()}
        max_lines={1}
      />
      <Spacer size={7} />
      {@body}
      <Spacer size={12} />
    </Column>
    """
  end

  @doc """
  The 44pt inset trough, with a real field in it.

  Board 157 made the only dark decision this stack needs: a trough goes
  `#2A2826` rather than inverting to card colour, so a field still reads as a
  hole rather than a raised surface. `Kati.Theme.Palette.placeholder/0` is
  that value in both modes.
  """
  @spec trough(atom(), String.t(), String.t()) :: map()
  def trough(tag, value, placeholder) do
    assigns = %{
      value: value,
      placeholder: placeholder,
      on_change: {self(), tag},
      id: Atom.to_string(tag)
    }

    ~MOB"""
    <Row
      fill_width={true}
      height={44}
      corner_radius={14}
      background={Palette.placeholder()}
      padding_left={13}
      padding_right={13}
      align="center"
    >
      <TextField
        value={@value}
        placeholder={@placeholder}
        return_key="done"
        weight={1.0}
        accessibility_id={@id}
        on_change={@on_change}
      />
    </Row>
    """
  end

  @doc """
  The chip row: one chip per set time, then the disc that adds the next.

  Each chip carries its own time in its tag, which is #97's shape — three
  chips sharing `:time` would be three nodes with one `accessibility_id`, and
  `onNodeWithTag` throws on the second match. `prefix` and `add_tag` are
  arguments because screen 189 draws the same row over the same times and the
  two screens must not share a tag namespace.

  The disc's label takes `pgettext/2` rather than a bare `gettext/1`: *Add a
  time* is three words that begin like `Add a medication` and `Add a language`,
  both of which are already msgids, and `mix gettext.merge`'s fuzzy matcher
  pairs on exactly that shape. A chip offering to add a LANGUAGE to a
  prescription is the kind of wrong that reads as deliberate.
  """
  @spec time_chips([String.t()], atom(), String.t()) :: map()
  def time_chips(times, add_tag, prefix) do
    chips =
      times
      |> Enum.map(fn at -> Kati.Screens.AddMedication.time_chip(at, prefix) end)
      |> Enum.intersperse(gap())

    assigns = %{chips: chips, add: {self(), add_tag}, lead: if(times == [], do: [], else: gap())}

    ~MOB"""
    <Row fill_width={true} align="center">
      {@chips}
      {@lead}
      <Row
        height={34}
        corner_radius={17}
        background={Palette.placeholder()}
        padding_left={13}
        padding_right={13}
        align="center"
        on_tap={@add}
      >
        {Kati.UI.symbol("add", size: 16, color: Palette.sub())}
        <Spacer size={6} />
        <Text
          text={pgettext("the dashed chip that adds a clock time", "Add a time")}
          text_size={12}
          font_weight="semibold"
          text_color={Palette.sub()}
          max_lines={1}
        />
      </Row>
      <Spacer weight={1.0} />
    </Row>
    """
  end

  @doc false
  def gap, do: ~MOB"<Spacer size={7} />"

  @doc false
  def time_chip(at, prefix) do
    # The chip is READ in the reader's digits and TAGGED with the stored ones.
    # Board 115 draws ۰۸:۰۰, ۱۴:۰۰ and ۲۱:۰۰ for the three dose cards screen
    # 112 builds out of the same list, and a chip row still reading `08:00`
    # under a Persian `ساعت‌ها` beside them would be the one Latin figure on the
    # page. `dose_row/1` converts for the same reason and calls it *a time the
    # page READ rather than one the copy quotes.*
    #
    # The tag keeps `at` untouched, which is the half that cannot move:
    # `handle_info/2` matches `"time_" <> at` and subtracts that exact string
    # from `times`, so a converted tag would be a tap that removes nothing —
    # and screen 189 takes its chips off the same way.
    #
    # `mono_face/0` and not the pinned `"mono"`: `kati_mono.ttf` carries none of
    # U+06F0–U+06F9, so `۰۸:۰۰` in DM Mono is handed to Android's own substitute
    # face. The content here is always a clock and therefore always in the
    # reader's own script, so the face follows the READER rather than the
    # string — which is `Kati.PersianFontTest`'s rule and screen 112's call.
    assigns = %{at: Kati.Locale.number(at), tap: {self(), String.to_atom(prefix <> at)}}

    ~MOB"""
    <Row
      height={34}
      corner_radius={17}
      background={Palette.ink_fill()}
      padding_left={14}
      padding_right={14}
      align="center"
      on_tap={@tap}
    >
      <Text
        text={@at}
        font_family={Kati.Locale.mono_face()}
        text_size={12.5}
        text_color={Palette.on_ink()}
        max_lines={1}
      />
    </Row>
    """
  end

  @doc """
  The quiet line under Times.

  A drawn state rather than an edge case: `Kati.Notifications.Sources.Health`
  contributes a suppressed `:no_times` candidate for a medication with none,
  precisely so *this one never reminds me* is answerable.

  Two lines of Vazirmatn at 11.5pt do not sit on Plus Jakarta's 1.5, so the
  leading goes through `Kati.Locale.leading/1` — `Kati.Theme.fa_line_height/0`
  carries the reasoning and `Kati.UI.SettingsList.note/2` asks it of the note
  band directly below this one.
  """
  @spec no_times_note() :: map()
  def no_times_note do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_left={2} padding_right={2}>
        {Kati.UI.symbol("notifications_off", size: 15, color: Palette.tertiary())}
        <Spacer size={9} />
        <Text
          text={gettext("No time set is a real answer — it is recorded and simply never reminds.")}
          text_size={11.5}
          line_height={Kati.Locale.leading(1.5)}
          text_color={Palette.sub()}
          weight={1.0}
        />
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc """
  The preview band: the two rows this draft becomes, composed by the two
  functions that already draw them.

  `Kati.Health.Medication.schedule_line/1` is screen 112's Schedules row and
  `dose_line/1` is its today card, so nothing here re-words either — which is
  the whole point of a preview: a second composer would be a second sentence
  able to disagree with the page it is previewing.

  ## The two mono slots ask two different questions

  The clock takes `Kati.Locale.mono_face/0` and the dose line takes
  `mono_face/1`, and the difference is not an oversight. A clock time is
  converted before it is drawn, so it is always in the READER's script and the
  face follows the reader. The dose line is whatever is in the troughs — the
  board's own `۵۰ میکروگرم` under `:fa`, or `500 mg` if that is what somebody
  typed on a Persian phone — so the face has to ask the STRING, which is the
  case `Kati.Locale.mono_face/1` exists for and screen 80's provider list is
  the other one. Pinning `"mono"` on either put Persian into a face with no
  glyph for it, and Android's substitute made that legible enough to ship.
  """
  @spec preview(map()) :: map()
  def preview(assigns) do
    row = row_of(assigns)

    assigns = %{
      name: row.name,
      schedule_line: Medication.schedule_line(row),
      # `Kati.UI.eyebrow_label/1` rather than `String.upcase/1`. Board 188 sets
      # the today card's dose line in DM Mono caps and the Arabic script has no
      # case at all, so upcasing `۵۰ میکروگرم · قبل از غذا` does nothing to four
      # fifths of it and mangles the rest — a no-op that reads as one. The
      # helper raises the script that has a raised form and leaves the one that
      # does not, which is what every other eyebrow in the app now does.
      dose_line: Kati.UI.eyebrow_label(Medication.dose_line(row)),
      # The clock the today card prints, in the reader's digits — the same
      # conversion `time_chip/2` above and screen 112's `dose_row/1` make, and
      # for the same reason: this is a time the page READ off `times`, not one
      # the copy quotes.
      time: Kati.Locale.number(first_time(assigns.times))
    }

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={17}
      >
        {Kati.Screens.AddMedication.band_label(pgettext("the preview band's name for screen 112's Schedules row", "Schedules row"))}
        <Row fill_width={true} align="center" padding_top={13} padding_bottom={13}>
          {Kati.UI.SettingsList.icon_tile("medication")}
          <Spacer size={13} />
          <Column weight={1.0}>
            <Text
              text={@name}
              text_size={13.5}
              font_weight="semibold"
              text_color={:on_surface}
              max_lines={1}
            />
            <Spacer size={3} />
            <Text text={@schedule_line} text_size={11.5} text_color={Palette.sub()} max_lines={1} />
          </Column>
          <Spacer size={12} />
          {Kati.UI.SettingsList.chevron()}
        </Row>
        <Box fill_width={true} height={1} background={Palette.hairline()} />
        <Spacer size={13} />
        {Kati.Screens.AddMedication.band_label(pgettext("the preview band's name for screen 112's today card", "Today card"))}
        <Row fill_width={true} align="top">
          <Text
            text={@time}
            font_family={Kati.Locale.mono_face()}
            text_size={12}
            text_color={Palette.muted()}
            width={44}
          />
          <Spacer size={12} />
          <Column
            weight={1.0}
            background={Palette.paper()}
            corner_radius={16}
            padding_left={13}
            padding_right={13}
            padding_top={11}
            padding_bottom={11}
          >
            <Text
              text={@name}
              text_size={13}
              font_weight="semibold"
              text_color={:on_surface}
              max_lines={1}
            />
            <Spacer size={4} />
            <Text
              text={@dose_line}
              font_family={Kati.Locale.mono_face(@dose_line)}
              text_size={10.5}
              text_color={Palette.muted()}
              max_lines={1}
            />
          </Column>
        </Row>
      </Column>
      <Spacer size={12} />
    </Column>
    """
  end

  @doc false
  def band_label(text) do
    assigns = %{text: text}

    ~MOB"""
    <Column fill_width={true}>
      <Text
        text={@text}
        font_family={Kati.Locale.mono_face(@text)}
        text_size={9.5}
        letter_spacing={Kati.Locale.tracking(0.1)}
        text_color={Palette.tertiary()}
        max_lines={1}
      />
      <Spacer size={11} />
    </Column>
    """
  end

  @doc """
  The draft as a `Kati.Health.Medication` struct, for the two line composers.

  A struct rather than a map because `schedule_line/1` and `dose_line/1` match
  on one, and the alternative — two more copies of *join the non-empty parts
  with a middot* — is exactly the second reader rule 4 is about. It is never
  written: `save/1` builds its own changeset from the same assigns.

  It carries no id and cannot: a preview is a picture of a row that does not
  exist yet.
  """
  @spec row_of(map()) :: Medication.t()
  def row_of(assigns) do
    # The four examples are `draft/0`'s and `fields/1`'s, msgid for msgid: the
    # trough's placeholder and the preview's fallback are the same word by
    # design — see `shown/2` — so they are the same call, and a second msgid
    # here would let the placeholder and the line under it disagree in Persian
    # while agreeing in English, which is the drift no fixture would catch.
    %Medication{
      name: shown(assigns.name, "Levothyroxine"),
      dose: shown(assigns.dose, gettext("50 mcg")),
      schedule: shown(assigns.schedule, gettext("every morning, 08:00")),
      instruction: shown(assigns.instruction, gettext("before food")),
      times: assigns.times
    }
  end

  # A preview of nothing is not a preview: an emptied trough previews the
  # board's own example rather than a blank line, and the trough's placeholder
  # says the same word underneath it.
  defp shown(value, example) do
    case String.trim(to_string(value)) do
      "" -> example
      typed -> typed
    end
  end

  defp first_time([]), do: "08:00"
  defp first_time([at | _rest]), do: at

  @doc """
  What the board says about the two things this sheet cannot do yet.

  The board numbers inside it — 119, and the ±5 of the stepper — are figures
  the COPY quotes rather than figures the page read, so they are translated
  with the sentence rather than passed through `Kati.Locale.number/1`.
  `Kati.Screens.Calendar`'s *you pick which on 32* carries its `۳۲` in the
  Persian for the same reason, and `Kati.Screens.MedicationDetail`'s
  quiet-hours row states the rule.
  """
  @spec method_note() :: map()
  def method_note do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.note("info", gettext("Times is a chip row with a stepper behind it, not a clock picker — the platform has no time input, so a picker is undrawable today and a row of common times plus ±5 minutes is buildable now. Every trough is drawn for the keyboard that does not exist yet, which is why 119’s preview band is here: what you cannot type, you can at least see."))}
      <Spacer size={12} />
    </Column>
    """
  end

  @doc """
  The refusal, in the shape board 155 established: what is missing, that
  nothing was written, and a button that is still live.
  """
  @spec error(String.t() | nil) :: map() | []
  def error(nil), do: []

  def error(message) do
    assigns = %{message: message}

    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={22}
      shadow={Kati.Theme.shadow_card_soft()}
      padding={17}
    >
      <Row fill_width={true} align="top">
        {Kati.UI.symbol("error", size: 18, color: Palette.red())}
        <Spacer size={11} />
        <Column weight={1.0}>
          <Text text={@message} text_size={13} font_weight="bold" text_color={:on_surface} />
          <Spacer size={5} />
          {Kati.Screens.AddMedication.refusal_body()}
        </Column>
      </Row>
    </Column>
    """
  end

  @doc false
  def refusal_body do
    # Two runs and therefore two msgids, because the board bolds the first half
    # and not the second and `Kati.UI.rich_text/1` styles per run. The leading
    # space on the second stays inside its msgid — that is how every other
    # split sentence in the fold carries the join, `Kati.Screens.BackupStates`'
    # `"; this device runs "` among them — so a translator sees the whole
    # fragment and the two halves cannot be pushed together.
    #
    # `nothing was written` is already the app's own phrase for this, in five
    # other refusals, so the wording is reused rather than reinvented. The
    # leading is `Kati.Locale.leading/1` for the reason `no_times_note/0` gives:
    # Vazirmatn's metrics are not Plus Jakarta's and this is a paragraph.
    Kati.UI.rich_text([
      {gettext("Nothing was written."),
       [
         font_weight: "semibold",
         text_color: :on_surface,
         text_size: 12.5,
         line_height: Kati.Locale.leading(1.6)
       ]},
      {gettext(" The sheet stays open and Save stays live — a dead button explains nothing."),
       [
         text_size: 12.5,
         line_height: Kati.Locale.leading(1.6),
         text_color: Palette.ink_soft(),
         base: true
       ]}
    ])
  end

  def handle_info({:tap, :close}, socket), do: {:noreply, Kati.Screens.Resume.pop(socket)}

  # A save that landed closes the sheet; a save that did not KEEPS IT OPEN and
  # says so — `Kati.Write`'s contract, and the reason
  # `Kati.Screens.AddIngredient` reads the same way.
  def handle_info({:tap, :save}, socket) do
    case save(socket.assigns) do
      {:ok, _medication} ->
        {:noreply,
         socket
         |> Mob.Socket.assign(:save_error, nil)
         |> Kati.Screens.Resume.pop()}

      {:error, :no_name} ->
        {:noreply, Mob.Socket.assign(socket, :save_error, refusal())}

      {:error, _reason} = error ->
        {:noreply, Mob.Socket.assign(socket, :save_error, Write.message(error))}
    end
  end

  def handle_info({:tap, :add_time}, socket) do
    {:noreply, Mob.Socket.assign(socket, :times, add_time(socket.assigns.times))}
  end

  def handle_info({:tap, tag}, socket) when is_atom(tag) do
    case Atom.to_string(tag) do
      "time_" <> at ->
        {:noreply, Mob.Socket.assign(socket, :times, socket.assigns.times -- [at])}

      _other ->
        {:noreply, socket}
    end
  end

  def handle_info({:change, field, typed}, socket)
      when field in [:name, :dose, :schedule, :instruction] and is_binary(typed),
      do: {:noreply, Mob.Socket.assign(socket, field, typed)}

  def handle_info(_message, socket), do: {:noreply, socket}

  @doc """
  The next common time not already set, appended in clock order.

  All three set is a no-op rather than a duplicate: two chips reading `08:00`
  would be two nodes with one `accessibility_id`, and
  `Kati.Notifications.Sources.Health` groups by clock time, so a repeated one
  would arm the same reminder twice.
  """
  @spec add_time([String.t()]) :: [String.t()]
  def add_time(times) do
    case Enum.reject(@common_times, &(&1 in times)) do
      [] -> times
      [next | _rest] -> Enum.sort(times ++ [next])
    end
  end

  @doc """
  Write the medication, or say why not.

  A name is the resource's one `allow_nil? false` string and the only thing
  this needs; everything else is optional, because a prescription you have not
  finished reading off the box is still one you are taking.

  No dose rows are created alongside it — see the moduledoc.
  """
  @spec save(map()) :: {:ok, Medication.t()} | {:error, term()}
  def save(assigns) do
    name = String.trim(to_string(assigns.name))

    if name == "" do
      Write.note({:error, :no_name}, "add medication")
    else
      Medication
      |> Ash.Changeset.for_create(:create, %{
        name: name,
        dose: blank_to_nil(assigns.dose),
        schedule: blank_to_nil(assigns.schedule),
        instruction: blank_to_nil(assigns.instruction),
        times: assigns.times,
        active: true
      })
      |> Ash.create()
      |> Write.note("add medication #{name}")
    end
  end

  defp blank_to_nil(value) do
    case String.trim(to_string(value)) do
      "" -> nil
      text -> text
    end
  end
end
