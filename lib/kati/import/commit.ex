defmodule Kati.Import.Commit do
  @moduledoc """
  Writing an import, once the reader has answered whatever it could not decide.

  `Kati.Import.Job.plan/1` counted; this is the walk that writes, over the same
  three lists, so the number on the pill is the number of rows that appear.

  ## Three writes, and one of them is a title

  A **new** record creates the pair *Add by hand* creates — a
  `Kati.Media.CachedTitle` carrying the name and whatever the file knew, and a
  `Kati.Media.TrackedTitle` pointing at it by the value pair — with
  `source: :import`. That source matters: a row that came out of somebody's
  export is not a row TMDB answered for, and a later refresh must not treat it
  as one. `Kati.Media.Cache.tracked/0` sweeps only `:tmdb` rows for exactly
  this reason.

  A **merged** record writes the watch and leaves the title alone. The title
  is already the reader's and the file is not entitled to re-describe it.

  A **conflict** writes what the reader said: *Keep mine* writes nothing,
  *Take file* updates the rating on the watch that already exists, and *Keep
  both* writes a second watch for the same day — which is a real thing, because
  two people importing each other's exports is exactly how one evening gets two
  honest accounts.

  ## Every write is checked and none is fatal

  A row that cannot be written is counted and the walk continues. An import of
  four hundred is a long enough operation that failing the lot on the four
  hundredth is not a behaviour anybody wants, and the result says how many.
  """

  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Media.Watch

  @doc """
  Write the job. Answers what was written and what could not be.

  `answers` maps a conflict's `watch_id` to `:keep_mine`, `:take_file` or
  `:keep_both`. A conflict with no answer is left alone, which is `:keep_mine`
  by another name and is the safe reading of silence.
  """
  @spec run(map(), %{optional(String.t()) => atom()}) ::
          {:ok,
           %{
             new: non_neg_integer(),
             merged: non_neg_integer(),
             resolved: non_neg_integer(),
             failed: non_neg_integer()
           }}
  def run(job, answers \\ %{}) do
    plan = job.plan

    tally = %{new: 0, merged: 0, resolved: 0, failed: 0}

    tally =
      Enum.reduce(plan.new, tally, fn record, acc ->
        bump(acc, :new, Kati.Import.Commit.create(record))
      end)

    tally =
      Enum.reduce(plan.merged, tally, fn record, acc ->
        bump(acc, :merged, Kati.Import.Commit.log(record.tracked_id, record))
      end)

    tally =
      Enum.reduce(plan.conflicts, tally, fn clash, acc ->
        bump(acc, :resolved, Kati.Import.Commit.resolve(clash, Map.get(answers, clash.watch_id)))
      end)

    # MOVIES-AND-TV.md #112. Screen 15's own sample carries *Imported 412 titles
    # from a CSV backup* and no import had ever recorded that it ran. One row
    # for the batch, not one per title: the reader did one thing.
    Kati.Media.Log.imported(tally.new + tally.merged + tally.resolved, Map.get(job, :file))

    {:ok, tally}
  end

  @doc false
  @spec create(map()) :: :ok | :error
  def create(record) do
    kind = Map.get(record, :kind, :movie)

    with {:ok, _cached} <- Kati.Import.Commit.cache(record, kind),
         {:ok, tracked} <- Kati.Import.Commit.track(record, kind),
         :ok <- Kati.Import.Commit.log(tracked.id, record) do
      :ok
    else
      _refused -> :error
    end
  end

  @doc false
  def cache(record, kind) do
    CachedTitle
    |> Ash.Changeset.for_create(:create, %{
      source: :import,
      source_id: record.title,
      kind: kind,
      title: record.title,
      fetched_at: Kati.Time.now()
    })
    |> Ash.create()
  end

  @doc false
  def track(record, kind) do
    TrackedTitle
    |> Ash.Changeset.for_create(:create, %{
      source: :import,
      source_id: record.title,
      kind: kind,
      # A file that says when you watched it says you watched it. Without a
      # date there is no such claim, and `:watching` is what an added title is.
      status: if(Map.get(record, :watched_on), do: :finished, else: :watching)
    })
    |> Ash.create()
  end

  @doc """
  The watch a record describes, or `:ok` when it describes none.

  A row with no date, no rating and no review is a title somebody keeps rather
  than an evening they had — a Letterboxd watchlist export is exactly that —
  and writing an empty watch for it would put a film in *Your year* nobody
  watched.
  """
  @spec log(String.t(), map()) :: :ok | :error
  def log(tracked_id, record) do
    if Kati.Import.Commit.watch?(record) do
      Watch
      |> Ash.Changeset.for_create(:create, Kati.Import.Commit.attrs(tracked_id, record))
      |> Ash.create()
      |> case do
        {:ok, _watch} -> :ok
        {:error, _reason} -> :error
      end
    else
      :ok
    end
  end

  @doc """
  Whether a record is an account of a watch at all.

      iex> Kati.Import.Commit.watch?(%{title: "Dune"})
      false

      iex> Kati.Import.Commit.watch?(%{title: "Dune", rating: 9})
      true
  """
  @spec watch?(map()) :: boolean()
  def watch?(record) do
    Enum.any?([:watched_on, :rating, :review], &Map.has_key?(record, &1))
  end

  @doc false
  def attrs(tracked_id, record) do
    day = Map.get(record, :watched_on)

    %{
      tracked_title_id: tracked_id,
      rating: Map.get(record, :rating),
      review: Map.get(record, :review),
      service: Map.get(record, :service),
      tags: Map.get(record, :tags),
      watched_on: day,
      # The hour nobody exported. Midday in the device's zone rather than
      # midnight, for the reason `Kati.Media.Watch` keeps the two columns
      # apart: midnight is the value that crosses a day boundary the moment
      # anything reads it in another zone.
      watched_at: day && Kati.Import.Commit.noon(day)
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  @doc false
  def noon(day) do
    day
    |> NaiveDateTime.new!(~T[12:00:00])
    |> Kati.Time.to_utc(Kati.Time.device_zone())
    |> case do
      {:ok, instant} -> DateTime.truncate(instant, :second)
      _impossible -> nil
    end
  end

  @doc """
  Do what the reader said about one disagreement.

  Silence is *Keep mine*: see `run/2`.
  """
  @spec resolve(map(), atom() | nil) :: :ok | :error
  def resolve(_clash, answer) when answer in [nil, :keep_mine], do: :ok

  def resolve(clash, :take_file) do
    case Ash.get(Watch, clash.watch_id) do
      {:ok, watch} ->
        watch
        |> Ash.Changeset.for_update(:update, %{rating: clash.theirs})
        |> Ash.update()
        |> case do
          {:ok, _updated} -> :ok
          {:error, _reason} -> :error
        end

      _gone ->
        :error
    end
  end

  def resolve(clash, :keep_both), do: Kati.Import.Commit.log(clash.tracked_id, clash.record)

  def resolve(_clash, _unknown), do: :ok

  defp bump(tally, key, :ok), do: Map.update!(tally, key, &(&1 + 1))
  defp bump(tally, _key, :error), do: Map.update!(tally, :failed, &(&1 + 1))
end
