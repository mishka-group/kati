defmodule Kati.Calendars.Changes.RejectOriginChange do
  @moduledoc """
  `origin` is immutable after creation.

  Whether Kati owns an event or is mirroring someone else's decides whether it
  may be written back at all. Letting that flip mid-life is how a mirrored event
  gets pushed to a server that never asked for it, so this is enforced rather
  than documented.
  """
  use Ash.Resource.Change

  @impl true
  def change(changeset, _opts, _context) do
    case Ash.Changeset.get_attribute(changeset, :origin) do
      nil ->
        changeset

      new_origin ->
        old_origin = Map.get(changeset.data, :origin)

        if is_nil(old_origin) or old_origin == new_origin do
          changeset
        else
          Ash.Changeset.add_error(changeset,
            field: :origin,
            message: "origin is immutable: #{old_origin} cannot become #{new_origin}"
          )
        end
    end
  end
end

defmodule Kati.Calendars.Changes.BumpLocalRev do
  @moduledoc """
  Bumps `local_rev` on every local write.

  `local_rev > synced_rev` is what "dirty" means. A counter rather than a boolean
  because it survives an edit landing while a push of the previous version is
  still in flight — the boolean would be cleared by the in-flight push and the
  newer edit would never be sent.
  """
  use Ash.Resource.Change

  @impl true
  def change(changeset, _opts, _context) do
    current = Map.get(changeset.data, :local_rev) || 0
    Ash.Changeset.force_change_attribute(changeset, :local_rev, current + 1)
  end
end

defmodule Kati.Calendars.Changes.DeriveTiming do
  @moduledoc """
  Keeps the derived timing columns consistent with the authoritative ones.

  `duration_iso` is canonical, so `dtend_utc` is recomputed on every write rather
  than trusted. `recurs_until_utc` is computed from the rule so a range query can
  skip a master that ended years ago without expanding it.
  """
  use Ash.Resource.Change

  alias Kati.Recurrence.Rule

  @impl true
  def change(changeset, _opts, _context) do
    changeset
    |> derive_dtend()
    |> derive_recurs_until()
  end

  defp derive_dtend(changeset) do
    start = Ash.Changeset.get_attribute(changeset, :dtstart_utc)
    duration = Ash.Changeset.get_attribute(changeset, :duration_iso)

    case {start, parse_duration(duration)} do
      {%DateTime{} = s, seconds} when is_integer(seconds) ->
        Ash.Changeset.force_change_attribute(changeset, :dtend_utc, DateTime.add(s, seconds))

      _ ->
        changeset
    end
  end

  # nil means unbounded, which is the honest answer for FREQ=DAILY with no
  # UNTIL or COUNT — pretending otherwise would silently truncate someone's
  # daily habit.
  defp derive_recurs_until(changeset) do
    rrule = Ash.Changeset.get_attribute(changeset, :rrule)
    start = Ash.Changeset.get_attribute(changeset, :dtstart_utc)

    until =
      with true <- is_binary(rrule),
           {:ok, rule} <- Rule.parse(rrule) do
        cond do
          match?(%DateTime{}, rule.until) -> rule.until
          match?(%Date{}, rule.until) -> DateTime.new!(rule.until, ~T[23:59:59.999999], "Etc/UTC")
          # A bounded COUNT still ends, but computing exactly when means
          # expanding. Left nil: correct, if pessimistic for the query planner.
          true -> nil
        end
      else
        _ -> if is_nil(rrule), do: start, else: nil
      end

    Ash.Changeset.force_change_attribute(changeset, :recurs_until_utc, until)
  end

  # Minimal ISO-8601 duration support: the shapes a calendar actually emits.
  defp parse_duration(nil), do: nil

  defp parse_duration(iso) when is_binary(iso) do
    case Regex.run(~r/^P(?:(\d+)W)?(?:(\d+)D)?(?:T(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?)?$/, iso) do
      nil ->
        nil

      captures ->
        [w, d, h, m, s] =
          captures
          |> Enum.drop(1)
          |> Enum.map(fn
            "" -> 0
            nil -> 0
            v -> String.to_integer(v)
          end)
          |> then(&(&1 ++ List.duplicate(0, 5 - length(&1))))

        w * 604_800 + d * 86_400 + h * 3_600 + m * 60 + s
    end
  end

  defp parse_duration(_), do: nil
end
