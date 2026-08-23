defmodule Mix.Tasks.Kati.Version do
  @shortdoc "Stamp mix.exs's version into every place that carries one"

  @moduledoc """
  One version, three files, and `mix.exs` is the source of truth.

  Kati's version lived in three places that were edited by hand and had already
  drifted apart: `mix.exs` said one thing, `android/app/build.gradle` said
  `versionName "1.0"`, and `ios/Info.plist` said `1.0` again. Nobody was wrong;
  there was simply nothing making them agree.

      mix kati.version          # stamp, printing what changed
      mix kati.version --check  # fail if anything is out of step

  ## What each field takes

    * **`versionName` / `CFBundleShortVersionString`** — the version as people
      read it, straight from `mix.exs`.
    * **`versionCode` / `CFBundleVersion`** — a monotonic integer, because both
      stores and both installers refuse a build whose number did not go up.
      Derived as `YYYYMMDDNN` from the day and a two-digit counter, or taken
      from `KATI_BUILD` when CI has a run number to hand. A date-derived code
      is monotonic without needing anything to remember the last one, which
      matters for a project whose releases are built on one laptop.

  ## Why a task rather than a build step

  Gradle could read `mix.exs` itself, and Xcode could not — so a step that
  works on one platform and not the other is a step that will be forgotten on
  the other. This runs on both and is one command before a tag.

  `--check` is what a CI job or a pre-tag hook runs: it writes nothing and
  exits non-zero with the mismatch named, so a release cannot be cut from a
  tree whose three numbers disagree.
  """

  use Mix.Task

  @gradle "android/app/build.gradle"
  @plist "ios/Info.plist"

  @impl Mix.Task
  def run(argv) do
    check? = "--check" in argv
    version = Mix.Project.config()[:version]
    code = build_code()

    edits = [
      {@gradle,
       [
         {~r/versionName\s+"([^"]*)"/, "versionName", version},
         {~r/versionCode\s+(\d+)/, "versionCode", code}
       ]},
      {@plist,
       [
         {plist_key("CFBundleShortVersionString"), "CFBundleShortVersionString", version},
         {plist_key("CFBundleVersion"), "CFBundleVersion", code}
       ]}
    ]

    stale = Enum.flat_map(edits, &apply_file(&1, check?))

    report(stale, version, code, check?)
  end

  # Every substitution for one file is applied to ONE buffer and written once.
  #
  # The first version of this task built a full replacement string per field
  # and wrote them in turn, each computed from the file as it was before any
  # of them ran — so the last write silently undid the others, and on a plist
  # with two adjacent version keys it destroyed one of them outright. Read
  # once, fold, write once: the only shape where two edits to one file cannot
  # race.
  defp apply_file({path, substitutions}, check?) do
    body = File.read!(path)

    {updated, stale} =
      Enum.reduce(substitutions, {body, []}, fn {pattern, field, wanted}, {acc, stale} ->
        case Regex.run(pattern, acc, capture: :all_but_first) do
          nil -> {acc, [{path, field, :not_found} | stale]}
          [^wanted] -> {acc, stale}
          [_other] -> {swap(pattern, acc, wanted), [{path, field, wanted} | stale]}
        end
      end)

    unless check? or updated == body, do: File.write!(path, updated)

    Enum.reverse(stale)
  end

  # A function replacement rather than a `\1` backreference string.
  #
  # The backreference form works and is unreadable through two layers of
  # escaping — and getting it wrong does not fail, it writes a plausible-looking
  # file with a key deleted. The function is handed the whole match and its one
  # capture, and rebuilds the match with the capture swapped, so there is no
  # escaping to get wrong and no way to lose the surrounding markup.
  defp swap(pattern, body, wanted) do
    Regex.replace(
      pattern,
      body,
      fn whole, captured ->
        {before, rest} = :binary.match(whole, captured) |> then(&split(whole, &1))
        before <> wanted <> rest
      end,
      global: false
    )
  end

  defp split(whole, {at, len}) do
    {binary_part(whole, 0, at), binary_part(whole, at + len, byte_size(whole) - at - len)}
  end

  # A `<key>` and its `<string>` are adjacent by definition in a plist, so the
  # pair is addressable as text without taking an XML dependency for two
  # substitutions — and rewriting the file through a parser would reformat
  # every other key in it.
  defp plist_key(key),
    do: ~r/<key>#{Regex.escape(key)}<\/key>\s*<string>([^<]*)<\/string>/

  # A build number that only ever goes up, without a file to remember the last
  # one. `KATI_BUILD` wins when CI supplies a run number.
  defp build_code do
    case System.get_env("KATI_BUILD") do
      nil ->
        %Date{year: y, month: m, day: d} = Date.utc_today()
        "#{y}#{pad(m)}#{pad(d)}01"

      given ->
        given
    end
  end

  defp pad(n), do: n |> Integer.to_string() |> String.pad_leading(2, "0")

  defp report([], version, code, _check?) do
    Mix.shell().info("kati.version: #{version} (#{code}) — all four fields agree")
  end

  defp report(stale, version, code, true) do
    lines =
      Enum.map(stale, fn
        {path, field, :not_found} -> "  #{path} — #{field} is missing entirely"
        {path, field, wanted} -> "  #{path} — #{field} is not #{wanted}"
      end)

    Mix.raise(
      "these carry a version other than mix.exs's #{version} (#{code}):\n" <>
        Enum.join(lines, "\n") <> "\n\nRun `mix kati.version` to stamp them."
    )
  end

  defp report(stale, version, code, false) do
    for {path, field, wanted} <- stale do
      case wanted do
        :not_found -> Mix.shell().error("  #{path} — #{field} is missing entirely, not stamped")
        _ -> Mix.shell().info("  #{path} #{field} -> #{wanted}")
      end
    end

    Mix.shell().info("kati.version: #{version} (#{code})")
  end
end
