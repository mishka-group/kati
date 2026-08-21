defmodule Kati.Onboarding.Sample do
  @moduledoc """
  The copy for the three onboarding steps screen 38 draws.

  It is sample data only in the sense that nothing is persisted yet — the
  words are the design's, from `.scratch/design/screens/38.html`, because the
  whole point of an onboarding screen is the sentences. When the flow becomes
  real, the titles stay and only `selected?` moves.

  The four starter posters are the design's own seeds, so the grid shows the
  pictures the drawing shows rather than four grey rectangles.
  """

  @doc """
  Steps 1, 3 and 4 — welcome, the notification decision, the first title.

  Step 2 (the section picker) is not in this drawing; the export's caption
  calls these "the three steps missing around the section picker".
  """
  @spec flow() :: map()
  def flow do
    %{welcome: welcome(), telling: telling(), first_title: first_title()}
  end

  @doc "Step 1 — what the app is, in one sentence and one button."
  @spec welcome() :: map()
  def welcome do
    %{
      title: "One place for\nwhat you keep",
      body:
        "Films, shows, books, habits — each one is a shelf, and all of them " <>
          "feed a single calendar. Start with one and add the rest whenever.",
      cta: "Get started"
    }
  end

  @doc """
  Step 3 — how loudly the app may speak.

  Asked before any permission is requested, and answered "Quietly" by default:
  the design's own position, and the reason screen 40 can say notifications
  are "Not yet asked".
  """
  @spec telling() :: map()
  def telling do
    %{
      title: "How should we tell you?",
      body: "Kati checks for new episodes on its own. You choose how loudly it mentions them.",
      options: [
        %{
          icon: "inbox",
          title: "Quietly",
          sub: "A card on home. Nothing buzzes.",
          selected?: true
        },
        %{
          icon: "notifications",
          title: "Notify me",
          sub: "A push when something lands.",
          selected?: false
        },
        %{
          icon: "mail",
          title: "Weekly digest",
          sub: "One summary, Sundays at 18:00.",
          selected?: false
        }
      ]
    }
  end

  @doc "Step 4 — one title, so the app is never empty on day one."
  @spec first_title() :: map()
  def first_title do
    %{
      title: "Add your first title",
      body: "Pick something you are watching now — the calendar fills itself from there.",
      posters: [
        %{title: "The Long Hollow", seed: "hollow71", selected?: true},
        %{title: "Ashfall", seed: "ashfall42", selected?: false},
        %{title: "Marram", seed: "marram15", selected?: false},
        %{title: "Nightbirds", seed: "nightbirds24", selected?: false}
      ],
      cta: "Finish setup",
      skip: "Skip — I’ll add things later"
    }
  end
end
