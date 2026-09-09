# The state of the app

Kati installs on an Android phone, boots, migrates a real SQLite database, and draws 152
screens that were built from 152 drawings. Almost none of what it draws is yours.

This document establishes what is actually true, from the source, because the owner installed
the APK and reported five things: the screens show dummy data, nothing is connected to the
database, nothing is connected to any API, search does not work, and every screen is reachable
only through Settings. Three of those are exactly right, one is right in a narrower and worse
way than it sounds, one is wrong as stated and right in substance — and there are two defects
the report did not reach.

Every claim below cites a file and a line. Where the evidence is ambiguous, it says so.

---

## 1. What the owner observed, and which parts are exactly right

**"Screens show dummy data" — correct, and it is the whole app, not a corner of it.**
120 of the 152 screens call a `*Sample*` module directly, and there are 75 such modules in
`lib/` (`lib/kati/library/sample.ex`, `lib/kati/music/sample.ex`, `lib/kati/import/sample.ex`,
`lib/kati/backup/sample_restore.ex`, and 71 more). More importantly, the 88 screens that *do*
reach the database all keep the Sample as a fallback for an empty store — and on a device the
store is empty, so the fallback is what draws. This is not a bug: it is designed, tested and
pinned. `test/kati/screen_empty_database_test.exs` exists specifically to assert that every
migrated screen still draws its drawing when nothing is stored
(`test/kati/screen_empty_database_test.exs:5-25`). The consequence is that a real read and a
frozen drawing are visually indistinguishable on a fresh install, which is exactly what the
owner saw.

**"Nothing is connected to the database" — half right, and the wrong half is the important one.**
The database is genuinely there. 12 Ash domains and 37 resources exist, all 37 have migrations,
all 37 have snapshots, and `Ecto.Migrator.run/4` runs at boot on device
(`lib/kati/app.ex:99`). 88 screens issue real Ash queries. What is missing is not the
connection — it is anything to connect *to*. Nothing in `lib/` ever writes a `CachedTitle`, a
`TrackedTitle` or a `Watch`, so the entire film-and-TV spine of the app — Library, Series,
Film, Up next, New releases, Your year — queries tables that can never contain a row. See §2.

**"Nothing is connected to any API" — correct, with one honourable exception that nothing calls.**
There is exactly one real HTTP client in the repo: the CalDAV adapter at
`lib/kati/sync/adapter/caldav/transport.ex:71-72`. It is a genuine RFC 6578 implementation with
a real `:xmerl` multistatus parser. Nothing in `lib/` calls it. TMDB, Open Library, MusicBrainz,
ListenBrainz, TVmaze, Hardcover and TheTVDB have no client module at all — they are entries in
a display list at `lib/kati/sources.ex:47-91`. A grep of `lib/` for `https?://` returns zero API
endpoints. Runtime network egress on device today is zero. See §3.

**"Search does not work" — correct, and it is worse than not working: it cannot receive input.**
Screen 19's field is a `<Text>` node, not an input (`lib/kati/screens/search.ex:236-242`). There
is no `on_change`, no keyboard, no query state. The screen's `mount/3` assigns
`Sample.results()` and never changes them (`lib/kati/screens/search.ex:121`). The only tap
handlers are the filter chips and the recent-search pills, and both only move an assign
(`lib/kati/screens/search.ex:160-174`). See §4.

**"Every screen is reachable only through Settings" — this one is wrong as stated, and the
truth underneath it is worse.** Only 15 of the 152 screens require Settings. But 47 screens
have no in-app route at all and are reachable *only through the developer gallery*, which lives
on a Settings row labelled "Every screen" (`lib/kati/screens/settings.ex:664`). A further 23 are
reachable only inside the first-run chain, which a device that has completed onboarding can
never re-enter (`lib/kati/onboarding.ex:79-81`). So on a phone set up in English, **70 of the 152
screens have no door but the gallery**, and 15 more need a Settings row — 85 screens in total
whose only way in starts with opening Settings. That is almost certainly what the owner met,
and the impression it gives — *the gallery is the app* — is a fair reading of what is on the
device. See §5.

**Two things the report did not reach.** First, the screens that *can* write persist hardcoded
sample values into arbitrarily chosen rows, and swallow every failure (§2). Second, ticking an
episode — the single core gesture of a media tracker — does not persist: it changes a socket
assign and nothing else (`lib/kati/screens/series.ex:1061`).

---

## 2. Screen by screen: where the pixels come from

### How this table was derived

Not from a grep of each screen's source, which would be wrong in both directions — a moduledoc
quoting `Ash.create!` is not a query, and a read that has moved into a helper is invisible. It
is derived from each module's **compiled BEAM import table**, the exact set of external
functions the module calls, closed transitively over the app's own modules. This is the same
technique `test/kati/screen_empty_database_test.exs:1236-1271` uses to keep its own list honest,
and it produces the same answer: 88 screens reach Ash.

Four classes:

| Class | Count | What it means |
|---|---:|---|
| **Ash (direct)** | 37 | The screen module itself calls `Ash.read/2` or a resource's read action |
| **Ash (indirect)** | 51 | It reaches the store through another module — `Kati.Calendars.Today`, or a primary screen it mirrors |
| **Sample only** | 55 | It reaches no store at all; a `*Sample*` module is the whole page |
| **Literals only** | 9 | No store, no Sample — the copy is written into the markup |

**Cross-check against `@migrated`.** `test/kati/screen_empty_database_test.exs:126` lists 88
numbered screens as store-readers, plus three undrawn ones — `Kati.Screens.InboxNotifications`,
`Kati.Screens.NotificationsHelp`, `Kati.Screens.Sync` — that have no artboard and so are not
among the 152. My independent derivation agrees **exactly**: the same 88 numbers, none added,
none missing. The test's list is neither stale nor aspirational. It is also, crucially, not a
claim that those screens *show* real data — it is a claim that they still draw correctly when
they find none, which is the opposite claim, and the one that matters on a fresh device.

**The fallback column is the honest one.** 69 of the 88 store-reading screens hold a direct
`*Sample*` call as well. On a device with an empty database — which is every device, see §2.2 —
that is the branch that runs.

### 2.1 The full table

`Module` is abbreviated: `S.` is `Kati.Screens.`, and a bare name in the Fallback column is
`Kati.`-prefixed — so `Library.Sample` is `Kati.Library.Sample` and `S.Search.Sample` is
`Kati.Screens.Search.Sample`. `Route` names the root the shortest push path starts from;
`Settings only` where Settings is the sole way in; **`Gallery only`** where there is no in-app
route at all. A route reading `LanguagePick` is inside the first-run chain and is unreachable
once onboarding completes. The numbers run to 153 with 134 missing — 134 is a 1720px flow
diagram rather than a screen, and `lib/kati/screens/gallery.ex:164-169` says so — which is why
153 numbers describe 152 rows.

