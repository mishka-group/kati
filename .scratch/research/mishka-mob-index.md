# Mishka Chelekom — Mob (BEAM-on-device) technical index

Research target: `/Users/shahryar/Documents/Programming/Elixir/mishka_chelekom`
Checked out branch: `feat/headless-daisyui-skin` (HEAD `5c4f5d68`), merge-base with `master` is `master`'s own tip `a053bf4b` — i.e. the branch is 108 commits **ahead**, 0 behind.
Library version: `0.0.10-alpha.6` (`mix.exs:4`). Target framework: `mob` **0.7.20** (hex).
All paths below are relative to the repo root unless absolute.

> **Headline corrections to the brief:** there are **73** Mob components in `priv/mob/`, not 61.
> `usage-rules/mob/` holds **60 component docs + README** = 61 files; 13 components ship with no usage-rule doc.
> Mob is **byte-identical on `master` and this feature branch** — `git diff master..HEAD` is empty for
> every Mob path.

---

## 1. How Mob components are defined and generated

### 1.1 The chain of custody

```
development/mob/lib/mishka_mob/components/mishka_<name>.ex   ← SOURCE OF TRUTH (a real, running Mob app)
        │  mix mishka.mob.sync   (maintainers only)
        ▼
priv/mob/<name>.eex   (EEx template)  +  priv/mob/<name>.exs   (catalog)
priv/mob/kit/{anchored,color,event}.eex  (shared support modules)
        │  mix mishka.ui.gen.mob / .components / .kit   (consumers)
        ▼
lib/<app>/components/<name>.ex          (+ lib/<app>/components.ex registry)
        + register_all/0 wired into <App>.App.on_start/0
        + tags appended to deps/mob/priv/tags/{android,ios}.txt, then `mix deps.compile mob --force`
```

`MishkaChelekom.Generators.Mob`'s moduledoc states the reason plainly
(`lib/mishka_chelekom/generators/mob.ex:6-12`):

> "`development/mob` is a real, running Mob application with a showcase and a test suite… Keeping a
> second, hand-maintained copy under `priv/mob` would guarantee the two drift. So the templates are
> **derived**, `mix mishka.mob.sync` regenerates them, and the tests assert the derivation
> round-trips: rendered, compiled and called."

So: **the source of truth is `development/mob/lib/mishka_mob/components/*.ex`.** `priv/mob/*.eex` is
generated, and `priv/mob/*.exs` is the generated catalog. There are no hand-written `.eex` files.

### 1.2 What the derivation rewrites

`lib/mishka_chelekom/generators/mob.ex:207-217` (`rewrite/2`) applies five passes:

| Pass | Line | Source → Template |
|---|---|---|
| `rewrite_doc_only_references/1` | `:221-223` | `` `MishkaMob.App.on_start/0` `` → "your app's `on_start/0`" |
| `rewrite_defmodule/2` | `:228-234` | `defmodule MishkaMob.Components.MishkaChip do` → `defmodule <%= @module %> do` |
| `rewrite_namespace/1` | `:236-243` | `MishkaMob.Components.Mishka` → `<%= @namespace %>.<%= @module_prefix_camel %>`; `MishkaMob.Components.` → `<%= @namespace %>.` |
| `rewrite_bare_modules/1` | `:253-255` | `\bMishka([A-Z]…)` → `<%= @module_prefix_camel %>\1` (also rewrites `<MishkaCloseButton />` in docs) |
| `rewrite_own_function/3` | `:259-269` | `def chip(` / `@spec chip(` / self-calls → `<%= @component_prefix %>chip(` |
| `rewrite_sibling_calls/2` | `:273-277` | `.action_icon(` → `.<%= @component_prefix %>action_icon(` |

The subtle one is documented at `:271-272`: *"prefixing a public function also moves every sibling's
call to it."* Mob components, unlike headless ones, **call each other in code** — a close button
`alias`es and calls an action icon — so the namespace and function prefix must be threaded through
every call site.

`siblings/1` (`:141-155`) derives dependencies **from `alias` lines only** — scanning the whole source
picked up moduledoc self-references (infinite generator recursion) and prose like `` `MishkaSelect`'s ``
(a component named `select's`).

`public_function/2` (`:114-116`) returns `nil` for composite-only components (`accordion`, `drawer`),
which expose `expand/3` plus helpers but no render function — so there is nothing for
`--component-prefix` to prefix.

### 1.3 The catalog `.exs` shape

Written by `Mob.catalog/2` (`lib/mishka_chelekom/generators/mob.ex:289-314`). Real example
(`priv/mob/tree_select.exs`):

```elixir
[
  tree_select: [
    name: "tree_select",
    category: "forms",
    doc_url: "https://mishka.tools/chelekom/docs/mob/tree-select",
    args: [type: ["tree_select"], only: ["tree_select"], helpers: [], module: ""],
    optional: [],
    necessary: ["tree"],
    scripts: [],
    mob: [
      composite_tag: "tree_select",
      function: "tree_select",
      kit: ["anchored", "event"]
    ]
  ]
]
```

* `category` is lifted from the matching **headless** catalog (`priv/headless/<name>.exs`) so the two
  layers cannot disagree (`mob.ex:369-377`); `skeleton` is the one Mob-only component and is pinned to
  `"feedback"` by `@mob_only_categories` (`mob.ex:367`).
* `doc_url` is **derived, not lifted** (`mob.ex:332-334`) — headless URLs pointed at the web page and
  used underscores where the site uses hyphens.
* `necessary` = alias-derived siblings ∪ `declared_dependencies/1` (the headless catalog's own
  `necessary`, which is how `tree_select → tree` is discovered — `tree_select` renders whatever tree it
  is handed and never names the module: `mob.ex:336-362`, `mishka.mob.sync.ex:128-136`).
* `mob: [kit: …]` = which of `anchored` / `color` / `event` the source references (`mob.ex:163-171`).
* `composite_tag` is the **unprefixed** base; the real registered tag is `prefix <> base`.

### 1.4 `mix mishka.ui.gen.mob` (single component)

`lib/mix/tasks/mishka.ui.gen.mob.ex`. Pipeline at `:122-136`:

```elixir
igniter
|> Igniter.assign(:mishka_user_config, Config.load_user_config(igniter))
|> Registry.check_dependency()      # warns unless the project depends on :mob
|> Locations.assign_namespace()     # :mob_namespace = MyApp.Components
|> resolve_template(component)      # Core.fetch_catalog(igniter, component, :mob)
|> compute_location()               # file name + module, honouring --module-prefix / --module
|> build_eex_assigns()
|> write_component()                # Igniter.copy_template(..., on_exists: :overwrite)
|> vendor_kit()                     # composes mishka.ui.gen.mob.kit --only <kit>
|> generate_necessary()             # recursively composes itself for each sibling
|> register_composites()            # rewrites lib/<app>/components.ex
|> wire_boot()                      # inserts <Ns>.register_all() into <App>.App.on_start/0
|> whitelist_tags()                 # rewrites deps/mob/priv/tags/{android,ios}.txt + deps.compile mob --force
|> maybe_save_prefixes()
```

Flags (`:96-104`): `--module`/`-m`, `--component-prefix`, `--module-prefix`, `--sub`, `--no-save`,
`--no-register`, `--no-kit`, `--no-tags`, `--yes`.

Locations (`lib/mishka_chelekom/generators/mob/locations.ex`):
* `mob_namespace` = `<App>.Components`, built with `Core.module_atom/1` **not** `Module.concat/1` — the
  latter yields `:"Elixir.MyApp.Components"` whose `to_string/1` keeps the `Elixir.` prefix and would
  emit `defmodule Elixir.MyApp.Components.Chip` (`:16-26`).
* component file → `lib/<app>/components/<name>.ex` (`:42-46`), kit → same dir (`:50`),
  registry → `lib/<app>/components.ex`, **beside** the dir so a wildcard never picks it up (`:52-59`).

`generate_necessary/1` (`:266-276`) does **not ask**: *"the dependency is a compile-time one — an alias
and a call — so declining it would leave a module that cannot compile."* Siblings inherit
`--sub --yes --no-register` plus both prefixes (`:292-298`).

### 1.5 `--module-prefix` (and its two siblings)

