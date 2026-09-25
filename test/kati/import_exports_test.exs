defmodule Kati.ImportExportsTest do
  @moduledoc """
  A MyAnimeList `animelist.xml` and an AniList JSON export import (P5).

  The import read only CSV, so the file screen 140's MyAnimeList tile names
  was answered *unrecognised*.
  """

  use Mob.ScreenCase, async: false

  alias Kati.Import.Job

  doctest Kati.Import.Exports

  @fixture Path.expand("../fixtures/import/animelist.xml", __DIR__)

  test "a MyAnimeList export is recognised, and every row is anime" do
    assert {:ok, job} = Job.read(@fixture, "animelist.xml")

    assert job.looks_like == "myanimelist"
    titles = Enum.map(job.records, & &1.title)
    assert "Sousou no Frieren" in titles
    assert "Cowboy Bebop" in titles
    assert Enum.all?(job.records, &(&1.kind == :anime))
  end

  test "its score is read as ten-point, and unscored and undated stay blank" do
    {:ok, job} = Job.read(@fixture, "animelist.xml")
    by_title = Map.new(job.records, &{&1.title, &1})

    assert by_title["Sousou no Frieren"].rating == 10
    assert by_title["Sousou no Frieren"].watched_on == ~D[2024-03-22]
    assert by_title["Cowboy Bebop"][:rating] == nil
    assert by_title["Cowboy Bebop"][:watched_on] == nil
  end

  test "an AniList export on a hundred-point scale is brought to ten" do
    json =
      JSON.encode!(%{
        "lists" => [
          %{
            "name" => "Completed",
            "entries" => [
              %{
                "score" => 85,
                "completedAt" => %{"year" => 2024, "month" => 3, "day" => 9},
                "media" => %{
                  "id" => 154_587,
                  "format" => "TV",
                  "title" => %{"romaji" => "Frieren"}
                }
              }
            ]
          }
        ]
      })

    path =
      Path.join(System.tmp_dir!(), "anilist-export-#{System.unique_integer([:positive])}.json")

    File.write!(path, json)

    assert {:ok, job} = Job.read(path, "anilist-export.json")
    assert job.looks_like == "anilist"
    assert [%{title: "Frieren", rating: 9, kind: :anime}] = job.records

    File.rm(path)
  end

  test "a CSV still reads as CSV" do
    path = Path.join(System.tmp_dir!(), "plain-#{System.unique_integer([:positive])}.csv")
    File.write!(path, "Title,Rating\nDune,4\n")

    assert {:ok, job} = Job.read(path, "plain.csv")
    assert [%{title: "Dune"}] = job.records

    File.rm(path)
  end
end
