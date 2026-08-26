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
      assert MyServices.subscribed_label() == "Subscribed · 1"

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

    test "the placeholder is still the drawing's, so 92's copy is unchanged" do
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
