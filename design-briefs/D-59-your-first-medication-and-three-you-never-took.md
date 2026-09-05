# Your first medication, and three you never took

> **One board — a state of screen 112** · ticket `D-59`

Found on a Pixel 9a, on the first device on which anybody could add a
medication. Board 188 shipped, the sheet saved, the page came back — and this
is what it showed:

* **TODAY** — Levothyroxine 08:00 ✓, Vitamin D 13:00 ✓, Iron 14:00 ✗ MISSED,
  Magnesium 21:00 ✓. The drawing's four. **None of them is yours.**
* **SCHEDULES** — one row. Levothyroxine, 50 mcg · every morning, 08:00. The
  one you just typed.
* **The header** — `SUNDAY 16 AUGUST · 4 DOSES`.

One page saying, in three places at once, that you take four medications and
that you take one. A person's first act of owning a prescription is answered
with three prescriptions they have never heard of, one of them marked missed.

## Why the code does that, and why the code is not wrong

Screen 112 has **two gates and they ask different questions**.
`Kati.Screens.Medication.schedules/0` asks whether any `Kati.Health.Medication`
is stored; `doses/0` and `subtitle/1` ask whether any `Kati.Health.Dose` is.
Until 5 September neither table could be written to outside a backup restore,
so the two questions had the same answer on every device that has ever existed
and the split was invisible.

Board 188 changed the first answer and not the second, because **nothing in
`lib/` creates a `Kati.Health.Dose`** — the resource has `create: :*` and no
caller, which is exactly the sentence `D-43` wrote about `Medication` before it
was fixed. So a medication with `times: ["08:00"]` produces no dose row for
today, and `doses/0` keeps falling back.

The app's own doctrine is written into `Kati.ScreenEmptyDatabaseTest` at screen
20's entry: *either every value on the page is this reader's or every value is
the drawing's.* Screen 112 is now the one page that breaks it, and it breaks it
on the first medication rather than the hundredth.

## Why this is a brief and not a patch

The one-line fix — gate the whole page on `Medication` — is written and was not
committed, because of what it leaves behind. With the gate moved, TODAY draws
its eyebrow, no rows, and the **Taken / Skip** pair over nothing: `D-58`'s
defect exactly, plus two buttons that act on no dose. Nothing in the 166 words
the state *you have medications and nothing is due today*, and it is a state a
real person reaches every single day — a Mon/Wed/Fri iron tablet gives it to
them four days a week.

So the shape of the answer is a design decision and not a refactor:

**Where do today's doses come from?** Two answers, and the board picks one.

  1. **Derived.** Today's list is composed from each medication's `times`,
     the way `Kati.Notifications.Sources.Health` already arms the reminder —
     that source reads `times` and nothing else, so `times` is already this
     app's answer to *what is due today*. A dose row is then written the
     first time someone marks one, which is the only moment there is anything
     to record. This needs no new copy for the common day and gives the person
     who just typed a medication a row at 08:00 with their own name on it.
  2. **Stored.** Dose rows are materialised on a day boundary and TODAY is a
     straight read. Truer to the resource as drawn, and it needs the empty
     state below, plus a decision about what happens on a device that was off
     at midnight.

The recommendation is **derived**, on the grounds that the reminder already
works that way and two sources for one question is how a page comes to
disagree with itself — which is the defect being reported.

## What to draw

| Board | What it is |
|---|---|
| **new** | Screen 112 with medications stored and **nothing due today** |

Screen 190 is the *empty* frame — no medications at all — and its words are
about starting. This is the other one, and its words are about a quiet day: the
Schedules group is full, the reminder card is real, and TODAY has a sentence
instead of four rows. `Kati.Screens.Medication.actions/1` must be absent rather
than inert, for the reason screen 190's caption gives about its own two
destinations: a control that cannot act is worse than no control.

If **derived** is chosen, this board is still wanted and is a rarer state — the
day every one of your medications is a Mon/Wed/Fri that is not today.

## Acceptance

  * Screen 112 answers one question about whether it is drawing the user's
    data, and `Kati.ScreenEmptyDatabaseTest`'s screen-20 rule holds for it:
    the header count, TODAY and SCHEDULES are all the reader's or all the
    drawing's, never one of each.
  * A medication added on screen 188 appears on the same page it was added
    from, without a fixture beside it.
  * `Kati.Health.Dose` has a writer in `lib/`, whichever answer is taken.
