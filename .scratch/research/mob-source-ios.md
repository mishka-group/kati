# Mob — the iOS / SwiftUI side, from source

Research date: 2026-08-17.
**Authority: pristine hex packages, not docs.** Every claim below was read out of source.
Where a capability is absent I say so and give the cost of adding it.

## Sources of record

| What | Path | Version |
|---|---|---|
| `mob` pristine | `/private/tmp/claude-501/-Volumes-Fast-Arise-Resource-AI-book/c5718512-beef-4e2f-bbc9-14f1d94a1350/scratchpad/mobtar/contents` | 0.7.20 |
| `mob_new` pristine | `…/scratchpad/mn420` (extracted fresh from `~/.hex/packages/hexpm/mob_new-0.4.20.tar`) | 0.4.20 |
| `mob_dev` pristine | `…/scratchpad/md623` | 0.6.23 |
| Mishka dev app (READ ONLY) | `/Users/shahryar/Documents/Programming/Elixir/mishka_chelekom/development/mob` | forked `MobBridge.kt`, 4607 lines |

Re-extract recipe if the scratch dirs are gone:

```
mkdir -p <dir> && tar xf ~/.hex/packages/hexpm/mob-0.7.20.tar -O contents.tar.gz | tar xzf - -C <dir>
mkdir -p <dir> && tar xf ~/.hex/packages/hexpm/mob_new-0.4.20.tar -O contents.tar.gz | tar xzf - -C <dir>
```

**Do not cite** `mishka_chelekom/development/mob/deps/mob` for what published Mob supports — Mishka's
`mix.exs` `tags/1` alias rewrites `priv/tags/*.txt` on every compile.

---

## 1. File inventory — the entire iOS surface is 10 files, 9,345 lines

`mob-0.7.20/ios/`:

| File | Lines | Role |
|---|---:|---|
| `mob_nif.m` | 6,406 | Every NIF. JSON→`MobNode` parser. Test harness (AX tree, synthetic touch). Device/sensor/audio/permission/overlay APIs. |
| `MobRootView.swift` | 1,539 | **The entire renderer.** `MobNodeView` switch, all component views, scroll observer, native-view registry. |
| `mob_beam.m` | 467 | BEAM launcher: OTP root resolution, env, erl args, EPMD thread, node naming. |
| `MobGpuView.swift` | 321 | `MTKView` + MSL fragment shader host. |
| `MobNode.h` | 269 | The node model. `MobNodeType` enum + every prop as an ObjC property. |
| `driver_tab_ios.zig` | 150 | Static NIF/driver table (Zig). Build plumbing. |
| `MobViewModel.swift` | 75 | `ObservableObject` bridge + `MobHostingController` (edge-swipe back) + `MobUIFactory`. |
| `MobNode.m` | 48 | `-init` defaults only. |
| `mob_beam.h` | 41 | 3 prototypes. |
| `MobDemo-Bridging-Header.h` | 29 | 5 C functions Swift calls back into. |

`mob_new-0.4.20/priv/templates/mob.new/ios/` (generated **once** into the app, app-owned thereafter):

| File | Lines |
|---|---:|
| `build.zig.eex` | 672 |
| `build_device.zig.eex` | 770 |
| `AppDelegate.m.eex` | 88 |
| `Info.plist.eex` | 47 |
| `beam_main.m.eex` | 9 |

**There is no `MobRootView.swift.eex` and no `MobNode.h.eex`.** The renderer is *not* forked into the
app the way `MobBridge.kt.eex` is on Android. This is the single most important structural difference
and section 10 works out what it costs.

### 1.1 How Swift gets compiled — and the additive extension point

`ios/build.zig.eex:133-161`:

```zig
// Glob all mob Swift sources so a newly-added file (e.g. MobGpuView.swift,
// referenced by MobRootView) compiles without editing this template.
var swift_entries = mob_ios.iterate();
while (swift_entries.next(glob_io) …) |entry| {
    if (entry.kind == .file and std.mem.endsWith(u8, entry.name, ".swift")) {
        swift_run.addFileArg(.{ .cwd_relative = b.fmt("{s}/ios/{s}", .{ mob_dir, entry.name }) });
    }
}
if (project_swift_sources.len > 0) { … swift_run.addFileArg(…) }
if (plugin_swift_files.len > 0) { … swift_run.addFileArg(…) }
```

Three source pools compile into one Swift module (`-wmo`, `-parse-as-library`) with
`-import-objc-header $MOB_DIR/ios/MobDemo-Bridging-Header.h`:

1. **`$MOB_DIR/ios/*.swift`** — globbed from `deps/mob`. Editing these = forking the dep.
2. **`-Dproject_swift_sources`** — from `mob.exs` `:project_swift_sources`, a list of absolute paths
   (`mob_dev/lib/mob_dev/native_build.ex:6555-6592`, `normalize_ios_swift_source!/1`; commas rejected).
   **This is the app-owned Swift pool. Zero merge cost.**
3. **`-Dplugin_swift_files`** — plugin-contributed Swift.

Because all three land in the *same module*, app Swift can see `internal` Mob types —
`MobNode`, `MobNodeView`, `MobBox`… no, `MobBox`/`MobCanvasView`/`MobTabView`/`MobWKWebView` are
`private struct` (file-private to `MobRootView.swift`). But `MobNodeView` is **internal** (no access
modifier, `MobRootView.swift:214`) so app Swift **can recursively render Mob subtrees**:

```swift
// in a project_swift_sources file — legal today, no fork
MobNodeView(node: someChildNode)
```

`MobNode` itself is `@interface MobNode : NSObject` in a header on the `-I` path, so app Swift reads
every prop. `MobNativeViewRegistry`, `MobNativeSend`, `MobNativeViewFactory`, `MobViewModel`,
`MobHostingController`, `MobUIFactory`, `MobRootView` are all `public`.

### 1.2 Plugin Swift registration is code-generated

`mob_dev/lib/mob_dev/plugin/ios_bootstrap.ex` emits one `@_cdecl("mob_register_plugins")` function:

```elixir
"    MobNativeViewRegistry.shared.register(\"#{view_module}\") { props, _send in",
"        AnyView(#{swift_struct}(props: props))",
"    }"
```

`AppDelegate.m:45-47` calls `mob_register_plugins()` **before** `mob_init_ui()`. A plugin declares
`ui_components.ios.view_module` (registry key, must match `Mob.Component.module_name/1`) and
`ui_components.ios.swift_struct`. A component missing `:swift_struct` is silently dropped.

Note the generated closure discards `send` (`{ props, _send in }`) — **plugin-registered views cannot
emit events back to the BEAM** through the generated bootstrap. Hand-registering from
`project_swift_sources` keeps `send`.

---

## 2. The node-type mapping

### 2.1 The enum — `MobNode.h:21-44`, verbatim

```objc
typedef NS_ENUM(NSInteger, MobNodeType) {
    MobNodeTypeColumn,
    MobNodeTypeRow,
    MobNodeTypeLabel,
    MobNodeTypeButton,
    MobNodeTypeScroll,
    MobNodeTypeBox,
    MobNodeTypeDivider,
    MobNodeTypeSpacer,
    MobNodeTypeProgress,
    MobNodeTypeTextField,
    MobNodeTypeToggle,
    MobNodeTypeSlider,
    MobNodeTypeImage,
    MobNodeTypeLazyList,
    MobNodeTypeTabBar,
    MobNodeTypeVideo,
    MobNodeTypeCameraPreview,
    MobNodeTypeWebView,
    MobNodeTypeNativeView,
    MobNodeTypeIcon,
    MobNodeTypeCanvas,
    MobNodeTypeGpuView,
};
```

22 types. `MobNodeTypeColumn == 0`.

### 2.2 The if/else chain — `mob_nif.m:598-648`, verbatim

```objc
static MobNode *mob_node_from_dict(NSDictionary *dict) {
    if (![dict isKindOfClass:[NSDictionary class]])
        return nil;

    MobNode *node = [[MobNode alloc] init];

    NSString *type = dict[@"type"];
    if ([type isEqualToString:@"column"])
        node.nodeType = MobNodeTypeColumn;
    else if ([type isEqualToString:@"row"])
        node.nodeType = MobNodeTypeRow;
    else if ([type isEqualToString:@"text"] || [type isEqualToString:@"label"])
        node.nodeType = MobNodeTypeLabel;
    else if ([type isEqualToString:@"button"])
        node.nodeType = MobNodeTypeButton;
    else if ([type isEqualToString:@"scroll"])
        node.nodeType = MobNodeTypeScroll;
    else if ([type isEqualToString:@"box"])
        node.nodeType = MobNodeTypeBox;
    else if ([type isEqualToString:@"divider"])
        node.nodeType = MobNodeTypeDivider;
    else if ([type isEqualToString:@"spacer"])
        node.nodeType = MobNodeTypeSpacer;
    else if ([type isEqualToString:@"progress"])
        node.nodeType = MobNodeTypeProgress;
    else if ([type isEqualToString:@"text_field"])
        node.nodeType = MobNodeTypeTextField;
    else if ([type isEqualToString:@"toggle"])
        node.nodeType = MobNodeTypeToggle;
    else if ([type isEqualToString:@"slider"])
        node.nodeType = MobNodeTypeSlider;
    else if ([type isEqualToString:@"image"])
        node.nodeType = MobNodeTypeImage;
    else if ([type isEqualToString:@"lazy_list"])
        node.nodeType = MobNodeTypeLazyList;
    else if ([type isEqualToString:@"tab_bar"])
        node.nodeType = MobNodeTypeTabBar;
    else if ([type isEqualToString:@"video"])
        node.nodeType = MobNodeTypeVideo;
    else if ([type isEqualToString:@"camera_preview"])
        node.nodeType = MobNodeTypeCameraPreview;
    else if ([type isEqualToString:@"web_view"])
        node.nodeType = MobNodeTypeWebView;
    else if ([type isEqualToString:@"native_view"])
        node.nodeType = MobNodeTypeNativeView;
    else if ([type isEqualToString:@"icon"])
        node.nodeType = MobNodeTypeIcon;
    else if ([type isEqualToString:@"canvas"])
        node.nodeType = MobNodeTypeCanvas;
    else if ([type isEqualToString:@"gpu_view"])
        node.nodeType = MobNodeTypeGpuView;
```

**Note there is no trailing `else`.** 22 string comparisons, 23 wire strings (`"text"` and `"label"`
both map to `MobNodeTypeLabel`).

### 2.3 The zero-initialisation fallback — unknown type renders as a **column**

`MobNode.m:8-46` is the whole initialiser. Read it for what is *not* there:

```objc
- (instancetype)init {
    if ((self = [super init])) {
        _textSize = 14.0;
        _padding = 0.0;
        _paddingTop = -1.0;
        …
        _children = [NSMutableArray array];
    }
    return self;
}
```

`_nodeType` is never assigned. ObjC guarantees zero-filled instance variables, and
`MobNodeTypeColumn == 0` is the first enumerator. So:

> **Any node whose `type` string does not match one of the 22 branches renders as a
> `VStack(alignment: .leading, spacing: 0)` that fills width, with its children rendered.**

This is *silent* — no log, no `LOGE`, no red box. `mob_node_from_dict` returns a valid node and
`nif_set_root` (`mob_nif.m:1934-1936`) only nils out on JSON parse failure.

