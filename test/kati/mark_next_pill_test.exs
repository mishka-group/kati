defmodule Kati.MarkNextPillTest do
  @moduledoc """
  The series page's *Mark watched* pill keeps its label inside it (#117): side
  padding, a smaller face, and `E12` in place of *episode 12*, so a long
  show's four-digit episode still fits beside the three discs.
  """
  use Mob.ScreenCase, async: false

  doctest Kati.Screens.Series, only: [mark_next_label: 1]

  alias Kati.Screens.Series

  setup do
    Kati.Locale.put(:en)
    on_exit(fn -> Kati.Locale.put(:en) end)
    :ok
  end

  test "the label names the episode as E and its number, at any length" do
    for n <- [1, 12, 128, 1024] do
      assert Series.mark_next_label(%{episodes: [%{n: n, watched: false}]}) ==
               "Mark E#{n} watched"
    end
  end

  test "the next unwatched episode is the one named" do
    episodes = [%{n: 1, watched: true}, %{n: 2, watched: false}]
    assert Series.mark_next_label(%{episodes: episodes}) == "Mark E2 watched"
  end

  test "Persian keeps board 58's sentence" do
    label =
      Kati.Locale.as(:fa, fn ->
        Series.mark_next_label(%{episodes: [%{n: 6, watched: false}]})
      end)

    assert label == "قسمت ۶ را دیده‌ام"
  end

  test "the pill pads its label off both ends" do
    pill =
      Series.actions(%{episodes: [%{n: 1, watched: false}], tracked_id: nil})
      |> inspect(limit: :infinity)

    assert pill =~ "padding_left: 16"
    assert pill =~ "padding_right: 16"
    assert pill =~ "text_size: 12.5"
  end
end
