defmodule Kati.Screens.Settings do
  @moduledoc """
  Screen 24 — Settings, pushed under Home.

  Built to `.scratch/design/screens/24.html`. Everything the app can be told,
  in the same card rhythm as every other screen: an account card, then four
  grouped lists.

  The **Sections** group is the growth mechanic made literal. Each row names
  the surfaces its section appears on — "Home card, calendar feed, shelf" —
  so a switch is not an opaque toggle but a statement about what will stop
  being drawn. That is also why Money ships off while the other four ship on:
  the drawing states the default, and defaults are the product.

  The last eyebrow's dash is grey, not orange. Orange means new/now, and About
  is a footnote to Data rather than a peer of it, so it uses
  `Kati.UI.SettingsList.eyebrow_muted/1`.

  No dock — this is a pushed screen — so the frame closes at 40, not 132.

  ## The controls are live, and the resting frame is untouched

  Every switch row taps to flip — the whole row, not just the 46pt track, which
  is how a settings list has behaved since the first one. The theme segments
  tap to select. `Kati.Settings.Sample` still states the defaults, so the screen
  at rest is byte-for-byte what `24.html` draws: Auto raised, Money off, the
  other four sections on.

  The account card's "4 SECTIONS" is the one number that had to stop being a
  literal. It is now the Sections group's own tally, so switching Money on
  makes it five. At rest the count is four and `meta/2` rewrites four as four —
  a header that contradicts the switches under it is worse than no header.

  ## The theme segments are the app's appearance mode, not a highlight

  Until this round the trough moved and nothing else did: the raised tile was
  a value in this screen's own assigns, thrown away with the socket the moment
  you backed out. Screen 24 draws the one control in the app that says which
  palette to use, so it now writes the choice where the rest of the app can
  read it.

  `Kati.Theme.Mode` owns that choice — `choice/0`, `put/1`, `choices/0`,
  stored in `Mob.State` for the same reason `Kati.Locale` stores the language
  there: the screen process dies on the next root switch, so a preference held
  in assigns is gone before anything uses it. Exactly three functions below
  reach it — `choices/0`, `choice/0` and `put_choice/1`, each one call deep —
  and they are the only place either settings screen names it. The rest of that
  section is position arithmetic layered on those three.
  `Kati.Screens.SettingsFa` calls them rather than repeating them, so the whole
  boundary is three lines in one file.

  Writing the choice is not the same as showing it. `Mob.Theme.set/1`
  snapshots a palette rather than re-reading one, so `Kati.Theme.Mode.put/1`
  alone would be correct and invisible until the next root switch;
  `put_choice/1` therefore calls `Kati.Theme.activate/0` too, which is what
  `Kati.Theme.Mode.put/1`'s own doc asks a settings tap to do. The re-render
  that makes it visible is the tap's returned socket.

  ### Position, not the English word

  A tap tells this screen a label — `"Dark"` — and the store wants an atom.
  The bridge between them is the trough's **order**, not the string:
  `Kati.Theme.Mode.choices/0` is `[:auto, :light, :dark]` and both drawings put
  the three tiles in exactly that order, so `choice_for/2` maps the label to a
  choice by where it sits in its own `options` list. That is what lets the
  Persian mirror — whose tiles say خودکار / روشن / تیره and whose tags carry an
  index rather than a word — share this code with no translation table between
  them.

  ### The resting frame still cannot move

  `Kati.Theme.Mode.choice/0` answers `:auto` for a key that has never been
  written, `:auto` is first, and first is what `Kati.Settings.Sample` already
  selected. So a fresh install renders the trough exactly as `24.html` draws
  it, and only a user who has actually chosen sees anything else.

  ### The raised tile stops being tappable

  It carried an `on_tap` that set the value it already had. Dropping it costs
  the press ripple on a tile that could not respond to a press anyway, and buys
  the invariant every switcher in this app relies on: **the tags a screen draws
  are the choices it can still make.** `Kati.Screens.Language` selects its rows
  this way for the same reason, and `Kati.ScreenSweep.tap_tags/1` names the
  selected segment of a switcher as the thing that is supposed to carry no tag.
  Without it, "tapping the lit tile changes nothing" and "this control is dead"
  are the same observation, and the sweep that tells them apart has to be told
  which one this is — separately for each mode the screen might have been
  mounted in.
  """
  use Kati.Screens.Pushed, back: "Home"

  alias Kati.Settings.Sample
  alias Kati.UI
  alias Kati.UI.SettingsList

  @impl true
  def load(socket) do
    Mob.Socket.assign(socket, :settings, %{
      synced: Sample.synced(),
      account: Sample.account(),
      appearance: Kati.Screens.Settings.settle(Sample.appearance()),
      sections: Sample.sections(),
      data: Sample.data(),
      about: Sample.about()
    })
  end

  # ── The appearance choice ───────────────────────────────────────────────────
  #
  # `choices/0`, `choice/0` and `put_choice/1` are the whole surface both
  # settings screens have on `Kati.Theme.Mode` — one call each, and nothing else
  # in either file names that module. What follows them turns a tile's position
  # into a choice and back, which is arithmetic over `choices/0` alone.

  @doc """
  Every choice the trough offers, in the order both drawings draw the tiles.

  Ordered, not a set: `choice_at/1` and `label_for/2` read positions off this
  list, and a reordering silently relabels every tile in both locales.
  """
  @spec choices() :: [Kati.Theme.Mode.choice()]
  def choices, do: Kati.Theme.Mode.choices()

  @doc """
  The appearance choice the user has made, or `:auto` if they never have.

  The **choice**, not the resolved mode: `Kati.Theme.mode/0` answers `:light`
  or `:dark` and is what a palette wants, while the trough has to be able to
  raise Auto, which is neither.
  """
  @spec choice() :: Kati.Theme.Mode.choice()
  def choice, do: Kati.Theme.Mode.choice()

  @doc """
  Store the user's choice and make it the active palette.

  Both halves, because they are two different things: `Kati.Theme.Mode.put/1`
  persists the preference, and `Kati.Theme.activate/0` re-snapshots the palette
  that `Mob.Theme.set/1` had already frozen. Storing without activating is a
  correct setting nobody can see until the next root switch — the case
  `Kati.Theme.Mode.put/1`'s own doc warns a settings tap about.
  """
  @spec put_choice(Kati.Theme.Mode.choice()) :: :ok
  def put_choice(choice) do
    :ok = Kati.Theme.Mode.put(choice)
    :ok = Kati.Theme.activate()
  end

  @doc """
  The choice a trough's `index`-th tile stands for, or `nil` for any index no
  tile has.

  Negatives are rejected rather than passed through: `Enum.at/2` reads `-1` as
  the *last* element, so a malformed tag would otherwise select Dark.
  """
  @spec choice_at(term()) :: Kati.Theme.Mode.choice() | nil
  def choice_at(index) when is_integer(index) and index >= 0,
    do: Enum.at(Kati.Screens.Settings.choices(), index)

  def choice_at(_index), do: nil

  @doc """
  Which of `options` stands for `choice` — the label to raise.

  Falls back to the first option rather than to none: a trough with no tile
  raised is not a state either drawing has, and is worse than raising the
  default.
  """
  @spec label_for([String.t()], atom()) :: String.t() | nil
  def label_for(options, choice) do
    index = Enum.find_index(Kati.Screens.Settings.choices(), &(&1 == choice)) || 0
    Enum.at(options, index) || List.first(options)
  end

  @doc "The choice `label` stands for within `options`, or `nil` if it is not one."
  @spec choice_for([String.t()], String.t()) :: Kati.Theme.Mode.choice() | nil
  def choice_for(options, label) do
    case Enum.find_index(options, &(&1 == label)) do
      nil -> nil
      index -> Kati.Screens.Settings.choice_at(index)
    end
  end

  @doc """
  Point a group's segmented control at the stored choice.

  Applied once, at mount, so a tap afterwards is an ordinary change to a shape
  that already exists — the same move `Kati.Screens.SettingsFa.settle/1` makes,
  and for the same reason.
  """
  @spec settle([map()]) :: [map()]
  def settle(rows) do
    choice = Kati.Screens.Settings.choice()

    Enum.map(rows, fn
      %{control: {:segments, options, _}} = row ->
        %{row | control: {:segments, options, Kati.Screens.Settings.label_for(options, choice)}}

      row ->
        row
    end)
  end

  @doc false
  def content(assigns) do
    s = assigns.settings

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
        {SettingsList.title("Settings", s.synced, "help")}
        {Kati.Screens.Settings.account(s.account, s.sections)}
        {UI.eyebrow("Appearance")}
        {Kati.Screens.Settings.group(s.appearance, 14, 22)}
        {UI.eyebrow("Sections")}
        {Kati.Screens.Settings.group(s.sections, 13, 22)}
        {UI.eyebrow("Data")}
        {Kati.Screens.Settings.group(s.data, 14, 22)}
        {SettingsList.eyebrow_muted("About")}
        {Kati.Screens.Settings.group(s.about, 14, 0)}
      </Column>
    </Scroll>
    """
  end

  @doc false
  def account(a, sections) do
    meta = Kati.Screens.Settings.meta(a.meta, Kati.Screens.Settings.enabled(sections))

    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={0xFFFBFAF8}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={16}
        align="center"
      >
        {Kati.Screens.Settings.avatar(a)}
        <Spacer size={14} />
        <Column weight={1.0}>
          <Text
            text={a.name}
            text_size={16}
            font_weight="bold"
            letter_spacing={-0.02}
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={4} />
          <Text
            text={meta}
            font_family="mono"
            text_size={10.5}
            text_color={0xFFA9A29A}
            max_lines={1}
          />
        </Column>
        <Spacer size={14} />
        {Kati.Screens.Settings.status(a.status)}
      </Row>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  The green *Synced* token at the trailing end of the account card.

  `Kati.Components.MishkaPill`, because that is what this is: a compact,
  untappable label on a tinted ground — the port's own line for telling the two
  apart is *"a Chip is selected, a Pill is removed"*, and this is neither, which
  leaves the pill's plain body. It could not be one until the port took `height`,
  per-edge padding and `corner_radius`; on its old hardcoded `:space_sm` and
  `:radius_pill` it could only draw a differently shaped token.

  The glyph and the label go in as **content** rather than as `label`, for the
  reason `Kati.Screens.Subscriptions.badge/1` gives about the avatar: the
  component's own `Text` carries one string, and this token is an icon *and* a
  word in a shared colour. Content replaces that `Text` wholesale, so the
  drawing's `cloud_done` at 14 and its semibold 11 survive untouched.

  **The pixels are the same node.** The port builds

      <Box background={0x294E9A73} corner_radius={13} padding={0}
           fill_width={false} height={26} padding_left={10} padding_right={10}
           align={:center}>
        <Row><Row>{glyph, gap, label}</Row><Row /></Row>
      </Box>

  where this was a single `<Row height={26} corner_radius={13} background
  padding_left={10} padding_right={10} align="center">` holding the same three
  children. Both hug: a `Row` never fills, and a `Box` told `fill_width={false}`
  hugs too (K-17). `padding` is `0` rather than left to the port's `:space_sm`
  so the uniform and the two edges agree — the bridge's `pad/1` resolves an
  unset edge to the uniform, so top and bottom come out `0`, which is what a
  `Row` with only horizontal padding had. `height` is applied after padding on
  both, so both measure 26 outside. The port's two wrapper `Row`s carry no
  props: the outer one hugs, the empty trailing one is `with_remove: false` and
  measures 0x0, and Compose's `Row` centres vertically unless told `top` or
  `bottom` — the same default the hand-rolled `align="center"` was asking for.
  """
  def status(label) do
    Kati.Components.MishkaPill.pill(
      [
        background: 0x294E9A73,
        corner_radius: 13,
        height: 26,
        padding: 0,
        padding_left: 10,
        padding_right: 10,
        align: :center
      ],
      [
        Kati.UI.symbol("cloud_done", size: 14, color: 0xFF3E8460),
        ~MOB"<Spacer size={5} />",
        ~MOB"""
        <Text text={label} text_size={11} font_weight="semibold" text_color={0xFF3E8460} max_lines={1} />
        """
      ]
    )
  end

  @doc """
  The 52pt round face at the head of the account card.

  `Kati.Components.MishkaAvatar` rather than a hand-rolled `Image`, because an
  image with a coloured fallback behind it is precisely what that component is:
  `shape: :circle` resolves to an exact `size / 2` radius, so 52 gives the
  drawing's own 26, and the missing-poster case is the component's own fallback
  rather than a second clause here.

  The pixels do not move. With a poster the component stacks
  `[fallback, image]` in a 52x52 box, and a 52pt `content_mode="fill"` image at
  radius 26 covers the fallback exactly — the same node the screen drew before,
  over a disc nothing can see. Without one it draws the fallback alone: the same
  `#E4E0D9` disc, now carrying an empty `Text` that has no glyphs to draw.

  What it adds is the moment in between. The disc is painted while the poster is
  still being read off disk, where the old markup drew a hole.
  """
  def avatar(a) do
    Kati.Components.MishkaAvatar.avatar(
      src: Kati.Design.Images.poster(a.seed),
      size: 52,
      background: 0xFFE4E0D9
    )
  end

  @doc "How many sections are switched on right now."
  def enabled(sections), do: Enum.count(sections, &match?(%{control: {:switch, true}}, &1))

  @doc """
  The account line with its section count replaced by the live tally.

  A substitution rather than a rebuilt string, so the copy still lives in
  `Kati.Settings.Sample` and the resting frame cannot drift: with four sections
  on, this rewrites `4 SECTIONS` as `4 SECTIONS`. If the pattern ever stops
  matching, the sample's own line is returned untouched.
  """
  def meta(text, count), do: Regex.replace(~r/\d+ SECTIONS/, text, "#{count} SECTIONS")

  @doc false
  def group(rows, pad, gap) do
    last = length(rows) - 1

    body =
      rows
      |> Enum.with_index()
      |> Enum.map(fn {row, i} -> Kati.Screens.Settings.row(row, pad, i < last) end)

    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.card(body)}
      <Spacer size={gap} />
    </Column>
    """
  end

  @doc false
  def row(row, pad, rule?) do
    SettingsList.row(
      SettingsList.icon_tile(row.icon),
      SettingsList.body(row.title, row.sub),
      Kati.Screens.Settings.control(row.control),
      padding: pad,
      rule: rule?,
      on_tap: Kati.Screens.Settings.tap_for(row)
    )
  end

  # Which rows lead somewhere. A row with no destination gets no tap, so it
  # does not pretend to be a link.
  @destinations %{
    "Release watcher" => Kati.Screens.ReleaseWatcher,
    "Calendars" => Kati.Screens.Calendars,
    "Auto-detect" => Kati.Screens.AutoDetect,
    "Import" => Kati.Screens.Import,
    "Widgets" => Kati.Screens.Widgets,
    "Account" => Kati.Screens.Account,
    "Accessibility" => Kati.Screens.Accessibility,
    "Language" => Kati.Screens.Language,
    "Text size" => Kati.Screens.Accessibility,
    "States" => Kati.Screens.States
  }

  @doc false
  def destinations, do: @destinations

  @doc """
  What a row does when you tap it — anywhere on it, not only on its control.

  A switch row flips; a row that names a screen opens it; anything else stays
  inert rather than pretending. The tag carries the row's own title, so adding
  a switch to `Kati.Settings.Sample` needs no code here. No title is both a
  switch and a destination, so the two prefixes cannot collide.

  The Theme row is the exception with no row tap of its own: its three segments
  each carry their own, because tapping the row could not say *which* theme.
  """
  def tap_for(%{control: {:switch, _}, title: title}),
    do: {self(), String.to_atom("switch_" <> title)}

  def tap_for(%{title: title}) do
    if Map.has_key?(@destinations, title), do: {self(), String.to_atom("go_" <> title)}
  end

  @doc false
  def control(:chevron), do: SettingsList.chevron()
  def control({:switch, on?}), do: SettingsList.switch(on?)

  def control({:segments, options, selected}),
    do: Kati.Screens.Settings.segments(options, selected)

  @doc """
  The theme picker, at a third of the size of screen 25's.

  Same trough-and-raised-tile idea, but it lives inside a row rather than
  spanning the frame, so its segments hug their labels instead of taking a
  weight.

  Not `Kati.Components.MishkaSegmentedControl`, and this one is blocked twice
  over:

    * **No gap between segments.** The drawing puts 3pt between the three tiles;
      the port emits them back to back and has no prop that inserts a `<Spacer>`,
      nor any way to intersperse one by hand — `expand/3` drops every child that
      is not an option. `padding` cannot stand in, because `MobBridge` applies
      `background` before `padding`, so a segment's padding widens the raised
      tile's own white rectangle instead of separating it from its neighbour.
      `Kati.Screens.ViewSwitcher` records this at length.
    * **The control always wraps itself in `<Column fill_width={true}>`.** That
      wrapper is unconditional — it is there to carry the optional `label`
      heading, and it stays when there is none. This strip is the trailing cell
      of a settings row and must *hug* its three labels; a full-width Column
      would take the row's whole leftover width and drag the trough with it.

  The tiles themselves are within reach: `Kati.Components.MishkaChip` at
  `height: 26, padding_y: 0, padding_x: 10, corner_radius: 9` is `segment/2`'s
  box exactly — except that the selected one carries `0 1 2 0 #1F1A1917`, and
  the chip has **no `shadow` prop**. Without the lift the raised tile stops
  reading as raised, which is the whole of what "selected" says here.
  """
  def segments(options, selected) do
    tiles =
      options
      |> Enum.map(fn o -> Kati.Screens.Settings.segment(o, o == selected) end)
      |> Enum.intersperse(Kati.Screens.Settings.segment_gap())

    ~MOB"""
    <Row background={0xFFEFECE7} corner_radius={12} padding={3} align="center">
      {tiles}
    </Row>
    """
  end

  @doc false
  def segment_gap, do: ~MOB"<Spacer size={3} />"

  # Two clauses rather than one, because the raised tile carries a shadow the
  # trough's other two must not have — and, since this round, no `on_tap`. Only
  # the unselected tiles are choices; see the moduledoc on what that buys. The
  # prop is omitted rather than passed as `nil`, which this bridge would send
  # down the wire as the string "nil".
  @doc false
  def segment(label, true) do
    ~MOB"""
    <Row
      height={26}
      corner_radius={9}
      background={0xFFFBFAF8}
      shadow="0 1 2 0 #1F1A1917"
      padding_left={10}
      padding_right={10}
      align="center"
    >
      <Text
        text={label}
        text_size={11}
        font_weight="semibold"
        text_color={:on_surface}
        max_lines={1}
      />
    </Row>
    """
  end

  def segment(label, false) do
    tap = {self(), String.to_atom("theme_" <> label)}

    ~MOB"""
    <Row
      height={26}
      corner_radius={9}
      padding_left={10}
      padding_right={10}
      align="center"
      on_tap={tap}
    >
      <Text
        text={label}
        text_size={11}
        font_weight="semibold"
        text_color={0xFFA0998F}
        max_lines={1}
      />
    </Row>
    """
  end

  @impl true
  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "go_" <> title ->
        case Map.fetch(@destinations, title) do
          {:ok, module} -> {:noreply, Mob.Socket.push_screen(socket, module)}
          :error -> {:noreply, socket}
        end

      "switch_" <> title ->
        {:noreply, put_rows(socket, &flip(&1, title))}

      "theme_" <> label ->
        {:noreply, choose_theme(socket, label)}

      _ ->
        {:noreply, socket}
    end
  end

  # Appearance and Sections are the only two groups holding a control that can
  # move; Data and About are chevrons all the way down. Both lists go through
  # the same function because a title is unique across the screen, so a rule
  # written once cannot hit the wrong row.
  defp put_rows(socket, fun) do
    s = socket.assigns.settings
    settings = %{s | appearance: fun.(s.appearance), sections: fun.(s.sections)}
    Mob.Socket.assign(socket, :settings, settings)
  end

  defp flip(rows, title) do
    Enum.map(rows, fn
      %{title: ^title, control: {:switch, on?}} = row -> %{row | control: {:switch, not on?}}
      row -> row
    end)
  end

  defp choose(rows, label) do
    Enum.map(rows, fn
      %{control: {:segments, options, _}} = row ->
        if label in options, do: %{row | control: {:segments, options, label}}, else: row

      row ->
        row
    end)
  end

  # Store first, then move the tile, and only for a label the trough actually
  # draws. The screen's own copy of the choice and the app-wide one are written
  # from the same guard, so the raised tile and `mode/0` cannot disagree — and
  # a tag naming a label this trough does not have changes neither.
  defp choose_theme(socket, label) do
    options = theme_options(socket.assigns.settings.appearance)

    case Kati.Screens.Settings.choice_for(options, label) do
      nil ->
        socket

      choice ->
        Kati.Screens.Settings.put_choice(choice)
        put_rows(socket, &choose(&1, label))
    end
  end

  # The Appearance group holds at most one segmented control — the Theme row.
  defp theme_options(rows) do
    Enum.find_value(rows, [], fn
      %{control: {:segments, options, _}} -> options
      _ -> false
    end)
  end
end
