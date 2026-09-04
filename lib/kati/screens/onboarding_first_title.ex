defmodule Kati.Screens.OnboardingFirstTitle do
  @moduledoc """
  Screen 163 — *Add your first title*, step 5 of five.

  The last step of the renumbering brief `D-33` asked for, and the one that
  makes #91's first criterion true by construction: *a clean install walked
  end to end leaves a usable app, asserted by adding a title straight after*.
  A first run that ends here has added one.

  ## What the board decides

  **Skipping lands on the empty Home — screen 139**, and not on a half-set-up
  page. Skipping is a real answer, so it gets the state the app draws for
  having nothing, which is a page that says which parts still work.

  **Artwork never mirrors.** In the RTL twin only the tick moves to the
  leading corner; a poster is a photograph and a mirrored photograph is a
  different picture. `Kati.Screens.LibraryFa` records the same rule for the
  shelf.
  """
  use Kati.Screens.Pushed, back: "Back to loudness"

  alias Kati.Screens.OnboardingWelcome
  alias Kati.Theme.Palette
  alias Kati.UI.SettingsList

  @suggestions ["The Long Hollow", "Ashfall", "Marram", "Nightbirds"]

  @impl true
  def load(socket), do: Mob.Socket.assign(socket, :picked, "The Long Hollow")

  @doc false
  def content(assigns) do
    ~MOB"""
    <Column fill_width={true}>
      {OnboardingWelcome.rail(5)}
      <Text text="Add your first title" text_size={28} max_font_scale={1.6} font_weight="bold" letter_spacing={-0.03} text_color={:on_surface} />
      <Spacer size={10} />
      <Text
        text="Pick something you are watching now — the calendar fills itself from there."
        text_size={13.5}
        line_height={1.55}
        text_color={Palette.ink_soft()}
      />
      <Spacer size={20} />
      {Kati.Screens.OnboardingFirstTitle.grid(assigns.picked)}
      <Spacer size={18} />
      {OnboardingWelcome.forward("Finish setup", :finish)}
      <Spacer size={12} />
      <Box fill_width={true} on_tap={{self(), :skip}}>
        <Text
          text="Skip — I’ll add things later"
          text_size={13}
          font_weight="semibold"
          text_color={Palette.sub()}
          text_align="center"
        />
      </Box>
      <Spacer size={18} />
      {SettingsList.note("info", "Skipping lands on empty Home — 139. Artwork never mirrors; only the tick moves to the leading corner.")}
  {OnboardingWelcome.back_row("Back to loudness")}
    </Column>
    """
  end

  @doc false
  def suggestion_list, do: @suggestions

  @doc false
  def grid(picked) do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.OnboardingFirstTitle.suggestion_list()
       |> Enum.map(fn title -> Kati.Screens.OnboardingFirstTitle.tile(title, title == picked) end)
       |> Enum.intersperse(Kati.Screens.OnboardingFirstTitle.gap())}
    </Column>
    """
  end

  @doc false
  def gap, do: ~MOB"<Spacer size={9} />"

  @doc false
  def tile(title, on?) do
    assigns = %{title: title, on?: on?, tap: {self(), String.to_atom("pick_" <> String.replace(title, " ", "_"))}}

    ~MOB"""
    <Row
      fill_width={true}
      background={if @on?, do: Palette.ink_fill(), else: Palette.card()}
      corner_radius={18}
      shadow={Kati.Theme.shadow_card_soft()}
      padding={15}
      align="center"
      on_tap={@tap}
    >
      <Text text={@title} weight={1.0} text_size={13.5} font_weight="semibold" text_color={if @on?, do: Palette.on_ink(), else: :on_surface} max_lines={1} />
      {Kati.Screens.OnboardingFirstTitle.tick(@on?)}
    </Row>
    """
  end

  @doc false
  def tick(false), do: ~MOB"<Spacer size={0} />"
  def tick(true), do: Kati.UI.symbol("check", size: 18, color: Palette.on_ink())

  @impl true
  def handle_tap(:finish, socket),
    do: {:noreply, Mob.Socket.reset_to(socket, Kati.Screens.Home)}

  # Skipping is a real answer, so it lands on the state the app draws for
  # having nothing — board 139, which states which parts still work.
  def handle_tap(:skip, socket),
    do: {:noreply, Mob.Socket.reset_to(socket, Kati.Screens.HomeEmpty)}

  def handle_tap(:step_back, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}

  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "pick_" <> title -> {:noreply, Mob.Socket.assign(socket, :picked, String.replace(title, "_", " "))}
      _other -> {:noreply, socket}
    end
  end
end
