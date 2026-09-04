Code.require_file("../support/screen_sweep.exs", __DIR__)

defmodule Kati.ScreenSubmitSweepTest do
  @moduledoc """
  Every keyboard action a screen draws reaches a handler.

  ## A submit is not a tap, and that is the whole reason this exists

  `Kati.ScreenTapSweepTest` walks the `on_tap` tags a rendered tree carries and
  asks whether something answers each one. A field's `on_submit` is not one of
  those: `mob_send_submit/1` in mob's NIF sends `{:submit, tag}` where a tap
  sends `{:tap, tag}`, so a screen can draw a Search key on the keyboard, wire
  it to a handler written as a `handle_tap/2` clause, and have the key do
  nothing at all. Nothing anywhere fails.

  That is not hypothetical. Screen 86's `Kati.Screens.SearchIdle.look/1` — the
  function that carries a query from the idle board to the results board — was
  written when the screen was, and was called by nothing for as long as it
  existed. When it was finally wired it was wired as a tap, and the mistake was
  found by reading mob's NIF rather than by any check in this suite.

  ## What it asks

  For every screen, in both locales: collect the `on_submit` tags the tree
  draws, and hand each one to the screen as `{:submit, tag}`. A handler that
  answers must do something — navigate, or change the assigns. A clause that
  matches and returns the socket untouched is the same dead key with a
  `handle_info/2` in front of it.

  There is no allow-list. A field carries `on_submit` because somebody meant
  the keyboard's action key to do something; if it should do nothing, it should
  not carry the prop.
  """
  use Mob.ScreenCase, async: false

  alias Kati.ScreenSweep

  for locale <- [:en, :fa] do
    test "every on_submit a screen draws reaches something that acts, in #{locale}" do
      dead = ScreenSweep.with_locale(unquote(locale), &dead_submits/0)

      assert dead == [], """
      these keyboard action keys are drawn and answered by nothing, so pressing
      Search or Go does nothing and the build stays green. A submit arrives as
      `{:submit, tag}`, NOT as `{:tap, tag}` — a `handle_tap/2` clause for one
      never fires, and the tap sweep cannot see it either.

      #{Enum.join(dead, "\n")}
      """
    end
  end

  test "the sweep found some to check, so a silent zero is not a pass" do
    # The failure mode of every sweep in this directory: a discovery step that
    # quietly answers nothing reports success over an empty list. At the time
    # of writing exactly one screen draws an `on_submit` — screen 86's field —
    # so the floor is one and it is a floor rather than an equality, because
    # the honest direction for this number is up.
    drawn = ScreenSweep.with_locale(:en, &submit_tags/0)

    assert drawn != [],
           "no screen draws an on_submit at all, so the test above passed over nothing"
  end

  defp submit_tags do
    for module <- ScreenSweep.screens(),
        {:ok, socket, tree} <- [ScreenSweep.render(module)],
        node <- Mob.ScreenCase.flatten(tree),
        props = Map.get(node, :props) || %{},
        {pid, tag} <- [props[:on_submit]],
        is_pid(pid) and is_atom(tag),
        do: {module, socket, tag}
  end

  defp dead_submits do
    for {module, socket, tag} <- submit_tags(),
        reason = inert(module, socket, tag),
        do: "  #{inspect(module)} draws on_submit #{inspect(tag)}: #{reason}"
  end

  # `nil` when the submit did something. A string saying what went wrong when
  # it did not.
  defp inert(module, socket, tag) do
    case ScreenSweep.safely(fn -> module.handle_info({:submit, tag}, socket) end) do
      {:ok, {:noreply, %Mob.Socket{} = moved}} ->
        navigated? = Map.get(moved.__mob__, :nav_action) != nil

        if navigated? or moved.assigns != socket.assigns,
          do: nil,
          else: "answered and changed nothing — a clause that matches is not a clause that acts"

      {:ok, other} ->
        "answered #{inspect(other, limit: 3)} instead of {:noreply, socket}"

      {:error, message} ->
        message
    end
  end
end
