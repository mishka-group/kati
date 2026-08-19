# What "finished" means, in the owner's words

Four requirements, none of them met yet. Recorded so they are not re-litigated.

## 1. Every page, not the nine that exist

**9 of 62 built** (01–09). The rest are untouched, including all eight Persian
mirrors (55–62). Any page the app needs that the design does not draw gets
invented in the design's language.

## 2. The design's own images

The export uses **130 `<image-slot>`s across 42 unique picsum seeds** —
`https://picsum.photos/seed/ashfall42/400/600` and so on. Deterministic: the
same seed is always the same photograph. All 50 distinct seed+size
combinations are downloaded to `priv/sample/design/` (1.5 MB) and the manifest
is `.scratch/design/image_slots.json`, which keeps each slot's `id`,
`placeholder` and dimensions so a slot can be matched to the screen it belongs
to.

The generated posters in `priv/sample/posters/` were a stopgap and should go:
they carry titles baked into the pixels, which is wrong twice over — the
design puts the title in a caption below, and a baked title cannot localise.

## 3. Data in the database, not in modules

The `Sample` modules (`Kati.Library.Sample`, `Kati.Stats.Sample`,
`Kati.Calendar.SampleDay`) hard-code what the screens show. They were the
right first step — a screen with no data cannot be compared with its drawing —
but they bypass the query paths the real app uses.

Next: seed the design's content into **Ash/SQLite** so every screen reads it
the way it will read real data. That makes the pages browsable end to end for
manual comparison, and it exercises the resources rather than the fixtures.
`Kati.Calendars.*` already works this way; media, meals, money and habits need
resources before they can.

## 4. Everything interactive actually works

Chips must filter. Segments must switch. The day strip must change the day.
Checkboxes must toggle and persist. Tapping a row must open the row it names.
A hardcoded chip that highlights but filters nothing is a screenshot, not an
app — and it is the kind of thing that looks finished and is not.

## Components → Mishka Chelekom

Per #44: build each component in `lib/kati/components/` first, use it in Kati,
and only then promote it to Mishka Chelekom **in that repo's own pattern**
(component + showcase + unit test + Kotlin e2e + `mix mishka.mob.sync` +
usage-rules doc + CHANGELOG, per its `mob-component-fix` skill). Nothing is
promoted before Kati has used it in anger.

Blocked: **#78** — `mishka.ui.gen.mob` hangs under a path dependency (23
minutes at 82–97% CPU, no output), so components cannot currently be generated
*from* Mishka into Kati. Kati-side components are unaffected.
