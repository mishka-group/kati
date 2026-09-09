defmodule Kati.ServiceWriteTest do
  @moduledoc """
  #95 — a service you pay for can be put into Kati.

  `Kati.Services.Service` shipped with `create: :*` and nothing in `lib/` ever
  called it. Screen 92 read the table on every render, found it empty on every
  device, and drew `Kati.Services.Sample`'s three — so the page that decides what
  *available* means everywhere else in the app was a picture of somebody else's
  subscriptions, and there was no way to make it yours.

  The door is the one the design draws: 92.html's `Something else` row, whose own
  sub-line promises *Kati will remember it for your subscription total*. This
  file is that promise, asked of the store rather than of the socket.
  """

  use Mob.ScreenCase, async: false

  alias Kati.Screens.MyServices
  alias Kati.Services.Service

  @prefix "svcwrite-"

  setup do
    # BOTH sides. `Kati.ScreenEmptyDatabaseTest` renders screen 92 against a
    # database it has asserted is empty, and `Kati.ScreenDesignLiteralTest`
    # renders it expecting the drawing's `Lumen+ £8.99` — one service row left
    # behind by this file takes the fallback away from both, for whatever
    # `--seed` happens to order them after it. An order-dependent suite has been
    # found here twice; cleaning only on the way in is how it happens the third.
    wipe = fn ->
      Kati.Repo.query!("DELETE FROM services WHERE name LIKE ?1", [@prefix <> "%"])
    end

    wipe.()
    on_exit(wipe)
    :ok
  end

  # What the device does, in order: type into the field, then tap the row.
  defp add(view, name) do
    view
    |> render_info({:change, :service_query, name})
    |> render_info({:tap, :add_service})
  end

  defp stored(name) do
    Enum.find(mine(), &(&1.name == name))
  end

  # Only this file's rows. The suite shares one SQLite file and several files
  # write services into it; a count over the whole table would be a claim about
  # what everything else left behind.
  defp mine do
    Service |> Ash.read!() |> Enum.filter(&String.starts_with?(&1.name, @prefix))
  end

  # A store the screen cannot write to, for the length of one tap. `after`
  # rather than `on_exit`: the table has to come back before anything else in
  # this file reads it, and a failed assertion inside `fun` must not leave the
  # rest of the suite without a `services` table. This module is `async: false`,
  # so no other test is reading the file while the table is away.
  defp without_the_services_table(fun) do
    Kati.Repo.query!("ALTER TABLE services RENAME TO services_away")

    try do
      fun.()
    after
      Kati.Repo.query!("ALTER TABLE services_away RENAME TO services")
    end
  end

  describe "Something else" do
    test "writes the row, and it is there on a fresh read" do
      view = mount_screen(MyServices)
      name = @prefix <> "Mubi"

      assert stored(name) == nil

      view = add(view, name)

      # The receipt is the store. Read back through Ash rather than through the
      # socket the tap returned, because a value still in an assign has proved
      # nothing about a table.
      service = stored(name)

      assert service != nil, "the row never reached the store"
      assert service.name == name

      assert service.tier == :subscribed,
             "the row's own sub-line promises a subscription total, and only " <>
               ":subscribed is counted towards one"

      assert service.provider_id == nil,
             "a service the user typed has no provider id, and inventing one " <>
               "would make the row unreconcilable the day JustWatch does list it"

      assert service.monthly_pence == nil,
             "no price field is drawn for this row — a figure here would be one " <>
               "nobody typed"

      # And it is on the page, under the name that was typed, through the
      # screen's own reader rather than a query written for the test.
      assert Enum.any?(MyServices.subscribed(), &(&1.name == name))
      assert MyServices.subscribed_label(MyServices.listed()) == "Subscribed · 1"

      # The field is empty again and nothing is being reported.
      assert assigns(view).query == ""
      assert assigns(view).save_error == nil
    end

    test "the service reaches screen 92 with no price rather than a price of nothing" do
      name = @prefix <> "Nebula"

      MyServices |> mount_screen() |> add(name)

      assert [%{name: ^name, price: nil, pence: nil}] = MyServices.subscribed()
    end
  end

  describe "a save that cannot land" do
    test "an empty field writes nothing and says so" do
      view = mount_screen(MyServices)

      view = render_info(view, {:tap, :add_service})

      assert mine() == [], "a row was written from an empty field"

      assert assigns(view).save_error == "Nothing to save yet.",
             "the tap did nothing and reported nothing, which is the exact shape #85 " <>
               "exists to forbid"
    end

    test "a field holding only spaces is the same refusal, not a service called nothing" do
      view = mount_screen(MyServices)

      view = add(view, "   ")

      assert mine() == []
      assert assigns(view).save_error == "Nothing to save yet."
    end

    test "the refusal keeps the typed name and puts the message on the page" do
      view = mount_screen(MyServices)

      # Nothing typed, so nothing to lose — then type, which must clear the
      # notice rather than leave a stale one over a field that now has a name
      # in it.
      view = render_info(view, {:tap, :add_service})
      assert find(tree(view), :text, text: "Nothing to save yet.") != nil

      view = render_info(view, {:change, :service_query, @prefix <> "Mubi"})
      assert assigns(view).query == @prefix <> "Mubi"

      # Asserted HERE, on the typing, and not after the tap below. After the tap
      # it proves nothing: a save that lands clears `:save_error` on its own, so
      # the same two assertions pass over a screen that left the red line under
      # a field holding `Mubi` for as long as the person took to reach the row.
      # They did pass over exactly that.
      assert assigns(view).save_error == nil,
             "the notice about the empty field outlived the empty field"

      assert find(tree(view), :text, text: "Nothing to save yet.") == nil

      view = render_info(view, {:tap, :add_service})

      assert assigns(view).save_error == nil
      assert find(tree(view), :text, text: "Nothing to save yet.") == nil
    end

    test "a store that refuses the write reports it and keeps the name" do
      view = mount_screen(MyServices)
      view = render_info(view, {:change, :service_query, @prefix <> "Nebula"})

      # The only failure this screen can be made to have, and the one the tests
      # above cannot reach: `:nothing_to_save` is a guard in front of the store,
      # so nothing else here ever exercises an `{:error, _}` coming BACK from
      # `Ash.create/2`. Taking the table away is that, at the only seam a host
      # test has. It also pins the sentence: Ash carries this one as
      # `"** (Exqlite.Error) no such table: services\nINSERT INTO ..."`, and
      # `Kati.Write.message/1` must not put that on a phone.
      view = without_the_services_table(fn -> render_info(view, {:tap, :add_service}) end)

      assert assigns(view).save_error ==
               "That did not save. Your text is still here — try again."

      assert find(tree(view), :text, text: assigns(view).save_error) != nil,
             "the message reached an assign and no node — the #85 defect with the " <>
               "reporting half missing"

      assert assigns(view).query == @prefix <> "Nebula",
             "the failure took the typed name with it, so there is nothing to try again with"

      assert mine() == []
    end
  end

  describe "a price typed after the name" do
    test "is stored, so the total is a total" do
      view = mount_screen(MyServices)
      view = render_info(view, {:change, :service_query, "svcwrite-Netflix 10.99"})
      _view = render_info(view, {:tap, :add_service})

      assert [%{name: "svcwrite-Netflix", monthly_pence: 1099}] =
               Ash.read!(Service) |> Enum.filter(&String.starts_with?(&1.name, "svcwrite-"))
    end

    test "and a name with a number in it is still a name" do
      view = mount_screen(MyServices)
      view = render_info(view, {:change, :service_query, "svcwrite-Apple TV+ 4K"})
      _view = render_info(view, {:tap, :add_service})

      assert [%{name: "svcwrite-Apple TV+ 4K", monthly_pence: nil}] =
               Ash.read!(Service) |> Enum.filter(&String.starts_with?(&1.name, "svcwrite-"))
    end

    test "and screen 23's total adds them up" do
      view = mount_screen(MyServices)
      view = render_info(view, {:change, :service_query, "svcwrite-Netflix 10.99"})
      _view = render_info(view, {:tap, :add_service})

      assert Kati.Subscriptions.ledger().monthly.total == "£10.99"
    end
  end

  describe "the page after the write" do
    test "lists the service that was just added, without leaving the screen" do
      view = mount_screen(MyServices)
      view = render_info(view, {:change, :service_query, "svcwrite-Cinepop"})
      view = render_info(view, {:tap, :add_service})

      assert find(tree(view), :text, text: "svcwrite-Cinepop") != nil,
             "the row was written and the page went on drawing the list it had at mount"
    end

    test "and the Not mine row counts it" do
      view = mount_screen(MyServices)
      view = render_info(view, {:change, :service_query, "svcwrite-Cinepop"})
      view = render_info(view, {:tap, :add_service})

      assert find(tree(view), :text, text: "Kati lists 1 service") != nil
      assert find(tree(view), :text, text: "Show all 47") == nil
    end
  end

  describe "the row that changed" do
    test "adding a third service leaves the two already listed exactly as they were" do
      first = Ash.create!(Service, %{name: @prefix <> "Aria", monthly_pence: 1099})
      second = Ash.create!(Service, %{name: @prefix <> "Beacon", monthly_pence: 499})

      MyServices |> mount_screen() |> add(@prefix <> "Mubi")

      after_first = stored(@prefix <> "Aria")
      after_second = stored(@prefix <> "Beacon")

      assert after_first.id == first.id
      assert after_first.monthly_pence == 1099
      assert after_first.updated_at == first.updated_at

      assert after_second.id == second.id
      assert after_second.monthly_pence == 499
      assert after_second.updated_at == second.updated_at

      assert length(mine()) == 3

      assert stored(@prefix <> "Mubi").id not in [first.id, second.id],
             "the write landed on a row that already existed instead of making one"
    end

    test "with two listed, re-adding the SECOND answers with that one and writes nothing" do
      first = Ash.create!(Service, %{name: @prefix <> "Aria", monthly_pence: 1099})
      second = Ash.create!(Service, %{name: @prefix <> "Beacon", monthly_pence: 499})

      # The test above it has one row in the store, so it cannot tell "found the
      # service you named" from "found the only service there is" — and
      # `already_listed/1` scans the whole table, so which row it picks is a
      # real question. Named in the second's case, it must answer with the
      # second and leave the first alone.
      view = mount_screen(MyServices)
      view = add(view, String.upcase(@prefix <> "Beacon"))

      assert {:ok, answered} = MyServices.save_service(@prefix <> "beacon")
      assert answered.id == second.id, "the check answered with the wrong row"

      assert length(mine()) == 2, "a duplicate of the second service was written"

      assert stored(@prefix <> "Aria").updated_at == first.updated_at
      assert stored(@prefix <> "Aria").monthly_pence == 1099
      assert stored(@prefix <> "Beacon").updated_at == second.updated_at
      assert stored(@prefix <> "Beacon").monthly_pence == 499

      assert assigns(view).save_error == nil
    end

    test "a name already listed is not written twice, whatever its case" do
      view = mount_screen(MyServices)

      view = add(view, @prefix <> "Mubi")
      view = add(view, @prefix <> "Mubi")
      view = add(view, String.upcase(@prefix <> "Mubi"))

      assert length(mine()) == 1,
             "re-adding a service you already have doubled it, and — the day a " <>
               "price editor exists — would charge you twice for one subscription"

      assert assigns(view).save_error == nil,
             "already having it is not a failure to report"
    end

    test "already_listed/1 ignores case and surrounding space, and nothing else" do
      Ash.create!(Service, %{name: @prefix <> "Mubi"})

      assert MyServices.already_listed(@prefix <> "mubi") != nil
      assert MyServices.already_listed(String.upcase(@prefix <> "Mubi")) != nil
      assert MyServices.already_listed(@prefix <> "Mubi Plus") == nil
    end
  end

  describe "the field that used to type and filter nothing" do
    test "narrows both groups, and the count with them" do
      # MOVIES-AND-TV.md #118: `content/1` passed `query` to `search_field/1`
      # and to nobody else, so a reader searching a list of twelve watched all
      # twelve stay put.
      view = mount_screen(MyServices)
      view = add(view, @prefix <> "Mubi 10.99")
      view = add(view, @prefix <> "Kino 11.49")

      narrowed = render_info(view, {:change, :service_query, "mubi"})
      drawn = text(narrowed)

      assert drawn =~ "Mubi"
      refute drawn =~ "Kino"

      # The eyebrow counts what is under it. A count that stayed at the
      # unfiltered number would be the heading disagreeing with its own rows.
      # Asked of the label rather than of the drawn string, which `UI.eyebrow/1`
      # upper-cases.
      assert MyServices.subscribed_label(assigns(narrowed).services) == "Subscribed · 2"

      assert MyServices.matching(assigns(narrowed).services, "mubi")
             |> MyServices.subscribed_label() == "Subscribed · 1"
    end

    test "and a name nothing answers to gets board 95's own sentence" do
      view = mount_screen(MyServices)
      view = add(view, @prefix <> "Mubi 10.99")

      drawn = text(render_info(view, {:change, :service_query, "mubi plus"}))

      assert drawn =~ "No service called that"

      assert drawn =~ "Something else",
             "the answer names the way out and the way out is the next row"

      # And NOT the empty-group card. *No subscriptions yet* over a reader who
      # has one, because they typed a word that matches none of them, is the
      # misreading #117 fixed on the search screen — found on the Pixel_9a,
      # where the card pushed the true answer below the fold.
      refute drawn =~ "No subscriptions yet"

      assert assigns(view).services
             |> MyServices.matching("mubi plus")
             |> MyServices.subscribed_label("mubi plus") == "Subscribed · 0"
    end

    test "and an empty field says nothing at all" do
      view = mount_screen(MyServices)
      view = add(view, @prefix <> "Mubi 10.99")

      refute text(render_info(view, {:change, :service_query, ""})) =~ "No service called that"
    end
  end

  describe "a service you no longer have" do
    test "the switch moves it to Not mine rather than deleting it" do
      # MOVIES-AND-TV.md #119: once *Something else* wrote a row you were stuck
      # with it — every service row tapped a handler that returned the socket
      # unchanged. Board 95 specifies the switch and this is it.
      view = mount_screen(MyServices)
      view = add(view, @prefix <> "Mubi 10.99")

      service = stored(@prefix <> "Mubi")
      assert service.tier == :subscribed

      dropped = render_info(view, {:tap, MyServices.drop_tag(%{id: service.id})})

      assert stored(@prefix <> "Mubi").tier == :not_mine,
             "a service you cancelled is not one you never had"

      refute text(dropped) =~ @prefix <> "Mubi",
             "the row is still on the page it was taken off"
    end

    test "and typing its name again puts it back" do
      # Found on the Pixel_9a: re-adding a service switched off answered
      # `{:ok, existing}` and wrote nothing, so the save reported success and
      # the row stayed under *Not mine* — a control that looks broken.
      view = mount_screen(MyServices)
      view = add(view, @prefix <> "Mubi 10.99")

      service = stored(@prefix <> "Mubi")
      view = render_info(view, {:tap, MyServices.drop_tag(%{id: service.id})})
      assert stored(@prefix <> "Mubi").tier == :not_mine

      back = add(view, @prefix <> "Mubi")

      assert stored(@prefix <> "Mubi").tier == :subscribed
      assert text(back) =~ @prefix <> "Mubi"

      # And the price it had is not blanked by a bare name.
      assert stored(@prefix <> "Mubi").monthly_pence == 1099
    end

    test "and a free service is not promoted by re-typing its name" do
      # `:free_with_ads` is a tier the reader chose.
      Ash.create!(Service, %{name: @prefix <> "Aria", tier: :free_with_ads})

      view = mount_screen(MyServices)
      add(view, @prefix <> "Aria")

      assert stored(@prefix <> "Aria").tier == :free_with_ads
    end

    test "and the switch is not drawn over a row that is only a drawing" do
      drawn = inspect(MyServices.mine_switch(%{name: "Lumen+"}), limit: :infinity)

      refute drawn =~ "drop_service"
    end
  end

  describe "a price that was typed wrong" do
    test "the row puts the line back in the field it was typed in" do
      view = mount_screen(MyServices)
      view = add(view, @prefix <> "Mubi 10.99")

      # `service_tag/1` replaces spaces with underscores, so the tag carries
      # the shaped name and `by_tag/2` resolves it against the very list the
      # rows were drawn from.
      tag = MyServices.service_tag(%{name: @prefix <> "Mubi"})
      "edit_service_" <> tagged = Atom.to_string(tag)

      refilled = render_info(view, {:tap, tag})

      assert assigns(refilled).query == @prefix <> "Mubi 10.99"

      # And the row the reader is editing is still on the page. One field does
      # two jobs here, and on the Pixel_9a they collided: `Mubi 9.99` matched
      # no service called *Mubi 9.99*, so the page emptied and said **No
      # service called that** about the row that had just been tapped.
      drawn = text(refilled)
      assert drawn =~ @prefix <> "Mubi"
      refute drawn =~ "No service called that"
      assert MyServices.by_tag(assigns(refilled).services, tagged).name == @prefix <> "Mubi"

      # And saving the corrected line changes the price rather than adding a
      # second Mubi.
      corrected =
        refilled
        |> render_info({:change, :service_query, @prefix <> "Mubi 12.99"})
        |> render_info({:tap, :add_service})

      assert length(Enum.filter(mine(), &(&1.name == @prefix <> "Mubi"))) == 1
      assert text(corrected) =~ "12.99"

      # And the field is actually empty afterwards, not just in the assign.
      # `K-46`: the bridge ignores a `value` for a field it has already drawn
      # unless the epoch moves — found on the Pixel_9a, where the price saved
      # and the line stayed sitting in the box.
      assert assigns(corrected).query == ""
      assert assigns(corrected).query_epoch > assigns(refilled).query_epoch
    end

    test "and a service with no price comes back as a bare name" do
      view = mount_screen(MyServices)
      view = add(view, @prefix <> "Aria")

      refilled = render_info(view, {:tap, MyServices.service_tag(%{name: @prefix <> "Aria"})})

      assert assigns(refilled).query == @prefix <> "Aria"
    end
  end

  describe "the field the name comes from" do
    test "screen 92 draws one that can be typed into, and holds what was typed" do
      view = mount_screen(MyServices)

      assert find(tree(view), :text_field, accessibility_id: "service_query") != nil

      view = render_info(view, {:change, :service_query, "mubi plus"})

      assert assigns(view).query == "mubi plus"

      assert find(tree(view), :text_field, value: "mubi plus") != nil,
             "the field did not echo what was typed, so the name about to be " <>
               "saved is not the one on screen"
    end

    test "the placeholder asks for a name while there is nothing to search" do
      # `Search services` is board 92's word and the right one on a page with
      # services on it. On a page with none it is a dead end — there is
      # nothing to search, and this field is in fact how the first one gets
      # named. Same control, same tap; the sentence the page is actually in.
      view = mount_screen(MyServices)

      assert find(tree(view), :text_field, placeholder: "Name a service, and what it costs") !=
               nil

      assert find(tree(view), :text_field, placeholder: "Search services") == nil
    end

    test "and goes back to the drawing's word once a service is listed" do
      Ash.create!(Service, %{name: "svcwrite-Mubi", tier: :subscribed, monthly_pence: 899})

      view = mount_screen(MyServices)

      assert find(tree(view), :text_field, placeholder: "Search services") != nil
    end

    test "screen 93 keeps the drawn field, because it draws no row to add from" do
      # `Kati.Screens.MyServicesEmpty` calls `search_field/0`. It is the board
      # with nothing set up and 93.html has no `Something else` row on it, so a
      # field you could type into there would take a name and have nowhere to
      # put it.
      tree = MyServices.search_field()

      assert find(tree, :text_field) == nil
      assert find(tree, :text, text: "Search services") != nil
    end
  end
end
