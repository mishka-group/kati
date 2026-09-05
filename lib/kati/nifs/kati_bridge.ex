defmodule Kati.Nifs.KatiBridge do
  @moduledoc """
  The statically-linked NIF that reaches the `MobBridge` statics Kati added.

  Scaffolded by `mix mob.add_nif kati_bridge --type c`; the native body is
  `c_src/kati_bridge.c`, and `kati_bridge_nif_init` is registered in
  `priv/generated/driver_tab_{android,ios}.zig`.

  ## Why this module exists at all

  `:mob_nif`'s function table lives inside the `mob` hex package. Kati has
  written four bridge features into `MobBridge.kt` — the credential store, the
  file transport, notification arming, the periodic worker — and none of them
  was reachable from Elixir, because there was no entry in that table and Kati
  does not fork Mob. `mix mob.add_nif` is mob_dev's supported answer: a
  project-owned NIF, statically linked into the same binary, that can call
  anything on the app's own bridge class.

  `MobBridge.notify_schedule/2` is the clearest illustration. It has existed
  since `K-01 notify-persist`, it is correct, it persists across reboot — and
  until this module it had **no caller**, which is why the only notification
  delivery backend Kati shipped was `Kati.Notifications.Delivery.Inert`.

  ## Nobody should call this module

  The surfaces are `Kati.Native.Files`, `Kati.Notifications.Delivery.Android`
  and `Kati.Background.Periodic`. Everything here is marshalling.

  ## Two reply shapes

    * **Synchronous** — `notify_arm/1`, `notify_cancel/1`, `notify_status/0`,
      `periodic_ensure/1`, `periodic_cancel/0` return the bridge's own reply:
      `"ok"`, `"ok:<payload>"` or `"error:<reason>"`.

    * **Asynchronous** — `file_save_as/1` and `file_share/1` put a system UI in
      front of the user. Their return value says only whether the call reached
      Kotlin; the outcome arrives later as a message to the **calling process**,
      through mob's own `mob_deliver_file_result` hook:

          {:kati_files, :saved,  [%{path: ..., bytes: ..., uri: ...}]}
          {:kati_files, :shared, [%{}]}
          {:kati_files, :error,  [%{reason: "..."}]}
          {:kati_files, :cancelled}

      A NIF that blocked a scheduler thread until a human finished choosing a
      folder is not an option, so "the call got through" and "the file was
      saved" are two different answers and this module only gives the first.
      `Kati.Native.Files.decode/1` turns the second into a value.

  See `Kati.Nifs.KatiSecureStore` for why a failed load is swallowed rather
  than raised — the same reasoning applies here, and unbound every function
  below raises `:erlang.nif_error(:nif_not_loaded)`.
  """

  @on_load :load_nif

  @doc false
  def load_nif do
    _ = :erlang.load_nif(~c"kati_bridge", 0)
    :ok
  end

  @doc """
  `"ok"` when this NIF is bound and the bridge class was cached in
  `JNI_OnLoad`, `"error:<reason>"` otherwise.

  Its own function on purpose: every other entry point here arms, enqueues or
  opens a dialog, so probing with one of them would have a side effect — and in
  `file_save_as/1`'s case would deliver a spurious error message to whichever
  process asked the question.
  """
  @spec available() :: binary()
  def available, do: :erlang.nif_error(:nif_not_loaded)

  # ── #64: file transport ─────────────────────────────────────────────────

  @doc """
  Open ACTION_CREATE_DOCUMENT for the file described by `json`.

  `%{"path" => ..., "name" => ..., "mime" => ...}` encoded. Returns `"ok"` when
  the intent was launched; the save itself reports back as a message.
  """
  @spec file_save_as(binary()) :: binary()
  def file_save_as(_json), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Open ACTION_SEND for the file described by `json`, through a FileProvider URI.
  """
  @spec file_share(binary()) :: binary()
  def file_share(_json), do: :erlang.nif_error(:nif_not_loaded)

  # ── #58: notification arming ────────────────────────────────────────────

  @doc """
  Arm one alarm. `json` carries `id`, `title`, `body`, `trigger_at` (epoch
  seconds) and an optional `data` object. Arming an id that is already armed
  replaces it.
  """
  @spec notify_arm(binary()) :: binary()
  def notify_arm(_json), do: :erlang.nif_error(:nif_not_loaded)

  @doc "Cancel by id. Cancelling something not armed answers `\"ok\"`."
  @spec notify_cancel(binary()) :: binary()
  def notify_cancel(_id), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  `"ok:<pending>:<exact>:<permitted>"` — how many alarms the store holds,
  whether exact alarms may be scheduled, and whether notifications may be
  posted at all.
  """
  @spec notify_status() :: binary()
  def notify_status, do: :erlang.nif_error(:nif_not_loaded)

  # ── #9: reading a permission ────────────────────────────────────────────

  @doc """
  `"ok:granted"` or `"ok:denied:<rationale>"` for one capability.

  The read `Mob.Permissions` does not have. `rationale` is Android's
  `shouldShowRequestPermissionRationale`, which is false BOTH for a permission
  never asked for and one denied permanently — see `Kati.Permissions` for how
  the two are told apart.
  """
  @spec permission_status(binary()) :: binary()
  def permission_status(_capability), do: :erlang.nif_error(:nif_not_loaded)

  # ── D-62: opening a link the app does not own ───────────────────────────

  @doc """
  `"ok"`, or `"error:<reason>"`, for handing one URL to the platform browser.

  The capability fifteen drawn controls were waiting on — screen 83's six
  source cards and its notices row, 84's two, 85's four, and the three *Open
  system settings* pills. Each of them named a place and went nowhere, and
  `Kati.ScreenTapSweepTest` recorded the same sentence against every one:
  *Kati has no fence that opens an external link.*

  `http` and `https` only; the Kotlin side refuses everything else rather than
  becoming a way to launch arbitrary intents from a string.
  """
  @spec open_url(binary()) :: binary()
  def open_url(_url), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  `"ok"`, or `"error:<reason>"`, for opening one of the phone's own settings
  screens by Kati name — `"battery"`, `"notification_listener"`, `"app"`.

  A closed set rather than an action string, because `startActivity` with a
  caller-supplied action is a way to launch anything on the device from a
  string, and the strings in this app come from screens. `Kati.Native.Links`
  refuses non-http URLs for the same reason.
  """
  @spec open_settings(binary()) :: binary()
  def open_settings(_which), do: :erlang.nif_error(:nif_not_loaded)

  # ── #58: periodic refresh ───────────────────────────────────────────────

  @doc """
  Enqueue (or leave alone) the periodic refresh worker. `json` carries
  `interval_minutes` and `flex_minutes`.
  """
  @spec periodic_ensure(binary()) :: binary()
  def periodic_ensure(_json), do: :erlang.nif_error(:nif_not_loaded)

  @doc "Cancel the periodic refresh worker."
  @spec periodic_cancel() :: binary()
  def periodic_cancel, do: :erlang.nif_error(:nif_not_loaded)
end
