defmodule Kati.DeviceRoundN24N32Test do
  @moduledoc """
  Nine defects found on the device on 25 September, N24 to N32, one describe
  each.

    * **N24** — backspacing through a query filled Recent with its prefixes.
    * **N25** — a title opened from a search hit had the back pill *Library*.
    * **N26** — screen 06's *Add “X” by hand* opened 154 with the title empty.
    * **N27** — 154's note broke into three lines around its bold clause.
    * **N28** — screen 08's rating card dropped a half star.
    * **N29** — screen 19 kept listing a title removed above it.
    * **N30** — a title whose row has gone drew a hollow detail page.
    * **N31** — Stats' *Activity log* row counted differently from the log.
    * **N32** — screen 19 opened empty drew the recent queries twice.
  """

  use Mob.ScreenCase, async: false

  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Media.Watch
  alias Kati.Screens.AddByHand
  alias Kati.Screens.AddTitle
  alias Kati.Screens.Film
  alias Kati.Screens.Search
  alias Kati.Screens.Series
  alias Kati.Search.Recent

  doctest Kati.Search.Recent, only: [deleting?: 2]
  doctest Kati.Screens.Film, only: [watched: 1]

  @prefix "n24-n32-"

  setup do
    Recent.forget!()
    AddByHand.take_prefill()

    on_exit(fn ->
      for table <- ~w(media_events media_watches tracked_titles cached_titles) do
        Kati.Repo.query!("DELETE FROM " <> table, [])
      end
    end)

    :ok
  end

  describe "N24: backspacing is not searching" do
    test "deleting back through a word records none of the shorter words" do
      socket = search_socket("")

      socket =
        Enum.reduce(["ho", "hol", "holl", "hollo", "hollow"], socket, &type/2)

      Enum.reduce(["hollo", "holl", "hol", "ho"], socket, &type/2)

      assert Recent.all() == ["hollow"]
    end

    test "a shorter search typed fresh after a longer one is still its own search" do
      socket = search_socket("")
      socket = Enum.reduce(["As", "Ash", "Ashf", "Ashfall"], socket, &type/2)
      socket = type("", socket)

      Enum.reduce(["A", "As", "Ash"], socket, &type/2)

      assert Recent.all() == ["Ash", "Ashfall"]
    end

    test "backspacing then typing on to a new word records the new word" do
      socket = search_socket("")
      socket = Enum.reduce(["ho", "hol", "holl", "hollo", "hollow"], socket, &type/2)
      socket = Enum.reduce(["hollo", "holl", "hol", "ho"], socket, &type/2)

      Enum.reduce(["hou", "hous", "house"], socket, &type/2)

      assert Recent.all() == ["house", "hollow"]
    end

    test "remember/2 without a previous query records as it always did" do
      Recent.remember("Ashfall")
      Recent.remember("Ash")

      assert Recent.all() == ["Ash", "Ashfall"]
    end
  end

  describe "N25: a hit opened from search says Search on its back pill" do
    test "a film hit and a series hit both push back: Search" do
      film = shelve!("arrival", "Arrival", :movie)
      series = shelve!("severance", "Severance", :tv)

      for {tracked, query, module} <- [
            {film, "Arrival", Film},
            {series, "Severance", Series}
          ] do
        results = Kati.Search.Query.run(query)
        row = Enum.find(results.titles, &(&1.id == tracked.id))
        socket = Mob.Socket.assign(Mob.Socket.new(Search), :results, results)

        moved = Search.open_hit(socket, Search.hit_tag(row), module)

        assert moved.__mob__.nav_action == {:push, module, %{id: tracked.id, back: "Search"}}
      end
    end

    test "and the page it opens draws that word, which the vocabulary carries" do
      assert "Search" in Kati.Screens.Pushed.back_vocabulary()

      tracked = shelve!("arrival", "Arrival", :movie)
      view = mount_screen(Film, %{id: tracked.id, back: "Search"})

      assert view.socket.assigns.back == "Search"
      assert text(view) =~ "Search"
    end
  end

  describe "N26: Add “X” by hand carries X" do
    test "screen 06's row leaves the typed words for 154" do
      socket = Mob.Socket.assign(Mob.Socket.new(AddTitle), :query, "  Quiet Earth Probe ")

      {:noreply, pushed} = AddTitle.handle_info({:tap, :add_by_hand}, socket)

      assert {:push, AddByHand, _params} = pushed.__mob__.nav_action
      assert AddByHand.take_prefill() == "Quiet Earth Probe"
    end

    test "154 opens with them in its title field, as a decision the bridge takes" do
      AddByHand.prefill("Quiet Earth Probe")

      view = mount_screen(AddByHand)

      assert view.socket.assigns.title == "Quiet Earth Probe"
      assert view.socket.assigns.title_epoch == 1

      field = title_field(view)
      assert field.props.value == "Quiet Earth Probe"
      assert field.props.value_epoch == 1
    end

    test "and a bare arrival is still an empty field at epoch zero" do
      view = mount_screen(AddByHand)

      assert view.socket.assigns.title == ""
      assert title_field(view).props.value_epoch == 0
    end
  end

  describe "N27: 154's notes are one flowing sentence each" do
    test "the film note is one Text, in English and in Persian" do
      for {locale, sentence, fragment} <- [
            {:en,
             "A hand-typed title carries no poster and no episode list. If Kati finds it later both arrive, and nothing you typed is overwritten.",
             "no poster and no episode list"},
            {:fa,
             "عنوان دست‌نویس پوستر و فهرست قسمت ندارد. اگر کاتی بعداً آن را پیدا کند، هر دو می‌آیند و چیزی که نوشته‌اید دست‌نخورده می‌ماند.",
             "پوستر و فهرست قسمت ندارد"}
          ] do
        texts = Kati.Locale.as(locale, fn -> texts(mount_screen(AddByHand)) end)

        assert sentence in texts, "(#{locale}) the note is not one node: #{inspect(texts)}"
        refute fragment in texts, "(#{locale}) the bold clause is still its own node"
      end
    end

    test "the series note under the episode field is one Text too" do
      view = mount_screen(AddByHand)
      tree = AddByHand.render(Map.put(view.socket.assigns, :kind, :tv))

      assert "Without it a series still tracks, but its progress bar has no denominator — which the app already draws honestly." in texts(
               tree
             )

      refute "no denominator" in texts(tree)
    end
  end

  describe "N28: the film page draws the half star screen 33 saved" do
    test "7 points is three stars, a half and an empty one" do
      tracked = shelve!("blue-hour", "Blue Hour", :movie)
      rate!(tracked, 7)

      f = Film.film(tracked.id)
      assert f.stars == 3.5

      assert star_census(Film.rating_card(f)) == %{filled: 4, outlined: 2, halves: 1}
    end

    test "whole ratings draw no half" do
      assert star_census(Film.stars(4.0)) == %{filled: 4, outlined: 1, halves: 0}
      assert star_census(Film.stars(0)) == %{filled: 0, outlined: 5, halves: 0}
      assert star_census(Film.stars(4.5)) == %{filled: 5, outlined: 1, halves: 1}
    end

    test "screen 04's episode column prints the half rather than dropping it" do
      assert Kati.Screens.EpisodeRatings.rating_label(3.5) =~ "3.5"
    end
  end

  describe "N29: screen 19 re-reads when it is looked at again" do
    test "a title removed above the results is gone from them on the way back" do
      tracked = shelve!("quiet", "Quiet Earth", :movie)
      socket = search_socket("quiet")

      assert Enum.any?(socket.assigns.results.titles, &(&1.id == tracked.id))

      Ash.destroy!(tracked)
      socket = Mob.Socket.assign(socket, :filter, :screen)

      {:noreply, back} = Search.handle_info({:kati, :resumed, nil}, socket)

      refute Enum.any?(back.assigns.results.titles, &(&1.id == tracked.id))
      assert back.assigns.query == "quiet"
      assert back.assigns.filter == :screen
    end
  end

  describe "N30: a title that has gone says so" do
    test "screen 08 draws the sentence and a back pill, and nothing about a film" do
      view = mount_screen(Film, %{id: "no-such-row", back: "Search"})
      drawn = texts(view)

      assert "This title is no longer in your library" in drawn
      assert "Search" in drawn
      refute Enum.any?(drawn, &(&1 == Kati.Icons.glyph!("check_circle")))
      refute Enum.any?(drawn, &(&1 == Kati.Icons.glyph!("star")))
    end

    test "screen 04 draws the same page" do
      drawn = texts(mount_screen(Series, %{id: "no-such-row"}))

      assert "This title is no longer in your library" in drawn
      refute Enum.any?(drawn, &(&1 == Kati.Icons.glyph!("check_circle")))
    end

    test "in Persian too" do
      drawn = Kati.Locale.as(:fa, fn -> texts(mount_screen(Film, %{id: "no-such-row"})) end)

      assert "این عنوان دیگر در کتابخانهٔ شما نیست" in drawn
    end

    test "a film removed under an open page turns into it on the way back" do
      tracked = shelve!("gone", "Gone Girl", :movie)
      view = mount_screen(Film, %{id: tracked.id})

      refute Film.gone?(view.socket.assigns.film)

      Ash.destroy!(tracked)
      {:noreply, back} = Film.handle_info({:kati, :resumed, nil}, view.socket)

      assert Film.gone?(back.assigns.film)
    end

    test "and a second pop does not swap in the top of the shelf" do
      shelve!("other", "Other Film", :movie)
      view = mount_screen(Film, %{id: "no-such-row"})

      {:noreply, back} = Film.handle_info({:kati, :resumed, nil}, view.socket)

      assert Film.gone?(back.assigns.film)
    end

    test "an empty watched label draws no pill" do
      assert Film.watched("") == []
      assert [_pill, _gap] = Film.watched("Watched 3 Sep")
    end
  end

  describe "N31: Stats counts the activity log the way the log does" do
    test "three adds, two watches and a drop are six on both" do
      titles =
        for n <- 1..3, do: shelve!("log-#{n}", "Log #{n}", :movie)

      for tracked <- titles, do: Kati.Media.Log.write(tracked, :added, %{})
      for tracked <- Enum.take(titles, 2), do: rate!(tracked, 8)
      Kati.Media.Log.write(hd(titles), :dropped, %{})

      assert Kati.Screens.Activity.log().count == 6
      assert Kati.Screens.Stats.entries_count() == Kati.Screens.Activity.log().entries_line
      assert Kati.Screens.Stats.entries_count() =~ "6"
    end
  end

  describe "N32: screen 19 opened empty draws its history once" do
    test "the idle page has the Recent card and no chip shelf under it" do
      Recent.remember("hollow")
      socket = search_socket("")
      tree = Search.render(socket.assigns)

      assert Enum.count(texts(tree), &(&1 == "hollow")) == 1
    end

    test "the results page still carries the chip shelf" do
      Recent.remember("hollow")
      socket = search_socket("estuary")
      tree = Search.render(socket.assigns)

      assert Enum.count(texts(tree), &(&1 == "hollow")) == 1
      assert Kati.UI.eyebrow_label("Recent") in texts(tree)
    end
  end

  defp search_socket(query) do
    {:ok, socket} = Search.mount(%{query: query}, %{}, Mob.Socket.new(Search))
    socket
  end

  defp type(typed, socket) do
    {:noreply, socket} = Search.handle_info({:change, :query, typed}, socket)
    socket
  end

  defp shelve!(slug, title, kind) do
    Ash.create!(CachedTitle, %{
      source: :tmdb,
      source_id: @prefix <> slug,
      kind: kind,
      title: title,
      fetched_at: Kati.Time.now()
    })

    Ash.create!(TrackedTitle, %{
      source: :tmdb,
      source_id: @prefix <> slug,
      kind: kind,
      status: :watching
    })
  end

  defp rate!(tracked, points) do
    Ash.create!(Watch, %{
      tracked_title_id: tracked.id,
      rating: points,
      watched_on: Kati.Time.today(),
      watched_at: DateTime.truncate(Kati.Time.now(), :second)
    })
  end

  defp title_field(view) do
    view |> flatten() |> Enum.find(&(Map.get(&1.props || %{}, :accessibility_id) == "title"))
  end

  defp texts(view_or_tree) do
    view_or_tree
    |> flatten()
    |> Enum.flat_map(fn node ->
      case Map.get(node, :props) || %{} do
        %{text: text} when is_binary(text) -> [text]
        _other -> []
      end
    end)
  end

  defp star_census(tree) do
    star = Kati.Icons.glyph!("star")
    nodes = flatten(tree)
    stars = Enum.filter(nodes, &(Map.get(&1.props || %{}, :text) == star))

    %{
      filled: Enum.count(stars, &(&1.props.font_family == "symbols_filled")),
      outlined: Enum.count(stars, &(&1.props.font_family == "symbols")),
      halves: Enum.count(nodes, &(Map.get(&1.props || %{}, :clip_width) == 0.5))
    }
  end
end
