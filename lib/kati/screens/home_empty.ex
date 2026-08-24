defmodule Kati.Screens.HomeEmpty do
  @moduledoc """
  Screen 139 — Home with nothing chosen, the state after *Skip, I will add
  things later*.

  Built to `.scratch/design/incoming/139.html`. Screen 01 is this same page
  once a section has something to show; this is the page the moment before
  any of them do, and — like screen 105 next to 104 — it earns a whole board
  rather than a state on some other screen's sheet, because it is the state
  every new user who skips onboarding lands in, and the only state in which
  Home has to argue for its own emptiness. The design's own caption is
  explicit about the shape that argument takes: *"skip 26 and 38·4 and this
  is what Home is. It follows 27's empty geometry — glyph tile, sentence, one
  ink action, one quiet alternative — and states which parts still work,
  because an empty Home that looks broken sends a new user back out."*

  ## Still a root, not a push

  Screen 105 is pushed under Stats because a page of goals is always
  reachable from somewhere with goals on it. Home is not reachable from
  anywhere — it is where the app opens — so this is `root: :home`, the tab
  bar and the FAB drawn by `Kati.Shell` exactly as they are for
  `Kati.Screens.Home`, `Kati.Screens.HomeDark` and `Kati.Screens.HomeFa`. The
  frame is Home's own `64px 21px 132px`, not 105's `40`: the dock still
  floats over the bottom of this page, because the dock is section-agnostic
  too.

  ## One disc, not two

  `Kati.Screens.Home.header/0` hangs a notification bell and a calendar disc
  off the greeting. Neither belongs here: the bell answers an inbox that has
  nothing in it before any section is chosen, and the calendar already has
  its own row lower on this same board. The drawing puts one disc — `tune` —
  and `Kati.Screens.Home.disc/3` is called for it directly rather than
  copied, at `badge?: false`, since it is the same 44pt card disc under the
  same `shadow_button/0` for the same reason. It reads as *Settings*, the one
  meaning `tune` already carries on this page — `Kati.Screens.Home.tile/5`
  labels the identical glyph "Settings" in its Sections row — so the tag is
  `:open_settings` and not a filter sheet nothing here would filter.

  The date line and the greeting are `Kati.Screens.Home.today/0`, not the
  drawing's own `Sunday · 16 August`. Screen 28 pins the drawing's literal
  deliberately, because it has to agree with screen 29's lock screen about
  what evening it is; this page carries no such twin, so it takes the device
  clock the way `Kati.Screens.Home` itself does rather than freezing a date
  that will be wrong the day after it ships.

  ## The card is 105's `invitation/1` at Home's own numbers

  Screen 27's empty recipe again — paper tile, sentence, one ink pill — and
  again not through `Kati.Screens.States.empty/1`, for the reason
  `Kati.Screens.GoalsEmpty.invitation/0` gives: that helper's card is 22/30 of
  padding around a 44pt `add` disc, and this one is radius 22 at 17pt of
  padding around a 54pt pill carrying a label and no glyph. Not one number is
  shared, so it is written out here too.

  The tile swaps `checklist` for `grid_view` — a picture of the six section
  tiles nothing has chosen yet, at the same 64pt paper square and the same
  `rail_idle/0` the goals board draws its own absence in.

  ## The secondary line is wired, and that is where this board leaves 105

  105's *or see what Kati already counts* stays a caption because its
  target — the list it points at — is already visible on the same board, and
  Mob has no way to scroll to a node it cannot tap toward. Neither excuse
  holds here: *or restore a backup* names a screen this board does not draw
  at all, and the caption calls it one of exactly two actions on the page —
  *"one ink action, one quiet alternative"* — not one action and one
  footnote. So it carries `on_tap`, pushing `Kati.Screens.Restore`.

  **Known gap, recorded rather than hidden.** `Kati.Screens.Restore` is
  `use Kati.Screens.Pushed, back: "Settings"`, correct on the one path the
  screen was built for — Settings → Backup → Restore — and slightly off on
  this one: tapping back here reads `‹ Settings` for a screen this page never
  opened. `Kati.Screens.RestoreFirstRun` exists because the same mismatch was
  worse from onboarding (no Settings screen had been *seen* at all yet, only
  never opened *from here*), and solved it with a second, chromeless screen.
  A third copy for one call site was not worth it: `pop_screen/1` still
  returns here regardless of what the pill reads, and the label is a papercut
  rather than a wrong destination.

  ## The calendar row is literal, and "stays live" is the tap, not the text

  The design draws exactly one state for this row — `Nothing scheduled — add
  anything with +` — and no other. `Kati.Calendars.Today` answers the
  device's real calendar and could, in principle, hold something even with
  every section off, since a mirrored calendar has nothing to do with which
  section cards Home draws. But this row is a one-line summary with no drawn
  shape for *what does a real event look like here*, and inventing one would
  be typing copy the board never wrote — the trap `Kati.Screens.GoalsEmpty`
  names at length for its own three counts. So the sentence is the drawing's,
  verbatim, and *"the calendar... stay[s] live"* is answered by the row's
  `on_tap` instead: it pushes `Kati.Screens.Calendar`, the real root, which
  reads `Kati.Calendars.Today` itself. The affordance is live; the caption
  under it is not a query.

  Built with `Kati.UI.SettingsList.card/1`, `icon_tile/1`, `body/2`,
  `chevron/0` — the same recipe screen 105's own list uses, at one row
  instead of three, `rule: false` since a single row has no rule to drop.

  ## The footnote is hand-built, for `Kati.Screens.BackupDark.no_server_note/0`'s reason

  `Kati.UI.SettingsList.note/2` draws this frame's family — solid where the
  design dashes, for the reason its own moduledoc gives — but two numbers
  here are one off that helper's: the icon sits at 17pt and the padding at
  15, where `note/2` is pinned to 18 and 16. And the sentence carries one
  semibold run in `Palette.ink/0` that `note/2`'s `label`-only path cannot
  typeset at all. `Kati.UI.rich_text/1` builds the paragraph instead, three
  runs long, the way `Kati.Screens.BackupDark.no_server_note/0` builds its
  own for the identical reason.

  `line_height: 1.65` is the drawing's own number for this paragraph, not
  `note_text/1`'s pinned `1.55` — the same one `no_server_note/0` also carries
  rather than the shared default, because both boards ask for a paragraph
  half a point looser than the helper draws everywhere else.

  ## The one property of the drawing that does not survive

  Both paragraphs in the card — the invitation's body and the footnote — are
  `text-wrap: pretty` in the export, which asks the browser to avoid a short
  last line. Compose has no balanced-wrap mode and the bridge exposes no prop
  for one, so both wrap greedily here. Recorded rather than worked around,
  for `Kati.Screens.GoalsEmpty`'s reason: the fix is a hard break typed into
  copy that is otherwise protected.
  """

  use Kati.Screens.Root, root: :home

  alias Kati.Components.MishkaThemeIcon
  alias Kati.Theme
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  @doc false
  @spec content(map()) :: map()
  def content(_assigns) do
    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={132}
      >
        {Kati.Screens.HomeEmpty.header()}
        {Kati.Screens.HomeEmpty.search()}
        {Kati.Screens.HomeEmpty.invitation()}
        {SettingsList.eyebrow_muted("The calendar still works")}
        {Kati.Screens.HomeEmpty.today_card()}
        {Kati.Screens.HomeEmpty.footnote()}
      </Column>
    </Scroll>
    """
  end

  @doc """
  The greeting, at `Kati.Screens.Home.today/0`'s own numbers, with the one
  disc this board draws.
  """
  @spec header() :: map()
  def header do
    {date_line, greeting} = Kati.Screens.Home.today()

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        <Column weight={1.0}>
          <Text
            text={String.upcase(date_line)}
            font_family="mono"
            text_size={11}
            letter_spacing={0.14}
            text_color={Palette.muted()}
          />
          <Spacer size={7} />
          <Text
            text={greeting}
            text_size={28}
            max_font_scale={1.6}
            font_weight="bold"
            letter_spacing={-0.03}
            text_color={:on_surface}
          />
        </Column>
        {Kati.Screens.Home.disc("tune", false, :open_settings)}
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc """
  The search bar, at the drawing's own copy.

  Same 52pt/radius-26 recipe `Kati.Screens.Home.search/0` draws, but not a
  call into it: this board's placeholder is *Search anything you keep*, not
  *Search films, shows, events…*, and this board draws no trailing `tune`
  glyph inside the bar — there is nothing yet to filter.

  **The shadow is not `Theme.shadow_search/0`.** Screen 01's own search bar
  is `0 1px 2px rgba(26,25,23,.04),0 8px 18px -14px rgba(26,25,23,.5)` — that
  token's own numbers. This board draws `0 1px 2px rgba(26,25,23,.04),0 12px
  24px -18px rgba(26,25,23,.7)` instead, which is `shadow_card_soft/0` byte
  for byte — the same lift the invitation card and the calendar row below it
  both carry. Two different depths for what reads as the same control on its
  sibling screen; the board's own number wins over the token named for this
  call site, the way `Kati.Screens.GoalsEmpty`'s moduledoc argues a shadow
  should.
  """
  @spec search() :: map()
  def search do
    ~MOB"""
    <Column fill_width={true}>
      <Box
        fill_width={true}
        height={52}
        background={Palette.card()}
        corner_radius={26}
        shadow={Theme.shadow_card_soft()}
        padding_left={18}
        padding_right={18}
        on_tap={{self(), :open_search}}
      >
        <Row fill_width={true} fill_height={true} align="center">
          {UI.symbol("search", size: 20, color: Palette.muted())}
          <Spacer size={11} />
          <Text
            text="Search anything you keep"
            text_size={14.5}
            text_color={Palette.muted()}
            weight={1.0}
            max_lines={1}
          />
        </Row>
      </Box>
      <Spacer size={26} />
    </Column>
    """
  end

  @doc """
  The card that says nothing is lost, and the two controls that follow from
  it — see the moduledoc for why both are wired where 105 only wires one.
  """
  @spec invitation() :: map()
  def invitation do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        padding={17}
        shadow={Theme.shadow_card_soft()}
      >
        <Spacer size={14} />
        <Row fill_width={true} align="center">
          <Spacer weight={1.0} />
          {Kati.Screens.HomeEmpty.tile()}
          <Spacer weight={1.0} />
        </Row>
        <Spacer size={18} />
        <Text
          text="Nothing chosen yet"
          text_size={17}
          font_weight="bold"
          letter_spacing={-0.02}
          text_align="center"
          text_color={:on_surface}
        />
        <Spacer size={9} />
        <Text
          text="Kati keeps what you tell it to. Pick a section and this page fills with what you are watching, reading and eating."
          text_size={13}
          line_height={1.6}
          text_align="center"
          text_color={Palette.sub()}
        />
        <Spacer size={18} />
        {Kati.Screens.HomeEmpty.choose_sections()}
        <Spacer size={15} />
        {Kati.Screens.HomeEmpty.restore_link()}
        <Spacer size={14} />
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  The 64pt paper square the card is headed by — `grid_view`, a picture of the
  section grid nothing has chosen from yet, at `Kati.Screens.GoalsEmpty.tile/0`'s
  own metrics: 64 square, radius 20, `rail_idle/0` on `paper/0`.

  The glyph goes in as a child rather than through `theme_icon/2`'s `icon`
  shorthand, for the reason `icon_tile/1` gives: that shorthand builds a
  `Text` with no `font_family` and would typeset `grid_view` as three words.
  """
  @spec tile() :: map()
  def tile do
    MishkaThemeIcon.theme_icon(
      %{variant: :filled, color: Palette.paper(), size: 64, radius: 20},
      [UI.symbol("grid_view", size: 28, color: Palette.rail_idle())]
    )
  end

  @doc """
  The one ink pill on the board — `Kati.Screens.GoalsEmpty.set_a_goal/0`'s
  own recipe, a 54pt pill with a label and no glyph, at the drawing's own
  `0 14px 28px -12px rgba(26,25,23,.5)`, which no `Kati.Theme` shadow names
  — `shadow_hero/0` is the closest and is gold at a -20 spread — so it is
  written out in the prop's own format here too.
  """
  @spec choose_sections() :: map()
  def choose_sections do
    ~MOB"""
    <Box
      fill_width={true}
      height={54}
      corner_radius={27}
      background={Palette.ink_fill()}
      shadow="0 14 28 -12 #801A1917"
      align="center"
      on_tap={{self(), :choose_sections}}
    >
      <Text
        text="Choose sections"
        text_size={14.5}
        font_weight="bold"
        text_color={Palette.on_ink()}
        max_lines={1}
      />
    </Box>
    """
  end

  @doc """
  *or restore a backup* — the board's second action, wired to
  `Kati.Screens.Restore`. See the moduledoc for why this diverges from
  `Kati.Screens.GoalsEmpty`'s own secondary line, which stays a caption.
  """
  @spec restore_link() :: map()
  def restore_link do
    ~MOB"""
    <Column fill_width={true} on_tap={{self(), :restore_backup}}>
      <Text
        text="or restore a backup"
        text_size={12.5}
        font_weight="semibold"
        text_align="center"
        text_color={Palette.sub()}
      />
    </Column>
    """
  end

  @doc """
  *Today*, one row, `Kati.UI.SettingsList`'s own recipe — `card/1`,
  `icon_tile/1`, `body/2`, `chevron/0` unchanged, `rule: false` since a
  single row has no hairline to drop.
  """
  @spec today_card() :: map()
  def today_card do
    row =
      SettingsList.row(
        SettingsList.icon_tile("calendar_month"),
        SettingsList.body("Today", "Nothing scheduled — add anything with +"),
        SettingsList.chevron(),
        on_tap: {self(), :open_calendar},
        rule: false
      )

    assigns = %{card: SettingsList.card(row)}

    ~MOB"""
    <Column fill_width={true}>
      {@card}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  The dashed-frame footnote, hand-built for
  `Kati.Screens.BackupDark.no_server_note/0`'s reason — see the moduledoc.
  """
  @spec footnote() :: map()
  def footnote do
    body_style = [text_size: 12.5, line_height: 1.65, text_color: Palette.ink_soft()]

    paragraph =
      UI.rich_text([
        {"Home is a page of section cards, so with no sections there is nothing for it to " <>
           "show. The calendar and quick-add are section-agnostic and stay live — ", body_style},
        {"the app is usable before it is configured",
         [font_weight: "semibold", text_color: Palette.ink()]},
        {".", body_style}
      ])

    assigns = %{paragraph: %{paragraph | props: Map.put(paragraph.props, :weight, 1.0)}}

    ~MOB"""
    <Row
      fill_width={true}
      corner_radius={18}
      border_color={Palette.border()}
      border_width={1.5}
      padding={15}
      align="top"
    >
      {UI.symbol("info", size: 17, color: Palette.sub())}
      <Spacer size={11} />
      {@paragraph}
    </Row>
    """
  end

  @impl true
  @spec handle_tap(atom(), term()) :: {:noreply, term()}
  def handle_tap(:open_settings, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Settings)}

  def handle_tap(:open_search, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.SearchIdle)}

  def handle_tap(:choose_sections, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.PickSections)}

  def handle_tap(:restore_backup, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Restore)}

  def handle_tap(:open_calendar, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Calendar)}
end
