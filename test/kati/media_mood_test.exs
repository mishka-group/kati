defmodule Kati.MediaMoodTest do
  @moduledoc """
  Mood, pace and content warnings — the recording layer #16 asks for.

  ## The three questions #16 left open, and where they are answered

    * **Fixed or extensible vocabulary** — fixed. The point of recording a mood
      is that it aggregates, and free text does not: "tense", "Tense" and "a
      bit tense" are three moods to a database and one to a person.
    * **Title or viewing** — the viewing. #16's own example settles it: a
      rewatch in a different frame of mind. The title-level answer is derived
      from the watches; the reverse cannot be.
    * **Where warnings come from** — the user, plus an import. Kati has no
      source, and `origin` is what keeps the two distinguishable.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Media.ContentWarning
  alias Kati.Media.Mood
  alias Kati.Media.WarningPreference

  # Every row this file writes is removed again, and that is not tidiness.
  # `Kati.ScreenDesignLiteralTest` renders screens 05, 07 and 08 against this
  # same shared database file and each falls back to its drawing only while the
  # tables are empty. A `:movie` tracked row left behind here makes screen 08
  # take the real path instead, and the drawing's literals stop appearing — a
  # failure that lands on a file this one never touched, and only for the seeds
  # that order the two modules the wrong way round.
  #
  # `Kati.Screens.SeriesSettings`' moduledoc records the same hazard from the
  # other side: a coin flip, not a flake.
  @prefix "mood-test-"

  setup do
    on_exit(&delete_rows!/0)
    :ok
  end

  defp delete_rows! do
    # Warnings first: the foreign key refuses the delete below otherwise. Raw
    # SQL because this runs from `on_exit`, after the test process is gone.
    Kati.Repo.query!(
      """
      DELETE FROM media_content_warnings
      WHERE tracked_title_id IN (SELECT id FROM tracked_titles WHERE source_id LIKE ?1)
      """,
      [@prefix <> "%"]
    )

    Kati.Repo.query!(
      "DELETE FROM media_watches WHERE tracked_title_id IN " <>
        "(SELECT id FROM tracked_titles WHERE source_id LIKE ?1)",
      [@prefix <> "%"]
    )

    Kati.Repo.query!("DELETE FROM tracked_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
    :ok
  end

  # `source` and `source_id` are required — a tracked title is always something
  # a provider named, even when the user typed the name.
  defp tracked_title(attrs) do
    Kati.Media.TrackedTitle
    |> Ash.Changeset.for_create(
      :create,
      Enum.into(attrs, %{
        source: :tmdb,
        source_id: @prefix <> "#{System.unique_integer([:positive])}"
      })
    )
    |> Ash.create!()
  end

  describe "the vocabulary is closed" do
    test "fourteen moods, exactly the brief's" do
      assert length(Mood.vocabulary()) == 14

      assert Mood.vocabulary() == [
               :adventurous,
               :challenging,
               :dark,
               :emotional,
               :funny,
               :hopeful,
               :informative,
               :inspiring,
               :lighthearted,
               :mysterious,
               :reflective,
               :relaxing,
               :sad,
               :tense
             ]
    end

    test "an unknown mood is dropped, not stored and not raised over" do
      # A StoryGraph export carries its own vocabulary and the overlap is
      # partial. Refusing a whole import over one unmapped word would lose the
      # thirteen that did match.
      assert Mood.parse(["tense", "whimsical", "dark"]) == [:tense, :dark]
    end

    test "parsing is case- and whitespace-insensitive, and de-duplicates" do
      assert Mood.parse(" Tense , tense,DARK ") == [:tense, :dark]
      assert Mood.parse("") == []
      assert Mood.parse(nil) == []
    end

    test "labels are derived, so there is no second list to drift" do
      for mood <- Mood.vocabulary() do
        assert Mood.label(mood) == String.capitalize(Atom.to_string(mood))
      end
    end
  end

  describe "mood lives on the viewing" do
    test "the same title can be funny once and sad the next time" do
      # The claim that decides where the column goes. On the title this is
      # unsayable; the schema would have to overwrite one with the other.
      watches = [%{moods: [:funny, :lighthearted]}, %{moods: [:sad, :reflective]}]

      assert Mood.for_title(watches) == [:funny, :lighthearted, :reflective, :sad]
    end

    test "a title's moods are ordered by how often they were chosen" do
      watches = [%{moods: [:tense]}, %{moods: [:tense, :dark]}, %{moods: [:tense]}]
      assert hd(Mood.for_title(watches)) == :tense
    end

    test "a distribution omits moods with no watches rather than reporting zero" do
      # Fourteen bars with eleven empty says less than three bars.
      dist = Mood.distribution([%{moods: [:dark]}, %{moods: [:dark, :sad]}])
      assert dist == [{:dark, 2}, {:sad, 1}]
      refute Enum.any?(dist, fn {_m, count} -> count == 0 end)
    end

    test "watches with no moods contribute nothing and do not crash" do
      assert Mood.distribution([%{moods: []}, %{moods: nil}, %{moods: [:sad]}]) == [{:sad, 1}]
    end
  end

  describe "a warning category is normalised so it can be keyed on" do
    test "case and spacing collapse to one category" do
      # Screens 11 and 19 look a title's categories up against the preference
      # table. That lookup is an equality test, so "Animal  Death " and
      # "animal death" have to arrive as the same string or the index cannot
      # serve it.
      assert ContentWarning.normalise("Animal  Death ") == "animal death"
      assert ContentWarning.normalise("animal death") == "animal death"
    end

    test "something that normalises to nothing is nil, not an empty row" do
      assert ContentWarning.normalise("   ") == nil
      assert ContentWarning.normalise(nil) == nil
    end
  end

  describe "three stances, and the worst one wins" do
    test "avoid beats warn beats show" do
      prefs = %{"animal death" => :avoid, "grief" => :warn}

      assert WarningPreference.verdict(["grief", "animal death"], prefs) == :avoid
      assert WarningPreference.verdict(["grief"], prefs) == :warn
      assert WarningPreference.verdict(["grief", "war"], prefs) == :warn
    end

    test "an unrecorded category shows — it is not a silent avoid" do
      assert WarningPreference.verdict(["war"], %{}) == :show
      assert WarningPreference.verdict([], %{"war" => :avoid}) == :show
    end
  end

  describe "the three fields reach the database" do
    test "a watch round-trips moods, pace and driven_by" do
      title = tracked_title(kind: :movie)

      watch =
        Kati.Media.Watch
        |> Ash.Changeset.for_create(:create, %{
          tracked_title_id: title.id,
          moods: [:tense, :dark],
          pace: :fast,
          driven_by: :character
        })
        |> Ash.create!()

      reloaded = Ash.get!(Kati.Media.Watch, watch.id)

      # The array survives SQLite, which is the part worth proving: ash_sqlite
      # stores it as JSON and a string column would have silently accepted the
      # same write and returned a string.
      assert reloaded.moods == [:tense, :dark]
      assert reloaded.pace == :fast
      assert reloaded.driven_by == :character
    end

    test "a mood outside the vocabulary is refused at the boundary" do
      title = tracked_title(kind: :movie)

      assert {:error, _} =
               Kati.Media.Watch
               |> Ash.Changeset.for_create(:create, %{
                 tracked_title_id: title.id,
                 moods: [:whimsical]
               })
               |> Ash.create()
    end

    test "a warning records where it came from" do
      title = tracked_title(kind: :book)

      warning =
        Kati.Media.ContentWarning
        |> Ash.Changeset.for_create(:create, %{
          tracked_title_id: title.id,
          category: ContentWarning.normalise("Animal Death"),
          origin: :import
        })
        |> Ash.create!()

      assert warning.category == "animal death"
      assert warning.origin == :import
    end

    test "origin defaults to the user, because that is who usually typed it" do
      title = tracked_title(kind: :book)

      warning =
        Kati.Media.ContentWarning
        |> Ash.Changeset.for_create(:create, %{tracked_title_id: title.id, category: "grief"})
        |> Ash.create!()

      assert warning.origin == :user
    end
  end
end
