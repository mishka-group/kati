> **SUPERSEDED — the board existed all along.** Claude Design drew screen 134
> at 1720px as plain `div`s rather than as an `IOSDevice` frame, which is what
> this brief asked for. The slicer here counted `<x-import>` boundaries and so
> could not see a board with no phone in it, and reported it missing. Kept as
> the record of the wrong call; nothing here needs drawing.

# The first-run flow map — the one board that is missing

> **One artboard, and it is not a phone screen** · issue [#11](https://github.com/mishka-group/kati/issues/11) · ticket `D-23b`

## What happened

`D-23` asked for the first-run sequence: a flow map plus the missing screens. **Eleven of the twelve arrived.** Screens 135–139 are drawn and good — the chromeless restore, the loudness-to-OS-prompt band, the Persian onboarding, the 235% pass, and Home with nothing set up.

**134 — First run — the flow map — has a caption in the export and no frame behind it.**

The likely cause is my own brief: it said *"the flow map may take whatever width it needs"*, and everything else in `Kati.dc.html` is a 402×874 `IOSDevice` artboard. A board that is not a phone is easy to skip when every other board is.

## What it is for, and why the other eleven do not replace it

Four onboarding screens existed before this round and none of them knew about the others. Screen 38 is drawn as four numbered steps whose numbers **do not match the order the app runs them in**, and no artboard anywhere answers:

- which screen is step 1, 2, 3, 4
- where a skip goes, from each screen that has one
- **where the app resumes if it is killed halfway** — the question #11 exists to answer
- how the restore branch rejoins the main path

Those are not four questions about four screens. They are one question about a sequence, and a sequence needs a picture of itself.

## Draw this

**One artboard. Not 402×874 — take whatever width and height the map needs to stay legible.** It is a diagram, not a screen, and it is the only board in the file that is allowed not to be a phone.

### The spine

```
53 Language ──► 38·1 Welcome ──► 26 Sections ──┬─► 38·3 Loudness ──► 38·4 First title ──► 01 Home
                                               │
                                               └─► 135 Restore ──► 37 Import ──► 01 Home
```

### On the map

1. **Each node** as a small labelled thumbnail or a titled box carrying its **screen number** and its **step number** — and where those two disagree today, show both, because reconciling them is half the deliverable.
2. **Every arrow labelled** with what causes it: a choice, a Continue, a Skip.
3. **Every skip path drawn**, from each screen that has one, to where it actually lands.
4. **The restore branch**, from `38·1 Welcome` *and* from `26 Sections`, since both offer it, rejoining at Home.
5. **The resume rule, written on the board as a sentence.** *"Killed after 26 → resumes at 26"*, or *"→ resumes at 53"*. Pick one. This is the single most important mark on the artboard: the ticket asks for the answer, not for the options, and it is currently unanswerable from any frame.
6. **The three refusals** as terminal states off the restore branch: a backup from a newer Kati, a corrupt file, and onboarding skipped entirely.
7. **A note that the language choice takes effect immediately**, so every node after 53 is drawn in the chosen language — which is what makes screens 137 and 138 part of this flow rather than variants of it.

### Style

Use the house palette, but this is a diagram: paper ground, ink nodes and rules, `#E8823C` for the **one** thing the map most wants read — the resume rule, or the restore branch. No dock, no back pill, no device chrome.

## What not to redraw

Screens 53, 26, 38·1, 38·3, 38·4, 135, 136, 137, 138 and 139 are done. This board **references** them; it does not restate them.

## Left open — decide and note which way you went

- **Where a killed app resumes.** Pick one and write it on the board.
- **Whether 38's four step numbers get renumbered** to match the run order, or whether the map carries the correspondence instead. Either is fine; leaving them contradicting each other is not.
- **Thumbnails or titled boxes.** Thumbnails read faster and are ten times the work; boxes with numbers are legible at any size. Prefer boxes unless the thumbnails come cheap.
