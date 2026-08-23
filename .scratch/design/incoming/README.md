# Drawn, sliced, not yet built

Twenty-five artboards from the 23 August export, staged here rather than in
`screens/` because `Kati.ScreenDesignLiteralTest` treats every file in that
directory as the claim *a screen exists for this and renders every literal in
it*. Putting them there before the screens exist would make the suite red for
work that is queued rather than broken.

Move a file into `screens/` in the same commit that adds its screen module and
its `Kati.Screens.Gallery` entry.

| # | Board | Brief |
|---|---|---|
| 128 | Back up everything | `D-22` |
| 129 | Restore from a backup | `D-22` |
| 130 | Backup & restore — states (eight) | `D-22` |
| 131 | Back up everything — dark | `D-22` |
| 132 | بازگردانی — Restore, RTL | `D-22` |
| 133 | Back up & restore at 235% | `D-22` |
| 135 | Restore — first-run, chromeless | `D-23` |
| 136 | Loudness → the OS prompt | `D-23` |
| 137 | راه‌اندازی — onboarding, RTL | `D-23` |
| 138 | Onboarding at 235% | `D-23` |
| 139 | Home — nothing set up | `D-23` |
| 140 | Import — where are you coming from | `D-24` |
| 141 | Import — recognised | `D-24` |
| 142 | Import — source states | `D-24` |
| 143 | Episode rows — the rating column | `D-25` |
| 144 | Rate an episode — three states | `D-25` |
| 145 | Shelf filter sheet | `D-26` |
| 146 | Shelf — selection mode | `D-26` |
| 147 | Selection & filters at 235% | `D-26` |
| 148 | Drop, DNF & abandon — the states | `D-27` |
| 149 | Dropping — the sheet and after | `D-27` |
| 150 | Auto-detect — music mode | `D-28` |
| 151 | Notification access — four states | `D-28` |
| 152 | Anime — a type, not a section | `D-29` |
| 153 | Numbering — inherited and overridden | `D-29` |

**134 is missing on purpose, and is the one thing to go back to Claude Design
for.** `D-23`'s deliverable was *"First run — the flow map"*, and the export
carries its caption with no frame behind it. The brief said a map may take
whatever width it needs, so it is likely to have been skipped as not fitting
the 402×874 artboard convention rather than forgotten. It is the artboard that
answers *where does a killed app resume* and *which screen is step 1*, which is
the whole reason #11 was opened.

---

## Screen 40 was redrawn and the redraw is NOT staged

The export replaces screen 40 outright and the replacement contradicts a locked
decision, so `screens/40.html` is deliberately still the old board.

**What the redraw removes:**

> "This device — nothing leaves it unless you send it"
> "Everything is in one file on this phone."
> "**There is no account, no sign-in and no server.** Because there is no
> server, moving to a new phone means moving the file yourself."

**What it adds:** *Signed in with Apple* · *Relay address · no email shared* ·
*Manage devices* · *Sign out* · a device list (iPhone 16 Pro, iPad Air, Apple
TV) · and a privacy line reading *"Your library, notes and history live on your
devices and in your own iCloud."*

That is an account system, a sign-in and a sync fabric, in an app whose
identity is that it has none of the three. It is not a screen edit; it is a
product decision, and it is the owner's to make rather than the design tool's
or mine.

**It is also load-bearing elsewhere.** Three things already shipped rest on the
old sentence being true:

  * Screen 98 prints *"Kati has no server that could receive it"* as the
    reassurance under Save image.
  * #62's Play Data-safety answer is *nothing to declare*, which holds only
    because data is never transmitted off the device.
  * #66 and #65 were both closed partly on Kati being local-only.

Building the new 40 would make all three wrong on the same day. Decide the
product question first; the artboard follows it, not the other way round.
