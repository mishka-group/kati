# Component policy

## Where components come from

Three sources, in order of preference:

1. **`Kati.UI`** — Kati's own building blocks (card, poster, chip, timeline row,
   pixel field). Built here first. **#44 decided nothing is promoted to Mishka
   Chelekom until Kati has actually used it**, so that other people's apps never
   receive a half-proven component.
2. **Mishka Chelekom, generated** — `mix mishka.ui.gen.mob <name> --module-prefix kati_`.
   Writes source into `lib/kati/components/`, which Kati then owns and styles.
   The library ships them **headless and unstyled**; all styling lives here.
3. **A bridge edit** — last resort, fenced and ledgered. See `native/README.md`.

## The generate set

Only what Kati actually uses. Every generated component is source in this repo
that has to be read, styled and maintained, so an unused one is pure cost:

| Component | Why |
|---|---|
| `dialog` / `alert_dialog` | The five modal screens (06, 18, 31, 33, 46) |
| `drawer` | Bottom sheets — `side: :bottom` with `snap_points` |
| `menu` | Overflow actions on a title |
| `select` / `combobox` | Calendar pickers, source pickers |
| `toast` | The snackbar-shaped feedback in the design |
| `loading_overlay` | Blocking states during sync |

**Not generated:** the colour pickers, sliders, tree/tree-select, code, JSON
input, marquee, and the rest of the 73. Kati's design uses none of them.

## The prefix

`--module-prefix kati_`, always. It moves the file, the module, the composite
tag and the doc tag together, so a generated `dialog` becomes
`Kati.Components.KatiDialog` and `<KatiDialog>` in `~MOB`.

The reason is not cosmetics: **without a prefix, a generated `<Dialog>` occupies
the same tag namespace as anything Mob might add later**, and a future Mob
release adding its own `Dialog` node would collide silently — the dispatch
`when` has no `else`, so the loser renders nothing.

## Guardrails

### `:anchored` must not reach a Kati screen

Three Mishka components — `popover`, `tooltip`, `preview_card` — emit
`%{type: :anchored}`, which the **published** mob 0.7.20 renderer does not know.
On Android the bridge's `when` has no `else` arm, so such a node draws **nothing
at all**; on iOS it falls through to a column and becomes an in-flow accordion.

`Kati.ComponentPolicyTest` fails the build if `Anchored.anchor` or
`Anchored.closed` is called anywhere under `lib/`. Note that `popover.ex` and
`anchored.ex` may still be *generated* as `necessary:` siblings of `menu` —
that is fine as dead code, and the lint is what keeps it dead.

### Regeneration must not silently revert Kati's edits

Generated files live in `lib/kati/components/` and Kati edits them for styling.
Re-running the generator **overwrites** them. So:

- `docs/COMPONENTS.md` (this file) records the exact generate command used.
- Every Kati edit to a generated component carries a `KATI-STYLED` marker
  comment, and the test asserts that no generated component has *lost* one.
- Before regenerating, run `git status` — a clean tree makes the diff readable
  and a dirty one makes it impossible.

## Consuming Mishka Chelekom as a path dep

Undocumented and non-obvious. In order:

```bash
mix deps.compile rustler          # igniter_js declares it optional: true, and
                                  # mishka declares it dev-only, so a consumer's
                                  # tree never installs it
IGNITERJS_BUILD=1 IGNITERCSS_BUILD=1 \
  mix deps.compile igniter_js igniter_css   # no published NIF artifacts
mix deps.compile anubis_mcp       # mishka's MCP modules need it
mix deps.compile mishka_chelekom
```

`igniter_js` and `igniter_css` are declared as **direct** path deps in Kati's
`mix.exs` purely so `rustler` is visible in the same tree when they force-build;
as transitive deps of Mishka they could not see it.
