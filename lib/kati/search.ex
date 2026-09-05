defmodule Kati.Search do
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
  @scopes [
    {:screen, "Screen",
     ["title", "original title", "alt titles", "cast", "your tags", "your review"]},
    {:books, "Books", ["title", "author", "series", "ISBN", "your notes", "your quotes"]},
    {:music, "Music", ["album", "artist", "track", "your notes"]},
    {:calendar, "Calendar", ["event title", "location", "notes", "never invitee names"]},
    {:meals, "Meals", ["meal name", "ingredients"]},
    {:money, "Money", ["service name"]},
    {:notes, "Notes", ["every cream card in the app"]}
  ]

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

  @doc "Every scope, in the fixed order every result list uses."
  @spec scopes() :: [{atom(), String.t(), [String.t()]}]
  def scopes, do: @scopes

  @doc "Just the labels, for the chip row — with `All` first."
  @spec chip_labels() :: [String.t()]
  def chip_labels, do: ["All" | Enum.map(@scopes, &elem(&1, 1))]

  @doc "The fields one scope searches, as screen 88 lists them."
  @spec fields(atom()) :: [String.t()]
  def fields(scope) do
    case Enum.find(@scopes, &(elem(&1, 0) == scope)) do
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
  def suggestions, do: ["what leaves this week", "notes about the estuary"]

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
  @narrowable ["All", "Screen", "Calendar", "Notes"]

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
  @spec narrowable(String.t()) :: String.t()
  def narrowable(scope) when scope in @narrowable, do: scope
  def narrowable(_unnarrowable), do: "All"

  @doc """
  The four scopes `narrowable/1` passes through.

  Public so the claim can be checked rather than trusted — these are meant to be
  exactly the labels `Kati.Search.Query.chip_counts/1` returns, and this module
  is deliberately unable to ask it. See `@narrowable`.
  """
  @spec narrowable_scopes() :: [String.t()]
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
