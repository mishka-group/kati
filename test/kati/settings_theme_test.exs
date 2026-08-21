defmodule Kati.SettingsThemeTest do
  @moduledoc """
  The Theme control on screens 24 and 62, and the setting behind it.

  ## The defect this exists for

  Both screens drew a trough with three tiles and moved the raised one when you
  tapped. The choice lived in the screen's own assigns and died with the socket,
  so the app's one appearance control decided nothing and forgot what you told
  it the moment you backed out. A screenshot could not see it: the resting
  frame was correct, the tap animated, the build was green.

  So the assertions here are deliberately not "the tile moved". Every one of
  them ends at either `Kati.Screens.Settings.choice/0` or at a **freshly mounted
  screen** — a second `mount_screen/1`, with its own socket and its own assigns
  — because that is the only thing that can tell a stored choice from one held
  in the render that drew it.

  ## Why the resting frame gets its own tests

  62 captured frames are this app's baseline and light mode may not move by a
  pixel. `an unset choice renders the same tree as a stored :auto` is the
  narrow version of that promise; the two `resting trough` tests are the wide
  one, pinning the drawing's own geometry and colours so that "the trough now
  reads a setting" cannot become "the trough now looks different".
  """
  use Mob.ScreenCase, async: false

  alias Kati.Screens.Settings
  alias Kati.Screens.SettingsFa
  alias Kati.Theme
  alias Kati.Theme.Palette

  # `put_choice/1` stores the preference AND installs the palette, and the two
  # outlive the test differently. The preference is safe: `Mob.ScreenCase` starts
  # `Mob.State` per test against a throwaway dir, so it dies with the test. The
  # palette is not — `Mob.Theme.set/1` is `Application.put_env/3`, which is one
  # global for the whole run. That was invisible while every screen forced light
  # at mount; now that screens read the setting, a dark palette left behind here
  # renders another file's screens dark, and those files assert the drawing's
  # light numbers. So put back the palette that was installed on the way in.
  #
  # Not `Kati.Theme.activate/0`: `on_exit` runs after the test process is gone,
  # which takes `Mob.State` with it, and resolving a choice would call a dead
  # GenServer. The snapshot needs nothing but application environment.
  setup do
    installed = Mob.Theme.current()
    on_exit(fn -> Mob.Theme.set(installed) end)
  end

  # The tiles both drawings put in the trough, in the order they put them.
  # Written out rather than read from the samples: a test that asks the code
  # under test what to expect agrees with it by construction.
  @en ["Auto", "Light", "Dark"]
  @fa ["خودکار", "روشن", "تیره"]

  # ── The boundary ────────────────────────────────────────────────────────────

  test "choices/0 names three choices, in the order both troughs draw their tiles" do
    # The size first, and on purpose. `choice_at/1` and `label_for/2` read
    # positions off this list, so a list that has quietly become two entries or
    # four maps every tile to the wrong choice while every other test in this
    # file still passes.
    assert length(Settings.choices()) == 3
    assert Settings.choices() == [:auto, :light, :dark]
  end

  test "a choice never made reads as the one both drawings raise" do
    assert Settings.choice() == :auto
  end

  test "put_choice/1 stores every choice, and choice/0 reads back the one just written" do
    for choice <- Settings.choices() do
      assert Settings.put_choice(choice) == :ok
      assert Settings.choice() == choice
    end
  end

  test "the tile positions and the choice names agree in both directions" do
    for {choice, index} <- Enum.with_index(Settings.choices()) do
      assert Settings.choice_at(index) == choice
      assert Settings.choice_for(@en, Enum.at(@en, index)) == choice
      assert Settings.choice_for(@fa, Enum.at(@fa, index)) == choice
      assert Settings.label_for(@en, choice) == Enum.at(@en, index)
      assert Settings.label_for(@fa, choice) == Enum.at(@fa, index)
    end
  end

  test "no index outside the trough names a choice" do
    # `-1` is the one that matters: `Enum.at/2` reads it as the LAST element, so
    # a malformed tag would otherwise select Dark rather than nothing.
    for index <- [-1, 3, 99] do
      assert Settings.choice_at(index) == nil
    end
  end

  test "a label the trough does not draw names no choice" do
    assert Settings.choice_for(@en, "Sepia") == nil
    assert Settings.choice_for(@fa, "Sepia") == nil
    assert Settings.choice_for(@en, "خودکار") == nil
  end

  test "label_for/2 never leaves the trough with nothing raised" do
    # A choice this build does not have is not a state either drawing has an
    # appearance for, and no tile raised is worse than the default raised.
    assert Settings.label_for(@en, :sepia) == "Auto"
    assert Settings.label_for(@fa, :sepia) == "خودکار"
  end

  # ── The resting frame ───────────────────────────────────────────────────────

  test "at rest screen 24 draws three tiles and raises the one 24.html raises" do
    view = mount_screen(Settings)

    assert labels(view) == @en
    assert raised(view) == ["Auto"]
  end

  test "at rest screen 62 draws three tiles and raises the one 62.html raises" do
    view = mount_screen(SettingsFa)

    assert labels(view) == @fa
    assert raised(view) == ["خودکار"]
  end

  test "the resting trough on 24 is the drawing's own geometry and colour" do
    view = mount_screen(Settings)
    trough = trough(view)

    assert trough.props[:background] == 0xFFEFECE7
    assert trough.props[:corner_radius] == 12
    assert trough.props[:padding] == 3

    [auto, light, dark] = tiles(view)

    assert auto.props[:height] == 26
    assert auto.props[:corner_radius] == 9
    assert auto.props[:background] == 0xFFFBFAF8
    assert auto.props[:shadow] == "0 1 2 0 #1F1A1917"
    assert auto.props[:padding_left] == 10
    assert auto.props[:padding_right] == 10
    assert label_props(auto)[:text_size] == 11
    assert label_props(auto)[:font_weight] == "semibold"
    assert label_props(auto)[:text_color] == :on_surface

    for idle <- [light, dark] do
      assert idle.props[:height] == 26
      assert idle.props[:corner_radius] == 9
      # Absent, not transparent: the English idle tile paints nothing at all,
      # and a background of any value would draw over the trough.
      refute Map.has_key?(idle.props, :background)
      refute Map.has_key?(idle.props, :shadow)
      assert label_props(idle)[:text_color] == 0xFFA0998F
    end

    # Three tiles, two gaps, and the gaps are the drawing's 3.
    assert Enum.count(trough.children, &(&1.type == :spacer)) == 2
    assert Enum.all?(trough.children, fn c -> c.type != :spacer or c.props[:size] == 3 end)
  end

  test "the resting trough on 62 is the drawing's own geometry and colour" do
    view = mount_screen(SettingsFa)
    trough = trough(view)

    assert trough.props[:background] == 0xFFEFECE7
    assert trough.props[:corner_radius] == 12
    assert trough.props[:padding] == 3

    [auto, light, dark] = tiles(view)

    assert auto.props[:height] == 26
    assert auto.props[:corner_radius] == 9
    assert auto.props[:background] == Theme.card(:light)
    assert label_props(auto)[:font_family] == "fa"
    assert label_props(auto)[:text_size] == 10.5
    assert label_props(auto)[:text_color] == Theme.ink()

    for idle <- [light, dark] do
      assert idle.props[:height] == 26
      assert idle.props[:corner_radius] == 9
      # Persian's idle tile carries a transparent fill where English carries no
      # fill at all. Both were drawn that way; neither may change.
      assert idle.props[:background] == 0x00FFFFFF
      assert label_props(idle)[:font_family] == "fa"
      assert label_props(idle)[:text_color] == 0xFFA0998F
    end
  end

  test "an unset choice renders the same tree as a stored :auto, on both screens" do
    # The whole tree, not the trough: this is the promise that reading a setting
    # at mount cannot move a pixel anywhere on either screen. Both copies are
    # rendered in this process, so the pids inside `on_tap` match.
    for module <- [Settings, SettingsFa] do
      unset = tree(mount_screen(module))
      :ok = Settings.put_choice(:auto)
      stored = tree(mount_screen(module))

      assert unset == stored, "#{inspect(module)} renders differently for an unset choice"
    end
  end

  # ── Storing a choice ────────────────────────────────────────────────────────

  test "each tile on 24 stores its choice, and a screen mounted afterwards raises it" do
    for {label, choice} <- Enum.zip(@en, Settings.choices()) do
      start_from_another_choice(choice)

      view = mount_screen(Settings)
      refute raised(view) == [label], "the test set up the choice it was about to assert"

      view = render_info(view, {:tap, String.to_atom("theme_" <> label)})

      assert Settings.choice() == choice
      assert raised(view) == [label]
      # The one that matters: a second socket, which has never seen the tap.
      assert raised(mount_screen(Settings)) == [label]
    end
  end

  test "each tile on 62 stores its choice, and a screen mounted afterwards raises it" do
    for {label, {choice, index}} <- Enum.zip(@fa, Enum.with_index(Settings.choices())) do
      start_from_another_choice(choice)

      view = mount_screen(SettingsFa)
      refute raised(view) == [label], "the test set up the choice it was about to assert"

      view = render_info(view, {:tap, String.to_atom("theme_#{index}")})

      assert Settings.choice() == choice
      assert raised(view) == [label]
      assert raised(mount_screen(SettingsFa)) == [label]
    end
  end

  test "the two screens are one setting, in both directions" do
    mount_screen(Settings) |> render_info({:tap, :theme_Dark})

    assert Settings.choice() == :dark
    assert raised(mount_screen(SettingsFa)) == ["تیره"]

    mount_screen(SettingsFa) |> render_info({:tap, :theme_1})

    assert Settings.choice() == :light
    assert raised(mount_screen(Settings)) == ["Light"]
  end

  test "only the tiles that are still choices carry a tag, on both screens" do
    for {module, drawn} <- [{Settings, @en}, {SettingsFa, @fa}] do
      for choice <- Settings.choices() do
        :ok = Settings.put_choice(choice)
        view = mount_screen(module)

        tagged = for tile <- tiles(view), Map.has_key?(tile.props, :on_tap), do: label(tile)

        assert length(tagged) == 2,
               "#{inspect(module)} at #{choice} offers #{length(tagged)} tappable tiles, not 2"

        assert raised(view) == drawn -- tagged
      end
    end
  end

  test "a tag naming a tile the trough does not draw leaves the setting alone" do
    :ok = Settings.put_choice(:dark)

    for {module, tag, raised} <- [
          {Settings, :theme_Sepia, "Dark"},
          {SettingsFa, :theme_9, "تیره"},
          {SettingsFa, :theme_x, "تیره"},
          {SettingsFa, :"theme_-1", "تیره"}
        ] do
      view = render_info(mount_screen(module), {:tap, tag})

      assert Settings.choice() == :dark, "#{inspect(tag)} rewrote the stored choice"
      assert raised(view) == [raised]
    end
  end

  # ── Reading the trough out of a rendered screen ─────────────────────────────

  # Store something other than `choice`, so the tap under test has work to do.
  # A test that taps Dark on a screen already showing Dark passes whether the
  # tap is wired or not.
  defp start_from_another_choice(choice) do
    other = Enum.find(Settings.choices(), &(&1 != choice))
    :ok = Settings.put_choice(other)
  end

  # The trough is the only `Row` on either screen painted the design's page
  # colour — the icon tiles that share it are `Box`es. Asserted rather than
  # assumed: if a second one ever appears, every helper below silently reads the
  # wrong control.
  #
  # Matched as `paper` in EITHER mode rather than as `0xFFEFECE7`. Screen 62 now
  # names its colours through `Kati.Theme.Palette` and mounts with
  # `Kati.Theme.activate/0`, so a test that stores :dark and then mounts it gets a
  # dark trough — which is the point of storing :dark. Screen 24 still writes the
  # light literal. Both are the same token; which side of it resolves is not what
  # these tests are about, and the resting-frame tests below still pin the exact
  # light number.
  defp trough(view) do
    troughs =
      view
      |> flatten()
      |> Enum.filter(&(&1.type == :row and &1.props[:background] in paper()))

    assert length(troughs) == 1, "expected one theme trough, found #{length(troughs)}"
    hd(troughs)
  end

  # The three tiles, in drawn order. The Persian trough wraps every tile after
  # the first in a spacer-carrying `Row`, so this reads the depth-first walk and
  # keeps the radius-9 tiles rather than the trough's own children.
  defp tiles(view) do
    view
    |> trough()
    |> flatten()
    |> Enum.filter(&(&1.type == :row and &1.props[:corner_radius] == 9))
  end

  defp labels(view), do: Enum.map(tiles(view), &label/1)

  # A tile is raised when it is painted the card colour; both screens paint the
  # raised one #FBFAF8 and neither paints the idle ones anything close. Read in
  # either mode, for the reason `trough/1` gives — 62's idle tiles are
  # `Palette.transparent/0` and 24's carry no fill at all, so neither collides
  # with `card` on either side.
  defp raised(view) do
    for tile <- tiles(view), tile.props[:background] in card(), do: label(tile)
  end

  defp paper, do: [Palette.paper(:light), Palette.paper(:dark)]
  defp card, do: [Palette.card(:light), Palette.card(:dark)]

  defp label(tile), do: label_props(tile)[:text]

  defp label_props(tile) do
    tile |> flatten() |> Enum.find(&(&1.type == :text)) |> Map.fetch!(:props)
  end
end
