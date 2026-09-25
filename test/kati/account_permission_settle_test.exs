defmodule Kati.AccountPermissionSettleTest do
  @moduledoc """
  Screen 40 does not keep a permission read that got no answer (N17).

  ## The defect this exists for

  Right after a hot deploy the *This device* rows all said *Not available
  here*, and `Kati.Permissions.status/1` answered `:granted` over RPC a minute
  later. The rows are read at render; nothing rendered again, so the read taken
  before the bridge could answer stayed on the page as a claim about the phone.

  ## What is asserted, and where it stops

    * the word an unanswered row wears: *Checking…* where the platform answers,
      *Not available here* where it does not — the host, which is what every
      render in this suite is;
    * that `settle/2` asks for one more read exactly when a platform that
      answers has not, and stays quiet otherwise;
    * that both re-read topics are answered without touching the assigns — the
      render they cause is the read.

  What a host cannot show is the bridge coming back: `status/1` is `:unknown`
  here for good. That half is the emulator check in the report.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Screens.Account

  setup do
    installed = Mob.Theme.current()
    on_exit(fn -> Mob.Theme.set(installed) end)

    Kati.Locale.put(:en)
    :ok
  end

  describe "the word an unanswered row wears" do
    test "on a platform that answers, it is checking rather than a claim" do
      assert Account.state_label(:unknown, true) == "Checking…"
      assert fa(fn -> Account.state_label(:unknown, true) end) == "در حال بررسی…"
    end

    test "where nothing will answer, it is not available" do
      assert Account.state_label(:unknown, false) == "Not available here"
    end

    test "the host is a platform that does not answer" do
      refute Kati.Permissions.platform_answers?()
      assert Account.state_label(:unknown) == "Not available here"
    end

    test "an answered permission is untouched" do
      assert Account.state_label(:granted) == "Allowed"
      assert Account.state_label(:denied) == ""
    end
  end

  describe "settle/2" do
    test "asks for one more read when a platform that answers has not" do
      permissions = Kati.Account.Sample.account().permissions

      assert Account.settle(permissions, true) == :ok
      assert_received {:kati, :permissions_settle, nil}
      refute_received {:kati, :permissions_settle, nil}
    end

    test "stays quiet where no answer is coming" do
      assert Account.settle(Kati.Account.Sample.account().permissions, false) == :ok
      refute_received {:kati, :permissions_settle, _}
    end

    test "stays quiet when there is nothing to ask about" do
      assert Account.settle([], true) == :ok
      refute_received {:kati, :permissions_settle, _}
    end

    test "a host mount asks for nothing" do
      mount_screen(Account)
      refute_received {:kati, :permissions_settle, _}
    end
  end

  describe "the re-read topics" do
    test "both render the page again with its assigns as they were" do
      view = mount_screen(Account)

      for topic <- [:permissions_settle, :resumed] do
        again = render_info(view, {:kati, topic, nil})

        assert assigns(again).account == assigns(view).account
        assert Enum.count(texts(again), &(&1 == "Not available here")) == 3
      end
    end
  end

  defp fa(fun) do
    Kati.Locale.put(:fa)

    try do
      fun.()
    after
      Kati.Locale.put(:en)
    end
  end

  defp texts(view) do
    for node <- flatten(view),
        text = (Map.get(node, :props) || %{})[:text],
        is_binary(text),
        do: text
  end
end
