defmodule Kati.DeviceRoundN34N42Test do
  @moduledoc """
  Defects found on the device on 25 September, N34 to N42, one describe each.

    * **N34** — screen 19's note counted chips the page does not show. Held in
      `Kati.SearchGroupsTest`, beside the rest of that note's contract.
    * **N36** — a title could not be removed from its own page.
    * **N37** — a page whose title was removed underneath kept drawing it.
    * **N38** — screen 34's SPECIAL badge truncated beside a long title.
    * **N40** — Settings said *your token* over Kati's bundled key.
    * **N41** — screen 80 listed sources Kati never calls.
    * **N42** — Restore opened from Import said *Settings* on its back pill.
  """

  use Mob.ScreenCase, async: false

  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Screens.DataSources
  alias Kati.Screens.Film
  alias Kati.Screens.Season
  alias Kati.Screens.Series
  alias Kati.Screens.Settings

  doctest Kati.Screens.Settings, only: [tmdb_line: 1]

  @prefix "n34-n42-"

  setup do
    on_exit(fn ->
      for table <- ~w(media_events media_watches tracked_titles cached_titles) do
        Kati.Repo.query!("DELETE FROM " <> table, [])
      end
    end)

    :ok
  end

  describe "N36: a title is removed from its own page, after a question" do
    test "screen 08's ⋯ offers it, and the row asks before it removes" do
      tracked = shelve!("arrival", "Arrival", :movie)
      view = mount_screen(Film, %{id: tracked.id})

      menu = render_info(view, {:tap, :toggle_menu})
      assert "Remove from library" in texts(menu)
      assert drawn_tag?(menu, :confirm_remove)

      asked = render_info(menu, {:tap, :confirm_remove})
      refute assigns(asked).menu?
      assert "Remove Arrival from your library?" in texts(asked)
      assert drawn_tag?(asked, :remove_title)
      assert drawn_tag?(asked, :keep_title)
      assert {:ok, _still} = Ash.get(TrackedTitle, tracked.id)

      kept = render_info(asked, {:tap, :keep_title})
      refute "Remove Arrival from your library?" in texts(kept)
      assert {:ok, _still} = Ash.get(TrackedTitle, tracked.id)
    end

    test "and its answer removes the title and pops" do
      tracked = shelve!("dune", "Dune", :movie)
      view = mount_screen(Film, %{id: tracked.id})

      asked = render_info(view, {:tap, :confirm_remove})
      removed = render_info(asked, {:tap, :remove_title})

      assert {:error, _gone} = Ash.get(TrackedTitle, tracked.id)
      assert Map.get(removed.socket.__mob__, :nav_action) == {:pop}
    end

    test "screen 04's ⋯ offers the same row, with the same question" do
      tracked = shelve!("severance", "Severance", :tv)
      view = mount_screen(Series, %{id: tracked.id})

      menu = render_info(view, {:tap, :toggle_menu})
      assert "Remove from library" in texts(menu)

      asked = render_info(menu, {:tap, :confirm_remove})
      assert "Remove Severance from your library?" in texts(asked)
      assert {:ok, _still} = Ash.get(TrackedTitle, tracked.id)

      removed = render_info(asked, {:tap, :remove_title})
      assert {:error, _gone} = Ash.get(TrackedTitle, tracked.id)
      assert Map.get(removed.socket.__mob__, :nav_action) == {:pop}
    end

    test "the drawing offers nothing to remove" do
      view = mount_screen(Film)
      menu = render_info(view, {:tap, :toggle_menu})

      refute "Remove from library" in texts(menu)
    end

    test "in Persian, the row and the question are Persian" do
      tracked = shelve!("stalker", "Stalker", :movie)

      drawn =
        Kati.Locale.as(:fa, fn ->
          view = mount_screen(Film, %{id: tracked.id})
          menu = render_info(view, {:tap, :toggle_menu})
          asked = render_info(menu, {:tap, :confirm_remove})
          texts(menu) ++ texts(asked)
        end)

      assert "حذف از کتابخانه" in drawn
      assert "«Stalker» از کتابخانهٔ شما حذف شود؟" in drawn
      assert "تغییر می‌کند:" in drawn
      refute "Changes:" in drawn
    end
  end

  describe "N37: a title removed underneath turns into the gone page" do
    test "screen 08, with its ⋯ and its question open" do
      tracked = shelve!("gone-film", "Gone Film", :movie)
      view = mount_screen(Film, %{id: tracked.id})
      view = render_info(view, {:tap, :confirm_remove})
      view = render_info(view, {:tap, :toggle_menu})

      Ash.destroy!(tracked)
      back = render_info(view, {:kati, :resumed, nil})

      assert Film.gone?(assigns(back).film)
      refute assigns(back).menu?
      refute assigns(back).confirm_remove?
      assert "This title is no longer in your library" in texts(back)
      refute "Gone Film" in texts(back)
    end

    test "screen 04 the same" do
      tracked = shelve!("gone-series", "Gone Series", :tv)
      view = mount_screen(Series, %{id: tracked.id})
      view = render_info(view, {:tap, :toggle_menu})

      Ash.destroy!(tracked)
      back = render_info(view, {:kati, :resumed, nil})

      assert Film.gone?(assigns(back).series)
      refute assigns(back).menu?
      assert "This title is no longer in your library" in texts(back)
      refute "Gone Series" in texts(back)
    end

    test "and a title still there keeps the reader's open ⋯" do
      tracked = shelve!("still-here", "Still Here", :movie)
      view = mount_screen(Film, %{id: tracked.id})
      view = render_info(view, {:tap, :toggle_menu})

      back = render_info(view, {:kati, :resumed, nil})

      refute Film.gone?(assigns(back).film)
      assert assigns(back).menu?
    end
  end

  describe "N38: the SPECIAL badge always reads whole" do
    test "it leads the sub-line, and the title has its line to itself" do
      title = String.duplicate("A very long special episode title ", 4)

      tree =
        Season.episode_body(
          %{
            number: "S1",
            title: title,
            sub: "55 min · 29 Aug",
            badge: %{label: "SPECIAL", tone: :cream}
          },
          :on_surface,
          :on_surface
        )

      rows = Enum.filter(flatten(tree), &(&1.type == :row))
      line = fn row, text -> contains?(row, text) and not contains?(row, "S1") end

      refute Enum.any?(rows, &(line.(&1, title) and contains?(&1, "SPECIAL"))),
             "the badge shares the title's row, where a long title squeezes it to …"

      assert Enum.any?(rows, &(line.(&1, "SPECIAL") and contains?(&1, "55 min · 29 Aug")))

      sub = Enum.find(flatten(tree), &text?(&1, "55 min · 29 Aug"))
      assert sub.props[:weight] == 1.0, "the sub-line gives way, not the badge"
    end

    test "an episode with no badge draws the sub-line alone" do
      tree =
        Season.episode_body(
          %{number: "E1", title: "Pilot", sub: "48 min", badge: nil},
          :on_surface,
          :on_surface
        )

      assert Enum.any?(flatten(tree), &text?(&1, "48 min"))
      refute Enum.any?(flatten(tree), &text?(&1, "SPECIAL"))
    end
  end

  describe "N40: Settings says whose TMDB key is in force" do
    test "Kati's key chosen on a build that carries one says so, not *your token*" do
      keyed(:kati, "a-developer-token", fn ->
        assert Settings.tmdb_state() == :kati
        line = Settings.sub(%{id: "data_sources"})

        assert line == "TMDB · Kati’s key"
        refute line =~ "your token"
      end)
    end

    test "Kati's key chosen on a build without one is no key" do
      keyed(:kati, nil, fn ->
        assert Settings.tmdb_state() == :none
        assert Settings.sub(%{id: "data_sources"}) == "TMDB · no token yet"
      end)
    end

    test "the reader's own chosen, with a build key present, is not Kati's" do
      keyed(:own, "a-developer-token", fn ->
        refute Settings.tmdb_state() == :kati

        unless Kati.SecureStore.available?(),
          do: assert(Settings.sub(%{id: "data_sources"}) == "TMDB · no token yet")
      end)
    end

    test "in Persian" do
      assert Kati.Locale.as(:fa, fn -> Settings.tmdb_line(:kati) end) == "TMDB · کلید کاتی"
    end
  end

  describe "N41: screen 80 lists only the source Kati calls" do
    test "no keyless group and no connect-an-account group, and TMDB stays" do
      drawn = texts(mount_screen(DataSources))

      assert "TMDB" in drawn

      for gone <- [
            "Working out of the box",
            "TV & film · TVmaze",
            "Books · Open Library",
            "Music · MusicBrainz",
            "Connect an account",
            "ListenBrainz",
            "Hardcover",
            "TheTVDB"
          ] do
        refute gone in drawn, "screen 80 still draws #{gone}, which Kati never calls"
      end
    end

    test "nor any tap that would open or connect one" do
      view = mount_screen(DataSources)

      for tag <- [:connect_listenbrainz, :connect_thetvdb, :why_hardcover] do
        refute drawn_tag?(view, tag)
        assert render_info_tap(view, tag) == view.socket
      end
    end

    test "in Persian too" do
      drawn = Kati.Locale.as(:fa, fn -> texts(mount_screen(DataSources)) end)

      assert "TMDB" in drawn
      refute Enum.any?(drawn, &(&1 =~ "TVmaze" or &1 =~ "ListenBrainz" or &1 =~ "MusicBrainz"))
    end
  end

  describe "N42: Restore opened from Import says Import" do
    test "the backup card pushes with Import's name" do
      view = mount_screen(Kati.Screens.ImportSources)
      {:noreply, pushed} = Kati.Screens.ImportSources.handle_tap(:kati_backup, view.socket)

      assert Map.get(pushed.__mob__, :nav_action) ==
               {:push, Kati.Screens.Restore, %{back: "Import"}}
    end

    test "and the pill reads it, in both languages" do
      drawn = texts(mount_screen(Kati.Screens.Restore, %{back: "Import"}))
      assert "Import" in drawn

      fa =
        Kati.Locale.as(:fa, fn ->
          texts(mount_screen(Kati.Screens.Restore, %{back: "Import"}))
        end)

      assert Kati.Locale.as(:fa, fn -> Gettext.dgettext(Kati.Gettext, "default", "Import") end) in fa
    end
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

  defp render_info_tap(view, tag) do
    {:noreply, socket} = DataSources.handle_tap(tag, view.socket)
    socket
  end

  # The choice and the build key set on the way in and put back on the way
  # out, inside the test: `Mob.ScreenCase` restarts `Mob.State` around each
  # test, so an `on_exit/1` would find it gone.
  defp keyed(choice, build_key, fun) do
    was = %{
      choice: Mob.State.get(:kati_tmdb_key),
      read: System.get_env("TMDB_READ_TOKEN"),
      token: System.get_env("TMDB_TOKEN")
    }

    System.delete_env("TMDB_TOKEN")
    restore_env("TMDB_READ_TOKEN", build_key)
    Mob.State.put(:kati_tmdb_key, choice)

    try do
      fun.()
    after
      restore_env("TMDB_READ_TOKEN", was.read)
      restore_env("TMDB_TOKEN", was.token)

      if was.choice,
        do: Mob.State.put(:kati_tmdb_key, was.choice),
        else: Mob.State.delete(:kati_tmdb_key)
    end
  end

  defp restore_env(name, nil), do: System.delete_env(name)
  defp restore_env(name, value), do: System.put_env(name, value)

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

  defp drawn_tag?(view_or_tree, tag) do
    view_or_tree
    |> flatten()
    |> Enum.any?(fn node ->
      Enum.any?(Map.get(node, :props) || %{}, fn
        {_key, {pid, ^tag}} when is_pid(pid) -> true
        _other -> false
      end)
    end)
  end

  defp text?(node, text), do: Map.get(Map.get(node, :props) || %{}, :text) == text

  defp contains?(node, text), do: Enum.any?(flatten(node), &text?(&1, text))
end
