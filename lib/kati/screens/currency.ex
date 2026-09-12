defmodule Kati.Screens.Currency do
  @moduledoc """
  Screen 125 — Currency, pushed under Language.

  Screen 54's Currency row finally leads somewhere.

  ## The confirmation is the point of the screen

  Not the list. The list is five rows; the screen exists for the sentence
  underneath it, and the design's caption says why in the bluntest terms it can
  find: *£8.99 becomes €8.99, not €10.42 — because a user who expects
  conversion and does not get it will think the app lost their money.*

  So the confirmation names both halves. **Changes:** the symbol and the number
  formatting, everywhere. **Does not change:** any amount you have already
  recorded. There is no code path in `Kati.Money` that rewrites a stored figure,
  which is what makes the second half true rather than aspirational.

  ## Why there is no conversion

  Kati has no server, so it cannot know what yesterday's rate was — and a
  converted history that quietly used today's rate would be worse than no
  conversion at all. That is on the page, under its own heading, because it is
  the question the screen provokes.

  ## Formatting comes from CLDR

  Persian uses U+066C for the group mark and U+066B for the decimal, arabext
  digits, and puts the currency word *after* the figure. All of that is
  `Kati.Cldr`'s, never hand-placed — a hand-placed symbol is a symbol on the
  wrong side of the number in half the world.

  ## Under `:fa`

  mishka-group/kati#103 folded the Persian mirrors away, so this page is both
  drawings now. Four things follow from that, and each is argued again where it
  happens:

    * The confirmation's figures come from `Kati.Money.display/2` rather than
      from a symbol glued onto `"8.99"`. The block above them spends a whole
      card saying the symbol is CLDR's and never hand-placed, and the crux
      sentence was the one place on the page that hand-placed one.
    * The currency names are translated in `currency_name/2` rather than where
      `Kati.Money.currencies/0` declares them, because that list is not this
      screen's to edit and a msgid frozen into a module attribute would be
      frozen into whichever locale compiled it.
    * `English` and `فارسی` stay in their own scripts, exactly as the two
      options on screens 53 and 54 do. This card is a SPECIMEN of two locales,
      and a row that named one of them in the other's script would be a
      specimen of nothing.
    * `U+066C` and `U+066B` are values rather than words. They stay Latin in
      the mono face and take `Kati.Locale.ltr/1`, so the `+` does not migrate to
      the wrong end of its own codepoint on a right-to-left line.
  """

  use Kati.Screens.Pushed, back: "Language"
  use Gettext, backend: Kati.Gettext

  alias Kati.Money
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  def load(socket) do
    socket
    |> Mob.Socket.assign(:currency, Money.currency())
    # Opens with the confirmation showing, which is the state the drawing was
    # captured in and the state that matters: the list is five rows, and the
    # screen exists for the sentence underneath it. A page that hid its own
    # subject until you tapped something would be a page whose subject most
    # people never read.
    |> Mob.Socket.assign(:confirming, Kati.Screens.Currency.other_than(Money.currency()))
  end

  @doc """
  A currency that is not the current one — the first in the list that differs.

  What the confirmation is drawn about before anything is picked. Derived
  rather than hardcoded to `EUR`, so a device already set to euros is shown a
  switch it could actually make.
  """
  @spec other_than(String.t()) :: String.t()
  def other_than(current) do
    Money.currencies()
    |> Enum.map(&elem(&1, 0))
    |> Enum.find(current, &(&1 != current))
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
        {SettingsList.title(gettext("Currency"), gettext("ONE CURRENCY, CHOSEN ONCE"))}
        {Kati.Screens.Currency.list(assigns.currency)}
        {Kati.Screens.Currency.why_not_convert()}
        {UI.eyebrow(pgettext("eyebrow", "Formatting"))}
        {Kati.Screens.Currency.formatting(assigns.currency)}
        {Kati.Screens.Currency.confirmation(assigns)}
      </Column>
    </Scroll>
    """
  end

  @doc "The five currencies, the current one ticked."
  @spec list(String.t()) :: map()
  def list(current) do
    rows =
      Enum.map(Money.currencies(), fn {code, symbol, name} ->
        SettingsList.row(
          Kati.Screens.Currency.symbol_tile(symbol),
          # The CODE stays Latin — `GBP` is an ISO 4217 identifier and the same
          # three letters in every script — and the NAME is the reader's, which
          # is `currency_name/2`'s whole job.
          SettingsList.body(code, Kati.Screens.Currency.currency_name(code, name)),
          SettingsList.trailing(Kati.Screens.Currency.tick(code == current)),
          on_tap: {self(), String.to_atom("pick_" <> code)}
        )
      end)

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.card(rows)}
      <Spacer size={12} />
      {Kati.UI.SettingsList.note("info", gettext("Kati records and shows every amount in one currency, chosen once and never converted. Changing it changes the symbol and the formatting — it does not touch a single stored figure."))}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  A currency's name in the reader's own language.

  The five names arrive as English literals off `Kati.Money.currencies/0` — a
  list this screen reads and does not own, held in a module attribute where a
  `gettext/1` would freeze into whichever locale ran `mix compile`. So the msgid
  lives here, at the one place the name is drawn, and the Latin name from the
  list is the fallback for a code this function has not been told about: a
  sixth currency added to `Kati.Money` tomorrow draws its English name rather
  than nothing.

  **A currency name is not a brand.** `Lumen+` and `TMDB` stay Latin on a
  Persian page because they are the names a service gave itself and there is no
  second spelling of them; a pound is a pound in every language that has a word
  for one, and CLDR's `fa` has all five.

  Not the same word as `Kati.Money.currency_word/1`, deliberately. That one is
  what a PRICE carries — `۸٫۹۹ پوند`, board 127's notation — and this is a
  currency's full name in a list of currencies, `پوند بریتانیا`, which is what
  the formatting card below prints straight out of CLDR. Shortening one to the
  other here would make the two halves of the page disagree.
  """
  @spec currency_name(String.t(), String.t()) :: String.t()
  def currency_name("GBP", _latin), do: pgettext("currency name", "Pound sterling")
  def currency_name("EUR", _latin), do: pgettext("currency name", "Euro")
  def currency_name("USD", _latin), do: pgettext("currency name", "US dollar")
  def currency_name("IRR", _latin), do: pgettext("currency name", "Iranian rial")
  def currency_name("TRY", _latin), do: pgettext("currency name", "Turkish lira")
  def currency_name(_code, latin), do: latin

  @doc false
  def symbol_tile(symbol) do
    assigns = %{symbol: symbol}

    ~MOB"""
    <Box width={40} height={40} corner_radius={12} background={Palette.paper()} align="center">
      <Text
        text={@symbol}
        text_size={17}
        font_weight="semibold"
        text_align="center"
        text_color={Palette.ink_soft()}
      />
    </Box>
    """
  end

  @doc false
  def tick(false), do: nil
  def tick(true), do: UI.symbol("check", size: 20, color: Palette.green())

  @doc "The heading the screen's hardest question gets, and its answer."
  @spec why_not_convert() :: map()
  def why_not_convert do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.eyebrow(gettext("Why not convert"))}
      <Text
        text={gettext("Kati has no server, so it cannot know what yesterday’s rate was — and a converted history that quietly used today’s rate would be worse than no conversion at all.")}
        text_size={13}
        line_height={Kati.Locale.leading(1.55)}
        text_color={Palette.ink_soft()}
      />
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  What the same amount looks like in each locale.

  Both rows are produced by `Kati.Money.format/2` under the locale they name,
  rather than typed — the whole claim of the block is that the formatting comes
  from CLDR, and two hand-written examples would be a claim about CLDR made
  without consulting it.
  """
  @spec formatting(String.t()) :: map()
  def formatting(code) do
    rows = [
      # `En` and `English` take no msgid, and neither do `فا` and `فارسی`. This
      # card is a specimen of two locales set side by side, which is screens 53
      # and 54's rule for the same pair: each language is named in its own
      # script, because a reader who cannot read the other one still has to be
      # able to tell the two rows apart. Translating this row would print
      # `انگلیسی` above a Persian figure and leave the card claiming nothing.
      SettingsList.row(
        Kati.Screens.Currency.locale_tile("En"),
        SettingsList.body("English", nil),
        SettingsList.trailing(Kati.Screens.Currency.example(code, "en"))
      ),
      SettingsList.row(
        Kati.Screens.Currency.locale_tile("فا", "fa"),
        Kati.Screens.Currency.persian_body("فارسی"),
        SettingsList.trailing(Kati.Screens.Currency.example(code, "fa"))
      )
    ]

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.card(rows)}
      <Spacer size={12} />
      {Kati.Screens.Currency.codepoint_note()}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def locale_tile(label, face \\ "sans") do
    assigns = %{label: label, face: face}

    ~MOB"""
    <Box width={40} height={40} corner_radius={12} background={Palette.paper()} align="center">
      <Text
        text={@label}
        font_family={@face}
        text_size={13}
        font_weight="semibold"
        text_align="center"
        text_color={Palette.ink_soft()}
      />
    </Box>
    """
  end

  @doc """
  The row title of the Persian locale, in the Persian face.

  `Kati.UI.SettingsList.body/2` builds its own `Text` and takes no
  `font_family` — the shape `Kati.Screens.Fa` calls the reason the mirrors
  adopt so little of `Kati.Components` — so the one Persian title on this
  screen is built here instead of translated into a prop the component does
  not have.
  """
  @spec persian_body(String.t()) :: map()
  def persian_body(title) do
    assigns = %{title: title}

    ~MOB"""
    <Column weight={1.0}>
      <Text
        text={@title}
        font_family="fa"
        text_size={14.5}
        font_weight="semibold"
        text_color={:on_surface}
        max_lines={1}
      />
    </Column>
    """
  end

  @doc """
  `£1,234.56`, in the named locale, straight from CLDR.

  The Persian example leaves the mono face, and it is the same trade
  `Kati.Screens.Fa` records for every Persian numeral in the app:
  `kati_mono.ttf` carries none of U+06F0–U+06F9 and none of the words, so
  `۱٬۲۳۴٫۵۶ پوند بریتانیا` in mono is drawn by Android's fallback face beside
  the English row's real DM Mono. Vazirmatn at the same size is the wrong face
  and the right glyphs, which is the better half of it.
  """
  @spec example(String.t(), String.t()) :: map()
  def example(code, locale) do
    text = Kati.Screens.Currency.formatted_example(code, locale)

    assigns = %{
      text: text,
      # The Persian row is Vazirmatn by construction, for the reason above. The
      # Latin row asks the STRING rather than the reader — `Kati.Locale.mono_face/1`
      # — because CLDR's `en` does not have a Latin symbol for every code this
      # screen offers: `IRR` falls back to `﷼`, which DM Mono has no glyph for
      # either. ASCII, which is every row the drawing draws, still answers
      # `"mono"`, so board 125 does not move.
      face: if(locale == "fa", do: "fa", else: Kati.Locale.mono_face(text))
    }

    ~MOB"""
    <Text
      text={@text}
      font_family={@face}
      text_size={12.5}
      text_color={Kati.Theme.Palette.sub()}
      max_lines={1}
    />
    """
  end

  @doc """
  `£1,234.56` in English, `۱٬۲۳۴٫۵۶ پوند بریتانیا` in Persian.

  Two different *formats*, not two renderings of one. English uses CLDR's
  standard currency pattern, where the symbol leads. Persian uses `¤¤¤` — the
  currency's **name** — because that is what the drawing shows and what the
  block above it claims: Persian *puts the currency word after the figure*. A
  symbol-led Persian line would make the caption false.

  The name is CLDR's full one — `پوند بریتانیا`, pound of Britain — where the
  drawing abbreviates it to `پوند`. CLDR wins: the block's whole assertion is
  that none of this is hand-placed, and shortening a currency name by hand is
  exactly the hand-placing it disclaims.
  """
  @spec formatted_example(String.t(), String.t()) :: String.t()
  def formatted_example(code, locale) do
    format = if locale == "fa", do: "#,##0.00 ¤¤¤", else: :currency

    case Kati.Cldr.Number.to_string(Decimal.new("1234.56"),
           currency: code,
           locale: locale,
           format: format
         ) do
      {:ok, formatted} -> formatted
      _other -> Kati.Screens.Currency.fallback_example(code, locale)
    end
  rescue
    _error -> Kati.Screens.Currency.fallback_example(code, locale)
  end

  @doc """
  What the example row says when CLDR could not answer.

  One string for both rows was wrong the moment this screen started rendering
  under `:fa`: `£1,234.56` in the Persian row is Latin digits, a leading symbol
  and a Latin decimal point, on the one row of the one card whose entire claim
  is that Persian does none of those three. A fallback that contradicts the
  caption above it is worse than a fallback that is merely plain.

  So the Latin row keeps the hand-placed form it always had — there is nothing
  else to fall back TO once CLDR has declined — and the Persian row falls back
  to `Kati.Money.display/2`, which is Kati's own copy for the same shape:
  arabext digits, the Persian decimal mark, and the currency word after the
  figure. `Kati.Locale.as/2` rather than the reader's locale, because this row
  is Persian whoever is looking at it.
  """
  @spec fallback_example(String.t(), String.t()) :: String.t()
  def fallback_example(code, "fa"),
    do: Kati.Locale.as(:fa, fn -> Money.display(123_456, code) end)

  def fallback_example(code, _latin), do: Money.symbol(code) <> "1,234.56"

  @doc """
  The confirmation, or nothing until a different currency is tapped.

  Two labelled halves, because the question a user actually has is *what
  happens to my money* and a single paragraph would let the reassuring half be
  skimmed past. `£8.99 becomes €8.99, not €10.42` is the sentence the whole
  screen exists to say.
  """
  @spec confirmation(map()) :: map() | []
  def confirmation(%{confirming: nil}), do: []

  def confirmation(assigns) do
    from = Money.currency()
    to = assigns.confirming

    # 269's recipe, which board 330 widened for a list delete. This screen drew
    # it first; `Kati.UI.Destructive.confirm/1` is that drawing lifted so the
    # second caller does not redraw it.
    #
    # The three figures go through `Kati.Money.display/2` rather than through a
    # symbol concatenated onto `"8.99"`, and that is this screen's own doctrine
    # applied to its own crux. The card 40 lines up from here spends a whole
    # block saying a hand-placed symbol is a symbol on the wrong side of the
    # number in half the world — and then this sentence hand-placed one, so a
    # Persian reader was promised `£8.99 becomes €8.99` in Latin digits with the
    # symbol leading, on the page that had just told them Persian does neither.
    # `display/2` is where board 127 wrote the Persian shape down (`۸٫۹۹ پوند`)
    # and it is CLDR's `£8.99` unchanged under `:en`, so nothing on 125 moves.
    #
    # No `Kati.Locale.ltr/1` around them: under `:fa` each figure is Persian
    # digits followed by a Persian word, which the paragraph's own direction
    # already orders correctly. An isolate would set the run left-to-right and
    # put the word in front of the number.
    Kati.UI.Destructive.confirm(
      eyebrow: gettext("Changing it"),
      # The CODE is a Latin run inside a Persian question, and the question mark
      # is a neutral: `Kati.Locale.ltr/1` is what keeps `؟` off the wrong end.
      title: gettext("Switch to %{code}?", code: Kati.Locale.ltr(to)),
      changes: gettext("the symbol and the number formatting, everywhere."),
      keeps:
        gettext("any amount you have already recorded — %{from} becomes %{to}, not %{other}.",
          from: Money.display(899, from),
          to: Money.display(899, to),
          other: Money.display(1042, to)
        ),
      confirm: {gettext("Switch anyway"), :switch},
      keep: {gettext("Keep %{code}", code: Kati.Locale.ltr(from)), :keep}
    )
  end

  @doc """
  The formatting note, with the two codepoints set in the mono face.

  Its own rather than `Kati.UI.SettingsList.note/2`, which takes one string and
  would set `U+066C` in the body face. The whole claim of the block is that
  Persian's group and decimal marks are specific characters that CLDR supplies,
  and a codepoint typeset as prose is a codepoint the reader cannot check.
  """
  @spec codepoint_note() :: map()
  def codepoint_note do
    # ONE SENTENCE ACROSS FOUR NODES, AND THE VERB MOVES.
    #
    # The row reads *Persian uses group `U+066C` and decimal `U+066B`* and the
    # paragraph under it finishes the sentence — *with arabext digits, and puts
    # the currency word after the figure.* Persian puts its verb at the end of
    # the clause, so the two halves do not split in the same place: the fragments
    # in the row end on `با` and the verb `می‌نویسد` opens the paragraph below.
    # Each fragment is therefore its own msgid with its own context — a
    # translator handed `and decimal` alone would have no way to know a verb was
    # owed three nodes later — and none of them is short enough to be
    # fuzzy-matched into by `mix gettext.merge` while it carries `codepoint note`.
    #
    # The codepoints themselves take `Kati.Locale.ltr/1` and keep DM Mono. They
    # are values rather than words, so they are the same in both scripts for the
    # reason a URL is; and `U+066C` left to the bidi algorithm on a right-to-left
    # line resolves its `+` as a neutral and hands the reader `066C+U`.
    assigns = %{
      group: Kati.Locale.ltr("U+066C"),
      decimal: Kati.Locale.ltr("U+066B")
    }

    ~MOB"""
    <Row
      fill_width={true}
      background={Palette.card()}
      corner_radius={16}
      border_width={1}
      border_color={Palette.border()}
      padding={15}
      align="top"
    >
      {Kati.UI.symbol("info", size: 17, color: Palette.sub())}
      <Spacer size={11} />
      <Column weight={1.0}>
        <Row fill_width={true} align="center">
          <Text
            text={pgettext("codepoint note", "Persian uses group")}
            text_size={12.5}
            text_color={Palette.ink_soft()}
          />
          <Spacer size={5} />
          <Text text={@group} font_family="mono" text_size={12} text_color={:on_surface} />
          <Spacer size={5} />
          <Text
            text={pgettext("codepoint note", "and decimal")}
            text_size={12.5}
            text_color={Palette.ink_soft()}
          />
          <Spacer size={5} />
          <Text text={@decimal} font_family="mono" text_size={12} text_color={:on_surface} />
          <Spacer weight={1.0} />
        </Row>
        <Spacer size={4} />
        <Text
          text={gettext("with arabext digits, and puts the currency word after the figure — all from CLDR, never hard-placed.")}
          text_size={12.5}
          line_height={Kati.Locale.leading(1.55)}
          text_color={Palette.ink_soft()}
        />
      </Column>
    </Row>
    """
  end

  @doc false
  def handle_tap(:switch, socket) do
    Money.put_currency(socket.assigns.confirming)

    {:noreply,
     socket
     |> Mob.Socket.assign(:currency, Money.currency())
     |> Mob.Socket.assign(:confirming, nil)}
  end

  def handle_tap(:keep, socket), do: {:noreply, Mob.Socket.assign(socket, :confirming, nil)}

  # Picking a currency does NOT change it. It raises the confirmation, which is
  # the screen's whole subject — a currency that switched on a tap would be
  # exactly the silent change the confirmation exists to prevent.
  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "pick_" <> code when code != "" ->
        if code == socket.assigns.currency do
          {:noreply, Mob.Socket.assign(socket, :confirming, nil)}
        else
          {:noreply, Mob.Socket.assign(socket, :confirming, code)}
        end

      _other ->
        {:noreply, socket}
    end
  end
end
