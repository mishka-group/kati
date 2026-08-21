defmodule Kati.Screens.MealReminders do
  @moduledoc """
  Screen 51 — meal reminders, pushed under Meals.

  Built to `.scratch/design/screens/51.html`. Both halves of the reminder are
  drawn as the notifications they actually become rather than as settings that
  describe them: a 20:00 preview that lists what to prep, and a 15-minute
  warning carrying **Eaten / Skip / Snooze** so it can be answered from the
  lock screen. Drawing the buttons inside the preview is what makes the
  footnote — "no need to open the app" — checkable rather than claimed.

  The evening card is cream and the meal card is white, and the previews inside
  them are grounded to match: `rgba(255,255,255,.6)` over cream, paper over
  card. The label colours follow, `#B09A72` on cream and `#A0998F` on paper,
  which is the palette's rule that cream warms rather than tints.

  **Manners** is the counterweight and belongs on this screen rather than in
  Settings. Meals is the one section allowed to push by default; the price is
  quiet hours, calendar awareness, a stop after two skips, and a silent mode
  that behaves like the release watcher's Home card.

  The option list nested inside the cream card and the Manners list are both
  `Kati.UI.SettingsList` — the same card and row every Settings screen uses,
  so an option under a reminder reads as an option rather than as a second kind
  of thing. Only the row padding differs, 12 inside the card and 13 outside it,
  which is the drawing's own difference.

  ## Nothing in the design opens this screen

  Every other Meals screen is reached from the tile row or the title pill on
  screen 43, and each of those destinations is identifiable because its own
  drawing opens with a `‹ Meals` back pill: 44, 45, 47, 48, 49. This screen
  carries that same pill and has no matching control anywhere. Checked, glyph
  by glyph: 43 draws `calendar_view_week`, `shopping_cart`, `monitoring`,
  `tune`, `unfold_more` and a per-meal `more_horiz` — four tiles, a plan
  picker and a meal's own actions, none of them a bell. 44 draws `edit`,
  `repeat`, `event_available` and `edit_calendar`. 47 draws `ios_share` and
  `lightbulb`. 48 draws `ios_share` and `add`. 49 draws `add`, `more_horiz`
  (screen 50) and the Switching group. 50's only reminder row is the
  *Reminder times* switch under "what travels with it", which is a toggle on
  the export, not a way in. Screen 24 Settings has no Meals row at all — its
  Sections group is Books, Music, Habits, Money — so the usual
  Settings-pushes-a-detail route is not drawn either.

  So the entry point is missing from the **design**, not from the code, and
  the honest state is to leave it: `Kati.Screens.Gallery` reaches it for
  comparison against the drawing, and inventing a row on 43 or on Settings
  would change a resting screen the drawing does not change. When the design
  grows the control, one `handle_tap/2` clause on whichever screen draws it is
  the whole fix.

  No dock, so the frame's bottom inset is 40 rather than 132.
  """
  use Kati.Screens.Pushed, back: "Meals"

  alias Kati.Meals.SampleReminders
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  @impl true
  def load(socket), do: Mob.Socket.assign(socket, :reminders, SampleReminders.reminders())

  @doc false
  def content(assigns) do
    r = assigns.reminders

    ~MOB"""
    <Scroll>
      <Column fill_width={true} padding_left={21} padding_right={21} padding_top={64} padding_bottom={40}>
        {SettingsList.chrome("more_horiz")}
        {SettingsList.title("Reminders", r.subtitle)}
        {UI.eyebrow("The day before")}
        {Kati.Screens.MealReminders.day_before(r.day_before)}
        {UI.eyebrow("On the day")}
        {Kati.Screens.MealReminders.on_the_day(r.on_the_day)}
        {SettingsList.eyebrow_muted("Manners")}
        {Kati.Screens.MealReminders.manners(r.manners)}
        {Kati.Screens.MealReminders.note(r.note)}
      </Column>
    </Scroll>
    """
  end

  @doc false
  def day_before(d) do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.cream()}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={18}
      >
        {Kati.Screens.MealReminders.card_head(d, Palette.gold_icon(), Palette.cream_meta())}
        <Spacer size={15} />
        {Kati.Screens.MealReminders.preview(d.notification, Palette.cream_raise(), Palette.cream_meta(), Palette.cream_sub())}
        <Spacer size={14} />
        {Kati.Screens.MealReminders.options(d.options)}
      </Column>
      <Spacer size={14} />
    </Column>
    """
  end

  @doc false
  def on_the_day(o) do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={18}
      >
        {Kati.Screens.MealReminders.card_head(o, Palette.ink(), Palette.muted())}
        <Spacer size={15} />
        {Kati.Screens.MealReminders.preview(o.notification, Palette.paper(), Palette.eyebrow(), Palette.sub())}
        <Spacer size={13} />
        <Row fill_width={true} align="center">
          {Kati.UI.symbol("touch_app", size: 15, color: Palette.tertiary())}
          <Spacer size={8} />
          <Text text={o.foot} text_size={11.5} text_color={Palette.sub()} weight={1.0} />
        </Row>
      </Column>
      <Spacer size={14} />
    </Column>
    """
  end

  # The cadence line is already upper case in the drawing's own copy — there is
  # no text-transform on it — so it is not upcased here.
  @doc false
  def card_head(card, icon_color, cadence_color) do
    ~MOB"""
    <Row fill_width={true} align="center">
      {Kati.UI.symbol(card.icon, size: 23, color: icon_color)}
      <Spacer size={13} />
      <Column weight={1.0}>
        <Text text={card.title} text_size={14.5} font_weight="bold" text_color={:on_surface} max_lines={1} />
        <Spacer size={4} />
        <Text text={card.cadence} font_family="mono" text_size={10.5} text_color={cadence_color} max_lines={1} />
      </Column>
      <Spacer size={13} />
      {Kati.UI.SettingsList.switch(card.on)}
    </Row>
    """
  end

  @doc """
  A notification, drawn where it will arrive.

  The app icon is the design's own mark — an ink square with an accent dot —
  rather than a bitmap, so it stays crisp at 20pt and needs no asset.
  """
  def preview(n, ground, label_color, body_color) do
    ~MOB"""
    <Column fill_width={true} background={ground} corner_radius={16} padding={14}>
      <Row fill_width={true} align="center">
        {Kati.Screens.MealReminders.app_icon()}
        <Spacer size={9} />
        <Text
          text={n.from}
          font_family="mono"
          text_size={9.5}
          letter_spacing={0.1}
          text_color={label_color}
          max_lines={1}
        />
      </Row>
      <Spacer size={9} />
      <Text text={n.title} text_size={13.5} font_weight="bold" text_color={:on_surface} />
      <Spacer size={5} />
      <Text text={n.body} text_size={12.5} line_height={1.45} text_color={body_color} />
      {Kati.Screens.MealReminders.preview_actions(n)}
    </Column>
    """
  end

  @doc """
  The app's own mark, as a notification's 20pt icon.

  `Kati.Components.MishkaThemeIcon` — "a themed container around exactly one
  icon" — for the same reason `Kati.UI.SettingsList.icon_tile/1` uses it. The
  one icon here is the design's accent dot rather than a glyph, and children
  are explicitly "any node", so the shorthand is not involved either way.

  ## Why the pixels do not move

  With children, an explicit numeric `color`, no `id` and no `on_tap`,
  `theme_icon/2` returns
  `%{type: :box, props: %{width: 20, height: 20, align: :center,
  corner_radius: 6, background: Palette.ink()}, children: [dot]}` — node for
  node what this wrote by hand. `align: :center` and `align="center"` reach the
  bridge as the same string, the gradient layer is empty for `:filled`, and
  the id markers are skipped without an `id`.

  `Palette.ink/0`, not `ink_fill/0`: this is a MARK, the app's own square, and
  it follows the page rather than inverting like a control does. Pinning it
  light would draw a near-black square on a near-black preview — an icon that
  is simply not there. The accent dot on it is a hue and does not move.
  """
  def app_icon do
    Kati.Components.MishkaThemeIcon.theme_icon(
      %{variant: :filled, color: Palette.ink(), size: 20, radius: 6},
      [~MOB"<Box width={6} height={6} corner_radius={3} background={Kati.Theme.accent()} />"]
    )
  end

  @doc false
  def preview_actions(%{actions: actions}) do
    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={12} />
      <Row fill_width={true} align="center">
        {actions
         |> Enum.with_index()
         |> Enum.map(fn {label, i} -> Kati.Screens.MealReminders.preview_action(label, i == 0) end)
         |> Enum.intersperse(Kati.Screens.MealReminders.action_gap())}
      </Row>
    </Column>
    """
  end

  def preview_actions(_notification), do: ~MOB"<Spacer size={0} />"

  @doc false
  def action_gap, do: ~MOB"<Spacer size={7} />"

  @doc false
  def preview_action(label, primary?) do
    bg = if primary?, do: Palette.ink_fill(), else: Palette.card()
    fg = if primary?, do: Palette.on_ink(), else: Palette.ink_soft()

    ~MOB"""
    <Box weight={1.0}>
      <Box fill_width={true} height={30} corner_radius={15} background={bg} align="center">
        <Text text={label} text_size={11.5} font_weight="semibold" text_color={fg} max_lines={1} />
      </Box>
    </Box>
    """
  end

  @doc false
  def options(rows), do: SettingsList.card(Kati.Screens.MealReminders.switch_rows(rows, 12))

  @doc false
  def manners(rows) do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.card(Kati.Screens.MealReminders.switch_rows(rows, 13))}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def switch_rows(rows, pad) do
    last = length(rows) - 1

    rows
    |> Enum.with_index()
    |> Enum.map(fn {row, i} ->
      SettingsList.row(
        SettingsList.icon_tile(row.icon),
        SettingsList.body(row.title, row.sub),
        SettingsList.switch(row.on),
        padding: pad,
        rule: i < last
      )
    end)
  end

  # Not SettingsList.note/2: that one pads 16 and sets its glyph at 18, and
  # this drawing says 15 and 17. FIDELITY's rule is that a number in the export
  # is a number here, so the frame is redrawn rather than approximated.
  @doc false
  def note(text) do
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
      <Text text={text} text_size={12.5} line_height={1.55} text_color={Palette.ink_soft()} weight={1.0} />
    </Row>
    """
  end
end
