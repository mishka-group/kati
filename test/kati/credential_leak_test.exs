defmodule Kati.CredentialLeakTest do
  @moduledoc """
  The ways a provider token could leave the place it is kept — in a backup, in
  a log or an error reason — and the one way a key could arrive from anywhere
  but the reader: the environment or a file at build time.

  Every test plants a canary — a value shaped like a token and used nowhere
  else — in every place a token can sit on a host, and then looks for it where
  it must not be. A canary rather than a real token, so a failure message can
  print what it found without printing anybody's credential.

  The storage rules themselves — no credential-shaped column, no
  credential-shaped `Mob.State` key, no fallback write in `Kati.SecureStore` —
  are `Kati.SecureStoreTest`'s. This file is about the exits.
  """
  use Mob.ScreenCase, async: false

  import ExUnit.CaptureLog

  alias Kati.Backup.Catalog
  alias Kati.Media.Tmdb

  @canary "kati-canary-eyJhbGciOiJIUzI1NiJ9.leak-test-token"

  @credential_shaped ~r/token|password|passwd|secret|api_?key|credential|bearer/i

  # A design-system colour name, not a secret — `Kati.Calendars.Calendar`
  # says so where it declares it.
  @not_a_credential [:colour_token]

  defmodule Adapter do
    @moduledoc false
    def run(request), do: Application.fetch_env!(:kati, :credential_leak_stub).(request)
  end

  setup do
    Application.put_env(:kati, :tmdb_test_token, @canary)

    on_exit(fn ->
      Application.delete_env(:kati, :tmdb_test_token)
      Application.delete_env(:kati, :tmdb_req_options)
      Application.delete_env(:kati, :credential_leak_stub)
    end)

    :ok
  end

  defp stub(fun) do
    Application.put_env(:kati, :credential_leak_stub, fun)
    Application.put_env(:kati, :tmdb_req_options, adapter: Adapter)
  end

  defp raw(term), do: inspect(term, limit: :infinity, printable_limit: :infinity, structs: false)

  describe "a backup" do
    test "carries no token from the environment, Mob.State or an account's keystore handle" do
      Mob.State.put(:credential_leak_canary, @canary)

      account =
        Kati.Calendars.Account
        |> Ash.Changeset.for_create(:create, %{
          provider: :caldav,
          account_name: "leak-test@example.org",
          display_name: "Leak test",
          credentials_ref: "caldav:" <> @canary,
          state: :live
        })
        |> Ash.create!()

      on_exit(fn -> Ash.destroy!(account) end)

      binary = Kati.Backup.export() |> Kati.Backup.to_binary()
      {:ok, members} = :zip.unzip(binary, [:memory])

      assert length(members) > 1, "the archive unpacked to nothing — this proves nothing"

      for {name, bytes} <- members do
        refute String.contains?(bytes, @canary),
               "#{name} in the backup carries a planted token"
      end

      assert Mob.State.get(:credential_leak_canary) == @canary,
             "the canary was not in Mob.State while the export ran"
    end

    test "every credential-shaped column of a backed-up table is written as null" do
      leaking =
        for entry <- Catalog.entries(),
            name <- Catalog.columns(entry),
            name not in @not_a_credential,
            Regex.match?(@credential_shaped, Atom.to_string(name)),
            name not in Catalog.dropped_columns(entry),
            do: "#{entry.table}.#{name}"

      assert leaking == [],
             "credential-shaped columns travel in every backup: #{inspect(leaking)} — " <>
               "drop them in Kati.Backup.Catalog or mark them sensitive?"

      assert "calendar_accounts" in Catalog.tables(),
             "the table the one keystore handle lives in is no longer backed up — revisit this test"
    end

    test "Kati.SecureStore offers nothing an exporter could enumerate" do
      refute function_exported?(Kati.SecureStore, :list, 0)
      refute function_exported?(Kati.SecureStore, :all, 0)
      refute function_exported?(Kati.SecureStore, :keys, 0)
    end
  end

  describe "the TMDB client" do
    test "the canary is the key in force, and it reaches the authorization header" do
      test_pid = self()

      stub(fn request ->
        send(test_pid, {:authorization, Req.Request.get_header(request, "authorization")})
        {request, Req.Response.new(status: 200, body: %{"results" => []})}
      end)

      assert {:ok, []} = Tmdb.search("leak test")
      assert_received {:authorization, ["Bearer " <> @canary]}
    end

    test "a transport error that quotes the header comes back without the token" do
      stub(fn request ->
        {request,
         %Mint.HTTPError{
           module: Mint.HTTP1,
           reason: {:invalid_header_value, "authorization", "Bearer " <> @canary}
         }}
      end)

      log =
        capture_log(fn ->
          assert {:error, reason} = Tmdb.search("leak test")
          refute raw(reason) =~ @canary, "the error reason carries the token"
          assert is_binary(Tmdb.message(reason))
        end)

      refute log =~ @canary
    end

    test "an exception that quotes the token comes back without it" do
      stub(fn _request -> raise "refused Bearer " <> @canary end)

      log =
        capture_log(fn ->
          assert {:error, reason} = Tmdb.search("leak test")
          refute raw(reason) =~ @canary, "the error reason carries the token"
        end)

      refute log =~ @canary
    end

    for status <- [401, 404, 429, 500] do
      test "a #{status} answer logs nothing and names no token" do
        stub(fn request ->
          {request, Req.Response.new(status: unquote(status), body: %{"status_message" => "x"})}
        end)

        log =
          capture_log(fn ->
            assert {:error, reason} = Tmdb.search("leak test")
            refute raw(reason) =~ @canary
          end)

        refute log =~ @canary
      end
    end

    test "the client itself has no way to write a line anywhere" do
      code =
        "lib/kati/media/tmdb.ex"
        |> File.read!()
        |> String.replace(~r/@(?:module)?doc\s+"""(?s).*?"""/, "")
        |> String.replace(~r/^\s*#.*$/m, "")

      assert code =~ "authorization",
             "comment stripping removed the code — this scan proves nothing"

      for forbidden <- ["Logger.", "IO.puts", "IO.inspect", "IO.write", "dbg(", ":logger."] do
        refute code =~ forbidden,
               "Kati.Media.Tmdb calls #{forbidden} — it holds a token in every request"
      end
    end
  end

  describe "a TMDB key" do
    test "comes from the reader's secure store and from nowhere else in lib" do
      refute function_exported?(Tmdb, :bundled?, 0)
      refute function_exported?(Tmdb, :compiled_key?, 0)
      refute Code.ensure_loaded?(Kati.Media.TmdbKeyFile)

      files = Path.wildcard(Path.join(Path.expand("../../lib", __DIR__), "**/*.{ex,exs}"))

      assert length(files) > 100,
             "found #{length(files)} files under lib — this scan proves nothing"

      for file <- files,
          forbidden <- ["TMDB_READ_TOKEN", "TMDB_TOKEN", "tmdb.env", "KATI_RELEASE_BUILD"] do
        refute File.read!(file) =~ forbidden,
               "#{file} names #{forbidden} — the reader's token is the only TMDB key"
      end
    end

    test "has no alias around mix mob.release any more, because there is nothing to refuse" do
      refute Mix.Project.config() |> Keyword.get(:aliases, []) |> Keyword.has_key?(:"mob.release")
    end
  end

  describe "an error reason on its way out" do
    doctest Kati.Net.Redact

    test "a CalDAV basic-auth header is caught whole or as its credential alone" do
      basic = Base.encode64("jo@example.org:app-specific-" <> @canary)

      for quoted <- ["Basic " <> basic, basic] do
        reason = {:invalid_header_value, "authorization", quoted}
        assert Kati.Net.Redact.reason(reason, ["Basic " <> basic, basic]) == :redacted
      end
    end

    test "a secret inside a list, a map and a struct is still found" do
      assert Kati.Net.Redact.reason([ok: %{nested: {"x", "…" <> @canary}}], [@canary]) ==
               :redacted

      assert Kati.Net.Redact.reason(%Mint.TransportError{reason: :closed}, [@canary]) ==
               %Mint.TransportError{reason: :closed}
    end
  end

  describe "the repository" do
    test "no tracked file carries a signed token" do
      root = Path.expand("../..", __DIR__)

      case System.cmd("git", ["ls-files", "-z"], cd: root, stderr_to_stdout: true) do
        {out, 0} ->
          files = out |> String.split(<<0>>, trim: true) |> Enum.map(&Path.join(root, &1))
          assert length(files) > 500, "git listed #{length(files)} files — not this repository"

          offenders =
            for file <- files,
                File.regular?(file),
                File.read!(file) =~ ~r/eyJ[\w-]{10,}\.eyJ[\w-]{10,}\.[\w-]{10,}/,
                do: Path.relative_to(file, root)

          assert offenders == [],
                 "a signed token (a TMDB read token is one) is committed in: #{inspect(offenders)}"

        {_out, _status} ->
          :ok
      end
    end
  end
end
