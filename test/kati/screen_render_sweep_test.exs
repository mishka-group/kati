Code.require_file("../support/screen_sweep.exs", __DIR__)

defmodule Kati.ScreenRenderSweepTest do
  @moduledoc """
  Mounts and renders **every** screen, in **both** locales.

  ## What this is for

  A `~MOB` template is compiled markup, so most of what can be wrong with one
  is only wrong at render time, on a value that exists only after `mount/3` has
  run. Three of those failures ship a green build:

    * **`@name` reading an assign the screen never set.** Inside `~MOB` the
      sigil rewrites `@name` to `assigns.name`, so a typo or an assign that
      only `load/1` sets on one branch is a `KeyError` the first time a user
      opens the screen — and nothing before that moment says so.

    * **more than one root node in a sigil.** A `~MOB` block returns one node.
      Two siblings at the top produce a list, the bridge takes the first and
      silently drops the rest, and the screen loses half of itself with no
      error anywhere. The check for it is that a render is a bare
      `%{type: _}` map — never a list.

    * **a locale-only crash.** Kati ships `:en` and `:fa`, and RTL runs through
      different code — `Kati.Locale.direction_prop/0`, the `fa` font family,
      Persian digits. A screen can render in English and raise in Persian, and
      the Persian mirrors are a minority of the app, so nothing else exercises
      that path. Every screen is rendered twice.

  ## What it is not

  It proves each screen produces *a* tree, not the *right* tree. Nothing here
  compares against `test/design/screens/NN.html`; a screen that renders a
  blank box passes. Taps are `Kati.ScreenTapSweepTest`'s job.
  """
  # `Mob.ScreenCase` is the blessed in-BEAM screen harness: it opens the
  # DETS-backed `Mob.State` against a throwaway data dir (without it, every
  # screen that reads a setting in `mount/3` crashes on a `:dets` argument
  # error) and supplies `flatten/1` and `renderable_types/0`. `async: false`
  # because the locale this sweep switches is global.
  use Mob.ScreenCase, async: false

  alias Kati.ScreenSweep

  @locales [:en, :fa]
  @screens_dir Path.expand("../../lib/kati/screens", __DIR__)

  test "discovery sees every screen that has a source file" do
    # The sweep is only worth what it covers, and its blind spot is silent: if
    # `Application.spec/2` ever answers with nothing, every test in this file
    # passes over an empty list. So the expected set is rebuilt here from a
    # different source — the files on disk — and the two have to agree.
    on_disk =
      @screens_dir
      |> Path.join("*.ex")
      |> Path.wildcard()
      |> Enum.map(fn path ->
        Module.concat(Kati.Screens, Macro.camelize(Path.basename(path, ".ex")))
      end)
      |> Enum.filter(&ScreenSweep.screen?/1)
      |> Enum.sort()

    assert on_disk != [], "no screen sources found under #{@screens_dir}"

    missing = on_disk -- ScreenSweep.screens()

    assert missing == [],
           "these screens have a source file but never reach the sweep, so nothing " <>
             "in this file or in Kati.ScreenTapSweepTest covers them:\n" <>
             Enum.map_join(missing, "\n", &("  " <> inspect(&1)))
  end

  test "every screen mounts and renders a single root node, in every locale" do
    failures =
      ScreenSweep.per_locale(@locales, fn locale ->
        for module <- ScreenSweep.screens(),
            failure = render_failure(module, locale),
            do: failure
      end)

    assert failures == [], "\n" <> Enum.join(failures, "\n\n")
  end

  test "every rendered node is a type the native layer can draw" do
    # `Kati.ScreenSweep.renderable_types/0` is mob's set plus the one type
    # Kati's own bridge adds — `anchored`, via K-18. A node outside it draws
    # NOTHING on Android: no crash, no log, just an absent control. Same class
    # of invisibility `Kati.ComponentPolicyTest` guards for `:anchored`, caught
    # here from the other end — off the rendered tree rather than the source.
    renderable = ScreenSweep.renderable_types()

    offenders =
      ScreenSweep.per_locale(@locales, fn locale ->
        for module <- ScreenSweep.screens(),
            {:ok, _socket, tree} <- [ScreenSweep.render(module)],
            types =
              tree
              |> Mob.ScreenCase.flatten()
              |> Enum.map(& &1.type)
              |> Enum.uniq()
              |> Enum.reject(&MapSet.member?(renderable, &1)),
            types != [] do
          "  #{inspect(module)} (#{locale}) draws #{inspect(types)}"
        end
      end)

    assert offenders == [],
           "these node types have no native renderer, so the control is simply " <>
             "absent on device:\n" <> Enum.join(offenders, "\n")
  end

  # Returns a formatted failure, or nil when the screen is fine.
  defp render_failure(module, locale) do
    case ScreenSweep.render(module) do
      {:ok, _socket, tree} -> single_root_failure(module, locale, tree)
      {:error, message} -> "#{inspect(module)} (#{locale}) failed to render:\n  #{message}"
    end
  end

  defp single_root_failure(_module, _locale, %{type: _}), do: nil

  defp single_root_failure(module, locale, tree) when is_list(tree) do
    types = Enum.map(tree, &Map.get(&1, :type, :unknown))

    """
    #{inspect(module)} (#{locale}) rendered #{length(tree)} root nodes: #{inspect(types)}
      A ~MOB sigil returns ONE node. Siblings at the top of a template become a
      list, the bridge draws the first and drops the rest, and there is no error
      anywhere. Wrap them in a single <Box> or <Column>.
    """
  end

  defp single_root_failure(module, locale, other) do
    "#{inspect(module)} (#{locale}) rendered #{inspect(other, limit: 5)}, " <>
      "which is not a view node"
  end
end
