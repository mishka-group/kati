defmodule Kati.Write do
  @moduledoc """
  What a screen says when a save does not land.

  Twelve write sites in this app ended `:ok` and rescued to `:ok` on the way
  out. Two things were wrong with that and only one of them was the rescue.

  `Ash.create/2` does not raise — it returns `{:ok, record}` or
  `{:error, changeset}`. So the rescue caught almost nothing, and the failure
  was thrown away one line earlier by a function that returned `:ok` whatever
  happened. A sheet closed, a screen redrew its sample, and a person had no way
  to tell a save that worked from one that did not. On a fresh install, where
  every screen draws a sample anyway, the two are pixel-identical.

  ## The contract

  A save returns `{:ok, record}` or `{:error, reason}`. Nothing returns a bare
  `:ok`, because a bare `:ok` is what made this invisible.

  A caller that gets `{:error, _}` **keeps the sheet open** and shows
  `message/1`. Closing on failure is the specific behaviour being fixed: it is
  what makes a lost write look like a completed one.

  ## Why the message is short and unapologetic

  A person who has just typed something and pressed Save needs to know two
  things: it did not save, and their text is still there. Everything else —
  changeset internals, Ash error structs — belongs in the log. `AGENTS.md`'s
  copy rule is that an error explains what went wrong and how to fix it, with
  no apologies and no vagueness.
  """

  @doc """
  A failure, in words a person can act on.

  Falls back to a plain sentence rather than inspecting the error into the UI:
  an `Ash.Error.Invalid` rendered raw is worse than saying nothing useful, and
  it is the log's job to carry the detail.

      iex> Kati.Write.message({:error, :nothing_to_save})
      "Nothing to save yet."

      iex> Kati.Write.message({:error, %{errors: [%{message: "is required"}]}})
      "Is required."

      iex> Kati.Write.message({:error, %{errors: [%{message: "must be one of %{atom_list}"}]}})
      "That did not save. Your text is still here — try again."
  """
  @spec message(term()) :: String.t()
  def message({:error, :nothing_to_save}), do: "Nothing to save yet."

  def message({:error, %{errors: [%{message: text} | _rest]}}) when is_binary(text) do
    # Ash carries its messages as TEMPLATES — `"must be one of %{atom_list},
    # got: %{value}"` — with the values in a separate `vars` key. Rendering the
    # message alone puts the literal `%{atom_list}` on screen, which was found
    # in review before it shipped: a sheet showed someone
    # `"Atom must be one of %{atom_list}, got: %{value}."`
    #
    # Substituting properly means reimplementing Ash's own interpolation, and
    # getting it subtly wrong is worse than not trying: a half-substituted
    # sentence still reads as gibberish and now looks deliberate. So an
    # un-substituted template falls back to the plain sentence, and the detail
    # goes to `note/2`'s log where it is complete and inspectable.
    if String.contains?(text, "%{") do
      generic()
    else
      String.capitalize(text) <> "."
    end
  end

  def message(_other), do: generic()

  defp generic, do: "That did not save. Your text is still here — try again."

  @doc """
  Log a failed write, and hand back the tuple unchanged.

  Between the screen and the store there is nowhere else for the reason to go:
  the device has no console a user reads, and the message they see is
  deliberately short. `:mob_nif.log/1` is where `Kati.App`'s boot trace lands,
  which is the one place a device failure is recoverable from afterwards.
  """
  @spec note({:ok, term()} | {:error, term()}, String.t()) :: {:ok, term()} | {:error, term()}
  def note({:ok, _record} = ok, _where), do: ok

  def note({:error, reason} = error, where) do
    log("Kati: #{where} failed: #{inspect(reason)}")
    error
  end

  defp log(line) do
    :mob_nif.log(line)
  rescue
    # No bridge on the host. The tests that exercise these paths run there, and
    # a logger that raises would turn a handled failure into an unhandled one.
    _error -> :ok
  end
end
