defmodule Kati.ScreenServiceTest do
  @moduledoc """
  Boards 252 and 302 — one service, and the two columns nothing could set.

  Screen 92 lists the reader's services and screen 23 adds them up. Neither
  could answer a question about **one** of them, and two columns on
  `Kati.Services.Service` were read across the app and written nowhere:

    * `paused` — `Kati.Screens.Subscriptions` greys a paused row and drops its
      rate, and `Kati.Notifications.Sources.Money` refuses to remind about a
      renewal for one. Both branches were unreachable, and worse than
      unreachable: the ledger row never even carried the column, so the styling
      fired for the drawing's services and could not fire for a reader's.
    * `renews_on` — `Kati.Subscriptions.renewal/1` prints it, screen 47 puts it
      on the money day, and the notification source fires on it. Nothing set a
      date.

  ## What this page deliberately does not draw

  Three groups both boards hold, dropped rather than drawn dead — the rule
  `Kati.Screens.SeriesSettings` states and screen 14 settled. **Cost per
  watched hour** and **hours watched** are argued against by board 252 itself:
  *"a watch records that an episode was watched, not for how long, and nothing
  maps a provider to a service."* **Shared with** would be one invented name,
  since Kati has no people table — the same absence `Kati.Screens.Rating`
  records about `commit_with/1`.

  And it displays the price without owning the editor, which is board 252's own
  instruction: screen 92's row is #119's price field, and two editors for one
  number is how two screens come to disagree about it.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Media.Watch
  alias Kati.Screens.Service, as: Page
  alias Kati.Services.Service

  @prefix "one-service-"

  setup do
    on_exit(fn ->
      Kati.Repo.query!(
        "DELETE FROM media_watches WHERE tracked_title_id IN " <>
          "(SELECT id FROM tracked_titles WHERE source_id LIKE ?1)",
        [@prefix <> "%"]
      )

      Kati.Repo.query!("DELETE FROM tracked_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
      Kati.Repo.query!("DELETE FROM cached_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
      Kati.Repo.query!("DELETE FROM services WHERE name LIKE ?1", [@prefix <> "%"])
    end)

    :ok
  end

  describe "which service the page is about" do
    test "the one it was named, and never a guess" do
      a = service!("Alpha")
      _b = service!("Beta")

      assert Page.find(a.name).id == a.id
    end

    test "a push that names none answers nothing rather than the first on the shelf" do
      service!("Alpha")

      refute Page.find(nil)

      # `Kati.ScreenWriteTargetTest`'s rule, and it applies with force here:
      # this page pauses subscriptions and takes them off a shelf.
      words = text(mount_screen(Page))

      assert words =~ "No service named"
      assert words =~ "must be told which"
    end
  end

  describe "the two columns nothing could set" do
    test "paused is a switch now, and it survives" do
      service = service!("Alpha")
      refute service.paused

      view = mount_screen(Page, %{name: service.name})
      {:noreply, paused} = Page.handle_tap(:toggle_paused, view.socket)

      assert paused.assigns.service.paused
      assert Ash.get!(Service, service.id).paused

      {:noreply, back} = Page.handle_tap(:toggle_paused, paused)
      refute back.assigns.service.paused
    end

    test "and the ledger row finally carries it, so screen 23 can grey the row" do
      service = service!("Alpha", monthly_pence: 899)

      row = Enum.find(Kati.Subscriptions.ledger().services, &(&1.name == service.name))
      refute row.paused

      Ash.update!(Ash.Changeset.for_update(service, :update, %{paused: true}))

      row = Enum.find(Kati.Subscriptions.ledger().services, &(&1.name == service.name))
      assert row.paused, "screen 23 reads `paused` off the row and the row never carried it"
    end

    test "a renewal day can be set, and it is a day rather than an instant" do
      service = service!("Alpha")
      refute service.renews_on

      view = mount_screen(Page, %{name: service.name})
      {:noreply, set} = Page.handle_tap(:cycle_day, view.socket)

      assert %Date{} = set.assigns.service.renews_on
      assert Ash.get!(Service, service.id).renews_on
    end

    test "and it wraps at 28, because nobody is billed on the 30th of February" do
      service = service!("Alpha")

      on_28 =
        Ash.update!(Ash.Changeset.for_update(service, :update, %{renews_on: ~D[2026-01-28]}))

      view =
        Page
        |> Mob.Socket.new()
        |> Mob.Socket.assign(:service, on_28)

      {:noreply, wrapped} = Page.handle_tap(:cycle_day, view)

      assert wrapped.assigns.service.renews_on.day == 1
    end
  end

  describe "the page" do
    test "shows the price and points at the screen that owns the editor" do
      service = service!("Alpha", monthly_pence: 899)

      assert Page.price_line(service) == "£8.99 a month"

      words = text(mount_screen(Page, %{name: service.name}))

      assert words =~ "£8.99 a month"
      assert words =~ "Edit it where you typed it"

      {:noreply, pushed} = Page.handle_tap(:edit_price, Mob.Socket.new(Page))
      assert {:push, Kati.Screens.MyServices, _} = Map.get(pushed.__mob__, :nav_action)
    end

    test "says so when nobody has given it a price" do
      service = service!("Alpha")

      assert Page.price_line(service) == "No price yet"
    end

    test "counts what was watched here, and never in hours" do
      service = service!("Alpha")
      tracked = shelve!()

      log!(tracked, %{service: service.name})
      log!(tracked, %{service: service.name})
      log!(tracked, %{service: "Somewhere else"})

      assert Page.watched(service) == %{logs: 2, titles: 1}

      words = text(mount_screen(Page, %{name: service.name}))

      assert words =~ "1 title on this service"
      assert words =~ "2 watches"

      # Board 252 argues its own hero figure away: a watch records that an
      # episode was watched, not for how long.
      refute words =~ "/h"
      refute words =~ "hours watched"
    end

    test "and drops the three groups no column can answer" do
      service = service!("Alpha", monthly_pence: 899)
      words = text(mount_screen(Page, %{name: service.name}))

      refute words =~ "Cost per watched hour"
      refute words =~ "Shared with"
      refute words =~ "Splits the cost"
    end

    test "removing it takes the service and leaves every watch" do
      service = service!("Alpha")
      tracked = shelve!()
      log!(tracked, %{service: service.name})

      view = mount_screen(Page, %{name: service.name})
      {:noreply, _popped} = Page.handle_tap(:remove, view.socket)

      refute Page.find(service.name)
      assert length(Ash.read!(Watch)) == 1
    end
  end

  describe "the door" do
    test "screen 23's rows open it, and the drawing's rows open nothing" do
      assert Kati.Screens.Subscriptions.service_tap(%{name: "Lumen+", live?: false}) == nil
      assert Kati.Screens.Subscriptions.service_tap(%{name: "Lumen+"}) == nil

      assert {_pid, :"open_service_Lumen+"} =
               Kati.Screens.Subscriptions.service_tap(%{name: "Lumen+", live?: true})
    end

    test "and the tap pushes the page with the service named" do
      {:noreply, pushed} =
        Kati.Screens.Subscriptions.handle_tap(
          :open_service_Alpha,
          Mob.Socket.new(Kati.Screens.Subscriptions)
        )

      assert {:push, Kati.Screens.Service, %{name: "Alpha"}} =
               Map.get(pushed.__mob__, :nav_action)
    end
  end

  defp service!(name, attrs \\ []) do
    Ash.create!(
      Service,
      Enum.into(attrs, %{name: @prefix <> name, tier: :subscribed, currency: "GBP"})
    )
  end

  defp shelve!(title \\ "Estuary Nights") do
    Ash.create!(CachedTitle, %{
      source: :tmdb,
      source_id: @prefix <> title,
      kind: :tv,
      title: title,
      fetched_at: Kati.Time.now()
    })

    Ash.create!(TrackedTitle, %{
      source: :tmdb,
      source_id: @prefix <> title,
      kind: :tv,
      status: :watching
    })
  end

  defp log!(tracked, attrs) do
    Ash.create!(
      Watch,
      Map.merge(%{tracked_title_id: tracked.id, watched_at: Kati.Time.now()}, attrs)
    )
  end
end
