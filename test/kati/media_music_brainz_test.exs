defmodule Kati.MediaMusicBrainzTest do
  @moduledoc """
  `Kati.Media.MusicBrainz` against a canned release-group answer.

  MusicBrainz is a stub handed to Req through `:music_brainz_req_options`, so
  nothing here reaches the network. The fixture is its own document shape.
  """

  use ExUnit.Case, async: false

  doctest Kati.Media.MusicBrainz

  alias Kati.Media.MusicBrainz

  defmodule Adapter do
    @moduledoc false
    def run(request), do: Application.fetch_env!(:kati, :music_brainz_test_stub).(request)
  end

  setup do
    Application.put_env(:kati, :music_brainz_req_options, adapter: Adapter, retry: false)

    on_exit(fn ->
      Kati.TestOffline.restore(:music_brainz_req_options)
      Application.delete_env(:kati, :music_brainz_test_stub)
    end)

    :ok
  end

  test "an empty or one-letter query asks nothing" do
    stub(fn _req -> flunk("a short query reached the network") end)

    assert {:ok, []} = MusicBrainz.search("")
    assert {:ok, []} = MusicBrainz.search("t")
  end

  test "albums come back as shelf rows, with MusicBrainz as their source" do
    test_pid = self()

    stub(fn req ->
      send(test_pid, {:asked, req})

      {req,
       Req.Response.new(
         status: 200,
         body: %{"release-groups" => [document("Tide Ledger")]}
       )}
    end)

    assert {:ok, [row]} = MusicBrainz.search("tide ledger")
    assert row.title == "Tide Ledger"
    assert row.artist == "Kell Ostrand"
    assert row.year == 1997
    assert row.source == :musicbrainz
    assert row.kind == :album
    assert row.source_id == "7f2b5d0e-0000-0000-0000-000000000000"
    assert row.seed == row.source_id

    assert_receive {:asked, req}
    assert req.headers["user-agent"] |> List.first() =~ "Kati/"
    assert URI.parse(req.url).query =~ "fmt=json"
  end

  test "a release group with no title is not a row" do
    stub(fn req -> {req, Req.Response.new(status: 200, body: %{"release-groups" => [%{}]})} end)
    assert {:ok, []} = MusicBrainz.search("nothing")
  end

  test "a failure is named, not raised" do
    stub(fn req -> {req, Req.Response.new(status: 503, body: "")} end)
    assert {:error, _reason} = MusicBrainz.search("tide")
  end

  test "the page wrapper is the whole answer" do
    stub(fn req ->
      {req, Req.Response.new(status: 200, body: %{"release-groups" => [document("Salt")]})}
    end)

    assert {:ok, %{results: [_one], more?: false}} = MusicBrainz.search_page("salt", 1)
    assert {:ok, %{results: [], more?: false}} = MusicBrainz.search_page("salt", 2)
  end

  defp stub(fun), do: Application.put_env(:kati, :music_brainz_test_stub, fun)

  defp document(title) do
    %{
      "id" => "7f2b5d0e-0000-0000-0000-000000000000",
      "title" => title,
      "first-release-date" => "1997-05-01",
      "primary-type" => "Album",
      "artist-credit" => [%{"name" => "Kell Ostrand"}]
    }
  end
end
