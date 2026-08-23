Code.require_file("support/screen_sweep.exs", __DIR__ |> Path.join("..") |> Path.expand())

defmodule THero do
  use Mob.ScreenCase, async: false
  alias Kati.ScreenSweep

  test "dump" do
    IO.inspect(Kati.Screens.Weight.drawn_entries() |> hd(), label: "ENTRY")
    IO.inspect(Kati.Screens.HealthFa.reading(), label: "READING")
  rescue
    e -> IO.inspect(e, label: "ERR")
  end

  test "tree" do
    ScreenSweep.with_locale(:fa, fn ->
      {:ok, _s, tree} = ScreenSweep.render(Kati.Screens.HealthFa)

      texts =
        tree
        |> Mob.ScreenCase.flatten()
        |> Enum.filter(&(&1.type == :text))
        |> Enum.map(&(&1.props[:text] || ""))

      IO.inspect(Enum.take(texts, 10), label: "TEXTS")
    end)
  end
end
