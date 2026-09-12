defmodule Kati.Screens.LogWeight do
  @moduledoc """
  Screen 111 — Log weight, a sheet over Weight.

  Screen 70's field geometry adapted for a decimal, and the caption names both
  adaptations: *the stepper moves in 0.1 steps, and the unit sits inside the
  numeral rather than as a separate label, so the hero reads as one value.*

  ## The unit switch is here as well as in Settings, on purpose

  *Changing it here is a correction, not a preference.* You weighed yourself on
  a scale set to pounds and typed pounds; the switch is you saying which number
  you just read, not you changing your mind about how weights are displayed.

  That is only coherent because `Kati.Health.Reading` stores grams: the
  correction converts the value you typed, and every other reading in the log
  is untouched. The opposite arrangement — storing whatever unit was current —
  would make this switch rewrite history.

  ## The confirmation compares with the last reading, not with a goal

  *0.4 kg down from your last reading, three days ago.* No target, no ideal
  range, no colour that means bad. `Kati.Health`'s moduledoc gives the rule this
  follows: Kati is not a medical device and records what it was told.

  ## A reading that did not save keeps the sheet open

  This sheet is the worst place in the app for a silent failure, because the
  screen behind it draws the sample series when nothing is stored. Save,
  close, and Weight still shows four readings dated 6-16 August — so a write
  that never landed looks exactly like one that did, and the number you stood
  on a scale to read is gone.

  So `save_reading/1` answers `Kati.Write`'s contract: `{:ok, reading}` or
  `{:error, reason}`, never a bare `:ok`. On a failure the sheet stays where it
  is, with your grams still in the stepper, and says so in red above the button
  you just pressed — the one place you are already looking.

  ## Two scripts, one sheet

  mishka-group/kati#103 folded the Persian mirrors away, so this module is the
  page in both scripts and every value on it has to ask `Kati.Locale` rather
  than `Calendar`: the hero's figure and its separator (board 115 writes
  `۷۶٫۰`, with U+066B), the clock line's CALENDAR — ۲۱ شهریور is not a
  translation of 12 September, it is a different arithmetic — and the row labels
  this screen reads back out of `Kati.Screens.Weight.entries/1`, which is where
  the fold actually broke something. `previous/0` and `days_since/1` carry that
  one between them.
  """

  use Mob.Screen
  use Gettext, backend: Kati.Gettext
  import Mob.Sigil

  alias Kati.Health
  alias Kati.Health.Reading
  alias Kati.Health.WeightSample
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.Segmented
  alias Kati.UI.Sheet
  alias Kati.Write

  # The three units were `@units`, a module attribute, and cannot be one any
  # more: `gettext/1` inside a module attribute is evaluated at COMPILE time,
  # so the words would freeze in whichever locale the compiler happened to be
  # in. They are `units/0` now, built from `unit_word/1` — the same function the
  # hero's own label calls — so a segment and the figure beside it cannot spell
  # one unit two ways.
  #
  # The comment that sat here described `step/1` rather than `mount/3`: a tenth
  # of the DISPLAY unit, derived per unit rather than kept as one constant. That
  # argument is in `step/1`'s own @doc, which is where it is read.
  def mount(_params, _session, socket) do
    Kati.Theme.activate()
    Kati.Locale.activate()

    {:ok,
     socket
     |> Mob.Socket.assign(:unit, Health.unit())
     |> Mob.Socket.assign(:grams, opening_grams())
     |> Mob.Socket.assign(:save_error, nil)}
  end

  @doc """
  The weight the sheet opens on: your last reading, or the drawing's 76.0.

  Your last, because a weighing is almost always a small change from the one
  before it — opening on a round number would make every entry a dozen taps.
  """
  @spec opening_grams() :: integer()
  def opening_grams do
    case Kati.Screens.Weight.entries() do
      [%{grams: grams} | _rest] -> grams
      _other -> 76_000
    end
  end

  def render(assigns),
    do: Sheet.sheet(gettext("Log weight"), body(assigns), Kati.Screens.Identity.of(__MODULE__))

  @doc false
  def body(assigns) do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.LogWeight.stepper(assigns.grams, assigns.unit)}
      <Spacer size={14} />
      {Segmented.plain(Kati.Screens.LogWeight.units(), Kati.Screens.LogWeight.unit_tag(assigns.unit))}
      <Spacer size={14} />
      {Kati.Screens.LogWeight.when_and_note()}
      <Spacer size={14} />
      {Kati.Screens.LogWeight.confirmation(assigns.grams)}
      <Spacer size={14} />
      {Kati.Screens.LogWeight.save_notice(assigns.save_error)}
      {Sheet.commit(gettext("Save reading"), :save)}
    </Column>
    """
  end

  @doc """
  The line that says the reading did not save, directly above the button.

  Above the commit rather than under the title, because that is where the eye
  already is a tenth of a second after a tap — a notice at the top of a sheet
  this tall is one a person can miss entirely while looking at the control they
  just pressed.

  `nil` draws a zero spacer rather than an empty `Text`, so nothing in the
  sheet moves until there is something to say.
  """
  @spec save_notice(String.t() | nil) :: map()
  def save_notice(nil), do: ~MOB"<Spacer size={0} />"

  def save_notice(message) do
    assigns = %{message: message}

    ~MOB"""
    <Column fill_width={true}>
      {# The message is `Kati.Write.message/1`'s, already translated, so this
       # `Text` can hold a Persian sentence — and Vazirmatn's metrics are not
       # Plus Jakarta's, which is what `Kati.Locale.leading/1` carries.}
      <Text
        text={@message}
        text_size={12.5}
        line_height={Kati.Locale.leading(1.45)}
        text_color={Palette.red()}
      />
      <Spacer size={12} />
    </Column>
    """
  end

  @doc """
  The three units the switch offers, as `{label, tag}`.

  The TAG is what the segment answers to and the word beside it is what the
  reader sees — the arrangement every folded segmented control in
  mishka-group/kati#103 ends up with, because a tag built from the label would
  be a different atom in each script.
  """
  @spec units() :: [{String.t(), atom()}]
  def units,
    do: [
      {Kati.Screens.LogWeight.unit_word(:kg), :unit_kg},
      {Kati.Screens.LogWeight.unit_word(:lb), :unit_lb},
      {Kati.Screens.LogWeight.unit_word(:st), :unit_st}
    ]

  @doc """
  A unit's own word, as the reader writes it.

  `Kati.Health.Reading.unit_label/1` is the Latin half of this and stays where
  it is — it is what the resource and the log rows are written in — but a word
  on a control is copy, and board 115 draws the hero's unit as **کیلوگرم**
  rather than as `kg`. The catalogue already holds that one from screen 109, so
  this reuses the msgid rather than inventing a second word for it; `lb` takes a
  context because a two-letter msgid is exactly what `mix gettext.merge` will
  fuzzy-match against the first sentence that happens to contain it.

  **`st` stays Latin**, and that is `Kati.Health.Reading`'s doing rather than a
  decision about Persian: `figure/2` writes a stone as `12st 0.4`, with the unit
  inside the numeral, and no msgid reaches that file. A segment reading سنگ over
  a figure reading `12st` would spell one unit two ways on one card — the rule
  the service names follow, one board over. The day the figure folds, this
  clause is the one line to change.
  """
  @spec unit_word(:kg | :lb | :st) :: String.t()
  def unit_word(:lb), do: pgettext("weight unit", "lb")
  def unit_word(:st), do: "st"
  def unit_word(_kg), do: gettext("kg")

  @doc """
  A weight with its unit, in the reader's own digits and words.

  `Kati.Health.Reading.display/2` is the Latin form of this — `0.4 kg` — and it
  cannot answer under `:fa`, where the digits are Persian, the decimal mark is
  U+066B and the unit is a word. The figure still comes from `Reading`, so the
  arithmetic stays in one place and only the typography is composed here.

  Stones carry their unit inside the figure, so that clause adds none — see
  `unit_word/1`.
  """
  @spec amount(integer(), :kg | :lb | :st) :: String.t()
  def amount(grams, :st), do: Kati.Locale.number(Reading.figure(grams, :st))

  def amount(grams, unit),
    do:
      Kati.Locale.number(Reading.figure(grams, unit)) <>
        " " <> Kati.Screens.LogWeight.unit_word(unit)

  @doc false
  def unit_tag(:lb), do: :unit_lb
  def unit_tag(:st), do: :unit_st
  def unit_tag(_kg), do: :unit_kg

  @doc false
  def unit_value(:unit_lb), do: :lb
  def unit_value(:unit_st), do: :st
  def unit_value(_kg), do: :kg

  @doc """
  A tenth of the display unit, in grams.

  The step follows what the user is reading, not what is stored: 0.1 kg is
  100g and 0.1 lb is 45g, and a stepper that moved 100g while the label said
  pounds would jump by 0.22 a press.
  """
  @spec step(:kg | :lb | :st) :: integer()
  def step(:lb), do: 45
  def step(:st), do: 45
  def step(_kg), do: 100

  @doc """
  The stepper: minus, the value with its unit on the baseline, plus.

  The unit is a second `Text` in the same Row rather than a line under it —
  see the moduledoc for why the hero has to read as one value.
  """
  @spec stepper(integer(), atom()) :: map()
  def stepper(grams, unit) do
    figure = Kati.Locale.number(Reading.figure(grams, unit))

    step =
      pgettext("the amount one press of the stepper moves", "%{n} steps",
        n: Kati.Locale.number("0.1")
      )

    assigns = %{
      figure: figure,
      # `kati_mono.ttf` carries none of U+06F0–U+06F9, so `۷۶٫۰` in DM Mono is
      # handed to Android's own substitute face — it renders, in a typeface that
      # is not Kati's, on the biggest number on the sheet. Latin digits keep DM
      # Mono, which is what the drawing sets them in. `Kati.PersianFontTest`.
      figure_face: Kati.Locale.mono_face(figure),
      unit: Kati.Screens.LogWeight.unit_word(unit),
      step: step,
      step_face: Kati.Locale.mono_face(step)
    }

    ~MOB"""
    <Row fill_width={true} align="center">
      {Kati.Screens.LogProgress.step_disc("remove", :step_down)}
      <Spacer size={11} />
      <Column
        weight={1.0}
        height={78}
        corner_radius={20}
        background={Palette.card()}
        shadow={Kati.Theme.shadow_card()}
        align="center"
      >
        <Spacer weight={1.0} />
        <Row fill_width={true} align="bottom">
          <Spacer weight={1.0} />
          <Text
            text={@figure}
            font_family={@figure_face}
            text_size={30}
            font_weight="medium"
            letter_spacing={Kati.Locale.tracking(-0.02)}
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={5} />
          <Text text={@unit} text_size={14} text_color={Palette.muted()} max_lines={1} />
          <Spacer weight={1.0} />
        </Row>
        <Spacer size={5} />
        <Text
          text={@step}
          font_family={@step_face}
          text_size={9.5}
          letter_spacing={Kati.Locale.tracking(0.1)}
          text_align="center"
          text_color={Palette.muted()}
        />
        <Spacer weight={1.0} />
      </Column>
      <Spacer size={11} />
      {Kati.Screens.LogProgress.step_disc("add", :step_up)}
    </Row>
    """
  end

  @doc """
  When it was taken, and the optional note.

  `now` is a control rather than a label, because the commonest correction is
  *I weighed myself this morning and am logging it at lunchtime* — and the
  second commonest is that the default was right.
  """
  @spec when_and_note() :: map()
  def when_and_note do
    taken = Kati.Screens.LogWeight.taken_line()

    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={20}
      padding_left={15}
      padding_right={15}
      shadow={Kati.Theme.shadow_card()}
    >
      <Row fill_width={true} padding_top={13} padding_bottom={13} align="center">
        <Box width={30} height={30} corner_radius={9} background={Palette.paper()} align="center">
          {UI.symbol("event", size: 17, color: Palette.ink_soft())}
        </Box>
        <Spacer size={13} />
        <Column weight={1.0}>
          <Text
            text={gettext("Today")}
            text_size={13.5}
            font_weight="semibold"
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={3} />
          {# The clock line is Persian under `:fa` — a Shamsi month name, not a
           # numeral — and `kati_mono.ttf` has no Arabic-script glyph at all.
           # `Kati.Locale.mono_face/1` asks the STRING which face it needs.}
          <Text
            text={taken}
            font_family={Kati.Locale.mono_face(taken)}
            text_size={11}
            text_color={Palette.sub()}
            max_lines={1}
          />
        </Column>
        <Row
          height={28}
          corner_radius={14}
          background={Palette.paper()}
          padding_left={12}
          padding_right={12}
          align="center"
          on_tap={{self(), :now}}
        >
          <Text
            text={pgettext("the chip that dates a reading to the current clock", "now")}
            text_size={11.5}
            font_weight="semibold"
            text_color={Palette.ink_soft()}
            max_lines={1}
          />
        </Row>
      </Row>
      <Box fill_width={true} height={1} background={Palette.hairline()} />
      <Row fill_width={true} padding_top={13} padding_bottom={13} align="center">
        <Box width={30} height={30} corner_radius={9} background={Palette.paper()} align="center">
          {UI.symbol("sticky_note_2", size: 17, color: Palette.ink_soft())}
        </Box>
        <Spacer size={13} />
        <Column weight={1.0}>
          <Text
            text={gettext("Note")}
            text_size={13.5}
            font_weight="semibold"
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={3} />
          <Text
            text={gettext("Optional — after a run, before breakfast…")}
            text_size={11.5}
            text_color={Palette.sub()}
            max_lines={1}
          />
        </Column>
        {Kati.UI.SettingsList.chevron()}
      </Row>
    </Column>
    """
  end

  @doc """
  `16 August, 07:42` — the device's own clock, not the drawing's, in the
  reader's own calendar.

  Composed from `Kati.Locale.day_of_month/1` and `month_name/2` rather than
  formatted with one `strftime`: `%-d %B` is a GREGORIAN instruction, and under
  `:fa` this row has to read ۲۱ شهریور — the same instant, counted in the
  calendar the reader keeps. `Kati.Locale.date/2` has no style with a full month
  name and no weekday, which is the shape this row wants, so the two halves are
  asked for separately and the comma between them is part of the msgid: Persian
  writes U+060C, not `,`.

  The time is `Kati.Locale.time/1` for its digits. Both scripts read the clock
  in 24 hours — `Kati.Screens.Settings` draws that as a setting of its own
  rather than as a consequence of the language.
  """
  @spec taken_line() :: String.t()
  def taken_line do
    now = Kati.Time.now()
    date = DateTime.to_date(now)

    gettext("%{day} %{month}, %{time}",
      day: Kati.Locale.day_of_month(date),
      month: Kati.Locale.month_name(date),
      time: Kati.Locale.time(now)
    )
  end

  @doc """
  The cream line: how far this is from your last reading, and how long ago.

  Only against the last reading. No target and no ideal range — see the
  moduledoc.
  """
  @spec confirmation(integer()) :: map()
  def confirmation(grams) do
    body = [
      text_size: 13,
      line_height: Kati.Locale.leading(1.55),
      text_color: Palette.cream_body()
    ]

    strong = [font_weight: "semibold", text_color: Palette.cream_ink(), text_size: 13]
    {icon, lead, tail} = Kati.Screens.LogWeight.change(grams)

    Sheet.insight(icon, [{lead, strong}, {" " <> tail, body}])
  end

  @doc """
  The change from the last reading, as `{icon, lead, tail}`.

  A first reading has nothing to compare with and says so rather than claiming
  no change: `Your first reading` is true, and `0.0 kg down` would not be.

  The two arrows are the drawing's; the neutral case takes `insights` instead,
  because `trending_flat` is not in Kati's icon subset and no drawing asks for
  it. Adding a glyph to the font to say *nothing happened* would be a font
  rebuild for a sentence that already says it.
  """
  @spec change(integer()) :: {String.t(), String.t(), String.t()}
  def change(grams) do
    unit = Health.unit()

    case Kati.Screens.LogWeight.stored_previous() do
      nil ->
        Kati.Screens.LogWeight.drawn_change()

      %{grams: last} = entry ->
        diff = grams - last
        ago = Kati.Screens.LogWeight.ago(entry)

        cond do
          diff == 0 ->
            {"lightbulb", gettext("No change"), Kati.Screens.LogWeight.since_line(ago)}

          diff < 0 ->
            {"arrow_downward",
             gettext("%{amount} down", amount: Kati.Screens.LogWeight.amount(abs(diff), unit)),
             Kati.Screens.LogWeight.since_line(ago)}

          true ->
            {"trending_up",
             gettext("%{amount} up", amount: Kati.Screens.LogWeight.amount(diff, unit)),
             Kati.Screens.LogWeight.since_line(ago)}
        end
    end
  end

  @doc """
  The tail all four leads share: what the reading is being compared with.

  One function rather than the same sentence written four times, because it is
  one sentence — and a msgid repeated at four call sites is four chances for a
  translator to be handed the same words twice with a space in a different
  place.
  """
  @spec since_line(String.t()) :: String.t()
  def since_line(ago), do: gettext("from your last reading, %{ago}.", ago: ago)

  @doc """
  The reading this one is being compared with: the newest that is not today's.

  Not simply the newest. The sheet opens on your last weight so you can nudge
  it, so comparing with the newest would compare a value with itself and report
  no change on every single entry. What you want to know is how today differs
  from the last time you stood on the scale, which is a different day by
  definition.

  ## Today's label is built, not formatted a second time

  A row carries its date as the string it is DRAWN as, so *is this one today's*
  is asked by comparing two labels — and this end of the comparison used to
  build its own with `strftime("%d %b")` while `Kati.Screens.Weight.entries/1`
  built the other with `Kati.Locale.date/2`. Two formatters, two answers:
  padded against unpadded meant nothing matched on the first nine days of any
  month, and after mishka-group/kati#103 a Persian reader's rows say ۲۱ شهریور
  while this said `12 SEP`, so *every* day missed. The sheet then compared the
  weight you are typing with itself and said `No change` under it.

  So the label comes out of the same two functions the row's did, and
  `label_key/1` is the one difference they are allowed to have.
  """
  @spec previous() :: map() | nil
  def previous do
    today = label_key(Kati.UI.eyebrow_label(Kati.Locale.date(Kati.Time.today(), :short)))

    Kati.Screens.Weight.entries()
    |> Enum.reject(&(label_key(&1.date) == today))
    |> List.first()
  end

  @doc """
  `previous/0`, but `nil` when the series is the drawing rather than the user's.

  The drawing's four readings are dated 6-16 August and the confirmation it
  draws — *0.4 kg down from your last reading, three days ago* — is true on 16
  August and on no other day. Computing it against the drawing on a Tuesday in
  November would print a real-looking sentence about a fixture.

  So the fallback path returns the drawing's own confirmation, whole, exactly
  as every other fallback in this app does. The clock line above it is the one
  value that still reads the device, because a clock is not data.
  """
  @spec stored_previous() :: map() | nil
  def stored_previous do
    case Kati.Screens.Weight.entries() do
      entries when entries == [] -> nil
      _entries -> if drawing?(), do: nil, else: Kati.Screens.LogWeight.previous()
    end
  end

  defp drawing?, do: Kati.Screens.Weight.entries() == Kati.Screens.Weight.drawn_entries()

  @doc """
  How long ago a reading was, in the drawing's own words.

  `three days ago` rather than `3 days ago`: the sentence is prose and the
  figure is small, and a numeral inside a sentence reads as data. Past ten it
  becomes a numeral, because `seventeen days ago` does not — see `days_ago/1`,
  which is also where that convention stops at the script boundary.
  """
  @spec ago(map()) :: String.t()
  def ago(%{date: date}) do
    case Kati.Screens.LogWeight.days_since(date) do
      nil ->
        # A row whose label names no day this year. See `days_since/1`: a date
        # with no year in it stops being answerable somewhere, and a vague
        # phrase is the honest end of it rather than a guessed number.
        pgettext("how long ago a reading was, when its day cannot be read", "last time")

      0 ->
        gettext("earlier today")

      1 ->
        gettext("yesterday")

      n ->
        Kati.Screens.LogWeight.days_ago(n)
    end
  end

  @doc """
  `three days ago`, `17 days ago`, `۳ روز پیش`.

  The spelled-out form is a LATIN convention and stops at the script boundary:
  Persian writes the numeral inside a sentence — board 115's own `۲ ماه` is the
  nearest example — and has no word form to mirror, so `Kati.Locale.pick/2` is
  where the two answers meet and only the English one is ever spelled.

  `ngettext/4` over a msgid the catalogue already carries from
  `Kati.Settings.Watcher`. Persian does not inflect a noun after a numeral, so
  its two plural forms are the same words; English needs both because this is
  also what a one-day gap would say if `ago/1` did not answer that with
  *yesterday*.
  """
  @spec days_ago(pos_integer()) :: String.t()
  def days_ago(n) when is_integer(n) and n > 0 do
    ngettext("%{n} day ago", "%{n} days ago", n,
      n: Kati.Locale.pick(spelled(n), Kati.Locale.number(n))
    )
  end

  defp spelled(n) when n <= 10,
    do: Enum.at(~w(zero one two three four five six seven eight nine ten), n)

  defp spelled(n), do: Integer.to_string(n)

  @doc """
  How many days ago the reading behind this row label was taken, or `nil`.

  ## Why it formats rather than parses

  `Kati.Screens.Weight.entries/1` formats each row's date for READING —
  `Kati.UI.eyebrow_label/1` over `Kati.Locale.date/2` — so the string handed
  here is `9 SEP` for one reader and `۱۸ شهریور` for another, of the same day.
  This used to split it on a space, `Integer.parse/1` the first half and look
  the second up in `~w(JAN FEB MAR …)`, which can only answer in one language
  and one calendar: after mishka-group/kati#103 every Persian row fell through
  to `nil`, and the sheet told that reader *دفعه پیش* whatever the date was.

  It cannot parse its way out of that, because a Shamsi month name is not a
  translation of a Gregorian one — it is a different month, and ۲۱ شهریور is
  arithmetic rather than vocabulary. So it goes the other way and formats
  instead: each of the last 366 days, in the reader's own calendar, through the
  same two functions the label came out of. The first match is the day, in any
  locale, with no second copy of the formatting rule to keep in step.

  It also answers the year boundary the parser got wrong. `Date.new(today.year,
  …)` dated a December row into THIS year, so in January the difference came
  out negative and `Enum.at/2` read the word list from its end — `-20` fell off
  it entirely and the sentence was built out of `nil`. Nothing here can be
  negative: it only ever walks backwards from today.

  Past a year, `nil`. A label with no year in it cannot tell this September
  from the last one, so answering at all beyond that is a guess, and `ago/1`
  says *last time* instead.
  """
  @spec days_since(String.t()) :: non_neg_integer() | nil
  def days_since(label) when is_binary(label) do
    today = Kati.Time.today()
    wanted = label_key(label)

    Enum.find_value(0..366, fn n ->
      day = Date.add(today, -n)
      if label_key(Kati.UI.eyebrow_label(Kati.Locale.date(day, :short))) == wanted, do: n
    end)
  end

  def days_since(_other), do: nil

  # `09 SEP` and `9 SEP` are the same day. The stored rows are formatted
  # `:short` and the drawing's own `:short_padded`, and a leading zero is a
  # column-alignment choice rather than a different date — Persian pads nothing,
  # because its numerals are already even-width, which is why
  # `Kati.Locale.date/2` maps `:short_padded` onto `:short` under `:fa`.
  defp label_key(label) when is_binary(label), do: String.replace_prefix(label, "0", "")
  defp label_key(_other), do: nil

  def handle_info({:tap, :close}, socket), do: {:noreply, Kati.Screens.Resume.pop(socket)}

  def handle_info({:tap, :step_up}, socket) do
    step = Kati.Screens.LogWeight.step(socket.assigns.unit)
    {:noreply, Mob.Socket.assign(socket, :grams, socket.assigns.grams + step)}
  end

  def handle_info({:tap, :step_down}, socket) do
    step = Kati.Screens.LogWeight.step(socket.assigns.unit)
    {:noreply, Mob.Socket.assign(socket, :grams, max(socket.assigns.grams - step, step))}
  end

  # Changing the unit here converts nothing: the grams stay, the label changes,
  # and the number under it is the same weight said differently. That is what
  # makes it a correction rather than a rewrite — see the moduledoc.
  def handle_info({:tap, tag}, socket) when tag in [:unit_kg, :unit_lb, :unit_st] do
    unit = Kati.Screens.LogWeight.unit_value(tag)
    Health.put_unit(unit)
    {:noreply, Mob.Socket.assign(socket, :unit, unit)}
  end

  def handle_info({:tap, :now}, socket), do: {:noreply, socket}

  def handle_info({:tap, :save}, socket) do
    case save_reading(socket.assigns.grams) do
      {:ok, _reading} ->
        {:noreply,
         socket
         |> Mob.Socket.assign(:save_error, nil)
         |> Kati.Screens.Resume.pop()}

      {:error, _reason} = error ->
        {:noreply, Mob.Socket.assign(socket, :save_error, Write.message(error))}
    end
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  @doc """
  Write the reading, in grams, dated today.

  Returns what `Ash.create/2` returned, noted on the way out — never a bare
  `:ok`. There is no `rescue` here because there is nothing to catch:
  `Ash.create/2` answers `{:error, changeset}` rather than raising, so the
  rescue this replaced never ran, and the failure it was meant to cover had
  already been thrown away by the `:ok` on the line above it. See `Kati.Write`.
  """
  @spec save_reading(integer()) :: {:ok, term()} | {:error, term()}
  def save_reading(grams) do
    Reading
    |> Ash.create(%{
      grams: grams,
      taken_on: Kati.Time.today(),
      taken_at: Kati.Time.now() |> DateTime.truncate(:second)
    })
    |> Write.note("log weight")
  end

  @doc """
  The confirmation the drawing prints, or the sentence a first reading gets.

  Two answers behind one `nil`, and they are the same shape: with the drawing's
  series there is a change to state and it is the drawing's; with nothing at
  all there is nothing to compare and the sheet says so rather than inventing a
  delta.

  ## The drawing's sentence is built here, not quoted from the fixture

  `Kati.Health.WeightSample.confirmation/0` holds it as two frozen English
  strings — *0.4 kg down* and *from your last reading, three days ago.* — and
  a fixture cannot be translated: no msgid reaches a literal, so this was the
  one sentence on the sheet a Persian reader met in Latin. It is composed here
  instead, out of the msgids the live path already uses, with the drawing's own
  figures in them — so board 111 reads word for word what it always did in
  Latin, and reads as a sentence in Persian.

  Board 111 is the source for both, not one for the other: the fixture quotes it
  in English for the screens that want it as data, and this quotes it in the
  reader's own language for the one place it is read as prose. The fixture keeps
  `direction`, which is the half of it that is not copy, and
  `drawn_confirmation/0` still hands the whole thing over untouched.
  """
  @spec drawn_change() :: {String.t(), String.t(), String.t()}
  def drawn_change do
    if Kati.Screens.Weight.entries() == Kati.Screens.Weight.drawn_entries() do
      drawn = Kati.Locale.number("0.4") <> " " <> Kati.Screens.LogWeight.unit_word(:kg)

      {"arrow_downward", gettext("%{amount} down", amount: drawn),
       Kati.Screens.LogWeight.since_line(Kati.Screens.LogWeight.days_ago(3))}
    else
      {"lightbulb", gettext("Your first reading"),
       gettext("— there is nothing to compare it with yet.")}
    end
  end

  @doc false
  def drawn_confirmation, do: WeightSample.confirmation()
end
