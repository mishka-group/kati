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

- **`Kati.Screens.AnimeFilter` (board 152) + `Kati.Media.AnimeSample`** — same
  gap: `:anime` is a real `:kind`, but the per-title override, the
  import-provenance flag and the "does this household watch anime" onboarding
  answer none exist as columns yet.

- **`Kati.Screens.ShelfSelection` (board 146)** — two of its three bands are
  explicitly stills — a picture of Library's resting header, not a second
  implementation of it — and its counts (`41 OF 418`, `4 selected`) are the
  board's own frozen figures by design, not a live count. Read the file's own
  moduledoc before touching it; this one already knows what it is.

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