**Android does the opposite.** `MobBridge.kt.eex:2188-2258` is a Kotlin `when` used as a *statement*
with no `else ->` branch, so an unknown type **renders nothing at all** and its children are dropped.

Consequences for Kati:

* A custom node type (`:anchored`, `:sheet`, `:blur_surface`) added on Android-first ships to iOS as a
  bare column of its children. That is *usually the better degradation* — an anchored popover renders
  inline instead of vanishing — but it is degradation, not a fallback you designed.
* Because `Mob.Renderer.prepare/4` does `Atom.to_string(type)` with **no allowlist**
  (`lib/mob/renderer.ex:256-266`), any atom reaches the wire. Nothing on the Elixir side stops you.
* `@component_defaults` (`renderer.ex:181-206`) only has entries for `:button`, `:text_field`,
  `:divider`, `:progress`. A custom type gets no defaults, which is what you want.

### 2.4 Prop parsing — what `mob_node_from_dict` reads (`mob_nif.m:650-1198`)

Every prop is read off `dict["props"]`. Ordering matters in three places:

* `text_field` — `props["value"]` overrides `props["text"]` (`:660-665`), because `value:` is the
  controlled-input name.
* `props["align"]` sets **both** `rowAlign` and `boxAlign` (`:756-760`); the Swift side picks which to
  honour by node type.
* `props["width"]` / `props["height"]` set `fixedWidth`/`fixedHeight` for everything **and
  additionally** `canvasWidth`/`canvasHeight` when `nodeType == MobNodeTypeCanvas` (`:1107-1112`).

Callback props become ObjC blocks capturing an `int handle`; the block calls `mob_send_*(handle)`
which resolves the pid from a double-buffered tap table (`tap_tables[2][MAX_TAP_HANDLES]`,
committed atomically in `nif_set_root` at `:1947-1949`).

`props["on_end_reached"]` is aliased onto `node.onTap` (`:1159-1165`) — a `lazy_list` uses `onTap`
as its end-reached callback, which is why `lazy_list` cannot have both a tap handler and pagination.

---

## 3. SwiftUI rendering, per node type

All of it is `MobNodeView.body` (`MobRootView.swift:217-482`). Two modifiers apply to **every** node,
outside the switch:

```swift
.offset(x: CGFloat(node.offsetX), y: CGFloat(node.offsetY))   // :477
.modifier(MobFrameTracker(node: node))                        // :481
```

`MobFrameTracker` (`:489-509`) is a no-op unless the node carries `id:`; when it does it sets
`.accessibilityIdentifier(id)` and reports `geo.frame(in: .global)` to `mob_register_frame`.

| Type | SwiftUI | Modifiers applied |
|---|---|---|
| `column` | `VStack(alignment:.leading, spacing:0)` | `.frame(maxWidth:.infinity, maxHeight: fillHeight ? .infinity : nil, alignment:.topLeading)` · `.padding(insets)` · `.background(color ?? .clear)` · `.contentShape(Rectangle()).onTapGesture` · `.mobGestures` |
| `row` | `HStack(alignment: rowAlign, spacing:0)` | `.frame(maxWidth:.infinity)` **only if `fill_width`** · padding · background · tap · gestures |
| `box` | `MobBox` → `ZStack(alignment:)` | see 3.1 |
| `label` | `Text` | `.font(resolvedFont)` · `.foregroundColor(textColor ?? .primary)` · `.multilineTextAlignment` · `.lineSpacing` · `.kerning` · conditional `.frame(maxWidth:.infinity, alignment:)` · padding · background · tap · gestures |
| `icon` | `Image(systemName: sfSymbolName(…))` | `.font(.system(size: textSize>0 ? textSize : 20))` · `.foregroundColor` · padding · background · tap · `.accessibilityLabel(node.text)` · `.accessibilityIdentifier(accessibilityId)` · gestures |
| `button` | `Button { onTap } label: { Text }` | padding+background **inside** the label · `.lineLimit(1)` · `.frame(maxWidth: fillWidth ? .infinity : nil)` · `.contentShape(Rectangle())` · `.clipShape(RoundedRectangle(cornerRadius:))` · `.accessibilityIdentifier` |
| `scroll` | `ScrollView(axes, showsIndicators:)` + inner `VStack`/`HStack` | `.scrollDismissesKeyboard(.interactively)` · padding · background · `.accessibilityIdentifier(nativeViewId)` · `.modifier(MobScrollObserverGate)` |
| `text_field` | `MobTextField` | `.padding(insets)` **only** |
| `toggle` | `MobToggle` | `.padding(insets)` only |
| `slider` | `MobSlider` | `.padding(insets)` only |
| `divider` | `Divider()` | `.frame(height: thickness)` · `.overlay(color ?? Color(UIColor.separator))` · padding |
| `spacer` | `Spacer()` | `.frame(width: fixedSize, height: fixedSize)` when `size > 0`, else bare |
| `image` | `MobImage` | `.padding(insets)` |
| `lazy_list` | `ScrollView(.vertical)` + `LazyVStack(alignment:.leading, spacing:0)` | last child `.onAppear { node.onTap?() }` · `.frame(maxHeight:.infinity)` · padding · background · `.accessibilityIdentifier(nativeViewId)` |
| `progress` | `ProgressView()` or `ProgressView(value:total:1.0)` | `.progressViewStyle(.linear)` · `.tint(color ?? .accentColor)` · `.frame(maxWidth:.infinity)` · padding |
| `tab_bar` | `MobTabView` → `TabView(selection:)` | `.tabItem { Label(_, systemImage:) }` · `.tag(id)` · `.ignoresSafeArea(.container, edges:.bottom)` |
| `video` | `MobVideoPlayer` (`AVPlayerViewController`) | conditional `.frame(width:)`/`.frame(height:)` · padding |
| `camera_preview` | `MobCameraPreviewView` (`AVCaptureVideoPreviewLayer`) | same |
| `web_view` | `MobWebView` → `VStack { Text(title)?; MobWKWebView }` | same |
| `native_view` | `MobNativeViewRegistry.shared.view(for:)` | `.padding(insets)` |
| `canvas` | `MobCanvasView` (SwiftUI `Canvas`) | `.padding(insets)` |
| `gpu_view` | `MobGpuView` (`MTKView`) | conditional frames · padding |

`@unknown default: EmptyView()` at `:470-471` is unreachable — the enum is closed and the parser
never produces a value outside it.

### 3.1 `MobBox` — the only node with a full styling chain (`:520-568`)

```swift
return Group {
    if node.fixedWidth > 0 {
        stack.frame(width: CGFloat(node.fixedWidth),
                    height: node.fixedHeight > 0 ? CGFloat(node.fixedHeight) : nil,
                    alignment: alignment)
    } else if node.fillHeight {
        stack.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
    } else {
        stack.frame(maxWidth: .infinity, alignment: alignment)
    }
}
.padding(node.paddingEdgeInsets)
.mobBoxBackground(node: node)
.overlay(
    RoundedRectangle(cornerRadius: node.cornerRadius)
        .stroke(node.borderColor.map { Color($0) } ?? Color.clear, lineWidth: node.borderWidth)
        .allowsHitTesting(false)
)
.ifLet(node.onTap) { view, tap in view.contentShape(Rectangle()).onTapGesture { tap() } }
.mobGestures(node)
```

`border_color` + `border_width` are honoured **on `box` and nowhere else.** The
`.allowsHitTesting(false)` is load-bearing (comment at `:554-557`: without it the overlay swallows
taps on every nested button).

The fixed-width path is the documented trick for circles: `width: N, height: N, corner_radius: N/2`
plus border → a ring, no dedicated primitive (`:517-519`).

### 3.2 Liquid Glass / material — `mobBoxBackground` (`:575-604`)

```swift
if node.useGlass {
    if #available(iOS 26.0, *) {
        self.glassEffect(.clear, in: shape)
    } else {
        self.background(.ultraThinMaterial, in: shape)
    }
} else {
    self.background(node.backgroundColor.map { Color($0) } ?? Color.clear, in: shape)
}
```

`useGlass` is set by the **renderer**, not by the app: `renderer.ex:277-279`

```elixir
defp inject_theme_flags(:box, props, %{flags: %{glass: true}}) do
  if Map.has_key?(props, :background), do: Map.put(props, :glass, true), else: props
end
```

So it is all-or-nothing per theme, only on `:box`, and only when the box already has a `background:`.
Per-node opt-in does not exist. It is also **destructive**: when glass is on, the box's solid
`backgroundColor` is *not drawn at all* — you get `.clear` glass or `.ultraThinMaterial`, never a
tinted material. That is the single hook you have today for backdrop blur, and section 5.2 says what
to do instead.

### 3.3 The modifier vocabulary actually in use

Complete list across `MobRootView.swift` — this is the whole design surface Mob exposes without a fork:

`.frame(width:height:alignment:)` · `.frame(maxWidth:maxHeight:alignment:)` · `.padding(EdgeInsets)` ·
`.padding(.horizontal/.vertical, _)` · `.background(Color)` · `.background(ShapeStyle, in: Shape)` ·
`.overlay(_)` · `.clipShape(RoundedRectangle)` · `.offset(x:y:)` · `.contentShape(Rectangle())` ·
`.allowsHitTesting(_)` · `.font(Font)` · `.foregroundColor(_)` · `.multilineTextAlignment(_)` ·
`.lineSpacing(_)` · `.kerning(_)` · `.lineLimit(1)` · `.tint(_)` · `.progressViewStyle(.linear)` ·
`.textFieldStyle(.roundedBorder)` · `.keyboardType(_)` · `.submitLabel(_)` · `.focused($_)` ·
`.onSubmit` · `.onChange(of:)` · `.onAppear` · `.onTapGesture(count:)` · `.onLongPressGesture` ·
`.gesture(DragGesture)` · `.scrollDismissesKeyboard(.interactively)` · `.onScrollGeometryChange` ·
`.ignoresSafeArea(.container, edges:)` · `.transition(_)` · `.id(_)` · `.tabItem` · `.tag(_)` ·
`.toolbar { ToolbarItemGroup(placement:.keyboard) }` · `.accessibilityLabel` ·
`.accessibilityIdentifier` · `.accessibilityAdjustableAction` · `.glassEffect(_:in:)` (iOS 26+).

**Never used, anywhere in Mob's iOS source:**
`.shadow` · `.blur` · `.opacity` · `.rotationEffect` · `.scaleEffect` (except the startup spinner) ·
`.animation` · `.matchedGeometryEffect` · `.sheet` · `.fullScreenCover` · `.popover` · `.alert` ·
`.confirmationDialog` · `.presentationDetents` · `.presentationBackground` · `.safeAreaInset` ·
`.mask` · `.compositingGroup` · `.drawingGroup` · `.accessibilityValue` · `.accessibilityHint` ·
`.accessibilityAddTraits` · `.accessibilityHidden` · `.accessibilityElement(children:)` ·
`.dynamicTypeSize` · `.environment(\.layoutDirection, _)` · `.textCase` · `.redacted` ·
`.contextMenu` · `.swipeActions` · `.refreshable` · `.searchable` · `.symbolRenderingMode` ·
`.symbolEffect` · `.containerRelativeFrame` · `.visualEffect` · `.scrollTargetBehavior` ·
`.scrollPosition` · `.defaultScrollAnchor` · `.listStyle` (no `List` at all — `LazyVStack` only).

### 3.4 Icon mapping — `sfSymbolName` (`:111-147`)

