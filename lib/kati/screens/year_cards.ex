defmodule Kati.Screens.YearCards do
  @moduledoc """
  Screen 100 — Year cards, pushed under Settings.

  **The authoritative render spec**, and the design's caption says so: *four
  faces at both ratios on one board, so the generator has nothing to infer.*
  This screen is a reference sheet in screen 27's manner rather than a place in
  the app — it exists so that whatever eventually writes the PNG has one page
  to be compared against.

  ## Story re-scales, it does not crop

  The reflow question the ticket left open, answered: *the same elements, larger
  type and looser spacing to fill the taller frame. Nothing is cut, because a
  cropped chart is a wrong chart.* Crop would truncate a bar chart, and restack
  would give the generator eight layouts to maintain instead of four.

  So `face/2` takes the ratio and changes only the scale, and there is no
  branch anywhere in this file that omits an element at one ratio and draws it
  at the other.

  ## No orange on any card

  The palette rule, and it has a reason rather than a preference behind it:
  **a saved image has no "now" to point at.** Orange means new/now everywhere
  else in Kati, and an image that outlives the day it was made cannot mean now.
  The field uses the bronze ramp and the bars a four-tone ink ramp.

  ## Only the field card carries the wordmark

  Screen 98 gives the reasoning and this sheet obeys it: the field is the card
  people ask about, so it is the one that answers.

  ## What this sheet translates, and what it only typesets

  mishka-group/kati#103. The sheet owns its **chrome** — the title, the
  subtitle, the two ratio eyebrows, the two mono labels it writes itself, the
  re-scale note and the row onto 101 — and those are `gettext/1` here.

  The words on the cards are **not** this file's, and the reuse the moduledoc
  argues for above is exactly why. The hours label, figure, change and year,
  the three ranked titles, `Your year`, `26 WEEKS`, the `Kati` wordmark and the
  palette sentence are `Kati.Stats.ShareSample`'s, some of them drawn through
  `Kati.Screens.YearShare`. A msgid has to be a literal at its own call site,
  so the only way to wrap them from here would be to retype the specimen this
  sheet's whole claim depends on being the same one screen 98 draws.
  `Kati.Screens.YearCardsStates` reached the same conclusion about the same
  strings, and `Kati` stays Latin in any event for board 127's reason: a name a
  thing calls itself is spelled one way.

  What this file does own for those words is their **typesetting**, and that is
  the half that fails silently:

    * `Kati.UI.eyebrow_label/1` rather than `String.upcase/1` on the hours
      label. The board sets these labels in sentence case and upper-cases them
      in CSS, which is the same division: the Arabic script has no case, so
      upper-casing **زمان تماشا** is a no-op that reads as one.
    * `Kati.Locale.mono_face/1` on every mono slot. The **arity-1** form takes
      the four strings that are the sample's — they are pure ASCII today and
      stay in DM Mono, and they move to Vazirmatn on the day the sample folds
      without this file changing. The arity-0 form takes the lines this file
      writes, which are the reader's own language by construction.
    * `Kati.Locale.tracking/1` on the `.14em` and `.12em` labels and on both
      negative display trackings. Letter-spacing is a Latin small-caps effect
      and it pulls Persian letters apart at their joins. The wordmark is the
      one exception and keeps its hardcoded `-0.02`: it is Latin in both
      scripts, so zeroing its tracking would loosen a word that never needed
      it.
    * `Kati.Locale.number/1` on the genre hours. `Integer.to_string/1` is the
      Latin digits whatever calendar and numerals the reader counts in.
    * `Kati.Locale.leading/1` on the palette paragraph, for the reason
      `Kati.Theme.fa_line_height/0` gives: Vazirmatn's metrics are not Plus
      Jakarta's.
    * `max_lines={1}` on the two display lines. Nothing on this sheet may
      reflow — the card's proportion **is** the spec — so a longer Persian
      word has to ellipsize rather than grow the frame it is being measured in.

  Both back pills are `Kati.Screens.Pushed`'s to translate and stay the plain
  literals its `back_vocabulary/0` declares; `Settings` and `Year cards` are
  both on that list already.
  """

  use Kati.Screens.Pushed, back: "Settings"
  use Gettext, backend: Kati.Gettext

  alias Kati.Stats.ShareSample
  alias Kati.Theme.Palette
  alias Kati.UI.SettingsList

  # The two ratios, with the scale each multiplies the type and spacing by.
  # One number per ratio rather than a table of sizes: re-scale means exactly
  # that, and a per-element table would be the eight layouts the caption
  # rejects.
  #
  # A FUNCTION rather than the `@ratios [...]` attribute this used to be. A
  # module attribute is evaluated at COMPILE time, so a `pgettext/3` inside one
  # freezes in whichever locale the compiler happened to be in and draws that
  # language for the life of the build. mishka-group/kati#103.
  #
  # The ratio itself is interpolated rather than typed into the msgid: a
  # translator cannot then turn 4:5 into 5:4, and the digits go through
  # `Kati.Locale.number/1` because the eyebrow is Vazirmatn under `:fa` rather
  # than DM Mono — ۴:۵ is what a Persian reader counts in, and the DM Mono
  # exception `Kati.Locale.number/1` documents does not reach here.
  #
  # `pgettext/3` and not `gettext/2`: two words is short enough for
  # `mix gettext.merge` to fuzzy-match onto the bare `Square` and `Story` that
  # screen 98's aspect chips already own, and those are the right words in the
  # wrong grammar — a chip is a control and this is a section heading.
  defp ratios do
    [
      {pgettext("year card ratio", "%{ratio} Square", ratio: Kati.Locale.number("4:5")), 1.0},
      {pgettext("year card ratio", "%{ratio} Story", ratio: Kati.Locale.number("9:16")), 1.25}
    ]
  end

  def load(socket), do: socket

  @doc false
  def content(_assigns) do
    # Bound out here rather than written inside the sigil, in the shape
    # `Kati.Screens.YearCardsStates.content/1` uses: the two msgids this page's
    # chrome owns read as one pair somebody can check against board 100.
    #
    # `Year cards` is already in the catalogue — `Kati.Settings.Sample` names
    # this sheet from the Settings list and board 101 titles itself with it —
    # and an exact msgid always beats minting a second Persian word for a thing
    # the app has already named.
    #
    # The subtitle is typed in capitals because `SettingsList.subtitle/2` does
    # not upcase for the caller; under `:fa` there is no case to apply. That
    # subtitle is pinned to one line, so the Persian is kept as short as the
    # English rather than spelled out.
    title = gettext("Year cards")
    subtitle = gettext("FOUR FACES × TWO RATIOS")

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
        {SettingsList.title(title, subtitle)}
        {Kati.Screens.YearCards.palette_note()}
        {Kati.Screens.YearCards.boards()}
        {Kati.Screens.YearCards.rescale_note()}
        {Kati.Screens.YearCards.states_row()}
      </Column>
    </Scroll>
    """
  end

  @doc """
  The row onto board 101 — the five states one of these cards can be in.

  MOVIES-AND-TV.md #2. This page draws the four faces at two ratios; 101 draws
  what happens when one of them cannot be filled or cannot be saved, which is
  the same subject one question further on. It was gallery-only, so the one
  correction it needed — band 5 names a capability that has since shipped —
  went unread for as long as the board did.
  """
  @spec states_row() :: map()
  def states_row do
    # The sub-line names three of board 101's five states, and it is worded to
    # match the eyebrows that sheet already carries rather than to paraphrase
    # them — `Not enough data` is the catalogue's own msgid there, so the
    # Persian a reader meets on this row is the Persian they meet on the page
    # it opens. Two sentences describing one thing in two vocabularies is the
    # failure this whole fold keeps finding.
    #
    # The chevron needs nothing here: `SettingsList.chevron/0` is
    # `Kati.Locale.forward_chevron/0` already, so a row that opens something
    # points leftward on a Persian page without this file asking.
    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={22} />
      {Kati.UI.SettingsList.card([
        Kati.UI.SettingsList.row(
          Kati.UI.SettingsList.icon_tile("help"),
          Kati.UI.SettingsList.body(
            gettext("When a card cannot be made"),
            gettext("Not enough data, a private title, a save that refused")
          ),
          Kati.UI.SettingsList.trailing(Kati.UI.SettingsList.chevron()),
          rule: false,
          on_tap: {self(), :open_states}
        )
      ])}
    </Column>
    """
  end

  @doc "The palette sentence and the rule inside it."
  @spec palette_note() :: map()
  def palette_note do
    # The sentence is `Kati.Stats.ShareSample.palette_note/0`'s to translate —
    # it is the module that writes it, and a msgid has to be a literal at its
    # own call site. The LEADING is this file's, and it is the half that fails
    # silently: Vazirmatn's metrics are not Plus Jakarta's, so a paragraph
    # measured at the Latin 1.55 sets too tight in Persian.
    # `Kati.Theme.fa_line_height/0` carries the numbers.
    ~MOB"""
    <Column fill_width={true}>
      <Text
        text={Kati.Stats.ShareSample.palette_note()}
        text_size={12.5}
        line_height={Kati.Locale.leading(1.55)}
        text_color={Palette.ink_soft()}
      />
      <Spacer size={22} />
    </Column>
    """
  end

  @doc "Both ratios, each with all four faces."
  @spec boards() :: map()
  def boards do
    boards =
      ratios()
      |> Enum.map(fn {label, scale} -> Kati.Screens.YearCards.board(label, scale) end)
      |> Enum.intersperse(~MOB"<Spacer size={24} />")

    ~MOB"""
    <Column fill_width={true}>
      {boards}
      <Spacer size={20} />
    </Column>
    """
  end

  @doc false
  def board(label, scale) do
    assigns = %{
      label: label,
      faces:
        ShareSample.faces()
        |> Enum.map(&Kati.Screens.YearCards.face(&1, scale))
        |> Enum.intersperse(~MOB"<Spacer size={11} />")
    }

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.eyebrow(@label)}
      {@faces}
    </Column>
    """
  end

  @doc """
  One card face at one scale.

  Every face is drawn at both ratios — see the moduledoc. `scale` multiplies
  the type; nothing is added or removed.
  """
  @spec face(atom(), float()) :: map()
  def face(:hours, scale) do
    h = ShareSample.hours()

    assigns = %{
      # `Kati.UI.eyebrow_label/1`, not `String.upcase/1`. The board sets this
      # label in sentence case and upper-cases it in CSS, which is the same
      # division of labour: `String.upcase/1` is a Latin operation, and the
      # Arabic script has no case for it to raise — **زمان تماشا** comes back
      # unchanged, so the call reads as a transformation that did nothing.
      label: Kati.UI.eyebrow_label(h.label),
      # The sample's three, and they stay the sample's: `312h 40m`, `18%` and
      # `2026` are `Kati.Stats.ShareSample.hours/0`'s to fold, and retyping
      # them here to reach a msgid would fork the specimen screen 98 draws from
      # the one this sheet is supposed to be specifying.
      #
      # Their typesetting below is this file's, and it is written so the fold
      # needs no second visit: `Kati.Locale.mono_face/1` — the arity that asks
      # the STRING's script rather than the reader's — keeps them in DM Mono
      # while they are ASCII and moves them to Vazirmatn on the day
      # `hours/0` starts answering **۳۱۲ ساعت ۴۰ دقیقه**, which
      # `Kati.Screens.Stats.hours_and_minutes/1` already does for board 61.
      figure: h.figure,
      change: h.change,
      year: h.year,
      figure_size: 30 * scale,
      label_size: 10 * scale
    }

    ~MOB"""
    <Column fill_width={true} background={Palette.card()} corner_radius={20} padding={17}>
      <Text
        text={@label}
        font_family={Kati.Locale.mono_face()}
        text_size={@label_size}
        letter_spacing={Kati.Locale.tracking(0.14)}
        text_color={Palette.muted()}
      />
      <Spacer size={9} />
      <Row fill_width={true} align="bottom">
        <Text
          text={@figure}
          text_size={@figure_size}
          font_weight="extrabold"
          letter_spacing={Kati.Locale.tracking(-0.035)}
          text_color={:on_surface}
          max_lines={1}
        />
        <Spacer size={9} />
        {Kati.UI.symbol("arrow_drop_up", size: 18, color: Palette.bar_ink())}
        <Text
          text={@change}
          font_family={Kati.Locale.mono_face(@change)}
          text_size={12}
          text_color={Palette.ink_soft()}
        />
        <Spacer weight={1.0} />
        <Text
          text={@year}
          font_family={Kati.Locale.mono_face(@year)}
          text_size={11}
          text_color={Palette.muted()}
        />
      </Row>
    </Column>
    """
  end

  def face(:top_titles, scale) do
    assigns = %{
      # The sentence-case msgid board 101 and screen 98 already share —
      # عنوان‌های برتر — raised by `Kati.UI.eyebrow_label/1` rather than typed
      # in capitals, so English still draws the board's `TOP TITLES` and
      # Persian is not handed a no-op upcase.
      label: Kati.UI.eyebrow_label(gettext("Top titles")),
      label_size: 10 * scale,
      # The three ranked titles are `Kati.Stats.ShareSample.top_titles/0`'s and
      # are set by `Kati.Screens.YearShare.rank_row/1`; neither the copy nor
      # the typesetting of them is this file's.
      posters: Kati.Screens.YearShare.posters(),
      ranks: Kati.Screens.YearShare.ranks()
    }

    ~MOB"""
    <Column fill_width={true} background={Palette.card()} corner_radius={20} padding={17}>
      <Text
        text={@label}
        font_family={Kati.Locale.mono_face()}
        text_size={@label_size}
        letter_spacing={Kati.Locale.tracking(0.14)}
        text_color={Palette.muted()}
      />
      <Spacer size={11} />
      {@posters}
      <Spacer size={13} />
      {@ranks}
    </Column>
    """
  end

  def face(:where_hours_went, scale) do
    top = ShareSample.where_hours_went() |> Enum.map(&elem(&1, 1)) |> Enum.max()

    assigns = %{
      # Screen 07's own heading, and board 98's — ساعت‌ها کجا رفتند — rather
      # than a second Persian phrase for the same four bars.
      label: Kati.UI.eyebrow_label(gettext("Where the hours went")),
      label_size: 10 * scale,
      bars:
        ShareSample.where_hours_went()
        |> Enum.with_index()
        |> Enum.map(fn {{genre, hours}, index} ->
          Kati.Screens.YearCards.bar(genre, hours, top, index, scale)
        end)
        |> Enum.intersperse(~MOB"<Spacer size={9} />")
    }

    ~MOB"""
    <Column fill_width={true} background={Palette.card()} corner_radius={20} padding={17}>
      <Text
        text={@label}
        font_family={Kati.Locale.mono_face()}
        text_size={@label_size}
        letter_spacing={Kati.Locale.tracking(0.14)}
        text_color={Palette.muted()}
      />
      <Spacer size={12} />
      {@bars}
    </Column>
    """
  end

  def face(:field, scale) do
    f = ShareSample.field_face()

    assigns = %{
      # All four are `Kati.Stats.ShareSample.field_face/0`'s, for the reason
      # the moduledoc gives, and the arity-1 `Kati.Locale.mono_face/1` below
      # carries the two mono ones across whichever script they end up in.
      # `Your year` and `26 WEEKS` already have Persian in the catalogue from
      # screen 98 — سال شما and «%{count} هفته» — so the day `field_face/0`
      # folds, this face draws them without being touched.
      year: f.year,
      title: f.title,
      span: f.span,
      # `Kati` is the one string on this sheet that is Latin in BOTH scripts:
      # board 127 draws `Lumen+` in Latin on a Persian page for the same
      # reason — a name a thing calls itself is spelled one way. So its
      # `letter_spacing` below stays the hardcoded `-0.02` rather than becoming
      # `Kati.Locale.tracking/1`: zeroing it under `:fa` would loosen a Latin
      # word that has no Persian joins to protect.
      wordmark: f.wordmark,
      title_size: 22 * scale,
      field: Kati.Screens.AlbumDetail.field_rows()
    }

    ~MOB"""
    <Column fill_width={true} background={Palette.card()} corner_radius={20} padding={17}>
      <Text
        text={@year}
        font_family={Kati.Locale.mono_face(@year)}
        text_size={11}
        letter_spacing={Kati.Locale.tracking(0.14)}
        text_color={Palette.muted()}
      />
      <Spacer size={6} />
      <Text
        text={@title}
        text_size={@title_size}
        font_weight="extrabold"
        letter_spacing={Kati.Locale.tracking(-0.03)}
        text_color={:on_surface}
        max_lines={1}
      />
      <Spacer size={14} />
      {@field}
      <Spacer size={13} />
      <Row fill_width={true} align="center">
        <Text
          text={@span}
          font_family={Kati.Locale.mono_face(@span)}
          text_size={9.5}
          letter_spacing={Kati.Locale.tracking(0.12)}
          text_color={Palette.muted()}
        />
        <Spacer weight={1.0} />
        <Text
          text={@wordmark}
          text_size={13}
          font_weight="bold"
          letter_spacing={-0.02}
          text_color={:on_surface}
        />
      </Row>
    </Column>
    """
  end

  @doc """
  One genre bar, on the four-tone ink ramp.

  A ramp rather than a hue per genre, because a saved image has no legend
  beside it — four colours meaning four genres would need one, and a card that
  needs a legend is a card that has failed.
  """
  @spec bar(String.t(), integer(), integer(), integer(), float()) :: map()
  def bar(genre, hours, top, index, scale) do
    rail =
      Kati.Components.MishkaProgress.progress(
        render: :box,
        value: hours / max(top, 1),
        max: 1,
        height: 6,
        corner_radius: 3,
        color: Kati.Screens.YearCards.tone(index),
        track_color: Palette.track()
      )

    assigns = %{
      # The genre is `Kati.Stats.ShareSample.where_hours_went/0`'s and is
      # already a `gettext/1` there — درام, هیجان‌انگیز.
      genre: genre,
      # `Kati.Locale.number/1` rather than `Integer.to_string/1`, which is the
      # Latin digits whatever the reader counts in. This number is the one
      # figure on the sheet that this file composes itself rather than reading
      # off the sample as a string, so it is this file's to convert — and it
      # can be, because the slot beside it is `mono_face/0`: Vazirmatn under
      # `:fa`, which carries U+06F0–U+06F9 where `kati_mono.ttf` carries none
      # of them. ۱۰۴ beside درام, and 104 beside Drama.
      hours: Kati.Locale.number(hours),
      rail: rail,
      size: 12 * scale
    }

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Text
          text={@genre}
          text_size={@size}
          font_weight="semibold"
          text_color={:on_surface}
          max_lines={1}
          weight={1.0}
        />
        <Spacer size={10} />
        <Text
          text={@hours}
          font_family={Kati.Locale.mono_face()}
          text_size={@size}
          text_color={Palette.sub()}
        />
      </Row>
      <Spacer size={6} />
      {@rail}
    </Column>
    """
  end

  @doc "The four-tone ink ramp, darkest first."
  @spec tone(integer()) :: integer()
  def tone(0), do: Palette.ink()
  def tone(1), do: Palette.bar_ink()
  def tone(2), do: Palette.settled_ink()
  def tone(_rest), do: Palette.tertiary()

  @doc "The sentence that answers the reflow question."
  @spec rescale_note() :: map()
  def rescale_note do
    # One msgid across three source lines rather than three: `gettext/1`
    # expands a `<>` chain of literals at compile time, so the catalogue gets
    # the whole paragraph and the translator gets a sentence to translate
    # instead of a clause to guess the end of. `Kati.Retired` and
    # `Kati.Search`'s long notes are written the same way.
    #
    # `SettingsList.note/2` already sets the paragraph with
    # `Kati.Locale.leading/1`, so nothing here needs to ask about leading.
    SettingsList.note(
      "info",
      gettext(
        "Story re-scales rather than crops: the same elements, larger type and looser " <>
          "spacing to fill the taller frame. Nothing is cut, because a cropped chart is a " <>
          "wrong chart. Only the field card carries the wordmark."
      )
    )
  end

  # A reference sheet has nothing to tap, which is screen 27's arrangement
  # exactly. The clause is here so a stray tag is a quiet no-op rather than a
  # `DEAD TAP` in the log.
  @doc false
  # Board 101's door. MOVIES-AND-TV.md #2: the sheet whose whole job is to name
  # honestly why a card cannot be saved was reachable only from the developer
  # gallery, so nobody ever read it — including after its central claim stopped
  # being true. This screen is the one page in the app that is already about
  # how a card is drawn, and 101 is about the states of that card, so the row
  # goes here rather than as a second Settings entry beside the first.
  def handle_tap(:open_states, socket),
    do:
      {:noreply,
       Mob.Socket.push_screen(socket, Kati.Screens.YearCardsStates, %{back: "Year cards"})}

  def handle_tap(_tag, socket), do: {:noreply, socket}
end
