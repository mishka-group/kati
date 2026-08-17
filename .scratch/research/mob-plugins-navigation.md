# Mob — plugins, navigation/performance, animation (source-verified)

Research date: **2026-08-17**. Everything below is read from **real source**, not from
hexdocs prose. Where the published docs contradict the source, the contradiction is
stated explicitly and both sides are quoted.

## 0. How to reproduce these citations

The hex tarballs were already in the local hex cache. Extracted with:

```bash
mkdir -p /tmp/mobsrc && cd /tmp/mobsrc
for p in mob-0.7.20 mob_dev-0.6.23 mob_new-0.4.20 mob_camera-0.1.3 mob_themes-0.1.0; do
  mkdir -p "$p" && tar xf ~/.hex/packages/hexpm/$p.tar -C "$p"
  mkdir -p "$p/src" && tar xzf "$p/contents.tar.gz" -C "$p/src"
done
```

Versions confirmed current via `https://hex.pm/api/packages/mob`:
`latest_stable_version = "0.7.20"`, `latest_version = "0.7.20"` (releases run
`0.7.20, 0.7.19, … 0.7.9`). **0.7.20 is the newest published mob.** This matters for §A.6.

Citation convention below: `<package> · <path-inside-package>:<line>`. In a real Kati
checkout those live at `deps/mob/…`, `deps/mob_dev/…`, and — for `mob_new` templates —
**inside your own app** at `android/app/src/main/java/…` (see §A.5).

Source layout of `mob 0.7.20` (93 files): `lib/mob/*.ex` (Elixir), `src/mob_nif.erl`
(NIF stubs), `android/jni/*.zig` (Android NIF in Zig), `ios/*.m|.swift` (iOS NIF +
SwiftUI renderer), `priv/tags/{android,ios}.txt` (tag whitelist).
**The Android Compose renderer is NOT in the `mob` package** — it is generated into your
app by `mob_new` from `priv/templates/mob.new/android/app/src/main/java/MobBridge.kt.eex`
(3 635 lines) and `MainActivity.kt.eex` (375 lines).

---

# A. The plugin system

## A.1 The five tiers — what they actually are

Tier is **derived**, not declared. `MobDev.Plugin.Manifest.tier/1` classifies a plugin by
which manifest sections are present (highest wins):

```elixir
# mob_dev 0.6.23 · lib/mob_dev/plugin/manifest.ex:686-697
def tier(nil), do: 0
def tier(m) when is_map(m) do
  cond do
    has_any?(m, @subapp_sections) -> 4   # [:lifecycle, :settings, :notifications]
    has_any?(m, @screen_sections) -> 3   # [:screens, :screens_generator, :migrations, :assets]
    has_any?(m, @visual_sections) -> 2   # [:ui_components, :ui_components_generator]
    has_any?(m, @tier1_sections)  -> 1   # [:nifs, :nifs_generator, :android, :ios, :permissions]
    true -> 1
  end
end
```

(section constants at `manifest.ex:21-36`)

| Tier | Trigger sections | Contributes | Hot-pushable? |
|---|---|---|---|
| 0 | *no `priv/mob_plugin.exs` at all* | plain Elixir modules | `true` |
| 1 | `:nifs`, `:android`, `:ios`, `:permissions` | C/ObjC/Zig/C++ NIFs, Kotlin bridge class, Swift files, gradle deps, Android permissions, AndroidManifest snippets, `res/` files, Info.plist keys, iOS frameworks, permission capabilities | `false` (or `:partial`) |
| 2 | `:ui_components` | native view registrations **or** pure-Elixir composite expanders | `false` if native-backed; `true` if `expand:`-only |
| 3 | `:screens`, `:screens_generator`, `:migrations`, `:assets` | `Mob.Screen` modules + routes, Ecto migrations (namespaced), fonts, images (`plugin://…`) | `:partial` |
| 4 | `:lifecycle`, `:settings`, `:notifications` | `on_start`/`on_resume`/`on_background` MFAs, supervised children, a typed settings schema + editor screen, notification handlers | `:partial` |

