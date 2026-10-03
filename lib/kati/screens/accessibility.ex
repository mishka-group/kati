defmodule Kati.Screens.Accessibility do
  @moduledoc """
  Screen 41 — Accessibility, pushed under Settings (*Text size*).

  Every control on it changes the whole app, and is stored in
  `Kati.Accessibility` (#119):

    * **Text size** — *Phone*, *Large*, *Larger*: 100%, 115% or 130% of the
      phone's own text size. The root of every screen carries the multiplier
      and `K-72` applies it to Compose's density, so the change is immediate
      and survives a restart. Titles still cap their own scale, so a large
      size makes text wrap and cards grow, never cut.
    * **Reduce motion** — a page change fades in instead of sliding (#118).
      The same switch as screen 24's, over the same stored value.
    * **Increase contrast** — the quiet greys and hairlines take the next step
      darker, everywhere `Kati.Theme.Palette` is asked for them.

  Under them, three things Kati keeps on every screen whatever is chosen:
  controls named for TalkBack, nothing under 44×44, and colour never alone.
  They are statements rather than options, drawn as ticks under *Always on*,
  with one row that opens Android's own accessibility settings for the rest
  (TalkBack, the system font size, colour correction).

  ## The preview

  The Up next card is the reader's own (screen 10's hero), at the size the
  chosen text size gives it, and the sentence under it is the one TalkBack
  speaks on that card. With nothing on the go neither is drawn.
  """
  use Kati.Screens.Pushed, back: "Settings"
  use Gettext, backend: Kati.Gettext

  alias Kati.Components.MishkaSeparator
  alias Kati.Components.MishkaThemeIcon
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  @impl true
  def load(socket) do
    socket
    |> Mob.Socket.assign(:hero, Kati.Screens.Accessibility.hero())
    |> Mob.Socket.assign(:display, Kati.Screens.Accessibility.display())
    |> Mob.Socket.assign(:error, nil)
  end

  @doc "The three stored choices, as the screen draws them."
  @spec display() :: %{scale: Kati.Accessibility.scale(), motion: boolean(), contrast: boolean()}
  def display do
    %{
      scale: Kati.Accessibility.text_scale(),
      motion: Kati.Accessibility.reduce_motion?(),
      contrast: Kati.Accessibility.contrast?()
    }
  end

  @doc """
  The reader's own Up next card, or `nil` when nothing is on the go.
  """
  @spec hero() :: map() | nil
  def hero do
    case Kati.Screens.UpNext.queue() do
      %{hero: %{title: title, meta: meta}} -> %{title: title, meta: meta}
      _nothing -> nil
    end
  rescue
    _error -> nil
  end

  @doc """
  A text size's name, as the control and screen 24's *Text size* row say it.

      iex> Kati.Screens.Accessibility.scale_label(:system)
      "Follows system"
      iex> Kati.Screens.Accessibility.scale_label(:larger)
      "Larger · 130%"
  """
  @spec scale_label(Kati.Accessibility.scale()) :: String.t()
  def scale_label(:system), do: gettext("Follows system")

  def scale_label(:large),
    do: gettext("Large · %{percent}", percent: Kati.Screens.Accessibility.percent(:large))

  def scale_label(:larger),
    do: gettext("Larger · %{percent}", percent: Kati.Screens.Accessibility.percent(:larger))

  @doc false
  def percent(scale) do
    gettext("%{n}%", n: Kati.Locale.number(round(Kati.Accessibility.factor(scale) * 100)))
  end

  @doc """
  The line under the title: what is on, or that everything follows the phone.

      iex> Kati.Screens.Accessibility.summary(%{scale: :system, motion: false, contrast: false})
      "Follows your phone"
      iex> Kati.Screens.Accessibility.summary(%{scale: :large, motion: true, contrast: true})
      "Text 115% · less motion · more contrast"
  """
  @spec summary(map()) :: String.t()
  def summary(%{scale: :system, motion: false, contrast: false}),
    do: gettext("Follows your phone")

  def summary(%{scale: scale, motion: motion?, contrast: contrast?}) do
    [
      scale != :system &&
        gettext("Text %{percent}", percent: Kati.Screens.Accessibility.percent(scale)),
      motion? && gettext("less motion"),
      contrast? && gettext("more contrast")
    ]
    |> Enum.filter(& &1)
    |> Enum.join(" · ")
  end

  @doc """
  The sentence a screen reader speaks on the Up next card: its title and its
  line, as the card itself says them.

      iex> Kati.Screens.Accessibility.voiceover_line(%{title: "Dark", meta: "S1 · E3"})
      "“Dark. S1 · E3. Double-tap to open.”"
  """
  @spec voiceover_line(map()) :: String.t()
  def voiceover_line(%{title: title, meta: meta}) do
    Kati.Locale.quoted(
      gettext("%{title}. %{line}. Double-tap to open.", title: title, line: meta || "")
    )
  end

  @doc "The three guarantees every screen keeps, whatever is chosen above."
  @spec always_on() :: [map()]
  def always_on do
    [
      %{
        icon: "record_voice_over",
        title: gettext("Named for TalkBack"),
        sub: gettext("Every control says what it is · posters described")
      },
      %{
        icon: "touch_app",
        title: gettext("Touch targets"),
        sub:
          gettext("Nothing under %{w}×%{h}", w: Kati.Locale.number(44), h: Kati.Locale.number(44))
      },
      %{
        icon: "colorize",
        title: gettext("Colour is never alone"),
        sub: gettext("Every dot has a label or icon")
      }
    ]
  end

  @doc false
  def content(assigns) do
    d = assigns.display
    hero = Map.get(assigns, :hero)

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {Kati.Screens.Accessibility.header(d.contrast)}
        {Kati.Screens.Accessibility.title(Kati.Screens.Accessibility.summary(d))}
        {Kati.Screens.Accessibility.up_next(hero, d.contrast)}
        {UI.eyebrow(gettext("Text size"))}
        {Kati.Screens.Accessibility.sizes(d.scale)}
        {UI.eyebrow(gettext("Display"))}
        {Kati.Screens.Accessibility.switches(d)}
        {Kati.Screens.Accessibility.error_line(Map.get(assigns, :error))}
        {UI.eyebrow(gettext("Always on"))}
        {Kati.Screens.Accessibility.built_in(d.contrast)}
        {Kati.Screens.Accessibility.voiceover(hero)}
      </Column>
    </Scroll>
    """
  end

  # 44pt reserves the row the back pill floats in, as every pushed screen does.
  @doc false
  def header(_contrast?) do
    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={44} />
      <Spacer size={16} />
    </Column>
    """
  end

  @doc """
  The 44pt floating disc a pushed screen sets opposite its back pill, lifted
  unless contrast is on. Kept for the screens whose own docs point here.
  """
  def disc(icon, contrast?) do
    MishkaThemeIcon.theme_icon(
      %{
        variant: :filled,
        color: Palette.card(),
        size: 44,
        radius: 22,
        shadow: Kati.Screens.Accessibility.lift(Kati.Theme.shadow_button(), contrast?)
      },
      [Kati.UI.symbol(icon, size: 21)]
    )
  end

  @doc """
  The shadow a card keeps, or none once contrast is on: a card then stands on
  its outline (`card_hairline`'s stronger step), not on a soft blur.
  """
  @spec lift(String.t(), boolean()) :: String.t() | nil
  def lift(shadow, false), do: shadow
  def lift(_shadow, true), do: nil

  @doc false
  def title(subtitle) do
    ~MOB"""
    <Column fill_width={true}>
      <Text
        text={gettext("Accessibility")}
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
      />
      <Spacer size={20} />
    </Column>
    """
  end

  @doc """
  The muted eyebrow: the design's `#C4BDB3` dash instead of the accent one,
  for a quotation rather than a section you act on.
  """
  def quiet_eyebrow(label) do
    drawn = Kati.UI.eyebrow_label(label)

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_left={2} padding_right={2}>
        <Box width={13} height={2} corner_radius={1} background={Palette.rail_idle()} />
        <Spacer size={9} />
        <Text
          text={drawn}
          font_family={Kati.Locale.mono_face(drawn)}
          text_size={Kati.Locale.pick(10.5, 11)}
          font_weight={Kati.Locale.pick("normal", "semibold")}
          letter_spacing={Kati.Locale.tracking(0.16)}
          text_color={Palette.eyebrow()}
          max_lines={1}
        />
      </Row>
      <Spacer size={11} />
    </Column>
    """
  end

  @doc false
  def up_next(nil, _contrast?), do: []

  def up_next(hero, contrast?) do
    shadow = Kati.Screens.Accessibility.lift(Kati.Theme.shadow_card_soft(), contrast?)
    label = Kati.UI.eyebrow_label(gettext("Up next"))
    assigns = %{hero: hero, shadow: shadow, label: label}

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        shadow={@shadow}
        padding={18}
      >
        <Text
          text={@label}
          font_family={Kati.Locale.mono_face(@label)}
          text_size={12}
          letter_spacing={Kati.Locale.tracking(0.16)}
          text_color={Palette.eyebrow()}
        />
        <Spacer size={12} />
        <Text
          text={@hero.title}
          text_size={30}
          font_weight="bold"
          letter_spacing={Kati.Locale.tracking(-0.02)}
          line_height={1.2}
          text_color={:on_surface}
        />
        <Spacer size={10} />
        <Text
          text={@hero.meta}
          text_size={22}
          line_height={Kati.Locale.leading(1.35)}
          text_color={Palette.ink_soft()}
        />
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  The three text sizes, side by side, each drawn at the size it gives.

  A tile per size rather than a slider: three stops are the whole choice, and
  each tile is 64 tall, well over the 44 this screen promises.
  """
  def sizes(selected) do
    tiles =
      Kati.Accessibility.scales()
      |> Enum.map(&Kati.Screens.Accessibility.size_tile(&1, &1 == selected))
      |> Enum.intersperse(~MOB"<Spacer size={8} />")

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true}>
        {tiles}
      </Row>
      <Spacer size={10} />
      <Text
        text={gettext("On top of your phone's own text size. Long titles wrap instead of being cut.")}
        text_size={11.5}
        line_height={Kati.Locale.leading(1.5)}
        text_color={Palette.sub()}
      />
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def size_tile(scale, selected?) do
    label =
      case scale do
        :system -> gettext("Phone")
        :large -> gettext("Large")
        :larger -> gettext("Larger")
      end

    sample = round(15 * Kati.Accessibility.factor(scale))
    tap = {self(), String.to_atom("text_size_" <> Atom.to_string(scale))}
    ground = if selected?, do: Palette.ink_fill(), else: Palette.card()
    ink = if selected?, do: Palette.on_ink(), else: Palette.ink()
    quiet = if selected?, do: Palette.on_ink_muted(), else: Palette.sub()

    spoken =
      if selected?,
        do: gettext("%{size} text, chosen", size: label),
        else: gettext("%{size} text", size: label)

    assigns = %{
      label: label,
      sample: sample,
      tap: tap,
      ground: ground,
      ink: ink,
      quiet: quiet,
      spoken: spoken
    }

    ~MOB"""
    <Box
      weight={1.0}
      height={64}
      corner_radius={18}
      background={@ground}
      on_tap={@tap}
      accessibility_label={@spoken}
    >
      <Column fill_width={true} fill_height={true} align="center" padding_top={10}>
        <Text
          text="Aa"
          text_size={@sample}
          max_font_scale={1.0}
          font_weight="bold"
          text_color={@ink}
          max_lines={1}
        />
        <Spacer size={2} />
        <Text text={@label} text_size={11} max_font_scale={1.0} text_color={@quiet} max_lines={1} />
      </Column>
    </Box>
    """
  end

  @doc false
  def switches(d) do
    rows = [
      SettingsList.row(
        SettingsList.icon_tile("motion_blur"),
        SettingsList.body(gettext("Reduce motion"), gettext("Pages fade in instead of sliding")),
        SettingsList.switch(d.motion, gettext("Reduce motion")),
        padding: 13,
        on_tap: {self(), :toggle_motion}
      ),
      SettingsList.row(
        SettingsList.icon_tile("contrast"),
        SettingsList.body(gettext("Increase contrast"), gettext("Darker grey text and lines")),
        SettingsList.switch(d.contrast, gettext("Increase contrast")),
        padding: 13,
        rule: false,
        on_tap: {self(), :toggle_contrast}
      )
    ]

    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.card(rows)}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def error_line(nil), do: []

  def error_line(message) do
    assigns = %{message: message}

    ~MOB"""
    <Column fill_width={true}>
      <Text text={@message} text_size={12.5} text_color={Palette.red()} />
      <Spacer size={16} />
    </Column>
    """
  end

  @doc false
  def built_in(contrast?) do
    shadow = Kati.Screens.Accessibility.lift(Kati.Theme.shadow_card_soft(), contrast?)

    rows =
      Enum.map(
        Kati.Screens.Accessibility.always_on(),
        &Kati.Screens.Accessibility.row(&1, contrast?)
      )

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={20}
        shadow={shadow}
        padding_left={15}
        padding_right={15}
        padding_top={4}
        padding_bottom={4}
      >
        {rows}
        {Kati.Screens.Accessibility.system_row()}
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def row(row, contrast?) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_top={13} padding_bottom={13}>
        {Kati.Screens.Accessibility.icon_tile(row.icon)}
        <Spacer size={13} />
        <Column weight={1.0}>
          <Text text={row.title} text_size={13.5} font_weight="semibold" text_color={:on_surface} />
          <Spacer size={3} />
          <Text text={row.sub} text_size={11.5} text_color={Palette.sub()} />
        </Column>
        <Spacer size={13} />
        {Kati.UI.symbol("check", size: 18, color: Palette.green_text())}
      </Row>
      {Kati.Screens.Accessibility.hairline(true, contrast?)}
    </Column>
    """
  end

  @doc """
  The row that opens Android's own accessibility settings: TalkBack, the
  system font size, colour correction — the parts a phone owns.
  """
  def system_row do
    ~MOB"""
    <Row
      fill_width={true}
      align="center"
      padding_top={13}
      padding_bottom={13}
      on_tap={{self(), :open_system}}
    >
      {Kati.Screens.Accessibility.icon_tile("settings")}
      <Spacer size={13} />
      <Column weight={1.0}>
        <Text
          text={gettext("Android accessibility settings")}
          text_size={13.5}
          font_weight="semibold"
          text_color={:on_surface}
        />
        <Spacer size={3} />
        <Text
          text={gettext("TalkBack, font size, colour correction")}
          text_size={11.5}
          text_color={Palette.sub()}
        />
      </Column>
      <Spacer size={13} />
      {SettingsList.chevron()}
    </Row>
    """
  end

  @doc "The 30x30 paper tile a row leads with."
  def icon_tile(name) do
    MishkaThemeIcon.theme_icon(
      %{variant: :filled, color: Palette.paper(), size: 30, radius: 9},
      [Kati.UI.symbol(name, size: 17, color: Palette.ink_soft())]
    )
  end

  @doc """
  The sentence TalkBack speaks, printed on ink — the screen's one inverted
  surface, which inverts back in dark.
  """
  def voiceover(nil), do: []

  def voiceover(hero) do
    label = Kati.UI.eyebrow_label(pgettext("the VoiceOver quotation’s label", "Up next card"))
    reads = Kati.Screens.Accessibility.voiceover_line(hero)
    assigns = %{label: label, reads: reads}

    [
      Kati.Screens.Accessibility.quiet_eyebrow(gettext("TalkBack reads")),
      ~MOB"""
      <Column fill_width={true} background={Palette.ink_fill()} corner_radius={20} padding={17}>
        <Text
          text={@label}
          font_family={Kati.Locale.mono_face(@label)}
          text_size={10}
          letter_spacing={Kati.Locale.tracking(0.14)}
          text_color={Palette.on_ink_meta()}
          max_lines={1}
        />
        <Spacer size={10} />
        <Text
          text={@reads}
          text_size={13.5}
          line_height={Kati.Locale.leading(1.6)}
          text_color={Palette.on_ink_glyph()}
        />
      </Column>
      """
    ]
  end

  @doc """
  The rule between two rows, a step darker once contrast is on.
  """
  def hairline(false, _contrast?), do: ~MOB"<Spacer size={0} />"

  def hairline(true, contrast?) do
    color = if contrast?, do: Palette.track_ink(), else: Palette.hairline()
    MishkaSeparator.separator(color: color, thickness: 1, render: :box)
  end

  @impl true
  def handle_tap(:toggle_motion, socket) do
    :ok = Kati.Accessibility.put_reduce_motion(not socket.assigns.display.motion)
    {:noreply, Kati.Screens.Accessibility.refresh(socket)}
  end

  def handle_tap(:toggle_contrast, socket) do
    :ok = Kati.Accessibility.put_contrast(not socket.assigns.display.contrast)
    :ok = Kati.Theme.activate()
    Kati.Locale.activate()
    {:noreply, Kati.Screens.Accessibility.refresh(socket)}
  end

  def handle_tap(:open_system, socket) do
    case Kati.Native.Links.settings(:accessibility) do
      :ok ->
        {:noreply, Mob.Socket.assign(socket, :error, nil)}

      {:error, reason} ->
        {:noreply, Mob.Socket.assign(socket, :error, Kati.Native.Links.message(reason))}
    end
  end

  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "text_size_" <> name ->
        case Enum.find(Kati.Accessibility.scales(), &(Atom.to_string(&1) == name)) do
          nil ->
            {:noreply, socket}

          scale ->
            :ok = Kati.Accessibility.put_text_scale(scale)
            {:noreply, Kati.Screens.Accessibility.refresh(socket)}
        end

      _other ->
        {:noreply, socket}
    end
  end

  @doc false
  def refresh(socket) do
    socket
    |> Mob.Socket.assign(:display, Kati.Screens.Accessibility.display())
    |> Mob.Socket.assign(:error, nil)
  end
end
