Code.require_file("../support/screen_sweep.exs", __DIR__)
Code.require_file("../support/design_literals.exs", __DIR__)

defmodule Kati.ScreenMoneyTest do
  @moduledoc """
  The recurring card on screen 122 reads the services the reader actually pays
  for, not the drawing's four.

  It answered `Kati.Money.Sample.recurring/0` on every device — Lumen+, Orbit,
  Kino and Aria Free — so a reader who had told Kati about one service saw four
  they did not, with prices that were not theirs. `Kati.Subscriptions.ledger/0`
  is the same read screen 23 draws; this file is the card.
  """
  use Mob.ScreenCase, async: false

  alias Kati.DesignLiterals
  alias Kati.ScreenSweep
  alias Kati.Screens.Money
  alias Kati.Services.Service

  @prefix "screen-122-test-"

  setup do
    delete_rows!()
    on_exit(&delete_rows!/0)
    :ok
  end

  test "with nothing subscribed the card says so, and draws none of the four" do
    assert {:ok, _socket, tree} = ScreenSweep.render(Money)
    texts = DesignLiterals.rendered(tree)

    assert "no subscriptions yet" in texts

    for drawn <- ["lumen+", "orbit", "kino", "aria free"] do
      refute drawn in texts, "the drawing's #{drawn} is still on the page"
    end
  end

  test "a stored service is the row, with its own price" do
    {:ok, _service} =
      Ash.create(Service, %{
        name: @prefix <> "Cinema",
        monthly_pence: 1234,
        badge: "C"
      })

    assert {:ok, _socket, tree} = ScreenSweep.render(Money)
    texts = DesignLiterals.rendered(tree)

    assert String.downcase(@prefix <> "Cinema") in texts
    assert "£12.34" in texts

    # The header and the hero read the same store: one service, no expenses,
    # and a total that is actually what is paid rather than the drawing's
    # £46.47.
    assert "1 service · 0 expenses this month" in Enum.map(texts, &String.downcase/1)
    assert "£46.47" not in texts, "the drawing's total is still on the page"
    refute "up £4.00 since march — orbit raised its price" in texts

    for drawn <- ["lumen+", "orbit", "kino", "aria free"] do
      refute drawn in texts
    end
  end

  defp delete_rows! do
    Kati.Repo.query!("DELETE FROM services WHERE name LIKE ?1", [@prefix <> "%"])
  end
end
