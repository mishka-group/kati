defmodule Kati.Backup.SampleRestore do
  use Gettext, backend: Kati.Gettext

  @moduledoc """
  Stand-in restore data for screen 135, `Kati.Screens.RestoreFirstRun`, until
  that screen reads a real file.

  Screen 129, `Kati.Screens.Restore`, used to read this module too — the
  board's filename, screen 37's `384 / 28 / 6` counts, the `Blue Hour`
  conflict and the `418 titles` Replace would delete. It stopped on
  25 September: every one of those is a claim about somebody's data, and 129
  now reads the picked file and `Kati.Backup.occupied/0` instead, so
  `counts/0` and `conflict/0` went with it. What is left is only what 135
  still draws, and it goes the same way when 135 is made real.
  """

  @doc "The file already picked on board 135, before anything reads it."
  @spec file() :: String.t()
  def file, do: "kati-backup-2026-08-14.json"

  @doc "What `Replace everything` would delete on board 135, if it were chosen over Merge."
  @spec replace() :: map()
  def replace, do: %{count: 418, noun: gettext("titles")}
end