`Locations.normalize_prefix/1` (`locations.ex:82-86`) forces a trailing `_`, and the docstring explains
why it is load-bearing (`:61-80`): a component's module is `camelize(prefix <> name)` while a
*sibling reference* in a template is `camelize(prefix) <> camelize(sibling)`. With `--module-prefix
mishka` (no underscore) you get `mishkaclose_button.ex` defining `MishkacloseButton` aliasing
`MishkaActionIcon`, while the sibling defines `MishkaactionIcon` — code that does not compile.

One flag moves **four** things at once:

| | no prefix | `--module-prefix mishka_` |
|---|---|---|
| file | `lib/app/components/chip.ex` | `lib/app/components/mishka_chip.ex` |
| module | `App.Components.Chip` | `App.Components.MishkaChip` |
| composite tag | `:chip` | `:mishka_chip` |
| `~MOB` tag / docs | `<Chip />` | `<MishkaChip />` |

`--component-prefix mishka_` is orthogonal: it renames the *public function* (`def mishka_chip/1`) and
every self-call and sibling call, but **never `expand/3`** — that is the composite protocol, not a
component (test at `test/mix/tasks/mishka.ui.gen.mob_test.exs:150-155`).

Kit modules (`Event`, `Color`, `Anchored`) are **never** module-prefixed
(`mishka.ui.gen.mob.kit.ex:20-26`): *"a prefix distinguishes your components from someone else's, and
these are neither — they are the shared floor both stand on."*

Prefixes persist to `priv/mishka_chelekom/config.exs` unless `--no-save`
(`MishkaChelekom.Config`, keys `:component_prefix` / `:module_prefix`, `config.ex:19-20`).

### 1.6 `components.ex` / `register_all/0`

Owned by `MishkaChelekom.Generators.Mob.Registry` (`lib/mishka_chelekom/generators/mob/registry.ex`).
The generated file (template at `:230-264`):

```elixir
defmodule MyApp.Components do
  @moduledoc """
  Composite-tag registry for the generated Mob components.

  Call `register_all/0` once at boot, from your app's `on_start/0`:

      def on_start do
        MyApp.Components.register_all()
        Mob.Nav.push(MyApp.HomeScreen)
      end
  …
  """

  @composites [
    {:action_icon, MyApp.Components.ActionIcon},
    {:close_button, MyApp.Components.CloseButton}
  ]

  def composites, do: @composites

  def register_all do
    Enum.each(@composites, fn {tag, module} ->
      Mob.Composite.register(tag, {module, :expand})
    end)
  end
end
```

Key invariants:

* **Rebuilt, never appended** (`:15-21`). `entries/2` (`:151-172`) unions (a) `{component, module}` pairs
  recorded during *this* Igniter run — which is the only place a custom `--module` survives — with
  (b) a filesystem scan of `lib/<app>/components/*.ex` plus pending in-run sources, matched against
  the catalog with the prefix stripped **and** as-is (`:195-203`).
* Kit modules are excluded because they are not in the catalog (test at `mob_test.exs:227-232`).
* `wire_boot/1` (`:280-292`) finds `<App>.App`, moves to `def on_start/0`, and inserts the
  `register_all()` call **unless already present** — idempotent, and falls back to an
  `Igniter.add_notice/2` if the module isn't found. Rationale at `:271-276`: *"an unregistered tag does
  not fail, it renders **nothing**."*
* Uninstall rebuilds or deletes it (see §1.8).

### 1.7 The `~MOB` tag whitelist

`Registry.whitelist/2` (`registry.ex:56-73`). Mob's `~MOB` sigil validates tag names at **compile
time** against `@known_tags`, baked from `Application.app_dir(:mob, "priv/tags/{ios,android}.txt")`
(`development/mob/deps/mob/lib/mob/sigil.ex:87-89`, check at `:493-498`). A runtime
`Mob.Composite.register/2` is invisible to that, so every `<MishkaChip>` call site warns — fatal under
`--warnings-as-errors`.

So the generator **rewrites the dependency's file**, inside a fence
(`registry.ex:27-28`):

```
# >>> mishka_chelekom composites — regenerated by `mix mishka.ui.gen.mob`
ActionIcon
Chip
CloseButton
# <<< mishka_chelekom composites
```

`render/1` (`:104-107`) strips any previous fence and re-emits — idempotent by construction — then
`recompile_mob/1` (`:98-102`) queues `mix deps.compile mob --force` **once**, because `@known_tags` is
baked at Mob's compile time. `mix deps.get`/`deps.clean` discard the block; re-running restores it.
`--no-tags` opts out. The whole thing is a no-op when `deps/mob/priv/tags/*.txt` is absent (`:78-92`).

The tags come from `entries/2` (not from filenames), which is what carries `--module-prefix` through
(`:41-45`).

Mob's own primitives in those files (`development/mob/deps/mob/priv/tags/android.txt:7-26`):

```
Box  Button  Column  Divider  Image  LazyList  List  Progress  Row  Scroll
Slider  Spacer  TabBar  Text  TextField  Toggle  Video  CameraPreview  WebView  GpuView
```

*(iOS is identical minus the "Video is a stub pending ExoPlayer integration" note.)*

### 1.8 `mix mishka.ui.gen.mob.components` (batch)

`lib/mix/tasks/mishka.ui.gen.mob.components.ex`. Positional arg optional; omitted or `all` means every
component in `priv/mob/`. It fans out to `mishka.ui.gen.mob` with
`["--sub", "--yes", "--no-register", "--no-tags"]` (`:81-84`) and then writes the registry, wires boot
and whitelists **once at the end** (`:92-96`) — *"doing either 72 times would be correct and pointlessly
slow — and the whitelist recompiles :mob, so per component it would rebuild the framework once per
component."* Extra flag: `--exclude`/`-e` (CSV).

### 1.9 `mix mishka.ui.gen.mob.kit`

`lib/mix/tasks/mishka.ui.gen.mob.kit.ex`. Vendors `anchored`, `color`, `event` from
`priv/mob/kit/*.eex` into `lib/<app>/components/`. `--only` filters. Composed automatically by
`mishka.ui.gen.mob` when a catalog's `mob: [kit: …]` is non-empty (`mishka.ui.gen.mob.ex:247-259`;
comment: *"41 of the 72 components alias `Event`"*).

### 1.10 Uninstall

`mix mishka.ui.uninstall <name> --mob` (`lib/mix/tasks/mishka.ui.uninstall.ex`).

* `target_kind(%{mob: true}) → :mob` — mob wins if `--headless` is also passed (`:152-154`).
* Catalog lookup paths for `:mob` (`:421-422`): `deps/mishka_chelekom/priv/mob`, `Core.lib_priv("mob")`,
  `priv/mob`.
* Components dir resolves through `MobLocations.components_dir/1` (`:446`, `:462`) — `lib/<app>/components`,
  **not** `lib/<app>_web/...`.
* `refresh_mob_registry/1` (`:520-553`): rebuilds `components.ex` from the survivors, or `Igniter.rm`s it
  when nothing survives; then rebuilds the `~MOB` whitelist from the survivors too, because *"leaving a
  removed tag in it is the worse of the two failures: `~MOB` would go on accepting a tag nothing
  registers any more, so the markup compiles clean and renders nothing."*
* No CoreComponents / html_helpers cleanup for a pure-Mob removal (`:924-929`).
* No CSS, no JS hooks, no npm — asserted by `mishka.ui.gen.mob_test.exs:372-381`.

---

## 2. The full component catalogue (73)

Legend: **fn** = public render function (`—` = composite-only, `expand/3` + helpers), **kit** =
vendored support modules, **needs** = `necessary:` siblings auto-generated with it.
"no doc" = no file in `usage-rules/mob/`.

### Forms / input (31)

