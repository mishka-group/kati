defmodule Kati.Locale do
  @moduledoc """
  Kati's active locale and its writing direction.

  The locale is an **in-app setting**, not `Locale.getDefault()`. A Persian user
  on an English phone must still get Persian and RTL, and the two must never
  disagree — which is why the direction is derived from this value and passed
  down as a prop rather than read natively at the leaves.

  Stored in `Mob.State` (DETS, SIGKILL-safe) so it survives a restart.
  """

  @locales [:en, :fa]
  @default :en

  @doc "Every locale Kati ships. Machinery supports more; translations do not."
  def supported, do: @locales

  @doc "The active locale."
  @spec current() :: :en | :fa
  def current do
    # `as/2`'s override first: a screen that draws both languages at once has
    # said which one this expression belongs to, and the stored preference is
    # the wrong answer inside it.
    case Process.get(:kati_locale_override) do
      l when l in @locales ->
        l

      _none ->
        stored()
    end
  end

  # A read that cannot reach its store answers the default rather than raising.
  #
  # `Mob.State` is a GenServer, and a pure unit test — one with no
  # `Mob.ScreenCase` and no store — has none. Every fixture in the app went
  # through `gettext/1` during mishka-group/kati#103, so every such test began
  # calling this, and a locale lookup taking a test down is the wrong failure
  # to have: the answer with no store is `:en`, which is exactly what
  # `Kati.Theme.Mode.choice/0` and `Kati.Screens.Settings.last_backup/0` do
  # with the same store.
  defp stored do
    case Mob.State.get(:locale, @default) do
      l when l in @locales -> l
      _ -> @default
    end
  rescue
    _error -> @default
  catch
    :exit, _reason -> @default
  end

  @doc """
  Set the active locale, and resolve it into the calling process.

  Both halves, for the reason `Kati.Screens.Settings.put_choice/1` gives about
  the theme: storing the preference and snapshotting it are two different
  things, and storing without activating is a correct setting nobody can see
  until the next screen mounts.
  """
  @spec put(:en | :fa) :: :ok
  def put(locale) when locale in @locales do
    Mob.State.put(:locale, locale)
    activate()
  end

  @doc "Writing direction for a locale."
  @spec direction(atom()) :: :ltr | :rtl
  def direction(:fa), do: :rtl
  def direction(_), do: :ltr

  @doc "Writing direction of the active locale, as the string the bridge expects."
  @spec direction_prop() :: String.t()
  def direction_prop do
    case direction(current()) do
      :rtl -> "rtl"
      :ltr -> "ltr"
    end
  end

  @doc """
  The typeface a locale's own text is set in, as the string the bridge expects.

  The twin of `direction_prop/0`, and it travels the same way: on the ROOT node
  of the three shared frames, where `MainActivity` reads it (`K-48
  locale-face-root`) and installs it as the default every `Text` falls back to.

  This is the half a screen cannot reach. A `Text` a screen writes can carry
  `font_family`; a `Text` a **component** builds cannot — `MishkaChip`'s
  `expand/3` discards its children, and `MishkaSegmentedControl` and
  `MishkaNavLink` take their labels as strings — and `MobBridge`'s
  `fontFamilyProp` resolved that missing prop to Plus Jakarta Sans, which
  carries no Arabic-script glyph at all. Android then substitutes its own face,
  so the sentence renders, correctly shaped, in a typeface that is not Kati's.
  `Kati.PersianFontTest`'s moduledoc is where that was first written down, and
  it is why the Persian mirrors adopt so little of `Kati.Components`.

      iex> Kati.Locale.face_for(:fa)
      "fa"

      iex> Kati.Locale.face_for(:en)
      "sans"
  """
  @spec face_for(atom()) :: String.t()
  def face_for(:fa), do: "fa"
  def face_for(_latin), do: "sans"

  @doc """
  The face of the active locale.

  `"sans"` rather than `nil` for English, deliberately: the bridge treats a
  root that names no face as *behave exactly as before*, so passing the name
  makes the English case a decision this app states rather than a default it
  inherits.
  """
  @spec face_prop() :: String.t()
  def face_prop, do: face_for(current())

  @doc """
  The glyph that means **forward** — where the reader is going.

      iex> Kati.Locale.forward_glyph()
      "arrow_forward"

  The twin of `Kati.Screens.Pushed.back_glyph/0`, and it exists for the same
  reason that one does: `layout_direction` mirrors a LAYOUT and cannot mirror
  a picture. An arrow is a picture. Under `rtl` the primary action's glyph has
  to be `arrow_back`, which reads wrong in a diff and right on a phone — the
  three Persian onboarding boards all draw it that way and say so in their
  captions.

  `mishka-group/kati#103`'s fold is what made this shared rather than a
  sentence written twice: `Kati.Screens.OnboardingWelcomeFa.forward/2` was one
  of the two functions a mirror kept for itself.
  """
  @spec forward_glyph() :: String.t()
  def forward_glyph, do: if(direction(current()) == :rtl, do: "arrow_back", else: "arrow_forward")

  @doc """
  The day the reader's own week starts on, as a word.

      iex> Kati.Locale.week_start()
      "Monday"

  One of the four things board 137 says follow from the language choice rather
  than from a setting of their own — the others are the writing direction, the
  calendar and the numerals.
  """
  @spec week_start() :: String.t()
  def week_start, do: pick("Monday", "شنبه")

  @doc """
  Run `fun` as if the reader had chosen `locale`, then put it back.

      iex> Kati.Locale.as(:en, fn -> Kati.Locale.week_start() end)
      "Monday"

  For the handful of screens that draw BOTH languages at once and mean to:
  `Kati.Screens.WeekImage` composes an English card and a Persian card on one
  page, and screen 53 asks the language question in both scripts because
  nobody who needs it can be assumed to read the other.

  Everywhere else this is the wrong tool — a screen renders in the reader's
  language and does not choose. It moves `Gettext`'s locale and the direction
  together, because a card whose words are English and whose grid is
  right-to-left is neither page.
  """
  @spec as(atom(), (-> term())) :: term()
  def as(locale, fun) when is_function(fun, 0) do
    previous = Process.get(:kati_locale_override)
    Process.put(:kati_locale_override, locale)
    before = Gettext.get_locale(Kati.Gettext)
    Gettext.put_locale(Kati.Gettext, Atom.to_string(locale))

    try do
      fun.()
    after
      Gettext.put_locale(Kati.Gettext, before)

      if previous,
        do: Process.put(:kati_locale_override, previous),
        else: Process.delete(:kati_locale_override)
    end
  end

  @doc """
  A date in the reader's own calendar.

      iex> Kati.Locale.date(~D[2026-08-16])
      "Sun 16 Aug"

  Three styles, and each names a shape rather than a format string:

    * `:long` — the weekday, the day, the month and the year.
    * `:short` — the day and the month, which is what a row under a title wants.
    * `:dated` — the day, the month and the year, for a row that has to name
      a year the reader cannot infer.
    * `:numeric` — the three numbers, for a field.

  **`Kati.Calendar.Shamsi` under `:fa`, and it is a different CALENDAR rather
  than the same date translated.** ۲۰ شهریور ۱۴۰۵ and 11 September 2026 are the
  same day, and neither is a formatting of the other. That is the half of
  mishka-group/kati#103 gettext cannot do: a catalogue translates words, and a
  date is an arithmetic.

  Seventeen files reached for `Kati.Calendar.Shamsi` by hand and every one of
  them was a `*Fa` mirror, which is exactly why a folded screen needs this: the
  English screen is now both, and it has one place to ask what day it is.
  """
  @spec date(Date.t(), :long | :full | :short | :short_padded | :dated | :numeric) :: String.t()
  def date(%Date{} = date, style \\ :long) do
    if direction(current()) == :rtl do
      # Shamsi has no `:dated` of its own: its `:long` already carries the year,
      # which is the difference between a calendar whose year the reader knows
      # by heart and one whose year they do not. `:short_padded` is a Latin
      # typographic choice — a leading zero so a column of dates lines up — and
      # Persian numerals are already even-width, so it takes `:short`.
      Kati.Calendar.Shamsi.format(
        date,
        case style do
          :dated -> :long
          :short_padded -> :short
          other -> other
        end
      )
    else
      case style do
        :long -> Calendar.strftime(date, "%a %-d %b")
        # `Sunday 16 August`, which board 02 heads its day with. `:long`'s
        # abbreviations are the ones a 44pt gutter needs; this is the one a
        # sentence does.
        :full -> Calendar.strftime(date, "%A %-d %B")
        :short -> Calendar.strftime(date, "%-d %b")
        :short_padded -> Calendar.strftime(date, "%d %b")
        :dated -> Calendar.strftime(date, "%-d %b %Y")
        :numeric -> Calendar.strftime(date, "%Y/%m/%d")
      end
    end
  end

  @doc """
  The month a date falls in, named in the reader's own calendar.

      iex> Kati.Locale.month_name(~D[2026-08-12])
      "August"

      iex> Kati.Locale.month_name(~D[2026-08-12], :short)
      "Aug"

      iex> Kati.Locale.as(:fa, fn -> Kati.Locale.month_name(~D[2026-08-12], :short) end)
      "مرداد"

  A DATE and not a month number, which is the whole of it: 12 August 2026 is in
  Mordad, and no arithmetic on the number 8 produces that. Screen 07's header
  built its range from `Kati.Time.month_name/1` over `1` and `today.month`, so
  a Persian reader was told their year ran *Jan – Aug* — the Gregorian months,
  in Latin, of a year that begins in Farvardin.
  """
  @spec month_name(Date.t(), :long | :short) :: String.t()
  def month_name(%Date{} = date, style \\ :long) do
    if direction(current()) == :rtl do
      {_year, month, _day} = Kati.Calendar.Shamsi.from_gregorian(date)
      # `:short` is a Latin abbreviation — `August` cut to `Aug` — and Persian
      # month names are already one short word. Cutting مرداد to three letters
      # gives مرد, which is a different word.
      Kati.Calendar.Shamsi.month_name(month)
    else
      name = Kati.Time.month_name(date.month)
      if style == :short, do: String.slice(name, 0, 3), else: name
    end
  end

  @doc """
  The first day of the year `date` falls in, in the reader's own calendar.

      iex> Kati.Locale.year_start(~D[2026-08-12])
      ~D[2026-01-01]

  Nowruz in Shamsi, 1 January in Gregorian — and it is a Gregorian `Date` in
  both cases, because everything downstream measures and formats in one
  calendar and names in the other.
  """
  @spec year_start(Date.t()) :: Date.t()
  def year_start(%Date{} = date) do
    if direction(current()) == :rtl do
      {year, month, day} = Kati.Calendar.Shamsi.from_gregorian(date)

      case Kati.Calendar.Shamsi.to_gregorian(year, 1, 1) do
        {:ok, nowruz} -> nowruz
        # A year outside the Nowruz table: the date itself is the best answer
        # there is, and it is never wrong about which year it is in.
        {:error, _outside} -> Date.new!(date.year, if(month == 1 and day == 1, do: 1, else: 1), 1)
      end
    else
      Date.new!(date.year, 1, 1)
    end
  end

  @doc """
  The year number a date falls in, in the reader's own calendar and digits.

      iex> Kati.Locale.year_of(~D[2026-08-12])
      "2026"

      iex> Kati.Locale.as(:fa, fn -> Kati.Locale.year_of(~D[2026-08-12]) end)
      "۱۴۰۵"

  `year/1` is its opposite number and the two are not interchangeable: that one
  takes a Gregorian year a RECORD carries — a book's publication, a film's
  release — and never converts it, because a title published in 1961 was not
  published in 1340. This one asks what year the READER is in.
  """
  @spec year_of(Date.t()) :: String.t()
  def year_of(%Date{} = date) do
    if direction(current()) == :rtl do
      {year, _month, _day} = Kati.Calendar.Shamsi.from_gregorian(date)
      number(year)
    else
      number(date.year)
    end
  end

  @doc """
  The day of the month, in the reader's own calendar and digits.

      iex> Kati.Locale.day_of_month(~D[2026-08-16])
      "16"

      iex> Kati.Locale.as(:fa, fn -> Kati.Locale.day_of_month(~D[2026-08-16]) end)
      "۲۵"

  The number a day-strip cell draws under its letter. Screen 02 drew
  `date.day` — the Gregorian number — so board 56's strip ran 16 17 18 where
  the board draws ۲۴ ۲۵ ۲۶: the right days, counted in the wrong calendar.
  """
  @spec day_of_month(Date.t()) :: String.t()
  def day_of_month(%Date{} = date) do
    if direction(current()) == :rtl do
      {_year, _month, day} = Kati.Calendar.Shamsi.from_gregorian(date)
      number(day)
    else
      number(date.day)
    end
  end

  @doc """
  One letter for a weekday, as a chart axis writes it.

      iex> Kati.Locale.weekday_initial(~D[2026-09-12])
      "S"

      iex> Kati.Locale.as(:fa, fn -> Kati.Locale.weekday_initial(~D[2026-09-12]) end)
      "ش"

  Persian's are single letters by nature — `Kati.Calendar.Shamsi.weekday_short/1`
  — and English's are the first letter of the day's name, which is how every
  seven-column axis in this app writes them. Two days share `S` and two share
  `T`, and the axis is read positionally rather than letter by letter; that is
  what an axis is.
  """
  @spec weekday_initial(Date.t()) :: String.t()
  def weekday_initial(%Date{} = date) do
    if direction(current()) == :rtl do
      Kati.Calendar.Shamsi.weekday_short(Kati.Calendar.Shamsi.weekday_index(date))
    else
      date |> Kati.Time.day_name() |> String.first()
    end
  end

  @doc """
  A quotation, in the marks the reader's own typography uses.

      iex> Kati.Locale.quoted("The tide keeps its own ledger.")
      "“The tide keeps its own ledger.”"

  U+201C/U+201D in Latin and **U+00AB/U+00BB** — the guillemets — in Persian.
  Not decoration: a Persian reader meets `“…”` as a foreign mark, and board 69
  writes «جزر و مد دفتر خودش را نگه می‌دارد.» with the guillemets it expects.
  `Kati.Books.Note.display/1` is the one caller, and it draws on two screens.
  """
  @spec quoted(String.t()) :: String.t()
  def quoted(body) when is_binary(body) do
    {open, close} = pick({"\u201C", "\u201D"}, {"\u00AB", "\u00BB"})
    open <> body <> close
  end

  @doc """
  A bare YEAR, in the reader's own digits and **never** in their calendar.

      iex> Kati.Locale.year(2024)
      "2024"

  This is the one date in the app that is not converted, and board 69 is where
  the rule is written: a publication year is a fact PRINTED ON THE BOOK. *2024*
  is on the copyright page, it is what a search for the edition matches, and
  rendering it as ۱۴۰۳ would make the app disagree with the object in the
  reader's hands. `date/2` converts, because a date Kati recorded is a moment
  in the reader's own life and belongs in the reader's own calendar; this is a
  citation, and a citation is quoted.

  So the digits change and nothing else does: **۲۰۲۴**.
  """
  @spec year(integer()) :: String.t()
  def year(gregorian) when is_integer(gregorian), do: number(gregorian)

  @doc """
  A time of day, in the reader's own digits.

      iex> Kati.Locale.time(~T[21:40:00])
      "21:40"

  24-hour in both scripts — the design's own choice, and `Kati.Screens.Settings`
  draws it as a setting rather than a consequence of the language. What changes
  is the numerals.
  """
  @spec time(Time.t() | DateTime.t() | NaiveDateTime.t()) :: String.t()
  def time(at), do: at |> Calendar.strftime("%H:%M") |> then(&number/1)

  @doc """
  The face a mono line takes.

      iex> Kati.Locale.mono_face()
      "mono"

  `kati_mono.ttf` carries **no** Persian glyph, so a Persian sentence set in
  `mono` is handed to Android's own substitute face — it renders, in a typeface
  that is not Kati's, beside sentences that are. `Kati.Screens.Fa` states the
  rule and `Kati.PersianFontTest` keeps it: Persian mono copy is Vazirmatn at
  the mono size.

  A NUMBER in mono is a different question and keeps its face — see
  `number/1`.
  """
  @spec mono_face() :: String.t()
  def mono_face, do: pick("mono", "fa")

  @doc """
  The face a mono line takes when the line's own script gets a say.

      iex> Kati.Locale.mono_face("ListenBrainz")
      "mono"

  `mono_face/0` asks the READER's language and this asks the STRING's script,
  which is the right question wherever a mono slot holds a proper noun. Screen
  80's provider list is the case: `ListenBrainz` and `TMDB` are a machine's
  names for itself, they are pure ASCII, and DM Mono has every glyph they need
  — so they stay in DM Mono in both scripts, which is what both drawings draw.
  `فیلم و سریال · TVmaze` is not, and DM Mono would set the Persian half as
  empty boxes and the Latin half perfectly, which is the worst of the two
  outcomes because it looks deliberate.

  Deciding by script rather than by a hand-kept list means a provider added to
  `Kati.Sources` tomorrow is typeset correctly without anybody deciding again.
  `Kati.Screens.DataSourcesFa.name/1` is where this started; it went the same
  way its screen did, and `Kati.Screens.DataSources.body/2` is what calls it
  now.
  """
  @spec mono_face(String.t()) :: String.t()
  def mono_face(text) when is_binary(text) do
    if String.match?(text, ~r/\A[\x20-\x7E]*\z/), do: "mono", else: mono_face()
  end

  @doc """
  A number in the reader's own digits.

      iex> Kati.Locale.number(190)
      "190"

  `Kati.I18n.Digits.to_persian/1` under `:fa` and `Integer.to_string/1`
  otherwise. Every mirror reached for the first of those by hand — screen 301's
  `جست‌وجو در ۱۹۰ کشور` is one of seventeen — and a folded screen has one place
  to ask instead.

  **Not every number is this one.** A figure the design sets in DM Mono keeps
  Latin digits in both scripts, because `kati_mono.ttf` carries none of
  U+06F0–U+06F9; `Kati.Screens.Fa` states that rule and `Kati.PersianFontTest`
  keeps it. This is for the numerals inside a sentence.
  """
  @spec number(integer() | String.t()) :: String.t()
  def number(value) do
    text = to_string(value)

    if direction(current()) == :rtl do
      # The SEPARATOR as well as the digits. Persian writes a decimal with
      # U+066B ARABIC DECIMAL SEPARATOR and groups with U+066C — `۷۶٫۰`, not
      # `۷۶.۰` — and board 115 draws it that way. `Kati.I18n.Digits.to_persian/1`
      # converts the digits alone, so a figure came out half-converted: Persian
      # numerals around a Latin full stop.
      # The DECIMAL separator only. CLDR's `fa` groups with U+066C as well, and
      # the boards do not: `test/design/screens/59.html` writes `۱,۴۸۰` with a
      # Latin comma and `test/design/screens/115.html` writes `۷۶٫۰` with the
      # Arabic decimal mark. The drawing is the specification, so the point
      # converts and the grouping does not.
      text
      |> Kati.I18n.Digits.to_persian()
      |> String.replace(".", "٫")
    else
      text
    end
  end

  @doc """
  One of two values, by writing direction.

      iex> Kati.Locale.pick(13.5, 14)
      13.5

  The general form of `tracking/1` and `leading/1`, for the places a drawing
  and its mirror differ by a number rather than by a word — a type size, a
  gap, a glyph. Both values stay at the call site, which is the point: a
  Persian screen that differs by 0.5pt should say so where it differs, not in a
  second module.
  """
  @spec pick(term(), term()) :: term()
  def pick(latin, persian), do: if(direction(current()) == :rtl, do: persian, else: latin)

  @doc """
  The glyph that means **back** — where the reader came from.

      iex> Kati.Locale.back_glyph()
      "arrow_back"

  The plain arrow, and the exact inversion of `forward_glyph/0`.
  `Kati.Screens.Pushed.back_glyph/0` is the other one and stays separate: it is
  the `_ios` chevron the floating pill draws, and a sequence that steps back
  through itself is not a stack being popped — the boards draw the difference.
  """
  @spec back_glyph() :: String.t()
  def back_glyph, do: if(direction(current()) == :rtl, do: "arrow_forward", else: "arrow_back")

  @doc """
  The chevron on a row that opens something, pointing the reading direction.

  `chevron_right` in English, `chevron_left` in Persian — and it is a different
  question from `back_glyph/0`, which points the way the reader CAME FROM. The
  two therefore point opposite ways in one script and the same way in neither,
  which is why they cannot share a helper.

  Material Symbols are text in a font and auto-mirror nothing, so nothing
  happens here unless it is asked for. `Icons.AutoMirrored` is Compose's answer
  to the same problem and reaches only the icons the bridge draws from the
  Material set — `K-12 auto-mirrored-chevrons` in `native/LEDGER.md` — not the
  glyphs Kati draws out of its own subset font.

      iex> Kati.Locale.as(:en, fn -> Kati.Locale.forward_chevron() end)
      "chevron_right"

      iex> Kati.Locale.as(:fa, fn -> Kati.Locale.forward_chevron() end)
      "chevron_left"
  """
  @spec forward_chevron() :: String.t()
  def forward_chevron, do: pick("chevron_right", "chevron_left")

  @doc """
  Wrap a Latin run so it keeps its own direction inside a Persian paragraph.

  A full stop is a **neutral** character in the Unicode bidirectional
  algorithm: it takes the direction of the paragraph it sits in, not of the
  words around it. So an English sentence drawn inside an RTL page has its
  terminating period resolved as right-to-left and laid out at the LEFT edge —

      .This product uses the TMDB API but is not endorsed or certified by TMDB

  which is what screen 83 drew for all five licence notices the moment it
  started rendering under `:fa`. The words are correct and the sentence reads
  as broken, which is the failure this whole fold keeps meeting: legible enough
  that nobody files it.

  The fix is Unicode's own and needs nothing from the bridge:
  `U+2066 LEFT-TO-RIGHT ISOLATE` opens a run with its own direction and
  `U+2069 POP DIRECTIONAL ISOLATE` closes it, so the neutrals inside resolve
  against the run rather than against the page. Isolate rather than
  `U+202D LRO`: an override would also reorder any Persian inside the run,
  and some notices name a product in both scripts.

  A no-op in LTR, so a call site does not have to ask which script it is in.

      iex> Kati.Locale.as(:en, fn -> Kati.Locale.ltr("hello.") end)
      "hello."

      iex> Kati.Locale.as(:fa, fn -> Kati.Locale.ltr("hello.") end)
      "\u2066hello.\u2069"
  """
  @spec ltr(String.t()) :: String.t()
  def ltr(text) when is_binary(text) do
    if direction(current()) == :rtl, do: "\u2066" <> text <> "\u2069", else: text
  end

  @doc """
  Latin tracking, or none.

      iex> Kati.Locale.tracking(-0.03)
      -0.03

  The design tightens its 28pt headings by a fraction of an em. Arabic script
  has no such tradition and Vazirmatn is not drawn for it — the mirrors all
  dropped `letter_spacing` rather than mirroring it, and
  `Kati.Screens.AddByHand.labelled/4` already carries the long version of the
  argument for the eyebrow labels.
  """
  @spec tracking(number()) :: number()
  def tracking(latin), do: if(direction(current()) == :rtl, do: 0, else: latin)

  @doc """
  A paragraph's line height: the design's own, or Persian's.

      iex> Kati.Locale.leading(1.55)
      1.55

  `Kati.Theme.fa_line_height/0` is the constant and its doc is where the
  reasoning lives — Vazirmatn's metrics are not Plus Jakarta's, so a fixed-height
  row measured against the Latin screen breaks on its Persian twin. This is that
  constant applied per paragraph, with the Latin value as the argument so both
  numbers stay visible at the call site.
  """
  @spec leading(number()) :: number()
  def leading(latin), do: if(direction(current()) == :rtl, do: 1.95, else: latin)

  @doc "The CLDR locale name for the active locale."
  @spec cldr_name() :: String.t()
  def cldr_name, do: Atom.to_string(current())

  @doc """
  Resolve the stored locale into THIS process, for `Kati.Gettext`.

  The twin of `Kati.Theme.activate/0`, and it sits beside it at every one of
  its call sites for the same reason: `Mob.Theme.set/1` and
  `Gettext.put_locale/2` both snapshot into the calling process, so storing a
  new choice with `put/1` changes nothing on screen by itself. A screen needs
  both, plus a re-render.

  **Process-scoped, deliberately, rather than `Application.put_env/3` on
  `:gettext, :default_locale`.** That would be one global write instead of 52
  paired calls and it is the wrong trade twice over: `Kati.Runtime` is the only
  module in this app allowed to write application environment (its moduledoc
  says why, and a locale is not a runtime config key), and a global default
  would mean a test that renders one screen in `:fa` had changed the locale for
  every other test in the run. `Kati.LocaleActivateTest` is what keeps the
  pairing honest.

  Gettext falls back to the msgid when a locale has no entry, and the msgid is
  the English copy — so a process that never called this draws English rather
  than a missing-translation marker. That is the right failure and also the
  quiet one, which is exactly why the pairing is asserted rather than trusted.
  """
  @spec activate() :: :ok
  def activate do
    Gettext.put_locale(Kati.Gettext, cldr_name())
    :ok
  end
end
