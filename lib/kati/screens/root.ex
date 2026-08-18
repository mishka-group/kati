defmodule Kati.Screens.Root do
  @moduledoc """
  Shared behaviour for the four fixed roots.

  Each root owns its content; the shell owns the chrome. Tab taps swap the
  root with `reset_to/3` rather than pushing, because a root is not a
  destination you come *back* from — the design's back pills always name a
  parent, and a root has none.
  """

  defmacro __using__(opts) do
    root = Keyword.fetch!(opts, :root)

    quote do
      use Mob.Screen
      import Mob.Sigil

      @root unquote(root)

      def mount(_params, _session, socket) do
        Mob.Theme.set(Kati.Theme.light())
        {:ok, Mob.Socket.assign(socket, :root, @root)}
      end

      def render(assigns) do
        Kati.Shell.render(%{
          root: @root,
          mode: :light,
          content: content(assigns)
        })
      end

      # Tab taps. Switching root is a reset, not a push: `Mob.Socket.switch_tab/2`
      # is inert for a hand-rolled shell (Mob.Screen throws the action away at
      # screen.ex:611-613), so the shell drives navigation itself.
      def handle_info({:tap, tag}, socket) do
        case Atom.to_string(tag) do
          "root_" <> id ->
            target = String.to_existing_atom(id)

            if target == @root do
              {:noreply, socket}
            else
              {:noreply, Mob.Socket.reset_to(socket, Kati.Shell.screen_for(target))}
            end

          "fab" ->
            {:noreply, socket}

          _ ->
            {:noreply, socket}
        end
      end

      def handle_info(_message, socket), do: {:noreply, socket}

      defoverridable handle_info: 2
    end
  end
end
