defmodule Kati.Theme.PaletteTest do
  @moduledoc """
  Holds `Kati.Theme.Palette` to the one rule the refactor is under: **light
  mode must not change by a single pixel.**

  The 62 frames in `.scratch/design/audit_v7/` are the baseline. So the light
  column is written out here by hand, all 87 of it, as a second and
  independent copy — if the table in the module moves, this fails, and the
  failure names the token. A test that read the values back out of the module
  it is testing would pass no matter what the module said.

  The other half is coverage. `.../screens/*.ex` writes 93 distinct
  `0xAARRGGBB` literals into its markup, and the table is only useful if it can
  produce all 93. That is asserted against the files on disk rather than
  against a number typed here, so a screen that grows a 94th literal fails
  this test rather than quietly falling outside the palette.

  And the count, because this repo has been bitten before: a derivation that
  returns nothing looks exactly like a codebase with nothing in it. Asserting
  `count/0` is what stops an empty table passing.
  """
  use ExUnit.Case, async: false

  alias Kati.Theme.Palette

  # ── The light column, written out by hand ────────────────────────────────
  #
  # Every entry is the literal that appears in the screens today. `light/1` MUST
  # return exactly this. No rounding, no tidying — `0xFFAFA89E` and `0xFFB3ACA2`
  # are four units apart and both are in the drawing.
  @expected %{
    # surfaces
    paper: {0xFFEFECE7, 0xFF121110},
    card: {0xFFFBFAF8, 0xFF1E1D1B},
    card_settled: {0xFFF4F1EC, 0xFF161514},
    cream: {0xFFFBF1DE, 0xFF2A2622},
    placeholder: {0xFFE4E0D9, 0xFF2A2826},
    poster_on_cream: {0xFFEADFC6, 0xFF3A342D},
    track: {0xFFE7E3DC, 0xFF312F2C},
    track_off: {0xFFDCD7CF, 0xFF3A3732},
    bar_neutral: {0xFFD8D2C8, 0xFF3D3935},
    star_empty: {0xFFE0DAD1, 0xFF2A2826},
    # ink and neutral marks
    ink: {0xFF1A1917, 0xFFF5F2EE},
    ink_soft: {0xFF5C574F, 0xFFCBC7C1},
    meta: {0xFF6E6860, 0xFFB6B1AB},
    bar_ink: {0xFF7C766D, 0xFFA29C94},
    sub: {0xFF8A8479, 0xFF8A837B},
    settled_ink: {0xFF9C958B, 0xFF79736D},
    eyebrow: {0xFFA0998F, 0xFF746F69},
    muted: {0xFFA9A29A, 0xFF6A6560},
    segment_idle: {0xFFAFA89E, 0xFF6A6560},
    tertiary: {0xFFB3ACA2, 0xFF6A6560},
    rail_idle: {0xFFC4BDB3, 0xFF4A453F},
    # on an ink-filled control
    on_ink: {0xFFFBFAF8, 0xFF1A1917},
    on_ink_glyph: {0xFFF5F2EE, 0xFF1A1917},
    on_ink_muted: {0xFFBFB8AC, 0xFF4A4238},
    on_ink_meta: {0xFF8A837B, 0xFF6E6860},
    on_ink_count: {0x99FBFAF8, 0x991A1917},
    on_ink_count_soft: {0xA6FBFAF8, 0xA61A1917},
    on_ink_veil: {0x1FF5F2EE, 0x1F1A1917},
    on_ink_track: {0x26F5F2EE, 0x261A1917},
    count_idle: {0x995C574F, 0x99CBC7C1},
    count_idle_soft: {0xA65C574F, 0xA6CBC7C1},
    count_idle_faint: {0x8C5C574F, 0x8CCBC7C1},
    ink_fill: {0xFF1A1917, 0xFFF7EFE4},
    # cream
    cream_ink: {0xFF1A1917, 0xFFF7EFE4},
    cream_body: {0xFF4A4238, 0xFFE4DBCE},
    cream_sub: {0xFF8A7B60, 0xFFA89B87},
    cream_meta: {0xFFB09A72, 0xFF7A6F5E},
    cream_rule: {0x4DB09A72, 0x4D7A6F5E},
    cream_raise: {0x99FFFFFF, 0xFF3A342D},
    cream_hairline: {0x00FFFFFF, 0x24E8823C},
    gold_icon: {0xFFC98A3E, 0xFFC98A3E},
    gold_label: {0xFFC08A4C, 0xFFC08A4C},
    gold_text: {0xFF96723C, 0xFFC98A3E},
    bar_gold: {0xFFE4D2B0, 0xFFE4D2B0},
    # state hues
    accent: {0xFFE8823C, 0xFFE8823C},
    accent_wash: {0x2EE8823C, 0x2EE8823C},
    accent_fill: {0x47E8823C, 0x47E8823C},
    green: {0xFF4E9A73, 0xFF4E9A73},
    green_wash: {0x294E9A73, 0x294E9A73},
    green_text: {0xFF3E8460, 0xFF4E9A73},
    red: {0xFFB4553C, 0xFFB4553C},
    red_wash: {0x1AB4553C, 0x1AB4553C},
    red_wash_strong: {0x24B4553C, 0x24B4553C},
    red_ring: {0x4DB4553C, 0x4DB4553C},
    bronze: {0xFFB08E55, 0xFFB08E55},
    # ink tints
    hairline: {0x121A1917, 0x12F5F2EE},
    hairline_soft: {0x141A1917, 0x14F5F2EE},
    hairline_strong: {0x1A1A1917, 0x1AF5F2EE},
    border_soft: {0x241A1917, 0x24F5F2EE},
    border: {0x291A1917, 0x29F5F2EE},
    border_strong: {0x2E1A1917, 0x2EF5F2EE},
    border_stronger: {0x331A1917, 0x33F5F2EE},
    track_ink: {0x381A1917, 0x38F5F2EE},
    divider_heavy: {0x591A1917, 0x59F5F2EE},
    ink_invisible: {0x001A1917, 0x00F5F2EE},
    card_hairline: {0x00FFFFFF, 0x0FF5F2EE},
    # chrome
    dock_fill: {0xE6FBFAF8, 0xEB1E1D1B},
    chrome_disc: {0xD1FBFAF8, 0xD11E1D1B},
    tab_well: {0xFFEFECE7, 0xFF0E0D0C},
    fab_fill: {0xFF1A1917, 0xFFF5F2EE},
    fab_glyph: {0xFFFBFAF8, 0xFF16150F},
    transparent: {0x00FFFFFF, 0x00FFFFFF},
    # over a photograph
    on_media: {0xFFFBFAF8, 0xFFFBFAF8},
    on_media_meta: {0xBFFBFAF8, 0xBFFBFAF8},
    on_media_track: {0x40FBFAF8, 0x40FBFAF8},
    on_media_ghost: {0x66F4F1EC, 0x66F4F1EC},
    lock_ink: {0xFFFFFFFF, 0xFFFFFFFF},
    lock_ink_85: {0xD9FFFFFF, 0xD9FFFFFF},
    lock_ink_65: {0xA6FFFFFF, 0xA6FFFFFF},
    lock_ink_60: {0x99FFFFFF, 0x99FFFFFF},
    lock_ink_55: {0x8CFFFFFF, 0x8CFFFFFF},
    lock_ink_50: {0x80FFFFFF, 0x80FFFFFF},
    lock_ink_40: {0x66FFFFFF, 0x66FFFFFF},
    lock_ink_15: {0x26FFFFFF, 0x26FFFFFF},
    lock_hairline: {0x24FFFFFF, 0x24FFFFFF},
    lock_glass: {0x801C1A18, 0x801C1A18},
    lock_ground: {0xFF1C1A18, 0xFF1C1A18}
  }

  @count 87

  # Screen 28 (Home, dark) is the same page as screen 01, so these pairs are
  # read straight off the two drawings rather than derived. If a derivation
  # rule is ever changed, these must not move — they are not derived.
  @drawn_pairs %{
    paper: {0xFFEFECE7, 0xFF121110},
    card: {0xFFFBFAF8, 0xFF1E1D1B},
    cream: {0xFFFBF1DE, 0xFF2A2622},
    ink: {0xFF1A1917, 0xFFF5F2EE},
    sub: {0xFF8A8479, 0xFF8A837B},
    muted: {0xFFA9A29A, 0xFF6A6560},
    rail_idle: {0xFFC4BDB3, 0xFF4A453F},
    placeholder: {0xFFE4E0D9, 0xFF2A2826},
    track: {0xFFE7E3DC, 0xFF312F2C},
    hairline: {0x121A1917, 0x12F5F2EE},
    cream_sub: {0xFF8A7B60, 0xFFA89B87},
    cream_meta: {0xFFB09A72, 0xFF7A6F5E},
    poster_on_cream: {0xFFEADFC6, 0xFF3A342D},
    on_ink: {0xFFFBFAF8, 0xFF1A1917},
    ink_fill: {0xFF1A1917, 0xFFF7EFE4},
    tab_well: {0xFFEFECE7, 0xFF0E0D0C},
    fab_fill: {0xFF1A1917, 0xFFF5F2EE},
    fab_glyph: {0xFFFBFAF8, 0xFF16150F},
    dock_fill: {0xE6FBFAF8, 0xEB1E1D1B}
  }

  @sources %{
    drawn: 24,
    theme: 3,
    hue: 11,
    media: 15,
    alpha: 18,
    ramp: 10,
    recession: 1,
    inversion: 3,
    step: 2
  }

  # Meant. Each is a light literal the screens use for more than one thing;
  # the moduledoc says which, and dark is where they part company.
  @light_collisions %{
    0xFFFBFAF8 => [:card, :fab_glyph, :on_ink, :on_media],
    0xFF1A1917 => [:cream_ink, :fab_fill, :ink, :ink_fill],
    0xFFEFECE7 => [:paper, :tab_well],
    0x00FFFFFF => [:card_hairline, :cream_hairline, :transparent],
    0x99FFFFFF => [:cream_raise, :lock_ink_60]
  }

  # Meant. The dark drawing has fewer neutral steps than the light one, so
  # light steps land together; and `:step` tokens are defined as taking the
  # unshaded hue, so they land on it.
  @dark_collisions %{
    0xFF6A6560 => [:muted, :segment_idle, :tertiary],
    0xFF2A2826 => [:placeholder, :star_empty],
    0xFF3A342D => [:cream_raise, :poster_on_cream],
    0xFF1A1917 => [:on_ink, :on_ink_glyph],
    0xFFF5F2EE => [:fab_fill, :ink],
    0xFFF7EFE4 => [:cream_ink, :ink_fill],
    0xFF4E9A73 => [:green, :green_text],
    0xFFC98A3E => [:gold_icon, :gold_text]
  }

  @twins [[:cream_ink, :ink_fill], [:fab_fill, :ink]]

  @screens Path.wildcard("lib/kati/screens/*.ex")

  # ── The count ────────────────────────────────────────────────────────────

  test "the table has #{@count} tokens" do
    assert Palette.count() == @count
    assert length(Palette.tokens()) == @count
    assert length(Palette.names()) == @count
    assert Enum.uniq(Palette.names()) == Palette.names()
  end

  test "the names are exactly the ones written out in this file" do
    assert Enum.sort(Palette.names()) == Enum.sort(Map.keys(@expected))
  end

  # ── The light column, one assertion per token ────────────────────────────

  for {name, {light, _dark}} <- @expected do
    hex = "0x" <> String.pad_leading(Integer.to_string(light, 16), 8, "0")

    test "#{name}/0 is #{hex} in light — the literal it replaces" do
      assert Palette.light(unquote(name)) == unquote(light)
      assert Palette.token(unquote(name), :light) == unquote(light)
      assert apply(Palette, unquote(name), [:light]) == unquote(light)
    end
  end

  test "every token has a dark value, and it is a 32-bit ARGB integer" do
    for %{name: name, dark: dark} <- Palette.tokens() do
      assert is_integer(dark), "#{name} has no dark value"
      assert dark >= 0x00000000 and dark <= 0xFFFFFFFF, "#{name}'s dark value is not ARGB"
      assert Palette.dark(name) == dark
      assert apply(Palette, name, [:dark]) == dark
    end
  end

  test "every dark value matches the one written out in this file" do
    for {name, {_light, dark}} <- @expected do
      assert Palette.dark(name) == dark, "#{name}: dark value moved"
    end
  end

  # ── Coverage: the 93 literals the screens actually write ─────────────────

  test "every 0xAARRGGBB literal in screen markup is reachable through a token" do
    literals = screen_literals()

    # The number is asserted so an empty or half-read scan cannot pass this
    # test by finding nothing to check.
    assert MapSet.size(literals) == 93

    covered = Palette.literals()
    missing = literals |> Enum.reject(&MapSet.member?(covered, &1)) |> Enum.sort()

    assert missing == [], "not named by any token: #{Enum.map_join(missing, ", ", &hex/1)}"
  end

  test "the two literals that appear only in comments are deliberately not tokens" do
    # `0x14000000` is `Kati.Theme`'s own border token, quoted in four screen
    # comments to explain why the drawing's `0x121A1917` is used instead of it;
    # `0x00000000` is `:transparent` quoted in two. Neither reaches markup, so
    # neither is a colour this module owes a dark value.
    literals = screen_literals()
    refute MapSet.member?(literals, 0x14000000)
    refute MapSet.member?(literals, 0x00000000)
  end

  # ── Collisions ───────────────────────────────────────────────────────────

  test "no two tokens share a light value except the declared ones" do
    assert Palette.collisions().light == @light_collisions
  end

  test "no two tokens share a dark value except the declared ones" do
    assert Palette.collisions().dark == @dark_collisions
  end

  test "no two tokens are identical in both modes except the declared twins" do
    assert Palette.twins() == @twins
  end

  # ── Provenance ───────────────────────────────────────────────────────────

  test "every token declares where its dark value came from, and the tally holds" do
    for %{name: name, source: source} <- Palette.tokens() do
      assert source in Palette.sources(), "#{name} claims an unknown source #{inspect(source)}"
    end

    assert Enum.frequencies_by(Palette.tokens(), & &1.source) == @sources
    assert Enum.sum(Map.values(@sources)) == @count
  end

  test "the pairs read off screens 01 and 28 are not derived and have not moved" do
    for {name, {light, dark}} <- @drawn_pairs do
      token = Enum.find(Palette.tokens(), &(&1.name == name))
      assert token.source == :drawn, "#{name} is drawn on screen 28, not derived"
      assert {token.light, token.dark} == {light, dark}
    end
  end

  test "every token carries a meaning, and no two tokens share one" do
    meanings = Enum.map(Palette.tokens(), & &1.meaning)

    for %{name: name, meaning: meaning} <- Palette.tokens() do
      assert is_binary(meaning) and byte_size(meaning) > 20, "#{name} has no real meaning written"
    end

    assert length(Enum.uniq(meanings)) == @count
  end

  # ── The derivation rules, checked against their own definitions ──────────

  test "an :alpha token keeps its alpha byte exactly" do
    alphas = Enum.filter(Palette.tokens(), &(&1.source == :alpha))
    assert length(alphas) == @sources.alpha

    for %{name: name, light: light, dark: dark} <- alphas do
      assert alpha(light) == alpha(dark),
             "#{name}: alpha moved from #{hex(light)} to #{hex(dark)}"
    end
  end

  test "the ink tints swap ink for ink-on-dark and nothing else" do
    ink = Palette.light(:ink)
    ink_on_dark = Palette.dark(:ink)

    tints =
      Palette.tokens()
      |> Enum.filter(&(&1.source == :alpha and rgb(&1.light) == rgb(ink)))

    # hairline is :drawn, so it is not in this list; the nine that are, are the
    # ones the rule was applied to.
    assert length(tints) == 9

    for %{name: name, light: light, dark: dark} <- tints do
      assert dark == alpha(light) * 0x1000000 + rgb(ink_on_dark),
             "#{name}: #{hex(dark)} is not #{hex(light)}'s alpha over ink-on-dark"
    end
  end

  test "the token the design draws the alpha rule with is the rule's own example" do
    # rgba(26,25,23,.07) on screen 01, rgba(245,242,238,.07) on screen 28.
    assert Palette.light(:hairline) == 0x121A1917
    assert Palette.dark(:hairline) == 0x12F5F2EE
    assert alpha(Palette.light(:hairline)) == alpha(Palette.dark(:hairline))
    assert rgb(Palette.light(:hairline)) == rgb(Palette.light(:ink))
    assert rgb(Palette.dark(:hairline)) == rgb(Palette.dark(:ink))
  end

  test "a :step token takes the undarkened hue it was a shade of" do
    assert Palette.dark(:green_text) == Palette.light(:green)
    assert Palette.dark(:gold_text) == Palette.light(:gold_icon)
  end

  test ":hue and :media tokens are identical in both modes, and nothing else is by accident" do
    for %{name: name, light: light, dark: dark, source: source} <- Palette.tokens(),
        source in [:hue, :media] do
      assert light == dark, "#{name} claims to be mode-independent but is not"
    end

    # Three tokens outside those two sources are also identical in both modes,
    # and each has a reason on the record: screen 28 keeps `#E8823C` at full
    # strength on near-black, and `Kati.Theme.dark/0` keeps `error: @red` and
    # exposes `bronze/0` with no mode at all. Nothing else may be.
    unchanged =
      Palette.tokens()
      |> Enum.filter(&(&1.light == &1.dark and &1.source not in [:hue, :media]))
      |> Enum.map(& &1.name)
      |> Enum.sort()

    assert unchanged == [:accent, :bronze, :red]
  end

  test "both hairlines are fully transparent in light, so light draws no border" do
    # Alpha 0 is not the same as absent — Compose draws a border inward, so a
    # screen must omit `border_width` in light rather than pass an invisible
    # colour. What this asserts is the half the palette can guarantee: nothing
    # is painted.
    assert alpha(Palette.light(:card_hairline)) == 0
    assert alpha(Palette.light(:cream_hairline)) == 0
    assert alpha(Palette.light(:transparent)) == 0
    assert alpha(Palette.dark(:transparent)) == 0
    assert alpha(Palette.light(:ink_invisible)) == 0
    assert alpha(Palette.dark(:ink_invisible)) == 0

    # …and that dark actually draws them.
    assert alpha(Palette.dark(:card_hairline)) > 0
    assert alpha(Palette.dark(:cream_hairline)) > 0
  end

  test "card_hairline is Kati.Theme's own dark border, not a second opinion" do
    assert Palette.dark(:card_hairline) == Kati.Theme.dark().border
  end

  test "the light column agrees with Kati.Theme wherever both name the same colour" do
    assert Palette.light(:paper) == Kati.Theme.paper(:light)
    assert Palette.light(:card) == Kati.Theme.card(:light)
    assert Palette.light(:cream) == Kati.Theme.cream(:light)
    assert Palette.light(:ink) == Kati.Theme.ink()
    assert Palette.light(:ink_soft) == Kati.Theme.ink_soft()
    assert Palette.light(:accent) == Kati.Theme.accent()
    assert Palette.light(:green) == Kati.Theme.green()
    assert Palette.light(:bronze) == Kati.Theme.bronze()
    assert Palette.light(:red) == Kati.Theme.red()
  end

  test "the dark column agrees with Kati.Theme's dark palette where both name the same colour" do
    assert Palette.dark(:paper) == Kati.Theme.paper(:dark)
    assert Palette.dark(:card) == Kati.Theme.card(:dark)
    assert Palette.dark(:cream) == Kati.Theme.cream(:dark)
    assert Palette.dark(:accent) == Kati.Theme.accent()
    assert Palette.dark(:red) == Kati.Theme.red()
    assert Palette.dark(:bronze) == Kati.Theme.bronze()
  end

  # ── Mode ─────────────────────────────────────────────────────────────────

  describe "mode" do
    setup do
      theme = Application.get_env(:mob, :theme)
      on_exit(fn -> put_env(:mob, :theme, theme) end)
      :ok
    end

    test "under the light theme, every zero-arity token returns its light literal" do
      Mob.Theme.set(Kati.Theme.light())

      assert Palette.mode() == :light

      for {name, {light, _dark}} <- @expected do
        assert apply(Palette, name, []) == light, "#{name} is not its light literal"
        assert Palette.token(name) == light
      end
    end

    test "under the dark theme, every zero-arity token returns its dark value" do
      Mob.Theme.set(Kati.Theme.dark())

      assert Palette.mode() == :dark

      for {name, {_light, dark}} <- @expected do
        assert apply(Palette, name, []) == dark, "#{name} did not follow the mode"
        assert Palette.token(name) == dark
      end
    end

    test "one call flips it, and flips it back" do
      Mob.Theme.set(Kati.Theme.light())
      assert Palette.mode() == :light
      assert Palette.card() == 0xFFFBFAF8

      Mob.Theme.set(Kati.Theme.dark())
      assert Palette.mode() == :dark
      assert Palette.card() == 0xFF1E1D1B

      Mob.Theme.set(Kati.Theme.light())
      assert Palette.mode() == :light
      assert Palette.card() == 0xFFFBFAF8
    end

    test "an unrecognised theme reads as light, never as dark" do
      # Mob's own neutral base is a dark grey, and nothing about it is Kati's
      # dark mode. Reading :dark off it would change every screen that had not
      # set a theme yet — which is the direction that costs pixels.
      Application.delete_env(:mob, :theme)

      assert Mob.Theme.current().background == :gray_900
      assert Palette.mode() == :light
      assert Palette.card() == 0xFFFBFAF8
    end

    test "the palette holds no mode of its own to go out of step with Mob.Theme" do
      # `function_exported?/3` answers false for an UNLOADED module, which
      # would make this refute pass without checking anything.
      {:module, Palette} = Code.ensure_loaded(Palette)
      assert function_exported?(Palette, :mode, 0)
      refute function_exported?(Palette, :put_mode, 1)

      assert Palette.mode() in [:light, :dark]
    end

    test "Kati.Theme.dark/0 still carries the page colour mode/0 recognises" do
      assert Palette.theme_agrees?()

      # And the recognition is not merely nominal: setting that exact theme is
      # what has to produce :dark.
      Mob.Theme.set(Kati.Theme.dark())
      assert Palette.mode() == :dark
    end
  end

  # ── Helpers ──────────────────────────────────────────────────────────────

  defp put_env(app, key, nil), do: Application.delete_env(app, key)
  defp put_env(app, key, value), do: Application.put_env(app, key, value)

  defp alpha(argb), do: Bitwise.bsr(argb, 24) |> Bitwise.band(0xFF)
  defp rgb(argb), do: Bitwise.band(argb, 0xFFFFFF)
  defp hex(v), do: "0x" <> String.pad_leading(Integer.to_string(v, 16), 8, "0")

  # Every `0xAARRGGBB` that reaches markup: whole-line `#` comments and
  # `@doc`/`@moduledoc` heredocs are skipped, because a literal quoted in prose
  # is not a colour anything paints.
  defp screen_literals do
    @screens
    |> Enum.flat_map(&literals_in/1)
    |> MapSet.new()
  end

  defp literals_in(path) do
    path
    |> File.read!()
    |> String.split("\n")
    |> Enum.reduce({false, []}, fn line, {in_doc?, acc} ->
      trimmed = String.trim(line)

      cond do
        in_doc? -> {trimmed != ~s(""") and not String.ends_with?(trimmed, ~s(""")), acc}
        Regex.match?(~r/^@(module)?doc\s+~?S?"""/, trimmed) -> {true, acc}
        String.starts_with?(trimmed, "#") -> {false, acc}
        true -> {false, scan(line) ++ acc}
      end
    end)
    |> elem(1)
  end

  defp scan(line) do
    ~r/0x[0-9A-Fa-f]{8}/
    |> Regex.scan(line)
    |> Enum.map(fn [match] -> String.to_integer(String.slice(match, 2..-1//1), 16) end)
  end
end
