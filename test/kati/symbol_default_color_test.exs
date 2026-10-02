defmodule Kati.SymbolDefaultColorTest do
  @moduledoc """
  An icon handed `color: nil` takes the theme's ink, not Compose's black.

  The series page's discs pass their ink straight through and it is `nil` when
  a disc is off, so the list disc and an unfollowed bookmark were drawn black
  on a dark disc in dark mode.
  """
  use ExUnit.Case, async: false

  alias Kati.Theme.Palette

  test "nil and a missing colour are the same default" do
    assert Kati.UI.symbol("bookmark", color: nil).props.text_color == Palette.ink()
    assert Kati.UI.symbol("bookmark").props.text_color == Palette.ink()
  end

  test "the series page's off discs draw in that ink" do
    disc = Kati.Screens.Series.action_disc("bookmarks", nil, nil)
    assert inspect(disc, limit: :infinity) =~ Integer.to_string(Palette.ink())
  end
end
