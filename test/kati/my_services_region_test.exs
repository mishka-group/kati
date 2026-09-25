defmodule Kati.MyServicesRegionTest do
  @moduledoc """
  Screen 92's region row says whether the reader chose a country, and the page
  never draws the drawing's services or total.

  `Kati.Services.region/0` answers `"GB"` for a reader who has picked nothing,
  so every availability question has an answer. The row used to draw that
  default as if the reader had chosen it. It now says *Not picked yet* until
  screen 94 writes a choice, and the choice is written here through 94's own
  control and read back by 92.

  `:kati_region` is cleared explicitly on the way in. `Mob.ScreenCase` starts
  `Mob.State` per test over a throwaway directory, so nothing needs restoring.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Screens.CountryPicker
  alias Kati.Screens.MyServices

  doctest MyServices, only: [region_sub: 1]

  @prefix "Region test "

  setup do
    Mob.State.delete(:kati_region)
    wipe!()
    on_exit(&wipe!/0)
    :ok
  end

  defp wipe!, do: Kati.Repo.query!("DELETE FROM services WHERE name LIKE ?1", [@prefix <> "%"])

  defp texts(view), do: view |> find_all(:text) |> Enum.map(&(&1.props[:text] || ""))

  test "an unchosen country is drawn as an assumption, not as the reader's" do
    view = mount_screen(MyServices)

    assert assigns(view).chosen_region == nil
    assert "Not picked yet — Kati assumes this until you choose" in texts(view)
    refute "Decides what “available” means" in texts(view)
  end

  test "picking a country on 94 is what 92 reads back" do
    picker = mount_screen(CountryPicker)
    _popped = render_info(picker, {:tap, :pick_DE})

    assert Kati.Services.chosen_region() == "DE"

    view = mount_screen(MyServices)

    assert "Germany" in texts(view)
    assert "Decides what “available” means" in texts(view)
    refute "Not picked yet — Kati assumes this until you choose" in texts(view)
  end

  test "no path draws the drawing's services or its total" do
    view = mount_screen(MyServices)
    drawn = texts(view)
    sample = Kati.Services.Sample.subscribed() ++ Kati.Services.Sample.free()

    for %{name: name} <- sample, stored?(name) == false do
      refute name in drawn, "#{name} is the drawing's, and nobody told Kati about it"
    end

    refute Enum.any?(drawn, &String.contains?(&1, Kati.Services.Sample.monthly_total()))
  end

  test "a stored service is listed with its own price, and the total is its own" do
    Ash.create!(Kati.Services.Service, %{
      name: @prefix <> "Mubi",
      tier: :subscribed,
      monthly_pence: 1099
    })

    view = mount_screen(MyServices)
    names = Enum.map(assigns(view).services.subscribed, & &1.name)

    assert (@prefix <> "Mubi") in names
    assert (@prefix <> "Mubi") in texts(view)
    refute MyServices.monthly_total() == Kati.Services.Sample.monthly_total()
  end

  defp stored?(name) do
    Kati.Services.Service
    |> Ash.read!()
    |> Enum.any?(&(&1.name == name))
  end
end
