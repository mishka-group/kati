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

  ## The switch is drawn rather than delegated

  `Kati.Components.MishkaSwitch` wraps Compose's own `Switch`, which brings
  platform metrics and platform animation with it. The design specifies a
  46x28 track with a 22pt thumb on a 3pt inset, in two exact colours — screen
  41 reached the same conclusion. Fidelity wins over reuse for the one control
  the drawing measures.

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
  legible in a log written left-to-right.
  """
  use Mob.Screen
  import Mob.Sigil

  alias Kati.Components.MishkaAvatar
  alias Kati.Design.Images
  alias Kati.Fa.SampleSettings
  alias Kati.Theme

  def mount(_params, _session, socket) do
    Mob.Theme.set(Kati.Theme.light())
    {:ok, Mob.Socket.assign(socket, :settings, settle(SampleSettings.settings()))}
  end

  # The sample names a segmented control's options but not which one is picked,
  # because until now nothing could pick. The selection is written in once, on
  # mount, as the first option — which is what the drawing raises — so from
  # then on a tap is an ordinary change to a shape that already exists.
  defp settle(settings) do
    sections =
      Enum.map(settings.sections, fn section ->
        %{section | rows: Enum.map(section.rows, &settle_row/1)}
      end)

    %{settings | sections: sections}
  end

  defp settle_row(%{trailing: {:segmented, [first | _] = options}} = row),
    do: %{row | trailing: {:segmented, options, first}}

  defp settle_row(row), do: row

  def render(assigns) do
    settings = assigns.settings

    ~MOB"""
    <Box fill_width={true} fill_height={true} background={:background} layout_direction="rtl">
      <Scroll>
        <Column fill_width={true} padding_left={21} padding_right={21} padding_top={64} padding_bottom={40}>
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
          background={Theme.card(:light)}
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
        <Box
          width={44}
          height={44}
          corner_radius={22}
          background={Theme.card(:light)}
          shadow={Theme.shadow_button()}
          align="center"
        >
          {Kati.UI.symbol("help", size: 21)}
        </Box>
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
      <Text text={settings.subtitle} font_family="fa" text_size={11.5} text_color={0xFFA9A29A} max_lines={1} />
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
        background={Theme.card(:light)}
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
          <Text text={meta} font_family="fa" text_size={11} text_color={0xFFA9A29A} max_lines={1} />
        </Column>
        <Spacer size={14} />
        <Row height={26} corner_radius={13} background={0x294E9A73} padding_left={10} padding_right={10} align="center">
          {Kati.UI.symbol("cloud_done", size: 14, color: 0xFF3E8460)}
          <Spacer size={5} />
          <Text
            text={me.sync}
            font_family="fa"
            text_size={11}
            font_weight="semibold"
            text_color={0xFF3E8460}
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
    MishkaAvatar.avatar(src: Images.poster(seed), size: 52, background: 0xFFE4E0D9)
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
        background={Theme.card(:light)}
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
    color = if dash == :muted, do: 0xFFC4BDB3, else: Theme.accent()

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_left={2} padding_right={2}>
        <Box width={13} height={2} corner_radius={1} background={color} />
        <Spacer size={9} />
        <Text text={label} font_family="fa" text_size={11} font_weight="semibold" text_color={0xFFA0998F} />
      </Row>
      <Spacer size={11} />
    </Column>
    """
  end

  @doc """
  One row, tappable along its whole width when it carries a toggle.

  Screen 24 does the same, and for the same reason: a 46pt track is a small
  target and the row already reads as one object. A chevron row stays inert —
  its destination is not built yet, and a row that lights up and goes nowhere
  is a worse promise than a row that does nothing.
  """
  def row(row, rule?, si, ri) do
    tap = Kati.Screens.SettingsFa.tap_for(row, si, ri)

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
          {Kati.Screens.SettingsFa.sub(row.sub)}
        </Column>
        <Spacer size={13} />
        {Kati.Screens.SettingsFa.trailing(row.trailing)}
      </Row>
      {Kati.Screens.SettingsFa.hairline(rule?)}
    </Column>
    """
  end

  @doc "A toggle row's tap tag, by position; everything else is inert."
  def tap_for(%{trailing: {:toggle, _}}, si, ri),
    do: {self(), String.to_atom("toggle_#{si}_#{ri}")}

  def tap_for(_row, _si, _ri), do: nil

  # The language row's tile carries two letters instead of a glyph — the design
  # names the language in the language, which no icon can do.
  #
  # Not `Kati.Components.MishkaActionIcon` for the glyph tile below either,
  # even though a small icon disc is what it draws: its radius comes from a
  # three-value `shape` (`:rounded` -> the `:radius_md` token, `:circle` ->
  # `size / 2`) with no way to name one, and this tile's is 9. The badge tile
  # is further out of reach — its text is Persian.
  @doc false
  def leading(%{badge: badge}) do
    ~MOB"""
    <Box width={30} height={30} corner_radius={9} background={Kati.Theme.ink()} align="center">
      <Text text={badge} font_family="fa" text_size={12} font_weight="bold" text_color={0xFFFBFAF8} max_lines={1} />
    </Box>
    """
  end

  def leading(row) do
    ~MOB"""
    <Box width={30} height={30} corner_radius={9} background={0xFFEFECE7} align="center">
      {Kati.UI.symbol(row.icon, size: 17, color: 0xFF5C574F)}
    </Box>
    """
  end

  @doc false
  def sub(nil), do: ~MOB"<Spacer size={0} />"

  def sub(text) do
    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={3} />
      <Text text={text} font_family="fa" text_size={11.5} text_color={0xFF8A8479} max_lines={1} />
    </Column>
    """
  end

  # `chevron_left` and not `chevron_right`: forward is leftwards in Persian,
  # and a Material Symbol is a glyph in a font — nothing mirrors it for us.
  @doc false
  def trailing(:chevron), do: Kati.UI.symbol("chevron_left", size: 18, color: 0xFFC4BDB3)

  def trailing({:text, label}) do
    ~MOB"""
    <Text text={label} font_family="fa" text_size={12} text_color={0xFFA9A29A} max_lines={1} />
    """
  end

  def trailing({:toggle, on?}), do: toggle(on?)

  # A segmented control that reached here unsettled still draws: the first
  # option is raised, which is what `settle/1` would have written anyway.
  #
  # Not `Kati.Components.MishkaSegmentedControl`, though this is the one
  # segmented control in the Persian set whose segments *are* content-sized
  # the way the component wants them. Three things still stop it: the labels
  # are Persian and the component's segment `Text` takes no `font_family`, so
  # روشن would draw blank; the segments abut where the drawing puts 3 between
  # them, and there is no gap prop; and a segment's box is sized by one
  # uniform `padding` where this one is 26 tall with 10 of horizontal padding
  # and a 10.5pt semibold label.
  def trailing({:segmented, [first | _] = options}), do: trailing({:segmented, options, first})

  def trailing({:segmented, options, selected}) do
    tiles =
      options
      |> Enum.with_index()
      |> Enum.map(fn {label, i} ->
        Kati.Screens.SettingsFa.segment_slot(label, i, label == selected)
      end)

    ~MOB"""
    <Row background={0xFFEFECE7} corner_radius={12} padding={3} align="center">
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

  # Every tile taps, the raised one included — a tap on the current choice is
  # then a no-op rather than a dead patch in the middle of the trough. The tag
  # carries the option's position, so the labels stay data.
  @doc false
  def segment(label, on?, index) do
    background = if on?, do: Theme.card(:light), else: 0x00FFFFFF
    color = if on?, do: Theme.ink(), else: 0xFFA0998F
    tap = {self(), String.to_atom("theme_#{index}")}

    ~MOB"""
    <Row
      height={26}
      corner_radius={9}
      background={background}
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
        text_color={color}
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
    track = if on?, do: Theme.ink(), else: 0xFFDCD7CF

    ~MOB"""
    <Box width={46} height={28} corner_radius={14} background={track} align="center">
      <Row width={40} align="center">
        {Kati.Screens.SettingsFa.thumb_lead(on?)}
        <Box width={22} height={22} corner_radius={11} background={0xFFFBFAF8} shadow="0 1 3 0 #4D1A1917" />
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

  # ## Not `Kati.Components.MishkaSeparator`, and the reason is one row of
  # pixels
  #
  # `separator(color: 0x121A1917, thickness: 1)` is this line, and the API fits
  # exactly. What does not fit is what it draws: the port renders `<Divider>`,
  # `MobBridge.kt:2962` hands that to Material 3's `HorizontalDivider`, and in
  # 1.2.0 that composable is not a filled box —
  #
  #     Canvas(modifier.fillMaxWidth().height(thickness)) {
  #       drawLine(color, strokeWidth = thickness.toPx(), …)
  #     }
  #
  # `height(1.dp)` rounds to whole device pixels while `thickness.toPx()` does
  # not, and the capture device runs at 2.6875x. The node is 3px tall and the
  # antialiased stroke covers 2.6875 of them, so the bottom row lands at 69%
  # coverage where `Box` + `background` fills all three. It is invisible at any
  # density where 1dp is a whole number of pixels, which is why a unit test
  # would never catch it — `Kati.Screens.Subscriptions.hairline/1` sets the
  # same case out at length.
  @doc false
  def hairline(false), do: ~MOB"<Spacer size={0} />"
  def hairline(true), do: ~MOB"<Box fill_width={true} height={1} background={0x121A1917} />"

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

  defp tapped("theme_" <> index, socket) do
    settings = choose(socket.assigns.settings, String.to_integer(index))
    Mob.Socket.assign(socket, :settings, settings)
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
