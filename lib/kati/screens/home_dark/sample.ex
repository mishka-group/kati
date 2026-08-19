defmodule Kati.Screens.HomeDark.Sample do
  @moduledoc """
  Home's content at the one moment screens 28 and 29 are both drawn at.

  ## Why this moment is pinned rather than computed

  `Kati.Screens.Home` reads the device clock, and should. This screen does
  not, because it is not a second Home — it is Home **held still** so the dark
  palette can be compared against its drawing. Screen 29 draws the lock screen
  of the same evening, down to the same two events at 20:00 and 21:30, so the
  two pages have to agree about what time it is or they stop being one design.

  When dark stops being a separate page and becomes `Kati.Shell`'s `mode`,
  this module goes with it and the real clock takes over.
  """

  @doc "The evening screens 28 and 29 share."
  @spec moment() :: map()
  def moment do
    %{date: "Sunday · 16 August", greeting: "Good evening", last_check: "last check 18:02"}
  end

  @doc """
  The New-this-week card, kept as its two drawn lines.

  The drawing breaks the headline with a `<br>` rather than letting it wrap,
  so the break is content and is stored as such.
  """
  @spec inbox() :: map()
  def inbox do
    %{
      headline: ["3 new episodes", "are waiting"],
      sub: "One premiere · two titles leave Lumen+ on Friday",
      cta: "Open inbox",
      posters: ~w(ashfall42 marram15 harbour86)
    }
  end

  @doc "The two titles part-watched, with the fraction the drawing's bar shows."
  @spec continue() :: [map()]
  def continue do
    [
      %{title: "The Long Hollow", meta: "S2 · E6 · 18m left", progress: 0.62, seed: "hollow71"},
      %{title: "Salt & Iron", meta: "S1 · E3 · 41m left", progress: 0.24, seed: "saltiron33"}
    ]
  end

  @doc """
  What is left of the evening.

  `now?` carries the accent rail, and it is the only orange on the card —
  orange means new or now and the 21:30 reminder is neither yet.
  """
  @spec rest_of_today() :: [map()]
  def rest_of_today do
    [
      %{
        time: "20:00",
        title: "The Long Hollow — S2E6",
        meta: "Airs tonight · Lumen+",
        now?: true
      },
      %{time: "21:30", title: "Call Mum", meta: "Repeats weekly", now?: false}
    ]
  end
end
