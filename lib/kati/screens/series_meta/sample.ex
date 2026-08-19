defmodule Kati.Screens.SeriesMeta.Sample do
  @moduledoc """
  Stand-in metadata for screen 14, until the Screen domain exists.

  The drawing's own copy: three ratings from three sources, four cast members
  with their character names, three ways to watch — one of which is the user's
  own shelf — and four tags the user wrote.

  ## The star

  The drawing writes your own rating as `&starf; 4.5` — a U+2605 glyph followed
  by the number. Plus Jakarta Sans does not carry U+2605; screen 08 proved that
  the hard way, where five text stars rendered as nothing at all and read as a
  layout bug. So `star?` asks for the Material Symbols glyph instead and the
  value stays plain text. The mark is the same mark; only the font that draws
  it changed.

  ## Where to watch

  `Your shelf` carries `owned` where the others carry a price, and Lumen+
  carries nothing at all — the drawing leaves that cell empty because
  "included" already said it in the line above. `nil` rather than `""`, so the
  screen can drop the node instead of laying out an empty one.
  """

  @doc "Everything screen 14 draws."
  @spec series() :: map()
  def series do
    %{
      title: "The Long Hollow",
      seed: "hollow71",
      meta: "2024 · 15 · DRAMA, MYSTERY · 3 SEASONS · 26 EP",
      ratings: [
        %{label: "Yours", value: "4.5", color: 0xFFE8823C, star?: true},
        %{label: "Audience", value: "8.1", color: 0xFF1A1917, star?: false},
        %{label: "Critics", value: "96%", color: 0xFF4E9A73, star?: false}
      ],
      synopsis:
        "A tidal surveyor returns to the estuary village she left at seventeen, " <>
          "and finds the water has been keeping records of its own.",
      more: "more",
      trailer: "Trailer",
      cast: [
        %{name: "Ines Karvel", role: "Mara", seed: "face26"},
        %{name: "Tomas Rhee", role: "Bryn", seed: "face14"},
        %{name: "Ada Vance", role: "Sister Ill", seed: "face45"},
        %{name: "Ola Beck", role: "The Warden", seed: "face58"}
      ],
      where: [
        %{badge: "L", name: "Lumen+", line: "included · 4K HDR", price: nil},
        %{badge: "K", name: "Kino store", line: "buy season", price: "£14.99"},
        %{badge: "D", name: "Your shelf", line: "Blu-ray, S1–S2", price: "owned"}
      ],
      tags: ["slow burn", "coastal", "watch with Jo", "rewatchable"],
      add_tag: "+ tag"
    }
  end

  @doc """
  The header still, at the 900x620 crop the drawing asks for.

  `Kati.Design.Images.hero/1` answers with 900x740 first, which is the crop
  screen 04 uses at 330pt. This header is 270pt, so it takes the shallower
  photograph the export actually names.
  """
  @spec hero_art() :: String.t() | nil
  def hero_art, do: Kati.Design.Images.path("hollow71", {900, 620})

  @doc "A cast portrait, or `nil` when that seed was never drawn."
  @spec face(String.t()) :: String.t() | nil
  def face(seed), do: Kati.Design.Images.poster(seed)
end
