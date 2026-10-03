defmodule Kati.ReduceMotionTest do
  @moduledoc """
  *Reduce motion* is stored, survives a fresh mount, and reaches every screen's
  root as the prop `MainActivity`'s `K-72` fence reads (#118).

  The switch on screen 24 used to flip its thumb and store nothing: the next
  mount drew it off again, and no page ever changed how it arrived.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Screens.Settings

  doctest Kati.Accessibility, only: [motion_prop: 1, factor: 1]

  setup do
    installed = Mob.Theme.current()
    Mob.State.put(:reduce_motion, false)
    Kati.Accessibility.forget()

    on_exit(fn ->
      Mob.State.put(:reduce_motion, false)
      Kati.Accessibility.forget()
      Mob.Theme.set(installed)
    end)
  end

  defp switch_on?(view) do
    view
    |> assigns()
    |> get_in([:settings, :appearance])
    |> Enum.find(&(&1.id == "reduce_motion"))
    |> Map.fetch!(:control)
  end

  test "it is off until somebody turns it on" do
    refute Kati.Accessibility.reduce_motion?()
    assert switch_on?(mount_screen(Settings)) == {:switch, false}
  end

  test "the switch writes the store, and a fresh mount reads it back" do
    view = mount_screen(Settings) |> render_info({:tap, :switch_reduce_motion})

    assert switch_on?(view) == {:switch, true}
    assert Mob.State.get(:reduce_motion) == true

    Kati.Accessibility.forget()
    assert switch_on?(mount_screen(Settings)) == {:switch, true}
  end

  test "a second tap turns it off again" do
    view =
      mount_screen(Settings)
      |> render_info({:tap, :switch_reduce_motion})
      |> render_info({:tap, :switch_reduce_motion})

    assert switch_on?(view) == {:switch, false}
    refute Kati.Accessibility.reduce_motion?()
  end

  test "every pushed screen's root carries the prop native reads" do
    root = fn -> mount_screen(Settings) |> flatten() |> hd() end

    assert root.().props[:reduce_motion] == "full"

    :ok = Kati.Accessibility.put_reduce_motion(true)
    assert root.().props[:reduce_motion] == "reduce"
  end

  test "the screens that draw their own root carry it too" do
    :ok = Kati.Accessibility.put_reduce_motion(true)

    for module <- [Kati.Screens.Search, Kati.Screens.QuickAdd, Kati.Screens.ListAddTitles] do
      root = mount_screen(module) |> flatten() |> hd()
      assert root.props[:reduce_motion] == "reduce", "#{inspect(module)} root lacks the prop"
    end
  end

  test "every root that names a direction names the motion beside it" do
    for path <- Path.wildcard("lib/**/*.ex"),
        source = File.read!(path),
        Regex.match?(~r/^\s*layout_direction=\{[^}]+\}\s*$/m, source) do
      assert source =~ "reduce_motion={Kati.Accessibility.motion_prop()}",
             "#{path} sets a root direction without reduce_motion"
    end
  end

  test "TalkBack hears the switch's state, which a drawn switch cannot say by itself" do
    labels = fn view ->
      for %{props: %{accessibility_label: label}} <- flatten(view), do: label
    end

    view = mount_screen(Settings)
    assert "Reduce motion: off" in labels.(view)

    view = render_info(view, {:tap, :switch_reduce_motion})
    assert "Reduce motion: on" in labels.(view)
  end

  test "K-72 fades instead of sliding, and honours Android's Remove animations" do
    kt = File.read!("android/app/src/main/java/com/example/kati/MainActivity.kt")

    assert kt =~ ~s|props?.get("reduce_motion") as? String) == "reduce"|
    assert kt =~ "ANIMATOR_DURATION_SCALE"
    assert kt =~ "alpha = fade.value"
  end
end
