defmodule Kati.Screens.UpNext.Sample do
  @moduledoc """
  Stand-in queue data for screen 10, until the Screen domain exists.

  Every string here is the drawing's own copy, not an invention: the counts in
  the subtitle and in both section labels, the season/episode lines, the
  runtimes, and the "4 MONTHS AGO" that is the whole argument for the cold
  section existing at all.

  The section labels are stored whole (`"Ready to watch · 12"`) rather than
  assembled from a count, because the drawing's number and the drawing's list
  length disagree on purpose — it says twelve are ready and shows four, the way
  a real queue is longer than one screen. Computing the label from
  `length(ready)` would quietly rewrite the design to say four.
  """

  @doc "The queue, as screen 10 draws it."
  @spec queue() :: map()
  def queue do
    %{
      subtitle: "12 ready · 4 airing soon",
      ready_label: "Ready to watch · 12",
      cold_label: "Gone cold · 3",
      hero: %{
        title: "The Long Hollow",
        seed: "hollow71",
        meta: "S2 · E6 · 18M LEFT",
        progress: 0.62
      },
      ready: [
        %{title: "Ashfall", seed: "ashfall42", meta: "S3 · E2 · 48m"},
        %{title: "Marram", seed: "marram15", meta: "S2 · E3 · 52m"},
        %{title: "Salt & Iron", seed: "saltiron33", meta: "S1 · E4 · 41m"},
        %{title: "The Cartographer", seed: "cartog60", meta: "S2 · E1 · 58m"}
      ],
      cold: [
        %{
          title: "The Quiet Ones",
          seed: "quietones12",
          meta: "S1 · E3 · 4 MONTHS AGO",
          action: "Drop"
        }
      ]
    }
  end

  @doc """
  The hero still, at the 700x400 crop the drawing asks for.

  `Kati.Design.Images.hero/1` would answer with the 900x740 crop, which is a
  different photograph of the same seed and a different shape — this card is
  landscape, so the landscape crop is the one to fetch.
  """
  @spec hero_art() :: String.t() | nil
  def hero_art, do: Kati.Design.Images.path("hollow71", {700, 400})

  @doc "A row's poster, or `nil` when that seed was never drawn."
  @spec poster(String.t()) :: String.t() | nil
  def poster(seed), do: Kati.Design.Images.poster(seed)
end
