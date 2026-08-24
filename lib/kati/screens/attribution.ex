defmodule Kati.Screens.Attribution do
  @moduledoc """
  Screen 83 — Where this comes from, pushed under Settings.

  Every Tier-0 attribution obligation, discharged in Kati's own voice.

  ## Two sentences are quoted verbatim and must stay that way

  TMDB's — *This product uses the TMDB API but is not endorsed or certified by
  TMDB* — is required word for word by their terms. TVmaze's CC BY-SA link is
  not a courtesy either: **the link is the licence condition**, so removing it
  breaks the licence rather than being impolite. Both are in
  `Kati.Screens.Attribution.sources/0` as literals with that reason written
  beside them.

  ## The notices list pushes rather than expands

  Because it is long, generated, and nobody reads it inline. And it is
  generated: `THIRD_PARTY_NOTICES.md` is produced at build time and never typed
  by hand, which the page says out loud — a hand-maintained notices list is a
  notices list that is wrong.

  ## The non-commercial note lives here

  *Kati is free, has no ads and sells nothing inside itself. That is what keeps
  it inside TMDB's and Last.fm's non-commercial terms.* A constraint worth
  naming rather than hiding: it is the reason certain features cannot ship, and
  a user who knows that can tell the difference between a missing feature and a
  refused one.

  ## The marks are empty slots

  Real brand assets go in unmodified and are never recoloured — most of these
  licences say so explicitly. Until the files are in `priv/`, each source draws
  a paper square with its initial, exactly as `Kati.Music.Album.initial/1` does
  for a missing cover, rather than a broken image or a recoloured approximation.
  """

  use Kati.Screens.Pushed, back: "Settings"

  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  # Each source: what Kati takes from it, the sentence the licence requires, the
  # licence tag where one must be shown, and the site.
  #
  # The `notice` strings are legal text. Editing one for tone is a licence
  # change, so they are here as literals and `Kati.AttributionTest` pins the two
  # that are quoted verbatim.
  @sources [
    %{
      id: :tmdb,
      name: "TMDB",
      takes: "Film posters, backdrops and the facts behind them.",
      notice: "This product uses the TMDB API but is not endorsed or certified by TMDB.",
      licence: nil,
      site: "themoviedb.org"
    },
    %{
      id: :justwatch,
      name: "JustWatch",
      takes: "Which services a title is on, and when it’s leaving.",
      notice: "Streaming availability data provided by JustWatch.",
      licence: nil,
      site: "justwatch.com"
    },
    %{
      id: :tvmaze,
      name: "TVmaze",
      takes: "TV schedules and episode lists.",
      notice:
        "Schedule data from TVmaze, used under CC BY-SA 4.0 — this link is the licence condition.",
      licence: "CC BY-SA",
      site: "tvmaze.com"
    },
    %{
      id: :open_library,
      name: "Open Library",
      takes: "Book covers, editions and ISBNs.",
      notice: "Book records from Open Library, an Internet Archive project.",
      licence: nil,
      site: "openlibrary.org"
    },
    %{
      id: :musicbrainz,
      name: "MusicBrainz",
      takes: "Album and artist data, and cover art where it exists.",
      notice:
        "Music metadata from MusicBrainz and cover art from the Cover Art Archive, " <>
          "both community-maintained.",
      licence: "CC0 / CC BY-NC-SA",
      site: "musicbrainz.org"
    }
  ]

  # The open-source half. Three rows, each a licence and what it covers.
  @open_source [
    {"MIT", "Kati, and Mob"},
    {"Apache-2.0", "Mishka Chelekom components"},
    {"OFL", "Plus Jakarta Sans, DM Mono, Vazirmatn"}
  ]

  @doc "Every third-party source, with the notice its licence requires."
  @spec sources() :: [map()]
  def sources, do: @sources

  @doc "The licences Kati's own dependencies ship under."
  @spec open_source() :: [{String.t(), String.t()}]
  def open_source, do: @open_source

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
        {SettingsList.title("Where this comes from", "Posters, covers, air dates and facts", nil, :name)}
        {Kati.Screens.Attribution.source_cards()}
        {UI.eyebrow("Open source")}
        {Kati.Screens.Attribution.open_source_card()}
        {Kati.Screens.Attribution.footnotes()}
      </Column>
    </Scroll>
    """
  end

  @doc "One card per source, each carrying its own required sentence."
  @spec source_cards() :: map()
  def source_cards do
    cards =
      @sources
      |> Enum.map(&Kati.Screens.Attribution.source_card/1)
      |> Enum.intersperse(~MOB"<Spacer size={11} />")

    ~MOB"""
    <Column fill_width={true}>
      {cards}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def source_card(source) do
    assigns = %{
      name: source.name,
      takes: source.takes,
      notice: source.notice,
      licence: source.licence,
      site: source.site,
      tap: {self(), String.to_atom("open_#{source.id}")}
    }

    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={20}
      padding={17}
      shadow={Kati.Theme.shadow_card()}
      on_tap={@tap}
    >
      <Row fill_width={true} align="center">
        {Kati.Screens.Attribution.mark(@name)}
        <Spacer size={13} />
        <Column weight={1.0}>
          <Text
            text={@takes}
            text_size={13.5}
            font_weight="semibold"
            text_color={:on_surface}
            line_height={1.35}
          />
        </Column>
      </Row>
      <Spacer size={11} />
      <Text text={@notice} text_size={12} line_height={1.5} text_color={Palette.ink_soft()} />
      <Spacer size={11} />
      <Row fill_width={true} align="center">
        {Kati.Screens.Attribution.licence_tag(@licence)}
        <Text
          text={@site}
          font_family="mono"
          text_size={11}
          text_color={Palette.muted()}
          max_lines={1}
        />
        <Spacer weight={1.0} />
        {Kati.UI.SettingsList.chevron()}
      </Row>
    </Column>
    """
  end

  @doc """
  The brand mark's slot.

  A paper square with the source's initial until the real assets are in
  `priv/`. Never a recoloured approximation of somebody's logo — most of these
  licences forbid modification of the mark, and a tinted one would breach the
  licence this very screen exists to honour.
  """
  @spec mark(String.t()) :: map()
  def mark(name) do
    assigns = %{initial: name |> String.first() |> String.upcase()}

    ~MOB"""
    <Box width={40} height={40} corner_radius={10} background={Palette.paper()} align="center">
      <Text
        text={@initial}
        text_size={15}
        font_weight="bold"
        text_align="center"
        text_color={Palette.sub()}
      />
    </Box>
    """
  end

  @doc false
  def licence_tag(nil), do: ~MOB"<Spacer size={0} />"

  def licence_tag(label) do
    assigns = %{label: label}

    ~MOB"""
    <Row align="center">
      <Row
        height={22}
        corner_radius={11}
        background={Kati.Theme.Palette.accent_wash()}
        padding_left={9}
        padding_right={9}
        align="center"
      >
        <Text
          text={@label}
          font_family="mono"
          text_size={9.5}
          letter_spacing={0.08}
          text_color={Kati.Theme.Palette.gold_text()}
          max_lines={1}
        />
      </Row>
      <Spacer size={9} />
    </Row>
    """
  end

  @doc "Kati's own licences, and the row that opens the generated notice list."
  @spec open_source_card() :: map()
  def open_source_card do
    rows =
      Enum.map(@open_source, fn {licence, covers} ->
        SettingsList.row(
          Kati.Screens.Attribution.licence_pill(licence),
          SettingsList.body(covers, nil),
          SettingsList.trailing(nil)
        )
      end)

    rows =
      rows ++
        [
          SettingsList.row(
            nil,
            SettingsList.body("Full notice list", nil),
            SettingsList.trailing(SettingsList.chevron()),
            on_tap: {self(), :open_notices}
          )
        ]

    ~MOB"""
    <Column fill_width={true}>
      <Text
        text="Kati is MIT-licensed. It stands on work by people who gave it away."
        text_size={12.5}
        line_height={1.5}
        text_color={Palette.ink_soft()}
      />
      <Spacer size={12} />
      {Kati.UI.SettingsList.card(rows)}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def licence_pill(label) do
    assigns = %{label: label}

    ~MOB"""
    <Box width={40} height={40} corner_radius={12} background={Palette.paper()} align="center">
      <Text
        text={@label}
        font_family="mono"
        text_size={9}
        text_align="center"
        text_color={Palette.ink_soft()}
        max_lines={1}
      />
    </Box>
    """
  end

  @doc """
  The two things this page says about itself.

  The first is about how the notices list is produced — generated at build time,
  never typed. The second is the non-commercial constraint, which is here rather
  than buried because it explains what Kati will never do.
  """
  @spec footnotes() :: map()
  def footnotes do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.note("info", "That list is generated from THIRD_PARTY_NOTICES.md at build time, never typed by hand.")}
      <Spacer size={12} />
      {Kati.UI.SettingsList.note("info", "Kati is free, has no ads and sells nothing inside itself. That is what keeps it inside TMDB’s and Last.fm’s non-commercial terms — a constraint worth naming, not hiding.")}
    </Column>
    """
  end

  # Every card and the notices row open a URL, and Kati has no in-app browser.
  # Answering them rather than leaving them dead: the control is drawn, it is
  # reachable, and what it would open is the platform's browser through a fence
  # that does not exist yet. `Kati.ScreenTapSweepTest` carries them with that
  # reason.
  @doc false
  def handle_tap(_tag, socket), do: {:noreply, socket}
end
