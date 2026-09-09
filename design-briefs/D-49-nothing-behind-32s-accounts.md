# Board 32's accounts group is a picture

> **Mixed — two new artboards, one states sheet, and one edit to 32** · ticket `D-49`

Someone opens Settings › Calendars because one of their calendars has stopped arriving.
Board 32 tells them exactly which one: the third row reads **CalDAV · fastmail · last sync
4h ago** with a red-amber **Stale** pill beside it. Then nothing happens. The row has no
chevron and no destination; `Kati.Screens.Calendars.account_row/1` builds it with no
`:on_tap` and there is no `handle_tap/2` in that file at all, so there is nowhere to go and
nothing to press. The dashed **Add an account** slot underneath is in the same condition,
and worse: it is the entry to a flow no artboard in 01–166 draws — no provider choice, no
CalDAV form, no OAuth handoff — and nothing anywhere in `lib/` has ever created a
`Kati.Calendars.Account` except `Kati.Seeds`. So the three accounts a user sees are the
seeder's three, the row that would add a fourth does nothing, and the one row the board
went out of its way to draw in a state whose *entire point* is that the user must act has
nothing to act on. `Kati.UI.SettingsList.row/4` states the rule this ticket exists to
restore, in its own comment: *"A row that names a screen should open it. Without a tap the
whole settings tree is a picture of a settings tree."*

## Why this is one brief and not two

Add, repair and remove are one account lifecycle, and they share every decision worth
making. Which providers Kati offers at all decides what the add flow lists *and* what the
repair path re-asks for. Whether the OAuth handoff and the CalDAV host/username/password
form are one board or two decides whether *Sign in again* on a stale account re-enters the
same board or a second one. What a credential that fails looks like is the same drawing
whether it failed on first connect or four hours ago. And what removal does to the mirrored
events is the question that decides whether the add flow can promise anything at all.
Splitting them sends the same owner to the same card list twice and lets the repair path be
drawn without the form it repairs.

Most of the parts already exist on **board 80**, which is why this is smaller than it
sounds: 80 draws a Connect row per provider, an expanded pairing panel with its code and
expiry, the same provider connected with a **Disconnect** pill, and the token-storage
footnote. **81** draws the verifying field and the bad-credential field. The genuinely new
half is calendar-specific and is the one thing 80's own copy explicitly excludes — a form
that takes a password.

## What to draw

| # | Artboard or edit | What it carries |
|---|---|---|
| **200** | **NEW — Add an account** | Pushed from 32's dashed slot. The provider list in 80's *Connect an account* manner, and the expanded CalDAV panel underneath it: server, username, app-specific password, and the sentence that says where the password goes. |
| **201** | **NEW — A calendar account** | Pushed from an account row on 32. Drawn as **the stale fastmail account**, because that is the row 32 draws and the one with something to do. Identity, what stale means, *Sign in again*, the calendars this account brings, and Remove. |
| **202** | **NEW — Account states** | A reference sheet in 27's manner and 81's rhythm: verifying, refused credential, unreachable server, the two `state` values nothing has ever drawn, the no-secure-store refusal, the remove confirmation and its undo, and the empty accounts group. |
| **32** | **edit** | A chevron on each of the three account rows, since they now lead somewhere. Nothing else on the board changes. |

If the CalDAV form has to be its own pushed board rather than an expanded panel on 200 —
see *Left open* — it takes the next free number after 202 and 200 keeps the provider list.

## 200 — Add an account, element by element

Chrome and heading:

| Element | Purpose | Glyph |
|---|---|---|
| Back pill `‹ Calendars` | 200 is pushed from 32; 32's own pill still reads `‹ Settings` | `arrow_back_ios_new` |
| Title *Add an account* + a mono subtitle | 32's title recipe — `SettingsList.title/4` at `:meta_tight`, DM Mono 11px `#A9A29A` under a 28px/700 heading | — |

The provider list — one card, one row per provider, 80's *Connect an account* group exactly:

| Element | Purpose | Glyph |
|---|---|---|
| **iCloud** — *Apple ID · app-specific password* | The most common CalDAV principal, and the one 32's first row is. `Kati.Calendars.Account.provider` stores `:caldav` for it | `cloud` |
| **CalDAV** — *Fastmail, Nextcloud, any CalDAV server* | The generic principal; 32's third row | `dns` |
| **Google** — *Signs in with Google* | `provider` accepts `:google`, and **there is no adapter behind it** (see *What it must NOT do*). Draw it, grey it, or leave it out — but say which, on the board | `mail` |
| **Microsoft** — `:graph` | Same position as Google. The enum has the value; nothing implements it | `mail` |
| A **Connect** pill on each row | 80's pill: height 30, radius 15, `#EFECE7`, 11.5px/600. Not a chevron — the row expands in place rather than pushing | — |

The expanded CalDAV panel — 80's expanded ListenBrainz card, with fields instead of a code:

| Element | Purpose | Glyph |
|---|---|---|
| Panel header: 40pt tile, name, *Connecting* sub-line, and the collapse affordance | 80's expanded row, node for node | `expand_more` |
| One explanatory sentence, 12.5px `#5C574F` | 80's is *"ListenBrainz needs your own token because it writes to your account, not Kati's."* The CalDAV one has to say why a password is being asked for at all when 80 promises it never will | — |
| **Server address** field | The `url` half of the credential JSON. Whether it takes a full collection URL or an email that Kati discovers from is *Left open* — the adapter does a `PROPFIND` on the calendar home either way | `public` |
| **Username** field | The `username` half. Usually the same address, sometimes not | `person` |
| **App-specific password** field, masked | The `password` half. **The label is not negotiable** — `Kati.SecureStore` requires these exact words, and the field must carry the line saying it can be revoked at the provider without changing the account password | `lock` |
| A reveal control on the password field | `Kati.Icons`'s inlined map has `visibility_off` and **not** `visibility`, so a two-state eye needs a glyph the shipped font subset cannot supply today. Draw it as a text pill (*Show* / *Hide*) or accept a new symbol and say so on the board | `visibility_off` |
| A *where do I get one* line, per provider | iCloud issues these at appleid.apple.com; Fastmail in its own settings. Latin URLs in DM Mono, the way 80 sets `listenbrainz.org/link` | `help` |
| **Connect** — the committing control | One per screen. Either a 54pt primary button at the foot or a 38pt ink header pill opposite the back pill, the way board 118 does it. Pick one and note it | — |
| Cream card — *where this password goes* | `#FBF1DE`, 80's storage-note recipe. The sentence is **derived, not written**: `Kati.SecureStore.status/0` answers `{:ok, :hardware}`, `{:ok, :software}` or `{:error, …}`, and each needs its own sentence. Draw the hardware one and list the other two | `shield` |
| Bordered footnote — *the calendars already on this phone* | The device's own calendars are not connected here; they arrive with the Android permission and land with **no account row at all** (`Kati.Calendars.DeviceImport` never sets `account_id`). Without this line, a user who granted the permission will come here looking for a row that will never exist | `phone_iphone` |

## 201 — A calendar account, element by element

| Element | Purpose | Glyph |
|---|---|---|
| Back pill `‹ Calendars` | — | `arrow_back_ios_new` |
| Identity header: 40pt tile, `display_name`, `account_name` underneath, state pill on the trailing edge | 32's own three fields — *CalDAV*, *fastmail*, **Stale** — at 80's 40pt tile size rather than 32's 30pt, because this is the subject of the screen rather than a row in a list | `dns` |
| Cream card — **what stale means** | `Kati.Settings.CalendarsSample`: *"A stale account is not an error — the calendar still draws from its last sync."* The card must say the events are still there and still correct as of four hours ago, or the screen will read as data loss | `history` |
| **Sign in again** — the primary action | The whole reason this board exists. Re-enters 200's CalDAV panel with `url` and `username` filled and the password field empty. A stale CalDAV account is almost always a revoked app password | `lock` |
| Eyebrow *Calendars from this account* | — | — |
| Calendar rows: 12pt swatch, `display_name`, and a marker on the read-only ones | 32's middle group's swatch, and only what a column holds. `read_only` is a real column and defaults to true for everything the device provider imports | `lock` on the read-only marker |
| Eyebrow *Details* | Quiet eyebrow — grey rule, not orange | — |
| **Last sync** — a stated fact, no chevron | `last_sync_at`. DM Mono | `schedule` |
| **Server** — the collection URL, with a copy affordance | Latin, DM Mono, truncated with an ellipsis the way 81 truncates a token | `content_copy` |
| **Sync window** — stated, **never editable here** | `sync_window_from` / `sync_window_to`. Its own column comment says why: *"Frozen at connect time: Google invalidates a syncToken if timeMin changes between requests, so the window cannot drift with the UI."* A chevron on this row would be a promise the engine cannot keep | `calendar_month` |
| **Remove this account** — red-wash tile, red label | 80's *Disconnect everything and wipe tokens* row, which is the same shape: a `rgba(180,85,60,.1)` 40pt tile, a `#B4553C` label, a chevron into an inline confirmation | `delete_forever` |
| Bordered footnote — what removal keeps | The one sentence that has to be right: what happens to this account's calendars and to the events already mirrored from them. See *Left open* — the schema permits either answer and the drawing has to pick | `shield` |

