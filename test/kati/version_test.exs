defmodule Kati.VersionTest do
  @moduledoc """
  One version, four fields, and `mix.exs` is the source of truth.

  This file is the reason `mix kati.version --check` cannot be forgotten. The
  three files carried three different numbers for a long time — `mix.exs` said
  `0.1.2`, Gradle said `versionName "1.0"`, the plist said `1.0` — and nothing
  noticed, because nothing was looking. This looks.
  """
  use ExUnit.Case, async: true

  @gradle Path.expand("../../android/app/build.gradle", __DIR__)
  @plist Path.expand("../../ios/Info.plist", __DIR__)

  defp version, do: Mix.Project.config()[:version]

  defp capture!(path, pattern, field) do
    body = File.read!(path)

    case Regex.run(pattern, body, capture: :all_but_first) do
      [value] ->
        value

      nil ->
        flunk(
          "#{Path.basename(path)} has no #{field} field at all. `mix kati.version` writes it; " <>
            "if the field moved, this test has to move with it"
        )
    end
  end

  test "the human-readable version is mix.exs's, in both native trees" do
    gradle = capture!(@gradle, ~r/versionName\s+"([^"]*)"/, "versionName")

    plist =
      capture!(
        @plist,
        ~r/<key>CFBundleShortVersionString<\/key>\s*<string>([^<]*)<\/string>/,
        "CFBundleShortVersionString"
      )

    assert gradle == version(),
           "android/app/build.gradle says #{gradle}, mix.exs says #{version()}. " <>
             "Run `mix kati.version`."

    assert plist == version(),
           "ios/Info.plist says #{plist}, mix.exs says #{version()}. Run `mix kati.version`."
  end

  test "the build code is a monotonic integer and the two trees agree on it" do
    # Both stores and both installers refuse a build whose number did not go
    # up, and the two platforms have to agree or a release is two releases.
    gradle = capture!(@gradle, ~r/versionCode\s+(\d+)/, "versionCode")

    plist =
      capture!(
        @plist,
        ~r/<key>CFBundleVersion<\/key>\s*<string>([^<]*)<\/string>/,
        "CFBundleVersion"
      )

    assert gradle == plist,
           "versionCode #{gradle} and CFBundleVersion #{plist} disagree. Run `mix kati.version`."

    assert {code, ""} = Integer.parse(gradle)
    assert code > 0, "the build code must be a positive integer, got #{gradle}"
  end

  test "the version is a plain three-part number" do
    # `mix kati.version` writes whatever mix.exs holds straight into a plist
    # and a Gradle string. A pre-release suffix is legal in Elixir and illegal
    # in CFBundleShortVersionString, so the constraint belongs here rather than
    # being discovered by a build.
    assert Regex.match?(~r/^\d+\.\d+\.\d+$/, version()),
           "#{version()} is not `major.minor.patch`. CFBundleShortVersionString takes no suffix."
  end
end
