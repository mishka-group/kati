defmodule Kati.Screens.Root do
  @moduledoc """
  Shared behaviour for the four fixed roots.

  ## The rule: a screen subscribes to nothing

  A screen is **transient**. It dies on every root switch, and Mob keeps exactly
  one screen process alive at a time. So a screen must not hold anything that
  needs to outlive it:

    * no PubSub or Ash notifier subscription
    * no `Process.send_after/3` or `:timer.send_interval/3` beyond one render
    * no `Registry` registration
    * no PIDs or large collections in `assigns` — they sit on the one heap the
      GC repeatedly scans

  Anything long-lived belongs under `Kati.Supervisor`. A supervised process may
  push to the UI with `send(:mob_screen, {:kati, topic, payload})`.

  **Addressing is by topic, not by identity.** Every screen that cares
  implements `handle_kati/3` for its topics and the catch-all eats the rest, so
  a message arriving after the user has navigated away is dropped instead of
  landing on the wrong module. The alternative — stamping the current screen
  into `Mob.State` and checking before sending — is cheaper but races with
  navigation, and a dropped update costs a re-query while a misdelivered one
  corrupts a screen.

  `Kati.SupervisionRuleTest` fails the build if a screen breaks this.

  ## Taps are rescued — but two different failures are not the same failure

  Mob catches nothing. An exception in a tap handler kills the screen process,
  and although `Kati.Supervisor` now restarts it, restarting to Home on a
  mistyped pattern match is a poor trade. `handle_tap/2` is therefore wrapped:
  a raise is logged and swallowed, leaving the screen exactly as it was.
  Restart remains the backstop for a crash outside a tap.

  That rescue used to flatten two unrelated things into one log line:

    * **a handler that exists and raised.** A bug *inside* that handler. The
      wiring is right, the control is alive, and the next tap may well work.
      Recoverable — log it and carry on. This is what the rescue is *for*.

    * **no handler at all.** The screen drew a control, gave it a tag, and
      defined nothing that can answer it. The button is not flaky, it is
      *permanently dead*, and it will stay dead for every user on every tap
      until somebody writes the function. Nothing about that is recoverable.

  `rescue_tap/3` now decides which one it is *before* it calls, with
  `function_exported?/3`, and says so in words you cannot confuse.

  ### Why there is no default `handle_tap/2` here any more

  This macro used to end with `def handle_tap(_tag, socket), do: {:noreply, socket}`.
  It reads like defensive hygiene. It is the opposite: it converts "raise, get
  logged, get found" into "silently do nothing, forever". A drawn button that
  does nothing and says nothing is invisible to the compiler, invisible to the
  logs, and invisible to every test — the build stays green and the screen
  looks finished in a screenshot, because the *resting* pixels are correct.
  The only thing that ever notices is a human tapping the button.

  Deleting that default cost nothing that worked and immediately named three
  screens whose Day/Week/Month/Agenda segments have never done anything
  (`agenda.ex`, `week.ex`, `month_grid.ex` all draw
  `Kati.Screens.ViewSwitcher.bar/1` and delegate to nothing).

  For the same reason `Kati.Screens.Pushed` must never grow such a default.

  `handle_kati/3` is deliberately the *other* way round — see `rescue_kati/4`.
  """

  @callback load(term()) :: term()
  @callback handle_tap(atom(), term()) :: {:noreply, term()}
  @callback handle_kati(atom(), term(), term()) :: {:noreply, term()}
  @optional_callbacks load: 1, handle_tap: 2, handle_kati: 3

  defmacro __using__(opts) do
    root = Keyword.fetch!(opts, :root)

    quote do
      use Mob.Screen
      import Mob.Sigil
      @behaviour Kati.Screens.Root

      @root unquote(root)

      def mount(_params, _session, socket) do
        Mob.Theme.set(Kati.Theme.light())

        socket
        |> Mob.Socket.assign(:root, @root)
        |> load()
        |> then(&{:ok, &1})
      end

      @doc """
      Screen-specific data loading, run on mount.

      A hook rather than an overridable `mount/3` so a screen cannot forget to
      set `:root` or the theme — those are the shell's business, not the
      screen's.
      """
      def load(socket), do: socket

      def render(assigns) do
        Kati.Shell.render(%{root: @root, mode: :light, content: content(assigns)})
      end

      # Root switching. `Mob.Socket.switch_tab/2` is inert for a hand-rolled
      # shell — Mob.Screen discards the action at screen.ex:611-613 — so the
      # shell navigates itself with reset_to/3.
      # The FAB opens the add sheet from every root — screen 06's note calls it
      # "one sheet reached from the + button", so it belongs here rather than
      # in four copies.
      def handle_info({:tap, :fab}, socket) do
        {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.AddTitle)}
      end

      def handle_info({:tap, tag}, socket) do
        case Atom.to_string(tag) do
          "root_" <> id ->
            target = String.to_existing_atom(id)

            if target == @root do
              {:noreply, socket}
            else
              {:noreply, Mob.Socket.reset_to(socket, Kati.Shell.screen_for(target))}
            end

          _ ->
            Kati.Screens.Root.rescue_tap(__MODULE__, tag, socket)
        end
      end

      # Topic-addressed pushes from supervised processes.
      def handle_info({:kati, topic, payload}, socket) do
        Kati.Screens.Root.rescue_kati(__MODULE__, topic, payload, socket)
      end

      def handle_info(_message, socket), do: {:noreply, socket}

      # No default `handle_tap/2` and no default `handle_kati/3` on purpose.
      #
      # A default `handle_tap(_tag, socket), do: {:noreply, socket}` would make
      # every screen answer every tag with silence, which is exactly what a
      # forgotten handler already looks like — so the mistake would have no
      # symptom at all. `rescue_tap/3` reports the absence loudly instead; see
      # the moduledoc. `rescue_kati/4` supplies the drop for `handle_kati/3`,
      # where an unclaimed topic is normal rather than a mistake.
      defoverridable load: 1
    end
  end

  require Logger

  @doc """
  Runs `module.handle_tap/2`, surviving both ways it can fail to answer.

  A tag only ever reaches here because the screen itself drew a control
  carrying it: the shell's own tags are intercepted upstream — `:fab` and
  `root_*` by this macro, `:back` by `Kati.Screens.Pushed` — so there is no
  such thing as a stray tag arriving from somewhere else. That is what makes
  "no handler" diagnosable rather than merely unexpected.

  Returns `{:noreply, socket}` unchanged in both failure cases. Loud means
  *logged*, never *fatal*: the user is looking at this screen.
  """
  @spec rescue_tap(module(), atom(), term()) :: {:noreply, term()}
  def rescue_tap(module, tag, socket) do
    # Decided BEFORE the call, not inferred from the wreckage afterwards.
    #
    # The tempting alternative is to call and then sniff the exception for an
    # `UndefinedFunctionError` naming this module and `:handle_tap/2`. It
    # cannot be made safe: a handler that *does* exist raises the very same
    # struct when it calls something renamed or misspelled somewhere below it,
    # and the fields alone will not tell you whether the missing function was
    # the one at the top of the call or one twelve frames down. Guess wrong in
    # that direction and a real bug gets relabelled "you forgot to wire this"
    # and filed under the wrong screen. `function_exported?/3` answers the only
    # question worth asking — could this call have landed at all — and answers
    # it with no ambiguity, one cheap BIF, once per human tap.
    if exports?(module, :handle_tap, 2) do
      try do
        module.handle_tap(tag, socket)
      rescue
        error ->
          # (a) The handler exists and blew up. A bug in it, and the wiring is
          # fine. Wording unchanged so old greps and notes still find it.
          Logger.error(
            "tap #{inspect(tag)} raised in #{inspect(module)}: #{Exception.message(error)}"
          )

          {:noreply, socket}
      end
    else
      unhandled_tap(module, tag, socket)
    end
  end

  @doc """
  Reports a tap nothing can answer, and leaves the socket alone.

  Public so a hand-rolled screen — one with its own `handle_info/2` rather
  than `use Kati.Screens.Root` — can end its tap clauses with

      def handle_info({:tap, tag}, socket) do
        Kati.Screens.Root.unhandled_tap(__MODULE__, tag, socket)
      end

  instead of a bare `{:noreply, socket}` catch-all, which is the same
  disappearing act by hand.
  """
  @spec unhandled_tap(module(), atom(), term()) :: {:noreply, term()}
  def unhandled_tap(module, tag, socket) do
    # (b) Nothing to call. Not a crash — a wiring hole. Deliberately worded so
    # it cannot be mistaken for the message above: that one sends you to read a
    # handler, this one tells you there is no handler to read, and naming the
    # tag names the control on screen that is dead.
    Logger.error(
      "DEAD TAP: #{inspect(module)} drew a control tagged #{inspect(tag)} but defines " <>
        "no handle_tap/2, so that control can never do anything. Add " <>
        "`def handle_tap(#{inspect(tag)}, socket)` to #{inspect(module)}."
    )

    {:noreply, socket}
  end

  @doc """
  Whether `module` has no way to answer any tap at all.

  The point of exposing this: a dead control is invisible to the compiler and
  to a screenshot, so the *only* cheap way to fail a build over one is to ask
  every screen this question. A sweep test needs no device and no tags —

      for path <- Path.wildcard("lib/kati/screens/*.ex"),
          module = Module.concat(Kati.Screens, Macro.camelize(Path.basename(path, ".ex"))),
          File.read!(path) =~ "on_tap=",
          Kati.Screens.Root.tap_handler_missing?(module),
          do: module

  should be empty. It catches the whole-screen case, which is the one that has
  actually happened. It does *not* catch a screen whose `handle_tap/2` exists
  but whose `case` has no clause for one particular tag — that one still shows
  up only as a `DEAD TAP` line at runtime.
  """
  @spec tap_handler_missing?(module()) :: boolean()
  def tap_handler_missing?(module), do: not exports?(module, :handle_tap, 2)

  @doc """
  Runs `module.handle_kati/3`, surviving a raise inside it.

  Deliberately **not** symmetric with `rescue_tap/3`, and the asymmetry is the
  whole point rather than an oversight.

  A tap tag can only arrive at the screen that drew it, so an unanswerable tap
  is always a mistake. A `{:kati, topic, payload}` push is the opposite: it is
  addressed by topic and sent to whichever screen happens to be alive, exactly
  so that a supervised process never has to know who that is. Most screens care
  about no topic at all, and the moduledoc's rule is that the ones that do not
  care simply drop it. So a missing `handle_kati/3` is a screen minding its own
  business, not a bug, and shouting about it would put an :error line on the
  device for every push to every uninterested screen — which is how a log stops
  being read, and how the `DEAD TAP` line above would get lost in the noise.

  A `handle_kati/3` that exists and raises is still a bug, and still logged.
  """
  @spec rescue_kati(module(), atom(), term(), term()) :: {:noreply, term()}
  def rescue_kati(module, topic, payload, socket) do
    if exports?(module, :handle_kati, 3) do
      try do
        module.handle_kati(topic, payload, socket)
      rescue
        error ->
          Logger.error(
            "kati #{inspect(topic)} raised in #{inspect(module)}: #{Exception.message(error)}"
          )

          {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  # `Code.ensure_loaded?/1` first: a screen module is compiled but not
  # necessarily loaded yet the first time a tap lands on it, and
  # `function_exported?/3` reports false for anything not in memory — which
  # would turn a perfectly wired screen into a DEAD TAP report exactly once,
  # the most confusing possible frequency.
  defp exports?(module, fun, arity) do
    Code.ensure_loaded?(module) and function_exported?(module, fun, arity)
  end
end
