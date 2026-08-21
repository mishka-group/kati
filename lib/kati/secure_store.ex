defmodule Kati.SecureStore do
  @moduledoc """
  The only place a Kati credential is allowed to live.

  Everything else Kati persists — meals, watches, calendars — goes into the
  SQLite database or `Mob.State`, and **both are plaintext files in the app
  sandbox**. That is fine for a meal log. It is not fine for a CalDAV
  app-specific password or an OAuth refresh token, because those are
  credentials to the user's *account*, not to Kati: whoever holds one holds
  the user's whole calendar until the user notices and revokes it.

  Mob offers nothing here. Every "keystore" in the Mob packages is the
  build-time *signing* keystore; there is no iOS Keychain binding, no Android
  Keystore wrapper, no encrypted storage. So Kati brings its own — see
  `android/app/src/main/java/com/example/kati/KatiSecureStore.kt`, ledgered as
  `K-19 secure-store`.

  ## The secret inventory

  Every credential Kati may hold, and whether Kati accepts it at all. The rule
  is **revocable tokens only, never an account password**:

  | Credential | Revocable at the provider? | Kati |
  |---|---|---|
  | CalDAV app-specific password (iCloud, Fastmail) | Yes — revoked from the Apple ID / provider page without changing the account password | **Accepted.** The UI must call it an app-specific password and say it can be revoked there; "password" alone is a lie by omission. |
  | CalDAV account password (self-hosted servers that offer nothing else) | No — revoking it means changing the account password | **Rejected.** Kati does not ask for one and has nowhere to put it. Those servers are unsupported until they can issue an app password. |
  | OAuth refresh/access token (Google, Microsoft Graph) | Yes — revoked from the account's connected-apps page | **Accepted.** |
  | A user's own third-party API key (TMDB and friends, the Tier-3 "Use my own API keys" setting) | Yes — rotated or deleted in the provider's dashboard | **Accepted.** |
  | Kati's own bundled provider keys | n/a | **Not stored here.** They ship inside the binary, are not the user's, and are not secrets from the user. |

  ## Threat model — say this much and no more

  Defends against: another app or a file browser reading the sandbox; an
  `adb backup`-style extraction (`android:allowBackup="false"` already blocks
  the OS backup path, and this closes the on-disk one); a stolen unencrypted
  disk image; anyone who opens `kati.db`.

  Does **not** defend against: a rooted device; an attacker holding the
  unlocked phone while Kati runs; a repackaged build signed with the
  developer's key; or code execution inside the BEAM, which can simply call
  `get/1` — that last one is why the Erlang-distribution hardening ticket and
  this one only work as a pair.

  ## Why there is no `list/0`

  Deliberate. An exporter cannot enumerate what the store will not enumerate,
  so "credentials are excluded from exports" is a property of the store rather
  than a convention the exporter has to remember. Deleting an account means
  calling `delete/1` for each key that account owns, which the caller knows
  from `Kati.Calendars.Account.credentials_ref` plus a fixed suffix.

  ## What happens with no native half — and what will never happen

  On the host BEAM, and on any build where the native side is not bound,
  `available?/0` is `false`, `put/2` and `delete/1` return
  `{:error, :no_native_store}` and `get/1` returns `:error`. There is no
  fallback: this module contains no `File.write`, no `Mob.State`, no repo
  call, and no encryption of its own. A credential store that quietly degrades
  to plaintext is worse than none, because the caller believes it worked.

  `Kati.SecureStoreTest` asserts that absence directly, so a future edit that
  adds a fallback fails the suite.

  ## The chain

      Kati.SecureStore.get/1
        └─ Kati.Nifs.KatiSecureStore.get/1        lib/kati/nifs/…
             └─ c_src/kati_secure_store.c         GetStaticMethodID + call
                  └─ MobBridge.secureStoreGet/1   android/…/MobBridge.kt (K-19)
                       └─ KatiSecureStore.get/1   android/…/KatiSecureStore.kt (K-19)
                            └─ AES-256-GCM under an AndroidKeyStore key

  `mob_nif` has no secure-store entry — its table is `deps/mob/src/mob_nif.erl`
  plus `deps/mob/android/jni/mob_nif.zig`, both inside the hex package — and
  Kati does not fork Mob, so the binding is a **project-owned static NIF**
  built with mob_dev's own route:

      mix mob.add_nif kati_secure_store --type c

  which generated `lib/kati/nifs/kati_secure_store.ex`,
  `c_src/kati_secure_store.c`, the `mob.exs` `:static_nifs` entry and the
  `kati_secure_store_nif_init` line in `priv/generated/driver_tab_android.zig`.

  The entry is `archs: [:android]`, narrowed from the scaffold's `[:all]`.
  That is not a preference: `mix mob.add_nif --type c` wires `c_src/*.c` into
  the **Android** build only — its own generated header says adding the iOS
  block is a manual step — so an `[:all]` entry puts an init symbol in
  `driver_tab_ios.zig` that nothing compiles, and the iOS link fails on a
  build machine nobody is watching. `Kati.NativeNifChainTest` asserts both
  halves of that.

  The one part that is not scaffolding is the class lookup: a NIF runs on an
  Erlang scheduler thread, which has no Java frames, so `FindClass` there
  resolves against the system class loader and cannot see `MobBridge`. The
  class is cached in `JNI_OnLoad` instead — `K-21 nif-bridge-class` in
  `android/app/src/main/jni/beam_jni.c`, next to the identical cache Mob keeps
  for its own bridge calls.

  None of this can be exercised on a host: there is no JVM, so the NIF does not
  bind and every function here answers `{:error, :no_native_store}`. What a
  host test *can* prove is that the absence is reported rather than papered
  over, and `Kati.SecureStoreTest` does exactly that.

  ## iOS

  Not implemented, and not faked. `available?/0` returns `false` there for the
  same reason it does on the host: nothing is bound. What an iOS half would
  need, so the next reader does not have to re-derive it:

    * `SecItemAdd`/`SecItemCopyMatching`/`SecItemDelete` with
      `kSecClass: kSecClassGenericPassword`, one `kSecAttrService` for Kati and
      the store key as `kSecAttrAccount`.
    * `kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` —
      *after first unlock* so a scheduled refresh can read it while the phone
      is locked, *this device only* so it never travels in an iCloud Keychain
      backup or an encrypted device backup.
    * No access group and no Keychain Sharing entitlement, so the item stays
      app-private.
    * Overwrite is `SecItemUpdate`, or delete-then-add; `SecItemAdd` alone
      returns `errSecDuplicateItem` on the second write.

  It is not written here because there is no iOS target in this repo to
  compile it against, and an unverified Objective-C file that makes
  `available?/0` answer `true` would be the worst of both worlds.

  ## Ownership

  In Kati's bridge for now, structured so extraction stays a one-commit
  decision: `KatiSecureStore.kt` names no Kati type and no Mob type, and the
  bridge fence is four delegating methods. Moving it to a tier-1 plugin
  (`android.bridge_kt` + `bridge_class`) or upstream as `mob_secure_store` is
  a file move plus a manifest entry. It is not a plugin *today* because the
  plugin boundary does not solve the missing NIF, and the upstream route adds
  an Ed25519 signing ceremony and a third party's review to Kati's schedule.
  """

  # The module `mix mob.add_nif kati_secure_store` will generate. Referenced as
  # an atom only — never as a compile-time remote call — so this compiles
  # cleanly while it does not exist.
  @nif Kati.Nifs.KatiSecureStore

  # A store key is a filename-shaped handle, not a secret and not user text.
  # Lowercase so two keys cannot differ only by case on a case-folding store,
  # and anchored with \z rather than $ so a trailing newline cannot pass.
  @key_pattern ~r/\A[a-z0-9][a-z0-9._:-]{0,127}\z/

  # Tokens and app-specific passwords are hundreds of bytes. The cap is not
  # about the Keystore — it is about noticing early that something other than
  # a credential is being handed to the credential store.
  @max_value_bytes 16 * 1024

  @type key :: String.t()
  @type backing :: :hardware | :software
  @type reason ::
          :no_native_store
          | :invalid_key
          | :too_large
          | :not_found
          | :no_context
          | :corrupt
          | :write_failed
          | :keystore_failed
          | {:native, String.t()}
          | {:native_error, String.t()}
          | {:bad_reply, term()}

  @doc """
  Whether a real platform-backed store is present and usable.

  `false` on the host BEAM, on iOS, and on any Android build where the NIF
  half is not bound. Callers that hold credentials must check this **before**
  offering to connect an account, so the user is told the truth instead of
  discovering it when the first save fails.
  """
  @spec available?() :: boolean()
  def available? do
    match?({:ok, _backing}, status())
  end

  @doc """
  `{:ok, :hardware}` when the key lives in a TEE or StrongBox,
  `{:ok, :software}` when the device has neither and the Keystore fell back to
  a software-backed key, `{:error, reason}` when there is no store at all.

  `:software` is a genuine degradation and worth surfacing in the Data sources
  screen's storage note. It is still a Keystore key this process cannot
  export, so it is strictly more than a plaintext file — and it is never
  plaintext, which is the only line that matters.
  """
  @spec status() :: {:ok, backing()} | {:error, reason()}
  def status do
    case native(:status, []) do
      {:ok, reply} -> decode_status(reply)
      {:error, _} = error -> error
    end
  end

  @doc """
  Stores `value` under `key`, replacing anything already there.

  Returns `{:error, :no_native_store}` rather than writing anywhere else when
  the native half is absent. Never returns `:ok` unless the bytes reached the
  encrypted store.
  """
  @spec put(key(), binary()) :: :ok | {:error, reason()}
  def put(key, value) when is_binary(value) do
    with :ok <- check_key(key),
         :ok <- check_value(value),
         {:ok, reply} <- native(:put, [key, encode_value(value)]) do
      decode_ack(reply)
    end
  end

  @doc """
  Reads `key`.

  `:error` covers every way there is nothing to return — no entry, no store,
  a blob the current Keystore key can no longer decrypt. That is deliberate:
  the caller's response to all of them is the same, which is to make the user
  authenticate again. Use `status/0` when the distinction matters, for example
  to explain *why* on screen.
  """
  @spec get(key()) :: {:ok, binary()} | :error
  def get(key) do
    with :ok <- check_key(key),
         {:ok, reply} <- native(:get, [key]),
         {:ok, value} <- decode_reply(reply) do
      {:ok, value}
    else
      _ -> :error
    end
  end

  @doc """
  Removes `key`. Removing something that is not there succeeds.

  Deviates from the sketch in #55, which types this `:: :ok`. A `delete/1`
  that answers `:ok` when there is no store would be claiming a credential was
  destroyed while it sits wherever it sat — the same dishonesty as a silent
  plaintext write, pointed the other way.
  """
  @spec delete(key()) :: :ok | {:error, reason()}
  def delete(key) do
    with :ok <- check_key(key),
         {:ok, reply} <- native(:delete, [key]) do
      decode_ack(reply)
    end
  end

  @doc """
  Whether `key` is a usable store key: lowercase `a-z0-9`, then any of
  `a-z0-9._:-`, up to 128 bytes.

  Keys are handles Kati mints (`Kati.Calendars.Account.credentials_ref` and a
  suffix), never user input and never secret. Validating them here means a
  malformed key is a clear error at the call site rather than a
  `SharedPreferences` entry nobody can find again.
  """
  @spec valid_key?(term()) :: boolean()
  def valid_key?(key) when is_binary(key), do: Regex.match?(@key_pattern, key)
  def valid_key?(_), do: false

  # ── The bridge contract ─────────────────────────────────────────────────
  #
  # Public so it can be tested against the Kotlin side, which is the only
  # half that can be run on a device. See KatiSecureStore.kt's module comment
  # for the same protocol written from the other end.

  @doc """
  Encodes a raw secret for the JNI boundary.

  Base64, because a JNI string is UTF-16 and a refresh token is bytes: sending
  the raw form corrupts any token that is not valid text, and does it only
  for some tokens, which is the worst possible failure schedule. The result is
  ASCII with no newlines — Kotlin decodes it with `Base64.NO_WRAP`.
  """
  @spec encode_value(binary()) :: String.t()
  def encode_value(value) when is_binary(value), do: Base.encode64(value)

  @doc """
  Decodes a reply to `get`: `"ok:<base64>"`, or `"error:<reason>"`.

  A reply that is neither is `{:error, {:bad_reply, reply}}` rather than a
  match error — the native side is across a JNI boundary and a drifted bridge
  should degrade to "no credential", not kill the caller.
  """
  @spec decode_reply(String.t()) :: {:ok, binary()} | {:error, reason()}
  def decode_reply("ok:" <> encoded) do
    case Base.decode64(encoded) do
      {:ok, value} -> {:ok, value}
      :error -> {:error, :corrupt}
    end
  end

  def decode_reply("error:" <> reason), do: {:error, reason_atom(reason)}
  def decode_reply(other), do: {:error, {:bad_reply, other}}

  # ── internals ───────────────────────────────────────────────────────────

  defp check_key(key), do: if(valid_key?(key), do: :ok, else: {:error, :invalid_key})

  defp check_value(value) when byte_size(value) <= @max_value_bytes, do: :ok
  defp check_value(_), do: {:error, :too_large}

  # `mod` is a variable, so this is a runtime dispatch and the compiler never
  # has to resolve the NIF module at compile time.
  #
  # There are two distinct ways the native half can be missing and both must
  # land on the same answer:
  #
  #   * the module is not in the build at all — `Code.ensure_loaded?/1` is
  #     false;
  #   * the module is there but `:erlang.load_nif/2` did not bind it, which is
  #     the host and iOS case. Its stubs then raise
  #     `:erlang.nif_error(:nif_not_loaded)`, which arrives here as an
  #     `ErlangError` carrying that exact atom.
  #
  # Anything else that escapes the native side is a genuine fault and keeps its
  # own reason, so a real bridge failure is never disguised as "no store".
  defp native(fun, args) do
    mod = @nif
    arity = length(args)

    if Code.ensure_loaded?(mod) and function_exported?(mod, fun, arity) do
      try do
        {:ok, apply(mod, fun, args)}
      rescue
        e -> {:error, native_reason(e)}
      end
    else
      {:error, :no_native_store}
    end
  end

  defp native_reason(%ErlangError{original: :nif_not_loaded}), do: :no_native_store
  defp native_reason(exception), do: {:native_error, Exception.message(exception)}

  defp decode_ack("ok"), do: :ok
  defp decode_ack("error:" <> reason), do: {:error, reason_atom(reason)}
  defp decode_ack(other), do: {:error, {:bad_reply, other}}

  defp decode_status("ok:hardware"), do: {:ok, :hardware}
  defp decode_status("ok:software"), do: {:ok, :software}
  defp decode_status("error:" <> reason), do: {:error, reason_atom(reason)}
  defp decode_status(other), do: {:error, {:bad_reply, other}}

  # A closed set. Native replies are never fed to String.to_atom — an
  # unbounded atom table is reachable from whatever the bridge happens to say.
  #
  # `no_native_store` is in the set because the NIF answers it from its own
  # non-Android arm (c_src/kati_secure_store.c): on iOS the table entry exists
  # and binds, so the store's absence arrives as a reply rather than as an
  # unbound stub. Same answer, second route.
  defp reason_atom("no_native_store"), do: :no_native_store
  defp reason_atom("no_jvm"), do: :no_native_store
  defp reason_atom("no_bridge"), do: :no_native_store
  defp reason_atom("no_method"), do: :no_native_store
  defp reason_atom("not_found"), do: :not_found
  defp reason_atom("no_context"), do: :no_context
  defp reason_atom("corrupt"), do: :corrupt
  defp reason_atom("write_failed"), do: :write_failed
  defp reason_atom("keystore_failed"), do: :keystore_failed
  defp reason_atom(other), do: {:native, other}
end
