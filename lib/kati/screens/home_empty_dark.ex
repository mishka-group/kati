defmodule Kati.Screens.HomeEmptyDark do
  @moduledoc """
  Screen 159 — screen 139 in the dark colourway.

  Board 159 is drawn in Persian and board 139 is the same page in English; both
  are `Kati.Screens.HomeEmpty`, which takes its script from `Kati.Locale`.
  Screen 68's arrangement applied to 139: every band is that screen's own
  function, and the only thing this file owns is the theme, so the two cannot
  disagree about which parts of an empty app still work.

  There is no English board of an empty Home in dark and no Persian one of a
  full Home in dark, which is why 159 keeps a module while 158 does not:
  mishka-group/kati#103 folded 158 into 139 outright, and this page is a
  COLOURWAY rather than a mirror — the same relation 28 has to 01.

  `Mob.Theme.set(Kati.Theme.dark())` is the whole switch, and it carries the
  cost screens 28, 29, 68 and 157 already carry, stated rather than hidden:
  `Mob.Theme.set/1` is global, so the app stays dark until the next mount
  activates the preference again. That closes when dark becomes a mode
  `Kati.Shell` carries rather than a page of its own.
  """
  use Mob.Screen
  import Mob.Sigil

  alias Kati.Screens.HomeEmpty

  def mount(_params, _session, socket) do
    Mob.Theme.set(Kati.Theme.dark())
    # Resolves the stored locale into THIS process. `Gettext.put_locale/2`
    # snapshots into the calling process exactly as `Mob.Theme.set/1` does,
    # and a screen is its own process — see `Kati.Locale.activate/0`.
    Kati.Locale.activate()
    {:ok, socket}
  end

  # Screen 28's own arrangement rather than `Kati.Shell.render/1`: the shell
  # stamps its root's name — `screen:home` — and this page needs its own, so
  # the frame is built here the way `Kati.Screens.HomeDark` builds its empty
  # branch. The scrim and the dock are that screen's, because they are the dark
  # ones and there is exactly one pair of them.
  def render(assigns) do
    ~MOB"""
    <Box
      fill_width={true}
      fill_height={true}
      background={:background}
      layout_direction={Kati.Locale.direction_prop()}
      font_family={Kati.Locale.face_prop()}
      accessibility_id={Kati.Screens.Identity.of(__MODULE__)}
    >
      {HomeEmpty.content(assigns)}
      {Kati.Screens.HomeDark.scrim()}
      {Kati.Screens.HomeDark.dock()}
    </Box>
    """
  end

  def handle_info(message, socket), do: HomeEmpty.handle_info(message, socket)
end
