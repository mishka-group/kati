defmodule Kati.MediaArtworkTest do
  @moduledoc """
  A title added from TMDB has a picture, and a title the design drew still has
  its own.

  The defect: `poster_path` on a `Kati.Media.CachedTitle` is a path on TMDB's
  image CDN — `/kBf3g9crrADGMc2AMAMlLBgSm2h.jpg` — and every screen in the app
  asks `Kati.Design.Images.poster/1` for a title's artwork. That function looked
  for `priv/sample/design/<value>_400x600.jpg`, which for a CDN path is a file
  that cannot exist, so it answered `nil` and every screen drew its grey
  placeholder. **Every title a user actually added was a grey rectangle** — on
  Home, on the shelf, on Up next, on its own page. Found by adding *Blade
  Runner* on a Pixel 9a.

  Nothing here talks to the network. The download is `cache/1`'s job and is
  covered by the device pass; what is pinned here is the part that decides
  which namespace a value belongs to, because that is the part every screen
  depends on and the part a future edit can quietly break.
  """

  use ExUnit.Case, async: true

  alias Kati.Design.Images
  alias Kati.Media.Artwork

  doctest Kati.Media.Artwork, only: [remote?: 1]

  describe "which namespace a value belongs to" do
    test "a CDN path is remote and a design seed is not" do
      assert Artwork.remote?("/kBf3g9crrADGMc2AMAMlLBgSm2h.jpg")
      refute Artwork.remote?("hollow71")
      refute Artwork.remote?("")
      refute Artwork.remote?(nil)
      refute Artwork.remote?(:hollow71)
    end

    test "the test is the leading slash, which a seed cannot have" do
      # Every seed that ships, asserted rather than assumed: if one ever
      # arrived with a slash in front of it the two namespaces would collide
      # and the design's own pictures would start resolving through a CDN.
      for seed <- Images.seeds() do
        refute Artwork.remote?(seed), "design seed #{inspect(seed)} looks like a CDN path"
      end
    end
  end

  describe "resolving a poster" do
    test "a design seed still comes out of priv, unchanged" do
      seed = hd(Images.seeds())

      assert path = Images.poster(seed)
      assert File.exists?(path)
      assert String.contains?(path, "sample/design")
    end

    test "a CDN path with nothing downloaded answers nil rather than raising" do
      # The honest fallback and the one every screen already handles: no file,
      # no picture, the placeholder. What it must NOT do is go looking in
      # `priv/` for a filename built out of a URL path.
      assert Images.poster("/nothing-was-ever-downloaded-for-this.jpg") == nil
      assert Images.hero("/nothing-was-ever-downloaded-for-this.jpg") == nil
      assert Artwork.local("/nothing-was-ever-downloaded-for-this.jpg") == nil
    end

    test "nil is still nil at both sizes" do
      assert Images.poster(nil) == nil
      assert Images.hero(nil) == nil
      assert Artwork.local(nil) == nil
    end
  end

  describe "the file a download would land in" do
    test "a downloaded poster is found by the resolver every screen uses" do
      # `cache/1` is not called — the network is not this test's business. The
      # file is written where `cache/1` would write it, which is the contract
      # between the two halves and the thing that would break silently if the
      # naming ever drifted.
      path = "/artwork-test-#{System.unique_integer([:positive])}.jpg"
      dir = Path.join(Mob.data_dir(), "artwork")
      File.mkdir_p!(dir)

      poster = Path.join(dir, "w342_" <> String.trim_leading(path, "/"))
      wide = Path.join(dir, "w780_" <> String.trim_leading(path, "/"))

      on_exit(fn ->
        File.rm(poster)
        File.rm(wide)
      end)

      assert Images.poster(path) == nil, "nothing is downloaded yet"

      File.write!(poster, "not really a jpeg")
      File.write!(wide, "not really a jpeg either")

      assert Images.poster(path) == poster
      assert Images.hero(path) == wide
      assert Artwork.local(path, :poster) == poster
      assert Artwork.local(path, :wide) == wide
    end

    test "cache/1 refuses a value that is not a CDN path, without touching the network" do
      assert Artwork.cache("hollow71") == {:error, :not_remote}
      assert Artwork.cache(nil) == {:error, :not_remote}
      assert Artwork.cache(:anything) == {:error, :not_remote}
    end
  end

  describe "every way a screen asks for a picture" do
    test "path/2 answers a downloaded poster at whatever size the caller asked for" do
      # The first fix put the branch in `poster/1` and `hero/1`, and Home went
      # on drawing a grey rectangle over a poster that was already on the disk
      # — because `home.ex:973` calls `path/2` with `{520, 384}` of its own.
      # Six screens do. The branch lives in the primitive for that reason, and
      # this test is the reason it has to stay there.
      path = "/artwork-sizes-#{System.unique_integer([:positive])}.jpg"
      dir = Path.join(Mob.data_dir(), "artwork")
      File.mkdir_p!(dir)

      poster = Path.join(dir, "w342_" <> String.trim_leading(path, "/"))
      wide = Path.join(dir, "w780_" <> String.trim_leading(path, "/"))
      on_exit(fn -> Enum.each([poster, wide], &File.rm/1) end)

      File.write!(poster, "jpeg")
      File.write!(wide, "jpeg")

      # The sizes the six direct callers actually pass.
      assert Images.path(path, {520, 384}) == poster, "Home's continue-watching card"
      assert Images.path(path, {400, 600}) == poster, "a shelf jacket"
      assert Images.path(path, {300, 300}) == poster
      assert Images.path(path, {700, 400}) == wide, "Up next's hero"
      assert Images.path(path, {900, 620}) == wide, "a page header"
      assert Images.path(path, {900, 740}) == wide
    end

    test "a design seed is unaffected at every size the app asks for" do
      seed = hd(Images.seeds())

      for size <- [{400, 600}, {520, 384}, {300, 300}, {700, 400}, {900, 620}] do
        answer = Images.path(seed, size)
        assert is_nil(answer) or File.exists?(answer)
        refute answer && String.contains?(answer, "artwork"), "a seed reached the download cache"
      end
    end
  end

  describe "what the add path hands it" do
    test "poster_of/1 reads the row fetch/2 answers with, and nothing else" do
      # `Kati.Media.Tmdb.fetch/2` answers `%{title: row, seasons: n, episodes:
      # n}`. The first version of the caller read `:poster_path` off that outer
      # map, which is a key it does not have — so the download never ran and the
      # defect this module exists for stayed fixed only in principle.
      assert Kati.Screens.AddTitle.poster_of(%{title: %{poster_path: "/abc.jpg"}}) == "/abc.jpg"
      assert Kati.Screens.AddTitle.poster_of(%{title: %{poster_path: nil}}) == nil
      assert Kati.Screens.AddTitle.poster_of(%{seasons: 2, episodes: 16}) == nil
      assert Kati.Screens.AddTitle.poster_of(nil) == nil
    end
  end
end
