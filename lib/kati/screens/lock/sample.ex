defmodule Kati.Screens.Lock.Sample do
  @moduledoc """
  What the three lock-screen widgets show at 21:40 on the evening screen 28 is
  also drawn at.

  The design's caption for screen 29 is the specification: *three widget sizes
  off one data model* — what to watch next, how loaded tonight is, and the
  year as a pixel field. So this module is deliberately **one** map with three
  views of it rather than three unrelated blobs; a widget that could disagree
  with the app it came from is worse than no widget.

  The two events at 20:00 and 21:30 are the same two `Kati.Screens.HomeDark`
  draws in *Rest of today*, because it is the same evening.
  """

  # The design's own alphas, as levels. `rgba(255,255,255, .13 / .3 / .55 /
  # .95)` — four steps, not a ramp, which is what keeps a pixel field readable
  # at 7pt when a continuous scale would turn to noise.
  @intensities [
    0x21FFFFFF,
    0x4CFFFFFF,
    0x8CFFFFFF,
    0xF2FFFFFF
  ]

  @doc "The clock block: the date over the time."
  @spec clock() :: map()
  def clock, do: %{date: "Sunday 16 August", time: "21:40"}

  @doc """
  The small widget: what to watch next.

  Its eyebrows are stored in capitals because the drawing types them in
  capitals — there is no `text-transform` on those lines, so `UP NEXT` is the
  copy rather than a styling of *Up next*.
  """
  @spec up_next() :: map()
  def up_next do
    %{
      eyebrow: "UP NEXT",
      title: "The Long Hollow",
      meta: "S2E6 · 18M",
      seed: "hollow71"
    }
  end

  @doc "The small widget beside it: how loaded tonight is."
  @spec tonight() :: map()
  def tonight, do: %{eyebrow: "TONIGHT", count: "6", label: "episodes airing"}

  @doc "The medium widget: what is left of today."
  @spec today() :: map()
  def today do
    %{
      eyebrow: "TODAY · 4 LEFT",
      rows: [
        %{time: "20:00", title: "6 episodes air", now?: true},
        %{time: "21:30", title: "Call Mum", now?: false}
      ]
    }
  end

  @doc """
  The large widget: the year as a pixel field, with its two footnotes.

  78 cells, chunked into three rows of 26. The drawing's `flex-wrap` packs 33
  to a line and leaves a ragged twelve on the third, but 33 cells at 7pt with
  3pt gaps measure 327 inside a 328pt card — one point of slack, which is not
  slack. Three clean rows of 26 divide the same 78 exactly, cost nothing in
  meaning, and cannot clip; `Kati.Screens.Stats` chunks its contribution grid
  the same way and for the same reason.
  """
  @spec year() :: map()
  def year do
    %{
      eyebrow: "THIS YEAR",
      watched: "312h watched",
      streak: "11-night streak",
      rows: Enum.chunk_every(cells(), 26)
    }
  end

  @doc "The design's own 78 cells, as intensity levels 0..3."
  @spec cells() :: [0..3]
  def cells do
    [
      1, 3, 2, 1, 3, 1, 0, 2, 0, 3, 2, 1, 1, 1, 2, 0, 1, 2, 1, 2, 2, 1, 0, 0, 2, 0,
      2, 0, 3, 1, 0, 3, 1, 3, 3, 3, 2, 0, 3, 2, 3, 1, 1, 1, 0, 3, 3, 0, 1, 0, 1, 2,
      2, 1, 0, 0, 2, 1, 2, 2, 2, 1, 1, 0, 0, 0, 0, 0, 1, 3, 2, 1, 2, 2, 2, 3, 2, 3
    ]
  end

  @doc "A cell's colour, by level."
  @spec intensity(0..3) :: integer()
  def intensity(level), do: Enum.at(@intensities, level)

  @doc "The wallpaper seed — the title the Up next widget is about."
  @spec wallpaper() :: String.t()
  def wallpaper, do: "hollow71"
end
