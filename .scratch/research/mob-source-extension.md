# Every route by which native code enters a Mob app

**Source-level reference. Read from source, not docs.** Verified against mob 0.7.20,
mob_dev 0.6.23, mob_new 0.4.20, and a real running Mob app with app-owned Kotlin
(Mishka's `development/mob`).

## Roots (all absolute; cited below by short name)

| Short | Absolute path | What it is |
|---|---|---|
| `⟨MOB⟩` | `/private/tmp/claude-501/-Volumes-Fast-Arise-Resource-AI-book/c5718512-beef-4e2f-bbc9-14f1d94a1350/scratchpad/mobtar/contents` | **Pristine** mob 0.7.20, extracted from `~/.hex/packages/hexpm/mob-0.7.20.tar`. The authority. |
| `⟨MOBGIT⟩` | `/private/tmp/claude-501/-Volumes-Fast-Arise-Resource-AI-book/c5718512-beef-4e2f-bbc9-14f1d94a1350/scratchpad/mob` | mob git checkout @ `26329fa` ("Bump to 0.7.20"). `lib/` is **byte-identical** to `⟨MOB⟩/lib/` (verified with `diff -rq`), and `priv/tags/android.txt` matches too. Adds the design docs Hex does **not** ship. |
| `⟨MOBDEV⟩` | `/private/tmp/claude-501/-Volumes-Fast-Arise-Resource-AI-book/c5718512-beef-4e2f-bbc9-14f1d94a1350/scratchpad/pkg/mob_dev_6_23` | mob_dev 0.6.23 |
| `⟨MOBNEW⟩` | `/private/tmp/claude-501/-Volumes-Fast-Arise-Resource-AI-book/c5718512-beef-4e2f-bbc9-14f1d94a1350/scratchpad/pkg/mob_new_4_20` | mob_new 0.4.20 — holds `MobBridge.kt.eex`, `MainActivity.kt.eex` |
| `⟨MISHKA⟩` | `/Users/shahryar/Documents/Programming/Elixir/mishka_chelekom` | READ ONLY. `development/mob/` is the worked `MobAnchored` example. |

### `MOB_PLUGINS.md` is not in the published package

`⟨MOB⟩` has exactly two Markdown files: `CHANGELOG.md` and `README.md`. `mix.exs` names
`MOB_PLUGINS.md` in `docs.extras` (`⟨MOB⟩/mix.exs:109`) and groups it under `Plugins`
(`:143`) — but `package.files` (`⟨MOB⟩/mix.exs:180-186`) ships only
`lib src priv android ios assets mix.exs mix.lock README.md CHANGELOG.md LICENSE`.
So the plugin reference exists **only** on hexdocs and in the git checkout at
`⟨MOBGIT⟩/MOB_PLUGINS.md` (1032 lines). Anyone reading `deps/mob` will never find it.

### Proof of the drift the pristine copy exists to guard against

`⟨MOB⟩/priv/tags/android.txt` is 26 lines / **21 tags** (Box … GpuView).
`⟨MISHKA⟩/development/mob/deps/mob/priv/tags/android.txt` has those 21 plus a fenced block
`# >>> mishka_mob composites — regenerated on compile, do not edit` containing `Anchored`,
`MishkaAccordion`, … — written by the `tags/1` alias wired as
`compile: [&tags/1, "compile"]` in `⟨MISHKA⟩/development/mob/mix.exs:56` and writing to
`deps/mob/priv/tags/#{platform}.txt` (`:197`, `:204`). **Never cite `deps/mob` for what
published Mob supports.**

---

## 0. The one fact that determines every answer

Mob's Elixir side is **open**. Its Android renderer is **closed**, and lives in a file
Mob ships zero copies of.

**Open half.** `Mob.Renderer.prepare/4` (`⟨MOB⟩/lib/mob/renderer.ex:256-265`) serialises
any node whatsoever:

```elixir
defp prepare(%{type: type, props: props, children: children}, nif, platform, ctx) do
  ...
  %{
    "type" => Atom.to_string(type),
    "props" => prepare_props(with_theme_flags, nif, platform, ctx),
    "children" => Enum.map(children, &prepare(&1, nif, platform, ctx))
  }
end
```

No whitelist. No `case`. `%{type: :anchored}` or `%{type: :kati_blur}` reaches the native
layer as a JSON string, with children, with arbitrary props (unknown prop keys fall through
`resolve_token/3` at `⟨MOB⟩/lib/mob/renderer.ex:470` unchanged). **Emitting a new node type
from Elixir costs nothing and needs no framework change.**

**Closed half.** `⟨MOBNEW⟩/priv/templates/mob.new/android/app/src/main/java/MobBridge.kt.eex:2188-2258`:

```kotlin
private fun RenderNodeInner(node: MobNode, modifier: Modifier) {
    ...
    when (node.type) {
        "column" -> ... ; "row" -> ... ; "box" -> ... ; "scroll" -> ...
        "text" -> MobText(node, m)
        ...
        "native_view"    -> MobNativeViewRegistry.render(node)
        "canvas"         -> MobCanvas(node, m)
        "gpu_view"       -> MobGpuView(node, m)
    }
}
```

Kotlin `when` used as a **statement** needs no `else`. An unrecognised `node.type` renders
**nothing, silently** — no crash, no log. This is precisely the failure mode a Mishka
consumer hits with `:anchored`.

Three consequences that drive the whole document:

1. **The only extension seam inside that `when` is `"native_view"`.** Everything else is a
   fixed branch in a per-app forked file.
2. **`native_view` is a leaf.** `Mob.UI.native_view/2` hard-codes `children: []`
   (`⟨MOB⟩/lib/mob/ui.ex:122-124`), and the Android renderer calls
   `factory(node.props, send)` (`MobBridge.kt.eex:2154`) — the factory never receives the
   node, so it cannot render children even if they were there. **A native_view can never
   wrap Mob-rendered content.**
3. **Node *props* (shadow, blur, semantics, long-press) are applied by `nodeModifier/1`**
   (`MobBridge.kt.eex:3366-3436`), which supports exactly: `corner_radius`, `background`,
   `border_color`+`border_width`, `padding`/`padding_*`, `clip`, `fill_width`,
   `fill_height`, `width`, `height`, `aspect_ratio`. Nothing can reach `nodeModifier` from
   outside the file.

---

## 1. Decision table

Columns: **Elixir?** · **Kotlin?** · **Swift?** · **Gradle?** · **Manifest?** ·
**New node type?** · **Survives a Mob bump?** · **Merge cost**

| # | Route | Elixir | Kotlin | Swift | Gradle deps | AndroidManifest | New renderable node type | Survives Mob bump | Merge cost |
|---|---|---|---|---|---|---|---|---|---|
| **R1** | Edit host `MobBridge.kt` / `MainActivity.kt` / `AndroidManifest.xml` directly | n/a | **Yes, unlimited** | n/a (iOS = `MobRootView.swift` fork) | by hand | by hand | **Yes — the only route that can** | **No.** Permanent divergence; no `mix mob.upgrade` exists | **Highest & permanent.** Every edit is re-applied by hand on every Mob bump |
| **R2** | Plugin tier 1 — `nifs` + `android.bridge_kt` + `android.bridge_class` (+ `ios.swift_files`/`frameworks`) | yes | **Yes** (copied into the app sourceSet, auto-registered at boot) | yes | **yes** (`gradle_deps`) | **yes** (`permissions`, `manifest_application_snippets`, `res_files`) | **No** (but see R3) | **Yes** — zero host-file edits | **Near zero.** Files land in generated, ledger-pruned locations |
| **R3** | Plugin tier 2 — `ui_components` with **native backing** (`native_view` component) | yes | yes, **only via R2's `bridge_kt`+`bridge_class`** | **yes, auto-generated bootstrap** | via R2 | via R2 | **No** — registers a `native_view` *factory*, not a node type. Leaf-only | **Yes** | Near zero |
| **R4** | Plugin tier 2 — `ui_components` with `expand: {M,F}` (pure-Elixir composite) | yes | no | no | no | no | No (expands to built-ins) | **Yes**, and hot-pushable | Zero |
| **R5** | Plugin tiers 3/4 — `screens`, `migrations`, `assets`, `lifecycle`, `settings`, `notifications` | yes | no | no | no | no | No | **Yes**, Elixir half hot-pushable | Zero |
| **R6** | `Mob.Component` + `Mob.UI.native_view` + a `MobNativeViewRegistry.register` call written **in the app's own Kotlin** | yes | yes | yes | app's own | app's own | **No** — leaf-only | **Partly** — the registration line lives in the forked `MobBridge.kt` (R1 in miniature) unless routed through R2 | Low but non-zero |
| **R7** | `mix mob.add_nif <name> --type c\|rustler\|zigler` | yes | **no** (JNI C is possible but hand-wired) | no | no | no | **No** — pure computation, no UI | **Yes** — app-owned files only | Zero. `--type c` needs manual CMake/build.zig wiring |
| **R8** | `mix mob.enable <feature>` | yes | patches `MainActivity.kt` for some | yes | yes | yes | No | **Partly** — it *edits host files*, which then drift | Low; one-shot Igniter patch |
| **R9** | Mishka Chelekom component | **yes, and only yes** | **no** | no | no | no | It can *emit* one; nothing renders it | Yes | Zero — but see §7 |

---

## 2. R1 — editing the host `MobBridge.kt` directly

### The fork-at-generation problem, in source

`mob` ships **no** host Kotlin. `⟨MOB⟩/android/` contains four Zig files and one header —
`mob_erts.zig`, `driver_tab_android.zig`, `mob_nif.zig`, `mob_zig.zig`, `mob_beam.zig`,
`mob_beam.h`. No `.kt` anywhere in the package.

The renderer is an **EEx template in a different package** —
`⟨MOBNEW⟩/priv/templates/mob.new/android/app/src/main/java/MobBridge.kt.eex`, 3635 lines,
`package <%= java_package %>` on line 1. `mix mob.new` renders it once. From that moment
the app owns it, and nothing ever re-renders it: `mix mob.deploy --native` rebuilds native
code but never touches the template. There is no `mix mob.upgrade`, no bridge diff, no
template resync — the 46 tasks in `⟨MOBDEV⟩/lib/mix/tasks/` are enumerated in §8 and none
does this.

The size of the divergence is already measurable: pristine template **3635 lines** →
Mishka's `⟨MISHKA⟩/development/mob/android/app/src/main/java/com/example/mishka_mob/MobBridge.kt`
is **4607 lines**. A ~1000-line delta on one app after a few months.

### What R1 buys that nothing else does

`MobAnchored` (`⟨MISHKA⟩/.../MobBridge.kt:2471-2577`) is the proof. It is dispatched from
one added line inside the closed `when`:

```kotlin
// :2436
"anchored"       -> MobAnchored(node, m)
```

and does three things no other route can:

1. **Renders `node.children`** — `RenderNode(anchor)` at `:2543`, `RenderNode(panel)` at
   `:2574`. Composition, not a leaf.
2. **Escapes the composition tree** — `androidx.compose.ui.window.Popup` with a custom
   `PopupPositionProvider` (`:2610-…`), i.e. a second window that no ancestor's
   `clip(shape)` or `verticalScroll` can defeat.
3. **Changes core dispatch behaviour** — `RenderNodeInner` was edited at
   `⟨MISHKA⟩/.../MobBridge.kt:2338-2341` so the generic `clickable` branch is skipped for
   this type (`node.type != "anchored"`), because `on_tap` on an anchored node means
   *dismiss*, not *tap the anchor*.

Point 3 is the tell: it is a change to **shared** code, not an addition. No plugin
mechanism can express it.

The imports it needed were added at `⟨MISHKA⟩/.../MobBridge.kt:208-223` under a
`// ── the `anchored` node type ──` banner — 15 new imports.

### What the drift ledger (#32 / `K-05`) must record

`K-05` (`/Users/shahryar/Documents/Programming/Elixir/kati/.scratch/tickets/K-05.md`)
already cites the framework admitting this: mob's own `guides/troubleshooting.md:481-487`
("*every app's `MobBridge` is its own diverged copy*") and `PLAN.md:2383-2420` ("*It will
become a real problem at ~10 [apps]*"), with three candidate fixes and **none
implemented**.

Per-edit, the ledger needs:

| Field | Why |
|---|---|
| **Host file + anchor** | `MobBridge.kt`, `MainActivity.kt`, `AndroidManifest.xml`, `app/build.gradle`, iOS `MobRootView.swift` |
| **Kind** — `addition` / **`modification`** / `import` | Additions re-apply mechanically; **modifications to shared functions (`RenderNodeInner`, `nodeModifier`, `MobBridge.init`) are the ones that conflict.** Mishka has one of each: `:2436` is an addition, `:2338-2341` is a modification |
| **Upstream anchor text** | The exact pristine line(s) the edit sits after / replaces, so a 3-way merge is possible against a re-rendered template |
| **Pristine baseline version** | mob_new version whose template was forked (here: 0.4.20) — the ledger is meaningless without it |
| **Ticket + reason** | Which K-ticket demanded it |
| **Elixir counterpart** | The node type / prop the edit renders, and the `assert_renderable(extra:)` or tags-file entry it needs (§6) |
| **Retire-if** | The condition under which Mob upstream makes it unnecessary (e.g. "mob ships a `shadow` prop") |
| **Reversibility** | Whether the same effect could later move to a plugin (§3) — most *additions* can once the generic seam of §9 exists |

**Regenerate-and-diff is the only verification that works.** `mix mob.new` a throwaway app
with the ledger's pinned mob_new version, `diff` its `MobBridge.kt` against Kati's, and
assert the diff equals the ledger. That check is ~20 lines of shell and is the single
highest-leverage thing to build alongside the first bridge edit.

---

## 3. R2/R3 — a Mob plugin

### The five tiers (`⟨MOBGIT⟩/MOB_PLUGINS.md:26-32`), and what mob_dev actually does with each

| Tier | Manifest sections | Actually wired by |
|---|---|---|
| 0 | none (no `priv/mob_plugin.exs` at all) | `Manifest.load/1` returns `{:ok, nil}` (`⟨MOBDEV⟩/lib/mob_dev/plugin/manifest.ex:48-56`); contributes nothing |
| 1 | `nifs`, `android`, `ios`, `permissions` | `Merge.nifs/1`, `nif_sources/2`, `zig_nif_sources/2`, `static_archives/2`, `android_sources/1`, `bridge_kt_sources/1`, `bridge_classes/1` |
| 2 | `ui_components` | **asymmetric — see below** |
| 3 | `screens`, `migrations`, `assets` | runtime manifest → `Mob.Plugins` |
| 4 | `lifecycle`, `settings`, `notifications` | runtime manifest → `Mob.Plugins.Supervisor` |

Classification lives at `⟨MOBDEV⟩/lib/mob_dev/plugin/manifest.ex:22-36`.

### Authoring + registration

A plugin is a plain Hex (or `path:`) dep with `priv/mob_plugin.exs`
(`@manifest_path`, `⟨MOBDEV⟩/lib/mob_dev/plugin/manifest.ex:16`). Two-step opt-in:

```elixir
# mix.exs
{:kati_native, path: "plugins/kati_native"}
# mob.exs
config :mob, :plugins, [:kati_native]
```

`MobDev.Plugin.activated/0` (`⟨MOBDEV⟩/lib/mob_dev/plugin.ex:111-120`) resolves each
activated name through **`Mix.Project.deps_paths()`** — so a `path:` dep is a
first-class plugin, no Hex publish required. Scaffold with
`mix mob.new_plugin <name> --tier 0..4` (`⟨MOBDEV⟩/lib/mix/tasks/mob.new_plugin.ex`).

### Ed25519 signing and the trust gate

`⟨MOBDEV⟩/lib/mob_dev/plugin/crypto.ex` — raw Ed25519 over a canonical term encoding:

```elixir
def generate_keypair do
  {pub, priv} = :crypto.generate_key(:eddsa, :ed25519)
  {priv, pub}
end
def sign(payload_term, priv_bin) when is_binary(priv_bin) do
  payload = canonical_encode(payload_term)
  :crypto.sign(:eddsa, :sha512, payload, [priv_bin, :ed25519])
end
```

Public key → `priv/mob_plugin.pub`, signature → `priv/mob_plugin.sig`; the host-visible
identifier is base64(SHA-256(pubkey)) (`crypto.ex:29`). Tasks: `mob.plugin.keygen`,
`mob.plugin.sign`, `mob.plugin.trust`, `mob.plugin.untrust`, `mob.validate_plugin`,
`mob.audit_plugins`.

The build-time gate is `MobDev.Plugin.SignatureGate.check_activated/1`
(`⟨MOBDEV⟩/lib/mob_dev/plugin/signature_gate.ex:52-70`), invoked from inside
`Validator.raise_on_capability_drift!/1`, which the Android path calls at
`⟨MOBDEV⟩/lib/mob_dev/native_build.ex:4564`. Four failure modes
(`signature_gate.ex:29-34`): `:missing_signature` (**suppressible** via
`config :mob, :acknowledge_unsafe_plugins`), `:missing_pubkey`, `:invalid_signature`
(**not** suppressible), `:untrusted` (**not** suppressible; run `mix mob.plugin.trust`).

**For Kati this is a non-issue.** `⟨MOBGIT⟩/MOB_PLUGIN_SECURITY.md:207-243` documents
`config :mob, :plugin_security, :dev` (path deps + git refs accepted unsigned) and the
per-plugin `config :mob, :unsafe_plugins, [{:kati_native, allow: [:unsigned]}]` escape
hatch, valid in any mode. A private `path:` plugin costs one config line.

### **The key question: can a plugin register a new renderable node type natively?**

**Answer: No for a genuinely new `node.type`. Yes for a `native_view` component — and on
Android only by way of tier 1's `bridge_kt` + `bridge_class`, not by the `ui_components`
field the doc points at.**

**(a) A new `node.type` — no, and nothing comes close.** Every plugin-Android function in
`⟨MOBDEV⟩/lib/mob_dev/native_build.ex` was read: `apply_plugin_android_manifest!` (`:4557`),
`apply_plugin_gradle_deps!` (`:4599`), `apply_plugin_android_kotlin!` (`:5035`),
`apply_plugin_android_res!` (`:4941`). **None reads, parses or writes `MobBridge.kt`.**
`apply_plugin_android_kotlin!` copies plugin `.kt` files verbatim and generates four fixed
files under `io.mob.plugin`. The `when (node.type)` block is untouchable from a plugin.

**(b) iOS `ui_components` — fully automatic, with one sharp edge.**
`MobDev.Plugin.IOSBootstrap.swift_source/1` (`⟨MOBDEV⟩/lib/mob_dev/plugin/ios_bootstrap.ex:57-64`)
emits a `@_cdecl("mob_register_plugins")` function; `AppDelegate.m` calls it before
`mob_init_ui()`. Each line is (`ios_bootstrap.ex:88-94`):

```elixir
"    MobNativeViewRegistry.shared.register(\"#{view_module}\") { props, _send in",
"        AnyView(#{swift_struct}(props: props))",
"    }"
```

Two sharp edges. First, `_send` is **discarded** — a plugin iOS view registered this way
**cannot send events back to the BEAM**; event-bearing iOS views need hand-written
registration. Second, the codegen requires `ui_components.ios.swift_struct`, and a
component lacking it is **silently dropped** (`ios_bootstrap.ex:87-97`). `swift_struct`
is validated (`⟨MOBDEV⟩/lib/mob_dev/plugin/validator.ex:386-415`) but **appears zero times
in `MOB_PLUGINS.md`** — an undocumented, load-bearing field.

**(c) Android `ui_components.android.composable` is inert.** Exhaustive grep of
`⟨MOBDEV⟩/lib` for `composable`: the *only* non-comment consumers are
`Validator.conflict_surface/0` (`validator.ex:242-243`) and `component_composables/1`
(`validator.ex:572-578`) — both cross-plugin collision detection. **There is no Android
counterpart to `IOSBootstrap`.** Declaring `android: %{composable: "MobChart"}` reserves a
name and does nothing else. `⟨MOBGIT⟩/MOB_PLUGINS.md:193-197` ("*mob's renderer dispatches
`"chart" -> MobChart(node, m)`*") describes behaviour that **does not exist**.

`mix mob.new_plugin --tier 2` is honest about it. `Scaffold.tier2_kt/2`
(`⟨MOBDEV⟩/lib/mob_dev/plugin/scaffold.ex:505-513`) generates a `.kt` whose header reads:

> *"Until the plugin merge engine wires plugin Kotlin into the build automatically, the
> host app developer copies this content into MobBridge.kt (alongside the
> MobNativeViewRegistry definition) and arranges `<Mod>Plugin.register()` to run at
> startup — the documented workflow for native components today."*

and `tier_specific_hint(2, name)` (`⟨MOBDEV⟩/lib/mix/tasks/mob.new_plugin.ex:139-146`)
prints the same manual instruction. Worse, `tier2_manifest/4`
(`scaffold.ex:480-503`) emits neither `android.bridge_kt`/`bridge_class` **nor**
`ios.swift_struct` — so a freshly scaffolded tier-2 plugin's native half is wired on
**neither** platform.

**(d) The Android route that does work — tier 1's bridge, carrying a tier-2 payload.**
`apply_plugin_android_kotlin!` (`⟨MOBDEV⟩/lib/mob_dev/native_build.ex:5035-5084`):

```elixir
Enum.flat_map(MobDev.Plugin.Merge.bridge_kt_sources(activated), fn src ->
  case File.read(src) do
    {:ok, content} ->
      case __parse_kotlin_package__(content) do
        nil -> ...skip...
        package ->
          dest = __bridge_kt_dest__(@android_java_root, package, Path.basename(src))
          File.mkdir_p!(Path.dirname(dest)); File.write!(dest, content); [dest]
      end
    ...
  end
end)
__prune_plugin_artifacts__(:android_kotlin, written)
```

The destination is derived from **the file's own `package` line**
(`__parse_kotlin_package__/1`, `:5089-5094`; `__bridge_kt_dest__/3`, `:5097-5100`). Then
`__bootstrap_kotlin__/1` (`:5148-5206`) generates `io.mob.plugin.MobPluginBootstrap`:

```kotlin
object MobPluginBootstrap {
    @JvmStatic
    fun registerAll(activity: Activity) {
        io.kati.native.KatiBridge.register()
        handOff(io.kati.native.KatiBridge, activity)
        collectPermissionProvider(io.kati.native.KatiBridge)
    }
    ...
}
```

called from `MainActivity.onCreate` at
`⟨MOBNEW⟩/priv/templates/mob.new/android/app/src/main/java/MainActivity.kt.eex:150` —
**after `super.onCreate`, before `setContent` (`:176`)**. So the registry is populated
before the first composition.

And `MobNativeViewRegistry` is a plain top-level, default-public Kotlin `object`
(`MobBridge.kt.eex:2136-2158`) with a mutable map:

```kotlin
object MobNativeViewRegistry {
    private val factories = mutableMapOf<String, MobNativeViewFactory>()
    fun register(name: String, factory: MobNativeViewFactory) { factories[name] = factory }
    @Composable fun render(node: MobNode) { ... factory(node.props, send) }
    external fun nativeDeliverComponentEvent(handle: Int, event: String, payloadJson: String)
}
```

**Therefore:** a plugin whose `bridge_kt` declares `package <the Kati app's package>` is
copied into the host package alongside `MobBridge.kt`, compiles with full access to
`MobNativeViewRegistry`, `MobBridge`, `MobNode` and every helper in the file, and its
`register()` runs at boot — **with zero edits to any host file**. Its `send` closure works
(unlike the iOS codegen path). Its copy is ledger-tracked and pruned on removal
(`native_build.ex:5065`).

The cost: hard-coding the host's Kotlin package makes the plugin **Kati-specific**. For a
private `path:` dep that is exactly right; for a published plugin it is fatal. There is no
mechanism to templatise the package — the copier reads a literal `package` line.

### Everything else a plugin contributes (verified in `Merge`)

`⟨MOBDEV⟩/lib/mob_dev/plugin/merge.ex` — every gatherer, with the manifest key:

| Gatherer | Manifest key | Lands where |
|---|---|---|
| `nifs/1` `:26` | `nifs[].{module,native_dir,lang,platform}` | static-NIF driver table |
| `nif_sources/2` `:172` | `lang: :c` / `:objc` | `-Dplugin_c_nifs` |
| `zig_nif_sources/2` `:202` | `lang: :zig` | `-Dplugin_zig_nifs` |
| `static_archives/2` `:256` | `lang: :cpp_archive` + `sources`/`includes`/`cxxflags*`/`nm_symbol` | cross-compiled `libNAME.a` |
| `android_permissions/1` `:39` | `android.permissions` | `<uses-permission>` in a managed block |
| `gradle_deps/1` `:43` | `android.gradle_deps` | `implementation "…"` in a managed block |
| **`android_manifest_snippets/1` `:54`** | **`android.manifest_application_snippets`** | spliced before `</application>`, idempotent per `android:name` |
| **`android_res_files/1` `:70`** | **`android.res_files`** | copied to `res/<type>/<file>`, path-contained + host-clobber-guarded |
| `bridge_kt_sources/1` `:134` | `android.bridge_kt` | app Kotlin sourceSet, at the file's own package |
| `bridge_classes/1` `:143` | `android.bridge_class` | `MobPluginBootstrap.registerAll` |
| `jni_sources/1` `:126` | `android.jni_source` | `-Dplugin_jni_sources` |
| `swift_files/1` `:103`, `ios_frameworks/1` `:99`, `plist_keys/1` `:295` | `ios.*` | swiftc / link / Info.plist |
| `screens/1` `:330`, `migrations/1` `:342`, `assets/1` `:361`, `lifecycle/1` `:375`, `settings/1` `:384`, `notification_handlers/1` `:396` | tier 3/4 | `priv/generated/mob_plugins.exs` |
| `host_requirements/1` `:412` | `host_requirements` | printed as a warning on every `--native` build |

**`mob_dev` 0.6.19 added `manifest_application_snippets` + `res_files`
(`⟨MOBDEV⟩/CHANGELOG.md:89-104`, MOB-39) and `MOB_PLUGINS.md` still omits them** — grep of
`⟨MOBGIT⟩/MOB_PLUGINS.md` returns **0** hits for both. The same grep returns **0** for
`cpp_archive`, `swift_struct`, `nm_symbol` and NIF `platform:`. Six implemented,
undocumented fields.

The 0.6.19 companion change matters as much: plugin contributions to host-owned build
files are now fenced in regenerated **managed blocks**
(`⟨MOBDEV⟩/lib/mob_dev/native_build.ex:5278-5289`):

```
    <!-- mob:plugin-permissions BEGIN (managed — regenerated each build; do not edit) -->
        <!-- mob:plugin-components BEGIN (managed — regenerated each build; do not edit) -->
    // mob:plugin-deps BEGIN (managed — regenerated each build; do not edit)
```

So plugin manifest/gradle contributions are **reversible** — removing the plugin removes
them. Hand-authored content outside the fence is untouched. This is the property R1 lacks
entirely, and it is the strongest argument for pushing everything possible into R2.

Two extra stable seams the plugin bridge can implement, both generated unconditionally:
`io.mob.plugin.MobActivityAware` (`native_build.ex:5237-5250`) — `setActivity(activity)`,
called from `registerAll` — and `io.mob.plugin.MobPermissionProvider`
(`native_build.ex:5215-5228`) — `permissionsFor(cap): Array<String>?`, consulted by core
`MobBridge.request_permission` for capabilities core does not know. A third,
`MobNotifyHub` (`native_build.ex:5113-5136`), is the notification-delivery seam.

**`MobActivityAware` is the ActivityResult seam.** `registerAll(this)` runs inside
`onCreate` (`MainActivity.kt.eex:150`) — *before* the Activity is STARTED — so a bridge
casting the handed Activity to `ComponentActivity` may legally call
`registerForActivityResult`. Compare the host's own file picker, a property initialiser at
`MainActivity.kt.eex:115-118` using `ActivityResultContracts.OpenMultipleDocuments`. This
is how `ACTION_CREATE_DOCUMENT` gets in without touching `MainActivity.kt` — but it is at
the edge of the AndroidX contract and must be device-verified, not assumed.

### Cross-plugin conflict detection

`Validator.conflict_surface/0` (`⟨MOBDEV⟩/lib/mob_dev/plugin/validator.ex:234-…`) classifies
every shared namespace as `:collision` / `:namespaced` / `:union` / `:build_time` /
`:derived`, and a `conflict_surface_test` asserts the classification covers **every**
gatherer in `Merge` — adding a gatherer without classifying it fails CI. Collision fields
include screen route, component atom, iOS `view_module`, Android `composable`, NIF module,
`cpp_archive` `nm_symbol`, Swift/JNI basenames, `bridge_class`, manifest-component
`android:name`, res destination, plist key, supervised worker, notification match.

---

## 4. R4/R5 — the pure-Elixir plugin lanes (no native at all)

**`expand:` composites.** Validated as **native XOR expand**
(`⟨MOBDEV⟩/lib/mob_dev/plugin/manifest.ex:573-601`) — mixing them is an error whose message
is itself the design statement: *"a composite that needs a native part should emit
`Mob.UI.native_view`"* (`:593`).

The pass is `Mob.Composite` (`⟨MOB⟩/lib/mob/composite.ex`), and it runs **first** in the
render pipeline (`⟨MOB⟩/lib/mob/screen.ex:727-733`):

```elixir
module.render(socket.assigns)
|> Mob.Composite.expand(self())          # composites first
|> Mob.List.expand(list_renderers, self())
|> Mob.Component.expand(self(), platform)
```

Contract: `expand(props, children, ctx)`; `on_*` props written as bare strings/atoms are
auto-injected as `{screen_pid, tag}` (no `self()` threading); fixpoint recursion with
`@max_depth 20` (`composite.ex:46`); a crashing expander logs and renders an empty Column
rather than killing the screen. Registration is either the manifest `expand:` form (boot,
via `Mob.Plugins.register_composites/0`, `⟨MOB⟩/lib/mob/plugins.ex:358-366`) or
`Mob.Composite.register/2` at runtime (`composite.ex:51-56`) — the latter needs no manifest
at all.

**Tiers 3/4** are entirely runtime-wired off `priv/generated/mob_plugins.exs`, read once at
boot by `Mob.Plugins.boot/1` (`⟨MOB⟩/lib/mob/plugins.ex:79-86`). The manifest's key set is
closed (`⟨MOB⟩/lib/mob/plugins.ex:21-32`):

```elixir
@empty %{screens: [], lifecycle: [], settings: [], notification_handlers: [],
         nifs: [], composites: [], styles: [], default_style: nil}
```

**There is no `node_types` key.** The runtime plugin system has no concept of a renderable
node type — which independently confirms §3(a) from the mob side.

---

## 5. R6 — `Mob.Component` + `MobNativeViewRegistry`, the full contract

This is the framework-blessed pairing of an Elixir process with a native view addressed by
string name. It works identically whether the Kotlin arrives by R1, R2 or R6.

### The four moving parts

**1. Declaration.** `⟨MOB⟩/lib/mob/ui.ex:118-124`:

```elixir
@spec native_view(module(), keyword() | map()) :: map()
def native_view(module, props \\ [])
def native_view(module, props) when is_list(props), do: native_view(module, Map.new(props))
def native_view(module, %{} = props) when is_atom(module) do
  %{type: :native_view, props: Map.put(props, :module, module), children: []}
end
```

**2. Expansion.** `Mob.Component.expand/3` (`⟨MOB⟩/lib/mob/component.ex:118-145`) walks the
tree, starts or updates a `Mob.ComponentServer` per `{id, module}`, calls the component's
`render/1`, and rewrites the node's props:

```elixir
enriched =
  Map.merge(rendered_props, %{
    module: module_name(module),
    id: Atom.to_string(id),
    component_handle: handle
  })
```

`module_name/1` (`component.ex:179-184`) is the naming convention:
`"Elixir.Kati.Ui.PosterShelf"` → **`"Kati_Ui_PosterShelf"`**. `:module` and `:id` must both
be atoms or it raises (`component.ex:127-130`). It returns `active_keys`, and
`Mob.ComponentRegistry.reconcile/2` (`screen.ex:735`) stops components that left the tree.

**3. The process.** `Mob.ComponentServer` (`⟨MOB⟩/lib/mob/component_server.ex`) — a
GenServer started **unlinked** (`:11`, so a component crash cannot take the screen down).
At `init/1` it calls `module.mount(props, socket)`, registers, and allocates the NIF handle
(`:46-51`):

```elixir
handle = if platform != :no_render, do: :mob_nif.register_component(self()), else: 0
```

Events arrive as `{:component_event, event, payload_json}` (`:87-100`), are JSON-decoded
with `:json.decode/1`, dispatched to `handle_event/3`, and the screen is poked with
`send(screen_pid, {:component_changed, id, module})` so it re-renders. `terminate/2`
deregisters the handle (`:120`).

**4. The native side.** `MobBridge.kt.eex:2136-2158` (quoted in §3(d)). `render/1` bails
silently on a missing `module`, a missing factory, or a missing `component_handle`
(`:2145-2147`) — three separate silent no-ops worth knowing when debugging.

### Behaviour callbacks (`⟨MOB⟩/lib/mob/component.ex:68-84`)

```elixir
@callback mount(props :: map(), socket :: Mob.Socket.t()) :: {:ok, Mob.Socket.t()} | {:error, term()}
@callback update(props :: map(), socket :: Mob.Socket.t()) :: {:ok, Mob.Socket.t()}
@callback render(assigns :: map()) :: map()
@callback handle_event(event :: String.t(), payload :: map(), socket :: Mob.Socket.t()) :: {:noreply, Mob.Socket.t()}
@callback handle_info(message :: term(), socket :: Mob.Socket.t()) :: {:noreply, Mob.Socket.t()}
@callback terminate(reason :: term(), socket :: Mob.Socket.t()) :: term()
@optional_callbacks [update: 2, handle_event: 3, handle_info: 2, terminate: 2]
```

`use Mob.Component` (`:86-105`) defaults `update/2` to `mount/2` and makes
`handle_event/3` **raise** on an unhandled event — loud by design.

### Worked example (the shape Kati should use)

```elixir
# lib/kati/ui/poster_shelf.ex
defmodule Kati.Ui.PosterShelf do
  use Mob.Component

  @impl true
  def mount(props, socket), do: {:ok, Mob.Socket.assign(socket, :items, props[:items] || [])}

  @impl true
  def update(props, socket), do: {:ok, Mob.Socket.assign(socket, :items, props[:items])}

  # render/1 returns the PROPS MAP handed to the native factory — not a node tree.
  @impl true
  def render(assigns), do: %{items: assigns.items}

  @impl true
  def handle_event("poster_tapped", %{"id" => id}, socket) do
    send(socket.assigns.parent, {:poster, id})
    {:noreply, socket}
  end
end
```

```elixir
# in a screen
Mob.UI.native_view(Kati.Ui.PosterShelf, id: :shelf, items: @items)
```

```kotlin
// plugins/kati_native/priv/native/android/KatiBridge.kt
// NOTE: the HOST app's package — this is what makes MobNativeViewRegistry visible.
package io.kati.app

import androidx.compose.runtime.Composable

object KatiBridge {
    @JvmStatic
    fun register() {
        MobNativeViewRegistry.register("Kati_Ui_PosterShelf") { props, send ->
            PosterShelf(props) { id -> send("poster_tapped", mapOf("id" to id)) }
        }
    }
}

@Composable
private fun PosterShelf(props: Map<String, Any?>, onTap: (String) -> Unit) { /* … */ }
```

```elixir
# plugins/kati_native/priv/mob_plugin.exs
%{
  name: :kati_native,
  mob_version: "~> 0.7",
  plugin_spec_version: 1,
  android: %{
    bridge_kt: "priv/native/android/KatiBridge.kt",
    bridge_class: "io.kati.app.KatiBridge"
  },
  ui_components: [
    %{tag: "PosterShelf", atom: :poster_shelf,
      ios: %{view_module: "Kati_Ui_PosterShelf", swift_struct: "KatiPosterShelfView"},
      android: %{composable: "Kati_Ui_PosterShelf"}}
  ],
  ios: %{swift_files: ["priv/native/ios/KatiPosterShelfView.swift"]}
}
```

The `ui_components` entry earns its keep on iOS (drives `IOSBootstrap` codegen, given
`swift_struct`) and as a **collision reservation** on Android. The Android wiring is done
by `bridge_kt` + `bridge_class`.

### Hard limits, restated

- **Leaf only.** No children, ever (§0.2). Any wrapping/containment need is out of scope.
- **Props must survive `:json.encode`.** They pass through `Renderer.prepare_props/4`
  (`renderer.ex:281-…`); token resolution applies to known color/size/spacing keys, and
  everything else passes through as-is.
- **Events are JSON only**, via `nativeDeliverComponentEvent(handle, event, payloadJson)`.
- **The registry key is a string derived from the Elixir module name** — rename the module
  and the view silently disappears. Nothing checks agreement at build time on Android.

---

## 6. Testing gate — `assert_renderable` will reject a custom node type

`Mob.ScreenCase` bakes `@renderable_types` **at mob's compile time** from
`priv/tags/{ios,android}.txt` plus `:native_view`
(`⟨MOB⟩/lib/mob/screen_case.ex:91-113`), and `assert_renderable/2` flunks on anything else
(`:295-313`). The `~MOB` sigil validates tags against the same two files
(`⟨MOB⟩/lib/mob/sigil.ex:78-90`).

So a custom node type has **three** registration surfaces, only one of which is native:

1. Kotlin `when` branch (R1) — else it renders nothing.
2. `assert_renderable(view, extra: [:kati_blur])` — or the tags file.
3. `~MOB` sigil tag list — only if written as `<KatiBlur/>` rather than as a raw map.

Mishka chose to rewrite `deps/mob/priv/tags/*.txt` on every compile (§Roots). **Kati should
not.** Use `extra:` on the assertion and emit raw maps from component functions, keeping
`deps/` pristine so the regenerate-and-diff drift check of §2 stays meaningful.

---

## 7. R9 — Mishka Chelekom components, and why `:anchored` is broken for consumers

**A Mishka component cannot carry native Kotlin. Verified, not inferred.**

- `find ⟨MISHKA⟩/priv ⟨MISHKA⟩/lib -name "*.kt"` → **zero results**.
- The generator's shipped artefacts are `⟨MISHKA⟩/priv/mob/*.eex` + `*.exs` — 147 files,
  all Elixir templates and prop specs.
- `MishkaChelekom.Generators.Mob.source_dir/0`
  (`⟨MISHKA⟩/lib/mishka_chelekom/generators/mob.ex:47`) is
  `"development/mob/lib/mishka_mob/components"` — Elixir only.
- `@kit_modules ~w(anchored color event)` (`generators/mob.ex:44`) with the comment:
  *"`anchored` is one of these rather than a component: it builds the `:anchored` node that
  popover, tooltip and preview_card all place their panel in, and a generated popover will
  not compile without it."*
- `⟨MISHKA⟩/development/mob/lib/mishka_mob/components/anchored.ex:98`:
  `%{type: :anchored, props: take(opts), children: [anchor, panel]}`

So a consumer who runs `mix mishka.ui.gen.mob.kit` receives the Elixir that **emits**
`:anchored` and **none** of the 190 lines of Kotlin at
`⟨MISHKA⟩/development/mob/android/.../MobBridge.kt:2436, 2471-2660` that render it. The
node reaches Compose, hits the `when` with no matching branch and no `else`, and
**disappears**. No error. Popover, tooltip, preview-card, combobox, select, menu,
navigation-menu, tree-select, autocomplete and context-menu all degrade to an invisible
panel.

**Resolution, given the Q5 constraint (Mishka stays headless and unstyled):**

Mishka's constraint is about **styling**, not about **shipping renderers** — and Mishka is
a *generator*, not a dependency (`⟨MOBGIT⟩/MOB_PLUGINS.md:909-935` settles the two-lane
question explicitly: *"For Mishka specifically, the faithful port is the generator lane."*).
A generator can only emit source into the consumer's project; it has no build hook, no
manifest, and no path into `MobBridge.kt`. Therefore:

**The native half of a Mishka component must always live in Kati (R1) or in a Kati-owned
plugin (R2) — never in Mishka.** Mishka's obligation is narrower and achievable:

1. Emit the node (already done).
2. **Ship the Kotlin as an inert, versioned text asset** the consumer pastes or a plugin
   vendors — e.g. `priv/mob/native/android/anchored.kt` plus a `usage-rules/mob/` entry
   stating the exact `when` line to add. Today it ships nothing, so the consumer cannot
   even discover what is missing.
3. **Fail loudly instead of silently** — the kit module should carry an
   `assert_renderable`-style note and, better, a dev-mode guard so a missing renderer
   surfaces in test rather than as an invisible panel on device.

Point 2 is a real, small change that fits `SKILL.md`'s definition of done
(`⟨MISHKA⟩/.claude/skills/mob-component-fix/SKILL.md`: component + showcase-with-handler +
unit test + Kotlin e2e + `mix mishka.mob.sync` + usage-rules + CHANGELOG).

---

## 8. R7/R8 — computation and pre-named features

### `mix mob.add_nif <name> --type c|rustler|zigler|elixir-only`

`⟨MOBDEV⟩/lib/mix/tasks/mob.add_nif.ex`. Igniter-backed. Three-to-five files change
(`:11-31`): `lib/<app>/nifs/<name>.ex` stub, a `%{module: :<name>, archs: [:all]}` entry
appended to `mob.exs`'s `:static_nifs` (`:329-349`), and `mix mob.regen_driver_tab`
composed into the same run (`:88`).

| `--type` | Files | Auto-linked on device? |
|---|---|---|
| `elixir-only` | stub only | n/a |
| `c` | `+ c_src/<name>.c` | **No.** The generated header says so verbatim (`:556`): *"Wire this file into your platform builds (TODO: scaffolded auto-wire — see mob/issues.md #18)"* — Android CMakeLists, iOS `build.zig` + `build_device.zig`, by hand, with `-DSTATIC_ERLANG_NIF` and `-DSTATIC_ERLANG_NIF_LIBNAME=<name>` |
| `rustler` | `+ native/<name>/{Cargo.toml,src/lib.rs,.cargo/config.toml}`, adds `{:rustler, "~> 0.32"}` | **Yes** — mob_dev cross-compiles the staticlib and links it |
| `zigler` | `~Z` in the stub, pins `{:zigler, github: "GenericJam/zigler", branch: "zig-016-port"}`, queues `mix zig.get` | **Yes** |

Two pins worth recording in the ledger, both flagged transient in source: the zigler fork
(macOS 26 SDK + Zig 0.16 `nif_init` symbol collision, `:216-223`) and a `[patch.crates-io]`
rustler fork for an Android `dlopen(NULL)`/Bionic bug (`:485-496`).

Static linking is non-negotiable (`:33-40`): iOS rejects bundled `.dylib`; Android's
`RTLD_LOCAL` hides `enif_*` from a `dlopen`'d child.

**A NIF gives compute and OS access, never UI.** It cannot render, cannot register a node
type, cannot touch Compose. For an Android *capability* (WorkManager, Keystore,
CalendarContract) the NIF is only half — the other half is a Kotlin/JNI bridge, i.e. R2.

### `mix mob.enable <feature>`

`@valid_features ~w(liveview camera photo_library file_sharing location notifications
pythonx mlx nxeigen tflite)` (`⟨MOBDEV⟩/lib/mix/tasks/mob.enable.ex:165`) — ten, of which
`nxeigen` and `tflite` are absent from `⟨MOBGIT⟩/guides/native_extensions.md:64-73`. One
Igniter run patches `mix.exs`, Info.plist / AndroidManifest, and for `pythonx` edits
`MainActivity.kt` (`⟨MOBDEV⟩/lib/mob_dev/enable.ex:316`). **It edits host files, so its
output becomes part of the drift surface** — record what it changed.

---

## 9. Recommendation per Kati native need

Three facts decide almost every row:

- **Wrapping existing Mob content ⇒ R1.** `native_view` is a leaf (§0.2).
- **Adding/changing a prop on an existing node type ⇒ R1.** `nodeModifier` is unreachable
  (§0.3).
- **Adding a self-contained view, or an OS capability with no UI ⇒ R2.** Zero merge cost.

Verified absences in pristine mob 0.7.20 / mob_new 0.4.20 (grep counts against
`MobBridge.kt.eex`): `shadow` 0 · `elevation` 0 · `semantics` 0 · `combinedClickable` 0 ·
`onLongClick` 0 · `FontVariation` 0 · `ACTION_CREATE_DOCUMENT` 0 · `WorkManager` 0 ·
`Keystore` 0 · `CalendarContract` 0 · `ModalBottomSheet` 0. (The 3 `blur` hits are
`nativeSendBlur` — focus-blur events. The 3 `Sheet` hits are `action_sheet_show` and the
system share sheet.) `Mob.Files.pick/2` uses `ActivityResultContracts.OpenMultipleDocuments`
(`MainActivity.kt.eex:116`) — **read only**, no create.

| Need | Route | Why, and what it costs |
|---|---|---|
| **Coloured shadows** | **R1** — new prop on the shared modifier | It is a `Modifier.shadow(elevation, shape, ambientColor, spotColor)` on *existing* nodes. Only `nodeModifier` can apply it. ~12 lines inside `nodeModifier` (`MobBridge.kt.eex:3366-3436`) reading `shadow_elevation` / `shadow_color` / `shadow_ambient`. **Ledger kind: `modification`** — a shared function. Elixir side: nothing; unknown props already pass through the renderer |
| **Backdrop blur** | **R1** — a wrapping node type | `Modifier.blur` (API 31+) or a `RenderEffect`-backed surface must sit *around* Mob content. Leaf-only routes are disqualified. Prefer **not** a `kati_blur` type but the generic container of the note below |
| **Modal sheet** | **R1** — a wrapping node type, and the strongest case for the generic seam | `ModalBottomSheet` needs (a) children, (b) its own window/scrim, (c) a dismiss callback into the BEAM. Structurally the same shape as `MobAnchored`: `RenderNode(child)` inside a window, `MobBridge.nativeSendTap(handle)` on dismiss. Copy that pattern — it is device-proven at `⟨MISHKA⟩/.../MobBridge.kt:2471-2577` |
| **`semantics`** (a11y) | **R1** — new props on the shared modifier | `Modifier.semantics { contentDescription = …; role = … }` must apply to *every* node type. Same function, same ledger entry as shadows — bundle them into one `modification` and you pay the merge cost once. Note core already sets a `testTag` for id'd nodes (`MobBridge.kt.eex:2184-2187`), so the hook point exists |
| **`combinedClickable` / long-press** | **R1** — modification of `RenderNodeInner` | The generic tap wiring is `RenderNodeInner`'s `modifier.clickable { … }` at `MobBridge.kt.eex:2179-2183`. Long-press means swapping it for `combinedClickable(onClick=…, onLongClick=…)` and reading a new `on_long_press` handle. Elixir side is free: `Mob.Renderer.prepare_props/4` already registers `{pid, tag}` tuples for `on_tap`/`on_change`/`on_focus`/`on_blur`/`on_submit` (`renderer.ex:308-330`) — add one clause. **This is the same shared function `MobAnchored` had to modify (`⟨MISHKA⟩/.../MobBridge.kt:2338-2341`) — expect a conflict there on every bump** |
| **Variable-font axes** | **R1** — extend `fontFamilyProp` | `FontVariation.Settings(FontVariation.weight(n), FontVariation.width(n), …)` on `Font(…, variationSettings = …)`, inside the existing `fontFamilyProp(node.props, LocalContext.current)` used by `MobText` (`MobBridge.kt.eex:2271`). **Ship the font file via R2** — plugin `assets.fonts` are build-bundled to Android `res/font` uncompressed and device-verified (`⟨MOBGIT⟩/MOB_PLUGINS.md:349-363`). So this splits: font **delivery** = R2 (free), axis **application** = R1 (~10 lines) |
| **`ACTION_CREATE_DOCUMENT`** | **R2** first; **R1** fallback | Try the plugin bridge implementing `MobActivityAware` and calling `registerForActivityResult(ActivityResultContracts.CreateDocument(mime))` from `setActivity`, which runs in `onCreate` before STARTED (`MainActivity.kt.eex:150`, `native_build.ex:5237-5250`). If AndroidX rejects the timing on device, fall back to a property initialiser in `MainActivity.kt` mirroring the existing picker at `:115-118` — a small, isolated **addition**, not a modification |
| **WorkManager periodic fetch** | **R2**, cleanly and entirely | No UI. Needs a Gradle dep (`gradle_deps`), a `<provider>`/`<receiver>` (`manifest_application_snippets`, **0.6.19**), a Kotlin `CoroutineWorker` + enqueue helper (`bridge_kt` + `bridge_class`), and an Elixir-callable NIF (`nifs` + `jni_source`). Every piece has a manifest key; **every piece is fenced and reversible**. Zero host-file edits. This is the archetypal R2 case |
| **Keystore / encrypted storage** | **R2** | `androidx.security:security-crypto` via `gradle_deps`; `EncryptedSharedPreferences` / `KeyStore` wrapped in `bridge_kt`; surface as a NIF. Pairs with `MobPermissionProvider` if a capability gate is wanted. No UI, no node type, no host edit |
| **`CalendarContract`** | **R2** | ContentProvider reads/writes + `READ_CALENDAR`/`WRITE_CALENDAR` via `android.permissions` (fenced managed block since 0.6.19), the query/insert code in `bridge_kt`, exposed as a NIF. Consistent with the already-decided *"`CalendarContract` only, no Google Calendar sync ever"* (#52). If an `ACTION_INSERT` intent path is wanted for user-confirmed inserts, that reuses the `MobActivityAware` seam from the `CREATE_DOCUMENT` row |

**Score: 4 of 10 need no bridge edit at all (WorkManager, Keystore, CalendarContract,
plus font delivery); 1 is R2-first (`CREATE_DOCUMENT`); 5 require R1.**

### The single highest-value architectural recommendation

Five of the ten needs force an R1 edit, and three of those (blur, modal sheet, and any
future wrapping component) are the **same shape**: *a node type that renders its children
inside something Compose-specific*. Adding five bespoke `when` branches means five
permanent ledger entries and five merge conflicts forever.

Instead, spend the R1 budget **once** on a generic seam that mirrors `MobNativeViewRegistry`
but passes the node and a child-renderer:

```kotlin
// ONE addition to the when block:
"native_container" -> MobNativeContainerRegistry.render(node, m)

// ONE new object, ~20 lines, alongside MobNativeViewRegistry:
typealias MobContainerFactory =
    @Composable (node: MobNode, modifier: Modifier, renderChild: @Composable (MobNode) -> Unit) -> Unit

object MobNativeContainerRegistry {
    private val factories = mutableMapOf<String, MobContainerFactory>()
    fun register(name: String, f: MobContainerFactory) { factories[name] = f }
    @Composable fun render(node: MobNode, m: Modifier) {
        val f = factories[node.props["module"] as? String ?: return] ?: return
        f(node, m) { child -> RenderNode(child) }
    }
}
```

After that one `addition` + one `modification`, **every** wrapping component Kati or Mishka
ever needs — blur, modal sheet, anchored, parallax container, shared-element transition — is
an R2 plugin with zero further host edits, ledger-fenced and reversible. Mishka's
`:anchored` could migrate onto it and become genuinely portable for consumers.

Do the same consolidation on the modifier side: land coloured shadows, `semantics`,
`combinedClickable` and variable-font axes as **one** `nodeModifier`/`RenderNodeInner`
change in a single ticket, so the permanent conflict surface is two functions rather than
six scattered hunks.

---

## 10. Corrections to `MOB_PLUGINS.md` (for the team's reference)

| Doc claim | Source reality |
|---|---|
| `:190-197` — *"mob's renderer dispatches `case .chart:` → `MobChartView(node:)` / `"chart" -> MobChart(node, m)`"* | **False on both platforms.** iOS goes through `MobNativeViewRegistry.shared` keyed by `view_module`, never a `case` on node type. Android has **no** codegen at all for `android.composable` |
| `:160` — *"Adds new render-tree node types"* (tier 2) | Adds `native_view` **factories**. No node type is added anywhere |
| `:673-684` schema reference | Omits `android.bridge_class` (used in the tier-1 example at `:121` but never listed), `android.manifest_application_snippets`, `android.res_files`, `ios.plist_keys` ordering, and **`ui_components.ios.swift_struct`** — the field without which iOS registration is silently skipped |
| `:718-720` — validator *"checks … `view_module` / `composable` exist and parse"* | `Validator.referenced_paths/1` (`⟨MOBDEV⟩/lib/mob_dev/plugin/validator.ex:33-45`) explicitly excludes them: *"`view_module`/`composable` are type/function names, not paths"* |
| `:794` — *"Today: spec version 1"* | `@supported_spec_versions [1, 2]` (`⟨MOBDEV⟩/lib/mob_dev/plugin/manifest.ex:19`) |
| Nowhere | `lang: :cpp_archive`, NIF `platform: :ios \| :android`, `nm_symbol` — all implemented in `Merge.static_archives/2` and `nif_for_platform?/2` |