Docs agree on the tier names (<https://mob.hexdocs.pm/plugins.html>: *"Tier 0: Pure-Elixir
helpers (no manifest)… Tier 4: Lifecycle hooks + supervised workers + settings +
notifications"*, and *"Tiers are cumulative in spirit but independent in the manifest — a
tier-4 plugin can also ship NIFs and screens"*). The **derivation rule and hot-push
classification are undocumented on hexdocs**; they are only in the source:

```elixir
# manifest.ex:706-715  — hot_pushable/1
cond do
  not has_any_native?(m) -> true
  has_any?(m, @pushable_sections) -> :partial   # [:screens, :screens_generator, :lifecycle, :migrations]
  true -> false
end
```

Note `:ui_components` counts as "native" **only** when an entry carries `:ios`/`:android`
(`manifest.ex:722-735`) — an `expand:`-only UI kit stays fully hot-pushable.

`@supported_spec_versions [1, 2]` (`manifest.ex:19`). Spec-v2 unlocks
`:screens_generator` / `:ui_components_generator` / `:nifs_generator`
(`manifest.ex:390-410`); `:screens` and `:screens_generator` are mutually exclusive.

## A.2 What a plugin may contribute — the complete validated manifest surface

Every key below is enforced by `MobDev.Plugin.Manifest.validate/1` (`manifest.ex:79-103`).
This is the authoritative list; hexdocs' `mob_plugins.html` matches it except where noted.

**Required** (`manifest.ex:109-137`):
- `:name` — atom
- `:mob_version` — a `Version.parse_requirement/1`-valid string (e.g. `"~> 0.7"`)
- `:plugin_spec_version` — integer in `[1, 2]`

**Native / build-time:**
- `:nifs` — list of `%{module: :atom, native_dir: "path", lang: :c | :objc | :zig | :cpp_archive, platform: :ios | :android}`.
  `lang` defaults to `:c` (`merge.ex:219`). `:objc` is implicitly Apple-only (`merge.ex:231-236`).
  `:cpp_archive` additionally requires `:sources` (paths or `{:dep, name, subpath}`) and
  `:nm_symbol`, which **must** equal `"<module>_nif_init"` (`manifest.ex:342-357`).
- `:android` — `%{bridge_kt:, bridge_class:, jni_source:, gradle_deps: [..], permissions: [..], manifest_application_snippets: [xml..], res_files: [..], min_sdk:}`.
  `res_files` must contain a `res` path segment and must not contain `..` (path-traversal guard, `manifest.ex:209-240`).
- `:ios` — `%{swift_files: [..], frameworks: [..], plist_keys: %{}, min_version:}`.
- `:permissions` — `[%{capability: :atom, ios: %{handler: "c_symbol"}}]`. Android needs
  nothing here: the provider is auto-discovered by interface (`manifest.ex:141-143`).

**Visual:**
- `:ui_components` — each entry needs `:tag` (PascalCase string) + `:atom` (snake_case),
  then **exactly one of**: native backing (`:ios` and/or `:android`) **or**
  `expand: {Module, :function}`. Mixing both is a validation error
  (`manifest.ex:572-602`):
  ```
  "ui_components entry #N mixes expand: with native backing — pick one
   (a composite that needs a native part should emit Mob.UI.native_view)"
  ```

**Screens / data / assets:**
- `:screens` — `[%{module: Mod, default_route: "/path"}]`; optional `:params` become
  route-bound params (`plugins.ex:117-127`).
- `:screens_generator` — `{M, :f, args}`, spec-v2 only.
- `:migrations` — `%{repo_namespace: "prefix_", migrations_dir: "path"}`.
- `:assets` — `%{fonts: [..], images: [..]}`.

**Sub-app:**
- `:lifecycle` — `%{on_start: mfa, on_resume: mfa, on_background: mfa, supervised: [child_spec]}`.
- `:settings` — `%{schema: [%{key:, type:, default:}], editor_screen: Mod}`.
  `type` ∈ `[:boolean, :string, :integer]` **only** (`manifest.ex:491`, enforced again at
  runtime in `Mob.Plugins.valid_setting?/2`, `plugins.ex:236-239`).
- `:notifications` — `%{handlers: [%{match: map | {M,F,arity}, handler: {M,F,arity}}]}`.
  **Anonymous functions are explicitly forbidden** — the handler set is serialised into a
  terms file and *"closures don't survive that"* (`manifest.ex:654-656`).

**Misc:** `:host_requirements` (list of non-empty strings, printed as build warnings),
`:host_config_keys` (spec-v2 generator audit allow-list, `plugin.ex:37-55`),
`:description`, `:setup` (documented on hexdocs; **no validator clause exists in
0.6.23** — treat as UNVERIFIED).

### Cross-plugin conflict surface

`MobDev.Plugin.Validator.conflict_surface/0` (`validator.ex:233-270`) classifies **every**
Merge gatherer as `:collision` / `:namespaced` / `:union` / `:build_time` / `:derived`, and
a test asserts full coverage. Hard build errors on duplicate: screen route, `ui_components.atom`,
`ios.view_module`, `android.composable`, migration `repo_namespace`, NIF module, cpp_archive
`nm_symbol`, Swift/JNI source basename, `android.bridge_class`, AndroidManifest component
`android:name`, `res_files` destination, Info.plist key, supervised worker, notification match.

## A.3 Ed25519 signing — the real scheme

`MobDev.Plugin.Crypto` (`mob_dev · lib/mob_dev/plugin/crypto.ex`) is the only crypto:

```elixir
# crypto.ex:39-42
def generate_keypair do
  {pub, priv} = :crypto.generate_key(:eddsa, :ed25519)
  {priv, pub}
end

# crypto.ex:53-56
def sign(payload_term, priv_bin) when is_binary(priv_bin) do
  payload = canonical_encode(payload_term)
  :crypto.sign(:eddsa, :sha512, payload, [priv_bin, :ed25519])
end

# crypto.ex:98-101 — the host-visible trust id
def fingerprint(pub_bin) when is_binary(pub_bin) do
  digest = :crypto.hash(:sha256, pub_bin)
  "ed25519:" <> Base.encode64(digest)
end

# crypto.ex:112-114 — determinism
def canonical_encode(term), do: :erlang.term_to_binary(term, [:deterministic, minor_version: 2])
```

`verify/3` rescues `ArgumentError`/`ErlangError` so an attacker-supplied wrong-size key or
sig returns `{:error, :invalid_signature}` instead of crashing (`crypto.ex:83-85`).

**What is signed** (`sign.ex:89-95`):

```elixir
%{manifest: <loaded manifest>, file_hashes: [{rel_path, sha256}, ...], envelope_version: 1}
```

`file_hashes` covers `ios.swift_files`, `android.bridge_kt`, `android.jni_source`,
`android.res_files`, and a recursive walk of each NIF `native_dir` filtered to
`[".c", ".h", ".cpp", ".zig"]` (`sign.ex:28`, `sign.ex:148-190`).
**Kotlin `bridge_kt` is hashed; `.kt` files inside a `native_dir` are NOT** (extension
filter excludes `.kt`) — a gap worth knowing.

Artefacts: `priv/mob_plugin.pub` (base64 raw 32-byte public key, committed) and
`priv/mob_plugin.sig` (binary `term_to_binary` of `%{signature:, envelope_version: 1}`).
Real example from `mob_camera 0.1.3 · priv/mob_plugin.pub`:
`Fdps1S9I5/BFuCIS6WOpQ0s7Rf98zvsc04wWy4+IqIE=`.
Private key lives at `~/.mob/keys/<plugin_name>.priv`, mode 0600, never shipped
(`mix mob.plugin.keygen` moduledoc, `lib/mix/tasks/mob.plugin.keygen.ex:7-25`).

**Host gate** — `MobDev.Plugin.SignatureGate.raise_on_signature_drift!/1`
(`signature_gate.ex:77-86`), invoked from `Validator.raise_on_capability_drift!/1` so all
three build paths (iOS sim, iOS device, Android) enforce it. Four failure modes
(`signature_gate.ex:29-34`, messages at `:201-229`):

| Error | Suppressible? |
|---|---|
| `{:missing_signature, name}` | yes, via `config :mob, :acknowledge_unsafe_plugins, [:name]` + a permanent stderr banner (`signature_gate.ex:94-128`) |
| `{:missing_pubkey, name}` | no |
| `{:invalid_signature, name}` | no — *"can indicate tampering with the plugin's manifest or source files"* |
| `{:untrusted, name, actual_fp, trusted_fp}` | no — run `mix mob.plugin.trust <name>` |

Trust lives in `mob.exs` as `config :mob, :trusted_plugins, %{name => "ed25519:…"}`. The
`mob_new` template pre-trusts all first-party plugins with one shared release key
(`mob_new · priv/templates/mob.new/mob.exs.eex`), e.g.
`mob_camera: "ed25519:nc56w+1Kx0gIt/4EkHxnMZCKHMzp4+S5kS/HoSzEZkg="`.

Docs agree the fingerprint is stable across re-signs: *"does **not** change when you
re-sign new content, so a host's trust record stays valid across releases"*
(<https://mob.hexdocs.pm/plugins.html>) — true, since it hashes the *public key*, not the payload.

## A.4 Activation and the two runtime paths

Activation is a **second, separate opt-in** from being a dep:

```elixir
# mob_dev · lib/mob_dev/plugin.ex:87-100
def activated_names do
  config_file = Path.join(File.cwd!(), "mob.exs")
  if File.exists?(config_file) do
    config_file |> Config.Reader.read!() |> Keyword.get(:mob, []) |> Keyword.get(:plugins, [])
  else
    Application.get_env(:mob, :plugins, [])
  end
end
```

Two entirely different wiring mechanisms:

**(a) Build-time / native** — `MobDev.Plugin.Merge` gathers per concern
(`merge.ex`): `nifs/1`, `android_permissions/1`, `gradle_deps/1`,
`android_manifest_snippets/1`, `android_res_files/1`, `ios_frameworks/1`,
`swift_files/1`, `bridge_kt_sources/1`, `bridge_classes/1`, `jni_sources/1`,
`nif_sources/2`, `zig_nif_sources/2`, `static_archives/2`, `plist_keys/1`.
`MobDev.NativeBuild` consumes them (`native_build.ex:162-165`), splicing gradle/manifest
edits inside **reversible fenced regions** (`MobDev.Plugin.ManagedBlock`, regenerated whole
each build so a removed plugin's lines vanish — `managed_block.ex:1-31`).

**(b) Runtime / Elixir** — `MobDev.Plugin.RuntimeManifest.build/1` emits
`priv/generated/mob_plugins.exs` (`runtime_manifest.ex:33-50`, `:127-152`) carrying
`screens, lifecycle, settings, notification_handlers, nifs, composites, styles, default_style`.
On device, `Mob.Plugins.boot/1` reads it into `:persistent_term` and wires it up:

```elixir
# mob 0.7.20 · lib/mob/plugins.ex:79-86
def boot(otp_app) when is_atom(otp_app) do
  load(otp_app)
  ensure_nif_modules_loaded()
  register_screens()
  register_composites()
  apply_default_style()
  :ok
end
```

called from the generated `MyApp.App.start/0` (`lib/mob/app.ex:109`), before
`Mob.State`, `Mob.ComponentRegistry`, `Mob.Device`, then
`Mob.Plugins.start_lifecycle()` (`app.ex:154`) and finally your `on_start/0` (`app.ex:156`).

`register_screens/0` inserts `String.to_atom(default_route) → {module, params}` into
`Mob.Nav.Registry` (`plugins.ex:111-131`). Note the route **atom is the whole route
string**, e.g. `:"/mob_camera/demo"`.

Settings are namespaced in `Mob.State` under `{:plugin_setting, plugin, key}`
(`plugins.ex:225`) with type validation on write (`plugins.ex:186-208`).
Notification dispatch runs **inside the screen GenServer**, first-match-wins, crash-isolated
(`plugins.ex:255-266`, called from `screen.ex:514-520`).

## A.5 Interaction with `MobBridge` — precisely

`MobBridge.kt` is a **template rendered once into your app** at `mix mob.new`
(`mob_new · priv/templates/mob.new/android/app/src/main/java/MobBridge.kt.eex`, first line
`package <%= java_package %>`). `MobDev.NativeBuild` **never rewrites it** — it only writes
these generated files into `android/app/src/main/java/io/mob/plugin/`
(`native_build.ex:4532-4547`): `MobPluginBootstrap.kt`, `MobActivityAware.kt`,
`MobPermissionProvider.kt`, `MobNotifyHub.kt`. ⇒ **`MobBridge.kt` and `MainActivity.kt`
are yours to edit and they survive rebuilds.**

The BEAM→Compose contract is two JNI statics:

```kotlin
// MobBridge.kt.eex:626-639
@JvmStatic
fun setRootJson(json: String, transition: String) {
    val newKey = if (transition != "none") {
        lazyListStates.clear(); scrollHandlesById.clear(); elementFramesById.clear()
        _rootState.value.navKey + 1
    } else { _rootState.value.navKey }
    _rootState.value = RootState(newKey, transition, JSONObject(json).toMobNode())
}
```

called from `mob 0.7.20 · android/jni/mob_nif.zig:1540`
(`CallStaticVoidMethod(jenv, Bridge.cls, Bridge.set_root, jjson, jtransition)`), which is
`:mob_nif.set_root/1` (`src/mob_nif.erl:261`).

**A plugin's Kotlin path** (the automated one, `native_build.ex:5035-5081`):
`android.bridge_kt` is copied into the app source tree at its own `package`-derived path,
and `android.bridge_class` gets a generated
`io.mob.plugin.MobPluginBootstrap.registerAll(activity)` that calls
`<class>.register()`, `handOff(<class>, activity)`, `collectPermissionProvider(<class>)`
(`native_build.ex:5148-5205`). `MainActivity.onCreate` calls `registerAll(this)`.
This is how `mob_camera` reaches CameraX:

```elixir
# mob_camera 0.1.3 · priv/mob_plugin.exs:35-51
android: %{
  bridge_kt: "priv/native/android/MobCameraBridge.kt",
  bridge_class: "io.mob.camera.MobCameraBridge",
  permissions: ["android.permission.CAMERA", "android.permission.RECORD_AUDIO"],
  gradle_deps: ["androidx.camera:camera-camera2:1.3.4",
                "androidx.camera:camera-lifecycle:1.3.4",
                "androidx.camera:camera-view:1.3.4"]
}
```

## A.6 ⚠️ Can a plugin add a NEW renderable node type natively? — **No.** (Direct answer)

This is the crux for `:anchored`. Verified three ways.

**1. The node dispatch is a closed `when` in your app's Kotlin.**
`MobBridge.kt.eex:2186-2258` — 22 cases, **no `else` branch**:

```kotlin
when (node.type) {
    "column" -> …  "row" -> …  "box" -> …  "scroll" -> …
    "text" -> MobText(node, m)          "button" -> MobButton(node, m)
    "tab_bar" -> MobTabBar(node, m)     "text_field" -> MobTextField(node, m)
    "toggle" -> …  "slider" -> …  "divider" -> …  "spacer" -> …
    "progress" -> …  "image" -> …  "icon" -> …  "lazy_list" -> MobLazyList(node, m)
    "video" -> …  "camera_preview" -> …  "web_view" -> …
    "native_view" -> MobNativeViewRegistry.render(node)
    "canvas" -> MobCanvas(node, m)      "gpu_view" -> MobGpuView(node, m)
}
```

An **unknown type on Android renders nothing at all** — no error, no children.
On iOS it's worse-but-softer: `mob_nif.m:600-648` is an if/else chain over the type string
with no default, and `MobNode.nodeType` defaults to `0 == MobNodeTypeColumn`
(`ios/MobNode.h:21-43`) ⇒ **unknown types on iOS silently render as a Column**, children
included. (Mishka's own doc says the same: *"An unknown node type on iOS falls through to
`MobNodeTypeColumn`"* — `mishka_chelekom/priv/mob/kit/anchored.eex:76-79`.)

The BEAM-side whitelist is only advisory: `Mob.Sigil` validates tags against
`priv/tags/{ios,android}.txt` and *"Unknown tags emit a warning but still pass through"*
(`lib/mob/sigil.ex:76-81`). Android tag list (`priv/tags/android.txt`), 22 entries:
`Box Button Column Divider Image LazyList List Progress Row Scroll Slider Spacer TabBar
Text TextField Toggle Video CameraPreview WebView GpuView` (+ `Icon`, `Canvas`).
**`Anchored` is not there, and `grep -rni anchored` across mob 0.7.20 returns only two
unrelated prose hits in `lib/mob/alert.ex`.** With 0.7.20 being the newest hex release,
**no published mob renders `:anchored`.** Mishka's `usage-rules/mob/preview_card.md:165`
claims *"The `:anchored` node is rendered by `MobAnchored` in the Android bridge"* — that
`MobAnchored` exists in **no published mob**. Treat Mishka's mob layer as targeting an
unreleased mob/fork.

**2. `ui_components.android.composable` is consumed by nothing.**
`grep -rn "composable" mob_dev/lib` outside the validator returns only `scaffold.ex:498`
(the scaffold template that *writes* it). The build never reads it. The scaffold says so
in its own generated comment:

```
# mob_dev · lib/mob_dev/plugin/scaffold.ex:508-513
// Until the plugin merge engine wires plugin Kotlin into the build
// automatically, the host app developer copies this content into
// MobBridge.kt (alongside the MobNativeViewRegistry definition) and
// arranges <Mod>Plugin.register() to run at startup — the documented
// workflow for native components today.
```

and `mix mob.new_plugin --tier 2` prints the same
(`lib/mix/tasks/mob.new_plugin.ex:138-145`): *"copy priv/native/android/<Mod>.kt into the
host's MobBridge.kt … (Mix automation of this step is a future merge-engine slice.)"*

**iOS is the exception and IS automated**: `MobDev.Plugin.IOSBootstrap.swift_source/1`
generates `mob_plugin_bootstrap.swift` with one
`MobNativeViewRegistry.shared.register("<view_module>") { props, _send in AnyView(<swift_struct>(props: props)) }`
per component (`ios_bootstrap.ex:87-98`), written at `native_build.ex:2429` and called from
`AppDelegate.m` via `@_cdecl("mob_register_plugins")`. **So `ui_components` native backing
works on iOS and is a no-op on Android.** (Kati is Android-first — this is the wrong way round for you.)

Note also `mob_dev`'s hexdocs claim the renderer dispatches
*"`case .chart:` → `MobChartView(node: node)`"* / *"`"chart" -> MobChart(node, m)`"*
(<https://mob.hexdocs.pm/mob_plugins.html>). **No such codegen exists in 0.6.23.** That is
aspirational documentation.

**3. Even `native_view` can't host Mob children.** The one *supported* native extension
point takes props only — no node, no children, on either platform:

```kotlin
// MobBridge.kt.eex:2133-2134
typealias MobNativeSend = (event: String, payload: Map<String, Any>) -> Unit
typealias MobNativeViewFactory = @Composable (props: Map<String, Any?>, send: MobNativeSend) -> Unit
```
```swift
// mob 0.7.20 · ios/MobRootView.swift:20-21
public typealias MobNativeViewFactory = (_ props: [String: Any], _ send: @escaping MobNativeSend) -> AnyView
```

and `Mob.UI.native_view/2` hard-codes `children: []` (`lib/mob/ui.ex:122-124`).
A `:native_view` also **requires a `Mob.Component` process** (handle injected at
`lib/mob/component.ex:132-141`; Kotlin bails without `component_handle`, `MobBridge.kt.eex:2144`),
and there are only **64 component slots** (`android/jni/mob_nif.zig:941`).

`Mob.Registry` (the "widget name → NIF constructor" map the older research mentioned) is
**vestigial** — `grep -rn "Mob.Registry"` across mob + mob_dev returns only its own file.
Nothing calls it.

### ⇒ The clean fix for `:anchored` is NOT a plugin

Options, ranked:

1. **Edit your own `MobBridge.kt`** (recommended for Kati). Add
   `"anchored" -> MobAnchored(node, m)` to the `when` at `MobBridge.kt.eex:2240-2257`
   and write the composable over `androidx.compose.ui.window.Popup`. It is *your* file
   (§A.5) — `mix mob.deploy --native` will not clobber it. This is the only path that
   gives you a node with **Mob-rendered children**, which `:anchored` requires (child 0 =
   anchor in flow, child 1 = panel in its own window). Cost: an Android-only fork-in-place
   of one Kotlin function; iOS degrades to a Column (acceptable — iOS is later for Kati).
2. **Wrap it as a tier-1 plugin for reuse** — put the Kotlin in `android.bridge_kt` +
   `android.bridge_class` so it is *copied and registered* automatically. This works for
   registering side-effects, **but the `when` dispatch still lives in `MobBridge.kt`**, so
   you'd still need one hand-edited line there. Half-automatable at best.
3. **Avoid `:anchored` entirely** — express popovers/menus/tooltips as a full-screen
   `:box` overlay (`fill_width`/`fill_height` + `box` `align`) placed last in the root
   `:box`. Zero native work, works on both platforms today. This is what Kati should do
   for v1 unless a design element genuinely needs to escape a `corner_radius` clip.
4. **A pure-Elixir composite** (`Mob.Composite`) can *rename* the tag but cannot escape
   clipping — it expands to built-ins only. Not a fix.

## A.7 Concrete authoring walkthrough

### Scaffold

```bash
mix mob.new_plugin kati_anchored --tier 1   # or --tier 3 for screens, --tier 0 for pure Elixir
# writes plugins/kati_anchored/ ; refuses to overwrite an existing dir
```

(`lib/mix/tasks/mob.new_plugin.ex:49-65`; `--dest DIR` overrides the default `plugins/<name>`.)

### Write the manifest — `plugins/kati_anchored/priv/mob_plugin.exs`

Plain data, evaluated with `Code.eval_file/1`, must return a map (`manifest.ex:57-67`):

```elixir
%{
  name: :kati_anchored,
  mob_version: "~> 0.7",
  plugin_spec_version: 1,
  description: "Anchored popup primitive for Kati",
  android: %{
    bridge_kt: "priv/native/android/KatiAnchoredBridge.kt",
    bridge_class: "io.kati.anchored.KatiAnchoredBridge"
  },
  host_requirements: [
    "Add `\"anchored\" -> MobAnchored(node, m)` to the when-block in " <>
      "android/app/src/main/java/MobBridge.kt (RenderNodeInner)."
  ]
}
```

`:host_requirements` strings are printed as warnings on every `mix mob.deploy --native`
(`merge.ex:405-417`) — the honest way to encode the one manual step.

### Sign

```bash
cd plugins/kati_anchored
mix mob.plugin.keygen          # → ~/.mob/keys/kati_anchored.priv (0600) + priv/mob_plugin.pub
mix mob.plugin.sign            # → priv/mob_plugin.sig ; prints the ed25519:… fingerprint
```

### Activate in the host (two files)

```elixir
# mix.exs
{:kati_anchored, path: "plugins/kati_anchored"}

# mob.exs
config :mob, :plugins, [:kati_anchored]
```

```bash
mix deps.get
mix mob.plugin.trust kati_anchored   # prompts y/N after showing declared capabilities
# ...or, for a prototype: config :mob, :acknowledge_unsafe_plugins, [:kati_anchored]
```

### Verify / deploy

```bash
mix mob.plugins            # lists activated plugins with tier + hot-push status
mix mob.validate_plugin    # run from the plugin dir
mix mob.audit_plugins      # capability audit
mix mob.regen_plugin_manifest   # rewrites host priv/generated/mob_plugins.exs
mix mob.deploy --native    # full native rebuild; runs the signature gate
```

### Tier-4 skeleton (for reference)

```elixir
lifecycle: %{
  on_start:      {KatiSync, :start, []},
  on_resume:     {KatiSync, :resume, []},
  on_background: {KatiSync, :flush, []},
  supervised:    [KatiSync.Worker]
},
settings: %{
  schema: [%{key: :interval_min, type: :integer, default: 30}],
  editor_screen: KatiSync.SettingsScreen
},
notifications: %{handlers: [%{match: %{kind: "sync"}, handler: {KatiSync, :handle_push, 1}}]}
```

`on_start` MFAs run in `Mob.Plugins.Supervisor.init/1` and **raise on `{:error, _}` — a
failing plugin `on_start` fails app boot loudly** (`lib/mob/plugins/supervisor.ex:29-39`).
`on_resume`/`on_background` are dispatched by `Mob.Plugins.Lifecycle` off `Mob.Device`'s
`:app` events, crash-isolated (`lib/mob/plugins/lifecycle.ex:26-54`).

### The `expand:` (composite) form — the one that is fully hot-pushable

This is the mechanism Mishka Chelekom's Mob layer should use for anything that isn't a new
native node:

```elixir
ui_components: [
  %{tag: "KatiHabitRing", atom: :kati_habit_ring, expand: {Kati.HabitRing, :expand}}
]
```

Expander contract (`lib/mob/composite.ex:26-39`):

```elixir
def expand(props, children, ctx)   # ctx == %{screen: pid}
```

`on_*` props written as bare strings/atoms are auto-rewritten to `{screen_pid, tag}`
(`composite.ex:130-145`) — no `self()` threading. Output is re-expanded to a fixpoint,
depth guard 20, and a crashing expander logs and renders an empty Column instead of
killing the screen (`composite.ex:86-124`). Runtime registration without a manifest:
`Mob.Composite.register(:kati_habit_ring, {Kati.HabitRing, :expand})` from `on_start/0`.

---

# B. Navigation and performance

## B.1 ⚠️ The single biggest correction: there is exactly ONE screen process

Both the hexdocs and the earlier `mob-framework.md` research say screens are separate
processes. **The source says otherwise.**

Docs (<https://mob.hexdocs.pm/navigation.html>), verbatim:
> *"Mob's navigation is process-based. When you pop back to a previous screen, that
> screen's process is still running with its original state."*

Source — `mob 0.7.20 · lib/mob/screen.ex`. `Mob.Screen` is **one** GenServer whose state
is the 4-tuple `{module, socket, nav_history, render_mode}` (`screen.ex:265`). In render
mode it registers the singleton name:

```elixir
# screen.ex:232
if render_mode == :render, do: Process.register(self(), :mob_screen)
```

Navigation swaps the module **inside that same process**:

```elixir
# screen.ex:554-615  apply_nav_action/3
{:push, dest, params} ->
  {new_module, route_params} = resolve_destination(dest)
  new_base = Mob.Socket.new(new_module, platform: platform)
             |> Mob.Socket.assign(:safe_area, socket.assigns.safe_area)
  {:ok, mounted} = new_module.mount(Map.merge(route_params, params), %{}, new_base)
  saved = {module, clear_nav_action(socket)}
  {new_module, mounted, [saved | nav_history], :push}

{:pop} ->
  case nav_history do
    [{prev_module, prev_socket} | rest] -> {prev_module, prev_socket, rest, :pop}
    [] -> {module, clear_nav_action(socket), [], :none}
  end
```

The back stack is a **plain list of `{module_atom, %Mob.Socket{}}` tuples on one process
heap.** There is no per-screen PID, no per-screen supervisor, no per-screen mailbox.

**Where the docs are accidentally right:** the *observable* behaviour ("original state
still there") holds, because the socket is stored verbatim and restored on pop without
re-running `mount/3`.

**Where this bites you (all undocumented):**

1. **`handle_info/2` always goes to the *current* module** (`screen.ex:524-538`,
   `module.handle_info(message, socket)` where `module` is the tuple's first element). A
   timer or PubSub subscription started in screen A's `mount/3` keeps delivering after you
   push to screen B — into **B's** `handle_info`, with **B's** socket. `use Mob.Screen`
   installs a catch-all `def handle_info(_message, socket), do: {:noreply, socket}`
   (`screen.ex:113`), so these messages are **silently swallowed**, not crashed on.
2. **`terminate/2` never fires on pop.** It's the GenServer `terminate` of the one process
   (`screen.ex:545-548`) — it runs once, at app teardown, for whatever module is current.
   Screens cannot clean up on navigation.
3. **`{:reset, …}` discards the whole history** (`screen.ex:600-609`) — every saved socket
   is dropped with no callback.
4. **State persistence follows the current module only.** `:__mob_sync_state__` fires every
   30 s (`@state_sync_interval_ms 30_000`, `screen.ex:696-700`) and dumps
   `Mob.ScreenState.dump(module, socket)` for the *current* module, re-scheduling only if
   that module has `__mob_persist__()` true (`screen.ex:501-508`). A `persist: true` screen
   sitting on the back stack is never synced, and **if you navigate from a persisting
   screen to a non-persisting one the 30 s timer stops permanently.**
5. **One heap, one GC.** All back-stack sockets live on the single screen process, so a
   deep stack of data-heavy screens is one large process the GC must repeatedly scan.
6. A crash in `handle_event` takes down **the whole UI**, not one screen. There is no
   framework supervisor for it in a `mob_new` app — `on_start/0` calls
   `Mob.Screen.start_root/1` bare (`mob_new · priv/templates/mob.new/lib/app_name/app.ex.eex`),
   linked to the boot process.

## B.2 `Mob.App.navigation/1` — what `stack`/`tab_bar`/`drawer` actually do

```elixir
# lib/mob/app.ex:231-260
def stack(name, opts), do: %{type: :stack, name: name, root: Keyword.fetch!(opts, :root),
                             title: Keyword.get(opts, :title)}
def tab_bar(branches),  do: %{type: :tab_bar, branches: branches}
def drawer(branches),   do: %{type: :drawer, branches: branches}
```

`grep -rn "navigation("` across `mob`, `mob_dev`, `mob_new` finds **exactly one consumer**:

```elixir
# lib/mob/nav/registry.ex:84-102
defp populate(app_module) do
  for platform <- [:android, :ios] do
    nav = app_module.navigation(platform)
    register_nav(nav)
  end
end
defp register_nav(%{type: :stack, name: name, root: root}), do: :ets.insert(@table, {name, root, %{}})
defp register_nav(%{type: type, branches: branches}) when type in [:tab_bar, :drawer],
  do: Enum.each(branches, &register_nav/1)
```

⇒ **`navigation/1` is a route table, not a shell.** `tab_bar/1` and `drawer/1` are pure
grouping sugar: they recurse into their branches and insert `{stack_name → root_module}`
ETS rows. **No native tab bar, no drawer, no chrome of any kind is produced.**

`Mob.App`'s own docstrings claim otherwise — `app.ex:243-244` (*"Renders as a bottom
NavigationBar on Android and a UITabBarController on iOS"*) and `app.ex:255-256`
(*"Renders as a ModalNavigationDrawer on Android"*). **Both are false in 0.7.20.** Mob's own
capability audit agrees with the source: *"Drawer navigation ❌ — — Plugin candidate; mob's
nav model is stack-based today"* (<https://mob.hexdocs.pm/mobile_surface_matrix.html>).

The `:tab_bar` **render node** (`<TabBar>`) is a *separate, unrelated* thing you place in
your own tree. It is real and it works (`MobBridge.kt.eex:2183-2210`): a Material 3
`Scaffold` + `NavigationBar`, driven by props `tabs`, `active`, `on_tab_select`, and it
renders **only `node.children[activeIdx]`**.

`Mob.Socket.switch_tab/2` (`socket.ex:187-190`) sets `{:switch_tab, tab}` — and
`Mob.Screen` throws it away:

```elixir
# screen.ex:611-613
{:switch_tab, _tab} ->
  # Tab switching is handled renderer-side; clear the action.
  {module, clear_nav_action(socket), nav_history, :none}
```

Nothing renderer-side consumes it. **`switch_tab/2` is a no-op in 0.7.20.** Drive tabs with
your own assign + the `<TabBar active=…>` prop instead.

## B.3 Every `Mob.Socket` navigation call

All defined in `lib/mob/socket.ex:129-190`; all just stash `__mob__.nav_action`, applied
after the callback returns.

| Call | Action term | Effect (`screen.ex:554-615`) | Runs `mount/3`? | Transition passed to native |
|---|---|---|---|---|
| `push_screen(socket, dest, params \\ %{})` | `{:push, dest, params}` | mounts `dest`, pushes `{old_module, old_socket}` onto history | **yes** | `:push` |
| `pop_screen(socket)` | `{:pop}` | restores head of history | **no** | `:pop` |
| `pop_to(socket, dest)` | `{:pop_to, dest}` | scans history for `dest`'s module, restores it, drops everything above; **no-op if absent** | **no** | `:pop` |
| `pop_to_root(socket)` | `{:pop_to_root}` | restores the *last* entry (`Enum.reverse(nav_history)` head), clears history | **no** | `:pop` |
| `reset_to(socket, dest, params \\ %{})` | `{:reset, dest, params}` | mounts `dest`, history := `[]` | **yes** | `:reset` |
| `switch_tab(socket, tab)` | `{:switch_tab, tab}` | **nothing** | no | `:none` |

`dest` resolution (`screen.ex:626-645`): `Code.ensure_loaded(dest)` first — a **loaded
module wins**; otherwise `Mob.Nav.Registry.lookup_route/1`; otherwise `ArgumentError`.
Route-bound params from the registry are merged **under** the caller's params
(`Map.merge(route_params, params)`).

**System back is free**: `handle_info({:mob, :back}, …)` is intercepted before your
clauses (`screen.ex:444-466`). It first tries `webview_go_back()`, then pops; on an empty
history it calls `:mob_nif.exit_app()`.

## B.4 Direct answers

**Is a screen's process started lazily on navigation, or eagerly at boot?**
Neither, strictly — **there are no per-screen processes**. Exactly one `Mob.Screen`
GenServer is started, once, by your `Mob.Screen.start_root/1` call in `on_start/0`. A
destination screen's **`mount/3` is called lazily, synchronously, at the moment you
navigate** (`screen.ex:567`). Boot cost is `mount/3` + `render/1` of the **root screen
only**. Nothing else is touched: `Mob.Nav.Registry` stores atoms, not code, and
`Code.ensure_loaded/1` runs per navigation.

**Are screens kept alive on the back stack, or torn down?**
Their **state** is kept (the `%Mob.Socket{}` is stored verbatim and restored without
re-mounting). Their **behaviour** is torn down: no process, no mailbox, no timers of their
own, no `terminate/2`, no `handle_info` routing. Pop restores data, not liveness.

**Memory cost per screen.**
Per back-stack entry = one 2-tuple + one `%Mob.Socket{}` struct (2 fields: `assigns` map +
`__mob__` 7-key map) + **whatever you put in `assigns`**. Framework overhead is a handful
of words; the `assigns` payload dominates and is entirely yours. All of it lives on **one
process heap**. No per-screen PID (~340 words each on 64-bit) is paid, because there are no
per-screen processes. **The framework publishes no memory numbers and I measured none —
the absolute per-screen figure is UNKNOWN; only the shape (assigns-dominated, single heap)
is established from source.**

**How would 62 screens behave?**
Fine at rest, because 62 screens ≈ 62 modules ≈ zero runtime cost until visited. The real
constraints:

- **Route registration is manual past the stack roots.** `navigation/1` registers only
  `{stack_name → root}`. For 62 screens either (a) push modules directly
  (`push_screen(socket, Kati.Books.DetailScreen, %{id: id})` — works with no registration
  at all, `screen.ex:628-630`), or (b) call `Mob.Nav.Registry.register/3` for each named
  route in `on_start/0`. Kati should prefer (a) plus a small hand-rolled
  `Kati.Routes` module; ETS lookup is O(1) either way and `Mob.Nav.Registry` is
  `read_concurrency: true` (`registry.ex:79`).
- **Deep stacks accumulate on one heap.** A user drilling calendar → day → event → edit →
  attachment keeps 5 sockets alive. Trim with `reset_to/3` at section boundaries (it
  clears history entirely) and by keeping `assigns` small — store IDs, re-query Ash on
  mount, don't stash rendered lists.
- **Cross-screen messaging is a trap.** With 62 screens you *will* be tempted to subscribe
  screens to PubSub/Ash notifications. Any message arriving after navigation lands on the
  wrong module and is silently dropped (§B.1). **Own subscriptions in a separate
  long-lived GenServer under your own supervisor, and let it `send(:mob_screen, …)` only
  when the relevant screen is current.**
- `mix mob.routes` statically checks every `push_screen` / `reset_to` / `pop_to` module
  reference and takes `--strict` for CI (`mob_dev · lib/mix/tasks/mob.routes.ex:1-45`).
  Registered **atom** routes are skipped ("require the app to be running"). Worth wiring
  into Kati's CI from day one.

**What controls render-diff cost?**
There is **no BEAM-side diff.** Every render serialises the *entire* tree and ships it:

```elixir
# lib/mob/renderer.ex:221-244
def render(tree, platform, nif \\ @default_nif, transition \\ :none) do
  ...
  nif.clear_taps()
  nif.set_transition(transition)
  json = tree |> prepare(nif, platform, ctx) |> :json.encode() |> IO.iodata_to_binary()
  nif.set_root(json)
  {:ok, :json_tree}
end
```

and `Mob.Screen.do_render/3` runs the full pipeline on **every** event, info message, and
component change (`screen.ex:722-738`):

```elixir
module.render(socket.assigns)
|> Mob.Composite.expand(self())      # pass 1: composite tags → built-ins (fixpoint, depth 20)
|> Mob.List.expand(list_renderers, self())  # pass 2: :list → :lazy_list, one node per item
|> Mob.Component.expand(self(), platform)   # pass 3: :native_view → props + handle
Mob.ComponentRegistry.reconcile(self(), active_component_keys)
{:ok, token} = Mob.Renderer.render(tree, platform, :mob_nif, transition)
```

So per-render cost = **O(total nodes)** for tree build + 3 expansion passes + token
resolution + JSON encode + one JNI/ObjC call. Diffing happens only on the far side, by
Compose/SwiftUI recomposition. What you control: **tree size**, nothing else. There is no
`:temporary_assigns`, no change tracking, no partial update.

Second-order cost: `clear_taps` + `register_tap` per event prop, per frame
(`renderer.ex:233`, `:308-471`; zig at `android/jni/mob_nif.zig:1560-1616`). Each
`register_tap` allocates an `ErlNifEnv` and copies the tag term; `clear_taps` frees all
256 slots. Double-buffered so a concurrent event never sees a half-built table
(`mob_nif.zig:970-977`).

**Documented performance pitfalls** (mostly *undocumented* — found in source):

1. 🔴 **Hard cap: 256 event handles per frame.**
   `const MAX_TAP_HANDLES: usize = 256;` (`android/jni/mob_nif.zig:940`),
   `#define MAX_TAP_HANDLES 256` (`ios/mob_nif.m:63`). Over the limit,
   `nif_register_tap` returns `badarg` (`mob_nif.zig:1572`) → raises inside
   `Mob.Renderer.prepare_props/4` → **the screen process dies**. Every `on_tap`,
   `on_change`, `on_scroll`, `on_swipe*`, `on_select`, `on_tab_select`, … counts.
   `Mob.List` wraps **every row** in a tappable `:box` (`lib/mob/list.ex:110-116`), so a
   250-row list alone nearly exhausts the table. **For Kati's book/film/music lists:
   paginate, or use a custom renderer that omits `on_tap` on non-interactive rows.**
2. 🔴 **`:lazy_list` is not lazy on the BEAM side.** `Mob.List.expand/3` materialises a
   node for **every** item on every render, and all of them are JSON-encoded and sent.
   Compose's `LazyColumn` only lazily *composes* what it received (`MobBridge.kt.eex`
   `MobLazyList`: `items(node.children) { child -> RenderNode(child) }`). Windowing/
   pagination is **your** job — use `on_end_reached` (`renderer.ex:338`) and grow the
   assign.
3. 🟠 **`items(node.children)` is unkeyed** — Compose falls back to positional identity, so
   inserting at the head re-composes everything below.
4. 🟠 **`<TabBar>` serialises all branches, renders one.** `MobTabBar` renders only
   `node.children[activeIdx]`, but every child is in the JSON. Emit
   `%{type: :column, props: %{}, children: []}` placeholders for inactive tabs.
5. 🟠 **64 concurrent `native_view` components** (`MAX_COMPONENT_HANDLES`,
   `mob_nif.zig:941`; `ios/mob_nif.m:5994`).
6. 🟠 **High-frequency events must be throttled.** `on_scroll`/`on_drag`/`on_pinch`/
   `on_rotate`/`on_pointer_move` accept `{pid, tag, throttle: ms | debounce: ms}` and
   default to **30 Hz / 1 px** (`renderer.ex:377-425`, `Mob.Event.Throttle`). Raw mode
   (`throttle: 0`) is explicitly called an *"escape hatch"*.
7. 🟡 **Scroll-driven UI has a native-only tier that never round-trips to BEAM** —
   `parallax:`, `fade_on_scroll:`, `sticky_when_scrolled_past:` pass through as configs
   consumed natively (`renderer.ex:449-461`). Use these instead of `on_scroll`.
8. 🟡 **`set_root`/`set_transition` are dirty NIFs** —
   `flags = erts.ERL_NIF_DIRTY_JOB_CPU_BOUND` (`mob_nif.zig:3896-3897`), so a large tree
   occupies a dirty scheduler, not a normal one. Good for latency, but throughput-bound.
9. 🟡 **A nav transition resets Compose scroll caches**: `setRootJson` clears
   `lazyListStates`, `scrollHandlesById`, `elementFramesById` whenever
   `transition != "none"` (`MobBridge.kt.eex:629-636`). Popping back **loses scroll
   position** even though the socket is restored.
10. 🟢 **Same-screen re-renders do not tear down the composition** — `navKey` only
    increments on real transitions, and `AnimatedContent(contentKey = { it.navKey })`
    means *"no content swap, no focus loss, no keyboard dismissal"* on ordinary re-renders
    (`MobBridge.kt.eex:212-216`). Same guarantee on iOS via `.id(currentNavVersion)`
    (`ios/MobRootView.swift:1336-1341`).

**How do you keep cold start fast?**
Everything on the critical path is what *you* put in `on_start/0`. `Mob.App.start/0`
itself (`app.ex:83-157`) is cheap and fixed: iOS inet_db fix → `NativeLogger.install()` →
`Theme.set` → `Nav.Registry.start_link` → `Plugins.boot` → `State` →
`ComponentRegistry` → `Device.IOS`/`Device.Android`/`Device` →
`Theme.AdaptiveWatcher` → `Plugins.start_lifecycle()` → `on_start/0`.

The generated `on_start/0` (`mob_new · priv/templates/mob.new/lib/app_name/app.ex.eex`)
does this **synchronously before the first paint**:

```elixir
Mob.DNS.configure_pure_beam()
{:ok, _} = Application.ensure_all_started(:ecto_sqlite3)
{:ok, _} = MyApp.Repo.start_link()
Ecto.Migrator.with_repo(MyApp.Repo, fn repo -> Ecto.Migrator.run(repo, migrations_dir(), :up, all: true) end)
Mob.Screen.start_root(MyApp.HomeScreen)
Mob.Dist.ensure_started(node: …, cookie: :mob_secret)
```

Kati-specific advice:
- **Move `Ecto.Migrator.run/4` off the boot path** or gate it (`if migrations_pending?`).
  With Ash + SQLite and a 62-screen schema this is the single largest cold-start item.
- **`start_root` before everything optional.** Reorder so the home screen paints first,
  then start Ash/registries/sync from a `Task` or your own supervisor.
- **Keep `HomeScreen.mount/3` query-free** — `assign_new/3` (`socket.ex:106-112`) or a
  `send(self(), :load)` after mount so the first frame is skeleton UI.
- **Strip `Mob.Dist.ensure_started/1` from release builds** — it starts Erlang distribution
  and, on iOS, has been observed to block (`app.ex:149-153` comments).
- **Every activated plugin adds boot work**: `Mob.Plugins.boot/1` `Code.eval_file`s the
  generated manifest, `Code.ensure_loaded/1`s each plugin NIF module, and
  `Mob.Plugins.Supervisor` runs every `lifecycle.on_start` MFA **before** your `on_start/0`
  (`app.ex:147-154`). Activate only plugins you use.
- `Mob.Plugins.boot/1` fails soft on a missing/malformed manifest (`plugins.ex:445-454`
  rescues to the empty set), so it can't break boot.

**Is there screen preloading, and can it be turned off?**
**No.** `grep -rni preload` across `mob 0.7.20`, `mob_dev 0.6.23` and `mob_new 0.4.20`
returns **zero hits**. Nothing is preloaded, nothing is prefetched, nothing is warmed —
so there is nothing to turn off. The only "eager" behaviour in the whole stack is
`Mob.Plugins.ensure_nif_modules_loaded/0` (`plugins.ex:99-101`), which force-loads
*plugin NIF modules* (not screens) so iOS permission handlers self-register at boot.
That's controlled by which plugins you activate in `mob.exs`, nothing else.

---

# C. Animation and transitions

## C.1 The complete inventory

Mob has **exactly one** animation feature: the navigation transition. There is **no
per-widget animation API on the BEAM side at all.**

Evidence: `grep -rniE "animat|transition|spring|tween|easing|shared_element"` across
`mob 0.7.20 · lib/` matches only (a) `Mob.Renderer`'s `transition` argument and
`set_transition` call, (b) `Mob.Screen` threading that atom through, (c) `on_rotate`
(a *gesture*, not a transform). `Mob.Motion` (`lib/mob/motion.ex`) is **sensors**
(accelerometer/gyro/magnetometer), not animation — the name is a false friend.

The guide that would document it doesn't: <https://mob.hexdocs.pm/styling.html> has
**no** content on animation, transitions, transforms, opacity, rotation, scale, spring,
or animated props. Mob's own audit says the quiet part out loud
(<https://mob.hexdocs.pm/mobile_surface_matrix.html>): animation frameworks are listed under
*"Architecturally not present"* — Mob uses SwiftUI/Compose layout rather than providing an
Animated/Reanimated-style abstraction.

## C.2 Navigation transition animations — the whole implementation

**BEAM side.** `Mob.Screen.apply_nav_action/3` returns a transition atom
(`:push | :pop | :reset | :none`, `screen.ex:554-615`), threaded into
`Mob.Renderer.render/4` → `nif.set_transition(transition)` **before** `nif.set_root(json)`
(`renderer.ex:233-242`). The NIF snapshots it and resets to `"none"` for the next frame
(`android/jni/mob_nif.zig:1519-1531`; `ios/mob_nif.m:1886-1894`). **You cannot set it
yourself** — no public API takes a transition, and `render/4`'s default is `:none`.

**Android** — `mob_new · priv/templates/mob.new/android/app/src/main/java/MainActivity.kt.eex:214-235`,
i.e. **in your own app's source**:

```kotlin
AnimatedContent(
    targetState   = state,
    contentKey    = { it.navKey },
    transitionSpec = {
        when (targetState.transition) {
            "push" -> slideInHorizontally(animationSpec = tween(300)) { it } togetherWith
                      slideOutHorizontally(animationSpec = tween(300)) { -it / 3 }
            "pop"  -> slideInHorizontally(animationSpec = tween(300)) { -it / 3 } togetherWith
                      slideOutHorizontally(animationSpec = tween(300)) { it }
            "reset"-> fadeIn(animationSpec = tween(250)) togetherWith
                      fadeOut(animationSpec = tween(250))
            else   -> EnterTransition.None togetherWith ExitTransition.None
        }
    },
    label = "nav"
) { s -> s.node?.let { RenderNode(it, modifier = Modifier.fillMaxSize().safeDrawingPadding()) } }
```

⇒ **push/pop = 300 ms horizontal slide (incoming full width, outgoing ⅓ parallax);
reset = 250 ms crossfade; none = instant.** Hardcoded — and **editable, because this file
is yours** (§A.5). Customising Kati's transitions on Android = editing this `when`.

**iOS** — `mob 0.7.20 · ios/MobRootView.swift:1410-1440`, inside the **hex package** (so
customising it means forking mob):

```swift
private func navTransition(_ t: String) -> AnyTransition {
    case "push":  .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))
    case "pop":   .asymmetric(insertion: .move(edge: .leading),  removal: .move(edge: .trailing))
    case "reset": .opacity
    default:      .identity
}
private func navAnimation(_ t: String) -> Animation? {
    case "push", "pop": .spring(response: 0.3, dampingFraction: 0.85)
    case "reset":       .easeInOut(duration: 0.25)
    default:            nil
}
```

Applied via `withAnimation(animation) { currentRoot = newRoot; currentNavVersion = newNavVersion }`
(`MobRootView.swift:1387-1395`). Every non-`none` transition logs
`[MobNav] transition=<…> navVersion=<n>` (`MobRootView.swift:1385`) — a free hook for
verifying nav in tests.

Note the platforms **differ**: Android tweens 300 ms linear-ish; iOS uses a spring
(`response 0.3, damping 0.85`). The earlier research's claim that Android push is
*"slide up"* is wrong — it is `slideInHorizontally`.

## C.3 Per-widget animation props — **none exist**

No `animate*` prop, no `:transition` prop, no `animated:` flag on any widget. Checked
exhaustively:

- `Mob.Renderer.prepare_props/4` (`renderer.ex:283-473`) enumerates every specially-handled
  prop. The list is: event handles (`on_tap`, `on_change`, `on_focus`, `on_blur`,
  `on_submit`, `on_compose`, `on_end_reached`, `on_tab_select`, `on_select`,
  `on_long_press`, `on_double_tap`, `on_swipe[_left|_right|_up|_down]`, `on_scroll`,
  `on_drag`, `on_pinch`, `on_rotate`, `on_pointer_move`, `on_scroll_began`,
  `on_scroll_ended`, `on_scroll_settled`, `on_top_reached`, `on_scrolled_past`), the three
  native scroll configs, canvas `draw` ops, and token resolution for colours/spacing/
  radii/text sizes. **No animation prop of any kind.**
- Android `nodeModifier` (`MobBridge.kt.eex:3366-3435`) consumes exactly:
  `corner_radius`, `background`, `border_color`, `border_width`, `padding`,
  `padding_{top,right,bottom,left}`, `fill_width`, `fill_height`, `width`, `height`,
  `aspect_ratio` — plus `weight` on `Column`/`Row` children and `offset_x`/`offset_y`
  handled one level up in `RenderNode` (`MobBridge.kt.eex:2161-2172`).
  **No `alpha`, no `rotate`, no `scale`, no `graphicsLayer`, no `animateContentSize`,
  no `AnimatedVisibility`.**
- `grep -niE "animat|Crossfade|graphicsLayer|spring|tween"` over the whole 3 635-line
  `MobBridge.kt.eex` matches only comments about the nav `AnimatedContent`.

## C.4 Transforms — what exists

The complete transform surface is **translation only**:

```kotlin
// MobBridge.kt.eex:2161-2172
val ox = floatProp(node.props, "offset_x") ?: 0f
val oy = floatProp(node.props, "offset_y") ?: 0f
if (ox != 0f || oy != 0f) {
    Box(modifier = Modifier.offset(x = ox.dp, y = oy.dp)) { RenderNodeInner(node, modifier) }
} else { RenderNodeInner(node, modifier) }
```

`offset_x` / `offset_y` (dp/pt) on **any** node, applied by wrapping the node in an outer
offset `Box` (the inline-modifier version *"didn't displace siblings reliably"* —
`MobBridge.kt.eex:3428-3432`). Sizing knobs (`width`, `height`, `aspect_ratio`,
`fill_width`, `fill_height`, `weight`) are layout, not transforms.

**You can hand-roll animation with these.** Drive `offset_x` from an assign and re-render
on a `Process.send_after/3` tick; each render is a full tree + JSON round-trip, so realistic
budget is ~10–20 fps for a whole-screen tree, better for a small one. Not recommended for
Kati beyond micro-nudges.

Rotation/scale/opacity are only reachable inside `:canvas` (Compose/SwiftUI `Canvas` draw
ops via `Mob.Canvas`, `lib/mob/canvas.ex`) or `:gpu_view` (Metal fragment shader at display
refresh rate — **iOS only**, *"Android support (`GLSurfaceView` + GLES 3.0) is not in v1"*,
`lib/mob/ui.ex:175`).

## C.5 Gesture-driven animation

Gestures are **plentiful**; gesture-*driven animation* is not. Available per-widget
(`renderer.ex:350-425`):

`on_long_press`, `on_double_tap`, `on_swipe`, `on_swipe_left/right/up/down`,
`on_scroll`, `on_drag`, `on_pinch`, `on_rotate`, `on_pointer_move` — the last five accept
`{pid, tag, throttle: ms | debounce: ms | leading: bool | trailing: bool | delta_threshold: n}`.
Plus semantic scroll events `on_scroll_began`, `on_scroll_ended`, `on_scroll_settled`,
`on_top_reached`, `on_end_reached`, and `on_scrolled_past` with a numeric threshold
(latched — re-fires only after going back below).

Every one of these **only delivers a message to Elixir**; any visual response costs a full
re-render. There is no native gesture↔property binding.

The **one** exception, and the right tool for Kati's scroll effects — Tier-3
"native-side scroll-driven UI primitives" that *"never round-trip to BEAM during scroll"*
(`renderer.ex:449-461`):

```elixir
parallax: %{...}
fade_on_scroll: %{...}
sticky_when_scrolled_past: %{...}
```

Passed through as string-keyed configs and consumed by
*"the platform layer (SwiftUI `.scrollPosition` observer / Compose `snapshotFlow`)"*.
**Their config schemas are documented nowhere** — `renderer.ex` calls
`encode_native_config/1` on an arbitrary map. Read the native consumer before relying on
them; treat the exact keys as **UNKNOWN**.

Mob's own audit rates the gesture layer honestly
(<https://mob.hexdocs.pm/mobile_surface_matrix.html>):
- *"Pan / drag gesture — 🟡 🟡 🟡 Tap-based; full pan-responder system (like react-native-gesture-handler) is missing"*
- *"Pinch / zoom — ❌ — — Plugin candidate; common for image/map views"*
- *"Rotation gesture — ❌ — — Plugin candidate"*

(`on_pinch`/`on_rotate` props *do* exist in `Mob.Renderer`; the ❌ presumably means no
built-in pinch-to-zoom behaviour.)

## C.6 Shared-element transitions — **do not exist**

Zero hits for `shared_element` / `matchedGeometryEffect` / `SharedTransitionLayout` across
`mob 0.7.20` (Elixir, Swift, ObjC) and `mob_new`'s Kotlin templates. Structurally
impossible as things stand: `AnimatedContent` swaps whole root trees keyed on `navKey`,
and there is no stable cross-tree element identity in the JSON protocol (`id` props feed a
*test* frame registry, `MobBridge.kt.eex` `frameTrackingModifier`, not animation).

## C.7 What must drop to Compose/SwiftUI

| Want | Available in Elixir? | Route |
|---|---|---|
| Nav push/pop/reset animation | ✅ automatic, not configurable | edit `MainActivity.kt` (Android, yours) / fork `MobRootView.swift` (iOS) |
| Custom nav transition (fade, scale, modal-up) | ❌ | edit the `transitionSpec` `when` in **your** `MainActivity.kt.eex`-generated file |
| Fade/slide a widget in-place | ❌ | new composable in **your** `MobBridge.kt` + a new node type in the `when` |
| `animateContentSize`, `AnimatedVisibility` | ❌ | ditto |
| Opacity / rotate / scale transform | ❌ | ditto, or `Mob.Canvas` draw ops, or `:gpu_view` (iOS only) |
| Translate a node | ✅ `offset_x` / `offset_y` (static value; animate by re-rendering) | — |
| Gesture callbacks | ✅ 19 props, throttleable | — |
| Gesture-driven animation (drag-follows-finger) | ❌ | native |
| Parallax / fade-on-scroll / sticky header | 🟡 pass-through configs, schema undocumented | verify natively |
| Shared-element transition | ❌ | native, and needs protocol changes |
| Bottom sheet / modal presentation | ❌ (docs: *"❌ — — Plugin candidate"* / *"full sheet-style modal is plugin territory"*) | `Mob.Alert` for alerts/action sheets, else native |
| Shader animation | 🟡 `:gpu_view`, **iOS only** | `lib/mob/ui.ex:168-257` |

**Bottom line for Kati:** yes, Mob "can reach Kotlin" — but for animation the reach is
*your own `MobBridge.kt` / `MainActivity.kt`*, not a plugin API. Budget any custom
animation as an Android-Kotlin task with an iOS-parity follow-up, and lean on Compose's
own implicit animations inside composables you add there.

---

# D. Corrections to prior research

`\.scratch/research/mob-framework.md` repeats several hexdocs claims the source refutes:

| §6 claim (from docs) | Source verdict |
|---|---|
| *"A screen = one GenServer, started under OTP supervision; crashed screens are restarted by the supervisor"* (§1) | ❌ One `:mob_screen` GenServer for the whole app (`screen.ex:232`). No per-screen supervision. |
| *"because processes persist across navigation…"* | ❌ Only the socket persists; there is no per-screen process. |
| Tab bar → `NavigationBar` / `UITabBarController`; Drawer → `ModalNavigationDrawer` | ❌ `navigation/1` output feeds only `Nav.Registry.populate/1` (`registry.ex:84-102`). No shell is rendered. Mob's own matrix: *"Drawer navigation ❌"*. |
| *"`switch_tab(socket, :tab_name)` — tab bar or drawer"* | ❌ Explicit no-op (`screen.ex:611-613`). |
| *"push = slide in from right (iOS) / slide up (Android)"* | ⚠️ Android is `slideInHorizontally`, not vertical (`MainActivity.kt.eex:219-221`). |
| §7 *"Registering a widget name → NIF constructor"* via `Mob.Registry` | ❌ `Mob.Registry` is unreferenced dead code. |

`\.scratch/research/mishka-mob-index.md` §4.0 correctly flags that `:anchored` is missing
from mob. Confirmed and sharpened: **`MobAnchored` exists in no published mob (0.7.20 is
latest on Hex); on Android an unknown node renders nothing, on iOS it renders as a
Column.** Mishka's `usage-rules/mob/*.md` statements that `:anchored` "floats on Android"
describe an unreleased mob.
