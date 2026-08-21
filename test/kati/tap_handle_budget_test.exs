Code.require_file("../support/screen_sweep.exs", __DIR__)

defmodule Kati.TapHandleBudgetTest do
  @moduledoc """
  Every screen's tap-handle count, against Mob's hard cap of 256 (#38).

  The cap is not a performance guideline. `MAX_TAP_HANDLES = 256` is enforced in
  `mob_nif.zig:940` and `mob_nif.m:63`; over it `nif_register_tap` returns
  `badarg`, which raises inside `Mob.Renderer.prepare_props/4` and **kills the
  screen process** — and a screen process has no supervisor to restart it. So
  crossing it does not make the app slow, it makes the screen disappear.

  Nothing measured this before, which meant the safety margin was unknown. It
  is a test rather than a one-off script because the number moves every time a
  list grows a row or a row grows a control, and the failure it prevents is
  invisible until it is fatal.
  """
  use Mob.ScreenCase, async: false

  alias Kati.ScreenSweep

  @cap 256

  # Headroom, not the cap. A screen at 250 passes the cap and is one design
  # change from dying, so the test fails while there is still room to act.
  @budget 180

  # Count nodes that CARRY an on_tap, not nodes whose on_tap is an integer.
  #
  # The integer handle is what `nif_register_tap` hands back on the device; on
  # the host the prop is still `{pid, tag}` and mob_nif does not load at all.
  # Testing for an integer therefore counted ZERO on every screen and passed —
  # a check that measured nothing and said everything was fine. It was caught
  # only by printing the numbers rather than trusting the green.
  #
  # One on_tap becomes one registered handle at render time, so counting the
  # props is the same budget one frame later.
  defp tap_handles(node) when is_map(node) do
    own = if Map.get(node.props || %{}, :on_tap) not in [nil, false], do: 1, else: 0
    own + Enum.sum(Enum.map(node.children || [], &tap_handles/1))
  end

  defp tap_handles(_), do: 0

  test "no screen approaches the 256-handle cap that would kill its process" do
    counts =
      for module <- Kati.Screens.Gallery.screens() |> Enum.map(&elem(&1, 2)) |> Enum.uniq() do
        {:ok, _socket, tree} = ScreenSweep.render(module)
        {module, tree |> List.wrap() |> Enum.map(&tap_handles/1) |> Enum.sum()}
      end

    if System.get_env("HANDLE_REPORT") do
      counts
      |> Enum.sort_by(&elem(&1, 1), :desc)
      |> Enum.take(8)
      |> Enum.each(fn {m, n} -> IO.puts("  #{n |> Integer.to_string() |> String.pad_leading(3)}  #{inspect(m)}") end)

      nums = Enum.map(counts, &elem(&1, 1))
      IO.puts("  #{length(nums)} screens: max #{Enum.max(nums)}, median #{Enum.sort(nums) |> Enum.at(div(length(nums), 2))}, headroom #{@cap - Enum.max(nums)}")
    end

    over = Enum.filter(counts, fn {_m, n} -> n > @budget end)
    worst = Enum.max_by(counts, &elem(&1, 1))

    assert counts != [], "no screens were measured — the gallery list is the source"

    assert over == [],
           """
           #{length(over)} screen(s) over the #{@budget}-handle budget (hard cap #{@cap},
           over which the screen PROCESS DIES with no supervisor):

             #{Enum.map_join(over, "\n  ", fn {m, n} -> "#{inspect(m)}: #{n}" end)}

           Worst overall: #{inspect(elem(worst, 0))} at #{elem(worst, 1)}.
           """
  end
end
