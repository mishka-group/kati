defmodule Kati.YearShareSaveTest do
  @moduledoc """
  *Save image* on screen 98 saves an image.

  MOVIES-AND-TV.md #80: it pushed `Kati.Screens.YearCards` — the reference
  sheet about how a card is drawn, which is a page about the feature rather
  than the feature — so a reader who wanted their year as a picture got a
  lesson instead, and nothing on the device.

  The note beside it said the capability was missing. It was not: `K-45
  capture-screen` had shipped and `Kati.Screens.WeekImage` had been saving its
  own page through `Kati.Native.Files.save_screen/1` since. This is the same
  three lines, and the same five refusal sentences, because a reader who meets
  both buttons should not meet two vocabularies.
  """

  use Mob.ScreenCase, async: false

  alias Kati.Screens.YearShare

  describe "the button" do
    test "no longer pushes the reference sheet" do
      view = mount_screen(YearShare)
      {:noreply, socket} = YearShare.handle_tap(:save_image, assigns_socket(view))

      refute match?({:push, Kati.Screens.YearCards, _}, Map.get(socket.__mob__, :nav_action))
    end

    test "reports a refusal rather than swallowing it" do
      # There is no bridge on the host, so the capture cannot happen and the
      # screen must say so — the whole point of the finding was a button that
      # appeared to work and did not.
      view = mount_screen(YearShare)
      {:noreply, socket} = YearShare.handle_tap(:save_image, assigns_socket(view))

      assert is_binary(socket.assigns.save_error)

      assert socket.assigns.save_error =~ "Nothing was saved." or
               socket.assigns.save_error =~ "does not work here yet."
    end

    test "and the refusal reaches a node, not just an assign" do
      view = mount_screen(YearShare)
      {:noreply, socket} = YearShare.handle_tap(:save_image, assigns_socket(view))

      words =
        socket.assigns
        |> YearShare.render()
        |> inspect(limit: :infinity, printable_limit: :infinity)

      assert words =~ socket.assigns.save_error
    end
  end

  describe "the filename" do
    test "carries the year the card is about" do
      assert YearShare.filename() == "kati-year-#{Kati.Time.today().year}.png"
    end

    test "and is ASCII, because the Kotlin half strips anything else" do
      assert YearShare.filename() =~ ~r/^[a-z0-9\-.]+$/
    end
  end

  describe "the capture path" do
    test "goes through PixelCopy, because a page with posters on it cannot be drawn" do
      # Found on the Pixel_9a: `Software rendering doesn't support hardware
      # bitmaps`, thrown from inside Compose's draw pass. Coil decodes into
      # hardware bitmaps and `View.draw(Canvas(bitmap))` cannot draw one — so
      # screen 121, a week of pure type, saved fine and screen 98, a share
      # card with three posters, could not. PixelCopy reads the window's
      # rendered surface instead, hardware layers included.
      #
      # Asserted against the bridge source for `max_font_scale`'s reason: an
      # unknown call is not an error here, it is a capture that silently goes
      # back to failing on every page with a picture on it.
      src = File.read!("android/app/src/main/java/com/example/kati/MobBridge.kt")

      assert src =~ "PixelCopy.request(",
             "the capture is back on View.draw, which cannot draw a Coil bitmap"

      assert src =~ "katiDrawCapture",
             "the software path is gone, so a window with no surface captures nothing"
    end
  end

  defp assigns_socket(view) do
    Kati.Screens.YearShare
    |> Mob.Socket.new()
    |> then(fn socket ->
      Enum.reduce(assigns(view), socket, fn {k, v}, acc -> Mob.Socket.assign(acc, k, v) end)
    end)
  end
end