| № | Screen | Module | Data source | Fallback / Sample | Route |
|---|---|---|---|---|---|
| 01 | Home | `S.Home` | Ash (indirect) | Settings.Sample | Home |
| 02 | Schedule | `S.Calendar` | Ash (indirect) | — | Calendar |
| 03 | Library | `S.Library` | Ash (direct) | Library.Sample | Library |
| 04 | Series detail | `S.Series` | Ash (direct) | Library.Sample | Library |
| 05 | New releases | `S.Inbox` | Ash (direct) | Library.Sample | Home |
| 06 | Add a title | `S.AddTitle` | Sample only | Library.Sample | Home |
| 07 | Your year | `S.Stats` | Ash (direct) | Stats.Sample | Stats |
| 08 | Film detail | `S.Film` | Ash (direct) | Library.Sample | Library |
| 09 | A heavy day | `S.Day` | Sample only | Calendar.SampleDay, Library.Sample | Calendar |
| 10 | Up next | `S.UpNext` | Ash (direct) | S.UpNext.Sample | Library |
| 11 | Discover | `S.Discover` | Sample only | S.Discover.Sample | Library |
| 12 | Lists | `S.Lists` | Sample only | S.Lists.Sample | Library |
| 13 | What fits? | `S.WhatFits` | Sample only | S.WhatFits.Sample | Library |
| 14 | Series metadata | `S.SeriesMeta` | Sample only | S.SeriesMeta.Sample | Library |
| 15 | Activity | `S.Activity` | Ash (direct) | Activity.Sample | Stats |
| 16 | Month grid | `S.MonthGrid` | Sample only | Calendar.SampleMonth | Calendar |
| 17 | Week | `S.Week` | Sample only | Calendar.SampleWeek | Calendar |
| 18 | Quick add | `S.QuickAdd` | Sample only | S.QuickAdd.Sample | Calendar |
| 19 | Search | `S.Search` | Sample only | S.Search.Sample | Calendar |
| 20 | Books | `S.Books` | Sample only | Books.Sample | Library |
| 21 | Music | `S.Music` | Sample only | Music.Sample | Library |
| 22 | Habits | `S.Habits` | Sample only | Habits.Sample | Home |
| 23 | Subscriptions | `S.Subscriptions` | Sample only | Subscriptions.Sample | Home |
| 24 | Settings | `S.Settings` | Ash (indirect) | Settings.Sample | Home |
| 25 | Release watcher | `S.ReleaseWatcher` | Sample only | Settings.WatcherSample | Home |
| 26 | Pick sections | `S.PickSections` | Sample only | S.PickSections.Sample | LanguagePick |
| 27 | States | `S.States` | Sample only | Settings.StatesSample | **Gallery only** |
| 28 | Home, dark | `S.HomeDark` | Ash (indirect) | S.HomeDark.Sample | **Gallery only** |
| 29 | Lock screen | `S.Lock` | Ash (direct) | S.Lock.Sample | **Gallery only** |
| 30 | Agenda | `S.Agenda` | Sample only | Calendar.SampleAgenda | Calendar |
| 31 | Event detail | `S.EventDetail` | Sample only | Calendar.SampleEvent | Calendar |
| 32 | Calendars | `S.Calendars` | Ash (direct) | Settings.CalendarsSample | Settings only |
| 33 | Rating | `S.Rating` | Ash (direct) | Rating.Sample | Library |
| 34 | Season | `S.Season` | Ash (direct) | Season.Sample | Library |
| 35 | Series settings | `S.SeriesSettings` | Sample only | SeriesSettings.Sample | Library |
| 36 | Auto-detect | `S.AutoDetect` | Sample only | Settings.DetectSample | Settings only |
| 37 | Import | `S.Import` | Sample only | Import.Sample | LanguagePick |
| 38 | Onboarding | `S.Onboarding` | Sample only | Onboarding.Sample | LanguagePick |
| 39 | Widgets | `S.Widgets` | Sample only | Widgets.Sample | Settings only |
| 40 | Account | `S.Account` | Sample only | Account.Sample | Settings only |
| 41 | Accessibility | `S.Accessibility` | Sample only | Accessibility.Sample | Settings only |
| 42 | Health | `S.Health` | Ash (direct) | Health.Sample, Settings.Sample | Stats |
| 43 | Meals today | `S.MealsToday` | Ash (direct) | Meals.SampleToday | Home |
| 44 | Meal plan | `S.MealPlan` | Ash (direct) | Meals.SamplePlan | Home |
| 45 | Meal | `S.Meal` | Ash (direct) | Meals.SampleRecipe | Home |
| 46 | Meal swap | `S.MealSwap` | Sample only | Meals.SampleSwap | Home |
| 47 | Nutrition | `S.Nutrition` | Ash (direct) | Meals.SampleNutrition | Home |
| 48 | Shopping | `S.Shopping` | Ash (direct) | Meals.SampleShopping | Home |
| 49 | Plans | `S.Plans` | Sample only | Meals.SampleProfiles | Home |
| 50 | Share a plan | `S.PlanShare` | Sample only | Meals.SampleShare | Home |
| 51 | Meal reminders | `S.MealReminders` | Sample only | Meals.SampleReminders | Home |
| 52 | Meals on the calendar | `S.MealsDay` | Sample only | Calendar.SampleMealDay | Calendar |
| 53 | Language pick | `S.LanguagePick` | Sample only | Onboarding.LanguageSample | LanguagePick |
| 54 | Language | `S.Language` | Sample only | Language.Sample | Settings only |
| 55 | خانه | `S.HomeFa` | Ash (indirect) | S.HomeFa.Sample | LanguagePick |
| 56 | برنامه | `S.ScheduleFa` | Ash (indirect) | S.ScheduleFa.Sample | LanguagePick |
| 57 | کتابخانه | `S.LibraryFa` | Ash (indirect) | S.LibraryFa.Sample | LanguagePick |
| 58 | سریال | `S.SeriesFa` | Ash (indirect) | S.SeriesFa.Sample | LanguagePick |
| 59 | امروز | `S.TodayFa` | Sample only | Fa.SampleToday | LanguagePick |
| 60 | وعده‌ها | `S.MealsMatrixFa` | Sample only | Fa.SampleWeek | LanguagePick |
| 61 | آمار | `S.StatsFa` | Ash (indirect) | Fa.SampleYear | LanguagePick |
| 62 | تنظیمات | `S.SettingsFa` | Ash (indirect) | Fa.SampleSettings | LanguagePick |
| 66 | Book detail | `S.BookDetail` | Ash (direct) | Books.Sample | Library |
| 70 | Log progress | `S.LogProgress` | Ash (direct) | Books.Sample | Library |
| 73 | Log a listen | `S.LogListen` | Ash (direct) | Music.Sample | Library |
| 74 | Album detail | `S.AlbumDetail` | Ash (direct) | Music.Sample | Library |
| 77 | Artist detail | `S.ArtistDetail` | Ash (direct) | Music.Sample | Library |
| 80 | Data sources | `S.DataSources` | Ash (direct) | — | Settings only |
| 83 | Where this comes from | `S.Attribution` | Literals only | — | Settings only |
| 92 | My services | `S.MyServices` | Ash (direct) | Services.Sample | Home |
| 94 | Country picker | `S.CountryPicker` | Ash (indirect) | Services.Sample | Home |
| 104 | Goals | `S.Goals` | Ash (direct) | Goals.Sample | Stats |
| 106 | New goal | `S.NewGoal` | Ash (direct) | Books.Sample | Stats |
| 122 | Money | `S.Money` | Ash (direct) | Money.Sample | Stats |
| 124 | Quick add — expense | `S.QuickAddExpense` | Ash (direct) | S.QuickAdd.Sample | Calendar |
| 125 | Currency | `S.Currency` | Ash (indirect) | — | Settings only |
| 109 | Weight | `S.Weight` | Ash (direct) | Health.WeightSample | Stats |
| 111 | Log weight | `S.LogWeight` | Ash (direct) | Health.WeightSample | Stats |
| 112 | Medication | `S.Medication` | Ash (direct) | Health.WeightSample | Stats |
| 116 | Meal library | `S.MealLibrary` | Ash (direct) | Meals.SampleLibrary | Home |
| 118 | Create or edit a meal | `S.MealEdit` | Ash (direct) | Meals.SampleLibrary | Home |
| 119 | Add an ingredient | `S.AddIngredient` | Ash (indirect) | Meals.SampleLibrary | Home |
| 98 | Your year, shared | `S.YearShare` | Sample only | Stats.ShareSample | Stats |
| 100 | Year cards | `S.YearCards` | Ash (indirect) | Stats.ShareSample | Home |
| 69 | کتاب | `S.BookDetailFa` | Ash (indirect) | Books.SampleFa | LanguagePick |
| 72 | ثبت پیشرفت | `S.LogProgressFa` | Ash (indirect) | Books.SampleFa | LanguagePick |
| 67 | Book detail — states | `S.BookDetailStates` | Ash (indirect) | Books.Sample | **Gallery only** |
| 68 | Book detail — dark | `S.BookDetailDark` | Ash (indirect) | Books.Sample | **Gallery only** |
| 71 | Log progress — states | `S.LogProgressStates` | Ash (indirect) | Books.Sample | **Gallery only** |
| 75 | Album detail — states | `S.AlbumDetailStates` | Ash (indirect) | Music.Sample | **Gallery only** |
| 78 | Artist detail — states | `S.ArtistDetailStates` | Ash (indirect) | Music.Sample | **Gallery only** |
| 86 | Search — idle | `S.SearchIdle` | Sample only | Search.Sample | Home |
| 88 | Scope & ranking | `S.SearchSpec` | Literals only | — | Home |
| 126 | Money on the calendar | `S.MoneyDay` | Ash (direct) | Money.DaySample | Calendar |
| 76 | آلبوم | `S.AlbumDetailFa` | Ash (indirect) | Music.Sample | LanguagePick |
| 79 | هنرمند | `S.ArtistDetailFa` | Ash (indirect) | Music.Sample | LanguagePick |
| 81 | Data sources — states | `S.DataSourcesStates` | Ash (indirect) | Settings.StatesSample | **Gallery only** |
| 82 | منابع داده | `S.DataSourcesFa` | Ash (direct) | Books.SampleFa | Settings only |
| 84 | Attribution — states | `S.AttributionStates` | Literals only | — | **Gallery only** |
| 85 | منابع | `S.AttributionFa` | Ash (indirect) | Books.SampleFa | Settings only |
| 93 | My services — nothing set up | `S.MyServicesEmpty` | Ash (indirect) | Services.Sample | Home |
| 95 | My services — states | `S.MyServicesStates` | Ash (indirect) | Services.Sample | **Gallery only** |
| 96 | Nothing set up — knock-on | `S.NothingSetUpKnockOn` | Ash (indirect) | S.WhatFits.Sample | **Gallery only** |
| 97 | سرویس‌های من | `S.MyServicesFa` | Ash (indirect) | Services.Sample | LanguagePick |
| 99 | Your year — Books | `S.YearShareBooks` | Sample only | Stats.ShareSample | **Gallery only** |
| 101 | Year cards — states | `S.YearCardsStates` | Sample only | Music.Sample, Stats.ShareSample | **Gallery only** |
| 87 | Search — typing | `S.SearchTyping` | Sample only | Search.Sample, Settings.StatesSample | **Gallery only** |
| 89 | Search — result states | `S.SearchResultStates` | Sample only | S.Search.Sample | **Gallery only** |
| 90 | جست‌وجو | `S.SearchFa` | Ash (indirect) | Books.SampleFa | LanguagePick |
| 91 | Search at 235% | `S.SearchLarge` | Literals only | — | **Gallery only** |
| 102 | Your year, shared — dark | `S.YearShareDark` | Ash (indirect) | Stats.Sample, Stats.ShareSample | **Gallery only** |
| 103 | سال شما | `S.YearShareFa` | Ash (indirect) | Fa.SampleYear, Stats.ShareSample | LanguagePick |
| 105 | Goals — empty | `S.GoalsEmpty` | Ash (indirect) | Goals.Sample | **Gallery only** |
| 110 | Weight — states | `S.WeightStates` | Ash (indirect) | Health.WeightSample | **Gallery only** |
| 113 | Health hub — empty | `S.HealthEmptyStates` | Ash (indirect) | Health.Sample | **Gallery only** |
| 107 | Goal states | `S.GoalStates` | Ash (indirect) | Music.Sample | **Gallery only** |
| 108 | اهداف | `S.GoalsFa` | Ash (indirect) | Music.Sample | LanguagePick |
| 114 | Retired tile | `S.RetiredTile` | Ash (indirect) | Health.Sample | Stats |
| 117 | Meal library — empty | `S.MealLibraryEmpty` | Ash (indirect) | Meals.SampleLibrary | **Gallery only** |
| 120 | Import a plan | `S.PlanImport` | Sample only | Meals.SampleShare | Home |
| 123 | Money — states | `S.MoneyStates` | Ash (indirect) | Money.Sample | **Gallery only** |
| 115 | سلامت | `S.HealthFa` | Ash (indirect) | Health.WeightSample | LanguagePick |
| 121 | The week as an image | `S.WeekImage` | Ash (indirect) | Fa.SampleWeek, Meals.SamplePlan | Home |
| 127 | پول | `S.MoneyFa` | Ash (indirect) | Money.Sample | LanguagePick |
| 63 | iOS home screen | `S.MarkIos` | Ash (indirect) | Meals.SamplePlan | **Gallery only** |
| 64 | Android home screen | `S.MarkAndroid` | Ash (indirect) | S.Lock.Sample | **Gallery only** |
| 65 | Launch screen | `S.LaunchScreen` | Literals only | — | **Gallery only** |
| 128 | Back up everything | `S.Backup` | Ash (indirect) | Backup.Sample | Settings only |
| 129 | Restore from a backup | `S.Restore` | Ash (indirect) | Backup.SampleRestore | Settings only |
| 130 | Backup & restore — states | `S.BackupStates` | Literals only | — | **Gallery only** |
| 131 | Back up everything — dark | `S.BackupDark` | Ash (indirect) | Books.Sample | **Gallery only** |
| 132 | بازگردانی | `S.RestoreFa` | Ash (indirect) | Backup.SampleRestore | **Gallery only** |
| 133 | Back up & restore at 235% | `S.BackupLarge` | Sample only | Backup.Sample | **Gallery only** |
| 135 | Restore — first run | `S.RestoreFirstRun` | Ash (indirect) | Backup.SampleRestore | LanguagePick |
| 136 | Loudness → the OS prompt | `S.LoudnessPrompt` | Sample only | Onboarding.Sample | **Gallery only** |
| 137 | راه‌اندازی | `S.OnboardingFa` | Sample only | S.OnboardingFa.Sample | **Gallery only** |
| 138 | Onboarding at 235% | `S.OnboardingLarge` | Sample only | Onboarding.Sample | **Gallery only** |
| 139 | Home — nothing set up | `S.HomeEmpty` | Ash (indirect) | Settings.Sample | **Gallery only** |
| 140 | Import — where are you coming from | `S.ImportSources` | Sample only | Import.Sample | Settings only |
| 141 | Import — recognised | `S.ImportRecognised` | Sample only | Import.Sample | Settings only |
| 142 | Import — source states | `S.ImportStates` | Sample only | Import.Sample | **Gallery only** |
| 143 | Episode rows — the rating column | `S.EpisodeRatings` | Literals only | — | **Gallery only** |
| 144 | Rate an episode | `S.RateEpisode` | Ash (direct) | S.RateEpisode.Sample | **Gallery only** |
| 145 | Shelf filter sheet | `S.ShelfFilters` | Sample only | Library.ShelfFiltersSample | **Gallery only** |
| 146 | Shelf — selection mode | `S.ShelfSelection` | Sample only | Library.Sample, Library.ShelfFiltersSample | **Gallery only** |
| 147 | Selection & filters at 235% | `S.ShelfLarge` | Literals only | — | **Gallery only** |
| 148 | Drop, DNF & abandon | `S.DropStates` | Sample only | Settings.DropStatesSample | **Gallery only** |
| 149 | Dropping — the sheet and after | `S.DropSheet` | Ash (direct) | S.DropSheet.Sample | **Gallery only** |
| 150 | Auto-detect — music | `S.AutoDetectMusic` | Sample only | Settings.DetectMusicSample | **Gallery only** |
| 151 | Notification access | `S.NotificationAccess` | Literals only | — | **Gallery only** |
| 152 | Anime — a type, not a section | `S.AnimeFilter` | Sample only | Media.AnimeSample | **Gallery only** |
| 153 | Numbering — inherited and overridden | `S.NumberingScheme` | Sample only | NumberingScheme.Sample | **Gallery only** |

