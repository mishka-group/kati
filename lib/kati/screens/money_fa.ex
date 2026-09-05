defmodule Kati.Screens.MoneyFa do
  @moduledoc """
  Screen 127 — پول, the Persian money page, pushed under آمار.

  Screen 122 in the mirror, and the one Persian screen that is almost entirely
  numbers. Its caption is about numbers too, and every clause of it is either a
  finding or a trade.

  ## `Kati.Screens.StatsFa` has been pointing here since 61 was built

  The caption ends *the parent row this needs on 61 is added below*, and it
  already is: `Kati.Screens.StatsFa.more_numbers/0` draws a `payments` row
  reading `پول · ۴۶٫۴۷ پوند در ماه` and
  `Kati.Screens.StatsFa.handle_info/2` pushes `Kati.Screens.MoneyFa`. Until
  this file existed that push named a module that was not there. Nothing in 61
  changes; this is the screen it was already asking for, which is also why the
  back pill says آمار and not تنظیمات.

  ## "Every figure keeps DM Mono" is the one thing that cannot be done

  `kati_mono.ttf` carries **zero** code points in U+06F0–U+06F9 —
  `Kati.Screens.Fa`'s moduledoc has the parse — and Vazirmatn carries all ten.
  So every figure on this page is set in `fa` at the drawing's own size and
  colour: the 34pt hero total, the 12pt prices, the 15pt per-hour rates, the
  12.5pt expense amounts, the 11.5pt delta. The face is wrong and the glyphs
  are right, which is the better half of an unwinnable trade, and it goes away
  the day the mono subset is regenerated with the Persian digits in it.

  The caption's *reason* for the mono face — *so both the price and the £/h
  columns stay aligned under mirroring* — survives, but not by the mechanism
  the caption names. Vazirmatn is proportional and does not measure `۸` and
  `۱۳` alike, so nothing here is a tabular column. What holds the two columns
  is the **edge**: `Kati.UI.SettingsList.row/4` lays every trailing group
  against the row's own trailing edge, and under `Kati.Screens.Fa.pushed_frame/1`
  that edge is the left one. The eye runs down the edge, not down the glyph
  advances. `Kati.Screens.MyServicesFa.price_chip/1` records the same finding
  for screen 97's prices.

  ## "The CLDR separators, no ASCII comma or dot anywhere" is true by construction

  Not by search-and-replace. `figure/1` parses the English figure back to a
  `Decimal` and hands it to `Kati.Cldr` at `locale: "fa"`, whose default number
  system is `arabext`; CLDR's own symbols for that system are **U+066B** for
  the decimal and **U+066C** for the group, so `£1,234.56` comes back as
  `۱٬۲۳۴٫۵۶` with no ASCII dot or comma ever present in the result to be
  replaced. `Kati.Screens.MyServicesFa.amount/1` reaches the same characters by
  `String.replace(".", "٫")`, which is right for a two-decimal price and would
  quietly leave an ASCII comma in a four-figure one; this screen totals months,
  so it takes the longer road.

  `Kati.I18n.Digits.parse_float/1` folds both marks back, so a figure printed
  here is a figure that can be typed in again.

  ## "The currency word follows the figure per CLDR" is true of one pattern only

  Worth being exact about which. `fa`'s **standard** currency pattern is
  symbol-leading: `format: :currency` answers `‎£۴۶٫۴۷`, LRM and all. It is the
  **name** pattern, `¤¤¤`, that trails the figure. So the caption is a
  statement about `¤¤¤` and is false of the symbol form, and `money/2` prints
  the name.

  What this file supplies is the abbreviation. CLDR's name for GBP in `fa` is
  `پوند بریتانیا`, *pound of Britain*; 127 prints `پوند`, as screen 56's
  `Kati.Screens.ScheduleFa.Sample` and screen 61's own money row already do.
  `Kati.Screens.Currency` keeps the full name and is right to — a currency
  picker is a screen where the country is the point — but here the word shares
  a trailing column with the per-hour rate under it, and a second word would
  push the column the caption asks to keep aligned. `word/0` holds the short
  forms for the five currencies `Kati.Money.currencies/0` offers and falls back
  to CLDR's full name for a code it has never heard of, which is the fallback
  `Kati.Screens.MyServicesFa.region_name/1` makes for a country.

  ## Where this file disagrees with `Kati.Screens.Money`, and the frame wins

  127 is a later drawing of 122's page, and in six places the two disagree.
  Each time this file draws **its own frame**, for `Kati.Screens.AlbumDetailFa`'s
  reason: the frame is the thing being reproduced, and the drift is 122's to
  settle for both sheets rather than the mirror's to invent a second money page
  around.

    * **Three services, not four.** 122 draws Lumen+, Orbit, Kino and a paused
      Aria Audio; 127 draws the three. The paused row's sentence goes with it —
      122's `info` line is three sentences and 127's is one, and it is the
      per-hour sentence that survives. Dropping the row and keeping the
      sentence, or the reverse, would be worse than either.
    * **One month, not two.** See the next section; this one is not the frame
      being terse.
    * **The month header is inside the card.** 122 hangs `August · £61.40`
      above a `Kati.UI.SettingsList.card/1`; 127 puts it inside a 22-radius card
      at 17 of padding with a hairline under it, which is why `expenses/1`
      builds its own container instead of calling that helper.
    * **The delta is a pill.** 122 draws a bare glyph and a figure; 127 draws
      them in a 28pt chip at radius 14 on `green_wash`. `delta/1` here is that
      chip.
    * **`trending_up` is red and `lightbulb` is accent.** Both frames say so —
      `#B4553C` and `#E8823C` in `test/design/screens/122.html` too — and
      `Kati.Screens.Money.hero/0` and `suggestion/1` paint both
      `Palette.gold_icon()`. The frames agree with each other and disagree with
      122's module, so the frames win.
    * **The dismiss control is a chip.** 122 draws bare text beside the ink
      pill; 127 draws a 40pt paper chip at radius 20, and the ink pill takes
      the remaining width rather than hugging its label.

  ## Why only the drawing's month is drawn, and what would change it

  Not squeamishness about English rows — `Kati.Screens.BookDetailFa` shows a
  shelved book's own title unapologetically, because a title is the user's.
  The blocker is the **month label**. `Kati.Money.Expense.by_month/1` answers
  `{label, total, rows}` where the label is already `Calendar.strftime("%B")`,
  a Gregorian month *name*, and مرداد runs 23 July to 22 August — no Shamsi
  month can be recovered from the word "August" without the dates that produced
  it. The same is true one level down: the drawing's `۲۵ مرداد` is 16 August
  1404/2025, and `Kati.Money.Sample` carries `"16 AUG · SCREEN"` as a string
  with no year in it. Guessing the year to convert it is exactly the invented
  precision `Kati.Screens.SeriesFa` refuses for a Gregorian period.

  So the Shamsi dates and the month word are the drawing's copy, and every
  figure beside them is `Kati.Screens.Money.drawn_months/0`'s. The upstream ask
  is one field: have `by_month/1` return the group's dates alongside its label,
  and this screen renders any month through `Kati.Calendar.Shamsi.format/2` and
  drops `@expenses` entirely.

  ## What is reused from 122, and the rule that decides

  **Every figure comes from 122's fixture and nothing is retyped.** The hero
  total and its change, the three prices and rates, the month total, its delta
  and its four amounts are all `Kati.Money.Sample`'s, read through
  `Kati.Screens.Money.drawn_months/0` where 122 has a reader for them, and the
  header's two counts are lifted out of `Kati.Screens.Money.subtitle/0` rather
  than restated. A mirror that disagreed with its original about £46.47 would
  be a second app.

  `Kati.Screens.Money`'s *builders*, though, are almost all unreachable, and
  for one reason: each of them ends in a `Text` that is either mono or English.
  `hero/0`, `rate/1`, `amount/1`, `delta/1`, `expense_row/1`, `service_row/1`
  and `suggestion/1` all typeset a figure in `font_family="mono"`, which has no
  Persian digits, so each is rebuilt here. What is reachable is reused:

    * `Kati.Screens.MyServices.badge_tile/1` — the `L`, `O` and `K` tiles, one
      Latin capital each, the one string on this page that is the same string
      in both languages.
    * `Kati.UI.SettingsList.card/1`, `row/4`, `trailing/1` and `hairline/1` —
      geometry and the rule between rows, no text of their own.
    * `Kati.UI.rich_text/1` — the only `Kati.UI` helper a Persian screen can
      call unchanged, because its run style is a keyword list of `Text` props
      rather than a fixed recipe, so `font_family: "fa"` simply goes in it.
    * `Kati.Screens.Fa.eyebrow/1` and `Kati.Screens.Fa.disc/2` — the accent
      eyebrow and the 44pt `more_horiz` disc.
    * `Kati.Screens.BookDetailFa.fa/4` for every label, and
      `Kati.Screens.MyServicesFa.body/3`, `consequence/2`, `footnote/1` and
      `split_symbol/1` — the Persian row body, the 1.7-leading sub-line, the
      bare `info` footnote and the currency-symbol split, all already written
      to these numbers on screen 97.

  Neither `Kati.UI.chip/2` nor `Kati.UI.Segmented` appears here, and neither
  could: `MishkaChip` takes its label as a prop and `expand/3` discards
  children, and the segmented control says in as many words that it paints its
  own label. A Persian label through either door is a row of empty boxes. This
  screen draws two hand-rolled chips instead — the delta pill and the dismiss
  chip — at the drawing's own geometry, the same way
  `Kati.Screens.BookDetailFa.chip/3` does.

  ## Two glyphs point opposite ways, and one push leaves Persian

  `arrow_forward_ios` on the back pill, because back is the way the reader came
  from and in Persian that is the right edge. Nothing else on this page points.

  A service row pushes `Kati.Screens.MyServicesFa` where 122 pushes
  `Kati.Screens.Subscriptions`, and that is a deliberate substitution rather
  than a different destination: 122's own `info` line says prices are owned by
  screen 92, and 97 is 92's Persian mirror, so the reader gets the screen that
  answers the question without the app changing language under them —
  the failure `Kati.Screens.Fa`'s moduledoc records for the آمار tab's
  stand-in.

  The reminder button has no such mirror. It pushes
  `Kati.Screens.ReleaseWatcher`, which is English, and that is the debt
  `Kati.Screens.AlbumDetailFa` already carries against `Kati.Screens.Rating`.
  It is paid the way that one is: by drawing the Persian screen, not by
  quietly deadening the only button on the card.

  ## The copy is a proposal

  Screens 72, 76 and 97 say it and it is true here: every Persian string below
  was open, and these are proposals. They live in `@copy`, `@services` and
  `@expenses` rather than scattered through the markup so that a native reader
  corrects each one once.
  """

  use Mob.Screen
  import Mob.Sigil

  alias Kati.I18n.Digits
  alias Kati.Screens.BookDetailFa
  alias Kati.Screens.Fa
  alias Kati.Screens.MyServices
  alias Kati.Screens.MyServicesFa
  alias Kati.Theme
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  # Everything the drawing prints that is a word rather than a figure. The
  # figures all come from `Kati.Money.Sample` through screen 122 — see the
  # moduledoc — so nothing numeric belongs in here except where a whole
  # sentence carries one, which `suggestion_tail` does and 122's own fixture
  # does too.
  @copy %{
    back: "آمار",
    title: "پول",
    subtitle: "۳ سرویس · ۷ هزینه این ماه",
    services: "سرویس",
    expenses: "هزینه این ماه",
    every_month: "هر ماه",
    change_lead: "از اسفند",
    change_rest: "بیشتر شده — اوربیت قیمتش را بالا برد",
    recurring: "تعهدهای ماهانه",
    per_hour_note: "هزینه به ازای هر ساعت تماشا مهم‌ترین عدد این صفحه است.",
    one_off: "هزینه‌های موردی",
    month: "مرداد",
    per_hour: "/ساعت",
    suggestion_lead: "این ماه",
    suggestion_hours: "۶ ساعت",
    suggestion_middle: "در اوربیت تماشا کرده‌اید و",
    suggestion_titles: "۱ عنوان",
    suggestion_tail: "در صف مانده. توقف بعد از ۲ شهریور ۱۳٫۹۹ پوند صرفه‌جویی است.",
    remind: "۱ شهریور یادم بیاور",
    dismiss: "بی‌خیال"
  }

  # The renewal line for each service the drawing names, keyed by the initial
  # `Kati.Money.Sample.recurring/0` gives it. Keyed rather than listed because
  # the key is also the filter: a service with no Persian line here is not
  # drawn at all, which is what happens to the paused Aria Audio that 127 does
  # not draw. An English renewal line inside a Persian card would be worse than
  # a missing row, and inventing a Persian one for a row the drawing never
  # showed would be worse than both.
  @services %{
    "L" => "تمدید ۲۷ مرداد · ۴۱ ساعت",
    "O" => "تمدید ۲ شهریور · ۶ ساعت",
    "K" => "تمدید ۱۰ شهریور · ۱۹ ساعت"
  }

  # The drawn month's four rows, as `{description, meta} => {title, meta}`.
  #
  # The description alone is not a key: `Weekly shop` is two different expenses
  # in `Kati.Money.Sample`, one in August and one in July, and keying on it
  # would give July's row August's date the day a second month is drawn. The
  # English meta carries the date and the section, so the pair is unambiguous
  # for anything the fixture holds.
  @expenses %{
    {"Kino rental — Blue Hour", "16 AUG · SCREEN"} =>
      {"کرایه کینو — ساعت آبی", "۲۵ مرداد · نمایش"},
    {"The Salt Almanac, paperback", "12 AUG · BOOKS"} => {"سالنامه نمک، شمیز", "۲۱ مرداد · کتاب"},
    {"Cinema — Vellum", "09 AUG · SCREEN"} => {"سینما — ولوم", "۱۸ مرداد · نمایش"},
    {"Weekly shop", "04 AUG · MEALS"} => {"خرید هفتگی", "۱۳ مرداد · وعده‌ها"}
  }

  # The five currencies `Kati.Money.currencies/0` offers, in the short form 127,
  # 56 and 61 all print. CLDR's own names carry a territory — `پوند بریتانیا`,
  # `دلار آمریکا` — which is right on the picker and too wide here; see the
  # moduledoc.
  @currency_words %{
    "GBP" => "پوند",
    "EUR" => "یورو",
    "USD" => "دلار",
    "IRR" => "ریال",
    "TRY" => "لیر"
  }

  @doc """
  Mount, with the suggestion undismissed.

  `dismissed?` is the screen's own state and not a stored preference, exactly
  as it is on screen 122: the card is advice about this month, so it has
  nothing to persist past the frame it was dismissed in.
  """
  @spec mount(map(), map(), Mob.Socket.t()) :: {:ok, Mob.Socket.t()}
  def mount(_params, _session, socket) do
    Kati.Theme.activate()

    {:ok,
     socket
     |> Mob.Socket.assign(:month, month())
     |> Mob.Socket.assign(:dismissed?, false)}
  end

  @doc """
  The page inside a root node that declares `rtl`.

  `Kati.Screens.Fa.pushed_frame/1` rather than `Kati.Screens.Pushed`, for the
  two reasons every Persian mirror records: that macro takes its direction from
  `Kati.Locale.direction_prop/0` — the *app's* setting, so a Persian page
  opened while the app is English would draw in a left-to-right grid — and it
  draws its own back pill with `arrow_back_ios_new` and a `Text` carrying no
  `font_family`, which is a left-pointing chevron beside a row of empty boxes.
  `content/1` still exists so the shape matches every other pushed screen.
  """
  @spec render(map()) :: map()
  def render(assigns), do: Fa.pushed_frame(content(assigns), Kati.Screens.Identity.of(__MODULE__))

  @doc "The page, in the order 127 stacks it."
  @spec content(map()) :: map()
  def content(assigns) do
    month = assigns.month
    dismissed? = assigns.dismissed?
    recurring = Fa.eyebrow(@copy.recurring)
    one_off = Fa.eyebrow(@copy.one_off)

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {Kati.Screens.MoneyFa.chrome()}
        {Kati.Screens.MoneyFa.title()}
        {Kati.Screens.MoneyFa.hero()}
        {recurring}
        {Kati.Screens.MoneyFa.recurring()}
        {one_off}
        {Kati.Screens.MoneyFa.expenses(month)}
        {Kati.Screens.MoneyFa.suggestion(dismissed?)}
      </Column>
    </Scroll>
    """
  end

  @doc "The drawing's Persian copy, so a native reader corrects each string once."
  @spec copy() :: %{atom() => String.t()}
  def copy, do: @copy

  @doc """
  The back pill and the `more_horiz` disc, opposite ends of one row.

  Hand-rolled because the label is آمار: `Kati.Screens.BookDetailFa.chrome/0`
  and `Kati.Screens.MyServicesFa.chrome/0` are this pill to the number — 44 at
  radius 22, card white under the button shadow, 12 of padding on the leading
  edge and 16 on the trailing one so the glyph sits closer to the edge than the
  word does — but both bake in their own parent's name, so neither can be
  called for a third.

  The disc is `Kati.Screens.Fa.disc/2` with no tag, which is what screens 59
  through 62 draw beside their pills: 127 gives it no menu, and a disc that
  lights up and opens nothing is a worse promise than one that does nothing.
  """
  @spec chrome() :: map()
  def chrome do
    word = BookDetailFa.fa(@copy.back, 13.5, :on_surface, weight: "semibold")
    chevron = UI.symbol("arrow_forward_ios", size: 17)
    disc = Fa.disc("more_horiz")

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
          {chevron}
          <Spacer size={6} />
          {word}
        </Row>
        <Spacer weight={1.0} />
        {disc}
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc """
  `پول` over the two counts.

  Not `Kati.UI.SettingsList.title/3`: that sets 28 with -.03em of tracking over
  a DM Mono sub, and Persian wants none of the three. Letter-spacing breaks the
  joins between Arabic-script letters, the mono face has no Persian digits, and
  the drawing's own heading is 25 with no tracking over a Vazirmatn sub at 12.5
  in `muted`.
  """
  @spec title() :: map()
  def title do
    heading = BookDetailFa.fa(@copy.title, 25, :on_surface, weight: "bold")
    sub = BookDetailFa.fa(subtitle(), 12.5, Palette.muted())

    ~MOB"""
    <Column fill_width={true}>
      {heading}
      <Spacer size={6} />
      {sub}
      <Spacer size={20} />
    </Column>
    """
  end

  @doc """
  `۳ سرویس · ۷ هزینه این ماه`, with both counts taken from screen 122.

  Lifted out of `Kati.Screens.Money.subtitle/0` with a regex rather than
  restated, the way `Kati.Screens.MyServicesFa.catalogue_label/0` lifts the
  catalogue count out of screen 92 — so the day 122 counts a real store's
  services and expenses, this line counts them too and the two headers cannot
  disagree. A subtitle that has stopped carrying two numbers falls back to the
  drawing's own line, which is a stale header and a far better one than a
  crash.

  There is no singular branch to write. A Persian noun after a number does not
  inflect, so `۱ سرویس` and `۳ سرویس` take the same word, where the English
  needs `if services == 1`.
  """
  @spec subtitle() :: String.t()
  def subtitle do
    case Regex.scan(~r/\d+/, Kati.Screens.Money.subtitle()) do
      [[services], [expenses] | _rest] ->
        Digits.to_persian(services) <>
          " " <> @copy.services <> " · " <> Digits.to_persian(expenses) <> " " <> @copy.expenses

      _other ->
        @copy.subtitle
    end
  end

  @doc """
  The cream hero: what leaves the account every month, and what changed.

  Cream because it carries a claim — the palette's own definition of the
  colour — and this is the one card on the page that asserts something rather
  than listing it.

  The 34pt total is the largest Persian string in the app and it takes **no**
  letter-spacing where the drawing sets -.04em. The drawing can afford tracking
  because it sets the line in DM Mono, where the string is nine Latin-shaped
  glyphs; here the same line is a Persian numeral run followed by an
  Arabic-script word, and tracking pulls the joins of `پوند` apart. The size,
  the weight and the colour are the drawing's; only the tracking is dropped,
  and it is dropped for the reason `Kati.Screens.MyServicesFa.title/0` gives.
  """
  @spec hero() :: map()
  def hero do
    m = Kati.Money.Sample.monthly()
    w = word()
    total = money(m.total, w)
    body = [font_family: "fa", text_size: 12.5, line_height: 1.8, text_color: Palette.cream_sub()]
    strong = [font_family: "fa", font_weight: "semibold", text_color: Palette.cream_ink()]

    # `base: true` on the body run rather than letting `rich_text/1` pick the
    # longest one. The copy here is a proposal — see the moduledoc — and a
    # native reader shortening the tail could otherwise flip the base to the
    # amount and take the whole paragraph bold.
    change =
      UI.rich_text([
        {@copy.change_lead <> " ", body},
        {money(m.change_amount, w), strong},
        {" " <> @copy.change_rest, Keyword.put(body, :base, true)}
      ])

    label = BookDetailFa.fa(@copy.every_month, 11, Palette.cream_meta(), weight: "semibold")
    glyph = UI.symbol("trending_up", size: 15, color: Palette.red())

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.cream()}
        corner_radius={24}
        padding={19}
        shadow={Theme.shadow_card_soft()}
      >
        {label}
        <Spacer size={7} />
        <Text
          text={total}
          font_family="fa"
          text_size={34}
          font_weight="medium"
          text_color={Palette.cream_ink()}
          max_lines={1}
        />
        <Spacer size={12} />
        <Row fill_width={true} align="center">
          {glyph}
          <Spacer size={7} />
          <Column weight={1.0}>
            {change}
          </Column>
        </Row>
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  The three services the drawing names, and the sentence about the figure that
  matters.

  Read through `Kati.Money.Sample.recurring/0` rather than re-derived: screen
  23 draws the same rows, screen 92 owns their prices, and four screens
  computing one number four ways is four chances to disagree. The Persian
  renewal line is this file's, keyed by the same initial — see `@services` for
  why that key is also the filter.

  The footnote is `Kati.Screens.MyServicesFa.footnote/1` unchanged, which is
  already this drawing's numbers: a 15pt `info` in `tertiary` beside a
  wrapping sentence at 11.5 in `sub` with the **1.7** leading Persian needs,
  2pt of side inset, and 24 below.
  """
  @spec recurring() :: map()
  def recurring do
    w = word()

    rows =
      Kati.Money.Sample.recurring()
      |> Enum.filter(&Map.has_key?(@services, &1.badge))
      |> Enum.map(&Kati.Screens.MoneyFa.service_row(&1, w))

    card = SettingsList.card(rows)
    note = MyServicesFa.footnote(@copy.per_hour_note)

    ~MOB"""
    <Column fill_width={true}>
      {card}
      <Spacer size={11} />
      {note}
    </Column>
    """
  end

  @doc """
  One service: the initial, the name over its renewal line, the price over its
  rate.

  The tile is `Kati.Screens.MyServices.badge_tile/1` untouched. A badge is one
  Latin capital, the one string on this page that is the *same string* in both
  languages, and screen 97 takes it through the same door for the same reason.
  It typesets in Plus Jakarta Sans where both frames draw DM Mono, and that is
  92's and 122's to settle: the day the tile moves to the mono face, both
  sheets follow for free.

  The body is `Kati.Screens.MyServicesFa.body/3` — 13 at semibold over 11.5 in
  `sub` with a 3pt gap, which is exactly what 127 draws. The trade name goes in
  Vazirmatn rather than the mono face because the drawing sets it there, and
  because Vazirmatn carries the Latin alphabet perfectly; nothing about a trade
  name asks for mono.
  """
  # The tag is `Kati.Screens.Money.subscription_tag/1`'s, not a Persian one of
  # its own: every row drew `:open_services`, so the ledger was one
  # accessibility_id repeated (#97), and an id is addressed by a device test
  # rather than read by a person — the mirror of screen 122 addresses its rows
  # by the same names screen 122 does.
  @spec service_row(map(), String.t()) :: map()
  def service_row(service, word \\ word()) do
    SettingsList.row(
      MyServices.badge_tile(service.badge),
      MyServicesFa.body(service.name, Map.fetch!(@services, service.badge)),
      SettingsList.trailing(Kati.Screens.MoneyFa.rate(service, word)),
      on_tap: {self(), Kati.Screens.Money.subscription_tag(service)}
    )
  end

  @doc """
  The price above, the per-hour rate below.

  The rate takes the colour of its own verdict — `green_text` when the service
  is earning its money, `red` when it is not, `tertiary` when there is no
  verdict to give, which is what an em dash means here. That mapping is
  `Kati.Screens.Money.rate/1`'s and is reproduced rather than reinvented; what
  could not be reproduced is the two `Text` nodes themselves, both of which are
  `font_family="mono"` there and so have no Persian digits.

  ## `align="trailing"` does the flushing now, and `text_align` used to try

  Both lines carried `text_align="end"` and neither does any more, and the
  reason is the defect that pairing caused. `MobText` reads a present
  `text_align` as *this text is wider than its glyphs* and applies
  `fillMaxWidth()`, so the rate column filled the row it was the trailing slot
  of — and `Kati.UI.SettingsList.row/4` puts the body in a `weight={1.0}`
  column beside it, which then measured **zero**. On a Pixel 9a this screen
  drew three service rows with a badge, a price and a per-hour rate and **no
  service name in any of them**. Screen 122 is the same markup and had the same
  hole.

  `align="trailing"` on the `Column` was already written here and in 122, and
  until `K-34 column-align` the bridge read it from nobody: `Column(modifier =
  m)` took no `horizontalAlignment`, so a column hugged its widest child and
  the narrower line sat at the start edge. The prop is honoured now, which is
  what flushes the two lines — so the alignment is expressed once, on the
  container that owns it, and the two `Text` nodes go back to hugging.
  """
  @spec rate(map(), String.t()) :: map()
  def rate(service, word \\ word()) do
    colour =
      case service.good? do
        true -> Palette.green_text()
        false -> Palette.red()
        nil -> Palette.tertiary()
      end

    price = money(service.price, word)
    per_hour = per_hour(service.rate)

    ~MOB"""
    <Column align="trailing">
      <Text text={price} font_family="fa" text_size={12} text_color={:on_surface} max_lines={1} />
      <Spacer size={4} />
      <Text
        text={per_hour}
        font_family="fa"
        text_size={15}
        font_weight="semibold"
        text_color={colour}
        max_lines={1}
      />
    </Column>
    """
  end

  @doc """
  The drawn month, in Persian, or nothing at all.

  Every figure is `Kati.Screens.Money.drawn_months/0`'s — the total, the delta
  and the four amounts — and every word is this file's. Only the first group is
  taken, and the moduledoc says why that is a limit of
  `Kati.Money.Expense.by_month/1` rather than the drawing being terse.

  `nil` for a fixture with no months in it at all, so `expenses/1` can draw
  nothing rather than an empty card with an eyebrow over it.
  """
  @spec month() :: map() | nil
  def month do
    case Kati.Screens.Money.drawn_months() do
      [drawn | _rest] ->
        %{
          label: @copy.month,
          total: money(drawn.total),
          direction: drawn.direction,
          delta: drawn.delta && figure(drawn.delta),
          rows: Enum.flat_map(drawn.rows, &Kati.Screens.MoneyFa.expense/1)
        }

      [] ->
        nil
    end
  end

  @doc """
  One expense in Persian, or nothing when the drawing never named it.

  A list rather than a map so `Enum.flat_map/2` can drop a row the copy does
  not cover: an English description under an English date inside a Persian card
  is not a translation of the row, it is the row untranslated, and the drawing
  gives Persian for four.
  """
  @spec expense(map()) :: [map()]
  def expense(row) do
    case Map.fetch(@expenses, {row.name, row.meta}) do
      {:ok, {name, meta}} -> [%{name: name, meta: meta, amount: figure(row.amount)}]
      :error -> []
    end
  end

  @doc """
  The one-off expenses: one card holding its own month header and its rows.

  Not `Kati.UI.SettingsList.card/1`. That is 20 at 4 and 15 of padding, and it
  has no room above its first row for the header 127 puts inside it; this card
  is the drawing's 22 at 17, with the header, a hairline, and then the rows.
  """
  @spec expenses(map() | nil) :: map() | []
  def expenses(nil), do: []

  def expenses(month) do
    last = length(month.rows) - 1

    rows =
      month.rows
      |> Enum.with_index()
      |> Enum.map(fn {row, i} -> Kati.Screens.MoneyFa.expense_row(row, i == last) end)

    label = BookDetailFa.fa(month.label, 11, Palette.eyebrow(), weight: "semibold")
    total = BookDetailFa.fa(month.total, 14, :on_surface)
    delta = Kati.Screens.MoneyFa.delta(month)
    rule = SettingsList.hairline(true)

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        padding={17}
        shadow={Theme.shadow_card_soft()}
      >
        <Row fill_width={true} align="center">
          {label}
          <Spacer weight={1.0} />
          {total}
          {delta}
        </Row>
        <Spacer size={12} />
        {rule}
        <Spacer size={4} />
        {rows}
      </Column>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  The month-on-month change, in the pill 127 draws, or nothing for a month with
  nothing before it.

  `Kati.Screens.Money.delta/1` draws a bare glyph and a mono figure; both
  frames draw them inside a 28pt chip at radius 14 on `green_wash`, the
  drawing's own 16% — see the moduledoc on which of the two wins. Green and
  `arrow_downward` for a month that fell, red and `trending_up` for one that
  rose, which is 122's own mapping and the only part of that function this
  could keep.

  The drawing only ever shows the green case, so the red ground is chosen
  rather than measured: `red_wash_strong` is the token whose own doc calls it a
  status pill's ground, and it is 14% where its green twin is 16%. Two washes a
  couple of points apart are the nearest honest pairing the palette holds, and
  neither is a hex literal invented for one chip.

  `Kati.UI.chip/2` cannot draw it: `MishkaChip` takes its label as a prop and
  paints it in the chip's own family, and `expand/3` discards children, so a
  Persian figure through that door is a row of empty boxes. Hand-rolled at the
  drawing's geometry until the component grows a content slot — the single
  upstream ask `Kati.Screens.Fa`'s moduledoc records.
  """
  @spec delta(map()) :: map() | []
  def delta(%{delta: nil}), do: []

  def delta(month) do
    up? = month.direction == :up
    icon = if up?, do: "trending_up", else: "arrow_downward"
    colour = if up?, do: Palette.red(), else: Palette.green_text()
    ground = if up?, do: Palette.red_wash_strong(), else: Palette.green_wash()

    glyph = UI.symbol(icon, size: 14, color: colour)
    figure = BookDetailFa.fa(month.delta, 11.5, colour)

    ~MOB"""
    <Row align="center">
      <Spacer size={10} />
      <Row
        height={28}
        corner_radius={14}
        background={ground}
        padding_left={11}
        padding_right={11}
        align="center"
      >
        {glyph}
        <Spacer size={5} />
        {figure}
      </Row>
    </Row>
    """
  end

  @doc """
  One expense: what it was, when and under which section, and what it cost.

  Not `Kati.UI.SettingsList.row/4`, and the reason is one number. That function
  puts a 13pt gap after its leading slot whether or not there is anything in
  it, which is right inside a card padded at 15 and wrong inside this one,
  padded at 17: the drawing runs the title all the way to the card's own
  padding. The hairline is still `Kati.UI.SettingsList.hairline/1`, so the rule
  between rows is the same `MishkaSeparator` box every other list in the app
  draws and not a second hand-rolled line.

  The section is the whole classification this page has — screen 122's caption
  forbids categories by name — so the meta line is the row's only label and it
  carries the date with it.
  """
  @spec expense_row(map(), boolean()) :: map()
  def expense_row(expense, last?) do
    name = BookDetailFa.fa(expense.name, 13, :on_surface, weight: "semibold")
    meta = BookDetailFa.fa(expense.meta, 11, Palette.tertiary())
    amount = BookDetailFa.fa(expense.amount, 12.5, :on_surface)
    rule = SettingsList.hairline(not last?)

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_top={12} padding_bottom={12}>
        <Column weight={1.0}>
          {name}
          <Spacer size={4} />
          {meta}
        </Column>
        <Spacer size={12} />
        {amount}
      </Row>
      {rule}
    </Column>
    """
  end

  @doc """
  The one piece of advice this app gives, or nothing once it is dismissed.

  One sentence, about one service, with one saving — and it offers to *remind*
  rather than to act, because Kati cannot cancel a subscription and would be
  lying if it implied otherwise.

  The two figures inside it, `۶ ساعت` and `۱۳٫۹۹ پوند`, are written out rather
  than computed, exactly as `Kati.Money.Sample.suggestion/0` writes `6 hours`
  and `£13.99` into the English one. That is one sentence per language with one
  owner each, and the day either becomes a real reading of
  `Kati.Money.per_hour/2`'s two inputs, both do.

  The paragraph is set at **1.85**, which is the drawing's own leading and far
  above the 1.55 the English card takes. Arabic-script letters carry dots above
  the baseline and descenders below it, so a Persian paragraph at a Latin
  paragraph's leading collides with itself — the finding
  `Kati.Screens.MyServicesFa.consequence/2` records at 1.7 for a two-line
  sub-line and `Kati.Screens.AlbumDetailFa.note/1` at 1.9 for a cream note.

  `Kati.UI.rich_text/1` flattens the two bold runs into the base style, because
  a `Text` carries one weight and the bridge has no `AnnotatedString` path yet;
  that function's own doc has the shape of the fix. The strings are all here
  either way, which is what the sentence is for.
  """
  @spec suggestion(boolean()) :: map() | []
  def suggestion(true), do: []

  def suggestion(false) do
    body = [
      font_family: "fa",
      text_size: 12.5,
      line_height: 1.85,
      text_color: Palette.cream_body()
    ]

    strong = [font_family: "fa", font_weight: "semibold", text_color: Palette.cream_ink()]

    sentence =
      UI.rich_text([
        {@copy.suggestion_lead <> " ", body},
        {@copy.suggestion_hours, strong},
        {" " <> @copy.suggestion_middle <> " ", body},
        {@copy.suggestion_titles, strong},
        {" " <> @copy.suggestion_tail, Keyword.put(body, :base, true)}
      ])

    glyph = UI.symbol("lightbulb", size: 19, color: Palette.accent())
    action = BookDetailFa.fa(@copy.remind, 12.5, Palette.on_ink(), weight: "semibold")
    dismiss = BookDetailFa.fa(@copy.dismiss, 12.5, Palette.ink_soft(), weight: "semibold")

    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.cream()}
      corner_radius={22}
      padding={17}
      shadow={Theme.shadow_card_soft()}
    >
      <Row fill_width={true} align="top">
        {glyph}
        <Spacer size={11} />
        <Column weight={1.0}>
          {sentence}
        </Column>
      </Row>
      <Spacer size={15} />
      <Row fill_width={true} align="center">
        <Row
          weight={1.0}
          height={40}
          corner_radius={20}
          background={Palette.ink_fill()}
          align="center"
          on_tap={{self(), :remind_me}}
        >
          <Spacer weight={1.0} />
          {action}
          <Spacer weight={1.0} />
        </Row>
        <Spacer size={9} />
        <Row
          height={40}
          corner_radius={20}
          background={Palette.paper()}
          padding_left={15}
          padding_right={15}
          align="center"
          on_tap={{self(), :dismiss}}
        >
          {dismiss}
        </Row>
      </Row>
    </Column>
    """
  end

  @doc """
  `£46.47` as this page prints it: `۴۶٫۴۷ پوند`.

  The digits and the separators are CLDR's, the position of the word is CLDR's,
  and only the word itself is this file's — the moduledoc has all three at
  length, including why `format: :currency` is the wrong pattern to ask for in
  `fa`.

  It takes the *formatted* string rather than the pence, the way
  `Kati.Screens.MyServicesFa.amount/1` does, so the number still has exactly
  one owner: `Kati.Money.format/2` decides how many decimals an amount gets and
  which currency it is in, and this decides nothing but which glyphs those
  characters are drawn with. Anything that will not parse as a number comes
  back with its digits folded and nothing else touched, which is how the em
  dash for an unwatched service survives.

  The word is a parameter with `word/0` as its default so that a builder
  printing several figures resolves it **once**. `Kati.Money.currency/0` reads
  `Mob.State`, which is `:dets` and so a file read rather than a map lookup,
  and this page prints fifteen figures a frame — the same arithmetic
  `Kati.UI.symbol/2`'s doc does for `Kati.Theme.mode/0` and reaches the same
  answer: not once per glyph.
  """
  @spec money(String.t(), String.t()) :: String.t()
  def money(text, word \\ word()) when is_binary(text) do
    case decimal(text) do
      nil -> Digits.to_persian(text)
      value -> localised(value) <> " " <> word
    end
  end

  @doc """
  The same figure without its currency word: `£12.10` becomes `۱۲٫۱۰`.

  The drawing prints the word on every figure that stands on its own — the hero
  total, the amount inside the hero's sentence, the three service prices, the
  month total — and drops it from every figure that sits beneath one of those:
  the per-hour rates, the month's delta, and the four expense amounts. That is
  a good rule as well as the drawing's. A column of amounts under a total in
  the same currency does not need the currency four more times, and the rate
  already says its own unit.
  """
  @spec figure(String.t()) :: String.t()
  def figure(text) when is_binary(text) do
    case decimal(text) do
      nil -> Digits.to_persian(text)
      value -> localised(value)
    end
  end

  @doc """
  `£0.21/h` becomes `۰٫۲۱/ساعت`.

  No currency word, because the rate sits directly under the price that already
  carries one, and no space before the slash, because the drawing sets none.
  A rate that is an em dash — a service paid for and not watched, where the
  figure is undefined and `Kati.Money.per_hour/2` refuses to invent one — has
  no slash in it and comes back unchanged.
  """
  @spec per_hour(String.t()) :: String.t()
  def per_hour(text) when is_binary(text) do
    case String.split(text, "/") do
      [amount, _unit] -> figure(amount) <> @copy.per_hour
      _other -> figure(text)
    end
  end

  @doc """
  The currency word for the amount every figure on this page is in.

  `Kati.Money.currency/0` is the app's one display currency — screen 125
  changes it and no stored figure moves — so every figure on the page prints
  the same word and it is resolved once per builder rather than once per
  figure; `money/2` says why that distinction is worth an argument.

  A code outside the five screen 125 offers falls back to CLDR's own Persian
  name for it — `فرانک سوئیس` for `CHF` — which is wider than the drawing and
  right, and a currency CLDR has nothing to say about falls back again to
  `Kati.Money.symbol/1`, which answers the code itself. Three steps, and each
  is worse-looking and still true; none of them is a crash on a screen that is
  only trying to print a price.
  """
  @spec word() :: String.t()
  def word do
    code = Kati.Money.currency()
    Map.get_lazy(@currency_words, code, fn -> Kati.Screens.MoneyFa.cldr_word(code) end)
  end

  @doc """
  CLDR's Persian name for a currency, or its symbol.

  Read out of `Kati.Cldr.Currency` rather than formatted out of a number
  through the `¤¤¤` pattern, because the name is what is wanted and stripping
  digits back off a formatted string would be the same answer arrived at
  fragilely.
  """
  @spec cldr_word(String.t()) :: String.t()
  def cldr_word(code) do
    case Kati.Cldr.Currency.currency_for_code(code, locale: "fa") do
      {:ok, %{name: name}} when is_binary(name) -> name
      _other -> Kati.Money.symbol(code)
    end
  rescue
    _error -> Kati.Money.symbol(code)
  end

  # `"£46.47"` → `Decimal.new("46.47")`, or nil for anything that is not a
  # figure. `Kati.Screens.MyServicesFa.split_symbol/1` peels the leading symbol
  # — it already knows the three the drawings use — and `Decimal.parse/1` is
  # required to consume the whole remainder, so a string with a stray suffix
  # falls through to the digit fold rather than being silently truncated.
  defp decimal(text) do
    {_symbol, digits} = MyServicesFa.split_symbol(text)

    case Decimal.parse(String.trim(digits)) do
      {value, ""} -> value
      _other -> nil
    end
  end

  # The figure alone, through CLDR at `locale: "fa"`. `fractional_digits: 2`
  # rather than a `"#,##0.00"` format string, because the standard pattern is
  # one of the three `Kati.Cldr` precompiles and a literal would be compiled at
  # runtime on every frame — ex_cldr logs a warning saying exactly that.
  defp localised(value) do
    case Kati.Cldr.Number.to_string(value, locale: "fa", fractional_digits: 2) do
      {:ok, formatted} -> formatted
      _other -> value |> Decimal.to_string() |> Digits.to_persian()
    end
  rescue
    _error -> value |> Decimal.to_string() |> Digits.to_persian()
  end

  @doc """
  The taps.

  Two destinations, and one of them leaves Persian — see the moduledoc for why
  the service rows go to screen 97 rather than to 122's own
  `Kati.Screens.Subscriptions`, and why the reminder still pushes an English
  screen instead of going dead. Anything unrecognised leaves the screen as it
  was rather than raising in a tap handler, which Mob does not catch.
  """
  @spec handle_info(term(), Mob.Socket.t()) :: {:noreply, Mob.Socket.t()}
  def handle_info({:tap, :back}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}

  def handle_info({:tap, :remind_me}, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.ReleaseWatcher)}

  def handle_info({:tap, :dismiss}, socket),
    do: {:noreply, Mob.Socket.assign(socket, :dismissed?, true)}

  # Every ledger row, by its own service name — see
  # `Kati.Screens.Money.subscription_tag/1`. Last, inside the clause that
  # already swallowed everything else: written as a clause of its own above,
  # it shadowed `:remind_me` and `:dismiss` and neither would have fired.
  #
  # Screen 97, not a Persian screen 23. `Kati.Screens.SubscriptionsFa` was
  # written here and has never existed: no such file, no `Kati.Screens.Gallery`
  # entry, and the name appeared nowhere else in `lib/` or `test/`. Nothing on
  # the host could say so — `Mob.Socket.push_screen/2` only records
  # `{:push, dest, params}`, so the tap sweep saw a well-formed nav action and
  # the reachability walk saw a graph node it then intersected away for not
  # being a drawing. `Mob.Screen.apply_nav_action/3` is what calls
  # `mount/3`, and it does it on the device, so the ledger died there and
  # nowhere else.
  #
  # The destination is the one the moduledoc names at 168-175 and the one
  # screen 62's سرویس‌ها row already opens (`settings_fa.ex:522`):
  # `Kati.Screens.MyServicesFa`, gallery screen 97 and 92's Persian mirror,
  # which is what 122's own `info` line means when it says prices are owned by
  # 92. It carries nothing, the same way 122's rows carry nothing —
  # `MyServicesFa.mount/3` ignores its params, and the per-row tag is identity
  # for the sake of being addressable rather than for routing
  # (`money.ex:459-464`).
  #
  # The clause that used to sit two above this one — `:open_services` →
  # `MyServicesFa` — is deleted with this change. It was the pre-rename
  # handler: #97 gave every row its own name through
  # `Kati.Screens.Money.subscription_tag/1`, so nothing on 127 has drawn
  # `:open_services` since, and a correct push to the right screen sitting on a
  # path no tap takes is what kept this line looking answered.
  def handle_info({:tap, tag}, socket) when is_atom(tag) do
    if String.starts_with?(Atom.to_string(tag), "open_subscriptions_") do
      {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.MyServicesFa)}
    else
      {:noreply, socket}
    end
  end

  def handle_info({:tap, _tag}, socket), do: {:noreply, socket}
  def handle_info(_message, socket), do: {:noreply, socket}
end
