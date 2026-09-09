# Your first medication, and three you never took

> **Two boards — states of screens 112 and 69** · ticket `D-59`

Two pages, one defect: a screen whose halves come from two sources, invisible
for as long as one of those sources could never have anything in it. `D-38`,
`D-39` and `D-43` gave three domains their first writers on 5 September, and
both pages started contradicting themselves the same afternoon.

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

## The same defect, on screen 69, found the same afternoon

`D-38` shipped board 176 and with it the only control in the app that creates a
`Kati.Books.Book`. A book was typed on a Pixel 9a — a title and nothing else,
status *Not started* — and screen 69 opened on it reading:

* the title, correctly, and the author line correctly absent;
* **در حال خواندن** in the status pill, and the *reading* chip lit;
* **۱۴۰۳ · ۳۸۰ صفحه** under it;
* a progress bar past half, and **ص. ۲۱۴ / ۳۸۰ · ۲۳ دقیقه در روز**;
* **۴٫۵** stars, four of them filled;
* a series line, a lending line and three content warnings.

One fact on that page is the reader's. `Kati.Screens.BookDetailFa.own/1` is
explicit about it — *a title, an author, a cover and an ISBN … everything else
on the page is Kati's copy* — and that was a fair reading of the situation when
it was written, because no Persian book could exist and the page was only ever
its own drawing. It is not a fair reading now: the page tells someone they are
214 pages into a book they added ten seconds ago as unstarted, and gives it a
rating they did not award.

**Most of this needs no design at all.** The shapers already exist:
`Kati.Screens.BooksFa.line/1` writes the Persian position line for a real book
and board 176's grid was drawing them correctly on the same screenshot;
`Kati.Books.SampleFa.statuses/0` is the status→word map the chips already use;
`Kati.Screens.Books.rail/2` is the fraction. So `own/1` should carry the
status, the selected status chip, the fraction, the position line, the rating
and the page count, and the chips should stop hard-coding `:reading` and
`:paperback`.

**Three parts of it do need a board**, and they are why this is written here
rather than patched:

  1. **The year.** The fixture prints `۱۴۰۳`, which is the Shamsi year for
     2024. Whether a book *published* in 2024 is a ۱۴۰۳ book is a question
     about what the number means, not about digits, and `D-55` is where the
     Persian-calendar decisions live.
  2. **The series, the lending and the warnings.** Three cards with nothing
     to put in them for a hand-typed book. Blanked, they are three eyebrows
     over nothing — `D-58` again.
  3. **The rating card with no rating.** Screen 66 draws a dash; 69's card is
     drawn only in its filled state.

## Acceptance

  * Screen 112 answers one question about whether it is drawing the user's
    data, and `Kati.ScreenEmptyDatabaseTest`'s screen-20 rule holds for it:
    the header count, TODAY and SCHEDULES are all the reader's or all the
    drawing's, never one of each.
  * A medication added on screen 188 appears on the same page it was added
    from, without a fixture beside it.
  * `Kati.Health.Dose` has a writer in `lib/`, whichever answer is taken.
  * Screen 69 states no fact about a book that the book does not carry. A
    hand-typed title opens a page that is empty where the app knows nothing,
    never a page filled in with somebody else's reading.