## 202 — Account states, band by band

81 is the model: an eyebrow per state, the card underneath, and a bordered footnote at the
foot explaining the two judgement calls.

| Band | What it draws | Glyph |
|---|---|---|
| **Verifying** | 81's *checking* field — the shimmer bar and the DM Mono `checking` label. Connecting is a `PROPFIND` over the network and can take seconds | — |
| **Refused** | 81's bad-key field — `#EFECE7` with an inset `1.5px #B4553C` ring — and a sentence that names the **likely mistake** rather than an HTTP status, the way 81's does. Here the likely mistake is an account password where an app-specific password was asked for | `error` |
| **Server unreachable** | Wrong host, no DNS, a TLS refusal. Distinct from *refused*: one is the credential, the other is the address | `cloud_off` |
| **All four `state` values, side by side** | `Kati.Calendars.Account.state` is `[:live, :stale, :error, :disconnected]`. Board 32 draws **two** of them. `:error` and `:disconnected` have never been drawn anywhere in the app and have no colour, no label and no pill | `check_circle` / `error` / `block` |
| **No secure store** | The refusal that cannot be worked around. `Kati.SecureStore.put/2` answers `{:error, :no_native_store}` where the native half is not bound, and there is **no fallback**. 200 must refuse *before* asking for a password, not after taking one | `block` |
| **Software-backed key** | `{:ok, :software}` — the milder note, which the store's own doc says is *"worth surfacing"* | `shield` |
| **Remove — confirmation, then undo** | 81's inline confirmation, which leads with what is **not** destroyed, plus its ink toast with the orange **Undo**. Not a modal: 81 settles that for the whole app | `undo` |
| **No accounts at all** | 32's accounts group with only the dashed slot in it, and whatever line replaces *3 connected* under the title | `add` |

## States to draw

Kati's sweeps compare an empty state against a board, so an **undrawn empty state becomes
an untested one** — `Kati.ScreenEmptyDatabaseTest` asserts a screen's literals with nothing
stored, and a screen either falls back to its own drawing, has an empty board, or is
recorded as having neither.

- **Resting.** 200 with the provider list collapsed. 201 as the stale fastmail account.
- **Active.** 200 with the CalDAV panel expanded and the three fields filled — this is the
  state the board is actually for, exactly as 80 opens with ListenBrainz already expanded
  *"because the page exists to be told how to connect something"*.
- **Empty — two, and both are load-bearing.**
  1. **200's form untouched**: three empty fields and a Connect that must refuse. This is
     what a first-run connect looks like and it is not the same drawing as the filled one.
  2. **32 with no accounts at all.** `Kati.Screens.Calendars.load/1` assigns
     `Kati.Settings.CalendarsSample.accounts/0` unconditionally, so board 32 has never been
     drawn or rendered without its three rows. The moment an account can be added, zero
     accounts becomes reachable, and the group above the dashed slot has no picture —
     including the mono `3 connected` under the title, which cannot say *3*.
- **Error — three, all real rather than invented.** The credential the server refused; the
  server that could not be reached; and the connect that cannot even be attempted because
  the device has no secure store. The third is not an edge case: it is every build where
  the native half is not bound, and on iOS it is every build full stop.

