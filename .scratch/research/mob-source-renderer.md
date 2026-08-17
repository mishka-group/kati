# Mob's Elixir Render Layer — Source-Level Reference

**Status:** verified against source, not docs. Every claim below is traceable to a file and line.
**Date:** 2026-08-17

## 0. Sources of truth used here

| Artifact | Path | Role |
|---|---|---|
| **mob 0.7.20 (pristine)** | `/private/tmp/claude-501/-Volumes-Fast-Arise-Resource-AI-book/c5718512-beef-4e2f-bbc9-14f1d94a1350/scratchpad/mobtar/contents` | **The authority.** Contains `lib/`, `priv/tags/`, `src/mob_nif.erl`, `ios/` (full SwiftUI renderer + NIF), `android/jni/` (Zig NIF only — **no Kotlin**). |
| **mob_new 0.4.20 (pristine)** | `…/scratchpad/mn420/priv/templates/mob.new/android/app/src/main/java/MobBridge.kt.eex` (3635 lines) | The Android renderer. Every app **forks** this at `mix mob.new` time. Also `MobNode.kt.eex`, `MainActivity.kt.eex`. |
| **Mishka dev app fork (read-only)** | `/Users/shahryar/Documents/Programming/Elixir/mishka_chelekom/development/mob/android/app/src/main/java/com/example/mishka_mob/MobBridge.kt` (4607 lines) | A **real, shipping fork**: +1020 / −48 lines vs the template. Proof of what a bridge extension costs. |

> **Do not cite** `mishka_chelekom/development/mob/deps/mob` — Mishka's `mix.exs` `tags/1` alias rewrites `priv/tags/*.txt` on every compile.

### The single most important structural fact

Mob's Android renderer **does not ship with `mob`**. It ships with `mob_new` as an `.eex` **template that every app forks and then owns forever**. There is no upstream to merge from; `mix mob.new` is a one-shot generator. iOS is the opposite: `ios/MobRootView.swift`, `ios/MobNode.h/.m` and `ios/mob_nif.m` ship *inside the `mob` hex package* and are recompiled from the dep on every build.

Consequence for Q10 / issue #32: **Android bridge edits are free of merge cost by construction** (there is nothing to merge — the file is app-owned). iOS edits to `MobRootView.swift` *are* upstream files and would be clobbered by a `mob` version bump; iOS extension must go through `native_view` / `MobNativeViewRegistry` or a patched vendored copy.

---

## 1. Every node type the renderer can emit

### 1.1 How a type atom comes to exist

There is **no node-type table in the Elixir renderer.** `Mob.Renderer.prepare/4` (renderer.ex:256–266) stringifies whatever atom is in `:type`:

```elixir
# renderer.ex:256-266
defp prepare(%{type: type, props: props, children: children}, nif, platform, ctx) do
  defaults = Map.get(@component_defaults, type, %{})
  with_defaults = Map.merge(defaults, props)
  with_theme_flags = inject_theme_flags(type, with_defaults, ctx)

  %{
    "type" => Atom.to_string(type),
    "props" => prepare_props(with_theme_flags, nif, platform, ctx),
    "children" => Enum.map(children, &prepare(&1, nif, platform, ctx))
  }
end
```

Three ways to produce a node map:

1. **Raw map** — `%{type: :column, props: %{}, children: []}`. No validation at all.
2. **`Mob.UI.*` constructors** — only 6 exist: `text/1`, `webview/1`, `camera_preview/1`, `native_view/2`, `canvas/1`, `gpu_view/1`. **There is no `Mob.UI.column/1`, `row/1`, `box/1`, `button/1`, `text_field/1`, …** Those must be written as raw maps or via the sigil.
3. **`~MOB` sigil** — `sigil.ex:490–511`, `resolve_type/2`:

```elixir
# sigil.ex:490-511
defp resolve_type(tag, caller) do
  atom = tag |> Macro.underscore() |> String.to_atom()
  unless MapSet.member?(@known_tags.both, tag) do
    …
    IO.warn(msg, Macro.Env.stacktrace(caller))
  end
  atom
end
```

> **An unknown tag is a compile-time `IO.warn` only. It still compiles and still renders.**
> The whitelist is read at *mob's* compile time from `Application.app_dir(:mob, "priv/tags/*.txt")` (sigil.ex:87–111) — which is why Mishka injects tags into the dep's `priv/` to silence the warning. **Adding a node type costs zero Elixir framework changes.**

Tag → atom is `Macro.underscore/1`: `Text→:text`, `TabBar→:tab_bar`, `WebView→:web_view`, `GpuView→:gpu_view`, `LazyList→:lazy_list`, `CameraPreview→:camera_preview`, `TextField→:text_field`, `MishkaCombobox→:mishka_combobox`, `Anchored→:anchored`.
Footnote: the tag-name parser accepts `.` (sigil.ex:121–124), so `<Mishka.Combobox>` becomes the atom `:"mishka/combobox"` — almost certainly not what you want. Use single PascalCase words.

### 1.2 The whitelist files (verbatim, pristine)

`priv/tags/android.txt` (26 lines) — Box, Button, Column, Divider, Image, LazyList, List, Progress, Row, Scroll, Slider, Spacer, TabBar, Text, TextField, Toggle, Video, CameraPreview, WebView, **GpuView**.
`priv/tags/ios.txt` (25 lines) — identical minus nothing; both lists are the same 20 tags. There is **no iOS-only or Android-only tag** in 0.7.20 despite `resolve_type/2` having branches for that case.

**Notably absent from both whitelists but fully implemented natively:** `Icon`, `Canvas`, `NativeView`. Using `<Icon …/>` or `<Canvas …/>` in a sigil emits a spurious "not in the Mob tag whitelist" warning and works perfectly. `Mob.UI.canvas/1` and `Mob.UI.native_view/2` sidestep the warning entirely because they build the map directly.

### 1.3 Node inventory

Dispatch sites:
- **Android** — `MobBridge.kt.eex:2188` `when (node.type)`.
- **iOS** — `mob_nif.m:598–648` `mob_node_from_dict` (string → `MobNodeType` enum) then `MobRootView.swift:214+` `MobNodeView.body` `switch node.nodeType`.

| `:type` atom | Wire string | Android composable | iOS enum | In whitelist? |
|---|---|---|---|---|
| `:column` | `"column"` | inline `Column` @2189 | `.column` | yes |
| `:row` | `"row"` | inline `Row` @2195 | `.row` | yes |
| `:box` | `"box"` | inline `Box` @2206 | `.box` → `MobBox` | yes |
| `:scroll` | `"scroll"` | inline @2213 | `.scroll` | yes |
| `:text` | `"text"` | `MobText` @2262 | `.label` | yes |
| `:label` | `"label"` | **unhandled → renders nothing** | `.label` (aliased, `mob_nif.m:610`) | no |
| `:button` | `"button"` | `MobButton` @2303 | `.button` | yes |
| `:text_field` | `"text_field"` | `MobTextField` @2332 | `.textField` | yes |
| `:toggle` | `"toggle"` | `MobToggle` @2399 | `.toggle` | yes |
| `:slider` | `"slider"` | `MobSlider` @2419 | `.slider` | yes |
| `:divider` | `"divider"` | `MobDivider` @2443 | `.divider` | yes |
| `:spacer` | `"spacer"` | `MobSpacer` @2454 | `.spacer` | yes |
| `:progress` | `"progress"` | `MobProgress` @2461 | `.progress` | yes |
| `:image` | `"image"` | `MobImage` @2481 | `.image` → `MobImage` | yes |
| `:icon` | `"icon"` | `MobIcon` @2515 | `.icon` | **no** |
| `:lazy_list` | `"lazy_list"` | `MobLazyList` @3303 | `.lazyList` | yes |
| `:tab_bar` | `"tab_bar"` | `MobTabBar` @3337 | `.tabBar` → `MobTabView` | yes |
| `:video` | `"video"` | `MobVideoPlayer` @3284 — **STUB**, draws a black box with the text `"Video: <src>"` | `.video` → `AVPlayerViewController` (real) | yes |
| `:camera_preview` | `"camera_preview"` | `MobCameraPreview` @2572 | `.cameraPreview` | yes |
| `:web_view` | `"web_view"` | `MobWebView` @2639 | `.webView` | yes |
| `:native_view` | `"native_view"` | `MobNativeViewRegistry.render` @2143 | `.nativeView` | **no** |
| `:canvas` | `"canvas"` | `MobCanvas` @2747 | `.canvas` → `MobCanvasView` | **no** |
| `:gpu_view` | `"gpu_view"` | `MobGpuView` @2987 (GLES 3.0) | `.gpuView` → `MobGpuView.swift` (Metal) | yes (Android only per `Mob.UI.gpu_view/1` doc, but present in **both** tag files) |
| `:list` | — | **never reaches native** | — | yes |

**`:list` is an Elixir-only pseudo-node.** `Mob.List.expand/3` (list.ex:100–121) rewrites it to `:lazy_list` before `Mob.Renderer` ever sees it. It requires a `:id` prop (`Map.fetch!`, list.ex:101 — **raises `KeyError` if missing**), and each item is wrapped in `%{type: :box, props: %{on_tap: {pid, {:list, id, :select, index}}}}`. All non-`:id`/`:items` props pass through to the `:lazy_list`.

