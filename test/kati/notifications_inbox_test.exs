defmodule Kati.NotificationsInboxTest do
  @moduledoc """
  The inbox behind Home's bell, and the diagnostic behind it.

  ## What these two screens are for

  Kati's notification manners are the app's quietest feature and its most
  easily mistaken one: push off by default, a badge instead, quiet hours
  23:00–08:00, stop after two skips, a weekly digest. Every one of those is a
  decision to interrupt less, and an app that arranges not to tell you things
  is indistinguishable from an app that has broken — unless something can say
  *this is what I decided, and here is what the phone decided.*

  So the assertions here are mostly about **honesty**: that the badge counts
  only what a badge should count, that a held-back reminder says why, and that
  a permission row never offers a button that would silently do nothing.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Notifications.Budget
  alias Kati.Notifications.Candidate
  alias Kati.Notifications.Inbox
  alias Kati.Notifications.Plan
  alias Kati.Screens.InboxNotifications
  alias Kati.Screens.NotificationsHelp

  @zone "Europe/London"
  @now DateTime.new!(~D[2026-08-16], ~T[09:00:00], @zone)

  defp candidate(id, domain, at, opts \\ []) do
    %Candidate{
      id: id,
      domain: domain,
      fire_at: at,
      title: Keyword.get(opts, :title),
      suppressed: Keyword.get(opts, :suppressed)
    }
  end

  defp plan(armed, suppressed \\ []) do
    %Plan{armed: armed, suppressed: suppressed, platform: :android, now: @now, zone: @zone}
  end

  describe "the three groups" do
    test "today and beyond split on the calendar day, not a rolling window" do
      # A reminder at 23:50 belongs to tonight, not to tomorrow — which is what
      # the header says and what a rolling 24 hours would get wrong.
      tonight = DateTime.new!(~D[2026-08-16], ~T[23:50:00], @zone)
      tomorrow = DateTime.new!(~D[2026-08-17], ~T[08:10:00], @zone)

      groups =
        Inbox.groups(plan([candidate("a", :tv, tonight), candidate("b", :meals, tomorrow)]))

      assert Enum.map(groups.now, & &1.id) == ["a"]
      assert Enum.map(groups.later, & &1.id) == ["b"]
    end

    test "held back is everything the scheduler suppressed, with its reason" do
      held = candidate("c", :tv, nil, suppressed: :muted)

      groups = Inbox.groups(plan([], [held]))

      assert Enum.map(groups.held, & &1.id) == ["c"]
      assert Inbox.held_reason(:muted) == "Muted for this show"
    end

    test "every suppression reason has words, including one nobody planned for" do
      for reason <- [:muted, :quiet_hours, :budget, :digest, :skipped, nil] do
        assert is_binary(Inbox.held_reason(reason))
        assert Inbox.held_reason(reason) != ""
      end

      # An atom this module has never seen still reads as English rather than
      # as `:some_new_reason`.
      assert Inbox.held_reason(:some_new_reason) == "Some new reason"
    end
  end

  describe "the badge" do
    test "counts today only" do
      # A badge counting everything Kati will ever tell you is a number that
      # never goes down, and a badge you cannot clear is one people learn to
      # ignore.
      today = DateTime.new!(~D[2026-08-16], ~T[18:00:00], @zone)
      next_week = DateTime.new!(~D[2026-08-23], ~T[18:00:00], @zone)

      assert Inbox.badge(plan([candidate("a", :tv, today), candidate("b", :tv, next_week)])) == 1
    end

    test "an empty plan has no badge" do
      assert Inbox.badge(plan([])) == 0
    end
  end

  describe "aggregation by section" do
    test "every budget domain gets a row, including the ones with no source" do
      # `Nothing today` is an answer; an absent row is not. Reading the budget's
      # own domain list is what guarantees it — a domain added there appears
      # here the same day.
      rows = Inbox.by_domain(plan([candidate("a", :tv, @now)]))

      assert length(rows) == length(Budget.domains())
      assert Enum.map(rows, &elem(&1, 0)) == Budget.domains()

      counts = Map.new(rows, fn {domain, count, _limit} -> {domain, count} end)
      assert counts[:tv] == 1
      assert counts[:meals] == 0
    end

    test "each row carries the section's real share of the phone's alarms" do
      # The same figure the scheduler sheds against — so a section that is full
      # says so here before a reminder goes missing.
      rows = Inbox.by_domain(plan([]))

      for {domain, _count, limit} <- rows do
        assert limit == Budget.limit(:android, domain)
      end
    end

    test "a section with nothing armed says so rather than showing a fraction" do
      assert InboxNotifications.usage_line(0, 24) == "Nothing today"
      assert InboxNotifications.usage_line(2, 24) == "2 of 24 slots"
    end

    test "sections are named in Kati's own vocabulary, not the budget's atoms" do
      assert Inbox.domain_label(:tv) == "Screen"
      assert Inbox.domain_label(:calendar) == "Calendar"
    end
  end

  describe "a candidate with no copy" do
    test "still gets a row rather than an empty one" do
      # `Kati.Notifications.Candidate` makes `title` nullable because the
      # scheduler's job is *when*, not *what*. The inbox is the one place that
      # has to print something anyway.
      assert Inbox.title(candidate("a", :meals, @now)) == "Meals reminder"
      assert Inbox.title(candidate("a", :meals, @now, title: "Dal, 19:00")) == "Dal, 19:00"
    end
  end

  describe "the inbox screen" do
    test "an empty inbox invites rather than apologises" do
      tree = tree(mount_screen(InboxNotifications))

      assert find(tree, :text, text: "Nothing waiting") != nil

      assert find(tree, :text,
               text:
                 "Kati is quiet unless you ask it not to be. Turn a reminder on and it " <>
                   "will show up here first, before it ever interrupts you."
             ) != nil
    end

    test "an empty group draws no eyebrow either" do
      # Three empty headings read as an app that has broken rather than as an
      # evening with nothing due.
      assert InboxNotifications.group("Now", [], :armed) == []
    end

    test "a held row has no time, because it has none" do
      # Printing the time it WOULD have had would be the page's one misleading
      # number.
      held = candidate("c", :tv, @now, suppressed: :budget)

      assert InboxNotifications.trailing(held, :held) == nil
      assert InboxNotifications.trailing(held, :armed) != nil
    end

    test "a held row's second line is the reason" do
      held = candidate("c", :tv, nil, suppressed: :quiet_hours)

      assert InboxNotifications.sub(held, :held) == "Inside quiet hours — moved to the morning"
    end

    test "the manners rows lead to the watcher and to the diagnostic" do
      view = mount_screen(InboxNotifications)

      assert navigated_to(render_info(view, {:tap, :open_watcher})) == Kati.Screens.ReleaseWatcher
      assert navigated_to(render_info(view, {:tap, :open_diagnostic})) == NotificationsHelp
    end

    test "it renders a tree the native layer can take" do
      assert_renderable(mount_screen(InboxNotifications))
    end
  end

  describe "the diagnostic" do
    test "what Kati decided comes before what the phone decided" do
      # The commonest true answer is *you did not turn any on*, and a page that
      # opened with permissions would teach the user to blame the phone for a
      # setting.
      texts =
        mount_screen(NotificationsHelp)
        |> tree()
        |> find_all(:text)
        |> Enum.map(&(&1.props[:text] || ""))

      kati = Enum.find_index(texts, &(&1 == "WHAT KATI DECIDED"))
      phone = Enum.find_index(texts, &(&1 == "WHAT THE PHONE DECIDED"))

      assert kati != nil and phone != nil
      assert kati < phone
    end

    test "a permission that cannot be re-prompted offers settings, not Allow" do
      # The whole reason `Kati.Permissions` distinguishes four states: once
      # Android has been told no permanently, `request/2` will not prompt, and
      # an Allow button that silently does nothing is worse than no button.
      assert Kati.Permissions.affordance(:unasked) == :allow
      assert Kati.Permissions.affordance(:blocked) == :settings

      assert NotificationsHelp.permission_tap(:granted) == nil
      assert elem(NotificationsHelp.permission_tap(:unasked), 1) == :ask
      assert elem(NotificationsHelp.permission_tap(:blocked), 1) == :open_settings
    end

    test "a granted permission says On and offers nothing" do
      assert NotificationsHelp.permission_trailing(:granted) != nil
      assert NotificationsHelp.permission_tap(:granted) == nil
    end

    test "the held-back line names the reasons rather than a bare count" do
      assert NotificationsHelp.held_line([]) == "Nothing is being held back"

      held = [candidate("a", :tv, nil, suppressed: :muted)]
      assert NotificationsHelp.held_line(held) == "1 held — muted for this show"
    end

    test "it renders a tree the native layer can take" do
      assert_renderable(mount_screen(NotificationsHelp))
    end
  end

  describe "the bell" do
    test "opens the inbox, not the gallery" do
      # It opened the gallery for as long as the gallery was the only way to
      # reach 53 screens that had landed at once. They are all reachable now.
      pushed = render_info(mount_screen(Kati.Screens.Home), {:tap, :notifications})

      assert navigated_to(pushed) == InboxNotifications
    end

    test "and the gallery moved to Settings, where a page about the app belongs" do
      assert Kati.Screens.Settings.destinations()["Every screen"] == Kati.Screens.Gallery
    end
  end
end
