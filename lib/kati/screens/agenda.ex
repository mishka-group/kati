defmodule Kati.Screens.Agenda do
  @moduledoc """
  Screen 30 — Calendar, agenda.

  Built to `test/design/screens/30.html`. The fourth view mode, and the
  only one with no grid at all: a date kicker appears where something exists
  and nowhere else, so an empty week costs no scrolling. The gap at the end is
  *stated* inside an outline rather than left as blank paper the user has to
  interpret.

  ## Whose agenda

  The reader's next `@horizon_days` days from today, read through
  `Kati.Screens.Calendar.rows_between/2` — the stored events and the followed
  shows' airings, the same rows screen 02 draws for each date. Each day with
  anything on it is one group; the footer says how far the list reaches. With
  nothing in that span the page draws screen 02's *Nothing scheduled* card and
  no footer.

  A row opens what screen 02's row for it opens.

  A root, not a pushed screen: the drawing carries the dock with Calendar
  active.

  ## Where this diverges from the drawing

  The footer's outline is `1.5px dashed`. The bridge's border has no dash
  pattern, so it ships solid at the design's `rgba(26,25,23,.16)`.

  The switcher's four labels are **deliberately still Latin**.
  `Kati.Screens.ViewSwitcher.bar/1` builds each segment's tap tag out of the
  word it prints and `ViewSwitcher.screen/1` routes on the English word, so
  translating the labels here would rename three live controls under `:fa` and
  the strip would go dead on the Persian page. The fix is a stable tag in the
  module that builds it.
  """
  use Kati.Screens.Root, root: :calendar
  use Gettext, backend: Kati.Gettext

  alias Kati.Components.MishkaActionIcon
  alias Kati.Components.MishkaSeparator
  alias Kati.Design.Images
  alias Kati.Screens.Calendar, as: Schedule
  alias Kati.Theme
  alias Kati.Theme.Palette
  alias Kati.UI

  @horizon_days 30

  @impl true
  def load(socket), do: Mob.Socket.assign(socket, :agenda, agenda(Kati.Time.today()))

  @doc """
  Coming back from a row opened from here: the agenda is read again.
  """
  @impl true
  def handle_kati(:resumed, _payload, socket),
    do: {:noreply, Mob.Socket.assign(socket, :agenda, agenda(Kati.Time.today()))}

  def handle_kati(_topic, _payload, socket), do: {:noreply, socket}

  @doc """
  The agenda from `today`: one group per day with anything on it, in date
  order, and the last day the list covers.
  """
  @spec agenda(Date.t()) :: %{groups: [map()], through: Date.t()}
  def agenda(%Date{} = today) do
    through = Date.add(today, @horizon_days - 1)

    groups =
      today
      |> Schedule.rows_between(through)
      |> Enum.sort_by(fn {day, _rows} -> day end, Date)
      |> Enum.map(fn {day, rows} -> group(day, rows, today) end)

    %{groups: groups, through: through}
  end

  defp group(day, rows, today) do
    n = length(rows)

    %{
      date: day,
      kicker: UI.eyebrow_label(kicker(day, today)),
      sub:
        Kati.Locale.date(day, :long) <>
          " · " <> ngettext("%{n} item", "%{n} items", n, n: Kati.Locale.number(n)),
      rows: rows
    }
  end

  @doc """
  What a day's kicker calls it: *Today*, *Tomorrow*, its weekday while it is
  inside the coming week, and its month after that — far enough out that the
  day of the week has stopped being how anybody finds it.
  """
  @spec kicker(Date.t(), Date.t()) :: String.t()
  def kicker(day, today) do
    case Date.diff(day, today) do
      0 -> gettext("Today")
      1 -> gettext("Tomorrow")
      n when n < 7 -> weekday(day)
      _later -> Kati.Locale.month_name(day, :short)
    end
  end

  # Three letters in Latin, the whole name in Persian: slicing پنج‌شنبه to
  # three graphemes gives پنج, the word for five.
  defp weekday(date) do
    Kati.Locale.pick(
      String.slice(Kati.Time.day_name(date), 0, 3),
      Kati.Calendar.Shamsi.weekday_name(Kati.Calendar.Shamsi.weekday_index(date))
    )
  end

  @doc false
  def content(assigns) do
    agenda = assigns.agenda

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={132}
      >
        {Kati.Screens.Agenda.header()}
        {Kati.Screens.Agenda.switcher()}
        {Kati.Screens.Agenda.body(agenda)}
      </Column>
    </Scroll>
    """
  end

  @doc false
  def body(%{groups: []}) do
    Schedule.empty_card("calendar_month", gettext("Nothing scheduled"), [
      gettext("Add anything with +")
    ])
  end

  def body(agenda) do
    ~MOB"""
    <Column fill_width={true}>
      {Enum.map(agenda.groups, fn group -> Kati.Screens.Agenda.group(group) end)}
      {Kati.Screens.Agenda.footer(Kati.Screens.Agenda.footer_label(agenda.through))}
    </Column>
    """
  end

  @doc "The footer's sentence: how far ahead the list has looked."
  @spec footer_label(Date.t()) :: String.t()
  def footer_label(through),
    do: gettext("Nothing else through %{date}", date: Kati.Locale.date(through, :short))

  # `tracking/1` rather than the bare -0.03: the same fraction of an em applied
  # to Vazirmatn pulls the letters apart at the joins.
  @doc false
  def header do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Text
          text={gettext("Agenda")}
          text_size={24}
          font_weight="bold"
          letter_spacing={Kati.Locale.tracking(-0.03)}
          text_color={:on_surface}
          max_lines={1}
        />
        <Spacer weight={1.0} />
        {Kati.Screens.Agenda.disc("search")}
        <Spacer size={9} />
        {Kati.Screens.Agenda.disc("tune")}
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc """
  A header disc: `Kati.Components.MishkaActionIcon`, filled and circular, with
  the `shadow` that makes it float rather than sit flat. The glyph goes in as
  a child so it resolves through the Material Symbols ligature.
  """
  def disc(icon) do
    MishkaActionIcon.action_icon(
      %{
        size: 44,
        shape: :circle,
        variant: :filled,
        background: Palette.card(),
        shadow: Kati.Theme.shadow_button()
      },
      [Kati.UI.symbol(icon, size: 21)]
    )
  end

  @doc false
  def switcher do
    bar =
      Kati.Screens.ViewSwitcher.bar([
        {"Day", false},
        {"Week", false},
        {"Month", false},
        {"Agenda", true}
      ])

    ~MOB"""
    <Column fill_width={true}>
      {bar}
      <Spacer size={20} />
    </Column>
    """
  end

  @doc false
  def group(group) do
    last = length(group.rows) - 1

    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.Agenda.kicker_row(group)}
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={20}
        shadow={Theme.shadow_card_soft()}
        padding_left={15}
        padding_right={15}
        padding_top={4}
        padding_bottom={4}
      >
        {group.rows
         |> Enum.with_index()
         |> Enum.map(fn {row, i} -> Kati.Screens.Agenda.row(row, i < last) end)}
      </Column>
      <Spacer size={20} />
    </Column>
    """
  end

  # Two mono labels on one baseline: the day in ink, its weight in `eyebrow`.
  # Both faces ask the STRING — `kati_mono.ttf` carries no Persian glyph — and
  # the tracking asks the reader, because 0.16em breaks Arabic-script joins.
  @doc false
  def kicker_row(group) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_left={2} padding_right={2}>
        <Text
          text={group.kicker}
          font_family={Kati.Locale.mono_face(group.kicker)}
          text_size={10.5}
          letter_spacing={Kati.Locale.tracking(0.16)}
          text_color={:on_surface}
          max_lines={1}
        />
        <Spacer size={9} />
        <Text
          text={group.sub}
          font_family={Kati.Locale.mono_face(group.sub)}
          text_size={10.5}
          text_color={Palette.eyebrow()}
          max_lines={1}
        />
      </Row>
      <Spacer size={10} />
    </Column>
    """
  end

  # The clock's face is asked of the string: `kati_mono.ttf` carries none of
  # U+06F0–U+06F9, so a Persian clock set in DM Mono would be empty boxes.
  @doc false
  def row(row, rule?) do
    tap = Schedule.tap(row)
    rule = row |> Schedule.section() |> Schedule.section_color()

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_top={13} padding_bottom={13} on_tap={tap}>
        <Column width={44}>
          <Text
            text={row.time}
            font_family={Kati.Locale.mono_face(row.time)}
            text_size={11}
            text_color={Palette.muted()}
            max_lines={1}
          />
        </Column>
        <Spacer size={12} />
        <Box width={3} height={30} corner_radius={2} background={rule} />
        <Spacer size={12} />
        {Kati.Screens.Agenda.thumb(Map.get(row, :seed))}
        <Column weight={1.0}>
          <Text
            text={row.title}
            text_size={13}
            font_weight="semibold"
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={3} />
          <Text text={row.meta} text_size={11.5} text_color={Palette.sub()} max_lines={1} />
        </Column>
      </Row>
      {Kati.Screens.Agenda.hairline(rule?)}
    </Column>
    """
  end

  # A poster only where the row has one — a followed show's. A row without
  # artwork closes the gap rather than reserving an empty 26pt slot.
  @doc false
  def thumb(nil), do: ~MOB"<Spacer size={0} />"

  def thumb(seed) do
    case Images.poster(seed) do
      nil ->
        ~MOB"""
        <Row align="center">
          <Box width={26} height={37} corner_radius={5} background={Palette.placeholder()} />
          <Spacer size={12} />
        </Row>
        """

      src ->
        ~MOB"""
        <Row align="center">
          <Image src={src} width={26} height={37} corner_radius={5} content_mode="fill" />
          <Spacer size={12} />
        </Row>
        """
    end
  end

  @doc """
  The rule between two agenda rows — `Kati.Components.MishkaSeparator` at
  `render: :box`. The default `:divider` is Material3's antialiased
  `drawLine`, whose last pixel row lands lighter than the 1px rule drawn.
  """
  def hairline(false), do: ~MOB"<Spacer size={0} />"

  def hairline(true),
    do: MishkaSeparator.separator(render: :box, color: Palette.hairline(), thickness: 1)

  @doc false
  def footer(label) do
    ~MOB"""
    <Box
      fill_width={true}
      corner_radius={18}
      border_color={Palette.border()}
      border_width={1.5}
      padding={14}
      align="center"
    >
      <Row align="center">
        {UI.symbol("expand_more", size: 18, color: Palette.sub())}
        <Spacer size={7} />
        <Text
          text={label}
          text_size={13}
          font_weight="semibold"
          text_color={Palette.ink_soft()}
          max_lines={1}
        />
      </Row>
    </Box>
    """
  end

  @doc """
  The day a row tag was drawn under, read back off the groups on screen, so a
  money or meals row opens its own day rather than today.
  """
  @spec day_of(map(), atom()) :: Date.t()
  def day_of(agenda, tag) do
    Enum.find_value(agenda.groups, Kati.Time.today(), fn group ->
      if Enum.any?(group.rows, &(Schedule.tag(&1) == tag)), do: group.date
    end)
  end

  # ── What a tap changes ────────────────────────────────────────────────────

  @impl true
  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "row_" <> _rest ->
        date = day_of(socket.assigns.agenda, tag)
        {:noreply, Schedule.open_timeline_row(socket, tag, date)}

      _other ->
        Kati.Screens.ViewSwitcher.handle_tap(tag, socket)
    end
  end
end