| Component | fn | kit | needs | One-liner | Key props / events |
|---|---|---|---|---|---|
| `checkbox` | ✓ | event | — | Labelled box with checked / unchecked / **indeterminate**; Mob has no checkbox widget so the indicator is drawn | `label` `checked` `indeterminate` `disabled` `on_toggle` `color` `size` `id` |
| `checkbox_group` | ✓ | event | checkbox | Labelled set with an optional tristate "select all" parent | `value` `label` `select_all` `select_all_label` `on_change` `on_select_all` `space` `color` |
| `radio` | ✓ | event | — | One option in a mutually exclusive set (circle + centre dot) | `label` `checked` `disabled` `on_select` `color` `text_color` `size` `fill_width` `id` |
| `radio_group` | ✓ | event | radio | Labelled set of mutually exclusive options | `value` `label` `disabled` `on_change` `orientation` `space` `color` `id` |
| `switch` | ✓ | event | — | On/off; thin wrapper over Mob's native `Toggle` | `checked` `label` `on_change` `color` `track_color` `disabled` |
| `toggle` | ✓ | event | — | Button that stays pressed (toolbar bold/italic) | `label` `pressed` `disabled` `on_change` `color` `background` `padding` `corner_radius` `border_*` `fill_width` `id` |
| `toggle_group` | ✓ | event | toggle | Row of toggles sharing one selection, single or multiple | `value` `multiple` `disabled` `on_change` `orientation` `space` `fill_width` `id` |
| `segmented_control` | ✓ | event | — | Joined strip where exactly one option is always selected | `value` `label` `on_change` `color` `text_color` `background` `track_padding` `segment_radius` `border_*` `fill_width` `id` |
| `chip` | ✓ | event | — | Compact selectable filter label (a pill you tap) | `label` `checked` `disabled` `on_toggle` `color` `text_color` |
| `slider` | ✓ | event | — | Draggable value along a range; wraps Mob's native `Slider`; supports 2-thumb `values` | `value` `min` `max` `values` `orientation` `length` `min_gap` `collision` `label` `show_value` `on_change` |
| `number_field` | ✓ | event | — | Numeric `TextField` + −/+ steppers, numeric keyboard | `value` `min` `step` `decimals` `format` `placeholder` `disabled` `on_change` `on_step` `value_width` `fill_width` |
| `otp_field` | ✓ | event | — | Segmented one-time-code input; the boxes *are* the input | `value` `length` `validation_type` `mask` `on_change` `slot_width` `group` `separator` `focused` `on_focus` `id` |
| `mask_input` | ✓ | event | — | Text field that formats to a pattern as you type (`9`/`a`/`*`) — **no doc** | `value` `mask` `placeholder` `keyboard` `disabled` `on_change` |
| `json_input` | ✓ | event | — | Multi-line JSON field with a server-validated error state | `value` `lines` `placeholder` `invalid` `error_text` `show_error` `on_change` `error_color` `id` |
| `field` | ✓ | — | — | Labelled control + description + validation errors (layout only; no aria wiring exists natively) | `label` `description` `errors` `required` `disabled` `space` `*_color` `text_size` |
| `fieldset` | ✓ | — | — | Group of controls under a legend — **no cascade of `disabled`** — **no doc** | `legend` `disabled` `space` `color` `background` `padding` `corner_radius` |
| `select` | ✓ | anchored, event | menu | Trigger showing the current choice + a list to pick from; slot tag `<SelectOption>` | `value` `open` `multiple` `placeholder` `label` `on_toggle` `on_select` `group` `id` |
| `combobox` | ✓ | anchored, event | menu, pill, select, tags_input | Text field filtering a list; single or multiple; `filter/3` is a pure fn the screen calls | `value` `query` `open` `multiple` `creatable` `on_query` `on_select` `on_create` `on_remove` `on_clear` `clear_icon` `wrap_chars` |
| `autocomplete` | ✓ | anchored | combobox | Text field suggesting completions (same machinery as combobox) | `query` `open` `suggestions` `filter` `empty_text` `on_query` `on_focus` `trigger` `id` |
| `tags_input` | ✓ | event | pill | Removable tokens (own pills) + a draft field | `tags` `draft` `on_draft` `on_add` `on_remove` `background` `space` `wrap_chars` `id` |
| `pills_input` | ✓ | event | — | Bordered container for **caller-supplied** pills + a text field — **no doc** | `draft` `on_draft` `on_add` `on_press` `on_focus` `space` `wrap_chars` `per_row` `id` |
| `tree_select` | ✓ | anchored, event | tree | Trigger + a tree that opens beneath it | `label` `placeholder` `open` `disabled` `on_toggle` `id` |
| `color_picker` | ✓ | color, event | hue_slider | Saturation/value canvas area over a hue slider | `hue` `saturation` `value` `width` `on_area` `on_hue` `id` |
| `color_input` | ✓ | anchored, color, event | color_picker | Hex field + swatch + picker panel | `value` `open` `label` `hue` `on_change` `on_toggle` `on_hue` `on_area` |
| `hue_slider` | ✓ | color, event | — | 0–360° hue over a real rainbow track drawn on `Mob.UI.canvas/1` | `value` `width` `height` `show_value` `label` `on_change` `id` |
| `alpha_slider` | ✓ | color, event | — | 0–100 opacity over a real transparency checkerboard | `value` `color` `width` `show_value` `label` `on_change` `id` |
| `angle_slider` | ✓ | color, event | — | Circular 0–360° dial drawn on canvas | `value` `size` `show_value` `label` `text_color` `color` `on_change` `id` |
| `spoiler` | ✓ | event | — | Long content collapsed behind Show more / Show less | `expanded` `show_label` `hide_label` `preview` `on_toggle` `color` `padding` |
| `collapsible` | ✓ | event | — | One trigger, one region (WAI-ARIA disclosure) | `title` `open` `disabled` `on_toggle` `chevron` `background` `color` `corner_radius` `padding` |
| `accordion` | — | — | — | Stack of disclosure items; slot tag `<AccordionItem>`; `expand/3` only | `open` `multiple` `collapsible` `disabled` `on_toggle` `on_open_change` `on_value_change` `chevron` `background` `color` `corner_radius` `padding` `space` |
| `splitter` | ✓ | color, event | — | Two panes sharing an extent, with a draggable grip (panes are **sized**, not weighted) | `value` `orientation` `extent` `min` `disabled` `grip` `grip_color` `on_change` `id` |

### Layout / structure (4)

| Component | fn | kit | needs | One-liner | Key props |
|---|---|---|---|---|---|
| `scroll_area` | ✓ | — | — | Bounded scrolling region wrapping Mob's native `Scroll`; **`height` is a no-op on iOS** (IOS_TODO #1) | `orientation` `height` `id` `background` `padding` `corner_radius` |
| `scroller` | ✓ | — | action_icon, scroll_area | Horizontal rail with prev/next arrows; arrows call `nudge/3` on an `id`'d scroll view | `id` `on_prev` `controls` `height` `space` |
| `separator` | ✓ | — | — | Thematic rule between groups, optionally with a centred label | `orientation` `label` `color` `thickness` `space` `id` |
| `visually_hidden` | ✓ | — | — | Renders **nothing** — "the one component in this port that cannot do its job" (no a11y tree) — **no doc** | — |

### Overlays (9)

| Component | fn | kit | needs | One-liner | Key props / slot tags |
|---|---|---|---|---|---|
| `dialog` | ✓ | event | — | Centred modal over a dimmed backdrop (`:box` stacking `[scrim, panel]`) | `id` `open` `modal` `title` `description` `actions` `dismissible` `on_close` `on_open_change` `width` `background` `corner_radius` `padding` `inset` `scrim_color`; slots `<DialogTitle> <DialogDescription> <DialogFooter> <DialogTrigger>` |
| `alert_dialog` | ✓ | event | dialog | Confirmation modal that demands a choice — `dismissible` forced `false`, `modal` forced `true` | Dialog's props minus those two; slot `<AlertDialogAction text id variant on_tap close>` (variants `:neutral` `:primary` `:danger`) |
| `drawer` | — | anchored, event | — | Edge-anchored sliding panel **with real gestures**: drag handle, swipe-to-dismiss, snap points, edge swipe-in area. `side: :bottom` ⇒ a bottom sheet | `open` `id` `side` `size` `title` `description` `header` `handle` `handle_color` `scrim` `scrim_color` `dismissible` `background` `padding` `corner_radius` `snap_points` `snap` `extent` `snap_sequential` `threshold` `swipe_direction` `swipe_area` `on_close` `on_swipe`; helper `swipe/3`; slots `<DrawerTrigger> <DrawerFooter>` |
| `popover` | ✓ | anchored, event | — | Trigger toggling an arbitrary panel beside it, in its own window | `id` `open` `trigger` `on_open_change` `open_on_hold` `side` `align` `side_offset` `align_offset` `flip` `clamp` `edge_padding` `title` `description` `close` `arrow` `width` `background` `corner_radius` `padding` `border_color`; slots `<PopoverTrigger> <PopoverTitle> <PopoverDescription> <PopoverClose> <PopoverArrow>` |
| `tooltip` | ✓ | anchored, event | — | Short hint; **long press is the hover** | `text` `open` `side` `align` `side_offset` `align_offset` `arrow` `on_open_change` `on_tap` `close_on_tap` `background` `color` `text_size` `fill_width` `id` |
| `preview_card` | ✓ | anchored, event | avatar, popover | Hold a trigger, get a detail card (avatar + title + subtitle + description) | `id` `open` `trigger` `on_hold` `on_tap` `on_dismiss` `side` `align` `arrow` `arrow_color` `title` `subtitle` `description` `initials` `avatar_color`; slot `<PreviewCardTrigger>` |
| `menu` | ✓ | anchored, event | popover | List of actions from a trigger; shares `Popover.panel/2` | `open` `on_select` `width` `danger_color`; slots `<MenuItem> <MenuLabel> <MenuSeparator> <MenuCheckbox> <MenuRadio> <MenuSubmenu>` |
| `context_menu` | ✓ | anchored, event | menu | The actions for a particular row/object — **no doc** | `for_label` |
| `floating_window` | ✓ | color, event | — | Titled panel dragged by its title bar over a stage; the drag is real (`on_drag` on a canvas) | `x` `width` `bounds` `step` `label` `handle` `dragging` `show_nudges` `on_move` `on_close` `id`; slot `<FloatingWindowHandle>` |

