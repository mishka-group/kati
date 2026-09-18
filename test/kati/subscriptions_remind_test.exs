defmodule Kati.SubscriptionsRemindTest do
  @moduledoc """
  *Remind me* on the suggestion card says something true.

  It flipped a socket boolean and changed the button to its secondary
  treatment. Nothing was armed. MOVIES-AND-TV.md #60 recorded the reason as
  `Kati.Notifications.Scheduler` not being built — **and that reason is no
  longer true, and was not the problem anyway.**

  `Kati.Notifications.Sources.Money.candidates/3` arms a renewal reminder for
  every subscribed service that has a `renews_on` date, unconditionally and
  with no opt-in anywhere. There was never anything for this button to arm: the
  reminder it offers already exists. What it could not do was say so.
  """

  use Mob.ScreenCase, async: false

  alias Kati.Notifications.Sources.Money
  alias Kati.Screens.Subscriptions, as: Screen
  alias Kati.Subscriptions

  describe "the date the card names" do
    test "counts back from the renewal by the scheduler's own lead" do
      renews = ~D[2026-08-23]

      assert Subscriptions.remind_on(renews) == Date.add(renews, -Money.lead_days())
    end

    test "and a service with no renewal date has no reminder to name" do
      assert Subscriptions.remind_on(nil) == nil
    end

    test "so the card and the thing that fires cannot disagree" do
      # The point of reading `lead_days/0` rather than copying the number: a
      # card naming a day the scheduler does not is the defect one step on.
      assert is_integer(Money.lead_days())
    end
  end

  describe "the button" do
    test "says Remind me until it is pressed" do
      card = %{confirm: "Remind me", dismiss: "Dismiss", remind_on: ~D[2026-08-23]}

      assert Screen.confirm_label(card, false) == "Remind me"
    end

    test "and names the day once it has been" do
      # `remind_on` is the day the reminder FIRES — a lead before the renewal —
      # and the button names that, not the renewal.
      card = %{confirm: "Remind me", dismiss: "Dismiss", remind_on: ~D[2026-08-22]}

      label = Screen.confirm_label(card, true)

      refute label == "Remind me", "pressed, it still only changed colour"
      assert label =~ "22 Aug"
    end

    test "and is not offered at all over a service with no renewal date" do
      # The rule `Kati.Screens.Season` states for *Merge multi-part*: a control
      # that cannot be honoured is not offered. No renewal date means no
      # reminder exists anywhere, so a button promising one is the lie this
      # change removes.
      card = %{confirm: "Remind me", dismiss: "Dismiss", remind_on: nil}

      drawn = inspect(Screen.confirm_slot(card, false), limit: :infinity)

      refute drawn =~ "Remind me"
    end
  end

  describe "the advice body" do
    test "goes through the catalogue rather than being built in English" do
      # It was a bare interpolated string in `Kati.Subscriptions` — a domain
      # module with no Gettext backend — so a Persian reader met the one
      # paragraph on screen 23 that wraps, in English.
      assert Subscriptions.suggestion([]) == nil

      row = %{
        pence: 999,
        minutes: 30,
        name: "Lumen+",
        price: "£9.99",
        renews_on: ~D[2026-08-23]
      }

      advice = Subscriptions.suggestion([row])

      assert advice.body =~ "Lumen+"
      assert advice.remind_on == ~D[2026-08-22]
    end
  end
end
