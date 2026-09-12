defmodule Kati.Health.WeightSample do
  use Gettext, backend: Kati.Gettext

  @moduledoc """
  Screens 109, 111 and 112, as the drawings captured them.

  The two weight screens share one series, because the sheet's confirmation —
  *0.4 kg down from your last reading, three days ago* — is arithmetic over the
  same list the page charts. A second copy would let the two disagree about
  what "your last reading" was.
  """

  alias Kati.Health.Medication

  # A drawn entry, with its date and figure formatted where they are read.
  # Board 115 writes `۱۴ اردیبهشت` and `۷۶٫۰` for the same day and the same
  # number, and a frozen string could not answer both.
  defp entry(on, figure, delta, grams) do
    %{
      date: Kati.UI.eyebrow_label(Kati.Locale.date(on, :short_padded)),
      weight: Kati.Locale.number(figure) <> " " <> gettext("kg"),
      delta: Kati.Locale.number(delta),
      grams: grams
    }
  end

  @doc "The four entries screen 109 lists, newest first."
  @spec entries() :: [map()]
  def entries do
    [
      entry(~D[2026-08-16], "76.0", "−0.4", 76_000),
      entry(~D[2026-08-13], "76.4", "+0.1", 76_400),
      entry(~D[2026-08-09], "76.3", "−0.2", 76_300),
      entry(~D[2026-08-06], "76.5", "−0.6", 76_500)
    ]
  end

  @doc """
  The hero: the latest reading and how far it is from where the series began.

  `DOWN FROM 78.4 ON 4 MAY` reaches back past the four entries above, which is
  the drawing's own asymmetry and is right: the list shows recent changes, the
  hero shows the whole arc.
  """
  @spec latest() :: map()
  def latest do
    %{
      label: gettext("Latest · today"),
      figure: Kati.Locale.number("76.0"),
      unit: gettext("kg"),
      direction: :down,
      change: Kati.Locale.number("2.4") <> " " <> gettext("kg"),
      since:
        Kati.UI.eyebrow_label(
          gettext("down from %{figure} on %{date}",
            figure: Kati.Locale.number("78.4"),
            date: Kati.Locale.date(~D[2026-05-04], :short)
          )
        )
    }
  end

  @doc "The chart's bars, oldest first, with the two axis labels the drawing prints."
  @spec bars() :: [float()]
  def bars do
    # Read off the drawing: a slow decline with two rises in it, which is what
    # a real series looks like and what a generated one never does.
    [1.0, 0.94, 0.97, 0.88, 0.83, 0.86, 0.79, 0.74, 0.77, 0.71, 0.66, 0.69, 0.62, 0.58]
  end

  @doc "The two labels under the chart."
  @spec axis() :: {String.t(), String.t()}
  def axis,
    do:
      {Kati.UI.eyebrow_label(Kati.Locale.date(~D[2026-05-04], :short)),
       Kati.UI.eyebrow_label(gettext("today"))}

  @doc """
  Screen 111's confirmation, as drawn — and the two halves stay English.

  The one term in this module that is deliberately NOT folded, and
  `Kati.Screens.LogWeight.drawn_change/0`'s doc is where the argument lives:
  the sheet composes board 111's sentence out of the msgids the live path
  already uses — `%{amount} down` and `from your last reading, %{ago}.` — with
  the drawing's own figures in them, so a Persian reader meets it as prose
  rather than as a quotation. This term is what is left over: the board quoted
  verbatim, for a caller that wants it as DATA.

  `direction` is the half of it that is not copy, and is the half every caller
  actually reads. Wording these two again here would mint a second pair of
  msgids able to disagree with the sheet's in Persian while agreeing in Latin,
  which is the drift the arrangement exists to prevent.
  """
  @spec confirmation() :: map()
  def confirmation do
    %{direction: :down, lead: "0.4 kg down", tail: "from your last reading, three days ago."}
  end

  @doc """
  Screen 112's four doses for today, in clock order.

  **The names stay Latin and the sentences fold**, which is
  `Kati.Screens.MedicationDetail.drawn_medication/0`'s rule applied to the
  column beside it, in the words it uses: a medication's name is whatever the
  pharmacy printed and the reader typed into `Kati.Health.Medication.name`, no
  msgid ever reaches a stored row, and a fixture that transliterated would
  spell one drug two ways — Persian here, Latin the moment the reader saves a
  prescription of their own. Board 115 draws منیزیم and this draws Magnesium
  for exactly the reason board 127 draws `Lumen+` in Latin on a Persian page.
  The dose and the instruction are the other half of that: they are the
  BOARD's own sentences, drawn where a row would be, and an English sentence
  is the thing mishka-group/kati#103 exists to remove.

  `time` is NOT converted here. `Kati.Screens.Medication.dose_row/1` runs it
  through `Kati.Locale.number/1` where it is drawn and says why — the same
  value has to stay `"08:00"` all the way into a changeset, and
  `Kati.MedicationQuietDayTest` pins that list.
  """
  @spec doses() :: [map()]
  def doses do
    [
      %{
        time: "08:00",
        name: "Levothyroxine",
        line: dose_line(gettext("50 mcg"), gettext("before food")),
        state: :taken
      },
      %{
        time: "13:00",
        name: "Vitamin D",
        line: dose_line(gettext("1000 IU"), nil),
        state: :taken
      },
      %{time: "14:00", name: "Iron", line: dose_line(gettext("65 mg"), nil), state: :missed},
      %{
        time: "21:00",
        name: "Magnesium",
        line: dose_line(gettext("200 mg"), gettext("with water")),
        state: :taken
      }
    ]
  end

  @doc """
  Screen 112's schedules, in the order the group lists them.

  The clock times inside `every morning, 08:00` and `every night, 21:00` are
  translated WITH the sentence rather than passed through
  `Kati.Locale.number/1`, because they are figures the copy quotes and not
  figures the page read — `Kati.Screens.AddMedication.method_note/0` states
  that split and `Kati.Screens.MedicationDetail`'s quiet-hours row repeats it.
  The msgids are `Kati.Screens.AddMedication.row_of/1`'s own, so the drawing's
  schedules and board 188's example read the same words in both scripts.
  """
  @spec schedules() :: [map()]
  def schedules do
    [
      %{
        name: "Levothyroxine",
        line: schedule_line(gettext("50 mcg"), gettext("every morning, 08:00"))
      },
      %{name: "Vitamin D", line: schedule_line(gettext("1000 IU"), gettext("daily, 13:00"))},
      %{name: "Iron", line: schedule_line(gettext("65 mg"), gettext("Mon, Wed, Fri"))},
      %{name: "Magnesium", line: schedule_line(gettext("200 mg"), gettext("every night, 21:00"))}
    ]
  end

  # The two second lines are composed by the functions that compose a STORED
  # row's, not written out with their middots in them.
  # `Kati.Screens.AddMedication.row_of/1` takes the same route and gives the
  # reason: a second copy of *join the non-empty parts with a middot* is a
  # second reader, and screen 112 draws these lines directly beside lines that
  # composer built — so a Persian middot that gained a space on one path and
  # not the other would show up as two list styles on one page.
  defp dose_line(dose, instruction),
    do: Medication.dose_line(%Medication{dose: dose, instruction: instruction})

  defp schedule_line(dose, schedule),
    do: Medication.schedule_line(%Medication{dose: dose, schedule: schedule})

  @doc """
  The reminder screen 112 draws as the notification it becomes.

  Drawn on the page rather than only on the lock screen, because the three
  actions on it — Taken, Skip, Snooze — are the whole reason the reminder is
  worth arming, and a user deciding whether to turn it on needs to see them.
  """
  @spec reminder() :: map()
  def reminder do
    %{
      # **KATI** is the app's name and stays Latin in both scripts — a
      # transliterated brand is one thing spelled two ways — and the clock
      # beside it CONVERTS, because it is a time the card draws rather than one
      # the copy quotes. `Kati.Screens.Medication.reminder/1` composes the live
      # line as `"KATI · " <> Kati.Locale.number(at)` and
      # `Kati.Screens.MedicationEmpty.reminder_caption/0` argues it at length;
      # this was the third place, and the only one still frozen.
      app: "KATI · " <> Kati.Locale.number("21:00"),
      # The name stays Latin and the dose folds — see `doses/0`. `pgettext/2`
      # rather than `gettext/1` because `%{name} — %{dose}` is two placeholders
      # and an em dash, and `mix gettext.merge` fuzzy-matches a msgid that
      # short against any sentence shaped like it.
      #
      # Composed rather than held as one sentence so the dose is the SAME msgid
      # the card's own body and screen 112's list already use: the bubble is a
      # picture of the 21:00 dose two bands above it, and two msgids for
      # `200 mg` would let the picture and the row disagree in Persian while
      # agreeing in Latin.
      title:
        pgettext("the medication reminder's title", "%{name} — %{dose}",
          name: "Magnesium",
          dose: gettext("200 mg")
        ),
      # Board 112's own wording, not the `dose · instruction` the live reminder
      # composes — `Kati.Screens.MedicationEmpty.caption_note/0` is the caption
      # about that mismatch, and its Persian already quotes this line as
      # «با آب، پیش از خواب». This is that wording and not a second one, which
      # is what that caption means by *the two agree again the moment
      # `Kati.Health.WeightSample` folds*.
      body: gettext("With water, before bed"),
      # The three labels are still the drawing's rather than a fact about this
      # reader — `Kati.Screens.Medication.reminder/1` keeps reading them from
      # here for that reason — and quoting the board is not the same as
      # freezing its script. `Taken` and `Skip` are the msgids the two verbs
      # under the dose list already carry, so the picture of a control says
      # exactly what the control says.
      actions: [gettext("Taken"), gettext("Skip"), gettext("Snooze")]
    }
  end

  @doc "Screen 112's header subtitle."
  @spec doses_subtitle() :: String.t()
  def doses_subtitle,
    do:
      Kati.UI.eyebrow_label(gettext("Sunday 16 August")) <>
        " · " <> Kati.Screens.Medication.count_clause(4)
end