### Feedback (8)

| Component | fn | kit | needs | One-liner | Key props |
|---|---|---|---|---|---|
| `progress` | ✓ | — | — | Determinate/indeterminate bar; wraps Mob's native `Progress` (linear only — there is no circular option) | `value` `min` `max` `label` `show_value` `value_text` `color` `height` |
| `meter` | ✓ | — | progress | Scalar gauge for a measurement in a known range (disk, battery) | same shape as progress |
| `semi_circle_progress` | ✓ | — | progress | Half-circle arc gauge drawn on canvas | `value` `min` `label` `value_text` `color` `size` `thickness` |
| `skeleton` | ✓ | — | — | Grey placeholder blocks. **Does not shimmer** and the moduledoc explains exactly why | `shape` (`:text` `:circle` `:rect`) `width` `height` `size` `lines` `last_line` `gap` `color` `corner_radius` `id` |
| `loading_overlay` | ✓ | — | — | Scrim over a region while it is busy (animates for free via Progress) | `visible` `label` `scrim_color` `panel_color` `color` `corner_radius` |
| `toast` | ✓ | event | action_icon | Transient messages stacked at a screen edge; ships a nested `Toast.Queue` module (push/dismiss/expire, `limit`, sticky) | `toasts` `position` `on_dismiss` `close_icon` `padding` `space`; slots `<ToastItem> <ToastClose>` |
| `empty_state` | ✓ | — | — | Placeholder for an empty list: indicator, title, description, actions row | `title` `description` `align` `indicator` `padding`; slots `<EmptyStateIndicator> <EmptyStateActions>` |
| `separator` | *(also listed under layout)* | | | | |

### Navigation (8)

| Component | fn | kit | needs | One-liner | Key props |
|---|---|---|---|---|---|
| `tabs` | ✓ | event | — | Inline tab strip above one visible panel. **Deliberately not Mob's `TabBar`** (which is bottom nav) | `active` `on_change` `indicator` `color` `space` `scrollable` `id`; slot `<Tab id label>` |
| `nav_link` | ✓ | event | — | Nav row: leaf or disclosure holding nested links | `id` `label` `description` `icon` `trailing` `active` `opened` `default_opened` `disabled` `href` `indent` `on_tap` `on_toggle` |
| `anchor` | ✓ | event | — | A link — a tappable `Text` + a destination — **no doc** | `label` `href` `on_tap` `color` `underline` `text_size` `disabled` |
| `menubar` | ✓ | anchored, event | — | Bar of menus, at most one open — **no doc** | `menus` `open` `disabled` `on_open` `on_select` |
| `navigation_menu` | ✓ | anchored, event | — | Nav whose expandable items share one content area — **no doc** | `items` `value` `orientation` `disabled` `on_open` `on_link` |
| `toolbar` | ✓ | event | — | Strip of grouped controls with separators and overflow | `id` `orientation` `disabled` `on_select` `on_hold` `on_input` `on_overflow` `hint` `overflow` `visible` `space` `height` `background` `padding` `group_background` `item_color` `link_color`; slots `<ToolbarButton> <ToolbarInput> <ToolbarLink> <ToolbarSeparator>` |
| `floating_indicator` | ✓ | event | — | One highlight marking the active target, moved by **state** not measurement — **no doc** | `targets` `active` `orientation` `color` `disabled` `on_change` |
| `tree` | ✓ | event | checkbox | Hierarchical expandable / selectable / checkable tree; async child loading | `nodes` `expanded` `selected` `checked` `loading` `with_checkboxes` `check_strictly` `with_expand_icon` `expand_icon` `loader_icon` `with_lines` `level_offset` `expand_on_click` `select_on_click` `allow_range_selection` `on_expand` `on_select` `on_load_children` `on_range_select`; slot `<TreeNode>`; helpers `toggle_expand/2` |

### Data display (8)

| Component | fn | kit | needs | One-liner | Key props |
|---|---|---|---|---|---|
| `avatar` | ✓ | — | — | Square image with stacked text fallback; `Image` is Coil / AsyncImage → **URL fetch + caching for free** | `src` `initials` `size` `shape` (`:circle` `:rounded` `:square`) `background` `color` `text_size` `id` |
| `pill` | ✓ | event | — | Compact label with an optional trailing ✕ (a token/tag) | `label` `with_remove` `on_remove` `on_tap` `disabled` `background` `color` `disabled_color` |
| `color_swatch` | ✓ | event | — | Block of one colour, optionally selectable, with a transparency checkerboard | `color` `size` `shape` `selected` `on_tap` `disabled` `checkerboard` `id` |
| `theme_icon` | ✓ | event | — | Themed container around exactly one icon (variants, gradient, radius) | `variant` `id` `icon` `label` `color` `size` `radius` `gradient` `icon_color` `on_tap` `on_long_press` |
| `rolling_number` | ✓ | — | — | Number that "counts up" — **the roll is the screen's**, the component renders a value | `value` `separator` `text_size` `color` |
| `number_formatter` | ✓ | — | — | Number with grouping/decimals/prefix/suffix; `format/2` is pure — **no doc** | `value` `decimals` `thousand_separator` `decimal_separator` `prefix` `text_size` |
| `overflow_list` | ✓ | event | — | One row of items, the rest collapsed into `+N`. **Count is declared, not measured** | `visible` `min_visible` `space` `counter_text` `on_counter` `id` |
| `marquee` | ✓ | — | scroll_area | Content that scrolls past — **the continuous animation is NOT ported** — **no doc** | `repeat` `space` `height` `id` |

### Typography (4)

| Component | fn | kit | needs | One-liner | Key props |
|---|---|---|---|---|---|
| `code` | ✓ | — | — | Inline code / code block; `Text` `font: "monospace"` gets the real platform mono face | `text` `block` `background` `color` `text_size` `padding` `scroll` `id` |
| `mark` | ✓ | — | — | Highlighted run of text (a `Text` inside a tinted `Box`) | `text` `background` `color` `text_size` |
| `highlight` | ✓ | — | mark | Text with matching substrings marked (search results) | `text` `highlight` `case_sensitive` `wrap_at` `line_space` `background` `color` `text_color` `text_size` |

### Buttons (4)

| Component | fn | kit | needs | One-liner | Key props |
|---|---|---|---|---|---|
| `action_icon` | ✓ | event | — | Compact icon-only button (finger-sized tap target) | `icon` `on_tap` `disabled` `size` `variant` `shape` `color` `background` |
| `close_button` | ✓ | — | action_icon | Action icon with ✕ and `:circle` baked in — **no doc** | everything `action_icon` takes |
| `burger` | ✓ | event | — | Three-bar nav button folding into ✕; drawn from boxes not a glyph — **no doc** | `opened` `on_toggle` `disabled` `size` `color` |
| `theme_icon` | *(listed under data display)* | | | | |

### Colour engine (kit, not components)

