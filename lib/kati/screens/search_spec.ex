defmodule Kati.Screens.SearchSpec do
  @moduledoc """
  Screen 88 — Scope & ranking, pushed under Settings.

  ## This board is a contract, and the screen renders it rather than restating it

  The design's own caption: *the annotation deliverable, drawn as its own board
  rather than margin notes — it is a contract the build reads, not a caption.*

  So every value on this page comes out of `Kati.Search`, which is the build's
  half of the same contract. The fields each scope searches, the four ranking
  tiers with their examples, the group order, the three-rows-per-group cap and
  the whole Persian normalisation table are read, not typed. A specification
  screen that held its own copy of the specification would be a second
  specification.

  ## The one field excluded by name

  Calendar searches event titles, locations and notes and **never invitee
  names**, and the board says why in one line: searching your calendar should
  not turn into searching your contacts. It is drawn in the excluded style
  rather than omitted, because a field that is missing and a field that is
  refused look identical in a list.

  ## Group order is fixed and the page says so

  *Always this order. A user learns where to look; relevance-sorted groups move
  the target every keystroke.* That sentence is the reason the group list on
  this page is a fixed rail rather than a sortable one.

  ## Three rows per group, and the second reason for it

  The board gives both: it keeps a result list readable, **and** it is what
  keeps a frame under 256 event handles — which is `Kati.TapHandleBudgetTest`'s
  ceiling and a real one, because a screen that exceeds it kills its own
  process.

  ## Half this page's words are not this page's to translate

  mishka-group/kati#103 folded board 88's Persian mirror away, so this module
  draws both scripts and its own copy goes through `Kati.Gettext`. Its own copy
  is the chrome: the title, the five eyebrows, the three notes, the caps card
  and the `NOT YET` pill.

  Everything the page is a specification OF belongs to `Kati.Search`, which is
  the other half of the contract, and reaches here already answered or not at
  all:

    * **The scope names and their fields** are `Kati.Search.scopes/0` and are
      already `pgettext("search scope", …)` — a function rather than an
      attribute, and its own comment says why: `gettext/1` inside a `@foo`
      freezes into whichever locale the compiler was in.
    * **The four tier names and their examples** are `Kati.Search`'s `@tiers`,
      which is exactly that attribute, so they are still English under `:fa`.
    * **The folding table's own words** — `ZWNJ`, `harakat`, `folded`,
      `stripped`, `Arabic-Indic` — are `Kati.Search.normalisation_table/0`'s.

  Translating any of them means moving an attribute to a function in that file,
  and a screen is not where that edit belongs: the same table is drawn by more
  than this board. Board 90's Persian annotation already names three of the
  five — نیم‌فاصله, اعراب, ارقام عربی — so the vocabulary is decided and only
  the seam is missing.
  """

  # `Settings` is what board 88 draws, and it is the answer for a push that
  # names nowhere — the gallery's. The tune disc on 86, which is the only real
  # door, hands `Search` (#131).
  use Kati.Screens.Pushed, back: "Settings"
  use Gettext, backend: Kati.Gettext

  alias Kati.Search
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  def load(socket), do: socket

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
        {SettingsList.title(gettext("Scope & ranking"), gettext("What each scope searches, and in what order"), nil, :name)}
        {UI.eyebrow(gettext("Fields searched, per scope"))}
        {Kati.Screens.SearchSpec.scopes()}
        {UI.eyebrow(gettext("Group order — fixed, not relevance-sorted"))}
        {Kati.Screens.SearchSpec.group_order()}
        {UI.eyebrow(gettext("Within a group"))}
        {Kati.Screens.SearchSpec.tiers()}
        {UI.eyebrow(gettext("Caps, emphasis, retention"))}
        {Kati.Screens.SearchSpec.caps()}
        {UI.eyebrow(gettext("Persian normalisation"))}
        {Kati.Screens.SearchSpec.normalisation()}
      </Column>
    </Scroll>
    """
  end

  @doc """
  One card per scope, its fields as chips.

  The `never invitee names` field draws in the refused style rather than being
  left out — see the moduledoc.
  """
  @spec scopes() :: map()
  def scopes do
    cards =
      Search.scopes()
      |> Enum.map(fn {key, label, fields} ->
        Kati.Screens.SearchSpec.scope_card(key, label, fields)
      end)
      |> Enum.intersperse(~MOB"<Spacer size={11} />")

    ~MOB"""
    <Column fill_width={true}>
      {cards}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def scope_card(key, label, fields) do
    rows =
      fields
      |> Enum.chunk_every(3)
      |> Enum.map(&Kati.Screens.SearchSpec.field_row/1)
      |> Enum.intersperse(~MOB"<Spacer size={7} />")

    assigns = %{label: label, rows: rows, state: Kati.Screens.SearchSpec.state_pill(key)}

    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={20}
      padding={16}
      shadow={Kati.Theme.shadow_card()}
    >
      <Row fill_width={true} align="center">
        <Text
          text={@label}
          text_size={13.5}
          font_weight="bold"
          text_color={:on_surface}
          max_lines={1}
        />
        <Spacer weight={1.0} />
        {@state}
      </Row>
      <Spacer size={11} />
      {@rows}
    </Column>
    """
  end

  @doc """
  `not yet`, on a scope a search does not look in.

  This board is the SPECIFICATION and its list is wider than the executor:
  `Kati.Search.Query.run/1` builds four of its seven groups, so Music, Meals
  and Money are searched by nothing at all. A specification screen that
  overstates is worse than none, because it is the page a reader opens to find
  out why a search missed — MOVIES-AND-TV.md #74.

  The scope is not removed. The contract is the design's and stating it whole
  is what this board is for; what was missing is which half of it is live.
  `Kati.Search.built?/1` is the seam, and screen 86 greys the same four chips
  from the same predicate.
  """
  @spec state_pill(atom()) :: map()
  def state_pill(key) do
    if Kati.Search.built?(key) do
      ~MOB"<Spacer size={0} />"
    else
      Kati.Screens.SearchSpec.not_yet_pill()
    end
  end

  @doc """
  The pill itself, for the other screens that owe the same answer.

  Screen 25's *Tell me about* rows take it for exactly the reason this screen's
  scopes do — a control the app cannot keep a promise about is marked rather
  than offered — so the mark is one object and not two that could drift apart.
  MOVIES-AND-TV.md #74 and #67.

  ## It is not the greyed chip on 03, and board 322 judged the two together

  This pill and `Kati.UI.chip/2`'s disabled state were invented for the same
  question — *is there anything behind this?* — and never drawn beside each
  other, so nobody had said whether they read as one system. 322 draws them side
  by side and rules that **they mean different things and both stay**:

    * **A greyed chip** is a filter with nothing behind it TODAY and a real
      count tomorrow. It keeps its tap, and 147 draws what happens when it is
      pressed. That is data.
    * **A `NOT YET` pill** is a feature with nothing behind it, and it takes no
      tap at all. That is scope.

  The casing is the board's. `not yet` in lower case read as a footnote beside a
  bold label; the board sets it in the same mono capitals every other state mark
  on this screen uses.

  ## The mark is the reader's words, so the typography is asked rather than typed

  Persian has no case at all, so the mono-capitals treatment is three separate
  decisions in `:fa` and only one of them survives. `Kati.UI.eyebrow_label/1`
  already makes that argument for the eyebrows above; here it is the pill's own
  three props:

    * **The face.** `kati_mono.ttf` carries no Persian glyph, so «هنوز نه» set
      in `mono` is handed to Android's own substitute face — legible, and not
      Kati's. `Kati.Locale.mono_face/0` is Vazirmatn at the mono size.
    * **The tracking.** `0.08em` is what makes a run of Latin capitals read as
      a mark rather than a word. Arabic script JOINS, and tracking pulls the
      joins apart, so `Kati.Locale.tracking/1` drops it.
    * **The word.** The board's capitals cannot be produced from «هنوز نه» and
      `String.upcase/1` on it is a no-op that reads as one.

  `pgettext/2` rather than `gettext/1`: two words is short enough for
  `mix gettext.merge` to fuzzy-match it onto some other sentence, and this one
  is a state mark rather than a phrase.
  """
  @spec not_yet_pill() :: map()
  def not_yet_pill do
    assigns = %{label: pgettext("state mark", "NOT YET")}

    ~MOB"""
    <Row
      height={22}
      corner_radius={11}
      background={Palette.placeholder()}
      padding_left={9}
      padding_right={9}
      align="center"
    >
      <Text
        text={@label}
        font_family={Kati.Locale.mono_face()}
        text_size={10}
        letter_spacing={Kati.Locale.tracking(0.08)}
        text_color={Palette.muted()}
        max_lines={1}
      />
    </Row>
    """
  end

  @doc false
  def field_row(fields) do
    chips =
      fields
      |> Enum.map(&Kati.Screens.SearchSpec.field_chip/1)
      |> Enum.intersperse(~MOB"<Spacer size={6} />")

    ~MOB"""
    <Row fill_width={true} align="center">
      {chips}
      <Spacer weight={1.0} />
    </Row>
    """
  end

  @doc """
  One field, or one refusal.

  A refused field takes the tertiary ink and a strike, which is the treatment
  `Kati.UI.Segmented`'s disabled segment uses — one visual for *drawn and
  deliberately not doing this*, wherever it appears.

  ## Struck, and never pilled — board 322

  322 divides the two kinds of no by where they sit rather than by how they
  look, and the difference is legible without reading: **a pill means later, a
  rule through the word means never.** So a withdrawn FIELD is struck and takes
  no pill — *"a pill implies a queue, and these are not queued"* — while a
  deferred SCOPE keeps full ink on its label and trails the pill.

  All three withdrawn fields are here for the same reason and the board names
  each: `cast` has no person resource (203 declined it, and 311 says so on the
  page), a book's `series` is not a column, and `invitee names` is excluded on
  purpose, because searching a calendar is not searching contacts.
  """
  #
  # MOVIES-AND-TV.md #74 at the field level. `Kati.Search.kept?/1` is the same
  # seam `built?/1` is one level up, and a field with nothing behind it takes
  # the same treatment as a refused one — the reasons differ and the reader's
  # question does not: *is this searched?*
  #
  # Asked with the KEY. It was asked with the drawn word, and matched `"never"
  # <> _rest` for the invitee line, so on the Persian rendering of this board
  # all three withdrawn fields drew as searched: «بازیگران» is not `"cast"` and
  # «هرگز نام مهمانان» does not begin with `never`. mishka-group/kati#103.
  @spec field_chip({atom(), String.t()}) :: map()
  def field_chip({key, label}) when is_atom(key) do
    if Kati.Search.kept?(key) do
      Kati.Screens.SearchSpec.searched(label)
    else
      Kati.Screens.SearchSpec.refused(label)
    end
  end

  @doc false
  def searched(field) do
    assigns = %{field: field, face: Kati.Locale.mono_face(field)}

    ~MOB"""
    <Row
      height={26}
      corner_radius={13}
      background={Palette.paper()}
      padding_left={10}
      padding_right={10}
      align="center"
    >
      <Text
        text={@field}
        font_family={@face}
        text_size={10.5}
        text_color={Palette.ink_soft()}
        max_lines={1}
      />
    </Row>
    """
  end

  @doc false
  def refused(field) do
    assigns = %{field: field, face: Kati.Locale.mono_face(field)}

    ~MOB"""
    <Row height={26} corner_radius={13} padding_left={10} padding_right={10} align="center">
      <Box>
        <Text
          text={@field}
          font_family={@face}
          text_size={10.5}
          text_color={Palette.track_off()}
          max_lines={1}
        />
        <Box fill_width={true} fill_height={true} align="center">
          <Box fill_width={true} height={1} background={Palette.track_off()} />
        </Box>
      </Box>
    </Row>
    """
  end

  @doc "The seven groups in the order every result list uses, and the sentence that fixes it."
  @spec group_order() :: map()
  def group_order do
    rows =
      Search.scopes()
      |> Enum.map(fn {_scope, label, _fields} ->
        SettingsList.row(
          nil,
          SettingsList.body(label, nil),
          SettingsList.trailing(SettingsList.chevron())
        )
      end)

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.card(rows)}
      <Spacer size={12} />
      {Kati.UI.SettingsList.note("info", gettext("Always this order. A user learns where to look; relevance-sorted groups move the target every keystroke."))}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc "The four ranking tiers, numbered, each with the example the board prints."
  @spec tiers() :: map()
  def tiers do
    rows = Enum.map(Search.tiers(), &Kati.Screens.SearchSpec.tier_row/1)

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.card(rows)}
      <Spacer size={12} />
      <Text
        text={gettext("Ties break by recency.")}
        text_size={12.5}
        text_color={Palette.ink_soft()}
      />
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def tier_row({rank, name, example}) do
    numeral = Kati.Locale.number(rank)
    assigns = %{rank: numeral, face: Kati.Locale.mono_face(numeral), example: example}

    # The tier's NAME and its EXAMPLE are `Kati.Search`'s — a `@tiers`
    # attribute, which is where a `gettext/1` would freeze into whichever
    # locale the compiler happened to be in — so they are still English under
    # `:fa` and this screen is not the file that fixes it. The example's
    # `font_family="mono"` is correct for exactly as long as that is true:
    # `hollow → Hollow` is ASCII plus one arrow and DM Mono suits it, and the
    # round that translates `@tiers` has to bring `Kati.Locale.mono_face/1`
    # here with it or the Persian tier names arrive as empty boxes.
    #
    # The RANK does not wait on that. It is a rendered number, so it is already
    # the reader's digits, and `mono_face/1` asks the numeral's own script —
    # `kati_mono.ttf` carries none of U+06F0–U+06F9, so `۳` takes the Persian
    # face and `3` keeps DM Mono without either being decided twice.
    SettingsList.row(
      ~MOB"""
      <Box width={26} height={26} corner_radius={13} background={Palette.paper()} align="center">
        <Text
          text={@rank}
          font_family={@face}
          text_size={11.5}
          text_align="center"
          text_color={Palette.ink_soft()}
        />
      </Box>
      """,
      SettingsList.body(name, nil),
      SettingsList.trailing(~MOB"""
      <Text
        text={@example}
        font_family="mono"
        text_size={10.5}
        text_color={Palette.muted()}
        max_lines={1}
      />
      """)
    )
  end

  @doc """
  The three numbers and one rule that keep a result list calm.

  `Never orange` is on the page rather than assumed: orange means new/now
  everywhere in this app, and a match is neither.
  """
  @spec caps() :: map()
  def caps do
    rows_per_group = Search.rows_per_group()

    # THE CAP AS EACH SCRIPT WRITES IT.
    #
    # The board spells the number out — `Three rows per group` — because it is a
    # rule rather than a measurement, and a rule reads as prose. Persian sets
    # the digit instead, which is `Kati.Locale`'s own division of labour and
    # `Kati.Screens.SearchTyping.nothing_yet/0`'s already: the same cap, the
    # same two answers, written the same way on both screens.
    #
    # `pick/2` here rather than a locale-aware `word/1`, and that is the whole
    # reason this is three lines instead of one. `word/1` is documented — by
    # `Kati.Screens.SearchTyping`'s moduledoc, which relies on it — as knowing
    # nothing about Persian, and `Kati.Screens.MoreSources.heading/0`
    # concatenates its result onto a bare English string and doctests the
    # answer. Teaching it a second language would reach both of them and it is
    # not this screen's file to do it in.
    #
    # The figure still comes from `Kati.Search` in both branches, so the word
    # and the cap cannot drift.
    cap =
      Kati.Locale.pick(
        Kati.Screens.SearchSpec.word(rows_per_group),
        Kati.Locale.number(rows_per_group)
      )

    rows = [
      SettingsList.row(
        SettingsList.icon_tile("checklist"),
        SettingsList.body(
          gettext("%{n} rows per group", n: cap),
          # `12` and `256` stay INSIDE the msgid rather than being interpolated
          # through `Kati.Locale.number/1`. Neither is read from anywhere —
          # the first is a figure in a quoted example of another screen's row
          # and the second is `Kati.TapHandleBudgetTest`'s ceiling typed by
          # hand — so interpolating them would add a seam without adding a
          # source of truth, and the Persian sentence has to be re-read anyway
          # the day either moves. `Kati.Screens.SearchTyping`'s *forty-two*
          # sentence is typed inside its msgid for the same reason; the fa
          # entry carries ۱۲ and ۲۵۶ and the arrow the other way round.
          gettext("Then a “See all 12 →” row — also what keeps a frame under 256 event handles"),
          lines: 3
        ),
        SettingsList.trailing(nil)
      ),
      SettingsList.row(
        SettingsList.icon_tile("format_bold"),
        SettingsList.body(
          gettext("Matches emphasise by weight"),
          gettext("600 → 700 and ink. Never orange — orange only means new/now"),
          lines: 3
        ),
        SettingsList.trailing(nil)
      ),
      SettingsList.row(
        SettingsList.icon_tile("history"),
        SettingsList.body(
          # Read, so it is interpolated and converted — the digit is the
          # reader's. Board 90's *Recent · last %{n}* is the same figure on the
          # same shelf and already reads `اخیر · ۸ تای آخر`.
          gettext("Recent keeps the last %{n}", n: Kati.Locale.number(Search.recent_kept())),
          gettext("Never translated, they are your words"),
          lines: 2
        ),
        SettingsList.trailing(nil)
      )
    ]

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.card(rows)}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  A small number as the word for it.

  Only the range a cap could plausibly sit in. Anything larger comes back as
  digits, because `twenty-seven rows per group` would be a sentence nobody
  wants to read and a cap nobody would set.
  """
  @spec word(integer()) :: String.t()
  def word(n) when n in 1..10,
    do:
      Enum.at(~w(one two three four five six seven eight nine ten), n - 1) |> String.capitalize()

  def word(n), do: Integer.to_string(n)

  @doc """
  The folding table, read from `Kati.Search.normalisation_table/0`.

  Read rather than typed for the reason the moduledoc gives: this board and the
  behaviour it specifies must be one thing, and a table transcribed into a
  screen is a table that can be wrong about the code beside it.

  ## The note under it is the one msgid on this screen whose English is pinned

  *Typing ي finds ی…* is a mostly-Latin sentence carrying two Persian letters,
  so under `:en` it is set in a face that cannot draw them and
  `Kati.PersianFontTest`'s `@mixed` inventory names it by its opening words to
  say that is deliberate. The inventory matches on a PREFIX, and the msgid is
  what `:en` renders — so rewording the first sentence fails that test rather
  than this one, and the failure names a font rule rather than a catalogue.
  Under `:fa` the question does not arise: the root declares `fa`, and the
  Persian entry is Persian throughout.
  """
  @spec normalisation() :: map()
  def normalisation do
    rows = Enum.map(Search.normalisation_table(), &Kati.Screens.SearchSpec.folding_row/1)

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.card(rows)}
      <Spacer size={12} />
      {Kati.UI.SettingsList.note("info", gettext("Typing ي finds ی. Both spellings of every affected word resolve to one form before matching, so a query typed on an Arabic keyboard finds a title typed on a Persian one."))}
    </Column>
    """
  end

  @doc false
  def folding_row({from, from_code, to, to_code}) do
    assigns = %{from: from, from_code: from_code, to: to, to_code: to_code || ""}

    # `Kati.Locale.forward_glyph/0` and not the literal `arrow_forward`. This
    # row is a mapping — what you typed on one side, what it folds to on the
    # other — and `layout_direction` mirrors the Row under `:fa`, so the typed
    # form moves to the right and the folded form to the left. An arrow is a
    # PICTURE and mirrors with nothing, which is the argument `forward_glyph/0`
    # carries in full; left as the literal it went on pointing back at the form
    # it came from, which is the one thing this row exists to say.
    #
    # The two mono code columns keep `font_family="mono"` rather than asking
    # `Kati.Locale.mono_face/1`. `U+064A` is a machine's name for a character,
    # ASCII in both scripts, and DM Mono has every glyph it needs — but one of
    # the five rows is `U+064B–0652`, whose EN DASH is not ASCII, so asking by
    # script would set that row alone in Vazirmatn and leave four in DM Mono.
    # A table whose codes are in two faces reads as a mistake.
    SettingsList.row(
      nil,
      ~MOB"""
      <Row fill_width={true} align="center">
        <Text text={@from} font_family="fa" text_size={14} text_color={:on_surface} width={54} />
        <Text text={@from_code} font_family="mono" text_size={10.5} text_color={Palette.muted()} />
        <Spacer size={10} />
        {Kati.UI.symbol(Kati.Locale.forward_glyph(), size: 15, color: Palette.tertiary())}
        <Spacer size={10} />
        <Text text={@to} font_family="fa" text_size={14} text_color={:on_surface} />
        <Spacer weight={1.0} />
      </Row>
      """,
      SettingsList.trailing(~MOB"""
      <Text
        text={@to_code}
        font_family="mono"
        text_size={10.5}
        text_color={Palette.muted()}
        max_lines={1}
      />
      """)
    )
  end

  # A specification board has nothing to press. The group rows carry a chevron
  # because the board draws one — they are naming an order rather than offering
  # a destination, and screen 27's own rows are inert for the same reason.
  @doc false
  def handle_tap(_tag, socket), do: {:noreply, socket}
end
