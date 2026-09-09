defmodule Kati.StalenessTest do
  @moduledoc """
  Gone cold, the one status Kati infers.

  Board 148 draws five states and its moduledoc claimed
  `Kati.Media.TrackedTitle.status` held all five. It holds four —
  `:not_started | :watching | :paused | :finished | :dropped`, no `:gone_cold`
  — and nothing anywhere in the app ever wrote `:paused` either. So both
  screens that draw a Gone cold band read `status == :paused`, a value with no
  writer, and drew nothing on every device that has ever existed.
  MOVIES-AND-TV.md #55 and #56.

  The board was right and the workaround was wrong. Its own footnote says
  which: *Paused and Dropped are things a person decided. Gone cold is
  something Kati noticed.* A thing Kati noticed is a question asked of the row
  every time it is drawn, which is why no migration was needed — and why one
  would have been the wrong answer: a stored `:gone_cold` would need a job to
  write it, would have to be unwritten the moment the reader watched something,
  and would disagree with the shelf for as long as that job had not run.
  """

  use Mob.ScreenCase, async: false

  alias Kati.Media.CachedTitle
  alias Kati.Media.Staleness
  alias Kati.Media.TrackedTitle

  doctest Staleness, only: [cold_after_days: 0]

  @prefix "staleness-"

  setup do
    on_exit(fn ->
      Kati.Repo.query!("DELETE FROM tracked_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
      Kati.Repo.query!("DELETE FROM cached_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
    end)

    %{now: Kati.Time.now()}
  end

  describe "what counts as cold" do
    test "a title nobody has touched for four months", %{now: now} do
      stale = tracked!("stale", :watching, days_ago(now, Staleness.cold_after_days() + 1))

      assert Staleness.gone_cold?(stale, now)
    end

    test "and one touched a day inside it is not", %{now: now} do
      warm = tracked!("warm", :watching, days_ago(now, Staleness.cold_after_days() - 1))

      refute Staleness.gone_cold?(warm, now)
    end

    test "exactly at the threshold is cold", %{now: now} do
      edge = tracked!("edge", :watching, days_ago(now, Staleness.cold_after_days()))

      assert Staleness.gone_cold?(edge, now)
    end
  end

  describe "what cannot go cold" do
    for status <- [:finished, :dropped, :not_started] do
      test "a #{status} title, however old", %{now: now} do
        old = tracked!("#{unquote(status)}", unquote(status), days_ago(now, 3650))

        refute Staleness.gone_cold?(old, now),
               "a title in a state the reader chose is not something Kati has noticed"
      end
    end

    test "and a row with no touch at all", %{now: now} do
      refute Staleness.gone_cold?(%TrackedTitle{status: :watching, last_touched_at: nil}, now)
    end
  end

  describe "the two halves" do
    test "every row is in exactly one of them", %{now: now} do
      rows = [
        tracked!("a", :watching, days_ago(now, 200)),
        tracked!("b", :watching, days_ago(now, 2)),
        tracked!("c", :finished, days_ago(now, 900))
      ]

      cold = Staleness.cold(rows, now)
      warm = Staleness.warm(rows, now)

      assert length(cold) + length(warm) == length(rows)
      assert cold != [] and warm != []

      assert MapSet.disjoint?(
               MapSet.new(cold, & &1.id),
               MapSet.new(warm, & &1.id)
             )
    end
  end

  describe "screen 10's cold band" do
    test "is the derived one, not a status nothing writes" do
      tracked!("hot", :watching, days_ago(Kati.Time.now(), 1))
      tracked!("cold", :watching, days_ago(Kati.Time.now(), 400))

      queue = Kati.Screens.UpNext.queue()

      assert Enum.map(queue.cold, & &1.title) == ["Cold"]
      refute Enum.any?(queue.ready, &(&1.title == "Cold"))
      assert queue.hero.title == "Hot"
    end
  end

  defp days_ago(now, days), do: DateTime.add(now, -days, :day)

  defp tracked!(slug, status, touched) do
    source_id = @prefix <> slug

    Ash.create!(CachedTitle, %{
      source: :tmdb,
      source_id: source_id,
      kind: :tv,
      title: String.capitalize(slug),
      fetched_at: Kati.Time.now()
    })

    TrackedTitle
    |> Ash.Changeset.for_create(:create, %{
      source: :tmdb,
      source_id: source_id,
      kind: :tv,
      status: status
    })
    |> Ash.Changeset.force_change_attribute(:last_touched_at, touched)
    |> Ash.create!()
  end
end
