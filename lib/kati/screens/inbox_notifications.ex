defmodule Kati.Screens.InboxNotifications do
  @moduledoc """
  Notifications — the inbox behind Home's bell.

  ## What this replaced, and why that mattered

  The bell on screen 01 opened `Kati.Screens.Gallery` — every screen in the
  app, in one list. That was scaffolding and said so in its own moduledoc: it
  existed so 53 screens that landed at once could be *looked at* before they
  could be *reached*. Every one of them is reachable now, from its own place,
  so the bell goes back to meaning what a bell means.

  ## Kati's notification manners need a surface, or quiet looks broken

  Push is off by default. Quiet hours run 23:00–08:00. Reminders stop after two
  skips. A weekly digest replaces a stream of individual pushes. Every one of
  those is a decision to interrupt you less, and an app that arranges not to
  tell you things has to put what it did not tell you somewhere — or *polite*
  and *broken* look exactly the same from the outside.

  So the badge on the bell is the interruption, and this is where it leads.

  ## Three groups, and the third is the point

  **Now** is today. **Later** is coming. **Held back** is the group that makes
  the quiet defensible: every suppressed reminder with the reason it was —
  muted, quiet hours, budget, digest, stopped after two skips. Those are
  decisions, and a user who can read them can tell the difference between an
  app being careful and an app having failed.

  ## Everything here is the plan, not a second opinion

  `Kati.Notifications.Scheduler.plan/2` decides what is armed, when, and what
  was shed — per domain, against a real budget. `Kati.Notifications.Inbox`
  presents it and computes nothing, which is what stops the badge and the
  alarms from disagreeing.

  ## Not drawn

  There is no artboard for this screen. The 127 the design holds include screen
  29 — the lock screen showing a Kati notification — and screen 25, the release
  watcher's loudness settings, and nothing between them. It is built in screen
  05's idiom instead: the same grouped rows, the same eyebrows, the same empty
  state, and it says so in `Kati.Screens.Gallery`'s undrawn list.
  """

  use Kati.Screens.Pushed, back: "Home"

  alias Kati.Notifications.Candidate
  alias Kati.Notifications.Inbox
  alias Kati.Notifications.Scheduler
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  def load(socket), do: Mob.Socket.assign(socket, :plan, plan())

  @doc """
  The plan this screen shows.

  Built from every domain's candidates through the one scheduler, on this
  device's platform and clock. `Kati.Notifications.Sources.Media` is the only
  source with a real collector today; the other five domains contribute nothing
  yet and their rows say `Nothing today` rather than being absent, because
  *nothing* is an answer.
  """
  @spec plan() :: Kati.Notifications.Plan.t()
  def plan do
    Scheduler.plan(candidates(), platform: platform(), now: Kati.Time.now())
  rescue
    _error ->
      %Kati.Notifications.Plan{platform: platform(), now: Kati.Time.now(), zone: "Etc/UTC"}
  end

  @doc """
  Every domain's candidates.

  One collector today and five domains without one, and that asymmetry is
  visible on the page rather than hidden: a domain with no source has an empty
  row, which is what `Kati.Notifications.Inbox.by_domain/1` guarantees by
  reading the budget's own domain list rather than the collectors'.
  """
  @spec candidates() :: [Candidate.t()]
  def candidates do
    Kati.Notifications.Sources.Media.candidates(media_pairs())
  rescue
    _error -> []
  end

  defp media_pairs do
    Kati.Media.TrackedTitle
    |> Ash.Query.for_read(:shelf, %{kind: :series})
    |> Ash.read()
    |> case do
      {:ok, tracked} -> Enum.map(tracked, &{&1, nil})
      _other -> []
    end
  rescue
    _error -> []
  end

  # `:android`, because that is the only build that ships. The budget's iOS
  # column exists and is real — `Kati.Notifications.Budget` caps iOS at 64
  # pending notifications against Android's 500 — so this is the one line that
  # has to change when an iOS build does, and it is one line rather than a
  # guess spread across the page.
  defp platform, do: :android

  @doc false
  def content(assigns) do
    groups = Inbox.groups(assigns.plan)

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
        {SettingsList.title("Notifications", Kati.Screens.InboxNotifications.subtitle(groups))}
        {Kati.Screens.InboxNotifications.group("Now", groups.now, :armed)}
        {Kati.Screens.InboxNotifications.group("Later", groups.later, :armed)}
        {Kati.Screens.InboxNotifications.group("Held back", groups.held, :held)}
        {Kati.Screens.InboxNotifications.empty(groups)}
        {UI.eyebrow("By section", dash: Palette.rail_idle())}
        {Kati.Screens.InboxNotifications.domains(assigns.plan)}
        {Kati.Screens.InboxNotifications.manners()}
      </Column>
    </Scroll>
    """
  end

  @doc "The header's mono subtitle: what is due today, and what is held."
  @spec subtitle(map()) :: String.t()
  def subtitle(groups) do
    now = length(groups.now)
    held = length(groups.held)

    String.upcase("#{now} today · #{held} held back")
  end

  @doc """
  One group, or nothing at all.

  An empty group draws no eyebrow either — screen 05's rule, and the reason is
  that three empty headings read as an app that has broken rather than as an
  evening with nothing due.
  """
  @spec group(String.t(), [Candidate.t()], :armed | :held) :: map() | []
  def group(_label, [], _kind), do: []

  def group(label, candidates, kind) do
    rows = Enum.map(candidates, &Kati.Screens.InboxNotifications.row(&1, kind))
    dash = if kind == :held, do: Palette.rail_idle(), else: Palette.accent()

    assigns = %{label: label, rows: rows, dash: dash}

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.eyebrow(@label, dash: @dash)}
      {Kati.UI.SettingsList.card(@rows)}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  One reminder.

  An armed row's trailing value is the time it will fire; a held row's is
  nothing, and its second line carries the reason instead. That asymmetry is
  deliberate — a held reminder has no time, and printing the time it *would*
  have had would be the page's one misleading number.
  """
  @spec row(Candidate.t(), :armed | :held) :: map()
  def row(%Candidate{} = candidate, kind) do
    SettingsList.row(
      SettingsList.icon_tile(Inbox.domain_icon(candidate.domain)),
      SettingsList.body(
        Inbox.title(candidate),
        Kati.Screens.InboxNotifications.sub(candidate, kind)
      ),
      SettingsList.trailing(Kati.Screens.InboxNotifications.trailing(candidate, kind)),
      on_tap: {self(), :open_source}
    )
  end

  @doc false
  def sub(%Candidate{} = candidate, :held), do: Inbox.held_reason(candidate.suppressed)
  def sub(%Candidate{body: body}, _armed) when is_binary(body) and body != "", do: body
  def sub(%Candidate{domain: domain}, _armed), do: Inbox.domain_label(domain)

  @doc false
  def trailing(%Candidate{}, :held), do: nil

  def trailing(%Candidate{fire_at: nil}, _armed), do: nil

  def trailing(%Candidate{fire_at: at}, _armed) do
    assigns = %{label: Calendar.strftime(Kati.Time.in_zone(at, Kati.Time.device_zone()), "%H:%M")}

    ~MOB"""
    <Text
      text={@label}
      font_family="mono"
      text_size={12}
      text_color={Kati.Theme.Palette.sub()}
      max_lines={1}
    />
    """
  end

  @doc """
  The empty state, or nothing.

  Invites rather than apologises, which is screen 27's own rule for an empty
  state — and here the invitation is specific: nothing is due **because** Kati
  is quiet by default, and the row underneath is where that is turned up.
  """
  @spec empty(map()) :: map() | []
  def empty(%{now: [], later: [], held: []}) do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        padding={19}
        shadow={Kati.Theme.shadow_card()}
        align="center"
      >
        {Kati.UI.symbol("notifications_off", size: 26, color: Palette.tertiary())}
        <Spacer size={12} />
        <Text
          text="Nothing waiting"
          text_size={16}
          font_weight="bold"
          text_align="center"
          text_color={:on_surface}
        />
        <Spacer size={7} />
        <Text
          text="Kati is quiet unless you ask it not to be. Turn a reminder on and it will show up here first, before it ever interrupts you."
          text_size={12.5}
          line_height={1.55}
          text_align="center"
          text_color={Palette.sub()}
        />
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  def empty(_groups), do: []

  @doc """
  How many reminders each section is using of its share.

  Every domain gets a row, including the five with no collector yet — see
  `Kati.Notifications.Inbox.by_domain/1`. The share is real: it is the same
  number `Kati.Notifications.Budget` sheds against, so a section that is full
  says so here before a reminder goes missing.
  """
  @spec domains(Kati.Notifications.Plan.t()) :: map()
  def domains(plan) do
    rows =
      plan
      |> Inbox.by_domain()
      |> Enum.map(fn {domain, count, limit} ->
        SettingsList.row(
          SettingsList.icon_tile(Inbox.domain_icon(domain)),
          SettingsList.body(
            Inbox.domain_label(domain),
            Kati.Screens.InboxNotifications.usage_line(count, limit)
          ),
          SettingsList.trailing(nil)
        )
      end)

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.card(rows)}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc "`2 of 24 slots` — or the sentence a section with nothing armed gets."
  @spec usage_line(non_neg_integer(), pos_integer()) :: String.t()
  def usage_line(0, _limit), do: "Nothing today"
  def usage_line(count, limit), do: "#{count} of #{limit} slots"

  @doc """
  The two rows that lead out of the inbox.

  `How loudly` is where the manners are set — screen 25 — and *Why am I not
  getting these?* is the diagnostic. The second is on the inbox rather than
  buried in Settings for the obvious reason: the person asking that question is
  looking at an empty inbox when they ask it.
  """
  @spec manners() :: map()
  def manners do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.eyebrow("Manners", dash: Kati.Theme.Palette.rail_idle())}
      {Kati.UI.SettingsList.card([
        Kati.UI.SettingsList.row(
          Kati.UI.SettingsList.icon_tile("notifications_active"),
          Kati.UI.SettingsList.body("How loudly", "Quiet hours, digest, stop after two skips"),
          Kati.UI.SettingsList.trailing(Kati.UI.SettingsList.chevron()),
          on_tap: {self(), :open_watcher}
        ),
        Kati.UI.SettingsList.row(
          Kati.UI.SettingsList.icon_tile("help"),
          Kati.UI.SettingsList.body("Why am I not getting these?", "Permissions, alarms and battery"),
          Kati.UI.SettingsList.trailing(Kati.UI.SettingsList.chevron()),
          on_tap: {self(), :open_diagnostic}
        )
      ])}
    </Column>
    """
  end

  @doc false
  def handle_tap(:open_watcher, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.ReleaseWatcher)}

  def handle_tap(:open_diagnostic, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.NotificationsHelp)}

  # A reminder's own screen is per-domain and this inbox spans six of them; the
  # candidate carries an id rather than a destination, so there is nothing here
  # to route on yet. Answered rather than left dead.
  def handle_tap(_tag, socket), do: {:noreply, socket}
end
