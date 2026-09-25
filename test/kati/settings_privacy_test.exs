defmodule Kati.SettingsPrivacyTest do
  @moduledoc """
  Settings' Privacy row opens a privacy page, the Reorder row is gone, and no
  settings chevron promises a page it does not open.

  The page's sentences are claims about the code, so the last describe block
  holds the one that can drift without anybody touching the page: *no other
  service is contacted*. It lists the modules that make HTTP requests, and a
  new one fails here until the page says where it goes.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Screens.Privacy
  alias Kati.Screens.Settings
  alias Kati.Settings.Sample

  setup do
    installed = Mob.Theme.current()
    on_exit(fn -> Mob.Theme.set(installed) end)
    Kati.Locale.put(:en)
    :ok
  end

  describe "the Privacy row" do
    test "carries a tap and opens the privacy page" do
      row = Enum.find(Sample.about(), &(&1.id == "privacy"))
      assert {_pid, :go_privacy} = Settings.tap_for(row)

      view = render_info(mount_screen(Settings), {:tap, :go_privacy})
      assert navigated_to(view) == Privacy
    end

    test "the tag is on the rendered tree, in both locales" do
      for locale <- [:en, :fa] do
        taps = as(locale, fn -> taps(mount_screen(Settings)) end)
        assert :go_privacy in taps, "screen 24 under #{locale} draws no Privacy tap"
      end
    end

    test "no longer claims that nothing leaves the device" do
      en = texts(mount_screen(Settings))
      refute "Nothing leaves the device" in en
      assert "No account, no server, no analytics" in en

      fa = as(:fa, fn -> texts(mount_screen(Settings)) end)
      assert "بدون حساب، بدون سرور، بدون آمارگیری" in fa
    end
  end

  describe "the Reorder sections row" do
    test "is gone from the data and from both screens" do
      refute Enum.any?(Sample.sections(), &(&1.id == "reorder_sections"))

      en = texts(mount_screen(Settings))
      refute "Reorder sections" in en
      refute "Drag to change home order" in en

      refute Map.has_key?(Settings.destinations(), "reorder_sections")
    end

    test "the store it would have needed keeps no order" do
      Kati.Sections.put(~w(money screen))

      try do
        assert Kati.Sections.chosen() == ~w(screen money)
      after
        Kati.Sections.forget!()
      end
    end
  end

  describe "every chevron on screen 24" do
    test "is drawn only on a row that opens something" do
      chevron = Kati.UI.SettingsList.chevron()

      rows =
        Sample.appearance() ++
          Sample.watching() ++
          Sample.sections() ++ Sample.data() ++ Sample.sources() ++ Sample.about()

      for row <- rows, row.control == :chevron do
        drawn? = contains?(Settings.row(row, 14, false), chevron)
        opens? = Settings.tap_for(row) != nil

        assert drawn? == opens?,
               "#{row.id}: chevron drawn #{drawn?}, destination #{opens?}"
      end
    end

    test "Version is the one row that states a value and opens nothing" do
      version = Enum.find(Sample.about(), &(&1.id == "version"))
      assert Settings.tap_for(version) == nil
      refute contains?(Settings.row(version, 14, false), Kati.UI.SettingsList.chevron())
    end
  end

  describe "the privacy page" do
    test "draws its statements in English and in Persian, and taps nothing but back" do
      en = mount_screen(Privacy)

      for line <- [
            "Privacy",
            "No account",
            "No analytics",
            "Your data",
            "Film and series data",
            "Backups",
            Kati.Sources.token_note()
          ] do
        assert line in texts(en), "the privacy page does not draw #{line}"
      end

      assert taps(en) == [:back]

      fa = as(:fa, fn -> texts(mount_screen(Privacy)) end)

      for line <- ["حریم خصوصی", "بدون حساب", "بدون آمارگیری", "داده‌های شما", "پشتیبان‌ها"] do
        assert line in fa, "the Persian privacy page does not draw #{line}"
      end

      refute "No account" in fa
    end

    test "its back pill says Settings" do
      assert "Settings" in texts(mount_screen(Privacy))
    end
  end

  describe "what the page claims about the network" do
    # Written out, not derived: this list is the page's claim, and the test is
    # that the code still matches it.
    @http_callers MapSet.new([
                    "lib/kati/media/tmdb.ex",
                    "lib/kati/media/artwork.ex",
                    "lib/kati/sync/adapter/caldav/transport.ex"
                  ])

    test "TMDB's two modules and the undriven CalDAV transport are the only HTTP callers" do
      callers =
        for path <- Path.wildcard("lib/**/*.ex"),
            File.read!(path) =~ ~r/\bReq\.(get|post|put|patch|delete|head|request|new)\b/,
            into: MapSet.new(),
            do: path

      assert callers == @http_callers,
             "the privacy page says TMDB is the only service Kati contacts; " <>
               "update Kati.Screens.Privacy for #{inspect(MapSet.difference(callers, @http_callers) |> MapSet.to_list())}"
    end

    test "the two TMDB modules talk to TMDB's hosts" do
      assert File.read!("lib/kati/media/tmdb.ex") =~ ~s(@host "https://api.themoviedb.org/3")
      assert File.read!("lib/kati/media/artwork.ex") =~ ~s(@host "https://image.tmdb.org/t/p")
    end

    test "nothing in the app drives a sync, so the CalDAV transport sends nothing" do
      drivers =
        for path <- Path.wildcard("lib/**/*.ex"),
            path != "lib/kati/sync/engine.ex",
            File.read!(path) =~ ~r/Engine\.sync\(/,
            do: path

      assert drivers == [],
             "#{inspect(drivers)} now runs a sync; the privacy page must name the calendar server"
    end
  end

  defp as(locale, fun) do
    Kati.Locale.put(locale)

    try do
      fun.()
    after
      Kati.Locale.put(:en)
    end
  end

  defp texts(view) do
    for node <- flatten(view),
        text = (Map.get(node, :props) || %{})[:text],
        is_binary(text),
        do: text
  end

  defp taps(view) do
    for node <- flatten(view),
        {_pid, tag} <- [(Map.get(node, :props) || %{})[:on_tap]],
        do: tag
  end

  defp contains?(tree, node), do: node in flatten(tree)
end
