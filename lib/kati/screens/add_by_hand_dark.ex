defmodule Kati.Screens.AddByHandDark do
  @moduledoc """
  Screen 157 — screen 154's form, in the dark colourway.

  Built to `test/design/screens/157.html`. The same page as
  `Kati.Screens.AddByHand` in the sense screen 28 is the same page as screen
  01: same bands, same copy, same order, and deliberately **not** an inversion.
  Every string and every field on this screen is 154's, rendered through that
  module's own functions under a dark theme — so the two cannot disagree about
  what the form asks or in what order.

  `Mob.Theme.set(Kati.Theme.dark())` in `load/1` is the whole switch, the same
  single call screens 28, 29 and 68 make: `Kati.Theme.Palette.mode/0` reads
  whichever theme is installed rather than keeping a second answer.

  It carries the cost those screens carry, stated rather than hidden —
  `Mob.Theme.set/1` is global and popping back does not remount the screen
  underneath, so the app stays dark until the next mount activates the
  preference again. That closes when dark stops being a separate page and
  becomes a mode `Kati.Shell` carries, which is what `Kati.Screens.HomeDark`
  is also waiting on.

  The board is drawn with a title typed and Series chosen, exactly as 154 is,
  and for the same reason: the episode-count field is only visible for a
  series. The resting state — Film, nothing assumed — is board 155's, and
  `Kati.Screens.AddByHand`'s moduledoc carries that argument once rather than
  twice.
  """
  use Kati.Screens.Pushed, back: "Add title"

  alias Kati.Screens.AddByHand

  @impl true
  def load(socket) do
    Mob.Theme.set(Kati.Theme.dark())

    Mob.Socket.assign(socket,
      title: "The Long Hollow",
      kind: :tv,
      year: "2024",
      status: "Not started",
      episodes: "",
      save_error: nil
    )
  end

  @doc false
  def content(assigns), do: AddByHand.content(assigns)

  @impl true
  def handle_tap(tag, socket), do: AddByHand.handle_tap(tag, socket)
end
