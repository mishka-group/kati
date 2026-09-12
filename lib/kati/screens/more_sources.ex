defmodule Kati.Screens.MoreSources do
  @moduledoc """
  The four sources that do not fit on 140's grid.

  Board **328**, and it exists because of what the chevron used to do: 140's
  *Four more sources* row pushed the manual column mapper with **no file and no
  source**, so the one row naming four services opened a mapping screen for
  none of them — *"a column table about nothing"*.

  ## Rows, not a second grid

  328 is explicit: *"the grid on 140 earns its shape by being the six
  commonest, and four overflow sources are a list."* Each row names its file
  exactly as 140's tiles do — the sub-line is the file, never the format, which
  is 140's own rule for all eleven — and each opens the picker with its source
  named, which is the whole point.

  The four names stay Latin in DM Mono. 278 transliterated them («سیمکل») and
  328 rules against it: they are trade names, and transliterating made the
  Persian row claim a fifth that was not there and misname the four that were.

  ## One gap, recorded rather than worked around

  The four names are drawn under the title by `Kati.UI.SettingsList.title/4`,
  whose subtitle asks `Kati.Locale.mono_face/0` — the READER's script — where
  this one line wants `mono_face/1`, the STRING's. So under `:fa` the four
  trade names come out in Vazirmatn: Latin, correctly ordered, and in the wrong
  face, where board 328's own Persian row draws them in DM Mono.

  The helper's default is right and this screen is the exception. A settings
  subtitle is translated prose on the other fifty-odd boards that call it, and
  only a subtitle that is a list of proper nouns wants to be asked by script —
  `title/4` has no face argument to say so. The fix is one option on that
  helper, not a second title recipe here, so it is written down rather than
  forked.
  """
  use Kati.Screens.Pushed, back: "Import"
  use Gettext, backend: Kati.Gettext

  alias Kati.Theme.Palette
  alias Kati.UI.SettingsList

  # The four `Kati.Import.Mapping` actually reads, in 140's own order. AniList
  # is NOT among them and is on the grid above instead — 140 drew it as a fifth
  # name in this row and the mapper has never read it.
  #
  # Still an attribute after mishka-group/kati#103, for the reason
  # `Kati.Screens.ImportSources`'s `@commonest` gives: the compile-time freeze
  # `gettext/1` suffers inside `@foo` cannot bite a table with no `gettext/1`
  # in it, and nothing in this one is copy — four trade names, four filenames
  # and four initials, none of which is translated.
  @sources [
    %{id: :simkl, letter: "S", name: "Simkl", file: "simkl-export.zip"},
    %{id: :tvtime, letter: "T", name: "TV Time", file: "tvtime-export.csv"},
    %{id: :libib, letter: "L", name: "Libib", file: "libib-export.csv"},
    %{id: :lastfm, letter: "F", name: "Last.fm", file: "lastfm-scrobbles.csv"}
  ]

  @doc """
  The four, as the row and the screen both name them.

      iex> Kati.Screens.MoreSources.sources() |> Enum.map(& &1.name)
      ["Simkl", "TV Time", "Libib", "Last.fm"]

  `Kati.Screens.ImportSources.more/0` draws its sub-line from this, so the count
  and the names cannot drift apart again — which is the defect 328 is about.
  """
  @spec sources() :: [map()]
  def sources, do: @sources

  @doc """
  `Simkl · TV Time · Libib · Last.fm` — the summary row's own sub-line.

      iex> Kati.Screens.MoreSources.names()
      "Simkl · TV Time · Libib · Last.fm"
  """
  @spec names() :: String.t()
  # NOT `Kati.Locale.ltr/1`, and the reason is the FACE rather than the order.
  #
  # Every character in this line is Latin or a neutral sitting BETWEEN two
  # Latin runs — the middle dots, and the stop inside `Last.fm` — so the bidi
  # algorithm already resolves the whole line left-to-right inside a
  # right-to-left page and strands no punctuation at the wrong edge. That is
  # the failure `ltr/1` exists for, and this line does not have it:
  # `Kati.Screens.ImportSources` wraps `goodreads_library_export.csv` because
  # there the filename is dropped INTO a Persian sentence, and leaves the same
  # filename bare when it is a line of its own.
  #
  # There is, however, something for an isolate to break here.
  # `Kati.Locale.mono_face/1` decides DM Mono by asking whether the string is
  # pure ASCII, and `U+2066` is not — so a line wrapped "just in case" would
  # answer `fa` and take the four trade names out of DM Mono, which is the one
  # thing board 328 says about them.
  def names, do: Enum.map_join(@sources, " · ", & &1.name)

  @doc """
  `Four more sources`, counted rather than typed.

      iex> Kati.Screens.MoreSources.heading()
      "Four more sources"
  """
  @spec heading() :: String.t()
  def heading, do: heading_for(length(@sources))

  # THE COUNT PICKS THE SENTENCE; IT IS NOT INTERPOLATED INTO ONE.
  #
  # This read `Kati.Screens.SearchSpec.word(length(@sources)) <> " more
  # sources"` until mishka-group/kati#103 reached it, which counts correctly
  # and cannot be translated at all: a msgid has to be a literal at the call
  # site, so neither `gettext(word(n) <> " more sources")` nor
  # `gettext(heading())` compiles, and `word/1` is documented — by
  # `Kati.Screens.SearchSpec.caps/0`, which says so while working around it —
  # as knowing nothing about Persian.
  #
  # `Kati.Locale.pick(SearchSpec.word(n), Kati.Locale.number(n))` is that
  # screen's answer to the same problem: spell the number in English, set the
  # digit in Persian. It is the wrong answer HERE, because board 328 draws the
  # Persian row as **چهار منبع دیگر** and not ۴ — both scripts spell this one
  # out, so both halves are copy and the whole sentence is one msgid.
  #
  # The count still comes from the list, which is 328's entire point ("a count
  # that matches its own names"): four selects the written-out sentence, and
  # any other length falls to the numeral form rather than to a word this
  # module would then have to spell in two languages. A fifth source can
  # therefore change the heading; it can never leave it claiming four.
  defp heading_for(4), do: gettext("Four more sources")

  defp heading_for(n),
    do: ngettext("%{n} more source", "%{n} more sources", n, n: Kati.Locale.number(n))

  @doc false
  def content(_assigns) do
    # `140` stays INSIDE the note's msgid rather than being interpolated
    # through `Kati.Locale.number/1`. It is a board number in a sentence about
    # a rule, not a figure read from anywhere, so a seam there would add no
    # source of truth — and the Persian entry writes it as ۱۴۰ the way every
    # other board number in the catalogue is written.
    # `Kati.Screens.SearchSpec.caps/0` makes the same call about its 12 and
    # its 256.
    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {SettingsList.chrome(nil, 44)}
        {SettingsList.title(Kati.Screens.MoreSources.heading(), Kati.Screens.MoreSources.names(), nil, :meta_tight)}
        {Kati.Screens.MoreSources.rows()}
        {SettingsList.note("info", gettext("The sub-line names the file, not the format — 140's rule, and it holds here too. Pick one and Kati opens the file picker with that source already named."))}
      </Column>
    </Scroll>
    """
  end

  @doc false
  def rows do
    last = length(@sources) - 1

    assigns = %{
      rows:
        @sources
        |> Enum.with_index()
        |> Enum.map(fn {source, i} ->
          SettingsList.row(
            Kati.Screens.MoreSources.letter(source.letter),
            SettingsList.body(source.name, source.file),
            SettingsList.trailing(SettingsList.chevron()),
            rule: i < last,
            on_tap: {self(), String.to_atom("open_" <> Atom.to_string(source.id))}
          )
        end)
    }

    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.card(@rows)}
      <Spacer size={18} />
    </Column>
    """
  end

  @doc "140's own tile letter, at row scale."
  @spec letter(String.t()) :: map()
  def letter(letter) do
    assigns = %{letter: letter}

    # `Kati.Locale.mono_face/1` rather than the literal `"mono"`: it asks the
    # LETTER and not the reader, so all four initials `@sources` holds today —
    # pure ASCII, and DM Mono has every glyph they need — keep DM Mono in both
    # scripts, which is exactly what board 328 draws on both sides of its
    # frame, and an overflow source added later whose initial is not ASCII
    # takes Vazirmatn rather than an empty box.
    # `Kati.Screens.ImportSources.source_letter_text/1` is the same call on the
    # same kind of table one board up, and carries the long form of the
    # argument.
    ~MOB"""
    <Box width={38} height={38} corner_radius={12} background={Palette.paper()} align="center">
      <Text
        text={@letter}
        font_family={Kati.Locale.mono_face(@letter)}
        text_size={14}
        text_color={Palette.ink()}
        max_lines={1}
      />
    </Box>
    """
  end

  @impl true
  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      # The whole point of the board: the picker opens with this source named,
      # where the old chevron opened the mapper with none.
      "open_" <> id ->
        {:noreply, Kati.Screens.ImportSources.choose_file(socket, id)}

      _other ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:files, :picked, _items} = message, socket),
    do: Kati.Screens.ImportSources.handle_info(message, socket)

  def handle_info({:files, _outcome, _rest} = message, socket),
    do: Kati.Screens.ImportSources.handle_info(message, socket)

  def handle_info(message, socket), do: super(message, socket)
end
