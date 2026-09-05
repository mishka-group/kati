defmodule Kati.Screens.EventDetail do
  @moduledoc """
  Screen 31 — Event detail & edit.

  Built to `test/design/screens/31.html`. Its own dismissal, not a back
  pill: the drawing puts a `close` disc, a centred "Edit event" title and an
  ink Save pill on one row, in flow at the top of the scroll — an editor you
  finish or abandon, not a page you came from. So this is `use Mob.Screen`
  with its own `mount/3` and `render/1`, the way screen 08 is, rather than
  `Kati.Screens.Pushed`.

  The frame's bottom padding is **40, not 132**: there is no dock under this
  screen, so the 132 that clears the tab bar would just be dead paper.

  ## What is live

  The two section chips are a single choice — an event lives in one section —
  so tapping Personal fills it and empties Work. The timezone row toggles its
  switch, track colour and knob together, by tapping anywhere along the row.

  The clash card's three buttons are deliberately left inert. Their fills are
  not a selection: the drawing gives **two** of them ink and one the quiet
  paper fill, which says "these two are suggestions and this one is accepting
  the overlap" — a selected-one-of-three model cannot draw that resting state,
  and shifting or shortening the event means editing times this screen has no
  way to recompute honestly.

  ## Where this diverges from the drawing

    * The title's caret is a real 2x22 accent rule after the text rather than
      an inline `vertical-align:-3px` span. Same mark, laid out by a `Row`.
    * "Add someone" has a `1.5px dashed` ring. The bridge's border has no dash
      pattern, so it ships solid at the design's `rgba(26,25,23,.2)`.
    * The timezone switch is drawn from primitives rather than
      `Kati.Components.MishkaSwitch`: the design specifies its exact geometry
      (46x28 track, 3pt inset, 22pt knob with its own shadow), and a component
      whose whole job is to own those numbers would have to be overridden on
      every one of them.

  ## The shared components this screen uses

  This paragraph used to record the opposite. The section chips, the `close`
  disc and the "Add someone" ring were hand-rolled because the vendored
  components took no `height`, no `font_weight`, no per-axis padding, no
  `border_*` and no `shadow`. All five props landed upstream, so all three are
  now the component that names them:

    * `close_disc/1` — `Kati.Components.MishkaCloseButton`, filled, with the
      `shadow` that is what makes a disc float rather than sit flat.
    * `save_pill/1`, `action/2` — `Kati.Components.MishkaPill`.
    * `section_chip/2` — `Kati.Components.MishkaChip`, whose `checked` carries
      the one-of-two state exactly.
    * `tile/1`, `add_ring/0` — `Kati.Components.MishkaThemeIcon`, filled and
      `:subtle` respectively.
    * `hairline/1` — `Kati.Components.MishkaSeparator` at `render: :box`.
    * `avatar/1` — `Kati.Components.MishkaAvatar`.

  What stays hand-rolled, and why:

    * **the timezone switch**, still. `Kati.Components.MishkaSwitch` wraps
      Compose's Material `Switch`, whose metrics are fixed in material3 (52x32
      track, 24/16 handles, a 2dp outline) with only the colours parameterised.
      No prop reshapes it into the design's 46x28 with a 22pt thumb.
    * **`delete/1`**, the outlined destructive bar. It is a full-width button,
      not a token, and putting it through a pill would buy a `Box` and cost two
      wrapper nodes.

  ## Which event this is about

  `mount/3`'s params, and nothing else. `%{id: id}` is an
  `Kati.Calendars.Event` primary key put there by the row that was tapped — see
  `Kati.Screens.Calendar.tag/1` — and this screen loads THAT event.

  It used to assign `Kati.Calendar.SampleEvent.event/0` unconditionally, which
  is the defect issue #84 is named for: screen 02 could open this screen and
  had no way to say which of the day's rows it had opened, so the third
  appointment on a Thursday and the first one drew the same page. A detail
  screen that cannot be told what it is detailing is a detail screen about
  whatever the store hands back first.

  **No id still means the sample, exactly as before.** That is the state every
  frame of `test/design/screens/31.html` was captured in and the state the
  empty-database sweep renders, and an id that names nothing stored — a
  deleted event, a fresh install — falls back to the same place rather than to
  a blank page.

  ## What a stored event can and cannot fill in

  Live, because the column exists: the title (`summary`), the date and clock
  line and its duration (`dtstart_utc`, `dtend_utc`, `is_all_day`,
  `dtstart_date`), the timezone row (`tzid`, `tz_behaviour`) and the location.

  **Absent rather than borrowed** — this is the part worth arguing, because the
  tempting thing is to lay the drawing's values under a real event and let the
  page look complete:

    * **the section chips.** No column anywhere says whether an event is
      Personal or Work. Drawing `Work` filled over a dentist appointment is not
      a placeholder, it is a false statement about this event, and the reader
      has no way to tell which of the two it is.
    * **the clash card.** `Overlaps Standup by 15 min` is a claim about the
      day around this event, in minutes. It is computable and it is not
      computed here; drawing it uncomputed would put a number on the screen
      that is right about nothing.
    * **the invitees.** `Kati.Calendars.Event` models timing, identity, kind
      and sync bookkeeping. There is no attendee table, so a real event's guest
      list is empty and the card says so with its own `Add someone` row.
    * **Repeats and Alerts.** `rrule` is stored and there is no humaniser
      anywhere in `lib/` — `Kati.Recurrence` expands rules, it does not
      describe them — and printing `FREQ=WEEKLY;INTERVAL=2;BYDAY=TH` at a user
      is a database row talking to itself. Alerts have no column at all.

  The drawn event keeps all four, because the drawing is where those values
  come from and it is the only thing they are true of.
  """
  use Mob.Screen
  import Mob.Sigil

  alias Kati.Calendar.SampleEvent
  alias Kati.Calendars.Event
  alias Kati.Components.MishkaAvatar
  alias Kati.Components.MishkaChip
  alias Kati.Components.MishkaCloseButton
  alias Kati.Components.MishkaPill
  alias Kati.Components.MishkaSeparator
  alias Kati.Components.MishkaThemeIcon
  alias Kati.Design.Images
  alias Kati.Theme
  alias Kati.Theme.Palette
  alias Kati.UI

  @spec mount(map(), map(), Mob.Socket.t()) :: {:ok, Mob.Socket.t()}
  def mount(params, _session, socket) do
    # The resolved mode, not a hardcoded `light()`. `Kati.Theme.current/0` is
    # the stored Auto/Light/Dark choice resolved against the device, and every
    # `Palette` token below reads the theme this installs.
    Mob.Theme.set(Kati.Theme.current())
    {:ok, Mob.Socket.assign(socket, :event, Kati.Screens.EventDetail.event(params))}
  end

  @doc """
  The event this screen is about: the one the push named, or the drawing's.

  Split out of `mount/3` and public because it is the whole of the screen's
  read, and the pair the empty-database sweep asks — *what does this answer
  with when nothing is stored* — can only be put to a named function. See the
  moduledoc for what a stored event fills in and what it deliberately leaves
  out.

  Three ways in and two answers. An id that names a stored, un-tombstoned event
  answers that event; no id at all, and an id that names nothing, both answer
  the drawing. The second of those matters as much as the first: an event
  deleted on another device is a push whose id is now a dead letter, and the
  screen it opens has to be a page rather than a crash.
  """
  @spec event(map()) :: map()
  def event(params \\ %{}) do
    case Map.get(params, :id) do
      id when is_binary(id) and id != "" -> stored(id) || SampleEvent.event()
      _no_id -> SampleEvent.event()
    end
  end

  # `Ash.get/2` answers a tombstone as happily as a live row — `deleted_at` is
  # a column and not a base filter — so a soft-deleted event is read back and
  # then refused here. Opening a row the user deleted would be the same defect
  # as opening the wrong one, said more quietly.
  defp stored(id) do
    case Ash.get(Event, id) do
      {:ok, %Event{deleted_at: nil} = event} -> shaped(event)
      _other -> nil
    end
  rescue
    _error -> nil
  end

  defp shaped(%Event{} = event) do
    zone = Kati.Time.device_zone()

    %{
      # The handle, not a rendering. Save and Delete are both writes about THIS
      # row, and everything else in this map is a projection of the event that
      # cannot be turned back into it. `Kati.Calendar.SampleEvent.event/0` has
      # no such key and is deliberately not given one: it is a transcription of
      # board 31, there is no row behind it, and `Map.get(event, :id)` reading
      # `nil` is what tells the two apart — and what keeps both controls
      # untapped on the page every sweep sees. See `save_pill/1`.
      id: event.id,
      title: event.summary || "Untitled",
      sections: [],
      fields: stored_fields(event, zone),
      clash: nil,
      invitees: []
    }
  end

  # In the drawing's order, minus the rows no column can answer. A row dropped
  # is a row the reader can see is not there; a row kept and filled with the
  # drawing's words is one they cannot.
  defp stored_fields(event, zone) do
    Enum.reject([when_field(event, zone), zone_field(event), place_field(event)], &is_nil/1)
  end

  # An all-day event is date-valued and has no clock — `dtstart_date` is the
  # column, and reading `dtstart_utc` for it would be reading a nil.
  defp when_field(%Event{is_all_day: true, dtstart_date: %Date{} = date}, _zone),
    do: %{icon: "schedule", title: day_line(date), sub: "All day", trailing: nil}

  defp when_field(%Event{dtstart_utc: %DateTime{} = starts} = event, zone) do
    local = Kati.Time.in_zone(starts, zone)
    ends = event.dtend_utc && Kati.Time.in_zone(event.dtend_utc, zone)

    %{
      icon: "schedule",
      title: day_line(DateTime.to_date(local)),
      sub: clock_line(local, ends),
      trailing: length_of(local, ends)
    }
  end

  defp when_field(_event, _zone), do: nil

  # `nil` tzid is FLOATING — "09:00 wherever you are" — and naming a zone for it
  # would invent the one fact the column exists to leave unsaid.
  defp zone_field(%Event{tzid: tzid, tz_behaviour: behaviour})
       when is_binary(tzid) and tzid != "",
       do: %{
         icon: "public",
         title: "Timezone",
         sub: tzid <> " · " <> travel(behaviour),
         trailing: {:switch, behaviour == :device}
       }

  defp zone_field(_event), do: nil

  defp travel(:device), do: "follows travel"
  defp travel(:floating), do: "floats where you are"
  defp travel(_fixed), do: "stays fixed"

  defp place_field(%Event{location: place}) when is_binary(place) and place != "",
    do: %{icon: "place", title: "Location", sub: place, trailing: :chevron}

  defp place_field(_event), do: nil

  # `Thu 20 Aug` — the drawing's own line, three letters of the day and three of
  # the month, so a real event and the drawn one read the same way.
  defp day_line(date) do
    day = Kati.Time.day_name(date) |> String.slice(0, 3)
    month = Kati.Time.month_name(date.month) |> String.slice(0, 3)
    "#{day} #{date.day} #{month}"
  end

  defp clock_line(local, nil), do: clock(local)
  defp clock_line(local, ends), do: clock(local) <> " – " <> clock(ends)

  defp clock(dt), do: Calendar.strftime(dt, "%H:%M")

  # The drawing's `1h`, read off the two times rather than stored: `dtend_utc`
  # is itself derived from `duration_iso` at write time, and an event with no
  # end has no length to state.
  defp length_of(_local, nil), do: nil

  defp length_of(local, ends) do
    case DateTime.diff(ends, local, :minute) do
      minutes when minutes <= 0 -> nil
      minutes -> {:value, span(div(minutes, 60), rem(minutes, 60))}
    end
  end

  defp span(0, minutes), do: "#{minutes}m"
  defp span(hours, 0), do: "#{hours}h"
  defp span(hours, minutes), do: "#{hours}h #{minutes}m"

  def render(assigns) do
    event = assigns.event

    ~MOB"""
    <Box
      fill_width={true}
      fill_height={true}
      background={:background}
      layout_direction={Kati.Locale.direction_prop()}
      accessibility_id={Kati.Screens.Identity.of(__MODULE__)}
    >
      <Scroll>
        <Column
          fill_width={true}
          padding_left={21}
          padding_right={21}
          padding_top={64}
          padding_bottom={40}
        >
          {Kati.Screens.EventDetail.chrome(event)}
          {Kati.Screens.EventDetail.title_card(event)}
          {Kati.Screens.EventDetail.fields(event)}
          {Kati.Screens.EventDetail.clash(event)}
          {Kati.Screens.EventDetail.muted_eyebrow("Invitees")}
          {Kati.Screens.EventDetail.invitees(event)}
          {Kati.Screens.EventDetail.delete(event)}
        </Column>
      </Scroll>
    </Box>
    """
  end

  @doc false
  def chrome(event) do
    close = {self(), :close}

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        {Kati.Screens.EventDetail.close_disc(close)}
        <Spacer weight={1.0} />
        <Text
          text="Edit event"
          text_size={15}
          font_weight="bold"
          text_color={:on_surface}
          max_lines={1}
        />
        <Spacer weight={1.0} />
        {Kati.Screens.EventDetail.save_pill(event)}
      </Row>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  The dismissal disc — `Kati.Components.MishkaCloseButton`, the same call
  screen 33's sheet makes.

  `variant: :filled` alone paints a flat patch; the `shadow` is what makes it a
  floating disc, and this design's is `Theme.shadow_button()`. That prop is new
  this round and is the reason this stopped being a hand-rolled Box.

  The glyph is a child rather than `icon:` — the shorthand's `Text` carries no
  `font_family`, so the component's default ✕ would fall to Plus Jakarta Sans,
  which has no U+2716.
  """
  def close_disc(tap) do
    MishkaCloseButton.close_button(
      %{
        size: 44,
        shape: :circle,
        variant: :filled,
        # The card token, not `on_ink`/`fab_glyph`/`on_media`: a disc is a
        # surface floating above the page, so it follows the ground.
        background: Palette.card(),
        shadow: Theme.shadow_button(),
        on_tap: tap
      },
      [UI.symbol("close", size: 21)]
    )
  end

  @doc """
  The Save pill.

  It used to carry no `on_tap` at all, on the grounds that *"this screen has no
  commit to make until an event is a real record"*. An event IS a real record
  now: `mount/3` takes `%{id: id}`, `stored/1` reads that row and `shaped/1`
  keeps its `:id`, so the sentence stopped being true the round screen 02's
  timeline started naming its own events.

  **It is still inert on the drawn event, and by the same clause rather than
  by a second one.** `Kati.Calendar.SampleEvent.event/0` has no `:id`, so
  `save_tap/1` answers `nil` and `Kati.Components.MishkaPill` omits the prop
  entirely — the drawn pill is the node it always was, down to the absent key,
  and it draws no `accessibility_id` for a control that would have nothing to
  write. A tap that silently does nothing is worse than no tap, which is
  `Kati.Screens.Account.row_tap/3`'s rule on the same kind of decision.

  What it commits is one field, and that is not a shortfall being hidden — it
  is the whole of what this page can edit. The title is a `Text`, not a
  `TextField`; the section chips have no column and are empty on a stored
  event; the clash buttons are inert by a design decision this file argues
  separately. The timezone row's switch is the one control here whose state a
  column holds, so it is the one thing Save has to save. See `save/1`.

  `padding: 0` is not decoration: a pill always writes a `padding` key
  defaulting to `:space_sm`, and `MobBridge.kt` resolves an unspecified edge
  against that uniform (`pad(v) = (v ?: uniform ?: 0)`), so the two horizontal
  edges alone would leave the pill padded top and bottom as well.
  """
  def save_pill(event) do
    MishkaPill.pill(
      label: "Save",
      on_tap: Kati.Screens.EventDetail.save_tap(event),
      background: Palette.ink_fill(),
      color: Palette.on_ink(),
      height: 38,
      corner_radius: 19,
      padding: 0,
      padding_left: 16,
      padding_right: 16,
      text_size: 13,
      font_weight: :bold,
      align: :center
    )
  end

  @doc false
  def title_card(event) do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        shadow={Theme.shadow_card_soft()}
        padding={18}
      >
        <Row fill_width={true} align="center">
          <Text
            text={event.title}
            text_size={22}
            font_weight="bold"
            letter_spacing={-0.025}
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={3} />
          <Box width={2} height={22} background={Palette.accent()} />
        </Row>
        {Kati.Screens.EventDetail.sections_row(event.sections)}
      </Column>
      <Spacer size={14} />
    </Column>
    """
  end

  @doc """
  The label glyph and the section chips, or nothing at all.

  Nothing at all is the stored event's answer: no column says which section an
  event is in, and a row holding only the `label` glyph would be a control with
  its subject missing. The 12 of space above it belongs to the row, so it goes
  with it — a gap under a title with nothing under the gap is the shape of
  something that failed to render.
  """
  @spec sections_row([{String.t(), boolean()}]) :: map()
  def sections_row([]), do: ~MOB"<Spacer size={0} />"

  def sections_row(sections) do
    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={12} />
      <Row fill_width={true} align="center">
        {UI.symbol("label", size: 16, color: Palette.sub())}
        <Spacer size={8} />
        {sections
         |> Enum.map(fn {label, on?} -> Kati.Screens.EventDetail.section_chip(label, on?) end)
         |> Enum.intersperse(Kati.Screens.EventDetail.chip_gap())}
      </Row>
    </Column>
    """
  end

  @doc false
  def chip_gap, do: ~MOB"<Spacer size={6} />"

  @doc """
  A section: `Kati.Components.MishkaChip`, which is what this actually is.

  A chip is *selected*, and an event lives in exactly one section, so `checked`
  carries the whole of the state and the four colour props carry both halves of
  the drawing — `on_ink` on `ink_fill` when picked, `sub` on `paper` when not,
  which in light is ink on `#FBFAF8` and `#8A8479` on `#EFECE7`. Until this
  round `unchecked_color` and `unchecked_text_color` were hardcoded and the chip
  could not draw the resting half at all.

  The tag carries the label, so a third section is a change to the event and
  not to this file.

  ## Why the pixels do not move

  The chip builds a `Box` where this wrote a `Row`, and the two hug alike:
  `MobBridge.kt`'s box branch hugs on `fill_width == false` (fence K-17, which
  the chip passes), and a `Row` never fills unless told. `height: 26` lands
  after the padding in both, `padding_x`/`padding_y` write all four edges so no
  uniform leaks in, and the single `Text` fills the content box, so
  `align: :center` on the Box and `align="center"` on the Row centre the same
  rectangle. `font_weight: :semibold` reaches the bridge as the string
  `"semibold"` — `Mob.Renderer` writes an atom as its own name.
  """
  def section_chip(label, on?) do
    tap = {self(), String.to_atom("section_" <> label)}

    MishkaChip.chip(
      label: label,
      checked: on?,
      # A checked chip is an ink-FILLED control — `ink_fill`, with `on_ink` on
      # it — and the resting one is a patch of the PAGE sitting on a card, which
      # is `paper` and not `tab_well`, the other token carrying `0xFFEFECE7`.
      color: Palette.ink_fill(),
      text_color: Palette.on_ink(),
      unchecked_color: Palette.paper(),
      unchecked_text_color: Palette.sub(),
      height: 26,
      corner_radius: 13,
      padding_x: 11,
      padding_y: 0,
      text_size: 11.5,
      font_weight: :semibold,
      max_lines: 1,
      on_toggle: tap
    )
  end

  @doc false
  def fields(event) do
    last = length(event.fields) - 1

    ~MOB"""
    <Column fill_width={true}>
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
        {event.fields
         |> Enum.with_index()
         |> Enum.map(fn {row, i} -> Kati.Screens.EventDetail.field_row(row, i < last) end)}
      </Column>
      <Spacer size={14} />
    </Column>
    """
  end

  @doc false
  def field_row(row, rule?) do
    tap = Kati.Screens.EventDetail.field_tap(row)

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_top={13} padding_bottom={13} on_tap={tap}>
        {Kati.Screens.EventDetail.tile(row.icon)}
        <Spacer size={13} />
        <Column weight={1.0}>
          <Text
            text={row.title}
            text_size={13.5}
            font_weight="semibold"
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={3} />
          <Text text={row.sub} text_size={11.5} text_color={Palette.sub()} max_lines={1} />
        </Column>
        <Spacer size={13} />
        {Kati.Screens.EventDetail.trailing(row.trailing)}
      </Row>
      {Kati.Screens.EventDetail.hairline(rule?)}
    </Column>
    """
  end

  @doc """
  The 30x30 paper tile a field row leads with — `Kati.Components.MishkaThemeIcon`,
  documented as "a themed container around exactly one icon", which is exactly
  what this is.

  `variant: :filled` with an explicit `color`, **not** `variant: :white`: the
  white variant paints the theme's `:surface`, which here is `#FBFAF8`, the
  card. The tile is paper, and the two are three values apart.

  The glyph is a child rather than the `icon:` shorthand, whose `Text` carries
  no `font_family` — a Material Symbols ligature would be typeset as the word.

  With children and no `id`, the component returns
  `%{type: :box, props: %{width: 30, height: 30, align: :center,
  corner_radius: 9, background: Palette.paper()}, children: [glyph]}` — node for
  node what this wrote by hand, and `Palette.paper()` is `0xFFEFECE7` in light.
  Nothing else in it runs: the gradient layer is empty for `:filled`, the id
  markers are skipped without an `id`, and the glyph shorthand is skipped when
  children are given.
  """
  def tile(name) do
    MishkaThemeIcon.theme_icon(
      %{variant: :filled, color: Palette.paper(), size: 30, radius: 9},
      [Kati.UI.symbol(name, size: 17, color: Palette.ink_soft())]
    )
  end

  @doc """
  Which detail rows are tappable, and with what tag.

  Only the switch row. The chevron rows name screens that do not exist yet, so
  they get `nil` rather than a tap that lands nowhere, and the duration is a
  reading of the two times above it rather than a control.

  The tag carries the row's title, so the handler finds the row by name
  instead of by an index that a reordered `fields/0` would silently break.
  """
  @spec field_tap(map()) :: {pid(), atom()} | nil
  def field_tap(%{trailing: {:switch, _on?}, title: title}),
    do: {self(), String.to_atom("switch_" <> title)}

  def field_tap(_row), do: nil

  # No trailing at all — an all-day event has no length to put on the right of
  # its own row. Drawn as nothing rather than as an empty value, so the title
  # and sub-line keep the full width they would have had.
  @doc false
  def trailing(nil), do: ~MOB"<Spacer size={0} />"

  def trailing({:value, text}) do
    ~MOB"""
    <Text text={text} font_family="mono" text_size={11} text_color={Palette.muted()} max_lines={1} />
    """
  end

  # The knob is pushed to the trailing edge by a weighted Spacer inside a
  # fixed-width Row, which is what `justify-content:flex-end` is here. A Box
  # would have stacked the knob over the track instead of beside it.
  # The shared switch, not a hand-drawn one. Declaring width/height AND padding
  # on the same Row inflated it to 52x34 and under-rounded the corners, because
  # the bridge applies padding before width.
  def trailing({:switch, on?}), do: Kati.UI.SettingsList.switch(on?)

  # `rail_idle`, and it is right by value and wrong by name. The palette's
  # `tertiary` is the token whose *meaning* is "a faint chevron" — but its light
  # value is `0xFFB3ACA2`, and this chevron is `0xFFC4BDB3`; the design draws two
  # chevron greys and only one of them is `tertiary`. Taking the better name
  # would have moved light mode by seventeen units, so the value wins.
  def trailing(:chevron),
    do: Kati.UI.symbol("chevron_right", size: 18, color: Palette.rail_idle())

  @doc """
  The rule between two rows — `Kati.Components.MishkaSeparator`, and it must be
  `render: :box`.

  The component's default is `:divider`, which the Android bridge maps to
  Material3's `HorizontalDivider`: an **antialiased stroke**, not a filled rect.
  At this device's 2.6875x a 1dp rule gets a 3px canvas and a 2.6875px stroke,
  so the last pixel row lands at ~69% coverage and the hairline is 4-5/255
  lighter on one row than the design's. `render: :box` swaps the primitive for a
  background-filled `Box` — three full rows of `rgba(26,25,23,.07)`, which is
  what this drew by hand.

  The one difference in the tree is the `<Spacer size={1}/>` the `:box` rule
  carries. It is an iOS workaround (`MobBox` drops a Box's height unless the Box
  also has a width), and on Android it is a 1x1dp child with no background
  inside a `Box` already pinned to `fill_width` and `height: 1`. It measures
  nothing new and paints nothing at all.
  """
  def hairline(false), do: ~MOB"<Spacer size={0} />"

  def hairline(true),
    do: MishkaSeparator.separator(render: :box, color: Palette.hairline(), thickness: 1)

  # On cream, and with no shadow: the design's warm card is where the app
  # speaks in its own voice rather than listing a field.
  #
  # The eyebrow moved inside because the two are one thing: `CLASH` over no
  # clash card is a heading for an absence. A stored event has no clash — see
  # the moduledoc on why an uncomputed one is worse than none — so both go.
  @doc false
  def clash(%{clash: nil}), do: ~MOB"<Spacer size={0} />"

  def clash(event) do
    clash = event.clash

    ~MOB"""
    <Column fill_width={true}>
      {UI.eyebrow("Clash")}
      <Column fill_width={true} background={Palette.cream()} corner_radius={20} padding={16}>
        <Row fill_width={true} align="center">
          {UI.symbol("call_split", size: 18, color: Palette.gold_icon())}
          <Spacer size={10} />
          <Text
            text={clash.line}
            text_size={13}
            font_weight="bold"
            text_color={:on_surface}
            weight={1.0}
            max_lines={1}
          />
        </Row>
        <Spacer size={13} />
        <Row fill_width={true} align="center">
          {clash.actions
           |> Enum.map(fn {label, tone} -> Kati.Screens.EventDetail.action(label, tone) end)
           |> Enum.intersperse(Kati.Screens.EventDetail.action_gap())}
        </Row>
      </Column>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc false
  def action_gap, do: ~MOB"<Spacer size={8} />"

  @doc """
  One clash button — `Kati.Components.MishkaPill`, not `MishkaChip`.

  The distinction matters here for a reason the moduledoc already gives: the
  drawing fills **two** of the three and leaves one quiet, which is not a
  selection. A chip's `checked` would say it was, and a reader of this file
  would then look for the handler that changes it. A pill has no state to
  mis-state; the tone picks the two colours and nothing else.
  """
  # The filled pair are `ink_fill`/`on_ink` — screen 28 draws exactly this pill
  # inside exactly this cream card, `#F7EFE4` filled with `#1A1917`. The quiet
  # one is `cream_raise`, "a chip lifted a step off the cream card", which is
  # the meaning of `0x99FFFFFF` here rather than the lock screen's mono meta;
  # its label is the cream card's second line.
  def action(label, :primary), do: action_pill(label, Palette.ink_fill(), Palette.on_ink())
  def action(label, :quiet), do: action_pill(label, Palette.cream_raise(), Palette.cream_sub())

  defp action_pill(label, background, color) do
    MishkaPill.pill(
      label: label,
      background: background,
      color: color,
      height: 34,
      corner_radius: 17,
      padding: 0,
      padding_left: 13,
      padding_right: 13,
      text_size: 11.5,
      font_weight: :semibold,
      align: :center
    )
  end

  # Kati.UI.eyebrow's dash is always the accent; this one is #C4BDB3, which is
  # how the design marks a section that lists rather than warns. That value is
  # `rail_idle` — the only token carrying it — and a 13x2 rule is a rail in all
  # but name; the label is `eyebrow`, which is what it is by both.
  @doc false
  def muted_eyebrow(label) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_left={2} padding_right={2}>
        <Box width={13} height={2} corner_radius={1} background={Palette.rail_idle()} />
        <Spacer size={9} />
        <Text
          text={String.upcase(label)}
          font_family="mono"
          text_size={10.5}
          letter_spacing={0.16}
          text_color={Palette.eyebrow()}
        />
      </Row>
      <Spacer size={11} />
    </Column>
    """
  end

  @doc false
  def invitees(event) do
    ~MOB"""
    <Column fill_width={true}>
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
        {Enum.map(event.invitees, fn person -> Kati.Screens.EventDetail.invitee_row(person) end)}
        {Kati.Screens.EventDetail.add_someone()}
      </Column>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc false
  def invitee_row(person) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_top={11} padding_bottom={11}>
        {Kati.Screens.EventDetail.avatar(person)}
        <Spacer size={13} />
        <Column weight={1.0}>
          <Text
            text={person.name}
            text_size={13}
            font_weight="semibold"
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={2} />
          <Text text={person.sub} text_size={11} text_color={Palette.sub()} max_lines={1} />
        </Column>
        <Spacer size={13} />
        {Kati.Screens.EventDetail.reply(person.state)}
      </Row>
      {Kati.Screens.EventDetail.hairline(true)}
    </Column>
    """
  end

  @doc """
  The invitee's face: `Kati.Components.MishkaAvatar` at the drawing's own numbers.

  The two hand-rolled clauses this replaces were the component's two branches
  spelled out — a 34pt circle of `#E4E0D9` when there is no picture, the picture
  clipped to the same circle when there is — so the swap is the same nodes with
  the case moved inside `avatar/2`.

  `shape: :circle` resolves to an exact `size / 2`, which is the 17 that was
  written here by hand. When a `src` is present the component stacks the
  fallback *under* the image rather than choosing between them, so `background`
  carries the same `#E4E0D9` in both branches: it is what shows for the instant
  before Coil has the bitmap, and is covered by an opaque poster afterwards.
  """
  def avatar(person) do
    MishkaAvatar.avatar(
      src: Images.poster(person.seed),
      size: 34,
      shape: :circle,
      background: Palette.placeholder()
    )
  end

  # Green is a `:hue` and does not move with the ground. The waiting clock is
  # `rail_idle` by value, for the reason `trailing(:chevron)` records.
  @doc false
  def reply(:accepted),
    do: Kati.UI.symbol("check_circle", size: 18, color: Palette.green(), fill: true)

  def reply(:waiting), do: Kati.UI.symbol("schedule", size: 18, color: Palette.rail_idle())

  @doc """
  The add affordance. Its ring is `Kati.Components.MishkaThemeIcon` at
  `variant: :subtle` — the variant that paints **nothing** — with the border
  overridden onto it.

  `:subtle`'s skin carries `background: nil`, which the component leaves off the
  node rather than sending as a null, so the container is the empty box the
  drawing has. `border_color` is documented as replacing the variant's choice
  "or drawing one where it has none", which is this case; `border_width` is read
  with `floatProp`, so the design's 1.5 survives.

  Solid, not dashed: the bridge's border is `Modifier.border`, which takes a
  width and a colour and no `PathEffect`.
  """
  def add_someone do
    ~MOB"""
    <Row fill_width={true} align="center" padding_top={11} padding_bottom={11}>
      {Kati.Screens.EventDetail.add_ring()}
      <Spacer size={13} />
      <Text
        text="Add someone"
        text_size={13}
        font_weight="semibold"
        text_color={Palette.sub()}
        weight={1.0}
        max_lines={1}
      />
    </Row>
    """
  end

  @doc false
  def add_ring do
    MishkaThemeIcon.theme_icon(
      %{
        variant: :subtle,
        size: 34,
        radius: 17,
        # 20% ink on a small subtle disc, which is `border_stronger` by both
        # value and words. The tint keeps its alpha and swaps its base in dark.
        border_color: Palette.border_stronger(),
        border_width: 1.5
      },
      [Kati.UI.symbol("add", size: 16, color: Palette.sub())]
    )
  end

  @doc """
  The two writes this page can make, as the tags their controls carry — or
  `nil` on the drawn event, which is no row and has nothing to write.

  One predicate for both, because it is one fact: `shaped/1` keeps the stored
  row's `:id` and `Kati.Calendar.SampleEvent.event/0` has none. That is also
  what keeps the page the design gates and both tap sweeps see byte-identical
  to the page they have always seen — a `nil` tap draws no `accessibility_id`
  and `Kati.ScreenSweep.tap_tags/1` does not collect it, so neither control can
  join `@inert_taps` by being drawn over nothing.

  Separate from the section chips and the timezone switch, which are socket
  state on both branches and stay live either way.
  """
  @spec save_tap(map()) :: atom() | nil
  def save_tap(event), do: if(writable?(event), do: :save)

  @doc false
  @spec delete_tap(map()) :: {pid(), atom()} | nil
  def delete_tap(event), do: if(writable?(event), do: {self(), :delete_event})

  defp writable?(event) do
    case Map.get(event, :id) do
      id when is_binary(id) and id != "" -> true
      _no_row -> false
    end
  end

  # Outlined in red rather than filled: destructive, and one tap away from
  # nothing. The design gives it no background at all.
  @doc false
  def delete(event) do
    tap = Kati.Screens.EventDetail.delete_tap(event)

    ~MOB"""
    <Box
      fill_width={true}
      height={48}
      corner_radius={24}
      border_color={Palette.red_ring()}
      border_width={1.5}
      align="center"
      on_tap={tap}
    >
      <Row align="center">
        {UI.symbol("delete", size: 18, color: Palette.red())}
        <Spacer size={8} />
        <Text
          text="Delete event"
          text_size={13}
          font_weight="bold"
          text_color={Palette.red()}
          max_lines={1}
        />
      </Row>
    </Box>
    """
  end

  def handle_info({:tap, :close}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}

  def handle_info({:tap, :save}, socket), do: {:noreply, Kati.Screens.EventDetail.save(socket)}

  def handle_info({:tap, :delete_event}, socket),
    do: {:noreply, Kati.Screens.EventDetail.delete_event(socket)}

  # One clause for every chip and every switch on the screen: the tag carries
  # the label, so a third section or a second switch is a change to
  # `Kati.Calendar.SampleEvent` rather than to this file.
  def handle_info({:tap, tag}, socket) do
    event = socket.assigns.event

    case Atom.to_string(tag) do
      # An event lives in one section, so picking one drops the other. The
      # drawing shows exactly one chip filled, and a multi-select would be able
      # to draw states the design never does.
      "section_" <> label ->
        sections = Enum.map(event.sections, fn {name, _on?} -> {name, name == label} end)
        {:noreply, Mob.Socket.assign(socket, :event, %{event | sections: sections})}

      "switch_" <> title ->
        fields =
          Enum.map(event.fields, fn field ->
            case field do
              %{title: ^title, trailing: {:switch, on?}} ->
                %{field | trailing: {:switch, not on?}}

              other ->
                other
            end
          end)

        {:noreply, Mob.Socket.assign(socket, :event, %{event | fields: fields})}

      _other ->
        {:noreply, socket}
    end
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  @doc """
  Commit the one field this page can edit: whether the event follows travel.

  `tz_behaviour` is the column behind the timezone row's switch, and the switch
  is the only control on a stored event whose state anything stores — see
  `save_pill/1`. Off is `:fixed` rather than `:floating`, and the row itself
  says why: `zone_field/1` only draws at all when `tzid` is a real zone, and
  `:floating` is the value that means there is none.

  The page is then READ BACK rather than left holding what it asked for, which
  is `Kati.Screens.Goals.toggle_repeat/2`'s contract as a page: a switch that
  snaps back to whatever the store actually says, and a row deleted underneath
  the screen falling to the drawing rather than staying editable.

  The drawn event never reaches here — `save_tap/1` draws it no tap — so there
  is no branch for it and no saved-nothing message on a page that draws no
  place for one.
  """
  @spec save(Mob.Socket.t()) :: Mob.Socket.t()
  def save(socket) do
    event = socket.assigns.event

    with id when is_binary(id) <- Map.get(event, :id),
         %{trailing: {:switch, travels?}} <-
           Enum.find(event.fields, &match?(%{trailing: {:switch, _on?}}, &1)),
         {:ok, stored} <- Ash.get(Event, id) do
      stored
      |> Ash.update(%{tz_behaviour: if(travels?, do: :device, else: :fixed)})
      |> Kati.Write.note("event timezone")

      Mob.Socket.assign(socket, :event, Kati.Screens.EventDetail.event(%{id: id}))
    else
      _nothing_to_save -> socket
    end
  rescue
    # No store at all — the same state `stored/1` rescues, one write later.
    # `Kati.Screens.Goals.write_repeat/2` is the precedent for the shape: the
    # failure is reported to the log rather than swallowed, and the page is
    # left as it stands.
    error ->
      Kati.Write.note({:error, error}, "event timezone")
      socket
  end

  @doc """
  Tombstone this event and leave.

  `:soft_delete` rather than `:destroy`, which is the resource's own decision
  and its own words: *"A synced row that vanishes cannot be told apart from one
  that never existed, and the other end would resurrect it."*

  The screen closes only if the write landed. A page that dismissed itself over
  a failed delete would be the sheet-closing-on-failure defect `Kati.Write`
  exists to name, said with a whole screen instead of a sheet.
  """
  @spec delete_event(Mob.Socket.t()) :: Mob.Socket.t()
  def delete_event(socket) do
    with id when is_binary(id) <- Map.get(socket.assigns.event, :id),
         {:ok, stored} <- Ash.get(Event, id),
         {:ok, _tombstone} <-
           Kati.Write.note(Ash.update(stored, %{}, action: :soft_delete), "event delete") do
      Mob.Socket.pop_screen(socket)
    else
      _no_write -> socket
    end
  rescue
    error ->
      Kati.Write.note({:error, error}, "event delete")
      socket
  end
end
