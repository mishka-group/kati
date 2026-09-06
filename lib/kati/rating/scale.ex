defmodule Kati.Rating.Scale do
  @moduledoc """
  Which scale the user reads their own ratings on: five stars, or ten points.

  MOVIES-AND-TV.md #96. The `5★` / `10pt` toggle on screen 33 was drawn as a
  control and changed nothing, and `Kati.Screens.Rating`'s moduledoc argued it
  had to: *both are display preferences — which scale the user reads ratings on
  — and no resource holds one*.

  No Ash resource does, and none should. A preference about how numbers are
  READ is not a fact about a title, a watch or a shelf, and putting it on
  `Kati.Media.TrackedTitle` would make it a per-show setting, which it is not.
  But `Kati.Locale` and the theme have kept exactly this class of setting in
  **`Mob.State`** — DETS, SIGKILL-safe, survives a restart — since the app had
  two screens, and that is where this goes.

  ## One stored number, two ways of reading it

  `Kati.Media.Watch.rating` is the ten-point integer on both scales and nothing
  here writes it. Half a star is one point, so `9` is *4.5 stars* or *9 pt* and
  the two are the same fact in different words — which is why switching the
  toggle re-labels every rating in the app rather than converting anything.
  A scale that rewrote the column would lose the half a five-star reader cannot
  express, and the reader who switched back would find their 4.5 had become 5.

  ## Everywhere, or it is a lie

  A preference honoured on the screen that sets it and nowhere else is worse
  than one that does nothing: the number beside an episode on screen 04 would
  disagree with the number on the sheet that wrote it. So `label/1` is the one
  place a rating becomes text — screen 33's numeral, screen 04's and 34's
  rating column, board 143's rows and screen 144's sheet all route through it.
  """

  @scales [:stars, :points]
  @default :stars

  @doc "Both scales, in the order screen 33's toggle draws them."
  @spec supported() :: [:stars | :points]
  def supported, do: @scales

  @doc """
  The active scale.

  `:stars` for anything unset or unrecognised, which is what the drawing shows
  and what a first run gets.
  """
  @spec current() :: :stars | :points
  def current do
    case Mob.State.get(:rating_scale, @default) do
      scale when scale in @scales -> scale
      _unset -> @default
    end
  end

  @doc "Set the active scale."
  @spec put(:stars | :points) :: :ok
  def put(scale) when scale in @scales do
    Mob.State.put(:rating_scale, scale)
    :ok
  end

  @doc """
  A stored rating as text, on whichever scale is active.

  The argument is the value the screens carry — a float on the five-point scale,
  `4.5` for a nine — because that is what `Kati.Media.Watch`'s readers have
  always handed their labels, not because five is the truer half.

      iex> Kati.Rating.Scale.label(4.5, :stars)
      "4.5"

      iex> Kati.Rating.Scale.label(4.5, :points)
      "9"

      iex> Kati.Rating.Scale.label(3.0, :stars)
      "3"

      iex> Kati.Rating.Scale.label(3.0, :points)
      "6"

      iex> Kati.Rating.Scale.label(nil, :points)
      "—"
  """
  @spec label(number() | nil, :stars | :points | nil) :: String.t()
  def label(value, scale \\ nil)

  # The em dash `Kati.Screens.Stats` uses for the same absence in `Avg ★`: a
  # card that is the user's own rating says "not rated" rather than "0".
  def label(nil, _scale), do: "—"

  def label(value, nil), do: label(value, Kati.Rating.Scale.current())

  def label(value, :points), do: Integer.to_string(round(value * 2))

  def label(value, :stars) do
    whole = trunc(value)
    if value == whole, do: Integer.to_string(whole), else: "#{value}"
  end

  @doc """
  The unit that follows the number, or `nil` when the stars beside it say it.

  Screen 33 draws its numeral against five stars, so `4.5` needs no unit. On
  the ten-point scale the same row would read `9` beside five stars, which is
  a number and a picture disagreeing, so the scale says so.

      iex> Kati.Rating.Scale.unit(:points)
      "pt"

      iex> Kati.Rating.Scale.unit(:stars)
      nil
  """
  @spec unit(:stars | :points | nil) :: String.t() | nil
  def unit(scale \\ nil)
  def unit(nil), do: unit(Kati.Rating.Scale.current())
  def unit(:points), do: "pt"
  def unit(:stars), do: nil
end
