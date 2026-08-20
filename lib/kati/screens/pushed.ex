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

  @doc """
  How far down a pushed screen's content must start.

  The pill floats at 54 and is 42 tall, so anything a screen draws at the
  design's usual 64 lands underneath it. Screens that open with a title use
  this instead — measured, not guessed: 54 + 42 + 14 of breathing room.
  """
  @spec content_top() :: pos_integer()
  def content_top, do: 110

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
    # The card colour, not the 90%-opaque chrome fill: the drawings paint this
    # pill solid and give it the same lift as every other floating control.
    assigns = %{label: label, tap: tap, chrome: Kati.Theme.card(:light)}

    # A Row, not a Box, and this was wrong on ~30 screens.
    #
    # `width={:wrap}` is not a thing: the bridge fills width whenever `width`
    # is not a NUMBER (MobBridge.kt:2673). So the pill spanned the entire
    # screen, clipped at the right edge, and painted its 90%-opaque fill over
    # whatever trailing control the screen drew — which is why those discs
    # looked pale grey rather than ink. A Row hugs its content.
    #
    # The outer Row keeps the pill left and leaves the rest of the width free,
    # so a screen's own trailing disc is untouched.
    ~MOB"""
    <Row fill_width={true} padding_left={21} padding_right={21} padding_top={64}>
      <Row
        height={44}
        background={@chrome}
        corner_radius={22}
        shadow={Kati.Theme.shadow_button()}
        padding_left={13}
        padding_right={16}
        align="center"
        on_tap={@tap}
      >
        {Kati.UI.symbol("arrow_back_ios_new", size: 17)}
        <Spacer size={6} />
        <Text
          text={@label}
          text_size={13.5}
          font_weight="semibold"
          letter_spacing={-0.01}
          text_color={:on_surface}
        />
      </Row>
      <Spacer weight={1.0} />
    </Row>
    """
  end
end
