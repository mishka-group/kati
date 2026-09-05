Code.require_file("../support/screen_sweep.exs", __DIR__)

defmodule Kati.ConnectedPagesTest do
  @moduledoc """
  Three things a device found that no host test was asking about.

  Each was reported the same way — by using the app rather than by reading it
  — and each is the same shape: a control that names one thing and reaches
  another, or a page that answers with somebody else's facts.

    * **A search that fails silently.** Screen 06 composed the sentence that
      explains an empty result and never drew it, so a phone with no TMDB key
      answered `RESULTS 0` and said nothing. Indistinguishable from a
      catalogue with nothing in it, and the difference is what a person needs.
    * **The music segment that was not a shelf.** Screen 57's موسیقی pushed
      one album's detail page, so pressing *Music* landed on a single record
      with a back pill saying کتابخانه — reported as *when I click on the
      music tab the library tab opens*.
    * **A record's page wearing another record's history.** Screen 76 merged
      `Kati.Music.SampleFa`'s dates and totals over a real album, so a record
      typed a minute ago was last played yesterday.
  """

  use Mob.ScreenCase, async: false

  alias Kati.Music.Album
  alias Kati.Screens.AddTitle
  alias Kati.Screens.AlbumDetailFa
  alias Kati.Screens.LibraryFa

  @prefix "connected-test-"

  setup do
    on_exit(fn ->
      Kati.Repo.query!(
        "DELETE FROM music_tracks WHERE album_id IN (SELECT id FROM music_albums WHERE title LIKE ?1)",
        [@prefix <> "%"]
      )

      Kati.Repo.query!(
        "DELETE FROM music_listens WHERE album_id IN (SELECT id FROM music_albums WHERE title LIKE ?1)",
        [@prefix <> "%"]
      )

      Kati.Repo.query!("DELETE FROM music_albums WHERE title LIKE ?1", [@prefix <> "%"])
      Kati.Repo.query!("DELETE FROM music_artists WHERE name LIKE ?1", [@prefix <> "%"])
    end)

    :ok
  end

  describe "screen 06 says why a search found nothing" do
    test "the reason reaches the tree, and the tree is what a device draws" do
      # The bug was not in `search/1` — it assigned `:search_error` correctly
      # from the day it was written. It was that `render/1` never read the key,
      # so the sentence existed on the socket and nowhere a person could see.
      # Asserted on the RENDERED tree rather than on the assign, because the
      # assign was already right while the page was already silent.
      message = Kati.Media.Tmdb.message(:no_api_key)

      assert message =~ "Data sources"

      drawn =
        AddTitle
        |> mount_screen()
        |> assigns()
        |> Map.put(:search_error, message)
        |> AddTitle.render()
        |> Mob.ScreenCase.flatten()
        |> Enum.map(&Map.get(&1.props || %{}, :text))

      assert message in drawn,
             "screen 06 held the reason its search failed and drew nothing"
    end

    test "and draws no notice when there is nothing to explain" do
      quiet =
        AddTitle
        |> mount_screen()
        |> assigns()
        |> AddTitle.render()
        |> Mob.ScreenCase.flatten()
        |> Enum.map(&Map.get(&1.props || %{}, :text))

      refute Kati.Media.Tmdb.message(:no_api_key) in quiet
      assert AddTitle.search_notice(nil) == []
    end
  end

  describe "screen 57's music segment opens a shelf" do
    test "موسیقی reaches the music shelf and not one album" do
      # It pushed `Kati.Screens.AlbumDetailFa` — a page about ONE record, with
      # no list, no `+` and nothing to come back to. Screen 21 is in English
      # because no board draws a Persian music shelf, which is the trade
      # `Kati.Screens.HealthFa` already makes for screen 111 and states.
      view = render_info(mount_screen(LibraryFa), {:tap, :shelf_2})

      assert navigated_to(view) == Kati.Screens.Music,
             "the Music segment does not open the music shelf"

      refute navigated_to(view) == Kati.Screens.AlbumDetailFa
    end

    test "and the books segment still opens the books shelf" do
      # The pair is asserted together because they were one mistake made
      # twice, fixed a fortnight apart.
      view = render_info(mount_screen(LibraryFa), {:tap, :shelf_1})

      assert navigated_to(view) == Kati.Screens.BooksFa
    end
  end

  describe "screen 76 states no fact about a record that the record does not carry" do
    test "a shelved album wears none of the drawing's history" do
      {:ok, album} =
        Album
        |> Ash.Changeset.for_create(:create, %{title: @prefix <> "Tidal Works"})
        |> Ash.create()

      drawn = AlbumDetailFa.drawn()
      words = AlbumDetailFa.words(Kati.Screens.AlbumDetail.album(album.id))

      assert words.title == album.title
      assert words.id == album.id

      for {key, claim} <- [
            first_heard: drawn.first_heard,
            last_played: drawn.last_played,
            artist_line: drawn.artist_line,
            plays_line: drawn.plays_line
          ] do
        refute Map.fetch!(words, key) == claim,
               "screen 76 kept the drawing's #{key} — `#{claim}` — over a real record"

        assert Map.fetch!(words, key) == nil,
               "#{key} must be absent rather than invented: no board words it for a real row"
      end
    end

    test "and an absent line takes its own node with it, rather than drawing nil" do
      # `text={nil}` is the word **nil** on a device — see
      # `Kati.ScreenNilTextTest`. Both lines answer with nothing at all.
      assert AlbumDetailFa.second_line(nil) == []
      assert AlbumDetailFa.second_line("") == []
      refute AlbumDetailFa.second_line("۴ آلبوم") == []
    end

    test "with nothing shelved the page is still its drawing, whole" do
      # The fixture path is what `Kati.ScreenDesignLiteralTest` compares board
      # 76 against, and it must be untouched by all of the above.
      drawn = AlbumDetailFa.drawn()

      assert drawn.first_heard == "۱۳ اسفند ۱۴۰۲"
      assert drawn.last_played == "دیروز"
      assert drawn.artist_line == "۴ آلبوم · ۶۱ ساعت"
      assert drawn.plays_line == "۴۱ پخش"
    end
  end

  describe "the source cards open the sites they name" do
    test "every card and the notices row resolves to a real address" do
      # Ten controls across screens 83 and 85 were drawn, reachable and dead
      # until the `K-43 open-url` fence was built. The table is screen 83's
      # and the Persian page reads it rather than keeping a second one: the
      # licence conditions are the same conditions, and a Persian page pointing
      # somewhere else would be a licence problem rather than a copy one.
      for source <- Kati.Screens.Attribution.sources() do
        tag = String.to_atom("open_#{source.id}")
        url = Kati.Screens.Attribution.site_for(tag)

        assert is_binary(url), "#{tag} names no address"
        assert Kati.Native.Links.http?(url), "#{tag} resolves to #{inspect(url)}"

        assert String.ends_with?(url, source.site),
               "#{tag} does not open the site the card prints"
      end

      assert Kati.Native.Links.http?(Kati.Screens.Attribution.site_for(:open_notices))
      refute Kati.Screens.Attribution.site_for(:something_else)
    end

    test "a tap reaches the handler and a refusal is drawn rather than swallowed" do
      # On the host there is no bridge, so every open refuses — which is the
      # case worth pinning: the page must SAY so. Screen 06's silent search is
      # the defect this is written against.
      view = render_info(mount_screen(Kati.Screens.Attribution), {:tap, :open_tmdb})

      assert assigns(view).link_error == Kati.Native.Links.message(:no_bridge)

      drawn =
        view
        |> assigns()
        |> Kati.Screens.Attribution.content()
        |> Mob.ScreenCase.flatten()
        |> Enum.map(&Map.get(&1.props || %{}, :text))

      assert assigns(view).link_error in drawn,
             "the refusal was put on the socket and never drawn — screen 06's bug again"
    end

    test "and only http addresses are carried" do
      refute Kati.Native.Links.http?("intent://evil")
      refute Kati.Native.Links.http?("file:///etc/passwd")
      refute Kati.Native.Links.http?("https://")
      assert {:error, :unsupported_scheme} = Kati.Native.Links.open("intent://evil")
    end
  end

  describe "the settings pills reach the phone's own screens" do
    test "each pill names a destination Kati knows, and an unknown one is refused" do
      # `K-44`'s whole safety argument: a Kati word, never an Android action
      # string. `startActivity` with a caller-supplied action is a way to
      # launch anything on the device, and the strings in this app come from
      # screens.
      assert {:error, :unknown_destination} = Kati.Native.Links.settings(:anything_at_all)
      assert {:error, :unknown_destination} = Kati.Native.Links.settings("battery")

      # On a host there is no bridge, so the three real destinations refuse
      # with the honest reason rather than the unknown-word one.
      for which <- [:battery, :notification_listener, :app] do
        assert {:error, :no_bridge} = Kati.Native.Links.settings(which)
      end
    end

    test "both pills on screen 151 act, and say so when they cannot" do
      for tag <- [:open_settings, :open_settings_revoked] do
        {:noreply, socket} =
          Kati.Screens.NotificationAccess.handle_tap(
            tag,
            Mob.Socket.new(Kati.Screens.NotificationAccess)
          )

        assert socket.assigns.link_error == Kati.Native.Links.message(:no_bridge),
               "#{tag} refused silently"
      end
    end

    test "and the battery row on the diagnostic does too" do
      {:noreply, socket} =
        Kati.Screens.NotificationsHelp.handle_tap(
          :open_battery,
          Mob.Socket.new(Kati.Screens.NotificationsHelp)
        )

      assert socket.assigns.link_error == Kati.Native.Links.message(:no_bridge)
    end
  end
end
