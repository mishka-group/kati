defmodule Kati.Rating.Sample do
  @moduledoc """
  Stand-in data for the log sheet, until watches are a domain.

  Screen 33 is one watch being written down, so this is one map rather than a
  list: the title it is about, the rating, the review as typed, and the three
  facts that make a log worth keeping later — when, where, and who with.

  Everything here is the drawing's own copy. `characters` is stored rather
  than derived from `review` because the two disagree: the drawing prints
  **184 characters** beside a body of a different length, and a counter that
  silently corrects the design would hide that rather than raise it.

  Marked clearly rather than hidden, because sample data that looks like real
  data is how a demo quietly becomes a lie.
  """

  @review "Second time through and the estuary scenes land completely differently once you know what Mara is looking for. The score does most of the work in the last reel."

  @doc "The watch being logged, as screen 33 draws it."
  @spec watch() :: map()
  def watch do
    %{
      title: "Blue Hour",
      seed: "bluehour58",
      meta: "2025 · 1H 52M",
      rewatch: "2nd rewatch",
      rating: 4.5,
      rating_note: "HALF STARS ON · TAP LEFT OR RIGHT OF CENTRE",
      spoilers: "Spoilers hidden",
      review: @review,
      characters: "184 characters",
      context: [
        %{icon: "event", title: "Watched on", sub: "Sun 16 Aug · 21:40"},
        %{icon: "tv", title: "Where", sub: "Lumen+ · living room"},
        %{icon: "group", title: "With", sub: "Jo"}
      ],
      tags: ["slow burn", "coastal", "rewatchable"]
    }
  end

  @doc """
  The two rating scales, the five-star one selected.

  The design labels them `5★` and `10pt`. The star is a glyph rather than a
  character here — see `Kati.Screens.Rating`'s moduledoc — so the first option
  carries its numeral and a `star:` flag instead of a composed string.
  """
  @spec scales() :: [map()]
  def scales do
    [
      %{label: "5", star: true, on: true},
      %{label: "10pt", star: false, on: false}
    ]
  end

  @doc "Absolute path to the poster, or `nil` when that seed was never drawn."
  @spec poster(String.t()) :: String.t() | nil
  def poster(seed), do: Kati.Design.Images.poster(seed)
end
