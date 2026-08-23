defmodule Kati.Screens.Gallery do
  @moduledoc """
  Every screen in the app, in one list, each one tappable.

  Two jobs, and the second is why it exists at all.

  **For the owner**: a way to see every page without hunting for the tap that
  reaches each one — "let me see all different type of each page". Every drawn
  screen is listed by its design number; anything built without a drawing is
  listed under *Not yet drawn*, unnumbered, for the reason `@undrawn` gives.

  **For verification**: a screen nobody can reach cannot be checked against its
  drawing. 53 screens landed at once with no way in, and wiring every real
  entry point first would have meant weeks before any of them could be looked
  at. This makes all of them reachable in one move, so each can be compared
  now and wired into its proper place after.

  It is not a substitute for real navigation. The Settings rows must still
  push their own screens, Library's posters must still open a title. This is
  scaffolding, and `@doc false` so it never reads as part of the app.
  """
  use Kati.Screens.Pushed, back: "Home"

  alias Kati.Theme.Palette
  alias Kati.UI

  # Ordered by the design's own numbering, which is how the owner refers to
  # them and how `.scratch/design/screens/NN.html` is named.
  @screens [
    {"01", "Home", Kati.Screens.Home, :root},
    {"02", "Schedule", Kati.Screens.Calendar, :root},
    {"03", "Library", Kati.Screens.Library, :root},
    {"04", "Series detail", Kati.Screens.Series, :push},
    {"05", "New releases", Kati.Screens.Inbox, :push},
    {"06", "Add a title", Kati.Screens.AddTitle, :push},
    {"07", "Your year", Kati.Screens.Stats, :root},
    {"08", "Film detail", Kati.Screens.Film, :push},
    {"09", "A heavy day", Kati.Screens.Day, :push},
    {"10", "Up next", Kati.Screens.UpNext, :push},
    {"11", "Discover", Kati.Screens.Discover, :push},
    {"12", "Lists", Kati.Screens.Lists, :push},
    {"13", "What fits?", Kati.Screens.WhatFits, :push},
    {"14", "Series metadata", Kati.Screens.SeriesMeta, :push},
    {"15", "Activity", Kati.Screens.Activity, :push},
    {"16", "Month grid", Kati.Screens.MonthGrid, :push},
    {"17", "Week", Kati.Screens.Week, :push},
    {"18", "Quick add", Kati.Screens.QuickAdd, :push},
    {"19", "Search", Kati.Screens.Search, :push},
    {"20", "Books", Kati.Screens.Books, :push},
    {"21", "Music", Kati.Screens.Music, :push},
    {"22", "Habits", Kati.Screens.Habits, :push},
    {"23", "Subscriptions", Kati.Screens.Subscriptions, :push},
    {"24", "Settings", Kati.Screens.Settings, :push},
    {"25", "Release watcher", Kati.Screens.ReleaseWatcher, :push},
    {"26", "Pick sections", Kati.Screens.PickSections, :push},
    {"27", "States", Kati.Screens.States, :push},
    {"28", "Home, dark", Kati.Screens.HomeDark, :push},
    {"29", "Lock screen", Kati.Screens.Lock, :push},
    {"30", "Agenda", Kati.Screens.Agenda, :push},
    {"31", "Event detail", Kati.Screens.EventDetail, :push},
    {"32", "Calendars", Kati.Screens.Calendars, :push},
    {"33", "Rating", Kati.Screens.Rating, :push},
    {"34", "Season", Kati.Screens.Season, :push},
    {"35", "Series settings", Kati.Screens.SeriesSettings, :push},
    {"36", "Auto-detect", Kati.Screens.AutoDetect, :push},
    {"37", "Import", Kati.Screens.Import, :push},
    {"38", "Onboarding", Kati.Screens.Onboarding, :push},
    {"39", "Widgets", Kati.Screens.Widgets, :push},
    {"40", "Account", Kati.Screens.Account, :push},
    {"41", "Accessibility", Kati.Screens.Accessibility, :push},
    {"42", "Health", Kati.Screens.Health, :push},
    {"43", "Meals today", Kati.Screens.MealsToday, :push},
    {"44", "Meal plan", Kati.Screens.MealPlan, :push},
    {"45", "Meal", Kati.Screens.Meal, :push},
    {"46", "Meal swap", Kati.Screens.MealSwap, :push},
    {"47", "Nutrition", Kati.Screens.Nutrition, :push},
    {"48", "Shopping", Kati.Screens.Shopping, :push},
    {"49", "Plans", Kati.Screens.Plans, :push},
    {"50", "Share a plan", Kati.Screens.PlanShare, :push},
    {"51", "Meal reminders", Kati.Screens.MealReminders, :push},
    {"52", "Meals on the calendar", Kati.Screens.MealsDay, :push},
    {"53", "Language pick", Kati.Screens.LanguagePick, :push},
    {"54", "Language", Kati.Screens.Language, :push},
    {"55", "خانه", Kati.Screens.HomeFa, :push},
    {"56", "برنامه", Kati.Screens.ScheduleFa, :push},
    {"57", "کتابخانه", Kati.Screens.LibraryFa, :push},
    {"58", "سریال", Kati.Screens.SeriesFa, :push},
    {"59", "امروز", Kati.Screens.TodayFa, :push},
    {"60", "وعده‌ها", Kati.Screens.MealsMatrixFa, :push},
    {"61", "آمار", Kati.Screens.StatsFa, :push},
    {"62", "تنظیمات", Kati.Screens.SettingsFa, :push},
    {"66", "Book detail", Kati.Screens.BookDetail, :push},
    {"70", "Log progress", Kati.Screens.LogProgress, :push},
    {"73", "Log a listen", Kati.Screens.LogListen, :push},
    {"74", "Album detail", Kati.Screens.AlbumDetail, :push},
    {"77", "Artist detail", Kati.Screens.ArtistDetail, :push},
    {"80", "Data sources", Kati.Screens.DataSources, :push},
    {"83", "Where this comes from", Kati.Screens.Attribution, :push},
    {"92", "My services", Kati.Screens.MyServices, :push},
    {"94", "Country picker", Kati.Screens.CountryPicker, :push},
    {"104", "Goals", Kati.Screens.Goals, :push},
    {"106", "New goal", Kati.Screens.NewGoal, :push},
    {"122", "Money", Kati.Screens.Money, :push},
    {"124", "Quick add — expense", Kati.Screens.QuickAddExpense, :push},
    {"125", "Currency", Kati.Screens.Currency, :push},
    {"109", "Weight", Kati.Screens.Weight, :push},
    {"111", "Log weight", Kati.Screens.LogWeight, :push},
    {"112", "Medication", Kati.Screens.Medication, :push},
    {"116", "Meal library", Kati.Screens.MealLibrary, :push},
    {"118", "Create or edit a meal", Kati.Screens.MealEdit, :push},
    {"119", "Add an ingredient", Kati.Screens.AddIngredient, :push},
    {"98", "Your year, shared", Kati.Screens.YearShare, :push},
    {"100", "Year cards", Kati.Screens.YearCards, :push},
    {"69", "کتاب", Kati.Screens.BookDetailFa, :push},
    {"72", "ثبت پیشرفت", Kati.Screens.LogProgressFa, :push},
    {"67", "Book detail — states", Kati.Screens.BookDetailStates, :push},
    {"68", "Book detail — dark", Kati.Screens.BookDetailDark, :push},
    {"71", "Log progress — states", Kati.Screens.LogProgressStates, :push},
    {"75", "Album detail — states", Kati.Screens.AlbumDetailStates, :push},
    {"78", "Artist detail — states", Kati.Screens.ArtistDetailStates, :push},
    {"86", "Search — idle", Kati.Screens.SearchIdle, :push},
    {"88", "Scope & ranking", Kati.Screens.SearchSpec, :push},
    {"126", "Money on the calendar", Kati.Screens.MoneyDay, :push},
    {"76", "آلبوم", Kati.Screens.AlbumDetailFa, :push},
    {"79", "هنرمند", Kati.Screens.ArtistDetailFa, :push},
    {"81", "Data sources — states", Kati.Screens.DataSourcesStates, :push},
    {"82", "منابع داده", Kati.Screens.DataSourcesFa, :push},
    {"84", "Attribution — states", Kati.Screens.AttributionStates, :push},
    {"85", "منابع", Kati.Screens.AttributionFa, :push},
    {"93", "My services — nothing set up", Kati.Screens.MyServicesEmpty, :push},
    {"95", "My services — states", Kati.Screens.MyServicesStates, :push},
    {"96", "Nothing set up — knock-on", Kati.Screens.NothingSetUpKnockOn, :push},
    {"97", "سرویس‌های من", Kati.Screens.MyServicesFa, :push},
    {"99", "Your year — Books", Kati.Screens.YearShareBooks, :push},
    {"101", "Year cards — states", Kati.Screens.YearCardsStates, :push},
    {"87", "Search — typing", Kati.Screens.SearchTyping, :push},
    {"89", "Search — result states", Kati.Screens.SearchResultStates, :push},
    {"90", "جست‌وجو", Kati.Screens.SearchFa, :push},
    {"91", "Search at 235%", Kati.Screens.SearchLarge, :push},
    {"102", "Your year, shared — dark", Kati.Screens.YearShareDark, :push},
    {"103", "سال شما", Kati.Screens.YearShareFa, :push},
    {"105", "Goals — empty", Kati.Screens.GoalsEmpty, :push},
    {"110", "Weight — states", Kati.Screens.WeightStates, :push},
    {"113", "Health hub — empty", Kati.Screens.HealthEmptyStates, :push},
    {"107", "Goal states", Kati.Screens.GoalStates, :push},
    {"108", "اهداف", Kati.Screens.GoalsFa, :push},
    {"114", "Retired tile", Kati.Screens.RetiredTile, :push},
    {"117", "Meal library — empty", Kati.Screens.MealLibraryEmpty, :push},
    {"120", "Import a plan", Kati.Screens.PlanImport, :push},
    {"123", "Money — states", Kati.Screens.MoneyStates, :push},
    {"115", "سلامت", Kati.Screens.HealthFa, :push},
    {"121", "The week as an image", Kati.Screens.WeekImage, :push},
    {"127", "پول", Kati.Screens.MoneyFa, :push},
    {"63", "iOS home screen", Kati.Screens.MarkIos, :push},
    {"64", "Android home screen", Kati.Screens.MarkAndroid, :push},
    {"65", "Launch screen", Kati.Screens.LaunchScreen, :push}
  ]

  # Screens with no drawing, kept **out** of `@screens` on purpose.
  #
  # `@screens` is not a list of screens; it is the app's number → drawing
  # registry, and three readers treat an entry as the claim that
  # `.scratch/design/screens/NN.html` exists. `Kati.ScreenDesignLiteralTest`
  # pairs every entry with that file and asserts the numbers are exactly the ones
  # on disk. `Kati.ScreenEmptyDatabaseTest` asks this module whether a drawing
  # exists at all, and moves a screen out of its `@undrawn` the moment one does.
  # `bin/capture_all.py` parses this file for `{"NN", label, module, kind}` and
  # then opens the frame of that number to identify the capture. So inventing a
  # "63" for a screen the design has never contained fails the first two and
  # sends the capture harness looking for a file that is not there — the
  # opposite of making a screen capturable.
  #
  # The gallery's own job is the other one in the moduledoc — every screen in
  # the app, in one list, each one tappable, so each can be *opened and looked
  # at* — and that job never needed a number. Both of these are reached from
  # screen 24's Data group in the real app, which is where a user finds them and
  # what `Kati.SettingsDataRoutesTest` pins; this list is so that the page which
  # claims to reach every screen is not lying about two of them.
  #
  # A three-element shape, so the regex in `bin/capture_all.py` — which wants
  # four elements beginning with two digits — cannot pick these up by accident.
  # Delete an entry the moment its drawing lands, and add it to `@screens` with
  # the number it was filed under.
  @undrawn [
    {:open_undrawn_backup, "Backup", Kati.Screens.Backup},
    # The two notification screens. Neither has an artboard: the 127 drawings
    # hold screen 29 (the lock screen showing a Kati notification) and screen 25
    # (the release watcher's loudness settings) and nothing between them, and
    # #26 is a *design* ticket that names the components rather than supplying a
    # frame. Both are built from those components — settings rows with status
    # values, the tinted info footnote, screen 40's Allow treatment — and each
    # says so in its own moduledoc.
    {:open_undrawn_notifications, "Notifications", Kati.Screens.InboxNotifications},
    {:open_undrawn_notifications_help, "Why am I not getting these?",
     Kati.Screens.NotificationsHelp},
    {:open_undrawn_sync, "Sync", Kati.Screens.Sync}
  ]

  @doc false
  def screens, do: @screens

  @doc false
  def undrawn, do: @undrawn

  @doc false
  def content(_assigns) do
    # Bound to a local: inside ~MOB an `@name` means an ASSIGN, so `@screens`
    # would be read as `assigns.screens` and fail.
    count = length(@screens) + length(@undrawn)

    ~MOB"""
    <LazyList>
      {Kati.Screens.Gallery.header(count)}
      {Kati.Screens.Gallery.rows()}
      {Kati.Screens.Gallery.undrawn_rows()}
      <Spacer size={40} />
    </LazyList>
    """
  end

  @doc """
  Title, count and the first eyebrow, as one lazy item.

  Everything above the first row, kept together because it scrolls as one thing
  and composing it is not what costs anything here.
  """
  @spec header(non_neg_integer()) :: map()
  def header(count) do
    assigns = %{count: count, top: Kati.Screens.Pushed.content_top()}

    ~MOB"""
    <Column fill_width={true}>
      <Column fill_width={true} padding_left={21} padding_right={21} padding_top={@top}>
        <Text
          text="All screens"
          text_size={28}
          max_font_scale={1.6}
          font_weight="bold"
          letter_spacing={-0.03}
          text_color={:on_surface}
        />
        <Spacer size={5} />
        <Text
          text={"#{@count} pages · tap to open"}
          font_family="mono"
          text_size={11}
          text_color={Palette.muted()}
        />
        <Spacer size={20} />
        {Kati.UI.eyebrow("Every page")}
      </Column>
      {Kati.Screens.Gallery.cap()}
    </Column>
    """
  end

  @doc """
  The 4pt rounded strip that opens and closes a card of rows.

  The card used to be one `Column` with `corner_radius={20}` and 4pt of top and
  bottom padding, holding every row. That is what a `Scroll` allows and a
  `LazyList` does not: a lazy list only skips composing what it can see the
  edges of, and a single child holding 127 rows is one item, so the whole list
  composes on every frame. It measurably did — a fling through this page ANR'd
  the app on a Pixel 9a, twice, with `Input dispatching timed out` and the BEAM
  at 8% CPU, which is what a UI thread laying out ~800 nodes a frame looks like.

  So the rows became items and the card became three pieces: this strip at the
  top, square-edged rows on the same ground, and this strip again at the
  bottom. The bridge has no per-corner radius — `corner_radius_top_start` is
  not a prop `MobBridge.kt` reads — so a 4pt tall rounded box is how the cap is
  spelled, and it is exactly the 4pt padding it replaces.

  Neither the caps nor the rows carry `Kati.Theme.shadow_card/0`. One card cast
  one shadow; 131 items casting it each drew a hard grey band under every cap
  and a faint seam between every row, because a shadow that used to fall
  outside the card now falls on the item below it. A flat ground is the honest
  reading of the same card.
  """
  @spec cap() :: map()
  def cap do
    ~MOB"""
    <Column fill_width={true} padding_left={21} padding_right={21}>
      <Box fill_width={true} height={4} corner_radius={20} background={Palette.card()} />
    </Column>
    """
  end

  # One lazy item per row, not one item holding every row — see `cap/0`.
  @doc false
  def rows do
    screens = @screens
    last = length(screens) - 1

    caps =
      screens
      |> Enum.with_index()
      |> Enum.map(fn {s, i} ->
        Kati.Screens.Gallery.on_card(Kati.Screens.Gallery.row(s, i < last))
      end)

    caps ++ [Kati.Screens.Gallery.cap(), Kati.Screens.Gallery.group_gap()]
  end

  @doc "The 20pt gap that used to sit between the two cards."
  @spec group_gap() :: map()
  def group_gap do
    ~MOB"""
    <Column fill_width={true}>
      <Column fill_width={true} padding_left={21} padding_right={21}>
        <Spacer size={20} />
        {Kati.UI.eyebrow("Not yet drawn")}
      </Column>
      {Kati.Screens.Gallery.cap()}
    </Column>
    """
  end

  @doc """
  One row on the card's ground, with the page's own side margins outside it.

  The 21pt page margin was on the `Scroll`'s single `Column` and the 15pt card
  margin was on the card. A lazy item is laid out edge to edge, so both live
  here now: 21 outside the ground, 15 inside it.
  """
  @spec on_card(map()) :: map()
  def on_card(row) do
    assigns = %{row: row}

    ~MOB"""
    <Column fill_width={true} padding_left={21} padding_right={21}>
      <Column fill_width={true} background={Palette.card()} padding_left={15} padding_right={15}>
        {@row}
      </Column>
    </Column>
    """
  end

  @doc false
  def undrawn_rows do
    undrawn = @undrawn
    last = length(undrawn) - 1

    rows =
      undrawn
      |> Enum.with_index()
      |> Enum.map(fn {u, i} ->
        Kati.Screens.Gallery.on_card(Kati.Screens.Gallery.undrawn_row(u, i < last))
      end)

    rows ++ [Kati.Screens.Gallery.cap()]
  end

  # The number column holds `--` rather than a number, which is the whole fact
  # about these two rows. The tag is the entry's own atom rather than one built
  # from that marker: every tag this app draws crosses into Kotlin and back, and
  # `open_--` is not a name anyone can read in a log.
  @doc false
  def undrawn_row({tag, name, module}, rule?),
    do: Kati.Screens.Gallery.row({"--", name, module, :push}, rule?, tag)

  @doc false
  def row(entry, rule?), do: Kati.Screens.Gallery.row(entry, rule?, nil)

  @doc false
  def row({number, name, module, kind}, rule?, override) do
    tap = {self(), override || String.to_atom("open_" <> number)}

    # The idle chevron is `rail_idle`, not `tertiary`: the design draws two
    # chevron greys and this is the `0xFFC4BDB3` one — the same call
    # `Kati.UI.SettingsList.chevron/0` makes.
    tint = if kind == :root, do: Palette.accent(), else: Palette.rail_idle()

    ~MOB"""
    <Column fill_width={true} on_tap={tap}>
      <Row fill_width={true} align="center" padding_top={13} padding_bottom={13}>
        <Column width={30}>
          <Text text={number} font_family="mono" text_size={12} text_color={Palette.tertiary()} />
        </Column>
        <Spacer size={12} />
        <Column weight={1.0}>
          <Text
            text={name}
            text_size={14}
            font_weight="semibold"
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={3} />
          <Text
            text={module |> Module.split() |> List.last()}
            font_family="mono"
            text_size={10.5}
            text_color={Palette.tertiary()}
            max_lines={1}
          />
        </Column>
        <Spacer size={10} />
        {UI.symbol("chevron_right", size: 18, color: tint)}
      </Row>
      {Kati.Screens.Gallery.hairline(rule?)}
    </Column>
    """
  end

  @doc false
  def hairline(false), do: ~MOB"<Spacer size={0} />"

  def hairline(true),
    do: ~MOB"<Box fill_width={true} height={1} background={Palette.hairline()} />"

  @impl true
  def handle_tap(tag, socket) do
    case List.keyfind(@undrawn, tag, 0) do
      {_tag, _name, module} -> {:noreply, Mob.Socket.push_screen(socket, module)}
      nil -> Kati.Screens.Gallery.open_numbered(tag, socket)
    end
  end

  @doc false
  def open_numbered(tag, socket) do
    number = tag |> Atom.to_string() |> String.replace_prefix("open_", "")

    case Enum.find(@screens, fn {n, _, _, _} -> n == number end) do
      # A root is swapped rather than pushed: pushing Home over the gallery
      # would leave the dock showing Home while the back stack says otherwise.
      {_, _, module, :root} -> {:noreply, Mob.Socket.reset_to(socket, module)}
      {_, _, module, :push} -> {:noreply, Mob.Socket.push_screen(socket, module)}
      nil -> {:noreply, socket}
    end
  end
end
