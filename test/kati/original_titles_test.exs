defmodule Kati.OriginalTitlesTest do
  @moduledoc """
  Screen 54's *Title language* switch is stored, and the film and series
  headers follow it.

  It was drawn on with nothing behind it, and no page in the app showed an
  original title (A6).
  """

  use Mob.ScreenCase, async: false

  alias Kati.Screens.Language

  doctest Kati.Locale, only: [original_title: 2]

  setup do
    before = Mob.State.get(:kati_original_titles)
    Mob.State.delete(:kati_original_titles)

    {:ok, before: before}
  end

  defp restore(nil), do: Mob.State.delete(:kati_original_titles)
  defp restore(value), do: Mob.State.put(:kati_original_titles, value)

  test "on by default, which is what board 54 draws", %{before: before} do
    assert Kati.Locale.original_titles?()
    restore(before)
  end

  test "the switch writes the choice and draws it", %{before: before} do
    socket =
      Language
      |> Mob.Socket.new()
      |> Language.load()

    assert socket.assigns.original_titles?

    {:noreply, off} = Language.handle_tap(:toggle_original_titles, socket)

    refute Kati.Locale.original_titles?()
    refute off.assigns.original_titles?

    assert [%{control: {:switch, false}}] =
             Enum.filter(
               Language.settled_content(off.assigns.original_titles?),
               &(&1.icon == "subtitles")
             )

    {:noreply, on} = Language.handle_tap(:toggle_original_titles, off)
    assert Kati.Locale.original_titles?()
    assert on.assigns.original_titles?

    restore(before)
  end

  test "the header line is there when on, and gone when off", %{before: before} do
    cached = %{title: "Spirited Away", title_original: "千と千尋の神隠し"}

    Kati.Locale.put_original_titles(true)
    drawn = inspect(Kati.UI.original_title(Kati.Locale.original_title(cached)), limit: :infinity)
    assert drawn =~ "千と千尋の神隠し"

    Kati.Locale.put_original_titles(false)
    assert Kati.UI.original_title(Kati.Locale.original_title(cached)) == []

    restore(before)
  end

  test "rows that open nothing draw no chevron" do
    assert Language.control(:chevron, nil) == Kati.Screens.Language.control_none()
    assert Language.control(:chevron, {self(), :open_currency}) == Kati.UI.SettingsList.chevron()
  end
end