31 logical names → SF Symbols, `default: return logical` (raw SF Symbol pass-through). Kati can use
`"film"`, `"tv"`, `"popcorn.fill"` etc. directly on iOS via the `:ios` prop block. Android's
`materialIconForLogical` (`MobBridge.kt.eex:3500+`) covers a *different* set and falls back to a
visible `Star` for unknown names — so a raw SF Symbol name on the shared `icon:` prop renders a star
on Android. **Always split icon names through the `:ios`/`:android` prop blocks** (`renderer.ex:293-302`).

### 3.5 Gestures — `mobGestures` (`:60-99`)

`.onLongPressGesture(minimumDuration: 0.5)` · `.onTapGesture(count: 2)` · a single
`DragGesture(minimumDistance: 30).onEnded` that derives one of four directions from
`abs(dx) > abs(dy)` and fires `onSwipe(direction)` *and* the matching `onSwipeLeft/Right/Up/Down`.
Attached only when at least one swipe handler is set — the comment at `:57-59` says explicitly that
attaching it unconditionally would interfere with `ScrollView` and tap behaviours.

`mobGestures` is applied to: `column`, `row`, `box`, `label`, `icon`. **Not** to `button`, `scroll`,
`text_field`, `toggle`, `slider`, `image`, `lazy_list`, `progress`, `divider`, `spacer`, or any of the
UIKit-backed views. A long-press on a poster image needs the image wrapped in a `box`.

### 3.6 Text input — `MobTextField` (`:1118-1205`)

`SecureField` when `secure`, else `TextField`. `.textFieldStyle(.roundedBorder)` is **hardcoded** —
which is why the renderer's `text_field` defaults (`background: :surface_raised`,
`border_color: :border`, `corner_radius: :radius_sm`, `padding: :space_sm`) are all silently
discarded on iOS. Only `padding` survives, applied *outside* the field by `MobNodeView`.

Controlled-input sync at `:1183-1187` — external `value:` changes are only applied when the field is
not focused, so an Elixir-side assign cannot yank the cursor mid-typing.

The keyboard toolbar is guarded (`:1196-1203`): without `if isFocused`, N visible fields produce N
stacked Done buttons.

### 3.7 Canvas — `MobCanvasView` (`:627-804`)

Ops: `line` · `circle` · `ellipse` · `arc` · `rect` (with `radius`) · `path` (polyline, `closed`) ·
`text` (with `anchor` start/center/end, manual measure via `resolved.measure(in:)`) · `image`
(`UIImage(named:)` — **asset-catalog name only, not a file path**).

Stroke style: `width`, `cap` (butt/round/square), `join` (miter/round/bevel), `dash`.
Colours arrive as pre-resolved ARGB ints from `renderer.ex`; a `#rrggbb` string fallback exists.

Documented divergence at `:652-657`: iOS uses `DragGesture(minimumDistance: 0)` so a stationary tap
fires a zero-length began/ended drag; Android's `detectDragGestures` has touch slop so it fires
nothing. Also, iOS canvas gesture coordinates are already in canvas points (the frame is sized to the
declared logical units); **Android needs a px→logical rescale**.

No `arc` fill. No gradient. No `clip`. No transform stack (`ctx.translateBy` etc. unused).

### 3.8 Scroll observation — `MobScrollObserver` (`:1451-1539`)

Gated `if #available(iOS 18.0, *)`. `.onScrollGeometryChange(for: CGPoint.self, of: { $0.contentOffset })`.

> **On iOS 17 every scroll event is silently dead.** `MobScrollObserverGate.body` falls through to
> bare `content`. The renderer still accepts and registers `on_scroll`, `on_scroll_began`,
> `on_scroll_ended`, `on_scroll_settled`, `on_top_reached`, `on_scrolled_past` — the handles are
> allocated, the pids registered, and nothing ever fires (comment at `:350-355`).

Tier 2 semantics derived in Swift: `on_top_reached` fires on `y <= 0.001 && lastY > 0.001`;
`on_scrolled_past` is latched on the threshold transition; `on_scroll_ended`/`on_scroll_settled` come
from a 150 ms debounce `Task` (`endDebounceMs = 150`, `:1481`). Throttling for Tier 1 happens
native-side in `mob_send_scroll` before the BEAM crossing (`MOB_APPLY_THROTTLE` macro,
`mob_nif.m:913-924`, reading `scroll_config` `%{throttle_ms, debounce_ms, delta_threshold, leading, trailing}`).

---

## 4. Props parsed on iOS and then never rendered

`mob_node_from_dict` populates these; **no Swift reads them.** Verified by grep across all `.swift`:

| Prop | `MobNode.h` | Parsed at | Swift readers |
|---|---|---|---|
| `parallax` → `parallaxConfig` | `:122` | `mob_nif.m:1022-1025` | **0** |
| `fade_on_scroll` → `fadeOnScrollConfig` | `:123` | `:1026-1029` | **0** |
| `sticky_when_scrolled_past` → `stickyWhenScrolledPastConfig` | `:124` | `:1030-1033` | **0** |
| `on_pinch` → `onPinch` | `:101` | `:946-953` | **0** |
| `on_rotate` → `onRotate` | `:104` | `:955-962` | **0** |
| `on_pointer_move` → `onPointerMove` | `:108` | `:964-971` | **0** |
| `on_compose` → `onCompose` (IME) | `:139` | `:836-843` | **0** |
| `on_select` → `onSelect` | `:73` | `:845-851` | **0** |
| `content_mode: "stretch"` | `:193` | `:1054-1056` | collapses to `.fit` (`MobImage:1276` only tests `== "fill"`) |
| `placeholder_color` on non-image | `:196` | `:1085-1087` | image only |
| `gap` | — | `renderer.ex:172` resolves it as a spacing token | **0 on both platforms** — `spacing: 0` is hardcoded in every stack |

The `MobNode.h:118-124` comment claims Tier 3 is *"rendered with no BEAM round-trip"*. **It is not
rendered at all.** `on_drag` is the only Tier-1 gesture with a consumer, and only inside
`MobCanvasView` (`:658-683`) — a `box` with `on_drag` gets nothing.

IME composition (`on_compose`) being dead matters for Kati's Persian/Farsi input path: there is no
marked-text signal on iOS. Android's side is worth checking separately before relying on it.

---

## 5. The iOS answers to what the Android reader is costing

For each: what the source says today, the Swift I would write, where it goes, and the merge cost.

### 5.1 Coloured shadows — `.shadow(color:radius:x:y:)`

**Today: absent.** Zero occurrences of `shadow` in any `.swift`, `.m`, or `.h`, and zero occurrences
of `shadow`/`elevation` in Mob's Elixir lib or in `MobBridge.kt.eex`. There is no prop and no plumbing.

SwiftUI shadows are **natively coloured with independent blur and offset**:
`.shadow(color: Color, radius: CGFloat, x: CGFloat, y: CGFloat)` — one modifier, one line, works on
any view, composes on the rendered result. This is a genuine iOS advantage: Compose's
`Modifier.shadow(elevation:shape:clip:ambientColor:spotColor:)` derives blur *and* offset from a
single `elevation` Dp, gives you no x/y control, and honours `ambientColor`/`spotColor` only on
**API 28+**. Matching a design's `0 8px 24px rgba(0,0,0,.18)` on Android means hand-rolling
`drawBehind { drawIntoCanvas { it.nativeCanvas.drawRoundRect(paint.setShadowLayer(...)) } }`.

**What I would write** — `MobNode.h`, after the border block at `:182`:

```objc
// Drop shadow. Rendered on iOS via .shadow(color:radius:x:y:) — a single native
// modifier with independent blur radius and offset. shadowRadius <= 0 means no
// shadow (the default), so the whole feature costs one float compare per node.
@property(nonatomic, strong, nullable) UIColor *shadowColor;
@property(nonatomic) CGFloat shadowRadius; // blur radius in pt; 0 = off
@property(nonatomic) CGFloat shadowX;
@property(nonatomic) CGFloat shadowY;
```

`MobNode.m` `-init`, after `_cornerRadius = 0.0;`:

```objc
_shadowRadius = 0.0;
_shadowX = 0.0;
_shadowY = 0.0;
```

`mob_nif.m`, inside `mob_node_from_dict` next to the border parse at `:729`:

```objc
id shadowColor = props[@"shadow_color"];
if (shadowColor)
    node.shadowColor = color_from_argb((long)[shadowColor longLongValue]);
id shadowRadius = props[@"shadow_radius"];
if (shadowRadius)
    node.shadowRadius = [shadowRadius doubleValue];
id shadowX = props[@"shadow_x"];
if (shadowX)
    node.shadowX = [shadowX doubleValue];
id shadowY = props[@"shadow_y"];
if (shadowY)
    node.shadowY = [shadowY doubleValue];
```

`MobRootView.swift`, a new `View` extension near `mobGestures`:

```swift
extension View {
    /// Drop shadow from a node's shadow_* props. No-op when shadow_radius is 0
    /// (the default), so untagged nodes pay one comparison and no extra layer.
    @ViewBuilder
    func mobShadow(_ node: MobNode) -> some View {
        if node.shadowRadius > 0 {
            self.shadow(
                color: node.shadowColor.map { Color($0) } ?? Color.black.opacity(0.18),
                radius: node.shadowRadius,
                x: node.shadowX,
                y: node.shadowY
            )
        } else {
            self
        }
    }
}
```

Applied once, uniformly, in `MobNodeView.body` — **before** `.offset` at `:477` so the shadow travels
with the node:

```swift
.mobShadow(node)
.offset(x: CGFloat(node.offsetX), y: CGFloat(node.offsetY))
```

Renderer side: add `:shadow_color` to `@color_props` in `renderer.ex:169` and `:shadow_radius`,
`:shadow_x`, `:shadow_y` to `@spacing_props` (or leave them raw floats).

**Cost:** ObjC-C 4 + 3 + 12 = 19 lines; Swift 15 lines; Elixir 1 line.
**~35 lines total, all inside `deps/mob` → a hard fork of `MobNode.h`, `MobNode.m`, `mob_nif.m`,
`MobRootView.swift`.**

There is a **fork-free variant** that costs more Swift but zero merge: register a
`Kati_Shadow` native view that takes a `shadow_*` props bag and renders `MobNodeView(node:)` of a
child that the Elixir side stores in a sibling. It does not work — `native_view` is
`children: []` by construction (`lib/mob/ui.ex:122-124`), so it cannot wrap. **Shadows are
fork-only on iOS.** See section 10.

### 5.2 Real backdrop blur — `.ultraThinMaterial` and the `Material` family

**Today: partially present, in the worst possible shape.** `MobRootView.swift:595` has exactly one
`.background(.ultraThinMaterial, in: shape)`, reachable only when `useGlass` is set, which happens
only when the *whole theme* has `glass: true` and only on a `box` that already has a `background:`.
And when it fires it **discards** the box's background colour.

This is the place where iOS is structurally and permanently better than Android, so it is worth being
precise about why.

* **iOS.** `Material` (`.ultraThinMaterial`, `.thinMaterial`, `.regularMaterial`, `.thickMaterial`,
  `.bar`) is a `ShapeStyle` that samples the *backdrop* — everything already composited behind the
  view — and applies a blur + vibrancy + saturation matrix in the compositor. It is implemented by
  the same `CABackdropLayer` machinery UIKit uses for navigation bars, so it costs roughly what a
  navigation bar costs: one extra offscreen pass on already-composited content, GPU-side, no
  application readback. It is available from iOS 15, needs no capability check, degrades gracefully
  under Reduce Transparency (the system substitutes an opaque fill automatically), and animates.
  On iOS 26 `glassEffect(_:in:)` supersedes it with lensing + specular.
