defmodule Kati.Screens.Sleep do
  @moduledoc """
  Sleep: last night's hours, and the nights before it.

  Screen 42's Sleep tile was an outline until `Kati.Health.SleepNight` existed.
  This is the page behind it: one number for last night, and the three most
  recent nights under it, so the line on the tile is a fact a reader can check
  rather than a figure Kati made up.

  There is no board for it — the drawings have the outline and no page — so the
  empty-database gate knows it as undrawn and the page borrows its chrome from
  the family: the back pill, the 28pt title with its mono line, and the card
  the Habits composer uses.
  """

  use Kati.Screens.Pushed, back: "Health"
  use Gettext, backend: Kati.Gettext

  import Mob.Sigil

  alias Kati.Components.MishkaPill
  alias Kati.Theme.Palette

  @impl true
  def load(socket) do
    socket
    |> Mob.Socket.assign(:minutes, "")
    |> Mob.Socket.assign(:nights, nights())
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
        padding_top={64}
        padding_bottom={40}
      >
        <Text
          text={gettext("Sleep")}
          text_size={28}
          max_font_scale={1.6}
          font_weight="bold"
          text_align="start"
          letter_spacing={-0.03}
          text_color={:on_surface}
        />
        <Spacer size={5} />
        <Text
          text={Kati.UI.eyebrow_label(Kati.Screens.Sleep.summary(assigns.nights))}
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
            id="sleep_minutes"
            value={assigns.minutes}
            placeholder={gettext("Minutes slept")}
            caret="end"
            keyboard="number"
            on_change={{self(), :sleep_minutes}}
            on_submit={{self(), :save_sleep}}
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
          {Kati.Screens.Sleep.error_line(assigns.save_error)}
          <Row fill_width={true} align="center">
            {Kati.Screens.Sleep.save_pill()}
          </Row>
        </MishkaCard>
        <Spacer size={18} />
        {Kati.UI.eyebrow(Kati.UI.eyebrow_label(gettext("Recent nights")))}
        {Kati.Screens.Sleep.night_rows(assigns.nights)}
      </Column>
    </Scroll>
    """
  end

  @doc "The tile's line: last night, or the empty wording the grid uses."
  @spec line() :: String.t()
  def line do
    case nights() do
      [latest | _] ->
        gettext("%{time} last night", time: Kati.Health.SleepNight.label(latest.minutes))

      [] ->
        gettext("Not set up")
    end
  end

  @doc false
  def summary([]), do: gettext("Not set up")
  def summary([latest | _]), do: Kati.Health.SleepNight.label(latest.minutes)

  @doc false
  def nights do
    Kati.Health.SleepNight
    |> Ash.Query.for_read(:recent)
    |> Ash.read!()
    |> Enum.take(3)
  rescue
    _error -> []
  end

  @doc false
  def night_rows([]) do
    assigns = %{line: gettext("No nights yet.")}

    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={10} />
      <Text text={@line} text_size={13} text_color={Palette.sub()} />
    </Column>
    """
  end

  def night_rows(nights) do
    rows =
      Enum.map(nights, fn night ->
        assigns = %{
          date: Kati.Locale.date(night.night_on, :short),
          time: Kati.Health.SleepNight.label(night.minutes)
        }

        ~MOB"""
        <Row fill_width={true} align="center">
          <Text text={@date} text_size={13} text_color={:on_surface} weight={1.0} />
          <Text
            text={@time}
            font_family={Kati.Locale.mono_face(@time)}
            text_size={12}
            text_color={Palette.sub()}
          />
        </Row>
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
      id: "sleep_save",
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
      on_tap: {self(), :save_sleep}
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
  def handle_tap(:save_sleep, socket), do: {:noreply, save(socket)}
  def handle_tap(_tag, socket), do: {:noreply, socket}

  @impl true
  def handle_info({:submit, :save_sleep}, socket), do: {:noreply, save(socket)}

  def handle_info({:change, :sleep_minutes, value}, socket) when is_binary(value),
    do: {:noreply, Mob.Socket.assign(socket, :minutes, value)}

  def handle_info(message, socket), do: super(message, socket)

  @doc """
  Write the night and re-read the list.

  The night is dated today: *last night* ended this morning, and a page that
  asked for a date before it accepted a figure would be a form where the one
  obvious answer has to be typed.
  """
  @spec save(Mob.Socket.t()) :: Mob.Socket.t()
  def save(socket) do
    case Integer.parse(socket.assigns.minutes || "") do
      {minutes, ""} when minutes > 0 and minutes < 1441 ->
        attrs = %{minutes: minutes, night_on: Kati.Time.today()}
        result = Ash.create(Kati.Health.SleepNight, attrs)
        Kati.Write.note(result, "sleep #{minutes}")

        case result do
          {:ok, _night} ->
            # Back to Health: the tile's line is where the night belongs, and the
            # field does not take a new value while it holds text of its own.
            Kati.Screens.Resume.pop(socket)

          {:error, _error} ->
            Mob.Socket.assign(socket, :save_error, gettext("Kati could not save that night."))
        end

      _none ->
        Mob.Socket.assign(socket, :save_error, gettext("Type the minutes you slept."))
    end
  rescue
    _error -> Mob.Socket.assign(socket, :save_error, gettext("Kati could not save that night."))
  end
end
