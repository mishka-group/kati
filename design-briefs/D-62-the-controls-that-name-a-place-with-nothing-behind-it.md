# The controls that name a place with nothing behind it

> **Mixed — three boards and one schema decision** · ticket `D-62`

`Kati.ScreenTapSweepTest`'s `@inert_taps` is down to 166 after `K-43 open-url`
and `K-44 open-settings` took thirteen off it. Most of what remains is not a
defect at all: a lit segment is the shelf you are already on, a lit chip is the
filter already showing, a states board's controls are pictures of controls, and
several writes land in `Mob.State`, which that sweep's heuristic structurally
cannot see.

This brief is the rest — the controls that are drawn, reachable, honest-looking
and dead, each because the thing behind them does not exist. They are grouped
by what is missing rather than by screen, because the missing thing is the unit
of work.

## 1 · Seven service rows, and no page to open

`Kati.Screens.MyServices` (screen 92) draws one row per subscribed service and
`Kati.Screens.MyServicesEmpty` (93) draws the free card. `service_tag/1` gives
each its own name — `edit_service_Lumen+`, `edit_service_Orbit` — so the sweep
can address them individually, which was #97's work. Every one of them opens
nothing, because **no board draws a service**.

What a service page would hold is already in the resource: the name, the
country, the monthly price in pence, whether it is shared, the renewal date.
Screen 23 prices them and screen 92 lists them; nothing edits one.

| Board | What it is |
|---|---|
| **new** | One service — name, price, renewal, shared-with, and the destructive remove at the foot in 31's manner |

## 2 · Four chevrons on a book, pointing at two screens nobody drew

Screen 66's series row ends in `Next: Low Water` and its ownership row in
`Due 27 Aug`; both carry a chevron. Screens 68 and 69 draw the same two rows
because they are the same page in another colourway and another script. Neither
a next-in-series screen nor a lending screen exists.

The lending one is the sharper of the two: `Kati.Books.Book` stores `lent_to`
and `lent_due_on`, so the app knows who has your book and when it is due, and
the only thing it can do about it is print one line.

| Board | What it is |
|---|---|
| **new** | Lending — who has it, since when, due when, and the *returned* action |

The series destination is a filtered shelf rather than a new page, and screen
20 already filters. It may need no board at all — a decision, not a drawing.

## 3 · Screen 43's *Done prepping*, and five neighbours

`Kati.Meals.Recipe` stores a method, a duration and an oven temperature, and
**nothing anywhere records that a prep was done**. So the card stays put, and
`done_prepping`, `add_tag`, `share`, `more` and two `open_menu` taps sit inert
beside it.

This one is not a board first. It is a question: **what is a prep, and what
does done mean?** Per recipe, per day, per meal-plan slot? Does it reset at
midnight? A `prepped_at` column answers the easy version and the wrong one — a
recipe prepped on Sunday for Wednesday's dinner is prepped for a SLOT, not for
itself, and `Kati.Meals.MealPlanSlot` is where that belongs.

Answer the question, then the column, then the card's second state.

## 4 · *Save image*, blocked on a capability

Screen 121 is the week rendered as one printable page and its button says
**Save image**. `Kati.Native.Files.save_as/2` can put a file into
`ACTION_CREATE_DOCUMENT`, so the saving half exists. What does not exist is the
half that turns a screen into a PNG: Mob renders to Compose, and nothing in
`native/LEDGER.md` captures a composable to a bitmap.

`K-43` and `K-44` are the shape this would take — a fence, a closed contract, a
refusal that gets drawn. It is a bigger fence than either, and it is the only
item here that is engineering rather than design.

## Why this is filed rather than fixed

Every other kind of dead control in this app has now been fixed: the ones that
needed a writer got one (`D-38`, `D-39`, `D-43`), the ones that named the wrong
row got `target/1` (`D-59`), and the ones that needed a way out to the platform
got two fences. What is left needs either a drawing that does not exist or an
answer to a question about what the app means — and inventing either in a
screen file is the one thing this pipeline does not allow.

## Acceptance

  * Each group above is either drawn, answered, or explicitly declined.
  * `@inert_taps` loses the entries as each lands, struck out rather than
    deleted, so the list stays a queue rather than a graveyard.
  * No control in Kati is drawn as a live affordance while doing nothing —
    which is the whole of what this ticket is for.
