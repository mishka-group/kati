defmodule Kati.Screens.NotificationAccess do
  @moduledoc """
  Screen 151 — Notification access, the one permission unlike every other,
  pushed under Auto-detect.

  Reached from screen 36's *This phone* row — the Sources card's permission
  row, which reads the same grant through `Kati.Media.Detect.access/0` — so a
  reader who taps it is told what the permission is before being sent to the
  system screen that grants it. Back returns to Auto-detect.

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
  action is `Open system settings`.

  ## One state, the phone's own

  Board 151 is a specimen sheet: it stacks all four states of this permission
  one above the other, each under an eyebrow that annotates the design
  (*purpose, then scope, then the action*; *different wording*), and its
  revoked card counts the board's own `128 tracks`. The screen draws exactly
  one of them — the one `status/0` reads — under a plain label naming the
  state:

    1. **Not granted** — `Kati.Media.Detect.access/0` answers `:denied` and
       nothing Kati ticked came from detection. Why Kati wants it, what it can
       see, `Open system settings`. The scope sentence is deliberately not
       softened: *every notification on the device, messages included* is
       Android's grant, and *Kati reads only media notifications and never
       stores anything else* is Kati's own promise about a grant that wide.
    2. **Turned off** — `:denied`, and `Kati.Media.Detect.detected_count/0` is
       above zero. A detected tick is only ever written while access is
       granted (see `Kati.Media.Detect.sweep/0` and `drain/0`), so a detected
       row in the store is the one record Kati keeps that the grant once
       existed. The card leads with what was kept — that real count, never
       the board's — because a reader who turned this off did not also ask
       Kati to forget what it already ticked. With no detected row the two
       states cannot be told apart, so the page does not pretend to know and
       draws the not-granted wording.
    3. **Granted** — the plain settings row every other permission's Allow
       becomes once it has been: a live badge and nothing else to press.
    4. **Not on this build** — `:unavailable`, a build with no native half (a
       host test, a non-Android build). Nothing here can ask for the grant, so
       the page draws the retired row `Kati.Screens.States` established for
       *drawn and not built* — dimmed rather than hidden, a `NOT IN V1` badge,
       and pressable into `Kati.Screens.RetiredTile`, whose
       `Notification access` subject says why.

  Detection ticks films and episodes rather than logging tracks, which is why
  the kept count is `Kati.Media.Watch` rows marked `detected` and is worded
  as things watched rather than as the board's *tracks*.

  The state is read in `load/1`, so it is the one the phone was in when the
  page opened. Returning from the system settings screen does not re-read it;
  going back to Auto-detect and tapping *This phone* again does.

  ## Bold runs, and the bridge gap every screen this round hits

  The scope sentence carries a bold clause inside a running paragraph.
  `Kati.UI.rich_text/1` concatenates every run into one `Text` and applies one
  style — the whole reason is in its own moduledoc — so the paragraph wraps
  correctly and the emphasis does not render.

  ## Where mishka-group/kati#103 costs the most

  A `rich_text/1` run is a msgid, and a run is a fragment of a sentence rather
  than a sentence. Persian puts its verb last and negates with a prefix fused
  to it, so a clause cut around an English bold word does not survive being
  translated a clause at a time. `scope_paragraph/0` and `not_folded_runs/0`
  each redistribute inside their own fragments rather than being merged into
  one msgid, and each documents its own move. The turned-off card's sentence
  is one msgid, because its number is interpolated and a count moved between
  fragments is a count a translator cannot place.

  ## `Palette.tile_grey/0` is a real third grey, not a rounding of `paper`

  The retired row's icon tile is filled `#F1EEE9` in the board — between
  `Palette.paper/0`'s `#EFECE7` and `Palette.card/0`'s `#FBFAF8`, and equal to
  neither. Forcing it onto the nearest token would move that token's meaning
  to match one drawing.

  ## Every control goes somewhere

  `Open system settings` (the not-granted button and the turned-off card's
  pill) opens the notification-listener list through
  `Kati.Native.Links.settings/1`, the `K-44 open-settings` fence; when that
  refuses, the refusal is drawn under the title with `Kati.UI.notice/1` rather
  than swallowed. `Log by hand instead` pushes `Kati.Screens.LogListen`, and
  the retired row pushes `Kati.Screens.RetiredTile`. See `handle_tap/2`.
  """

  use Kati.Screens.Pushed, back: "Auto-detect"
  use Gettext, backend: Kati.Gettext

  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList
  alias Kati.UI.Sheet

  @typedoc "Which of the four states the page draws, and how many detected ticks it keeps."
  @type status :: %{
          state: :not_granted | :revoked | :granted | :unavailable,
          kept: non_neg_integer()
        }

  @doc "Reads the grant and the detected-tick count once, on mount."
  @impl true
  def load(socket) do
    Mob.Socket.assign(socket, :access, Kati.Screens.NotificationAccess.status())
  end

  @doc """
  The phone's own state of this permission, from the grant and the store.

  See the moduledoc for why a detected tick is what tells *turned off* from
  *never granted*, and why nothing else can.
  """
  @spec status() :: status()
  def status do
    Kati.Screens.NotificationAccess.status(
      Kati.Media.Detect.access(),
      Kati.Media.Detect.detected_count()
    )
  end

  @doc """
  The state for one grant and one count.

      iex> Kati.Screens.NotificationAccess.status(:denied, 0)
      %{state: :not_granted, kept: 0}

      iex> Kati.Screens.NotificationAccess.status(:denied, 3)
      %{state: :revoked, kept: 3}

      iex> Kati.Screens.NotificationAccess.status(:granted, 3)
      %{state: :granted, kept: 3}

      iex> Kati.Screens.NotificationAccess.status(:unavailable, 0)
      %{state: :unavailable, kept: 0}
  """
  @spec status(:granted | :denied | :unavailable, non_neg_integer()) :: status()
  def status(:granted, kept), do: %{state: :granted, kept: kept}
  def status(:denied, kept) when kept > 0, do: %{state: :revoked, kept: kept}
  def status(:denied, _kept), do: %{state: :not_granted, kept: 0}
  def status(_unavailable, kept), do: %{state: :unavailable, kept: kept}

  @doc false
  def content(assigns) do
    access = Map.get(assigns, :access) || Kati.Screens.NotificationAccess.status()

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
        {SettingsList.title(gettext("Notification access"), gettext("THE ONE PERMISSION UNLIKE EVERY OTHER"))}
        {Kati.UI.notice(assigns[:link_error])}
        {UI.eyebrow(Kati.Screens.NotificationAccess.label(access.state))}
        {Kati.Screens.NotificationAccess.card(access)}
      </Column>
    </Scroll>
    """
  end

  @doc """
  The plain label above the card — the name of the state, and nothing about
  the design.

  Each takes the `"permission"` context `Kati.Screens.NotificationsHelp` and
  `Kati.Screens.Account` already use for a permission's state: one- and
  two-word msgids are the shape `mix gettext.merge` fuzzy-matches against the
  first longer entry that resembles them. `UI.eyebrow/1` upcases, which is a
  no-op on the Persian.
  """
  @spec label(atom()) :: String.t()
  def label(:not_granted), do: pgettext("permission", "Not granted")
  def label(:revoked), do: pgettext("permission", "Turned off")
  def label(:granted), do: pgettext("permission", "Granted")
  def label(:unavailable), do: pgettext("permission", "Not on this build")

  @doc "The one card for `status`'s state."
  @spec card(status()) :: map()
  def card(%{state: :not_granted}), do: Kati.Screens.NotificationAccess.not_granted()
  def card(%{state: :revoked, kept: kept}), do: Kati.Screens.NotificationAccess.revoked(kept)
  def card(%{state: :granted}), do: Kati.Screens.NotificationAccess.granted()
  def card(%{state: :unavailable}), do: Kati.Screens.NotificationAccess.retired()

  @doc """
  Not granted — purpose, then scope, then the one action there is.

  Two cards, not one: the `sensors` card is *why Kati wants it* and *what it
  can see*, one hairline apart the way a permission's reason and its blast
  radius are two different claims; the cream card underneath is `Sheet.insight/2`
  — reused rather than rebuilt, because a card that *asserts something rather
  than collects something* is exactly what that helper is documented for.

  *Why Kati wants it* names no kind of app: `Kati.Media.Detect` reads every
  media session on the phone, and the board's *music apps* and *every track*
  described a detector Kati does not have.

  The closing caption asks for `Kati.Locale.mono_face/0` rather than naming
  `"mono"`: it is a msgid, so under `:fa` it arrives as Persian, and
  `kati_mono.ttf` carries no Arabic-script glyph.
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
              text={gettext("Why Kati wants it")}
              text_size={14}
              font_weight="bold"
              letter_spacing={Kati.Locale.tracking(-0.015)}
              text_color={:on_surface}
            />
            <Spacer size={6} />
            <Text
              text={gettext("To see what your apps are playing, so you do not have to log everything by hand.")}
              text_size={12.5}
              line_height={Kati.Locale.leading(1.65)}
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
          text={gettext("SPECIAL ACCESS · NO DIALOG TO RAISE")}
          font_family={Kati.Locale.mono_face()}
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
  the same weight as the lead-in, because the board bolds both.

  ## The spaces moved out of the msgids, and one clause moved inside one

  A run's leading and trailing space is concatenation rather than copy, so it
  sits at the call site. The harder half is that **Persian puts the verb
  last** and this sentence's verb is in the middle, before the bolded clause.
  So the Persian of `Android grants this as access to` is a colon construction
  — *اندروید این اجازه را این‌طور می‌دهد: دسترسی به* — which carries its own
  verb and hands the bolded clause over intact.
  """
  @spec scope_paragraph() :: map()
  def scope_paragraph do
    body = [
      text_size: 12.5,
      line_height: Kati.Locale.leading(1.65),
      text_color: Palette.ink_soft()
    ]

    strong = [font_weight: "semibold", text_color: Palette.ink()]

    UI.rich_text([
      {gettext("What it can see.") <> " ", strong},
      {gettext("Android grants this as access to") <> " ", body},
      {gettext("every notification on the device, messages included"), strong},
      {". " <> gettext("Kati reads only media notifications and never stores anything else."),
       body ++ [base: true]}
    ])
  end

  @doc """
  The runs for the cream card's claim: this permission does not live in the
  ordinary Notifications row under *This device* (screen 40).

  ## `not` is a bolded word, and Persian has no bolded word to put there

  Persian negates with a prefix fused to a verb at the end of the clause —
  *گنجانده نمی‌شود* — so there is no separable *not* for this run to hold. The
  Persian of that run is **هرگز**, the emphatic negator, which sits exactly
  where the board puts the bold and leaves the grammatical negation to the
  verb in the run after it.

  Both short runs take `pgettext/2`: `"It is"` and `"not"` are the two- and
  one-word msgids `mix gettext.merge` fuzzy-matches against the first longer
  string that resembles them.

  The board names the row by its board number, *on 40*, which a reader has no
  way to read; the screen names it by the title screen 40 draws.
  """
  @spec not_folded_runs() :: [{String.t(), keyword()}]
  def not_folded_runs do
    body = [
      text_size: 12.5,
      line_height: Kati.Locale.leading(1.65),
      text_color: Palette.cream_body()
    ]

    strong = [font_weight: "semibold", text_color: Palette.ink()]

    [
      {pgettext("notification access, the cream card", "It is") <> " ", body},
      {pgettext("notification access, the cream card", "not"), strong},
      {" " <>
         gettext(
           "folded into the ordinary Notifications row under This device. A permission that can read every message in a person’s life does not belong in a list next to “show me notifications”."
         ), body ++ [base: true]}
    ]
  end

  @doc """
  The one action the not-granted card offers — not an Allow button, because
  there is nothing to raise. Full-width and ink-filled the way
  `Sheet.commit/2` ends a sheet, with an icon this board's button carries.
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
        text={gettext("Open system settings")}
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
  Turned off — reads differently from never-granted, and leads with what was
  kept. `notifications_off` in `gold_icon` rather than `ink_soft`, because
  this card is a warning about a setting a user changed, not a neutral
  explainer.
  """
  @spec revoked(non_neg_integer()) :: map()
  def revoked(kept) do
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
              text={gettext("Turned off in system settings")}
              text_size={13.5}
              font_weight="bold"
              text_color={:on_surface}
            />
            <Spacer size={6} />
            <Text
              text={Kati.Screens.NotificationAccess.revoked_line(kept)}
              text_size={12.5}
              line_height={Kati.Locale.leading(1.65)}
              text_color={Palette.ink_soft()}
            />
          </Column>
        </Row>
        <Spacer size={14} />
        <Row align="center">
          <Column on_tap={{self(), :open_settings_revoked}}>
            {SettingsList.action_pill(gettext("Open system settings"))}
          </Column>
          <Spacer size={8} />
          <Column on_tap={{self(), :log_by_hand}}>
            {SettingsList.action_pill(gettext("Log by hand instead"))}
          </Column>
        </Row>
      </Column>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc """
  What was kept, then what stopped — the real count of ticks detection made,
  and no count at all when there are none.

  One `ngettext/4` sentence rather than the board's four bolded fragments:
  the count is interpolated, and Persian's verb-last order would otherwise
  have to carry it across a fragment boundary. Persian does not inflect a
  noun after a numeral, which is why its two forms differ only in the
  closing pronoun.

      iex> Kati.Screens.NotificationAccess.revoked_line(0)
      "Nothing new is detected until it is turned back on."

      iex> Kati.Screens.NotificationAccess.revoked_line(3)
      "While it was on, Kati ticked 3 things you watched, and it keeps all of them. Nothing new is detected until it is turned back on."
  """
  @spec revoked_line(non_neg_integer()) :: String.t()
  def revoked_line(0), do: gettext("Nothing new is detected until it is turned back on.")

  def revoked_line(kept) do
    ngettext(
      "While it was on, Kati ticked %{n} thing you watched, and it keeps it.",
      "While it was on, Kati ticked %{n} things you watched, and it keeps all of them.",
      kept,
      n: Kati.Locale.number(kept)
    ) <> " " <> gettext("Nothing new is detected until it is turned back on.")
  end

  @doc """
  Granted — the plain row every other permission's Allow becomes, once it has
  been. One row, so `rule: false`.

  ## *Live* is the third thing in this app called Live and takes a context

  `Kati.Screens.AutoDetect`'s now-playing pill is **در حال پخش** and
  `Kati.Screens.Sync`'s account pill is **به‌روز**, and neither is what this one
  means: here the permission itself is switched on and listening, which is
  **فعال**.
  """
  @spec granted() :: map()
  def granted do
    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.card([
        SettingsList.row(
          SettingsList.icon_tile("sensors"),
          SettingsList.body(gettext("Notification access"), gettext("On · media notifications only")),
          SettingsList.status_pill(
            pgettext("notification access status pill", "Live"),
            Palette.green_text(),
            Palette.green_wash()
          ),
          rule: false
        )
      ])}
      <Spacer size={20} />
    </Column>
    """
  end

  @doc """
  Not on this build — the retired treatment `Kati.Screens.States` already
  drew, for a build with nothing that can ask for this grant. The tap lands on
  `Kati.Screens.RetiredTile`'s `Notification access` subject.

  Trailing is passed bare, not pre-wrapped in `SettingsList.trailing/1` —
  `row/4` applies that itself.
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
      %{variant: :filled, color: Palette.tile_grey(), size: 30, radius: 9},
      [UI.symbol("sensors", size: 17, color: Palette.rail_idle())]
    )
  end

  @doc false
  def retired_body do
    ~MOB"""
    <Column fill_width={true}>
      <Text
        text={gettext("Notification access")}
        text_size={13.5}
        font_weight="semibold"
        text_color={Palette.tertiary()}
        max_lines={1}
      />
      <Spacer size={3} />
      <Text
        text={gettext("Not set up — tap to see why")}
        text_size={11.5}
        text_color={Palette.rail_idle()}
        max_lines={1}
      />
    </Column>
    """
  end

  @doc """
  The badge, in the recipe `Kati.Screens.DataSources.not_in_v1/0` already
  settled for the same token on the same treatment.

  The msgid is sentence case and `Kati.UI.eyebrow_label/1` does the shouting,
  because `String.upcase/1` is a Latin operation and the Persian — **در نسخه ۱
  نیست** — has no case to raise. The tracking goes through
  `Kati.Locale.tracking/1` because `.06em` is a Latin small-caps effect that
  pulls Persian letters out of their joins.
  """
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
        text={UI.eyebrow_label(gettext("Not in v1"))}
        font_family={Kati.Locale.mono_face()}
        text_size={9}
        letter_spacing={Kati.Locale.tracking(0.06)}
        text_color={Palette.sub()}
        max_lines={1}
      />
    </Row>
    """
  end

  @doc """
  `:open_retired` pushes `Kati.Screens.RetiredTile` with the
  `"Notification access"` subject. That string is a **key, not copy**:
  `Kati.Screens.RetiredTile.subject/1` matches it untranslated, and the name
  the sheet draws comes from its own gettext call.

  `:log_by_hand` goes to `Kati.Screens.LogListen`: this page gates
  *auto*-detecting, so the alternative it offers is logging by hand.

  Both `Open system settings` taps open the system notification-listener
  list, and a refusal — no bridge, or a phone that will not open it — is
  assigned to `:link_error` and drawn under the title, the way
  `Kati.Screens.NotificationsHelp` draws its own settings taps' refusals.
  Kati cannot grant the access and does not try.
  """
  @impl true
  @spec handle_tap(atom(), Mob.Socket.t()) :: {:noreply, Mob.Socket.t()}
  def handle_tap(:open_retired, socket) do
    {:noreply,
     Mob.Socket.push_screen(socket, Kati.Screens.RetiredTile, %{section: "Notification access"})}
  end

  def handle_tap(:log_by_hand, socket) do
    {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.LogListen)}
  end

  def handle_tap(tag, socket) when tag in [:open_settings, :open_settings_revoked] do
    {:noreply, Kati.Screens.NotificationAccess.open_listener_settings(socket)}
  end

  def handle_tap(_tag, socket), do: {:noreply, socket}

  @doc false
  @spec open_listener_settings(Mob.Socket.t()) :: Mob.Socket.t()
  def open_listener_settings(socket) do
    case Kati.Native.Links.settings(:notification_listener) do
      :ok -> Mob.Socket.assign(socket, :link_error, nil)
      {:error, why} -> Mob.Socket.assign(socket, :link_error, Kati.Native.Links.message(why))
    end
  end
end
