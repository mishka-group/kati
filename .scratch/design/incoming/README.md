# Drawn, sliced, and one still staged

Twenty-six artboards landed in the 23 August export. **Twenty-five are built**
— their boards moved into `screens/` in the commit that added the screen module
and its `Kati.Screens.Gallery` entry, which is the rule this directory exists to
enforce: `Kati.ScreenDesignLiteralTest` reads every file in `screens/` as the
claim *a screen exists for this and renders every literal in it*, so a board
arrives there only once that claim is true.

One remains here.

| # | Board | Brief | Why it is still staged |
|---|---|---|---|
| 134 | First run — the flow map | `D-23` | Not a screen. See below. |

The twenty-five that left are 128–133 (`D-22`, #25), 135–139 (`D-23`, #11),
140–142 (`D-24`, #12), 143–144 (`D-25`, #15), 145–147 (`D-26`, #19), 148–149
(`D-27`, #17), 150–151 (`D-28`, #20) and 152–153 (`D-29`, #21).

---

## Screen 134 is a map, not a screen

It is a 1720px-wide diagram of how the first run flows between screens. Kati
does not draw it and never will — there is no phone it fits on and no route
that could reach it. It stays here as the design record for #11 rather than
becoming a gallery entry, and `Kati.Screens.Gallery` says so at its `#11`
comment.

**134 is not a phone, and my splitter could not see it.** The brief said a map
may take whatever width it needs; Claude Design drew it as plain `div`s at
1720px rather than as an `<x-import IOSDevice>` frame, and the splitter here
sliced on `<x-import>` boundaries — so a board with no phone frame was invisible
to it and reported missing. It was never missing. The splitter now slices on
`data-screen-label` for a board with no frame.

It answers all three questions `D-23` left open, on the board:

  * **The resume rule** — *"Killed after 26 → resumes at 26. Kati reopens at the
    last completed step with earlier answers intact. Language is never
    re-asked."*
  * **One wide artboard**, not a spread.
  * **38's numbering** — the map carries the correspondence rather than the
    boards being renumbered, and says what the build must do: *renumber the
    rules to five segments at build time.* 38 draws "1, 3 and 4 of four"; with
    53 ahead of it the run order is five.

`D-23b` was written to ask for this board and is unnecessary. Left in
`design-briefs/` as the record of the wrong call rather than deleted.

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
