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

  ## Said in the reader's own language

  Every sentence on the page is a msgid. Two things on it are not, and both are
  somebody else's:

    * **The held-back reasons.** `held_line/1` joins whatever
      `Kati.Notifications.Inbox.held_reason/1` answers, and those five
      sentences belong to the inbox — they are drawn on screen 59 as well, and
      one of them translated twice would be two Persians for one rule. The
      frame around them is this screen's and is translated; the reasons arrive
      as the inbox says them.
    * **A failed settings intent.** `Kati.Native.Links.message/1` owns those
      six sentences for the three screens that open a system screen.

  Three figures on the page are read rather than written: the quiet-hours
  window comes off `Kati.Notifications.QuietHours.default/0`, the alarm ceiling
  off `Kati.Notifications.Budget.cap/1`, and the armed count off the plan. A
  diagnostic that states a number the scheduler does not use is the exact
  failure this screen exists to prevent, and a number spelled into a Persian
  sentence by a translator is that failure with an extra step.
  """

  use Kati.Screens.Pushed, back: "Settings"
  use Gettext, backend: Kati.Gettext

  alias Kati.Notifications.Budget
  alias Kati.Notifications.Inbox
  alias Kati.Notifications.Plan
  alias Kati.Notifications.QuietHours
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

  # THE BATTERY ROW'S FAILURE HAD NOWHERE TO GO.
  #
  # `handle_tap(:open_battery, …)` has assigned `:link_error` since `K-44
  # open-settings` landed and nothing drew it, so a phone with no activity for
  # the battery-optimisation intent answered `{:error, :no_handler}`, the
  # message was built, stored — and the row simply did nothing. On the one page
  # in the app whose subject is *a thing that silently fails to happen*, that
  # is the wrong bug to carry.
  #
  # `Kati.UI.notice/1` is the same node `Kati.Screens.Attribution` draws for
  # the same assign, and `notice(nil)` is `[]`, so the ordinary render is the
  # tree it always was. It sits UNDER the phone group rather than under the
  # title, which is where screen 83 puts it: the control that can fail is the
  # last row of that card, and a red line at the top of a scrolling page is a
  # message the reader who pressed the button cannot see.
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
        {SettingsList.title(gettext("Why am I not getting these?"), gettext("FIVE THINGS, THREE OF THEM SILENT"))}
        {UI.eyebrow(gettext("What Kati decided"))}
        {Kati.Screens.NotificationsHelp.kati_group(assigns.plan)}
        {UI.eyebrow(gettext("What the phone decided"), dash: Palette.bronze())}
        {Kati.Screens.NotificationsHelp.phone_group(assigns)}
        {Kati.UI.notice(assigns[:link_error])}
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
          gettext("Push is off until you ask"),
          gettext("Kati shows a badge on the bell instead. Nothing here is broken by that."),
          lines: 3
        ),
        SettingsList.trailing(
          Kati.Screens.NotificationsHelp.status(
            pgettext("a status on the notifications diagnostic", "By design"),
            :neutral
          )
        )
      ),
      SettingsList.row(
        SettingsList.icon_tile("bedtime"),
        SettingsList.body(
          Kati.Screens.NotificationsHelp.quiet_hours_label(),
          gettext("A reminder inside them moves to the morning. It is never dropped."),
          lines: 3
        ),
        SettingsList.trailing(
          Kati.Screens.NotificationsHelp.status(
            pgettext("a status on the notifications diagnostic", "Shifting"),
            :neutral
          )
        )
      ),
      SettingsList.row(
        SettingsList.icon_tile("inbox"),
        SettingsList.body(
          gettext("Held back right now"),
          Kati.Screens.NotificationsHelp.held_line(groups.held),
          lines: 3
        ),
        # `SettingsList.chevron/0` already points the reading direction —
        # `Kati.Locale.forward_chevron/0` inside it — and this row opens screen
        # 59, so it is the chevron that belongs here rather than a glyph name.
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

  @doc """
  The quiet-hours row's title, with the window's own two times in it.

  Read off `Kati.Notifications.QuietHours.default/0` rather than written into
  the sentence. That struct is what `Kati.Notifications.Scheduler` shifts
  against when nothing overrides it, so the row and the rule it describes have
  one source; screen 38 is where the window becomes a setting, and when it does
  this reads the setting instead of the default without the copy being touched.

  One msgid with two holes rather than a label joined to a range, for the
  reason `Kati.Screens.ReleaseWatcher.copy/1` gives about its own quiet-hours
  row: Persian puts a WORD between the two times where the drawing puts an en
  dash, and a screen that concatenates has already decided. Both times go
  through `Kati.Locale.time/1`, so `23:00` is ۲۳:۰۰ without a translator
  carrying a digit.
  """
  @spec quiet_hours_label() :: String.t()
  def quiet_hours_label do
    window = QuietHours.default()

    gettext("Quiet hours %{from} – %{to}",
      from: Kati.Locale.time(window.from),
      to: Kati.Locale.time(window.to)
    )
  end

  @doc "How many are held back, and by what — or that nothing is."
  @spec held_line([Kati.Notifications.Candidate.t()]) :: String.t()
  def held_line([]), do: gettext("Nothing is being held back")

  # `gettext/2` and not `ngettext/4`: *held* is a past participle and does not
  # inflect after a numeral in English any more than it does in Persian, so
  # there is no second form for a translator to fill in.
  #
  # `%{reasons}` arrives untranslated and deliberately stays that way. The five
  # sentences are `Kati.Notifications.Inbox.held_reason/1`'s, screen 59 draws
  # the same five, and a second msgid here would be a second Persian for one
  # rule. Not wrapped in `Kati.Locale.ltr/1` either: the run is English only
  # until the inbox is folded, and an isolate around Persian would then force
  # the wrong base direction on it.
  def held_line(held) do
    reasons =
      held
      |> Enum.map(& &1.suppressed)
      |> Enum.uniq()
      |> Enum.map_join(", ", fn reason -> reason |> Inbox.held_reason() |> String.downcase() end)

    gettext("%{n} held — %{reasons}", n: Kati.Locale.number(length(held)), reasons: reasons)
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
        pgettext("a row on the notifications diagnostic", "Showing notifications"),
        gettext(
          "Denied, Kati still arms the alarm and the phone never displays it. Nothing reports the failure."
        ),
        assigns.notifications
      ),
      Kati.Screens.NotificationsHelp.permission_row(
        "schedule",
        pgettext("a row on the notifications diagnostic", "Exact alarms"),
        gettext(
          "Without this a reminder is batched — right for “new episode”, wrong for “starts now”."
        ),
        assigns.alarms
      ),
      SettingsList.row(
        SettingsList.icon_tile("bolt"),
        SettingsList.body(
          pgettext("a row on the notifications diagnostic", "Battery optimisation"),
          gettext(
            "Some phones stop background work in ways an app cannot detect. If reminders are late or missing, this is the first place to look."
          ),
          # Five, not four: this row's sub shares its width with an
          # `Open settings` pill, so it wraps narrower than the rows above it.
          # Counted from the device rather than guessed — the screenshot showed
          # `…this is the fi…` at four.
          #
          # The count is the ENGLISH one and stays it. Vazirmatn sets this
          # sentence a little wider and the fifth line is where it breaks in
          # both, so the number is not per-locale; if a Persian screenshot ever
          # shows a sixth, `Kati.Locale.pick/2` is the knob, not a bumped
          # literal that would loosen the English row for nothing.
          lines: 5
        ),
        SettingsList.trailing(
          SettingsList.action_pill(
            pgettext("a pill that opens the phone's own settings", "Open settings")
          )
        ),
        on_tap: {self(), :open_battery}
      ),
      SettingsList.row(
        SettingsList.icon_tile("timer"),
        SettingsList.body(
          pgettext("a row on the notifications diagnostic", "After a restart"),
          gettext(
            "Kati re-arms everything still due. Anything that was due while the phone was off is gone — it cannot be delivered late."
          ),
          lines: 5
        ),
        SettingsList.trailing(
          Kati.Screens.NotificationsHelp.status(
            pgettext("a status on the notifications diagnostic", "Re-armed"),
            :good
          )
        )
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
      SettingsList.body(title, why, lines: 4),
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

  ## The four words are four msgids, and two of them are not this screen's own

  `Allow` is the msgid screen 40's permission group already carries, under the
  context that keeps the VERB on the button (اجازه) apart from the state beside
  a granted row (مجاز) — `Kati.Screens.Account.state_label/1` is where that
  argument is written out. One button, one word, on both screens.

  `On` and `Off` are this page's and take a context of their own rather than
  the switch's. Screen 40 says **Allowed** where this says **On**, because that
  page is a list of permissions and this is a list of *reasons a notification
  did not arrive*; one English word two boards write differently is exactly
  what `pgettext/2` is for. The Persian is روشن and خاموش either way — the
  context is what stops `mix gettext.merge` folding a one-letter-different
  msgid into the switch's and making the two move together later.
  """
  @spec permission_trailing(atom()) :: map()
  def permission_trailing(:granted),
    do: status(pgettext("a status on the notifications diagnostic", "On"), :good)

  def permission_trailing(state) do
    case Permissions.affordance(state) do
      :allow ->
        SettingsList.action_pill(pgettext("permission", "Allow"))

      :settings ->
        SettingsList.action_pill(
          pgettext("a pill that opens the phone's own settings", "Open settings")
        )

      :none ->
        status(pgettext("a status on the notifications diagnostic", "Off"), :bad)
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

  ## The face is asked for rather than named

  `Kati.Locale.mono_face/1`, not the literal `"mono"`. All five labels this
  page passes — *By design*, *Shifting*, *Re-armed*, *On*, *Off* — are msgids,
  so under `:fa` every one of them arrives as Persian, and `kati_mono.ttf`
  carries no Arabic-script glyph at all: set in it, طبق طراحی is handed to
  Android's own substitute face and renders, correctly shaped, in a typeface
  that is not Kati's, two rows above a sentence that is.

  The arity-1 form because the label arrives here as a VALUE. The question a
  status slot wants asked is the string's own script rather than the reader's
  — `Kati.Screens.Account.state_mark/1` is the same call for the same slot —
  so a label that is still ASCII on a Persian page stays in DM Mono, which is
  what the boards draw for a machine's own word.
  """
  @spec status(String.t(), :good | :bad | :neutral) :: map()
  def status(label, tone) do
    colour =
      case tone do
        :good -> Palette.green_text()
        :bad -> Palette.gold_text()
        :neutral -> Palette.sub()
      end

    assigns = %{label: label, colour: colour, face: Kati.Locale.mono_face(label)}

    ~MOB"""
    <Text text={@label} font_family={@face} text_size={11.5} text_color={@colour} max_lines={1} />
    """
  end

  @doc """
  How full the phone's alarm budget is, and what happens when it fills.

  A real figure rather than a warning: `Kati.Notifications.Plan.usage/1` is the
  same arithmetic the scheduler sheds against, so the number here and the
  reminder that went missing have one source.

  ## The ceiling was the one figure on the page that was not read

  The sentence said **500** and the row says *this phone*. 500 is Android's
  `AlarmManager` cap and iOS keeps 64 — `Kati.Notifications.Budget`'s moduledoc
  is where both cliffs are written down and `cap/1` is where they are answered
  — so on the platform whose failure is the silent one, a page built to explain
  a missing reminder was stating a ceiling nearly eight times the real one.
  `plan.platform` is never `nil` here: `Kati.Screens.InboxNotifications.plan/0`
  sets it on the rescue path as well as the live one. On Android it prints the
  same number it always did.

  **Six is still a word.** `Budget.domains/0` has six entries and interpolating
  its length would print *the 6 sections*, which is not the sentence the copy
  writes — and unlike the cap it is a constant of Kati's own design rather than
  a fact about the phone in the reader's hand.

  ## Two msgids rather than one, split on the sentence boundary

  `ngettext/4` has to hold the singular and the plural of the whole paragraph
  or of none of it, and only two words of it move. So the count is its own
  msgid and the explanation is another, joined with the space that was already
  between them — the arrangement `Kati.Screens.MealReminders.copy/1` uses for
  its own two-part line. Persian does not inflect a noun after a numeral, so
  `msgstr[0]` and `msgstr[1]` are the same sentence there; the plural form
  exists for the English.
  """
  @spec budget_note(Plan.t()) :: map()
  def budget_note(plan) do
    pending = Plan.pending_count(plan)
    cap = Budget.cap(plan.platform)

    SettingsList.note(
      "info",
      ngettext("%{n} reminder is armed.", "%{n} reminders are armed.", pending,
        n: Kati.Locale.number(pending)
      ) <>
        " " <>
        gettext(
          "This phone allows %{cap} across the whole app, divided between the six sections so a busy calendar cannot quietly starve your meal reminders. When a section is full, the furthest-away reminder is the one dropped — never the soonest.",
          cap: Kati.Locale.number(cap)
        )
    )
  end

  @doc """
  The sentence that says the quiet is deliberate.

  Last on the page, because it is the answer somebody arrives at after reading
  the rest, and putting it first would read as an excuse.

  ## It quotes a label, so the two have to be translated together

  *“by design”* inside this sentence is not a phrase — it is the word the first
  card's trailing status wears, said back to the reader so they can find it.
  The status is `By design` under this page's own status context, and a Persian
  closing sentence that quoted anything else would be pointing at a row that
  does not exist. Both are طبق طراحی, and they move together or not at all.
  """
  @spec closing() :: map()
  def closing do
    assigns = %{
      text:
        gettext(
          "Kati is quiet on purpose. It would rather show you a badge you can look at than interrupt you, and it stops asking after you have skipped something twice. If the answer above is “by design”, nothing is broken — but every one of those is a setting you can change."
        )
    }

    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={12} />
      {Kati.UI.SettingsList.note("info", @text)}
    </Column>
    """
  end

  @doc false
  def handle_tap(:open_inbox, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.InboxNotifications)}

  def handle_tap(:ask, socket), do: {:noreply, ask(socket)}

  # Both clauses below open a system screen through the platform, and both go
  # through the one fence that may: `K-44 open-settings` in `native/LEDGER.md`,
  # which takes a Kati word rather than a caller-supplied Android action.
  #
  # This comment used to say the opposite — that nothing in the ledger launched
  # a settings intent and these rows were honestly waiting on it. K-44 is what
  # it was waiting for; the sentence outlived the wait and is corrected rather
  # than deleted, because the doc immediately below it already names K-44 and a
  # file that says both is worse than one that says either.
  @doc """
  The battery row opens the phone's battery-optimisation list.

  Drawn, reachable and dead until `K-44 open-settings` was built. The research beside
  this row is explicit that the exemption must be reached by the user rather
  than granted, and this reaches it: `Kati.Native.Links.settings(:battery)`
  opens the LIST, not `ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`, which is
  a prompt Google's policy restricts and which an app of this kind should not
  be firing. Kati grants itself nothing.
  """
  def handle_tap(:open_battery, socket) do
    result = Kati.Native.Links.settings(:battery)

    message = if result == :ok, do: nil, else: Kati.Native.Links.message(elem(result, 1))

    {:noreply, Mob.Socket.assign(socket, :link_error, message)}
  end

  # A PERMANENTLY REFUSED PERMISSION OPENS KATI'S OWN PAGE IN SYSTEM SETTINGS.
  #
  # `permission_tap/1` has answered `{self(), :open_settings}` for `:denied`
  # and `:blocked` since this screen was written, and nothing matched it — the
  # tag fell through to the catch-all below and the pill did nothing at all.
  # `Kati.NotificationsInboxTest` asserts the tag is produced and stops there,
  # which is why the gap survived. On a page whose entire subject is *a thing
  # that silently fails to happen*, an **Open settings** button that silently
  # fails to open settings was the worst dead control in the app.
  #
  # `:app` and not `:battery`: Android will not re-prompt for a refused
  # `POST_NOTIFICATIONS` or `SCHEDULE_EXACT_ALARM`, and the app's own info page
  # is where both of those switches live. `Kati.Screens.NotificationAccess`
  # sends its two pills to `:notification_listener` for the same reason — each
  # names the screen its own switch is on.
  #
  # The error path is `handle_tap(:open_battery, …)`'s, key for key, so a phone
  # with no activity for the intent says so in `content/1`'s notice rather than
  # going quiet a second time. A comment and not a `@doc`, because this is the
  # third clause of `handle_tap/2` and a third `@doc` on one function is a
  # redefinition warning rather than documentation.
  def handle_tap(:open_settings, socket) do
    result = Kati.Native.Links.settings(:app)

    message = if result == :ok, do: nil, else: Kati.Native.Links.message(elem(result, 1))

    {:noreply, Mob.Socket.assign(socket, :link_error, message)}
  end

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
