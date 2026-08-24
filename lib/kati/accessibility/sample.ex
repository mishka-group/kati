defmodule Kati.Accessibility.Sample do
  @moduledoc """
  The accessibility spec screen 41 draws, as data.

  The drawing is the spec: the app's densest card rendered at 235% Dynamic
  Type, the six guarantees as a switch list, and the sentence VoiceOver
  actually speaks on an episode row. Copy is the design's own, from
  `test/design/screens/41.html`.

  `up_next` is the same episode `Kati.Library.Sample.series/0` carries — the
  point of the card is that the *ordinary* screen survives the largest type,
  so it must be the ordinary screen's content.
  """

  @doc "Everything screen 41 shows, in the order it shows it."
  @spec spec() :: map()
  def spec do
    %{
      subtitle: "Dynamic Type at 235%",
      up_next: up_next(),
      note:
        "At the largest sizes, rows become stacks and icon-only buttons grow " <>
          "labels. Nothing truncates — cards get taller instead.",
      built_in: built_in(),
      voiceover: voiceover()
    }
  end

  @doc "The Up next card, at the size the drawing renders it."
  @spec up_next() :: map()
  def up_next do
    %{
      label: "Up next",
      title: "The Long Hollow",
      lines: "Season 2, episode 6\n18 minutes left",
      resume: "Resume",
      mark: "Mark watched"
    }
  end

  @doc """
  The six guarantees, each stated as a behaviour rather than a feature name.

  "Colour is never alone" is the one that constrains every other screen: the
  status dots on Home and in the inbox all carry a word or a glyph beside
  them, which is why this list can claim it.
  """
  @spec built_in() :: [map()]
  def built_in do
    [
      %{
        icon: "record_voice_over",
        title: "VoiceOver",
        sub: "Every control labelled · posters described",
        toggle: true
      },
      %{
        icon: "format_size",
        title: "Dynamic Type",
        sub: "Up to 235% · no truncation",
        toggle: true
      },
      %{
        icon: "motion_blur",
        title: "Reduce motion",
        sub: "Cross-fades instead of slides",
        toggle: true
      },
      %{
        icon: "contrast",
        title: "Increase contrast",
        sub: "Hairlines darken, shadows drop",
        toggle: false
      },
      %{
        icon: "touch_app",
        title: "Touch targets",
        sub: "Nothing under 44×44",
        toggle: true
      },
      %{
        icon: "colorize",
        title: "Colour is never alone",
        sub: "Every dot has a label or icon",
        toggle: true
      }
    ]
  end

  @doc "What VoiceOver says on one episode row, written out rather than described."
  @spec voiceover() :: map()
  def voiceover do
    %{
      label: "EPISODE ROW",
      reads:
        "“Episode 6, The Undertow. 55 minutes. Airs 20 August. Not watched. " <>
          "Double-tap to mark watched.”"
    }
  end
end
