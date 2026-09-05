# A Persian screen cannot say a save failed

> **Copy — one sentence, and a rule** · ticket `D-60`

Found while closing `D-59` on a device. Every Persian screen in the app that can
write sets `:save_error` on its socket and then draws nothing.

`Kati.Screens.LogProgressFa` sets it (`log_progress_fa.ex:656`) and renders it
nowhere. `Kati.Screens.HealthFa` hands its dose taps to
`Kati.Screens.Medication.handle_tap/2`, which sets it and hands the socket back
(`medication.ex`, `record/3`), and 115's `content/1` reads the key nowhere.
`Kati.Screens.AddByHandFa` assigns it at mount and never draws it. The English
mirrors all draw it: `Kati.Screens.Medication.save_notice/1` puts the failure
between the list it failed to change and the buttons that were just pressed, and
`Kati.Screens.AddByHand` does the same under its form.

So a Persian reader taps **خوردم**, the write is refused, and the page redraws
identically. They tap it again. `D-59` is what makes this reachable for a
medication dose — before it, no `Kati.Health.Dose` could exist to fail — and the
page whose own moduledoc says *of everything in this app, **did I take it** is
the question a wrong answer costs the most* is the one it lands on first.

## Why this is a board question and not a patch

`Kati.Write.message/1` answers in English, by design and at length: it has one
sentence for a refused write (*Nothing to save yet.*), one for an Ash error it
can render, and one generic (*That did not save. Your text is still here — try
again.*). Translating those three is copy, and nothing in the 173 boards writes
a Persian failure line of any kind. Inventing one in a screen file is the thing
this pipeline does not allow.

It is also not one sentence per screen. The failure is the same failure
everywhere, which is why the English side has exactly one function for it.

## What to draw

| Board | What it is |
|---|---|
| **new** | The refusal band, in Persian, drawn once on the screen most likely to hit it — screen 115's TODAY group, between the dose list and the two verbs, where 112 draws its own |

One band, three states, matching `Kati.Write.message/1`'s three answers so the
two sides cannot drift:

  1. **Nothing to save yet** — the write was refused because there was no row.
     This is the state a fixture reaches, and the state a reader reaches when
     the medication was deleted on screen 189 while this page was open.
  2. **A named refusal**, when Ash gives a sentence Kati can render.
  3. **The generic**, whose English says *your text is still here* — the half
     that matters, because it is the promise that nothing was lost.

The English band is `Kati.Screens.Medication.save_notice/1`: a 1.5pt-bordered
row, `error` glyph in `Palette.red()`, the sentence at 12.5/1.55 in
`Palette.ink_soft()`. The Persian one is that row in Vazirmatn through
`Kati.Screens.BookDetailFa.fa/4`, RTL, and it should say so rather than being
redrawn.

## The second half: a rule, not a board

Once the sentence exists, the gap it fills is app-wide and the fix is one
function. `Kati.Write.message/1` should answer in the active locale — the same
shape `Kati.Locale` already gives every other reader — so that a screen carrying
`:save_error` draws the right words without deciding anything. Any Persian
screen that then still fails to DRAW the key is a defect a sweep can find, and
that sweep is worth writing in the same round: *every screen that assigns
`:save_error` renders it*.

## Acceptance

  * A refused dose write on screen 115 is visible to the reader, in Persian.
  * The Persian and English sentences say the same three things, from one
    source, so neither can drift.
  * A sweep fails when a screen assigns `:save_error` and draws nothing.

## Two things found beside it, filed here so they are not lost

**Screen 115 asks two questions.** `mount/3` gates the weight half on
`Weight.latest() == WeightSample.latest()` and the dose half on
`Medication.doses() == Medication.drawn_doses()`. Before `D-59` the second could
only flip if a `health_doses` row existed and nothing could create one, so the
two answers moved together. They no longer do: the first medication anybody adds
puts the reader's own doses beside the drawing's weight, the drawing's date and
the drawing's chart — screen 20's rule broken on the Persian page in the same
way `D-59` found it broken on the English one. The fix has the same shape as
112's: one term, computed at mount, that all four bands read.

**A tag namespace bounded by names typed rather than by rows.**
`Kati.Screens.Medication.schedule_tag/1` mints an atom from the user's own
medication name, so renaming a medication mints another and the old one never
goes back. `Kati.Screens.MyServices.service_tag/1`,
`Kati.Screens.Money.subscription_tag/1` and
`Kati.Screens.ArtistDetail.album_tag/1` all do the same. It is the app's
pattern rather than one screen's slip, and the app's pattern is what should
change — to the row's id, in one round, with the `@empty_builders` entries that
name those tags moving with it.
