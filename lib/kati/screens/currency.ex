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
  """

  use Kati.Screens.Pushed, back: "Language"

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
        {SettingsList.title("Currency", "ONE CURRENCY, CHOSEN ONCE")}
        {Kati.Screens.Currency.list(assigns.currency)}
        {Kati.Screens.Currency.why_not_convert()}
        {UI.eyebrow("Formatting")}
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
          SettingsList.body(code, name),
          SettingsList.trailing(Kati.Screens.Currency.tick(code == current)),
          on_tap: {self(), String.to_atom("pick_" <> code)}
        )
      end)

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.card(rows)}
      <Spacer size={12} />
      {Kati.UI.SettingsList.note("info", "Kati records and shows every amount in one currency, chosen once and never converted. Changing it changes the symbol and the formatting — it does not touch a single stored figure.")}
      <Spacer size={24} />
    </Column>
    """
  end

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
      {Kati.UI.eyebrow("Why not convert")}
      <Text
        text="Kati has no server, so it cannot know what yesterday’s rate was — and a converted history that quietly used today’s rate would be worse than no conversion at all."
        text_size={13}
        line_height={1.55}
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
    assigns = %{
      text: Kati.Screens.Currency.formatted_example(code, locale),
      face: if(locale == "fa", do: "fa", else: "mono")
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
      _other -> Money.symbol(code) <> "1,234.56"
    end
  rescue
    _error -> Money.symbol(code) <> "1,234.56"
  end

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
    to = assigns.confirming
    from = assigns.currency

    assigns = %{
      title: "Switch to #{to}?",
      example:
        "any amount you have already recorded — #{Money.symbol(from)}8.99 becomes " <>
          "#{Money.symbol(to)}8.99, not #{Money.symbol(to)}10.42.",
      keep: "Keep #{from}"
    }

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.eyebrow("Changing it", dash: Kati.Theme.Palette.bronze())}
      <Column fill_width={true} background={Palette.cream()} corner_radius={22} padding={17}>
        <Row fill_width={true} align="center">
          {Kati.UI.symbol("error", size: 18, color: Palette.gold_icon())}
          <Spacer size={11} />
          <Text
            text={@title}
            text_size={15}
            font_weight="bold"
            text_color={Palette.cream_ink()}
            max_lines={1}
          />
        </Row>
        <Spacer size={13} />
        {Kati.Screens.Currency.clause("Changes:", "the symbol and the number formatting, everywhere.")}
        <Spacer size={9} />
        {Kati.Screens.Currency.clause("Does not change:", @example)}
        <Spacer size={15} />
        <Row fill_width={true} align="center">
          <Row
            height={38}
            corner_radius={19}
            background={Palette.ink_fill()}
            padding_left={16}
            padding_right={16}
            align="center"
            on_tap={{self(), :switch}}
          >
            <Text
              text="Switch anyway"
              text_size={12.5}
              font_weight="bold"
              text_color={Palette.on_ink()}
              max_lines={1}
            />
          </Row>
          <Spacer size={14} />
          <Text
            text={@keep}
            text_size={12.5}
            font_weight="semibold"
            text_color={Palette.cream_sub()}
            on_tap={{self(), :keep}}
          />
          <Spacer weight={1.0} />
        </Row>
      </Column>
    </Column>
    """
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
          <Text text="Persian uses group" text_size={12.5} text_color={Palette.ink_soft()} />
          <Spacer size={5} />
          <Text text="U+066C" font_family="mono" text_size={12} text_color={:on_surface} />
          <Spacer size={5} />
          <Text text="and decimal" text_size={12.5} text_color={Palette.ink_soft()} />
          <Spacer size={5} />
          <Text text="U+066B" font_family="mono" text_size={12} text_color={:on_surface} />
          <Spacer weight={1.0} />
        </Row>
        <Spacer size={4} />
        <Text
          text="with arabext digits, and puts the currency word after the figure — all from CLDR, never hard-placed."
          text_size={12.5}
          line_height={1.55}
          text_color={Palette.ink_soft()}
        />
      </Column>
    </Row>
    """
  end

  @doc """
  One half of the confirmation: a bold label and the sentence under it.

  Two `Text` nodes rather than one `Kati.UI.rich_text/1` run, and this is the
  one place in the app where that is the right call. `rich_text/1` merges its
  runs into a single node, which is correct for a sentence with a number
  emphasised inside it — and wrong here, because these are a **heading and a
  clause**, and a reader skimming for "does it touch my money" needs the two
  labels to be findable rather than buried mid-paragraph.
  """
  @spec clause(String.t(), String.t()) :: map()
  def clause(label, body) do
    assigns = %{label: label, body: body}

    ~MOB"""
    <Column fill_width={true}>
      <Text text={@label} text_size={13} font_weight="semibold" text_color={Palette.cream_ink()} />
      <Spacer size={4} />
      <Text text={@body} text_size={13} line_height={1.5} text_color={Palette.cream_body()} />
    </Column>
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