### 2.2 The database is real, and it is empty by construction

The domain layer is not a sketch. 12 domains and 37 resources, every one on
`AshSqlite.DataLayer` over `Kati.Repo`:

| Domain | File | Resources |
|---|---|---:|
| `Kati.Books` | `lib/kati/books.ex:41` | 3 |
| `Kati.Calendars` | `lib/kati/calendars.ex:9` | 4 |
| `Kati.Goals` | `lib/kati/goals.ex:29` | 1 |
| `Kati.Health` | `lib/kati/health.ex:34` | 3 |
| `Kati.Meals` | `lib/kati/meals.ex:62` | 9 |
| `Kati.Media` | `lib/kati/media.ex:29` | 7 |
| `Kati.Money` | `lib/kati/money.ex:34` | 1 |
| `Kati.Music` | `lib/kati/music.ex:45` | 4 |
| `Kati.Notifications` | `lib/kati/notifications.ex:27` | 1 |
| `Kati.Services` | `lib/kati/services.ex:38` | 1 |
| `Kati.Sync` | `lib/kati/sync.ex:50` | 2 |
| `Kati.Spike` | `lib/kati/spike.ex:8` | 1 |

Migrations are generated and present — 18 files in `priv/repo/migrations/`, of which 17 create
resource tables and one (`20260507000001_create_mob_screen_states.exs`) backs no resource at all
(see §2.4). Every one of the 37 resources also has a snapshot under
`priv/resource_snapshots/repo/`. There is
no orphan resource and no orphan snapshot. `Kati.Spike` is a throwaway whose own moduledoc says
to delete it (`lib/kati/spike.ex:5-6`) and it is still shipping, with a table, on every device.

