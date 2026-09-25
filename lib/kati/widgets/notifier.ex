defmodule Kati.Widgets.Notifier do
  @moduledoc """
  Every write to a resource the widget's hero is read from pokes
  `Kati.Widgets.Refresher`.

  The choke point for W3, and deliberately the resource rather than the
  screens. The hero is `Kati.Screens.UpNext.queue/0`'s first row, which reads
  `Kati.Media.TrackedTitle` — status, progress, archived, `last_touched_at` —
  and `Kati.Media.CachedTitle` for the title, the runtime and the poster
  path. The writes that change those are spread over the series page, the
  film page, the rating sheet, the drop sheet, the add sheet, the importer,
  a backup restore and a sync, and a refresh call beside each would be one
  more thing every future write path has to remember. A notifier is run by
  Ash after every create, update and destroy on the resource, whoever calls
  it.

  `Kati.Media.Watch` is deliberately not registered: the hero never reads a
  watch. Ticking an episode moves the hero through the bookmark and status
  `Kati.Screens.Series.restate/1` writes back onto the tracked row, and
  logging a film finishes its tracked row (`Kati.Screens.Rating`) — both
  tracked-title updates, both caught here.

  Registered as a `simple_notifiers:` entry, so it adds no DSL. AshSqlite
  cannot transact (`Ash.DataLayer.can?(:transact, …)` is false), so Ash never
  holds these back for a commit — which is also why none of them is ever
  reported as missed inside a hand-rolled `Kati.Repo.transaction/1`.
  """

  use Ash.Notifier

  @impl true
  def notify(%Ash.Notifier.Notification{}), do: poke()

  @doc """
  Tell `Kati.Widgets.Refresher` the hero may have moved. Returns at once.

  The one door for the writes that do not pass through an Ash action — a
  downloaded poster, a restored backup — as well as for `notify/1`.

  A cast to the Refresher's registered NAME rather than a call to
  `Kati.Widgets.Refresher.poke/1`, on purpose. `Kati.Media.Artwork` is reached
  by nearly every screen through `Kati.Design.Images`, and a function call is
  an edge in `Kati.ScreenEmptyDatabaseTest`'s graph of modules that reach the
  store: the Refresher reads `Kati.Screens.UpNext.queue/0`, so calling it from
  Artwork put ten screens that read nothing on that test's list of screens
  that read the database. A module name is an atom, not an edge. A cast to a
  name nobody holds — the host suite, which never starts `Kati.Supervisor` —
  is dropped rather than raised.
  """
  @spec poke() :: :ok
  def poke, do: GenServer.cast(Kati.Widgets.Refresher, :poke)
end
