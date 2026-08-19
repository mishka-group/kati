defmodule Kati.PrivTest do
  @moduledoc """
  Guards the bundled-asset contract that #72 established.

  Five features ship files in `priv/` — the CA certificates, the Nowruz
  table, fonts, the timezone database and the food database. Every failure
  in this area is silent at build time and fatal at runtime on a user's
  phone, so each rule that was verified by hand there is held here instead.
  """
  # NOT async: these mutate `MOB_BEAMS_DIR`, which is process-global. Run
  # concurrently with anything else that reads or clears it — as the priv
  # probe tests do — and they race: one test's setup deletes the variable
  # another is mid-assertion on. It failed roughly one run in three.
  use ExUnit.Case, async: false

  # The deploy tooling exports MOB_BEAMS_DIR — a DEVICE path — and it leaks
  # into a shell that later runs the suite. `Kati.Priv.path/1` then resolves
  # assets to /data/user/0/... on the host and every probe reports MISSING.
  # The tests are about the bundle, not about whoever's shell ran them.
  setup do
    case System.fetch_env("MOB_BEAMS_DIR") do
      {:ok, value} ->
        System.delete_env("MOB_BEAMS_DIR")
        on_exit(fn -> System.put_env("MOB_BEAMS_DIR", value) end)

      :error ->
        :ok
    end

    :ok
  end

  describe "probe/0" do
    test "reports a healthy bundle and reads every asset back" do
      assert %{ok?: true, lines: lines} = Kati.Priv.probe()

      refute Enum.any?(lines, &(&1 =~ "MISSING")),
             "an asset did not resolve:\n" <> Enum.join(lines, "\n")

      refute Enum.any?(lines, &(&1 =~ "CORRUPT"))
    end

    test "the binary probe is byte-identical to the source asset" do
      assert File.read!(Kati.Priv.path("probe/probe.db")) ==
               File.read!("priv/probe/probe.db")
    end

    test "a nested path survives, because flattening is a plausible failure" do
      assert File.read!(Kati.Priv.path("probe/nested/deep.txt")) =~ "kati-priv-probe-v1"
    end
  end

  describe "the release slimming pass" do
    @doc_ref "otp_asset_bundle.ex:strip_static_archives"

    test "no asset is named in a way the release build deletes (#{@doc_ref})" do
      # `find <staging> -type f -name "*.a" -delete` is global, not scoped to
      # lib/, and `lib/*/priv/bin/*` is stripped too. Either one removes a
      # bundled asset from the RELEASE build only — it survives every dev
      # deploy, so the first sign would be a crash in production.
      assert Kati.Priv.unsafe_assets("priv") == []
    end
  end

  describe "the device boot path" do
    setup do
      # Application.spec/2 answers nil for an unloaded app, which would make
      # every assertion below vacuously pass.
      Application.load(:ash)
      :ok
    end

    test "igniter is never started, because the OTP runtime has no :inets" do
      # ash.app names :igniter — a codegen tool — in its runtime
      # `applications`, and igniter requires :inets, which the Android OTP
      # runtime does not ship. ensure_all_started(:ash) therefore kills the
      # BEAM on a fresh install. Kati starts ash's dependencies directly and
      # skips this list.
      assert :igniter in Application.spec(:ash, :applications),
             "if Ash has dropped igniter from its applications, delete the " <>
               "workaround in Kati.App.start_ash!/0"

      assert :igniter in Kati.App.never_start_on_device()
    end

    test "ash is a library app with nothing to start" do
      # Justifies loading rather than starting it.
      assert Application.spec(:ash, :mod) in [nil, []]
    end
  end
end

defmodule Kati.ScreenDateTest do
  @moduledoc """
  A screen must never derive a date from UTC.

  Found by using the app just after midnight: the Calendar header read
  "Tuesday 18" while the device clock said Wednesday 19. Amsterdam is UTC+2
  in summer, so for the first two hours of every day a UTC-derived date names
  yesterday — and the greeting says "Good evening" over breakfast.
  """
  use ExUnit.Case, async: true

  @screens Path.wildcard("lib/kati/screens/*.ex")

  test "no screen calls DateTime.utc_now/0 or Date.utc_today/0" do
    offenders =
      for path <- @screens,
          line <- String.split(File.read!(path), "\n"),
          String.contains?(line, "DateTime.utc_now") or String.contains?(line, "Date.utc_today"),
          not String.starts_with?(String.trim(line), "#"),
          do: "#{path}: #{String.trim(line)}"

    assert offenders == [],
           "screens must use Kati.Time.now/0 or Kati.Time.today/0:\n" <>
             Enum.join(offenders, "\n")
  end

  test "Kati.Time.today/0 agrees with the device zone, not UTC" do
    # Deliberately a zone far from UTC so the two genuinely differ for most
    # of the day; the assertion is that today/0 tracks the zone.
    zone = "Pacific/Kiritimati"
    expected = DateTime.utc_now() |> DateTime.shift_zone!(zone) |> DateTime.to_date()

    assert expected == DateTime.utc_now() |> Kati.Time.in_zone(zone) |> DateTime.to_date()
  end
end
