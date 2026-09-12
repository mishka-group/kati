defmodule Kati.Search do
  use Gettext, backend: Kati.Gettext

  @moduledoc """
  What a search looks at, in what order, and how a query is folded first.

  Screen 88 is the specification and calls itself one: *the annotation
  deliverable, drawn as its own board rather than margin notes — it is a
  contract the build reads, not a caption.* This module is the build's half of
  that contract, and screen 88 renders it rather than restating it, so the two
  cannot drift.

  ## Group order is fixed, and that is the point

  Screen · Books · Music · Calendar · Meals · Money · Notes, always, whatever
  matched. The board's own reasoning: *a user learns where to look;
  relevance-sorted groups move the target every keystroke.* A list that
  reorders itself as you type is a list you have to re-read.

  Ranking happens **within** a group, in four tiers — exact title, prefix,
  substring, body text — with ties broken by recency.

  ## One field is excluded by name

  Calendar searches event titles, locations and notes, and **never invitee
  names**. Screen 88 says why in one line: searching your calendar should not
  turn into searching your contacts.

  ## The minimum is two characters, or one for a script where one is a word

  Persian, Arabic, Chinese and Japanese. A one-character Latin query matches
  most of a library and costs seven counted queries — one per scope — to say so.

  ## Debounce is 180 ms and it is load-bearing here

  Screen 87 draws it rather than asserting it: six keystrokes collapse into one
  fire. Every fire costs seven counted queries, so an undebounced field would
  run forty-two of them for the word *hollow*.
  """

  alias Kati.I18n.Digits

  # `{scope, label, [fields]}` in the order every result list uses. The fields
  # are the contract screen 88 draws; the module is what makes them true.
  # The contract the design states, and it is WIDER than the executor.
  #
  # Seven scopes and twenty-five fields; `Kati.Search.Query.run/1` builds four
  # groups. Music, Meals and Money are searched by nothing. On Screen, `cast`
  # is now the only field nothing reads — `episode titles` joined the list on
  # the round `Kati.Search.Query.episodes_for/2` landed, LIVE rather than
  # promised (#144), `location` stopped being a gap when #74 closed, and the
  # other four came in with #114. That is still a real gap and boards 86, 88,
  # 90 and 91 all draw the wider list — so the list stays as the design's, and
  # `built?/1` is what says which half of it is live. A specification screen that overstates is worse than none, because it
  # is the page a reader opens to find out why a search missed
  # (MOVIES-AND-TV.md #74); a specification screen that says *not yet* against
  # four rows is the same page telling the truth.
  #
  # `Kati.SearchContractTest` pins `built?/1` to `narrowable_scopes/0`, so a
  # scope cannot be marked built without a group behind it.
  # A function, not an attribute: `gettext/1` inside one is evaluated at
  # COMPILE time, so seven translated labels and their field lists would freeze
  # in whichever locale the compiler happened to be in. See `scopes/0`.

  # Fields this list names that a search does not look in, because nothing on
  # the device holds them — MOVIES-AND-TV.md #74 at the field level, and #114.
  #
  # The field is not removed, for `built?/1`'s reason one level down: the
  # contract is the design's and stating it whole is what screen 88 is FOR;
  # what was missing is which parts of it are live. So these draw in the same
  # struck, tertiary treatment `never invitee names` already had — one visual
  # for *named and not doing this*, whatever the reason.
  #
  # `cast` — TMDB's credits are not fetched and `Kati.Media.CachedTitle` has no
  # column for a person. `series` — `Kati.Books.Book` has no series name. Both
  # become searchable the day the column does, and nothing else has to change.
  @unkept ["cast", "series"]

  @doc """
  Whether a field this board names is one a search actually reads.

      iex> Kati.Search.kept?("your review")
      true

      iex> Kati.Search.kept?("cast")
      false
  """
  @spec kept?(String.t()) :: boolean()
  def kept?(field), do: field not in @unkept

  # The scopes `Kati.Search.Query.run/1` actually builds a group for. Written
  # as labels rather than derived from `@narrowable`, because that list also
  # holds `All` — which is every group rather than a scope of its own.
  @built [:screen, :books, :calendar, :notes]

  # The four tiers, with the example screen 88 prints for each.
  @tiers [
    {1, "Exact title match", "hollow → Hollow"},
    {2, "Prefix match", "hollow → Hollow Season"},
    {3, "Substring", "hollow → The Long Hollow"},
    {4, "Body text", "hollow → a note mentioning it"}
  ]

  # Scripts where a single character is a word, and the minimum is therefore 1.
  # Ranges rather than a language list, because what matters is what was typed
  # rather than what the app is set to.
  @single_char_scripts [
    {0x0600, 0x06FF},
    {0x0750, 0x077F},
    {0x08A0, 0x08FF},
    {0x3040, 0x30FF},
    {0x3400, 0x4DBF},
    {0x4E00, 0x9FFF},
    {0xF900, 0xFAFF}
  ]

  @doc """
  Every scope, in the fixed order every result list uses.

  `{key, label, fields}`. The KEY is what a chip's tap is named after and what
  `built?/1` and `narrowable/1` answer about; the label and the field list are
  copy. They were one string, which is the defect this whole ticket is about.
  """
  @spec scopes() :: [{atom(), String.t(), [String.t()]}]
  def scopes do
    [
      {:screen, pgettext("search scope", "Screen"),
       [
         gettext("title"),
         gettext("original title"),
         gettext("alt titles"),
         gettext("episode titles"),
         gettext("cast"),
         gettext("your tags"),
         gettext("your review")
       ]},
      {:books, pgettext("search scope", "Books"),
       [
         gettext("title"),
         gettext("author"),
         gettext("series"),
         "ISBN",
         gettext("your notes"),
         gettext("your quotes")
       ]},
      {:music, pgettext("search scope", "Music"),
       [gettext("album"), gettext("artist"), gettext("track"), gettext("your notes")]},
      {:calendar, pgettext("search scope", "Calendar"),
       [
         gettext("event title"),
         gettext("location"),
         gettext("notes"),
         gettext("never invitee names")
       ]},
      {:meals, pgettext("search scope", "Meals"), [gettext("meal name"), gettext("ingredients")]},
      {:money, pgettext("search scope", "Money"), [gettext("service name")]},
      {:notes, pgettext("search scope", "Notes"), [gettext("every cream card in the app")]}
    ]
  end

  @doc """
  Whether a search actually looks in this scope.

  `@scopes` is the design's contract and `Kati.Search.Query.run/1` builds four
  of its seven groups. Screens 86 and 88 both draw all seven; this is what lets
  them say which ones are live rather than offering a choice that
  `narrowable/1` silently turns into `All` on the way to screen 19
  (MOVIES-AND-TV.md #73 and #74).

      iex> Kati.Search.built?(:screen)
      true

      iex> Kati.Search.built?(:music)
      false

      iex> Kati.Search.built?(:all)
      true

  The KEY and not the label. It was the label, and a chip whose word is «همه»
  answered `false` to every clause — so a Persian reader's every scope read as
  *not built yet*. mishka-group/kati#103; the same defect
  `Kati.Screens.Library.chip_counts/1` carries the note for.
  """
  @spec built?(atom()) :: boolean()
  def built?(:all), do: true
  def built?(key), do: key in @built

  @doc "Just the keys, for the chip row — with `:all` first."
  @spec chip_keys() :: [atom()]
  def chip_keys, do: [:all | Enum.map(Kati.Search.scopes(), &elem(&1, 0))]

  @doc """
  One scope's own word, as every chip row draws it.

      iex> Kati.Search.scope_label(:all)
      "All"
  """
  @spec scope_label(atom()) :: String.t()
  def scope_label(:all), do: pgettext("search scope", "All")

  def scope_label(key) do
    case Enum.find(Kati.Search.scopes(), &(elem(&1, 0) == key)) do
      {_key, label, _fields} -> label
      nil -> Atom.to_string(key)
    end
  end

  @doc "The fields one scope searches, as screen 88 lists them."
  @spec fields(atom()) :: [String.t()]
  def fields(scope) do
    case Enum.find(Kati.Search.scopes(), &(elem(&1, 0) == scope)) do
      {_scope, _label, fields} -> fields
      nil -> []
    end
  end

  @doc "The four ranking tiers, with their examples."
  @spec tiers() :: [{pos_integer(), String.t(), String.t()}]
  def tiers, do: @tiers

  @doc "How long the field waits before it fires, in milliseconds."
  @spec debounce_ms() :: pos_integer()
  def debounce_ms, do: 180

  @doc "How many rows a group shows before its `See all` row."
  @spec rows_per_group() :: pos_integer()
  def rows_per_group, do: 3

  @doc """
  The field's placeholder.

  Copy rather than data, which is why it lives with the specification and not
  in a fixture: it says what the field will look in, and the answer is
  everything — the scope chips narrow, the field does not.
  """
  @spec placeholder() :: String.t()
  def placeholder, do: "Search anything you keep"

  # Board 86's two, and its own caption says they are *drawn from what you
  # actually have* — which they were not: two fixed strings that match nothing
  # on any device but the one the board was captured on. MOVIES-AND-TV.md #72.
  @drawn_suggestions ["what leaves this week", "notes about the estuary"]

  @doc """
  The two suggestions, and there are only ever two.

  Screen 86's caption: *Try suggestions ship, but only two, drawn from what you
  actually have.* Two, because a suggestion list long enough to browse is a
  second search — and drawn from your own library, because a suggestion for
  something you do not keep is an advert.

  Fixed strings for now, and the boards' own. Deriving them wants a notion of
  what a person has been near lately that nothing in Kati stores; the pair
  here are shaped like the two the design chose — one about time, one about a
  place in the library — so the screen that draws them will not have to change
  when they are derived.
  """
  @spec suggestions() :: [String.t()]
  def suggestions, do: @drawn_suggestions

  @doc """
  The sentence explaining why the chips carry no counts until something is typed.

  The three numbers in it are `debounce_ms/0`, `minimum/1` and this module's
  own rule about zero, so it is written beside them rather than in a fixture
  where the two could drift apart silently.
  """
  @spec counts_note() :: String.t()
  def counts_note do
    "Counts stay off the chips until a query exists — eight zeroes on open would read as an " <>
      "empty app. Searching starts at 2 characters, or 1 for Persian, Arabic and CJK, where one " <>
      "character is a word. Keystrokes debounce at 180 ms, so one pause costs seven counted " <>
      "queries, not seven per letter."
  end

  @doc """
  What screen 19 says while it is waiting, which is about screen 19.

  It drew `counts_note/0` — board 88's specification — and every clause of it
  was false here. That note describes **eight** scopes and this screen narrows
  to five; it promises a 180 ms debounce and this screen runs on every
  keystroke, deliberately and for a reason its own `handle_info/2` argues at
  length: the query is a scan of a personal SQLite library, so a debounce would
  buy latency rather than spend it. A reader was told the app was being careful
  with requests it does not make. MOVIES-AND-TV.md #63.

  Board 88 keeps `counts_note/0`, because board 88 is where seven scopes are
  actually drawn.

      iex> Kati.Search.local_note() =~ "debounce"
      false
  """
  @spec local_note() :: String.t()
  def local_note do
    "Counts stay off the chips until a query exists — #{length(narrowable_scopes())} zeroes on open " <>
      "would read as an empty app. Searching starts at 2 characters, or 1 for Persian, Arabic " <>
      "and CJK, where one character is a word. Every keystroke runs: the search is your own " <>
      "library on this device, so waiting would cost more than it saved."
  end

  @doc """
  Put a query where the next screen will look for it.

  Screen 86 is the idle board and screen 19 is the results board, and the two
  are separate pages — so what was typed on one has to reach the other. It
  travelled the road `Kati.Locale` takes, a key in `Mob.State`, on the belief
  that `Mob.Socket.push_screen/2` took a module and nothing else. It takes a
  params map, and 86 now names its query in the push.

  The key is kept, and it is not a leftover. A push that names no query at all
  still has to open on something — the gallery's is one, and any door built
  before 86 has run is another — and this is what
  `Kati.Screens.Search.opening_query/1` reads when nothing was named.

  It lives with the specification rather than on either screen, and that is not
  tidiness. `Kati.ScreenEmptyDatabaseTest` derives which screens reach the
  database from the compiled call graph, transitively — so a handover defined
  on `Kati.Screens.Search`, which runs the query, made every screen that hands
  a query over into a database reader, and then every screen that called one of
  those. Two reference sheets joined the migration list that way in one edit.
  This module runs nothing.
  """
  @spec hand_over(String.t()) :: :ok
  def hand_over(query) when is_binary(query) do
    Mob.State.put(:kati_search_query, query)
    :ok
  rescue
    # `Mob.State` is DETS and raises when its table is not open — a host test
    # that has not started it, and the gallery on a cold boot.
    _error -> :ok
  end

  @doc "The query the last screen handed over, or `\"\"`. See `hand_over/1`."
  @spec handed_over() :: String.t()
  def handed_over do
    case Mob.State.get(:kati_search_query) do
      query when is_binary(query) -> query
      _nothing -> ""
    end
  rescue
    _error -> ""
  end

  # The four scopes screen 19 can actually narrow to. They are the labels
  # `Kati.Search.Query.chip_counts/1` builds, written out here rather than
  # derived, for the reason that module's own moduledoc gives at length: this
  # module runs nothing, and a call into the query executor from here would make
  # every screen that merely mentions the specification — boards 86, 88, 89 and
  # 91 among them — a database reader in `Kati.ScreenEmptyDatabaseTest`'s
  # derived list. `narrowable_scopes/0` is what lets the two lists be checked
  # against each other instead.
  # `Books` joined on 6 September. A book used to be concatenated into the
  # Screen group, drawn under that heading, counted by that chip and given a
  # chevron that opened nothing — MOVIES-AND-TV.md #61.
  @narrowable [:all, :screen, :books, :calendar, :notes]

  @doc """
  The scope screen 19 can narrow to, given one of the eight screen 86 offers.

  86 draws a chip per `chip_labels/0` — All and the seven `@scopes` — and 19
  draws four, because `Kati.Search.Query.run/1` builds three groups. So Books,
  Music, Meals and Money are choosable on 86 and cannot exist on 19, and a scope
  carried across unchecked is worse than one dropped:
  `Kati.Screens.Search.visible_groups/2` filters on `filter == label`, so
  `"Books"` leaves no group standing at all and the page draws its *matched
  nothing* card — a correct-looking report of nothing found, over a query that
  found things.

  Opening on All is the honest degradation: the reader sees everything that
  matched rather than a lie about nothing matching. The four scopes 19 does have
  narrow as chosen.
  """
  @spec narrowable(atom()) :: atom()
  def narrowable(scope) when scope in @narrowable, do: scope
  def narrowable(_unnarrowable), do: :all

  @doc """
  The four scopes `narrowable/1` passes through.

  Public so the claim can be checked rather than trusted — these are meant to be
  exactly the labels `Kati.Search.Query.chip_counts/1` returns, and this module
  is deliberately unable to ask it. See `@narrowable`.
  """
  @spec narrowable_scopes() :: [atom()]
  def narrowable_scopes, do: @narrowable

  @doc "How many recent queries are kept."
  @spec recent_kept() :: pos_integer()
  def recent_kept, do: 8

  @doc """
  The shortest query this scope will search on: 2, or 1 for a script where one
  character is a word.

  Measured on the query rather than on the app's locale, because somebody
  reading Kati in English can still type a Persian title into it.
  """
  @spec minimum(String.t()) :: 1 | 2
  def minimum(query) when is_binary(query) do
    if String.trim(query) |> String.to_charlist() |> Enum.any?(&single_char_script?/1),
      do: 1,
      else: 2
  end

  defp single_char_script?(cp) do
    Enum.any?(@single_char_scripts, fn {from, to} -> cp >= from and cp <= to end)
  end

  @doc "Whether a query is long enough to run. See `minimum/1`."
  @spec long_enough?(String.t()) :: boolean()
  def long_enough?(query) when is_binary(query) do
    trimmed = String.trim(query)
    String.length(trimmed) >= minimum(trimmed)
  end

  @doc """
  A query and an index entry reduced to the one form they are compared in.

  Screen 88 draws the whole table, and every row of it is here:

    * **ي U+064A → ی U+06CC** and **ك U+0643 → ک U+06A9.** The Arabic and
      Persian letters look alike, sit on different keyboards, and are different
      codepoints. Typing `ي` finds `ی`, which is the board's own example.
    * **ZWNJ U+200C is folded**, so `می‌رود` and `میرود` are one word.
    * **Harakat U+064B–U+0652 are stripped.** They are optional in writing and
      almost never typed, so an indexed word that carries them would be
      unreachable.
    * **Arabic-Indic and Persian digits fold to ASCII**, through
      `Kati.I18n.Digits.fold/1`, so `٤` and `۴` both find `4`.

  Then case-folded and whitespace-collapsed, which is what makes the whole
  thing a single comparison rather than a chain of them.
  """
  @spec normalise(String.t()) :: String.t()
  def normalise(text) when is_binary(text) do
    text
    |> Digits.fold()
    |> String.replace("ي", "ی")
    |> String.replace("ك", "ک")
    |> String.replace("‌", "")
    |> String.replace(~r/[\x{064B}-\x{0652}]/u, "")
    |> String.downcase()
    |> String.replace(~r/\s+/u, " ")
    |> String.trim()
  end

  @doc """
  Where a query actually falls in a piece of raw text: `{at, len}` in BYTES of
  `text`, or `:nomatch`.

  This exists because the obvious version is wrong, and was shipped:

      case :binary.match(normalise(body), normalise(query)) do
        {at, len} -> binary_part(body, at, len)

  Those offsets are into the NORMALISED string and that slice is out of the
  RAW one. `normalise/1` changes lengths — it strips ZWNJ and harakat, folds
  two-byte Persian digits to one-byte ASCII, collapses runs of whitespace and
  trims the ends — so on any note with a doubled space, a leading newline, a
  ZWNJ or a vowel mark, the card highlighted the wrong characters. And when
  normalisation SHORTENED the text enough, `at + len` ran off the end of the
  raw body, `binary_part/3` raised, and a `rescue` in `Kati.Search.Query`
  turned that into "there is no note here": the Notes group vanished from the
  results, silently, for the query that matched it best. MOVIES-AND-TV.md #32.

  So the search happens in raw coordinates. For each grapheme boundary in
  `text`, the window starting there is grown until its NORMALISED form is as
  long as the normalised query, and the window whose normalised form equals it
  wins. `normalise/1` is the oracle rather than something reimplemented here,
  which is the point: there is no second copy of the folding rules to drift
  from the first, and a rule added to `normalise/1` is honoured here the day
  it lands.

  Windows starting on whitespace are skipped, because normalisation trims and
  such a window would answer for the same match one space early — a highlight
  with a space hanging off the front of it.

      iex> Kati.Search.locate("The  Long  Hollow", "long hollow")
      {5, 12}

      iex> {at, len} = Kati.Search.locate("The  Long  Hollow", "long hollow")
      iex> binary_part("The  Long  Hollow", at, len)
      "Long  Hollow"

      iex> Kati.Search.locate("hello", "nothing")
      :nomatch

  The interesting case, and the one the shipped version got wrong: a body
  whose bytes and whose normalised bytes are different lengths.

      iex> body = "  می‌رود به خانه"
      iex> {at, len} = Kati.Search.locate(body, "خانه")
      iex> binary_part(body, at, len)
      "خانه"
  """
  @spec locate(String.t(), String.t()) :: {non_neg_integer(), non_neg_integer()} | :nomatch
  def locate(text, query) when is_binary(text) and is_binary(query) do
    needle = normalise(query)

    if needle == "" do
      :nomatch
    else
      starts(text)
      |> Enum.find_value(:nomatch, &window_at(text, &1, needle))
    end
  end

  # Every grapheme boundary that is not whitespace, as a byte offset.
  defp starts(text) do
    text
    |> String.graphemes()
    |> Enum.reduce({[], 0}, fn grapheme, {offsets, at} ->
      offsets = if String.trim(grapheme) == "", do: offsets, else: [at | offsets]
      {offsets, at + byte_size(grapheme)}
    end)
    |> elem(0)
    |> Enum.reverse()
  end

  # The window starting at `at` whose normalised form is the needle, or nil.
  #
  # `normalise/1` never shortens a window when the window grows — it strips and
  # collapses, and both of those are per-character — so the normalised length
  # climbs monotonically and the search stops the moment it passes the needle's.
  defp window_at(text, at, needle) do
    size = byte_size(text)
    target = byte_size(needle)

    Enum.reduce_while(ends(text, at), nil, fn stop, _acc ->
      len = stop - at
      window = binary_part(text, at, len)
      normalised = normalise(window)

      cond do
        normalised == needle -> {:halt, {at, len}}
        byte_size(normalised) > target -> {:halt, nil}
        stop >= size -> {:halt, nil}
        true -> {:cont, nil}
      end
    end)
  end

  # The byte offsets a window starting at `at` may end on: every grapheme
  # boundary after it.
  defp ends(text, at) do
    text
    |> binary_part(at, byte_size(text) - at)
    |> String.graphemes()
    |> Enum.scan(at, fn grapheme, offset -> offset + byte_size(grapheme) end)
  end

  @doc """
  Which tier a candidate falls in for a query, or `nil` for no match at all.

  `title` is the candidate's own name and `body` is everything else about it —
  the fields screen 88 lists under its scope. The split is what makes tier 4
  distinguishable from tiers 1–3: a query found in a note is a weaker match
  than the same query found in a title, however exactly it matched.
  """
  @spec tier(String.t(), String.t(), String.t()) :: 1 | 2 | 3 | 4 | nil
  def tier(query, title, body \\ "") do
    q = normalise(query)
    t = normalise(title)
    b = normalise(body)

    cond do
      q == "" -> nil
      t == q -> 1
      String.starts_with?(t, q) -> 2
      String.contains?(t, q) -> 3
      String.contains?(b, q) -> 4
      true -> nil
    end
  end

  @doc """
  Order a scope's matches: by tier, then by recency, newest first.

  Each candidate is `{tier, recency, value}` where `recency` is any term
  `Date`/`DateTime` comparison understands, or `nil`. Ties break by recency
  because that is the board's own rule, and a `nil` recency sorts last rather
  than first — an undated thing is not the newest thing.
  """
  @spec rank([{1..4, term(), term()}]) :: [term()]
  def rank(candidates) do
    candidates
    |> Enum.sort_by(fn {tier, recency, _value} -> {tier, recency_key(recency)} end)
    |> Enum.map(fn {_tier, _recency, value} -> value end)
  end

  # Sorts ascending, so a newer date must produce a smaller key. Negating a
  # day count does that and keeps `nil` at the end.
  defp recency_key(nil), do: {1, 0}
  defp recency_key(%Date{} = date), do: {0, -Date.to_gregorian_days(date)}

  defp recency_key(%DateTime{} = at),
    do: {0, -(at |> DateTime.to_unix())}

  defp recency_key(n) when is_integer(n), do: {0, -n}
  defp recency_key(_other), do: {1, 0}

  @doc """
  The Persian normalisation table, as screen 88 prints it.

  Read from here rather than typed into the screen, so the board and the
  behaviour are one thing. Each row is `{from, from codepoint, to, to
  codepoint}`; `to` is `nil` where the rule removes rather than replaces.
  """
  @spec normalisation_table() :: [{String.t(), String.t(), String.t() | nil, String.t() | nil}]
  def normalisation_table do
    [
      {"ي", "U+064A", "ی", "U+06CC"},
      {"ك", "U+0643", "ک", "U+06A9"},
      {"ZWNJ", "U+200C", "folded", nil},
      {"harakat", "U+064B–0652", "stripped", nil},
      {"٤ ۴", "Arabic-Indic", "4", "folded"}
    ]
  end
end
