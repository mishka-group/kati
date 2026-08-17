# Kati — Wayfinder Map

> This file mirrors the canonical map issue on GitHub (label `wayfinder:map`).
> The issue is the source of truth; this copy keeps the map readable inside the repo.

## Destination

**A decision-complete plan for Kati — every architectural decision made and evidenced, every
component gap identified, every design gap written up — such that implementation can begin on
command and proceed without re-litigating foundations.**

Reaching the end of this map means: the project scaffold is decided (not yet run), the data layer
and supervision model are settled, the styling and localization stacks are chosen, the calendar's
domain model and sync strategy are specified, the media-tracking data sources and the on-device
notification mechanism are proven, every missing Mishka Chelekom component is listed with an
agreed extension path, and every gap in the design has an issue the owner can paste into Claude
Design to complete it.

**Implementation does not start until the owner says so.** Prototypes built to answer a ticket are
throwaway evidence, not the app.

## Notes

**Domain.** Kati is a personal all-in-one mobile app: a professional calendar as the spine, plus
film/TV tracking, books, music, health, money and habits. The design is 62 screens in 14 groups
(A–N) with four fixed roots — Home, Calendar, Library, Stats — and a detached FAB.

**Locked decisions** (from the owner; do not re-open without them):

| # | Decision |
|---|---|
| Q1 | This map plans and researches; it does **not** implement. Prototypes are allowed as evidence. The owner gives the go-ahead to build. |
| Q2 | Scope is the **whole design**, plus gaps found by comparing against comparable products. Design gaps become issues the owner pastes into Claude Design. |
| Q3 | **Open source**, published to Play Store, App Store and APK-on-GitHub. Built for anybody, not just the owner. Needs import/export and device-to-device sharing. A server may come later. |
| Q4 | **Ash** over **SQLite** for the whole system. **Device-first, no server.** Background jobs run on device (Oban/AshOban-style) — notifications must work with the app closed. |
| Q5 | **Mishka Chelekom is a dev-only dependency** installed as a **`path:` dep**, never a released version. It is a CLI that generates component source into Kati. Missing or broken components are fixed **on its current branch — no new branch** — and must stay **headless and unstyled**; all styling lives in Kati. The owner authors Mishka Chelekom. |
| Q6 | **Mob only** — no alternative framework. Bypass to **Kotlin/Swift** where needed. Use **Mob's plugin system** for native additions and components. Use Mob's **router** with lazy screen loading; **speed is a first-class requirement** across 62 screens. Animation/transition is available and in scope for common cases. |
| Q7 | **English + Persian only.** Localization must be automatic — no manual per-string work. Prefer native/Elixir-ecosystem solutions (`ex_cldr` / Localize / `ash_localize`). **Jalali is display-only; stored data stays Gregorian/UTC.** |
| Q8 | Fidelity target is **100% of the design**. Where Mob cannot do it, drop to **Kotlin/SwiftUI**. **Android is the priority now**; iOS later but never architecturally foreclosed. |
| Q9 | **Kati owns the calendar**, fully integrated with external systems (Google et al.), **including two-way sync** — which needs comprehensive issues. The whole app depends on this calendar. |

**Skills every session should consult:** `/grilling` and `/domain-modeling` for decision tickets;
`/prototype` for prototype tickets; `/research` for research tickets. Mishka Chelekom carries its
own definition of done for component work at
`.claude/skills/mob-component-fix/SKILL.md` — component + showcase with a working handler + unit
test + Kotlin e2e + `mix mishka.mob.sync` + usage-rules doc + CHANGELOG. Follow it exactly.

**Standing technical constraints** established by research (see `docs/research/`):

- Mob is **v0.7.20, pre-1.0, single-maintainer**, no `mix mob.upgrade`, and generated `android/`
  and `ios/` shells are **forked at generation time** — pin exactly and budget a three-way diff on
  every bump.
- **Screens are not supervised** despite the docs saying so — `start_root/3` is a bare
  `GenServer.start_link` and a crashed screen stays dead. Kati must supply its own supervision.
- A fresh `mix mob.new` app **crashes on its first HTTPS call on Android** — no CA bundle is wired
  into the template.
- The BEAM **stops when backgrounded**. OS-scheduled local notifications fire while force-quit;
  discovering *new* facts while closed needs native periodic work.
- Mob has **no wrap primitive** and reports no geometry back to `render/1`.
- `Mob.Storage`/DETS is SIGKILL-safe; there is **no encryption at rest** anywhere.

**Always use `mix` generators** rather than hand-writing scaffolding, and always the latest
versions of dependencies.

## Decisions so far

<!-- one line per closed ticket: gist + link -->

_None yet._

## Not yet specified

<!-- in-scope fog: real, but not yet sharp enough to ticket -->

- The nine non-initial design sections (books, music, health, meal plans, money, habits,
  automation, account/access, off-app surfaces) are in scope per Q2 but are not yet decomposed —
  they graduate once the foundation and the two lead sections are settled.
- Widget/lock-screen surfaces, Siri shortcuts, share-extension OCR, Chromecast/AirPlay scrobbling
  and QR scanning appear in the design and all require native work whose feasibility on Mob is
  unknown.
- Stats and charting across every section — the design draws mirrored charts and a 104-cell pixel
  field, and Mob has no chart primitive.
- Accessibility beyond Dynamic Type: screen readers, focus order, contrast in both themes.
- Whether a server ever arrives, and what it would own if it did.

## Out of scope

<!-- ruled beyond the destination; closed, never graduates -->

- **Building the app.** This map produces decisions and evidence; implementation begins on the
  owner's word (Q1).
- **Locales beyond English and Persian.** The design's locale table lists `ar` and `tr`; Q7 rules
  them out. The i18n *machinery* must not make them impossible later, but neither is shipped.
