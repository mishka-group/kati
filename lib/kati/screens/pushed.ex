defmodule Kati.Screens.Pushed do
  @moduledoc """
  A screen pushed over a root, rather than one of the four roots.

  Most of the design's screens are these: a back pill instead of the tab
  bar, and a title that names where back goes. Screen 09 is the reference —
  *"pushed screen under the Calendar root with a `‹ Calendar` back pill and
  no tab bar"*.

  Sibling to `Kati.Screens.Root`, and the split is deliberate: a root sets
  `:root` and draws the shell, a pushed screen must not draw the tab bar at
  all. Making that a parameter of one macro would let a screen quietly get
  it wrong; two macros cannot.

  Provides the same tap rescue as `Kati.Screens.Root` — Mob catches nothing,
  and a raise in a tap handler otherwise kills the screen process — plus a
  `back` tap wired to `Mob.Socket.pop_screen/1`.
  """

  defmacro __using__(opts) do
    back_label = Keyword.fetch!(opts, :back)

    quote do
      use Mob.Screen
      import Mob.Sigil
      @behaviour Kati.Screens.Root

      @back_label unquote(back_label)

      def mount(params, _session, socket) do
        Mob.Theme.set(Kati.Theme.light())

        socket
        |> Mob.Socket.assign(:params, params)
        |> load()
        |> then(&{:ok, &1})
      end

      def load(socket), do: socket

      def render(assigns) do
        Kati.Screens.Pushed.chrome(@back_label, content(assigns))
      end

      def handle_info({:tap, :back}, socket) do
        {:noreply, Mob.Socket.pop_screen(socket)}
      end

      def handle_info({:tap, tag}, socket) do
        Kati.Screens.Root.rescue_tap(__MODULE__, tag, socket)
      end

      def handle_info({:kati, topic, payload}, socket) do
        Kati.Screens.Root.rescue_kati(__MODULE__, topic, payload, socket)
      end

      def handle_info(_message, socket), do: {:noreply, socket}

      defoverridable load: 1, handle_info: 2
    end
  end

  @doc "The pushed-screen frame: a back pill over the content, no tab bar."
  def chrome(back_label, content) do
    direction = Kati.Locale.direction_prop()
    assigns = %{content: content, back_label: back_label, direction: direction}

    import Mob.Sigil

    ~MOB"""
    <Box fill_width={true} fill_height={true} background={:background} layout_direction={@direction}>
      {@content}
      {Kati.Screens.Pushed.back_pill(@back_label)}
    </Box>
    """
  end

  @doc false
  def back_pill(label) do
    import Mob.Sigil
    tap = {self(), :back}
    assigns = %{label: label, tap: tap, chrome: Kati.Theme.chrome_fill(:light)}

    ~MOB"""
    <Box padding_left={21} padding_top={54}>
      <Box
        background={@chrome}
        corner_radius={999}
        padding_left={14}
        padding_right={16}
        padding_top={9}
        padding_bottom={9}
        width={:wrap}
        on_tap={@tap}
      >
        <Row vertical_align="center">
          <Text text="‹" text_size={17} text_color={:on_surface} />
          <Spacer size={6} />
          <Text text={@label} text_size={14} text_color={:on_surface} />
        </Row>
      </Box>
    </Box>
    """
  end
end
