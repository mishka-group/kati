defmodule Kati.Settings.StatesSample do
  @moduledoc """
  The copy screen 27 puts in each of the states nobody designs.

  This is a reference sheet rather than a screen with a domain behind it, so
  the "sample" here is the specimen itself: the empty state's invitation, the
  three fading skeleton rows, the offline promise, the failed check, and the
  undo bar. Every one of them is real copy from the drawing, because the point
  of the sheet is the wording as much as the layout.

  ## The skeleton's opacities are baked, not applied

  The drawing fades its three rows to 1, .75 and .5. No Mob node carries an
  `opacity` prop, so each row's colours are composited against the `#EFECE7`
  paper here instead — the same pixels, arrived at arithmetically. The shadow
  alphas are scaled by the same factors, or the third row would sit on a
  shadow it has no body to cast.
  """

  @doc "Empty — the state that has to sell the app rather than apologise."
  @spec empty() :: map()
  def empty do
    %{
      icon: "movie",
      title: "No titles yet",
      body: "Add one thing you are watching and the calendar starts filling itself.",
      action: "Add a title",
      secondary: "or import a backup"
    }
  end

  @doc """
  The three skeleton rows, already composited against paper.

  `card` is `#FBFAF8` over `#EFECE7`, `bar` is `#E7E3DC` over the same, each at
  the row's own opacity; `shadow` is the design's two-layer card recipe with
  both alphas scaled to match.
  """
  @spec skeletons() :: [map()]
  def skeletons do
    [
      %{
        card: 0xFFFBFAF8,
        bar: 0xFFE7E3DC,
        shadow: "0 1 2 0 #0A1A1917 | 0 12 24 -18 #B31A1917"
      },
      %{
        card: 0xFFF8F7F4,
        bar: 0xFFE9E5DF,
        shadow: "0 1 2 0 #081A1917 | 0 12 24 -18 #861A1917"
      },
      %{
        card: 0xFFF5F3F0,
        bar: 0xFFEBE8E2,
        shadow: "0 1 2 0 #051A1917 | 0 12 24 -18 #591A1917"
      }
    ]
  end

  @doc "Offline — a promise about the ticks, not an apology for the network."
  @spec offline() :: map()
  def offline do
    %{icon: "cloud_off", title: "Offline", sub: "Ticks are saved and will sync later"}
  end

  @doc "A failed check, with the last success named and a way to try again."
  @spec error() :: map()
  def error do
    %{
      icon: "error",
      title: "Couldn’t check for releases",
      sub: "Last success 6h ago",
      action: "Retry"
    }
  end

  @doc "The undo bar every destructive action puts up."
  @spec undo() :: map()
  def undo do
    %{icon: "undo", text: "Dropped The Quiet Ones", action: "Undo"}
  end

  @doc """
  The sixth band: a surface Kati draws and cannot open.

  The other five are states a screen passes through. This one is a state a
  *screen* is in, and it is here because #22 asked for the ritual that was
  missing — how a drawn surface gets downgraded to *not in v1* without the
  design losing coherence. Screen 42 invented the visual answer and used it
  once; naming it here is what makes it a pattern.

  `example` is the tile screen 42 draws for Sleep, reproduced rather than
  imported: this sheet is a reference, and a reference that reads a section
  list would report what the app happens to hold today instead of what the
  treatment looks like.
  """
  @spec retired() :: map()
  def retired do
    %{
      title: "A surface Kati draws and cannot open",
      body:
        "It keeps its place, dashed rather than filled, and says Not set up. " <>
          "It never says coming soon — a date is a promise this version cannot " <>
          "keep. Tapping it opens one sheet that names what it is, why it is not " <>
          "here, and what Kati can do instead today.",
      example: %{icon: "bedtime", name: "Sleep", status: "Not set up"}
    }
  end
end
