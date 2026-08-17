# Media Tracker — Data Sources Reference

> **Provenance.** Supplied by the owner (Shahryar) on 2026-08-17, verbatim below the divider.
> This is a primary reference for every media-source decision in the project. Rate limits and
> endpoints change often on free tiers — re-verify against live docs before relying on them.

## What this changes for Kati

Read this section first; the reference itself follows unedited.

1. **Several high-value sources need no credentials at all.** TVmaze, AniList, Jikan, Wikidata and
   Bangumi are keyless. Issue #56 decided to ship a TMDB key and keep "Tier 2" empty specifically
   to avoid credential management and support burden for a solo maintainer — but that reasoning
   does not apply to a keyless source. #56 is reopened on this basis.

2. **Anime is a first-class media type with its own sources**, not a TMDB genre. AniList's
   `nextAiringEpisode { airingAt }` is a Unix timestamp — precisely the input Kati's local alarm
   scheduler (#59) needs — and it is the single best anime release signal available. This makes
   anime cheap to support well, and it lands inside v1 rather than after it: #60 scoped v1 to the
   Screen domain, and #21 already establishes anime as a **filter across existing screens** rather
   than a separate section.

3. **Two schema requirements that must be in migration 1**, both painful to retrofit:
   - **`external_ids`** — `{tmdb, imdb, tvmaze, anilist, mal, tvdb}` on every title, from day one.
     The moment TMDB and AniList are both in play, cross-service identity is unavoidable.
   - **`date_confidence`** — `exact | day | month | quarter | year | unknown`. A source that gives
     only a year must **not** be stored as 1 January and must **not** fire a notification. This is
     a correctness requirement for the app's headline feature, not a nicety.
   Filed as its own ticket alongside #57's `fetched_at` rule.

4. **TVmaze's `airstamp` beats TMDB's `air_date`** for scheduling: a full ISO-8601 timestamp with
   timezone rather than a bare date. Kati arms OS-level alarms at exact instants (#59), so the
   hour matters. This makes TVmaze schedule-authoritative even though TMDB stays
   metadata-authoritative.

5. **Incremental endpoints exist and should be used** — `TVmaze /updates/shows?since=day` and
   TMDB's `/tv/changes` collapse an entire followed-list refresh into very few requests. Directly
   relevant to #58's Kotlin periodic fetch, which runs on a 6-hour WorkManager cadence and must be
   cheap.

6. **Constraints that bind decisions already made:** TMDB caps caching at **6 months** (already
   #57's rule, now corroborated), requires attribution plus its logo (#8), is non-commercial
   without a written agreement, and **prohibits using its content to train ML/AI models**. Trakt's
   free tier now limits an account to **one connected third-party app**, which is a strong argument
   against building on it.

7. **Not applicable to Kati, and why.** The reference's notification section assumes a server:
   FCM, Telegram bots, Web Push and per-user `.ics` feeds all need infrastructure Kati does not
   have (#52 ruled out any server; #58/#59 do it on-device). Simkl and Trakt as list-storage
   backends are likewise out — Kati owns its own data on the device. `TheTVDB` v4 needs a paid
   subscription for most use, and `Watchmode`/`Streaming Availability` are credentialed, so all
   three stay out of v1 under #56's reasoning.

8. **Ship a manual-entry path and a "report missing title" action.** The reference makes the point
   well: manual entry closes nearly all remaining coverage gaps for almost no engineering cost, and
   TMDB is community-editable so a missing title can be fixed upstream. Kati's design has no such
   surface today — this is a design gap.

---

# Media Tracker — Data Sources Reference

Reference for building a personal "what have I watched / what's releasing next"
tracker covering **movies, TV series, and anime**.

Goal of the app: keep a user's list, know the release/air date of every item,
and notify when something drops. All sources below are free (or have a usable
free tier).

> Verify rate limits and endpoints against live docs before relying on them —
> free tiers change often.

---

## Quick decision table

| Need | Use |
|---|---|
| Movie + TV metadata, posters, release dates | **TMDB** (primary) |
| Accurate per-episode TV air schedule | **TVmaze** |
| Anime episode countdowns | **AniList** (primary) |
| Anime fallback / MAL data | **Jikan** |
| Anime dub release dates | **AnimeSchedule.net** |
| One API for all three media types + user lists | **Simkl** |
| Where to stream legally | TMDB `/watch/providers` |
| Obscure / announced / regional titles | **Wikidata** |
| Cross-service ID mapping | **anime-offline-database**, TMDB `/find` |

**Recommended core stack:** TMDB (film + TV) + AniList (anime) + TVmaze
(schedule accuracy) + Wikidata (long tail). Everything else is optional.

---

## 1. TMDB — The Movie Database

**Primary source for movies and TV.**

- Base URL: `https://api.themoviedb.org/3`
- Docs: https://developer.themoviedb.org/docs
- Auth: free API key. Two options —
  - v3: `?api_key=YOUR_KEY`
  - v4: header `Authorization: Bearer YOUR_READ_ACCESS_TOKEN` (preferred)
- Cost: free for non-commercial use. **Attribution + TMDB logo required.**
  Terms also cap caching at 6 months. Commercial use needs a written agreement.
- Rate limit: ~40–50 req/s soft ceiling. Generous.

### Key endpoints

```
GET /search/multi?query=dune                    # movies + tv + people in one
GET /movie/{id}                                 # details
GET /movie/{id}/release_dates                   # per-COUNTRY dates (theatrical/digital)
GET /tv/{id}                                    # includes next_episode_to_air
GET /tv/{id}/season/{n}                         # every episode + air_date
GET /tv/{id}/watch/providers                    # JustWatch data, by country
GET /discover/tv?first_air_date.gte=2026-09-01
GET /find/{external_id}?external_source=imdb_id # IMDb -> TMDB id
```

### Example

```bash
curl -H "Authorization: Bearer $TMDB_TOKEN" \
     "https://api.themoviedb.org/3/tv/1396?append_to_response=external_ids"
```

Use `append_to_response` to merge several sub-resources into one request —
big win for rate limits.

### Images

```
https://image.tmdb.org/t/p/w500{poster_path}
```

Sizes come from `GET /configuration`.

### Gotchas

- Release dates are **per country** — always pick the user's region, don't use
  the top-level `release_date` field blindly.
- "Planned" titles often have only a year, or `null`. Handle it (see
  `date_confidence` below).
- Community-edited, so obscure titles may be thin or wrong.
- Daily full ID dumps: `http://files.tmdb.org/p/exports/` — useful for seeding
  a local DB instead of hammering the API.

---

## 2. TVmaze

**Best free per-episode TV schedule. No key.**

- Base URL: `https://api.tvmaze.com`
- Docs: https://www.tvmaze.com/api
- Auth: none for public endpoints
- Rate limit: ~20 calls per 10 s per IP

```
GET /search/shows?q=severance
GET /shows/{id}?embed=episodes         # all episodes with airstamp (ISO + TZ)
GET /shows/{id}/episodebynumber?season=2&number=3
GET /schedule?country=US&date=2026-08-16
GET /schedule/web?date=2026-08-16      # streaming-only releases
GET /lookup/shows?imdb=tt11280740      # IMDb/TVDB -> TVmaze
GET /updates/shows?since=day           # incremental sync
```

`airstamp` is a full ISO-8601 timestamp with timezone — more reliable than
TMDB's date-only `air_date` when you need to fire a notification at the right
hour.

**Gotchas:** Western TV coverage is excellent; non-English and streaming
exclusives are weaker.

---

## 3. AniList

**Primary anime source. GraphQL, no key for public data.**

- Endpoint: `POST https://graphql.anilist.co`
- Docs: https://docs.anilist.co
- Auth: none for public data. OAuth2 only to read/write a logged-in user's list.
- Rate limit: low (tens of requests/minute) — read the `X-RateLimit-Remaining`
  response header and back off on `429`.

### Next-episode query

```graphql
query ($id: Int) {
  Media(id: $id, type: ANIME) {
    id
    title { romaji english native }
    status
    episodes
    nextAiringEpisode { airingAt episode timeUntilAiring }
    idMal
    coverImage { large }
  }
}
```

`airingAt` is a Unix timestamp — exactly what you want for scheduling a push.

### Weekly schedule query

```graphql
query ($start: Int, $end: Int) {
  Page(perPage: 50) {
    airingSchedules(airingAt_greater: $start, airingAt_lesser: $end) {
      airingAt episode media { title { romaji } idMal }
    }
  }
}
```

### Example

```bash
curl -s https://graphql.anilist.co \
  -H 'Content-Type: application/json' \
  -d '{"query":"{ Media(id:21, type:ANIME){ title{romaji} nextAiringEpisode{ airingAt episode } } }"}'
```

**Gotchas:** sub-only schedule (no dub dates). Query only the fields you need —
GraphQL means no over-fetching, so keep payloads small.

---

## 4. Jikan (unofficial MyAnimeList API)

Fallback / cross-check for anime.

- Base URL: `https://api.jikan.moe/v4`
- Docs: https://docs.api.jikan.moe
- Auth: none
- Rate limit: ~3 req/s, ~60/min. Hard. Cache aggressively.

```
GET /anime/{mal_id}
GET /anime/{mal_id}/full
GET /schedules?filter=monday
GET /seasons/now
GET /seasons/2026/fall
GET /anime?q=frieren&limit=5
```

**Gotchas:** cached MAL scrape, so data can lag a few hours. Do not use as your
only anime source.

---

## 5. MyAnimeList Official API

Only needed if you want to sync a user's actual MAL list.

- Base URL: `https://api.myanimelist.net/v2`
- Docs: https://myanimelist.net/apiconfig/references/api/v2
- Auth: `X-MAL-CLIENT-ID: {client_id}` header for public data;
  OAuth2 + PKCE for user list read/write.

```
GET /anime?q=&limit=10
GET /anime/{id}?fields=start_date,broadcast,status,num_episodes
GET /users/@me/animelist?status=watching
PATCH /anime/{id}/my_list_status
```

---

## 6. Simkl

The only API that covers **TV + movies + anime in one schema**, plus user lists.
Good option if you want to avoid running your own accounts/list storage.

- Base URL: `https://api.simkl.com`
- Docs: https://simkl.docs.apiary.io
- Auth: header `simkl-api-key: {client_id}`; OAuth (incl. device/PIN flow) for
  user data.

```
GET  /search/tv?q=dark
GET  /tv/{id}?extended=full
GET  /calendar/tv                       # upcoming episodes
GET  /calendar/movies
GET  /sync/all-items/shows/watching     # user's list (OAuth)
POST /sync/history                      # mark watched (OAuth)
```

Also exposes **iCal / RSS / JSON feeds** for a user's calendar — you can skip
building a notification engine entirely and just hand users an `.ics` URL.

---

## 7. Trakt

Similar role to Simkl. Note: free-user list limits got tight in 2025–2026 and
free accounts are now limited to one connected third-party app, which is a
real constraint for a new client app.

- Base URL: `https://api.trakt.tv`
- Docs: https://trakt.docs.apiary.io
- Headers:
  ```
  trakt-api-version: 2
  trakt-api-key: {client_id}
  Authorization: Bearer {access_token}   # for user endpoints
  ```

```
GET /shows/{id}/next_episode
GET /calendars/my/shows/2026-08-16/7     # OAuth
GET /search/movie?query=arrival
```

---

## 8. TheTVDB v4

TV metadata, strong on episode numbering and non-US shows.

- Base URL: `https://api4.thetvdb.com/v4`
- Auth: `POST /login` with `{"apikey": "..."}` → returns a bearer token
  (valid ~30 days). API key requires a subscription for most use; check current
  terms for personal/open-source exceptions.

```
GET /series/{id}/episodes/default
GET /search?query=...&type=series
```

---

## 9. OMDb

Cheap IMDb-derived lookups. Good for IMDb ratings, not for schedules.

- Base URL: `https://www.omdbapi.com/`
- Auth: `?apikey=YOUR_KEY`
- Free tier: 1,000 req/day

```
GET /?apikey=KEY&i=tt0903747
GET /?apikey=KEY&t=Breaking+Bad&Season=1
```

---

## 10. AnimeSchedule.net

Fills AniList's biggest gap: **dub release dates**, plus sub/raw timetables.

- Base URL: `https://animeschedule.net/api/v3`
- Auth: `Authorization: Bearer {token}` (free token from your account page)

```
GET /timetables/sub?year=2026&week=33
GET /timetables/dub
GET /anime?q=...
```

---

## 11. Wikidata — the long-tail fallback

Free, no key, and surprisingly good for announced, regional, and obscure titles
that TMDB hasn't got yet.

- SPARQL: `https://query.wikidata.org/sparql?format=json&query=...`
- REST: `https://www.wikidata.org/w/api.php`
- Auth: none. **Set a descriptive `User-Agent`** or you'll get blocked.

Useful properties: `P577` publication date, `P1476` title, `P345` IMDb ID,
`P4947` TMDB movie ID, `P4983` TMDB TV ID.

Use it as a last-resort resolver when your primary sources return nothing.

---

## 12. Streaming availability

- **TMDB `/watch/providers`** — free, JustWatch-sourced, per country. Start here.
- **Watchmode** — `https://api.watchmode.com/v1`, `?apiKey=`, free monthly credit
  allowance, deeper catalog + deep links.
- **Streaming Availability API** (via RapidAPI) — small free tier, good regional
  coverage.
- JustWatch itself has **no public API** — don't scrape it.

---

## 13. Known coverage gaps

| Gap | Workaround |
|---|---|
| Asian dramas (K/C/Thai/Turkish) — bad episode dates | Wikidata + manual entry; MyDramaList has no official API (only unofficial scrapers like `kuryana` — unstable, use at your own risk) |
| Chinese donghua / Korean aeni | AniList > MAL; Bangumi.tv (`https://api.bgm.tv`) for Chinese titles |
| Announced-but-unscheduled titles | Store date precision, don't invent a day |
| Anime dubs | AnimeSchedule.net |
| Regional/local TV | Wikidata + user-submitted entries |

**Always ship a manual-entry path.** Letting a user add a title with their own
date closes ~all remaining gaps for near-zero engineering cost. Also add
"report missing title" — TMDB is community-editable, so you (or the user) can
add it upstream.

---

## 14. ID mapping between services

You will need this the moment you mix TMDB and AniList.

- **anime-offline-database** (manami-project, GitHub) — single JSON mapping
  MAL / AniList / Kitsu / AniDB / AnimePlanet IDs. Download and cache it.
- **Fribb/anime-lists** (GitHub) — adds TMDB and TVDB mappings for anime.
- **TMDB `/find/{id}?external_source=imdb_id`** — IMDb ↔ TMDB.
- **TVmaze `/lookup/shows?imdb=`** — IMDb/TVDB ↔ TVmaze.
- AniList `Media.idMal` gives you the MAL ID for free in any query.

Store a `external_ids` object on every record from day one. Retrofitting this
later is painful.

---

## 15. Notifications

- **Firebase Cloud Messaging** — free push for iOS/Android/web.
- **Telegram Bot API** — free, trivial to implement, great for a v1 or for a
  personal-use build. `POST https://api.telegram.org/bot{token}/sendMessage`
- **iCal export** — generate an `.ics` feed per user and let their phone's
  calendar handle reminders. Zero infrastructure, very reliable.
- **Web Push (VAPID)** — for a PWA.

---

## 16. Suggested schema notes

Store, per title:

```
id, type (movie|tv|anime)
external_ids { tmdb, imdb, tvmaze, anilist, mal, tvdb }
next_release_at        # UTC timestamp
date_confidence        # exact | day | month | quarter | year | unknown
source                 # which API this date came from
last_checked_at
user_override_date     # manual entry wins over everything
```

`date_confidence` matters: if a source only gave you a year, do **not** store
Jan 1 and fire a notification. Suppress or degrade the reminder instead.

**Sync strategy:** nightly cron over items with `status != ended`, refresh from
the source API, diff `next_release_at`, schedule notifications for changes.
Use incremental endpoints (`TVmaze /updates/shows?since=day`) where available
rather than re-fetching everything.

---

## 17. Legal / terms checklist

- TMDB: attribution + logo, non-commercial only without an agreement, ≤6 month
  cache. Their terms also prohibit using TMDB content for training ML/AI models.
- AniList / Jikan / TVmaze: respect rate limits; identify your client via
  `User-Agent`.
- Never scrape JustWatch, IMDb, or MyDramaList directly — use the APIs above.
- Torrent indexers are the worst possible release signal (later and less
  accurate than official air dates) on top of the legal exposure. Skip them.
- Read each service's terms before any commercial use; several free tiers are
  explicitly personal-use-only.
