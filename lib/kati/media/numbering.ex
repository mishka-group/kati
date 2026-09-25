defmodule Kati.Media.Numbering do
  @moduledoc """
  How one title's episodes are numbered: by season (`S4 E12`) or absolutely
  (`E87`).

  The same episode has both numbers, and different sources lead with
  different ones — anime databases count absolutely, TMDB counts by season.
  `Kati.Media.TrackedTitle.numbering` holds the reader's choice for one title,
  and is `nil` until they make one. This module is the only place that turns
  that column into a scheme.

  ## The default, and its reason

  A title with no choice inherits a default, and the default says why it is
  what it is (screen 153):

    * **anime** counts absolutely — the convention every anime source and
      every anime fan uses;
    * **everything else** counts by season.

  "Anime" is `Kati.Media.Anime`'s first rule applied to the tracked row: the
  reader's own `anime_override` wins in both directions, and only when they
  have not said does `kind == :anime` decide. A reader who tagged a show
  *not anime* on screen 152 gets seasons, whatever its kind still reads.

  ## What a choice writes

  `choose/2` stores the scheme only when it differs from the default, and
  clears the column when it matches. So *you set this* on screen 153 is shown
  exactly when the reader's choice is doing something, and a title whose kind
  later changes follows its new default unless the reader overruled the old
  one. `reset/1` clears the column outright.

  ## What it changes

  Only the label. `Kati.Media.Watch` keys a tick on the episode's `source_id`,
  never on either number, so switching schemes cannot lose or move a tick.

  ## Where an absolute number comes from

  `absolute_numbers/1`: the provider's own `absolute_number` when any episode
  of the title carries one, and otherwise the numbering
  `Kati.Media.CachedEpisode.derived_absolute/1` can prove from a complete
  cache. An episode neither can place has no absolute number, and a screen
  showing it falls back to season and episode rather than inventing one.
  """

  alias Kati.Media.CachedEpisode
  alias Kati.Media.TrackedTitle

  @type scheme :: :seasons | :absolute

  @schemes [:seasons, :absolute]

  @doc "Both schemes, seasons first."
  @spec schemes() :: [scheme()]
  def schemes, do: @schemes

  @doc """
  Whether a tracked row counts as anime for numbering.

      iex> Kati.Media.Numbering.anime?(%{kind: :anime, anime_override: nil})
      true

      iex> Kati.Media.Numbering.anime?(%{kind: :anime, anime_override: false})
      false

      iex> Kati.Media.Numbering.anime?(%{kind: :tv, anime_override: true})
      true

      iex> Kati.Media.Numbering.anime?(%{kind: :tv, anime_override: nil})
      false
  """
  @spec anime?(map()) :: boolean()
  def anime?(%{anime_override: true}), do: true
  def anime?(%{anime_override: false}), do: false
  def anime?(%{kind: kind}), do: kind == :anime
  def anime?(_row), do: false

  @doc """
  The scheme a title inherits when the reader has not chosen.

      iex> Kati.Media.Numbering.default(%{kind: :anime, anime_override: nil})
      :absolute

      iex> Kati.Media.Numbering.default(%{kind: :tv, anime_override: nil})
      :seasons
  """
  @spec default(map()) :: scheme()
  def default(row), do: if(anime?(row), do: :absolute, else: :seasons)

  @doc """
  The scheme a title is numbered in: the reader's choice, or the default.

      iex> Kati.Media.Numbering.effective(%{kind: :tv, anime_override: nil, numbering: :absolute})
      :absolute

      iex> Kati.Media.Numbering.effective(%{kind: :anime, anime_override: nil, numbering: nil})
      :absolute
  """
  @spec effective(map()) :: scheme()
  def effective(%{numbering: scheme}) when scheme in @schemes, do: scheme
  def effective(row), do: default(row)

  @doc "Whether the reader's own choice is set on this title."
  @spec chosen?(map()) :: boolean()
  def chosen?(%{numbering: scheme}) when scheme in @schemes, do: true
  def chosen?(_row), do: false

  @doc """
  The episode order a scheme lists in, and the scheme an order stands for.

  Screen 34's strip names orders — *Aired*, *Absolute* — and the column names
  schemes; seasons is the aired order.

      iex> Kati.Media.Numbering.order(:seasons)
      :aired

      iex> Kati.Media.Numbering.scheme(:absolute)
      :absolute
  """
  @spec order(scheme()) :: CachedEpisode.order()
  def order(:seasons), do: :aired
  def order(:absolute), do: :absolute

  @doc false
  @spec scheme(CachedEpisode.order()) :: scheme()
  def scheme(:aired), do: :seasons
  def scheme(:absolute), do: :absolute

  @doc """
  Store the reader's choice for one title.

  Clears the column when the choice is the default — see the moduledoc.
  """
  @spec choose(TrackedTitle.t(), scheme()) :: {:ok, TrackedTitle.t()} | {:error, term()}
  def choose(%TrackedTitle{} = tracked, scheme) when scheme in @schemes do
    stored = if scheme == default(tracked), do: nil, else: scheme
    write(tracked, stored)
  end

  @doc "Clear the reader's choice, so the title follows its default again."
  @spec reset(TrackedTitle.t()) :: {:ok, TrackedTitle.t()} | {:error, term()}
  def reset(%TrackedTitle{} = tracked), do: write(tracked, nil)

  @doc "The opposite of a scheme — what *Override* on screen 153 switches to."
  @spec other(scheme()) :: scheme()
  def other(:seasons), do: :absolute
  def other(:absolute), do: :seasons

  defp write(tracked, stored) do
    tracked
    |> Ash.Changeset.for_update(:set_numbering, %{numbering: stored})
    |> Ash.update()
  end

  @doc """
  Every absolute number a title's episodes can honestly carry, by `source_id`.

  The provider's column when any episode has it, otherwise
  `Kati.Media.CachedEpisode.derived_absolute/1`, otherwise `%{}`.

      iex> alias Kati.Media.CachedEpisode
      iex> Kati.Media.Numbering.absolute_numbers([
      ...>   %CachedEpisode{source_id: "a", season_number: 1, episode_number: 1, absolute_number: 87, special: false}
      ...> ])
      %{"a" => 87}
  """
  @spec absolute_numbers([CachedEpisode.t()]) :: %{String.t() => pos_integer()}
  def absolute_numbers(episodes) do
    case for(%CachedEpisode{absolute_number: n} = ep <- episodes, is_integer(n), do: ep) do
      [] -> CachedEpisode.derived_absolute(episodes)
      stored -> Map.new(stored, &{&1.source_id, &1.absolute_number})
    end
  end

  @doc """
  A title's absolute numbers, read from the cache, or `%{}` when none can be
  given or the cache cannot be read.
  """
  @spec absolute_numbers_for(TrackedTitle.t()) :: %{String.t() => pos_integer()}
  def absolute_numbers_for(%TrackedTitle{} = tracked) do
    tracked.source
    |> CachedEpisode.for_title(tracked.source_id)
    |> absolute_numbers()
  rescue
    _error -> %{}
  end
end
