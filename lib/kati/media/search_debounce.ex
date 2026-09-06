defmodule Kati.Media.SearchDebounce do
  @moduledoc """
  One request when somebody stops typing, not one per letter.

  ## The defect

  `Kati.Screens.AddTitle` ran `Kati.Media.Tmdb.search/1` from its
  `{:change, :title_query, _}` handler, which the bridge sends on **every
  keystroke**. Typing `severance` on a Pixel 9a made nine TMDB requests, eight
  of whose answers were thrown away by the ninth — nine round trips over a
  phone's radio, nine rows against a rate limit that is shared with every other
  Kati user, and a results list that flickered through the answers to `s`,
  `se`, `sev` on the way.

  ## Why the sleep is here and not in the screen

  `Kati.SupervisionRuleTest` forbids `Process.send_after/3` in a screen module,
  and it is right to: *screens must not outlive themselves.* A screen that
  schedules a message to itself and is then popped leaves a timer holding a
  reference to a dead process.

  So the waiting is done by a task under `Kati.TaskSupervisor`, which is what
  that supervisor exists for, and the screen is left with the only decision
  that needs its state: **is this answer still wanted?** A message to a screen
  that has since been popped lands on a dead pid and is dropped, which is the
  behaviour a timer would have had to be cancelled to get.

  ## Trailing edge, and how it stays correct without a token

  Every keystroke starts a task, so `severance` still starts nine of them. What
  it does not do is make nine requests: each task sends `{:search_ready,
  query}` back and `Kati.Screens.AddTitle` compares that query with the one
  currently in its assigns, which is the LAST thing typed. Eight of the nine
  arrive stale and are dropped before the network is touched.

  That comparison is the whole mechanism and it needs no sequence number,
  because the socket's `:query` is already the single source of truth for what
  the person has typed. It also gets the edge case right for free: type
  `arrival`, delete it, type `arrival` again, and the first run's message is
  still wanted — the query really is `arrival` — so the person sees results
  rather than a screen waiting on a request nobody will make.
  """

  @delay_ms 350

  @doc """
  Ask for `query` to be searched, once the typing has stopped.

  Sends `{:search_ready, query}` to `pid` after the delay. The caller decides
  whether it is still wanted — see the moduledoc.

  Answers `:ok` whatever happens, including when the task cannot be started:
  a debounce that raised would take the keystroke with it, and the cost of
  losing one is that the person types another letter.
  """
  @spec ask(pid(), String.t()) :: :ok
  def ask(pid, query) when is_pid(pid) and is_binary(query) do
    wait = fn ->
      Process.sleep(delay())
      send(pid, {:search_ready, query})
    end

    # Supervised when there is a supervisor, and plainly spawned when there is
    # not. `Task.Supervisor.start_child/2` is a `GenServer.call` to a named
    # process, so it **exits** rather than raising when `Kati.TaskSupervisor` is
    # not running — which is every unit test, and would be a device that had
    # not finished booting. A `rescue` does not catch that, which is how the
    # first version of this took the keystroke down with it.
    #
    # The fallback is not a lesser version of the same thing: there is nothing
    # to supervise here beyond a sleep and a `send/2`, and the supervisor is
    # wanted so a crash inside one cannot reach a screen rather than because
    # the work needs restarting.
    try do
      Task.Supervisor.start_child(Kati.TaskSupervisor, wait)
      :ok
    catch
      :exit, _reason ->
        spawn(wait)
        :ok
    end
  rescue
    _error -> :ok
  end

  @doc """
  How long the typing has to stop for, in milliseconds.

  350 is the usual figure and it is a real trade rather than a default: below
  about 250 a fast typist still fires two requests for one word, and above
  about 500 the results feel like they are lagging the field. Exposed as a
  function so a test can wait exactly one delay rather than sleeping a round
  number and hoping.

      iex> Kati.Media.SearchDebounce.delay()
      350
  """
  @spec delay() :: pos_integer()
  def delay, do: @delay_ms
end
