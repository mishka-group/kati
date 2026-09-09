defmodule Kati.PlanQrScopeTest do
  @moduledoc """
  Board 316 — the QR's promise, on both sides of it.

  The encode stays and the promise changes, which is the board's own ruling and
  its arithmetic: *"A QR holds about 2,900 bytes and 35 meals with ingredients
  is tens of kilobytes — widening it is not a decision, it is a physical
  impossibility."*

  `Kati.Meals.SampleShare.qr_scope/0` has said `SETTINGS ONLY` on the mono line
  since it was written. What 316 found is that the rest of the card had not
  followed: it was titled *Scan to import this plan*, said nothing about the
  meals, and offered no route for the thing it could not carry. And on the
  receiving side, screen 120 counted **29 new** for an arrival that brings
  none — *"the one thing a code-import must never do is print a meal count it
  cannot deliver."*

  Both halves are pinned here, and each is pinned against the OTHER rather than
  against a literal wherever it can be: the card's promise is compared with the
  scope word, and the receiving side's counts with the card's promise.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Meals.SampleShare
  alias Kati.Screens.PlanImport
  alias Kati.Screens.PlanShare

  describe "screen 50 — the card, reworded" do
    test "the title says what a scan does, which is set the plan up" do
      texts = texts(mount_screen(PlanShare))

      assert "Scan to set up this plan" in texts
      refute "Scan to import this plan" in texts
    end

    test "and the sentence under it names what does not travel" do
      texts = texts(mount_screen(PlanShare))

      assert SampleShare.qr_body() in texts
      assert SampleShare.qr_body() =~ "not the 35 meals"
      assert SampleShare.qr_body() =~ "empty Cutting v3"
    end

    test "the mono line and the sentence agree, which is the whole board" do
      # The card's two halves said different things: the mono line has always
      # been honest and the title was not. Pinned against each other so neither
      # can drift back.
      assert SampleShare.share().qr_uri =~ SampleShare.qr_scope()
      refute SampleShare.share().qr_uri =~ "35 MEALS"
      refute SampleShare.share().qr_title =~ "import"
    end

    test "and the card offers the route that does carry the meals" do
      texts = texts(mount_screen(PlanShare))

      assert "Send the whole plan" in texts

      assert {:noreply, socket} =
               PlanShare.handle_tap(:send_whole_plan, mount_screen(PlanShare).socket)

      assert socket.__mob__.nav_action == {:push, Kati.Screens.Backup, %{}}
    end

    test "Copy link and Share are untouched — both are still true about the code" do
      texts = texts(mount_screen(PlanShare))

      assert "Copy link" in texts
      assert "Share" in texts
    end

    test "Scan a plan reaches the receiving side, in its code state" do
      assert {:noreply, socket} =
               PlanShare.handle_tap(:scan_plan, mount_screen(PlanShare).socket)

      assert socket.__mob__.nav_action == {:push, PlanImport, %{from: :code}}
    end
  end

  describe "screen 120 — the receiving side" do
    test "counts nothing, because a code delivers nothing to count" do
      assert Enum.map(PlanImport.counts(:code), & &1.value) == ["0", "0", "0"]

      # And the file arrival is unchanged: 120 was drawn as a file import and
      # still is one.
      assert Enum.map(PlanImport.counts(), & &1.value) == ["29", "4", "2"]
    end

    test "the header verb carries no meal count" do
      code = PlanImport.plan(:code)

      assert code.action == "Set up"
      refute code.action =~ "35"
      assert code.uri =~ SampleShare.qr_scope()

      assert PlanImport.plan().action == "Import 35"
    end

    test "three things arrive and one says it cannot" do
      texts = texts(mount_screen(PlanImport, %{from: :code}))

      for row <- SampleShare.carried() do
        assert row.title in texts
        assert row.sub in texts
      end

      assert "The 35 meals" in texts
      assert "Ask for the file — a code cannot hold them" in texts
    end

    test "and the conflict queue is not drawn, because a code cannot conflict" do
      texts = texts(mount_screen(PlanImport, %{from: :code}))

      refute "CONFLICTS · KEEP WHICH?" in texts
      refute PlanImport.conflict().title in texts
      refute "COMING IN AS-IS" in texts
    end

    test "a file arrival is the page it always was" do
      texts = texts(mount_screen(PlanImport))

      assert "CONFLICTS · KEEP WHICH?" in texts
      assert "Import 35" in texts
      refute "The 35 meals" in texts
    end
  end

  defp texts(view) do
    view
    |> tree()
    |> find_all(:text)
    |> Enum.map(&(&1.props[:text] || ""))
    |> Enum.reject(&(&1 == ""))
  end
end
