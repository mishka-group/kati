defmodule Kati.MixProject do
  use Mix.Project

  def project do
    [
      app: :kati,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: false,
      deps: deps(),
      aliases: aliases(),
      erlc_paths: ["src"],
      erlc_options: [:debug_info]
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      # Mob is pre-1.0 with a fast release cadence, no `mix mob.upgrade`, and a
      # native shell that is forked at generation time — so every bump has to be
      # a deliberate act with a bridge diff, not a silent `~>` drift.
      {:mob, "== 0.7.20"},
      {:mob_dev, "== 0.6.23", only: :dev, runtime: false},
      {:ecto_sqlite3, "~> 0.24"},
      # Mozilla's CA trust store. Android has no bundle at any path OTP knows,
      # so this is copied into priv/ and loaded at boot — see Kati.App.
      {:castore, "~> 1.0"},
      # Code quality — Credo + ex_slop (catches AI-generated patterns
      # like blanket rescue, narrator docs, redundant Enum chains, etc).
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:ex_slop, "~> 0.4", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases do
    [
      # Refresh priv/cacerts.pem from castore on every compile. Copying once by
      # hand would pin Kati to whatever Mozilla trusted on the day it was
      # copied, and the staleness would be invisible until a certificate
      # rotation broke TLS on users' phones.
      compile: ["kati.certs", "compile"],
      "kati.certs": &sync_cacerts/1
    ]
  end

  defp sync_cacerts(_args) do
    Mix.Task.run("loadpaths")
    source = CAStore.file_path()
    dest = Path.join(__DIR__, "priv/cacerts.pem")

    if not File.exists?(dest) or File.read!(source) != File.read!(dest) do
      File.mkdir_p!(Path.dirname(dest))
      File.cp!(source, dest)
      Mix.shell().info([:green, "* synced ", :reset, "priv/cacerts.pem from castore"])
    end
  end
end
