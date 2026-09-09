defmodule Kati.Search.Recent do
  @moduledoc """
  The queries this install has actually run, newest first.

  Screens 19, 86 and 88 all draw a shelf of them and none of them had one:
  `Kati.Search.Sample.recent/0` held `dentist`, `leaving soon`, `ines karvel`,
  `4 stars` and `miso salmon` on every device, so a person's own search
  history was five words they had never typed — the same defect #91 reports
  about the shelves, one screen further in.

  ## Why `Mob.State` and not a resource

  The same argument `Kati.Sections` makes: this is a preference, not data. It
  survives a restart, it is readable before the repo is up, and it is
  deliberately **not** in `kati.db` — restoring a backup taken on another
  device must not hand this phone somebody else's search history. There is
  nothing in a query worth syncing and quite a lot in one worth not syncing.

  ## What screen 88 specifies, and this keeps

    * **Eight.** `Kati.Search.recent_kept/0`, and the shelf on 86 shows the
      first few of them — the drawing's own note is that the field remembers
      more than fits.
    * **Never translated.** *"they are your words"*, in 88's own row. So
      nothing here folds, normalises or localises what was typed; it is stored
      as it was typed and compared as it was typed.
    * **Newest first, and each query once.** Searching the same thing twice
      moves it to the front rather than filling the shelf with it.

  ## Why the write is separate from the read

  `remember/1` is called by the screen that ran the query, not by
  `Kati.Search.Query.run/1`. Running a query is what the reference boards do
  when they draw the spec, and a history that filled itself from a render
  would fill with whatever the gallery drew last.
  """

  @key :kati_search_recent

  @doc """
  Every remembered query, newest first.

  `[]` before anything has been searched, which is a real state and the one
  screen 86 draws its own empty shelf for. Not the drawing's five words.
  """
  @spec all() :: [String.t()]
  def all do
    case Mob.State.get(@key) do
      list when is_list(list) -> Enum.filter(list, &is_binary/1)
      _never_searched -> []
    end
  rescue
    # `Mob.State` is DETS and raises when its table is not open — a host test
    # that has not started it, and the gallery on a cold boot. No history is
    # the right answer to a store that cannot be read.
    _error -> []
  end

  @doc """
  Remember `query`, at the front.

  Short queries are dropped rather than stored: `Kati.Search.long_enough?/1`
  is what says a query has run at all, and a shelf that filled with every
  first keystroke would be a list of single letters.

  ## A query you were on the way to is not a query you made

  `Kati.Screens.Search` records on every keystroke and says why — the results
  arrive while you type, so there is no submit to record on. The cost showed up
  the first time anyone typed a whole word on a device: searching *Ashfall*
  left `Ash`, `Ashf`, `Ashfa`, `Ashfal` and `Ashfall` in a list that keeps
  eight, so one search filled five of the eight slots with its own keystrokes
  and pushed out every earlier search.

  So an entry the new query **starts with** is dropped along with an exact
  repeat: it is a word you passed through rather than one you stopped on. The
  reverse is not true and must not be — typing `Ash` after having searched
  `Ashfall` is a shorter search, not an abandoned longer one, and both are kept
  with the newer first.
  """
  @spec remember(String.t()) :: :ok
  def remember(query) when is_binary(query) do
    trimmed = String.trim(query)

    if Kati.Search.long_enough?(trimmed) do
      kept =
        [trimmed | Enum.reject(all(), &passed_through?(trimmed, &1))]
        |> Enum.take(Kati.Search.recent_kept())

      Mob.State.put(@key, kept)
    end

    :ok
  rescue
    _error -> :ok
  end

  # An exact repeat, or a word the new query was typed through. Compared
  # case-insensitively for the reason the search itself is: `ash` and `Ash` are
  # one word to a person, and keeping both would put the shift key in the
  # history.
  defp passed_through?(now, stored) do
    String.starts_with?(String.downcase(now), String.downcase(stored))
  end

  @doc "Forget everything. For the tests, and for a future *Clear history* row."
  @spec forget!() :: :ok
  def forget! do
    Mob.State.delete(@key)
    :ok
  rescue
    _error -> :ok
  end
end
