defmodule Kati.Screens.GoalsFa do
  @moduledoc """
  Screen 108 — اهداف, the Persian goals page, pushed under آمار.

  Screen 104 in the mirror. The caption pins four things, and only three of
  them are about pixels.

  ## The one that is not visual: a «سالانه» goal ends at the end of اسفند

  This is the whole i18n consequence of the screen and it is a *domain* fact
  rather than a translation. `Kati.Goals.Goal` keeps `starts_on` and `ends_on`
  as plain `Date`s and `Kati.Goals.Goal.title/1` composes the phrase *this
  year* from `period`, so a yearly goal created today runs to 31 December
  whatever language it is read in. Screen 108 answers by *saying so*: the cream
  `info` card at the foot of the page is the one thing 108 draws that 104 does
  not, and it exists to state that a Persian year closes at the end of اسفند
  and that the periods follow the Shamsi calendar.

  Saying it is all a screen can do. Making it true means a Shamsi
  `period_phrase/1` and a Shamsi roll-forward for `repeat`, and both belong in
  `Kati.Goals` beside the dates they shape — the same boundary
  `Kati.Screens.AlbumDetailFa` drew when it left two Shamsi dates undone rather
  than shaping a date on a screen. Until that lands, the note is honest and the
  arithmetic underneath it is not, and that is named here instead of being
  papered over with a translated month name.

  ## The hero numerals are not DM Mono, and the column still aligns

  The caption asks for `۳۸ / ۵۲` to stay in the mono face. It cannot:
  `Kati.Screens.Fa`'s moduledoc parsed the shipped subset and `kati_mono.ttf`
  carries **none** of U+06F0–U+06F9, so a Persian numeral in mono is a blank
  box rather than a fallback. The standing trade applies — set in `fa` at the
  design's size and colour, the face wrong and the glyphs right.

  What the caption is actually protecting survives the trade. The three hero
  figures line up down the page because they all start at the card's own
  padding, which is layout and not advance width. What is lost is the tabular
  tick *inside* one figure as it counts up, and that comes back the day the
  mono subset is regenerated with the Persian digits in it.

  ## Two things mirror for free, and nothing here reverses a list

    * **The bar fills from the right.** It is the same
      `Kati.Components.MishkaProgress.progress(render: :box, …)` call screens 69
      and 104 make, and that component lays its fill out as a `Row`.
      `Kati.Screens.Fa.pushed_frame/1` declares `rtl` on the root and the bridge
      reads `layout_direction` from the root node only, so start becomes the
      right edge for every `Row` under it.
    * **The sparkline starts top-right.** Same mechanism, one level up:
      `field/1` chunks the cells into explicit rows because a `Row` does not
      wrap, and each of those rows begins at the right.

  ## The sparkline is the bar, spelled cell by cell

  Both frames draw thirty-four cells and fill 25, 34 and 24 of them — which is
  73%, 100% and 70%, the three bar widths on the same three cards. So the field
  is **derived** from `fraction` here rather than stored: `field/1` takes the
  goal's own fraction and lights that many cells of one shared ramp. A field
  that disagreed with the bar six inches above it would be the worst kind of
  chart, and now it cannot.

  ## Nothing on this page is the user's own words

  Unlike screens 69 and 76, this mirror never has to decide what not to
  translate. A goal is a `kind`, a `target` and a `period`;
  `Kati.Goals.Goal.title/1` composes *52 books this year* out of the three and
  `Kati.Goals.Goal.counts/1` supplies the footnote from the kind alone. The
  whole page is Kati's copy, so translating it means giving the same facts a
  Persian sentence rather than swapping a stored string.

  There is a limit, and it is the reason `goals/0` still branches. The Persian
  copy is keyed by position against the drawing, exactly as
  `Kati.Screens.AlbumDetailFa.tracks/0` keys its titles, and it is applied only
  when `Kati.Screens.Goals.goals/0` answers with the drawing's own three. A
  goal the reader actually stored keeps its English title and English
  projection, because composing a Persian one needs the unit and the period
  phrase in Persian and those live on `Kati.Goals.Goal`, not on a screen. Its
  figures still fold to Persian digits, which is `Kati.Screens.AlbumDetailFa`'s
  answer to the same split: a numeral is not a word.

  ## What this file reuses, and it is most of the page

  From screen 104: `Kati.Screens.Goals.goals/0` reads the goals — one Ash query
  it already owns — so the two pages cannot disagree about the record;
  `Kati.Screens.Goals.drawn_goals/0` is the test for whether the page is the
  drawing; and `Kati.Screens.Goals.projection/1` draws the sentence in the
  branch where it is still English. From the Persian mirrors:
  `Kati.Screens.Fa.pushed_frame/1` for the direction,
  `Kati.Screens.BookDetailFa.fa/4` for every Persian `Text` on the page,
  `Kati.Screens.BookDetailFa.title/1` for the header, and
  `Kati.Screens.AlbumDetailFa.eyebrow/2` for both dashes.

  ## Where the frame and `Kati.Screens.Goals` disagree, and the frame wins

  `Kati.Screens.AlbumDetailFa` set this rule and the reasoning carries: the
  frame is the thing being reproduced, every number below is also in
  `test/design/screens/104.html` — screen 104's own capture, byte for byte
  identical to `pending/104.html` — and the drift is 104's to settle. A mirror
  is not licensed to invent a second goals page, but it is not licensed to
  reproduce a departure from the drawing either.

    * **The add disc is ink.** Both frames fill it `#1A1917` with a `#FBFAF8`
      plus and give it no shadow. `Kati.Screens.Goals.chrome/0` fills it card
      white with the button shadow, which is the inverse.
    * **The pace word is an eyebrow, not a pill.** Both frames put طبق برنامه /
      جلوتر / عقب‌تر on the section dash above the card and leave the card's
      top-left corner empty. `Kati.Screens.Goals.pace_pill/1` draws it inside
      the card instead, which is why nothing here calls it.
    * **Behind is red.** Both frames give the falling pill `#B4553C` on a 14%
      wash. `Kati.Screens.Goals`' moduledoc argues for bronze — *behind on a
      goal is not an error, it is a fact about a Tuesday* — and that is a good
      argument the drawing did not take.
    * **The drift figure sits in a wash.** A 26pt pill at radius 13 in both
      frames; `Kati.Screens.Goals.drift/1` draws a bare row with no ground, at
      a 20pt glyph rather than the drawing's filled 15.
    * **The rail is 2pt on `rail_idle`.** `Kati.Screens.Goals.bar/1` draws 5pt
      on `track`, so it is not reused; the call underneath is the same one.
    * **Every card ends in the field.** `Kati.Screens.Goals.card/1` draws none
      at all.

  Two differences are the drawings' own rather than anybody's drift, and they
  are reproduced rather than reconciled. 104 closes with the Repeat switch and
  the Habits row; **108 draws neither**, so `Kati.Screens.Goals.repeat_group/1`
  and `Kati.Screens.Goals.repeat_row/1` are deliberately not called and this
  screen owns no switch.
  And `Kati.Goals.Goal.counts/1` guarantees a *what counts* sentence for all
  ten kinds, but 104 draws two of the three and **108 draws one** — the books
  card only. The other nine sentences exist and have no Persian yet; that is
  `Kati.Goals`' to give them, for the same reason the title is.
  """

  use Mob.Screen
  import Mob.Sigil

  alias Kati.Components.MishkaActionIcon
  alias Kati.Components.MishkaProgress
  alias Kati.Components.MishkaSeparator
  alias Kati.I18n.Digits
  alias Kati.Music.Sample
  alias Kati.Screens.AlbumDetailFa
  alias Kati.Screens.BookDetailFa
  alias Kati.Screens.Fa
  alias Kati.Screens.Goals
  alias Kati.Theme.Palette
  alias Kati.UI

  # U+066A, the Arabic percent sign. `Kati.I18n.Digits.to_persian/1` maps the
  # digit range and nothing else — its own moduledoc says which separator a
  # number wants is a formatting decision rather than a character map's
  # business — so the screen makes this one, once, exactly as
  # `Kati.Screens.AlbumDetailFa` makes the decimal separator.
  @percent "٪"

  # The page's own chrome: the two lines in the header and the back pill's
  # label. The pill says آمار because 108 is pushed under the Persian stats
  # root, `Kati.Screens.StatsFa`, and not under the English one.
  @chrome %{
    back: "آمار",
    title: "اهداف",
    range: "فروردین تا اسفند ۱۴۰۵"
  }

  # The pace word, by the atom `Kati.Goals.Goal.pace/2` answers with. Derived
  # rather than drawn, because unlike the card titles the pace is not a
  # sentence about a goal the drawing happened to have — it is one of three
  # words and every goal gets one.
  @paces %{on_pace: "طبق برنامه", ahead: "جلوتر", behind: "عقب‌تر"}

  # The drawing's three cards, keyed by position, applied only when the page is
  # showing the drawing — see `goals/0`. The projection is a list of runs
  # because the drawing emphasises the number inside the sentence and
  # `Kati.UI.rich_text/1` takes runs; the numerals are frozen into the copy
  # here rather than folded from the goal, because they are words in a sentence
  # (*۴۸ از ۵۲*) and not the figures the card counts with.
  @copy [
    %{
      title: "۵۲ کتاب در این سال",
      sentence: [
        {"با این روند تا ", :body},
        {"پایان اسفند", :strong},
        {" به ", :body},
        {"۴۸ از ۵۲", :strong},
        {" می‌رسید.", :body}
      ],
      counts: "فقط کتاب‌های تمام‌شده شمرده می‌شوند."
    },
    %{
      title: "۶۰۰ دقیقه مطالعه در ماه",
      sentence: [
        {"از هدف گذشته‌اید، با ", :body},
        {"۹ روز", :strong},
        {" باقی‌مانده از مرداد.", :body}
      ],
      counts: nil
    },
    %{
      title: "۱۲۰ فیلم در این سال",
      sentence: [
        {"با این روند به ", :body},
        {"۱۰۶ از ۱۲۰", :strong},
        {" می‌رسید.", :body}
      ],
      counts: nil
    }
  ]

  # The cream card at the foot of the page — the one thing 108 draws that 104
  # does not. See the moduledoc: it states the Shamsi period boundary that the
  # domain underneath does not yet honour.
  @note [
    {"یک هدف «سالانه» در پایان ", :body},
    {"اسفند", :strong},
    {" تمام می‌شود، نه ۳۱ دسامبر. دوره‌ها از تقویم شمسی پیروی می‌کنند.", :body}
  ]

  # The thirty-four steps of the sparkline, as ramp indices rather than
  # colours. Both frames draw this same sequence on all three cards and stop it
  # at a different cell, which is the finding `field/1` is built on.
  @field [
    3,
    3,
    3,
    2,
    2,
    2,
    0,
    1,
    2,
    4,
    2,
    4,
    0,
    4,
    3,
    2,
    4,
    1,
    4,
    4,
    3,
    2,
    3,
    3,
    1,
    0,
    4,
    0,
    2,
    3,
    1,
    0,
    3,
    0
  ]

  # Thirty-two cells to the row, which is what fits: the card is 402 wide less
  # the page's 21 either side and its own 17 either side, so 326pt of content,
  # and a 7pt cell on a 3pt gap costs 10n - 3. Thirty-three would be 327. The
  # drawing's `flex-wrap` lands on the same split; a `Row` cannot wrap, so the
  # count is declared instead of measured.
  @per_row 32

  @doc false
  def mount(_params, _session, socket) do
    Kati.Theme.activate()
    {:ok, Mob.Socket.assign(socket, :goals, goals())}
  end

  @doc false
  def render(assigns), do: Fa.pushed_frame(content(assigns), Kati.Screens.Identity.of(__MODULE__))

  @doc """
  The goals on the page: screen 104's, with the Persian half added.

  `Kati.Screens.Goals.goals/0` does the reading, so the two pages read one set
  of goals and cannot disagree about a target. What this adds is the language:
  a pace word, Persian figures, and — only when the list *is*
  `Kati.Screens.Goals.drawn_goals/0` — the drawing's Persian titles and
  sentences. The equality test is the whole branch, and it is reliable because
  both functions answer with `Kati.Goals.Sample.goals/0` when nothing is
  stored, so the two are the same term exactly when the page is the drawing.
  """
  @spec goals() :: [map()]
  def goals do
    live = Goals.goals()
    words = if live == Goals.drawn_goals(), do: @copy, else: []

    live
    |> Enum.with_index()
    |> Enum.map(fn {goal, index} -> shaped(goal, Enum.at(words, index)) end)
  end

  @doc """
  One goal as the card wants it: the record, plus the four fields that are
  Persian whether or not the words are.

  `words` is the drawing's copy for this position, or `nil` for a goal the
  reader stored. The figures fold either way — a numeral is not a word, and a
  Persian page that printed `38` under a Persian header would read as a bug
  rather than as a fallback.
  """
  @spec shaped(map(), map() | nil) :: map()
  def shaped(goal, words) do
    Map.merge(goal, %{
      words: words,
      pace_label: pace_label(goal.pace),
      figure: Digits.to_persian(goal.progress),
      of: "/ " <> Digits.to_persian(goal.target),
      drift: persian_percent(goal.drift)
    })
  end

  @doc """
  The pace word for one of `Kati.Goals.Goal.pace/2`'s three answers.

  Falls back to طبق برنامه rather than raising, because this runs inside a
  render and an unknown pace should cost the reader a slightly wrong word, not
  a blank screen.
  """
  @spec pace_label(atom()) :: String.t()
  def pace_label(pace), do: Map.get(@paces, pace, @paces.on_pace)

  @doc "The drawing's Persian copy, unconditionally — the three cards in the order 108 stacks them."
  @spec drawn_copy() :: [map()]
  def drawn_copy, do: @copy

  # `"23%"` → `"۲۳٪"`. Nil passes through so a goal on pace draws no pill at
  # all rather than an empty one; see `drift/1`.
  defp persian_percent(nil), do: nil

  defp persian_percent(drift) when is_binary(drift),
    do: drift |> Digits.to_persian() |> String.replace("%", @percent)

  @doc "The page, in the order 108 stacks it."
  @spec content(map()) :: map()
  def content(assigns) do
    goals = assigns.goals

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {Kati.Screens.GoalsFa.chrome()}
        {Kati.Screens.GoalsFa.header()}
        {Kati.Screens.GoalsFa.cards(goals)}
        {Kati.Screens.GoalsFa.calendar_note()}
      </Column>
    </Scroll>
    """
  end

  @doc """
  The back pill and the add disc, on one row.

  Hand-rolled rather than `Kati.Screens.Goals.chrome/0`, which draws the disc
  and no pill: a screen under `Kati.Screens.Fa.pushed_frame/1` has no
  `Kati.Screens.Pushed` chrome behind it, so the pill is this screen's to draw.
  Its geometry is `Kati.Screens.BookDetailFa.chrome/0`'s, number for number —
  `arrow_forward_ios`, because back is the way the reader came from and in
  Persian that is the right edge, and the same 12/16 padding split that screen
  69's frame asks for. Only the label differs, and a label is not worth a
  second copy of the pill; the shared one would take a caption argument.

  The `Spacer` does the mirroring: under `rtl` the pill starts at the right and
  the weight pushes the disc to the left, which is the drawing's
  `space-between` seen from the other side.
  """
  @spec chrome() :: map()
  def chrome do
    label = @chrome.back

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
          {Kati.Screens.BookDetailFa.fa(label, 13.5, :on_surface, weight: "semibold")}
        </Row>
        <Spacer weight={1.0} />
        {Kati.Screens.GoalsFa.add_disc()}
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc """
  The 44pt ink disc that makes a goal.

  `Kati.Components.MishkaActionIcon` at the drawing's size, which is what
  `Kati.Screens.Fa.disc/2` is — but not a call to it, because that helper fixes
  the fill at card white with the button shadow and both frames draw this one
  ink-filled and flat. It is a real control rather than a decorative disc,
  which is the reason screen 104 gave for owning its chrome in the first place.
  """
  @spec add_disc() :: map()
  def add_disc do
    MishkaActionIcon.action_icon(
      %{
        size: 44,
        shape: :circle,
        variant: :filled,
        background: Palette.ink_fill(),
        on_tap: :add
      },
      [UI.symbol("add", size: 21, color: Palette.on_ink())]
    )
  end

  @doc """
  The screen title over its Persian range line.

  `Kati.Screens.BookDetailFa.title/1` unchanged, because 69 and 108 draw the
  same two lines: Vazirmatn 25 bold over 12.5 in `muted`. Not
  `Kati.UI.SettingsList.title/2`, which builds both `Text` nodes itself with no
  `font_family` and a mono subtitle — a Persian range line handed to it is two
  rows of empty boxes. The helper's spacer between the lines is 5 where 108
  draws 6; one point is not worth a fourth copy of the header.
  """
  @spec header() :: map()
  def header do
    BookDetailFa.title(%{title: @chrome.title, author: @chrome.range})
  end

  @doc "Every goal, each under its own pace eyebrow."
  @spec cards([map()]) :: map()
  def cards(goals) do
    sections =
      goals
      |> Enum.with_index()
      |> Enum.map(fn {goal, index} -> Kati.Screens.GoalsFa.section(goal, index) end)

    ~MOB"""
    <Column fill_width={true}>
      {sections}
    </Column>
    """
  end

  @doc """
  One pace eyebrow and the card under it.

  The dash is accent on the first section and `rail_idle` on the rest, which is
  what both frames draw and is the palette's one-accent-per-screen rule rather
  than a fact about being on pace: orange means *new or now*, and the top of
  the page is where the reader is. `Kati.Screens.AlbumDetailFa.eyebrow/2`
  already owns both recipes — the accent case delegates to
  `Kati.Screens.Fa.eyebrow/1` — so neither is spelled out again here.
  """
  @spec section(map(), non_neg_integer()) :: map()
  def section(goal, index) do
    dash = if index == 0, do: :accent, else: :grey

    ~MOB"""
    <Column fill_width={true}>
      {AlbumDetailFa.eyebrow(goal.pace_label, dash)}
      {Kati.Screens.GoalsFa.card(goal)}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  One goal card: title and drift, the pair of figures, the rail, the
  projection, the rule, the field, and — on the books card only — what counts.

  `Kati.Theme.shadow_card_soft/0` and not `shadow_card/0`: the drawing's second
  layer is `rgba(26,25,23,.7)` and `shadow_card_soft/0` is the token whose
  alpha is exactly that.
  """
  @spec card(map()) :: map()
  def card(goal) do
    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={22}
      padding={17}
      shadow={Kati.Theme.shadow_card_soft()}
    >
      {Kati.Screens.GoalsFa.head(goal)}
      <Spacer size={13} />
      {Kati.Screens.GoalsFa.figures(goal)}
      <Spacer size={13} />
      {Kati.Screens.GoalsFa.bar(goal.fraction)}
      <Spacer size={14} />
      {Kati.Screens.GoalsFa.projection(goal)}
      <Spacer size={14} />
      {MishkaSeparator.separator(color: Palette.hairline(), thickness: 1, render: :box)}
      <Spacer size={13} />
      {Kati.Screens.GoalsFa.field(goal.fraction)}
      {Kati.Screens.GoalsFa.counts(goal)}
    </Column>
    """
  end

  @doc """
  The card's top line: the title takes the width, the drift pill does not.

  The title is wrapped in a weighted `Column` rather than given the weight
  itself, because `Kati.Screens.BookDetailFa.fa/4` sets the face, the size and
  the colour and takes no layout weight — and the face is the one thing a
  Persian title cannot be drawn without.
  """
  @spec head(map()) :: map()
  def head(goal) do
    ~MOB"""
    <Row fill_width={true} align="top">
      <Column weight={1.0}>
        {Kati.Screens.GoalsFa.title(goal)}
      </Column>
      {Kati.Screens.GoalsFa.drift(goal)}
    </Row>
    """
  end

  @doc """
  The card title, in whichever language the goal's words are in.

  A goal the reader stored still carries `Kati.Goals.Goal.title/1`'s English
  composition, and an English string must be drawn in the sans face — handing
  it to `Kati.Screens.BookDetailFa.fa/4` would set Latin text in Vazirmatn,
  which renders but is the wrong typeface for the wrong reason. The drawn case
  goes through the helper, as every Persian `Text` on this page does.
  """
  @spec title(map()) :: map()
  def title(%{words: nil} = goal) do
    text = goal.title

    ~MOB"""
    <Text
      text={text}
      text_size={14}
      font_weight="bold"
      letter_spacing={-0.015}
      line_height={1.5}
      text_color={:on_surface}
      max_lines={2}
    />
    """
  end

  def title(goal),
    do: BookDetailFa.fa(goal.words.title, 14, :on_surface, weight: "bold", lines: 2)

  @doc """
  The drift pill: an arrow and a percentage on a wash of its own colour, or
  nothing at all.

  Nothing at all on the on-pace card, and that is the drawing agreeing with
  screen 104's reasoning for once: a number attached to *طبق برنامه* invites
  reading the band as a failure, so `Kati.Goals.Goal.drift/2` is not asked and
  the corner stays empty.

  Hand-rolled rather than `Kati.UI.chip/2`, for the reason screens 69 and 76
  hand-roll theirs: `chip/2` builds its own label `Text` with no
  `font_family`, and `۲۳٪` in Plus Jakarta Sans is three empty boxes. Same
  geometry, one prop more.

  Red on the falling card, `#B4553C` on its 14% wash, because that is what both
  frames draw — see the moduledoc for the argument screen 104 makes for bronze
  instead.
  """
  @spec drift(map()) :: map() | []
  def drift(%{drift: nil}), do: []

  def drift(goal) do
    {icon, tint, wash} = drift_tones(goal.pace)
    label = goal.drift

    ~MOB"""
    <Row align="center">
      <Spacer size={12} />
      <Row
        height={26}
        corner_radius={13}
        background={wash}
        padding_left={10}
        padding_right={10}
        align="center"
      >
        {UI.symbol(icon, size: 15, color: tint, fill: true)}
        <Spacer size={5} />
        {Kati.Screens.BookDetailFa.fa(label, 11.5, tint)}
      </Row>
    </Row>
    """
  end

  defp drift_tones(:ahead), do: {"arrow_drop_up", Palette.green_text(), Palette.green_wash()}
  defp drift_tones(_behind), do: {"arrow_downward", Palette.red(), Palette.red_wash_strong()}

  @doc """
  The pair of figures, and the reason they are not in the mono face.

  `kati_mono.ttf` carries none of U+06F0–U+06F9, so the caption's DM Mono is
  unavailable to a Persian numeral; these are Vazirmatn at the design's size
  and colour. The moduledoc has the trade in full, including what alignment
  survives it and what does not.

  The trailing weighted `Spacer` is what keeps the pair at the start edge —
  under `rtl` that is the right, where both frames put it.
  """
  @spec figures(map()) :: map()
  def figures(goal) do
    ~MOB"""
    <Row fill_width={true} align="bottom">
      {Kati.Screens.BookDetailFa.fa(goal.figure, 27, :on_surface, weight: "medium")}
      <Spacer size={8} />
      {Kati.Screens.BookDetailFa.fa(goal.of, 15, Palette.meta())}
      <Spacer weight={1.0} />
    </Row>
    """
  end

  @doc """
  The progress rail — the one orange thing on the card, and the one that
  mirrors for free.

  The same `Kati.Components.MishkaProgress` call screens 69 and 104 make, at
  108's own numbers: a 2pt rail on `rail_idle` rather than
  `Kati.Screens.Goals.bar/1`'s 5pt on `track`. The component lays its fill out
  as a `Row`, so under the `rtl` root the fill starts at the right edge without
  anything here reversing a value.
  """
  @spec bar(float()) :: map()
  def bar(fraction) do
    MishkaProgress.progress(
      render: :box,
      value: fraction,
      max: 1,
      height: 2,
      corner_radius: 1,
      color: Palette.accent(),
      track_color: Palette.rail_idle()
    )
  end

  @doc """
  The projection sentence, as one wrapping paragraph.

  `Kati.UI.rich_text/1` and not three `Text` nodes in a `Row`: a `Row` does not
  wrap, so each run would become its own unbreakable box and the emphasised
  number would orphan onto a line of its own. The helper is also the only thing
  in `Kati.UI` that emits a `Text` with no `max_lines` cap, which is what a
  paragraph needs.

  Every run carries `base: true` on the body style, and that is load-bearing
  rather than decorative. With no base marked, `rich_text/1` styles the
  paragraph after its **longest** run — and on the films card the emphasised
  `۱۰۶ از ۱۲۰` is one character longer than the body run after it, so the whole
  sentence would come out semibold in ink.

  A goal the reader stored has no Persian sentence, and screen 104's own
  `projection/1` draws it instead — same runs, same helper, Latin styles.
  """
  @spec projection(map()) :: map()
  def projection(%{words: nil} = goal), do: Goals.projection(goal)

  def projection(goal) do
    body = [
      text_size: 12.5,
      line_height: 1.85,
      text_color: Palette.ink_soft(),
      font_family: "fa",
      base: true
    ]

    strong = [
      text_size: 12.5,
      line_height: 1.85,
      text_color: Palette.ink(),
      font_weight: "semibold",
      font_family: "fa"
    ]

    goal.words.sentence
    |> Enum.map(fn {text, tone} -> {text, if(tone == :strong, do: strong, else: body)} end)
    |> UI.rich_text()
  end

  @doc """
  The sentence that says what counts, on the one card that draws it.

  `Kati.Goals.Goal.counts/1` guarantees one per kind and 108 draws only the
  books card's, so the other two answer `[]` — an explicit absence rather than
  an empty paragraph holding 12pt of space open. The moduledoc says why the
  remaining nine sentences have no Persian.
  """
  @spec counts(map()) :: map() | []
  def counts(%{words: %{counts: nil}}), do: []
  def counts(%{words: nil} = goal), do: counts_line(goal.counts, "sans")
  def counts(goal), do: counts_line(goal.words.counts, "fa")

  # One run through `rich_text/1` rather than a bare `Text`, for the same
  # reason `projection/1` uses it: this is a two-line sentence and every other
  # Persian `Text` helper on these screens caps `max_lines` at 1, which would
  # truncate it mid-word.
  defp counts_line(text, face) do
    line =
      UI.rich_text([
        {text, [text_size: 11, line_height: 1.7, text_color: Palette.sub(), font_family: face]}
      ])

    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={12} />
      {line}
    </Column>
    """
  end

  @doc """
  The sparkline: thirty-four cells, lit as far as the goal has got.

  Derived from the same `fraction` the rail above it takes, which is the
  moduledoc's finding — both frames fill 25, 34 and 24 of thirty-four on cards
  whose bars run to 73%, 100% and 70%. Rounding is deliberate rather than
  floor: 73% of thirty-four is 24.8, and a field that showed twenty-four where
  the bar showed three quarters would read as an off-by-one.

  Chunked into declared rows because a `Row` does not wrap, and interspersed
  rather than trailed with spacers so the field ends flush with the cell rather
  than 3pt below it.
  """
  @spec field(float()) :: map()
  def field(fraction) do
    lit = fraction |> Kernel.*(length(@field)) |> round() |> max(0) |> min(length(@field))

    rows =
      @field
      |> Enum.with_index()
      |> Enum.map(fn {level, index} -> if index < lit, do: level, else: nil end)
      |> Enum.chunk_every(@per_row)
      |> Enum.map(fn row -> Kati.Screens.GoalsFa.field_row(row) end)
      |> Enum.intersperse(~MOB"<Spacer size={3} />")

    ~MOB"""
    <Column fill_width={true}>
      {rows}
    </Column>
    """
  end

  @doc """
  One row of cells, laid out start-to-end.

  Which under the `rtl` root means the first cell of the first row lands in the
  top-right corner, exactly as the caption asks. Nothing here reverses a list.
  """
  @spec field_row([non_neg_integer() | nil]) :: map()
  def field_row(row) do
    cells =
      row
      |> Enum.map(&Kati.Screens.GoalsFa.cell/1)
      |> Enum.intersperse(~MOB"<Spacer size={3} />")

    ~MOB"""
    <Row>
      {cells}
    </Row>
    """
  end

  @doc """
  One 7pt cell: a step of the warm ramp, or an outlined hole for a day the
  period has not reached.

  The ramp is `Kati.Music.Sample.tone/1` — the five warm tones screen 74 draws
  its listening field with, on a card of the same white, and the identical five
  values 108 asks for. It is borrowed rather than copied because copying it
  would put five hex literals in this file, and its own comment explains why
  those five are not palette tokens yet: only `#B08E55` has a name, and naming
  one step of a ramp while its neighbours stay hex would read as if the other
  four had been checked and rejected.

  The empty cell is `Palette.transparent/0` behind a 1pt `hairline_soft`
  border, which is the drawing's `rgba(26,25,23,.08)` inset ring to the alpha.
  """
  @spec cell(non_neg_integer() | nil) :: map()
  def cell(nil) do
    ~MOB"""
    <Box
      width={7}
      height={7}
      corner_radius={2}
      background={Palette.transparent()}
      border_color={Palette.hairline_soft()}
      border_width={1}
    />
    """
  end

  def cell(level) do
    tone = Sample.tone(level)

    ~MOB"""
    <Box width={7} height={7} corner_radius={2} background={tone} />
    """
  end

  @doc """
  The cream card that says when a Persian year ends.

  The one thing 108 draws that 104 does not, and the reason is in the
  moduledoc: the period boundary is a domain fact the app does not honour yet,
  and until it does, stating it is the honest half of the answer.

  Cream because cream is this design's warm aside, and `info` in `gold_icon`
  because that is the note hue. The paragraph goes in a weighted `Column`
  rather than being weighted itself — `Kati.UI.rich_text/1` returns a styled
  `Text` and takes no layout weight — and it is set at 1.85 leading, which is
  the leading Persian needs and not the 1.65 the Latin cards use: Vazirmatn's
  descenders run under the line and its diacritics over it, so a Persian
  paragraph at a Latin paragraph's leading collides with itself.
  """
  @spec calendar_note() :: map()
  def calendar_note do
    body = [
      text_size: 12.5,
      line_height: 1.85,
      text_color: Palette.cream_body(),
      font_family: "fa",
      base: true
    ]

    strong = [
      text_size: 12.5,
      line_height: 1.85,
      text_color: Palette.ink(),
      font_weight: "semibold",
      font_family: "fa"
    ]

    # Three `Text` nodes rather than one `Kati.UI.rich_text/1` run, and the
    # reason is the one `Kati.Screens.LogProgressFa.insight/1` records: that
    # helper merges its runs into a single node and takes one run's style for
    # all of them, so on a Persian screen one run would decide the face for the
    # rest. Wrapped in a `Column` of `Row`s because a `Row` does not wrap and
    # the tail of this sentence is long.
    note =
      @note
      |> Enum.map(fn {text, tone} ->
        Kati.Screens.GoalsFa.note_run(text, if(tone == :strong, do: strong, else: body))
      end)

    ~MOB"""
    <Row fill_width={true} background={Palette.cream()} corner_radius={20} padding={16} align="top">
      {UI.symbol("info", size: 18, color: Palette.gold_icon())}
      <Spacer size={11} />
      <Column weight={1.0}>
        {note}
      </Column>
    </Row>
    """
  end

  @doc """
  One run of the footnote, as its own `Text`.

  Its own node so the Persian face survives — see the comment in
  `calendar_note/0`. Each
  run carries `max_lines: 3` rather than 1, because the tail of this sentence is
  a clause and a clause that truncates is a clause that changed meaning.
  """
  @spec note_run(String.t(), keyword()) :: map()
  def note_run(text, style) do
    assigns = %{
      text: text,
      size: Keyword.fetch!(style, :text_size),
      colour: Keyword.fetch!(style, :text_color),
      weight: Keyword.get(style, :font_weight, "normal"),
      height: Keyword.fetch!(style, :line_height)
    }

    ~MOB"""
    <Text
      text={@text}
      font_family="fa"
      text_size={@size}
      font_weight={@weight}
      line_height={@height}
      text_color={@colour}
      max_lines={3}
    />
    """
  end

  def handle_info({:tap, :back}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}

  # Screen 106, which is English. The same debt `Kati.Screens.AlbumDetailFa`
  # carries against `Kati.Screens.Rating` and `Kati.Screens.Fa`'s moduledoc
  # names the cost of: a push that changes the app's language out from under
  # the reader, and RTL with it. It is still the right destination — a mirror
  # that made a goal somewhere else would be a second app rather than the same
  # one in another language.
  def handle_info({:tap, :add}, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.NewGoal)}

  def handle_info({:tap, _tag}, socket), do: {:noreply, socket}
  def handle_info(_message, socket), do: {:noreply, socket}
end
