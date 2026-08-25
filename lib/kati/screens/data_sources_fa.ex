defmodule Kati.Screens.DataSourcesFa do
  @moduledoc """
  Screen 82 — منابع داده, the Persian mirror of Data sources, pushed under
  تنظیمات.

  Screen 80's page in the mirror. `Kati.Sources` is read unchanged — the same
  ids, the same three tiers, the same tokens — and what this file supplies is
  the Persian half: the names, the sub-lines, the two sentences about where a
  token lives. `Kati.Screens.SeriesFa`'s doctrine applied to providers: *one
  list, read once, presented twice.*

  ## Four things the caption pins, and each is a real decision

    * **Provider names, licence names and domains stay Latin.** They are proper
      nouns, not copy, so nothing here translates or transliterates one.
      `name/1` makes that mechanical rather than a matter of remembering: a
      name that is pure ASCII goes in DM Mono, because it is a machine's name
      for itself and the mono face has every glyph it needs; a name that
      carries Persian — `فیلم و سریال · TVmaze` — goes in Vazirmatn, because
      `kati_mono.ttf` has no Arabic-script glyphs and would draw the Persian
      half as empty boxes while the Latin half read perfectly. The script that
      is in the string picks the face, so a provider added to `Kati.Sources`
      tomorrow is typeset correctly without anybody deciding again.

    * **The pairing code keeps DM Mono — and it cannot.** This is the one place
      the drawing asks for something the shipped fonts refuse.
      `Kati.Screens.Fa`'s moduledoc counted it: the mono subset carries **zero**
      of U+06F0–U+06F9, so `K۴Q۹B۲` in DM Mono is three Latin capitals and
      three empty boxes. It is set in `fa` at the design's 34pt, its .14em
      tracking and its `cream_ink`, which is the same trade every Persian
      numeral on every mirror already makes — the face is wrong and the glyphs
      are right. The caption's other half, *the six characters hold their
      column*, goes with it: Vazirmatn is proportional. Nothing aligns under
      the code, and nothing needs to — it is centred in its own cream card and
      is the only thing in it.

    * **The orange rule moves to the right of each section label.** It does
      that for free. `Kati.Screens.Fa.eyebrow/1` is a `Row` with the dash
      first, and a `Row` under an `rtl` root lays out start-to-end, so the dash
      lands at the right edge without a second arrangement. Nothing here
      reverses a list by hand — the same mechanism that puts the Persian dock's
      home tab on the right.

    * **The entry row belongs to screen 62 and is not in this file.** The
      caption says the ticket implied it rather than mandating it; either way
      the row that pushes here lives in `Kati.Screens.SettingsFa`'s داده‌ها
      group, and until it is added this screen is reachable only from the
      gallery. Recording that is better than a comment claiming a route that
      does not exist.

  ## Two glyphs point opposite ways, and both are right

  `arrow_forward_ios` on the back pill, `chevron_left` on the row that pushes.
  In Persian, back is rightwards and forward is leftwards, and Material Symbols
  are text in a font, which nothing auto-mirrors. Screens 62 and 69 record the
  same pair, and the commonest RTL bug there is is flipping one and not the
  other.

  ## Why this is not `use Kati.Screens.Pushed`

  That macro draws the back pill itself, and it draws it with
  `arrow_back_ios_new` and a `Text` carrying no `font_family` — a left-pointing
  chevron beside a row of empty boxes. It also takes its direction from
  `Kati.Locale.direction_prop/0`, which is the *app's* locale: a Persian mirror
  opened while the app is set to English would draw Persian copy in a
  left-to-right grid, the one thing these drawings exist to disprove. So this
  is `Kati.Screens.Fa.pushed_frame/1` with a hand-rolled pill, exactly as
  screens 69 and 72 are, and `content/1` still exists so the shape matches
  every other pushed screen.

  ## Every Persian string goes through `Kati.Screens.BookDetailFa.fa/4`

  Plus Jakarta Sans — the default for an unstyled `Text` — has no
  Arabic-script glyphs at all, so a Persian label without `font_family="fa"` is
  a row of empty boxes rather than a fallback. That rules out most of what
  screen 80 reuses: `Kati.UI.SettingsList.body/3`, `title/3`, `note/2` and
  `action_pill/1` all build their own `Text` and leave the prop off, and no
  component in `Kati.Components` accepts `font_family` either. What survives
  is everything text-free, and this screen leans on all of it — `card/1`,
  `row/4`, `icon_tile/1`, `hairline/1`, `trailing/1`, plus screen 80's own
  `last_reached/1`, `pairing_code/1`, `database_megabytes/0` and
  `connect_control/2`'s wordless head.

  ## The segmented control is screen 72's, not `Kati.UI.Segmented`

  `Kati.UI.Segmented` and `Kati.UI.chip/2` both paint their own label —
  `MishkaChip.expand/3` discards children outright and the segmented control
  says in as many words that "the label is a prop rather than the slot's
  children because the control paints it" — so a Persian label through either
  door is a row of boxes. `Kati.Screens.LogProgressFa.segments/2` is that
  control hand-rolled once, with the same trough, the same 34pt segments and
  the same shadow, and it takes its labels as strings it typesets in
  Vazirmatn. Screen 80 drew the same two options as chips; the drawing draws a
  trough on both sides of the mirror, so this takes the trough.

  ## All three connectable providers are listed, though 82 draws one

  The drawing is showing the pairing state, so it draws ListenBrainz expanded
  and stops. The screen cannot: `Kati.Sources.tier2/0` has three entries, and a
  Persian build that offered two fewer providers than the English one would be
  a translation that removed features. So the card holds every provider the app
  supports, mirroring `Kati.Screens.DataSources.tier2/1` row for row, and the
  one that is open is the one the drawing captured.

  ## Where tokens live, derived rather than translated

  `Kati.Sources.token_note/0` picks its sentence from
  `Kati.SecureStore.available?/0` rather than being copy somebody has to
  remember to update, and `token_note/0` here does the same with the Persian
  pair. Printing the reassuring version on a device where it is false would be
  the most expensive sentence in the app, and it would be exactly as expensive
  in Persian.

  ## The copy is a proposal

  Screen 72 says it and it is true here: every Persian string below was open,
  and these are proposals. They are held in `@copy` and `@sources` rather than
  scattered through the markup so that a native reader corrects each one once.
  The tables are keyed by `Kati.Sources`' own ids and merged onto its own maps,
  so a provider with no Persian entry keeps its English name and sub-line
  rather than vanishing from the list.
  """

  use Mob.Screen
  import Mob.Sigil

  alias Kati.I18n.Digits
  alias Kati.Media.CachedTitle
  alias Kati.Screens.BookDetailFa
  alias Kati.Screens.DataSources
  alias Kati.Screens.Fa
  alias Kati.Screens.LogProgressFa
  alias Kati.Screens.SettingsFa
  alias Kati.Sources
  alias Kati.Theme
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  # The screen's own words. Everything that is not a provider's name, a domain
  # or a number the device knows.
  @copy %{
    back: "تنظیمات",
    title: "منابع داده",
    subtitle: "پوسترها، جلدها و اطلاعات کاتی از کجا می‌آیند.",
    tier0: "بدون تنظیم کار می‌کند",
    tmdb: "تصویر و اطلاعات بهتر",
    tier2: "اتصال حساب",
    tokens: "توکن‌ها کجا می‌مانند",
    cache: "حافظه موقت",
    key_kati: "کلید کاتی",
    key_own: "کلید خودم",
    tmdb_note:
      "کلید کاتی عمومی است، چون کاتی متن‌باز است. این برای شما هزینه‌ای ندارد — " <>
        "TMDB درخواست‌ها را بر اساس نشانی IP می‌شمارد، نه بر اساس کلید.",
    pairing: "در حال جفت‌شدن",
    enter_code: "کد را وارد کنید",
    link: "listenbrainz.org/link",
    connect: "اتصال",
    disconnect: "قطع اتصال",
    connected: "متصل",
    wipe: "قطع همه اتصال‌ها و پاک‌کردن توکن‌ها",
    refresh: "تازه‌سازی",
    clear: "پاک‌کردن",
    megabytes: "مگابایت",
    oldest: "قدیمی‌ترین",
    nothing_cached: "هنوز چیزی ذخیره نشده",
    nothing_to_refresh: "چیزی برای تازه‌سازی نیست",
    never: "—",
    secure:
      "توکن‌ها در انبار امن همین دستگاه می‌مانند. کاتی هر توکن را فقط به سرویس " <>
        "خودش می‌فرستد و هرگز رمز عبور نمی‌خواهد.",
    unencrypted:
      "توکن‌ها رمزنگاری‌نشده روی همین دستگاه می‌مانند، چون سیستم هنوز جای امنی در " <>
        "اختیار کاتی نمی‌گذارد. کاتی هر توکن را فقط به سرویس خودش می‌فرستد و هرگز " <>
        "رمز عبور نمی‌خواهد."
  }

  # Keyed by `Kati.Sources`' own ids, and merged onto its own maps rather than
  # replacing them: `icon` and `id` stay the English list's, so a row here
  # cannot drift from the provider it claims to be. A provider with no entry
  # keeps its English name and sub-line, which is a worse row than a Persian
  # one and a far better one than a missing provider.
  @sources %{
    tvmaze: %{name: "فیلم و سریال · TVmaze", supplies: "تاریخ پخش، فهرست قسمت‌ها"},
    open_library: %{name: "کتاب · Open Library", supplies: "جلد، نسخه‌ها، شماره شابک"},
    musicbrainz: %{name: "موسیقی · MusicBrainz", supplies: "آلبوم، هنرمند، تصویر جلد"},
    listenbrainz: %{
      supplies: "پخش‌های ثبت‌شده، تاریخچه شنیدن",
      why: "ListenBrainz به توکن خودتان نیاز دارد، چون روی حساب شما می‌نویسد نه حساب کاتی."
    },
    hardcover: %{
      supplies: "امتیازهای انجمن کتاب‌خوان",
      why: "Hardcover امتیازها را با توکن خودتان می‌خواند، تا خواندن شما به نام کس دیگری ثبت نشود."
    },
    thetvdb: %{
      supplies: "تصاویر، ترتیب مطلق قسمت‌ها",
      why: "TheTVDB برای هر کاربر کلیدی می‌دهد که خودتان می‌توانید از صفحه حسابتان باطل کنید."
    }
  }

  def mount(_params, _session, socket) do
    Kati.Theme.activate()

    {:ok,
     socket
     |> Mob.Socket.assign(:tmdb, Sources.tmdb_key())
     # Opens with ListenBrainz's pairing card showing, for screen 80's reason
     # and because it is the state 82 was captured in: the page exists to be
     # told how to connect something, and the first row that can be is already
     # explaining itself.
     |> Mob.Socket.assign(:expanded, :listenbrainz)}
  end

  def render(assigns), do: Fa.pushed_frame(content(assigns), Kati.Screens.Identity.of(__MODULE__))

  @doc """
  The page, in the order 82 stacks it.

  Four accent eyebrows and one grey one. The grey dash is the design's mark for
  a section that is a footnote to the page rather than a thing to set up, and
  `Kati.Screens.Fa.eyebrow/1` only ever draws the orange one — orange means new
  or now — so the muted case comes from `Kati.Screens.SettingsFa.eyebrow/2`,
  the only Persian screen that had already drawn it.
  """
  @spec content(map()) :: map()
  def content(assigns) do
    c = @copy

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {Kati.Screens.DataSourcesFa.chrome()}
        {Kati.Screens.DataSourcesFa.title()}
        {Fa.eyebrow(c.tier0)}
        {Kati.Screens.DataSourcesFa.tier0()}
        {Fa.eyebrow(c.tmdb)}
        {Kati.Screens.DataSourcesFa.tmdb(assigns.tmdb)}
        {Fa.eyebrow(c.tier2)}
        {Kati.Screens.DataSourcesFa.tier2(assigns.expanded)}
        {Fa.eyebrow(c.tokens)}
        {Kati.Screens.DataSourcesFa.tokens()}
        {SettingsFa.eyebrow(c.cache, :muted)}
        {Kati.Screens.DataSourcesFa.cache()}
      </Column>
    </Scroll>
    """
  end

  @doc """
  The back pill, with the chevron pointing the way the reader came from.

  Hand-rolled for the reason the moduledoc gives about `Kati.Screens.Pushed`,
  and identical in every number to screens 62 and 69's: 44 tall at radius 22,
  card white under the button shadow, 12 of padding on the leading edge and 16
  on the trailing one so the glyph sits closer to the edge than the word does.
  """
  @spec chrome() :: map()
  def chrome do
    assigns = %{label: @copy.back}

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Row
          height={44}
          corner_radius={22}
          background={Palette.card()}
          shadow={Theme.shadow_button()}
          padding_left={12}
          padding_right={16}
          align="center"
          on_tap={{self(), :back}}
        >
          {UI.symbol("arrow_forward_ios", size: 17)}
          <Spacer size={6} />
          {BookDetailFa.fa(@label, 13.5, :on_surface, weight: "semibold")}
        </Row>
        <Spacer weight={1.0} />
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc """
  The screen title over its one-line subtitle.

  Not `Kati.UI.SettingsList.title/3`, and not only because it typesets in Plus
  Jakarta Sans: it sets the title at 28 with -.03em of tracking and the sub in
  DM Mono. Persian has neither. The drawing asks for 25pt at a 1.4 leading with
  no tracking at all — letter-spacing breaks the joins between Arabic-script
  letters — and a Vazirmatn sub at 12.5, which is the same substitution
  `Kati.Screens.Fa`'s moduledoc makes for every mono line on every mirror.
  """
  @spec title() :: map()
  def title do
    assigns = %{title: @copy.title, subtitle: @copy.subtitle}

    ~MOB"""
    <Column fill_width={true}>
      {BookDetailFa.fa(@title, 25, :on_surface, weight: "bold")}
      <Spacer size={5} />
      {BookDetailFa.fa(@subtitle, 12.5, Palette.muted())}
      <Spacer size={20} />
    </Column>
    """
  end

  @doc """
  The three that need no setup, each with when it was last reached.

  A time and not a tick, which is screen 80's decision and stands unchanged
  here: *reachable* is a claim with a clock on it, and a green dot beside a
  provider that last answered in March would be a lie the page has no way to
  notice. The drawing paints the dot on both sides of the mirror; repeating it
  in Persian would only be repeating it wrong.
  """
  @spec tier0() :: map()
  def tier0 do
    sources = Sources.tier0()
    last = length(sources) - 1

    rows =
      sources
      |> Enum.with_index()
      |> Enum.map(fn {source, i} ->
        source = Kati.Screens.DataSourcesFa.localise(source)

        SettingsList.row(
          SettingsList.icon_tile(source.icon),
          Kati.Screens.DataSourcesFa.body(source.name, source.supplies),
          SettingsList.trailing(Kati.Screens.DataSourcesFa.reached(source.id)),
          rule: i < last
        )
      end)

    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.card(rows)}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  A provider from `Kati.Sources` with its Persian name and sub-line laid over it.

  A merge rather than a replacement, so `id` and `icon` remain the English
  list's and cannot drift. An id `@sources` has never heard of comes back
  untouched: an English row is a poor row, and a provider silently missing from
  the Persian build is not a row at all.
  """
  @spec localise(map()) :: map()
  def localise(source), do: Map.merge(source, Map.get(@sources, source.id, %{}))

  @doc """
  A row's name over its sub-line, with the name in the face its own script needs.

  `Kati.UI.SettingsList.body/3` draws this shape and cannot draw these words —
  it builds both `Text` nodes itself and leaves `font_family` off — so only
  the two nodes are this screen's. Every number is that function's: 13 over
  11.5 with 3pt between them, ink over `sub`.
  """
  @spec body(String.t(), String.t()) :: map()
  def body(name, sub) do
    assigns = %{name: Kati.Screens.DataSourcesFa.name(name), sub: sub}

    ~MOB"""
    <Column fill_width={true}>
      {@name}
      <Spacer size={3} />
      {BookDetailFa.fa(@sub, 11.5, Palette.sub())}
    </Column>
    """
  end

  @doc """
  A provider's name, set in the face the script inside it can actually be drawn in.

  The caption's rule — *provider names, licence names and domains stay Latin,
  they are proper nouns, not copy* — made mechanical. `TMDB` and `ListenBrainz`
  are pure ASCII and take DM Mono, which is what the drawing sets them in and
  what they are: a machine's name for itself. `فیلم و سریال · TVmaze` is not,
  and DM Mono has no Arabic-script glyphs, so it would draw the Persian half as
  empty boxes and the Latin half perfectly — the worst of the two outcomes,
  because it looks deliberate. Deciding by script rather than by a hand-kept
  list means a provider added to `Kati.Sources` tomorrow is typeset right
  without anybody deciding again.
  """
  @spec name(String.t()) :: map()
  def name(text) do
    if Kati.Screens.DataSourcesFa.latin?(text) do
      assigns = %{text: text}

      ~MOB"""
      <Text text={@text} font_family="mono" text_size={13} text_color={:on_surface} max_lines={1} />
      """
    else
      BookDetailFa.fa(text, 13, :on_surface, weight: "semibold")
    end
  end

  @doc "Whether every character in `text` is one DM Mono is certain to carry."
  @spec latin?(String.t()) :: boolean()
  def latin?(text), do: String.match?(text, ~r/\A[\x20-\x7E]+\z/)

  @doc """
  When a source last answered, as `۱۸:۰۲`, or an em dash.

  `Kati.Screens.DataSources.last_reached/1` unchanged — the newest cache row
  that source wrote, in the device's own zone — with the digits folded over.
  The drawing sets this in DM Mono and it cannot be: `kati_mono.ttf` carries
  none of U+06F0–U+06F9, so the whole time would be four empty boxes and a
  colon. Vazirmatn at the design's 10.5 in `muted`, which is
  `Kati.Screens.Fa`'s standing trade for every numeral the design sets in mono.
  """
  @spec reached(atom()) :: map()
  def reached(id) do
    label =
      case DataSources.last_reached(id) do
        nil -> @copy.never
        at -> Digits.to_persian(at)
      end

    BookDetailFa.fa(label, 10.5, Palette.muted())
  end

  @doc """
  TMDB, and the choice between Kati's key and your own.

  One card holding the row and the control, which is how both drawings draw it.
  Two segments rather than a switch, because neither is the *off* state — both
  are a working configuration, and the page's job is to say that plainly. The
  trough is `Kati.Screens.LogProgressFa.segments/2`; see the moduledoc for why
  it is not `Kati.UI.Segmented`.

  The tile carries `movie` where the drawing carries TMDB's own mark, which is
  screen 80's substitution: nothing in the app fetches a provider's logo, and a
  slot that stayed empty until it did would be a hole in the card.
  """
  @spec tmdb(:kati | :own) :: map()
  def tmdb(choice) do
    units = [{@copy.key_kati, :key_kati}, {@copy.key_own, :key_own}]
    selected = if choice == :own, do: :key_own, else: :key_kati
    assigns = %{note: @copy.tmdb_note, sub: "پوستر، پس‌زمینه، بازیگران"}

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        padding={15}
        shadow={Theme.shadow_card_soft()}
      >
        {SettingsList.row(
          SettingsList.icon_tile("movie"),
          Kati.Screens.DataSourcesFa.body("TMDB", @sub),
          SettingsList.trailing(Kati.Screens.DataSourcesFa.reached(:tmdb)),
          padding: 0,
          rule: false
        )}
        <Spacer size={15} />
        {LogProgressFa.segments(units, selected)}
      </Column>
      <Spacer size={11} />
      {Kati.Screens.DataSourcesFa.note(@note)}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  The cream footnote: a gold `info`, then a paragraph at Persian leading.

  Not `Kati.UI.SettingsList.note/2`, and for two independent reasons. It builds
  its own `Text`, so the sentence would be blank boxes; and it draws a bordered
  frame over the page where both drawings here draw a cream card with a gold
  glyph. The cream card is what this page's two footnotes are — warm asides
  rather than outlined controls — so the drawing wins on both counts.
  """
  @spec note(String.t()) :: map()
  def note(text) do
    assigns = %{text: text}

    ~MOB"""
    <Column fill_width={true} background={Palette.cream()} corner_radius={20} padding={16}>
      <Row fill_width={true} align="top">
        {UI.symbol("info", size: 18, color: Palette.gold_icon())}
        <Spacer size={11} />
        <Column weight={1.0}>
          {Kati.Screens.DataSourcesFa.paragraph(@text, Palette.cream_body())}
        </Column>
      </Row>
    </Column>
    """
  end

  @doc """
  A Persian paragraph, at the leading Persian actually needs.

  `Kati.Screens.BookDetailFa.fa/4` pins `line_height` at 1.4, which is right
  for a label and wrong for a block: the drawing sets every multi-line Persian
  paragraph on this page at **1.85**, against 1.6 for the same sentences in
  English on screen 80. That gap is not decoration. Arabic-script letters carry
  descenders below the baseline and dots above it, and at 1.4 the dots of one
  line collide with the descenders of the line above. Six lines is the most any
  of these runs to, which is what `max_lines` is set to.
  """
  @spec paragraph(String.t(), term()) :: map()
  def paragraph(text, colour) do
    assigns = %{text: text, colour: colour}

    ~MOB"""
    <Text
      text={@text}
      font_family="fa"
      text_size={12.5}
      line_height={1.85}
      text_color={@colour}
      max_lines={6}
    />
    """
  end

  @doc """
  The providers you can connect, one of them open if you tapped it.

  All three, though 82 draws only the open one — see the moduledoc. Open shows
  the pairing card: a code, the site to enter it at, and how long it lasts.
  Connected offers قطع اتصال, which is the whole reason only revocable-token
  providers are on this list at all.
  """
  @spec tier2(atom() | nil) :: map()
  def tier2(expanded) do
    sources = Sources.tier2()
    last = length(sources) - 1

    rows =
      sources
      |> Enum.with_index()
      |> Enum.map(fn {source, i} ->
        Kati.Screens.DataSourcesFa.tier2_row(source, expanded, i < last)
      end)

    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.card(rows)}
      <Spacer size={11} />
    </Column>
    """
  end

  @doc """
  One connectable provider, with its pairing card under it when it is open.

  The row's own rule is suppressed and drawn after the pairing card instead, so
  an open row and the card explaining it read as one block rather than as a row
  and an orphan. `Kati.Screens.DataSources.tier2_row/2`'s arrangement exactly;
  only the two `Text` nodes and the connect control are Persian.
  """
  @spec tier2_row(map(), atom() | nil, boolean()) :: map()
  def tier2_row(source, expanded, rule?) do
    source = Kati.Screens.DataSourcesFa.localise(source)
    connected? = Sources.connected?(source.id)
    expanded? = expanded == source.id

    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.row(
        SettingsList.icon_tile(source.icon),
        Kati.Screens.DataSourcesFa.body(source.name, Kati.Screens.DataSourcesFa.sub_line(source, connected?)),
        SettingsList.trailing(Kati.Screens.DataSourcesFa.connect_control(connected?, expanded?)),
        on_tap: {self(), String.to_atom("connect_#{source.id}")},
        rule: false
      )}
      {Kati.Screens.DataSourcesFa.pairing(source, expanded?)}
      {SettingsList.hairline(rule?)}
    </Column>
    """
  end

  @doc """
  What the row says under its name: two states, not three.

  Screen 80's contract, kept. Connected names the account, because *connected*
  on its own is not worth a row — the question a connected provider answers is
  *connected as whom*. Everything else says what the provider is for, and
  **opening the row does not take that away**, which is the one place both
  drawings are overruled: they put در حال جفت‌شدن in this slot, and losing
  پخش‌های ثبت‌شده، تاریخچه شنیدن the moment you tap Connect would delete the
  answer to *what am I connecting this for* at exactly the point the question
  gets asked. The words are not lost — `pairing/2` carries them as the card's
  own label, which is where screen 80 put them too.
  """
  @spec sub_line(map(), boolean()) :: String.t()
  def sub_line(source, false), do: source.supplies

  def sub_line(_source, true), do: @copy.connected

  @doc """
  What sits at the end of a connectable row: a disclosure, a pill, or a way out.

  The open row's `expand_more` is `Kati.Screens.DataSources.connect_control/2`
  called directly — it is the one head of that function with no words in it, so
  it is the one this screen can reuse whole rather than redraw. The other two
  carry a label and are rebuilt around a Persian one at screen 80's own
  geometry: an ink-filled 30pt pill to connect, and قطع اتصال in `red` to
  leave, because leaving is the only thing here a second tap cannot undo.
  """
  @spec connect_control(boolean(), boolean()) :: map()
  def connect_control(true, _expanded?),
    do: BookDetailFa.fa(@copy.disconnect, 12.5, Palette.red(), weight: "semibold")

  def connect_control(false, true), do: DataSources.connect_control(false, true)

  def connect_control(false, false) do
    assigns = %{label: @copy.connect}

    ~MOB"""
    <Row
      height={30}
      corner_radius={15}
      background={Palette.ink_fill()}
      padding_left={14}
      padding_right={14}
      align="center"
    >
      {BookDetailFa.fa(@label, 12, Palette.on_ink(), weight: "bold")}
    </Row>
    """
  end

  @doc """
  The pairing card, or nothing.

  A device code rather than an in-app password field, which is the whole reason
  these three providers are the ones offered: the code is entered on the
  provider's own site, so Kati never sees a credential and the user never types
  one into a screen they cannot verify. `Kati.Sources`' promise — never a
  password, only a token you can revoke — is kept by there being no field here
  to type one into.

  The code is `Kati.Screens.DataSources.pairing_code/1`, folded to Persian
  digits and set in Vazirmatn; see the moduledoc for why it cannot stay in DM
  Mono. The site is screen 80's literal for all three providers, which is right
  for the one the drawing captured and wrong for the other two — the fix is a
  `link` beside `why` in `Kati.Sources`, where the real code will come from
  too, rather than two URLs invented here.
  """
  @spec pairing(map(), boolean()) :: map() | []
  def pairing(_source, false), do: []

  def pairing(source, true) do
    assigns = %{
      label: @copy.pairing,
      why: Map.get(source, :why, ""),
      enter: @copy.enter_code,
      code: Digits.to_persian(DataSources.pairing_code(source.id)),
      link: @copy.link,
      expires: "تا " <> Digits.to_persian("9:48") <> " دیگر معتبر است"
    }

    ~MOB"""
    <Column fill_width={true} padding_bottom={13}>
      {BookDetailFa.fa(@label, 11, Palette.muted(), weight: "semibold")}
      <Spacer size={8} />
      {Kati.Screens.DataSourcesFa.paragraph(@why, Palette.ink_soft())}
      <Spacer size={14} />
      <Column fill_width={true} background={Palette.cream()} corner_radius={20} padding={18}>
        {BookDetailFa.fa(@enter, 11, Palette.cream_meta(), weight: "semibold", align: "center")}
        <Spacer size={12} />
        <Text
          text={@code}
          font_family="fa"
          text_size={34}
          font_weight="medium"
          letter_spacing={0.14}
          text_align="center"
          text_color={Kati.Theme.Palette.cream_ink()}
          max_lines={1}
        />
        <Spacer size={12} />
        <Text
          text={@link}
          font_family="mono"
          text_size={11}
          text_align="center"
          text_color={Kati.Theme.Palette.cream_sub()}
          max_lines={1}
        />
        <Spacer size={9} />
        {BookDetailFa.fa(@expires, 11.5, Palette.cream_meta(), align: "center")}
      </Column>
    </Column>
    """
  end

  @doc """
  Where tokens live, and the one row that takes them all away.

  `delete_forever` and red, because it is the only destructive control on the
  page and the only one whose consequence cannot be undone by pressing it
  again. `chevron_left`, because a row that opens something opens it in the
  reading direction, and in Persian that is leftward.
  """
  @spec tokens() :: map()
  def tokens do
    assigns = %{note: Kati.Screens.DataSourcesFa.token_note(), wipe: @copy.wipe}

    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.DataSourcesFa.note(@note)}
      <Spacer size={11} />
      {SettingsList.card([
        SettingsList.row(
          SettingsList.icon_tile("delete_forever"),
          Kati.Screens.BookDetailFa.fa(@wipe, 13, Kati.Theme.Palette.red(), weight: "semibold"),
          SettingsList.trailing(
            Kati.UI.symbol("chevron_left", size: 18, color: Kati.Theme.Palette.rail_idle())
          ),
          on_tap: {self(), :wipe_tokens},
          rule: false
        )
      ])}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  The Persian sentence about where tokens live, chosen the way the English one is.

  `Kati.Sources.token_note/0` returns a different sentence depending on whether
  the platform gave Kati a secure store, and it asks
  `Kati.SecureStore.available?/0` rather than being copy somebody has to
  remember to update. This is the same question with the same two answers in
  Persian. On Android today the answer is *no* (#55), so the drawing shows the
  unencrypted sentence — and it is drawn rather than written, which is the only
  reason it can be trusted. A mirror that hardcoded the reassuring version
  because it looked better in Persian would be the most expensive sentence in
  the app.
  """
  @spec token_note() :: String.t()
  def token_note do
    if Kati.SecureStore.available?(), do: @copy.secure, else: @copy.unencrypted
  end

  @doc """
  What the cache holds, and the two pills that change it.

  Both figures are read. A page about where data comes from that stated its own
  cache size would be the one page in the app allowed to guess. The pills are
  `Kati.UI.SettingsList.action_pill/1`'s geometry with a Persian label — 30 at
  radius 15 on paper, 11.5 semibold, 12 of side padding — hand-rolled because
  the shared pill takes its label as a prop and paints it in its own family.

  Neither pill is wired, exactly as screen 80 leaves them: refreshing and
  clearing the metadata cache are `Kati.Media.CachePolicy`'s to do, and a
  button that emptied the cache from a mirror but not from the English screen
  would be the worst possible place for the two to diverge.
  """
  @spec cache() :: map()
  def cache do
    assigns = %{
      size: Kati.Screens.DataSourcesFa.cache_size(),
      oldest: Kati.Screens.DataSourcesFa.oldest(),
      refresh: @copy.refresh,
      clear: @copy.clear
    }

    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={22}
      padding={15}
      shadow={Theme.shadow_card_soft()}
    >
      <Row fill_width={true} align="center">
        <Column weight={1.0}>
          {BookDetailFa.fa(@size, 13, :on_surface, weight: "semibold")}
          <Spacer size={4} />
          {BookDetailFa.fa(@oldest, 11, Palette.muted())}
        </Column>
        <Spacer size={12} />
        {Kati.Screens.DataSourcesFa.action_pill(@refresh)}
        <Spacer size={12} />
        {Kati.Screens.DataSourcesFa.action_pill(@clear)}
      </Row>
    </Column>
    """
  end

  @doc "The small paper button a row carries instead of a switch, with a Persian label."
  @spec action_pill(String.t()) :: map()
  def action_pill(label) do
    assigns = %{label: label}

    ~MOB"""
    <Row
      height={30}
      corner_radius={15}
      background={Palette.paper()}
      padding_left={12}
      padding_right={12}
      align="center"
    >
      {BookDetailFa.fa(@label, 11.5, :on_surface, weight: "semibold")}
    </Row>
    """
  end

  @doc """
  How much the metadata cache holds, as the row prints it.

  `Kati.Screens.DataSources.database_megabytes/0` unchanged — the database
  file's own size, rounded up so a cache with something in it never says ۰,
  which reads as empty and is the one thing it is not. Only the unit and the
  numerals are this screen's.
  """
  @spec cache_size() :: String.t()
  def cache_size do
    case Ash.count(CachedTitle) do
      {:ok, 0} ->
        @copy.nothing_cached

      {:ok, _count} ->
        Digits.to_persian(DataSources.database_megabytes()) <> " " <> @copy.megabytes

      _other ->
        @copy.nothing_cached
    end
  rescue
    _error -> @copy.nothing_cached
  end

  @doc """
  How old the oldest cache row is, as the drawing writes it.

  The query is screen 80's `oldest_entry/0` repeated, and the repetition is
  worth naming rather than hiding: what that function returns is an English
  *sentence*, and the half worth sharing is the day count under it. Extracting
  `oldest_days/0` there and calling it from both sides is the one upstream ask
  this screen has.

  What cannot be shared is `Kati.Screens.DataSources.age/1`, and not for want
  of trying. Almost all of that function is choosing between `DAY` and `DAYS`,
  `MONTH` and `MONTHS` — and Persian counts nouns in the singular. ۲ ماه, never
  ۲ ماه‌ها. There is no branch here to reuse, because there is no plural.
  """
  @spec oldest() :: String.t()
  def oldest do
    CachedTitle
    |> Ash.Query.sort(fetched_at: :asc)
    |> Ash.Query.limit(1)
    |> Ash.read()
    |> case do
      {:ok, [%CachedTitle{fetched_at: %DateTime{} = at}]} ->
        days = Date.diff(Kati.Time.today(), DateTime.to_date(at))
        Kati.Screens.DataSourcesFa.age(days) <> " " <> @copy.oldest

      _other ->
        @copy.nothing_to_refresh
    end
  rescue
    _error -> @copy.nothing_to_refresh
  end

  @doc "A span of days as the row writes it — امروز, روز, ماه. No plurals: Persian has none."
  @spec age(integer()) :: String.t()
  def age(days) when days <= 0, do: "امروز"
  def age(days) when days < 31, do: Digits.to_persian(days) <> " روز"
  def age(days), do: Digits.to_persian(div(days, 30)) <> " ماه"

  def handle_info({:tap, :back}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}

  def handle_info({:tap, :key_kati}, socket) do
    Sources.put_tmdb_key(:kati)
    {:noreply, Mob.Socket.assign(socket, :tmdb, :kati)}
  end

  def handle_info({:tap, :key_own}, socket) do
    Sources.put_tmdb_key(:own)
    {:noreply, Mob.Socket.assign(socket, :tmdb, :own)}
  end

  def handle_info({:tap, :wipe_tokens}, socket) do
    Sources.disconnect_all()
    {:noreply, Mob.Socket.assign(socket, :expanded, nil)}
  end

  # A second tap on an open row closes it, so the control that opened the
  # pairing card is also the one that dismisses it. `String.to_existing_atom/1`
  # rather than `to_atom/1`: the id came from `Kati.Sources`, so it already
  # exists, and a tag that does not is a bug rather than a new atom.
  def handle_info({:tap, tag}, socket) do
    case Atom.to_string(tag) do
      "connect_" <> id ->
        source = String.to_existing_atom(id)
        now = if socket.assigns.expanded == source, do: nil, else: source
        {:noreply, Mob.Socket.assign(socket, :expanded, now)}

      _other ->
        {:noreply, socket}
    end
  end

  def handle_info(_message, socket), do: {:noreply, socket}
end
