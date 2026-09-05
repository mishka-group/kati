defmodule Kati.Screens.OnboardingLoudness do
  @moduledoc """
  Screen 162 — *How should we tell you?*, step 4 of five.

  This is the board `Kati.Screens.LoudnessPrompt` has been waiting on.
  `Kati.AppReachabilityTest`'s inventory says so in as many words: that screen
  *"is the three outcomes of 38·3's loudness choice, and its entry is 38·3
  itself routing forward, which needs 38 renumbered to five steps"*. #93's own
  analysis named it the single thing that ticket was blocked on. Step 4 is
  38·3, and it routes forward.

  ## What the board decides

  **Quietly asks for nothing.** Kati will not raise the OS notification prompt
  for a reader who chose it — everything arrives in the inbox instead, which
  is a real decision and not a default: a permission dialog on a choice that
  needs no permission is how an app teaches people to refuse them.

  Choosing *Notify me* or *Weekly digest* raises the prompt on the **next**
  step, which is the band drawn on screen 136.
  """
  use Kati.Screens.Pushed, back: nil

  # `back: nil` — the board draws no pill. Its back control is the row at
  # the foot of the page, "Back to sections", which `back_row/1` builds. A
  # floating pill over this would be a second way back the design did not
  # draw, sitting on top of the step rail.

  alias Kati.Screens.OnboardingWelcome
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  @choices [
    {"Quietly", "A card on home. Nothing buzzes.", "inbox"},
    {"Notify me", "A push when something lands.", "notifications"},
    {"Weekly digest", "One summary, Sundays at 18:00.", "mail"}
  ]

  @impl true
  def load(socket) do
    Kati.Onboarding.reached!(:loudness)
    Mob.Socket.assign(socket, :choice, "Quietly")
  end

  @doc false
  def content(assigns) do
    Kati.Screens.Pushed.page(~MOB"""
    <Column fill_width={true}>
      {OnboardingWelcome.rail(4)}
      <Text
        text="How should we"
        text_size={28}
        max_font_scale={1.6}
        font_weight="bold"
        letter_spacing={-0.03}
        text_color={:on_surface}
      />
      <Text
        text="tell you?"
        text_size={28}
        max_font_scale={1.6}
        font_weight="bold"
        letter_spacing={-0.03}
        text_color={:on_surface}
      />
      <Spacer size={10} />
      <Text
        text="Kati checks for new episodes on its own. You choose how loudly it mentions them."
        text_size={13.5}
        line_height={1.55}
        text_color={Palette.ink_soft()}
      />
      <Spacer size={20} />
      {Kati.Screens.OnboardingLoudness.choices(assigns.choice)}
      {Kati.Screens.OnboardingLoudness.quiet_note(assigns.choice)}
      <Spacer size={18} />
      {OnboardingWelcome.forward("Continue", :next)}
      <Spacer size={14} />
      {SettingsList.note("info", "Choosing Notify me or Weekly digest raises the OS prompt on the next step — the band drawn on 136")}
      {OnboardingWelcome.back_row("Back to sections")}
    </Column>
    """)
  end

  @doc false
  def choice_list, do: @choices

  @doc false
  def choices(active) do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.OnboardingLoudness.choice_list()
       |> Enum.map(fn {label, line, icon} ->
         Kati.Screens.OnboardingLoudness.row(label, line, icon, label == active)
       end)
       |> Enum.intersperse(Kati.Screens.OnboardingLoudness.gap())}
      <Spacer size={16} />
    </Column>
    """
  end

  @doc false
  def gap, do: ~MOB"<Spacer size={9} />"

  @doc false
  def row(label, line, icon, on?) do
    assigns = %{
      label: label,
      line: line,
      icon: icon,
      on?: on?,
      tap: {self(), String.to_atom("choose_" <> label)}
    }

    ~MOB"""
    <Row
      fill_width={true}
      background={if @on?, do: Palette.ink_fill(), else: Palette.card()}
      corner_radius={20}
      shadow={Kati.Theme.shadow_card_soft()}
      padding={16}
      align="center"
      on_tap={@tap}
    >
      {UI.symbol(@icon, size: 19, color: if(@on?, do: Palette.on_ink(), else: Palette.ink_soft()))}
      <Spacer size={12} />
      <Column weight={1.0}>
        <Text
          text={@label}
          text_size={13.5}
          font_weight="semibold"
          text_color={if @on?, do: Palette.on_ink(), else: :on_surface}
        />
        <Spacer size={4} />
        <Text
          text={@line}
          text_size={11.5}
          text_color={if @on?, do: Palette.on_ink(), else: Palette.sub()}
        />
      </Column>
      {Kati.Screens.OnboardingLoudness.tick(@on?)}
    </Row>
    """
  end

  @doc false
  def tick(false), do: ~MOB"<Spacer size={0} />"
  def tick(true), do: Kati.UI.symbol("check", size: 18, color: Palette.on_ink())

  @doc """
  The sentence that only *Quietly* earns.

  Drawn under the choice because it is the consequence of it: Kati raises no
  notification permission prompt at all for a reader who picked the quiet
  option. A dialog asking for a permission the choice does not need is how an
  app teaches people to refuse them.
  """
  @spec quiet_note(String.t()) :: map()
  def quiet_note("Quietly") do
    ~MOB"""
    <Row
      fill_width={true}
      background={Kati.Theme.Palette.card()}
      corner_radius={20}
      shadow={Kati.Theme.shadow_card_soft()}
      padding={16}
      align="top"
    >
      {Kati.UI.symbol("check_circle", size: 17, color: Kati.Theme.Palette.green())}
      <Spacer size={9} />
      <Column weight={1.0}>
        <Text
          text="Kati"
          text_size={12.5}
          line_height={1.5}
          text_color={Kati.Theme.Palette.ink_soft()}
        />
        <Text
          text="won’t ask"
          text_size={12.5}
          line_height={1.5}
          font_weight="semibold"
          text_color={Kati.Theme.Palette.ink()}
        />
        <Text
          text="for notification permission. Everything arrives in your inbox."
          text_size={12.5}
          line_height={1.5}
          text_color={Kati.Theme.Palette.ink_soft()}
        />
      </Column>
    </Row>
    """
  end

  def quiet_note(_other), do: ~MOB"<Spacer size={0} />"

  @doc """
  Where Continue goes, which is the whole of what this step decides.

  A loud choice takes the OS prompt on the way — board 136, which this screen's
  own dashed note names: *"Choosing Notify me or Weekly digest raises the OS
  prompt on the next step."* `Kati.Screens.LoudnessPrompt` is that band, and
  its entry has been *"38·3 itself routing forward, which needs 38 renumbered
  to five steps"* since `Kati.AppReachabilityTest`'s inventory was written.
  This is that step, and this is it routing forward.

  Quietly goes straight on, and that is the decision the board makes rather
  than a shortcut: Kati raises no notification prompt at all for a reader who
  chose it. A dialog asking for a permission the choice does not need is how
  an app teaches people to refuse them.
  """
  @impl true
  def handle_tap(:next, socket) do
    {:noreply,
     Mob.Socket.push_screen(socket, Kati.Screens.OnboardingLoudness.after_choice(socket))}
  end

  def handle_tap(:step_back, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}

  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "choose_" <> label -> {:noreply, Mob.Socket.assign(socket, :choice, label)}
      _other -> {:noreply, socket}
    end
  end

  @doc false
  @spec after_choice(Mob.Socket.t()) :: module()
  def after_choice(socket) do
    case socket.assigns[:choice] do
      "Quietly" -> Kati.Screens.OnboardingFirstTitle
      _loud -> Kati.Screens.LoudnessPrompt
    end
  end
end
