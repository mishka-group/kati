# TODO — scaffolding to revisit

Owner's rule (18 September 2026): every page built to show UI before its
domain existed must eventually become real and have its sample deleted; a
page with **no domain and no use case at all** goes here instead, with why it
was built, so it can be judged — kept or deleted — once the app is otherwise
finished. Don't act on anything below without asking first.

Scope right now is film and series only (and their settings). Other sections
get their own pass later.

## Confirmed real, not scaffolding (verified on-device, 18 Sep 2026)

Audited by reading `load/1`/`content/1` for every screen in scope and
confirming zero direct `*Sample.` calls in the render path, then verified
visually on the Pixel_9a emulator with real TMDB data (`Dark`, `Arcane`,
`Severance` — real posters, real episode titles, real air dates): Home,
Library, Series detail, the series `···` menu, Series settings, My services.
`mix mob.routes` — 201/201 navigation references valid — covers the rest of
the app's screen graph, not just this list.

**Film detail (board 08)** was the one screen in this list left unverified —
no movie-kind title existed in the seed data, only three TV series. Closed
18 Sep 2026: the emulator's DNS could not reach TMDB that session (host had
real internet — `curl` to `api.themoviedb.org` worked — but the emulator's
own resolver could not, survived a reboot, and was left as an environment
issue rather than chased further), so the title was created through
`Kati.Screens.AddByHand` — the app's own real "add manually" flow a user
hits in the identical situation — rather than through a live TMDB fetch. The
resulting `TrackedTitle`/`CachedTitle` pair is a genuine Ash-created record,
not a fixture. Confirmed on-device: the page rendered in full (no crash, no
missing section), the "Where to watch" empty-service band matched
`Kati.Screens.NothingSetUpKnockOn`, and its `my_services_where_to_watch` tap
pushed `Kati.Screens.MyServices` correctly — the live confirmation of the
`dfbd596` nav-crash fix from earlier this session, in its real calling
screen. The test title was removed afterward with
`Kati.Screens.AddTitle.untrack/1`, the same function a real "untrack" tap
calls; its `CachedTitle` remnant was left in place, matching documented,
real `untrack/1` behavior for every user, not a leftover fixture.

These are not on this TODO. Don't re-audit them without a reason.

## Widened, 18 Sep 2026 (later same day) — every remaining `*Sample` module in scope