* **Android/Compose.** There is no backdrop-sampling primitive. `Modifier.blur` blurs *the node's own
  content*, which is the opposite of what a frosted card needs. The three real options are:
  (a) `RenderEffect.createBlurEffect` on a `RenderNode` — **API 31+**, and you must arrange for the
  content behind to be recorded into a layer you control;
  (b) `Window.setBackgroundBlurRadius` — **API 31+**, blurs behind the *entire window*, so it is only
  usable for a dialog/popup window, not an inline card;
  (c) Compose 1.7's `GraphicsLayer.record()` + `toImageBitmap()` + blur — a capture/readback per frame.
  All three are additionally gated on `WindowManager.isCrossWindowBlurEnabled()`, which the system
  turns **off** under battery saver, on low-RAM devices, and whenever the OEM decides.

So: **frosted glass is nearly free on iOS and is a per-device gamble on Android.** Any Kati surface
whose design depends on backdrop blur must have a designed opaque fallback, and that fallback will be
the *Android* path, not the iOS one.

**What I would write** — replace the boolean `useGlass` with a material token so it stops being
theme-global and stops eating the background.

`MobNode.h`, replacing `:189`:

```objc
// Backdrop material. nil = solid backgroundColor (the default). Otherwise one
// of "ultra_thin" | "thin" | "regular" | "thick" | "bar". On iOS this is a real
// backdrop-sampling Material; the node's backgroundColor is drawn UNDER it as a
// tint so a themed card keeps its hue. iOS 26+ upgrades to .glassEffect().
@property(nonatomic, copy, nullable) NSString *backdropMaterial;
@property(nonatomic) BOOL useGlass; // legacy theme-wide flag; kept for back-compat
```

`mob_nif.m`, next to the `glass` parse at `:1073`:

```objc
id material = props[@"backdrop"];
if ([material isKindOfClass:[NSString class]])
    node.backdropMaterial = material;
```

`MobRootView.swift`, replacing `mobBoxBackground` (`:575-604`):

```swift
private extension View {
    @ViewBuilder
    func mobBoxBackground(node: MobNode) -> some View {
        let radius = node.cornerRadius
        let shape: AnyShape = radius > 0
            ? AnyShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            : AnyShape(Rectangle())

        if let name = node.backdropMaterial {
            // Tint UNDER material: a Material is translucent, so a low-alpha
            // fill below it reads as a coloured frost rather than replacing it.
            // This is what the old useGlass path got wrong — it dropped the fill.
            self
                .background(node.backgroundColor.map { Color($0) } ?? Color.clear, in: shape)
                .background(mobMaterial(name), in: shape)
        } else if node.useGlass {
            if #available(iOS 26.0, *) { self.glassEffect(.clear, in: shape) }
            else { self.background(.ultraThinMaterial, in: shape) }
        } else {
            self.background(node.backgroundColor.map { Color($0) } ?? Color.clear, in: shape)
        }
    }
}

private func mobMaterial(_ name: String) -> Material {
    switch name {
    case "thin":    return .thinMaterial
    case "regular": return .regularMaterial
    case "thick":   return .thickMaterial
    case "bar":     return .bar
    default:        return .ultraThinMaterial
    }
}
```

**Cost:** ObjC 5 lines, Swift ~30 lines (a rewrite of an existing 30-line function), Elixir 0.
**~35 lines, fork of `MobNode.h` + `mob_nif.m` + `MobRootView.swift`.**
Android's matching implementation is **80-150 lines of Kotlin plus a capability check plus a designed
fallback**, and it will be visibly different on API < 31.

### 5.3 Modal sheets — `.sheet` / `.presentationDetents`

**Today: absent.** Zero `.sheet`, zero `.fullScreenCover`, zero `.presentationDetents`, zero
`.popover` in any Swift file. What Mob has instead:

* `nif_alert_show/3` (`mob_nif.m:5760-5811`) — `UIAlertController` `.alert`, JSON button array with
  `label`/`action`/`style` (`default`/`cancel`/`destructive`), each firing
  `mob_deliver_alert_action(action)`.
* `nif_action_sheet_show/2` (`:5815-5867`) — same, `.actionSheet` style, with an iPad
  `popoverPresentationController` source rect at the bottom-centre.
* `nif_toast_show/2` (`:5871-5934`) — a hand-rolled `UILabel` added to the key window, 12pt corner
  radius, 75% black, 80pt above the bottom, fade 0.25s in / 2.0s or 3.5s hold / 0.25s out.
* Everything else — a `box` with `fill_height: true` and `align: "center"`, per the comment at
  `MobRootView.swift:539-544`.

So a Kati bottom sheet today is a full-screen `box` inside the node tree. What that costs you:
no drag-to-dismiss, no detent snapping, no rubber-band, no dimmed-scrim animation, no corner-radius
morph, no `.presentationBackground(.ultraThinMaterial)`, no keyboard-aware resize, no
`.presentationDragIndicator`, and the sheet participates in the screen's `.id(navVersion)` so a
navigation push tears it down.

**What I would write.** Sheets are a *root-level* concern, so this goes in `MobViewModel` + a
modifier on `MobRootView`, driven by a new NIF — not a node type. That keeps the sheet outside
`navVersion` identity.

`MobViewModel.swift`:

```swift
@Published public var sheetRoot: MobNode?
@Published public var sheetDetents: [String] = ["large"]
@Published public var sheetDragIndicator: Bool = true

@objc public func setSheet(_ node: MobNode?, detents: NSArray, dragIndicator: Bool) {
    DispatchQueue.main.async {
        self.sheetDetents = (detents as? [String]) ?? ["large"]
        self.sheetDragIndicator = dragIndicator
        self.sheetRoot = node
    }
}
```

`MobRootView.swift`, appended to the root `ZStack`'s modifier chain after `:1373`:

```swift
.sheet(isPresented: Binding(
    get: { model.sheetRoot != nil },
    set: { if !$0 { model.sheetRoot = nil; mob_sheet_dismissed() } }
)) {
    if let sheet = model.sheetRoot {
        MobNodeView(node: sheet)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .presentationDetents(detentSet(model.sheetDetents))
            .presentationDragIndicator(model.sheetDragIndicator ? .visible : .hidden)
            .presentationBackground(.regularMaterial)
    }
}

private func detentSet(_ names: [String]) -> Set<PresentationDetent> {
    var out: Set<PresentationDetent> = []
    for n in names {
        if n == "medium" { out.insert(.medium) }
        else if n == "large" { out.insert(.large) }
        else if n.hasSuffix("%"), let f = Double(n.dropLast()) { out.insert(.fraction(f / 100)) }
        else if let h = Double(n) { out.insert(.height(CGFloat(h))) }
    }
    return out.isEmpty ? [.large] : out
}
```

Plus `nif_sheet_present/3` (parse JSON → `mob_node_from_dict` → `[[MobViewModel shared] setSheet:…]`,
~35 lines mirroring `nif_set_root` at `:1916-1956`), `nif_sheet_dismiss/0` (~8 lines),
`void mob_sheet_dismissed(void)` in the bridging header + a `mob_send2` to `:mob_screen` (~12 lines),
2 entries in the `ErlNifFunc` table, and `Mob.Sheet` on the Elixir side (~60 lines: render the
subtree through `Mob.Renderer.prepare` and call the NIF).

**Cost:** Swift ~45, ObjC ~55, Elixir ~60. **~160 lines, fork of `MobViewModel.swift`,
`MobRootView.swift`, `mob_nif.m`, `MobDemo-Bridging-Header.h`.**
Android's equivalent (`ModalBottomSheet` + `rememberModalBottomSheetState`) is **~50 lines of Kotlin
in the already-forked `MobBridge.kt`** — so on this feature Android is the *cheaper* platform,
because the Kotlin file is app-owned and the Swift files are not.

### 5.4 Accessibility — `.accessibilityLabel` / `.accessibilityValue`

**Today: three call sites total.**

| Where | Line | What |
|---|---|---|
| `icon` | `MobRootView.swift:301` | `.accessibilityLabel(node.text)` when `text:` set |
| `MobToggle` | `:1229` | `.accessibilityLabel(label)` — with an explicit comment that SwiftUI's `Toggle("Label", isOn:)` does *not* propagate the string into the control's AX label |
| `MobSlider` | `:1257-1268` | `.accessibilityAdjustableAction` with `step = (max - min) / 10` — because a plain `Slider` emits no AX adjustable action and `Mob.Test.adjust_slider/4` silently no-ops without it |

`.accessibilityIdentifier` appears at `:302` (icon, from `accessibility_id`), `:324-326` (button,
from `accessibility_id`), `:349` (scroll, from `id`), `:412` (lazy_list, from `id`), and `:495`
(`MobFrameTracker`, any node with `id`).

`accessibility_id` itself is derived by the renderer from a **tagged tuple `on_tap`** — see
`renderer.ex:305-309` — so it exists for testability, not for VoiceOver.

**`.accessibilityValue` is used zero times in the renderer.** It appears 6 times in `mob_nif.m`, all
inside the AX-tree *reader* used by the test harness (`nif_ui_tree` / `nif_ui_debug`, which `dlsym`
`AXUIElementCopyAttributeValue` out of AppSupport).

So today: images have no label (VoiceOver announces "image"), a poster grid is 200 unlabelled
elements, a rating box announces its raw digits, no element has a hint, no decorative divider is
hidden, and there is no way to group a card into a single AX element. **Android is the same** —
`MobImage` passes `contentDescription = null` (`MobBridge.kt.eex:2508`) and only the tab-bar icons
get a description. This is symmetric neglect, which means the fix has to be designed once and
implemented twice.

**What I would write** — a single uniform modifier, mirroring `mobGestures`:

`MobNode.h`, near `accessibilityId` at `:238`:

```objc
// Author-facing accessibility. Distinct from accessibilityId, which is a TEST
// identifier derived from a tagged on_tap. These are what VoiceOver speaks.
@property(nonatomic, copy, nullable) NSString *a11yLabel;
@property(nonatomic, copy, nullable) NSString *a11yValue;
@property(nonatomic, copy, nullable) NSString *a11yHint;
@property(nonatomic, copy, nullable) NSString *a11yTraits; // csv: button,header,image,link,selected
@property(nonatomic) BOOL a11yHidden;
@property(nonatomic) BOOL a11yGroup; // collapse subtree into one element
```

`mob_nif.m`, next to `accessibility_id` at `:1194`:

```objc
id a11yLabel = props[@"accessibility_label"];
if ([a11yLabel isKindOfClass:[NSString class]]) node.a11yLabel = a11yLabel;
id a11yValue = props[@"accessibility_value"];
if ([a11yValue isKindOfClass:[NSString class]]) node.a11yValue = a11yValue;
id a11yHint = props[@"accessibility_hint"];
if ([a11yHint isKindOfClass:[NSString class]]) node.a11yHint = a11yHint;
id a11yTraits = props[@"accessibility_traits"];
if ([a11yTraits isKindOfClass:[NSString class]]) node.a11yTraits = a11yTraits;
id a11yHidden = props[@"accessibility_hidden"];
if (a11yHidden) node.a11yHidden = [a11yHidden boolValue];
id a11yGroup = props[@"accessibility_group"];
if (a11yGroup) node.a11yGroup = [a11yGroup boolValue];
```

