defmodule Kati.Screens.OnboardingWelcomeFa do
  @moduledoc """
  Screen 164 — خوش‌آمد, step 2 of five in Persian.

  Built to `test/design/screens/164.html`, the mirror of
  `Kati.Screens.OnboardingWelcome`. Its caption names it exactly: *"the Persian
  step 2 a first run currently walks in English"*.

  ## The three rules this board and its two siblings settle

    * **Restore keeps its position, beneath the button.** RTL mirrors the grid,
      not the vertical order — the primary action above, the quiet alternative
      below, in both scripts. Reversing a column is the RTL mistake nobody
      catches by reading, so the board draws it rather than describing it.
    * **The forward arrow is `arrow_back`.** A glyph that points at where the
      reader is going, and in Persian that is leftward. The step back takes
      `arrow_forward` for the same reason, which reads wrong in a diff and
      right on a phone. `Kati.Screens.AddByHandFa` records the same trap for
      the chevron on screen 156.
    * **The mark does not mirror.** A dot centred in a square has no
      handedness; `Kati.Screens.OnboardingWelcome.mark/0` is drawn here
      unchanged.

  ## Why these three screens are what unblock the locale

  `Kati.Onboarding.screen_for_step/1` carried a comment explaining why it was
  deliberately not locale-aware: artboard 137 is screen **26** in Persian, not
  38, so routing the finish step there would send a Persian run back to the
  sections question and strand it. That comment ends *"closing that needs
  Persian artboards that do not exist"*. 164, 165 and 166 are those artboards.
  """
  use Mob.Screen
  import Mob.Sigil

  alias Kati.Screens.Fa
  alias Kati.Screens.OnboardingWelcome
  alias Kati.Theme.Palette

  def mount(_params, _session, socket) do
    Kati.Theme.activate()
    Kati.Onboarding.reached!(:welcome)
    {:ok, socket}
  end

  def render(assigns) do
    Fa.pushed_frame(Fa.page(content(assigns)), Kati.Screens.Identity.of(__MODULE__))
  end

  @doc false
  def content(_assigns) do
    ~MOB"""
    <Column fill_width={true}>
      {OnboardingWelcome.rail(2)}
      {OnboardingWelcome.mark()}
      <Text
        text="یک جا برای
هر چه نگه می‌دارید"
        font_family="fa"
        text_size={28}
        max_font_scale={1.6}
        font_weight="bold"
        line_height={1.45}
        text_color={:on_surface}
      />
      <Spacer size={14} />
      <Text
        text="فیلم، سریال، کتاب، عادت — هر کدام یک قفسه‌اند و همه به یک تقویم می‌ریزند. با یکی شروع کنید و بقیه را هر وقت خواستید اضافه کنید."
        font_family="fa"
        text_size={14}
        line_height={1.95}
        text_color={Palette.ink_soft()}
      />
      <Spacer size={24} />
      {Kati.Screens.OnboardingWelcomeFa.forward("شروع کنیم", :next)}
      <Spacer size={14} />
      <Box fill_width={true} on_tap={{self(), :restore}}>
        <Text
          text="پشتیبان دارید؟ بازگردانی کنید"
          font_family="fa"
          text_size={13}
          font_weight="semibold"
          text_color={Palette.sub()}
          text_align="center"
        />
      </Box>
      <Spacer size={20} />
      {Fa.note("info", "بازگردانی زیر دکمه می‌ماند — جایش عوض نمی‌شود. در RTL همه‌چیز آینه می‌شود جز ترتیب عمودی: عمل اصلی بالا، جایگزین آرام پایین، در هر دو زبان.")}
      {Kati.Screens.OnboardingWelcomeFa.back_row("بازگشت به زبان")}
    </Column>
    """
  end

  @doc """
  The primary button of a Persian step: `arrow_back` beside the label.

  Not a mirrored `arrow_forward`. The glyph points where the reader is going,
  which in a right-to-left grid is the left edge, and all three Persian step
  boards draw it that way. Shared by 165 and 166.
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
        font_family="fa"
        text_size={14}
        font_weight="bold"
        text_color={Palette.on_ink()}
        max_lines={1}
      />
      <Spacer size={9} />
      {Kati.UI.symbol("arrow_back", size: 18, color: Palette.on_ink())}
      <Spacer weight={1.0} />
    </Row>
    """
  end

  @doc """
  The step back, named for where it goes, with `arrow_forward` leading it.

  The mirror of `Kati.Screens.OnboardingWelcome.back_row/1` and the exact
  inversion of `forward/2` above: back is where the reader came from, and in
  Persian that is the right.
  """
  @spec back_row(String.t()) :: map()
  def back_row(label) do
    assigns = %{label: label, tap: {self(), :step_back}}

    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={20} />
      <Row align="center" on_tap={@tap}>
        {Kati.UI.symbol("arrow_forward", size: 17, color: Palette.sub())}
        <Spacer size={7} />
        <Text
          text={label}
          font_family="fa"
          text_size={13}
          font_weight="semibold"
          text_color={Palette.sub()}
          max_lines={1}
        />
      </Row>
    </Column>
    """
  end

  def handle_info({:tap, :next}, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.OnboardingFa)}

  def handle_info({:tap, :restore}, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.RestoreFa)}

  def handle_info({:tap, :step_back}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}
  def handle_info({:tap, :back}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}

  def handle_info({:tap, tag}, socket), do: Fa.dock_tap(tag, :home, socket)
  def handle_info(_message, socket), do: {:noreply, socket}
end
