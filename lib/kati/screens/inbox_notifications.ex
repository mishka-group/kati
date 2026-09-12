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

  ## Said in the reader's own language

  Every word this page writes is a msgid. Three kinds of word on it are not,
  and none of them is this screen's to say:

    * **A row's title, its domain name and its held-back reason.**
      `Kati.Notifications.Inbox.title/1`, `domain_label/1` and `held_reason/1`
      answer all three. Those sentences are drawn on the diagnostic (#26) as
      well — `Kati.Screens.NotificationsHelp.held_line/1` joins the same five —
      and one of them translated twice would be two Persians for one rule. The
      frame around them is this screen's and is translated; the words arrive as
      the inbox says them.
    * **A candidate's own body.** `Kati.Notifications.Sources.*` writes it per
      domain, out of a meal's name or an episode's number, and a line built
      from a record is not copy.
    * **The back pill.** `Kati.Screens.Pushed.back_vocabulary/0` owns every
      label a pill can carry, for the reason its own doc gives about
      `mix gettext.extract --merge` deleting hand-added entries.

  Two figures on the page are read rather than written: the counts in the
  header come off the groups and the share in each section's line comes off
  `Kati.Notifications.Budget`. Both go through `Kati.Locale.number/1` rather
  than being spelled into a sentence — a translator carrying a digit is how a
  page ends up stating a number the scheduler does not use.
  """

  use Kati.Screens.Pushed, back: "Home"
  use Gettext, backend: Kati.Gettext

  alias Kati.Notifications.Candidate
  alias Kati.Notifications.Inbox
  alias Kati.Notifications.Scheduler
  alias Kati.Notifications.Sources
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  def load(socket), do: Mob.Socket.assign(socket, :plan, plan())

  @doc """
  The plan this screen shows.

  Built from every domain's candidates through the one scheduler, on this
  device's platform and clock. All six domains have a collector now — see
  `candidates/0` — so a row that says `Nothing today` means the domain was
  asked and had nothing, rather than that nobody asked.
  """
  @spec plan() :: Kati.Notifications.Plan.t()
  def plan do
    Scheduler.plan(candidates(), platform: platform(), now: Kati.Time.now())
  rescue
    _error ->
      %Kati.Notifications.Plan{platform: platform(), now: Kati.Time.now(), zone: "Etc/UTC"}
  end

  @doc """
  Every domain's candidates, from all six collectors.

  One call per domain, each reading its own store and each free to fail on its
  own: a collector that raises contributes `[]` and the other five still
  answer. That is deliberate rather than defensive — this screen is the one a
  reader opens *because* something is not arriving, and a page that goes blank
  when one domain is unhappy cannot tell them which.

  The domain list the page renders comes from
  `Kati.Notifications.Inbox.by_domain/1`, which reads
  `Kati.Notifications.Budget`'s own list rather than the collectors', so a
  domain that returns nothing still draws its row.

  Each source is told the day rather than reading the clock itself, so the six
  answers are about one day and `Kati.Notifications.Scheduler` is comparing
  like with like.
  """
  @spec candidates() :: [Candidate.t()]
  def candidates do
    day = Kati.Time.today()
    opts = [zone: Kati.Time.device_zone()]

    zone = Kati.Time.device_zone()

    Enum.concat([
      safely(fn -> Sources.Media.candidates(media_pairs()) end),
      safely(fn -> Sources.Calendar.candidates(Sources.Calendar.events(day, zone), opts) end),
      safely(fn -> Sources.Habits.candidates(Sources.Habits.events(day, zone), day, opts) end),
      safely(fn -> meals(day, opts) end),
      safely(fn -> Sources.Health.candidates(Sources.Health.active(), day, opts) end),
      safely(fn -> Sources.Money.candidates(Sources.Money.subscribed(), day, opts) end)
    ])
  end

  # The plan and its slots are two reads and the source takes both, so the pair
  # is assembled here — one place that knows they belong together, and a `nil`
  # plan never runs the second read.
  defp meals(day, opts) do
    case Sources.Meals.active_plan() do
      nil -> []
      plan -> Sources.Meals.candidates(plan, Sources.Meals.slots(plan, day), day, opts)
    end
  end

  # One collector's failure is not the page's. See `candidates/0`.
  defp safely(fun) do
    fun.()
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

  # THE FOUR EYEBROW LABELS ARE TRANSLATED HERE RATHER THAN WHERE THEY ARE DRAWN.
  #
  # `group/3` takes its label as an argument and hands it to `Kati.UI.eyebrow/2`,
  # so by the time it reaches a `<Text>` it is a runtime value — and
  # `gettext(some_variable)` does not compile, the msgid having to be a literal
  # at the call site. This is that call site.
  #
  # They share the `eyebrow` context the rest of the app's short section labels
  # use, which is what lets *Manners* below reuse screen 51's آداب rather than
  # opening a second Persian for one word.
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
        {SettingsList.title(gettext("Notifications"), Kati.Screens.InboxNotifications.subtitle(groups))}
        {Kati.Screens.InboxNotifications.group(pgettext("eyebrow", "Now"), groups.now, :armed)}
        {Kati.Screens.InboxNotifications.group(pgettext("eyebrow", "Later"), groups.later, :armed)}
        {Kati.Screens.InboxNotifications.group(pgettext("eyebrow", "Held back"), groups.held, :held)}
        {Kati.Screens.InboxNotifications.empty(groups)}
        {UI.eyebrow(pgettext("eyebrow", "By section"), dash: Palette.rail_idle())}
        {Kati.Screens.InboxNotifications.domains(assigns.plan)}
        {Kati.Screens.InboxNotifications.manners()}
      </Column>
    </Scroll>
    """
  end

  @doc """
  The header's mono subtitle: what is due today, and what is held.

  One msgid with two holes rather than two counts joined to two labels, for the
  reason `Kati.Screens.NotificationsHelp.quiet_hours_label/0` gives about its
  own two times: Persian does not put its words in the order the separator
  assumes, and a line assembled out of fragments has already decided for the
  translator.

  `Kati.UI.eyebrow_label/1` rather than `String.upcase/1`. Persian has no case,
  so upcasing a Persian line changes nothing while *looking* like a rule the
  page applies — and the helper keeps the English line the caps the design
  draws while leaving the Persian alone.

  Both counts go through `Kati.Locale.number/1`. That is safe here and is not
  safe everywhere: this line is set in `Kati.UI.SettingsList.subtitle/2`, whose
  face is `Kati.Locale.mono_face/0` — Vazirmatn under `:fa`, not
  `kati_mono.ttf` — so the Persian numerals it asks for are numerals that face
  actually carries.
  """
  @spec subtitle(map()) :: String.t()
  def subtitle(groups) do
    now = length(groups.now)
    held = length(groups.held)

    Kati.UI.eyebrow_label(
      gettext("%{now} today · %{held} held back",
        now: Kati.Locale.number(now),
        held: Kati.Locale.number(held)
      )
    )
  end

  @doc """
  One group, or nothing at all.

  An empty group draws no eyebrow either — screen 05's rule, and the reason is
  that three empty headings read as an app that has broken rather than as an
  evening with nothing due.

  `label` arrives **already translated** — see the note above `content/1` — and
  is drawn through `Kati.UI.eyebrow/2`, which upcases only Latin and sets the
  line in `Kati.Locale.mono_face/0`. So nothing here has to know which script
  it is in.
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
      # The candidate, not `candidate.domain`. The row knows which reminder it is
      # drawing and threw that away one field before the tap was built, so ten
      # calendar reminders drew ten identical taps.
      on_tap: {self(), Kati.Screens.InboxNotifications.tag_for(candidate)}
    )
  end

  @doc """
  Which screen a row opens: its own event, or the screen that owns that kind of
  reminder.

  A row on this page is a reminder from somewhere else, and for five of the six
  domains the useful thing to do with it is go to where it is configured — a
  held meal reminder is a question about screen 51, not about tonight's dal.
  Those five carry the **domain**, because the domain is the thing that has a
  screen: a habit, a meal reminder, an air date and a subscription have no
  per-row board in the 165 to open.

  A calendar reminder does have one. Screen 31 takes `%{id: id}` and
  `Kati.Notifications.Sources.Calendar` carries the event's primary key on the
  candidate, so that row opens the event it is actually about rather than the
  Calendar root every calendar reminder used to share. The id travels **in the
  tag** because a tap has no other channel: an `on_tap` is `{pid, atom}` and
  `handle_tap/2` sees the atom alone. Screen 02 settled the spelling —
  `row_event_<uuid>`, decoded in its own catch-all — and this is that shape with
  this page's prefix.

  The tag is per domain rather than one `:open_source` for all six. That was
  the shape until every domain had a collector, and it could not survive one:
  a single tag has to decide at handle time what it could not know at draw time,
  and `Kati.ScreenTapSweepTest` reports a tag that reaches nothing — correctly,
  because a tap answered by a catch-all is a tap that does nothing.
  """
  @spec tag_for(Candidate.t() | Kati.Notifications.Budget.domain()) :: atom()
  def tag_for(%Candidate{domain: :calendar, meta: %{event_id: id}})
      when is_binary(id) and id != "",
      do: String.to_atom("open_calendar_" <> id)

  # Everything else falls through to the domain it was already answered by — the
  # five domains with nowhere of their own to go, and a calendar candidate built
  # before its source carried the key, or from an event that has none.
  def tag_for(%Candidate{domain: domain}), do: tag_for(domain)

  def tag_for(:calendar), do: :open_calendar
  def tag_for(:tv), do: :open_tv
  def tag_for(:habits), do: :open_habits
  def tag_for(:meals), do: :open_meals
  def tag_for(:health), do: :open_health
  def tag_for(:money), do: :open_money

  # A row's second line is the reason it was held, its own body, or its domain,
  # and NONE of the three is a msgid of this screen's — see the moduledoc. The
  # held reason and the domain name belong to
  # `Kati.Notifications.Inbox.held_reason/1` and `domain_label/1`, which the
  # diagnostic draws as well; the body is whatever the domain's own collector
  # wrote out of a record. Wrapping any of them here would be a second Persian
  # for one rule.
  @doc false
  def sub(%Candidate{} = candidate, :held), do: Inbox.held_reason(candidate.suppressed)
  def sub(%Candidate{body: body}, _armed) when is_binary(body) and body != "", do: body
  def sub(%Candidate{domain: domain}, _armed), do: Inbox.domain_label(domain)

  @doc false
  def trailing(%Candidate{}, :held), do: nil

  def trailing(%Candidate{fire_at: nil}, _armed), do: nil

  # `Kati.Locale.time/1` rather than `Calendar.strftime/2` with `"%H:%M"`. Both
  # are 24-hour — the design's own choice, and `Kati.Screens.Settings` draws it
  # as a setting rather than as a consequence of the language — so the only
  # thing that moves is the numerals: ۲۱:۴۰ beside a header counted in Persian
  # rather than 21:40 stranded in the middle of a Persian page.
  #
  # And then the face has to ask the STRING and not the reader.
  # `Kati.Locale.mono_face/1` is the arity that does: `21:40` is pure ASCII and
  # stays DM Mono in both scripts, while `۲۱:۴۰` cannot — `kati_mono.ttf`
  # carries none of U+06F0–U+06F9, so a hardcoded `font_family="mono"` here
  # would have handed the converted time to Android's own substitute face and
  # drawn it in a typeface that is not Kati's. Screen 51's notification preview
  # settled the same question for `KATI · ۱۹:۱۵`.
  def trailing(%Candidate{fire_at: at}, _armed) do
    assigns = %{label: Kati.Locale.time(Kati.Time.in_zone(at, Kati.Time.device_zone()))}

    ~MOB"""
    <Text
      text={@label}
      font_family={Kati.Locale.mono_face(@label)}
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
          text={pgettext("the notification inbox's empty state", "Nothing waiting")}
          text_size={16}
          font_weight="bold"
          text_align="center"
          text_color={:on_surface}
        />
        <Spacer size={7} />
        <Text
          text={gettext("Kati is quiet unless you ask it not to be. Turn a reminder on and it will show up here first, before it ever interrupts you.")}
          text_size={12.5}
          line_height={Kati.Locale.leading(1.55)}
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

  @doc """
  `2 of 24 slots` — or the sentence a section with nothing armed gets.

  One msgid with both holes in it rather than a count joined to a label: the
  two numbers do not sit either side of the word *of* in Persian, and a line
  assembled out of fragments has decided the word order before a translator
  sees it.

  `gettext/2` and not `ngettext/4`, deliberately. The noun that could inflect
  is *slots*, and it is governed by `limit` rather than by `count` — a budget
  from `Kati.Notifications.Budget`, whose smallest allocation is the four iOS
  gives Health and Money. There is no singular English form for a translator to
  fill in because the table can never produce one.

  Both numbers go through `Kati.Locale.number/1`. This line is the sub of a
  `Kati.UI.SettingsList.body/3`, which names no `font_family` and so falls back
  to the root face the locale installed — Vazirmatn under `:fa` — so the
  Persian numerals are ones the face carries.
  """
  @spec usage_line(non_neg_integer(), pos_integer()) :: String.t()
  def usage_line(0, _limit), do: pgettext("a section with nothing armed", "Nothing today")

  def usage_line(count, limit) do
    gettext("%{count} of %{limit} slots",
      count: Kati.Locale.number(count),
      limit: Kati.Locale.number(limit)
    )
  end

  @doc """
  The two rows that lead out of the inbox.

  `How loudly` is where the manners are set — screen 25 — and *Why am I not
  getting these?* is the diagnostic. The second is on the inbox rather than
  buried in Settings for the obvious reason: the person asking that question is
  looking at an empty inbox when they ask it.

  ## Two of the five strings here are already said somewhere else

  *Why am I not getting these?* is the diagnostic's own title and the msgid it
  already carries, so this row and the page it opens say the same sentence
  once. *How loudly* is not: screen 25 holds it under the `eyebrow` context,
  where it labels a section, and here it is a row that opens that screen. One
  English phrase two boards write differently is what `pgettext/2` is for, so
  this takes a context of its own — the Persian is چقدر بلند بگوید either way,
  and the context is what stops `mix gettext.merge` folding the two together
  and making them move as one later.

  *Manners* takes the `eyebrow` context screen 51 already uses for the same
  word above the same kind of card, so there is one آداب rather than two.
  """
  @spec manners() :: map()
  def manners do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.eyebrow(pgettext("eyebrow", "Manners"), dash: Kati.Theme.Palette.rail_idle())}
      {Kati.UI.SettingsList.card([
        Kati.UI.SettingsList.row(
          Kati.UI.SettingsList.icon_tile("notifications_active"),
          Kati.UI.SettingsList.body(
            pgettext("a row on the inbox that opens the loudness settings", "How loudly"),
            gettext("Quiet hours, digest, stop after two skips")
          ),
          Kati.UI.SettingsList.trailing(Kati.UI.SettingsList.chevron()),
          on_tap: {self(), :open_watcher}
        ),
        Kati.UI.SettingsList.row(
          Kati.UI.SettingsList.icon_tile("help"),
          Kati.UI.SettingsList.body(
            gettext("Why am I not getting these?"),
            gettext("Permissions, alarms and battery")
          ),
          Kati.UI.SettingsList.trailing(Kati.UI.SettingsList.chevron()),
          on_tap: {self(), :open_diagnostic}
        )
      ])}
    </Column>
    """
  end

  @doc false
  def handle_tap(:open_watcher, socket),
    do:
      {:noreply,
       Mob.Socket.push_screen(socket, Kati.Screens.ReleaseWatcher, %{back: "Notifications"})}

  def handle_tap(:open_diagnostic, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.NotificationsHelp)}

  # One clause per domain, and each one lands on the screen that owns that
  # reminder rather than on the thing it is about: a held meal reminder is a
  # question about screen 51's controls, not about tonight's dal. `tag_for/1`
  # carries the argument.
  def handle_tap(:open_calendar, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Calendar)}

  def handle_tap(:open_tv, socket),
    do:
      {:noreply,
       Mob.Socket.push_screen(socket, Kati.Screens.ReleaseWatcher, %{back: "Notifications"})}

  def handle_tap(:open_habits, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Habits)}

  def handle_tap(:open_meals, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.MealReminders)}

  def handle_tap(:open_health, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Medication)}

  def handle_tap(:open_money, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Subscriptions)}

  # Below the named clauses and not above them: a prefix clause placed first
  # shadows the bare tag it starts with, and `:open_calendar` above is still the
  # answer for a calendar reminder that names no event.
  #
  # `%{id: id}` is the key screen 31 reads and the key screen 02's own timeline
  # pushes, so a reminder and a timeline row cannot disagree about what names an
  # event. `Kati.Screens.EventDetail.event/1` refuses an id that names nothing
  # and answers the drawing, so a reminder for an event deleted on another
  # device opens a page rather than crashing.
  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "open_calendar_" <> id ->
        {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.EventDetail, %{id: id})}

      _other ->
        {:noreply, socket}
    end
  end
end
