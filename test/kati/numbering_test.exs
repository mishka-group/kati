defmodule Kati.NumberingTest do
  @moduledoc """
  P1: a show's numbering is a column, and screens 34, 153 and 04 read it and
  write it.

  `Kati.Media.TrackedTitle.numbering` is `nil` until the reader chooses, and
  `Kati.Media.Numbering` derives the scheme from it — absolute for anime,
  seasons for everything else. Every write here goes through the control a
  reader presses and is read back from the store, never from the socket that
  pressed it.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Media.CachedEpisode
  alias Kati.Media.CachedSeason
  alias Kati.Media.CachedTitle
  alias Kati.Media.Numbering
  alias Kati.Media.TrackedTitle
  alias Kati.Screens.NumberingScheme
  alias Kati.Screens.Season

  doctest Kati.Media.Numbering
  doctest Kati.Screens.NumberingScheme

  @tables ~w(media_watches media_content_warnings tracked_titles cached_episodes cached_seasons cached_titles)

  @day 24 * 60 * 60

  setup do
    empty_the_tables!()
    on_exit(&empty_the_tables!/0)
    :ok
  end

  describe "the column" do
    test "is nil until the reader chooses, and the default follows the kind" do
      tv = track!(%{kind: :tv})
      anime = track!(%{kind: :anime})

      assert tv.numbering == nil
      assert Numbering.effective(tv) == :seasons
      assert Numbering.effective(anime) == :absolute
    end

    test "the reader's own anime tag decides the default in both directions" do
      assert Numbering.default(track!(%{kind: :anime, anime_override: false})) == :seasons
      assert Numbering.default(track!(%{kind: :tv, anime_override: true})) == :absolute
    end

    test "choosing the default clears the column; choosing the other stores it" do
      tv = track!(%{kind: :tv})

      {:ok, _} = Numbering.choose(tv, :absolute)
      assert reload(tv).numbering == :absolute

      {:ok, _} = Numbering.choose(reload(tv), :seasons)
      assert reload(tv).numbering == nil
    end

    test "a choice does not bump the shelf" do
      tv = track!(%{kind: :tv})
      {:ok, _} = Numbering.choose(tv, :absolute)

      assert reload(tv).last_touched_at == tv.last_touched_at
    end

    test "a provider's own absolute number wins over the derived one" do
      tv = track!(%{kind: :tv, season: 1})
      id = episode!(tv, %{season: 1, number: 1, title: "One", absolute: 87})

      assert Numbering.absolute_numbers_for(tv) == %{id => 87}
    end
  end

  describe "screen 34's order strip" do
    setup :seed_whole_series

    test "a tv show opens in Aired, and Absolute is written and read back", %{tracked: tracked} do
      view = mount_screen(Season)
      assert assigns(view).season.current_order == "Aired"

      {:noreply, socket} = Season.handle_tap(:order_Absolute, view.socket)
      assert socket.assigns.season.current_order == "Absolute"
      assert reload(tracked).numbering == :absolute

      again = mount_screen(Season)
      assert assigns(again).season.current_order == "Absolute"
      assert Enum.map(assigns(again).season.episodes, & &1.number) == ["E4", "E5", "E6"]

      {:noreply, _back} = Season.handle_tap(:order_Aired, again.socket)
      assert reload(tracked).numbering == nil
    end

    test "an anime opens in Absolute without anything stored", %{tracked: tracked} do
      tracked
      |> Ash.Changeset.for_update(:update, %{kind: :anime})
      |> Ash.update!()

      view = mount_screen(Season)
      assert assigns(view).season.current_order == "Absolute"

      {:noreply, _socket} = Season.handle_tap(:order_Aired, view.socket)
      assert reload(tracked).numbering == :seasons
      assert assigns(mount_screen(Season)).season.current_order == "Aired"
    end

    test "the help disc opens 153 for this show", %{tracked: tracked} do
      view = mount_screen(Season)

      {:noreply, socket} = Season.handle_tap(:explain_numbering, view.socket)

      assert socket.__mob__.nav_action ==
               {:push, NumberingScheme, %{back: "Episodes", title_id: tracked.id}}
    end

    test "coming back re-reads the stored order", %{tracked: tracked} do
      view = mount_screen(Season)
      {:ok, _} = Numbering.choose(tracked, :absolute)

      {:noreply, socket} = Season.handle_kati(:resumed, nil, view.socket)

      assert socket.assigns.season.current_order == "Absolute"
    end
  end

  describe "screen 153" do
    setup :seed_whole_series

    test "says a tv show inherits seasons because it is not anime", %{tracked: tracked} do
      words = text(tree(mount_screen(NumberingScheme, NumberingScheme.params_for(tracked.id))))

      assert words =~ "Tidewrack"
      assert words =~ "Aired"
      assert words =~ "because this is not anime"
      assert words =~ "Override"
      refute words =~ "you set this"
      refute words =~ "MyAnimeList"
    end

    test "Override writes the column, and Reset clears it", %{tracked: tracked} do
      view = mount_screen(NumberingScheme, NumberingScheme.params_for(tracked.id))

      {:noreply, overridden} = NumberingScheme.handle_tap(:override_numbering, view.socket)
      assert reload(tracked).numbering == :absolute
      assert overridden.assigns.numbering.scheme == :absolute

      words = text(tree(mount_screen(NumberingScheme, NumberingScheme.params_for(tracked.id))))
      assert words =~ "you set this · the default here is Aired"
      assert words =~ "Reset"

      {:noreply, reset} = NumberingScheme.handle_tap(:reset_numbering, overridden)
      assert reload(tracked).numbering == nil
      assert reset.assigns.numbering.chosen? == false
    end

    test "an anime inherits Absolute and says why", %{tracked: tracked} do
      tracked
      |> Ash.Changeset.for_update(:update, %{kind: :anime})
      |> Ash.update!()

      words = text(tree(mount_screen(NumberingScheme, NumberingScheme.params_for(tracked.id))))

      assert words =~ "Absolute"
      assert words =~ "because this is anime"
    end

    test "compares one of this show's own episodes", %{tracked: tracked} do
      facts = NumberingScheme.facts(tracked)

      assert facts.example == %{absolute: 4, season: 2, episode: 1}

      words = text(tree(mount_screen(NumberingScheme, NumberingScheme.params_for(tracked.id))))
      assert words =~ "E4"
      assert words =~ "S2 · E1"
      refute words =~ "E32"
    end

    test "a show no absolute number can be given draws no comparison" do
      lone = track!(%{kind: :tv, season: 1, title: "Lone"})
      episode!(lone, %{season: 1, number: 1, title: "Only"})

      assert NumberingScheme.facts(lone).example == nil

      words = text(tree(mount_screen(NumberingScheme, NumberingScheme.params_for(lone.id))))
      refute words =~ "Same episode"
    end

    test "opened without a show, it says so and offers nothing to press" do
      view = mount_screen(NumberingScheme)

      assert assigns(view).numbering == nil
      assert text(tree(view)) =~ "episode list"

      {:noreply, socket} = NumberingScheme.handle_tap(:override_numbering, view.socket)
      assert socket.assigns.numbering == nil
    end
  end

  describe "screen 04's episode numbers" do
    setup :seed_whole_series

    test "follow the show's scheme, and the tick keeps its season number", %{tracked: tracked} do
      rows = fn ->
        view = mount_screen(Kati.Screens.Series, %{id: tracked.id})
        assigns(view).series.episodes
      end

      assert Enum.map(rows.(), & &1.shown) == [1, 2, 3]

      {:ok, _} = Numbering.choose(tracked, :absolute)

      assert Enum.map(rows.(), & &1.shown) == [4, 5, 6]
      assert Enum.map(rows.(), & &1.n) == [1, 2, 3]
    end
  end

  defp seed_whole_series(_context) do
    tracked = track!(%{title: "Tidewrack", season: 2})

    season!(tracked, 1)
    season!(tracked, 2)

    for {n, title} <- [{1, "One"}, {2, "Two"}, {3, "Three"}],
        do: episode!(tracked, %{season: 1, number: n, title: title})

    episode!(tracked, %{season: 0, number: 1, title: "Marsh", special: true})

    for {n, title} <- [{1, "Four"}, {2, "Five"}, {3, "Six"}],
        do: episode!(tracked, %{season: 2, number: n, title: title})

    %{tracked: tracked}
  end

  defp track!(attrs) do
    source_id = "numbering:#{System.unique_integer([:positive])}"
    kind = attrs[:kind] || :tv

    CachedTitle
    |> Ash.Changeset.for_create(:create, %{
      source: :tmdb,
      source_id: source_id,
      kind: kind,
      title: attrs[:title],
      fetched_at: now()
    })
    |> Ash.create!()

    TrackedTitle
    |> Ash.Changeset.for_create(:create, %{
      source: :tmdb,
      source_id: source_id,
      kind: kind,
      status: :watching,
      anime_override: attrs[:anime_override],
      progress_season: attrs[:season]
    })
    |> Ash.create!()
  end

  defp season!(%TrackedTitle{} = tracked, number) do
    CachedSeason
    |> Ash.Changeset.for_create(:create, %{
      source: tracked.source,
      title_source_id: tracked.source_id,
      season_number: number,
      name: "Season #{number}",
      episode_count: 3,
      fetched_at: now()
    })
    |> Ash.create!()
  end

  defp episode!(%TrackedTitle{} = tracked, attrs) do
    source_id = "episode:#{System.unique_integer([:positive])}"

    CachedEpisode
    |> Ash.Changeset.for_create(:create, %{
      source: tracked.source,
      source_id: source_id,
      title_source_id: tracked.source_id,
      season_number: attrs[:season],
      episode_number: attrs[:number],
      absolute_number: attrs[:absolute],
      special: attrs[:special] || false,
      title: attrs[:title],
      runtime_minutes: 50,
      air_at: DateTime.add(now(), -100 * @day, :second),
      date_confidence: :exact,
      fetched_at: now()
    })
    |> Ash.create!()

    source_id
  end

  defp reload(%TrackedTitle{id: id}), do: Ash.get!(TrackedTitle, id)

  defp now, do: Kati.Time.now() |> DateTime.shift_zone!("Etc/UTC")

  defp empty_the_tables! do
    for table <- @tables,
        do: Ecto.Adapters.SQL.query!(Kati.Repo, "delete from #{table}", [])

    :ok
  end
end
