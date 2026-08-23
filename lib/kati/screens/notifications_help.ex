defmodule Kati.Screens.NotificationsHelp do
  @moduledoc """
  Why am I not getting notifications? — the diagnostic (#26).

  ## Five things Kati cannot control, and three of them fail silently

  Issue #26 states the problem precisely and this screen is the answer to it.
  Kati's notification behaviour depends on:

    1. **`POST_NOTIFICATIONS`.** Denied, `MobNotify.schedule/2` still arms the
       alarm and the receiver still calls `notify(...)` — it simply does not
       display, and **no error is reported anywhere**.
    2. **`SCHEDULE_EXACT_ALARM`.** Denied, Mob falls back to
       `setAndAllowWhileIdle`: inexact, batched, potentially an hour late.
       Acceptable for *new episode*, not for *your show starts now*.
    3. **Reboot.** `MobNotifyBootReceiver` re-arms what is pending and
       deliberately drops past-due entries, so a reminder that was due while
       the phone was off is gone with no trace.
    4. **Battery optimisation.** On Xiaomi, Huawei and OPPO this kills
       background work in ways an app cannot detect directly. Kati links to the
       system screen rather than requesting the exemption, because
       `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` carries Play-policy risk.
    5. **Budgets.** Android throws at 500 alarms per UID and iOS silently keeps
       only the soonest 64. `Kati.Notifications.Budget` divides that ceiling
       between six domains so the truncation is a decision rather than a
       discovery on somebody's phone.

  ## An app that is deliberately quiet has to prove it is quiet on purpose

  That is the whole reason this screen exists rather than a FAQ entry. Kati's
  notification manners — push off by default, an inbox badge instead, quiet
  hours, a weekly digest, stop after two skips — are a competitive asset and
  are indistinguishable from a bug unless something can say *this is what I
  decided, and here is what the phone decided.*

  So the page is in two halves and they are labelled as such: **what Kati
  decided** and **what the phone decided**. Nothing on it is a developer
  console — every row is a state with a plain sentence and, where there is one,
  a way to fix it.

  ## Every glyph on this page is already in Kati's subset

  `Kati.Icons` is generated from the drawings, and this screen has none — so a
  row wanting `alarm`, `battery_saver` or `restart_alt` would mean regenerating
  the font subset for a screen the design has not drawn. `schedule`, `bolt` and
  `timer` say the same three things and are already there. When #26 gains an
  artboard, the glyphs it asks for arrive with it.

  ## Reached from four places

  The inbox's Manners group, screen 25's *How loudly*, screen 51's manners rows
  and screen 40's Notifications permission row. Somebody asking this question is
  looking at one of those four when they ask it.

  ## Not drawn

  #26 is a **design** ticket with no artboard yet — it names the components to
  build it from and this screen uses exactly those: settings rows with status
  values, the info footnote in a tinted card, and screen 40's Allow-button
  treatment for a permission that has not been asked for. `Kati.Screens.Gallery`
  carries it on the undrawn list for that reason.
  """

  use Kati.Screens.Pushed, back: "Settings"

  alias Kati.Notifications.Inbox
  alias Kati.Notifications.Plan
  alias Kati.Permissions
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  def load(socket) do
    socket
    |> Mob.Socket.assign(:notifications, Permissions.status(:notifications))
    |> Mob.Socket.assign(:alarms, Permissions.status(:exact_alarms))
    |> Mob.Socket.assign(:plan, Kati.Screens.InboxNotifications.plan())
  end

  @doc false
  def content(assigns) do
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
        {SettingsList.title("Why am I not getting these?", "FIVE THINGS, THREE OF THEM SILENT")}
        {UI.eyebrow("What Kati decided")}
        {Kati.Screens.NotificationsHelp.kati_group(assigns.plan)}
        {UI.eyebrow("What the phone decided", dash: Palette.bronze())}
        {Kati.Screens.NotificationsHelp.phone_group(assigns)}
        {Kati.Screens.NotificationsHelp.budget_note(assigns.plan)}
        {Kati.Screens.NotificationsHelp.closing()}
      </Column>
    </Scroll>
    """
  end

  @doc """
  The half Kati is responsible for.

  Listed first, deliberately. The commonest true answer to *why am I not
  getting notifications* in this app is **because you did not turn any on**,
  and a page that opened with permissions would be teaching the user to blame
  the phone for a setting.
  """
  @spec kati_group(Plan.t()) :: map()
  def kati_group(plan) do
    groups = Inbox.groups(plan)

    rows = [
      SettingsList.row(
        SettingsList.icon_tile("notifications"),
        SettingsList.body(
          "Push is off until you ask",
          "Kati shows a badge on the bell instead. Nothing here is broken by that."
        ),
        SettingsList.trailing(Kati.Screens.NotificationsHelp.status("By design", :neutral))
      ),
      SettingsList.row(
        SettingsList.icon_tile("bedtime"),
        SettingsList.body(
          "Quiet hours 23:00 – 08:00",
          "A reminder inside them moves to the morning. It is never dropped."
        ),
        SettingsList.trailing(Kati.Screens.NotificationsHelp.status("Shifting", :neutral))
      ),
      SettingsList.row(
        SettingsList.icon_tile("inbox"),
        SettingsList.body(
          "Held back right now",
          Kati.Screens.NotificationsHelp.held_line(groups.held)
        ),
        SettingsList.trailing(SettingsList.chevron()),
        on_tap: {self(), :open_inbox}
      )
    ]

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.card(rows)}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc "How many are held back, and by what — or that nothing is."
  @spec held_line([Kati.Notifications.Candidate.t()]) :: String.t()
  def held_line([]), do: "Nothing is being held back"

  def held_line(held) do
    reasons =
      held
      |> Enum.map(& &1.suppressed)
      |> Enum.uniq()
      |> Enum.map_join(", ", fn reason -> reason |> Inbox.held_reason() |> String.downcase() end)

    "#{length(held)} held — #{reasons}"
  end

  @doc """
  The half the phone owns, each row with a way to fix it where one exists.

  `Kati.Permissions.affordance/1` decides which: `:allow` offers a button that
  raises the system dialog, `:settings` offers the system settings page because
  Android will not re-prompt, and `:none` means there is nothing to press. That
  distinction is the whole reason `Kati.Permissions` exists — an Allow button
  that silently does nothing is worse than no button.
  """
  @spec phone_group(map()) :: map()
  def phone_group(assigns) do
    rows = [
      Kati.Screens.NotificationsHelp.permission_row(
        "notifications",
        "Showing notifications",
        "Denied, Kati still arms the alarm and the phone never displays it. Nothing reports the failure.",
        assigns.notifications
      ),
      Kati.Screens.NotificationsHelp.permission_row(
        "schedule",
        "Exact alarms",
        "Without this a reminder is batched — right for “new episode”, wrong for “starts now”.",
        assigns.alarms
      ),
      SettingsList.row(
        SettingsList.icon_tile("bolt"),
        SettingsList.body(
          "Battery optimisation",
          "Some phones stop background work in ways an app cannot detect. If reminders are late or missing, this is the first place to look."
        ),
        SettingsList.trailing(SettingsList.action_pill("Open settings")),
        on_tap: {self(), :open_battery}
      ),
      SettingsList.row(
        SettingsList.icon_tile("timer"),
        SettingsList.body(
          "After a restart",
          "Kati re-arms everything still due. Anything that was due while the phone was off is gone — it cannot be delivered late."
        ),
        SettingsList.trailing(Kati.Screens.NotificationsHelp.status("Re-armed", :good))
      )
    ]

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.card(rows)}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def permission_row(icon, title, why, state) do
    SettingsList.row(
      SettingsList.icon_tile(icon),
      SettingsList.body(title, why),
      SettingsList.trailing(Kati.Screens.NotificationsHelp.permission_trailing(state)),
      on_tap: Kati.Screens.NotificationsHelp.permission_tap(state)
    )
  end

  @doc """
  What a permission row offers, by state.

  Four states and three answers: granted says so and offers nothing, unasked
  offers Allow, and both denied states offer the system settings page — because
  once Android has been told no, `request/2` will not prompt again and a button
  that claims it will is a lie.
  """
  @spec permission_trailing(atom()) :: map()
  def permission_trailing(:granted), do: status("On", :good)

  def permission_trailing(state) do
    case Permissions.affordance(state) do
      :allow -> SettingsList.action_pill("Allow")
      :settings -> SettingsList.action_pill("Open settings")
      :none -> status("Off", :bad)
    end
  end

  @doc false
  def permission_tap(:granted), do: nil

  def permission_tap(state) do
    case Permissions.affordance(state) do
      :allow -> {self(), :ask}
      :settings -> {self(), :open_settings}
      :none -> nil
    end
  end

  @doc """
  A status value, in the three tones this page uses.

  Green for a thing that is working, bronze for a thing that is off, and
  tertiary for a decision Kati made — which is neither good nor bad and must
  not be coloured as though it were.
  """
  @spec status(String.t(), :good | :bad | :neutral) :: map()
  def status(label, tone) do
    colour =
      case tone do
        :good -> Palette.green_text()
        :bad -> Palette.gold_text()
        :neutral -> Palette.sub()
      end

    assigns = %{label: label, colour: colour}

    ~MOB"""
    <Text text={@label} font_family="mono" text_size={11.5} text_color={@colour} max_lines={1} />
    """
  end

  @doc """
  How full the phone's alarm budget is, and what happens when it fills.

  A real figure rather than a warning: `Kati.Notifications.Plan.usage/1` is the
  same arithmetic the scheduler sheds against, so the number here and the
  reminder that went missing have one source.
  """
  @spec budget_note(Plan.t()) :: map()
  def budget_note(plan) do
    pending = Plan.pending_count(plan)

    SettingsList.note(
      "info",
      "#{pending} #{if pending == 1, do: "reminder is", else: "reminders are"} armed. " <>
        "This phone allows 500 across the whole app, divided between the six sections so a " <>
        "busy calendar cannot quietly starve your meal reminders. When a section is full, " <>
        "the furthest-away reminder is the one dropped — never the soonest."
    )
  end

  @doc """
  The sentence that says the quiet is deliberate.

  Last on the page, because it is the answer somebody arrives at after reading
  the rest, and putting it first would read as an excuse.
  """
  @spec closing() :: map()
  def closing do
    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={12} />
      {Kati.UI.SettingsList.note("info", "Kati is quiet on purpose. It would rather show you a badge you can look at than interrupt you, and it stops asking after you have skipped something twice. If the answer above is “by design”, nothing is broken — but every one of those is a setting you can change.")}
    </Column>
    """
  end

  @doc false
  def handle_tap(:open_inbox, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.InboxNotifications)}

  def handle_tap(:ask, socket), do: {:noreply, ask(socket)}

  # Both open a system screen through the platform, which Kati has no fence
  # for: nothing in `native/LEDGER.md` launches an Android settings intent.
  # Drawn, reachable, and honest about waiting on that — the same state screen
  # 83's six link rows are in.
  def handle_tap(_tag, socket), do: {:noreply, socket}

  @doc """
  Raise the system dialog, note that it was asked, and re-read.

  Noting the ask is what makes the four states four: Android cannot tell
  *never asked* from *permanently refused*, and `Kati.Permissions` disambiguates
  with its own record. Without this line the row would offer Allow forever
  after the first refusal.
  """
  @spec ask(Mob.Socket.t()) :: Mob.Socket.t()
  def ask(socket) do
    socket = Mob.Permissions.request(socket, :notifications)
    Permissions.note_asked(:notifications)
    Mob.Socket.assign(socket, :notifications, Permissions.status(:notifications))
  rescue
    _error -> socket
  end
end
