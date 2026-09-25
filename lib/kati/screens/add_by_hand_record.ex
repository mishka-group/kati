defmodule Kati.Screens.AddByHandRecord do
  @moduledoc """
  Screen 178 — Add by hand, a record. The first thing in Kati that can put an
  album or an artist on the Music shelf.

  Built to `test/design/screens/178.html`. `D-39` opens with the sentence this
  screen exists to falsify: *the music domain is finished and unreachable*.
  `Kati.Music.Album`, `Artist`, `Track` and `Listen` are migrated, indexed and
  read by four screens, and until this file nothing anywhere in `lib/` wrote
  one — so screen 21 was permanently on `Kati.Music.Sample`, screen 74's rating
  tile printed a figure nothing could set, and screen 73's **Save listen**
  answered `{:error, :nothing_to_save}` on every device that has ever existed.

  ## Why this is not a Kind on screen 154

  `Kati.Screens.AddByHand` writes a `Kati.Media.CachedTitle` and a
  `Kati.Media.TrackedTitle`. Screen 21 reads `Kati.Music`, and the two cannot be
  made one write: `CachedTitle` has no byline column at all, and
  `Kati.Media.Watch` records that a title was watched, never that a record was
  played. So the Kind row is one control that reveals **two forms**, which is
  what board 178's own annotation says, and this is the second of them. Film,
  Series and Book are 154's domain and their chips push it.

  ## Artist is a Kind beside Album, not a field reached only through one

  `Kati.Music.Album`'s `belongs_to :artist` is `allow_nil? true`, so an
  album-only path would quietly accumulate records with nobody behind them —
  and screen 77 is a full detail page carrying `role`, `country` and
  `following`, three values an album form has nowhere to put. Following
  somebody whose records you do not own yet is a thing people do.

  Within the Album state the Artist field still creates one inline, so the
  common path stays one form: see `artist_for/1`, which reuses an artist whose
  name matches rather than filing a second person under one name.

  ## The Artist inset is a picture, and its chips carry no taps

  Board 178 draws the Album state live and the Artist state as an inset beside
  it, because that state drops three fields and gains two. This screen draws
  both, and the inset is drawn only while the live form is NOT in the Artist
  state — pick **Artist** and the inset's job has been taken over by the form
  above it.

  Nothing in the inset is tappable. `Kati.Screens.AddByHandStates.drawn_kinds/0`
  is the precedent and its own doc gives the reason in as many words: *a preview
  is not a control*. Reusing `kinds/1` there put live `kind_*` tags on a
  reference sheet that answered none of them, and here it would additionally
  give two nodes one `accessibility_id` — which `Kati.ScreenTapSweepTest`'s
  collision register exists to refuse.

  ## Where Tracks goes, and the column that does not exist

  **Tracks is a count, never eleven rows of `4:12`** — `Kati.Music.Track` marks
  `seconds` nullable and says why. There is no `track_count` column on
  `Kati.Music.Album` to put the count in, and adding one is not a free change:
  `Kati.Backup.Catalog.columns/1` is derived from the resource, so a new
  attribute moves `Kati.Backup.Catalog.fingerprint/0`, which is pinned in
  `Kati.BackupCatalogTest` against a schema version older backups are read
  under.

  So a typed count writes that many `Kati.Music.Track` rows, positioned 1..n,
  each titled `Track n`, with no seconds and no plays. That gives screen 74 the
  denominator its tracklist eyebrow has never had, and it is honest about what
  it knows: a position and nothing else. A real running order arrives with a
  provider, or with the second life board 178's caption leaves open for this
  field. Nothing is invented that a person did not type — a placeholder that
  says *track 7* claims only that the album has a seventh track, which is
  exactly what was typed.

  ## No Status row

  `Kati.Media.TrackedTitle`'s five statuses are watch statuses. An album is not
  watched and is never finished — `Kati.Music.Listen`'s own moduledoc settles
  it: *music gets no "finished" shortcut*. The row is removed rather than
  translated, and the board says so on its face.

  ## First heard takes the reader's own calendar, in both directions

  This form suggests the date it will accept, and after mishka-group/kati#103
  the suggestion is Persian for a Persian reader — ۱۳ اسفند ۱۴۰۲ where the
  English board writes `3 Mar 2024`, which is the same day. A placeholder
  advertising a format the parser refuses would be worse than an English one,
  so `parse_date/1` reads both calendars and `create_album/3` still stores the
  Gregorian date `Kati.Music.Album.first_heard_on` is declared as.

  The same asymmetry runs through Released and Tracks, and
  `Kati.I18n.Digits`'s moduledoc is where it is argued: **output needs
  nothing** — `fa` renders ۲۰۲۵ on its own — while **input is the half that
  breaks**, because `Integer.parse/1` does not recognise a Persian digit as a
  number. Both fields fold before they parse, so what the form suggests is
  what the form can read back.
  """
  use Kati.Screens.Pushed, back: "Add title"

  # The back pill's word is not wrapped here and must not be: `back:` is a
  # compile-time option, so `Kati.Screens.Pushed` translates it at draw time out
  # of the vocabulary it declares for exactly this — `gettext("Add title")` is
  # one of the entries in `Kati.Screens.Pushed.back_vocabulary/0`, and
  # `Kati.BackPillVocabularyTest` is what keeps the two lists one list.
  use Gettext, backend: Kati.Gettext

  alias Kati.Calendar.Shamsi
  alias Kati.I18n.Digits
  alias Kati.Music.Album
  alias Kati.Music.Artist
  alias Kati.Music.Track
  alias Kati.Screens.AddByHand
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  # `{kind, glyph}`, in the board's own order — the LABEL is asked for at draw
  # time and is no longer in here, which is the same move
  # `Kati.Screens.AddByHand`'s own `@kinds` made and for the same two reasons.
  #
  # A label is a translation now, and `gettext/1` inside a module attribute is
  # evaluated at COMPILE time: five labels in this list would freeze in
  # whichever locale the compiler happened to be in and no reader would ever
  # see the other one. And `kind_list/0` is a function rather than the attribute
  # at the call site for the trap `Kati.Screens.AddByHand` records: inside
  # `~MOB` an `@name` is an ASSIGN.
  #
  # The words themselves are 154's. All five Kinds are named once, by
  # `Kati.Screens.AddByHand.kind_label/1`, so this row draws the same five words
  # the chip rows on 154 and 177 draw rather than a second set of msgids that
  # could drift into a second Persian word for *album*.
  @kinds [
    {:movie, "movie"},
    {:tv, "live_tv"},
    {:book, "menu_book"},
    {:album, "graphic_eq"},
    {:artist, "mic"}
  ]

  @impl true
  def load(socket) do
    Mob.Socket.assign(socket,
      kind: :album,
      title: "",
      artist: "",
      released: "",
      tracks: "",
      first_heard: "",
      role: "",
      country: "",
      following: false,
      save_error: nil
    )
  end

  @doc false
  @spec kind_list() :: [{String.t(), atom(), String.t()}]
  def kind_list,
    do: Enum.map(@kinds, fn {kind, glyph} -> {AddByHand.kind_label(kind), kind, glyph} end)

  @doc false
  def content(assigns) do
    Kati.Screens.Pushed.page(
      ~MOB"""
      <Column fill_width={true}>
        {Kati.Screens.AddByHandRecord.heading()}
        {AddByHand.labelled(Kati.Screens.AddByHandRecord.title_label(assigns.kind), Kati.Screens.AddByHandRecord.field(:title, assigns.title, Kati.Screens.AddByHandRecord.title_hint(assigns.kind)))}
        {AddByHand.labelled(gettext("Kind"), Kati.Screens.AddByHandRecord.kinds(assigns.kind))}
        {Kati.Screens.AddByHandRecord.fields(assigns)}
        {Kati.Screens.AddByHandRecord.error(assigns.save_error)}
        {Kati.UI.Sheet.commit(gettext("Add to library"), :add)}
        <Spacer size={14} />
        {Kati.Screens.AddByHandRecord.card_note()}
        {Kati.Screens.AddByHandRecord.artist_inset(assigns.kind)}
        {Kati.Screens.AddByHandRecord.decision_note()}
      </Column>
      """,
      Kati.Screens.Pushed.content_top()
    )
  end

  @doc """
  The board's own heading, at the board's own numbers.

  Not `Kati.Screens.AddByHand.heading/0`, and the difference is measured rather
  than a matter of taste: board 154 sets its subtitle at 13px over a 7px gap and
  board 178 sets it at 13.5 over 6. `Kati.ScreenTitleSubtitleTest` parses both
  out of the HTML and compares them with what the screen rendered, so sharing
  the function would fail on this screen for a difference the board really has.

  **Neither `Text` names a `font_family`, and that is deliberate.** The bridge
  resolves a missing family against the root's and `Kati.Screens.Pushed.chrome/3`
  declares the root's as `Kati.Locale.face_prop/0`, so Persian arrives in
  Vazirmatn without either line saying so — while an explicit `sans` here would
  force Latin and draw the heading as empty boxes. The sweep above reads an
  absent family as the design's default for the same reason.

  Two things travel with the fold, both of them 177's:
  `letter_spacing` goes through `Kati.Locale.tracking/1`, because the design
  tightens its 28pt headings by a fraction of an em and the Arabic script joins
  its letters — tracking a Persian heading pulls the joins apart. And the title
  gains `max_lines={1}`: *Add by hand* is three short words and **افزودن دستی**
  is two long ones, and a display line that wraps at 28pt takes the subtitle's
  6pt gap with it.

  The two msgids are 154's, word for word. This board and 154 write the same
  sentence and there is nothing for a translator to decide twice.
  """
  @spec heading() :: map()
  def heading do
    ~MOB"""
    <Column fill_width={true}>
      <Text
        text={gettext("Add by hand")}
        text_size={28}
        max_font_scale={1.6}
        font_weight="bold"
        letter_spacing={Kati.Locale.tracking(-0.03)}
        max_lines={1}
        text_color={:on_surface}
      />
      <Spacer size={6} />
      <Text
        text={gettext("For something Kati could not find. The title is the only thing it needs.")}
        text_size={13.5}
        line_height={1.6}
        text_color={Palette.sub()}
      />
      <Spacer size={20} />
    </Column>
    """
  end

  @doc "The one required value, relabelled by Kind — `Album` under Album, `Name` under Artist."
  @spec title_label(atom()) :: String.t()
  def title_label(:artist), do: gettext("Name")
  def title_label(_kind), do: gettext("Album")

  @doc false
  @spec title_hint(atom()) :: String.t()
  def title_hint(:artist), do: gettext("Kell Ostrand")
  def title_hint(_kind), do: gettext("e.g. Tidal Works")

  @doc """
  The date the First heard field suggests, in the reader's own calendar.

  A msgid and not a `Kati.Locale.date/2` call, for two reasons the board settles
  between them. `:dated` maps onto Shamsi's `:long` under `:fa` and that shape
  carries a weekday — *یکشنبه ۱۳ اسفند ۱۴۰۲* is four tokens in a trough drawn
  for three, and `from_long/1` splits on exactly three. And the suggestion is a
  decision about which calendar a reader types in rather than a digit swap,
  which is the distinction `Kati.Screens.AddByHandBook.length_placeholder/1`
  draws between its Year field and its extent field.

  **The Persian is load-bearing and `parse_date/1` is its other half.** ۱۳ اسفند
  ۱۴۰۲ and `3 Mar 2024` are the same day, the parser reads both, and a
  translation that changed the SHAPE of this line — a comma, a fourth token, a
  month spelled in a way `Kati.Calendar.Shamsi.month_name/1` does not — would
  advertise a format the form then refused.

  `pgettext/2` and not `gettext/1`: three tokens is exactly the length
  `mix gettext.merge` fuzzy-matches against the wrong entry, which is the
  caution `Kati.Screens.AddByHandBook.length_placeholder/1` records for `380`.
  """
  @spec first_heard_hint() :: String.t()
  def first_heard_hint,
    do: pgettext("the date the First heard field suggests", "3 Mar 2024")

  @doc """
  A field, keyed on its own assign name.

  Copied from `Kati.Screens.AddByHand.field/3` rather than called, for one
  reason: the tag it builds must reach THIS screen's `handle_info/2`, and the
  `accessibility_id` must name this screen's field. Calling 154's would build
  `{self(), :title}` in this process — which is right — but would also tie this
  form's trough recipe to 154's, and 178 draws the same trough only because the
  two boards agree today.
  """
  @spec field(atom(), String.t(), String.t()) :: map()
  def field(tag, value, placeholder) do
    assigns = %{
      value: value,
      placeholder: placeholder,
      on_change: {self(), tag},
      id: Atom.to_string(tag)
    }

    ~MOB"""
    <Row
      fill_width={true}
      height={48}
      corner_radius={14}
      background={Palette.card()}
      shadow={Kati.Theme.shadow_card_soft()}
      padding_left={15}
      padding_right={15}
      align="center"
    >
      <TextField
        value={@value}
        placeholder={@placeholder}
        return_key="done"
        weight={1.0}
        accessibility_id={@id}
        on_change={@on_change}
      />
    </Row>
    """
  end

  @doc """
  The five Kind chips, live. This is the control that reveals everything below it.

  The fifth argument is the reader's face and was missing. `kind_chip/5` writes
  `font_family` out explicitly and defaults it to `"sans"`, so five chips that
  said nothing were five Persian words handed to Plus Jakarta Sans — a face with
  no Arabic glyph at all, which draws them as empty boxes rather than falling
  back to one that has. `Kati.Screens.AddByHand.kinds/1` and
  `Kati.Screens.AddByHandBook.kinds/0` pass `face_prop/0` for that reason and
  this row now does too; `Kati.PersianFontTest` is what keeps it.
  """
  @spec kinds(atom()) :: map()
  def kinds(active) do
    ~MOB"""
    <Row fill_width={true} align="center">
      {Enum.map(Kati.Screens.AddByHandRecord.kind_list(), fn {label, kind, icon} ->
        AddByHand.kind_chip(label, icon, kind == active, kind, Kati.Locale.face_prop())
      end)
      |> Enum.intersperse(AddByHand.gap())}
    </Row>
    """
  end

  @doc """
  What the chosen Kind reveals: five fields for an album, four for an artist.

  Three of the album's fields drop and two arrive, which is what the inset's
  eyebrow says out loud.
  """
  @spec fields(map()) :: map()
  def fields(%{kind: :artist} = assigns) do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.AddByHandRecord.pair(assigns)}
      {Kati.Screens.AddByHandRecord.following_row(assigns.following, {self(), :toggle_following})}
      <Spacer size={18} />
    </Column>
    """
  end

  # Three of the four placeholders are figures, and they are not the same kind
  # of figure — which is why two of them are specimens and one is a msgid.
  #
  # **Released** is `Kati.Locale.year/1` and not a msgid, which is that
  # function's own rule applied to the field that collects the figure rather
  # than to the one that prints it: *a publication year is a fact printed on the
  # object, and rendering it as ۱۴۰۳ would make the app disagree with the thing
  # in the reader's hands*. `1984` is on the sleeve. `Kati.Music.Album`'s
  # `released_year` is a Gregorian integer and screen 77 prints it back through
  # `Kati.Locale.number/1`, so a 2025 record already reads ۲۰۲۵ on a Persian
  # page — a trough suggesting ۱۴۰۴ would be inviting a reader to type a Shamsi
  # year into a column nothing downstream reads as one. Digits change here and
  # the calendar does not.
  #
  # **Tracks** is `Kati.Locale.number/1` for the reason
  # `Kati.Screens.AddByHandBook.length_placeholder/1` gives about 380: there is
  # nothing for a translator to decide about eleven, and a two-character msgid
  # is what `mix gettext.merge` fuzzy-matches against the wrong entry.
  #
  # **First heard** is the one real decision — see `first_heard_hint/0`.
  def fields(assigns) do
    ~MOB"""
    <Column fill_width={true}>
      {AddByHand.labelled(gettext("Artist"), Kati.Screens.AddByHandRecord.field(:artist, assigns.artist, gettext("Kell Ostrand")), gettext("optional"))}
      {AddByHand.labelled(gettext("Released"), Kati.Screens.AddByHandRecord.field(:released, assigns.released, Kati.Locale.year(2025)), gettext("optional"))}
      {AddByHand.labelled(gettext("Tracks"), Kati.Screens.AddByHandRecord.field(:tracks, assigns.tracks, Kati.Locale.number(11)), gettext("optional"))}
      {AddByHand.labelled(gettext("First heard"), Kati.Screens.AddByHandRecord.field(:first_heard, assigns.first_heard, Kati.Screens.AddByHandRecord.first_heard_hint()), gettext("optional"))}
    </Column>
    """
  end

  @doc "Role and Country, one row and two free-text fields — screen 77 prints them as `Composer · Iceland`."
  @spec pair(map()) :: map()
  def pair(assigns) do
    ~MOB"""
    <Row fill_width={true} align="top">
      <Column weight={1.0}>
        {AddByHand.labelled(gettext("Role"), Kati.Screens.AddByHandRecord.field(:role, assigns.role, gettext("Composer")), gettext("optional"))}
      </Column>
      <Spacer size={10} />
      <Column weight={1.0}>
        {AddByHand.labelled(gettext("Country"), Kati.Screens.AddByHandRecord.field(:country, assigns.country, gettext("Iceland")), gettext("optional"))}
      </Column>
    </Row>
    """
  end

  @doc """
  The same two labels with the values printed rather than typeable.

  The inset's own troughs. A `<TextField>` here would be a second field carrying
  the tag and the `accessibility_id` the live one carries, on a card that is a
  picture of a state — the same mistake in the same place `drawn_kinds/0`
  refuses for the chips.

  The same four msgids as `pair/0` and not four of its own. These are the two
  words screen 77 prints as one line — `Kati.Music.Sample` already carries
  `Composer · Iceland` as a single msgid — so a second pair here would risk two
  Persian words for *composer* on two pages showing the same artist.
  """
  @spec drawn_pair() :: map()
  def drawn_pair do
    ~MOB"""
    <Row fill_width={true} align="top">
      <Column weight={1.0}>
        {AddByHand.labelled(gettext("Role"), Kati.Screens.AddByHandRecord.specimen(gettext("Composer")), gettext("optional"))}
      </Column>
      <Spacer size={10} />
      <Column weight={1.0}>
        {AddByHand.labelled(gettext("Country"), Kati.Screens.AddByHandRecord.specimen(gettext("Iceland")), gettext("optional"))}
      </Column>
    </Row>
    """
  end

  @doc """
  The Following switch, and the sub-line that says exactly what it feeds.

  `Kati.Music.Artist`'s moduledoc is the reason the sub-line is not decoration:
  *premieres stay a separate opt-in so following an artist cannot silently turn
  on push*. The switch drives screen 21's releases band and one of screen 25's
  six alert types, and the row says so rather than leaving a person to find out
  which by being notified.

  `tap` is `nil` in the inset, which `Kati.ScreenTapSweepTest` documents as the
  one value a control can carry that means *not tappable* rather than *broken*.
  """
  @spec following_row(boolean(), {pid(), atom()} | nil) :: map()
  def following_row(on?, tap) do
    # The two board numbers are drawn figures and go through
    # `Kati.Locale.number/1`: ۲۱ and ۲۵ inside a Persian sentence, not 21 and
    # 25 — the one line on the row that would otherwise be in the reader's
    # other script. Interpolated rather than left inside the msgid so that a
    # board cannot be renumbered by a translator retyping a digit, which is the
    # same reason `Kati.Screens.Inbox`'s season and episode numbers are bound
    # rather than spelled.
    feeds =
      gettext("Feeds %{music}’s releases band and one of %{alerts}’s alert types — no push",
        music: Kati.Locale.number(21),
        alerts: Kati.Locale.number(25)
      )

    assigns = %{on?: on?, tap: tap, feeds: feeds}

    ~MOB"""
    <Row fill_width={true} align="center" padding_top={13} padding_bottom={13} on_tap={@tap}>
      {SettingsList.icon_tile("notifications")}
      <Spacer size={13} />
      <Column weight={1.0}>
        <Text
          text={gettext("Following")}
          text_size={13.5}
          font_weight="semibold"
          text_color={:on_surface}
        />
        <Spacer size={3} />
        <Text text={@feeds} text_size={11.5} line_height={1.4} text_color={Palette.sub()} />
      </Column>
      <Spacer size={13} />
      {SettingsList.switch(@on?)}
    </Row>
    """
  end

  @doc false
  @spec error(String.t() | nil) :: map()
  def error(nil), do: ~MOB"<Spacer size={0} />"

  def error(message) do
    assigns = %{message: message}

    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.note("error", @message)}
      <Spacer size={14} />
    </Column>
    """
  end

  @doc """
  The quiet note under the button, in five runs.

  Five `<Text>` nodes and not one sentence, because the board writes the
  emphasis as its own run. Screen 154's own note was built this way and is now
  one `Text` (`Kati.Screens.AddByHand.note/2`), because a `Column` of runs
  stacks rather than flows and broke the sentence into lines on the device.

  That costs the translator the sentence's shape. The Persian here lets the
  bold run carry the verb, which is how 154's three runs were translated, so
  the runs still read as one sentence in the other direction.

  `No Status row` is three words and takes `pgettext/2`. A msgid that short is
  what `mix gettext.merge` fuzzy-matches against any sentence that happens to
  end in the same words, and the context names the board it belongs to.
  """
  @spec card_note() :: map()
  def card_note do
    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Palette.card()}
        corner_radius={20}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={15}
        align="top"
      >
        {UI.symbol("info", size: 18, color: Palette.sub())}
        <Spacer size={11} />
        <Column weight={1.0}>
          <Text
            text={gettext("A record typed by hand carries")}
            text_size={12.5}
            line_height={1.65}
            text_color={Palette.ink_soft()}
          />
          <Text
            text={gettext("no art and no tracklist")}
            text_size={12.5}
            line_height={1.65}
            font_weight="semibold"
            text_color={Palette.ink()}
          />
          <Text
            text={gettext("; both arrive if Kati finds it later.")}
            text_size={12.5}
            line_height={1.65}
            text_color={Palette.ink_soft()}
          />
          <Text
            text={pgettext("board 178 annotation", "No Status row")}
            text_size={12.5}
            line_height={1.65}
            font_weight="semibold"
            text_color={Palette.ink()}
          />
          <Text
            text={gettext("— an album is not watched and is never finished, so the five watch statuses are removed rather than translated.")}
            text_size={12.5}
            line_height={1.65}
            text_color={Palette.ink_soft()}
          />
        </Column>
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc """
  The Artist state, drawn rather than lived — and only while the form is not
  already in it.

  See the moduledoc: nothing here carries a tap, so the chips and the switch are
  pictures of the state the chip row above opens.
  """
  @spec artist_inset(atom()) :: map()
  def artist_inset(:artist), do: ~MOB"<Spacer size={0} />"

  # The eyebrow is wrapped and called exactly as it was.
  # `Kati.UI.Eyebrow.quiet/1` still pins `font_family="mono"` and still runs its
  # label through `String.upcase/1`, so a Persian label reaches DM Mono, which
  # carries no Persian glyph, and is upcased in a script that has no case. That
  # is `Kati.UI.Eyebrow`'s to fix — the loud `Kati.UI.eyebrow/2` already asks
  # `Kati.Locale` for both, through `mono_face/0` and `eyebrow_label/1` — and
  # wrapping here is what `Kati.Screens.Subscriptions` and
  # `Kati.Screens.MedicationDetail` do with the same helper. Noted rather than
  # worked around: a call site that composed its own eyebrow to dodge it would
  # be the next copy of the decision #103 spent itself removing.
  def artist_inset(_kind) do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.Eyebrow.quiet(gettext("Artist chosen — three fields drop, two arrive"))}
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={17}
      >
        {Kati.Screens.AddByHandRecord.drawn_kinds()}
        <Spacer size={14} />
        {AddByHand.labelled(gettext("Name"), Kati.Screens.AddByHandRecord.specimen(gettext("Kell Ostrand")))}
        {Kati.Screens.AddByHandRecord.drawn_pair()}
        {Kati.Screens.AddByHandRecord.following_row(false, nil)}
      </Column>
      <Spacer size={14} />
    </Column>
    """
  end

  @doc "The chip row as a picture, with Artist lit and no taps on any of it."
  @spec drawn_kinds() :: map()
  def drawn_kinds do
    ~MOB"""
    <Row fill_width={true} align="center">
      {Enum.map(Kati.Screens.AddByHandRecord.kind_list(), fn {label, kind, icon} ->
        Kati.Screens.AddByHandRecord.drawn_chip(label, icon, kind == :artist)
      end)
      |> Enum.intersperse(AddByHand.gap())}
    </Row>
    """
  end

  @doc false
  @spec drawn_chip(String.t(), String.t(), boolean()) :: map()
  def drawn_chip(label, icon, on?) do
    assigns = %{label: label, icon: icon, on?: on?}

    ~MOB"""
    <Row
      height={32}
      corner_radius={16}
      background={if @on?, do: Palette.ink_fill(), else: Palette.card()}
      padding_left={15}
      padding_right={15}
      align="center"
    >
      {UI.symbol(@icon, size: 15, color: if(@on?, do: Palette.on_ink(), else: Palette.sub()))}
      <Spacer size={6} />
      <Text
        text={@label}
        text_size={12.5}
        font_weight="semibold"
        text_color={if @on?, do: Palette.on_ink(), else: Palette.ink_soft()}
        max_lines={1}
      />
    </Row>
    """
  end

  @doc "A field trough with a value printed in it and nothing to type into."
  @spec specimen(String.t()) :: map()
  def specimen(value) do
    assigns = %{value: value}

    ~MOB"""
    <Row
      fill_width={true}
      height={44}
      corner_radius={14}
      background={Palette.paper()}
      padding_left={13}
      padding_right={13}
      align="center"
    >
      <Text text={@value} text_size={14} text_color={:on_surface} max_lines={1} />
    </Row>
    """
  end

  @doc """
  The board's dashed annotation, in the six runs it is drawn in.

  Six msgids for the reason `card_note/0` gives: the board writes its emphasis
  as its own run and `Kati.ScreenDesignLiteralTest` compares a drawing's lines
  against the tree's, so joining them would be a different shape.

  Two of the six are short enough to take `pgettext/2` — *Tracks is a count*
  and *stored, not derived* are a board's shorthand rather than a label, and a
  three-word msgid is what `mix gettext.merge` fuzzy-matches onto a sentence
  that ends the same way.

  The two figures in it are bound rather than written into a msgid. `4:12` is a
  running time and `2011` is a year somebody has owned a record since; both are
  numerals a Persian reader reads in their own digits, and neither is a word a
  translator should have to retype correctly. `Kati.Locale.year/1` is the right
  one for 2011 and not `number/1` said twice: a year of a record is a citation,
  so its digits change and its calendar does not.
  """
  @spec decision_note() :: map()
  def decision_note do
    # Built out here rather than in the attribute: inside `~MOB` an `@name` is
    # an ASSIGN, so a binding read through one cannot also be an argument to the
    # call that consumes it.
    counted =
      gettext(
        ", never eleven rows of %{timing} — a tracklist typed by hand often has names and no timings. First heard is",
        timing: Kati.Locale.number("4:12")
      )

    derived =
      gettext(
        ": deriving it would report yesterday for a record somebody has had since %{year}.",
        year: Kati.Locale.year(2011)
      )

    assigns = %{counted: counted, derived: derived}

    ~MOB"""
    <Row
      fill_width={true}
      corner_radius={18}
      border_width={1.5}
      border_color={Palette.border()}
      padding={15}
      align="top"
    >
      {UI.symbol("info", size: 17, color: Palette.sub())}
      <Spacer size={11} />
      <Column weight={1.0}>
        <Text
          text={gettext("Artist is a Kind, not a field reached only through Album")}
          text_size={12.5}
          line_height={1.65}
          font_weight="semibold"
          text_color={Palette.ink()}
        />
        <Text
          text={gettext("— the album’s artist is nullable, so an album-only path accumulates records with nobody behind them, and following somebody whose records you do not own yet is a thing people do. Within Album the Artist field still creates one inline, so the common path stays one form.")}
          text_size={12.5}
          line_height={1.65}
          text_color={Palette.ink_soft()}
        />
        <Text
          text={pgettext("board 178 annotation", "Tracks is a count")}
          text_size={12.5}
          line_height={1.65}
          font_weight="semibold"
          text_color={Palette.ink()}
        />
        <Text text={@counted} text_size={12.5} line_height={1.65} text_color={Palette.ink_soft()} />
        <Text
          text={pgettext("board 178 annotation", "stored, not derived")}
          text_size={12.5}
          line_height={1.65}
          font_weight="semibold"
          text_color={Palette.ink()}
        />
        <Text text={@derived} text_size={12.5} line_height={1.65} text_color={Palette.ink_soft()} />
      </Column>
    </Row>
    """
  end

  @doc """
  What was typed, in whichever of the six fields.

  One clause rather than six: each `<TextField>` carries its own assign name as
  its change tag, which is the same atom `field/3` puts in `accessibility_id`.

  **The catch-all delegates to `super/2`** — `Kati.Screens.Pushed` marks
  `handle_info/2` overridable and defines four clauses on it, one of which
  routes every `{:tap, tag}` to `handle_tap/2`. Replacing all four is how screen
  88 went unreachable earlier on this branch.
  """
  @impl true
  def handle_info({:change, field, typed}, socket)
      when field in [:title, :artist, :released, :tracks, :first_heard, :role, :country] and
             is_binary(typed),
      do: {:noreply, Mob.Socket.assign(socket, field, typed)}

  def handle_info(message, socket), do: super(message, socket)

  @impl true
  def handle_tap(:add, socket), do: {:noreply, Kati.Screens.AddByHandRecord.save(socket)}

  def handle_tap(:toggle_following, socket),
    do: {:noreply, Mob.Socket.update(socket, :following, &(not &1))}

  # Album and Artist are this form's two states. Film, Series and Book belong to
  # a different write — see the moduledoc — so their chips open the form that
  # owns them rather than pretending this one can file a film.
  def handle_tap(:kind_album, socket), do: {:noreply, Mob.Socket.assign(socket, :kind, :album)}
  def handle_tap(:kind_artist, socket), do: {:noreply, Mob.Socket.assign(socket, :kind, :artist)}

  def handle_tap(tag, socket) when tag in [:kind_movie, :kind_tv, :kind_book],
    do: {:noreply, Mob.Socket.push_screen(socket, AddByHand.for_locale())}

  def handle_tap(_tag, socket), do: {:noreply, socket}

  @doc """
  Write the row, or say why not.

  The refusal is board 155's shape and this form's noun: name what is missing,
  then say **nothing was written**. The button is never disabled, because a dead
  button explains nothing — `Kati.Write`'s contract and `Kati.WriteContractTest`
  hold that on the host.

  Nothing here re-reads a shelf. Every value written is one this page drew and
  the person typed, which is the narrow form rule 2 takes on a form: there is no
  row to act on, so there is no fresh query that could substitute one.
  """
  @spec save(Mob.Socket.t()) :: Mob.Socket.t()
  def save(socket) do
    typed = String.trim(socket.assigns.title)

    # Board 155's two sentences — what is missing, then that nothing was
    # written — are ONE msgid each rather than a fragment joined to a shared
    # tail. `refusal/1` used to concatenate the second sentence on, and after
    # the fold that would hand a translator half a sentence and no say in what
    # order the two halves stand in. `Kati.Screens.AddByHandBook.taken/1` and
    # `Kati.Screens.AddToList` both carry the whole refusal in one entry —
    # *چیزی نوشته نشد.* is already the app's word for the second half — and
    # these two follow them. The English is unchanged to the byte.
    cond do
      typed == "" and socket.assigns.kind == :artist ->
        Mob.Socket.assign(
          socket,
          :save_error,
          gettext("A name is the one thing this needs. Nothing was written.")
        )

      typed == "" ->
        Mob.Socket.assign(
          socket,
          :save_error,
          gettext("An album title is the one thing this needs. Nothing was written.")
        )

      true ->
        commit(socket, typed)
    end
  end

  defp commit(socket, typed) do
    case write(socket.assigns.kind, typed, socket.assigns) do
      {:ok, _record} -> Kati.Screens.Resume.pop(socket)
      error -> Mob.Socket.assign(socket, :save_error, Kati.Write.message(error))
    end
  end

  @doc """
  The write, one clause per Kind.

  An artist is one row. An album is up to three writes and they are ordered so
  that a failure leaves the least behind: the artist first (it may already
  exist), then the album that points at it, then the tracks that point at the
  album. A tracklist that cannot be written does not undo the album — the record
  is the thing the person asked for, and the count is the denominator.
  """
  @spec write(atom(), String.t(), map()) :: {:ok, struct()} | {:error, term()}
  def write(:artist, name, assigns) do
    Artist
    |> Ash.Changeset.for_create(:create, %{
      name: name,
      role: presence(assigns.role),
      country: presence(assigns.country),
      following: assigns.following,
      source: :manual,
      source_id: name
    })
    |> Ash.create()
    |> Kati.Write.note("add artist by hand #{name}")
  end

  def write(_album, title, assigns) do
    with {:ok, artist_id} <- artist_for(assigns.artist),
         {:ok, album} <- create_album(title, artist_id, assigns),
         {:ok, _tracks} <- create_tracks(album, assigns.tracks) do
      {:ok, album}
    end
    |> Kati.Write.note("add album by hand #{title}")
  end

  @doc """
  The artist behind a typed name: the one already stored, or a new one.

  **A typed name that matches nothing creates the artist**, and a typed name
  that matches one REUSES it — matched case-insensitively on the trimmed name,
  because *kell ostrand* and *Kell Ostrand* are one person and filing two rows
  would give screen 77 two pages and screen 21 two follow switches for them.

  Matched in Elixir over one read rather than by a filter, for the reason
  `Kati.Screens.AddTitle.cache/2` gives one domain over: there is no index on a
  case-folded name, and adding one to make a form's lookup prettier is a
  migration this ticket has no need of.

  An empty field answers `{:ok, nil}`. `Kati.Music.Album`'s `artist_id` is
  nullable and the form must not pretend otherwise.
  """
  @spec artist_for(String.t()) :: {:ok, String.t() | nil} | {:error, term()}
  def artist_for(typed) do
    case presence(typed) do
      nil ->
        {:ok, nil}

      name ->
        case existing_artist(name) do
          %Artist{id: id} -> {:ok, id}
          nil -> new_artist(name)
        end
    end
  end

  defp existing_artist(name) do
    folded = String.downcase(name)

    case Ash.read(Artist) do
      {:ok, artists} -> Enum.find(artists, &(String.downcase(&1.name) == folded))
      _other -> nil
    end
  rescue
    _error -> nil
  end

  defp new_artist(name) do
    Artist
    |> Ash.Changeset.for_create(:create, %{name: name, source: :manual, source_id: name})
    |> Ash.create()
    |> case do
      {:ok, artist} -> {:ok, artist.id}
      error -> error
    end
  end

  defp create_album(title, artist_id, assigns) do
    Album
    |> Ash.Changeset.for_create(:create, %{
      title: title,
      artist_id: artist_id,
      released_year: year(assigns.released),
      first_heard_on: Kati.Screens.AddByHandRecord.parse_date(assigns.first_heard),
      source: :manual,
      source_id: title
    })
    |> Ash.create()
  end

  # Nothing typed is no tracklist at all, which is a real state of a record
  # somebody has just remembered they own.
  defp create_tracks(_album, ""), do: {:ok, []}

  defp create_tracks(album, typed) do
    case count(typed) do
      nil ->
        {:ok, []}

      n ->
        Enum.reduce_while(1..n, {:ok, []}, fn position, {:ok, made} ->
          case create_track(album, position) do
            {:ok, track} -> {:cont, {:ok, [track | made]}}
            error -> {:halt, error}
          end
        end)
    end
  end

  # `Kati.Music.Track.title` is `allow_nil? false`, so a counted tracklist has
  # to write a word, and screen 74 prints it back verbatim. In the reader's own
  # language, then, and in the reader's own digits: eleven rows reading
  # `Track 1`…`Track 11` on a Persian page would be the longest run of Latin
  # anywhere in the app, and the person who put them there typed nothing but a
  # number.
  #
  # **This is the one string on this screen that freezes.** It is written to the
  # database at save time, so a reader who later changes language keeps the
  # tracklist they created in the old one. That is the honest trade rather than
  # an oversight: the alternative freezes English for everybody, and the row is
  # a placeholder the moduledoc already describes as standing in until a
  # provider supplies the real running order — which overwrites it anyway.
  #
  # `pgettext/3`: `Track %{n}` is two words and would fuzzy-match, and the
  # context says which of the app's several senses of *track* this is.
  defp create_track(album, position) do
    Track
    |> Ash.Changeset.for_create(:create, %{
      album_id: album.id,
      position: position,
      title:
        pgettext("a counted tracklist's placeholder title", "Track %{n}",
          n: Kati.Locale.number(position)
        )
    })
    |> Ash.create()
  end

  # A year is four digits or it is nothing. `1984` is a year; `nineteen
  # eighty-four` is a sentence, and storing `nil` for it is better than storing
  # a number nobody typed.
  #
  # `Kati.I18n.Digits.parse_integer/1` and not `Integer.parse/1`: the field
  # suggests ۲۰۲۵ to a Persian reader — see `fields/1` — and a reader who takes
  # a form up on its own suggestion must not have it silently dropped.
  # `parse_integer/1` also strips the grouping mark, which matters here because
  # the separator a Persian keyboard produces is U+066C and not a comma:
  # `Integer.parse/1` answers `{1, "٬984"}` for `۱٬۹۸۴` — a wrong number,
  # quietly, rather than an error.
  defp year(typed) do
    case Digits.parse_integer(String.trim(typed)) do
      {value, ""} when value > 0 and value < 3000 -> value
      _other -> nil
    end
  end

  # A count is a positive whole number, capped at the longest running order
  # anyone would type by hand. The cap is not taste: each track is a row, and a
  # slipped keystroke of `1100` would write eleven hundred of them.
  #
  # Folded for `year/1`'s reason, and here the placeholder the field draws IS
  # Persian digits under `:fa` — `Kati.Locale.number(11)` — so `Integer.parse/1`
  # would have refused the exact figure the trough was showing.
  defp count(typed) do
    case Digits.parse_integer(String.trim(typed)) do
      {value, ""} when value > 0 and value <= 200 -> value
      _other -> nil
    end
  end

  @doc """
  `3 Mar 2024` or `۱۳ اسفند ۱۴۰۲` — which are the same day — or nothing.

  The board writes the date the way screen 74 prints it, so that is the form
  this parses; an ISO date is accepted too because a keyboard offers one and
  refusing it would be pedantry. Anything else is `nil` rather than a guess —
  `Kati.Music.Album.first_heard_on` is nullable and *stored, not derived*, so
  the honest answer to an unparseable date is that it was not recorded.

  ## Both calendars, because the field suggests both

  `first_heard_hint/0` draws a Shamsi date for a Persian reader, and a
  placeholder advertising a shape the parser refused would be worse than an
  English one: the reader would type what they were shown, the form would
  accept the save, and the date would simply not be there. So the long form is
  read in either calendar.

  A Shamsi month name is **not** a translation of a Gregorian one —
  `Kati.Screens.LogWeight.days_since/1` states the rule and is where it was last
  got wrong — it is a different month, and ۱۳ اسفند ۱۴۰۲ is arithmetic rather
  than vocabulary. `Kati.Calendar.Shamsi.to_gregorian/3` is that arithmetic, and
  its own moduledoc names this as the case it exists for: *converting at the
  edge, for rendering and for parsing a date the user picked.*

  Digits fold before anything looks at the string, which
  `Kati.I18n.Digits`'s moduledoc calls the asymmetric half of the whole
  problem: a reader typing ۱۳ hands `Integer.parse/1` and `Date.from_iso8601/1`
  a string neither recognises as a number.

  What is stored is Gregorian either way. Only the reading changes.

      iex> Kati.Screens.AddByHandRecord.parse_date("3 Mar 2024")
      ~D[2024-03-03]

      iex> Kati.Screens.AddByHandRecord.parse_date("۱۳ اسفند ۱۴۰۲")
      ~D[2024-03-03]

      iex> Kati.Screens.AddByHandRecord.parse_date("2024-03-03")
      ~D[2024-03-03]

      iex> Kati.Screens.AddByHandRecord.parse_date("some time in the nineties")
      nil
  """
  @spec parse_date(String.t()) :: Date.t() | nil
  def parse_date(typed) do
    trimmed = typed |> String.trim() |> Digits.fold()

    case Date.from_iso8601(trimmed) do
      {:ok, date} -> date
      _error -> from_long(trimmed)
    end
  end

  @months ~w(jan feb mar apr may jun jul aug sep oct nov dec)

  # `3 Mar 2024` and `۱۳ اسفند ۱۴۰۲` are one shape — a day, a month's name, a
  # year — in two calendars, so the split and the two numbers are shared and
  # only the month lookup differs. Neither branch can answer for the other's
  # date: `mar` is not a Persian month name and اسفند's first three characters
  # are in no Latin list, so the fall-through is a real miss rather than a
  # coincidence waiting to happen.
  defp from_long(text) do
    with [day, month, year] <- String.split(text, " ", trim: true),
         {day, ""} <- Integer.parse(day),
         {year, ""} <- Integer.parse(year) do
      gregorian(year, month, day) || shamsi(year, month, day)
    else
      _other -> nil
    end
  end

  defp gregorian(year, month, day) do
    with index when is_integer(index) <-
           Enum.find_index(@months, &(&1 == month |> String.downcase() |> String.slice(0, 3))),
         {:ok, date} <- Date.new(year, index + 1, day) do
      date
    else
      _other -> nil
    end
  end

  # The month names come from `Kati.Calendar.Shamsi.month_name/1` rather than a
  # list copied down here, for the reason that module gives one delegation over:
  # two tables drift, and the one on this side is the one that would quietly
  # stop being maintained. Nothing is abbreviated — cutting مرداد to three
  # characters gives مرد, which is a different word, and `Kati.Locale.date/2`
  # records that as why Shamsi has no `:short` month at all.
  defp shamsi(year, month, day) do
    with index when is_integer(index) <- Enum.find(1..12, &(Shamsi.month_name(&1) == month)),
         {:ok, date} <- Shamsi.to_gregorian(year, index, day) do
      date
    else
      _other -> nil
    end
  end

  defp presence(value) when is_binary(value) do
    case String.trim(value) do
      "" -> nil
      trimmed -> trimmed
    end
  end

  defp presence(_value), do: nil
end
