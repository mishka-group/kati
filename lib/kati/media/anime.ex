defmodule Kati.Media.Anime do
  @moduledoc """
  Whether a title is anime, decided by board 152's own three rules.

  `:anime` was a kind every reader in the app knew and
  nothing ever wrote: `Kati.Screens.Library.shelf/0` queried a third shelf that
  was always empty, `Kati.Screens.Stats` had an `ANIME` label no row could
  carry, and screen 152 — a whole board about the flag — had no column and no
  writer behind a word of it.

  Screen 152 states the rule in three lines — `rules/0`, which that screen
  draws as fixed app behaviour — and this module is those three lines, in that
  order:

    1. **Your own tag** — *always wins, you know.*
       `Kati.Media.TrackedTitle.anime_override`, which is three-valued so that
       *I have not said* and *no* stay different answers.
    2. **The import source** — *a MAL or AniList file marks everything in it.*
       `Kati.Import.Mapping.looks_like/1` already names the file's own service,
       so the importer knows this without a column.
    3. **The provider genre** — *TMDB's Animation + Japanese origin.*
       Both halves, because either alone is wrong in a way a reader would
       notice: Animation alone files Pixar as anime, and Japanese origin alone
       files every live-action drama as anime.

  ## Anime is a kind, not a section

  `Kati.Screens.AnimeFilter`'s moduledoc says it first — *anime is a type, not
  a section* — and both resources have constrained `:kind` to include `:anime`
  since they were written. So the flag is the kind, and nothing downstream has
  to learn a new word: the shelf, the stats and the year cards already read all
  three Screen kinds.

  ## Which screen an anime opens

  `:anime` collapsed a distinction the rest of the app keeps. `Kati.Screens.
  Library.shaped/3` decided film-vs-series with `kind == :movie`, so an anime
  FILM would have opened the series screen — the latent half of #104. `film?/1`
  is what decides it now, from the cached row rather than from the kind.
  """

  @animation "Animation"
  @japanese ~w(ja)
  @promote_threshold 10

  @doc """
  How many anime titles a shelf holds before the Library draws an Anime chip.

  A fixed rule, not a setting: board 152 states it as *the tab-row chip
  appears at 10 or more anime titles*. Below it the chip is dropped rather than
  drawn with a small count — see `Kati.Screens.Library.anime_chip/1`.

      iex> Kati.Media.Anime.promote_threshold()
      10
  """
  @spec promote_threshold() :: pos_integer()
  def promote_threshold, do: @promote_threshold

  @doc """
  The three rules, as screen 152 prints them: rank, name, and what it means.

  English keys; `Kati.Screens.AnimeFilter.sample_text/1` turns each into the
  reader's words. They describe what `kind_for/3`, `source_says?/1` and
  `provider_says?/1` do, in that priority, and they are not a setting — no
  control on any screen reorders or disables them.
  """
  @spec rules() :: [{pos_integer(), String.t(), String.t()}]
  def rules do
    [
      {1, "Your own tag", "Always wins — you know"},
      {2, "The import source", "A MAL or AniList file marks everything in it"},
      {3, "The provider genre", "TMDB’s Animation + Japanese origin"}
    ]
  end

  @doc """
  The kind to file a title under, given what is known about it.

  `guessed` is the kind the provider or the form said — `:movie` or `:tv` — and
  is what comes back when no rule fires. A title is never *promoted out of*
  anime by a guess: rule 1 is the only thing that can say no.

      iex> Kati.Media.Anime.kind_for(:tv, %{genres: "Animation, Action", original_language: "ja"}, nil)
      :anime

      iex> Kati.Media.Anime.kind_for(:tv, %{genres: "Animation", original_language: "en"}, nil)
      :tv

      iex> Kati.Media.Anime.kind_for(:tv, %{genres: "Drama", original_language: "ja"}, nil)
      :tv

  Rule 1 beats rule 3 in both directions — a reader who says *not anime* about
  a Japanese cartoon is answered, and so is one who says *anime* about a
  co-production TMDB files under English:

      iex> Kati.Media.Anime.kind_for(:tv, %{genres: "Animation", original_language: "ja"}, false)
      :tv

      iex> Kati.Media.Anime.kind_for(:tv, %{genres: "Drama", original_language: "en"}, true)
      :anime
  """
  @spec kind_for(atom(), map() | nil, boolean() | nil) :: atom()
  def kind_for(_guessed, _cached, true), do: :anime
  def kind_for(guessed, _cached, false), do: Kati.Media.Anime.screen_kind(guessed)

  def kind_for(guessed, cached, _unsaid) do
    if Kati.Media.Anime.provider_says?(cached), do: :anime, else: guessed
  end

  @doc """
  Rule 3, asked of a cached row: Animation **and** Japanese origin.

      iex> Kati.Media.Anime.provider_says?(%{genres: "Animation", original_language: "ja"})
      true

      iex> Kati.Media.Anime.provider_says?(nil)
      false
  """
  @spec provider_says?(map() | nil) :: boolean()
  def provider_says?(nil), do: false

  def provider_says?(cached) do
    genres = cached |> Map.get(:genres) |> to_string()
    language = cached |> Map.get(:original_language) |> to_string()

    String.contains?(genres, @animation) and language in @japanese
  end

  @doc """
  Rule 2: whether an import source marks everything in its file as anime.

      iex> Kati.Media.Anime.source_says?("myanimelist")
      true

      iex> Kati.Media.Anime.source_says?("letterboxd")
      false
  """
  @spec source_says?(String.t() | atom() | nil) :: boolean()
  def source_says?(source), do: to_string(source) in ~w(myanimelist anilist)

  @doc """
  What an anime falls back to when the reader says it is not one.

  `:anime` carries no film-or-series information of its own, so the answer has
  to come from somewhere: the guess that was made before the flag was applied.
  A bare `:anime` with nothing else known is a series, which is what the
  overwhelming majority of them are and what screen 152's own board draws.

      iex> Kati.Media.Anime.screen_kind(:movie)
      :movie

      iex> Kati.Media.Anime.screen_kind(:anime)
      :tv
  """
  @spec screen_kind(atom()) :: atom()
  def screen_kind(:movie), do: :movie
  def screen_kind(:anime), do: :tv
  def screen_kind(kind), do: kind

  @doc """
  Whether this title opens the film screen rather than the series screen.

  The latent half of #104: `Kati.Screens.Library.shaped/3` asked `kind ==
  :movie`, so an anime film — now that anime films can exist — would have
  opened screen 04 and asked for its seasons.

  `:anime` carries no film-or-series information of its own, so the answer has
  to come from the row. **The cache is asked first**, and that is the whole
  fix: an override writes `Kati.Media.TrackedTitle.kind` and leaves the cached
  row alone, so `Akira` marked as anime is a `:movie` in the cache still. This
  was found on the Pixel_9a — a film added by hand and marked as anime moved to
  the series screen, because the shape guess below is all the app had to go on
  and a hand-added film has neither a runtime nor an episode count.

  The shape guess stays for the row the cache has never held: a runtime and no
  episodes is a film, and everything else is a series, which is what the
  overwhelming majority of anime are and what board 152 draws.

      iex> Kati.Media.Anime.film?(:movie, %{})
      true

      iex> Kati.Media.Anime.film?(:anime, %{kind: :movie})
      true

      iex> Kati.Media.Anime.film?(:anime, %{kind: :tv, runtime_minutes: 24})
      false

      iex> Kati.Media.Anime.film?(:anime, %{episode_count: 12})
      false

      iex> Kati.Media.Anime.film?(:anime, %{runtime_minutes: 117})
      true

      iex> Kati.Media.Anime.film?(:anime, nil)
      false
  """
  @spec film?(atom(), map() | nil) :: boolean()
  def film?(:movie, _cached), do: true
  def film?(:tv, _cached), do: false
  def film?(_anime, %{kind: :movie}), do: true
  def film?(_anime, %{kind: kind}) when kind in [:tv, :book, :album], do: false

  def film?(_anime, cached) do
    episodes = cached && Map.get(cached, :episode_count)
    runtime = cached && Map.get(cached, :runtime_minutes)

    is_nil(episodes) and is_integer(runtime) and runtime > 0
  end
end
