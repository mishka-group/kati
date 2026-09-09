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

  # How far back each segment reaches, in days. Read off the segment's own label
  # rather than invented — `Week` is seven days and `Month` is thirty — and
  # `nil` for the one that reaches all the way back.
  #
  # Keyed by `@ranges`' tags, so a fourth segment added above without a window
  # here falls through `within?/2`'s `nil` and takes everything, which is the
  # segment behaving as `All` rather than as an empty chart.
  @windows %{range_week: 7, range_month: 30, range_all: nil}

  # The segment the page opens on, in one place, because the list is read for it
  # and the chip is lit for it and those two must not be able to disagree.
  # `Month` is the drawing's lit chip — `test/design/screens/109.html` — so this
  # is the design's own choice rather than a default.
  @opening :range_month

  def load(socket) do
    socket
    |> Mob.Socket.assign(:entries, entries(@opening))
    |> Mob.Socket.assign(:latest, latest())
    |> Mob.Socket.assign(:range, @opening)
  end

  @doc "The readings: what is stored, or the drawing's four."
  @spec entries() :: [map()]
  def entries, do: entries(:range_all)

  @doc """
  The same, narrowed to one segment of the range row.

  `:range_all` is the identity and `entries/0` is defined as that call, so the
  callers with no range on hand — `Kati.Screens.LogWeight` five times over,
  `Kati.Screens.WeightStates` and `Kati.Screens.HealthFa` — keep the whole
  series they have always read.

  ## The window is measured, the drawing is not

  Narrowing applies to stored readings only. The drawing's four carry
  `date: "16 AUG"` as a string rather than a `Date`, and there is nothing else
  on the sample path a window could be measured against. So a fresh install
  lists the same four rows under every segment, which is the state the design
  was captured in: a series of four readings has no month to narrow to, and it
  narrows once there is something to narrow.

  ## The delta belongs to the series, not to the window

  The zip happens before the filter, so the oldest row inside a week still
  compares itself with the reading before it rather than reporting `nil`.
  Narrowing the view must not change what a row *means* — `Kati.Health.Reading`
  settles that: there is one row per weighing, and a delta is the step from the
  weighing before it.
  """
  @spec entries(atom()) :: [map()]
  def entries(range) do
    case stored() do
      [] ->
        WeightSample.entries()

      readings ->
        unit = Health.unit()

        readings
        |> Enum.zip(Enum.drop(readings, 1) ++ [nil])
        |> Enum.filter(fn {reading, _previous} -> within?(reading, range) end)
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

  # Whether one stored reading falls inside a segment's window, measured back
  # from today. `:range_all` — and any tag that is not a range at all — takes
  # everything, which is what keeps `entries/0` and `bars/0` the whole series
  # for the callers outside this screen that have no range in hand.
  #
  # Only a `Kati.Health.Reading` can be asked this. The drawing's four carry
  # their dates as strings and `Kati.Health.WeightSample.bars/0` carries no
  # dates at all, so there is nothing on the sample path to measure a window
  # against — see `entries/1`.
  defp within?(reading, range) do
    case Map.get(@windows, range) do
      nil -> true
      days -> Date.diff(Kati.Time.today(), reading.taken_on) < days
    end
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
        {Kati.Screens.Weight.chart(assigns.range)}
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
    icon = if latest.direction == :down, do: "arrow_downward", else: "arrow_drop_up"
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
  def chart, do: chart(:range_all)

  @doc """
  The same, drawn for one segment of the range row.

  The two axis labels stay `Kati.Health.WeightSample.axis/0`'s under every
  segment, and that is deliberate rather than overlooked: they are the
  *drawing's* labels, printed under a chart that is the drawing's fourteen bars
  whenever nothing is stored, which is every state the captures render. A
  window has no month name to put there that would not be invented on the one
  path the labels are read on.
  """
  @spec chart(atom()) :: map()
  def chart(range) do
    bars = Kati.Screens.Weight.bars(range)
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
  def bars, do: bars(:range_all)

  @doc """
  The same, narrowed to one segment — and normalised against what is left.

  Against the window's own low and high rather than the whole series', because
  the reason the chart is not zero-based is that a weight series is a large
  number close to every other large number, and that argument is stronger
  inside a week than across a year.

  `[]` when readings are stored and none of them falls inside the window. An
  empty chart is the honest answer to *no weighings this week*, and it is why
  the low/high pair is computed inside a `case` — `Enum.min/1` raises on `[]`.
  """
  @spec bars(atom()) :: [float()]
  def bars(range) do
    case stored() do
      [] ->
        WeightSample.bars()

      readings ->
        windowed = readings |> Enum.filter(&within?(&1, range)) |> Enum.map(& &1.grams)

        case Enum.reverse(windowed) do
          [] ->
            []

          grams ->
            low = Enum.min(grams)
            high = Enum.max(grams)
            span = max(high - low, 1)

            Enum.map(grams, fn g -> 0.35 + (g - low) / span * 0.65 end)
        end
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

  # The list is re-read; the chart is not. `content/1` hands `assigns.range` to
  # `chart/1` at render, so the bars follow the chip without being carried on
  # the socket — one fewer assign that could go stale against the other.
  def handle_tap(range, socket) when range in [:range_week, :range_month, :range_all] do
    {:noreply,
     socket
     |> Mob.Socket.assign(:range, range)
     |> Mob.Socket.assign(:entries, Kati.Screens.Weight.entries(range))}
  end

  def handle_tap(_tag, socket), do: {:noreply, socket}
end