## RTL — does this need a Persian mirror?

**One panel, not three boards.** Screen 32 has no Persian twin — there is no
`calendars_fa.ex` among the Persian screens in `lib/kati/screens/`, and the Persian
Settings root (62) names five destinations in `@destinations` (Backup, Sync, My services,
Data sources, Attribution) and Calendars is not one of them — so parity does not oblige a
Persian 200 or 201.

What *does* need drawing is **one Persian version of 200's CalDAV panel**, because it is
the first form in the app to put three Latin-only values inside an RTL page: a URL, a
username that is usually an email address, and a masked password. Board 82 has already
settled the treatment — it keeps `listenbrainz.org/link` and `ListenBrainz` in Latin DM
Mono inside `direction:rtl` and substitutes Persian digits only where the value is a number
— and this panel is the case where a build cannot be trusted to infer it. Draw the three
fields with their labels in Persian on the right and their values reading left-to-right,
and say which way the masking dots run.

What mirrors: the grid, the back pill's position, the row layout, the eyebrow's rule (which
moves to the right of its label). Dates go Shamsi and digits Persian, both in DM Mono so the
columns still align. What does **not** mirror: the Latin values above; and the **vertical
order never reverses** — provider list still above the panel, panel still above the storage
card. The back pill's glyph becomes `arrow_forward_ios` and chevrons become `chevron_left`.

## Dark colourway

**Not needed as separate boards, with one note.** Nothing on 200 or 201 is a surface the
dark palette has not already answered: card, paper tile, cream card, pill, red-wash tile and
ink toast on `#121110` / `#1E1D1B`, all of which resolve through `Kati.Theme.Palette` rather
than a literal. The one thing worth a written note rather than a drawing is **the masked
password field and 81's red inset ring** — `#B4553C` at `1.5px` inset over `#EFECE7` is a
light-mode pair, and 202 should say what the ring and the masking dots become on the dark
card so a build does not pick them itself.

## Reuse, do not invent

- **The provider list** is 80's *Connect an account* card: 40pt tile, name, supplies line,
  `Connect` pill. Not a new list style.
- **The expanded CalDAV panel** is 80's expanded ListenBrainz card — same 22px radius, same
  15pt padding, same header row with `expand_more`, same explanatory sentence. The cream
  block that holds the pairing code becomes the field group.
- **The verifying and refused fields** are 81's, unchanged: the shimmer bar with its DM Mono
  `checking`, and the inset `#B4553C` ring with the `error` glyph and a sentence naming the
  likely mistake.
- **The connected/disconnect row** is 80's, which is the shape 201's identity header wants.
- **The storage footnote** is 80's cream card, and its sentence is `Kati.Sources.token_note/0`'s
  sibling — derived from `Kati.SecureStore`, not written by hand.
- **The remove row** is 80's *Disconnect everything and wipe tokens*; **its confirmation and
  undo** are 81's, inline rather than modal.
- **Every row** is `Kati.UI.SettingsList.row/4` — 30×30 paper tile at 32's size or 40pt at
  80's, 13.5px/600 title, 11.5px `#8A8479` second line — and **a chevron means *leads
  elsewhere***. 201's *Last sync*, *Server* and *Sync window* rows must therefore not carry
  one.
- **The status pill** is `SettingsList.status_pill/3`: 24pt high, radius 12, a 5pt dot and a
  10.5px/600 label, both in the same colour. `:error` and `:disconnected` need colours from
  the palette, not two new hexes.
- **Prefer glyphs the app already ships.** `mix kati.gen.icons` builds the font subset from
  these boards, and `test/design/material_symbols.codepoints` *is not in the repo* — the map
  in `Kati.Icons` is inlined and nothing is blocked "until a new symbol is needed". Every
  glyph named in this brief except `visibility_off`'s missing partner is already in it.

## What it must NOT do

Every line here is a decision the codebase has already made.

**Do not call it "password" alone, and do not accept an account password.**
`Kati.SecureStore`'s secret inventory is a table with a verdict per credential:

