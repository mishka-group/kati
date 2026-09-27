defmodule Kati.Test.KeylessStubs do
  @moduledoc """
  AniList and TVmaze as canned catalogues, for the tests about screen 19's
  keyless sections and the title pages they lead to.

  `install!/0` hands both clients an adapter through their Req seams;
  `restore!/0` puts the suite's offline default back. Every request is also
  sent to the installing process as `{:keyless_request, source, what}` so a
  test can say what was — and was not — asked.

  Two AniList titles: *SAKAMOTO DAYS* (177709, a series of three episodes
  here) and *Your Name.* (21519, a film). Two TVmaze shows: *Sakamoto Days*
  (77777, the same anime, same year) and *Sakamoto Desu ga?* (4444, 2016).
  """

  defmodule AnilistAdapter do
    @moduledoc false
    def run(request), do: Kati.Test.KeylessStubs.anilist(request)
  end

  defmodule TvmazeAdapter do
    @moduledoc false
    def run(request), do: Kati.Test.KeylessStubs.tvmaze(request)
  end

  def install!(opts \\ []) do
    :persistent_term.put({__MODULE__, :owner}, self())
    :persistent_term.put({__MODULE__, :opts}, opts)
    Application.put_env(:kati, :anilist_req_options, adapter: AnilistAdapter, retry: false)
    Application.put_env(:kati, :tvmaze_req_options, adapter: TvmazeAdapter, retry: false)
  end

  def restore! do
    Kati.TestOffline.restore(:anilist_req_options)
    Kati.TestOffline.restore(:tvmaze_req_options)
    :persistent_term.erase({__MODULE__, :opts})
  end

  defp opts, do: :persistent_term.get({__MODULE__, :opts}, [])

  defp tell(message) do
    case :persistent_term.get({__MODULE__, :owner}, nil) do
      pid when is_pid(pid) -> send(pid, message)
      _nobody -> :ok
    end
  end

  def anilist(request) do
    variables = request.body |> IO.iodata_to_binary() |> Jason.decode!() |> Map.get("variables")

    case {Keyword.get(opts(), :anilist), variables} do
      {status, _variables} when is_integer(status) ->
        tell({:keyless_request, :anilist, :failed})
        {request, Req.Response.new(status: status, body: "")}

      {_ok, %{"s" => query}} ->
        tell({:keyless_request, :anilist, {:search, query}})
        media = if query =~ ~r/sakamoto/i, do: [sakamoto(), your_name()], else: []
        json(request, %{"data" => %{"Page" => %{"media" => media}}})

      {_ok, %{"id" => 177_709}} ->
        tell({:keyless_request, :anilist, {:detail, 177_709}})
        json(request, %{"data" => %{"Media" => sakamoto()}})

      {_ok, %{"id" => 21_519}} ->
        tell({:keyless_request, :anilist, {:detail, 21_519}})
        json(request, %{"data" => %{"Media" => your_name()}})
    end
  end

  def tvmaze(request) do
    case {Keyword.get(opts(), :tvmaze), request.url.path} do
      {status, _path} when is_integer(status) ->
        tell({:keyless_request, :tvmaze, :failed})
        {request, Req.Response.new(status: status, body: "")}

      {_ok, "/search/shows"} ->
        query = URI.decode_query(request.url.query || "")["q"]
        tell({:keyless_request, :tvmaze, {:search, query}})

        hits =
          if query =~ ~r/sakamoto/i,
            do: [%{"score" => 0.9, "show" => days()}, %{"score" => 0.5, "show" => desu_ga()}],
            else: []

        json(request, hits)

      {_ok, "/shows/4444"} ->
        tell({:keyless_request, :tvmaze, {:detail, 4444}})
        json(request, Map.put(desu_ga(), "_embedded", desu_ga_embedded()))
    end
  end

  defp json(request, body), do: {request, Req.Response.new(status: 200, body: body)}

  def sakamoto do
    %{
      "id" => 177_709,
      "format" => "TV",
      "episodes" => 3,
      "duration" => 23,
      "title" => %{"romaji" => "SAKAMOTO DAYS", "english" => "SAKAMOTO DAYS"},
      "coverImage" => %{
        "large" => "https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx177709.jpg"
      },
      "startDate" => %{"year" => 2025, "month" => 1, "day" => 11},
      "countryOfOrigin" => "JP",
      "description" => "Taro Sakamoto was the ultimate assassin.",
      "genres" => ["Action", "Comedy"]
    }
  end

  def your_name do
    %{
      "id" => 21_519,
      "format" => "MOVIE",
      "episodes" => 1,
      "duration" => 106,
      "title" => %{"romaji" => "Kimi no Na wa.", "english" => "Your Name."},
      "coverImage" => %{
        "large" => "https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx21519.png"
      },
      "startDate" => %{"year" => 2016, "month" => 8, "day" => 26},
      "countryOfOrigin" => "JP",
      "description" => "Two strangers find themselves linked.",
      "genres" => ["Drama", "Romance"]
    }
  end

  def days do
    %{
      "id" => 77_777,
      "name" => "Sakamoto Days",
      "type" => "Animation",
      "language" => "Japanese",
      "premiered" => "2025-01-11",
      "image" => %{"medium" => "https://static.tvmaze.com/uploads/images/medium_portrait/7/7.jpg"}
    }
  end

  def desu_ga do
    %{
      "id" => 4444,
      "name" => "Sakamoto Desu ga?",
      "type" => "Animation",
      "language" => "Japanese",
      "genres" => ["Comedy", "Anime"],
      "premiered" => "2016-04-08",
      "summary" => "<p>The coolest high schooler.</p>",
      "image" => %{"medium" => "https://static.tvmaze.com/uploads/images/medium_portrait/4/4.jpg"}
    }
  end

  defp desu_ga_embedded do
    %{
      "seasons" => [%{"id" => 4400, "number" => 1, "name" => "", "episodeOrder" => 2}],
      "episodes" => [
        %{
          "id" => 44_001,
          "name" => "The Coolest High Schooler",
          "season" => 1,
          "number" => 1,
          "airdate" => "2016-04-08",
          "airstamp" => "2016-04-08T15:00:00+00:00",
          "runtime" => 24,
          "summary" => "<p>He arrives.</p>"
        },
        %{
          "id" => 44_002,
          "name" => "Bring It On",
          "season" => 1,
          "number" => 2,
          "airdate" => "2016-04-15",
          "airstamp" => "2016-04-15T15:00:00+00:00",
          "runtime" => 24
        }
      ]
    }
  end
end
