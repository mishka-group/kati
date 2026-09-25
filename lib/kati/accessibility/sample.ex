defmodule Kati.Accessibility.Sample do
  @moduledoc """
  The copy screen 41 draws: its subtitle, the note, and the five things Kati
  guarantees about every screen. Copy is the design's own, from
  `test/design/screens/41.html`, except where the design claimed what the app
  does not do (A5): 235% Dynamic Type, and *Increase contrast*, which only ever
  restyled this one page. The Up next card and the VoiceOver sentence are the
  reader's own now — see `Kati.Screens.Accessibility.load/1`.
  """

  @doc "Everything screen 41 shows, in the order it shows it."
  @spec spec() :: map()
  def spec do
    %{
      subtitle: "Follows your system text size",
      note:
        "At the largest sizes, rows become stacks and icon-only buttons grow " <>
          "labels. Nothing truncates — cards get taller instead.",
      built_in: built_in()
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
        sub: "Follows your system text size · no truncation",
        toggle: true
      },
      %{
        icon: "motion_blur",
        title: "Reduce motion",
        sub: "Cross-fades instead of slides",
        toggle: true
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
end
