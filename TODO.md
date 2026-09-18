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
