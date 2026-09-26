defmodule Kati.Screens.LoudnessPrompt do
  @moduledoc """
  Screen 136 — the notification permission, for a reader who chose *Notify me*.

  Reached from step 4, `Kati.Screens.OnboardingLoudness`, which has already
  stored the choice as the release watcher's push switch. This page says what
  the permission is for, then **Continue** raises Android's dialog.

  ## It used to be the design board

  Board 136 draws step 4 again with all three of its outcomes stacked beneath
  it — the *Quietly* sentence, the pre-prompt, the refusal — and the screen drew
  exactly that, reading the question and its cards from
  `Kati.Onboarding.Sample.telling/0`. So a reader who chose *Notify me* landed
  on a page with *Quietly* ticked and a sentence promising Kati would not ask
  for permission, directly above the button that asked. The page now draws the
  one outcome the reader is in.

  ## What each answer does

    * **Granted** — push stays on, and the run goes on to the first title.
    * **Denied or blocked** — push is switched back off, since the switch
      would otherwise claim a delivery Android will not make; the bell's inbox
      holds the same releases either way. The run goes on: Android will not
      re-prompt once refused, so holding someone here would be holding them at
      a question that can no longer be asked.
    * **Already granted, or no platform to ask** (a host, or iOS today) —
      Continue goes straight on without raising anything.

  The screen does not advance until the answer arrives:
  `Mob.Permissions.request/2` delivers its result to the process that asked,
  so pushing the next step in the same breath sends the answer to a screen
  that no longer exists.
  """
  use Kati.Screens.Pushed, back: nil
  use Gettext, backend: Kati.Gettext

  alias Kati.Permissions
  alias Kati.Screens.OnboardingWelcome
  alias Kati.Theme.Palette
  alias Kati.UI

  @impl true
  def load(socket),
    do: Mob.Socket.assign(socket, :notifications, Permissions.status(:notifications))

  @doc false
  def content(_assigns) do
    Kati.Screens.Pushed.page(~MOB"""
    <Column fill_width={true}>
      {OnboardingWelcome.rail(4)}
      <Text
        text={gettext("One prompt, then never again")}
        text_size={28}
        max_font_scale={1.6}
        font_weight="bold"
        letter_spacing={Kati.Locale.tracking(-0.03)}
        text_color={:on_surface}
      />
      <Spacer size={Kati.Locale.pick(10, 14)} />
      <Text
        text={gettext("Continue raises Android’s permission dialog once. Kati uses it for new episodes and releases you follow, and the meal reminders you switch on — nothing else.")}
        text_size={Kati.Locale.pick(13.5, 14)}
        line_height={Kati.Locale.leading(1.55)}
        text_color={Palette.ink_soft()}
      />
      <Spacer size={20} />
      {Kati.Screens.LoudnessPrompt.denial()}
      <Spacer size={18} />
      {OnboardingWelcome.forward(gettext("Continue"), :continue)}
      <Spacer size={14} />
      {OnboardingWelcome.back_row(gettext("Back to loudness"))}
    </Column>
    """)
  end

  @doc "What a refusal means: a sentence, not a button — Android will not re-prompt."
  def denial do
    body = [
      text_size: 12.5,
      line_height: Kati.Locale.leading(1.65),
      text_color: Palette.cream_body(),
      font_family: Kati.Locale.face_prop(),
      base: true
    ]

    strong = [
      font_weight: "semibold",
      text_color: Palette.cream_ink(),
      text_size: 12.5,
      line_height: Kati.Locale.leading(1.65),
      font_family: Kati.Locale.face_prop()
    ]

    paragraph =
      UI.rich_text([
        {gettext("If you say no, Kati falls back to the inbox badge and") <> " ", body},
        {gettext("will not ask again"), strong},
        {". " <>
           gettext(
             "Android does not allow a second prompt — the only way back is its own settings app."
           ), body}
      ])

    ~MOB"""
    <Box fill_width={true} background={Palette.cream()} corner_radius={20} padding={16}>
      <Row fill_width={true} align="top">
        {Kati.UI.symbol("notifications_off", size: 18, color: Palette.gold_icon())}
        <Spacer size={11} />
        <Column weight={1.0}>
          {paragraph}
        </Column>
      </Row>
    </Box>
    """
  end

  @doc """
  Whether Continue has a dialog to raise: only on Android, and only while the
  permission is neither granted nor refused for good.

      iex> Kati.Screens.LoudnessPrompt.ask?(:unasked, true)
      true

      iex> Kati.Screens.LoudnessPrompt.ask?(:granted, true)
      false

      iex> Kati.Screens.LoudnessPrompt.ask?(:unknown, false)
      false
  """
  @spec ask?(Permissions.state(), boolean()) :: boolean()
  def ask?(state, platform?), do: platform? and state not in [:granted, :blocked]

  @impl true
  def handle_tap(:continue, socket) do
    if ask?(Permissions.status(:notifications), Permissions.platform_answers?()) do
      {:noreply, Kati.Screens.LoudnessPrompt.continue(socket)}
    else
      {:noreply, Kati.Screens.LoudnessPrompt.settle(socket, Permissions.status(:notifications))}
    end
  end

  def handle_tap(:step_back, socket), do: {:noreply, Kati.Screens.Resume.pop(socket)}

  @impl true
  def handle_info({:permission, :notifications, result}, socket),
    do: {:noreply, Kati.Screens.LoudnessPrompt.settle(socket, result)}

  def handle_info(message, socket), do: super(message, socket)

  @doc """
  Record the answer on the push switch, and go on to the first title.

  Only a refusal changes the switch: `:unknown` off Android leaves the reader's
  *Notify me* standing, since nothing has said no. Nothing is armed here — the
  shelf is empty until the next step, and `Kati.Notifications.Releases.sync/1`
  runs on the watcher's own check.
  """
  @spec settle(Mob.Socket.t(), atom()) :: Mob.Socket.t()
  def settle(socket, result) do
    if result in [:denied, :blocked], do: Kati.Settings.Watcher.put_loud(:push, false)
    Mob.Socket.push_screen(socket, Kati.Screens.OnboardingFirstTitle)
  end

  @doc """
  Raise the system dialog and note that it was asked — the same shape as
  `Kati.Screens.NotificationsHelp.ask/1`, so a later `:blocked` read can be
  told apart from `:unasked`.
  """
  @spec continue(Mob.Socket.t()) :: Mob.Socket.t()
  def continue(socket) do
    socket = Mob.Permissions.request(socket, :notifications)
    Permissions.note_asked(:notifications)
    socket
  rescue
    _error -> socket
  end
end
