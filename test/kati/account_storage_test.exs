defmodule Kati.AccountStorageTest do
  @moduledoc """
  Screen 40's storage card reads this phone, not the drawing.

  *Storage used* said `214 MB · 1,206 titles` and *Last backup* said *Never* on
  every phone, including one that had just exported (A4).
  """

  use Mob.ScreenCase, async: false

  alias Kati.Account.Sample

  setup do
    Kati.Repo.query!("DELETE FROM tracked_titles WHERE source_id LIKE 'account-storage-%'")
    :ok
  end

  test "the title count is the shelf's" do
    before = Sample.titles_kept()

    Ash.create!(Kati.Media.TrackedTitle, %{
      source: :manual,
      source_id: "account-storage-one",
      kind: :movie,
      status: :watching
    })

    assert Sample.titles_kept() == before + 1

    Kati.Repo.query!("DELETE FROM tracked_titles WHERE source_id LIKE 'account-storage-%'")
  end

  test "never backed up is a gentle warning" do
    assert %{value: "Never", warn: true} = Sample.last_backup_row(nil)
  end

  test "a backup is dated, and is not a warning" do
    row = Sample.last_backup_row(~U[2026-09-20 10:00:00Z])

    refute row[:warn]
    refute row.value == "Never"
    assert row.value =~ "20"
  end
end
