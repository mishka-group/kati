defmodule Kati.Settings.DetectSample do
  @moduledoc """
  Stand-in auto-detect state, screen 36.

  Manual ticking stays the default; this screen is the opt-in that removes it,
  so the sample has to show the opt-in actually working — something playing
  right now, three sources with real tick counts, and one ambiguous match
  waiting on an answer.

  That last part is the design's argument: an unsure match queues up as a
  question rather than guessing, because a wrong tick pollutes a history the
  user cannot easily audit. A sample with an empty queue would hide the whole
  idea.
  """

  @doc "The mono line under the title."
  @spec sources_line() :: String.t()
  def sources_line, do: "3 sources"

  @doc "The cream banner: the opt-in itself, and what it has done so far."
  @spec banner() :: map()
  def banner do
    %{title: "Detect what you play", meta: "41 EPISODES TICKED FOR YOU", on: true}
  end

  @doc """
  What is playing, how far in, and when it will tick.

  The progress bar states the rule beside the number — "ticks at 90%" — so the
  thing about to happen is legible before it happens.
  """
  @spec now_playing() :: map()
  def now_playing do
    %{
      seed: "hollow71",
      title: "The Long Hollow",
      meta: "S2E6 · LUMEN+ · APPLE TV",
      status: "Live",
      progress: 0.74,
      elapsed: "41:02 / 55:00",
      rule: "ticks at 90%"
    }
  end

  @doc "The four sources, one of which is not installed and offers itself instead."
  @spec sources() :: [map()]
  def sources do
    [
      %{icon: "tv", title: "Apple TV", sub: "Connected · 28 ticks", control: {:switch, true}},
      %{
        icon: "cast",
        title: "Chromecast",
        sub: "On this network · 13 ticks",
        control: {:switch, true}
      },
      %{
        icon: "computer",
        title: "Browser extension",
        sub: "Not installed",
        control: {:pill, "Get"}
      },
      %{
        icon: "phone_iphone",
        title: "This phone",
        sub: "Detects audio from any app",
        control: {:switch, false}
      }
    ]
  end

  @doc "When a play counts, and what never counts."
  @spec rules() :: [map()]
  def rules do
    [
      %{icon: "percent", title: "Tick at", sub: "90% watched", control: :chevron},
      %{
        icon: "help",
        title: "Ask before ticking",
        sub: "Only when the match is unsure",
        control: {:switch, true}
      },
      %{
        icon: "do_not_disturb_on",
        title: "Ignore",
        sub: "Trailers, anything under 5 min",
        control: {:switch, true}
      }
    ]
  end

  @doc "The queued question: a 43-minute play that matches two different titles."
  @spec decision() :: map()
  def decision do
    %{
      seed: "marram15",
      question: "“Marram E3” or “Marram Grass”?",
      sub: "Played 43m on Orbit, 21:10",
      options: ["The series", "The film", "Neither"],
      chosen: "The series"
    }
  end
end
