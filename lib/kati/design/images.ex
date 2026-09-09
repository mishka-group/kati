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

  ## Not every picture is a seed any more

  Since screen 06 could add a real film, these functions are asked about titles
  this design never drew: TMDB answers with `/kBf3g9crrADGMc2AMAMlLBgSm2h.jpg`,
  a path on its image CDN, and they hand those to `Kati.Media.Artwork`, which
  keeps them in the device's own writable directory — see that module for why
  the download cannot happen here. A seed is still a seed and still comes out
  of `priv/`; the two namespaces are told apart by the leading slash, which is
  a shape a seed cannot have.

  **The branch is in `path/2` and not in `poster/1`**, and that is the whole
  lesson of the first attempt at this: `poster/1` and `hero/1` are not the only
  way in. Six screens — `home.ex:973` among them, which is the first card a
  user sees — call `path/2` with a size of their own, so fixing the two
  aggregates left Home drawing a grey rectangle over a poster that was sitting
  on the disk. One branch in the primitive covers every caller there is.
  """

  @dir "sample/design"

  @doc """
  Absolute path to a design image, or `nil` when that seed and size were never
  drawn.

      Kati.Design.Images.path("hollow71", {400, 600})
  """
  @spec path(String.t(), {pos_integer(), pos_integer()}) :: String.t() | nil
  def path(value, {w, h}) do
    if Kati.Media.Artwork.remote?(value) do
      # A downloaded picture has two crops rather than the design's fifty, so
      # the requested size is answered with whichever of the two is closer.
      # `Kati.Media.Artwork.local/2` is pure and answers `nil` for a poster
      # this device has not fetched, which is the same `nil` a seed the design
      # never drew has always produced — so every caller's existing `case` is
      # already correct for it.
      Kati.Media.Artwork.local(value, if(w > 520, do: :wide, else: :poster))
    else
      file = Kati.Priv.path("#{@dir}/#{value}_#{w}x#{h}.jpg")
      if File.exists?(file), do: file, else: nil
    end
  end

  @doc """
  The poster for a seed, at whichever poster size the design has for it.

  Tries the sizes the export actually uses, largest crop last, so a caller
  that just wants "the picture of this title" does not have to know which
  sizes were drawn.
  """
  @spec poster(String.t()) :: String.t() | nil
  def poster(nil), do: nil

  def poster(value) do
    Enum.find_value([{400, 600}, {300, 300}, {520, 384}, {400, 400}], &path(value, &1))
  end

  @doc """
  The 520x384 card still, or the poster when the design never drew one.

  The design's rule is real and is kept: a still is **a different photograph**
  from the poster of the same title, not the same image scaled, so `path/2` is
  asked for the exact crop first. What changed is what happens when there is
  none.

  Only two of the fifty seeds have a 520x384 — `hollow71` and `saltiron33` —
  and three of the four titles screen 163's poster wall offers do not. Found on
  a real phone: picking **Marram** in onboarding put it on Home's *Continue
  watching* card as a grey rectangle, because the seed reached the card and the
  crop did not. It only showed up there because the emulator run happened to
  pick The Long Hollow, which has every crop.

  A different crop of the right title beats a rectangle of nothing, and it is
  the rule `path/2` already follows one branch up: a DOWNLOADED poster has two
  crops rather than the design's fifty, and the requested size is answered with
  whichever is closer. This is the same answer for the bundled half.

      iex> Kati.Design.Images.card("marram15") |> Path.basename()
      "marram15_400x600.jpg"

      iex> Kati.Design.Images.card("hollow71") |> Path.basename()
      "hollow71_520x384.jpg"
  """
  @spec card(String.t() | nil) :: String.t() | nil
  def card(nil), do: nil
  def card(value), do: path(value, {520, 384}) || poster(value)

  @doc "The widest crop of a seed, for a hero header."
  @spec hero(String.t()) :: String.t() | nil
  def hero(nil), do: nil

  def hero(value) do
    Enum.find_value([{900, 740}, {900, 620}, {900, 1600}, {520, 384}], &path(value, &1))
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
