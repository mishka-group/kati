defmodule Kati.MediaOpenLibraryTest do
  @moduledoc """
  `Kati.Media.OpenLibrary` against a canned `/search.json` answer.

  Open Library is a stub handed to Req through `:open_library_req_options`, so
  nothing here reaches the network. The fixture is its own document shape,
  cut down.
  """

  use ExUnit.Case, async: false

  doctest Kati.Media.OpenLibrary

  alias Kati.Media.OpenLibrary

  defmodule Adapter do
    @moduledoc false
    def run(request), do: Application.fetch_env!(:kati, :open_library_test_stub).(request)
  end

  setup do
    Application.put_env(:kati, :open_library_req_options, adapter: Adapter, retry: false)

    on_exit(fn ->
      Kati.TestOffline.restore(:open_library_req_options)
      Application.delete_env(:kati, :open_library_test_stub)
    end)

    :ok
  end

  describe "search" do
    test "an empty query asks Open Library nothing" do
      stub(fn _req -> flunk("the empty query reached the network") end)

      assert {:ok, []} = OpenLibrary.search("")
      assert {:ok, []} = OpenLibrary.search("  ")
    end

    test "one letter is not a search" do
      stub(fn _req -> flunk("a one-letter query reached the network") end)
      assert {:ok, []} = OpenLibrary.search("s")
    end

    test "books come back as shelf rows, with Open Library as their source" do
      test_pid = self()

      stub(fn req ->
        send(test_pid, {:asked, URI.parse(req.url).query})

        {req, Req.Response.new(status: 200, body: %{"docs" => [document("The Salt Almanac")]})}
      end)

      assert {:ok, [row]} = OpenLibrary.search("salt almanac")
      assert row.title == "The Salt Almanac"
      assert row.author == "Ines Karvel"
      assert row.year == 2024
      assert row.pages == 380
      assert row.isbn == "9780571339152"
      assert row.source == :open_library
      assert row.kind == :book
      assert row.source_id == "/works/OL123W"
      assert row.seed == "ol-12345"

      assert_receive {:asked, query}
      assert query =~ "q=salt+almanac"
      assert query =~ "fields="
    end

    test "a document with no title is not a row" do
      stub(fn req ->
        {req, Req.Response.new(status: 200, body: %{"docs" => [%{"key" => "/works/OL1W"}]})}
      end)

      assert {:ok, []} = OpenLibrary.search("nothing")
    end

    test "a book Open Library knows only partly still arrives" do
      stub(fn req ->
        {req, Req.Response.new(status: 200, body: %{"docs" => [%{"title" => "Estuary"}]})}
      end)

      assert {:ok, [row]} = OpenLibrary.search("estuary")
      assert row.title == "Estuary"
      assert row.author == nil
      assert row.seed == nil
      assert row.sub == nil
    end

    test "a failure is named, not raised" do
      stub(fn req -> {req, Req.Response.new(status: 503, body: "")} end)
      assert {:error, _reason} = OpenLibrary.search("salt")
    end
  end

  test "the page wrapper is the whole answer" do
    stub(fn req ->
      {req, Req.Response.new(status: 200, body: %{"docs" => [document("Salt")]})}
    end)

    assert {:ok, %{results: [_one], more?: false}} = OpenLibrary.search_page("salt", 1)
    assert {:ok, %{results: [], more?: false}} = OpenLibrary.search_page("salt", 2)
  end

  defp stub(fun), do: Application.put_env(:kati, :open_library_test_stub, fun)

  defp document(title) do
    %{
      "key" => "/works/OL123W",
      "title" => title,
      "author_name" => ["Ines Karvel"],
      "first_publish_year" => 2024,
      "number_of_pages_median" => 380,
      "isbn" => ["9780571339152"],
      "cover_i" => 12_345
    }
  end
end
