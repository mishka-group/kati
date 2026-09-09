defmodule Kati.Screens.Identity do
  @moduledoc """
  What a screen calls itself on the device.

  Nothing else on a phone says which of the 152 screens is on top.
  `MobBridge.RootState` carries a navigation counter and a transition name, and
  asserting on visible text is not a substitute: Kati draws the same strings in
  an English screen and its Persian mirror, and again in a live screen and its
  `— states` reference sheet. A device test that waited on the word *Library*
  could be looking at screen 03, screen 03's Persian twin, or a sheet
  demonstrating what screen 03 looks like.

  So every screen stamps `screen:<name>` as an `accessibility_id` on its root
  node. `Mob.Renderer` serialises any prop it does not special-case, so the
  value arrives in Kotlin under the key `K-35 test-tag` reads, and becomes a
  Compose `testTag` the harness can wait on.

  ## Why the name is derived

  `Kati.Screens.BookDetailFa` becomes `book_detail_fa`, from the module and
  nothing else. Hand-written names would be 152 opportunities to give two
  screens the same one, and a stamp that is not unique is worse than no stamp —
  it makes a test that waits for the wrong screen look like a test that passed.

  The three shells reach this differently and all end up here:
  `Kati.Shell.render/1` stamps the four roots by their root id,
  `Kati.Screens.Pushed.chrome/3` stamps every screen built on that macro, and
  the screens that hand-roll `use Mob.Screen` call `of/1` on their own root
  node.
  """

  @doc """
  The stamp for a screen module.

      iex> Kati.Screens.Identity.of(Kati.Screens.BookDetailFa)
      "screen:book_detail_fa"
  """
  @spec of(module()) :: String.t()
  def of(module) when is_atom(module) do
    "screen:" <> name(module)
  end

  @doc """
  The bare name, without the `screen:` prefix.

      iex> Kati.Screens.Identity.name(Kati.Screens.HomeDark)
      "home_dark"
  """
  @spec name(module()) :: String.t()
  def name(module) when is_atom(module) do
    module
    |> Module.split()
    |> List.last()
    |> Macro.underscore()
  end
end
