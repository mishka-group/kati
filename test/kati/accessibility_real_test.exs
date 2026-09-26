defmodule Kati.AccessibilityRealTest do
  @moduledoc """
  Screen 41 shows the reader's own Up next card, or none (A5).

  It drew *The Long Hollow · Season 2, episode 6* and a VoiceOver sentence
  about *The Undertow* on every phone, six switches that stored nothing, and a
  235% Dynamic Type claim the app does not keep.
  """

  use Mob.ScreenCase, async: false

  alias Kati.Screens.Accessibility

  doctest Kati.Screens.Accessibility, only: [voiceover_line: 1]

  defp drawn(hero) do
    socket =
      Accessibility
      |> Mob.Socket.new()
      |> Mob.Socket.assign(:spec, Kati.Accessibility.Sample.spec())
      |> Mob.Socket.assign(:hero, hero)

    inspect(Accessibility.render(socket.assigns), limit: :infinity, printable_limit: :infinity)
  end

  test "the reader's hero is the card, and the sentence names it" do
    words = drawn(%{title: "Dark", meta: "S1 · E3"})

    assert words =~ "Dark"
    assert words =~ "Dark. S1 · E3. Double-tap to open."
    refute words =~ "The Long Hollow"
    refute words =~ "The Undertow"
  end

  test "with nothing on the go there is no card and no sentence" do
    words = drawn(nil)

    refute words =~ "Double-tap"
    refute words =~ "The Long Hollow"
  end

  test "the guarantees are a legend: nothing on the page toggles" do
    tree = Accessibility.render(%{spec: Kati.Accessibility.Sample.spec(), hero: nil})

    taps =
      for %{props: %{on_tap: {_pid, tag}}} <- Mob.ScreenCase.flatten(tree),
          is_atom(tag),
          String.starts_with?(Atom.to_string(tag), "switch_"),
          do: tag

    assert taps == []
  end

  test "no 235% claim and no contrast row" do
    words = drawn(nil)

    refute words =~ "235%"
    refute words =~ "Increase contrast"
  end
end
