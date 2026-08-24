defmodule Kati.Screens.ScheduleFa do
  @moduledoc """
  Screen 56 — برنامه, the Persian Schedule root.

  Built to `test/design/screens/56.html`. Screen 02's page, right to left:
  the header with its two 44pt discs, seven `flex:1` day cells at radius 16
  with a 2pt gap, the filter chips, and a 44pt time gutter beside every card.

  ## What changes, and why it is not mirroring

  **The week restarts.** شنبه is the first column, not Monday moved to the
  right. `Kati.Screens.ScheduleFa.Sample` holds the order for that reason, and
  `Kati.Calendar.Shamsi` already returns weeks the same way, so nothing here
  reverses a list.

  **The selected day is card white.** Screen 02 paints today ink; this drawing
  lifts ی/۲۵ onto `#FBFAF8` with the button shadow and leaves the ink for the
  20:00 gutter figure. Copying 02's ink cell would have been the reasonable
  guess and the wrong one.

  **The time gutter is at the right,** which the direction does on its own —
  the gutter is simply the first child of the row.

  ## Five rows, five shapes

  The drawing spends the page proving a schedule row is not one row repeated:
  a finished habit on the flat `#F4F1EC` card with a filled `check_circle`; an
  appointment lifted on card white; a reminder whose lead is a hollow circle
  rather than a rule; a payment behind a 26pt `#E4E0D9` glyph tile; and the
  evening's episode on its own deeper-shadowed card with the poster inline and
  a cream pill. `tone`, `lead` and `trailing` in the sample carry exactly those
  three axes.

  Persian text is Vazirmatn throughout, digits included — see
  `Kati.Screens.Fa` for why the times cannot be set in DM Mono.

  ## Real data versus the drawing

  Screen 02's query, read the same way: `Kati.Calendars.Today.rows/1` for the
  selected day, falling back to the drawn day when nothing is mirrored — the
  substitution `Kati.Screens.Calendar.day_rows/1` makes, and *only* for today,
  because a fresh install must still be comparable with
  `.scratch/design/audit/56.png` and no other day may be dressed up with events
  that are not there.

  **The strip is the real week, and it is still not a mirrored list.** `days/1`
  walks forward from the شنبه of the selected week —
  `Kati.Calendar.Shamsi.weekday_index/1` is 1 for شنبه, so the Saturday is
  `date - (index - 1)` and the seven cells are generated in reading order.
  Nothing is reversed to get there, which is the whole point 60 makes about
  matrices whose columns are days.

  **The subtitle counts what is drawn.** یکشنبه ۲۵ مرداد · ۵ مورد is the
  weekday, the Shamsi day and month, and the number of rows under it — five on
  the drawn day, because the four ordinary rows and the evening's episode are
  five items. A real day answers with its own.

  ### The feature card is the one thing a real row cannot become

  The evening's episode has a poster, a service and a cream pill saying why it
  matters, and `Kati.Calendars.Today` carries none of the three: a row is a
  time, a summary and a composed meta line. So a real air date draws as an
  ordinary row with the accent rule — the same fact, minus artwork nothing can
  supply — and the feature card belongs to the drawn day. Screen 02 makes the
  same admission in a different shape: `Kati.Screens.Calendar.shaped/1` stamps
  `posters: []` on every real row it builds.

  Nor can a real row be drawn **done**. The flat `#F4F1EC` card with the green
  `check_circle` says a habit was kept, and `Kati.Calendars.Override.kind` is
  `:modified | :cancelled` — an occurrence can be called off and cannot be
  ticked, which is the gap `Kati.Screens.Habits` is waiting on in full. A row
  that is not imminent therefore settles onto the flat card with a hollow ring,
  which asserts nothing about whether it happened.

  ### The sub-line is composed here, not taken off the row

  A row's `:meta` is its sub-line **in English** — screens 01, 02 and 28 draw
  that field and were captured drawing it — so a page that renders it verbatim
  ends every real row in `Airs today` or `Habit` beneath a Persian title. That
  is what this screen used to do.

  The row carries `:location` and `:kind` now, which are the two facts the line
  is made of, so `shaped/1` asks `Kati.Calendars.Today.meta/2` for the Persian
  line and the English one never reaches the page. The location is the user's
  own words either way and is not rewritten; only Kati's half of the line is
  translated. `Kati.Screens.Calendar.kind/1` reads the same `:kind` to pick the
  chrome, so the card a row gets and the words under it are now derived from one
  fact rather than from a sentence one of them had to search.
  """
  use Mob.Screen
  import Mob.Sigil

  alias Kati.Calendar.Shamsi
  alias Kati.I18n.Digits
  alias Kati.Screens.Fa
  alias Kati.Screens.ScheduleFa.Sample
  alias Kati.Theme.Palette
  alias Kati.UI

  def mount(_params, _session, socket) do
    Kati.Theme.activate()

    date = Kati.Time.today()
    day = Kati.Screens.ScheduleFa.day(date)
    count = length(day.events) + if(day.feature, do: 1, else: 0)

    socket
    |> Mob.Socket.assign(:header, Kati.Screens.ScheduleFa.header_line(date, count))
    |> Mob.Socket.assign(:days, Kati.Screens.ScheduleFa.days(date))
    |> Mob.Socket.assign(:events, day.events)
    |> Mob.Socket.assign(:feature, day.feature)
    |> then(&{:ok, &1})
  end

  def render(assigns) do
    Fa.frame(:calendar, Kati.Screens.ScheduleFa.content(assigns))
  end

  @doc """
  The day's rows, in the two shapes this page draws them in.

  `events` are the ordinary rows and `feature` is the evening's episode card,
  which only the drawn day has — see the moduledoc. Returned as one map rather
  than two reads so the pair can never come from two different answers about
  whether the store is empty.
  """
  @spec day(Date.t()) :: %{events: [map()], feature: map() | nil}
  def day(date) do
    case Kati.Calendars.Today.rows(date) do
      # Today, and only today, is dressed in the drawing. The strip on this
      # page selects nothing yet, so `date` is always today and this is the
      # branch that never runs — kept because it is the rule
      # `Kati.Screens.Calendar.day_rows/1` states and the one the first day tap
      # will need: no other day may be shown events it does not have.
      [] -> if date == Kati.Time.today(), do: drawn_day(), else: %{events: [], feature: nil}
      rows -> %{events: Enum.map(rows, &Kati.Screens.ScheduleFa.shaped/1), feature: nil}
    end
  end

  @doc """
  The five rows `test/design/screens/56.html` draws, in its own order.

  Stand-in copy, and `Kati.Screens.ScheduleFa.Sample` says so — but the five
  SHAPES are not stand-in: a kept habit, an appointment, a reminder, a payment
  and an air date are five states the real timeline needs, and the drawing
  spends the whole page proving they are not one row repeated.
  """
  @spec drawn_day() :: %{events: [map()], feature: map()}
  def drawn_day, do: %{events: Sample.events(), feature: Sample.feature()}

  @doc """
  A real timeline row, given the drawn chrome its kind calls for.

  `tone`, `lead` and `trailing` are the three axes `Sample.events/0` carries,
  and every one of them is decided here from something the row actually says:
  `Kati.Screens.Calendar.kind/1` for which of the four kinds it is, and `now?`
  for whether it is imminent. Nothing claims a habit was kept — see the
  moduledoc — so `trailing` is `nil` on every real row.

  **The sub-line is composed here, in Persian**, rather than taken off the row.
  `row.meta` is the same sentence in English — it is what screens 01, 02 and 28
  were captured drawing, so `Kati.Calendars.Today` keeps writing it there — and
  drawing that field on this page is what ended every real row in `Airs today`
  under a Persian title. `Kati.Calendars.Today.meta/2` builds the line from the
  row's own `:location` and `:kind` instead, so the location stays the user's
  own words and only Kati's half is translated.
  """
  @spec shaped(map()) :: map()
  def shaped(row) do
    {tone, lead} = chrome(Kati.Screens.Calendar.kind(row), row.now?)

    %{
      time: Digits.to_persian(row.time),
      tone: tone,
      lead: lead,
      title: row.title,
      meta: Kati.Calendars.Today.meta(row, :fa),
      trailing: nil
    }
  end

  # Orange means new or now and only that, which on this page is an air date.
  # An imminent appointment is lifted on card white with the ink rule; anything
  # else settles onto the flat card behind a hollow ring, which is the drawing's
  # own shape for a row that is neither done nor happening.
  defp chrome("money", _now?), do: {:done, {:badge, "payments"}}
  defp chrome("screen", _now?), do: {:raised, {:rule, Palette.accent()}}
  defp chrome(_kind, true), do: {:raised, {:rule, Palette.ink()}}
  defp chrome(_kind, _now?), do: {:done, {:icon, "radio_button_unchecked"}}

  @doc """
  The seven day cells, شنبه first, for the week the selected day falls in.

  Generated forward from that week's Saturday, so the sequence is produced in
  reading order rather than reversed out of a Gregorian one. Day numbers are
  Shamsi and Persian-digited, which is `Kati.Calendar.Shamsi.fa/1`'s job.
  """
  @spec days(Date.t()) :: [map()]
  def days(date) do
    saturday = Date.add(date, -(Shamsi.weekday_index(date) - 1))

    for offset <- 0..6 do
      cell = Date.add(saturday, offset)
      {_year, _month, day} = Shamsi.from_gregorian(cell)

      %{
        name: Shamsi.weekday_short(Shamsi.weekday_index(cell)),
        num: Shamsi.fa(day),
        selected?: cell == date
      }
    end
  end

  @doc "The root's title, and the selected day with the number of rows on it."
  @spec header_line(Date.t(), non_neg_integer()) :: map()
  def header_line(date, count) do
    {_year, month, day} = Shamsi.from_gregorian(date)

    subtitle =
      "#{Shamsi.weekday_name(Shamsi.weekday_index(date))} #{Shamsi.fa(day)} " <>
        "#{Shamsi.month_name(month)} · #{Shamsi.fa(count)} مورد"

    %{title: "برنامه", subtitle: subtitle}
  end

  @doc false
  def content(assigns) do
    header = assigns.header
    days = assigns.days
    events = assigns.events
    feature = assigns.feature

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={132}
      >
        {Kati.Screens.ScheduleFa.header(header)}
        {Kati.Screens.ScheduleFa.day_strip(days)}
        {Kati.Screens.ScheduleFa.week_note()}
        {Kati.Screens.ScheduleFa.chips()}
        {Kati.Screens.ScheduleFa.timeline(events)}
        {Kati.Screens.ScheduleFa.feature_row(feature)}
      </Column>
    </Scroll>
    """
  end

  @doc false
  def header(header) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        <Column weight={1.0}>
          <Text
            text={header.title}
            font_family="fa"
            font_weight="bold"
            text_size={27}
            text_color={:on_surface}
          />
          <Spacer size={5} />
          <Text
            text={header.subtitle}
            font_family="fa"
            text_size={11.5}
            text_color={Palette.muted()}
            max_lines={1}
          />
        </Column>
        {Fa.disc("search", :open_search)}
        <Spacer size={9} />
        {Fa.disc("more_horiz", :open_menu)}
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc false
  def day_strip(days) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        {days
         |> Enum.map(&Kati.Screens.ScheduleFa.day_cell/1)
         |> Enum.intersperse(Kati.Screens.ScheduleFa.cell_gap())}
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc false
  def cell_gap, do: ~MOB"<Spacer size={2} />"

  # Two clauses rather than one with conditional colours: the unselected cell
  # carries no fill and no shadow at all, and a transparent shadow is not the
  # same node as no shadow.
  @doc false
  def day_cell(%{selected?: true} = day) do
    ~MOB"""
    <Box weight={1.0}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={16}
        shadow={Kati.Theme.shadow_button()}
        padding_top={9}
        padding_bottom={11}
      >
        <Text
          text={day.name}
          font_family="fa"
          font_weight="medium"
          text_size={11}
          text_color={Palette.sub()}
          text_align="center"
        />
        <Spacer size={5} />
        <Text
          text={day.num}
          font_family="fa"
          font_weight="medium"
          text_size={15}
          text_color={Palette.ink()}
          text_align="center"
        />
      </Column>
    </Box>
    """
  end

  def day_cell(day) do
    ~MOB"""
    <Box weight={1.0}>
      <Column fill_width={true} corner_radius={16} padding_top={9} padding_bottom={11}>
        <Text
          text={day.name}
          font_family="fa"
          font_weight="medium"
          text_size={11}
          text_color={Palette.tertiary()}
          text_align="center"
        />
        <Spacer size={5} />
        <Text
          text={day.num}
          font_family="fa"
          font_weight="medium"
          text_size={15}
          text_color={Palette.sub()}
          text_align="center"
        />
      </Column>
    </Box>
    """
  end

  @doc false
  def week_note do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_left={2} padding_right={2}>
        {UI.symbol("info", size: 15, color: Palette.tertiary())}
        <Spacer size={8} />
        <Text
          text={Sample.week_note()}
          font_family="fa"
          text_size={11.5}
          text_color={Palette.sub()}
        />
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc false
  def chips do
    ~MOB"""
    <Column fill_width={true}>
      <Scroll axis="horizontal">
        <Row>
          {Sample.chips()
           |> Enum.with_index()
           |> Enum.map(fn {label, i} -> Kati.Screens.ScheduleFa.chip(label, i == 0) end)
           |> Enum.intersperse(Kati.Screens.ScheduleFa.chip_gap())}
        </Row>
      </Scroll>
      <Spacer size={18} />
    </Column>
    """
  end

  # The gap lives between the pills, like day_strip's cell_gap. Held inside the
  # chip it padded the label instead, pushing every one 3.5 off centre.
  @doc false
  def chip_gap, do: ~MOB"<Spacer size={7} />"

  @doc false
  def chip(label, on?) do
    bg = if on?, do: Palette.ink_fill(), else: Palette.card()
    fg = if on?, do: Palette.on_ink(), else: Palette.ink_soft()
    shadow = if on?, do: nil, else: Kati.Theme.shadow_card_soft()

    ~MOB"""
    <Row
      height={32}
      corner_radius={16}
      background={bg}
      shadow={shadow}
      padding_left={15}
      padding_right={15}
      align="center"
    >
      <Text
        text={label}
        font_family="fa"
        font_weight="semibold"
        text_size={12.5}
        text_color={fg}
        max_lines={1}
      />
    </Row>
    """
  end

  @doc false
  def timeline(events) do
    ~MOB"""
    <Column fill_width={true}>
      {Enum.map(events, &Kati.Screens.ScheduleFa.event_row/1)}
    </Column>
    """
  end

  @doc false
  def event_row(row) do
    bg = if row.tone == :done, do: Palette.card_settled(), else: Palette.card()
    shadow = if row.tone == :done, do: nil, else: Kati.Theme.shadow_card_soft()

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        <Column width={44} padding_top={14}>
          <Text
            text={row.time}
            font_family="fa"
            text_size={12}
            text_color={Palette.muted()}
            max_lines={1}
          />
        </Column>
        <Spacer size={12} />
        <Box weight={1.0}>
          <Row
            fill_width={true}
            background={bg}
            corner_radius={18}
            shadow={shadow}
            padding_left={15}
            padding_right={15}
            padding_top={13}
            padding_bottom={13}
            align="center"
          >
            {Kati.Screens.ScheduleFa.lead(row.lead)}
            <Spacer size={12} />
            <Column weight={1.0}>
              <Text
                text={row.title}
                font_family="fa"
                font_weight="semibold"
                text_size={13.5}
                text_color={:on_surface}
                max_lines={1}
              />
              <Spacer size={3} />
              <Text
                text={row.meta}
                font_family="fa"
                text_size={11.5}
                text_color={Palette.sub()}
                max_lines={1}
              />
            </Column>
            {Kati.Screens.ScheduleFa.trailing(row.trailing)}
          </Row>
        </Box>
      </Row>
      <Spacer size={10} />
    </Column>
    """
  end

  # The drawing stretches the rule to the card (`align-self:stretch`). Nothing
  # in this bridge stretches a child inside a wrap-height Row, so it has to be
  # the card's own content height as a number.
  #
  # 36 was that number by arithmetic and was wrong on the device: measured off
  # the 08:00 row in `audit_snapshot/56.png`, the card is 67.7dp tall at 13pt
  # of padding each side, so the content — 13.5 + 3 + 11.5 of Vazirmatn — is
  # 41.7. Compose's line metrics run taller than the browser's (FIDELITY,
  # "Measured, not eyeballed"), and at 36 the rule stopped ~3dp short at each
  # end of a centred row.
  @doc false
  def lead({:rule, color}) do
    ~MOB"<Box width={3} height={42} corner_radius={2} background={color} />"
  end

  def lead({:icon, name}) do
    ~MOB"""
    <Column>
      {Kati.UI.symbol(name, size: 21, color: Palette.tertiary())}
    </Column>
    """
  end

  # The payment row's 26pt glyph tile is `Kati.Components.MishkaThemeIcon` —
  # "a themed container around exactly one icon", which is precisely what the
  # drawing puts here — for the same reason `Kati.UI.SettingsList.icon_tile/1`
  # is, and with the same guarantee. With children, an explicit numeric
  # `color`, no `id` and no `on_tap`, `theme_icon/2` returns
  # `%{type: :box, props: %{width: 26, height: 26, align: :center,
  # corner_radius: 8, background: Palette.placeholder()}, children: [glyph]}` — node for
  # node what this wrote by hand. `align: :center` and `align="center"` reach
  # the bridge identically; the glyph shorthand, the gradient layer and the id
  # markers are all skipped.
  #
  # It carries no direction assumption to worry about: the tile is square, its
  # one child is centred, and the `rtl` root moves the whole tile as one child
  # of the row.
  def lead({:badge, name}) do
    Kati.Components.MishkaThemeIcon.theme_icon(
      %{variant: :filled, color: Palette.placeholder(), size: 26, radius: 8},
      [Kati.UI.symbol(name, size: 15, color: Palette.ink_soft())]
    )
  end

  @doc false
  def trailing(nil), do: ~MOB"<Spacer size={0} />"

  def trailing({:icon, name, color}) do
    ~MOB"""
    <Row align="center">
      <Spacer size={12} />
      {Kati.UI.symbol(name, size: 21, color: color, fill: true)}
    </Row>
    """
  end

  # The evening's episode: padding 15 rather than 13/15, a deeper shadow
  # (`0 16px 30px -18px rgba(26,25,23,.75)`), the poster inline, and the gutter
  # figure in ink at 500 rather than muted.
  #
  # The accent rule is a declared number because that is the card's content
  # height — title, meta and the pill beneath them — and a Row gives a child no
  # way to inherit it. Measured off `audit_snapshot/56.png`: the card runs
  # y=1643..1923 (106.9dp) at 15pt padding, and the cream pill's bottom edge —
  # the last thing in the text column — lands 77.3dp below the content top. 72
  # left the rule a full 5dp short of the pill.
  # A real day has no feature card — see the moduledoc — so the node is absent
  # rather than an empty one, which is what `<Spacer size={0} />` is for
  # everywhere else on these screens.
  @doc false
  def feature_row(nil), do: ~MOB"<Spacer size={0} />"

  def feature_row(feature) do
    ~MOB"""
    <Row fill_width={true} align="top">
      <Column width={44} padding_top={15}>
        <Text
          text={feature.time}
          font_family="fa"
          font_weight="medium"
          text_size={12}
          text_color={Palette.ink()}
          max_lines={1}
        />
      </Column>
      <Spacer size={12} />
      <Box weight={1.0}>
        <Row
          fill_width={true}
          background={Palette.card()}
          corner_radius={18}
          shadow="0 1 2 0 #0D1A1917 | 0 16 30 -18 #BF1A1917"
          padding={15}
          align="top"
        >
          <Box width={3} height={77} corner_radius={2} background={Palette.accent()} />
          <Spacer size={12} />
          {Kati.Screens.ScheduleFa.poster(feature.seed)}
          <Spacer size={12} />
          <Column weight={1.0}>
            <Text
              text={feature.title}
              font_family="fa"
              font_weight="bold"
              text_size={14}
              text_color={:on_surface}
              max_lines={1}
            />
            <Spacer size={4} />
            <Text
              text={feature.meta}
              font_family="fa"
              text_size={11.5}
              text_color={Palette.sub()}
              max_lines={1}
            />
            <Spacer size={9} />
            <Row
              height={24}
              corner_radius={12}
              background={Palette.cream()}
              padding_left={10}
              padding_right={10}
              align="center"
            >
              <Box width={5} height={5} corner_radius={3} background={Palette.accent()} />
              <Spacer size={5} />
              <Text
                text={feature.pill}
                font_family="fa"
                font_weight="semibold"
                text_size={11}
                text_color={Palette.gold_text()}
                max_lines={1}
              />
            </Row>
          </Column>
        </Row>
      </Box>
    </Row>
    """
  end

  @doc false
  def poster(seed) do
    case Kati.Design.Images.poster(seed) do
      nil ->
        ~MOB"<Box width={42} height={60} corner_radius={8} background={Palette.placeholder()} />"

      src ->
        ~MOB"""
        <Image src={src} width={42} height={60} corner_radius={8} content_mode="fill" />
        """
    end
  end

  def handle_info({:tap, :open_search}, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Search)}

  def handle_info({:tap, tag}, socket), do: Fa.dock_tap(tag, :calendar, socket)
  def handle_info(_message, socket), do: {:noreply, socket}
end
