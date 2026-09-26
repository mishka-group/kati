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
  use Kati.Screens.Pushed, back: nil
  use Gettext, backend: Kati.Gettext

  # `back: nil` — the board draws no pill. Its back control is the row at
  # the foot of the page, "Back to language", which `back_row/1` builds. A
  # floating pill over this would be a second way back the design did not
  # draw, sitting on top of the step rail.

  alias Kati.Screens.Onboarding
  alias Kati.Theme.Palette

  @impl true
  def load(socket) do
    Kati.Onboarding.reached!(:welcome)
    socket
  end

  @doc false
  def content(_assigns) do
    Kati.Screens.Pushed.page(~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.OnboardingWelcome.rail(2)}
      {Kati.Screens.OnboardingWelcome.mark()}
      <Text
        text={gettext("One place for")}
        text_size={28}
        max_font_scale={1.6}
        font_weight="bold"
        letter_spacing={Kati.Locale.tracking(-0.03)}
        text_color={:on_surface}
      />
      <Text
        text={gettext("what you keep")}
        text_size={28}
        max_font_scale={1.6}
        font_weight="bold"
        letter_spacing={Kati.Locale.tracking(-0.03)}
        text_color={:on_surface}
      />
      <Spacer size={Kati.Locale.pick(10, 14)} />
      <Text
        text={gettext("Films, shows, books, habits — each one is a shelf, and all of them feed a single calendar. Start with one and add the rest whenever.")}
        text_size={Kati.Locale.pick(13.5, 14)}
        line_height={Kati.Locale.leading(1.55)}
        text_color={Palette.ink_soft()}
      />
      <Spacer size={24} />
      {Kati.Screens.OnboardingWelcome.forward(gettext("Get started"), :next)}
      <Spacer size={12} />
      <Box fill_width={true} on_tap={{self(), :restore}}>
        <Text
          text={gettext("Already have a Kati backup? Restore it")}
          text_size={13}
          font_weight="semibold"
          text_color={Palette.sub()}
          text_align="center"
        />
      </Box>
      <Spacer size={18} />
      {Kati.Screens.OnboardingWelcome.back_row(gettext("Back to language"))}
    </Column>
    """)
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
  `Kati.Locale.forward_glyph/0` beside the label — `arrow_forward` in Latin and
  `arrow_back` in Persian. `layout_direction` mirrors a LAYOUT and cannot mirror
  a picture, and an arrow is a picture; board 164's caption says so in as many
  words. That glyph was `Kati.Screens.OnboardingWelcomeFa.forward/2`'s whole
  reason to exist, and mishka-group/kati#103's fold is what made it shared.
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
      <Text
        text={@label}
        text_size={14.5}
        font_weight="bold"
        text_color={Palette.on_ink()}
        max_lines={1}
      />
      <Spacer size={9} />
      {Kati.UI.symbol(Kati.Locale.forward_glyph(), size: 18, color: Palette.on_ink())}
      <Spacer weight={1.0} />
    </Row>
    """
  end

  @doc """
  The step back, named for where it goes.

  `Kati.Locale.back_glyph/0`, the exact inversion of `forward/2` above.

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
        {Kati.UI.symbol(Kati.Locale.back_glyph(), size: 17, color: Palette.sub())}
        <Spacer size={8} />
        <Text
          text={@label}
          text_size={12.5}
          font_weight="semibold"
          text_color={Palette.sub()}
          max_lines={1}
        />
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

  @doc """
  Where *Restore it* goes, which is a different screen in each script.

  `restore_screen` and not `restore`: `Mob.Screen` already defines a `restore`.

      iex> Kati.Screens.OnboardingWelcome.restore_screen()
      Kati.Screens.Restore

  `Kati.Screens.RestoreFa` was a mirror and this forked. Since
  mishka-group/kati#103 folded it away there is one screen, so it does not.
  forking the day that one folds.
  """
  @spec restore_screen() :: module()
  def restore_screen, do: Kati.Screens.Restore

  # `screen_for_step/1` rather than the module by name, because this screen is
  # now BOTH runs. Board 164's own step forward is 137 — screen 26 in Persian —
  # and naming `Kati.Screens.PickSections` here would have walked a Persian
  # reader onto an English page at step 3. mishka-group/kati#103.
  @impl true
  def handle_tap(:next, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Onboarding.screen_for_step(:sections))}

  def handle_tap(:restore, socket),
    do:
      {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.OnboardingWelcome.restore_screen())}

  def handle_tap(:step_back, socket), do: {:noreply, Kati.Screens.Resume.pop(socket)}

  def handle_tap(_tag, socket), do: {:noreply, socket}
end
