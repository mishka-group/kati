defmodule Kati.Screens.Plans do
  @moduledoc """
  Screen 49 — Meal plan profiles, pushed under Meals.

  Built to `test/design/screens/49.html`. Plans are the profile mechanism:
  a plan owns its meals, its targets and its reminder times, exactly one is
  active, and switching swaps all three at once. The screen is arranged to say
  that — one ink card for the active plan, a list of saved ones you can
  activate, and then the rules that govern the swap.

  Switching is **scheduled**, not instant. "Next Monday · keeps this week
  intact" is the design's answer to the obvious bug of flipping targets
  half-way through a logged week, and it is drawn as a disclosure rather than a
  switch because it opens a date rather than toggling a behaviour.

  Two eyebrows take the accent dash and one takes the muted one, exactly as
  drawn: **Active** and **Switching** are now, **Saved plans** is a shelf.

  The Switching group is `Kati.UI.SettingsList` unchanged. The active card and
  the saved rows are not, because the drawing does not draw them that way: the
  active plan is the one card in the app set on ink, and a saved row leads with
  a 44pt photograph and ends in a 32pt Activate pill.

  ## Where this diverges from the drawing

    * **The footnote's frame is solid, not dashed.** `1.5px dashed
      rgba(26,25,23,.16)` has no dashed equivalent on this bridge —
      `Modifier.border` takes a width and a colour and no `PathEffect` — so the
      weight and the alpha are the drawing's and the rhythm is lost, the same
      trade `Kati.UI.SettingsList.note/2` records.

  No dock, so the frame's bottom inset is 40 rather than 132.

  ## Where the Persian comes from

  Board 294 — *برنامه‌ها — plans, RTL* — is this page in the other script, and
  every msgid below is its wording rather than a fresh translation: فعال for
  the ink card's eyebrow, هفتهٔ ۶ از ۱۲ for the week, ۸۶٪ پایبندی for the
  adherence figure, جابه‌جایی for the section that schedules a swap.

  Two lines do **not** take the board's words, and both times because the app
  has already decided the question elsewhere:

    * *Next Monday* is `Kati.Locale.week_start/0`, not دوشنبه.
      `Kati.Screens.MealEdit.plan_group/0` draws the same row in the same kind
      of card and interpolates the same helper, under board 137's ruling that
      the week's first day follows the language. A Persian page promising a
      Monday rollover promises a day its own week does not turn over on.
    * *Keep the history* takes the msgid `Kati.Screens.MealEdit` already
      introduced, so the one toggle does not acquire two Persian names.

  `Kati.Meals.SampleProfiles` still holds this page's copy as composed English
  — it is the one Meals fixture that does not call `gettext/1` for itself, the
  way `Kati.Meals.SamplePlan` and `Kati.Meals.SampleToday` do — so the
  translation happens where the strings are drawn. See the copy section at the
  bottom of this file for what that costs and what it buys.
  """
  use Kati.Screens.Pushed, back: "Meals"
  use Gettext, backend: Kati.Gettext

  alias Kati.Components.MishkaActionIcon
  alias Kati.Components.MishkaPill
  alias Kati.Meals.SampleProfiles
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  # The drawing's dates, as `Date`s rather than as the words it prints.
  #
  # `started 6 Jul` and `used Mar–Jun` are a day and a span of months, and a
  # Persian reader's ۱۵ تیر and اسفند–خرداد are those same moments counted in
  # another calendar — the arithmetic `gettext/1` cannot do, which is why
  # `Kati.Locale.date/2` and `Kati.Locale.month_name/2` take a `Date` and not a
  # string. Frozen at the drawing's own year for the reason
  # `Kati.Screens.BackupDark` freezes `~D[2026-08-14]`: the figure belongs to
  # the picture rather than to the clock. Board 294 draws `از ۱۵ تیر`.
  @started ~D[2026-07-06]
  @used_from ~D[2026-03-01]
  @used_to ~D[2026-06-01]

  # The note as `Kati.Meals.SampleProfiles` writes it, so `note_text/1` can
  # match on it. A plain literal — a `gettext/1` call in a module attribute
  # would be resolved at COMPILE time and freeze in whichever locale the
  # compiler happened to be in.
  @drawn_note "A plan owns its meals, targets and reminder times. Switching swaps " <>
                "all three at once — nothing has to be re-entered when you come " <>
                "back to an old one."

  @impl true
  def load(socket), do: Mob.Socket.assign(socket, :plans, SampleProfiles.plans())

  @doc false
  def content(assigns) do
    plans = assigns.plans
    subtitle = Kati.Screens.Plans.subtitle(plans)

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {SettingsList.chrome(nil, 42)}
        {SettingsList.title(gettext("Plans"), subtitle, "add", :meta_tight)}
        {UI.eyebrow(pgettext("eyebrow", "Active"))}
        {Kati.Screens.Plans.active(plans.active)}
        {SettingsList.eyebrow_muted(pgettext("eyebrow", "Saved plans"))}
        {Kati.Screens.Plans.saved(plans.saved)}
        {UI.eyebrow(pgettext("eyebrow", "Switching"))}
        {Kati.Screens.Plans.switching(plans.switching)}
        {Kati.Screens.Plans.note(plans.note)}
        {Kati.Screens.Plans.import_row()}
      </Column>
    </Scroll>
    """
  end

  @doc """
  The row that takes a plan in, opposite screen 50 which sends one out.

  On Plans rather than on Meals, because a plan somebody sent you has to land
  where plans live — and because the import writes nothing until its last step,
  which is screen 37's discipline and is what makes an import row safe to put on
  a page full of live plans.
  """
  @spec import_row() :: map()
  def import_row do
    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={22} />
      {Kati.UI.SettingsList.card([
        Kati.UI.SettingsList.row(
          Kati.UI.SettingsList.icon_tile("download"),
          Kati.UI.SettingsList.body(
            gettext("Import a plan"),
            gettext("From a link or a code somebody sent you")
          ),
          Kati.UI.SettingsList.trailing(Kati.UI.SettingsList.chevron()),
          on_tap: {self(), :import_plan}
        )
      ])}
    </Column>
    """
  end

  # The one card in the app drawn on ink rather than on card: it is the plan
  # every other screen is currently obeying, and the inversion says so without
  # a badge.
  #
  # `Palette.ink_fill/0` rather than `Palette.ink/0`: this is the ink-FILLED
  # ground the `on_ink_*` family is measured against. `Kati.Theme.Palette`'s
  # `:inversion` rule solves those for contrast against the pill screen 28
  # draws as `#F7EFE4`, which is `ink_fill`'s dark value and not `ink`'s.
  #
  # The three `0xFF6A6560` mono figures below are LEFT as literals: no token in
  # `Kati.Theme.Palette` has that LIGHT value — it appears there only as the
  # dark side of `muted`, `segment_idle` and `tertiary`. They mean "the mono
  # meta step on an ink fill", which is `on_ink_meta`, but that token's light
  # value is `#8A837B` and swapping would move light-mode pixels. Naming them
  # is the palette's call, not this screen's.
  @doc false
  def active(active) do
    # `Kati.UI.eyebrow_label/1` rather than `String.upcase/1`: Persian has no
    # case, so upcasing هفتهٔ ۶ از ۱۲ is a no-op that reads as one — a caps
    # eyebrow that quietly is not one.
    #
    # The face, the size, the weight and the tracking under it are the same
    # four answers `Kati.UI.eyebrow/2` already gives for a mono section label,
    # and board 294 draws this one exactly that way: Vazirmatn, half a point
    # larger, semibold, no tracking. Each is a `Kati.Locale` pick rather than a
    # second number, so the Latin card's pixels are untouched.
    week = UI.eyebrow_label(Kati.Screens.Plans.week_line(active.week))
    name = Kati.Screens.Plans.plan_name(active.name)
    targets = Kati.Screens.Plans.targets_line(active.targets)
    started = Kati.Screens.Plans.started_line(active.started)
    adherence = Kati.Screens.Plans.adherence_line(active.adherence)

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.ink_fill()}
        corner_radius={24}
        shadow="0 16 32 -16 #E61A1917"
        padding={19}
      >
        <Row fill_width={true} align="top">
          <Column weight={1.0}>
            <Text
              text={week}
              font_family={Kati.Locale.mono_face(week)}
              text_size={Kati.Locale.pick(10, 10.5)}
              font_weight={Kati.Locale.pick("normal", "semibold")}
              letter_spacing={Kati.Locale.tracking(0.16)}
              text_color={0xFF6A6560}
              max_lines={1}
            />
            <Spacer size={8} />
            <Text
              text={name}
              text_size={22}
              font_weight="bold"
              letter_spacing={Kati.Locale.tracking(-0.03)}
              text_color={Palette.on_ink()}
              max_lines={1}
            />
            <Spacer size={6} />
            <Text text={targets} text_size={12.5} text_color={Palette.on_ink_meta()} max_lines={1} />
          </Column>
          <Spacer size={12} />
          {Kati.Screens.Plans.overflow()}
        </Row>
        <Spacer size={16} />
        {Kati.Screens.Plans.progress(active.progress)}
        <Spacer size={10} />
        <Row fill_width={true} align="center">
          <Text
            text={started}
            font_family={Kati.Locale.mono_face(started)}
            text_size={10}
            text_color={0xFF6A6560}
            max_lines={1}
          />
          <Spacer weight={1.0} />
          <Text
            text={adherence}
            font_family={Kati.Locale.mono_face(adherence)}
            text_size={10}
            text_color={0xFF6A6560}
            max_lines={1}
          />
        </Row>
      </Column>
      <Spacer size={20} />
    </Column>
    """
  end

  # `Kati.Components.MishkaActionIcon` — an icon-only button, here on ink
  # rather than on paper. No `shadow`: this one sits inside the card, and the
  # drawing gives it none; `variant: :filled` on its own is the `background` +
  # `corner_radius` box it replaces, and `shape: :circle` computes 36 / 2 =
  # 18.0, the radius written before.
  #
  # `Palette.on_ink_veil/0` is `rgba(245,242,238,.12)` — a white-ish veil ON
  # the ink card, not a grey — and `Palette.on_ink_glyph/0` is the mark on it.
  # Both invert with the card rather than following the page. The glyph is a
  # child rather than `icon:`, because Kati's icons are Material Symbols
  # through `Kati.UI.symbol/2`; a child is wrapped in a `<Row>` that hugs it,
  # inside a Box that already centred it.
  #
  # ## Why this disc opens screen 50
  #
  # `Kati.Screens.PlanShare`'s drawing opens with a `‹ Plans` back pill and is
  # titled *"Cutting v3 · share & transfer"* — so it is pushed from this
  # screen, over the plan this card names. This disc is the only control the
  # drawing puts on that card, and 49 draws no other affordance that could
  # lead anywhere: the header disc is `add`, the saved rows end in Activate
  # pills, and the Switching group is one chevron and two switches.
  #
  # It is an overflow glyph, so on a platform with menus it would open one and
  # share would be an item in it. Mob has no menu node, and inventing a menu is
  # a bigger fiction than letting the plan's only button reach the plan's only
  # other screen. `on_tap` adds no ink, so the card's resting pixels are the
  # drawing's, unchanged.
  @doc false
  def overflow do
    MishkaActionIcon.action_icon(
      [
        size: 36,
        shape: :circle,
        variant: :filled,
        background: Palette.on_ink_veil(),
        on_tap: :share_plan
      ],
      [UI.symbol("more_horiz", size: 19, color: Palette.on_ink_glyph())]
    )
  end

  # Orange, and allowed to be: this bar is how far through *now* is.
  @doc false
  def progress(fraction) do
    ~MOB"""
    <Box fill_width={true} height={5} corner_radius={3} background={Palette.on_ink_track()}>
      <Row fill_width={true}>
        <Box weight={fraction} height={5} corner_radius={3} background={Kati.Theme.accent()} />
        <Spacer weight={1.0 - fraction} />
      </Row>
    </Box>
    """
  end

  @doc false
  def saved(rows) do
    ~MOB"""
    <Column fill_width={true}>
      {Enum.map(rows, fn row -> Kati.Screens.Plans.saved_row(row) end)}
      <Spacer size={12} />
    </Column>
    """
  end

  # Separate cards with a 10pt gap, not one grouped card with hairlines: each
  # of these is a thing you can activate, so it gets its own edge.
  @doc false
  def saved_row(row) do
    name = Kati.Screens.Plans.plan_name(row.name)
    line = Kati.Screens.Plans.saved_line(row.line)
    meta = Kati.Screens.Plans.saved_meta(row.meta)

    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Palette.card()}
        corner_radius={18}
        shadow={Kati.Theme.shadow_card_soft()}
        padding_left={13}
        padding_right={13}
        padding_top={12}
        padding_bottom={12}
        align="center"
      >
        {Kati.Screens.Plans.thumb(row.seed)}
        <Spacer size={13} />
        <Column weight={1.0}>
          <Text
            text={name}
            text_size={13.5}
            font_weight="bold"
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={4} />
          <Text text={line} text_size={11.5} text_color={Palette.sub()} max_lines={1} />
          <Spacer size={3} />
          <Text
            text={meta}
            font_family={Kati.Locale.mono_face(meta)}
            text_size={10}
            text_color={Palette.rail_idle()}
            max_lines={1}
          />
        </Column>
        <Spacer size={13} />
        {Kati.Screens.Plans.activate(row.action)}
      </Row>
      <Spacer size={10} />
    </Column>
    """
  end

  # `Kati.Components.MishkaPill`: a compact label, no selected state, no tap —
  # which is the port's own dividing line ("a Chip is selected, a Pill is
  # removed"). This one is drawn but not yet wired, so it is a label in the
  # tree as well as in the drawing.
  #
  # The same pixels, one wrapper deeper. The hugging `Row` that carried the
  # `#EFECE7` fill, the 16 radius, 13 of horizontal padding and a 32 height
  # becomes the pill's root `Box fill_width={false}` carrying all four, around
  # a `Row` holding the `Text` and the empty `Row` the unused remove slot
  # leaves behind — a 0x0 node that adds nothing to the line.
  #
  # All four padding edges are named, so the component's `:space_sm` default
  # never reads: `nodeModifier/1` consults the uniform value only for an edge
  # that is missing. The vertical zeros pin the outer height at 32, since the
  # bridge pads before it sizes. `align: :center` stands in for the Row's
  # `align="center"`; horizontally the content box is exactly the Text's width,
  # so only its vertical half has anything to do.
  @doc false
  def activate(label) do
    MishkaPill.pill(
      label: Kati.Screens.Plans.activate_label(label),
      background: Palette.paper(),
      color: :on_surface,
      corner_radius: 16,
      height: 32,
      padding_left: 13,
      padding_right: 13,
      padding_top: 0,
      padding_bottom: 0,
      text_size: 11.5,
      font_weight: :semibold,
      align: :center
    )
  end

  @doc false
  def thumb(seed) do
    case Kati.Design.Images.poster(seed) do
      nil ->
        ~MOB"<Box width={44} height={44} corner_radius={12} background={Palette.placeholder()} />"

      src ->
        ~MOB"""
        <Image src={src} width={44} height={44} corner_radius={12} content_mode="fill" />
        """
    end
  end

  @doc false
  def switching(rows) do
    last = length(rows) - 1

    cards =
      rows
      |> Enum.with_index()
      |> Enum.map(fn {row, i} ->
        SettingsList.row(
          SettingsList.icon_tile(row.icon),
          SettingsList.body(
            Kati.Screens.Plans.switch_title(row.title),
            Kati.Screens.Plans.switch_sub(row.sub)
          ),
          Kati.Screens.Plans.trail(row.trail),
          rule: i < last
        )
      end)

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.card(cards)}
      <Spacer size={22} />
    </Column>
    """
  end

  # A disclosure, not a switch: the first row opens a date rather than toggling
  # a behaviour, and the drawing distinguishes the two.
  @doc false
  def trail(:chevron), do: SettingsList.chevron()
  def trail({:toggle, on?}), do: SettingsList.switch(on?)

  # Not SettingsList.note/2: that one pads 16 and sets its glyph at 18, and
  # this drawing says 15 and 17. FIDELITY's rule is that a number in the export
  # is a number here, so the frame is redrawn rather than approximated.
  @doc false
  def note(text) do
    body = Kati.Screens.Plans.note_text(text)

    ~MOB"""
    <Row
      fill_width={true}
      corner_radius={18}
      border_color={Palette.border()}
      border_width={1.5}
      padding={15}
      align="top"
    >
      {Kati.UI.symbol("info", size: 17, color: Palette.sub())}
      <Spacer size={11} />
      <Text
        text={body}
        text_size={12.5}
        line_height={Kati.Locale.leading(1.55)}
        text_color={Palette.ink_soft()}
        weight={1.0}
      />
    </Row>
    """
  end

  # ── The drawing's copy, in the reader's language ───────────────────────────
  #
  # `Kati.Meals.SampleProfiles` holds this page's copy as composed English
  # sentences — `2,100 kcal · 168P 210C 70F`, `used Mar–Jun` — and it is the
  # one Meals fixture that does not call `gettext/1` for itself the way
  # `Kati.Meals.SamplePlan` and `Kati.Meals.SampleToday` do. Until it does, the
  # translation happens HERE, where each string reaches a `Text`, which is
  # `Kati.Screens.AddToList.count_line/1`'s rule one layer up: *a value decided
  # somewhere else is translated where it is drawn.*
  #
  # Every clause answers the fixture's own English and every function ends in a
  # pass-through, which is the honest fallback in both directions. A plan name
  # that came from `Kati.Meals.MealPlan` is a name a person typed and must not
  # be translated; and the day `Kati.Meals.SampleProfiles` starts calling
  # `gettext/1` for itself, its strings arrive here already Persian and go
  # through untouched. What the arrangement costs is that the figures are
  # written twice — once in the fixture's sentence and once as the numbers
  # `Kati.Locale.number/1` needs — and that is the argument for moving these
  # calls into the fixture the moment somebody owns it.

  @doc """
  `4 saved · 1 active`, counted rather than copied.

  Four is the three rows below plus the one on the ink card, which is what the
  drawing means by *saved* — a figure the reader can count off this page, and
  so the one number here that must not be frozen. The second is the domain
  rule this whole screen is arranged to say rather than a count: exactly one
  plan is active.
  """
  @spec subtitle(map()) :: String.t()
  def subtitle(plans) do
    gettext("%{saved} saved · %{active} active",
      saved: Kati.Locale.number(length(plans.saved) + 1),
      active: Kati.Locale.number(1)
    )
  end

  @doc false
  @spec week_line(String.t()) :: String.t()
  def week_line("Week 6 of 12"),
    do: gettext("Week %{n} of %{total}", n: Kati.Locale.number(6), total: Kati.Locale.number(12))

  def week_line(other), do: other

  @doc """
  A plan's name.

  `Cutting v3` is the msgid `Kati.Meals.SamplePlan` already introduced and
  screens 44 and 50 already draw, so the one plan keeps one Persian name
  wherever it appears. `Maintenance` takes a context because the word here is
  the WEIGHT sense — نگه‌داری, holding a figure steady — and a catalogue that
  let it merge with a maintenance *mode* somewhere else would translate one of
  the two wrongly with nothing failing.

  Anything else is a name somebody typed, and is returned as it was given.
  """
  @spec plan_name(String.t()) :: String.t()
  def plan_name("Cutting v3"), do: gettext("Cutting v3")
  def plan_name("Maintenance"), do: pgettext("a saved meal plan's name", "Maintenance")
  def plan_name("Travel week"), do: gettext("Travel week")
  def plan_name("Jo’s plan"), do: gettext("Jo’s plan")
  def plan_name(entered), do: entered

  # The macro letters are INSIDE the msgid because they are letters: board 294
  # writes ۱۶۸پ ۲۱۰ک ۷۰چ, the initials of پروتئین، کربوهیدرات، چربی. The
  # thousands comma is not translated — `Kati.Locale.number/1` converts the
  # digits and leaves the grouping mark alone, which is what board 59 draws
  # (۱,۴۸۰) and what 294 draws here (۲,۱۰۰).
  @doc false
  @spec targets_line(String.t()) :: String.t()
  def targets_line("2,100 kcal · 168P 210C 70F") do
    gettext("%{kcal} kcal · %{protein}P %{carbs}C %{fat}F",
      kcal: Kati.Locale.number("2,100"),
      protein: Kati.Locale.number(168),
      carbs: Kati.Locale.number(210),
      fat: Kati.Locale.number(70)
    )
  end

  def targets_line(other), do: other

  @doc false
  @spec started_line(String.t()) :: String.t()
  def started_line("started 6 Jul"),
    do: gettext("started %{date}", date: Kati.Locale.date(@started, :short))

  def started_line(other), do: other

  @doc false
  @spec adherence_line(String.t()) :: String.t()
  def adherence_line("86% adherence"),
    do: gettext("%{percent}% adherence", percent: Kati.Locale.number(86))

  def adherence_line(other), do: other

  @doc "The middle line of a saved row: what the plan is, in one phrase."
  @spec saved_line(String.t()) :: String.t()
  def saved_line("2,450 kcal · 5 meals") do
    ngettext("%{kcal} kcal · %{n} meal", "%{kcal} kcal · %{n} meals", 5,
      kcal: Kati.Locale.number("2,450"),
      n: Kati.Locale.number(5)
    )
  end

  def saved_line("3 meals · no prep"),
    do: ngettext("%{n} meal · no prep", "%{n} meals · no prep", 3, n: Kati.Locale.number(3))

  def saved_line("shared with you"), do: gettext("shared with you")
  def saved_line(other), do: other

  @doc """
  The mono line under a saved row: when the plan was last in use, or what it is.

  `used Mar–Jun` is named out of two `Date`s rather than out of the words
  *Mar* and *Jun*, for `month_name/2`'s own reason: March 2026 is اسفند and
  June is خرداد, and no arithmetic on the numbers 3 and 6 produces either.
  """
  @spec saved_meta(String.t()) :: String.t()
  def saved_meta("used Mar–Jun") do
    gettext("used %{from}–%{to}",
      from: Kati.Locale.month_name(@used_from, :short),
      to: Kati.Locale.month_name(@used_to, :short)
    )
  end

  def saved_meta("used 4 times"),
    do: ngettext("used %{n} time", "used %{n} times", 4, n: Kati.Locale.number(4))

  def saved_meta("vegetarian"), do: pgettext("a saved plan's dietary tag", "vegetarian")
  def saved_meta(other), do: other

  @doc false
  @spec activate_label(String.t()) :: String.t()
  def activate_label("Activate"), do: gettext("Activate")
  def activate_label(other), do: other

  @doc false
  @spec switch_title(String.t()) :: String.t()
  def switch_title("Switch takes effect"), do: gettext("Switch takes effect")
  # The msgid `Kati.Screens.MealEdit.plan_group/0` introduced, deliberately
  # shared: it is the same toggle over the same promise, and one toggle with
  # two Persian names is how a settings page stops reading as one page.
  def switch_title("Keep the history"), do: gettext("Keep the history")
  def switch_title("Switch on a date"), do: gettext("Switch on a date")
  def switch_title(other), do: other

  @doc """
  The line under a Switching row.

  **`Kati.Locale.week_start/0`, not the word Monday.**
  `Kati.Screens.MealEdit.plan_group/0` draws the same row in the same kind of
  card and interpolates the same helper, under board 137's ruling that the
  week's first day follows the language chosen in step one. A Persian page
  promising a Monday rollover promises a day its own week does not turn over
  on — and board 294 writes دوشنبه here, which is the one place that board is
  not followed.
  """
  @spec switch_sub(String.t()) :: String.t()
  def switch_sub("Next Monday · keeps this week intact"),
    do: gettext("Next %{day} · keeps this week intact", day: Kati.Locale.week_start())

  def switch_sub("Past days stay on their old plan"),
    do: gettext("Past days stay on their old plan")

  # The plan named here is the saved row two cards up, so it is named through
  # `plan_name/1` rather than written out again: one plan, one Persian name.
  def switch_sub("Travel week takes effect next Monday") do
    gettext("%{plan} takes effect next %{day}",
      plan: Kati.Screens.Plans.plan_name("Travel week"),
      day: Kati.Locale.week_start()
    )
  end

  def switch_sub(other), do: other

  @doc false
  @spec note_text(String.t()) :: String.t()
  def note_text(@drawn_note) do
    gettext(
      "A plan owns its meals, targets and reminder times. Switching swaps " <>
        "all three at once — nothing has to be re-entered when you come " <>
        "back to an old one."
    )
  end

  def note_text(other), do: other

  # One clause and no `_tag` catch-all, deliberately. A catch-all here would
  # answer every future control with silence, and `Kati.Screens.Pushed`'s
  # moduledoc is explicit that the DEAD TAP report is the only thing that can
  # see a button whose resting pixels are correct and whose wiring is absent.
  # The Activate pills are drawn without a tap and so are not reported; the
  # moment one grows one, this screen says so.
  @impl true
  # Screen 120 is the other half of 50: one screen shares a plan and the other
  # takes one in. The import row is on Plans because that is where a plan you
  # have been sent has to land.
  def handle_tap(:import_plan, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.PlanImport)}

  def handle_tap(:share_plan, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.PlanShare)}
end