`MobRootView.swift`:

```swift
extension View {
    /// Author-facing accessibility. Every branch is opt-in; a node with no
    /// accessibility_* props pays six nil/BOOL checks and no view wrapping.
    @ViewBuilder
    func mobAccessibility(_ node: MobNode) -> some View {
        self
            .ifLet(node.a11yGroup ? () : nil) { v, _ in v.accessibilityElement(children: .combine) }
            .ifLet(node.a11yLabel) { v, s in v.accessibilityLabel(s) }
            .ifLet(node.a11yValue) { v, s in v.accessibilityValue(s) }
            .ifLet(node.a11yHint)  { v, s in v.accessibilityHint(s) }
            .ifLet(node.a11yTraits) { v, csv in v.accessibilityAddTraits(mobTraits(csv)) }
            .accessibilityHidden(node.a11yHidden)
    }
}

private func mobTraits(_ csv: String) -> AccessibilityTraits {
    var t = AccessibilityTraits()
    for name in csv.split(separator: ",").map({ $0.trimmingCharacters(in: .whitespaces) }) {
        switch name {
        case "button":   t.insert(.isButton)
        case "header":   t.insert(.isHeader)
        case "image":    t.insert(.isImage)
        case "link":     t.insert(.isLink)
        case "selected": t.insert(.isSelected)
        case "search":   t.insert(.isSearchField)
        case "summary":  t.insert(.isSummaryElement)
        default: break
        }
    }
    return t
}
```

Applied uniformly in `MobNodeView.body` right after `.mobShadow(node)`.

**Cost:** ObjC 6 + 13 = 19 lines; Swift ~35 lines. **~54 lines, fork of `MobNode.h` + `mob_nif.m` +
`MobRootView.swift`.** Android's counterpart is `Modifier.semantics { contentDescription = …;
stateDescription = …; heading(); role = Role.Button }` plus `.clearAndSetSemantics {}` for grouping —
~40 lines of Kotlin inside the already-forked `nodeModifier`, so again *cheaper on Android*.

### 5.5 Dynamic Type — `.font` semantics, and an inconsistency already in the source

`MobNode.resolvedFont` (`MobRootView.swift:165-186`), verbatim:

```swift
var resolvedFont: Font {
    let size: CGFloat = textSize > 0 ? textSize : 16.0
    let weight: Font.Weight = { … }()
    var font: Font
    if let family = fontFamily, !family.isEmpty {
        font = Font.custom(family, size: size)
    } else {
        font = .system(size: size)
    }
    font = font.weight(weight)
    if italic { font = font.italic() }
    return font
}
```

These two branches have **different Dynamic Type behaviour**:

* `Font.system(size:)` — a **fixed** point size. Does not respond to the user's text-size setting at all.
* `Font.custom(_:size:)` — since iOS 14, **scales relative to `.body`** automatically. (The
  non-scaling form is `Font.custom(_:fixedSize:)`, which Mob does not use.)

> **Therefore: on iOS, setting `font:` on a text node silently turns Dynamic Type on for that node,
> and omitting it leaves the node fixed.** A card where the title has `font: "Vazirmatn"` and the
> subtitle does not will change its proportions as the user moves the text-size slider. This is a
> real bug surface for Kati, not a theoretical one.

`icon` is worse — `.font(.system(size: node.textSize > 0 ? node.textSize : 20))` (`:294`), always
fixed. And `MobCanvasView`'s text op uses `.system(size:)` / `.custom(family, size:)` the same
inconsistent way (`:762-765`).

**Android scales everything.** `sizeProp` (`MobBridge.kt.eex:3566-3572`) returns `.sp`, and Compose
`.sp` multiplies by `Configuration.fontScale` unconditionally. So today: **Android text respects the
OS font-size setting; iOS text mostly does not.** Same tree, different accessibility posture.

**What I would write** — make the behaviour explicit and identical for both branches:

```swift
/// Resolved font. `dynamic_type: false` (the default for now — see the
/// migration note) pins the size; true opts the node into Dynamic Type on
/// BOTH the system and custom-family paths, which .custom(_:size:) does
/// implicitly and .system(size:) does not. Without this the two branches
/// disagree and a card's proportions shift when the user changes text size.
var resolvedFont: Font {
    let size: CGFloat = textSize > 0 ? textSize : 16.0
    let weight: Font.Weight = { … }()          // unchanged
    var font: Font
    if let family = fontFamily, !family.isEmpty {
        font = dynamicType
            ? Font.custom(family, size: size, relativeTo: .body)
            : Font.custom(family, fixedSize: size)
    } else {
        font = dynamicType
            ? .system(size: UIFontMetrics(forTextStyle: .body).scaledValue(for: size))
            : .system(size: size)
    }
    font = font.weight(weight)
    if italic { font = font.italic() }
    return font
}
```

Note `UIFontMetrics(forTextStyle:).scaledValue(for:)` reads the *current* trait collection, so a view
using it must be invalidated on a content-size-category change. The robust version wraps the whole
root:

```swift
// MobRootView.body, alongside .onChange(of: colorScheme):
@Environment(\.dynamicTypeSize) private var dynamicTypeSize
…
.onChange(of: dynamicTypeSize) { _, new in
    mob_notify_dynamic_type(String(describing: new))
    model.rootVersion += 1   // force a re-resolve of every scaledValue
}
```

and optionally a cap so a 310% setting cannot destroy a dense list:

```swift
.dynamicTypeSize(...DynamicTypeSize.accessibility2)
```

**Cost:** `MobNode.h` 1 property, `MobNode.m` 1 default, `mob_nif.m` 3 lines, `MobRootView.swift`
~18 lines changed + ~8 added. **~31 lines, fork of all four files.**

### 5.6 RTL — `.environment(\.layoutDirection, .rightToLeft)`

**Today: absent, but far less broken than it sounds — with one live trap.**

Zero occurrences of `layoutDirection` anywhere. SwiftUI derives layout direction from the process
locale, and Mob's geometry is already written in leading/trailing terms, so most of the tree mirrors
for free:

* `MobNode.paddingEdgeInsets` (`:156-162`):

  ```swift
  let right  = paddingRight  >= 0 ? paddingRight  : padding
  let left   = paddingLeft   >= 0 ? paddingLeft   : padding
  return EdgeInsets(top: top, leading: left, bottom: bottom, trailing: right)
  ```

  > **`padding_left` is really `padding_start` and `padding_right` is really `padding_end`.**
  > Under RTL a `padding_left: 16` renders 16pt on the *right* of the screen. Android does the same —
  > `MobBridge.kt.eex:3396-3401` maps `left → start`, `right → end`. So the two platforms agree, but
  > the prop *names* lie. Document this in Kati's component usage rules; it is exactly the kind of
  > thing that produces a bug report six months in.

* `textAlignEnum` (`:188-194`) — `"left" → .leading`, `"right" → .trailing`. Also mirrors, also
  misnamed.
* `boxAlignmentFromString` (`:606-620`) — `"leading"/"trailing"/"top_trailing"/"bottom_leading"` are
  RTL-aware; `"center"`, `"top"`, `"bottom"` are direction-neutral. Correct.
* `HStack` child order mirrors automatically.

What does **not** mirror: `offset_x` (raw `.offset(x:)`, `:477`), everything in `canvas` (raw
coordinates), `MobGpuView` UVs, and the swipe-direction strings in `mobGestures` (`:83-87`) — a
"forward" swipe in RTL still reports `"right"`. `MobHostingController`'s back gesture is hardcoded to
`edgePan.edges = .left` (`MobViewModel.swift:58`), which is **wrong in RTL** — iOS's own back swipe
comes from the trailing edge, i.e. the right, under RTL.

Kati needs **app-controlled** direction, not system-locale-derived, because the in-app language is a
user setting independent of the device locale.

**What I would write** — `MobViewModel.swift`:

```swift
/// App-controlled layout direction. Kati's UI language is a user setting that
/// does not have to match the device locale, so the direction cannot come from
/// Locale.current. "ltr" | "rtl"; anything else means "follow the system".
@Published public var layoutDirection: String = "system"

