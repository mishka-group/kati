defmodule Kati.SecureStoreTest do
  @moduledoc """
  Guards for the credential store.

  Two of these can never be proved on a host BEAM — the AES-GCM round trip and
  the Keystore itself only exist on a device — so what is asserted here is
  everything that *can* be: that the store fails honestly with no native half,
  that the JNI wire protocol is byte-exact, that the Kotlin still says the
  things the security argument depends on, and that no credential-shaped value
  has appeared anywhere else in the app.
  """
  use ExUnit.Case, async: true

  alias Kati.SecureStore

  @root Path.expand("../..", __DIR__)
  @module Path.join(@root, "lib/kati/secure_store.ex")
  @kotlin Path.join(@root, "android/app/src/main/java/com/example/kati/KatiSecureStore.kt")
  @bridge Path.join(@root, "android/app/src/main/java/com/example/kati/MobBridge.kt")
  @activity Path.join(@root, "android/app/src/main/java/com/example/kati/MainActivity.kt")
  @gradle Path.join(@root, "android/app/build.gradle")
  @tracked Path.join(@root, "native/TRACKED")

  describe "with no native half" do
    test "the store reports itself unavailable rather than inventing one" do
      # Today `Kati.Nifs.KatiSecureStore` does not exist at all, so the reason
      # is :no_native_store. Once `mix mob.add_nif kati_secure_store` generates
      # the stub, it loads on the host but the NIF behind it never does, so the
      # reason becomes {:native_error, _}. Both mean "there is no store"; the
      # thing that must never happen is a success.
      assert {:error, reason} = SecureStore.status()

      assert reason == :no_native_store or match?({:native_error, _}, reason),
             "unexpected status reason: #{inspect(reason)}"

      refute SecureStore.available?()
    end

    test "put refuses, get finds nothing, delete refuses" do
      key = "kati.test.refresh_token"

      assert {:error, _} = SecureStore.put(key, "a-refresh-token")
      assert SecureStore.get(key) == :error
      assert {:error, _} = SecureStore.delete(key)
    end

    test "put never returns :ok when there is nowhere encrypted to put it" do
      # The whole point of the ticket in one assertion: a store that answers
      # :ok while writing nothing, or writing plaintext, is worse than none.
      refute SecureStore.put("kati.test.token", "s3cret") == :ok
    end

    test "a bad key is rejected before the store is even consulted" do
      # On the host every other path returns a "no store" error, so getting
      # :invalid_key back proves validation runs first.
      assert SecureStore.put("Bad Key!", "x") == {:error, :invalid_key}
      assert SecureStore.delete("../escape") == {:error, :invalid_key}
    end

    test "an oversized value is rejected as a value, not as a missing store" do
      assert SecureStore.put("kati.test.blob", :binary.copy("x", 17_000)) ==
               {:error, :too_large}

      # And 16 KiB exactly is still a value, so the cap is a cap and not an
      # off-by-one that rejects the largest legitimate token.
      assert {:error, reason} = SecureStore.put("kati.test.blob", :binary.copy("x", 16 * 1024))
      refute reason == :too_large
    end

    test "the module contains no way to write a credential anywhere else" do
      body = code_only(@module)

      assert body =~ "def put(key, value)",
             "stripping docs and comments removed the code — this scan proves nothing"

      for forbidden <- ["Mob.State", "File.write", "File.open", "Kati.Repo", ":dets", "Ash."] do
        refute body =~ forbidden,
               "Kati.SecureStore now references #{forbidden} — a credential store that " <>
                 "falls back to plaintext is worse than no credential store"
      end
    end

    test "the module names the NIF it will be bound through" do
      # Behavioural tests can never see this: with no native half every path
      # returns an error whatever module name is written down. Pinning it here
      # means the Elixir side and `mix mob.add_nif kati_secure_store` cannot
      # drift apart silently.
      assert File.read!(@module) =~ "Kati.Nifs.KatiSecureStore"
    end
  end

  describe "the JNI wire protocol" do
    @values [
      {"a plain token", "ya29.a0AfB_by-not-a-real-token"},
      {"raw bytes", <<0, 1, 2, 253, 254, 255>>},
      {"random key material", :crypto.strong_rand_bytes(64)},
      {"multibyte text", "sénha-très-sécurisée"},
      {"a long token", String.duplicate("A", 4096)},
      {"an empty value", ""}
    ]

    for {label, value} <- @values do
      test "#{label} survives the round trip byte for byte" do
        value = unquote(value)
        encoded = SecureStore.encode_value(value)

        assert SecureStore.decode_reply("ok:" <> encoded) == {:ok, value}
      end
    end

    test "the encoded form is safe to hand to a JNI string" do
      # This is the reason base64 is in the protocol at all: a JNI string is
      # UTF-16, and half of what Kati will store is not valid text.
      raw = <<0xFF, 0xFE, 0xFD>>
      refute String.valid?(raw), "the risk this encoding defends against is not real any more"

      encoded = SecureStore.encode_value(raw)
      assert String.valid?(encoded)
      assert String.printable?(encoded)
      refute String.contains?(encoded, "\n"), "Kotlin decodes with Base64.NO_WRAP"
    end

    test "known error reasons decode to atoms" do
      assert SecureStore.decode_reply("error:not_found") == {:error, :not_found}
      assert SecureStore.decode_reply("error:no_context") == {:error, :no_context}
      assert SecureStore.decode_reply("error:corrupt") == {:error, :corrupt}
      assert SecureStore.decode_reply("error:write_failed") == {:error, :write_failed}
      assert SecureStore.decode_reply("error:keystore_failed") == {:error, :keystore_failed}
    end

    test "an unknown reason is carried as a string and creates no atom" do
      novel = "reason_#{System.unique_integer([:positive])}"

      assert SecureStore.decode_reply("error:" <> novel) == {:error, {:native, novel}}

      assert_raise ArgumentError, fn -> String.to_existing_atom(novel) end
    end

    test "a corrupt or drifted reply degrades instead of raising" do
      assert SecureStore.decode_reply("ok:not base64!!") == {:error, :corrupt}
      assert SecureStore.decode_reply("garbage") == {:error, {:bad_reply, "garbage"}}
      assert SecureStore.decode_reply("") == {:error, {:bad_reply, ""}}
    end
  end

  describe "store keys" do
    test "handles Kati mints are accepted" do
      for key <- [
            "a",
            "tmdb.api_key",
            "caldav:8f1c-42ab:app_password",
            "google:refresh-token",
            String.duplicate("a", 128)
          ] do
        assert SecureStore.valid_key?(key), "#{inspect(key)} should be a valid store key"
      end
    end

    test "anything that could collide, escape or hide is rejected" do
      for key <- [
            "",
            "Tmdb",
            "with space",
            "../escape",
            ".leading-dot",
            "trailing\n",
            "abc\n",
            String.duplicate("a", 129),
            :not_a_string,
            nil
          ] do
        refute SecureStore.valid_key?(key), "#{inspect(key)} should not be a valid store key"
      end
    end
  end

  describe "the Android half" do
    test "the Kotlin exists and is registered in the drift ledger's tracked set" do
      assert File.exists?(@kotlin)

      assert File.read!(@tracked) =~
               "android/app/src/main/java/com/example/kati/KatiSecureStore.kt",
             "untracked native code is invisible to the ledger test and to a Mob upgrade"
    end

    test "encryption is a Keystore-held AES-GCM key" do
      # Asserted against the CODE, not the file. This Kotlin's comments argue
      # at length about the crypto choices, so a raw-text assertion here would
      # be satisfied by the argument surviving after the implementation had
      # gone.
      kotlin = kotlin_code()

      assert kotlin =~ ~s("AndroidKeyStore")
      assert kotlin =~ ~s("AES/GCM/NoPadding")
      assert kotlin =~ "PURPOSE_ENCRYPT"
      assert kotlin =~ "PURPOSE_DECRYPT"
      assert kotlin =~ "setKeySize(256)"

      assert kotlin =~ "setRandomizedEncryptionRequired(true)",
             "without it a future edit could supply its own IV and reuse one under a GCM key"

      assert kotlin =~ "setUserAuthenticationRequired(false)",
             "a background token refresh has no UI to prompt from; this is deliberate " <>
               "and the threat model depends on it being stated"

      assert kotlin =~ "setIsStrongBoxBacked(true)",
             "StrongBox is requested and degraded, not skipped"
    end

    test "the deprecated AndroidX crypto wrapper is not used, here or in Gradle" do
      # androidx.security:security-crypto reached stable 1.1.0 (2025-07-30)
      # with every API deprecated in favour of using the Android Keystore
      # directly. Adding a deprecated dependency to a vendored bridge is a bad
      # trade, and this is the assertion that keeps the finding from being
      # re-litigated by the next reader.
      kotlin = kotlin_code()
      refute kotlin =~ "EncryptedSharedPreferences"
      refute kotlin =~ "androidx.security"
      refute File.read!(@gradle) =~ "androidx.security"

      # ...and the finding itself is written down where the next reader looks,
      # rather than being a decision nobody can retrace.
      assert File.read!(Path.join(@root, "native/LEDGER.md")) =~ "Deprecated all APIs"
    end

    test "the store never writes a value it has not encrypted" do
      kotlin = kotlin_code()

      writes = Regex.scan(~r/\.putString\(/, kotlin) |> length()

      assert writes == 1,
             "expected exactly one write path (the encrypted one), found #{writes}"

      # ...and that one write takes the base64 of the ciphertext blob.
      assert kotlin =~ ~r/putString\(key, Base64\.encodeToString\(blob/
    end

    test "the bridge exposes the four methods a NIF can bind to" do
      region = bridge_fence_code()

      for signature <- [
            "fun secureStoreStatus(): String",
            "fun secureStorePut(key: String, valueB64: String): String",
            "fun secureStoreGet(key: String): String",
            "fun secureStoreDelete(key: String): String"
          ] do
        assert region =~ signature,
               "MobBridge.#{signature} is gone — mob's nif_load resolves bridge methods by " <>
                 "name and signature, so a drift here is silent"
      end

      statics = Regex.scan(~r/@JvmStatic/, region) |> length()

      assert statics == 4,
             "expected 4 @JvmStatic methods in the fence, found #{statics} — a JNI lookup " <>
               "of a non-static method fails at runtime, not at compile time"

      assert region =~ "KatiSecureStore.put(key, valueB64)"
      assert region =~ "KatiSecureStore.get(key)"
      assert region =~ "KatiSecureStore.delete(key)"
    end

    test "the application context is attached where an Activity certainly exists" do
      # activityRef is a WeakReference. A background token refresh runs with the
      # Activity destroyed, and without this line every read would answer
      # error:no_context — which the Elixir side would faithfully report as
      # "no credential", i.e. a re-auth prompt that can never be satisfied.
      assert File.read!(@activity) =~ "KatiSecureStore.attach(this)"
    end
  end

  describe "no credential is stored anywhere else" do
    @credential_shaped ~r/token|password|passwd|secret|api_?key|credential|bearer/i

    # Both are handles or design tokens, not secrets, and both say so where
    # they are declared. Anything else matching the pattern is a bug.
    @allowed_attributes ~w(colour_token credentials_ref)

    test "no Ash attribute is named like a credential" do
      sources = elixir_sources()

      assert length(sources) > 50,
             "the scan found #{length(sources)} source files — it is not looking at the app"

      attributes =
        sources
        |> Enum.flat_map(fn path ->
          ~r/attribute\s+:([a-z_0-9]+)/
          |> Regex.scan(File.read!(path))
          |> Enum.map(fn [_, name] -> {name, path} end)
        end)

      assert length(attributes) > 100,
             "only #{length(attributes)} attributes found — the pattern has stopped matching " <>
               "the resources it is supposed to police"

      offenders =
        attributes
        |> Enum.filter(fn {name, _} -> Regex.match?(@credential_shaped, name) end)
        |> Enum.reject(fn {name, _} -> name in @allowed_attributes end)

      assert offenders == [],
             "credential-shaped Ash attributes found — the database is a plaintext file, so " <>
               "these belong in Kati.SecureStore: #{inspect(offenders)}"
    end

    test "no Mob.State key is named like a credential" do
      keys = mob_state_keys()

      # Mob.State is called both with a literal atom and through an @attribute.
      # Asserting both resolved forms are present proves the scanner reads both
      # spellings rather than quietly seeing none.
      assert "locale" in keys, "the scanner no longer resolves Mob.State.put(:literal)"
      assert "theme_mode" in keys, "the scanner no longer resolves Mob.State.put(@attribute)"

      offenders = Enum.filter(keys, &Regex.match?(@credential_shaped, &1))

      assert offenders == [],
             "credential-shaped Mob.State keys found — Mob.State is a plaintext :dets file: " <>
               inspect(offenders)
    end
  end

  # ── helpers ───────────────────────────────────────────────────────────────

  defp elixir_sources do
    Path.wildcard(Path.join(@root, "lib/**/*.ex"))
  end

  # Kotlin with its comments removed. The whole security argument for this file
  # lives in its comments — including the names of the mechanisms it decided
  # NOT to use — so every assertion about what the code does or does not do has
  # to be made against the code.
  defp strip_kotlin_comments(source) do
    source
    |> String.replace(~r{/\*(?s).*?\*/}, "")
    |> String.replace(~r{//.*$}m, "")
  end

  defp kotlin_code do
    code = @kotlin |> File.read!() |> strip_kotlin_comments()

    assert code =~ "object KatiSecureStore",
           "comment stripping removed the implementation — this scan proves nothing"

    code
  end

  defp bridge_fence_code do
    [region] =
      Regex.run(
        ~r/KATI-BEGIN\(K-19 secure-store-bridge\)(?s).*?KATI-END\(K-19 secure-store-bridge\)/,
        File.read!(@bridge)
      )

    code = strip_kotlin_comments(region)

    assert code =~ "KatiSecureStore",
           "comment stripping removed the fence body — this scan proves nothing"

    code
  end

  # Strips @moduledoc/@doc heredocs and comments, so a scan for a forbidden
  # call cannot be satisfied by prose that exists to explain why the call is
  # forbidden.
  defp code_only(path) do
    path
    |> File.read!()
    |> String.replace(~r/@(?:module)?doc\s+"""(?s).*?"""/, "")
    |> String.replace(~r/^\s*#.*$/m, "")
  end

  # Every key handed to Mob.State anywhere in lib/, resolving the
  # `Mob.State.put(@key, …)` spelling through the module attribute it names.
  defp mob_state_keys do
    Enum.flat_map(elixir_sources(), fn path ->
      src = File.read!(path)

      attrs =
        ~r/^\s*@([a-z_][a-zA-Z_0-9]*)\s+:([a-z_][a-zA-Z_0-9]*)\s*$/m
        |> Regex.scan(src)
        |> Map.new(fn [_, name, value] -> {name, value} end)

      ~r/Mob\.State\.(?:put|get)\(\s*(:|@)([a-zA-Z_][a-zA-Z_0-9]*)/
      |> Regex.scan(src)
      |> Enum.map(fn
        [_, ":", name] -> name
        [_, "@", name] -> Map.get(attrs, name, "unresolved:#{name}")
      end)
    end)
    |> Enum.uniq()
  end
end
