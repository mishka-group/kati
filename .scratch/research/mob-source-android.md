# Mob — the Android / Compose side, read from source

Status: source-verified. Every claim below was checked in the file cited, not in
the docs. Where a doc sentence and the source disagree, the source wins and the
disagreement is called out.

## 0. Provenance — what I read, and where it lives

| Artefact | Path | Authority |
|---|---|---|
| `mob` 0.7.20, pristine | `/private/tmp/claude-501/…/scratchpad/mobtar/contents` | **canonical** for the Elixir framework + the Zig NIF |
| `mob_new` 0.4.20, pristine | `/private/tmp/claude-501/…/scratchpad/mobsrc/mob_new-0.4.20/src` | **canonical** for every native template |
| `mob_dev` 0.6.23, pristine | `/private/tmp/claude-501/…/scratchpad/mobsrc/mob_dev-0.6.23/src` | canonical for the build-time asset pipeline |
| Mishka's live app fork | `/Users/shahryar/Documents/Programming/Elixir/mishka_chelekom/development/mob/android/app/src/main/java/com/example/mishka_mob/MobBridge.kt` | **read-only**; existence proof for a custom node type |
| Kati design source | `/Users/shahryar/Documents/Programming/Elixir/kati/examples/ui_design/Kati.dc.html` | the fidelity target |

Shorthands used below:

- **`BRIDGE`** = `…/mob_new-0.4.20/src/priv/templates/mob.new/android/app/src/main/java/MobBridge.kt.eex` (3635 lines)
- **`MAIN`** = `…/android/app/src/main/java/MainActivity.kt.eex` (375 lines)
- **`NODE`** = `…/android/app/src/main/java/MobNode.kt.eex` (35 lines)
- **`MANIFEST`** = `…/android/app/src/main/AndroidManifest.xml.eex` (99 lines)
- **`APPGRADLE`** = `…/android/app/build.gradle.eex` (140 lines)
- **`MISHKA`** = the Mishka app-owned `MobBridge.kt` (4607 lines)

The complete native template set in `mob_new` 0.4.20 is exactly:
`MobBridge.kt.eex` (3635), `MainActivity.kt.eex` (375), `MobNode.kt.eex` (35),
`AndroidManifest.xml.eex` (99), `app/build.gradle.eex` (140),
`build.gradle.eex` (8), `settings.gradle.eex` (1), `gradle.properties.eex` (2),
`local.properties.eex` (9), plus `jni/{CMakeLists.txt,beam_jni.c,build.zig}.eex`
and static `res/values/styles.xml`, `res/xml/{file_provider_paths,network_security_config}.xml`.
**There is no other Kotlin.** Everything Compose-facing is in those 3635 lines.

The `MobBridge.kt.eex` at `scratchpad/MobBridge.kt.eex` is byte-identical to the
package copy (`diff -q` → SAME), so either is safe to cite.

---

## 1. The build surface, and why the numbers matter

`APPGRADLE:29-47`:

```groovy
android {
    namespace '<%= bundle_id %>'
    compileSdk 35
    ndkVersion '<%= ndk_version %>'
    defaultConfig {
        applicationId "<%= bundle_id %>"
        minSdk 28
        targetSdk 35
```

`APPGRADLE:112-121`:

```groovy
def composeBom = platform('androidx.compose:compose-bom:2024.02.00')
implementation composeBom
implementation 'androidx.compose.ui:ui'
implementation 'androidx.compose.material3:material3'
implementation 'androidx.compose.material:material-icons-extended'
implementation 'androidx.compose.foundation:foundation'
implementation 'androidx.compose.animation:animation'
implementation 'androidx.activity:activity-compose:1.8.2'
implementation 'io.coil-kt:coil-compose:2.6.0'
```

I resolved the BOM against the machine's real Gradle cache rather than trusting a
release note:

```
~/.gradle/caches/modules-2/files-2.1/androidx.compose.ui/ui-android/          → 1.6.1
~/.gradle/caches/modules-2/files-2.1/androidx.compose.foundation/foundation-android/ → 1.6.1
~/.gradle/caches/modules-2/files-2.1/androidx.compose.material3/material3-android/  → 1.2.0
```

**These four numbers gate everything in sections 2–8: `minSdk 28`, Compose UI
1.6.1, Foundation 1.6.1, Material3 1.2.0.**

AGP 8.2.0 / Kotlin 1.9.22 / Gradle 8.2.1 / Compose compiler ext 1.5.8
(`build.gradle.eex:1-8`, `gradle-wrapper.properties`, `APPGRADLE:72-74`).
Mishka's app runs the identical set (`development/mob/android/app/build.gradle`
lines 31/42/44/90/130) — so a bridge change made against these versions
transplants between the two projects without a toolchain delta.

Two build facts with visual consequences:

- `res/values/styles.xml` — `AppTheme` inherits `android:style/Theme.NoTitleBar`
  (a **platform** theme, not AppCompat/Material) and hardcodes
  `<item name="android:windowBackground">@android:color/black</item>`.
  Kati's light theme will therefore flash black for the window between surface
  creation and the first Compose frame. Fix is one line in that file (it is a
  *static* asset in `priv/static/mob.new/`, so it is app-owned after generation
  and costs no drift).
