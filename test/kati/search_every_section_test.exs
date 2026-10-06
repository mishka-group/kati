defmodule Kati.SearchEverySectionTest do
  @moduledoc """
  All searches every section the chips name: an album, a recipe and an
  expense are found beside films and books, each under its own heading.
  """
  use Mob.ScreenCase, async: false

  setup do
    on_exit(fn ->
      Kati.Repo.query!("DELETE FROM music_albums WHERE title LIKE 'Zephyr%'", [])
      Kati.Repo.query!("DELETE FROM expenses WHERE description LIKE 'Zephyr%'", [])
    end)

    :ok
  end

  test "an album and an expense are found under All, and each scope counts its own" do
    Ash.create!(Kati.Music.Album, %{title: "Zephyr Nights"})
    Ash.create!(Kati.Money.Expense, %{description: "Zephyr tickets", spent_on: Kati.Time.today()})

    results = Kati.Search.Query.run("zephyr")

    assert [%{kind: :album, title: "Zephyr Nights"}] = results.music
    assert [%{kind: :expense, title: "Zephyr tickets"}] = results.money

    counts = Map.new(Kati.Search.Query.chip_counts(results), fn {key, _l, n} -> {key, n} end)
    assert counts.music == 1
    assert counts.money == 1
    assert counts.all >= 2

    groups = Kati.Screens.Search.visible_groups(results, :all) |> Enum.map(&elem(&1, 0))
    assert :music in groups
    assert :money in groups

    view = mount_screen(Kati.Screens.Search, %{query: "zephyr"})
    words = inspect(tree(view), limit: :infinity, printable_limit: :infinity)
    assert words =~ "Zephyr Nights"
    assert words =~ "Zephyr tickets"
  end
end
