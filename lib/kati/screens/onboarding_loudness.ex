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

  **Notify me** raises the prompt on the **next** step,
  `Kati.Screens.LoudnessPrompt`.

  ## What the choice is stored as

  The release watcher's own *Push notifications* switch —
  `Kati.Settings.Watcher.loud?(:push)`, the one screen 25 draws and
  `Kati.Notifications.Releases.sync/1` reads. The step used to hold the answer
  in an assign and drop it on Continue, so a reader who asked to be notified
  had push off exactly as if they had not been asked. There is no *Weekly
  digest* card: nothing in Kati sends one, and screen 25 took its switch away
  for that reason, so offering it here promised something the app does not do.
  """
  use Kati.Screens.Pushed, back: nil
  use Gettext, backend: Kati.Gettext

  # `back: nil` — the board draws no pill. Its back control is the row at
  # the foot of the page, "Back to sections", which `back_row/1` builds. A
  # floating pill over this would be a second way back the design did not
  # draw, sitting on top of the step rail.

  alias Kati.Screens.OnboardingWelcome
  alias Kati.Theme.Palette
  alias Kati.UI

  # `{key, glyph}`. The KEY is the state and the words are asked for at draw
  # time — mishka-group/kati#158's rule, and #103's fold is what made it matter
  # here: `:choice` held the label, `after_choice/1` matched on `"Quietly"`, and
  # the Persian mirror's own label was آرام. Every clause would have fallen
  # through on a Persian run and sent a quiet reader to the OS prompt.
  @choices [{:quiet, "inbox"}, {:notify, "notifications"}]

  @impl true
  def load(socket) do
    Kati.Onboarding.reached!(:loudness)
    Mob.Socket.assign(socket, :choice, Kati.Screens.OnboardingLoudness.stored())
  end

  @doc """
  The choice the watcher's push switch already holds — `:quiet` on a fresh
  install, where push defaults off.
  """
  @spec stored() :: :quiet | :notify
  def stored, do: if(Kati.Settings.Watcher.loud?(:push), do: :notify, else: :quiet)

  @doc "Write a choice through to the watcher's push switch."
  @spec store(:quiet | :notify) :: :ok
  def store(:notify), do: Kati.Settings.Watcher.put_loud(:push, true)
  def store(_quiet), do: Kati.Settings.Watcher.put_loud(:push, false)

  @doc false
  def content(assigns) do
    Kati.Screens.Pushed.page(~MOB"""
    <Column fill_width={true}>
      {OnboardingWelcome.rail(4)}
      {Kati.Screens.OnboardingLoudness.heading()}
      <Spacer size={Kati.Locale.pick(10, 14)} />
      <Text
        text={gettext("Kati checks for new episodes on its own. You choose how loudly it mentions them.")}
        text_size={Kati.Locale.pick(13.5, 14)}
        line_height={Kati.Locale.leading(1.55)}
        text_color={Palette.ink_soft()}
      />
      <Spacer size={20} />
      {Kati.Screens.OnboardingLoudness.choices(assigns.choice)}
      {Kati.Screens.OnboardingLoudness.quiet_note(assigns.choice)}
      <Spacer size={18} />
      {OnboardingWelcome.forward(gettext("Continue"), :next)}
      <Spacer size={14} />
      {OnboardingWelcome.back_row(gettext("Back to sections"))}
    </Column>
    """)
  end

  @doc """
  The two choices, in the reader's own language.

      iex> Kati.Screens.OnboardingLoudness.choice_list() |> Enum.map(&elem(&1, 0))
      [:quiet, :notify]
  """
  @spec choice_list() :: [{atom(), String.t(), String.t(), String.t()}]
  def choice_list do
    Enum.map(@choices, fn {key, icon} ->
      {key, Kati.Screens.OnboardingLoudness.label(key), Kati.Screens.OnboardingLoudness.line(key),
       icon}
    end)
  end

  @doc false
  @spec label(atom()) :: String.t()
  def label(:notify), do: gettext("Notify me")
  def label(_quiet), do: gettext("Quietly")

  @doc false
  @spec line(atom()) :: String.t()
  def line(:notify), do: gettext("A push when something lands.")
  def line(_quiet), do: gettext("A card on home. Nothing buzzes.")

  @doc """
  The question, as many lines as its own board draws it in.

  **Two `Text`s in Latin and one in Persian.** Board 165 asks
  `چطور به شما خبر بدهیم؟` on a single line and 136 breaks *How should we / tell
  you?* across two — a line break is typesetting, and the catalogue is where a
  translation's own typesetting belongs. One msgid carrying a `\n`, split here,
  rather than two msgids one of which would have to be empty.
  """
  @spec heading() :: [map()]
  def heading do
    gettext("How should we\ntell you?")
    |> String.split("\n")
    |> Enum.map(&Kati.Screens.OnboardingLoudness.heading_line/1)
  end

  @doc false
  @spec heading_line(String.t()) :: map()
  def heading_line(line) do
    assigns = %{line: line}

    ~MOB"""
    <Text
      text={@line}
      text_size={28}
      max_font_scale={1.6}
      font_weight="bold"
      letter_spacing={Kati.Locale.tracking(-0.03)}
      text_color={:on_surface}
    />
    """
  end

  @doc "Take a choice's tap, if it names one of the two, and store it."
  @spec pick_choice(Mob.Socket.t(), String.t()) :: Mob.Socket.t()
  def pick_choice(socket, key) do
    case Enum.find(@choices, fn {choice, _icon} -> Atom.to_string(choice) == key end) do
      {choice, _icon} ->
        Kati.Screens.OnboardingLoudness.store(choice)
        Mob.Socket.assign(socket, :choice, choice)

      nil ->
        socket
    end
  end

  @doc false
  def choices(active) do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.OnboardingLoudness.choice_list()
       |> Enum.map(fn {key, label, line, icon} ->
         Kati.Screens.OnboardingLoudness.row(key, label, line, icon, key == active)
       end)
       |> Enum.intersperse(Kati.Screens.OnboardingLoudness.gap())}
      <Spacer size={16} />
    </Column>
    """
  end

  @doc false
  def gap, do: ~MOB"<Spacer size={9} />"

  @doc false
  def row(key, label, line, icon, on?) do
    assigns = %{
      label: label,
      line: line,
      icon: icon,
      on?: on?,
      # Built here rather than through `Kati.Screens.AddByHand.tag/2`: that
      # module reaches the store, and `Kati.ScreenEmptyDatabaseTest` derives
      # *this screen reads the database* from the compiled import table. A pure
      # string function is not worth a screen joining that list.
      tap: {self(), String.to_atom("choose_" <> Atom.to_string(key))}
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
  @spec quiet_note(atom()) :: map()
  def quiet_note(:quiet) do
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
          text={gettext("Kati won’t ask for notification permission. Everything arrives in your inbox.")}
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

  *Notify me* takes the OS prompt on the way — `Kati.Screens.LoudnessPrompt`.
  The choice is stored before either route, so the answer survives whatever
  the reader does at the system dialog.

  Quietly goes straight on, and that is the decision the board makes rather
  than a shortcut: Kati raises no notification prompt at all for a reader who
  chose it. A dialog asking for a permission the choice does not need is how
  an app teaches people to refuse them.
  """
  @impl true
  def handle_tap(:next, socket) do
    Kati.Screens.OnboardingLoudness.store(socket.assigns[:choice])

    {:noreply,
     Mob.Socket.push_screen(socket, Kati.Screens.OnboardingLoudness.after_choice(socket))}
  end

  def handle_tap(:step_back, socket), do: {:noreply, Kati.Screens.Resume.pop(socket)}

  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "choose_" <> key -> {:noreply, Kati.Screens.OnboardingLoudness.pick_choice(socket, key)}
      _other -> {:noreply, socket}
    end
  end

  @doc false
  @spec after_choice(Mob.Socket.t()) :: module()
  def after_choice(socket) do
    case socket.assigns[:choice] do
      :notify -> Kati.Screens.LoudnessPrompt
      _quiet -> Kati.Screens.OnboardingFirstTitle
    end
  end
end
