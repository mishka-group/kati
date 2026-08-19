defmodule Kati.Screens.WhatFits.Sample do
  @moduledoc """
  Stand-in runtime data for screen 13, until the Screen domain exists.

  The drawing's own numbers: a 45-minute window, three episodes that fit at
  41, 43 and 44 minutes, and one film that does not — 1h 46m, which is 61
  minutes over. That last row is the point of the screen, so the sample keeps
  it rather than showing four clean matches.

  Both selector rows carry their selection in the data (`45m`, and the `Light`
  mood) because the drawing draws a chosen state for each and a screen with
  nothing chosen would not exercise either.
  """

  @doc "Everything screen 13 draws."
  @spec tonight() :: map()
  def tonight do
    %{
      now: "Sunday, 21:40",
      window: "45 min",
      lengths: [
        %{label: "20m", selected: false},
        %{label: "30m", selected: false},
        %{label: "45m", selected: true},
        %{label: "1h", selected: false},
        %{label: "2h+", selected: false}
      ],
      moods: [
        %{label: "Any mood", selected: false},
        %{label: "Light", selected: true},
        %{label: "Tense", selected: false},
        %{label: "Long-form", selected: false}
      ],
      fits_label: "3 episodes fit",
      fits: [
        %{title: "Ashfall", seed: "ashfall42", meta: "S3 · E2", run: "41m"},
        %{title: "Marram", seed: "marram15", meta: "S2 · E3", run: "43m"},
        %{title: "Salt & Iron", seed: "saltiron33", meta: "S1 · E4", run: "44m"}
      ],
      over_label: "Nothing else fits — nearest film is 1h 46m",
      over: %{
        title: "Quiet Harbour",
        seed: "harbour86",
        meta: "1H 46M · 61 MIN OVER",
        action: "Tomorrow"
      }
    }
  end

  @doc "A row's poster, or `nil` when that seed was never drawn."
  @spec poster(String.t()) :: String.t() | nil
  def poster(seed), do: Kati.Design.Images.poster(seed)
end
