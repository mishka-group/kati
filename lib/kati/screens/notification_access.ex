defmodule Kati.Screens.NotificationAccess do
  @moduledoc """
  Screen 151 — Notification access, a reference sheet for the one permission
  unlike every other, pushed under Auto-detect.

  ## Why this cannot be screen 40's Notifications row with an extra line

  Every other permission in the app is a runtime dialog: Android raises it,
  the user taps a button, `Kati.Permissions` records the answer. Notification
  access has no dialog to raise. `NotificationListenerService` is *special
  access* — Android's own name for the handful of permissions granted only
  from a system settings screen — and it is special for a reason worth being
  blunt about: granting it hands an app **every notification on the device,
  messages included**, not just the ones from the apps a user meant to allow.
  A permission that can read a person's texts does not belong in a list next
  to "show me notifications", so it is not folded into 40's row and it does
  not get an Allow button, because there is nothing for Allow to do. The one
  action is `Open system settings`, and this sheet draws that fact rather
  than a shortened version of it.

  ## Four states, drawn once, exactly as `Kati.Screens.States` draws its own

  This is a *reference sheet*, in the same sense screen 27 is: a static
  specimen of every state one control can be in, stacked and labelled, rather
  than one screen that renders whichever state the phone happens to be in
  today. `Kati.Permissions` has a real `:notification_access` status the
  moment #26 lands and a live screen wants one; today the board asks for all
  four states side by side and that is what a specimen screen answers, not
  four `if` branches lucky enough to agree with what is on this phone during
  a screenshot.

  The four, in the board's own order — purpose, then scope, then the one
  action, is fixed and does not reorder by state:

    1. **Not granted.** Why Kati wants it, what it can see, `Open system
       settings`. The scope sentence is deliberately not softened: *every
       notification on the device, messages included* is Android's grant, and
       *Kati reads only media notifications and never stores anything else*
       is Kati's own promise about what it does with a grant that wide.
    2. **Revoked after being granted.** Different wording on purpose — it
       leads with what was kept (128 tracks, still on the phone) rather than
       with what stopped, because a user who turned this off did not also ask
       Kati to forget what it already logged.
    3. **Granted.** The plain settings row every other permission's Allow
       becomes once it has been — a live badge and nothing else to press.
    4. **What actually ships.** See below.

  ## The fourth state is not a fourth design — it is what state 3 becomes

  Play Protect blocks a sideloaded APK that declares
  `NOTIFICATION_LISTENER`, and Kati installs directly rather than through a
  store listing that could apply for the review exemption. So states 1–3 are
  the **design record** — correct, and correctly not reachable on this build
  — and the row that ships wears the retired treatment `Kati.Screens.States`
  already established for exactly this situation: dimmed rather than hidden,
  carrying a `NOT IN V1` badge, and pressable into `Kati.Screens.RetiredTile`
  so the tap answers *why* rather than doing nothing. `retired_row/0` reuses
  that tile's own numbers — 30pt paper-adjacent tile, `tertiary` title,
  `rail_idle` sub-line — because the shape of *drawn and not built* is one
  shape app-wide, not a second one invented for this permission.

  `Kati.Screens.RetiredTile.subject/1` has no entry keyed for this row, so the
  push falls back to its drawn subject the same way `Kati.Screens.States`
  falls back for every one of *its* six example tiles — see that screen's own
  `retired/1` doc. The half a static picture cannot show is *that tapping it
  goes somewhere*, and it does; the sheet's copy being about Sleep rather than
  about notification listeners is `Kati.Screens.RetiredTile`'s subject map to
  extend, not this screen's to fork.

  ## Two paragraphs lose their bold, and it is the same bridge gap every screen this round hits

  The scope sentence in state 1 and the kept-tracks sentence in state 2 each
  carry a bold clause inside a running paragraph. `Kati.UI.rich_text/1`
  concatenates every run into one `Text` and applies one style — the whole
  reason is in its own moduledoc — so both paragraphs wrap correctly and
  neither emphasis renders. The footnote's two bold terms
  (`NOTIFICATION_LISTENER`, *design record*) are lost the same way one level
  further down: `SettingsList.note/2` takes a plain string, not runs, so that
  paragraph goes in as one already-flattened sentence rather than through
  `rich_text/1` at all.

  ## `0xFFF1EEE9` is a real third grey, not a rounding of `paper`

  The retired row's icon tile is filled `#F1EEE9` in the board — between
  `Palette.paper/0`'s `#EFECE7` and `Palette.card/0`'s `#FBFAF8`, and equal to
  neither. `Kati.Screens.States` hits the same literal for its skeleton
  shimmer and leaves it unnamed for the same reason: forcing it onto the
  nearest token would move that token's meaning to match one drawing, and the
  three greys are doing three different jobs on this board.

  ## Two actions with nowhere to go, and one line documents why for both

  `Open system settings` (drawn twice — the state-1 button and the state-2
  pill) and `Log by hand instead` all name a destination this build cannot
  reach yet: nothing in `native/LEDGER.md` launches an Android settings
  intent, the same gap #26's diagnostic states outright, and *log by hand* is
  `Kati.Screens.LogListen`, a sheet that opens over a specific album rather
  than from a bare permissions screen with no album in hand. Wiring either
  would be a button that lies about what pressing it does, which
  `Kati.Screens.NotificationsHelp` argues at length is worse than a button
  that admits it has nowhere to go yet. Drawn, reachable, honest about
  waiting — the same treatment that screen gives its own settings taps.
  """

  use Kati.Screens.Pushed, back: "Auto-detect"

  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList
  alias Kati.UI.Sheet

  @doc false
  def content(_assigns) do
    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {SettingsList.chrome(nil, 44)}
        {SettingsList.title("Notification access", "THE ONE PERMISSION UNLIKE EVERY OTHER")}
        {UI.eyebrow("Not granted — purpose, then scope, then the action")}
        {Kati.Screens.NotificationAccess.not_granted()}
        {SettingsList.eyebrow_muted("Revoked after being granted — different wording")}
        {Kati.Screens.NotificationAccess.revoked()}
        {SettingsList.eyebrow_muted("Granted")}
        {Kati.Screens.NotificationAccess.granted()}
        {SettingsList.eyebrow_muted("What actually ships — retired")}
        {Kati.Screens.NotificationAccess.retired()}
        {Kati.Screens.NotificationAccess.footnote()}
      </Column>
    </Scroll>
    """
  end

  @doc """
  State 1 — purpose, then scope, then the one action there is.

  Two cards, not one: the `sensors` card is *why Kati wants it* and *what it
  can see*, one hairline apart the way a permission's reason and its blast
  radius are two different claims; the cream card underneath is `Sheet.insight/2`
  — reused rather than rebuilt, because a card that *asserts something rather
  than collects something* is exactly what that helper is documented for, and
  this is the one place on the board that asserts a policy decision (this
  permission does not live in the ordinary Notifications row) rather than
  describing a state.
  """
  @spec not_granted() :: map()
  def not_granted do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={17}
      >
        <Row fill_width={true} align="top">
          {Kati.Screens.NotificationAccess.why_tile()}
          <Spacer size={12} />
          <Column weight={1.0}>
            <Text
              text="Why Kati wants it"
              text_size={14}
              font_weight="bold"
              letter_spacing={-0.015}
              text_color={:on_surface}
            />
            <Spacer size={6} />
            <Text
              text="To see what your music apps are playing, so you do not have to log every track by hand."
              text_size={12.5}
              line_height={1.65}
              text_color={Palette.ink_soft()}
            />
          </Column>
        </Row>
        <Spacer size={14} />
        {SettingsList.hairline(true)}
        <Spacer size={14} />
        {Kati.Screens.NotificationAccess.scope_paragraph()}
        <Spacer size={15} />
        {Kati.Screens.NotificationAccess.open_settings_button()}
        <Spacer size={11} />
        <Text
          text="SPECIAL ACCESS · NO DIALOG TO RAISE"
          font_family="mono"
          text_size={10.5}
          text_color={Palette.muted()}
          text_align="center"
        />
      </Column>
      <Spacer size={14} />
      {Sheet.insight("lock", Kati.Screens.NotificationAccess.not_folded_runs())}
      <Spacer size={20} />
    </Column>
    """
  end

  @doc false
  def why_tile do
    Kati.Components.MishkaThemeIcon.theme_icon(
      %{variant: :filled, color: Palette.paper(), size: 36, radius: 12},
      [UI.symbol("sensors", size: 19, color: Palette.ink_soft())]
    )
  end

  @doc """
  *What it can see.* — the sentence with the widest blast radius on the page.

  `strong` marks Android's own grant (every notification, messages included)
  the same weight as the lead-in, because the board bolds both: what Kati is
  handed and that Kati is handed something wide are the same claim in two
  clauses. See the moduledoc for why the bold does not survive `rich_text/1`.
  """
  @spec scope_paragraph() :: map()
  def scope_paragraph do
    body = [text_size: 12.5, line_height: 1.65, text_color: Palette.ink_soft()]
    strong = [font_weight: "semibold", text_color: Palette.ink()]

    UI.rich_text([
      {"What it can see.", strong},
      {" Android grants this as access to ", body},
      {"every notification on the device, messages included", strong},
      {". Kati reads only media notifications and never stores anything else.",
       body ++ [base: true]}
    ])
  end

  @doc "The runs for the cream card's claim: this permission does not live in 40's list."
  @spec not_folded_runs() :: [{String.t(), keyword()}]
  def not_folded_runs do
    body = [text_size: 12.5, line_height: 1.65, text_color: Palette.cream_body()]
    strong = [font_weight: "semibold", text_color: Palette.ink()]

    [
      {"It is ", body},
      {"not", strong},
      {" folded into the ordinary Notifications row on 40. A permission that can read every message in a person’s life does not belong in a list next to “show me notifications”.",
       body ++ [base: true]}
    ]
  end

  @doc """
  The one action state 1 offers — not an Allow button, because there is
  nothing to raise. Full-width and ink-filled the way `Sheet.commit/2` ends a
  sheet, with an icon this board's button carries and that one does not.
  """
  @spec open_settings_button() :: map()
  def open_settings_button do
    ~MOB"""
    <Row
      fill_width={true}
      height={44}
      corner_radius={22}
      background={Palette.ink_fill()}
      align="center"
      on_tap={{self(), :open_settings}}
    >
      <Spacer weight={1.0} />
      {UI.symbol("settings", size: 17, color: Palette.on_ink())}
      <Spacer size={8} />
      <Text
        text="Open system settings"
        text_size={12.5}
        font_weight="bold"
        text_color={Palette.on_ink()}
        max_lines={1}
      />
      <Spacer weight={1.0} />
    </Row>
    """
  end

  @doc """
  State 2 — revoked reads differently from never-granted, and leads with what
  was kept. `notifications_off` in `gold_icon` rather than `ink_soft`,
  because this card is a warning about a setting a user changed, not a
  neutral explainer.
  """
  @spec revoked() :: map()
  def revoked do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={17}
      >
        <Row fill_width={true} align="top">
          {UI.symbol("notifications_off", size: 19, color: Palette.gold_icon())}
          <Spacer size={11} />
          <Column weight={1.0}>
            <Text
              text="Turned off in system settings"
              text_size={13.5}
              font_weight="bold"
              text_color={:on_surface}
            />
            <Spacer size={6} />
            {Kati.Screens.NotificationAccess.revoked_paragraph()}
          </Column>
        </Row>
        <Spacer size={14} />
        <Row align="center">
          <Column on_tap={{self(), :open_settings}}>
            {SettingsList.action_pill("Open system settings")}
          </Column>
          <Spacer size={8} />
          <Column on_tap={{self(), :log_by_hand}}>
            {SettingsList.action_pill("Log by hand instead")}
          </Column>
        </Row>
      </Column>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc "What was kept, then what stopped — in that order, per the moduledoc."
  @spec revoked_paragraph() :: map()
  def revoked_paragraph do
    body = [text_size: 12.5, line_height: 1.65, text_color: Palette.ink_soft()]
    strong = [font_weight: "semibold", text_color: Palette.ink()]

    UI.rich_text([
      {"Kati logged ", body},
      {"128 tracks", strong},
      {" while it was on and ", body},
      {"keeps all of them", strong},
      {". Nothing new is detected until it is turned back on.", body ++ [base: true]}
    ])
  end

  @doc """
  State 3 — the plain row every other permission's Allow becomes, once it has
  been. One row, so `rule: false` — there is nothing under it to rule off
  from.
  """
  @spec granted() :: map()
  def granted do
    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.card([
        SettingsList.row(
          SettingsList.icon_tile("sensors"),
          SettingsList.body("Notification access", "On · media notifications only"),
          SettingsList.status_pill("Live", Palette.green_text(), Palette.green_wash()),
          rule: false
        )
      ])}
      <Spacer size={20} />
    </Column>
    """
  end

  @doc """
  State 4 — what actually ships. `Kati.Screens.States` already drew this
  treatment for its own six examples; this row is that treatment for one
  named permission instead of a specimen list, and the tap lands on the same
  `Kati.Screens.RetiredTile` for the same reason — see the moduledoc.

  Trailing is passed bare, not pre-wrapped in `SettingsList.trailing/1` —
  `row/4` applies that itself, and `RetiredTile`'s own moduledoc records what
  handing it an already-wrapped node costs.
  """
  @spec retired() :: map()
  def retired do
    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.card([
        SettingsList.row(
          Kati.Screens.NotificationAccess.retired_icon_tile(),
          Kati.Screens.NotificationAccess.retired_body(),
          Kati.Screens.NotificationAccess.not_in_v1_badge(),
          rule: false,
          on_tap: {self(), :open_retired}
        )
      ])}
      <Spacer size={14} />
    </Column>
    """
  end

  @doc false
  def retired_icon_tile do
    Kati.Components.MishkaThemeIcon.theme_icon(
      # LEFT AS A LITERAL — see the moduledoc. `0xFFF1EEE9` sits between
      # `paper` (`0xFFEFECE7`) and `card` (`0xFFFBFAF8`) and is neither; the
      # retired tile is the one surface on this board that is deliberately a
      # third, in-between grey.
      %{variant: :filled, color: Palette.tile_grey(), size: 30, radius: 9},
      [UI.symbol("sensors", size: 17, color: Palette.rail_idle())]
    )
  end

  @doc false
  def retired_body do
    ~MOB"""
    <Column fill_width={true}>
      <Text
        text="Notification access"
        text_size={13.5}
        font_weight="semibold"
        text_color={Palette.tertiary()}
        max_lines={1}
      />
      <Spacer size={3} />
      <Text
        text="Not set up — tap to see why"
        text_size={11.5}
        text_color={Palette.rail_idle()}
        max_lines={1}
      />
    </Column>
    """
  end

  @doc false
  def not_in_v1_badge do
    ~MOB"""
    <Row
      height={22}
      corner_radius={11}
      background={Palette.paper()}
      padding_left={8}
      padding_right={8}
      align="center"
    >
      <Text
        text="NOT IN V1"
        font_family="mono"
        text_size={9}
        letter_spacing={0.06}
        text_color={Palette.sub()}
        max_lines={1}
      />
    </Row>
    """
  end

  @doc "The closing footnote: why the shipped app never shows states 1–3 at all."
  @spec footnote() :: map()
  def footnote do
    SettingsList.note(
      "info",
      "Play Protect blocks sideloaded APKs declaring NOTIFICATION_LISTENER, and Kati installs directly. So the three states above are the design record, and the live row wears 114’s retired treatment — it keeps its place and explains itself rather than vanishing."
    )
  end

  @doc """
  `:open_retired` is the one tap on this board with somewhere real to go —
  see the moduledoc for why it falls back to `RetiredTile`'s drawn subject
  rather than a subject keyed for this permission.

  `:log_by_hand` goes to `Kati.Screens.LogListen`. That is not a consolation
  prize: this sheet gates *auto*-detecting a listen, so the alternative it
  offers is the same hand-logging screen `Kati.Screens.AlbumDetail` pushes for
  `Log a listen`. One way in, whichever way you arrived.

  Both `Open system settings` taps answer with the screen unchanged. Reaching
  the system notification-listener settings needs an Android intent no build
  has yet, and `Kati.Screens.NotificationsHelp` leaves `:open_battery` in the
  same honest state for the same reason. Drawn, reachable, and waiting on the
  intent rather than pretending to have it.
  """
  @spec handle_tap(atom(), Mob.Socket.t()) :: {:noreply, Mob.Socket.t()}
  def handle_tap(:open_retired, socket) do
    {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.RetiredTile, %{section: "Sleep"})}
  end

  def handle_tap(:log_by_hand, socket) do
    {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.LogListen)}
  end

  def handle_tap(_tag, socket), do: {:noreply, socket}
end