| Module | What |
|---|---|
| `Event` (`priv/mob/kit/event.eex`) | `handler/1` widens a bare tag into `{screen_pid, tag}`; `handler/2` for per-item values. **Never `handler({tag, value})`** — `Mob.Composite` pre-widens tag props, so composing gives `{self(), {{pid,:check}, value}}` and no `handle_info` clause matches (this "broke ten components at once") |
| `Color` (`priv/mob/kit/color.eex`) | `parse/1` `valid?/1` `hex/1` `argb/2` `hsv_to_rgb/3` `rgb_to_hsv/1` `hue_rgb/1` `hsv_to_hex/3` `hex_to_hsv/2` `light?/1` `ink_on/1` `wrap_hue/1` `clamp/3` — all doctested |
| `Anchored` (`priv/mob/kit/anchored.eex`) | Builds `%{type: :anchored, …}` with exactly two children (anchor in flow, panel over the page). **See §4.0 — this node type is not rendered by `mob` itself.** Props: `side` `align` `side_offset` `align_offset` `flip` `clamp` `edge_padding` `on_tap` (= dismiss) |

**13 components have no `usage-rules/mob/` doc:** `anchor`, `burger`, `close_button`, `context_menu`,
`fieldset`, `floating_indicator`, `marquee`, `mask_input`, `menubar`, `navigation_menu`,
`number_formatter`, `pills_input`, `visually_hidden`.

---

## 3. Styling model — there is no CSS, there are tokens

### 3.1 Two layers

1. **`Mob.Theme` — a compiled struct of semantic design tokens**, global to the app.
2. **Per-component colour/size props**, which default to those tokens.

`Mob.Theme` (`development/mob/deps/mob/lib/mob/theme.ex:85-123`):

```elixir
defstruct [
  primary: :blue_500,   on_primary: :white,
  secondary: :gray_600, on_secondary: :white,
  surface: :gray_800,   surface_raised: :gray_700,  on_surface: :gray_100,
  muted: :gray_500,
  background: :gray_900, on_background: :gray_100,
  error: :red_500,      on_error: :white,
  border: :gray_700,
  type_scale: 1.0, space_scale: 1.0,
  radius_sm: 6, radius_md: 10, radius_lg: 16, radius_pill: 100,
  glass: false
]
```

Spacing tokens are derived (`theme.ex:127-133`): `space_xs: 4`, `sm: 8`, `md: 16`, `lg: 24`, `xl: 32`,
each multiplied by `space_scale`.

The renderer resolves tokens at render time (`renderer.ex:170-175`, `:478-520`):

```elixir
@color_props   ~w(background text_color border_color color placeholder_color)a
@spacing_props ~w(padding padding_top padding_right padding_bottom padding_left gap)a
@radius_props  ~w(corner_radius)a
@size_props    ~w(text_size font_size)a
```

Colour resolution is two-step (`renderer.ex:527-541`): semantic token → palette atom → ARGB int
(`:primary → :blue_500 → 0xFF2196F3`). An **ARGB integer is always accepted in place of a token**.

### 3.2 How a component consumes it — real code

`priv/mob/chip.eex:73-108` (this is the whole styling surface of a Chelekom Mob component):

```elixir
node = ~MOB"""
<Box fill_width={false} background={fill} corner_radius={:radius_pill} padding={:space_sm}>
  <Text text={label} text_size={:base} text_color={ink} />
</Box>
"""

defp background(props, checked?, disabled?) do
  cond do
    checked? and disabled? -> :muted
    checked?               -> Map.get(props, :color, :primary)
    true                   -> :surface_raised
  end
end

defp text_color(props, checked?, disabled?) do
  cond do
    checked? and disabled? -> Map.get(props, :text_color, :on_primary)
    disabled?              -> :muted
    checked?               -> Map.get(props, :text_color, :on_primary)
    true                   -> :on_surface
  end
end
```

So: **hardcoded semantic tokens as defaults, overridable per call via props.** Some values are *not*
token-driven — `corner_radius={:radius_pill}` and `padding={:space_sm}` are baked in here; other
components expose `corner_radius` / `padding` props (`toggle`, `collapsible`, `dialog`, `drawer`,
`segmented_control`, `scroll_area`, `fieldset`, `theme_icon`, …).

### 3.3 Restyling wholesale

Four escalating levers:

1. **Swap the theme** — `use Mob.App, theme: MobThemes.Obsidian` or `theme: [primary: :emerald_500,
   type_scale: 1.1]`, or at runtime `Mob.Theme.set({MobThemes.Obsidian, primary: :rose_500})`
   (`theme.ex:11-36`, `:141`, `:156-172`). Any module exporting `theme/0` returning a `%Mob.Theme{}`
   works, so you can publish `Kati.BrandTheme`. `Mob.Theme.set/1` also pushes the resolved palette to
   the native side so Compose `MaterialTheme` / the SwiftUI environment follow (`:204-220`).
2. **Pass props per call site** — every colour prop accepts a token or a raw `0xAARRGGBB` int.
3. **`%Mob.Style{}`** (`deps/mob/lib/mob/style.ex`) — a named, reusable props bundle merged into a node's
   props at serialisation time; inline props win. Useful for your own wrappers, but Chelekom components
   do not thread a `style` prop through.
4. **Fork the generated module.** This is the intended path for a real design system. The components are
   *vendored into your repo* (`lib/<app>/components/*.ex`), not a dependency — so editing
   `chip.ex`'s `background/3` is a supported act. The only caveat: re-running the generator uses
   `on_exists: :overwrite` (`mishka.ui.gen.mob.ex:232-240`), so a re-run silently reverts your edits.
   Generate once, then own the files (or generate with `--module-prefix` into a namespace you never
   regenerate).

There is **no theme struct threaded through component functions** and **no per-component style map**.
For a heavily branded app the realistic model is: set `Mob.Theme` for the global palette, then fork.

---

## 4. What is genuinely missing for a rich media / calendar mobile app

### 4.0 First, the biggest structural gap: `:anchored` is not in `mob`

13 components declare `kit: ["anchored"]` — `autocomplete`, `color_input`, `combobox`, `context_menu`,
`drawer`, `menu`, `menubar`, `navigation_menu`, `popover`, `preview_card`, `select`, `tooltip`,
`tree_select`. They build `%{type: :anchored, …}` nodes.

`grep -rn anchored development/mob/deps/mob/lib development/mob/deps/mob/priv` returns **nothing**.
The node type is rendered by `development/mob/android/app/src/main/java/com/example/mishka_mob/MobBridge.kt`
(`MobAnchored`, `:2436`, `:2471`) — **the demo app's own hand-written Kotlin**, which the generator does
not ship. On iOS it does not exist at all; `IOS_TODO.md:271-296` documents the consequence precisely:

> "`mob_nif.m`'s `mob_node_from_dict` maps the type string through an `if`/`else if` chain … that ends
> at `"gpu_view"` with **no else**, so an unrecognised type leaves `node.nodeType` at the
> zero-initialised value — which is `MobNodeTypeColumn` … An anchored node therefore renders as a plain
> `VStack` of `[trigger, panel]`: exactly the stacked accordion the node type was built to replace."

And the trap (`IOS_TODO.md:299-303`): `Mob.ScreenCase.assert_renderable/2` bakes `@renderable_types`
from the **union** of `ios.txt ++ android.txt`, and `Anchored` is written into *both* files by the
Chelekom fence — *"Nothing in the unit suite can see this gap. Only a device run can."*

**Practical consequence for a consumer app:** generate `popover`/`select`/`menu`/`tooltip` into a fresh
Mob app and their panels will render as in-flow stacked columns on both platforms — pushing siblings
down the page — unless you port `MobAnchored` into your own `MobBridge.kt` (Android) and there is no
iOS answer short of an upstream `mob` change. Budget this before designing around dropdowns.

### 4.1 The checklist

Legend: **F** = exists as a Mob *framework* primitive/prop (usable today, no Chelekom component);
**C** = exists as a Chelekom Mob component; **✗** = neither.

