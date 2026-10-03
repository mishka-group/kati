defmodule Kati.Notifications.Fold do
  @moduledoc """
  One notification per title per day, however many updates it has (#125).

  A season dropped whole is ten episodes airing at the same minute, and ten
  alarms for one show is noise, not news. Candidates that name the same title
  (`meta.tracked_id`) and fire on the same local day fold into the earliest of
  them, which keeps its time and its title and takes a body that counts the
  rest: *3 new episodes*. The folded ids ride along in `members`, so the plan
  still knows what it stands for.

  Suppressed candidates and candidates naming no title pass through untouched.
  """
  use Gettext, backend: Kati.Gettext

  alias Kati.Notifications.Candidate

  @doc """
  Fold `candidates` by title and local day in `zone`.
  """
  @spec by_title([Candidate.t()], String.t()) :: [Candidate.t()]
  def by_title(candidates, zone) do
    {foldable, rest} = Enum.split_with(candidates, &Kati.Notifications.Fold.foldable?/1)

    folded =
      foldable
      |> Enum.group_by(&{&1.meta.tracked_id, Kati.Notifications.Fold.day(&1, zone)})
      |> Enum.map(fn {_key, group} -> Kati.Notifications.Fold.fold(group) end)

    rest ++ folded
  end

  @doc false
  def foldable?(%Candidate{suppressed: nil, at: {:absolute, %DateTime{}}, meta: %{tracked_id: id}})
      when is_binary(id),
      do: true

  def foldable?(_candidate), do: false

  @doc false
  def day(%Candidate{at: {:absolute, at}}, zone),
    do: at |> Kati.Time.in_zone(zone) |> DateTime.to_date()

  @doc """
  The group as one candidate: the earliest, counting the rest.
  """
  @spec fold([Candidate.t()]) :: Candidate.t()
  def fold([one]), do: one

  def fold(group) do
    [first | _] = sorted = Enum.sort_by(group, fn %{at: {:absolute, at}} -> at end, DateTime)
    n = length(sorted)

    %{
      first
      | body: ngettext("%{n} new episode", "%{n} new episodes", n, n: Kati.Locale.number(n)),
        members: Enum.map(sorted, & &1.id)
    }
  end
end
