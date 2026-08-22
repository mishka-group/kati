defmodule Kati.Services.Sample do
  @moduledoc """
  Screens 92 and 94, as the drawings captured them.

  The fallback for a device where nobody has opened screen 92 yet, and the
  fixture the frames are compared against. Prices are the drawing's own and
  match `Kati.Subscriptions.Sample`'s to the penny for the three services both
  screens name — screen 92 says it owns them and screen 23 reads them, so a
  drifted figure here would be two screens disagreeing about one number.
  """

  @doc "The three services on the account, in the order screen 92 lists them."
  @spec subscribed() :: [map()]
  def subscribed do
    [
      %{badge: "L", name: "Lumen+", price: "£8.99", pence: 899},
      %{badge: "O", name: "Orbit", price: "£13.99", pence: 1399},
      %{badge: "K", name: "Kino", price: "£11.49", pence: 1149}
    ]
  end

  @doc "Services that cost nothing and carry ads."
  @spec free() :: [map()]
  def free do
    [
      %{badge: "A", name: "Aria Free", price: nil, pence: nil},
      %{badge: "D", name: "Dispatch", price: nil, pence: nil}
    ]
  end

  @doc """
  The figure screen 92's Money row prints — and it is screen 23's, not this
  screen's.

  Worth being exact about, because the two numbers look like they should match
  and do not. The three services listed above the row cost 8.99 + 13.99 + 11.49
  = **£34.47**. The row says **£46.47**, which is screen 23's own total across
  the five services on the account, including the two this screen's *Subscribed
  · 3* group does not list.

  That is not a mistake in the drawing: the row is a link into screen 23 and it
  quotes screen 23's answer, which is the whole point of a link. What screen 92
  owns is the **prices**; what screen 23 owns is the **account total**, and the
  row says `Subscriptions` on it.

  `Kati.ServicesTest` pins both figures and their difference, so a change to
  either shows up as a change to the relationship rather than as one number
  quietly following the other.
  """
  @spec monthly_total() :: String.t()
  def monthly_total, do: "£46.47"

  @doc "What the three listed services actually add up to."
  @spec listed_total() :: String.t()
  def listed_total, do: "£34.47"

  @doc "The everything-else row's count, which is JustWatch's and not Kati's."
  @spec catalogue_count() :: String.t()
  def catalogue_count, do: "Show all 47"
end