Prompted by a direct question: is every film/series Sample module gone from
its screen's real render path? The list above only covered the screens
audited by hand that day. A second pass checked every other film/series-scope
Sample module (`Kati.Library.Sample`, `UpNextFiltersSample`,
`SeriesSettings.Sample`, `Season.Sample`, `Discover.Sample`,
`WhatFits.Sample`, `UpNext.Sample`, `WatcherSample`, `DropStatesSample`,
`Services.Sample`, `Subscriptions.Sample`, `Rating.Sample`, `Lists.Sample`,
`DropSheet.Sample`, `HomeDark`'s Sample) for the same thing: a call reachable
from a real render path with real data available.

Almost all of it turned out to be the same already-accepted pattern used by
`Kati.Screens.ShelfFilters`/`Kati.Screens.Film` and named in the section
above — `real() || Sample.drawn()`, an all-or-nothing gate that only shows
the drawing when the reader's own store is genuinely empty — just not yet
written down here. `Kati.Subscriptions.ledger/0` in particular is fully real
for any reader with a subscribed service (real hours, derived from `Watch` +
`CachedTitle.providers`, real totals from `Kati.Services.Service`) —
`HANDOFF.md`'s claim that screen 23 is still sample-only predates that work
and is wrong.

One genuine, trivial residual found and fixed the same day:
**`Kati.Screens.Lists`** — `tile_art/1` called `Sample.poster/1`, a one-line
pass-through to `Kati.Design.Images.poster/1` with no logic of its own. Fixed
to call `Kati.Design.Images.poster/1` directly and removed the now-dead
delegate from `Kati.Screens.Lists.Sample`. `Sample.lists/0` stays — it is
still the genuine empty-shelf fallback `Kati.Screens.Lists.Sample`'s own
moduledoc describes, and `Kati.ScreenDesignLiteralTest` still reads it.

Two genuine schema gaps found, matching the class already listed below —
added there rather than fixed, per the "don't act without asking" rule:
**`Kati.Screens.Discover`** and **`Kati.Screens.ReleaseWatcher`**.

**`HomeDark`**'s header (`Sample.moment/0`) is the one item this whole pass
found that HANDOFF.md already named correctly — it is real, cross-referenced
below rather than duplicated.

**`HANDOFF.md` itself is stale** — it names issues (#89–#94), a commit range
ending `d7150fa`, and a `dev` branch with nothing pushed, none of which match
current `git log` (`origin/master`, well past that point, with two whole
Persian-sweep phases and this file's own history since). Its "What is left"
list is one-for-four right against current code: `HomeDark` still holds;
Subscriptions does not. Worth a decision on whether to rewrite or retire it
rather than leave a doc a new reader would trust and be misled by.

## Fixed, 18 Sep 2026 (later still) — AnimeFilter no longer scaffolding

**`Kati.Screens.AnimeFilter` (board 152)** was listed above as blocked on
schema that turned out to already exist: `TrackedTitle.anime_override`
(a real column, contradicting `AnimeSample`'s own stale moduledoc) and
`TrackedTitle.source`'s import-provenance constraints
(`:jikan`/`:anilist`/etc., via `Kati.Import.Mapping.looks_like/1`).
`load/1` rewritten to compute `type_counts`, `tab_counts`, `anime_count`,
`misclassified` (a real per-title guess against `Kati.Media.Anime`'s
existing classifier) and `watches_anime?` from the real store; the "fix
misclassification" tap now does a real `Ash.update/2` on
`anime_override`. `threshold`/`rules` stay on `Sample` — they describe the
app's own fixed rules, not personal data, so that is correct, not a gap.
Verified via `test/kati/screen_empty_database_test.exs` (`misclassified/0`
moved from `fallbacks/1` to `empties/1`) and the existing screen test
suite; committed `c5784a9`.

## Genuine scaffolding — no domain exists yet

- **`Kati.Screens.AutoDetect` (board 36) + `Kati.Settings.DetectSample`** —
  auto-detect needs Android's `NOTIFICATION_LISTENER`, which Play Protect
  blocks for a sideloaded APK. There is no bridge, so there is nothing real to
  read; the sample is the design record for a feature that cannot ship on
  this distribution channel. Decide: build a bridge some other way, or drop
  the feature and delete both the screen and the sample.

- **`Kati.Screens.NumberingScheme` (board 153)** — argues for a per-title
  numbering override. `Kati.Media.TrackedTitle`/`CachedTitle` have no
  `type_override` column and nothing writes import provenance. Its own
  moduledoc says so. Needs the schema work before it can read anything.

- **`Kati.Screens.ShelfSelection` (board 146)** — two of its three bands are
  explicitly stills — a picture of Library's resting header, not a second
  implementation of it — and its counts (`41 OF 418`, `4 selected`) are the
  board's own frozen figures by design, not a live count. Read the file's own
  moduledoc before touching it; this one already knows what it is.

- **`Kati.Screens.Discover` + `Kati.Screens.Discover.Sample`** — `feed/0`
  itself is real and gated correctly, but four of its five sections have
  nothing behind them yet: match score, people/follow, leaving-soon
  availability and the tuned-corpus count. All four are blanked in the real
  path rather than made real, because none of `Kati.Media`'s resources carry
  the columns for a match score, a followed-person, or a per-shelf tuned
  count. Needs the same kind of schema decision as `NumberingScheme`/
  `AnimeFilter` before any of the four can read something.

- **`Kati.Screens.ReleaseWatcher` (board 25) + `Kati.Settings.WatcherSample`**
  — its own moduledoc says so directly: 13 of its 15 controls have no
  preferences domain to read, and stay on the Sample honestly rather than
  silently. Two controls (cadence, "New episodes") are already real, through
  `Mob.State`. The banner conditionally reads real data with the same
  documented empty-store fallback used elsewhere. Needs the schema work
  before the other 13 can follow.

## Reachable but worth a second look

- **`Kati.Screens.Gallery`** ("Every screen", `Kati.Settings.Sample`'s
  `every_screen` row) is a REAL, shipped, translated feature — not internal
  tooling — confirmed by `lib/kati/settings/sample.ex`'s own comment: it used
  to live behind a hidden entry and was deliberately moved to a visible
  Settings row once every screen became reachable. That means every screen it
  lists is something a real user can open, including the design-reference
  boards above. Worth asking the owner whether a real user should be able to
  reach `NumberingScheme`/`AnimeFilter`/`AutoDetect`'s honest "not built yet"
  state this way, or whether Gallery itself should filter those out.

- **`Kati.Screens.HomeDark` (board 28)** — real everywhere except its header,
  which stays pinned to `Sample.moment/0`. Already named in `HANDOFF.md`
  rather than fixed: unpinning needs headroom in `ScreenDesignLiteralTest`'s
  capped device-values allow-list, and the board is gallery-only (real dark
  mode goes through `Kati.Theme.Palette` on the live `Kati.Screens.Home`, not
  through this module), so nothing in production shows the frozen date.
  Belongs on the same "should Gallery expose this" question as the row above.

- **`Kati.Screens.DropStates` (board 148) + `Kati.Settings.DropStatesSample`**
  — the same kind of static, no-domain specimen sheet as board 27's
  `StatesSample` and `Kati.Screens.EpisodeRatings` (board 143): a picture of
  what "paused / dropped / cold" look like, not a live query. Its real,
  live sibling — the actual drop sheet a reader hits from a title's `···`
  menu — is `Kati.Screens.DropSheet`, already confirmed real this session.
  Reachable through a real Settings row ("Dropping", under About), same
  question as Gallery above.