At runtime on device the database really is created and migrated: `Kati.Repo.start_link/0` at
`lib/kati/app.ex:82` opens `kati.db` under `Mob.data_dir()` (`lib/kati/repo.ex:31`), and
`Ecto.Migrator.run(Kati.Repo, priv_path("repo/migrations"), :up, all: true)` runs at
`lib/kati/app.ex:99`. So the schema on the phone is the schema in the repo, assuming
`mix mob.deploy --native` was used — the fast path does not sync `priv/`, which
`lib/kati/app.ex:85-92` documents at length after it cost a round on device.

**The boot check that is supposed to catch a stale schema does not.**
`Kati.Runtime.assert!(~w(schema_migrations spike_things))` at `lib/kati/app.ex:105` asserts that
exactly two tables exist. `spike_things` is created by the *first* domain migration
(`20260818141939`). A device that ran two of eighteen migrations and stopped passes this check.
All 36 real domain tables are unasserted, and the failure mode the assertion exists to prevent —
a screen crashing on its first query with a blank frame — is exactly what would happen.

**Nothing seeds the device.** `Kati.Seeds` writes the design's own values as real rows, and its
own moduledoc says it is not wired: *"Nothing here is wired into `Kati.App.on_start/0` yet"*
(`lib/kati/seeds.ex:38`). `Seeds.run/1` has no caller anywhere outside `test/kati/seeds_test.exs`.
The only production reference is the pure helper `Kati.Seeds.sample_seed/1`, which computes a
picsum URL fragment and touches no database (`lib/kati/screens/film.ex:214`,
`lib/kati/screens/series.ex:351`, `lib/kati/screens/activity.ex:730`).

So: a fresh install boots with 37 empty tables, and every screen that reads takes its Sample
branch. That is the mechanism behind the owner's first observation, stated precisely.

### 2.3 What can actually be persisted

Sixteen Ash write sites exist in `lib/kati/screens/`, across eleven screens. This is the
complete list, and each one carries a caveat that matters more than its presence:

| Screen | Write | Line |
|---|---|---|
| 70 Log progress | `Ash.create(ReadingSession, …)`, then `Ash.update(book, %{current_page: …})` | `lib/kati/screens/log_progress.ex:543`, `:553`, `:572` |
| 73 Log a listen | `Ash.create(Listen, …)`, `Ash.update(album, …)`, `Ash.update(track, …)` | `lib/kati/screens/log_listen.ex:523`, `:532`, `:557` |
| 111 Log weight | `Ash.create(Reading, %{grams: …})` | `lib/kati/screens/log_weight.ex:415` |
| 106 New goal | `Ash.create(Goal, …)` | `lib/kati/screens/new_goal.ex:237` |
| 124 Quick add — expense | `Ash.create(Kati.Money.Expense, …)` | `lib/kati/screens/quick_add_expense.ex:225` |
| 66 Book detail | `Ash.update(book, %{attribute => value})` | `lib/kati/screens/book_detail.ex:960` |
| 77 Artist detail | `Ash.update(stored, %{following: now})` | `lib/kati/screens/artist_detail.ex:548` |
| 104 Goals | `Ash.update(goal, %{repeat: now})` | `lib/kati/screens/goals.ex:421` |
| 112 Medication | `Ash.update(dose, %{state: …})` | `lib/kati/screens/medication.ex:396` |
| 118 Create or edit a meal | `Ash.update(recipe, %{slot_name: slot})` — one column | `lib/kati/screens/meal_edit.ex:615` |
| 149 Dropping | `Ash.update(tracked, attrs)` — **screen has no route** | `lib/kati/screens/drop_sheet.ex:327` |

**Three problems run through all of them.**

*The write targets a row the user did not choose.* None of these screens carries an entity id.
They re-query and take the head of the list: `current_book/0` is
`Ash.read(Book, action: :shelf)` → `[book | _rest]` (`lib/kati/screens/log_progress.ex:99-103`);
`log_listen.ex:472-476` and `meal_edit.ex:67-71` are the same shape. Log progress always writes
against the shelf's first book, whichever book you opened.

*The value written is a hardcoded sample.* `quick_add_expense.ex:225` writes
`description: draft.title`, and `draft` comes from `Sample.expense_draft()`
(`lib/kati/screens/quick_add_expense.ex:85`), whose title is the literal `"The Salt Almanac"`
with `amount: nil` (`lib/kati/screens/quick_add/sample.ex:113-120`, the title at `:116`). Every tap of *Add* inserts
a row named "The Salt Almanac" with no amount. The `:edit_amount` handler sets `saved?: false`
and nothing else (`lib/kati/screens/quick_add_expense.ex:211-212`).

*Every write swallows its own failure.* `rescue _error -> :ok` appears at
`log_progress.ex:558`, `log_progress.ex:576`, `log_weight.ex:424`, `log_listen.ex:535`,
`new_goal.ex:246`, `quick_add_expense.ex:234`, `meal_edit.ex:618`, `book_detail.ex:964`,
`drop_sheet.ex:330`, `artist_detail.ex:553`, `goals.ex:424` and `medication.ex:400`. A missing
table, a constraint violation and a successful save are indistinguishable: the sheet pops either
way.

**Two screens whose Save button does nothing at all.** Screen 33 Rating —
`def handle_info({:tap, :save}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}`
(`lib/kati/screens/rating.ex:1056`), in a 1058-line file with no Ash write anywhere, and the
five stars carry no `on_tap` (`lib/kati/screens/rating.ex:122`). This is deliberate and pinned:
`test/kati/screen_rating_log_test.exs:27-29` states *"What is deliberately NOT asserted here: a
write. Screen 33 reads."* Screen 119 Add an ingredient is the same
(`lib/kati/screens/add_ingredient.ex:241`) — name, quantity, unit, aisle and nutrition are all
discarded on Save.

**And the gesture the app is named for does not persist.** Ticking an episode on screen 04 runs
`Mob.Socket.assign(socket, :series, toggle(socket.assigns.series, index))`
(`lib/kati/screens/series.ex:1061`). No `Kati.Media.Watch` row is created — indeed nothing in
`lib/` ever creates one. Screen 06 *Add a title* has no write either: its handlers only move a
filter chip and toggle a row's selected state (`lib/kati/screens/add_title.ex:136-155`).

**Seventeen of the 37 resources have no production write path at all** — including
`Kati.Media.CachedTitle`, `CachedSeason`, `CachedEpisode`, `TrackedTitle`, `Watch`,
`Kati.Services.Service`, `Kati.Books.Note`, every `Kati.Meals` resource except `Recipe` and
`RecipeIngredient`, `Kati.Notifications.Pending`, and both `Kati.Sync` resources. Tables,
migrations, snapshots, validations and read actions all exist for rows the device can never
create.

**One writer does run unprompted, and it is real.** `Kati.Calendars.DeviceImport.run/0` at
`lib/kati/app.ex:133` ingests calendars and events published by
`android/app/src/main/java/com/example/kati/KatiCalendarReader.kt`, which
`MainActivity.kt:182` invokes on every foreground. It queries `CalendarContract.Instances`, so
the OS expands recurrence for it, and it writes real `calendars` and `events` rows
(`lib/kati/calendars/device_import.ex:103,107,191,195`). This is the one path in the app that
puts a user's own data on screen. **It is gated on a permission nothing ever asks for.**
`KatiCalendarReader.kt:42-43` checks `READ_CALENDAR` and returns silently if it is not granted;
`Mob.Permissions.request/2` is called in exactly two places in `lib/`, both for `:notifications`
(`lib/kati/screens/notifications_help.ex:347`, `lib/kati/screens/loudness_prompt.ex:410`), and
`:loudness_prompt`'s screen has no route at all. So the calendar import is a working pipe with
its tap closed.

### 2.4 What persists across a restart, and what does not

`Mob.State` is a `:dets` file at `MOB_DATA_DIR/mob_state.dets` (`deps/mob/lib/mob/state.ex:5-7`,
`:35-37`), so it genuinely survives an app kill. It holds 25 small preferences and nothing else:
weight unit (`lib/kati/health.ex:47,56`), locale (`lib/kati/locale.ex:22,31`), currency
(`lib/kati/money.ex:60,76`), theme (`lib/kati/theme/mode.ex:103,119`), the first-run flag
(`lib/kati/onboarding.ex:44,53,65`), which permissions have been asked
(`lib/kati/permissions.ex:86,93,102`), and the TMDB key *choice* — not a key
(`lib/kati/sources.ex:124,133`).

**Screen state does not persist at all**, despite a migration for it.
`priv/repo/migrations/20260507000001_create_mob_screen_states.exs` creates `mob_screen_states`,
which `Mob.ScreenState` writes to only when `__mob_persist__()` is true; that defaults from
`vsn` (`deps/mob/lib/mob/screen.ex:100-101`), and `grep -rn "vsn:" lib/` returns zero hits across
every `use Mob.Screen` site. The table is created on every device and never receives a row.
`lib/kati/runtime.ex:78-82` asserts that `Application.get_env(:mob, :repo) == Kati.Repo` on the
grounds that screen state would otherwise never persist. The repo is set correctly. Screen state
still never persists, because no screen opts in.

---

## 3. APIs: one real client, and it is not connected

`mix.exs:81` declares `{:req, "~> 0.7"}`. A grep of `lib/**/*.ex` for `Req.` / `Finch` /
`:httpc` / `Mint.` / any other HTTP entry point finds **one** file with executable code:

