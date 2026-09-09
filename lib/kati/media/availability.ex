defmodule Kati.Media.Availability do
  @moduledoc """
  Whether the reader can actually watch a title, and where.

  ## The question screen 92 has been asking on Kati's behalf

  That page offers three switches — *Count rentals as available*, *Count
  purchases as available*, *Hide titles I can't watch* — and the third prints
  the pages it empties: *Removes them from Discover, Up next and What fits
  tonight. Your library and wishlist keep everything.* All three were stored
  and read by nothing (MOVIES-AND-TV.md #77), because nothing in Kati knew
  where a title streams. A switch that remembers your answer and ignores it is
  worse than one that is missing: it has taken the decision and filed it.

  `Kati.Media.CachedTitle.providers` knows now. TMDB folds JustWatch's data
  into the detail response Kati already fetches, so the answer arrives with
  the poster and the runtime.

  ## What "available" means here, precisely

  A title is available when one of the ways it is offered in the reader's
  region is a way the reader has said yes to:

    * **Included with something you pay for.** `flatrate` matched against the
      services on screen 92, by name. This one needs no switch — it is what
      *subscribed* means.
    * **Free**, with or without ads. `free` and `ads`, and they are always
      available: there is nothing to opt into.
    * **Rentable**, when *Count rentals as available* is on.
    * **Buyable**, when *Count purchases as available* is on.

  Matching is by NAME and case-insensitively, because both sides are names a
  person recognises — `Kati.Services.Service` is keyed on what somebody typed,
  and TMDB gives `provider_name`. `Netflix` and `netflix` are one service.

  ## The three answers, and why `:unknown` is not `false`

  `state/3` answers `:available`, `:unavailable` or `:unknown`, and the third
  is the one that matters. A title nobody has fetched providers for, or one in
  a region JustWatch does not cover, is not a title you cannot watch — it is a
  title Kati has not been told about. Hiding it would empty a shelf for a
  reason the reader would have no way to discover, which is the failure screen
  92's own country note is about. So **`hide?/3` hides only what is known to
  be unavailable**, and a page with no provider data behaves exactly as it did
  before this module existed.
  """

  alias Kati.Media.CachedTitle

  @free ["free", "ads"]

  @doc """
  What the reader can do with this title in this region.

  `nil` for a title with no provider block at all — not `%{}`, because *not
  asked* and *asked, and nowhere* are different facts and only the second is
  worth putting on a screen.

      iex> Kati.Media.Availability.offers(nil, "GB")
      nil

      iex> Kati.Media.Availability.offers(%{"GB" => %{"flatrate" => ["Netflix"]}}, "GB")
      %{"flatrate" => ["Netflix"]}

      iex> Kati.Media.Availability.offers(%{"GB" => %{"flatrate" => ["Netflix"]}}, "IE")
      nil
  """
  @spec offers(map() | CachedTitle.t() | nil, String.t()) :: map() | nil
  def offers(%CachedTitle{providers: providers}, region), do: offers(providers, region)
  def offers(providers, region) when is_map(providers), do: Map.get(providers, region)
  def offers(_none, _region), do: nil

  @doc """
  `:available`, `:unavailable` or `:unknown`.

  `subscribed` is the names on screen 92; `rules` is `Kati.Services.rules/0`.

      iex> rules = %{rentals: false, purchases: false, hide_unavailable: true}
      iex> Kati.Media.Availability.state(%{"flatrate" => ["Netflix"]}, ["netflix"], rules)
      :available

      iex> rules = %{rentals: false, purchases: false, hide_unavailable: true}
      iex> Kati.Media.Availability.state(%{"rent" => ["Apple TV"]}, ["Netflix"], rules)
      :unavailable

      iex> rules = %{rentals: true, purchases: false, hide_unavailable: true}
      iex> Kati.Media.Availability.state(%{"rent" => ["Apple TV"]}, [], rules)
      :available

      iex> rules = %{rentals: false, purchases: false, hide_unavailable: true}
      iex> Kati.Media.Availability.state(nil, ["Netflix"], rules)
      :unknown
  """
  @spec state(map() | nil, [String.t()], map()) :: :available | :unavailable | :unknown
  def state(nil, _subscribed, _rules), do: :unknown

  def state(offers, subscribed, rules) when is_map(offers) do
    if reachable?(offers, subscribed, rules), do: :available, else: :unavailable
  end

  @doc """
  Whether a page should leave this title out.

  Only `:unavailable` hides, and only while the switch is on. `:unknown` never
  hides — see the moduledoc: a shelf emptied by data the reader cannot see is
  a shelf they cannot understand.

      iex> rules = %{rentals: false, purchases: false, hide_unavailable: true}
      iex> Kati.Media.Availability.hide?(nil, [], rules)
      false

      iex> rules = %{rentals: false, purchases: false, hide_unavailable: true}
      iex> Kati.Media.Availability.hide?(%{"rent" => ["Apple TV"]}, [], rules)
      true

      iex> rules = %{rentals: false, purchases: false, hide_unavailable: false}
      iex> Kati.Media.Availability.hide?(%{"rent" => ["Apple TV"]}, [], rules)
      false
  """
  @spec hide?(map() | nil, [String.t()], map()) :: boolean()
  def hide?(offers, subscribed, rules) do
    Map.get(rules, :hide_unavailable, false) and state(offers, subscribed, rules) == :unavailable
  end

  @doc """
  The line a title's page puts under it: *On Netflix*, *Rent from Apple TV*.

  `nil` when there is nothing true to say — no provider block, or a block with
  nothing in it that the reader's rules admit. A page that said *Not available*
  on a title Kati simply has not looked up would be inventing a fact.

  What the reader pays for wins, then free, then the ways their rules let in.
  Two names are joined; more than two say how many, because a line naming
  eight services is a paragraph.

      iex> rules = %{rentals: true, purchases: false, hide_unavailable: false}
      iex> Kati.Media.Availability.line(%{"flatrate" => ["Netflix"]}, ["Netflix"], rules)
      "On Netflix"

      iex> rules = %{rentals: true, purchases: false, hide_unavailable: false}
      iex> Kati.Media.Availability.line(%{"rent" => ["Apple TV", "Amazon"]}, [], rules)
      "Rent from Apple TV or Amazon"

      iex> rules = %{rentals: false, purchases: false, hide_unavailable: false}
      iex> Kati.Media.Availability.line(%{"rent" => ["Apple TV"]}, [], rules)
      nil

      iex> Kati.Media.Availability.line(nil, [], %{})
      nil
  """
  @spec line(map() | nil, [String.t()], map()) :: String.t() | nil
  def line(nil, _subscribed, _rules), do: nil

  def line(offers, subscribed, rules) when is_map(offers) do
    mine = yours(offers, subscribed)
    gratis = pick(offers, @free)
    rent = if rentals?(rules), do: pick(offers, ["rent"]), else: []
    buy = if buys?(rules), do: pick(offers, ["buy"]), else: []

    cond do
      mine != [] -> "On " <> names(mine)
      gratis != [] -> "Free on " <> names(gratis)
      rent != [] -> "Rent from " <> names(rent)
      buy != [] -> "Buy from " <> names(buy)
      true -> nil
    end
  end

  @doc """
  Every service this title is included with, whoever pays for it.

  What screen 92 could offer a reader who has told it nothing: *these are the
  services the things you are watching are on.* Names, ordered by how many of
  the reader's titles are on each.
  """
  @spec suggestions([CachedTitle.t()], String.t()) :: [{String.t(), pos_integer()}]
  def suggestions(cached, region) do
    cached
    |> Enum.flat_map(fn title ->
      case offers(title, region) do
        nil -> []
        offers -> pick(offers, ["flatrate"])
      end
    end)
    |> Enum.frequencies()
    |> Enum.sort_by(fn {name, count} -> {-count, name} end)
  end

  defp reachable?(offers, subscribed, rules) do
    yours(offers, subscribed) != [] or
      pick(offers, @free) != [] or
      (rentals?(rules) and pick(offers, ["rent"]) != []) or
      (buys?(rules) and pick(offers, ["buy"]) != [])
  end

  defp yours(offers, subscribed) do
    mine = MapSet.new(subscribed, &fold/1)

    offers
    |> pick(["flatrate"])
    |> Enum.filter(&MapSet.member?(mine, fold(&1)))
  end

  defp pick(offers, kinds) do
    kinds
    |> Enum.flat_map(&List.wrap(Map.get(offers, &1)))
    |> Enum.filter(&is_binary/1)
    |> Enum.uniq()
  end

  defp rentals?(rules), do: Map.get(rules, :rentals, false)
  defp buys?(rules), do: Map.get(rules, :purchases, false)

  defp fold(name) when is_binary(name), do: name |> String.trim() |> String.downcase()
  defp fold(_other), do: ""

  # No `[]` clause: every caller has already checked the list is non-empty, and
  # a clause the compiler can prove unreachable is a reader's false comfort.
  defp names([one]), do: one
  defp names([one, two]), do: one <> " or " <> two
  defp names([one, two | rest]), do: "#{one}, #{two} and #{length(rest)} more"
end