- `MAIN:138` calls `enableEdgeToEdge()` before `super.onCreate`, and `MAIN:234`
  applies `Modifier.fillMaxSize().safeDrawingPadding()` to the root node. So the
  app draws behind the system bars and then pads the whole tree away from them.
  A tab bar that wants to sit *under* a translucent nav bar (Kati's design does)
  cannot: the root padding is applied above every node and nothing in the prop
  vocabulary switches it off.

---

## 2. The dispatch table

Parsing: `NODE:17-35`. A `MobNode` is `data class MobNode(type: String, props:
Map<String, Any?>, children: List<MobNode>)`. Props are **raw `org.json` values**
— `toMobNode()` does `propsMap[key] = propsObj.get(key)` with no conversion, so
nested objects arrive as `JSONObject` and arrays as `JSONArray`. That is why
`MobCanvas` (`BRIDGE:2750-2755`) and `tabDefsProp` (`BRIDGE:3515-3523`) each
re-walk JSON by hand.

### 2.1 The modifier chain every node gets, in order

`BRIDGE:2162-2187`:

```kotlin
fun RenderNode(node: MobNode, modifier: Modifier = Modifier) {
    val ox = floatProp(node.props, "offset_x") ?: 0f
    val oy = floatProp(node.props, "offset_y") ?: 0f
    if (ox != 0f || oy != 0f) {
        Box(modifier = Modifier.offset(x = ox.dp, y = oy.dp)) { RenderNodeInner(node, modifier) }
    } else { RenderNodeInner(node, modifier) }
}
...
    val tapModifier = if (tapHandle != null && node.type != "button")
        modifier.clickable { MobBridge.nativeSendTap(tapHandle) } else modifier
    val base = tapModifier.then(nodeModifier(node.props))
    val trackId = node.props["id"] as? String
    val m = if (trackId != null) base.then(MobBridge.frameTrackingModifier(trackId)) else base
```

So the chain, outermost-first, is:

```
[parent-supplied modifier]                       // Modifier.weight(w) from a Column/Row parent,
                                                 // Modifier.padding(innerPadding) from tab_bar,
                                                 // Modifier.fillMaxSize().safeDrawingPadding() at root
  .clickable { nativeSendTap }                   // iff on_tap != null && type != "button"
  .then(nodeModifier(props))                     // ← the whole style vocabulary; expanded below
  .then(testTag(id).onGloballyPositioned{…})     // iff props["id"] != null
  [+ per-composable extras]
```

`nodeModifier` (`BRIDGE:3366-3434`) in strict source order:

| # | Modifier | Guard | Line |
|---|---|---|---|
| 1 | `.background(bg)` or `.background(bg, shape)` | `background` resolves to an int | 3376-3378 |
| 2 | `.border(w.dp, color)` / `.border(w.dp, color, shape)` | **both** `border_color` and `border_width > 0` | 3382-3387 |
| 3 | `.padding(top=, end=, bottom=, start=)` or `.padding(uniform.dp)` | any of `padding*` | 3389-3404 |
| 4 | `.clip(RoundedCornerShape(r.dp))` | `corner_radius > 0` | 3408 |
| 5 | `.fillMaxWidth()` | `fill_width == true` | 3410 |
| 6 | `.fillMaxHeight()` | `fill_height == true` | 3414 |
| 7 | `.width(w.dp)` | `width` present | 3420 |
| 8 | `.height(h.dp)` | `height` present | 3421 |
| 9 | `.aspectRatio(r)` | `aspect_ratio > 0` | 3427 |

**Two order traps that will bite the design port:**

- **`width` is inside `padding`.** Compose modifier order is outside-in for
  layout, and `.padding(8.dp)` at position 3 precedes `.width(110.dp)` at
  position 7. A node with `width: 110, padding: 8` measures **126dp** wide, not
  110. CSS `box-sizing: border-box` gives 110. Every fixed-size padded cell in
  the design is 2×padding too wide unless you pre-subtract.
- **`fill_width` beats `width`.** `.fillMaxWidth()` pins incoming constraints to
  `min == max == parentMax`; the later `.width()` is coerced into that. Setting
  both silently yields "fill".

`offset_x`/`offset_y` are deliberately *not* in `nodeModifier` — comment at
`BRIDGE:3429-3432` explains that `Modifier.offset` on the node's own chain failed
to displace siblings, so `RenderNode` wraps the node in an unmodified outer `Box`
instead. That outer Box wraps content, so an offset node inside a `Row` still
occupies its un-offset slot.

### 2.2 Every `node.type` case

`BRIDGE:2188-2258`. Twenty-two arms, no `else`.

| `node.type` | Composable built | Modifier applied to it | Extra props read | Line |
|---|---|---|---|---|
| `column` | `Column(modifier = m)` | `m`; each child gets `Modifier.weight(w)` **only** if the child has `weight` — otherwise bare `Modifier` (the child's own `nodeModifier` still runs inside `RenderNode`) | `weight` (on children) | 2189-2194 |
| `row` | `Row(modifier = m, verticalAlignment = rowAlignProp(props))` | same weight rule | `align` → `top`/`bottom`/else `CenterVertically` | 2195-2200, 3531-3536 |
| `box` | `Box(modifier, contentAlignment = boxAlignProp(props))` | `m`, or `m.fillMaxWidth()` when `width` is absent | `align` → 10 named 2-D alignments, default `TopStart` | 2206-2212, 3540-3553 |
| `scroll` | `Row(m.then(reg).horizontalScroll(s))` or `Column(m.then(reg).verticalScroll(s).imePadding())` | + `onGloballyPositioned` viewport capture when `id` present | `axis`, `id` | 2213-2239 |
| `text` | `Text(...)` | `m` → `.clickable` again if `on_tap` (**double-registered**, see below) → `.fillMaxWidth()` if `text_align` set and no `width` | `text`, `text_color`, `text_size`, `font_weight`, `italic`, `text_align`, `letter_spacing`, `line_height`, `font`, `on_tap`, `fill_width`, `width` | 2262-2300 |
| `button` | `Button(onClick, colors, shape = RoundedCornerShape(corner_radius.dp))` wrapping `Text(maxLines=1, overflow=Ellipsis)` | `m` or `m.fillMaxWidth()` | `text`, `on_tap`, `background`, `corner_radius`, `fill_width`, `text_color`, `text_size` | 2303-2329 |
| `text_field` | `TextField(...)` | `m` (+`.fillMaxWidth()` if `fill_width`) `.onFocusChanged{…}` | `on_change/focus/blur/submit`, `placeholder`, `secure`, `keyboard` (6 kinds), `return_key` (5 kinds), `value` | 2332-2396 |
| `toggle` | `Row(m, CenterVertically){ Text(weight 1f)?; Switch }` | `m` | `on_change`, `value`, `color`, `label` | 2399-2416 |
| `slider` | `Slider(...)` | **`m.fillMaxWidth()` unconditionally** | `on_change`, `min`, `max`, `color`, `value` | 2419-2440 |
| `divider` | `HorizontalDivider(thickness, color)` | `m` | `thickness`, `color` | 2443-2451 |
| `spacer` | `Spacer` | `m.size(size.dp)` if `size`, else `m` | `size` | 2454-2458 |
| `progress` | `LinearProgressIndicator` (determinate if `value`) | **`m.fillMaxWidth()` unconditionally** | `value`, `color` | 2461-2478 |
| `image` | Coil `AsyncImage(model, contentScale, contentDescription = null)` | `m` → `.width` → `.height` → `.clip(RoundedCornerShape)` (a **second, local** application — `nodeModifier` already did width/height/clip) | `src`, `content_mode` (`fill`→Crop / `stretch`→FillBounds / else Fit), `corner_radius`, `width`, `height` | 2481-2512 |
| `icon` | `Icon(imageVector = materialIconFor(name), tint, contentDescription = props["text"])` | `m` (+`.clickable` if `on_tap`, **again double-registered**) `.size(sizeDp)` | `name` (29 logical names, `BRIDGE:2538-2569`), `text_color`, `text_size`, `text`, `on_tap` | 2515-2532 |
| `lazy_list` | `LazyColumn(state)` + `derivedStateOf` end-detection | **`m.fillMaxWidth()`** | `on_end_reached`, `id` | 3303-3334 |
| `video` | **stub** — `Box(m.background(Color.Black)){ Text("Video: $src") }` | `m.background(Black)` | `src`, `autoplay` (read, ignored) | 3284-3300 |
| `camera_preview` | `AndroidView(factory = PreviewView)` + CameraX bind | `m.clipToBounds()` | `facing` | 2572-2624 |
| `web_view` | `Column(m){ Text(title)?; AndroidView(WebView) }` | outer `m`; the WebView gets `Modifier.weight(1f)` | `url`, `allow`, `title` | 2639-2740 |
| `native_view` | `MobNativeViewRegistry.render(node)` — **`m` is discarded** | *none* | `module`, `component_handle` | 2255, 2136-2158 |
| `canvas` | `Canvas(modifier = sized)` running a declarative op list | `m.size(w.dp, h.dp)` when both >0, else `m` | `draw` (12 op kinds), `width`, `height` | 2747-2766, 2768-2910 |
| `gpu_view` | `Box(sized){ AndroidView(GLSurfaceView) ; error overlay }` | `m.size(...)` | `shader` (String or `{android:…}`), `uniforms` | 2987-3042 |
| `tab_bar` | `Scaffold(bottomBar = { NavigationBar { NavigationBarItem × n } })` | `m`; active child gets `Modifier.padding(innerPadding)` | `tabs` (JSONArray of `{id,label,icon}`), `active`, `on_tab_select` | 3337-3362 |

**Doc correction — `tab_bar`.** The prior research note "`tab_bar/1` renders
nothing" is right about the *wrong* `tab_bar`. There are two:

- `Mob.App.tab_bar/1` (`lib/mob/app.ex:246-249`) returns
  `%{type: :tab_bar, branches: branches}` — a **navigation declaration**, not a
  render node. Its only consumer is `Mob.Nav.Registry` (`lib/mob/nav/registry.ex:97-99`),
  which walks `branches` to build a name→module table. It renders nothing, on
  either platform. The moduledoc's "Renders as a bottom NavigationBar on Android"
  is false.
- The **node type** `"tab_bar"` (`~MOB <TabBar tabs={…}>` / a `%{type: :tab_bar,
  props: %{tabs: …}}` node) **does** render a Material3 `Scaffold` +
  `NavigationBar` at `BRIDGE:3337-3362`. Verified.

Same class of error at `lib/mob/app.ex:250-259`: `Mob.App.drawer/1` claims
"Renders as a ModalNavigationDrawer on Android." There is **no `"drawer"` arm in
the dispatch and no `ModalNavigationDrawer` anywhere in `BRIDGE`** (grep: 0
hits). It is a registry entry only.

**Tag file vs. dispatch.** `priv/tags/android.txt` (pristine) lists 20 tags:
`Box Button Column Divider Image LazyList List Progress Row Scroll Slider Spacer
TabBar Text TextField Toggle Video CameraPreview WebView GpuView`.

- `List` is in the list but has no dispatch arm — correct, because
  `Mob.List.expand/3` (`lib/mob/list.ex:100-120`) rewrites `:list` → `:lazy_list`
  on the BEAM before render, and `Mob.Screen` calls it (`lib/mob/screen.ex:732`).
- `Icon`, `NativeView`, `Canvas` are dispatched but **absent from the tag file**,
  so `<Icon …>` in a `~MOB` sigil emits a compile warning today. Harmless (see
  §2.4) but noisy.

### 2.3 The missing `else ->` arm, and what it costs

`BRIDGE:2188-2258` is a `when` **statement**, not an expression — it is the last
statement of a `Unit`-returning `@Composable fun RenderNodeInner`. Kotlin only
requires exhaustiveness of a `when` whose value is used. So the compiler accepts
it, and an unmatched `node.type`:

1. **emits no composable at all** — no crash, no `Log.w`, no placeholder;
2. **drops the entire subtree** — children are only walked inside the arms;
3. **loses the node's `testTag` and frame tracking** — `m` is fully computed
   (background, padding, `frameTrackingModifier`) and then thrown away, so the id
   never reaches `elementFramesById`. `Mob.Test.element_frames/0` will not list
   it, which means **an agent cannot tell a silently-dropped node from a node
   that was never rendered**. This is the worst property of the bug: it defeats
   the framework's own screenshot-free introspection.

And the Elixir side does not stop you getting here. `Mob.Sigil.resolve_type/2`
(`lib/mob/sigil.ex:490-511`) only `IO.warn`s:

```elixir
unless MapSet.member?(@known_tags.both, tag) do
  ...
  IO.warn(msg, Macro.Env.stacktrace(caller))
end
atom
```

A typo — `<Colum>` — compiles, ships, and renders a blank hole. **This is the
single cheapest high-value fix in the whole bridge.**

Cost to fix: **6 Kotlin lines**, no Elixir, no API floor.

```kotlin
else -> {
    Log.w("MobBridge", "unhandled node type '${node.type}' — subtree dropped")
    if (BuildConfig.DEBUG) Box(m.background(Color(0x60FF00FF))) {
        Text("?${node.type}", color = Color.White, fontSize = 10.sp)
    }
}
```

### 2.4 Adding a node type is proven, and cheap

`MISHKA:2436` is a one-line dispatch addition:

```kotlin
"anchored"       -> MobAnchored(node, m)
```

backed by `MobAnchored` at `MISHKA:2471-2577`, `rememberRealDisplaySizePx` at
`MISHKA:2597-2608` and `MobAnchoredPositionProvider` from `MISHKA:2610`. It uses
`androidx.compose.ui.window.Popup` + a custom `PopupPositionProvider`, reads
eleven new props (`side`, `align`, `side_offset`, `align_offset`,
`panel_offset_x/y`, `flip`, `clamp`, `edge_padding`, `panel_max_width`,
`panel_max_height`, `focusable`), and works on device.

**Total Elixir cost of that node type: zero.** `Mob.Renderer.prepare/4`
(`lib/mob/renderer.ex:256-266`) does `"type" => Atom.to_string(type)` with no
whitelist, and `prepare_props/4`'s fallback clause
(`lib/mob/renderer.ex:469-471`) is:

```elixir
{key, value} ->
  [{Atom.to_string(key), resolve_token(key, value, ctx)}]
```

— an unconditional pass-through. **Any prop name you invent reaches the Kotlin
`props` map with no renderer change.** You only touch the renderer if you want
*token resolution* (`:primary` → ARGB), which means adding the key to one of four
module attributes at `lib/mob/renderer.ex:170-175`:

```elixir
@color_props   ~w(background text_color border_color color placeholder_color)a
@spacing_props ~w(padding padding_top padding_right padding_bottom padding_left gap)a
@radius_props  ~w(corner_radius)a
@size_props    ~w(text_size font_size)a
```

That is the whole extension mechanism. **One line of Elixir per token-resolving
prop; zero for a raw prop.**

Mishka's fork also proves `combinedClickable` (`MISHKA:2346-2350`), `Popup`,
`LocalLayoutDirection`, `LocalDensity`, `WindowInsets.safeDrawing`,
`CompositionLocalProvider` (`MISHKA:3035`), `RangeSlider`, `TextFieldValue`,
`Modifier.rotate`, `pointerInput` + `detectDragGestures` and `awaitEachGesture`
are all reachable from inside the bridge. None of them needed a Mob change.

---

## 3. The Modifier vocabulary actually in use

Complete list of Compose modifiers reachable from an Elixir prop, from the
`import` block (`BRIDGE:38-198`) cross-checked against call sites:

`background`, `border`, `clickable`, `clip`, `clipToBounds`, `padding`, `offset`,
`size`, `width`, `height`, `fillMaxWidth`, `fillMaxHeight`, `fillMaxSize`,
`aspectRatio`, `weight` (Row/Column scope), `verticalScroll`, `horizontalScroll`,
`imePadding`, `safeDrawingPadding` (root only, `MAIN:234`), `onFocusChanged`,
`onGloballyPositioned`, `testTag`.

Twenty-two modifiers. That is the entire surface.

Prop → modifier map (the complete set of props the Kotlin ever reads, extracted
mechanically from `BRIDGE`):

```
active aspect_ratio align allow autoplay axis background border_color border_width
color component_handle content_mode corner_radius data draw facing fill_height
fill_width font font_weight height id italic keyboard label letter_spacing
line_height max min module name offset_x offset_y on_blur on_change on_end_reached
on_focus on_submit on_tab_select on_tap padding padding_bottom padding_left
padding_right padding_top placeholder return_key secure shader size src tabs text
text_align text_color text_size thickness title uniforms url value weight width
```

**62 props. That is the whole language.**

### 3.1 Props the renderer emits that the Android bridge never reads

Verified by grepping `BRIDGE` for each string — all returned 0:

```
on_long_press on_double_tap on_swipe on_swipe_left on_swipe_right on_swipe_up
on_swipe_down on_scroll on_drag on_pinch on_rotate on_pointer_move
on_scroll_began on_scroll_ended on_scroll_settled on_top_reached on_scrolled_past
parallax fade_on_scroll sticky_when_scrolled_past on_select on_compose glass
accessibility_id gap placeholder_color
```

**26 dead props.** `Mob.Renderer` registers a real tap handle for each
(`lib/mob/renderer.ex:335-460`), the BEAM allocates it, it is serialised into the
JSON, and Android drops it on the floor. Consequences worth naming:

- **`on_long_press`** — registered at `renderer.ex:356-357`, implemented on iOS,
  silently dead on Android. Mishka already fixed this in its fork
  (`MISHKA:2332-2350`, `combinedClickable`); the fix is 8 lines and is the
  reference implementation to copy.
- **`gap`** — a spacing token resolved by the renderer (`@spacing_props`) that
  never becomes `Arrangement.spacedBy`. Every gap in Kati has to be an explicit
  `Spacer`. That is a lot of nodes: `Column(verticalArrangement =
  Arrangement.spacedBy(gap.dp))` is **4 lines** in each of the `column`/`row`
  arms and would delete a large fraction of the tree.
- **`placeholder_color`** — injected by `@component_defaults` for every
  `text_field` (`renderer.ex:195`), ignored; the placeholder always renders in
  M3's `onSurfaceVariant`.
- **`glass`** — `inject_theme_flags/3` (`renderer.ex:277-279`) stamps it on any
  `box` with a `background` when the theme sets `glass: true`. The comment is
  honest: "Android receives it but ignores it." It is the natural hook for §5's
  backdrop work.
- **`accessibility_id`** — emitted whenever `on_tap:` is a `{pid, tag}` tuple
  (`renderer.ex:312-313`). See §7.

### 3.2 Modifiers available but NOT wired

Everything below was verified present in the **exact pinned artefacts**, by
listing and `javap`-ing the AAR class jars — not from documentation.

#### `Modifier.shadow(elevation, shape, clip, ambientColor, spotColor)`

Present. `javap androidx.compose.ui.draw.ShadowKt` on `ui-android-1.6.1`:

```
public static final Modifier shadow-ziNgDLE(Modifier, float, Shape, boolean);
public static final Modifier shadow-s4CzXII(Modifier, float, Shape, boolean, long, long);
```

The `s4CzXII` overload's trailing two `long`s are the inline-class `Color`
`ambientColor` / `spotColor`. **Coloured shadows are available.** Platform floor
is API 28 (`RenderNode.setAmbientShadowColor` / `setSpotShadowColor`), which
*equals* `minSdk 28` — so **free on every device this app supports**.

Cost to wire: **12 Kotlin lines + 3 imports = 15**, plus **1 Elixir line**.

#### `Modifier.border`

**Already wired** (`BRIDGE:3382-3387`), opt-in on `border_color` + `border_width`.
Gaps: no per-side borders, no dashed stroke, no inset stroke. Kati's design uses
`box-shadow: inset 0 0 0 1px rgba(...)` 10 times — an inset hairline, which
`Modifier.border` draws *centred* on the bounds, not inside. For a 1px hairline
the difference is sub-pixel; ignore it.

#### `Modifier.alpha`

Present (`androidx/compose/ui/draw/AlphaKt.class` in the 1.6.1 jar). No API floor.
Cost: **2 lines + 1 import**.

```kotlin
floatProp(props, "opacity")?.let { a -> m = m.alpha(a.coerceIn(0f, 1f)) }
```

Elixir: `opacity: 0.6` — pass-through, **0 renderer lines**. Insert at position 1
of `nodeModifier` so the whole node (background, border, children) fades
together; put it after `background` and only the content fades.

#### `Modifier.blur(radius, edgeTreatment)`

Present (`androidx/compose/ui/draw/BlurKt.class`; `blur-F8QBwvs(Modifier, float,
Shape)` and `blur-1fqS-gw(Modifier, float, float, Shape)`).

**API floor: 31.** I verified the gate in bytecode rather than trusting the doc.
`Modifier.blur` sets `renderEffect` on the node's graphics layer; the layer
implementation is `RenderNodeApi29.setRenderEffect`, and `javap -c` on
`ui-android-1.6.1` gives:

```
5: getstatic  #198  // Field android/os/Build$VERSION.SDK_INT:I
8: bipush     31
10: if_icmplt  24                      // ← jump to `return`
13: getstatic  #204  // RenderNodeApi29VerificationHelper.INSTANCE
21: invokevirtual #207  // setRenderEffect(RenderNode, RenderEffect)
24: return
```

On API 28-30 the effect is **stored and silently dropped**. No exception, no log,
no fallback. A blurred tab bar renders perfectly crisp on an Android 9/10/11
device and looks like a bug report.

**And `Modifier.blur` does not do what the design needs — see §5.**

Cost to wire (own-content blur): **4 lines + 2 imports**, plus an explicit
`Build.VERSION.SDK_INT >= 31` guard so the fallback is a decision rather than an
accident (**+3 lines**).

#### `android.graphics.RenderEffect.createBlurEffect`

API 31, same floor, same reason. Not imported anywhere in `BRIDGE`. Only useful
against a *captured* bitmap — see §5.

#### `Modifier.graphicsLayer`

Present (`androidx/compose/ui/graphics/GraphicsLayerModifierKt.class`). No floor
for `scaleX/scaleY/rotationX/Y/Z/alpha/translationX/Y/transformOrigin/
compositingStrategy/clip/shape`; the `renderEffect` **field** carries the API-31
gate above.

This is the single highest-leverage unwired modifier: it delivers rotation,
scale, transform-origin, layer-level alpha and `CompositingStrategy.Offscreen`
(needed for correct group opacity) in one block.

Cost: **14 lines + 1 import**.

```kotlin
val gRot = floatProp(props, "rotate")
val gSx  = floatProp(props, "scale_x") ?: floatProp(props, "scale")
val gSy  = floatProp(props, "scale_y") ?: floatProp(props, "scale")
val gAl  = floatProp(props, "opacity")
if (gRot != null || gSx != null || gSy != null || gAl != null) {
    m = m.graphicsLayer(
        rotationZ = gRot ?: 0f,
        scaleX    = gSx  ?: 1f,
        scaleY    = gSy  ?: 1f,
        alpha     = gAl  ?: 1f,
        transformOrigin = TransformOrigin(
            floatProp(props, "origin_x") ?: 0.5f,
            floatProp(props, "origin_y") ?: 0.5f,
        ),
    )
}
```

Elixir: `rotate: 12.0, scale: 1.04, opacity: 0.9, origin_x: 0.0` — all
pass-through, **0 renderer lines**.

#### `Modifier.semantics` / `clearAndSetSemantics`

Present. No floor. See §7 for the full costing.

#### `combinedClickable`

Present (`androidx/compose/foundation/ClickableKt.class`). `@ExperimentalFoundationApi`
in Foundation 1.6.1, so it needs an `@OptIn`. **Already proven in Mishka's fork**
— copy `MISHKA:2313-2351` verbatim.

Cost: **8 lines + 2 imports + 1 `@OptIn`**, **0 Elixir** (the renderer has
registered `on_long_press` since `renderer.ex:356`).

#### Summary table

| Modifier | In 1.6.1? | API floor | Kotlin lines | Elixir lines | Elixir prop |
|---|---|---|---|---|---|
| `shadow(elev, shape, clip, ambient, spot)` | yes | **28** (= minSdk) | 15 | 1 | `elevation:`, `shadow_color:` |
| `border` | **already wired** | — | 0 | 0 | `border_color:`, `border_width:` |
| `alpha` | yes | none | 3 | 0 | `opacity:` |
| `blur` | yes | **31** — silent no-op below | 7 (incl. guard) | 0 | `blur:` |
| `RenderEffect.createBlurEffect` | platform | **31** | see §5 | 0 | — |
| `graphicsLayer` | yes | none (`renderEffect` field: 31) | 15 | 0 | `rotate:`, `scale*:`, `origin_*:` |
| `semantics` | yes | none | 19 | 0 | `a11y_label:`, `a11y_role:` |
| `combinedClickable` | yes | none (`@OptIn`) | 11 | 0 | `on_long_press:` (already emitted) |

Below API 31, for both `blur` and `RenderEffect`: there is no software fallback
in Compose. The honest options are (a) a tinted translucent fill, (b) ship a
pre-blurred bitmap asset for the few fixed backgrounds, or (c) raise `minSdk` to
31. `minSdk 31` is Android 12, Oct 2021 — as of 2026 that is roughly the bottom
6-8% of the active install base. For Kati, **(a) as the default with (b) never**
is the right call; do not raise `minSdk` for a blur.

---

## 4. Elevation and shadow

### 4.1 What the design actually asks for

Measured directly from `examples/ui_design/Kati.dc.html` (825,635 bytes):

- **605** `box-shadow` occurrences, **47 distinct** strings.
- The single dominant recipe appears **262 times**:

  ```css
  box-shadow: 0 1px 2px rgba(26,25,23,.04), 0 12px 24px -18px rgba(26,25,23,.7)
  ```

- Runners-up: 99× `0 1px 2px rgba(26,25,23,.05), 0 8px 16px -12px rgba(26,25,23,.5)`;
  75× `0 1px 3px rgba(26,25,23,.3)`; 14× each for two more two-layer variants.
- Every shadow colour is `rgba(26,25,23,α)` = **`#1A1917`, a warm ink** — never
  neutral black. Two exceptions: `rgba(80,55,20,.45)` (6×, a warm amber glow) and
  the white/cream inset hairlines.

So the target is: **a two-layer shadow — a 1-2px contact shadow at very low alpha
plus a large, heavily spread-in ambient shadow at high alpha — in a warm ink.**

### 4.2 What `Modifier.shadow` can and cannot do

`Modifier.shadow(elevation, shape, clip, ambientColor, spotColor)` renders **one**
platform shadow. Its geometry is derived by the framework from `elevation` plus
the window's light source; you get **no independent control of blur radius, no
y-offset, no spread, and no way to stack two shadows on one node**.

Mapping the CSS onto it:

| CSS parameter | `Modifier.shadow` | Verdict |
|---|---|---|
| colour | `ambientColor` + `spotColor` | **exact**, API 28 = minSdk |
| blur radius | derived from `elevation` | approximate only |
| y-offset | derived from `elevation` + light position | approximate only |
| spread (esp. **negative**) | none | **unreachable** |
| second layer | none | **unreachable** |
| `inset` | none | use `border` |

So `Modifier.shadow` gets you a *plausible* elevated card in the right colour,
and it is the right first move — but it will not reproduce the 262-instance
recipe. That recipe's character comes from `-18px` spread on a 24px blur: a wide,
very soft, tightly-contained pool. An elevation-derived shadow is broader and
harder at the same visual weight.

### 4.3 Tier 1 — `Modifier.shadow`, 15 lines

Insert as the **first** entry of `nodeModifier` (before `background`, so the
shadow draws behind the fill):

```kotlin
// ── shadow (before background: the silhouette draws behind the fill) ──
val elev = floatProp(props, "elevation") ?: 0f
if (elev > 0f) {
    val ink = longColorProp(props, "shadow_color") ?: DefaultShadowColor
    m = m.shadow(
        elevation    = elev.dp,
        shape        = shape ?: RectangleShape,
        clip         = false,          // the chain clips at step 4 already
        ambientColor = ink,
        spotColor    = ink,
    )
}
```

Imports: `androidx.compose.ui.draw.shadow`,
`androidx.compose.ui.graphics.RectangleShape`,
`androidx.compose.ui.graphics.DefaultShadowColor`.

Elixir side, `lib/mob/renderer.ex:170`, one character-level edit:

```elixir
@color_props ~w(background text_color border_color color placeholder_color shadow_color)a
```

Usage:

```elixir
~MOB"""
<Box elevation={6} shadow_color={:ink} corner_radius={:radius_lg} background={:surface}>
  ...
</Box>
"""
```

`elevation` needs no renderer entry (pass-through, arrives as a number).
`shadow_color: :ink` resolves through the theme's palette to an ARGB int, exactly
like `background`. **Note the alpha:** the design's shadows are `α .04`–`.9`, and
`Color(argb)` honours the alpha byte, so a token whose ARGB is `0xB31A1917`
(`α .7`) works directly — but Mob's `@colors` table stores fully-opaque values
only, so Kati's theme must define shadow tokens as raw ints, e.g.
`shadow_card: 0xB31A1917`. `resolve_color/2` (`renderer.ex:526-537`) passes an
integer straight through.

### 4.4 Tier 2 — CSS-exact shadows, ~50 lines

If the 262-instance recipe has to be exact (Q8 says 100%), the honest route is to
draw it yourself with `Paint.setShadowLayer` on the framework canvas, which has
**precisely CSS box-shadow semantics**: blur radius, dx, dy, colour. Spread is
emulated by inflating the rect before drawing.

`Paint.setShadowLayer` on **shapes** (not just text) is hardware-accelerated from
**API 28** — again exactly `minSdk`, so no floor problem.

```kotlin
private data class MobShadow(
    val dx: Float, val dy: Float, val blur: Float, val spread: Float, val argb: Int,
)

private fun Modifier.mobShadows(shadows: List<MobShadow>, radiusDp: Float) =
    this.drawBehind {
        drawIntoCanvas { canvas ->
            val fw = Paint().asFrameworkPaint()
            shadows.forEach { s ->
                fw.reset()
                fw.isAntiAlias = true
                fw.color = android.graphics.Color.TRANSPARENT
                fw.setShadowLayer(s.blur.dp.toPx(), s.dx.dp.toPx(), s.dy.dp.toPx(), s.argb)
                val sp = s.spread.dp.toPx()
                val r  = radiusDp.dp.toPx()
                canvas.nativeCanvas.drawRoundRect(
                    -sp, -sp, size.width + sp, size.height + sp, r, r, fw,
                )
            }
        }
    }
```

Plus a parser turning the JSON prop into `List<MobShadow>` (~12 lines) and the
`nodeModifier` hook (~6 lines). **Total ≈ 50 Kotlin lines.** `drawIntoCanvas`,
`nativeCanvas`, `Paint` and `toArgb` are **already imported** at
`BRIDGE:51-55` for the Canvas node — no new imports needed.

Elixir side, still zero renderer changes (a list of maps passes straight
through — `prepare_props/4`'s fallback clause handles it; only the colour would
not be token-resolved, so pass raw ARGB):

```elixir
<Box shadows={[
       %{dy: 1,  blur: 2,  spread: 0,   color: 0x0A1A1917},
       %{dy: 12, blur: 24, spread: -18, color: 0xB31A1917}
     ]}
     corner_radius={:radius_lg}>
```

Better: define it **once** in Kati as a `Mob.Style` constant and reuse it 262
times — `%Mob.Style{props: %{shadows: @card_shadow, corner_radius: :radius_lg}}`.
`Mob.Renderer.prepare_props/4:285-291` merges `:style` into the node's props
before serialisation with zero runtime cost, so the whole design system collapses
to a handful of style structs.

**Recommendation:** ship Tier 1 first (15 lines, works today, ~85% of the look),
and take Tier 2 as a follow-up once there is a device to A/B against. Tier 2 is
the only path that reaches 100%.

---

## 5. Blur / backdrop

### 5.1 What the design asks for

Measured: **23 `backdrop-filter` declarations** (46 occurrences, because each is
paired with a `-webkit-backdrop-filter`; grep confirms exactly 23 `-webkit-`
copies). By radius:

- `blur(20px)` × 14
- `blur(14px)` × 5
- `blur(22px)` × 4

They sit on the tab bar and the lock-screen widgets — i.e. **on chrome that
overlays scrolling content**, which is exactly the hard case.

### 5.2 The load-bearing fact

**`Modifier.blur` blurs the node's own content. It does not sample what is behind
the node.** This is not a subtlety — it is the whole difference.

Mechanism, from source: `Modifier.blur` (`BlurKt`) sets `renderEffect =
BlurEffect(...)` on **the node's own graphics layer**. A graphics layer is the
buffer the node draws *itself* (and its children) into. The effect is applied to
that buffer at composite time. Nothing outside the layer's own draw is in scope.
So `Box(Modifier.blur(20.dp).background(barColor)) { Text("Home") }` produces a
blurred *bar and blurred label* over a razor-sharp page. That is the opposite of
frosted glass.

The web's `backdrop-filter` is a compositor feature with no Compose 1.6.1
equivalent. Combined with the API-31 gate from §3.2, the naive port fails twice:
wrong effect everywhere, and no effect at all below Android 12.

### 5.3 The honest options, ranked

**(a) Tinted translucent fill — 0 lines, ship this.**

An alpha-carrying surface colour plus a hairline top border reads as "frosted"
at tab-bar scale, because the eye reads the *value shift and the edge*, not the
blur kernel. It is **already expressible today**: `background:` takes an ARGB
int and `longColorProp` (`BRIDGE:3558-3564`) does `Color(v.toInt())`, alpha byte
included.

```elixir
<Box fill_width={true} background={0xE6161513} border_color={0x141A1917} border_width={1}>
```

Fidelity ≈ 70%. Cost: zero Kotlin, zero Elixir, no API floor, no drift.

**(b) Haze (`dev.chrisbanes.haze`) — ~30 lines + 1 gradle line.**

Real backdrop sampling. Pick the release built against Compose 1.6 (the 0.7.x
line) so the BOM does not have to move. The shape is: a `hazeParent` (actually
`Modifier.haze(state)`) on the screen root, `hazeChild(state)` on the bar. In the
bridge that means threading a `HazeState` through a `CompositionLocal` — the
pattern is already established in Mishka's fork (`MISHKA:61`, `MISHKA:268-270`
`LocalRenderEpoch`, `MISHKA:3035` `CompositionLocalProvider`).

```kotlin
// MainActivity, around the AnimatedContent
val hazeState = remember { HazeState() }
CompositionLocalProvider(LocalHazeState provides hazeState) { … }
// in nodeModifier, at position 1:
if (boolProp(props, "blur_backdrop") == true)
    m = m.hazeChild(LocalHazeState.current, shape = shape ?: RectangleShape)
// on the scroll/root arm:
m = m.haze(LocalHazeState.current)
```

Elixir: `blur_backdrop: true` — pass-through, **0 renderer lines**. Haze itself
falls back to a translucent scrim below API 31, so the API floor is handled
inside the library. **Drift cost: one `implementation` line in `app/build.gradle`
(app-owned after generation), plus ~30 lines in the bridge fork.**

Fidelity ≈ 95%. This is the right answer if (a) is judged insufficient on device.

**(c) Capture-and-blur yourself — ~70 lines + a BOM bump. Do not.**

The in-house version of (b) needs `rememberGraphicsLayer()` +
`GraphicsLayer.record {}` + `toImageBitmap()`, which arrived in
`androidx.compose.ui.graphics.layer` at **Compose 1.7.0**. The pinned BOM is
2024.02.00 (UI 1.6.1) — the API is not in the jar. Bumping the BOM moves
Material3 from 1.2.0 to 1.3+, which changes M3 component defaults under every
existing screen. That is a large, permanent drift cost for something (b) buys for
30 lines.

**(d) `Modifier.blur` on the node's own content — 7 lines, different feature.**

Worth wiring anyway as `blur:`, because it is the correct tool for a *disabled/
censored* surface (blur a poster behind a spoiler warning) — just never call it
"backdrop". 7 lines with the API-31 guard, 0 Elixir.

### 5.4 Recommendation

Ship (a) now. Ship (d) as `blur:` because it is nearly free and genuinely useful
for a media app. Hold (b) as a scoped, ~30-line follow-up with a device A/B.
Never (c).

---

## 6. Fonts

### 6.1 How `res/font/` gets populated

Build-time, by **`mob_dev`**, not by `mob` and not by Gradle.
`MobDev.NativeBuild.apply_fonts_to_android!/0`
(`mob_dev-0.6.23/src/lib/mob_dev/native_build.ex:4892-4919`), called from the
main build pipeline at `native_build.ex:166`:

```elixir
@android_res_font "android/app/src/main/res/font"

defp collect_all_fonts do
  app_fonts = Path.wildcard("priv/fonts/*.{ttf,otf,TTF,OTF}")
  plugin_fonts =
    for %{fonts: fonts} <- MobDev.Plugin.Merge.assets(MobDev.Plugin.activated()),
        f <- fonts, do: f
  Enum.uniq(app_fonts ++ plugin_fonts)
end
```

Sources: **`priv/fonts/*.{ttf,otf}` in the app**, plus any activated plugin's
`assets.fonts`. Destination filename comes from
`MobDev.Plugin.Assets.android_font_resource_name/1`
(`plugin/assets.ex:88-96`):

```elixir
base =
  filename
  |> Path.basename(Path.extname(filename))
  |> String.downcase()
  |> String.replace(~r/[^a-z0-9_]/, "_")

if base =~ ~r/^[a-z]/, do: base, else: "f_" <> base
```

`Inter-Regular.ttf` → `inter_regular`. Two files normalising to the same resource
name raise `:font_resource_collision` at build time (`native_build.ex:4901-4906`)
rather than silently overwriting — good.

The comment at `native_build.ex:4890-4891` notes why `res/font/` and not
`assets/`: **`res/font/` entries are stored uncompressed, which Android's font
loader requires.**

### 6.2 How a family is selected per node

`fontFamilyProp` (`BRIDGE:3473-3492`) — the only font resolution in the bridge:

```kotlin
private fun fontFamilyProp(props: Map<String, Any?>, context: android.content.Context?): FontFamily? {
    val name = props["font"] as? String ?: return null
    if (context != null) {
        var resName = name.lowercase().replace(Regex("[^a-z0-9_]"), "_")
        if (!resName.matches(Regex("^[a-z].*"))) resName = "f_$resName"
        val resId = context.resources.getIdentifier(resName, "font", context.packageName)
        if (resId != 0) {
            try {
                val tf = androidx.core.content.res.ResourcesCompat.getFont(context, resId)
                if (tf != null) return FontFamily(tf)
            } catch (_: Exception) { }
        }
    }
    return try { FontFamily(Typeface.create(name, Typeface.NORMAL)) }
    catch (_: Exception) { null }
}
```

Called from **`MobText` only** (`BRIDGE:2271`). So:

- **`font:` works on `<Text>` and nowhere else.** Button labels
  (`BRIDGE:2326`), `TextField` text and placeholder (`BRIDGE:2374-2380`), toggle
  labels (`BRIDGE:2405`), tab labels (`BRIDGE:3351`), and the `web_view` title
  (`BRIDGE:2665`) all render in `MaterialTheme.typography`'s default family. For
  Kati that means every button in the app is in Roboto while every paragraph is
  in the brand face, unless you never use `<Button>`.
- The two-step fallback (`res/font` id → `Typeface.create(name)`) means a typo in
  `font:` degrades to a system family rather than erroring. `Typeface.create`
  never throws for an unknown name — it returns the default — so a misspelled
  font is **invisible in logs**.

**Cost to make `font:` universal: ~5 lines** — hoist `val ff = fontFamilyProp(...)`
in the four other composables and pass `fontFamily = ff` to each `Text`.
`MobButton` and `MobTextField` are the two that matter.

### 6.3 Variable fonts and `FontVariation.Settings` — the `FILL 1` question

**`FontVariation.Settings` is present and reachable**, but **not through the
current code path**. Verified against `ui-text-android-1.6.1`:

```
androidx/compose/ui/text/font/FontVariation.class
androidx/compose/ui/text/font/FontVariation$Settings.class
androidx/compose/ui/text/font/FontVariation$Setting{,Float,Int,TextUnit}.class
```

and `javap androidx.compose.ui.text.font.FontKt`:

```
public static final Font Font-RetOiIg(int, FontWeight, int);
public static final Font Font-YpTlLL0(int, FontWeight, int, int);
public static final Font Font-F3nL8kk(int, FontWeight, int, int, FontVariation$Settings);
                                                                ^^^^^^^^^^^^^^^^^^^^^^^
```

and:

```
public final FontVariation$Setting Setting(java.lang.String, float);   // arbitrary axis by tag
public final FontVariation$Setting weight(int);
public final FontVariation$Setting width(float);
public final FontVariation$Setting slant(float);
public final FontVariation$Setting grade(int);
public final FontVariation$Setting opticalSizing--R2X_6o(long);
```

`FontVariation.Setting("FILL", 1f)` is expressible. **Material Symbols' `FILL`
axis is reachable.**

**But the bridge cannot get there today**, because `fontFamilyProp` builds
`FontFamily(Typeface)` from `ResourcesCompat.getFont`. That produces a
`LoadedFontFamily` wrapping a plain `android.graphics.Typeface` **loaded at the
variable font's default instance** — for Material Symbols, `FILL 0`, i.e. the
outlined form. Compose applies variation settings only through the
`Font(resId, …, variationSettings)` factory, which builds a `ResourceFont` and
goes via `Typeface.Builder.setFontVariationSettings`. The `Typeface` path never
touches the axes.

**Fix: rewrite `fontFamilyProp` to the resource-Font path — 22 Kotlin lines.**
API floor for font variation settings on a resource font is **26** (`Typeface.Builder`),
below `minSdk 28`, so free.

```kotlin
private fun fontFamilyProp(props: Map<String, Any?>, context: android.content.Context?): FontFamily? {
    val name = props["font"] as? String ?: return null
    if (context != null) {
        var resName = name.lowercase().replace(Regex("[^a-z0-9_]"), "_")
        if (!resName.matches(Regex("^[a-z].*"))) resName = "f_$resName"
        val resId = context.resources.getIdentifier(resName, "font", context.packageName)
        if (resId != 0) {
            // axes: {"FILL": 1.0, "wght": 500, "GRAD": -25, "opsz": 24}
            val axes = (props["font_variation"] as? JSONObject)?.let { obj ->
                obj.keys().asSequence().mapNotNull { k ->
                    (obj.opt(k) as? Number)?.let { FontVariation.Setting(k, it.toFloat()) }
                }.toList()
            }.orEmpty()
            return try {
                if (axes.isEmpty()) FontFamily(Font(resId))
                else FontFamily(Font(resId, variationSettings = FontVariation.Settings(*axes.toTypedArray())))
            } catch (_: Exception) { null }
        }
    }
    return try { FontFamily(Typeface.create(name, Typeface.NORMAL)) } catch (_: Exception) { null }
}
```

Elixir: **0 renderer lines** (`font_variation:` is a map, passes through as a
`JSONObject`).

```elixir
<Text font="material_symbols_rounded"
      font_variation={%{"FILL" => 1.0, "wght" => 500, "GRAD" => 0, "opsz" => 24}}
      text="\u{e87d}" />
```

Note the second-order win: with this in place, `font_weight:` no longer has to
map onto Compose's five-bucket `FontWeight` enum (`BRIDGE:3438-3446` supports
only `bold/semibold/medium/light/thin` — **no `regular`, no numeric weights**);
you can drive `wght` continuously, which is what a variable brand face wants.

