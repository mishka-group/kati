defmodule Kati.UI.ImportChrome do
  @moduledoc """
  The pieces four import screens draw the same way.

  Screens 37, 120, 140 and 142 share a header pill, a step meter and a file
  tile, and until now they shared them by calling into `Kati.Screens.Import`.
  That was fine while every one of them drew a fixture. It stopped being fine
  the round screen 37 learned to read a file: `Kati.ScreenEmptyDatabaseTest`
  derives *which screens reach the store* from each module's compiled import
  table and closes over it, so borrowing a `Box` from a module that now reaches
  Ash made three screens store readers that read nothing.

  A derived answer is only as good as what it derives from, and the honest fix
  is not to exempt the three — it is to stop the markup living in a module with
  a database behind it. Shared chrome belongs in `Kati.UI`, where the rest of
  this app's shared chrome is.

  The pixels do not move. Every function here is the body it had one file over.
  """

  import Mob.Sigil

  alias Kati.Components.MishkaThemeIcon
  alias Kati.Components.MishkaToggle
  alias Kati.Theme.Palette

  @doc """
  The ink action pill, opposite the back pill `Kati.Screens.Pushed` floats.

  The 44pt row is what reserves the pill's space; the action sits at its
  trailing edge. `on_tap` is `nil` on three of the four screens that draw this,
  and `nil` is the ordinary answer — not tappable rather than broken.
  """
  @spec header(String.t(), {pid(), atom()} | nil) :: map()
  def header(label, on_tap \\ nil) do
    assigns = %{label: label, tap: on_tap}

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} height={44} align="center">
        <Spacer weight={1.0} />
        <Row
          height={38}
          corner_radius={19}
          background={Palette.ink_fill()}
          padding_left={16}
          padding_right={16}
          align="center"
          on_tap={@tap}
        >
          <Text
            text={@label}
            text_size={13}
            font_weight="bold"
            text_color={Palette.on_ink()}
            max_lines={1}
          />
        </Row>
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc "The 5pt gap between two step bars."
  @spec step_gap() :: map()
  def step_gap, do: ~MOB"<Spacer size={5} />"

  @doc "One bar of the step meter: ink when that step is done."
  @spec step_bar(boolean()) :: map()
  def step_bar(done?) do
    color = if done?, do: Palette.ink(), else: Palette.track_off()

    ~MOB"<Box weight={1.0} height={4} corner_radius={2} background={color} />"
  end

  @doc "The 8pt gap between two answer pills."
  @spec choice_gap() :: map()
  def choice_gap, do: ~MOB"<Spacer size={8} />"

  @doc "The 10pt gap between two outcome cards."
  @spec outcome_gap() :: map()
  def outcome_gap, do: ~MOB"<Spacer size={10} />"

  @doc """
  One answer to a conflict: a 32pt pill, ink when it is the chosen one.

  `Kati.Components.MishkaToggle`, whose own showcase builds a segmented bar out
  of nothing but these props — a chip cannot take the two colour pairs and a
  segmented control cannot take three independent labels.

  `on_tap` is `nil` unless the caller says otherwise, which is what keeps
  screen 120's three pills pictures: it draws the same control over a plan
  import that has no conflict queue to answer.
  """
  @spec choice({String.t(), boolean()}, {pid(), atom()} | nil) :: map()
  def choice(chip, on_tap \\ nil)

  def choice({label, primary?}, on_tap) do
    assigns = %{
      button:
        MishkaToggle.toggle(
          label: label,
          pressed: primary?,
          on_tap: on_tap,
          color: Palette.ink_fill(),
          text_color: Palette.on_ink(),
          background: Palette.cream_raise(),
          label_color: Palette.cream_sub(),
          corner_radius: 16,
          height: 32,
          padding: 0,
          border_width: 0,
          fill_width: true,
          align: :center,
          text_size: 11.5,
          font_weight: :semibold,
          max_lines: 1
        )
    }

    ~MOB"""
    <Box weight={1.0}>
      {@button}
    </Box>
    """
  end

  @doc "The 38pt paper tile a file row leads with."
  @spec file_tile() :: map()
  def file_tile do
    MishkaThemeIcon.theme_icon(
      %{variant: :filled, color: Palette.paper(), size: 38, radius: 11},
      [Kati.UI.symbol("description", size: 20, color: Palette.ink_soft())]
    )
  end
end
