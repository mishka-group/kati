defmodule Kati.MediaArtworkUrlTest do
  @moduledoc """
  `Kati.Media.Artwork` with the full `https` URLs AniList and TVmaze answer
  with, rather than TMDB's CDN paths.

  The download goes through `:artwork_req_options`, so the CDN is a stub and
  nothing reaches the network. What is pinned: a URL is remote, is its own
  thumbnail, downloads once to one file that answers for both sizes, and is
  found afterwards by the resolver every screen asks.
  """
  use ExUnit.Case, async: false

  alias Kati.Design.Images
  alias Kati.Media.Artwork

  defmodule Adapter do
    @moduledoc false
    def run(request), do: Application.fetch_env!(:kati, :artwork_test_stub).(request)
  end

  setup do
    on_exit(fn ->
      Kati.TestOffline.restore(:artwork_req_options)
      Application.delete_env(:kati, :artwork_test_stub)
    end)

    :ok
  end

  test "an https URL is remote and is its own thumbnail; http is neither" do
    url = "https://static.tvmaze.com/uploads/images/medium_portrait/1/4388.jpg"

    assert Artwork.remote?(url)
    assert Artwork.thumbnail(url) == url
    refute Artwork.remote?("http://static.tvmaze.com/a.jpg")
    assert Artwork.thumbnail("http://static.tvmaze.com/a.jpg") == nil
    assert Artwork.cache("http://static.tvmaze.com/a.jpg") == {:error, :not_remote}
  end

  test "a URL downloads once, to one file both sizes answer with" do
    test_pid = self()
    url = "https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx#{unique()}.png"

    stub(fn req ->
      send(test_pid, {:fetched, URI.to_string(req.url)})
      {req, Req.Response.new(status: 200, body: "png bytes")}
    end)

    assert Artwork.local(url) == nil
    assert {:ok, file} = Artwork.cache(url)
    on_exit(fn -> File.rm(file) end)

    assert_received {:fetched, ^url}
    refute_received {:fetched, _second}, "a URL was fetched once per size"

    assert File.read!(file) == "png bytes"
    assert Path.extname(file) == ".png"
    assert Artwork.local(url, :poster) == file
    assert Artwork.local(url, :wide) == file
    assert Images.poster(url) == file
    assert Images.hero(url) == file

    assert {:ok, ^file} = Artwork.cache(url)
    refute_received {:fetched, _again}, "a poster already on disk was fetched again"
  end

  test "two URLs with the same file name on different hosts do not collide" do
    name = "#{unique()}.jpg"
    stub(fn req -> {req, Req.Response.new(status: 200, body: req.url.host)} end)

    assert {:ok, a} = Artwork.cache("https://s4.anilist.co/cover/" <> name)
    assert {:ok, b} = Artwork.cache("https://static.tvmaze.com/cover/" <> name)
    on_exit(fn -> Enum.each([a, b], &File.rm/1) end)

    refute a == b
    assert File.read!(a) == "s4.anilist.co"
    assert File.read!(b) == "static.tvmaze.com"
  end

  test "a CDN that fails leaves nothing on disk and says why" do
    url = "https://static.tvmaze.com/uploads/#{unique()}.jpg"
    stub(fn req -> {req, Req.Response.new(status: 404, body: "")} end)

    assert {:error, _reason} = Artwork.cache(url)
    assert Artwork.local(url) == nil
  end

  test "a TMDB path still asks TMDB's CDN for two widths" do
    test_pid = self()
    path = "/artwork-url-test-#{unique()}.jpg"

    stub(fn req ->
      send(test_pid, {:fetched, URI.to_string(req.url)})
      {req, Req.Response.new(status: 200, body: "jpg")}
    end)

    assert {:ok, poster} = Artwork.cache(path)
    wide = Artwork.local(path, :wide)
    on_exit(fn -> Enum.each([poster, wide], &File.rm/1) end)

    assert_received {:fetched, "https://image.tmdb.org/t/p/w780" <> ^path}
    assert_received {:fetched, "https://image.tmdb.org/t/p/w342" <> ^path}
  end

  defp stub(fun) do
    Application.put_env(:kati, :artwork_test_stub, fun)
    Application.put_env(:kati, :artwork_req_options, adapter: Adapter, retry: false)
  end

  defp unique, do: System.unique_integer([:positive])
end
