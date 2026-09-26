defmodule Kati.OnboardingFirstTitleTest do
  @moduledoc """
  Screen 163's first title is a real one (N46).

  The step used to offer board 163's four invented films and shelve the one
  tapped with its design seed in `Kati.Media.CachedTitle.poster_path` —
  `hollow71` — so Home, the Library and Up next drew a design photograph as
  though it were the reader's film. The step is screen 06's search now, and
  these walk it through its own handlers: a TMDB hit is added with TMDB's
  poster path, a title typed by hand arrives with none, and no token is a door
  to screen 80 rather than a search that answers nothing.

  TMDB is a stub handed to Req through `:tmdb_req_options`, the seam
  `Kati.MediaTmdbTest` uses. The poster files are laid in the artwork cache
  first, so `Kati.Media.Artwork.cache/1` finds them on disk and asks no CDN.
  """
  use Mob.ScreenCase, async: false

  doctest Kati.Screens.OnboardingFirstTitle

  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Screens.OnboardingFirstTitle

  @poster "/onboarding-first-title-test.jpg"

  defmodule Adapter do
    @moduledoc false
    def run(request), do: Application.fetch_env!(:kati, :tmdb_test_stub).(request)
  end

  # The key choice is restored at the END of each test rather than in
  # `on_exit`: it lives in `Mob.State`, which `Kati.FirstRunTest` records is no
  # longer alive by the time an on_exit callback runs.
  setup do
    Kati.Locale.put(:en)
    Kati.Onboarding.reset!()
    Process.put(:tmdb_key_choice, Kati.Sources.tmdb_key())
    token = System.get_env("TMDB_READ_TOKEN")

    on_exit(fn ->
      Application.delete_env(:kati, :tmdb_req_options)
      Application.delete_env(:kati, :tmdb_test_stub)

      if token,
        do: System.put_env("TMDB_READ_TOKEN", token),
        else: System.delete_env("TMDB_READ_TOKEN")

      for size <- ~w(w342 w780) do
        File.rm(artwork_file(size))
      end
    end)

    :ok
  end

  describe "a title found on TMDB" do
    test "is added with TMDB's own poster path, never a design seed" do
      stub_tmdb!()

      rolled_back(fn ->
        before = cached_ids()
        {socket, results} = search(socket_for(), "spirited")

        assert [%{source: :tmdb, source_id: "129", title: "Spirited Away"}] = results

        drawn = inspect(OnboardingFirstTitle.render(socket.assigns), limit: :infinity)
        assert drawn =~ "Spirited Away"
        assert drawn =~ "1 RESULT"

        {:noreply, added} = OnboardingFirstTitle.handle_info({:tap, :add_0}, socket)

        assert added.assigns.save_error == nil
        assert [%{added: true}] = added.assigns.results

        assert %TrackedTitle{status: :watching, kind: :anime} =
                 Enum.find(
                   Ash.read!(TrackedTitle),
                   &(&1.source == :tmdb and &1.source_id == "129")
                 )

        cached =
          Enum.find(Ash.read!(CachedTitle), &(&1.source == :tmdb and &1.source_id == "129"))

        assert cached.poster_path == @poster
        assert_only_tmdb_posters!(before)

        {:noreply, moved} = OnboardingFirstTitle.handle_info({:tap, :finish}, added)
        assert Kati.Onboarding.complete?()
        assert reset_target(moved) == Kati.Screens.Home
      end)
    after
      restore_key()
    end

    test "tapping the added disc again takes it back off the shelf" do
      stub_tmdb!()

      rolled_back(fn ->
        {socket, _results} = search(socket_for(), "spirited")
        {:noreply, added} = OnboardingFirstTitle.handle_info({:tap, :add_0}, socket)
        {:noreply, removed} = OnboardingFirstTitle.handle_info({:tap, :add_0}, added)

        assert [%{added: false}] = removed.assigns.results
        refute Enum.find(Ash.read!(TrackedTitle), &(&1.source == :tmdb and &1.source_id == "129"))
      end)
    after
      restore_key()
    end

    test "nothing found says so and offers the query by hand" do
      stub_tmdb!(fn -> %{"results" => []} end)

      {socket, []} = search(socket_for(), "zzqwx")
      drawn = inspect(OnboardingFirstTitle.render(socket.assigns), limit: :infinity)

      assert drawn =~ "Nothing here for"
      assert drawn =~ "Add “zzqwx” by hand"
    after
      restore_key()
    end

    test "offline is a sentence, not an empty list" do
      Kati.Sources.put_tmdb_key(:kati)
      System.put_env("TMDB_READ_TOKEN", "test-token")

      stub(fn req -> {req, %Req.TransportError{reason: :nxdomain}} end)
      Application.put_env(:kati, :tmdb_req_options, adapter: Adapter, retry: false)

      {socket, []} = search(socket_for(), "spirited")

      assert socket.assigns.search_error

      assert inspect(OnboardingFirstTitle.render(socket.assigns), limit: :infinity) =~
               socket.assigns.search_error
    after
      restore_key()
    end
  end

  describe "a title typed by hand" do
    test "goes to screen 154 with the query, and arrives with no poster" do
      rolled_back(fn ->
        before = cached_ids()
        typed = "Onboarding By Hand #{System.unique_integer([:positive])}"

        {:noreply, socket} =
          OnboardingFirstTitle.handle_info({:change, :title_query, typed}, socket_for())

        {:noreply, pushed} = OnboardingFirstTitle.handle_info({:tap, :add_by_hand}, socket)
        assert {:push, Kati.Screens.AddByHand, _params} = pushed.__mob__.nav_action

        {:ok, form} = Kati.Screens.AddByHand.mount(%{}, %{}, %Mob.Socket{})
        assert form.assigns.title == typed

        {:noreply, _saved} = Kati.Screens.AddByHand.handle_info({:tap, :add}, form)

        cached =
          Enum.find(Ash.read!(CachedTitle), &(&1.source == :manual and &1.source_id == typed))

        assert cached, "the typed title was not written"
        assert cached.poster_path == nil
        assert_only_tmdb_posters!(before)
      end)
    after
      restore_key()
    end
  end

  describe "with no TMDB token" do
    test "the step draws the token door once, and it opens screen 80" do
      Kati.Sources.put_tmdb_key(:own)
      refute Kati.Media.Tmdb.usable?(), "this host has a reader's own TMDB token stored"

      socket = socket_for()
      refute socket.assigns.tmdb_ready

      {:noreply, typed} =
        OnboardingFirstTitle.handle_info({:change, :title_query, "spirited"}, socket)

      {:noreply, refused} = OnboardingFirstTitle.handle_info({:search_ready, "spirited"}, typed)
      assert refused.assigns.search_reason == :no_api_key

      drawn = inspect(OnboardingFirstTitle.render(refused.assigns), limit: :infinity)
      assert length(String.split(drawn, "Add your TMDB token")) == 2

      {:noreply, opened} = OnboardingFirstTitle.handle_info({:tap, :add_tmdb_token}, refused)
      assert {:push, Kati.Screens.DataSources, _params} = opened.__mob__.nav_action
    after
      restore_key()
    end
  end

  defp restore_key, do: Kati.Sources.put_tmdb_key(Process.get(:tmdb_key_choice, :own))

  defp new_cached(before) do
    Enum.reject(Ash.read!(CachedTitle), &MapSet.member?(before, &1.id))
  end

  defp cached_ids, do: MapSet.new(Ash.read!(CachedTitle), & &1.id)

  defp socket_for do
    {:ok, socket} = OnboardingFirstTitle.mount(%{}, %{}, %Mob.Socket{})
    socket
  end

  defp search(socket, query) do
    {:noreply, typed} = OnboardingFirstTitle.handle_info({:change, :title_query, query}, socket)
    {:noreply, found} = OnboardingFirstTitle.handle_info({:search_ready, query}, typed)
    {found, found.assigns.results}
  end

  defp stub_tmdb!(search_body \\ nil) do
    Kati.Sources.put_tmdb_key(:kati)
    System.put_env("TMDB_READ_TOKEN", "test-token")

    for size <- ~w(w342 w780) do
      File.mkdir_p!(Path.dirname(artwork_file(size)))
      File.write!(artwork_file(size), "poster")
    end

    stub(fn req ->
      body =
        case req.url.path do
          "/3/search/multi" ->
            if search_body, do: search_body.(), else: search_answer()

          "/3/movie/129" ->
            %{
              "id" => 129,
              "title" => "Spirited Away",
              "release_date" => "2001-07-20",
              "runtime" => 125,
              "poster_path" => @poster,
              "genres" => [%{"id" => 16, "name" => "Animation"}],
              "original_language" => "ja"
            }
        end

      {req, Req.Response.new(status: 200, body: body)}
    end)
  end

  defp search_answer do
    %{
      "results" => [
        %{
          "media_type" => "movie",
          "id" => 129,
          "title" => "Spirited Away",
          "release_date" => "2001-07-20",
          "overview" => "A girl in a spirit world.",
          "poster_path" => @poster
        }
      ]
    }
  end

  defp stub(fun) do
    Application.put_env(:kati, :tmdb_test_stub, fun)
    Application.put_env(:kati, :tmdb_req_options, adapter: Adapter)
  end

  defp artwork_file(size) do
    Path.join([Mob.data_dir(), "artwork", size <> "_" <> String.trim_leading(@poster, "/")])
  end

  defp assert_only_tmdb_posters!(before) do
    for %CachedTitle{poster_path: path, title: title} <- new_cached(before),
        not is_nil(path) do
      assert String.starts_with?(path, "/"),
             "#{title} carries #{inspect(path)}, which is not a TMDB path"
    end
  end

  defp reset_target(socket) do
    case socket.__mob__.nav_action do
      r when is_tuple(r) and elem(r, 0) == :reset -> elem(r, 1)
      _other -> nil
    end
  end

  defp rolled_back(fun) when is_function(fun, 0) do
    {:error, {:rolled_back, result}} =
      Kati.Repo.transaction(fn -> Kati.Repo.rollback({:rolled_back, fun.()}) end)

    result
  end
end
