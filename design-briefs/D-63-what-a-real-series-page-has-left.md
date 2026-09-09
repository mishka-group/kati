# What a real series page has left

> **One board** · ticket `D-63`

Found on a device, closing MOVIES-AND-TV.md #51.

Screen 14 — *Show details*, reached from screen 04's ⋯ — used to draw
`Kati.Screens.SeriesMeta.Sample` on every arrival. *Show details* on Severance
opened a page about *The Long Hollow*: a synopsis about a tidal surveyor, three
ratings, four cast members with their character names, three priced ways to
watch and five tags the reader never wrote.

That is fixed (`5915c2a`). The push names the row, the page reads it, and the
four values the store can express — the title, the still, the meta line, the
synopsis — are that show's. The seven it cannot are empty, and their headings
are dropped with them.

Which leaves the page in the state this brief is about. On a real series, board
14 is now: a 270pt still, a title, one mono meta line, a paragraph, and then
1100pt of paper.

## Why this is a board question and not a patch

The four dropped bands are not dropped for want of wiring. Screen 14's own
moduledoc lists them and what each would need:

* **Cast** — no person resource, no credit resource, no column. Kati has no
  people table and its own `Kati.Media.Watch.companions` says inventing one
  *"would be a larger privacy decision than the feature is asking for"*.
* **Audience and Critics** — other people's scores; nothing caches them.
* **Where to watch** — the offers resource screen 08 also names. Availability,
  pricing and physical ownership; `Kati.Media.Watch.service` is per-watch and
  carries none of them.
* **Your tags** — `Kati.Media.Watch.tags` is tags on one night's watch, not on
  the title.
* **Trailer** — no video, no link, no column.

None of those arrives this round. So the question is what a page about a show
says when it can only say true things, and that is a layout, not a value.

## What the store can already answer

Every one of these exists today, unread by screen 14, and each is about the
show rather than about a night of it:

| Value | Where it lives | Reads as |
|---|---|---|
| Status | `Kati.Media.TrackedTitle.status` | `Watching` · `Paused` · `Finished` |
| Next airing | `Kati.Media.CachedEpisode.air_at`, with `date_confidence` | `Next episode Fri 12 Sep` |
| Episode length | `Kati.Media.CachedTitle.runtime_minutes` | `Episodes ≈ 59 min` |
| Seasons | `Kati.Media.CachedSeason` rows | `S1 9 · S2 10 · S3 —` |
| Progress | the ticks screen 04 already counts | `11 of 19 watched` |
| Original title | `Kati.Media.CachedTitle.title_original` | under the title, when it differs |
| Where it came from | `source` and the id columns | `TMDB` — the attribution screen 96 argues for |

Screen 04 draws the third, fourth and fifth already, in its own idiom. A board
that repeated them would make *Show details* a second copy of the page it is
reached from, which is the thing to avoid: 04 answers *what do I watch next*
and 14 answers *what is this thing*, and the split is the whole reason 14
exists.

## What to draw

| Board | What it is |
|---|---|
| **new** | Screen 14 on a real series. The still, the title, the meta line and the synopsis are as built. Below them, a card group of the facts above that 04 does not already draw — status, next airing, episode length, original title, provider — in the card rhythm every other screen uses. No eyebrow over an empty section, and nothing that needs a resource this app has not got. |

The board must also say what happens as each absent resource arrives: where a
cast band would slot back in, and where offers would. A layout that only works
while those are missing is a layout that has to be redrawn twice.

## Acceptance

* A device with one tracked series opens *Show details* and every line on the
  page is about that series.
* No line on the page is a value the store cannot answer. The test that holds
  this is `Kati.SeriesMetaSubjectTest`, and it must still pass unchanged in its
  claim that `cast`, `where`, `tags` and `ratings` are `[]`.
* An empty store still draws board 14 whole — `Kati.ScreenEmptyDatabaseTest`
  gates it at `series/0`.
* Nothing on the new board duplicates a card screen 04 already draws.
