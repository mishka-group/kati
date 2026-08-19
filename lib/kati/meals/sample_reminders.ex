defmodule Kati.Meals.SampleReminders do
  @moduledoc """
  Meal reminders — screen 51, as data.

  A stand-in for the Meals domain. The copy is the design's own, from
  `.scratch/design/screens/51.html`.

  Both halves of the reminder are drawn as the **notifications they actually
  become**, not as settings that describe them: a 20:00 preview listing what to
  prep, and a 15-minute warning with the three buttons you can press without
  opening the app. That is why each half carries a `notification` map — the
  preview is the specification.

  `manners` is the counterweight. Meals is the one section allowed to push by
  default, because a reminder that arrives after dinner is worthless, and the
  price of that permission is quiet hours, calendar awareness, a stop after two
  skips, and a silent mode that behaves like the release watcher's Home card.
  """

  @doc "Everything screen 51 shows, in the order it shows it."
  @spec reminders() :: map()
  def reminders do
    %{
      subtitle: "Cutting v3",
      day_before: day_before(),
      on_the_day: on_the_day(),
      manners: manners(),
      note:
        "Meals are the one section allowed to push by default — a reminder " <>
          "that arrives after dinner is worthless. Every other section stays " <>
          "quiet unless you ask."
    }
  end

  @doc "The evening preview, on cream, with the two things it may mention."
  @spec day_before() :: map()
  def day_before do
    %{
      icon: "nights_stay",
      title: "Evening preview",
      cadence: "EVERY DAY AT 20:00",
      on: true,
      notification: %{
        from: "KATI · NOW",
        title: "Tomorrow: 5 meals, 2 need prep",
        body: "Soak the oats tonight and move the chicken to the fridge."
      },
      options: [
        %{
          icon: "checklist",
          title: "List what needs prep",
          sub: "Only meals with an overnight step",
          on: true
        },
        %{
          icon: "shopping_cart",
          title: "Flag missing ingredients",
          sub: "Cross-checked with the shopping list",
          on: true
        }
      ]
    }
  end

  @doc """
  The meal warning, with the three actions it carries.

  They are on the notification, not on this screen: the footnote — "Tick it
  straight from the notification" — is the claim, and drawing the buttons
  inside the preview is how the drawing proves it.
  """
  @spec on_the_day() :: map()
  def on_the_day do
    %{
      icon: "wb_twilight",
      title: "At each meal",
      cadence: "15 MIN BEFORE · 5 TIMES A DAY",
      on: true,
      notification: %{
        from: "KATI · 19:15",
        title: "Dinner in 15 minutes",
        body: "Miso salmon, greens, rice · 620 kcal",
        actions: ["Eaten", "Skip", "Snooze"]
      },
      foot: "Tick it straight from the notification — no need to open the app"
    }
  end

  @doc "The four rules that keep a pushing section civil."
  @spec manners() :: [map()]
  def manners do
    [
      %{
        icon: "bedtime",
        title: "Quiet hours",
        sub: "23:00 – 06:30 · nothing fires",
        on: true
      },
      %{
        icon: "event_busy",
        title: "Skip when busy",
        sub: "No nudge during a calendar event",
        on: true
      },
      %{
        icon: "do_not_disturb_on",
        title: "Stop after 2 skips",
        sub: "Stays quiet for the rest of the day",
        on: true
      },
      %{
        icon: "inbox",
        title: "Or keep it silent",
        sub: "Home card only, like the release watcher",
        on: false
      }
    ]
  end
end
