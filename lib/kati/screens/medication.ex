defmodule Kati.Screens.Medication do
  @moduledoc """
  Screen 112 — Medication, pushed under Health.

  ## Drawn with the honesty note accepted rather than the tile retired

  The design's caption. The tile could have been dropped — a medication tracker
  is the kind of feature an app ships and then regrets — and instead it ships
  with the two claims it has to make written plainly on the page:

    * *Reminders can arrive late if the phone is restricting alarms to save
      battery, so treat them as a nudge and not a guarantee.* Android's
      `AlarmManager` is best-effort under Doze, and an app that implied
      otherwise about a medication reminder would be making a promise it cannot
      keep about something that matters.
    * *Kati is not a medical device and gives no medical advice — it only
      records what you tell it.*

  Neither is small print. Both are `info` rows in the flow of the page.

  ## Doses reuse screen 43's meal cards exactly

  Taken, missed and skipped are the same three states as eaten, skipped and
  upcoming, and the caption says so. Deliberately parallel vocabulary: a person
  reading both pages should not have to learn two systems for *did this
  happen*.

  ## The reminder is drawn as the notification it becomes

  Because its three actions — Taken, Skip, Snooze — are the whole reason
  arming it is worth anything, and a user deciding whether to turn it on needs
  to see them before they do.

  ## A dose that did not record says so

  `Taken` and `Skip` used to end in an `Ash.update/2` whose result went
  nowhere, under a `rescue` that caught nothing — `Ash.update/2` returns
  `{:error, changeset}` rather than raising. The page then re-read the day and
  redrew either way, so a decision that landed and one that vanished dismissed
  to identical pixels. On a fresh install they still would: this page draws the
  drawing's four doses whatever the store holds, and none of the four is a row
  anything can be written against.

  Which is the case that matters most here. A medication page whose caption
  already refuses to promise a reminder must not silently pretend to have
  recorded a dose — of everything in this app, *did I take it* is the question
  a wrong answer costs the most. So `save_dose/2` hands back the tuple,
  `save_notice/1` draws the failure above the two buttons, and the list is
  re-read only when there is something new to read.

  ## The dose that changes is the dose you touched

  And that was the half still missing. Every control on this page — four rows
  and two verbs — carried one of two shared tags, and the write behind them
  re-queried the day and took the head of whatever came back. Three things were
  wrong with that at once, and only the third is visible in a screenshot:

    * **The row you tapped was not the row that changed.** Tapping the 21:00
      card marked the 14:00 one, because the query answered first-undecided and
      the tap carried no clue which card had been pressed. #84's rule, one
      screen over: *act on the row you were handed, not on the head of a
      re-query.*
    * **Four rows shared one name.** `Mob.Renderer` emits `accessibility_id`
      from the tag, so `:toggle_dose` on four cards is four nodes called the
      same thing — `onNodeWithTag` throws on the second match rather than
      picking one, and a screen reader announced four identical controls.
      `Kati.ScreenTapSweepTest`'s own duplicate-id check names this exact fix.
    * **The re-query could answer differently from the page.** A dose recorded
      on another screen between draw and tap moves the head, so the verbs would
      land somewhere the user was not looking.

  So `tags/1` builds a row's three tags out of the row's own id, `doses/0` and
  `drawn_doses/0` carry them, and `handle_tap/2` resolves a tag **against the
  doses already on the socket** rather than parsing an id back out of it —
  `Kati.Screens.Goals` fixed the same defect the same way, and the reason to
  resolve rather than parse is that nothing can then name a row that is not on
  the screen.

  The drawing's four keep `id: nil` and are tagged by position, which for a
  fixture is identity. Tapping one answers `Nothing to save yet.` rather than
  moving a tick: screen 104 flips its drawn switch in place and is right to,
  because a repeat toggle that lies costs a redrawn switch — here the same
  courtesy would be the app telling someone they had taken a tablet.

  ## The `add` disc and the four chevrons open something now

  Both were drawn, reachable and inert from the day this page shipped, and
  `Kati.ScreenTapSweepTest` listed all five by name with the reason: *neither
  a new-medication sheet nor a per-medication page is drawn anywhere in the
  artboards*. D-43 drew both. `add` opens `Kati.Screens.AddMedication` — the
  first writer of `health_medications` in `lib/` — and a Schedules row opens
  `Kati.Screens.MedicationDetail` **for the row this render drew**, resolved
  by rebuilding each row's own tag rather than by re-reading the day. That is
  the same rule the doses above them follow and for the same reason: nothing
  can then name a medication that is not on the screen.

  So `schedules/0` carries `:id` on a stored row and omits it entirely on the
  drawing's four, which is what lets the sheet tell *the row you tapped* from
  *a row nobody named*.

  ## One page, one question, and today's doses are composed — D-59

  This page used to have two gates asking different questions. `schedules/0`
  asked whether a `Kati.Health.Medication` was stored; `doses/0` and
  `subtitle/1` asked whether a `Kati.Health.Dose` was. Two tables — and until
  board 188 shipped, nothing in `lib/` could write either of them outside a
  backup restore, so the two questions had the same answer on every device that
  had ever existed and the split was invisible.

  188 changed the first answer and not the second. A medication typed on a
  Pixel 9a came back to a page reading `SUNDAY 16 AUGUST · 4 DOSES`, four
  tablets under TODAY belonging to nobody — one of them an Iron marked MISSED —
  and under SCHEDULES the single row the person had just written. One page
  saying in three places at once that you take four medications and that you
  take one, answering somebody's first act of owning a prescription with three
  prescriptions they have never heard of.

  So there is one question now — `day/0`, *does the reader own a prescription,
  which of them are they still taking, and what has today already recorded?* —
  asked once by `load/1` and handed to all three bands. `doses/1`, `schedules/1`
  and `reminder/1` take the tuple rather than each asking for their own, which
  is what makes *asked once* a property of the code: they were three
  independent pairs of reads at three instants until the tuple started being
  passed, and a medication paused between two of them gave exactly the
  reader's-half-beside-the-drawing's-half page this ticket exists to remove.
  `subtitle/1` asks nothing at all: it compares the list it was handed with
  `drawn_doses/0`, so the header cannot disagree with TODAY. Screen 20's rule,
  which `Kati.ScreenEmptyDatabaseTest` writes down: *either every value on the
  page is this reader's or every value is the drawing's.*

  **The gate is the medication ROW and not the active one**, which is the
  second round of the same defect. `{Health.active(), stored_doses()}` answers
  `{[], []}` for somebody who owns one prescription and has paused it —
  screen 189's *Stop taking*, two taps from here — and handed that reader the
  whole fixture back: four tablets they never took, an Iron marked MISSED, a
  header counting four. `day/0`'s first element is *do you own any medication at
  all*, so an all-paused page is theirs and quiet rather than somebody else's
  and full. See the `t:day/0` typedoc.

  **All four bands, not three.** The reminder card was
  `Kati.Health.WeightSample.reminder/0` unconditionally until `reminder/1`, so a
  page whose header, TODAY and SCHEDULES had all become the reader's still drew
  a 21:00 Magnesium under an eyebrow. It is composed from
  `Kati.Notifications.Sources.Health` now — the same source that arms the real
  one — and absent when nothing is armed.

  **Today's doses are DERIVED, and a row is written when you decide.** D-59
  chose between composing the day from each medication's `times` and
  materialising rows on a day boundary, and took the first:
  `Kati.Notifications.Sources.Health` arms the reminder from `times` and
  nothing else, so `times` is already this app's answer to *what is due today*,
  and a second source for one question is how a page comes to disagree with
  itself — which is the defect being fixed. `Kati.Health.Dose.derive/2` and
  `merge/2` hold the composition and the argument for it; `save_dose/2`'s
  middle clause is what turns a derived dose into a row, the first time
  somebody marks one.

  What that leaves is a state nobody had drawn: **medications stored and
  nothing due today**, which board 188 hands a person the moment they save a
  prescription with no clock times on it. `today/3`'s empty clause is where
  that is answered, and `nothing_due/1` is the sentence.

  ## `:mark_taken` and `:mark_skipped` survive, and only screen 115 uses them

  Screen 115 is this page in Persian and draws its two verbs inside the due
  card, with `Kati.Screens.HealthFa.doses/0` behind them — a list that keeps
  the name, the line and the state and drops the id. So its chips have no row
  in them to act on, and they come through `handle_tap/2` here to reach
  `next_undecided/1`, which is what they have always reached. They are the
  identity-less door, kept working rather than quietly broken; wiring them
  properly means giving 115's own list ids, which is 115's change.

  D-59 moved what is behind that door without moving the door.
  `next_undecided/1` used to re-read `health_doses` at tap time, which on a day
  whose doses are derived answers nothing at all — both chips would have
  reported *Nothing to save yet.* to every person with a medication. It resolves
  `undecided/1` **against the socket the tap arrived on**, which is the list
  that screen drew, so the chips and the buttons cannot pick different doses and
  no re-query at tap time can move the row out from under them.
  """

  use Kati.Screens.Pushed, back: "Health"

  alias Kati.Health.Dose
  alias Kati.Health.Medication
  alias Kati.Health.WeightSample
  # The NOTIFICATION source, not the domain. `active/0` there is the reader
  # both gates on this page go through, so the list the reminder is armed from
  # and the list the page draws are one read — which is D-59's whole argument.
  # `Kati.Screens.MedicationDetail` already aliases it this way for `title/1`
  # and `body/1`, and nothing in this file refers to `Kati.Health` bare.
  alias Kati.Notifications.Sources.Health
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList
  alias Kati.Write

  # ONE `day/0` per render, handed to all three bands — see the moduledoc's
  # *asked once*, which was a claim about this line and was not true of it
  # until the tuple started being passed. `doses/0` and `schedules/0` each
  # asked it for themselves, so a mount issued two independent pairs of reads
  # and the page's own comments argued an invariant the code did not have.
  def load(socket) do
    day = day()

    socket
    |> Mob.Socket.assign(:doses, doses(day))
    |> Mob.Socket.assign(:schedules, schedules(day))
    |> Mob.Socket.assign(:reminder, reminder(day))
    |> Mob.Socket.assign(:save_error, nil)
  end

  @typedoc """
  The one question this page asks: *does the reader own a prescription at all,
  which of them are they still taking, and what has today already recorded?*

  Three parts rather than two, and the first is D-59's second round. The gate
  used to be `{Health.active(), stored_doses()}`, which asks whether anything is
  ACTIVE — and screen 189's *Stop taking* is two taps from here. A person who
  owns one medication and has paused it, with nothing recorded today, answered
  `{[], []}` and got the whole fixture back: four tablets they never took, an
  Iron marked MISSED, and a header counting four. That is the exact page D-59
  was filed against, reached from the opposite direction.

  So *whose page is this* is answered by whether a `Kati.Health.Medication` row
  exists, and *what is on it* is answered by the active ones. An all-paused
  reader gets their own quiet day and no Schedules band at all — rule 5's
  *there is nothing to say, so nothing says it* — rather than somebody else's
  four prescriptions.
  """
  @type day :: {boolean(), [Medication.t()], [Dose.t()]}

  @doc """
  Today's doses — the reader's, composed from their own schedules, or the
  drawing's four.

  D-59, and the moduledoc carries the argument. Three things about this that
  the rest of the page turns on:

    * **One gate, `day/0`, for the whole page.** The fixture is drawn only when
      the reader owns no medication at all AND nothing was recorded today.
      `schedules/1` and `reminder/1` are handed the SAME tuple by `load/1`, so
      the three bands cannot answer differently about whose data this is —
      not merely *do not, in the tests we happened to write*.
    * **It can answer `[]`, and could never do so before.** The old gate made an
      empty list unreachable, because `[]` meant *fall back*. It now means the
      one thing this page could not say: *you have medications and none of them
      is due today* — which is every medication saved on board 188 without a
      clock time on it, every day of a Mon/Wed/Fri tablet whose schedule
      sentence Kati deliberately does not parse, and every day of a hospital
      stay somebody has paused all of them for. `today/3` words that state.
    * **Derived and stored rows go through ONE shaper.** `shape/2` builds both,
      so `dose_row/1` reads the four keys it always read and cannot tell them
      apart. Two branches shaping two lists is two pieces of code that can
      disagree about what a dose is, which is the defect one level up.

  The zero-arity head is kept for the callers that ask this page one question
  and hold no tuple — `Kati.ScreenEmptyDatabaseTest`'s screen-112 pair and
  `Kati.Screens.HealthFa.doses/0`.
  """
  @spec doses() :: [map()]
  @spec doses(day()) :: [map()]
  def doses(day \\ day())

  def doses({false, [], []}), do: drawn_doses()

  def doses({_owned, medications, stored}) do
    now = Kati.Time.now()

    stored
    |> Dose.merge(Dose.derive(medications, Kati.Time.today()))
    |> Enum.map(&shape(&1, now))
  end

  # The one question this page asks — see the `t:day/0` typedoc for what the
  # three parts are and why the first one is there. `load/1` asks it once and
  # hands the tuple to all three bands.
  #
  # `Kati.Notifications.Sources.Health.active/0` rather than a second
  # `Ash.Query.for_read(:active)` here — it already rescues to `[]`, already
  # sorts by name, and is already what arms the reminder, so the page and the
  # notification are reading one list. That is D-59's argument rather than
  # deduplication: there is now no second place that could be given a different
  # filter, a different sort or a different error branch, which is exactly how
  # the two gates on this page came to disagree.
  defp day, do: {owns_medication?(), Health.active(), stored_doses()}

  # The three fixture heads above match `{false, [], []}` and not
  # `{false, _active, []}`, and the difference is a page. Each of the three
  # reads has its own failure path — `owns_medication?/0` has an `_other` and a
  # `rescue`, `Kati.Notifications.Sources.Health.active/0` has its own, and
  # neither consults the other — so `{false, [%Medication{}, …], []}` is a
  # reachable tuple: the cheapest read of the three fails transiently while the
  # list comes back full. Under the looser head that tuple drew four
  # prescriptions the reader never typed, which is the page this whole ticket
  # is against. Under this one it falls through to the composing clause and
  # draws the list `active/0` actually returned.

  # Whether the reader owns a prescription AT ALL, paused or not. One row is
  # the whole question, so one row is what is read: this decides whose page it
  # is and never what is drawn on it, and a list read here would be a second
  # list able to disagree with `Health.active/0` about names, order or
  # emptiness.
  defp owns_medication? do
    Medication
    |> Ash.Query.limit(1)
    |> Ash.read()
    |> case do
      {:ok, [_row | _rest]} -> true
      _other -> false
    end
  rescue
    _error -> false
  end

  # One row, stored or derived, in the shape the list draws. `time`, `name`,
  # `line` and `state` are byte-identical to what the old stored branch built,
  # so `dose_row/1` and `Kati.Health.Medication.dose_line/1` are untouched.
  #
  # The three new keys are what a WRITE needs to name a row that is not a row
  # yet: `save_dose/2`'s create clause takes the medication and the day off the
  # row the page drew, never off the clock at tap time.
  defp shape(%Dose{} = dose, now) do
    Map.merge(
      %{
        time: dose.due_at,
        name: dose.medication.name,
        line: Medication.dose_line(dose.medication),
        state: Dose.resolve(dose, now),
        id: dose.id,
        medication_id: dose.medication_id,
        due_on: dose.due_on,
        due_at: dose.due_at
      },
      tags(key(dose))
    )
  end

  # A stored row is named by its id; a derived one by the medication and the
  # clock time it was composed from — see `tags/1` for why that family is
  # bounded and why the colon comes out.
  defp key(%Dose{id: id}) when is_binary(id), do: id

  defp key(%Dose{id: nil, medication_id: medication_id, due_at: at}),
    do: medication_id <> "_" <> String.replace(at, ":", "")

  @doc """
  The drawing's four doses, unconditionally — each with `id: nil`.

  Built through the same merge a stored dose goes through, so the
  empty-database gate still compares `doses/0` with this term for term, and
  `subtitle/1` compares the list it is handed against this one to decide whose
  drawing it is looking at.

  **`id: nil` is no longer the whole of what separates them, and D-59 is why.**
  A derived dose carries `id: nil` too — it is a real dose of the reader's that
  has no row yet — so what stops a write is the ABSENCE of `:medication_id`
  rather than a nil id. `save_dose/2`'s create clause matches
  `%{id: nil, medication_id: m}` with `is_binary(m)`, and these four rows have
  no `:medication_id` key at all, so they fall to the refusal clause.

  Absence rather than a `nil`, which is this domain's rule for exactly this
  question — `Kati.Screens.MedicationDetail`'s schedule rows put it plainly:
  *a fixture row that carries a `nil` id is a row a write can be handed.
  Absence is the whole signal.* So a fixture row must never gain a
  `:medication_id` key; `Kati.ScreenWriteTargetTest` is what exists to catch it
  if one does.
  """
  @spec drawn_doses() :: [map()]
  def drawn_doses do
    WeightSample.doses()
    |> Enum.with_index(1)
    |> Enum.map(fn {dose, position} ->
      dose |> Map.put(:id, nil) |> Map.merge(tags("drawn_#{position}"))
    end)
  end

  @doc """
  A dose's three tap tags, named after the dose rather than after the control.

  Atoms rather than `{:dose, id}` tuples for the reason
  `Kati.Screens.ImportSources.tag/1` sets out at length: `Mob.Renderer` emits
  `accessibility_id` only for the `is_atom(tag)` clause, so a tuple-tagged card
  fires on the device and is invisible to every sweep and unnamed to a screen
  reader.

  Three, because a dose has three ways of being decided about — its own card,
  and the two verbs that sit under the list — and all three have to name the
  same row. The id rather than the row's position: `:for_day` sorts by clock
  time, so a dose's position moves the moment another medication is taken at
  09:00, and a tag that moves names a different dose tomorrow.

  The drawing's rows have no id and cannot borrow one, so they take
  `"drawn_1"`..`"drawn_4"` — held in the same `dose_` namespace so one
  `handle_tap/2` reads both, and distinct from each other so the four cards on
  a fresh install stop sharing one `accessibility_id`.

  `String.to_atom/1` on a uuid is the shape screens 98, 03 and 104 already use,
  and doses are the one place worth saying why it is still safe: this is the
  only family in the app that grows every day rather than every time the user
  adds something. Three atoms per dose and a handful of doses a day is a few
  thousand a year against a table of a million, and the atoms are only ever
  built for the doses of **one** day — `:for_day` never reads a second.

  ## The third namespace, and why it is the smallest of the three — D-59

  There are three keys now, not two, because a dose can be the reader's without
  being a row: `<uuid>` for a stored dose, `<medication_id>_<hhmm>` for one
  derived from a schedule, and `drawn_1`..`drawn_4` for the drawing's.

  `<medication_id>_<hhmm>` is `:dose_5f3a…_0800` — the medication's uuid, an
  underscore, and the clock time with its colon taken out. Bounded three ways,
  and the third is the one that matters: the uuid half is the same family the
  paragraph above already justifies, one per medication the reader stores; the
  clock half reaches `String.to_atom/1` only after `Kati.Health.Dose.clock?/1`
  has accepted it, so it is at most 1440 values and in practice the
  medication's own `times`; and the key carries **no date at all**, so unlike a
  dose id this family does not grow with the calendar. It is strictly smaller
  than the one argued safe above — bounded by the medications the reader owns,
  forever.

  The colon comes out for `Kati.Notifications.Sources.Health.id/1`'s reason,
  which is worth taking rather than restating differently: this app already
  writes a clock time into an identifier one way, and *an id that can be built
  two ways from two identities is an id that can collide.*

  The three namespaces are pairwise disjoint, and by construction rather than
  by convention: a uuid contains no underscore, `drawn` is not a uuid, and
  `0800` is neither `taken` nor `skip`.

  **A row's tag CHANGES the moment it materialises.** `dose_<med>_0800` becomes
  `dose_<uuid>` on the redraw after the first write against it, and that is
  fine here for the same reason nothing parses an id out of an atom:
  `handle_tap/2` resolves a tag against the doses on the socket, which are
  always the ones this render drew. It is not fine for a device test pinned to
  a derived tag across a tap, which is why it is written here.
  """
  @spec tags(String.t()) :: %{tap: atom(), taken: atom(), skip: atom()}
  def tags(key) when is_binary(key) do
    %{
      tap: String.to_atom("dose_" <> key),
      taken: String.to_atom("dose_" <> key <> "_taken"),
      skip: String.to_atom("dose_" <> key <> "_skip")
    }
  end

  @doc """
  The schedules: what is stored, or the drawing's four.

  Takes the tuple `doses/1` was handed — `load/1` asks `day/0` once and gives
  it to both — so the two bands cannot drift. That is D-59: this gate used to
  ask only about medications while TODAY asked only about doses, and screen 189
  has an `active` switch, so *every medication paused, one dose already recorded
  today* is a state a person can reach. Under the old gates it drew the reader's
  TODAY beside the drawing's four SCHEDULES, which is the reported defect with
  its halves swapped.

  A reader who owns medications and has paused every one of them gets `[]`
  here, and `schedule_band/1` takes the eyebrow away with the card. That is the
  answer rather than the fixture, because the fixture would be four
  prescriptions they never typed on a page whose other two bands are theirs.
  """
  @spec schedules() :: [map()]
  @spec schedules(day()) :: [map()]
  def schedules(day \\ day())

  def schedules({false, [], []}), do: WeightSample.schedules()

  def schedules({_owned, medications, _stored}) do
    # `id:` is on a STORED row and absent from the drawing's, never `nil`:
    # `Kati.Screens.MedicationDetail.params_for/1` reads it to decide
    # whether it can name the medication it is being pushed with, and a
    # `nil` id is a name a write could be handed.
    Enum.map(medications, fn m ->
      %{id: m.id, name: m.name, line: Medication.schedule_line(m)}
    end)
  end

  defp stored_doses do
    Dose
    |> Ash.Query.for_read(:for_day, %{day: Kati.Time.today()})
    |> Ash.Query.load(:medication)
    |> Ash.read()
    |> case do
      {:ok, doses} -> doses
      _other -> []
    end
  rescue
    _error -> []
  end

  @doc false
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
        {Kati.Screens.Goals.chrome()}
        {SettingsList.title("Medication", Kati.Screens.Medication.subtitle(assigns.doses))}
        {UI.eyebrow("Today")}
        {Kati.Screens.Medication.today(assigns.doses, assigns[:save_error], assigns.schedules)}
        {Kati.Screens.Medication.schedule_band(assigns.schedules)}
        {Kati.Screens.Medication.reminder_band(assigns[:reminder])}
        {Kati.Screens.Medication.footnotes()}
      </Column>
    </Scroll>
    """
  end

  @doc "The header's mono subtitle, carrying today's real count — or the drawing's."
  @spec subtitle([map()]) :: String.t()
  def subtitle(doses) do
    # Asks the LIST it was handed, not the store, and that is the D-59 change.
    # The old comment's argument is untouched and is why this branch exists at
    # all — *the drawing is drawn whole or not at all*, because dating the
    # drawing's doses with the device's today would put a real date on a
    # fixture. What moved is only how the question is asked.
    #
    # It used to be a SECOND query, against `health_doses`, which is a
    # different table from the one `schedules/0` gated on — and that is exactly
    # how this header came to print `4 DOSES` over a page holding one
    # medication. A term cannot disagree with itself: `drawn_doses/0` carries
    # `id: nil`, no `:medication_id` and the `dose_drawn_N` tags, none of which
    # a stored or derived row can produce, so the identity is exact. It is also
    # the identity `Kati.ScreenEmptyDatabaseTest`'s screen-112 pair compares,
    # so the header is right by the same term the suite checks rather than by a
    # read that happened to agree with it. `Kati.Screens.HealthFa.doses/0` asks
    # its half of the same question the same way and says why: *the identity
    # check against `drawn_doses/0` is how the question is asked without a
    # second query.*
    if doses == drawn_doses() do
      WeightSample.doses_subtitle()
    else
      String.upcase(Calendar.strftime(Kati.Time.today(), "%A %-d %B")) <>
        " · " <> Kati.Screens.Medication.count_clause(length(doses))
    end
  end

  @doc """
  The count half of the header line: `4 DOSES`, `1 DOSE` or `NO DOSES`.

  `NO DOSES` rather than `0 DOSES` is board 190's own word and not a new one.
  `Kati.Screens.MedicationEmpty.subtitle/0` draws `SUNDAY 16 AUGUST · NO DOSES`
  and its doc argues it for the empty page — *a page with nothing stored cannot
  count four doses* — and a quiet day is one step along from that: the
  medications are real, the date is the device's, and the count is nothing. A
  zero drawn as a numeral reads as a tally that came out empty; the word reads
  as an answer, which is what screen 96's rule asks an empty state for.

  Zero was unreachable until D-59, because `doses/0` could not answer `[]`, so
  this clause is new only because the state is.

      iex> Kati.Screens.Medication.count_clause(0)
      "NO DOSES"

      iex> Kati.Screens.Medication.count_clause(1)
      "1 DOSE"

      iex> Kati.Screens.Medication.count_clause(4)
      "4 DOSES"
  """
  @spec count_clause(non_neg_integer()) :: String.t()
  def count_clause(0), do: "NO DOSES"
  def count_clause(1), do: "1 DOSE"
  def count_clause(count), do: "#{count} DOSES"

  @doc """
  Today's doses, each in screen 43's card treatment.

  A taken dose sits on the settled fill with a green tick; a missed one keeps
  card white and takes a close glyph, so *missed* reads as something that
  happened rather than as an error.

  Takes the failed-write message as well as the doses, because the place it
  belongs is inside this group: between the list it failed to change and the
  buttons that were just pressed.

  ## The day nothing is due keeps its eyebrow and says so — D-59

  With the page gated on `day/0` rather than on `health_doses`, `doses/0` can
  answer `[]` for the first time, and it means the thing this page could never
  say before: *you have medications and none of them is due today*. Board 188
  saves a prescription with whatever clock times were set and no more, so the
  first medication somebody adds without one puts them here — and a Mon/Wed/Fri
  tablet, whose schedule sentence Kati deliberately does not parse, is the same
  state four days a week. It is not an edge.

  **Drawn rather than omitted**, and the fork is not a close one once this
  app's own boards are read. Screen 66 takes a whole band away when it is empty
  — `Kati.Screens.BookDetail.series_section/1`: *a book in no series and lent to
  nobody takes the whole band with it … there is nothing to say, so nothing says
  it* — but series and lending are OPTIONAL ATTRIBUTES of a book. TODAY is not
  an attribute of this page, it is the page: the header counts it, the two
  verbs belong to it, and it is drawn first. Board 160 decides exactly this
  fork for the app and decides it both ways in one breath — تازه‌های این هفته and
  ادامه تماشا are omitted entirely, while باقی امروز *stays whatever happens …
  the calendar does not depend on sections, and "nothing today" is itself a
  piece of news.* TODAY is باقی امروز's position exactly: it depends on nothing
  but having medications, which this reader has.

  160 words the cost of getting it wrong too — *an empty row says something is
  broken, a missing row says you have not started yet* — and a page whose first
  section silently vanished on a Tuesday would tell somebody with four
  prescriptions that they had not started, which is the one thing that is false
  about them. So the eyebrow stays in `content/1` and what changes underneath
  it is four rows for one sentence. `Kati.Screens.Medication.schedule_band/1`
  goes the other way for the other band, and the difference between them is
  precisely screen 66's distinction.

  The two verbs need no clause of their own: `undecided([])` is `nil` and
  `actions(nil)` is already `[]`, which is D-59's *absent rather than inert*
  and the reason `actions/1` already gives — a control whose only possible
  outcome is a red line is a control that exists to fail.

  **The schedules ride along** so the sentence can know whether the band it
  points at is on the page — `nothing_due/1` carries that argument. They are
  read for nothing else: the rows themselves are `schedule_band/1`'s.

  `save_notice/1` is still drawn here, and it is defensive rather than
  load-bearing — said plainly because the paragraph that used to stand here
  said the opposite and was wrong. It claimed screen 115's two identity-less
  chips report their refusal into this tree. They do not: 115 renders its own
  `content/1`, which reads `:save_error` nowhere, so a refusal on the Persian
  mirror is silent today. That is a real gap and it is not this function's —
  every Persian screen in the app that can fail sets `:save_error` and draws
  nothing, because `Kati.Write.message/1` answers in English and no board
  writes the Persian sentence. It is filed rather than invented here.

  What the call is actually for is this page: `record/3` can set `:save_error`
  and then re-read a day that has emptied underneath it — the last dose
  deleted from screen 189 while this page was open — and the notice is what
  keeps that failure visible instead of vanishing with the rows it was about.
  """
  @spec today([map()], String.t() | nil, [map()]) :: map()
  def today(doses, save_error \\ nil, schedules \\ [])

  def today([], save_error, schedules) do
    notice = Kati.Screens.Medication.save_notice(save_error)
    card = Kati.Screens.Medication.quiet_day(schedules)

    ~MOB"""
    <Column fill_width={true}>
      {notice}
      {card}
      <Spacer size={24} />
    </Column>
    """
  end

  def today(doses, save_error, _schedules) do
    rows =
      doses
      |> Enum.map(&Kati.Screens.Medication.dose_row/1)
      |> Enum.intersperse(~MOB"<Spacer size={8} />")

    notice = Kati.Screens.Medication.save_notice(save_error)
    actions = Kati.Screens.Medication.actions(Kati.Screens.Medication.undecided(doses))

    ~MOB"""
    <Column fill_width={true}>
      {rows}
      <Spacer size={12} />
      {notice}
      {actions}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  What TODAY says on a day with medications and nothing due.

  **A function rather than a literal so a test can point at it**, which is
  `Kati.Screens.HomeFa.empty_day/0`'s own reason for being one — and like that
  sentence, no artboard contains this one. D-59 asks for the board (*screen 112
  with medications stored and nothing due today*) and it is not drawn yet, so
  where every word came from is written down here instead:

    * *Nothing … today* is `Kati.Screens.InboxNotifications.usage_line/2`
      exactly — `"Nothing today"` is already what this app says about a section
      whose count is zero and which stays on the page rather than going away.
    * *due* is this page's own word and not a new one:
      `Kati.Health.Medication`'s `times` is documented as *the list of clock
      times a dose is due*, and `Kati.Health.Dose.resolve/2` names the state
      `:due`.
    * The em-dash and the pointer after it are screen 139's shape — *Nothing
      scheduled — add anything with +* — borrowed the way
      `Kati.Screens.Home.rest_of_today/1` borrows it, which is to say the
      structure and not the words: say what is missing, then name the one thing
      that answers it.
    * *your schedules are below* names `UI.eyebrow("Schedules")`, which
      `content/1` draws directly beneath this on every render that has any. That
      it names something really on the page is the requirement rather than a
      nicety — `empty_day/0`'s doc states it: *the control it names is real.*

  ## The pointer is dropped when there is nothing to point at

  Which is why this takes the schedules. A reader who owns medications and has
  paused every one of them gets `[]` from `schedules/1`, `schedule_band/1` takes
  the whole band away, and the tail would then name a heading that is not on the
  page — the one requirement the paragraph above calls the requirement rather
  than a nicety.

  Dropping the tail and keeping the lead is not a new sentence and it is not a
  new decision either: `Kati.Screens.HealthFa`'s own `nothing_due` label is this
  sentence with 139's tail already dropped, for this exact reason in this exact
  wording — *the control it names is real*, and neither pointer the English
  sentence takes is true on that page. Screen 115 reached the state first
  because it never draws a Schedules group at all; this is the same drop on the
  day screen 112 can reach the same state.

  What is deliberately NOT said is *add a medication*. Screen 139's structure
  offers the one thing that fixes the state, and nothing here is broken: this
  reader already owns prescriptions, and inviting them to add another would
  answer a fault they do not have. Screen 96's rule, quoted by
  `Kati.Screens.Home.rest_of_today/1`, is the test this is written to pass —
  *an empty state should say what is missing and offer the one thing that fixes
  it, never render a plausible-looking zero* — and on a quiet day what is
  missing is nothing.
  """
  @spec nothing_due([map()]) :: String.t()
  def nothing_due([]), do: "Nothing due today."
  def nothing_due(_schedules), do: "Nothing due today — your schedules are below."

  @doc """
  The quiet day's one card, in the shape a dose row would have had.

  `dose_row/1`'s own geometry — `Palette.card()`, radius 18, 14 at the sides —
  rather than board 190's glyph tile or a shape of its own, for the reason
  `Kati.Screens.Home.rest_of_today/1` states about borrowing 139's sentence:
  *what is borrowed is the one thing 139 contributes that this screen does not
  have — the words for an empty day — and the container is this screen's own.*
  The sentence stands exactly where the 08:00 row would have stood.

  No `on_tap`, which is the rule the absent verbs follow one function up. There
  is nothing here to decide about and nothing to fix, so a control could only
  act on a premise that is false — worse than the inert control board 190's
  caption already refuses.

  `Palette.sub()` at 13 is `rest_of_today/1`'s type for the same sentence in
  the same position, and `sub` is already the colour a dose row's second line
  takes, so the card reads as the list gone quiet rather than as a notice about
  the list.
  """
  @spec quiet_day([map()]) :: map()
  def quiet_day(schedules) do
    assigns = %{sentence: Kati.Screens.Medication.nothing_due(schedules)}

    ~MOB"""
    <Box
      fill_width={true}
      background={Palette.card()}
      corner_radius={18}
      padding_left={14}
      padding_right={14}
      padding_top={18}
      padding_bottom={18}
    >
      <Text text={@sentence} text_size={13} line_height={1.55} text_color={Palette.sub()} />
    </Box>
    """
  end

  @doc """
  The dose the two verbs belong to: the first on the page not decided about.

  `:missed` counts as undecided, and that is the whole reason this is a
  function rather than a `state == :due` test. A dose reads `:missed` the
  minute after it was due — `Kati.Health.Dose.resolve/2` derives it from the
  clock rather than storing it — so a page opened at 21:00 with an untouched
  14:00 tablet on it has one thing left to answer and it is that one. A verb
  that skipped past it would leave the only undecided dose of the day
  unreachable from the two controls drawn for exactly that job.
  """
  @spec undecided([map()]) :: map() | nil
  def undecided(doses), do: Enum.find(doses, &(&1.state in [:due, :missed]))

  @doc """
  A dose's second line: what is known about it, and what became of it.

  Composed the way `Kati.Health.Medication.dose_line/1` and `schedule_line/1`
  compose their own — reject the empty parts, then join — rather than by
  appending a middot to whatever was there. D-59 is why it matters here: board
  188 saves a medication with a name and nothing else (`Kati.Screens.AddMedication`
  runs Dose and Instruction through `blank_to_nil/1`, and
  `Kati.MedicationWriteTest` pins that as a supported save), so `dose_line/1`
  answers `""` for a real prescription — and a dose row could not exist to print
  it until today's doses started being derived. Appending gave that row
  `" · MISSED"`, a leading middot with nothing before it, which is the shape
  this repo already treats as a defect one function over:
  `Kati.MedicationWriteTest` asserts `refute schedule_line(row) =~ " ·  · "`.

  `""` is a real answer and `dose_row/1` draws no second line for it — see
  there.

      iex> Kati.Screens.Medication.state_line(%{line: "50 mcg · before food", state: :taken})
      "50 mcg · before food"

      iex> Kati.Screens.Medication.state_line(%{line: "50 mcg", state: :missed})
      "50 mcg · MISSED"

      iex> Kati.Screens.Medication.state_line(%{line: "", state: :missed})
      "MISSED"

      iex> Kati.Screens.Medication.state_line(%{line: "", state: :due})
      ""
  """
  @spec state_line(map()) :: String.t()
  def state_line(dose) do
    [dose.line, Dose.state_suffix(dose.state)]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join(" · ")
  end

  @doc false
  def dose_row(dose) do
    line = Kati.Screens.Medication.state_line(dose)
    second = Kati.Screens.Medication.dose_line_nodes(line)

    assigns = %{
      time: dose.time,
      name: dose.name,
      second: second,
      background: Kati.Screens.Medication.fill(dose.state),
      tap: {self(), dose.tap}
    }

    ~MOB"""
    <Row
      fill_width={true}
      background={@background}
      corner_radius={18}
      padding_left={14}
      padding_right={14}
      padding_top={12}
      padding_bottom={12}
      align="center"
      on_tap={@tap}
    >
      <Text text={@time} font_family="mono" text_size={12} text_color={Palette.muted()} width={44} />
      <Spacer size={12} />
      <Column weight={1.0}>
        <Text
          text={@name}
          text_size={13.5}
          font_weight="bold"
          text_color={:on_surface}
          max_lines={1}
        />
        {@second}
      </Column>
      <Spacer size={12} />
      {Kati.Screens.Medication.mark(dose.state)}
    </Row>
    """
  end

  @doc """
  The gap and the second line, or neither — the card's own version of rule 5.

  A medication saved with a name and nothing else has nothing to put on this
  line: `state_line/1` answers `""` for it until the dose is decided about. The
  `<Text>` was drawn anyway, so the card carried a blank row under the name in
  both locales — `Kati.ScreenNilTextTest` cannot see it, because `""` is not the
  word `nil`, and no fixture row could produce it.

  Both nodes go together, which is the whole point:
  `Kati.Screens.BookDetailFa.title/1` is the house precedent for a page with
  nothing to say under its title saying nothing, and a `<Spacer>` left behind
  would be the eyebrow over the empty band that
  `Kati.Screens.BookDetail.series_section/1` refuses.

  A list rather than a wrapping `<Column>`, so the geometry of the card that
  HAS a line is unchanged to the point.
  """
  @spec dose_line_nodes(String.t()) :: [map()]
  def dose_line_nodes(""), do: []

  def dose_line_nodes(line) do
    assigns = %{line: line}

    [
      ~MOB"<Spacer size={4} />",
      ~MOB"""
      <Text text={@line} text_size={11.5} text_color={Palette.sub()} max_lines={1} />
      """
    ]
  end

  @doc false
  def fill(:taken), do: Palette.card_settled()
  def fill(_other), do: Palette.card()

  @doc "The trailing glyph: a green tick, or the close that means missed."
  @spec mark(atom()) :: map()
  def mark(:taken), do: UI.symbol("check", size: 20, color: Palette.green())
  def mark(:skipped), do: UI.symbol("close", size: 20, color: Palette.tertiary())
  def mark(:missed), do: UI.symbol("close", size: 20, color: Palette.gold_icon())
  def mark(_due), do: UI.symbol("check", size: 20, color: Palette.border_strong())

  @doc """
  The two verbs a dose takes, tagged with the dose they are about to decide.

  `Taken` and `Skip`, side by side rather than as a swipe: a dose is a thing you
  decide about once a day and a gesture with no affordance is not a control.

  They take the row rather than reading for it, so *which dose* is answered at
  draw time by the list the user is looking at. The board answers it visually,
  by drawing this pair inside the one undecided card; this page keeps them
  under the list, as it always has, and carries the same answer in the tag.

  A day with nothing left to decide draws no verbs at all. Two buttons whose
  only possible outcome is a red line saying there is nothing to save would be
  a control that exists to fail — and a page listing four ticks has already
  said what it has to say.
  """
  @spec actions(map() | nil) :: map() | []
  def actions(nil), do: []

  def actions(dose) do
    assigns = %{taken: {self(), dose.taken}, skip: {self(), dose.skip}}

    ~MOB"""
    <Row fill_width={true} align="center">
      <Row
        weight={1.0}
        height={40}
        corner_radius={20}
        background={Palette.ink_fill()}
        align="center"
        on_tap={@taken}
      >
        <Spacer weight={1.0} />
        <Text
          text="Taken"
          text_size={13}
          font_weight="bold"
          text_color={Palette.on_ink()}
          max_lines={1}
        />
        <Spacer weight={1.0} />
      </Row>
      <Spacer size={10} />
      <Row
        weight={1.0}
        height={40}
        corner_radius={20}
        background={Palette.card()}
        shadow={Kati.Theme.shadow_button()}
        align="center"
        on_tap={@skip}
      >
        <Spacer weight={1.0} />
        <Text
          text="Skip"
          text_size={13}
          font_weight="semibold"
          text_color={Palette.ink_soft()}
          max_lines={1}
        />
        <Spacer weight={1.0} />
      </Row>
    </Row>
    """
  end

  @doc """
  What a dose that did not record leaves above the two buttons.

  Directly above `actions/0` rather than at the top of the page: the buttons
  are what was just pressed, so the eye is already there, and a notice level
  with the title would read as a claim about the whole screen.

  Not one of `footnotes/0`'s `info` pills, though the page has two of them and
  reaching for a third is the obvious move. Those carry the two things that are
  always true of this feature; a write that failed is true for one tap, and
  dressing it as an `info` would both mute it and cast doubt on the pair it
  copied. Red, and its own line.
  """
  @spec save_notice(String.t() | nil) :: map() | []
  def save_notice(nil), do: []

  def save_notice(message) do
    assigns = %{message: message}

    ~MOB"""
    <Column fill_width={true}>
      <Text
        text={@message}
        text_size={12.5}
        font_weight="semibold"
        line_height={1.35}
        text_color={Palette.red()}
      />
      <Spacer size={10} />
    </Column>
    """
  end

  @doc """
  One schedule row's tag, built from the medicine's name.

  Every schedule shared `:open_schedule`, so the card gave one
  `accessibility_id` to every row and `onNodeWithTag` throws on the second
  match (#97). A schedule is the medicine it is for, which is what the row's
  own first line says.

      iex> Kati.Screens.Medication.schedule_tag(%{name: "Levothyroxine"})
      :open_schedule_Levothyroxine

      iex> Kati.Screens.Medication.schedule_tag(%{name: ""})
      :open_schedule

  ## This namespace is bounded by names typed, not by rows

  Said out loud because `tags/1` above spends thirty lines proving its three
  namespaces are bounded and this one is not bounded the same way: it is built
  from the user's own typed name, so renaming a medication mints another atom
  and the old one never goes back. `Kati.Screens.MyServices.service_tag/1`,
  `Kati.Screens.Money.subscription_tag/1` and
  `Kati.Screens.ArtistDetail.album_tag/1` all do exactly this, so it is the
  app's pattern rather than this screen's slip — and the app's pattern is the
  thing to change, in one place, rather than here alone. Filed as such.

  The row's id would bound it to one atom per medication ever created, which
  is what `tags/1` does with a dose. It also changes every tag on the band and
  the four `@empty_builders` entries that name them, so it is a change with a
  ratchet edit attached rather than a line.
  """
  @spec schedule_tag(map()) :: atom()
  def schedule_tag(schedule) do
    case schedule
         |> Map.get(:name, "")
         |> to_string()
         |> String.trim()
         |> String.replace(" ", "_") do
      "" -> :open_schedule
      name -> String.to_atom("open_schedule_" <> name)
    end
  end

  @doc """
  The Schedules eyebrow and its card — or neither, when there is nothing in it.

  The other half of `today/3`'s fork, decided the other way, and the difference
  is screen 66's. `schedules/1` answers `[]` for a reader who owns medications
  and has paused every one of them — a state screen 189's `active` switch makes
  reachable in two taps — and a paused medication is an OPTIONAL ATTRIBUTE of
  this page in the way TODAY is not: nothing on the page counts schedules, nothing points at
  them, and a person who has switched all of them off has said what they meant.

  So this band takes its own eyebrow with it, which is
  `Kati.Screens.BookDetail.series_section/1`'s rule in that function's own
  words: *there is nothing to say, so nothing says it*. An eyebrow over an
  empty card is D-58's defect, and
  `Kati.Screens.InboxNotifications.group/3` gives the reading of it that
  decides the case — *three empty headings read as an app that has broken
  rather than as an evening with nothing due*, which is screen 05's rule.
  """
  @spec schedule_band([map()]) :: map() | []
  def schedule_band([]), do: []

  def schedule_band(schedules) do
    ~MOB"""
    <Column fill_width={true}>
      {UI.eyebrow("Schedules")}
      {Kati.Screens.Medication.schedule_group(schedules)}
    </Column>
    """
  end

  @doc """
  The schedules, each pushing `Kati.Screens.MedicationDetail` — see `handle_tap/2`.

  A row whose line is empty is drawn as a title and nothing else, which is
  `dose_line_nodes/1`'s rule on the band above and the same newly reachable
  state: a medication saved on board 188 with a name and nothing else has no
  dose and no schedule sentence, so `Kati.Health.Medication.schedule_line/1`
  answers `""` for it. `Kati.UI.SettingsList.body/3` already draws the one-line
  row for `nil` — the empty string is what it cannot tell from a subtitle, and
  a settings row with a blank second line under the name is the same defect as a
  dose card with one.
  """
  @spec schedule_group([map()]) :: map()
  def schedule_group(schedules) do
    rows =
      Enum.map(schedules, fn schedule ->
        SettingsList.row(
          SettingsList.icon_tile("medication"),
          SettingsList.body(schedule.name, Kati.Screens.Medication.said(schedule.line)),
          SettingsList.trailing(SettingsList.chevron()),
          on_tap: {self(), Kati.Screens.Medication.schedule_tag(schedule)}
        )
      end)

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.card(rows)}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  A line that says something, or `nil` — the shape a component reads as absence.

  `Kati.UI.SettingsList.body/3` draws a subtitle for any string it is handed and
  a title alone for `nil`, so `""` is the one value that turns *nothing to say*
  into a blank row. Absence rather than an empty string is the same rule
  `drawn_doses/0` states for an id: *absence is the whole signal.*

      iex> Kati.Screens.Medication.said("50 mcg · every morning, 08:00")
      "50 mcg · every morning, 08:00"

      iex> Kati.Screens.Medication.said("")
      nil
  """
  @spec said(String.t() | nil) :: String.t() | nil
  def said(""), do: nil
  def said(line), do: line

  @doc """
  The reminder this page arms — or the drawing's, on the page that is the
  drawing's.

  ## The fourth band, and the last invented value on the page — D-59

  TODAY, SCHEDULES and the header became the reader's and this one did not. It
  read `Kati.Health.WeightSample.reminder/0` with no gate at all, so a person
  taking one 08:00 tablet was shown `KATI · 21:00`, *Magnesium — 200 mg*, *With
  water, before bed* — four values they never typed, under a heading, in a card
  this file's own moduledoc describes as *drawn as the notification it becomes*,
  which is to say as the reminder THIS page arms. Screen 20's rule, which D-59
  quotes as its acceptance, was still broken: three bands the reader's and a
  fourth the drawing's.

  So the card is composed by the code that composes the real one.
  `Kati.Notifications.Sources.Health.candidates/3` is handed the same active
  list `doses/1` and `schedules/1` were, and `title/1` and `body/1` are already
  public for exactly this reason — screen 189's preview says it in as many
  words: *a preview that composed its own title would be a second sentence able
  to disagree with the one the scheduler sends.*
  `Kati.Screens.MedicationDetail.preview/1` has done it this way since board
  189, including `"KATI · " <> at` for the app line, and this was the last
  medication page that did not.

  **The three action labels stay the drawing's** and are the one thing here
  that is not read. They are the notification's own three buttons rather than a
  fact about this reader — the card is a picture of a notification and the
  labels are part of the picture — and `Kati.Health.WeightSample.reminder/0` is
  the board's word for them, quoted rather than invented (rule 6).

  `nil` when nothing is armed — every medication paused, or every one of them a
  schedule sentence with no clock in it — and `reminder_band/1` then takes the
  eyebrow away with the card. An absent illustration says nothing; this one
  said Magnesium.
  """
  @spec reminder(day()) :: map() | nil
  def reminder({false, [], []}), do: WeightSample.reminder()

  def reminder({_owned, medications, _stored}) do
    medications
    |> Health.candidates(Kati.Time.today())
    |> Enum.filter(&armed?/1)
    |> next_armed(Kati.Time.now())
    |> case do
      nil ->
        nil

      candidate ->
        %{
          app: "KATI · " <> candidate.meta.at,
          title: candidate.title,
          body: candidate.body,
          actions: WeightSample.reminder().actions
        }
    end
  end

  # A candidate that will actually fire. `Kati.Notifications.Sources.Health`
  # contributes a SUPPRESSED `:no_times` candidate per medication with no clock
  # time — *this medication never reminds me* has to be answerable — and a
  # suppressed candidate has no `:at` and nothing to draw a card from.
  defp armed?(candidate), do: is_nil(candidate.suppressed) and is_map_key(candidate.meta, :at)

  # The next one due. `candidates/3` is already in clock order, so this is the
  # first time still ahead of the clock — and the day's first when they have all
  # passed, because a wall-clock dose repeats and the next 08:00 is tomorrow's.
  # The card carries a time and never a date, so that is the same card either
  # way rather than a claim about today.
  defp next_armed([], _now), do: nil

  defp next_armed(candidates, now) do
    at = now |> DateTime.to_time() |> Calendar.strftime("%H:%M")

    Enum.find(candidates, List.first(candidates), &(&1.meta.at >= at))
  end

  @doc """
  The reminder's eyebrow and its card — or neither, when nothing is armed.

  `schedule_band/1`'s rule, applied to the band beside it and for the same
  reason: an eyebrow over nothing is D-58's defect, and
  `Kati.Screens.BookDetail.series_section/1` is the house precedent — *there is
  nothing to say, so nothing says it*.
  """
  @spec reminder_band(map() | nil) :: map() | []
  def reminder_band(nil), do: []

  def reminder_band(card) do
    assigns = %{card: Kati.Screens.Medication.reminder_card(card)}

    ~MOB"""
    <Column fill_width={true}>
      {UI.eyebrow("The reminder")}
      {@card}
    </Column>
    """
  end

  @doc """
  The reminder, drawn as the notification it becomes.

  On the page rather than only on the lock screen — see the moduledoc. Its
  three actions are drawn and inert here, because tapping a picture of a
  notification is not taking a dose; the real ones live on the notification.

  Draws whatever `reminder/1` composed — the reader's next armed dose group or
  the drawing's card — from four keys it cannot tell apart, which is `shape/2`'s
  rule one band up: two branches drawing two cards is two pieces of code that
  can disagree about what a reminder looks like.
  """
  @spec reminder_card(map()) :: map()
  def reminder_card(r) do
    assigns = %{
      app: r.app,
      title: r.title,
      body: r.body,
      actions:
        r.actions
        |> Enum.map(&Kati.Screens.Medication.reminder_action/1)
        |> Enum.intersperse(~MOB"<Spacer size={9} />")
    }

    ~MOB"""
    <Column fill_width={true}>
      <Column fill_width={true} background={Palette.card_settled()} corner_radius={20} padding={16}>
        <Text
          text={@app}
          font_family="mono"
          text_size={9.5}
          letter_spacing={0.14}
          text_color={Palette.muted()}
        />
        <Spacer size={9} />
        <Text
          text={@title}
          text_size={14.5}
          font_weight="bold"
          text_color={:on_surface}
          max_lines={1}
        />
        <Spacer size={4} />
        <Text text={@body} text_size={12.5} text_color={Palette.sub()} max_lines={1} />
        <Spacer size={13} />
        <Row fill_width={true} align="center">
          {@actions}
        </Row>
      </Column>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc false
  def reminder_action(label) do
    assigns = %{label: label}

    ~MOB"""
    <Text
      text={@label}
      text_size={12.5}
      font_weight="semibold"
      text_color={Kati.Theme.Palette.ink_soft()}
    />
    """
  end

  @doc "The two claims this page has to make, both in the flow rather than as small print."
  @spec footnotes() :: map()
  def footnotes do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.note("info", "Reminders can arrive late if the phone is restricting alarms to save battery, so treat them as a nudge and not a guarantee.")}
      <Spacer size={12} />
      {Kati.UI.SettingsList.note("info", "Kati is not a medical device and gives no medical advice — it only records what you tell it.")}
    </Column>
    """
  end

  @doc false
  # Every tag this page draws for a dose is one of that dose's own three, so
  # the doses already on the socket are what a tag is resolved against —
  # rather than the id being parsed back out of the atom. `Kati.Screens.Goals`
  # settled the same question the same way, and the reason is the same: nothing
  # can then name a row that is not on the screen.
  #
  # `Map.get/3` rather than `socket.assigns.doses`, because screen 115 forwards
  # its own two tags here with its own socket, which carries Persian doses
  # under the same key and no ids in them.
  def handle_tap(tag, socket) when is_atom(tag) do
    case Enum.find_value(Map.get(socket.assigns, :doses, []), &decision(&1, tag)) do
      nil -> other_tap(tag, socket)
      {dose, state} -> {:noreply, record(socket, dose, state)}
    end
  end

  defp decision(%{tap: tag} = dose, tag), do: {dose, :taken}
  defp decision(%{taken: tag} = dose, tag), do: {dose, :taken}
  defp decision(%{skip: tag} = dose, tag), do: {dose, :skipped}
  defp decision(_dose, _tag), do: nil

  # Screen 115's two chips, which carry no dose — see the moduledoc. They are
  # the only callers left of `next_undecided/1`, and they are why it is still
  # here.
  defp other_tap(:mark_taken, socket),
    do: {:noreply, record(socket, next_undecided(socket), :taken)}

  defp other_tap(:mark_skipped, socket),
    do: {:noreply, record(socket, next_undecided(socket), :skipped)}

  # The `add` disc, drawn and inert since this page shipped. Board 188 is the
  # sheet behind it, and D-43 is the ticket that ends three rounds of this
  # page having no way to own a prescription.
  defp other_tap(:add, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.AddMedication)}

  # A Schedules chevron. Resolved against the schedules THIS RENDER DREW —
  # each row's own tag rebuilt and compared — rather than by parsing a name
  # back out of the atom or by re-reading the store, so nothing can name a
  # medication that is not on the screen. `Kati.Screens.Goals` settled the
  # same question the same way.
  #
  # The drawing's four carry no id, so `params_for/1` hands the page nothing
  # and it draws its own fixture; `Kati.ScreenParamsSweepTest`'s
  # `@empty_builders` records those four doors until a real medication is
  # stored, which screen 188 is now the way to do.
  defp other_tap(tag, socket) do
    schedules = Map.get(socket.assigns, :schedules, [])

    case Enum.find(schedules, &(Kati.Screens.Medication.schedule_tag(&1) == tag)) do
      nil ->
        {:noreply, socket}

      schedule ->
        {:noreply,
         Mob.Socket.push_screen(
           socket,
           Kati.Screens.MedicationDetail,
           Kati.Screens.MedicationDetail.params_for(schedule)
         )}
    end
  end

  # The page re-reads the day because a dose was recorded, not because a button
  # was pressed. Those were the same line until now.
  #
  # A failure leaves `:doses` untouched rather than re-reading: the store did
  # not change, so re-reading would redraw the identical list underneath an
  # error saying nothing was written — the same mixed message the bare `:ok`
  # used to send, only louder.
  #
  # TODAY alone, and `load/1`'s three-band re-read is not wanted here: a dose
  # decision cannot move `day/0`'s other two answers. It writes to
  # `health_doses` and nothing else, so the medications the reader owns, the
  # ones they are still taking and the reminder armed from those are all exactly
  # what this render already drew — and the fixture branch cannot flip either,
  # because a page drawing the fixture has no row a write can be handed.
  defp record(socket, dose, state) do
    case save_dose(dose, state) do
      {:ok, _dose} ->
        socket
        |> Mob.Socket.assign(:doses, doses())
        |> Mob.Socket.assign(:save_error, nil)

      {:error, _reason} = error ->
        Mob.Socket.assign(socket, :save_error, Write.message(error))
    end
  end

  @doc """
  Record `dose` — the row a control was drawn for — as `state`.

  Takes the row rather than looking one up, which is the whole of the fix. The
  row is then read back **by its own id** and that row is updated: the page
  hands over an id it drew, and the store answers about that id or about
  nothing. A dose deleted or already decided underneath the page comes back as
  the tuple rather than as a write landing on a neighbour.

  No `rescue`. `Ash.update/2` returns `{:error, changeset}` rather than
  raising, so the one this carried caught nothing while the line above it threw
  the failure away; `Kati.Screens.Root.rescue_tap/3` is already around every
  tap for the raises that are real.

  ## `id: nil` no longer means one thing — D-59

  It used to mean *the drawing*, because a dose with no row was always a
  fixture. Today's doses are composed from the reader's own schedules now, so
  `id: nil` means *derived, not materialised yet* when a `:medication_id` rides
  with it and *this is the drawing* when nothing does — and the difference
  between those two is a row being created versus a refusal.

  Absence, not a `nil`, is the signal, for the reason `drawn_doses/0` sets out:
  a fixture row that carried a `nil` medication id would be a row this write
  could be handed. `Kati.ScreenWriteTargetTest` exists for exactly that failure
  and `Kati.Health.WeightSample.doses/0` has no such key.

  The create clause takes `due_on` and `due_at` **off the row the page drew**,
  never from `Kati.Time.today/0` at tap time, which is the same rule the id
  clause follows: a page drawn at 23:59 and tapped at 00:01 must record the
  dose it was drawing. And it writes the state DECIDED — `:taken` or
  `:skipped`, never the `:due` default — because the row exists only because
  somebody decided about it. That is what a `health_doses` row means after
  D-59: not a plan, a record.

  ## One dose, one row, however the decision arrived

  A derived dose is drawn with THREE tags — its card and the two verbs — and all
  three resolve to the same row through `decision/2`. Creating unconditionally
  made that three rows for one (medication, day, time) for any caller pressing
  more than one of them against the same socket. On a device the redraw hides it,
  because `record/3` re-reads and the derived tags stop existing; a holder of a
  stale socket is not so lucky, and `Kati.ScreenWriteTargetTest` is one — its
  sweep presses every drawn tag against the mount-time socket.

  So the create clause looks first, keyed on `{medication_id, due_on, due_at}`
  — the same key `Kati.Health.Dose.merge/2` uses to let a stored row win its
  derived twin, read through the same `:for_day` action, so there is one answer
  in this app to *is this dose already a row?* A second decision then MOVES the
  first rather than laying a duplicate beside it, which is what the id clause
  has always done and what a reader pressing Taken twice means.
  """
  @spec save_dose(map(), :taken | :skipped) :: {:ok, Dose.t()} | {:error, term()}
  def save_dose(%{id: id}, state) when is_binary(id) do
    with {:ok, %Dose{} = dose} <- Ash.get(Dose, id) do
      mark(dose, state)
    end
    |> Write.note("medication dose")
  end

  def save_dose(%{id: nil, medication_id: medication_id, due_on: due_on, due_at: due_at}, state)
      when is_binary(medication_id) do
    case recorded(medication_id, due_on, due_at) do
      %Dose{} = dose ->
        mark(dose, state)

      nil ->
        Dose
        |> Ash.Changeset.for_create(:create, %{
          medication_id: medication_id,
          due_on: due_on,
          due_at: due_at,
          state: state,
          recorded_at: Kati.Time.now() |> DateTime.truncate(:second)
        })
        |> Ash.create()
    end
    |> Write.note("medication dose")
  end

  def save_dose(_drawn, _state) do
    Write.note({:error, :nothing_to_save}, "medication dose")
  end

  # The decision itself, shared by the two clauses above, so a row that already
  # existed and a row that was just found are recorded by one piece of code
  # rather than by two that can drift about what `recorded_at` means.
  defp mark(%Dose{} = dose, state) do
    Ash.update(dose, %{
      state: state,
      recorded_at: Kati.Time.now() |> DateTime.truncate(:second)
    })
  end

  # The day's row for this (medication, clock time), if there already is one —
  # `Kati.Health.Dose.merge/2`'s key, through `:for_day`, which is the read this
  # page already makes about a day.
  #
  # `nil` on any failure, and that is a decision with a cost worth naming.
  # **Nothing in the schema refuses a duplicate**: `health_doses` has no unique
  # index over `{medication_id, due_on, due_at}` and `Kati.Health.Dose`'s
  # `create: :*` has no identity, so a store that cannot answer *is this
  # already a row?* falls through to the create and a second row for one dose
  # is what comes back. The alternative is refusing the decision outright,
  # which loses a tick the reader actually made; a duplicate is recoverable and
  # a lost tick is not, so the create wins. `merge/2` then shows the reader one
  # card either way, because it keys on the pair rather than counting rows.
  #
  # A unique index is the real answer and it is a migration.
  defp recorded(medication_id, due_on, due_at) do
    Dose
    |> Ash.Query.for_read(:for_day, %{day: due_on})
    |> Ash.read()
    |> case do
      {:ok, rows} ->
        Enum.find(rows, &(&1.medication_id == medication_id and &1.due_at == due_at))

      _other ->
        nil
    end
  rescue
    _error -> nil
  end

  # The first undecided dose ON THE PAGE, for the two Persian chips that carry
  # none of their own — see the moduledoc.
  #
  # It re-read `health_doses` at tap time until D-59, and that stopped being an
  # answer the day the day became composed: a person whose doses are derived
  # has no rows to find, so both chips would have reported *Nothing to save
  # yet.* on every device with a medication and nothing marked. The first fix
  # swapped that query for `undecided(doses())`, which is a DIFFERENT re-read
  # at tap time and not the page's list at all — the shape
  # `Kati.ScreenWriteTargetTest`'s moduledoc names as the bug in as many words:
  # *a re-read of the shelf at tap time is the bug.* A dose recorded on another
  # screen between draw and tap moves the head, and the chip lands somewhere the
  # user was not looking.
  #
  # So it asks the SOCKET, through the same `undecided/1` the two verbs use, and
  # the row it hands back carries whatever `save_dose/2` needs to write it — id,
  # or medication and clock time. `Map.get/3` rather than
  # `socket.assigns.doses`, for `handle_tap/2`'s reason: screen 115 forwards its
  # own two tags here with its own socket.
  #
  # `%{id: nil}` when there is nothing to answer about, rather than `nil`: the
  # refusal belongs to `save_dose/2`, which is where every other caller's does,
  # and a `nil` here would be a second place deciding there is nothing to save.
  defp next_undecided(socket),
    do: undecided(Map.get(socket.assigns, :doses, [])) || %{id: nil}
end
