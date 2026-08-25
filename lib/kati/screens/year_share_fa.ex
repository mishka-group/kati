defmodule Kati.Screens.YearShareFa do
  @moduledoc """
  Screen 103 — سال شما، هم‌رسان, the Persian share sheet, pushed under آمار.

  Screen 98's page in the mirror, and the third board built on that page after
  98 itself and `Kati.Screens.YearShareBooks`. The caption pins three
  consequences and one rule, and none of the four is a translation.

  ## The three consequences, and why none of them could be folded out of 98

  > the year is **۱۴۰۵** not 2026, the range reads **فروردین تا مرداد**, and the
  > percent sign is **U+066A** (۱۸٪).

  `Kati.I18n.Digits.to_persian/1` would turn `2026` into `۲۰۲۶` — the right
  glyphs for the wrong year — and there is no folding at all that turns
  `JAN – AUG` into a Shamsi month or `%` into `٪`. A calendar is not a numeral
  map and a numeral map is not a script. So this screen reads
  `Kati.Fa.SampleYear`, which was written for screen 61 and already carries all
  three: `range` is `فروردین تا مرداد ۱۴۰۵`, `change` is `۱۸٪` with U+066A, and
  `title`, `weeks` and `breakdown` are the same figures 61 draws. Two Persian
  boards that disagreed about which year it is would be two apps.

  `۱۸٪` is the one caption literal this board does not print, and it is a
  consequence of what the drawing previews rather than a gap: the change sits on
  the **hours** face, and 103 previews the field face and the breakdown face.
  It is on screen 61, one push away, in the hero's green lozenge.

  ## The pixel field and the bars are screen 61's, called rather than copied

  > The pixel field starts top-right and the bars fill from the right, per 61.

  Both are `Kati.Screens.StatsFa`'s own builders, unchanged.
  `Kati.Screens.StatsFa.field/0` chunks `Kati.Fa.SampleYear.contributions/0`
  into rows and lets `Kati.Screens.Fa.pushed_frame/1`'s `rtl` root seat the
  first day at the right; `Kati.Screens.StatsFa.bar/2` builds each track with
  the fill as its **first** child, so the bar grows from the leading edge, which
  under `rtl` is the right. That is the drawing's `float:right` and it needs no
  branch. Neither function reverses a list, and reusing them is the point: a
  second field and a second bar row written here would be a second answer to a
  question 61 has already answered, and the two would drift.

  The field measures 27 cells at 8 on a 4pt gap — 320 — inside a card whose
  inner width is 331 at this frame's gutters and padding. It fits for the same
  reason it fits on 61, which is where that arithmetic is written down.

  ## The carousel, the pager and the two faces

  Both artboards draw two 252pt cards side by side with the second at half
  opacity, over four dots. Screen 98 collapsed that into one full-width card
  holding both faces and `Kati.Screens.YearShareBooks` followed it, with the
  reason that applies here word for word: four dots over one card would be a
  pager pointing at three cards this screen does not have.
  `Kati.Stats.ShareSample.faces/0` names four faces and screen 100 is the board
  that draws all four.

  So the pager is gone and the carousel is one card. What the card holds is the
  drawing's choice and not 98's: 103 previews **سال شما** and **ساعت‌ها کجا
  رفتند** where 98 previews the hours and the top titles. That is a decision
  about which two of the four to show, not a second card template — the frame
  around them is 98's `card/0`, number for number.

  The wordmark obeys 98's rule rather than breaking it: *only the field card
  carries the wordmark, because it is the one people ask about, so it is the one
  that answers.* The field face here carries `Kati` and the breakdown face
  carries none.

  ## Where 103 and screen 98 disagree about a number, 98 wins

  `Kati.Screens.YearShareBooks` settled this for a sibling board of the same
  page — *a state that redrew its own template would report a difference the app
  does not have* — and a mirror is in exactly that position. So the card is
  radius 22 at 19 of padding under `Kati.Theme.shadow_card/0`, the face label is
  `Kati.Theme.Palette.muted/0` where both drawings say `#A0998F`, the primary
  button is 52 at radius 26 with no shadow where both drawings draw 54 at 27
  with one, and the switch opens **off** and the scope opens on `همه` where the
  drawing lights `نمایش`. `mount/3` gets those three opening positions by
  calling `Kati.Screens.YearShare.load/1` itself, so they cannot drift.

  The words are the other way round, and that is the whole reason this file
  exists.

  ## What could not be called, and it is every `Text`

  Plus Jakarta Sans carries no Arabic-script glyphs at all, so a Persian label
  handed to a builder that makes its own `Text` is a row of empty boxes rather
  than a fallback — `Kati.Screens.Fa`'s moduledoc checked the font. That rules
  out every builder on 98 that carries a word, and both of the vendored controls
  it reaches for:

    * **`Kati.UI.chip/2`** paints its label from a prop and
      `Kati.Components.MishkaChip.expand/3` discards children, so the scope
      chips are `Kati.Screens.BookDetailFa.chip/3` — screen 69's hand-rolled
      chip at `Kati.UI.chip/2`'s own geometry, 32 tall at radius 16 with 15 of
      side padding and a 12pt label. The horizontal `Scroll` around them is 98's.
    * **`Kati.UI.Segmented.plain/2`** says in as many words that the label is a
      prop rather than the slot's children because the control paints it, so
      `aspect/1` restates its trough and its two tiles here. Same reason, same
      numbers.
    * **`Kati.UI.eyebrow/2`** uppercases and tracks mono, and the Arabic script
      has no case. `Kati.Screens.StatsFa.quiet_eyebrow/1` is the Persian recipe
      — Vazirmatn 11 at 600 with no tracking — and it carries the grey dash both
      drawings give this section. Orange means new or now in this design and a
      ratio picker is neither; `Kati.UI.eyebrow/2`'s own comment records that
      three Latin screens needed the same escape.
    * **`Kati.UI.SettingsList.note/2`** builds its paragraph as an unstyled
      `Text`, so the sentence has to be restated whatever frame goes round it —
      and once it is being restated, the frame that gets restated is the one
      both artboards draw. `no_server_note/0` is
      `Kati.Screens.Accessibility.note/1`'s cream recipe with the gold `info`,
      at the drawing's 1.85 leading. Persian sets tall — Vazirmatn's descenders
      run under the line and its diacritics over it — which is why
      `Kati.Screens.BookDetailFa.fa/4`'s fixed 1.4 cannot hold a paragraph, the
      same finding `Kati.Screens.AlbumDetailFa.note/1` records for screen 76.

  Everything text-free is called. `Kati.UI.SettingsList.card/1` holds the
  privacy row directly, and `row/4`, `icon_tile/1`, `trailing/1` and `switch/1`
  reach it through `Kati.Screens.BookDetailFa.row/5`, which is screen 69's
  wrapper around them for exactly this reason: it hands the two `Text` nodes
  back to the caller and takes the rest as it comes.
  `Kati.Screens.BookDetailFa.title/1` is the header at 25 over 12.5, which is
  what 103 draws, and `Kati.Screens.BookDetailFa.chip/3` is the scope chip.

  ## `هم‌رسانی…` lost its badge, and the row is deliberately untapped

  98 sets `WHEN FILE SHARING LANDS` beside it in DM Mono caps. 103 draws the
  label alone, and the reason is the same one that keeps `Kati.UI.eyebrow/2`
  out of this file: that badge is an uppercased Latin mono token and Persian has
  no uppercase to set it in. So the marker goes and the row carries no `on_tap`
  instead — which says the same thing in the idiom
  `Kati.Screens.Stats.share_disc/0` established and 98 quotes: *a disc that
  swallowed a tap silently would be worse than one that plainly does nothing.*
  Kati still has no share-sheet fence; nothing in `native/LEDGER.md` hands a
  file to the platform.

  ## The disc on screen 61 is what pushes this, and it is not wired yet

  `Kati.Screens.StatsFa.header/1` draws `Kati.Screens.Fa.disc("ios_share")`, and
  `disc/2` defaults its tag to `nil`, which `Kati.Components.Event.handler/1`
  maps to no handler at all. So 61's share disc is drawn and inert for exactly
  the reason 07's was before 98 landed. This screen is its destination; making
  it one is a one-line change to 61 rather than anything here.

  ## Three things this board does not reproduce, named rather than papered over

    * **The sixth scope chip.** 98 draws six — `Kati.Stats.ShareSample.scopes/0`
      names `Habits` last — and 103 draws five. `scope_options/0` therefore
      filters `ShareSample.scopes/0` against the Persian labels this drawing
      gives, so the order and the tags stay 98's and the one section with no
      Persian word is simply not offered. Inventing عادت‌ها would put a word on
      screen that nobody has read.
    * **`هیجان`.** The drawing's second bar is `هیجان` where
      `Kati.Fa.SampleYear.breakdown/0` says `هیجان‌انگیز`. The drawing's label
      gutter is 70pt inside a 252pt preview and this card is full width, so the
      short form was a fit rather than a second name for the genre. 61's name
      wins; two charts in one app that disagreed about a genre would be two
      charts.
    * **The bold run in the note.** The artboard sets *کاتی سروری ندارد که آن را
      دریافت کند* at 600 in ink inside a 12.5pt paragraph. A Mob `Text` carries
      one weight and one colour for the whole run, so the sentence is drawn flat
      — which is what 98 did with the same emphasis on its own artboard.

  ## The one destination that leaves Persian

  `ذخیره تصویر` goes to `Kati.Screens.YearCards`, screen 100, which is English.
  That is the debt `Kati.Screens.AlbumDetailFa` already carries against
  `Kati.Screens.Rating`, and `Kati.Screens.Fa`'s moduledoc names its cost: a
  push that changes the app's language out from under the reader, and RTL with
  it. It is taken here rather than dropped because 100 is the render spec for
  the aspect this page's segmented control picks, and a save button that saved
  nothing would be worse than one that lands on an English sheet.
  """

  use Mob.Screen
  import Mob.Sigil

  alias Kati.Fa.SampleYear
  alias Kati.Screens.BookDetailFa
  alias Kati.Screens.Fa
  alias Kati.Screens.StatsFa
  alias Kati.Screens.YearShare
  alias Kati.Stats.ShareSample
  alias Kati.Theme
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  # Everything 103 prints that is a WORD this screen adds. The year, the range,
  # the field label, the breakdown label and every figure in the chart come from
  # `Kati.Fa.SampleYear` instead, because 61 draws them too and one of the two
  # boards would otherwise start telling a different year.
  @drawn %{
    back: "آمار",
    title: "سال شما، هم‌رسان",
    year: "۱۴۰۵",
    aspect: "نسبت تصویر",
    privacy: "عنوان‌های خصوصی پنهان شوند",
    save: "ذخیره تصویر",
    share: "هم‌رسانی…",
    wordmark: "Kati",
    note:
      "همه کارت‌ها روی همین دستگاه ساخته می‌شوند. هیچ چیزی از سال شما جایی " <>
        "فرستاده نمی‌شود — کاتی سروری ندارد که آن را دریافت کند."
  }

  # Keyed by 98's own scope string rather than listed in order, so the order and
  # the `scope_…` tags come from `Kati.Stats.ShareSample.scopes/0` and only the
  # words are this file's. `Habits` is absent on purpose — see the moduledoc.
  @scope_labels %{
    "All" => "همه",
    "Screen" => "نمایش",
    "Books" => "کتاب",
    "Music" => "موسیقی",
    "Meals" => "وعده"
  }

  # Keyed by 98's tag for the same reason, and with `Map.fetch!/2` behind it in
  # `aspect_options/0`: a third ratio added to 98 should stop this screen loudly
  # rather than draw an English segment in a Persian trough.
  @aspect_labels %{aspect_square: "مربع", aspect_story: "استوری"}

  # The tags `Kati.Screens.YearShare.handle_tap/2` answers that mean the same
  # thing in both languages. Listed rather than caught, so a control added to
  # 98's markup arrives here as an unanswered tag instead of a delegation that
  # quietly does the wrong thing.
  @borrowed [:toggle_private, :save_image, :aspect_square, :aspect_story]

  @doc """
  The three opening positions, taken from screen 98 rather than restated.

  Which position a control opens in belongs to the screen, and this is the same
  screen in another language: `Kati.Screens.YearShare.load/1` sets the scope to
  `All`, the ratio to square and the privacy switch to off. All three differ
  from what 103 draws — the drawing lights `نمایش` and shows the switch on — and
  `Kati.Screens.YearShareBooks` already settled that a variant board which
  changed a default would be claiming the variant had changed one.
  """
  @spec mount(map(), map(), Mob.Socket.t()) :: {:ok, Mob.Socket.t()}
  def mount(_params, _session, socket) do
    Kati.Theme.activate()
    {:ok, YearShare.load(socket)}
  end

  @doc """
  The page inside a root node that declares `rtl`.

  `Kati.Screens.Pushed` cannot be used for two independent reasons, and
  `Kati.Screens.BookDetailFa` records both: `chrome/2` takes its direction from
  `Kati.Locale`, which answers for the app's setting rather than for this
  screen, and the bridge reads `layout_direction` from the root node only — so a
  Persian mirror rendered while the app is set to English would draw Persian
  copy in a left-to-right grid, which is the one thing these boards exist to
  disprove. `Kati.Screens.Fa.pushed_frame/1` is that root and nothing else.
  """
  @spec render(map()) :: map()
  def render(assigns), do: Fa.pushed_frame(content(assigns), Kati.Screens.Identity.of(__MODULE__))

  @doc """
  The page, in the order 103 stacks it — which is 98's order with the pager
  removed.

  The three 16pt spacers between the ratio picker, the switch, the actions and
  the note are 98's `content/1`'s own, so the two pages breathe the same.
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
        {Kati.Screens.YearShareFa.chrome()}
        {Kati.Screens.YearShareFa.header()}
        {Kati.Screens.YearShareFa.scope_chips(assigns.scope)}
        {Kati.Screens.YearShareFa.card()}
        {Kati.Screens.StatsFa.quiet_eyebrow(Kati.Screens.YearShareFa.drawn().aspect)}
        {Kati.Screens.YearShareFa.aspect(assigns.aspect)}
        <Spacer size={16} />
        {Kati.Screens.YearShareFa.privacy_row(assigns.hide_private)}
        <Spacer size={16} />
        {Kati.Screens.YearShareFa.actions()}
        <Spacer size={16} />
        {Kati.Screens.YearShareFa.no_server_note()}
      </Column>
    </Scroll>
    """
  end

  @doc """
  The Persian copy this screen adds to screen 61's figures.

  Exposed rather than kept private because the strings are the deliverable: a
  native reader correcting one corrects it here, once, and every call site
  follows. Screen 72's caption states the standing rule for all of it — *these
  strings are proposals*.
  """
  @spec drawn() :: map()
  def drawn, do: @drawn

  @doc """
  The scope chips 103 offers, in 98's order and under 98's tags.

  Built by filtering `Kati.Stats.ShareSample.scopes/0` rather than by listing
  five strings, so the order, the spelling of each tag and any section 98 adds
  all arrive from one place. `Habits` falls out because the drawing gives it no
  Persian label; see the moduledoc for why that is left as a gap.
  """
  @spec scope_options() :: [{String.t(), String.t()}]
  def scope_options do
    ShareSample.scopes()
    |> Enum.filter(&Map.has_key?(@scope_labels, &1))
    |> Enum.map(&{&1, Map.fetch!(@scope_labels, &1)})
  end

  @doc """
  The two ratios, in 98's order and under 98's tags.

  `Map.fetch!/2` rather than `Map.get/3`: a ratio added to
  `Kati.Screens.YearShare.aspects/0` with no Persian word for it should raise
  where the omission is, not draw `Story` inside a Persian trough where nobody
  would read it as a bug.
  """
  @spec aspect_options() :: [{atom(), String.t()}]
  def aspect_options do
    Enum.map(YearShare.aspects(), fn {_label, tag} ->
      {tag, Map.fetch!(@aspect_labels, tag)}
    end)
  end

  @doc """
  The back pill, with the chevron pointing the way the reader came from.

  `arrow_forward_ios`, because back is the right edge in Persian — the commonest
  RTL bug there is. `Kati.Screens.BookDetailFa.chrome/0` draws the identical
  pill and could not be called only because its label is frozen to کتابخانه;
  `Kati.Screens.ArtistDetailFa.chrome/0` restates it for the same reason. All
  three numbers are the same: 44 at radius 22, 12 of padding at the chevron and
  16 at the label, on `Kati.Theme.shadow_button/0`.

  The pill pops the stack rather than routing, so naming آمار on it costs
  nothing even though screen 61 is a root the reader may not have come through.
  """
  @spec chrome() :: map()
  def chrome do
    label = @drawn.back

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
          {BookDetailFa.fa(label, 13.5, :on_surface, weight: "semibold")}
        </Row>
        <Spacer weight={1.0} />
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc """
  The title over the range.

  `Kati.Screens.BookDetailFa.title/1` unchanged — 25 bold over 12.5 muted with
  the 20pt gap under it, which is what 103 draws and what screen 69 and screen
  76 already draw. The range is `Kati.Fa.SampleYear`'s, not a formatted date:
  فروردین تا مرداد ۱۴۰۵ is a Shamsi span and nothing in this app converts one.
  """
  @spec header() :: map()
  def header do
    BookDetailFa.title(%{title: @drawn.title, author: SampleYear.year().range})
  end

  @doc """
  The scope chips, in 98's horizontal scroll.

  `Kati.Screens.BookDetailFa.chip/3` rather than `Kati.UI.chip/2` — see the
  moduledoc — and the tag it builds is `scope_All`, `scope_Screen` and so on,
  which is exactly what `Kati.Screens.YearShare.handle_tap/2` already answers.
  The chips are wired for that reason and not as decoration: the tags cross the
  language boundary unchanged because they are tags rather than words.

  The `Scroll` is 98's own. Five Persian chips fit this frame today, but a `Row`
  clips what it cannot hold and a sixth label — or a longer word from a reader
  correcting one of these five — would silently lose a section.
  """
  @spec scope_chips(String.t()) :: map()
  def scope_chips(active) do
    chips =
      scope_options()
      |> Enum.map(fn {scope, label} ->
        BookDetailFa.chip(label, scope == active, "scope_" <> scope)
      end)
      |> Enum.intersperse(~MOB"<Spacer size={7} />")

    ~MOB"""
    <Column fill_width={true}>
      <Scroll axis="horizontal">
        <Row>
          {chips}
        </Row>
      </Scroll>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc """
  The card preview: the field face over the breakdown face, in one frame.

  One card and not a carousel, for `Kati.Screens.YearShareBooks`' reason — see
  the moduledoc. Every number in the frame is screen 98's `card/0`: radius 22,
  19 of padding, `Kati.Theme.shadow_card/0`, and the 20pt gap between the two
  faces. They are restated rather than called because `card/0` takes no
  arguments and reads `Kati.Stats.ShareSample` directly, which is the same
  reason screen 99 restates them. If the three ever disagree it is a bug on this
  side, and the fix is a `card/1` on 98 that takes a face.
  """
  @spec card() :: map()
  def card do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        padding={19}
        shadow={Theme.shadow_card()}
      >
        {Kati.Screens.YearShareFa.field_face()}
        <Spacer size={20} />
        {Kati.Screens.YearShareFa.breakdown_face()}
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  One face label, in the Persian eyebrow's recipe.

  Vazirmatn 11 at 600 with no tracking, where 98 sets DM Mono 10 uppercase at
  .14em: the Arabic script has no case to upper and tracking a joined script
  breaks the joins between its letters, which is why every Persian line in the
  drawings carries `letter-spacing:0`. The colour is `Kati.Theme.Palette.muted/0`
  where both artboards write `#A0998F` — screen 99 settled that one for all four
  faces and this follows it rather than reopening it.
  """
  @spec face_label(String.t()) :: map()
  def face_label(label) do
    BookDetailFa.fa(label, 11, Palette.muted(), weight: "semibold")
  end

  @doc """
  The field face: سال شما over the year as pixels, then the span and the
  wordmark.

  `Kati.Screens.StatsFa.field/0` verbatim. It contains no text at all, which is
  the only reason a Persian screen can adopt a builder whole — the font rule
  that keeps this file away from most of `Kati.Components` never bites on a grid
  of coloured boxes — and under the `rtl` root each `Row` starts at the right,
  so the year begins in the top-right corner as the caption asks.

  This is the one face that carries `Kati`, which is screen 98's rule kept
  rather than broken: the field is the card people ask about, so it is the one
  that answers. The wordmark stays Latin and stays in DM Mono — it is a name,
  not a sentence, and `kati_mono.ttf` has every glyph in it.
  """
  @spec field_face() :: map()
  def field_face do
    year = SampleYear.year()

    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.YearShareFa.face_label(year.title)}
      <Spacer size={11} />
      {Kati.Screens.StatsFa.field()}
      <Spacer size={13} />
      <Row fill_width={true} align="center">
        {Kati.Screens.BookDetailFa.fa(year.weeks, 10, Kati.Theme.Palette.muted())}
        <Spacer weight={1.0} />
        <Box width={9} height={9} corner_radius={5} background={Kati.Theme.Palette.ink()} />
        <Spacer size={6} />
        <Text
          text={Kati.Screens.YearShareFa.drawn().wordmark}
          font_family="mono"
          text_size={10.5}
          text_color={Kati.Theme.Palette.sub()}
          max_lines={1}
        />
      </Row>
    </Column>
    """
  end

  @doc """
  The breakdown face: ساعت‌ها کجا رفتند over four bars, with the year under them.

  Every bar is `Kati.Screens.StatsFa.bar/2` with `Kati.Fa.SampleYear.breakdown/0`
  behind it, so this chart and screen 61's chart are the same chart — same four
  tones, same 76pt label gutter, same `absolute_left` count column, and the same
  fill growing from the right because it is the track's first child. Screen 79
  makes the same call for the same reason and its moduledoc carries the tone
  ramp's one eighteen-unit compromise.

  The 12pt gap under the label is `Kati.Screens.YearCards.face/2`'s for this
  face, not a number of this file's own.
  """
  @spec breakdown_face() :: map()
  def breakdown_face do
    year = SampleYear.year()
    last = length(year.breakdown) - 1

    bars =
      year.breakdown
      |> Enum.with_index()
      |> Enum.map(fn {bar, index} -> StatsFa.bar(bar, index < last) end)

    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.YearShareFa.face_label(year.breakdown_label)}
      <Spacer size={12} />
      {bars}
      <Spacer size={16} />
      {Kati.Screens.YearShareFa.watermark()}
    </Column>
    """
  end

  @doc """
  The year at the card's foot, as a mark rather than a figure.

  Two notes on it, and both are about a token being wrong in a chosen direction.

  The colour: the drawing writes `#D6D0C7`, which no token in
  `Kati.Theme.Palette` carries. `bar_neutral` is two units off it and is one of
  the three tokens the palette places on the drawing's **inert-fill** ladder
  rather than its text ladder — which is what a watermark needs, because a
  neutral that followed the text ladder into dark would come back as a number
  somebody is meant to read. `muted`, the nearest text step, is exactly that.

  The face: `Kati.Screens.Fa`'s second type rule settles it — *Persian digits
  cannot go in the mono face.* `kati_mono.ttf` carries **zero** of U+06F0–U+06F9,
  re-checked against its `cmap` this round, and `MobBridge.kt:4769` builds
  `katiMono` from that one file, so nothing sits behind it: ۱۴۰۵ set in mono is
  four blank boxes on the device, not a substituted run. The artboard's
  `font-family:'DM Mono',monospace` reads correctly on the page only because a
  browser falls through to the system monospace, which the bridge has no
  equivalent of. So the watermark is Vazirmatn at the drawing's 22 and 500 — the
  face is wrong and the glyphs are right, which is the trade `Kati.Screens.Fa`
  already made for every mono figure on the Persian mirrors.

  That does leave the four bar counts eleven points above it in mono, because
  they are `Kati.Screens.StatsFa.bar/2`'s and screen 61 draws them that way. One
  card face giving two answers to one question is the smaller bug of the two, and
  the fix belongs on 61 rather than here. No `letter_spacing` either way: the
  drawing's -.03em tracks a joined script, and every Persian line in these
  drawings sets tracking to zero for that reason.
  """
  @spec watermark() :: map()
  def watermark do
    ~MOB"""
    <Text
      text={Kati.Screens.YearShareFa.drawn().year}
      font_family="fa"
      text_size={22}
      font_weight="medium"
      text_color={Kati.Theme.Palette.bar_neutral()}
      max_lines={1}
    />
    """
  end

  @doc """
  The ratio picker: `Kati.UI.Segmented.plain/2`'s trough with Persian tiles in
  it.

  Restated rather than called because that control paints its own label — its
  moduledoc says so outright — and a Persian label through a prop is a row of
  empty boxes. Everything else is its: a `placeholder` trough at radius 16 with
  4 of padding, 34pt tiles at radius 12, a 4pt gap, and the 12.5pt label.
  """
  @spec aspect(atom()) :: map()
  def aspect(selected) do
    segments =
      aspect_options()
      |> Enum.map(fn {tag, label} ->
        Kati.Screens.YearShareFa.segment(label, tag, tag == selected)
      end)
      |> Enum.intersperse(~MOB"<Spacer size={4} />")

    ~MOB"""
    <Row
      fill_width={true}
      background={Palette.placeholder()}
      corner_radius={16}
      padding={4}
      align="center"
    >
      {segments}
    </Row>
    """
  end

  @doc """
  One segment, raised or not.

  Two clauses rather than one with conditional props, for the reason
  `Kati.UI.Segmented` gives: the raised tile is *defined* by its shadow, and a
  nil shadow prop flattens it into the trough rather than omitting a decoration.

  The shadow is written out because `Kati.Theme` has no recipe for a 2pt lift at
  6% and the palette has no API for the inside of a shadow string —
  `Kati.Screens.YearShareBooks.cover/2` states a shadow the same way and for the
  same reason. The value is `Kati.UI.Segmented`'s own, so the two controls lift
  by the same amount.
  """
  @spec segment(String.t(), atom(), boolean()) :: map()
  def segment(label, tag, true) do
    tap = {self(), tag}

    ~MOB"""
    <Box weight={1.0} on_tap={tap}>
      <Row
        fill_width={true}
        height={34}
        corner_radius={12}
        background={Palette.card()}
        shadow="0 1 2 0 #0F1A1917"
        align="center"
      >
        <Spacer weight={1.0} />
        {BookDetailFa.fa(label, 12.5, :on_surface, weight: "bold")}
        <Spacer weight={1.0} />
      </Row>
    </Box>
    """
  end

  def segment(label, tag, false) do
    tap = {self(), tag}

    ~MOB"""
    <Box weight={1.0} on_tap={tap}>
      <Row fill_width={true} height={34} align="center">
        <Spacer weight={1.0} />
        {BookDetailFa.fa(label, 12.5, Palette.segment_idle(), weight: "semibold")}
        <Spacer weight={1.0} />
      </Row>
    </Box>
    """
  end

  @doc """
  The one privacy control on the page.

  A switch rather than a chip, which is 98's reasoning kept: it changes what is
  *in* the card rather than what the card is about, and a control that looked
  like the five above it would be read as a sixth scope.

  `Kati.Screens.BookDetailFa.row/5` inside `Kati.UI.SettingsList.card/1` — the
  same route screen 69's *owned* row takes. Everything geometric is
  `Kati.UI.SettingsList`'s: the 30pt paper tile, the 13pt padding, the hairline
  and the switch. Only the title is this file's, because only the title is
  Persian.
  """
  @spec privacy_row(boolean()) :: map()
  def privacy_row(on?) do
    SettingsList.card([
      BookDetailFa.row(@drawn.privacy, nil, nil, "visibility_off",
        trailing: SettingsList.switch(on?),
        on_tap: {self(), :toggle_private}
      )
    ])
  end

  @doc """
  Save, and the share that is waiting on a fence.

  `ذخیره تصویر` takes the ink because it is the one that works, at screen 98's
  52 by radius 26. `هم‌رسانی…` carries no badge and no `on_tap` — see the
  moduledoc for why the Latin marker could not come across and why an untapped
  control says the same thing.
  """
  @spec actions() :: map()
  def actions do
    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        height={52}
        corner_radius={26}
        background={Palette.ink_fill()}
        align="center"
        on_tap={{self(), :save_image}}
      >
        <Spacer weight={1.0} />
        {BookDetailFa.fa(Kati.Screens.YearShareFa.drawn().save, 15, Palette.on_ink(), weight: "bold")}
        <Spacer weight={1.0} />
      </Row>
      <Spacer size={11} />
      <Row fill_width={true} align="center">
        <Spacer weight={1.0} />
        {BookDetailFa.fa(Kati.Screens.YearShareFa.drawn().share, 13.5, Palette.ink_soft(),
          weight: "semibold"
        )}
        <Spacer weight={1.0} />
      </Row>
    </Column>
    """
  end

  @doc """
  The sentence whose second clause is the proof rather than the reassurance.

  **کاتی سروری ندارد که آن را دریافت کند** — Kati has no server that could
  receive it. Every card is composed on the device, which is not a policy the
  app is keeping but the only thing the architecture permits, and that is why
  the clause is stated as a fact about the system rather than as a promise about
  its conduct.

  Hand-rolled on `Kati.Screens.Accessibility.note/1`'s cream recipe rather than
  `Kati.UI.SettingsList.note/2`'s frame, and the paragraph is a bare `Text`
  rather than `Kati.Screens.BookDetailFa.fa/4`, because that helper fixes
  `line_height` at 1.4 and this paragraph is set at **1.85**. Persian sets tall —
  Vazirmatn's descenders run under the line and its diacritics over it — so a
  Persian paragraph at a Latin paragraph's leading collides with itself. Screen
  76's note records the same finding at 1.9.
  """
  @spec no_server_note() :: map()
  def no_server_note do
    note = @drawn.note

    ~MOB"""
    <Row fill_width={true} background={Palette.cream()} corner_radius={20} padding={16} align="top">
      {UI.symbol("info", size: 18, color: Palette.gold_icon())}
      <Spacer size={11} />
      <Text
        text={note}
        font_family="fa"
        text_size={12.5}
        line_height={1.85}
        text_color={Palette.cream_body()}
        weight={1.0}
      />
    </Row>
    """
  end

  @doc """
  Every tap on the page, answered by screen 98 wherever the answer is the same
  in both languages.

  The switch, the two ratios, `Save image` and all five scope chips go to
  `Kati.Screens.YearShare.handle_tap/2` unchanged — two boards of one screen that
  disagreed about what a control does would be two screens. `@borrowed` lists
  the four rather than catching them so a fifth control added to 98's markup
  arrives here unanswered instead of being delegated blindly.

  An unrecognised tag leaves the screen as it was rather than raising, which is
  what `Kati.Screens.BookDetailFa` and `Kati.Screens.AlbumDetailFa` both do: Mob
  does not catch a raise in a tap handler.
  """
  @spec handle_info(term(), Mob.Socket.t()) :: {:noreply, Mob.Socket.t()}
  def handle_info({:tap, :back}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}

  def handle_info({:tap, tag}, socket) when tag in @borrowed,
    do: YearShare.handle_tap(tag, socket)

  def handle_info({:tap, tag}, socket) when is_atom(tag) do
    case Atom.to_string(tag) do
      "scope_" <> _section -> YearShare.handle_tap(tag, socket)
      _other -> {:noreply, socket}
    end
  end

  def handle_info(_message, socket), do: {:noreply, socket}
end
