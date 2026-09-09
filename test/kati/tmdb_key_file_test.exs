defmodule Kati.TmdbKeyFileTest do
  @moduledoc """
  The token reaches a device build without anybody remembering a shell step.

  `Kati.Media.Tmdb` captures a TMDB token at compile time so it can travel in
  the BEAM `mix kati.e2e.stage` pushes — a phone has no environment to read one
  from. The capture was `System.get_env/1`, so it depended on whether the shell
  that ran the task had sourced `~/.config/kati/tmdb.env`.

  Two builds went out without a key on 6 September because a `mix` invocation
  in a different shell had not. Nothing said so, and nothing could: a device
  with a keyless build and a device nobody has given a token are identical from
  the inside — screen 06 returns no results, and screen 11 says there is no
  token. It took reading `{:error, :no_api_key}` off the device to find it.

  So the documented file is parsed directly. This is that parser, and the one
  thing it must never do is raise: it runs at compile time, and a credential
  that is allowed to be absent must not be able to fail a build.

  No real token is read here. Every fixture is written into the test's own
  temporary directory, and the assertions are about shapes.
  """

  use ExUnit.Case, async: true

  alias Kati.Media.TmdbKeyFile

  doctest TmdbKeyFile

  @tmp Path.join(System.tmp_dir!(), "kati-tmdb-key-file-test")

  setup do
    File.mkdir_p!(@tmp)
    on_exit(fn -> File.rm_rf!(@tmp) end)
    %{dir: @tmp}
  end

  describe "the file the project documents" do
    test "is read from the home directory" do
      path = TmdbKeyFile.path()

      assert String.ends_with?(path, Path.join([".config", "kati", "tmdb.env"]))
      assert Path.type(path) == :absolute
    end
  end

  describe "reading one" do
    test "takes the read token out of the documented shape", %{dir: dir} do
      file =
        write!(dir, """
        # TMDB credentials for the kati project. NOT in the repo, never committed.
        # Read by test/dev runs via: set -a; . ~/.config/kati/tmdb.env; set +a
        export TMDB_READ_TOKEN=abc.def.ghi
        export TMDB_API_KEY=0123456789
        """)

      assert TmdbKeyFile.read(file) == "abc.def.ghi"
    end

    test "does not mistake the api key for the read token", %{dir: dir} do
      file = write!(dir, "export TMDB_API_KEY=0123456789\n")

      assert TmdbKeyFile.read(file) == nil
    end

    test "ignores a commented-out line", %{dir: dir} do
      file = write!(dir, "# export TMDB_READ_TOKEN=old\nexport TMDB_READ_TOKEN=new\n")

      assert TmdbKeyFile.read(file) == "new"
    end

    test "unquotes both quoting styles", %{dir: dir} do
      assert TmdbKeyFile.read(write!(dir, ~s(TMDB_READ_TOKEN="abc"\n))) == "abc"
      assert TmdbKeyFile.read(write!(dir, "TMDB_READ_TOKEN='abc'\n")) == "abc"
    end

    test "an empty value is no value", %{dir: dir} do
      assert TmdbKeyFile.read(write!(dir, "TMDB_READ_TOKEN=\n")) == nil
    end
  end

  describe "every way it is allowed to be absent" do
    test "no file at all" do
      assert TmdbKeyFile.read(Path.join(@tmp, "nothing-here.env")) == nil
    end

    test "a directory where the file should be", %{dir: dir} do
      path = Path.join(dir, "a-directory.env")
      File.mkdir_p!(path)

      assert TmdbKeyFile.read(path) == nil
    end

    test "a file with nothing in it", %{dir: dir} do
      assert TmdbKeyFile.read(write!(dir, "")) == nil
    end
  end

  describe "the test environment" do
    test "never carries a bundled key" do
      # The `Mix.env() == :test` guard on `@bundled_key`, asserted rather than
      # trusted: `Kati.MediaTmdbTest`'s *no key is not a failed request* block
      # deletes both environment variables and expects a refusal, and a token
      # baked into the test binary would answer past it. It would also mean a
      # test artefact carrying somebody's credentials.
      System.delete_env("TMDB_READ_TOKEN")
      System.delete_env("TMDB_TOKEN")

      assert Kati.Media.Tmdb.key() == {:error, :no_api_key}
    after
      System.put_env("TMDB_READ_TOKEN", "test-token")
    end
  end

  defp write!(dir, body) do
    path = Path.join(dir, "tmdb-#{System.unique_integer([:positive])}.env")
    File.write!(path, body)
    path
  end
end
