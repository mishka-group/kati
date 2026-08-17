# Ash Framework on Mob (BEAM-on-device) — exactly how it works

Research date: **2026-08-17**. Versions reviewed: `mob` **0.7.20**, `mob_new` **0.4.20**,
`mob_dev` **0.6.23**, `mob_ash` **0.1.1**, `ash` **3.31.3** (measurements taken against a
locally compiled **3.29.3**), `ash_sqlite` **0.2.17**, `oban` **2.23.1**, `ash_oban` **0.8.12**.

Companion research (read first, not repeated here):
`/Users/shahryar/Documents/Programming/Elixir/kati/.scratch/research/mob-framework.md`,
`.../design-index.md`, `.../mishka-mob-index.md`.

Local source used for citation (extracted hex tarballs + a vendored mob checkout):

| What | Path |
|---|---|
| mob 0.7.20 (full, incl. native src) | `/Users/shahryar/Documents/Programming/Elixir/mishka_chelekom/development/mob/deps/mob` |
| mob_new 0.4.20 | `/private/tmp/claude-501/-Volumes-Fast-Arise-Resource-AI-book/c5718512-beef-4e2f-bbc9-14f1d94a1350/scratchpad/pkgs/mob_new-0.4.20` |
| mob_dev 0.6.23 | `.../scratchpad/pkgs/mob_dev-0.6.23` |
| mob_ash 0.1.1 | `.../scratchpad/pkgs/mob_ash` |
| ash 3.31.3 / ash_sqlite 0.2.17 / ash_oban 0.8.12 / oban 2.23.1 | `.../scratchpad/pkgs/<name>-<vsn>` |
| ash 3.29.3 compiled (for size measurements) | `/Users/shahryar/Documents/Programming/Elixir/guarded_struct/_build/dev/lib/ash/ebin` |

---

## 0. Verdict up front

**Ash on Mob is real and supported — but the *integration package* (`mob_ash`) is a 350-line
demo, not infrastructure.** What you actually get is: "Ash is pure Elixir, it runs in the
on-device BEAM, and `mob_ash` proves it by generating three throwaway CRUD screens." For Kati
you will use `ash` + `ash_sqlite` **directly** and write your own 62 screens; `mob_ash` buys
you nothing and costs you a build-time coupling.

The decision "SQLite via Ash for the whole system" is **viable but carries four sharp,
verifiable costs** that were not obvious when it was made:

1. **`config/*.exs` is not loaded on device.** Everything Ash/AshSqlite/Oban normally reads
   from Application env must be `Application.put_env/3`'d in `on_start/0` (§3.4).
2. **AshSqlite has `can?(:transact) == false`, no aggregates, no `distinct`.** (§2.4)
3. **AshOban is not viable** — it hard-requires `postgrex` and never mentions SQLite (§4).
4. **+~6 MB compressed / +~10 MB extracted** on the APK, measured (§6).

None of these is fatal. All of them change how you write the app.

---

## 1. Does Mob actually support Ash?

### 1.1 Yes — there is a first-party package, `mob_ash`

`mob_ash` exists on Hex, is owned by Mob's author, and is **pre-trusted by every generated
Mob app**.

`mob_new-0.4.20/priv/templates/mob.new/mob.exs.eex:30-41` — the trust gate baked into every
`mix mob.new` project:

```elixir
config :mob, :trusted_plugins, %{
  mob_audio_capture: "ed25519:nc56w+1Kx0gIt/4EkHxnMZCKHMzp4+S5kS/HoSzEZkg=",
  ...
  mob_ash: "ed25519:nc56w+1Kx0gIt/4EkHxnMZCKHMzp4+S5kS/HoSzEZkg="
}
```

with the surrounding comment (`mob.exs.eex:22-29`):

> "Trust gate for the first-party plugins. Each is signed in CI with the shared mob release
> key… every official plugin is pre-trusted and 'just works' the moment you add it to deps +
> `:plugins` above."