> CalDAV app-specific password (iCloud, Fastmail) … **Accepted.** The UI must call it an
> app-specific password and say it can be revoked there; "password" alone is a lie by
> omission.
>
> CalDAV account password (self-hosted servers that offer nothing else) … **Rejected.**
> Kati does not ask for one and has nowhere to put it. Those servers are unsupported until
> they can issue an app password.

So the field's label carries the words *app-specific password*, the panel says where to
revoke it, and a server that can only issue an account password is out of scope — it does
not get an "advanced" escape hatch on this board.

**Do not copy board 80's promise onto 200.** 80's footnote says *"Kati never asks for a
password — only for tokens you can revoke from the provider's own site"*, and
`Kati.Sources` keeps it:

> A password, ever. Only tokens the user can revoke from the provider's own site. Screen 80
> prints that as a promise, and this module is where it is kept: there is no field anywhere
> in `Kati` that takes a provider password.

That sentence is true of the *media* providers and 200 is the exception to it. Reprinting it
above a password field would make the app call itself a liar on the one screen where it
matters. 200 needs its own sentence, and it is the app-specific-password one above.

**Do not draw a field for anything but url, username and password.**
`Kati.Sync.Adapter.CalDAV.Credentials`:

> The stored value is JSON — `{"url": ..., "username": ..., "password": ...}` — under the
> key in `Kati.Calendars.Account.credentials_ref`. The password never reaches a column, a
> log or a screen.

Three values. Not a port, not a "calendar path", not a display name the user types.

**Do not show `credentials_ref` anywhere, and do not draw it as a masked secret.**
`Kati.Calendars.Account`: *"`credentials_ref` is an opaque key into the keystore (#55) and
is **never a secret**."* It is a handle, it is meaningless to a person, and 201 must not
print it as reassurance.

**Do not draw a Google or Microsoft flow as if it works.** `provider` accepts `:google` and
`:graph`, and the adapter directory holds exactly three implementations — `caldav`,
`device_provider` and `inert`. There is no OAuth code in the app: `grep -ri oauth lib/`
returns two moduledoc lines and nothing executable. `Kati.Sources` also states the rule that
kept Trakt, Simkl and Last.fm off board 80 — *"A secret pasted into a client-side app is not
a secret"* — so a Google row that asks for a pasted client secret is not an option either.
The honest drawings are a row with a system browser handoff and no pasted secret, or a row
that says *not yet*. Pick one on the board.

**Do not offer the phone's own calendars as something to connect.** They arrive through the
Android calendar permission and `Kati.Calendars.DeviceImport`, which sets no `account_id` at
all, and the transport is read-only by design —
`Kati.Sync.Adapter.DeviceProvider`:

> `capabilities/1` reports `writable: false`, and it is not a placeholder. Writing to the
> provider needs `WRITE_CALENDAR`, which Kati does not request.

A *Connect the calendars on this phone* row would be a second, contradictory door onto a
permission, and the permission itself (screen 40's Allow pill, which flips a sample row and
raises no dialog) is a different gap with a different owner.

**Do not put per-account sync status, retry, or conflict resolution on 201.** That surface
is built, is reachable, and is owed its own drawing under #25/#54.
`Kati.Screens.Sync`:

> Every other file in `lib/kati/screens/` is built to a numbered frame under
> `test/design/screens/`. This one is not. Issue #25 asks for a drawing of the sync surface
> and it does not exist.

`Kati.SettingsDataRoutesTest` pins its door — 24's Data group, sync row — and the screen
already draws per-calendar status, the outbox with `Retry` on the entries that can be
retried, and the three conflict answers. 201 may state *last sync* as a fact and stop there.
A **Retry** pill on 201 would be a second, unowned copy of the one control that screen has
rules about: Retry is drawn on `:push_failed` and on nothing else, *"because trying again
cannot fix either of them"*.

**Do not make the sync window editable.** The column comment is the reason, quoted in the
element table above; a UI-driven window invalidates Google's `syncToken` between requests.

**Do not promise that removing an account deletes its events.** `Kati.Calendars.Event`:

> Rows are **never hard-deleted** once synced; `deleted_at` is a tombstone, kept 90 days and
> never collected while an outbox entry still references it.

And `Kati.Calendars.Calendar`'s `belongs_to :account` is `allow_nil?: true`, so the schema
permits calendars to survive their account. Whatever the copy says, it must be a sentence
the store can actually keep.

