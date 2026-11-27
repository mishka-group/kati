defmodule Kati.Screens.Workouts do
  @moduledoc """
  Workouts: this week's, typed by hand.

  The last of screen 42's four outlines, and `Kati.Screens.Sleep`'s twin: a
  title, a duration, the day, and the week's count under them. The tile's line
  is `N this week` because that is the question the grid asks of a workout
  section — the same way it asks Sleep for last night.
  """

  use Kati.Screens.Pushed, back: "Health"
  use Gettext, backend: Kati.Gettext

  import Mob.Sigil

  alias Kati.Components.MishkaPill
  alias Kati.Theme.Palette

  @impl true
  def load(socket) do
    socket
    |> Mob.Socket.assign(:title, "")
    |> Mob.Socket.assign(:minutes, "")
    |> Mob.Socket.assign(:recent, recent())
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
          text={gettext("Workouts")}
          text_size={28}
          max_font_scale={1.6}
          font_weight="bold"
          text_align="start"
          letter_spacing={Kati.Locale.tracking(-0.03)}
          text_color={:on_surface}
        />
        <Spacer size={5} />
        <Text
          text={Kati.UI.eyebrow_label(Kati.Screens.Workouts.summary(assigns.recent))}
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
            id="workout_title"
            value={assigns.title}
            placeholder={gettext("What did you do?")}
            caret="end"
            on_change={{self(), :workout_title}}
            background={Palette.paper()}
            corner_radius={14}
            padding_left={12}
            padding_right={12}
            padding_top={10}
            padding_bottom={10}
            text_size={14}
            max_length={80}
            fill_width={true}
          />
          <Spacer size={10} />
          <MishkaTextInput
            id="workout_minutes"
            value={assigns.minutes}
            placeholder={gettext("Minutes")}
            caret="end"
            keyboard="number"
            on_change={{self(), :workout_minutes}}
            on_submit={{self(), :save_workout}}
            background={Palette.paper()}
            corner_radius={14}
            padding_left={12}
            padding_right={12}
            padding_top={10}
            padding_bottom={10}
            text_size={14}
            max_length={4}
            fill_width={true}
          />
          <Spacer size={10} />
          {Kati.Screens.Workouts.error_line(assigns.save_error)}
          <Row fill_width={true} align="center">
            {Kati.Screens.Workouts.save_pill()}
          </Row>
        </MishkaCard>
        <Spacer size={18} />
        {Kati.UI.eyebrow(Kati.UI.eyebrow_label(gettext("Recent workouts")))}
        {Kati.Screens.Workouts.recent_rows(assigns.recent)}
      </Column>
    </Scroll>
    """
  end

  @doc "The tile's line: this week's count, or the empty wording the grid uses."
  @spec line() :: String.t()
  def line do
    case count_this_week() do
      0 -> gettext("Not set up")
      n -> gettext("%{count} this week", count: Kati.Locale.number(n))
    end
  end

  @doc false
  def summary(workouts) do
    case Kati.Health.Workout.count_in_week(workouts, monday()) do
      0 -> gettext("Not set up")
      n -> gettext("%{count} this week", count: Kati.Locale.number(n))
    end
  end

  defp count_this_week, do: Kati.Health.Workout.count_in_week(recent_raw(), monday())

  defp monday do
    today = Kati.Time.today()
    Date.add(today, -(Date.day_of_week(today) - 1))
  end

  @doc false
  def recent, do: recent_raw() |> Enum.take(3)

  defp recent_raw do
    Kati.Health.Workout
    |> Ash.Query.for_read(:recent)
    |> Ash.read!()
  rescue
    _error -> []
  end

  @doc false
  def recent_rows([]) do
    assigns = %{line: gettext("No workouts yet.")}

    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={10} />
      <Text text={@line} text_size={13} text_color={Palette.sub()} />
    </Column>
    """
  end

  def recent_rows(workouts) do
    rows =
      Enum.map(workouts, fn workout ->
        assigns = %{
          title: workout.title,
          meta:
            gettext("%{count} min · %{date}",
              count: Kati.Locale.number(workout.minutes),
              date: Kati.Locale.date(workout.done_on, :short)
            )
        }

        ~MOB"""
        <Column fill_width={true}>
          <Text
            text={@title}
            text_size={13.5}
            font_weight="semibold"
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={3} />
          <Text text={@meta} text_size={11.5} text_color={Palette.sub()} max_lines={1} />
        </Column>
        """
      end)

    assigns = %{rows: rows}

    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={10} />
      {Enum.intersperse(@rows, ~MOB"<Spacer size={10} />")}
    </Column>
    """
  end

  @doc false
  def save_pill do
    MishkaPill.pill(
      id: "workout_save",
      label: gettext("Save"),
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
      on_tap: {self(), :save_workout}
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
  def handle_tap(:save_workout, socket), do: {:noreply, save(socket)}
  def handle_tap(_tag, socket), do: {:noreply, socket}

  @impl true
  def handle_info({:submit, :save_workout}, socket), do: {:noreply, save(socket)}

  def handle_info({:change, :workout_title, value}, socket) when is_binary(value),
    do: {:noreply, Mob.Socket.assign(socket, :title, value)}

  def handle_info({:change, :workout_minutes, value}, socket) when is_binary(value),
    do: {:noreply, Mob.Socket.assign(socket, :minutes, value)}

  def handle_info(message, socket), do: super(message, socket)

  @doc "Write the workout and re-read the list."
  @spec save(Mob.Socket.t()) :: Mob.Socket.t()
  def save(socket) do
    title = String.trim(socket.assigns.title || "")

    case Integer.parse(socket.assigns.minutes || "") do
      {minutes, ""} when minutes > 0 and minutes < 1441 and title != "" ->
        attrs = %{title: title, minutes: minutes, done_on: Kati.Time.today()}
        result = Ash.create(Kati.Health.Workout, attrs)
        Kati.Write.note(result, "workout #{title}")

        case result do
          {:ok, _workout} ->
            Kati.Screens.Resume.pop(socket)

          {:error, _error} ->
            Mob.Socket.assign(socket, :save_error, gettext("Kati could not save that workout."))
        end

      _none ->
        Mob.Socket.assign(socket, :save_error, gettext("Name the workout and how long it took."))
    end
  rescue
    _error -> Mob.Socket.assign(socket, :save_error, gettext("Kati could not save that workout."))
  end
end
