<div align="center">

<img src="docs/media/icon.png" width="104" alt="Kati">

# Kati

**One warm surface for everything you keep track of.**

Films and series, books, music, health, meals, money and habits —
with a real calendar as the spine, not a widget bolted on the side.

**🚧 Under active development.** Not released yet, and not yet stable.

</div>

<br>

![Home, a film, and your library](docs/media/screens.png)

<br>

## What it does

🏠 &nbsp;**Four places, and they never move** — Home, Calendar, Library, Stats. Sections add shelves
and feeds, never tabs. Turn one off and it leaves everywhere at once.

🎬 &nbsp;**A title is not a row in a list** — what you rated it, how many times you have seen it,
where to watch it, and the note you wrote on the way home.

📅 &nbsp;**A calendar that is actually a calendar** — CalDAV sync, conflicts handled. Episodes,
meals, doses and renewals all land on it.

🔍 &nbsp;**One search for everything** — titles, calendar entries and your own notes, and it tells
you which is which.

🌙 &nbsp;**Persian throughout** — right to left, Shamsi dates, Persian numerals, the week starting
Saturday. Not a translation layer.

🔒 &nbsp;**It stays yours** — no account, no server. One file on your phone, backed up wherever you
like and sealed with a passphrase if you want.

📥 &nbsp;**Bring your history** — Goodreads, StoryGraph, Letterboxd, Trakt, MyAnimeList, AniList.
Name your tracker and Kati does the mapping.

## Built with

Kati is an Elixir app. The BEAM runs **on the device** and the interface is real native Jetpack
Compose — not a webview, not a bridge to JavaScript.

| | |
|---|---|
| **[Mob](https://hex.pm/packages/mob)** | Elixir on the phone, rendering native Compose. Screens are `Mob.Screen` modules and the `~MOB` sigil is the markup. |
| **[Mishka Chelekom](https://mishka.tools/chelekom)** | The component library the interface is assembled from — pills, chips, sheets, list rows, theme icons. |
| **[Ash](https://ash-hq.org)** | The domain layer, over SQLite on the device. |

<br>

<div align="center">

Built and vibe coded by [Shahryar Tavakkoli](https://github.com/shahryarjb) · part of
[Mishka Group](https://github.com/mishka-group)

</div>
