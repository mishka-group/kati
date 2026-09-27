defmodule Kati.Media.Provider do
  @moduledoc """
  The catalogues a film, series or anime can be found in and fetched from,
  asked by name.

  Three: `Kati.Media.Tmdb`, which needs the reader's own token, and the two
  that need nothing — `Kati.Media.Anilist` (anime, series and films) and
  `Kati.Media.Tvmaze` (series only). A search row, a preview and an add all
  carry `source`, and this module is where that atom turns into the client
  that answers for it, so no screen has a `case` over providers of its own.

  ## Why the keyless two exist

  Without a token TMDB answers `{:error, :no_api_key}` to everything, and
  screen 19 had nothing else to ask: a fresh install searching *sakamoto*
  found nothing at all. AniList and TVmaze are free and keyless, so they are
  asked instead whenever no token is saved (`Kati.Search.Keyless`). With a
  token, TMDB is asked alone, exactly as before.

  ## What stays TMDB's

  Refreshing the cache (`Kati.Media.Cache.tracked/0`), recommendations,
  `/discover` and where-to-watch are TMDB endpoints keyed on TMDB ids. A row
  from AniList or TVmaze carries that source's own id, and TMDB would answer
  it with a different title that happens to share the number — so those paths
  take `tmdb?/1` rows only, and a keyless row simply has nothing there.

  ## One transport for the keyless two

  `request/3` is the whole of their HTTP: `Kati.Net.Tls.ensure!/0`, the host
  resolved through `Kati.Net.Dns.resolve/1` (Android's BEAM cannot resolve a
  name itself), the test seam merged in, and every failure named — a sinkhole
  answer is `:blocked` through `Kati.Media.Tmdb.transport_failure/2`, the
  same question TMDB's failures are asked. Nothing raises.
  """

  use Gettext, backend: Kati.Gettext

  @timeout 15_000

  @typedoc "A catalogue Kati can search and fetch from."
  @type source :: :tmdb | :anilist | :tvmaze

  @doc """
  Every source a search row, a preview or an add can come from.

      iex> Kati.Media.Provider.fetchable()
      [:tmdb, :anilist, :tvmaze]
  """
  @spec fetchable() :: [source()]
  def fetchable, do: [:tmdb, :anilist, :tvmaze]

  @doc """
  The sources that need no key, in the order screen 19 draws them.

      iex> Kati.Media.Provider.keyless()
      [:anilist, :tvmaze]
  """
  @spec keyless() :: [source()]
  def keyless, do: [:anilist, :tvmaze]

  @doc """
  Whether `source` is one this module can fetch from.

      iex> Kati.Media.Provider.fetchable?(:tvmaze)
      true

      iex> Kati.Media.Provider.fetchable?(:manual)
      false
  """
  @spec fetchable?(term()) :: boolean()
  def fetchable?(source), do: source in fetchable()

  @doc """
  Whether a row's ids are TMDB's, which is what every TMDB-only path asks
  before it sends one.

      iex> Kati.Media.Provider.tmdb?(%{source: :tmdb})
      true

      iex> Kati.Media.Provider.tmdb?(%{source: :anilist})
      false
  """
  @spec tmdb?(map() | nil) :: boolean()
  def tmdb?(%{source: :tmdb}), do: true
  def tmdb?(_other), do: false

  @doc """
  The catalogue's own name, which is a trade name and never translated.

      iex> Kati.Media.Provider.name(:anilist)
      "AniList"
  """
  @spec name(source()) :: String.t()
  def name(:tmdb), do: "TMDB"
  def name(:anilist), do: "AniList"
  def name(:tvmaze), do: "TVmaze"

  @doc """
  Whether `source` can be asked right now: TMDB only with a saved token, the
  keyless two always.
  """
  @spec usable?(source()) :: boolean()
  def usable?(:tmdb), do: Kati.Media.Tmdb.usable?()
  def usable?(source) when source in [:anilist, :tvmaze], do: true

  @doc "Search one catalogue. `{:ok, [result]}` or `{:error, reason}`, never a raise."
  @spec search(source(), String.t()) :: {:ok, [map()]} | {:error, term()}
  def search(:tmdb, query), do: Kati.Media.Tmdb.search(query)
  def search(:anilist, query), do: Kati.Media.Anilist.search(query)
  def search(:tvmaze, query), do: Kati.Media.Tvmaze.search(query)

  @doc "One page of `source`'s search, and whether there is another."
  @spec search_page(source(), String.t(), pos_integer()) ::
          {:ok, %{results: [map()], more?: boolean()}} | {:error, term()}
  def search_page(:tmdb, query, page), do: Kati.Media.Tmdb.search_page(query, page)
  def search_page(:anilist, query, page), do: Kati.Media.Anilist.search_page(query, page)
  def search_page(:tvmaze, query, page), do: Kati.Media.Tvmaze.search_page(query, page)

  @doc """
  Fill the cache for one title from its own catalogue, answering what
  `Kati.Media.Tmdb.fetch/2` answers: `%{title: cached_row, seasons: n,
  episodes: n}`.
  """
  @spec fetch(source(), String.t(), :movie | :tv) :: {:ok, map()} | {:error, term()}
  def fetch(:tmdb, source_id, kind), do: Kati.Media.Tmdb.fetch(source_id, kind)
  def fetch(:anilist, source_id, kind), do: Kati.Media.Anilist.fetch(source_id, kind)
  def fetch(:tvmaze, source_id, kind), do: Kati.Media.Tvmaze.fetch(source_id, kind)

  @doc """
  The sentence a screen shows for a failure from `source`.

  TMDB's are `Kati.Media.Tmdb.message/1`'s. The keyless two share one set,
  with the catalogue's name in it, one clause per reason and no `_` — for
  the reason that function gives.
  """
  @spec message(source(), {:error, term()} | term()) :: String.t()
  def message(source, {:error, reason}), do: message(source, reason)
  def message(:tmdb, reason), do: Kati.Media.Tmdb.message(reason)

  def message(source, :rate_limited),
    do: gettext("%{source} is busy. Try again in a minute.", source: name(source))

  def message(source, :not_found),
    do: gettext("%{source} has nothing under that id.", source: name(source))

  def message(source, {:http, status}),
    do:
      gettext("%{source} answered %{status}. Nothing was saved.",
        source: name(source),
        status: status
      )

  def message(source, {:network, _reason}),
    do: gettext("Could not reach %{source}. Hand-typed titles still work.", source: name(source))

  def message(source, :blocked),
    do:
      gettext(
        "This network is blocking %{source}. Try another Wi-Fi or mobile data. Hand-typed titles still work.",
        source: name(source)
      )

  @doc """
  One request to a keyless catalogue, with every failure named.

  `options` are Req's; `dns_host` is the name `Kati.Net.Dns.resolve/1`
  seeds; `seam` is the application-env key a test hands its adapter
  through (`:anilist_req_options`, `:tvmaze_req_options`), merged last.
  Answers the decoded body of a 200, or `:rate_limited`, `:not_found`,
  `{:http, status}`, `:blocked` or `{:network, reason}`.
  """
  @spec request(keyword(), String.t(), atom()) :: {:ok, term()} | {:error, term()}
  def request(options, dns_host, seam) do
    Kati.Net.Tls.ensure!()
    _resolved = Kati.Net.Dns.resolve(dns_host)

    [receive_timeout: @timeout, retry: false]
    |> Keyword.merge(options)
    |> Keyword.merge(Application.get_env(:kati, seam, []))
    |> Req.new()
    |> Req.request()
    |> case do
      {:ok, %Req.Response{status: 200, body: body}} when is_map(body) or is_list(body) ->
        {:ok, body}

      {:ok, %Req.Response{status: 200}} ->
        {:error, {:http, 200}}

      {:ok, %Req.Response{status: 429}} ->
        {:error, :rate_limited}

      {:ok, %Req.Response{status: 404}} ->
        {:error, :not_found}

      {:ok, %Req.Response{status: status}} ->
        {:error, {:http, status}}

      {:error, reason} ->
        {:error, Kati.Media.Tmdb.transport_failure(reason, dns_host)}
    end
  rescue
    error -> {:error, Kati.Media.Tmdb.transport_failure(error, dns_host)}
  end

  @doc """
  Upsert one cache row by `filter`: update the row that matches, or create
  one. The three cache resources are re-fetched by design, so writing the same
  row twice must update rather than fail — `Kati.Media.Tmdb`'s own rule.
  """
  @spec upsert(module(), keyword(), map()) :: {:ok, term()} | {:error, term()}
  def upsert(resource, filter, attrs) do
    existing =
      resource
      |> Ash.Query.do_filter(filter)
      |> Ash.read!()
      |> List.first()

    case existing do
      nil -> resource |> Ash.Changeset.for_create(:create, attrs) |> Ash.create()
      row -> row |> Ash.Changeset.for_update(:update, attrs) |> Ash.update()
    end
  rescue
    error -> {:error, error}
  end

  @doc """
  Provider prose as plain text: tags dropped, the common entities decoded,
  runs of whitespace folded, and `nil` for nothing left.

      iex> Kati.Media.Provider.plain("<p>A <b>quiet</b> town&#039;s secret.<br>Part&nbsp;one.</p>")
      "A quiet town's secret. Part one."

      iex> Kati.Media.Provider.plain("<p></p>")
      nil

      iex> Kati.Media.Provider.plain(nil)
      nil
  """
  @spec plain(term()) :: String.t() | nil
  def plain(text) when is_binary(text) do
    text
    |> String.replace(~r/<br\s*\/?>/i, " ")
    |> String.replace(~r/<[^>]*>/, "")
    |> String.replace("&amp;", "&")
    |> String.replace("&quot;", "\"")
    |> String.replace("&#039;", "'")
    |> String.replace("&#39;", "'")
    |> String.replace("&lt;", "<")
    |> String.replace("&gt;", ">")
    |> String.replace("&nbsp;", " ")
    |> String.replace(~r/\s+/u, " ")
    |> String.trim()
    |> case do
      "" -> nil
      plain -> plain
    end
  end

  def plain(_other), do: nil

  @doc """
  A positive integer, or `nil`.

      iex> Kati.Media.Provider.positive(24)
      24

      iex> Kati.Media.Provider.positive(0)
      nil
  """
  @spec positive(term()) :: pos_integer() | nil
  def positive(n) when is_integer(n) and n > 0, do: n
  def positive(_other), do: nil

  @doc "`map` with `key` put only when `value` is not `nil`."
  @spec put_if(map(), atom(), term()) :: map()
  def put_if(map, _key, nil), do: map
  def put_if(map, key, value), do: Map.put(map, key, value)

  @doc """
  An ISO date as midnight UTC at `:day` confidence, onto `map`'s `air_at` and
  `date_confidence`; `map` unchanged for anything that is not a date.
  """
  @spec put_day(map(), term()) :: map()
  def put_day(map, date) when is_binary(date) and date != "" do
    case Date.from_iso8601(date) do
      {:ok, day} ->
        map
        |> Map.put(:air_at, DateTime.new!(day, ~T[00:00:00.000000], "Etc/UTC"))
        |> Map.put(:date_confidence, :day)

      _error ->
        map
    end
  end

  def put_day(map, _date), do: map
end
