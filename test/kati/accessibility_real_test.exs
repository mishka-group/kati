defmodule Kati.AccessibilityRealTest do
  @moduledoc """
  Screen 41 changes the app, and every change is stored (#119).

  It drew five ticks that looked like settings and changed nothing, about
  *VoiceOver* on an Android phone, and an Up next card about a show nobody had
  (A5). Now: three text sizes, *Reduce motion* and *Increase contrast*, each
  written to `Kati.Accessibility`, each read back by a fresh mount, and each
  reaching the place it promises to change.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Screens.Accessibility
  alias Kati.Theme.Palette

  doctest Kati.Screens.Accessibility, only: [voiceover_line: 1, scale_label: 1, summary: 1]

  setup do
    installed = Mob.Theme.current()
    reset()

    on_exit(fn ->
      reset()
      Mob.Theme.set(installed)
    end)
  end

  defp reset do
    Mob.State.put(:reduce_motion, false)
    Mob.State.put(:text_scale, :system)
    Mob.State.put(:high_contrast, false)
    Kati.Accessibility.forget()
  end

  defp tags(view) do
    for %{props: %{on_tap: {_pid, tag}}} <- flatten(view), is_atom(tag), do: tag
  end

  defp heard(view) do
    for %{props: %{accessibility_label: label}} <- flatten(view), do: label
  end

  defp root(view), do: view |> flatten() |> hd()

  describe "the preview" do
    defp drawn(hero) do
      socket =
        Accessibility
        |> Mob.Socket.new()
        |> Mob.Socket.assign(:hero, hero)
        |> Mob.Socket.assign(:display, Accessibility.display())

      inspect(Accessibility.render(socket.assigns), limit: :infinity, printable_limit: :infinity)
    end

    test "the reader's hero is the card, and the sentence names it" do
      words = drawn(%{title: "Dark", meta: "S1 · E3"})

      assert words =~ "Dark"
      assert words =~ "Dark. S1 · E3. Double-tap to open."
      assert words =~ "TALKBACK READS"
      refute words =~ "VoiceOver"
      refute words =~ "The Long Hollow"
    end

    test "with nothing on the go there is no card and no sentence" do
      refute drawn(nil) =~ "Double-tap"
    end
  end

  describe "text size" do
    test "every size is a tile, and the chosen one says so to TalkBack" do
      view = mount_screen(Accessibility)

      assert Enum.all?([:text_size_system, :text_size_large, :text_size_larger], &(&1 in tags(view)))
      assert "Phone text, chosen" in heard(view)
      assert "Larger text" in heard(view)
    end

    test "a tile stores the size, and every root carries the multiplier" do
      view = mount_screen(Accessibility) |> render_info({:tap, :text_size_larger})

      assert Mob.State.get(:text_scale) == :larger
      assert "Larger text, chosen" in heard(view)
      assert root(view).props[:text_scale] == 1.3

      Kati.Accessibility.forget()
      assert root(mount_screen(Kati.Screens.Settings)).props[:text_scale] == 1.3
    end

    test "screen 24's Text size row names the size chosen" do
      sub = fn ->
        mount_screen(Kati.Screens.Settings)
        |> assigns()
        |> get_in([:settings, :appearance])
        |> Enum.find(&(&1.id == "text_size"))
        |> Map.fetch!(:sub)
      end

      assert sub.() == "Follows system"
      :ok = Kati.Accessibility.put_text_scale(:large)
      assert sub.() == "Large · 115%"
    end

    test "a tag naming no size changes nothing" do
      mount_screen(Accessibility) |> render_info({:tap, :text_size_enormous})
      assert Kati.Accessibility.text_scale() == :system
    end
  end

  describe "reduce motion" do
    test "is the same stored value screen 24's switch writes" do
      view = mount_screen(Accessibility) |> render_info({:tap, :toggle_motion})

      assert "Reduce motion: on" in heard(view)
      assert Kati.Accessibility.reduce_motion?()
      assert root(view).props[:reduce_motion] == "reduce"

      settings = mount_screen(Kati.Screens.Settings)
      assert "Reduce motion: on" in heard(settings)
    end

    test "a Settings screen already on the stack shows the change once it is back on top" do
      settings = mount_screen(Kati.Screens.Settings)
      assert "Reduce motion: off" in heard(settings)

      :ok = Kati.Accessibility.put_reduce_motion(true)
      :ok = Kati.Accessibility.put_text_scale(:larger)
      settings = render_info(settings, {:kati, :resumed, nil})

      assert "Reduce motion: on" in heard(settings)
      assert text(settings) =~ "Larger · 130%"
    end
  end

  describe "increase contrast" do
    test "is stored, and the quiet tokens take their stronger step" do
      quiet = Palette.sub()
      rule = Palette.hairline()

      view = mount_screen(Accessibility) |> render_info({:tap, :toggle_contrast})

      assert "Increase contrast: on" in heard(view)
      assert Mob.State.get(:high_contrast) == true
      assert Palette.sub() == Palette.ink_soft()
      assert Palette.hairline() == Palette.track_ink()
      refute Palette.sub() == quiet
      refute Palette.hairline() == rule
    end

    test "off, every token is exactly the literal it always was" do
      for %{name: name, light: light} <- Palette.tokens() do
        assert Palette.token(name, :light) == light
      end

      for {name, _stronger} <- Palette.stronger() do
        assert apply(Palette, name, []) == Palette.token(name, Palette.mode())
      end
    end

    test "every stronger step is darker in light and lighter in dark" do
      luminance = fn argb ->
        r = Bitwise.band(Bitwise.bsr(argb, 16), 0xFF)
        g = Bitwise.band(Bitwise.bsr(argb, 8), 0xFF)
        b = Bitwise.band(argb, 0xFF)
        0.2126 * r + 0.7152 * g + 0.0722 * b
      end

      opacity = fn argb -> Bitwise.band(Bitwise.bsr(argb, 24), 0xFF) end

      for {name, stronger} <- Palette.stronger() do
        for mode <- [:light, :dark] do
          from = Palette.token(name, mode)
          to = Palette.token(stronger, mode)

          # An `on_ink_*` token is drawn ON the ink fill, whose ground is dark
          # in light mode and light in dark, so its stronger step runs the
          # other way.
          dark_ground? = (mode == :dark) != String.starts_with?(Atom.to_string(name), "on_ink")

          stronger? =
            if opacity.(from) < 0xFF or opacity.(to) < 0xFF,
              do: opacity.(to) >= opacity.(from),
              else:
                if(dark_ground?,
                  do: luminance.(to) >= luminance.(from),
                  else: luminance.(to) <= luminance.(from)
                )

          assert stronger?, "#{name} → #{stronger} is not a stronger step in #{mode}"
        end
      end
    end

    test "the theme's own muted slot follows it" do
      before = Kati.Theme.current().muted
      :ok = Kati.Accessibility.put_contrast(true)
      refute Kati.Theme.current().muted == before
    end
  end

  describe "always on" do
    test "the guarantees are statements: none of them is a control" do
      view = mount_screen(Accessibility)

      refute Enum.any?(tags(view), &String.starts_with?(Atom.to_string(&1), "switch_"))
      assert text(view) =~ "Named for TalkBack"
      assert text(view) =~ "Colour is never alone"
    end

    test "the system row asks for Android's own settings, and says so when it cannot" do
      view = mount_screen(Accessibility)
      assert :open_system in tags(view)

      view = render_info(view, {:tap, :open_system})
      assert assigns(view).error == Kati.Native.Links.message(:no_bridge)
    end
  end
end