**Do not draw the provider's own colours on 201's calendar list.**
`Kati.Calendars.Calendar`:

> `colour_source` keeps the provider's own value **verbatim** … and is never rendered.
> `colour_token` is the Kati palette slot it maps to. Rendering foreign hex directly would
> break a locked design system.

**Do not derive the account glyph from `provider` on these boards without saying so.**
`Kati.Screens.Calendars` refuses to, and gives the reason:

> the drawing distinguishes iCloud (`cloud`), Google (`mail`) and Fastmail-over-CalDAV
> (`dns`), and `Kati.Calendars.Account.provider` collapses the first and third into one
> `:caldav` … What it needs is a service/brand slot on the account, or a `provider` value
> set that separates iCloud from a generic CalDAV principal.

`Kati.Screens.Sync` *does* derive it — `provider_icon(:caldav)` is `"dns"` — precisely
because it has no drawing to contradict. The moment 200 draws an iCloud row with `cloud` on
it, that row has to be storable, so the board should say which of the two fixes it assumes.

**Do not add a second visibility switch.** 32's middle group already owns
*which calendars show* (`Kati.Calendars.Calendar.visible`). If 201 lists this account's
calendars with switches, there are two controls for one column on two screens.

**Do not draw a second door for 32's `more_horiz`.** The header disc is its own undrawn gap
with its own candidates (refresh now, sync window, per-account removal). This ticket adds
rows and a chevron; it does not decide what the overflow contains.

## Left open — decide and note which way you went

- **One board or two.** Is the CalDAV form an expanded panel on 200, the way 80 expands
  ListenBrainz in place, or its own pushed board? A panel keeps the provider list visible
  and matches 80 exactly; a pushed board gives the form room and a back pill of its own. If
  it pushes, it takes the next free number and 200's rows get chevrons instead of Connect
  pills.
- **What the server field asks for.** A full collection URL, or an email address Kati
  discovers the principal from. Discovery is friendlier and can fail in a way a URL cannot;
  say which, because it changes the field's label, its keyboard and its error copy.
- **Google and Microsoft: drawn, greyed, or absent.** And if drawn, whether the handoff is a
  system browser or nothing at all until an adapter exists.
- **What Remove keeps.** Three defensible answers, all permitted by the schema: drop the
  calendars and tombstone their events; keep the calendars with no account, so the events
  stay and stop updating; or keep everything and only forget the credential. The footnote on
  201 is that decision written down, and it cannot be deferred to the build.
- **Whether the dashed slot gains a chevron.** It now pushes a screen, and the house rule is
  that a chevron means *leads elsewhere* — but `Kati.Screens.Calendars.add_tile/0` is drawn
  deliberately as *"a slot waiting to be filled rather than a button"*. Break the tie on the
  board rather than in code.
- **How the pill and the chevron share one trailing slot.** `SettingsList.trailing/1` wraps
  a single node with a 12pt leading spacer; a **Stale** pill *and* a chevron is two. Draw
  the spacing between them and to the row's right edge.
- **Colours for `:error` and `:disconnected`.** Live is the green wash, Stale is the
  red-amber wash. The other two need palette tokens and labels, and `:disconnected` may not
  want a pill at all — a greyed row may say it better.