Hex metadata (<https://hex.pm/api/packages/mob_ash>):

| Field | Value |
|---|---|
| Latest | **0.1.1**, published **2026-06-16** |
| Releases | 2 (0.1.0 on 2026-06-12) |
| Downloads | **176 all-time** |
| Requires | `ash ~> 3.0` (REQUIRED), `mob ~> 0.7` (REQUIRED) |
| Repo | <https://github.com/GenericJam/mob_ash> — **0 stars, 0 open issues** |
| Docs | <https://mob-ash.hexdocs.pm/> (HTTP 200) |
| Licence | MIT |

It is listed in Mob's own **First-Party Packages** guide
(<https://mob.hexdocs.pm/packages.html>) under a table heading that contains exactly one row:

> **Framework integrations**
> | Package | Gives you |
> | `mob_ash` | Declare [Ash](https://hexdocs.pm/ash) resources, get generated
> list/detail/create screens per resource — **Ash runs on-device** |

`mob_ash/mix.exs:42-46` is the clearest statement of intent in the whole ecosystem:

```elixir
# :ash is a REAL runtime dep — it runs ON DEVICE in the host's BEAM (the
# first mob plugin with a heavyweight pure-Elixir runtime dependency).
[
  {:mob, "~> 0.7"},
  {:ash, "~> 3.0"},
```

### 1.2 No — there is no `mix mob.new --ash`, and no Ash guide

`mob_new-0.4.20/lib/mix/tasks/mob.new.ex:125-134` — the complete switch list:

```elixir
@switches [
  no_install: :boolean,
  ios: :boolean,
  android: :boolean,
  dest: :string,
  local: :boolean,
  liveview: :boolean,
  python: :boolean,
  blank: :boolean
]
```

No `--ash`. The generated `mix.exs` hardcodes `{:ecto_sqlite3, "~> 0.18"}` and nothing Ash
(`mob_new-0.4.20/priv/templates/mob.new/mix.exs.eex:21-40`).

The **Mob core docs contain zero mentions of Ash** outside the one-row packages table. I
enumerated all 34 guides from the ExDoc sidebar
(<https://mob.hexdocs.pm/dist/sidebar_items-1E07B7BD.js>); the only regex hits for `ash` are
"crashes". In particular **`https://mob.hexdocs.pm/data.html` (Data & Persistence) never
mentions Ash** — it teaches raw Ecto schemas, `mix ecto.gen.migration`, and `MyApp.Repo.all/1`.

The only Ash reference in mob's own source is a doc comment:
`mob/lib/mob/nav/registry.ex:43-46`

```elixir
# Route-bound params let N routes share one parameterized screen module (the
# data-driven-plugin pattern — e.g. mob_ash registers `/ash/post/list` as
# `{MobAsh.ListScreen, %{resource: MyApp.Post}}`).
```

### 1.3 The plugin-manifest spec treats Ash as *the* motivating example

The Plugins manifest reference (<https://mob.hexdocs.pm/mob_plugins.html>, "Code-generated
plugins (spec version 2+)") says:

> "Some plugins need to derive their contributions from the host app's configuration at
> compile time, not declare them statically. **The canonical case is an Ash integration**:
> define N Ash resources in the host app, and a `mob_ash` plugin generates N × 3 screens
> (list, detail, form) plus any matching UI components — all baked into the build, not
> runtime."

and mob's CHANGELOG (`mob/CHANGELOG.md:352`) records spec-v2 shipping in the tier-3/4 plugin
work, device-verified:

> "**Tier 3:** plugins ship whole `Mob.Screen` modules (static `:screens` or spec-v2
> `:screens_generator` codegen run under the host-config audit) … **Device-verified on a
> physical iPhone (SE) and Android (Moto G): static + generated screens register, a plugin
> migration creates its table on device**…"

`mob_ash/priv/mob_plugin.exs:4-19` confirms it is that lane:

```elixir
plugin_spec_version: 2,
screens_generator: {MobAsh.Generator, :generate, []},
host_config_keys: [:ash_domains]
# Pure Elixir end to end: no nifs / android / ios sections — every screen is
# hot-pushable, and Ash itself runs on-device in the host BEAM.
```

### 1.4 ⚠️ The docs describe a `mob_ash` that does not exist

`mob_plugins.html` shows a `mob_ash` with **native components and generated modules**:

```elixir
screens_generator: {MobAsh.ScreenGenerator, :generate, []},
ui_components: [
  %{tag: "AshForm",  atom: :ash_form,  props: [:resource, :action, :record]},
  %{tag: "AshList",  atom: :ash_list,  props: [:resource, :filter, :sort]},
  %{tag: "AshField", atom: :ash_field, props: [:attribute, :record]}
],
ios: %{swift_files: ["priv/native/ios/MobAshForm.swift", ...]},
android: %{composable_files: [...]}
```
producing `MobAsh.Generated.Blog.Post.ListScreen` etc.

**The shipped 0.1.1 package has none of that.** Its complete contents:

```
lib/mob_ash.ex            (54 lines)
lib/mob_ash/generator.ex  (42 lines)
lib/mob_ash/info.ex       (74 lines)
lib/mob_ash/list_screen.ex   (76 lines)
lib/mob_ash/detail_screen.ex (65 lines)
lib/mob_ash/form_screen.ex   (81 lines)
priv/mob_plugin.{exs,pub,sig}
```

No `ui_components`, no Swift/Kotlin, no `MobAsh.Generated.*` — just three **shared
parameterized screens** carrying `%{resource: Mod}` as route-bound nav params
(`mob_ash/lib/mob_ash/generator.ex:30-39`).

Also: `mob_ash/CHANGELOG.md:21` claims "Generates spec-v2 screens from your Ash resources via
`mix mob_ash.gen`" — **there is no `lib/mix/tasks` directory in the package**. That task does
not exist. Treat the CHANGELOG as aspirational.

### 1.5 What `mob_ash` actually gives you (and why Kati should skip it)

`mob_ash/lib/mob_ash/info.ex:38-49` — the form only handles four scalar types:

```elixir
a.writable? and not a.generated? and a.name not in pk and
  a.name not in [:inserted_at, :updated_at] and
  a.type in [Ash.Type.String, Ash.Type.CiString, Ash.Type.Integer, Ash.Type.Atom]
```

`list_screen.ex:54` loads **every record with no filter, no sort, no pagination**:
`Mob.Socket.assign(socket, :records, Ash.read!(resource))`.
`detail_screen.ex:45` deletes with `Ash.destroy!/1`. There is **no update screen at all**
(`mob_ash.ex:46-50`: only `:list | :detail | :new`).

Against Kati's requirements this is unusable: no dates, no decimals (money), no booleans, no
relationships, no RTL, no Persian, no Shamsi display, no Mishka Chelekom components (all
markup is raw `~MOB` `<Button>`/`<TextField>` — `list_screen.ex:22-32`).

**Recommendation: add `{:ash, ...}` and `{:ash_sqlite, ...}` directly. Do not add
`{:mob_ash, ...}`.** You lose nothing except three demo screens, and you avoid coupling your
build to `mix mob.regen_plugin_manifest` and the plugin signature gate.

---

## 2. AshSqlite on device

### 2.1 exqlite is already there, and Mob cross-compiles the C itself

This is the reassuring part. Mob does **not** use `elixir_make`'s precompiled-NIF path for
the device build; **the generated app's own native build compiles exqlite's C from source per
Android ABI.**

`mob_new-0.4.20/priv/templates/mob.new/android/app/src/main/jni/build.zig.eex:376-397`:

```zig
// --- exqlite / SQLite NIF ─────────────────────────────────────────────
// Compile sqlite3_nif.c + sqlite3.c (the SQLite amalgamation) and link
// them into libsqlite3_nif.so. NDK clang for the link as before; zig cc
// for compile. -DSQLITE_THREADSAFE=1 matches CMake.
const sqlite_flags = &[_][]const u8{
    "-Os", "-ffunction-sections", "-fdata-sections", "-fPIC",
    "-DSQLITE_THREADSAFE=1",
    b.fmt("--sysroot={s}", .{ndk_sysroot}), ...
};
const sqlite_sources = [_]CObjectSpec{
    .{ .name = "sqlite3_nif", .source = b.fmt("{s}/sqlite3_nif.c", .{exqlite_src}) },
    .{ .name = "sqlite3",     .source = b.fmt("{s}/sqlite3.c",     .{exqlite_src}) },
};
```

- **Android ABIs**: `android/app/build.gradle.eex:47` — `ndk { abiFilters 'arm64-v8a',
  'armeabi-v7a', 'x86_64' }`. So arm64 **and** x86_64 (emulator) **and** armeabi-v7a are all
  covered by the same zig-cc path.
- Output is mirrored to `android/app/src/main/jniLibs/<ABI>/libsqlite3_nif.so`
  (`jni/CMakeLists.txt.eex:161-167`), linked against `lib<app>.so` for the `enif_*` symbols
  (`build.zig.eex:735-760`), with `-Wl,-z,max-page-size=16384` for the Android 15 / Play
  16 KB-page requirement.
- At boot, `mob/android/jni/mob_beam.zig:587-660` symlinks it into
  `$OTP_ROOT/lib/exqlite-VSN/priv/sqlite3_nif.so` so `:code.priv_dir(:exqlite)` resolves:

  > "The OTP code server registers lib_dirs by scanning `$OTP_ROOT/lib/*/ebin` at boot. For
  > `code:lib_dir(:exqlite)` to work, exqlite must live at `$OTP_ROOT/lib/exqlite-VERSION/` —
  > a flat `-pa` dir is NOT sufficient."

- **iOS**: the NIF is **statically linked into the BEAM binary** (iOS forbids dlopen of app-
  external shared objects). `mob/ios/driver_tab_ios.zig:69-78,116-146`:

  ```zig
  // exqlite's sqlite3_nif is linked statically on device only. The build
  // ... either isn't provided OR has sqlite_static = false.
  const sqlite_static = build_options.sqlite_static;
  extern fn sqlite3_nif_nif_init() callconv(.c) ?*anyopaque;
  ```
  and `mob_dev`'s tarball task notes "**iOS targets don't ship exqlite BEAMs so the flag is
  ignored**" (`mob_dev/lib/mix/tasks/mob.release.tarball.ex:14`).

**Conclusion for Q2's cross-compile worry: solved, and not by you.** exqlite is the one C NIF
Mob treats as first-class. `ecto_sqlite3` is an unconditional dep of every generated app
(`mix.exs.eex:25`) and its adapter is what the generated `Repo` uses (`repo.ex.eex:4`).

### 2.2 Does AshSqlite work with the bundled exqlite/ecto_sqlite3? — Version-wise, yes

`ash_sqlite` 0.2.17 requirements (<https://hex.pm/api/packages/ash_sqlite/releases/0.2.17>):

```
ash        ~> 3.19                     REQUIRED
ash_sql    ~> 0.2 and >= 0.2.20        REQUIRED
ecto       ~> 3.13                     REQUIRED
ecto_sql   ~> 3.13                     REQUIRED
ecto_sqlite3 ~> 0.12                   REQUIRED
jason      ~> 1.0                      REQUIRED
igniter    ~> 0.6 and >= 0.6.14        optional
```

`ecto_sqlite3 ~> 0.12` is satisfied by Mob's `~> 0.18`. AshSqlite goes through the same
`Ecto.Adapters.SQLite3` → `exqlite` → `sqlite3_nif` chain that Mob already cross-compiles.
**There is no additional native code in AshSqlite** — it is pure Elixir on top of ecto_sql.

### 2.3 The Repo: how to keep `MOB_DATA_DIR` while using `AshSqlite.Repo`

`AshSqlite.Repo.__using__` **defines its own `init/2`** (`ash_sqlite-0.2.17/lib/repo.ex:57-66`):

```elixir
def init(_, config) do
  new_config =
    config
    |> Keyword.put(:installed_extensions, installed_extensions())
    |> Keyword.put(:migrations_path, migrations_path())
    |> Keyword.put(:case_sensitive_like, :on)
  {:ok, new_config}
end
```

so you cannot just copy Mob's generated `repo.ex`. The moduledoc (`lib/repo.ex:11-13`) gives
the contract:

> "You can use `Ecto.Repo`'s `init/2` to configure your repo like normal, but instead of
> returning `{:ok, config}`, use `super(config)` to pass the configuration to the
> `AshSqlite.Repo` implementation."

Concretely, for Kati (this is the merge of `mob_new`'s `repo.ex.eex:6-22` with AshSqlite's
contract, plus the write-safety knobs AshSqlite documents):

```elixir
defmodule Kati.Repo do
  use AshSqlite.Repo, otp_app: :kati

  def installed_extensions, do: []
  def min_pg_version, do: 10          # required callback; meaningless for SQLite

  @impl true
  def init(type, config) do
    # Mob.data_dir/0 wraps MOB_DATA_DIR with the host fallback and mkdir_p.
    data_dir = Mob.data_dir()

    config =
      Keyword.merge(config,
        database: Path.join(data_dir, "kati.db"),
        pool_size: 1,
        default_transaction_mode: :immediate,
        busy_timeout: 5_000
      )

    super(type, config)   # <- MUST call super, not {:ok, config}
  end
end
```

`Mob.data_dir/0` is the documented accessor (`mob/lib/mob.ex:46-70`):

> "On device this is `MOB_DATA_DIR`, set by the BEAM launcher to the platform's persistent
> app-private location (iOS `NSDocumentDirectory`, Android `getFilesDir()`)… **Use this — not
> `MOB_BEAMS_DIR`. `MOB_BEAMS_DIR` points inside the signed, read-only `.app` bundle on iOS,
> so writing there fails with `:eperm`**; it happens to be writable on Android, which is how
> that trap stays hidden until an app ships to iOS."

`default_transaction_mode: :immediate` + `busy_timeout` are AshSqlite's own recommendation
(`ash_sqlite-0.2.17/documentation/topics/about-ash-sqlite/transactions.md`).

### 2.4 ⚠️ AshSqlite capability gaps — read this before designing resources

`ash_sqlite-0.2.17/lib/data_layer.ex:444-514` (verbatim, elided):

```elixir
def can?(_, :async_engine),            do: false
def can?(_, :transact),                do: false
def can?(_, {:lock, _}),               do: false
def can?(_, {:aggregate, _type}),      do: false
def can?(_, :aggregate_filter),        do: false
def can?(_, :aggregate_sort),          do: false
def can?(_, {:aggregate_relationship, _}), do: false
def can?(_, :distinct),                do: false
def can?(_, :distinct_sort),           do: false
def can?(_, :multitenancy),            do: false
def can?(_resource, {:lateral_join, _}), do: false
def can?(_, {:filter_expr, %Ash.Query.Function.StringJoin{}}), do: false
# and true for: bulk_create, update_query, destroy_query, composite_primary_key,
# {:atomic, :update|:upsert|:create}, upsert, changeset_filter, boolean_filter,
# expression_calculation(+_sort), create/read/select/filter/limit/offset/sort,
# {:query_aggregate, :count|:first|:sum|:max|:min|:avg|:exists}
```

Consequences for Kati's 62 screens:

| Gap | What it means for Kati |
|---|---|
| **`:transact == false`** | Ash will **not wrap your actions in transactions**. A multi-resource create (e.g. "log a workout + its sets + update a habit streak") is **not atomic** unless you explicitly `Kati.Repo.transaction/1` around it yourself. Documented: *"AshSqlite disables transaction support by default (`can?(:transact)` returns `false`). Without extra configuration, Ash will not wrap actions in transactions when using the SQLite data layer."* (`transactions.md`) |
| **No resource `aggregates`** | You cannot declare `count :entries_count, :entries` or `sum :total, :transactions, :amount` on a resource. Money totals, habit streak counts, "films watched this month" must be **query aggregates** (`Ash.count/2`, `Ash.sum/3`) or **calculations**, computed per screen. `{:query_aggregate, …}` IS supported, so `Ash.count!(Kati.Money.Transaction |> Ash.Query.filter(...))` works. |
| **No `distinct`** | `Ash.Query.distinct/2` is unavailable. De-dup in Elixir or via `group_by` in a manual `Ecto` query. |
| **No lateral join** | "load the 5 most recent entries per book" degrades to N+1-ish separate queries. Fine at Kati's data scale; know it. |
| **`:async_engine == false`** | Good news on device — Ash will not fan reads out across processes against a `pool_size: 1` connection. |
| **No multitenancy** | Irrelevant (single-user app). |

AshSqlite's own summary (`documentation/topics/about-ash-sqlite/what-is-ash-sqlite.md`):

> "This doesn't have all of the features of AshPostgres, but it does support most of the
> features of Ash data layers. **The main feature missing is Aggregate support.**"

### 2.5 Has anyone actually run AshSqlite on Mob? — **No public evidence.**

- `mob_ash` all-time downloads: **176**. GitHub stars: **0**. Open issues: **0**.
- Its README only *suggests* AshSqlite; it does not claim to have run it:
  > "Use a device-friendly Ash data layer (`Ash.DataLayer.Ets`, or AshSqlite over the bundled
  > SQLite)." (`mob_ash/README.md:27-29`)
- The Elixir Forum Mob thread
  (<https://elixirforum.com/t/mob-native-beam-elixir-on-native-mobile/74924>, both pages)
  **never mentions Ash, AshSqlite, mob_ash, or Ecto** (checked; zero hits).
- Mob's CHANGELOG device-verification claim (`CHANGELOG.md:352`) covers *tier-3 generated
  screens and a plugin migration*, **not Ash or AshSqlite specifically**.

**State this as UNKNOWN/unproven.** You would be the first public user of AshSqlite on a
device BEAM. Budget a spike: one resource, one migration, one device run, day one.

---

## 3. Migrations on device

### 3.1 Where the DB lives

`MOB_DATA_DIR`, set by the native launcher before `erl_start`:

- Android — `context.getFilesDir()` ("app-private, survives updates")
- iOS — `NSDocumentDirectory` ("app-private, iCloud-backed")

(`mob_new-0.4.20/priv/templates/mob.new/lib/app_name/repo.ex.eex:8-11`;
`mob/ios/mob_beam.m:212`; `mob/lib/mob.ex:50-53`.) Use `Mob.data_dir()`.

### 3.2 How migrations run at boot

The generated `on_start/0` (`mob_new-0.4.20/priv/templates/mob.new/lib/app_name/app.ex.eex:25-29`):

```elixir
{:ok, _} = Application.ensure_all_started(:ecto_sqlite3)
{:ok, _} = <%= module_name %>.Repo.start_link()
Ecto.Migrator.with_repo(<%= module_name %>.Repo, fn repo ->
  Ecto.Migrator.run(repo, migrations_dir(), :up, all: true)
end)
```

with the migrations dir resolved **explicitly, not via `:code.priv_dir/1`**
(`app.ex.eex:71-95`):

```elixir
# On Android and iOS, Mob deploys .beam files to a flat -pa directory with no
# versioned lib structure, so :code.priv_dir/1 returns {error, bad_name}.
# Ecto.Migrator.run/3 silently finds zero migrations and logs "Migrations
# already up" — tables are never created and any query against them crashes
# the screen GenServer, making the screen appear frozen.
#
# The fix: mob_beam.c/mob_beam.m set MOB_BEAMS_DIR=beams_dir before erl_start.
defp migrations_dir do
  case System.get_env("MOB_BEAMS_DIR") do
    nil       -> Application.app_dir(:<%= app_name %>, "priv/repo/migrations")
    beams_dir -> Path.join([beams_dir, "priv", "repo", "migrations"])
  end
end
```

`mob_dev/lib/mob_dev/deployer.ex:488-535` pushes `priv/` to `{beams_dir}/priv/` and warns:

> "**PERMISSION TRAP: `chmod -R 755` is not optional.** … the BEAM process runs as the app
> user (u0_a0) … `Path.wildcard` calls `opendir(3)` … Without it, wildcard returns `[]` even
> though the `.exs` file is right there — and Ecto again logs 'Migrations already up'."

⚠️ **The docs contradict the code.** `https://mob.hexdocs.pm/data.html` says the opposite:

> "The migration modules are compiled into your app's `.beam` files and copied to the device
> by the build scripts, so `Ecto.Migrator` finds them at the correct path via
> `:code.priv_dir/1`."

Which is right? I tested the mechanism directly. `mob_beam.zig:259` builds
`beams_dir = "{otp_root}/{app_module}"` and passes it as `-pa`; `code_server.erl`'s
`insert_dir/2` registers the *basename* of a `-pa` entry as the app name. Empirically on
OTP 28.1.1:

```
$ erl -noshell -pa .../privtest/kati -eval 'io:format("~p~n",[code:priv_dir(kati)]),halt(0).'
"/private/tmp/.../privtest/kati/priv"
```

So `:code.priv_dir/1` **does** resolve when the `-pa` dir is named after the app — which is
exactly what Mob constructs. **The `app.ex.eex` comment is probably stale.** But since the
comment is Mob's own, and the failure mode ("silently zero migrations, screen appears frozen")
is catastrophic and silent, **keep the explicit `MOB_BEAMS_DIR` path**. It costs nothing and
is correct either way. (Verify on-device on day one.)

### 3.3 Ash-specific: generating those migrations on the host

AshSqlite's generator writes to the same place Mob expects. Default snapshot/migration paths
(`ash_sqlite-0.2.17/lib/migration_generator/migration_generator.ex:178,839-851`):

```elixir
config[:priv] || "priv/"                                             # snapshots
config[:priv] || "priv/#{repo |> Module.split() |> List.last() |> Macro.underscore()}"  # migrations
```

For `Kati.Repo` that is `priv/repo/migrations` — **already what Mob pushes**. Snapshots land
in `priv/resource_snapshots/repo/`.

Host workflow (`ash_sqlite-0.2.17/documentation/topics/development/migrations-and-tasks.md`):

```
mix ash.codegen --dev            # iterate without naming migrations
mix ash.migrate                  # apply locally
mix ash.codegen add_habits       # squash dev migrations into a named one when the feature lands
```

⚠️ `priv/resource_snapshots/` **must be committed** — it is the diff base. Losing it makes the
next `ash.codegen` emit a full recreate.

### 3.4 🔴 The blocker nobody mentions: `config/*.exs` is NOT loaded on device

`mob_dev/lib/mob_dev/adopt/patcher.ex:364-366` states it flatly:

> "…are embedded directly because **Mix config files (`config/*.exs`) are not loaded on-device
> — `Application.put_env/3` is the only way to configure** the endpoint before
> `ensure_all_started/1` runs."

Confirmed three independent ways:

1. The BEAM launcher passes **no `-config`**. `mob/android/jni/mob_beam.zig:388-429` builds
   argv as `-root … -bindir … -progname erl -- -noshell -noinput -boot
   {otp_root}/releases/29/start_clean -pa … -eval "{app}:start()."`. `start_clean` carries no
   application env.
2. The erl bootstrap starts only three apps
   (`mob_new-0.4.20/priv/templates/mob.new/src/app_name.erl.eex:7-13`):
   ```erlang
   start() ->
       step(1, fun() -> application:start(compiler) end),
       step(2, fun() -> application:start(elixir)   end),
       step(3, fun() -> application:start(logger)   end),
       step(4, fun() -> mob_nif:platform()          end),
       step(5, fun() -> 'Elixir.MyApp.App':start()  end),
   ```
3. Mix does not bake `config/*.exs` into `.app` files — I checked a compiled dep's
   `_build/dev/lib/*/ebin/*.app`: **no `{env, …}` key**.

**What this means for Ash:**

- `config :kati, :ash_domains, [...]` is read **only at build time on the host** by
  `mob_ash`'s generator (`mob_ash/lib/mob_ash/generator.ex:21` →
  `MobDev.Plugin.host_config/3`, audited against `host_config_keys`). At *runtime* on device
  it is nil. That's fine if you never call `Ash.Info.domains/0` /
  `Ash.Domain.Info` reflection at runtime — resources carry their `domain:` at compile time.
- **Anything you `config :ash, …` is dead on device unless it is `compile_env`.** Good news:
  most of Ash's tunables are compile-time. `ash-3.31.3` uses `Application.compile_env` for
  `:custom_types`, `:custom_expressions`, `:default_belongs_to_type`,
  `:require_atomic_by_default?`, `:show_sensitive?`, `Ash.Type.UUIDv7` matching, etc.
  (`lib/ash/type/registry.ex:43`, `lib/ash/filter/filter.ex:69`,
  `lib/ash/resource/transformers/belongs_to_attribute.ex:16`, …). Those bake in at host
  compile time and ship correctly.
- Runtime `Application.get_env(:ash, …)` reads all have safe defaults, so nothing crashes —
  but you should **explicitly set the ones you care about in `on_start/0`**:

  ```elixir
  Application.put_env(:ash, :disable_async?, true)      # belt-and-braces; AshSqlite already says async_engine: false
  Application.put_env(:ash, :missed_notifications, :ignore)
  ```
  (`ash/lib/ash/actions/read/async_limiter.ex:29`, `ash/lib/ash/actions/helpers.ex:493`.)
- **Repo config must live in `init/2`, not `config/*.exs`** — which is why §2.3's `init/2`
  override is mandatory, not stylistic.
- Same trap already bites Mob itself: `config :mob, :repo, MyApp.Repo` in the generated
  `config/config.exs:10` is read at runtime via `Application.get_env(:mob, :repo)`
  (`mob/lib/mob/screen_state.ex:101`) and "**All functions are silent no-ops when no Repo is
  configured**". So `Mob.ScreenState` persistence is probably silently dead on device unless
  you `Application.put_env(:mob, :repo, Kati.Repo)` in `on_start/0`. **Do that.**

### 3.5 Migrating a user's existing DB across app updates

This is **solved and is the strongest part of the story**:

- The DB file lives in `getFilesDir()` / `NSDocumentDirectory`, which **survive app updates**
  (`repo.ex.eex:10-11`: "app-private, survives updates").
- `Ecto.Migrator.run(repo, dir, :up, all: true)` runs on **every boot** and is idempotent —
  the `schema_migrations` table lives in the same user DB, so v1.4 booting on a v1.0 database
  applies exactly the missing migrations.
- New migrations ship inside the APK's `priv/repo/migrations` (release path:
  `mob_dev/lib/mob_dev/release_android.ex:8-10` — "App `priv/` → `{app_name}/priv/`").
- Android release re-extracts `otp.zip` keyed on `PackageInfo.lastUpdateTime`
  (`mob_dev/lib/mob_dev/otp_asset_bundle.ex:24-26`), so new migration files land on update.

⚠️ **SQLite `ALTER TABLE` limits still apply.** Mob's guide warns:
> "**Limited `ALTER TABLE`** — SQLite cannot drop or rename columns in older versions. Write
> migrations that add columns or recreate tables instead." (<https://mob.hexdocs.pm/data.html>)

Ash's migration generator will happily emit a rename; **review every generated migration
before shipping**, per AshSqlite's own warning ("Always review migrations before applying
them").

⚠️ **Boot-order requirement**: because Ash actions hit the Repo, the Repo + migrations must be
up *before* `Mob.Screen.start_root/1`. The generated `on_start/0` already orders it that way.
Your `on_start/0` becomes:

```elixir
def on_start do
  Mob.DNS.configure_pure_beam()

  Application.put_env(:mob, :repo, Kati.Repo)
  Application.put_env(:ash, :disable_async?, true)

  {:ok, _} = Application.ensure_all_started(:ecto_sqlite3)
  {:ok, _} = Application.ensure_all_started(:ash)   # see §6.3 — pulls in :mnesia
  {:ok, _} = Kati.Repo.start_link()

  Ecto.Migrator.with_repo(Kati.Repo, fn repo ->
    Ecto.Migrator.run(repo, migrations_dir(), :up, all: true)
  end)

  Mob.Screen.start_root(Kati.HomeScreen)
  Mob.Dist.ensure_started(node: :"kati_android@127.0.0.1", cookie: :mob_secret)
end
```

---

## 4. AshOban / Oban on device

### 4.1 Oban itself: SQLite is supported

`oban` 2.23.1 declares `ecto_sqlite3 ~> 0.9` **optional**
(<https://hex.pm/api/packages/oban/releases/2.23.1>) and ships a dedicated engine,
`oban-2.23.1/lib/oban/engines/lite.ex:1-14`:

```elixir
defmodule Oban.Engines.Lite do
  @moduledoc """
  An engine for running Oban with SQLite3.

      Oban.start_link(engine: Oban.Engines.Lite, queues: [default: 10], repo: MyApp.Repo)
  """
```

with `oban-2.23.1/lib/oban/migrations/sqlite.ex` providing the schema. So **Oban would run**
on a Mob device BEAM in principle: it is pure Elixir + Ecto, needs a supervisor (which Mob
lets you start in `on_start/0`), and its notifier would have to be `Oban.Notifiers.PG`
(Postgres `LISTEN/NOTIFY` is obviously unavailable).

### 4.2 AshOban: **not viable**

`ash_oban` 0.8.12 requirements (<https://hex.pm/api/packages/ash_oban/releases/0.8.12>):

```
ash      ~> 3.0 and >= 3.8.0   REQUIRED
oban     ~> 2.20               REQUIRED
postgrex ~> 0.18               REQUIRED     <-- not optional
```

Confirmed in `ash_oban-0.8.12/mix.exs` — `{:postgrex, "~> 0.18"}` sits in the unconditional
list, not behind `only: [:dev, :test]`. And a full-text grep of the package for
`sqlite`/`Engines.Lite` returns **zero hits**.

So AshOban would (a) drag the entire Postgres wire driver into your APK for nothing, and
(b) is untested against `Oban.Engines.Lite`. **Do not use AshOban.**

### 4.3 What happens when the OS kills the app

Oban's durability model assumes a **server process that is always running**. On a phone it is
not. Concretely:

- Jobs already `INSERT`ed into `oban_jobs` survive — that's SQLite, and per Mob's data guide
  writes are durable.
- **Jobs `executing` when the process dies are stranded.** Oban recovers those via its
  `Stager`/rescue plugins, which only run *while Oban is running*. On a phone the app can be
  dead for days. `Oban.Plugins.Lifeline` (rescue) would only fire on the next launch —
  meaning "background job" really means "job that runs next time the user opens the app."
- Kati's real background needs (calendar reminders, habit nudges) are **wall-clock events
  while the app is not running** — that is an OS scheduling problem, not a queue problem.
  Mob's answer is `mob_notify` ("Local notification scheduling + push registration",
  <https://mob.hexdocs.pm/packages.html>) plus the background-execution guide
  (<https://mob.hexdocs.pm/background_execution.html>); see `mob-framework.md` §on
  notifications for the details. Prior research also records that the docs advise
  *"Persist enough state locally with `Mob.State` or SQLite to resume after suspension or
  cold start"* (mob-framework.md:1057-1059).
- Oban's staging loop polls the DB on an interval. On a `pool_size: 1` SQLite connection that
  is a background writer competing with your UI reads, and a battery draw, for a queue that
  will almost always be empty.

### 4.4 Recommendation

**Use a simple in-app scheduler, not Oban.**

```
Kati.Jobs.Job          — an Ash resource (AshSqlite): kind, payload (:map),
                         run_at (:utc_datetime_usec), attempts, state, last_error
Kati.Jobs.Runner       — a GenServer started in on_start/0; on boot and on
                         Mob.Device :did_become_active, reads due jobs and runs them
mob_notify             — for anything that must fire while the app is dead
```

This is ~150 lines, has no Postgres driver, no polling loop, no `oban_jobs`/`oban_peers`
tables, and matches the actual lifecycle: *"do the work when the app is next alive."* You keep
Ash for the job resource, so retries/state transitions can be `AshStateMachine` if you want
them declarative.

Revisit Oban only if you ever add a long-running foreground sync (e.g. the Google Calendar
two-way sync) with genuinely concurrent work — and even then, a `Task.Supervisor` +
`:queue` in an Ash resource is likely enough.

---

## 5. Which Ash extensions are realistic on device

Requirements pulled from the Hex API for each package's latest release.

| Extension | Latest | Hard deps | On a Mob device? |
|---|---|---|---|
| **AshSqlite** | 0.2.17 | `ecto_sqlite3 ~> 0.12`, `ash_sql`, `ecto_sql` | ✅ **The point of the exercise.** Pure Elixir on top of the exqlite Mob already ships. Mind §2.4. |
| **AshStateMachine** | 0.2.13 | `ash ~> 3.0` **only** | ✅ **Best fit after the data layer.** Zero extra deps, compile-time DSL. Ideal for Kati's habit/task/watch statuses and for the calendar-sync state (`local → pending_push → synced → conflict`). |
| **AshArchival** | 2.0.3 | `ash ~> 3.0` **only** | ✅ **Recommended.** Soft-delete via an `archived_at` attribute — exactly right for a personal app where "delete" should be undoable and for sync tombstones (you need to remember a deletion to push it to Google Calendar). No extra tables. |
| **AshPaperTrail** | 0.6.0 | `ash ~> 3.5` **only** | ⚠️ **Possible, expensive.** Creates a mirror `*_versions` resource **per versioned resource** in the same data layer → doubles table count and write volume on a `pool_size: 1` SQLite file, and grows the DB unboundedly on a device with no server-side pruning. Use on **at most** the 1–2 resources where an audit trail is a product feature (e.g. money transactions). Do not blanket-apply. |
| **AshCloak** | 0.3.1 | `ash ~> 3.26` (you supply the `Cloak` vault) | ⚠️ **Security theatre on Mob today.** Prior research (`mob-framework.md`) established: *"Encryption at rest: none. No SQLCipher, no keychain/keystore, no encrypted storage anywhere in Mob… `Mob.State`'s DETS file and the SQLite DB are plaintext in the app sandbox."* AshCloak encrypts columns with a key that has nowhere safe to live — it would sit in the same plaintext sandbox. Only worth it if/when you add a Keystore/Keychain NIF. For Kati (open-source, no server, no OAuth token yet) skip it; revisit for the Google Calendar refresh token. |
| **AshPhoenix** | 2.3.24 | `phoenix`, `phoenix_html`, **`phoenix_live_view`** — all REQUIRED | ❌ **Pointless for native Mob screens.** Mob screens are GenServers rendering Elixir maps → JSON → Compose/SwiftUI (`mob-framework.md` §1); there is no LiveView socket and no HTML. `AshPhoenix.Form` is bound to `Phoenix.HTML.Form`. Drags Phoenix + LiveView + Plug into the APK for nothing. **Write your own form state in screen assigns** and call `Ash.Changeset.for_create/3` + `Ash.create/1` directly (that is exactly what `mob_ash/lib/mob_ash/form_screen.ex:44` does). *Caveat:* if you ever use Mob's `--liveview` WebView mode for a sub-surface, AshPhoenix becomes relevant there — but that mode contradicts "62 native screens". |
| **AshGraphql** (1.10.0) / **AshJsonApi** (1.7.1) | — | Absinthe / Plug + an HTTP server | ❌ **Actively wrong.** These expose your data over a network API. Kati is device-first with **no server** and no clients. Pure APK bloat and an attack surface on a device you don't want listening. |
| **AshAuthentication** | 5.0.0-rc.12 | `assent`, `bcrypt_elixir` (**Rust/C NIF**), `finch`, `castore`, `joken`, `nimble_totp`, `plug` — all REQUIRED | ❌ **No.** Kati is single-user, no server, no accounts. Beyond being unnecessary, `bcrypt_elixir` is a **native NIF that Mob does not cross-compile** — you would have to add it to the zig/CMake build yourself (`mix mob.add_nif`), for password hashing you don't need. If you later add a device PIN/biometric lock, use `mob_biometric` (iOS working; *"Android currently reports `:not_available` (fix tracked)"* — <https://mob.hexdocs.pm/packages.html>) plus a locally hashed PIN, not AshAuthentication. |
| **AshOban** | 0.8.12 | `oban`, **`postgrex` (REQUIRED)** | ❌ See §4. |
| **AshAdmin, AshAi, AshCsv, AshDoubleEntry…** | — | web / network | ❌ Dev-machine only at best. |

**Shortlist for Kati:** `ash`, `ash_sqlite`, `ash_state_machine`, `ash_archival`. Optionally
`ash_paper_trail` on the money resources only. Everything else stays out of the APK.

---

## 6. Binary size and boot time — measured

### 6.1 What I measured (real numbers, this machine)

Ash **3.29.3** compiled at `/Users/shahryar/Documents/Programming/Elixir/guarded_struct/_build/dev/lib/ash/ebin`,
then `:beam_lib.strip_files/1` (which is what Mob's release does — see §6.2), then zipped:

| Package | BEAM modules | ebin (dev, w/ debug_info) | after strip | zipped (what ships) |
|---|---:|---:|---:|---:|
| **ash 3.29.3** | **1 299** | **24.2 MB** | **7.6 MB** | **4.53 MB** |
| reactor 1.0.2 (required by ash) | 245 | — | 1.26 MB | 0.70 MB |
| ecto 3.14.0 | 102 | — | 0.60 MB | 0.37 MB |
| spark 2.7.2 | 49 | — | 0.32 MB | 0.23 MB |
| **subtotal (measured)** | **1 695** | — | **~9.8 MB** | **~5.8 MB** |

Not measured (no local compiled copy): `ash_sqlite`, `ash_sql`, `ash_state_machine`,
`ash_archival`, `splode`, `ets`, `stream_data`, `crux`, `decimal`, `jason`, `telemetry`.
`ash_sqlite`'s `lib/data_layer.ex` alone is 61.5 KB of source; a reasonable extrapolation for
the remainder is **+0.7–1.5 MB compressed**.

**Realistic APK delta for going Ash-first: ≈ +6.5–7.5 MB compressed**, on top of an
`ecto_sqlite3`-only baseline. Against Mob's own claimed *"~25 MB per-device binary"*
(repo/forum, not the guides — see `mob-framework.md:857`) that is roughly **+25–30 %**.

Two things that make it less bad than it looks:

- **BEAM files are architecture-independent.** They ship once in `assets/otp.zip`, not per
  ABI. Only `libsqlite3_nif.so` / `lib<app>.so` are multiplied across
  `arm64-v8a / armeabi-v7a / x86_64`.
- **Mob strips debug chunks in release builds.** `mob_dev/lib/mob_dev/otp_asset_bundle.ex:146,162`:
  `~s|catch beam_lib:strip_release("#{staging}"), erlang:halt(0).|`, and
  `mob_dev/lib/mob_dev/otp_audit/slim.ex:21`: *"`:beam_lib.strip_release/1` drops Debug/Doc"*.
  So the 24 MB dev figure never ships.

Cost that *is* doubled: the APK carries `otp.zip`, and `MobBridge.extractOtpIfNeeded()`
unzips it into `<filesDir>/otp/` on first launch
(`mob_dev/lib/mob_dev/otp_asset_bundle.ex:23-26`). So Ash costs **~6.5 MB in the download
plus ~10 MB of the user's storage**, and the first-launch extraction gets slower.

### 6.2 Boot time — **UNKNOWN. I could not measure this honestly.**

I tried. Loading all 1 299 Ash modules on this host took 12.6 s via `:code.load_binary/3` and
32 s via `:code.ensure_loaded/1`. **Those numbers are worthless**: a control run loading 300
*stdlib* modules on the same machine took 2.54 s (**8.5 ms/module**), which is 5–10× slower
than a healthy BEAM. The sandbox's filesystem interception dominates the measurement. I am
reporting this so nobody re-derives the same bad number.

What can be said with evidence:

- **Ash does no work at boot.** `ash.app` has **no `{mod, …}` entry** — there is no
  application callback module and no supervision tree. Starting `:ash` starts nothing.
- **Ash's cost is compile-time, not boot-time.** Spark DSL + transformers + verifiers all run
  during `mix compile` on your Mac. On device, `Ash.Resource.Info` reads persisted module
  attributes.
- **Module loading is lazy and demand-driven.** Only the Ash modules a given code path touches
  get loaded. A first `Ash.read!/1` will pull in a meaningful slice of
  `Ash.Actions.Read.*`, `Ash.Query.*`, `Ash.Filter.*`, `AshSql.*`, `Ecto.*` — plausibly
  200–400 modules. That is a **one-time first-query cost**, not a per-boot cost, and it lands
  on whatever screen queries first.
- **Practical mitigation**, since Mob's docs already care about cold start: show the root
  screen first, then do the first Ash query in a `handle_continue`/`Task` so module loading
  overlaps with the first frame rather than blocking it. Do **not** eagerly force-load Ash.
- **Mob ships a real tool to check this**: `mix mob.verify_strip` "connect[s] to the running
  app's BEAM and asks it to force-load every `.beam` shipped in the bundle"
  (`mob_dev/lib/mix/tasks/mob.verify_strip.ex:5-30`). Run it after the first Ash build — it
  will also catch "Ash module X depends on stripped OTP lib Y".

**Published numbers for Ash on a mid-range Android phone: none exist.** Nobody has published
them because (per §2.5) nobody has publicly done this.

### 6.3 ⚠️ `:ash` pulls in `:mnesia`

`ash-3.31.3/mix.exs`:

```elixir
def application do
  [extra_applications: [:mnesia]]
end
```

and the compiled `ash.app` `applications` list starts
`[kernel, stdlib, elixir, mnesia, spark, ecto, ets, decimal, jason, telemetry, reactor, …]`.

So `Application.ensure_all_started(:ash)` **starts `:mnesia`** on the device — for
`Ash.DataLayer.Mnesia`, which you will never use. Mnesia wants a writable `dir`. Mob's OTP
strip list (`mob_dev/lib/mob_dev/otp_asset_bundle.ex:48-53`) does *not* drop `mnesia`, so it
will be present. **Set `Application.put_env(:mnesia, :dir, String.to_charlist(Mob.data_dir()))`
in `on_start/0` before starting anything**, or verify that skipping
`ensure_all_started(:ash)` entirely works (Ash has no `mod`, so nothing *needs* starting —
but its deps `:ecto`/`:telemetry` do). Test both on device.

Also note `stream_data ~> 1.0` is a **REQUIRED** (not test-only) dep of `ash` — a property-
testing library shipped to end users' phones. Nothing you can do about it; just know it's in
the 4.5 MB.

---

## 7. Recommended project structure for an Ash-first Mob app

```
kati/
├── mix.exs                  # {:mob,…} {:mob_dev,…} {:ecto_sqlite3,"~> 0.18"}
│                            # {:ash,"~> 3.31"} {:ash_sqlite,"~> 0.2"}
│                            # {:ash_state_machine,"~> 0.2"} {:ash_archival,"~> 2.0"}
│                            # {:mishka_chelekom, …, only: :dev, runtime: false}
├── mob.exs                  # config :mob, :plugins, [:mob_notify, …]   (NOT :mob_ash)
├── config/config.exs        # HOST-ONLY. Mix tasks read it; the device never does. (§3.4)
│
├── lib/kati/
│   ├── app.ex               # use Mob.App — navigation/1 + on_start/0 (§3.5)
│   ├── repo.ex              # use AshSqlite.Repo + init/2 → super/2 (§2.3)
│   │
│   ├── calendar/            # ── DOMAIN: one dir per bounded context
│   │   ├── calendar.ex      #    defmodule Kati.Calendar do use Ash.Domain
│   │   ├── event.ex         #    use Ash.Resource, domain: Kati.Calendar,
│   │   ├── recurrence.ex    #                      data_layer: AshSqlite.DataLayer
│   │   └── sync_state.ex    #    (AshStateMachine for the Google two-way sync)
│   ├── media/               #    films, tv, books, music
│   ├── health/
│   ├── money/
│   ├── habits/
│   └── shared/
│       ├── jalali.ex        # PURE display-layer Gregorian↔Shamsi; NEVER a DB concern
│       └── jobs/            # runner.ex + job.ex (§4.4)
│
├── lib/kati_ui/             # ── SCREENS: 62 of them, mirroring design-index.md
│   ├── components/          #    Mishka Chelekom OUTPUT (generated, committed, edited)
│   ├── calendar/month_screen.ex
│   ├── media/film_detail_screen.ex
│   └── …
│
├── priv/repo/migrations/    # ash.codegen output — pushed to device by mob_dev
├── priv/resource_snapshots/ # ash.codegen diff base — MUST be committed
└── test/
    ├── kati/…               # domain tests: plain ExUnit, no device, no Mob
    └── kati_ui/…            # screen tests: Mob.ScreenCase
```

### 7.1 How screens read/write resources

Directly. No `AshPhoenix`, no `mob_ash` screens. A Mob screen is a GenServer with
`mount/3`, `render/1`, `handle_event/3` (`mob/lib/mob/screen.ex:50-53`), so:

```elixir
defmodule KatiUI.Money.LedgerScreen do
  use Mob.Screen

  @impl true
  def mount(%{month: month}, _session, socket) do
    txns =
      Kati.Money.Transaction
      |> Ash.Query.filter(occurred_on >= ^Date.beginning_of_month(month))
      |> Ash.Query.sort(occurred_on: :desc)
      |> Ash.read!()

    # no resource aggregates in AshSqlite (§2.4) — use a query aggregate
    total = Ash.count!(Kati.Money.Transaction, query: month_query(month))

    {:ok, socket |> assign(:txns, txns) |> assign(:total, total)}
  end

  @impl true
  def handle_event("save", _p, socket) do
    case Kati.Money.Transaction
         |> Ash.Changeset.for_create(:create, socket.assigns.form)
         |> Ash.create() do
      {:ok, _}      -> {:noreply, Mob.Socket.pop_screen(socket)}
      {:error, err} -> {:noreply, assign(socket, :error, Ash.Error.to_error_class(err))}
    end
  end
end
```

Two rules that fall out of the research:

1. **Persian/Shamsi and RTL never touch Ash.** Attributes stay `:date` / `:utc_datetime_usec`
   (Gregorian/UTC). `Kati.Shared.Jalali` converts at render time only. This also sidesteps
   SQLite's lack of a real date type.
2. **Money is `:decimal`, not float.** `decimal` is already a required Ash dep; ecto_sqlite3
   stores it as text/numeric. Verify round-tripping on device in the day-one spike.

### 7.2 Keeping the domain testable on the host — this is the big architectural win

Ash's payoff on Mob is precisely that **all your business logic is device-independent**.

- `lib/kati/**` has **zero `Mob.*` references**. It compiles and tests under plain `mix test`
  on your Mac against the same `AshSqlite` data layer, with the Repo's `init/2` falling back
  to `$HOME`/cwd when `MOB_DATA_DIR` is unset (`Mob.data_dir/0`, `mob/lib/mob.ex:66-70`) — so
  the *same* migrations and the *same* SQLite file format are exercised on host and device.
- `mob_ash`'s own author made the same call — `mob_ash/lib/mob_ash/info.ex:2-6`:
  > "Pure Ash-introspection helpers … Kept public + side-effect free so the resource→UI
  > mapping is **unit-testable without a device** (and without mob_dev)."
- Screens get tested with `Mob.ScreenCase` (`mob-framework.md`), which is a separate, thinner
  test suite.
- Practical target: **~90 % of Kati's test suite should run in `mix test` with no emulator.**
  The device tests then only need to prove: (a) the NIF loads, (b) migrations run, (c) render
  output looks right, (d) MOB_DATA_DIR persistence survives a kill.

### 7.3 Migration/codegen loop

```
# host, iterating
mix ash.codegen --dev && mix ash.migrate && mix test

# host, feature done
mix ash.codegen add_habit_streaks     # squashes dev migrations
git add priv/repo/migrations priv/resource_snapshots

# device
mix mob.deploy --android              # pushes beams + priv/ (§3.2)
mix mob.verify_strip                  # after any dep change (§6.2)
```

---

## 8. Risks — the honest list

Ordered by how likely each is to hurt.

1. **🔴 `config/*.exs` is not loaded on device (§3.4).** This is the single most likely thing
   to produce a mystifying device-only failure. Ash, AshSqlite, Oban, and Mob's own
   `ScreenState` all read Application env at runtime. Mitigation is mechanical
   (`Application.put_env/3` in `on_start/0`) but it must be *known*, and it means "works on my
   Mac" proves less than usual. Mob's own generated `config/config.exs` sets
   `config :mob, :repo, …` that the device will never see.

2. **🔴 You would be the first public user of AshSqlite on a device BEAM (§2.5).** 176
   downloads of `mob_ash`, 0 GitHub stars, zero forum mentions, no Ash mention in Mob's own
   Data guide. Every claim in this document about *versions and code paths* is verified;
   nothing about *runtime behaviour on an Android phone* is. Bugs you hit will be yours to
   diagnose, in a one-maintainer framework (`mob-framework.md`: *"Maturity verdict: pre-1.0,
   API-unstable, effectively a one-person project"*, v0.7.0 was a hard breaking change with no
   compat shims).

3. **🟠 `can?(:transact) == false` (§2.4).** Ash's usual guarantee — "an action is atomic" —
   does not hold. Any multi-resource operation in Kati (log a workout and its sets; import a
   calendar batch; record a transaction and update a budget) needs a hand-rolled
   `Kati.Repo.transaction/1`. This is easy to forget precisely *because* Ash normally handles
   it, and the failure mode is a half-written record after a crash or an OS kill mid-action.

4. **🟠 No resource aggregates, no `distinct` (§2.4).** Kati is full of "total spend this
   month", "days in a row", "books finished this year". These become per-screen query
   aggregates or calculations rather than declarative resource fields — more code, and no
   `load: [:total]` convenience. Design around it from day one; retrofitting is painful.

5. **🟠 +6.5–7.5 MB APK / ~10 MB device storage (§6.1), for an app whose data layer is one
   SQLite file.** For an open-source personal app distributed as an APK on GitHub that's
   acceptable. But the honest framing is: *Ash costs roughly a third again of Mob's entire
   runtime, to replace what plain Ecto schemas already do on the same SQLite file.* If Kati's
   62 screens turn out to be mostly straightforward CRUD, that spend buys policies,
   calculations, and state machines you might not use. Ash earns its size if you lean on
   `AshStateMachine` for sync, calculations for Shamsi/derived fields, and a uniform action
   surface across seven domains — which is a real, defensible bet, just not a free one.

6. **🟠 `:ash` starts `:mnesia` (§6.3).** An unused disk-backed DB engine starting on a phone,
   defaulting to a `dir` that may not be writable. Cheap to fix, easy to miss, and the failure
   would be at boot.

7. **🟡 Compile times.** Spark + Ash transformers/verifiers run on every resource change. With
   seven domains and (say) 25 resources, expect the host compile loop to get noticeably
   slower — and Mob's dev loop (`mix mob.watch`, hot push) sits on top of it. This is
   friction on *your* iteration speed, not on the user's device.

8. **🟡 `mob_ash` will rot if you depend on it.** It targets `mob ~> 0.7`, was last released
   2026-06-16, and mob shipped 0.7.20 on 2026-07-11 with a fast patch cadence (~every 1–3
   days). Its manifest declares `mob_version: "~> 0.6"`. The docs describe a version that
   doesn't exist (§1.4). **Not depending on it removes this risk entirely** — which is the
   main reason to skip it.

9. **🟡 Migration path resolution is contradictory in Mob's own sources (§3.2).** The guide
   says `:code.priv_dir/1` works; the generated code says it returns `{error, bad_name}` and
   that the failure is *silent*. My host experiment suggests it does work with Mob's current
   directory layout, but "silent, tables never created, screen appears frozen" is a bad enough
   failure to warrant the explicit `MOB_BEAMS_DIR` path plus a first-boot assertion that the
   expected tables exist.

10. **🟡 No encryption at rest, anywhere (`mob-framework.md`).** The SQLite file is plaintext
    in the app sandbox. Fine for films and books; a real consideration for health data, money
    data, and (later) a Google Calendar refresh token. AshCloak does **not** solve it (§5) —
    it needs a keystore Mob doesn't have.

11. **🟢 iOS is a different build path for the SQLite NIF (§2.1)** — statically linked into the
    BEAM via `driver_tab_ios.zig` rather than a `.so`. Since Android is the priority and iOS
    is later, the risk is deferred, but the iOS path is exercised by fewer people. Also recall
    the `MOB_BEAMS_DIR`-is-read-only-on-iOS trap that "stays hidden until an app ships to iOS"
    (`mob/lib/mob.ex:55-58`).

### Bottom line

Ash on Mob **works, is officially blessed, and is the right shape for a 7-domain personal
app** — the domain layer becomes pure, host-testable Elixir and the device becomes a rendering
concern. The decision is defensible.

But treat it as **`ash` + `ash_sqlite` used directly**, not as "the mob_ash integration".
Budget a **day-one device spike** that proves, in order: (1) the app boots with `:ash` started
and `:mnesia` behaving, (2) `Ecto.Migrator` actually creates AshSqlite's tables on device,
(3) one `Ash.create!/1` + `Ash.read!/1` round-trips a `:decimal` and a `:utc_datetime_usec`,
(4) the data survives an app kill and an app update, (5) `mix mob.verify_strip` is clean.
If those five pass, the rest is ordinary Ash work.

---

## Appendix — key file references

| Claim | Source |
|---|---|
| `mob_ash` is pre-trusted in every generated app | `mob_new-0.4.20/priv/templates/mob.new/mob.exs.eex:40` |
| No `--ash` flag | `mob_new-0.4.20/lib/mix/tasks/mob.new.ex:125-134` |
| `ecto_sqlite3` is an unconditional dep | `mob_new-0.4.20/priv/templates/mob.new/mix.exs.eex:25` |
| Ash runs on-device, first heavyweight runtime dep | `mob_ash/mix.exs:42-46` |
| mob_ash manifest (spec v2, no native) | `mob_ash/priv/mob_plugin.exs` |
| mob_ash screens (list/detail/form only) | `mob_ash/lib/mob_ash/{list,detail,form}_screen.ex` |
| Form types limited to 4 scalars | `mob_ash/lib/mob_ash/info.ex:38-49` |
| Docs' richer mob_ash spec (not shipped) | <https://mob.hexdocs.pm/mob_plugins.html> §"Code-generated plugins" |
| mob_ash listed as the only framework integration | <https://mob.hexdocs.pm/packages.html> |
| Android exqlite compiled from C per-ABI | `mob_new-0.4.20/priv/templates/mob.new/android/app/src/main/jni/build.zig.eex:376-425` |
| Android ABIs | `.../android/app/build.gradle.eex:47` |
| iOS static sqlite3_nif | `mob/ios/driver_tab_ios.zig:69-146` |
| iOS ships no exqlite BEAMs | `mob_dev/lib/mix/tasks/mob.release.tarball.ex:14` |
| Runtime symlink of the NIF into `priv/` | `mob/android/jni/mob_beam.zig:587-660` |
| `MOB_DATA_DIR` / `Mob.data_dir/0` | `mob/lib/mob.ex:46-70`; `mob_new/.../repo.ex.eex:8-22` |
| Boot migration pattern + `MOB_BEAMS_DIR` | `mob_new/.../app.ex.eex:25-29, 71-95` |
| Deployer priv push + chmod trap | `mob_dev/lib/mob_dev/deployer.ex:488-540` |
| Release stages app+deps beams flat, priv alongside | `mob_dev/lib/mob_dev/release_android.ex:1-30, 97-155` |
| `beam_lib:strip_release` in release | `mob_dev/lib/mob_dev/otp_asset_bundle.ex:146,162` |
| No `-config`; `start_clean` boot | `mob/android/jni/mob_beam.zig:367-429` |
| Only compiler/elixir/logger started | `mob_new/.../src/app_name.erl.eex:7-13` |
| "config/*.exs are not loaded on-device" | `mob_dev/lib/mob_dev/adopt/patcher.ex:364-366` |
| `Mob.ScreenState` reads repo at runtime | `mob/lib/mob/screen_state.ex:101` |
| `Mob.Plugins` reads manifest via `:code.priv_dir/1` | `mob/lib/mob/plugins.ex:436-441` |
| AshSqlite capability matrix | `ash_sqlite-0.2.17/lib/data_layer.ex:444-514` |
| AshSqlite transactions disabled | `ash_sqlite-0.2.17/documentation/topics/about-ash-sqlite/transactions.md` |
| AshSqlite "main feature missing is Aggregate support" | `.../about-ash-sqlite/what-is-ash-sqlite.md` |
| `AshSqlite.Repo` defines `init/2`, requires `super` | `ash_sqlite-0.2.17/lib/repo.ex:11-13, 57-66` |
| Migration/snapshot default paths | `ash_sqlite-0.2.17/lib/migration_generator/migration_generator.ex:178, 839-851` |
| `:ash` has no `mod`, `extra_applications: [:mnesia]` | `ash-3.31.3/mix.exs`; compiled `ash.app` |
| Ash compile-time vs runtime config | `ash/lib/ash/type/registry.ex:43`, `lib/ash/filter/filter.ex:69`, `lib/ash/actions/read/async_limiter.ex:29` |
| Oban SQLite engine | `oban-2.23.1/lib/oban/engines/lite.ex:1-14`; `lib/oban/migrations/sqlite.ex` |
| AshOban requires postgrex | <https://hex.pm/api/packages/ash_oban/releases/0.8.12>; `ash_oban-0.8.12/mix.exs` |
| Extension dep sets | Hex API `releases/<vsn>` for each package |
| Forum thread has no Ash mentions | <https://elixirforum.com/t/mob-native-beam-elixir-on-native-mobile/74924> (pp. 1–2) |
