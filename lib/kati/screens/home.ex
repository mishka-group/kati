defmodule Kati.Screens.Home do
  @moduledoc """
  Screen 01 — Home.

  Built to `.scratch/design/screens/01.html`, where every number is literal:
  the `64px 21px 132px` frame, the 44px header discs, the 52px search bar at
  radius 26, the cream hero at radius 24 with its three overlapping posters,
  the two continue-watching cards, three section tiles, and the rest-of-today
  card whose rows are separated by a `rgba(26,25,23,.07)` hairline.

  The design's one fixed element is the **New this week** card; everything
  below it is a shelf that can be swapped as sections arrive.

  ## Real data versus the drawing

  The date, the greeting and *Rest of today* come from the device — the last
  from `Kati.Calendars.Today`, so it shows the user's actual calendar. The
  hero, Continue watching and the section counts still render the drawing's
  own copy, because the Screen domain that would supply them is not built
  yet. Those are placeholders that look exactly like the design and will be
  fed by their domains as each lands, rather than empty space that makes the
  screen impossible to compare against the drawing.
  """
  use Kati.Screens.Root, root: :home

  alias Kati.Components.MishkaProgress
  alias Kati.Components.MishkaSeparator
  alias Kati.Theme
  alias Kati.Theme.Palette
  alias Kati.UI

  @impl true
  def load(socket), do: Mob.Socket.assign(socket, :timeline, Kati.Calendars.Today.rows())

  @doc false
  def content(assigns) do
    timeline = assigns.timeline

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={132}
      >
        {Kati.Screens.Home.header()}
        {Kati.Screens.Home.search()}
        {UI.eyebrow("New this week")}
        {Kati.Screens.Home.hero()}
        {UI.eyebrow("Continue watching")}
        {Kati.Screens.Home.continue_watching()}
        {UI.eyebrow("Watching")}
        {Kati.Screens.Home.watching()}
        {UI.eyebrow("Sections")}
        {Kati.Screens.Home.sections()}
        {UI.eyebrow("Rest of today", trailing: "See all")}
        {Kati.Screens.Home.rest_of_today(timeline)}
      </Column>
    </Scroll>
    """
  end

  @doc false
  def header do
    {date_line, greeting} = today()

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        <Column weight={1.0}>
          <Text
            text={String.upcase(date_line)}
            font_family="mono"
            text_size={11}
            letter_spacing={0.14}
            text_color={Palette.muted()}
          />
          <Spacer size={7} />
          <Text
            text={greeting}
            text_size={28}
            max_font_scale={1.6}
            font_weight="bold"
            letter_spacing={-0.03}
            text_color={:on_surface}
          />
        </Column>
        {Kati.Screens.Home.disc("notifications", true, :notifications)}
        <Spacer size={9} />
        {Kati.Screens.Home.disc("calendar_month", false, :open_calendar)}
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

  # A 44px disc. The unread dot is 8px of #E8823C with a 2px card-coloured
  # ring, which is how the design keeps it legible against the icon behind it.
  # CSS grows that ring OUTWARD from the 8px box (content-box), so the drawn
  # badge measures 12; Compose draws a border INWARD, so the box is stated as
  # 12 and the border eats back to the 8px the design shows.
  #
  # NOT Chelekom's Action Icon, though screens 02, 03, 06 and 07 all draw their
  # header discs with it now that `shadow` exists. This one has TWO children,
  # and the component puts caller-supplied children in a `<Row>`:
  #
  #     defp glyph(_props, content, _disabled?), do: ~MOB(<Row>{content}</Row>)
  #
  # A Row lays out along its axis; a Box stacks. The badge is an overlay — a
  # `fill_width`/`fill_height` Box that pins a 12pt dot to `top_trailing` of the
  # 44pt disc — so through a Row it would sit BESIDE the bell rather than over
  # its corner, and its two fills would have a hugging Row to fill rather than
  # the disc. The unread dot is the only thing on this screen that says there is
  # anything to open, so that is not a subtle regression.
  #
  # What it lacks, precisely: a way to say "stack these children", or a badge /
  # overlay slot of its own. `<Row>` is right for the icon-plus-nothing case it
  # was written for and wrong for every decorated one.
  @doc false
  def disc(icon, badge?, tag) do
    tap = {self(), tag}
    card = Palette.card()
    shadow = Theme.shadow_button()

    ~MOB"""
    <Box
      width={44}
      height={44}
      background={card}
      corner_radius={22}
      shadow={shadow}
      align="center"
      on_tap={tap}
    >
      {UI.symbol(icon, size: 21)}
      {Kati.Screens.Home.badge(badge?)}
    </Box>
    """
  end

  @doc false
  def badge(false), do: ~MOB"<Spacer size={0} />"

  def badge(true) do
    ~MOB"""
    <Box fill_width={true} fill_height={true} align="top_trailing">
      <Column padding_top={9} padding_right={10}>
        <Box
          width={12}
          height={12}
          corner_radius={6}
          background={Palette.accent()}
          border_width={2}
          border_color={Palette.card()}
        />
      </Column>
    </Box>
    """
  end

  @doc false
  def search do
    tap = {self(), :open_search}
    card = Palette.card()
    shadow = Theme.shadow_search()

    ~MOB"""
    <Column fill_width={true}>
      <Box
        fill_width={true}
        height={52}
        background={card}
        corner_radius={26}
        shadow={shadow}
        padding_left={18}
        padding_right={18}
        on_tap={tap}
      >
        <Row fill_width={true} fill_height={true} align="center">
          {UI.symbol("search", size: 20, color: Palette.muted())}
          <Spacer size={11} />
          <Text
            text="Search films, shows, events…"
            text_size={14.5}
            text_color={Palette.muted()}
            weight={1.0}
            max_lines={1}
          />
          <Spacer size={11} />
          {UI.symbol("tune", size: 19)}
        </Row>
      </Box>
      <Spacer size={26} />
    </Column>
    """
  end

  @doc false
  def hero do
    tap = {self(), :open_inbox}
    fill = Palette.ink_fill()

    ~MOB"""
    <Column fill_width={true}>
      <Box
        fill_width={true}
        background={Palette.cream()}
        corner_radius={24}
        shadow={Kati.Theme.shadow_hero()}
        padding_left={19}
        padding_right={19}
        padding_top={19}
        padding_bottom={17}
      >
        <Column fill_width={true}>
          <Row fill_width={true} align="top">
            <Column weight={1.0}>
              {Enum.map(Kati.Screens.Home.headline_lines(), fn line ->
              Kati.Screens.Home.headline(line)
            end)}
              <Spacer size={8} />
              <Text
                text="One premiere · two titles leave Lumen+ on Friday"
                text_size={13}
                line_height={1.45}
                text_color={Palette.cream_sub()}
              />
            </Column>
            <Spacer size={14} />
            {Kati.Screens.Home.poster_stack()}
          </Row>
          <Spacer size={17} />
          <Row align="center">
            <Row
              height={40}
              corner_radius={20}
              background={fill}
              padding_left={18}
              padding_right={18}
              align="center"
              on_tap={tap}
            >
              <Text
                text="Open inbox"
                text_size={13.5}
                font_weight="semibold"
                text_color={Palette.on_ink()}
              />
              <Spacer size={7} />
              {UI.symbol("arrow_forward", size: 17, color: Palette.on_ink())}
            </Row>
            <Spacer size={10} />
            <Text
              text="last check 18:02"
              font_family="mono"
              text_size={11}
              text_color={Palette.cream_meta()}
            />
          </Row>
        </Column>
      </Box>
      <Spacer size={26} />
    </Column>
    """
  end

  # The design breaks this headline itself — `3 new episodes<br>are waiting` —
  # so the break is content, not wrapping. Left to reflow, Compose fits
  # "3 new episodes are" on the first line and drops one word onto the second.
  # Two Texts rather than one `\n` string, which is how screen 28 draws the
  # same two lines.
  @doc false
  def headline_lines, do: ["3 new episodes", "are waiting"]

  @doc false
  def headline(line) do
    ~MOB"""
    <Text
      text={line}
      text_size={21}
      font_weight="bold"
      letter_spacing={-0.025}
      line_height={1.2}
      text_color={:on_surface}
      max_lines={1}
    />
    """
  end

  # Three 46x64 posters overlapping leftward by 16, each ringed 2px in the
  # hero's own cream so the overlap reads as a stack rather than a smear.
  #
  # The design does this with `margin-left:-16px`, which both shifts the poster
  # AND shrinks the box it occupies: three 46px posters at -16 measure
  # 46*3 - 16*2 = 106, not 138. Negative padding cannot express that — Compose
  # throws and takes the activity down — so the stack is a fixed 106-wide Box
  # with each poster offset by 30. Same geometry, stated once.
  @doc false
  def poster_stack do
    ~MOB"""
    <Box width={106} height={64}>
      {Enum.map(0..2, fn i -> Kati.Screens.Home.poster(i) end)}
    </Box>
    """
  end

  # The design's own three, in the order it stacks them.
  @hero_seeds ~w(ashfall42 marram15 harbour86)

  @doc false
  def poster(index) do
    shadow = Theme.shadow_poster()
    offset = index * 30
    src = Kati.Design.Images.poster(Enum.at(@hero_seeds, index))

    ~MOB"""
    <Box
      width={46}
      height={64}
      offset_x={offset}
      corner_radius={9}
      background={Palette.poster_on_cream()}
      border_width={2}
      border_color={Palette.cream()}
      shadow={shadow}
    >
      {Kati.Screens.Home.poster_image(src)}
    </Box>
    """
  end

  @doc false
  def poster_image(nil), do: ~MOB"<Spacer size={0} />"

  def poster_image(src) do
    ~MOB"""
    <Image src={src} width={42} height={60} corner_radius={7} content_mode="fill" />
    """
  end

  @doc false
  def continue_watching do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        {Kati.Screens.Home.watch_card("The Long Hollow", "S2 · E6 · 18m left", 0.62, "hollow71")}
        <Spacer size={13} />
        {Kati.Screens.Home.watch_card("Salt & Iron", "S1 · E3 · 41m left", 0.24, "saltiron33")}
      </Row>
      <Spacer size={26} />
    </Column>
    """
  end

  @doc false
  def watch_card(title, meta, progress, seed) do
    card = Palette.card()
    shadow = Theme.shadow_card()

    ~MOB"""
    <Box weight={1.0}>
      <Box fill_width={true} background={card} corner_radius={20} shadow={shadow} padding={11}>
        <Column fill_width={true}>
          <Box fill_width={true} height={112} corner_radius={12} background={Palette.placeholder()}>
            {Kati.Screens.Home.still(seed)}
          </Box>
          <Spacer size={11} />
          <Text
            text={title}
            text_size={14.5}
            font_weight="bold"
            letter_spacing={-0.02}
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={3} />
          <Text
            text={meta}
            font_family="mono"
            text_size={10.5}
            text_color={Palette.muted()}
            max_lines={1}
          />
          <Spacer size={10} />
          {Kati.Screens.Home.watch_bar(progress)}
        </Column>
      </Box>
    </Box>
    """
  end

  @doc """
  The continue-watching rail — 4pt, radius 2, ink on `#E7E3DC`, the design's
  `height:4px;border-radius:2px` twice over in screen 01.

  Chelekom's headless Progress in `render: :box`. Under the native mode this is
  Material's `LinearProgressIndicator`: it fills its parent, draws its own
  track in a colour that is not a prop, and carries whatever thickness and caps
  the pinned material3 draws that year — so none of the three numbers above
  were expressible, and the card hand-rolled two weighted Boxes instead.

  A finished episode is 100% and an unstarted one 0%; both made the
  hand-rolled shape hand Compose a literal `weight: 0.0` — the crash, not a
  warning. The component omits the node at either end.

  This screen already trusts the same shape elsewhere: `hairline/1` is
  `MishkaSeparator.separator(render: :box)`, which is the identical
  track-Box-with-a-trailing-`Spacer`, and it draws as a 1pt rule.
  """
  @spec watch_bar(float()) :: map()
  def watch_bar(progress) do
    MishkaProgress.progress(
      render: :box,
      value: progress,
      max: 1,
      height: 4,
      corner_radius: 2,
      color: Palette.ink(),
      track_color: Palette.track()
    )
  end

  # The 520x384 crop, which is what the design draws in these cards — a
  # different photograph from the 400x600 poster of the same title, not the
  # same image scaled.
  @doc false
  def still(seed) do
    case Kati.Design.Images.path(seed, {520, 384}) do
      nil ->
        ~MOB"<Spacer size={0} />"

      src ->
        ~MOB"""
        <Image src={src} fill_width={true} height={112} corner_radius={12} content_mode="fill" />
        """
    end
  end

  @doc """
  The Watching band — one row, and the same row screen 24 draws.

  The 23 August redraw puts *My services* on Home as well as in Settings, and
  the reason is what the row answers: **what can I actually watch**. Every
  recommendation, every "leaving on Friday", every *What fits tonight* is
  downstream of it, and a user whose services are wrong gets a home page full
  of confident nonsense with no visible cause.

  `Kati.Settings.Sample.watching/0` is the row, unchanged and unwrapped — the
  region and the subscribed count are read there, once, so Home and Settings
  cannot come to different answers about how many services somebody has. Screen
  92 is where it goes from both.
  """
  @spec watching() :: map()
  def watching do
    rows =
      Kati.Settings.Sample.watching()
      |> Enum.map(fn row ->
        Kati.UI.SettingsList.row(
          Kati.UI.SettingsList.icon_tile(row.icon),
          Kati.UI.SettingsList.body(row.title, row.sub),
          Kati.UI.SettingsList.chevron(),
          rule: false,
          on_tap: {self(), :open_services}
        )
      end)

    assigns = %{card: Kati.UI.SettingsList.card(rows)}

    ~MOB"""
    <Column fill_width={true}>
      {@card}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def sections do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        {Kati.Screens.Home.tile("restaurant", "Meals", "Dinner 19:30", Palette.bronze(), :open_meals)}
        <Spacer size={9} />
        {Kati.Screens.Home.tile("bolt", "Habits", "2 left today", Palette.green(), :open_habits)}
        <Spacer size={9} />
        {Kati.Screens.Home.tile("tune", "Settings", nil, nil, :open_settings)}
      </Row>
      <Spacer size={26} />
    </Column>
    """
  end

  @doc false
  def tile(icon, title, meta, dot, tag) do
    card = Palette.card()
    shadow = Theme.shadow_card_soft()
    tap = {self(), tag}

    ~MOB"""
    <Box weight={1.0} on_tap={tap}>
      <Box
        fill_width={true}
        background={card}
        corner_radius={18}
        shadow={shadow}
        padding_left={12}
        padding_right={12}
        padding_top={13}
        padding_bottom={13}
      >
        <Column fill_width={true}>
          <Row fill_width={true} align="center">
            {UI.symbol(icon, size: 19)}
            <Spacer weight={1.0} />
            {Kati.Screens.Home.dot(dot)}
          </Row>
          <Spacer size={10} />
          <Text
            text={title}
            text_size={12.5}
            font_weight="bold"
            letter_spacing={-0.01}
            text_color={:on_surface}
            max_lines={1}
          />
          {Kati.Screens.Home.tile_meta(meta)}
        </Column>
      </Box>
    </Box>
    """
  end

  @doc false
  def dot(nil), do: ~MOB"<Spacer size={0} />"
  def dot(color), do: ~MOB"<Box width={6} height={6} corner_radius={3} background={color} />"

  @doc false
  def tile_meta(nil), do: ~MOB"<Spacer size={0} />"

  def tile_meta(meta) do
    ~MOB"""
    <Column>
      <Spacer size={3} />
      <Text
        text={meta}
        font_family="mono"
        text_size={9.5}
        text_color={Palette.muted()}
        max_lines={1}
      />
    </Column>
    """
  end

  @doc """
  The two rows the drawing puts in this card.

  A device with no calendar mirrored yet answers `Kati.Calendars.Today` with
  an empty list, and the card then drew one grey line where the design draws a
  20:00 air date and a 21:30 reminder — so the one screen the owner opens
  first could not be compared with its frame at all. FIDELITY's rule applies:
  *missing data is not a reason for a blank screen*. Same shape the real rows
  arrive in, so `timeline_row/2` cannot tell them apart, and named a stand-in
  so nobody mistakes it for the user's own day.
  """
  @spec drawn_rows() :: [map()]
  def drawn_rows do
    [
      %{
        time: "20:00",
        title: "The Long Hollow — S2E6",
        meta: "Airs tonight · Lumen+",
        now?: true
      },
      %{time: "21:30", title: "Call Mum", meta: "Repeats weekly", now?: false}
    ]
  end

  @doc false
  def rest_of_today([]), do: rest_of_today(drawn_rows())

  def rest_of_today(rows) do
    card = Palette.card()
    last = length(rows) - 1

    ~MOB"""
    <Box
      fill_width={true}
      background={card}
      corner_radius={20}
      shadow={Kati.Theme.shadow_card()}
      padding_left={15}
      padding_right={15}
      padding_top={5}
      padding_bottom={5}
    >
      <Column fill_width={true}>
        {rows |> Enum.with_index() |> Enum.map(fn {row, i} ->
          Kati.Screens.Home.timeline_row(row, i < last)
        end)}
      </Column>
    </Box>
    """
  end

  @doc false
  def timeline_row(row, rule?) do
    accent = if row.now?, do: Palette.accent(), else: Palette.rail_idle()
    icon = if row.now?, do: "notifications_active", else: "radio_button_unchecked"

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_top={14} padding_bottom={14}>
        <Box width={40}>
          <Text
            text={row.time}
            font_family="mono"
            text_size={12}
            text_color={Palette.muted()}
            max_lines={1}
          />
        </Box>
        <Spacer size={14} />
        <Box width={3} height={34} corner_radius={2} background={accent} />
        <Spacer size={14} />
        <Column weight={1.0}>
          <Text
            text={row.title}
            text_size={14}
            font_weight="semibold"
            letter_spacing={-0.01}
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={3} />
          <Text text={row.meta} text_size={12} text_color={Palette.sub()} max_lines={1} />
        </Column>
        <Spacer size={14} />
        {UI.symbol(icon, size: 20, color: Palette.rail_idle())}
      </Row>
      {Kati.Screens.Home.hairline(rule?)}
    </Column>
    """
  end

  # Chelekom's headless Separator, given the design's own 7%-ink rule colour.
  #
  # `render: :box` is load-bearing, and the comment that used to sit here was
  # wrong about why. The default `:divider` is NOT the hand-rolled Box this
  # replaced: the bridge maps it to Material3's `HorizontalDivider`, which is a
  # Canvas drawing an ANTIALIASED `drawLine`, not a filled rect. At this
  # device's 2.6875x a 1dp rule gets a 3px canvas and a 2.6875px stroke, so the
  # last pixel row lands at ~69% coverage — a hairline 4-5/255 lighter than the
  # design's on one full-width row. `render: :box` swaps the primitive back to
  # `<Box fill_width height={1} background={color}>`, which is the node this
  # screen drew by hand, so every pixel row carries the full colour again.
  @doc false
  def hairline(false), do: ~MOB"<Spacer size={0} />"

  def hairline(true),
    do: MishkaSeparator.separator(color: Palette.hairline(), thickness: 1, render: :box)

  @doc "Today's date line and greeting, in the device's zone."
  def today do
    now = Kati.Time.now()
    day = Kati.Time.day_name(now)
    month = Kati.Time.month_name(now.month)

    greeting =
      cond do
        now.hour < 12 -> "Good morning"
        now.hour < 18 -> "Good afternoon"
        true -> "Good evening"
      end

    {"#{day} · #{now.day} #{month}", greeting}
  end

  @impl true
  def handle_tap(:open_inbox, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Inbox)}

  # The bell opens the gallery for now. Every page needs to be reachable
  # before any of it can be checked, and this is the one tap that does it.
  # The bell opened `Kati.Screens.Gallery` for as long as the gallery was the
  # only way to reach 53 screens that had landed at once. Every one of them is
  # reachable from its own place now, so the bell means what a bell means:
  # `Kati.Screens.InboxNotifications`, which is where Kati's badge-instead-of-
  # push manners are visible. The gallery moved to Settings → About, which is
  # where a page that describes the app belongs.
  def handle_tap(:notifications, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.InboxNotifications)}

  def handle_tap(:open_settings, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Settings)}

  def handle_tap(:open_services, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.MyServices)}

  def handle_tap(:open_meals, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.MealsToday)}

  def handle_tap(:open_habits, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Habits)}

  # Screen 86 rather than 19, and the two are different states rather than a
  # replacement: 86 is the empty field the moment it opens — which is what a tap
  # on this one produces — and 19 is *Search everything* with results showing,
  # reached from the Library. Both are drawn and both are worth being able to
  # look at.
  def handle_tap(:open_search, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.SearchIdle)}

  def handle_tap(_tag, socket), do: {:noreply, socket}
end