- **Where the connect action lives** — a 54pt primary button at the foot, or a 38pt ink
  header pill opposite the back pill (118's pattern). One per screen either way.
- **What the mono line under 32's title says with no accounts.** *3 connected* has no zero
  form drawn anywhere.

## Acceptance — how we know the drawing is complete enough to build from

1. Every control on 200 and 201 has a destination or a stored column named on the board.
   `Kati.Calendars.Account` holds `provider`, `account_name`, `display_name`,
   `credentials_ref`, `state`, `last_sync_at` and the two window columns, and the credential
   JSON holds `url`, `username`, `password` — a field on the board outside that set is a
   defect in the drawing, not a migration to write.
2. The password field's label contains the words **app-specific password**, and the board
   carries the revocation sentence next to it.
3. Board 200 does **not** carry 80's *"Kati never asks for a password"* footnote, and
   carries its own storage sentence instead, with the `:hardware` / `:software` /
   no-store variants listed.
4. All four `state` values appear somewhere across 32 and 202, each with a colour and a
   label — `:error` and `:disconnected` included.
5. Three empty or refused states are drawn: 200 untouched, 32 with no accounts, and the
   connect that cannot proceed because there is no secure store.
6. 201 states *last sync* and draws **no Retry** — `grep` on the exported board should find
   no *Retry*, no outbox, and no conflict copy.
7. 201's removal footnote names what happens to the calendars **and** to the events, in one
   sentence the store can keep.
8. Board 32's export gains exactly three `chevron_right` glyphs and changes nothing else:
   the accounts card keeps its four rows, its three pills and its dashed slot.
9. The Persian CalDAV panel exists, its Latin values read left-to-right inside the mirrored
   grid, and its vertical order is unchanged from the LTR board.
10. Every glyph on the three boards is in `Kati.Icons`'s inlined map, or the board names the
    new symbol explicitly so someone can decide whether it is worth unblocking
    `mix kati.gen.icons` for.

## House style — Kati

Draw into `examples/ui_design/Kati.dc.html` as a new `IOSDevice` artboard, 402×874.

**Numbering.** The app runs **01–166** and nothing may be inserted below 167. This screen takes the
next free number.

**Type.** `Plus Jakarta Sans` for everything, `DM Mono` for data, counts, times, IDs and eyebrows,
`Vazirmatn` for Persian. Material Symbols Rounded for glyphs.

**Palette.**

| Token | Light | Meaning |
|---|---|---|
| paper | `#EFECE7` | page ground |
| card | `#FBFAF8` | any raised surface |
| cream | `#FBF1DE` | a card that carries a claim or a warning |
| ink | `#1A1917` | primary text, filled buttons |
| ink soft | `#5C574F` | body copy on a card |
| sub | `#8A8479` | a row's second line |
| tertiary | `#A9A29A` | mono captions, chevrons |
| accent | `#E8823C` | one thing per screen, never two |
| bronze | `#C98A3E` | money, meals, a gentle warning |
| green | `#4E9A73` | done, allowed |

Dark ground is `#121110`, card `#1E1D1B`, ink `#F5F2EE`.

**Recipes already in the app** — reuse rather than invent:

- **Pushed screen** — scroller `padding: 64px 21px 40px`, floating back pill (44pt, radius 22,
  `#FBFAF8`, `arrow_back_ios_new` + parent name), no dock, frame closes at 40.
- **Root screen** — same but the dock is drawn and the frame closes at 132.
- **Eyebrow** — a 13×2 rounded `#E8823C` rule, then DM Mono 10.5px, `.16em` tracking, uppercase,
  `#A0998F`. A quiet eyebrow swaps the rule to `#C4BDB3`.
- **Card** — `#FBFAF8`, radius 22, `box-shadow: 0 1px 2px rgba(26,25,23,.04), 0 12px 24px -18px rgba(26,25,23,.7)`.
- **List row** — 30×30 paper tile (radius 9, `#EFECE7`, glyph 17px `#5C574F`), 13.5px/600 title,
  11.5px `#8A8479` second line, trailing chevron `#C4BDB3`. A chevron means *leads elsewhere* —
  never use one for a row that does not push a screen.
- **Chip** — height 32, radius 16, padding-x 15, 12.5px/600. Selected is `#1A1917` on ink with
  `#FBFAF8` text.
- **Pill button** — height 30, radius 15, `#EFECE7`, 11.5px/600.
- **Primary button** — height 54, radius 27, ink fill, 14.5px/700 in `#FBFAF8`. **One per screen.**
- **Progress bar** — 2px, track `#C4BDB3`, fill `#E8823C`.

**RTL.** The container gets `dir="rtl"`; the whole grid mirrors. Artwork and star glyphs never
mirror. The back pill's glyph becomes `arrow_forward_ios`, chevrons become `chevron_left`. Dates go
Shamsi and digits Persian, both in DM Mono so columns still align.

**Dynamic Type.** Content grows with the system font size. Chrome whose size carries structure —
a seven-across week strip, a fixed-height pill — caps instead. A heading sharing a row with a
control yields to the control.
