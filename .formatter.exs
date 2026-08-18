[
  # Mob.Formatter formats the ~MOB sigil's markup.
  plugins: [Mob.Formatter],
  # import_deps pulls in each library's DSL metadata so `mix format` does not
  # add parentheses to declarative blocks, which defeats the point of the DSL.
  import_deps: [:ash, :ash_sqlite],
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"]
]
