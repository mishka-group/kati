defmodule Kati.Screens.Discover.Sample do
  use Gettext, backend: Kati.Gettext

  @moduledoc """
  Stand-in recommendation data for screen 11, until the Screen domain exists.

  The drawing's own copy throughout — the match percentages, the roles, the
  service name and the number of days it is leaving in. `new?` is the field
  that decides the trailing mark on a person's row: an orange dot when there is
  something to look at, a muted `check` when there is not. Two people with news
  and one without, because the design draws both states and a list of three
  identical rows would exercise neither.

  ## Which of these strings this module owns

  Every value here is drawn by `Kati.Screens.Discover` exactly as it arrives, so
  it is this module that has to be in the reader's language — with one exception
  the screen states at length. A chip's `label` is a **KEY**, not a word:
  `Kati.Screens.Discover.shows?/2` matches it clause by clause and
  `Kati.Screens.Discover.chip/2` builds `:filter_…` out of it, while
  `Kati.Screens.Discover.chip_label/1` is what turns it into the word on the
  chip. Translating the four labels here would leave the rail drawn in Persian
  and every chip on it emptying the page — the defect `chip_label/1`'s own doc
  records as found four times. So the chips stay English and nothing else does.

  The board's numbers are the reader's numbers and convert with them
  (`Kati.Locale.number/1`). The one service name on the page does not: `Lumen+`
  is what that service calls itself, `Kati.Services` holds the real ones and
  translates none of them, and board 127 draws `Lumen+` in Latin on a Persian
  page for exactly this reason.
  """

  @doc """
  How many rows the leaving section holds, as the chip's badge prints it.

      iex> Kati.Screens.Discover.Sample.leaving_count()
      "2"

  Latin digits, deliberately. The badge is drawn by
  `Kati.Screens.Discover.chip_count/2`, which runs this value through
  `Kati.Locale.number/1` and then asks `Kati.Locale.mono_face/1` about the
  RESULT — so `2` stays in DM Mono on an English page and `۲` moves to
  Vazirmatn on a Persian one. Converting here as well would hand that function
  a string it has already converted.
  """
  @spec leaving_count() :: String.t()
  def leaving_count, do: Integer.to_string(length(Kati.Screens.Discover.Sample.leaving()))

  @doc "Everything screen 11 draws."
  @spec feed() :: map()
  def feed do
    %{
      subtitle: tuned_line(),
      chips: [
        # KEYS, not words. `Kati.Screens.Discover.chip_label/1` is the
        # translation, and the moduledoc above says why it cannot be here.
        %{label: "For you", count: nil, selected: true},
        %{label: "People", count: nil, selected: false},
        # The count follows the list. Board 11 draws `5` over two leaving rows —
        # and a badge that disagrees with
        # the section under it is the plausible-looking figure screen 96's rule
        # is against. `leaving_count/0` reads `leaving/0`, so the two cannot
        # part company again.
        %{label: "Leaving", count: Kati.Screens.Discover.Sample.leaving_count(), selected: false},
        %{label: "Awards", count: nil, selected: false}
      ],
      # The title interpolates rather than riding inside the msgid, so the one
      # sentence on this page a real feed can also produce keeps a single
      # catalogue entry whichever title fills it. `Kati.Library.Sample` already
      # names this show, and `gettext/1` on the same literal here reaches the
      # same Persian — a fixture that spelled it twice would be two shows to a
      # reader who only ever sees the translation.
      because: gettext("Because you watched %{title}", title: gettext("The Long Hollow")),
      picks: picks(),
      people: people(),
      leaving_label: leaving_label(),
      leaving: Kati.Screens.Discover.Sample.leaving()
    }
  end

  @doc "The rows the leaving section holds, which is what its badge counts."
  @spec leaving() :: [map()]
  def leaving do
    [
      %{
        title: gettext("Nightbirds"),
        seed: "nightbirds24",
        line: pgettext("leaving row", "on your wishlist"),
        action: schedule_label()
      },
      %{
        title: gettext("A Quieter Place to Land"),
        seed: "quieterplace8",
        # `pgettext/2` rather than `gettext/1`: *never started* is two words,
        # and the catalogue already holds *Not started* twice — from the shelf
        # chip and from a book's status. `mix gettext.merge` fuzzy-matches a
        # msgid that short against whatever it resembles, and these are
        # different statements: one is a filter the reader chose, this is a
        # fact about a title that is about to disappear.
        line: pgettext("leaving row", "never started"),
        action: schedule_label()
      }
    ]
  end

  @doc "A poster or a face, whichever the seed was drawn as."
  @spec image(String.t()) :: String.t() | nil
  def image(seed), do: Kati.Design.Images.poster(seed)

  # The size of the corpus a recommender was tuned to. `ngettext/4` over the
  # WHOLE sentence rather than a `Tuned to %{titles}` wrapper around the
  # catalogue's own `%{n} titles`: the count sits inside the sentence, and the
  # entries the catalogue already shapes this way — `%{n} titles airing`,
  # `%{n} titles on this service` — let the translator put the noun where
  # Persian wants it rather than where an interpolation left it. Persian does
  # not inflect a noun after a numeral, so both forms read the same; the plural
  # exists for English.
  defp tuned_line do
    ngettext("Tuned to %{n} title", "Tuned to %{n} titles", 128, n: Kati.Locale.number(128))
  end

  # `harbour86` is `Kati.Library.Sample`'s `Harbour` — the same seed, so the
  # same photograph — and that fixture's Persian already carries the *quiet*
  # this title says out loud. One picture under two names is the drift this
  # fold is for, so the msgid here takes that wording rather than a second of
  # its own.
  defp picks do
    [
      %{title: gettext("Vellum"), seed: "vellum97", match: match_line(94)},
      %{title: gettext("Quietus"), seed: "quietus39", match: match_line(89)},
      %{title: gettext("Quiet Harbour"), seed: "harbour86", match: match_line(81)}
    ]
  end

  # `94% match`, `89% match`, `81% match` — one msgid and three bindings. The
  # msgid is still a LITERAL at the call site, which is the rule `gettext/1`
  # enforces; only `n` varies. Three separate literals would have been three
  # chances to leave one of them Latin, and the percent sign is the translator's
  # business as much as the word is: Persian writes it `٪` (U+066A), which is
  # what every `%{n}%` already in the catalogue does.
  defp match_line(percent), do: gettext("%{n}% match", n: Kati.Locale.number(percent))

  # The three names are translated, the service name is not, and the difference
  # is who owns the spelling. `Lumen+` is a product's own name for itself and no
  # msgid reaches the real ones off `Kati.Services`. These three are the
  # drawing's inventions, and `Kati.Books.Sample` already puts *Ines Karvel* in
  # the catalogue — the same person, on a book's cover, two screens away. A
  # fixture that transliterated her there and not here would be two people.
  defp people do
    [
      %{
        name: gettext("Ines Karvel"),
        line: person_line(role_director(), new_projects(2)),
        seed: "face32",
        new?: true
      },
      %{
        name: gettext("Tomas Rhee"),
        line: person_line(role_writer(), in_production(1)),
        seed: "face14",
        new?: true
      },
      %{
        name: gettext("Ada Vance"),
        line: person_line(role_actor(), nothing_new()),
        seed: "face45",
        new?: false
      }
    ]
  end

  # `Director · 2 new projects` is a LIST of two labels, not a sentence, so it
  # is joined here rather than entering the catalogue as a `%{role} · %{news}`
  # template. The middot is a separator both scripts write the same way, the
  # reading order is role-then-news in both, and the catalogue already carries
  # a shelf of near-identical `%{a} · %{b}` entries that a fifth would only be
  # confused with. `Kati.Settings.DetectSample.playing_meta/0` composes its own
  # middot line for the same reason.
  defp person_line(role, news), do: Enum.join([role, news], " · ")

  # `pgettext/2` for all three roles. Each is a single word, and a one-word
  # msgid is what `mix gettext.merge` fuzzy-matches against any sentence that
  # resembles it. The catalogue holds none of the three yet, and the context is
  # what keeps a books screen's *Author* or some later credits list from being
  # merged into them: these are credits on a person's row on board 11 and
  # nothing else in the app means them.
  defp role_director, do: pgettext("a credit on board 11", "Director")
  defp role_writer, do: pgettext("a credit on board 11", "Writer")
  defp role_actor, do: pgettext("a credit on board 11", "Actor")

  # A real plural, so `ngettext/4`.
  defp new_projects(n) do
    ngettext("%{n} new project", "%{n} new projects", n, n: Kati.Locale.number(n))
  end

  # NOT `ngettext/4`: English elides the noun here, so *1 in production* and
  # *2 in production* are the same three words and a second form would be the
  # same string twice. `gettext/2` with the count bound, and the `%{n}` is what
  # keeps a three-word msgid out of fuzzy-match range.
  defp in_production(n), do: gettext("%{n} in production", n: Kati.Locale.number(n))

  # Two words, so `pgettext/2` — see `leaving/0`'s *never started* for the
  # merge this avoids. The context is the row rather than the board's number
  # because this is the third of three states one line can be in.
  defp nothing_new, do: pgettext("a person you follow on board 11", "nothing new")

  # `Lumen+` stays Latin and rides in as a binding, so no msgid reaches it.
  #
  # `Kati.Locale.ltr/1` because here it sits inside a Persian run. The plus is a
  # **neutral** in the Unicode bidirectional algorithm, and a neutral that is
  # not between two Latin characters takes the PARAGRAPH's direction rather
  # than the run's — under `:fa` it jumps to the far side and the eyebrow reads
  # `+Lumen`. `Kati.Settings.DetectSample.playing_meta/0` writes the same pair.
  #
  # The days are inside the msgid rather than composed, for `tuned_line/0`'s
  # reason: Persian puts the window before the verb, and an English word order
  # frozen around an interpolation cannot get there.
  defp leaving_label do
    ngettext(
      "Leaving %{service} in %{n} day",
      "Leaving %{service} in %{n} days",
      7,
      service: Kati.Locale.ltr("Lumen+"),
      n: Kati.Locale.number(7)
    )
  end

  # The verb, not the noun. `Kati.Screens.Discover.leaving_action/2` already
  # draws this button's other state as `pgettext("leaving row", "Scheduled")`,
  # so sharing the context puts the two halves of one control in front of a
  # translator together. It is also required rather than tidy: a bare
  # `Schedule` would collide with screen 44's calendar noun, which is already
  # in the catalogue as `برنامه` — and what this button asks for is
  # `برنامه‌ریزی`.
  defp schedule_label, do: pgettext("leaving row", "Schedule")
end
