defmodule Kati.Screens.OnboardingFirstTitleFa do
  @moduledoc """
  Screen 166 — اولین عنوان, step 5 of five in Persian, and the end of the run.

  Built to `test/design/screens/166.html`, the mirror of
  `Kati.Screens.OnboardingFirstTitle`.

  ## The one place the mirroring rule bites

  **Poster artwork never mirrors.** The tile is identical to 163's, down to the
  2:3 lock, and only the selection tick crosses — to the trailing corner, which
  `Alignment.TopEnd` puts on the left here and on the right there without this
  screen deciding anything. A poster is a photograph, and a mirrored photograph
  is a different picture. `Kati.Screens.LibraryFa` keeps the same rule for the
  shelf.

  ## Skipping lands on 158, not 139

  The Persian empty Home, which is the pairing this brief and `D-32` complete
  between them: `Kati.Screens.HomeFaEmpty` exists because 158 was drawn in the
  same delivery, and without it this step's skip would have had to end an
  entirely Persian run on an English page.
  """
  use Mob.Screen
  import Mob.Sigil

  alias Kati.Screens.Fa
  alias Kati.Screens.OnboardingFirstTitle
  alias Kati.Screens.OnboardingWelcome
  alias Kati.Screens.OnboardingWelcomeFa
  alias Kati.Theme.Palette

  @suggestions ["گودال بلند", "بارش خاکستر", "مرام", "پرندگان شب"]

  def mount(_params, _session, socket) do
    Kati.Theme.activate()
    Kati.Onboarding.reached!(:first_title)
    {:ok, Mob.Socket.assign(socket, :picked, "گودال بلند")}
  end

  def render(assigns) do
    Fa.pushed_frame(Fa.page(content(assigns)), Kati.Screens.Identity.of(__MODULE__))
  end

  @doc false
  def content(assigns) do
    ~MOB"""
    <Column fill_width={true}>
      {OnboardingWelcome.rail(5)}
      <Text
        text="اولین عنوان را اضافه کنید"
        font_family="fa"
        text_size={24}
        max_font_scale={1.6}
        font_weight="bold"
        text_color={:on_surface}
      />
      <Spacer size={10} />
      <Text
        text="چیزی را انتخاب کنید که همین حالا تماشا می‌کنید — تقویم از همان‌جا خودش پر می‌شود."
        font_family="fa"
        text_size={13.5}
        line_height={1.75}
        text_color={Palette.ink_soft()}
      />
      <Spacer size={18} />
      {Kati.Screens.OnboardingFirstTitleFa.grid(assigns.picked)}
      <Spacer size={20} />
      {OnboardingWelcomeFa.forward("پایان راه‌اندازی", :finish)}
      <Spacer size={16} />
      <Box fill_width={true} on_tap={{self(), :skip}}>
        <Text
          text="رد کن — بعداً اضافه می‌کنم"
          font_family="fa"
          text_size={13}
          font_weight="semibold"
          text_color={Palette.sub()}
          text_align="center"
        />
      </Box>
      <Spacer size={20} />
      {Fa.note("info", "رد کردن این گام به خانه خالی می‌رسد — ۱۵۸ در فارسی، ۱۳۹ در انگلیسی. پوسترها هرگز آینه نمی‌شوند؛ فقط تیک به گوشه پیشرو می‌رود.")}
      {OnboardingWelcomeFa.back_row("بازگشت به اعلان‌ها")}
    </Column>
    """
  end

  @doc false
  def suggestion_list, do: @suggestions

  @doc false
  def grid(picked) do
    [first, second, third, fourth] = @suggestions

    assigns = %{
      row_one: Kati.Screens.OnboardingFirstTitleFa.pair(first, second, picked),
      row_two: Kati.Screens.OnboardingFirstTitleFa.pair(third, fourth, picked)
    }

    ~MOB"""
    <Column fill_width={true}>
      {@row_one}
      <Spacer size={11} />
      {@row_two}
    </Column>
    """
  end

  @doc false
  def pair(left, right, picked) do
    assigns = %{
      left: Kati.Screens.OnboardingFirstTitleFa.tile(left, left == picked),
      right: Kati.Screens.OnboardingFirstTitleFa.tile(right, right == picked)
    }

    ~MOB"""
    <Row fill_width={true} align="top">
      {@left}
      <Spacer size={11} />
      {@right}
    </Row>
    """
  end

  @doc """
  One poster and its title, Persian.

  The frame is `Kati.Screens.OnboardingFirstTitle.tick/1`'s and the numbers are
  163's, because the artwork does not mirror; only the title's face and the
  tap tag are this screen's own.
  """
  @spec tile(String.t(), boolean()) :: map()
  def tile(title, on?) do
    assigns = %{
      title: title,
      on?: on?,
      tap: {self(), Kati.Screens.OnboardingFirstTitleFa.tag(title)}
    }

    ~MOB"""
    <Column weight={1.0} on_tap={@tap}>
      <Box
        fill_width={true}
        aspect_ratio={0.667}
        corner_radius={13}
        background={Palette.placeholder()}
        shadow={Kati.Theme.shadow_card_soft()}
        border_width={if @on?, do: 2.5, else: 0}
        border_color={Palette.ink()}
      >
        {OnboardingFirstTitle.tick(@on?)}
      </Box>
      <Spacer size={9} />
      <Text
        text={@title}
        font_family="fa"
        text_size={12.5}
        font_weight="bold"
        text_color={:on_surface}
        max_lines={1}
      />
    </Column>
    """
  end

  @doc """
  The tap tag for a Persian poster, keyed on position.

  Same reason as `Kati.Screens.OnboardingLoudnessFa.tag/1`: an atom made of
  Persian words is a name no device test can type, and both sweeps address a
  control by its tag.
  """
  @spec tag(String.t()) :: atom()
  def tag(title) do
    index = Enum.find_index(@suggestions, &(&1 == title)) || 0
    String.to_atom("pick_#{index + 1}")
  end

  # Through screen 163's writer rather than one of its own: the two screens are
  # one step in two scripts, and a second copy of the two writes is a second
  # place to forget one of them. The title stored is the Persian one the
  # person chose — `Kati.Media.CachedTitle.title` is what the shelf draws, and
  # a Persian run should not put an English name on a Persian shelf.
  def handle_info({:tap, :finish}, socket) do
    Kati.Screens.OnboardingFirstTitle.shelve(socket.assigns.picked)
    Kati.Onboarding.complete!()
    {:noreply, Mob.Socket.reset_to(socket, Kati.Screens.HomeFa)}
  end

  # Skipping is a real answer, so it lands on the state the app draws for
  # having nothing — and on the Persian one, 158, rather than ending an
  # entirely Persian run on an English page.
  def handle_info({:tap, :skip}, socket) do
    Kati.Onboarding.complete!()
    {:noreply, Mob.Socket.reset_to(socket, Kati.Screens.HomeFaEmpty)}
  end

  def handle_info({:tap, tag}, socket) when tag in [:step_back, :back],
    do: {:noreply, Mob.Socket.pop_screen(socket)}

  def handle_info({:tap, tag}, socket) do
    case Atom.to_string(tag) do
      "pick_" <> index ->
        picked = Enum.at(@suggestions, String.to_integer(index) - 1, hd(@suggestions))
        {:noreply, Mob.Socket.assign(socket, :picked, picked)}

      _other ->
        Fa.dock_tap(tag, :home, socket)
    end
  end

  def handle_info(_message, socket), do: {:noreply, socket}
end