@objc public func setLayoutDirection(_ d: String) {
    DispatchQueue.main.async { self.layoutDirection = d }
}
```

`MobRootView.body`, appended after `.ignoresSafeArea(...)` at `:1373`:

```swift
.ifLet(model.layoutDirection == "rtl" ? LayoutDirection.rightToLeft
     : model.layoutDirection == "ltr" ? LayoutDirection.leftToRight
     : nil) { view, dir in
    view.environment(\.layoutDirection, dir)
}
```

and `MobHostingController.viewDidLoad` (`MobViewModel.swift:54-60`):

```swift
// The back gesture lives on the LEADING edge, which is the right edge in RTL.
// Hardcoding .left sends Farsi users hunting for a back swipe that isn't there.
edgePan.edges = MobViewModel.shared.layoutDirection == "rtl" ? .right : .left
```

Plus a `nif_set_layout_direction/1` (~14 lines ObjC) and `Mob.Device.set_layout_direction/1`.

**Cost:** Swift ~20 lines, ObjC ~16 lines, Elixir ~10. **~46 lines, fork of `MobViewModel.swift`,
`MobRootView.swift`, `mob_nif.m`.** Android's equivalent is
`CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Rtl)` around the root in
`MainActivity.kt` — **~6 lines in an app-owned file.** Android wins again on cost, iOS wins on
correctness of the underlying primitives.

### 5.7 Variable-font axes — `UIFontDescriptor`

**Today: absent.** Zero occurrences of `UIFontDescriptor`, `CTFontDescriptor`, `kCTFontVariationAttribute`.
Font resolution is `Font.custom(family, size:)` — which resolves a **named instance** by PostScript
name and gives no axis control. A variable Vazirmatn or Inter ships as one file whose axes you cannot
reach; you can only pick whatever named instances the font exposes, by name.

There is a second, sharper problem in the font pipeline. `mob_dev/lib/mob_dev/native_build.ex:4857-4885`:

* **iOS** — `plan_ios_font_bundle` uses `&Path.basename/1` (`plugin/assets.ex:111-113`), copies the
  file to the `.app` root, and appends the **basename** to `UIAppFonts`. `Font.custom(name, size:)`
  then resolves by **PostScript name**.
* **Android** — `plan_android_font_copies` normalises to `lowercase + [^a-z0-9_] → _`
  (`assets.ex:128-135`), and `MobBridge.kt.eex:3479-3491` looks it up with
  `resources.getIdentifier(resName, "font", packageName)`.

> A single `font: "Vazirmatn-Regular"` prop therefore means *"the PostScript name"* on iOS and
> *"`vazirmatn_regular.ttf` in res/font"* on Android. They coincide only when the file basename
> happens to equal the PostScript name. **Both platforms fail silently** — iOS falls back to the
> system font, Android falls through to `Typeface.create(name, NORMAL)` which also silently returns
> the default. Verify per font, on device, or route `font:` through the `:ios`/`:android` prop blocks.

**What I would write** for axes:

```swift
/// Variable-font axis application. `axes` maps a 4-char axis tag ("wght",
/// "wdth", "slnt", "opsz") to a value. Resolves the family to a UIFont, applies
/// kCTFontVariationAttribute, and hands the result back as a SwiftUI Font.
/// Falls back to the plain named-instance path when the family is unknown or
/// exposes no variation axes — silently, the way Font.custom already does.
private func mobVariableFont(family: String, size: CGFloat, axes: [String: Double]) -> Font {
    guard !axes.isEmpty else { return Font.custom(family, size: size) }
    var variations: [UInt32: Double] = [:]
    for (tag, value) in axes {
        let bytes = Array(tag.utf8)
        guard bytes.count == 4 else { continue }
        let key = (UInt32(bytes[0]) << 24) | (UInt32(bytes[1]) << 16)
                | (UInt32(bytes[2]) << 8)  |  UInt32(bytes[3])
        variations[key] = value
    }
    guard !variations.isEmpty else { return Font.custom(family, size: size) }
    let desc = UIFontDescriptor(fontAttributes: [
        .name: family,
        UIFontDescriptor.AttributeName(kCTFontVariationAttribute as String): variations
    ])
    return Font(UIFont(descriptor: desc, size: size))
}
```

Wired into `resolvedFont`, with `node.fontAxes` parsed from `props["font_axes"]`
(`%{"wght" => 450, "opsz" => 18}` → `NSDictionary`).

**Cost:** `MobNode.h` 1 property, `mob_nif.m` 4 lines, `MobRootView.swift` ~26 lines.
**~31 lines, fork of three files.**
Compose has first-class support — `Font(resId, variationSettings = FontVariation.Settings(FontVariation.weight(450)))`
since Compose 1.5 / API 26 — so Android is **~10 lines** here and is the better platform for variable
fonts *given that its bridge is already forked*.

---

## 6. Where iOS is structurally better or worse, per Kati need

| Kati need | iOS | Android | Verdict |
|---|---|---|---|
| **Backdrop blur** (frosted sheet, poster-derived scrim) | `Material` / `glassEffect` — real backdrop sampling, compositor-side, iOS 15+, auto-degrades under Reduce Transparency | no primitive; API 31+ `RenderEffect` on a layer you record yourself, gated on `isCrossWindowBlurEnabled()` | **iOS much better.** Design the Android fallback first; iOS gets the good one free. |
| **Coloured shadow** with blur+offset | `.shadow(color:radius:x:y:)`, one line, exact | `elevation`-derived, no x/y, `ambientColor`/`spotColor` API 28+; exact match needs `setShadowLayer` on a native canvas | **iOS better.** ~35 lines vs ~40 + API gate. |
| **Poster grid / image caching** | bare `AsyncImage` + `URLSession.shared`; no decoded-bitmap cache, re-decodes on identity change | **Coil 2.6.0** (`build.gradle.eex:121`) with memory (25% heap) + disk cache | **Android much better.** See 7.5. |
| **Scroll-driven UI** (parallax header, collapsing toolbar) | `onScrollGeometryChange` iOS **18+ only**; dead on 17; Tier-3 configs parsed and ignored | Compose `ScrollState.value` is readable at any API | **Android better today.** Both need work; iOS needs a UIKit fallback for 17. |
| **Dynamic Type** | fixed unless `font:` set (see 5.5) — inconsistent | `.sp` everywhere, always scales | **Android better today**, iOS better after 5.5 (SwiftUI's `relativeTo:` + caps are richer than raw `sp`). |
| **RTL** | leading/trailing throughout; back-swipe edge hardcoded wrong | same leading/trailing; direction via one `CompositionLocal` | **Tie on correctness, Android cheaper to switch.** |
| **Modal sheets / detents** | `.sheet` + `.presentationDetents` + `.presentationBackground(.material)` are excellent — but unwired | `ModalBottomSheet` in the already-forked file | **iOS better primitive, Android cheaper to reach.** |
| **Icons** | SF Symbols with raw pass-through (`sfSymbolName` default) — enormous vocabulary, weight/scale-aware | Material Symbols via a fixed `when` map, unknown → visible Star | **iOS better.** Route names through `:ios`/`:android` blocks. |
| **Custom node types** | requires forking `deps/mob` (3 files) | Kotlin-only in an app-owned file (`MobAnchored` proves it) | **Android dramatically better.** This is the big one — section 10. |
| **GPU / shaders** | `MobGpuView` (Metal, MSL) — real, working, 321 lines | `MobGpuView` exists on the Kotlin side too | Parity, but shaders are per-platform source. |
| **Charts** | SwiftUI `Canvas` via `canvas` node; no `Swift Charts` binding | Compose `Canvas`; no Vico binding | Parity via `canvas`; both need `native_view` for anything richer. |
| **Text rendering quality** | Core Text; `.kerning`, `.lineSpacing` wired | Compose text; `letterSpacing`, `lineHeight` wired | Parity in what's exposed. Neither exposes `.tracking` vs `.kerning`, ligature control, or `AttributedString`. |
| **Safe area** | root does `.ignoresSafeArea(.container, edges: [.bottom, .horizontal])` — top respected, bottom **not** | `Modifier.fillMaxSize().safeDrawingPadding()` — **all** edges inset | **Asymmetric.** iOS content runs under the home indicator; Android does not. |
| **Video** | `AVPlayerViewController` — real player, real controls | `MobVideoPlayer` renders a `Text("Video: $src")` placeholder (`MobBridge.kt.eex:3298`) | **iOS much better** — Android's video node is a stub. |
| **Startup UX** | branded phase text + spinner + red startup-error screen (`MobRootView.swift:1342-1371`) | equivalent in `MainActivity` | Parity. |

---

## 7. Every cross-platform asymmetry that would make a component behave differently

Ordered by how likely it is to bite Kati.

**7.1 Unknown node type.** iOS → renders as a **column** with children (zero-init fallback, §2.3).
Android → renders **nothing**, children dropped (no `else ->`, `MobBridge.kt.eex:2188-2258`).

**7.2 Adding a node type.** iOS → edit `MobNode.h` + `mob_nif.m` + `MobRootView.swift`, all inside
`deps/mob`. Android → edit one `when` arm in the app-owned `MobBridge.kt`. `MobAnchored`
(`mishka_chelekom/development/mob/android/app/src/main/java/com/example/mishka_mob/MobBridge.kt`,
dispatch `:2436`, `MobAnchored` `:2471-2607`, `MobAnchoredPositionProvider` `:2610-2698`) is ~230
Kotlin lines in an app-owned file, zero merge cost. The iOS equivalent is ~200 Swift lines **plus a
dep fork**.

**7.3 `column` fill-width.** iOS `column` is **unconditionally** `.frame(maxWidth: .infinity)`
(`:229`). Android `Column(modifier = m)` fills only when `fill_width: true`
(`nodeModifier`, `:3410`). A column of chips hugs its content on Android and spans the screen on iOS.

**7.4 `row` fill-width.** Both conditional on `fill_width` — but iOS applies it via
`.ifLet(node.fillWidth ? () : nil)` at `:253` and Android via `nodeModifier`. Parity here.

**7.5 Image loading.** iOS `AsyncImage(url:)` with the default `URLSession.shared` — no decoded-image
cache, so scrolling a poster grid re-downloads (HTTP cache permitting) and **always re-decodes**;
`URLCache` is never configured anywhere in Mob (0 occurrences). Android uses **Coil 2.6.0** with a
real two-tier cache. Also, iOS treats a non-`http(s)` `src` as `UIImage(contentsOfFile:)`
(`:1296`) — a **synchronous main-thread disk read + decode** on every re-render; Android wraps it in
`java.io.File` and hands it to Coil, which is async and cached.

**7.6 `content_mode: "stretch"`.** Android → `ContentScale.FillBounds` (`:2485`). iOS →
`node.contentModeStr == "fill" ? .fill : .fit` (`:1276`), so `"stretch"` silently becomes `.fit`.

**7.7 Child `weight:`.** Android honours `weight` on direct children of `column`/`row`
(`Modifier.weight(w)`, `:2190-2199`). iOS ignores it entirely — the prop is not in `MobNode.h`, not
parsed, not read. A 2:1 split works on Android and collapses to content-size on iOS. Note `weight`
is also absent from `Mob.UI` — it is an undocumented Android-only extra.

**7.8 `gap`.** `renderer.ex:172` resolves `:gap` as a spacing token. **Neither platform reads it.**
`spacing: 0` on every iOS stack; Compose default (0) on Android. Spacing must be `spacer` nodes.

**7.9 Border.** iOS honours `border_color`/`border_width` on **`box` only** (`MobBox`, `:551-561`).
Android's `nodeModifier` applies it to **every** node type (`:3382-3387`). A bordered `row` or
bordered `text` works on Android and renders unbordered on iOS.

**7.10 Corner radius.** iOS honours `corner_radius` on `box` (background shape + border overlay),
`button` (`.clipShape`, `:323`) and `image` (`.clipShape`, `:1311`). Android's `nodeModifier` clips
**every** node (`:3408`).

**7.11 Background.** iOS applies `background` on `column`, `row`, `box`, `label`, `icon`, `scroll`,
`lazy_list`, `button` (inside the label). **Not** on `text_field`, `toggle`, `slider`, `progress`,
`divider`, `spacer`, `image`, `video`, `web_view`, `camera_preview`, `canvas`, `gpu_view`,
`native_view`. Android applies it to all of them via `nodeModifier`.

**7.12 `text_field` styling.** iOS hardcodes `.textFieldStyle(.roundedBorder)` (`:1188`) and drops
the renderer's `background`/`border_color`/`corner_radius` defaults. Android's `MobTextField` honours
them via `nodeModifier`. **The same text field looks different on the two platforms out of the box.**

**7.13 Gestures.** iOS `mobGestures` is attached only to `column`/`row`/`box`/`label`/`icon`.
Android's `tapModifier` (`:2179-2183`) attaches `clickable` to **every** type except `button`. Swipes
on iOS come from a `DragGesture(minimumDistance: 30)`; on Android from whatever the bridge wires.

**7.14 Scroll events.** iOS 18+ only, silently dead on 17 (§3.8). Android has no such floor.

**7.15 Tier-1/Tier-3 props.** `on_pinch`, `on_rotate`, `on_pointer_move`, `on_compose`, `on_select`,
`parallax`, `fade_on_scroll`, `sticky_when_scrolled_past` — parsed on iOS, **rendered by nothing**
(§4). Check each against the Android bridge before designing on them.

**7.16 Canvas tap.** iOS fires a zero-length `began`/`ended` drag on a stationary tap; Android's
touch slop fires nothing (comment `MobRootView.swift:652-657`). Canvas coordinates need a px→logical
rescale on Android and none on iOS.

**7.17 Safe area.** iOS root: `.ignoresSafeArea(.container, edges: [.bottom, .horizontal])` (`:1373`)
— top inset applied, bottom and sides not. Android root: `Modifier.fillMaxSize().safeDrawingPadding()`
(`MainActivity.kt.eex:234`) with `enableEdgeToEdge()` (`:138`) — **all** edges inset. A bottom bar
sits under the home indicator on iOS and above the nav bar on Android.

**7.18 `tab_bar`.** iOS renders a real `TabView` with `.tabItem`/`.tag` — a functioning iOS tab bar
(`MobTabView`, `:885-913`). The Android side's `tab_bar` behaviour must be checked separately (prior
research flags the docs as wrong about it rendering a NavigationBar).

**7.19 Video.** iOS = real `AVPlayerViewController` with autoplay/loop/controls. Android's
`MobVideoPlayer` renders `Text("Video: $src")` (`MobBridge.kt.eex:3298`) — a placeholder.

**7.20 `set_theme`.** iOS `nif_set_theme` is an **explicit no-op** (`mob_nif.m:1907-1911`, with the
comment that Android needs it to drive Material 3's NavigationBar/Button colours). Any theme effect
you see on Android chrome has no iOS counterpart.

**7.21 Font name resolution.** PostScript name (iOS) vs normalised resource name (Android). Both fail
silently to the system font. §5.7.

**7.22 Icon vocabulary.** Different maps, different fallbacks (iOS passes unknown names through to SF
Symbols; Android shows a Star).

**7.23 `padding_left`/`padding_right` are start/end** on both platforms. Consistent, but misnamed.
§5.6.

**7.24 Back gesture.** iOS: `UIScreenEdgePanGestureRecognizer(.left)` on the hosting controller
(`MobViewModel.swift:56-59`) → `mob_handle_back()`. Wrong edge under RTL. Android: system back.

**7.25 Plugin-registered views cannot send events on iOS.** The generated bootstrap discards `send`
(`ios_bootstrap.ex:91`); Android's `MobNativeViewRegistry.render` builds a working `send` from
`component_handle` (`MobBridge.kt.eex:2144-2154`). A plugin component that needs to talk back must be
hand-registered from `project_swift_sources`.

**7.26 `native_view` cannot wrap children on either platform.** `Mob.UI.native_view/2` hardcodes
`children: []` (`lib/mob/ui.ex:124`), and both registries pass only `props` + `send`
(`MobNativeViewFactory` on both sides). Any composite that must contain Mob-rendered children —
an anchored popover, a shadowed card wrapper, a blur surface — **cannot** be built as a
`native_view`. This is why `MobAnchored` had to be a real node type.

**7.27 `exit_app`.** `nif_exit_app` returns `:ok` and does nothing on iOS, by design
(`mob_nif.m:1212-1219`).

**7.28 USB.** Every `vendor_usb_*` NIF is an iOS stub (`mob_nif.m:6179+`).

---

## 8. The known iOS sharp edges, re-confirmed in source

**8.1 DNS.** Confirmed. `nif_resolve_ipv4/1` (`mob_nif.m:6033-6121`), dirty-IO-scheduled. The comment
at `:6035-6040`:

> *"BEAM's normal DNS path (`inet_gethost`, a port-program subprocess) is unrunnable on iOS — the
> sandbox forbids execve of bundled helper binaries. getaddrinfo is a libc function that runs in the
> app process with no exec / no sandbox interaction."*

Returns `{:ok, {a,b,c,d}}` / `{:error, :badarg | :nxdomain | :timeout | :no_address | {:gai, code}}`.
App code must use `Mob.DNS.resolve/1`, which seeds `:inet_db` so Req/Finch/Mint find the host.
**Every Kati network call to TMDB must go through a path that has been DNS-seeded.**

**8.2 Memory / BEAM flags.** Confirmed, `mob_beam.m:347-348`:

```c
static const char *s_default_flags[] = {"-S", "1:1",   "-SDcpu", "1:1",    "-SDio", "1", "-A",
                                        "1",  "-sbwt", "none",   "-MIscs", "128",   NULL};
