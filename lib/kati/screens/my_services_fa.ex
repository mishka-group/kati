defmodule Kati.Screens.MyServicesFa do
  @moduledoc """
  Screen 97 — سرویس‌های من, the Persian mirror of My services, pushed under
  تنظیمات.

  Screen 92's page in the mirror. `Kati.Services` is read unchanged — the same
  region, the same three rules, the same two service tiers — and what this file
  supplies is the Persian half: the labels, the consequence sentences, and the
  numerals. `Kati.Screens.SeriesFa`'s doctrine applied to an account: *one
  list, read once, presented twice.*

  ## Three things the caption pins, and each is a real decision

    * **Provider names stay Latin.** `Lumen+`, `Orbit`, `Kino`, `Aria Free`
      and `Dispatch` are trade names, not copy, so nothing here translates or
      transliterates one — the same rule `Kati.Screens.DataSourcesFa` applies
      to providers and licences. They are set in Vazirmatn rather than DM Mono
      because the drawing sets them there and because Vazirmatn carries the
      Latin alphabet perfectly; nothing about a trade name asks for the mono
      face. Their initials go through `Kati.Screens.MyServices.badge_tile/1`
      untouched: a badge is one Latin capital, the one string on this sheet
      that is the *same string* in both languages.

    * **Prices keep DM Mono with Persian digits — and they cannot.** This is
      the standing trade every mirror makes, counted in `Kati.Screens.Fa`'s
      moduledoc: `kati_mono.ttf` carries **zero** of U+06F0–U+06F9, so `۸٫۹۹`
      in the mono face is four empty boxes and a separator. `amount/1` sets it
      in `fa` at the drawing's 12.5 in ink. The face is wrong and the glyphs
      are right, which is the better half of an unwinnable trade.

      The caption's other half — *so the price column still aligns under a
      mirrored layout* — survives, but not for the reason the caption gives.
      Vazirmatn is proportional and does not measure `۸` and `۱۳` alike. What
      holds the column is `price_chip/1`: every chip is laid against the row's
      own trailing edge by `Kati.UI.SettingsList.row/4`, so the prices share
      the edge the eye runs down even though the face does not.

      The separator is **U+066B** (`٫`) rather than a full stop, and it is not
      decoration. `Kati.I18n.Digits` already folds it back — `parse_float/1`
      answers `{8.99, ""}` for `"۸٫۹۹"` — so a price printed here is a price
      that can be typed back in.

    * **Consequence lines carry Vazirmatn's taller line-height.** The three
      rule sub-lines are set at **1.7** where screen 92's are at 1.5, and that
      is why each rule row runs deeper here. Arabic-script letters carry dots
      above the baseline and descenders below it, and at English leading the
      dots of one line land in the descenders of the line above.
      `Kati.Screens.BookDetailFa.fa/4` pins 1.4, which is right for a label and
      wrong for a block, so `consequence/2` is this file's own `Text` — the
      same split `Kati.Screens.DataSourcesFa.paragraph/2` makes at 1.85 for a
      cream note.

  ## Persian digits are for quantities, Latin digits are for screen numbers

  `مشترک هستم · ۳`, `نمایش همه ۴۷` and `۴۶٫۴۷ £` fold; the `23` in the
  ownership footnote does not. A screen number is an identifier in this
  repository rather than a count of anything, so it is left alone for the same
  reason a provider's name is — and `Kati.I18n.Digits.to_persian/1` is applied
  to the number, never to the sentence, so there is nowhere for the two to be
  confused.

  ## Two glyphs point opposite ways, and both are right

  `arrow_forward_ios` on the back pill, `chevron_left` on the three rows that
  push. In Persian, back is rightwards and forward is leftwards, and Material
  Symbols are text in a font, which nothing auto-mirrors. Screens 62, 69 and 82
  record the same pair; flipping one and not the other is the commonest RTL bug
  there is.

  ## Why this is not `use Kati.Screens.Pushed`

  That macro draws the back pill itself, with `arrow_back_ios_new` and a `Text`
  carrying no `font_family` — a left-pointing chevron beside a row of empty
  boxes. It also takes its direction from `Kati.Locale.direction_prop/0`, which
  is the *app's* locale, so a Persian mirror opened while the app is set to
  English would draw Persian copy in a left-to-right grid. So this is
  `Kati.Screens.Fa.pushed_frame/1` with a hand-rolled pill, exactly as screens
  69, 72 and 82 are, and `content/1` still exists so the shape matches every
  other pushed screen.

  ## What is taken from screen 92, and the rule that decides

  **Screen 92's builder is called wherever the fonts allow it, even where that
  builder and the drawing disagree.** A mirror that corrected a number on one
  side only would make the two sheets diverge, and the drift is 92's to fix
  once for both. So `Kati.Screens.MyServices.listed/0` supplies both groups,
  `badge_tile/1` the initials, `flag_tile/1` the country tile, and
  `Kati.UI.SettingsList.icon_tile/1` the `more_horiz` and `payments` tiles at
  92's 30pt rather than at the drawing's 40 — the day 92 re-measures that tile,
  this sheet follows for free.

  What the fonts refuse is everything that carries a Persian word:
  `Kati.UI.SettingsList.body/3`, `title/3` and `note/2` all build their own
  `Text` and leave `font_family` off, and no component in `Kati.Components`
  accepts it either. Those are rebuilt here — and, being rebuilt, they are
  rebuilt to the drawing rather than to 92's code, which is why three things
  look different from the English sheet as it stands today:

    * the search field is the drawing's 46 at radius 23, where 92's code
      rounded it to 48 at 24;
    * a price sits in the drawing's bordered chip with the service's switch
      beside it, where 92's code draws bare mono text and no switch at all;
    * the monthly total is the money row's **sub-line**, where 92's code hangs
      it in the trailing slot. Persian has no case, so it is not upper-cased
      either.

  ## The region default is this sheet's, and it costs something

  `Kati.Services.region/0` answers `"GB"` until somebody says otherwise, and
  its own doc says why: that is the region the *English* drawings were captured
  in. Screen 97 was captured in Iran, and a Persian mirror that answers
  *available* for the United Kingdom before anyone has chosen is answering for
  the wrong country. `region/0` here therefore substitutes `"IR"` for that
  default and passes every other code through untouched.

  The cost is stated rather than hidden: a Persian reader who deliberately
  picks the United Kingdom is shown ایران, because `Kati.Services` cannot
  currently tell a stored `"GB"` from an unset one. The upstream ask is one
  function — a `region_chosen?/0`, or a default that reads `Kati.Locale` — and
  recording it is what `Kati.Screens.Fa`'s moduledoc does with the three
  components that need a content slot.

  ## Three chevron rows are inert, and one field is

  کشور, نمایش همه ۴۷ and the money row all push screens that exist only in
  English — `Kati.Screens.CountryPicker` and `Kati.Screens.Subscriptions` — and
  `Kati.Screens.Fa`'s moduledoc has already thrown away one such stand-in for
  changing the app's language, and RTL with it, out from under the reader. So
  they carry no `on_tap`: `Kati.Screens.SettingsFa` states the rule this
  follows, that a row which lights up and goes nowhere is a worse promise than
  a row that does nothing. The search field is drawn as a placeholder on both
  sheets and filters this list rather than opening a screen; the filtering is
  not built, so nothing is wired to it.

  ## The service switches are the drawing's state, and nothing owns them yet

  `Kati.Services.Service` has a `tier` and a `paused`, and neither is this
  control: `paused` means a subscription on hold, and a free-with-ads service
  drawn **off** is not paused. Screen 92 renders no switch at all, so there is
  no English behaviour to mirror. The value is therefore the screen's own,
  seeded exactly as both drawings paint it — subscribed on, free off — and
  flipped in place, so the control is a control rather than a picture of one.
  When 92 grows an owner for it, this reads that owner instead.

  ## The copy is a proposal

  Screens 72 and 82 say it and it is true here: every Persian string below was
  open, and these are proposals. They live in `@copy` and `@rules` rather than
  scattered through the markup so that a native reader corrects each one once.
  """

  use Mob.Screen
  import Mob.Sigil

  alias Kati.I18n.Digits
  alias Kati.Screens.BookDetailFa
  alias Kati.Screens.DataSourcesFa
  alias Kati.Screens.Fa
  alias Kati.Screens.MyServices
  alias Kati.Screens.SettingsFa
  alias Kati.Services
  alias Kati.Services.Sample
  alias Kati.Theme
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  # Everything that is not a trade name, a screen number or a figure the app
  # already knows.
  @copy %{
    back: "تنظیمات",
    title: "سرویس‌های من",
    subtitle: "تا کاتی فقط چیزی را نشان دهد که می‌توانید ببینید.",
    region: "کشور",
    region_why: "معنای «در دسترس» را تعیین می‌کند",
    availability:
      "دسترسی به محتوا کشور به کشور متفاوت است. گفتن اینکه فیلمی در دسترس است وقتی فقط " <>
        "در کشور دیگری پخش می‌شود، از نگفتن بدتر است.",
    search: "جست‌وجوی سرویس‌ها",
    subscribed: "مشترک هستم",
    owner: "قیمت‌ها اینجا نگه داشته می‌شوند و 23 آن‌ها را می‌خواند.",
    free: "رایگان با تبلیغ",
    not_mine: "مال من نیست",
    show_all: "نمایش همه",
    rules: "قواعد",
    money: "مالی",
    services: "سرویس",
    a_month: "در ماه"
  }

  # The seven countries `Kati.Services.countries/0` offers, in Persian. Keyed by
  # its codes and consulted beside its list rather than replacing it, so a code
  # with no entry here falls back to the English name instead of vanishing —
  # the same fallback `Kati.Screens.DataSourcesFa.localise/1` makes for a
  # provider.
  @countries %{
    "GB" => "بریتانیا",
    "IR" => "ایران",
    "US" => "ایالات متحده",
    "DE" => "آلمان",
    "FR" => "فرانسه",
    "NL" => "هلند",
    "AU" => "استرالیا"
  }

  # Each rule with the sentence that says what it does, keyed by
  # `Kati.Services.rules/0`'s own keys so the two cannot drift. The sentence is
  # not optional copy: the third rule silently empties three other screens,
  # which is exactly why it names them — and names what it leaves alone,
  # because "پنهان" beside a library is a frightening word.
  @rules [
    {:rentals, "کرایه را در دسترس بشمار",
     "فیلمی که باید کرایه کنید هم در «چه چیزی جا می‌شود» می‌آید."},
    {:purchases, "خرید را در دسترس بشمار", "عنوان‌هایی که باید بخرید هم شمرده می‌شوند."},
    {:hide_unavailable, "چیزهایی که نمی‌توانم ببینم پنهان شوند",
     "از کشف، بعدی و «چه چیزی جا می‌شود» حذف می‌شوند. کتابخانه و فهرست آرزو دست‌نخورده می‌مانند."}
  ]

  def mount(_params, _session, socket) do
    Kati.Theme.activate()
    services = MyServices.listed()

    {:ok,
     socket
     |> Mob.Socket.assign(:services, services)
     |> Mob.Socket.assign(:on, MapSet.new(Enum.map(services.subscribed, & &1.name)))
     |> Mob.Socket.assign(:rules, Services.rules())
     |> Mob.Socket.assign(:region, Kati.Screens.MyServicesFa.region())}
  end

  def render(assigns), do: Fa.pushed_frame(content(assigns), Kati.Screens.Identity.of(__MODULE__))

  @doc """
  The page, in the order 97 stacks it.

  Three accent eyebrows and three muted ones. `Kati.Screens.Fa.eyebrow/1` only
  ever draws the orange dash — orange means new or now — so the grey one comes
  from `Kati.Screens.SettingsFa.eyebrow/2`, which is the same recipe with the
  dash swapped. Orange marks the three sections you set up (کشور, the account
  you pay for, قواعد); grey marks the three that are a footnote to them.
  """
  @spec content(map()) :: map()
  def content(assigns) do
    # `c` rather than `@copy` inside the markup: the sigil reads `@name` as an
    # assign, the way `Kati.Screens.DataSourcesFa.content/1` does it.
    c = @copy
    services = assigns.services
    on = assigns.on
    subscribed = Kati.Screens.MyServicesFa.subscribed_label(services.subscribed)

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {Kati.Screens.MyServicesFa.chrome()}
        {Kati.Screens.MyServicesFa.title()}
        {Fa.eyebrow(c.region)}
        {Kati.Screens.MyServicesFa.region_group(assigns.region)}
        {Kati.Screens.MyServicesFa.search_field()}
        {Fa.eyebrow(subscribed)}
        {Kati.Screens.MyServicesFa.service_group(services.subscribed, on, 0)}
        {Kati.Screens.MyServicesFa.owner_note()}
        {SettingsFa.eyebrow(c.free, :muted)}
        {Kati.Screens.MyServicesFa.service_group(services.free, on, length(services.subscribed))}
        {SettingsFa.eyebrow(c.not_mine, :muted)}
        {Kati.Screens.MyServicesFa.catalogue_group()}
        {Fa.eyebrow(c.rules)}
        {Kati.Screens.MyServicesFa.rules_group(assigns.rules)}
        {SettingsFa.eyebrow(c.money, :muted)}
        {Kati.Screens.MyServicesFa.money_group(services.subscribed)}
      </Column>
    </Scroll>
    """
  end

  @doc """
  The back pill, with the chevron pointing the way the reader came from.

  Hand-rolled for the reason the moduledoc gives about `Kati.Screens.Pushed`,
  and identical in every number to screens 69 and 82's: 44 tall at radius 22,
  card white under the button shadow, 12 of padding on the leading edge and 16
  on the trailing one so the glyph sits closer to the edge than the word does.
  """
  @spec chrome() :: map()
  def chrome do
    label = @copy.back
    word = BookDetailFa.fa(label, 13.5, :on_surface, weight: "semibold")
    chevron = UI.symbol("arrow_forward_ios", size: 17)

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
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc """
  The screen title over its one-line subtitle.

  Not `Kati.UI.SettingsList.title/3`, and not only because it typesets in Plus
  Jakarta Sans: it sets the title at 28 with -.03em of tracking and the sub in
  DM Mono at 11. Persian wants none of the three — letter-spacing breaks the
  joins between Arabic-script letters — so this is the drawing's 25 at a 1.4
  leading with no tracking, over a Vazirmatn sub at 12.5 in `muted`.
  """
  @spec title() :: map()
  def title do
    heading = BookDetailFa.fa(@copy.title, 25, :on_surface, weight: "bold")
    sub = BookDetailFa.fa(@copy.subtitle, 12.5, Palette.muted(), lines: 2)

    ~MOB"""
    <Column fill_width={true}>
      {heading}
      <Spacer size={5} />
      {sub}
      <Spacer size={20} />
    </Column>
    """
  end

  @doc """
  The country this sheet answers *available* for.

  `Kati.Services.region/0`, with one substitution: its `"GB"` is a default
  rather than a choice — its own doc says so, and the drawings it names are the
  English ones. Screen 97 was captured in Iran. See the moduledoc for what the
  substitution costs and the one function upstream that would remove it.
  """
  @spec region() :: String.t()
  def region do
    case Services.region() do
      "GB" -> "IR"
      code -> code
    end
  end

  @doc """
  A country's name in Persian, or `Kati.Services`' own name for one this file
  has never heard of.

  An English row is a poor row and a country silently missing from the Persian
  build is not a row at all — the same fallback
  `Kati.Screens.DataSourcesFa.localise/1` makes for a provider.
  """
  @spec region_name(String.t()) :: String.t()
  def region_name(code), do: Map.get(@countries, code, Services.region_name(code))

  @doc """
  The country row, and the sentence that says why it is first.

  The list below it is meaningless without it, which is screen 92's reasoning
  and stands unchanged. The tile is `Kati.Screens.MyServices.flag_tile/1`: a
  flag is an emoji pair out of the system emoji font, so it is sized rather
  than coloured, and it is the same node on both sheets because a flag does not
  translate.
  """
  @spec region_group(String.t()) :: map()
  def region_group(code) do
    tile = MyServices.flag_tile(Services.flag(code))
    name = Kati.Screens.MyServicesFa.region_name(code)
    body = Kati.Screens.MyServicesFa.body(name, @copy.region_why)

    card =
      SettingsList.card([
        SettingsList.row(tile, body, SettingsList.trailing(Kati.Screens.MyServicesFa.chevron()),
          rule: false
        )
      ])

    note = DataSourcesFa.note(@copy.availability)

    ~MOB"""
    <Column fill_width={true}>
      {card}
      <Spacer size={11} />
      {note}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  The disclosure chevron, pointing the way a push goes.

  `chevron_left` and not `Kati.UI.SettingsList.chevron/0`'s `chevron_right`: a
  row that opens something opens it in the reading direction, and in Persian
  that is leftward. Everything else about it is that function's — 18pt in
  `rail_idle`, which is the value the drawing gives even though the token's
  name is about a timeline rail.
  """
  @spec chevron() :: map()
  def chevron, do: UI.symbol("chevron_left", size: 18, color: Palette.rail_idle())

  @doc """
  The search field, which filters the list rather than opening a screen.

  The drawing's own geometry: 46 tall at radius 23, 16 of side padding, a 19pt
  glyph and a 13.5pt placeholder, both in `muted`. Nothing is wired to it — see
  the moduledoc on the four inert controls.
  """
  @spec search_field() :: map()
  def search_field do
    glyph = UI.symbol("search", size: 19, color: Palette.muted())
    placeholder = BookDetailFa.fa(@copy.search, 13.5, Palette.muted())

    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        height={46}
        corner_radius={23}
        background={Palette.card()}
        shadow={Theme.shadow_card_soft()}
        padding_left={16}
        padding_right={16}
        align="center"
      >
        {glyph}
        <Spacer size={10} />
        {placeholder}
      </Row>
      <Spacer size={18} />
    </Column>
    """
  end

  @doc """
  The subscribed eyebrow, carrying the count of what is actually listed.

  The count folds to Persian digits because it is a quantity; the `·` is the
  drawing's own U+00B7 and is not a numeral, so it is left alone.
  """
  @spec subscribed_label([map()]) :: String.t()
  def subscribed_label(services) do
    @copy.subscribed <> " · " <> Digits.to_persian(length(services))
  end

  @doc """
  A group of services: the initial, the name, the price where there is one, and
  the switch.

  `offset` is where this group starts in the two groups laid end to end, so
  each row's tap tag names a position in one list rather than a position in a
  group whose length the handler would have to know.
  """
  @spec service_group([map()], MapSet.t(), non_neg_integer()) :: map()
  def service_group(services, on, offset) do
    last = length(services) - 1

    rows =
      services
      |> Enum.with_index()
      |> Enum.map(fn {service, i} ->
        Kati.Screens.MyServicesFa.service_row(
          service,
          MapSet.member?(on, service.name),
          offset + i,
          rule: i < last
        )
      end)

    card = SettingsList.card(rows)

    ~MOB"""
    <Column fill_width={true}>
      {card}
      <Spacer size={11} />
    </Column>
    """
  end

  @doc """
  One service row.

  The whole row is the tap target, not the 46pt track — `Kati.Screens.SettingsFa`
  gives the reason and screen 24 does the same: the row already reads as one
  object, and a switch is a small thing to hit.

  The name is Vazirmatn rather than DM Mono even though every one of these is
  Latin, because the drawing sets it there and because a trade name is a word
  in a sentence, not a machine's name for itself — which is the line
  `Kati.Screens.DataSourcesFa.name/1` draws in the other direction for `TMDB`.
  """
  @spec service_row(map(), boolean(), non_neg_integer(), keyword()) :: map()
  def service_row(service, on?, index, opts \\ []) do
    switch = SettingsList.switch(on?)

    trailing =
      case Kati.Screens.MyServicesFa.amount(service.price) do
        nil ->
          switch

        price ->
          chip = Kati.Screens.MyServicesFa.price_chip(price)

          ~MOB"""
          <Row align="center">
            {chip}
            <Spacer size={13} />
            {switch}
          </Row>
          """
      end

    SettingsList.row(
      MyServices.badge_tile(service.badge),
      BookDetailFa.fa(service.name, 13, :on_surface, weight: "semibold"),
      SettingsList.trailing(trailing),
      rule: Keyword.get(opts, :rule, true),
      on_tap: {self(), String.to_atom("service_#{index}")}
    )
  end

  @doc """
  A price in its own bordered chip: 32 tall at radius 11, paper, 11 either side.

  The frame is the drawing's, and screen 92 draws it too even though 92's code
  prints bare text — see the moduledoc's rule about which of the two wins when
  a node has to be rebuilt anyway. It is a frame rather than a plain figure
  because this is the screen that *owns* the price: 92's caption calls these
  editable fields here and read-only on 23, and a field looks like a field.

  The border is `hairline_strong` — 10% ink where the drawing writes 9% — and
  no token is nearer. It is the one mapping here that is right by value and
  wrong by name, which is the same trade `Kati.UI.SettingsList.chevron/0`
  records for `rail_idle`: a rule and a border at the same alpha are the same
  colour, whatever the token is called.
  """
  @spec price_chip(String.t()) :: map()
  def price_chip(price) do
    text = BookDetailFa.fa(price, 12.5, :on_surface)

    ~MOB"""
    <Row
      height={32}
      corner_radius={11}
      background={Palette.paper()}
      border_color={Palette.hairline_strong()}
      border_width={1.5}
      padding_left={11}
      padding_right={11}
      align="center"
    >
      {text}
    </Row>
    """
  end

  @doc """
  A price as this sheet prints it: `£8.99` becomes `۸٫۹۹ £`.

  Three things happen and each is the drawing's. The digits fold to
  U+06F0–U+06F9; the decimal point becomes **U+066B**, which is the separator
  `fa` actually uses and the one `Kati.I18n.Digits.parse_float/1` folds back;
  and the currency symbol moves to the trailing edge, because that is where the
  drawing puts it.

  It takes the formatted string rather than the pence, so the number still has
  exactly one owner. `Kati.Services.Service.price/1` decides how many decimals
  a price gets and which symbol it carries; this decides nothing but which
  glyphs those characters are drawn with. A currency code Kati has no symbol
  for passes through with its code where it was.
  """
  @spec amount(String.t() | nil) :: String.t() | nil
  def amount(nil), do: nil

  def amount(price) when is_binary(price) do
    {symbol, digits} = Kati.Screens.MyServicesFa.split_symbol(price)
    persian = digits |> Digits.to_persian() |> String.replace(".", "٫")
    String.trim(persian <> " " <> symbol)
  end

  @doc "A price split into its leading currency symbol and the rest, if it has one."
  @spec split_symbol(String.t()) :: {String.t(), String.t()}
  def split_symbol(<<symbol::utf8, rest::binary>>) when symbol in [?£, ?$, ?€],
    do: {<<symbol::utf8>>, rest}

  def split_symbol(price), do: {"", price}

  @doc """
  The footnote that says which screen owns these prices.

  A bare row rather than `Kati.UI.SettingsList.note/2`'s frame: the drawing
  gives it no border and no ground, because it is a credit rather than a
  warning. Compare the availability note above, which the drawing does put on
  cream — the two footnotes on this page are deliberately different weights.
  """
  @spec owner_note() :: map()
  def owner_note, do: Kati.Screens.MyServicesFa.footnote(@copy.owner)

  @doc "A bare footnote: a 15pt `info` in `tertiary`, then the sentence at 11.5 in `sub`."
  @spec footnote(String.t()) :: map()
  def footnote(text) do
    glyph = UI.symbol("info", size: 15, color: Palette.tertiary())
    line = Kati.Screens.MyServicesFa.consequence(text, 3)

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top" padding_left={2} padding_right={2}>
        {glyph}
        <Spacer size={9} />
        <Column weight={1.0}>
          {line}
        </Column>
      </Row>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  The one row that reaches past the account: everything JustWatch lists.

  Screen 92 puts a second row under this one — *Something else*, for a service
  Kati has never heard of. The drawing for 97 does not, and this file draws the
  drawing: the row that adds a service opens a text field, and there is no
  Persian one. The count is JustWatch's own, read out of
  `Kati.Services.Sample.catalogue_count/0` rather than restated, so the two
  sheets cannot disagree about how many services exist.
  """
  @spec catalogue_group() :: map()
  def catalogue_group do
    body = Kati.Screens.MyServicesFa.body(Kati.Screens.MyServicesFa.catalogue_label(), nil)

    card =
      SettingsList.card([
        SettingsList.row(
          SettingsList.icon_tile("more_horiz"),
          body,
          SettingsList.trailing(Kati.Screens.MyServicesFa.chevron()),
          rule: false
        )
      ])

    ~MOB"""
    <Column fill_width={true}>
      {card}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  `نمایش همه ۴۷`, with the 47 taken from screen 92's own figure.

  The digits are lifted out of `Kati.Services.Sample.catalogue_count/0` rather
  than typed again, because a catalogue that grew would otherwise grow on one
  sheet only. A label with no digits in it at all answers the words alone,
  which is a worse row than a counted one and a far better one than a crash.
  """
  @spec catalogue_label() :: String.t()
  def catalogue_label do
    case Regex.run(~r/\d+/, Sample.catalogue_count()) do
      [digits] -> @copy.show_all <> " " <> Digits.to_persian(digits)
      _other -> @copy.show_all
    end
  end

  @doc """
  The three rules, each with its consequence written under it.

  Every one of them is `Kati.Services`' own key, and the toggle goes straight
  back to `Kati.Services.toggle_rule/1` — the rule set is device-level state
  and there is exactly one of it, so a rule flipped here is flipped on screen
  92 too. That is the whole point of a mirror.
  """
  @spec rules_group(map()) :: map()
  def rules_group(rules) do
    last = length(@rules) - 1

    rows =
      @rules
      |> Enum.with_index()
      |> Enum.map(fn {{key, title, why}, i} ->
        SettingsList.row(
          nil,
          Kati.Screens.MyServicesFa.body(title, why, 3),
          SettingsList.trailing(SettingsList.switch(Map.fetch!(rules, key))),
          rule: i < last,
          on_tap: {self(), String.to_atom("rule_#{key}")}
        )
      end)

    card = SettingsList.card(rows)

    ~MOB"""
    <Column fill_width={true}>
      {card}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  The link into screen 23, quoting screen 23's own figure.

  `Kati.Services.Sample.monthly_total/0` and not a sum of the three rows above
  it: the two numbers differ on purpose, and its doc explains that the row is a
  link and quotes what it links to. This sheet re-typesets that answer and
  changes nothing about it.

  The count takes no plural branch. Persian does not inflect a noun after a
  number — `۱ سرویس` and `۳ سرویس` are both correct — which is the same thing
  `Kati.Screens.DataSourcesFa.age/1` records for روز and ماه, and it is why the
  English `if count == 1` has no twin here.
  """
  @spec money_group([map()]) :: map()
  def money_group(services) do
    count = Digits.to_persian(length(services)) <> " " <> @copy.services
    total = Kati.Screens.MyServicesFa.amount(Sample.monthly_total()) <> " " <> @copy.a_month

    card =
      SettingsList.card([
        SettingsList.row(
          SettingsList.icon_tile("payments"),
          Kati.Screens.MyServicesFa.body(count, total),
          SettingsList.trailing(Kati.Screens.MyServicesFa.chevron()),
          rule: false
        )
      ])

    ~MOB"""
    <Column fill_width={true}>
      {card}
    </Column>
    """
  end

  @doc """
  A row's title over its sub-line, in Vazirmatn.

  `Kati.UI.SettingsList.body/3` draws this shape and cannot draw these words —
  it builds both `Text` nodes itself and leaves `font_family` off. The numbers
  are the drawing's: 13 over 11.5, ink over `sub`, and the gap between them
  widens from 3 to 4 when the sub-line is a paragraph rather than a phrase,
  which is the same one-point difference the drawing makes.
  """
  @spec body(String.t(), String.t() | nil, pos_integer()) :: map()
  def body(title, sub, lines \\ 1)

  def body(title, nil, _lines), do: BookDetailFa.fa(title, 13, :on_surface, weight: "semibold")

  def body(title, sub, lines) do
    heading = BookDetailFa.fa(title, 13, :on_surface, weight: "semibold")
    gap = if lines > 1, do: 4, else: 3

    line =
      if lines > 1 do
        Kati.Screens.MyServicesFa.consequence(sub, lines)
      else
        BookDetailFa.fa(sub, 11.5, Palette.sub())
      end

    ~MOB"""
    <Column fill_width={true}>
      {heading}
      <Spacer size={gap} />
      {line}
    </Column>
    """
  end

  @doc """
  A sub-line that wraps, at the leading Persian actually needs.

  **1.7**, against 1.5 for the same sentences in English on screen 92, and the
  caption names this as the reason each rule row runs deeper here.
  `Kati.Screens.BookDetailFa.fa/4` pins `line_height` at 1.4, which is right
  for a label and wrong for a block: Arabic-script letters carry dots above the
  baseline and descenders below it, and at 1.4 the dots of one line land in the
  descenders of the line above.
  """
  @spec consequence(String.t(), pos_integer()) :: map()
  def consequence(text, lines) do
    ~MOB"""
    <Text
      text={text}
      font_family="fa"
      text_size={11.5}
      line_height={1.7}
      text_color={Palette.sub()}
      max_lines={lines}
    />
    """
  end

  def handle_info({:tap, :back}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}

  def handle_info({:tap, tag}, socket) when is_atom(tag) do
    case Atom.to_string(tag) do
      # `to_existing_atom/1` rather than `to_atom/1`: the key came out of
      # `@rules`, so it already exists, and a tag that does not is a bug rather
      # than a new atom.
      "rule_" <> rule ->
        Services.toggle_rule(String.to_existing_atom(rule))
        {:noreply, Mob.Socket.assign(socket, :rules, Services.rules())}

      "service_" <> index ->
        {:noreply, Kati.Screens.MyServicesFa.toggle_service(socket, String.to_integer(index))}

      _other ->
        {:noreply, socket}
    end
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  @doc """
  Flip one service's switch, by its position in the two groups laid end to end.

  Keyed by name rather than by index once it is stored, because the index is a
  property of this render and the name is a property of the service. A position
  the list no longer has leaves the screen exactly as it was — Mob catches
  nothing thrown in a tap handler, so a stale tag must not raise.
  """
  @spec toggle_service(map(), non_neg_integer()) :: map()
  def toggle_service(socket, index) do
    services = socket.assigns.services
    on = socket.assigns.on

    case Enum.at(services.subscribed ++ services.free, index) do
      nil ->
        socket

      %{name: name} ->
        now =
          if MapSet.member?(on, name),
            do: MapSet.delete(on, name),
            else: MapSet.put(on, name)

        Mob.Socket.assign(socket, :on, now)
    end
  end
end
