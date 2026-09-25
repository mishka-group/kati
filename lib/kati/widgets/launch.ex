defmodule Kati.Widgets.Launch do
  @moduledoc """
  Where a tap on the home-screen widget lands.

  The widget's tap starts `MainActivity` with Mob's own
  `mob_notification_json` extra, so it arrives exactly as a notification tap
  does: `Mob.Router` decodes it and hands the current screen
  `{:notification, %{data: data}}`, with `data`'s keys as atoms. From a
  killed app that happens in the router's init; from a running one,
  `Kati.Native.TapRelay` forwards it. `Kati.Screens.Root` and
  `Kati.Screens.Pushed` both route that message here.

  Two payloads, both written by `KatiContinueWidget.kt`:

    * `%{kati_open: "title", id: id, kind: kind}` — the hero. Opens the film
      page for a film and the series page for anything else, the same split
      `Kati.Screens.UpNext.open/2` makes for the same row.
    * `%{kati_open: "add"}` — the empty state's *Add a title*. Opens the add
      sheet the FAB opens.

  Anything else — a notification that is not the widget's, a payload from an
  older build — leaves the screen as it is: the app has already been brought
  to the front, which is the whole of what a plain tap promised.

  **Pure navigation, no read.** The id is not looked up here: this function is
  reached from every root and every pushed screen, and a store read from those
  macros would put all of them inside `Kati.ScreenEmptyDatabaseTest`'s closure
  of screens that touch the database. A stale id — a title removed after the
  widget last drew — lands on the page's own honest empty frame, which is what
  `Kati.Screens.Series.series/1` and `Kati.Screens.Film.film/1` draw for an id
  that no longer resolves.
  """

  @doc """
  Navigate for a decoded notification, or return the socket untouched.
  """
  @spec open(Mob.Socket.t(), map()) :: Mob.Socket.t()
  def open(socket, %{data: %{kati_open: "title", id: id} = data})
      when is_binary(id) and id != "" do
    Mob.Socket.push_screen(socket, screen_for(Map.get(data, :kind)), %{id: id, back: "Back"})
  end

  def open(socket, %{data: %{kati_open: "add"}}),
    do: Mob.Socket.push_screen(socket, Kati.Screens.AddTitle)

  def open(socket, _other), do: socket

  @doc """
  The page a hero of `kind` opens on.

      iex> Kati.Widgets.Launch.screen_for("movie")
      Kati.Screens.Film

      iex> Kati.Widgets.Launch.screen_for("tv")
      Kati.Screens.Series

      iex> Kati.Widgets.Launch.screen_for(nil)
      Kati.Screens.Series
  """
  @spec screen_for(term()) :: module()
  def screen_for("movie"), do: Kati.Screens.Film
  def screen_for(_series), do: Kati.Screens.Series
end
