defmodule Kati.Screens.Calendars do
  @moduledoc """
  Screen 32 — Calendars, pushed under Settings.

  Built to `test/design/screens/32.html`. Two-way sync stated plainly, in
  three groups that answer three different questions: which accounts come in,
  which of their calendars are drawn, and exactly what Kati is allowed to
  write out.

  Write back gets the grey dash rather than the orange one. It is the
  consequence of the two groups above it — you cannot push to a calendar you
  have not connected — and orange means new/now.

  Each calendar row leads with a 12pt swatch instead of an icon tile, because
  the colour is the thing being configured: it is what the imported events
  will be drawn in on screens 02 and 09.

  No dock — pushed screen — so the frame closes at 40, not 132.

  ## Components, and the one that does not fit

  Every row on this screen is `Kati.UI.SettingsList.row/4`, so the leading
  tiles, the rules and the status pills are that module's business. What this
  file owns is the two leadings the shared recipe has no clause for:

    * `add_tile/0` — `Kati.Components.MishkaThemeIcon` at `variant: :subtle`,
      the variant that paints nothing, with the drawing's ring passed as
      `border_color` / `border_width`. Both of those are new this round; before
      them the component could only draw a filled or tinted tile.
    * `swatch/1` — **still a `Box`**. `Kati.Components.MishkaColorSwatch` is
      the obvious candidate and cannot be used: it draws a hairline
      unconditionally (`border_color: :border`, `border_width: 1` when
      unselected, `:on_surface` at 2 when selected) with no prop to turn it
      off, and the design's 12pt calendar swatch is a bare fill. A ring around
      each one would change every calendar row. The prop it needs upstream is
      a `border_color` that can be `nil` — the same escape `MishkaThemeIcon`
      already has in the other direction.

  ## Which of the three groups is real, and which are not

  The screen's own structure is three groups answering three different
  questions, so they are answered separately rather than gated as one — the
  middle one is `Kati.Calendars.Calendar` and the other two have nothing behind
  them yet.

    * **"Which calendars show" is real.** `calendar_list/0` reads
      `Kati.Calendars.Calendar` and falls back to `Kati.Settings.CalendarsSample`
      when there is none, exactly as `Kati.Screens.Library.titles/0` does. Every
      field the group draws is a column: `display_name` is the title,
      `visible` is the switch, and `colour_token` is the swatch — which is
      precisely what that column is for, since `colour_source` keeps the
      provider's own value and is documented as never rendered.

    * **Accounts stay on the Sample, and the icon is why.** Title, subtitle and
      the Live/Stale pill are all derivable — `account_name`, a count of the
      account's calendars, `last_sync_at`, `state`. The 30pt tile's glyph is
      not: the drawing distinguishes iCloud (`cloud`), Google (`mail`) and
      Fastmail-over-CalDAV (`dns`), and `Kati.Calendars.Account.provider`
      collapses the first and third into one `:caldav`. `Kati.Seeds` says the
      same thing from the other side — *"the drawing has no way to say 'this
      iCloud row is CalDAV underneath'"* — and the reverse is just as true.
      Deriving the glyph from `provider` would draw `dns` where the design
      draws `cloud`, so the group is left whole rather than moved with one
      field wrong. What it needs is a service/brand slot on the account, or a
      `provider` value set that separates iCloud from a generic CalDAV
      principal.

    * **Write back stays on the Sample too**, and for a plainer reason: its
      three rows are Kati's own event categories — air dates, habits, renewals
      — and nothing stores a per-category push preference.
      `Kati.Calendars.Calendar.writeback_policy` is per *calendar*, which is
      the wrong axis and would answer a different question than the one the
      group asks.
  """
  use Kati.Screens.Pushed, back: "Settings"

  # Deliberately aliased away from `Calendar`: the bare name is Elixir's own
  # module, and shadowing it here would be a trap for the next function that
  # wants `Calendar.strftime/2`. `Kati.Seeds` aliases it the same way.
  alias Kati.Calendars.Calendar, as: CalendarRow
  alias Kati.Components.MishkaThemeIcon
  alias Kati.Settings.CalendarsSample, as: Sample
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  @impl true
  def load(socket) do
    Mob.Socket.assign(socket, :calendars, %{
      connected: Sample.connected(),
      accounts: Sample.accounts(),
      add_account: Sample.add_account(),
      calendars: calendar_list(),
      write_back: Sample.write_back(),
      note: Sample.note()
    })
  end

  @doc """
  The calendars the middle group draws: the device's own, or the drawing's.

  `stored_calendars/0` answers with nothing on a fresh install, and four rows
  of nothing cannot be compared with `.scratch/design/audit/32.png` — the
  swatches, the three ticked switches and the one greyed title would all go
  unexercised. The same rule `Kati.Screens.Library.titles/0` states applies
  here: *missing data is not a reason for a blank screen*.
  """
  @spec calendar_list() :: [map()]
  def calendar_list do
    case stored_calendars() do
      [] -> drawn_calendars()
      rows -> rows
    end
  end

  @doc """
  Every calendar Kati knows about, in the order it learnt about them.

  One query, no join: the group draws nothing that belongs to the account, so
  nothing about the account is loaded. Ordered by `inserted_at` because there
  is no position column and none should be invented — the order a calendar
  arrived in is the only order the schema actually holds, and it is the order
  `Kati.Seeds` writes the drawing's four in. `id` breaks a tie so the list is
  stable rather than merely usually stable.

  **A calendar with no `display_name` is dropped.** The row is a title and a
  switch, and a switch labelled `nil` is not a control — the same call
  `Kati.Screens.Library.shelf/0` makes for a title whose cache row was evicted.
  Every writer in the app sets a name (`Kati.Calendars.DeviceImport` falls back
  to `"Calendar"`), so this is the column's nullability being honoured rather
  than a case anything is expected to hit.
  """
  @spec stored_calendars() :: [map()]
  def stored_calendars do
    CalendarRow
    |> Ash.Query.sort(inserted_at: :asc, id: :asc)
    |> Ash.read!()
    |> Enum.map(&shaped/1)
    |> Enum.reject(&(&1.title == nil))
  rescue
    # The degradation `Kati.Calendars.Today` and `Kati.Screens.Library.shelf/0`
    # both make: a screen that cannot reach its store draws the drawing rather
    # than taking the push down.
    _ -> []
  end

  @doc "The four calendars `test/design/screens/32.html` draws, in its order."
  @spec drawn_calendars() :: [map()]
  def drawn_calendars, do: Sample.calendars()

  @doc """
  One calendar in the shape `calendar_row/3`, `calendar_title/1` and `swatch/1`
  all read — the three keys `Kati.Settings.CalendarsSample.calendars/0`
  produces, plus the handle a stored row has and a drawing does not.

  `:id` is what makes this row's switch a switch about THIS calendar rather
  than about calendars in general, which is the same argument
  `Kati.Screens.Goals` makes for the same key on the same kind of control. The
  drawing's rows have no id and cannot borrow one, so `row_tag/2` falls back to
  their position and `Kati.Settings.CalendarsSample.calendars/0` is left
  exactly as it is — which is what keeps `calendar_list/0` equal to
  `drawn_calendars/0` term for term on an empty store, and keeps
  `Kati.ScreenCalendarsTest`'s `calendar_list() == Sample.calendars()` true.
  """
  @spec shaped(CalendarRow.t()) :: map()
  def shaped(row) do
    %{
      id: row.id,
      color: swatch_colour(row.colour_token),
      title: row.display_name,
      on: row.visible
    }
  end

  @doc """
  The 12pt swatch's fill, resolved from the calendar's palette slot.

  `Kati.Theme.Palette.token/1` rather than a mapping written out here: the
  column holds a token name and the table is what token names mean, so a slot
  added to the palette needs no clause. In light the drawing's four resolve to
  the four literals the Sample carries — `:ink` is `0xFF1A1917`, `:green`
  `0xFF4E9A73`, `:bronze` `0xFFB08E55`, `:rail_idle` `0xFFC4BDB3` — and in
  dark they follow the theme, which a literal could not.

  **A calendar with no slot is drawn in `rail_idle`**, and that is the one
  place this screen falls short of what it draws.
  `Kati.Calendars.DeviceImport` stores `colour_source` and never sets
  `colour_token`, so every calendar imported from the device provider has no
  palette slot at all — nothing in the app maps a provider's own colour onto
  one. Until something does, they are all the design's "exists, no colour of
  its own" grey. Inventing a colour per calendar would be worse: the swatch's
  whole meaning is *this is what your events will be drawn in*, and a colour
  chosen here is not one anything else would honour.
  """
  @spec swatch_colour(atom() | nil) :: pos_integer()
  def swatch_colour(token) when is_atom(token) and not is_nil(token) do
    if token in Palette.names(), do: Palette.token(token), else: Palette.rail_idle()
  end

  def swatch_colour(_token), do: Palette.rail_idle()

  @doc false
  def content(assigns) do
    c = assigns.calendars

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {SettingsList.chrome("more_horiz")}
        {SettingsList.title("Calendars", c.connected, nil, :meta_tight)}
        {UI.eyebrow("Accounts")}
        {Kati.Screens.Calendars.accounts(c)}
        {UI.eyebrow("Which calendars show")}
        {Kati.Screens.Calendars.calendars(c.calendars)}
        {SettingsList.eyebrow_muted("Write back")}
        {Kati.Screens.Calendars.write_back(c.write_back)}
        {SettingsList.note("lock", c.note)}
      </Column>
    </Scroll>
    """
  end

  @doc false
  def accounts(c) do
    rows =
      Enum.map(c.accounts, fn a -> Kati.Screens.Calendars.account_row(a) end) ++
        [Kati.Screens.Calendars.add_row(c.add_account)]

    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.card(rows)}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def account_row(a) do
    SettingsList.row(
      SettingsList.icon_tile(a.icon),
      SettingsList.body(a.title, a.sub),
      Kati.Screens.Calendars.status(a.status, a.state),
      padding: 13
    )
  end

  @doc false
  def status(label, :live),
    do: SettingsList.status_pill(label, Palette.green_text(), Palette.green_wash())

  def status(label, :stale),
    do: SettingsList.status_pill(label, Palette.red(), Palette.red_wash_strong())

  # The one row with no trailing control and no filled tile: a dashed square
  # that reads as a slot waiting to be filled rather than a button.
  @doc false
  def add_row(label) do
    SettingsList.row(
      Kati.Screens.Calendars.add_tile(),
      SettingsList.body_muted(label),
      nil,
      padding: 13,
      rule: false
    )
  end

  @doc """
  The empty slot: `Kati.Components.MishkaThemeIcon` at `variant: :subtle` — the
  variant that paints nothing — with the drawing's ring overridden onto it.

  `:subtle`'s skin carries `background: nil`, which the component leaves off the
  node rather than sending as a null, so this really is an unfilled box.
  `border_color` is documented as drawing a border where the variant has none,
  which is the case here, and `border_width` is read with `floatProp`, so the
  design's 1.5 survives where an `intProp` would truncate it to 1.

  The glyph is a child rather than the `icon:` shorthand — the shorthand's
  `Text` carries no `font_family`, so the `add` ligature would be typeset as the
  word.

  ## Why the pixels do not move

  With children and no `id` the component returns
  `%{type: :box, props: %{width: 30, height: 30, align: :center,
  corner_radius: 9, border_color: Palette.border_stronger(), border_width: 1.5},
  children: [glyph]}` — node for node what this wrote by hand, with `align`
  reaching the bridge as the same `"center"` either way. `border_stronger/0` is
  `0x331A1917` in light — the literal this used to carry, unchanged — and the
  same 20% alpha over ink-on-dark in dark.

  Solid, not dashed: `Modifier.border` takes a width and a colour and no
  `PathEffect`, so the stitching does not survive.
  """
  def add_tile do
    MishkaThemeIcon.theme_icon(
      %{
        variant: :subtle,
        size: 30,
        radius: 9,
        border_color: Palette.border_stronger(),
        border_width: 1.5
      },
      [Kati.UI.symbol("add", size: 16, color: Palette.sub())]
    )
  end

  @doc false
  def calendars(rows) do
    last = length(rows) - 1

    body =
      rows
      |> Enum.with_index()
      |> Enum.map(fn {row, i} -> Kati.Screens.Calendars.calendar_row(row, i, i < last) end)

    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.card(body)}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def calendar_row(row, index, rule?) do
    SettingsList.row(
      Kati.Screens.Calendars.swatch(row.color),
      Kati.Screens.Calendars.calendar_title(row),
      SettingsList.switch(row.on),
      padding: 13,
      rule: rule?,
      on_tap: {self(), Kati.Screens.Calendars.row_tag(row, index)}
    )
  end

  @doc """
  A calendar's switch, as an atom naming the calendar it belongs to.

  On the row rather than on the control: `Kati.UI.SettingsList.switch/1` takes
  a boolean and nothing else, and its own doc says why — `on_toggle` is the
  prop to reach for when these rows go live, and reaching for it would put a
  tap target on a 46x28 track, under the 44x44 screen 41 promises. The row is
  taller than that and `Kati.UI.SettingsList.row/4` already takes the tap.

  An atom rather than a tuple, for the reason `Kati.Screens.Goals`'s repeat
  switch states: `Mob.Renderer` emits an `accessibility_id` only for an atom
  tag, so a tuple-tagged switch fires on device and is invisible to every
  sweep.

  The drawing's four have no id and are tagged by the position the drawing
  draws them in, held in their own `calendar_drawn_` namespace so a device test
  can tell which page it is looking at.
  """
  @spec row_tag(map(), non_neg_integer()) :: atom()
  def row_tag(%{id: id}, _index) when is_binary(id), do: String.to_atom("calendar_" <> id)

  def row_tag(_row, index), do: String.to_atom("calendar_drawn_" <> Integer.to_string(index))

  @doc false
  def swatch(color) do
    ~MOB"""
    <Box width={12} height={12} corner_radius={4} background={color} />
    """
  end

  # A calendar that is not drawn has a grey title as well as a grey swatch, so
  # the row reads as off at a glance rather than only at the switch.
  @doc false
  def calendar_title(%{on: true, title: title}), do: SettingsList.body(title)
  def calendar_title(%{title: title}), do: SettingsList.body_muted(title)

  @doc false
  def write_back(rows) do
    last = length(rows) - 1

    body =
      rows
      |> Enum.with_index()
      |> Enum.map(fn {row, i} -> Kati.Screens.Calendars.write_row(row, i < last) end)

    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.card(body)}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def write_row(row, rule?) do
    SettingsList.row(
      SettingsList.icon_tile(row.icon),
      SettingsList.body(row.title, row.sub),
      SettingsList.switch(row.on),
      padding: 13,
      rule: rule?
    )
  end

  # The middle group is the one with a resource behind it — the moduledoc says
  # so at length — so it is the one group that answers a tap. The accounts and
  # the Write back rows are still `Kati.Settings.CalendarsSample`'s and still
  # carry no tap of their own, which is why there is nothing above this clause.
  @impl true
  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      # A drawn row has nothing to write to, so its switch is moved in place —
      # `Kati.Screens.Goals`' exact call on the same question, and for its exact
      # reason: the alternative is a control that visibly does nothing on the
      # page most people meet first, since a fresh install has no calendars.
      # Board 32 draws both states already — Birthdays is the row it draws off,
      # greyed label and all — so every state this can reach is a state the
      # board words.
      "calendar_drawn_" <> index ->
        {:noreply, flip_drawn(socket, String.to_integer(index))}

      # A stored row is written and then the page is READ BACK, rather than the
      # switch being moved on the strength of having asked. That is `Kati.Write`'s
      # contract as a page: a switch that snaps back to whatever the store
      # actually says, and a row deleted underneath the screen dropping out of
      # the list rather than leaving a switch that toggles a calendar nobody has.
      "calendar_" <> id ->
        {:noreply, write_visible(socket, id)}

      _other ->
        {:noreply, socket}
    end
  end

  defp flip_drawn(socket, index) do
    c = socket.assigns.calendars
    rows = List.update_at(c.calendars, index, fn row -> %{row | on: not row.on} end)

    Mob.Socket.assign(socket, :calendars, %{c | calendars: rows})
  end

  defp write_visible(socket, id) do
    with {:ok, row} <- Ash.get(CalendarRow, id) do
      Ash.update(row, %{visible: not row.visible})
    end
    |> Kati.Write.note("calendar visible")

    c = socket.assigns.calendars
    rows = Kati.Screens.Calendars.calendar_list()

    Mob.Socket.assign(socket, :calendars, %{c | calendars: rows})
  rescue
    # No store at all — the same state `stored_calendars/0` rescues, one write
    # later. `Kati.Screens.Goals.write_repeat/2` is the shape.
    error ->
      Kati.Write.note({:error, error}, "calendar visible")
      socket
  end
end
