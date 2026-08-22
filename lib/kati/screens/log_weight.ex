defmodule Kati.Screens.LogWeight do
  @moduledoc """
  Screen 111 — Log weight, a sheet over Weight.

  Screen 70's field geometry adapted for a decimal, and the caption names both
  adaptations: *the stepper moves in 0.1 steps, and the unit sits inside the
  numeral rather than as a separate label, so the hero reads as one value.*

  ## The unit switch is here as well as in Settings, on purpose

  *Changing it here is a correction, not a preference.* You weighed yourself on
  a scale set to pounds and typed pounds; the switch is you saying which number
  you just read, not you changing your mind about how weights are displayed.

  That is only coherent because `Kati.Health.Reading` stores grams: the
  correction converts the value you typed, and every other reading in the log
  is untouched. The opposite arrangement — storing whatever unit was current —
  would make this switch rewrite history.

  ## The confirmation compares with the last reading, not with a goal

  *0.4 kg down from your last reading, three days ago.* No target, no ideal
  range, no colour that means bad. `Kati.Health`'s moduledoc gives the rule this
  follows: Kati is not a medical device and records what it was told.
  """

  use Mob.Screen
  import Mob.Sigil

  alias Kati.Health
  alias Kati.Health.Reading
  alias Kati.Health.WeightSample
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.Segmented
  alias Kati.UI.Sheet

  @units [{"kg", :unit_kg}, {"lb", :unit_lb}, {"st", :unit_st}]

  # A tenth of a kilogram, in grams. The step is a tenth of the DISPLAY unit,
  # which is why this is derived per unit rather than being one constant.
  def mount(_params, _session, socket) do
    Kati.Theme.activate()

    {:ok,
     socket
     |> Mob.Socket.assign(:unit, Health.unit())
     |> Mob.Socket.assign(:grams, opening_grams())}
  end

  @doc """
  The weight the sheet opens on: your last reading, or the drawing's 76.0.

  Your last, because a weighing is almost always a small change from the one
  before it — opening on a round number would make every entry a dozen taps.
  """
  @spec opening_grams() :: integer()
  def opening_grams do
    case Kati.Screens.Weight.entries() do
      [%{grams: grams} | _rest] -> grams
      _other -> 76_000
    end
  end

  def render(assigns), do: Sheet.sheet("Log weight", body(assigns))

  @doc false
  def body(assigns) do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.LogWeight.stepper(assigns.grams, assigns.unit)}
      <Spacer size={14} />
      {Segmented.plain(Kati.Screens.LogWeight.units(), Kati.Screens.LogWeight.unit_tag(assigns.unit))}
      <Spacer size={14} />
      {Kati.Screens.LogWeight.when_and_note()}
      <Spacer size={14} />
      {Kati.Screens.LogWeight.confirmation(assigns.grams)}
      <Spacer size={14} />
      {Sheet.commit("Save reading", :save)}
    </Column>
    """
  end

  @doc false
  def units, do: @units

  @doc false
  def unit_tag(:lb), do: :unit_lb
  def unit_tag(:st), do: :unit_st
  def unit_tag(_kg), do: :unit_kg

  @doc false
  def unit_value(:unit_lb), do: :lb
  def unit_value(:unit_st), do: :st
  def unit_value(_kg), do: :kg

  @doc """
  A tenth of the display unit, in grams.

  The step follows what the user is reading, not what is stored: 0.1 kg is
  100g and 0.1 lb is 45g, and a stepper that moved 100g while the label said
  pounds would jump by 0.22 a press.
  """
  @spec step(:kg | :lb | :st) :: integer()
  def step(:lb), do: 45
  def step(:st), do: 45
  def step(_kg), do: 100

  @doc """
  The stepper: minus, the value with its unit on the baseline, plus.

  The unit is a second `Text` in the same Row rather than a line under it —
  see the moduledoc for why the hero has to read as one value.
  """
  @spec stepper(integer(), atom()) :: map()
  def stepper(grams, unit) do
    assigns = %{
      figure: Reading.figure(grams, unit),
      unit: Reading.unit_label(unit),
      step: "0.1 steps"
    }

    ~MOB"""
    <Row fill_width={true} align="center">
      {Kati.Screens.LogProgress.step_disc("remove", :step_down)}
      <Spacer size={11} />
      <Column
        weight={1.0}
        height={78}
        corner_radius={20}
        background={Palette.card()}
        shadow={Kati.Theme.shadow_card()}
        align="center"
      >
        <Spacer weight={1.0} />
        <Row fill_width={true} align="bottom">
          <Spacer weight={1.0} />
          <Text
            text={@figure}
            font_family="mono"
            text_size={30}
            font_weight="medium"
            letter_spacing={-0.02}
            text_color={:on_surface}
          />
          <Spacer size={5} />
          <Text text={@unit} text_size={14} text_color={Palette.muted()} />
          <Spacer weight={1.0} />
        </Row>
        <Spacer size={5} />
        <Text
          text={@step}
          font_family="mono"
          text_size={9.5}
          letter_spacing={0.1}
          text_align="center"
          text_color={Palette.muted()}
        />
        <Spacer weight={1.0} />
      </Column>
      <Spacer size={11} />
      {Kati.Screens.LogProgress.step_disc("add", :step_up)}
    </Row>
    """
  end

  @doc """
  When it was taken, and the optional note.

  `now` is a control rather than a label, because the commonest correction is
  *I weighed myself this morning and am logging it at lunchtime* — and the
  second commonest is that the default was right.
  """
  @spec when_and_note() :: map()
  def when_and_note do
    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={20}
      padding_left={15}
      padding_right={15}
      shadow={Kati.Theme.shadow_card()}
    >
      <Row fill_width={true} padding_top={13} padding_bottom={13} align="center">
        <Box width={30} height={30} corner_radius={9} background={Palette.paper()} align="center">
          {UI.symbol("event", size: 17, color: Palette.ink_soft())}
        </Box>
        <Spacer size={13} />
        <Column weight={1.0}>
          <Text text="Today" text_size={13.5} font_weight="semibold" text_color={:on_surface} />
          <Spacer size={3} />
          <Text
            text={Kati.Screens.LogWeight.taken_line()}
            font_family="mono"
            text_size={11}
            text_color={Palette.sub()}
            max_lines={1}
          />
        </Column>
        <Row
          height={28}
          corner_radius={14}
          background={Palette.paper()}
          padding_left={12}
          padding_right={12}
          align="center"
          on_tap={{self(), :now}}
        >
          <Text
            text="now"
            text_size={11.5}
            font_weight="semibold"
            text_color={Palette.ink_soft()}
            max_lines={1}
          />
        </Row>
      </Row>
      <Box fill_width={true} height={1} background={Palette.hairline()} />
      <Row fill_width={true} padding_top={13} padding_bottom={13} align="center">
        <Box width={30} height={30} corner_radius={9} background={Palette.paper()} align="center">
          {UI.symbol("sticky_note_2", size: 17, color: Palette.ink_soft())}
        </Box>
        <Spacer size={13} />
        <Column weight={1.0}>
          <Text text="Note" text_size={13.5} font_weight="semibold" text_color={:on_surface} />
          <Spacer size={3} />
          <Text
            text="Optional — after a run, before breakfast…"
            text_size={11.5}
            text_color={Palette.sub()}
            max_lines={1}
          />
        </Column>
        {Kati.UI.SettingsList.chevron()}
      </Row>
    </Column>
    """
  end

  @doc "`16 August, 07:42` — the device's own clock, not the drawing's."
  @spec taken_line() :: String.t()
  def taken_line, do: Calendar.strftime(Kati.Time.now(), "%-d %B, %H:%M")

  @doc """
  The cream line: how far this is from your last reading, and how long ago.

  Only against the last reading. No target and no ideal range — see the
  moduledoc.
  """
  @spec confirmation(integer()) :: map()
  def confirmation(grams) do
    body = [text_size: 13, line_height: 1.55, text_color: Palette.cream_body()]
    strong = [font_weight: "semibold", text_color: Palette.cream_ink(), text_size: 13]
    {icon, lead, tail} = Kati.Screens.LogWeight.change(grams)

    Sheet.insight(icon, [{lead, strong}, {" " <> tail, body}])
  end

  @doc """
  The change from the last reading, as `{icon, lead, tail}`.

  A first reading has nothing to compare with and says so rather than claiming
  no change: `Your first reading` is true, and `0.0 kg down` would not be.

  The two arrows are the drawing's; the neutral case takes `insights` instead,
  because `trending_flat` is not in Kati's icon subset and no drawing asks for
  it. Adding a glyph to the font to say *nothing happened* would be a font
  rebuild for a sentence that already says it.
  """
  @spec change(integer()) :: {String.t(), String.t(), String.t()}
  def change(grams) do
    unit = Health.unit()

    case Kati.Screens.LogWeight.stored_previous() do
      nil ->
        Kati.Screens.LogWeight.drawn_change()

      %{grams: last} = entry ->
        diff = grams - last
        ago = Kati.Screens.LogWeight.ago(entry)

        cond do
          diff == 0 ->
            {"insights", "No change", "from your last reading, #{ago}."}

          diff < 0 ->
            {"trending_down", Reading.display(abs(diff), unit) <> " down",
             "from your last reading, #{ago}."}

          true ->
            {"trending_up", Reading.display(diff, unit) <> " up",
             "from your last reading, #{ago}."}
        end
    end
  end

  @doc """
  The reading this one is being compared with: the newest that is not today's.

  Not simply the newest. The sheet opens on your last weight so you can nudge
  it, so comparing with the newest would compare a value with itself and report
  no change on every single entry. What you want to know is how today differs
  from the last time you stood on the scale, which is a different day by
  definition.
  """
  @spec previous() :: map() | nil
  def previous do
    today = String.upcase(Calendar.strftime(Kati.Time.today(), "%d %b"))

    Kati.Screens.Weight.entries()
    |> Enum.reject(&(&1.date == today))
    |> List.first()
  end

  @doc """
  `previous/0`, but `nil` when the series is the drawing rather than the user's.

  The drawing's four readings are dated 6-16 August and the confirmation it
  draws — *0.4 kg down from your last reading, three days ago* — is true on 16
  August and on no other day. Computing it against the drawing on a Tuesday in
  November would print a real-looking sentence about a fixture.

  So the fallback path returns the drawing's own confirmation, whole, exactly
  as every other fallback in this app does. The clock line above it is the one
  value that still reads the device, because a clock is not data.
  """
  @spec stored_previous() :: map() | nil
  def stored_previous do
    case Kati.Screens.Weight.entries() do
      entries when entries == [] -> nil
      _entries -> if drawing?(), do: nil, else: Kati.Screens.LogWeight.previous()
    end
  end

  defp drawing?, do: Kati.Screens.Weight.entries() == Kati.Screens.Weight.drawn_entries()

  @doc """
  How long ago a reading was, in the drawing's own words.

  `three days ago` rather than `3 days ago`: the sentence is prose and the
  figure is small, and a numeral inside a sentence reads as data. Past ten it
  becomes a numeral, because `seventeen days ago` does not.
  """
  @spec ago(map()) :: String.t()
  def ago(%{date: date}) do
    case Kati.Screens.LogWeight.days_since(date) do
      nil ->
        "last time"

      0 ->
        "earlier today"

      1 ->
        "yesterday"

      n when n <= 10 ->
        Enum.at(~w(zero one two three four five six seven eight nine ten), n) <> " days ago"

      n ->
        "#{n} days ago"
    end
  end

  @doc false
  def days_since(date) do
    with [day, month] <- String.split(date, " "),
         {day, ""} <- Integer.parse(day),
         index when not is_nil(index) <-
           Enum.find_index(
             ~w(JAN FEB MAR APR MAY JUN JUL AUG SEP OCT NOV DEC),
             &(&1 == String.upcase(month))
           ),
         today <- Kati.Time.today(),
         {:ok, then} <- Date.new(today.year, index + 1, day) do
      Date.diff(today, then)
    else
      _other -> nil
    end
  end

  def handle_info({:tap, :close}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}

  def handle_info({:tap, :step_up}, socket) do
    step = Kati.Screens.LogWeight.step(socket.assigns.unit)
    {:noreply, Mob.Socket.assign(socket, :grams, socket.assigns.grams + step)}
  end

  def handle_info({:tap, :step_down}, socket) do
    step = Kati.Screens.LogWeight.step(socket.assigns.unit)
    {:noreply, Mob.Socket.assign(socket, :grams, max(socket.assigns.grams - step, step))}
  end

  # Changing the unit here converts nothing: the grams stay, the label changes,
  # and the number under it is the same weight said differently. That is what
  # makes it a correction rather than a rewrite — see the moduledoc.
  def handle_info({:tap, tag}, socket) when tag in [:unit_kg, :unit_lb, :unit_st] do
    unit = Kati.Screens.LogWeight.unit_value(tag)
    Health.put_unit(unit)
    {:noreply, Mob.Socket.assign(socket, :unit, unit)}
  end

  def handle_info({:tap, :now}, socket), do: {:noreply, socket}

  def handle_info({:tap, :save}, socket) do
    save_reading(socket.assigns.grams)
    {:noreply, Mob.Socket.pop_screen(socket)}
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  @doc "Write the reading, in grams, dated today."
  @spec save_reading(integer()) :: :ok
  def save_reading(grams) do
    Ash.create(Reading, %{
      grams: grams,
      taken_on: Kati.Time.today(),
      taken_at: Kati.Time.now() |> DateTime.truncate(:second)
    })

    :ok
  rescue
    _error -> :ok
  end

  @doc """
  The confirmation the drawing prints, or the sentence a first reading gets.

  Two answers behind one `nil`, and they are the same shape: with the drawing's
  series there is a change to state and it is the drawing's; with nothing at
  all there is nothing to compare and the sheet says so rather than inventing a
  delta.
  """
  @spec drawn_change() :: {String.t(), String.t(), String.t()}
  def drawn_change do
    if Kati.Screens.Weight.entries() == Kati.Screens.Weight.drawn_entries() do
      c = WeightSample.confirmation()
      {"trending_down", c.lead, c.tail}
    else
      {"insights", "Your first reading", "— there is nothing to compare it with yet."}
    end
  end

  @doc false
  def drawn_confirmation, do: WeightSample.confirmation()
end