```

**One scheduler, one dirty-CPU scheduler, one dirty-IO scheduler, async thread pool of 1, no busy
wait.** The `-MIscs 128` comment (`:340-346`) explains that iOS cannot reserve OTP's default 1 GB
literal super-carrier and falls back to ~10 MB; 128 MB is a `MAP_NORESERVE` virtual reservation that
iOS accepts. A previously-appended hardcoded `-MIscs 10` used to silently override it (allocator
flags are last-wins) and crashed `Mix.install`.

Overridable at runtime from `beams_dir/mob_beam_flags` (`:350-378`), written by
`mix mob.deploy --schedulers N` / `--beam-flags`.

**Implication for Kati:** with `-S 1:1` there is exactly one scheduler. Any long CPU work in a screen
process blocks every other process including the renderer. TMDB JSON decoding of a large response,
image-derived colour extraction, and RRULE expansion all need `Task` + dirty scheduling or explicit
yielding.

**8.3 `dlopen`.** Confirmed, `mob_nif.m:21-30`:

```c
// dlopen/dlsym are marked unavailable in iOS SDK headers but exist at runtime
// in the iOS Simulator (macOS). Declare prototypes directly to bypass the header
// restriction. On a real device these will be NULL (weak symbols).
extern void *dlopen(const char *path, int mode) __attribute__((weak));
extern void *dlsym(void *handle, const char *symbol) __attribute__((weak));
extern char *dlerror(void) __attribute__((weak));
```

`dlopen` is **simulator-only**. It is used exclusively by the AX test harness (`load_ax()`,
`g_AXCopyAttr`, `:3641-3653`). Consequence: **every NIF must be statically linked** —
`driver_tab_ios.zig` / `mob.exs` `:static_nifs`, regenerated by `mix mob.regen_driver_tab`. Any
Kati dependency shipping a `.so`-style NIF must be added there or it will not load on device.

**8.4 `UIBackgroundModes: [audio]`.** Confirmed, `Info.plist.eex:33-36`:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

`audio` is the **only** background mode. Absent: `fetch`, `processing`, `remote-notification`,
`location`, `bluetooth-central`, `voip`. So on iOS, Kati gets background execution **only** while
audio is actually playing. There is no `BGAppRefreshTask`, no `BGProcessingTask`, no silent-push
wake. Any "sync in the background" design must be Android-only or user-foreground on iOS.

Also absent from the generated plist, and needed the moment Kati touches these:
`NSCameraUsageDescription` · `NSPhotoLibraryUsageDescription` · `NSPhotoLibraryAddUsageDescription` ·
`NSCalendarsUsageDescription` / `NSCalendarsFullAccessUsageDescription` (**required for the
`CalendarContract`-equivalent `EventKit` path, issue #52**) · `NSContactsUsageDescription` ·
`NSLocationWhenInUseUsageDescription` · `NSFaceIDUsageDescription` · `NSUserTrackingUsageDescription` ·
`CFBundleLocalizations` / `CFBundleDevelopmentRegion` (**i18n**) · `ITSAppUsesNonExemptEncryption` ·
`UIUserInterfaceStyle` · `NSAppTransportSecurity` · `UIViewControllerBasedStatusBarAppearance` ·
`UIAppFonts` (injected at build time by `apply_fonts_to_ios_bundle!`, `native_build.ex:4860-4885`).

Only `NSMicrophoneUsageDescription` is present. **Missing a usage-description string is a hard crash
at first use, not a denial.**

Good news on cost: `ios/Info.plist` is generated **once** by `mix mob.new`
(`mob_new/lib/mix/tasks/mob.new.ex:327`) and thereafter is app-owned — `mob_dev` only `File.cp!`s it
into the `.app` (`native_build.ex:4184-4185`, `:4376-4377`) and `PlistBuddy Add`s plugin keys on top,
with "project Info.plist wins" semantics (`:4422-4426`). **Extending it is zero merge cost.**

**8.5 Image caching.** Confirmed. `MobImage` (`MobRootView.swift:1272-1313`) is a bare `AsyncImage`
with no `URLSession` configuration, no `URLCache`, no `.cacheResponse`, no image-level memoisation:

```swift
AsyncImage(url: url) { phase in
    switch phase {
    case .success(let image): image.resizable().aspectRatio(contentMode: contentMode)
    default: placeholder
    }
}
```

`AsyncImage` caches nothing itself; it relies on `URLSession.shared`'s `URLCache.shared` (HTTP-level,
default ~512 KB memory / ~10 MB disk on iOS, and only when TMDB's `Cache-Control` allows it). Every
view-identity change re-decodes. In a poster grid this is the dominant scroll cost.

**What I would write** — and this one is **fork-free**, because it can live entirely in a
`project_swift_sources` file plus one `native_view` registration:

```swift
// Kati/ios/KatiPoster.swift — listed in mob.exs :project_swift_sources.
// A decoded-image cache in front of AsyncImage. AsyncImage has none: it defers
// to URLCache (HTTP bytes only) and re-decodes on every view identity change,
// which in a poster grid is the whole scroll cost.
import SwiftUI

final class KatiImageCache {
    static let shared = KatiImageCache()
    private let memory = NSCache<NSString, UIImage>()
    private init() {
        memory.totalCostLimit = 96 * 1024 * 1024   // decoded bytes, not file bytes
        // Bump the shared HTTP cache too — the default is far too small for
        // a TMDB poster wall and every miss becomes a network round trip.
        URLCache.shared = URLCache(memoryCapacity: 32 * 1024 * 1024,
                                   diskCapacity: 256 * 1024 * 1024,
                                   diskPath: "kati_img")
    }
    func image(for url: URL) -> UIImage? { memory.object(forKey: url.absoluteString as NSString) }
    func store(_ img: UIImage, for url: URL) {
        let cost = Int(img.size.width * img.size.height * img.scale * img.scale * 4)
        memory.setObject(img, forKey: url.absoluteString as NSString, cost: cost)
    }
}

struct KatiPoster: View {
    let props: [String: Any]
    @State private var loaded: UIImage?

    private var url: URL? { (props["src"] as? String).flatMap(URL.init(string:)) }
    private var w: CGFloat { CGFloat((props["width"]  as? Double) ?? 0) }
    private var h: CGFloat { CGFloat((props["height"] as? Double) ?? 0) }
    private var radius: CGFloat { CGFloat((props["corner_radius"] as? Double) ?? 0) }

    var body: some View {
        Group {
            if let img = loaded {
                Image(uiImage: img).resizable().aspectRatio(contentMode: .fill)
            } else {
                Color(UIColor.systemGray5)
            }
        }
        .frame(width: w > 0 ? w : nil, height: h > 0 ? h : nil)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .accessibilityLabel((props["accessibility_label"] as? String) ?? "")
        .task(id: url) { await load() }
    }

