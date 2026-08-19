defmodule Kati.Music.Sample do
  @moduledoc """
  Stand-in music-shelf data, until the Screen domain grows a Music section.

  Screen 21 is deliberately the *same skeleton* as screen 03 — header, segmented
  control, sections — filled with a different medium, and the drawing's own note
  says why: *"the release watcher is section-agnostic"*. So the shapes here
  mirror `Kati.Library.Sample`'s: a list of works with artwork seeds, and a list
  of upcoming releases with a dot.

  `plays` is stored already capitalised because the export writes `41 PLAYS`
  into the markup rather than uppercasing it in CSS — unlike `This month`
  beside it, which is `text-transform:uppercase` and is upcased at render.
  """

  @doc "The header's mono subtitle."
  @spec subtitle() :: String.t()
  def subtitle, do: "418 albums · 61h this year"

  @doc "The three albums on repeat, in the order the row draws them."
  @spec albums() :: [map()]
  def albums do
    [
      %{seed: "albm1", title: "Tidal Works", artist: "Kell Ostrand", plays: "41 PLAYS"},
      %{seed: "albm2", title: "Low Country", artist: "Vesper Line", plays: "28 PLAYS"},
      %{seed: "albm3", title: "Nine Rooms", artist: "Aud Marne", plays: "19 PLAYS"}
    ]
  end

  @doc """
  This month's listening total, and the twenty daily bars under it.

  `{height, tone}` in dp, straight off the drawing: a 40pt field where the
  darker bronze marks the days above the run of ordinary ones. Heights are
  declared rather than derived from a percentage, because nothing measures the
  field back for us and the export's own numbers are the ground truth.
  """
  @spec listening() :: map()
  def listening do
    soft = 0xFFE4D2B0
    strong = 0xFFB08E55

    %{
      label: "This month",
      total: "9h 12m",
      window: "mostly 21:00–23:00",
      bars: [
        {17.6, soft},
        {30.8, soft},
        {13.2, soft},
        {39.6, strong},
        {26.4, soft},
        {35.2, strong},
        {22.0, soft},
        {8.8, soft},
        {30.8, soft},
        {39.6, strong},
        {17.6, soft},
        {26.4, soft},
        {35.2, strong},
        {13.2, soft},
        {22.0, soft},
        {30.8, soft},
        {39.6, strong},
        {26.4, soft},
        {17.6, soft},
        {35.2, strong}
      ]
    }
  end

  @doc "New records from followed artists — the same watcher that feeds screen 05."
  @spec releases() :: [map()]
  def releases do
    [
      %{seed: "albm4", artist: "Kell Ostrand", line: "Estuary Tapes · out Friday"},
      %{seed: "albm5", artist: "Vesper Line", line: "single · out now"}
    ]
  end
end
