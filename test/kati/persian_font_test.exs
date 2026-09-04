Code.require_file("../support/screen_sweep.exs", __DIR__)

defmodule Kati.PersianFontTest do
  @moduledoc """
  Every Persian sentence a screen draws is set in the Persian face.

  ## The failure is legible, which is exactly why nothing caught it

  `Kati.Screens.Fa`'s first type rule — *"every Persian string needs
  `font_family="fa"`"* — has been obeyed by hand since it was written, which is
  the arrangement that breaks the first time a screen is added quickly. Nothing
  failed when it did: the template compiles, `Kati.ScreenRenderSweepTest` gets
  its one root node, `Kati.ScreenDesignLiteralTest` finds the drawing's
  sentence because the *string* is right, and the tap sweep taps a control it
  can see.

  **And it does not look broken on the device either.** That claim was checked
  rather than assumed — screen 27 was opened on the Pixel_9a with three
  unmarked Persian strings on it and photographed. Compose falls through a
  `FontFamily` that lacks a glyph to the platform's own fallback chain, so
  Android substitutes its system Arabic face and the sentence renders,
  correctly shaped and joined. It is not tofu. It is Kati's Persian set in
  somebody else's typeface, one paragraph at a time, and the two faces sit
  side by side on the same screen where nobody reads them as a bug.

  That is the whole reason for a test rather than a code review: the defect
  has no symptom. `Kati.Screens.Fa`'s own moduledoc predicted blank boxes,
  which would at least have been loud; the truth is quieter and has therefore
  lasted longer.

  ## What the faces actually carry

  Re-derived here rather than trusted — `face_covers_persian?/1` parses the
  shipped `cmap` tables. `kati_sans_400.ttf`, the face an unstyled `Text` gets
  per `MobBridge.kt`'s own *"No prop means body text, and body text is Plus
  Jakarta Sans"*, carries **zero** code points in U+0600–U+06FF.
  `kati_fa_400.ttf` carries 142, and covers Latin and the em dash too — which
  is what makes `fa` the safe answer for a mixed sentence as well as a Persian
  one.

  `kati_mono.ttf` has none of U+06F0–U+06F9, which is why `Kati.Screens.Fa`
  sets Persian numerals in `fa` at the design's mono size. Four screens still
  did not, and their figures were being drawn in the system face beside Latin
  ones in DM Mono.

  ## The rule this enforces

  A string whose letters are **mostly Persian** must be set in `fa`. A string
  that is mostly Latin with a Persian word inside it cannot be: one `Text`
  gets one face, and setting Kati's English in Vazirmatn to fix one word is
  the worse trade. Those are named in `@mixed` with the reason, and the
  inventory has to match exactly — so a new mixed string fails until someone
  decides which way it goes, and a fixed one fails until it leaves the list.

  Every screen is checked in **both** locales, because a Persian literal is a
  fact about the module rather than about the setting: the mirrors hard-code
  `layout_direction="rtl"` and draw Persian whatever `Kati.Locale` says.

  The check reads the rendered tree rather than the source, so it also covers
  Persian handed to a component that builds its own `Text` — the case
  `Kati.Screens.Fa` calls the reason the mirrors adopt so little of
  `Kati.Components`, and the one a grep of the screen file misses entirely.
  """
  use Mob.ScreenCase, async: false

  alias Kati.ScreenSweep

  @fonts Path.expand("../../android/app/src/main/res/font", __DIR__)

  # U+0600–U+06FF is the Arabic block, where Persian letters and the Persian
  # digits both live.
  @persian ~r/[\x{0600}-\x{06FF}]/u

  # The props a person reads. `placeholder` counts as much as `text`: an empty
  # field is all placeholder, so screen 156's form is four of them.
  @readable [:text, :placeholder]

  # Mostly-Latin sentences carrying a Persian word, kept in the Latin face on
  # purpose. Each one names a language rather than speaking one.
  @mixed [
    {Kati.Screens.LanguagePick, "Picking فارسی flips the whole interface"},
    {Kati.Screens.LanguagePick, "RIGHT TO LEFT · ۱۲۳۴ · SHAMSI"},
    {Kati.Screens.Settings, "English · فارسی"},
    {Kati.Screens.SearchSpec, "Typing ي finds ی."}
  ]

  describe "the shipped faces" do
    test "the body face has no Persian glyphs, so an unmarked Text leaves the family" do
      refute face_covers?("kati_sans_400.ttf", 0x600..0x6FF),
             """
             kati_sans_400.ttf now carries Arabic-block glyphs.

             Re-read this file's moduledoc before deleting anything: a face that
             gained the glyphs is good news, but the rule it justified — Kati's
             Persian is set in Vazirmatn, not in whatever has glyphs — is a design
             decision that outlives the technical reason for it.
             """
    end

    test "the Persian face covers the block, so the prop has somewhere to point" do
      assert face_covers?("kati_fa_400.ttf", 0x600..0x6FF)
    end

    test "the Persian face covers Latin too, which is what makes it safe for a mixed line" do
      assert face_covers?("kati_fa_400.ttf", ?A..?z)
    end

    test "the mono face has no Persian digits, which is why Fa sets numerals in fa" do
      refute face_covers?("kati_mono.ttf", 0x6F0..0x6F9)
    end
  end

  describe "every screen" do
    for locale <- [:en, :fa] do
      test "sets its Persian sentences in the Persian face, in #{locale}" do
        offenders = ScreenSweep.with_locale(unquote(locale), &offenders/0)
        {mixed, persian} = Enum.split_with(offenders, &mostly_latin?/1)

        assert persian == [], """
        Persian text left in a Latin face. On the device Android substitutes its
        own Arabic face, so this renders — in a typeface that is not Kati's,
        beside sentences that are.

        Put `font_family="fa"` on the Text. If the string goes through a
        component, pass it as children with the prop on it rather than as a
        label prop — `Kati.Screens.Fa` names the four components with a content
        slot, and `Kati.Screens.Fa.note/2` is the dashed aside already done.

        #{report(persian)}
        """

        assert named(mixed) == Enum.sort(@mixed), """
        The inventory of mostly-Latin sentences carrying a Persian word no
        longer matches what the screens draw.

        A new one: decide which face it takes. One `Text` gets one face, so a
        sentence that is mostly English keeps the Latin one and joins @mixed
        with a reason; a sentence that is mostly Persian takes `fa`.

        One that has gone: take it out of @mixed.

        drawn: #{inspect(named(mixed), pretty: true)}
        """
      end
    end
  end

  defp offenders do
    for module <- ScreenSweep.screens(),
        {:ok, _socket, tree} <- [ScreenSweep.render(module)],
        node <- Mob.ScreenCase.flatten(tree),
        props = Map.get(node, :props) || %{},
        key <- @readable,
        value = props[key],
        is_binary(value),
        Regex.match?(@persian, value),
        props[:font_family] != "fa" do
      {module, key, value, props[:font_family]}
    end
  end

  # Matched on a prefix rather than the whole sentence: these are paragraphs,
  # and an inventory that has to be re-typed every time a comma moves stops
  # being read and starts being pasted over.
  defp named(offenders) do
    offenders
    |> Enum.map(fn {module, _key, value, _family} ->
      Enum.find_value(@mixed, {module, value}, fn
        {^module, prefix} -> if String.starts_with?(value, prefix), do: {module, prefix}
        _other -> nil
      end)
    end)
    |> Enum.uniq()
    |> Enum.sort()
  end

  # Counting letters, not characters: digits, spaces and punctuation belong to
  # neither script, and a line of Persian numerals separated by colons would
  # otherwise read as mostly-Latin and be waved through.
  defp mostly_latin?({_module, _key, value, _family}) do
    graphemes = String.graphemes(value)
    persian = Enum.count(graphemes, &Regex.match?(@persian, &1))
    latin = Enum.count(graphemes, &Regex.match?(~r/[A-Za-z]/, &1))

    latin > persian
  end

  defp report(offenders) do
    offenders
    |> Enum.group_by(&elem(&1, 0))
    |> Enum.sort()
    |> Enum.map_join("\n", fn {module, rows} ->
      lines =
        Enum.map_join(rows, "\n", fn {_m, key, value, family} ->
          "      #{key} (#{inspect(family)}): " <> String.slice(value, 0, 48)
        end)

      "  #{inspect(module)} — #{length(rows)}\n#{lines}"
    end)
  end

  defp face_covers?(file, range) do
    codepoints = codepoints(file)
    Enum.any?(range, &(&1 in codepoints))
  end

  # The `cmap` of a shipped face, as a MapSet of code points. Formats 4 and 12
  # are the two the Google Fonts pipeline emits and the only two these files
  # use; an unknown subtable contributes nothing rather than raising, because a
  # face this cannot parse must not read as a face with no glyphs.
  defp codepoints(file) do
    data = File.read!(Path.join(@fonts, file))
    <<_::binary-4, tables::16, _::binary>> = data

    {offset, _length} =
      Enum.find_value(0..(tables - 1), fn i ->
        at = 12 + 16 * i
        <<_::binary-size(at), tag::binary-4, _checksum::32, off::32, len::32, _::binary>> = data
        if tag == "cmap", do: {off, len}
      end)

    <<_::binary-size(offset + 2), subtables::16, _::binary>> = data

    Enum.reduce(0..(subtables - 1), MapSet.new(), fn i, acc ->
      at = offset + 4 + 8 * i
      <<_::binary-size(at + 4), sub_offset::32, _::binary>> = data
      MapSet.union(acc, subtable(data, offset + sub_offset))
    end)
  end

  defp subtable(data, at) do
    <<_::binary-size(at), format::16, _::binary>> = data
    subtable(data, at, format)
  end

  defp subtable(data, at, 4) do
    <<_::binary-size(at + 6), segments_x2::16, _::binary>> = data
    segments = div(segments_x2, 2)
    ends = shorts(data, at + 14, segments)
    starts = shorts(data, at + 16 + segments_x2, segments)

    [starts, ends]
    |> Enum.zip()
    |> Enum.reduce(MapSet.new(), fn {first, last}, acc ->
      # The final segment is the required 0xFFFF..0xFFFF terminator rather than
      # a range of real glyphs.
      if first == 0xFFFF, do: acc, else: MapSet.union(acc, MapSet.new(first..last))
    end)
  end

  defp subtable(data, at, 12) do
    <<_::binary-size(at + 12), groups::32, _::binary>> = data

    Enum.reduce(0..(groups - 1), MapSet.new(), fn i, acc ->
      group = at + 16 + 12 * i
      <<_::binary-size(group), first::32, last::32, _glyph::32, _::binary>> = data
      MapSet.union(acc, MapSet.new(first..last))
    end)
  end

  defp subtable(_data, _at, _other_format), do: MapSet.new()

  defp shorts(data, at, count) do
    for i <- 0..(count - 1) do
      <<_::binary-size(at + 2 * i), value::16, _::binary>> = data
      value
    end
  end
end