    private func load() async {
        guard let url else { return }
        if let hit = KatiImageCache.shared.image(for: url) { loaded = hit; return }
        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let img = UIImage(data: data) else { return }
        // Force decode off the main thread so the first paint doesn't stutter.
        let decoded = await Task.detached(priority: .userInitiated) { () -> UIImage in
            let fmt = UIGraphicsImageRendererFormat.default()
            fmt.scale = img.scale
            return UIGraphicsImageRenderer(size: img.size, format: fmt).image { _ in
                img.draw(at: .zero)
            }
        }.value
        KatiImageCache.shared.store(decoded, for: url)
        loaded = decoded
    }
}
```

Registered from a project Swift file (keeping `send` available, unlike the generated bootstrap):

```swift
MobNativeViewRegistry.shared.register("Kati_Poster") { props, _ in AnyView(KatiPoster(props: props)) }
```

Elixir: `Mob.UI.native_view(Kati.Poster, src: url, width: 120, height: 180, corner_radius: 8)`.

**Cost:** ~75 Swift lines, **zero merge cost** — it lives in Kati, not in `deps/mob`.
Android needs no counterpart (Coil already does this).

---

## 9. iOS NIF surface — the complete capability list

From `mob_nif.m:6279-6382` (`ErlNifFunc mob_funcs[]`), grouped:

**UI/render** — `set_root/1` · `set_transition/1` · `set_theme/1` (**no-op**) · `register_tap/1` ·
`clear_taps/0` · `register_component/1` · `deregister_component/1`
**Test harness** — `ui_tree/0` · `ui_view_tree/0` · `ui_debug/0` · `screen_info/0` · `tap/1` ·
`tap_xy/2` · `ax_action/2` · `ax_action_at_xy/3` · `type_text/1` · `delete_backward/0` ·
`key_press/1` · `clear_text/0` · `long_press_xy/3` · `swipe_xy/4` · `screenshot/3` · `scroll_info/1` ·
`scroll_to/3` · `element_frames/0`
**Device** — `platform/0` · `color_scheme/0` · `battery_level/0` · `device_set_dispatcher/1` ·
`device_battery_state/0` · `device_thermal_state/0` · `device_network_state/0` ·
`device_low_power_mode/0` · `device_foreground/0` · `device_os_version/0` · `device_model/0` ·
`device_orientation/0` · `device_lock_orientation/1` · `device_keep_awake/1` · `safe_area/0`
**Overlays** — `alert_show/3` · `action_sheet_show/2` · `toast_show/2`
**Media/audio** — `audio_start_recording/1` · `audio_stop_recording/0` ·
`audio_start_input_metering/0` · `audio_input_level/0` · `audio_stop_input_metering/0` ·
`audio_play/2` · `audio_play_at/3` · `audio_stop_playback/0` · `audio_set_volume/1` ·
`audio_output_status/0` · `audio_output_level/1` · `tts_speak/2` · `tts_stop/0`
**Sensors/hardware** — `motion_start/2` · `motion_stop/0` · `haptic/1` · `torch/1`
**Storage/system** — `storage_dir/1` · `storage_save_to_photo_library/1` ·
`storage_save_to_media_store/2` · `storage_external_files_dir/1` · `files_pick/1` ·
`clipboard_put/1` · `clipboard_get/0` · `share_text/1` · `open_url/1` · `open_settings/1` ·
`request_permission/1` · `take_launch_notification/0` · `take_opened_document/0` · `log/1` · `log/2` ·
`exit_app/0` (**no-op**)
**WebView** — `webview_eval_js/1` · `webview_post_message/1` · `webview_can_go_back/0` ·
`webview_go_back/0`
**Network** — `resolve_ipv4/1`
**Stubs** — `vendor_usb_*` (7 functions)

`nif_haptic/1` (`:2023-2051`) maps `success`/`error`/`warning` → `UINotificationFeedbackGenerator`,
`light`/`heavy`/anything-else → `UIImpactFeedbackGenerator` `Light`/`Heavy`/`Medium`.

`nif_screen_info/0` (`:3812-3850`) returns `%{width, height, scale, safe_area: %{top, bottom, left, right}}`
in **logical points**. `nif_safe_area/0` (`:1831-1848`) returns the 4-tuple `{Top, Right, Bottom, Left}` —
note the *different ordering* between the two.

---

## 10. Extension-cost model — the drift ledger (#32)

This is the answer to "how many lines of Swift and where do they live".

| Where the code lives | Merge cost on `mix deps.update mob` | What can go here |
|---|---|---|
| `mob.exs :project_swift_sources` → Kati-owned `.swift` files | **Zero.** Never overwritten. | Any `View`, any `UIViewRepresentable`, any registry registration, any `NSCache`, any `URLCache` config, any `EventKit`/`StoreKit`/`PhotoKit` wrapper. Can call `MobNodeView(node:)` to render Mob subtrees. Can read every `MobNode` prop. |
| `ios/Info.plist` | **Zero.** Generated once by `mix mob.new`; `mob_dev` only copies it. Plugin keys are `PlistBuddy Add`ed with project-wins semantics. | Usage descriptions, `UIBackgroundModes`, localizations, ATS. |
| `ios/AppDelegate.m`, `ios/beam_main.m`, `ios/build.zig` | **Zero.** App-owned. | Boot ordering, extra registrations, extra frameworks, plugin bootstrap. |
| A Mob plugin (`ui_components.ios.swift_struct`) | **Zero for the host**, but the plugin's manifest form loses `send`. | Reusable components shared across apps. |
| **`deps/mob/ios/*.{h,m,swift}`** | **Permanent, per-release, three-file merge.** | New node types, new uniform modifiers (shadow, a11y, Dynamic Type), `MobNode` props, sheets, layout direction. |

**The asymmetry with Android is stark and it is the central architectural fact:**

* Android's `MobBridge.kt` is a **template** — `mob_new` copies it into `android/app/src/main/java/`
  at `mix mob.new` time and it is app-owned forever. Mishka's is 4,607 lines vs the template's 3,635:
  **972 lines of app-owned Kotlin, including `MobAnchored`, with zero merge obligation.**
* iOS's `MobRootView.swift` is a **library file** globbed out of `deps/mob/ios/` at build time. There
  is no template, no copy step, no app-owned equivalent. Editing it means vendoring `mob` (a `path:`
  or forked-git dep) and re-merging `MobRootView.swift` + `MobNode.h` + `mob_nif.m` on every Mob
  release. `mob_nif.m` is 6,406 lines and changes often.

### 10.1 Recommended Kati policy

1. **Everything that can be a `native_view` should be**, and should live in
   `:project_swift_sources`. Zero merge cost. Covers: the poster/image cache (§8.5), charts, any
   leaf-shaped custom rendering, `EventKit` bridges, anything platform-specific with no Mob children.
2. **Accept `native_view`'s hard limit**: it cannot wrap children (`children: []` at
   `lib/mob/ui.ex:124`). Composites that must contain Mob-rendered subtrees are the only reason to
   fork.
3. **Batch the fork.** If Kati is going to fork `deps/mob/ios`, do it *once*, and land shadow (§5.1,
   35), backdrop material (§5.2, 35), accessibility (§5.4, 54), Dynamic Type (§5.5, 31), layout
   direction (§5.6, 46), variable-font axes (§5.7, 31) and sheets (§5.3, 160) in the same fork.
   **Total ≈ 390 lines across 4 files** — and critically, five of the seven are *uniform modifiers
   applied once in `MobNodeView.body`*, which is a small, stable, easy-to-re-merge diff. The sheet
   work is the one that touches structure.
4. **Prefer upstreaming.** Shadow, accessibility props and a `backdrop:` material token are
   framework-shaped, not Kati-shaped. A PR to `mob` costs less over five years than a fork.
5. **Mirror every fork on Android.** Every one of the seven is *cheaper* in Kotlin because
   `MobBridge.kt` is already forked. Never let the iOS fork be the only implementation — that is how
   the platforms diverge.

### 10.2 Concrete cost table

| Gap | iOS lines | iOS files touched | Fork? | Android lines | Android files |
|---|---:|---|---|---:|---|
| Coloured shadow | ~35 | `MobNode.h/.m`, `mob_nif.m`, `MobRootView.swift` | **yes** | ~40 + API-28 gate | `MobBridge.kt` (owned) |
| Backdrop material | ~35 | `MobNode.h`, `mob_nif.m`, `MobRootView.swift` | **yes** | ~80–150 + API-31 gate + fallback | `MobBridge.kt` (owned) |
| Modal sheet + detents | ~160 | +`MobViewModel.swift`, bridging header, Elixir | **yes** | ~50 | `MobBridge.kt` (owned) |
| Accessibility props | ~54 | `MobNode.h`, `mob_nif.m`, `MobRootView.swift` | **yes** | ~40 | `MobBridge.kt` (owned) |
| Dynamic Type | ~31 | `MobNode.h/.m`, `mob_nif.m`, `MobRootView.swift` | **yes** | 0 (already `.sp`) | — |
| RTL override | ~46 | `MobViewModel.swift`, `MobRootView.swift`, `mob_nif.m` | **yes** | ~6 | `MainActivity.kt` (owned) |
| Variable-font axes | ~31 | `MobNode.h`, `mob_nif.m`, `MobRootView.swift` | **yes** | ~10 | `MobBridge.kt` (owned) |
| Image cache / poster | ~75 | Kati-owned `.swift` | **no** | 0 (Coil) | — |
| A new node type (e.g. `anchored`) | ~200 | `MobNode.h`, `mob_nif.m`, `MobRootView.swift` | **yes** | ~230 | `MobBridge.kt` (owned) |
| `EventKit` calendar bridge (#52) | ~120 + plist keys | Kati-owned `.swift` + `Info.plist` | **no** | ~150 | app-owned Kotlin |

---

## 11. Verification appendix — searched for and confirmed absent

Grepped across all of `mob-0.7.20/ios/*.{swift,m,h}` (and, where noted, `mob_new`'s Android template
and Mob's Elixir lib). Zero occurrences:

`shadow` · `elevation` · `presentationDetents` · `presentationBackground` · `fullScreenCover` ·
`popover` · `confirmationDialog` · `dynamicTypeSize` · `layoutDirection` · `UIFontDescriptor` ·
`CTFontDescriptor` · `URLCache` · `URLSessionConfiguration` · `accessibilityValue` (render path;
6 hits in the AX *reader*) · `accessibilityHint` · `accessibilityAddTraits` · `accessibilityHidden` ·
`accessibilityElement` · `matchedGeometryEffect` · `drawingGroup` · `compositingGroup` ·
`safeAreaInset` · `refreshable` · `searchable` · `contextMenu` · `swipeActions` · `List(` ·
`symbolRenderingMode` · `symbolEffect` · `visualEffect` · `scrollTargetBehavior` · `scrollPosition` ·
`redacted` · `BGTaskScheduler` · `EventKit` · `PhotosUI` · `StoreKit`.

`sheet` — 6 hits in `mob_nif.m`, all comments or `action_sheet_show` (never SwiftUI `.sheet`).
`Material` — 3 hits in `MobRootView.swift` (all `.ultraThinMaterial` at `:595` plus its comments),
2 in `MobNode.h` comments, 2 in `mob_nif.m` (`storage_save_to_media_store` naming).
`shadow`/`elevation` in `MobBridge.kt.eex` — **also zero.** Neither platform has ever had shadows.

Props declared in `MobNode.h` with **zero Swift readers**: `parallaxConfig`, `fadeOnScrollConfig`,
`stickyWhenScrolledPastConfig`, `onPinch`, `onRotate`, `onPointerMove`, `onCompose`, `onSelect`.
Props resolved by `Mob.Renderer` with zero readers on **either** platform: `gap`.
Props read on Android with zero readers on iOS: `weight`.

---

## 12. One-paragraph summary for the design review

iOS gives Kati **better primitives and a worse extension story**. `Material` backdrop blur,
`.shadow(color:radius:x:y:)`, `.sheet` + `.presentationDetents`, SF Symbols and `AVPlayerViewController`
are all materially better than their Compose counterparts — and every one of them except the video
player is currently **unwired** in Mob. Wiring them costs ~390 lines across four files that live in
`deps/mob`, i.e. a permanent fork, because unlike Android's `MobBridge.kt` (app-owned, already 972
lines ahead of the template in Mishka) the SwiftUI renderer is a library file. The escape hatch that
costs nothing is `mob.exs :project_swift_sources` + `MobNativeViewRegistry` — good for leaves like a
cached poster view (which iOS badly needs, since Android has Coil and iOS has bare `AsyncImage`), and
useless for anything that must wrap Mob-rendered children, because `native_view` is `children: []` by
construction. The two behaviours most likely to bite before any of that: an unknown node type renders
as a **column** on iOS and as **nothing** on Android, and scroll events are **silently dead on iOS 17**.
