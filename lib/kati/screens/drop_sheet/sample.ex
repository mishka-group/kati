defmodule Kati.Screens.DropSheet.Sample do
  @moduledoc """
  `.scratch/design/incoming/149.html` exactly as it is drawn, until a real
  gone-cold title exists to draw instead.

  `The Quiet Ones` is not invented for this board — it is the one title this
  app already uses everywhere a "gone cold, then dropped" specimen is needed:
  `Kati.Screens.UpNext.Sample.queue/0`'s cold section, and
  `Kati.Activity.Sample.earlier/0`'s `"Dropped The Quiet Ones after S1E3"` row,
  are the same show at the same seed (`quietones12`). Typing a second title
  here would give the app two "the one that got away" shows instead of one.

  `season` and `episode` are integers, not the pre-joined `"S1 E3"` string
  `Kati.Screens.UpNext` builds for its own row — this board changes the
  number, not the sentence, so `Kati.Screens.DropSheet` needs the two ints
  apart.
  """

  @doc "Screen 149 exactly as it is drawn."
  @spec sheet() :: map()
  def sheet do
    %{
      tracked: nil,
      title: "The Quiet Ones",
      seed: "quietones12",
      cold_label: "GONE COLD · 4 MONTHS",
      season: 1,
      episode: 3
    }
  end
end
