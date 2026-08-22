defmodule Kati.ServicesTest do
  @moduledoc """
  What you pay for, what country Kati answers *available* for, and where the
  facts come from — screens 92, 94, 80 and 83.

  ## Two things this file exists to pin

    * **The money arithmetic.** Prices are pence and screens 92 and 23 both
      print them. A float here would be wrong in the third decimal place and
      then rendered, which is the expensive kind of wrong.
    * **The sentences that are legal obligations.** TMDB's notice is required
      word for word and TVmaze's CC BY-SA link *is* the licence condition.
      Both are asserted as exact strings, because an edit for tone is a licence
      change and nothing else in the repo would notice.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Screens.Attribution
  alias Kati.Screens.CountryPicker
  alias Kati.Screens.DataSources
  alias Kati.Screens.MyServices
  alias Kati.Services
  alias Kati.Services.Service
  alias Kati.Sources

  @prefix "svc-test-"

  setup do
    # Only the database needs clearing. `Mob.ScreenCase` opens `Mob.State`
    # against a throwaway data dir per test, so the region, the rules and the
    # TMDB choice start empty every time and cannot leak — and `Mob.State` is
    # already gone by the time `on_exit` runs, so resetting it here would
    # exit rather than tidy.
    on_exit(fn ->
      Kati.Repo.query!("DELETE FROM services WHERE name LIKE ?1", [@prefix <> "%"])
    end)

    :ok
  end

  defp a_service!(attrs) do
    Ash.create!(Service, Map.merge(%{name: @prefix <> "Lumen+", monthly_pence: 899}, attrs))
  end

  describe "money" do
    test "a price is pence and prints with two places always" do
      # `£9` beside `£13.99` reads as an estimate, so the minor unit is never
      # dropped even when it is zero.
      assert Service.price(%Service{monthly_pence: 899, currency: "GBP"}) == "£8.99"
      assert Service.price(%Service{monthly_pence: 900, currency: "GBP"}) == "£9.00"
      assert Service.price(%Service{monthly_pence: 5, currency: "GBP"}) == "£0.05"
      assert Service.price(%Service{monthly_pence: nil}) == nil
    end

    test "a currency with no symbol prints its code rather than guessing one" do
      assert Service.price(%Service{monthly_pence: 100, currency: "SEK"}) == "SEK 1.00"
    end

    test "the total skips services with no price rather than treating them as free" do
      services = [
        %Service{monthly_pence: 899, currency: "GBP"},
        %Service{monthly_pence: 1399, currency: "GBP"},
        %Service{monthly_pence: nil, currency: "GBP"}
      ]

      assert Service.total(services) == "£22.98"
      assert Service.total([%Service{monthly_pence: nil, currency: "GBP"}]) == nil
      assert Service.total([]) == nil
    end

    test "the badge is the name's initial unless the service says otherwise" do
      assert Service.badge(%Service{name: "Lumen+"}) == "L"
      assert Service.badge(%Service{name: "Apple TV+", badge: "+"}) == "+"
      assert Service.badge(%Service{name: "   "}) == "?"
    end
  end

  describe "the two totals screen 92 shows, and why they differ" do
    test "the three listed services add up to thirty-four pounds and change" do
      # Not the £46.47 the Money row prints. That row quotes screen 23's total
      # across the whole account, and the difference is the point — see
      # `Kati.Services.Sample.monthly_total/0`.
      pence = Enum.sum(Enum.map(Kati.Services.Sample.subscribed(), & &1.pence))

      assert pence == 3447
      assert Kati.Services.Sample.listed_total() == "£34.47"
      assert Kati.Services.Sample.monthly_total() == "£46.47"
      refute Kati.Services.Sample.listed_total() == Kati.Services.Sample.monthly_total()
    end
  end

  describe "region" do
    test "the flag is derived from the country code, never stored" do
      assert Services.flag("GB") == "🇬🇧"
      assert Services.flag("NL") == "🇳🇱"
      assert Services.flag("IR") == "🇮🇷"
      # Lower case is accepted, because a code is a code.
      assert Services.flag("gb") == "🇬🇧"
    end

    test "a code this app has no name for still gets a name and a flag" do
      assert Services.region_name("ZZ") == "ZZ"
      assert Services.flag("ZZ") == "🇿🇿"
    end

    test "the default is the region the drawings were captured in" do
      assert Services.region() == "GB"
      assert Services.region_name(Services.region()) == "United Kingdom"
    end

    test "picking a country stores it and closes the sheet" do
      view = mount_screen(CountryPicker)
      picked = render_info(view, {:tap, :pick_NL})

      assert Services.region() == "NL"
      assert navigated_to(picked) == {:pop}
    end

    test "the tick follows the stored region" do
      Services.put_region("IR")

      tree = tree(mount_screen(CountryPicker))

      assert find(tree, :text, text: "Iran") != nil
      assert find(tree, :text, text: "🇮🇷") != nil
    end
  end

  describe "availability rules" do
    test "the defaults are what a device that has never opened 92 gets" do
      assert Services.rules() == %{rentals: true, purchases: false, hide_unavailable: false}
    end

    test "each rule flips on its own and the set is stored" do
      # Asserted here rather than through the tap sweep, which cannot see a
      # write that lands in `Mob.State` — see `@inert_taps`.
      for rule <- [:rentals, :purchases, :hide_unavailable] do
        before = Map.fetch!(Services.rules(), rule)
        Services.toggle_rule(rule)
        assert Map.fetch!(Services.rules(), rule) == not before
      end
    end

    test "tapping a rule row moves the switch on the page" do
      view = mount_screen(MyServices)
      assert assigns(view).rules.hide_unavailable == false

      toggled = render_info(view, {:tap, :rule_hide_unavailable})

      assert assigns(toggled).rules.hide_unavailable == true
    end

    test "every rule row states its consequence" do
      tree = tree(mount_screen(MyServices))

      # `Hide titles I can't watch` empties three other screens, so its own
      # line names them and names what it does not touch.
      assert find(tree, :text,
               text:
                 "Removes them from Discover, Up next and What fits tonight. " <>
                   "Your library and wishlist keep everything."
             ) != nil
    end
  end

  describe "screen 92 with services stored" do
    test "the groups read the rows and the eyebrow carries the count" do
      a_service!(%{name: @prefix <> "Aria", monthly_pence: 1099})
      a_service!(%{name: @prefix <> "Beacon", monthly_pence: 499})

      assert MyServices.subscribed_label() == "Subscribed · 2"
      assert Enum.map(MyServices.subscribed(), & &1.price) == ["£10.99", "£4.99"]
    end

    test "a free service has no price rather than a price of nothing" do
      a_service!(%{name: @prefix <> "Dispatch", tier: :free_with_ads, monthly_pence: nil})

      assert [%{name: name, price: nil}] = MyServices.free()
      assert name == @prefix <> "Dispatch"
    end

    test "the settings row counts what is actually stored" do
      a_service!(%{name: @prefix <> "Aria"})

      assert [%{sub: sub}] = Kati.Settings.Sample.watching()
      assert sub == "United Kingdom · 1 subscribed"
    end

    test "the region row follows the picker" do
      Services.put_region("DE")

      assert [%{sub: sub}] = Kati.Settings.Sample.watching()
      assert sub =~ "Germany"
    end
  end

  describe "screen 92 with nothing stored" do
    test "both groups fall back to the drawing, whole" do
      assert MyServices.listed() == MyServices.drawn()
    end
  end

  describe "screen 80" do
    test "the token sentence follows the platform, not the copywriter" do
      note = Sources.token_note()

      # On the host — and on every Android build today, see #55 — there is no
      # secure store, and the page must say so. Printing the reassuring version
      # where it is false would be the most expensive sentence in the app.
      refute Kati.SecureStore.available?()
      assert note =~ "unencrypted on this device"
      assert note =~ "Kati never asks for a password"
    end

    test "the tier-2 list is only providers with revocable tokens" do
      ids = Enum.map(Sources.tier2(), & &1.id)

      assert ids == [:listenbrainz, :hardcover, :thetvdb]

      # And the ones left out say why, in code rather than only in prose.
      assert Enum.map(Sources.refused(), &elem(&1, 0)) == [:trakt, :simkl, :lastfm]
      assert Enum.all?(Sources.refused(), fn {_id, why} -> why =~ "client_secret" end)
    end

    test "nothing is connected without a token in the store" do
      refute Sources.connected?(:listenbrainz)
      assert Sources.key_for(:listenbrainz) == "source_token_listenbrainz"
    end

    test "the sheet opens with ListenBrainz explaining itself" do
      view = mount_screen(DataSources)

      assert assigns(view).expanded == :listenbrainz

      tree = tree(view)
      assert find(tree, :text, text: "Pairing — expanded") != nil
      assert find(tree, :text, text: "K4Q9B2") != nil
      # Expanding must not take the answer to *what is this for* away.
      assert find(tree, :text, text: "Scrobbles, listening history") != nil
    end

    test "tapping a connected row's provider collapses and expands it" do
      view = mount_screen(DataSources)

      collapsed = render_info(view, {:tap, :connect_listenbrainz})
      assert assigns(collapsed).expanded == nil

      other = render_info(view, {:tap, :connect_hardcover})
      assert assigns(other).expanded == :hardcover
    end

    test "the TMDB choice is two working configurations, not an on and an off" do
      assert Sources.tmdb_key() == :kati

      Sources.put_tmdb_key(:own)
      assert Sources.tmdb_key() == :own

      Sources.put_tmdb_key(:kati)
      assert Sources.tmdb_key() == :kati
    end

    test "an empty cache says so rather than reporting nought megabytes" do
      assert DataSources.cache_size() == "Nothing cached yet"
      assert DataSources.oldest_entry() == "NOTHING TO REFRESH"
    end

    test "an age is written in the units the row uses" do
      assert DataSources.age(0) == "TODAY"
      assert DataSources.age(1) == "1 DAY"
      assert DataSources.age(9) == "9 DAYS"
      assert DataSources.age(30) == "30 DAYS"
      assert DataSources.age(60) == "2 MONTHS"
      assert DataSources.age(31) == "1 MONTH"
    end

    test "the database size never rounds down to nothing" do
      # A cache with something in it that reported `0 MB` would read as empty,
      # which is the one thing it is not.
      assert DataSources.database_megabytes() >= 1
    end
  end

  describe "screen 83, the obligations" do
    test "TMDB's sentence is quoted verbatim" do
      # Required word for word by TMDB's terms. Editing this for tone is a
      # licence change, and nothing else in the repo would notice.
      tmdb = Enum.find(Attribution.sources(), &(&1.id == :tmdb))

      assert tmdb.notice ==
               "This product uses the TMDB API but is not endorsed or certified by TMDB."
    end

    test "TVmaze's link is carried as the licence condition it is" do
      tvmaze = Enum.find(Attribution.sources(), &(&1.id == :tvmaze))

      assert tvmaze.licence == "CC BY-SA"
      assert tvmaze.notice =~ "this link is the licence condition"
      assert tvmaze.site == "tvmaze.com"
    end

    test "every source carries a notice, a site and something Kati takes from it" do
      for source <- Attribution.sources() do
        assert is_binary(source.notice) and source.notice != ""
        assert is_binary(source.site) and source.site != ""
        assert is_binary(source.takes) and source.takes != ""
      end
    end

    test "the page names the non-commercial constraint rather than hiding it" do
      tree = tree(mount_screen(Attribution))

      assert find(tree, :text,
               text:
                 "Kati is free, has no ads and sells nothing inside itself. That is what " <>
                   "keeps it inside TMDB’s and Last.fm’s non-commercial terms — a constraint " <>
                   "worth naming, not hiding."
             ) != nil
    end

    test "the notices list is described as generated, because it is" do
      assert File.exists?("THIRD_PARTY_NOTICES.md"),
             "screen 83 tells the user this file is generated at build time. If it does not " <>
               "exist, the page is claiming a provenance the repo cannot back."
    end

    test "the marks are slots, never recoloured logos" do
      # Most of these licences forbid modification of the mark. Until real
      # assets land, each source draws its own initial on paper.
      tree = tree(mount_screen(Attribution))

      for source <- Attribution.sources() do
        initial = source.name |> String.first() |> String.upcase()
        assert find(tree, :text, text: initial) != nil
      end
    end
  end

  describe "the four screens render" do
    test "each one draws a tree the native layer can take" do
      for module <- [MyServices, CountryPicker, DataSources, Attribution] do
        assert_renderable(mount_screen(module))
      end
    end
  end
end
