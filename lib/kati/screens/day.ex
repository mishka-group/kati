defmodule Kati.Screens.Day do
  @moduledoc """
  Screen 09 — a heavy day, and the density rules.

  A time-gutter timeline: a mono time column on the left, one card per item
  on the right. Clashes split that right-hand side into lanes, capped at
  two, with a `+n MORE` tile in the trailing lane when a cluster needs more.
  `Kati.Calendar.Layout` hands that tile back separately because it is not
  part of the column grid; the drawing still puts it inside the split row, at
  a fixed 44pt, so `lanes/1` appends it there rather than under the row.

  The lane widths are **weights, never pixels**. `Kati.Calendar.Layout`
  emits `{col, span, n_cols}` and each card carries `weight = span`, so
  Compose resolves the real widths at layout time, at the device's actual
  density (`MobBridge.kt:2195-2200`). Elixir cannot do that arithmetic —
  `Mob.Device` reports battery, thermal, network, orientation and model, and
  no screen size at all — which is why the engine is built to need only
  proportions.

  Deliberately **not** an absolutely-positioned grid. The design calls for a
  gutter timeline, so vertical placement is ordinary stacking and the
  `offset_x`/`offset_y` props stay unused. Those are not Mob API — they
  appear nowhere in `mob/lib`, `mob/guides` or `mob/priv` — and a screen
  this central should not be the first thing to depend on a prop with no
  upstream contract.

  ## The chips

  `Screen · Personal · Money`, each with the day's own count, narrow the
  timeline to one kind.

  There is no `All` chip, unlike screen 02, and the drawing shows the first
  chip in ink above a timeline holding **every** kind. So the resting state is
  *the whole day with the first chip lit*, and that is what `filter: nil` is.
  `lit/2` lights the first chip for it, and tapping the kind already showing
  widens back to it — the screen would otherwise have three states and no way
  home.

  ## The grouped card opens

  Screen 09 draws the 20:00 group **collapsed** — a poster stack, a count tile
  and a chevron disc — and its own caption says where the other half is drawn:
  *"tap the one on 02 to expand it"*. So the expanded state's geometry comes
  from `test/design/screens/02.html`, which draws it under
  `<sc-if value="{{ groupOpen }}">`: the members go **inside** the card, below
  a 13/4 gap either side of an 8%-ink hairline, one 26x37 poster per member
  with the title, the episode line and the member's own clock on the trailing
  edge.

  That is why the members are not `Kati.Screens.Calendar`'s `airing_row/1`
  read across: that one indents rows *under* the card on the page, which is
  the shape 02's own drawing does not have. The composition is the same —
  `group_members/2` is `with_members/3` — and the numbers are 02's.

  Collapsed is the resting state and nothing about it moved: the header row
  keeps every prop it had, and the card's fill, radius, shadow and 14 of
  padding moved one level out to the `<Column>` that now holds the header row
  and the members. A `<Column fill_width>` with one `fill_width` `<Row>` in it
  measures what the `<Row>` measured alone.

  ## Which day

  A push carrying `%{date: date}` — what `Kati.Screens.Calendar`'s open
  gesture, the month grid and the week lanes send — titles this screen with
  that date and draws that day's own events out of `Kati.Calendars.Event`. A
  push carrying nothing draws the day the calendar has selected —
  `Kati.Calendars.SelectedDate`, which is today unless the reader picked
  another. `day/1` is the whole of that decision.

  ## Why a real day is thinner than the drawing

  `Kati.Calendars.Today.occurrences/1` returns the day in the shape
  `Kati.Calendar.Layout` takes, ids included. What it does not return is the
  rest of the drawing, and the five things below are why. So the day draws its
  cards, its lanes, its clashes and its own count, and **draws none of the
  furniture that would have to be invented** — the all-day band, a merged
  renewals total, and chip counts or a headline it cannot count.

    * **Most of the episodes.** A followed show's airing is not an event —
      `Kati.Calendars.Event` carries no `{source, source_id}` pair — so it
      comes from `Kati.Calendars.Airings`, which reads the air date off
      `Kati.Media.CachedEpisode` and joins it to its show, poster and `S · E`
      line (`Kati.Calendars.Airings.occurrences/1`). A followed film's release
      comes the same way. The ones with an HOUR are laned; a day-only air
      date has no minute to sit at, so it is listed under *All day* above the
      timeline (`all_day/1`) and counted with the rest. Leaving it off made
      this page say *Nothing scheduled* for a day the month grid had just
      dotted and listed. A tap on one opens the show or the film, not
      screen 31.

    * **The tick.** `done` on the 08:00 habit and on the 15:00 todo has no
      column anywhere: `Kati.Calendars.Event` models timing, identity, kind and
      sync bookkeeping, and nothing about completion. `handle_tap/2`'s
      `"todo_" <> id` clause would go on flipping a flag with nowhere to put
      it, which is a control that silently forgets rather than one that works.

    * **A renewals total.** An event has no amount. A price could ride in
      `description`, but that is free iCalendar text on any row a user or a
      sync wrote, so reading money out of it would be a guess wearing the shape
      of a join.

    * **The meta lines.** `09:30–09:45`, `S2 · E3` and `leaves Lumen+ at
      midnight` are not stored — the seeder writes `summary` and the timing and
      drops `meta` — and `Kati.Calendars.Today.meta/1` synthesises a *different*
      string (`Calendar`, `Airs today`) out of `location` and `kind`.

    * **`rail` and `flat`.** A per-event colour override on Design review, and
      the settled paper under the 23:15 notice, are facts the drawing states
      and the schema does not carry.

  A day with nothing on it renders as a day with nothing on it — `Nothing
  scheduled` — whichever day it is.
  """
  use Kati.Screens.Pushed, back: "Calendar"
  use Gettext, backend: Kati.Gettext

  alias Kati.Calendar.Layout
  alias Kati.Components.MishkaActionIcon
  alias Kati.Components.MishkaChip
  alias Kati.Components.MishkaSeparator
  alias Kati.Design.Images
  alias Kati.Theme.Palette

  # The drawing's gap BETWEEN LANES — `display:flex;gap:7px` on the split row.
  # Not to be confused with the 9pt `margin-bottom` that separates one lane row
  # from the next; that one is vertical and lives in `cluster_block/1`.
  @lane_gap 7

  # The chips' keys, in the drawing's order. A key is what `bucket/1` answers
  # and what a chip's tag carries; `chip_label/1` turns it into a word.
  @chips ["Screen", "Personal", "Money"]

  # `nil` is the whole day, and it is the state the screen opens in — see
  # `lit/2`. `open_groups` holds which collapsed groups are open, by the tag
  # their card carries: a day can hold more than one group, and they open
  # independently.
  @impl true
  def load(socket) do
    {date, occurrences} = Kati.Screens.Day.day(socket.assigns.params)

    Mob.Socket.assign(socket,
      date: date,
      filter: nil,
      open_groups: [],
      occurrences: occurrences,
      all_day: Kati.Screens.Day.all_day(date)
    )
  end

  @doc """
  The day's items with no hour — a show whose episodes air on a date and not
  at a time, a film released on a day — as the rows screen 02 draws for them.
  Every one belongs to the Screen chip.
  """
  @spec all_day(Date.t()) :: [map()]
  def all_day(%Date{} = date) do
    date
    |> Kati.Calendars.Airings.rows()
    |> Enum.filter(&is_nil(&1.at))
    |> Enum.map(&Kati.Screens.Calendar.shaped/1)
  end

  @doc """
  Which day this is, and its occurrences: `{date, occurrences}`.

  `%{date: date}` is what the calendar's views push — the cell the user tapped
  — and this screen titles itself with it and draws that day's own events. No
  date is the calendar's selected day, `Kati.Calendars.SelectedDate`, read like
  any other day. `Kati.Calendars.Today.occurrences/1`
  answers the day's timed events in `Kati.Calendar.Layout`'s own shape, ids
  included, and a day with none answers `[]`.
  """
  @spec day(map()) :: {Date.t(), [map()]}
  def day(params) do
    date =
      case Map.get(params, :date) do
        %Date{} = date -> date
        _no_date -> Kati.Calendars.SelectedDate.get()
      end

    {date, Kati.Calendars.Today.occurrences(date) ++ Kati.Calendars.Airings.occurrences(date)}
  end

  @doc false
  def content(assigns) do
    date = assigns.date
    filter = assigns.filter

    # Clustered from the FILTERED list, not filtered after clustering: a clash
    # between a meeting and a renewal is not a clash once the renewals are
    # gone, and the lanes have to be recomputed to say so.
    clusters = clusters(visible(assigns.occurrences, filter), assigns.open_groups)
    all_day = if filter in [nil, "Screen"], do: Map.get(assigns, :all_day, []), else: []

    ~MOB"""
    <Scroll>
      <Column fill_width={true} padding_top={64} padding_bottom={40}>
        <Column fill_width={true} padding_left={21} padding_right={21}>
          {Kati.Screens.Day.header(date, clusters, length(all_day))}
          {Kati.Screens.Day.chips(filter, Kati.Screens.Day.counts(assigns))}
          {Kati.Screens.Day.all_day_block(all_day)}
        </Column>
        {Kati.Screens.Day.timeline(clusters)}
      </Column>
    </Scroll>
    """
  end

  @doc """
  The three chips and their counts, counted off the day's own rows through
  `bucket/1` — the same function that decides which chip narrows to what, so a
  chip can never say `6` and then show four.
  """
  @spec counts(map()) :: [{String.t(), non_neg_integer()}]
  def counts(%{occurrences: occurrences} = assigns) do
    tally =
      occurrences
      |> Enum.frequencies_by(&Kati.Screens.Day.bucket/1)
      |> Map.update(
        "Screen",
        length(Map.get(assigns, :all_day, [])),
        &(&1 + length(Map.get(assigns, :all_day, [])))
      )

    for label <- @chips, do: {label, Map.get(tally, label, 0)}
  end

  @doc "The *All day* group above the timeline, or nothing when the day has none."
  def all_day_block([]), do: ~MOB"<Spacer size={0} />"

  def all_day_block(rows) do
    ~MOB"""
    <Column fill_width={true} padding_top={18}>
      {Kati.UI.eyebrow(gettext("All day"))}
      {Kati.Screens.MonthGrid.day_rows(rows)}
    </Column>
    """
  end

  @doc "The lane rows, in clock order."
  def timeline(clusters) do
    clusters
    |> Enum.sort_by(& &1.start_min)
    |> Enum.map(&Kati.Screens.Day.cluster_block/1)
  end

  # `Kati.Locale.date/2`'s `:long` — `Thu 20 Aug`, and Shamsi under `:fa`.
  # The heading's tracking asks the reader (a negative letter-spacing breaks
  # Arabic-script joins) and the sub-line's face asks the string, because
  # `kati_mono.ttf` carries no Persian glyph.
  @doc false
  def header(date, clusters, all_day \\ 0) do
    heading = Kati.Locale.date(date, :long)
    subtitle = summary(clusters, all_day)

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Spacer weight={1.0} />
        {Kati.Screens.Day.density_disc()}
      </Row>
      <Spacer size={16} />
      <Text
        text={heading}
        text_size={28}
        max_font_scale={1.6}
        font_weight="bold"
        letter_spacing={Kati.Locale.tracking(-0.03)}
        text_color={:on_surface}
        max_lines={1}
      />
      <Spacer size={5} />
      <Text
        text={subtitle}
        font_family={Kati.Locale.mono_face(subtitle)}
        text_size={11}
        text_color={Palette.muted()}
        max_lines={1}
      />
      <Spacer size={20} />
    </Column>
    """
  end

  @doc false
  def chips(filter, all) do
    lit = lit(all, filter)

    children =
      all
      |> Enum.map(fn {label, n} -> Kati.Screens.Day.chip(label, n, label == lit) end)
      |> Enum.intersperse(Kati.Screens.Day.chip_gap())

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true}>
        {children}
      </Row>
      <Spacer size={18} />
    </Column>
    """
  end

  @doc """
  Which chip the row lights.

  A narrowed timeline lights its own chip. The whole day — `nil` — lights the
  first, because that is the state the design draws: `Screen` in ink over a
  timeline that still holds every kind. Reading it off the chip list rather
  than naming `"Screen"` keeps the default a data fact, the way the old
  `i == 0` did.
  """
  @spec lit([{String.t(), non_neg_integer()}], String.t() | nil) :: String.t() | nil
  def lit(chips, nil) do
    case chips do
      [{first, _count} | _rest] -> first
      [] -> nil
    end
  end

  def lit(_chips, filter), do: filter

  @doc false
  def chip_gap, do: ~MOB"<Spacer size={7} />"

  @doc """
  One kind chip — Mishka's Chip, which is exactly what this is: a label that
  carries a selected state and toggles the timeline when tapped.

  It could not be one until the chip stopped hardcoding its own metrics and
  its own unchecked colours. It now takes both, so the four numbers the drawing
  gives this row — 30 tall, 15 of radius, 13 of side padding, a 12.5pt semibold
  label — are passed rather than approximated, and the *unselected* fill
  (`card`) and ink (`#5C574F`) are the chip's props instead of being the one
  state the component decided for itself.

  Nothing moves. `padding_x: 13` with `padding_y: 0` is the same 13/0 the Row
  carried, and because padding is applied before height, `height: 30` is still
  30 on screen. The chip is a `Box fill_width={false}` holding a `Row`, where
  this was a `Row`: the Box hugs (K-17), the inner Row hugs its three children,
  and a Box that hugs and centres content of its own size puts them at exactly
  the offsets the Row did. The count keeps its own node — `trailing` takes a
  node, not just a string — so it stays mono at 10.5 in its own tone rather
  than inheriting the label's.
  """
  @spec chip(String.t(), non_neg_integer(), boolean()) :: map()
  def chip(label, count, on?) do
    MishkaChip.chip(
      # The WORD, not the key — `chip_label/1` and its doc say why the two are
      # different values and why this is the last moment one can become the
      # other.
      label: Kati.Screens.Day.chip_label(label),
      checked: on?,
      # The tag carries the label, so one handler serves every chip and a
      # fourth kind is a change to `@chips` alone. The KEY, always:
      # an atom built out of `نمایش` is a tag no clause in `handle_tap/2` can
      # read.
      on_toggle: String.to_atom("filter_" <> label),
      color: Palette.ink_fill(),
      text_color: Palette.on_ink(),
      unchecked_color: Palette.card(),
      unchecked_text_color: Palette.ink_soft(),
      height: 30,
      corner_radius: 15,
      padding_x: 13,
      padding_y: 0,
      text_size: 12.5,
      font_weight: :semibold,
      max_lines: 1,
      trailing_gap: 6,
      trailing: Kati.Screens.Day.chip_count(count, on?)
    )
  end

  @doc """
  The word a chip draws, for the key it narrows on.

  The KEY is three things at once: what `bucket/1` answers, what `visible/2`
  compares a row against, and what `chip/3` builds `filter_<key>` out of for
  `handle_tap/2` to split back apart. Translate it anywhere upstream of here
  and all three break together — a chip drawn «نمایش» tags `:"filter_نمایش"`,
  no clause in `handle_tap/2` matches it, `visible/2` compares نمایش against
  `bucket/1`'s `"Screen"` and the Screen chip hides the episodes it names.
  `Kati.Screens.MealsDay.chip_label/1` carries the long version of the same
  defect, found in the same fold; this is that screen's row on the day before
  it.

  So the key travels English the whole way down and becomes a word at the last
  possible moment, which is this call site.

  None of the three is a new msgid. `Kati.Screens.Calendar` draws the same
  three on its own section chips and `Kati.Screens.MealsDay` two of them, and a
  section cannot be called one thing on the calendar and another one tap in.
  The catch-all returns the key untouched — a kind this screen has no word for
  reads as it was stored, which is what gettext does with a missing msgid
  anyway.
  """
  @spec chip_label(String.t()) :: String.t()
  def chip_label("Screen"), do: gettext("Screen")
  def chip_label("Personal"), do: gettext("Personal")
  def chip_label("Money"), do: gettext("Money")
  def chip_label(other), do: other

  # The count rides at .55/.6 of the label's own colour rather than a token of
  # its own, so it stays a shade of the chip it sits on in either state.
  #
  # `Kati.Locale.number/1` first and `Kati.Locale.mono_face/1` about the RESULT
  # — the same pair in the same order `Kati.Screens.MealsDay.chip_count/1` uses
  # on the other filter row, and for the same reason: `kati_mono.ttf` carries
  # none of U+06F0–U+06F9, so ۶ asked for in DM Mono comes back in Android's
  # own substitute face beside a chip label set in Vazirmatn. Asking the string
  # rather than the reader keeps the English `6` in DM Mono without a second
  # branch here.
  @doc false
  def chip_count(count, on?) do
    fg = if on?, do: Palette.on_ink_count(), else: Palette.count_idle_faint()
    n = Kati.Locale.number(count)

    ~MOB"""
    <Text
      text={n}
      font_family={Kati.Locale.mono_face(n)}
      text_size={10.5}
      text_color={fg}
      max_lines={1}
    />
    """
  end

  # An open group's member poster: 26x37 at radius 5, the placeholder showing
  # where the artwork is missing.
  @doc false
  def thumb(item, placeholder) do
    case Images.poster(item[:seed]) do
      nil ->
        ~MOB"<Box width={26} height={37} corner_radius={5} background={placeholder} />"

      src ->
        ~MOB"""
        <Image src={src} width={26} height={37} corner_radius={5} content_mode="fill" />
        """
    end
  end

  @doc """
  The occurrences a chip leaves on the timeline.

  The design's three chips are the day's three kinds and their counts sum to
  the day's own total — `6 + 6 + 2 = 14` — so every item belongs to exactly
  one of them and the buckets can be an exhaustive split rather than a set of
  overlapping searches.
  """
  @spec visible([map()], String.t() | nil) :: [map()]
  def visible(occurrences, nil), do: occurrences

  def visible(occurrences, filter),
    do: Enum.filter(occurrences, fn o -> Kati.Screens.Day.bucket(o) == filter end)

  @doc """
  Which chip an occurrence belongs to.

  Read off `:kind`, the same field `kind_rail/1` colours from, so the rail and
  the chip cannot disagree about what a row is. A device-mirrored event
  arrives as `:event` and lands in Personal, which is what a phone's own
  calendar holds.
  """
  @spec bucket(map()) :: String.t()
  def bucket(occurrence) do
    case Map.get(occurrence, :kind) do
      :air_date -> "Screen"
      :episode -> "Screen"
      :money -> "Money"
      _ -> "Personal"
    end
  end

  @doc """
  The mono line under the date: how many items the timeline on screen holds
  and how many of its rows clash, or `Nothing scheduled`.

  Counted off the clusters actually drawn, so a chip that narrows the day
  narrows the count with it. A collapsed card counts every member it stands
  for — "3 episodes" is three things the day holds, not one.
  """
  @spec summary([map()], non_neg_integer()) :: String.t()
  def summary(clusters, all_day \\ 0) do
    items =
      Enum.reduce(clusters, all_day, fn c, acc ->
        acc + Enum.sum(Enum.map(c.placements, &member_count(&1.event))) + hidden_count(c.overflow)
      end)

    clashes = Enum.count(clusters, &(&1.n_cols > 1))

    case {items, clashes} do
      {0, _} -> gettext("Nothing scheduled")
      {_, 0} -> items_tally(items)
      _ -> joined(items_tally(items), clashes_tally(clashes))
    end
  end

  defp member_count(%{collapsed: members}), do: length(members)
  defp member_count(_event), do: 1

  defp hidden_count(nil), do: 0
  defp hidden_count(tile), do: length(tile.event.overflow)

  # `plural(n, "item", "items")` was two things gettext cannot do, and it was
  # the same pair `Kati.Screens.MealsDay.meals_tally/1` already replaced: a
  # msgid has to be a literal where the extractor can see it — `gettext(noun)`
  # does not compile — and an `s` is English's plural rule rather than every
  # language's. Persian does not inflect a noun after a numeral at all, so both
  # `ngettext` forms come back the same word; that is the catalogue's answer to
  # give, not this module's.
  #
  # `%{n} item` is not a new entry: `Kati.Screens.Calendar` heads its own day
  # with it, and a day cannot be `۱۴ مورد` on one screen and something else one
  # tap in.
  defp items_tally(n), do: ngettext("%{n} item", "%{n} items", n, n: Kati.Locale.number(n))

  defp clashes_tally(n), do: ngettext("%{n} clash", "%{n} clashes", n, n: Kati.Locale.number(n))

  # The `·` is the separator in both scripts — board 56 draws `عادت · ۱۲ روز
  # پیاپی` — so it is punctuation between two translated halves rather than
  # copy of its own, and `Kati.Screens.MealsDay.joined/2` makes the same call.
  # Kept out of the msgids deliberately: one sentence holding both halves would
  # multiply two plural rules into a four-form entry, and a msgid that is
  # nothing but a middot between two placeholders is exactly the tiny string
  # `mix gettext.merge` fuzzy-matches onto something else.
  defp joined(left, right), do: left <> " · " <> right

  # A clash is labelled, not just laid out. The design puts "2 at once" or
  # "3 at once" above the split with a `call_split` glyph, so the reason two
  # cards are side by side is stated rather than inferred from their width.
  @doc false
  def clash_label(%{n_cols: n} = cluster) when n > 1 do
    total = length(cluster.placements) + hidden_count(cluster.overflow)

    # `Kati.UI.eyebrow_label/1` rather than `String.upcase/1`, for the reason
    # `Kati.Screens.MealsDay.collapsed_for/1` gives about its own upper-case
    # line: Arabic script has no case, so upcasing the Persian is a no-op that
    # reads as a decision nobody took. The English is still `2 AT ONCE`.
    #
    # A plain `gettext/1` and not `ngettext/4`: this clause is guarded on
    # `n_cols > 1`, so `total` is never 1 and a singular form would be an
    # unreachable entry for a translator to have to guess at.
    label = Kati.UI.eyebrow_label(gettext("%{n} at once", n: Kati.Locale.number(total)))

    ~MOB"""
    <Row align="center" padding_left={56} padding_bottom={7}>
      {Kati.UI.symbol("call_split", size: 14, color: Palette.accent())}
      <Spacer size={6} />
      <Text
        text={label}
        font_family={Kati.Locale.mono_face(label)}
        text_size={10}
        letter_spacing={Kati.Locale.tracking(0.12)}
        text_color={Palette.gold_label()}
        max_lines={1}
      />
    </Row>
    """
  end

  def clash_label(_), do: ~MOB"<Spacer size={0} />"

  @doc false
  def cluster_block(cluster) do
    ~MOB"""
    <Column fill_width={true} padding_left={21} padding_right={21}>
      {Kati.Screens.Day.clash_label(cluster)}
      <Row align="top" fill_width={true}>
        {Kati.Screens.Day.gutter(cluster)}
        {Kati.Screens.Day.lanes(cluster)}
      </Row>
      <Spacer size={9} />
    </Column>
    """
  end

  @doc """
  The time column.

  44dp wide, which is the drawing's own number and — more to the point — the
  same 44 the all-day band uses. Sized to its content instead, the band's card
  started 8dp to the right of every card below it, which is visible as a step
  down the left edge of the timeline.

  The old comment feared a two-line "02:" over "19" at 235% Dynamic Type. That
  cannot happen: the label is `max_lines={1}` and every Text in this bridge is
  built with `TextOverflow.Ellipsis`, so an oversized label shortens rather
  than wraps.

  `padding_top` tracks what the row is. A plain lane sits its clock beside the
  card's first line; a clash row has already spent that space on the "n at
  once" marker; the grouped card is taller and pads more, and the drawing also
  darkens its clock — it is the one row the day is pointed at.
  """
  def gutter(cluster) do
    top = gutter_top(cluster)
    strong? = grouped?(cluster)
    colour = if strong?, do: Palette.ink(), else: Palette.muted()
    weight = if strong?, do: "medium", else: "regular"
    # `label_for/1`'s answer, which is already in the reader's own digits — so
    # the face is the only thing left to ask, and it is asked of the string:
    # `08:00` stays in DM Mono and ۰۸:۰۰ cannot, because `kati_mono.ttf`
    # carries none of U+06F0–U+06F9.
    label = cluster.label

    ~MOB"""
    <Row>
      <Column min_width={44} padding_top={top}>
        <Text
          text={label}
          text_size={12}
          font_weight={weight}
          text_color={colour}
          font_family={Kati.Locale.mono_face(label)}
          max_lines={1}
        />
      </Column>
      <Spacer size={12} />
    </Row>
    """
  end

  @doc false
  def grouped?(%{placements: [%{event: %{collapsed: _members}}]}), do: true
  def grouped?(_cluster), do: false

  defp gutter_top(cluster) do
    cond do
      grouped?(cluster) -> 15
      cluster.n_cols > 1 -> 5
      true -> 12
    end
  end

  @doc """
  The lane row.

  One child per column position, each carrying `weight = span`. A gap
  `Spacer` sits between lanes and is a fixed size rather than a weight, so
  the gap stays 9dp at every width instead of growing with the lane.
  """
  def lanes(%{n_cols: 1, placements: [only]} = cluster) do
    if grouped?(cluster), do: grouped_card(only, cluster), else: card(only, false)
  end

  def lanes(cluster) do
    cards =
      cluster.placements
      |> Enum.sort_by(& &1.col)
      |> Enum.map(&card(&1, true))

    children = Enum.intersperse(cards ++ overflow_tile(cluster.overflow), gap())

    ~MOB"""
    <Row fill_width={true} align="top">
      {children}
    </Row>
    """
  end

  # A lane, not a footer. `Kati.Calendar.Layout` hands the tile back separately
  # because it is not part of the column grid, and an earlier version took that
  # literally and drew a full-width cream pill on the line below. The drawing
  # puts it INSIDE the split row: a 44pt tile on the trailing edge, the same
  # height as the cards beside it.
  #
  # 55 is that height written out rather than measured — 11 + 11 of padding
  # around a 12.5pt title and a 10pt meta line. There is no way to say "as tall
  # as my siblings" here: `fill_height` inside a Row resolves against the
  # incoming maximum, which is unbounded inside a Scroll.
  defp overflow_tile(nil), do: []

  defp overflow_tile(tile) do
    # `Kati.Locale.ltr/1` around the sign and the digit together. `+` is a
    # NEUTRAL in the bidi algorithm, so on an RTL page it resolves against the
    # paragraph rather than against the number it belongs to and is laid out on
    # the wrong side — `۱+`, where the tile means `+۱`. A no-op in Latin.
    #
    # The face is asked of the BARE figure, before the isolates: `mono_face/1`
    # tests for pure ASCII, and U+2066 is not, so asking it of the wrapped
    # string would take `+1` out of DM Mono on an English page too.
    figure = Kati.Locale.number(length(tile.event.overflow))
    label = Kati.Locale.ltr("+" <> figure)

    [
      ~MOB"""
      <Box
        min_width={44}
        min_height={55}
        corner_radius={16}
        background={Palette.placeholder()}
        align="center"
      >
        <Column>
          <Row align="center">
            <Spacer weight={1.0} />
            <Text
              text={label}
              font_family={Kati.Locale.mono_face(figure)}
              text_size={13}
              font_weight="medium"
              text_color={:on_surface}
              max_lines={1}
            />
            <Spacer weight={1.0} />
          </Row>
          <Spacer size={2} />
          <Row align="center">
            <Spacer weight={1.0} />
            <Text
              text={pgettext("the +n MORE tile on a clash row", "MORE")}
              font_family={Kati.Locale.mono_face()}
              text_size={8.5}
              letter_spacing={Kati.Locale.tracking(0.08)}
              text_color={Palette.sub()}
              max_lines={1}
            />
            <Spacer weight={1.0} />
          </Row>
        </Column>
      </Box>
      """
    ]
  end

  defp gap do
    # A local, not @lane_gap: inside ~MOB an `@name` means an assign, so the
    # module attribute would be read as `assigns.lane_gap` and fail.
    size = @lane_gap

    ~MOB"""
    <Spacer size={size} />
    """
  end

  @doc """
  One card in a lane.

  `split?` is the difference between the drawing's two card shapes. A card
  that has the row to itself is 13pt titled with 13pt of side padding; one
  sharing the row with another is 12.5pt titled with 12pt, because two of them
  and a 7pt gutter have to fit where one did.

  The leading slot holds exactly one mark. The drawing gives the habit row a
  kind rail, the todo row its ring, the renewals row its coin chip and the
  "leaves at midnight" row its poster — never two of them — so a card that
  carries a poster or a ring does not also carry a rail.
  """
  def card(%{event: event, span: span}, split?) do
    weight = span * 1.0
    title = Map.get(event, :title) || collapsed_title(event)
    meta = Map.get(event, :meta) || collapsed_meta(event)

    # A done or todo row sits on #F4F1EC with no shadow — the design sinks
    # anything already dealt with, so the live rows are the ones that lift.
    # `flat` says the same thing about a row that was never yours to do: a
    # title leaving a service at midnight is a notice, not an appointment.
    settled? =
      Map.get(event, :done) == true or Map.get(event, :todo) == true or
        Map.get(event, :flat) == true

    background = if settled?, do: Palette.card_settled(), else: Palette.card()
    shadow = if settled?, do: nil, else: "0 1 2 0 #0A1A1917 | 0 10 20 -18 #B31A1917"

    # 11pt of air above and below a rail-led card, 10 above and below one led
    # by a ring, a chip or a poster: the drawing's own two numbers, and the
    # taller mark is the one that gets less.
    pad_v = if rail?(event), do: 11, else: 10
    pad_h = if split?, do: 12, else: 13
    title_size = if split?, do: 12.5, else: 13
    meta_gap = if split?, do: 4, else: 3
    tap = Kati.Screens.Day.card_tap(event)

    ~MOB"""
    <Box weight={weight}>
      <Row
        fill_width={true}
        background={background}
        corner_radius={16}
        shadow={shadow}
        padding_left={pad_h}
        padding_right={pad_h}
        padding_top={pad_v}
        padding_bottom={pad_v}
        align="center"
        on_tap={tap}
      >
        {Kati.Screens.Day.kind_rail(event, split?, meta)}
        {Kati.Screens.Day.leading_state(event)}
        {Kati.Screens.Day.leading_poster(event)}
        <Column weight={1.0}>
          <Text
            text={title}
            text_size={title_size}
            font_weight="semibold"
            text_color={:on_surface}
            max_lines={2}
          />
          {Kati.Screens.Day.card_meta(meta, meta_gap)}
        </Column>
        {Kati.Screens.Day.state_icon(event)}
      </Row>
    </Box>
    """
  end

  # The drawing's 08:00 card is a single line — a habit that is done says so
  # with its tick, not with a second sentence — so an absent meta draws nothing
  # rather than an empty line and the gap above it.
  @doc false
  def card_meta(meta, _gap) when meta in [nil, ""], do: ~MOB"<Spacer size={0} />"

  def card_meta(meta, gap) do
    ~MOB"""
    <Column fill_width={true}>
      <Box fill_width={true} height={gap} />
      <Text
        text={meta}
        font_family={Kati.Locale.mono_face(meta)}
        text_size={10}
        text_color={Palette.muted()}
        max_lines={1}
      />
    </Column>
    """
  end

  @doc "Whether this row's leading mark is the kind rail rather than a ring, a chip or a poster."
  @spec rail?(map()) :: boolean()
  def rail?(event) do
    Map.get(event, :todo) != true and Map.get(event, :seed) == nil and
      Map.get(event, :kind) != :money
  end

  # The 3dp rail that says what KIND of thing this is, before the title says
  # what it is. Green for a habit, bronze for money, ink for everything else —
  # and whatever `:rail` names, for the one card the drawing colours by hand.
  #
  # The drawing stretches the rail to the card's content. Nothing here can say
  # "as tall as my sibling", so the height is the text block's own: a title and
  # a meta line, or a title alone.
  @doc false
  def kind_rail(event, split?, meta) do
    if rail?(event) do
      colour =
        Map.get(event, :rail) ||
          case Map.get(event, :kind) do
            :habit -> Palette.green()
            :money -> Palette.bronze()
            :air_date -> Palette.accent()
            _ -> Palette.ink()
          end

      height = if meta in [nil, ""], do: 18, else: 34
      gap = if split?, do: 9, else: 11

      ~MOB"""
      <Row align="center">
        <Box width={3} height={height} corner_radius={2} background={colour} />
        <Spacer size={gap} />
      </Row>
      """
    else
      ~MOB"<Spacer size={0} />"
    end
  end

  # The 24x34 poster on the drawing's 23:15 row. It replaces the rail rather
  # than joining it — see `card/2`.
  @doc false
  def leading_poster(%{seed: seed}) when is_binary(seed) do
    case Images.poster(seed) do
      nil ->
        ~MOB"""
        <Row align="center">
          <Box width={24} height={34} corner_radius={5} background={Palette.placeholder()} />
          <Spacer size={11} />
        </Row>
        """

      src ->
        ~MOB"""
        <Row align="center">
          <Image src={src} width={24} height={34} corner_radius={5} content_mode="fill" />
          <Spacer size={11} />
        </Row>
        """
    end
  end

  def leading_poster(_event), do: ~MOB"<Spacer size={0} />"

  @doc """
  The grouped card — three episodes on one line, with their posters fanned.

  A different object from a lane card, not a lane card with extra props: 18pt
  radius against 16, 14pt of padding, a deeper shadow, a 14pt title and a
  chevron disc that says it opens.

  The fan is the drawing's `margin-left:-14px` trick read from the other side.
  Mob has no negative margin, so each tile is pushed in from a Box of declared
  width instead: 22pt apart for a 34pt tile is the same 12pt overlap, and the
  Box is `n * 22 + 30` wide because the dark count tile that ends the stack is
  30 rather than 34.

  The count on that tile is `{{ groupCount }}` in the export, with no value
  behind it. It is drawn as the group's own size here — the only number the
  card holds that the title does not already spell out is how many members the
  stack stands for, and three posters over "3" is at least true. Worth
  re-checking against the design source if that template ever resolves.

  ## It opens

  The whole header row is the target, which is where 02's drawing puts it:
  `onClick="{{ toggleGroup }}"` sits on the flex row holding the rail, the
  stack, the text and the disc — not on the disc, which is why the disc stays
  a plain `action_icon/2` with no tap of its own.

  The card chrome (fill, radius, shadow, 14 of padding) lives on the `<Column>`
  so the members can sit inside it under the hairline. Collapsed, that Column
  holds one `fill_width` `<Row>` and measures exactly what the Row measured
  when it carried the chrome itself.
  """
  def grouped_card(%{event: event}, cluster) do
    members = Map.get(event, :collapsed, [])
    title = collapsed_title(event)
    meta = collapsed_meta(event)
    open? = Map.get(cluster, :open?, false)
    tap = {self(), Map.fetch!(cluster, :tag)}

    ~MOB"""
    <Box weight={1.0}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={18}
        shadow="0 1 2 0 #0D1A1917 | 0 16 30 -18 #BF1A1917"
        padding={14}
      >
        <Row fill_width={true} on_tap={tap} align="center">
          <Box width={3} height={48} corner_radius={2} background={Palette.accent()} />
          <Spacer size={12} />
          {Kati.Screens.Day.poster_stack(members)}
          <Spacer size={4} />
          <Column weight={1.0}>
            <Text
              text={title}
              text_size={14}
              font_weight="bold"
              letter_spacing={Kati.Locale.tracking(-0.015)}
              text_color={:on_surface}
              max_lines={1}
            />
            <Spacer size={4} />
            <Text
              text={meta}
              font_family={Kati.Locale.mono_face(meta)}
              text_size={10.5}
              text_color={Palette.sub()}
              max_lines={1}
            />
          </Column>
          <Spacer size={12} />
          {Kati.Screens.Day.chevron_disc(open?)}
        </Row>
        {Kati.Screens.Day.group_members(members, open?)}
      </Column>
    </Box>
    """
  end

  @doc """
  The members, drawn only while the group is open.

  Screen 02's `<sc-if value="{{ groupOpen }}">` block, number for number:
  `margin-top:13px` above an 8%-ink hairline, `padding-top:4px` below it, then
  one row per member. Closed it draws a zero `<Spacer>` rather than an empty
  `<Column>` — the 13 above the rule belongs to
  the block, and a closed group has to take it with it or the collapsed card
  is 13pt taller than the drawing.
  """
  @spec group_members([map()], boolean()) :: map()
  def group_members(_members, false), do: ~MOB"<Spacer size={0} />"

  def group_members(members, true) do
    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={13} />
      {Kati.Screens.Day.group_rule()}
      <Spacer size={4} />
      {Enum.map(members, fn member -> Kati.Screens.Day.member_row(member) end)}
    </Column>
    """
  end

  # `border-top:1px solid rgba(26,25,23,.08)`, which is Chelekom's Separator
  # rather than a Box pretending to be a line. `render: :box` for the reason
  # `Kati.Screens.Calendar.rule/0` states: the default `:divider` is
  # Material3's antialiased `drawLine`, and at this device's 2.6875x the last
  # pixel row of a 1dp rule lands at ~69% coverage — a hairline lighter than
  # the drawn one.
  @doc false
  def group_rule,
    do: MishkaSeparator.separator(color: Palette.hairline_soft(), thickness: 1, render: :box)

  @doc """
  One member of an open group.

  `display:flex;align-items:center;gap:11px;padding:9px 0` over a 26x37 poster,
  the title, the episode line and the member's own clock — 02's row, whose
  trailing `{{ a.t }}` is the one field screen 09's members already carry as
  data: `start_min`, through the same `label_for/1` the gutter reads.
  """
  @spec member_row(map()) :: map()
  def member_row(member) do
    title = Map.get(member, :title) || gettext("Untitled")

    ~MOB"""
    <Row fill_width={true} align="center" padding_top={9} padding_bottom={9}>
      {Kati.Screens.Day.thumb(member, Palette.placeholder())}
      <Spacer size={11} />
      <Column weight={1.0}>
        <Text
          text={title}
          text_size={13}
          font_weight="semibold"
          letter_spacing={Kati.Locale.tracking(-0.01)}
          text_color={:on_surface}
          max_lines={1}
        />
        {Kati.Screens.Day.member_meta(Map.get(member, :meta))}
      </Column>
      {Kati.Screens.Day.member_time(member)}
    </Row>
    """
  end

  @doc false
  def member_meta(meta) when meta in [nil, ""], do: ~MOB"<Spacer size={0} />"

  def member_meta(meta) do
    ~MOB"""
    <Column fill_width={true}>
      <Box fill_width={true} height={3} />
      <Text
        text={meta}
        font_family={Kati.Locale.mono_face(meta)}
        text_size={10.5}
        text_color={Palette.muted()}
        max_lines={1}
      />
    </Column>
    """
  end

  # The `gap:11px` before the clock rides INSIDE this node, so a member with no
  # start minute takes its own gap with it rather than leaving 11pt of air on
  # the trailing edge. Same shape as `state_icon/1`.
  @doc false
  def member_time(%{start_min: minutes}) when is_integer(minutes) do
    label = label_for(minutes)

    ~MOB"""
    <Row align="center">
      <Spacer size={11} />
      <Text
        text={label}
        font_family={Kati.Locale.mono_face(label)}
        text_size={11}
        text_color={Palette.ink_soft()}
        max_lines={1}
      />
    </Row>
    """
  end

  def member_time(_member), do: ~MOB"<Spacer size={0} />"

  @doc """
  The header's `density_medium` disc — Mishka's Action Icon, now that it can
  float.

  This one is 44pt and **lifted**, and a floating disc is defined by its
  shadow: without one it reads as a flat patch of card colour on paper rather
  than as a control sitting above it. `action_icon/2` had no way to say that,
  which is why it stayed hand-rolled while the shadowless 26pt chevron below
  was already the component. `shadow` closes it, and takes the design's
  `Kati.Theme.shadow_button()` string untouched.

  Same pixels as the Box it replaces: `shape: :circle` is an exact `size / 2`,
  so 44 rounds at 22; the fill, the shadow and the centring are passed
  straight through; and the glyph is the same `Kati.UI.symbol/2` Text, now
  inside a Row that hugs it — a Row takes its content's size, and a hugging Row
  centred in a Box lands where the bare Text did.

  It opens the agenda. The disc was drawn lifted, which is how this app says
  *button*, and it carried no tap at all. `density_medium` is the glyph screen
  02's own menu gives *Agenda*, so the same picture leads to the same place
  here, through `Kati.Screens.ViewSwitcher` like the other views' segments.
  """
  @spec density_disc() :: map()
  def density_disc do
    MishkaActionIcon.action_icon(
      [
        size: 44,
        shape: :circle,
        variant: :filled,
        background: Palette.card(),
        shadow: Kati.Theme.shadow_button(),
        on_tap: :view_Agenda
      ],
      [Kati.UI.symbol("density_medium", size: 21)]
    )
  end

  @doc """
  The grouped card's chevron disc — Mishka's Action Icon.

  A round icon button is what `action_icon/2` is for. The pixels are the same:
  `shape: :circle` resolves to an exact `size / 2`, so 26 rounds at 13 as
  before; the fill is passed through; and the glyph is the same
  `Kati.UI.symbol/2` Text, wrapped in a Row that hugs it, centred in a Box of
  the same declared size.

  It is only the disc. The tap belongs to the header row around it — 02's
  drawing puts `onClick` there — so this stays an icon in a container with no
  `on_tap` of its own.
  """
  @spec chevron_disc(boolean()) :: map()
  def chevron_disc(open?) do
    MishkaActionIcon.action_icon(
      [size: 26, shape: :circle, variant: :filled, background: Palette.paper()],
      [Kati.Screens.Day.chevron(open?)]
    )
  end

  # The collapse glyph is `expand_more` turned over, which is what the design
  # itself does — 02's export rotates it 180deg in CSS. There is no
  # `expand_less` in the icon subset and there does not need to be: a missing
  # glyph draws empty space and says nothing, and re-subsetting the font for a
  # glyph that is this one upside down is not the trade. Fence K-16 gave the
  # bridge `rotate` instead.
  @doc false
  def chevron(false), do: Kati.UI.symbol("expand_more", size: 17, color: Palette.ink_soft())

  def chevron(true) do
    ~MOB"""
    <Box width={17} height={17} rotate={180.0} align="center">
      {Kati.UI.symbol("expand_more", size: 17, color: Palette.ink_soft())}
    </Box>
    """
  end

  @doc false
  def poster_stack(members) do
    shown = Enum.take(members, 3)
    n = length(shown)
    width = n * 22 + 30
    count = Kati.Locale.number(length(members))

    tiles =
      shown
      |> Enum.with_index()
      |> Enum.map(fn {m, i} -> Kati.Screens.Day.stack_tile(Map.get(m, :seed), i * 22) end)

    ~MOB"""
    <Box width={width} height={48}>
      {tiles}
      {Kati.Screens.Day.stack_count(count, n * 22)}
    </Box>
    """
  end

  # The 2pt ring is a centred 30x44 image inside a 34x48 card-coloured box, not
  # `padding={2}` — padding measures OUTSIDE the declared width here, so a
  # padded tile would be 38 wide and the fan would drift.
  @doc false
  def stack_tile(seed, offset) do
    src = Images.poster(seed)

    ~MOB"""
    <Row padding_left={offset}>
      <Box
        width={34}
        height={48}
        corner_radius={7}
        background={Palette.card()}
        shadow="0 3 8 -3 #801A1917"
        align="center"
      >
        {Kati.Screens.Day.stack_art(src)}
      </Box>
    </Row>
    """
  end

  @doc false
  def stack_art(nil),
    do: ~MOB"<Box width={30} height={44} corner_radius={5} background={Palette.placeholder()} />"

  def stack_art(src) do
    ~MOB"""
    <Image src={src} width={30} height={44} corner_radius={5} content_mode="fill" />
    """
  end

  @doc false
  def stack_count(count, offset) do
    ~MOB"""
    <Row padding_left={offset}>
      <Box width={30} height={48} corner_radius={7} background={Palette.card()} align="center">
        <Box width={26} height={44} corner_radius={5} background={Palette.ink()} align="center">
          <Text
            text={count}
            font_family={Kati.Locale.mono_face(count)}
            text_size={11}
            text_color={Palette.on_ink()}
            max_lines={1}
          />
        </Box>
      </Box>
    </Row>
    """
  end

  # A todo's circle leads the row — it is a thing to tick, and the drawing puts
  # the affordance where the eye starts. A done check trails, because it is a
  # statement rather than an invitation.
  #
  # So the tick flips in place rather than moving to the trailing edge: the
  # hollow ring becomes the same filled green `check_circle` the done habit
  # wears, which is the design's own word for "dealt with", said in the slot
  # the design chose for a todo. The row's paper does not change because the
  # design already sinks a todo onto `#F4F1EC` — it is settled either way,
  # once as a thing to do and once as a thing done.
  @doc false
  def leading_state(%{todo: true} = event) do
    tap = {self(), String.to_atom("todo_" <> to_string(event.id))}
    done? = Map.get(event, :done) == true
    icon = if done?, do: "check_circle", else: "radio_button_unchecked"
    ink = if done?, do: Palette.green(), else: Palette.tertiary()

    ~MOB"""
    <Row align="center" on_tap={tap}>
      {Kati.UI.symbol(icon, size: 19, color: ink, fill: done?)}
      <Spacer size={11} />
    </Row>
    """
  end

  def leading_state(_), do: ~MOB"<Spacer size={0} />"

  # In a Row, so it sits AFTER the text. As a sibling of the Column inside the
  # Box it stacked on top of it instead — the green check landed across the
  # middle of "Morning run".
  @doc false
  def state_icon(%{todo: true}), do: ~MOB"<Spacer size={0} />"

  def state_icon(%{done: true}) do
    ~MOB"""
    <Row align="center">
      <Spacer size={11} />
      {Kati.UI.symbol("check_circle", size: 19, color: Palette.green(), fill: true)}
    </Row>
    """
  end

  def state_icon(_), do: ~MOB"<Spacer size={0} />"

  defp collapsed_title(%{collapsed: members, kind: kind}),
    do: kind_label(kind, length(members))

  defp collapsed_title(_), do: gettext("Untitled")

  # The member titles are the events' own summaries, so only the fallback is
  # copy, and it is the same `Untitled` `member_row/1` falls back to.
  #
  # The `·` is punctuation between two names rather than copy, exactly as it is
  # in `joined/2`: it separates two titles in both scripts.
  defp collapsed_meta(%{collapsed: members}) do
    members
    |> Enum.map(&Map.get(&1, :title, gettext("Untitled")))
    |> Enum.take(2)
    |> Enum.join(" · ")
  end

  defp collapsed_meta(_), do: ""

  # The label a user reads, not the atom the schema stores. "3 air_date
  # events" is a database row talking to itself.
  #
  # `ngettext/4` per kind rather than the old `kind_plural/2` handing a noun
  # back to a caller that interpolated it: a msgid has to be a literal where
  # the extractor can see it, and `"#{n} #{noun}"` put both the number and the
  # word outside gettext's reach. The count goes in as a placeholder rather
  # than being glued on in front, because a numeral does not lead every
  # language's phrase.
  #
  # The English is unchanged, down to the `s`. The two forms are there for the
  # catalogue's sake — Persian does not inflect a noun after a numeral, so its
  # singular and plural are the same word, which is the answer a translator
  # gives rather than one this module can assume.
  #
  # `%{n} meal` is `Kati.Screens.MealsDay`'s own msgid: the meal day and this
  # day collapse the same rows under the same rule and must count them in the
  # same word.
  defp kind_label(:meal, n), do: ngettext("%{n} meal", "%{n} meals", n, n: Kati.Locale.number(n))

  defp kind_label(:air_date, n),
    do: ngettext("%{n} episode", "%{n} episodes", n, n: Kati.Locale.number(n))

  defp kind_label(:habit, n),
    do: ngettext("%{n} habit", "%{n} habits", n, n: Kati.Locale.number(n))

  defp kind_label(:money, n),
    do: ngettext("%{n} renewal", "%{n} renewals", n, n: Kati.Locale.number(n))

  defp kind_label(_kind, n),
    do: ngettext("%{n} event", "%{n} events", n, n: Kati.Locale.number(n))

  # The engine groups these itself. An earlier version reconstructed the
  # clusters here by grouping placements on `start_min`, which gave every
  # event its own cluster: the lanes never split, the Row never got two
  # children, and the screen looked plausible while proving nothing.
  defp clusters(occurrences, open) do
    occurrences
    |> Layout.clusters()
    |> Enum.map(fn cluster ->
      # Stamped here rather than recomputed at the card, so the tag a chevron
      # draws and the tag `handle_tap/2` stored are the same value read twice
      # — not two `String.to_atom/1` calls that have to agree.
      tag = group_tag(cluster.start_min)

      %{
        label: label_for(cluster.start_min),
        start_min: cluster.start_min,
        n_cols: cluster.n_cols,
        placements: Enum.filter(cluster.placements, &(&1.role == :event)),
        overflow: cluster.overflow,
        tag: tag,
        open?: tag in open
      }
    end)
  end

  # The cluster's start minute, not the collapsed event's id. `Layout` keys a
  # collapsed occurrence `{:collapsed, kind, [ids]}`, which is a tuple and
  # cannot be a tap tag; the minute is unique across a day's clusters by
  # construction — the sweep in `Layout.cluster/1` never opens two clusters at
  # one minute — and it survives a tick or a filter that reshuffles ids.
  defp group_tag(start_min), do: String.to_atom("group_#{start_min}")

  # `Kati.Locale.time/1` rather than the format string, which answers the same
  # `~2..0B:~2..0B` in Latin — `%H:%M` is zero-padded too — and answers it in
  # Persian numerals under `:fa`. The gutter is the one column on this page a
  # reader scans as a column, and it was the one column still counting in
  # digits the rest of the page had stopped using.
  #
  # A `Time` and not a formatting of one, because there is a value
  # `Kati.Locale.time/1` cannot take: `Kati.Calendars.Today.occurrences/1`
  # answers `start_min: 1440` for an event that begins after the day it is
  # being drawn on (`minutes_into/3`'s `:gt` clause), and `Time.new!/3` would
  # raise on hour 24 where this function used to print `24:00`. So the clamp is
  # explicit and the old string stays as the fallback: a row past midnight
  # still draws, with Latin digits, which is a better failure than a screen
  # that does not.
  defp label_for(minutes) do
    case Time.new(div(minutes, 60), rem(minutes, 60), 0) do
      {:ok, at} ->
        Kati.Locale.time(at)

      {:error, _out_of_range} ->
        :io_lib.format("~2..0B:~2..0B", [div(minutes, 60), rem(minutes, 60)]) |> to_string()
    end
  end

  @doc """
  The tag a timeline card carries: `event_<occurrence id>`, an airing's
  `Kati.Screens.Calendar.tag/1` (`row_series_<id>` or `row_film_<id>`), or
  none.

  An atom rather than a tuple, for `Kati.Screens.Calendar.tag/1`'s reason —
  `Mob.Renderer` derives an `accessibility_id` only from an atom, so a
  tuple-tagged card fires on device and is invisible to every sweep and unnamed
  to a screen reader.

  `nil` for anything whose id is not a scalar. `Kati.Calendar.Layout` keys a
  collapsed occurrence `{:collapsed, kind, [ids]}`, which is not a name; that
  cluster is drawn by `grouped_card/2` and carries the cluster's own
  `group_<minute>` tag instead.

  The whole card is the target. The ring inside a todo row keeps its own
  `todo_<id>` and wins for its own 24pt, which is the split
  `grouped_card/2` already makes between a card and the disc on it.
  """
  @spec card_tap(map()) :: {pid(), atom()} | nil
  def card_tap(%{tracked_id: tracked_id} = airing) when is_binary(tracked_id),
    do: {self(), Kati.Screens.Calendar.tag(airing)}

  def card_tap(%{id: id}) when is_binary(id) or is_integer(id),
    do: {self(), String.to_atom("event_" <> to_string(id))}

  def card_tap(_event), do: nil

  # One clause for all three chips: the tag carries the label, so a fourth kind
  # is a change to `@chips` and to `bucket/1`, not to this.
  #
  # Tapping the kind the timeline is already narrowed to widens it back to the
  # whole day. Without that the screen has three states and no way back to the
  # one it opened in.
  @impl true
  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "event_" <> id ->
        {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.EventDetail, %{id: id})}

      "row_" <> _show ->
        {:noreply, Kati.Screens.Calendar.open_timeline_row(socket, tag, socket.assigns.date)}

      "filter_" <> label ->
        filter = if socket.assigns.filter == label, do: nil, else: label
        {:noreply, Mob.Socket.assign(socket, :filter, filter)}

      # Toggled by the tag itself, not by an index into the clusters: the
      # clusters are rebuilt from the filtered occurrences on every render, so
      # a position would name a different group after a chip tap.
      "group_" <> _minute ->
        open = socket.assigns.open_groups
        open = if tag in open, do: List.delete(open, tag), else: [tag | open]
        {:noreply, Mob.Socket.assign(socket, :open_groups, open)}

      # Matched as a string rather than converted back to an integer: the id is
      # `term()` in `Layout`, and a tick should not be the thing that decides
      # every occurrence must be numbered.
      "todo_" <> id ->
        occurrences =
          Enum.map(socket.assigns.occurrences, fn o ->
            if to_string(o.id) == id, do: Map.put(o, :done, Map.get(o, :done) != true), else: o
          end)

        {:noreply, Mob.Socket.assign(socket, :occurrences, occurrences)}

      _other ->
        Kati.Screens.ViewSwitcher.handle_tap(tag, socket)
    end
  end
end
