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
  """
  use Kati.Screens.Pushed, back: "Import"

  alias Kati.Theme.Palette
  alias Kati.UI.SettingsList

  # The four `Kati.Import.Mapping` actually reads, in 140's own order. AniList
  # is NOT among them and is on the grid above instead — 140 drew it as a fifth
  # name in this row and the mapper has never read it.
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
  def names, do: Enum.map_join(@sources, " · ", & &1.name)

  @doc """
  `Four more sources`, counted rather than typed.

      iex> Kati.Screens.MoreSources.heading()
      "Four more sources"
  """
  @spec heading() :: String.t()
  def heading, do: Kati.Screens.SearchSpec.word(length(@sources)) <> " more sources"

  @doc false
  def content(_assigns) do
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
        {SettingsList.note("info", "The sub-line names the file, not the format — 140's rule, and it holds here too. Pick one and Kati opens the file picker with that source already named.")}
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

    ~MOB"""
    <Box width={38} height={38} corner_radius={12} background={Palette.paper()} align="center">
      <Text
        text={@letter}
        font_family="mono"
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
