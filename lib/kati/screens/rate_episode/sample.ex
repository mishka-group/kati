defmodule Kati.Screens.RateEpisode.Sample do
  @moduledoc """
  Stand-in data for the episode rating sheet, until a real log exists to draw.

  `.scratch/design/screens/144.html` draws one live sheet and hangs two
  labelled swatches under it. `sheet/0` is the live half: the episode being
  rated, four stars and a half, and a review not yet written. `context` is the
  three rows the drawing fills in — `Tonight · 21:40`, `Lumen+ · living room`,
  `Jo` — copied exactly rather than composed, for the reason
  `Kati.Rating.Sample` gives: sample data that looks derived is how a demo
  quietly drifts from the frame it was captured from.

  `masked_headline` sits beside `headline` rather than being derived at the
  markup, because on a real log it is not derivable from the string: `S2 E6 ·
  The Undertow` cannot be turned back into `S2 E6 · Episode 6` without the
  episode number, which only `Kati.Screens.RateEpisode.shaped/4` still has.
  Both sides therefore carry the pair, and this one carries the board's.

  `previous` stays `nil` — the live sheet the board draws is a first watch, so
  no cream card sits above its input. `reference_verdict/0` is the separate
  thing: the verdict the board's own **rewatch swatch** quotes, which is not
  this sheet's data and is never mixed into it. See
  `Kati.Screens.RateEpisode`'s moduledoc for why the swatch draws a frozen
  verdict where the spoiler swatch draws a live headline — one has a live twin
  to derive and the other has nothing to derive it from.
  """

  @doc "Screen 144's live sheet, exactly as its frame draws it."
  @spec sheet() :: map()
  def sheet do
    %{
      headline: "S2 E6 · The Undertow",
      masked_headline: "S2 E6 · Episode 6",
      show_title: "The Long Hollow",
      spoiler_safe?: false,
      rewatch?: false,
      rating: 4.5,
      review: "",
      context: [
        %{icon: "event", title: "Watched on", sub: "Tonight · 21:40", trailing: "now"},
        %{icon: "tv", title: "Where", sub: "Lumen+ · living room", trailing: nil},
        %{icon: "group", title: "With", sub: "Jo", trailing: nil}
      ],
      previous: nil
    }
  end

  @doc """
  The verdict screen 144's rewatch swatch quotes, in `previous_verdict/2`'s
  own shape.

  `rating_label` is `"4"` and not `"★4"`: the star beside it is a Material
  Symbol `Kati.Screens.RateEpisode.verdict_meta/1` draws as its own node,
  because no typeface Kati ships has U+2605 — the defect screen 08 shipped and
  `Kati.Screens.Rating`'s moduledoc records at length.
  """
  @spec reference_verdict() :: map()
  def reference_verdict do
    %{
      date: "3 Mar 2024",
      rating_label: "4",
      review:
        "The estuary scenes land completely differently once you know what Mara is looking for."
    }
  end
end
