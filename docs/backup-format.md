# The Kati backup format (`.katibackup`)

Kati sets `android:allowBackup="false"`, has no server and no account, and keeps its
database in app-private storage a file browser cannot reach. Those are three good
decisions that compose into one bad outcome: a lost, stolen, broken or replaced phone
is the **total and unrecoverable** loss of everything the user ever logged. Export is
the only insurance policy, and a restore nobody can run is worse than no backup at all,
because it is a false comfort.

This document is the format, published so that the data outlives the app. Anyone can
write a reader or a converter against it without running Kati.

Implementation: [`lib/kati/backup/`](../lib/kati/backup). JSON Schemas:
[`manifest.schema.json`](backup/manifest.schema.json),
[`payload.schema.json`](backup/payload.schema.json).

---

## 1. The container

A `.katibackup` is a **zip archive of JSON files**. It is deliberately not a copy of
`kati.db`: a SQLite file is opaque, coupled to the schema version that wrote it, and
unrepairable by hand. JSON is diffable, greppable and salvageable with a text editor on
any machine the user owns.

```
kati-backup-2026-08-21.katibackup
├── manifest.json
└── data/
    ├── calendar_accounts.json
    ├── calendars.json
    ├── events.json
    ├── event_occurrence_overrides.json
    ├── tracked_titles.json
    ├── media_watches.json
    ├── foods.json
    ├── recipes.json
    ├── recipe_ingredients.json
    ├── meal_plans.json
    ├── meal_plan_slots.json
    ├── meal_logs.json
    └── shopping_list_items.json
```

Every backed-up table has a file, **even when it is empty**. A missing file is a
damaged backup, not an empty table.

Two exports of the same data produce byte-identical payload files: rows are sorted by
primary key and columns by name, so a payload's SHA-256 depends on the data and nothing
else. Only `manifest.json` differs, and only in `exported_at`.

## 2. `manifest.json`

```json
{
  "format": "kati.backup",
  "format_version": 1,
  "schema_version": 1,
  "app_version": "0.1.2",
  "exported_at": "2026-08-21T18:44:02.913044Z",
  "record_counts": { "events": 412, "media_watches": 1203, "meal_logs": 88 },
  "dropped_columns": { "calendar_accounts.credentials_ref": 1 },
  "files": {
    "data/events.json": { "sha256": "9f2c…", "bytes": 481203 }
  }
}
```

| Field | Meaning |
| --- | --- |
| `format` | Always `"kati.backup"`. A file without it is not a Kati backup. |
| `format_version` | The archive layout: member names, manifest shape, hashing. |
| `schema_version` | The row shapes: which tables, which columns, how a value is spelled. |
| `app_version` | Informational. Nothing branches on it. |
| `exported_at` | UTC, ISO-8601, always with a `Z`. |
| `record_counts` | Rows per table. What a confirmation screen shows before a restore. |
| `dropped_columns` | `"table.column" → how many rows held a value that was deliberately not written`. See §5. Columns that dropped nothing are absent. |
| `files` | SHA-256 (lowercase hex) and byte length of every payload. `manifest.json` does not hash itself. |

## 3. `data/<table>.json`

```json
{
  "resource": "Kati.Calendars.Event",
  "table": "events",
  "count": 2,
  "columns": ["calendar_id", "created_utc", "deleted_at", "…"],
  "rows": [
    { "calendar_id": "0189…", "created_utc": null, "…": "…" }
  ]
}
```

`columns` is sorted and identical for every row in the file. Each row is a JSON object
whose keys are **exactly** that column set — no extra key, no missing key, including
the columns that are always `null` (§5). A reader that finds a key it does not know is
reading a file from a newer Kati and must stop; see §6.

## 4. How a value is spelled

| Column type | JSON | Example |
| --- | --- | --- |
| uuid | string | `"0189f0a1-2b3c-4d5e-8f90-1234567890ab"` |
| string | string | `"Miso salmon"` |
| integer | number | `-42` |
| float | number | `1.5` |
| boolean | `true` / `false` | `false` |
| atom (enumeration) | string | `"eaten"` |
| date | `YYYY-MM-DD` | `"2026-08-16"` |
| time | `HH:MM:SS.ffffff` | `"19:00:00.000000"` |
| instant | ISO-8601 with offset | `"2026-08-16T18:05:00.000000Z"` |
| decimal | **string** | `"12.3400"` |
| anything null | `null` | |