| Want | Status | What exists | What building it would take |
|---|---|---|---|
| **Calendar / date picker / month grid** | ✗ | Nothing. `grep -ci calendar priv/mob` = 0. Headless (web) has `calendar` (`priv/headless/calendar.eex`) but there is no Mob port | A month grid is 7×6 `Box`es in `Column`s of `Row`s — but **`Row` does not wrap and reports no geometry**, so the grid must be chunked by a declared count (the `pill`/`overflow_list` pattern). All date maths in Elixir (`Date.beginning_of_month`, `Date.day_of_week`). Realistically ~400–600 LOC + a `date_field` trigger. Highest-value single addition |
| **Agenda / timeline view** | ✗ | Nothing named that | Composable today from `scroll_area` + `separator` + `nav_link`-shaped rows. A real agenda wants **sticky day headers** — see below |
| **Image / poster from URL with caching** | **F** | Mob's `Image` tag; `avatar.eex:16-17`: *"`Image` is backed by Coil (Android) / AsyncImage (iOS), which handles fetching and caching."* Props seen in use: `src` `width` `height` `corner_radius` `content_mode="fill"` `description` (the one a11y hook in the whole bridge) | Nothing framework-side. A `poster` / `media_card` Chelekom component (aspect-ratio box, placeholder, rounded corners, tap) is a thin ~80-line wrapper. `src` also resolves `plugin://…` paths (`renderer.ex:513-519`) |
| **Lazy / virtualised list** | **F** | `LazyList` primitive + `Mob.List` (`type: :list`) which expands to `:lazy_list` with a per-row renderer registered via `Mob.List.put_renderer/3` (`deps/mob/lib/mob/list.ex:100-121`) | No Chelekom wrapper. Note `Mob.List.expand/3` **eagerly maps every item** into a node before handing it to the lazy list — it virtualises *drawing*, not *node building*. For a very long media list you may want to page the data yourself |
| **Pull-to-refresh** | ✗ | No `refresh` prop anywhere in `mob` | Closest primitives: `on_top_reached` (`renderer.ex:437`) + `on_swipe_down` (`:374`). A convincing pull-to-refresh needs a native gesture-driven indicator; nothing exposes one. Would need upstream `mob` work or a custom `MobBridge.kt` node |
| **Swipe actions (swipe a row to reveal)** | **F**(partial) | `on_swipe`, `on_swipe_left/right/up/down` are first-class renderer props (`renderer.ex:362-375`); `on_drag` (`:396`) with throttle config | Discrete swipe **events** exist; the *reveal animation* does not (Mob has no animation, per `skeleton.eex`). A "swipe left → row jumps to the action state" is implementable as a state flip; a finger-tracking reveal is not |
| **Bottom tab bar** | **F** | Mob's `TabBar` tag — a Compose `Scaffold` + Material `NavigationBar` pinned to the bottom, `on_tab_select` (`renderer.ex:341`). `tabs.eex:6-17` explicitly says *"When you do want bottom navigation, use `TabBar` directly; it is the right widget for that job"* | Nothing needed — use `TabBar`. A Chelekom wrapper would add little |
| **App bar / header** | ✗ | No `app_bar` / `header` component; `TabBar` brings a `Scaffold` but that is bottom nav | Trivial to hand-roll (`Row` + `action_icon` + `Text`), but the **"first child of a Row takes every pixel"** trap applies — later children get zero width. Any header component must `fill_width={false}` its actions (see the repo skill, §7) |
| **Search field** | ✗(as such) | `autocomplete` / `combobox` are the nearest; Mob's `TextField` is the primitive | A `search_field` (leading glyph, clear ✕, debounce hint, `on_query`) is a ~120-line component; `combobox` already contains most of the parts |
| **Carousel** | ✗ | Headless has `carousel`; no Mob port | `scroll_area(orientation: :horizontal)` gives the rail and `scroller` gives arrows. No snapping, no page indicator, no `on_scroll`-driven index without wiring `on_scroll {pid, tag, throttle: …}` yourself |
| **Star rating** | ✗ | Nothing | Trivially a `Row` of tappable `Text` glyphs (★/☆) or `theme_icon`s + `on_tap` carrying the index. ~60 lines |
| **Badge / counter** | ✗(as a component) | `pill` and `chip` are the closest; `overflow_list` renders a `+N` counter | A `badge` (dot, count, positioned over a child) needs a `:box` stack + explicit offsets. Small |
| **Chart / sparkline** | ✗ | **Headless only** — `priv/headless/sparkline.{eex,exs}` and the `Chart` component (ECharts/Chart.js/billboard). `ls priv/mob | grep -c chart` = 0 | Mob has `Mob.UI.canvas/1` with a `draw:` op list (`renderer.ex:466-470`) — the same primitive `hue_slider`, `angle_slider` and `semi_circle_progress` already draw with. A sparkline/line chart is genuinely feasible as a canvas component |
| **Video player** | **F**(stub) | `Video` tag is whitelisted; `android.txt:6` says *"Video is a stub pending ExoPlayer integration."* A `mob_video` capability package exists (`skeleton.eex:33-36` lists the published `mob_*` packages) | For real playback, use the `mob_video` plugin. No Chelekom component |
| **Pager / swipe between pages** | ✗ | `on_swipe_left/right` + `Mob.Nav` | Discrete page flip on swipe is doable today; an interactive tracking pager is not (no animation, no mid-gesture geometry) |
| **Sticky headers** | **F** | `sticky_when_scrolled_past` is a **native-side, Tier-3 scroll-driven primitive** (`renderer.ex:459-461`) that never round-trips to the BEAM. Siblings: `parallax`, `fade_on_scroll` (`:453-457`) | Not used by any Chelekom component. Wiring it into an agenda/section-list is a config map on a node — cheap, and the highest-leverage thing here for a calendar |
| **Snackbar** | **C**(≈) | `toast` — position, stacking, `limit`, auto-dismiss, sticky, `<ToastClose>`, plus a `Toast.Queue` module for push/expire | Rename, essentially. `Mob.Alert` (`deps/mob/lib/mob/alert.ex`) also offers a native bottom action sheet |
| **Bottom sheet with drag** | **C** | `drawer` with `side: :bottom`, `handle: true`, `snap_points: [180, 300, 440]`, `swipe_area`, and `Drawer.swipe/3` folding the drag in the screen | Exists. Caveat (`drawer.eex:58-67`): **the panel does not follow the finger** — it settles on release only, because a canvas reports canvas-local coordinates and Mob has no animation |
| **Shimmer** | ✗ | `skeleton` is deliberately **static**. `skeleton.eex:6-36` is the definitive analysis: ordinary nodes expose no opacity/alpha/transition; `Mob.UI.gpu_view/1` could do it as a fragment shader but *"the host provides no time uniform, so animating means pushing a new uniform from Elixir on every frame — a full render plus a NIF call at 60 Hz, per placeholder"*, and each is a whole GLSurfaceView | Not worth it. Use `progress` / `loading_overlay` for "work is happening" |
| **Infinite scroll** | **F** | `on_end_reached` (`renderer.ex:338`) passes through `Mob.List` props (`list.ex:118`) | Just wire it. No component needed |

### 4.2 Cross-cutting platform walls that shape any new component

From `usage-rules/mob/README.md:56-58` and the repo's own skill file:

* **Three layouts — `Box`, `Column`, `Row` — and nothing wraps.** A `Row` runs off the edge. No geometry
  is reported back to `render/1`, so wrapping means chunking by a **declared** count.
* **A `Box` with neither `width` nor `fill_width` fills its parent.** Anything meant to hug needs
  `fill_width={false}`.
