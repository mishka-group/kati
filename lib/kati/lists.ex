defmodule Kati.Lists do
  @moduledoc """
  Hand-made lists: a name, an order, and the titles in it.

  Screen 12 draws them and, until this domain existed, drew somebody else's
  three on every device — `Best of 2026`, `Rainy Sunday`, `Recommended by Jo` —
  while its `+` prepended a row titled `New list` to a socket assign that was
  lost the moment you went back. MOVIES-AND-TV.md #106.

  Two resources, which is what the board needs and no more:

    * `Kati.Lists.List` — the name, and the two flags the board draws as
      badges (`ranked`, `shared`).
    * `Kati.Lists.Membership` — one row per title in one list, carrying the
      position that makes a ranked list ranked.

  Membership references `Kati.Media.TrackedTitle` and not the cache, for the
  reason every durable row in this app does: a list is about a title the reader
  KEEPS, and the cache is evicted.
  """
  use Ash.Domain, otp_app: :kati

  resources do
    resource Kati.Lists.List
    resource Kati.Lists.Membership
  end
end
