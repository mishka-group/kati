defmodule Kati.ServiceWriteTest do
  @moduledoc """
  #95 — a service you pay for can be put into Kati, and corrected, and taken
  out again.

  The door is screen 92's add card: a name, paid or free with ads, a price
  for a paid one, and *Add service*. Any name is accepted — a service TMDB
  lists or one it has never heard of. This file asks the store, not the socket,
  whether each promise was kept.
  """

  use Mob.ScreenCase, async: false

  alias Kati.Screens.MyServices
  alias Kati.Services.Service

  @prefix "svcwrite-"

  setup do
    # BOTH sides. `Kati.ScreenEmptyDatabaseTest` renders screen 92 against a
    # database it has asserted is empty — one service row left behind by this
    # file takes that away for whatever `--seed` orders it after this one.
    wipe = fn ->
      Kati.Repo.query!("DELETE FROM services WHERE name LIKE ?1", [@prefix <> "%"])
    end

    wipe.()
    on_exit(wipe)
    :ok
  end

  # What the device does, in order: type into the fields, then tap the button.
  defp add(view, name, price \\ nil) do
    view = render_info(view, {:change, :service_name, name})
    view = if price, do: render_info(view, {:change, :service_price, price}), else: view
    render_info(view, {:tap, :add_service})
  end

  defp stored(name), do: Enum.find(mine(), &(&1.name == name))

  # Only this file's rows: the suite shares one SQLite file.
  defp mine do
    Service |> Ash.read!() |> Enum.filter(&String.starts_with?(&1.name, @prefix))
  end

  defp notice(view), do: assigns(view).notice

  defp taps(view), do: for(%{props: %{on_tap: {_pid, tag}}} <- flatten(view), do: tag)

  # A store the screen cannot write to, for the length of one tap. `after`
  # rather than `on_exit`, so the table is back before anything else reads it.
  defp without_the_services_table(fun) do
    Kati.Repo.query!("ALTER TABLE services RENAME TO services_away")

    try do
      fun.()
    after
      Kati.Repo.query!("ALTER TABLE services_away RENAME TO services")
    end
  end

  describe "the add card" do
    test "a name alone writes a paid service with no price, and the card empties" do
      name = @prefix <> "Mubi"
      view = MyServices |> mount_screen() |> add(name)

      service = stored(name)
      assert service != nil, "the row never reached the store"
      assert service.tier == :subscribed
      assert service.provider_id == nil
      assert service.monthly_pence == nil

      assert Enum.any?(MyServices.subscribed(), &(&1.name == name))
      assert MyServices.subscribed_label(assigns(view).services) == "Subscribed · 1"

      assert assigns(view).draft_name == ""
      assert assigns(view).editing == nil
      assert notice(view) == {:ok, "Added #{name}."}
      assert find(tree(view), :text, text: "Added #{name}.") != nil
    end

    test "a price is stored in pence, and screen 23's total adds it up" do
      MyServices
      |> mount_screen()
      |> add(@prefix <> "Mubi", "10.99")
      |> add(@prefix <> "Now", "9")

      assert stored(@prefix <> "Mubi").monthly_pence == 1099
      assert stored(@prefix <> "Now").monthly_pence == 900
      assert Service.total(Enum.filter(mine(), &(&1.tier == :subscribed))) == "£19.99"
    end

    test "any name is a service, numbers and all" do
      MyServices |> mount_screen() |> add(@prefix <> "Apple TV+ 4K", "6.99")

      assert stored(@prefix <> "Apple TV+ 4K").monthly_pence == 699
    end

    test "free with ads hides the price, and a free service has none" do
      view = mount_screen(MyServices)
      assert find(tree(view), :text_field, accessibility_id: "service_price") != nil

      view = render_info(view, {:tap, :kind_free})
      assert find(tree(view), :text_field, accessibility_id: "service_price") == nil

      add(view, @prefix <> "Pluto", "4.99")

      assert stored(@prefix <> "Pluto").tier == :free_with_ads
      assert stored(@prefix <> "Pluto").monthly_pence == nil
    end

    test "switching kind keeps the name that was typed" do
      view =
        MyServices
        |> mount_screen()
        |> render_info({:change, :service_name, @prefix <> "Pluto"})
        |> render_info({:tap, :kind_free})

      assert assigns(view).field_name == @prefix <> "Pluto"
      assert find(tree(view), :text_field, value: @prefix <> "Pluto") != nil
    end
  end

  describe "typing" do
    test "does not change what is drawn, so the page is not repainted per keystroke" do
      view = mount_screen(MyServices)
      before = tree(view)

      typed =
        view
        |> render_info({:change, :service_name, "Net"})
        |> render_info({:change, :service_name, "Netflix"})
        |> render_info({:change, :service_price, "10.9"})

      assert tree(typed) == before
      assert assigns(typed).draft_name == "Netflix"
      assert assigns(typed).draft_price == "10.9"
    end
  end

  describe "a save that cannot land" do
    test "no name writes nothing and says so beside the button" do
      view = MyServices |> mount_screen() |> render_info({:tap, :add_service})

      assert notice(view) == {:error, "Type the service’s name first."}
      assert find(tree(view), :text, text: "Type the service’s name first.") != nil
      assert mine() == []
    end

    test "a name of spaces is the same refusal" do
      view = MyServices |> mount_screen() |> add("   ")

      assert notice(view) == {:error, "Type the service’s name first."}
    end

    test "a price that is not a number is refused and the typing kept" do
      view = MyServices |> mount_screen() |> add(@prefix <> "Mubi", "ten")

      assert notice(view) == {:error, "The price has to be a number, like 10.99."}
      assert assigns(view).draft_name == @prefix <> "Mubi"
      assert mine() == []
    end

    test "the next keystroke takes the refusal away" do
      view =
        MyServices
        |> mount_screen()
        |> render_info({:tap, :add_service})
        |> render_info({:change, :service_name, "M"})

      assert notice(view) == nil
      assert find(tree(view), :text, text: "Type the service’s name first.") == nil
    end

    test "a store that refuses the write reports it and keeps the name" do
      view =
        MyServices |> mount_screen() |> render_info({:change, :service_name, @prefix <> "Nebula"})

      view = without_the_services_table(fn -> render_info(view, {:tap, :add_service}) end)

      assert notice(view) == {:error, "That did not save. Your text is still here — try again."}
      assert assigns(view).draft_name == @prefix <> "Nebula"
      assert mine() == []
    end
  end

  describe "a name already listed" do
    test "is refused in any case, and points at the row to change instead" do
      Ash.create!(Service, %{name: @prefix <> "Mubi", tier: :subscribed})

      view = MyServices |> mount_screen() |> add(String.upcase(@prefix <> "mubi"))

      assert notice(view) ==
               {:error, "#{@prefix}Mubi is already on your list. Tap it below to change it."}

      assert length(mine()) == 1
    end

    test "under Not mine is brought back with what was typed" do
      Ash.create!(Service, %{name: @prefix <> "Mubi", tier: :not_mine})

      MyServices |> mount_screen() |> add(@prefix <> "Mubi", "11.99")

      assert stored(@prefix <> "Mubi").tier == :subscribed
      assert stored(@prefix <> "Mubi").monthly_pence == 1199
      assert length(mine()) == 1
    end

    test "already_listed/1 ignores case and surrounding space, and nothing else" do
      Ash.create!(Service, %{name: @prefix <> "Mubi", tier: :subscribed})

      assert MyServices.already_listed(@prefix <> "MUBI").name == @prefix <> "Mubi"
      assert MyServices.already_listed(@prefix <> "Mubi Plus") == nil
    end
  end

  describe "a listed service" do
    setup do
      %{
        service:
          Ash.create!(Service, %{name: @prefix <> "Mubi", tier: :subscribed, monthly_pence: 1099})
      }
    end

    test "tapped, fills the card to be corrected, and Save changes it in place", %{service: s} do
      view = mount_screen(MyServices)
      tag = String.to_atom("edit_service_" <> s.id)
      assert tag in taps(view)

      editing = render_info(view, {:tap, tag})
      assert assigns(editing).editing == s.id
      assert assigns(editing).field_name == @prefix <> "Mubi"
      assert assigns(editing).field_price == "10.99"
      # The editor opens under the row, and the add card is not drawn meanwhile.
      refute text(editing) =~ "ADD A SERVICE"
      texts = text(editing)
      {row_at, _} = :binary.match(texts, @prefix <> "Mubi")
      {save_at, _} = :binary.match(texts, "Save")
      assert row_at < save_at

      saved =
        editing
        |> render_info({:change, :service_price, "12.99"})
        |> render_info({:tap, :add_service})

      assert stored(@prefix <> "Mubi").monthly_pence == 1299
      assert length(mine()) == 1
      assert assigns(saved).editing == nil
      assert assigns(saved).field_epoch > assigns(editing).field_epoch
      assert notice(saved) == {:ok, "Saved #{@prefix}Mubi."}
    end

    test "renamed onto another listed name is refused", %{service: s} do
      Ash.create!(Service, %{name: @prefix <> "Now", tier: :subscribed})

      view =
        MyServices
        |> mount_screen()
        |> render_info({:tap, String.to_atom("edit_service_" <> s.id)})
        |> render_info({:change, :service_name, @prefix <> "now"})
        |> render_info({:tap, :add_service})

      assert {:error, _} = notice(view)
      assert stored(@prefix <> "Mubi") != nil
    end

    test "can be deleted from the card", %{service: s} do
      view =
        MyServices
        |> mount_screen()
        |> render_info({:tap, String.to_atom("edit_service_" <> s.id)})
        |> render_info({:tap, :delete_service})

      assert mine() == []
      assert notice(view) == {:ok, "Deleted #{@prefix}Mubi."}
      assert assigns(view).editing == nil
    end

    test "a long press opens the same editor as a tap", %{service: s} do
      view =
        MyServices
        |> mount_screen()
        |> render_info({:long_press, String.to_atom("edit_service_" <> s.id)})

      assert assigns(view).editing == s.id
      assert :delete_service in taps(view)
    end

    test "Cancel empties the card and changes nothing", %{service: s} do
      view =
        MyServices
        |> mount_screen()
        |> render_info({:tap, String.to_atom("edit_service_" <> s.id)})
        |> render_info({:change, :service_price, "1"})
        |> render_info({:tap, :cancel_edit})

      assert assigns(view).editing == nil
      assert assigns(view).field_name == ""
      assert stored(@prefix <> "Mubi").monthly_pence == 1099
    end

    test "its switch moves it to Not mine rather than deleting it", %{service: s} do
      dropped = MyServices |> mount_screen() |> render_info({:tap, MyServices.drop_tag(s)})

      assert stored(@prefix <> "Mubi").tier == :not_mine
      refute MyServices.drop_tag(s) in taps(dropped)
      assert String.to_atom("restore_service_" <> s.id) in taps(dropped)
    end
  end

  describe "a service under Not mine" do
    test "opens the editor too, and can be deleted for good" do
      s = Ash.create!(Service, %{name: @prefix <> "Digikala", tier: :not_mine})
      tag = String.to_atom("edit_service_" <> s.id)

      view = mount_screen(MyServices)
      assert tag in taps(view)

      view = view |> render_info({:tap, tag}) |> render_info({:tap, :delete_service})

      assert mine() == []
      assert notice(view) == {:ok, "Deleted #{@prefix}Digikala."}
      refute String.to_atom("restore_service_" <> s.id) in taps(view)
    end
  end

  describe "the drawing" do
    test "the switch is not drawn over a row that is only a drawing" do
      drawn = inspect(MyServices.mine_switch(%{name: "Lumen+"}), limit: :infinity)

      refute drawn =~ "drop_service"
    end

    test "screen 93 keeps the drawn search field, because it draws nowhere to add" do
      tree = MyServices.search_field()

      assert find(tree, :text_field) == nil
      assert find(tree, :text, text: "Search services") != nil
    end
  end
end
