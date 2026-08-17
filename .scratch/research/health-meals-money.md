# Health, meals and money — resolving K-41

Research answer for wayfinder ticket `K-41` (issue #68). Subject: screens 42–52 (the health and
meal cluster) plus screen 23 (the subscription ledger).

Everything below is either cited to a URL, cited to a repo file with a line number, or marked
**UNKNOWN**. Where an existing research file is wrong, that is said plainly rather than repeated.

---

## 0. The four verdicts, up front

| # | Question | Verdict |
|---|---|---|
| 1 | **Nutrition data source** | **Bundle USDA FoodData Central (Foundation + SR Legacy) as a ~1 MB SQLite file in `priv/`.** CC0 1.0 public domain, **no API key for bulk downloads**, no share-alike. Open Food Facts is ODbL — usable only as a *separate, unmerged* bundled file, and not in v1. FatSecret and Nutritionix are ruled out: both forbid offline bundling and both need shipped secrets. **No Persian food dataset exists anywhere** — Kati authors that layer itself. §1 |
| 2 | **Recipe / food / portion model** | **First-class Ash resources** — `foods`, `recipes`, `recipe_ingredients`, `meal_plans`, `meal_plan_slots`, `meal_logs`, `shopping_list_items` — not denormalised meal entries. The portion multiplier is `Decimal` arithmetic over an in-memory struct, never a query. `meal_logs` stores a **frozen nutrition snapshot**, or every past adherence figure silently changes when a recipe is edited. Aisle is a fixed 14-value Kati-owned enum. §2 |
| 3 | **Currency** | **Single-currency storage and display. Kati never converts.** ISO 4217 code stored **per row**, amounts as `:decimal`. Mixed-currency totals are refused, not guessed. The design already says so: the Persian screens show `۸٫۹۹ پوند` — pounds, in Persian. §3 |
| 4 | **PDF** | **A concrete Android path exists — WebView + `PrintManager`, with "Save as PDF" as a pure-AOSP destination — but do not build it for v1.** Retire "Print the week (PDF)" as K-43's first worked example. No pure-Elixir library can typeset Persian: the blocker is specifically the **absence of any UAX #9 bidi implementation on Hex**, not missing shaping. And D-20's proposed image fallback is **more** expensive, not less — `Mob.Canvas` has no snapshot function and `Mob.Share` is text-only. §4 |

---

## 1. Nutrition data

**Verdict: bundle a subset of USDA FoodData Central (Foundation Foods + SR Legacy) as an indexed
SQLite file in `priv/`. It is CC0 1.0 public domain, needs no API key even for the bulk download,
carries no share-alike, and a bilingual subset with the six macro figures costs about 1 MB. Open
Food Facts is usable but only as a separate, unmerged, ODbL-licensed file. FatSecret and Nutritionix
are ruled out — both forbid the offline bundling Kati's architecture requires and both need shipped
secrets.**

### 1.1 The candidates

| Source | Licence | Bundle? | Key/secret? | Share-alike | Bulk size |
|---|---|---|---|---|---|
| **USDA FoodData Central** | **CC0 1.0 / US public domain** | **yes** | **none for bulk** | **none** | Foundation CSV 3.65 MB zip · SR Legacy CSV 5.79 MB zip · full 459 MiB |
| Open Food Facts | ODbL 1.0 (db) · DbCL 1.0 (contents) · CC BY-SA 3.0 (images) | yes, **separately** | none (UA required) | **yes, on derived databases** | CSV.gz 1.19 GiB · JSONL.gz 11.8 GiB · Mongo 14.4 GiB |
| UK CoFID (McCance & Widdowson) | Open Government Licence v3.0 | yes | none | none | 4.63 MB xlsx, 2,889 foods |
| Danish FCDB (DTU Frida) | CC BY 4.0 | yes | none | none | 12.01 MB xlsx |
| Canadian Nutrient File | Open Government Licence – Canada | yes | none | none | ~5,993 foods; **exact size UNKNOWN** |
| FatSecret Platform API | proprietary | **no — prohibited** | key **+ secret** | n/a | n/a |
| Nutritionix | **terms not publicly readable** | **no** | app id + key | n/a | commercial CSV export |

### 1.2 USDA FoodData Central — the recommendation

**Licence.** *"USDA FoodData Central data are in the public domain and they are not copyrighted.
They are published under CC0 1.0 Universal (CC0 1.0) No permission is needed for their use, but we
request that users list FoodData Central as the source of the data…"* —
<https://fdc.nal.usda.gov/api-guide/>. Note the trap: **the licence statement appears only on the
API Guide page**; `/data-documentation/` and `/faq/` carry no licence text at all.

**The API key does not apply to bulk downloads.** This is the fact that makes FDC shippable in an
open-source repo. `api.nal.usda.gov` needs an `api.data.gov` key; the ZIP downloads at
<https://fdc.nal.usda.gov/download-datasets/> do not — verified twice, once by a plain `curl` of
`FoodData_Central_sr_legacy_food_csv_2018-04.zip` returning HTTP 200 with no auth, and once
against the download page itself, which states no registration requirement. **So Kati ships zero
secrets**, and none of K-29's API-key tier machinery applies here.

**Which datasets.** Foundation Foods (395 rigorously analysed foods, 2026-04-30) plus SR Legacy
(7,793 generic foods, frozen at 2018-04). These are **generic raw ingredients**, which is exactly
what a recipe ingredient list needs. Skip Branded Foods (~2.9 GB, US retail packaging) and FNDDS
(survey composites) for v1.

**Measured subset sizes**, built by extracting `fdc_id`, `description` and the six nutrients
(1008 kcal, 1003 protein, 1005 carbohydrate-by-difference, 1004 fat, 1079 fibre, 2000/1063 sugars):

| Subset | Format | On disk | Gzipped |
|---|---|---|---|
| 3,000 common foods | SQLite + index | **0.35 MB** | 0.13 MB |
| 3,000 common foods | SQLite + FTS5 name search | **0.34 MB** | 0.14 MB |
| SR Legacy + Foundation, all 7,928 | SQLite + FTS5 | **1.09 MB** | 0.38 MB |

Add ~0.2 MB for Persian names on 3,000 rows and ~0.3–0.5 MB for household portions
(`food_portion.csv`, needed for *"1 cup"*, *"1 medium"*). **A realistic bilingual EN+FA bundle with
macros and portions lands at roughly 1 MB.**

For scale: Ash costs +6.5–7.5 MB (S-07, `charting-brief.md:33`) and the CLDR stack 2.49 MB gzipped
(S-27, `charting-brief.md:63`). **There is no size argument for going server-backed.** A live-API
food lookup would be a worse product on a device-first app and would buy nothing.

**Attribution.** Requested, not required. Suggested form: *"U.S. Department of Agriculture,
Agricultural Research Service. FoodData Central, 2019. fdc.nal.usda.gov."* This becomes one card
on D-05's Attribution screen — per this ticket's instruction, not a new screen.

**Coverage bias, stated honestly.** US. Generic ingredients travel well; the dataset has no Persian
or Middle Eastern composite dishes.

### 1.3 The Persian gap — no offline source exists, and that is the answer

**There is no open, bulk-downloadable Persian-language or Iranian food composition dataset.**

