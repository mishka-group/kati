defmodule Kati.Health.Sample do
  use Gettext, backend: Kati.Gettext

  @moduledoc """
  Stand-in Health data, until the sections it contains are real.

  Screen 42's note is the architectural claim the whole screen exists to make:
  *"Health is a container, not a feature. Each tile is an independent section
  with its own shelf, calendar feed and home card."* So the tiles are not a
  menu — they are a list of sections, two switched on and four not, and that
  distinction is the only state a tile has.

  Which is why `sections/0` returns tiles with an `on?` flag rather than two
  separate lists: the drawing lays live and unbuilt tiles in one wrapping grid,
  interleaved by nothing but order, and splitting them here would invent a
  grouping the design does not have.

  ## What this module owes a Persian reader — mishka-group/kati#103

  `Kati.Screens.Health` draws every string below and writes none of them: the
  hero, the meal row, the grid and the closing note all read out of here, and
  `drawn_day/0` is what the screen falls back to with nothing planned. So the
  fold lands in this file rather than in the screen, and the screen's own half
  is already done — every `Text` there asks `Kati.Locale.mono_face/1` about the
  string it is given, goes through `Kati.UI.eyebrow_label/1` rather than
  `String.upcase/1`, and takes its chevron from `Kati.Locale.forward_chevron/0`.
  Nothing here draws, so nothing here picks a face or a glyph.

  Each run is composed the way `Kati.Screens.Health` composes the DERIVED one
  it replaces — same msgid, same interpolation, same separator — so the card a
  reader sees over a real meal plan and the card they see over the fixture
  cannot word the same fact two ways. Where the screen has no derived twin
  (the grid's lines, the closing note) the msgid is borrowed from the screen
  that owns the sentence: `Kati.Screens.Habits.subtitle/1` for the streak line,
  `Kati.Meals.SampleToday.plan/0` for the plan's name.

  The figures stay the drawing's and go through `Kati.Locale.number/1`. They
  are set in DM Mono in Latin and in Vazirmatn under `:fa` — `kati_mono.ttf`
  carries none of U+06F0–U+06F9 — so there is no reason for `1,480` to be the
  one figure on a Persian card still counted in Latin digits.

  `name:` on `sections/0` is the one string that stays Latin, and `sections/0`
  carries the argument for why.
  """

  @doc "The mono line under the title — the day this screen is showing."
  @spec day_line() :: String.t()
  # The drawing's day as a DATE rather than as a sentence. `Kati.Locale.date/2`'s
  # `:full` is `%A %-d %B` in Latin, so English still reads `Sunday 16 August`
  # byte for byte, and `:fa` gets یکشنبه ۲۵ مرداد — which `Kati.Calendar.Shamsi`
  # works out rather than looks up. `Kati.Screens.Health.logged_day/4` formats
  # the live day line with exactly this call and its comment carries the whole
  # argument: the two are one day in two CALENDARS and neither is a formatting
  # of the other, which is the half of mishka-group/kati#103 a catalogue cannot
  # do. The fallback and the derived line are one shape with two dates now,
  # rather than a formatted date beside a frozen sentence.
  #
  # 16 August 2026 and not `Kati.Time.today/0`. This is the day the DRAWING
  # shows, and dating a fixture with the device's today would put a real date
  # on invented figures — the rule `Kati.Screens.MedicationEmpty.subtitle/0`
  # states for its own header and `Kati.Health.WeightSample.entry/3` keeps for
  # its four readings.
  def day_line, do: Kati.Locale.date(~D[2026-08-16], :full)

  @doc """
  Today's intake, as the cream hero draws it.

  `eaten` and `target` are two runs because the drawing sets them at 34 and 16
  on one baseline; `macros` are the three segments of the 9pt bar, stored with
  the weight each takes so the bar is declared rather than recomputed from
  grams — the export's own 31/44/25 split.
  """
  @spec eaten() :: map()
  # Run for run, this is `Kati.Screens.Health.logged_day/4`'s `eaten` map with
  # the drawing's figures in place of the day's. Same msgids, so the hero says
  # one thing whether it counted a real day or fell back here.
  #
  # The three `tone`s are still light-mode hex literals — the drawing's own
  # `#1A1917`, `#B08E55`, `#E4D2B0`, where the derived split reaches for
  # `Kati.Theme.Palette`. That is a dark-mode question rather than a language
  # one and it is left exactly as it was.
  def eaten do
    %{
      label: gettext("Eaten today"),
      # `1,480` and not `1480`: the grouping is the drawing's, and the group
      # MARK stays ASCII in both scripts while the decimal point converts —
      # `Kati.Locale.number/1`'s own note sets that split out, and
      # `test/design/screens/59.html` draws ۱,۴۸۰ with a Latin comma.
      calories: Kati.Locale.number("1,480"),
      # The leading space and the slash stay OUT of the catalogue, for the
      # reason `Kati.Screens.Health.target_run/1` gives over the derived run:
      # ` / %{count} kcal` is a leading space and two words around a separator,
      # which is precisely the shape `mix gettext.merge` fuzzy-matches onto any
      # sentence ending the same way. The separator is punctuation between two
      # runs on one baseline, not copy — and nothing mirrors it, because the
      # bridge's `layout_direction` puts the target run to the left of the 34pt
      # figure under `:fa` and the line still reads ۱,۴۸۰ / ۲,۱۰۰ کالری from
      # the right.
      target: " / " <> gettext("%{count} kcal", count: Kati.Locale.number("2,100")),
      # `pgettext/2` rather than `gettext/1`: two numbers and a preposition is
      # exactly the length `mix gettext.merge` fuzzy-matches, and the catalogue
      # already carries `Week %{n} of %{total}` for it to land on.
      meals:
        pgettext("meals logged out of the day's total", "%{n} of %{total}",
          n: Kati.Locale.number(3),
          total: Kati.Locale.number(5)
        ),
      # The names are the legend's copy and nothing keys on them:
      # `Kati.Screens.Health.macro_bar/1` reads the share and the tone and
      # drops the name, and `legend/1` draws it. The same three msgids
      # `Kati.Screens.Health.macro_split/1` uses over derived grams, so the app
      # names a macro once.
      macros: [
        {gettext("Protein"), 0.31, 0xFF1A1917},
        {gettext("Carbs"), 0.44, 0xFFB08E55},
        {gettext("Fat"), 0.25, 0xFFE4D2B0}
      ],
      # The three letters are the INITIALS of the three names above, so they go
      # where the names go: the catalogue already writes this line
      # `%{protein}پ · %{carbs}ک · %{fat}چ`, and one app should not abbreviate
      # پروتئین two ways. That makes the whole run non-ASCII under `:fa`, which
      # is why `Kati.Screens.Health.eaten/1` asks `Kati.Locale.mono_face/1`
      # about it rather than naming `mono`.
      grams:
        gettext("%{protein}P · %{carbs}C · %{fat}F",
          protein: Kati.Locale.number(118),
          carbs: Kati.Locale.number(163),
          fat: Kati.Locale.number(41)
        )
    }
  end

  @doc "The one live section with something happening in it right now."
  @spec next_meal() :: map()
  # Composed the way `Kati.Screens.Health.row/4` composes the derived row — the
  # verb, an em dash, the slot and the clock — rather than frozen as one
  # sentence. A frozen sentence would leave `19:30` in Latin numerals inside a
  # Persian line; asked for, it is ۱۹:۳۰, and 24-hour in both scripts because
  # the design draws that as a setting of its own rather than as a consequence
  # of the language.
  #
  # `String.downcase/1` over `Dinner` is the call `dash/2` makes on a slot name,
  # and it is a no-op on Persian rather than a mangling — the Arabic script has
  # no case — so شام comes back شام while English still reads `dinner`.
  def next_meal do
    %{
      title:
        gettext("Open Meals") <>
          " — " <> String.downcase(gettext("Dinner")) <> " " <> Kati.Locale.time(~T[19:30:00]),
      line:
        gettext("%{title} · %{kcal} kcal",
          title: gettext("Miso salmon, greens, rice"),
          kcal: Kati.Locale.number(620)
        )
    }
  end

  @doc """
  The six sections Health holds, in the order the grid wraps them.

  A tile that is `on?` carries a status dot and a real line; one that is not
  carries a dashed outline and *"Not set up"*. Nothing else differs, which is
  the point: switching one on is a state change, not a new screen.
  """
  @spec sections() :: [map()]
  # `id:` is not decoration and not a key into anything else: it is what a
  # caller asks `Kati.Retired.known?/1` with. `Kati.Screens.HealthEmptyStates`
  # asked with `name`, which is drawn — so the two dashed tiles would have
  # stopped being tappable the day this grid was read in Persian, silently.
  # mishka-group/kati#103.
  #
  # ## Every LINE below folds into the catalogue and `name:` does not
  #
  # That looks inconsistent and is the opposite. A line is copy; a name is
  # still **compared state**, and three lookups outside this file match against
  # the English word with no `id` path to take instead:
  #
  #   * `Kati.Screens.Health.built?/1` is a hand-kept list of four English
  #     names, and `Kati.Screens.RetiredTile.unbuilt/0` filters this list
  #     through it;
  #   * `Kati.Screens.RetiredTile.section_subject/1` finds a section by
  #     `&1.name == name`, then falls back to `&1.name == "Sleep"`;
  #   * `Kati.Screens.States` and `Kati.Screens.NotificationAccess` both push
  #     `%{section: "Sleep"}` into that lookup, and both say in as many words
  #     that they are pushing a key rather than a label.
  #
  # Fold `name` into `gettext/1` and all three miss under `:fa`: `built?/1`
  # answers false for every tile, so `unbuilt/0` returns all six; both
  # `Enum.find/2`s answer `nil`; and `label(nil)` raises inside `mount/3` —
  # screen 114 failing to open at all for a Persian reader, which is the same
  # *label doubling as compared state* defect this fold is about, only fatal
  # instead of silent. `Kati.Screens.Health.tile_key/1` has already taken the
  # other half of the move and routes a TAP by `id`; the sheet's half is a
  # change to those files, not to this one.
  #
  # So the word stays here as a key and the word a reader reads comes off
  # `Kati.Screens.RetiredTile.label/1`, which is keyed on `id` and is already
  # Persian. The one place still short is screen 42's own grid, which draws
  # `section.name` straight — six Latin section names on a Persian board until
  # that lookup moves to `id` as well.
  def sections do
    [
      %{
        id: :meals,
        icon: "restaurant",
        name: "Meals",
        # `Kati.Screens.Health.plan_line/2` joins a real plan's name to its
        # derived week with this middot, and this is that line with the
        # drawing's plan in it. `Cutting v3` is already in the catalogue as
        # `Kati.Meals.SampleToday.plan/0` — screen 43 draws the same fixture
        # plan and the two boards must not name it two ways — and `week %{n}`
        # takes the meal screens' own context, lower case because this is the
        # tail of a line rather than a heading.
        line:
          gettext("Cutting v3") <>
            " · " <> pgettext("meal plan, mid-sentence", "week %{n}", n: Kati.Locale.number(6)),
        on?: true,
        dot: 0xFF1A1917
      },
      %{
        id: :habits,
        icon: "bolt",
        name: "Habits",
        # `Kati.Screens.Habits.subtitle/1`'s msgid exactly, with the drawing's
        # two figures where the derived ones go. The screen that owns the
        # sentence and the tile that quotes it cannot drift apart, and both
        # numbers are interpolated rather than concatenated so Persian can put
        # the streak where Persian puts it: ۴ فعال · بهترین رشته ۱۲ روز.
        line:
          gettext("%{count} active · %{n}-day best",
            count: Kati.Locale.number(4),
            n: Kati.Locale.number(12)
          ),
        on?: true,
        dot: 0xFF4E9A73
      },
      # `Not set up` is the catalogue's existing msgid and not a new one.
      # `Kati.Screens.HealthEmptyStates.nothing_set_up/0` overwrites this line
      # with the same words for its own band, which is the point: an outline
      # says *not set up* in one wording wherever it is drawn.
      %{id: :sleep, icon: "bedtime", name: "Sleep", line: gettext("Not set up"), on?: false},
      # Weight and Medication stopped being outlines when screens 109 and 112
      # landed. Both now carry a real line and a dot, which is what `on?` has
      # always meant on this grid: switching a section on is a state change, not
      # a new screen. Sleep and Workouts are still unbuilt and still dashed.
      %{
        id: :weight,
        icon: "monitor_weight",
        name: "Weight",
        # The figure and the change are `Kati.Health.WeightSample.latest/0`'s
        # own two numbers, said in one line rather than in a hero and a pill.
        # `kg` sits inside the msgid because the word is what moves —
        # کیلوگرم is longer than the figure it follows and Persian puts it
        # where Persian puts it — while both numerals are interpolated so they
        # arrive as ۷۶٫۰ and ۲٫۴, with the U+066B decimal mark board 115 draws
        # and `Kati.Locale.number/1` supplies.
        line:
          gettext("%{figure} kg · down %{change}",
            figure: Kati.Locale.number("76.0"),
            change: Kati.Locale.number("2.4")
          ),
        on?: true,
        dot: 0xFF4E9A73
      },
      %{
        id: :workouts,
        icon: "fitness_center",
        name: "Workouts",
        line: gettext("Not set up"),
        on?: false
      },
      %{
        id: :medication,
        icon: "medication",
        name: "Medication",
        # `ngettext/4` rather than a frozen `4 doses today`: the fixture's four
        # is a number the day could answer differently, and English inflects
        # the noun after it. Persian does not, so both forms are the same
        # sentence. `dose` is the word `Kati.Screens.Medication.count_clause/1`
        # already puts in the catalogue; the difference here is `today`, which
        # this tile says and that eyebrow does not.
        line: ngettext("%{n} dose today", "%{n} doses today", 4, n: Kati.Locale.number(4)),
        on?: true,
        dot: 0xFF1A1917
      }
    ]
  end

  @doc "The design's own explanation of the screen, drawn inside the screen."
  @spec container_note() :: String.t()
  # `Kati.Screens.Health.container_note/0` prints this and takes no text, so the
  # sentence is translated here or not at all. It is the one real paragraph on
  # the board, which is why that function asks `Kati.Locale.leading/1` for
  # Vazirmatn's own line height over it rather than setting the drawing's 1.55
  # solid.
  #
  # The Persian keeps the app's own nouns rather than inventing a second set:
  # کاشی for a tile, بخش for a section, قفسه for a shelf. And the three places
  # a section shows up in are named with `Kati.Settings.Sample`'s own phrase
  # for them — کارت خانه، تقویم، قفسه — so the sentence that states the rule
  # and the row that lists the three places name them the same way.
  def container_note do
    gettext(
      "Health is a container, not a feature. Each tile is an independent " <>
        "section with its own shelf, calendar feed and home card — switch one " <>
        "on and it appears everywhere."
    )
  end
end