Two rules a reader can rely on:

- **Every date, time and instant is Gregorian ISO-8601 in ASCII digits**, whatever the
  app's locale draws on screen. A `fa`-locale export shows `۱۴۰۵/۰۵/۲۵` to the user and
  writes `2026-08-16` to the file. Persian text is preserved verbatim in the fields
  where the user typed it — notes, reviews, titles — and only there.
- **A decimal is a string**, never a JSON number, so nothing rounds it on the way back.

## 5. What is in a backup, and what is not

A table is in the backup when a row in it can hold something **the user authored** —
typed, ticked, rated, planned, corrected — that no network and no re-seed can
reproduce.

### In the backup (`:backup`)

| Resource | Table | What it holds |
| --- | --- | --- |
| `Kati.Calendars.Account` | `calendar_accounts` | The calendar sources the user connected |
| `Kati.Calendars.Calendar` | `calendars` | Their calendars, colours and visibility |
| `Kati.Calendars.Event` | `events` | Every event Kati owns, and the retained bytes of every one it mirrors |
| `Kati.Calendars.Override` | `event_occurrence_overrides` | "Just this Tuesday" — moved and cancelled instances |
| `Kati.Media.TrackedTitle` | `tracked_titles` | Status, position, rating, per-show switches, hand-typed release dates |
| `Kati.Media.Watch` | `media_watches` | Every tick, log, review, rewatch, place and companion |
| `Kati.Meals.Food` | `foods` | Foods Kati or the user wrote, and remembered prices |
| `Kati.Meals.Recipe` | `recipes` | Recipes, methods, notes, ratings, cached totals |
| `Kati.Meals.RecipeIngredient` | `recipe_ingredients` | Every ingredient line, with its own figures |
| `Kati.Meals.MealPlan` | `meal_plans` | Plans, targets, reminder rules |
| `Kati.Meals.MealPlanSlot` | `meal_plan_slots` | The slots a plan is made of |
| `Kati.Meals.MealLog` | `meal_logs` | What was eaten, **with the figures frozen at the moment it was logged** |
| `Kati.Meals.ShoppingListItem` | `shopping_list_items` | The list, what was got, what it cost |

### Not in the backup

| Resource | Class | Why not |
| --- | --- | --- |
| `Kati.Media.CachedTitle` | `:cache` | Third-party title metadata under a provider's terms, behind a `fetched_at` eviction sweep. Restoring it seven months later would be restoring someone else's data under terms that expired — and it re-fetches on its own. The user's half references it by `{source, source_id}` as a *value*, not a foreign key, so leaving it out orphans nothing. |
| `Kati.Meals.LicensedFood` | `:cache` | Food data under someone else's licence, with a not-null `fetched_at` so the same sweep reaches it. Re-fetched, never re-distributed. |
| `Kati.Meals.BundledFood` | `:bundled` | The CC0 corpus shipped in `priv/`. Byte-identical on every install, so a copy in the file is size for nothing. |
| `Kati.Spike.Thing` | `:internal` | A migration spike. Holds no user data. |

Posters, backdrops and synopses are in none of the above and in no backup. A backup
carries **ids plus what the user did**; metadata re-fetches.

### The three dropped columns

Three columns are written as `null` in every export. They are still columns — the key
is present with a `null` value — so a restore can tell "deliberately dropped" from
"unknown field".

| Column | Why |
| --- | --- |
| `recipe_ingredients.bundled_food_id` | Points into a table the backup does not carry. SQLite enforces foreign keys, so restoring the reference would fail on the missing row. |
| `recipe_ingredients.licensed_food_id` | The same, for the licensed corpus. |
| `calendar_accounts.credentials_ref` | An opaque handle into the device keystore. A restored account claiming a key the new phone has never held is worse than one that knows it must re-authenticate. No OAuth token or other credential is ever written to a backup. |

What is lost with the first two is **provenance only**: an ingredient row carries its
own name, amount, unit, aisle and all seven nutrition figures, so a recipe restores
whole and correct. Every drop is counted into `manifest.dropped_columns`, so the loss
is stated in the file rather than discovered later.