- FAO/INFOODS' Middle East directory
  (<https://www.fao.org/infoods/infoods/tables-and-databases/middle-east/en/>) lists exactly one
  Iran entry — *"Traditional and Traditional Fermented Foods in Iran: 1- Fars Province"*, NNFTRI,
  1998, 57 pp — with **no downloadable file**, unlike neighbouring entries that do carry PDFs.
- The *Iranian Food Composition Table* (NNFTRI) and the IFCP software are documented in the
  literature but are not openly distributed. Multiple Iranian nutrition papers fall back on USDA
  data for exactly this reason.
- Nothing surfaced in the Persian open-dataset collections.

**Consequence for Kati:** the Persian half of the food database is Kati's own work — Persian names
for USDA generic ingredients, plus a hand-curated table of Iranian composite dishes (kuku, ghormeh
sabzi, tahchin…) whose macros are computed from USDA ingredient rows. Names and recipes Kati writes
are Kati's copyright and carry no upstream obligation. This is a content task, not a licensing
one, and it is genuinely novel — worth saying out loud, because it is the sort of thing that makes
an English+Persian app worth existing.

### 1.4 Open Food Facts — the ODbL share-alike, precisely

The ticket is right to single this out, and the obligation is sharper than "attribution".

**Licences** (<https://world.openfoodfacts.org/terms-of-use>): the **database** is ODbL 1.0
(<https://opendatacommons.org/licenses/odbl/1-0/>); **individual contents** are DbCL 1.0; **product
images** are CC BY-SA 3.0.

**ODbL §4.4, verbatim:**

> **4.4a** *"Any Derivative Database that You Publicly Use must be only under the terms of: This
> License; A later version of this License similar in spirit to this License; or A compatible
> license."*
> **4.4b** *"Extraction or Re-utilisation of the whole or a Substantial part of the Contents into a
> new database is a Derivative Database and must comply with Section 4.4."*
> **4.4c** *"A Derivative Database is Publicly Used and so must comply with Section 4.4 if a
> Produced Work created from the Derivative Database is Publicly Used."*

And the carve-out that matters: **§4.5(b)** — *"Using this Database, a Derivative Database, or this
Database as part of a Collective Database to create a Produced Work does not create a Derivative
Database for purposes of Section 4.4."* A Produced Work still needs an attribution notice under
§4.3, but not share-alike.

Open Food Facts' own reading agrees: *"The two conditions are attribution and share-alike"* and
*"If you combine data from Open Food Facts with other databases, then the ODbL requires that the
resulting database must be released as open data as well"*
(<https://support.openfoodfacts.org/help/en-gb/12-api-data-reuse/94-are-there-conditions-to-use-the-api>).

**What this means for Kati concretely, in three steps:**

1. A filtered, restructured, on-device SQLite table built from OFF **is a Derivative Database**
   (§4.4b), and shipping it inside an APK is Public Use. That file must be published under ODbL.
2. Kati is open source and MIT-licensed, so publishing a data file under ODbL is survivable. The
   app's **code** licence is unaffected — ODbL attaches to the database, not to software that reads
   it.
3. **The real trap is merging.** If OFF rows and USDA rows land in the same table, the merged
   database is a Derivative Database of OFF in its entirety, and the CC0 USDA rows get pulled under
   ODbL with them. **Rule: if OFF is ever used, it lives in its own bundled file, unmodified,
   separately licensed, joined only at query time** — the "Collective Database" shape, which §4.4
   does not reach.

**Bulk sizes, measured today** (the "~0.9 GB" figure on OFF's own data page is stale): CSV.gz
1.19 GiB (~9 GB uncompressed), JSONL.gz 11.8 GiB, MongoDB dump 14.4 GiB, HuggingFace Parquet
7.24 GiB / 4.68M rows. **There is no "off-lite" and no per-country export** — `fr.` and `en.`
prefixes are *language variants of the same global export*, not country subsets
(`fr.openfoodfacts.org.products.csv.gz` measures 1,294,369,794 bytes against the `en.` file's
1,275,171,186). Any subset is Kati's to build.

**API use, if ever.** No key, but a custom User-Agent of the form `AppName/Version (ContactEmail)`
is mandatory (<https://openfoodfacts.github.io/openfoodfacts-server/api/>), and limits are 15
req/min/IP for product reads and 10 req/min/IP for search — the same shape of obligation MusicBrainz
imposes under S-50 (`charting-brief.md:101`).

**Recommendation on OFF: not in v1.** Its coverage is branded packaged goods skewed to Western
Europe, with patchy crowdsourced completeness — a poor fit for recipe *ingredients*, which is what
screens 45 and 48 need. Its natural use is the **barcode scan** path D-20 draws
(`D-20.md:85-88`), which is a later feature. Revisit it then, with the separate-file rule above.

### 1.5 Ruled out

**FatSecret.** Terms at <https://platform.fatsecret.com/terms> require deletion of content within
24 hours unless it appears on the storable-indefinitely list
(<https://platform.fatsecret.com/docs/guides/storable-data>) — and that list is **IDs only**
(`food_id`, `serving_id`, `recipe_id`, …). **Nutrient values are explicitly not storable.** Offline
bundling is flatly prohibited, and the API needs an OAuth consumer key *and secret* which an
open-source repo cannot ship.

**Nutritionix.** The API terms page (<https://www.nutritionix.com/apiterms>) currently serves a
placeholder — *"We're improving Nutritionix! Our full website is temporarily offline…"* — with no
terms text, and archived snapshots are 404s or JS shells. The company is now Syndigo LLC, whose
site ToU says only *"You are not allowed to copy, republish or download in any manner the contents
of this Website without the written permission of Syndigo."* The free tier is gone: *"due to
increased misuse of free trial accounts, we are no longer able to maintain a public free-access
tier"* (<https://developer.nutritionix.com/>). **A source whose licence cannot be read is not a
source.**

### 1.6 Optional secondaries, if European coverage is wanted later

- **UK CoFID** — Open Government Licence v3.0, © Crown copyright, attribution string *"Contains
  public sector information licensed under the Open Government Licence v3.0."* 4.63 MB xlsx, 2,889
  foods. <https://www.gov.uk/government/publications/composition-of-foods-integrated-dataset-cofid>
  *(Caveat: the OGL boilerplate hedges "except where otherwise stated"; a search of all 18,199
  shared strings in the workbook found no carve-out, so this is verified by absence rather than by
  an affirmative statement.)*
- **Danish FCDB (Frida)** — CC BY 4.0, version 6.1, 2026-06-09, 12.01 MB xlsx, DOI
  `10.11583/DTU.32312844`. Well-curated generic foods with EuroFIR/FoodEx2 coding.
- **Canadian Nutrient File** — Open Government Licence – Canada, ~5,993 foods. Exact archive size
  **UNKNOWN** (the portal bot-blocks scripted downloads). Health Canada also runs an
  unauthenticated REST endpoint at `https://food-nutrition.canada.ca/api/canadian-nutrient-file/`,
  whose terms of use are **UNKNOWN**.

All three are attribution-only, no share-alike, and could be merged with USDA without licence
contamination — unlike OFF.

### 1.7 Two engineering consequences

**a. Bundling mechanism, and an unverified step.** Kati's own `priv/` is copied to the device: the
host app's `priv/` is rsynced (`native_build.ex:2220-2240`, `copy_priv_repo_assets/2`) and the host
app gets a real OTP lib dir *"required for `code:priv_dir`"* (`native_build.ex:3400-3436`), per
`i18n-l10n.md:170-178`. Dependency `priv/` directories are **not** copied — which is why S-20 kills
Localize — but Kati's own is. So `priv/food.sqlite` reaches the device and `:code.priv_dir(:kati)`
resolves.

**UNKNOWN, and it must be settled before anyone designs around it:** that citation covers the
**dev deploy** path. Whether a `priv/` data file survives `mix mob.release --android` into
`assets/otp.zip` was **not verified**. This is a one-command check and it should be added to K-03
or K-10. See follow-up 8.

**b. Food search is a new consumer of K-40.** The measured subset above was built as
**SQLite + FTS5** precisely because name search over ~8,000 rows on a phone wants it. That is
exactly K-40's open question — *"can AshSqlite reach FTS5, or does Kati hand-roll it"*. If the
answer is "hand-roll", the food table is a second reason to, alongside screen 19.

---

## 2. The recipe, food and portion model

**Verdict: first-class Ash resources — `foods`, `recipes`, `recipe_ingredients`, `meal_plans`,
`meal_plan_slots`, `meal_logs`, `shopping_list_items` — not denormalised meal entries. The design
forces this; it is not a preference.**

### 2.1 Why denormalising is not available

Three drawn behaviours each independently require structure:

1. **The portion multiplier rescales five ingredient rows** (`design-index.md:142`, and §7 item 18
   at `design-index.md:427`: *"a stepper that live-rescales six macro figures, five ingredient rows
   and their kcal"*). A free-text ingredient list cannot be rescaled. Each row needs a numeric
   quantity and a unit.
2. **The shopping list sums quantities across meals and attributes each line back to them**
   (`design-index.md:145`: *"each line showing which meals asked for it and the summed quantity"*).
   Summing requires a canonical unit; attribution requires a join, not a string.
3. **Screen 46 ranks candidates by "Closest macros"** (`design-index.md:143`). Ranking requires
   per-recipe macro totals that are queryable.

### 2.2 The resources

Conventions follow K-21: `uuid_v7_primary_key`, `:utc_datetime_usec` timestamps, JSON-as-`:string`
rather than map types, no arrays (`K-21.md:69-80`; `mob-framework.md:1381` — *"no arrays or JSONB
indexes"*).

**`foods`** — one canonical per-100 g nutrition row.

| Column | Type | Notes |
|---|---|---|
| `id` | uuid v7 | pk |
| `source` | `:atom` | `:bundled \| :user \| :scanned`. Drives attribution (D-05) and export classification (K-37) |
| `source_ref` | `:string` | e.g. an FDC `fdcId`, or a GTIN barcode. Nullable |
| `source_licence` | `:atom` | which bundle the row came from. **Required for `:bundled`.** See §1 — a licence is a per-row fact, not an app-level one, the moment more than one dataset is involved |
| `name`, `name_fa` | `:string` | interface-side names. A user-created food's name is *content* and is never translated (`design-index.md:394-395`) |
| `brand` | `:string` | nullable |
| `kcal_100g`, `protein_100g`, `carbs_100g`, `fat_100g`, `fibre_100g`, `sugar_100g` | `:decimal` | the per-100 g basis. Store the superset even if screen 45 shows six figures; dropping a column later is free, adding one after user data exists is not |
| `density_g_per_ml` | `:decimal` | nullable. Required to resolve `ml` → `g` |
| `grams_per_piece` | `:decimal` | nullable. Required to resolve *"1 onion"* → `g` |
| `aisle` | `:atom` | Kati's own taxonomy — see §2.4 |
| `confidence` | `:atom` | `:measured \| :estimated \| :unknown`. Feeds D-20's "approximate total" treatment |

**`recipes`** — the meal definition behind screen 45.

`id`, `title` (content, never translated), `photo_path` (`:string`, nullable — the hero photo slot
that D-20 says must have a no-photo state), `method` (`:string`), `prep_minutes`, `cook_minutes`,
`oven_c` (all `:integer`, nullable — screen 45's *"time/oven/serves chips"*), `base_servings`
(`:decimal`, default `1`), `slot_hint` (`:atom`), `rating` (`:decimal`, nullable), `notes`.

Plus **cached totals per serving**: `kcal_serving`, `protein_serving`, `carbs_serving`,
`fat_serving`, `fibre_serving`, `sugar_serving` (`:decimal`) and `completeness` (`:decimal`, 0–1 —
the fraction of ingredient mass whose `food_id` resolves to a row with `confidence != :unknown`).

These are **cached columns, recomputed on every write to the recipe or its ingredients, not Ash
aggregates**. Settled item S-04 (`charting-brief.md:30`): AshSqlite has no resource aggregates and
no `distinct`. Screen 46 sorts candidates by macro distance; that sort must hit indexed columns.

**`recipe_ingredients`** — the five rows.

`id`, `recipe_id` (required), `position` (`:integer`, stable display order — SQLite has no arrays,
so order is a column), `food_id` (uuid, **nullable** — free-text ingredients are legal and are
D-20's third row state), `display_name` (`:string`, required — what the row renders; the user's
words), `quantity` (`:decimal`, nullable), `unit` (`:atom`:
`:g | :ml | :piece | :tsp | :tbsp | :cup | :pinch | :none`), `grams_resolved` (`:decimal`,
nullable), `note` (`:string`).

**Per-row nutrition is not stored.** It is `food.per_100 × grams_resolved / 100`, computed at
render. Storing it doubles the update surface for zero gain: a corrected `foods` row would leave
stale numbers on every recipe that used it.

`grams_resolved` **is** stored, because unit resolution is lossy and depends on the food
(`ml`→`g` needs `density_g_per_ml`; `piece`→`g` needs `grams_per_piece`). `nil` means unresolvable,
which is the signal that the recipe total is approximate.

**`meal_plans`** (screen 49) — `id`, `name` (*"Cutting v3"*), `active` (`:boolean`),
`target_kcal`, `target_protein_g`, `target_carbs_g`, `target_fat_g` (`:decimal`),
`activates_on` (`:date`, nullable — see §5.1 on *"takes effect next Monday"*), `archived_at`.

**`meal_plan_slots`** — the 5 × 7 matrix of screen 44. `id`, `plan_id`, `slot_index` (`:integer`
1–5), `slot_label` (`:string`), `day_of_week` (`:integer`, **ISO 1 = Monday**, stored Gregorian and
locale-free; screen 60's Saturday-first ordering is a render concern, per `ash-on-mob.md:894-896`
— *"Persian/Shamsi and RTL never touch Ash"*), `time_of_day` (`:time` — **floating**, see §5.2),
`recipe_id` (nullable — `nil` is screen 44's `Free` cell), `portion_multiplier` (`:decimal`,
default `1.0`). Unique `(plan_id, slot_index, day_of_week)`. Exactly 35 rows per plan.

**`meal_logs`** — what actually happened. The adherence source for screens 42, 43, 47.

`id`, `on_date` (`:date`), `slot_index`, `plan_id`, `plan_slot_id` (nullable), `recipe_id`
(nullable), `state` (`:atom` `:planned | :eaten | :skipped` — screen 43's three card states),
`eaten_at` (`:utc_datetime_usec`, nullable), `portion_multiplier` (`:decimal`), and **snapshot
columns** `kcal`, `protein_g`, `carbs_g`, `fat_g`, `fibre_g`, `sugar_g`, `completeness`
(`:decimal`).

**The snapshot is the single most important rule in this model.** If February's adherence chart is
computed by re-reading today's recipe, then editing a recipe in March silently rewrites February's
history. Screen 47 charts *"86% adherence"* over Week/Month/All (`design-index.md:144`) and screen
49 promises *"Keep the history"* on a plan switch (`design-index.md:146`) — both are lies unless the
eaten numbers are frozen at the moment of eating. This is the same discipline K-21 applies to
`raw_icalendar` (`K-21.md:151-156`) and K-30 applies to metadata TTL: *record what you saw, do not
recompute it later.*

Screen 45's *"eaten 14×"* is therefore `Ash.count!` over `meal_logs` filtered by `recipe_id` and
`state: :eaten` — not an aggregate, per S-04.

**`shopping_list_items`** (screen 48) — `id`, `week_start` (`:date`), `food_id` (nullable),
`display_name`, `quantity_total` (`:decimal`), `unit`, `aisle` (`:atom`), `in_basket`
(`:boolean`), `unit_price` (`:decimal`, nullable), `currency` (`:string`, nullable). Plus a join
`shopping_list_item_sources` (`item_id`, `plan_slot_id` or `meal_log_id`, `quantity`) so each line
can render *"which meals asked for it"*.

`unit_price` is **user-entered and optional**. See §2.5.

### 2.3 The portion multiplier: arithmetic on a struct, never a query

Screen 45's `− 1.0× +` stepper must not touch the database. The rules:

1. **Load once.** On mount, read the recipe and its ingredients into one
   `%Kati.Meals.Scaled{recipe:, rows:, multiplier:}` struct in socket assigns.
2. **Rescale in memory** with `Decimal.mult/2`. Every `+`/`−` tap is a pure function over that
   struct. Zero `Ash.read` per tap.
3. **`Decimal`, never float.** `ash-on-mob.md:900`: *"Money is `:decimal`, not float."* The same
   applies to grams and kcal — 0.1× steps accumulate float error visibly across a 5-row list.
4. **Round once, at display, from unrounded values.** The headline kcal and the six macro figures
   are computed from the unrounded sum and rounded at the end. The five ingredient rows are rounded
   independently. **The rows must not be summed to produce the headline** — round-then-sum and
   sum-then-round differ, and screen 45 shows both on one page where the mismatch is visible.
   Write this as a doc comment and a test.
5. **Clamp** to a sane band (proposal: `0.25×`–`4.0×`, step `0.1`) and store the multiplier as
   `:decimal` wherever it is persisted (`meal_plan_slots`, `meal_logs`).
6. **Budget the re-render, not the arithmetic.** Settled item S-39 (`charting-brief.md:80`): there
   is no BEAM-side diff — *"full tree → JSON → `set_root` on every event"*. Every stepper tap
   re-serialises screen 45 entirely. That is the real cost and it is unavoidable; the arithmetic is
   free by comparison. Screen 45 must also stay under the 256-tap-handle cap (S-38,
   `charting-brief.md:79`), which it comfortably does at ~5 ingredient rows.

### 2.4 The aisle taxonomy is Kati's, and it is an enum

The ticket is right that *"food databases do not agree on one"* — and the deeper reason is that
none of them is trying to. USDA FoodData Central's `foodCategory` and Open Food Facts' `categories`
taxonomy both classify foods by **what they are**, not by **where a shop puts them**. "Aisle" is a
retail-geography concept, and it varies by country, which matters for an app shipping English and
Persian.

Recommendation: a **fixed `:atom` enum of ~14 values**, owned by Kati, translated through the
string catalogue like any other interface noun (`design-index.md:389-393`):

`:produce`, `:bakery`, `:meat_fish`, `:dairy_eggs`, `:chilled`, `:frozen`, `:dry_goods`,
`:tins_jars`, `:condiments`, `:spices_baking`, `:drinks`, `:snacks`, `:household`, `:other`.

`:other` is D-20's required *"Uncategorised"* group (`D-20.md:110`). Not a user-editable table: a
mutable taxonomy makes screen 48's "By aisle" tab unstable between sessions and makes the shared-
plan import in screen 50 have to reconcile two users' taxonomies.

Mapping a bundled dataset's own category onto this enum is a one-time build-step lookup table
committed to the repo, not a runtime inference.

### 2.5 The price estimate on screen 48 has no data source

Screen 48 renders *"9 of 24 in the basket · £41.20 est."* (`design-index.md:145`). No free,
bulk-downloadable food database carries retail prices. Open Food Facts has a sibling project,
Open Prices (<https://prices.openfoodfacts.org/>), but its data licence, bulk-export availability
and coverage could not be established from the project's own pages — the landing page and API docs
returned only titles to automated fetch, and the GitHub README states the **code** licence
(AGPL-3.0) without stating the **data** licence
(<https://github.com/openfoodfacts/open-prices>). **UNKNOWN**, and in any case a crowdsourced price
feed for one country is not a basis for a headline figure.

Two honest options, and this is a design decision, not a research one:

- **Drop the estimate.** The screen still works: 24 items, 9 in basket.
- **Make it user-entered.** `foods.last_unit_price` + `currency`, filled in as the user shops,
  with the total marked approximate until every line has a price. This is consistent with §3's
  single-currency rule and with D-20's "approximate total" treatment.

Recommend the second, deferred: ship screen 48 without the estimate and add prices later.

---

## 3. Currency

**Verdict: single-currency storage and display, with the ISO 4217 code stored per row. Kati never
converts between currencies. Not in v1, and the recommendation is not in v2 either.**

### 3.1 The reasoning

**a. Conversion needs live rates, and live rates are a network dependency in a ledger.** Kati is
device-first with no server. A conversion feature means the numbers on screen 23 depend on a
successful HTTP call to a third party, which contradicts the whole product. It also means an
offline device shows either stale or absent numbers for its *own recorded spending*.

**b. Silently re-denominating recorded money is a data-integrity failure, not a formatting one.**
D-21 already states this (`D-21.md:41-43`): *"a subscription recorded in £ that silently becomes a
different number in ﷼ is a data-integrity failure, not a formatting one."*

**c. The design has already answered it.** The Persian screens show **pounds**: `۸٫۹۹ پوند`
(`design-index.md:378`) — Persian digits, the Persian decimal separator U+066B, and the currency
*name* in Persian. The fa pass changes numerals, separator and the currency's *name*; it does not
change the currency. That is precisely "single-currency storage with locale-aware formatting".

**d. Screen 54 files currency under *Content*, next to title language and units**
(`design-index.md:152`), and the content boundary is *"Your own words … are never translated"*
(`design-index.md:394-395`). An amount the user recorded is their datum.

**e. An FX rate source is an open-source shipping problem in its own right.** Any provider is
either key-bound — which an open-source repo cannot ship (the K-29 / S-51 argument that TMDB's key
is safe rests on TMDB rate-limiting per **IP** rather than per key, `charting-brief.md:102`, and
that property is **UNKNOWN** for every FX provider) — or carries its own licence and attribution
obligations for D-05. None of that cost buys a single drawn feature.

### 3.2 The storage rule

Store `amount` as `:decimal` and `currency` as a 3-character ISO 4217 `:string` **on every money
row**, never as a single global setting.

Three characters per row is nothing, and it makes the "user changed their currency setting" case
non-destructive:

- Existing rows keep the code they were recorded in and keep rendering in it.
- The setting changes only the **default for new rows**.
- A total across rows of differing codes is **refused, not guessed**: screen 23's *"£46.47 a
  month"* headline renders a mixed-currency state instead of a wrong number. This is the same
  refusal discipline K-37 applies to a newer `schema_version` (`K-37.md:225-226`).

`:decimal` and not float, per `ash-on-mob.md:900` — *"Money is `:decimal`, not float. `decimal` is
already a required Ash dep; ecto_sqlite3 stores it as text/numeric. Verify round-tripping on device
in the day-one spike."* That verification is already an acceptance item of the K-03 spike
(`ash-on-mob.md:1018` — *"one `Ash.create!/1` + `Ash.read!/1` round-trips a `:decimal` and a
`:utc_datetime_usec`"*), so this decision adds no new device risk.

Minor units vary (GBP 2, IRR 0, JPY 0). Store full precision; round only at display, using the
currency's own digit count rather than a hardcoded 2.

### 3.3 Do `ex_cldr_currencies` and `Decimal` work on device?

**Yes to both, and the currency stack is already paid for — it costs one word in K-13's
`providers:` list.**

**`ex_cldr_currencies` is already in Kati's dependency tree and already in its size budget.** It
arrives transitively via `ex_cldr_numbers`, which K-13 already requires
(`K-13.md:148-152`), and it is already a line in the measured i18n cost table at **0.80 MB
unstripped** (`i18n-l10n.md:872`), inside the 2.49 MB gzipped total that S-27 already accepts
(`charting-brief.md:63`). Formatting money is `Cldr.Number.to_string(amount, currency: :GBP,
locale: "fa")`, and `Cldr.Number` is already in K-13's provider list (`K-13.md:161`). Adding
`Cldr.Currency` to that list buys the currency metadata functions. **No new dependency, no new
megabytes.**

**It satisfies the K-04 constraint by not needing runtime configuration at all.** This is the
important part. S-03 (`charting-brief.md:29`) says every runtime config must be
`Application.put_env/3` in `on_start/0` because `config/*.exs` never reaches the device. ex_cldr
sidesteps that entirely because its model is **compile-time**: *"There is essentially **no
boot-time risk with ex_cldr**, and that is a direct consequence of the compile-time model: all
data is in the `LitT` chunk of already-loaded modules. No file I/O, no ETS build, no
`:persistent_term` population, no supervisor"* (`i18n-l10n.md:933-936`).

The one runtime key that does exist — `:ex_cldr`, `:default_backend`, read by
`Cldr.Config.default_backend/0` at `ex_cldr/lib/cldr/config/config.ex:382-385` and listed in K-04's
silent-failure table (`K-04.md`) — **is never reached if K-13's rule is followed**: never call
`Cldr.put_locale/1`, always pass `locale:` explicitly at the call site (`K-13.md:135-141`). Money
formatting inherits that rule unchanged.

**`Decimal` is pure Elixir and is already a required Ash dependency.** Version 3.1.1 (2026-05-27,
Apache-2.0) has **zero dependencies** and, verified against the repository tree, **no `c_src`, no
`Makefile`, no `.c` file and no NIF** — arbitrary-precision arithmetic in plain Elixir
(<https://hex.pm/packages/decimal>, <https://github.com/ericmj/decimal>). It appears in the
compiled `ash.app` applications list — `[kernel, stdlib, elixir, mnesia, spark, ecto, ets, decimal,
jason, telemetry, reactor, …]` (`ash-on-mob.md:803`) — so it ships whether or not Kati uses it, and
`ash-on-mob.md:900` already prescribes it for money: *"Money is `:decimal`, not float. `decimal` is
already a required Ash dep; ecto_sqlite3 stores it as text/numeric."* The device round-trip is
already a K-03 acceptance item (`ash-on-mob.md:1018`), so no new spike is needed.

**Two caveats worth carrying forward.**

1. **`digital_token` rides along and cannot be dropped.** It arrives via `ex_cldr_currencies` and
   is *"a registry of crypto-asset codes… It is a hard dependency, so you cannot drop it, but it is
   the single largest avoidable item if you ever need the space"* — 3.07 MB unstripped, 0.38 MB
   stripped (`i18n-l10n.md:926-929`). Kati's money screens deal only in real currencies. This is a
   known, accepted cost, not a surprise.
2. **`ex_money` must not be added, and there is now a second, harder reason.** Its value is a
   `Money` struct plus an exchange-rate service, and the rate service is precisely the network
   dependency §3.1 rejects. But as of **6.0.0 (2026-05-08) `ex_money` deleted the CLDR backend
   system entirely**: *"The `ex_cldr`, `ex_cldr_numbers`, and `ex_cldr_units` dependencies have
   been replaced by `localize`"* and *"The `Money.Backend` module has been deleted"*
   (<https://github.com/ex-money/money/blob/master/CHANGELOG.md>). Current 6.2.1 (2026-08-04,
   Apache-2.0) hard-requires `localize ~> 1.0`
   (<https://hex.pm/packages/ex_money/dependencies>) — **and S-20 already disqualified Localize for
   Mob**: *"All three of Localize's runtime-data assumptions are false on Mob"* — `Application.app_dir`
   raises on Mob's flat beam directory, its supervisor never boots, and `config :localize` is a
   no-op under S-03 (`charting-brief.md:56`). So current `ex_money` is doubly out, and pinning 5.x
   to avoid that means pinning an abandoned branch. **`:decimal` plus a 3-character code column is
   the whole model.**

*(Two details for whoever implements this. `ex_cldr_currencies` 2.17.2 is Apache-2.0, depends only
on `ex_cldr ~> 2.38` plus optional `jason`, and **ships zero `priv`** — 172 KB total, all its data
coming from `ex_cldr`'s own priv. It **does** require a `use Cldr` backend generated at compile
time, which is not a problem because that is exactly what K-13 builds. The one genuine compile-time
trap — `Application.compile_env(:ex_cldr, :json_library)` at
`ex_cldr/lib/cldr/config/config.ex:147` — does not bite Kati: on OTP 27+/Elixir 1.18+ the native
JSON module is used and the key is not needed, and `i18n-l10n.md` reproduced its findings on OTP 28
/ Elixir 1.19.5.)*

**Persian formatting falls out for free, with the two gotchas K-13 already owns.** `fa`'s default
number system is `arabext`, so Persian digits are automatic (S-24, `charting-brief.md:60`); the
CLDR group separator is U+066C, not the design mock's ASCII comma (`K-13.md:116-118`); and
`precompile_transliterations: [{:latn, :arabext}]` is required or every call logs a slow-path
warning (`K-13.md:126`). All three apply to money exactly as they apply to kcal counts. The design's
`۸٫۹۹ پوند` (`design-index.md:378`) is a `format: :long` currency render in `fa` — the currency
*name* localises, the currency itself does not.

### 3.4 Cost per watched hour

### 3.4 Cost per watched hour

Screen 23's `£/h` (`design-index.md:113`) is **derived and never stored**:
`Decimal.div(period_cost, watched_hours)`.

Two rules the design does not state and the implementation must:

- **Zero hours renders `—`, not `∞` and not a crash.** A newly added service, and the drawn
  "paused service" row, both have this case.
- **Recompute, never cache.** Watched hours change every time an episode is ticked; a cached
  `£/h` is wrong within a day. It is a cheap division over two numbers Kati already holds.

This is the app's strongest single idea per the competitive read
(`competitors-media.md:441-445`) and it needs **no** currency conversion to work: it joins one
currency's spend to one user's hours.

---

## 4. PDF

**Verdict: a concrete native path exists and it is not the obvious one — but it should not be
built for v1. Retire "Print the week (PDF, fridge-sized)" from screen 50 and make it K-43's first
worked example, with Path C below recorded as the costed route if it is ever revived.**

Mob has no PDF surface at all: PDF and printing are **not mentioned anywhere** in Mob's own
surface matrix (<https://mob.hexdocs.pm/mobile_surface_matrix.html>), and `Mob.Share` exposes
exactly one function, `text/2` (<https://mob.hexdocs.pm/Mob.Share.html>;
`mob/lib/mob/share.ex:17-24` per `K-37.md:50`). So every path below starts with native work.

### 4.1 The four candidate paths

**Path A — a pure-Elixir PDF library producing bytes.** *(see §4.2 for the library survey)*
Ruled out on script support before anything else: Kati ships English **and Persian**
(`design-index.md:167`), and a "print the week" whose Persian renders as disconnected, unreversed
letterforms is worse than no feature. Arabic-script shaping is not text drawing; it is
contextual-form substitution plus bidi reordering, and no pure-Elixir PDF writer implements it.

**Path B — Android `PdfDocument` via a Kotlin plugin.** `android.graphics.pdf.PdfDocument` gives
you a `Canvas` per page and nothing above it. Kati would reimplement the entire week-grid layout —
type, metrics, line breaking, RTL — a second time, in Kotlin, inside a fenced patch with permanent
merge cost (K-05). It duplicates layout in a second language for one row on one screen.

**Path C — WebView driven through the print framework. This is the real path.** Verified against
Android's own guide (<https://developer.android.com/training/printing/html-docs>) and the API
reference:

- `WebView` printing landed in **Android 4.4 (API 19)**; the `createPrintDocumentAdapter(String)`
  overload Kati would use is **API 21** (the no-arg variant is API 19 and deprecated at 21). Both
  are far below Kati's targetSdk 36 floor (K-02).
- The dialog flow is `webView.createPrintDocumentAdapter(jobName)` → `printManager.print(jobName,
  adapter, PrintAttributes.Builder().build())`.

It comes in **two variants**, and the difference matters:

**C1 — with the system dialog.** `PrintManager.print(...)` shows Android's print sheet, which
carries a built-in *Save as PDF* destination. That destination is **pure AOSP, not Play Services**:
it is a fake printer inside PrintSpooler (`PrintActivity.java`,
`DEST_ADAPTER_ITEM_ID_SAVE_AS_PDF`, `createFakePdfPrinter()`) that routes to a SAF
`ACTION_CREATE_DOCUMENT`. **So C1 needs no file-export patch at all — one bridge entry point, not
two.** Its risk: it requires PrintSpooler to be present, the OEM not to have stripped it, and a
DocumentsUI handler to exist. Whether specific GMS-less, Android Go or Chinese-OEM ROMs omit
PrintSpooler is **UNKNOWN** — no authoritative CDD language was found. Note also that
`PrintHelper.systemSupportsPrint()` is hardcoded `return true`, so it must **not** be used as the
capability gate.

**C2 — headless, no dialog.** `PrintDocumentAdapter.onLayout/onWrite` are public API, and `onWrite`
is documented as writing *"in the form of a PDF file to the given file descriptor"*. Calling them
directly against your own `ParcelFileDescriptor` produces the PDF bytes with no UI, no
`FEATURE_PRINTING` dependency and no PrintSpooler uncertainty. Two costs: the helper class **must
be declared `package android.print;`** because the two result callbacks have `@hide` constructors
stripped from the public SDK — a real fragility to pin with a test — and the resulting file then
needs K-37's `ACTION_SEND` / `ACTION_CREATE_DOCUMENT` patch to reach the user. So **C2 is two
native pieces, C1 is one.**

Why this family fits Kati:

1. **Kati already has the WebView.** `<WebView>` is ✅ on both platforms in the surface matrix
   (*"Inline web view, JS bridge, navigation control"*), and `Mob.WebView` ships a bidirectional JS
   bridge (`mob-framework.md:354`, `:577-583`). An off-screen, unattached `WebView` is the
   *recommended* configuration for printing, not a workaround.
2. **The layout stays in Elixir.** The week grid is generated as HTML — pure, host-testable, no
   `Mob.*`, exactly the S-10 discipline (`charting-brief.md:36`). No layout code moves to Kotlin.
3. **Persian is handled by a real shaping engine.** Android's WebView is Blink, which shapes with
   HarfBuzz and reorders with ICU bidi. This is the strongest argument over Paths A and B — but see
   the caveat below; it is *probable*, not *proven*.

**Four caveats that must be tested before anyone commits to this path:**

- **Persian through the *PDF conversion* is UNKNOWN.** On-screen correctness is certain; that the
  same shaping and bidi survive the print-to-PDF pipeline identically is undocumented. There is a
  documented (if old, 2013–2015, pre-Lollipop) failure mode where Android WebView *"can render
  custom english fonts without any issue… this is not the case in custom Arabic font — it ignores
  any defined custom font"* (<https://github.com/delight-im/Android-AdvancedWebView/issues/29>).
  Whether that still reproduces is **UNKNOWN**. Mitigation that removes the whole class of failure:
  embed Vazirmatn as a `data:font/ttf;base64,…` URI inside the CSS — no file access, no origin
  rules — plus explicit `direction: rtl; unicode-bidi: isolate;`.
- **CSS print attributes are officially unsupported.** The guide states: *"An HTML document
  containing CSS print attributes, such as landscape properties, is not supported."* Chromium
  honours some `@page` / `break-*` in practice, but exact conformance is **UNKNOWN** and varies
  with WebView version, which updates independently of the OS. For a "one page, fridge-sized" grid
  this is exactly the property being relied on.
- **`onPageFinished` does not wait for async JS or webfont loading.** Trigger from it *and* add a
  readiness signal (`document.fonts.ready` plus a `@JavascriptInterface` ping), or the output may
  be *"incomplete or blank, or may fail completely"*.
- Hold a hard reference to the `WebView` until the adapter is handed over, and run one job at a
  time.

**Path D — retire the row.**

### 4.2 Elixir PDF library survey

Rendering Persian in a PDF needs three things, and libraries fail at different ones:
**(i)** TTF/OTF embedding (the base-14 Type1 PDF fonts have no Arabic glyphs at all);
**(ii)** contextual shaping — Arabic letters take initial / medial / final / isolated forms;
**(iii)** **bidi reordering (UAX #9)** — because every meal row mixes Persian text with Latin or
Persian numerals, times and a currency symbol.

| Package | Latest / last release | Verdict |
|---|---|---|
| `pdf` (andrewtimberlake) | 0.8.1 · 2026-08-06 · MIT · zero runtime deps | **Structurally incapable of Persian.** `lib/pdf/external_font.ex` parses an `.afm` metrics file and a `.pfb` — **Adobe Type 1 only, not TrueType**. It emits `FontFile` with `Length1/2/3` and has **no `FontFile2`, no `CIDFont`, no `Identity-H`**. `font_dictionary/3` hardcodes `WinAnsiEncoding`, widths are keyed per single byte, and `lib/pdf/text.ex:113` pipes all text through `Pdf.Encoding.WinAnsi.encode/1` — **non-WinAnsi characters are silently replaced with a substitute glyph.** Persian becomes replacement characters. Best-in-class for Latin invoices; useless here. |
| `mudbrick` | 0.9.1 · 2025-09-16 · MIT | **The closest, and still not enough.** It depends on `opentype`, which genuinely implements the Unicode joining algorithm (`lib/opentype/layout.ex` — `arabic_shaping/3` with `isol`/`init`/`medi`/`fina`, GSUB/GPOS, RTL run reversal). But `opentype`'s own source says it: *"This version does not apply width or height constraints, line breaking, or **a bidirectional algorithm**. Such layout logic is assumed to be handled by the caller"* (`lib/opentype.ex:117`). Script is detected as `hd(scripts)` and the whole run reversed wholesale — a grid mixing Persian labels with Latin digits and times **lays out wrong**. Also: font subsetting is on mudbrick's to-do list, so the **full** TTF embeds in every file; 13 GitHub stars, one maintainer, self-described *"Early-stages"*. |
| `tincture` | 0.2.0 · 2026-07-31 · MIT · zero required deps | Impressive on paper — Knuth-Plass line breaking, TTF/CFF subsetting, PDF/A+UA — but its "shaping" is substring→ligature replacement (`:off \| :latin_ligatures \| :gsub_ligatures`) and `bidi: :basic` is a codepoint-range check. **No Arabic joining.** 282 downloads; unproven. |
| `rendro` | 1.0.0 · 2026-06-05 | Has real bidi *and* HarfBuzz shaping — but `harfbuzz_ex` is a **required, non-optional Rustler NIF**, which Mob's static-linking constraint rules out (`mob-framework.md:491-493` via `K-20.md:48-53`). Its own error string concedes it *"does not currently support complex text shaping or RTL boundaries."* |
| `gutenex` | 0.2.0 · **2016-05-30** · MIT | Abandoned for ten years, and `lib/gutenex/pdf/font.ex` is a hardcoded map of the 14 standard Type1 fonts. No TTF, no Unicode, no CID. |
| `prawn_ex` | 0.2.0 | Zero deps, but no CID / subsetting / FontFile code at all. Base-14 only. |
| `chromic_pdf`, `pdf_generator`, `puppeteer_pdf`, wkhtmltopdf, WeasyPrint, `ex_pdf_poppler` | — | **All spawn an OS process** via `System.cmd/3` or `Port.open({:spawn, …})` and require an external binary — Chrome/Chromium, wkhtmltopdf (repo **archived 2023-01-02**), Node, or CPython + Pango. Structurally impossible on an embedded BEAM with no shell. |
| Rustler-NIF group (`imprintor`, `ex_pdfium`, `folio`, `merge_pdf`, `pdf_oxide`) | — | No OS process, but all need `rustler_precompiled` artifacts. Whether any ship `aarch64-linux-android` or static-linkable iOS targets is **UNKNOWN**; iOS needs static NIF linking regardless. Assume custom cross-compilation. |

**Conclusion, and one correction to the intuitive version of it.** The blocker is **not** missing
shaping — `opentype` already does Arabic joining correctly. The blocker is that **no pure-Elixir
UAX #9 bidi implementation exists on Hex**, and no library combines shaping + bidi + subsetting.
What does exist is the *input data*: `unicode_data` 0.8.0 exposes `bidi_class/1` and
`joining_type/1`, documented as *"used to initialize the Unicode bidirectional algorithm"*.

So writing UAX #9 on top of that and adding subsetting to `mudbrick` is a **bounded** project — a
well-specified algorithm, a few hundred lines — rather than an impossible one. It is simply not a
sane price for one row on one screen. **Rule out Path A for v1, and note it as the fallback of last
resort if native ever proves impossible.**

This is also why Path C beats Path A on more than convenience: Blink already contains both the
shaping engine and the bidi implementation.

### 4.3 Why the recommendation is still "retire it", and why the image fallback is not the escape

D-20 proposes replacing the PDF with a saved PNG and calls it *"cheaper"* (`D-20.md:97-100`).
**It is not.** Two facts:

- **`Mob.Canvas` cannot be snapshotted.** Its public surface is eight *draw-op constructors* —
  `line/5`, `circle/4`, `ellipse/5`, `arc/6`, `rect/5`, `path/2`, `text/4`, `image/6` — described
  as *"Drawing-op constructors for `Mob.UI.canvas/1`"*. There is **no export, snapshot or
  to-bytes function** (<https://mob.hexdocs.pm/Mob.Canvas.html>). Producing a PNG of a rendered
  view needs a native bitmap capture, i.e. a Kotlin patch.
- **`Mob.Share` is text-only** and *"Share sheet (image / file)"* is ❌ in the surface matrix, so
  handing the image to the user needs K-37's `ACTION_CREATE_DOCUMENT` or `ACTION_SEND` patch on
  top.

So the image fallback costs **two** native pieces (bitmap capture + file export) where Path C costs
**one** (a print call). That is worth telling D-20, because its recommendation is built on the
opposite assumption.

Given that, the ranking is: if the fridge sheet is ever built, build **Path C1**. But it is one row
on one screen of a section that does not yet have a create-a-recipe surface; it adds a fourth fenced
`MobBridge.kt` region to a shell with no upstream upgrade path (S-40, `charting-brief.md:81`; K-05's
ledger); and it carries two UNKNOWNs that need device time to close — Persian survival through the
PDF conversion, and `@page` behaviour for the grid. **Retire it for v1**, record Path C in K-05's
patch table as a costed future row with those two tests attached, and let K-43's ritual do its first
real job here — which is exactly what K-43 asks for (`K-43.md:63`).

### 4.4 iOS

iOS is materially *better* than Android here — headless PDF generation is first-class, and Core
Text handles Arabic joining, bidi and font cascading natively:

| API | Min iOS | Silent (no UI) PDF? |
|---|---|---|
| `UIGraphicsPDFRenderer` | 10.0 | yes |
| `WKWebView.viewPrintFormatter()` + `UIPrintPageRenderer` | 4.2 | yes — the Path C equivalent |
| `UIMarkupTextPrintFormatter` + `UIPrintPageRenderer` | 4.2 | yes, but drops images unless the HTML was previously loaded in a web view (<https://github.com/nyg/HTMLWithImagesToPDF>) |
| `WKWebView.createPDF` | 14.0 | yes, but **single page — does not paginate** |
| `UIPrintInteractionController` | 4.2 | **no — cannot produce a PDF at all** |

**It still is not v1.** `deps/mob/ios/mob_nif.m` is **not** app-owned (`K-37.md:84-86`), so an iOS
PDF path is a fork-and-patch-series or an upstream pull request rather than a vendored, fenced
edit — and K-39 has not yet established that an Erlang app passes App Review at all. Android is the
declared priority. **Do not plan iOS PDF for v1**, but record that if the feature ever returns, iOS
is the easier half.

---

## 5. Reuse check

### 5.1 K-20 `Kati.Recurrence` (#47) — **do not use it for the meal week**

This is the sharpest reuse answer in the ticket, and it is a *no*.

Screen 44's repeating week is *"Repeats every week, indefinitely"*, *"Started Week 6 · 6 Jul
2026"*, *"Edit this week only"* (`design-index.md:141`). As an RRULE that is
`FREQ=WEEKLY;INTERVAL=1` — the most degenerate rule the RFC can express. Routing it through K-20
would buy nothing and cost the whole `RECURRENCE-ID` override apparatus
(`K-21.md:179-196`) for a case that is naturally a 35-row matrix plus a materialised log:

- **Expansion is a `Date.range` walk.** `day_of_week` lookup against `meal_plan_slots`. Four lines,
  no timezone arithmetic, no DST, no `COUNT`/`UNTIL`, no expand/limit table.
- **"Edit this week only" is a row in `meal_logs`**, not an override `VEVENT`. The log already
  exists for adherence; a one-off swap writes a `meal_log` whose `recipe_id` differs from its
  `plan_slot_id`'s. Screen 46's *"Swap just today"* vs *"Every week"* maps exactly onto
  "write a `meal_log`" vs "update the `meal_plan_slot`" — two different tables, no ambiguity.
- **"Switch takes effect next Monday"** (`design-index.md:146`) is a single future date
  (`meal_plans.activates_on`), not a recurrence. It is resolved by a comparison at read time, not
  by an expander.

**Where K-20 *is* genuinely needed in this cluster: screen 23's renewal dates.** A subscription
billing cycle is a real RRULE with real edge cases, and K-20 already specifies the behaviour that
matters here — `FREQ=MONTHLY;BYMONTHDAY=31` **skips** February, April, June, September and November
rather than clamping (`K-20.md:125-128`, quoting `rfc5545.txt:2382-2386`). That is correct for the
RFC and **wrong for a subscription that actually bills on the last day of the month**. So the
subscription editor must author `BYMONTHDAY=-1` for end-of-month cycles — which K-20 supports
(`K-20.md:215`) and which K-21's recurrence editor must expose. Worth stating in both tickets.

### 5.2 K-21 the event model (#48) — **reuse wholesale; it is already provisioned**

K-21 anticipated this cluster in three places, and none of it needs changing:

- `events.kind` already includes `:meal` — `:event | :reminder | :habit | :meal | :air_date |
  :money | :note` (`K-21.md:143`), explicitly citing screen 52.
- `events.tzid == nil` (floating time) is already documented as *"the correct model for habits and
  **meal slots**"* (`K-21.md:136`). A 07:30 breakfast is 07:30 wherever you wake up. Meal slots must
  therefore store `time_of_day` floating and must **not** carry a `tzid`.
- K-23 already carries screen 52 as a named acceptance fixture: *"The screen 52 fixture collapses
  five meals into one row"* (`K-23.md:277`), keyed on `kind` (`K-23.md:92-96`).

So **screen 52 is free**. Meals become `events` rows with `kind: :meal`, `origin: :kati` on a local
calendar, and flow through `Kati.Calendar.events_in_range/3` and `Kati.Calendar.Layout` with no new
code.

**One rule must be stated or the two stores will drift: the calendar row is a *projection* of the
meal plan, not the source of truth.** `meal_plan_slots` and `meal_logs` own the data; a
materialiser writes and refreshes `kind: :meal` event rows. Nothing may edit a meal through the
calendar and expect the plan to follow.

The same applies to screen 23: subscription renewals become `kind: :money` events — which screen
02's Money filter chip (`design-index.md:87`) and screen 09's *"merged money events"*
(`design-index.md:94`) already assume — projected from a separate `subscriptions` resource that
holds cost, currency and cycle.

### 5.3 K-37 export and QR (#64) — **reuse export; the QR as drawn does not work**

**Export / import.** Screen 50's *"Import file / Export JSON"* rows **are** K-37, not a second
mechanism. The meal resources must appear in K-37's per-resource `:backup` / `:cache` / `:secret`
table (`K-37.md:212-213`):

| Resource | Class | Why |
|---|---|---|
| `recipes`, `recipe_ingredients`, `meal_plans`, `meal_plan_slots`, `meal_logs`, `shopping_list_items` | `:backup` | user-generated; irreplaceable |
| `foods` where `source == :user` | `:backup` | user-generated |
| `foods` where `source == :bundled` | `:cache` | rebuildable from the shipped dataset — **and possibly licence-encumbered, see §1** |

That last row is not a size optimisation. If a bundled dataset carries a share-alike obligation on
derived databases, then a backup file containing thousands of its rows is itself a derived
database, and it leaves the device. Classifying bundled rows as `:cache` and exporting only the
*reference* (`source`, `source_ref`) keeps the export clean.

**QR.** Screen 50 draws `kati://plan/cutting-v3 · 35 meals` with *"What travels with it (meals,
targets, reminder times)"* (`design-index.md:147`). K-37 already reads this as sharing *"a plan
reference, not the data — that is consistent, keep it that way"* (`K-37.md:286-288`).

**With no server, a reference resolves to nothing on the receiving device.** The QR ceiling is
~2,953 bytes (version 40, byte mode, EC level L — `opensource-release.md:1079-1081`), and 35 meals
with their ingredients is an order of magnitude past it. Two coherent resolutions:

- **(a)** the QR carries a compact skeleton — 35 `slot → recipe name` pairs plus targets and
  reminder times — and the recipient must already have the recipes. That contradicts *"35 meals"*
  travelling.
- **(b)** the QR is demoted to a **pairing token** and the plan travels as a `.katiplan` file
  through K-37's `ACTION_SEND` share path. This matches `opensource-release.md:1097` —
  *"ship (1) [file hand-off] in v1, (2) [QR] as the pairing mechanism"*.

**Recommend (b).** It needs a design decision, so it is a follow-up ticket.

Two mechanical notes on the QR:

- **`mob_scanner` scans; it does not generate.** Rendering the QR *image* on screen 50 needs a
  generator. `eqrcode` 0.2.1 (MIT, released 2025-02-21, <https://hex.pm/packages/eqrcode>) is pure
  Elixir with *"no other dependencies"* and emits SVG or PNG via `EQRCode.svg/2` / `EQRCode.png/2`
  (<https://eqrcode.hexdocs.pm/EQRCode.html>). Write the PNG into `Mob.data_dir/0` and render it
  with `<Image>`, which the Mob surface matrix lists as ✅ *"Local + remote"*
  (<https://mob.hexdocs.pm/mobile_surface_matrix.html>; `mob-framework.md:369` — *"accepts URL or
  local path"*). No native work.
- The **scanning** half of screen 50 (*"Scan a plan"*) needs `mob_scanner`
  (`mob-framework.md:687`, `:930`), a tier-1 plugin — so it carries a camera permission and is not
  hot-pushable (`mob-plugins-navigation.md:61-64`).

### 5.4 K-32 notifications (#59) — reuse the budget; **screen 51's inline actions do not exist**

K-32 already allocates this domain: **Meals — 60 Android alarms, 6 iOS pending**
(`K-32.md:117`). Screen 51 needs five meal reminders plus a 20:00 next-day preview = 6/day, so 60
alarms is ten days of Android runway and the 6 iOS slots are a single day. K-32's
reconcile-on-every-foreground rule (`K-32.md:128-130`) is what makes that survivable. No new
budget work.

**But the drawn promise cannot be kept.** Screen 51 renders *"a 19:15 'Dinner in 15 minutes' with
inline **Eaten / Skip / Snooze** actions"* and says *"Tick it straight from the notification — no
need to open the app"* (`design-index.md:148`, `:409`). Notification action buttons do not exist in
Mob on either platform:

- `mob-framework.md:1208-1212`: *"### Actions — **None.** No `UNNotificationAction` /
  `UNNotificationCategory` registration anywhere in the iOS NIF; no `addAction` in the Android
  receiver."*
- Confirmed directly against Mob's own surface matrix
  (<https://mob.hexdocs.pm/mobile_surface_matrix.html>): *"Notification actions (buttons)"* — ❌ on
  both platforms, marked *"Plugin / core candidate"*.

> **Correction to existing research.** `calendar-and-sync.md:125` states the opposite —
> *"`mob_notify` supports notification actions (`mob-framework.md:1208` 'Actions'), so this is
> reachable"* — and concludes snooze is available. It cites the **heading** at
> `mob-framework.md:1208` and misses the **verdict** two lines below at `:1210`, which is
> "**None.**". That claim is load-bearing for K-32's snooze design and for screen 51, and it should
> be corrected in `calendar-and-sync.md` and in K-32.

So screen 51's action buttons are a **fourth fenced `MobBridge.kt` patch** (after K-37's two and
K-12's RTL work) or they are cut. Nobody has costed them. See §7.

### 5.5 K-23 layout (#50) — already fixtured, nothing to do

Screen 52's *"Collapse meals → 5 meals · 1,960 kcal · 1 eaten · next at 10:30"* is K-23's phase-0
collapse-by-kind pre-pass and is already an acceptance criterion (`K-23.md:92-96`, `:222-223`,
`:277`). Screen 43's time gutter is the same shared component listed for screens 02, 30, 43, 52, 56
and 59 (`K-23.md:211`).

### 5.6 K-40 FTS5 (#67) — the food search depends on it

If Kati bundles a food table, "search for a food" is a text query over thousands of rows on a
phone. That is exactly K-40's open question — *"can AshSqlite reach FTS5, or does Kati hand-roll
it"*. The meal creator D-20 asks for is a **new consumer of K-40**, alongside screen 19. Worth
noting on both.

### 5.7 D-05 attribution (#8) — any bundled dataset lands here

Per this ticket's own instruction: fold attribution into D-05 rather than creating a screen. See
§1 for the exact obligation.

---

## 6. The eleven screens

Marks are **buildable** (the drawn screen has a data model, a rendering path and an owning ticket),
**needs-design-work** (something drawn has no source, no model or no platform path and a person must
decide), **not-in-v1**.

| # | Screen | Verdict | Reason |
|---|---|---|---|
| 42 | Health — hub | **buildable** | The eaten-today ring and macro split bar are pure reads over `meal_logs` (§2.2). The ring is an arc — `Mob.Canvas.arc/6` exists (<https://mob.hexdocs.pm/Mob.Canvas.html>). The four "Not set up" tiles are already D-19's, and the tile treatment is K-43's retirement band. Nothing here is unowned. |
| 43 | Meals — today | **buildable** | Reuses screen 02's time-gutter component and K-23's layout wholesale (`K-23.md:211`). The three card states map to `meal_logs.state`. Depends on §2's model landing, not on the nutrition source — a recipe with user-typed macros renders identically. |
| 44 | Meals — repeating week | **buildable** | A 35-row matrix (§2.2), **not** a recurrence problem (§5.1). Rendering is `Row`/`Column` with per-child `weight`, which S-47 confirms is native (`charting-brief.md:93`). The RTL variant (screen 60) is K-12 and K-24's already-ticketed work. |
| 45 | Meal detail | **buildable** | The portion multiplier is arithmetic on a struct (§2.3) and §7 item 18 already grades it *"hard but usually possible"* (`design-index.md:427`). **Dependency, not a blocker:** the screen is a detail view and no screen in the 62 creates a recipe — D-20 already owns that gap (`D-20.md:61-69`) and correctly requires the editor to reuse this exact layout. |
| 46 | Swap a meal | **needs-design-work** | Two of the three ranking tabs are buildable: "Closest macros" sorts on the cached per-serving columns (§2.2), "Faster" on `prep_minutes + cook_minutes`. **"In my fridge" is not** — it requires a pantry/inventory model, and nothing in the 62 screens creates, edits or depletes a pantry. Either draw that surface or cut the tab. "Effect on today" and the two swap scopes are fine (§5.1). |
| 47 | Nutrition & adherence | **buildable** | Bars, target line and the 12-week pixel field are §7 item 13 *"hard but usually possible with custom painting"* (`design-index.md:422`); S-47 recommends `Canvas` for pixel fields specifically (`charting-brief.md:93`). Adherence is arithmetic over the frozen `meal_logs` snapshots (§2.2). **Scope the insight row:** *"Friday is your weak day — 4 of 5 skips happen after 16:00"* must be a small fixed library of rules over the log, not an open-ended insight engine. |
| 48 | Shopping list | **needs-design-work** | Aisle and meal grouping and the summed quantities are buildable on §2.2 and §2.4. **The "£41.20 est." headline has no data source** (§2.5): no free bulk food database carries prices, and Open Prices' data licence is UNKNOWN. Somebody must decide: drop the estimate, or draw a user-entered price surface. |
| 49 | Meal plan profiles | **needs-design-work** | Targets, activate, adherence and *"takes effect next Monday"* are all buildable (§5.1 — a single `activates_on` date). **"Auto-switch → Travel week when a trip is on the calendar" is not**: "a trip" is not a modelled concept anywhere in the 62 screens, and inferring one from calendar events is a heuristic nobody has specified. D-20 flags the same thing (`D-20.md:153-155`). Retire the row or specify the rule. |
| 50 | Share, import & export | **needs-design-work** | Export/import JSON is K-37 and needs only the resource classification (§5.3). Rendering the QR is solved (`eqrcode`, §5.3). **Two rows are not:** the QR shares a `kati://` reference that cannot resolve on a receiving device with no server (§5.3), and "Print the week (PDF)" has no path in v1 (§4). Both need an owner decision, and the PDF row is this design's first candidate for K-43's retirement ritual. |
| 51 | Meal reminders | **needs-design-work** | The scheduling half is settled: `MobNotify.schedule/2` arms a real OS alarm that fires while the app is dead (S-13, `charting-brief.md:44`) and K-32 already budgets 60 Android alarms for meals (`K-32.md:117`). **The inline Eaten / Skip / Snooze buttons do not exist on either platform** (§5.4) — ❌ in Mob's own surface matrix, and `calendar-and-sync.md:125` is wrong about this. Either cost a fourth `MobBridge.kt` patch or redraw the bubble as tap-to-open. |
| 52 | Meals on the calendar | **buildable** | Entirely covered by tickets that already exist: `events.kind: :meal` is in K-21's frozen schema (`K-21.md:143`), and the collapse row is a named K-23 acceptance fixture (`K-23.md:277`). The only new work is the projection rule in §5.2. |

**Bonus — screen 23 (the subscription ledger), in scope per the ticket:**

| # | Screen | Verdict | Reason |
|---|---|---|---|
| 23 | Subscriptions | **buildable** | Single-currency `:decimal` storage (§3.2), £/h as a live division (§3.3), renewal dates as `kind: :money` events on K-21's table with K-20 expanding the billing rule (§5.1, and note the `BYMONTHDAY=-1` requirement). `ex_cldr_currencies` formatting is settled (§3). The one caveat is the *"Worth a look"* advice card, which needs its rule written down like screen 47's insight row. |

Summary: **6 buildable, 5 needs-design-work, 0 not-in-v1** — but one *row* inside screen 50
("Print the week (PDF)") is not-in-v1, and one row inside screen 51 (inline notification actions)
is not-in-v1 unless native work is funded.

---

## 7. Follow-up tickets this raises

Per the ticket's own note — *"treat a long list of follow-ups as success, not scope creep"*. These
are **recommendations for the main session to file**; this research created none of them.

1. **Model the meal domain and ship it as a migration** (task, sibling of K-21). §2's seven
   resources, the snapshot rule on `meal_logs`, the aisle enum, and the portion-multiplier
   rounding contract. Blocked by K-03 for the same reason K-21 is.
2. **Correct the notification-actions claim, and decide screen 51's fate** (task/grilling).
   `calendar-and-sync.md:125` asserts `mob_notify` supports notification actions; it does not
   (§5.4). Fix the research file, fix K-32's snooze design, and either cost a `MobBridge.kt`
   action-button patch as a new row in K-05's ledger or redraw screens 51 and 31's snooze.
3. **Screen 50's QR: pairing token or plan payload** (grilling/design, extends D-20 and K-37).
   Resolve what a `kati://plan/…` reference means with no server (§5.3). Recommend demoting the QR
   to a pairing token over a `.katiplan` file hand-off.
4. **Retire "Print the week (PDF)" as K-43's first worked example** (process). §4 gives the costed
   alternative path if it is ever revived; K-43 explicitly wants *"the first application of the
   ritual, to whichever item has the strongest evidence at the time"* (`K-43.md:63`).
5. **A pantry model, or cut screen 46's "In my fridge" tab** (design, extends D-20). §6.
6. **Specify or retire screen 49's "Auto-switch → Travel week"** (design, extends D-20). §6.
7. **Screen 48's price estimate: drop it or draw the input** (design, extends D-20). §2.5.
8. **Verify a `priv/` data file survives `mix mob.release --android`** (spike, extends K-03/K-10).
   The dev deploy rsyncs the host app's `priv/` and gives it a real OTP lib dir so
   `:code.priv_dir/1` works (`i18n-l10n.md:174-178`), but **the release path was not verified** and
   the whole bundling decision in §1 rests on it. **UNKNOWN until measured.** Check one known
   Elixir bug while there: <https://github.com/elixir-lang/elixir/issues/12307> — *"`mix do` does
   not detect changes in `priv` directory when `release` task is used"*, so a chained
   `mix do …, release` ships **without** those files. If Kati's build pipeline chains mix tasks,
   that silently drops both the food database and ex_cldr's compile-time-downloaded `fa.json`.
9. **A charting ticket** (task). Screens 47, 07, 22 and 61 need bars, target lines and pixel fields
   with RTL mirroring — §7 item 13 (`design-index.md:422`), S-47 (`charting-brief.md:93`). No K-
   ticket owns charts today; D-11, D-13, D-15 and D-19 all assume they exist.
10. **Add the meal and money resources to K-37's backup classification** (amend K-37, not a new
    ticket). §5.3's table, including the `:cache` classification for bundled food rows.
11. **If the PDF row is ever revived, two device tests gate it** (attach to the K-05 ledger row, not
    a ticket yet): does Persian shaping and bidi survive Android WebView's *print-to-PDF*
    conversion — using an embedded `data:font/ttf;base64,…` Vazirmatn to sidestep the documented
    custom-Arabic-font failure mode — and does the week grid's `@page` / `break-*` CSS hold, given
    the guide states print attributes are *"not supported"*. §4.1.