- `lib/kati/sync/adapter/caldav/transport.ex:71-72` — `|> Req.new() |> Req.request()`

A grep for `https?://` in `lib/` returns zero API endpoints — only documentation links and the
XML namespace `http://calendarserver.org/ns/` (`lib/kati/sync/adapter/caldav.ex:353`). The
Android sources contain no `HttpURLConnection`, `OkHttp` or `Retrofit`.

| Provider | Client module | Real HTTP | Wired to a screen |
|---|---|---|---|
| CalDAV | `lib/kati/sync/adapter/caldav.ex` + `caldav/xml.ex` + `caldav/transport.ex` | Yes | **No** |
| Android `CalendarContract` | `lib/kati/calendars/device_import.ex` | N/A — file handoff | Yes, at boot; permission never requested |
| TMDB | none | no | name only, `lib/kati/sources.ex:113-131` |
| Open Library | none | no | name only, `lib/kati/sources.ex:53-58` |
| MusicBrainz | none | no | name only, `lib/kati/sources.ex:59-64` |
| ListenBrainz / TVmaze / Hardcover / TheTVDB | none | no | name only, `lib/kati/sources.ex:47-91` |

**The CalDAV adapter deserves to be described accurately, because it is the best code in the
repo and it is inert.** It builds real `PROPFIND` and `sync-collection` `REPORT` bodies
(`lib/kati/sync/adapter/caldav.ex:350-380`), sends real `If-Match` / `If-None-Match: *`
conditional headers (`:166-167`, `:322-331`), handles `412`-on-create as success and
`412`-on-update as conflict (`:180-183`), maps `403 valid-sync-token` and `410` to
`:cursor_invalid` (`:95-98`), and percent-encodes the UID into the href to stop path traversal
(`:206-212`). `lib/kati/sync/adapter/caldav/xml.ex` is a 282-line `:xmerl` WebDAV multistatus
parser. This would work against a real server.

**Nothing calls it.** `Kati.Sync.Engine.sync/3` (`lib/kati/sync/engine.ex:71`) has one caller in
the whole repo: `test/kati/sync_engine_test.exs:520`. `Engine.drain/3`
(`lib/kati/sync/engine.ex:377`) is called from `engine.ex:77` and from tests. Zero callers in
`lib/`. The repo's own boundary test pins this — `test/kati/sync_boundary_test.exs:120-128`
asserts that the only file allowed to call an adapter is `lib/kati/sync/engine.ex`, and the
engine is not in the supervision tree: `lib/kati/supervisor.ex:48-53` lists
`Kati.Sync.Engine`, `Kati.Notifications.Scheduler`, `Kati.Jobs.Runner` and `Kati.Net.Throttle`
as *comments* describing future children.

**Even if it were called it could not authenticate.** `Kati.SecureStore.put/2` has zero callers
in `lib/`; nothing writes `credentials_ref` on `Kati.Calendars.Account`; there is no UI anywhere
that collects a server URL, a username or a password. `Keystore.fetch/1`
(`lib/kati/sync/adapter/caldav/transport.ex:118-126`) would return `{:error, :no_credentials}`
on every device.

**Is CalDAV sync reachable from the UI at all? No.** `lib/kati/screens/sync.ex` is a read-only
queue viewer — `Kati.Sync.status/1` at `:316`, `conflicts/1` at `:410`, `rejected/1` at `:415`,
all local reads. Its own moduledoc says so: *"**No Send now.** Draining is
`Kati.Sync.Engine.drain/3` and it takes an adapter… Sending is the background syncer's job"*
(`lib/kati/screens/sync.ex:114-117`). That background syncer does not exist. And screen 32
Calendars has no account-creation path at all.

**The background refresh worker is enqueued and fetches nothing.**
`Kati.Background.Periodic.ensure/0` is wired at `lib/kati/app.ex:159` and really does enqueue an
Android WorkManager job. Inside `doWork()`, where the fetch belongs, is a comment and an empty
array (`android/app/src/main/java/com/example/kati/KatiRefreshWorker.kt:202-207`); its own KDoc
at `:176` says *"Missing: the actual metadata fetch."* And the BEAM→Worker half,
`Kati.Background.Handoff.put_watchlist/2` (`lib/kati/background/handoff.ex:112`), has no caller
in `lib/`, so the worker would have no watchlist to check even if the fetch were written.

**There is no offline mode, no host allowlist and no network kill switch.**
`test/kati/host_hardening_test.exs` is about the forked Android shell — permissions, boot
receiver, ABI filters — not about outbound hosts. What does exist is the opposite: the manifest
requests `INTERNET` (`test/kati/host_hardening_test.exs:110`), `mix.exs:110-131` syncs a CA
bundle into `priv/` on every compile, `lib/kati/net/tls.ex:53-61` loads it before the first
request, and `test/kati/boot_path_test.exs:31-48` enforces that any file calling `Req` also
calls `Kati.Net.Tls.ensure!/0`. The plumbing to make a call safe is real, tested, and unused.

**Runtime egress on device today is zero.**

**One consequence worth naming.** Screen 80 *Data sources* draws a "last reached" column by
reading `CachedTitle.fetched_at` per source (`lib/kati/screens/data_sources.ex:135-152`). The
only writer of that column is `Kati.Seeds`, which never runs on device. On a real phone the
column is correctly `—` (`:121`); on any database where seeds were run, it displays a seed
timestamp as *when this source last answered*.

---

## 4. Search

Screen 19 is `Kati.Screens.Search`, and it is one of six screens the repo already classifies as
unmovable: `test/kati/screen_sample_only_test.exs:76-83` lists 06, 11, 18, 19, 22 and 23 as
still on their Sample modules, and its moduledoc names the reason for each —
*"**19 Search** — no index. Nothing anywhere matches a title, an episode, an event or a review
by substring"* (`test/kati/screen_sample_only_test.exs:20-21`).

**Does the text field capture input? No — it is not a field.** The rendered node is:

```elixir
<Text
  text={results.query}
  text_size={14.5}
  ...
/>
<Spacer size={2} />
<Box width={2} height={19} background={Palette.accent()} />
```

(`lib/kati/screens/search.ex:236-244`). The 2×19 box is the orange caret, drawn as a rectangle.
`results.query` is the literal string `"hollow"` from
`lib/kati/screens/search/sample.ex:23-31`. There is no `on_change`, no `on_submit`, no keyboard.

**Does it query anything? No.** `mount/3` assigns `Sample.results()` once and nothing ever
replaces it (`lib/kati/screens/search.ex:121`). The chip counts `6 / 3 / 2 / 1` are typed
literals, not derived — `lib/kati/screens/search/sample.ex:51-58` — and the sample's own doc
explains that deriving them from the drawn rows produces 5 and 2, which would not match the
artboard (`:36-45`).

