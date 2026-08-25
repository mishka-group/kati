defmodule Kati.Screens.RestoreFirstRun do
  @moduledoc """
  Screen 135 — *Bring your Kati back*, the chromeless twin of 129, reached
  from inside first-run onboarding rather than from Settings.

  Built to `test/design/reference/135.html`. The flow map, `134.html`,
  draws it as a branch offered on two of the five onboarding steps — 38·1
  (Welcome) and 26 (`Kati.Screens.PickSections`) — with one outgoing edge:
  "file accepted" into 37, `Kati.Screens.Import`. Reached from onboarding, so
  there is no tab bar to sit under; reached before there is anything to
  navigate back to inside the app, so there is no back pill either — only the
  step meter above and a plain text link below.

  ## Why this is not a call into `Kati.Screens.Restore`

  129 draws the identical file row and scan card this screen draws, and
  `129.html`'s own caption says so — "37's pre-write summary and conflict
  resolver used verbatim." But 129 is `use Kati.Screens.Pushed, back:
  "Settings"`: a fixed back pill reading **Settings**, correct on the one path
  that reaches it (Settings → Backup → Restore) and wrong on every path that
  reaches this screen instead. Pushing into 129 from onboarding would draw a
  back pill promising a Settings screen that was never opened. So this is a
  second screen, not a redirect to the first — `use Mob.Screen` directly, the
  same choice `Kati.Screens.PickSections` makes for the same reason: "Step 2
  of 4 has neither a tab bar nor a back pill in the drawing... so this uses
  `Mob.Screen` directly."

  ## The collapse `135.html`'s own caption asks for

  129 previews a write onto a device that already holds a library: three
  counts — New, Merged, Conflicts — because a merge can genuinely produce all
  three. A first run has nothing on the device yet, so two of those three
  numbers are always zero and the third is dishonest as a *count* rather than
  a *total*. The caption states the fix directly: *"On an empty device 37's
  three-count summary is dishonest... so it collapses to a single figure and
  says so in words."* `outcome_card/1` is that single figure — one DM Mono
  total beside a sentence that names what will not happen (no merge, no
  replace, nothing to lose) — built from `Kati.Backup.SampleRestore.replace/1`,
  the same `%{count: "418", noun: "titles"}` 129's own `replace_card/1` reads,
  because it is the same fact — everything on the file — read a second way.

  ## Reused rather than copied

    * `Kati.Backup.SampleRestore.file/0` and `.replace/0` — the picked
      filename and the `418 titles` figure, unchanged from 129's own fixture,
      because both screens preview the same one backup.
    * `Kati.UI.SettingsList.card/1`, `.row/4`, `.icon_tile/1`, `.body/2` and
      `.chevron/0` — the file row, node for node what 129's own `file_row/1`
      draws, because `135.html` draws the identical row.
    * `Kati.UI.eyebrow/2` — "This device has no data" sits at the design's own
      defaults (9pt dash gap, 11pt tail, 2pt side inset), so nothing here
      overrides them.
    * `Kati.Screens.Restore.qr_pattern/0` — the 49-cell QR glyph is read off
      `135.html` cell for cell and comes out identical to 129's own reading of
      it, which makes sense: it is the same iconographic mark, drawn twice.

  ## Redrawn, because the numbers are not 129's

  The scan tile is 70pt here and 74pt on 129 — `135.html` sets `width:70px;
  height:70px` where `129.html` sets 74 — so `scan_tile/0` is this screen's
  own function, not a call to `Kati.Screens.Restore.scan_tile/0`. Its module
  size follows 129's own arithmetic on this board's own numbers: 7 modules
  across a 50px row with 6 gaps of 2px is `(50 - 6·2) / 7`, kept to two
  decimals as `5.43` rather than rounded, for the reason 129's moduledoc gives
  for its own `5.71` — a cleaner number would drift the pattern off-centre.
  The shadow stays 129's own `"0 6 16 -8 #7378501E"`: 45% of the same warm
  brown `Kati.Theme.shadow_hero/0` already carries at 50%, and `135.html`
  draws the identical `rgba(120,80,30,.45)`, so there is no second literal to
  invent here either.

  The step meter is its own function too, not a call into
  `Kati.Screens.PickSections.step/1`: the shape is identical — a `Row` of
  weighted bars gapped 5, ink for done and `Palette.track_off/0` for not —
  but the count is this board's own. `135.html` draws five bars with the
  first two filled, matching where the branch is offered from (mid-sequence,
  past Language and into Welcome) rather than counting steps of its own; this
  screen is a branch, not a sixth step, so `steps/0` draws the meter's
  resting position rather than advancing it.

  ## Every drawn control reaches a handler, and here is which one

  `135.html` draws five tappable things and the flow map draws exactly one
  destination out of this node, so three of the five converge on it:

    * **Pick a file**, **Scan from your old phone** and **Restore
      everything** all push `Kati.Screens.Import` — the flow map's own
      "file accepted" arrow. They are kept as three tags rather than one
      shared atom because they are three different controls a person can
      point at, even though `135.html` gives them one shared outcome; a
      screenshot of `Kati.ScreenTapSweepTest` failing over `:restore_everything`
      should not read "did you mean `:pick_file`". `Kati.Screens.Import` is
      the same placeholder `Kati.Screens.PickSections.handle_info/2` already
      routes its own "Restore from a backup instead" link through, and for
      the same reason that link gives: the real destination is a conflict
      resolver, and an empty first-run device has no conflicts to resolve —
      collapsing to Import's generic pre-write summary is the honest stand-in
      until a chromeless preview screen exists to receive this specific edge
      rather than 129's Settings-flavoured one.
    * **Back to welcome** pushes `Kati.Screens.Onboarding`, screen 38, whose
      first section renders the Welcome step this link names.
    * **Set up fresh instead** pushes `Kati.Screens.PickSections`, screen 26 —
      the step the design's own "Get started" arrow leads to from Welcome, so
      declining to restore lands exactly where accepting Welcome would have.

  ## Audited

  **No backup is actually inspected or written by any tap on this screen.**
  `Kati.Backup.inspect_file/2` and `Kati.Backup.restore_file/2` are real and
  reachable, but nothing on `135.html` hands them a path — the filename in
  the file row is `Kati.Backup.SampleRestore.file/0`'s fixture, not a result
  of a system file picker Mob does not expose to a screen module, and the QR
  card scans nothing. Every tap here is real in the sense the sweep checks —
  it changes the screen stack — and not yet real in the sense the feature
  needs, which is `Kati.Screens.Backup`'s own gap to close, not this drawing's.

  No dock and no back pill, so the frame's bottom inset is 40, not 132, the
  same choice `Kati.Screens.PickSections` makes for the same reason.
  """
  use Mob.Screen
  import Mob.Sigil

  alias Kati.Backup.SampleRestore
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  def mount(_params, _session, socket) do
    Mob.Theme.set(Kati.Theme.current())

    {:ok,
     Mob.Socket.assign(socket, :restore, %{
       file: SampleRestore.file(),
       replace: SampleRestore.replace()
     })}
  end

  def render(assigns) do
    job = assigns.restore

    ~MOB"""
    <Box
      fill_width={true}
      fill_height={true}
      background={:background}
      layout_direction={Kati.Locale.direction_prop()}
      accessibility_id={Kati.Screens.Identity.of(__MODULE__)}
    >
      <Scroll>
        <Column
          fill_width={true}
          padding_left={21}
          padding_right={21}
          padding_top={64}
          padding_bottom={40}
        >
          {Kati.Screens.RestoreFirstRun.intro()}
          {Kati.Screens.RestoreFirstRun.file_row(job.file)}
          {Kati.Screens.RestoreFirstRun.scan_card()}
          {UI.eyebrow("This device has no data")}
          {Kati.Screens.RestoreFirstRun.outcome_card(job.replace)}
          {Kati.Screens.RestoreFirstRun.cta_button()}
          {Kati.Screens.RestoreFirstRun.footer()}
        </Column>
      </Scroll>
    </Box>
    """
  end

  # `:pick_file`, `:scan_qr` and `:restore_everything` share a destination —
  # see the moduledoc for why the flow map draws one arrow out of three
  # controls. `:back_to_welcome` and `:set_up_fresh` are the chromeless foot
  # link `134.html` requires of every onboarding screen without a dock.
  def handle_info({:tap, tag}, socket) do
    case Atom.to_string(tag) do
      "pick_file" -> {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Import)}
      "scan_qr" -> {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Import)}
      "restore_everything" -> {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Import)}
      "back_to_welcome" -> {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Onboarding)}
      "set_up_fresh" -> {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.PickSections)}
      _ -> {:noreply, socket}
    end
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  # ── Steps, headline, blurb ───────────────────────────────────────────────────

  @doc false
  def intro do
    ~MOB"""
    <Column fill_width={true} padding_top={26}>
      {Kati.Screens.RestoreFirstRun.steps()}
      {Kati.Screens.RestoreFirstRun.heading_line("Bring your")}
      {Kati.Screens.RestoreFirstRun.heading_line("Kati back")}
      <Spacer size={12} />
      <Text
        text="Choose the file you saved. Sections, settings and everything you logged come with it — you can skip the rest of setup."
        text_size={14}
        line_height={1.6}
        text_color={Palette.ink_soft()}
      />
      <Spacer size={20} />
    </Column>
    """
  end

  @doc false
  def heading_line(line) do
    ~MOB"""
    <Text
      text={line}
      text_size={28}
      max_font_scale={1.6}
      font_weight="extrabold"
      letter_spacing={-0.035}
      line_height={1.15}
      text_color={:on_surface}
    />
    """
  end

  @doc """
  The five-bar meter, two filled — the design's own resting position for a
  branch offered mid-sequence. See the moduledoc for why this is not a call
  into `Kati.Screens.PickSections.step/1`.
  """
  @spec steps() :: term()
  def steps do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        {1..5
         |> Enum.map(fn i -> Kati.Screens.RestoreFirstRun.step(i <= 2) end)
         |> Enum.intersperse(Kati.Screens.RestoreFirstRun.step_gap())}
      </Row>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def step_gap, do: ~MOB"<Spacer size={5} />"

  @doc false
  def step(done?) do
    color = if done?, do: Palette.ink(), else: Palette.track_off()
    ~MOB"<Box weight={1.0} height={4} corner_radius={2} background={color} />"
  end

  # ── The file row ─────────────────────────────────────────────────────────────

  @doc """
  The single-row card offering the picked file — node for node
  `Kati.Screens.Restore.file_row/1`'s own build, on this screen's own tap.
  """
  @spec file_row(String.t()) :: term()
  def file_row(name) do
    row =
      SettingsList.row(
        SettingsList.icon_tile("upload_file"),
        SettingsList.body("Pick a file", name),
        SettingsList.chevron(),
        rule: false,
        on_tap: {self(), :pick_file}
      )

    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.card([row])}
      <Spacer size={11} />
    </Column>
    """
  end

  # ── The scan card ────────────────────────────────────────────────────────────

  @doc "The cream card offering a QR handoff from another phone."
  @spec scan_card() :: term()
  def scan_card do
    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Palette.cream()}
        corner_radius={20}
        padding={16}
        align="center"
        on_tap={{self(), :scan_qr}}
      >
        {Kati.Screens.RestoreFirstRun.scan_tile()}
        <Spacer size={14} />
        <Column weight={1.0}>
          <Text
            text="Scan from your old phone"
            text_size={13}
            font_weight="bold"
            text_color={Palette.cream_ink()}
            max_lines={1}
          />
          <Spacer size={5} />
          <Text
            text="Settings and plans only — a library needs the file."
            text_size={11.5}
            line_height={1.6}
            text_color={Palette.cream_sub()}
          />
        </Column>
      </Row>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc "The 70pt QR-shaped tile. See the moduledoc for why this is not `Kati.Screens.Restore.scan_tile/0`."
  @spec scan_tile() :: term()
  def scan_tile do
    rows =
      Kati.Screens.Restore.qr_pattern()
      |> Enum.map(fn row -> Kati.Screens.RestoreFirstRun.qr_row(row) end)
      |> Enum.intersperse(Kati.Screens.RestoreFirstRun.qr_gap())

    ~MOB"""
    <Box
      width={70}
      height={70}
      corner_radius={14}
      background={Palette.card()}
      shadow="0 6 16 -8 #7378501E"
      align="center"
    >
      <Column>
        {rows}
      </Column>
    </Box>
    """
  end

  @doc false
  def qr_gap, do: ~MOB"<Spacer size={2} />"

  @doc false
  def qr_row(row) do
    ~MOB"""
    <Row>
      {row
       |> String.graphemes()
       |> Enum.map(fn cell -> Kati.Screens.RestoreFirstRun.qr_module(cell) end)
       |> Enum.intersperse(Kati.Screens.RestoreFirstRun.qr_gap())}
    </Row>
    """
  end

  @doc false
  def qr_module("1"),
    do: ~MOB"<Box width={5.43} height={5.43} corner_radius={1} background={Palette.ink()} />"

  def qr_module(_off), do: ~MOB"<Box width={5.43} height={5.43} />"

  # ── The collapsed outcome card ───────────────────────────────────────────────

  @doc """
  The single DM Mono total beside a sentence naming what will not happen. See
  the moduledoc for why this replaces 129's three-count row on an empty
  device.
  """
  @spec outcome_card(map()) :: term()
  def outcome_card(r) do
    body = [text_size: 13, line_height: 1.6, text_color: Palette.ink_soft()]

    emphasis = [
      text_size: 13,
      line_height: 1.6,
      text_color: Palette.ink(),
      font_weight: "semibold"
    ]

    paragraph =
      UI.rich_text([
        {"#{r.noun}, and everything attached to them, will be restored. ", body},
        {"Nothing to merge and nothing to replace", emphasis},
        {" — there is nothing here yet.", body}
      ])

    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={17}
        align="center"
      >
        <Text
          text={r.count}
          font_family="mono"
          text_size={30}
          font_weight="medium"
          letter_spacing={-0.03}
          text_color={Palette.ink()}
          max_lines={1}
        />
        <Spacer size={14} />
        <Column weight={1.0}>
          {paragraph}
        </Column>
      </Row>
      <Spacer size={11} />
    </Column>
    """
  end

  # ── The commit and the way out ───────────────────────────────────────────────

  @doc "The single ink CTA — no icon, unlike `Kati.Screens.PickSections.commit/1`'s: `135.html` draws none."
  @spec cta_button() :: term()
  def cta_button do
    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        height={54}
        corner_radius={27}
        background={Palette.ink_fill()}
        shadow="0 14 28 -12 #801A1917"
        align="center"
        on_tap={{self(), :restore_everything}}
      >
        <Text
          text="Restore everything"
          text_size={14.5}
          font_weight="bold"
          text_color={Palette.on_ink()}
          max_lines={1}
        />
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc """
  The plain-text foot link `134.html` requires of every chromeless onboarding
  screen, plus the drawing's own "Set up fresh instead" beside it.
  """
  @spec footer() :: term()
  def footer do
    ~MOB"""
    <Row fill_width={true} align="center">
      <Row align="center" on_tap={{self(), :back_to_welcome}}>
        {UI.symbol("arrow_back", size: 17, color: Palette.sub())}
        <Spacer size={7} />
        <Text
          text="Back to welcome"
          text_size={13}
          font_weight="semibold"
          text_color={Palette.sub()}
          max_lines={1}
        />
      </Row>
      <Spacer weight={1.0} />
      <Row align="center" on_tap={{self(), :set_up_fresh}}>
        <Text
          text="Set up fresh instead"
          text_size={13}
          font_weight="semibold"
          text_color={Palette.sub()}
          max_lines={1}
        />
      </Row>
    </Row>
    """
  end
end
