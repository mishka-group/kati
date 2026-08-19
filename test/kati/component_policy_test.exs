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

  test "no Kati code calls the :anchored node type" do
    # popover/tooltip/preview_card emit %{type: :anchored}, which the published
    # mob 0.7.20 renderer does not know. On Android the dispatch `when` has no
    # `else` arm, so the node draws NOTHING — no crash, no log. On iOS it falls
    # through to a column and becomes an in-flow accordion.
    #
    # Generated `anchored.ex`/`popover.ex` may exist as `necessary:` siblings.
    # That is fine as dead code; this lint is what keeps it dead.
    # The three library components that genuinely need `:anchored` are
    # quarantined rather than excused: they are copied in so the set is
    # complete, and they stay unusable until the bridge gains MobAnchored
    # (Mishka's own commit 2cd3a427 has a working Kotlin port to take). The
    # rule this test defends is that nothing Kati *renders* reaches for them.
    quarantined = ~w(mishka_popover.ex mishka_preview_card.ex mishka_tooltip.ex)

    offenders =
      for path <- sources(),
          not String.contains?(path, "components/anchored.ex"),
          not String.contains?(path, "components/popover.ex"),
          Path.basename(path) not in quarantined,
          body = strip_comments(File.read!(path)),
          body =~ ~r/Anchored\.(anchor|closed)\s*\(/ do
        Path.relative_to(path, @lib)
      end

    assert offenders == [],
           "these call the :anchored node type, which renders nothing on a " <>
             "stock Android bridge:\n" <> Enum.join(offenders, "\n")
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
