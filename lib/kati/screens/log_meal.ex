defmodule Kati.Screens.LogMeal do
  @moduledoc """
  A meal eaten, written by hand.

  The meals pages count `Kati.Meals.MealLog` rows: today's hero adds up their
  kcal, Nutrition buckets them by day, and the plan's week counts the ones that
  came off a slot. A reader with a plan had no way to put anything in it —
  the day was always *0 of 0* — so this page is the missing half of the Meals
  section: a title, a figure, and which meal of the day it was.

  It writes `:log_manual`, which is the log for a plate nobody planned and the
  one action that accepts the figures from the caller. `portion_milli` stays at
  its default 1000 — a whole portion — because a manual log has no recipe to
  scale.

  ## No board

  The drawings have no manual log page; screen 43's *Mark eaten* writes against
  a slot the plan already drew. So this is one of the screens the empty-database
  gate knows as undrawn, and it borrows the family's chrome — the back pill, the
  28pt title with its mono line, the Habits composer's card.
  """

  use Kati.Screens.Pushed, back: "Meals"
  use Gettext, backend: Kati.Gettext

  import Mob.Sigil

  alias Kati.Components.MishkaPill
  alias Kati.Theme.Palette

  @slots [
    {"breakfast", "Breakfast", ~T[07:30:00]},
    {"lunch", "Lunch", ~T[13:00:00]},
    {"dinner", "Dinner", ~T[19:30:00]},
    {"snack", "Snack", ~T[16:00:00]}
  ]

  @impl true
  def load(socket) do
    socket
    |> Mob.Socket.assign(:title, "")
    |> Mob.Socket.assign(:kcal, "")
    |> Mob.Socket.assign(:slot, "breakfast")
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
          text={gettext("Log a meal")}
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
            id="meal_title"
            value={assigns.title}
            placeholder={gettext("What did you eat?")}
            caret="end"
            on_change={{self(), :meal_title}}
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
            id="meal_kcal"
            value={assigns.kcal}
            placeholder={gettext("Calories")}
            caret="end"
            keyboard="number"
            on_change={{self(), :meal_kcal}}
            on_submit={{self(), :save_meal}}
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
          <Spacer size={12} />
          <Row fill_width={true} align="center">
            {Enum.map(Kati.Screens.LogMeal.slots(), fn slot -> Kati.Screens.LogMeal.slot_pill(slot, assigns.slot) end)}
          </Row>
          <Spacer size={10} />
          {Kati.Screens.LogMeal.error_line(assigns.save_error)}
          <Row fill_width={true} align="center">
            {Kati.Screens.LogMeal.save_pill()}
            <Spacer size={8} />
            {Kati.Screens.LogMeal.cancel_pill()}
          </Row>
        </MishkaCard>
      </Column>
    </Scroll>
    """
  end

  @doc "The four slots, as `{key, label, time}`."
  # Translated per call, not stored translated: a module attribute holding
  # `gettext/1` freezes in whichever locale the compiler was in, which is the
  # trap `Kati.Screens.RetiredTile.why_for/1` records. The keys stay Latin —
  # `slot_name` is written from the key, so a meal logged in Persian and one
  # logged in English are the same row.
  def slots,
    do:
      Enum.map(@slots, fn {key, label, time} ->
        {key, Gettext.gettext(Kati.Gettext, label), time}
      end)

  @doc false
  def slot_pill({key, label, _time}, selected) do
    chosen? = key == selected

    MishkaPill.pill(
      id: "slot_" <> key,
      label: label,
      background: if(chosen?, do: Palette.ink(), else: Palette.paper()),
      color: if(chosen?, do: Palette.on_ink(), else: :on_surface),
      corner_radius: 14,
      height: 32,
      padding: 0,
      padding_left: 12,
      padding_right: 12,
      text_size: 12,
      font_weight: :semibold,
      align: :center,
      on_tap: {self(), String.to_atom("slot_" <> key)}
    )
  end

  @doc false
  def save_pill do
    MishkaPill.pill(
      id: "meal_save",
      label: gettext("Log it"),
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
      on_tap: {self(), :save_meal}
    )
  end

  @doc false
  def cancel_pill do
    MishkaPill.pill(
      id: "meal_cancel",
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
  def handle_tap(:save_meal, socket), do: {:noreply, save(socket)}

  def handle_tap(tag, socket)
      when tag in [:slot_breakfast, :slot_lunch, :slot_dinner, :slot_snack] do
    {:noreply,
     Mob.Socket.assign(socket, :slot, tag |> Atom.to_string() |> String.replace("slot_", ""))}
  end

  def handle_tap(_tag, socket), do: {:noreply, socket}

  # The keyboard's action key arrives as `{:submit, tag}`, not as a tap — see
  # `Kati.ScreenSubmitSweepTest`. Without this the return key on either field
  # would do nothing while the Save pill beside it worked.
  @impl true
  def handle_info({:submit, :save_meal}, socket), do: {:noreply, save(socket)}

  def handle_info({:change, :meal_title, value}, socket) when is_binary(value),
    do: {:noreply, Mob.Socket.assign(socket, :title, value)}

  def handle_info({:change, :meal_kcal, value}, socket) when is_binary(value),
    do: {:noreply, Mob.Socket.assign(socket, :kcal, value)}

  def handle_info(message, socket), do: super(message, socket)

  @doc """
  Write the row and go back.

  A meal with no name and a meal with no calories are both refused here rather
  than in the resource, because both fields are the reader's to fill and a
  database error is not a sentence anyone should read. The slot's own time is
  stored with it, so the day's timeline can sort it without the plan.
  """
  @spec save(Mob.Socket.t()) :: Mob.Socket.t()
  def save(socket) do
    title = String.trim(socket.assigns.title || "")
    kcal = Integer.parse(socket.assigns.kcal || "")

    {_key, label, time} =
      Enum.find(@slots, fn {key, _, _} -> key == socket.assigns.slot end) ||
        {"breakfast", "Breakfast", ~T[07:30:00]}

    cond do
      title == "" ->
        Mob.Socket.assign(socket, :save_error, gettext("Name the meal."))

      true ->
        case kcal do
          {target, ""} when target > 0 -> create(socket, title, target, time, label)
          _none -> Mob.Socket.assign(socket, :save_error, gettext("Add the calories."))
        end
    end
  end

  defp create(socket, title, kcal, time, slot_name) do
    now = Kati.Time.now()

    attrs = %{
      logged_on: Kati.Time.today(),
      logged_at: now,
      state: :eaten,
      title: title,
      kcal: kcal,
      # The vocabulary every other meals screen stores and reads — `Breakfast`,
      # `Lunch` — and not the lowercase key the field is chosen with. Written in
      # English: it is an enum, not a sentence, and `Kati.Screens.MealEdit.slot_label/1`
      # translates it at the render.
      slot_name: slot_name,
      slot_time: time,
      meal_plan_id: active_plan_id()
    }

    result = Ash.create(Kati.Meals.MealLog, attrs, action: :log_manual)
    Kati.Write.note(result, "meal #{title}")

    case result do
      {:ok, _log} ->
        Kati.Screens.Resume.pop(socket)

      {:error, _error} ->
        Mob.Socket.assign(socket, :save_error, gettext("Kati could not save that meal."))
    end
  rescue
    _error -> Mob.Socket.assign(socket, :save_error, gettext("Kati could not save that meal."))
  end

  defp active_plan_id do
    case Kati.Meals.MealPlan |> Ash.Query.for_read(:active) |> Ash.read_one() do
      {:ok, %{id: id}} -> id
      _none -> nil
    end
  rescue
    _none -> nil
  end
end
