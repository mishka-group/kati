defmodule Kati.WriteContractTest do
  @moduledoc """
  Every write says whether it worked.

  Twelve sites in this app ended with a bare `:ok` and a `rescue _error -> :ok`.
  The rescue was never the bug. `Ash.create/2` returns `{:ok, record}` or
  `{:error, changeset}` rather than raising, so the rescue caught almost
  nothing — the failure was discarded one line earlier, by a function that
  returned `:ok` whatever happened.

  What that cost is specific: the sheet closed, the screen redrew its sample,
  and a lost write looked exactly like a completed one. On a fresh install,
  where every screen draws a sample anyway, they are pixel-identical. Nobody
  could have noticed, including the person who lost the data.

  This file is the ratchet. It reads the source rather than the behaviour,
  because the behaviour is per-screen and already tested where it lives; what
  cannot be allowed back is the *shape* — a write path that cannot fail.
  """

  use ExUnit.Case, async: true

  doctest Kati.Write

  # Every screen whose save was rewritten under #85, with the function that
  # writes. Listed rather than discovered: a discovered list silently shrinks
  # when someone renames a function, and a shrinking guard is the failure mode
  # this whole ticket is about.
  @writers [
    {"lib/kati/screens/log_weight.ex", "save_reading"},
    {"lib/kati/screens/new_goal.ex", "save_goal"},
    {"lib/kati/screens/quick_add_expense.ex", "save_expense"},
    {"lib/kati/screens/log_listen.ex", "save_listen"},
    {"lib/kati/screens/meal_edit.ex", "save_slot"},
    {"lib/kati/screens/log_progress.ex", "save_session"},
    {"lib/kati/screens/medication.ex", "save_dose"},
    {"lib/kati/screens/book_detail.ex", "apply_change"},
    # Not one of #85's twelve — screen 33 had no write at all to rewrite, and
    # #88 gave it one. It is here because this file's subject is the SHAPE of a
    # write rather than the history of one ticket: a save added later that
    # cannot report its own failure is the same defect arriving by a different
    # door, and a ratchet that only guards the sites already fixed guards the
    # past.
    {"lib/kati/screens/rating.ex", "save_watch"},
    # Screen 119, added by #95 for the same reason screen 33 is here: its Save
    # popped the sheet and wrote nothing at all, which is the bare-`:ok` defect
    # with the write removed as well as the result. It is the first writer in
    # this list that commits through a DOMAIN function
    # (`Kati.Meals.Totals.write_ingredient/2`) rather than `Ash.create/2`
    # directly, and the contract is unchanged by that: the clause still has to
    # hand back a tuple and still has to route it through `Kati.Write.note/2`.
    {"lib/kati/screens/add_ingredient.ex", "save_ingredient"},
    # Screen 92, added by #95. Sharper again than screen 33's case:
    # `Kati.Services.Service` shipped with `create: :*` and no caller anywhere
    # in `lib/`, so there was no write to get wrong until this one. It joins on
    # the day it is written rather than on the day it is found broken, which is
    # the only day joining is cheap.
    {"lib/kati/screens/my_services.ex", "save_service"}
  ]

  describe "the shape of a write" do
    test "every rewritten screen still has its writer" do
      # A guard over a list of names is worth exactly as much as the names
      # being real. This is what stops the file below passing because a
      # function was renamed out from under it.
      missing =
        for {path, fun} <- @writers,
            source = File.read!(path),
            not String.contains?(source, "def #{fun}("),
            do: "  #{path} no longer defines #{fun}/n"

      assert missing == [],
             "these writers were renamed or removed, so the contract below is checking " <>
               "nothing for them:\n" <> Enum.join(missing, "\n")
    end

    test "no write path rescues its own failure" do
      # A `rescue` on a READ is legitimate and common here — a screen that
      # cannot reach the store falls back to its drawing, which is what the
      # empty-database sweep exists to check. A rescue on a WRITE is different:
      # it is the app deciding on your behalf that a failure did not happen.
      offenders =
        for {path, fun} <- @writers,
            source = File.read!(path),
            clause <- writer_clauses(source, fun),
            String.contains?(clause, "rescue"),
            do: "  #{path} — #{fun} rescues its own failure"

      assert offenders == [],
             "a write that rescues cannot report a failure, and `Ash.create/2` does not " <>
               "raise anyway — the rescue only hides the tuple:\n" <> Enum.join(offenders, "\n")
    end

    test "no writer returns a bare :ok" do
      # The actual defect. `:ok` is indistinguishable from success and is what
      # made twelve broken saves invisible for the life of the project.
      offenders =
        for {path, fun} <- @writers,
            source = File.read!(path),
            clause <- writer_clauses(source, fun),
            bare_ok?(clause),
            do: "  #{path} — #{fun} can return a bare :ok"

      assert offenders == [],
             "a write that returns `:ok` has thrown its result away. Return " <>
               "`{:ok, record}` or `{:error, reason}` — see `Kati.Write`:\n" <>
               Enum.join(offenders, "\n")
    end

    test "every writer routes its result through Kati.Write.note/2" do
      # Not decoration. The message a person sees is deliberately short, and a
      # phone has no console they could read anyway, so the log is the only
      # place a device failure stays recoverable from afterwards.
      missing =
        for {path, fun} <- @writers,
            source = File.read!(path),
            clause <- writer_clauses(source, fun),
            not String.contains?(clause, "Write.note("),
            do: "  #{path} — #{fun} does not log its failure"

      assert missing == [],
             "a failure nobody can read afterwards is only half-reported:\n" <>
               Enum.join(missing, "\n")
    end
  end

  describe "what a person is shown" do
    test "an Ash template never reaches the screen" do
      # Ash carries messages as templates with the values in a separate `vars`
      # key. Rendering the message alone put `"Atom must be one of
      # %{atom_list}, got: %{value}."` in front of someone during review of
      # this very ticket.
      leaked =
        Kati.Write.message({:error, %{errors: [%{message: "must be one of %{atom_list}"}]}})

      refute leaked =~ "%{",
             "an un-substituted Ash template reached the user: #{leaked}"
    end

    test "a message says the text is still there" do
      # The two things someone needs after pressing Save and having it fail.
      # `AGENTS.md`'s copy rule: say what went wrong and what to do, without
      # apologising.
      message = Kati.Write.message({:error, :something_unexpected})

      assert message =~ "did not save"
      assert message =~ "still here"
      refute message =~ "sorry", "the copy rule forbids apologising"
    end
  end

  # EVERY clause of a writer, each from its own `def` to the next top-level
  # `def`, `defp` or `@doc`. Crude, and deliberately so: a parser here would be
  # a second thing to get wrong, and the shapes this reads are two lines apart.
  #
  # ## Why every clause and not the first
  #
  # This read the first clause only, and it was green over a `rescue _ -> :ok`
  # sitting on a real write path — measured, by putting one there. Eight of the
  # nine writers are single-clause, so nothing had ever exercised the
  # difference; `Kati.Screens.Rating.save_watch/1` is the first to split its
  # refusal into a head of its own:
  #
  #     def save_watch(%{watch_id: nil}), do: Write.note({:error, …}, …)
  #     def save_watch(%{watch_id: id, watch: w}) do …the actual write… end
  #
  # A `parts: 2` split stops at the second `def`, so the seventy-eight
  # characters that write nothing were the whole of what three assertions
  # inspected, and the clause holding `Ash.update/1` was invisible to all of
  # them. Splitting a guard clause out of a writer is ordinary Elixir and must
  # not be a way through the ratchet — the shape this file exists to forbid
  # would have arrived by exactly that door.
  #
  # Each clause is checked on its own rather than concatenated, which also
  # makes `Write.note(` mean what it says: a writer whose second clause returns
  # without reporting is the same defect as one that never reported at all.
  defp writer_clauses(source, fun) do
    source
    |> String.split("def #{fun}(")
    |> Enum.drop(1)
    |> Enum.map(fn rest ->
      rest
      |> String.split(~r/\n  (?:@doc|def |defp )/, parts: 2)
      |> List.first()
    end)
  end

  # A `:ok` standing alone as a return value, rather than inside `{:ok, _}` or
  # `:ok <-` or a doc line.
  defp bare_ok?(body) do
    body
    |> String.split("\n")
    |> Enum.any?(fn line ->
      trimmed = String.trim(line)
      trimmed == ":ok" or String.ends_with?(trimmed, "-> :ok")
    end)
  end
end
