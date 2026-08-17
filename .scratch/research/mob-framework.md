# Mob — BEAM-on-device mobile framework for Elixir

Research date: 2026-08-17. Docs version reviewed: **v0.7.20**.

Canonical docs host: <https://mob.hexdocs.pm/> (`https://hexdocs.pm/mob/*` 301-redirects here).
The docs index page is JS-rendered; concrete page URLs and the ExDoc sidebar
(`https://mob.hexdocs.pm/dist/sidebar_items-1E07B7BD.js`) were used to enumerate everything.

---

## 1. What Mob is — architecture

**One-line:** OTP/BEAM is embedded *inside* the APK / `.app` bundle; Elixir screens are
GenServers whose `render/1` output is serialized and rendered by **Jetpack Compose**
(Android) and **SwiftUI** (iOS) through a thin NIF.
(<https://mob.hexdocs.pm/readme.html>, <https://mob.hexdocs.pm/architecture.html>)

**Fully on-device, not server-driven.** The architecture guide states flatly *"There is no
server"* — your Elixir app runs locally in the same BEAM node the user installs.
(<https://mob.hexdocs.pm/architecture.html>)

### Render pipeline

Per <https://mob.hexdocs.pm/architecture.html>:

1. Your Elixir app (GenServers, supervision tree, business logic).
2. `Mob.Screen` — a GenServer **you** implement; owns screen logic + nav state.
3. `render/1` returns a **plain Elixir map** representing the component tree.
4. `Mob.Renderer` serializes that map to **JSON** and passes it over **NIF** calls.
5. Compose (Android) / SwiftUI (iOS) receive the JSON and **diff** it, rendering native widgets.
6. UI events return as NIF callbacks → messages to the screen GenServer.

Summarized by the docs as *"The BEAM owns state; the native UI is a thin view."* The
rendering model is explicitly **"Elixir maps → JSON → native diff, not a custom canvas"**
(<https://github.com/GenericJam/mob>).

### Process tree → widget mapping

- A **screen** = one GenServer (`Mob.Screen`), started under OTP supervision; crashed
  screens are restarted by the supervisor.
  (<https://mob.hexdocs.pm/screen_lifecycle.html>, <https://mob.hexdocs.pm/Mob.Screen.html>)
- A **stateful component** = its own process (`Mob.ComponentServer`) paired with a
  named native view. *"A component is a stateful Elixir process paired with a
  platform-native view registered by name on iOS/Android."*
  (<https://mob.hexdocs.pm/Mob.Component.html>)
- **Composites** (`Mob.Composite`) are *stateless* pure-Elixir macros/expanders — no process,
  no native code — that expand into built-in widget trees ("third expansion pass",
  fixpoint recursion with a depth guard of 20).
  (<https://mob.hexdocs.pm/Mob.Composite.html>)
- The widget-name → native-constructor mapping lives in `Mob.Registry`, keyed
  `{nif_module, function, extra_args}` per platform.
  (<https://mob.hexdocs.pm/Mob.Registry.html>)

### Dev-time distribution

Standard **Erlang distribution** is used rather than a bespoke debug protocol: `mix mob.connect`
tunnels EPMD and attaches your desktop IEx to the on-device node, so `Node.list()`, `nl/1`,
`:rpc.call`, `:sys.get_state`, `:observer` and tracing all work.
(<https://mob.hexdocs.pm/architecture.html>)

### Prior-art positioning (from the docs)

| Compared to | Mob's stated difference |
|---|---|
| **LiveView Native** | LVN runs Phoenix on a server pushing native trees over WebSocket to a thin client. Mob inverts it — BEAM is local: zero-latency, offline, self-contained. LVN suits "apps that are already Phoenix-centric". |
| **React Native** | *"bridge crossings are asynchronous and involve serialisation overhead"*; Mob stays in Elixir/OTP. |
| **Flutter** | Flutter renders via its own engine (Impeller/Skia); Mob *"renders native Compose and SwiftUI components"*. |
| **Elixir Desktop** | Same BEAM-on-device insight, but wxWidgets + WebView; Mob uses Compose/SwiftUI directly. |

Source: <https://mob.hexdocs.pm/architecture.html>

---

## 2. Current version and maturity

| Fact | Value | Source |
|---|---|---|
| Latest `mob` | **0.7.20**, released **2026-07-11** | <https://hex.pm/api/packages/mob> |
| First release | 0.1.0, 2026-04-05 | same |
| Total releases | **62** in ~3 months | same |
| Cadence | new patch roughly every 1–3 days; minor every ~4 weeks (0.5.0 Apr 25, 0.6.0 May 14, 0.7.0 Jun 12) | <https://hex.pm/api/packages/mob>, <https://mob.hexdocs.pm/changelog.html> |
| Licence | **MIT** | <https://hex.pm/api/packages/mob> |
| Maintainer | **genericjam** (single owner, `genericjam@gmail.com`); no other maintainers listed | <https://hex.pm/api/packages/mob> |
| Repo | <https://github.com/GenericJam/mob> — 181 stars, 22 forks, 444 commits on master | <https://github.com/GenericJam/mob> |
| Downloads | ~6,690 all-time, ~52/week | <https://hex.pm/api/packages/mob> |
| `mob_new` generator | **0.4.20**, 2026-07-07, MIT | <https://hex.pm/api/packages/mob_new> |

**Maturity verdict: pre-1.0, API-unstable, effectively a one-person project.**

- README and site both say **"Status: Early development."** and "not yet ready for
  production use." (<https://github.com/GenericJam/mob>, <https://mobframework.com/>)
- **v0.7.0 was a hard breaking change with no compat shims**: the "plugin-extraction
  major" moved Camera, Location, Notifications, Photos, Biometric, Scanner, Bluetooth and
  themes out of core into opt-in packages. Apps had to add deps and rewrite module
  references. v0.7.3 further removed `Mob.Background` from core.
  (<https://mob.hexdocs.pm/changelog.html>)
- The author on Elixir Forum: there's *"probably lots wrong"* and *"an awful lot of
  surface area that needs fleshed out."*
  (<https://elixirforum.com/t/mob-native-beam-elixir-on-native-mobile/74924>)
- Counterweight: at least one shipped app (**AirCartMax**) is claimed to be live in both
  the Apple App Store and Google Play. (same forum thread)
- Community coverage: Thinking Elixir #302 "BEAM in Your Pocket"
  (<https://podcast.thinkingelixir.com/302>); Elixir Montréal talk
  (<https://www.youtube.com/watch?v=G74tjFcs7E4>); plugin-system RFC
  (<https://elixirforum.com/t/proposed-plugin-system-for-mob-beam-mobile-framework/75420>).

---

## 3. Creating a project — exact commands

Source: <https://mob.hexdocs.pm/getting_started.html> and <https://mob-new.hexdocs.pm/Mix.Tasks.Mob.New.html>

### Install the generator archive

```bash
mix local.hex
mix archive.install hex mob_new
```

### Scaffold

```bash
# both platforms
mix mob.new my_app
cd my_app
mix mob.install

# iOS only  (skips ~400 MB of Android downloads)
mix mob.new my_app --ios

# Android only
mix mob.new my_app --android
```

Then verify the toolchain:

```bash
mix mob.doctor
```

### Full `mix mob.new` signature

```
mix mob.new APP_NAME [--liveview] [--python] [--blank] [--ios | --android] [--no-install] [--dest DIR] [--local]
```

| Flag | Meaning |
|---|---|
| `--ios` / `--no-android` | iOS boilerplate only |
| `--android` / `--no-ios` | Android boilerplate only |
| `--liveview` | generate a Phoenix LiveView app wrapped in a Mob WebView |
| `--python` | pre-configure embedded CPython via Pythonx (**iOS only**) |
| `--blank` | minimal native app, no demo screens |
| `--no-install` | skip `mix deps.get` |
| `--dest DIR` | target directory |
| `--local` | use local mob/mob_dev repos (framework contributors only) |

Adding Mob to an **existing** Phoenix/Elixir project uses `mix mob.adopt` (and its
sub-tasks `mob.adopt.deps`, `mob.adopt.native`, `mob.adopt.mob_exs`, `mob.adopt.screen`,
`mob.adopt.bridge`, `mob.adopt.finalize`). (<https://mob-dev.hexdocs.pm/api-reference.html>)

### Generated structure (native mode)

```
my_app/
  mix.exs
  mob.exs                       # Mob build/runtime config (plugins, epmd_port, signing keys…)
  lib/my_app/
    app.ex                      # use Mob.App — navigation/1 + on_start/0
    home_screen.ex              # use Mob.Screen
  android/
    settings.gradle, build.gradle, gradle.properties, local.properties
    app/src/main/AndroidManifest.xml
    app/src/main/java/com/mob/my_app/
      MainActivity.kt, MobBridge.kt, MobNode.kt, MobScannerActivity.kt
  ios/
    beam_main.m, Info.plist
```

`--liveview` mode adds the full Phoenix tree plus `lib/my_app/mob_screen.ex`.

Add to `mix.exs`: `{:mob, "~> 0.7"}`.

### Toolchain prerequisites

Source: <https://mob.hexdocs.pm/getting_started.html>

**Common**
- Elixir **1.19+** with Hex. *(Note: <https://mob.hexdocs.pm/troubleshooting.html> says
  "Elixir 1.18 or later" — the two pages disagree; treat 1.19 as the safe floor.)*
  Hex must be ≥ 2.0 or dependency resolution silently misbehaves.
- `mob_new` archive.

**iOS**
- macOS + **Xcode 15+** (`xcode-select --install`).
- Physical device: Apple ID signed into Xcode; **Apple Developer Program ($99/yr)** for
  App Store / TestFlight distribution.

**Android**
- **Java 17–21** (`brew install --cask temurin`).
- **Android Studio** (supplies SDK, NDK and `adb`).

**Erlang/OTP cross-compilation** is handled *for you* — Mob downloads pre-built OTP/erts
tarballs per platform/arch (`mix mob.install`, cached). `mix mob.release.otp` and
`mix mob.release.openssl` exist to cross-compile OTP and OpenSSL yourself if needed.
(<https://mob.hexdocs.pm/support_matrix.html>, <https://mob-dev.hexdocs.pm/api-reference.html>)
For physical iOS, OTP must be built for `arm64-apple-ios` with `--disable-jit` (iOS enforces
W^X) and `--disable-esock`, and the whole OTP tree rsync'd into `.app/otp/` because `/tmp` is
sandboxed. (<https://mob.hexdocs.pm/ios_physical_device.html>)

### Running

```bash
# iOS simulator
xcrun simctl boot "iPhone 16 Pro" && open -a Simulator
mix mob.deploy --native --ios      # first time (builds native shell)
mix mob.deploy --ios               # subsequent, fast

# Android emulator (start AVD from Android Studio first)
mix mob.deploy --native --android
mix mob.deploy --android

# physical iPhone: Developer Mode ON, then
mix mob.provision
mix mob.deploy --native --ios

# physical Android: USB debugging ON, `adb devices`, then
mix mob.deploy --native --android
```

**There is no default platform — `--ios` or `--android` is always required.**
(<https://mob.hexdocs.pm/publishing.html>)

---

## 4. Platform support today — Android vs iOS

**Both platforms genuinely ship, and iOS is not a second-class stub.** iOS support has been
present throughout the documented changelog history; recent releases are explicitly
*parity* work (e.g. 0.7.19 fixed iOS accelerometer sign/unit conventions to match Android;
0.7.10 iOS baseline row alignment; 0.7.6 iOS canvas drag).
(<https://mob.hexdocs.pm/changelog.html>)

Confirmed working: iOS **simulator + physical device**, Android **emulator + physical
(non-rooted) device**. (<https://github.com/GenericJam/mob>,
<https://elixirforum.com/t/mob-native-beam-elixir-on-native-mobile/74924>)

### Minimums (<https://mob.hexdocs.pm/support_matrix.html>)

| | Android | iOS |
|---|---|---|
| Min OS | **API 28 / Android 9** | **iOS 13** |
| Archs | arm64-v8a, x86_64 (emulator), armeabi-v7a | arm64 (device + Apple-Silicon sim), x86_64 (Intel Mac sim) |
| Pythonx feature | arm64-v8a + x86_64 only (Chaquopy dropped 32-bit ARM); +~30 MB | arm64; iOS 13+ (BeeWare python-apple-support); +~70 MB |

Compatibility is validated at deploy time by `mix mob.deploy`, which names the upstream
vendor responsible for each constraint.

### Where the platforms actually diverge

From <https://mob.hexdocs.pm/mobile_surface_matrix.html> and
<https://mob.hexdocs.pm/troubleshooting.html>:

- **Video**: 🟡 — works on iOS via `AVPlayerViewController`; **Android is a stub pending
  ExoPlayer wiring**. (also <https://mob.hexdocs.pm/styling.html>)
- **Bluetooth Classic**: Android-only (plugin). BLE peripheral role: both.
- **USB host** (`Mob.VendorUsb`): **Android only**.
- **`mob_biometric`**: *"iOS fully functional; Android support pending"*
  (<https://mob.hexdocs.pm/packages.html>) — note this conflicts with the surface matrix,
  which lists biometric auth under "Missing (plugin exists)". Verify before relying on it.
- **`mlx`** feature (Apple MLX tensors): iOS only. **`--python`**: iOS only at generate time.
- **Background execution**: Android can genuinely run long via foreground service; iOS
  cannot (see §8).
- **DNS on physical iOS is broken by default** — the BEAM's `inet_gethost` helper is
  spawned via `execve`, which the iOS sandbox forbids, so Req/Finch/Mint fail with
  `nxdomain`. Workaround: `Mob.DNS.configure_pure_beam/0` (switches lookup chain to
  `[:file, :dns]`, raw UDP/TCP via `gen_udp`) or `Mob.DNS.resolve/1` / `preresolve/1`
  (libc `getaddrinfo` in a NIF). Simulators and Android are unaffected.
  (<https://mob.hexdocs.pm/dns_on_ios.html>)
- **`Mob.Test.pop` / `pop_to_root` crashes the BEAM on iOS** — SwiftUI mutations from a
  distribution thread violate the main-thread requirement; only the push path is guarded.
  (<https://mob.hexdocs.pm/troubleshooting.html>)
- **Android defers `Node.start/2` by 3 s** to avoid a `pthread_mutex_lock on destroyed
  mutex` SIGABRT before the hwui thread pool exists. (same)
- iOS platform features **explicitly out of scope**: Live Activities, home-screen widgets,
  app clips, watch companion, share extensions. Android out of scope: home widgets, quick
  settings tiles. (<https://mob.hexdocs.pm/mobile_surface_matrix.html>)

**Honest read:** cross-platform is real and Android is *not* meaningfully ahead of iOS for
UI work. But the iOS *physical device* path carries genuine sharp edges (DNS, memory
supercarrier cap `-MIscs 10`, in-process EPMD, static-NIF registration in
`driver_tab_ios.c`, no `dlopen`) that the simulator hides. Budget time for it.

---

## 5. Widget / layout model

Sources: <https://mob.hexdocs.pm/components.html>, <https://mob.hexdocs.pm/styling.html>,
<https://mob.hexdocs.pm/Mob.UI.html>, <https://mob.hexdocs.pm/Mob.Sigil.html>

### Template syntax — the `~MOB` sigil

Compiled **at compile time** with NimbleParsec into a `Mob.Renderer`-compatible node map;
`{...}` expressions evaluate at runtime in the caller's scope. `@foo` rewrites to
`assigns.foo` when an `assigns` var is in scope. LiveView-style `:if` and `:for` directives
are supported (`:if` also filters a `:for` comprehension). Tags are validated against
`ios.txt` / `android.txt` whitelists; unknown tags still compile with a warning
(PascalCase → snake_case atom).

```elixir
~MOB(<Text text="Hello" text_size={:xl} text_color={:primary} />)

~MOB"""
<Column padding={16} gap={8}>
  <Text text="New" :if={@count > 0} />
  <Row :for={user <- @users}><Text text={user.name} /></Row>
</Column>
"""
```

### Layout primitives

| Tag | Props |
|---|---|
| `Column` | `padding` (+ `_top/_bottom/_left/_right`), `gap`, `background`, `fill_width`, `fill_height`, `align` (`:start`/`:center`/`:end`) |
| `Row` | as Column, plus child `weight` (float, flex-like distribution) |
| `Box` | single-child styling container: `padding`, `background`, `corner_radius`, `fill_width` |
| `Spacer` | `size` (number); **omit `size` to fill available space** |

**Sizing/fill semantics:** `fill_width` maps to `.frame(maxWidth: .infinity)` on SwiftUI and
`Modifier.fillMaxWidth()` on Compose. It defaults to **`true` for Button**, `false` for most
others. Fixed `width`/`height` are in points (iOS) / dp (Android). `content_mode` is
`"fit"` (preserve aspect) or `"fill"` (crop).

**Wrapping: there is no flow/wrap primitive documented.** Row distributes via `weight`;
nothing indicates children reflow to a second line. Plan on explicit chunking.

### Scrolling and lists

- `Scroll` — vertically scrolling container (`padding`, `background`).
- `List` — platform-native scrolling, recommended for ~20+ items; `items`, `on_select`.
- `LazyList` — **virtualized** with pagination via `on_end_reached`.
- Scroll events come in three tiers (<https://mob.hexdocs.pm/events.html>): raw deltas
  (throttle default **33 ms ≈ 30 Hz**, plus `debounce:`, `delta:`, `leading/trailing`);
  semantic (`began`/`ended`/`settled`/`top_reached`/`end_reached`, `on_scrolled_past`);
  and **tier-3 native-only** effects (parallax, sticky headers, fades) computed at display
  refresh with *"zero BEAM involvement during the scroll"*.
- **Pull-to-refresh is listed as ❌ missing** as a component; the docs suggest emulating it
  with `on_top_reached`.

### Content / input widgets

`Text`, `Button`, `TextField`, `Image`, `Toggle`, `Slider`, `Divider`, `Progress`,
`TabBar`, `WebView`, `CameraPreview`, `GpuView`, `NativeView`, `Canvas`, `Video` (🟡).

- **Text**: `text` (required), `text_size` (number or token), `text_color`, `font_weight`
  (`thin`/`light`/`regular`/`medium`/`semibold`/`bold`), `text_align`. Letter spacing and
  line height supported; Mob converts line-height multipliers for SwiftUI via
  `(multiplier - 1.0) × font_size` because `.lineSpacing` adds *extra* space, not total.
- **Button**: `text`, `on_tap` (`{pid, tag}`), `background`, `text_color`, `text_size`,
  `font_weight`, `padding`, `corner_radius`, `fill_width`, `weight`, `disabled`.
  Defaults injected: `background: :primary`, `fill_width: true`.
- **TextField**: controlled — `value`, `placeholder`, `secure`, `on_change`/`on_submit`/
  `on_focus`/`on_blur`, `keyboard_type` (`:default`/`:email`/`:number`/`:decimal`/`:phone`/
  `:url`), return-key actions (done/next/go/search/send), colors, `corner_radius`.
  Defaults `background: :surface_raised`.
- **Toggle** → `{:change, tag, bool}`; **Slider** (`min`/`max`, default 0.0–1.0) →
  `{:change, tag, float}`.
- **Image**: uses `AsyncImage` on **both** platforms; accepts URL or local path;
  placeholder colour while loading; corner radius applied after sizing.
- **Custom fonts**: drop `.ttf`/`.otf` into `priv/fonts/`; Mob resolves PostScript names
  (iOS) vs normalized filenames (Android) uniformly.
- **Per-platform prop overrides**: nest `:ios` / `:android` keys inside a props map
  (docs recommend using sparingly).

### Missing components (docs' own ❌ list)

Date / time / colour pickers, SearchBar, **modal sheets**, pull-to-refresh, Maps
(entirely absent, flagged as a plugin candidate).
(<https://mob.hexdocs.pm/mobile_surface_matrix.html>)

### Theming

Sources: <https://mob.hexdocs.pm/theming.html>, <https://mob.hexdocs.pm/Mob.Theme.html>

Design-token system with three token families:
- **Semantic colours** — `:primary` (→ `:blue_500`), `:background` (→ `:gray_900`),
  `:surface`, `:surface_raised`, `:border`, `:error` (→ `:red_500`)…
- **Spacing** — `:space_xs`/`sm`/`md` (16 px)/`lg`/`xl` (32 px), scaled by `space_scale`.
- **Typography** — `:xs` (12 sp) … `:6xl` (60 sp), scaled by `type_scale`.
- **Radius** — `:radius_sm`/`:radius_md` (10)/`:radius_lg`/`:radius_pill` (100).

Colour resolution precedence: semantic token → palette atom (`:blue_500`) → raw
**`0xAARRGGBB`** integer (alpha-first; remember `0xFF`) → unknown atoms are no-ops.

Built-ins: `Mob.Theme.Light`, `Mob.Theme.Dark`, `Mob.Theme.Adaptive` (+
`Mob.Theme.AdaptiveWatcher` reacting to OS appearance changes). Set at startup with
`use Mob.App, theme: Mob.Theme.Dark` or at runtime with `Mob.Theme.set/1` (takes effect on
next render). Custom themes export `theme/0` returning a `%Mob.Theme{}`. Presets ship in
`mob_themes` (Obsidian, ObsidianGlass, Citrus, Birch, Material3).
Named reusable styles: `Mob.Style`.

---

## 6. Navigation

Source: <https://mob.hexdocs.pm/navigation.html>, <https://mob.hexdocs.pm/Mob.App.html>,
<https://mob.hexdocs.pm/Mob.Socket.html>

Declared in your `Mob.App` module's `navigation/1` callback, which receives the platform
atom (`:ios` / `:android`) so you can pattern-match platform-specific shells:

```elixir
defmodule MyApp do
  use Mob.App

  def navigation(_platform), do: stack(:home, root: MyApp.HomeScreen)

  def on_start do
    Mob.Screen.start_root(MyApp.HomeScreen)
    Mob.Dist.ensure_started(node: :"my_app@127.0.0.1", cookie: :secret)
  end
end
```

Three shells via helpers `stack/2` (`:root`, `:title`), `tab_bar/1`, `drawer/1`:

| Shell | Android | iOS |
|---|---|---|
| Stack | native stack | native stack |
| Tab bar | `NavigationBar` (bottom) | `UITabBarController` |
| Drawer | `ModalNavigationDrawer` | custom iOS implementation |

### API (all on `Mob.Socket`, all return a new socket)

- `push_screen(socket, dest, params)` — `dest` is a **module or a registered stack-name atom**
- `pop_screen(socket)`
- `pop_to(socket, dest)` — pop until `dest` is on top
- `pop_to_root(socket)`
- `reset_to(socket, screen, params)` — replace the whole stack (auth transitions)
- `switch_tab(socket, :tab_name)` — tab bar **or** drawer

Animations are chosen automatically: **push** = slide in from right (iOS) / slide up
(Android); **pop** = reverse; **reset** = cross-fade.
System back gesture is handled automatically unless overridden
(<https://mob.hexdocs.pm/screen_lifecycle.html>).

**Named routes:** `Mob.Nav.Registry` is an ETS-backed name→screen registry; named stacks
become valid `push_screen` destinations automatically, so screens need not import each
other's modules. Route-bound params can be registered.
(<https://mob.hexdocs.pm/Mob.Nav.Registry.html>)

**Returning data on pop:** because processes persist across navigation, the documented
pattern is to pass the parent's pid in params and message it before popping.

**`mix mob.routes`** validates screen navigation modules at build time.
(<https://mob-dev.hexdocs.pm/api-reference.html>)

### Modals and deep links — caveats

- **Modal sheets are listed as ❌ not implemented** as a component.
  Native `Mob.Alert` covers alert dialogs, action sheets and toasts.
  (<https://mob.hexdocs.pm/mobile_surface_matrix.html>, <https://mob.hexdocs.pm/Mob.Alert.html>)
- **Deep links: iOS universal links are "partially working"**; no dedicated deep-link
  guide exists. Notification payloads carry a `data: %{screen: "..."}` convention that you
  route manually in `handle_info`. (<https://mob.hexdocs.pm/mobile_surface_matrix.html>,
  <https://mob.hexdocs.pm/push_notifications.html>)

---

## 7. Native interop

Source: <https://mob.hexdocs.pm/native_extensions.html>, <https://mob.hexdocs.pm/Mob.Component.html>,
<https://mob.hexdocs.pm/plugins.html>, <https://mob.hexdocs.pm/Mob.Registry.html>

### Two mechanisms, deliberately split

> *"`add_nif` creates instances the user names… and can have many of. `enable` toggles
> singleton features… each exists at most once per app."*

**Custom NIFs**

```bash
mix mob.add_nif <name> [--type c | --type rustler | --type zigler] [--demo]
```

Default with no `--type` is an Elixir-only stub. Generates an Elixir stub in
`lib/<app>/nifs/`, native sources, and **auto-regenerates the iOS/Android dispatch
tables** (`mix mob.regen_driver_tab` regenerates them manually).

**Static linking is mandatory**, not a preference: *"iOS App Store rejects bundled
`.dylib`; Android `RTLD_LOCAL` hides the parent's `enif_*` symbols."* On physical iOS,
`dlopen` of `.so` files fails **silently** (log warning only, not a crash).

**Built-in features**

```bash
mix mob.enable <feature>
```

Available: `liveview`, `camera`, `photo_library`, `file_sharing`, `location`,
`notifications`, `pythonx` (embedded CPython 3.13, +~70 MB), `mlx` (Apple MLX tensors,
iOS only, +~30 MB).

### Exposing a native view as a Mob component

Implement the `Mob.Component` behaviour in Elixir:

```elixir
defmodule MyApp.ChartComponent do
  use Mob.Component

  def mount(props, socket), do: {:ok, Mob.Socket.assign(socket, :data, props[:data])}
  def render(assigns), do: %{data: assigns.data}
  def handle_event("segment_tapped", %{"index" => i}, socket),
    do: {:noreply, Mob.Socket.assign(socket, :selected, i)}
end
```

Callbacks: `mount/2` (required), `render/1` (required, returns a **props map** for the
native factory), `update/2`, `handle_event/3`, `handle_info/2`, `terminate/2`.
Lifecycle: parent declares `Mob.UI.native_view/2` → `Mob.ComponentServer` starts →
`mount/2` → `render/1` → native factory → parent updates call `update/2` → native events
call `handle_event/3` → state change re-runs `render/1` → `terminate/2` on removal.

Register the native factory at app startup. **Naming rule: strip the `Elixir.` prefix and
replace dots with underscores** (`MyApp.ChartComponent` → `"MyApp_ChartComponent"`).

```swift
// iOS
MobNativeViewRegistry.shared.register("MyApp_ChartComponent") { props, send in
    AnyView(ChartView(data: props["data"]) { index in
        send("segment_tapped", ["index": index])
    })
}
```

```kotlin
// Android
MobNativeViewRegistry.register("MyApp_ChartComponent") { props, send ->
    ChartView(data = props["data"]) { index -> send("segment_tapped", mapOf("index" to index)) }
}
```

Declare in a screen: `Mob.UI.native_view(MyApp.ChartComponent, id: :revenue_chart, data: @points)`.

Stateless components may omit `mount/2` and `handle_info/2`.

### Registering a widget name → NIF constructor

`Mob.Registry.register/3` takes a keyword list of `platform: {mod, fun, args}` entries;
third-party packages call it from `Application.start/2`. `lookup/3` and `all/1` round it out.

### Packaging as a plugin

Five cumulative tiers (<https://mob.hexdocs.pm/plugins.html>):

| Tier | Contains |
|---|---|
| 0 | pure Elixir helpers, no manifest, **hot-pushable** |
| 1 | + a NIF with Elixir wrapper (requires native rebuild) |
| 2 | + native UI components (SwiftUI / Compose views) |
| 3 | + full screens, Ecto migrations, assets |
| 4 | + lifecycle hooks, supervised workers, settings, notifications |

Scaffold: `mix mob.new_plugin my_widget --tier <n>`.
Sign: `mix mob.plugin.keygen` (Ed25519) → `mix mob.plugin.sign`; hosts opt in via
`mix mob.plugin.trust`. Activation is deliberately two steps: add to `deps` in `mix.exs`
**and** list under `:plugins` in `mob.exs` (+ `:trusted_plugins`).
Deploy tiers 1–4 with `mix mob.deploy --native`.
Conflicts on screen routes, NIF module names, UI component keys, migration namespaces,
worker names and notification matches are **build-time errors**, never silent overwrites.
Settings via `Mob.Plugins.get_setting/2` / `put_setting/3`.
Manifest and security references: <https://mob.hexdocs.pm/mob_plugins.html>,
<https://mob.hexdocs.pm/mob_plugin_security.html>, <https://mob.hexdocs.pm/mob_styles.html>.

### WebView JS bridge

`Mob.WebView` provides a bidirectional JS bridge (`window.mob.send(data)` /
`window.mob.onMessage(fn)`); `Mob.LiveView` swaps the same `window.mob` API to route over
the Phoenix WebSocket when `MobHook` mounts. The two bridges are mutually exclusive and
API-identical. (<https://mob.hexdocs.pm/liveview.html>)

---

## 8. Platform services

### Notifications — <https://mob.hexdocs.pm/push_notifications.html>

Plugin `mob_notify` (`{:mob_notify, "~> 0.1"}` + `config :mob, :plugins, [:mob_notify]`).

- **Local**: `MobNotify.schedule(socket, id: "id", title: "…", at: ~U[…])` or
  `delay_seconds: 3600`; `MobNotify.cancel(socket, id)`.
- **Push**: `MobNotify.register_push(socket)` → `{:push_token, platform, token}` in
  `handle_info`. Server side uses **`mob_push`** (`{:mob_push, "~> 0.2"}`,
  `mix mob_push.install`) speaking APNs and FCM:
  `MobPush.send(token, :ios, %{title:, body:, data: %{…}})`.
- **Unified receive**: `{:notification, notif}` arrives in `handle_info` in all three
  states — foreground (no system banner), background (tap foregrounds), killed (tap
  launches, delivered once BEAM boots).
- **Caveats**: Android 8+ requires notification channels created in `MainActivity.onCreate`
  or messages are **silently dropped**; APNs sandbox and production tokens are not
  interchangeable (`{:error, {:apns_error, "BadDeviceToken"}}`).
- **Missing**: notification actions, grouping, critical flags.
  (<https://mob.hexdocs.pm/mobile_surface_matrix.html>)

### Background work — <https://mob.hexdocs.pm/background_execution.html>

This is the single most important architectural constraint.

> *"iOS suspends normal apps shortly after they enter the background. When that happens,
> BEAM schedulers stop running with the rest of the process."*

The README repeats it: *"The BEAM runs on the device, but it does **not** keep running once
the app is backgrounded."* Timers, GenServers, sockets and distribution connections all stop.
iOS wake-ups only via sanctioned channels: notification interaction, silent push,
background fetch, `BGTaskScheduler`, location, Bluetooth, audio.

Android **can** run genuinely long via **foreground services** —
`MobBackground.keep_alive/0` maps to a foreground service on Android (audio session on
iOS) — but *"foreground services must show a persistent notification."*

Note `Mob.Background` was removed from core in v0.7.3 and is now plugin-provided.
**Missing entirely**: background fetch, scheduled jobs, background download/upload.
`Mob.Plugins.Lifecycle` dispatches foreground/background transitions.

### Storage / database — <https://mob.hexdocs.pm/data.html>

Two layers:

1. **`Mob.State`** — key-value on `:dets`. `Mob.State.put(:theme, :citrus)`,
   `get/2`, `delete/1`. Auto-started before `on_start/0`; writes call `:dets.sync/1` for
   crash safety. Capacity **O(dozens) of keys** — themes, onboarding flags, cached IDs.
2. **Ecto + SQLite** via `ecto_sqlite3`. Repo generated at `lib/my_app/repo.ex`, reads
   `MOB_DATA_DIR`, stored in `getFilesDir()` (Android) / `NSDocumentDirectory` (iOS).
   **`pool_size: 1`** (SQLite limitation). Millions of rows. SQLite caveats: limited
   `ALTER TABLE`, no array/JSONB indexes (use string + Jason or normalized tables),
   `:binary_id` UUIDs. On-device migrations via `Ecto.Migrator.with_repo/2` before Repo start.

Also: `Mob.ScreenState` persists screen assigns (`use Mob.Screen, persist: true, vsn: N`,
with `dump_state/1`, `load_state/2`, `screen_key/1` callbacks).

**Missing: keychain/keystore and encrypted storage.**
(<https://mob.hexdocs.pm/mobile_surface_matrix.html>)

### HTTP

No Mob-specific HTTP client — **use ordinary Elixir libraries** (Req/Finch/Mint) against
the real `:ssl`/`:public_key` and OpenSSL 3.x shipped in the runtime. The surface matrix
marks WebSocket/HTTP as "partial: use Elixir libraries directly."
**On physical iOS you must first call `Mob.DNS.configure_pure_beam/0`** or every request
fails `nxdomain` (§4).

### Files & filesystem — `Mob.Storage`

`dir/1`, `list/1`, `stat/1`, `write/2`, `read/1`, `copy/2`, `move/2`, `delete/1`,
`extension/1`; locations `:documents`, `:cache`, `:temp`, `:app_support`.
Platform specifics in `Mob.Storage.Android` (MediaStore) and `Mob.Storage.Apple` (media
library). `Mob.Files` is the system file picker (Files app / SAF).
(<https://mob.hexdocs.pm/device_capabilities.html>)

### Permissions — <https://mob.hexdocs.pm/permissions.html>

`Mob.Permissions.request(socket, :capability)` →
`handle_info({:permission, :capability, :granted | :denied}, socket)`.
Atoms: `:camera`, `:microphone`, `:photo_library`, `:location`, `:notifications`.
Haptics/clipboard/file-picking need none.

- iOS requires matching `NS*UsageDescription` keys in `Info.plist` — **without them the
  dialog is silently suppressed: no event, no error.** This is the docs' stated #1 gotcha.
- Android requires `uses-permission` entries: `CAMERA`, `RECORD_AUDIO`,
  `READ_MEDIA_IMAGES`/`READ_MEDIA_VIDEO` (API 33+), `ACCESS_FINE/COARSE_LOCATION`,
  `POST_NOTIFICATIONS` (API 33+).
- Once denied, `request/2` won't re-prompt; `:denied` still fires so you can deep-link to
  Settings (`open_settings/1`, added 0.7.8).

### Camera / media / sensors

- `mob_camera` → `MobCamera.capture_photo/…`, `capture_video/…`, `start_preview/2`,
  `stop_preview/1`, live `<CameraPreview>`, ML-ready frame streaming.
  Zoom/focus/exposure are **basic only**.
- `mob_photos` → `MobPhotos.pick/…` system picker (no runtime permission).
- `mob_location` → `MobLocation.get_once/…`, `start/…`, `stop/…`
  (CLLocationManager / FusedLocationProviderClient). **Background location on Android
  needs the foreground-service workaround; geofencing missing.**
- `mob_biometric` → `MobBiometric.authenticate/…` (Face/Touch ID, BiometricPrompt).
- `mob_scanner` → QR/barcode. `mob_bluetooth`, `mob_screencast` (on-device H264).
- Core: `Mob.Audio` (record/play, output probes, input-level metering as of 0.7.18),
  `Mob.Speech` (TTS; **speech recognition missing**), `Mob.Motion` (accel/gyro/magnetometer/
  compass), `Mob.Torch`, `Mob.Haptic`, `Mob.Clipboard`, `Mob.Share` (**text only — sharing
  files/images is missing**), `Mob.Alert`, `Mob.Device` (+ `.Android`/`.IOS`),
  `Mob.VendorUsb`, `Mob.Certs`, `Mob.Canvas`.
- ML: TensorFlow Lite inference ships; Nx-based inference is "exploratory".
  Vision framework, Foundation Models, face/pose detection and OCR are **missing**.

---

## 9. Testing and dev workflow

### Hot reload — <https://mob.hexdocs.pm/getting_started.html>

```bash
mix mob.push        # push changed .beam files, no restart (requires distribution)
mix mob.watch       # auto-compile + hot-push on save   (mix mob.watch_stop to end)
mix mob.connect     # live IEx attached to the on-device BEAM
# then, inside IEx:
nl(MyApp.Screen)    # hot-push a single module
```

Caveat: code loading only takes effect **on the next function call** — trigger an event or
navigate away and back. (<https://mob.hexdocs.pm/troubleshooting.html>)
`mix mob.server` launches a dev dashboard with per-device Deploy/Update buttons and
streaming device + Elixir log panels.

### Unit tests — `Mob.ScreenCase` (<https://mob.hexdocs.pm/Mob.ScreenCase.html>)

LiveView-test-shaped, but you query a **typed view tree**, not HTML strings.

```elixir
defmodule MyApp.CounterScreenTest do
  use Mob.ScreenCase

  test "increment updates state and view" do
    view = mount_screen(MyApp.CounterScreen)
    assert assigns(view).count == 0

    view = render_event(view, "increment")
    assert assigns(view).count == 1
    assert text(view) =~ "Count: 1"
    assert_renderable(view)
  end
end
```

API: `mount_screen/3`, `render_event/3`, `render_info/2`, `assigns/1`, `tree/1`,
`find/3`, `find_all/3`, `flatten/1`, `text/1`, `assert_renderable/2`.
Lower-level alternative: `Mob.Screen.start_link/2` runs in **`:no_render` mode** — all
Elixir callbacks run, NIF calls are skipped — with `get_socket/1`, `dispatch/3`,
`get_current_module/1`, `get_nav_history/1`. For `handle_info` tests, send the message and
use `:sys.get_state(pid)` as a sync point.

**Three tiers** (docs' own framing): tier 1 = logic/state/view-tree shape (fast,
deterministic); tier 2 = `assert_renderable/2` node-type contract check; tier 3 = real
device via `Mob.Test`.

`Mob.Test` (over `mix mob.connect`) does live inspection (screen module, assigns, UI tree,
element finding), interaction (tap, navigate/pop/reset, list select) and **device
simulation** (mock results for permissions, camera, location, notifications, biometrics,
audio, WebView events). Navigation fns are synchronous; taps are fire-and-forget.
Tag device tests `@tag :integration` and run CI with `mix test --exclude integration`.
(<https://mob.hexdocs.pm/testing.html>)

### Formatting / lint — <https://mob.hexdocs.pm/tooling.html>

```elixir
# .formatter.exs
[plugins: [Mob.Formatter], inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"]]
```

`mix format` formats `~MOB` sigils (children indented 2 spaces, attributes wrap at
`line_length`, default **98**). `mix format --check-formatted` in CI. A tailored
`.credo.exs` ships; `mix credo --strict`. `mix erlfmt [--check]` for `.erl`.

### Release builds — <https://mob.hexdocs.pm/publishing.html>

```bash
mix mob.release              # → _build/mob_release/<App>.ipa (and Android artifact)
mix mob.publish --ios        # upload via xcrun altool to App Store Connect
mix mob.republish --ios      # bump CFBundleVersion + build + upload, one shot
```

iOS one-time setup: register App ID at developer.apple.com; Apple Distribution certificate
in Xcode; App Store provisioning profile; install `.mobileprovision`;
`mix mob.provision --distribution`; App Store Connect app record; App Store Connect API key
(`.p8`, **downloadable once**) configured in `mob.exs`.
Android: `mix mob.setup.google_play` configures Play authentication.
Icons: `mix mob.icon`.

Publishing caveats the docs call out: bundle ID **can't be `com.example.*`**; build numbers
must strictly increment; "upload accepted" ≠ in TestFlight (Apple's secondary validation
takes ~20 min); **`--ios`/`--android` is always required, there's no default**; re-run
provisioning annually when the profile expires.

### Other notable tooling

`mix mob.doctor`, `mix mob.devices`, `mix mob.emulators`, `mix mob.uninstall`,
`mix mob.cache`, `mix mob.routes`, `mix mob.plugins`, `mix mob.styles`,
`mix mob.security_scan` (+ `.log`), `mix mob.audit_otp`, `mix mob.audit_plugins`,
`mix mob.trace_otp`, `mix mob.snapshot_loaded`, `mix mob.verify_strip`,
`mix mob.battery_bench_android` / `_ios`, `mix mob.gen.live_screen`,
`mix mob.onboarding_test`. Full list: <https://mob-dev.hexdocs.pm/api-reference.html>

---

## 10. Known gaps and caveats the docs themselves admit

From <https://mob.hexdocs.pm/troubleshooting.html> unless noted.

**Runtime / architecture**
1. **BEAM does not run while backgrounded** (iOS suspends within seconds). No persistent
   socket-to-server pattern; you must use push. (<https://mob.hexdocs.pm/background_execution.html>)
2. **DNS is broken on physical iOS by default** — `execve` of `inet_gethost` is sandboxed
   away. (<https://mob.hexdocs.pm/dns_on_ios.html>)
3. **iOS memory**: default 1 GB supercarrier reservation is rejected and the process is
   *silently killed*; must pass `-MIscs 10`. (<https://mob.hexdocs.pm/ios_physical_device.html>)
4. **No `dlopen` on physical iOS** — `.so` NIF failures are log warnings, not crashes, so
   they fail obscurely. All NIFs must be static and registered in `driver_tab_ios.c`.

**Tooling collisions**
5. **EPMD port 4369 collides with `adb`.** Workaround: `epmd_port: 4380` in `mob.exs`,
   passed to `Mob.Dist.ensure_started/1`. The docs note the collision "is coincidental" —
   EPMD predates Android by 15 years.
6. **An attached Android device breaks iOS-simulator distribution**: `adb forward tcp:9100`
   grabs the port the simulator needs → silent BEAM death with `eaddrinuse`. Workaround
   `--dist-port 9200`.
7. **`:rpc.call/4` returns `{:badrpc, :nodedown}`** even when EPMD shows the node, if dist
   port 9101 is firewalled or occupied.
8. **`Mob.Test.pop` / `pop_to_root` crashes the BEAM on iOS** (SwiftUI main-thread
   violation; push path guarded, pop path not).
9. **Android `Node.start/2` deferred 3 s by default** to dodge a SIGABRT; you must tune it
   manually if you need distribution earlier.
10. **OTP cache extraction silently half-fails** ("No erts-* directory found") — an empty
    cache dir makes later runs skip the re-download. Common on Nix-managed macOS with SSL
    cert issues.
11. **Hot-push looks successful but doesn't apply** until the next function call.
12. **Path-dependency builds go stale** → `undef` on `mob_nif` functions; needs
    `mix deps.compile mob --force`.

**Product gaps**
13. **Canvas coordinate scaling is wrong on high-density devices.** Root cause is
    structural: *"The framework ships no host-app Kotlin/Swift code, so each app's
    `MobBridge` copy can drift."* You fix it in your own app's renderer. This means
    generated native shells are **forked at generation time and do not receive framework
    updates**.
14. **No OTA update mechanism.** *"For OTA updates, the recommended pattern is on-demand
    polling via HTTP, but this requires custom code — Mob provides no built-in mechanism."*
    Distribution in production also requires custom gating you write yourself.
15. **Accessibility is partial**: some labels, no uniform coverage, no focus management,
    no reduce-motion, no screen-reader announcements.
    (<https://mob.hexdocs.pm/mobile_surface_matrix.html>)
16. Missing surfaces: date/time/colour pickers, SearchBar, modal sheets, pull-to-refresh,
    **Maps entirely**, keychain/encrypted storage, NFC, WiFi scanning, mDNS, background
    fetch/scheduled jobs, in-app purchase, Apple Pay, Sign-In variants, calendar/contacts,
    share files/images, keyboard events, pinch/rotate on some paths, drag-and-drop,
    barometer/proximity/ambient-light/pedometer. (same)
17. **Docs drift is acknowledged**: the agentic-coding guide states these docs "go stale
    fast" and treats updating `AGENTS.md` as a contractual obligation.
    (<https://mob.hexdocs.pm/agentic_coding.html>)
18. **Internal inconsistency spotted during this research**: `packages.html` says
    `mob_biometric` is "iOS fully functional; Android support pending", while
    `mobile_surface_matrix.html` lists biometric auth under Missing. Also
    `getting_started.html` requires Elixir 1.19+ but `troubleshooting.html` says 1.18+.

**Performance data** (<https://mob.hexdocs.pm/why_beam.html>) — background, screen off:
iOS ~2 %/hr or less (one 60-min run showed zero measurable drain); Android 32-bit Moto E
~54–56 mAh/hr (~2–4 %/hr); Android 64-bit Moto G one run ~143 mAh/hr, another ~0, against a
~200 mAh/hr no-BEAM baseline. Boot time ~0.5 s and ~25 MB per-device binary are claimed on
the repo/forum, not in the guides.
(<https://github.com/GenericJam/mob>, <https://elixirforum.com/t/mob-native-beam-elixir-on-native-mobile/74924>)

---

## Complete documentation inventory

Enumerated from the ExDoc sidebar: `https://mob.hexdocs.pm/dist/sidebar_items-1E07B7BD.js`

### Guides / extras (34) — all at `https://mob.hexdocs.pm/<id>.html`

`api-reference` · `readme` · `changelog`

**Guides:** `why_beam` (Why the BEAM?) · `getting_started` · `packages` (First-Party
Packages) · `architecture` (Architecture & Prior Art) · `screen_lifecycle` · `events` ·
`event_model` · `background_execution` · `components` · `styling` (Styling & Native
Rendering) · `theming` · `navigation` · `device_capabilities` · `mobile_surface_matrix` ·
`permissions` · `native_extensions` (NIFs, features) · `plugins` (Writing a Plugin) ·
`dns_on_ios` · `push_notifications` · `data` (Data & Persistence) · `testing` · `tooling`
(Tooling & Formatting) · `publishing` (App Store / TestFlight) · `troubleshooting` ·
`support_matrix` (Device Support Matrix) · `liveview` (LiveView Mode) ·
`ios_physical_device` · `agentic_coding`

**Plugins:** `mob_plugins` (Manifest Reference) · `mob_plugin_security` (Security & Trust) ·
`mob_styles` (Styles — Manifest Reference)

### Modules (59) — all at `https://mob.hexdocs.pm/<Module>.html`

**Core:** `Mob` · `Mob.App` · `Mob.Screen` · `Mob.ScreenState` · `Mob.Socket` · `Mob.State`

**UI:** `Mob.Composite` · `Mob.Renderer` · `Mob.Style` · `Mob.Theme` · `Mob.Theme.Adaptive` ·
`Mob.Theme.Dark` · `Mob.Theme.Light` · `Mob.UI`

**Navigation:** `Mob.Nav.Registry`

**Plugins:** `Mob.Plugins` · `Mob.Plugins.Lifecycle` · `Mob.Plugins.Supervisor`

**Device APIs:** `Mob.Audio` · `Mob.Clipboard` · `Mob.Files` · `Mob.Haptic` · `Mob.Motion` ·
`Mob.Permissions` · `Mob.Share`

**Testing & Debugging:** `Mob.Test`

**Tooling:** `Mob.Formatter`

**Internals:** `Mob.Dist` · `Mob.List` · `Mob.NativeLogger` · `Mob.Sigil`

**Ungrouped:** `Mob.Alert` · `Mob.Canvas` · `Mob.Certs` · `Mob.Component` · `Mob.DNS` ·
`Mob.Device` · `Mob.Device.Android` · `Mob.Device.IOS` · `Mob.Diag` · `Mob.Event` ·
`Mob.Event.Address` · `Mob.Event.Bridge` · `Mob.Event.Component` · `Mob.Event.Target` ·
`Mob.Event.Throttle` · `Mob.Event.Trace` · `Mob.LiveView` · `Mob.Registry` ·
`Mob.ScreenCase` · `Mob.ScreenCase.View` · `Mob.Speech` · `Mob.Storage` ·
`Mob.Storage.Android` · `Mob.Storage.Apple` · `Mob.Theme.AdaptiveWatcher` · `Mob.Torch` ·
`Mob.VendorUsb` · `Mob.WebView`

### Mix tasks documented in `mob` itself (2)

`mix erlfmt` (<https://mob.hexdocs.pm/Mix.Tasks.Erlfmt.html>) ·
`mix mob.onboarding_test` (<https://mob.hexdocs.pm/Mix.Tasks.Mob.OnboardingTest.html>)

### Companion packages

| Package | Docs | Purpose |
|---|---|---|
| `mob_new` | <https://mob-new.hexdocs.pm/> · <https://hex.pm/packages/mob_new> | project generator archive (v0.4.20) |
| `mob_dev` | <https://mob-dev.hexdocs.pm/> · <https://github.com/GenericJam/mob_dev> | all `mix mob.*` dev/build/release/plugin tooling |
| `mob_push` | <https://hex.pm/packages/mob_push> | **server-side** APNs/FCM sender |
| `mob_themes` | <https://hex.pm/packages/mob_themes> | Obsidian, ObsidianGlass, Citrus, Birch, Material3 |
| `mob_camera` | <https://hex.pm/packages/mob_camera> | photo/video capture, preview, frame streaming |
| `mob_photos` | <https://hex.pm/packages/mob_photos> | system photo/video picker (no runtime permission) |
| `mob_location` | <https://hex.pm/packages/mob_location> | GPS/network, one-shot + continuous |
| `mob_notify` | <https://hex.pm/packages/mob_notify> | local scheduling + push registration |
| `mob_biometric` | <https://hex.pm/packages/mob_biometric> | Face/Touch ID, fingerprint (Android pending) |
| `mob_scanner` | <https://hex.pm/packages/mob_scanner> | QR/barcode full-screen scanner |
| `mob_bluetooth` | <https://hex.pm/packages/mob_bluetooth> | discovery + multiple protocols |
| `mob_screencast` | — | on-device H264 screen stream |
| `mob_ash` | — | generates list/detail/create screens from Ash resources |

### External sources

- Landing site: <https://mobframework.com/> (returned HTTP 403 to direct fetch; content
  reached via search index)
- GitHub: <https://github.com/GenericJam/mob> · <https://github.com/GenericJam/mob_dev> ·
  <https://github.com/genericjam/mob_new>
- Hex: <https://hex.pm/packages/mob> · <https://hex.pm/api/packages/mob>
- Elixir Forum announcement:
  <https://elixirforum.com/t/mob-native-beam-elixir-on-native-mobile/74924>
- Plugin-system RFC:
  <https://elixirforum.com/t/proposed-plugin-system-for-mob-beam-mobile-framework/75420>
- Thinking Elixir #302 "BEAM in Your Pocket": <https://podcast.thinkingelixir.com/302>
- Elixir Montréal talk: <https://www.youtube.com/watch?v=G74tjFcs7E4>

---
---

# Background, notifications, storage

Second research pass, 2026-08-17. **This section is grounded in the actual source**, not
only the guides. Repos cloned at:

| Repo | Commit | Date |
|---|---|---|
| `GenericJam/mob` | `26329fa` | 2026-07-11 |
| `GenericJam/mob_notify` | `d4fd658` | 2026-07-12 |
| `GenericJam/mob_new` | `19d2462` | 2026-07-07 |
| `GenericJam/mob_dev` | `3f03a63` | 2026-07-24 |

Where the guides and the source disagree, the source wins and I say so.

## VERDICT: does "notify me when a new episode airs" need a server?

**Yes — for a reliable product, it needs a server. But less of one than you'd think.**

Split the feature in two:

**(a) Firing the notification — fully device-capable, no server.** `MobNotify.schedule/2`
arms a *real OS-level* alarm. Android: `AlarmManager.setExactAndAllowWhileIdle(RTC_WAKEUP)`
→ a `BroadcastReceiver` that posts to `NotificationManager` with **zero BEAM involvement**.
iOS: a `UNTimeIntervalNotificationTrigger` handed to `UNUserNotificationCenter`, which the
OS owns. **Both fire while the app is force-quit / dead / the BEAM is not running.**
Verified in source, not just docs.

**(b) Knowing *when* to fire it — not device-capable on iOS.** To learn that S03E07 airs
Thursday, something must poll TMDB/Trakt/JustWatch. Polling needs execution.

- **iOS: Mob exposes no background execution whatsoever for this.** I grepped the entire
  iOS native source: **zero** occurrences of `BGTaskScheduler`, `BGAppRefreshTask`,
  `BGProcessingTask`, or `performFetchWithCompletionHandler`. The generated `AppDelegate.m`
  does **not** implement `didReceiveRemoteNotification:fetchCompletionHandler:`, so a
  **silent/data-only push cannot wake the BEAM at all**. The only wired iOS push path is
  *token registration*. An iOS Mob app can only refresh when the user opens it or taps a
  visible notification.
- **Android: genuinely possible but awkward.** A foreground service via
  `MobBackground.keep_alive/0` keeps the BEAM alive — but it must show a permanent
  notification forever, which is unacceptable UX for a movie tracker. There is **no
  WorkManager binding** (the guide says "WorkManager-style patterns" but ships no API).

### The practical architecture this forces

The cheapest correct design is a **thin server that owns schedule knowledge**, plus
device-local scheduling for precision:

1. Server polls TMDB/Trakt on a cron, holds each user's follow list, and computes air dates.
2. Server sends a **visible** push (APNs/FCM) via `mob_push` at air time → works on both
   platforms even when the app is dead. This alone delivers the headline feature.
3. **Optimisation:** on each app open, fetch the next N air dates and pre-arm them as
   *local* notifications with `MobNotify.schedule/2`. These fire with no network and no
   server at the moment of truth, and cover users who don't open the app often. Cancel and
   re-arm on the next open. This is a real, load-bearing use of Mob's local scheduling —
   it makes the server's push a *backstop* rather than the sole path.

A pure device-only build is viable **only** if you accept: notifications are computed at
app-open time from a batch fetch, and a user who doesn't open the app for three weeks gets
whatever was pre-armed three weeks ago (bounded by iOS's 64-pending-notification cap, see
below). For "a film I track got a release date" — an event you cannot predict in advance —
device-only cannot work at all without a server, because nothing polls.

---

## 1. Background execution, per platform

Guide: <https://mob.hexdocs.pm/background_execution.html> (source: `mob/guides/background_execution.md`, 86 lines).

### iOS

Verbatim from the guide:

> "iOS suspends normal apps shortly after they enter the background. When that happens,
> BEAM schedulers stop running with the rest of the process. Timers, GenServers, sockets,
> and distribution connections do not continue like they would on a server."

The guide lists the OS-sanctioned wake paths — "visible notification taps, silent pushes,
background fetch, `BGTaskScheduler`, location, Bluetooth, audio" — but **that is a
description of what iOS offers, not of what Mob implements**. Source check:

```
grep -rn "BGTaskScheduler|BGAppRefreshTask|BGProcessingTask|performFetchWithCompletionHandler" \
     mob/ios/ mob_new/priv/templates/mob.new/ios/     →  no matches
```

**Mob binds none of them.** The only background-related thing in the generated
`ios/Info.plist.eex` is:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

⚠️ **Every `mix mob.new` app ships `UIBackgroundModes: [audio]` by default**
(`mob_new/priv/templates/mob.new/ios/Info.plist.eex:33-36`). Apple rejects apps declaring
the audio background mode without a user-facing audio feature. **Remove this before
submitting a movie-tracker app**, or expect a review rejection.

**Duration:** the guide says wakeups "usually provide a short execution window rather than
an always-on process" and gives **no numbers**. The docs are silent on exact limits.

**State on return:** the docs are silent on whether iOS *suspension* preserves BEAM heap.
(In practice iOS suspension freezes the process, so a resume is warm; a *termination* is a
cold start. Mob's docs do not say this — treat it as unverified.) The guide's own advice is
to not rely on it: "Persist enough state locally with `Mob.State` or SQLite to resume after
suspension or cold start."

`MobBackground.keep_alive/0` on iOS works **only via the audio background mode** and the
guide warns: "Do not use this just to hide a server listener in the background; Apple
expects the declared background mode to match a user-visible app capability."

### Android

> "Android permits true long-running background work through a foreground service. Mob maps
> `MobBackground.keep_alive/0` to a foreground service on Android. Foreground services must
> show a persistent notification; Android intentionally makes always-running background
> work visible to the user."

Without one: "recent Android versions restrict background execution heavily. Use FCM for
server-initiated wakeups and **WorkManager-style patterns for deferred work**."
— note "WorkManager-style *patterns*". **There is no WorkManager binding in Mob.** No
occurrence of `WorkManager` in any native source or template; the word appears only in that
one sentence of guide prose.

`mob_background` is an **opt-in plugin** (`{:mob_background, "~> 0.1"}` +
`config :mob, :plugins, [:mob_background]`), removed from core in v0.7.3.

### The docs' own decision table (verbatim structure)

| Goal | Recommended path |
|---|---|
| Show or route a server event to a screen | Push notification via APNs / FCM |
| Refresh local state after a user taps a notification | Handle `{:notification, notif}` and fetch from your server |
| Run continuously while visible | Normal Mob screen / supervision tree |
| Run continuously in Android background | `MobBackground.keep_alive/0` foreground service |
| Run continuously in iOS background | Only for legitimate background modes such as audio, location, or Bluetooth |
| **Hold a hidden always-on iOS socket** | **"Not a supported mobile OS model"** |

---

## 2. Local notifications — YES, real OS-level scheduling

**Answer to the direct question: yes.** Elixir can schedule an OS-level local notification
at a future timestamp that the OS fires **while the app is dead**. This is not a
foreground-only postbox. Verified in native source on both platforms.

There is **no `mix mob.enable notifications`** for this path and **no `Mob.Notification`
module** — it is the **`mob_notify` plugin**, exposing module **`MobNotify`**.
(`Mob.Notify` existed in core before v0.7.0 and was extracted.)

```elixir
# mix.exs
{:mob_notify, "~> 0.1"}
# mob.exs
config :mob, :plugins, [:mob_notify]
```

### API — `mob_notify/lib/mob_notify.ex`

```elixir
MobNotify.schedule(socket,
  id:    "reminder_1",              # required, string; the cancel handle
  title: "Time to check in",        # required
  body:  "Open the app to see today's updates",  # required
  at:    ~U[2027-04-16 09:00:00Z],  # absolute UTC — or delay_seconds: 3600
  data:  %{screen: "reminders"}     # arbitrary map, returned on tap
)

MobNotify.cancel(socket, "reminder_1")   # no effect once already delivered
MobNotify.register_push(socket)
```

`schedule_opts/1` is exposed as a pure function so you can unit-test serialisation without
the NIF. `at:` is converted to a Unix timestamp; if absent it is `now + delay_seconds`.

### Android implementation — `mob_notify/priv/native/android/MobNotifyBridge.kt`

The chain, exactly:

1. `notify_schedule` → `MobNotifySchedules.schedule(ctx, id, triggerAtMs, title, body, data)`
2. `ensureChannel` creates channel `MobNotifyHub.CHANNEL_ID` = `"mob_notifications"`
   (API 26+, `IMPORTANCE_DEFAULT`).
3. `arm()` sets an `AlarmManager` alarm with **an exact-alarm guard and inexact fallback**:

```kotlin
val canExact = if (Build.VERSION.SDK_INT >= 31) am.canScheduleExactAlarms() else true
when {
  canExact && SDK_INT >= 23 -> am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMs, pi)
  canExact                  -> am.setExact(AlarmManager.RTC_WAKEUP, triggerAtMs, pi)
  SDK_INT >= 23             -> am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMs, pi)
  else                      -> am.set(AlarmManager.RTC_WAKEUP, triggerAtMs, pi)
}
```

⚠️ **On Android 12+ (API 31), exact alarms are special-access permission.** Without
`SCHEDULE_EXACT_ALARM` granted, you silently fall back to an **inexact, battery-batched**
alarm. For "your show starts now" that can drift by many minutes. The plugin declares the
permission, but the user grants it through a separate Settings screen.

4. The `PendingIntent` targets **`<applicationId>.NotificationReceiver`** by
   `setClassName`, keyed `id.hashCode()`.
5. That receiver lives in the **host app**, generated at
   `mob_new/priv/templates/mob.new/android/app/src/main/java/MobBridge.kt.eex:3602`. It
   builds a `NotificationCompat` notification and calls `nm.notify(...)` — **entirely
   without the BEAM**. Comment in source: the tap payload is "delivered now if running,
   else on next boot."

6. **Boot re-arm.** From the source header: "AlarmManager alarms are wiped on reboot, so
   scheduled notifications silently vanish." `notify_schedule` persists every schedule to
   `SharedPreferences` (`mob_notify_schedules`, one JSON array), and
   `MobNotifyBootReceiver` re-arms every still-future entry on `ACTION_BOOT_COMPLETED`.

**Android manifest requirements** (`mob_notify/priv/mob_plugin.exs`):
`POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, `RECEIVE_BOOT_COMPLETED`;
gradle dep `com.google.firebase:firebase-messaging:24.0.0`.

### iOS implementation — `mob_notify/priv/native/ios/mob_notify_nif.m`

```objc
NSTimeInterval delay = [opts[@"trigger_at"] doubleValue] - [[NSDate date] timeIntervalSince1970];
if (delay < 1) delay = 1;
UNTimeIntervalNotificationTrigger *trigger =
    [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:delay repeats:NO];
```

Content gets `title`, `body`, `userInfo = data`, `sound = default`. Handed to
`UNUserNotificationCenter`. **The OS owns it from that moment — it fires with the app
dead.** `notify_cancel` calls `removePendingNotificationRequestsWithIdentifiers:`.

⚠️ Three iOS caveats, **all of which the Mob docs are silent on**:

- It uses **`UNTimeIntervalNotificationTrigger`, not `UNCalendarNotificationTrigger`.** The
  delay is computed *once, at schedule time*, from the device's current clock. Cross a
  timezone or change the clock and the fire time drifts off wall-clock. For "9pm Thursday
  local" this is the wrong trigger type. You would need a native extension to fix it.
- iOS enforces a **64 pending local notification limit per app**, silently dropping the
  rest. This is an OS constraint, not a Mob one, and Mob's docs never mention it. It hard-
  caps the "pre-arm everything on app open" strategy.
- `repeats: NO` always — **no recurring notifications**.

### Permissions

`Mob.Permissions.request(socket, :notifications)` → `handle_info({:permission,
:notifications, :granted | :denied}, socket)`. The `mob_notify` README warns: **"An
unauthorized iOS app drops scheduled notifications silently — request `:notifications`
before scheduling."** No `Info.plist` key needed. Android 13+ needs `POST_NOTIFICATIONS`
(declared by the plugin manifest).

### Channels

Exactly **one** channel, hardcoded: `MobNotifyHub.CHANNEL_ID = "mob_notifications"`,
`IMPORTANCE_DEFAULT`. **No API to create additional channels** for "new episodes" vs
"streaming arrivals" vs "release dates" — you would need to patch the host `MobBridge.kt`.

### Actions

**None.** No `UNNotificationAction` / `UNNotificationCategory` registration anywhere in the
iOS NIF; no `addAction` in the Android receiver. Confirmed by the surface matrix's
"Missing: notification actions/grouping, critical flags"
(<https://mob.hexdocs.pm/mobile_surface_matrix.html>). No "Mark watched" button on the
notification.

### Deep-linking on tap

Yes, by convention rather than framework routing. The `data:` map round-trips, and you
route manually:

```elixir
def handle_info({:notification, %{id: id, data: data, source: :local}}, socket) do
  case data["screen"] do
    "chat" -> {:noreply, Mob.Socket.push_screen(socket, ChatScreen)}
    _      -> {:noreply, socket}
  end
end
```

Android: tap → `PendingIntent.getActivity` → `MainActivity` (`SINGLE_TOP`) carrying
`mob_notification_json` → `onCreate`/`onNewIntent` forward it to the BEAM. Cold start is
handled: core exposes `take_launch_notification` (`mob/ios/mob_nif.m:2394`) consumed by
`Mob.Screen`, so a tap that launches the app from dead still delivers.

⚠️ **iOS `source:` is always `:local`.** `mob/ios/mob_nif.m:3371,3379` hardcodes
`source:@"local"` in *both* delegate paths (`willPresentNotification` and
`didReceiveNotificationResponse`). There is **no** `source:@"push"` anywhere in the iOS
source. So the documented `source: :push` discriminator **does not work on iOS** — do not
pattern-match on it cross-platform.

---

## 3. Push notifications

Guide: <https://mob.hexdocs.pm/push_notifications.html>. Device half = `mob_notify`;
server half = **`mob_push`** (separate package, "runs on your server (APNs HTTP/2 + FCM v1)
with zero device/NIF code"). Wire contract pinned by shared fixtures
(`test/fixtures/push_contract.exs`, vendored identically in both repos).

**Token registration**

```elixir
MobNotify.register_push(socket)                  # after :notifications granted
def handle_info({:push_token, :ios,     token}, socket), do: ...
def handle_info({:push_token, :android, token}, socket), do: ...
```

iOS: `registerForRemoteNotifications` → AppDelegate
`didRegisterForRemoteNotificationsWithDeviceToken` → `mob_send_push_token(hex)`
(`mob_new/.../ios/AppDelegate.m.eex:67-74`).
Android: `FirebaseMessaging.getInstance().token`, with a `MobNotifyHub.pendingToken` drain
for refreshes that arrived before any screen registered.

**Server send**

```elixir
MobPush.send(token, :ios, %{title: "New episode", body: "S03E07 is out",
                            data: %{screen: "show", id: "1399"}})
```

Platform extras: iOS `subtitle`/`badge`/`sound`; Android `android` map with icon, color,
`channel_id`, priority.

**Waking the BEAM on receipt — the critical detail**

| State | Android | iOS |
|---|---|---|
| Foreground | delivered to `handle_info`, no tray banner | delivered to `handle_info` |
| Background | OS shows tray notification; **tap** foregrounds + delivers | same |
| Killed | OS shows notification; **tap** launches, delivers once BEAM boots | same |

**A push does not run Elixir code by itself.** On both platforms the BEAM only sees the
notification when the app is already foreground or the **user taps**. There is no
background-delivery path that runs your Elixir handler silently.

**Data-only / silent push: not supported on iOS.** No
`didReceiveRemoteNotification:fetchCompletionHandler:` in the AppDelegate template, no
`content-available` handling anywhere in the iOS source. On Android, `MobFirebaseService`
*would* be the hook — but see the gap below.

⚠️ **Documented-vs-actual gap.** `mob_notify`'s `host_requirements` assert that
"**mob_new-generated apps already satisfy all of them via their templates**". **Three of the
five do not hold** against `mob_new` @ `19d2462`:

- ✅ `.NotificationReceiver` — declared in `AndroidManifest.xml.eex:84`, class at
  `MobBridge.kt.eex:3602`.
- ❌ **`MobFirebaseService.kt` does not exist** in `mob_new/priv/templates/` (searched all
  repos: the string appears only in two comments in `mob_dev/lib/mob_dev/native_build.ex`).
- ❌ **The FCM `<service>` is not declared** in the generated `AndroidManifest.xml.eex`.
- ❌ **The `MobNotifyBootReceiver` `<receiver>` is not declared** either — so **boot re-arm
  silently does not work** in a stock generated app, and every scheduled notification is
  lost on device reboot.
- ❓ google-services plugin + `google-services.json` are host-level by design; you must add
  them regardless.

**Consequence:** push on Android requires you to hand-write `MobFirebaseService.kt` and
patch the manifest. Budget for it.

---

## 4. Periodic / background work

**There is no scheduler, no cron, and no WorkManager binding.** Exhaustive check:

- No `WorkManager` in any native source or template.
- No `BGTaskScheduler` / `BGAppRefreshTask` / `BGProcessingTask` on iOS.
- The mix-task list (~55 tasks) has nothing job-related; the module list (59 modules) has
  no scheduler.
- The guide's only guidance is the phrase "WorkManager-style patterns for deferred work",
  with no API behind it.

**Can the app poll an HTTP API on a schedule without being open?**

- **iOS: no.** Categorically, with current Mob. Nothing runs.
- **Android: only** with `MobBackground.keep_alive/0`'s foreground service running a normal
  Elixir process with `Process.send_after/3` — at the cost of a permanent visible
  notification and Doze-mode battery scrutiny.

In-app while foregrounded, ordinary OTP (`Process.send_after`, `:timer`, GenServer loops)
works normally — the BEAM is a real BEAM.

---

## 5. On-device persistence

Guide: <https://mob.hexdocs.pm/data.html> (source `mob/guides/data.md`).

**Every generated app ships two layers.** `{:ecto_sqlite3, "~> 0.18"}` is a **default,
unconditional dep** in `mob_new/priv/templates/mob.new/mix.exs.eex:25` — including
`--blank` projects.

| | `Mob.State` | Ecto Repo |
|---|---|---|
| Backed by | `:dets` (OTP stdlib) | SQLite3 via `ecto_sqlite3` |
| Best for | App preferences, UI state | User records, structured data |
| API | `get`/`put`/`delete` | Schemas, queries, migrations |
| Setup | none — auto-started | `mix ecto.migrate` |
| Capacity | O(dozens) of keys | millions of rows |

**`Mob.State`** — `put/2`, `get/2`, `delete/1`, any Elixir term. "Writes call `:dets.sync/1`
before returning, so data is on disk before the function returns — **safe against
`SIGKILL`**." Docs explicitly say: "If you find yourself storing hundreds of keys or wanting
to query across them, move that data to Ecto." **Your watchlist belongs in SQLite, not here.**

**SQLite binding: `ecto_sqlite3` (which wraps `exqlite`).** It cross-compiles — this is the
default, exercised path, not an experiment.

**Writable data directory.** The native launcher sets `MOB_DATA_DIR`; the Repo reads it.
Android `getFilesDir()`, iOS `NSDocumentDirectory`. Both are the correct
backed-up/persistent locations. `Mob.Storage` exposes `:documents`, `:cache`, `:temp`,
`:app_support`.

**Schema migration across app updates — solved, with a sharp edge.** The generated
`app.ex.eex` runs migrations on every boot:

```elixir
{:ok, _} = Application.ensure_all_started(:ecto_sqlite3)
{:ok, _} = MyApp.Repo.start_link()
Ecto.Migrator.with_repo(MyApp.Repo, fn repo ->
  Ecto.Migrator.run(repo, migrations_dir(), :up, all: true)
end)
```

with a documented workaround worth knowing (comment in `app.ex.eex`): on device, Mob deploys
`.beam` files to a flat `-pa` directory with no versioned `lib` structure, so
`:code.priv_dir/1` returns `{error, bad_name}`, and **"`Ecto.Migrator.run/3` silently finds
zero migrations and logs 'Migrations already up' — tables are never created and any query
against them crashes the screen GenServer, making the screen appear frozen."** The fix is
`MOB_BEAMS_DIR`, read by a `migrations_dir/0` helper. If you hand-roll a Repo, replicate it.

**SQLite constraints:** `pool_size: 1` (single writer), limited `ALTER TABLE`, no arrays or
JSONB indexes (use string + Jason, or normalise), `:binary_id` UUIDs stored as binary.

**Encryption at rest: none.** No SQLCipher, no keychain/keystore, no encrypted storage
anywhere in Mob. Surface matrix confirms "Missing: keychain/keystore, encrypted storage".
`Mob.State`'s DETS file and the SQLite DB are plaintext in the app sandbox. For a movie
tracker that's probably fine; for a stored Trakt OAuth token it is not — you would need a
native extension.

**Also available** (plain OTP, undocumented by Mob): ETS, DETS directly, Mnesia. `CubDB` is
never mentioned in any Mob doc or source.

---

## 6. HTTP client

**Ordinary Elixir HTTP libraries work** — Req / Finch / Mint / `:httpc`. Mob ships real
`:crypto` with OpenSSL 3.x plus `:public_key` and `:ssl`. Mob provides no HTTP client of its
own. The surface matrix lists HTTP/WebSocket as "partial: use Elixir libraries directly."

### ⚠️ Android TLS fails at boot unless you fix CA certs

From `mob/lib/mob/certs.ex` `@moduledoc` — this is **not** in the guides I read and is a
genuine trap:

> "`:public_key.cacerts_load/0` looks for a system CA bundle at one of the distro paths it
> knows … On Android none of those exist — the system trust store lives behind a Java API
> that BEAM's `:public_key` doesn't reach. Subsequent calls to `:public_key.cacerts_get/0`
> therefore raise with `no_cacerts_found`, and any library that consults it (Req → Mint →
> `:ssl`, Finch, anything using OTP-26+ default `:ssl` opts) **crashes on the first TLS
> connect**."

Worse, the surfaced error is often an opaque `FunctionClauseError` because some OTP versions
lack a clause for `no_cacerts_found`. Fix:

```elixir
def on_start do
  Mob.Certs.load_cacerts!(Application.app_dir(:my_app, "priv/cacerts.pem"))
  # …rest of startup…
end
```

Bundle `castore`'s `cacerts.pem` into `priv/`. **iOS is unaffected** (Darwin exposes the
trust store at a path Erlang knows); calling it there is a harmless no-op, so call it
unconditionally.

⚠️ **`Mob.Certs` is NOT wired into the generated project.** I grepped all of
`mob_new/priv/templates/` for `Certs`/`cacerts`/`castore`: **zero hits**. A fresh
`mix mob.new` app calling TMDB over HTTPS **will crash on Android on the first request**.
This is the single most likely first-day blocker for this project.

### iOS DNS — re-confirmed, and it IS handled by default

Guide: <https://mob.hexdocs.pm/dns_on_ios.html>.

**When it bites:** physical iOS devices **only**. Not the simulator (shares the Mac's
network stack), not Android (helpers ship as `.so`), not macOS/Linux. Cause: the BEAM spawns
`inet_gethost` via `execve`, which the iOS app sandbox forbids, so Req/Finch/Mint fail
`nxdomain`.

**Does `Mob.DNS.configure_pure_beam/0` fully solve it? For normal API calls, yes.** It flips
the lookup chain from `:native` to `[:file, :dns]` and does raw UDP/TCP queries inside
Erlang via `gen_udp`/`gen_tcp`, seeding Google + Cloudflare as nameservers (overridable via
`nameservers:`). No fork, no `execve`.

**It is already in the generated template.** `mob_new/.../lib/app_name/app.ex.eex` calls
`Mob.DNS.configure_pure_beam()` as the *first* line of `on_start/0`. (Contrast with
`Mob.Certs`, which is not.) Separately, `Mob.App.start/0` calls
`Mob.App.configure_ios_inet_db()` before anything else, to seed `localhost` so distribution
and local TCP work.

**What it does not cover:** VPN-pushed DNS, mDNS, captive portals, search-domain expansion.
For those, call `Mob.DNS.resolve/1` or `preresolve/1` per-host, which uses libc
`getaddrinfo` inside a NIF. The two paths compose. For TMDB/Trakt over the public internet,
`configure_pure_beam/0` alone is sufficient.

---

## 7. Image loading — **the two platforms are not equivalent, and this matters here**

There is an `<Image>` component that loads remote URLs on both platforms. **But the caching
behaviour is asymmetric, and iOS is the weak side.** This is invisible in the docs; I found
it only in source.

### Android — good. Coil.

`mob_new/.../MobBridge.kt.eex:190` imports `coil.compose.AsyncImage`;
`app/build.gradle.eex:121` pins `io.coil-kt:coil-compose:2.6.0`. Coil gives you a **memory
cache and a disk cache by default**, plus request dedup and bitmap pooling. Local paths are
detected and wrapped in `java.io.File` (a bare path string would be treated as a relative
URL and "fail silently").

### iOS — weak. Bare SwiftUI `AsyncImage`.

`mob/ios/MobRootView.swift:1288`:

```swift
AsyncImage(url: url) { phase in
    switch phase {
    case .success(let image): image.resizable().aspectRatio(contentMode: contentMode)
    default:                  placeholder
    }
}
```

Two consequences for a poster grid:

1. **No disk or decoded-image cache is configured.** I grepped all iOS sources for
   `URLCache` / `URLSessionConfiguration`: **zero hits**. SwiftUI's `AsyncImage` relies on
   `URLSession.shared`/`URLCache.shared` defaults and keeps no decoded-image cache of its
   own — it re-issues the load whenever the view is reconstructed. In a scrolling
   `LazyList` of posters that means **repeated fetch + decode as rows recycle**, with the
   visible jank and data usage that implies. (The re-fetch-on-recycle behaviour is a
   well-known property of SwiftUI `AsyncImage`, not something Mob's docs state — treat the
   mechanism as inferred from the code, the absence of cache configuration as verified.)
2. **Failure and loading are the same state.** The `switch` has only `.success` and
   `default:` — `.empty` (loading) and `.failure` both render `placeholder`. **You cannot
   distinguish "still loading" from "broken poster"** without patching `MobRootView.swift`.

`placeholder` = the `placeholder_color` prop, else `UIColor.systemGray5`. Sizing via
`width`/`height`, then `.clipShape(RoundedRectangle(cornerRadius:))`.

**Recommendation for this project:** plan on replacing the iOS `MobImage` with a caching
loader (Nuke/Kingfisher, or a `URLCache` + `NSCache` layer) as a native extension, or
pre-download posters to `Mob.Storage` and render from local file paths — the local-file
branch (`UIImage(contentsOfFile:)`) sidesteps the problem entirely and is the same code path
on both platforms. Doing your own disk cache in Elixir is arguably the cleanest fix and
keeps the platforms symmetric.

**Undocumented bonus found in source:** there is an `<Icon>` component (`MobIcon`) that maps
logical names to **SF Symbols on iOS and Material icons on Android** from one `name:` prop
(`MobBridge.kt.eex:~3520`, mirroring `MobRootView.swift`'s `sfSymbolName/1`). It is in
neither `components.html` nor `Mob.UI`'s function list.

---

## 8. The native-shell fork problem — spelled out

This is the framework's own top-listed structural debt. The guide is blunt
(<https://mob.hexdocs.pm/troubleshooting.html>, source `mob/guides/troubleshooting.md:481-487`):

> "**Mob ships zero host-app Kotlin / Swift today; every app's `MobBridge` is its own
> diverged copy.** A future Mob improvement is to ship the renderer as a generated module or
> an AAR / Swift package so this kind of contract drift can't happen. Tracked in PLAN.md."

`mob/PLAN.md:2383-2420` ("MobBridge.kt / MobBridge.swift duplication (drift hazard)") is
more explicit:

> "They're scaffolded once and then diverge — `nxeigen_probe`'s is 3068 lines;
> `mob_lv_test`'s is 1657. **When Mob adds a feature that needs Kotlin support … every app
> has to be patched independently. When a Kotlin-side bug is fixed in one app … the fix
> doesn't propagate.**"
>
> "This is sustainable while there are ~2 Mob apps. **It will become a real problem at ~10.**"

### What actually breaks over time

1. **New widgets silently don't render.** `MobBridge.kt` / `MobRootView.swift` contain the
   `when`/`switch` that maps node types to composables. A widget added in Mob 0.8 has no arm
   in your 0.7-era bridge — the node arrives and is dropped or renders as an error stub.
   Your generated app's own comment acknowledges this pattern: mappings are named "so
   missing mappings show up in the UI rather than failing silently"
   (`MobBridge.kt.eex:3499`).
2. **Contract changes produce wrong output, not errors.** The shipped example: the
   `Mob.Canvas` logical-viewport contract changed; older scaffolded bridges kept a
   1-coord-=-1-pixel renderer, so draw ops land shifted/cropped on high-density devices with
   no error. The fix is a per-app manual patch (a `sx`/`sy` scaling recipe in
   `Mob.Canvas`'s `@moduledoc`).
3. **Plugin host requirements accumulate.** Every plugin that needs a `<service>`,
   `<receiver>` or `<provider>` fragment must be added to *your* manifest by hand — plugin
   manifests cannot contribute those. `mob_notify` alone needs two, and as shown in §3 the
   templates do not currently ship them.
4. **Native fixes in the framework never reach you.** Bug fixes in Compose/SwiftUI rendering
   land in `mob_new`'s templates, which only affect *newly generated* projects.

### Is there an upgrade path? No.

I enumerated every task in `mob_dev/lib/mix/tasks/` (46 files). **There is no
`mix mob.upgrade`, no template resync, no bridge diff task.** `mix mob.deploy --native`
rebuilds native code but does not re-render `MobBridge.kt` / `MobRootView.swift` from
templates. PLAN.md lists three candidate fixes — ship as AAR/Swift package, regenerate on
every build, or a `mix mob.audit_bridge` diff tool — and **none is implemented**.

### Recommended practice for a long-lived app

The docs prescribe nothing, so this is my recommendation:

- **Commit `android/` and `ios/` and treat them as vendored third-party code**, with a
  header recording the `mob_new` version they were generated from.
- On every Mob minor bump: `mix mob.new` a throwaway app with the new generator into
  `/tmp`, then **three-way-diff its `MobBridge.kt` / `MobRootView.swift` / `AndroidManifest.xml`
  against yours** and port changes by hand. This is the missing `mix mob.upgrade`, run
  manually. Automate it as a script early — it is the single highest-leverage piece of
  project infrastructure you can build.
- **Keep your own edits to the bridges minimal and clearly fenced** with comment markers, so
  the three-way merge stays tractable. Every custom widget you add to the bridge is
  permanent merge cost.
- Prefer `Mob.Component` native views and plugins over editing `MobBridge` directly — those
  live in *your* Elixir/plugin code and are not clobbered by a bridge resync.
- Pin `{:mob, "== 0.7.x"}` rather than `~> 0.7`, and upgrade deliberately. Given 62 releases
  in 3 months and a no-shim 0.7.0 break, floating is dangerous.

---

## 9. App lifecycle & process supervision

### ⚠️ There is no supervision tree for screens. The docs claim there is.

`Mob.Screen`'s own `@moduledoc` (`mob/lib/mob/screen.ex:5-9`) says:

> "Each screen runs as a **supervised** GenServer … a buggy `handle_event` crashes its own
> screen and **the supervisor restarts it** without taking down navigation, audio,
> background services, or the BEAM itself."

and <https://mob.hexdocs.pm/architecture.html> lists "Built-in fault tolerance (OTP
supervision restarts crashed screens automatically)" as a design priority.

**The source does not support this.** Findings:

- There is **no `application.ex` and no supervisor module** in `mob/lib/mob/`.
- `grep -rn "Supervisor" mob/lib/` returns hits in **only** `Mob.Plugins.Supervisor` and
  `Mob.Plugins.Lifecycle`. `Mob.Plugins.Supervisor` (`strategy: :one_for_one`) supervises
  **tier-4 plugin workers plus the lifecycle listener** — not screens.
- `Mob.Screen.start_root/3` (`screen.ex:200-203`) is a bare
  `GenServer.start_link(__MODULE__, {...}, opts)`, called from your `on_start/0`. It is
  *linked* to whatever process runs `on_start/0`, with **no restart strategy and no child
  spec in a supervisor**.
- `mob/lib/mob/screen.ex` contains no `:EXIT` / restart handling.

**Practical consequence:** an unhandled exception in a screen's `handle_info` kills that
screen process, and nothing brings it back. Treat "screens are supervised" as **aspirational
documentation**. If you want the resilience the docs promise, put your *own* `Supervisor`
in `on_start/0` and start screens under it, or defensively handle errors in screen
callbacks. **Do not architect around automatic screen restart.**

### Startup sequence

`use Mob.App` generates `start/0` (`mob/lib/mob/app.ex:50-95+`), called from the BEAM entry
module (e.g. `mob_demo.erl`) **after OTP applications have started** — note a Mob app "boots
via a custom BEAM entry (not `Application.start`)", so `Application.get_application/1`
returns `nil` at runtime. `start/0`:

1. `Mob.App.configure_ios_inet_db()` — iOS-only; switches to file-only hostname lookup and
   seeds `localhost`, because otherwise "any subsequent code path that resolves a hostname …
   crashes the calling process with `badarg`".
2. `Mob.NativeLogger.install()` — routes Logger to logcat/NSLog.
3. Seeds `Mob.Nav.Registry` from `navigation/1`.
4. Calls your `on_start/0`.

`Mob.State` is started automatically **before** `on_start/0`.

### Foreground/background events

`Mob.Plugins.Lifecycle` subscribes to `Mob.Device`'s `:app` events and dispatches
`:did_become_active` / `:did_enter_background` to plugin hooks (`lifecycle.on_resume` /
`lifecycle.on_background`). Screens can observe the same via `Mob.Device` events; the
surface matrix lists foreground/background state as fully supported on both platforms.

### What happens to GenServer state when the OS kills the app

It is **gone**. There is no automatic snapshotting of screen assigns on background.

### The documented rehydration pattern: `Mob.ScreenState`

`mob/lib/mob/screen_state.ex` — this is a real, complete answer:

- Opt in per screen with `use Mob.Screen, vsn: N, persist: true`; implement `dump_state/1`,
  `load_state/2`, and optionally `screen_key/1`.
- **Backed by the app's Ecto Repo**, not DETS — `config :mob, :repo, MyApp.Repo`, table
  `mob_screen_states` (migration generated by `mix mob.new`).
- Keyed by screen module name by default; override `screen_key/1` for per-user or
  parameterised state: `def screen_key(assigns), do: "#{__MODULE__}:#{assigns.user_id}"`.
- Serialised with `:erlang.term_to_binary/1` **after stripping non-serialisable terms**
  (PIDs, refs, ports, functions); decoded with the `:safe` flag "to prevent atom-table
  pollution from untrusted data".
- `vsn` is stored alongside, so `load_state/2` can migrate or discard stale shapes across
  app updates.
- ⚠️ **All functions are silent no-ops when no Repo is configured**, and "persistence
  failures are silent so a missing or misconfigured Repo never crashes a screen"
  (`dump/2` returns `:ok` unconditionally). Convenient, but it means a misconfiguration
  looks exactly like working code that loses state. Test it explicitly.

### One more thing worth flagging

The generated `app.ex.eex` ships this line in `on_start/0`, unconditionally:

```elixir
Mob.Dist.ensure_started(node: :"my_app_android@127.0.0.1", cookie: :mob_secret)
```

A **hardcoded distribution cookie in a shipped template**. The troubleshooting guide already
notes "distribution in production differs significantly from development but requires custom
implementation". **Strip or gate this behind `Mix.env()` before shipping.**

---

## Source files cited in this section

Local clones under the scratchpad; upstream paths given for permanence.

| Path | What it establishes |
|---|---|
| `mob/guides/background_execution.md` | iOS suspension, Android foreground service, decision table |
| `mob/guides/data.md` | Mob.State vs Ecto/SQLite, MOB_DATA_DIR, migrations |
| `mob/guides/troubleshooting.md:445-487` | Canvas drift; "Mob ships zero host-app Kotlin/Swift" |
| `mob/PLAN.md:2383-2420` | MobBridge duplication hazard, three unimplemented fixes |
| `mob/lib/mob/certs.ex` | Android `no_cacerts_found` TLS failure + fix |
| `mob/lib/mob/screen.ex:1-20, 170-203` | "supervised" claim vs bare `GenServer.start_link` |
| `mob/lib/mob/screen_state.ex` | Repo-backed screen persistence, vsn, silent no-ops |
| `mob/lib/mob/app.ex:50-95` | `start/0` boot sequence, custom BEAM entry |
| `mob/lib/mob/plugins/supervisor.ex` | the only Supervisor in core; supervises plugins only |
| `mob/ios/mob_nif.m:2359-2400, 3360-3440` | notification delegate, `source:@"local"` hardcode, launch handoff |
| `mob/ios/MobRootView.swift:1270-1315` | `MobImage` — bare `AsyncImage`, no cache, merged loading/failure |
| `mob_notify/lib/mob_notify.ex` | `schedule/2`, `cancel/2`, `register_push/1`, `schedule_opts/1` |
| `mob_notify/priv/native/android/MobNotifyBridge.kt` | AlarmManager, exact-alarm guard, boot re-arm, SharedPreferences |
| `mob_notify/priv/native/ios/mob_notify_nif.m` | `UNTimeIntervalNotificationTrigger`, min 1s, `repeats: NO` |
| `mob_notify/priv/mob_plugin.exs` | permissions, gradle deps, five host_requirements |
| `mob_new/.../lib/app_name/app.ex.eex` | generated `on_start/0`: DNS, Repo, migrations, dist cookie |
| `mob_new/.../mix.exs.eex:21-40` | default deps incl. `ecto_sqlite3` |
| `mob_new/.../ios/Info.plist.eex:33-36` | `UIBackgroundModes: [audio]` shipped by default |
| `mob_new/.../ios/AppDelegate.m.eex:67-79` | push token forwarding; no silent-push handler |
| `mob_new/.../android/AndroidManifest.xml.eex:34-35, 84` | permissions, `.NotificationReceiver`; **no FCM service, no boot receiver** |
| `mob_new/.../android/MobBridge.kt.eex:190, 2485-2530, 3602-3640` | Coil import, `MobImage`, `NotificationReceiver` |
| `mob_new/.../android/app/build.gradle.eex:114-139` | Coil 2.6.0, ExoPlayer, CameraX |
| `mob_dev/lib/mix/tasks/` (46 files) | **no `mix mob.upgrade`** |
| `mob_dev/lib/mob_dev/native_build.ex:4550-4580, 5125-5150` | generated `io.mob.plugin` seams, `MobNotifyHub` |
