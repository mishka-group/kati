defmodule Kati.Backup.SampleRestore do
  @moduledoc """
  Stand-in restore data, until `Kati.Screens.Restore` reads a real file.

  Screen 129 is drawn mid-preview: a file has already been picked, its counts
  are already known, and the first of six conflicts is already open. None of
  that can be read off an empty database, and the screen's whole argument is
  that the person sees the consequences *before* anything is written — see
  `Kati.Backup.inspect_file/2`, which already makes this promise for real and
  is the call this module stands in for — so the drawing's own numbers live
  here.

  ## Why these are screen 37's numbers, not new ones

  `129.html`'s own caption says it outright: *"37's pre-write summary and
  conflict resolver used verbatim."* `counts/0` is `384 / 28 / 6`, the same
  three figures `Kati.Import.Sample.outcome/0` draws in the same three
  colours, and `conflict/0` is `Blue Hour`, `Yours ★4 · file says ★5`, the
  same three choices and `1 of 6 · apply to all` — character for character
  what `Kati.Import.Sample.conflict/0` holds for screen 37's CSV import.

  That module is not called from here, on purpose. The two screens draw the
  same *preview pattern* for two different sources — a spreadsheet row and a
  device backup — and a coincidence of mockup copy is not a claim that a CSV
  import and a whole-device restore are the same event. Screen 50 reading
  `Kati.Meals.SampleShare.share/0` for its own URI is the opposite case: two
  screens open the *one* plan, so two copies of that string is how they would
  quietly stop agreeing. Nothing here is that document twice.
  """

  @doc "The file already picked, before this drawing reads anything about it."
  @spec file() :: String.t()
  def file, do: "kati-backup-2026-08-14.json"

  @doc """
  What the write would do, as three counts — screen 37's own figures.

  `tone` rather than a colour for the reason `Kati.Screens.PlanImport.counts/0`
  gives: `Kati.Theme.Palette`'s tokens resolve against the theme installed at
  render, and a colour baked in at load time would be the mount's answer
  rather than the frame's.
  """
  @spec counts() :: [map()]
  def counts do
    [
      %{value: "384", label: "New", tone: :ink},
      %{value: "28", label: "Merged", tone: :green},
      %{value: "6", label: "Conflicts", tone: :red}
    ]
  end

  @doc """
  The conflict on top of the pile — screen 37's `Blue Hour`, unchanged.

  `icon` is this screen's own addition: the CSV import conflict sits under a
  film poster, and a restored film has no artwork on this drawing either, so
  it leads with a plain `star` glyph instead — the same substitution
  `Kati.Screens.PlanImport.conflict_tile/1` makes for a meal.
  """
  @spec conflict() :: map()
  def conflict do
    %{
      icon: "star",
      title: "Blue Hour",
      line: "Yours ★4 · file says ★5",
      choices: [{"Keep mine", true}, {"Take file", false}, {"Keep both", false}],
      progress: "1 of 6 · apply to all"
    }
  end

  @doc "What `Replace everything` would delete, if it were chosen over Merge."
  @spec replace() :: map()
  def replace, do: %{count: "418", noun: "titles"}
end
