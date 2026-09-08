# Movies & TV — every page, every control, as a user

**What this is.** One scenario per thing a person can do in the film-and-series
half of Kati, written as a person doing it, with the taps they actually make.
It is a **todo list**: work down it, one page at a time, and a page is finished
only when every scenario under it passes on a real device.

**The rule for a finished page**, in the user's own words: *each page done we
must delete it from settings screen pages there too.* `Settings → Every screen`
is the flat list of all 173 boards. A page that can only be opened from there is
not in the app yet. When a page is reachable by a real route and every scenario
below it passes, its row comes out of `Kati.Screens.Gallery` and this file
records the commit that did it.

**Order of work** (also the user's): start at **Home**, finish it completely,
then move to the next screen page. Books and music are out of scope for now.

## How to run one

```bash
set -a; . ~/.config/kati/tmdb.env; set +a
touch lib/kati/media/tmdb.ex          # see "The compile-time token trap" below
mix kati.e2e.stage && ./bin/deploy_native.sh
```

Then walk the steps on the Pixel 9a. `adb shell input tap X Y` works; screenshot
with `adb shell screencap -p /sdcard/s.png && adb pull /sdcard/s.png`.

## The compile-time token trap — read this before testing anything with search

`Kati.Media.Tmdb.key/0` falls back to `@bundled_key`, a **module attribute
captured when `tmdb.ex` is compiled**. `mix` does not recompile a module because
an environment variable changed, so sourcing `tmdb.env` in the staging shell is
not enough on its own: if `tmdb.ex` was last compiled without the token, the
staged build carries `nil` and every search answers `RESULTS 0` **in silence**.

Cost me an hour and a wrong diagnosis. `touch lib/kati/media/tmdb.ex` before
staging, every time.

**Verified working on the device on 6 September**: search `blade` → `RESULTS 20`
with real overviews, tap the `+` on Blade Runner → the disc becomes a check →
the title is tracked. The chain from TMDB to the store is sound. What follows is
everything around it that is not.

## Status key

- `[ ] untested` — needs a device pass
- `[!] known broken` — provable from the source, with the trace beside it
- `[?] unknown` — depends on data or on something not yet established

---

## Finding a title and adding it

**Routes, verified against the code (routes.txt is right except where noted):**

| # | Page | How a person gets there |
|---|---|---|
| 06 | Add a title | `+` FAB, from **any** dock root — Home, Calendar, Library, Stats (`root.ex:228,231`) |
| 154 | Add a title by hand | Home → `+` → *Can't find it? Add it by hand* (`add_title.ex:189`) |
| 156 | افزودن دستی | same row, with Language = فارسی (`AddByHand.for_locale/0`) |
| 80 | Data sources | Home → Settings → Data sources |
| 18 | Quick add | **routes.txt is wrong here.** It IS reachable: dock **Calendar** → the ⋯ in the header → *Quick add* (`calendar.ex:303,1237`). The BFS missed it because `Kati.UI.Menu` draws no panel until `:toggle_menu` fires. |
| 155, 157 | Add by hand — states / dark | ⚠️ **gallery only** |

**The one fact that governs the whole group.** `Kati.Media.Tmdb.key/0` (`tmdb.ex:283`) is the gate. It reads `Kati.Sources.tmdb_key/0`: `:kati` → `bundled_key/0`, which is `System.get_env("TMDB_READ_TOKEN")` at runtime **or** `@bundled_key` captured at **compile** time (`tmdb.ex:332-337`). So on a Pixel — which has no shell and no environment — search works **only if `~/.config/kati/tmdb.env` was sourced in the shell that ran `mix kati.e2e.stage`**. Source it, or every scenario below that involves TMDB draws *"No TMDB key yet. Add one in Settings → Data sources."* and the whole sheet is a fixture. Run each 06 scenario **twice**: once staged with the token, once without.

---

### 80 — Data sources (`Kati.Screens.DataSources`)

The page the error message points at. Read this page before 06, because it decides whether 06 can work at all.

**1. I follow the app's own instruction and go to Settings → Data sources to add my key**
- Home → tap **Settings** → tap **Data sources**.
- **Expect:** somewhere to paste a TMDB read token.
- `[!] known broken — there is no field. Nowhere on this screen, or anywhere in the app, can a TMDB key be typed.` The message on 06 sends the user to a page that cannot do what it promises. `tmdb.ex:302-307` reads `Kati.SecureStore.get("tmdb")`; grep across `lib/` finds `SecureStore.put/2` called by **nothing** for the key `"tmdb"` (`sources.ex:145` and `caldav/transport.ex:119` are the only other `get`s). Board `80.html` draws no field either, so this is a gap in the design as well as the build.

**2. I tap "Use my own key" because I want my own rate limit**
- Home → Settings → Data sources → tap **Use my own key**.
- **Expect:** a field appears, or a sheet opens, asking for the key.
- `[!] known broken — it silently disables TMDB.` `handle_tap(:key_own, …)` (`data_sources.ex:563`) writes `:own` to `Mob.State` and relights the chip. From that moment `key/0` reads the empty secure store and answers `{:error, :no_api_key}`, so screen 06 stops returning results and starts showing the *"No TMDB key yet"* notice — which points back at this page, which has no field. A working search becomes a broken one, permanently, from one tap on a chip that looks like a preference. Recoverable only by tapping **Use Kati's key** again.

**3. I tap Connect on ListenBrainz**
- Data sources → tap the **ListenBrainz** row.
- **Expect:** a real pairing code that ListenBrainz will accept.
- `[!] known broken — the code is a constant.` `pairing_code/1` (`data_sources.ex:397-400`) returns the hardcoded `"K4Q9B2"`, the card prints a hardcoded `"Expires in 9:48"` that never counts down (`:378`), and the URL under it is hardcoded `listenbrainz.org/link` **for all three providers** (`:375`) — tap Hardcover or TheTVDB and you are still sent to ListenBrainz. Nothing in `lib/` talks to any of the three. Not a Movies/TV blocker, but it is drawn beside TMDB and it teaches the user this page lies.

**4. I try to disconnect what I connected**
- **Expect:** a row showing *Connected as …* with a **Disconnect**.
- `[?] unknown — unreachable in practice.` `Sources.connected?/1` asks `SecureStore` (`sources.ex:144`) and nothing ever writes a tier-2 token, so `connect_control(true, _)` and `connected_line/1` (`:287-290`, the stated fiction *"Connected as ines.k · 412 listens"*) can never render on a device. The whole *Connect an account* section is decoration.

**5. I tap Refresh, then Clear, under Cached metadata**
- Data sources → scroll to **Cached metadata** → tap **Refresh**; tap **Clear**.
- **Expect:** Refresh re-fetches stale cache rows; Clear empties the cache and the label drops to *Nothing cached yet*.
- `[!] known broken — both are pictures.` `SettingsList.action_pill/1` (`settings_list.ex:702-716`) passes no `on_tap` at all, so neither pill emits a tap. They are not even in `@inert_taps`, because a control that sends nothing is invisible to `Kati.ScreenTapSweepTest`. This is the only place in the app that offers to clear the metadata cache.

**6. I tap "Disconnect everything and wipe tokens"**
- Data sources → tap the red **Disconnect everything and wipe tokens** row.
- **Expect:** a confirmation, then every token gone.
- `[!] known broken — no confirmation on the only destructive control on the page`, and it also silently deletes the `"tmdb"` key (`sources.ex:193-198`) that nothing can put back. `handle_tap(:wipe_tokens, …)` (`:551`) fires immediately.

**7. The reached-at times are honest**
- Data sources → read the times on the right of TVmaze / Open Library / MusicBrainz / TMDB.
- **Expect:** `—` on a fresh install; a real `HH:MM` for TMDB after a successful add on 06.
- `[ ] untested` — `last_reached/1` (`:135`) genuinely reads `CachedTitle` by source. It only ever moves for `:tmdb`, because TVmaze, Open Library and MusicBrainz have no client. Worth confirming that a fresh phone shows four em dashes and that TMDB's fills in the moment scenario 06/9 succeeds.

---

### 06 — Add a title (`Kati.Screens.AddTitle`)

The user's own journey lives here. It is also the screen with the most drawn-but-false state in the group.

**8. I open the + and see four films I have never heard of**
- Dock **Home** → tap the **+** button.
- **Expect:** an empty sheet, or a prompt to type.
- `[!] known broken — it opens on four invented titles.` `mount/3` assigns `results: Sample.search_results()` (`add_title.ex:101`), so the sheet always opens on *The Quiet Coast*, *Quiet Earth*, *A Quiet Place to Land* and *Quietus* — with **real poster images** (`thumb/1` → `Kati.Design.Images.poster/1`), a **`4 results`** eyebrow, and availability lines reading *Lumen+*, *Cinema*, *Northlight*. Nothing here is the user's data and nothing marks it as a sample. Board 06 was drawn mid-query; the resting state was never drawn and never built.

**9. The user's own scenario: I search for a film that exists and I add it**
- Home → **+** → tap the search field → type `estuary` (or any real film) → tap the **ink + disc** on the row you want.
- **Expect:** results from TMDB replace the fixtures; the eyebrow counts them; the disc turns to a muted check; the title is in the library, and appears on **Library** with a poster and *Watching*.
- `[?] unknown — depends entirely on whether the staged build carries the token.` The path is real: `handle_info({:change, :title_query, …})` (`:224`) → `searched/2` (`:270`) → `Tmdb.search/1`; `add/2` (`:452`) → `track/2` (`:487`) → `Tmdb.fetch/2` fills `CachedTitle`/`CachedSeason`/`CachedEpisode`, then `Ash.create(TrackedTitle, source: :tmdb, status: :watching)`. **Check the shelf after, not just the disc** — the disc flips on `{:ok, _}` only.

**10. I search for something that does not exist**
- Home → **+** → type `zzzqwertyfilm`.
- **Expect:** *No results for "zzzqwertyfilm"* — something that says the search ran and found nothing.
- `[!] known broken — you get the bare eyebrow "0 results" and a blank page below it.` `render/1` (`:114-137`) draws `search_notice`, the eyebrow, then `results([])` — an empty `Column` and a `Spacer`. There is no empty state. The sibling music sheet has one (`AddTitleMusic.nothing_band/2`); 06 does not. Indistinguishable from a search that never ran.

**11. I type two letters of a short title**
- Home → **+** → type `Up`.
- **Expect:** results for *Up*.
- `[!] known broken — under three characters the sheet silently restores the four fixtures.` `@min_query 3` at `:222`, and the sub-floor branch at `:228-238` re-assigns `Sample.search_results()` and clears the error. So typing `Up` shows *Quiet Earth* and *Quietus*, captioned `4 results`, as if they matched. `Up`, `It`, `Us`, `Coco`… — real films that this floor makes unfindable, answered with a lie instead of a prompt.

**12. I type, then delete back to nothing**
- Home → **+** → type `estuary` → hold backspace until the field is empty.
- **Expect:** back to the resting state.
- `[!] known broken — the four fixtures come back` (same branch, `:228`), so a person who has just seen real results watches them replaced by four films they did not search for.

**13. I tap the X at the end of the search field**
- Home → **+** → type something → tap the **cancel (X)** glyph on the right of the field.
- **Expect:** the field clears.
- `[!] known broken — the X is a glyph with no tap.` `Kati.UI.symbol("cancel", …)` at `:423` passes no `on_tap`; it is inside the field `Row`, which also has none.

**14. I use the three scope chips**
- Home → **+** → search something that returns both films and series → tap **Films**, then **Series**, then **Everything**.
- **Expect:** the list narrows and the `N results` eyebrow follows it; a title added under Films is still marked added under Everything.
- `[ ] untested` — `visible/2` (`:326-328`) filters on `String.contains?(r.meta, "FILM"/"SERIES")` and `meta_line/1` (`:311`) writes exactly those words, so it should hold. **`filter_Everything` is in `@inert_taps`** (`screen_tap_sweep_test.exs:383`) with the stated reason *"the already-selected member of its family"* — tapping the chip that is already lit sets the value it already has. Correct, but confirm it visibly stays lit rather than looking dead.

**15. I add the same title twice**
- Home → **+** → search a title → add it → tap the **close disc** → tap **+** again → search the same title → tap its **+** disc.
- **Expect:** the row already shows a check, or the sheet tells you it is already in your library.
- `[!] known broken — nothing happens at all, and no row is written.` Two proven defects compound: (a) `mount/3` never asks the library what is already tracked, so `added:` is always `false` on reopen (`:101`); (b) the write hits the `unique index [:source, :source_id]` on `tracked_titles` (`tracked_title.ex:64`), `add/2` takes the `{:error, _}` branch at `:470` and assigns `:save_error` — **and `render/1` never draws `save_error`** (grep: assigned at `:104, :282, :467, :470`, read nowhere). The disc does not flip, because `mark/2` is only called on success. A tap into total silence. `add_title_write_test.exs:85` asserts only that no second row is written, never that the user is told.

**16. I change my mind and un-add a title I just added from TMDB**
- Home → **+** → search → add a title (disc turns to a check) → tap the **check** to remove it.
- **Expect:** it leaves the library.
- `[!] known broken — the disc flips back to + and the title stays in the library forever.` `untrack/1` (`:567-572`) looks for `source == :manual and source_id == title`. A TMDB add wrote `source: :tmdb, source_id: <numeric id>` (`:496-501`). The filter matches nothing, returns `{:ok, :already_gone}`, and `mark/2` cheerfully un-checks the row. This is the single most dishonest control in the group: it reports success for a deletion it did not perform, and the sheet offers no other way to undo an add.

**17. I add "A Quiet Place to Land", which the sheet says I already have**
- Home → **+** (do not type) → tap the **muted check** on the third row.
- **Expect:** it is already in my library; tapping removes it.
- `[!] known broken — it was never in the library.` `Sample.search_results/0` hardcodes `added: true` on that row (`library/sample.ex:284`). The check is fiction. Tapping it runs the untrack path, finds nothing, flips to `+`; tapping again **writes a real `:manual` TrackedTitle + CachedTitle for a film that does not exist** and it appears on the Library shelf. Every one of the four fixture rows can be added for real this way.

**18. I search for a remake and add the right one**
- Home → **+** → search `Dune` (or anything with two same-named results — board 06 itself draws three titles beginning *Quiet*) → tap the **+** on the **second** row with that exact title.
- **Expect:** the one I tapped is added.
- `[!] known broken — the first row with that title is added instead, and both rows change state.` `add/2` does `Enum.find(socket.assigns.results, &(&1.title == title))` (`:453`) and `mark/2` (`:599`) rewrites every row whose `title` matches. The tap tag is built as `String.to_atom("add_" <> title)` (`:762`), so two identical titles produce one identical tag and the sheet cannot tell them apart. Same code also mints a permanent atom per distinct TMDB title returned — an unbounded atom table from provider data.

**19. I search with airplane mode on**
- Turn on airplane mode → Home → **+** → type `estuary`.
- **Expect:** *Could not reach TMDB. Hand-typed titles still work.*
- `[ ] untested` — this path is genuinely built now, and the brief's premise is stale: `search_notice/1` **is** rendered (`:133`), above the count, and `Tmdb.message({:network, _})` (`tmdb.ex:363`) has that exact wording. Worth walking, because it is the one failure the sheet handles well and it should not regress. Also try it with `Use my own key` selected (scenario 2) — you should get the `:no_api_key` sentence instead.

**20. Where the + takes me from each root**
- Tap **+** from Home, then from **Calendar**, then from **Library**, then from **Stats**. Then Library → **Books** shelf → **+**. Then Library → **Music** shelf → **+**.
- **Expect:** the sheet appropriate to where I am.
- `[!] known broken — only Music forks.` `Kati.Screens.Root.add_sheet/0` returns `Kati.Screens.AddTitle` for every root (`root.ex:228`); the sole override in `lib/` is `music.ex:1089` → `AddTitleMusic`. So the **Books** shelf's `+` opens the films-and-series sheet, and so does the **Calendar** root's — pressing `+` on the Schedule tab offers to add a film. The music sheet's own moduledoc calls the fork `AddTitle.for_shelf/1`; no such function exists.

**21. I add a title and then look for it**
- Complete scenario 9, then tap the **close disc** → tap the **Library** dock icon.
- **Expect:** the title on the shelf, with poster and status.
- `[ ] untested` — the write shape is right (`CachedTitle` carries the name, which `Kati.Screens.Library` requires) but there is **no confirmation of any kind** on 06: no toast, no count change, nothing but the disc. Check what the shelf actually draws for a `:manual` add with no poster.

---

### 154 — Add a title by hand (`Kati.Screens.AddByHand`)

The best-built page in the group, and still lying about two of its five fields.

**22. Nothing was found, so I type it in myself**
- Home → **+** → type something with no results → tap **Can't find it? Add it by hand** → type a title → tap **Add to library**.
- **Expect:** the title is in the library; I land somewhere that shows me it worked.
- `[!] known broken — it pops back to screen 06, which is still showing the four fixture films.` `save/1` ends in `Mob.Socket.pop_screen(socket)` (`add_by_hand.ex:467`). Board **155** decided this explicitly and in as many words: *"Straight to the new title's detail screen — 04 for a series, 08 for a film. Returning to 89 would leave the person on a search results page for a title they just finished typing."* The write itself is correct — `cache/2` then `track/2` (`:461-470`), and `add_by_hand_test.exs:81` proves it reaches the shelf and `Kati.Search.Query.run/1`.

**23. I fill in the Year, because I know it**
- Home → **+** → *Add by hand* → type `The Long Hollow` → type `2024` in **Year** → **Add to library** → open the title from the Library.
- **Expect:** the year on the detail screen; it is the whole reason the field exists ("*losing it would mean asking again when the catalogue arrives*").
- `[!] known broken — Year is typed, held on the socket, and thrown away.` `track/2` (`:477-486`) writes `source, source_id, kind, status` only; `AddTitle.create_cache/2` (`add_title.ex:545-562`) writes `source, source_id, kind, title, fetched_at` only. **`Kati.Media.CachedTitle` has no year column at all** — only `next_release_at` (`cached_title.ex:108`). The field cannot be persisted even if the writer wanted to.

**24. I add a series and give it a total episode count**
- Home → **+** → *Add by hand* → title → tap **Series** → type `7` into **Total episodes** → **Add to library** → open it and check the progress bar.
- **Expect:** a progress bar with a denominator of 7. The note under the field says so by implication: *"Without it a series still tracks, but its progress bar has no denominator."*
- `[!] known broken — the count is discarded too.` `CachedTitle` **does** have `episode_count` (`cached_title.ex:95`) and `create_cache/2` never sets it. So the progress bar has no denominator whether you fill the field or not, and the note beside it is false in the case it exists to describe.

**25. I tap Add to library with nothing typed**
- Home → **+** → *Add by hand* → tap **Add to library** immediately.
- **Expect:** board 155's refusal — *"A title is needed / Kati cannot keep a thing with no name. Nothing was written — this form is still open and your other answers are intact."*
- `[ ] untested — wording differs from the board.` The code refuses correctly and writes nothing (`:462-463`) but says one line: *"A title is the one thing this needs."* The board's two-part shape (name what is missing, then say nothing was written) is what 95 uses everywhere else. Also try a title of **only spaces** — `String.trim` handles it (`:460`, covered by `add_by_hand_test.exs:62`).

**26. I add a title I already have**
- Add `Estuary Nights` by hand. Go back in, add `Estuary Nights` again.
- **Expect:** *"Estuary Nights" is already in your library.*
- `[ ] untested` — this one is properly built: `refusal/2` (`:503-515`) intercepts the constraint's *"Has already been taken"* and rewrites it. Covered by `add_by_hand_test.exs:112`. **The edge to walk:** add it as a **Film**, then try to re-add it as a **Series** — you are refused, and there is no way anywhere in the app to correct the kind. And: a title added from TMDB under `source: :tmdb` does **not** collide with a hand-typed one under `source: :manual`, so the same film can sit on the shelf twice, once from each door.

**27. I start typing and back out without saving**
- Home → **+** → *Add by hand* → type a title, pick Series, type an episode count → tap the **back chevron**.
- **Expect:** nothing written; nothing lost that matters.
- `[ ] untested` — `Pushed`'s `:back` pops with no guard (`pushed.ex:72`). No draft is kept, which is right, but there is no "discard?" prompt either. Confirm the store is untouched.

**28. I switch Film → Series → Film**
- Home → **+** → *Add by hand* → tap **Series**, then **Film**.
- **Expect:** the Total episodes field appears and disappears; anything typed into it is either kept or visibly dropped.
- `[!] known broken — a stale episode count survives the switch, invisibly.` `episodes/1` (`:311`) returns a `Spacer` for `:movie` but `handle_tap` (`:452`) only reassigns `:kind` — `assigns.episodes` keeps whatever was typed. Harmless today only because the value is discarded anyway (scenario 24); it becomes a real defect the moment episode counts are written. `kind_Film` and `status_Not started` are in `@inert_taps` (`screen_tap_sweep_test.exs:289,352`) as the already-selected members of their families.

---

### 155 — Add by hand, resting & refused (`Kati.Screens.AddByHandStates`)

**29. I want to see the form's two states**
- ⚠️ `Settings → Every screen → 155`.
- **Expect:** a reference sheet — resting, refused, and where the button goes.
- `ROUTE MISSING`, and correctly so: it is a picture of two situations, not a situation the app can be in, and `app_reachability_test.exs:106` carries it on the inventory with that reason. **This board is not a page to fix — it is the specification the other three are failing.** It states three decisions: Film is the default (built, `add_by_hand.ex:64`), Year is blank not this year (built, `:65`), and *Add to library goes to the new title's detail screen* (**not** built — scenario 22). Fix 154 against it, then delete 155 from Settings.

---

### 157 — Add by hand, dark (`Kati.Screens.AddByHandDark`)

**30. I open the dark form and try to type in it**
- ⚠️ `Settings → Every screen → 157` → tap the **Title** field → type anything → tap **Add to library**.
- **Expect:** what I typed is saved.
- `[!] known broken — the fields are frozen, and the button writes the fixture.` `AddByHandDark` delegates `content/1` and `handle_tap/2` to `AddByHand` but **defines no `handle_info({:change, …})` clause**, and `Kati.Screens.Pushed` defines none either (`pushed.ex:72-87`: `:tap`/`:tap`/`:kati`/catch-all). Every keystroke falls into the no-op catch-all. The assigns stay at `load/1`'s hardcoded `title: "The Long Hollow", kind: :tv, year: "2024"` (`add_by_hand_dark.ex:37-44`), so **Add to library** writes a real TrackedTitle + CachedTitle called *The Long Hollow* into the user's library, whatever they typed. This is the exact defect `AddByHand`'s own moduledoc says the device test caught on 154 — 157 never got the fix.

**31. I look at the dark board and then go back to the app**
- ⚠️ `Settings → Every screen → 157` → tap **back** → go anywhere.
- **Expect:** the app returns to my chosen theme.
- `[!] known broken — the whole app stays dark.` `load/1` calls `Mob.Theme.set(Kati.Theme.dark())` (`:36`), which is global, and popping does not remount the screen underneath. The moduledoc states this. Reachable only from the gallery, so it is a trap laid specifically for the person walking the gallery.

---

### 156 — افزودن دستی (`Kati.Screens.AddByHandFa`)

**32. I use Kati in Persian and add a title by hand**
- Home → Settings → **Language** → **فارسی** → Home → **+** → tap the *add by hand* row → type a title → **افزودن به کتابخانه**.
- **Expect:** the Persian form, mirrored, and the same row in the store as the English form writes.
- `[ ] untested` — this is genuinely wired and is the one mirror in the app that got routed properly: `AddByHand.for_locale/0` (`add_by_hand.ex:130-135`) forks, and `app_reachability_test.exs:335` lists `{Screens.AddTitle, :add_by_hand}` as a locale fork so both halves are proven. The write goes through `AddByHand.save/1` via `status_english/1` (`add_by_hand_fa.ex:266-271`), so English and Persian cannot disagree about what reaches the store.
- **The edge that matters:** `mount/3` pre-fills `title: "گودال بلند"` and `year: "۱۴۰۳"` (`:58-65`). Unlike 157, `handle_info({:change, …})` **is** defined (`:257`), so typing works — but **if the user taps افزودن به کتابخانه without touching the title field, they add a film called گودال بلند.** A form that opens pre-filled with a fixture is a form that saves a fixture.
- **Second edge:** the year is Persian digits `۱۴۰۳` and Shamsi. It is discarded like the English one (scenario 23), so the Shamsi/Gregorian question the moduledoc raises has no consequence yet — but it will the moment Year is persisted, and there is no converter in the write path.

**33. Back goes the wrong way in the mirror**
- In فارسی, on 156, tap the back chevron at the **top right**.
- **Expect:** back to the search sheet.
- `[ ] untested` — `Fa.pushed_frame/2` owns the `arrow_forward_ios` flip and `handle_info({:tap, :back})` pops (`:261`). Worth one tap to confirm, since this is the commonest RTL bug and the moduledoc claims it is handled.

---

### 18 — Quick add (`Kati.Screens.QuickAdd`)

**34. I use the one-field-for-everything box to add a film**
- Dock **Calendar** → tap the **⋯** in the header → tap **Quick add** → tap the field → type `the long hollow`.
- **Expect:** a text field; the sentence parsed; the **Title** chip files it as a film.
- `[!] known broken — the screen has no text field and no parser.` `mount/3` assigns `Sample.draft()` and nothing else (`quick_add.ex:85`). `field/1` (`:195`) draws the fixed sentence *"dentist thu 11am for 45m, remind 1h before"* as tinted `<Text>` runs — no `<TextField>` anywhere in the file. `Kati.Screens.QuickAdd.Sample`'s own moduledoc says it exists "until a parser exists", and the module moduledoc states outright that `lib/` has none.

**35. I tap the "Title" chip because I want this filed as a film**
- Calendar → **⋯** → **Quick add** → type a film's name → tap the **movie / Title** chip.
- **Expect:** the sentence is filed as a title and lands in the film library.
- `[x] verified on device 7 September.` The chip opens screen 06 with the parsed title already in the field and TMDB's results under it, so adding the film is one more tap. The other four chips set `Kati.Calendars.Event.kind` — Event, Reminder, Habit, Note — and Expense keeps its push to 124. Six chips, six tags, where five answered `nil`.

**36. I tap "Add to Thursday"**
- Calendar → **⋯** → **Quick add** → tap the big **Add to Thursday** button.
- **Expect:** something is written.
- `[!] known broken — the commit button has no tap.` `actions/1` does `tap = Map.get(draft, :on_commit)` (`:534`) and `Sample.draft/0` supplies no `:on_commit` key, so `on_tap` is `nil`. The 52pt primary button on the screen is inert. The **mic** beside it likewise passes no `on_tap` (`:579-589`).

**37. I read the clash warning**
- Calendar → **⋯** → **Quick add**.
- **Expect:** *Clashes with Design review — add anyway?* to reflect my actual calendar.
- `[!] known broken — hardcoded.` `Sample.draft/0`'s `clash:` tuple. It happens to name a seeded event, which makes it read as real on a seeded phone and as a hallucination on a clean install.

**Verdict on 18:** everything on it except *close* and the Expense chip is a drawing. It is reachable, which makes it worse than the gallery-only boards: a person can find it from the Calendar root and conclude the app is broken. Until a parser exists, the honest options are to remove the ⋯ item or to give the screen the empty-state treatment 06 needs.

---

## The shelf, and finding something on it

**Read this first — there are two different searches in this app and nothing tells the user which is which.**

* **`Kati.Screens.Search` (19) / `SearchIdle` (86)** search **only what you have already shelved**. `Kati.Search.Query.run/1` reads `Kati.Media.CachedTitle`, `Kati.Books.Book`, `Kati.Calendars.Event` and `Kati.Books.Note` out of SQLite. It never touches the internet. On a fresh phone it matches nothing, correctly.
* **`Kati.Screens.AddTitle` (06)** searches **TMDB**. That is the only place a new film can come from.

The one sentence that says so is on 19's *nothing found* card — *"Kati only searches what you keep. If it is a title you have not added yet, look it up."* — and the door out of it (`Search TMDB for "x"`) lands on 06, which on the device returns **0 results silently** because `Kati.Media.Tmdb.key/0` reads `TMDB_READ_TOKEN` from the environment and the phone has no such variable. Every scenario below that ends "…and add it" dead-ends there. It is not re-derived per scenario; it is marked `[!] TMDB key`.

---

### 03 — Library (`Kati.Screens.Library`)

**Route:** dock `Library`. Confirmed in routes.txt as a root.

**What it reads:** `shelf/0` — three `TrackedTitle` `:shelf` reads (`:movie`, `:tv`, `:anime`), one `CachedTitle` read keyed by `{source, source_id}`, one `Watch` read for episode ticks. Rows with no cache row are dropped. **No `Sample` fallback** — an empty shelf draws screen 27's *No titles yet* card. This screen is honest about your data. What it is not honest about is what it claims that data can do.

**Controls:** search disc → 19, sort disc → 145, ⋯ disc → menu (*What fits?* / *Filter shelf* / *Select titles*), three segments (Screen / Books / Music), three quick tiles (Up next / Discover / Lists), four chips (All / Watching / Not started / Finished), the grid.

**The four things that break it, all provable from source:**

1. **The shelf is frozen at mount and there is no way to refresh it from this screen.** `load/1` (`library.ex:114`) assigns `titles: titles()`; `Kati.Screens.Root`'s `mount/3` calls `load()` once (`root.ex:167-170`). Mob's `{:pop}` (`deps/mob/lib/mob/screen.ex:571-578`) restores `prev_socket` **verbatim — `mount/3` is not re-run**. And `root.ex:255-257` makes the Library dock tab a deliberate no-op when you are already on Library. So: add a title, come back, and the shelf still says *No titles yet*, and the only cure is to visit another dock root and return.
2. **Nothing in the app can set a film or series status.** `AddTitle.track/2` always writes `status: :watching` (`add_title.ex:487-505`). The only writer of `TrackedTitle.status` afterwards is `Kati.Screens.DropSheet` (`drop_sheet.ex:338,349,356`), which routes.txt lists as **gallery-only**. So **Not started** and **Finished** are permanently `0`, the mono subtitle always reads `N titles · N in progress`, `up_next_badge/1` always equals the shelf size, and four of `tile_meta/1`'s six clauses (`not started`, `finished`, `paused`, `dropped`) are unreachable.
3. **A film's progress rail can never move.** `fraction_for/3` for `:movie` divides `tracked.progress_seconds` by runtime, and `Kati.Media.TrackedTitle`'s own doc says *"nothing writes it yet"* (echoed at `home.ex:116`, `home_dark.ex:684`). Every film draws an empty rail and the mono line `watching`. Series rails do work — `Kati.Screens.Series.write_tick/2` (`series.ex:1295`) creates the `Watch` rows.
4. **The sort disc opens a sheet made entirely of fixtures that cannot touch this shelf.** See 145.

#### Scenarios

**1. I open the Library on a brand-new phone**
Steps: dock → **Library**.
Expect: `Library`, mono `0 titles · 0 in progress`, the three segments, the three quick tiles with **no** badge on Up next, then one card: a `movie` glyph, *No titles yet*, *Add one thing you are watching and the calendar starts filling itself.*, an ink pill **Add a title**, and *or import a backup*. **No filter chips and no grid.**
Status: `[ ] untested`

**2. I add my first film from the empty card**
Steps: dock → **Library** → **Add a title** → type a film → tap it → tap back.
Expect: the shelf now shows one poster, `1 titles · 1 in progress`, chips `All 1 · Watching 1 · Not started 0 · Finished 0`.
Status: `[!] known broken — twice. TMDB returns 0 results with no key, so there is nothing to tap; and even with a key, popping back restores the frozen socket and Library still draws "No titles yet".`

**3. I add a film from Home instead, then go to the Library**
Steps: dock → **Home** → **+** → search → tap a result → back → dock → **Library**.
Expect: the poster is on the shelf.
Status: `[!] known broken — TMDB key. The navigation half is sound: Home → Library is a reset_to, which remounts and re-reads.`

**4. I tap a film on the shelf**
Steps: dock → **Library** → tap a poster.
Expect: Film detail for **that** film, not for whichever film the store returns first.
Status: `[ ] untested` — `poster_tag/1` carries the title and `open_tile/3` resolves it back against the rendered list, so the id is right.

**5. I have two films with the same name**
Steps: shelf two titles that render the same tag (identical titles, or `Low Water` and `Low_Water`).
Expect: two separate tiles, each opening its own row.
Status: `[!] known broken — poster_tag/1 replaces spaces with underscores, so both tiles carry one accessibility_id and open_tile/3 opens whichever comes first.`

**6. I tap the Finished chip**
Steps: dock → **Library** (with films on it) → tap **Finished**.
Expect: either the finished titles, or something that says there are none.
Status: `[!] known broken — Finished is always 0 (nothing writes the status), and shelf_body/3 branches on the shelf being empty rather than on the filter emptying it, so you get live chips over a blank space with no card and no explanation. Same for Not started.`

**7. I tap Watching**
Steps: dock → **Library** → tap **Watching**.
Expect: the grid narrows.
Status: `[ ] untested` — it will show everything, because everything is `:watching`.

**8. I tap the Books segment**
Steps: dock → **Library** → tap **Books**.
Expect: the Books shelf (screen 20), pushed.
Status: `[ ] untested` — wired, and `Kati.ShelfRoutesTest` asserts all six crossings.

**9. I turned the Screen section off in Settings and come back**
Steps: Settings → sections → turn Screen off → dock → **Library**.
Expect: something coherent.
Status: `[?] unknown — kept_segments/1 filters the strip by Kati.Sections.on?/1, but assigns.shelf stays "Screen" and the grid still renders films under a strip that no longer offers Screen.`

**10. I tap the sort disc**
Steps: dock → **Library** → tap the **sort** disc (top right, next to search).
Expect: a sheet whose choices reorder or narrow *my* shelf.
Status: `[!] known broken — opens 145, which is 100% fixture and hands nothing back. See 145.`

**11. I tap ⋯**
Steps: dock → **Library** → tap **⋯**.
Expect: three rows — *What fits?*, *Filter shelf*, *Select titles*.
Status: `[ ] untested` — all three are wired and close the menu before pushing. **Note for routes.txt:** these three (13, 145, 146) show as NOT REACHED because the menu is gated on the `menu?` assign and the route sweep never pressed `:toggle_menu` before re-rendering. They *are* reachable on a device.

**12. I tap Up next / Discover / Lists**
Steps: dock → **Library** → tap each tile.
Expect: 10, 11, 12.
Status: `[ ] untested` — all three push. **Lists never carries a count** (`up_next_badge/1`'s doc: there is no list resource anywhere in `lib/kati`), and Discover never has. Only Up next badges, and its number is the whole shelf (see defect 2).

**13. I add an anime**
Steps: any add path, hoping for an anime shelf entry.
Expect: it lands on the Screen shelf and is identifiable as anime.
Status: `[!] known broken — :anime is a dead kind. AddTitle.kind_of/1 only ever answers :movie or :tv; nothing anywhere writes :anime. shelf/0 queries for it and always gets zero rows. And shaped/3 collapses every non-:movie kind to :series, so if an anime film ever existed its tile would open the Series detail screen.`

**14. I delete a film on the detail screen and come back**
Steps: **Library** → tap a poster → untrack → back.
Expect: the tile is gone.
Status: `[!] known broken — same frozen-socket defect as scenario 2; the tile stays until the root is remounted.`

**15. The Library after the cache is evicted**
Steps: shelf a TMDB title, let its `CachedTitle` be evicted.
Expect: something honest.
Status: `[ ] untested` — `shelf/0` **drops** rows with no cache row (`Enum.reject(&is_nil(&1.title))`). The tracked row survives and reappears on re-fetch, but in the meantime the title has silently vanished from the shelf and from the counts, with nothing saying why.

---

### 145 — Shelf filter sheet (`Kati.Screens.ShelfFilters`)

**Route:** Library → **sort** disc, and Library → ⋯ → **Filter shelf**. (Also from Books 20, Music 21, and their Persian mirrors — all four push it bare.)

**This screen cannot work, by construction.** Every number on it is `Kati.Library.ShelfFiltersSample`: `total/0` is `418`, the decade counts are `24/38/11/6`, ratings `31/52/9`, genres `41/12/8/0`, services `22/7/3/2`. `mount/3` takes `_params` — there is no way to tell it which shelf opened it — and it returns nothing: `close` is `pop_screen/1`, and board 145 draws **no Apply** (grep of `145.html`: one `Reset`, one `close`). `Kati.Screens.Library`'s own comment at `library.ex:1266` admits this in as many words.

It also **opens pre-filtered**: `mount/3` assigns `decade_2020s`, `rating_4`, `genre_anime` and the literal `showing: 41`.

#### Scenarios

**16. I tap sort on a shelf holding two films**
Steps: dock → **Library** → **sort**.
Expect: sort options for my two films, and a count of two.
Status: `[!] known broken — the sheet opens announcing "showing 41 of 418", with 2020s, 4★ and up and Anime already lit, on a shelf of two.`

**17. I pick "Title" as my sort and close the sheet**
Steps: **Library** → **sort** → tap **Title** → tap **close**.
Expect: the grid on 03 reorders alphabetically.
Status: `[!] known broken — the sort lives in this sheet's assigns and dies with it. Nothing is written, nothing is passed back, and 03 re-renders from its frozen titles list.`

**18. I tap Title twice to flip the direction**
Steps: **Library** → **sort** → **Title** → **Title**.
Expect: the pill flips DESC → ASC and the arrow turns.
Status: `[ ] untested` — `apply_sort/2` does exactly this, and `direction_pill/1` rotates the one `arrow_downward` glyph 180°. It is the only control on the page that behaves correctly, and it still changes nothing outside the sheet.

**19. I clear every filter**
Steps: **Library** → **sort** → tap **2020s**, **4★ and up** and **Anime** to unselect → read the count.
Expect: `showing 2 of 2`.
Status: `[!] known broken — reads "showing 418 of 418".`

**20. I tap Comedy, which says 0**
Steps: **Library** → **sort** → tap **Comedy**.
Expect: an empty shelf, and the chip warned me.
Status: `[?] unknown — the chip's hairline-grey 0 is a nice piece of design (facet_chip/4's fourth colour), and it is warning about a shelf it is not connected to. recompute/1 will answer `showing 0 of 418`.`

**21. I go looking for the filter disc 145 says it hangs off**
Steps: dock → **Library** → look at the header.
Expect: a trailing **tune** disc, per 145's caption *"a trailing filter disc in the header of screens 03, 20 and 21"*.
Status: `[!] known broken — board 03.html draws exactly two glyphs, "search" and "sort". No board of the three has the disc. The ⋯ menu row is a placeholder Library's own moduledoc calls one.`

---

### 146 — Shelf, selection mode (`Kati.Screens.ShelfSelection`)

**Route:** Library → ⋯ → **Select titles**. (routes.txt says NOT REACHED — that is the assign-gated menu, see scenario 11. It is genuinely reachable.) The gesture the board actually specifies is a **long press on a poster tile**, and no board draws it.

**This screen cannot work either.** `load/1` assigns `Kati.Library.Sample.selection_shelf/0` — a fixture. Selecting, `Status`, `Remove` and `Undo` all mutate assigns; **no `Ash` call appears anywhere in the file**. And the page carries three *stills* of states it is not in, which a user has no way to tell apart from live controls except that they do not respond.

#### Scenarios

**22. I open selection mode to tidy my shelf**
Steps: dock → **Library** → **⋯** → **Select titles**.
Expect: my own posters, selectable.
Status: `[!] known broken — you get five fixture titles (The Long Hollow, Salt & Iron, Nightbirds and two more added to reach the board's "4 selected"), one of them already selected, above a still of a header reading "41 OF 418 · RECENTLY ADDED" and a dark pill claiming "Removed 4 titles" that has removed nothing.`

**23. I select one title and tap Status**
Steps: … → tap one poster → tap **Status**.
Expect: a status picker, or at minimum a persisted status change.
Status: `[!] known broken — change_status/2 flips a done? flag on a fixture map. The board draws no picker (that is 148's subject) and the moduledoc calls this "the smallest real state change the pill can make". Nothing reaches the store; nothing survives close.`

**24. I select four titles and tap Remove**
Steps: … → tap four posters → tap **Remove**.
Expect: four titles leave my library; an undo bar appears.
Status: `[!] known broken — remove_selected splits an assign list. Tap close and reopen: all five are back.`

**25. I remove, then change my mind**
Steps: … → **Remove** → **Undo**.
Expect: the four come back, still selected.
Status: `[ ] untested` — this round-trip does work within the assigns, and is the one loop on the page that is complete.

**26. I select more than ten**
Steps: … → select eleven posters.
Expect: the actions collapse behind an overflow disc (146's own caption).
Status: `[!] known broken — actions/2 still lays out the two-pill row past ten; the moduledoc defers the rule to 147, which is a picture.`

**27. I tap Add to list with two titles selected**
Steps: … → select two → **Add to list**.
Expect: a list picker; the two titles land in a list.
Status: `[!] known broken — pushes Kati.Screens.Lists (12) and drops the selection on the floor. There is no list resource in lib/kati at all, so nothing could be written.`

---

### 147 — Selection & filters at 235% (`Kati.Screens.ShelfLarge`)

**Route: NONE.** ⚠️ `Settings → Every screen → 147`. Its own back pill reads `Library` and no control on 03 opens it.

A specimen, and it says so: `@selected_count` is `4`, `@chip_label` is `"Comedy"`, every `sp` is the drawing's 235% figure typed out, and `Kati.Screens.Pushed` defines no `handle_tap/2` so nothing on it taps. Its value is as a check that `4 selected` and the zero-result card do not clip — which nobody will ever perform, because it is not on a route.

**28. I want to see what selection mode does at 235% text**
Steps: ⚠️ `Settings → Every screen → 147` — `ROUTE MISSING`.
Expect: nothing to tap; three 56pt action rows, a `Drop the Comedy chip` pill, a zero-result card, none of them live.
Status: `[ ] untested` — behaves as documented. The finding is that it is a private reference sheet shipped inside the app, and 146's real 235% behaviour is untested because 146 itself is fixtures.

---

### 152 — Anime, a type not a section (`Kati.Screens.AnimeFilter`)

**Route: NONE.** ⚠️ `Settings → Every screen → 152`. Its back pill reads `Settings` and no row in Settings opens it.

It is not a filter sheet; it is the **argument** for one, drawn. It reads `Kati.Media.AnimeSample` throughout and writes nothing. What it proposes needs a per-title anime override column, and `Kati.Media.TrackedTitle` has no such attribute (`tracked_title.ex:81-157` — `kind` is a one-of constraint, not an override). Since `:anime` is a kind nothing writes (03, defect 2), the whole subject is unreachable in the running app.

Two of its controls are in `ScreenTapSweepTest`'s `@inert_taps` with the test's own stated reason: *"`load/1` opens screen 152 on `onboarding_pick: "Screen"` and `watches_anime?: true`, so `:pick_screen` and `:watches_yes` write the values already there while `:pick_books` and `:watches_no` move the screen."* — the resting members of two live families, which is honest.

**29. I want to mark a title as anime**
Steps: ⚠️ `Settings → Every screen → 152` → tap **Not anime** on the Marram card — `ROUTE MISSING`.
Expect: a per-title override that beats every guess (the board's Rule 1).
Status: `[!] known broken — :marram_fixed? is an assign on a sample row. No column, no writer, and the card is about a title that is not on your shelf.`

**30. I have ten anime and expect the fourth tab chip**
Steps: ⚠️ `152` → read the tab row.
Expect: a fourth **Anime** chip once the count clears the threshold.
Status: `[!] known broken — promote?/2 does compute this correctly against Kati.Media.AnimeSample's 12, but the tab row it appends to is this board's picture. Screen 03's real chip row is All / Watching / Not started / Finished and has no fifth clause.`

---

### 19 — Search (`Kati.Screens.Search`) — the results page

**Routes:** Library → **search** disc (pushes with `query: ""`, `back: "Library"`, so it opens idle), and Home → search field → 86 → keyboard **search** key / a recent row / a suggestion.

**What it reads:** `Kati.Search.Query.run/1` — `CachedTitle` + `Books.Book` (merged into the **Screen** group), `Calendars.Event`, `Books.Note`. Three groups. Empty groups are omitted, not worded. `handle_info({:change, :query, typed})` re-runs on **every keystroke**, no debounce, and calls `Kati.Search.Recent.remember/1` — there is no submit here, which `Kati.Screens.SearchIdle` explains: `mob_send_submit/1` sends `{:submit, tag}` where a tap sends `{:tap, tag}`, so a keyboard action is invisible to `ScreenTapSweepTest` by construction.

**What is wrong with it:**

* **Books are drawn under the heading `SCREEN`.** `titles_for/1` (`query.ex:104-110`) concatenates `books_for/1` into the same list `visible_groups/2` labels `"Screen"`, and `chip_counts/1` counts them there. Searching `Estuary` puts a book card, sub `Book · Ines Karvel`, under an orange `SCREEN` eyebrow — and its chevron opens nothing, because `hit_tag/1` answers `nil` for `:book`.
* **Results are silently capped at three per group, and the chips agree with the cap rather than the truth.** `titles_for/1` and `calendar_for/1` both `Enum.take(rows_per_group())` (3) **before** `chip_counts/1` counts them. Ten matching films render three and the chip says `3`. `Kati.Search.rows_per_group/0`'s own doc is *"How many rows a group shows before its `See all` row"*, and screen 88 prints *"Then a 'See all 12 →' row"* — **there is no `See all` anywhere in `lib/kati/screens/search*.ex`.** The other seven results are unreachable.
* **Your review of a film is not searchable.** `Kati.Search`'s `@scopes` promises the Screen scope searches *title, original title, alt titles, cast, your tags, your review*. `cached_for/1` passes `tier(query, title, overview)` — **only title and overview**. The Notes group reads `Kati.Books.Note` and nothing else, while a film review lives on `Kati.Media.Watch.review` (written by screen 33). So the one place in the app that holds your own words about a film is invisible to the search screen whose Notes group claims to hold it.
* **The note highlight is offset against the wrong string.** `note_card/2` computes `:binary.match(normalise(body), normalise(query))` and then slices with `binary_part(body, at, len)` — offsets from the *normalised* body applied to the *raw* one. `normalise/1` trims, collapses runs of whitespace, strips ZWNJ and harakat and downcases. A note beginning with two spaces shifts every offset by two: body `"  The hollow ground"`, query `hollow` → lead `"  Th"`, highlighted `"e ho"`, tail `"llow ground"`. Persian notes with ZWNJ are worse. When downcasing lengthens (`İ`), `binary_part/3` raises and `note_for/1`'s `rescue` swallows the whole Notes group.
* **The note eyebrow loses two thirds of itself.** Board 19 draws `NOTE · 6 AUG · THE LONG HOLLOW`; `note_card/2` emits `eyebrow: "NOTE"`.
* **The idle page prints a paragraph about a debounce this screen does not have.** `waiting/1` renders `Kati.Search.counts_note/0` — *"Keystrokes debounce at 180 ms, so one pause costs seven counted queries"* — on a screen that runs on every keystroke and draws four chips.
* `{Kati.Screens.Search, :clear}` is in `@inert_taps`, with the test's own reason: *"the field it empties is already empty on a bare mount"*. On a device with a query typed, it works.

#### Scenarios

**31. I search with nothing shelved**
Steps: dock → **Library** → **search** disc → type `hollow`.
Expect: *Nothing here for "hollow"* — the glyph card, *Kati only searches what you keep…*, an ink pill **Search TMDB for "hollow"**, and *or add it by hand*.
Status: `[ ] untested` — this path is correct and is the best-behaved thing in the group.

**32. I take the "Search TMDB" pill out of that dead end**
Steps: … → tap **Search TMDB for "hollow"**.
Expect: screen 06 already searching for `hollow`, with results.
Status: `[!] known broken — TMDB key. hand_over/1 carries the query correctly, 06 opens on it, and returns zero results with no message; Kati.Media.Tmdb.message(:no_api_key) is composed and never drawn.`

**33. I take "or add it by hand" instead**
Steps: … → tap **or add it by hand**.
Expect: screen 154, prefilled with `hollow`.
Status: `[?] unknown — pushes AddByHand.for_locale() with no params, so the query is dropped and you retype the word the app just showed you.`

**34. I search for a film I have shelved**
Steps: shelf a film → dock → **Library** → **search** → type its name.
Expect: an orange `SCREEN` eyebrow, one card with poster, title, `Film`, and a chevron that opens the Film detail for that row.
Status: `[ ] untested` — `title_row/1` + `open_hit/3` resolve the id through `tracked_ids/0`'s `:shelf` read, so an archived title is correctly not opened.

**35. I search a film that is in the cache but not on my shelf**
Steps: look a title up on 06 without adding it, then search for it on 19.
Expect: it either does not appear, or appears and is clearly not shelved.
Status: `[!] known broken — it appears as a full hit card with a chevron, indistinguishable from a shelved one, and the chevron does nothing (open_hit/3 pushes with no params on a nil id).`

**36. I type one character**
Steps: **search** → type `h`.
Expect: the idle state, not a "nothing found".
Status: `[ ] untested` — `long_enough?/1` gates at 2 Latin characters and `:idle?` distinguishes waiting from having looked. Correct, and the reason it is correct is the one design decision in this group I would not touch.

**37. I type one Persian character**
Steps: **search** → type `ه`.
Expect: it runs — one character is a word in that script.
Status: `[ ] untested` — `minimum/1` measures the *query*, not the locale.

**38. I clear the field**
Steps: **search** → type `hollow` → tap the **⊗** disc.
Expect: back to idle, with my recent shelf under it.
Status: `[ ] untested` — the assign resets and `run("")` answers idle. Note the recent shelf still holds `hollow`, which is right.

**39. I tap the Calendar chip**
Steps: **search** → type a word that matches a title and an event → tap **Calendar**.
Expect: only the Calendar group, with its eyebrow now orange (the accent dash is positional).
Status: `[ ] untested`

**40. I tap a chip whose group is empty**
Steps: **search** → type a word matching only a title → tap **Notes**.
Expect: the *nothing found* card, or something saying the match is elsewhere.
Status: `[?] unknown — visible_groups/2 filters to Notes, rejects it as blank, and state_or_groups/2 falls to no_matches/1 — so you get "Nothing here for 'hollow'" over a query that found a film. Board 89's third band draws the correct answer for this (the cross-scope card) and screen 19 does not use it.`

**41. I search and ten films match**
Steps: shelf ten films sharing a word → search that word.
Expect: ten, or three and a *See all 10 →*.
Status: `[!] known broken — three, and the chip says 3. The other seven cannot be reached from this screen at all.`

**42. I search for a book**
Steps: shelf a book → dock → **Library** → **search** → type the author's name.
Expect: a Books group, or at minimum not a Screen group.
Status: `[!] known broken — the book renders under the eyebrow SCREEN, counted by the Screen chip, with a chevron that goes nowhere.`

**43. I search for a note I wrote about a film**
Steps: rate a film on screen 33, write a review, then search a word from it.
Expect: the Notes group, quoting my review with the word highlighted.
Status: `[!] known broken — the Notes group only reads Kati.Books.Note. A film review on Kati.Media.Watch.review is unfindable, which is the exact defect Kati.Screens.Search's own moduledoc says it is waiting to fix.`

**44. My note starts with a space, or is Persian**
Steps: write a book note beginning `"  The hollow ground"` → search `hollow`.
Expect: `…the` **hollow** `ground`.
Status: `[!] known broken — highlights "e ho". Offsets are computed on the normalised body and sliced out of the raw one.`

**45. I tap a recent query on the results page**
Steps: **search** → run two different queries → tap the first one in the **Recent** shelf.
Expect: the field and the hits both move to it, and the chip fills.
Status: `[ ] untested` — `"recent_" <> label` re-runs, re-remembers and lights the chip. Correct.

**46. I search for something with an underscore in it**
Steps: **search** → run `sci_fi` → tap it in the Recent shelf.
Expect: `sci_fi` again.
Status: `[!] known broken on 86's copy of the shelf — SearchIdle.open/2 does String.replace(line, "_", " ") to undo query_tag/2, so it opens on "sci fi". 19's own shelf carries the label whole and is fine.`

**47. I search with no network**
Steps: aeroplane mode → **search** → type a shelved title.
Expect: full results — this search is local.
Status: `[ ] untested` — correct by construction, and worth confirming so the *nothing found* card's TMDB pill is the only thing that fails offline.

---

### 86 — Search, idle (`Kati.Screens.SearchIdle`)

**Route:** dock **Home** → the search field (`home.ex:1362`). This is the door most users take; Library's disc skips it and lands on 19.

Eight scope chips (`All` + `Kati.Search.scopes/0`), a `tune` disc → 88, the last eight queries from `Kati.Search.Recent` (`Mob.State`, deliberately not in `kati.db` so a restored backup cannot hand you somebody else's history), a **Clear** control on the eyebrow, and two fixed suggestions.

**The defect that matters:** the scope rides across and is then silently discarded. 86 offers eight chips; 19 can only build three groups. `Kati.Search.narrowable/1` maps `Books`, `Music`, `Meals` and `Money` to `"All"` — the honest degradation, and the module argues for it well — but **nothing tells the user their choice was dropped**. You pick `Books`, press search, and land on a page lit `All`.

**48. I search from Home for the first time**
Steps: dock → **Home** → tap the search field.
Expect: an empty field, eight chips with no numbers, `Recent · last 8` over a *Nothing searched yet* card, two `Try` rows, and the counts footnote.
Status: `[ ] untested` — `recent/1` words the empty history rather than hiding the section, which is right.

**49. I type a title and press the keyboard's search key**
Steps: **Home** → search field → type → press **search** on the keyboard.
Expect: screen 19, on that query, with the query in the Recent shelf.
Status: `[ ] untested` — this is the one submit path in the codebase and it is easy to break: `look/1` is reached by `handle_info({:submit, :look})`, not by any `handle_tap`, so `ScreenTapSweepTest` cannot see it. **If you change `handle_info/2` here, re-test this by hand — a single new clause replaces all four of `Kati.Screens.Pushed`'s and silently kills both the back pill and the `tune` disc.**

**50. I pick the Books scope and then search**
Steps: **Home** → search → tap **Books** → type → press search.
Expect: results narrowed to books.
Status: `[!] known broken — narrowable/1 downgrades Books to All and the chip on 19 lights All, with no message. You get everything, and no way to tell whether the app ignored you or you have no books.`

**51. I tap a recent query**
Steps: **Home** → search → tap a row under **Recent**.
Expect: 19, on that query.
Status: `[ ] untested` — see scenario 46 for the underscore round-trip.

**52. I tap Clear**
Steps: **Home** → search → tap **Clear** on the Recent eyebrow.
Expect: the card gives way to *Nothing searched yet*.
Status: `[ ] untested` — `clear_recent` forgets and re-assigns `:history`, which is exactly right; the moduledoc explains that forgetting without the re-assign would leave eight rows under a heading that says they are gone.

**53. I tap one of the two Try suggestions**
Steps: **Home** → search → tap *what leaves this week*.
Expect: results for it.
Status: `[!] known broken — Kati.Search.suggestions/0 is two fixed strings, and its own doc says so: "drawn from your own library" is the design's rule and nothing derives them. Tapping one runs a query that will match nothing on almost any device.`

**54. I type a whole word letter by letter and check my history**
Steps: **Home** → search → type `Ashfall` → search → back → look at Recent.
Expect: one entry, `Ashfall`.
Status: `[ ] untested` — `Recent.passed_through?/2` drops prefixes the new query was typed through, and keeps a genuinely shorter later search. This is well built.

**55. I tap the tune disc**
Steps: **Home** → search → tap the **tune** disc.
Expect: 88, and a back pill that names where I came from.
Status: `[!] known broken (cosmetic) — 88's pill reads "Settings" (use Kati.Screens.Pushed, back: "Settings") but pops back to 86. This is the only route into 88.`

---

### 87 — Search, typing (`Kati.Screens.SearchTyping`)

**Route: NONE.** ⚠️ `Settings → Every screen → 87`. Back pill `Home`.

A reference sheet of the three states between 86 and 19 — first-run idle, one character under the minimum, and searching — drawn all at once, which is a combination no device is ever in. Its debounce strip is real arithmetic off `Kati.Search.debounce_ms/0` (130/180 = 72%). It reads no store and only its reused chip row taps.

**One thing on it is load-bearing elsewhere:** `nothing_yet/0` is the *Nothing searched yet* card that 86 and 19 both render for an empty history. That is fine, and it is the reason 87 must not be deleted along with the gallery.

**56. I want to see why the field feels calm**
Steps: ⚠️ `Settings → Every screen → 87` — `ROUTE MISSING`.
Expect: three fields, a six-cell keystroke strip with one ink cell, a bar at 72% and `180 ms` under it.
Status: `[ ] untested` — behaves as documented. Note the debounce it documents **is not implemented** on 19 (see 19's defect list), so this sheet asserts by drawing something the app does not do.

**57. I tap a scope chip on 87**
Steps: ⚠️ `87` → tap **Calendar**.
Expect: the chip lights, and nothing else changes.
Status: `[ ] untested` — deliberate: the rows underneath stay a skeleton whatever scope is picked. `handle_tap/2` has no catch-all on purpose, so any non-scope tag is reported dead rather than swallowed.

---

### 89 — Search, result states (`Kati.Screens.SearchResultStates`)

**Route: NONE.** ⚠️ `Settings → Every screen → 89`. Back pill `Settings` — and no Settings row opens it.

Four bands: a scope with nothing in it, a query that matched nowhere, a hit that is in another scope, and offline. Nothing on the sheet taps.

**Its `nothing/2` card is the live *nothing found* card on screen 19**, wired with two real taps — so this file is not dead code even though the sheet is unreachable.

**58. I want to check the seven-zeroes state does not read as a broken index**
Steps: ⚠️ `Settings → Every screen → 89` — `ROUTE MISSING`.
Expect: eight chips, seven at `0` in hairline grey, `Meals` lit at 3.
Status: `[ ] untested` — correct as drawn.

**59. The band screen 19 should be using and is not**
Steps: ⚠️ `89` → third band, *nothing in the lit scope, three matches in another*.
Expect: a card offering the move to the scope that has the answer.
Status: `[!] known broken as a product gap — screen 19 has no equivalent. Narrowing to an empty scope on 19 draws the "matched nothing" card instead (scenario 40), which is the misreading this band was drawn to prevent.`

---

### 91 — Search at 235% (`Kati.Screens.SearchLarge`)

**Route: NONE.** ⚠️ `Settings → Every screen → 91`. Back pill `Home`.

A specimen. Its argument is worth keeping: `Kati.Screens.Search.title_row/1` is a `Row` with `max_lines={1}` on both text nodes, so **at 235% a real search result on screen 19 stops showing the words** — 91 draws what it should become instead (a stacked card, no `max_lines`, chips wrapped three to a row rather than horizontally scrolled). It is a correct diagnosis of a live defect on 19, published as a picture and never applied to 19.

**60. I run the phone at 235% text and search**
Steps: Android Settings → font size max → dock → **Library** → **search** → type a long title.
Expect: the title readable.
Status: `[!] known broken — 19's hit row clips. The fix is drawn on 91 and lives only there.`

**61. I look at the scope chips at 235%**
Steps: same, on screen 86.
Expect: all eight scopes findable.
Status: `[!] known broken — SearchIdle.chips/1 is a horizontal Scroll; at 235% half the scopes are behind a gesture. 91's own moduledoc names this as the one builder it exists to contradict.`

---

### 88 — Scope & ranking (`Kati.Screens.SearchSpec`)

**Route:** Home → search field → **tune** disc. Reachable, and confirmed in routes.txt.

This is a **specification rendered from `Kati.Search`** — the fields per scope, the four tiers, the fixed group order, the three-rows cap, the Persian normalisation table. `handle_tap(_tag, socket)` answers everything with silence, so nothing on it is a control.

The problem is that the contract it renders is not the contract the build honours:

* It lists the Screen scope as searching *original title, alt titles, cast, your tags, your review*. `Kati.Search.Query.cached_for/1` searches **title and overview**. Five of six fields on the page are not searched.
* It lists Books, Music, Meals and Money as scopes. `Query.run/1` builds three groups and Books is merged into Screen; Music, Meals and Money are searched by nothing at all.
* It says ties break by **recency**. `Kati.Search.rank/1` implements that and **is never called** — `titles_for/1` and `calendar_for/1` sort by `{tier, title}`.
* It prints *"Then a 'See all 12 →' row"*. There is no such row on 19.
* It says Calendar searches *location*. `calendar_for/1` passes `tier(query, summary, description)` — the location field is not read.

**62. I open the spec to find out what search will look at**
Steps: dock → **Home** → search field → **tune** disc.
Expect: an accurate contract.
Status: `[!] known broken — of the seven scopes it names, three exist; of the six Screen fields it names, one is searched. Everything on it is read out of Kati.Search, so the page and the constant agree; the constant and Kati.Search.Query do not.`

**63. I check the Persian normalisation table is real**
Steps: … → scroll to **Persian normalisation** → then search `ي` for a title spelled with `ی`.
Expect: it matches.
Status: `[ ] untested` — `Kati.Search.normalise/1` implements every row of the table and `tier/3` folds both sides. This half of the spec is genuinely honoured.

**64. The back pill**
Steps: … → tap the back pill.
Expect: it names 86.
Status: `[!] known broken (cosmetic) — reads "Settings".`

---

## One film — 08, 33, 148, 149, 15

The question this group exists to answer is *can a person record that they watched a film, rate it, write a note about it, and see it again afterwards?* The answer, from the source, is **no**, and it fails at the first step for a reason that is one line long:

> `Kati.Media.Watch` is created in exactly ONE place in the whole app — `Kati.Screens.Series.write_tick/2` (`lib/kati/screens/series.ex:1309`), which requires an `episode_source_id`. There is no other `Ash.create`/`for_create` against `Watch` anywhere in `lib/`.

A film has no episodes. So **no title-level watch row can ever come into existence on a device**, and everything downstream of one is unreachable in practice: screen 08's watched pill, its `Seen n times`, its note card, screen 33's Save, and every film row on screen 15. Screen 33 is an *editor* by design (`rating.ex:1487` — `save_watch(%{watch_id: nil})` returns `{:error, :nothing_to_save}`); it can only ever write back onto a watch something else made, and nothing makes one.

A second, independent break sits beside it: screen 08's `Your rating` stars read **`TrackedTitle.rating`** (`film.ex:235`), and screen 33 saves to **`Watch.rating`** (`rating.ex:1493`). They are different columns on different tables. `TrackedTitle.rating` has **no writer anywhere in the app** — grep for `Ash.update`/`for_update` across `lib/kati/screens/` returns twenty call sites and not one of them touches it. So even if a watch existed and were rated, screen 08's card would still draw five empty stars.

And a third, which colours every "press back and look" step below: **a popped-to screen never re-reads.** `deps/mob/lib/mob/screen.ex:571` answers `{:pop}` by restoring the *saved socket*; `mount/3` and `load/1` do not run again. Save on 33 pops to 08 — 08 shows exactly what it showed before the save. You must leave the stack (switch dock root) and come back to see any write.

### Getting a film onto the shelf at all — read this before scenario 1

TMDB search returns nothing on the phone (`Tmdb.key/0` reads `TMDB_READ_TOKEN`, absent on device → `{:error, :no_api_key}`), and screen 06 clears its results list when that happens (`add_title.ex:277-281`). But `add_title.ex:228` says a query of **fewer than 3 characters** puts `Kati.Library.Sample.search_results/0` on the socket — four fixture rows, one of which is `Quiet Earth`, and their `+` buttons write real rows (`add_title.ex:503`: `Ash.create(TrackedTitle, %{source: :manual, source_id: title, kind: kind, status: :watching})`).

**So the only way to get a film into the library today is: Home → + → type `qu` (two letters, no more) → tap `+` on `Quiet Earth`.** That is how the route sweep's `open_film_Quiet_Earth` tag came to exist. Do that first; every scenario below assumes it, and says so when it does not.

That film's cached row carries a title and nothing else (`add_title.ex:546-562` sets `source, source_id, kind, title, fetched_at` only), so on screen 08 it has no runtime, no genres, and no poster.

---

### 08 — Film detail (`Kati.Screens.Film`)

**Reachable.** Library (dock) → tap a film poster. `library.ex:1299` routes `open_film_*` through `open_tile/3`, which pushes `%{id: id}` when the row has one (`library.ex:1044-1048`). Confirmed in routes.txt: `Library > open_film_Quiet_Earth`.

**What it draws.** `film/0` = `tracked_film(id) || drawn_film()`, all-or-nothing (`film.ex:117`). With no tracked film — or with a poster tile that has no id — the whole page is `Kati.Library.Sample.film/0`: **Blue Hour**, `2025 · 1H 52M · DRAMA`, `Watched 12 Aug`, four gold stars, `2 times`, a note about the Rex, and a `Where to watch` card quoting **Lumen+ · included** and **Kino store · £9.99**.

**Live controls: three.** `:back`, `:toggle_menu`, and `:log_watch` (the one row in the ⋯ menu, `film.ex:617`). Everything else on the board is paint.

---

**1. I open a film from my shelf and it is somebody else's film**
Home → Library → tap the poster captioned **Harbour** (or any tile, on a phone with nothing tracked).
*Expect:* screen 08 titled `Harbour`.
*What happens:* `Kati.Library.Sample.titles/0` (`library/sample.ex:23-33`) carries no `id` key, so `open_tile/3` pushes **bare**; `film/0` with no id calls `newest_film/0`, finds nothing, and falls through to `drawn_film/0`. You get a page titled **Blue Hour** with a stranger's note on it.
**Status:** `[!] known broken — every untracked shelf tile opens the same fixture film, whatever it was captioned.`

**2. I open the film I actually added**
Home → + → type `qu` → tap `+` beside **Quiet Earth** → back → Library → tap the **Quiet Earth** tile.
*Expect:* title `Quiet Earth`; a meta line; a poster; `Your rating` empty; `Seen never`; no watched pill; no note; no Where-to-watch card.
*What actually renders:* title correct, **meta line empty** (no `runtime_minutes`, no `genres`), **hero is a flat grey 330pt rectangle** (`seed_of/2` answers `Kati.Seeds.sample_seed("Quiet Earth")` → `nil` → `Images.poster(nil)` → `nil` → `hero_art` draws a zero Spacer), five empty stars, `never`. That is the honest state and it is correct — note it as the baseline, not a bug.
**Status:** `[ ] untested`

**3. I tap "Log rewatch"**
On screen 08, tap the **Log rewatch** button in the row of three under the note.
*Expect:* a watch row, or the rating sheet.
*What happens:* nothing at all. `Film.action/2` (`film.ex:880`) builds the button with **no `on_tap` prop**. It carries no tag, so it does not even reach `handle_info/2` — which is why it is absent from `@inert_taps` (that list only records controls that *do* reach a handler). The same is true of **Schedule** and **Share**.
**Status:** `[!] known broken — the three action buttons have no tap tag; film.ex:880 draws a Box with no on_tap.`

**4. I tap the pencil on my note to fix a typo**
On screen 08 (fixture state, since a real note is impossible — see scenario 6), tap the ✎ at the right of the cream note card.
*Expect:* the review becomes editable.
*What happens:* nothing. `film.ex:724` is a bare `Kati.UI.symbol("edit", …)` — a glyph, not a control.
**Status:** `[!] known broken — the note's edit affordance is a painted glyph with no tap.`

**5. I tap my own star rating to change it**
On screen 08, tap the third star in the `Your rating` card.
*Expect:* the rating moves, or the rating sheet opens.
*What happens:* nothing. `rating_card/1` (`film.ex:628`) and `stars/1` draw no taps at all. The only door to a rating is ⋯ → Log a watch.
**Status:** `[!] known broken — the rating card is not tappable; the ⋯ menu is the only route to 33.`

**6. I mark the film watched — the whole point of the screen**
On screen 08 for **Quiet Earth**, tap ⋯ → **Log a watch** → set 4 stars → type a review → **Save**.
*Expect:* a `media_watches` row against Quiet Earth; back on 08 a green `Watched <today>` pill, `Seen 1 time`, four stars, and the note on cream.
*What happens:* `:log_watch` (`film.ex:923`) pushes 33 with `%{tracked_title_id: <id>}`. 33's `mount` runs `newest_log(title_id)`, which filters `not is_nil(rating) or (not is_nil(review) and review != "")` (`rating.ex:381`). Quiet Earth has no watches, so it answers `nil`, the sheet falls back to `Kati.Rating.Sample` — **the sheet opens on "Blue Hour"** — and `watch_id` is `nil`. Save answers `{:error, :nothing_to_save}` and prints **"Nothing to save yet."** under the header. Nothing is written, ever.
**Status:** `[!] known broken — no code path in the app creates a title-level Watch; marking a film watched is impossible.`

**7. I use the app for a month and check "Seen"**
Any film, any time.
*Expect:* `Seen 2 times` after two watches.
*What happens:* `seen_line/1` (`film.ex:315`) reads `length(watches)` and `rewatch_number`, both of which can only be non-zero for episode rows. A film's card reads **`never`** permanently.
**Status:** `[!] known broken — downstream of scenario 6.`

**8. I look at where I can stream this**
Screen 08 on a real film.
*Expect:* nothing, honestly — Kati holds no offers.
*What happens:* correct on a real film (`where: []` at `film.ex:239` drops the eyebrow and the card). But on the *fixture* page every user sees on a fresh install (scenario 1), the app prints **`Kino store · £9.99`** as if it were a real price for a real film.
**Status:** `[!] known broken — the fallback quotes a fabricated price to a real user.`

**9. I delete the film from the shelf while its detail page is open, then press back and reopen it**
Add Quiet Earth, open 08, press back, Home → + → type `qu` → tap the row again to untrack, back → Library → tap the tile.
*Expect:* an honest "that's gone" or the empty shelf.
*What happens:* the tile is gone from the grid, so there is no tap. If you had arrived by id and the row vanished, `film_record/1` (`film.ex:161`) answers `nil` and the page becomes **Blue Hour** rather than saying the film is gone. This is the documented `BookDetail` rule applied one step too late — the fallback is a *different film*, not an empty state.
**Status:** `[?] unknown — needs the device to confirm the ordering; the code path is film.ex:161 → drawn_film/0.`

---

### 33 — Rating (`Kati.Screens.Rating`)

**Reachable, seven doors, and only one of them says which title.** `Kati.Screens.Film` is the only caller that passes params (`Film.handle_info({:tap, :log_watch})` → `Rating.params_for/1`). The other six push it **bare**: `book_detail.ex:1090` and `:1119`, `book_detail_dark.ex:595` and `:611`, `book_detail_fa.ex:1588` and `:1646`, `album_detail_fa.ex:1006`, `log_progress.ex:653`. routes.txt reached it by the book route only (`Library > shelf_Books > open_book > rate`); the film route exists in code but the sweep did not follow it, because `:log_watch` is only drawn once `:toggle_menu` has fired.

**What it draws.** All-or-nothing again. `newest_log/1` (`rating.ex:379`) wants the newest watch carrying a rating or a non-blank review; anything else → `Kati.Rating.Sample` — "Blue Hour", 4.5 stars, a written review, three context rows, three tags.

**Live controls: thirteen.** `:close`, `:save`, the ten half-star targets `:star_1`..`:star_10`, and the review `TextField`. `:add_tag` is drawn and dead (`@inert_taps`, `screen_tap_sweep_test.exs:797`, filed under **Backlog** — "a sheet that never opens"). `:star_9` is also in the list (`:413`) but for the harmless reason: it is the point the fixture's 4.5 already sits on.

**10. I rate a film I just watched**
Screen 08 (Quiet Earth) → ⋯ → **Log a watch**.
*Expect:* an empty sheet titled *Quiet Earth*, no stars lit, a blank review, Save enabled.
*What happens:* the sheet opens showing **Blue Hour**, 4.5 stars already lit, and a review nobody wrote. See scenario 6.
**Status:** `[!] known broken — with no rateable watch, the sheet shows the fixture's film and the fixture's opinion.`

**11. I open the rating sheet from a book and it shows a film**
Library → Books → tap a book → **Rate**.
*Expect:* that book.
*What happens:* pushed bare, so `newest_log(nil)` returns the newest log **anywhere in the library** — or, on any real device (no logs exist), "Blue Hour". Same for the Persian album screen (`album_detail_fa.ex:1006`), which opens the English film sheet.
**Status:** `[!] known broken — six of seven doors push 33 with no subject; rating.ex:379 then answers with whatever is newest.`

**11a. I fill in when, where and who with**
On 33, tap **Watched on**, then **Where**, then **With**.
*Expect:* each row opens something.
*What happens (from 7 September):* each opens under itself, in the card. Four days, the reader's own services then the places they have named before, and a field for names as typed. One row open at a time; pressing the open one closes it. Everything lands on `Kati.Media.Watch` at Save.
**Status:** `[x] verified on device 7 September`

**12. I tap the right half of the third star**
On 33, tap just right of centre on star 3.
*Expect:* the number beside the stars reads `3`, three filled stars.
*Verify:* `star_cell/3` (`rating.ex:~1050`) lays a 13x26 target over each half; `handle_info({:tap, tag})` maps `:star_6` → `6/2 = 3.0` → `rating_label/1` prints `3`. This half is genuinely wired — it is the one control on this screen that works end to end in the socket.
**Status:** `[ ] untested`

**13. I set a rating, press Save, and it refuses — do my stars survive?**
On 33 (any real device), tap star 8, type "great", press **Save**.
*Expect (per #85's rule):* the sheet stays up, the message appears, and the 4 stars and the typed text are still there so pressing Save again is worth doing.
*Verify:* `handle_info({:tap, :save})` assigns `:save_error` and does **not** pop (`rating.ex:1440-ish`); `save_notice/1` draws the red line under the header. This is correct behaviour and worth confirming on glass — it is the app's only working failure receipt in this group.
**Status:** `[ ] untested`

**14. I type a long review**
On 33, tap the cream card and type three sentences.
*Expect:* a wrapping paragraph.
*What happens:* it scrolls sideways on one line. `MobTextField` is `singleLine = true` (`MobBridge.kt:3543`) and the screen's own moduledoc records the trade deliberately.
**Status:** `[!] known broken — single-line field on a review card; a bridge prop, not a screen fix.`

**15. I tap "+ tag" to add "cinema"**
On 33, tap the dashed **+ tag** pill.
*Expect:* a tag field.
*What happens:* nothing. `@inert_taps` `{Kati.Screens.Rating, :add_tag}` — Backlog group: needs a tag field this screen does not draw.
**Status:** `[!] known broken — inert, by the sweep's own record.`

**16. I set where I watched it and who with**
On 33, tap **Watched on**, then **Where**, then **With** — all three carry chevrons.
*Expect:* a date picker, a service picker, a names field.
*What happens:* nothing at all. `context_card/1` (`rating.ex:1300`) builds three `SettingsList.row/4`s with `SettingsList.chevron()` and **no `on_tap` on any of them** — three chevrons promising three screens, with no tag, so they are invisible to the tap sweep as well.
**Status:** `[!] known broken — three chevron rows with no tap tag; rating.ex:1300.`

**17. I toggle "Spoilers hidden" / I switch to the 10-point scale**
Tap the spoiler line, then the `5★`/`10pt` toggle.
*Expect:* the flag flips; the scale changes.
*What happens:* neither is a control. `spoiler_toggle/1` (`rating.ex:1283`) is a glyph and a Text; `scale/1` (`rating.ex:~920`) draws two Rows with no `on_tap`. `contains_spoilers` has a column and no way to set it; the scale has no resource at all (documented).
**Status:** `[!] known broken — both painted; scale is knowingly storeless, spoilers is a real column with no control.`

**18. I save, press back, and check the film page**
On 33 with a *real* rateable watch (only constructible in tests today), press **Save**, land back on 08.
*Expect:* 08 shows the new stars.
*What happens:* two failures stack. (a) the pop restores 08's saved socket (`mob/screen.ex:571`) so it re-reads nothing; (b) even after a full re-mount, 08's stars come from `TrackedTitle.rating` and 33 wrote `Watch.rating`. **The number can never appear on 08.**
**Status:** `[!] known broken — 08 reads a different column from the one 33 writes, and the pop does not re-read either way.`

---

### 148 — Drop, DNF & abandon (`Kati.Screens.DropStates`)

**Unreachable except through Settings → Every screen → 148.** Nothing in `lib/` pushes `DropStates` — `grep` finds it only in `gallery.ex:188`. Its own moduledoc claims it is "pushed under Settings"; `settings.ex` contains no such row. It should hang off **Settings → a "How Kati thinks" / reference group**, beside screen 27's states sheet, which is the only other page of its kind.

**It is a static reference sheet and has zero live taps by design** — its moduledoc says so outright and it is correct: five statuses × three media, plus a transitions table, all from `Kati.Settings.DropStatesSample`. It reads nothing from `Kati.Media` and nothing on it can be wrong about a user's data.

**19. I want to know what "gone cold" means and go looking for it**
Home → Settings → scroll.
*Expect:* a row that opens this sheet.
*What happens:* there is none. The only door is the developer gallery.
**Status:** `[!] known broken — ROUTE MISSING. ⚠️ Settings → Every screen → 148.`

**20. I read the sheet and try to act on it**
⚠️ Settings → Every screen → 148 → tap any row, any state, the cream footnotes.
*Expect:* a reference sheet — nothing should move.
*Verify:* nothing does, and that is right. Confirm no row draws a chevron the user would read as a promise.
**Status:** `[ ] untested`

**One caveat worth flagging on the sheet's own content:** it names five statuses (`:active | :paused | :gone_cold | :dropped | :finished`). `Kati.Media.TrackedTitle` (`tracked_title.ex:109`) constrains `status` to `:not_started | :watching | :paused | :finished | :dropped`. `gone_cold` does not exist in the store, and this sheet asserts it does.

---

### 149 — Dropping (`Kati.Screens.DropSheet`)

**Reachable — but never for a film.** The one door is `Kati.Screens.Series` ⋯ → **Drop this show** (`series.ex:1164-1172`), which passes `params_for(series)`. routes.txt lists 149 as unreached for the same reason 33's film route was missed: it lives behind a two-step ⋯ menu. Screen 08's ⋯ menu has one row, **Log a watch**, and no drop of any kind. **A film cannot be dropped, abandoned or DNF'd anywhere in the app.**

**Live controls: ten.** `:close`, `:step_back` (the **Change** pill), six `:reason_*` chips, `:drop`, `:keep`, and `:undo` — the last live only after a drop. None of them is in `@inert_taps`; all of them reach a clause.

**21. I go quiet on a film and want to drop it**
Library → tap a film → ⋯.
*Expect:* a Drop row.
*What happens:* the menu holds one item, `Log a watch` (`film.ex:617`). There is no drop control on 08 at all, and 149 is titled "Drop this **show**" — its position card is `S# E#` and `step_back/1` walks seasons and episodes, so it could not honestly serve a film even if 08 pushed it.
**Status:** `[!] known broken — MISSING FEATURE. No drop path for a film; 149 is series-shaped.`

**22. I drop a series I actually track, from the series page**
Library → tap a series → ⋯ → **Drop this show** → **Drop at S1 E3**.
*Expect:* that series' status becomes dropped at the position shown.
*What happens:* `gone_cold_title/1` (`drop_sheet.ex:270`) filters `status == :paused`, then `pick/2` looks for your id **inside that filtered list**. **Nothing in the app ever writes `status: :paused`** — `AddTitle` creates every title as `:watching` (`add_title.ex:491`, `:503`) and no screen updates a title's status except this sheet and `LogProgress` (books). So the find fails, `sheet/1` falls back to `Sample.sheet/0`, and **you get "The Quiet Ones · GONE COLD · 4 MONTHS" over a series you have never paused.** Then tapping **Drop at S1 E3** runs `commit_drop/1` with `sheet.tracked == nil`, `update_tracked(nil, _)` returns `:ok` (`drop_sheet.ex:362`), **nothing is written**, and the sheet flips to the dark pill reading **"Dropped The Quiet Ones at S1 E3"**.
**Status:** `[!] known broken — the sheet opens on a fixture, writes nothing, and then tells the user it dropped a show that does not exist.`

**23. My drop fails and I am told it worked**
Same as 22 on a device where a paused row *does* exist (only reachable by hand-editing the DB today).
*Expect:* a failure receipt if the write is refused.
*What happens:* `update_tracked/2` (`drop_sheet.ex:364-369`) calls `Ash.update(tracked, attrs)`, **discards the result**, returns `:ok`, and has a `rescue _ -> :ok` under it. A rejected or raised write is indistinguishable from a successful one, and the undo pill announces the drop regardless. This is the exact defect `Kati.Write` and #85 exist to prevent, in a screen that never adopted them.
**Status:** `[!] known broken — the only write on this screen swallows its own errors; the receipt is a lie by construction.`

**24. I pick a reason, then drop**
On 149: tap **Too slow**, then **Drop at S1 E3**.
*Expect:* the reason is stored with the drop.
*What happens:* the chip lights (`handle_info({:tap, tag}) when tag in @reason_tags`), and `commit_drop/1` writes `status`, `progress_season`, `progress_episode` and **nothing else** (`drop_sheet.ex:337-341`). `TrackedTitle` has no `drop_reason` column. The reason is discarded when the sheet closes. The screen's moduledoc admits this; the user is given no hint.
**Status:** `[!] known broken — the reason chip is honest in the source and silent on the phone.`

**25. I drop, then immediately press Undo**
On 149 after tapping Drop, tap **Undo** in the dark pill.
*Expect:* status back to watching, position untouched.
*Verify:* `commit_undo/1` writes `%{status: :watching}` and flips `dropped?` back. This is genuinely wired (assuming a real `tracked`), and the pill is deliberately drawn *before* the drop with `Undo` inert — the one place in the app where an inert control is the right answer.
**Status:** `[ ] untested`

**26. I press "Still on it"**
On 149, tap **Still on it**.
*Expect:* the gone-cold mark clears, the sheet closes, and the series is unchanged otherwise.
*Verify:* `commit_keep/1` → `%{status: :watching}` → `pop_screen`. Then note the pop-staleness: the series page you land on still shows whatever it showed before.
**Status:** `[ ] untested`

**27. I press Change three times to correct where I stopped**
On 149, tap **Change** repeatedly.
*Expect:* some way to *pick* an episode.
*What happens:* it only ever steps **backwards, one episode at a time**, flooring at S1 E1 (`step_back/1`, `drop_sheet.ex:326-333`). There is no forward, no picker, and no way back up once you overshoot — you must close the sheet and reopen it.
**Status:** `[!] known broken — a one-way decrement labelled "Change".`

---

### 15 — Activity (`Kati.Screens.Activity`)

**Reachable.** Stats (dock) → **Activity log** (`stats.ex:1137`). Confirmed in routes.txt.

**What it draws.** `log/0` (`activity.ex:145`) reads every `Watch`, buckets into *today* and *earlier this month*, and — if **both** buckets are empty — replaces the entire page with `Kati.Activity.Sample`. Verbs are derived, not stored: `Rated` if the watch has a rating, `Rewatched` if `rewatch_number > 1`, else `Watched` (`activity.ex:712-718`).

**Live controls: six.** `:open_search` (pushes 19, works), four `filter_*` chips, and `:open_filters` — the ⚙/tune disc, in `@inert_taps` under **Backlog** (`screen_tap_sweep_test.exs:772`), reason on file: *no board in the 165 draws an activity filter sheet.* `filter_All` is also listed (`:382`) but only as the already-selected member of its family.

**28. I finish a film, then open Activity to see it**
Screen 08 → ⋯ → Log a watch → Save → Stats → Activity log.
*Expect:* a `Watched Quiet Earth` row stamped with today's clock, and the header count going up by one.
*What happens:* nothing was written (scenario 6), so both buckets are empty and the screen draws the fixture: **"1,204 entries"**, `21:12 Watched The Long Hollow S2E5`, `20:40 Rated Blue Hour ★★★★`, `18:03 Added Vellum to Wishlist`, and four more under *Earlier this month* including `Imported 412 titles from a CSV backup`. **A user who has done nothing is shown a fabricated year of history.**
**Status:** `[!] known broken — no film watch can exist, so the log is always the fixture for a film-only user.`

**29. I tick one episode of a series today, then open Activity**
Library → tap a series → tick an episode → Stats → Activity log.
*Expect:* `1 entry` and one real row.
*Verify:* this is the one path that produces a real Activity row — `write_tick` creates a `Watch` with `watched_at` and `watched_on` (`series.ex:1309-1318`). The header should read `1 entry` and the fixture should vanish entirely.
**Status:** `[ ] untested — the single working end-to-end write in this whole group.`

**30. I have watched things, but not this month**
Tick an episode, then wait until the calendar turns (or set the device clock forward a month).
*Expect:* an honest "nothing this month" and my real count.
*What happens:* `log/0`'s gate is `%{today: [], earlier: []} -> drawn()` (`activity.ex:147`). Both buckets go empty the moment your only watch falls out of the current month, so the page reverts to **"1,204 entries"** and seven invented rows. `screen_activity_test.exs:192` asserts this behaviour by name — *"a watch from before this month leaves the drawing standing"*.
**Status:** `[!] known broken — a real history is replaced by a fictional one as soon as it ages out of the month.`

**31. I tap the "Added" chip**
Stats → Activity log → tap **Added**.
*Expect:* the titles I added, or "nothing here".
*What happens:* `verb/2` can only ever return `Rated`, `Rewatched` or `Watched`, so on a real log `Added` matches nothing; `group([], …)` returns `[]` (`activity.ex:251`), so **both eyebrows and both cards disappear and no empty state is drawn.** You are left with a title, a count, four chips and a blank page (the rewatch card stays if you have one).
**Status:** `[!] known broken — the Added chip can never match a real row, and an empty filter draws no empty state.`

**32. I want to see my drops in the log**
Stats → Activity log → look for the row for the show I dropped in scenario 22.
*Expect:* `Dropped <show> after S1E3`.
*What happens:* there is no such row and no chip that would find one. Dropping writes a column on `TrackedTitle` and leaves nothing behind — the screen's own moduledoc names the missing resource (`media_events`, or a status-change row). The fixture's `07 AUG Dropped The Quiet Ones after S1E3` is the only drop this app has ever shown anyone.
**Status:** `[!] known broken — MISSING FEATURE. The append-only "undo trail" that 148 and 149 both promise does not exist.`

**33. I tap a row in the log to open the title**
Stats → Activity log → tap `Watched The Long Hollow S2E5`.
*Expect:* the series or film detail page.
*What happens:* nothing. No row in `entry_row/5` carries an `on_tap` — `grep on_tap lib/kati/screens/activity.ex` returns only the two header discs and the chip. Every one of those rows names a title the user could want to open.
**Status:** `[!] known broken — the log is not navigable; no row has a tap tag.`

**34. I tap the filter disc beside the search disc**
Stats → Activity log → tap the ⚙ (tune) disc top right.
*Expect:* a filter sheet.
*What happens:* nothing. `@inert_taps` `{Kati.Screens.Activity, :open_filters}`, Backlog group — *"a sheet that never opens"*, and the reason on file is that no board draws one.
**Status:** `[!] known broken — inert, by the sweep's own record.`

**35. I search from the Activity screen**
Stats → Activity log → tap the 🔍 disc.
*Expect:* screen 19, with a back pill reading **Activity**.
*Verify:* `handle_tap(:open_search)` pushes `Search` with `%{query: "", back: "Activity"}` (`activity.ex:632`). This one is wired properly and the back label is correct.
**Status:** `[ ] untested`

---

### What has to land before any of this group can be walked end to end

1. **A creator for a title-level `Kati.Media.Watch`.** One function, on the film screen or behind the ⋯ menu, writing `%{tracked_title_id, watched_at, watched_on}` the way `Series.write_tick/2` already does. Nothing else in this group is testable until it exists.
2. **Screen 33 must be able to create, not only update.** `save_watch(%{watch_id: nil})` should create against the `tracked_title_id` it was pushed with, rather than refusing — and keep refusing only when there is no title id either (the gallery's door).
3. **One rating column, not two.** Either 08 reads the newest watch's rating, or 33 also writes `TrackedTitle.rating`. Today they cannot agree.
4. **The pop-staleness decision.** Every scenario above that ends "press back and look" is undecidable until a popped-to screen re-reads. That is the fork already on file in `MISSING-CONNECTIONS.md`.

---

## One series, and its episodes

**Read this first — one fact governs all eight pages.**

Nothing in the app writes `Kati.Media.CachedSeason` or `Kati.Media.CachedEpisode` except `Kati.Media.Tmdb.fetch/2` (`lib/kati/media/tmdb.ex:142`), and the only caller is `Kati.Screens.AddTitle.track/2` (`add_title.ex:485`), on the TMDB branch only. `Kati.Seeds.groups/0` (`seeds.ex:141-155`) writes `CachedTitle` and nothing else — no `TrackedTitle`, no season, no episode; `:media_tracking` is still a documented future group.

So on a Pixel 9a with no `TMDB_READ_TOKEN`:

- **there is no season or episode row in the database, ever**;
- `Kati.Screens.Series.facts/1` hits its `[] -> nil` gate at `series.ex:299-303` for every title, and screen 04 draws `Kati.Library.Sample` — *The Long Hollow* — no matter what you tapped;
- screens 34, 14, 35, 143, 144, 153 and 58 are all on their fixtures for the same or a related reason.

The one series you can put on the shelf without a key is a hand-typed one (154 → `:manual` `TrackedTitle` + `CachedTitle`, no episodes — `add_by_hand.ex:478-485`). That is **exactly** the state `design-briefs/D-58-a-title-with-nothing-under-it.md` was written about, boards 248/249 are not drawn (`ls test/design/screens/` stops at 190), and screen 04 has no third branch for it. **Every hand-added series in this app opens as *The Long Hollow*.** That is the headline defect of this group and scenario 04-3 walks it.

Second fact, smaller but everywhere: **`:save_error` is assigned on screens 04 and 34 and rendered on neither** (`series.ex:1284`, `season.ex:235`; ten other screens do render it — `add_by_hand.ex:87`, `log_weight.ex:95`, …). Every write failure on this group's two writing screens is silent. It also defeats `Kati.ScreenTapSweepTest`'s dead-tap heuristic, which compares assigns before and after: setting an unrendered assign counts as "the control did something".

Route note: `routes.txt` lists **14, 34, 35, 144** as gallery-only. That is a sweep artefact, not the truth — 04's ⋯ disc is wired (`series.ex:740` → `Event.handler/1` at `components/event.ex:34` widens the bare atom to `{self(), :toggle_menu}`), and its five menu rows push all of them (`series.ex:1135-1170`). The sweep pressed `:toggle_menu`, got no push back, and never re-rendered to find the rows. **Verify the menu opens on device first** — `Kati.Components.Anchored` is `K-18`, its first use in Kati, and if the popup does not draw then 14, 34, 35, 144 and 149 really are gallery-only. Genuinely gallery-only in this group: **143** and **153**.

---

### 04 — Series detail (`Kati.Screens.Series`)

**Route** Library → tap a series poster (`library.ex:1301` → `open_tile/3` passes `%{id: …}` when the row has one).
**Reads** `TrackedTitle` `:shelf` (two reads, `:tv` + `:anime`) → `Release.cached_for/1`, `CachedSeason.for_title/2`, `CachedEpisode.for_title/2`, `Watch` `:episode_ticks`. Falls back whole to `Kati.Library.Sample.series/0` when there is no season number to draw.
**Writes** `Kati.Media.Watch` — one row per ticked episode, destroyed on untick (`write_tick/2`, `series.ex:1296-1326`). This is the only episode-level write in the entire app.

1. **I open the series I am watching** — `[!] known broken — the shelf is empty on a fresh phone, so there is no poster to tap.`
   Home → Library. Expect the Screen shelf with your series on it. Today `Kati.Screens.Library.shelf/0` answers `[]` and `content/1` draws screen 27's *No titles yet* card (`library.ex:40-66`, #91). There is no route into 04 until you have added something.

2. **I add a series with a TMDB key and open it** — `[ ] untested`
   Home → **+** → type a real show → tap the row → back to Library → tap its poster. Expect the show's own artwork, `DRAMA · 3 SEASONS` (no year, no service — neither is stored), the season strip lit on S1, `0 of N watched`, the real episode list, and `Next episode airs …` only if `Kati.Media.Release` resolves one. Store afterwards: one `TrackedTitle`, one `CachedTitle`, N `CachedSeason`, M `CachedEpisode`. **Only reachable on the developer's Mac** — `Tmdb.key/0` answers `{:error, :no_api_key}` on the phone.

3. **I add a show by hand because Kati could not find it, then tap it** — `[!] known broken — it opens somebody else's show.`
   Home → **+** → **Add by hand** → Kind: **Series** → title *"My Show"* → Save → Library → tap *My Show*.
   Expect: *My Show*, a poster placeholder, a status chip, and an honest **"No episode list yet."** card where the season bar goes (D-58, boards 248/249).
   Actual: `series_record/1` finds your row, `facts/1` reads zero seasons and zero episodes, returns `nil` (`series.ex:299-303`), and `series/1` draws `Sample` — **The Long Hollow**, hollow71 artwork, `2024 · DRAMA · LUMEN+ · 3 SEASONS`, S1/S2/S3, seven episodes with names and air dates. Nothing on the page is yours. The id you carried is discarded silently.

4. **I mark episode 6 watched** — `[!] known broken on the fixture — the tap writes nothing and says nothing.`
   On 04, tap the *Ash and After* row. Expect the ring to fill, the counter to go `6 of 7`, the bar to move, and a `Kati.Media.Watch` row to exist. Actual on the drawn page: `Sample.series/0` carries no `:tracked_id`, so `write_tick(nil, ep)` returns `{:error, :not_tracked}` (`series.ex:1290`), `tick/2` assigns `:save_error` (`series.ex:1284`), and `render/1` (`series.ex:578-610`) never draws it. **Nothing moves. No message.** On a real TMDB-backed series this path does work.

5. **I press Mark next watched** — `[!] known broken on the fixture — same silent failure as 4.`
   Tap the big ink button. `mark_next` finds the first aired, unticked row and routes through the same `tick/2` (`series.ex:1182-1187`), so it fails identically and silently. On a season with nothing left to mark it correctly does nothing — but that is indistinguishable from the failure above, which is the problem.

6. **I mark an episode, switch to S1, and come back to S2** — `[!] known broken — the tick disappears from the screen.`
   Tap an episode in S2 → tap **S1** → tap **S2**. Expect the tick still there. Actual: `tick/2` updates `series.episodes` but never `series.by_season[current_season]`, and `switch/2` restores `view.episodes` from that stale map (`series.ex:1209-1223`). On a real series the row is in the database and gone from the screen — worse than losing it.

7. **I tap the bookmark disc, then the star disc** — `[!] known broken — both are decorative.`
   The two 50pt discs beside *Mark next watched*. `action_disc/1` (`series.ex:952-963`) passes no `on_tap` at all; the comment says so outright ("bookmark and rate are not built"). They are drawn as buttons at button size beside a live button.

8. **I open the ⋯ menu** — `[?] unknown — needs a device.`
   Tap ⋯ top-right. Expect a five-row panel: *Show details*, *Episode order*, ─, *Show settings*, *Rate an episode*, *Drop this show*. All five are wired (`series.ex:1135-1170`); the panel is `Kati.Components.Anchored`, a bridge node used nowhere else in Kati (`native/LEDGER.md` K-18). **If it does not appear, five screens are stranded.**

9. **I tap Episode order from the menu** — `[!] known broken — 04 and 34 disagree about which Season 2 you are on.`
   ⋯ → *Episode order*. On the drawn page `Season.params_for/1` gets no `tracked_id` and yields `%{}` (`season.ex:300`), so screen 34 falls back to `Kati.Season.Sample` — *Season 2*, episodes *Low Water / The Estuary / The Cull*. Screen 04 above it lists *The Weight of Water / Hollow Ground / …*. Same show, same season, two different episode lists, one back tap apart.

10. **I open a series, archive it elsewhere, and come back** — `[?] unknown`
    04 reads through the `:shelf` action, so an archived row answers `nil` and the page swaps to the fixture rather than saying the title is gone. Correct per `BookDetail.shelved_book/1`'s rule, indistinguishable from every other fallback in practice.

11. **A ten-season show** — `[?] unknown — probable overflow.`
    `episodes_header/1` (`series.ex:966-986`) lays the `EPISODES` eyebrow and every season pill in one un-scrolling `Row`; ten 30pt pills plus gaps is ~345pt against ~369pt of content width on a 411dp device, before the eyebrow. Worth checking against a long-running show.

12. **Spoiler-safe episode names** — `[!] known broken — the column has one reader and no writer, and 04 is not it.`
    `TrackedTitle.hide_unwatched_titles` is annotated "spoiler-safe episode names on screen 04" and 04 never reads it (`series.ex:106-108`). Only `RateEpisode.shaped/4` does. Screen 35, where you would turn it on, is inert.

---

### 34 — Season (`Kati.Screens.Season`)

**Route** 04 → ⋯ → *Episode order*, with `%{title_id:, season:}` when 04 has a real series. Gallery otherwise.
**Reads** `TrackedTitle` `:shelf` → `CachedSeason.by_reference/3`, `CachedEpisode.for_season/3`, `CachedEpisode.for_title/2` for the absolute numbering, `Watch` `:episode_ticks`. Falls back to `Kati.Season.Sample.season/0` when the bookmarked season has nothing cached.
**Writes** `Kati.Screens.Series.write_tick/2`, shared with 04 — correct, one write path, and it was handing that path a string until 6 September (see 16).

13. **I switch from Aired to Absolute** — `[x] verified on device 6 September`
    Tap **Absolute** and the list renumbers, drops the special and changes its count with it; tap **Aired** and it comes back. Verified against Severance S2: `E1–E10` with `S1 Welcome to Lumon` listed first becomes `E10–E19` with no special and `10 IN THIS ORDER`. The ticks survive, which is the footnote's own claim, because the tick is written against `episode_source_id` and never against a number.
    The data half did *not* already exist, which is why this took a resource change: `absolute_number` is a column no source Kati fetches from fills, so a live Absolute tile over `in_order/2` alone would have emptied the list. `Kati.Media.CachedEpisode.derived_absolute/1` computes it instead, and only from a cache that holds the whole series — a season missing, a gap in one, or a single-season show and the tile is not offered at all. **DVD is never offered**, and a strip left with one tile is dropped whole: one segment is not a control.

14. **I turn off Include specials** — `[!] known broken — inert, and the label is false either way.`
    `options/1` builds `SettingsList.switch(row.on)` with no tap (`season.ex:620-643`). Worse: on a real season `assemble/3` (`season.ex:398-411`) replaces only `title`, `eyebrow`, `episodes` and `note`, so *Include specials · Shown inline, at air date* stays **on** while `for_season/3` reads one season number and never touches season 0. The switch claims a behaviour the list does not have.

15. **Merge multi-part and the PARTS 1–2 badge** — `[!] known broken — a claim about somebody else's episodes.`
    *Treat E7 & E8 as one 2h finale* survives onto a real season's card. Nothing records a merge; no real row ever carries the badge. The switch and its sub-line are the fixture's, sitting over your episodes.

16. **I mark an episode watched here** — `[x] fixed 6 September, and it had never worked`
    Untested was doing a lot of work in the old entry. **Every tick made on this screen was refused.** The row carried `number: "E2"` — a string, because the same field is `S1` for a special and `""` for an episode a source never placed — and `Kati.Screens.Series.write_tick/2` falls back to it for `Kati.Media.Watch.episode_number`, an integer column. Ash answered `Is invalid.`, the ring never filled, and nothing in the suite pressed it. Screen 04's rows have carried `:n` and `:season` since #46; this screen's now do, off the columns rather than off the chosen order, so a tick made in Absolute records the season and number the show uses. Verified on the Pixel_9a. The refusal *is* drawn now (`refusal/1`), which is how a future one would be seen.

17. **I tap the ⋯ disc at the top** — `[x] verified on device 6 September`
    It opens `Kati.Screens.ShowPages` — *Show details* and *Show settings*, this page's own row left out. 35 draws the same disc with *Show details* and *Episode order*. Each push carries the show and a back label naming the page you came from, so 34 → *Show settings* → *Show details* leaves a pill reading `Show settings`. Over the board the disc is still a picture: a menu whose every row would push a bare screen is worse than the one that opened nothing.

18. **The back pill says Series** — `[?] unknown`
    `use Kati.Screens.Pushed, back: "Series"`. Correct from 04, wrong from the gallery.

---

### 14 — Series metadata (`Kati.Screens.SeriesMeta`)

**Route** 04 → ⋯ → *Show details*. `routes.txt` says gallery-only; the code says otherwise (see the route note).
**Reads** `Kati.Media.TrackedTitle` through `:shelf` and the `Kati.Media.CachedTitle` behind it, by the `:id` the push names (`series_meta.ex`). With nothing stored it answers `Sample.series()` whole, which is the state board 14 was captured in.
**Writes** nothing.

19. **I tap Show details on my show** — `[x] fixed 6 September` (`5915c2a`).
    04 → ⋯ → *Show details*. The push now carries the row screen 04 is drawing, and the page reads it: the title, the still, the meta line and the synopsis are that show's. Verified on the Pixel_9a — Severance draws `Severance`, `DRAMA, MYSTERY, SCI-FI & FANTASY · 3 SEASONS · 19 EP`, its own backdrop and its own synopsis.
    The cast, the two foreign ratings, *Where to watch* and the tags are `[]` on a real title and their headings go with them, because no resource behind them exists — the moduledoc lists all four. **Open:** what the page draws in the space they leave. See `design-briefs/D-63`.

20. **I tap Trailer** — `[!] known broken — inert.` The 48pt ink primary button (`series_meta.ex:393-427`) has no `on_tap`. No video, no link, no column behind it.

21. **I tap the bookmark or label disc, or + tag** — `[!] known broken — all three inert.` `action_disc/1` (`series_meta.ex:430-443`) and `tag/2` (`series_meta.ex:676-709`) draw no taps. The only live control on this screen is the back pill.

---

### 35 — Series settings (`Kati.Screens.SeriesSettings`)

**Route** 04 → ⋯ → *Show settings*, carrying the show the menu was opened over (`series.ex:1502`).
**Reads** the tracked row that push names, and `Kati.Media.Release.cached_for/1` for its title. With no id — the gallery, a sweep, a push that named nothing — `Kati.SeriesSettings.Sample.show/0`.
**Writes** `TrackedTitle.status` and the four season-pass columns.

22. **I set the show to Paused** — `[x] verified on device 6 September`
    Tap **Paused**. The tile lights, `TrackedTitle.status` becomes `:paused`, and it is still Paused after ‹ Series and back in. All three tiles write, the lit one included — pressing *Watching* on a watching show writes the same value, which is how somebody checks rather than changes. The off-state arm of `status/1` was the last thing to break here: it computed the tap and drew a `Box` without it, so the two tiles you press to change anything were dead. Found by pressing them on the phone; `Kati.SeriesSettingsTest` now asserts all three carry a tap on the drawn tree.

23. **I turn off Tell me about episodes** — `[x] verified on device 6 September`
    All four season-pass switches write the `TrackedTitle` column they sit over — `auto_add_new_seasons`, `notify_new_episodes`, `add_air_dates_to_calendar`, `hide_unwatched_titles` — and only that one. The tap is on the whole row rather than on the 46×28 switch, which is the shape screen 25 settled. The moduledoc's *a switch that flips and forgets is worse* still holds and is why the control moves only after the store answers.

24. **I tap Remove from library** — `[x] the row is gone, which is the honest answer`
    *This show* had no schema behind any of its three rows and *Region & availability* had none behind any of its four, so both groups are dropped over a real show rather than drawn dead. A destructive-looking control that does nothing is not a smaller version of one that works. Both groups are still drawn whole on the board, which is what the drawing is a drawing of.

25. **Whose show is this anyway** — `[x] verified on device 6 September`
    The header is the show you opened the menu from — *Severance*, not *The Long Hollow*. `S4 will appear when announced` and `Currently 5 of 7 in S2` stay the board's on both branches: they belong to rows whose switches now write, and they say what the switch DOES rather than where this show is.

---

### 143 — Episode rows, the rating column (`Kati.Screens.EpisodeRatings`)

**Route** ⚠️ `Settings → Every screen → 143`. **Gallery-only.** It is a specimen sheet in the manner of 89, so it may be right that a user never reaches it — but then the feature it specifies should exist on 04, and it does not.
**Reads** two literal lists (`episode_ratings.ex:163-181`).
**Writes** nothing except `:hint_visible?`.

26. **I go and look at what a rated episode row is meant to look like** — `[ ] untested`
    ⚠️ Settings → Every screen → 143. Expect *The Long Hollow*, `SEASON 2 · 5 OF 7 WATCHED`, six rows with `4.5★`, `5★`, `3.5★` on three of them and no column at all on the two unrated, then a second band with no column band-wide, then the hint card and the cream gesture-rule note. This board renders correctly and completely; it is the only screen in the group that does what it says.

27. **I tap Got it on the hint** — `[ ] untested`
    Expect the card and its 14pt of trailing space to leave the layout. `handle_tap(:dismiss_hint, …)` (`episode_ratings.ex:497`) does exactly that. Reopen the screen and it is back — there is no column for "has seen the hint", which the moduledoc states.

28. **I go to screen 04 and look for the column this board specifies** — `[!] known broken — it does not exist.`
    `Kati.Screens.Series.episode/1` (`series.ex:1041-1095`) draws number, title, sub-line and check. No rating node, no call to `Watch.for_episode/2`. Board 143 has been drawn and built as a picture and never applied to the screen it is an edit of.

29. **I long-press an episode row to rate it** — `[!] known broken — Mob has no long press.`
    The hint on 143 and the closing note both name the gesture. A repo-wide grep for `long_press` finds nothing. On 04 the same gesture the hint describes is unavailable, and the only door to 144 is a ⋯ menu row the design does not draw.

---

### 144 — Rate an episode (`Kati.Screens.RateEpisode`)

**Route** 04 → ⋯ → *Rate an episode*, **pushed bare** (`series.ex:1155-1156`) — it is not told which series or which episode.
**Reads** the newest `Watch` anywhere in the store with an `episode_source_id` **and** a rating or a review (`rate_episode.ex:305-316`).
**Writes** nothing.

30. **I rate the episode I just watched** — `[!] known broken — this screen can never show your episode, and cannot save.`
    Three independent failures stack:
    - **The referent.** Pushed with no params, it picks the newest rated episode log in the whole database — not the episode you were looking at, not even necessarily the same show.
    - **It can never have one.** The only writer of an episode-level `Watch` is `Series.write_tick/2` (`series.ex:1308-1318`), which sets `tracked_title_id`, `episode_source_id`, `watched_at`, `watched_on` — **no rating, no review**. So `newest_episode_log/0`'s `not is_nil(rating) or review != ""` filter can never match. `logged_sheet/0` always answers `nil` and the sheet is always `Kati.Screens.RateEpisode.Sample`. A closed loop: the only thing that could populate this screen is this screen.
    - **The stars are not controls.** `rating_card/1` calls `Rating.stars(s.rating)` (`rate_episode.ex:640`) — arity 1, so `tappable?` defaults to `false` (`rating.ex:1002`) and `star_cell/3` returns the bare glyph. Screen 33 calls `Rating.stars(w.rating, true)` (`rating.ex:874`) and gets ten tap targets.

31. **I press Save** — `[!] known broken — it pops the screen and writes nothing.`
    `handle_info({:tap, :save}, socket)` is `{:noreply, Mob.Socket.pop_screen(socket)}` (`rate_episode.ex:1007`). The screen closes; a user reads that as saved. Screen 33's own `:save` calls `save_watch/1` and only pops on `{:ok, _}` (`rating.ex:1419-1430`) — so this module's moduledoc claim that "Save here pops the screen exactly as screen 33's does, without writing" is stale about 33 and describes a gap, not a policy.

32. **I close it with the ✕** — `[ ] untested` `Sheet.close_disc/0` → `:close` → pop. Works.

33. **I expand the previous verdict** — `[ ] untested`
    The cream card's whole surface carries `:toggle_verdict` (`rate_episode.ex:693`) and the chevron rotates 180°. Live, and the only working control on the sheet — but it can only ever quote `Sample.reference_verdict/0`, since `rewatch?` needs two rated logs and there can be zero.

34. **A show with spoiler-safe names on** — `[!] blocked` `spoiler_safe?` reads `tracked.hide_unwatched_titles` (`rate_episode.ex:357`), the app's only reader of it. Screen 35, the only place to set it, is inert. So the headline can never be masked in practice.

---

### 153 — Numbering, inherited and overridden (`Kati.Screens.NumberingScheme`)

**Route** ⚠️ `Settings → Every screen → 153`. **Gallery-only.** It should hang off 34 — it explains the strip 34 draws — or off 35 under *This show*.
**Reads** `Kati.NumberingScheme.Sample` throughout (`numbering_scheme.ex:80-87`).
**Writes** nothing.

35. **I read why my anime is numbered the way it is** — `[ ] untested`
    ⚠️ Settings → Every screen → 153. Expect *Inherited* over a row with its reason, *Overridden* over the same row correcting itself, a two-column Absolute-vs-Seasons comparison over "display changes, storage does not", and the MyAnimeList tile. Renders correctly. It is an explainer, and as an explainer it is complete.

36. **I tap Override** — `[!] known broken — inert, and stated as such.`
    `SettingsList.action_pill/1` takes no `on_tap` and the moduledoc says why: there is no `numbering_scheme` column anywhere in `Kati.Media` for a tap to write. Correct reasoning. The consequence is that the app has no numbering preference at all — which is also why screen 34's Absolute tile has nothing to persist.

37. **I get here from the season I am actually confused about** — `[!] known broken — no route.`
    Nothing pushes this screen. A user hits the Aired/Absolute/DVD strip on 34, wonders, and has nowhere to go.

---

### 58 — سریال (`Kati.Screens.SeriesFa`)

**Route** Persian only: Settings → Language → فارسی → کتابخانه → tap a series poster (`library_fa.ex:960-966`, passing `Series.params_for/1`). Also from Persian search (`search_fa.ex:976`, **bare** — no id). `routes.txt` only found the search door because its BFS ran in English.
**Reads** `Kati.Screens.Series.tracked_series/1` — screen 04's own read, correctly shared. Presentation only in this file.
**Writes** **nothing.** This is the defect.

38. **I open my series in Persian** — `[ ] untested` (fixture path certain)
    کتابخانه → tap a poster. On a fresh or hand-typed store you get `Sample.series/0` — گودال بلند — for the same reason as 04, one gate up. With TMDB-backed data you get your show, in Persian digits and Shamsi dates, headings built as `فصل ۲` rather than from a provider's English `name`.

39. **I mark an episode watched in Persian** — `[!] known broken — the tick is never written and is lost the moment you leave.`
    Tap an episode row, or the big `قسمت ۶ را دیده‌ام` button. The ring fills, the counter moves to `۶ از ۷`, the bar advances, the button relabels — all of it correct, all of it in memory. `toggle/2` (`series_fa.ex:1007-1010`) flips a boolean and calls `recount/1`; there is no `write_tick`, and `shaped/1` (`series_fa.ex:195-212`) does not even carry `:tracked_id` for one to use. Press back, reopen: every tick is gone. Screen 04 fixed this in #90; the mirror was not. **This is the opposite failure to 04's** — 04 writes and shows nothing, 58 shows and writes nothing — and the two pages tick the same episodes.

40. **I tick something in Persian, then look at it in English** — `[!] known broken` The English page will disagree, because only one of them touched the database. `Kati.ScreenSeriesTest`'s *"58 and 04 agree about the series, the season and the counter"* compares them at rest, not after a tap.

41. **I tap the bookmark disc** — `[!] known broken — it flips a glyph and stores nothing.`
    `:toggle_save` (`series_fa.ex:948-951`) toggles `series.saved` in the socket. There is no bookmark column anywhere. It survives until you leave the screen.

42. **I tap the ⋯ disc** — `[!] known broken — it is not a control at all.`
    `more/0` (`series_fa.ex:475-480`) passes no `on_tap`. Where the English page opens a five-row menu, the Persian page's identical-looking disc does nothing — so Persian users have **no route** to 14, 34, 35, 144 or 149.

43. **I switch seasons after ticking** — `[!] known broken — same stale-cache bug as 04-6.**
    `toggle/2` updates `episodes`, `switch/2` restores from `by_index` (`series_fa.ex:990-1005`), which the toggle never touched. Here it costs nothing extra, since the tick was never real anyway.

44. **A coarse air date** — `[ ] untested` `{:quarter, 2026, 3}` draws no row rather than a Shamsi year Kati invented (moduledoc, and `Kati.ScreenSeriesTest`'s *"a coarse date draws nothing"*). Correct and deliberate; the English page says `Q3 2026` in the same state.

---

## What to watch next, and where

Screens 10, 11, 12, 13, 05, 25, 92, 93, 94, 95, 96, 23.

These twelve answer *what should I watch tonight, and can I?* Read together, the group has one shape: **the pages that read your data cannot be operated, and the pages that can be operated do not read your data.** Screens 10 and 05 assemble real rows out of `Kati.Media` with real care and then draw every button as a picture. Screens 11, 12, 13 and 23 are fixtures with working chips on top. Screen 92 is the only page in the group that both reads and writes — and it is also the only one that mixes the two in the same card.

Two facts to carry into every scenario below.

**The store's own vocabulary.** `:watching` is *ready*, `:paused` is *gone cold*, `archived` hides a row from the shelf. Everything a user adds through screen 06 lands as `status: :watching`, so **anything you add appears on Up next immediately** — that is the fastest way to get a real row onto these pages.

**The TMDB key.** `Kati.Media.Tmdb.key/0` reads `System.get_env("TMDB_READ_TOKEN")`, absent on the phone, so search returns `{:error, :no_api_key}`. Screen 06 composes the sentence and never draws it. In this group that bites in three places: 05's Out now list can never fill (no episodes without a fetch), 11's leaving rows have no availability data to be real, and any title you *do* add by hand carries no runtime and no poster — which is what makes 10's hero render blank. A key can be entered on **Settings → Data sources → my own key** (`Kati.Sources.put_tmdb_key/1`), and walking these scenarios with a key in place is a genuinely different run from walking them without. Do both.

### Routes, corrected

| # | Page | Route |
|---|---|---|
| 10 | Up next | Library → **Up next** tile |
| 11 | Discover | Library → **Discover** tile |
| 12 | Lists | Library → **Lists** tile (also Book/Album detail → Add to list; Shelf selection → Add to list) |
| 13 | What fits? | Library → **⋯** (top right) → **What fits?** |
| 05 | New releases | **Settings → New releases** since #1; also Home → **New this week** hero → **Open inbox**, when there is something out |
| 25 | Release watcher | Home → **bell** → **Release watcher**; also Settings → Release watcher |
| 92 | My services | Home → **My services** row; also Settings → My services |
| 93 | — nothing set up | 92 → **Show all 47** |
| 94 | Country picker | 92 → the country row; 93 → **Pick your country** |
| 23 | Subscriptions | 92 → **Subscriptions** money row; 93 → two different rows |
| 95, 96 | states / knock-on | ⚠️ Settings → Every screen only, and correctly so |

`routes.txt` puts **13** under NOT REACHED. That is a BFS artefact, not a defect: the Library overflow menu is not drawn at rest, so `open_what_fits` was never on screen to be pressed. It is two taps from the dock (`library.ex:588`, `:1237`). Several other NOT REACHED entries — 34, 35, 143, 144, 146, 147, 152, 153 — are worth re-checking for the same reason before anyone calls them unrouted.

`routes.txt` puts **05** at "only via fa". That one is real and is the most serious reachability finding in the group. See 05 below.

---

### 10 — Up next (`Kati.Screens.UpNext`)

The board's caption is *"the screen the whole app is for"*. It is the best-read page in this group — sections are `TrackedTitle.status`, order is `last_touched_at` desc, `18M LEFT` and the burnt-in bar are `progress_seconds` against `runtime_minutes`, `4 MONTHS AGO` is real arithmetic on `last_touched_at`, `4 airing soon` goes through `Release.resolve/2` and refuses a date coarser than a day.

**And not one thing on it can be pressed.** `grep -n 'on_tap\|handle_tap' lib/kati/screens/up_next.ex` returns nothing across 743 lines. The hero's play disc, four ready-row play discs, the `tune` disc and every `Drop` pill are built without a tap (`play_disc/4` :610, `drop_pill/1` :701, `tune_disc/0` :358). `Kati.ScreenTapSweepTest` is blind to this by construction — `ScreenSweep.tap_tags/1` collects tags that ARE drawn, so a screen with zero drawn tags passes every check in the file.

1. **I open Up next with nothing on my shelf.**
   Steps: Home → **Library** → **Up next**.
   Expect: an empty-queue state, or at worst the drawing. What you get is the drawing: The Long Hollow at 62%, four ready rows, one cold row — over a subtitle reading `12 ready · 4 airing soon`, an eyebrow reading `Ready to watch · 12` above four rows, and `Gone cold · 3` above one. The Library tile above it is honest (`up_next_badge/1` answers `nil` on an empty shelf, `library.ex:762`) so the tile shows no count and the page it opens announces twelve.
   Status: `[!] known broken — fixture with counts that contradict its own list; store is never consulted.`

2. **I add one film, then open Up next.**
   Steps: Home → **+** → tap a row on Add a title → back → **Library** → **Up next**.
   Expect: one hero, real title, real poster, `S… E…` or a runtime. What you get: `create_cache/2` (`add_title.ex:552`) writes only `source: :manual`, `source_id: <the title string>`, `kind`, `title`, `fetched_at` — no `poster_path`, no `runtime_minutes`. So `hero_art/1` draws a Spacer, `hero_row/2`'s meta composes to `""` (no season, no episode, no runtime), `fraction/2` answers `nil` so `progress/1` draws nothing, and the two eyebrows read `Ready to watch · 0` and `Gone cold · 0` over two empty sections.
   Status: `[!] known broken — the first real row renders as a grey rectangle with an empty caption line and two empty labelled sections.`

3. **All my shows are paused. I open Up next.**
   Steps: shelf a title, set it to paused (Film/Series detail), → **Library** → **Up next**.
   Expect: my paused title under **Gone cold**, nothing under Ready.
   Reality: `queue/0` (:110) is `case tracked(:watching) do [] -> Sample.queue(); [hero|rest] -> assemble(hero, rest, tracked(:paused)) end`. With no `:watching` row the fallback fires **whole** and `tracked(:paused)` is never called — four invented titles, and the user's own paused show nowhere on the page.
   Status: `[!] known broken — the all-or-nothing fallback hides real paused rows behind fixtures.`

4. **I tap the play button on the hero.**
   Expect: the title's detail screen, or resume.
   Reality: nothing. No press feedback, no push. Same for the four row discs.
   Status: `[!] known broken — decorative control.`

5. **I tap `Drop` on a cold row.**
   Expect: the drop sheet. It exists and it writes — `Kati.Screens.DropSheet` takes `params_for(%{tracked_id: id})` (`drop_sheet.ex:237`) and is already pushed with params from screen 04. The pill is one `on_tap` and one extra key in `cold_data/2` away from working.
   Status: `[!] known broken — the destination is built; the pill is not wired to it.`

6. **I tap the `tune` disc, expecting to reorder or filter the queue.**
   Status: `[!] known broken — a Box with a glyph in it and no tap.` (Library's four sort discs already push `Kati.Screens.ShelfFilters`; this is the same disc.)

7. **A title I am watching gets archived from another screen while Up next is on the stack; I come back.**
   `load/1` runs at mount only, and `pop` restores the saved socket without re-mounting (`deps/mob/lib/mob/screen.ex:571`). The archived row stays on screen.
   Status: `[?] unknown — worth confirming on device; the mechanism is certain, the observable depends on how you got back.`

---

### 11 — Discover (`Kati.Screens.Discover`)

**Reads `Kati.Media` since 6 September** (`ca8f89e`). `Kati.Media.Recommendations` seeds on the newest title the reader touched and TMDB's `/recommendations` answers it; the other two sections still have no resource behind them and are now empty rather than fixtures. With nothing stored, board 11 is still drawn whole.

What it used to mean in front of a user: six specific claims about them, all invented. *Tuned to 128 titles*. *Because you watched The Long Hollow*. *94% match*. Three people — Ines Karvel, Tomas Rhee, Ada Vance — with roles and credit counts. *Leaving Lumen+ in 7 days*, for a service that may not be on their account.

8. **I open Discover on a fresh phone.** — `[x] fixed 6 September` (`ca8f89e`).
   Steps: Home → **Library** → **Discover**.
   A device with a title on it gets one section: the picks, under the title they came from. A device with nothing gets board 11. Verified on the Pixel_9a — *BECAUSE YOU WATCHED SEVERANCE* over Emergence, Tales from the Loop and Mr. Mercedes, with their own posters.
   Three empty answers are drawn apart: a request in flight, a token nobody has entered (which takes `Kati.Media.Tmdb.message/1`'s own sentence), and a provider that knows of nothing like this show.

9. **I tap `Awards`.** — `[x] gone on a real device 6 September`; still true on board 11.
   `shows?/2` answers `false` for every section and the page below the chips empties with no message. On a real feed there is one section and therefore one chip, and `chips/2` drops the rail entirely rather than offering three chips over sections this device has none of. The board keeps all four.

10. **I tap `Leaving`, which claims 5.** — `[x] gone on a real device 6 September`; still true on board 11.
    `leaving` is `[]` on a real feed and the chip that named it is not drawn. The board's `"5"` over two rows is the fixture's own disagreement and is left as drawn.

11. **I tap `Schedule` on a leaving row, then go back and return.**
    Status: `[x] resolved 7 September — the button is a picture now, in both states.` It was the one *working* control on the page and what it did was toggle a socket assign the next pop threw away. There is nothing to schedule against — `leaving` is `[]` on every real feed and this section exists only on board 11 — so a button that changes and forgets was the screen claiming a thing was scheduled.

12. **I tap the `tune` disc.**
    Steps: Library → **Discover** → the disc at the top right.
    Status: `[x] verified on device 7 September` — it opens **PICKS FROM** over the shelf and picking a title rebuilds the feed from that one. Not offered on a shelf of one, and a picture on board 11.

12. **I tap `For you`, the chip that is already lit.**
    Status: `[ ] untested` — recorded in `@inert_taps` as `{Kati.Screens.Discover, :"filter_For you"}`, the ordinary already-selected case. Not a defect.

13. **I tap the `tune` disc top right.**
    `header/1` (:196) draws `<Box width={44} height={44} corner_radius={22} …>` with a glyph and no `on_tap`.
    Status: `[!] known broken — drawn control, no tap.`

14. **I tap a poster in the rail** — `[x] fixed 6 September` (`1b1293f`).
    Tapping a pick adds it, through the same `Kati.Screens.AddTitle.track/2` a search hit goes through, and the poster ticks. A pick already on the shelf is never suggested; one already added is not added twice; a refused add is drawn rather than swallowed. The tap exists only on a pick that names a title, so the board's three stay untappable — which is also why `Kati.ScreenTapSweepTest` cannot see it and `Kati.DiscoverFeedTest` covers it instead.
    Verified on the Pixel_9a: tap Emergence → tick → back → the shelf reads `7 titles` with Emergence on it.

    **A person's row** still carries no tap, and there is no person to open. See the moduledoc.

---

### 12 — Lists (`Kati.Screens.Lists`)

Fixture (`load/1` :80 → `Sample.lists()`). One control, and it writes nothing.

15. **I open Lists with no lists.**
    Steps: Home → **Library** → **Lists**.
    Expect: an empty state and a way in. What you get: `7 lists · 2 ranked`, three fanned made lists (Best of 2026 / Rainy Sunday / Recommended by Jo), four kept lists with counts (Wishlist 12, Rewatches 9, Abandoned 3, Owned on disc 22).
    Status: `[!] known broken — seven lists on a device that has never made one.`

16. **I tap `+` to make a list.**
    `add_list/1` (:390) prepends `%{title: "New list", count: "0 titles", badge: nil, seeds: []}` to the socket and bumps the subtitle's first number. There is no name field, no `Ash.create`, and no resource.
    Expect: a naming sheet, then a stored list.
    Status: `[!] known broken — creates an unnamed row in memory; lost on back.`

17. **I tap `+` twice.**
    Two rows both titled `New list`, subtitle now `9 lists · 2 ranked`.
    Status: `[!] known broken — indistinguishable duplicates.`

18. **I tap `Best of 2026` to see what is in it.**
    Nothing. The moduledoc states the rows are untappable on purpose because the detail screen was never drawn.
    Status: `[!] known broken — chevrons on the four kept rows in particular are affordances for a screen that does not exist.`

19. **I go back and return.**
    The list I made is gone; the subtitle is `7 lists` again.
    Status: `[!] known broken — no writer anywhere in lib/.`

Worth noting for the fix: two of the four kept lists are one query each — `Abandoned` is `TrackedTitle` at `status: :dropped`, `Rewatches` is a `Watch` with a `rewatch_number`. They would be the cheapest true rows on the page.

---

### 13 — What fits? (`Kati.Screens.WhatFits`)

Reachable (Library → ⋯ → **What fits?**), fixture (`load/1` :87 → `Sample.tonight()`), and **entirely inert** — `grep -n 'on_tap\|handle_tap' lib/kati/screens/what_fits.ex` returns nothing across 424 lines. Five window buttons, four mood chips, three play discs, the `Tomorrow` defer pill and the overflow disc: all pictures.

The board's own caption is *"Set the window you actually have and the library filters itself"*.

20. **I have forty minutes. I open What fits? and tap `45m`.**
    Steps: Home → **Library** → **⋯** → **What fits?** → tap **45m**.
    Status: `[x] verified on device 7 September` — the window, the count, the list and the over-budget row all move together. Three Severance episodes at 44m, 44m and 41m, under *3 EPISODES FIT*.

21. **I tap `30m` to shorten the evening.**
    Status: `[x] verified on device 7 September` — down to one 7m episode, and the film row recomputes its `MIN OVER`. `2h+` widens it to an 80m episode.

22. **I tap `Tense` instead of `Light`.**
    Status: `[x] resolved 7 September — the chips are gone over a real list.` Nothing could ever have answered them: `mood` has no column anywhere (`CachedTitle.genres` is a genre, `Watch.tags` is written after the fact). The finding's own suggestion, taken — removed rather than left as dead controls — and the whole row goes with them rather than leaving a gap. Board 13 keeps all four, which is what it is a drawing of. The `Tomorrow` pill and the overflow disc go the same way and for the same kind of reason.

23. **I tap a row.**
    Status: `[x] verified on device 7 September` — it opens the show, or the film on the over-budget row, with a back pill reading `What fits?`.

23. **I tap `Tomorrow` on the over-budget row.**
    Expect: a scheduled reminder or a calendar event. Reality: nothing (`defer_pill/1` :396).
    Status: `[!] known broken.`

24. **It is 9pm on a Sunday; the card says `Sunday, 21:40`.**
    A literal in `WhatFits.Sample.tonight/0`. `Kati.Time` could answer this today and the moduledoc says so.
    Status: `[!] known broken — the one value on the page a user will check against their own clock.`

The moduledoc is worth quoting to whoever fixes this: since `CachedEpisode` landed, `41m`/`43m`/`44m` (per-episode `runtime_minutes`), `S3 · E2` (`for_title/2`) and `3 episodes fit` are all **derivable today**. Only the mood row is genuinely blocked. Wiring the five window buttons to a `:window` assign and deriving the list is the single highest-value fix in this group.

---

### 05 — New releases (`Kati.Screens.Inbox`)

The best-engineered page here — five reads, episodes split by `Release.airing/2`, a seven-day window with its reasoning written down, bells armed through `Release.alarm_for/3` so a muted show and a vague date both draw the hollow bell — and **you cannot get to it, and nothing on it can be pressed.**

**Reachability.** The only English push of `Kati.Screens.Inbox` is `home.ex:1311`, from the `New this week` hero. `new_this_week(nil)` draws a Spacer (`home.ex:641`), and `hero_summary/0` (`:331`) answers `nil` unless `Inbox.releases/0` returns a non-empty `out_now` — which needs a followed title with an unticked episode aired in the last seven days, which needs TMDB episodes, which needs the key. The bell at `home.ex:1323` goes to `InboxNotifications`, not here. `routes.txt` confirms it empirically: the BFS with a populated store reached 05 only through the Persian Home.

**Controls.** `grep -n 'tap' lib/kati/screens/inbox.ex` returns nothing across 816 lines. `Mark all` (:502), the `Watch` pill on every Out now row (:694) and the `settings` gear on the watcher card (:591) are all drawn without taps. The tap-sweep carries a comment at `screen_tap_sweep_test.exs:328` saying Mark all "joined this group the round it was wired" — the comment is orphaned, the entry is gone, and the file's own stale check would have failed on a phantom, so the tag is genuinely no longer drawn.

25. **I want to see what is new. I look for the inbox.**
    Steps: ⚠️ `Settings → Every screen → 05`. From Home there is no door on a normal device.
    Status: `[!] known broken — ROUTE MISSING in English.`

26. **I follow a show, an episode airs today, I open Home.**
    Expect: the `New this week` hero appears with `Open inbox`. This is the one path that works — and it needs the API key, because without episodes in `CachedEpisode` `out_now` is always empty.
    Status: `[?] unknown — test with a key entered on Settings → Data sources.`

27. **I am in the inbox and tap `Mark all`.**
    Expect: one `Kati.Media.Watch` per Out now row, the section empties, the subtitle recounts. The moduledoc describes exactly this behaviour as if it shipped.
    Status: `[x] verified on device 7 September` — two rows, one tap, `0 out now`. Drawn without a tap when the list is empty, which is the smallest case of the gesture rather than a failure of it.

28. **I tap `Watch` on one release.**
    Status: `[x] verified on device 7 September` — the row leaves the list and the subtitle recounts. The tick is a `Kati.Media.Watch` through the same `write_tick/2` screens 04 and 34 use, carrying the season and number off the columns.

29. **I tap the gear on the cream watcher card.**
    Expect: screen 25. Status: `[x] verified on device 7 September` — *Release watcher · Watching 2 titles*, back pill `Inbox`.

30. **The route, walked.** With an episode aired into the window on a followed show, Home draws **NEW THIS WEEK · 1 new episode is waiting** with *Open inbox*, and it opens 05. The English door is not missing — it is **conditional**, and the condition is the thing the screen is about. See #1, which is about a device with nothing new having no way to look.

30. **I read the watcher card.**
    `Watching for 24 titles · checked 18:02` — all three values are `Kati.Library.Sample`'s, on every device, deliberately (the moduledoc argues that one live number beside two frozen ones is worse than three frozen ones). The count IS queryable today (`TrackedTitle`'s `:followed` read).
    Status: `[!] known broken — a card that reports on background work, reporting fiction.`

31. **I follow one show that has nothing out this week.**
    `releases/0` returns a real map with an empty `out_now`, so the screen correctly shows `Out now · 0` — and `Coming up` is `coming_up_rows/0`, three hardcoded rows (`The Long Hollow — S2E6 · Lumen+ · 20:00`, `Vellum · In cinemas`, `Nightbirds — Season 2 · Full season drop`) laid over the real map by `drawn_inbox/0` (:167). So one half of the page is honest and the other half is the drawing, in the same scroll.
    Status: `[!] known broken — mixes the user's empty list with three invented dated rows.`

---

### 25 — Release watcher (`Kati.Screens.ReleaseWatcher`)

Reachable two ways (Home → bell → **Release watcher**; Settings → **Release watcher**). Every control moves on screen. **Nothing is stored and nothing is consumed.** `load/1` (:50) reads `Kati.Settings.WatcherSample`; `handle_tap/2` (:256) only ever calls `Mob.Socket.assign(socket, :watcher, …)`; `grep -rn 'WatcherSample' lib/` finds no reader outside this file.

The cadence is the sharpest case, because there IS a background engine. `Kati.Background.Periodic` runs at `@interval_minutes 6 * 60` (`periodic.ex:60`) with a two-hour flex, enqueued with KEEP at boot (`app.ex:196`) — a compile-time constant that never reads this screen.

32. **I want alerts less often. I tap `Daily`.**
    Steps: Home → **bell** → **Release watcher** → tap **Daily**.
    Expect: the watcher runs daily. Reality: the segment lights, the assign moves, `Periodic` still runs every six hours.
    Status: `[!] known broken — a control that renames nothing.`

33. **I tap `Manual`, meaning stop checking.**
    Same. `Periodic.cancel/0` exists and is never called from here.
    Status: `[!] known broken.`

34. **I tap `Every 6h`, the one already selected.**
    Status: `[ ] untested` — `{Kati.Screens.ReleaseWatcher, :"cadence_Every 6h"}` is in `@inert_taps` as an ordinary already-selected member. Not a defect.

35. **I turn `Price drops` on, go back, come in again.**
    Off again — `pop` restores the saved socket and re-entering re-runs `load/1` off the Sample.
    Status: `[!] known broken — the same for all ten switches and the master switch.`

36. **I turn `Push notifications` on.**
    Nothing arms. `Kati.Notifications.QuietHours` states 23:00–08:00 as a struct default and says in its own words that the window is "configurable because it is a user setting", with nowhere for the configuration to live.
    Status: `[!] known broken — a notification preference that no delivery path reads.`

37. **I turn the cream banner off — the master switch.**
    The switch flips and no background work stops.
    Status: `[!] known broken.`

38. **I read `Watching 24 titles · 3 FOUND THIS WEEK`.**
    Both frozen. The first is derivable today from the same `:followed` read screen 05 uses.
    Status: `[!] known broken.`

---

### 92 — My services (`Kati.Screens.MyServices`)

The only page in the group that both reads and writes, and the one worth the most attention. Region is real (`Mob.State`, `Services.region/0`). Rules are real writes (`Services.toggle_rule/1`). `Something else` is a real create with a real refusal path (`save_service/1` → `Write.note/2`, empty field → *Nothing to save yet.*, duplicate name → `{:ok, existing}` with nothing written, case- and space-insensitive). `Kati.ServiceWriteTest` covers all of it.

Everything around that write is where it goes wrong.

39. **Fresh phone. Home says `No subscriptions yet`. I tap it.**
    Steps: Home → **My services**.
    Expect: agreement. What you get: `Subscribed · 3` — Lumen+ £8.99, Orbit £13.99, Kino £11.49 — plus `Free with ads` with two more, plus a Money row reading `£46.47 A MONTH`.
    Proof: `home.ex:1036` `services_line(%{count: 0}), do: "No subscriptions yet"` over the live `Kati.Services.subscribed_count/0`; `my_services.ex:101` falls back to `Sample.subscribed()`. Home's own moduledoc names this bug and fixes it on one side only.
    Status: `[!] known broken — two screens, one tap apart, giving opposite answers about the same table.`

40. **I type `mubi` into the search field.**
    Expect: the list narrows; nothing matches; the sentence screen 95 wrote appears — *No service called that. Kati uses JustWatch's list through TMDB. If it is a real service they do not track, add it as Something else.*
    Reality: the field holds what you type (that part works — `handle_info({:change, :service_query, …})` :608) and the list below it does not move. `content/1` (:147) hands `query` to `search_field/1` and to nothing else. 95's sentence is drawn on 95 and nowhere in the app.
    Status: `[!] known broken — a search field that searches nothing.`

41. **I tap `Something else` with `mubi` still typed.**
    Expect: Mubi appears in Subscribed with a blank price, the eyebrow count goes to 1, the field clears. That happens. But: the fixture's three services **vanish** while `Free with ads` still shows Aria Free and Dispatch, and the Money row now reads `1 service` beside `£46.47 A MONTH` — a live count against a frozen total for four services you never had.
    Proof: `my_services.ex:101` and `:110` are two independent per-tier fallbacks; `money_group/0` (:505) composes `length(subscribed())` with `Sample.monthly_total()` (`services/sample.ex:51`).
    Status: `[!] known broken — the recurring defect: the user's row on one card, the fixture's on the next.`

42. **I tap `Something else` with nothing typed.**
    *Nothing to save yet.* appears under the row, in red, and clears on the next keystroke. This works and is well done.
    Status: `[ ] untested — expected to pass.`

43. **I add `Mubi` twice.**
    Second tap answers `{:ok, existing}` and writes nothing (`already_listed/1` :700, case- and space-insensitive). No second row, no second charge.
    Status: `[ ] untested — expected to pass.`

44. **I change my mind and want Mubi off the list.**
    There is no way. `handle_tap` (:584) answers `"edit_service_" <> _name` with `{:noreply, socket}`. All five drawn rows are in `@inert_taps` with the stated reason "no per-service editor is drawn anywhere in the set". You cannot remove, rename or price a service, and once one row exists you can never get the fixture list back either.
    Status: `[!] known broken — a write with no undo.` (Board 95 specifies the missing control: a price lozenge and a 46×28 switch on each row.)

45. **I tap `Hide titles I can't watch`, which promises to change three screens.**
    The switch flips and stores (`Mob.State`). Nothing reads it. `grep -rn 'Services.rules()\|hide_unavailable' lib/` finds only the screens that draw the switches — no reader in `discover.ex`, `up_next.ex` or `what_fits.ex`.
    Status: `[!] known broken — a sub-line naming three consequences, none of which exist.` Same for `Count rentals as available` and `Count purchases as available`.

46. **I tap `Show all 47 · Everything JustWatch lists for the UK`.**
    You land on **screen 93** — a board titled *My services* that says `Subscribed · none yet` and `Pick your country · Nothing works until this is set`, to a user who has three services and a country. It is a reference board wired into the live flow.
    Proof: `my_services.ex:568` pushes `Kati.Screens.MyServicesEmpty`. There is no catalogue screen anywhere in the app.
    Status: `[!] known broken — wrong destination, and the right one does not exist.`

47. **I tap the Money row.**
    Screen 23. Correct destination, wrong figure — see 23.
    Status: `[!] known broken (downstream).`

48. **I add a service and then open a film to see where to watch it.**
    Nothing changes, and nothing can. `Kati.Screens.Film`'s `where_section/1` (`film.ex:748`) is `def where_section(%{where: []}), do: []` — on a real title the entire *Where to watch* card, eyebrow and all, is omitted, because no resource holds an offer. The card only draws on the fixture.
    Status: `[!] known broken — the page 92's own caption exists to make true (*"makes availability… true rather than decorative"*) cannot consume anything 92 writes.` Needs an offers resource per `{title, service, region}`.

---

### 94 — Country picker (`Kati.Screens.CountryPicker`)

A sheet, correctly. It reads `Services.region/0`, ticks the current row, writes through `put_region/1` and pops. The write is real and `Kati.ServicesTest` covers it.

49. **I switch from United Kingdom to Iran.**
    Steps: Home → **My services** → the country row → **Iran**.
    Expect: the sheet closes and the row underneath now reads Iran with the Iranian flag.
    Reality: the sheet closes and **the row still says United Kingdom**. `pop` restores the saved socket without re-running `mount`/`load` (`deps/mob/lib/mob/screen.ex:571`), and 92's region row is drawn from `assigns.region`, read once at mount (`my_services.ex:93`, `:180`). The value IS stored — leave 92 and come back and it is right — but the screen you are looking at lies until you do.
    Note the asymmetry that makes this visible: the *service list* on the same page refreshes, because `content/1` calls `subscribed/0` at render time rather than from assigns.
    Status: `[!] known broken — stale region on the page that just changed it.`

50. **I look for a country not in the list.**
    The field says `Search 190 countries` (:85) over exactly seven rows — GB, IR, US, DE, FR, NL, AU (`services.ex:48`). Tapping the field does nothing (`{Kati.Screens.CountryPicker, :search}` is in `@inert_taps`).
    Status: `[!] known broken — placeholder promises 190, list holds 7, field does not filter.`

51. **I open the picker, change my mind, and tap the ✕.**
    Closes without writing. Correct.
    Status: `[ ] untested — expected to pass.`

52. **I change my country and then check my library.**
    The footnote's promise — *it never touches your library, ratings or history* — is true of the code: `put_region/1` writes one `Mob.State` key and touches no resource.
    Status: `[ ] untested — expected to pass.` Verifying this on device is worth doing precisely because it is the fear the copy addresses.

---

### 93 — My services, nothing set up (`Kati.Screens.MyServicesEmpty`)

Not a reference sheet in practice — it is 92's `Show all 47` destination, and therefore a live page. It should not be one.

53. **I get here with three services already set up.**
    Steps: Home → **My services** → **Show all 47**.
    You read: *Subscribed · none yet*, *Pick your country — Nothing works until this is set*, *Nothing to add up yet*.
    Status: `[!] known broken — a board about day one, shown on day fifty.`

54. **I tap `Pick your country` from here.**
    It pushes the real `Kati.Screens.CountryPicker` (:390) and writes the device's real region. A specimen board changing the app's actual availability setting.
    Status: `[!] known broken — a reference page with a live side effect.`

55. **I flip a rule switch on 93.**
    It moves and is deliberately socket-only (`flip/1`, :430 — the comment explains: a board about defaults must not become somebody's settings). So the switches on 92 and 93 disagree with each other and only one of them stores.
    Status: `[!] known broken — two pages, same three controls, different semantics.`

56. **I tap `Show all 47` on 93.**
    Screen **23**, the money ledger (:393). And `Nothing to add up yet` two rows below it (:396) also goes to 23. Two visually distinct rows, one destination, neither of them a catalogue.
    Status: `[!] known broken.`

---

### 23 — Subscriptions (`Kati.Screens.Subscriptions`)

Fixture (`Kati.Subscriptions.Sample`), listed as permanently sample-only in `screen_sample_only_test.exs:81`. Two controls work; both are socket-only.

57. **I open Subscriptions from My services.**
    Steps: Home → **My services** → **Subscriptions**.
    You get `£46.47 · Every month`, `Up £4.00 since March — Orbit raised its price`, four services (Lumen+ £8.99 / £0.21/h, Orbit £13.99 / £2.33/h, Kino £11.49 / £0.60/h, Aria Audio £5.00 paused), regardless of what is on the account. Its back pill reads **‹ Stats** while you arrived from My services.
    Status: `[!] known broken — fixture ledger, and a back pill naming a screen you did not come from.`

58. **I add a service on 92 and come here.**
    Nothing changes. 92 owns the prices and says so on screen — *this screen owns these prices; 23 reads them — edit here, and cost per watched hour follows* — and 23 reads nothing.
    Status: `[!] known broken — the ownership sentence is a promise the code does not keep.`

59. **I tap `Dismiss` on the Worth-a-look card.**
    The card and its eyebrow go. Back and return: they are back.
    Status: `[!] known broken — socket-only; correct behaviour otherwise.`

60. **I tap `Remind me 23 Aug`.**
    The button changes to its secondary treatment and **nothing is scheduled** — the moduledoc says so outright: `Kati.Notifications.Scheduler` is a planned child of the supervisor and is not built.
    Status: `[!] known broken — a reminder button that arms no reminder.` The screen is honest about it in its docs and not on the device.

61. **I tap the `⋯` disc.**
    Nothing. Recorded in `@inert_taps`' Backlog section as `{Kati.Screens.Subscriptions, :open_menu}` with the reason that 23.html contains one `more_horiz` and no menu anywhere in the export.
    Status: `[!] known broken — inert by admission.`

---

### 95 — My services, states (`Kati.Screens.MyServicesStates`)

⚠️ `Settings → Every screen → 95`. Correctly gallery-only (`app_reachability_test.exs:94`), correctly untappable (no `handle_tap/2` at all — the moduledoc explains that a live `Undo` here would change the device's real region).

Its value to this pass is as a **specification of five things screen 92 cannot do**, all of which are findings against 92 rather than against 95:

- *Search with no match* — 92's field does not filter and never draws the sentence (scenario 40).
- *Provider list unavailable* — 92 has no offline state at all.
- *Region changed*, with `Got it` / `Undo` — 92 has neither, and cannot even refresh its own region row (scenario 49).
- *Removed service* — there is no way to remove one (scenario 44).
- *Region set, no services* — 92 cannot enter this state, because it falls back to fixtures (scenario 39).

The sheet also records that 92 is behind its **own** board on two counts: the service rows should carry a price lozenge and a per-service switch, and 92 draws neither. That is the change that unblocks the price editor, removal, and screen 23's real total in one go.

62. **I open 95 to check what 92 should look like mid-query.**
    Steps: ⚠️ `Settings → Every screen → 95`.
    Status: `[ ] untested — renders as drawn; nothing on it taps, by design.`

---

### 96 — Nothing set up, the knock-on (`Kati.Screens.NothingSetUpKnockOn`)

⚠️ `Settings → Every screen → 96`. Correctly gallery-only (`app_reachability_test.exs:140`). Four bands showing what screens 08, 11, 13 and 23 look like before any service is set up. Every band's button carries the tag `:my_services` and pushes screen 92 — the one working thing about it, and it works.

The file states its own defect plainly: *"the predicate cannot answer `false` today: 92 falls back to `Kati.Services.Sample` when the store is empty, so the four screens that would ask this question need that fallback to become conditional before any of them can put these bands on screen."* `set_up?/0` asks `Kati.Screens.MyServices.listed/0` and is called by nothing.

So all four of these empty states are drawn once, in a place a user will never look, and cannot appear in the four places they belong. Fixing 92's fallback (scenario 39) is what turns this board into four shipped empty states — and lets it be deleted from the gallery, which is what the user asked for.

63. **I open 96 and tap any of the four `My services` buttons.**
    Steps: ⚠️ `Settings → Every screen → 96` → any band's button.
    Expect and get: screen 92. `handle_tap/2` is one clause for all four (`:368`).
    Status: `[ ] untested — expected to pass.`

---

### The order I would fix these in

1. **92's fallback gate** — one change, and it fixes the Home/92 contradiction (39), the half-fixture page after a write (41), and unblocks all four of 96's bands so 96 can be deleted.
2. **Wire screen 10.** Six `on_tap`s and one extra key in `cold_data/2`. `DropSheet` already writes; `Film`/`Series` need the referent param that MISSING-CONNECTIONS Phase 1 is already about. This is *"the screen the whole app is for"* and it currently cannot be touched.
3. **A door to 05**, then its three taps. The page underneath is already correct.
4. **13's window buttons** — the data is there since `CachedEpisode` landed; five taps and a derived list turn a picture into the feature.
5. **92's price lozenge and per-service switch** (board 95's own spec) — gives removal, gives 23 a real total, gives `Something else` somewhere to put a figure.
6. **94 → 92 refresh**, one line.
7. **Delete or rewire `Show all 47` on both boards**, and take 93 out of the live flow.
8. **25's cadence** — either drive `Periodic.ensure/1` or stop drawing four segments that rename nothing.
9. **11, 12, 23** — these need resources (a recommender, a list table, a price with hours). Until then their inert controls should be removed rather than left drawn, and their fixture counts should not ship to a device.

---

## Bringing titles in, and what the year says about them

Two structural facts decide most of this group; everything below leans on them rather than re-deriving them.

**A. Nothing in the import flow ever opens a file.** `lib/kati/import/` contains exactly one file, `sample.ex`. No Ash resource models a file, a column mapping, an outcome or a conflict queue. Screens 140 → 141 → 37 are three drawings of a job that does not exist. This is *not* a missing fence: `Kati.Native.Files.pick/2` works and `Kati.Screens.Restore` calls it (`lib/kati/screens/restore.ex:1297`). Every scenario below about "a file that does not exist" or "a file with two titles" is therefore unwalkable — you cannot get as far as choosing a file.

**B. Screen 07 genuinely reads the store — and the only thing that can ever fill it is a series episode tick.** `Kati.Screens.Stats.entries/0` (`lib/kati/screens/stats.ex:874-945`) is a real read of `Kati.Media.Watch` joined to `TrackedTitle` and `CachedTitle`. But the only `Ash.create` of a `Watch` anywhere in `lib/` is `Kati.Screens.Series.write_tick/2` (`lib/kati/screens/series.ex:1308-1319`). A film cannot be marked watched anywhere in this app: `Kati.Screens.Film`'s "Log a watch" pushes `Kati.Screens.Rating` with only `tracked_title_id` (`film.ex:922-930`, `rating.ex:362`), and `Kati.Screens.Rating.save_watch/1` is `Ash.update` only — with no `watch_id` it returns `{:error, :nothing_to_save}` and the sheet says "Nothing to save yet." (`rating.ex:1487-1503`).

---

### 140 — Import: where are you coming from (`Kati.Screens.ImportSources`)

**Route:** Home → tap **Settings** → scroll to Data → tap **Import**. Real, confirmed in `routes.txt`.
**Reads:** the `@commonest` module attribute — a build constant, not a fixture and not the store. Correct as-is.
**Writes:** nothing. No picker, no job.
**Controls:** all ten tap and all ten navigate. None is inert.

The defect is where they go. `handle_tap/2` (`import_sources.ex:393-396`) matches `"source_" <> _id` and **discards the id** — all six tiles push the same screen 141, which is a Goodreads *books* board. "Five more sources" and "Something else" both push screen 37, which is a fixed Trakt CSV (`import_sources.ex:406-409`). So four of the six named film/TV sources (Letterboxd, Trakt, MyAnimeList, AniList) lead to a board about books.

1. **I pick Letterboxd, because that is where my films are.**
   Steps: Home → **Settings** → **Import** → tap the **Letterboxd** tile (`letterboxd-export.zip`).
   Expect: the system file picker opens, filtered as far as SAF allows; I choose my export; Kati reads it and tells me what it found.
   Actual: no picker. Screen 141 pushes, headed **Goodreads**, `goodreads_library_export.csv`, `418 ROWS · 9 COLUMNS`, mapping *Author*, *Bookshelves*, *Number of Pages*.
   `[!] known broken — the tile id is parsed off the tag and then thrown away; every tile lands on the same books board.`

2. **I pick Trakt, and the filename on the tile said `.json`.**
   Steps: as above, tap **Trakt**.
   Expect: a JSON reader, or at minimum a screen that says "Trakt".
   Actual: identical Goodreads board. Note the tile promises `trakt-export.json` and screen 37 — one step later — calls the same job `trakt-backup.csv`. The two literals contradict each other inside one flow.
   `[!] known broken — same as 1; plus the `.json` / `.csv` contradiction between 140's tile and `Kati.Import.Sample.job/0`.`

3. **I want Simkl, so I open "Five more sources".**
   Steps: Home → **Settings** → **Import** → tap **Five more sources**.
   Expect: five more tiles, one of them Simkl.
   Actual: pushes straight to screen 37, mid-job on a Trakt file. There is no fifth-source list anywhere. Also the row's own sub-line reads `Simkl · TV Time · Libib · Last.fm · AniList` — AniList is already a tile in the grid above, so "five more" names four new sources.
   `[!] known broken — the row is a navigation stub, not a list; and its copy repeats AniList (kept deliberately, `import_sources.ex` moduledoc).`

4. **My tracker isn't listed, so I use "Something else" to map my own CSV.**
   Steps: Home → **Settings** → **Import** → tap **Something else** ("Any CSV — map the columns yourself").
   Expect: a picker, then the manual column mapper against *my* headers.
   Actual: screen 37 with somebody else's five columns already mapped. Nothing on 37 lets me change a mapping.
   `[!] known broken — the one honest destination in the grid still shows a fixture.`

5. **I actually have a Kati backup, not another tracker's export.**
   Steps: Home → **Settings** → **Import** → tap the top card **A Kati backup** ("goes to Restore instead").
   Expect: `Kati.Screens.Restore`, which really does open the picker.
   Actual: exactly that. This is the only tap in the whole import flow that reaches working machinery.
   `[ ] untested — expected to pass.`

6. **I back out and come in again.**
   Steps: from 141 press the **Settings** back pill, then tap **Import** again.
   Expect: nothing remembered (there is nothing to remember) and no crash.
   `[ ] untested`

---

### 141 — Import: recognised (`Kati.Screens.ImportRecognised`)

**Route:** 140 → any source tile. Confirmed in `routes.txt` (`… > go_Import > source_goodreads`).
**Reads:** `Kati.Import.Sample.recognised/0` — a fixed Goodreads book export, identical on every device.
**Writes:** nothing.
**Controls:** two, and both navigate — `Check the mapping` → screen 37 (`import_recognised.ex:582-584`); `Not Goodreads? Change` → `pop_screen` (`:586-588`). The board also draws a black **Import 412** pill top-right and it has **no `on_tap` at all** (`import_recognised.ex:353-370`) — the confirm button of the whole import flow is decoration, and because it carries no tag the tap sweep cannot even report it.

`test/design/screens/141.html` contains the word "Goodreads" four times and the words Letterboxd, Trakt, film, movie and TV **zero** times. There is no drawn "recognised" board for a film or TV source anywhere in the design set.

7. **The screen says Goodreads and I tapped Letterboxd.**
   Steps: Home → **Settings** → **Import** → **Letterboxd** tile.
   Expect: "This looks like a Letterboxd export", the columns it found, and the two ways out — which is exactly what screen 142 draws and nothing reaches.
   `[!] known broken — see 1. The wrong-guess state exists as art (142) and is gallery-only.`

8. **I press the big black "Import 412" button.**
   Steps: on 141, tap the **Import 412** pill.
   Expect: 412 rows written, or a progress state.
   Actual: nothing. No handler, no tag, no accessibility id.
   `[!] known broken — the pill carries no `on_tap` (`import_recognised.ex:353-370`).`

9. **I open "Check the mapping" to see the nine columns.**
   Steps: on 141, tap the row **Check the mapping — 7 matched · 2 skipped · still editable**.
   Expect: the same nine columns, editable.
   Actual: screen 37 pushes with a *different job* — `trakt-backup.csv`, five columns (`title`, `watched_at`, `rating`, `type`, `show_notes`). The summary I just tapped counted nine. Neither screen shares a job, because there is no job.
   `[!] known broken — 141 draws `Sample.recognised/0` and 37 draws `Sample.job/0`; the two are unrelated maps.`

10. **I decide "Publisher" should not be skipped.**
    Steps: on 141, scroll to *Mapping — expanded*, tap the **Publisher → Skip** row.
    Expect: a field picker.
    Actual: the row is not a control. The summary above it says "still editable" and nothing on either screen edits anything.
    `[!] known broken — the screen's own moduledoc calls this "the one promise on this board the app does not keep".`

11. **I press "Not Goodreads? Change".**
    Steps: on 141, tap the **Not Goodreads? Change** pill.
    Expect: back to the source grid with my file still held.
    Actual: `pop_screen` — from 140 that happens to land on the grid, which reads right. It would be wrong from anywhere else, and no file is held either way.
    `[ ] untested — passes by coincidence of the only route in.`

12. **The step meter and the step label disagree.**
    Steps: look at the top of 141 — five bars, three filled — and read the mono line: `STEP 1 OF 4`.
    Expect: one number.
    Actual: two, and `Kati.Import.Sample.recognised/0` documents that both are kept on purpose.
    `[!] known broken — 3-of-5 bars under a "STEP 1 OF 4" caption.`

---

### 37 — Import (`Kati.Screens.Import`)

**Route:** 140 → **Five more sources** or **Something else**; 141 → **Check the mapping**. Reachable.
**Reads:** `Kati.Import.Sample.job/0` — a fixed Trakt job, step 3 of 4, five columns, one of six conflicts.
**Writes:** nothing.
**Controls:** `grep -c on_tap lib/kati/screens/import.ex` returns **0**. Every control on this page is a picture: the **Import 412** pill, the four step bars, and the three conflict answers *Keep mine / Take file / Keep both* (built from `MishkaToggle` with no `on_tap`, `import.ex:choice/1`). Because none carries a tag, none appears in `@inert_taps` — the sweep is blind to this whole screen.

13. **I answer the conflict: keep my ★4, not the file's ★5.**
    Status: `[x] wired 7 September` — the pill goes ink, the card advances, and the answer is held on the socket until the write. Nothing is lit until you say something: a default answer to a question about destroying a rating is the one thing this card exists to avoid, and the fixture lit *Keep mine*.

14. **I use "apply to all" because six is a lot.**
    Status: `[x] wired 7 September` — and it is not tappable until you have answered one, because *apply to all* means *this answer, to all of them*, and a blanket answer to a question nobody read is how an import quietly destroys a rating. The fixture's own note said so.

15. **I press "Import 412" to commit.**
    Status: `[x] verified on device 7 September` — with a real Letterboxd export: **Import 3** → *3 added.* → Arrival, Blade Runner 2049 and Paddington on the shelf, finished, with their ratings. On the board the pill carries no tap at all: committing the drawing would file four hundred invented films under the reader's own shelf.

16. **I import a file that disagrees with nothing, which is the ordinary case.**
    Status: `[x] fixed 7 September — it killed the screen.` `conflict/1` drew `job.conflict` unconditionally and `conflict_poster/1` raised a `BadMapError` on `nil`, so the process died and the reader was thrown back to Home. Every test that rendered 37 used the fixture, which always has a conflict. The band is dropped with the card now, eyebrow and all.
    `[!] known broken — no `on_tap` anywhere in the file; `lib/kati/import/` holds only `sample.ex`.`

16. **I leave and come back mid-job.**
    Steps: from 37 press the **Settings** back pill, then **Import** → **Something else** again.
    Expect: my job where I left it — step 3, conflict 2 of 6.
    Actual: step 3 of 4, conflict 1 of 6, forever. The screen is drawn mid-job and there is no job.
    `[!] known broken — the same fixture on every entry.`

17. **The file it names is not a file I have.**
    Steps: read the file card on 37: `trakt-backup.csv · 418 ROWS · 9 COLUMNS`, with a green tick.
    Expect: my file's name and my file's shape.
    Actual: a green check-circle asserting a file was successfully read that was never opened. This is the most actively misleading thing on the page.
    `[!] known broken — a success affordance over a fixture.`

---

### 142 — Import: source states (`Kati.Screens.ImportStates`)

**Route:** ⚠️ **none.** In the NOT-REACHED half of `routes.txt`. Only `Settings → Every screen → 142`.
**Reads:** literals typed into the screen (deliberately, so a sibling's private attribute cannot break it).
**Writes:** nothing. **Controls:** none — the module defines no `handle_tap/2` at all, on purpose (`import_states.ex` moduledoc, "Nothing on this board taps").

This is the only place in the entire app that names a **Letterboxd** export, and it is a picture. It is also the answer to "what should happen when the guess is wrong", and nothing can produce a wrong guess because nothing guesses.

18. **The wrong-guess state, which the app cannot reach.**
    Steps: ⚠️ `Settings → Every screen → 142`. `ROUTE MISSING` — belongs on 141 when the file's columns do not match the tapped tile.
    Expect (once real): after tapping Goodreads and choosing a Letterboxd file, the cream card *"You picked Goodreads and that file is not one"*, the grid back underneath, **Pick again** live.
    `[!] known broken — unreachable, and both buttons (**Use Letterboxd instead**, **Pick again**) are drawn without taps.`

19. **The partial-columns state.**
    Steps: ⚠️ `Settings → Every screen → 142`, scroll to *Partial columns*. `ROUTE MISSING`.
    Expect (once real): an old export that lacks *Date Read* imports anyway, with the consequence named.
    `[!] known broken — unreachable.`

---

### 36 — Auto-detect (`Kati.Screens.AutoDetect`)

**Route:** Home → **Settings** → Sources group → **Auto-detect**. Reachable, confirmed in `routes.txt`.
**Reads:** `Kati.Settings.DetectSample`, whole. Every string — `3 sources`, `41 EPISODES TICKED FOR YOU`, *The Long Hollow* `S2E6 · LUMEN+ · APPLE TV` at 74%, `Apple TV · 28 ticks`, `Chromecast · 13 ticks`, `Tick at 90%`, and the *"Marram E3" or "Marram Grass"?* question — is a literal. There is no resource for the master switch, the per-source switches, the tick counts, the threshold, a playing session, or the unsure-match queue.
**Writes:** nothing.
**Controls:** twelve are drawn; **two** work.
- Works: the **Music** segment → screen 150 (`auto_detect.ex:handle_tap(:music, …)`); the **Browser extension** row → `Kati.Screens.RetiredTile` (`:open_retired`).
- Inert with a tag: **TV & film** segment — `{Kati.Screens.AutoDetect, :tv}` is in `@inert_taps` (`test/kati/screen_tap_sweep_test.exs:302`), reason given: *"there is no second state for a screen to move to when you tap the mode you are already in"*. Fair.
- Inert with **no tag at all**, so invisible to the sweep: the cream banner's master switch, the *Apple TV*, *Chromecast* and *This phone* switches, the *Tick at* chevron row, the *Ask before ticking* and *Ignore* switches, and all three decision pills. `Kati.Screens.AutoDetect.tap/1` returns `nil` for every title except "Browser extension"; `SettingsList.switch/1` and `MishkaToggle` here carry no `on_tap`.

Detection itself does not exist. Worth writing down once: `Kati.Media.Watch` has no provenance column — `driven_by` (`watch.ex:135`) is a story preference (`:character | :both | :plot`), not "detected vs tapped" — so `41 EPISODES TICKED FOR YOU` cannot be derived even if detection landed.

20. **I turn auto-detect on, because ticking every episode by hand is the thing I want to stop doing.**
    Steps: Home → **Settings** → **Auto-detect** → tap the switch in the cream **Detect what you play** card.
    Status: `[x] verified on device 7 September` — and it does the thing. The switch is `Kati.Media.Detect.on?/0` in `Mob.State`, so it survives leaving the screen and restarting the app, and off means nothing is looked at at all.

21. **I have not allowed it to look yet.**
    Status: `[x] verified on device 7 September` — the page says so, in three places rather than pretending: `not allowed to look yet` under the title, `NOTHING TICKED FOR YOU YET` in the banner, and `Needs notification access — tap to allow` on the one source Kati has. The row opens the system page, because there is no runtime dialog for a notification listener and a switch that could not grant anything would be the lie one row down.

22. **Something plays and it is on my shelf.**
    Status: `[x] verified on device 7 September` — a real Chrome media session named *Paddington*, past 95%, written as a `Kati.Media.Watch` with `detected: true`, counted in the banner as `1 EPISODE TICKED FOR YOU`. The same session a minute later writes nothing: a play sits above the threshold for the whole of its last ten minutes, and a detector that wrote on each pass would file forty watches for one evening.

23. **Something plays and it is not.**
    Status: `[x] verified on device 7 September` — *“A Film Nobody Keeps” — is that something you keep?* under **NEEDS A DECISION**, with **Add it** (which opens the add sheet already searching for it) and **Not mine**, which forgets it and takes the card with it. Nothing is added to the shelf by a detector, ever: a browser tab with a mistyped name is not a film somebody keeps.

21. **I turn Chromecast off because it keeps ticking my flatmate's shows.**
    Steps: on 36, tap the **Chromecast** row or its switch.
    Expect: off, and its 13 ticks stop.
    Actual: nothing. Same for Apple TV and This phone.
    `[!] known broken — `tap/1` returns `nil` for every source row but "Browser extension".`

22. **90% is too late for me; I want 80%.**
    Steps: on 36, under *Rules*, tap **Tick at — 90% watched** (it draws a chevron).
    Expect: a picker.
    Actual: nothing. The chevron promises a page that does not exist.
    `[!] known broken — a chevron with no destination.`

23. **Auto-detect asks me a question and I answer it.**
    Steps: on 36, scroll to *Needs a decision* — *"Marram E3" or "Marram Grass"?* — tap **The film**.
    Expect: the pill goes ink, a `Watch` is written against the film, the card empties or shows the next question.
    Actual: nothing moves; "The series" stays lit because the fixture says so. This is the card the whole screen is arranged around.
    `[!] known broken — the three pills are `MishkaToggle` with no `on_tap` (`auto_detect.ex:choice/2`).`

24. **Something is playing right now — is it really?**
    Steps: on 36, look at *Now playing*: *The Long Hollow*, `S2E6 · LUMEN+ · APPLE TV`, `Live`, 74%, `41:02 / 55:00`.
    Expect: what is actually playing, or the section absent.
    Actual: a fixture with a green **Live** badge on a device playing nothing. Nothing anywhere in the app holds a session in flight.
    `[!] known broken — `Kati.Settings.DetectSample.now_playing/0`, with a "Live" status pill over it.`

25. **I install the browser extension.**
    Steps: on 36, tap the **Browser extension — Not installed / Get** row.
    Expect: something honest.
    Actual: `Kati.Screens.RetiredTile` — "isn't in this version". Correct behaviour, and the model for the eleven rows above and below it.
    `[ ] untested — expected to pass.`

26. **I switch to Music and back.**
    Steps: on 36, tap the **Music** segment, then **TV & film** on screen 150.
    Expect: the pair round-trips.
    `[ ] untested`

---

### 07 — Your year (`Kati.Screens.Stats`), the film and series half

**Route:** dock **Stats**. A root; always reachable.
**Reads: the store, for real.** `figures/0` → `entries/0` reads `Kati.Media.Watch` with `tracked_title` loaded and joins `CachedTitle` by `{source, source_id}` (`stats.ex:874-945`). With no watches, `year` is `nil` and the page draws board 101's *"Not much to show yet"* card plus *More numbers* — no invented hero, no grid, no count cards. That empty branch is correct and is covered by `Kati.ScreenStatsEmptyTest`. **This is the answer to "does Your year count what the user marked watched or a fixture": above the fold it counts the user. Below the fold it does not, and above the fold the numbers cannot move.**

Six defects, in order of how hard they bite:

- **Time watched is 0h 0m for every series a user actually ticks.** `minutes` comes from `CachedTitle.runtime_minutes` (`stats.ex:900`), and `Kati.Media.Tmdb.upsert_title/3` maps only `body["runtime"]` (`tmdb.ex:187`) — TMDB's `/tv/{id}` has no `runtime` field, it has `episode_run_time`. The per-episode runtime *is* cached, on `CachedEpisode.runtime_minutes` (`tmdb.ex:245`), and Stats never reads it. `Kati.ScreenStatsTest` passes because its fixture sets `runtime_minutes: 47` on the TV title by hand (`screen_stats_test.exs:299-301`).
- **Films can never be counted at all** — fact B above. The `84 Films` card reads `0` on any real device.
- **`Recently watched` says "SERIES · 2h ago", never "S2 E5 · 2h ago".** `write_tick/2` writes only `tracked_title_id`, `episode_source_id`, `watched_at`, `watched_on` (`series.ex:1308-1319`) — never `season_number` / `episode_number` — so `recent_label/1` falls past its two episode clauses to the kind clause (`stats.ex:1091-1100`). The test fixture sets both numbers explicitly (`screen_stats_test.exs:303-310`).
- **The recurring mixing defect, twice.** *Where the hours went* is `Sample.year().breakdown` unconditionally (`stats.ex:965`) — real hours in the hero, fixture Drama `128h` / Documentary `71h` / Comedy `49h` bars underneath, which sum to more hours than the headline on any real device. *More numbers*' second lines (`1,204 entries`, `4 active · 12-day best`, `£46.47 a month · 7 expenses`) are `Kati.Stats.Sample.more_numbers/0` whenever the year is counted (`more_numbers(true)`).
- **A first year reads "↑ 0%".** `change(_now, 0), do: 0` and `rising?: change >= 0` (`stats.ex:983`) — so year one shows a green up-pill saying `0%` against a comparison that does not exist. The moduledoc claims this branch reports 100%.
- **A falling year still draws a green pill.** The pill's background is `Palette.green_wash()` and its text `Palette.green_text()` unconditionally (`stats.ex:416, 424`); only the arrow flips (`arrow/1`). A year down 40% is a green pill with a down arrow in it.

27. **Fresh phone, I open Stats.**
    Steps: dock → **Stats**.
    Expect: *Not much to show yet* + *"Your year is counted from what you tick off. Mark one thing watched and this page starts filling itself."*, the share disc still live, and five *More numbers* rows with no second lines. Store unchanged.
    `[ ] untested — expected to pass; this branch is the best-built thing in the group.`

28. **I follow that instruction and mark one thing watched.**
    Steps: from the empty Stats card, try to do what it says — dock **Library** → a film → **⋯** → **Log a watch** → set stars → **Save**.
    Expect: a `Watch` row; Stats leaves the empty state.
    Actual: the Rating sheet opens on `Kati.Rating.Sample`'s *Blue Hour* and Save answers "Nothing to save yet." Nothing is written; Stats stays empty forever.
    `[!] known broken — no path in the app creates a film watch (fact B). The empty state's own instruction cannot be carried out for a film.`

29. **I tick five episodes of a series, then open Stats.**
    Steps: dock **Library** → **Quietus** (series) → tick five episodes → dock **Stats**.
    Expect: `~4h`, `0 Films / 1 Series`, five lit squares, `longest streak — 1 night`, and three *Recently watched* rows reading `S1 E3 · just now`.
    Actual: **`0h 0m`** in the hero (series `runtime_minutes` is nil), `1 Series` correct, squares correct, streak correct, and the recent rows read **`SERIES · just now`**.
    `[!] known broken — two proven bugs: nil TV runtime, and a tick that stores no episode numbers.`

30. **I keep ticking all year and check my hours.**
    Steps: dock **Stats**, read *Time watched*.
    Expect: hours that grow.
    Actual: `0h 0m` beside a green `↑ 0%` pill and a contribution field full of lit squares — a grid that says "you watched a lot" over a figure that says "you watched nothing".
    `[!] known broken — the grid and the headline are computed from the same rows and cannot both be right.`

31. **I read the genre bars.**
    Steps: dock **Stats**, scroll to *Where the hours went*.
    Expect: my genres, from my titles.
    Actual: `Drama 128h`, `Documentary 71h`, `Comedy 49h`, `Thriller 38h`, `Everything else 26h` — identical on every device, and 312 hours' worth of bars under a `0h 0m` headline. `CachedTitle.genres` is one free-text column with no separator, which is the stated reason nothing parses it.
    `[!] known broken — fixture below real data, the group's signature defect.`

32. **I read the "More numbers" figures.**
    Steps: dock **Stats**, scroll to *More numbers*.
    Expect: my counts, or no second line.
    Actual: on any device with one tick, the fixture's second lines reappear whole — including `£46.47 a month · 7 expenses` for a user who has entered no money at all. (On the empty device they are correctly suppressed, which makes this the one page in the app that is *more* honest when it has less data.)
    `[!] known broken — `more_numbers(true)` draws `Kati.Stats.Sample`'s subs.`

33. **I tap through the More numbers rows.**
    Steps: dock **Stats** → tap **Activity log**, back, **Habits**, back, **Nutrition**, back, **Goals**, back, **Money**.
    Expect: five pushes. These five rows are the app's only route to those screens outside the gallery.
    `[ ] untested — expected to pass (`@destinations`, `stats.ex:1131-1138`).` Note the map also holds a `"Recently watched"` key that `more_numbers/1` explicitly rejects — dead entry.

34. **My year was worse than last year.**
    Steps: needs a store with more watched minutes in the previous January–August than this one; then dock **Stats**.
    Expect: a red or neutral pill, down arrow, e.g. `↓ 22%`.
    Actual: a green pill containing a down arrow.
    `[!] known broken — pill colours are unconditional (`stats.ex:416, 424`).`

35. **I open Stats in March and read the grid against the header.**
    Steps: set the device clock to March, dock **Stats**.
    Expect: the header range and the grid to describe the same span.
    Actual: the header says `Jan – Mar 2026` (`range/1`) while the field is the last 182 days ending today (`contributions/1`, `stats.ex:1043`) — mostly *last* year, labelled `26 weeks`.
    `[?] unknown — worth one look on device; the two are simply different spans.`

36. **I press the share disc.**
    Steps: dock **Stats** → tap the circular **share** disc, top right.
    Expect: screen 98 with *my* year in it.
    `[!] known broken — see 37 below.`

---

### 98 — Your year, shared (`Kati.Screens.YearShare`)

**Route:** Stats → share disc (`stats.ex:1145-1146`). Reachable.
**Reads: `Kati.Stats.ShareSample`, entirely.** `312h 40m`, `↑ 18%`, `2026`, and the three top titles *The Long Hollow / Blue Hour / The Cartographer* with their poster seeds. Not one figure on this page comes from the store — including on a device where screen 07, one tap back, has just drawn the user's real numbers. Its subtitle is the literal `JAN – AUG 2026` while 07's header is the device clock, so on any phone whose clock is not August 2026 the two pages disagree about what year is being shared.
**Writes:** nothing.
**Controls:** six scope chips, two aspect segments, one privacy switch, **Save image**, and a `Share…` label.

- **The five non-resting scope chips are the worst kind of inert: they move an assign that nothing reads.** `handle_tap/2` sets `:scope` (`year_share.ex:373-376`), and `:scope` is consumed only by `scopes/1` to decide which chip is lit. The card is built from `card(assigns.aspect)` (`year_share.ex:63`). `@inert_taps` only lists `scope_All` and `aspect_square` as "already-selected" (`screen_tap_sweep_test.exs:583-584`) — the sweep sees an assign change and passes the other five. Screen 102's own moduledoc names this: *"the scope chips, which relight over a card that does not follow them — that is 98's small untruth"*.
- **The privacy switch is the same shape.** `:hide_private` toggles (`year_share.ex:364-365`) and is read only by `privacy_row/1` to draw the switch. The card never loses a title.
- **The aspect segments do work** — `scale/1` re-sizes the preview's type by 1.0 / 1.25 (`year_share.ex:124-200`).
- **"Save image" does not save an image.** It pushes `Kati.Screens.YearCards` (`year_share.ex:370-371`) — a reference sheet. `Kati.Native.Files.save_screen/1` exists and works, and `Kati.Screens.WeekImage` already calls it (`native/files.ex:271`, `week_image.ex:1072`); the sweep file records this as the last stubbed save in the app, *"one call away"* (`screen_tap_sweep_test.exs:807-809`).
- The card's change arrow is a hardcoded `arrow_drop_up` even though `ShareSample.hours/0` carries a `direction` key.

37. **I share my year and it is not my year.**
    Steps: dock **Stats** → share disc.
    Expect: my hours, my top three titles, my span.
    Actual: `312h 40m`, `↑ 18%`, and three titles I may not own — beside a page that just told me the truth.
    `[!] known broken — the whole page is `Kati.Stats.ShareSample`.`

38. **I only want the screen half, so I tap "Screen".**
    Steps: on 98, tap the **Screen** chip (or **Books**, **Music**, **Meals**, **Habits**).
    Expect: the card recomputes to that scope.
    Actual: the chip lights; the card is identical, still headed *Time watched*. Tapping **Books** leaves a card of film hours.
    `[!] known broken — `:scope` is written and never read (`year_share.ex:63, 373-376`).`

39. **I switch to Story because I post to stories.**
    Steps: on 98, under *Aspect*, tap **Story**.
    Expect: a taller card, larger type.
    Actual: type scales by 1.25 — the preview really does change. Working.
    `[ ] untested — expected to pass.`

40. **I hide the titles I marked private.**
    Steps: on 98, flip **Hide titles I marked private**.
    Expect: a hidden title replaced by a locked paper slot (which is exactly what board 101 draws).
    Actual: the switch flips; the three posters are unchanged.
    `[!] known broken — `:hide_private` is written and never read.`

41. **I press "Save image".**
    Steps: on 98, tap the black **Save image** button.
    Expect: a PNG in my gallery, or the system save dialog.
    Actual: the system save dialog, with `kati-year-2026.png` in it.
    `[x] fixed 6 September — `handle_tap(:save_image, …)` calls `Kati.Native.Files.save_screen/1` and reports a refusal inline; it used to push screen 100. MOVIES-AND-TV.md #80, pinned by `Kati.YearShareSaveTest`.`

42. **I press "Share…".**
    Steps: on 98, tap **Share…**.
    Expect: the system share sheet, with the card in it.
    Actual: the system share sheet, with `kati-year-2026.png` in it.
    `[x] fixed 8 September — the chip named `K-20 file-transport`, which had already shipped `ACTION_SEND`; `Kati.Native.Files.share_screen/1` joins it to `K-45 capture-screen` the way `save_screen/1` does, and `WHEN FILE SHARING LANDS` is retired in `Kati.DesignLiterals.retired_lines/0`. MOVIES-AND-TV.md #142.`

---

### 102 — Your year, shared, dark (`Kati.Screens.YearShareDark`)

**Route:** ⚠️ **none.** NOT REACHED in `routes.txt`. Only `Settings → Every screen → 102`.
**Reads:** `Kati.Stats.ShareSample` + `Kati.Stats.Sample.contributions/0`. **Writes:** nothing.
**Controls:** every tap delegates to screen 98's handlers (`year_share_dark.ex:619-626`), so it inherits all of 98's defects, including the inert scope chips — which its own moduledoc concedes.

It is **not just a colourway**, and that is the finding. `Kati.Theme.Palette.mode/0` reads `Mob.Theme.current()` at render time (`palette.ex:507-512`), so screen 98 already draws itself dark on a dark device. What 102 actually adds is **two card faces 98 never previews** — the contribution field and the genre bars. Those two faces exist nowhere a user can reach in light mode.

43. **I look at what my card will look like in dark mode.**
    Steps: ⚠️ `Settings → Every screen → 102`. `ROUTE MISSING` — 98 should render this itself under a dark theme.
    Expect: the same page, dark.
    Actual: a *different* page — four faces instead of two.
    `[!] known broken — unreachable, and a superset of the screen it claims to mirror.`

---

### 100 — Year cards (`Kati.Screens.YearCards`)

**Route:** Home → **Settings** → About group → **Year cards**. Reachable, confirmed in `routes.txt`. Also the (wrong) destination of 98's **Save image**.
**Reads:** `Kati.Stats.ShareSample` — four faces at two ratios, all fixture. Correct for a spec sheet.
**Writes:** nothing. **Controls:** none — `handle_tap(_tag, socket), do: {:noreply, socket}` (`year_cards.ex:342`), deliberately.

This page is fine *as what it is*: a render spec, filed under About beside *Every screen*, the app describing itself. Its only defect is inherited — it is where a button labelled **Save image** lands.

44. **I go looking for how a shared card is drawn.**
    Steps: Home → **Settings** → **Year cards**.
    Expect: eight pictures, no controls, nothing claiming to be my data.
    `[ ] untested — expected to pass.`

45. **I pressed Save image and ended up here.**
    Steps: dock **Stats** → share disc → **Save image**.
    Expect: a saved file.
    Actual: this spec sheet, with no save button on it and no way to complete the act I started.
    `[!] known broken — see 41.`

---

### 101 — Year cards, states (`Kati.Screens.YearCardsStates`)

**Route:** ⚠️ **none.** NOT REACHED in `routes.txt`. Only `Settings → Every screen → 101`.
**Reads:** `ShareSample.top_titles/0`, `ShareSample.field_face/0`, `Kati.Music.Sample.tone/1`. **Writes:** nothing.
**Controls:** none anywhere — no `on_tap` in the file and no `handle_tap/2` at all (`year_cards_states.ex:154-156`), including on the **Show me the card full-screen** button (`:427, :480`).

Two things make this board more than decoration. Its first band, *Not enough data*, is the board screen 07's empty state was built from — that reuse is real and correct. Its fifth band, *Save not supported yet*, is the copy the app is supposed to show instead of a dead save button — and it names the wrong missing capability.

46. **The not-enough-data card, which does have a home.**
    Steps: ⚠️ `Settings → Every screen → 101`, band 1. `ROUTE MISSING` — but its decision is already honoured live on screen 07 (dock **Stats** on a fresh phone), which is where it belongs.
    `[ ] untested`

47. **The "save not supported yet" card, whose reason has expired.**
    Steps: ⚠️ `Settings → Every screen → 101`, band 5. `ROUTE MISSING` — this is what **Save image** on 98 should show if it cannot save.
    Expect: an honest failure naming the real gap.
    Actual: the copy says nothing turns a rendered node tree into image bytes. `Kati.Native.Files.save_screen/1` does exactly that and `Kati.Screens.WeekImage` already ships it (`native/files.ex:271`, `week_image.ex:1072`). The honest-failure state is itself now dishonest, and the button it explains should simply be wired.
    `[!] known broken — stale capability claim on the board that exists to be honest about capability.`

48. **The private-title state.**
    Steps: ⚠️ `Settings → Every screen → 101`, band 3. `ROUTE MISSING` — should be what 98's **Hide titles I marked private** switch produces.
    `[!] known broken — the switch that would produce it is inert (see 40).`

---

### Removal from Settings — nothing in this group qualifies yet

The user's rule is that a page comes out of `Settings → Every screen` once it fully works. In this group that gate is not met by any page, and three of them are *only* in that list. The three genuine Settings rows here — **Import**, **Auto-detect**, **Year cards** (`lib/kati/screens/settings.ex:681-706`) — are real destinations and should stay; **Year cards** in particular is filed under About as self-description and is not scaffolding. The gallery entries `140`, `141`, `142`, `101`, `102` (`lib/kati/screens/gallery.ex:135-179`) all still need to be there, because 142, 101 and 102 have no other door at all.

---

# The defect list, worst first

**147 findings**, every one traced to a line, and every one carries a closing verdict
naming the function and the line — so this list can be read rather than re-derived.

Three are closed *partly*, and each says in its own section what is left and what it is
waiting on: **#51** (screen 14's short page, waiting on a board), **#133** (three of
board 307's four release shelves, waiting on a producer — Books and Music are
[#100](https://github.com/mishka-group/kati/issues/100) and
[#101](https://github.com/mishka-group/kati/issues/101), which are blocked on a free
API being chosen at all), and **#136** (a medication's days, filed as
[#102](https://github.com/mishka-group/kati/issues/102) and not this section's).

The table below is the first 137 and is not extended: findings 138-147 landed after it
and are read in their own sections. It also carries one duplicate row — `103` appears
twice — which is a defect in the table rather than in the app.

| # | Page | Severity | What is wrong |
|---|---|---|---|
| 1 | 05 New releases | `fixed` | ~~There is no route to screen 05 in English.~~ Fixed 7 September with the first of the finding's three options: a **New releases** row in Settings, beside **Release watcher**, because they are the two halves of one subject — 25 is what Kati watches for and 05 is what it found. Home's hero is still the fast door when there IS something out this week; the row is the door that does not depend on there being. Walked on the Pixel_9a: Settings → **New releases** → *0 out now · 0 coming up*, which is the sentence the page existed to say and could not be reached to say it. |
| 2 | 101 Year cards — states (Kati.Screens.YearCardsStates) | `fixed` | ~~The board whose job is to name honestly why a card cannot be saved names a capability that has since shipped, and it is gallery-only so nobody sees the correction.~~ Fixed 7 September. The first half was already true — #80 wired 98's **Save image** to `Kati.Native.Files.save_screen/1` — so what was left was a moduledoc still saying *nothing turns a rendered node tree into image bytes* and a board nobody could reach to read it. Both are answered: the paragraph now says what band 5 is a picture OF (a device whose capture call refuses, which `save_screen/1` reports and 98 draws inline as a refusal — a whole board for a failed button press is a worse answer than the sentence beside the button), and screen 100 carries the row onto it. 100 is the one page in the app already about how a card is drawn, and 101 is about the states of that card, so the door goes there rather than as a second Settings entry beside the first. Walked on the Pixel_9a: Settings → Year cards → **When a card cannot be made** → *FIVE STATES*. |
| 3 | 102 Your year, shared — dark | `fixed` | ~~The dark share board is gallery-only, yet it is not a colourway — it draws two card faces that screen 98 never previews, so those faces are unreachable in light mode.~~ Fixed 7 September by taking the finding's own fix: **102 is deleted** and screen 98 has both faces. It was never a colourway — `Kati.Theme.Palette.mode/0` reads the theme at render time, so 98 has always drawn dark on a dark device — and what 102 held was the contribution field and the genre bars. Both are on 98's card now and both are the READER's: the grid is `Kati.Screens.Stats`'s own 26 weeks and the bars are their own genres (#45), where 102's were `Kati.Stats.Sample`'s. The board is kept, in `test/design/retired/`, which is the third case beside `incoming/` — a drawing whose screen was deleted on purpose, with a README saying why. Walked on the Pixel_9a: *Every day* and *Where the hours went* are on the card, at this reader's own figures. |
| 4 | 142 Import — source states (Kati.Screens.ImportStates) | `fixed` | ~~The only board in the app that handles a wrong source guess, an unrecognised file, or a partial export is reachable only from the gallery, and every control on it is drawn without a tap.~~ Fixed 7 September, by #5's route: ship what the board is a drawing OF rather than route the drawing. `Kati.Import.Job.read/2` had always had three refusals to report — `:unreadable`, `:empty`, `:unrecognised` — and screen 141 swallowed all three into `Kati.Import.Sample.recognised/0`, so a reader who handed Kati a photo was shown somebody else's Goodreads export and told it had 418 rows and nine matched columns. 141 now draws the refusal INSTEAD of the board, in board 142's own card and red `error` glyph, naming the file and which of the three it was, with `Pick again` live back to the picker — the control board 142 draws inert. *Wrong guess* is the second state: `Kati.Import.Mapping.looks_like/1` reads the header vocabulary each service is alone in using (`Letterboxd URI`, `Bookshelves`, `Trakt Rating`), and when it disagrees with the tile that was tapped 141 says so in gold `help` above an otherwise intact board — mapping is by column name, so the file still reads, and `books?/1` is what makes a books export under a films tile say *but a books export has no watches in it* rather than the milder line. Fixed alongside: screen 140's tile ids are ATOMS, `source_name/1` matched strings only, and so every real import through the picker was headed **CSV**. Walked all three on the Pixel_9a — a junk CSV under Letterboxd refuses and `Pick again` lands back on the grid; `letterboxd-watched.csv` under **Trakt** reads *This looks like a Letterboxd export* and still imports; a Goodreads export under Letterboxd adds the books sentence; and the right tile with the right file is unchanged — no band, **Import 2** → *2 merged.* 142 stays in the gallery, as 143 does, because it is a specimen sheet of states you go and look at. |
| 5 | 143 Episode rows — the rating column | `fixed e44d44d` | ~~Screen 143 is reachable only from Settings > Every screen.~~ Fixed 6 September, by shipping what it is a drawing OF rather than by routing the drawing: `Kati.Screens.Series.rating_column/1` and its twin on 34 draw the numeral-and-one-star column beside every aired episode, reading the same watch rows the ticks come from, and a tap on it opens screen 144 over that episode. 143 itself is a specimen sheet — the same rows before and after the edit, side by side — and was already on `Kati.AppReachabilityTest`'s `@no_route` inventory as *"a board about a change to 04, not a screen beside it"*; that entry now records that the change has shipped. |
| 6 | 147 Selection & filters at 235% | `fixed` | ~~A picture-only specimen with no route in and no live control, whose back pill names Library.~~ Fixed 7 September by the finding's second option — *move its findings into 146 as real 235% behaviour* — which became possible when 146 was built. The sheet states one split and 146 broke half of it: **`4 selected` carries no cap**, because the board's own caption names it as the one thing that bar exists to say, and both its lines carried `max_lines={1}` — so at the largest text size the count and the sentence under it were the first two things to lose their ends. And **the close glyph caps**, because it is chrome whose size carries structure and a glyph that grew with the text would push the count off its own bar. 147 stays as the specimen it is, in 27's manner, like 91 for search and 133 for backup; its moduledoc no longer says 146 is unbuilt. |
| 7 | 148 Drop, DNF & abandon | `fixed` | ~~Screen 148 can only be opened from Settings > Every screen; nothing in the app pushes it, despite its own moduledoc claiming it is 'pushed under Settings'.~~ Fixed 7 September, by giving it the row its own moduledoc and its own back pill both already claimed. Filed under About beside **Year cards**, which is the identical case and carries the argument in its own comment — a reference sheet rather than a place in the app, the app describing itself. It is where the one distinction Kati makes about a shelf is written down: *Paused and Dropped are things a person decided; Gone cold is something Kati noticed.* Walked on the Pixel_9a: Settings → **Dropping** → *Five states, three media*. |
| 8 | 152 Anime | `fixed` | ~~No route in, and its back pill names a screen it cannot be reached from.~~ Fixed 7 September. The finding's own fix — *fold its rule into a real Library filter once TrackedTitle gains an override* — is done: the override exists (#104), `Kati.Media.Anime` is the board's three rules, and screen 03 grows the fifth chip 152 draws, appearing at the board's own threshold (`Kati.Media.AnimeSample.promote_threshold/0`, read rather than retyped) and dropped below it, because a `0` chip on a shelf with no anime is a section nobody asked for. The board is kept and given the Settings row its own back pill always claimed, beside **Dropping** and **Year cards** — the argument is where the rule is written down now that the rule exists, which is what those two rows are for. Walked on the Pixel_9a: Settings → **Anime** → *FOUR EDITS, ONE SENTENCE*. |
| 9 | 153 Numbering — inherited and overridden | `fixed` | ~~Screen 153 explains the Aired/Absolute numbering choice and nothing pushes it — including screen 34, which draws that choice as a three-tile strip a user will want explained.~~ Fixed 7 September with the finding's own fix: a `help` disc beside the order strip on screen 34. A disc rather than a note row, because the strip is a row and a note under it would read as a caption on the season rather than on the choice — and it is drawn only where the strip is, since a season that can offer one order has no choice to explain. Walked on the Pixel_9a: Severance → ⋯ → Episode order → the disc → *A DEFAULT THAT ANNOUNCES ITS OWN REASON*. |
| 10 | 87 Search typing / 89 Result states / 91 Search at 235% | `fixed` | ~~Three reference sheets reachable only from the developer gallery, two of which name back destinations that cannot reach them.~~ Fixed 7 September, by the rule this round settled everywhere else: ship what a sheet is a drawing OF and keep the sheet. All three subjects are live now. **87** — `nothing_yet/0` is rendered by 86 and by 19's waiting state, and has been. **89** — `nothing/2` is 19's no-match card, and its third band, the cross-scope row, went live with #117: *Nothing in Books. 1 match in Screen*, with the move behind it. **91** — its one finding is the chip that clips at 235%, which Kati cannot fix; filed as [mishka-group/kati#98](https://github.com/mishka-group/kati/issues/98). The three sheets stay in the gallery as the specimens they are, beside 142, 143, 147 and 148. |
| 11 | 03 Library | `fixed 9829477` | ~~The shelf is read once at mount and never refreshed.~~ Fixed 6 September: `Kati.Screens.Resume` tells the screen underneath a pop to re-read, using Mob's own `{:kati, …}` topic push. Verified on the Pixel_9a. |
| 12 | 03 Library | `fixed` | ~~Nothing can set a film or series status.~~ Fixed earlier this round: `Kati.Screens.Rating.finish_title/2` for a film and `Kati.Screens.Series.restate/1` for a series. Verified on the Pixel_9a — the shelf reads `Finished 1` with *Blade Runner · finished* on it. |
| 13 | 03 Library | `fixed` | ~~A film's progress rail can never be anything but empty.~~ Fixed earlier this round: `fraction_for/4` answers 1.0 for a watched film. Verified on the Pixel_9a — *Arrival · 100% watched* with a full rail. |
| 14 | 04 Series detail | `fixed ab15f39` | ~~A tick is lost when you switch seasons and come back.~~ Fixed 6 September: `restored/2` writes the flip into both lists. Verified on the Pixel_9a — the screenshot after S1→S2→S1 is byte-identical to the one before. |
| 15 | 06 Add a title (Kati.Screens.AddTitle) | `fixed` | ~~Two results with the same title are indistinguishable.~~ Fixed earlier this round: `row_key/1` names a TMDB row by its own id. Verified on the Pixel_9a — `dune` answers with Dune 2021 and Dune 1984 as separate rows. |
| 16 | 06 Add a title (Kati.Screens.AddTitle) | `fixed 64d9353` | ~~The Books shelf's + opens the films-and-series sheet.~~ Fixed 6 September: `Kati.Screens.Books` overrides `add_sheet/0` to screen 155's by-hand form. **And the Calendar half, 6 September:** the Schedule's `+` opens `Kati.Screens.QuickAdd`. No board said which door was right and board 18 does — *One field for the whole app* — and it became the right answer the moment #31 made that screen real. A `+` on the Schedule is somebody saying *something is happening*, and 18 is the screen that takes that sentence. |
| 17 | 07 Your year (Kati.Screens.Stats) | `fixed` | ~~The Films count can never be anything but 0.~~ Fixed earlier this round: `Kati.Screens.Rating.save_watch/1` creates the first watch of a film. Verified on the Pixel_9a — `2 FILMS`. |
| 18 | 07 Your year (Kati.Screens.Stats) | `fixed de61d14` | ~~Time watched reads 0h 0m however many episodes are ticked.~~ Fixed 6 September: the EPISODE's runtime is counted, which is where TMDB puts a series' duration. Device reads `8h 48m`. |
| 19 | 08 Film detail | `fixed` | ~~'Your rating' reads a column nothing writes.~~ Fixed earlier this round: `newest_rating(watches) || tracked.rating` reads the rating off the newest watch first. Verified on the Pixel_9a — rate four stars on 33, and 08 draws four. |
| 20 | 08 Film detail / 33 Rating | `fixed 9829477` | ~~A save on 33 is invisible on 08.~~ Fixed 6 September, by the same `Kati.Screens.Resume`. Verified on the Pixel_9a: rate four stars, save, and the card reads four stars over `SEEN 2 times`. |
| 21 | 08 Film detail / 33 Rating / 15 Activity | `fixed` | ~~No code path can create a title-level Watch.~~ Fixed earlier this round: `save_watch/1` gained a create clause, guarded by an `Ash.get` so it refuses when the named row is gone. |
| 22 | 10 Up next | `fixed` | ~~The first title added renders as a broken hero.~~ Fixed earlier this round by the artwork pipeline and `meta_for/4`. Verified on the Pixel_9a — *Fool Me Once* with its backdrop over `7 ready · 0 airing soon` and six real rows. |
| 23 | 10 Up next / 05 New releases / 11 Discover | `fixed` | ~~A title added from TMDB has no artwork anywhere.~~ Fixed earlier this round: `Kati.Media.Artwork` downloads at add time and the branch lives in `Kati.Design.Images.path/2`, so every caller gets it. Verified on the Pixel_9a across the shelf, Home, Up next and Discover. |
| 24 | 11 Discover | `fixed ca8f89e` | ~~The `Awards` chip empties the entire page.~~ Fixed 6 September: a real feed has one section and therefore one chip, and `chips/2` drops the rail rather than offering three chips over sections this device has none of. Board 11 keeps all four. |
| 25 | 144 Rate an episode | `fixed e44d44d` | ~~The screen can never display a real episode rating and cannot create one.~~ Fixed 6 September: a tick is the subject a verdict has not been left on yet, the stars are tappable, and Save writes — creating the watch when there is none, which is board 144's own *"rating an unwatched episode ticks it watched"*. It also gained the route it never had: screens 04 and 34 draw board 143's rating column beside every aired episode, and a tap on it opens the sheet over that episode. Verified on the Pixel_9a — Library → Severance → the star beside *The You You Are* → five stars → Save, and the series reads *4 of 9 watched* with a `5` in that column. |
| 26 | 145 Shelf filter sheet | `fixed` | ~~The sheet is fixture data and hands nothing back.~~ Fixed 6 September: the choice lives in `Mob.State`, the sheet writes it on every tap, and screen 03 re-reads through `Kati.Screens.Resume`. Verified on the Pixel_9a — Mystery narrows the shelf from 8 to 4 and every count moves with it. |
| 27 | 146 Shelf selection mode | `fixed c946a49` | ~~Selection mode operates on a fixture shelf and every action mutates assigns only.~~ Fixed 6 September: the grid is `Kati.Screens.Library.shelf/0`, Status writes the status, Remove destroys the tracked row, and Undo re-creates it from the `{source, source_id}` pair — then re-reads, because a created row has a new id. Verified on the Pixel_9a through Library → ⋯ → *Select titles*: Status takes the shelf from 8 in progress to 7, Remove takes Emergence off it, Undo puts it back. |
| 28 | 154 Add a title by hand (Kati.Screens.AddByHand) | `fixed` | ~~A save returns to screen 06's fixture list.~~ Fixed 6 September: `opened/2` resets to the title just written — 04 for a series, 08 for a film — which is what board 155 rules in, in as many words. `reset_to/3` rather than a push, because both screens behind are about typing a title that now exists. |
| 29 | 157 Add by hand — dark (Kati.Screens.AddByHandDark) | `fixed` | ~~None of the three text fields accept input, and Add to library writes the hardcoded fixture title into the user's real library.~~ Fixed 6 September: the screen opens in `Kati.Screens.AddByHand`'s resting state — board 155's *empty, Film, nothing assumed* — and board 157's captured frame moved to `Kati.ScreenDesignLiteralTest.drawn_state/0`. The fields type: the delegation stopped one clause short, so every `{:change, …}` fell through `Kati.Screens.Pushed`'s catch-all. Verified on the Pixel_9a. |
| 30 | 157 Add by hand — dark (Kati.Screens.AddByHandDark) | `fixed` | ~~Opening this board from the gallery leaves the entire app in dark mode until the next mount that reactivates the preference.~~ Fixed 6 September, for all seven dark boards at once: `Kati.Screens.Resume.pop/1` calls `Kati.Theme.activate/0`, which is the one place every back control in the app already goes through. `Kati.DarkBoardThemeTest` holds both halves — the board is dark while it is open, and the reader's own theme is back on the way out. Verified on the Pixel_9a. |
| 31 | 18 Quick add (Kati.Screens.QuickAdd) | `fixed 64d9353` | ~~The screen has no text field, no parser and no writer.~~ Fixed 6 September: `Kati.QuickAdd.Parse` reads a day, an hour, a duration and a reminder out of one sentence and everything else is the title; the clash is an overlap against `Kati.Calendars.Today.timed/1`; the commit writes a `Kati.Calendars.Event`. It does not guess — a sentence with no day is refused and the button says what is missing. An untyped field keeps board 18, which is drawn mid-typing and is the clearest statement of the syntax the screen has, and is also the field's placeholder. Verified on the Pixel_9a. |
| 32 | 19 Search | `fixed 2424112` | ~~The note card's highlight is computed against the normalised body and sliced out of the raw body.~~ Fixed 6 September: `Kati.Search.locate/2` searches in RAW coordinates, growing a window at each grapheme boundary until its normalised form is the normalised query — using `normalise/1` as the oracle rather than reimplementing the folding rules, so there is no second copy to drift. A note that matches only after normalisation draws unhighlighted rather than disappearing, which is what `binary_part/3` raising into `note_for/1`'s rescue used to do to the whole Notes group. `Kati.SearchHighlightTest` holds the six shapes that used to break it. |
| 33 | 58 سریال | `fixed` | ~~Marking an episode watched on the Persian page writes nothing.~~ Fixed 6 September: `episode_row/2` carries `source_id`, `season` and the integer `number` — the same three screen 04 lost once and for the same reason — and the tap goes through `Kati.Screens.Series.write_tick/2`, so a tick means one thing in both languages. A refused write draws a Persian sentence, not `Kati.Write.message/1`'s English one. Verified on the Pixel_9a in both languages: ۴ از ۹ → ۵ از ۹, kept across a pop, and 5 of 9 on the English page. |
| 34 | 91 Search at 235% | `fixed` | ~~The defect 91 was drawn to document is live on screen 19 and unfixed.~~ Fixed 6 September, in the three places board 91 names. The **scope chips wrap** instead of scrolling — `chip_rows/1`, balanced, three to a line, which is board 91's own layout — because *"a horizontal scroll at this size hides half the scopes behind a gesture"*, and it was hiding two of five at ordinary size too. A **hit's title wraps to three lines** and its sub-line to two, where both were `max_lines={1}`: *"a search result that clips the searched word has failed at its one job."* And the **query field grows with the query** — `min_height={52}` where a fixed `height` was clipping the reader's own words, descenders first. Verified on the Pixel_9a at `font_scale 2.35`. Residual: #132. |
| 35 | 92 My services / 93 nothing set up | `fixed 44445c1` | ~~The `Show all 47` row opens the wrong screen on both boards, and no catalogue screen exists anywhere in the app.~~ Fixed 6 September. Kati has no catalogue provider — `Kati.Services.Service` holds the services a person has told it about and nothing else — so 47 was the drawing's number and could never become anyone's. The row counts what Kati lists and says a fuller list needs a source it has not got: a statement, not a door, with no chevron and no tap on either board. A device with nothing stored still draws board 92's own words, and both are in `device_values/0` under patterns stricter than the frozen literals. Verified on the Pixel_9a. |
| 36 | 94 Country picker → 92 My services | `fixed` | ~~Picking a country leaves the page you come back to showing the old one.~~ Fixed 6 September: `Kati.Screens.Resume` plus a `handle_kati(:resumed, …)` on 92 that re-reads the region and the rules and keeps what the reader typed. |
| 37 | 03 Library | `fixed` | ~~A filter chip that matches nothing leaves a blank space.~~ Fixed 6 September: `nothing_here/2` draws a card with a sentence per chip, saying what would put a title there. Verified on the Pixel_9a. |
| 38 | 04 Series detail | `fixed` | ~~A hand-typed series opens as somebody else's show.~~ Fixed 6 September: `no_episodes/2` draws the reader's own row with an empty strip, and `episodes/1` draws a card saying why the list is empty. The gate is whether a ROW exists, not whether a provider has filled it in. |
| 39 | 04 Series detail / 34 Season | `fixed ab15f39` | ~~:save_error is assigned on both screens and rendered on neither.~~ Fixed 6 September: `refusal/1` on each draws it. |
| 40 | 04 Series detail → 34 Season | `fixed` | ~~Opening 'Episode order' from the drawn series shows a different Season 2 from the one on screen.~~ Fixed 6 September: board 04 draws `{{ ep.title }}` and names no episode, so `Kati.Library.Sample` had invented seven and nothing compared them to board 34, which does name them. 04's Season 2 is 34's now — same titles, same order, same dates, less the making-of, because a special is what 34's own switch is about and 04 draws no badge for one. `Kati.DrawnSeasonAgreementTest` holds it. Verified on the Pixel_9a with a real series behind both pages. |
| 41 | 06 Add a title (Kati.Screens.AddTitle) | `fixed ab15f39` | ~~Removing a TMDB title reports success and deletes nothing.~~ Fixed 6 September: `tracked_key/2` looks under the pair the row is actually stored on. |
| 42 | 06 Add a title (Kati.Screens.AddTitle) | `fixed ab15f39` | ~~Every write failure on screen 06 is silent.~~ Fixed 6 September: `save_notice/1` draws it, through the same `Kati.UI.notice/1` the search failure two lines above uses. |
| 43 | 06 Add a title (Kati.Screens.AddTitle) | `fixed` | ~~The sheet opens on four invented films.~~ Fixed 6 September: it opens on a card. Board 06 is drawn MID-QUERY, so its four results belong to that query — `Kati.ScreenDesignLiteralTest` compares them in the state the board was captured in, and `@quoted` holds the chrome that survives. |
| 44 | 06 Add a title (Kati.Screens.AddTitle) | `fixed` | ~~One or two characters restores the four fixtures.~~ Fixed 6 September: under the minimum the sheet says *Keep typing*, and clearing the field goes back to the resting card rather than to the drawing. |
| 45 | 07 Your year (Kati.Screens.Stats) | `fixed` | ~~Where the hours went is the fixture's.~~ Fixed 6 September: the bars are the reader's own genres, and the Activity row's `1,204 entries` is a real count. Finished 7 September. Two of the four remaining `More numbers` rows CAN be counted and are — `Kati.Goals.Goal` and `Kati.Money.Expense` are real resources, and the Money line reads `Kati.Screens.MyServices.monthly_total/0`, the same function screen 92's own Money row reads, so the two pages cannot disagree about what a month costs. The other two cannot: `Kati.Habits` is a `Sample` module and nothing else, and `Nutrition`'s *Cutting v3 · 86%* is a diet plan no column holds. Those two now draw **no second line at all** rather than somebody else's figures — the call #75 made on screen 92 and #58 on screen 15 — and the rows stay, because a row is the door to a page that exists and only the figure was nobody's. Walked on the Pixel_9a: **Goals · None set**, **Money · £19.49 a month** against the reader's own services, and Habits and Nutrition silent. |
| 46 | 07 Your year (Kati.Screens.Stats) | `fixed de61d14` | ~~Recently watched labels every tick 'SERIES'.~~ Fixed 6 September: `write_tick/2` writes the season and episode numbers the columns have always had. |
| 47 | 07 Your year (Kati.Screens.Stats) | `fixed de61d14` | ~~A first year draws '↑ 0%' and a falling year draws green.~~ Fixed 6 September: no comparison, no pill; and down is red on red. |
| 48 | 08 Film detail | `fixed` | ~~An untracked tile opens a page titled 'Blue Hour'.~~ Fixed earlier this round: the shelf lists only tracked rows and every tile carries its id, so `film/1` always finds the row the tile names. Verified on the Pixel_9a — the Blade Runner tile opens Blade Runner. |
| 49 | 10 Up next | `fixed` | ~~With a partly-real library the whole page reverts to fixtures.~~ Fixed 6 September for a paused shelf; finished 7 September for an empty one. `queue/0` fell back to board 10 whenever there was no `:watching` row AND nothing cold, so a reader who had finished everything they own was shown four invented titles, `12 ready` over four rows and `Gone cold · 3` over one. `shelf?/0` is the seam — a shelf holding dropped and finished titles IS a shelf, and its owner is told their queue is empty rather than shown somebody else's — and an empty DATABASE still draws the board, because `Ash.read!` raising mid-migration is a different fact and a page that dies is worse than one showing what it was drawn from. `empty/0` carries no eyebrow labels, and `cold_eyebrow/1` is what stops a heading standing over a section that is not there. The card offers the shelf, which is where starting something happens. |
| 50 | 11 Discover | `fixed ca8f89e` | ~~Discover is a fixture end to end — no `Kati.Media` read anywhere — and it prints six specific claims about the user: "Tuned to 128 titles", "Because you watched The Long Hollow", three match percentages, three people the app has never heard of, and "Leaving Lumen+ in 7 days" for a service that may not be on the account.~~ Fixed 6 September: the picks are TMDB's, keyed on the newest title the reader touched; the two sections with no resource behind them are empty and their headings, chips and the corpus-size line go with them. |
| 51 | 14 Series metadata | `fixed 5915c2a` | ~~Show details always describes The Long Hollow — a fixed synopsis, three ratings, four named cast members with character names, priced Where-to-watch rows and five tags — regardless of which series' overflow menu opened it. The push carries no subject and the screen would ignore one.~~ Fixed 6 September: the push names the row and the page reads it; the four bands with no resource behind them are dropped rather than borrowed. |
| 52 | 140 Import — where are you coming from (Kati.Screens.ImportSources) | `fixed` | ~~All six tiles push the Goodreads books board.~~ Fixed 6 September: `opens/1` sends the four film and TV sources to screen 37, which is a Trakt job. Neither board has an engine behind it; what changed is that a Letterboxd import no longer opens somebody's bookshelves. |
| 53 | 141 Import — recognised (Kati.Screens.ImportRecognised) | `fixed` | ~~'Check the mapping' promises the nine columns it just counted and pushes a screen showing five columns of a different file.~~ Fixed 6 September, the same shape as #40: the caller names its subject and `Kati.Import.Sample.job/1` answers with it. A `:source` atom rather than the job, which is what a real import would pass once a job is a resource. The Goodreads job is board 141's nine columns with the sampled value beside each — the reader's actual first record, which is the whole reason board 37 exists. Screen 140's six tiles join `@bare_pushes` with the reason. Verified on the Pixel_9a. |
| 54 | 145 Shelf filter sheet | `fixed` | ~~Opens already filtered and announces 418 titles.~~ Fixed 6 September: opens on nothing selected, counts the reader's own shelf, and offers that shelf's own genres. Decades are the reader's own since `first_release_year` landed on 6 September; services are still dropped, because nothing in Kati holds a catalogue. Verified on the Pixel_9a — a dated title gives a `2020s · 1` chip that narrows the shelf to it. |
| 55 | 148 Drop, DNF & abandon | `fixed` | ~~The sheet documents a :gone_cold the store cannot hold.~~ Fixed 6 September: four of the five ARE the column, and Gone cold is derived — which is what this board's own footnote argues for, *Gone cold is something Kati noticed*. `Kati.Media.Staleness` asks it on `last_touched_at` and this board's own four-month figure. |
| 56 | 149 Dropping — the sheet and after | `fixed` | ~~The sheet reads `status == :paused`, which nothing writes.~~ Fixed 6 September: it reads the derived Gone cold, and a NAMED push is taken whether or not Kati would have called it cold — screen 04's *Drop this show* is a decision the reader is making, not a suggestion the sheet may argue with. The announce-without-writing half is `c4cdb7b`. |
| 57 | 149 Dropping — the sheet and after | `fixed` | ~~The only write on 149 discards its result and rescues to :ok.~~ Fixed 6 September: `written/3` keeps it, `refusal/1` draws it, and `dropped?` follows the WRITE rather than the tap — the sheet no longer flips to its Dropped face over a refusal. |
| 58 | 15 Activity | `fixed` | ~~A reader whose watches are all older than this month sees the fixture.~~ Fixed 6 September: the gate is the whole history, not the two month-scoped groups, and an empty month says so. |
| 59 | 154 Add a title by hand (Kati.Screens.AddByHand) | `fixed` | ~~Year and Total episodes are typed and silently discarded.~~ Fixed 6 September: `typed_facts/1` parses both and `create_cache/3` writes them. Year needed a column — `Kati.Media.CachedTitle.first_release_year`, added in `20260906120000` — which also fills screen 14's meta line and gives screen 145's decade chips something to bucket by. |
| 60 | 156 افزودن دستی (Kati.Screens.AddByHandFa) | `fixed` | ~~The Persian form opens pre-filled with a fixture title.~~ Fixed 6 September: it opens empty, as screen 154 does. Board 156's typed title is a drawing of the form in use, not a default. |
| 61 | 19 Search | `fixed` | ~~Book results are drawn under SCREEN and counted by the Screen chip.~~ Fixed 6 September: `run/1` has a `:books` group, `Books` is a narrowable scope, and the screen draws it under its own heading. A book still has nowhere to go — screen 66 discards its params — so it draws no chevron, which is the honest shape for a hit with no door. |
| 62 | 19 Search | `fixed` | ~~Results are capped at three and the chips agree with the cap.~~ Fixed 6 September: the caps are gone and every match is drawn. `rows_per_group/0` stays as what BOARD 19 draws, which is what screen 88 is about. |
| 63 | 19 Search | `fixed` | ~~The idle page asserts a 180 ms debounce and seven counted queries.~~ Fixed 6 September: `Kati.Search.local_note/0` is about screen 19 — its own five scopes, and that every keystroke runs because the search is a scan of a local library. Board 88 keeps `counts_note/0`. |
| 64 | 19 Search | `fixed` | ~~The note card's eyebrow drops the date and the book.~~ Fixed 6 September: `note_eyebrow/1` composes all three, dropping a part that is absent rather than inventing it. |
| 65 | 19 Search | `fixed` | ~~A cache-only hit renders with a chevron that pushes screen 04 or 08 BARE.~~ Fixed 6 September: `hit_tag/1` refuses a row with no id, so the card is a card and not a door onto somebody else's title. |
| 66 | 23 Subscriptions | `fixed` | ~~Screen 23 is a fixture that quotes four services and £46.47 a month regardless of what is on the account.~~ Fixed 6 September: `Kati.Subscriptions.ledger/0` reads the account, gated whole. The hours are derived from `Kati.Media.CachedTitle.providers` rather than from `Kati.Media.Watch.service`, which nothing writes and nothing should — one service per watch, so a title on two never flatters both. A price can be entered at last: the field on screen 92 takes `Netflix 10.99`. The change line is absent rather than guessed, because Kati keeps no price history. The back pill says *My services*. Verified on the Pixel_9a — four services, £9.99 a month, and *You have watched nothing on Mubi this month. Pausing it saves £9.99 a month.* |
| 67 | 25 Release watcher | `fixed` | ~~The cream banner claims *Watching 24 titles · 3 FOUND THIS WEEK* on every device.~~ Fixed 6 September: both halves are counted. Finished 7 September by taking `design-briefs/D-64`'s own table at its word — it asks which consumer each of the fifteen controls would need and answers **yes** for exactly two. **The cadence** is stored and `Kati.App` asks WorkManager for it on every boot; `Kati.Background.Periodic.ensure/1`'s doc named this exact use — *a future "check less often" setting* — before there was one, and `Manual` asks for no periodic work rather than a very long interval. **New episodes** is the global gate over every title's `notify_new_episodes`, read by `Kati.Notifications.Sources.Media.followed/0`: off means Kati does not tell you about an episode however many shows you have followed. The other thirteen take the `not yet` mark screen 88 already uses (#74) and carry no tap, because the brief is right that persisting them would turn *forgotten* into *remembered and still inert*. `Kati.Screens.SearchSpec.not_yet_pill/0` is one object, not two that could drift. The brief's acceptance is met: no control on 25 changes something the app then ignores, and its named test block is now an assertion about the not-yet state. |
| 68 | 33 Rating | `fixed` | ~~A sheet pushed bare opens on the newest log anywhere in the library.~~ Fixed 6 September: `newest_log/1` refuses a push that names nothing, and the sheet falls to its drawing — the state it already documents as safe, since `save_watch/1` never commits the drawing. Screen 08's door passes `params_for/1`; the book and album doors have no media title to name and belong to a Books/Music decision. |
| 69 | 34 Season | `fixed` | ~~Two switches drawn ON over a list that does neither.~~ Fixed 6 September: season 0 is read, so *Include specials* is drawn in the state the list is actually in and says where they are — `Listed first, before the season`, because `in_order(:aired)` sorts by `{season, episode}` and re-sorting by air date would be the renumbering this screen's own footnote warns about. *Merge multi-part* is not offered: nothing records that a merge happened. Verified on the Pixel_9a. |
| 70 | 80 Data sources (Kati.Screens.DataSources) | `fixed` | ~~'Use my own key' breaks search with no way to supply the key.~~ Fixed 6 September: the chip reveals a token field, a Save that stores into `Kati.SecureStore`, and a line saying where to get one. `available?/0` is checked BEFORE the field is offered, which is the rule that module states. Verified on the Pixel_9a: paste → Save → *A token of yours is stored* → back to Kati's key → 16 results for `matrix`. |
| 71 | 80 Data sources (Kati.Screens.DataSources) | `fixed` | ~~The pairing card shows a constant code, a countdown that never counts down, and sends Hardcover and TheTVDB users to ListenBrainz's URL.~~ Fixed 6 September: the card keeps its shape and every slot is true — the site the token actually comes from (`:site` on `Kati.Sources`, one per provider), what connecting would bring, and that Kati cannot complete it yet. No code, and no clock on a code that does not exist; `Kati.Screens.DataSources.ready?/1` is the one line that changes when a client lands. Screen 82 lost the same three lines. `Kati.DesignLiterals.retired_lines/0` records them, which is `@retired_symbols`' twin for text. Verified on the Pixel_9a. |
| 72 | 86 Search idle | `fixed` | ~~The two Try suggestions are fixed strings.~~ Fixed 6 September: `Kati.Search.Suggestions.for_reader/0` offers the newest title on the shelf and the book the newest note is about — both queries that will match. A device with neither keeps the board's two. *What leaves this week* is deliberately not derived: it needs the offers resource screen 11's Leaving band also waits on. Verified on the Pixel_9a. |
| 73 | 86 Search idle -> 19 | `fixed` | ~~Four of the eight chips are silently turned into All.~~ Fixed 6 September, as the plan prescribed: a scope with no group behind it is drawn disabled and carries no tag, so the choice is never offered and then discarded. Verified on the Pixel_9a — Music is greyed. |
| 74 | 88 Scope & ranking | `fixed` | ~~The contract board renders scopes the executor does not implement.~~ Fixed 6 September at scope level: `Kati.Search.built?/1` is the seam and screen 88 draws a `not yet` pill against Music, Meals and Money. Fixed 7 September at FIELD level, the half that was still open. Five of the Screen scope's six are searched now — `title_original` is a column of the same row, `Kati.Media.TitleAlias` is what auto-detect writes when you connect a name to a title, and `review` and `tags` are the reader's own words off `Kati.Media.Watch`. Calendar's `location` is searched. Books' `ISBN`, `your notes` and `your quotes` are searched — quotes are `Kati.Books.Note` rows with `kind: :quote`, which the Notes group already drew and the Books group never read. What the app cannot keep is struck rather than dropped, in the same treatment `never invitee names` already had, behind `Kati.Search.kept?/1` as the scope-level `not yet` sits behind `built?/1`: `cast` (nothing holds a person — TMDB's credits are not fetched) and Books' `series` (`Kati.Books.Book` has no series name). Verified on the Pixel_9a: 88 draws `cast` and `series` struck beside live `location`, `ISBN`, `your notes` and `your quotes`. |
| 75 | 92 My services | `fixed 1ec2913` | ~~Home and screen 92 give opposite answers one tap apart.~~ Fixed 6 September: both groups read the store and answer with nothing when it holds nothing. The LIST is what goes — the country row, the field, the rules and the money row all stay live, which is screen 03's arrangement — and board 93's *No services yet* card takes its place, called rather than copied. The Free with ads band goes entirely, because a heading over an empty section is an eyebrow over a hole. Board 93 as a WHOLE is not the answer and reading it said so: it has no way to add a service. So the empty state carries the action — the field asks *Name a service you pay for* and the card has an *Add it* pill on the same write as *Something else*. Boards 24 and 42 quote 92's line and it counts too. Verified on the Pixel_9a from a cleared install, through the whole first run. |
| 76 | 92 My services | `fixed` | ~~Adding one service produces a page half the user's and half the drawing's.~~ Fixed 6 September: `set_up?/0` gates the WHOLE page, and the Money row totals `Kati.Services.Service.total/1` rather than the frozen £46.47 — a set-up page whose services carry no price says `—`, because a total nobody entered is not a total. |
| 77 | 92 My services / 93 | `fixed 71142ba` | ~~All three availability rules are stored and consumed by nothing.~~ Fixed 6 September, by getting the data rather than rewording the switch. TMDB folds JustWatch's per-country answer into the detail request Kati already makes (`append_to_response=watch/providers`), `Kati.Media.CachedTitle.providers` keeps it by region, and `Kati.Media.Availability` reads it — whose whole subject is that **`:unknown` is not `:unavailable`**, so a title nobody has looked up is never hidden. Up next and Discover honour the switch; screen 14's *Where to watch* band fills and says which service you already pay for; the sentence names the two pages it empties rather than the board's three, because screen 13 reads nothing at all (#88). Verified on the Pixel_9a: Severance reads *Apple TV · included*, the switch takes Up next from 2 ready to 1, and subscribing to Apple TV brings it back as *included · you pay for this*. |
| 78 | 94 Country picker | `fixed` | ~~The field promises 190 countries over a list of seven and filters nothing.~~ Fixed 6 September: it is a `<TextField>` that filters by name or code, and the placeholder counts the list. Verified on the Pixel_9a — `ger` leaves Germany. |
| 79 | 98 Your year, shared (Kati.Screens.YearShare) | `fixed` | ~~Every figure on the share page is a fixture.~~ Fixed 6 September: the card reads `Kati.Screens.Stats.figures/0` — the same year screen 07 draws, so the two cannot disagree — and its three titles are `Kati.Media.Watch` grouped by title. An empty history answers board 98's card. |
| 80 | 98 Your year, shared (Kati.Screens.YearShare) | `fixed` | ~~'Save image' saves nothing — it pushes the Year cards reference sheet.~~ Fixed 6 September, and the second half was the real one: wiring it took three lines, and then the capture threw `Software rendering doesn't support hardware bitmaps`. Coil decodes into hardware bitmaps and `View.draw(Canvas)` cannot draw one, so the fence worked on exactly the pages with no pictures on them — screen 121 saved fine, screen 98 could not. It uses `PixelCopy` now, with the old path as the fallback, and every page that saves itself gains it. Verified on the Pixel_9a: 450KB written to Downloads, and the PNG pulled back off the device is the page, posters and all. |
| 81 | 04 Series detail | `fixed` | ~~The bookmark and star discs beside 'Mark next watched' carry no tap.~~ Fixed 6 September: the star opens screen 33, the one place a rating is written; the bookmark writes `notify_new_episodes` — the column screen 25 is a page ABOUT and which nothing could set for a single show — and fills when it is on. A drawn series keeps two pictures. Verified on the Pixel_9a. |
| 82 | 05 New releases | `fixed` | ~~Every control on screen 05 is dead: `Mark all`, the `Watch` pill on each Out now row, and the `settings` gear on the watcher card. The tap-sweep's own comment claims Mark all "joined this group the round it was wired" — the comment is orphaned.~~ Fixed 7 September, orphaned comment included. The rows carried nothing a tick could be written against, so they now carry the reference `Kati.Media.Watch` names an episode by plus the season and number off the COLUMNS — screen 34's shape, for its reason. **Watch** ticks one row through the shared `Kati.Screens.Series.write_tick/2` and re-reads; **Mark all** does the same for the set and is drawn without a tap when the set is empty, which is not the same as inert; the **gear** opens screen 25. Verified on the Pixel_9a with three episodes aired into the window: `1 out now` → Watch → `0 out now`, then `2 out now` → Mark all → `0 out now`, and the gear opens *Release watcher · Watching 2 titles*. |
| 83 | 06 Add a title (Kati.Screens.AddTitle) | `fixed 91e56a9` | ~~The cancel (X) glyph at the end of the search field is not tappable.~~ Fixed earlier this round — `clear_disc/0` carries `:clear_query` and the handler empties the field. Verified on the Pixel_9a when the sheet stopped opening on four invented films. |
| 84 | 08 Film detail | `fixed` | ~~The three action buttons — Log rewatch, Schedule, Share — carry no tap tag at all.~~ Fixed 6 September. *Log rewatch* was wired earlier this round; *Schedule* opens screen 18 with `Watch <title>` already typed, now that there is a date sheet to open; *Share* uses `Mob.Share.text/2`, which is Mob's own and was there all along, and sends the title, the year and where it can be watched. Verified on the Pixel_9a — the system sheet opened with *Dune — On HBO Max Amazon Channel*. |
| 85 | 08 Film detail | `fixed` | ~~The note card's edit pencil and the whole rating card are painted, not tappable.~~ Fixed 6 September: both open screen 33, which is the one place a rating and a review are written. A drawn film has no row to edit and keeps its pictures. Screen 08's *Where to watch* band fills at the same time, from the column the availability rules read. |
| 86 | 10 Up next | `fixed` | ~~Screen 10 draws no tappable control at all.~~ Fixed 6 September: the play discs open the title — series screen for a series, film screen for a film — the `tune` disc opens screen 145's sort-and-filter sheet, and a cold row's `Drop` pill opens the drop sheet over that show. The row carries its id the way screen 03's tiles do; a drawn row carries none, so board 10's discs stay pictures. Worth recording why no sweep caught it: `ScreenSweep.tap_tags/1` collects the tags a screen DOES draw, so a screen with none passes every check in `Kati.ScreenTapSweepTest`. Verified on the Pixel_9a. |
| 87 | 11 Discover | `fixed` | ~~Discover's `tune` disc is drawn as a plain Box with no tap at all, and the `Schedule` buttons that do work forget themselves the moment you go back.~~ Fixed 7 September. The disc now answers the question the page was already answering badly for you: `Kati.Media.Recommendations.seed/0` picks the newest title you touched, and *the last thing I opened* is not *the thing I want more like*. It opens the shelf — `seedable/0`, newest first — and picking one rebuilds the whole feed, heading and posters together, because a heading naming one show over picks fetched for another is the substitution this app spends its moduledocs preventing. Not offered on a shelf of one, and a picture over the board. The `Schedule` buttons are now pictures in both states: `leaving` is `[]` on every real feed — no offers resource, no window in which a title leaves a service — so there is nothing to schedule against, and a button that changes and forgets is the screen claiming a thing was scheduled. Verified on the Pixel_9a: *Dune* → tune → *Severance* redraws **BECAUSE YOU WATCHED SEVERANCE** over Mr. Mercedes, The Capture and The Institute. |
| 88 | 13 What fits? | `fixed` | ~~Every control on screen 13 is decoration: the five window buttons (20m/30m/45m/1h/2h+), the four mood chips, the three play discs, the `Tomorrow` defer pill and the overflow disc. The board's own caption is "Set the window you actually have and the library filters itself".~~ Fixed 7 September, and the library filters itself. The screen's own moduledoc had already recorded that three of the four things blocking it stopped being blocked when `Kati.Media.CachedEpisode` was built; this is that round. The **five buttons** set the window and the page re-reads — the list, its count, and the over-budget row with its `MIN OVER` are four views of one number, and moving the buttons while leaving the rows is the finding itself. The list is unwatched **aired** episodes off the tracked shelf that fit, longest first, because the point of a window is to fill it. The **rows open** the show or the film they name, by position and not by id: three unwatched episodes of one series is the ordinary case here, and three siblings carrying `open_<tracked_id>` are three nodes with one `accessibility_id`. The **mood chips**, the **`Tomorrow` pill** and the **overflow disc** are all dropped over a real list: a mood has no column anywhere, nothing records a deferral, and the moods were the one thing an overflow could have held. The board keeps all of them. Verified on the Pixel_9a: 45m → three Severance episodes at 44/44/41 with *nearest film is 2H 35M · 110 MIN OVER*; 30m → one at 7m; 2h+ → an 80m episode; and a row opens Severance. |
| 89 | 141 Import — recognised (Kati.Screens.ImportRecognised) | `fixed` | ~~The 'Import 412' pill — the commit action of the whole import flow — carries no on_tap on both screens that draw it, so the tap sweep cannot report it either.~~ Fixed 7 September, and it was found by auditing my own work: #101 wired screen 37's commit pill and left 141's, which was hand-drawn rather than built by the shared `Kati.UI.ImportChrome.header/2`. Both use it now. From 141 the pill commits a file that disagrees with nothing in one press, and opens 37 when there IS a conflict queue — silence reads as *keep mine* in `Kati.Import.Commit.run/2`, which is the safe reading but not one to make on somebody's behalf without showing them. |
| 90 | 15 Activity | `fixed` | ~~No row in the activity log is tappable, so the user cannot open a title from their own history.~~ Fixed 6 September: the row carries the title it is about and opens the series or film screen under a pill reading *Activity*. A drawn row carries no id, so board 15's rows stay pictures. Verified on the Pixel_9a. |
| 91 | 15 Activity | `fixed` | ~~The filter (tune) disc in the Activity header reaches a handler and does nothing.~~ Fixed 6 September: it opens screen 145, the same sort-and-filter sheet the chips beside it narrow with. |
| 92 | 152 Anime | `fixed` | ~~Two of the board's five taps are the already-selected members of live families and change nothing.~~ Closed 7 September as **not a defect, and now the app's stated rule**. `:pick_screen` and `:watches_yes` write the value already there while `:pick_books` and `:watches_no` move the screen; the entry the tap sweep already carried called that honest, and this round made it the rule everywhere rather than one screen's local judgement. Screen 35's status tiles, screen 34's order tiles, screen 33's `5★`/`10pt` toggle, screen 13's window buttons and screen 18's *Event* chip all keep their tap when chosen, for one reason written out at `Kati.Screens.SeriesSettings.status_tap/1`: **pressing the thing you are already on is how somebody checks that they are on it**, and a control that goes dead once chosen stops answering exactly when it is pressed to be sure. Each is recorded in `@inert_taps` with that sentence. 152's own remaining problems — no route, no per-title override column — are #1's and #29's, not this. |
| 93 | 18 Quick add (Kati.Screens.QuickAdd) | `fixed` | ~~Five of the six 'Or file it as' chips — including Title, the only one that would add a film — swallow taps and do nothing.~~ Fixed 7 September. The reason they answered `nil` was *these are not dead, they are undrawn: when each gets its own screen it gets its own tag* — and five of the six do not want a screen. `Kati.Calendars.Event.kind` already takes `:event`, `:reminder`, `:habit` and `:note`, so four of the chips are one attribute on the row this screen already writes: the sentence is parsed the same way whichever is lit, and the chip says what the parsed thing IS. **Title** is the one the finding is named for and the one exception — a film is not an event, so it pushes screen 06 carrying the parsed title, and the add sheet opens already searching for it (`Kati.Screens.AddTitle.opening_query/1`, a `:query` param rather than screen 19's `Mob.State` key, which 06 has never read). Expense keeps its push to 124. Screen 124 draws the same row as a picture, having no handler for it. Verified on the Pixel_9a: *arrival* → **Title** opens 06 with `Arrival` in the field and 17 TMDB results; **Reminder** lights and files the sentence as one. |
| 94 | 19 Search | `fixed` | ~~The clear disc is booked inert by the tap sweep, with the sweep's own stated reason.~~ Fixed 7 September, and it was not inert — it was **half right**, which nothing in the suite could see. The sweep reaches 19 with an empty field, where clearing is correctly a no-op, so the tag had never been pressed over a real query. Pressed on the device it emptied the results and left the typed word sitting in the box: the page read *no results for hollow* over a query it had just thrown away. The field needed the `query_epoch` counter screen 06 has carried since `K-46` — the bridge remembers the last epoch per field and ignores a `value` for one it has already drawn. Verified on the Pixel_9a: `hollow` → 1 result → clear → the placeholder is back. |
| 95 | 33 Rating | `fixed` | ~~The three context rows — Watched on, Where, With — each draw a chevron and carry no tap tag, promising three screens that do not open.~~ Fixed 7 September. Three screens is not what they want: each edit is one short answer, so each opens **under its own row, inside the same card**, the shape `+ tag` settled one card down. *Watched on* offers tonight and the three nights before it and changes the day without touching the hour, which is why `Kati.Media.Watch` keeps `watched_on` and `watched_at` in separate columns. *Where* offers the reader's own subscribed services (`Kati.Services.Service` `:subscribed`) followed by the places they have named on past watches, because a cinema is somewhere a subscription list will never hold; pressing the chosen one clears it. *With* takes the names as typed, which is the privacy decision `Watch.companions` already recorded. One row open at a time. Over the drawing all three are chevrons with no tap and the board keeps its own `Lumen+ · Living room`. Verified on the Pixel_9a over Dune: Mubi, Sun 6 Sep, Jo — all three still there after Save and reopening. |
| 96 | 33 Rating | `fixed` | ~~'+ tag', the spoiler toggle and the 5★/10pt scale toggle are all drawn as controls and none of them changes anything.~~ Fixed 7 September. **`+ tag`** was filed under Backlog as *a sheet that never opens*; there is no sheet, because a tag is one short word — the field opens under the chips with the three tags this reader has used most beside it, a chip is removed by tapping it, and `Kati.Media.Watch.tags` finally has a writer. **The spoiler badge** sets and unsets `contains_spoilers`, and its off state is now drawn as an invitation (*Mark spoilers*) rather than not at all — the old rule that the icon must not assert the opposite is kept by not changing the icon, which it could not anyway since `Kati.Icons.glyph!/1` raises on `visibility`. **The scale toggle** writes `Kati.Rating.Scale` — `Mob.State`, where `Kati.Locale` has kept the locale since the app had two screens, because a preference about how a number is READ is not a fact about a title or a watch. One stored integer, two readings, honoured everywhere a rating becomes text: 33's numeral, 04's and 34's rating column, 143 and 144. Verified on the Pixel_9a over Dune: 5★ reads `5` and 10pt reads `10`, the flag and the tag survive Save and reopening. |
| 97 | 34 Season | `fixed` | ~~The Aired / Absolute / DVD strip is a picture: neither clause of order/2 emits on_tap and handle_tap/2 matches only episode rows, so the screen's central control does nothing. CachedEpisode.in_order/2 already implements :absolute.~~ Fixed 6 September. Wiring all three tiles would have been the worse fix: **DVD** has no numbers from any source Kati fetches, and **Absolute** had none either — `absolute_number` is a column no ingest fills, so `in_order(:absolute)` dropped every episode and answered `[]`. So `Kati.Media.CachedEpisode.derived_absolute/1` computes the numbering a COMPLETE cache implies (contiguous seasons from 1, each contiguous from 1, more than one season) and `%{}` for one that cannot support the claim, `offered_orders/1` drops a tile with no numbers behind it, and a strip left with one tile is dropped whole. Verified on the Pixel_9a against Severance: Aired draws S2 as E1–E10 with the special listed first, Absolute draws it as E10–E19 with the special gone and the count changing with it, and the choice survives leaving the screen. |
| 98 | 34 Season / 35 Series settings | `fixed` | ~~The ⋯ disc at the top of both screens is not a control — SettingsList.disc/1 builds a themed icon with no on_tap, so it reaches no handler and Kati.ScreenTapSweepTest's 'answers every tag' check cannot see it.~~ Fixed 6 September. Deleting the disc was the smaller fix and the worse one: both screens are per-show pages reached through 04's ⋯, and from either the only way to the sibling page was back to 04 and reopen that menu. So the disc opens `Kati.Screens.ShowPages` — the other per-show pages, this one left out, each push carrying the show and a back label naming the page you came from. 04 is deliberately not a row: it is where the back pill goes. Over the board the disc stays a picture, the rule 34's order tiles and 35's status tiles both keep. Walked on the Pixel_9a: 34 → Show settings → Show details, whose back pill reads `Show settings`. |
| 99 | 35 Series settings | `fixed` | ~~Every control on the screen is inert, including four switches whose columns exist on TrackedTitle with matching defaults and no other reader or writer in the app, and the three-way Status tiles that map exactly onto TrackedTitle.status.~~ Fixed 6 September. The screen's own argument for staying frozen — *half of it would become the user's own and half would stay a picture* — is right and named the wrong unit: the half with no schema is two whole GROUPS, *Region & availability* and *This show*, and a group with nothing behind it is DROPPED, the rule screen 14's bands and screen 92's *Free with ads* already keep. So over a real show the page is the three Status tiles and the four season-pass switches, every one of them writing `Kati.Media.TrackedTitle`; over no show it is board 35 whole. 04's ⋯ → *Show settings* now carries `tracked_id`, so the page saves onto the show the menu was opened over rather than onto whichever row a bare push found. Walked on the Pixel_9a: all seven controls write and survive a back-and-return. Retired from *Every screen*. |
| 100 | 36 Auto-detect (Kati.Screens.AutoDetect) | `fixed` | ~~Ten of the twelve controls on Auto-detect — including the master on/off switch for the whole feature — carry no on_tap and are invisible to the tap sweep.~~ Fixed 7 September, and the screen's own moduledoc was right that this was not a wiring job — *detection is a feature that has not been built*. The reader chose to have it built. `KatiMediaListener` (`K-46`) is a `NotificationListenerService` that overrides no callback and exists only to satisfy `MediaSessionManager.getActiveSessions`, which is the one API that answers *what is this phone playing*; `Kati.Media.Detect` matches what it hears against the shelf **by name**, ticks past a threshold, and turns a name it cannot place into a question rather than a guess. `Kati.Media.Watch.detected` is the provenance column the banner needed — the moduledoc's own first near miss — so `41 EPISODES TICKED FOR YOU` is counted rather than stated. What the board invented is dropped: there is no Apple TV, no Chromecast and no browser extension, because Kati has one source and inventing three more would be the same claim the count was. Walked on the Pixel_9a end to end: notification access granted, master switch on, a real Chrome media session titled *Paddington* detected and ticked (`detected 0 → 1`), a second sweep answering `:already`, and *“A Film Nobody Keeps”* becoming a question that **Not mine** clears. **Then walked again, because the first version could not have worked:** `sweep/0` answers what is playing at this moment, and the moment that matters is one Kati is not running for — you finish an episode, close the app, and the session is gone before Kati is next opened. Nothing called it either, and the moduledoc named a `Kati.Media.Detect.Sweep` that did not exist. `KatiMediaListener` records instead, keeping each session's high-water mark while it is bound, and `Kati.App` drains that at boot — the shape `Kati.Background.Handoff` already uses. Verified in the real scenario: Kati backgrounded, Chrome plays *Blade Runner 2049* to the end, Chrome killed so the session is destroyed, Kati reopened → ticked. |
| 101 | 37 Import (Kati.Screens.Import) | `fixed` | ~~Screen 37 has zero controls: the 'Import 412' commit pill, the step meter and the three conflict answers are all pictures, and because none carries a tag the tap sweep cannot see any of them.~~ Fixed 7 September, and there is an importer now rather than a wired-up drawing — the reader chose *Build the features*. `Kati.Import.Csv` reads RFC 4180 (quoted fields, doubled quotes, newlines inside them), `Kati.Import.Mapping` matches columns by HEADER and reads the rating scale off the column itself because Trakt and Letterboxd both call it `Rating` and mean different things by it, `Kati.Import.Job` counts every row against the shelf as **new**, **merged** or **conflict** without writing anything, and `Kati.Import.Commit` writes what the reader answered. The three answers hold between renders and *apply to all* applies the answer just given rather than deciding for you. Screens 140 → 141 → 37 are three views of one job now, where 141 and 37 used to contradict each other about one file (#53). Walked on the Pixel_9a with a real Letterboxd export: `3 ROWS · 4 COLUMNS`, *Kati matched 3 of 4 columns … 5★ → 10pt, and dates read as YYYY-MM-DD. One column is skipped.*, then **Import 3** → *3 added.* → three films on the shelf, finished, with their ratings. |
| 102 | 80 Data sources (Kati.Screens.DataSources) | `fixed` | ~~The Refresh and Clear pills under Cached metadata emit no tap at all — the only cache controls in the app are pictures, and they are invisible to the tap sweep.~~ Fixed 7 September. **Clear** empties the three cache resources and the poster files, which is safe by construction and not by care: each of them says in its own moduledoc that no column on it can hold something the reader made, and the library is joined to them by a VALUE PAIR rather than a foreign key so that emptying one cannot orphan the other. **Refresh** re-reads every tracked title through `Kati.Media.Tmdb.fetch/2` — the tracked shelf and not the cache table, because a cached row nobody added is a search result and refreshing it spends the reader's request budget on a title they did not ask for — off the screen's process, because one round trip per season per show would stop it drawing. Verified on the Pixel_9a: *Refreshing…* → *Refreshed 2 titles.*, then *Cleared 27 cached rows.* **And pressing Clear found a second defect**, in the one screen that shows what it clears — see #103. |
| 103 | 03 Library | `fixed` | Found on the device 7 September by pressing #102's new **Clear** pill: the shelf dropped every tracked row whose cache had gone, so a cleared cache left three tracked titles and two watches intact and a Library reading `0 titles · 0 in progress` over *No titles yet · Add one thing you are watching*. The rule was deliberate — *a tile captioned `nil` is worse than a tile that is not there* — and it is right about `nil` and wrong about the alternative: `Untitled` is what `Kati.Screens.Inbox`, `Kati.Screens.Rating` and `Kati.Screens.SeriesSettings` have always drawn for the same row. The shelf now draws it too, and the tile keeps its kind, its status, its progress and its rating, all of which are the tracked row's or the watches'. This matters beyond the button: the card the button sits on promises Kati refreshes anything older than six months **on its own**, so this was a state the app would have reached by itself. Verified on the Pixel_9a: cleared → `3 titles · 2 in progress` over three *Untitled* tiles with their real statuses, then Refresh → *Dune*, *Severance* named again. |
| 103 | 98 Your year, shared (Kati.Screens.YearShare) | `fixed` | ~~The five non-resting scope chips and the privacy switch move assigns that nothing reads.~~ Fixed 6 September: the scopes narrow the card, and a scope with nothing in it shows nothing rather than the same three titles under a different word. The switch had nothing to mark — `Kati.Media.TrackedTitle.private` is the column now, set from the ⋯ menu on the title's own page, and it hides a title from the CARD and nowhere else. Schema version 11. |
| 104 | 03 Library / 152 Anime | `fixed` | ~~`:anime` is a dead kind — nothing in the app writes it — so the Library queries a third shelf that is always empty, and board 152's entire subject has no column and no writer.~~ Fixed 7 September by building the three rules board 152 states in priority order. **1. Your own tag, always wins:** `tracked_titles.anime_override`, three-valued on purpose — `NULL` is *I have not said*, which a boolean defaulting to false could not tell from *no* — written by a ⋯ row on screens 04 and 08, where `private` already lives and for its reason. **2. The import source:** `looks_like/1` names the file's own service, so a MAL or AniList export marks everything in it; no column needed. **3. The provider genre:** TMDB's Animation **and** Japanese origin, both halves, because Animation alone files Pixar as anime and Japanese origin alone files every live-action drama as one — `cached_titles.original_language` is the half that was not stored. The latent bug is fixed too: `shaped/3` asked `kind == :movie`, so an anime film would have opened the series screen; `Kati.Media.Anime.film?/2` asks the CACHE first, which an override leaves alone — found on the Pixel_9a when a hand-added film marked as anime moved to the series screen. Backup schema 14 → 15. Walked there: **Mark as anime** flips to **Not anime**, and the tile still opens the film screen. |
| 105 | 06 Add a title (Kati.Screens.AddTitle) | `fixed` | ~~A search that returns nothing draws a bare '0 results' and empty space — no message, indistinguishable from a search that never ran.~~ Fixed 6–7 September. `Kati.Screens.AddTitle.nothing_card/3` draws *Nothing here for “…”* for a search that found nothing, and separate cards for not-yet-searched and under-the-floor — three states where there was one blank. Confirmed by an adversarial audit on 7 September. |
| 106 | 12 Lists | `fixed` | ~~Screen 12 has one working control and it writes nothing.~~ Fixed 7 September. The first pass shipped what the store could answer and filed the rest as a design gap ([#99](https://github.com/mishka-group/kati/issues/99)) — the owner asked for the feature instead, so it is built, and where it had to invent it invents by BORROWING: `Kati.Lists.List` and `Kati.Lists.Membership` are two ordinary tables, the name field is `Kati.UI.SettingsList`'s own, `Kati.Screens.ListDetail` draws 12's header, the library's poster row and board 146's destructive pill, and every departure is recorded in the moduledocs. `+` opens the field and makes a list that survives the pop; the same name twice is one list; a blank name is refused in `Kati.Write.message/1`'s own words. Board 146's *Add to list* carries its selection now — it used to push 12 and leave it behind — and the page it lands on says *Pick a list for 2 titles*, puts them in the list that is pressed, and opens it so the press has a visible result. Rows open, `Remove` and `Delete this list` write, and a title opens its own screen. Two of the four *Kept automatically* rows are the reader's own counts; `Wishlist` and `Owned on disc` are not drawn, because both are assertions no column holds. Two bugs the device found: coming back showed the counts the page had mounted with, and the *Pick a list* note outlived the act — both re-read on `Kati.Screens.Resume`. Backup schema 15 → 16. Walked on the Pixel_9a: made **Rainy Sunday**, put two titles in from the shelf, removed one, opened Dune from it, and deleted the list back to the empty card. |
| 107 | 143 Episode rows / 144 Rate an episode | `fixed e44d44d` | ~~Both boards depend on a long press, and Mob has no long-press primitive.~~ Fixed 6 September, by giving the door a shape this bridge has. The gesture the boards name is *long press an episode row rates*; Mob's tap is `on_tap` and there is no `on_long_press`, so the door is the **rating column itself** — the numeral and one star board 143 draws at the trailing edge of every episode row, tappable, opening screen 144 over that episode. It is a control the user can see, which a long press is not, and it is drawn where the board draws it. If Mob gains a long press, the row can gain one too; nothing here has to move for that. |
| 108 | 143 Episode rows — the rating column | `fixed e44d44d` | ~~Board 143 specifies a rating column for screen 04's episode rows, and screen 04 has none.~~ Fixed 6 September: `Kati.Screens.Series.rating_column/1` and `Kati.Screens.Season.rating_column/1` draw it, off `ratings_by_episode/1` — the same `Kati.Media.Watch` rows the ticks are read from, so the column and the tick beside it cannot disagree. A rated episode prints its numeral and star through board 143's own `rating_node/1`; an aired unrated one draws a hollow star, which is the affordance; an episode that has not aired draws nothing, because there is no opinion to have. Verified on the Pixel_9a — *In Perpetuity* reads `4.5`. |
| 109 | 145 Shelf filter sheet | `fixed` | ~~The trailing filter disc that board 145's caption names as its own entry point does not exist on any of the three shelves it names.~~ Fixed 7 September by taking the finding's second option, because board 03 already has the next thing to it: a `sort` disc, in that header, trailing the title, which has opened `Kati.Screens.ShelfFilters` since the shelf could be sorted at all. The board draws exactly two discs — `search` and `sort` — and a *filter* disc beside a *sort* disc opening the same sheet would be two doors into one room from one wall. So the sort disc is the permanent entry and the duplicate ⋯ row is gone; `Select titles` stays, because 146's own gesture is a long press and nothing draws one. Verified on the Pixel_9a. |
| 110 | 149 Dropping — the sheet and after | `fixed` | ~~A film cannot be dropped, abandoned or DNF'd anywhere in the app: 08's ⋯ menu has one row and 149 is series-shaped.~~ Fixed 7 September, and 149 IS reused — the ledger's *cannot be reused as drawn* turned out to be four places, not a shape. `heading/1` says **Drop this film**, `position_card/1` draws nothing where there is no position, and `at/1` is what the action button and the undo pill build their sentence from; with the numbers nil those two read **Drop at S E** and **Dropped Dune at S E**, which is worse than no position and was found by opening the sheet on the device. A film carries `season: nil`, never a manufactured `S1 E1`. Screen 08's ⋯ gains **Drop this film**, and only over a real film — over the drawing the row is dropped, because a bare push opens the sheet on whatever gone-cold title happens to be newest. Walked on the Pixel_9a: Dune → ⋯ → **Drop this film** → *Too slow* → **Drop**. |
| 111 | 149 Dropping — the sheet and after | `fixed` | ~~The drop reason the user picks is held in socket assigns and thrown away; there is no column and no event row for it.~~ Fixed 7 September by building the resource screen 15's own moduledoc named as missing: `Kati.Media.Event`, append-only, `media_events`. A status column says where a title *is* and cannot say when it got there, what it was before, or why — all three are things screen 15 draws. The reason goes in as the words the reader read (`Too slow`, not `:too_slow`) because the column has to hold *Something else* typed by hand. Written only when the status write landed: an event log that records a change the store refused is a record of something that did not happen. Undo appends `:resumed` rather than erasing the drop — an append-only log whose undo erases its own cause is not one. Backup schema 13 → 14, and a restored 13 has a history starting the day it was upgraded, because nothing can reconstruct one. Walked on the Pixel_9a: **Dropped · Dune · too slow** in the log. |
| 112 | 15 Activity | `fixed` | ~~The 'Added' filter chip can never match a real row, and selecting it draws a blank page with no empty state.~~ Fixed 7 September, both halves. `Kati.Media.Event` (#111) is what the chip finds: `Kati.Media.Log` is written by both add screens, the drop sheet and the importer, and screen 15 folds events into the same time-ordered stream as watches — one list, because the reader does not think of them as two tables. *Imported 412 titles from a CSV backup* is a row with no title behind it, which is why `tracked_title_id` is nullable. The blank half is #117's fix in a second place: *nothing under this chip* and *nothing this month* are different sentences, and the second one is simply false when the month is full of rows the chip filtered out — so a chip that matches nothing now says which, and offers **All**. Its tap is `:show_all`, not the chip's own `filter_All`, because two nodes may not share an `accessibility_id`. Walked on the Pixel_9a: **Added · Marram Grass**, **Dropped · Dune · too slow**, and *No added entries this month · There is other activity this month. Press All to see it.* |
| 113 | 154 Add a title by hand (Kati.Screens.AddByHand) | `fixed` | ~~The same film can sit on the shelf twice — once from TMDB and once hand-typed — because the duplicate guard is per-source, and a wrong Kind can never be corrected.~~ Fixed 7 September, both halves. `already_kept/1` matches on the NAME across every source, through `Kati.Media.CachedTitle.names/1` and normalised the way every other name comparison in this app is — so *dune* finds the TMDB row, and a reader who types the original title of a show they added under its English one is told. It refuses in board 155's two-part shape (#128) and the second line says what to do instead, because *you already have this* with no way forward is a dead end on the one screen a reader reaches by NOT finding something. The Kind is correctable from a ⋯ row on both 08 and 04 — *This is a series* / *This is a film* — which writes BOTH rows, because the tracked kind is what the shelf queries and the cached kind is what decides which screen a tile opens; correcting one would put the title on the right shelf behind the wrong door. An anime stays an anime through it. Two bugs the device found and this fixed: `film_record/1` read `kind: :movie` alone, so a film marked as anime answered `nil` and screen 08 fell back to the DRAWING — the reader tapped their own film and got somebody else's; and `Kati.Screens.Series`'s render shape rebuilds from its facts map and drops every key it does not name, so both new ⋯ rows read the wrong state on 04. Walked on the Pixel_9a: typing `Dune` over the TMDB row is refused, and Marram Grass goes film → series → film with the tile following it. |
| 114 | 19 Search | `fixed` | ~~Your own review of a film or series is not searchable anywhere, although the Search screen's Notes group and Kati.Search's Screen scope both claim it is.~~ Fixed 7 September. A review IS a note — the same paragraph in the reader's own words about one thing on their shelf — so `note_for/1` reads `Kati.Media.Watch.review` alongside `Kati.Books.Note` rather than getting a group of its own, and `note_eyebrow/1`'s second slot is `:about` for a review where it is `:book` for a book note. The film itself is a hit too, through the Screen scope's own `your review` and `your tags` fields; see #74 for the rest of that list. Walked on the Pixel_9a: wrote *The marram grass scene is the whole film.* on Dune through **Log a watch**, searched `marram`, and got both — **Dune · Film** under SCREEN and `NOTE · 6 SEP · DUNE` under NOTES with the word picked out. |
| 115 | 36 Auto-detect (Kati.Screens.AutoDetect) | `fixed` | ~~Auto-detect detects nothing: every figure, source, tick count, rule and queued question is a literal, and no resource exists for any of it.~~ Fixed 7 September by #100's engine. Every figure on screen 36 is now the device's own — `real_banner/0` counts `Kati.Media.Watch.detected`, `real_now_playing/1` reads live sessions, `real_sources/2` names only what Kati has actually heard, and the invented Apple TV / Chromecast / browser-extension rows are gone. Confirmed by an adversarial audit. |
| 116 | 80 Data sources (Kati.Screens.DataSources) | `fixed` | ~~There is nowhere in the entire app to enter a TMDB key, yet every TMDB failure message tells the user to come here and do exactly that.~~ Fixed 6–7 September. There is a place to enter a TMDB key: `Kati.Screens.DataSources` draws a real `TextField` (`tmdb_token`) with a Save that writes through `Kati.SecureStore`, which is what every TMDB failure message had been pointing at. Confirmed by an adversarial audit. |
| 117 | 89 Result states | `fixed` | ~~Screen 19 has no cross-scope card, so narrowing to an empty scope draws "Nothing here" over a query that did find things — the exact misreading board 89's third band was drawn to prevent.~~ Fixed 7 September. `state_or_groups/3` now separates *nothing in this scope* from *nothing anywhere*: `elsewhere/2` finds the scope holding the most hits (never `All`, which is not a state), and `cross_scope/2` draws board 89's own row — `swap_horiz`, the sentence, `arrow_forward` — with the move behind it. Its own `go_` tag rather than the chip's `filter_` one, because two nodes may not share an `accessibility_id`; the row drew the chip's tag first and `ui.sh ids` on the Pixel_9a listed `filter_Screen` twice. Walked there: `dune` narrowed to Books reads **Nothing in Books. 1 match in Screen**, and pressing it lights Screen. |
| 118 | 92 My services | `fixed` | ~~The search field types but filters nothing, and the one sentence it exists for is never drawn.~~ Fixed 7 September. `matching/2` narrows both groups, and the eyebrow and the money total narrow with them — a count over an unfiltered list under filtered rows is the heading disagreeing with what is beneath it. A name nothing answers to gets board 95's own sentence, drawn immediately above the `Something else` row it names. Two things the device found: the empty-group card said *No subscriptions yet* over a reader with four, which is #117's misreading in a third place, so a group a FILTER emptied now draws nothing and lets `no_match/2` answer; and one field doing two jobs collided once the row refilled it (#119) — `Mubi 9.99` matched no service called *Mubi 9.99* — so the filter reads the name half and ignores the price, which is right for searching and for editing. Walked on the Pixel_9a: `mubi` narrows four to one and the eyebrow to **SUBSCRIBED · 1**; `mubi plus` gives **SUBSCRIBED · 0** over *No service called that*. |
| 119 | 92 My services | `fixed` | ~~There is no way to remove, rename or price a service. Once `Something else` writes a row you are stuck with it.~~ Fixed 7 September, with the control board 95 specifies. Every row carries a **Mine** switch: off writes `:not_mine`, which is the tier the *Not mine* group already counts, so the row leaves the two lists without leaving the store — a service you cancelled is not one you never had. The row's own tap, which used to reach `{:noreply, socket}`, puts the service's line back in the field it was typed in (`Netflix 10.99`), and `save_service/1` now REPRICES a name already listed rather than writing nothing, so correcting a price is retyping the line where you typed it instead of a second sheet drawing a second way to say one thing. A bare name still writes nothing — re-adding what you have is how somebody checks they have it, and it must not blank a price. Fixed alongside, found on the device: the field kept the old line after a save, because the bridge ignores a `value` for a field it has already drawn — `K-46`'s epoch counter, the same one screen 19 carries. Rows are tagged by service id, not name, for `poster_tag/1`'s reason. Walked on the Pixel_9a: **Subscribed · 4 → 3** on the switch, and Mubi £9.99 → £12.99 → £8.50 through the field. |
| 120 | 96 Nothing set up — knock-on | `fixed` | ~~Screen 96 documents four empty states that no screen can ever enter, and says so itself: the predicate it defines cannot answer false, because 92 falls back to fixtures on an empty store.~~ Fixed 7 September. The predicate can answer `false` — #75 took the fixture fallback off `Kati.Screens.MyServices.listed/0`, which is exactly the change 96's own moduledoc named as the one these bands were waiting on — and all four are shipped on the screens they are drawings of. **08:** the *Where to watch* heading keeps its place and the band goes under it, because *nothing you pay for carries this film* and *you have not said what you pay for* are different absences and only one is the reader's to fix. **11:** the Leaving-soon rail, behind its own chip, like the section it replaces. **13:** above the list rather than instead of it — the board's band is `11 episodes fit — 0 you can watch`, which is not an empty list but an unfiltered count, and screen 92's third rule already records that this page filters by nothing. **23:** the page keeps its header and the ledger under it is replaced, which is 96's own caption — *each band is a single replaced section of a screen that already exists* — so the monthly total, the service rows and the Worth-a-look card all go, exactly as the band's note says. The gate is an assign on 08, 13 and 23 so a captured frame can set it without writing a service into a store the suite shares. Fixed alongside, found on the device: re-adding a service the reader had switched off answered `{:ok, existing}` and wrote nothing, so the save reported success and the row stayed under *Not mine*. Walked all four on the Pixel_9a with every service turned off, and each button lands on My services. |
| 121 | 03 Library | `fixed` | ~~Two shelf titles that differ only by a space versus an underscore collapse onto one tap target, and every distinct cached title mints a new atom.~~ Fixed 7 September: a tile is named by its tracked row's id, which is unique by construction and bounded by the shelf. The title stays as the fallback for a row that has none — `Kati.Library.Sample`'s nine, and every drawing that reuses this — because a tile still has to be nameable when the store is not behind it. Verified on the Pixel_9a: `ui.sh ids` lists `open_film_939417da-…`, one per row. |
| 122 | 03 Library | `fixed` | ~~The Books/Music branch of visible/3 is unreachable: the shelf assign can never hold anything but "Screen".~~ Fixed 7 September by deleting it. Both other segments PUSH screens 20 and 21, so the assign could only ever hold `"Screen"` — the guard, the assign, its writer and `nothing_here/2`'s first clause are all gone, and what to say to a reader who presses Books is their own screens' business. `shelf_Screen` keeps its tap and changes nothing, because pressing the segment you are on is how you check you are on it. |
| 123 | 04 Series detail | `fixed` | ~~The season pill strip and the EPISODES eyebrow share one un-scrolling Row, so a long-running show overflows.~~ Fixed 7 September: `season_strip/1` wraps the pills in a horizontal `Scroll` with `weight={1.0}`, which is what keeps the eyebrow its own width — without it the scroll hugs its content and the overflow simply moves. A `Scroll` rather than a second row under the eyebrow, because the board draws them on the eyebrow's line and that is where a reader who has learnt where they are will look. Verified on the Pixel_9a: Severance's S1 · S2 · S3 sit on the eyebrow's line, each with its own tag. |
| 124 | 07 Your year (Kati.Screens.Stats) | `fixed` | ~~The contribution grid is the last 182 days ending today, while the header names the calendar year so far.~~ Fixed 7 September by taking the ledger's second option and saying so: the caption reads **26 weeks to today**. Clipping the grid to the calendar year was the other and is worse — on 3 January it would be a field of three squares, and the thing the grid is for (*have I kept this up*) needs a window long enough to see a habit in. So the window stays and the label stops pretending. Verified on the Pixel_9a. |
| 125 | 07 Your year (Kati.Screens.Stats) | `fixed` | ~~@destinations carries a 'Recently watched' -> UpNext entry that more_numbers/1 explicitly filters out, so it is dead code.~~ Fixed 7 September by deleting it. The row is rejected because this screen already shows those three watches in full one section down, and a numbers row that only counted them would be the page telling you twice — so the destination had nothing to be a destination for. |
| 126 | 140 Import — where are you coming from (Kati.Screens.ImportSources) | `fixed` | ~~'Five more sources' lists five names of which one, AniList, is already a tile in the grid above it, and the row itself is a navigation stub with no list behind it.~~ Fixed 7 September, both halves, and there was no guess to make: the drawing's own closing note counts eleven sources — six tiles, four new names, the Kati backup row — so the board contradicts itself and the arithmetic is the half that is right. It reads **Four more sources · Simkl · TV Time · Libib · Last.fm**, and the two lines it stopped drawing are recorded in `DesignLiterals.retired_lines/0` beside board 80's invented pairing code. The row opens the picker now instead of pushing the manual mapper with no file: mapping is by column header, so a Simkl export reads without a tile to press, and `opens(nil)` answers `Kati.Screens.Import` because a file with no source named has no guess for 141 to describe. |
| 127 | 149 Dropping — the sheet and after | `fixed` | ~~The 'Change' pill only decrements the captured position one episode at a time and can never go forward, so overshooting requires closing and reopening the sheet.~~ Fixed 7 September: two discs, `remove` and `add`, at the same 30pt the pill was, so the card's geometry is unchanged. `Change` named neither direction and did one; two discs say which way each goes before it is pressed, which one word never could. No ceiling — the cache would know how many episodes the season has, and reading it here would make the pill refuse a number the reader can see is right whenever the cache is behind the broadcast. |
| 128 | 155 Add by hand — resting & refused (Kati.Screens.AddByHandStates) | `fixed` | ~~The empty-title refusal is one line where the board specifies two, and drops the reassurance that nothing was lost.~~ Fixed 7 September with board 155's own two-part card — `error` in `Palette.red/0`, a bold 13.5 line, a 12.5/1.65 body — and its own words: *A title is needed* / *Kati cannot keep a thing with no name. Nothing was written — this form is still open and your other answers are intact.* The second half is the one that matters: somebody whose save just failed does not know whether their other four answers survived it, so `nothing_lost/0` closes every refusal on the form, a store error included. The Title field takes the red inset ring the board draws on it — told *a title is needed* over four fields, a reader had to work out which — at `border_width: 0` when there is no refusal, so the ring appearing does not move the text. Walked on the Pixel_9a. |
| 129 | 19 Search / 88 Scope & ranking | `fixed` | ~~The tie-break the specification screen renders — tier, then recency — is implemented and never called; results actually tie-break alphabetically.~~ Fixed 7 September by calling it. `Kati.Search.rank/1` is the sort in all four groups now, with the recency each row actually has: the shelf's `last_touched_at` for a title you keep and the cache's `fetched_at` for one you merely looked up, `updated_at` for a book, `dtstart_utc` for an event, `inserted_at` for a note. A title is only the last resort inside it. On the Pixel_9a `er` returns Blade Runner 2049, Severance, Dune — not the alphabet. |
| 130 | 86 Search idle | `fixed` | ~~A recent query or suggestion is round-tripped through underscore substitution, so any query containing an underscore or a run of spaces comes back changed.~~ Fixed 7 September. There is no inverse to write, because `query_tag/2`'s mapping is not injective — `String.replace(line, "_", " ")` is not the inverse of anything. `resolve/2` resolves the tag against the rows that drew it instead, the way `Kati.Screens.Library.open_tile/3` resolves a poster tag, and each of the two lists answers its own prefix. Walked on the Pixel_9a: `sci_fi` on the recent shelf reopens as `sci_fi`. |
| 131 | 88 Scope & ranking | `fixed` | ~~88's back pill reads "Settings" but its only route in is the tune disc on the idle search page, and it pops back there.~~ Fixed 7 September: the tune disc names `Search` in its push, as every other push in the app does, and `Settings` stays as the answer for a push that names nowhere — the gallery's. Verified on the Pixel_9a: the pill reads **Search** and lands on 86. |
| 132 | 19 Search at 235% | `fixed` | ~~The third scope chip on a wrapped line loses its count at 235%.~~ Fixed 7 September by board 313, which settles the row rather than the measurement: `chip_rows/1` returns ONE line and `chip_line/1` scrolls it, so no chip is ever on a wrapped line to lose its count. 313 rejects the wrapped version on its own merits as well as on the bridge's — *better to read, and three lines tall — on a 235% page where the field alone is 62pt, that is the results pushed off-screen* — and requires the scroll to carry a chevron, which screen 86's row got on 8 September (#34). [mishka-group/kati#98](https://github.com/mishka-group/kati/issues/98) stays open for the `FlowRow` itself, which other rows may still want. |
| 133 | 05 New releases (Kati.Screens.Inbox) | `partly fixed` | Board 307 draws the inbox as four rows across three shelves and only the episode shelf can exist: nothing in the app produces a book, record or film release. 25's *Tell me about* offers all three and 66 has the **Follow the author** row that feeds one; the glyph-tile row recipe waits on the first producer, because 307's own reason for it — three aspect ratios in one list — needs a second shelf to bite. |
| 134 | 97 سرویس‌های من | `fixed` | ~~The Persian My services printed ایران to every reader whether or not they had chosen a country, drew the drawing's ۴۶٫۴۷ £ over an empty shelf, and its country row opened nothing.~~ Fixed 8 September with boards 324 and 301: `chosen_region/0` can say *no country*, the money row says nothing has been totalled, and `Kati.Screens.CountryPickerFa` is the sheet the row had never had a door to. |
| 135 | 02 Schedule (Kati.Screens.Calendar) | `fixed` | ~~Screen 02 could only say *Kati cannot see your calendar* on a day that was otherwise empty, so a day holding one habit drew a timeline with the reader's appointments silently missing and no way to ask for them.~~ Fixed 8 September with board 306: `calendars_card/1` sits under the timeline in the three states `Kati.Permissions.affordance/1` names. |
| 136 | 112 Medication (Kati.Health.Medication) | `partly fixed` | A medication whose schedule reads `Mon, Wed, Fri` is given a dose every day, because `schedule` is free text and only `times` is structured. Board 327's card is drawn and says why nothing is due in the two ways this page can honestly answer; the board's own sentence — *your four schedules all fall on other days, next is Monday at 08:00* — needs a `days` column, which is the fix named in the section. |
| 137 | 50 Share a plan / 120 Import a plan | `fixed` | ~~The QR card promised the 35 meals a code cannot hold, and the receiving side counted 29 new for an arrival that brings none.~~ Fixed 8 September with board 316: the card says what a scan sets up and offers the file for the rest, and a code arrival is its own page — `Set up`, four rows saying what came and what could not, three zeroes, and no conflict queue. |

## The proof for each, in order

### 1. 05 New releases — `unreachable`

**There is no route to screen 05 in English. Its only English door is Home's `New this week` hero, and that hero is omitted unless `Kati.Screens.Inbox.releases/0` returns a non-empty `out_now` — which needs a followed title with an unticked episode that aired in the last 7 days, which needs TMDB episodes, which needs the API key the phone does not have.**

*Proof.* lib/kati/screens/home.ex:641 `def new_this_week(nil), do: ~MOB"<Spacer size={0} />"`; :331 `hero_summary/0` answers `nil` for `_nothing_to_announce`; :1311 `handle_tap(:open_inbox, …)` is the only English push of `Kati.Screens.Inbox`. The bell at home.ex:1323 goes to `InboxNotifications`, not here. routes.txt confirms empirically: "05 New releases (Inbox) — only via fa: Settings > Language > fa > open_inbox", i.e. the BFS with a populated store never reached it in English.

*Fix.* Add a permanent door. Either a `New releases` row in Settings' Screen group, or a second action on `Kati.Screens.InboxNotifications` (which already pushes 25 from the same page), or draw the hero in a "nothing new this week" state rather than omitting it.

*Fixed 7 September.* A **New releases** row in Settings, beside Release watcher.

### 2. 101 Year cards — states (Kati.Screens.YearCardsStates) — `unreachable`

**The board whose job is to name honestly why a card cannot be saved names a capability that has since shipped, and it is gallery-only so nobody sees the correction.**

*Proof.* routes.txt lists 101 under NOT REACHED FROM ANY ROOT. lib/kati/screens/year_cards_states.ex moduledoc (lines ~50-58) states 'nothing turns a rendered node tree into image bytes'. Kati.Native.Files.save_screen/1 does exactly that (lib/kati/native/files.ex:271-277) and Kati.Screens.WeekImage already calls it (lib/kati/screens/week_image.ex:1072). The board's own 'Show me the card full-screen' button carries no on_tap and the module defines no handle_tap/2 (year_cards_states.ex:154-156, 427, 480).

*Fix.* Wire 98's Save image to save_screen/1 (which removes the need for band 5 entirely), and route 98's failure and private-title states to this board so it stops being gallery-only.

*Fixed 7 September.* The moduledoc says what band 5 is a picture of, and screen 100 carries the row onto it.

### 3. 102 Your year, shared — dark (Kati.Screens.YearShareDark) — `unreachable`

**The dark share board is gallery-only, yet it is not a colourway — it draws two card faces (the contribution field and the genre bars) that screen 98 never previews, so those faces are unreachable in light mode.**

*Proof.* routes.txt lists 102 under NOT REACHED FROM ANY ROOT. Kati.Theme.Palette.mode/0 reads Mob.Theme.current() at render time (lib/kati/theme/palette.ex:507-512), so screen 98 already renders dark on a dark device. Kati.Screens.YearShare.card/1 draws only the hours face and the top-titles face (year_share.ex:135-186); year_share_dark.ex draws the field from Kati.Stats.Sample.contributions/0 (:381) and the bars from ShareSample.where_hours_went/0 (:442-445) as well.

*Fix.* Delete 102 and give screen 98 the two missing faces, letting Palette.mode/0 do the colourway as it already does everywhere else.

*Fixed 7 September.* 102 is deleted; both its faces are on 98, out of the reader's own year. The board is kept in `test/design/retired/`.

### 4. 142 Import — source states (Kati.Screens.ImportStates) — `unreachable`

**The only board in the app that handles a wrong source guess, an unrecognised file, or a partial export is reachable only from the gallery, and every control on it is drawn without a tap.**

*Proof.* routes.txt lists 142 under NOT REACHED FROM ANY ROOT. lib/kati/screens/import_states.ex declares no handle_tap/2 and sets no on_tap on 'Use Letterboxd instead' or 'Pick again' (moduledoc section 'Nothing on this board taps'). Nothing in the flow can produce these states, because nothing reads a file: lib/kati/import/ contains only sample.ex, and Kati.Native.Files.pick/2 (native/files.ex:168) is called only by Kati.Screens.Restore (restore.ex:1297).

*Fix.* These states become reachable only once 140 opens the picker and something inspects the chosen file. Until then they belong where they are; the finding is that the whole edge-case half of import is art.

*Fixed 7 September.* Both preconditions have since landed — 140 opens the picker (#52) and `Kati.Import.Job.read/2` inspects the file (#101) — so what was left was that 141 threw the inspection away. It no longer does: see the ledger row for the three states, the `looks_like/1` header vocabulary behind *wrong guess*, and the atom-vs-string bug that had been titling every real import **CSV**. *Partial columns*, the board's third state, is the one 141 already drew before this: it is the ordinary skipped-column line, `Kati.Screens.ImportRecognised.skipped_clause/2`.

### 5. 143 Episode rows — the rating column — `unreachable`

**Screen 143 is reachable only from Settings > Every screen.**

*Proof.* grep for EpisodeRatings across lib/ finds only its own module and gallery.ex:181. routes.txt lists it under NOT REACHED FROM ANY ROOT.

*Fix.* It is a specimen sheet, so the right resolution is to apply its column to screen 04 and delete the board from the gallery, not to route it.

*Fixed differently, and this finding's own *Fix* line is what happened.* 143's rating column is on screen 04's episode rows — see #108 — and the board is a specimen sheet with no route, which `Kati.AppReachabilityTest` carries with that reason. It is not a page a user should reach.

### 6. 147 Selection & filters at 235% — `unreachable`

**A picture-only specimen with no route in and no live control, whose back pill names Library.**

*Proof.* routes.txt NOT REACHED: `147 Selection at 235%  Kati.Screens.ShelfLarge`; lib/kati/screens/gallery.ex:186 is the only reference. lib/kati/screens/shelf_large.ex:125 `use Kati.Screens.Pushed, back: "Library"`, and its moduledoc line 113 says "`Kati.Screens.Pushed` defines no `handle_tap/2` on purpose". Every literal (@selected_count 4, @chip_label "Comedy") is typed from the board.

*Fix.* It is a design reference, not an app screen. Delete it with the gallery, or move its findings into 146 as real 235% behaviour.

*Fixed 7 September.* Both halves of 147's split are real behaviour on 146 now.

### 7. 148 Drop, DNF & abandon — `unreachable`

**Screen 148 can only be opened from Settings > Every screen; nothing in the app pushes it, despite its own moduledoc claiming it is 'pushed under Settings'.**

*Proof.* grep -rn "DropStates" lib/ --include=*.ex returns only lib/kati/screens/drop_states.ex itself, lib/kati/settings/drop_states_sample.ex (its fixture), and lib/kati/screens/gallery.ex:188. grep for 'DropStates' in lib/kati/screens/settings.ex returns nothing. routes.txt lists it under NOT REACHED FROM ANY ROOT.

*Fix.* Add a Settings row for it beside screen 27's states sheet, in a reference/'how Kati thinks' group.

*Fixed 7 September.* The Settings row exists, filed under About beside **Year cards** for the same reason its own comment gives.

### 8. 152 Anime — `unreachable`

**No route in, and its back pill names a screen it cannot be reached from.**

*Proof.* routes.txt NOT REACHED: `152 Anime filter  Kati.Screens.AnimeFilter`; lib/kati/screens/gallery.ex:194 is the only reference. lib/kati/screens/anime_filter.ex:84 `use Kati.Screens.Pushed, back: "Settings"`, and no row in `Kati.Screens.Settings` pushes it.

*Fix.* It is the argument for a feature, not the feature. Fold its rule into a real Library filter once TrackedTitle gains an override, and delete the board screen.

*Fixed 7 September.* The rule is a Library chip now and the board is the place it is written down, with the Settings row its back pill always claimed.

### 9. 153 Numbering — inherited and overridden — `unreachable`

**Screen 153 explains the Aired/Absolute numbering choice and nothing pushes it — including screen 34, which draws that choice as a three-tile strip a user will want explained.**

*Proof.* grep for NumberingScheme across lib/ finds only lib/kati/screens/numbering_scheme.ex and its gallery row (gallery.ex:195). routes.txt lists it under NOT REACHED FROM ANY ROOT.

*Fix.* Push it from screen 34 — a note row or an info glyph beside the order strip — or from 35's 'This show' group.

*Fixed 7 September.* A `help` disc beside screen 34's order strip.

### 10. 87 Search typing / 89 Result states / 91 Search at 235% — `unreachable`

**Three reference sheets reachable only from the developer gallery, two of which name back destinations that cannot reach them.**

*Proof.* routes.txt NOT REACHED lists all three; lib/kati/screens/gallery.ex:136,137,139 are the only references. search_typing.ex `use Kati.Screens.Pushed, back: "Home"`; search_result_states.ex:116 `back: "Settings"`; search_large.ex:143 `back: "Home"`. None of the three has a `handle_tap/2` for its drawn controls, by design.

*Fix.* Keep the two functions the live screens depend on — `Kati.Screens.SearchTyping.nothing_yet/0` (rendered by 86 and by 19's waiting state) and `Kati.Screens.SearchResultStates.nothing/2` (rendered by 19's no-match state) — and delete the sheets when the gallery goes.

*Fixed 7 September.* All three subjects are live; #91's own finding is filed upstream as [#98](https://github.com/mishka-group/kati/issues/98).

### 11. 03 Library — `cannot-work`

**The Library shelf is read once at mount and can never be refreshed from the Library itself, so a title added or removed on a pushed screen does not appear or disappear when you come back.**

*Proof.* lib/kati/screens/library.ex:114 `def load(socket), do: Mob.Socket.assign(socket, filter: "All", shelf: "Screen", titles: titles(), menu?: false)`; lib/kati/screens/root.ex:167-170 calls `load()` only inside `mount/3`; deps/mob/lib/mob/screen.ex:571-578 `{:pop} -> case nav_history do [{prev_module, prev_socket} | rest] -> {prev_module, prev_socket, rest, :pop}` — the saved socket is restored verbatim and `mount/3` is not re-run; lib/kati/screens/root.ex:255-257 `if screen == __MODULE__ do {:noreply, socket}` makes the Library dock tab a no-op while on Library, removing the only other refresh. Trace: Library (empty) -> tap `Add a title` -> AddTitle -> save (add_title.ex:487-505 creates the rows; the sheet does not navigate) -> tap back -> pop restores the pre-add Library socket -> `titles` is still `[]` -> `shelf_body/3` draws `empty_state/0` -> 'No titles yet' over a database that now holds the film.

*Fix.* Re-read the shelf when Library becomes visible again — either re-run `load/1` on pop (a Mob-level resume hook), or have `Kati.Media` broadcast `{:kati, :media, :changed}` after a TrackedTitle write and give `Kati.Screens.Library` a `handle_kati/3` that re-assigns `titles: titles()`. The pubsub road is already carved: `Kati.Screens.Root` routes `{:kati, topic, payload}` to `rescue_kati/4` (root.ex:266).

*Fixed.* `Kati.Screens.Library.handle_kati(:resumed, _payload, socket)` (library.ex:143) re-reads the shelf when the screen is popped back to. `Kati.Screens.Resume` is the mechanism and its moduledoc states the rule this finding named: a popped-to screen restores its saved socket, so a screen whose rows can change under it has to say so.

### 12. 03 Library — `cannot-work`

**Nothing in the reachable app can set a film or series status, so the Not started and Finished chips are permanently 0, the subtitle always says every title is in progress, and four of tile_meta/1's six clauses are unreachable.**

*Proof.* lib/kati/screens/add_title.ex:487-505 — both `track/2` clauses `Ash.create(Kati.Media.TrackedTitle, %{... status: :watching})`, unconditionally. The only writer of `status` afterwards is lib/kati/screens/drop_sheet.ex:338 (`status: :dropped`), :349 and :356 (`%{status: :watching}`) — and routes.txt lists `149 Dropping — sheet/after  Kati.Screens.DropSheet` under NOT REACHED FROM ANY ROOT. `grep -rn "Ash.update" lib/kati/screens/*.ex` shows no other TrackedTitle status write; lib/kati/screens/log_progress.ex:762 `Ash.update(%{status: :finished})` operates on `%Kati.Books.Book{}` (`finish_book/1` calls `current_book/1`), not on a tracked title. Consequences in library.ex: `chip_counts/1` ("Not started", "Finished") always 0; `subtitle/1` counts `:watching` and so equals `length(titles)`; `up_next_badge/1` likewise; `tile_meta/1` clauses at :1120, :1121, :1123, :1124 are dead.

*Fix.* Either route DropSheet from the Film and Series detail screens so a status can actually change, or give the Library chips a status the app can produce. Until then the four-chip row on 03 is a control family with one live member.

*Fixed.* All four chips count something a reader can produce. `Watching` is what `Kati.Screens.AddTitle`'s two `track/2` clauses create (add_title.ex:674, :707). `Not started` is board 154's own default — `Kati.Screens.AddByHand` opens on `status: "Not started"` (add_by_hand.ex:66) and saves it through `status_atom/1`. `Finished` is `Kati.Screens.Rating.finish_title/2` for a film and the last episode tick for a series. `Dropped` and `paused` are `Kati.Screens.DropSheet`, which this finding's *Fix* line asked to be routed from the two detail screens and now is — film.ex:1169 and series.ex:1627 both push it with `params_for/1`.

### 13. 03 Library — `cannot-work`

**A film's progress rail and its percentage line can never be anything but empty, because the field they derive from has no writer.**

*Proof.* lib/kati/screens/library.ex:253 `seconds = tracked.progress_seconds` in `fraction_for(%TrackedTitle{kind: :movie}, ...)`. `grep -rn "progress_seconds" lib/` finds only readers — library.ex:253, up_next.ex:233/246, lock.ex:613 — and three comments quoting the resource: lib/kati/screens/home.ex:116 and lib/kati/screens/home_dark.ex:684 both say `Kati.Media.TrackedTitle` states of `progress_seconds` that "nothing writes it yet". So `fraction_for/3` returns nil for every film, `fraction/1` falls through to 0.0, and `tile_meta/1` falls to its last clause, "watching". The board's own mid-progress film tile is unreachable.

*Fix.* Either write `progress_seconds` from a resume/log-progress path for films, or drop the rail from film tiles rather than drawing an always-empty one.

*Fixed.* `fraction_for/3`'s film clause no longer draws an empty rail. A film with a logged watch is a film you are through and its rail says so (`seen > 0 -> 1.0`); one with neither a watch nor a resume point answers `nil` and draws no rail at all. `progress_seconds` is still unwritten and the clause that reads it says so in as many words — it is where a player would land, not a branch that runs.

### 14. 04 Series detail — `cannot-work`

**A tick is lost from the screen when you switch seasons and come back, because tick/2 updates series.episodes but never series.by_season, and switch/2 restores the stale list.**

*Proof.* lib/kati/screens/series.ex:1272-1280 updates only the :episodes key; defp switch/2 at series.ex:1209-1223 does `Map.fetch(s.by_season, label)` and replaces :episodes with view.episodes, which still carries the pre-tap watched flags. Same shape in series_fa.ex:990-1010 (toggle/2 vs switch/2 over :by_index).

*Fix.* Write the flipped list back into by_season[current_season] in tick/2 (and into by_index in SeriesFa.toggle/2).

*Fixed.* `tick/2` writes the flipped list back into `by_season[label]` as well as into `:episodes` (series.ex:1840-1842), and the comment above it states the rule this finding found: *`episodes` is the season on screen and `by_season` is every season, and `switch/2` restores the season on screen out of `by_season`.*

### 15. 06 Add a title (Kati.Screens.AddTitle) — `cannot-work`

**Two search results with the same title are indistinguishable: adding the second adds the first, and marks both.**

*Proof.* lib/kati/screens/add_title.ex:762 builds the tap tag as `String.to_atom("add_" <> title)` — identical for two rows with identical titles. add/2 at :453 does `Enum.find(socket.assigns.results, &(&1.title == title))`, which returns the first. mark/2 at :599 rewrites every row whose title matches. TMDB routinely returns remakes and same-named film/series pairs; board 06 itself draws three titles beginning 'Quiet'. The same line also mints a permanent atom per distinct provider-supplied title.

*Fix.* Key the tap on the row's {source, source_id} (or its index), not its title, and stop calling String.to_atom on provider data — use a stable positional or hashed tag.

*Fixed.* The tap is keyed on the row's own identity, not its title: `row_key/1` answers the `source_id` and falls back to the title only for a row that has none, and `add_button/2`'s comment states why it is not the position either — the chips renumber. Two remakes with one name are two rows now. The atom is still minted from provider data, and deliberately: the set is bounded by the ids a reader has actually searched, and a positional tag would reintroduce the defect the chips caused.

### 16. 06 Add a title (Kati.Screens.AddTitle) — `cannot-work`

**The Books shelf's + button opens the films-and-series sheet, and so does the Calendar root's.**

*Proof.* lib/kati/screens/root.ex:228 `def add_sheet, do: Kati.Screens.AddTitle` with defoverridable at :229; the FAB handler at :231 pushes it from every root. grep 'def add_sheet' across lib/ returns exactly two hits — root.ex:228 and lib/kati/screens/music.ex:1089 (AddTitleMusic). Kati.Screens.Books declares no override, so screen 20's + offers to add a film. lib/kati/screens/add_title_music.ex:12 refers to a fork function `Kati.Screens.AddTitle.for_shelf/1` that does not exist.

*Fix.* Override add_sheet/0 on Kati.Screens.Books to Kati.Screens.AddByHandBook's sheet (or a books state of 06), and decide what the Calendar root's + should open — a film sheet from the Schedule tab is the wrong door.

*Fixed.* Every root that needed a different sheet overrides `add_sheet/0`: `Kati.Screens.Books` answers `Kati.Screens.AddByHandBook` (books.ex:104), `Kati.Screens.Music` answers `Kati.Screens.AddTitleMusic`, and `Kati.Screens.Calendar` answers `Kati.Screens.QuickAdd` (calendar.ex:101) — a film sheet from the Schedule tab was the wrong door and this finding is what named it.

### 17. 07 Your year (Kati.Screens.Stats) — `cannot-work`

**The Films count on Your year can never be anything but 0, because no screen in the app creates a Watch row for a film.**

*Proof.* lib/kati/screens/stats.ex:1000-1002 counts distinct tracked_ids with kind == :movie among Watch rows. The only Ash.create of a Watch in lib/ is lib/kati/screens/series.ex:1308-1319 (an episode tick). Kati.Screens.Film's 'Log a watch' pushes the Rating sheet with only tracked_title_id (film.ex:922-930 -> rating.ex:362), and Kati.Screens.Rating.save_watch/1 is Ash.update only: save_watch(%{watch_id: nil}) returns {:error, :nothing_to_save} (rating.ex:1487-1503). grep 'Ash.create' over lib/ returns no Watch creation outside series.ex.

*Fix.* Give Kati.Screens.Rating a create branch when watch_id is nil and tracked_title_id is present, writing watched_on/watched_at plus the rating; or add a 'Mark watched' action to Kati.Screens.Film that writes the Watch directly.

*Fixed.* `Kati.Screens.Rating.save_watch/1` has the create branch this finding's *Fix* line asked for (rating.ex:2337), so a film can be logged and Your year counts it.

### 18. 07 Your year (Kati.Screens.Stats) — `cannot-work`

**Time watched reads 0h 0m no matter how many episodes the user ticks, because TV titles never get a runtime_minutes.**

*Proof.* lib/kati/screens/stats.ex:900 takes minutes from CachedTitle.runtime_minutes and stats.ex:948 sums (&1.minutes || 0). Kati.Media.Tmdb.upsert_title/3 sets runtime_minutes: positive(body["runtime"]) (lib/kati/media/tmdb.ex:187); TMDB's /tv/{id} returns episode_run_time, not runtime, so the column is nil for every series. The per-episode runtime is cached at lib/kati/media/tmdb.ex:245 on CachedEpisode.runtime_minutes and Stats never reads it. Kati.ScreenStatsTest passes only because its fixture hand-sets runtime_minutes: 47 on the TV title (test/kati/screen_stats_test.exs:299-301).

*Fix.* For an entry whose watch carries an episode_source_id, read the minutes off CachedEpisode.runtime_minutes; fall back to CachedTitle.runtime_minutes for whole-title watches. Also map episode_run_time into CachedTitle for TV in upsert_title/3.

*Fixed.* `Kati.Screens.Stats` reads the per-episode runtime a tick names — `Map.get(runtimes, watch.episode_source_id) || (cached && cached.runtime_minutes)` (stats.ex:1072), built from `Kati.Media.CachedEpisode` in `runtimes/1`. The comment above it states the fact this finding found: TMDB's `/tv/{id}` answers `episode_run_time` and not `runtime`, so the title column is nil for every series.

### 19. 08 Film detail — `cannot-work`

**Screen 08's 'Your rating' reads TrackedTitle.rating, which no control in the app writes; screen 33 writes Watch.rating instead. The two can never meet.**

*Proof.* lib/kati/screens/film.ex:235 `stars: star_count(tracked.rating)` reads the TrackedTitle column (tracked_title.ex:132). lib/kati/screens/rating.ex:1493 updates `Ash.get(Watch, id)` with `rating: ten_point(w.rating)`. Grepping every `Ash.update`/`Ash.Changeset.for_update` in lib/kati/screens/ (20 call sites) finds no writer for TrackedTitle.rating; the only TrackedTitle creates are add_title.ex:487 and :503, neither of which sets rating. test/kati/screen_film_test.exs:118 seeds `rating: 8` directly, which is why the test passes.

*Fix.* Have Film.shaped/3 derive stars from the newest rated watch, or have Rating.save_watch/1 also write TrackedTitle.rating.

*Fixed.* `Kati.Screens.Film.shaped/3` derives the stars from the newest rated WATCH — `newest_rating(watches) || tracked.rating` — which is the first of the two options this finding's *Fix* line offered, and the comment beside it records the device walk that proved the defect: rate Arrival four stars, save, reopen, blank card.

### 20. 08 Film detail / 33 Rating — `cannot-work`

**Even a successful save on 33 is invisible on 08, because a popped-to screen restores its saved socket and never re-reads.**

*Proof.* deps/mob/lib/mob/screen.ex:571-574: the `{:pop}` branch returns `{prev_module, prev_socket, rest, :pop}` — the saved socket verbatim; mount/3 and load/1 are not re-run. rating.ex handle_info({:tap, :save}) on success calls Mob.Socket.pop_screen(socket). This is the documented fork in MISSING-CONNECTIONS.md.

*Fix.* Upstream resume callback, re-mount instead of restore for store-reading screens, or vendor mob/screen.ex — a dependency-fork decision, not a screen fix.

*Fixed.* `Kati.Screens.Resume` is the mechanism `MISSING-CONNECTIONS.md` scoped, built without forking Mob: a screen that pops broadcasts `:resumed`, and the screen returned to refreshes. Screen 08 answers it at film.ex:1299 — hand-rolled rather than through `handle_kati/3`, because that screen is not `Kati.Screens.Pushed` — and re-reads the film by the `tracked_id` on screen so the refresh describes the same title the arrival did.

### 21. 08 Film detail / 33 Rating / 15 Activity — `cannot-work`

**No code path in the app can create a title-level Kati.Media.Watch, so a film can never be marked watched, rated, noted, or shown in Activity.**

*Proof.* grep for `for_create`/`Ash.create` against `Watch` across lib/ returns exactly one hit: lib/kati/screens/series.ex:1309, inside `Series.write_tick/2`, which is guarded by `write_tick(tracked_id, %{source_id: nil}) -> {:error, :no_episode_id}` and therefore requires an episode. lib/kati/screens/rating.ex:1487 `save_watch(%{watch_id: nil}), do: Write.note({:error, :nothing_to_save}, ...)` — the rating sheet only ever `Ash.update`s (rating.ex:1493). Trace: Film.handle_info({:tap, :log_watch}) (film.ex:923) -> Rating.params_for -> Rating.mount -> logged_record(id) -> newest_log(id) (rating.ex:379) filters `not is_nil(rating) or (not is_nil(review) and review != "")` -> nil for a film with no watches -> draft_and_id(nil) -> {drawn_watch(), nil} -> Save returns :nothing_to_save.

*Fix.* Add a title-level watch writer (mirror Series.write_tick/2 without episode_source_id) behind screen 08's ⋯ menu, and make Rating.save_watch/1 create against the pushed :tracked_title_id when watch_id is nil.

*Fixed.* `Kati.Screens.Rating.save_watch/1` creates a title-level watch (rating.ex:2337), and `Kati.Screens.RateEpisode` creates the episode-level one. The comment above the create names this finding's own grep as the thing that was true when it was written.

### 22. 10 Up next — `cannot-work`

**The first title a real user adds renders as a broken hero: no still, an empty meta line, no progress bar, and the section labels read "Ready to watch · 0" and "Gone cold · 0" over two empty sections.**

*Proof.* lib/kati/screens/add_title.ex:552-563 `create_cache/2` writes only `source: :manual, source_id: title, kind, title, fetched_at` — no `poster_path`, no `runtime_minutes`. In up_next.ex `hero_row/2` (:180): `episode(row)` is `[]` (both `progress_season` and `progress_episode` are nil), `hero_tail/2` (:224) falls to `runtime(cached)` which returns `[]` for `runtime_minutes: nil`, so `meta` is `""`; `fraction/2` (:249) answers `nil` so `progress/1` (:521) draws `~MOB"<Spacer size={0} />"`; `hero_art/1` (:496) draws a Spacer with no seed. `assemble/3` then labels the two sections with `length(rest)` = 0 and `length(cold)` = 0.

*Fix.* Omit an eyebrow whose section is empty (10 already argues this for the cold section elsewhere); draw a placeholder still rather than nothing; and hide the meta Text when it composes to an empty string.

*Fixed.* Both halves. `create_cache/3` takes an `extra` map, so the TMDB branch fills the poster and the runtime that `hero_tail/2` and `hero_art/1` read; a hand-typed row still has neither, which is honest — nothing knows a poster for a title nobody looked up — and draws the placeholder rather than a broken hero. And the two `· 0` labels are gone: `queue/0` answers `empty/0` for a shelf with nothing on the go and `nothing_ready/1` for one that is all cold, on screen 96's rule. See #49.

### 23. 10 Up next / 05 New releases / 11 Discover — `cannot-work`

**A title added from TMDB has no artwork anywhere in the app. `poster_path` is a TMDB CDN path and every screen resolves it as a filename in `priv/sample/design/`, so `Kati.Design.Images.poster/1` answers `nil` and the row draws a grey placeholder.**

*Proof.* lib/kati/design/images.ex:29 `file = Kati.Priv.path("sample/design/#{seed}_#{w}x#{h}.jpg"); if File.exists?(file), do: file, else: nil`. lib/kati/media/tmdb.ex:112 `poster_path: row["poster_path"]` — TMDB's `/abc123.jpg`. lib/kati/screens/up_next.ex:194 `seed_of(%CachedTitle{poster_path: path}), do: path`, then :633 `Sample.poster(row.seed)` → `Kati.Design.Images.poster/1`. `grep -rn 'image.tmdb.org' lib/` returns nothing — there is no image fetcher.

*Fix.* Either fetch and cache posters (a `Kati.Media` image cache keyed on `{source, source_id}`), or make the resolver explicit: seeds through `Design.Images`, anything starting `/` through a downloader, and keep the placeholder as the honest fallback rather than the universal one.

*Fixed.* `Kati.Media.Artwork` fetches and caches from `https://image.tmdb.org/t/p`, so a `poster_path` that is a TMDB CDN path resolves to a file. There was no image fetcher when this was written and that was the whole finding.

### 24. 11 Discover — `cannot-work`

**Tapping the `Awards` chip empties the entire page — no picks, no people, no leaving rows, no message. The chip row is left floating over a blank screen.**

*Proof.* lib/kati/screens/discover.ex:135-141 `shows?/2`: `"For you" -> true; "People" -> section == :people; "Leaving" -> section == :leaving; _ -> false`. Each of the three section functions (:299, :312, :325) returns `~MOB"<Spacer size={0} />"` when `shows?/2` is false, so all three vanish together. Nothing draws an empty state. Separately, the `Leaving` chip's count badge reads "5" while `Sample.feed().leaving` has two rows.

*Fix.* Draw an empty state under a chip that matches nothing, or drop the `Awards` chip — the moduledoc defends the blank page and it is not defensible on a phone. Make the chip count `length(f.leaving)`.

*Fixed 8 September.* `Kati.Screens.Discover.no_section/2` draws a card when the chosen chip hides every section, naming the chips that do have something — screen 03's `nothing_here/1` one screen over, for its reason. On a device the rail is not drawn at all unless the feed carries two sections; the board's own fixture carries four chips, which is what a fresh install sees and what this finding was reported from. The Leaving badge counts `length(feed.leaving)` and no longer a frozen 5.

### 25. 144 Rate an episode — `cannot-work`

**The screen can never display a real episode rating and cannot create one. Its query requires a Watch row carrying a rating or a review, and the app's only episode-level Watch writer sets neither; its stars are not tappable; and Save pops the screen without writing.**

*Proof.* lib/kati/screens/rate_episode.ex:305-316 filters `not is_nil(episode_source_id) and (not is_nil(rating) or review != "")`. The only writer of episode_source_id is lib/kati/screens/series.ex:1308-1318, whose create attrs are tracked_title_id, episode_source_id, watched_at, watched_on — no rating, no review. rate_episode.ex:640 calls `Rating.stars(s.rating)` at arity 1, and rating.ex:1002 defaults tappable? to false, so star_cell/3 returns a bare glyph (rating.ex:1080). rate_episode.ex:1007 is `handle_info({:tap, :save}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}`; screen 33's equivalent calls save_watch/1 first (rating.ex:1419-1430).

*Fix.* Push 144 with the tracked title and episode_source_id from 04; call Rating.stars(s.rating, true) and add the ten star_N handlers; make :save create or update a Watch with the rating before popping.

*Fixed.* `Kati.Screens.RateEpisode.save_rating/1` creates the watch (rate_episode.ex:1261) rather than requiring one to exist, the stars are drawn through `Rating.stars/2` with `writable?/1` deciding whether they are tappable, and Save reports a refusal instead of popping over it.

### 26. 145 Shelf filter sheet — `cannot-work`

**The sort/filter sheet the Library's sort disc opens is entirely fixture data, has no way to learn which shelf opened it, and hands nothing back — so no sort or filter chosen on it can ever affect the shelf.**

*Proof.* lib/kati/screens/shelf_filters.ex:79 `def mount(_params, _session, socket)` — the params are discarded. Every value comes from lib/kati/library/shelf_filters_sample.ex: `total/0` is the literal 418, `decades/0` 24/38/11/6, `ratings/0` 31/52/9, `genres/0` 41/12/8/0, `services/0` 22/7/3/2. `mount/3` assigns `showing: 41` as a literal. The only exits are `handle_info({:tap, :close})` -> `pop_screen/1` and `:reset`; there is no Apply, and `grep -oiE "Apply|Reset|Done|close" test/design/screens/145.html` returns one Reset and one close, so the board does not draw one either. lib/kati/screens/library.ex:1266 admits it: "there is no key to name a shelf in, and writing one the sheet does not read is an argument nobody can check."

*Fix.* Give `mount/3` a `shelf:` param and derive the facets from `Kati.Screens.Library.shelf/0`, then return the chosen sort and buckets to the caller (a `pop_to` with params, or a `Mob.State` handover the way `Kati.Search.hand_over/1` works). Until then the sort disc on 03 should not open it.

*Fixed.* The choice is durable rather than handed back: `Kati.Library.ShelfFilters` keeps it in `Mob.State` and `Kati.Screens.Library.shelf/1` applies it on every read (library.ex:212, :237). So the sheet needs no Apply and no knowledge of which shelf opened it — which is why the board draws neither. `showing` counts `ShelfFilters.apply/2`'s own result rather than the literal 41.

### 27. 146 Shelf selection mode — `cannot-work`

**Selection mode operates on a fixture shelf and every action — select, Status, Remove, Undo — mutates assigns only; nothing reaches the store, so nothing survives closing the screen.**

*Proof.* lib/kati/screens/shelf_selection.ex:229 `titles = Sample.selection_shelf()` (Kati.Library.Sample). `grep -n "Ash\." lib/kati/screens/shelf_selection.ex` returns nothing. `handle_info({:tap, :remove_selected})` at :895 does `Enum.split_with` and assigns `:titles`/`:undo`; `handle_info({:tap, :change_status})` at :885 calls the private `toggle_done/2`, which is `Map.update!(item, :done?, &(not &1))` on a plain map; `:add_to_list` at :882 pushes `Kati.Screens.Lists` and discards the selection entirely. The screen also draws three stills (`resting_header_still/0`, `one_selected_still/1`, `undo_band/1` before any Remove) that are visually indistinguishable from live controls except that they do not respond.

*Fix.* Read `Kati.Screens.Library.shelf/0` and make Remove destroy the selected `TrackedTitle` rows (with a real undo window), or take the screen out of the Library's ⋯ menu until it can.

*Fixed.* Selection mode reaches the store — eight `Ash.` call sites in `Kati.Screens.ShelfSelection` where the grep in this finding returned none.

### 28. 154 Add a title by hand (Kati.Screens.AddByHand) — `cannot-work`

**A successful save returns the user to screen 06's fixture list, which board 155 explicitly ruled out.**

*Proof.* lib/kati/screens/add_by_hand.ex:467 `Mob.Socket.pop_screen(socket)`. test/design/screens/155.html, band 'Where Add to library goes': 'Straight to the new title's detail screen — 04 for a series, 08 for a film. Returning to 89 would leave the person on a search results page for a title they just finished typing; the detail screen is where the next thing they want to do lives.' The screen popped to (06) also still shows Sample.search_results() (add_title.ex:101), so the user lands on four films they did not add.

*Fix.* reset_to / push the detail screen for the row just written — Kati.Screens.Series for :tv, Kati.Screens.Film for :movie — replacing 154 and 06 in the stack.

*Fixed.* `Kati.Screens.AddByHand.opened/2` resets to the new title's own detail screen — `Kati.Screens.Film` for a film, `Kati.Screens.Series` for a series — carrying its id and a `Library` back label. That is board 155's ruling word for word, and the fixture list this finding landed on is no longer where a save goes.

### 29. 157 Add by hand — dark (Kati.Screens.AddByHandDark) — `cannot-work`

**None of the three text fields accept input, and Add to library writes the hardcoded fixture title 'The Long Hollow' into the user's real library.**

*Proof.* lib/kati/screens/add_by_hand_dark.ex defines only load/1 (:35), content/1 (:49) and handle_tap/2 (:52). It defines no handle_info({:change, …}) clause, and Kati.Screens.Pushed's generated clauses (lib/kati/screens/pushed.ex:72-87) are {:tap,:back}, {:tap,tag}, {:kati,…} and a no-op catch-all — none matches {:change, …}. So assigns stay at load/1's `title: "The Long Hollow", kind: :tv, year: "2024"` (:37-44), and handle_tap(:add) delegates to AddByHand.save/1, which writes that title.

*Fix.* Add `def handle_info(msg, socket), do: AddByHand.handle_info(msg, socket)` (or delegate the :change clause), and load/1 should open empty like 154 rather than pre-filled — a form that opens holding a fixture saves the fixture.

*Fixed.* `Kati.Screens.AddByHandDark` answers `{:change, field, typed}` (add_by_hand_dark.ex:66) and hands it to the same handler screen 154 uses, so the three fields hold what was typed and Add to library writes it.

### 30. 157 Add by hand — dark (Kati.Screens.AddByHandDark) — `cannot-work`

**Opening this board from the gallery leaves the entire app in dark mode until the next mount that reactivates the preference.**

*Proof.* lib/kati/screens/add_by_hand_dark.ex:36 `Mob.Theme.set(Kati.Theme.dark())` in load/1. Mob.Theme.set/1 is global and popping the screen does not remount the screen underneath — the module's own moduledoc states this and names screens 28, 29 and 68 as carrying the same cost.

*Fix.* Restore the previous theme on :back, or delete the module once Kati.Shell carries dark as a mode and 154 renders in it directly.

*Fixed.* `Kati.Screens.Resume.pop/1` calls `Kati.Theme.activate/0` before it pops — one call at the one place every back control in the app already goes through, rather than seven dark boards each remembering to put the preference back. That module's own doc names this finding; a board whose palette IS dark re-asserts it on `handle_kati(:resumed, …)`.

### 31. 18 Quick add (Kati.Screens.QuickAdd) — `cannot-work`

**The screen has no text field, no parser and no writer — the field, the parse card, the clash warning and the commit button are all fixtures, and it is reachable from the Calendar dock root.**

*Proof.* lib/kati/screens/quick_add.ex:85 mount/3 assigns only `Sample.draft()`; field/1 (:195) draws Sample.query/0 as tinted <Text> runs and the file contains no <TextField>. actions/1 (:534) does `tap = Map.get(draft, :on_commit)` and Kati.Screens.QuickAdd.Sample.draft/0 supplies no :on_commit, so the 52pt primary button and the mic (:579) both reach the wire with no on_tap. Reachable via lib/kati/screens/calendar.ex:303 -> :1237 (routes.txt lists it as unreached only because the overflow panel is not drawn until :toggle_menu fires).

*Fix.* Either remove the 'Quick add' item from screen 02's overflow until a parser exists, or replace the drawn sentence with a real <TextField> and an honest 'Kati cannot read that yet' state.

*Fixed.* Screen 18 has two `<TextField>`s, `parsed/1` reads what was typed, and the commit writes: `Ash.create(Kati.Calendars.Event, …)` at quick_add.ex:434, creating a `Personal` calendar to hang it on when the device has none.

### 32. 19 Search — `cannot-work`

**The note card's highlight is computed against the normalised body and sliced out of the raw body, so any note with leading or doubled whitespace, a ZWNJ or harakat highlights the wrong characters — and a body that lengthens under downcasing takes the whole Notes group out silently.**

*Proof.* lib/kati/search/query.ex `note_card/2`: `case :binary.match(normalise(body), normalise(query)) do {at, len} -> %{lead: body |> binary_part(0, at) ..., match: binary_part(body, at, len), tail: binary_part(body, at + len, byte_size(body) - at - len)}`. `Kati.Search.normalise/1` (lib/kati/search.ex) trims, collapses `~r/\s+/u` to one space, strips ZWNJ and U+064B-0652, and downcases — every one of which shifts byte offsets. Trace: body `"  The hollow ground"`, query `hollow`. normalised = `"the hollow ground"`, match at 4 len 6. Applied to the raw body: lead = `"  Th"`, match = `"e ho"`, tail = `"llow ground"`. When downcasing lengthens (U+0130 -> two codepoints) `at + len` can exceed `byte_size(body)` and `binary_part/3` raises, which `note_for/1`'s `rescue _error -> nil` swallows — the Notes group vanishes with no error.

*Fix.* Match on the raw body with a case- and diacritic-insensitive scan that keeps raw offsets, or normalise once and slice the normalised string for display.

*Fixed.* `Kati.Search.locate/2` finds the match in the RAW body rather than slicing raw offsets out of a normalised one, and a match that cannot be pointed at draws the card whole and unhighlighted rather than dropping it — `note_card/2`'s `:nomatch` clause, with the Persian case that forced it written out beside it.

### 33. 58 سریال — `cannot-work`

**Marking an episode watched on the Persian page writes nothing. The ring fills, the counter moves and the button relabels, and every one of those changes is discarded when the screen is popped.**

*Proof.* lib/kati/screens/series_fa.ex:1007-1010 — `defp toggle(series, index)` flips `watched` in the assign and calls recount/1; no call to Kati.Screens.Series.write_tick/2 anywhere in the file (grep 'write_tick' returns nothing). shaped/1 (series_fa.ex:195-212) does not carry :tracked_id, so no write is possible without adding it. Screen 04 writes via series.ex:1272-1286.

*Fix.* Carry :tracked_id and each row's :source_id through SeriesFa.shaped/1, and route :mark_next and 'episode_' taps through Kati.Screens.Series.tick/2 the way Kati.Screens.Season.tick/2 already does.

*Fixed.* `Kati.Screens.SeriesFa` carries `tracked_id` (series_fa.ex:219) and its tick calls `Kati.Screens.Series.write_tick/2` (series_fa.ex:1053) — the English screen's writer and not a second one — then restates from the store.

### 34. 91 Search at 235% — `cannot-work`

**The defect 91 was drawn to document is live on screen 19 and unfixed: at large text a search hit stops showing its own words, and 86's scope chips hide behind a horizontal scroll.**

*Proof.* lib/kati/screens/search.ex `title_row/1` is a `<Row>` whose title and sub `<Text>` both carry `max_lines={1}` inside a fixed-height band. lib/kati/screens/search_large.ex's moduledoc: "That pair of ones IS the row ... at 235% the row does not survive; it just stops showing the words", and "`Kati.Screens.SearchIdle.chips/1`, a `<Scroll axis=\"horizontal\">` ... is the builder this board exists to contradict" — lib/kati/screens/search_idle.ex `chips/1` is indeed `<Scroll axis="horizontal">`.

*Fix.* Apply 91's own answer to 19 and 86: stack the hit above ~200% and wrap the chips three to a row instead of scrolling them.

*Fixed; the last of it 8 September.* The hit row survives large text: `title_row/1`'s two `Text` nodes take `max_lines={3}` and `{2}` where board 91 found a pair of ones inside a fixed-height band. The chip row is board 313's ruling rather than 91's objection — a scroll is right for chrome and a wrap is not available on the bridge (mishka-group/kati#98) — but 313 requires the scroll to carry a mark, and screen 86's row had none. It calls `Kati.Screens.Search.chip_line/1` now, so both pages draw one control.

### 35. 92 My services / 93 nothing set up — `cannot-work`

**The `Show all 47 · Everything JustWatch lists for the UK` row opens the wrong screen on both boards, and no catalogue screen exists anywhere in the app. From 92 it opens 93 — a board that announces "Subscribed · none yet" and "Pick your country · Nothing works until this is set" to a user who has three services and a country. From 93 the identical row opens screen 23, the money ledger.**

*Proof.* lib/kati/screens/my_services.ex:568 `def handle_tap(:show_all, socket), do: … push_screen(socket, Kati.Screens.MyServicesEmpty)`. lib/kati/screens/my_services_empty.ex:393 `def handle_tap(:show_all, socket), do: … push_screen(socket, Kati.Screens.Subscriptions)` — and :396 `handle_tap(:open_subscriptions, …)` pushes the same screen, so two different rows on 93 are one destination. `Kati.Services.Sample.catalogue_count/0` is the literal string "Show all 47" (lib/kati/services/sample.ex:59).

*Fix.* Either build the provider list (TMDB `/watch/providers/movie?watch_region=<region>`, which is the same client `Kati.Media.Tmdb` already speaks) or remove the row from both boards. It must not point at a states board.

*Fixed.* The *Not mine* row no longer says `Show all 47`; `Kati.Screens.MyServices`'s own doc at :972-990 records the change and what the row says instead. There is still no catalogue screen and the row does not pretend there is.

### 36. 94 Country picker → 92 My services — `cannot-work`

**Picking a country writes the region but the page you come back to still shows the old one. Mob's pop restores the saved socket rather than re-mounting, and 92's region row is drawn from `assigns.region`, which was read once at mount.**

*Proof.* deps/mob/lib/mob/screen.ex:571 `{:pop} -> case nav_history do [{prev_module, prev_socket} | rest] -> {prev_module, prev_socket, rest, :pop}` — no `mount`, no `load`. lib/kati/screens/my_services.ex:93 `Mob.Socket.assign(:region, Services.region())` in `load/1`; :180 `region_group(assigns.region)`. lib/kati/screens/country_picker.ex:125-127 writes through `Services.put_region/1` then pops. (The service list does refresh, because `content/1` calls `subscribed/0` at render — which makes the inconsistency visible on one screen.)

*Fix.* Have 94 hand the code back — `Mob.Socket.pop_screen` with a result, or have 92 read `Services.region()` in `content/1` the way it already reads `subscribed/0`, not from assigns.

*Fixed.* `Kati.Screens.MyServices.handle_kati(:resumed, …)` re-reads the region when the picker pops back, through `Kati.Screens.Resume` — the mechanism `MISSING-CONNECTIONS.md` scoped for exactly this, built without forking Mob.

### 37. 03 Library — `lies-to-user`

**Tapping a filter chip that matches nothing leaves a blank space under live chips with no card and no explanation — which, because Not started and Finished are always 0, is what every user sees when they tap either of them.**

*Proof.* lib/kati/screens/library.ex `shelf_body/3` has one branch, `def shelf_body(_filter, _shelf, []), do: empty_state()` — on the SHELF being empty. With rows present it always returns `[chips(...), grid(...)]`, and `grid/3` chunks `visible/3`'s output, which is `[]` for a filter that matches nothing, producing a `<Column>` with no children. The moduledoc argues this deliberately ("the four counts beside the chips say which one to tap next"), which holds when a count is non-zero; combined with the status defect above, Finished and Not started are always 0 and always produce this blank.

*Fix.* Draw a small 'nothing in this filter' line when `visible/3` is empty but the shelf is not.

*Fixed.* `grid/2` answers an empty filter with `nothing_here/1` rather than a `Column` of nothing, and that function's own doc cites this finding. The second half went with it: all four chips can count something now — see #12.

### 38. 04 Series detail — `lies-to-user`

**A hand-typed series opens as somebody else's show. Screen 04 finds the user's tracked row, discovers it has no cached seasons or episodes, and silently falls back to Kati.Library.Sample — so every hand-added series draws 'The Long Hollow' with hollow71 artwork, three seasons and seven named episodes, none of which the user has ever heard of.**

*Proof.* lib/kati/screens/series.ex:299-303 — facts/1 answers nil for `season_numbers(seasons, episodes) == []`; series/1 (series.ex:159-164) turns that nil into drawn_series(). The only writer of CachedSeason/CachedEpisode is Kati.Media.Tmdb.fetch/2 (lib/kati/media/tmdb.ex:142), called only from add_title.ex:485 on the TMDB branch; add_by_hand.ex:478-485 writes a :manual TrackedTitle with no seasons. design-briefs/D-58-a-title-with-nothing-under-it.md is this exact case; its boards 248/249 do not exist in test/design/screens/.

*Fix.* Add facts/1's third branch: when the tracked row exists but has no seasons, return a map marked as episode-less and draw the D-58 claim card (poster placeholder, typed title and year, status chip, 'No episode list yet.', no Mark-next-watched button) instead of Sample.

*Fixed.* `facts/1` has the third branch this finding's *Fix* line asked for. A tracked series whose provider has filled nothing in answers `no_episodes/2` rather than `nil`, so the page draws the reader's own row; the comment at series.ex:302-311 states the distinction it turns on — the gate is about whether a ROW exists, not about whether a provider has answered.

### 39. 04 Series detail / 34 Season — `lies-to-user`

**:save_error is assigned on both screens and rendered on neither, so every failed episode tick fails silently — including the one that happens on every device today, where the drawn series carries no :tracked_id and write_tick returns {:error, :not_tracked}.**

*Proof.* lib/kati/screens/series.ex:1284 and lib/kati/screens/season.ex:235 assign :save_error; neither render/1 (series.ex:578-610) nor content/1 (season.ex:529-551) reads it, and neither mount/load initialises it. Ten other screens do render it — add_by_hand.ex:87, log_weight.ex:95, add_title_music.ex:166, meal_edit.ex:282, … . Kati.Library.Sample.series/0 (library/sample.ex:150-171) has no :tracked_id key, so write_tick(nil, _) hits series.ex:1290.

*Fix.* Draw the notice on both screens the way add_by_hand.ex:87 does. Separately, this assign is why Kati.ScreenTapSweepTest's dead-tap heuristic passes these taps: it compares assigns, and an unrendered assign counts as a change.

*Fixed.* Both screens draw the notice: `Kati.Screens.Series.refusal/1` at series.ex:724 and `Kati.Screens.Season.refusal/1` at season.ex:864, each reading the `:save_error` its own `tick/2` writes.

### 40. 04 Series detail → 34 Season — `lies-to-user`

**Opening 'Episode order' from the drawn series shows a different Season 2 from the one on screen: 04 lists 'The Weight of Water / Hollow Ground / …' from Kati.Library.Sample and 34 lists 'Low Water / The Estuary / The Cull' from Kati.Season.Sample, one back tap apart.**

*Proof.* lib/kati/library/sample.ex:150-171 vs lib/kati/season/sample.ex:23-77. Season.params_for/1 (season.ex:291-300) yields %{} when the series map has no :tracked_id, which is exactly the drawn case, so 34 falls back to its own fixture rather than being told which season 04 is showing.

*Fix.* Make the two fixtures one — Kati.Season.Sample should derive from Kati.Library.Sample's S2 — or suppress the menu row entirely on the drawn page.

*Fixed.* `Kati.Library.Sample.series/0`'s episodes ARE board 34's list — 34's aired order, runtimes and dates, less the making-of, because a special is what board 34 is about and screen 04 draws no badge to say a row is one. The comment at library/sample.ex:161-173 names this finding and the two lists it reconciled.

### 41. 06 Add a title (Kati.Screens.AddTitle) — `lies-to-user`

**Removing a title you added from TMDB reports success and deletes nothing — the check flips back to a + while the row stays in the library forever.**

*Proof.* lib/kati/screens/add_title.ex:567 untrack/1 filters `&(&1.source == :manual and &1.source_id == title)`. A TMDB add wrote `source: :tmdb, source_id: <numeric tmdb id>` at add_title.ex:496-501. The find returns nil, untrack answers {:ok, :already_gone}, add/2 (:462) takes the {:ok,_} branch and calls mark/2 (:599), which flips `added` to false. Store unchanged; UI says removed.

*Fix.* untrack/1 must take the row (source + source_id), not the title: `Enum.find(rows, &(&1.source == row.source and &1.source_id == row.source_id))`. add/2 already has the row from :453 — pass it through.

*Fixed.* `untrack/2` resolves the row's own `{source, source_id}` through `tracked_key/2` rather than assuming `:manual` and the title, so a TMDB add is found and destroyed — and a row that is genuinely gone answers `{:ok, :already_gone}` rather than reporting a delete that did not happen.

### 42. 06 Add a title (Kati.Screens.AddTitle) — `lies-to-user`

**Every write failure on this screen is silent: :save_error is assigned in three places and rendered nowhere, so adding a duplicate title is a tap into total nothing.**

*Proof.* lib/kati/screens/add_title.ex — assigned at :104, :282, :467 and :470; grep for save_error finds no read. render/1 (:114-137) draws header, field, chips, search_notice(:search_error), eyebrow, results, by_hand. The duplicate path: tracked_titles has `index [:source, :source_id], unique: true` (lib/kati/media/tracked_title.ex:64), so a second Ash.create errors, add/2 hits :470, and mark/2 is never called — the disc does not even change.

*Fix.* Draw it. `{Kati.Screens.AddTitle.search_notice(assigns[:save_error])}` above the results (or a dedicated save_notice/1), exactly as Kati.Screens.AddByHand.error/1 does at add_by_hand.ex:373.

*Fixed.* `save_notice(assigns[:save_error])` is drawn at add_title.ex:189, so a refused add says why.

### 43. 06 Add a title (Kati.Screens.AddTitle) — `lies-to-user`

**The sheet opens on four invented films with real poster images, a '4 results' count and fake availability lines, and one of them is drawn as already in the library when it is not.**

*Proof.* lib/kati/screens/add_title.ex:101 `results: Sample.search_results()` in mount/3, and again at :233 whenever the query drops below three characters. lib/kati/library/sample.ex:263-294 supplies The Quiet Coast / Quiet Earth / A Quiet Place to Land / Quietus, with `added: true` hardcoded on the third (:284) and `seed:` values that thumb/1 (add_title.ex:735) resolves to real images via Kati.Design.Images.poster/1. Tapping any of their + discs runs the :manual branch of track/2 (:498) and writes a real TrackedTitle + CachedTitle to the shelf.

*Fix.* Give the screen a real resting state — empty field, no rows, a prompt — and drop the Sample fallback entirely. The fixture rows must not be tappable into the store.

*Fixed.* `mount/3` opens on `results: []` and the eyebrow reads `SEARCH` rather than a count, which is board 308's first band: *`0 results` over a sheet nobody has asked anything of is a report on a search that has not happened.*

### 44. 06 Add a title (Kati.Screens.AddTitle) — `lies-to-user`

**Typing one or two characters restores the four fixtures under a '4 results' caption, so short real titles (Up, It, Us) are answered with films the user did not search for.**

*Proof.* lib/kati/screens/add_title.ex:222 `@min_query 3`; :228-238 — below the floor the handler assigns `Sample.search_results()` and clears :search_error. render/1 then captions them `#{length(shown)} results` (:112). Deleting a query back to empty does the same, replacing real TMDB results with fixtures.

*Fix.* Below the floor: empty results and a prompt ('Keep typing…'), never the sample. Lower the floor to 1 if TMDB tolerates it; /search/multi does.

*Fixed.* A query below the floor empties the list rather than restoring the drawing's four, and the floor is `Kati.Search.long_enough?/1` — the rule screen 86 already states — rather than a second number that could drift from it. Typing `Up` answers nothing rather than four films nobody searched for.

### 45. 07 Your year (Kati.Screens.Stats) — `lies-to-user`

**On any device with at least one tick, 'Where the hours went' and the 'More numbers' second lines are the fixture's, sitting directly under the user's real figures.**

*Proof.* lib/kati/screens/stats.ex:965 sets breakdown: Sample.year().breakdown inside year/1, so Drama 128h / Documentary 71h / Comedy 49h / Thriller 38h / Everything else 26h draw on every device — 312 hours of bars under a headline that is currently 0h 0m. counted/1 calls more_numbers(true) (stats.ex:203), which draws Kati.Stats.Sample.more_numbers/0's subs including '1,204 entries' and '£46.47 a month · 7 expenses' (stats/sample.ex:29-41).

*Fix.* Draw no breakdown card until CachedTitle.genres has a defined separator and a reader, exactly as the empty branch already does; and use more_numbers(false) on both branches until each domain can answer its own line.

*Fixed.* `breakdown: genre_bars(this)` (stats.ex:1166) — the bars are the reader's own watches by genre.

### 46. 07 Your year (Kati.Screens.Stats) — `lies-to-user`

**Recently watched labels every real episode tick 'SERIES', never 'S2 E5', because the tick writer stores no season or episode number.**

*Proof.* Kati.Screens.Series.write_tick/2 creates a Watch with only tracked_title_id, episode_source_id, watched_at and watched_on (lib/kati/screens/series.ex:1308-1319). Kati.Screens.Stats.recent_label/1 needs integer season and episode to render 'S#E#' (stats.ex:1091-1094) and otherwise falls to the kind clauses (stats.ex:1096-1100). test/kati/screen_stats_test.exs:303-310 sets season_number: 2, episode_number: 5 by hand, which is why the suite never sees this.

*Fix.* Have write_tick/2 carry the episode's season_number and episode_number onto the Watch (the episode map on screen 04 already has both), or have Stats resolve them from CachedEpisode via episode_source_id.

*Fixed.* `write_tick/2` stores `season_number` and `episode_number` on the watch (series.ex:2035-2036), so `recent_label/1` can render `S2 E5`.

### 47. 07 Your year (Kati.Screens.Stats) — `lies-to-user`

**A first year draws a green '↑ 0%' pill against a prior year that does not exist, and a falling year draws a green pill with a down arrow in it.**

*Proof.* lib/kati/screens/stats.ex:983 defp change(_now, 0), do: 0, and year/1 sets rising?: change >= 0 (stats.ex:958-961), so year one is rising? true with change '0%'. The moduledoc above it claims this branch reports 100%. The pill's background is Palette.green_wash() (stats.ex:416) and its text Palette.green_text() (stats.ex:424) unconditionally; only arrow/1 (stats.ex:466-471) varies.

*Fix.* Draw no pill at all when there is no comparable prior span (the empty-state reasoning from board 123 applies), and pick the wash/text pair from rising? so a fall is not green.

*Fixed.* A year with nothing to compare against carries `change: nil` and `change_pill/1` draws nothing at all for it — no pill rather than a green `↑ 0%` against a year that does not exist. A falling year is `rising?: false`, which takes the red ground and the down arrow together.

### 48. 08 Film detail — `lies-to-user`

**An untracked shelf tile opens a page titled 'Blue Hour' with a stranger's note and a fabricated £9.99 price, whatever the tile was captioned.**

*Proof.* lib/kati/library/sample.ex:23-33 (@titles) carries no :id key, so Library.open_tile/3 (library.ex:1044-1048) pushes Film bare. film.ex:117 `film/0 = tracked_film(id) || drawn_film()`; with no tracked movie newest_film/0 answers nil and drawn_film/0 = Kati.Library.Sample.film/0 (library/sample.ex:298-316), which carries title 'Blue Hour', a note about the Rex, and `where: [%{name: "Kino store", price: "£9.99"}]`. Kati.Seeds.groups/0 (seeds.ex:143-152) seeds only :calendars and :media (CachedTitle) — no TrackedTitle — so a seeded device has an empty shelf and hits this on every tile.

*Fix.* Draw the empty/unknown state on 08 when the tap carried no id, rather than substituting a different film; and never draw the fixture's `where` rows outside the design gallery.

*Fixed.* `open_tile/3` passes the row's own id when it has one (library.ex:1463-1466), and a shelf row always does — the fixture is no longer what an empty shelf draws, so there is no untracked tile to open. See #11 and #37.

### 49. 10 Up next — `partly fixed`, 6 September

**With any real library the header counts are wrong and with a partly-real one the whole page reverts to fixtures. `queue/0` falls back to `Sample.queue/0` whole whenever there is no `:watching` row — so a user whose shows are all paused sees four invented titles and none of their own. And the fixture itself says "12 ready" over four rows and "Gone cold · 3" over one.**

*Proof.* lib/kati/screens/up_next.ex:110-115 — `case tracked(:watching) do [] -> Sample.queue(); [hero | rest] -> assemble(hero, rest, tracked(:paused)) end`. `tracked(:paused)` is only reached on the second branch. lib/kati/screens/up_next/sample.ex:21-23 — `subtitle: "12 ready · 4 airing soon"`, `ready_label: "Ready to watch · 12"`, `cold_label: "Gone cold · 3"` against a `ready` list of 4 and a `cold` list of 1. Library's own tile is honest by contrast — `up_next_badge/1` (library.ex:762) answers `nil` on an empty shelf — so the tile shows no count and the page it opens announces twelve.

*Fixed — the first half, as prescribed.* `queue/0` now branches on both reads. A reader whose shows are all paused gets their own titles in the cold section, no hero at all, and a card where the hero would be saying why — *Nothing ready to watch. Everything on your shelf is paused.* The ready eyebrow is dropped with its section rather than drawn over nothing. `Kati.ScreenUpNextTest` holds it, including that none of board 10's four titles appears.

*Not changed, deliberately.* The subtitle and the eyebrow count different things and each counts its own thing exactly: `3 ready` is everything ready including the hero, and `Ready to watch · 2` labels the two rows under it. Board 10's `12 ready` over `Ready to watch · 12` over four rows is a drawing showing a slice of a longer list, and is not a semantics a page that draws the whole list can copy. Making the two agree was tried and reverted: it turned an exact section label into one that overcounts its own rows.

*Still open.* The fixture's own counts — `12 ready` over four rows, `Gone cold · 3` over one — are shipped to a device with an empty library, because screen 10 is gated at `fallbacks/0` and answers the board when there is nothing stored. That is a board question: 10 has no empty state of its own.

*Fixed 7 September.* `shelf?/0` separates a shelf with nothing on the go from a store that cannot be read; only the second draws the board.

### 50. 11 Discover — `fixed ca8f89e` and `1b1293f`, 6 September

**Discover is a fixture end to end — no `Kati.Media` read anywhere — and it prints six specific claims about the user: "Tuned to 128 titles", "Because you watched The Long Hollow", three match percentages, three people the app has never heard of, and "Leaving Lumen+ in 7 days" for a service that may not be on the account.**

*Proof.* lib/kati/screens/discover.ex:100-107 `load/1` assigns `Sample.feed()` and nothing else; there is no `Ash.Query` or `Kati.Media` alias in the file. lib/kati/screens/discover/sample.ex holds every string. test/kati/screen_sample_only_test.exs:78 lists `{"11", Kati.Screens.Discover}` as permanently sample-only. The moduledoc concedes there is no recommender and no person table.

*Fixed, and not the way this said.* One of the three sections COULD be made true: TMDB answers `/movie/{id}/recommendations` and `/tv/{id}/recommendations`, which is a real recommendation from a real corpus keyed on a title the reader actually tracked — exactly what *Because you watched* claims to be. `Kati.Media.Recommendations` is that, seeded on the newest touched `Kati.Media.TrackedTitle`, asked from a task under `Kati.TaskSupervisor` rather than from `mount/3`, and matched against the seed it was asked about before the answer is taken.

The rest went the way this prescribed: people and Leaving are `[]` on a real device and their eyebrows, their chips and the *Tuned to N titles* line are dropped with them. The board still draws all of it.

No match percentage was invented to fill the gap under a title. TMDB's ordering is a ranking; a match is a statement about a title against one person's history, and Kati runs no recommender and has no column to keep such a number in.

The picks are also tappable now (`1b1293f`) — see scenario 14. And screen 11 no longer suggests something already on the shelf.

### 51. 14 Series metadata — `fixed 5915c2a`, 6 September

**Show details always describes The Long Hollow — a fixed synopsis, three ratings, four named cast members with character names, priced Where-to-watch rows and five tags — regardless of which series' overflow menu opened it. The push carries no subject and the screen would ignore one.**

*Proof.* lib/kati/screens/series_meta.ex:98-101 — `def mount(_params, _session, socket)` assigns `Sample.series()` unconditionally. series.ex:1135-1136 pushes it with no params. Four values the app can express today — title, artwork, Kati.Media.CachedTitle.overview and TrackedTitle.rating — are not read.

*Fixed.* Exactly as prescribed. `Kati.Screens.SeriesMeta.params_for/1` reads screen 04's `tracked_id`, `series/1` reads the shelf row and the cache behind it, and `shaped/2` fills the four expressible keys and empties the seven that are not. `band/4` drops a heading whose section is empty. `Kati.SeriesMetaSubjectTest` holds both halves — a real title is that title and does not borrow the fixture's cast; an empty store still draws the board whole.

*One correction to the prescription.* `TrackedTitle.rating` is NOT drawn, so *Yours* is absent too. That column has no writer anywhere in the app — `Kati.Screens.Film.shaped/3` documents this at length — and the ratings this app does write are `Kati.Media.Watch.rating` against one episode, which is not the show's score. Three empty rating cards were the alternative and would have been the same defect at a third the size.

*Left open.* The page is now honest and short: a still, a title, a meta line and a paragraph, then nothing. What fills the space the four dropped bands leave is a design question, not a data one — see `design-briefs/D-63`. Candidates the store can already answer: the tracked status, `runtime_minutes` as an episode length, `next_release_at` as the next airing, and the per-season episode counts screen 04 already reads.

### 52. 140 Import — where are you coming from (Kati.Screens.ImportSources) — `lies-to-user`

**All six source tiles discard which source was tapped and push the same Goodreads books board, so Letterboxd, Trakt, MyAnimeList and AniList all land on a screen about books.**

*Proof.* lib/kati/screens/import_sources.ex:393-397 matches "source_" <> _id and ignores the id, pushing Kati.Screens.ImportRecognised unconditionally. ImportRecognised.load/1 assigns Kati.Import.Sample.recognised/0 (import_recognised.ex:139-141), a fixed Goodreads export whose columns are Author, Bookshelves, Number of Pages. test/design/screens/141.html contains 'Goodreads' four times and no film/TV source at all.

*Fix.* Carry the tapped id into ImportRecognised as a screen param and branch the drawn source on it; at minimum add a film/TV job to Kati.Import.Sample so a Letterboxd tap does not draw a book export.

*Fixed.* `tag/1` builds `source_<id>` per tile and `handle_tap/2` splits it back apart, so a tile opens the file picker remembering which source it was — the shape screens 98 and 03 already use for a tag per member of a drawn family.

### 53. 141 Import — recognised (Kati.Screens.ImportRecognised) — `lies-to-user`

**'Check the mapping' promises the nine columns it just counted and pushes a screen showing five columns of a different file.**

*Proof.* mapping_collapsed/1 draws '#{job.matched} matched · #{job.skipped} skipped' from Kati.Import.Sample.recognised/0 — 7 of 9 on goodreads_library_export.csv — with on_tap :check_mapping (import_recognised.ex:406-425). handle_tap(:check_mapping, …) pushes Kati.Screens.Import (import_recognised.ex:582-584), whose load/1 assigns Kati.Import.Sample.job/0 — trakt-backup.csv, five columns (import.ex:~86, import/sample.ex:44-56). The two maps share no fields.

*Fix.* Pass the job through as a screen param so 37 renders the same job 141 summarised, rather than each screen loading its own Sample function.

*Fixed.* The mapping screen is opened with the job it counted rather than a second file's five columns; `Kati.Screens.ImportRecognised` shapes the recognition line from the file that was chosen (board 329).

### 54. 145 Shelf filter sheet — `lies-to-user`

**The sheet opens already filtered and announces a library of 418 titles on a phone that may hold two.**

*Proof.* lib/kati/screens/shelf_filters.ex:82-90 — `mount/3` assigns `decade: :decade_2020s`, `rating: :rating_4`, `genres: MapSet.new([:genre_anime])` and `showing: 41`; `count_card/2` then renders `"showing #{showing} of #{Sample.total()}"` = `showing 41 of 418`. The moduledoc defends 41 as "the drawing's own illustrative number", which is correct about the board and wrong about a running app.

*Fix.* Open unfiltered (the state `reset/1` already produces) and compute both numbers off the real shelf.

*Fixed.* `opening/0` reads the shelf twice — as it stands and with nothing selected — and shapes the sheet from both, so `showing N of M` counts this device. An empty shelf still gets `drawn_opening/0`, and `Kati.ScreenEmptyDatabaseTest` compares the two, which is what makes *an empty device draws board 145* a claim a run settles.

### 55. 148 Drop, DNF & abandon — `lies-to-user`

**The sheet documents five statuses including :gone_cold, which the store cannot hold.**

*Proof.* lib/kati/screens/drop_states.ex:9 states `Kati.Media.TrackedTitle.status` is ':active | :paused | :gone_cold | :dropped | :finished'. lib/kati/media/tracked_title.ex:109 constrains it to `[:not_started, :watching, :paused, :finished, :dropped]`. drop_sheet.ex:31-42 already records the discrepancy and works around it by reading :paused as gone cold.

*Fix.* Either migrate TrackedTitle.status to the five names 148 draws, or redraw 148 in the vocabulary the resource actually holds.

*Fixed.* `drop_states.ex`'s moduledoc says so itself: it *used to claim* the column held `:gone_cold` and it never did. Gone cold is derived by `Kati.Media.Staleness` rather than stored — see #56.

### 56. 149 Dropping — the sheet and after — `lies-to-user`

**Dropping a series opens on the 'The Quiet Ones' fixture and then announces a drop that wrote nothing, because no code in the app ever sets status: :paused.**

*Proof.* lib/kati/screens/drop_sheet.ex:270 filters `archived == false and status == :paused`, then `pick/2` searches that filtered list for the pushed id. grep for `status: :paused` across lib/ returns no writer — add_title.ex:491 and :503 create every title as `:watching`, and no screen updates a title's status except drop_sheet.ex itself and log_progress.ex (books, :reading/:finished). So gone_cold_title/1 answers nil, sheet/1 falls back to Sample.sheet/0, commit_drop/1 (drop_sheet.ex:334) calls update_tracked(nil, ...) which is `defp update_tracked(nil, _attrs), do: :ok` (drop_sheet.ex:362), and handle_info({:tap, :drop}) still assigns dropped?: true, drawing 'Dropped The Quiet Ones at S1 E3'.

*Fix.* Either write :paused somewhere (a gone-cold detector) or widen gone_cold_title/1 to accept the pushed id regardless of status; and refuse to draw the undo pill when sheet.tracked is nil.

*Fixed.* `cold_or_paused?/1` asks `Kati.Media.Staleness.gone_cold?/1` rather than filtering on a status nothing writes, and the sheet's own moduledoc records the correction. `:paused` is still read alongside it, because a reader who pauses a show has said something and Kati should not argue.

### 57. 149 Dropping — the sheet and after — `lies-to-user`

**The only write on screen 149 discards its result and rescues to :ok, so a refused or raised update is indistinguishable from a successful drop.**

*Proof.* lib/kati/screens/drop_sheet.ex:364-369: `defp update_tracked(tracked, attrs) do Ash.update(tracked, attrs); :ok rescue _ -> :ok end`. The return value of Ash.update is never inspected. handle_info({:tap, :drop}) (drop_sheet.ex:787) then unconditionally sets dropped?: true. The screen imports neither Kati.Write nor a save_notice, unlike rating.ex:1440 and series.ex:1275.

*Fix.* Return {:ok, _} | {:error, reason} from update_tracked/2, thread it through Kati.Write.note/2, and draw a save_notice on failure instead of flipping dropped?.

*Fixed.* `update_tracked/2` inspects the result — `{:ok, _}` is `:ok`, `{:error, reason}` is returned, and the rescue returns the error rather than swallowing it — so a refused drop is distinguishable from one that landed.

### 58. 15 Activity — `lies-to-user`

**A user with real watches that are all older than the current month is shown '1,204 entries' and seven invented rows in place of their own history.**

*Proof.* lib/kati/screens/activity.ex:145-149: `def log do case entries() do %{today: [], earlier: []} -> drawn(); log -> log end end`. drawn/0 (activity.ex:158-166) returns Kati.Activity.Sample wholesale, including `entries_line: Sample.entries_line()` = "1,204 entries" (activity/sample.ex:21) and rows such as 'Imported 412 titles from a CSV backup' (activity/sample.ex:56). entries/1 buckets only today and the current month (activity.ex:210-222), so any older real watch empties both buckets. test/kati/screen_activity_test.exs:192 asserts this by name.

*Fix.* Gate the fallback on `watches == []` rather than on both dated buckets being empty, and draw a real empty state for a month with no entries.

*Fixed.* The gate is `%{count: 0}` — nothing recorded — rather than `%{today: [], earlier: []}`, which was the state of every reader whose watches are all older than the first of the month. The comment at activity.ex:148 names this finding.

### 59. 154 Add a title by hand (Kati.Screens.AddByHand) — `lies-to-user`

**Year and Total episodes are typed, held, and silently discarded — and the note under the episode field implies the opposite.**

*Proof.* lib/kati/screens/add_by_hand.ex:477-486 track/2 writes only source, source_id, kind, status. The cache row goes through Kati.Screens.AddTitle.create_cache/2 (lib/kati/screens/add_title.ex:545-562), which writes only source, source_id, kind, title, fetched_at. Kati.Media.CachedTitle has episode_count (lib/kati/media/cached_title.ex:95) — never set — and no year column at all (only next_release_at, :108). The note at add_by_hand.ex:319 reads 'Without it a series still tracks, but its progress bar has no denominator', which is true with it too.

*Fix.* Pass episodes (parsed to a positive integer) into create_cache as :episode_count. Year needs a column — add first_release_year (or first_release_at + date_confidence) to CachedTitle — or the field must come off the form.

*Fixed.* `typed_facts/1` carries both fields into the cache row, parsed rather than trusted: anything that is not a positive integer is absent, and a film's episode field is ignored. The note under the field promised the denominator and it is now the denominator.

### 60. 156 افزودن دستی (Kati.Screens.AddByHandFa) — `lies-to-user`

**The Persian form opens pre-filled with a fixture title, so tapping the commit button without editing adds a film called گودال بلند.**

*Proof.* lib/kati/screens/add_by_hand_fa.ex:58-65 mount/3 assigns `title: "گودال بلند", kind: :tv, year: "۱۴۰۳"`. handle_info({:tap, :add}, …) at :266 pipes straight into Kati.Screens.AddByHand.save/1, which only refuses on a blank title (add_by_hand.ex:460-463). The English form at add_by_hand.ex:63 correctly opens with `title: ""`.

*Fix.* Open empty, as 154 does; the board's typed title is a drawing state, not a default.

*Fixed.* `Kati.Screens.AddByHandFa` mounts on `title: ""` — board 155's resting state one language over — so the commit button has nothing to add until something is typed, and `save/1`'s blank-title refusal is reachable rather than unreachable.

### 61. 19 Search — `lies-to-user`

**Book results are drawn under the heading SCREEN and counted by the Screen chip, and their chevrons open nothing.**

*Proof.* lib/kati/search/query.ex:104-110 `titles_for/1` is `(cached_for(query, tracked_ids()) ++ books_for(query)) |> Enum.sort_by(...)`, so book rows land in `results.titles`. lib/kati/screens/search.ex `visible_groups/2` labels that key `{"Screen", :titles}` and `Kati.Search.Query.chip_counts/1` counts `length(titles)` as the Screen chip. `book_row/1` (query.ex) sets `kind: :book`, and `Kati.Screens.Search.hit_tag/1` answers `nil` for anything that is not `:film` or `:series`, so `title_row/1` gets `tap = nil`.

*Fix.* Give `run/1` a fourth group keyed `:books`, add "Books" to `Kati.Search.narrowable_scopes/0` and to `chip_counts/1`, and route the hit to `Kati.Screens.BookDetail` once that screen reads its params.

*Fixed.* Books are their own group — `books: books_for(query)` (query.ex:63) with its own heading and its own chip — rather than rows landing in `results.titles` under SCREEN.

### 62. 19 Search — `lies-to-user`

**Results are silently capped at three per group and the chip counts agree with the cap rather than with what matched, and the See all row that would reach the rest does not exist.**

*Proof.* lib/kati/search/query.ex `titles_for/1` and `calendar_for/1` both end `|> Enum.take(rows_per_group())` (`Kati.Search.rows_per_group/0` = 3) BEFORE `Kati.Search.Query.chip_counts/1` is called on the result map, so `{"Screen", length(titles)}` counts at most 3. `Kati.Search.rows_per_group/0`'s own @doc reads "How many rows a group shows before its `See all` row", and lib/kati/screens/search_spec.ex:284 prints "Then a “See all 12 →” row". `grep -rn "See all\|see_all" lib/kati/screens/search*.ex lib/kati/search*.ex lib/kati/search/*.ex` finds only those two strings — screen 19 has no such row. Ten matching films therefore render three, the chip says 3, and the other seven are unreachable from the search screen.

*Fix.* Count before taking (carry a `total` alongside each group), and add the `See all N →` row the spec promises, or draw all matches.

*Fixed.* No group ends `Enum.take/2` any more, and the comment at query.ex:110-117 records why the cap went rather than being paired with a *See all*: the groups scroll, and a search that found ten answers with ten.

### 63. 19 Search — `lies-to-user`

**The idle search page prints a paragraph asserting a 180 ms debounce and seven counted queries, on a screen that runs on every keystroke and draws four chips.**

*Proof.* lib/kati/screens/search.ex `waiting/1` renders `Kati.UI.SettingsList.note("search", Kati.Search.counts_note())`; lib/kati/search.ex `counts_note/0` reads "Keystrokes debounce at 180 ms, so one pause costs seven counted queries, not seven per letter." `handle_info({:change, :query, typed}, socket)` in search.ex re-runs `Kati.Search.Query.run/1` immediately with no timer, and its own @doc says so ("No debounce, and `Kati.Search.debounce_ms/0` is not being ignored"). `chip_counts/1` returns four labels, not seven.

*Fix.* Reword the note for screen 19 (its own scopes and its own no-debounce behaviour), or keep it only on 86/87/88 where seven scopes are actually drawn.

*Fixed.* `counts_note/0` is written beside the three numbers it quotes — `debounce_ms/0`, `minimum/1` and this module's own rule about zero — so the sentence and the behaviour cannot drift, and it counts eight chips because there are eight.

### 64. 19 Search — `lies-to-user`

**The note card's eyebrow drops the date and the title the board draws, so a note hit is unattributed.**

*Proof.* Board 19 draws `NOTE · 6 AUG · THE LONG HOLLOW` — transcribed in lib/kati/screens/search.ex `drawn_results/0` as `eyebrow: "NOTE · 6 AUG · THE LONG HOLLOW"`. lib/kati/search/query.ex `note_card/2` builds `%{eyebrow: "NOTE", ...}`. So a device draws a bare NOTE with no date and no source.

*Fix.* `Kati.Books.Note` has the book association and a timestamp; compose the same three-part eyebrow.

*Fixed.* `note_eyebrow/1` builds the three-part eyebrow board 19 draws — `NOTE · 6 AUG · THE LONG HOLLOW` — from the note's own date and the title it is about. See the doc at query.ex:463.

### 65. 19 Search — `lies-to-user`

**A cache-only hit — a title looked up on the add sheet but never shelved — renders as a full result card with a chevron that does nothing.**

*Proof.* lib/kati/search/query.ex `cached_for/1` reads the whole of `Kati.Media.CachedTitle`, and `title_row/2` sets `id: Map.get(tracked, {row.source, row.source_id})` — nil when the title is not on the shelf. lib/kati/screens/search.ex `open_hit/3`: `case row && Map.get(row, :id) do nil -> Mob.Socket.push_screen(socket, module)` — pushes Film/Series with no params, which draws the fixture branch rather than this title. Nothing in `title_row/1` marks the card as unshelved.

*Fix.* Either mark cache-only hits (an 'Add' affordance rather than a chevron) or exclude them from the group.

*Fixed.* `Kati.Search.Query`'s row builders carry the tracked id where there is one and the row draws no chevron where there is not — a cache-only hit is a thing Kati knows about and not a thing you keep, and a chevron that opened nothing was the claim.

### 66. 23 Subscriptions — `lies-to-user`

**Screen 23 is a fixture that quotes four services and £46.47 a month regardless of what is on the account, and its back pill reads "‹ Stats" while the only route to it is My services.**

*Proof.* lib/kati/screens/subscriptions.ex:110 `use Kati.Screens.Pushed, back: "Stats"`; :118 `load/1` assigns only `suggestion: true, reminded: false` and every row comes from `Kati.Subscriptions.Sample`. Routes: my_services.ex:562 `handle_tap(:open_subscriptions, …)` and my_services_empty.ex:393/:396. test/kati/screen_sample_only_test.exs:81 lists it as permanently sample-only. Its `more_horiz` disc is in @inert_taps' Backlog section (`{Kati.Screens.Subscriptions, :open_menu}`).

*Fix.* Read `Kati.Services.Service` for the rows and `Service.total/1` for the hero figure once a price editor exists — 92 already claims ownership of the prices on screen. Set `back: "My services"`, or make the pill label follow the pusher.

*Fixed.* The back pill reads `My services`, which is the only route in, and `ledger/0` reads `Kati.Subscriptions.ledger/0` — the drawing is what a device with nothing stored falls back to, and `drawn_ledger/0` is what board 23 is compared against.

### 67. 25 Release watcher — `lies-to-user`

**Ten switches, a master switch and a four-way cadence, all of which edit one socket assign and are forgotten on back. The cadence in particular is a lie against working code: `Kati.Background.Periodic` runs on a compile-time constant six hours and never reads this screen.**

*Proof.* lib/kati/screens/release_watcher.ex:50-58 `load/1` assigns `Kati.Settings.WatcherSample` values; :256-283 `handle_tap/2` only ever calls `Mob.Socket.assign(socket, :watcher, …)`. `grep -rn 'WatcherSample' lib/` finds no reader outside release_watcher.ex. lib/kati/background/periodic.ex:60 `@interval_minutes 6 * 60`, :69 `def cadence, do: {@interval_minutes, @flex_minutes}` — hardcoded, and `Kati.App` enqueues it with KEEP at boot (app.ex:196).

*Fix.* A preferences resource, or at minimum `Mob.State` keys the way `Kati.Services` stores region and rules. `Hourly`/`Daily`/`Manual` must either drive `Periodic.ensure(interval: …)` or be removed — a segment that renames nothing is worse than three segments.

*Fixed 7 September.* The cadence and *New episodes* are stored and read; the other thirteen are marked `not yet`.

### 68. 33 Rating — `lies-to-user`

**Six of the seven doors into screen 33 push it bare, so it opens on the newest log anywhere in the library — or the 'Blue Hour' fixture — rather than the book, album or film the user was looking at.**

*Proof.* grep -rn "Kati.Screens.Rating)" lib/ : book_detail.ex:1090, book_detail.ex:1119, book_detail_dark.ex:595, book_detail_dark.ex:611, book_detail_fa.ex:1588, book_detail_fa.ex:1646, album_detail_fa.ex:1006, log_progress.ex:653 — all `push_screen(socket, Kati.Screens.Rating)` with no params. Only film.ex:923 passes Rating.params_for/1. rating.ex:379 `newest_log(nil)` then runs unnarrowed across every Watch in the store.

*Fix.* Pass Rating.params_for/1 (or a book/album equivalent) from every door; refuse to draw a subject the caller did not name.

*Fixed for the two domains screen 33 rates; the rest is recorded where a run can see it.* `Kati.Screens.Film` and `Kati.Screens.Series` name the title they drew, and screen 74's Rate row moved to `Kati.Screens.RateAlbum`, which names the album. The remaining bare pushes are the book doors, and `Kati.ScreenParamsSweepTest`'s `@bare_pushes` carries each with the reason: 33 reads `:tracked_title_id` and a book is not a tracked title, so making it rate one is a screen build — a second reader, a second writer, and a decision about which rating column the stars commit to.

### 69. 34 Season — `lies-to-user`

**On a real season, 'Include specials · Shown inline, at air date' and 'Merge multi-part · Treat E7 & E8 as one 2h finale' stay switched on above a list that does neither — assemble/3 replaces only title, eyebrow, episodes and note, and for_season/3 reads one season number and never season 0.**

*Proof.* lib/kati/screens/season.ex:398-411 — the struct update keeps :orders, :current_order, :options and :subtitle from drawn_season(). lib/kati/screens/season.ex:388-393 calls CachedEpisode.for_season(source, source_id, number) for the bookmarked number only.

*Fix.* Either wire the two switches (they are per-season display state, so they can live on the socket) or drop them from the real-season branch rather than carrying the fixture's positions and sub-lines over the user's list.

*Fixed for the half that had an answer.* `Include specials` is honoured: `specials/2` reads season 0 — where every provider files them — and merges it in by air date, which is what the sub-line promises. `Merge multi-part` is not, and cannot be until a column marks an episode as merged and pairs it with its other half; `Kati.Media.CachedEpisode` is a cache and is the one place a reader's choice must never live. The screen's own moduledoc says which is which.

### 70. 80 Data sources (Kati.Screens.DataSources) — `lies-to-user`

**Tapping 'Use my own key' permanently breaks TMDB search from one tap on a control that reads as a preference, with no way to supply the key it just switched to.**

*Proof.* lib/kati/screens/data_sources.ex:563 handle_tap(:key_own, …) calls Sources.put_tmdb_key(:own) (lib/kati/sources.ex:132, writes :kati_tmdb_key to Mob.State). Kati.Media.Tmdb.key/0 (tmdb.ex:283-291) then routes to own_key/0, which reads the always-empty secure store, and answers {:error, :no_api_key}. Screen 06 stops returning results and starts drawing the 'No TMDB key yet' notice — pointing back at this page, which has no field (previous finding).

*Fix.* Gate the chip: either show the key field on selecting :own and only commit the choice once a token is stored, or disable :own until Kati.SecureStore.available?/0 and a writer exist.

*Fixed.* Board 318 built the card the tap needs: choosing *Use my own key* draws a field to paste one into, and the key is stored outside the repo. The choice is no longer a switch to a key the reader has no way to supply.

### 71. 80 Data sources (Kati.Screens.DataSources) — `lies-to-user`

**The pairing card shows a constant code, a countdown that never counts down, and sends Hardcover and TheTVDB users to ListenBrainz's URL.**

*Proof.* lib/kati/screens/data_sources.ex:397-400 pairing_code/1 returns hardcoded K4Q9B2 / K7M3D8 / K2V6X1; :378 draws the literal 'Expires in 9:48'; :375 draws the literal 'listenbrainz.org/link' inside pairing/2, which is rendered for whichever of the three sources is expanded. Nothing in lib/ implements a client for any of them, and Sources.connected?/1 (lib/kati/sources.ex:144) can never be true because nothing writes a tier-2 token.

*Fix.* Collapse the tier-2 section to a stated 'not built yet' state, or at minimum derive the URL per source and drop the fake code and countdown.

*Fixed.* `pairing_code/1` is gone — the doc at data_sources.ex:841 records what replaced it and why: Kati talks to nothing that issues a code, so a constant one, a countdown that never counts and one provider's URL under three names were three claims about a handshake that does not happen.

### 72. 86 Search idle — `lies-to-user`

**The two Try suggestions are fixed strings that will match nothing on a real device, presented as "drawn from what you actually have".**

*Proof.* lib/kati/search.ex `suggestions/0` returns the literals ["what leaves this week", "notes about the estuary"], and its own @doc says "Fixed strings for now, and the boards' own. Deriving them wants a notion of what a person has been near lately that nothing in Kati stores". lib/kati/screens/search_idle.ex `suggestions/0` renders them as tappable rows under the eyebrow "Try", and `open/2` runs them for real against `Kati.Search.Query.run/1`.

*Fix.* Derive them from the shelf (a title leaving a service, a title with a note) or withhold the section until they can be, the way the counts are withheld.

*Fixed.* `Kati.Screens.SearchIdle.suggestions/0` draws `Kati.Search.Suggestions.derived()` — the newest title on this reader's shelf and the book their newest note is about — and falls back to the board's two strings only on a device with neither. `Kati.ScreenDesignLiteralTest`'s allow-list carries both with a pattern rather than the frozen words.

### 73. 86 Search idle -> 19 — `lies-to-user`

**Four of the eight scope chips on the idle page are silently discarded when the search runs, and the results page lights All without saying the choice was dropped.**

*Proof.* lib/kati/screens/search_idle.ex `chips/1` renders `Kati.Search.chip_labels/0` — All plus all seven @scopes. `look/1` pushes `%{query: ..., scope: socket.assigns.scope}`. lib/kati/screens/search.ex `mount/3` does `filter: Kati.Search.narrowable(Map.get(params, :scope, "All"))`, and lib/kati/search.ex `@narrowable ["All", "Screen", "Calendar", "Notes"]` with `def narrowable(_unnarrowable), do: "All"`. So Books, Music, Meals and Money all become All. The docstring calls this "the honest degradation" and it is — but no text on either screen tells the user.

*Fix.* Either build the missing groups, or grey the four unbuildable chips on 86 the way an unavailable control is drawn, so the choice is never offered and then discarded.

*Fixed.* A scope with no group behind it is drawn DISABLED rather than silently collapsed into `All` on the way to screen 19 — search_idle.ex:142-144 states exactly the sequence this finding found: a reader picked a scope, ran the search, and the choice was gone.

### 74. 88 Scope & ranking — `lies-to-user`

**The contract board renders scopes and fields the query executor does not implement: four of seven scopes do not exist, five of six Screen fields are not searched, and Calendar's location is not read.**

*Proof.* lib/kati/search.ex @scopes lists seven scopes and their fields; lib/kati/screens/search_spec.ex renders them straight out of it. lib/kati/search/query.ex `run/1` builds exactly three groups (`titles`, `calendar`, `note`) — Music, Meals and Money are searched by nothing, Books is folded into `titles`. `cached_for/1` matches title + overview only (no original title, alt titles, cast, tags, review). `calendar_for/1` matches `summary` + `description` only (no location).

*Fix.* Trim @scopes to the built contract, or build the rest. A specification screen that overstates is worse than none, because it is the page a user opens to find out why a search missed.

*Fixed.* `@scopes` is the contract and `built?/1` is what says which half of it runs, so board 88 draws every scope and marks the ones a query does not reach rather than promising all seven. The field-level half is written down beside it (#114).

### 75. 92 My services — `lies-to-user`

**Home and screen 92 give opposite answers one tap apart. On a phone with no services Home's row reads "No subscriptions yet"; tapping it opens 92 listing Lumen+ £8.99, Orbit £13.99, Kino £11.49, "Subscribed · 3", and "£46.47 A MONTH".**

*Proof.* lib/kati/screens/home.ex:1036 `def services_line(%{count: 0}), do: "No subscriptions yet"` over `Kati.Services.subscribed_count/0`, which counts the real table. lib/kati/screens/my_services.ex:101 `subscribed/0` answers `[]` with `Sample.subscribed()` (lib/kati/services/sample.ex:14-19). home.ex's own moduledoc (:993) names the bug and then says "the moduledoc says why 92's own fallback is left alone" — i.e. it was fixed on one side only.

*Fix.* Gate 92's fallback the way 96's `set_up?/0` was meant to: fixtures only when the store is empty AND the device has never opened 92. Better, draw the 93 empty-state groups inside 92 on an empty store and delete 93 as a separate page.

*Fixed.* Neither group falls back to `Kati.Services.Sample`: `subscribed/0` and `free/0` read what is stored and answer nothing when nothing is. Home and 92 ask one question now, and `Kati.Screens.MyServices`'s own doc names this finding twice.

### 76. 92 My services — `lies-to-user`

**Adding one service through `Something else` produces a page that is half the user's and half the drawing's. `subscribed/0` and `free/0` fall back independently, so the Subscribed group becomes your one service while the Free group still shows Aria Free and Dispatch, and the Money row still reads £46.47 a month beside a live count of "1 service".**

*Proof.* lib/kati/screens/my_services.ex:101 and :110 — two separate `case stored(tier) do [] -> Sample.x() …` fallbacks. :505 `money_group/0` composes `count = length(subscribed())` (live) with `Sample.monthly_total()` (frozen "£46.47", lib/kati/services/sample.ex:51). test/kati/service_write_test.exs:198 asserts the tier-swap behaviour and never looks at the other group.

*Fix.* One gate for the whole page: if `Service |> Ash.Query.for_read(:listed)` returns anything, draw only stored rows in both groups and compute the total from `Service.total/1` — never `Sample.monthly_total/0`.

*Fixed with #75.* The two groups no longer fall back independently, because neither falls back at all, and the Money row reads the same store.

### 77. 92 My services / 93 — `lies-to-user`

**All three availability rules are stored and consumed by nothing. `Hide titles I can't watch` prints "Removes them from Discover, Up next and What fits tonight" — all three of those screens are fixtures that never call `Kati.Services.rules/0`.**

*Proof.* `grep -rn 'Services.rules()\|hide_unavailable' lib/ --include=*.ex` returns only lib/kati/services.ex, my_services.ex:84/94/582, my_services_empty.ex:101, my_services_fa.ex:215/227/818 — the screens that draw the switches. No reader in discover.ex, up_next.ex or what_fits.ex. The sweep's @inert_taps entry says the rules "ARE wired" and means only that the write lands in `Mob.State`.

*Fix.* Until an offers resource exists these three switches should not be drawn as live controls. Either build the availability filter or replace the switches with the honest note 93 already carries.

*Fixed; the last third landed 8 September.* `Kati.Media.Availability` reads TMDB's provider block and `Kati.Screens.UpNext.watchable/1` and `Kati.Media.Recommendations` filter on it. Screen 13 was the page the sentence had been cut for — it read a fixture, so the rule named two pages instead of three — and board 310 counts the filter rather than remembering it: `Kati.Screens.WhatFits.watchable/1` filters both halves of that page and the sentence names all three again.

### 78. 94 Country picker — `lies-to-user`

**The field says "Search 190 countries" over a list of seven, and tapping it does nothing.**

*Proof.* lib/kati/screens/country_picker.ex:85 `text="Search 190 countries"`; lib/kati/services.ex:48-57 `@countries` holds seven pairs. The field's `on_tap={{self(), :search}}` (:80) falls to `handle_info(_message, socket)` (:134); the tap sweep records `{Kati.Screens.CountryPicker, :search}` in @inert_taps.

*Fix.* Ship the real ISO list (or JustWatch's) and make the field filter it, or change the placeholder to the number actually offered. The sheet itself works correctly — it writes and pops.

*Fixed.* The placeholder counts `Kati.Services.countries/0` — `Search 7 countries`, and `Search 190 countries` the day the list is 190 — and the field is a `<TextField>` that filters rather than a picture.

### 79. 98 Your year, shared (Kati.Screens.YearShare) — `lies-to-user`

**Every figure on the share page is a fixture, on a device where screen 07 one tap earlier draws the user's real year.**

*Proof.* lib/kati/screens/year_share.ex:121-186 builds the card from Kati.Stats.ShareSample.hours/0 and top_titles/0 — '312h 40m', '18%', 'The Long Hollow'/'Blue Hour'/'The Cartographer' — and the header subtitle is the literal ShareSample.subtitle/0 'JAN – AUG 2026' (year_share.ex:60), while Kati.Screens.Stats.range/1 derives 07's range from Kati.Time.today(). load/1 (year_share.ex:41-46) reads nothing from the store.

*Fix.* Feed the card from Kati.Screens.Stats.figures/0 — year.time, year.change, year.rising? and a top-titles read off Watch grouped by tracked_title — and take the subtitle from the same range/1 that 07 uses.

*Fixed.* `share/2` reads `Kati.Screens.Stats.figures/0` — the same year screen 07 draws, through the same function rather than a second query — and falls back to the drawing only when there is no year to read. The doc at year_share.ex:60 names this finding and the reason it mattered most here: a share card is the one page whose purpose is to leave the device.

### 80. 98 Your year, shared (Kati.Screens.YearShare) — `lies-to-user`

**'Save image' saves nothing — it pushes the Year cards reference sheet — even though the screen-to-bitmap fence it is waiting on already shipped and is already used elsewhere.**

*Proof.* lib/kati/screens/year_share.ex:370-371: handle_tap(:save_image, socket) -> push_screen(socket, Kati.Screens.YearCards). Kati.Screens.YearCards.handle_tap/2 is a no-op stub (year_cards.ex:342). Kati.Native.Files.save_screen/1 exists (lib/kati/native/files.ex:271-277) and Kati.Screens.WeekImage calls it (lib/kati/screens/week_image.ex:1072). test/kati/screen_tap_sweep_test.exs:807-809 records YearCards as the last screen in the app stubbing its own save, 'one call away'.

*Fix.* Wire :save_image to Kati.Native.Files.save_screen/1 with a year-card filename, following Kati.Screens.WeekImage's handler; keep the push to 100 only as a 'how this is drawn' link.

*Fixed.* `handle_tap(:save_image, …)` calls `Kati.Native.Files.save_screen/1` and reports a failure rather than pushing the reference sheet.

### 81. 04 Series detail — `inert-control`

**The bookmark and star discs beside 'Mark next watched' are drawn at button size, with a card fill and a lift, and carry no handler at all.**

*Proof.* lib/kati/screens/series.ex:952-963 — action_disc/1 passes size, shape, variant, background and shadow to MishkaActionIcon and no on_tap; the comment above it says 'No handler is passed and none is wanted — bookmark and rate are not built'. Same two discs on series_meta.ex:430-443 and one on series_fa.ex:636-666 (:toggle_save, which stores nothing).

*Fix.* Wire the star to screen 33 (Rating already writes) and either wire bookmark to TrackedTitle.progress_season or remove the disc; a third inert disc is not a smaller version of a control.

*Fixed.* `action_disc/3` takes a tap and the call sites pass one: the bookmark disc is `:toggle_follow` (series.ex:1167), `bookmarks` is `:add_to_list` (:1185) and the star is `:rate_title` (:1201). Each has a `nil`-tap twin for the drawn page, where there is no row to act on — a control with nowhere to go draws no tap, which is this repo's rule and what the sweep is written to.

### 82. 05 New releases — `inert-control`

**Every control on screen 05 is dead: `Mark all`, the `Watch` pill on each Out now row, and the `settings` gear on the watcher card. The tap-sweep's own comment claims Mark all "joined this group the round it was wired" — the comment is orphaned; the entry it describes is not in `@inert_taps` because the tag is no longer drawn.**

*Proof.* lib/kati/screens/inbox.ex — `grep -n 'tap' lib/kati/screens/inbox.ex` returns nothing across 816 lines. `mark_all/0` (:502) draws `<Row height={36} corner_radius={18} background=… padding_left={14}…><Text text="Mark all"…/></Row>` with no `on_tap`. `release_row/1` (:694) draws the `Watch` pill the same way. `watcher/1` (:591) ends in a bare `Kati.UI.symbol("settings", …)`. test/kati/screen_tap_sweep_test.exs:328 carries the comment; the next line is `{Kati.Screens.Search, :clear}`, and the file's stale check (:906) would fail on a phantom entry, so `{Kati.Screens.Inbox, :mark_all}` is genuinely absent.

*Fix.* `Mark all` writes one `Kati.Media.Watch` per `out_now` row and re-reads (the moduledoc already describes this behaviour as if it shipped). `Watch` on a row ticks that one episode. The gear pushes `Kati.Screens.ReleaseWatcher`.

*Fixed.* Screen 05's three controls all reach something: `:mark_all` ticks every tickable row and re-reads, `:open_watcher` pushes screen 25, and the `Watch` pill is `watch_tap/1` — a tap for a row carrying an episode reference and none for a drawn one.

### 83. 06 Add a title (Kati.Screens.AddTitle) — `inert-control`

**The cancel (X) glyph at the end of the search field is not tappable, so there is no way to clear the query.**

*Proof.* lib/kati/screens/add_title.ex:423 `{Kati.UI.symbol("cancel", size: 19, color: Palette.rail_idle(), fill: true)}` — Kati.UI.symbol/2 takes no on_tap, and the enclosing Row (:404-412) has none either.

*Fix.* Wrap it in a tappable Box with {self(), :clear_query} and a handler assigning query: "" and results: [].

*Fixed.* `clear_disc/0` wraps the glyph in a 40pt `<Box>` carrying `:clear_query` — a 19pt target is under every guideline there is, and a tap on the bare glyph fell through to the field underneath and APPENDED to the query it was meant to clear.

### 84. 08 Film detail — `inert-control`

**The three action buttons — Log rewatch, Schedule, Share — carry no tap tag at all, so they do not even reach a handler.**

*Proof.* lib/kati/screens/film.ex:880 `def action(icon, label)` builds `<Box weight={1.0}><Box fill_width height={52} corner_radius background shadow align="center">...` with no `on_tap` prop anywhere in the function. The labels come from @actions (film.ex:88). Because no tag is registered, ScreenTapSweepTest cannot see them and they are absent from @inert_taps — the sweep only records controls that reach a handler. test/kati/screen_film_test.exs:232 asserts only that the labels are drawn.

*Fix.* Wire Log rewatch to the same title-level watch writer as the ⋯ menu, Schedule to Kati.Screens.Schedule, and Share to the platform share sheet; or drop the buttons until they have destinations.

*Fixed.* `action/4` takes a tag and `@actions` gives all three one — `:add_to_list`, `:schedule_watch`, `:share_film`. The first pill's label follows the film as well: it read *Log rewatch* on a film whose own card said `SEEN never`.

### 85. 08 Film detail — `inert-control`

**The note card's edit pencil and the whole rating card are painted, not tappable, so a note cannot be edited and a rating cannot be set from screen 08.**

*Proof.* lib/kati/screens/film.ex:724 is a bare `{Kati.UI.symbol("edit", size: 17, color: Palette.gold_icon())}` inside note/1 with no enclosing tap. rating_card/1 (film.ex:628) and stars/1 (film.ex:~672) draw Rows and Texts with no on_tap. Film's only handle_info clauses are :back, :toggle_menu, :close_menu and :log_watch (film.ex:915-930).

*Fix.* Route the pencil and the rating card into screen 33 with the film's tracked_id, the same way :log_watch already does.

*Fixed.* The rating card carries `:rate` and the note's pencil `:edit_note` (film.ex:781, :1000), both gated on the page having a `tracked_id` — the drawn page has none and draws no tap. `handle_info({:tap, tag}, …)` answers all three doors at film.ex:1142.

### 86. 10 Up next — `inert-control`

**Screen 10 draws no tappable control at all. The hero play disc, the four ready-row play discs, the `tune` disc and every cold row's `Drop` pill are decoration — the module contains no `on_tap` and no `handle_tap/2`.**

*Proof.* lib/kati/screens/up_next.ex — `grep -n 'on_tap\|handle_tap' lib/kati/screens/up_next.ex` returns nothing. `play_disc/4` (:610) builds `MishkaActionIcon.action_icon([size:, shape:, variant:, background:], [symbol])` with no `on_tap` key; `drop_pill/1` (:701) builds `MishkaPill.pill(label:, background:, color:, corner_radius:, height:, padding:…)` with no `on_tap`; `tune_disc/0` (:358) likewise. `Kati.ScreenTapSweepTest` cannot see this: `ScreenSweep.tap_tags/1` only collects tags that ARE drawn, so a screen with zero drawn tags passes every check in that file. Board caption (test/design/screens/10.html): "The screen the whole app is for".

*Fix.* Give `cold_data/2` and `ready_data/2` the durable row's `id`; hang `on_tap` on the cold pill → `Mob.Socket.push_screen(Kati.Screens.DropSheet, Kati.Screens.DropSheet.params_for(%{tracked_id: id}))` (that sheet already writes `:dropped` — drop_sheet.ex:237). Hang `on_tap` on each play disc and each row → `Kati.Screens.Film` / `Kati.Screens.Series` with the row's id as a param (both are currently pushed bare from Library and resolve "newest tracked" themselves, so the param has to land at the same time). `tune` opens `Kati.Screens.ShelfFilters`, as Library's four sort discs already do.

*Fixed.* Screen 10 has taps: `:open_filters` on the tune disc, `:open_library`, and a play disc per row. The grep in this finding returned nothing and now returns seven call sites.

### 87. 11 Discover — `inert-control`

**Discover's `tune` disc is drawn as a plain Box with no tap at all, and the `Schedule` buttons that do work forget themselves the moment you go back.**

*Proof.* lib/kati/screens/discover.ex:196-205 — `<Box width={44} height={44} corner_radius={22} background=… shadow=… align="center">{Kati.UI.symbol("tune", size: 21)}</Box>`, no `on_tap`. :105 `scheduled: []` is a socket assign; :612 `handle_tap` "schedule_" toggles it and nothing writes. Same shape as `Kati.Screens.UpNext.tune_disc/0` (up_next.ex:358) and `Kati.Screens.WhatFits.more_disc/0` (what_fits.ex:145) — three discs the boards draw and no code taps.

*Fix.* Wire all three discs to `Kati.Screens.ShelfFilters` (Library's four sort discs already push it) or stop drawing them. `Schedule` needs a `Kati.Calendars.Event` write to survive a pop.

*Fixed.* The tune disc opens the panel (`:tune?`, discover.ex:1211). The Schedule button's second half was fixed the other way and deliberately: `schedule_tap/1` answers `nil` for every row, so the button draws no tap at all rather than a toggle that forgets itself the moment you go back — the same rule `Kati.Screens.PlanShare.tile_tap/1` keeps.

### 88. 13 What fits? — `inert-control`

**Every control on screen 13 is decoration: the five window buttons (20m/30m/45m/1h/2h+), the four mood chips, the three play discs, the `Tomorrow` defer pill and the overflow disc. The board's own caption is "Set the window you actually have and the library filters itself".**

*Proof.* lib/kati/screens/what_fits.ex — `grep -n 'on_tap\|handle_tap' lib/kati/screens/what_fits.ex` returns nothing across 424 lines. `length_button/1` (:231), `mood_chip/1` (:263), `defer_pill/1` (:396) and `more_disc/0` (:145) all build their nodes without a tap. `load/1` (:87) assigns `Sample.tonight()` and the screen never reads `Kati.Media`.

*Fix.* The window buttons are the cheap half and the moduledoc says so: `CachedEpisode.runtime_minutes` plus `for_title/2` gives a real "3 episodes fit" for a chosen window. Wire the five buttons to a `:window` assign and derive the list. The mood chips have no data behind them — drop them or mark them unavailable.

*Fixed 7 September; finished 8 September.* The five buttons move a `:window` assign and the list is derived from it. Board 310 closed the last of it: the page is filtered by *Hide titles I can't watch* too, which is what screen 92's sentence had been claiming and could not have meant while this page read a fixture.

### 89. 141 Import — recognised (Kati.Screens.ImportRecognised) — `inert-control`

**The 'Import 412' pill — the commit action of the whole import flow — carries no on_tap on both screens that draw it, so the tap sweep cannot report it either.**

*Proof.* import_recognised.ex:353-370 (header/1) and import.ex:97-119 (header/1) both draw a 38pt ink pill with text job.action and no on_tap prop. Neither module has a handler for it, and no tag exists for Kati.ScreenSweep to collect (it only collects %{on_tap: {pid, tag}} when is_atom(tag)).

*Fix.* Same as screen 37's: no job resource means nothing to commit. Draw it disabled or route it to Kati.Screens.RetiredTile until the reader lands.

*Fixed.* Both screens pass the commit tap: `if(live?(job), do: {self(), :commit})` at import.ex:303 and import_recognised.ex:527, and the pill draws no tap on a job that cannot be committed.

### 90. 15 Activity — `inert-control`

**No row in the activity log is tappable, so the user cannot open a title from their own history.**

*Proof.* grep -n "on_tap" lib/kati/screens/activity.ex returns only lines 306 and 321 (the header disc component) and the chip's on_toggle at 385. entry_row/5 and its children (activity.ex:440-500) draw stamp, thumbnail, lead and rest with no tap prop.

*Fix.* Give each row the tracked title's id and push Kati.Screens.Film or Kati.Screens.Series from it.

*Fixed.* Every entry row carries a tap (activity.ex:626) and opens the title the entry is about.

### 91. 15 Activity — `inert-control`

**The filter (tune) disc in the Activity header reaches a handler and does nothing.**

*Proof.* lib/kati/screens/activity.ex:288 draws `Kati.Screens.Activity.disc("tune", :open_filters)`; handle_tap/2 (activity.ex:638-643) matches only `"filter_" <> label` and falls through to `_ -> {:noreply, socket}`. Listed at test/kati/screen_tap_sweep_test.exs:772 under the Backlog group; the reason on file (activity.ex:624-626) is 'No board in the 165 draws an activity filter sheet, so it has nowhere to go that would not be invented here.'

*Fix.* Draw the sheet, or remove the disc.

*Fixed 8 September.* `handle_tap(:open_filters, …)` pushes `Kati.Screens.ShelfFilters` — the same sheet the chips narrow with — and the comment beside it names this finding: *alive enough to swallow the tap, dead enough to answer it with silence.* The wiring landed earlier and the entry stayed on `@inert_taps` until today, which is a stale exemption over a live control; it is gone.

### 92. 152 Anime — `inert-control`

**Two of the board's five taps are the already-selected members of live families and change nothing.**

*Proof.* test/kati/screen_tap_sweep_test.exs:620-621 `{Kati.Screens.AnimeFilter, :pick_screen}` and `{Kati.Screens.AnimeFilter, :watches_yes}`, with the stated reason: "`load/1` opens screen 152 on `onboarding_pick: \"Screen\"` and `watches_anime?: true`, so `:pick_screen` and `:watches_yes` write the values already there while `:pick_books` and `:watches_no` move the screen."

*Fix.* None — this is the honest resting-member category. Recorded for completeness.

*Not a defect, and the sweep says so where it counts.* `:pick_screen` and `:watches_yes` are the ALREADY-SELECTED members of two live families: `load/1` opens screen 152 on `onboarding_pick: "Screen"` and `watches_anime?: true`, and their siblings `:pick_books` and `:watches_no` move the screen. That is the first category `@inert_taps` documents and it is confirmed the way that paragraph prescribes. Board 152's own argument became a feature separately — see #8 and #104.

### 93. 18 Quick add (Kati.Screens.QuickAdd) — `inert-control`

**Five of the six 'Or file it as' chips — including Title, the only one that would add a film — swallow taps and do nothing.**

*Proof.* lib/kati/screens/quick_add.ex:128-129 kind_tap/1 returns {self(), :file_as_expense} for "Expense" and nil for every other label; the nil reaches the chip node at :486 and :511 as no on_tap. Event, Reminder, Title, Habit and Note are drawn identically to Expense and are not tappable.

*Fix.* Until each has a destination, draw the five differently (muted, or with a 'coming' marker) so the user is not invited to tap them; or wire Title straight to Kati.Screens.AddByHand with the sentence pre-filled.

*Fixed.* `kind_tap/1` gives every chip a tag (quick_add.ex:301), and `filing/1` says which write each one is: four file an event by kind, **Title** goes to screen 06 and **Expense** to screen 124.

### 94. 19 Search — `inert-control`

**The clear disc is booked inert by the tap sweep, with the sweep's own stated reason.**

*Proof.* test/kati/screen_tap_sweep_test.exs:335 `{Kati.Screens.Search, :clear}`, with the comment on the following line: "Screen 06's clear disc, for screen 19's reason one line up: the field it empties is already empty on a bare mount." On a device with something typed it does work — `handle_info({:tap, :clear})` re-assigns `:query` and `:results`.

*Fix.* None needed; listed so the sweep entry is not mistaken for a defect. Confirm on device that the bound `<TextField value={@query}>` actually clears visually on re-render.

*Fixed.* The clear disc works on a device with something typed; what the sweep saw was a bare mount, where the field it empties is already empty. Board 312 rewrote what clearing LANDS on — screen 86's recent shelf, carrying the just-cleared query — and `Kati.SearchClearTest` presses it over a real query.

### 95. 33 Rating — `inert-control`

**The three context rows — Watched on, Where, With — each draw a chevron and carry no tap tag, promising three screens that do not open.**

*Proof.* lib/kati/screens/rating.ex:1300-1320: context_card/1 builds `SettingsList.row(SettingsList.icon_tile(row.icon), SettingsList.body(row.title, row.sub), SettingsList.chevron(), padding: 13, rule: i < last)` — no on_tap is passed to row/4. Because no tag is registered these are invisible to ScreenTapSweepTest and absent from @inert_taps.

*Fix.* Either wire a date picker, a service picker and a names field, or drop the chevrons so the rows read as values rather than as destinations.

*Fixed.* The three rows carry `on_tap: if(live?, do: {self(), row.tag})` (rating.ex:1570) and disclose one at a time — pressing the open row closes it, because a disclosure that only opens is a row you have to leave the screen to be rid of.

### 96. 33 Rating — `inert-control`

**'+ tag', the spoiler toggle and the 5★/10pt scale toggle are all drawn as controls and none of them changes anything.**

*Proof.* `{Kati.Screens.Rating, :add_tag}` is in @inert_taps under the Backlog group at test/kati/screen_tap_sweep_test.exs:797, whose header reads 'Every tag in the family is inert, so the whole control does nothing'. spoiler_toggle/1 (rating.ex:1283) draws a symbol and a Text with no on_tap. scale/1 (rating.ex:~920) draws two Rows with no on_tap; rating.ex:445 hardcodes `rating_note: Sample.watch().rating_note` on a real watch.

*Fix.* add_tag needs a tag field; contains_spoilers is a real column and needs a switch; the scale toggle needs a preference resource (screen 35) before it can be anything but paint.

*Fixed.* All three act: `:toggle_spoilers` flips the line, `:add_tag` opens a tag field that commits on `:commit_tag` (with `:use_tag_` and `:drop_tag_` beside it), and the scale toggle is `scale_toggle(writable?(w))`. Each is live only when the sheet has a row behind it, because a control over a drawn page would be editing nothing.

### 97. 34 Season — `inert-control`

**The Aired / Absolute / DVD strip is a picture: neither clause of order/2 emits on_tap and handle_tap/2 matches only episode rows, so the screen's central control does nothing. CachedEpisode.in_order/2 already implements :absolute.**

*Proof.* lib/kati/screens/season.ex:580-617 — both `def order(label, true|false)` clauses build Boxes with no on_tap prop. handle_tap/2 at season.ex:192-197 matches `"episode_" <> index` and falls through on everything else, so the sweep's 'answers every tag' check never sees these tiles.

*Fix.* Give the two supported tiles a tag, hold :current_order on the socket, and rebuild the rows through CachedEpisode.in_order/2. Leave DVD unselectable, per CachedEpisode.orders/0.

*Fixed.* Both `order/2` clauses carry `on_tap` (season.ex:984, :1009) and the strip changes the order the episodes are listed in, through `CachedEpisode.in_order/2` which this finding noted already implemented `:absolute`.

### 98. 34 Season / 35 Series settings — `inert-control`

**The ⋯ disc at the top of both screens is not a control — SettingsList.disc/1 builds a themed icon with no on_tap, so it reaches no handler and Kati.ScreenTapSweepTest's 'answers every tag' check cannot see it.**

*Proof.* lib/kati/ui/settings_list.ex:135-149 — disc/1 calls MishkaThemeIcon.theme_icon with variant, color, size, radius and shadow, and no on_tap. Called from season.ex:541 and series_settings.ex:124 via SettingsList.chrome("more_horiz", 44).

*Fix.* Either give chrome/2 an optional tag and wire a menu, or pass nil so the row reserves height without drawing a button, as numbering_scheme.ex:100 already does.

*Fixed.* `Kati.UI.SettingsList.disc/2` takes an `on_tap`, so the ⋯ disc is a control on the screens that give it one and draws no tap on the screens that have nothing behind it.

### 99. 35 Series settings — `inert-control`

**Every control on the screen is inert, including four switches whose columns exist on TrackedTitle with matching defaults and no other reader or writer in the app, and the three-way Status tiles that map exactly onto TrackedTitle.status.**

*Proof.* lib/kati/screens/series_settings.ex:109 loads Kati.SeriesSettings.Sample.show/0 only. status/1 (series_settings.ex:170-232) draws two shadow states and no on_tap. control/1 (series_settings.ex:286-287) returns SettingsList.chevron() or SettingsList.switch(on?), neither of which takes a tap. The moduledoc names auto_add_new_seasons, notify_new_episodes, add_air_dates_to_calendar and hide_unwatched_titles as having no other reader; hide_unwatched_titles is read only by rate_episode.ex:357, which is itself unreachable in practice.

*Fix.* Split the screen: bind Status and the four season-pass switches to the tracked row this show's ⋯ menu named, and leave the four Region rows visibly disabled or off the page until an offers/settings resource exists.

*Fixed.* `Kati.Screens.SeriesSettings` writes: `Ash.Changeset.for_update(:update, changes) |> Ash.update()` at :311, over the four `Kati.Media.TrackedTitle` columns the board draws, with `handle_tap/2` splitting the tags.

### 100. 36 Auto-detect (Kati.Screens.AutoDetect) — `inert-control`

**Ten of the twelve controls on Auto-detect — including the master on/off switch for the whole feature — carry no on_tap and are invisible to the tap sweep.**

*Proof.* Kati.Screens.AutoDetect.tap/1 (auto_detect.ex:~300) returns {self(), :open_retired} for "Browser extension" and nil for every other title, so the Apple TV / Chromecast / This phone switches, the 'Tick at' chevron row and the two rule switches get no tap. banner/1 (auto_detect.ex:~100) draws SettingsList.switch(b.on) with no on_tap, and SettingsList.switch/1 (ui/settings_list.ex:641-660) adds none. choice/2 (auto_detect.ex:~430) builds the three decision pills from MishkaToggle with no on_tap. Only {Kati.Screens.AutoDetect, :tv} appears in @inert_taps (test/kati/screen_tap_sweep_test.exs:302).

*Fix.* None of these can persist until a detect-settings resource exists. Report them as a group and either disable-style them or, per the screen's own precedent, route them to Kati.Screens.RetiredTile.

*Fixed.* `tap/1` names the three rows that have somewhere to go — the browser extension's retirement reason, the media-access system page, and the tick threshold — and the master switch on the cream banner carries its own tap. Everything still without one has nothing behind it, which is #115 and is a feature rather than a wire.

### 101. 37 Import (Kati.Screens.Import) — `inert-control`

**Screen 37 has zero controls: the 'Import 412' commit pill, the step meter and the three conflict answers are all pictures, and because none carries a tag the tap sweep cannot see any of them.**

*Proof.* grep -c on_tap lib/kati/screens/import.ex returns 0. header/1 (import.ex:97-119) draws the ink 'Import 412' pill with no on_tap; choice/1 (import.ex:~470) builds each conflict answer from MishkaToggle with no on_tap; the module defines no handle_tap/2. Consequently none of these appear in @inert_taps in test/kati/screen_tap_sweep_test.exs.

*Fix.* Nothing here can be wired until a job resource exists (the moduledoc names the shape). Until then, draw the pill and the three choices in a plainly disabled treatment, or route the pill to Kati.Screens.RetiredTile the way screen 36's Browser extension row does.

*Fixed for the controls; the resource is still missing and is the point.* The three conflict choices carry `answer_`/`all_` tags and `answer/3` closes the card, and the commit pill carries `:commit` — each live only when the job behind it is, so the drawn frame still taps nothing because there is nothing on it to answer about. What remains is what this finding's own *Fix* named: no Ash resource models a file, a column mapping, an outcome count or a conflict queue, so step 3 of 4 cannot survive the screen popping. That is a feature, and `Kati.Backup.inspect_file/1` is the shape to copy when it lands.

### 102. 80 Data sources (Kati.Screens.DataSources) — `inert-control`

**The Refresh and Clear pills under Cached metadata emit no tap at all — the only cache controls in the app are pictures, and they are invisible to the tap sweep.**

*Proof.* lib/kati/screens/data_sources.ex:469 and :471 call Kati.UI.SettingsList.action_pill/1, which (lib/kati/ui/settings_list.ex:702-716) passes no on_tap to MishkaPill. Because they send nothing, Kati.ScreenTapSweepTest never sees them and they carry no @inert_taps entry stating a reason.

*Fix.* Give action_pill/1 an optional tag, wire :refresh_cache to a Kati.Media.CachePolicy stale pass and :clear_cache to a destroy of CachedTitle/CachedSeason/CachedEpisode behind a confirmation.

*Fixed.* `action_pill/2` takes an `on_tap` and screen 80 passes one to both: `:refresh_cache` and `:clear_cache` (data_sources.ex:922, :924).

### 103. 98 Your year, shared (Kati.Screens.YearShare) — `inert-control`

**The five non-resting scope chips and the privacy switch move assigns that nothing reads, so they relight over a card that never changes — and the sweep passes them because the assign does change.**

*Proof.* handle_tap/2 sets :scope (year_share.ex:373-376) and :hide_private (year_share.ex:364-365). content/1 builds the card as card(assigns.aspect) (year_share.ex:63); :scope is consumed only by scopes/1 for chip highlighting and :hide_private only by privacy_row/1 for the switch graphic. @inert_taps lists only scope_All and aspect_square (test/kati/screen_tap_sweep_test.exs:583-584). Kati.Screens.YearShareDark's moduledoc calls this '98's small untruth'.

*Fix.* Either make card/1 take the scope and the privacy flag and recompute, or draw only the scopes the app can actually answer and remove the privacy switch until a private-title flag exists.

*Fixed.* `Kati.ShareCardScopeTest` is the file this finding produced: the five chips narrow the card through `top_titles/1`, and the privacy switch reads `Kati.Media.TrackedTitle.private`, which the ⋯ menu on a title's own page writes.

### 104. 03 Library / 152 Anime — `missing-feature`

**`:anime` is a dead kind — nothing in the app writes it — so the Library queries a third shelf that is always empty, and board 152's entire subject has no column and no writer.**

*Proof.* lib/kati/screens/library.ex:111 `@screen_kinds [:movie, :tv, :anime]` and `shelf/0` reads all three. lib/kati/screens/add_title.ex:592-596 `kind_of/1` answers `:tv` when the meta contains "SERIES" and `:movie` otherwise — the only two values any create ever receives (:487-505). `grep -rn ":anime" lib/ --include=*.ex` outside the anime fixture files finds only readers and one-of constraints; no writer. lib/kati/media/tracked_title.ex:81-157 has no anime-override attribute, which is exactly what lib/kati/screens/anime_filter.ex's moduledoc says board 152 is proposing ("three things with no column yet"). Latent consequence: lib/kati/screens/library.ex `shaped/3` sets `kind: if(tracked.kind == :movie, do: :film, else: :series)`, so if an anime FILM ever existed its tile would push `Kati.Screens.Series`.

*Fix.* Add the override attribute and a writer, or drop `:anime` from `@screen_kinds` and from the resource's one_of until there is one. If it is kept, `shaped/3` must decide film-vs-series from the cached row's runtime/episode_count, not from `kind == :movie`.

*Fixed 7 September.* `Kati.Media.Anime` is board 152's three rules, `tracked_titles.anime_override` and `cached_titles.original_language` are the two columns they needed, and `film?/2` asks the cache which screen an anime opens.

### 105. 06 Add a title (Kati.Screens.AddTitle) — `missing-feature`

**A search that returns nothing draws a bare '0 results' and empty space — no message, indistinguishable from a search that never ran.**

*Proof.* lib/kati/screens/add_title.ex:114-137 render/1 draws search_notice (nil on a successful empty search, because searched/2 at :274 assigns :search_error nil on {:ok, []}), then the eyebrow, then results([]) — an empty Column plus a Spacer (:686-696). The sibling sheet has exactly this band: Kati.Screens.AddTitleMusic.nothing_band/2 (lib/kati/screens/add_title_music.ex:168).

*Fix.* Add a nothing-found band mirroring AddTitleMusic.nothing_band/2, pointing at the 'Add it by hand' row that is already below it.

*Fixed.* *Nothing here for “…”* — a search that ran and found nothing, said out loud and distinguishable from one that never ran (add_title.ex:1039).

### 106. 12 Lists — `missing-feature`

**Screen 12 has one working control and it writes nothing. `+` prepends a row literally titled "New list" to the socket, which is lost on back; tapping it twice gives two identical "New list" rows; there is no way to name a list, put anything in one, or open one. Every list row is untappable by design.**

*Proof.* lib/kati/screens/lists.ex:80 `load/1` assigns `Sample.lists()`; :373 `handle_tap(:new_list, …)` calls `Mob.Socket.update(socket, :lists, &add_list/1)`; :390-393 `add_list/1` — `row = %{title: "New list", count: "0 titles", badge: nil, seeds: []}` — and nothing calls `Ash.create`. The moduledoc states "The rows themselves are left untappable on purpose" and "With a resource behind it, `add_list/1` is where the create goes." `made_row/1` (:159) and `kept_row/2` (:288) carry no `on_tap` — the kept rows draw a `chevron_right` that opens nothing.

*Fix.* A `Kati.Lists.List` resource plus a list-title join, a name field on create, and a list-detail screen. Until then the four `Kept automatically` chevrons should be removed — two of the four (`Abandoned` = `status: :dropped`, `Rewatches` = a `Watch` with a `rewatch_number`) are one query each and would be the cheapest real rows on the page.

*Code done 7 September; design filed as [mishka-group/kati#99](https://github.com/mishka-group/kati/issues/99), and the drawings landed the same day.* The two derivable kept lists are real, the two that store nothing are not drawn, and `+` stopped lying. The three surfaces #99 asked for arrived in the `D-65` wave and are all built: board 335's naming grammar, board 333's picker sheet (`Kati.Screens.AddToList`), and boards 330-332's list detail (`Kati.Screens.ListDetail`), each with a Persian mirror. The chevrons point at 331 now.

### 107. 143 Episode rows / 144 Rate an episode — `missing-feature`

**Both boards depend on a long press, and Mob has no long-press primitive — so the gesture that is meant to be the door to rating an episode does not exist anywhere in the app.**

*Proof.* A repo-wide grep for 'long_press' returns nothing; episode_ratings.ex:126-130 records this ('Mob has no long-press primitive at all — a screen-wide grep for long_press finds nothing'). The only door to 144 is series.ex:1155-1156's ⋯ menu row, which the design does not draw.

*Fix.* Either add a long-press node to the bridge, or accept the menu row as the permanent door and redraw board 04 with it, rather than leaving a hint card that describes an unavailable gesture.

*Fixed.* `K-47 long-press` is on the bridge: `Mob.Renderer` had serialised `on_long_press` since it was written and `MobBridge.kt` read only `on_tap`; `combinedClickable` reads both now, and `native/LEDGER.md` carries the fence. `Kati.Screens.ListDetail` is the first screen to use it.

### 108. 143 Episode rows — the rating column — `missing-feature`

**Board 143 specifies a rating column for screen 04's episode rows, and screen 04 has none — no rating node, no read of Watch.rating. The board has been built as a standalone picture and never applied to the screen it is an edit of.**

*Proof.* lib/kati/screens/series.ex:1041-1095 — episode/1 draws number, title, sub-line and check/2 and nothing else. lib/kati/screens/episode_ratings.ex:163-181 are two hard-coded specimen lists; the moduledoc says wiring the column 'belongs to Kati.Screens.Series itself'. Kati.Media.Watch.rating exists (lib/kati/media/watch.ex:80).

*Fix.* Read Watch.rating per episode in Series.assembled/5 and add EpisodeRatings.rating_node/1's construction to Series.episode/1. Then 143 can be deleted from Settings, as the user asked.

*Fixed.* Screen 04's episode rows carry the column. `ratings_by_episode/1` reads the ticks' own ratings, `episode_facts/4` puts one on each row, and `Kati.Screens.EpisodeRatings.rating_node/1` draws it (series.ex:1411) — board 143's own moduledoc named `Kati.Screens.Series` as where the wiring belonged and this is it.

### 109. 145 Shelf filter sheet — `missing-feature`

**The trailing filter disc that board 145's caption names as its own entry point does not exist on any of the three shelves it names.**

*Proof.* 145's caption (quoted in lib/kati/screens/library.ex:571-575) is "a trailing filter disc in the header of screens 03, 20 and 21", and library.ex:573 says "none of the three boards has one". `grep -oE "search|sort|tune|more_horiz" test/design/screens/03.html` returns exactly `search` and `sort`. The ⋯ menu row Library added is called a placeholder by its own moduledoc (library.ex:583-586).

*Fix.* Redraw 03/20/21 with the disc, or accept the sort disc as the permanent entry and delete the ⋯ menu row.

*Fixed 7 September.* The sort disc board 03 already draws is the permanent entry; the duplicate ⋯ row is gone.

### 110. 149 Dropping — the sheet and after — `missing-feature`

**A film cannot be dropped, abandoned or DNF'd anywhere in the app: 08's ⋯ menu has one row and 149 is series-shaped.**

*Proof.* lib/kati/screens/film.ex:617 builds the overflow with a single item, `Kati.UI.Menu.item("star", "Log a watch", :log_watch)`. The only push of DropSheet is lib/kati/screens/series.ex:1164-1172 (Series ⋯ -> 'Drop this show'). DropSheet's header is literally "Drop this show" (drop_sheet.ex:~404), its position card prints `S#{s.season} E#{s.episode}` and step_back/1 (drop_sheet.ex:326-333) walks seasons and episodes.

*Fix.* Design a film-shaped drop (no position, or a runtime position) and add it to 08's menu; 149 cannot be reused as drawn.

*Fixed 7 September.* 149 is reused — `heading/1`, `position_card/1` and `at/1` are the four places it was series-shaped, and screen 08's ⋯ gains the row.

### 111. 149 Dropping — the sheet and after — `missing-feature`

**The drop reason the user picks is held in socket assigns and thrown away; there is no column and no event row for it.**

*Proof.* lib/kati/screens/drop_sheet.ex:217 `assign(:reason, nil)`; handle_info({:tap, tag}) when tag in @reason_tags (drop_sheet.ex:781) only assigns. commit_drop/1 (drop_sheet.ex:334-341) writes `%{status: :dropped, progress_season:, progress_episode:}` and nothing else. lib/kati/media/tracked_title.ex has no drop_reason attribute.

*Fix.* Add the media_events append-only resource that screen 15's moduledoc already specifies, and write {dropped, position, reason} into it.

*Fixed 7 September.* `Kati.Media.Event` exists — the append-only `media_events` table screen 15's own moduledoc specified — and the drop writes `{dropped, position, reason}` into it.

### 112. 15 Activity — `missing-feature`

**The 'Added' filter chip can never match a real row, and selecting it draws a blank page with no empty state.**

*Proof.* lib/kati/screens/activity.ex:712-718: verb/2 returns only "Rated", "Rewatched" or "Watched". Kati.Activity.Sample.filters/0 (activity/sample.ex:25) offers ["All", "Watched", "Rated", "Added"]. visible/2 (activity.ex:238-241) filters on `lead`, so "Added" matches nothing; group([], ...) returns [] (activity.ex:251) and rewatch_section([]) returns [] (activity.ex:531), leaving header + chips and nothing else.

*Fix.* Drop the Added chip until a media_events/status-change resource exists, and give the screen an empty state for a filter that matches nothing.

*Fixed 7 September.* The chip finds real `:added` rows, and a chip that matches nothing says so rather than leaving a blank.

### 113. 154 Add a title by hand (Kati.Screens.AddByHand) — `missing-feature`

**The same film can sit on the shelf twice — once from TMDB and once hand-typed — because the duplicate guard is per-source, and a wrong Kind can never be corrected.**

*Proof.* The guard is the unique index on [:source, :source_id] (lib/kati/media/tracked_title.ex:64). A TMDB add writes source: :tmdb with a numeric source_id (lib/kati/screens/add_title.ex:496-501); a hand-typed add writes source: :manual with the title as source_id (lib/kati/screens/add_by_hand.ex:478-482). They never collide. Conversely, re-adding the same title with a different kind IS refused (refusal/2, :503-515), and no screen in the app updates TrackedTitle.kind.

*Fix.* Before writing a :manual row, look for a cached title with the same name under any source and refuse with 'you already have this'. Separately, expose Kind on the title's detail screen so a mistake is correctable.

*Fixed 7 September.* `already_kept/1` guards on the name across every source, and a ⋯ row on 08 and 04 corrects the Kind on both rows.

### 114. 19 Search — `missing-feature`

**Your own review of a film or series is not searchable anywhere, although the Search screen's Notes group and Kati.Search's Screen scope both claim it is.**

*Proof.* lib/kati/search/query.ex `note_for/1` reads `Kati.Books.Note` and nothing else; `cached_for/1` calls `tier(query, &1.title || "", &1.overview || "")`, so only title and overview are matched. The user's film review lives on `Kati.Media.Watch.review` (lib/kati/media/watch.ex:81, written by lib/kati/screens/rating.ex:1442/1495 and rate_episode.ex). lib/kati/search.ex @scopes declares the Screen scope searches ["title", "original title", "alt titles", "cast", "your tags", "your review"] and screen 88 renders that list verbatim.

*Fix.* Add a `Kati.Media.Watch` pass to `note_for/1` (its `watched_on` and the cached title are exactly the `NOTE · 6 AUG · THE LONG HOLLOW` eyebrow the board draws), and either search the extra Screen fields or trim `@scopes` to what is true.

*Fixed 7 September.* `note_for/1` reads `Kati.Media.Watch.review` alongside `Kati.Books.Note`, and the Screen scope searches five of its six named fields — see the ledger row and #74.

### 115. 36 Auto-detect (Kati.Screens.AutoDetect) — `missing-feature`

**Auto-detect detects nothing: every figure, source, tick count, rule and queued question is a literal, and no resource exists for any of it.**

*Proof.* load/1 assigns six values, all from Kati.Settings.DetectSample (auto_detect.ex:58-68). lib/kati/settings/detect_sample.ex is pure literals ('3 sources', '41 EPISODES TICKED FOR YOU', 'The Long Hollow' S2E6 at 0.74, 'Apple TV · 28 ticks', the Marram question). Kati.Media.Watch has no provenance column — driven_by (lib/kati/media/watch.ex:135) is constrained to :character | :both | :plot — so a detected-vs-tapped count is not derivable, and nothing anywhere holds a session in flight.

*Fix.* Out of scope for a wiring pass. The screen's own moduledoc names what is needed; the reportable defect today is the green 'Live' status pill over a device playing nothing.

*Fixed.* `Kati.Media.Detect` is the feature. It holds the master switch and the tick threshold, reads what the phone is playing through `KatiMediaListener` (`K-46` in `native/LEDGER.md`), matches by name against the reader's own shelf — exactly, case and whitespace aside, because `Se7en` and `Seven` are two films — ticks what it is sure of, and turns what it is not into the question the queue card is arranged around. `Kati.Media.Watch.detected` is the provenance column this finding's first near miss said did not exist, so the banner counts the ticks Kati made rather than every tick ever.

### 116. 80 Data sources (Kati.Screens.DataSources) — `missing-feature`

**There is nowhere in the entire app to enter a TMDB key, yet every TMDB failure message tells the user to come here and do exactly that.**

*Proof.* lib/kati/media/tmdb.ex:302-307 reads Kati.SecureStore.get("tmdb"); grep across lib/ shows SecureStore.put/2 is never called for "tmdb" (only .get at sources.ex:145, tmdb.ex:304, caldav/transport.ex:119, and .delete at sources.ex:196). lib/kati/screens/data_sources.ex contains no <TextField>. tmdb.ex:359 composes "No TMDB key yet. Add one in Settings → Data sources." Board test/design/screens/80.html draws no field either.

*Fix.* Add a key field to the TMDB card, shown when `choice == :own`, writing through Kati.SecureStore.put("tmdb", token). Until then, key_own must not be selectable — or the message must stop pointing here.

*Fixed.* Board 318 built the card: `Kati.SecureStore.put("tmdb", token)` at data_sources.ex:1216, so the screen every TMDB failure message points at is a screen where a key can actually be entered.

### 117. 89 Result states — `missing-feature`

**Screen 19 has no cross-scope card, so narrowing to an empty scope draws "Nothing here" over a query that did find things — the exact misreading board 89's third band was drawn to prevent.**

*Proof.* lib/kati/screens/search.ex `state_or_groups/3`: `Kati.Screens.Search.visible_groups(results, filter) == [] -> Kati.Screens.Search.no_matches(results.query)`. `visible_groups/2` filters on `filter == label` then rejects blank groups, so filtering to Notes when only titles matched leaves `[]` and the no-match card is drawn. lib/kati/screens/search_result_states.ex draws the correct answer (`elsewhere_chips/0` and the cross-scope card) and screen 19 calls only its `nothing/2`.

*Fix.* In `state_or_groups/3`, distinguish 'nothing matched anywhere' from 'nothing matched in this scope' and render 89's cross-scope card for the second, offering the chip that has the hits.

*Fixed 7 September.* `state_or_groups/3` separates the two states and `cross_scope/2` draws board 89's third band live. Its tap is a `go_` tag, not the chip's `filter_` one — two nodes may not share an `accessibility_id`.

### 118. 92 My services — `missing-feature`

**The search field types but filters nothing, and the one sentence it exists for is never drawn. `content/1` renders `subscribed()` and `free()` unconditionally; `query` reaches only `search_field/1`. Screen 95 draws the answer — "No service called that. Kati uses JustWatch's list through TMDB. If it is a real service they do not track, add it as Something else." — and nothing on 92 can produce it.**

*Proof.* lib/kati/screens/my_services.ex:147-176 — `content/1` passes `query` to `search_field/1` and to nothing else; `service_group(subscribed(), true)` and `service_group(free(), false)` take no query. lib/kati/screens/my_services_states.ex:337-343 holds the copy (`query_field("mubi plus")`, "No service called that"). The tap sweep lists `{Kati.Screens.MyServices, :search}` as inert with the reason "What the row's own `on_tap` still opens is nothing" (test/kati/screen_tap_sweep_test.exs, @inert_taps).

*Fix.* Filter both groups on `String.contains?(String.downcase(name), String.downcase(query))`, and when the filtered result is empty draw 95's sentence above the `Something else` row.

*Fixed 7 September.* `matching/2` narrows both groups and the count with them, and `no_match/2` draws board 95's sentence above the row it names.

### 119. 92 My services — `missing-feature`

**There is no way to remove, rename or price a service. Once `Something else` writes a row you are stuck with it and can never get back to the drawing; every service row taps a handler that returns the socket unchanged.**

*Proof.* lib/kati/screens/my_services.ex:584-587 — `"edit_service_" <> _name -> {:noreply, socket}`. @inert_taps lists all five drawn rows (`:"edit_service_Lumen+"`, `:edit_service_Orbit`, `:edit_service_Kino`, `:edit_service_Aria_Free`, `:edit_service_Dispatch`) with the reason "`:edit_service` opens nothing because no per-service editor is drawn anywhere in the set". `Kati.Services.Service` has full CRUD. Screen 95's own moduledoc records that 92's rows are missing the price pill and the per-service switch its board specifies.

*Fix.* Board 95 already specifies the control: a 32pt price lozenge and a 46x28 switch on each row. Adding the switch gives removal (tier → `:not_mine`) and the price field gives 23 a real total — the two changes that unblock the whole cluster.

*Fixed 7 September.* Board 95's switch is on every row, and the row's tap refills the field the service was typed in — where a repriced save now updates rather than writing nothing.

### 120. 96 Nothing set up — knock-on — `missing-feature`

**Screen 96 documents four empty states that no screen can ever enter, and says so itself: the predicate it defines cannot answer false, because 92 falls back to fixtures on an empty store.**

*Proof.* lib/kati/screens/nothing_set_up_knock_on.ex — moduledoc: "It is also the honest place to record that the predicate cannot answer `false` today: 92 falls back to `Kati.Services.Sample` when the store is empty, so the four screens that would ask this question need that fallback to become conditional before any of them can put these bands on screen." `set_up?/0` asks `Kati.Screens.MyServices.listed/0` (my_services.ex:118) and is never called by 08, 11, 13 or 23.

*Fix.* Same fix as the 92 fallback finding: make `listed/0` able to answer "nothing", then have 08/11/13/23 draw 96's bands. That single change turns 96 from a picture into four shipped empty states and lets it be deleted from the gallery.

*Fixed 7 September.* All four bands ship on 08, 11, 13 and 23; the predicate can answer `false` since #75.

### 121. 03 Library — `polish`

**Two shelf titles that differ only by a space versus an underscore collapse onto one tap target, and every distinct cached title mints a new atom.**

*Proof.* lib/kati/screens/library.ex `poster_tag/1` does `String.replace(" ", "_") |> String.to_atom()` on the cached title, and `open_tile/3` resolves with `Enum.find(... == tag)` — the first match wins. The @doc for `poster_tag/1` already records the identical collision class that #97 fixed for bare `:open_film`. `String.to_atom/1` on provider-supplied titles also adds an unreclaimable atom per distinct title.

*Fix.* Tag by the tracked row's id (`:open_film_<uuid>`), which is unique and bounded, and keep the title only in the accessibility label.

*Fixed 7 September.* A tile is named by its row id; the title is the fallback for a row that has none.

### 122. 03 Library — `polish`

**The Books/Music branch of visible/3 is unreachable: the shelf assign can never hold anything but "Screen".**

*Proof.* lib/kati/screens/library.ex `def visible(_titles, _filter, shelf) when shelf != "Screen", do: []`. The only writer of the `:shelf` assign is the catch-all `"shelf_" <> label` clause in `handle_tap/2`, and `:shelf_Books` and `:shelf_Music` are answered by their own earlier clauses which push `Kati.Screens.Books` / `Kati.Screens.Music` instead. So only `:shelf_Screen` — which the segment strip only emits for the already-selected segment — ever reaches the assign.

*Fix.* Delete the guard clause and the `shelf` assign, or restore it if the segments are ever meant to swap in place.

*Fixed 7 September.* Deleted — the guard, the assign and its writer.

### 123. 04 Series detail — `polish`

**The season pill strip and the EPISODES eyebrow share one un-scrolling Row, so a long-running show overflows: ten 30pt pills plus 5pt gaps is ~345pt against ~369pt of content width on a 411dp device, before the eyebrow takes its share.**

*Proof.* lib/kati/screens/series.ex:966-986 — episodes_header/1 lays the eyebrow, a weighted Spacer and `Enum.map(s.seasons, …)` in a single Row with no Scroll. season_pill/2 (series.ex:1009-1019) is a fixed Box width={30} with pill_gap/0 at 5.

*Fix.* Wrap the pills in a horizontal Scroll, or move the strip to its own row below the eyebrow.

*Fixed 7 September.* `season_strip/1` scrolls horizontally, weighted so the eyebrow keeps its width.

### 124. 07 Your year (Kati.Screens.Stats) — `polish`

**The contribution grid is the last 182 days ending today, while the header names the calendar year so far — in early months the field is mostly last year under this year's label.**

*Proof.* contributions/1 builds the field from (@grid_days - 1)..0 offsets back from Kati.Time.today() (lib/kati/screens/stats.ex:1043-1055), where @grid_days is 182. range/1 renders 'Jan – <this month> <this year>' (stats.ex:990-992), and the hero prints year.weeks as '26 weeks' (stats.ex:435-441). In March the two describe different spans.

*Fix.* Either clip the grid to the calendar year and let it be short, or label it '26 weeks to today' so the field and the header stop claiming the same span.

*Fixed 7 September.* The caption reads **26 weeks to today**.

### 125. 07 Your year (Kati.Screens.Stats) — `polish`

**@destinations carries a 'Recently watched' -> UpNext entry that more_numbers/1 explicitly filters out, so it is dead code.**

*Proof.* lib/kati/screens/stats.ex:1131-1138 maps "Recently watched" => Kati.Screens.UpNext, but more_numbers/1 begins Enum.reject(Kati.Stats.Sample.more_numbers(), &(&1.title == "Recently watched")) (stats.ex:~630), so no row with that title is ever drawn and no go_Recently watched tag is ever emitted.

*Fix.* Delete the entry, or draw the row and let it open Up next.

*Fixed 7 September.* Deleted.

### 126. 140 Import — where are you coming from (Kati.Screens.ImportSources) — `polish`

**'Five more sources' lists five names of which one, AniList, is already a tile in the grid above it, and the row itself is a navigation stub with no list behind it.**

*Proof.* lib/kati/screens/import_sources.ex more/0 draws the sub-line 'Simkl · TV Time · Libib · Last.fm · AniList' while @commonest already contains %{id: :anilist, name: "AniList"}. handle_tap :five_more pushes Kati.Screens.Import (import_sources.ex:405-407), not a list of five. The moduledoc records the repeat as the drawing's own copy error, kept deliberately.

*Fix.* Once a fifth-source list exists, drop AniList from the sub-line and point :five_more at it.

*Fixed 7 September.* **Four more sources**, the drawing's own count, and the row opens the picker.

### 127. 149 Dropping — the sheet and after — `polish`

**The 'Change' pill only decrements the captured position one episode at a time and can never go forward, so overshooting requires closing and reopening the sheet.**

*Proof.* lib/kati/screens/drop_sheet.ex:326-333: step_back/1 has three clauses — episode-1 when e > 1, season-1/episode 1 when s > 1, and identity otherwise. handle_info({:tap, :step_back}) (drop_sheet.ex:777) is the only handler for the pill (drop_sheet.ex:500-520).

*Fix.* Either build the episode picker the moduledoc says does not exist, or make the pill a two-way stepper.

*Fixed 7 September.* Two discs, both directions.

### 128. 155 Add by hand — resting & refused (Kati.Screens.AddByHandStates) — `polish`

**The empty-title refusal is one line where the board specifies two, and drops the reassurance that nothing was lost.**

*Proof.* lib/kati/screens/add_by_hand.ex:463 assigns the single string 'A title is the one thing this needs.' test/design/screens/155.html, band 'The save that refuses': 'A title is needed' / 'Kati cannot keep a thing with no name. Nothing was written — this form is still open and your other answers are intact.' — the same two-part shape screen 95 uses.

*Fix.* Use the board's two-part wording through Kati.UI.SettingsList.note/2, and give the Title field the red inset ring 155 draws.

*Fixed 7 September.* Board 155's two-part card, and the red ring on the field it is about.

### 129. 19 Search / 88 Scope & ranking — `polish`

**The tie-break the specification screen renders — tier, then recency — is implemented and never called; results actually tie-break alphabetically.**

*Proof.* lib/kati/search.ex `rank/1` sorts by `{tier, recency_key(recency)}` and is public with a @doc describing the board's rule. `grep -rn "Search.rank\|rank(" lib/` finds no call site. lib/kati/search/query.ex sorts `Enum.sort_by(fn {tier, title, _row} -> {tier, title} end)` for titles and `{tier, row.summary}` for calendar.

*Fix.* Call `rank/1` with `last_touched_at` / `dtstart_utc` as the recency, or delete it and correct screen 88.

*Fixed 7 September.* `rank/1` is the sort in all four groups, with the recency each row actually has.

### 130. 86 Search idle — `polish`

**A recent query or suggestion is round-tripped through underscore substitution, so any query containing an underscore or a run of spaces comes back changed.**

*Proof.* lib/kati/screens/search_idle.ex `query_tag/2` does `String.replace(" ", "_")` to build the tap tag; `open/2` does `query = String.replace(line, "_", " ")` to undo it. `sci_fi` is stored as typed by `Kati.Search.Recent.remember/1` (which "never translates — they are your words"), tagged `:repeat_query_sci_fi`, and reopened as `sci fi`. Screen 19's own recent shelf does not have this bug — `recent_" <> label` carries the label whole.

*Fix.* Index the rows and resolve the tag against `socket.assigns.history` the way `Kati.Screens.Library.open_tile/3` resolves a poster tag.

*Fixed 7 September.* `Kati.Screens.SearchIdle.resolve/2` resolves the tag against the rows that drew it. There was no inverse to write.

### 131. 88 Scope & ranking — `polish`

**88's back pill reads "Settings" but its only route in is the tune disc on the idle search page, and it pops back there.**

*Proof.* lib/kati/screens/search_spec.ex:39 `use Kati.Screens.Pushed, back: "Settings"`. The only push is lib/kati/screens/search_idle.ex `def handle_tap(:filters, socket), do: push_screen(socket, Kati.Screens.SearchSpec)`, confirmed by routes.txt `88 Scope & ranking  Home > open_search > filters`. `Kati.Screens.Pushed`'s `{:tap, :back}` is `pop_screen/1`, so the pill returns to 86 while naming Settings.

*Fix.* Take the label from the push, as `Kati.Screens.Search` already does with its `back:` param.

*Fixed 7 September.* The push names `Search`; `Settings` stays as the answer for a push that names nowhere.

### 132. 19 Search at 235% — `polish`

**The third scope chip on a wrapped line loses its count at 235%: `chip_rows/1` packed three to a line and three of the labels are wider than a 393dp phone has at that scale, so `Books` kept its name and dropped its `0`.**

*Proof.* The measurement that would settle it is not available to Elixir — `max_font_scale` caps growth and nothing reports it, and `MobBridge.kt` has no wrapping row — so the choice was between packing two to a line (three lines of chips above every ordinary search, where board 19 draws one) and a `FlowRow` on the bridge.

*Fix.* A `FlowRow` on the bridge, or a font-scale reading, or a row that does not wrap.

*Fixed 7 September.* Board 313 takes the third answer and settles the ROW rather than the measurement: `chip_rows/1` returns one line and `chip_line/1` scrolls it, so no chip is ever on a wrapped line to lose its count. 313 rejects the wrapped version on its own merits as well as on the bridge's — *"Better to read, and three lines tall — on a 235% page where the field alone is 62pt, that is the results pushed off-screen"* — and requires the scroll to carry an affordance, which screen 86's row got on 8 September (#34). [mishka-group/kati#98](https://github.com/mishka-group/kati/issues/98) stays open for the `FlowRow` itself, which other rows may still want.

### 133. 05 New releases (Kati.Screens.Inbox) — `missing-feature`

**Board 307 draws the inbox as four rows across three shelves — an episode, a book, a record and a film — and screen 05 can only ever draw the episode. Nothing in the app produces a book release, a record release or a film release, so the other three shelves of board 307's own top frame are unreachable.**

*Proof.* lib/kati/screens/inbox.ex `out_now_rows/5` is episodes and says so in its moduledoc: *"Films are not in this list"*, because a film's date is `Kati.Media.CachedTitle.next_release_at`, which is *the next* release and moves forward — reading it backwards to say *this came out today* asks a forward-looking column a question about the past. Board 307's film row is fed by a **wishlist**, and there is no wishlist: `Kati.Media.TrackedTitle`'s `status` is `one_of: [:not_started, :watching, :paused, :finished, :dropped]`, which is why board 12's `Wishlist` row is on `DesignLiterals.retired_lines/0` already. The book row is fed by `Kati.Books.FollowedAuthor`, which now exists — screen 66 writes it — but Open Library is asked about a title and never about a person's next one. The record row is fed by `Kati.Music.Artist.following`, which is real and has been since screen 77, and no MusicBrainz release feed is read.

**Books and Music are blocked on choosing a free, keyless API first — Open Library and MusicBrainz are named on screen 80 and neither is called anywhere in `lib/`.**

*Fix.* Three producers, one per shelf, and each is its own piece of work — and two of them are not this section's. **Books** and **Music** are filed as [mishka-group/kati#100](https://github.com/mishka-group/kati/issues/100) and [mishka-group/kati#101](https://github.com/mishka-group/kati/issues/101): neither domain has an HTTP client at all, so the shelf is the smaller half of a bigger gap. What stays here is the **film** producer — a wishlist status on `Kati.Media.TrackedTitle`, whose `status` is `one_of [:not_started, :watching, :paused, :finished, :dropped]` and holds no such thing, which is why board 12's `Wishlist` row is already on `DesignLiterals.retired_lines/0`.

*Partly done 8 September.* The two halves that do not need a producer are built. Screen 25's *Tell me about* offers the three shelves board 307 lists, and screen 66 (with its Persian mirror, 69) has the **Follow the author** row the board calls *"the only new ink 66 needs"* — `Kati.Books.FollowedAuthor`, backed up at schema version 18.

**The one thing deliberately not built: board 307's row recipe.** The board replaces screen 05's 44×62 poster with a 40×40 glyph tile, and states its reason — *"a record has square art, a book a portrait cover, an episode a landscape still, and three aspect ratios in one list breaks the row rhythm."* That reason is **conditional on the list holding more than one shelf**, and it holds one. Swapping a real poster for a generic `live_tv` glyph today would degrade the only state that can occur, to fix a rhythm problem that cannot yet happen. The recipe goes in with the first producer above; until then screen 05 keeps its poster and its `Watch` pill.

### 134. 97 سرویس‌های من — `lies-to-user`

**Screen 97 printed ایران to every Persian reader whether or not they had chosen a country, drew the drawing's ۴۶٫۴۷ £ monthly total over a shelf with nothing on it, and its country row carried a chevron that opened nothing because no Persian country picker existed.**

*Proof.* lib/kati/screens/my_services_fa.ex `region/0` was `case Services.region() do "GB" -> "IR"; code -> code end` — `region/0` answers `"GB"` on a phone nobody has told anything, so a reader who had chosen nothing got Iran and a reader who deliberately chose Britain got Iran too, which is board 301's own closing sentence. `money_group/1` printed `Kati.Services.Sample.monthly_total/0` for any list, empty included. `region_group/1` drew `chevron/0` with no `on_tap`, and `handle_info({:tap, tag}, …)` had no `:pick_country` clause; `grep -rn CountryPickerFa lib/` returned nothing.

*Fix.* Read `Kati.Services.chosen_region/0`, which can answer *no country*; draw board 324's cream *choose a country* row for a `nil`, and 93's *nothing to add up yet* row for an empty shelf; build board 301's sheet and push it from both country rows.

*Fixed 8 September.* All three. `Kati.Screens.CountryPickerFa` is board 301 — a sheet, Iran marked before any choice and marked without storing it, matching by Persian name, English name or code. `Kati.ScreenMyServicesFaTest` holds every part of it.

*One deviation, and it is a decision already made.* 301 draws the field as «جست‌وجو در ۱۹۰ کشور» and argues seven rows do not need filtering but the sentence should speak correctly about the list. That is the argument #78 was filed against on screen 94, whose fix was to count what the field actually filters. The Persian placeholder counts `Kati.Services.countries/0` and prints it in Persian digits; the sheet's moduledoc says so.

*Two things board 324 draws that were not built, both deliberately.* Its rules card carries the empty-state third sentence — «خاموش به‌طور پیش‌فرض — با هیچ سرویسی همه‌چیز پنهان می‌شد» — where 97 draws the full one that board 310 counted; board 323, which 324's own note defers to, rules that the rules group is ONE group with one sentence, and 310 is the board that counted it. And 324 omits the *مال من نیست* eyebrow and the catalogue row, where screen 93 draws both on the same state in English; two locales showing a different number of groups for one state would be a drift, so 97 keeps them.

### 135. 02 Schedule (Kati.Screens.Calendar) — `missing-feature`

**Screen 02 could only say "Kati cannot see your calendar" on a day that was otherwise empty. On any day holding one of Kati's own events — a habit, an air date, a renewal — the page drew a timeline with the reader's appointments silently missing from it and no way to ask for them.**

*Proof.* lib/kati/screens/calendar.ex `empty_reason/2` is `def empty_reason([], access) when access in [:unasked, :denied, :blocked], do: :no_permission` — the first clause matches an empty list only, so a day with any row at all answers `:no_events` and `timeline/2` draws the rows. Board 306's own frame is that day: a habit at 08:00 and an air date at 20:00, over a calendar Kati cannot read. Nothing anywhere on screen 02 called `Mob.Permissions.request/2`; a repo-wide grep found the calendar request only in `Kati.Screens.PickSections.ask_for_calendar/1`, which runs once during onboarding.

*Fix.* Board 306's card, under the timeline rather than instead of it, in the three states `Kati.Permissions.affordance/1` names.

*Fixed 8 September.* `Kati.Screens.Calendar.calendars_card/1`. `:allow` draws the button and calls the same `note_asked/1`-then-request pair screen 40 and the onboarding step make; `:settings` keeps the card and replaces the button with screen 02's own sentence, which is 306's rule — *"the card stays, reworded to send you to system settings — Android grants no second prompt"* — and 136's before it; `:none` draws nothing, because granted needs no card and `:unknown` is the absence of an answer rather than a refusal.

*One deviation, and the manifest is the proof.* 306's mono line reads `READ AND WRITE · YOU PICK WHICH ON 32`. `AndroidManifest.xml`'s `K-26 read-calendar` fence declares `READ_CALENDAR` alone and states why — *"write-back is a separate decision (#54) and would need WRITE_CALENDAR"* — and screen 40's Calendars row already words it correctly as *Kati only reads them*. The line reads `READ ONLY`, and `Kati.ScreenCalendarEmptyStateTest` asserts it against the manifest so the day `WRITE_CALENDAR` is declared, the test says to follow the board.

*Two things 306 draws that were not built.* Its filter row carries counts — `All 2 · Screen 1 · Habits 1 · Personal 0` — over a chip set screen 02 does not have (02 draws All / Screen / Personal / Money, and none of them counts). 306's stated point about that row is that `Personal` must not vanish at zero, and it cannot: the four chips are a fixed list. Counting all four is a change to board 02's own row and belongs to a board about screen 02's chips.

### 136. 112 Medication (Kati.Health.Medication) — `missing-feature`

**A medication whose schedule reads `Mon, Wed, Fri` is given a dose every day of the week, and armed a reminder every day, because `schedule` is a free string the reader types and nothing structured records which days a prescription falls on.**

*Proof.* lib/kati/health/medication.ex:43 `attribute :schedule, :string` — free text, entered on screen 188 through `Kati.Screens.AddMedication`'s `trough(:schedule, …)` with the placeholder `every morning, 08:00`. The only structured half is `times`, and lib/kati/health/dose.ex `derive/2` is `for medication <- medications, at <- Enum.uniq(medication.times), clock?(at)` with no day test at all — the day it is handed is simply stamped on every row. `Kati.Notifications.Sources.Health.active/0` filters on `active` alone, so the same is true of the reminder.

*Fix.* Filed as [mishka-group/kati#102](https://github.com/mishka-group/kati/issues/102) — it is the Health section rather than this one. A `days` column on `Kati.Health.Medication` — the days of the week a dose falls on, defaulting to all seven so nothing already stored changes — read by `Dose.derive/2` and by the notification source, written by screens 188 and 189, and printed by `schedule_line/1`. Then board 327's sentence becomes expressible: with days, *which* schedules fall elsewhere is a filter and *when next* is the next day any of them matches.

*Partly built 8 September.* Board 327's card is drawn — a `check_circle` on a green wash, `Nothing due today` as its title, and a body that names why — but the why it can honestly give is not the board's. `Kati.Screens.Medication.nothing_due/1`'s two clauses are the only two ways this page reaches a quiet day: every medication paused, or schedules none of which has a clock time yet. The board's *"Your four schedules all fall on other days. Next is Monday at 08:00 — levothyroxine"* needs the column above, and that function's doc says so.

*What 327's second frame asks for and was not built.* Its *true empty* — `No medications` over an `Add a medication` ink button, with the Schedules group and its eyebrow both gone — is the state a reader with nothing stored is in, and screen 112 draws the drawing there instead: `doses({false, [], []})` answers `drawn_doses/0`, which is FIDELITY's rule that an empty store answers the board and which `Kati.ScreenEmptyDatabaseTest` pins for all 172 screens. Changing it for one screen is a decision about that rule rather than about this page.

### 137. 50 Share a plan / 120 Import a plan — `lies-to-user`

**Screen 50's QR card was titled `Scan to import this plan` over a mono line reading `SETTINGS ONLY`, said nothing about the 35 meals it cannot carry, and offered no route for them; screen 120 counted `29 New` for an arrival that brings none.**

*Proof.* lib/kati/meals/sample_share.ex `share/0` had `qr_title: "Scan to import this plan"` beside `qr_uri: "KATI://PLAN/CUTTING-V3 · SETTINGS ONLY"` — the two halves of one card disagreeing, and `qr_scope/0`'s own doc already argued at length that a QR cannot hold a meal library. lib/kati/screens/plan_import.ex `counts/0` was a single clause returning `29 / 4 / 2`, and `plan/0` a single clause whose `action` was `Import 35`; nothing distinguished a scanned arrival from a file one, and screen 50's *Scan a plan* row carried no tap at all (`tile_tap/1` matched `picture_as_pdf` and nothing else).

*Fix.* Board 316's ruling: *"Two ways out: widen the encode, or reword the card. Reword. A QR holds about 2,900 bytes and 35 meals with ingredients is tens of kilobytes — widening it is not a decision, it is a physical impossibility."*

*Fixed 8 September.* The card is `Scan to set up this plan` over a sentence naming what does and does not travel, and it offers the route that does carry the meals — screen 128's file, which is the only file this app produces. *Scan a plan* pushes screen 120 with `from: :code`, and that arrival is its own page: `Set up` rather than `Import 35`, `FROM A CODE · SETTINGS ONLY`, four rows saying what came and what could not, three zeroes where the counts were, and no conflict queue — a code cannot conflict with anything. `Kati.PlanQrScopeTest` pins both sides, and pins the card's promise against `qr_scope/0` rather than against a literal.

### 138. 98 Your year, shared (Kati.Screens.YearShare) — `lies-to-user`

**The card you are about to post draws a green up-arrow on a year that fell. Screen 07 one tap earlier draws the same figure red and pointing down.**

*Proof.* lib/kati/screens/year_share.ex `hours_face/1` computes `direction: if(year.rising?, do: :up, else: :down)` and `card/2` rendered `change_pill(@hours.change)` — the string alone — so `:direction` was computed, stored and read by nobody. `change_pill/1`'s drawing clause was unconditional: `Kati.UI.symbol("arrow_drop_up", size: 20, color: Palette.green_text())` over a `Text` in the same colour. Neither page prints a sign — `Kati.Screens.Stats`'s year is `change: change && "#{abs(change)}%"` — so the arrow is the ONLY place the direction is written down, which is why dropping it inverted the claim in silence rather than producing a visible mismatch. And this is the tree `:save_image` captures: there is no second render path.

*Fix.* Pass the hours face whole and ask `Kati.Screens.Stats.arrow/2` for the glyph and the colour, so the two pages cannot disagree about one year.

*Fixed 8 September.* `arrow/1` gained an opts list — `:size` and `:fill`, defaulting to screen 07's own 14pt filled — so 98 draws the same decision at its own 20pt unfilled. `Kati.ShareCardScopeTest` holds it at both ends: that a fallen year carries `arrow_downward` and not `arrow_drop_up`, and that the card's pill CONTAINS the node 07's helper builds rather than a second copy of it.

*Two outright `arrow_drop_up` glyphs remain and are safe only while their pages are fixtures.* `year_share_books.ex` draws board 99's pages figure, which is a literal that rises by construction, and `stats_fa.ex` draws screen 61 from `Kati.Fa.SampleYear`. Each is the second copy of this decision the day its page reads a real shelf, and both now say so.

### 139. 19 Search (Kati.Search.Query) — `polish`

**The Notes group returns at most one note however many match, and the Notes chip and the All chip agree with the cap.**

*Proof.* lib/kati/search/query.ex `note_for/1` built `book_notes() ++ review_notes()`, tiered them, ranked with `Kati.Search.rank/1` — and then `|> List.first()`. `chip_counts/1` counted it `if note, do: 1, else: 0`, so All added 1 for any number of matching notes. `titles_for/1`, `books_for/1` and `calendar_for/1` all return whole ranked lists: #62 removed the identical `Enum.take/2` from those three and did not reach this one. There is no `See all N →` row anywhere in `lib/`, so the other matches were unreachable from the page — five reviews with the same word in them drew one card and a chip reading `1`.

*Fix.* Drop the `List.first/1`, map `note_card/2` over the ranked list, and rename the result key `:note` to `:notes` — the word `Kati.Search`'s own `@scopes` list already uses, and the one place in the codebase that called it `:note`.

*Fixed 8 September.* `notes_for/1` returns the whole ranked list and screen 19's cream band maps over it. The rename deleted four special cases that existed only to keep a one-of shape working beside three lists — `count_of/2`'s `:note` clause, `blank?/2`'s, `chip_counts/1`'s `if note` and `empty?/1`'s `== nil`. The card's trailing 24 became 9 between cards and 15 after the last, which is board 19's own `gap:9px` rhythm and the arithmetic `titles/1` already does. `Kati.SearchGroupsTest` seeds five matching notes and holds all three claims: the group returns five, the chip says five, and all five are drawn.

### 140. 28 Home dark / 55 خانه — `cannot-work`

**Each screen gives two different nodes one `accessibility_id`, so on any device that follows a show, neither the notification bell nor the hero's *Open inbox* button can be addressed by a device test.**

*Proof.* `Mob.Renderer` emits an `accessibility_id` for every `{pid, atom}` `on_tap`, so the tag IS the id. On 28 the header bell was `disc("notifications", :inbox)` and the hero's button was `tap = {self(), :inbox}`; on 55 both the bell and `باز کردن صندوق` were `:open_inbox`. Espresso's `onNodeWithTag` throws on the second match rather than picking one, so BOTH controls became unaddressable together. `Kati.ScreenTapSweepTest`'s `@known_collisions` used to carry them and they came off it without being fixed — the sweep renders an empty store, where 28 draws board 315's page and 55 draws 158's and neither header has a bell at all, so the debt moved out of the sweep's reach.

*Fix.* Screen 01's two names, on all three: `:notifications` for the bell — which opens `Kati.Screens.InboxNotifications`, the page a bell means — and `:open_inbox` for the hero's button, which means the release inbox.

*Fixed 8 September.* Both screens split, and the claim is held where the fixture can exist: `Kati.ScreenDarkWidgetsTest` and `Kati.ScreenHomeFaEmptyStateTest` each write a tracked title and an aired episode to bring both nodes back, then assert no tag repeats and that each opens 01's destination. The sweep's own note was rewritten, because it recorded the debt as unpaid and was two versions out of date about which map held what.

*One drift left where it is, and written down at the site.* Screen 160's bell keeps `:open_inbox` and keeps opening `Kati.Screens.Inbox`. That page draws no hero, so the name collides with nothing there; renaming it would move a board screen's destination inside a defect fix. `lib/kati/screens/home_fa_omitted_sections.ex` says so above the disc.

### 141. 05 New releases (Kati.Screens.Inbox) — `lies-to-user`

**Screen 05's cream banner told every reader `Watching for 24 titles · last checked 18:02 · every 6h`, one tap from a screen that correctly said *Watching 2 titles* and *never checked* — and a refused tick said nothing at all.**

*Proof.* `assemble/1` overlaid only the two lists onto `drawn_inbox/0`, so all three of the watcher card's values stayed `Kati.Library.Sample`'s. Board 314 had already built the store for two of them — `Kati.Settings.Watcher.last_checked/0` and `cadence/0` — on the very page this card's cog opens, and screen 25 reads both. A reader who chose **Daily** on 25 was still told `every 6h` by 05. Separately, `tick/2` matched `_refused -> socket` and `handle_tap(:mark_all, _)` was an `Enum.each` over `write_tick/2`: both discarded the result, so a store that said no left the row in the list, the count unmoved, and the page saying no more than if the finger had missed the pill. That is the defect #39 names on screens 04 and 34; #82's wiring is how it reached a third screen without being named again.

*Fix.* Count `:followed` through the list the sections are already built from, read the mono line from the store screen 25 writes, and give 05 the `refusal/1` band 04 and 34 have.

*Fixed 8 September.* `watcher_line/0` composes `checked_line/2` and `cadence/0` — one store, two readers, so the two pages cannot disagree — and `assemble/1` overlays `watching: length(tracked)`, which makes *the banner and the list it is a banner FOR cannot disagree* structural rather than a promise. The frozen `last checked 18:02 · every 6h` is bought back by pattern in both sweeps rather than retired, because the line is still drawn and still says one of four things about the sweep beside one of three cadences. *Mark all* speaks the first refusal it meets and re-reads regardless, because ticks that DID land must leave the list; `tick/2` keeps a silent `nil` clause, because a tag naming no row is not a refused write.

### 142. 98 Your year, shared (Kati.Screens.YearShare) — `inert-control`

**`Share…` is dead ink under a badge reading `WHEN FILE SHARING LANDS` — a fence that had already landed.**

*Proof.* `actions/0` drew the label with no `on_tap`, which is the right way to draw a control with nowhere to go, over a claim that had stopped being true. `K-20 file-transport` is `ACTION_SEND` behind a FileProvider URI and `native/LEDGER.md` has carried the row since `Kati.Backup` needed a way off the phone; `K-45 capture-screen` supplies the bytes; and `Kati.Native.Files.share/2` reaches the intent. All three existed and nothing joined them — `share/2` had **no caller anywhere in `lib/`**. `Kati.Screens.YearCardsStates` had already written the sentence down: *"`Kati.Screens.YearShare`'s line about there being no way to hand a file out has been overtaken by that fence."*

*Fix.* The join, and it is the join **Save image** already is: capture, then hand over.

*Fixed 8 September.* `Kati.Native.Files.share_screen/1` is `save_screen/1` with `ACTION_SEND` on the far end, and both refuse at the capture on a host. The badge is not reworded, it is not drawn — a marker naming no fence is a marker the next reader believes — so `when file sharing lands` is retired. Screens 99 and 103 borrow the tag rather than growing their own handler, because two boards of one screen that disagreed about what a control does would be two screens; 99 also gained the refusal slot it had been swallowing `Save image`'s errors into since save was wired. Persian 103's moduledoc said *Kati still has no share-sheet fence* and now says what actually changed.

### 143. 25 Release watcher — `inert-control`

**The banner's master switch and the four *How loudly* switches flip and are forgotten. The eight rows above them honestly carry a `not yet` pill, which makes these five read as the working ones.**

*Proof.* `handle_tap/2`'s `"banner"` clause was `%{w | banner: %{w.banner | on: not w.banner.on}}` and its `"loud_" <> i` clause was `flip(w.loudness, i)` — both socket-only, both lost on the pop. Nothing in `lib/` read either value. `Kati.App.on_start/0` called `Kati.Background.Periodic.ensure/1` unconditionally, so even a remembered *off* would have come back on the next cold start.

*Fix.* Wire the master switch to its one honest consumer and mark the four that have no sender.

*Fixed 8 September.* `Kati.Background.Periodic` IS the watcher's background check and nothing else — *"periodic work refreshes data, it does not deliver reminders"* — so the master switch has exactly one meaning: off cancels the worker, on enqueues it at the cadence below. `Kati.Settings.Watcher.watching?/0` stores it beside the cadence, `request/2` is the pure decision both `reschedule/1` and boot ask, and `Kati.BackgroundHandoffTest` greps `on_start`'s source for the cancel branch so boot cannot go back to enqueueing over the switch. **Check now** is untouched: a one-off run is an action, not a schedule.

The four *How loudly* rows are marked, and `@live_loudness` is empty on purpose: nothing in Kati sends a notification for a release. Two of them have a READER and are still marked — the unread dot is derived from a plan rather than stored, and quiet hours only shifts a `fire_at` in a plan nothing arms — so either would change a printed hour rather than keep the promise it makes. The `"loud_"` clause is deleted rather than left flipping an assign: a marked row draws no tag, and a clause that only moves a switch is the defect this closes. `design-briefs/D-64` is where the group's own board is asked for.

### 144. 19 Search (Kati.Search.Query) — `missing-feature`

**Cached episodes are never searched. Type the name of an episode TMDB wrote onto the device and you get nothing — though board 19 draws an episode hit and board 88's own tier-2 example is one.**

*Proof.* `Kati.Search.Query` had no reference to `Kati.Media.CachedEpisode` anywhere; `cached_for/2` read `Kati.Media.CachedTitle` only. Board 19 (`test/design/screens/19.html`) draws `Hollow Season · Episode · S2E5` as the second card in the Screen group's `gap:9px` stack — same markup, same 36×51 thumb, same seed as its parent — and board 88's ranking table gives `hollow → Hollow Season` as its tier-2 example, which IS that row. So the design has covered episodes since it was drawn; the read was missing and the field list was silent.

*Fix.* Read them, merge into `:titles` before the rank, and add one field to board 88's Screen scope.

*Fixed 8 September.* `episodes_for/2` matches on the episode's OWN NAME and merges into the Screen group before `Kati.Search.rank/1` — separately-ranked lists joined afterwards would put a substring-tier title above a prefix-tier episode, which is the reason books are concatenated the same way. The card carries the SERIES' poster, because a still is a 16:9 crop in a 36×51 portrait slot, and it opens the series, because screen 04 is where an episode lives and Kati has no episode page. Its tap tag is its own `source_id` and not the parent's id — both rows carrying one `accessibility_id` is what `onNodeWithTag` throws on, and board 19's own frame draws exactly that pair.

*One new field on the contract, nothing retired.* `episode titles` joins the Screen scope's list and is live the moment it is added, so `built?/1` draws it searched rather than struck. The body it matches against is `""` on purpose: an episode's `overview` is a field the board does not name, and searching one the contract never states is #74 pointing the other way. An episode a provider has not titled yet is dropped before the tier, because *TBA* is a string a provider invented rather than a name.

### 145. 10 Up next (Kati.Screens.UpNext) — `wrong-screen`

**The tune disc opened screen 03's filter sheet — a sheet that cannot sort a queue, and that shares one stored key with the shelf, so choosing `Title` on the Library silently reordered Up next.**

*Proof.* `up_next.ex:122-123` pushed `Kati.Screens.ShelfFilters`. That sheet's five orderings are `Recently added · Title · Your rating · Runtime · Release date` (`Kati.Library.ShelfFiltersSample.sort_options/0`), and a queue is ordered by none of them — *Up next* is a list of things part-watched, not a shelf. Both sheets wrote `Kati.Library.ShelfFilters`' single `Mob.State` key, so the two pages could not hold different answers: a `Title` sort picked on screen 03 reordered screen 10, and clearing the shelf's genre chips cleared whatever screen 10 was narrowed by. Board 167 has drawn the right sheet since the 5-September export and it sat unbuilt in `test/design/incoming/`.

*Fix.* Build 167, give it its own store, and point the disc at it.

*Fixed 8 September.* `Kati.Screens.UpNextFilters` is board 167 and `Kati.Library.UpNextFilters` is its store — a separate `Mob.State` key holding the four orderings board 167 actually draws. The chrome is **shared, not copied**: `sort_row/5`, `chip_row/2`, `facet_chip/4` and `count_card/2` are `Kati.Screens.ShelfFilters`' own functions called from the new screen, so the two sheets are pixel-identical by construction, which is the claim board 167 makes about itself.

Three rulings from board 168 are in the code rather than in a comment. **A sort persists and a filter lasts a session** — one key, with the filter half stamped with `run_id/0`, the millisecond this VM started, and dropped on read when it does not match; on Android the BEAM outlives an activity restart, so *session* means *this launch*, which the moduledoc states rather than leaves to be found. **Reset clears the chips and not the sort**, which is the one place this parts from 145, whose `Reset` clears both. **A newly chosen sort opens at its own natural direction** — `Airing soonest` and `Time left` open `:asc`, not 145's flat DESC, because a sort named *soonest* opening at DESC draws that word over the latest row.

The counts are screen 10's own arithmetic and not four independent numbers: `bands_of/3` answers a LIST because *Airing soon* is a subset of *Ready* rather than a fourth band, so the drawn `12 · 4 · 3` over fifteen rows is the same statement screen 10's header makes. `buckets/1` offers every bucket at its real count **including the zeroes** — a chip at `0` in 145's hairline grey says it would empty the page before it is tapped, where a chip that is not drawn says nothing at all. A row whose sort key cannot be read sorts LAST in both directions by splitting the list rather than by ordering a `{unknown?, value}` pair: whichever way round that flag is written, one of the two comparators puts the unknown group at the front.

Board 168's fourth state is drawn too. A filter that empties the page now says **Nothing matches** and names the chips that did it, with one control that clears them and leaves the sort — a different card from *Nothing queued*, because *nothing on the go* is a fact about the shelf and *nothing matches* is a fact about the chips, and the one thing that fixes each is different. 168 itself stays in `test/design/incoming/`: it is a state catalogue, four states in one frame, and cannot be compared literal-for-literal against a render.


### 146. 35 Show settings — `device-tested`

**Screen 35's writes were verified by a person walking the device once, and a walk somebody did once is not a thing that keeps being true.**

*Proof.* `Kati.Screens.Gallery`'s `@routed` carried the claim in as many words — *"Walked on the device: all three Status tiles and all four season-pass switches write, and the values survive a back-and-return"* — and nothing in the repository could re-check it. The host suite cannot: `Mob.ScreenCase`'s own moduledoc says these helpers *"cannot catch a node that renders wrong or behaves wrong on a real iOS/Android build"*, and the door to screen 35 is the `⋯` panel, `Kati.Components.Anchored` (K-18), which has no host-side existence at all.

*Fixed 8 September.* `android/app/src/androidTest/java/com/example/kati/SeriesSettingsTest.kt`, run on the Pixel_9a: **2 tests, both passing.** It walks the real journey — the dock's `+`, screen 06, *Add "…" by hand*, `kind_Series`, save, and the detail screen board 155 says a save lands on — then the `⋯` disc and *Show settings*. Every assertion is a row read out of `kati.db` through `KatiRule.scalar`, because screen 35 draws `Kati.Screens.SeriesSettings.Sample` over a show it does not have and the two faces are otherwise identical.

The four season-pass switches are asserted **one column at a time**, and that is the point of the second test rather than a flourish: the tap tag is built from the column name (`"pass_" <> Atom.to_string(field)`) and `change_for/2` looks it up in `@pass_columns`, so a typo in one of the four is a tag matching no column, `change_for/2` answering `:error`, and `write/2` returning the socket unchanged — silently. Both tests then pop back to screen 04 and re-enter, because `write/2` assigns the updated struct into the socket and a screen that never wrote looks identical until that socket is thrown away.

*Two things it deliberately does not do.* It keys every query on `id`, read back by `source_id` after the save, rather than on whichever series tile is first on the shelf: step 5 of the first run shelves a series of its own, so the first tile is usually not the row under test — an assertion about the wrong show that looks exactly right. And it does not pin the by-hand form's default status; the first version asserted *Watching* and the device answered `not_started`, so it now checks only that the row is not already the value the tap is about to write.

### 147. 163 / 166 Add your first title — `lies-to-user`

**Step 5 of the first run opened with one of the board's four invented titles already selected, so pressing *Finish setup* without choosing put a film the reader had never heard of on their shelf — and made screen 139 unreachable by the path most people walk.**

*Proof.* `lib/kati/screens/onboarding_first_title.ex:37` was `Mob.Socket.assign(socket, :picked, "The Long Hollow")`, and its Persian mirror `onboarding_first_title_fa.ex:39` was `assign(socket, :picked, "گودال بلند")`. `@suggestions` is `["The Long Hollow", "Ashfall", "Marram", "Nightbirds"]` — the board's four, invented. `handle_tap(:finish, …)` calls `shelve(socket.assigns.picked)`, which caches a `Kati.Media.CachedTitle` and creates a `Kati.Media.TrackedTitle`. So the default was not a drawing state, it was a write.

This is MOVIES-AND-TV.md #91's own sentence about a different screen — *nine invented films on a phone that has tracked nothing is the app lying about the one thing it exists to hold* — and it had been shipping since D-33 split the first run into five steps.

It came from reading board 163 too literally: the board draws `The Long Hollow` **ticked**, which is the drawing showing what a chosen tile looks like, and it was built as an opening value. The board's own footnote is the tell — *"Skipping lands on empty Home — 139. Its skip is the only route to 139"* — and Finish setup was quietly a second route away from it.

*How it surfaced.* Six device tests, all failing on the same line: `could not find any node that satisfies: (TestTag = 'add_title')`. `add_title` is on `Kati.Screens.Library.empty_state/0` and is drawn only while the shelf is empty, and after a first run the shelf was not. `FirstRunTest.assertNothingInvented/1` is the assertion written for exactly this defect and it was one screen too late to catch it — the shelf had a real row on it by then, holding a name the reader never typed.

*Fixed 8 September.* `load/1` assigns `nil` in both scripts. `shelve/1`'s `nil` clause was already correct and simply could not be reached, so **Finish setup** with nothing chosen now finishes and writes nothing — which is what the board's footnote describes Skip doing, minus the wording. Board 163 and 166's `check` moves to `@unreachable_symbols` and `@moment_symbols`, and 166 takes a `@floor_allowance` of 1 because the glyph is a `Text` node like any other. Two entries LEAVE `@inert_taps`: `:pick_The_Long_Hollow` and `:pick_1` were listed as the resting member of their family, and with nothing pre-selected they are live.

`Kati.FirstRunTest` now taps a tile before asserting the shelf, in both locales, and carries a new test for the half that had never been true: *finishing without choosing shelves nothing at all*.


### 148. The back chevron is not mirrored — `cannot-work`

**Every pushed screen in Persian drew a back arrow pointing at the edge the reader did not come from, because a container flips under RTL and a glyph does not.**

*Proof.* `Kati.Screens.Pushed.back_pill/1` drew `Kati.UI.symbol("arrow_back_ios_new", size: 17)`, and five screens draw their own pill over their own artwork with the same literal: `series.ex:853` (04), `film.ex:672` (08), `series_meta.ex:597` (14), `search.ex:502` (19) and `meal.ex:561`. Four of the five are Movies & Series.

`MainActivity` provides `LocalLayoutDirection` from the root node (`K-12 rtl-root`), which mirrors every **container** under it. An arrow is not a container: `arrow_back_ios_new` is a codepoint in a font (`Kati.Icons:19`), so it is drawn exactly as it was designed whatever the direction is. The Persian mirrors have always known this — `Kati.Screens.Fa.pushed_frame/2` draws `arrow_forward_ios`, and board 156's caption pins it by name: *"The back chevron is `arrow_forward_ios`. Back is the way the reader came from, and in Persian that is the right edge — the commonest RTL bug there is."* `Kati.Screens.BookDetailFa` records the same trap for screen 69.

What was missing is that the **shared** frame did not, so every English page opened while the app is in Persian got the RTL layout and the LTR arrow. That is live today — `Kati.Locale` is an in-app setting and `Pushed` already reads it for the direction — and after [#103](https://github.com/mishka-group/kati/issues/103) it would be every pushed page in the app.

*Fixed 8 September.* `Kati.Screens.Pushed.back_glyph/0` answers from `Kati.Locale`, and all six call sites read it. Not `rotate={180}` on the Box — the way `Kati.Screens.ShelfFilters.direction_pill/1` turns its one sort arrow — because that idiom exists for a glyph with no mirrored twin, and this one has a real twin Kati already ships. Turning a chevron instead of swapping it puts its optical weight on the wrong side.

`Kati.LocaleFaceTest` renders all six in both locales and asserts each draws the leading-edge chevron and not the other one.


# Pages a user cannot reach except through Settings

Each needs a real door before it can be called finished, and then it comes out of the gallery.

- adding: 155 Add by hand — states (Kati.Screens.AddByHandStates) — correctly gallery-only; it is a reference sheet, not a place in the app, and app_reachability_test.exs:106 carries it on the inventory with that reason. It is the SPEC for 154 (Film default, blank Year, and 'Add to library goes to the new title's detail screen'), so fix 154 against it and then delete it from Settings.
- adding: 157 Add by hand — dark (Kati.Screens.AddByHandDark) — gallery-only, and on the inventory as 'the same page in another colourway, reached by having dark on rather than by navigating'. It SHOULD be reachable by turning dark mode on in Settings > Appearance and then opening 154 the normal way (Home > + > Add it by hand); it is a separate module only because Kati.Shell does not yet carry the mode. Until that lands it is also actively harmful (scenarios 30 and 31), so it should come out of Settings whether or not the mode work happens.
- shelf: 147 Selection & filters at 235% (Kati.Screens.ShelfLarge) — should be reachable from 146 Shelf selection mode, or not at all: it is a specimen of 146 at 235% and its own back pill says Library. Its real content belongs inside 146's own large-text behaviour.
- shelf: 152 Anime — a type, not a section (Kati.Screens.AnimeFilter) — back pill says Settings and no Settings row opens it. It argues for a per-title anime override; it should be reachable from Settings → Data sources / Auto-detect once TrackedTitle has the override column, or its rule should be folded into the Library's filter sheet (145) and the screen deleted.
- shelf: 87 Search — typing (Kati.Screens.SearchTyping) — back pill says Home. A reference sheet of the three states between 86 and 19; nothing should route to it. Keep only `nothing_yet/0`, which 86 and 19 both render.
- shelf: 89 Search — result states (Kati.Screens.SearchResultStates) — back pill says Settings and no Settings row opens it. Its third band (nothing in the lit scope, matches elsewhere) is a state screen 19 genuinely needs and does not have; move that band into 19's `state_or_groups/3` and the sheet stops being needed. Keep `nothing/2`, which 19 already renders.
- shelf: 91 Search at 235% (Kati.Screens.SearchLarge) — back pill says Home. A specimen documenting a live defect on 19 and 86 (clipped hit rows, horizontally scrolled scope chips). Apply its answer to 19 and 86; nothing should route to the sheet.
- film: 148 Drop, DNF & abandon (Kati.Screens.DropStates) — nothing in lib/ pushes it; grep finds it only in gallery.ex:188. It should hang off Settings, beside screen 27's states sheet, in a reference / 'how Kati thinks' group — its own moduledoc already claims it is 'pushed under Settings' and settings.ex has no such row.
- series: 143 Episode rows — the rating column (Kati.Screens.EpisodeRatings) — should not need a route at all: its rating column belongs on screen 04's episode rows (Series.episode/1), after which the board can be deleted from Settings. If it is kept as a specimen sheet, the only sane door is 04's ⋯ menu.
- series: 153 Numbering — inherited and overridden (Kati.Screens.NumberingScheme) — should be reachable from screen 34, beside the Aired/Absolute/DVD strip it explains (a note row or an info glyph under the strip), or from screen 35's 'This show' group.
- series: 14 Series metadata, 34 Season, 35 Series settings and 144 Rate an episode are listed as gallery-only in routes.txt, but the code routes all four from screen 04's ⋯ menu (series.ex:1135-1170); the sweep pressed :toggle_menu, got no push back, and never re-rendered to find the rows. Verify on device — the panel is Kati.Components.Anchored, K-18, its first use in Kati — and if it does not draw, all four are genuinely gallery-only and should be reached from 04's ⋯. In Persian they are gallery-only regardless: SeriesFa's identical ⋯ disc carries no on_tap (series_fa.ex:475-480).
- next: 95 My services — states (Kati.Screens.MyServicesStates) — a reference sheet by design (test/kati/app_reachability_test.exs:94 allows it no route). It should not become a page: its five states — region set with no services, a search that missed, the provider list down, region changed with Undo, a service removed — are five things screen 92 must be able to BE. Delete the board once 92 draws them.
- next: 96 Nothing set up — knock-on (Kati.Screens.NothingSetUpKnockOn) — reference sheet, allowed no route at app_reachability_test.exs:140. Its four bands belong inside screens 08 (Where to watch), 11 (Discover), 13 (What fits?) and 23 (Subscriptions) as their real empty states. Blocked on 92's fixture fallback becoming conditional — the file says so itself.
- next: 05 New releases (Kati.Screens.Inbox) — not on any allow-list and not meant to be gallery-only, but on a real English device it is: its one door is Home's `New this week` hero, which is omitted unless a followed title has an unticked episode from the last seven days (home.ex:641, :331). It should be reachable from Settings alongside `Release watcher`, and/or from `Kati.Screens.InboxNotifications`, which already pushes 25 from the same page.
- next: 13 What fits? is listed under NOT REACHED in routes.txt and that is wrong — it IS reachable: Library dock → the `⋯` disc top-right → `What fits?` (library.ex:588-596, :1237). The BFS missed it because the overflow menu is not drawn at rest, so its tap was never on screen to press. Screens 34, 35, 143, 144, 146, 147, 152 and 153 are likely behind the same kind of closed menu and worth re-checking before they are called unrouted.
- inout: 142 Import — source states (Kati.Screens.ImportStates) — should be reached from 141 when the file's columns do not match the tapped tile (wrong guess / unrecognised / partial columns), i.e. as the failure branch of Kati.Screens.ImportRecognised.load/1 once a real reader inspects the chosen file. Today nothing reads a file, so the state cannot arise.
- inout: 101 Year cards — states (Kati.Screens.YearCardsStates) — should be reached from 98 (Kati.Screens.YearShare): band 3 (private title) is what the 'Hide titles I marked private' switch should produce, and band 5 (save not supported) is what 'Save image' should show instead of pushing screen 100. Band 1 is already honoured live on screen 07's empty state.
- inout: 102 Your year, shared — dark (Kati.Screens.YearShareDark) — should not be a separate screen at all: Kati.Theme.Palette.mode/0 already makes screen 98 render dark on a dark device. Its two extra card faces (the contribution field and the genre bars) belong on 98's own preview, reached from Stats -> share disc.
