defmodule Kati.Screens.OnboardingWelcome do
  @moduledoc """
  Screen 161 — *One place for what you keep*, step 2 of five.

  Part of the renumbering brief `D-33` asked for and board 161 answers. Screen
  38 draws more than one panel in a single scroll, which is why
  `Kati.ScreenTapSweepTest` found `finish` on two nodes at once; the flow map
  (134) has named the split as a build task since it was drawn.

  ## What the board decides

  **Restore stays beneath the button, in both scripts.** RTL mirrors the grid,
  not the vertical order — primary above, quiet alternative below. That is the
  rule for every mirrored screen in the app and it is worth having drawn once,
  because reversing a column is the RTL mistake nobody catches by reading.
  """
  use Kati.Screens.Pushed, back: "Back to language"

  alias Kati.Screens.Onboarding
  alias Kati.Theme.Palette
  alias Kati.UI.SettingsList

  @impl true
  def load(socket) do
    Kati.Onboarding.reached!(:welcome)
    socket
  end

  @doc false
  def content(_assigns) do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.OnboardingWelcome.rail(2)}
      {Kati.Screens.OnboardingWelcome.mark()}
      <Text
        text="One place for"
        text_size={28}
        max_font_scale={1.6}
        font_weight="bold"
        letter_spacing={-0.03}
        text_color={:on_surface}
      />
      <Text
        text="what you keep"
        text_size={28}
        max_font_scale={1.6}
        font_weight="bold"
        letter_spacing={-0.03}
        text_color={:on_surface}
      />
      <Spacer size={10} />
      <Text
        text="Films, shows, books, habits — each one is a shelf, and all of them feed a single calendar. Start with one and add the rest whenever."
        text_size={13.5}
        line_height={1.55}
        text_color={Palette.ink_soft()}
      />
      <Spacer size={24} />
      {Kati.Screens.OnboardingWelcome.forward("Get started", :next)}
      <Spacer size={12} />
      <Box fill_width={true} on_tap={{self(), :restore}}>
        <Text
          text="Already have a Kati backup? Restore it"
          text_size={13}
          font_weight="semibold"
          text_color={Palette.sub()}
          text_align="center"
        />
      </Box>
      <Spacer size={18} />
      {SettingsList.note("info", "Restore stays beneath the button in both scripts. RTL mirrors the grid, not the vertical order — primary above, quiet alternative below.")}
      {Kati.Screens.OnboardingWelcome.back_row("Back to language")}
    </Column>
    """
  end

  @doc """
  The Kati mark: a 56pt ink tile with the accent dot centred in it.

  The same object `Kati.Screens.Onboarding.welcome/1` draws at the head of
  screen 38's first panel — 161 is that panel renumbered, so it keeps the
  mark. Shared with the Persian twin, 164, which draws it identically:
  a dot in a square has no handedness and mirroring it would be motion for
  its own sake.
  """
  @spec mark() :: map()
  def mark do
    ~MOB"""
    <Column fill_width={true}>
      <Box width={56} height={56} corner_radius={18} background={Palette.ink()} align="center">
        <Box width={13} height={13} corner_radius={7} background={Kati.Theme.accent()} />
      </Box>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc """
  The primary button, with the forward arrow every step board draws.

  `Kati.UI.Sheet.commit/2` is the sentence a sheet completes and carries no
  glyph; a step in a sequence is going somewhere, and the boards say so with
  `arrow_forward` beside the label.
  """
  @spec forward(String.t(), atom()) :: map()
  def forward(label, tag) do
    assigns = %{label: label, tap: {self(), tag}}

    ~MOB"""
    <Row
      fill_width={true}
      height={54}
      corner_radius={27}
      background={Palette.ink_fill()}
      align="center"
      on_tap={@tap}
    >
      <Spacer weight={1.0} />
      <Text text={@label} text_size={14.5} font_weight="bold" text_color={Palette.on_ink()} max_lines={1} />
      <Spacer size={9} />
      {Kati.UI.symbol("arrow_forward", size: 18, color: Palette.on_ink())}
      <Spacer weight={1.0} />
    </Row>
    """
  end

  @doc """
  The step back, named for where it goes.

  `arrow_back` and not `arrow_back_ios_new`: a sequence steps back through
  itself rather than popping a stack, and the boards draw the difference.
  """
  @spec back_row(String.t()) :: map()
  def back_row(label) do
    assigns = %{label: label, tap: {self(), :step_back}}

    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={18} />
      <Row align="center" on_tap={@tap}>
        {Kati.UI.symbol("arrow_back", size: 17, color: Palette.sub())}
        <Spacer size={8} />
        <Text text={@label} text_size={12.5} font_weight="semibold" text_color={Palette.sub()} max_lines={1} />
      </Row>
    </Column>
    """
  end

  @doc "The five-step rail this renumbering introduces, filled to `done`."
  @spec rail(pos_integer()) :: map()
  def rail(done) do
    assigns = %{done: done}

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        {1..5
         |> Enum.map(fn i -> Onboarding.step_bar(i <= @done) end)
         |> Enum.intersperse(Onboarding.step_gap())}
      </Row>
      <Spacer size={24} />
    </Column>
    """
  end

  @impl true
  def handle_tap(:next, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.PickSections)}

  def handle_tap(:restore, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Restore)}

  def handle_tap(:step_back, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}

  def handle_tap(_tag, socket), do: {:noreply, socket}
end
