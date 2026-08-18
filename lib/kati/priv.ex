defmodule Kati.Priv do
  @moduledoc """
  The one way Kati locates a bundled asset.

  ## The rule

  `Kati.Priv.path/1`, never `Application.app_dir/2` and never
  `:code.priv_dir/1`.

  `:code.priv_dir/1` resolves an app's `priv/` by walking the versioned
  `$OTP_ROOT/lib/APP-VSN/ebin/` layout of a normal OTP release. Mob deploys
  `.beam` files **flat** into a single `-pa` directory with no such
  structure, so `:code.priv_dir(:kati)` returns `{:error, :bad_name}` and
  `Application.app_dir/2` raises. mob_dev's own source says so at
  `deployer.ex:483-499`.

  The failure is silent and expensive. `Ecto.Migrator.run/3` given a path
  that does not exist finds zero migrations, logs "Migrations already up",
  creates no tables, and the first query crashes a screen GenServer — which
  the user sees as a frozen screen with no error.

  ## Why `MOB_BEAMS_DIR` is correct in a release too

  This was verified rather than assumed, because five features bundle assets
  (the CA certificates, the Nowruz table, fonts, the timezone database, the
  food database) and the production failure mode is a crash on a user's
  phone with no build-time warning.

  `mob_beam.zig:259` computes `beams_dir = "{otp_root}/{app_module}"` from
  `getFilesDir()` at runtime and exports it as `MOB_BEAMS_DIR`. Both build
  paths put `priv/` in exactly that directory:

    * **dev** — `deployer.ex:511` pushes `priv/` to `{beams_dir}/priv/`.
    * **release** — `release_android.ex:110` copies `priv/` to
      `{staging}/{app_name}/priv`, which is zipped into `otp.zip` and
      extracted to `{filesDir}/otp/{app_name}/priv`.

  The two converge on the same absolute path, so one lookup serves both.
  `MOB_BEAMS_DIR` is the only reliable channel: the path contains the
  Android user id and is not knowable at compile time.

  ## What is not safe to bundle

  The release slimming pass deletes static archives with a **global**
  `find <staging> -type f -name "*.a" -delete`
  (`otp_asset_bundle.ex:strip_static_archives`). It is not scoped to
  `lib/`, so an asset under `priv/` whose name ends in `.a` is deleted from
  the release bundle and survives dev — the worst shape of bug, one that
  only appears in production. Do not name a bundled asset `*.a`.
  `probe/2` enforces this.
  """

  @probe_marker "kati-priv-probe-v1"

  @doc """
  Absolute path to a file or directory inside the app's `priv/`.

  Falls back to `Application.app_dir/2` off-device, where there is no
  `MOB_BEAMS_DIR` and the normal layout does apply — that is what makes the
  test suite able to read the same assets on the host.
  """
  @spec path(String.t()) :: String.t()
  def path(relative) do
    case System.get_env("MOB_BEAMS_DIR") do
      nil -> Application.app_dir(:kati, Path.join("priv", relative))
      beams_dir -> Path.join([beams_dir, "priv", relative])
    end
  end

  @doc """
  Reports what is actually reachable, so a broken bundle is loud instead of
  silent.

  Checks the three lookup mechanisms and reads back the probe assets that
  ship in `priv/probe/`. The binary one is a real SQLite file: a truncated
  or re-encoded asset is a different failure from a missing one, and only a
  byte comparison tells them apart.
  """
  @spec probe() :: %{ok?: boolean(), lines: [String.t()]}
  def probe do
    beams = System.get_env("MOB_BEAMS_DIR")
    text = path("probe/nested/deep.txt")
    binary = path("probe/probe.db")

    text_read = File.read(text)
    binary_read = File.read(binary)

    nested_ok? = match?({:ok, @probe_marker <> _}, text_read)
    binary_ok? = with {:ok, b} <- binary_read, do: sqlite_marker(b)

    lines = [
      "MOB_BEAMS_DIR      = #{beams || "(unset — host)"}",
      "code:priv_dir      = #{inspect(:code.priv_dir(:kati))}",
      "app_dir            = #{inspect(safe_app_dir())}",
      "Kati.Priv.path     = #{path("")}",
      "nested text        = #{describe(text_read)} #{if nested_ok?, do: "marker ok", else: "MARKER MISSING"}",
      "binary sqlite      = #{describe(binary_read)} #{if binary_ok?, do: "bytes intact", else: "BYTES CORRUPT"}",
      "migrations dir     = #{describe_dir(path("repo/migrations"))}",
      "cacerts.pem        = #{describe(File.read(path("cacerts.pem")))}"
    ]

    %{ok?: nested_ok? and binary_ok?, lines: lines}
  end

  @doc """
  Names under `priv/` that the release slimming pass would delete.

  Returns `[]` when the bundle is safe. Called by a test, so a `*.a` asset
  can never be added without the suite failing.
  """
  @spec unsafe_assets(Path.t()) :: [Path.t()]
  def unsafe_assets(root) do
    Path.wildcard(Path.join(root, "**/*.a")) ++ Path.wildcard(Path.join(root, "bin/*"))
  end

  # The marker lives in a table, but reading it needs a DB connection this
  # early. Matching the header plus the raw marker bytes proves the file
  # arrived whole without opening it.
  defp sqlite_marker(<<"SQLite format 3", 0, _::binary>> = bytes),
    do: :binary.match(bytes, @probe_marker) != :nomatch

  defp sqlite_marker(_), do: false

  defp describe({:ok, bytes}), do: "#{byte_size(bytes)} bytes"
  defp describe({:error, reason}), do: "MISSING (#{:file.format_error(reason)})"

  defp describe_dir(dir) do
    case File.ls(dir) do
      {:ok, entries} -> "#{length(entries)} entries"
      {:error, reason} -> "MISSING (#{:file.format_error(reason)})"
    end
  end

  defp safe_app_dir do
    Application.app_dir(:kati, "priv")
  rescue
    e -> {:raised, e.__struct__}
  end
end