**Trace of every handler.** `handle_info({:tap, :back}, …)` pops the screen (`:156`);
`"filter_" <> label` sets `:filter` (`:162-163`); `"recent_" <> label` sets `:recent`
(`:167-169`); everything else is `{:noreply, socket}` (`:171-176`). Filtering hides groups that
are already drawn. Tapping a recent search fills the pill and deliberately does *not* write into
the field — the screen's own moduledoc says why: *"until an index exists the screen cannot
answer the new question — so it does not pretend to have been asked"*
(`lib/kati/screens/search.ex:35-38`).

**There is a second search screen and it is the one Home opens.** The bell-adjacent search on
Home pushes `Kati.Screens.SearchIdle` (86), not 19; screen 19 is reached from the Calendar root.
Neither can accept a keystroke.

**A correction the repo owes itself.** Screen 124's comment states *"Mob has no text input,
which is why every field in this app is drawn rather than typed into"*
(`lib/kati/screens/quick_add_expense.ex:208-209`). That is false for the pinned Mob version.
`lib/kati/screens/backup.ex:984-991` renders a real `<TextField>` with `value`, `secure` and
`on_change`, handled at `backup.ex:1311-1313`, and the Android bridge maps it at
`android/app/src/main/java/com/example/kati/MobBridge.kt:3038`. Text input exists and exactly
one screen pair uses it — the backup passphrase fields. Every other screen in the app cites its
absence as the reason it cannot take typed values.

---

## 5. Routing, and what the Gallery is for

`Kati.Screens.Gallery` says what it is in its own moduledoc, and it is honest:

> **For verification**: a screen nobody can reach cannot be checked against its drawing. 53
> screens landed at once with no way in, and wiring every real entry point first would have
> meant weeks before any of them could be looked at. This makes all of them reachable in one
> move, so each can be compared now and wired into its proper place after.
>
> It is not a substitute for real navigation. The Settings rows must still push their own
> screens, Library's posters must still open a title. This is scaffolding, and `@doc false` so
> it never reads as part of the app.

— `lib/kati/screens/gallery.ex:12-20`

It lists 152 numbered screens (`lib/kati/screens/gallery.ex:29-196`) plus three undrawn ones
(`:236-253`), and it is reached from Settings' Data group by the row labelled `"Every screen"`
(`lib/kati/screens/settings.ex:664`).

### The numbers

Walking the push graph — the same walk `test/kati/app_reachability_test.exs:258-268` performs,
from the four shell roots (`lib/kati/shell.ex:50-55`) plus `Kati.Screens.LanguagePick`:

| Bucket | Count |
|---|---:|
| Reachable from a root, without going through Settings | **67** |
| Reachable only inside the first-run chain (`LanguagePick → …`) | **23** |
| Reachable only through Settings | **15** |
| **No in-app route at all — Gallery only** | **47** |
| Total | 152 |

So the owner's "only through Settings" is literally wrong — 67 screens hang off Home, Calendar,
Library and Stats, and the section trees are real: `Library → Series → Season`,
`Home → Meals today → Meal plan`, `Stats → Health → Weight → Log weight`. But the practical
picture on a set-up English phone is close to what was reported. The 23 first-run screens are
gone the moment onboarding completes — `Kati.Onboarding.first_screen/0` returns the shell root
once `complete?/0` is true (`lib/kati/onboarding.ex:79-81`) — and that range contains every
Persian mirror (55–62, 69, 72, 76, 79, 90, 97, 103, 108, 115, 127). So on a phone that has completed
onboarding in English, **70 of the 152 screens have no route but the gallery** — the 47 on the
inventory plus the 23 stranded behind a finished first run — and a further 15 need a trip to
Settings. That is 85 screens whose only door is a Settings row, and 70 of them arrive through a
row the moduledoc calls scaffolding.

### `@no_route`, verbatim

`test/kati/app_reachability_test.exs:41-179` holds the inventory. It has **47 entries**, and its
own header describes it as *"Screens with no in-app route, and why each one is allowed to have
none. An inventory, not an aspiration: wiring one fails this test, and the fix is to delete its
line"* (`:33-36`). It groups into three kinds:

**36 are reference sheets, colourways or type sizes** — pictures of states rather than places.
`Screens.States` is *"a catalogue of empty, loading and offline states for comparison against the
drawing. Not a place in the app"* (`:42-44`), and thirty-odd entries say *"in 27's manner. As
above."* `Screens.Lock` is *"a drawing of the OS lock screen showing Kati's notification.
Nothing in an app can navigate to the lock screen"* (`:90-92`); `Screens.MarkIos`,
`MarkAndroid` and `LaunchScreen` are the same argument (`:170-178`). These are legitimately
unroutable and the reasons hold.

**8 are real destinations waiting on a control that has not been drawn.** The list marks them
off explicitly at `:124-133` — *"These eight are NOT reference sheets. Each is a real destination
whose own board draws the control that opens it — and that control belongs on a PARENT screen the
23 August export did not redraw."* They are `LoudnessPrompt`, `RateEpisode`, `ShelfFilters`,
`ShelfSelection`, `DropSheet`, `AutoDetectMusic`, `NotificationAccess` and `NumberingScheme`
(`:134-162`). One of them, `DropSheet`, is the eleventh writing screen in §2.3 — a screen that
can persist, with no door.

**3 are states of a screen reached by being in that state**, not by navigating — `HomeEmpty`,
`GoalsEmpty`, `MealLibraryEmpty` (`:59-65`, `:163-166`).

The test passes as written: 152 drawings, 47 on the inventory, 105 reachable — and the fourth
assertion (`:217-233`) exists precisely to stop the other three going quiet together.

### Which roots actually lead somewhere

- **Home** → New releases, Add a title, My services, Meals today, Habits, Settings, Search-idle,
  Notifications
- **Calendar** → Search (19), Month grid, A heavy day, Event detail, Money on the calendar,
  Agenda, Quick add, Meals on the calendar
- **Library** → Series, Film, Books, Music, Up next, Discover, Lists, What fits
- **Stats** → Your year shared, Activity, Habits, Health, Goals, Money

Those trees are real navigation, and §2 is what happens at the end of them. Every film-and-TV
destination on that list — Series, Film, Up next, New releases, Season, Rating, Activity, Your
year — queries `Kati.Media` tables that nothing in `lib/` can put a row into. Books and Music
are the only branches with a working write, and issue #60 decided they are out of v1.

---

## 6. Why it ended up this way

This is not drift. It is the consequence of a decision that was written down, agreed and closed.

GitHub issue #1, *Kati — Wayfinder Map* (closed 2026-08-24), states in its **Locked decisions**
table:

> | Q1 | This map plans and researches; it does **not** implement. Prototypes are allowed as
> evidence. The owner gives the go-ahead to build. |

and under **Out of scope**:

> - **Building the app.** This map produces decisions and evidence; implementation begins on the
>   owner's word (Q1).

and in its opening statement of destination:

> **Implementation does not start until the owner says so.** Prototypes built to answer a ticket
> are throwaway evidence, not the app.

That is the honest explanation for the Sample modules, for the empty database, and for a gallery
that exists so drawings can be compared. A map that plans and does not implement produces
exactly this artefact: a complete, high-fidelity, comparable rendering of every screen, with
nothing behind it.

