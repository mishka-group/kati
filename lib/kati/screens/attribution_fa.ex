defmodule Kati.Screens.AttributionFa do
  @moduledoc """
  Screen 85 — این‌ها از کجا می‌آیند, the Persian mirror of screen 83, pushed
  under تنظیمات.

  ## One rule decides every string on this page

  The caption states it: **Kati's own sentences translate; the quoted notices
  do not.** A licence's sentence is quoted, so it has to read as what it is —
  English, in an English block — and Kati's sentence beside it is Kati talking
  to a Persian reader, so it is Persian. Every difference between this file and
  `Kati.Screens.Attribution` falls out of that one line, including three that
  look at first like the drawing drifting:

    * **The `takes` line translates.** *Film posters, backdrops and the facts
      behind them* is Kati describing what it fetched. Nobody's licence
      requires those words.
    * **Two notices lose a clause.** Screen 83 ends TVmaze's with *— this link
      is the licence condition* and MusicBrainz's with *, both
      community-maintained*. Neither clause is in the licence; both are Kati's
      own gloss. Left in the English block here they would be Kati's sentence
      left untranslated, which is the one thing this page tells the reader it
      does not do. So `@quoted` carries the required sentence and stops.
    * **`Kati, and Mob` becomes `Kati, Mob`.** The same rule again, one word
      long: *and* is English grammar inside a column that is otherwise nothing
      but Latin proper names. A list of names survives the mirror; a sentence
      does not.

  What stays Latin stays Latin: licence names, typeface names and domains, all
  in DM Mono. Those are identifiers, not prose — `CC BY-SA` transliterated is a
  different licence, and `openlibrary.org` transliterated is not a domain.

  ## The English block is an alignment, not a direction

  `layout_direction` is read from the **root node only** — `MainActivity.kt:285`
  pulls it off `root.props` and provides `LocalLayoutDirection` once for the
  whole tree — so wrapping a notice in an `ltr` Box would compile, render, and
  do nothing. The block is stated instead as `text_align="absolute_left"`,
  which `textAlignProp` (`MobBridge.kt:4632`) maps to `TextAlign.Left`: an
  *absolute* alignment that never consults the layout direction, so it is left
  on this screen and left on screen 83. Setting any alignment also makes the
  bridge fill the `Text`'s width (`MobBridge.kt:3385`), which is what gives the
  alignment something to align inside — without it a `Text` measures to its
  content and the prop is a no-op the bridge's own comment warns about.

  ## Two glyphs point opposite ways, and both are right

  The back pill takes `arrow_forward_ios` and every card takes `chevron_left`.
  Back is the way the reader came from and in Persian that is the right edge;
  a row that opens something opens it in the reading direction, which is
  leftward. Material Symbols are text in a font and nothing auto-mirrors them,
  so a screen that flips one and not the other sends the reader both ways at
  once. `Kati.Screens.SettingsFa` records the same pair for screen 62.

  ## Every padding number is screen 83's number, unchanged

  `padding_left` reaches Compose as `start` and `padding_right` as `end`
  (`MobBridge.kt:4517`) — direction-aware, not physical. So the back pill's
  `padding_left={12} padding_right={16}` is the drawing's `12px` beside the
  chevron and `16px` after the label on *this* screen exactly as it is the
  other way round on 83, and not one inset is swapped by hand here.

  ## What comes back from screen 83 is precisely its Latin half

  `mark/1`, `sources/0` and `open_source/0`, and that is not a coincidence —
  it is the caption's rule seen from the other end. The half of screen 83 that
  does not change under the mirror is the half that was never prose:

    * `Kati.Screens.Attribution.mark/1` draws all four square slots. It is a
      paper square holding a Latin initial, so the font rule below never bites
      it. It comes at 83's own 10pt radius rather than the drawing's 12 — two
      points, and one mark slot that both screens share is worth more than two
      that agree until somebody edits one.
    * `Kati.Screens.Attribution.sources/0` supplies every domain and licence
      tag. Those must never drift between the two pages, and the way to
      guarantee that is to have one list, not two that look alike.
    * `Kati.Screens.Attribution.open_source/0` supplies the licence names *and
      their order*, so a fourth licence added there appears here — loudly, via
      `Map.fetch!/2`, rather than silently going uncredited.

  Nothing else survives, because everything else on 83 builds its own `Text`.

  ## The font rule, which is why so little else is shared

  Every Persian `Text` needs `font_family="fa"`. Plus Jakarta Sans carries no
  Arabic-script glyphs at all, so a Persian label without it is a row of empty
  boxes rather than a fallback — `Kati.Screens.Fa`'s moduledoc checked the
  `cmap` and says so. That rules out `Kati.UI.SettingsList.body/3`,
  `title/3`, `note/2` and `Kati.UI.eyebrow/2` wholesale: each paints its own
  label in the default family. The single English `Text` on this page —
  `quoted/1` — is the one that must **not** carry the prop.

  Two shared nodes survive the rule because they hold no text at all:
  `Kati.UI.SettingsList.hairline/1` is every rule inside every card here, and
  `Kati.Components.MishkaPill` frames the closing note through its content
  slot, which is the door `Kati.Screens.Fa` names for exactly this.

  ## The eyebrow's dash is grey, and that is meaning rather than taste

  `Kati.Screens.Fa.eyebrow/1` pins the accent dash and takes no option;
  `Kati.UI.SettingsList.eyebrow_muted/1` exists because orange means new/now in
  this design and a footnote section is neither. متن‌باز is a footnote to the
  sources above it, so it takes the `#C4BDB3` dash — with the Persian type
  recipe (Vazirmatn 11 / 600 / no tracking) that `Kati.Screens.Fa.eyebrow/1`
  would otherwise have supplied.

  ## Why not `Kati.Screens.Pushed`

  `Kati.Screens.Pushed.back_pill/1` hard-codes `arrow_back_ios_new` and an
  unstyled `Text`, and `chrome/2` takes its direction from `Kati.Locale` — so a
  Persian page rendered through it while the app is still set to English would
  draw a left-pointing chevron beside a row of empty boxes in a left-to-right
  grid. `Kati.Screens.Fa.pushed_frame/1` declares `rtl` as a literal instead,
  on the same reasoning screens 69 and 72 give: the screen *is* the Persian
  one, whatever the setting says.

  ## JustWatch is on 83 and is not here

  The drawing lists four sources; screen 83 lists five. `@drawn` names the four
  in the drawing's order rather than filtering, because a source Kati takes
  data from and does not credit is a licence breach, and an omission that lives
  in a visible list can be argued with — a `reject` clause cannot. If 83's
  fifth source is meant to appear in the mirror, adding `:justwatch` to
  `@drawn` and its two lines to `@fa` is the whole change.

  ## The copy is a proposal

  Screens 69 and 72 keep their Persian in `Kati.Books.SampleFa`; there is no
  attribution fixture yet, so it is here in `@copy`, `@fa` and `@covers` — one
  place, for the same reason those files give: when a native reader corrects a
  line it is corrected once. It moves to a fixture module unchanged.
  """

  use Mob.Screen
  import Mob.Sigil

  alias Kati.Components.MishkaPill
  alias Kati.Screens.Attribution
  alias Kati.Screens.BookDetailFa
  alias Kati.Screens.Fa
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  # Kati's own sentences, so all of them are Persian. See the moduledoc's first
  # section for the rule, and its last for why they live here rather than in a
  # `Kati.Fa.Sample*` fixture.
  @copy %{
    back: "تنظیمات",
    title: "این‌ها از کجا می‌آیند",
    sub: "پوستر، جلد، تاریخ پخش و اطلاعات",
    eyebrow: "متن‌باز",
    open_source:
      "کاتی با پروانه MIT منتشر شده و بر کار کسانی ایستاده که آن را رایگان در اختیار گذاشتند.",
    non_commercial:
      "کاتی رایگان است، تبلیغ ندارد و چیزی درون خودش نمی‌فروشد. " <>
        "همین است که آن را در چارچوب شرایط غیرتجاری TMDB نگه می‌دارد.",
    mirror:
      "نشان‌های تجاری هرگز آینه نمی‌شوند و هرگز به رنگ‌های کاتی درنمی‌آیند. " <>
        "جمله‌های خود کاتی ترجمه می‌شوند؛ متن حقوقی نقل‌شده در زبان اصلی می‌ماند."
  }

  # The four the drawing lists, in the drawing's order. A list rather than a
  # filter over screen 83's five — see the moduledoc on JustWatch.
  @drawn [:tmdb, :tvmaze, :open_library, :musicbrainz]

  # Per source, the two strings the mirror decides for itself.
  #
  # `takes` is Kati's own sentence and therefore Persian. `notice` is the
  # licence's, and is the QUOTED sentence only: screen 83 appends its own gloss
  # to two of these, and a gloss is Kati talking, which on this page means
  # Persian or nothing. Editing one of these for tone is a licence change, so
  # they are literals — the domains and licence tags beside them are not, and
  # come from `Kati.Screens.Attribution.sources/0` so the two pages cannot
  # disagree about where a thing came from.
  @fa %{
    tmdb: %{
      takes: "پوستر فیلم‌ها، پس‌زمینه‌ها و اطلاعات پشت آن‌ها.",
      notice: "This product uses the TMDB API but is not endorsed or certified by TMDB."
    },
    tvmaze: %{
      takes: "برنامه پخش تلویزیون و فهرست قسمت‌ها.",
      notice: "Schedule data from TVmaze, used under CC BY-SA 4.0."
    },
    open_library: %{
      takes: "جلد کتاب‌ها، نسخه‌ها و شماره شابک.",
      notice: "Book records from Open Library, an Internet Archive project."
    },
    musicbrainz: %{
      takes: "اطلاعات آلبوم و هنرمند، و تصویر جلد جایی که وجود دارد.",
      notice: "Music metadata from MusicBrainz and cover art from the Cover Art Archive."
    }
  }

  # What each licence covers, keyed by the licence name screen 83 already
  # publishes. Bare lists of proper names, not the English phrases 83 uses —
  # the moduledoc's third bullet.
  @covers %{
    "MIT" => "Kati, Mob",
    "Apache-2.0" => "Mishka Chelekom",
    "OFL" => "Plus Jakarta Sans, DM Mono, Vazirmatn"
  }

  def mount(_params, _session, socket) do
    Kati.Theme.activate()
    {:ok, socket}
  end

  def render(assigns), do: Fa.pushed_frame(content(assigns), Kati.Screens.Identity.of(__MODULE__))

  @doc """
  Kati's own strings on this page, in one map.

  Public so a reviewer who reads Persian can find every sentence this screen
  puts in front of a reader without reading the markup, and so the day an
  attribution fixture exists the move is a one-line change here.
  """
  @spec copy() :: map()
  def copy, do: @copy

  @doc """
  The four sources the drawing lists, each a screen-83 source with its Persian
  line and its quoted notice merged over the top.

  The domain, the licence tag and the name behind the mark all come from
  `Kati.Screens.Attribution.sources/0`, so neither page can drift on a fact the
  other states. The raise is deliberate: if screen 83 renames or drops a source
  this screen draws, the mirror must stop rather than quietly credit nobody.
  """
  @spec sources() :: [map()]
  def sources do
    english = Attribution.sources()

    Enum.map(@drawn, fn id ->
      source =
        Enum.find(english, &(&1.id == id)) ||
          raise ArgumentError,
                "screen 83 no longer lists #{inspect(id)}, which screen 85 draws — " <>
                  "the mirror cannot invent a domain or a licence tag"

      Map.merge(source, Map.fetch!(@fa, id))
    end)
  end

  @doc """
  The licences Kati's own dependencies ship under, with what each covers.

  The names and their order are `Kati.Screens.Attribution.open_source/0`'s, so
  a licence added there appears here too; only the covered names are restated,
  as a list rather than a sentence. `Map.fetch!/2` rather than a default: a new
  licence with no line yet should raise on the next render, because the
  alternative is a licence row that credits nothing.
  """
  @spec open_source() :: [{String.t(), String.t()}]
  def open_source do
    Enum.map(Attribution.open_source(), fn {licence, _covers} ->
      {licence, Map.fetch!(@covers, licence)}
    end)
  end

  @doc """
  The page, from the back pill down to the closing note.

  Named `content/1` and called from `render/1` so this file has the same shape
  as every pushed screen even though it cannot use `Kati.Screens.Pushed` — see
  the moduledoc.
  """
  @spec content(map()) :: map()
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
        {Kati.Screens.AttributionFa.chrome()}
        {Kati.Screens.AttributionFa.title()}
        {Kati.UI.notice(assigns[:link_error])}
        {Kati.Screens.AttributionFa.source_cards()}
        {Kati.Screens.AttributionFa.eyebrow()}
        {Kati.Screens.AttributionFa.open_source_card()}
        {Kati.Screens.AttributionFa.non_commercial()}
        {Kati.Screens.AttributionFa.mirror_note()}
      </Column>
    </Scroll>
    """
  end

  @doc """
  The back pill, with the chevron pointing the way the reader came from.

  Screen 69's pill, number for number, rebuilt here only because that one reads
  its label out of `Kati.Books.SampleFa` and this one goes back to تنظیمات.
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
          shadow={Kati.Theme.shadow_button()}
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
  The 25pt title over its Persian subtitle.

  `Kati.UI.SettingsList.title/3` is the shared version and cannot be used: it
  sets 28pt, `letter_spacing={-0.03}`, and a `font_family="mono"` subtitle —
  three things that are all wrong for Persian at once. Negative tracking closes
  up a script that joins its letters, and the drawing sets Persian tracking to
  0 everywhere.
  """
  @spec title() :: map()
  def title do
    c = @copy

    ~MOB"""
    <Column fill_width={true}>
      {BookDetailFa.fa(c.title, 25, :on_surface, weight: "bold", lines: 2)}
      <Spacer size={5} />
      {BookDetailFa.fa(c.sub, 12.5, Palette.muted())}
      <Spacer size={20} />
    </Column>
    """
  end

  @doc "One card per source, each carrying its own required sentence."
  @spec source_cards() :: map()
  def source_cards do
    cards =
      sources()
      |> Enum.map(&Kati.Screens.AttributionFa.source_card/1)
      |> Enum.intersperse(~MOB"<Spacer size={12} />")

    ~MOB"""
    <Column fill_width={true}>
      {cards}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  One source: mark and Persian line, then the quoted notice, then the licence
  tag beside the domain.

  Three bands separated by two hairlines, and the order is the argument the
  page is making — *this is what we took*, *this is what they require us to
  say*, *this is where it came from*. The notice is the middle band on purpose:
  it is the only one a licence has an opinion about.
  """
  @spec source_card(map()) :: map()
  def source_card(source) do
    assigns = %{
      source: source,
      tap: {self(), String.to_atom("open_#{source.id}")}
    }

    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={22}
      padding={15}
      shadow={Kati.Theme.shadow_card_soft()}
      on_tap={@tap}
    >
      <Row fill_width={true} align="center">
        {Kati.Screens.AttributionFa.mark(@source)}
        <Spacer size={13} />
        <Column weight={1.0}>
          {Kati.Screens.AttributionFa.para(@source.takes, Kati.Theme.Palette.ink_soft(), 1.8)}
        </Column>
      </Row>
      <Spacer size={13} />
      {Kati.UI.SettingsList.hairline(true)}
      <Spacer size={12} />
      {Kati.Screens.AttributionFa.quoted(@source.notice)}
      <Spacer size={12} />
      {Kati.UI.SettingsList.hairline(true)}
      <Spacer size={12} />
      <Row fill_width={true} align="center">
        {Kati.Screens.AttributionFa.licence_tag(@source.licence)}
        <Column weight={1.0}>
          <Text
            text={@source.site}
            font_family="mono"
            text_size={12}
            text_color={:on_surface}
            max_lines={1}
          />
        </Column>
        <Spacer size={11} />
        {Kati.UI.symbol("chevron_left", size: 18, color: Kati.Theme.Palette.rail_idle())}
      </Row>
    </Column>
    """
  end

  @doc """
  The brand mark's slot, square or wide.

  TMDB's is the wide one because TMDB's mark is a wordmark, and squeezing a
  wordmark into a 40pt square is a modification of the mark — which most of the
  licences on this page forbid in as many words, including TMDB's. The slot has
  to be the shape the artwork is, or the artwork cannot go in it unaltered.

  The other three are `Kati.Screens.Attribution.mark/1` unchanged: a paper
  square with the source's initial, holding the place until the real files are
  in `priv/`, never a recoloured approximation of somebody's logo.
  """
  @spec mark(map()) :: map()
  def mark(%{id: :tmdb, name: name}), do: Kati.Screens.AttributionFa.wide_mark(name)
  def mark(%{name: name}), do: Attribution.mark(name)

  @doc """
  The 96x40 slot, with the wordmark spelled out rather than cut to an initial.

  A `T` in a wide box would read as a square mark that failed to fill its
  frame. The word says the slot is waiting for a word.
  """
  @spec wide_mark(String.t()) :: map()
  def wide_mark(name) do
    assigns = %{name: name}

    ~MOB"""
    <Box width={96} height={40} corner_radius={8} background={Palette.paper()} align="center">
      <Text
        text={@name}
        font_family="mono"
        text_size={12}
        letter_spacing={0.08}
        text_align="center"
        text_color={Palette.sub()}
        max_lines={1}
      />
    </Box>
    """
  end

  @doc """
  The licence tag beside a domain, or nothing where the licence names none.

  Bare tracked mono, where screen 83 draws a gold pill. The notice directly
  above already carries the licence inside the sentence it is quoting — *used
  under CC BY-SA 4.0* — so a coloured pill repeating it would state the same
  fact twice and louder the second time. Demoted to a tag, it reads as what it
  is: a label on the link below it.
  """
  @spec licence_tag(String.t() | nil) :: map()
  def licence_tag(nil), do: ~MOB"<Spacer size={0} />"

  def licence_tag(label) do
    assigns = %{label: label}

    ~MOB"""
    <Row align="center">
      <Text
        text={@label}
        font_family="mono"
        text_size={10.5}
        letter_spacing={0.16}
        text_color={Palette.eyebrow()}
        max_lines={1}
      />
      <Spacer size={11} />
    </Row>
    """
  end

  @doc """
  The متن‌باز label: a grey dash, then Persian at the drawing's own recipe.

  See the moduledoc — the dash is grey because orange means new/now, and the
  type is Vazirmatn 11 / 600 / no tracking because the Arabic script has no
  case to upper and the drawing sets Persian tracking to 0.
  """
  @spec eyebrow() :: map()
  def eyebrow do
    assigns = %{label: @copy.eyebrow}

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_left={2} padding_right={2}>
        <Box width={13} height={2} corner_radius={1} background={Palette.rail_idle()} />
        <Spacer size={9} />
        {BookDetailFa.fa(@label, 11, Palette.eyebrow(), weight: "semibold")}
      </Row>
      <Spacer size={11} />
    </Column>
    """
  end

  @doc """
  Kati's own licences: one Persian sentence, then three Latin rows.

  One card rather than `Kati.UI.SettingsList.card/1`'s grouped list, because
  the sentence and the rows are one statement — *this is the licence, and this
  is who it covers* — and the shared card has nowhere to put a paragraph above
  its rows.

  Screen 83's *Full notice list* row is not drawn here. The drawing does not
  have it, and the generated `THIRD_PARTY_NOTICES.md` it opens is English; a
  chevron promising a Persian page that does not exist is worse than no
  chevron.
  """
  @spec open_source_card() :: map()
  def open_source_card do
    list = open_source()
    last = length(list) - 1

    rows =
      list
      |> Enum.with_index()
      |> Enum.map(fn {row, index} ->
        Kati.Screens.AttributionFa.licence_row(row, index != last)
      end)

    intro = Kati.Screens.AttributionFa.para(@copy.open_source, Palette.ink_soft(), 1.85)

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        padding={15}
        shadow={Kati.Theme.shadow_card_soft()}
      >
        {intro}
        <Spacer size={14} />
        {rows}
      </Column>
      <Spacer size={11} />
    </Column>
    """
  end

  @doc """
  One licence row: the name in a fixed 78pt column, then what it covers.

  The column is fixed so the three licence names stack into a rule the eye can
  follow down, which is the only reason a 10.5pt tracked label is legible at
  all. Both halves are Latin in DM Mono and neither takes a `text_align`: the
  root is `rtl`, so start is the right edge and the pair lands against the
  gutter the drawing puts it against, with no alignment stated anywhere.
  """
  @spec licence_row({String.t(), String.t()}, boolean()) :: map()
  def licence_row({licence, covers}, rule?) do
    assigns = %{licence: licence, covers: covers, rule: SettingsList.hairline(rule?)}

    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={11} />
      <Row fill_width={true} align="center">
        <Box width={78}>
          <Text
            text={@licence}
            font_family="mono"
            text_size={10.5}
            letter_spacing={0.14}
            text_color={Palette.eyebrow()}
            max_lines={1}
          />
        </Box>
        <Spacer size={12} />
        <Column weight={1.0}>
          <Text
            text={@covers}
            font_family="mono"
            text_size={12}
            text_color={:on_surface}
            max_lines={1}
          />
        </Column>
      </Row>
      <Spacer size={11} />
      {@rule}
    </Column>
    """
  end

  @doc """
  The cream card: Kati is free, and that is what keeps it inside TMDB's
  non-commercial terms.

  A constraint worth naming rather than hiding, exactly as screen 83 argues —
  it is the reason certain features cannot ship, and a reader who knows that
  can tell a missing feature from a refused one. Cream rather than the dashed
  frame below it because this one is a promise Kati is making, not a note about
  how the page was built.
  """
  @spec non_commercial() :: map()
  def non_commercial do
    body = Kati.Screens.AttributionFa.para(@copy.non_commercial, Palette.cream_body(), 1.85)

    ~MOB"""
    <Column fill_width={true}>
      <Column fill_width={true} background={Palette.cream()} corner_radius={20} padding={16}>
        <Row fill_width={true} align="top">
          {UI.symbol("info", size: 18, color: Palette.gold_icon())}
          <Spacer size={11} />
          <Column weight={1.0}>
            {body}
          </Column>
        </Row>
      </Column>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  The closing note, which states this page's own rule on the page itself.

  `Kati.Components.MishkaPill` through its content slot, with
  `Kati.UI.SettingsList.note/2`'s props — that helper builds its own `Text` and
  so cannot hold Persian, but the component underneath it can, because a
  caller's children carry the caller's font. `Kati.Screens.Fa`'s moduledoc
  names this as the one door every Persian adoption goes through.

  The frame draws solid where the drawing dashes it: `Modifier.border` takes a
  width and a colour and no `PathEffect`, which `Kati.UI.SettingsList`'s
  moduledoc records as the bridge's limit rather than this screen's choice.
  """
  @spec mirror_note() :: map()
  def mirror_note do
    MishkaPill.pill(
      %{
        background: :none,
        corner_radius: 18,
        border_color: Palette.border(),
        border_width: 1.5,
        padding: 15,
        fill_width: true,
        content_align: :top,
        content_fill_width: true,
        leading: UI.symbol("info", size: 17, color: Palette.sub()),
        leading_gap: 11
      },
      [note_para(@copy.mirror)]
    )
  end

  @doc """
  A wrapped Persian paragraph, at the one size the drawing uses for all of them.

  12.5 is pinned rather than passed because every Persian paragraph on this
  page is 12.5 — the card lines, the open-source sentence, the cream card and
  the closing note — and a size that is the same in four places should not be
  spelled four times. `line_height` is the parameter instead, because that is
  what actually moves: 1.8 in the cards and 1.85 in the prose blocks.

  Both beat `Kati.Theme.fa_line_height/0`'s 1.2 on purpose. That constant is
  documented as the default *for the far more common case where the drawing
  says nothing at all*; this drawing says something, so it wins.

  `max_lines` is left unset. These are paragraphs, and the only thing a line
  cap can do to a paragraph is hide the end of it.
  """
  @spec para(String.t(), term(), number()) :: map()
  def para(text, colour, line_height) do
    assigns = %{text: text, colour: colour, line_height: line_height}

    ~MOB"""
    <Text
      text={@text}
      font_family="fa"
      text_size={12.5}
      text_color={@colour}
      line_height={@line_height}
    />
    """
  end

  @doc """
  A quoted notice: English, in English's own direction, in the default family.

  The one `Text` on this screen that must not carry `font_family="fa"`. It is a
  sentence somebody else wrote in Latin script, and Plus Jakarta Sans is the
  face the rest of the app reads it in.

  `text_align="absolute_left"` is the whole of the LTR block — see the
  moduledoc: it is `TextAlign.Left`, which ignores the layout direction, and a
  nested `layout_direction` prop would not have worked because the bridge reads
  that one off the root node only.
  """
  @spec quoted(String.t()) :: map()
  def quoted(text) do
    assigns = %{text: text}

    ~MOB"""
    <Text
      text={@text}
      text_size={12.5}
      line_height={1.6}
      text_color={Palette.ink_soft()}
      text_align="absolute_left"
    />
    """
  end

  # The pill's paragraph carries `weight={1.0}` where `para/3` does not, for the
  # reason `Kati.UI.SettingsList.note/2` records: the component fills its content
  # row and marks the children wrapper weighted, and the text inside that wrapper
  # needs a weight of its own to take the width rather than measure at its
  # natural one. Everywhere else on this page the paragraph is a Column's child,
  # where a weight would be a vertical claim on a Column that has no height to
  # give.
  defp note_para(text) do
    assigns = %{text: text}

    ~MOB"""
    <Text
      text={@text}
      font_family="fa"
      text_size={12.5}
      text_color={Palette.ink_soft()}
      line_height={1.85}
      weight={1.0}
    />
    """
  end

  def handle_info({:tap, :back}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}

  # Every card opens the site it names, through screen 83's own table.
  #
  # The four taps were answered-and-inert until `K-43 open-url` was built: the
  # control was drawn, it was reachable, and what it would open was the
  # platform's browser through a fence that did not exist. It exists now, and
  # the URL comes from `Kati.Screens.Attribution.site_for/1` rather than from a
  # second table here — the source list is the same list, the licence
  # conditions are the same conditions, and a Persian page pointing somewhere
  # else would be a licence problem rather than a copy one.
  #
  # The refusal is drawn in ENGLISH, and that is not an oversight: no board
  # writes a Persian failure line and `Kati.Native.Links.message/1` answers in
  # one language, which is `D-60`'s subject. An English sentence a reader can
  # act on beats a silence they cannot.
  def handle_info({:tap, tag}, socket) when is_atom(tag) do
    case Kati.Screens.Attribution.site_for(tag) do
      nil -> {:noreply, socket}
      url -> {:noreply, Kati.Screens.Attribution.follow(socket, url)}
    end
  end

  def handle_info({:tap, _tag}, socket), do: {:noreply, socket}
  def handle_info(_message, socket), do: {:noreply, socket}
end
