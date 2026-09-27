defmodule Kati.SearchMorePagesTest do
  @moduledoc """
  Screen 19's *Show more*: a catalogue section that answered one page of many
  asks for the next under the rows it already drew.

  AniList is the catalogue here, through its Req seam: page 1 holds two
  titles and says there is another, page 2 holds one new title and one
  already shown and says there is not. A `:fail_page_2` switch makes page 2
  answer 500 once, for the retry.
  """
  use Mob.ScreenCase, async: false

  doctest Kati.Search.OnTmdb, only: [more_begin: 1]

  alias Kati.Screens.Search
  alias Kati.Search.OnTmdb
  alias Kati.Search.Recent

  defmodule PagedAnilist do
    @moduledoc false
    def run(request) do
      variables =
        request.body |> IO.iodata_to_binary() |> Jason.decode!() |> Map.get("variables")

      page = Map.get(variables, "p", 1)
      send(:persistent_term.get({__MODULE__, :owner}), {:anilist_page, page})

      if page == 2 and :persistent_term.get({__MODULE__, :fail}, false) do
        :persistent_term.put({__MODULE__, :fail}, false)
        {request, Req.Response.new(status: 500, body: "")}
      else
        body = %{
          "data" => %{
            "Page" => %{
              "pageInfo" => %{"hasNextPage" => page == 1},
              "media" => media(page)
            }
          }
        }

        {request, Req.Response.new(status: 200, body: body)}
      end
    end

    defp media(1), do: [show(1, "Paged One"), show(2, "Paged Two")]
    defp media(2), do: [show(2, "Paged Two"), show(3, "Paged Three")]
    defp media(_page), do: []

    defp show(id, title),
      do: %{
        "id" => id,
        "format" => "TV",
        "title" => %{"romaji" => title},
        "startDate" => %{"year" => 2020}
      }
  end

  setup do
    Kati.Locale.put(:en)
    Recent.forget!()
    Application.delete_env(:kati, :tmdb_test_token)
    :persistent_term.put({PagedAnilist, :owner}, self())
    :persistent_term.put({PagedAnilist, :fail}, false)
    Application.put_env(:kati, :anilist_req_options, adapter: PagedAnilist, retry: false)

    on_exit(fn ->
      Kati.TestOffline.restore(:anilist_req_options)
      :persistent_term.erase({PagedAnilist, :fail})
    end)

    :ok
  end

  describe "the catalogue's pages" do
    test "AniList says whether there is a page after this one" do
      assert {:ok, %{results: [_, _], more?: true}} = Kati.Media.Anilist.search_page("paged", 1)
      assert {:ok, %{results: [_, _], more?: false}} = Kati.Media.Anilist.search_page("paged", 2)
    end

    test "TVmaze has one page and nothing after it" do
      assert {:ok, %{results: [], more?: false}} = Kati.Media.Tvmaze.search_page("x", 2)
    end
  end

  describe "the section's state" do
    test "the next page is appended, the repeat dropped, and positions run on" do
      section = answered_page_1()
      assert {:ok, section, 2} = OnTmdb.more_begin(section)
      assert section.more == :loading
      assert OnTmdb.more_begin(section) == :none

      {:ok, page} = Kati.Media.Anilist.search_page("paged", 2)
      section = OnTmdb.more_answered(section, 2, {:ok, page}, &Kati.Search.Keyless.shape/1)

      assert Enum.map(section.rows, & &1.title) == ["Paged One", "Paged Two", "Paged Three"]
      assert Enum.map(section.rows, & &1.position) == [0, 1, 2]
      assert section.page == 2
      refute section.more?
      assert section.more == :idle
    end

    test "a failed page keeps the rows and can be asked again" do
      {:ok, section, 2} = OnTmdb.more_begin(answered_page_1())
      section = OnTmdb.more_answered(section, 2, {:error, {:http, 500}}, & &1)

      assert length(section.rows) == 2
      assert section.more == {:error, {:http, 500}}
      assert section.more?
      assert {:ok, _section, 2} = OnTmdb.more_begin(section)
    end

    test "an answer for a page nobody is waiting on changes nothing" do
      section = answered_page_1()
      assert OnTmdb.more_answered(section, 2, {:ok, %{results: [], more?: false}}, & &1) == section
    end
  end

  describe "screen 19" do
    test "Show more under the rows, skeletons while it loads, then the next rows" do
      view = settle(typed(search(), "paged"))

      assert "Show more" in texts(view)
      assert :more_anilist in tap_tags(view)
      assert titles(view) == ["Paged One", "Paged Two"]

      view = render_info(view, {:tap, :more_anilist})
      assert_receive {:anilist_page, 2}, 5_000
      refute "Show more" in texts(view)
      assert skeletons(view) == 2
      assert titles(view) == ["Paged One", "Paged Two"]

      view = deliver_more(view)

      assert titles(view) == ["Paged One", "Paged Two", "Paged Three"]
      refute "Show more" in texts(view)
      assert skeletons(view) == 0
      assert :anilist_open_2 in tap_tags(view)
    end

    test "a failed page says so and tries again from the same control" do
      :persistent_term.put({PagedAnilist, :fail}, true)
      view = settle(typed(search(), "paged"))

      view = view |> render_info({:tap, :more_anilist}) |> deliver_more()
      assert "Couldn’t load more · Try again" in texts(view)
      assert titles(view) == ["Paged One", "Paged Two"]

      view = view |> render_info({:tap, :more_anilist}) |> deliver_more()
      assert titles(view) == ["Paged One", "Paged Two", "Paged Three"]
    end

    test "an answer for a query typed past is dropped" do
      view = settle(typed(search(), "paged"))
      view = render_info(view, {:tap, :more_anilist})
      assert_receive {:more_answer, :anilist, epoch, "paged", 2, result}, 5_000

      view = typed(view, "pagedx")
      view = render_info(view, {:more_answer, :anilist, epoch, "paged", 2, result})
      refute "Paged Three" in titles(view)
    end
  end

  defp answered_page_1 do
    {:ok, page} = Kati.Media.Anilist.search_page("paged", 1)

    OnTmdb.idle()
    |> Map.put(:source, :anilist)
    |> Map.merge(%{status: :pending, query: "paged"})
    |> OnTmdb.answered({:ok, page}, &Kati.Search.Keyless.shape/1)
  end

  defp search, do: mount_screen(Search, %{query: ""})

  defp typed(view, query), do: render_info(view, {:change, :query, query})

  defp settle(view) do
    query = String.trim(assigns(view).query)
    view = render_info(view, {:search_ready, query})

    Enum.reduce([:anilist, :tvmaze], view, fn _each, view ->
      assert_receive {:keyless_answer, source, epoch, ^query, result}, 5_000
      render_info(view, {:keyless_answer, source, epoch, query, result})
    end)
  end

  defp deliver_more(view) do
    assert_receive {:more_answer, :anilist, epoch, query, page, result}, 5_000
    render_info(view, {:more_answer, :anilist, epoch, query, page, result})
  end

  defp titles(view), do: Enum.filter(texts(view), &String.starts_with?(&1, "Paged "))

  defp skeletons(view) do
    Enum.count(flatten(view), fn node ->
      props = Map.get(node, :props) || %{}
      node.type == :box and props[:width] == 150 and props[:height] == 13
    end)
  end

  defp tap_tags(view) do
    for node <- flatten(view),
        {_pid, tag} <- [Map.get(Map.get(node, :props) || %{}, :on_tap)],
        is_atom(tag),
        do: tag
  end

  defp texts(view) do
    view
    |> flatten()
    |> Enum.flat_map(fn node ->
      case Map.get(node, :props) || %{} do
        %{text: text} when is_binary(text) -> [text]
        _other -> []
      end
    end)
  end
end
