defmodule Kati.ComponentPolicyTest do
  @moduledoc """
  Guards the component policy in `docs/COMPONENTS.md`.

  The `:anchored` lint is the important one: it guards against a defect that is
  **invisible** at runtime. A node type the published renderer does not know
  draws nothing at all on Android — no crash, no log, just an absent control.
  """
  use ExUnit.Case, async: true

  @lib Path.expand("../../lib", __DIR__)
  @components Path.join(@lib, "kati/components")
  @policy Path.expand("../../docs/COMPONENTS.md", __DIR__)

  defp sources do
    Path.wildcard(Path.join(@lib, "**/*.ex"))
  end

  defp strip_comments(body), do: String.replace(body, ~r/^\s*#.*$/m, "")

  test "the policy document exists and names the generate command" do
    assert File.exists?(@policy)
    body = File.read!(@policy)

    assert body =~ "mix mishka.ui.gen.mob"

    assert body =~ "--module-prefix kati_",
           "the prefix must be recorded, or a regeneration will not match"
  end

  test "only Kati.UI.Menu reaches the :anchored node type" do
    # This was a flat ban, on the grounds that the published mob 0.7.20
    # renderer does not know `:anchored`: on Android the dispatch `when` has no
    # `else` arm, so the node draws NOTHING — no crash, no log — and on iOS it
    # falls through to a column and becomes an in-flow accordion.
    #
    # `K-18 anchored-node` lifted half of that. Kati's Android bridge carries a
    # real `MobAnchored`, so on the platform Kati ships the node draws a proper
    # floating window, and `Kati.UI.Menu` is built on it — the overflow menu
    # that makes seven otherwise-stranded screens reachable.
    #
    # The allowance is deliberately one module wide. iOS is still the stock
    # renderer (`ios/` has no Swift bridge), so every other use would be an
    # accordion there, and the three library components stay quarantined: they
    # are copied in so the set is complete, not so they can be rendered.
    allowed = ~w(menu.ex)
    quarantined = ~w(mishka_popover.ex mishka_preview_card.ex mishka_tooltip.ex)

    offenders =
      for path <- sources(),
          not String.contains?(path, "components/anchored.ex"),
          not String.contains?(path, "components/popover.ex"),
          Path.basename(path) not in quarantined,
          Path.basename(path) not in allowed,
          body = strip_comments(File.read!(path)),
          body =~ ~r/Anchored\.(anchor|closed)\s*\(/ do
        Path.relative_to(path, @lib)
      end

    assert offenders == [],
           "these call the :anchored node type. Only Kati.UI.Menu may — " <>
             "everywhere else it is an accordion on iOS:\n" <> Enum.join(offenders, "\n")
  end

  test "the bridge still renders the node Kati.UI.Menu depends on" do
    # The other half of the allowance, and the one that fails silently. If
    # K-18 is dropped from MobBridge.kt — a bad merge after a mob bump, a
    # regenerated bridge — every overflow menu in the app goes back to drawing
    # nothing at all, with no crash and no log, and seven screens become
    # unreachable again. Nothing else in the suite would notice.
    bridge =
      Path.expand("../../android/app/src/main/java/com/example/kati/MobBridge.kt", __DIR__)

    src = File.read!(bridge)

    assert src =~ ~s|"anchored"|,
           "K-18 is gone: the bridge no longer dispatches the anchored node"

    assert src =~ "MobAnchored",
           "K-18 is gone: MobAnchored is not in the bridge"
  end

  test "generated components keep the prefix the policy records" do
    if File.dir?(@components) do
      for path <- Path.wildcard(Path.join(@components, "*.ex")) do
        body = File.read!(path)

        # The copied Mishka set keeps its own `Mishka` prefix, which serves the
        # same purpose as `Kati`: a bare <Dialog> would share a tag namespace
        # with anything Mob adds later. What matters is that a prefix exists.
        assert body =~ ~r/defmodule Kati\.Components\.(Kati|Mishka)\w+/ or
                 body =~ ~r/defmodule Kati\.Components\.(Anchored|Color|Event)\b/,
               "#{Path.basename(path)} is not prefixed — a bare <Dialog> shares a " <>
                 "tag namespace with anything Mob may add later, and the loser " <>
                 "renders nothing"
      end
    end
  end

  test "Kati's own styling edits to generated components are marked" do
    # Regeneration overwrites these files. A marker makes a lost edit visible in
    # a diff rather than discovered on a screen weeks later.
    if File.dir?(@components) do
      for path <- Path.wildcard(Path.join(@components, "*.ex")),
          body = File.read!(path),
          # Only assert on files that have clearly been touched for styling.
          body =~ "Kati.Theme" do
        assert body =~ "KATI-STYLED",
               "#{Path.basename(path)} references Kati.Theme but carries no " <>
                 "KATI-STYLED marker — a regeneration would revert it silently"
      end
    end
  end
end
