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

  ## Taps are rescued

  Mob catches nothing. An exception in a tap handler kills the screen process,
  and although `Kati.Supervisor` now restarts it, restarting to Home on a
  mistyped pattern match is a poor trade. `handle_tap/2` is therefore wrapped:
  a raise is logged and swallowed, leaving the screen exactly as it was.
  Restart remains the backstop for a crash outside a tap.
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

      def handle_tap(_tag, socket), do: {:noreply, socket}
      def handle_kati(_topic, _payload, socket), do: {:noreply, socket}

      defoverridable handle_tap: 2, handle_kati: 3, load: 1
    end
  end

  require Logger

  @doc false
  def rescue_tap(module, tag, socket) do
    module.handle_tap(tag, socket)
  rescue
    error ->
      Logger.error(
        "tap #{inspect(tag)} raised in #{inspect(module)}: #{Exception.message(error)}"
      )

      {:noreply, socket}
  end

  @doc false
  def rescue_kati(module, topic, payload, socket) do
    module.handle_kati(topic, payload, socket)
  rescue
    error ->
      Logger.error(
        "kati #{inspect(topic)} raised in #{inspect(module)}: #{Exception.message(error)}"
      )

      {:noreply, socket}
  end
end
