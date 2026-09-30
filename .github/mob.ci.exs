# mob.exs for CI. The real one is gitignored because it holds machine paths;
# this is the same file with the paths CI has. Copied to ./mob.exs by the
# workflows.
import Config

config :mob_dev,
  mob_dir: Path.join(File.cwd!(), "deps/mob"),
  elixir_lib: Path.join(:code.lib_dir(:elixir), ".."),
  static_nifs: [
    %{module: :kati_secure_store, archs: [:android]},
    %{module: :kati_bridge, archs: [:android]}
  ]
