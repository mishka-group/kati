defmodule Kati.Screens.Weight do
  @moduledoc """
  Screen 109 — Weight, pushed under Health.

  ## Bars, not a line

  The design's caption settles it and the reason is a claim about the data:
  *weight is a series of discrete readings, and a line implies measurements
  between them that do not exist.* You did not weigh 76.2 on the Tuesday you
  did not stand on the scale, and a line drawn through two points says you did.

  ## The list reads as change, not as absolutes

  Every row carries its delta from the reading before it, and the entry point
  is a header disc rather than a row at the foot. Both are the caption's, and
  together they make the page about *movement* — which is the only thing a
  weight log is for.

  ## Nothing is connected

  The `info` row says so: *Kati stores the readings you type and nothing else —
  no scale is connected, and nothing here leaves the device.* `Kati.Health` has
  no integration point and no `source` column waiting to be filled in, so that
  sentence is a description rather than a promise.
  """

  use Kati.Screens.Pushed, back: "Health"

  alias Kati.Health
  alias Kati.Health.Reading
  alias Kati.Health.WeightSample
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  @ranges [{"Week", :range_week}, {"Month", :range_month}, {"All", :range_all}]

  def load(socket) do
    socket
    |> Mob.Socket.assign(:entries, entries())
    |> Mob.Socket.assign(:latest, latest())
    |> Mob.Socket.assign(:range, :range_month)
  end

  @doc "The readings: what is stored, or the drawing's four."
  @spec entries() :: [map()]
  def entries do
    case stored() do
      [] ->
        WeightSample.entries()

      readings ->
        unit = Health.unit()

        readings
        |> Enum.zip(Enum.drop(readings, 1) ++ [nil])
        |> Enum.map(fn {reading, previous} ->
          %{
            date: String.upcase(Calendar.strftime(reading.taken_on, "%d %b")),
            weight: Reading.display(reading.grams, unit),
            delta: Reading.delta_label(Reading.delta(reading, previous), unit),
            grams: reading.grams
          }
        end)
    end
  end

  @doc "The drawing's four, unconditionally."
  @spec drawn_entries() :: [map()]
  def drawn_entries, do: WeightSample.entries()

  @doc "The hero: the latest reading and how far it is from the first."
  @spec latest() :: map()
  def latest do
    case stored() do
      [] ->
        WeightSample.latest()

      readings ->
        unit = Health.unit()
        newest = hd(readings)
        oldest = List.last(readings)
        change = newest.grams - oldest.grams

        %{
          label: "Latest · " <> Kati.Screens.Weight.when_label(newest.taken_on),
          figure: Reading.figure(newest.grams, unit),
          unit: Reading.unit_label(unit),
          direction: if(change <= 0, do: :down, else: :up),
          change: Reading.display(abs(change), unit),
          # The figure without its unit, which is the drawing's own line:
          # `DOWN FROM 78.4 ON 4 MAY`. The unit is already on the hero above
          # it, and repeating it inside a mono caption reads as a second
          # measurement rather than the same one.
          since:
            String.upcase(
              "#{if change <= 0, do: "down", else: "up"} from " <>
                "#{Reading.figure(oldest.grams, unit)} on " <>
                Calendar.strftime(oldest.taken_on, "%-d %b")
            )
        }
    end
  end

  @doc "`today`, `yesterday`, or a date — the same ladder screen 74 uses."
  @spec when_label(Date.t()) :: String.t()
  def when_label(%Date{} = on) do
    case Date.diff(Kati.Time.today(), on) do
      0 -> "today"
      1 -> "yesterday"
      _older -> Calendar.strftime(on, "%-d %b")
    end
  end

  defp stored do
    Reading
    |> Ash.Query.for_read(:recent)
    |> Ash.read()
    |> case do
      {:ok, readings} -> readings
      _other -> []
    end
  rescue
    _error -> []
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
        {Kati.Screens.Goals.chrome()}
        {SettingsList.title("Weight", nil)}
        {Kati.Screens.Weight.hero(assigns.latest)}
        {Kati.UI.Segmented.plain(Kati.Screens.Weight.ranges(), assigns.range)}
        <Spacer size={16} />
        {Kati.Screens.Weight.chart()}
        {UI.eyebrow("Entries")}
        {Kati.Screens.Weight.entry_list(assigns.entries)}
        {Kati.Screens.Weight.privacy_note()}
      </Column>
    </Scroll>
    """
  end

  @doc false
  def ranges, do: @ranges

  @doc """
  The hero: the figure, its unit beside it, and the arc since the first reading.

  The unit sits on the baseline of the numeral rather than under it, which is
  screen 111's rule as well — *the unit sits inside the numeral rather than as
  a separate label, so the hero reads as one value*.
  """
  @spec hero(map()) :: map()
  def hero(latest) do
    icon = if latest.direction == :down, do: "arrow_drop_down", else: "arrow_drop_up"
    colour = if latest.direction == :down, do: Palette.green_text(), else: Palette.gold_text()
    assigns = %{latest: latest, icon: icon, colour: colour}

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        padding={19}
        shadow={Kati.Theme.shadow_card()}
      >
        <Text
          text={String.upcase(@latest.label)}
          font_family="mono"
          text_size={10}
          letter_spacing={0.14}
          text_color={Palette.muted()}
        />
        <Spacer size={9} />
        <Row fill_width={true} align="bottom">
          <Text
            text={@latest.figure}
            text_size={38}
            font_weight="extrabold"
            letter_spacing={-0.035}
            text_color={:on_surface}
          />
          <Spacer size={6} />
          <Text text={@latest.unit} text_size={16} text_color={Palette.muted()} />
          <Spacer weight={1.0} />
        </Row>
        <Spacer size={11} />
        <Row fill_width={true} align="center">
          {Kati.UI.symbol(@icon, size: 20, color: @colour)}
          <Text
            text={@latest.change}
            font_family="mono"
            text_size={13}
            text_color={@colour}
            max_lines={1}
          />
          <Spacer size={10} />
          <Text
            text={@latest.since}
            font_family="mono"
            text_size={10}
            letter_spacing={0.1}
            text_color={Palette.muted()}
            max_lines={1}
          />
        </Row>
      </Column>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc """
  The chart: one bar per reading, and nothing between them.

  See the moduledoc for why this is not a line. Each bar is a `Column` with a
  weight, so fourteen readings and forty both fill the card — a fixed bar width
  would clip the second.
  """
  @spec chart() :: map()
  def chart do
    bars = Kati.Screens.Weight.bars()
    {left, right} = WeightSample.axis()

    assigns = %{
      bars:
        bars
        |> Enum.map(&Kati.Screens.Weight.bar/1)
        |> Enum.intersperse(~MOB"<Spacer size={3} />"),
      left: left,
      right: right
    }

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={20}
        padding={17}
        shadow={Kati.Theme.shadow_card()}
      >
        <Row fill_width={true} height={96} align="bottom">
          {@bars}
        </Row>
        <Spacer size={10} />
        <Row fill_width={true} align="center">
          <Text
            text={@left}
            font_family="mono"
            text_size={9.5}
            letter_spacing={0.12}
            text_color={Palette.muted()}
          />
          <Spacer weight={1.0} />
          <Text
            text={@right}
            font_family="mono"
            text_size={9.5}
            letter_spacing={0.12}
            text_color={Palette.muted()}
          />
        </Row>
      </Column>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  The bar heights, oldest first, normalised against the series' own range.

  Against the range rather than against zero: every reading in a weight series
  is a large number close to every other, so a zero-based axis draws fourteen
  bars of identical height and says nothing.
  """
  @spec bars() :: [float()]
  def bars do
    case stored() do
      [] ->
        WeightSample.bars()

      readings ->
        grams = readings |> Enum.map(& &1.grams) |> Enum.reverse()
        low = Enum.min(grams)
        high = Enum.max(grams)
        span = max(high - low, 1)

        Enum.map(grams, fn g -> 0.35 + (g - low) / span * 0.65 end)
    end
  end

  @doc false
  def bar(fraction) do
    assigns = %{height: max(round(fraction * 96), 4)}

    ~MOB"""
    <Column weight={1.0} align="bottom">
      <Box fill_width={true} height={@height} corner_radius={2} background={Palette.bar_ink()} />
    </Column>
    """
  end

  @doc "One row per reading, each carrying its change from the one before."
  @spec entry_list([map()]) :: map()
  def entry_list(entries) do
    rows = Enum.map(entries, &Kati.Screens.Weight.entry_row/1)

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.card(rows)}
      <Spacer size={12} />
    </Column>
    """
  end

  @doc false
  def entry_row(entry) do
    SettingsList.row(
      ~MOB"""
      <Text
        text={entry.date}
        font_family="mono"
        text_size={10.5}
        letter_spacing={0.12}
        text_color={Kati.Theme.Palette.muted()}
        width={58}
      />
      """,
      ~MOB"""
      <Text
        text={entry.weight}
        font_family="mono"
        text_size={13}
        text_color={:on_surface}
        max_lines={1}
      />
      """,
      SettingsList.trailing(Kati.Screens.Weight.delta(entry.delta))
    )
  end

  @doc "The trailing delta, coloured by direction, or nothing for a first reading."
  @spec delta(String.t() | nil) :: map() | nil
  def delta(nil), do: nil

  def delta(label) do
    colour =
      if String.starts_with?(label, "−"), do: Palette.green_text(), else: Palette.gold_text()

    assigns = %{label: label, colour: colour}

    ~MOB"""
    <Text text={@label} font_family="mono" text_size={12} text_color={@colour} max_lines={1} />
    """
  end

  @doc "The sentence that says nothing here goes anywhere."
  @spec privacy_note() :: map()
  def privacy_note do
    SettingsList.note(
      "info",
      "Kati stores the readings you type and nothing else — no scale is connected, " <>
        "and nothing here leaves the device."
    )
  end

  @doc false
  def handle_tap(:add, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.LogWeight)}

  def handle_tap(range, socket) when range in [:range_week, :range_month, :range_all],
    do: {:noreply, Mob.Socket.assign(socket, :range, range)}

  def handle_tap(_tag, socket), do: {:noreply, socket}
end
