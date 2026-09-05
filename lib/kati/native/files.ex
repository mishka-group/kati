defmodule Kati.Native.Files do
  @moduledoc """
  The only way a file leaves — or enters — Kati.

  ## Why this module had to be written

  Mob's outbound file surface is `Mob.Share.text/2` and nothing else. There is
  no `Mob.Share.file/2`; the framework's own capability matrix says so. And
  `mix mob.enable file_sharing` is not the answer it looks like — its entire
  body sets two iOS plist keys and declares the Android FileProvider, and its
  table records "(no Elixir surface)". A FileProvider with no `Intent` behind
  it gives a user nothing at all.

  That gap is not cosmetic. Kati sets `android:allowBackup="false"`, keeps its
  database in `filesDir` where no file browser can reach it, and has no server
  and no account. Until this module existed, `Kati.Backup` could produce a
  perfect `.katibackup` and there was **no way for the user to obtain it** —
  which makes "phone lost, stolen, broken or replaced" mean the total,
  unrecoverable loss of everything they ever logged.

  ## The three doors

  | Direction | How | Result |
  |---|---|---|
  | **Save** | `ACTION_CREATE_DOCUMENT` — the user picks the destination, Kati streams into the `content://` URI it gets back | `{:saved, …}` with a byte count, or `:cancelled` |
  | **Share** | `ACTION_SEND` with a FileProvider URI | `{:shared, …}` or `{:dismissed, …}` — see below |
  | **Open** | `Mob.Files.pick/2`, which already works | `{:files, :picked, items}` |

  Import needed no new native code; export needed both intents plus the NIF
  that reaches them (`Kati.Nifs.KatiBridge`, `c_src/kati_bridge.c`, and the
  `K-20 file-transport` fence in `MobBridge.kt`).

  ## Share cannot tell you whether the share happened

  Android returns `RESULT_CANCELED` from a chooser whether the user dismissed
  the sheet or completed a send, because the result comes from the receiving
  app and almost none set one. So a closed sheet is reported as
  `{:dismissed, …}` — "the sheet came back, and the OS did not say what
  happened" — and never as success. `{:shared, …}` only ever means a receiving
  app explicitly said so.

  This is why **Save is the insurance path and Share is the convenience path**,
  and why a settings screen must not offer Share as the way to make a backup.
  A user who taps Share, opens their mail app, and abandons the draft has no
  backup and no way to know it.

  ## Everything is asynchronous, and cancellation is not an error

  `save_as/2` and `share/2` return `:ok` when the intent was **launched** —
  nothing more. The outcome arrives as a message to the calling process, and
  the caller turns it into a value with `decode/1`:

      def handle_info(message, socket) do
        case Kati.Native.Files.decode(message) do
          {:saved, %{bytes: bytes}} -> …
          :cancelled                -> …   # the user changed their mind
          {:error, reason}          -> …
          :ignore                   -> {:noreply, socket}
        end
      end

  A user who backs out of the folder picker has done a normal thing, so
  `:cancelled` is its own answer and never an error. `decode/1` is a pure
  function over a message and is what the host tests exercise.

  ## iOS

  Not wired, and not faked: `available?/0` is `false` there and both calls
  answer `{:error, :no_bridge}`. iOS does not need these intents — setting
  `UIFileSharingEnabled` and `LSSupportsOpeningDocumentsInPlace` makes
  `Mob.data_dir/0` (which *is* `NSDocumentDirectory` there) visible in the
  Files app, so a backup written with `File.write!/2` is already retrievable
  with no native code. The catch worth writing down before anyone flips those
  keys: the same switch exposes `kati.db` and `mob_state.dets` in the same
  folder. A real `Mob.Share.file/2` would have to be patched into
  `deps/mob/ios/mob_nif.m`, which is **not** app-owned — that is an upstream
  pull request, not a vendored edit, and it is recorded as one in
  `native/UPSTREAM`.
  """

  alias Kati.Native.Bridge

  @event :kati_files

  @default_mime "application/octet-stream"

  @type outcome ::
          {:saved, map()}
          | {:shared, map()}
          | {:dismissed, map()}
          | :cancelled
          | {:error, reason()}
          | :ignore

  @type reason ::
          :no_bridge
          | :no_activity
          | :source_missing
          | :bad_request
          | :write_failed
          | :share_failed
          | :not_a_file
          | {:native, String.t()}

  @doc """
  Whether the native transport is bound.

  `false` on the host and on iOS. Check it before offering a Save button, so
  the user is told the truth rather than tapping something that answers
  nothing.
  """
  @spec available?() :: boolean()
  defdelegate available?(), to: Bridge

  @doc """
  Open the system Save As… dialog for `path`.

  Options:

    * `:name` — the filename to pre-fill. Defaults to the basename of `path`.
      This is what `Kati.Backup.suggested_filename/1` is for.
    * `:mime` — defaults to `#{@default_mime}`, which is right for a
      `.katibackup`: a more specific type invites the picker to rename the file
      to match it.

  Returns `:ok` once the dialog is open. The save itself reports back as a
  message — see `decode/1`.
  """
  @spec save_as(Path.t(), keyword()) :: :ok | {:error, reason()}
  def save_as(path, opts \\ []) when is_binary(path) do
    with :ok <- check_file(path) do
      request(path, opts) |> then(&call(:file_save_as, &1))
    end
  end

  @doc """
  Open the system share sheet for `path`.

  Takes the same options as `save_as/2`, plus `:subject` — the title the sheet
  shows and the subject line a mail app pre-fills.

  Read the "Share cannot tell you whether the share happened" section of this
  module's docs before using this as a backup route. It is not one.
  """
  @spec share(Path.t(), keyword()) :: :ok | {:error, reason()}
  def share(path, opts \\ []) when is_binary(path) do
    with :ok <- check_file(path) do
      path
      |> request(opts)
      |> Map.put("subject", Keyword.get(opts, :subject, Path.basename(path)))
      |> then(&call(:file_share, &1))
    end
  end

  @doc """
  Open the system document picker. Delegates to `Mob.Files.pick/2`, which
  already works on both platforms.

  Here rather than at the call site so that every file crossing Kati's boundary
  goes through one module, and so the Android caveat is written down once:
  **SAF filters by MIME type only**, and `.katibackup` has no registered MIME,
  so the picker cannot be narrowed and the user can still choose the wrong
  file. Enforce on the result with `Mob.Files.accept/2` — which works now that
  `K-20 file-picker-display-name` makes the returned `:name` an actual
  filename rather than a provider-internal document id.
  """
  @spec pick(Mob.Socket.t(), keyword()) :: Mob.Socket.t()
  def pick(socket, opts \\ []) do
    Mob.Files.pick(socket, opts)
  end

  @doc """
  Turn a transport message into a value, or `:ignore` if it is not one.

  Pure, and the only part of this module a host test can exercise. Kati runs
  one screen process, so `handle_info/2` sees everything the BEAM sends it —
  `:ignore` is what keeps an unrelated message from matching a transport
  clause by accident.

      iex> Kati.Native.Files.decode({:kati_files, :cancelled})
      :cancelled
      iex> Kati.Native.Files.decode({:kati_files, :error, [%{reason: "source_missing"}]})
      {:error, :source_missing}
      iex> Kati.Native.Files.decode({:tick, 1})
      :ignore
  """
  @spec decode(term()) :: outcome()
  def decode({@event, :cancelled}), do: :cancelled

  def decode({@event, :saved, [item | _]}), do: {:saved, saved_item(item)}

  def decode({@event, :shared, [item | _]}), do: {:shared, %{name: string(item[:name])}}

  def decode({@event, :dismissed, [item | _]}), do: {:dismissed, %{name: string(item[:name])}}

  def decode({@event, :error, [item | _]}), do: {:error, reason_atom(string(item[:reason]))}

  def decode({@event, sub, []}) when is_atom(sub), do: {:error, :bad_request}

  def decode(_other), do: :ignore

  # ── internals ───────────────────────────────────────────────────────────

  defp check_file(path) do
    if File.regular?(path), do: :ok, else: {:error, :not_a_file}
  end

  defp request(path, opts) do
    %{
      "path" => path,
      "name" => Keyword.get(opts, :name, Path.basename(path)),
      "mime" => Keyword.get(opts, :mime, @default_mime)
    }
  end

  defp call(fun, payload) when is_map(payload) do
    case Bridge.reply(fun, [Bridge.encode(payload)]) do
      {:ok, reply} -> ack(Bridge.split(reply))
      {:error, :no_bridge} -> {:error, :no_bridge}
      {:error, other} -> {:error, other}
    end
  end

  defp ack({:ok, _payload}), do: :ok
  defp ack({:error, reason}), do: {:error, reason_atom(reason)}

  defp saved_item(item) do
    %{
      path: string(item[:path]),
      name: string(item[:name]),
      bytes: integer(item[:bytes]),
      uri: string(item[:uri])
    }
  end

  defp string(value) when is_binary(value), do: value
  defp string(_value), do: nil

  defp integer(value) when is_integer(value), do: value
  defp integer(_value), do: 0

  # A closed set. A native reply never reaches String.to_atom — the atom table
  # is not garbage collected and the bridge's vocabulary is not Kati's to bound
  # once it has drifted.
  defp reason_atom("no_activity"), do: :no_activity
  defp reason_atom("source_missing"), do: :source_missing
  defp reason_atom("bad_request"), do: :bad_request
  defp reason_atom("write_failed"), do: :write_failed
  defp reason_atom("share_failed"), do: :share_failed
  defp reason_atom(reason) when reason in ~w(no_jvm no_bridge no_method no_pid), do: :no_bridge
  defp reason_atom(other) when is_binary(other), do: {:native, other}
  defp reason_atom(_other), do: :bad_request

  @doc """
  Rasterise what is on screen and hand it to the document picker.

  The two halves of *Save image*, joined. `Kati.Nifs.KatiBridge.capture_screen/1`
  writes a PNG of the app's own content area into the cache directory — never
  anywhere the user can see, because a capture that wrote to Pictures itself
  would be saving without being asked — and `save_as/2` is what puts it
  somewhere permanent, through the same `ACTION_CREATE_DOCUMENT` picker every
  other file in Kati goes through.

  Screen 121's button said **Save image** and did nothing from the day it was
  drawn. `Kati.ScreenTapSweepTest` recorded it as *blocked on a capability the
  app does not have*, and the missing half was never the saving.

  Returns `:ok` once the picker is open, which is what `save_as/2` returns and
  means the same thing: the save itself reports back as a message.
  """
  @spec save_screen(String.t()) :: :ok | {:error, term()}
  def save_screen(name) when is_binary(name) do
    with {:ok, path} <- capture(name) do
      save_as(path, name: name, mime: "image/png")
    end
  end

  @doc false
  @spec capture(String.t()) :: {:ok, Path.t()} | {:error, term()}
  def capture(name) when is_binary(name) do
    case Bridge.reply(:capture_screen, [name]) do
      {:ok, "ok:" <> path} -> {:ok, path}
      {:ok, "error:" <> reason} -> {:error, String.to_atom(reason)}
      {:ok, _other} -> {:error, :capture_failed}
      {:error, why} -> {:error, why}
    end
  end
end