**Unknown types are silently dropped, never raised.** Android: the `when` in `RenderNodeInner` has no `else` → nothing renders (the node's own `nodeModifier` is never applied either). iOS: `mob_node_from_dict` leaves `nodeType` at its zero value, which is `MobNodeTypeColumn` (`MobNode.h:22`) → **an unknown node silently renders as a Column on iOS and as nothing on Android.** That divergence is worth knowing when adding a node type to one platform first.

### 1.4 Props read by EVERY node (the universal layer)

Applied before the type switch, so they work on every node type on Android (`RenderNode` @2162 + `nodeModifier` @3366) and per-case on iOS.

| Prop | Value shape | Default | Android | iOS | Notes |
|---|---|---|---|---|---|
| `offset_x` / `offset_y` | number (dp/pt) | `0` | `RenderNode` wraps in `Box(Modifier.offset)` @2163-2172 | `MobNode.offsetX/Y`, applied in `MobNodeView` body | Android deliberately wraps rather than chaining — comment @3430 explains sibling-displacement bug |
| `id` | string | — | `frameTrackingModifier(id)` + `testTag` @2183 | `nativeViewId` → `accessibilityIdentifier` (scroll only) | Powers `Mob.Test.element_frames/1`, `scroll_info/2`, `scroll_to/3`. **Must be a string on the wire** — an atom becomes a string via `:json.encode`, so `id: :hero` works |
| `background` | color token atom \| ARGB int | unset → transparent | `nodeModifier` @3377 `m.background(bg, shape)` | per-case `.background(...)` | Applied **before** padding so it fills the padded area |
| `corner_radius` | radius token atom \| number | `0` | @3368 `RoundedCornerShape`, also `m.clip(shape)` @3409 | `node.cornerRadius` | On Android, clipping applies to children too |
| `border_color` | color token atom \| ARGB int | unset | @3383 | `MobBox` `.overlay(RoundedRectangle.stroke)` | **Both** `border_color` and `border_width > 0` required |
| `border_width` | number (dp/pt) | `0` | @3384 | ” | iOS honours it **only on `:box`**; Android honours it on **every** node type |
| `padding` | spacing token atom \| int | `0` (iOS) / none (Android) | @3390-3405 | `paddingEdgeInsets` (`MobRootView.swift:155`) | |
| `padding_top`/`_right`/`_bottom`/`_left` | int | falls back to `padding` | @3391-3405 | `-1` sentinel means "use uniform" (`MobNode.m` init) | |
| `fill_width` | bool | `false` (button default `true` via `@component_defaults`) | @3411 `fillMaxWidth()` | per-case | |
| `fill_height` | bool | `false` | @3415 `fillMaxHeight()` | column/box only | |
| `width` / `height` | number (dp/pt) | unset | @3421-3422 exact size | `fixedWidth`/`fixedHeight`, `0` = auto | |
| `aspect_ratio` | float > 0 | unset | @3428 `m.aspectRatio(r)` | **NOT READ ON iOS** | Android-only |
| `align` | string atom | `:top_start` (box) / `:center` (row) | `boxAlignProp` @3540, `rowAlignProp` @3531 | `boxAlign`, `rowAlign` | Box: `center`, `top`, `top_center`, `top_trailing`, `leading`, `trailing`, `bottom`, `bottom_leading`, `bottom_center`, `bottom_trailing`. Row: `top`, `center`, `bottom` (+ **`baseline` on iOS only**, `MobRootView.swift:242`) |
| `weight` | float | unset | `Column`/`Row` children only @2191, @2197 | **NOT READ ON iOS** | Android-only flex |
| `on_tap` | `pid` \| `{pid, tag}` | — | `clickable` on all types except `button` @2178-2180 | `.onTapGesture` on most types | |
| `glass` | bool (**injected by the renderer, never authored**) | `false` | **read but never applied** — theme JSON drops non-`Number` values (`setTheme` @2245) | `MobBox` `.glassEffect(.clear)` iOS 26+, `.ultraThinMaterial` iOS 17–25 | Injected only onto `:box` nodes that already have a `background` (`renderer.ex:277-279`) |
| `style` | `%Mob.Style{}` | — | — | — | Consumed entirely in Elixir (`renderer.ex:285-291`); never reaches the wire |
| `ios:` / `android:` | map | — | — | — | Platform block, merged then deleted (`renderer.ex:294-302`) |
| `accessibility_id` | **auto-emitted** when `on_tap: {pid, atom_tag}` | — | not read | `.accessibilityIdentifier` on text/button (`MobRootView.swift:302, 324`) | `renderer.ex:313` |

### 1.5 Per-node prop tables

#### `:column` / `:row`
No own props beyond the universal layer. Spacing between children is **hardcoded to 0** on both platforms (`VStack(spacing: 0)` `MobRootView.swift:216`; Compose `Column(modifier = m)` with no `verticalArrangement` @2189). Row alignment via `align`; Column alignment is **fixed** to `.leading`/`topLeading` on iOS and Compose default `Start` on Android — **not configurable**.

> **`gap` is dead.** `Mob.Renderer` resolves `:gap` as a spacing token (`renderer.ex:172`) and serialises the number, and **neither platform reads it.** Grep: 0 hits in `MobBridge.kt.eex`, 0 in `mob_nif.m`. Gaps must be `<Spacer size={8}/>`. Cost to fix on Android: 2 lines (read `floatProp(props,"gap")`, pass `verticalArrangement = Arrangement.spacedBy(g.dp)`).

#### `:box`
`align` (2D), plus the universal layer. Android defaults to `fillMaxWidth()` when no explicit `width` (@2207-2209); iOS `MobBox` defaults to `.frame(maxWidth: .infinity)`.

#### `:scroll`
| Prop | Shape | Default | Notes |
|---|---|---|---|
| `axis` | `"vertical"` \| `"horizontal"` | `"vertical"` | Android @2215; iOS `MobNode.axis` |
| `show_indicator` | bool | `true` | **iOS only** (`MobRootView.swift:331`). Android has no equivalent |
| `id` | string | — | registers a `ScrollHandle` for the test harness (@2220-2231) |

Android applies `.imePadding()` on the vertical branch (@2238); iOS applies `.scrollDismissesKeyboard(.interactively)` (@343).

#### `:text`
See §4.

#### `:button`
| Prop | Shape | Default (from `@component_defaults`, renderer.ex:182-191) | Read where |
|---|---|---|---|
| `text` | string | `""` | @2304 |
| `on_tap` | `pid`\|`{pid,tag}` | — | @2318 |
| `background` | color | `:primary` | @2306 → `ButtonDefaults.buttonColors(containerColor=)` |
| `text_color` | color | `:on_primary` | @2326 |
| `text_size` | size token \| number | `:base` (16.0 × type_scale) | @2327 |
| `corner_radius` | radius token \| number | `:radius_md` (10) | @2307 |
| `padding` | spacing | `:space_md` (16) | Android: **NOT applied** — `MobButton` uses M3's own content padding, `nodeModifier`'s padding is on the outer modifier. iOS: applied *inside* the label (@318) |
| `fill_width` | bool | `true` | @2309 |
| `font_weight` | string | `"medium"` | **DEAD on both** — `MobButton` builds its `Text` without `fontWeight`; iOS uses `node.resolvedFont` which does honour it |
| `text_align` | atom | `:center` | **DEAD on both** — never read for buttons |

Button label is hard-wired to `maxLines = 1, overflow = Ellipsis` on Android (@2328) and `.lineLimit(1)` on iOS (@317). **A two-line button label is impossible without native work.**

#### `:text_field`
| Prop | Shape | Default | Notes |
|---|---|---|---|
| `value` | string | `""` | Controlled input. Android `remember(node.props["value"])` @2364 — re-keys local state when the BEAM pushes a new value. iOS maps `value` → `node.text` (`mob_nif.m:660-666`), `value` wins over `text` |
| `placeholder` | string | `""` | |
| `secure` | bool | `false` | Overrides `keyboard` → `KeyboardType.Password` @2345 |
| `keyboard` | `"number"`\|`"decimal"`\|`"email"`\|`"phone"`\|`"url"`\|_default_ | `"default"` | @2347-2354 |
| `return_key` | `"next"`\|`"go"`\|`"search"`\|`"send"`\|_default_ | `"done"` | @2356-2362 |
| `fill_width` | bool | `false` | @2372 |
| `on_change` / `on_focus` / `on_blur` / `on_submit` | `{pid, tag}` | — | |
| `on_compose` | `{pid, tag}` | — | **iOS only** (`MobNode.h:139`). Android never wires it |
| `background`, `text_color`, `placeholder_color`, `border_color`, `padding`, `corner_radius`, `text_size` | defaults from `@component_defaults` (`:surface_raised`, `:on_surface`, `:muted`, `:border`, `:space_sm`, `:radius_sm`, `:base`) | | **`MobTextField` on Android reads NONE of these.** It uses M3 `TextField` defaults. `placeholder_color` is not read on Android; on iOS it *is* (`mob_nif.m` props list). **`border_color` defaults to `:border` but `@component_defaults` sets no `border_width`, so a text field's border never draws.** |

`singleLine = true` is hardcoded on Android (@2385). Multi-line text input requires native work.

#### `:toggle`
`value` (bool, default `false`), `label` (string — renders as a `Text` with `weight(1f)` before the Switch, Android @2403; **iOS `MobToggle` does not read `label`**), `color` (tints `checkedThumbColor`), `on_change` → `{:change, tag, boolean}`.

#### `:slider`
`value` (float, defaults to `min`), `min` (default `0.0`), `max` (default `1.0`), `color` (thumb + active track), `on_change` → `{:change, tag, float}`. Android forces `fillMaxWidth()` (@2436). **There is no `step` prop** — the slider is continuous on both platforms.

#### `:divider`
`thickness` (float, default `1`), `color` (default `:border` from `@component_defaults`). Horizontal only — **no `axis`/vertical divider exists**.

#### `:spacer`
`size` (float). When absent: Android applies the bare modifier (so a Spacer in a Column with no size does nothing useful unless `weight` is set); iOS emits a flexible `Spacer()`. When present, **both axes are constrained** so it works in Row and Column (`MobRootView.swift:381-386`, Android `modifier.size(size.dp)` @2457).

#### `:progress`
`value` (float 0..1; **omit for indeterminate**), `color` (default `:primary`). Always `fillMaxWidth()` on Android. Linear only — **no circular/spinner variant on Android**.

#### `:image`
`src` (string), `content_mode` (`"fit"` default \| `"fill"` → `ContentScale.Crop` \| `"stretch"` → `FillBounds`), `corner_radius`, `width`, `height`. Android uses Coil `AsyncImage`; `http(s)://` → URL, anything else → `java.io.File(src)` (@2495-2499) — **a bare relative path silently fails**. `src` beginning `plugin://` is rewritten to an absolute bundle path in Elixir (`renderer.ex:513-518` → `Mob.Plugins.resolve_image/1`). **No `alt`/`content_description`, no placeholder, no error image, no tint.**

#### `:icon`
`name` (logical string), `text_color` (tint), `text_size` (glyph size; Android converts sp→dp @2519, default `24.dp`; iOS default `20`), `text` (accessibility label), `on_tap`.
Android's logical name table (`materialIconFor` @2537): settings, back, forward, close, add, remove, edit, check, chevron_right, chevron_left, chevron_up, chevron_down, info, warning, error, search, trash, share, more, menu, refresh, favorite, favorite_filled, star, star_filled, user, home, expand_more, expand_less → else `QuestionMark`.
iOS `sfSymbolName` (`MobRootView.swift:111-145`) covers the same set **plus** history, list, qr_code, link, snowflake, and — critically — **passes unknown names through verbatim** so raw SF Symbol IDs work on iOS. Android has no such escape hatch; an unknown name becomes a `?`.

#### `:lazy_list`
`on_end_reached` (`{pid, tag}`), `id` (registers a scroll handle). Children are rendered by `items(node.children)` — **the whole child list is still built in Elixir and serialised**; "lazy" refers only to Compose/SwiftUI view recycling, not to data. A 5000-row list is a 5000-node JSON payload every render.
Android forces `fillMaxWidth()`. `LazyListState` is cached by the `on_end_reached` handle integer (@2263-2267, @3308-3311) so scroll position survives re-renders — **a list without `on_end_reached` gets a fresh `LazyListState()` and loses scroll position on every render.** That is a live gotcha.

#### `:tab_bar`
`tabs` (list of maps with `id`/`label`/`icon` string keys), `active` (string id; defaults to first tab), `on_tab_select` (`{pid, tag}` — fires `{:change, tag, tab_id_string}` via `nativeSendChangeStr` @3352). Android renders an M3 `Scaffold` with a bottom `NavigationBar` and renders **only `node.children[activeIdx]`** (@3356-3362) — so children must be index-aligned with `tabs`.
Icons come from a *second, different* logical table `materialIconForLogical` @3500 (home, history, list, qr_code, link, snowflake, star, settings, search, user → else `Star`) — **not** the same table as `:icon`.

> **This is the node that the docs get wrong in the opposite direction to how it's usually reported.** The `<TabBar>` **node** does render a real NavigationBar. What renders *nothing* is `Mob.App.tab_bar/1` — see §7.

#### `:video`
`src`, `autoplay`, `loop`, `controls`. **Android is a stub** — `MobVideoPlayer` @3284 draws a black `Box` containing the literal text `Video: <src>`; the comment says it awaits a Media3 dependency, and `priv/tags/android.txt:5` says so too. iOS is a real `AVPlayerViewController`. **Video on Android is a native task, not a config task.**

#### `:camera_preview`
`facing` (`"back"` default \| `"front"`), `width`, `height`. Android binds CameraX with `ImplementationMode.COMPATIBLE` (TextureView) specifically so Compose overlays draw on top (@2586-2593).

#### `:web_view`
`url` (required — Android `?: return` @2640), `allow` (comma-joined prefix string built by `Mob.UI.webview/1` from a list), `show_url` (**iOS only**), `title`, `width`, `height`. `Mob.UI.webview/1` (`ui.ex:66-80`) is the only sane constructor — it does the `Enum.join(",")`.

#### `:native_view`
Built only via `Mob.UI.native_view/2`. Props: `module` (atom → `"MyApp_ChartComponent"`), `id` (atom, unique per screen), plus everything the component's `render/1` returns. `Mob.Component.expand/3` (`component.ex:123-145`) starts a `Mob.ComponentServer`, calls `render_props/1`, and injects `component_handle`. **Raises `ArgumentError` if `:module` or `:id` is not an atom** (component.ex:127-130). This is the officially-supported native escape hatch and the one place where iOS extension does not require patching `mob`'s own Swift.

#### `:canvas` — see §5. `:gpu_view` — `id`, `width`, `height`, `shader` (MSL string or `%{ios: "…"}`), `uniforms` (**ordered list**: number → `float`/`uint`, `[a,b]` → `float2`, `[a,b,c,d]` → `float4`; `float3` unsupported by design, `ui.ex:190-193`), plus `on_tap`/`on_drag`/`on_pinch`. `Mob.UI.gpu_view/1` `Map.take`s exactly those 8 keys — anything else you pass is silently dropped.

---

## 2. `Mob.Theme` — complete

### 2.1 The struct (theme.ex:85–123) — 20 fields, that is all of them

```elixir
defstruct [
  # Semantic colors (13)
  primary: :blue_500,      on_primary: :white,
  secondary: :gray_600,    on_secondary: :white,
  surface: :gray_800,      surface_raised: :gray_700,  on_surface: :gray_100,
  muted: :gray_500,
  background: :gray_900,   on_background: :gray_100,
  error: :red_500,         on_error: :white,
  border: :gray_700,
  # Scale factors (2)
  type_scale: 1.0,  space_scale: 1.0,
  # Corner radii, dp/pt (4)
  radius_sm: 6,  radius_md: 10,  radius_lg: 16,  radius_pill: 100,
  # Material / effect flags (1)
  glass: false
]
```

### 2.2 Does ANY field express elevation, shadow, blur, border, outline or opacity?

**No — with one narrow exception.**

| Concept | In `%Mob.Theme{}`? | Anywhere in the render path? |
|---|---|---|
| **elevation** | **No** | No. Grep `elevation` across `MobBridge.kt.eex`, `mob_nif.m`, `MobRootView.swift`: **0 hits.** Compose `Card`/`Surface` elevation is never used; Mob only uses `Modifier.background`. |
| **shadow** | **No** | No. **0 hits** for `shadow` in all three renderers. `Modifier.shadow` / `.shadow(radius:)` are never called. |
| **blur** | **No** | Only as `.ultraThinMaterial` / `.glassEffect` on iOS, gated by `theme.glass` — there is no numeric blur radius anywhere and Android drops the flag entirely (`setTheme` @2245 keeps only `Number` values, and `_glass` is a boolean). |
| **border / outline** | **Partly — `border` is a *colour token* only.** | `theme.border` is a colour. **There is no `border_width` token and no default border width.** Width is per-node (`border_width`), always numeric, never themeable. |
| **opacity / alpha** | **No** | **0 hits** for `opacity`/`alpha` as a node prop on either platform. The only opacity in the system is `Mob.Canvas`'s per-draw-op `:opacity` (§5). You cannot fade a node. |

**Bottom line for design work:** Mob's visual vocabulary is **flat fills + corner radius + 1px-style strokes**. Depth, elevation, drop shadows, scrims, disabled-state dimming and cross-fades are **not expressible**. Every one of those is a Kotlin/Swift addition. Cost estimates in §8.

### 2.3 Token resolution

Three independent namespaces, each resolved by a different clause of `resolve_token/3`.

**Colours** — two-step (`renderer.ex:526-537`):
1. `Map.get(theme_colors, value)` — the 13 semantic tokens from `Theme.color_map/1`.
2. Result is itself an atom → look it up in `@colors` (the 60-entry base palette, `renderer.ex:75-154`).
3. Result is already an integer (themes like `Mob.Theme.Light` set raw `0xFF1F1F1F`) → used directly.
4. Miss everywhere → the atom passes through and `:json.encode` stringifies it. `longColorProp` then returns `null` (Android @3558) / iOS ignores it. **A typo'd colour token is a silent no-colour, not an error.**

Applies **only** to `@color_props` (`renderer.ex:170`): `background`, `text_color`, `border_color`, `color`, `placeholder_color`. **Nothing else.** Any other prop you invent that carries a colour (e.g. a hypothetical `tint`, `shadow_color`, `track_color`) is **not** token-resolved and must be a raw ARGB int or a hex string.

**Spacing** (`renderer.ex:491-502`) — `@spacing_props`: `padding`, `padding_top/right/bottom/left`, `gap`. `space_xs:4, space_sm:8, space_md:16, space_lg:24, space_xl:32`, each `round(v * space_scale)` (theme.ex:270-272). Non-atoms pass through. Note `width`, `height`, `size`, `thickness`, `side_offset` etc. are **not** spacing props — spacing tokens don't work there.

**Radii** (`renderer.ex:505-507`) — `@radius_props`: `corner_radius` **only**. `radius_sm/md/lg/pill` map straight to the four struct ints. `space_scale` does **not** scale radii.

**Text sizes** (`renderer.ex:483-488`) — `@size_props`: `text_size`, `font_size`. `@text_sizes` (`renderer.ex:156-167`): `xs:12, sm:14, base:16, lg:18, xl:20, "2xl":24, "3xl":30, "4xl":36, "5xl":48, "6xl":60`, each `× type_scale`. Unknown atom → passes through untouched. `font_size` is resolved but **read by nothing on either platform** — only `text_size` is.

### 2.4 How a prop overrides a token

`Map.merge(defaults, props)` — `renderer.ex:258`. **Explicit props always win over `@component_defaults`.** There is no `!important`, no cascade, no inheritance: a `:text` node inside a themed `:column` inherits **nothing**; text colour must be set on every text node (or via a `%Mob.Style{}`).

Precedence, lowest to highest (`renderer.ex:256-302`):
1. `@component_defaults[type]`
2. `%Mob.Style{}` under `:style`
3. inline props
4. platform block (`ios:` / `android:`) — **highest**, wins over everything
5. `inject_theme_flags` (`glass`) is applied *before* prop serialisation and only adds a key

### 2.5 What a wholesale restyle actually touches

Setting a theme (`Mob.Theme.set/1`, theme.ex:156-172) does exactly two things:
1. `Application.put_env(:mob, :theme, theme)` — read on **every** `Mob.Renderer.render/4` call (`renderer.ex:222`). No cache, no invalidation needed; the next render picks it up.
2. `notify_native/1` → `:mob_nif.set_theme(json)` with `resolved_palette/1` + `"_glass"`.

On the native side:
- **iOS: `nif_set_theme` is a literal no-op** (`mob_nif.m:1907-1911`). Themes never leave the BEAM on iOS.
- **Android:** `MobBridge.setTheme` (@242-258) parses the ARGB map and drives `MaterialTheme(colorScheme = darkColorScheme(...))` in `MainActivity` (@193-212). This affects only **M3 system chrome** — `NavigationBar`, `Button` fallback colours, `TextField`, `Switch`, `Slider`, `HorizontalDivider` defaults. Mob's own `Box`/`Text`/`Column` primitives are painted from explicit per-node props and are unaffected.

So a wholesale restyle touches:
- the 13 colour tokens + 4 radii + 2 scales, and
- **every hard-coded value in app render code** — which is where the real work is, because there is no inheritance.

**Practical implication for Kati:** since a `%Mob.Theme{}` cannot express elevation/shadow/opacity, a Kati design system needs a **second, app-owned token layer** (an Elixir module of `%Mob.Style{}` structs + numeric constants) sitting above `Mob.Theme`. `Mob.Style` (`style.ex`) is exactly the right primitive: it's a bare props map merged at `renderer.ex:289`, so `@card = %Mob.Style{props: %{background: :surface, corner_radius: :radius_lg, padding: :space_md, border_color: :border, border_width: 1}}` composes cleanly and is compile-time-constant.

### 2.6 Adaptive theming

`Mob.Theme.Adaptive.theme/0` reads `Mob.Theme.color_scheme/0` at *call* time. `Mob.Theme.AdaptiveWatcher` (started by `use Mob.App`) subscribes to `Mob.Device` `:appearance` and re-calls `Mob.Theme.set/1` on `{:mob_device, :color_scheme_changed, _}` — **but only if `Mob.Theme.current() == module.theme()`** (adaptive_watcher.ex:97-101). A theme built as `{Mob.Theme.Adaptive, primary: :rose_500}` will **never** re-resolve, because the struct equality check fails. That's a real trap for any customised adaptive theme.

Also: `Mob.Theme.set/1` does **not** trigger a re-render. The next render picks up the new theme; until then the screen shows the old palette.

---

## 3. How a prop reaches the native side

### 3.1 The path

```
Screen.render(assigns) → node map
  → Mob.Composite.expand/2      (composite.ex:75)   pure-Elixir tag expansion, fixpoint, depth ≤ 20
  → Mob.List.expand/3           (list.ex:100)       :list → :lazy_list
  → Mob.Component.expand/3      (component.ex:118)  :native_view → props + component_handle
  → Mob.Renderer.render/4       (renderer.ex:221)
       Theme.current() → ctx (colors, spacing, radii, type_scale, flags, platform)
       nif.clear_taps()
       nif.set_transition(transition)
       prepare/4                (renderer.ex:256)  recursive
         prepare_props/4        (renderer.ex:283)
       :json.encode/1 |> IO.iodata_to_binary()
       nif.set_root(json)
```

Order is set in `Mob.Screen.do_render/3` (screen.ex:722-738). Note the comment at screen.ex:730: composites run **first** so they can emit `<List>` and `native_view` for the later passes.

### 3.2 `prepare_props/4` — the three phases (renderer.ex:283–473)

**Phase 1** — pop `:style`, `Map.merge(style.props, base)` (inline wins).
**Phase 2** — pop `:ios` and `:android`, merge the current platform's block over everything.
**Phase 3** — `Enum.flat_map` over every remaining `{key, value}` pair. This is the only place any prop is inspected.

The flat_map has ~35 clauses. **34 of them match `on_*` handler shapes and `:draw`. The 35th is the catch-all:**

```elixir
# renderer.ex:469-471
{key, value} ->
  [{Atom.to_string(key), resolve_token(key, value, ctx)}]
```

### 3.3 What happens to a prop the native side does not know?

**It is passed through, not dropped and not raised.** In detail:

**Elixir side.** There is **no allowlist**. Every key survives; `resolve_token/3`'s final clause is `defp resolve_token(_key, value, _ctx), do: value` (renderer.ex:520). An invented prop like `elevation: 4` arrives on the wire as `"elevation": 4`.

**JSON encoding** (`:json.encode/1`, OTP's stdlib — verified empirically):

| Elixir value | Wire |
|---|---|
| `12`, `1.5` | `12`, `1.5` |
| `true` / `false` | `true` / `false` |
| `:null` | `null` |
| **`nil`** | **`"nil"` — the STRING** |
| `:space_md` (unresolved atom) | `"space_md"` |
| `"text"` | `"text"` |
| `[1,2]`, `%{…}` | array / object |
| **tuple, pid, ref, fun** | **raises `ErlangError {:unsupported_type, …}`** |

> **Two sharp edges.** (a) `props: %{title: nil}` puts the literal four-character string `"nil"` on the wire, and `node.props["title"] as? String` happily returns `"nil"` — you get the word "nil" drawn on screen. Always omit the key instead of setting `nil`. (b) any un-encodable term in props (a stray tuple that isn't one of the 34 handled `on_*` shapes, e.g. `%{size: {10, 20}}`) **crashes the screen GenServer at render time**, not at compile time.

**Android** (`MobNode.kt.eex:17-31`): every prop key is copied verbatim into `props: Map<String, Any?>`. **Nothing is validated, nothing is dropped.** An unread prop simply sits in the map. Reading it later is `floatProp(node.props, "elevation")`.

**iOS** (`mob_nif.m:598+`): props are transcribed into the fixed `MobNode` ObjC properties by ~90 explicit `props[@"key"]` lookups. **Anything not in that list is discarded at parse time.** There is no `userInfo` bag. Adding an iOS prop therefore requires **three** edits (a `@property` in `MobNode.h`, a lookup in `mob_nif.m`, a use in `MobRootView.swift`) — versus **one** on Android.

### 3.4 So: how cheap is adding a prop?

| | Elixir | Android | iOS |
|---|---|---|---|
| **New prop on an existing node** | **0 lines** | **1–3 lines** in the composable | **3 edits** across 3 files, one of which is in the `mob` hex dep |
| **New colour-resolved prop** | 1 line — add the atom to `@color_props` (`renderer.ex:170`) | 1–3 lines | 3 edits |
| **New node type** | **0 lines** (+1 line in `priv/tags/android.txt` to silence a warning) | **1 line** dispatch + the composable | 3 edits + a new `MobNodeType` enum case |
| **New event** | ~3 lines — one `flat_map` clause in `prepare_props/4` | JNI stub + a Zig `sendEvent` export | ObjC block property + sender |

**Verified against a real fork.** Mishka's `MobAnchored` (a popover node type that positions a panel in its own `Popup` window): **1 dispatch line** (`MobBridge.kt:2436 "anchored" -> MobAnchored(node, m)`), a ~190-line composable + position provider (`:2471–2660`), and **zero changes to `mob` itself**. The whole Mishka fork is **+1020 / −48 lines** against the pristine 0.4.20 template.

**Drift ledger (#32) impact:** because `MobBridge.kt` is app-owned generated output with no upstream, Android bridge additions carry **no recurring merge cost**. The recurring cost is (a) re-applying them if the app is ever regenerated from a newer `mob_new`, and (b) keeping parity with iOS by hand. The *iOS* side is the one with real drift risk: `MobRootView.swift` / `MobNode.h` / `mob_nif.m` live in the `mob` hex package and are replaced on every `mob` bump.

### 3.5 The one hard limit: 256 handlers per render

```zig
// android/jni/mob_nif.zig:940
const MAX_TAP_HANDLES: usize = 256;
// :1572
if (tap_build_count >= @as(c_int, @intCast(MAX_TAP_HANDLES))) return erts.badarg(env);
```
Identical on iOS (`mob_nif.m:63`, `:1977`).

`clear_taps` runs at the start of every render; every `on_*` prop consumes one slot; slots are handed out in tree-walk order. **The 257th handler in a single frame returns `badarg`, which surfaces in Elixir as an `ArgumentError` from `nif.register_tap/1` inside `prepare_props/4` — crashing the screen process mid-render.**

For a media app this is a live constraint: 256 taps ≈ 60 poster cards with 4 handlers each. Mitigations: (a) use `:list`/`:lazy_list` where each row costs exactly **one** handle (`list.ex:113`), (b) hoist handlers to the row container instead of per-child, (c) raise the constant — it's a one-line change in `mob_nif.zig` but that file **is** in the `mob` hex package, so it's a fork-of-mob, not a fork-of-bridge.

Registry is double-buffered (`mob_nif.zig:969-977`) so an event firing during a re-render always resolves against a complete table.

---

## 4. Text

### 4.1 Every text-related prop

| Prop | Shape | Default | Android (`MobText` @2262) | iOS (`.label`, `resolvedFont` `MobRootView.swift:164`) |
|---|---|---|---|---|
| `text` | string | `""` | ✅ | ✅ |
| `text_size` | `:xs`…`:6xl` \| number | Android: M3 `LocalTextStyle` (bodyLarge, 16sp); **iOS: 14.0** (`MobNode.m` init) | ✅ `sizeProp` → `.sp` | ✅ `textSize > 0 ? textSize : 16.0` |
| `text_color` | colour token \| ARGB | `Color.Unspecified` / `Color.primary` | ✅ | ✅ |
| `font_weight` | `"thin"`\|`"light"`\|`"medium"`\|`"semibold"`\|`"bold"` | `null` / `"regular"` | ✅ @3438 | ✅ @167-182 |
| `italic` | bool | `false` | ✅ | ✅ |
| `text_align` | `"center"` \| `"right"` (anything else → left/leading) | leading | ✅ @3448 | ✅ `textAlignEnum` |
| `line_height` | float **multiplier** | unset | ✅ `lineHeightMul * fontSize` (a true line-height) | ✅ `computedLineSpacing = (lineHeight-1)*size` — **`lineSpacing`, i.e. EXTRA space between lines**, not total line height. Same prop, different geometry per platform. |
| `letter_spacing` | float | `0` | ✅ `.sp` | ✅ `.kerning()` (points, not sp) |
| `font` | string family name | system | ✅ @3473 — resource lookup in `res/font/<normalized>.ttf`, then `Typeface.create(name)`, then null | ✅ `Font.custom(family, size:)` |
| `fill_width` | bool | see below | ✅ | ✅ |
| `on_tap` | `{pid,tag}` | — | ✅ | ✅ |
| `padding`, `background`, `corner_radius`, `border_*` | universal | | ✅ via `nodeModifier` | ✅ per-case |

Alignment gotcha, handled slightly differently on each side: `text_align` is meaningless unless the Text is wider than its content. Android widens it when `text_align != null && fill_width != false && width == null` (@2286-2290). iOS widens when `fillWidth || text_align in ["center","right"]` (`MobRootView.swift:264`).

### 4.2 Props that DO NOT EXIST

| Wanted | Status | Grep evidence |
|---|---|---|
| **`max_lines`** | **Absent from both platforms.** | `max_lines`: 0 hits in `MobBridge.kt.eex`, `mob_nif.m`, `MobRootView.swift` |
| **`overflow` / ellipsis** | **Absent** as a prop. `TextOverflow.Ellipsis` appears exactly once — hardcoded inside `MobButton` (@2328). | `overflow`: 0 hits outside that |
| **text decoration** (underline, strikethrough) | **Absent** | `underline`/`strikethrough`: 0 hits |
| **`min_lines`, `soft_wrap`, `text_transform`, `baseline_shift`** | Absent | |
| **Rich / attributed text, spans, inline links** | Absent — `text` is a plain `String` on both sides | |
| **`opacity` on text** | Absent (see §2.2) | |

For a film/TV app this is the most consequential gap in the whole framework: **"2-line title with ellipsis" is not expressible.** Cost on Android: 3 lines in `MobText` — read `intProp(props,"max_lines")` and `props["overflow"] as? String`, pass `maxLines = …, overflow = TextOverflow.Ellipsis`. Cost on iOS: `@property NSInteger maxLines` in `MobNode.h` + a lookup in `mob_nif.m` + `.lineLimit(node.maxLines)` and `.truncationMode(.tail)` in `MobRootView.swift` — three files, one of which is in the hex dep.

### 4.3 OS font-scale: which props are scaled?

This is determined entirely by the **unit type** each renderer chooses.

**Android — YES, text scales with the OS font-size setting.**
```kotlin
// MobBridge.kt.eex:3566
private fun sizeProp(props: Map<String, Any?>, key: String): TextUnit =
    when (val v = props[key]) {
        is Double -> v.toFloat().sp
        …
    }
```
`.sp` is Compose's scale-independent-pixel unit and is multiplied by `Configuration.fontScale`. So `text_size` — and only `text_size` — is OS-scaled on Android. **Every other numeric prop uses `.dp`** (`nodeModifier` @3366-3435: padding, width, height, corner_radius, border_width; `MobSpacer`, `MobDivider`, `MobIcon`'s converted `fontSizeSp.value.dp`). `letter_spacing` uses `.sp` (@2299) so it scales too.

> **Consequence:** at OS font scale 1.3, text grows 30% but its container's padding, fixed heights and corner radii do not. Any `<Box height={44}>` with text inside will clip. This is the standard Android accessibility-layout hazard and Mob does nothing to mitigate it — no `text_size` clamping, no `fontScale` read exposed to Elixir. `Mob.Device` exposes battery/thermal/network/orientation but **not** font scale.

**iOS — NO for the system font, YES for custom fonts.**
```swift
// MobRootView.swift:176-181
if let family = fontFamily, !family.isEmpty {
    font = Font.custom(family, size: size)   // scales with Dynamic Type
} else {
    font = .system(size: size)               // FIXED — ignores Dynamic Type
}
```
`Font.system(size:)` is a fixed-point size and does not respond to Dynamic Type; `Font.custom(_:size:)` scales relative to the body text style. (That is SwiftUI's documented API behaviour, not a Mob decision — but it's the behaviour Mob's choice of API produces.) `MobIcon`'s iOS analogue is `.font(.system(size:))` — also fixed. Canvas text uses `.font(.system(size:))` / `.font(.custom(family, size:))`, same split.

**So the same `text_size: :base` behaves differently on the two platforms and differently again depending on whether `font` is set.** Any pixel-exact design must account for this. If Kati needs deterministic type on Android, the fix is one line in `MobText`: `fontSize = fontSize.value.dp.value.sp` won't do it — you need `with(LocalDensity.current) { (fontSizeSp.value / fontScale).sp }`, i.e. explicitly divide out `LocalDensity.current.fontScale`. That is a deliberate accessibility regression; prefer designing for scale.

---

## 5. Canvas

### 5.1 Constructing a canvas

`Mob.UI.canvas/1` (`ui.ex:157-166`) — `Map.take(props, [:width, :height, :draw])`. **Anything else you pass is silently dropped**, including `id`, `on_tap`, `on_drag`, `background`, `padding`. To get a canvas with an `on_drag` (which the Mishka fork and the iOS renderer both support) you must build the raw map yourself:
```elixir
%{type: :canvas, props: %{width: 240, height: 240, draw: ops, on_drag: {self(), :sketch}}, children: []}
```

`width` and `height` are documented "required (>0)" (`MobNode.h:249-250`). When either is 0/absent, Android falls back to the parent-supplied modifier (@2757-2761) — see the defect below.

### 5.2 Full draw-op vocabulary (`Mob.Canvas`, canvas.ex)

Helpers and raw maps are interchangeable (`canvas.ex:71-76`). All ops carry `:op`.

| Op | Constructor | Required fields | Accepted modifiers (`@*_opts`, canvas.ex:105-112) |
|---|---|---|---|
| `:line` | `line(x1,y1,x2,y2,opts)` | `x1 y1 x2 y2 color` | `width cap dash opacity` |
| `:circle` | `circle(x,y,r,opts)` | `x y r color` | `width fill dash opacity` |
| `:ellipse` | `ellipse(x,y,rx,ry,opts)` | `x y rx ry color` | `width fill dash opacity` |
| `:arc` | `arc(x,y,r,start_deg,end_deg,opts)` | `x y r start_deg end_deg color` | `width cap dash opacity` |
| `:rect` | `rect(x,y,w,h,opts)` | `x y w h color` | `width fill radius join dash opacity` |
| `:path` | `path(points,opts)` | `points color` | `width fill closed cap join dash opacity` |
| `:text` | `text(x,y,content,opts)` | `x y text color size` | `weight family anchor opacity` |
| `:image` | `image(x,y,w,h,source,opts)` | `x y w h source` | `opacity` |

- `:color` is **required** on every op except `:image` — `required/3` raises `ArgumentError` (canvas.ex:246-254).
- `:size` is **required** on `:text`.
- `points` are `{x,y}` tuples or `[x,y]` lists, normalised to lists (canvas.ex:265-271) — a malformed point raises.
- Modifier value shapes: `opacity` float 0.0–1.0 · `width` number · `dash` `[on, off]` floats · `cap` `:butt|:round|:square` · `join` `:miter|:round|:bevel` · `fill` bool (default `false` = stroke) · `weight` `:thin|:light|:regular|:medium|:semibold|:bold` (Android collapses bold/semibold/medium → `Typeface.DEFAULT_BOLD`, everything else → `DEFAULT`, @2961) · `anchor` `:start|:center|:end` · `family` string.
- `take/2` (canvas.ex:256-260) means **unknown options are silently dropped by the constructor**. `circle(…, join: :round)` loses `join`. Raw maps bypass this and pass everything through `encode_canvas_op/2`.

**Serialisation** (`renderer.ex:578-593`): `:op` → `"op"` string; `:color` → two-step theme resolution (same as top-level colour props); every other atom-keyed pair is stringified with `encode_canvas_value/1` (atoms → strings, booleans/nil untouched).

**`:image` is a no-op on Android** — `drawCanvasOp` @2903-2906 is an empty `case` with the comment "Image asset rendering deferred". iOS implements it (`MobRootView.swift:788+`).

### 5.3 Coordinate space

Documented contract (canvas.ex:13-32): **canvas-local logical units, top-left origin**, where the unit is defined by the node's own `width`/`height`. `(width/2, height/2)` must land dead centre "regardless of the canvas's actual on-screen pixel size". Angles: degrees, 0° = right, sweeping clockwise (canvas.ex:157-159). Text baseline: y is the **top** edge — both renderers offset by the font ascent (Android @2896, iOS comment @758).

### 5.4 The documented coordinate-scaling defect

`Mob.Canvas`'s moduledoc documents both the defect and its fix (canvas.ex:34-67):

> "the original per-app implementations interpreted coordinates as raw pixels, which made bounding-box overlays drift on every device where 1 dp ≠ 1 px (i.e., every modern Android device)"

and prescribes the reference recipe:
```kotlin
val sx = if (width  > 0f) size.width  / width  else 1f
val sy = if (height > 0f) size.height / height else 1f
ops.forEach { op -> drawCanvasOp(op, sx, sy) }
```
with scalars (stroke widths, radii, text sizes) scaled by `(sx + sy) / 2`.

**The shipped `mob_new` 0.4.20 template does not implement this.** `MobCanvas` (@2747-2766) sizes the Canvas and then calls `drawCanvasOp(op)` with no scale factors at all; the only conversion is per-value in `canvasFloat`:
```kotlin
// MobBridge.kt.eex:2912-2924
private fun DrawScope.canvasFloat(v: Any?): Float {
    val dp = …
    return dp.dp.toPx()   // density conversion only
}
```

**Why the bug hides.** `modifier.size(width.dp, height.dp)` normally gives the Canvas exactly `width.dp.toPx()` pixels, so `sx == density` and `canvasFloat`'s density conversion coincidentally equals the correct ratio. **It diverges in exactly two cases, and both are common:**
1. **`width`/`height` omitted or 0** — no `.size()` modifier is applied (@2757-2761), the Canvas takes whatever the parent gives, but `canvasFloat` keeps multiplying by density. Every op lands at the wrong place.
2. **The parent overrides the size constraint** — `Modifier.size()` is a *constraint*, not a guarantee. Inside a `Row` that squeezes, a `Box` with `aspect_ratio`, a `weight`ed child, or a `fillMaxWidth` parent narrower than `width.dp`, the measured `size` ≠ the declared size and every op drifts.

**The fix exists and is 14 lines.** The Mishka dev-app fork has already landed it (`MobBridge.kt:3705-3722`):
```kotlin
val declaredW = width.dp.toPx()
val declaredH = height.dp.toPx()
val sx = if (declaredW > 0f) size.width / declaredW else 1f
val sy = if (declaredH > 0f) size.height / declaredH else 1f
if (sx == 1f && sy == 1f) { ops.forEach { drawCanvasOp(it) } }
else { scale(sx, sy, pivot = Offset.Zero) { ops.forEach { drawCanvasOp(it) } } }
```
Using `DrawScope.scale(pivot = Offset.Zero)` rather than threading `sx`/`sy` into every op is strictly better than the moduledoc's own recipe — it scales strokes and text uniformly for free and needs no per-op changes. **Kati should carry this patch from day one.**

**iOS has no such defect** — `MobCanvasView` frames the Canvas to `canvasWidth`/`canvasHeight` **in points**, and SwiftUI `GraphicsContext` is already in points, so declared units == drawing units by construction (`MobRootView.swift:640-644`, and the comment at @647-652 explicitly notes Android needs the rescale and iOS does not).

---

## 6. Events

### 6.1 Registration (Elixir side, `prepare_props/4`)

Every `on_*` prop is a `{pid, tag}` tuple. `nif.register_tap({pid, tag})` returns an integer handle; the handle is what goes on the wire. `on_tap` uniquely also accepts a bare `pid` (tag becomes `:ok`) and, when the tag is an atom, emits a sibling `"accessibility_id"` (renderer.ex:309-316).

Composites get this for free: `Mob.Composite.inject_event_targets/2` (composite.ex:132-145) rewrites any `on_*` prop whose value is a bare atom or binary into `{screen_pid, tag}` — so a composite user writes `on_select="combo_select"` and never threads `self()`.

### 6.2 Complete event table

| Prop | Registered at | Message delivered to the pid | Payload keys | Android wired? | iOS wired? |
|---|---|---|---|---|---|
| `on_tap` | renderer.ex:309-316 | `{:tap, tag}` | — | ✅ | ✅ |
| `on_change` | :318 | `{:change, tag, value}` | `value` is `binary` (text_field, tab_bar) \| `boolean` (toggle) \| `float` (slider) | ✅ | ✅ |
| `on_focus` | :321 | `{:focus, tag}` | — | ✅ text_field | ✅ |
| `on_blur` | :324 | `{:blur, tag}` | — | ✅ text_field | ✅ |
| `on_submit` | :327 | `{:submit, tag}` | — | ✅ text_field | ✅ |
| `on_compose` | :335 | `{:compose, tag, %{text: charlist, phase: atom}}` | phase ∈ `:began \| :updating \| :committed \| :cancelled` | ❌ **never wired** | ✅ |
| `on_end_reached` | :338 | **`{:tap, tag}`** — reuses `nativeSendTap` (@3330) | — | ✅ lazy_list | ✅ lazy_list |
| `on_tab_select` | :341 | **`{:change, tag, tab_id_binary}`** (@3352) | — | ✅ tab_bar | ✅ (`onTabSelect`) |
| `on_select` | :347 | `{:select, tag}` | — | ❌ | ✅ (`MobNode.onSelect`) |
| `on_long_press` | :356 | `{:long_press, tag}` | — | ❌ **absent from the pristine template**; Mishka's fork adds it (`MobBridge.kt:2332-2348`, `combinedClickable`) | ✅ 0.5 s |
| `on_double_tap` | :359 | `{:double_tap, tag}` | — | ❌ | ✅ |
| `on_swipe` | :362 | `{:swipe, tag, direction_atom}` | `:left\|:right\|:up\|:down` | ❌ | ✅ 30 pt threshold |
| `on_swipe_left/right/up/down` | :365-375 | `{:swipe_left, tag}` etc. | — | ❌ | ✅ (fire alongside `on_swipe`) |
| `on_scroll` | :388/391 | `{:scroll, tag, payload}` | `x y dx dy velocity_x velocity_y phase ts seq` (zig :1246-1263) | ❌ | ✅ **iOS 18+ only** — `.onScrollGeometryChange`; silently inert on iOS 17 (`MobRootView.swift:349-356`) |
| `on_drag` | :395/398 | `{:drag, tag, payload}` | `x y dx dy phase ts seq` | ❌ (Mishka fork adds it for canvas) | ✅ |
| `on_pinch` | :402/405 | `{:pinch, tag, payload}` | `scale velocity phase ts seq` | ❌ | ✅ |
| `on_rotate` | :409/412 | `{:rotate, tag, payload}` | `degrees velocity phase ts seq` | ❌ | ✅ |
| `on_pointer_move` | :416/419 | `{:pointer_move, tag, payload}` | `x y ts seq` | ❌ | ✅ |
| `on_scroll_began` | :428 | `{:scroll_began, tag}` | — | ❌ | ✅ |
| `on_scroll_ended` | :431 | `{:scroll_ended, tag}` | — | ❌ | ✅ |
| `on_scroll_settled` | :434 | `{:scroll_settled, tag}` | — | ❌ | ✅ |
| `on_top_reached` | :437 | `{:top_reached, tag}` | — | ❌ | ✅ |
| `on_scrolled_past` | :443 | `{:scrolled_past, tag}` + sibling prop `"scrolled_past_threshold"` | latched: re-fires only after going back below | ❌ | ✅ |

`phase` values are `"began" \| "dragging"/"scrolling" \| "ended"` (delivered as **atoms**, `enif_make_atom`).

> **The gesture story on Android is nearly empty.** Of the 24 event props the Elixir renderer registers, the pristine `mob_new` 0.4.20 Android bridge wires **8**. Everything gestural (`long_press`, `double_tap`, all swipes, drag/pinch/rotate, all scroll observation) exists in Elixir and on iOS and **does nothing on Android**. Since Android is Kati's priority (Q8), assume any gesture beyond tap is a Kotlin task. The Mishka fork's `combinedClickable` change (~16 lines) is the template for how cheap `on_long_press` is; scroll observation needs a `snapshotFlow` on the `ScrollState`/`LazyListState` plus a throttle gate mirroring the iOS one, call it 60–90 lines.

### 6.3 Native-side scroll-driven props (no BEAM round-trip)

`parallax`, `fade_on_scroll`, `sticky_when_scrolled_past` (renderer.ex:453-460) take a config **map**, are stringified by `encode_native_config/1` and passed through. **iOS reads all three** (`MobNode.h:122-124`, props list in `mob_nif.m`). **Android reads none.**

### 6.4 Throttling

`Mob.Event.Throttle.parse/2` runs when the handler is `{pid, tag, opts}`. Opts: `throttle:` ms, `debounce:` ms, `delta:` number, `leading:`, `trailing:`. Defaults per kind (throttle.ex:42-60): scroll 33 ms/1 px · drag 16/1 · pinch 16/0.01 · rotate 16/1° · pointer_move 33/4, trailing `false`. Serialised as a sibling prop (`"scroll_config"`, `"drag_config"`, `"pinch_config"`, `"rotate_config"`, `"pointer_config"`) with keys `throttle_ms debounce_ms delta_threshold leading trailing` (renderer.ex:546-554). Invalid values **raise `ArgumentError` at render time** (throttle.ex:108-127). Gating is enforced natively before any `enif_send`; phase boundaries bypass the throttle.

### 6.5 Where the messages land

All of these are **`handle_info/2`** messages, not `handle_event/3`. `Mob.Screen.handle_event/3` exists as a behaviour callback and is driven only by `Mob.Screen.dispatch/3` (a `GenServer.call`) — the native side never calls it. The default generated `handle_event/3` **raises** for any unhandled event (screen.ex:116-119).

`Mob.Screen` intercepts four message shapes before the user's `handle_info/2`:
- `{:mob, :back}` (screen.ex:444-466) — WebView history first, then `{:pop}`, then `exit_app()` at the root.
- `{:tap, {:list, id, :select, index}}` (screen.ex:471-485) — rewritten to **`{:select, id, index}`**.
- `{:component_changed, id, module}` — triggers a re-render.
- `:__mob_sync_state__` — 30 s state persistence tick.
Plus `{:notification, payload}` is offered to `Mob.Plugins.dispatch_notification/1` first (screen.ex:514-520).

`Mob.Event.Bridge.legacy_to_canonical/3` converts the legacy tuples to `{:mob_event, %Address{}, event, payload}` **on request only** — nothing in `Mob.Screen` calls it. The `%Mob.Event.Address{}` model is aspirational plumbing; the shipped path is the legacy tuples.

---

## 7. Navigation

### 7.1 `Mob.App.navigation/1` — what it accepts, and what it actually does

`@callback navigation(platform :: atom()) :: map()` (app.ex:37). Three helpers:

```elixir
# app.ex:231-238
def stack(name, opts), do: %{type: :stack, name: name, root: Keyword.fetch!(opts, :root), title: Keyword.get(opts, :title)}
# app.ex:247-249
def tab_bar(branches), do: %{type: :tab_bar, branches: branches}
# app.ex:258-260
def drawer(branches), do: %{type: :drawer, branches: branches}
```

**The ONLY consumer of `navigation/1` in the entire package is `Mob.Nav.Registry.populate/1`:**

```elixir
# nav/registry.ex:84-102
defp populate(app_module) do
  for platform <- [:android, :ios] do
    nav = app_module.navigation(platform)
    register_nav(nav)
  end
end
defp register_nav(%{type: :stack, name: name, root: root}), do: :ets.insert(@table, {name, root, %{}})
defp register_nav(%{type: type, branches: branches}) when type in [:tab_bar, :drawer],
  do: Enum.each(branches, &register_nav/1)
defp register_nav(_), do: :ok
```

Verified by grep: no other reference to `navigation/1`, `:drawer`, or `%{type: :tab_bar, branches:}` exists in `lib/`, `ios/`, or `mob_new`'s templates.

> **Therefore:**
> - **`stack/2`** contributes exactly one thing: an ETS row `name → {root_module, %{}}`. Its `:title` option is **stored in the map and then discarded** — `register_nav/1` never reads it. Nothing renders a stack.
> - **`tab_bar/1` renders nothing.** It is a *grouping container for registration only*; both branches are flattened into the same flat ETS table. There is no tab UI, no per-tab nav stack, no tab state. (The `<TabBar>` **node** in a render tree is unrelated and does render — §1.5.)
> - **`drawer/1` renders nothing.** Same. No `ModalNavigationDrawer` exists anywhere in `mob_new` or `MobRootView.swift`. The docstring at app.ex:252-256 claiming otherwise is false.
> - **`navigation/1` is called twice** — once per platform — and both results are merged into one table, so a name declared differently per platform gets last-write-wins (`:ios` overwrites `:android`).
> - There is **one** navigation stack for the whole app, held in the `Mob.Screen` GenServer's `nav_history` list.

`Mob.Nav.Registry.register/3` (nav/registry.ex:67-73) is the runtime path and additionally supports **route-bound params** (`{name, module, params}`), merged *under* the caller's push params at the `mount/3` call site (screen.ex:567).

### 7.2 Every `Mob.Socket` nav function, verified against `apply_nav_action/3`

All five are pure state-stamps: `put_mob(socket, :nav_action, …)`. **Nothing happens at call time.** `Mob.Screen` reads `socket.__mob__.nav_action` after the callback returns and executes it in `apply_nav_action/3` (screen.ex:554-615).

| Function | Stamped action | What `apply_nav_action/3` actually does | Transition |
|---|---|---|---|
| `push_screen(socket, dest, params \\ %{})` | `{:push, dest, params}` | Resolves `dest` (loaded module → itself; otherwise ETS lookup — **raises `ArgumentError` if unknown**, screen.ex:639-643). Builds a **fresh** `Mob.Socket`, copies only `:safe_area` across, calls `new_module.mount(Map.merge(route_params, params), %{}, base)`. Pushes `{old_module, old_socket}` onto `nav_history`. | `:push` |
| `pop_screen(socket)` | `{:pop}` | Pops the head of `nav_history` and **restores the saved socket verbatim** — the previous screen's assigns are exactly as they were; **`mount/3` is NOT re-run**. Empty history → no-op. | `:pop` / `:none` |
| `pop_to(socket, dest)` | `{:pop_to, dest}` | `resolve_module(dest)` then linear search of `nav_history` for the first matching module (screen.ex:647-655). Found → restore that saved socket, keep the rest. **Not found → complete no-op, silently.** | `:pop` / `:none` |
| `pop_to_root(socket)` | `{:pop_to_root}` | `Enum.reverse(nav_history) |> hd` — restores the **oldest** entry and empties history. Empty history → no-op. | `:pop` / `:none` |
| `reset_to(socket, dest, params \\ %{})` | `{:reset, dest, params}` | Same mount path as `:push`, but `nav_history` becomes `[]`. | `:reset` |
| `switch_tab(socket, tab)` | `{:switch_tab, tab}` | **`{module, clear_nav_action(socket), nav_history, :none}` — it does nothing.** screen.ex:611-613, comment: "Tab switching is handled renderer-side". There is no renderer-side handling. **`switch_tab/2` is dead API.** | `:none` |

Three important behaviours:
1. **Only one nav action per callback survives.** They all write the same key, so two calls in one `handle_event` = last wins, silently.
2. **`:safe_area` is the only assign carried across a push.** screen.ex:563-566.
3. **Back is free.** `handle_info({:mob, :back}, …)` is implemented in `Mob.Screen` ahead of the user's `handle_info/2` (screen.ex:444-466), so Android's system back and iOS's edge-pan work on every screen with no code. At the root it calls `:mob_nif.exit_app()`.

### 7.3 Transitions

`Mob.Renderer.render/4`'s 4th arg. `:push | :pop | :reset | :none`, default `:none` (renderer.ex:217-221). Delivered via `nif.set_transition/1` **before** `set_root/1`, snapshotted at set_root.
Android (`MainActivity.kt.eex:214-231`): `AnimatedContent` keyed on `navKey` — `push` = slide-in from right / out to −⅓, `pop` = reverse, both `tween(300)`; `reset` = crossfade `tween(250)`; else no animation.
iOS (`MobRootView.swift:1410-1435`): matching `AnyTransition`s + `Animation`s.

### 7.4 There is no screen supervisor

`Mob.Screen.start_link/3` and `start_root/3` are plain `GenServer.start_link` (screen.ex:171-173, 200-204). `use Mob.App`'s generated `start/0` (app.ex:83-157) starts `Mob.Nav.Registry`, `Mob.State`, `Mob.ComponentRegistry`, `Mob.Device{,.IOS,.Android}`, `Mob.Theme.AdaptiveWatcher` and the plugin lifecycle — **and then hands over to `on_start/0`, where the app is expected to call `Mob.Screen.start_root/1` itself.** No supervisor is created for it, and `start_root` links to whatever process calls `on_start/0`.

The moduledoc's claim (screen.ex:5-8) that "each screen runs as a supervised GenServer … the supervisor restarts it" is **false in the shipped package.** A crash in `handle_event/3` or `handle_info/2` kills the screen process and, via the link, whatever started it. `Process.register(self(), :mob_screen)` (screen.ex:232) means only one screen process exists at a time anyway — screens are *swapped* inside one GenServer, not run as N processes. `nav_history` is `[{module, socket}]`, plain data.

**For Kati:** if you want crash isolation, you supervise `Mob.Screen` yourself in `on_start/0`. Note the restart loses `nav_history` entirely (it lives in GenServer state) unless the screen opts into `use Mob.Screen, vsn: N` persistence (screen.ex:99-124, `Mob.ScreenState`, 30 s sync + terminate flush) — and persistence covers **assigns only**, never the nav stack.

---

## 8. Absences, and what filling them costs

Each row: what's missing, whether it's missing in Elixir/Android/iOS, and the concrete edit.

| Capability | Missing where | Fix, Android | Fix, iOS | Merge cost |
|---|---|---|---|---|
| `max_lines` / `overflow` on text | both | **3 lines** in `MobText` @2262 | 3 files (`MobNode.h` prop, `mob_nif.m` lookup, `.lineLimit`/`.truncationMode`) | Android: none (app-owned). iOS: **replayed on every `mob` bump** |
| Text decoration (underline/strike) | both | 2 lines (`textDecoration = TextDecoration.Underline`) | 3 files | same |
| Node `opacity` | both | 1 line in `nodeModifier` (`m.alpha(a)`) | 3 files (`.opacity()`) | same |
| Shadow / elevation | both | 2 lines in `nodeModifier` (`m.shadow(elev.dp, shape)`) — must go **before** background | 3 files (`.shadow(color:radius:x:y:)`) | same |
| Blur | both | ~4 lines (`Modifier.blur`, API 31+) | 3 files (`.blur(radius:)`) | same |
| `gap` on Column/Row | both (resolved in Elixir, read nowhere) | 2 lines (`verticalArrangement = Arrangement.spacedBy`) | 2 lines | same |
| Vertical divider | both | new branch in `MobDivider` (~8 lines) | ~6 lines | same |
| Multi-line text field | both (hardcoded `singleLine = true`) | 2 lines (`singleLine = boolProp(...) ?: true`, `minLines`) | `TextEditor` swap, ~20 lines | same |
| Circular progress | Android | ~10 lines (`CircularProgressIndicator` branch on a `variant` prop) | already possible via `native_view` | none |
| Video playback | **Android (stub)** | Media3 dep + real player, ~80 lines + `build.gradle` | already real | none |
| `on_long_press` | Android | **~16 lines** — `combinedClickable`; **Mishka has already written it**, `MobBridge.kt:2332-2348` | — | none |
| Swipe gestures | Android | ~40 lines (`detectDragGestures` + direction classification + `nativeSendSwipe` JNI stub) — the JNI stub side is `beam_jni.c.eex`, also app-owned | — | none |
| Scroll observation (`on_scroll*`, `parallax`, `fade_on_scroll`) | Android | ~60–90 lines: `snapshotFlow` on `ScrollState`/`LazyListState`, throttle gate mirroring `mob_nif.zig:1246+`, new JNI stubs | — | none |
| Canvas viewport scaling | **Android (defect)** | **14 lines** — already written in Mishka's fork, `MobBridge.kt:3705-3722`. **Carry this.** | not needed | none |
| `>256` handlers per frame | both | one constant in `mob_nif.zig:940` — **but that file is inside the `mob` hex package**, so this is a fork-of-mob | `mob_nif.m:63` | **high** — avoid; design around it |
| New node type | — | **1 dispatch line + composable**; `MobAnchored` = ~190 lines total | new enum case + 3 files | Android none, iOS high |

**The asymmetry is the headline.** Android extension is genuinely cheap and permanently app-owned; iOS extension either patches upstream `mob` files (high recurring cost) or must be routed through `Mob.Component` + `MobNativeViewRegistry`, which is the supported seam and costs nothing at merge time. For Kati's Android-first, iOS-later posture (Q8): **build the Android bridge extensions freely, and design each one so its iOS counterpart can be a `native_view` rather than a `MobRootView.swift` patch.**

---

## 9. Traps found in source that the docs do not mention

1. **`nil` prop values render as the string `"nil"`.** Omit keys, never set them to `nil`.
2. **A non-JSON-encodable prop value crashes the screen at render time**, not compile time.
3. **`gap` is silently ignored** on both platforms.
4. **Unknown node types render as a Column on iOS and as nothing on Android.**
5. **`Mob.UI.text/1` `Map.take`s only `[:text, :text_color, :text_size]`** (ui.ex:21) — `Mob.UI.text(text: "x", font_weight: "bold")` silently drops the weight. Same class of trap in `canvas/1`, `camera_preview/1`, `gpu_view/1`.
6. **`~MOB` accepts exactly one root node** (sigil.ex:248-254 — `parsec(:node) |> eos()`). Sibling roots are a `CompileError`.
7. **`text_field`'s `border_color` default has no matching `border_width`**, so its border never draws.
8. **`@component_defaults[:button]`'s `font_weight` and `text_align` are read by neither platform.**
9. **A `lazy_list` without `on_end_reached` loses scroll position on every re-render** (Android keys `LazyListState` by that handle, @3308).
10. **`Mob.Composite`'s moduledoc promises `ctx = %{screen: pid, platform: platform}`** (composite.ex:29) but `run_expander/4` passes **`%{screen: pid}`** only (composite.ex:114). A composite reading `ctx.platform` gets a `KeyError` — which `run_expander`'s rescue converts into a logged error and an empty Column, i.e. **a silently blank component**.
11. **`switch_tab/2` is dead API** — it clears itself and does nothing.
12. **`Mob.App.tab_bar/1` / `drawer/1` render nothing**; `stack/2`'s `:title` is discarded.
13. **`Mob.Theme.set/1` does not re-render**, and on iOS `set_theme` is a no-op NIF.
14. **`Mob.Theme.AdaptiveWatcher` only re-resolves when `Mob.Theme.current() == module.theme()`** — any `{Adaptive, overrides}` theme silently stops following the OS.
15. **There is no screen supervisor** despite the moduledoc.
16. **Android's `:icon` uses a different logical-name table than `:tab_bar`'s icons** (`materialIconFor` @2537 vs `materialIconForLogical` @3500), and unknown names degrade to `?` / `Star` — whereas **iOS passes unknown icon names through as raw SF Symbol identifiers**. A name that works on iOS may be a question mark on Android.
17. **iOS default `text_size` is 14** (`MobNode.m` init) while Android's is M3 `bodyLarge` = 16sp. Always set `text_size` explicitly.
18. **`aspect_ratio` and `weight` are Android-only**; `show_indicator`, `on_compose`, row `align: :baseline`, and all Tier-3 scroll configs are iOS-only.
