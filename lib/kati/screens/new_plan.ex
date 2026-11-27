defmodule Kati.Screens.NewPlan do
  @moduledoc """
  Start a meal plan by hand.

  Until this screen there was no way for a reader to own a plan: every meals
  page reads one, `Kati.Screens.PlanImport` draws a shared plan and writes
  nothing, and the four screens behind the Meals tile therefore drew the
  import card on every phone forever. A plan is three numbers — a name, a
  target, a start day — and this is the page that writes them.

  It is not the design's: the drawings have a plan importer and no creator, so
  there is no board to compare against and `Kati.ScreenEmptyDatabaseTest` knows
  it as undrawn. What it borrows is the family's own chrome: the same back
  pill, the same 28pt title with its mono line, and the same card the Habits
  composer uses, so a page that arrived late does not look like one that
  arrived from elsewhere.

  ## Only what a plan needs to be useful

  `name` and `target_kcal` are the two a meals screen reads; `starts_on` is
  today, because a plan that starts in the future would leave today blank
  again. Everything else on `Kati.Meals.MealPlan` has a default — status
  `:active`, reminders on, tolerance — and the plan page (49) is where those
  are changed, not here.
  """

  use Kati.Screens.Pushed, back: "Meals"
  use Gettext, backend: Kati.Gettext

  import Mob.Sigil

  alias Kati.Components.MishkaPill
  alias Kati.Theme.Palette

  @impl true
  def load(socket) do
    socket
    |> Mob.Socket.assign(:name, "")
    |> Mob.Socket.assign(:kcal, "")
    |> Mob.Socket.assign(:save_error, nil)
  end

  @doc false
  def content(assigns) do
    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={Kati.Screens.Pushed.content_top()}
        padding_bottom={40}
      >
        <Text
          text={gettext("Start a plan")}
          text_size={28}
          max_font_scale={1.6}
          font_weight="bold"
          letter_spacing={Kati.Locale.tracking(-0.03)}
          text_align="start"
          text_color={:on_surface}
        />
        <Spacer size={5} />
        <Text
          text={Kati.UI.eyebrow_label(gettext("Meals"))}
          font_family={Kati.Locale.mono_face()}
          text_size={11}
          text_color={Palette.muted()}
          max_lines={1}
        />
        <Spacer size={18} />
        <MishkaCard
          background={Palette.card()}
          corner_radius={20}
          shadow={Kati.Theme.shadow_card_soft()}
          padding={15}
        >
          <MishkaTextInput
            id="plan_name"
            value={assigns.name}
            placeholder={gettext("Plan name")}
            caret="end"
            on_change={{self(), :plan_name}}
            background={Palette.paper()}
            corner_radius={14}
            padding_left={12}
            padding_right={12}
            padding_top={10}
            padding_bottom={10}
            text_size={14}
            max_length={60}
            fill_width={true}
          />
          <Spacer size={10} />
          <MishkaTextInput
            id="plan_kcal"
            value={assigns.kcal}
            placeholder={gettext("Daily target, kcal")}
            caret="end"
            keyboard="number"
            on_change={{self(), :plan_kcal}}
            on_submit={{self(), :save_plan}}
            background={Palette.paper()}
            corner_radius={14}
            padding_left={12}
            padding_right={12}
            padding_top={10}
            padding_bottom={10}
            text_size={14}
            max_length={5}
            fill_width={true}
          />
          <Spacer size={10} />
          {Kati.Screens.NewPlan.error_line(assigns.save_error)}
          <Row fill_width={true} align="center">
            {Kati.Screens.NewPlan.save_pill()}
            <Spacer size={8} />
            {Kati.Screens.NewPlan.cancel_pill()}
          </Row>
        </MishkaCard>
        <Spacer size={11} />
        <Text
          text={gettext("Kati counts meals against this plan. Import a plan instead if you already have one.")}
          text_size={12}
          line_height={Kati.Locale.leading(1.5)}
          text_color={Palette.sub()}
        />
      </Column>
    </Scroll>
    """
  end

  @doc false
  def save_pill do
    MishkaPill.pill(
      id: "plan_save",
      label: gettext("Start"),
      background: Palette.green(),
      color: 0xFFFBFAF8,
      corner_radius: 15,
      height: 34,
      padding: 0,
      padding_left: 16,
      padding_right: 16,
      text_size: 12.5,
      font_weight: :semibold,
      align: :center,
      on_tap: {self(), :save_plan}
    )
  end

  @doc false
  def cancel_pill do
    MishkaPill.pill(
      id: "plan_cancel",
      label: gettext("Cancel"),
      background: Palette.paper(),
      color: :on_surface,
      corner_radius: 15,
      height: 34,
      padding: 0,
      padding_left: 14,
      padding_right: 14,
      text_size: 12.5,
      align: :center,
      on_tap: {self(), :back}
    )
  end

  @doc false
  def error_line(nil), do: ~MOB"<Spacer size={0} />"

  def error_line(message) do
    assigns = %{message: message}

    ~MOB"""
    <Column fill_width={true}>
      <Text text={@message} text_size={12} text_color={:error} max_lines={2} />
      <Spacer size={8} />
    </Column>
    """
  end

  @impl true
  def handle_tap(:save_plan, socket), do: {:noreply, save(socket)}
  def handle_tap(_tag, socket), do: {:noreply, socket}

  # The keyboard's action key arrives as `{:submit, tag}`, not as a tap — see
  # `Kati.ScreenSubmitSweepTest`. Without this the return key on either field
  # would do nothing while the Save pill beside it worked.
  @impl true
  def handle_info({:submit, :save_plan}, socket), do: {:noreply, save(socket)}

  def handle_info({:change, :plan_name, value}, socket) when is_binary(value),
    do: {:noreply, Mob.Socket.assign(socket, :name, value)}

  def handle_info({:change, :plan_kcal, value}, socket) when is_binary(value),
    do: {:noreply, Mob.Socket.assign(socket, :kcal, value)}

  def handle_info(message, socket), do: super(message, socket)

  @doc """
  Write the plan and go back to the meals page, which re-mounts on the way.

  Two refusals, and both are the reader's to fix rather than the database's: a
  plan with no name cannot be found on page 49, and a target of zero makes the
  hero divide by nothing. Everything else has a default.
  """
  @spec save(Mob.Socket.t()) :: Mob.Socket.t()
  def save(socket) do
    name = String.trim(socket.assigns.name || "")
    kcal = Integer.parse(socket.assigns.kcal || "")

    cond do
      name == "" ->
        Mob.Socket.assign(socket, :save_error, gettext("Give the plan a name."))

      true ->
        case kcal do
          {target, ""} when target > 0 ->
            create(socket, name, target)

          _none ->
            Mob.Socket.assign(socket, :save_error, gettext("Set a daily target above zero."))
        end
    end
  end

  defp create(socket, name, target) do
    attrs = %{
      name: name,
      status: :active,
      origin: :user,
      starts_on: Kati.Time.today(),
      target_kcal: target
    }

    result = Ash.create(Kati.Meals.MealPlan, attrs)
    Kati.Write.note(result, "meal plan #{name}")

    case result do
      {:ok, _plan} ->
        Kati.Screens.Resume.pop(socket)

      {:error, _error} ->
        Mob.Socket.assign(socket, :save_error, gettext("Kati could not save that plan."))
    end
  rescue
    _error -> Mob.Socket.assign(socket, :save_error, gettext("Kati could not save that plan."))
  end
end