Any column a resource marks `sensitive?` is dropped by the same mechanism,
automatically.

## 6. Versions

`format_version` and `schema_version` move independently, because the container and the
rows change for different reasons.

**A file whose either version is newer than the reading app is refused outright**, with
a message naming both numbers. It is not read field by field and it is not partially
applied — a newer file may contain a column this app would drop on the floor, and a
restore that silently drops a column is a restore that loses the data it was run to
save.

**An older `schema_version` must keep working forever.** `Kati.Backup.Upgrade` holds a
chain of `{from, to, fun}` steps that bring rows forward one version at a time, applied
before any column is decoded. There are no steps yet, because there has only ever been
one schema version.

`schema_version` moves whenever a backed-up column is added, removed, renamed, or
changes encoding. `Kati.BackupCatalogTest` pins a SHA-256 fingerprint of every
backed-up table and column, so the change fails the build and the decision has to be
made deliberately.

## 7. Restoring

### Verification, all of it, before the first write

In order: the archive opens and is not absurdly large; `manifest.json` is present,
readable, and of a version this app understands; the member list is exactly what the
manifest claims, with no extra file smuggled in; every payload's SHA-256 and byte
length match; every payload parses; rows are brought forward to the current schema
version; every table is one this app knows; every row carries exactly the columns that
table has; every value decodes to its column's type; no primary key appears twice; the
row counts agree with the manifest.

Only then does anything get written. **Every error means the database was not touched.**

### One transaction

`AshSqlite` reports `can?(:transact) == false`, so an Ash action is not atomic and a
thirteen-table restore is thousands of separate writes. The repository underneath is
still Ecto and still SQLite, so the whole restore — the deletes and the inserts both —
runs inside one `Kati.Repo.transaction/1`. Any failure at any point rolls back
everything, including a `:replace`'s wipe. A restore either happened or it did not.

### Rows go in exactly as they came out

Writes bypass Ash actions entirely (`Ash.Seed.seed!/2`). That is the requirement, not a
shortcut: replaying create actions would let `Kati.Media.Changes.Touch` stamp
`last_touched_at` with the moment of the restore and reorder every shelf, would replace
`inserted_at` with today, and would recompute `Kati.Meals.MealLog`'s nutrition figures
from whatever the recipe says **now** — destroying the frozen-history property that
exists precisely so an edit made next week cannot rewrite last Thursday. A restore
replays **rows**, not the user's actions.

### What happens to rows that are already there

Three modes. The default is the refusal, because it is the only one with no way to lose
anything.

| Mode | What it does | What it cannot do |
| --- | --- | --- |
| `:into_empty` *(default)* | Refuses unless every backed-up table is empty, and names what it found. | Lose anything. |
| `:merge` | Insert-only, by primary key. A row whose id is already present is **skipped** and reported; nothing existing is overwritten, updated or deleted. | Overwrite. A backup row that collides with an existing row on a *natural* key instead of an id — the same show tracked again on the new phone under a fresh id — refuses the whole restore rather than guessing which of the two the user meant. |
| `:replace` | Empties the backed-up tables and puts the backup in their place. Reachable only by asking for it **and** by supplying a sink that successfully takes an export of the current state first. If that safety export cannot be written, the wipe does not happen. | Delete anything that has not already been saved somewhere else. |

`:merge`'s natural-key refusal is a deliberate v1 limit. Choosing between two rows that
mean the same thing is a per-conflict decision with a screen attached to it; a lossless
restore must not wait for that screen to exist.

A `:replace` does not touch the excluded tables: the cache is not the backup's to
delete, and not the backup's to fill.

## 8. Writing a reader

Everything needed is in this document, and the format is stable within a
`format_version`. A minimal reader:

1. Unzip.
2. Read `manifest.json`; refuse if `format != "kati.backup"` or either version is
   newer than you understand.
3. For each entry in `files`, check SHA-256 and byte length before parsing.
4. Read `data/<table>.json`; the rows are what you want, decoded per §4.

The one thing worth repeating: **the figures on a `meal_logs` row are the figures as of
the moment that meal was logged.** They are not to be recomputed from the recipe the
row points at. That is the whole reason the columns exist.
