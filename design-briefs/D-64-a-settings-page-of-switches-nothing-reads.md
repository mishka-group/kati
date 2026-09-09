# A settings page of switches nothing reads

> **One board, and a decision** · ticket `D-64`

Found closing MOVIES-AND-TV.md #67 and #77.

Screen 25 — *Release watcher*, reached from Home's bell and from Settings —
draws a master switch, six *Tell me about* switches, a four-way cadence and
four *How loudly* switches. Fifteen controls. Every one of them edits a single
socket assign and is forgotten the moment the screen is popped, and **nothing
anywhere in the app reads any of them**.

Screen 92 — *My services* — has the same shape in miniature: three availability
rules that are stored and consumed by nothing. `Hide titles I can't watch`
prints a sentence about removing titles from lists that no list removes
anything from.

The banner above them is fixed (`8b189f9` and this round's commit): `Watching 24
titles · 3 FOUND THIS WEEK` is now the reader's own `:followed` count and the
`out_now` list screen 05 builds from it. That is the only line on either page
that could be counted.

## Why persisting them would be worse

The obvious patch is a `Mob.State` key per switch, the way
`Kati.Library.ShelfFilters` now holds the shelf's sort. It is the wrong move
here, and the difference is worth stating: the shelf's sort has a **consumer** —
`Kati.Screens.Library.shelf/1` applies it on the next read. These switches have
none. Persisting them turns *forgotten on the pop* into *remembered, and still
inert*, which is a worse lie: the reader has evidence the setting took, and
nothing behind it ever did.

So the switches stay socket-local until either a consumer exists or the board
says they are not offered.

## What each would need

| Control | What would read it | Exists? |
|---|---|---|
| Cadence (Hourly / 6h / Daily / Manual) | `Kati.Background.Periodic.settings/1`'s `interval_minutes` | **yes** — this one is wireable today |
| New episodes | `Kati.Media.Release.alarm_at/3`, as a global gate over the per-title `notify_new_episodes` | **yes** |
| Premieres | a first-episode-of-a-season predicate over `Kati.Media.CachedEpisode` | derivable |
| Leaving soon | an offers resource — an availability window on a named service | **no** |
| People you follow | a person resource | **no**, and `Kati.Media.Watch.companions` says why not |
| Price drops | a price, and a wishlist | **no** |
| Renewals | a subscription with a renewal date | **no** — screen 23 is a fixture for the same reason |
| Push notifications | the notification permission and a sender | partly — `Kati.Screens.NotificationAccess` exists |
| Inbox badge | an unread count on `Kati.Screens.Inbox` | derivable |
| Quiet hours | a window, honoured by whatever sends | **no** sender |
| Weekly digest | a scheduled job and a digest | **no** |
| 92's three availability rules | the same offers resource *Leaving soon* needs | **no** |

Two are wireable today, two more are derivable, and seven need a resource that
does not exist.

## What to draw

| Board | What it is |
|---|---|
| **new** | Screen 25 on a device. The banner as built, the cadence and *New episodes* as live controls, and the rest — however the board decides to handle them: a *not yet* group, an absence, or a single honest line where nine switches are. The same decision then applies to 92's three rules. |

The board must also say what happens as each resource arrives, so a control can
be added back without redrawing the page. `D-63` asks the same of screen 14 and
for the same reason.

## Acceptance

* No control on screen 25 or 92 changes something the app then ignores.
* The banner stays counted; a device following nothing keeps the board's line.
* `Kati.ReleaseWatcherBannerTest`'s last block — *the rest of the page is still
  the drawing's* — either goes away because the controls became real, or
  becomes an assertion about the not-yet state. It must not stay as it is.
