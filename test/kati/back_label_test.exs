defmodule Kati.BackLabelTest do
  @moduledoc """
  What the floating back pill says it will do.

  Every pushed page in the app names its origin in the pill, and until now that
  name was a compile-time constant: `use Kati.Screens.Pushed, back: "Library"`,
  or the word written straight into the markup on the hand-rolled pages.

  A film is pushed from the Library shelf AND from Home's *Continue watching*.
  Both arrivals drew `Library`. On the Home path the word was wrong twice over:
  it is not where you came from, and — because the tap pops one screen, and so
  does the phone's own back gesture — it is not where the pill takes you. The
  pill described a journey the app was not going to make.

  The pushing screen is the only thing that knows where you were, so it says
  so: `%{back: "Home"}` alongside whatever else it carries. Every pushed page
  reads that, falling back to its own declaration, so a push that names no
  origin (the gallery's, a test's) still draws exactly the word it always drew.

  These are the Movies and TV routes, which is where the lie was found.
  """

  use Mob.ScreenCase, async: false

  alias Kati.Screens.Pushed

  describe "back_label/2" do
    test "the pushing screen's name wins" do
      assert Pushed.back_label(%{back: "Home"}, "Library") == "Home"
    end

    test "a push that says nothing keeps the page's own declaration" do
      assert Pushed.back_label(%{id: "x"}, "Library") == "Library"
      assert Pushed.back_label(%{}, "Library") == "Library"
      assert Pushed.back_label(nil, "Library") == "Library"
    end

    test "an empty or non-binary origin is not an origin" do
      assert Pushed.back_label(%{back: ""}, "Library") == "Library"
      assert Pushed.back_label(%{back: :home}, "Library") == "Library"
    end
  end

  describe "screen 08 — a film" do
    test "opened from Home, the pill says Home" do
      assert Kati.Screens.Film.render(film_assigns(%{back: "Home"}))
             |> text_of() =~ "Home"
    end

    test "opened from the Library shelf, the pill says Library" do
      film = %{back: "Library"}
      assert Kati.Screens.Film.render(film_assigns(film)) |> text_of() =~ "Library"
    end

    test "a bare mount still draws the word the board draws" do
      {:ok, socket} = Kati.Screens.Film.mount(%{}, %{}, Mob.Socket.new(Kati.Screens.Film))
      assert socket.assigns.back == "Library"
    end

    test "mount takes the origin the pusher named" do
      {:ok, socket} =
        Kati.Screens.Film.mount(%{back: "Home"}, %{}, Mob.Socket.new(Kati.Screens.Film))

      assert socket.assigns.back == "Home"
    end
  end

  describe "screen 04 — a series" do
    test "a bare mount draws the board's word" do
      {:ok, socket} = Kati.Screens.Series.mount(%{}, %{}, Mob.Socket.new(Kati.Screens.Series))
      assert socket.assigns.back == "Library"
    end

    test "opened from Home, the pill says Home" do
      {:ok, socket} =
        Kati.Screens.Series.mount(%{back: "Home"}, %{}, Mob.Socket.new(Kati.Screens.Series))

      assert socket.assigns.back == "Home"
    end
  end

  describe "screen 34 — a series' details" do
    test "is reached from the series, not the shelf" do
      {:ok, socket} =
        Kati.Screens.SeriesMeta.mount(%{}, %{}, Mob.Socket.new(Kati.Screens.SeriesMeta))

      assert socket.assigns.back == "Series"
      refute socket.assigns.back == "Library"
    end
  end

  describe "the Persian series page" do
    test "opened from Persian search, the pill says search" do
      {:ok, socket} =
        Kati.Screens.SeriesFa.mount(%{back: "جست‌وجو"}, %{}, Mob.Socket.new(Kati.Screens.SeriesFa))

      assert socket.assigns.series.back == "جست‌وجو"
    end

    test "a bare mount keeps the board's word" do
      {:ok, socket} = Kati.Screens.SeriesFa.mount(%{}, %{}, Mob.Socket.new(Kati.Screens.SeriesFa))
      assert socket.assigns.series.back == "کتابخانه"
    end
  end

  describe "a macro-built page" do
    test "reads the origin out of the params its mount stored" do
      {:ok, socket} =
        Kati.Screens.MyServices.mount(
          %{back: "Home"},
          %{},
          Mob.Socket.new(Kati.Screens.MyServices)
        )

      assert Kati.Screens.MyServices.render(socket.assigns) |> text_of() =~ "Home"
    end

    test "and keeps its own when the push named none" do
      {:ok, socket} =
        Kati.Screens.MyServices.mount(%{}, %{}, Mob.Socket.new(Kati.Screens.MyServices))

      assert Kati.Screens.MyServices.render(socket.assigns) |> text_of() =~ "Settings"
    end
  end

  defp film_assigns(overrides) do
    Map.merge(%{film: Kati.Screens.Film.film(), menu?: false}, overrides)
  end

  defp text_of(tree), do: tree |> inspect(limit: :infinity, printable_limit: :infinity)
end