* **A `Row`'s first child takes every pixel it asks for** — later children measure to zero width, stay
  in the tree with working handlers, and only a finger on a device can tell. `weight` is *not* the fix
  (Mob's iOS renderer does not implement `Modifier.weight`).
* **A `Column` cannot align its children** — `align` is read for `Box` and `Row` only.
* **No animation anywhere** except Material's linear progress indicator.
* **No accessibility tree** — `Image`'s `description` prop is the single exception.

---

## 5. Branch / version reality

### 5.1 master vs `feat/headless-daisyui-skin`

```
$ git merge-base master HEAD        → a053bf4b   (= master's tip)
$ git rev-list --count master..HEAD → 108
$ git rev-list --count HEAD..master → 0
$ git diff --stat master..HEAD -- priv/mob usage-rules/mob \
      lib/mishka_chelekom/generators/mob.ex lib/mishka_chelekom/generators/mob/ \
      'lib/mix/tasks/mishka*mob*' development/mob
                                    → (empty)
```

**Mob is identical on both.** The 108 commits are the daisyUI headless skin, the CMS bundle exporter,
and headless fixes. `Chart` and `Sparkline` (mentioned in master's log) are **headless/web only** —
`priv/headless/sparkline.eex` exists, `priv/mob/sparkline.eex` does not.

So there is no reason to prefer this branch over `master` for Mob, and no reason to fear master is
behind.

### 5.2 How a consumer depends on it — and two blockers

`mix.exs:4` → `@version "0.0.10-alpha.6"`. Consumers of the styled/headless kit normally use
`{:mishka_chelekom, "~> 0.0.x", only: [:dev], runtime: false}`.

**Blocker A — `priv/mob` is not in the hex package.** `mix.exs:117-119` (identical on master, `:105-107`):

```elixir
files: ~w(lib .formatter.exs mix.exs LICENSE README* MCP.md usage-rules.md usage-rules
     priv/assets priv/demos priv/headless
     priv/components/*.exs priv/components/*.eex),
```

`priv/mob` is absent. `Core.template_dir(:mob)` resolves to `Core.lib_priv("mob")` →
`:code.priv_dir(:mishka_chelekom) <> "/mob"` (`core.ex:36-45`, `:74`, `:152`). On a hex install that
directory does not exist, so `mix mishka.ui.gen.mob chip` fails with *"Mob component "chip" not found in
priv/mob/"*. **A hex dependency cannot generate Mob components today.** (`usage-rules/` *is* shipped, so
the docs would arrive without the code.)

**Blocker B — master's `mix.exs` carries two path deps.** `mix.exs:59-70`:

```elixir
# LOCAL DEVELOPMENT ONLY — restore the hex versions before release:
{:igniter_js, path: "../igniter_js", override: true},
{:igniter_css, path: "../igniter_css", override: true},
```

A `git:` dependency on master will therefore fail to resolve in a consumer app — the sibling checkouts
do not exist there.

**What "latest master" would look like anyway:**

```elixir
{:mishka_chelekom, github: "mishka-group/mishka_chelekom", branch: "master", only: [:dev], runtime: false}
# or pinned:
{:mishka_chelekom, github: "mishka-group/mishka_chelekom", ref: "a053bf4b", only: [:dev], runtime: false}
```

Note a git dep still resolves `priv/` through `:code.priv_dir/1`, and the git checkout *does* contain
`priv/mob` — so **git works where hex does not**, provided Blocker B is dealt with (fork and swap the
two path deps back to hex, or vendor).

**Most robust option for a consumer:** clone the repo next to your app and use
`{:mishka_chelekom, path: "../mishka_chelekom", only: [:dev], runtime: false}` — path deps get the full
tree, `Core.lib_priv_dir/1` handles path deps explicitly, and you control the two local deps.

The generated code itself depends only on `{:mob, "~> 0.7"}` (`registry.ex:337-346`) — Chelekom is a
dev-time code generator, never a runtime dependency of the Mob app.

---

## 6. Testing conventions

Three tiers, deliberately separated.

### 6.1 Library-side unit tests (`test/`, in `mishka_chelekom`)

| File | LOC | Covers |
|---|---|---|
| `test/mishka_chelekom/generators/mob_test.exs` | 276 | Catalog invariants + `doctest MishkaChelekom.Generators.Mob` |
| `test/mix/tasks/mishka.ui.gen.mob_test.exs` | 382 | Location, module, kit, siblings, prefixes, registry, boot wiring, tag whitelist |
| `test/mix/tasks/mishka.ui.gen.mob.components_test.exs` | 246 | Batch generation |
| `test/mix/tasks/mishka.ui.uninstall_mob_test.exs` | 214 | `--mob` targeting + registry/whitelist rebuild |

House pattern (`mishka.ui.gen.mob_test.exs:1-21`):

```elixir
defmodule Mix.Tasks.Mishka.Ui.Gen.MobTest do
  use ExUnit.Case
  import MishkaChelekom.ComponentTestHelper
  alias Mix.Tasks.Mishka.Ui.Gen.Mob
  @moduletag :igniter

  setup do
    Application.ensure_all_started(:owl)
    MishkaChelekom.ComponentTestHelper.setup_config()
    on_exit(fn -> MishkaChelekom.ComponentTestHelper.cleanup_config() end)
    :ok
  end

  defp content(igniter, path) do
    case igniter.rewrite.sources[path] do
      nil -> nil
      source -> Rewrite.Source.get(source, :content)
    end
  end

  defp gen(args), do: test_project_with_formatter() |> Igniter.compose_task(Mob, args)
```

…and an assertion reads (`:34-39`):

```elixir
test "--module-prefix moves both the file and the module" do
  igniter = gen(["chip", "--module-prefix", "mishka_", "--yes"])

  assert content(igniter, "lib/test/components/mishka_chip.ex") =~
           "defmodule Test.Components.MishkaChip do"
end
```

Every test asserts on **generated text**, because the library does not depend on `:mob` and cannot
compile a Mob component. Catalog tests are filesystem-driven (`mob_test.exs:15-16`,
`@templates Path.wildcard("priv/mob/*.eex")`) with a guard against vacuous passes:

```elixir
test "there is a catalog to check at all" do
  assert length(@templates) > 50,
         "the wildcard matched nothing — every test in this file would pass vacuously"
end
```

Invariants asserted: every `.eex` has a `.exs` and vice versa; every catalog passes
`Core.validate_catalog/1`; `:name` matches the filename; every `necessary` entry names an existing
component; every `doc_url` is `/chelekom/docs/mob/<hyphenated>`; no template leaks `MishkaMob`.

### 6.2 Round-trip test (`development/mob/test/mishka_mob/generated_components_test.exs`, 299 lines)

The strongest tier. Its moduledoc (`:17-35`) states why it lives in the demo app:

> "`mishka_chelekom` cannot run it. It does not depend on `mob`… The library's own tests can only assert
> on the *text* a generator produces. Text is not the property that matters… So this asserts the strong
> version: rendered → compiled → invoked → identical."

Each `priv/mob/*.eex` is `EEx.eval_file`'d, `Code.compile_string`'d into `Generated.Plain.*` /
`Generated.Pfx.*` / `Generated.Live.*`, then:

```elixir
test "every component renders a node tree identical to the one we ship" do
  for path <- templates() do
    name = component_name(path)
    generated = compiled_module(Generated.Plain, "", name)
    shipped = Module.concat([MishkaMob.Components, "Mishka#{Macro.camelize(name)}"])

    assert generated.expand(%{}, [], %{screen: self()}) ==
             shipped.expand(%{}, [], %{screen: self()}),
           "#{name} renders differently after generation"
  end
end
```

plus `assert_renderable(…, extra: [:canvas])`, `function_exported?(module, :expand, 3)`, the
prefix round-trip, and a check that `Toast.Queue` travels inside the toast template.

### 6.3 Per-component tests (`development/mob/test/mishka_mob/components/*_test.exs`, 59 files)

`use Mob.ScreenCase, async: false` (async false — `Mob.ScreenCase` starts the globally-named
`Mob.State`). Helpers: `text/1`, `find/2`, `find_all/2`, `assert_renderable/1,2`.

Real example, `development/mob/test/mishka_mob/components/mishka_chip_test.exs:42-108`:

```elixir
describe "checked state" do
  test "unchecked reads as a raised surface with normal text" do
    node = MishkaChip.chip(label: "Elixir")

    assert node.props.background == :surface_raised
    assert find(node, :text).props.text_color == :on_surface
  end
end

describe "the handler" do
  test "a bare tag is widened to {pid, tag}" do
    assert MishkaChip.chip(label: "E", on_toggle: :pick).props.on_tap == {self(), :pick}
  end

  test "a tuple tag is widened too, so one handler can serve many chips" do
    assert MishkaChip.chip(label: "E", on_toggle: {:tag, :elixir}).props.on_tap ==
             {self(), {:tag, :elixir}}
  end
end

describe "composite tag" do
  test "expand/3 delegates to chip/1 and ignores children" do
    children = [%{type: :text, props: %{text: "ignored"}, children: []}]

    assert MishkaChip.expand(%{label: "E"}, children, %{screen: self()}) ==
             MishkaChip.chip(label: "E")
  end
end

test "every variant renders" do
  for props <- [%{}, %{label: "E"}, %{label: "E", checked: true}, %{label: "E", disabled: true}] do
    assert_renderable(MishkaChip.chip(props))
  end
end
```

Note the regression comments carried inline (`:87-89`): *"This used to assert both were
`:surface_raised`, which pinned the bug: a locked-ON chip looked exactly like a locked-OFF one."*
That is the house style — a test names the defect it locks out.

### 6.4 On-device e2e (`development/mob/android/app/src/androidTest/…`, 52 Kotlin files)

Compose UI tests, one per component (`ChipTest.kt`, `DrawerTest.kt`, …), run with `mix e2e <Name>Test`.
They assert what the node tree cannot: geometry, hit-testing, real round trips. Two rules from the repo
skill: **`mix android` before `mix e2e`** (e2e only builds Kotlin, it does not push BEAM files), and
**`performScrollTo` before measuring** (an off-screen node reports `(0,0,0,0)` whatever its layout).

---

## 7. Extension path

The repo encodes its own definition of done in `.claude/skills/mob-component-fix/SKILL.md` (present on
both branches). Its opening line: *"Fixing the reported bug is **one seventh** of the job."*

### 7.1 Adding a NEW Mob component

Work in `development/mob` unless noted.

1. **Write the component** — `development/mob/lib/mishka_mob/components/mishka_<name>.ex`, module
   `MishkaMob.Components.Mishka<Name>`. Contract:
   * `def expand(props, children, ctx)` — the composite protocol. **Never prefixed.**
   * `def <name>(props \\ %{}, children \\ [])` returning a node map — this is what
     `--component-prefix` moves. Omit it only for composite-only components (accordion/drawer).
   * Reach siblings **through an `alias`** (`alias MishkaMob.Components.MishkaActionIcon`) — that alias
     line is the *only* signal `Mob.siblings/1` reads to build `necessary:`.
   * Route every `on_*` prop through `Event.handler/1` (or `/2` for per-item values). Skipping this
     yields a control that renders perfectly and does nothing.
   * Give text-less / drawn / icon-only controls an `:id` (a native testTag) — it is the only handle a
     device test has. Suffix multiples (`<id>-area`, `<id>-hue`, `<id>-0`).
   * Watch the four layout traps in §4.2.
   * Slot tags are legal: match children on `:type` and consume them in `expand/3`; add the new slot tag
     to `@slot_tags` in `development/mob/lib/mishka_mob/showcase.ex`.

2. **Showcase** — `development/mob/lib/mishka_mob/showcase/components/<name>.ex`, `use
   MishkaMob.Showcase`, implement `entry/0` (slug, name, category, order, description) and `examples/0`
   (`%MishkaMob.Showcase.Example{title:, description:, code:, render:}`). Register in
   `MishkaMob.App.on_start/0`. If the component has any `on_*` prop, the `code:` sample **must show the
   `handle_info` clause** — `grep -c "handle_info" lib/mishka_mob/showcase/components/<name>.ex`.

3. **Unit test** — `development/mob/test/mishka_mob/components/mishka_<name>_test.exs`, following §6.3.

4. **e2e** — `development/mob/android/app/src/androidTest/java/com/example/mishka_mob/<Name>Test.kt`,
   asserting only what the node tree cannot prove. Then `mix android && mix e2e <Name>Test`.

5. **Sync the catalog** — from the repo root:
   ```bash
   mix mishka.mob.sync --yes            # or --only <name>
   ```
   This writes `priv/mob/<name>.eex` + `.exs` and refreshes `priv/mob/kit/*.eex`.
   `GeneratedComponentsTest` fails if you skip it (`generated_components_test.exs:124-136`:
   *"catalog and app disagree — run `mix mishka.mob.sync`"*).

6. **Check the generated `.exs`** — `category` (lifted from `priv/headless/<name>.exs` if a web
   counterpart exists; add to `@mob_only_categories` in `generators/mob.ex:367` if not, or it lands in a
   bucket called `"mob"`), `doc_url` hyphenated, `necessary`, `mob: [function:, kit:]`.

7. **Usage rule** — `usage-rules/mob/<name>.md`. House order (see `usage-rules/mob/chip.md`):
   `# <name> (mob)` → one-line summary + link to README → `## Generate` → `## What it renders` (an ASCII
   node tree) → `## Example` (markup **plus** the `handle_info` clause) → `## Props` table → `## N things
   to know` → `## Related`. *"Lead with the platform wall the component ran into, not the prop list."*

8. **CHANGELOG.md** — append `- Add \`<Name>\` component for Mob` to the `### Mob (native Android and
   iOS):` section (currently `CHANGELOG.md:80-183`). Prose entries for tasks/behaviour go in the same
   section's opening bullets.

9. **Library tests** — nothing to add; `test/mishka_chelekom/generators/mob_test.exs` is filesystem-driven
   and picks the new component up automatically. Run `mix test` in the repo root.

10. **Verify** (from `development/mob`):
    ```bash
    mix format --check-formatted && mix compile --warnings-as-errors && mix test
    mix deploy --android && mix e2e
    ```

### 7.2 Adding a PROP to an existing component

1. Edit `development/mob/lib/mishka_mob/components/mishka_<name>.ex` — read it with
   `Map.get(props, :new_prop, default)`, and **add a row to the moduledoc `## Props` table** (the table
   is the props contract; `priv/mob/<name>.eex` is generated verbatim from this file).
2. Props check, both directions (skill §5):
   ```bash
   grep -o 'Map.get(props, :[a-z_]*' lib/mishka_mob/components/mishka_<name>.ex | sort -u
   grep -n 'name: "' lib/mishka_mob/showcase/components/<name>.ex
   ```
   Props the component reads but the showcase omits, **and** props the showcase lists that the component
   ignores — *"the second kind is worse: it sends a reader off wiring something inert."*
3. Add a showcase example exercising it (with a handler if it is an `on_*`).
4. Add a test in `development/mob/test/mishka_mob/components/mishka_<name>_test.exs`.
5. `mix mishka.mob.sync --only <name> --yes` from the repo root.
6. Update `usage-rules/mob/<name>.md`'s props table (or create the doc if the component is one of the 13
   without one).
