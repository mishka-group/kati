defmodule Kati.Media.TmdbKeyFile do
  @moduledoc """
  The one place `~/.config/kati/tmdb.env` is read.

  `Kati.Media.Tmdb` captures a TMDB token at compile time so it can travel in
  the BEAM that `mix kati.e2e.stage` pushes — a phone has no shell and no
  environment, so a runtime `System.get_env/1` alone means every device build
  answers `{:error, :no_api_key}`. That much was already true and is argued
  where the attribute is.

  What was still true is that the compile-time read was ALSO
  `System.get_env/1`, so it depended on whether the shell that happened to run
  the stage task had sourced the file. Two builds went out without a key on
  6 September for exactly that reason, and nothing said so: a device with a
  stale build and a device nobody has given a token look identical from the
  inside — no search results, and screen 11 saying there is no token.

  So the documented location is read directly, and the environment still wins
  over it. The file's own header says it is meant to be sourced; parsing it
  instead is what removes the step a person can forget.

  ## Why this is its own module

  A module attribute cannot call a function defined in the same module — the
  module is not compiled yet at the point the attribute is evaluated. This is
  the smallest thing that can be compiled first.

  ## What is not committed

  Nothing. The path is a path; the value it yields lives in `_build`, which is
  ignored, and in the pushed artefact. The file itself is outside the
  repository and mode 600.
  """

  @doc "Where the token lives, by convention. Absent on most machines."
  @spec path() :: String.t()
  def path, do: Path.join([System.user_home() || "", ".config", "kati", "tmdb.env"])

  @doc """
  The read token in `file`, or `nil`.

  Understands `NAME=value` and `export NAME=value`, with or without quotes,
  which is every line shape the documented file uses. Anything else — no file,
  an unreadable one, a file without the name in it — is `nil`, because this is
  read at compile time and a build must not fail over a credential that is
  allowed to be absent.

      iex> Kati.Media.TmdbKeyFile.read("/nonexistent/tmdb.env")
      nil
  """
  @spec read(String.t()) :: String.t() | nil
  def read(file) do
    case File.read(file) do
      {:ok, body} -> body |> String.split("\n") |> Enum.find_value(&token_in/1)
      {:error, _reason} -> nil
    end
  end

  @doc """
  The token on one line, or `nil`.

      iex> Kati.Media.TmdbKeyFile.token_in(~s(export TMDB_READ_TOKEN="abc"))
      "abc"

      iex> Kati.Media.TmdbKeyFile.token_in("TMDB_READ_TOKEN=abc")
      "abc"

      iex> Kati.Media.TmdbKeyFile.token_in("# TMDB_READ_TOKEN=abc")
      nil

      iex> Kati.Media.TmdbKeyFile.token_in("TMDB_API_KEY=abc")
      nil
  """
  @spec token_in(String.t()) :: String.t() | nil
  def token_in(line) do
    case Regex.run(~r/^\s*(?:export\s+)?TMDB_READ_TOKEN\s*=\s*(.+?)\s*$/, line) do
      [_whole, value] -> value |> String.trim("\"") |> String.trim("'") |> blank_to_nil()
      nil -> nil
    end
  end

  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: value
end
