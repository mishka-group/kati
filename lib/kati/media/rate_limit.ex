defmodule Kati.Media.RateLimit do
  @moduledoc """
  One request per interval, per catalogue, for the APIs that ask for it.

  MusicBrainz answers more than one anonymous request a second with **503**,
  and that 503 is not distinguished from an outage by `Kati.Media.Provider`.
  Found on the phone: a search returned no rows and said nothing, because the
  request was throttled and the section had no way to tell.

  Lives under `Kati.Supervisor` rather than in a screen: a screen is transient
  (`AGENTS.md`) and a rate table that dies with it forgets what it just sent.

  The wait happens in the CALLER — the catalogue's fetch runs in a task — so a
  throttle never blocks a render.
  """

  use Agent

  @doc false
  def start_link(_opts), do: Agent.start_link(fn -> %{} end, name: __MODULE__)

  @doc """
  Block until `key` may be asked again, then mark it asked. No-op with no
  limiter running (a test that never started the app's supervisor).
  """
  @spec take(atom(), pos_integer()) :: :ok
  def take(key, interval_ms \\ 1_000) do
    now = System.monotonic_time(:millisecond)

    wait =
      Agent.get_and_update(__MODULE__, fn times ->
        last = Map.get(times, key, 0)
        wait = max(0, interval_ms - (now - last))
        {wait, Map.put(times, key, now + wait)}
      end)

    if wait > 0, do: Process.sleep(wait)
    :ok
  catch
    :exit, _reason -> :ok
  end
end
