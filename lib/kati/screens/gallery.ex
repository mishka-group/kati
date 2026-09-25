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
  use Gettext, backend: Kati.Gettext

  alias Kati.Theme.Palette
  alias Kati.UI

  # Ordered by the design's own numbering, which is how the owner refers to
  # them and how `test/design/screens/NN.html` is named.
  #
  # The labels are NOT wrapped in `gettext/1`, and the reason is the one that
  # keeps `TMDB` in Latin on a Persian page: each is the NAME OF A DRAWING —
  # *Search — idle*, *Anime — a type, not a section* — rather than a sentence
  # the app says to a reader. A person looking for board 86 is looking for what
  # `test/design/screens/86.html` is called, and a msgid per row would spell one
  # artefact two ways. `Kati.ScreenDesignLiteralTest` reads this table as the
  # number → drawing registry rather than as copy, which is the same fact from
  # the other side. `@undrawn` below is the same decision for the ten rows that
  # have no drawing to be named after: they are the module's own name in the
  # index, and both tables are ATTRIBUTES — a `gettext/1` in one would be
  # evaluated once, at compile time, in whatever locale the compiler was in.
  #
  # That the Persian labels below stay Persian in an ENGLISH app is the same
  # rule read the other way: a board drawn in Persian is named in Persian
  # whoever is reading. `face/1` sets each label in the script it is written
  # in; only the page's own chrome — the title, the count and the two eyebrows
  # — follows the reader.
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
    # 55 was `Kati.Screens.HomeFa` until mishka-group/kati#103 folded that
    # mirror away — the last of the four Persian roots. It is screen 01 read
    # under `:fa`, with "55" on `Kati.ScreenDesignLiteralTest`'s `@fa_screens`.
    {"55", "خانه", Kati.Screens.Home, :push},
    # 56 was `Kati.Screens.ScheduleFa` until mishka-group/kati#103 folded that
    # mirror away. It is screen 02 read under `:fa`, with "56" on
    # `Kati.ScreenDesignLiteralTest`'s `@fa_screens`.
    {"56", "برنامه", Kati.Screens.Calendar, :push},
    # 57 was `Kati.Screens.LibraryFa` until mishka-group/kati#103 folded that
    # mirror away. It is screen 03 read under `:fa`, with "57" on
    # `Kati.ScreenDesignLiteralTest`'s `@fa_screens`.
    {"57", "کتابخانه", Kati.Screens.Library, :push},
    # mishka-group/kati#103's fold of screen 58. Board 58 is screen 04 under
    # `:fa`, with "58" on `Kati.ScreenDesignLiteralTest`'s `@fa_screens`.
    {"58", "سریال", Kati.Screens.Series, :push},
    # mishka-group/kati#103. Board 59 is screen 43 under `:fa`.
    {"59", "امروز — Meals today, RTL", Kati.Screens.MealsToday, :push},
    {"60", "وعده‌ها", Kati.Screens.MealPlan, :push},
    # 61 was `Kati.Screens.StatsFa` until mishka-group/kati#103 folded that
    # mirror away. It is screen 07 read under `:fa`, with "61" on
    # `Kati.ScreenDesignLiteralTest`'s `@fa_screens`.
    {"61", "آمار", Kati.Screens.Stats, :push},
    # mishka-group/kati#103's fold of screen 62. Board 62 is screen 24 under
    # `:fa`, with "62" on `Kati.ScreenDesignLiteralTest`'s `@fa_screens`.
    {"62", "تنظیمات — Settings, RTL", Kati.Screens.Settings, :push},
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
    # mishka-group/kati#103's fold of screen 69. Board 69 is screen 66 under
    # `:fa`, with "69" on `Kati.ScreenDesignLiteralTest`'s `@fa_screens`.
    {"69", "کتاب — Book detail, RTL", Kati.Screens.BookDetail, :push},
    # mishka-group/kati#103's fold of screen 72. Board 72 is screen 70 under
    # `:fa`, with "72" on `Kati.ScreenDesignLiteralTest`'s `@fa_screens`.
    {"72", "ثبت پیشرفت — Log progress, RTL", Kati.Screens.LogProgress, :push},
    {"67", "Book detail — states", Kati.Screens.BookDetailStates, :push},
    {"68", "Book detail — dark", Kati.Screens.BookDetailDark, :push},
    {"71", "Log progress — states", Kati.Screens.LogProgressStates, :push},
    {"75", "Album detail — states", Kati.Screens.AlbumDetailStates, :push},
    {"78", "Artist detail — states", Kati.Screens.ArtistDetailStates, :push},
    {"86", "Search — idle", Kati.Screens.SearchIdle, :push},
    {"88", "Scope & ranking", Kati.Screens.SearchSpec, :push},
    {"126", "Money on the calendar", Kati.Screens.MoneyDay, :push},
    # mishka-group/kati#103's fold of screen 76. Board 76 is screen 74 under
    # `:fa`, with "76" on `Kati.ScreenDesignLiteralTest`'s `@fa_screens`.
    {"76", "آلبوم", Kati.Screens.AlbumDetail, :push},
    # mishka-group/kati#103. Board 79 is screen 77 under `:fa`.
    {"79", "هنرمند — Artist detail, RTL", Kati.Screens.ArtistDetail, :push},
    {"81", "Data sources — states", Kati.Screens.DataSourcesStates, :push},
    # mishka-group/kati#103's fold of screen 82. Board 82 is screen 80 under
    # `:fa` now, exactly as 85, 97 and 156 are their own English screens, and
    # "82" is on `Kati.ScreenDesignLiteralTest`'s `@fa_screens` so the sweep
    # renders it in the locale it is drawn in.
    {"82", "منابع داده — Data sources, RTL", Kati.Screens.DataSources, :push},
    {"84", "Attribution — states", Kati.Screens.AttributionStates, :push},
    # mishka-group/kati#103. Board 85 is screen 83 in the mirror, and 83 IS the
    # mirror now — the same module rendered under `:fa`, exactly as 154/156.
    {"85", "منابع — Where this comes from, RTL", Kati.Screens.Attribution, :push},
    {"93", "My services — nothing set up", Kati.Screens.MyServicesEmpty, :push},
    {"95", "My services — states", Kati.Screens.MyServicesStates, :push},
    {"96", "Nothing set up — knock-on", Kati.Screens.NothingSetUpKnockOn, :push},
    # mishka-group/kati#103. Board 97 is screen 92 under `:fa`.
    {"97", "سرویس‌های من — My services, RTL", Kati.Screens.MyServices, :push},
    {"99", "Your year — Books", Kati.Screens.YearShareBooks, :push},
    {"101", "Year cards — states", Kati.Screens.YearCardsStates, :push},
    {"87", "Search — typing", Kati.Screens.SearchTyping, :push},
    {"89", "Search — result states", Kati.Screens.SearchResultStates, :push},
    # mishka-group/kati#103's fold of screen 90. Board 90 is screen 19 under
    # `:fa`, with "90" on `Kati.ScreenDesignLiteralTest`'s `@fa_screens`.
    {"90", "جست‌وجو", Kati.Screens.Search, :push},
    {"91", "Search at 235%", Kati.Screens.SearchLarge, :push},
    {"103", "سال شما", Kati.Screens.YearShare, :push},
    {"105", "Goals — empty", Kati.Screens.GoalsEmpty, :push},
    {"110", "Weight — states", Kati.Screens.WeightStates, :push},
    {"113", "Health hub — empty", Kati.Screens.HealthEmptyStates, :push},
    {"107", "Goal states", Kati.Screens.GoalStates, :push},
    # mishka-group/kati#103. Board 108 is screen 104 under `:fa`.
    {"108", "اهداف — Goals, RTL", Kati.Screens.Goals, :push},
    {"114", "Retired tile", Kati.Screens.RetiredTile, :push},
    {"117", "Meal library — empty", Kati.Screens.MealLibraryEmpty, :push},
    {"120", "Import a plan", Kati.Screens.PlanImport, :push},
    {"123", "Money — states", Kati.Screens.MoneyStates, :push},
    # mishka-group/kati#103. Board 115 is the one board in the app that draws
    # TWO screens on one page: screen 109's weight half above screen 112's
    # medication half. The app does not have such a page and is not gaining
    # one — the ruling is that a Persian reader gets the same screens an
    # English one does — so the board is registered against the half it leads
    # with, and the medication half's lines are recorded in
    # `DesignLiterals.retired_lines/0` against board 112, which draws them.
    {"115", "سلامت — Weight, RTL", Kati.Screens.Weight, :push},
    {"121", "The week as an image", Kati.Screens.WeekImage, :push},
    # mishka-group/kati#103. Board 127 is screen 122 under `:fa`.
    {"127", "پول — Money, RTL", Kati.Screens.Money, :push},
    {"65", "Launch screen", Kati.Screens.LaunchScreen, :push},
    # #25 — backup and restore, the two screens three others had been promising.
    {"128", "Back up everything", Kati.Screens.Backup, :push},
    {"129", "Restore from a backup", Kati.Screens.Restore, :push},
    {"130", "Backup & restore — states", Kati.Screens.BackupStates, :push},
    {"131", "Back up everything — dark", Kati.Screens.BackupDark, :push},
    # mishka-group/kati#103. Board 132 is screen 129 under `:fa`.
    {"132", "بازگردانی — Restore from a backup, RTL", Kati.Screens.Restore, :push},
    {"133", "Back up & restore at 235%", Kati.Screens.BackupLarge, :push},
    # #11 — the first run. 134 is the flow map and is deliberately absent from
    # this list: it is a diagram at 1720px rather than a 402x874 screen, it has
    # no `IOSDevice` frame to render, and there is nothing in the app for it to
    # be. It lives in `test/design/reference/134.html` as the design record,
    # and what it decides — the resume rule, 38's numbering correspondence — is
    # carried by the screens below rather than by a screen of its own.
    {"135", "Restore — first run", Kati.Screens.RestoreFirstRun, :push},
    {"136", "Loudness → the OS prompt", Kati.Screens.LoudnessPrompt, :push},
    {"137", "راه‌اندازی", Kati.Screens.PickSections, :push},
    {"138", "Onboarding at 235%", Kati.Screens.OnboardingLarge, :push},
    {"139", "Home — nothing set up", Kati.Screens.HomeEmpty, :push},
    # #12 — the importer's step 0, so a switcher is not asked to map nine
    # columns before seeing a row of their own data arrive.
    {"140", "Import — where are you coming from", Kati.Screens.ImportSources, :push},
    {"141", "Import — recognised", Kati.Screens.ImportRecognised, :push},
    {"142", "Import — source states", Kati.Screens.ImportStates, :push},
    # #15 — per-episode rating.
    {"143", "Episode rows — the rating column", Kati.Screens.EpisodeRatings, :push},
    {"144", "Rate an episode", Kati.Screens.RateEpisode, :push},
    # #19 — the shelves' escalation, above the four tabs that stay the default.
    {"145", "Shelf filter sheet", Kati.Screens.ShelfFilters, :push},
    {"146", "Shelf — selection mode", Kati.Screens.ShelfSelection, :push},
    {"147", "Selection & filters at 235%", Kati.Screens.ShelfLarge, :push},
    # #17 — one state machine for three media.
    {"148", "Drop, DNF & abandon", Kati.Screens.DropStates, :push},
    {"149", "Dropping — the sheet and after", Kati.Screens.DropSheet, :push},
    # #20 — the music half of auto-detect.
    {"150", "Auto-detect — music", Kati.Screens.AutoDetectMusic, :push},
    {"151", "Notification access", Kati.Screens.NotificationAccess, :push},
    # #21 — anime as a type rather than a section.
    {"152", "Anime — a type, not a section", Kati.Screens.AnimeFilter, :push},
    {"153", "Numbering — inherited and overridden", Kati.Screens.NumberingScheme, :push},
    {"154", "Add a title by hand", Kati.Screens.AddByHand, :push},
    {"155", "Add by hand — resting & refused", Kati.Screens.AddByHandStates, :push},
    # mishka-group/kati#103's first fold. Board 156 is screen 154 in the mirror,
    # and 154 IS the mirror now — the same module rendered under `:fa`. So the
    # board keeps its number and its row, and points at the English screen,
    # with "156" added to `Kati.ScreenDesignLiteralTest`'s `@fa_screens` so the
    # sweep renders it in the locale it is drawn in.
    {"156", "افزودن دستی — Add by hand, RTL", Kati.Screens.AddByHand, :push},
    # 158 is board 139 read under `:fa`; 159 is the same page in dark, which is
    # a colourway rather than a mirror and so keeps a module of its own —
    # the relation 28 has to 01.
    {"158", "خانه — nothing stored, RTL", Kati.Screens.HomeEmpty, :push},
    {"159", "خانه — nothing stored, dark RTL", Kati.Screens.HomeEmptyDark, :push},
    {"160", "The two empty sections — omitted, decided", Kati.Screens.HomeOmittedSections, :push},
    {"161", "Welcome — step 2 of 5", Kati.Screens.OnboardingWelcome, :push},
    {"162", "Loudness — step 4 of 5", Kati.Screens.OnboardingLoudness, :push},
    {"163", "First title — step 5 of 5", Kati.Screens.OnboardingFirstTitle, :push},
    {"164", "خوش‌آمد — welcome, RTL", Kati.Screens.OnboardingWelcome, :push},
    {"165", "اعلان‌ها — loudness, RTL", Kati.Screens.OnboardingLoudness, :push},
    {"166", "اولین عنوان — first title, RTL", Kati.Screens.OnboardingFirstTitle, :push},
    {"157", "Add by hand — dark", Kati.Screens.AddByHandDark, :push},
    # #D-38 — the shelf, and how a book reaches it, in both languages. 176 is
    # the destination screen 57's کتاب‌ها segment has never had; 177 is the only
    # control in the app that creates a `Kati.Books.Book`.
    # mishka-group/kati#103's fold of screen 176. Board 176 is screen 20 under
    # `:fa`, with "176" on `Kati.ScreenDesignLiteralTest`'s `@fa_screens`.
    {"176", "کتاب‌ها — the Persian Books shelf", Kati.Screens.Books, :push},
    {"177", "Add by hand — Book", Kati.Screens.AddByHandBook, :push},
    # D-43 — the three boards that let a medication be owned rather than only
    # read. 188 is the sheet behind screen 112's `add` disc, 189 the page
    # behind its four chevrons, and 190 the empty frame `D-19-medication.md`
    # asked for in 2026 and nobody drew.
    {"188", "Add a medication", Kati.Screens.AddMedication, :push},
    {"189", "One medication", Kati.Screens.MedicationDetail, :push},
    {"190", "Medication — empty and annotated", Kati.Screens.MedicationEmpty, :push},
    # D-39 — the read-only music shelf gets a way in, and a way to rate what is
    # already there. 178 and 179 are the add path: nothing in `lib/` wrote a
    # `Kati.Music.Album` before them, so screen 21 was permanently on its
    # fixture. 180 is the album rating sheet screen 74's Rate row had been
    # pushing screen 33's film sheet for.
    {"178", "Add by hand — a record", Kati.Screens.AddByHandRecord, :push},
    {"179", "Add a title — the music state", Kati.Screens.AddTitleMusic, :push},
    {"180", "Rate an album", Kati.Screens.RateAlbum, :push},
    # D-46 — the sort disc on screen 10 stopped opening screen 03's sheet.
    # Board 167 is 145's chrome with Up next's vocabulary; 168 stays in
    # `incoming/` because it is a state catalogue rather than an artboard.
    {"167", "Up next sort & filter", Kati.Screens.UpNextFilters, :push}
  ]

  # Screens with no drawing, kept **out** of `@screens` on purpose.
  #
  # `@screens` is not a list of screens; it is the app's number → drawing
  # registry, and two readers treat an entry as the claim that
  # `test/design/screens/NN.html` exists. `Kati.ScreenDesignLiteralTest`
  # pairs every entry with that file and asserts the numbers are exactly the ones
  # on disk. `Kati.ScreenEmptyDatabaseTest` asks this module whether a drawing
  # exists at all, and moves a screen out of its `@undrawn` the moment one does.
  # `Kati.ScreenTitleSubtitleTest` parses the same file by number as well, but
  # reads a missing one as nothing to compare rather than as a failure, so it is
  # the first two that a lie here actually breaks. There used to be a third
  # asserting reader outside Elixir — the capture harness parsed this file for
  # `{"NN", label, module, kind}` and opened the frame of that number to label
  # each shot — and it is deleted along with the rest of the device tooling, for
  # the reasons `docs/DESIGN-ASSETS.md` sets out. So inventing a number for a
  # screen the design has never contained fails both of the readers that are
  # left, and it was never what made a screen reachable in the first place.
  #
  # The gallery's own job is the other one in the moduledoc — every screen in
  # the app, in one list, each one tappable, so each can be *opened and looked
  # at* — and that job never needed a number. Both of these are reached from
  # screen 24's Data group in the real app, which is where a user finds them and
  # what `Kati.SettingsDataRoutesTest` pins; this list is so that the page which
  # claims to reach every screen is not lying about two of them.
  #
  # Three elements rather than four, because there is no number to put in the
  # fourth slot: an entry here is a tag, a name and a module, and `undrawn_row/2`
  # supplies the `"--"` marker at the point of drawing rather than storing a
  # number the design has never issued. The shape used to be argued for on a
  # second ground as well — the capture script's regex wanted four elements
  # beginning with two digits, so a three-element entry could not be swept up as
  # a numbered screen by accident — and that half of the argument is a leftover
  # now that the script is gone. What pins the shape today is the Elixir that
  # destructures it: `handle_tap/2` and `undrawn_row/2` below, and the tag check
  # in `Kati.ScreenDesignLiteralTest`.
  #
  # Delete an entry the moment its drawing lands, and add it to `@screens` with
  # the number it was filed under.
  @undrawn [
    # Board 267 — Clear watch history. A states board (the page and its
    # confirmation in one frame), so it has no artboard the literal sweep can
    # compare it against; it is reached from Settings → Data → Clear watch
    # history, which is the row that opened nothing until it was built.
    {:open_undrawn_clear_history, "Clear watch history", Kati.Screens.ClearHistory},
    # Boards 252 and 302 — one service. Reached from My services, by tapping a
    # service. It drops the three groups those boards draw and this device
    # cannot answer, so no artboard holds what it renders.
    {:open_undrawn_service, "One service", Kati.Screens.Service},
    # Board 169 — Discover's Sort & filter sheet. Six of its eleven controls
    # cannot be answered by any TMDB field and its eight count badges are one
    # request each, so the page draws its buildable half and no artboard holds
    # what it renders. `Kati.Discover.Filters` names each omission with the
    # reason. Reached from Discover's `sort` disc; here so the one list that
    # opens every screen can open this one.
    {:open_undrawn_discover_filters, "Discover sort & filter", Kati.Screens.DiscoverFilters},
    # `Kati.Screens.Backup` left this list on 24 August: #25's drawings landed
    # as 128-133 and it is filed under 128 above, which is the move this
    # comment describes. `Kati.Screens.Sync` is still here — #54's screen has
    # no artboard in the 152.
    #
    # The two notification screens. Neither has an artboard: the 127 drawings
    # hold screen 29 (the lock screen showing a Kati notification, since
    # retired to `test/design/retired/`) and screen 25 (the release watcher's
    # loudness settings) and nothing between them, and
    # #26 is a *design* ticket that names the components rather than supplying a
    # frame. Both are built from those components — settings rows with status
    # values, the tinted info footnote, screen 40's Allow treatment — and each
    # says so in its own moduledoc.
    {:open_undrawn_notifications, "Notifications", Kati.Screens.InboxNotifications},
    {:open_undrawn_notifications_help, "Why am I not getting these?",
     Kati.Screens.NotificationsHelp},
    {:open_undrawn_sync, "Sync", Kati.Screens.Sync},
    # The two Lists screens. Boards 330-333 and 335 draw them and arrived on
    # 7 September, so neither is undrawn any more — what they are is drawn by a
    # STATE CATALOGUE: 330 stacks the resting page, an open menu, a confirmation
    # and an undo bar in one frame, and 333 is 1249pt of states in an 806pt
    # sheet. Neither is a state a screen is ever in, so neither board can be
    # compared literal-for-literal against a render, and both stay here until a
    # specimen screen per board is built the way 155 was for 154.
    #
    # Both are reachable from the app: `ListDetail` from screen 12's rows, and
    # `AddToList` from the *Add to list* control on 08, 04, 66, 68, 74, 76 and
    # 146. They are here because the one list that checks every screen has to be
    # able to open them. MOVIES-AND-TV.md #106.
    {:open_undrawn_list_detail, "One list", Kati.Screens.ListDetail},
    {:open_undrawn_add_to_list, "Add to list", Kati.Screens.AddToList},
    # Boards 336 and 337 were two more rows here, opening two more modules.
    # mishka-group/kati#103 folded both mirrors into the two screens above, so
    # the rows would open the same module twice and are gone. The boards are
    # 12 and 182 under `:fa`.
    # Board 328's screen, and 328 is a state catalogue too — the summary row in
    # both locales, the screen behind it, and the defect it replaces, in one
    # frame. It IS reachable, from 140's own summary row; it is here because the
    # one list that checks every screen has to be able to open it.
    {:open_undrawn_more_sources, "Four more sources", Kati.Screens.MoreSources},
    # Board 114. Screen 42's two dashed tiles, board 320's retired Hardcover row
    # and the three importers `Kati.Sources.refused/0` names have all drawn *tap
    # to see why* with nothing behind it since they were written; this is the
    # screen that was missing. Reachable from 80 and 82, and here for the same
    # reason as its neighbours.
    {:open_undrawn_retired_reason, "Why not in v1", Kati.Screens.RetiredReason},
    # No board. Board 24 draws a Privacy row that opened nothing; this is
    # the page it opens now, built from the settings list's own parts. Reached
    # from Settings → About → Privacy; here for the same reason as the rest.
    {:open_undrawn_privacy, "Privacy", Kati.Screens.Privacy}

    # Board 301, the Persian country sheet, was here and is not any more.
    # mishka-group/kati#103 folded `Kati.Screens.CountryPickerFa` into screen
    # 94, and 94 has a drawing — so the module stopped being undrawn and this
    # list is only for the ones that are not. 301 itself lives in
    # `test/design/incoming/` and is a sheet drawn beside three notes rather
    # than a numbered artboard; it is board 94 under `:fa` now.
  ]

  # Numbers whose page has left this list, and the route that took it.
  #
  # The owner's rule, in his own words: *"each screen we did and connected in
  # our pages must be deleted in Every screen in settings — its routing not
  # there, it must have its own routing from the actual app."* A page that a
  # user reaches by going where the page lives is finished with this
  # scaffolding, and leaving it here invites the next person to check it from
  # the wrong door.
  #
  # It leaves the LIST, not the registry. `screens/0` still answers with every
  # number, because three sweeps read it as the app's number → drawing map —
  # `Kati.ScreenDesignLiteralTest` pairs each with `test/design/screens/NN.html`,
  # `Kati.ScreenEmptyDatabaseTest` asks it whether a drawing exists, and
  # `Kati.AppReachabilityTest` walks it to ask whether a user can get there.
  # Deleting the tuple would quietly delete all three checks, which is the
  # opposite of finishing a page.
  #
  # A number goes here when both halves of MOVIES-AND-TV.md's rule are true:
  # a real route in, and every scenario under it passing on the device. The
  # commit that retires it says which route was walked.
  @routed [
    # Series → ⋯ → Show details. 5915c2a.
    "14",
    # Series → ⋯ → Show settings, which now carries the show it was opened
    # over. The walk is a test now rather than a memory of one:
    # `SeriesSettingsTest` in `android/app/src/androidTest/` drives the ⋯ menu,
    # taps the Status tiles and all four season-pass switches, and reads each
    # write back out of `kati.db` — including after a pop and a return, which
    # is the half a socket assign would otherwise fake.
    "35",
    # 92 My services → the country row, and 93 → Pick your country. Verified
    # when `Kati.Screens.Resume` made the page behind it re-read.
    "94",
    # Series → an episode's rating column. e44d44d, which built that column.
    "144",
    # Library → ⋯ → Select titles. c946a49.
    "146",
    # ── Retired 7 September, at the end of the MOVIES-AND-TV pass. Every one
    # was walked on the Pixel_9a in the commit that closed its finding, and
    # the route is named beside it.
    #
    # Settings → New releases. #1 — this page had no English door at all
    # until that row: its only one was Home's hero, which is omitted when
    # there is nothing out this week, so the page that says so was the page
    # you could not reach.
    "05",
    # Library → Up next. #49 — an empty shelf drew the board's four invented
    # titles; it draws its own empty card now.
    "10",
    # Library → Lists. #106 — the lists are the reader's, `+` makes one that
    # survives the pop, and a row opens it.
    "12",
    # Library → ⋯ → What fits? #88 wired its window; #120 put board 96's band
    # over the count.
    "13",
    # Stats → Activity log. #112 — the `Added` chip finds real rows, and a
    # chip that matches nothing says which.
    "15",
    # Home → the search field. #114, #117, #129, #130, #131 — the fields it
    # names are searched, and narrowing to an empty scope says where the
    # answer is.
    "19",
    # 92 My services → the Money row. #120 — board 96's empty ledger is what a
    # device with no service draws.
    "23",
    # Settings → Release watcher, and Home → the bell. #67 — the cadence and
    # *New episodes* are read by something; the rest carry `not yet`.
    "25",
    # Series → ⋯ → Episode order. #34's ticks write, the order strip reorders,
    # and #9's help disc explains the choice.
    "34",
    # Settings → Import → a source tile → Check the mapping. #101 built the
    # importer; #4 made 141 say when a file cannot be read.
    "37",
    # Home → My services, and Settings → My services. #118, #119 — the field
    # filters, every row has a switch, and a price can be corrected.
    "92",
    # Settings → Import. #52 sends each tile to the right board; #126 made the
    # *Four more sources* row open the picker.
    "140",
    # 140 → a source tile → pick a file. #4 — the three edge states board 142
    # draws are what a real file produces now.
    "141",
    # Series → ⋯ → Drop this show, and Film → ⋯ → Drop this film. #110, #111,
    # #127 — a film can be dropped, the reason is kept, and the position pill
    # goes both ways.
    "149",
    # Season → the help disc beside the order strip. #9.
    "153",
    # ("101" was here — Settings → Year cards → When a card cannot be made. The
    # Settings row it hung off is gone: screen 100 is a render spec, not a place
    # in the app. Both are back on the gallery, which is where a spec belongs.
    # "148" and "152" went the same way the round after, and for the same
    # reason: both were argued from their own back pills saying `Settings`, and
    # both argue for features that now live where a reader meets them — the ⋯
    # anime toggle and the Library chip, the shelf's own paused/dropped/cold
    # marks and the drop sheet behind them.)
    # ── The four dock roots, and the hub in one of them. The owner's words:
    # *"01 - Home exist in the first page of app, no need in all screens, and
    # Library menu exists in the dock on all pages — no need again inside All
    # screens."* A page you land on when the app opens cannot be checked from
    # anywhere else, and listing it here is a door beside a doorway.
    "01",
    "02",
    "03",
    "07",
    # Home → Settings. The hub every Settings row below is reached through.
    "24",
    # ── The Movies and TV pages, each in its own place in the app.
    #
    # Library → a series poster. The page a season strip, an episode list, a
    # tick and a rating all hang off.
    "04",
    # Any dock root → the `+` FAB.
    "06",
    # Library → a film poster.
    "08",
    # Library → Discover.
    "11",
    # Film → Log a watch, and Series → an episode's rating column.
    "33",
    # Settings → Auto-detect.
    "36",
    # Settings → Auto-detect → This phone (auto_detect.ex:897,1197). N22 — it
    #   draws the one card for the phone's own grant, not the board's four.
    "151",
    # Home → the search field, which opens idle before a query exists.
    "86",
    # 86 → the tune disc. #131 made its back pill name the page it returns to.
    "88",
    # Stats → the share disc. #3 gave it board 102's two missing card faces.
    "98",
    # ("100" was here — Settings → Year cards. Removed with the row; see the
    # note beside "101" above.)
    # Library → the sort disc. #109 settled that as the one door.
    "145",
    # Up next → the tune disc. Board 167 is what that disc opens now; it used
    # to push 145, which sorts by keys this page does not have.
    "167",
    # Home → `+` → Can't find it? Add it by hand. #113 made its Kind
    # correctable and its duplicate guard match on the name.
    "154",
    # Home with nothing stored — board 139 is what Home draws on a fresh
    # install, and a fresh install is how you reach it.
    "139",
    # ── Retired in the same pass, once every remaining row had been checked
    # for a real door. The route beside each is the one a person walks; a
    # 12-agent survey found them and `Kati.AppReachabilityTest` proves them,
    # because a number here with no route in makes that test fail.
    #
    # What is LEFT in the list after this is what the list is for: reference
    # sheets in screen 27's manner, dark and 235% colourways of pages that are
    # themselves reachable, the launch screen, and the state boards. (The
    # lock-screen and two home-screen marks, 29, 63 and 64, are deleted; their
    # boards are in `test/design/retired/`.) Not one of them is a page of the app.
    # ── The calendar pages. Reached from the Schedule tab, its ⋯ and its own rows.
    # Calendar → a second tap on the already-selected day cell
    #   (calendar.ex:1351); also the Day segment of the view switcher.
    "09",
    # Calendar → the month name at the top of the page (calendar.ex:1262).
    "16",
    # Calendar → month name → Month grid → the Week segment of the view
    #   switcher (view_switcher.ex:137,154).
    "17",
    # Calendar → ⋯ → Quick add (calendar.ex:1272); also Film → ⋯ → Schedule
    #   watch.
    "18",
    # Calendar → ⋯ → Agenda (calendar.ex:1270); also the Agenda segment of the
    #   view switcher.
    "30",
    # Calendar → a personal event row in the day timeline
    #   (calendar.ex:1237,1417); also Home and Day.
    "31",
    # Settings → Sources → Calendars (settings.ex:683,846).
    "32",
    # ── The Books shelf and what hangs off it. Library → the Books segment.
    # Library → the Books segment of the shelf switcher (library.ex:1702).
    "20",
    # Library → Books → a book cover or the Reading-now hero
    #   (books.ex:984,1109); also after a by-hand save.
    "66",
    # Library → Books → Log progress on the Reading-now hero, or the timer
    #   disc (books.ex:950,976); also Book detail.
    "70",
    # Library → Books → the + FAB, which the Books shelf overrides to the by-
    #   hand book form (books.ex:105; root.ex:232).
    "177",
    # ── The Music shelf and what hangs off it. Library → the Music segment.
    # Library → the Music segment of the shelf switcher (library.ex:1705);
    #   also from Books.
    "21",
    # Library → Music → an album tile → Log a listen (album_detail.ex:914).
    "73",
    # Library → Music → an album tile (music.ex:1051); also Artist detail's
    #   album rail.
    "74",
    # Library → Music → a row in the releases band (music.ex:1071); also Album
    #   detail's artist row.
    "77",
    # Settings → Auto-detect → the Music half of the segmented control, or its
    #   Music tile (auto_detect.ex:889,987).
    "150",
    # Library → Music → + → Can't find it? Add it by hand
    #   (add_title_music.ex:435,614); also the Album/Artist chip on 177.
    "178",
    # Library → Music → the + FAB, which the Music shelf overrides
    #   (music.ex:1089; root.ex:232).
    "179",
    # Library → Music → an album tile → Rate (album_detail.ex:52,945).
    "180",
    # ── The meal pages. Home → Meals, and the tiles on the day.
    # Home → the Meals tile (home.ex:1372); also Health → the Meals card.
    "43",
    # Meals today → the Week tile, or the calendar_view_week disc
    #   (meals_today.ex:1377,1382).
    "44",
    # Meals today → any meal card on the day's timeline
    #   (meals_today.ex:1220,1481).
    "45",
    # Meals today → a meal card's Swap button (meals_today.ex:1200,1419); also
    #   Meal → the swap disc.
    "46",
    # Meals today → the Nutrition tile (meals_today.ex:1432).
    "47",
    # Meals today → the Shop tile (meals_today.ex:1386).
    "48",
    # Meals today → the Plan tile or the plan-name pill
    #   (meals_today.ex:1438,1441); also Meal plan → the edit disc.
    "49",
    # Plans → the ⋯ disc on the active plan card (plans.ex:410).
    "50",
    # Meals today → ⋯ → Reminders (meals_today.ex:1454); also Notifications →
    #   a held meal reminder.
    "51",
    # Schedule → ⋯ → Meals on the calendar (calendar.ex:1274); also Meals
    #   today → See tomorrow.
    "52",
    # Meals today → the Library tile (meals_today.ex:1380).
    "116",
    # Meal library → the + disc for a new meal, or a meal tile to edit one
    #   (meal_library.ex:609,627).
    "118",
    # Create or edit a meal → Add an ingredient, or an ingredient row
    #   (meal_edit.ex:798,800,856).
    "119",
    # Plans → the Import a plan row (plans.ex:92,407).
    "120",
    # Plans → Share a plan → Print the week (plan_share.ex:266,362).
    "121",
    # ── Health, habits and weight. Stats → More numbers, and Health's own tiles.
    # Stats → More numbers → Habits (stats.ex:1407); also Home's Habits
    #   shortcut and Health's Habits tile.
    "22",
    # Stats → More numbers → Nutrition (stats.ex:1408) — the only non-gallery
    #   door, and it survives a fresh install.
    "42",
    # Stats → More numbers → Nutrition → Health → the Weight tile
    #   (health.ex:937,1102).
    "109",
    # Health → Weight → the + disc (weight.ex:475).
    "111",
    # Health → the Medication tile (health.ex:1105); also Notifications → a
    #   health reminder.
    "112",
    # Health → the dashed Sleep or Workouts tile (health.ex:1111,1145); also
    #   Auto-detect → the Browser extension tile.
    "114",
    # Health → Medication → the + disc in the header (medication.ex:1330).
    "188",
    # Health → Medication → a row in the Schedules band
    #   (medication.ex:1080-1088,1351).
    "189",
    # ── Goals. Stats → More numbers → Goals.
    # Stats → More numbers → Goals (stats.ex:1409).
    "104",
    # Stats → More numbers → Goals → the + disc (goals.ex:269,520).
    "106",
    # ── Money. Stats → More numbers → Money.
    # Stats → More numbers → Money (stats.ex:1410) — the only non-gallery
    #   door.
    "122",
    # Schedule → ⋯ → Quick add → the Expense chip in the file-as row
    #   (quick_add.ex:301,343).
    "124",
    # Settings → Language → the Currency row (language.ex:429,503).
    "125",
    # Schedule → ⋯ → Money on the calendar (calendar.ex:1276); also a money
    #   row in the day timeline.
    "126",
    # ── Settings' own rows, each reached from the row that names it.
    # Settings → Appearance → Widgets (settings.ex:699,846).
    "39",
    # Settings → About → This device (settings.ex:700,846).
    "40",
    # Settings → Appearance → Text size (settings.ex:702,846).
    "41",
    # Settings → the Language row (settings.ex:701,846); also Persian Settings
    #   → زبان → تغییر.
    "54",
    # Settings → Data → Data sources (settings.ex:706).
    "80",
    # Settings → About → Where this comes from (settings.ex:707).
    "83",
    # ── The first-run chain. Reached by being a fresh install.
    # First run: 53 → Welcome → Get started (onboarding_welcome.ex:185); also
    #   Home-with-nothing → Choose sections.
    "26",
    # First run: 26 Pick sections → import a backup → 135 Restore → Back to
    #   welcome (restore_first_run.ex:178).
    "38",
    # The screen a fresh install opens on — Kati.Onboarding.first_screen/0 via
    #   root.ex:176.
    "53",
    # First run: 162 Loudness → Notify me / Weekly digest → Continue
    #   (onboarding_loudness.ex:217,234).
    "136",
    # First run, step 2: 53 Language → Continue (language_pick.ex:541;
    #   onboarding.ex:186).
    "161",
    # First run, step 4: 26 Pick sections → Continue
    #   (pick_sections.ex:180,221).
    "162",
    # First run, step 5: 162 Loudness → Continue, direct or via 136
    #   (onboarding_loudness.ex:233; loudness_prompt.ex:412).
    "163",
    # ── Backup and restore. Settings → the Data group.
    # Settings → Data → Back up everything, or Export everything
    #   (settings.ex:690,696); also Persian Settings.
    "128",
    # Settings → Data → Restore a Kati backup (settings.ex:697); also Home-
    #   with-nothing, Library's empty card and first-run Welcome.
    "129",
    # First run: 26 Pick sections → Restore from a backup instead
    #   (pick_sections.ex:157).
    "135",
    # ── The Persian app. Settings → Language → فارسی, then its own dock — en and fa are one app, and its pages are reached the same way.
    # Settings → Language → فارسی (language.ex:533,542); the Persian dock's
    #   Home tab and the Persian shell root.
    "55",
    # Persian dock → the calendar tab, or Persian Home's calendar disc
    #   (fa.ex:127,458; home_fa.ex:1057).
    "56",
    # Persian dock → the grid tab (fa.ex:128,458).
    "57",
    # Persian Library → a poster tile (library_fa.ex:964); also Persian Search
    #   → a result.
    "58",
    # Persian Home → the وعده‌ها tile (home_fa.ex:1060).
    "59",
    # Persian Home → وعده‌ها → امروز → the week disc (today_fa.ex:711).
    "60",
    # Persian dock → the آمار tab (fa.ex:129,458).
    "61",
    # Persian Home → the تنظیمات tile (home_fa.ex:1063); also the Persian
    #   empty Home's tune disc.
    "62",
    # Persian Library → کتاب‌ها → Persian Books shelf → a book cover
    #   (books_fa.ex:940,1018).
    "69",
    # Persian Books shelf → ثبت پیشرفت, or the timer disc
    #   (books_fa.ex:914,929).
    "72",
    # Persian Books shelf → the موسیقی segment (books_fa.ex:968).
    "76",
    # Persian album page → the artist row (album_detail_fa.ex:1001).
    "79",
    # Persian Settings → منابع داده under داده‌ها (settings_fa.ex:525,941).
    "82",
    # Persian Settings → منابع (پروانه‌ها و اعتبارها)
    #   (settings_fa.ex:524,941).
    "85",
    # Persian Home → the search field (home_fa.ex:1054); also the Persian
    #   empty Home.
    "90",
    # Persian Settings → سرویس‌های من (settings_fa.ex:522,941); also Persian
    #   Money → a subscription row.
    "97",
    # Persian Stats → the share disc (stats.ex).
    "103",
    # Persian Stats → the اهداف card (stats.ex).
    "108",
    # Persian Stats → the سلامت card (stats.ex).
    "115",
    # Persian Stats → the پول card (stats.ex).
    "127",
    # Persian first run → the بازگردانی link on 164/137, or the Persian empty
    #   Home's restore invitation (home_fa_empty.ex:309).
    "132",
    # Persian first run: 164 Persian welcome → بعدی
    #   (onboarding_welcome_fa.ex:168).
    "137",
    # The same door in Persian — AddByHand.for_locale/0 answers this module
    #   while the locale is :fa (add_by_hand.ex:139).
    "156",
    # Persian first run: 53 → فارسی → Continue (language_pick.ex:541;
    #   onboarding.ex:185).
    "164",
    # Persian first run: 137 Persian sections → ادامه (onboarding_fa.ex:140).
    "165",
    # Persian first run: 165 Persian loudness → its continue pill
    #   (onboarding_loudness_fa.ex:247).
    "166",
    # Persian Library → the کتاب‌ها segment (library_fa.ex:931).
    "176"
  ]

  @doc false
  def screens, do: @screens

  @doc """
  The screens this page still lists — every drawing that has not been retired.

  See `@routed` for what retires one and why the registry keeps it.
  """
  @spec listed() :: [{String.t(), String.t(), module(), :root | :push}]
  def listed, do: Enum.reject(@screens, fn {number, _, _, _} -> number in @routed end)

  @doc false
  def routed, do: @routed

  @doc false
  def undrawn, do: @undrawn

  @doc false
  def content(_assigns) do
    # Bound to a local: inside ~MOB an `@name` means an ASSIGN, so `@screens`
    # would be read as `assigns.screens` and fail.
    count = length(Kati.Screens.Gallery.listed()) + length(@undrawn)

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
    # Built once and assigned, rather than composed in the `text` slot the way
    # it used to be: the line is now READ TWICE — once as the text and once by
    # `mono_face/1`, which decides the face from the script the finished string
    # is in. Building it in both places would be two chances for them to
    # disagree, and the way they would disagree is a Persian line in DM Mono.
    subtitle = Kati.Screens.Gallery.count_line(count)

    assigns = %{subtitle: subtitle, top: Kati.Screens.Pushed.content_top()}

    ~MOB"""
    <Column fill_width={true}>
      <Column fill_width={true} padding_left={21} padding_right={21} padding_top={@top}>
        <Text
          text={pgettext("screen title", "All screens")}
          text_size={28}
          max_font_scale={1.6}
          font_weight="bold"
          letter_spacing={Kati.Locale.tracking(-0.03)}
          text_color={:on_surface}
          max_lines={1}
        />
        <Spacer size={5} />
        <Text
          text={@subtitle}
          font_family={Kati.Locale.mono_face(@subtitle)}
          text_size={11}
          text_color={Palette.muted()}
        />
        <Spacer size={20} />
        {Kati.UI.eyebrow(pgettext("eyebrow", "Every page"))}
      </Column>
      {Kati.Screens.Gallery.cap()}
    </Column>
    """
  end

  @doc """
  The header's mono line: `50 pages · tap to open`.

  Counted rather than written down — `listed/0` plus `@undrawn` is exactly the
  two groups this page draws — so a screen retired into `@routed` takes itself
  out of the figure instead of leaving a number that used to be true.

  `%{n} page` is the msgid screens 66 and 70 already own. A page of a book and
  a page of the app are both **صفحه**, and a second entry would be a second
  word for one word; the Gallery's own sense is fixed by the title above it.

  ## Neither the face nor the digits is a constant here

  `Kati.Locale.number/1` puts the count in the reader's own numerals, which is
  a change of FACE as well as of glyph: `kati_mono.ttf` carries none of
  U+06F0–U+06F9, so a Persian figure left in DM Mono is drawn by Android's
  substitute face beside Latin ones that are not. `mono_face/1` at the call
  site asks the finished string which script it is in — DM Mono while the line
  is ASCII, Vazirmatn the moment it is not — which is the same answer screen
  20's shelf line gives for the same reason.

      iex> Kati.Screens.Gallery.count_line(2)
      "2 pages · tap to open"
  """
  @spec count_line(non_neg_integer()) :: String.t()
  def count_line(count) do
    ngettext("%{n} page", "%{n} pages", count, n: Kati.Locale.number(count)) <>
      " · " <> gettext("tap to open")
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
    screens = Kati.Screens.Gallery.listed()
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
        {Kati.UI.eyebrow(pgettext("eyebrow", "Not yet drawn"))}
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

  @doc """
  The face a registry label is set in: Vazirmatn once it carries any Persian.

  Twenty-nine of the registry's labels are written in Persian and nineteen of
  those name a board in both scripts at once — `خانه — nothing stored, RTL` is
  the shape. The counts were twenty-two and three when this was written and
  mishka-group/kati#103 raised both, which is the direction they go: a board
  drawn in Persian is named in Persian. Left unmarked they came out in
  Android's own fallback Arabic face — legible, and not the one the rest of
  the app is set in, which is the failure `Kati.PersianFontTest` exists to
  make loud.

  Only two of them are still LISTED — 158 and 159, the pair `@routed` has no
  route for yet. The face is decided per label rather than per page all the
  same, because `screens/0` is the registry three sweeps read and a number
  comes back into the list the moment its route is withdrawn.

  Vazirmatn covers Latin and the em dash as well, so the mixed rows take it
  whole rather than being split into two `Text`s to keep three English words
  in Plus Jakarta Sans.

  It asks the LABEL and not the reader, which is why it survived the fold: the
  page's chrome follows `Kati.Locale` now, and every one of these labels names
  a drawing instead — so `sans` here is a Latin name deliberately kept Latin
  under a Persian root, not a screen that forgot to declare a face. The `sans`
  it returns is what stops the frame's `fa` being inherited, and
  `Kati.PersianFontTest` reads an explicit prop exactly that way.
  """
  @spec face(String.t()) :: String.t()
  def face(label) do
    if String.match?(label, ~r/[\x{0600}-\x{06FF}]/u), do: "fa", else: "sans"
  end

  @doc false
  def row(entry, rule?), do: Kati.Screens.Gallery.row(entry, rule?, nil)

  @doc false
  def row({number, name, module, kind}, rule?, override) do
    tap = {self(), override || String.to_atom("open_" <> number)}

    # The idle chevron is `rail_idle`, not `tertiary`: the design draws two
    # chevron greys and this is the `0xFFC4BDB3` one — the same call
    # `Kati.UI.SettingsList.chevron/0` makes.
    tint = if kind == :root, do: Palette.accent(), else: Palette.rail_idle()

    # The number stays Latin digits in DM Mono in both scripts, where the
    # header's count does not. It is not a quantity the reader is being told —
    # it is the drawing's NAME, the `NN` of `test/design/screens/NN.html` and
    # the number the owner says out loud — so converting it would make board ۸۶
    # and board 86 two names for one file. `Kati.Locale.number/1`'s own docs
    # draw the same line: the mono slot keeps Latin figures, and `--` on an
    # undrawn row is not a numeral at all.
    #
    # The chevron does turn, because it is the one node here that points at
    # something: every row OPENS a screen, and forward is the leading edge the
    # reader is already travelling towards. A glyph is a codepoint in a font, so
    # `layout_direction="rtl"` moves the Row's contents and leaves the arrow
    # aimed the way it was drawn — the trap `Kati.Screens.Pushed.back_glyph/0`
    # records for the back pill, and this is the same trap facing the other way.
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
            font_family={Kati.Screens.Gallery.face(name)}
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
        {UI.symbol(Kati.Locale.forward_chevron(), size: 18, color: tint)}
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

    case Enum.find(Kati.Screens.Gallery.listed(), fn {n, _, _, _} -> n == number end) do
      # A root is swapped rather than pushed: pushing Home over the gallery
      # would leave the dock showing Home while the back stack says otherwise.
      {_, _, module, :root} -> {:noreply, Mob.Socket.reset_to(socket, module)}
      {_, _, module, :push} -> {:noreply, Mob.Socket.push_screen(socket, module)}
      nil -> {:noreply, socket}
    end
  end
end
