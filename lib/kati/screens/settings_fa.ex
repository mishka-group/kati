defmodule Kati.Screens.SettingsFa do
  @moduledoc """
  Screen 62 — تنظیمات, the Persian mirror of Settings.

  Built to `.scratch/design/screens/62.html`. Pushed under خانه (Home), so no
  dock and a bottom inset of **40, not 132**.

  ## Two glyphs point opposite ways here, and both are right

  The back pill takes `arrow_forward_ios` and every disclosure row takes
  `chevron_left`. In Persian, back is rightwards and forward is leftwards, so
  the pair reads correctly only when both are mirrored — and Material Symbols
  are text in a font, which nothing auto-mirrors. A screen that flips one and
  not the other sends the reader in both directions at once.

  `layout_direction="rtl"` is a literal, as on the other Persian screens: the
  copy is Persian, so this screen is right-to-left whatever the app's locale
  says. Only `MainActivity` acts on the prop, and only on the root node.

  ## The switch is drawn rather than delegated, and no prop can change that

  `Kati.Components.MishkaSwitch` wraps Compose's own `Switch`, which brings
  platform metrics and platform animation with it. The design specifies a
  46x28 track with a 22pt thumb on a 3pt inset, in two exact colours — screen
  41 reached the same conclusion. Fidelity wins over reuse for the one control
  the drawing measures.

  This one is not waiting on an upstream prop. `MishkaToggle`'s own moduledoc
  states the difference between the two components in exactly these terms:
  *"`MishkaSwitch` bottoms out in Mob's `<Toggle>`, which is Compose's Material
  `Switch`: its track (52x32), its handles (24 on, 16 off) and its 2dp outline
  are constants inside material3… that one needs a different native node, not
  a wider prop list."* Nor is `MishkaToggle` the substitute — it is a
  square-cornered pressed button, and the three lookalikes are kept visually
  distinct on purpose so a user can tell a setting from a filter from a
  formatting button. A sliding track is what a settings row means.

  The numbers say it plainly. `SwitchTokens` in Material 3 1.2.0 — the version
  `compose-bom:2024.02.00` resolves — fixes `TrackWidth` at **52**,
  `TrackHeight` at **32**, and the handle at **24** selected / **16** idle.
  Nothing on the `Switch` composable takes a size, so 46x28 with a 22pt thumb
  is not reachable through it at all. Colour would not survive either:
  `MobToggle` (`MobBridge.kt:2918`) reads only `color`, and builds
  `SwitchDefaults.colors(checkedThumbColor = color)` from it — the port's
  documented `track_color` prop is decoded in Elixir and then never read, so
  this screen's `#DCD7CF` idle track has nowhere to go.

  ## The controls behave exactly as screen 24's do

  Every toggle row taps to flip, the پوسته segments tap to select, and the
  account card's section count is the بخش‌ها group's own tally rather than a
  quoted number. `Kati.Fa.SampleSettings` still states the defaults, so at rest
  this is what `62.html` draws: خودکار raised, مالی off, the other four on.

  Tap tags are ASCII and positional — `toggle_2_4`, `theme_1` — not the row's
  Persian title. A tag becomes an atom and an `accessibility_id`, and the
  capture tooling reads that id; keeping it out of the script keeps the tag
  legible in a log written left-to-right. The two Data rows added this round
  follow the same rule and key on the row's **glyph** — `go_upload`, `go_sync`
  — which is the one part of a row that is not copy; see `@destinations`.

  ## داده‌ها reaches the backup and sync engines, and its date is real

  Two rows under داده‌ها now open something: برون‌ریزی همه‌چیز pushes
  `Kati.Screens.Backup` and همگام‌سازی pushes `Kati.Screens.Sync`, the same two
  destinations screen 24's own Data group names. Both engines were finished and
  proven on device long before either screen existed, and nothing in the app
  invoked them, which made them exactly as useful to a user as no engine at all.

  The برون‌ریزی row's second line follows from that. `۱۴ مرداد` was a literal in
  `Kati.Fa.SampleSettings` with nothing behind it; it is now
  `Kati.Screens.Settings.last_backup/0` — one setting, read through the screen
  that owns it, exactly as پوسته reads the appearance choice — rendered in
  Shamsi by `backup_line/1`, or stated as an absence when there has been no
  backup. `Kati.Screens.Settings`' moduledoc argues what is recorded, when, and
  why the store is a note about the backup rather than the backup.

  ## پوسته writes the app's appearance choice, and does it through screen 24

  The three tiles are the same control screen 24 draws, so they had better mean
  the same thing. `Kati.Theme.Mode` owns the setting; `Kati.Screens.Settings`
  holds the wrapper over it, and this screen calls exactly four of those
  functions — `choice/0`, `put_choice/1`, `label_for/2`, `choice_at/1` — rather
  than keeping a second copy, because a boundary written twice is rewired once
  and then wrong.

  Nothing here has to know that خودکار means auto. The tags already carry the
  tile's **position**, `Kati.Theme.Mode.choices/0` is in that same order in both
  drawings, and the choice falls out of the index — which is the only reason a
  Persian screen and an English one can share this without a translation table
  between them.
  """
  use Mob.Screen
  import Mob.Sigil

  alias Kati.Components.MishkaAvatar
  alias Kati.Components.MishkaSeparator
  alias Kati.Components.MishkaThemeIcon
  alias Kati.Design.Images
  alias Kati.Fa.SampleSettings
  alias Kati.Screens.Fa
  alias Kati.Theme
  alias Kati.Theme.Palette

  def mount(_params, _session, socket) do
    Kati.Theme.activate()
    {:ok, Mob.Socket.assign(socket, :settings, settle(SampleSettings.settings()))}
  end

  # The sample names a segmented control's options but not which one is picked,
  # because until now nothing could pick. The selection is written in once, on
  # mount, so from then on a tap is an ordinary change to a shape that already
  # exists.
  #
  # It used to be the first option unconditionally. It is now the tile standing
  # for the **stored appearance choice**, read through the boundary that
  # `Kati.Screens.Settings` owns — see the moduledoc. `خودکار` is the first
  # option and `:auto` is what a choice never made reads as, so an untouched
  # install settles on exactly what it settled on before, which is what 62.html
  # raises.
  defp settle(settings) do
    sections =
      Enum.map(settings.sections, fn section ->
        %{section | rows: Enum.map(section.rows, &settle_row/1)}
      end)

    %{settings | sections: sections}
  end

  defp settle_row(%{trailing: {:segmented, options}} = row) do
    label = Kati.Screens.Settings.label_for(options, Kati.Screens.Settings.choice())
    %{row | trailing: {:segmented, options, label}}
  end

  defp settle_row(row), do: row

  def render(assigns) do
    settings = assigns.settings

    ~MOB"""
    <Box fill_width={true} fill_height={true} background={:background} layout_direction="rtl">
      <Scroll>
        <Column
          fill_width={true}
          padding_left={21}
          padding_right={21}
          padding_top={64}
          padding_bottom={40}
        >
          {Kati.Screens.SettingsFa.header(settings)}
          {Kati.Screens.SettingsFa.title(settings)}
          {Kati.Screens.SettingsFa.me(settings)}
          {Kati.Screens.SettingsFa.sections(settings)}
        </Column>
      </Scroll>
    </Box>
    """
  end

  @doc false
  def header(settings) do
    back = {self(), :back}

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        <Row
          height={44}
          corner_radius={22}
          background={Palette.card()}
          shadow={Theme.shadow_button()}
          padding_left={12}
          padding_right={16}
          align="center"
          on_tap={back}
        >
          {Kati.UI.symbol("arrow_forward_ios", size: 17)}
          <Spacer size={6} />
          <Text
            text={settings.back}
            font_family="fa"
            text_size={13.5}
            font_weight="semibold"
            text_color={:on_surface}
            max_lines={1}
          />
        </Row>
        <Spacer weight={1.0} />
        {Fa.disc("help")}
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc false
  def title(settings) do
    ~MOB"""
    <Column fill_width={true}>
      <Text
        text={settings.title}
        font_family="fa"
        text_size={27}
        font_weight="bold"
        line_height={1.35}
        text_color={:on_surface}
        max_lines={1}
      />
      <Spacer size={5} />
      <Text
        text={settings.subtitle}
        font_family="fa"
        text_size={11.5}
        text_color={Palette.muted()}
        max_lines={1}
      />
      <Spacer size={20} />
    </Column>
    """
  end

  @doc false
  def me(settings) do
    me = settings.me
    count = Kati.Screens.SettingsFa.enabled(settings.sections)
    meta = Kati.Screens.SettingsFa.meta(me.meta, count)

    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        shadow={Theme.shadow_card_soft()}
        padding={16}
        align="center"
      >
        {Kati.Screens.SettingsFa.avatar(me.seed)}
        <Spacer size={14} />
        <Column weight={1.0}>
          <Text
            text={me.name}
            font_family="fa"
            text_size={15.5}
            font_weight="bold"
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={4} />
          <Text
            text={meta}
            font_family="fa"
            text_size={11}
            text_color={Palette.muted()}
            max_lines={1}
          />
        </Column>
        <Spacer size={14} />
        <Row
          height={26}
          corner_radius={13}
          background={Palette.green_wash()}
          padding_left={10}
          padding_right={10}
          align="center"
        >
          {Kati.UI.symbol("cloud_done", size: 14, color: Palette.green_text())}
          <Spacer size={5} />
          <Text
            text={me.sync}
            font_family="fa"
            text_size={11}
            font_weight="semibold"
            text_color={Palette.green_text()}
            max_lines={1}
          />
        </Row>
      </Row>
      <Spacer size={24} />
    </Column>
    """
  end

  # `Kati.Components.MishkaAvatar`, not a hand-drawn Image with a Box behind
  # it: a circular face with a coloured fallback under it is what the component
  # *is*, and it carries the seed-missing branch that used to be written out
  # here. `:circle` resolves to an exact `size / 2`, so 52 still rounds at 26.
  #
  # The pixels do not move in either state. With no image it draws the same
  # 52x52 disc in the same `#E4E0D9`, plus an empty initials `Text` that
  # renders nothing inside a box already sized to 52. With an image it stacks
  # `[fallback, image]`, and the design's photographs are opaque JPEGs at the
  # same 52x52 with the same radius, so the image covers the fallback exactly
  # rather than tinting it.
  #
  # It is also the one component on this screen that can carry Persian copy —
  # because it carries none. Nothing in the vendored set accepts
  # `font_family`, and an unstyled `Text` is Plus Jakarta Sans, which has zero
  # code points in U+0600-U+06FF. The initials here are the empty string, so
  # there is no glyph to lose.
  @doc false
  def avatar(seed) do
    MishkaAvatar.avatar(src: Images.poster(seed), size: 52, background: Palette.placeholder())
  end

  # The one group whose switches are sections. کاهش حرکت is a toggle too, but
  # it is a preference — counting it would make the header claim a section that
  # does not exist.
  @sections_label "بخش‌ها"

  @doc """
  How many sections are switched on right now, or `nil` if the group moved.

  `nil` rather than zero on a miss, because `meta/2` then leaves the sample's
  own line alone: a count that silently reads ۰ would rewrite the resting frame
  the moment the label changed.
  """
  def enabled(sections) do
    case Enum.find(sections, fn section -> section.label == @sections_label end) do
      nil -> nil
      section -> Enum.count(section.rows, &match?(%{trailing: {:toggle, true}}, &1))
    end
  end

  @doc """
  The account line with its section count replaced by the live tally.

  A substitution on the sample's own string rather than a rebuilt one, so the
  copy stays in `Kati.Fa.SampleSettings` and the resting frame cannot drift:
  with four sections on, this rewrites ۴ as ۴. Anything that fails to match —
  a missing separator, a Latin numeral — returns the line untouched.
  """
  def meta(text, nil), do: text

  def meta(text, count) do
    case String.split(text, " · ", parts: 2) do
      [head, tail] ->
        head <> " · " <> Regex.replace(~r/^[\x{06F0}-\x{06F9}]+/u, tail, fa_number(count))

      _ ->
        text
    end
  end

  # Persian digits are their own code points, and the sample writes every
  # numeral in them. A count rendered 4 beside ۱,۲۰۴ would be the only Latin
  # digit on the screen.
  @fa_numerals ["۰", "۱", "۲", "۳", "۴", "۵", "۶", "۷", "۸", "۹"]

  defp fa_number(n) do
    numerals = @fa_numerals

    n
    |> Integer.to_string()
    |> String.to_charlist()
    |> Enum.map_join(fn c -> Enum.at(numerals, c - ?0) end)
  end

  # The last section carries no bottom gap — the drawing wraps only the first
  # three in a `margin-bottom:22px` block, and the frame's own 40 closes the
  # page.
  @doc false
  def sections(settings) do
    last = length(settings.sections) - 1

    ~MOB"""
    <Column fill_width={true}>
      {settings.sections
       |> Enum.with_index()
       |> Enum.map(fn {section, i} -> Kati.Screens.SettingsFa.section(section, i < last, i) end)}
    </Column>
    """
  end

  @doc false
  def section(section, gap?, si) do
    last = length(section.rows) - 1

    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.SettingsFa.eyebrow(section.label, section.dash)}
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
        {section.rows
         |> Enum.with_index()
         |> Enum.map(fn {row, i} -> Kati.Screens.SettingsFa.row(row, i < last, si, i) end)}
      </Column>
      {Kati.Screens.SettingsFa.section_gap(gap?)}
    </Column>
    """
  end

  @doc false
  def section_gap(false), do: ~MOB"<Spacer size={0} />"
  def section_gap(true), do: ~MOB"<Spacer size={22} />"

  @doc """
  The section label, in Persian.

  `Kati.UI.eyebrow/2` is DM Mono, uppercased and letter-spaced. The drawing's
  Persian labels are Vazirmatn at 11 semibold with `letter-spacing:0` — Persian
  has no case, and tracking it apart breaks the joins between letters. The
  muted dash is the design's mark for a section you visit rather than set up.
  """
  def eyebrow(label, dash) do
    color = if dash == :muted, do: Palette.rail_idle(), else: Theme.accent()

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_left={2} padding_right={2}>
        <Box width={13} height={2} corner_radius={1} background={color} />
        <Spacer size={9} />
        <Text
          text={label}
          font_family="fa"
          text_size={11}
          font_weight="semibold"
          text_color={Palette.eyebrow()}
        />
      </Row>
      <Spacer size={11} />
    </Column>
    """
  end

  @doc """
  One row, tappable along its whole width when it carries a toggle or leads
  somewhere.

  Screen 24 does the same, and for the same reason: a 46pt track is a small
  target and the row already reads as one object. A chevron row whose
  destination is not built stays inert — a row that lights up and goes nowhere
  is a worse promise than a row that does nothing — which as of this round is
  every chevron row here except the two under داده‌ها that `@destinations` names.

  ## Not `Kati.Components.MishkaNavLink`, which is the component for this shape

  A leading glyph, a title, a second line under it, a trailing chevron and a
  tap is precisely what that component draws, and its `icon` and `trailing`
  slots take "a glyph string, node, or list" — so the 30pt tile from
  `leading/1` and the mirrored `chevron_left` would both go straight in as
  nodes, the same door `leading/1` itself walks through.

  Two things stop it, and the first is decisive:

    * **`label` and `description` are strings the component turns into `Text`
      itself.** Every title and sub-line here is Persian, and no component in
      the vendored set takes `font_family`, so both lines would draw as blank
      boxes in Plus Jakarta Sans. `icon` and `trailing` being slots while the
      words are props is the exact asymmetry that makes this component reach
      99% of the way and stop: give `label` the treatment `icon` already has
      and this row is `MishkaNavLink`.
    * **No type or metric props at all.** Its prop table carries `indent` and
      nothing else dimensional — no `text_size`, no `font_weight`, no padding,
      no colours. The drawing pins the title at 13.5/semibold on `#1A1917`, the
      sub at 11.5 on `#8A8479`, and 13 of padding above and below; the
      component's ink is `:primary` when `active` and the theme's otherwise.
      Even with a label slot, the 13/13 padding would have to arrive as a prop.

  The hairline under the row is `hairline/1`, which **is** the component — see
  its own doc.
  """
  def row(row, rule?, si, ri) do
    tap = Kati.Screens.SettingsFa.tap_for(row, si, ri)
    sub = Kati.Screens.SettingsFa.sub(Kati.Screens.SettingsFa.sub_for(row))

    ~MOB"""
    <Column fill_width={true} on_tap={tap}>
      <Row fill_width={true} align="center" padding_top={13} padding_bottom={13}>
        {Kati.Screens.SettingsFa.leading(row)}
        <Spacer size={13} />
        <Column weight={1.0}>
          <Text
            text={row.title}
            font_family="fa"
            text_size={13.5}
            font_weight="semibold"
            text_color={:on_surface}
            max_lines={1}
          />
          {sub}
        </Column>
        <Spacer size={13} />
        {Kati.Screens.SettingsFa.trailing(row.trailing)}
      </Row>
      {Kati.Screens.SettingsFa.hairline(rule?)}
    </Column>
    """
  end

  # Which rows lead somewhere, keyed by the row's **glyph** rather than by its
  # Persian title. Two reasons, and the first is the one that matters:
  #
  #   * The tag has to survive the bridge. Every other tag this screen draws is
  #     ASCII and positional (`toggle_0_1`, `theme_2`) because a tag is an atom
  #     that crosses into Kotlin and back; `برون‌ریزی همه‌چیز` carries a
  #     zero-width non-joiner, and a tag nobody can read in a log is a tag
  #     nobody can debug.
  #   * The glyph is the one part of these rows that is not copy, so screen 24
  #     and this screen name the same destinations without a translation table
  #     between them — the same reason the theme trough tags by position.
  @destinations %{
    "upload" => Kati.Screens.Backup,
    "sync" => Kati.Screens.Sync,
    # The two the second wave added, keyed on the glyph for the reason above:
    # screen 24 and this screen name the same destinations without a
    # translation table between them.
    "subscriptions" => Kati.Screens.MyServicesFa,
    "dns" => Kati.Screens.DataSourcesFa,
    "info" => Kati.Screens.AttributionFa
  }

  @doc false
  def destinations, do: @destinations

  @doc """
  A row's tap tag: a toggle flips by position, a row that names a screen opens
  it, everything else is inert.

  The language row carries `badge:` and no `icon:`, so it cannot match the
  glyph-keyed destination clause — a map without the key does not match a
  pattern that names it — and it gets a clause of its own.

  That row is the only way out of Persian. Screen 62 draws no other language
  control and the Persian dock has four tabs, none of them Settings' English
  twin, so while تغییر was inert a reader who chose فارسی on screen 53 could
  not get back: every route from here stays inside the eight Persian screens.
  `Kati.Screens.Language` is screen 54, and it is written for exactly this —
  its own comment notes that `:choose_language_en` "can only ever be sent from
  a `:fa` app".
  """
  def tap_for(%{trailing: {:toggle, _}}, si, ri),
    do: {self(), String.to_atom("toggle_#{si}_#{ri}")}

  def tap_for(%{icon: icon}, _si, _ri) when is_map_key(@destinations, icon),
    do: {self(), String.to_atom("go_" <> icon)}

  def tap_for(%{badge: _badge}, _si, _ri), do: {self(), :go_language}

  def tap_for(_row, _si, _ri), do: nil

  @doc """
  A row's second line: the sample's copy, except on the برون‌ریزی row, which
  reports the backup ledger.

  The reading is `Kati.Screens.Settings.last_backup/0` — one setting, read
  through the screen that owns it, exactly as this screen reads the appearance
  choice. Only the sentence is this file's, because only the sentence is
  Persian: `Kati.Calendar.Shamsi.format/2` at `:short` is `۱۴ مرداد`, which is
  the form 62.html draws.
  """
  def sub_for(%{icon: "upload"}),
    do: Kati.Screens.SettingsFa.backup_line(Kati.Screens.Settings.last_backup())

  def sub_for(%{sub: sub}), do: sub

  @doc """
  What the برون‌ریزی row's second line says, given a backup time or `nil`.

  `هنوز پشتیبانی گرفته نشده` is impersonal, like every other sub-line on this
  screen, and states an absence rather than raising an error — the empty value
  `.scratch/tickets/D-06.md` asks to read as a gentle warning.
  """
  @spec backup_line(DateTime.t() | nil) :: String.t()
  def backup_line(nil), do: "هنوز پشتیبانی گرفته نشده"

  def backup_line(%DateTime{} = at),
    do: "آخرین پشتیبان " <> Kati.Calendar.Shamsi.format(DateTime.to_date(at), :short)

  @doc """
  A row's 30pt leading tile, as `Kati.Components.MishkaThemeIcon`.

  The language row's tile carries two letters instead of a glyph — the design
  names the language in the language, which no icon can do — and both clauses
  are otherwise the same tile.

  This was `MishkaActionIcon` territory and could not be reached: that
  component's radius comes from a two-value `shape` (`:rounded` -> the
  `:radius_md` token, `:circle` -> `size / 2`), and this tile's is 9.
  `MishkaThemeIcon.radius/1` takes **a number** — `n when is_number(n) -> n` —
  so 9 is simply sayable, and that is the whole of what unblocked it.

  Node for node it is the map the sigil built. With no `id` the component adds
  no markers, so `theme_icon/2` returns

      %{type: :box,
        props: %{width: 30, height: 30, align: :center,
                 corner_radius: 9, background: 0xFFEFECE7},
        children: [glyph]}

  and the markup's map differs only in `align` being the string `"center"`
  rather than the atom — which `:json.encode/1` renders as that same string,
  and `boxAlignProp` reads with `props["align"] as? String`
  (`MobBridge.kt:4298`).

  ## This is the one component on the Persian screens that draws Persian

  The فا badge is `font_family="fa"` at 12/bold in card white, and it survives
  because it goes in as a **child**. Nothing in `Kati.Components` accepts
  `font_family`, so any component that builds its own label is out of reach
  here — but this one's `icon` is a shorthand, not the only door: `children`
  wins whenever it is non-empty, and a child is a node the caller wrote. The
  badge `Text` below is the same `Text` this function drew before, moved one
  level out.

  That is the pattern `MishkaChip`, `MishkaSegmentedControl` and
  `MishkaNavLink` are missing, and it is why the chips on 57, the segments on
  60 and the rows below are still hand-rolled.
  """
  def leading(%{badge: badge}) do
    label = ~MOB"""
    <Text
      text={badge}
      font_family="fa"
      text_size={12}
      font_weight="bold"
      text_color={Palette.on_ink()}
      max_lines={1}
    />
    """

    MishkaThemeIcon.theme_icon(
      %{variant: :filled, color: Palette.ink_fill(), size: 30, radius: 9},
      [label]
    )
  end

  def leading(row) do
    MishkaThemeIcon.theme_icon(
      %{variant: :filled, color: Palette.paper(), size: 30, radius: 9},
      [Kati.UI.symbol(row.icon, size: 17, color: Palette.ink_soft())]
    )
  end

  @doc false
  def sub(nil), do: ~MOB"<Spacer size={0} />"

  def sub(text) do
    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={3} />
      <Text text={text} font_family="fa" text_size={11.5} text_color={Palette.sub()} max_lines={1} />
    </Column>
    """
  end

  # `chevron_left` and not `chevron_right`: forward is leftwards in Persian,
  # and a Material Symbol is a glyph in a font — nothing mirrors it for us.
  @doc false
  def trailing(:chevron), do: Kati.UI.symbol("chevron_left", size: 18, color: Palette.rail_idle())

  def trailing({:text, label}) do
    ~MOB"""
    <Text text={label} font_family="fa" text_size={12} text_color={Palette.muted()} max_lines={1} />
    """
  end

  def trailing({:toggle, on?}), do: toggle(on?)

  # A segmented control that reached here unsettled still draws: the first
  # option is raised, which is what `settle/1` would have written anyway.
  #
  # ## Still not `Kati.Components.MishkaSegmentedControl` — one blocker fewer,
  # two left
  #
  # This is the one segmented control in the Persian set whose segments *are*
  # content-sized the way the component wants them, and the **sizing blocker is
  # gone**: `segment_height: 26` with `padding: 0` and `padding_left` /
  # `padding_right: 10` and `text_size: 10.5` and `font_weight: :semibold` all
  # exist now, and padding is resolved per edge against the uniform rather than
  # added to it (`MobBridge.kt:3978`, `fun pad`), so `padding: 0` really does
  # pin the 26.
  #
  # Two remain:
  #
  #   * **The labels are Persian.** روشن / تیره / خودکار, and the component
  #     builds each segment's `Text` from the `label` prop with no
  #     `font_family` — deliberately, its moduledoc says, "because the control
  #     paints it". `kati_sans_400.ttf` has zero code points in U+0600-U+06FF,
  #     so all three draw as blank boxes.
  #   * **The segments abut.** The track is `<Row>{segments}</Row>` with
  #     nothing between them; this drawing puts 3, screens 57 and 60 put 4.
  #     `track_padding` is the trough's own inset, not a gap.
  #
  # `MishkaToggle` would draw one of these segments — it takes children that
  # replace `label`, plus `height`, `corner_radius`, per-edge padding and
  # `border_width: 0` — but a segmented control is not three toggles that
  # happen to sit together: the invariant this trough has to keep is that
  # exactly one segment is lit and tapping the lit one is a no-op, which is
  # `MishkaSegmentedControl.select/2`'s whole reason to exist. Three
  # independent pressed-buttons can be all-off or all-on, and nothing in the
  # markup would say they cannot.
  def trailing({:segmented, [first | _] = options}), do: trailing({:segmented, options, first})

  def trailing({:segmented, options, selected}) do
    tiles =
      options
      |> Enum.with_index()
      |> Enum.map(fn {label, i} ->
        Kati.Screens.SettingsFa.segment_slot(label, i, label == selected)
      end)

    ~MOB"""
    <Row background={Palette.paper()} corner_radius={12} padding={3} align="center">
      {tiles}
    </Row>
    """
  end

  # The 3pt gap belongs to the segments after the first, so the trough's own
  # 3pt padding is not doubled at the leading edge.
  @doc false
  def segment_slot(label, 0, on?), do: Kati.Screens.SettingsFa.segment(label, on?, 0)

  def segment_slot(label, index, on?) do
    tile = Kati.Screens.SettingsFa.segment(label, on?, index)

    ~MOB"""
    <Row align="center">
      <Spacer size={3} />
      {tile}
    </Row>
    """
  end

  # Only the tiles that are still choices tap. The raised one used to as well —
  # a no-op rather than a dead patch — and it no longer does, for the reason
  # `Kati.Screens.Settings`' moduledoc gives at length: a control that draws a
  # tag it cannot act on is indistinguishable from a control nothing answers.
  # Two clauses rather than a conditional prop, because `on_tap={nil}` reaches
  # the wire as the string "nil" on this bridge.
  #
  # The tag carries the option's position, so the labels stay data — and the
  # position is also what names the choice, since the trough's order is
  # `Kati.Screens.Settings.choices/0`'s order.
  @doc false
  def segment(label, true, _index) do
    background = Palette.card()
    color = Palette.ink()

    ~MOB"""
    <Row
      height={26}
      corner_radius={9}
      background={background}
      padding_left={10}
      padding_right={10}
      align="center"
    >
      <Text
        text={label}
        font_family="fa"
        text_size={10.5}
        font_weight="semibold"
        text_color={color}
        max_lines={1}
      />
    </Row>
    """
  end

  def segment(label, false, index) do
    tap = {self(), String.to_atom("theme_#{index}")}

    ~MOB"""
    <Row
      height={26}
      corner_radius={9}
      background={Palette.transparent()}
      padding_left={10}
      padding_right={10}
      align="center"
      on_tap={tap}
    >
      <Text
        text={label}
        font_family="fa"
        text_size={10.5}
        font_weight="semibold"
        text_color={Palette.eyebrow()}
        max_lines={1}
      />
    </Row>
    """
  end

  @doc """
  The design's own switch: a 46x28 track, a 22pt thumb, a 3pt inset.

  The inset comes from a 40pt inner row rather than from padding, because
  mixing `padding` with an explicit `width` on one node inflates it on this
  bridge instead of insetting it. The thumb takes the trailing edge when on —
  and under RTL that is the physical left, which is exactly what the drawing
  shows, with no mirroring code of its own.
  """
  def toggle(on?) do
    track = if on?, do: Palette.ink_fill(), else: Palette.track_off()

    ~MOB"""
    <Box width={46} height={28} corner_radius={14} background={track} align="center">
      <Row width={40} align="center">
        {Kati.Screens.SettingsFa.thumb_lead(on?)}
        <Box
          width={22}
          height={22}
          corner_radius={11}
          background={Palette.on_ink()}
          shadow="0 1 3 0 #4D1A1917"
        />
        {Kati.Screens.SettingsFa.thumb_trail(on?)}
      </Row>
    </Box>
    """
  end

  @doc false
  def thumb_lead(true), do: ~MOB"<Spacer weight={1.0} />"
  def thumb_lead(false), do: ~MOB"<Spacer size={0} />"

  @doc false
  def thumb_trail(true), do: ~MOB"<Spacer size={0} />"
  def thumb_trail(false), do: ~MOB"<Spacer weight={1.0} />"

  @doc """
  The 1pt rule between rows, as `Kati.Components.MishkaSeparator` — and only
  with `render: :box`.

  `separator(color: 0x121A1917, thickness: 1)` always fitted this line's API.
  What did not fit was what it drew, and the new `render` prop is exactly that
  fix. The default is still `:divider`, which renders `<Divider>`;
  `MobBridge.kt:2962` hands that to Material 3 1.2.0's `HorizontalDivider`, and
  that composable is not a filled box —

      Canvas(modifier.fillMaxWidth().height(thickness)) {
        drawLine(color, strokeWidth = thickness.toPx(), …)
      }

  `height(1.dp)` rounds to whole device pixels while `thickness.toPx()` does
  not, and the capture device runs at 2.6875x. The node is 3px tall and the
  antialiased stroke covers 2.6875 of them, so the bottom row lands at ~69%
  coverage where `Box` + `background` fills all three. It is invisible at any
  density where 1dp is a whole number of pixels, which is why a unit test would
  never catch it — `Kati.Screens.Subscriptions.hairline/1` sets the same case
  out at length. **A screen that adopts this component without `render: :box`
  regresses its hairlines**, silently, on this device only.

  With the prop, the built node is the markup's own `Box` plus one child:

      <Box fill_width={true} height={1} background={0x121A1917}>
        <Spacer size={1} />
      </Box>

  The `Spacer` is the component's iOS workaround — `MobBox` drops a Box's
  `height` unless the Box also has a `width`, so a childless full-width bar
  measures 0pt tall there. On this bridge it costs nothing: the Box's `height`
  pins the node at 1dp in `nodeModifier`, and a Spacer paints no background, so
  the three pixel rows are the same three rows in the same colour.
  """
  def hairline(false), do: ~MOB"<Spacer size={0} />"

  def hairline(true) do
    MishkaSeparator.separator(color: Palette.hairline(), thickness: 1, render: :box)
  end

  def handle_info({:tap, :back}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}

  # Positional tags, parsed back to positions. Nothing here raises on a tag it
  # does not recognise: this screen is a bare `Mob.Screen` with no rescue
  # around its taps, so a bad match would take the whole screen down with it.
  def handle_info({:tap, tag}, socket) do
    {:noreply, tapped(Atom.to_string(tag), socket)}
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  defp tapped("toggle_" <> position, socket) do
    case String.split(position, "_") do
      [si, ri] ->
        settings = flip(socket.assigns.settings, String.to_integer(si), String.to_integer(ri))
        Mob.Socket.assign(socket, :settings, settings)

      _ ->
        socket
    end
  end

  # The Persian trough tags by position, which is already the mode's position,
  # so this needs no table of Persian words. Store first, then move the tile,
  # and only for a position the trough actually has — `Integer.parse/1` rather
  # than `String.to_integer/1` so a malformed tag returns the screen instead of
  # raising it into `handle_info/2`.
  defp tapped("theme_" <> index, socket) do
    with {i, ""} <- Integer.parse(index),
         choice when not is_nil(choice) <- Kati.Screens.Settings.choice_at(i) do
      Kati.Screens.Settings.put_choice(choice)
      Mob.Socket.assign(socket, :settings, choose(socket.assigns.settings, i))
    else
      _ -> socket
    end
  end

  # The glyph is the key, so the tag stays ASCII and readable in a log. A tag
  # naming a glyph no row here carries returns the screen rather than raising
  # it into `handle_info/2`, for the reason the comment above `tapped/2` gives.
  # Before the glyph clause, which matches "go_" <> anything: `language` is not
  # a key in `@destinations` — it is a badge row, not a glyph row — so falling
  # through to that clause returns the screen unchanged and the only way out of
  # Persian stays shut.
  defp tapped("go_language", socket),
    do: Mob.Socket.push_screen(socket, Kati.Screens.Language)

  defp tapped("go_" <> icon, socket) do
    case Map.fetch(@destinations, icon) do
      {:ok, module} -> Mob.Socket.push_screen(socket, module)
      :error -> socket
    end
  end

  defp tapped(_tag, socket), do: socket

  defp flip(settings, si, ri) do
    sections =
      List.update_at(settings.sections, si, fn section ->
        %{section | rows: List.update_at(section.rows, ri, &flip_row/1)}
      end)

    %{settings | sections: sections}
  end

  defp flip_row(%{trailing: {:toggle, on?}} = row), do: %{row | trailing: {:toggle, not on?}}
  defp flip_row(row), do: row

  defp choose(settings, index) do
    sections =
      Enum.map(settings.sections, fn section ->
        %{section | rows: Enum.map(section.rows, &choose_row(&1, index))}
      end)

    %{settings | sections: sections}
  end

  defp choose_row(%{trailing: {:segmented, options, _}} = row, index) do
    case Enum.at(options, index) do
      nil -> row
      label -> %{row | trailing: {:segmented, options, label}}
    end
  end

  defp choose_row(row, _index), do: row
end
