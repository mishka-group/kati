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

    # `AddByHand.load/1`'s own resting state — empty, Film, nothing assumed —
    # and not board 157's captured values.
    #
    # It used to open on `The Long Hollow`, `:tv`, `2024`, which is the frame
    # this board was drawn in, and then *Add to library* wrote exactly that
    # into the reader's real library: a series nobody had typed, from a
    # colourway specimen (MOVIES-AND-TV.md #29). Board 155 states the screen's
    # actual default and `Kati.Screens.AddByHand`'s moduledoc carries the
    # argument; the board's own values are installed by
    # `Kati.ScreenDesignLiteralTest.drawn_state/0`, which is where a captured
    # frame belongs.
    AddByHand.load(socket)
  end

  @doc false
  def content(assigns), do: AddByHand.content(assigns)

  @impl true
  def handle_tap(tag, socket), do: AddByHand.handle_tap(tag, socket)

  # The three fields, and their absence is the other half of #29.
  #
  # This screen delegates `content/1` and `handle_tap/2` and stopped there, so
  # the `TextField`s it draws are `Kati.Screens.AddByHand`'s — with its
  # `on_change` — and every `{:change, …}` they sent fell through to
  # `Kati.Screens.Pushed`'s catch-all and was dropped. Three fields drawn, none
  # of them typeable, and nothing to see: the field renders its value, and the
  # value never changed.
  @impl true
  def handle_info({:change, _field, _typed} = message, socket),
    do: AddByHand.handle_info(message, socket)

  def handle_info(message, socket), do: super(message, socket)
end
