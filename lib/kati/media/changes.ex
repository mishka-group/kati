defmodule Kati.Media.Changes.Touch do
  @moduledoc """
  Stamps `last_touched_at` on every write to a tracked title.

  The shelves on screens 03, 20 and 21 sort by it, so it is forced here rather
  than accepted from the caller. A sort key that some write paths remember to
  set is a shelf that reorders when a rating lands but not when a tick does, and
  the user reads that as the app losing their place.

  Deliberately not applied to background metadata writes: nothing on this
  resource is written by a sync, so every write here is the user's hand.
  """
  use Ash.Resource.Change

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.force_change_attribute(changeset, :last_touched_at, DateTime.utc_now())
  end
end
