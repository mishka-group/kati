defmodule Kati.Screens.Language do
  @moduledoc """
  Screen 54 — Language, pushed under Settings.

  Built to `.scratch/design/screens/54.html`. The design's caption states the
  idea: *"language is one switch that carries five settings with it, each still
  overridable. The row that matters most is the last one: nothing you typed
  yourself ever gets rewritten."*

  Three parts, in that order of consequence: the picker, the five settings the
  choice drags along, and then Content — which is a footnote to the language
  rather than a peer of it, so its eyebrow takes the grey dash from
  `Kati.UI.SettingsList.eyebrow_muted/1` and not the accent one.

  ## Persian rows are drawn in Vazirmatn

  `فا`, `فارسی` and `ایران` are the picker's own copy, and two rows below mix
  Persian into an English sentence. Plus Jakarta Sans carries neither Arabic
  glyphs nor Arabic-Indic digits, so those five strings take
  `font_family="fa"` — Vazirmatn, which Kati ships at 400–800 and which covers
  Latin as well, so the English half of a mixed line still reads. The rows
  carry `script: :fa` in `Kati.Language.Sample` rather than the screen
  guessing from the characters.

  ## The picker is the real switch, not a highlight

  `Kati.Locale` owns the active locale, so this screen sets it rather than
  duplicating it. `Kati.Locale.put/1` writes `Mob.State`, which is a named
  GenServer over a DETS table — process-independent, app-wide and synced to
  disk before the call returns — so writing it from a screen is safe and
  survives the screen dying on the next root switch. The picker therefore
  reads its selection from `Kati.Locale.current/0` and not from
  `Kati.Language.Sample`'s `on:` flag, which is now the stand-in it always
  said it was: at `:en`, the default, the two agree exactly and the resting
  frame is 54.html unchanged.

  Choosing a language then **opens the interface in it**, because setting the
  locale alone would not: `Kati.Shell.roots/0` is a static list of the English
  roots, and the eight Persian mirrors hang off `Kati.Screens.Fa.roots/0`
  instead. So `:fa` pushes `Kati.Screens.HomeFa` — screen 55, whose own dock
  then reaches 56, 57 and 61 — and `:en` pushes `Kati.Screens.Home`.

  Pushed, not `reset_to/2`, and that is a judgement rather than the obvious
  reading. A language change really does relaunch an interface at its root,
  which argues for a reset; but there is no Persian language picker (no
  `LanguageFa`, and nothing pushes `Kati.Screens.SettingsFa` from anywhere),
  so a reset would clear the only stack that still contains this screen and
  strand the user in Persian with no drawn way back. Pushing keeps 54
  underneath, where the hardware back button reaches it. **The strand still
  arrives one tap later** — the Persian dock switches roots with `reset_to/2`,
  which empties the history — and closing that needs a route into this screen
  from the Persian side, which is not this file's to add.

  No dock — this is a pushed screen — so the frame closes at 40, not 132. The
  header is the back pill alone, with nothing opposite it, so the chrome row
  reserves the pill's height and draws no disc.
  """
  use Kati.Screens.Pushed, back: "Settings"

  alias Kati.Language.Sample
  alias Kati.UI
  alias Kati.UI.SettingsList

  @impl true
  def load(socket) do
    Mob.Socket.assign(socket, heading: Sample.heading(), locale: Kati.Locale.current())
  end

  @doc false
  def content(assigns) do
    h = assigns.heading
    locale = assigns.locale

    ~MOB"""
    <Scroll>
      <Column fill_width={true} padding_left={21} padding_right={21} padding_top={64} padding_bottom={40}>
        {SettingsList.chrome(nil, 44)}
        {SettingsList.title(h.title, h.subtitle)}
        {UI.eyebrow(h.interface_label)}
        {Kati.Screens.Language.picker(locale)}
        {UI.eyebrow(h.follows_label)}
        {Kati.Screens.Language.group(Kati.Language.Sample.follows(), 24)}
        {SettingsList.eyebrow_muted(h.content_label)}
        {Kati.Screens.Language.group(Kati.Language.Sample.content(), 24)}
        {Kati.Screens.Language.note()}
      </Column>
    </Scroll>
    """
  end

  @doc false
  def picker(locale) do
    ~MOB"""
    <Column fill_width={true}>
      {Enum.map(Kati.Language.Sample.languages(), fn l ->
         Kati.Screens.Language.language(l, Kati.Screens.Language.locale_of(l) == locale)
       end)}
      {Kati.Screens.Language.add_language()}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  Which locale a picker row stands for.

  `Kati.Language.Sample` already carries `script:` — it has to, so a row can
  choose its typeface — and the two rows it draws are exactly the two locales
  `Kati.Locale.supported/0` returns, so nothing further is needed to tell them
  apart. A third installed language would need its own key on that data and a
  third locale to point it at; neither exists, and the dashed "Add a language"
  row below the picker is where that would start.
  """
  @spec locale_of(map()) :: :en | :fa
  def locale_of(%{script: :fa}), do: :fa
  def locale_of(_row), do: :en

  @doc false
  def choose_tag(row) do
    String.to_atom("choose_language_" <> Atom.to_string(Kati.Screens.Language.locale_of(row)))
  end

  # The selected card carries the drawing's inset 2pt ink ring. Two clauses
  # rather than a conditional border, because `border_width` and `border_color`
  # are opt-in as a pair in this bridge and a nil colour draws a black hairline
  # rather than nothing.
  #
  # The selected row carries no `on_tap`, which is the drawing's own decision
  # and is kept: choosing the language you are already in is not a choice. It
  # also means `:choose_language_en` can only ever be sent from a `:fa` app and
  # vice versa.
  @doc false
  def language(l, true) do
    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Kati.Theme.card(:light)}
        corner_radius={20}
        shadow={Kati.Theme.shadow_card_soft()}
        border_width={2}
        border_color={0xFF1A1917}
        padding={14}
        align="center"
      >
        {Kati.Screens.Language.code_tile(l)}
        <Spacer size={13} />
        {Kati.Screens.Language.language_body(l)}
        <Spacer size={13} />
        {Kati.Screens.Language.selected_mark()}
      </Row>
      <Spacer size={10} />
    </Column>
    """
  end

  def language(l, false) do
    # The tag carries which language it is, so one handler serves every row and
    # a new locale is a data change rather than a code change.
    tap = {self(), Kati.Screens.Language.choose_tag(l)}

    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Kati.Theme.card(:light)}
        corner_radius={20}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={14}
        align="center"
        on_tap={tap}
      >
        {Kati.Screens.Language.code_tile(l)}
        <Spacer size={13} />
        {Kati.Screens.Language.language_body(l)}
        <Spacer size={13} />
        {Kati.Screens.Language.unselected_mark()}
      </Row>
      <Spacer size={10} />
    </Column>
    """
  end

  @doc """
  The 38pt paper tile every picker row leads with.

  `Kati.Components.MishkaThemeIcon` — "a themed container around exactly one
  icon" — rather than a fourth hand-rolled `Box`, which is the same call
  `Kati.UI.SettingsList.icon_tile/1` makes one size down. The three rows this
  screen draws above the card all lead with this tile, so it is one function
  and the "Add a language" row shares it.

  ## Why the pixels do not move

  With children, an explicit numeric `color`, no `id` and no `on_tap`,
  `theme_icon/2` returns
  `%{type: :box, props: %{width: 38, height: 38, align: :center,
  corner_radius: 12, background: 0xFFEFECE7}, children: [child]}` — node for
  node what this wrote by hand. `align: :center` and `align="center"` reach
  the bridge as the same string. Nothing else in the component runs: the
  `icon` shorthand is skipped when children are given, `:filled`'s gradient
  layer is empty, and the id markers need an `id`.

  The glyph is passed as a child rather than through the `icon` prop for the
  reason `SettingsList` gives — the shorthand builds a `Text` with no
  `font_family`, which would typeset a Material Symbols ligature as words and,
  here, would lose Vazirmatn on `فا` entirely.
  """
  def tile(child) do
    Kati.Components.MishkaThemeIcon.theme_icon(
      %{variant: :filled, color: 0xFFEFECE7, size: 38, radius: 12},
      [child]
    )
  end

  @doc false
  def code_tile(%{script: :fa} = l) do
    Kati.Screens.Language.tile(~MOB"""
    <Text text={l.code} font_family="fa" text_size={15} font_weight="bold" text_color={:on_surface} max_lines={1} />
    """)
  end

  def code_tile(l) do
    Kati.Screens.Language.tile(~MOB"""
    <Text text={l.code} font_family="mono" text_size={13} text_color={:on_surface} max_lines={1} />
    """)
  end

  @doc """
  The 24pt ink disc that marks the language you are in.

  Also `MishkaThemeIcon`: radius 12 at size 24 is an exact circle, and the
  component's own `:circle`-shaped siblings resolve theirs the same way. Its
  unfilled partner is `unselected_mark/0`, which is now the same component.
  """
  def selected_mark do
    Kati.Components.MishkaThemeIcon.theme_icon(
      %{variant: :filled, color: Kati.Theme.ink(), size: 24, radius: 12},
      [Kati.UI.symbol("check", size: 15, color: 0xFFFBFAF8)]
    )
  end

  @doc """
  The empty 24pt ring on a language you are **not** in.

  `MishkaThemeIcon` as of this round. 54.html draws it
  `width:24px;height:24px;border-radius:12px;border:1.5px solid
  rgba(26,25,23,.16)` — a hairline with no fill, at a fractional width — and
  the component used to reach a border only through `variant: :outline`,
  which forfeits the fill and hard-codes the width at 1. `border_color` and
  `border_width` are caller overrides on every variant now, so `:subtle`
  (which paints neither a background nor a border of its own) carries exactly
  the two the drawing specifies and nothing else.

  ## Why the pixels do not move

  `put_some/3` drops a nil, so `:subtle`'s absent background is absent from
  the node rather than a JSON `null`; with no `id`, no `icon` and no `on_tap`
  the id markers, the glyph shorthand and the handler are all skipped, and the
  gradient layer is empty for anything but `:gradient`. The node is
  `%{type: :box, props: %{width: 24, height: 24, align: :center,
  corner_radius: 12, border_color: 0x291A1917, border_width: 1.5},
  children: []}` — the `Box` written here by hand, plus an `align` that a
  childless box has nothing to apply.

  The 1.5 survives because the bridge reads `border_width` through
  `floatProp`; `intProp` — which is what `padding` and `max_lines` get — would
  have truncated it to 1.
  """
  def unselected_mark do
    Kati.Components.MishkaThemeIcon.theme_icon(%{
      variant: :subtle,
      size: 24,
      radius: 12,
      border_color: 0x291A1917,
      border_width: 1.5
    })
  end

  @doc false
  def language_body(%{script: :fa} = l) do
    ~MOB"""
    <Column weight={1.0}>
      <Text text={l.name} font_family="fa" text_size={15} font_weight="bold" text_color={:on_surface} max_lines={1} />
      <Spacer size={3} />
      <Text text={l.region} font_family="fa" text_size={12} text_color={0xFF8A8479} max_lines={1} />
    </Column>
    """
  end

  def language_body(l) do
    ~MOB"""
    <Column weight={1.0}>
      <Text text={l.name} text_size={14} font_weight="bold" text_color={:on_surface} max_lines={1} />
      <Spacer size={3} />
      <Text text={l.region} text_size={11.5} text_color={0xFF8A8479} max_lines={1} />
    </Column>
    """
  end

  # Solid, not dashed: `Modifier.border` takes a width and a colour and no
  # PathEffect. The 1.5pt weight and the alpha are the drawing's own.
  @doc false
  def add_language do
    a = Sample.add_language()
    tap = {self(), :add_language}

    ~MOB"""
    <Row
      fill_width={true}
      corner_radius={20}
      border_width={1.5}
      border_color={0x291A1917}
      padding={14}
      align="center"
      on_tap={tap}
    >
      {Kati.Screens.Language.tile(Kati.UI.symbol("add", size: 18, color: 0xFF8A8479))}
      <Spacer size={13} />
      <Column weight={1.0}>
        <Text text={a.title} text_size={14} font_weight="bold" text_color={0xFF8A8479} max_lines={1} />
        <Spacer size={3} />
        <Text text={a.sub} text_size={11.5} text_color={0xFF8A8479} max_lines={1} />
      </Column>
      <Spacer size={13} />
      {Kati.UI.SettingsList.chevron()}
    </Row>
    """
  end

  @doc false
  def group(rows, gap) do
    last = length(rows) - 1

    body =
      rows
      |> Enum.with_index()
      |> Enum.map(fn {row, i} -> Kati.Screens.Language.row(row, i < last) end)

    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.card(body)}
      <Spacer size={gap} />
    </Column>
    """
  end

  @doc false
  def row(row, rule?) do
    SettingsList.row(
      SettingsList.icon_tile(row.icon),
      Kati.Screens.Language.body(row),
      Kati.Screens.Language.control(row.control),
      padding: 13,
      rule: rule?
    )
  end

  # Vazirmatn for the two rows whose second line carries Persian — see the
  # moduledoc. The title stays in the body face; only the line with the glyphs
  # in it changes font.
  @doc false
  def body(%{script: :fa} = row) do
    ~MOB"""
    <Column fill_width={true}>
      <Text text={row.title} text_size={13.5} font_weight="semibold" text_color={:on_surface} max_lines={1} />
      <Spacer size={3} />
      <Text text={row.sub} font_family="fa" text_size={11.5} text_color={0xFF8A8479} max_lines={1} />
    </Column>
    """
  end

  def body(row), do: SettingsList.body(row.title, row.sub)

  @doc false
  def control(:chevron), do: SettingsList.chevron()
  def control({:switch, on?}), do: SettingsList.switch(on?)

  def control({:value, text}) do
    ~MOB"""
    <Text text={text} font_family="mono" text_size={11} text_color={0xFFA9A29A} max_lines={1} />
    """
  end

  @doc false
  def note do
    text = Sample.note()

    ~MOB"""
    <Row
      fill_width={true}
      corner_radius={18}
      border_width={1.5}
      border_color={0x291A1917}
      padding={15}
      align="top"
    >
      {Kati.UI.symbol("info", size: 17, color: 0xFF8A8479)}
      <Spacer size={11} />
      <Text text={text} text_size={12.5} line_height={1.55} text_color={0xFF5C574F} weight={1.0} />
    </Row>
    """
  end

  @impl true
  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "choose_language_" <> code ->
        {:noreply, choose(code, socket)}

      # `:add_language` lands here. 53.html and 54.html between them draw two
      # installed languages and `Kati.Locale.supported/0` returns two; there is
      # no drawn screen behind "Arabic, Turkish, German…" and no third locale
      # for it to install. Left tappable but inert rather than untapped, so the
      # row keeps the press feedback the drawing's control implies — and inert
      # through the catch-all, so it no longer raises into `rescue_tap/3`.
      _ ->
        {:noreply, socket}
    end
  end

  # `String.to_existing_atom/1` would do, and would raise on a tag this screen
  # did not write. Matching against `Kati.Locale.supported/0` cannot raise and
  # cannot name a locale the app does not have, which is the same check
  # `Kati.Locale.put/1` guards on — done here so the guard is never the thing
  # that fails.
  defp choose(code, socket) do
    locale = Enum.find(Kati.Locale.supported(), &(Atom.to_string(&1) == code))

    if locale && locale != socket.assigns.locale do
      Kati.Locale.put(locale)

      # Assigned before the push: `Mob.Screen` saves *this* socket onto the nav
      # history, so backing out of the Persian shell returns to a picker that
      # already shows فارسی selected and — via `Kati.Screens.Pushed.chrome/2`,
      # which reads the direction at render — already draws right to left.
      socket
      |> Mob.Socket.assign(:locale, locale)
      |> Mob.Socket.push_screen(shell_root(locale))
    else
      socket
    end
  end

  # The Persian mirrors hard-code `rtl` in `Kati.Screens.Fa.frame/2` rather than
  # reading the locale, so they are correct however this lands; the locale is
  # what makes every *other* screen agree with them.
  defp shell_root(:fa), do: Kati.Screens.HomeFa
  defp shell_root(_locale), do: Kati.Screens.Home
end
