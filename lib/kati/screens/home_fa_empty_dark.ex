defmodule Kati.Screens.HomeFaEmptyDark do
  @moduledoc """
  Screen 159 — screen 158 in the dark colourway.

  The Persian empty Home, dark. Screen 68's arrangement applied to 158: every
  band is `Kati.Screens.HomeFaEmpty`'s own function, and the only thing this
  file owns is the theme, so the two cannot disagree about which parts of an
  empty app still work.

  `Mob.Theme.set(Kati.Theme.dark())` is the whole switch, and it carries the
  cost screens 28, 29, 68 and 157 already carry, stated rather than hidden:
  `Mob.Theme.set/1` is global, so the app stays dark until the next mount
  activates the preference again. That closes when dark becomes a mode
  `Kati.Shell` carries rather than a page of its own.
  """
  use Mob.Screen
  import Mob.Sigil

  alias Kati.Screens.Fa
  alias Kati.Screens.HomeFaEmpty

  def mount(_params, _session, socket) do
    Mob.Theme.set(Kati.Theme.dark())
    {:ok, socket}
  end

  def render(assigns),
    do: Fa.frame(:home, HomeFaEmpty.content(assigns), Kati.Screens.Identity.of(__MODULE__))

  def handle_info(message, socket), do: HomeFaEmpty.handle_info(message, socket)
end
