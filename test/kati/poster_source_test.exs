defmodule Kati.PosterSourceTest do
  @moduledoc """
  Screens 06 and 10 draw a poster from the title's own path, never from the
  drawing.

  Screen 06's result rows resolve through `Kati.Media.Artwork` alone: a TMDB
  path is a downloaded file or TMDB's thumbnail by URL, and anything else —
  a design seed included — is the placeholder tile. Screen 10's rows resolve
  `Kati.Media.CachedTitle.poster_path` through `Kati.Design.Images.poster/1`
  with no sample module in between.
  """
  use ExUnit.Case, async: true

  alias Kati.Screens.AddTitle
  alias Kati.Screens.UpNext

  defp image_src(tree) do
    case tree do
      %{type: :image, props: %{src: src}} -> src
      _placeholder -> nil
    end
  end

  test "a result row with a TMDB path shows TMDB's thumbnail" do
    path = "/kBf3g9crrADGMc2AMAMlLBgSm2h.jpg"

    assert image_src(AddTitle.thumb(%{seed: path})) == Kati.Media.Artwork.thumbnail(path)
  end

  test "a result row never shows one of the drawing's photographs" do
    assert Kati.Design.Images.poster("hollow71") != nil,
           "the seed must exist for this to mean anything"

    assert image_src(AddTitle.thumb(%{seed: "hollow71"})) == nil
    assert image_src(AddTitle.thumb(%{seed: nil})) == nil
  end

  test "an Up next row with no poster draws the placeholder" do
    assert image_src(UpNext.thumb(%{seed: nil})) == nil
    assert image_src(UpNext.thumb(%{seed: "/not-downloaded-on-this-device.jpg"})) == nil
  end

  test "the Up next sample no longer carries a poster lookup of its own" do
    Code.ensure_loaded!(Kati.Screens.UpNext.Sample)

    refute function_exported?(Kati.Screens.UpNext.Sample, :poster, 1)
  end
end
