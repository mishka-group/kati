defmodule Kati.Screens.Lists.Sample do
  @moduledoc """
  Stand-in list data for screen 12, until the Screen domain exists.

  Two kinds of list, which is the whole point of the screen: the three at the
  top are hand-made and carry a fanned stack of the artwork they hold, the four
  underneath are kept by the app and carry an icon and a count. The drawing
  gives one hand-made list a `ranked` badge, one a `shared` badge and one
  neither — so the sample does too, and the third falls through to the chevron.

  The counts are the drawing's, including the header's `7 lists · 2 ranked`,
  which does not match the three cards on screen on purpose: the list of lists
  is longer than one screenful.
  """

  @doc "Everything screen 12 draws."
  @spec lists() :: map()
  def lists do
    %{
      subtitle: "7 lists · 2 ranked",
      made: [
        %{
          title: "Best of 2026",
          count: "14 titles",
          badge: "ranked",
          seeds: ["hollow71", "bluehour58", "cartog60"]
        },
        %{
          title: "Rainy Sunday",
          count: "8 titles",
          badge: nil,
          seeds: ["harbour86", "nightbirds24", "marram15"]
        },
        %{
          title: "Recommended by Jo",
          count: "5 titles",
          badge: "shared",
          seeds: ["quietus39", "vellum97", "ashfall42"]
        }
      ],
      kept: [
        %{icon: "bookmark", title: "Wishlist", count: "12"},
        %{icon: "replay", title: "Rewatches", count: "9"},
        %{icon: "do_not_disturb_on", title: "Abandoned", count: "3"},
        %{icon: "inventory_2", title: "Owned on disc", count: "22"}
      ]
    }
  end

  @doc "A poster for the fanned stack, or `nil` when that seed was never drawn."
  @spec poster(String.t()) :: String.t() | nil
  def poster(seed), do: Kati.Design.Images.poster(seed)
end
