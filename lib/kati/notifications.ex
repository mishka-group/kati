defmodule Kati.Notifications do
  @moduledoc """
  The one place that knows what Kati intends to tell you, and when.

  Six domains want reminders and both platforms cap the **app** rather than the
  feature, so somebody has to divide a fixed number of slots between them. That
  somebody is this domain, written before the six reminder features rather than
  retrofitted into them — `Kati.Notifications.Scheduler`'s moduledoc gives the
  full argument.

  Only one resource is persisted. Everything else in the namespace is a pure
  module over structs:

    * `Kati.Notifications.Pending` — the rows. One per intended notification,
      keyed on a deterministic id.
    * `Kati.Notifications.Scheduler` decides, `Kati.Notifications.Reconcile`
      diffs, `Kati.Notifications.Delivery` applies. None of them touches a
      database, which is what makes "six hundred candidates in, fifty out, and
      here are the fifty" an assertion about a value.

  The store arrived after the decision layer and the decision layer did not
  change to receive it, which is the clearest evidence the split was in the
  right place: `Kati.Notifications.Pending.to_armed/1` is the only function that
  crosses between them.
  """

  use Ash.Domain, validate_config_inclusion?: false

  resources do
    resource Kati.Notifications.Pending
  end
end