**It does not cover everything, and it should not be used to.** #1 rules out *building the app*;
it does not authorise a README that claims finished features. `README.md:30` says *"A calendar
that is actually a calendar — CalDAV sync, conflicts handled"*; the conflict machinery is real
and the sync is connected to nothing (§3). `README.md:33` says *"One search for everything"*;
the field cannot take a keystroke (§4). `README.md:42` says *"Bring your history — Goodreads,
StoryGraph, Letterboxd, Trakt, MyAnimeList, AniList. Name your tracker and Kati does the
mapping"*; `lib/kati/import/` contains one file, `sample.ex`, whose moduledoc reads
*"Stand-in import data, until a real CSV reader exists"* (`lib/kati/import/sample.ex:3`). There
is no CSV reader. The repo is unusually honest about all of this **in its source comments** —
`KatiRefreshWorker.kt:176`, `lib/kati/screens/sync.ex:114`, `lib/kati/import/sample.ex:3` all
state their own gaps plainly — but that honesty does not reach the README, and the README is
what a visitor reads.

Two further things #1 does not excuse, because they are defects rather than deferrals: the boot
assertion that checks two tables — one of them the throwaway spike's — and leaves the other 36
unchecked (`lib/kati/app.ex:105`), and the twelve
`rescue _error -> :ok` clauses that make a failed save indistinguishable from a successful one
(§2.3).

And one decision worth re-reading against the current state: #1's own linked ticket #60 decided
that *"v1 ships one media domain: Screen (film and TV). Books and music stay greyed out."* The
only screens in the app that can persist a user's action are Books (70) and Music (73). The one
domain v1 was supposed to ship is the one with no write path at all.

---

## 7. What it would take to close the gap

Ordered by how much each unblocks, not by size.

**1. A text input pass (#45).** Everything else is downstream of this. Mob has `<TextField>`
and Kati already uses it in `lib/kati/screens/backup.ex:984-991`; the bridge maps it at
`MobBridge.kt:3038` (`"text_field" -> MobTextField`). Until fields can take a keystroke, no
screen can persist what a user meant — which is why eleven writing screens write sample values,
and why Save on screens 33 and 119 does nothing. Fixing this converts a dozen existing `Ash.create` calls from theatre into
function.

**2. Ask for `READ_CALENDAR`.** The single cheapest change in this document, and the highest
ratio of user-visible truth to lines edited. Every part of this pipe is already built: the
manifest declares the permission (`android/app/src/main/AndroidManifest.xml:49`); the bridge
already maps the `"calendar"` capability to `READ_CALENDAR` in **both** the read map
(`MobBridge.kt:833`) and the request map (`MobBridge.kt:1000`, under a `KATI-BEGIN(K-26
calendar-permission)` fence whose own comment records that the stock map lacked it); the reader
queries `CalendarContract.Instances` and publishes JSON
(`android/app/src/main/java/com/example/kati/KatiCalendarReader.kt:42-52`); `MainActivity.kt:182`
calls it on every foreground; `lib/kati/app.ex:133` ingests it; and
`lib/kati/calendars/device_import.ex:103-195` writes real `calendars` and `events` rows. The
**only** missing piece is one `Mob.Permissions.request/2` for `:calendar` in Elixir, with
`Kati.Permissions.note_asked/1` beside it (`lib/kati/permissions.ex:85-88`). Today that call
exists nowhere: the only two `Mob.Permissions.request/2` call sites in `lib/` both ask for
`:notifications`. Screen 40 is where the Allow row is drawn, and it is drawn inert.

**3. Give the media domain a write path.** Nothing in `lib/` creates a `CachedTitle`,
`TrackedTitle` or `Watch`. Until something does, Library, Series, Film, Season, Up next, New
releases, Activity, Rating and Your year — nine reachable screens, all querying Ash correctly —
can only ever draw their Samples. The minimum viable version is not TMDB: it is *Add a title*
(06) writing a `CachedTitle` + `TrackedTitle` from typed text, and screen 04's episode tick
writing a `Watch` instead of a socket assign (`lib/kati/screens/series.ex:1061`).

**4. Wire one TMDB call.** Issue #56 already decided the key model. `lib/kati/net/tls.ex` and
the CA bundle are ready, `test/kati/boot_path_test.exs:31-48` already enforces the safety
contract, and `KatiRefreshWorker.kt:202-207` is a labelled hole with the diff strategy already spelled
out in comments. One
`/3/search/tv` call behind screen 06 makes the whole media spine real.

**5. Fix the boot assertion, and stop swallowing write failures.** Change
`lib/kati/app.ex:105` to assert the tables the app actually reads, and replace the twelve
`rescue _error -> :ok` clauses with something the screen can show. Both are small; both are the
difference between a defect that reports itself and one that presents as dummy data.

**6. Give the eight drawn-and-waiting screens their controls.**
`test/kati/app_reachability_test.exs:134-162` already names the exact edit each one needs — a filter disc in the header of 03/20/21, a long
press on an episode row in 04, a mode switch at the top of 36. One of them, `DropSheet`, already
writes to Ash.

**7. Connect the sync engine, or say it is not in v1.** The CalDAV adapter, the outbox, the
tombstones, the rejection log and ~1500 lines of `lib/kati/sync/` are finished and unreferenced.
Either `Kati.Sync.Engine` joins the supervision tree with a credential-entry screen in front of
it, or the README stops claiming CalDAV sync. Issue #52 already decided that Android's
`CalendarContract` is the intended route to every calendar server — which makes step 2 the
higher-value half of this, and the CalDAV client an asset in waiting rather than a gap.

**8. Delete `Kati.Spike`.** Its own moduledoc asks for it (`lib/kati/spike.ex:5-6`), and it
ships a table to every device.

---

## Confidence and limits

- **The data classification** is derived from compiled BEAM import tables and closed
  transitively over the app's own modules. It answers *can this screen reach a store*, not
  *does this pixel come from a row*. A screen marked "Ash (indirect)" may reach Ash through a
  helper it calls for an unrelated reason; the `Fallback` column and §2.2 are what make the
  device behaviour clear.
- **The routing walk** is static. It dispatches `handle_info({:tap, tag}, …)` for every tag a
  freshly mounted screen renders, plus one level of opened menus. A control that only appears
  after some other state change would be invisible to it, so the 47 is a ceiling on stranded
  screens, not a floor. It is also the same walk the repo's own test uses, and that test passes.
- **I have not run the app on a device.** Every claim here is from source, tests and the
  compiled artefacts. Where behaviour depends on what `mix mob.deploy` copied to the phone —
  most importantly whether all 18 migrations are present — I cannot tell from here, and
  `lib/kati/app.ex:105` cannot tell you either.
- **`Kati.Screens.Sync`, `InboxNotifications` and `NotificationsHelp`** have no artboard and are
  not among the 152. They are store-readers and appear in the reachability graph, but not in the
  table above.
