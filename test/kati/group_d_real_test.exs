defmodule Kati.GroupDRealTest do
  @moduledoc """
  N52-D — Home's Sections row follows the sections the reader chose, empty
  Home reads no design notes, and Stats and the share card draw the reader's
  own year or an honest empty state.

  Each block writes into a transaction that is rolled back, so the store is
  exactly what the block says it is: nothing, or one watched film.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Media.Watch
  alias Kati.Screens.Home
  alias Kati.Screens.HomeEmpty
  alias Kati.Screens.Stats
  alias Kati.Screens.YearShare

  @emptied ~w(media_events media_watches media_content_warnings tracked_titles cached_episodes cached_seasons cached_titles services event_occurrence_overrides events)

  describe "Home's Sections row follows the sections the reader chose" do
    test "Screen and Books chosen: those two cards and Settings, nothing unchosen" do
      :ok = Kati.Sections.put(["screen", "books"])

      texts = with_empty_store(fn -> texts_of(tree(mount_screen(Home))) end)

      assert "Screen" in texts
      assert "Books" in texts
      assert "Settings" in texts

      for word <- ["Meals", "Habits", "Music", "Money"] do
        refute word in texts, "#{word} has a card on Home, and nobody chose it"
      end
    end

    test "every section chosen: a card for each section with a page, then Settings" do
      :ok = Kati.Sections.put(Kati.Sections.all())

      assert Enum.map(Home.tile_rows(), & &1.tag) ==
               [
                 :open_library,
                 :open_books,
                 :open_music,
                 :open_habits,
                 :open_money,
                 :open_settings
               ]
    end

    test "every card opens its section's page" do
      socket = Mob.Socket.new(Home)

      for {tag, module} <- [
            {:open_books, Kati.Screens.Books},
            {:open_music, Kati.Screens.Music},
            {:open_habits, Kati.Screens.Habits},
            {:open_money, Kati.Screens.Money}
          ] do
        {:noreply, moved} = Home.handle_tap(tag, socket)
        assert {:push, ^module, _params} = moved.__mob__.nav_action
      end
    end

    test "Screen not chosen: no Screen card" do
      :ok = Kati.Sections.put(["books"])

      assert Enum.map(Home.tile_rows(), & &1.title) == ["Books", "Settings"]
    end

    test "the Screen card opens the Library the way the dock does" do
      {:noreply, moved} = Home.handle_tap(:open_library, Mob.Socket.new(Home))

      assert {:reset, Kati.Screens.Library, _params, _how} = moved.__mob__.nav_action
    end

    test "and the Screen card is in Persian on a Persian device" do
      Kati.Locale.put(:fa)
      :ok = Kati.Sections.put(["screen"])

      assert Enum.map(Home.tile_rows(), & &1.title) == ["نمایش", "تنظیمات"]
    end
  end

  describe "Home with nothing chosen" do
    test "draws no footnote explaining the design to the reader" do
      Kati.Sections.forget!()

      texts = with_empty_store(fn -> texts_of(tree(mount_screen(Home))) end)

      assert "Nothing chosen yet" in texts
      refute Enum.any?(texts, &(&1 =~ "section-agnostic"))
      refute Enum.any?(texts, &(&1 =~ "usable before it is configured"))
      refute function_exported?(HomeEmpty, :footnote, 0)
    end
  end

  describe "Stats" do
    test "with one film watched, the year is that film's" do
      words =
        with_empty_store(fn ->
          watch_film!("Harbour", 96)
          text(tree(mount_screen(Stats)))
        end)

      assert words =~ "1h 36m"
      assert words =~ "Harbour"
      assert words =~ "1 entry"
      refute words =~ "312h 40m"
    end

    test "the grid's colours come from the ramp, not the sample" do
      assert Kati.Stats.Ramp.intensity(0) == Kati.Stats.Sample.intensity(0)
      assert Kati.Stats.Ramp.intensity(4) == Kati.Stats.Sample.intensity(4)
    end
  end

  describe "the share card" do
    test "with nothing watched it says so, and draws no zero and no drawn titles" do
      share = with_empty_store(fn -> YearShare.share() end)
      words = inspect(YearShare.card(:aspect_square, share), limit: :infinity)

      assert share.hours == nil
      assert share.subtitle == Stats.range(Kati.Time.today())
      assert words =~ "Not much to show yet"
      refute words =~ "Top titles"
      refute words =~ "The Long Hollow"
      refute words =~ "312h 40m"
    end

    test "with one film watched it carries that film" do
      share =
        with_empty_store(fn ->
          watch_film!("Harbour", 96)
          YearShare.share()
        end)

      assert share.hours.figure == "1h 36m"
      assert [%{title: "Harbour"}] = share.top
    end

    test "a render with no card read draws the empty year, never the drawing's" do
      shown = YearShare.shown(%{})

      assert shown == YearShare.empty_share()
      refute shown == YearShare.drawn_share()
    end
  end

  defp watch_film!(title, minutes) do
    source_id = "group-d:#{System.unique_integer([:positive])}"

    CachedTitle
    |> Ash.Changeset.for_create(:create, %{
      source: :tmdb,
      source_id: source_id,
      kind: :movie,
      title: title,
      runtime_minutes: minutes,
      fetched_at: Kati.Time.now()
    })
    |> Ash.create!()

    tracked =
      TrackedTitle
      |> Ash.Changeset.for_create(:create, %{
        source: :tmdb,
        source_id: source_id,
        kind: :movie,
        status: :watching
      })
      |> Ash.create!()

    Watch
    |> Ash.Changeset.for_create(:create, %{
      tracked_title_id: tracked.id,
      watched_on: Kati.Time.today(),
      watched_at: DateTime.add(Kati.Time.now(), -30 * 60, :second)
    })
    |> Ash.create!()
  end

  defp with_empty_store(fun) do
    {:error, {:rolled_back, result}} =
      Kati.Repo.transaction(fn ->
        Enum.each(@emptied, &Kati.Repo.query!("DELETE FROM #{&1}"))
        Kati.Repo.rollback({:rolled_back, fun.()})
      end)

    result
  end

  defp texts_of(tree) do
    tree
    |> find_all(:text)
    |> Enum.map(&(&1.props[:text] || ""))
    |> Enum.reject(&(&1 == ""))
  end
end
