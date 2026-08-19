defmodule Kati.Design.Images do
  @moduledoc """
  The design's own photographs.

  The export's `<image-slot>`s are not placeholders. Each carries a
  `picsum.photos` URL with a **seed** — `seed/hollow71/400/600` — and picsum
  seeds are deterministic, so the same seed always returns the same picture.
  The app can therefore show exactly what the drawing shows.

  All 50 distinct seed+size combinations live in `priv/sample/design/`, named
  `{seed}_{w}x{h}.jpg`. The seeds are semantic, which is what makes them
  usable: `hollow71` is The Long Hollow, `bluehour58` is Blue Hour,
  `mealsalmon` is a plate of salmon, `bookaa1` is a book cover.

  Sizes matter as well as seeds. The same title appears at 400x600 as a
  poster, 520x384 as a card, and 900x740 as a hero — different crops of a
  different photograph, not one image scaled — so `path/2` takes both.
  """

  @dir "sample/design"

  @doc """
  Absolute path to a design image, or `nil` when that seed and size were never
  drawn.

      Kati.Design.Images.path("hollow71", {400, 600})
  """
  @spec path(String.t(), {pos_integer(), pos_integer()}) :: String.t() | nil
  def path(seed, {w, h}) do
    file = Kati.Priv.path("#{@dir}/#{seed}_#{w}x#{h}.jpg")
    if File.exists?(file), do: file, else: nil
  end

  @doc """
  The poster for a seed, at whichever poster size the design has for it.

  Tries the sizes the export actually uses, largest crop last, so a caller
  that just wants "the picture of this title" does not have to know which
  sizes were drawn.
  """
  @spec poster(String.t()) :: String.t() | nil
  def poster(nil), do: nil

  def poster(seed) do
    Enum.find_value([{400, 600}, {300, 300}, {520, 384}, {400, 400}], &path(seed, &1))
  end

  @doc "The widest crop of a seed, for a hero header."
  @spec hero(String.t()) :: String.t() | nil
  def hero(nil), do: nil

  def hero(seed) do
    Enum.find_value([{900, 740}, {900, 620}, {900, 1600}, {520, 384}], &path(seed, &1))
  end

  @doc "Every seed that shipped, for tests and for a gallery screen."
  @spec seeds() :: [String.t()]
  def seeds do
    Kati.Priv.path(@dir)
    |> Path.join("*.jpg")
    |> Path.wildcard()
    |> Enum.map(&(Path.basename(&1, ".jpg") |> String.split("_") |> hd()))
    |> Enum.uniq()
    |> Enum.sort()
  end
end
