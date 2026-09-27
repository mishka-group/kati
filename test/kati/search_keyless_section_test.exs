Code.require_file("../support/keyless_stubs.exs", __DIR__)

defmodule Kati.SearchKeylessSectionTest do
  @moduledoc """
  Screen 19 with no TMDB token: *On AniList* and *On TVmaze* under the
  library, and the token card under them.

  Searching *sakamoto* on a fresh install used to find nothing, because TMDB
  was the only catalogue and it needs the reader's own token. Now the same
  query goes to AniList and TVmaze, which need none: skeletons while they are
  out, their rows when they answer — TVmaze's copy of an anime AniList already
  lists left out — a preview on the row body, and the add disc adding from
  the row under the catalogue's own id. With a token saved neither is asked.

  Both catalogues are `Kati.Test.KeylessStubs`, handed to Req through their
  seams, so nothing reaches the network.
  """
  use Mob.ScreenCase, async: false

  doctest Kati.Search.Keyless

  alias Kati.Media.CachedEpisode
  alias Kati.Media.TrackedTitle
  alias Kati.Screens.Search
  alias Kati.Search.Recent
  alias Kati.Test.KeylessStubs

  @tables ~w(media_events media_watches tracked_titles cached_episodes cached_seasons cached_titles)

  setup do
    Kati.Locale.put(:en)
    Recent.forget!()
    Application.delete_env(:kati, :tmdb_test_token)
    wipe!()

    on_exit(fn ->
      KeylessStubs.restore!()
      Application.delete_env(:kati, :tmdb_test_token)
      wipe!()
    end)

    :ok
  end

  describe "no token" do
    test "AniList and TVmaze are asked, with skeletons while they are out" do
      KeylessStubs.install!()

      view = search() |> typed("sakamoto")
      drawn = texts(view)

      assert Kati.UI.eyebrow_label("On AniList") in drawn
      assert Kati.UI.eyebrow_label("On TVmaze") in drawn
      refute Kati.UI.eyebrow_label("On TMDB") in drawn
      assert skeletons(view) == 6
      assert Enum.count(drawn, &(&1 == "Add your TMDB token")) == 1

      view = settle(view)
      drawn = texts(view)

      assert skeletons(view) == 0
      assert "SAKAMOTO DAYS" in drawn
      assert "Your Name." in drawn
      assert "Sakamoto Desu ga?" in drawn

      refute "Sakamoto Days" in drawn,
             "TVmaze's copy of the anime AniList already lists was drawn twice"

      assert Enum.count(drawn, &(&1 == "Add your TMDB token")) == 1

      heading = Enum.find_index(drawn, &(&1 == Kati.UI.eyebrow_label("On AniList")))
      tvmaze = Enum.find_index(drawn, &(&1 == Kati.UI.eyebrow_label("On TVmaze")))
      hint = Enum.find_index(drawn, &(&1 == "Add your TMDB token"))

      assert heading < tvmaze and tvmaze < hint,
             "the sections are out of order: #{inspect(drawn)}"

      assert :anilist_open_0 in tap_tags(view)
      assert :anilist_add_1 in tap_tags(view)
      assert :tvmaze_open_1 in tap_tags(view)
      refute :tvmaze_open_0 in tap_tags(view)
      refute :add_0 in tap_tags(view), "a keyless row drew the TMDB section's tag"

      assert length(assigns(view).results.titles) == 0,
             "the library's own count took the catalogues' rows into it"
    end

    test "the library answers first, and a title it keeps is not listed again" do
      KeylessStubs.install!()

      view = search() |> typed("sakamoto") |> settle()
      _added = render_info(view, {:tap, :anilist_add_0})

      again = search() |> typed("sakamoto") |> settle()
      drawn = texts(again)

      assert Enum.count(drawn, &(&1 == "SAKAMOTO DAYS")) == 1
      assert [%{source: :anilist}] = assigns(again).results.titles

      local = Enum.find_index(drawn, &(&1 == "SAKAMOTO DAYS"))
      heading = Enum.find_index(drawn, &(&1 == Kati.Screens.Search.keyless_label(:anilist)))
      assert local < heading
    end

    test "an answer to a query the reader typed past is dropped" do
      KeylessStubs.install!()

      view = search() |> typed("sakamoto")
      stale = assigns(view).tmdb_epoch
      view = typed(view, "sakamoto d")

      view =
        render_info(
          view,
          {:keyless_answer, :anilist, stale, "sakamoto",
           {:ok, [hd(elem(Kati.Media.Anilist.search("sakamoto"), 1))]}}
        )

      assert assigns(view).keyless.anilist.status == :pending
      refute "SAKAMOTO DAYS" in texts(view)
    end

    test "a row body opens its preview, fetched from its own catalogue" do
      KeylessStubs.install!()

      view = search() |> typed("sakamoto") |> settle()

      opened = render_info(view, {:tap, :anilist_open_0})

      assert {:push, Kati.Screens.Series,
              %{preview: %{source: :anilist, source_id: "177709", kind: :tv}, back: "Search"}} =
               opened.socket.__mob__.nav_action

      film = render_info(view, {:tap, :anilist_open_1})

      assert {:push, Kati.Screens.Film, %{preview: %{source: :anilist, source_id: "21519"}}} =
               film.socket.__mob__.nav_action

      show = render_info(view, {:tap, :tvmaze_open_1})

      assert {:push, Kati.Screens.Series, %{preview: %{source: :tvmaze, source_id: "4444"}}} =
               show.socket.__mob__.nav_action

      assert Ash.read!(TrackedTitle) == [], "opening a preview put the title on the shelf"
    end

    test "the add disc tracks an AniList series under AniList's id, as anime, with its episodes" do
      KeylessStubs.install!()

      view = search() |> typed("sakamoto") |> settle()
      added = render_info(view, {:tap, :anilist_add_0})

      assert [tracked] = Ash.read!(TrackedTitle)
      assert tracked.source == :anilist and tracked.source_id == "177709"
      assert tracked.kind == :anime
      assert tracked.status == :not_started

      assert Enum.map(CachedEpisode.for_title(:anilist, "177709"), & &1.source_id) ==
               ["177709-1", "177709-2", "177709-3"]

      assert [%{id: id, added: true} | _rest] = assigns(added).keyless.anilist.rows
      assert id == tracked.id
      assert Recent.all() == ["sakamoto"]
      assert [%{id: ^id}] = assigns(added).results.titles

      reopened = render_info(added, {:tap, :anilist_add_0})
      assert navigated_to(reopened) == Kati.Screens.Series
    end

    test "the add disc tracks a TVmaze show with its real episodes" do
      KeylessStubs.install!()

      view = search() |> typed("sakamoto") |> settle()
      _added = render_info(view, {:tap, :tvmaze_add_1})

      assert [tracked] = Ash.read!(TrackedTitle)
      assert tracked.source == :tvmaze and tracked.source_id == "4444"
      assert tracked.kind == :anime

      assert Enum.map(CachedEpisode.for_title(:tvmaze, "4444"), & &1.title) ==
               ["The Coolest High Schooler", "Bring It On"]
    end

    test "a catalogue that fails says so in its own section, and the other still answers" do
      KeylessStubs.install!(anilist: 503)

      view = search() |> typed("sakamoto") |> settle()
      drawn = texts(view)

      assert "AniList answered 503. Nothing was saved." in drawn
      assert "Sakamoto Days" in drawn, "TVmaze's row was dropped as a copy of a row never drawn"
      assert "Sakamoto Desu ga?" in drawn
    end

    test "nothing anywhere says so in each section, and offers the title by hand" do
      KeylessStubs.install!()

      view = search() |> typed("zzqwx") |> settle()
      drawn = texts(view)

      assert "Nothing on AniList for “zzqwx”" in drawn
      assert "Nothing on TVmaze for “zzqwx”" in drawn
      assert Enum.count(drawn, &(&1 == "Add “zzqwx” by hand?")) == 1
      assert :add_by_hand in tap_tags(view)
    end

    test "both catalogues unreachable still leaves the title to add by hand" do
      KeylessStubs.install!(anilist: 503, tvmaze: 503)

      view = search() |> typed("zzqwx") |> settle()
      drawn = texts(view)

      assert "AniList answered 503. Nothing was saved." in drawn
      assert Enum.count(drawn, &(&1 == "Add “zzqwx” by hand?")) == 1
      assert :add_by_hand in tap_tags(view)
    end

    test "catalogue rows do not hide the by-hand row when the library has nothing" do
      KeylessStubs.install!()

      view = search() |> typed("sakamoto") |> settle()

      assert "SAKAMOTO DAYS" in texts(view)
      assert Enum.count(texts(view), &(&1 == "Add “sakamoto” by hand?")) == 1
    end

    test "one catalogue still out leaves no by-hand row yet" do
      KeylessStubs.install!(anilist: 503)

      view = search() |> typed("zzqwx")
      view = render_info(view, {:search_ready, "zzqwx"})
      assert_receive {:keyless_answer, :anilist, epoch, "zzqwx", result}, 5_000
      view = render_info(view, {:keyless_answer, :anilist, epoch, "zzqwx", result})

      refute :add_by_hand in tap_tags(view)
    end

    test "in Persian, the headings and a failure are Persian with the trade names kept" do
      KeylessStubs.install!(tvmaze: 429)

      drawn =
        Kati.Locale.as(:fa, fn ->
          search() |> typed("sakamoto") |> settle() |> texts()
        end)

      assert "در AniList" in drawn
      assert "در TVmaze" in drawn
      assert "TVmaze فعلاً شلوغ است. یک دقیقه دیگر دوباره امتحان کنید." in drawn
      assert "SAKAMOTO DAYS" in drawn
    end

    test "committing the query asks both at once, without waiting for the pause" do
      KeylessStubs.install!()

      view = search() |> typed("sakamoto")
      _committed = render_info(view, {:submit, :commit})

      assert_receive {:keyless_request, :anilist, {:search, "sakamoto"}}, 2_000
      assert_receive {:keyless_request, :tvmaze, {:search, "sakamoto"}}, 2_000
    end
  end

  describe "with a token" do
    test "neither AniList nor TVmaze is asked, and the page is TMDB's" do
      KeylessStubs.install!()
      Application.put_env(:kati, :tmdb_test_token, "test-token")

      view = search() |> typed("sakamoto")

      assert assigns(view).keyless.anilist.status == :idle
      assert assigns(view).keyless.tvmaze.status == :idle
      refute Kati.UI.eyebrow_label("On AniList") in texts(view)
      refute "Add your TMDB token" in texts(view)

      _committed = render_info(view, {:search_ready, "sakamoto"})
      refute_receive {:keyless_request, _source, _what}, 300
    end
  end

  defp search, do: mount_screen(Search, %{query: ""})

  defp typed(view, query), do: render_info(view, {:change, :query, query})

  defp settle(view) do
    query = String.trim(assigns(view).query)
    view = render_info(view, {:search_ready, query})

    Enum.reduce([:anilist, :tvmaze], view, fn _each, view ->
      assert_receive {:keyless_answer, source, epoch, ^query, result}, 5_000
      render_info(view, {:keyless_answer, source, epoch, query, result})
    end)
  end

  defp wipe! do
    for table <- @tables, do: Kati.Repo.query!("DELETE FROM " <> table, [])
    :ok
  end

  defp skeletons(view) do
    Enum.count(flatten(view), fn node ->
      props = Map.get(node, :props) || %{}
      node.type == :box and props[:width] == 150 and props[:height] == 13
    end)
  end

  defp tap_tags(view) do
    for node <- flatten(view),
        {_pid, tag} <- [Map.get(Map.get(node, :props) || %{}, :on_tap)],
        is_atom(tag),
        do: tag
  end

  defp texts(view) do
    view
    |> flatten()
    |> Enum.flat_map(fn node ->
      case Map.get(node, :props) || %{} do
        %{text: text} when is_binary(text) -> [text]
        _other -> []
      end
    end)
  end
end