7. CHANGELOG bullet under `### Mob`.
8. If the new prop introduces a **slot tag**, also add it to `@slot_tags` in `showcase.ex` and it will
   flow into the `~MOB` whitelist via `mix.exs`'s fence.

### 7.3 What you do NOT have to touch

* `priv/mob/*.eex` / `*.exs` — generated. Editing them is undone by the next sync.
* `deps/mob/priv/tags/*.txt` in a consumer app — the generator maintains the fence.
* `lib/<app>/components.ex` in a consumer app — rebuilt, not appended, on every run.
* Any list of component names in the library's tests — all filesystem-driven.

---

## Appendix — quick file map

| Concern | Path |
|---|---|
| Derivation engine | `lib/mishka_chelekom/generators/mob.ex` |
| Paths / prefixes | `lib/mishka_chelekom/generators/mob/locations.ex` |
| Registry + tag whitelist | `lib/mishka_chelekom/generators/mob/registry.ex` |
| Single-component task | `lib/mix/tasks/mishka.ui.gen.mob.ex` |
| Batch task | `lib/mix/tasks/mishka.ui.gen.mob.components.ex` |
| Kit task | `lib/mix/tasks/mishka.ui.gen.mob.kit.ex` |
| Maintainer sync | `lib/mix/tasks/mishka.mob.sync.ex` |
| Uninstall (`--mob`) | `lib/mix/tasks/mishka.ui.uninstall.ex` (`:152`, `:421`, `:520-553`) |
| Shared helpers | `lib/mishka_chelekom/generators/core.ex` (`:36`, `:74`, `:152`) |
| Templates + catalogs | `priv/mob/*.eex`, `priv/mob/*.exs`, `priv/mob/kit/*.eex` |
| Consumer docs | `usage-rules/mob/README.md` + 60 component docs |
| Source of truth app | `development/mob/lib/mishka_mob/components/` |
| Showcase | `development/mob/lib/mishka_mob/showcase.ex` + `showcase/components/` (60) |
| Round-trip test | `development/mob/test/mishka_mob/generated_components_test.exs` |
| Device tests | `development/mob/android/app/src/androidTest/java/com/example/mishka_mob/` (52) |
| iOS gaps ledger | `development/mob/IOS_TODO.md` (item 1 = `scroll_area` height; item 17 = `:anchored`) |
| Tag whitelist writeup | `development/mob/TAG_WHITELIST.md` |
| Contribution rules | `.claude/skills/mob-component-fix/SKILL.md` |
| Mob framework (vendored dep, 0.7.20) | `development/mob/deps/mob/lib/mob/{theme,renderer,list,sigil,style,ui}.ex` |