### 6.4 Icons: the Material Symbols route is the way in

`MobIcon` (`BRIDGE:2515-2532`) draws from a **hardcoded 29-name lookup**
(`materialIconFor`, `BRIDGE:2537-2569`) into `Icons.Filled.*`, with
`else -> Icons.Filled.QuestionMark`. The tab-bar variant (`materialIconForLogical`,
`BRIDGE:3500-3513`) has an entirely separate **10-name** table falling back to
`Icons.Filled.Star`. Two tables, no overlap guarantee, both closed.

For a design with a real icon set this is unusable. The right move is **not** to
extend the tables — it is to ship Material Symbols (or Kati's own set) as a
variable font in `priv/fonts/` and render glyphs through `<Text>`, which §6.3
makes exact. That path needs **zero** new icon plumbing and gives the `FILL 1`
axis for the selected-tab state.

---

## 7. Accessibility

### 7.1 Everything currently wired

Exhaustive. There are five hooks and one of them is a test tag.

| Hook | Line | Notes |
|---|---|---|
| `Icon(contentDescription = node.props["text"])` | `BRIDGE:2528` | the `text:` prop doubles as the label. Null if unset → unlabelled icon. |
| `NavigationBarItem(icon = { Icon(..., contentDescription = tab["label"]) })` | `BRIDGE:3352` | tab icons are labelled from the tab label. |
| `AsyncImage(contentDescription = null)` | `BRIDGE:2508` | **hardcoded null.** Every image in every Mob app is invisible to TalkBack. There is no prop to change it. |
| `Modifier.testTag(id)` | `BRIDGE:310` | test-only. Does **not** set a content description and is not exposed to a11y services by default. |
| M3 component defaults | — | `Button`, `TextField`, `Switch`, `Slider`, `Text` carry their own role/state semantics from Material3. |

**`accessibility_id` is emitted and ignored.** `Mob.Renderer.prepare_props/4:312-313`:

```elixir
{:on_tap, {pid, tag}} when is_pid(pid) and is_atom(tag) ->
  [{"on_tap", nif.register_tap({pid, tag})}, {"accessibility_id", Atom.to_string(tag)}]
```

Grep for `accessibility_id` in `BRIDGE`: **0 hits.** Every tagged tap handler in
every Mob app already ships a semantic name across the NIF boundary and Android
throws it away.

**The a11y NIFs are hardcoded Android stubs.** `mob/android/jni/mob_nif.zig:706-731`:

```zig
// nif_ax_action/2 + nif_ax_action_at_xy/3 — Android stubs.
// Both are iOS-only today. Compose semantics walker (the proper Android
// implementation) is queued under WireTap (see future_developments.md).
export fn nif_ax_action(...) { return errorAtom(env, "not_supported_on_android"); }
export fn nif_ax_action_at_xy(...) { return errorAtom(env, "not_supported_on_android"); }
```

`Mob.Test`'s `ax_action/2` returns `{:error, :not_supported_on_android}`, by
design and by comment.

**Three more bridge methods the NIF looks for and does not find.**
`mob_nif.zig:3843-3845` uses `cacheOptional`:

```zig
cacheOptional(jenv, "uiTree",     "()Ljava/lang/String;", &Bridge.ui_tree);
cacheOptional(jenv, "uiViewTree", "()Ljava/lang/String;", &Bridge.ui_view_tree);
cacheOptional(jenv, "screenInfo", "()[F",                 &Bridge.screen_info);
```

Grep for `fun uiTree` / `fun uiViewTree` / `fun screenInfo` in `BRIDGE`: **0 hits**.
Same in Mishka's fork: **0 hits**. So:

- `:mob_nif.ui_tree/0` and `ui_view_tree/0` return `{:error, :not_loaded}`.
- `:mob_nif.screen_info/0` **does not error** — `nif_screen_info`
  (`mob_nif.zig:531-579`) initialises `var vals: [7]f32 = @splat(0)` and only
  fills them `if (Bridge.screen_info != null)`. **It returns
  `%{width: 0.0, height: 0.0, scale: 0.0, safe_area: %{top: 0.0, …}}`** on every
  Android device. This is a live, silent data bug: any Elixir doing responsive
  layout off `screen_info` sees a 0×0 screen.

  Fix is ~12 Kotlin lines against a documented contract
  (`mob_nif.zig:528-530`: `float[7] = [w_dp, h_dp, scale, safe_top, safe_bottom,
  safe_left, safe_right]`), with **zero** Zig or Elixir change:

  ```kotlin
  @JvmStatic
  fun screenInfo(): FloatArray {
      val a = activityRef?.get() ?: return FloatArray(7)
      val dm = a.resources.displayMetrics
      val sa = getSafeArea()   // already exists, BRIDGE:1490 — [top,right,bottom,left]
      return floatArrayOf(
          dm.widthPixels / dm.density, dm.heightPixels / dm.density, dm.density,
          sa[0], sa[2], sa[3], sa[1],
      )
  }
  ```

### 7.2 `Modifier.semantics` as a generic prop — 19 lines

Insert in `RenderNodeInner` between `base` and the `trackId` line
(`BRIDGE:2183-2187`):

```kotlin
val axLabel  = node.props["a11y_label"] as? String ?: node.props["accessibility_id"] as? String
val axRole   = node.props["a11y_role"] as? String
val axHidden = boolProp(node.props, "a11y_hidden") == true
val semantic = when {
    axHidden -> base.clearAndSetSemantics { }
    axLabel != null || axRole != null -> base.semantics {
        axLabel?.let { contentDescription = it }
        when (axRole) {
            "button"   -> role = Role.Button
            "image"    -> role = Role.Image
            "checkbox" -> role = Role.Checkbox
            "switch"   -> role = Role.Switch
            "tab"      -> role = Role.Tab
            "header"   -> heading()
            else       -> {}
        }
    }
    else -> base
}
val m = if (trackId != null) semantic.then(MobBridge.frameTrackingModifier(trackId)) else semantic
```

Imports: `androidx.compose.ui.semantics.{semantics, clearAndSetSemantics,
contentDescription, role, heading}`, `androidx.compose.ui.semantics.Role`.

**19 Kotlin lines, 0 Elixir lines, no API floor.** The `accessibility_id`
fallback means every existing `on_tap: {self(), :play_button}` in Kati becomes
TalkBack-announceable for free.

Plus **1 line** to fix images (`BRIDGE:2508`):

```kotlin
contentDescription = node.props["alt"] as? String ?: node.props["a11y_label"] as? String,
```

### 7.3 Does `sp` text scaling reach through `text_size`? — Yes for text, no for icons

`sizeProp` (`BRIDGE:3566-3573`) returns `TextUnit` in **`.sp`**:

```kotlin
private fun sizeProp(props: Map<String, Any?>, key: String): TextUnit =
    when (val v = props[key]) {
        is Double -> v.toFloat().sp
        is Float  -> v.sp
        is Int    -> v.sp
        is Long   -> v.toFloat().sp
        else      -> TextUnit.Unspecified
    }
```

So `text_size:` → `Text(fontSize = …sp)` → **scales with the user's system font
size**. Same for `line_height` (`BRIDGE:2274-2275`, multiplier × `fontSize.value`,
re-`.sp`'d) and `letter_spacing` (`BRIDGE:2297`, `.sp`).

`AndroidManifest.xml.eex:74` includes `fontScale` in `android:configChanges`, so
a font-size change is delivered to `onConfigurationChanged` instead of recreating
the Activity; Compose's `LocalConfiguration`/`Density` update and text reflows
live.

**The break is icons.** `BRIDGE:2518-2520`:

```kotlin
val fontSizeSp  = sizeProp(node.props, "text_size")
val sizeDp      = if (fontSizeSp != TextUnit.Unspecified) fontSizeSp.value.dp else 24.dp
```

`.value` strips the unit and re-tags the raw number as **`dp`**. So at font scale
1.3 a `text_size: 16` label grows to ~21dp while the `text_size: 16` icon beside
it stays exactly 16dp. Every icon-plus-label row in Kati drifts out of alignment
for large-text users. Mishka's fork has the identical line (`MISHKA:3392`).

Fix: **1 line**, using the composition's density:

```kotlin
val sizeDp = if (fontSizeSp != TextUnit.Unspecified)
    with(LocalDensity.current) { fontSizeSp.toDp() } else 24.dp
```

`TextUnit.toDp()` in a `Density` scope applies `fontScale`, which is exactly the
intent. (Keep an opt-out — `icon_size:` in dp — for icons that must not scale,
e.g. a fixed-height tab bar. +3 lines.)

**Everything else is `dp` and does not scale:** `padding*`, `width`, `height`,
`corner_radius`, `size` (spacer), `thickness`, `border_width`, `offset_x/y`. That
is conventional and correct.

**Elixir cannot see the font scale at all.** No NIF exposes it — the `screenInfo`
contract (`mob_nif.zig:528-530`) has seven slots and none is `fontScale`. Adding
it needs a Zig change in `mob` itself (an eighth float + a `font_scale` map key,
~6 lines) — i.e. an upstream PR, not a host-fork change. Until then, scale-aware
layout must be done by Compose (which it is, for text) rather than by Elixir.

---

## 8. Modal / sheet

### 8.1 What exists

- **No `ModalBottomSheet`.** Grep across the whole `mob_new` template tree: 0 hits.
- **No Compose `Dialog`.** 0 hits.
- **No `Popup` in the pristine bridge.** 0 hits. (Mishka's fork added one — see below.)
- **Two `android.app.AlertDialog`s** — `BRIDGE:1278` (`alert_show`) and
  `BRIDGE:1308` (`action_sheet_show`). These are **platform View dialogs**, not
  Compose, driven imperatively from Elixir via `Mob.Alert.show/2` and
  `Mob.Alert.action_sheet/2`. They render in the platform theme
  (`Theme.NoTitleBar`), take no styling from `Mob.Theme`, and cannot contain Mob
  nodes. For Kati they are usable only for genuine OS-level confirmations.
- **`Popup` is proven reachable** by Mishka's `anchored` node type
  (`MISHKA:2553-2575`), including a custom `PopupPositionProvider`, edge
  clamping, flip, `WindowInsets.safeDrawing` and `clippingEnabled = false`. That
  is ~180 lines including the position provider, and it works on device across
  API 34/35/36 (the comments at `MISHKA:2516-2529` document the API-level
  differences they had to defeat).

### 8.2 Cost of adding `ModalBottomSheet`

`ModalBottomSheet` **is** in the pinned Material3 1.2.0 — verified by listing the
AAR:

```
androidx/compose/material3/ModalBottomSheet_androidKt.class      (34,494 bytes)
androidx/compose/material3/SheetState.class
androidx/compose/material3/BottomSheetScaffoldKt*.class
```

51 `ModalBottomSheet*` classes. It is `@ExperimentalMaterial3Api`, so it needs an
`@OptIn`. No API floor.

**~30 Kotlin lines + 5 imports + 1 dispatch line.**

```kotlin
@OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class)
@Composable
private fun MobSheet(node: MobNode, modifier: Modifier) {
    if (boolProp(node.props, "open") != true) return
    val dismiss = intProp(node.props, "on_dismiss")
    val state = rememberModalBottomSheetState(
        skipPartiallyExpanded = boolProp(node.props, "skip_partial") ?: false,
    )
    val bg = colorProp(node.props, "background")
    ModalBottomSheet(
        onDismissRequest = { dismiss?.let { MobBridge.nativeSendTap(it) } },
        sheetState       = state,
        modifier         = modifier,
        containerColor   = if (bg != Color.Unspecified) bg else BottomSheetDefaults.ContainerColor,
        dragHandle       = if (boolProp(node.props, "drag_handle") != false)
            { { BottomSheetDefaults.DragHandle() } } else null,
    ) {
        node.children.forEach { RenderNode(it) }
    }
}
```

Dispatch: `"sheet" -> MobSheet(node, m)`.

Elixir side:

```elixir
<Sheet open={@sheet_open} on_dismiss={{self(), :close_sheet}} background={:surface_raised}>
  <Column padding={:space_lg}> ... </Column>
</Sheet>
```

**0 renderer lines.** The BEAM owns open/closed — exactly the discipline Mishka
adopted for `anchored` (`MISHKA:2544-2550`): the window never closes itself, it
*reports* the dismiss and the screen flips the assign, so the rendered tree and
the state can never disagree. Copy that.

The only cost outside the bridge is a compile **warning** per `<Sheet>` usage
from `Mob.Sigil.resolve_type/2` (`sigil.ex:493-509`), because `Sheet` is not in
`priv/tags/android.txt`. It is `IO.warn`, not an error — the tag passes through.
Do **not** work around it by editing `deps/mob/priv/tags/android.txt`; that file
is regenerated and is exactly the drift Mishka's `tags/1` alias creates. Either
live with the warning or upstream the tag.

**Compose `Dialog` (centred modal, Mob-node content): ~18 lines + 2 imports.**
`androidx.compose.ui.window.Dialog` is in compose-ui, already a dependency.

---

## 9. RTL

### 9.1 `android:supportsRtl` is not set

`MANIFEST:61-67`, the complete `<application>` attribute list:

```xml
<application
    android:label="<%= display_name %>"
    android:icon="@mipmap/ic_launcher"
    android:allowBackup="false"
    android:extractNativeLibs="true"
    android:networkSecurityConfig="@xml/network_security_config"
    android:theme="@style/AppTheme">
```

No `android:supportsRtl`. Mishka's generated manifest
(`development/mob/android/app/src/main/AndroidManifest.xml:66`) is the same —
grep for `supportsRtl`: 0 hits. Default is `false`.

### 9.2 `LocalLayoutDirection` is read, never provided

Grep across the whole `mob_new` template tree: **0 hits**. In Mishka's fork it
appears exactly once, `MISHKA:2492`:

```kotlin
val ld = LocalLayoutDirection.current
```

— *read*, to resolve `WindowInsets` for the `anchored` position provider. It is
never *provided*: `CompositionLocalProvider` appears twice in Mishka
(`MISHKA:61` import, `MISHKA:3035` use) and both are for
`LocalTextSelectionColors`, not layout direction.

### 9.3 What actually happens on a Persian locale

I traced this in bytecode rather than reasoning from the docs, because it decides
whether Kati's RTL is a manifest edit or a project.

`javap -c androidx.compose.ui.platform.AndroidComposeView` on `ui-android-1.6.1`:

- **Constructor** (offsets 738-764): reads
  `Resources.getConfiguration()` → `AndroidComposeView_androidKt.getLocaleLayoutDirection(Configuration)`
  → stores into `layoutDirection$delegate`. So the **initial** value is derived
  from the **locale**, and would be `Rtl` under `fa`.
- **`onRtlPropertiesChanged(int)`** (offsets 8-24): `layoutDirectionFromInt(int)`
  → `setLayoutDirection(...)` → also `FocusOwner.setLayoutDirection(...)`.

`onRtlPropertiesChanged` is a `View` callback driven by RTL resolution up the
view hierarchy, whose root is pinned by `ViewRootImpl` to `LAYOUT_DIRECTION_LTR`
when the application's `hasRtlSupport()` is false — which is exactly what an
absent `android:supportsRtl` means.

**Net: Compose initialises to `Rtl` from the locale, then the platform resolves
the root to LTR and Compose is corrected back to `Ltr`. RTL does not engage.**

**Fix: one attribute.**

```xml
android:supportsRtl="true"
```

Add to `<application>` in the app's own `AndroidManifest.xml` (app-owned after
generation — zero drift). Then verify on device, because the initial-value /
resolved-value sequence above means the first frame can differ from steady state.

### 9.4 What flips once RTL engages — and what does not

The bridge is *accidentally* well prepared, because it already uses
direction-aware Compose APIs:

**Flips correctly (no code change):**

- `nodeModifier`'s padding, `BRIDGE:3396-3401` — `padding_left` is mapped to
  **`start`** and `padding_right` to **`end`**:
  ```kotlin
  hasEdge -> m.padding(
      top    = (top    ?: uniform ?: 0).dp,
      end    = (right  ?: uniform ?: 0).dp,
      bottom = (bottom ?: uniform ?: 0).dp,
      start  = (left   ?: uniform ?: 0).dp,
  )
  ```
  **This is a semantic landmine, not a bug**: under RTL, `padding_left: 16`
  produces 16dp on the *right*. Every Kati component authored against the
  LTR-visual reading of `padding_left` will mirror. That is usually what you
  want — but it means the prop name lies, and the team must read `padding_left`
  as `padding_leading` from day one.
- `boxAlignProp` (`BRIDGE:3540-3553`) — `Alignment.CenterStart` / `TopStart` /
  `BottomEnd` etc. are all direction-aware.
- `textAlignProp` (`BRIDGE:3448-3453`) — `"right" -> TextAlign.End`, likewise.
- `Row` / `Column` / `LazyColumn` arrangement — Compose mirrors `Row` under RTL.
- `TextField` caret, selection and BiDi text runs — handled by `ui-text`.

**Does not flip / needs attention:**

- `offset_x` (`BRIDGE:2166`) — `Modifier.offset(x = …)` is **absolute**, not
  direction-aware. Use `Modifier.absoluteOffset` if you want it pinned, or flip
  the sign in Elixir. Compose also offers no `offset` variant keyed to direction
  for this shape; a `RenderNode` change of ~4 lines
  (`if (LocalLayoutDirection.current == Rtl) -ox else ox`) would make it mirror.
- `textAlignProp` has **no `"left"`, `"start"`, `"end"` or `"justify"` cases** —
  `else -> null` → Compose's `TextAlign.Start` default. Persian body copy that
  wants justification cannot get it. +3 lines to add `"justify" ->
  TextAlign.Justify` and explicit `"start"`/`"end"`.
- `materialIconFor` (`BRIDGE:2547-2548`) maps `chevron_right`/`chevron_left` to
  fixed glyphs. Under RTL a "forward" chevron must point left. Either add
  `chevron_forward`/`chevron_back` logical names that resolve via
  `LocalLayoutDirection` (+6 lines) or use `Icons.AutoMirrored.Filled.*`, which
  exists in `material-icons-extended` at this version.
- `Modifier.offset` in `MobAnchored`'s `panel_offset_x` (Mishka) — same absolute
  semantics.

**Total RTL cost: 1 XML attribute + ~13 Kotlin lines for the three edge cases +
a naming convention decision (`padding_left` means leading).**

---

## 10. Consolidated gap ledger

Every gap, with a concrete line count, the Elixir API, where the code lives, and
the permanent merge cost against the drift ledger (#32).

Location key: **H** = host bridge fork (`kati/android/.../MobBridge.kt`, merged
by hand on every `mob_new` bump) · **A** = app-owned non-template asset (manifest,
`styles.xml`, `app/build.gradle` — generated once, then yours, **no drift**) ·
**U** = upstream `mob` / `mob_new` PR · **M** = Mishka component (headless).

| # | Gap | Kotlin | Elixir | Where | API floor | Drift |
|---|---|---|---|---|---|---|
| 1 | missing `else ->` arm | 6 | 0 | H | — | low |
| 2 | `Modifier.shadow` + `elevation:`/`shadow_color:` | 15 | 1 | H + U(renderer) | 28 = minSdk | low |
| 3 | CSS-exact multi-layer shadow (`setShadowLayer`) | ~50 | 0 | H | 28 = minSdk | med |
| 4 | `opacity:` (`Modifier.alpha`) | 3 | 0 | H | — | low |
| 5 | `graphicsLayer` (`rotate`/`scale`/`origin`) | 15 | 0 | H | — | low |
| 6 | `a11y_label:`/`a11y_role:`/`a11y_hidden:` semantics | 19 | 0 | H | — | low |
| 7 | image `contentDescription` | 1 | 0 | H | — | trivial |
| 8 | icon `sp` scaling (`.value.dp` bug) | 1 (+3 opt-out) | 0 | H | — | trivial |
| 9 | `on_long_press` via `combinedClickable` | 11 | 0 | H (copy `MISHKA:2313-2351`) | — | low |
| 10 | `gap:` → `Arrangement.spacedBy` | 8 | 0 | H | — | low |
| 11 | `font:` on Button/TextField/Toggle/Tab | 5 | 0 | H | — | low |
| 12 | `font_variation:` (Material Symbols `FILL 1`) | 22 | 0 | H | 26 < minSdk | med |
| 13 | `<Sheet>` → `ModalBottomSheet` | 31 | 0 (+1 tag) | H | — | med |
| 14 | `<Dialog>` → Compose `Dialog` | 18 | 0 | H | — | low |
| 15 | `blur:` (own content) with 31-guard | 7 | 0 | H | **31**, no-op below | low |
| 16 | backdrop via Haze | 30 + 1 gradle | 0 | H + A | 31 (lib falls back) | med |
| 17 | `screenInfo()` — fixes `%{width: 0.0}` | 12 | 0 | H | — | low |
| 18 | `android:supportsRtl="true"` | 1 XML | 0 | **A** | — | **none** |
| 19 | RTL edge cases (offset, justify, chevrons) | 13 | 0 | H | — | low |
| 20 | `windowBackground` black flash | 1 XML | 0 | **A** | — | **none** |
| 21 | `text_align` `start`/`end`/`justify` | 3 | 0 | H | — | trivial |
| 22 | `maxLines:`/`text_overflow:` on `<Text>` | 6 | 0 | H | — | trivial |
| 23 | font scale → Elixir | 4 | 6 zig | **U** | — | upstream |

**Totals: ~280 Kotlin lines in the host bridge fork, 1 line of `mob` renderer,
2 app-owned XML attributes, 1 gradle line, and one upstream PR.**

Against 3635 lines of template, a ~280-line fork is **7.7%**. Mishka's live fork
is already 4607 lines against the same 3635 — a **+27%** delta — and it merges.
The mechanical merge burden is real but bounded, and the way to keep it bounded
is discipline about *shape*: every item above except #3 and #16 is a
self-contained insertion into one of four places — `nodeModifier`, the `when`
arms, `RenderNodeInner`'s modifier prelude, or a new `private fun Mob*`
composable. Insertions at those four seams survive an upstream diff; edits woven
into existing bodies do not.

**Cheapest wins, in order:** #18 and #20 (two XML attributes, zero drift), #1,
#7, #8, #21 (10 lines total, all trivial), then #2 and #6 (34 lines, the two
biggest visual/quality returns per line in the whole list).

---

## 11. Corrections to the documentation, for the record

Each verified in source, with the file and line that disproves the doc.

1. **`Mob.App.tab_bar/1` "Renders as a bottom NavigationBar on Android."**
   (`lib/mob/app.ex:243`) — False. It returns `%{type: :tab_bar, branches: …}`,
   consumed only by `Mob.Nav.Registry` (`lib/mob/nav/registry.ex:97-99`). The
   *node type* `"tab_bar"` does render (`BRIDGE:3337`); the two are unrelated.
2. **`Mob.App.drawer/1` "Renders as a ModalNavigationDrawer on Android."**
   (`lib/mob/app.ex:253`) — False. No `"drawer"` dispatch arm, no
   `ModalNavigationDrawer` import, 0 grep hits in `BRIDGE`.
3. **`Mob.Renderer` "Border (currently honored on `:box` only)"**
   (`lib/mob/renderer.ex:34`) — False on Android. `nodeModifier`
   (`BRIDGE:3382-3387`) runs for **every** node type, so `border_color` +
   `border_width` work on `text`, `row`, `column`, `image`, everything.
4. **`priv/tags/android.txt` claims `Video` is supported** (with the caveat "Video
   is a stub pending ExoPlayer integration") — the caveat is right, but note that
   `APPGRADLE:137-139` **already declares** `androidx.media3:media3-exoplayer:1.3.1`
   and `media3-ui:1.3.1`, while `MobVideoPlayer` (`BRIDGE:3284-3300`) is still a
   black `Box` with the text `"Video: $src"` and a comment saying "Stubbed until
   Media3 dependency is added to build.gradle." The dependency *is* added. The
   stub is now the only thing missing.
5. **`priv/tags/android.txt` omits `Icon`, `NativeView` and `Canvas`**, all three
   of which are dispatched. Any `~MOB <Icon …>` warns at compile time.
6. **`Mob.Device.screen_info/0` silently returns zeros on Android** — see §7.1.
   Not a doc error so much as an undocumented hole with a data-shaped failure.

---

## 12. Reading list, if you only open three files

1. `BRIDGE:2160-2260` — `RenderNode` + `RenderNodeInner`. The whole dispatch and
   the whole modifier prelude, 100 lines. Everything in §2 and §3 lives here.
2. `BRIDGE:3366-3434` — `nodeModifier`. The entire style vocabulary, 68 lines.
   Every item in §10 that touches styling is an insertion into this function.
3. `mob/lib/mob/renderer.ex:283-473` — `prepare_props/4`. The pass-through
   fallback at 469-471 is the single fact that makes Q10 cheap: **new props cost
   nothing on the Elixir side.**

Then, for the proof that a custom node type ships:
`MISHKA:2436` + `MISHKA:2471-2577`.
