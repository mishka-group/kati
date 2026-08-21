defmodule Kati.NativeFilesTest do
  @moduledoc """
  What a host can prove about the file transport.

  It cannot open a share sheet, and it cannot write into a `content://` URI.
  What it can prove is everything on this side of JNI: that the transport
  reports itself absent rather than pretending, that a cancelled save is not an
  error, that a reply from a drifted bridge degrades to a value instead of a
  match error, and that no native reason string ever becomes an atom.

  The other half of the contract — that the Kotlin actually sends these
  shapes — is checked as source in `Kati.NativeNifChainTest` and in the
  "the Android half" section below.
  """
  use ExUnit.Case, async: true

  alias Kati.Native.Files

  @root Path.expand("../..", __DIR__)
  @bridge Path.join(@root, "android/app/src/main/java/com/example/kati/MobBridge.kt")
  @activity Path.join(@root, "android/app/src/main/java/com/example/kati/MainActivity.kt")
  @provider Path.join(@root, "android/app/src/main/res/xml/file_provider_paths.xml")

  setup do
    dir = Path.join(System.tmp_dir!(), "kati_files_#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)
    on_exit(fn -> File.rm_rf(dir) end)

    path = Path.join(dir, "kati-backup-2026-08-21.katibackup")
    File.write!(path, "not a real backup, but a real file")

    {:ok, dir: dir, path: path}
  end

  describe "with no native half" do
    test "the transport reports itself absent" do
      refute Files.available?()
    end

    test "save and share refuse rather than reporting a phantom success", %{path: path} do
      assert Files.save_as(path) == {:error, :no_bridge}
      assert Files.share(path) == {:error, :no_bridge}
    end

    test "a missing source file is refused before the bridge is consulted", %{dir: dir} do
      missing = Path.join(dir, "gone.katibackup")

      # :not_a_file rather than :no_bridge proves the check runs first — which
      # matters on a device, where :no_bridge never happens and this would
      # otherwise be a dialog opened over a file that does not exist.
      assert Files.save_as(missing) == {:error, :not_a_file}
      assert Files.share(missing) == {:error, :not_a_file}
    end

    test "a directory is not a file", %{dir: dir} do
      assert Files.save_as(dir) == {:error, :not_a_file}
    end
  end

  describe "decoding what the bridge sends back" do
    test "a completed save carries the byte count and the destination" do
      message =
        {:kati_files, :saved,
         [
           %{
             path: "/data/user/0/com.example.kati/files/x.katibackup",
             name: "x.katibackup",
             bytes: 2_119_483,
             uri: "content://com.android.providers.downloads/1"
           }
         ]}

      assert {:saved, saved} = Files.decode(message)
      assert saved.bytes == 2_119_483
      assert saved.name == "x.katibackup"
      assert saved.uri == "content://com.android.providers.downloads/1"
    end

    test "cancelling is its own answer and not an error" do
      # A user who backs out of the folder picker has done a normal thing. If
      # this ever becomes {:error, _} a settings screen starts telling people
      # their backup failed when they simply changed their mind.
      assert Files.decode({:kati_files, :cancelled}) == :cancelled
    end

    test "a closed share sheet is reported as dismissed, never as shared" do
      # Android returns RESULT_CANCELED from the chooser whether the user sent
      # the file or dismissed the sheet, so `shared` would be a guess printed
      # as a fact — on the one feature whose job is being trustworthy.
      assert Files.decode({:kati_files, :dismissed, [%{name: "x.katibackup"}]}) ==
               {:dismissed, %{name: "x.katibackup"}}

      assert Files.decode({:kati_files, :shared, [%{name: "x.katibackup"}]}) ==
               {:shared, %{name: "x.katibackup"}}
    end

    test "every reason the Kotlin can send maps to an atom" do
      for reason <- ~w(no_activity source_missing bad_request write_failed share_failed) do
        assert Files.decode({:kati_files, :error, [%{reason: reason}]}) ==
                 {:error, String.to_existing_atom(reason)}
      end
    end

    test "every way of having no bridge collapses to one reason" do
      for reason <- ~w(no_jvm no_bridge no_method no_pid) do
        assert Files.decode({:kati_files, :error, [%{reason: reason}]}) == {:error, :no_bridge}
      end
    end

    test "an unknown reason is carried as a string and creates no atom" do
      novel = "reason_#{System.unique_integer([:positive])}"

      assert Files.decode({:kati_files, :error, [%{reason: novel}]}) ==
               {:error, {:native, novel}}

      assert_raise ArgumentError, fn -> String.to_existing_atom(novel) end
    end

    test "a drifted or empty payload degrades instead of raising" do
      assert Files.decode({:kati_files, :saved, []}) == {:error, :bad_request}
      assert {:saved, %{bytes: 0, path: nil}} = Files.decode({:kati_files, :saved, [%{}]})
    end

    test "messages that are not the transport's are left alone" do
      # Kati runs ONE screen process, so handle_info/2 sees every message the
      # BEAM sends it. A decode/1 that matched loosely would swallow another
      # feature's message.
      for message <- [
            {:files, :picked, [%{name: "a"}]},
            {:mob_device, :did_become_active},
            {:kati_files_other, :saved, []},
            :tick,
            {:tick, 1}
          ] do
        assert Files.decode(message) == :ignore, "decode/1 claimed #{inspect(message)}"
      end
    end
  end

  describe "the Android half" do
    test "both intents are in the fence, and so are their result handlers" do
      region = fence(@bridge, "K-20 file-transport")

      assert region =~ "katiFileSaveAs"
      assert region =~ "katiFileShare"
      assert region =~ "handleKatiSaveAsResult"
      assert region =~ "handleKatiShareResult"

      launcher = fence(@activity, "K-20 file-transport-launcher")
      assert launcher =~ "ACTION_CREATE_DOCUMENT"
      assert launcher =~ "EXTRA_TITLE"
      assert region =~ "ACTION_SEND"
      assert region =~ "FLAG_GRANT_READ_URI_PERMISSION"
    end

    test "the share URI is served out of the cache directory, never filesDir" do
      # file_provider_paths.xml declares only <cache-path>. A <files-path> root
      # would let the provider hand kati.db and mob_state.dets to any app that
      # ever received a URI from Kati — the database is the thing the backup
      # exists to protect, not to publish.
      provider = File.read!(@provider)
      assert provider =~ "cache-path"

      refute provider =~ "files-path",
             "a files-path root exposes the whole of filesDir through the FileProvider"

      # Against the CODE, not the file: this fence's comment argues at length
      # about filesDir, so a raw-text check would be satisfied by the argument
      # surviving after the implementation had gone the other way.
      code = fence(@bridge, "K-20 file-transport") |> strip_comments()

      assert code =~ "getUriForFile",
             "comment stripping removed the implementation — this scan proves nothing"

      assert code =~ "cacheDir"

      refute code =~ "filesDir",
             "the share staging copy must not come from filesDir"
    end

    test "the copy never runs on the UI thread" do
      # A backup is megabytes. Copying it on the main thread ANRs on exactly
      # the phones with the most data to save.
      region = fence(@bridge, "K-20 file-transport")

      assert region =~ "Thread {",
             "the save-as and share copies must be off the main thread"

      assert region =~ "runOnUiThread",
             "launch() must be called from the main thread"
    end

    test "the picker reports a real filename, not a document id" do
      # SAF filters by MIME type and .katibackup has none registered, so the
      # extension is the only filter that works — and lastPathSegment is a
      # provider-internal id like msf:1000000123, with no extension at all.
      region = fence(@bridge, "K-20 file-picker-display-name")

      assert region =~ "OpenableColumns.DISPLAY_NAME"

      assert region =~ "org.json.JSONObject()",
             "hand-built JSON breaks on a filename containing a quote or a newline"
    end
  end

  defp strip_comments(source) do
    source
    |> String.replace(~r{/\*(?s).*?\*/}, "")
    |> String.replace(~r{//.*$}m, "")
  end

  defp fence(path, label) do
    [region] =
      Regex.run(
        ~r/KATI-BEGIN\(#{Regex.escape(label)}\)(?s).*?KATI-END\(#{Regex.escape(label)}\)/,
        File.read!(path)
      )

    region
  end
end
