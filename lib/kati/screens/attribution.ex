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
  use Gettext, backend: Kati.Gettext

  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  # Each source: what Kati takes from it, the sentence the licence requires,
  # Kati's own gloss on it where there is one, the licence tag where one must be
  # shown, and the site.
  #
  # ## Why `notice` and `gloss` are two fields
  #
  # `notice` is legal text. Editing one for tone is a licence change, so they
  # are literals here and `Kati.ServicesTest` pins the two quoted verbatim —
  # and, for the same reason, `notice` is NOT translated: a quotation that has
  # been through a translator is no longer the quotation the licence asks for.
  #
  # `gloss` is Kati's own sentence about the notice, and it IS translated. Two
  # sources had one welded onto the end of their notice — *— this link is the
  # licence condition* and *, both community-maintained* — and board 85 is what
  # made that a defect rather than a tidiness question: it draws this page with
  # Kati's sentences in Persian and the quotations left alone, which a single
  # string cannot express. `Kati.Screens.AttributionFa` expressed it by
  # SHORTENING the two notices, so the mirror and the page it mirrors disagreed
  # about what the licence says. Splitting the field is what lets one page do
  # both, which is mishka-group/kati#103's whole shape.
  #
  # ## Why this is a function and not a module attribute
  #
  # `gettext/1` in an attribute is evaluated once at COMPILE time, so the
  # locale of whoever ran `mix compile` would be the locale every reader got.
  # `takes` and `gloss` are Kati's own sentences and are translated here;
  # `name`, `site` and `notice` are not, for the reasons above.
  @doc "Every third-party source, with the notice its licence requires."
  @spec sources() :: [map()]
  def sources do
    [
      %{
        id: :tmdb,
        name: "TMDB",
        takes: gettext("Film posters, backdrops and the facts behind them."),
        notice: "This product uses the TMDB API but is not endorsed or certified by TMDB.",
        licence: nil,
        site: "themoviedb.org"
      },
      %{
        id: :justwatch,
        name: "JustWatch",
        takes: gettext("Which services a title is on, and when it’s leaving."),
        notice: "Streaming availability data provided by JustWatch.",
        licence: nil,
        site: "justwatch.com"
      },
      %{
        id: :tvmaze,
        name: "TVmaze",
        takes: gettext("TV schedules and episode lists."),
        notice: "Schedule data from TVmaze, used under CC BY-SA 4.0.",
        gloss: gettext("This link is the licence condition."),
        licence: "CC BY-SA",
        site: "tvmaze.com"
      },
      %{
        id: :open_library,
        name: "Open Library",
        takes: gettext("Book covers, editions and ISBNs."),
        notice: "Book records from Open Library, an Internet Archive project.",
        licence: nil,
        site: "openlibrary.org"
      },
      %{
        id: :musicbrainz,
        name: "MusicBrainz",
        takes: gettext("Album and artist data, and cover art where it exists."),
        notice: "Music metadata from MusicBrainz and cover art from the Cover Art Archive.",
        gloss: gettext("Both are community-maintained."),
        licence: "CC0 / CC BY-NC-SA",
        site: "musicbrainz.org"
      }
    ]
  end

  @doc """
  The licences Kati's own dependencies ship under.

  A function for `sources/0`'s reason — `gettext/1` in a module attribute is
  compile-time — and the halves are split the same way: the licence TAG is an
  identifier and is the same word everywhere, and the covered-by line is Kati
  describing its own dependencies and is translated. The third is a list of
  typeface names and translates to itself, which is why it goes through
  `gettext/1` anyway: a msgid whose Persian entry is the same string is a
  decision recorded in the catalogue, and a literal is a decision nobody can
  see.
  """
  @spec open_source() :: [{String.t(), String.t()}]
  def open_source do
    [
      {"MIT", gettext("Kati, and Mob")},
      {"Apache-2.0", gettext("Mishka Chelekom components")},
      {"OFL", gettext("Plus Jakarta Sans, DM Mono, Vazirmatn")}
    ]
  end

  @doc false
  def content(assigns) do
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
        {SettingsList.title(gettext("Where this comes from"), gettext("Posters, covers, air dates and facts"), nil, :name)}
        {Kati.UI.notice(assigns[:link_error])}
        {Kati.Screens.Attribution.source_cards()}
        {UI.eyebrow(Kati.UI.eyebrow_label(gettext("Open source")))}
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
      Kati.Screens.Attribution.sources()
      |> Enum.map(&Kati.Screens.Attribution.source_card/1)
      |> Enum.intersperse(~MOB"<Spacer size={11} />")

    ~MOB"""
    <Column fill_width={true}>
      {cards}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  Kati's own sentence about a notice, or nothing.

  Its own `Text` rather than a clause welded onto `notice`, because the two are
  different kinds of writing: the notice is a quotation a licence requires and
  is not translated, and this is Kati talking and is. Set a shade lighter, so
  the eye can tell which is which without being told.
  """
  @spec gloss(String.t() | nil) :: map()
  def gloss(nil), do: ~MOB"<Spacer size={0} />"

  def gloss(sentence) do
    assigns = %{sentence: sentence}

    # `Kati.Locale.leading/1` and not the bare 1.5, because this is the half of
    # the card that IS translated: under `:fa` it is a Persian sentence set in
    # Vazirmatn, whose metrics are not Plus Jakarta's. The notice above it keeps
    # its Latin 1.5 for the mirror-image reason — see `source_card/1`.
    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={5} />
      <Text
        text={@sentence}
        text_size={12}
        line_height={Kati.Locale.leading(1.5)}
        text_color={Palette.muted()}
        font_family={Kati.Locale.face_prop()}
      />
    </Column>
    """
  end

  @doc false
  def source_card(source) do
    assigns = %{
      name: source.name,
      takes: source.takes,
      notice: Kati.Locale.ltr(source.notice),
      gloss: Map.get(source, :gloss),
      licence: source.licence,
      site: source.site,
      tap: {self(), String.to_atom("open_#{source.id}")}
    }

    # THE NOTICE PINS THREE PROPS, AND ALL THREE SAY THE SAME THING.
    #
    # It is a quotation a licence requires, so it is English on a Persian page —
    # board 85 draws it as *a left-aligned LTR block, since a legal sentence
    # quoted in English must read as English* — and without these it would
    # inherit all three of that page's Persian defaults:
    #
    #   * `Kati.Locale.ltr/1` on the string, so the bidi algorithm keeps the
    #     sentence's own full stop at the sentence's own edge rather than at the
    #     paragraph's.
    #   * `text_align="absolute_left"`, because `Start` under `rtl` is the RIGHT
    #     edge, and an English paragraph ragged down its left is the one thing
    #     board 85 says this block must not be. `absolute_left` and not `left`:
    #     `MobBridge.textAlignProp/1` knows `center`, `right`, `start`, `end`,
    #     `absolute_left`, `absolute_right` and `justify`, and drops anything
    #     else in silence (`K-12 absolute-text-align`).
    #   * `font_family="sans"`, because the root declares `fa` under `:fa`
    #     (`K-48 locale-face`) and every unmarked `Text` falls back to it — and
    #     this sentence is never Persian. `Kati.Screens.Language.language_body/1`
    #     pins the same prop for the same reason, on the other page that draws a
    #     script it is not written in.
    #
    # `line_height` deliberately does NOT take `Kati.Locale.leading/1`: that
    # constant is Vazirmatn's metrics, and this line is not set in Vazirmatn.
    # Board 85 holds the notice at 1.6 while opening every Persian paragraph
    # around it out to 1.8.
    #
    # The site keeps a hardcoded `mono` for the neighbouring reason. It is an
    # ASCII domain out of `sources/0` in both locales — never the reader's
    # script — so DM Mono has every glyph it needs and both drawings set it
    # there. `Kati.Locale.mono_face/1` would answer `"mono"` for every one of
    # the five and only hide that this slot cannot hold Persian.
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
            line_height={Kati.Locale.leading(1.35)}
          />
        </Column>
      </Row>
      <Spacer size={11} />
      <Text
        text={@notice}
        text_size={12}
        line_height={1.5}
        text_color={Palette.ink_soft()}
        font_family="sans"
        text_align="absolute_left"
      />
      {Kati.Screens.Attribution.gloss(@gloss)}
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
      Enum.map(Kati.Screens.Attribution.open_source(), fn {licence, covers} ->
        SettingsList.row(
          Kati.Screens.Attribution.licence_pill(licence),
          # The covered-by line is a run of Latin names — `Kati, Mob`, `Plus
          # Jakarta Sans, DM Mono, Vazirmatn` — sitting on a page that is RTL
          # under `:fa`, and board 85 draws each of the three `direction:ltr`.
          # The commas in the third sit between Latin words and resolve LTR on
          # their own today; the isolate is what keeps that true the day a name
          # with a neutral at either edge is added to `open_source/0`, which is
          # not a breakage anybody goes looking for in a licence list.
          #
          # `Kati.Locale.ltr/1` here rather than inside `open_source/0`, so the
          # list stays the pair of plain strings its `@spec` promises and the
          # bidi marks belong to the thing that draws them.
          SettingsList.body(Kati.Locale.ltr(covers), nil),
          SettingsList.trailing(nil)
        )
      end)

    rows =
      rows ++
        [
          SettingsList.row(
            nil,
            SettingsList.body(gettext("Full notice list"), nil),
            SettingsList.trailing(SettingsList.chevron()),
            on_tap: {self(), :open_notices}
          )
        ]

    ~MOB"""
    <Column fill_width={true}>
      <Text
        text={gettext("Kati is MIT-licensed. It stands on work by people who gave it away.")}
        text_size={12.5}
        line_height={Kati.Locale.leading(1.5)}
        text_color={Palette.ink_soft()}
        font_family={Kati.Locale.face_prop()}
      />
      <Spacer size={12} />
      {Kati.UI.SettingsList.card(rows)}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  The sentence board 85 adds and board 83 does not have.

  It is about the page itself — which of its words are translated and which are
  not — so it is only true where something has been translated. Under `:en` it
  would be a paragraph explaining that nothing was translated, which is why
  `Kati.Locale.pick/2` draws it in Persian and draws nothing in English rather
  than being folded into the two notes above it.

  `Kati.Screens.AttributionFa.@copy.mirror` is where it came from, and it was
  the one string in that mirror with no English original at all — which is also
  why it is a literal here rather than a `gettext/1` call. A msgid is an English
  sentence somebody translated; this sentence has never had an English side, so
  there is nothing for a catalogue entry to be keyed on.
  """
  @spec marks_note() :: map()
  def marks_note do
    assigns = %{
      sentence:
        Kati.Locale.pick(
          nil,
          "نشان‌های تجاری هرگز آینه نمی‌شوند و هرگز به رنگ‌های کاتی درنمی‌آیند. " <>
            "جمله‌های خود کاتی ترجمه می‌شوند؛ متن حقوقی نقل‌شده در زبان اصلی می‌ماند."
        )
    }

    if assigns.sentence do
      ~MOB"""
      <Column fill_width={true}>
        <Spacer size={12} />
        {Kati.UI.SettingsList.note("translate", @sentence)}
      </Column>
      """
    else
      ~MOB"<Spacer size={0} />"
    end
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
      {Kati.UI.SettingsList.note("info", gettext("That list is generated from THIRD_PARTY_NOTICES.md at build time, never typed by hand."))}
      <Spacer size={12} />
      {Kati.UI.SettingsList.note("info", gettext("Kati is free, has no ads and sells nothing inside itself. That is what keeps it inside TMDB’s and Last.fm’s non-commercial terms — a constraint worth naming, not hiding."))}
      {Kati.Screens.Attribution.marks_note()}
    </Column>
    """
  end

  @doc """
  Every card and the notices row open the site they name.

  Six controls on this board were drawn, reachable and dead until `K-43 open-url` gave
  Kati a way to open a link. `Kati.ScreenTapSweepTest` carried each with the
  same sentence — *every one opens a URL in the platform browser, and Kati has
  no fence that does* — and that was true for as long as
  `native/LEDGER.md` had no `K-43`.

  The URL is built from the `:site` the card already prints, so the address in
  the browser is the address the reader was shown; a second column holding a
  full URL would be a second thing to keep in step with the first.

  A refusal is drawn rather than swallowed. `Kati.Native.Links.message/1` has a
  sentence for each — no browser on the phone, no bridge at all on a host —
  and screen 06's silent search is the reason this page does not repeat it:
  a control that appears to act and then says nothing is worse than one that
  never moved.
  """
  def handle_tap(tag, socket) when is_atom(tag) do
    case Kati.Screens.Attribution.site_for(tag) do
      nil -> {:noreply, socket}
      url -> {:noreply, Kati.Screens.Attribution.follow(socket, url)}
    end
  end

  def handle_tap(_tag, socket), do: {:noreply, socket}

  @doc """
  The URL one of this page's tap tags names, or `nil`.

  `:open_notices` is the licences of Kati's own dependencies rather than a
  source, and it goes to the same place `open_source/0`'s rows are about.
  """
  @spec site_for(atom()) :: String.t() | nil
  def site_for(:open_notices), do: "https://github.com/mishka-group/kati"

  def site_for(tag) do
    Enum.find_value(Kati.Screens.Attribution.sources(), fn source ->
      if String.to_atom("open_#{source.id}") == tag, do: "https://" <> source.site
    end)
  end

  @doc false
  @spec follow(Mob.Socket.t(), String.t()) :: Mob.Socket.t()
  def follow(socket, url) do
    case Kati.Native.Links.open(url) do
      :ok ->
        Mob.Socket.assign(socket, :link_error, nil)

      {:error, reason} ->
        Mob.Socket.assign(socket, :link_error, Kati.Native.Links.message(reason))
    end
  end
end
