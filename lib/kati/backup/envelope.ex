defmodule Kati.Backup.Envelope do
  @moduledoc """
  Opt-in passphrase encryption, wrapped around the archive and nothing else.

  A `.katibackup` is the whole of a user's history in one file, and #64 exists
  precisely so that file leaves the phone — into a Downloads folder, a chat
  thread, a cloud drive, a laptop that someone else also uses. Encryption is
  **opt-in** because a passphrase a user forgets destroys the backup as
  thoroughly as losing the phone did, and this feature is insurance, not a
  vault. So both forms are first-class: a plain zip of JSON, and that same zip
  sealed inside an envelope.

  The passphrase is the only key. There is deliberately **no device-bound key**
  anywhere in here — a key held in the Android Keystore cannot leave the phone,
  which would make the backup openable only on the phone it was made to survive
  the loss of.

  ## The envelope

      "KATIENC\\0"          8 bytes, the magic that identifies the file
      header_length         uint32, big-endian
      header                header_length bytes of JSON — plaintext, and the AAD
      tag                   16 bytes, the AES-GCM authentication tag
      ciphertext            the rest: the `.katibackup` zip, encrypted

  The header is JSON in the clear so the file can say what it is without the
  passphrase:

      {"format":"kati.backup.encrypted","envelope_version":1,
       "cipher":"aes-256-gcm","kdf":"pbkdf2-hmac-sha512","iterations":210000,
       "normalization":"nfc","salt":"…base64…","iv":"…base64…",
       "created_at":"2026-08-21T18:44:02.913044Z"}

  It is also the GCM **additional authenticated data**, so a file whose
  iteration count or salt has been edited fails to open as an authentication
  failure rather than as a wrong-looking key.

  `created_at` is the one thing in here that is a deliberate metadata leak, and
  it earns it: a user looking at three encrypted files needs to know which is
  the recent one before typing three passphrases, and the date is already in
  the filename Kati proposes and in the file's own mtime. Nothing else about
  the contents is outside the ciphertext — not the record counts, not the app
  version, not the table names.

  ## Why every parameter is in the file

  `iterations` and `kdf` are written into each backup rather than compiled in,
  because the cost of a KDF is supposed to rise with hardware. An app that
  hard-codes today's number and raises it next year cannot open the backups it
  wrote this year, which is the failure this whole ticket exists to prevent.
  Reading the number from the file means a raise costs nothing and orphans
  nothing.

  ## Why PBKDF2 and not Argon2id

  #64 names "Argon2id/PBKDF2", and Argon2id is the better of the two: PBKDF2 is
  cheap to attack on a GPU in a way a memory-hard KDF is not. It is not used
  here because every Argon2 library on Hex is a Rust or C NIF, and this app is
  a BEAM on an Android phone whose native toolchain is Mob's — a NIF that has
  to cross-compile for four Android ABIs, in a tree where the native shell is
  vendored and fenced, to protect a file the user chose to encrypt. `:crypto`
  ships PBKDF2 in OTP itself and needs nothing added.

  The mitigation is that `kdf` is a **string in the file**, not an assumption.
  The day an Argon2id NIF is worth its cost, it becomes a new `kdf` value, new
  backups carry it, and every old backup still opens — the reader branches on
  what the file says.

  210,000 iterations of PBKDF2-HMAC-SHA512 is OWASP's 2023 figure; it measures
  126 ms on a development Mac, so roughly half a second to a second on a
  mid-range phone, paid once per export and once per restore.

  ## What a wrong passphrase does

  It fails as an **authentication failure**, with `reason: :bad_passphrase`,
  before a single byte reaches the unzipper. That is not the same error as a
  damaged file and it must not be shown as one: "this passphrase is wrong" is
  a thing the user can act on, and "this backup is damaged" sends them looking
  for another copy of a file that was fine. A flipped byte anywhere in the
  ciphertext, the tag or the header produces the same authentication failure,
  because GCM cannot tell a wrong key from altered bytes — and saying so
  honestly is better than guessing.
  """

  alias Kati.Backup.Error

  @magic "KATIENC\0"
  @magic_bytes byte_size(@magic)
  @format "kati.backup.encrypted"
  @envelope_version 1
  @cipher "aes-256-gcm"
  @kdf "pbkdf2-hmac-sha512"
  @digest :sha512

  # OWASP's 2023 figure for PBKDF2-HMAC-SHA512. Written into every file; see
  # the moduledoc for why raising it later is free.
  @iterations 210_000

  # A file claiming fewer iterations than this was not written by Kati and is
  # not worth the word "encrypted". A file claiming more than the ceiling is a
  # denial of service — the count is attacker-controlled, and a passphrase box
  # that hangs the app for an hour is a bug, not a security feature.
  @min_iterations 100_000
  @max_iterations 10_000_000

  @salt_bytes 16
  @iv_bytes 12
  @tag_bytes 16
  @key_bytes 32

  # The header is a fixed set of short fields. The cap is three orders of
  # magnitude above it, and exists so a corrupt length prefix is a refusal
  # rather than an allocation.
  @max_header_bytes 64 * 1024

  @type header :: %{String.t() => term()}

  @doc "The eight bytes every encrypted Kati backup starts with."
  @spec magic() :: binary()
  def magic, do: @magic

  @doc "The envelope version this app writes."
  @spec envelope_version() :: pos_integer()
  def envelope_version, do: @envelope_version

  @doc "The KDF cost this app writes today. Old files carry their own."
  @spec iterations() :: pos_integer()
  def iterations, do: @iterations

  @doc """
  Is this an encrypted backup?

  Reads eight bytes, so it answers for a plain `.katibackup` (a zip, starting
  `PK`), an encrypted one, and a file that is neither.
  """
  @spec encrypted?(binary()) :: boolean()
  def encrypted?(binary) when is_binary(binary) and byte_size(binary) >= @magic_bytes do
    binary_part(binary, 0, @magic_bytes) == @magic
  end

  def encrypted?(binary) when is_binary(binary), do: false

  @doc """
  Encrypt archive bytes when `:passphrase` is given, and pass them through
  untouched when it is not.

  This is the opt-in, in one function: every export path calls it, and a caller
  that never mentions a passphrase gets exactly the bytes it handed in.
  """
  @spec wrap(binary(), keyword()) :: {:ok, binary()} | {:error, Error.t()}
  def wrap(archive, opts \\ []) when is_binary(archive) do
    case Keyword.get(opts, :passphrase) do
      nil -> {:ok, archive}
      passphrase -> seal(archive, passphrase, opts)
    end
  end

  @doc """
  Decrypt an envelope, or pass a plain archive through untouched.

  The form is detected from the bytes, never asked of the user: someone
  restoring a backup on a new phone has one file and no memory of which button
  they pressed a year ago. A passphrase given for a file that turns out to be
  unencrypted is ignored rather than refused, for the same reason.
  """
  @spec unwrap(binary(), keyword()) :: {:ok, binary()} | {:error, Error.t()}
  def unwrap(binary, opts \\ []) when is_binary(binary) do
    cond do
      not encrypted?(binary) ->
        {:ok, binary}

      is_nil(Keyword.get(opts, :passphrase)) ->
        Error.error(
          :passphrase_required,
          "This backup is encrypted. Enter the passphrase it was made with — " <>
            "Kati cannot open it without one, and nobody can reset it."
        )

      true ->
        open(binary, Keyword.fetch!(opts, :passphrase))
    end
  end

  @doc """
  Seal archive bytes with a passphrase.

  A fresh salt and a fresh IV every time, so two backups of the same data with
  the same passphrase share no bytes and reveal nothing by comparison.
  """
  @spec seal(binary(), term(), keyword()) :: {:ok, binary()} | {:error, Error.t()}
  def seal(archive, passphrase, opts \\ []) when is_binary(archive) do
    with {:ok, normalized} <- normalize(passphrase),
         {:ok, rounds} <- usable_iterations(Keyword.get(opts, :iterations, @iterations)) do
      salt = :crypto.strong_rand_bytes(@salt_bytes)
      iv = :crypto.strong_rand_bytes(@iv_bytes)
      header = encode_header(salt, iv, rounds)
      key = derive(normalized, salt, rounds)

      {ciphertext, tag} =
        :crypto.crypto_one_time_aead(:aes_256_gcm, key, iv, archive, header, @tag_bytes, true)

      {:ok, @magic <> <<byte_size(header)::unsigned-big-32>> <> header <> tag <> ciphertext}
    end
  end

  @doc """
  Open an envelope and return the archive bytes inside.

  Every failure here is a value with a sentence attached, and the sentences are
  different on purpose: a passphrase that does not authenticate, a file this
  version of Kati cannot read, and a file that is cut short are three different
  things to tell a user.
  """
  @spec open(binary(), term()) :: {:ok, binary()} | {:error, Error.t()}
  def open(binary, passphrase) when is_binary(binary) do
    with {:ok, parts} <- split(binary),
         {:ok, header} <- decode_header(parts.header),
         :ok <- supported(header),
         {:ok, salt} <- fetch_bytes(header, "salt", @salt_bytes),
         {:ok, iv} <- fetch_bytes(header, "iv", @iv_bytes),
         {:ok, rounds} <- usable_iterations(Map.get(header, "iterations")),
         {:ok, normalized} <- normalize(passphrase) do
      key = derive(normalized, salt, rounds)

      case :crypto.crypto_one_time_aead(
             :aes_256_gcm,
             key,
             iv,
             parts.ciphertext,
             parts.header,
             parts.tag,
             false
           ) do
        plaintext when is_binary(plaintext) ->
          {:ok, plaintext}

        :error ->
          Error.error(
            :bad_passphrase,
            "That passphrase does not open this backup. Either it is not the one the " <>
              "backup was made with, or the file has been altered since — Kati cannot " <>
              "tell those apart, and it will not guess. Nothing has been changed."
          )
      end
    end
  end

  @doc """
  The envelope's plaintext header, without the passphrase.

  Parsing only: a header naming a cipher this app has never heard of still
  comes back, so `describe/1` can say *why* the file cannot be opened instead
  of calling it corrupt.
  """
  @spec header(binary()) :: {:ok, header()} | {:error, Error.t()}
  def header(binary) when is_binary(binary) do
    with {:ok, parts} <- split(binary), do: decode_header(parts.header)
  end

  @doc """
  What is knowable about the container itself, for any bytes at all.

  Never fails, because it is what a screen puts next to a filename before the
  user has typed anything: `encrypted: false` for a plain backup,
  `encrypted: true` with the parameters for a sealed one, and
  `encryption: nil` for a file that starts like an envelope and then does not
  hold one.
  """
  @spec badge(binary()) :: %{encrypted: boolean(), encryption: map() | nil}
  def badge(binary) when is_binary(binary) do
    if encrypted?(binary) do
      %{encrypted: true, encryption: describe(binary)}
    else
      %{encrypted: false, encryption: nil}
    end
  end

  @doc """
  The header, read for a human, without the passphrase.

  `supported` is this app's answer to "could I even try?" — false for an
  envelope written by a newer Kati, which is a different sentence from a wrong
  passphrase.
  """
  @spec describe(binary()) :: map() | nil
  def describe(binary) when is_binary(binary) do
    case header(binary) do
      {:ok, header} ->
        %{
          envelope_version: Map.get(header, "envelope_version"),
          cipher: Map.get(header, "cipher"),
          kdf: Map.get(header, "kdf"),
          iterations: Map.get(header, "iterations"),
          created_at: created_at(header),
          supported: supported(header) == :ok
        }

      {:error, _} ->
        nil
    end
  end

  @doc """
  The summary `Kati.Backup.inspect_file/1` shows for an encrypted file nobody
  has unlocked yet.

  Every field that lives inside the ciphertext is `nil` rather than absent, so
  a screen written against the unencrypted summary reads blanks instead of
  raising — and `unlocked: false` is the field that says why they are blank. A
  file that cannot identify itself is indistinguishable from a corrupt one, and
  this is the identification.
  """
  @spec locked_summary(binary()) :: {:ok, map()} | {:error, Error.t()}
  def locked_summary(binary) when is_binary(binary) do
    with {:ok, header} <- header(binary) do
      {:ok,
       %{
         encrypted: true,
         unlocked: false,
         encryption: describe(binary),
         format_version: nil,
         schema_version: nil,
         app_version: nil,
         exported_at: created_at(header),
         record_counts: nil,
         total_records: nil,
         dropped_columns: nil
       }}
    end
  end

  defp split(<<@magic, header_bytes::unsigned-big-32, rest::binary>>)
       when header_bytes > 0 and header_bytes <= @max_header_bytes do
    case rest do
      <<header::binary-size(^header_bytes), tag::binary-size(@tag_bytes), ciphertext::binary>> ->
        {:ok, %{header: header, tag: tag, ciphertext: ciphertext}}

      _short ->
        truncated()
    end
  end

  defp split(<<@magic, header_bytes::unsigned-big-32, _rest::binary>>) do
    Error.error(
      :unsupported_encryption,
      "This encrypted Kati backup declares a #{header_bytes}-byte header, and Kati reads " <>
        "at most #{@max_header_bytes}. It will not open it.",
      %{header_bytes: header_bytes, max: @max_header_bytes}
    )
  end

  defp split(<<@magic, _rest::binary>>), do: truncated()

  defp split(_other) do
    Error.error(:not_a_backup, "This file is not a Kati backup.")
  end

  defp truncated do
    Error.error(
      :unreadable_archive,
      "This is an encrypted Kati backup, and it is cut short — it did not copy over " <>
        "completely. Try another copy of the file."
    )
  end

  defp decode_header(bytes) do
    case Jason.decode(bytes) do
      {:ok, %{"format" => @format} = header} ->
        {:ok, header}

      {:ok, _other} ->
        Error.error(
          :unsupported_encryption,
          "This file starts like an encrypted Kati backup and does not say it is one."
        )

      {:error, _reason} ->
        truncated()
    end
  end

  defp supported(header) do
    case {Map.get(header, "envelope_version"), Map.get(header, "cipher"), Map.get(header, "kdf")} do
      {@envelope_version, @cipher, @kdf} ->
        :ok

      {version, _cipher, _kdf} when is_integer(version) and version > @envelope_version ->
        Error.error(
          :unsupported_encryption,
          "This backup was encrypted by a newer version of Kati (envelope version " <>
            "#{version}; this app understands up to #{@envelope_version}). Update Kati " <>
            "and try again. Nothing has been changed.",
          %{envelope_version: version, supported: @envelope_version}
        )

      {version, cipher, kdf} ->
        Error.error(
          :unsupported_encryption,
          "Kati does not know how to open this encrypted backup — it names " <>
            "#{inspect(cipher)} and #{inspect(kdf)}, and Kati reads #{inspect(@cipher)} " <>
            "and #{inspect(@kdf)}.",
          %{envelope_version: version, cipher: cipher, kdf: kdf}
        )
    end
  end

  defp usable_iterations(rounds)
       when is_integer(rounds) and rounds >= @min_iterations and rounds <= @max_iterations do
    {:ok, rounds}
  end

  defp usable_iterations(rounds) do
    Error.error(
      :unsupported_encryption,
      "Kati stretches a backup passphrase between #{@min_iterations} and " <>
        "#{@max_iterations} rounds, and this asks for #{inspect(rounds)}.",
      %{iterations: rounds, min: @min_iterations, max: @max_iterations}
    )
  end

  defp fetch_bytes(header, key, size) do
    with value when is_binary(value) <- Map.get(header, key),
         {:ok, decoded} <- Base.decode64(value),
         ^size <- byte_size(decoded) do
      {:ok, decoded}
    else
      _ ->
        Error.error(
          :unsupported_encryption,
          "This encrypted backup's #{key} is missing or the wrong size, so Kati cannot " <>
            "derive a key from it.",
          %{key: key, expected_bytes: size}
        )
    end
  end

  # NFC, because the passphrase is text a person types, and on a Persian or an
  # accented keyboard the same characters can arrive as one code point on one
  # device and two on another. Without this, a backup made on the old phone
  # would refuse the passphrase typed correctly on the new one — the exact
  # failure this feature exists to prevent. Recorded in the header as
  # `normalization`, so a third-party reader knows to do the same.
  defp normalize(passphrase) when is_binary(passphrase) do
    case :unicode.characters_to_nfc_binary(passphrase) do
      normalized when is_binary(normalized) -> non_blank(normalized)
      _not_text -> unusable("is not readable text")
    end
  end

  defp normalize(_other), do: unusable("is not text")

  defp non_blank(normalized) do
    if String.trim(normalized) == "" do
      unusable("is empty")
    else
      {:ok, normalized}
    end
  end

  defp unusable(what) do
    Error.error(
      :unusable_passphrase,
      "Kati cannot use this passphrase — it #{what}. A backup is either encrypted with " <>
        "a real passphrase or not encrypted at all."
    )
  end

  defp derive(passphrase, salt, rounds) do
    :crypto.pbkdf2_hmac(@digest, passphrase, salt, rounds, @key_bytes)
  end

  defp encode_header(salt, iv, rounds) do
    Jason.encode!(%{
      "format" => @format,
      "envelope_version" => @envelope_version,
      "cipher" => @cipher,
      "kdf" => @kdf,
      "iterations" => rounds,
      "normalization" => "nfc",
      "salt" => Base.encode64(salt),
      "iv" => Base.encode64(iv),
      "created_at" => DateTime.utc_now() |> DateTime.to_iso8601()
    })
  end

  defp created_at(header) do
    case DateTime.from_iso8601(Map.get(header, "created_at", "")) do
      {:ok, datetime, _offset} -> datetime
      _unreadable -> nil
    end
  end
end
