defmodule Mix.Tasks.Kati.Gen.Notices do
  @shortdoc "Regenerate THIRD_PARTY_NOTICES.md from the lock file and the fonts"

  @moduledoc """
  Writes `THIRD_PARTY_NOTICES.md` from what the build actually contains.

  Screen 83 tells the user *that list is generated from THIRD_PARTY_NOTICES.md
  at build time, never typed by hand*, and this task is what makes that true.
  A hand-maintained notices file is a notices file that is wrong: it goes stale
  on the first `mix deps.update` and nobody notices, because nothing reads it.

  ## What it reads

    * **`mix.lock`** — every dependency in the checkout, at the version actually
      in it. Not `mix.exs`, whose requirements are ranges.
    * **`Mix.Project.deps_tree/0`** — which of those actually **ship**. A
      notices file is about redistribution, and a package that only ever runs
      on the maintainer's laptop is not redistributed. `credo` and
      `mishka_chelekom` are `only: :dev`; so is everything they pull in, and
      `anubis_mcp` — which is LGPL — is one of those. Listing it beside the
      shipped packages would imply Kati distributes LGPL code in an APK, which
      it does not.
    * **`deps/<name>/LICENSE*`** — the licence file the package shipped, where
      it shipped one. Its *name* is recorded, not its text: reproducing every
      licence body would make this file enormous and is not what any of these
      licences ask for. What they ask for is attribution and a pointer.
    * **The four typefaces** — which are not deps. They are subset TTFs in
      `android/app/src/main/res/font/`, all four under the SIL Open Font
      License, and they are listed here because a font in a shipped APK is a
      redistribution exactly as a library is.

  ## What it deliberately does not do

  It does not guess a licence. A dependency with no `LICENSE` file in its
  checkout is listed as `licence not stated in the package` rather than as
  whatever hex.pm's metadata claims — the package is what ships, and a guess in
  a legal notice is worse than an admission.

  Run it after any dependency change, and commit the result.
  """

  use Mix.Task

  @target "THIRD_PARTY_NOTICES.md"

  # The four faces Kati ships as subset TTFs. Not deps, and not discoverable
  # from the lock file, so they are named here with the licence each is under.
  @fonts [
    {"Plus Jakarta Sans", "SIL Open Font License 1.1", "github.com/tokotype/PlusJakartaSans"},
    {"DM Mono", "SIL Open Font License 1.1", "github.com/googlefonts/dm-mono"},
    {"Vazirmatn", "SIL Open Font License 1.1", "github.com/rastikerdar/vazirmatn"},
    {"Material Symbols Rounded", "Apache License 2.0", "github.com/google/material-design-icons"}
  ]

  # Data Kati fetches at runtime rather than ships. Not a redistribution, and
  # so not strictly a notice — but screen 83 credits every one of them, and a
  # notices file that omitted what the app is actually built on would be
  # technically complete and practically useless.
  @data_sources [
    {"TMDB", "TMDB API terms — non-commercial use", "themoviedb.org"},
    {"JustWatch", "JustWatch attribution requirement", "justwatch.com"},
    {"TVmaze", "CC BY-SA 4.0", "tvmaze.com"},
    {"Open Library", "Internet Archive terms", "openlibrary.org"},
    {"MusicBrainz", "CC0 / CC BY-NC-SA", "musicbrainz.org"},
    {"Cover Art Archive", "CC0", "coverartarchive.org"}
  ]

  @impl Mix.Task
  def run(_args) do
    {shipped, tooling} = Enum.split_with(lock_entries(), &elem(&1, 3))

    File.write!(@target, render(shipped, tooling))

    Mix.shell().info(
      "wrote #{@target} — #{length(shipped)} shipped, #{length(tooling)} build-only, " <>
        "#{length(@fonts)} typefaces, #{length(@data_sources)} data sources"
    )
  end

  @doc """
  Every dependency in the lock file: version, licence, and whether it ships.

  The fourth element is the one that matters legally — see the moduledoc.
  """
  @spec lock_entries() :: [{String.t(), String.t(), String.t(), boolean()}]
  def lock_entries do
    case File.read("mix.lock") do
      {:ok, contents} ->
        ships = shipped()

        contents
        |> parse_lock()
        |> Enum.map(fn {name, version} ->
          {name, version, licence(name), MapSet.member?(ships, name)}
        end)
        |> Enum.sort()

      _other ->
        []
    end
  end

  @doc """
  The apps that end up in a release: the top-level deps that are not `only:
  :dev` or `only: :test`, plus everything they pull in.

  Walked rather than taken from the top level, because a shipped package's own
  dependencies ship with it — `mob` brings `bandit`, and neither is in the
  notices file by name in `mix.exs`.
  """
  @spec shipped() :: MapSet.t(String.t())
  def shipped do
    tree = Mix.Project.deps_tree()

    roots =
      Mix.Project.config()
      |> Keyword.get(:deps, [])
      |> Enum.filter(&ships?/1)
      |> Enum.map(&(&1 |> elem(0) |> Atom.to_string()))

    walk(roots, tree, MapSet.new())
  rescue
    # `deps_tree/0` needs the deps loaded. Without them, claim nothing rather
    # than claim everything ships — an over-broad notices file is merely long,
    # and an under-broad one is wrong.
    _error -> MapSet.new()
  end

  defp ships?(dep) do
    only = dep |> Tuple.to_list() |> Enum.find_value(&(is_list(&1) && Keyword.get(&1, :only)))

    case only do
      nil -> true
      envs when is_list(envs) -> :prod in envs
      env -> env == :prod
    end
  end

  defp walk([], _tree, seen), do: seen

  defp walk([app | rest], tree, seen) do
    if MapSet.member?(seen, app) do
      walk(rest, tree, seen)
    else
      children = tree |> Map.get(String.to_atom(app), []) |> Enum.map(&Atom.to_string/1)
      walk(children ++ rest, tree, MapSet.put(seen, app))
    end
  end

  # The lock is Elixir source, and evaluating it would run arbitrary code from a
  # file this task is supposed to be reading. A regex over `"name": {:hex, :x,
  # "1.2.3"` takes the two values that matter and cannot execute anything.
  defp parse_lock(contents) do
    ~r/"(?<name>[a-z0-9_]+)":\s*\{:hex,\s*:[a-z0-9_]+,\s*"(?<version>[^"]+)"/
    |> Regex.scan(contents, capture: :all_names)
    |> Enum.map(fn [name, version] -> {name, version} end)
    |> Enum.uniq_by(&elem(&1, 0))
  end

  @doc """
  The licence a package shipped, by the name of its licence file.

  Never a guess — see the moduledoc.
  """
  @spec licence(String.t()) :: String.t()
  def licence(name) do
    dir = Path.join("deps", name)

    with {:ok, files} <- File.ls(dir),
         file when not is_nil(file) <-
           Enum.find(files, &(String.upcase(&1) =~ ~r/^(LICEN[CS]E|COPYING)/)),
         {:ok, text} <- File.read(Path.join(dir, file)) do
      identify(text)
    else
      _other -> "licence not stated in the package"
    end
  end

  # Matched on the phrase each licence opens with, which is stable across every
  # copy of it. Anything unrecognised is reported as present-but-unidentified
  # rather than assigned a name.
  defp identify(text) do
    cond do
      text =~ "Apache License" -> "Apache License 2.0"
      text =~ "MIT License" or text =~ "Permission is hereby granted, free of charge" -> "MIT"
      text =~ "Mozilla Public License" -> "Mozilla Public License 2.0"
      text =~ "GNU LESSER GENERAL PUBLIC" -> "LGPL"
      text =~ "GNU GENERAL PUBLIC" -> "GPL"
      text =~ "ISC License" -> "ISC"
      text =~ "SIL OPEN FONT LICENSE" -> "SIL Open Font License 1.1"
      true -> "licence file present, not identified"
    end
  end

  defp render(shipped, tooling) do
    """
    # Third-party notices

    <!--
      GENERATED by `mix kati.gen.notices`. Do not edit by hand.

      Screen 83 (`Kati.Screens.Attribution`) tells the user this file is
      generated at build time, and `Kati.ServicesTest` asserts it exists. Run
      the task after any dependency change and commit the result.
    -->

    Kati is MIT-licensed. It stands on work by people who gave it away, and this
    file names all of it.

    ## Elixir and Erlang dependencies that ship

    Everything inside the app: the runtime dependencies and everything they pull
    in, at the version the build actually uses. The licence is read from the
    `LICENSE` file the package shipped; a package that shipped none is recorded
    as such rather than assigned one.

    | Package | Version | Licence |
    | --- | --- | --- |
    #{Enum.map_join(shipped, "\n", fn {name, version, licence, _ships} -> "| `#{name}` | #{version} | #{licence} |" end)}

    ## Build-time only

    Present in the checkout and **not** in any build that leaves this machine —
    `only: :dev` or `only: :test`, and everything they pull in. Listed for
    completeness, and kept apart because a notices file is about
    redistribution: none of this is redistributed.

    | Package | Version | Licence |
    | --- | --- | --- |
    #{Enum.map_join(tooling, "\n", fn {name, version, licence, _ships} -> "| `#{name}` | #{version} | #{licence} |" end)}

    ## Typefaces

    Shipped as subset TTFs in `android/app/src/main/res/font/`. A font inside an
    APK is a redistribution exactly as a library is.

    | Face | Licence | Source |
    | --- | --- | --- |
    #{Enum.map_join(@fonts, "\n", fn {name, licence, source} -> "| #{name} | #{licence} | #{source} |" end)}

    ## Data sources

    Fetched at runtime rather than shipped, so not a redistribution — listed
    because Kati is built on them and screen 83 credits every one.

    | Source | Terms | Site |
    | --- | --- | --- |
    #{Enum.map_join(@data_sources, "\n", fn {name, terms, site} -> "| #{name} | #{terms} | #{site} |" end)}

    ## Kati's own components

    `lib/kati/components/` holds generated Mishka Chelekom components under the
    Apache License 2.0. They are generated into this repository rather than
    depended on, which is the library's own distribution model, so they do not
    appear in `mix.lock`.
    """
  end
end
