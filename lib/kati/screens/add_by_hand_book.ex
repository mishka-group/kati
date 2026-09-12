defmodule Kati.Screens.AddByHandBook do
  @moduledoc """
  Screen 177 — Add by hand, **Book**. The only control in the app that creates
  a `Kati.Books.Book`.

  Built to `test/design/screens/177.html`, from `design-briefs/D-38-a-book-onto-the-shelf.md`.

  ## Why it exists at all

  Three rounds ended with the same sentence in the report: the Books shelf is
  built, screen 66 is built, `Kati.Books` is built, and **nothing in the app can
  put a book on the shelf by hand**. `Kati.Backup.Catalog` was the resource's
  only writer, so on a device screen 20 was a photograph of six books nobody
  owns and screen 66 fell to `Kati.Books.Sample.detail/0` under every cover.
  This form is the write that ends that, and the moment one book exists the
  whole of Phase 3's books path — 20's grid, its ids, 66 opened by id, 70's
  sheet — becomes reachable from a device.

  ## It is 154, not a copy of 154

  `Kati.Screens.AddByHand` is the same form in its Film and Series kinds and
  this file reuses its parts wherever they are the same part: `labelled/4`,
  `field/3`, `gap/0`, `status_chip/2` and `kind_chip/4` are all called from
  here rather than re-declared. What is this screen's own is what the board
  adds — Author, Edition, the one extent field, ISBN, the book status
  vocabulary, and a heading whose subtitle the board sets at 13.5 over a 6pt
  gap where 154 sets 13 over 7 (`Kati.ScreenTitleSubtitleTest` reads exactly
  those three, off each board).

  **A separate module rather than a third state of 154.** Board 177 is its own
  artboard with its own number, and `Kati.Screens.Gallery` maps one number to
  one module — the arrangement 155, 156 and 157 already use for the same form.
  It also keeps this ticket's edits out of `add_by_hand.ex`, which another
  door is editing in the same tree.

  ## Five Kind chips, and two of them are drawn and inert

  The board draws **five** — Film, Series, Book, Album, Artist — where the
  brief's element table says three. The board is the specification, so five are
  drawn.

  Film and Series push `Kati.Screens.AddByHand`, which is those two kinds of
  the same form. **Album and Artist reach nothing**: the record form is
  `D-39`'s board 178 and is not built by this ticket, and pushing a screen that
  does not exist is not available to it. They are on
  `Kati.ScreenTapSweepTest`'s `@inert_taps` with that sentence, which is the
  list's own shape — *drawn, reachable, and pushing nothing because the
  destination has not been built* — and the entries come off the day 178 lands.

  **Book is not the default anywhere else.** Board 155's resting band is *empty,
  Film, nothing assumed* and stays so; 177 is drawn in Book for the reason 154
  is drawn in Series — so the kind's own fields are visible.

  ## One extent field, never two

  `Kati.Books.Book`'s moduledoc is explicit: *an audiobook has no pages and a
  paperback has no runtime … `format` is what decides which of `page_count` and
  `duration_minutes` is meaningful*. So Edition decides the label, the
  placeholder and the column, and the field is offered rather than required —
  *`page_count` is nullable on purpose*, and a book with none draws no bar
  because `Kati.Books.Book.fraction/1` answers `nil` rather than a zero.

  The audiobook label reads **minutes** rather than the `11h 20m` screen 66
  prints. The column is `duration_minutes` and a typed `11h 20m` is a parse
  nobody asked for; the reading is 66's, the typing is a number, and the label
  says which.

  ## Three statuses, not five

  The board's own annotation settles the brief's second open question in as
  many words: *three is drawn — Not started, Reading, Finished — because Paused
  and Did-not-finish belong to 66's status control, and a book you are adding
  has not been paused.* `Kati.Books.Book` says the same from the other side:
  *`:not_started` is the default, and the four the control offers are the four
  you can move to.*

  ## The two refusals

  A save with no title refuses in words and writes nothing, which is
  `Kati.Write`'s contract. The second is new and the brief asks for it by name:
  **a book already on the shelf**. `Kati.Books.Book` declares no identity on
  title, so nothing in the database refuses a duplicate — the check is a read
  of the shelf before the write, and it is a *guard* rather than a target: it
  chooses no row, it only declines to add a second one. Nothing is written on
  either path.

  ## Where Add to library lands

  Screen 66, on the row that was just created and by its own id — the board's
  annotation says *Add to library lands on 66*, and board 155's *Where Add to
  library goes* annotation gains its book answer there. `params_for/1` is
  screen 66's own builder, so the key is spelled once.
  """
  use Kati.Screens.Pushed, back: "Add title"
  use Gettext, backend: Kati.Gettext

  alias Kati.Books.Book
  alias Kati.Screens.AddByHand
  alias Kati.Theme.Palette
  alias Kati.UI

  # Five, and the last two are drawn without a destination — see the moduledoc.
  # A function and not an `@` inside `~MOB`, where `@name` is an ASSIGN: the
  # trap `Kati.Screens.AddByHand.kind_list/0` records.
  #
  # `{key, glyph}` rather than `{label, key, glyph}` since mishka-group/kati#103.
  # A label is a translation now, `gettext/1` resolves against the locale of the
  # process that ASKS, and a module attribute is evaluated once at COMPILE time
  # — so three lists of words here would freeze whichever locale the compiler
  # happened to be in and every Persian reader would get that one. The KEY is
  # the attribute and the WORD is asked for at draw time, which is exactly the
  # arrangement `Kati.Screens.AddByHand`'s own `@kinds` moved to.
  @kinds [
    {:movie, "movie"},
    {:tv, "live_tv"},
    {:book, "menu_book"},
    {:album, "graphic_eq"},
    {:artist, "mic"}
  ]

  @editions [:paperback, :ebook, :audiobook]

  @statuses [:not_started, :reading, :finished]

  @impl true
  def load(socket) do
    Mob.Socket.assign(socket,
      title: "",
      author: "",
      year: "",
      edition: :paperback,
      length: "",
      isbn: "",
      status: :not_started,
      save_error: nil
    )
  end

  @doc false
  @spec kind_list() :: [{String.t(), atom(), String.t()}]
  def kind_list, do: Enum.map(@kinds, fn {kind, icon} -> {kind_label(kind), kind, icon} end)

  @doc """
  What a Kind chip says.

  The tap is named after the KEY and never after this — `Kati.Screens.AddByHand.kind_chip/5`
  carries the argument in full: a tag built from the label made the Persian
  form's control `:kind_کتاب`, a name no device test can type.

  Not `Kati.Screens.AddByHand.kind_label/1`, which is the two-kind form's and
  answers *Film* for anything that is not `:tv` — this row has five.
  """
  @spec kind_label(atom()) :: String.t()
  # One table, `Kati.Screens.AddByHand.kind_label/1`. It was five clauses here
  # and two there, which is how board 178 came to draw *Film* under a
  # `menu_book` glyph the moment it started reading the shared one.
  defdelegate kind_label(kind), to: AddByHand

  @doc false
  @spec edition_list() :: [{String.t(), atom()}]
  def edition_list, do: Enum.map(@editions, &{edition_label(&1), &1})

  @doc """
  What an Edition chip says — screen 66's three words, in screen 66's spelling.

  The same three msgids `Kati.Books.Sample.formats/0` declares, so a book's
  edition is one word across the form that creates it and the screen that draws
  it. Two spellings of *شمیز* would read as two different things.
  """
  @spec edition_label(atom()) :: String.t()
  def edition_label(:ebook), do: gettext("Ebook")
  def edition_label(:audiobook), do: gettext("Audiobook")
  def edition_label(_paperback), do: gettext("Paperback")

  @doc false
  @spec status_list() :: [{String.t(), atom()}]
  def status_list, do: Enum.map(@statuses, &{status_label(&1), &1})

  @doc """
  What a Status chip says, in screen 66's own book vocabulary.

  `pgettext/2` under the `book status` context and not a bare `gettext/1`,
  because the app holds three different *Reading*s and Persian keeps them
  apart: reading a book is **در حال خواندن**, the shelf filter's chip is its
  own entry, and screen 60's section of the day is **مطالعه**. The context is
  `Kati.Screens.BookDetail`'s and `Kati.Books.Sample.statuses/0`'s — which is
  the control this form's value ends up under, so the word a reader picks here
  is the word they meet on 66.
  """
  @spec status_label(atom()) :: String.t()
  def status_label(:reading), do: pgettext("book status", "Reading")
  def status_label(:finished), do: pgettext("book status", "Finished")
  def status_label(_not_started), do: pgettext("book status", "Not started")

  @doc false
  def content(assigns) do
    # The board draws its back pill in the flow at 64; the macro floats one at
    # 54, so the content starts at `content_top/0` to clear it — 154's note,
    # and the same pill.
    #
    # The ISBN specimen is `ltr/1`'d rather than translated. It is a number
    # printed on a book and a translator has nothing to decide about it, but
    # its hyphens are BIDI-neutral: dropped into an RTL field as a bare string
    # the algorithm resolves them against the page and `978-0-571-33915-2`
    # comes out with its groups in the wrong order. The isolate makes the run
    # carry its own direction, which is `Kati.Locale.ltr/1`'s whole job.
    Kati.Screens.Pushed.page(
      ~MOB"""
      <Column fill_width={true}>
        {Kati.Screens.AddByHandBook.heading()}
        {AddByHand.labelled(gettext("Title"), AddByHand.field(:title, assigns.title, gettext("The Salt Almanac")))}
        {AddByHand.labelled(gettext("Kind"), Kati.Screens.AddByHandBook.kinds())}
        {AddByHand.labelled(gettext("Author"), AddByHand.field(:author, assigns.author, gettext("Ines Karvel")), gettext("optional"))}
        {AddByHand.labelled(gettext("Year"), AddByHand.field(:year, assigns.year, gettext("2024")), gettext("optional"))}
        {AddByHand.labelled(gettext("Edition"), Kati.Screens.AddByHandBook.editions(assigns.edition))}
        {AddByHand.labelled(Kati.Screens.AddByHandBook.length_label(assigns.edition), AddByHand.field(:length, assigns.length, Kati.Screens.AddByHandBook.length_placeholder(assigns.edition)), gettext("optional"))}
        {AddByHand.labelled(gettext("ISBN"), AddByHand.field(:isbn, assigns.isbn, Kati.Locale.ltr("978-0-571-33915-2")), gettext("optional"))}
        {AddByHand.labelled(gettext("Status"), Kati.Screens.AddByHandBook.statuses(assigns.status))}
        {AddByHand.error(assigns.save_error)}
        {Kati.UI.Sheet.commit(gettext("Add to library"), :add)}
        <Spacer size={14} />
        {Kati.Screens.AddByHandBook.closing_note()}
        <Spacer size={16} />
        {Kati.UI.eyebrow(gettext("Refused"), dash: Palette.rail_idle())}
        {Kati.Screens.AddByHandBook.refused_band()}
        <Spacer size={14} />
        {Kati.Screens.AddByHandBook.annotation()}
      </Column>
      """,
      Kati.Screens.Pushed.content_top()
    )
  end

  @doc """
  The heading, at board 177's own measurements.

  Not `Kati.Screens.AddByHand.heading/0`, and the difference is three numbers
  rather than a style: 154's board sets its subtitle at 13px over a 7pt gap and
  177's at 13.5 over 6. `Kati.ScreenTitleSubtitleTest` parses exactly the size,
  the family and the `margin-top` out of each board and compares them with what
  the screen rendered, so sharing 154's helper would fail here — correctly, on
  a board this screen is not drawn to.

  **Neither `Text` names a `font_family`, and that is deliberate.** The bridge
  resolves a missing family against the root's and `Kati.Screens.Pushed.chrome/3`
  declares the root's as `Kati.Locale.face_prop/0`, so Persian arrives in
  Vazirmatn without either line mentioning it — and an explicit `sans` here
  would force Latin and draw the heading as empty boxes. The sweep above reads
  an absent family as the design's default for the same reason.

  Two things travel with the fold. `letter_spacing` goes through
  `Kati.Locale.tracking/1`: the design tightens its 28pt headings by a fraction
  of an em and the Arabic script joins its letters, so tracking a Persian
  heading pulls the joins apart. And the title gains `max_lines={1}` — *Add by
  hand* is three short words and **افزودن دستی** is one long one, and a display
  line that wraps at 28pt takes the subtitle's gap with it.
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

  @doc """
  The five Kind chips, with Book lit.

  Book is the screen, so the lit chip is a constant rather than an assign:
  changing kind here is a navigation, not a state — a Book form and a Film form
  ask different questions and draw different fields.

  The fifth argument is the reader's face and was missing. `kind_chip/5` writes
  `font_family` out explicitly and defaults it to `"sans"`, so five chips that
  said nothing were five Persian words handed to Plus Jakarta Sans — a face
  with no Arabic glyph at all, which draws them as empty boxes rather than
  falling back. `Kati.Screens.AddByHand.kinds/1` passes `face_prop/0` for that
  reason and this row now does too; `Kati.PersianFontTest` is what keeps it.
  """
  @spec kinds() :: map()
  def kinds do
    ~MOB"""
    <Row fill_width={true} align="center">
      {Enum.map(Kati.Screens.AddByHandBook.kind_list(), fn {label, kind, icon} ->
        AddByHand.kind_chip(label, icon, kind == :book, kind, Kati.Locale.face_prop())
      end)
      |> Enum.intersperse(AddByHand.gap())}
    </Row>
    """
  end

  @doc "The three Edition chips, in screen 66's order and screen 66's spelling."
  @spec editions(atom()) :: map()
  def editions(active) do
    ~MOB"""
    <Row fill_width={true} align="center">
      {Enum.map(Kati.Screens.AddByHandBook.edition_list(), fn {label, format} ->
        Kati.Screens.AddByHandBook.edition_chip(label, format == active, format)
      end)
      |> Enum.intersperse(AddByHand.gap())}
    </Row>
    """
  end

  @doc "One Edition chip. `format` names the tap and `label` is drawn — `Kati.Screens.AddByHand.kind_chip/5` says why they are two things."
  @spec edition_chip(String.t(), boolean(), atom()) :: map()
  def edition_chip(label, on?, format) do
    assigns = %{label: label, on?: on?, tap: {self(), AddByHand.tag("edition_", format)}}

    ~MOB"""
    <Row
      height={32}
      corner_radius={16}
      background={if @on?, do: Palette.ink_fill(), else: Palette.card()}
      shadow={if @on?, do: nil, else: Kati.Theme.shadow_card_soft()}
      padding_left={15}
      padding_right={15}
      align="center"
      on_tap={@tap}
    >
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

  @doc false
  def statuses(active) do
    ~MOB"""
    <Row fill_width={true} align="center">
      {Enum.map(Kati.Screens.AddByHandBook.status_list(), fn {label, status} ->
        AddByHand.status_chip(label, status == active, status)
      end)
      |> Enum.intersperse(AddByHand.gap())}
    </Row>
    """
  end

  @doc """
  The extent field's label, which restates its unit on every Edition switch.

  Screen 66 restates the unit for the same reason: *380 pages* against
  *11h 20m*, so the number never looks like the other kind.

      iex> Kati.Locale.as(:en, fn -> Kati.Screens.AddByHandBook.length_label(:paperback) end)
      "Length · pages"

      iex> Kati.Locale.as(:en, fn -> Kati.Screens.AddByHandBook.length_label(:audiobook) end)
      "Length · minutes"

      iex> Kati.Locale.as(:fa, fn -> Kati.Screens.AddByHandBook.length_label(:paperback) end)
      "طول · صفحه"

  The locale is named rather than left to the ambient one. `Kati.BooksByHandTest`
  hosts this doctest and sets `:fa` for the whole file — board 176 is screen 20
  read as a Persian reader — so an example that did not say which language it
  meant was asserting whichever one the host file happened to be in, and passed
  only while this function was untranslated.

  The whole label is one msgid rather than *Length* joined to a unit, because
  the middle dot is part of what a translator is deciding: Persian reads
  right-to-left and the separator has to sit between the two words in the order
  the reader meets them, which a caller gluing two translations together in
  Latin order cannot arrange.
  """
  @spec length_label(atom()) :: String.t()
  def length_label(:audiobook), do: gettext("Length · minutes")
  def length_label(_format), do: gettext("Length · pages")

  @doc """
  The figure the empty extent field shows, in the reader's own numerals.

  A specimen and not a msgid: there is nothing for a translator to decide about
  380, and a three-character msgid is exactly what `mix gettext.merge` fuzzy-
  matches against the wrong sentence. `Kati.Locale.number/1` is the whole of the
  question — this is a numeral inside the reader's own script, so it is ۳۸۰
  under `:fa` rather than a Latin figure sitting in a Persian field.

  Unlike the Year field's placeholder, which IS a msgid: `Kati.Locale.year/1`'s
  rule is that a publication year is a citation and never converts, so what the
  Year field suggests is a decision about the calendar a reader types in and
  board 156 answers it — ۱۴۰۳ — rather than a digit swap.
  """
  @spec length_placeholder(atom()) :: String.t()
  def length_placeholder(:audiobook), do: Kati.Locale.number(680)
  def length_placeholder(_format), do: Kati.Locale.number(380)

  @doc """
  The honest sentence under the button, in the board's own three runs.

  A card rather than 154's cream one, because the board draws it as a card: it
  states a fact about what was stored rather than carrying a warning.

  Three msgids and not one, for `Kati.Screens.AddByHand.split_note/4`'s reason:
  `Kati.ScreenDesignLiteralTest` compares a drawing's lines against the tree's,
  and the board's `<strong>` splits the sentence into runs a single joined
  string would no longer match. It costs the translator the sentence's shape —
  154's Persian solves it by letting the bold run carry the verb
  (*پوستر و فهرست قسمت ندارد*), and this one follows it.
  """
  @spec closing_note() :: map()
  def closing_note do
    ~MOB"""
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
          text={gettext("A book typed by hand carries")}
          text_size={12.5}
          line_height={1.65}
          text_color={Palette.ink_soft()}
        />
        <Text
          text={gettext("no jacket and no page count")}
          text_size={12.5}
          line_height={1.65}
          font_weight="semibold"
          text_color={Palette.ink()}
        />
        <Text
          text={gettext("unless you gave one. If Kati finds it later both arrive, and nothing you typed changes.")}
          text_size={12.5}
          line_height={1.65}
          text_color={Palette.ink_soft()}
        />
      </Column>
    </Row>
    """
  end

  @doc """
  The refusal, as a picture of itself.

  Board 155's second band, worded for a book: the field keeps its caret and
  takes the red inset ring, the button is **never** disabled, and the sentence
  ends in *nothing was written*.

  Drawn and not tappable. `Kati.Screens.AddByHandStates.drawn_chip/3` records
  the trap this avoids — *a preview is not a control* — so nothing here carries
  an `on_tap` or an `accessibility_id` that a sweep could address.

  The title in it is the same specimen `Kati.Books.Sample` names, and it goes
  through the same msgid: this band is a picture of the refusal a reader meets,
  so a Latin book title inside a Persian card would be the one line on the page
  that is not in their script. It is a fixture and not user-entered content —
  the title `taken/1` quotes at runtime is what the reader typed, and that is
  never translated.

  The sentence under it is its own msgid rather than `taken/1`'s: the drawn one
  has no `%{title}` in it, because the board puts the name on the line above.
  """
  @spec refused_band() :: map()
  def refused_band do
    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={22}
      shadow={Kati.Theme.shadow_card_soft()}
      padding={17}
    >
      <Row
        fill_width={true}
        height={44}
        corner_radius={14}
        background={Palette.paper()}
        border_color={Palette.red_ring()}
        border_width={1.5}
        padding_left={13}
        padding_right={13}
        align="center"
      >
        <Text
          text={gettext("The Salt Almanac")}
          text_size={14}
          text_color={:on_surface}
          max_lines={1}
        />
        <Spacer size={2} />
        <Box width={2} height={18} background={Palette.accent()} />
      </Row>
      <Spacer size={12} />
      <Row fill_width={true} align="top">
        {UI.symbol("error", size: 17, color: Palette.red())}
        <Spacer size={10} />
        <Column weight={1.0}>
          <Text
            text={gettext("The Salt Almanac")}
            text_size={12.5}
            line_height={1.6}
            font_weight="semibold"
            text_color={Palette.ink()}
          />
          <Text
            text={gettext("is already on your shelf. Nothing was written.")}
            text_size={12.5}
            line_height={1.6}
            text_color={Palette.ink_soft()}
          />
        </Column>
      </Row>
    </Column>
    """
  end

  @doc """
  The board's own note about the four decisions it settles.

  Nine runs and not one paragraph: `Kati.ScreenDesignLiteralTest` compares a
  drawing's lines against the tree's, and the board's `<strong>`s split the
  sentence into runs a single joined string would no longer match.

  So nine msgids, and three of them are two words or fewer. Those take
  `pgettext/2`: `mix gettext.merge` fuzzy-matches a short new msgid against any
  longer sentence that resembles it, and *three*, *one field* and *lands on 66.*
  are exactly the size that goes wrong — a bare `three` would find any sentence
  in the catalogue containing the word. The context names the board, because a
  run is only a sentence fragment in the company of the other eight.

  The board numbers stay numbers inside the msgid rather than being interpolated
  through `Kati.Locale.number/1`: they are part of a sentence a translator is
  rewriting whole, and the Persian catalogue already writes them in its own
  digits — *صفحهٔ ۰۴*, *۱۵۸ در فارسی* — where the sentence puts them.
  """
  @spec annotation() :: map()
  def annotation do
    Kati.Screens.AddByHandBook.runs([
      {gettext("Three chips would be the reuse and five is the truth;"), :plain},
      {pgettext("board 177 annotation", "three"), :bold},
      {gettext(
         "is drawn — Not started, Reading, Finished — because Paused and Did-not-finish belong to 66’s status control, and a book you are adding has not been paused."
       ), :plain},
      {gettext("Film stays the default"), :bold},
      {gettext(
         "on 155: 177 is drawn in Book so the fields are visible, exactly as 154 is drawn in Series. Length is"
       ), :plain},
      {pgettext("board 177 annotation", "one field"), :bold},
      {gettext("whose unit follows Edition — pages, or hours and minutes, never both."), :plain},
      {gettext("Add to library"), :bold},
      {pgettext("board 177 annotation", "lands on 66."), :plain}
    ])
  end

  @doc """
  A dashed aside whose paragraph is a list of runs.

  `Kati.UI.SettingsList.note/2` takes one string and this board's asides
  emphasise inside the sentence, so the paragraph comes in as its own nodes.
  The frame is that helper's — 1.5pt on `Palette.border/0` at radius 18, over
  no fill at all, which is what the board's `border: 1.5px dashed` resolves to
  in a renderer with no dash.
  """
  @spec runs([{String.t(), :plain | :bold}]) :: map()
  def runs(parts) do
    assigns = %{parts: parts}

    ~MOB"""
    <Row
      fill_width={true}
      corner_radius={18}
      border_color={Palette.border()}
      border_width={1.5}
      padding={15}
      align="top"
    >
      {Kati.UI.symbol("info", size: 17, color: Palette.sub())}
      <Spacer size={11} />
      <Column weight={1.0}>
        {Enum.map(@parts, fn {text, weight} -> Kati.Screens.AddByHandBook.run(text, weight) end)}
      </Column>
    </Row>
    """
  end

  @doc false
  def run(text, weight) do
    assigns = %{text: text, bold?: weight == :bold}

    ~MOB"""
    <Text
      text={@text}
      text_size={12.5}
      line_height={1.65}
      font_weight={if @bold?, do: "semibold", else: "normal"}
      text_color={if @bold?, do: Palette.ink(), else: Palette.ink_soft()}
    />
    """
  end

  @doc """
  What was typed, in whichever of the five fields.

  Each `<TextField>` carries its own assign name as its change tag, so this is
  one clause rather than five — and the catch-all delegates to `super/2`,
  which is the trap `Kati.Screens.AddByHand.handle_info/2` records: replacing
  all of `Kati.Screens.Pushed`'s clauses takes `{:tap, tag}` with it and the
  whole screen goes dead.
  """
  @impl true
  def handle_info({:change, field, typed}, socket)
      when field in [:title, :author, :year, :length, :isbn] and is_binary(typed),
      do: {:noreply, Mob.Socket.assign(socket, field, typed)}

  def handle_info(message, socket), do: super(message, socket)

  @impl true
  def handle_tap(:add, socket), do: {:noreply, Kati.Screens.AddByHandBook.save(socket)}

  # Every Kind chip is a navigation: the row is one control that reveals five
  # forms, and four of them are somewhere else.
  #
  # Film and Series are screen 154, this form in its other two kinds. Album and
  # Artist are board 178, which did not exist when this screen was written —
  # `Kati.ScreenTapSweepTest` carried both with the instruction *delete both the
  # moment 178 lands*, and it landed with `D-39`. A chip that lights like a
  # control and reaches nothing is what that note was against.
  #
  # `Kati.Screens.AddByHandRecord` opens on Album and its own Kind row moves to
  # Artist, which is why both chips push the one screen: the record form is one
  # form in two kinds, exactly as this one is.
  def handle_tap(kind, socket) when kind in [:kind_movie, :kind_tv],
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.AddByHand)}

  def handle_tap(kind, socket) when kind in [:kind_album, :kind_artist],
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.AddByHandRecord)}

  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "edition_" <> key ->
        {:noreply, Kati.Screens.AddByHandBook.pick_edition(socket, key)}

      "status_" <> key ->
        {:noreply, Kati.Screens.AddByHandBook.pick_status(socket, key)}

      _other ->
        {:noreply, socket}
    end
  end

  @doc """
  What the form says when Add is pressed with no title.

  Public so a test can ask for the sentence rather than typing it: it is one
  msgid and a test that spelled it out would be asserting the English on a page
  a Persian reader sees in Persian.
  """
  @spec no_title_error() :: String.t()
  def no_title_error, do: gettext("A title is the one thing this needs.")

  @doc """
  Write the book, or say why not.

  Three outcomes and only one of them touches the store.

  **No title** — refused in words, `Kati.Write`'s contract and board 155's
  sentence.

  **Already on the shelf** — refused, and this is the refusal the brief asks
  for by name. `Kati.Books.Book` declares no identity on `title`, so there is
  no constraint for Ash to report and `Kati.Screens.AddByHand.refusal/2`'s
  *"Has already been taken"* translation has nothing to translate. The shelf is
  read and compared instead.

  That read is a **guard and not a target**. `Kati.ScreenWriteTargetTest`'s
  rule is that a write acts on the row the page drew; this read chooses no row
  to act on, it only declines to create a second one. Nothing is written on
  either refusal, which is what `Kati.Write`'s contract asks and what
  `Kati.BooksByHandTest` asserts against real rows.

  **Otherwise** — one `Kati.Books.Book` with `source: :manual`, and screen 66
  opened on it by its own id through screen 66's own builder.
  """
  @spec save(Mob.Socket.t()) :: Mob.Socket.t()
  def save(socket) do
    title = String.trim(socket.assigns.title)

    cond do
      title == "" ->
        Mob.Socket.assign(socket, :save_error, Kati.Screens.AddByHandBook.no_title_error())

      Kati.Screens.AddByHandBook.shelved?(title) ->
        Mob.Socket.assign(socket, :save_error, Kati.Screens.AddByHandBook.taken(title))

      true ->
        case Kati.Screens.AddByHandBook.create(title, socket.assigns) do
          {:ok, book} ->
            Mob.Socket.push_screen(
              socket,
              Kati.Screens.BookDetail,
              Kati.Screens.BookDetail.params_for(book)
            )

          error ->
            Mob.Socket.assign(socket, :save_error, Kati.Write.message(error))
        end
    end
  end

  @doc """
  Is a book of this name already on the shelf?

  Case-folded and trimmed, because *the salt almanac* and *The Salt Almanac*
  are one book to the person typing the second one. A store that cannot be
  read answers `false`: the write below will fail on its own and say so, which
  is a better failure than refusing a book because the database was busy.
  """
  @spec shelved?(String.t()) :: boolean()
  def shelved?(title) do
    wanted = String.downcase(title)

    case Ash.read(Book, action: :shelf) do
      {:ok, books} ->
        Enum.any?(
          books,
          &(&1.title |> to_string() |> String.trim() |> String.downcase() == wanted)
        )

      _other ->
        false
    end
  rescue
    _error -> false
  end

  @doc """
  The duplicate refusal, in words.

      iex> Kati.Screens.AddByHandBook.taken("The Salt Almanac")
      "“The Salt Almanac” is already on your shelf. Nothing was written."
  """
  @spec taken(String.t()) :: String.t()
  def taken(title),
    do:
      gettext("%{title} is already on your shelf. Nothing was written.",
        title: Kati.Locale.quoted(title)
      )

  @doc """
  The row, from what was typed and nothing else.

  `source: :manual`, which is what `Kati.Books.Book` documents a typed book as
  — the `:open_library` value is for a fetch nothing in `lib/` performs. No
  `cover_seed`: a hand-typed book has no jacket, and the closing note says so
  in words rather than the form drawing a grey rectangle that promises one.
  """
  @spec create(String.t(), map()) :: {:ok, Book.t()} | {:error, term()}
  def create(title, assigns) do
    Book
    |> Ash.Changeset.for_create(:create, Kati.Screens.AddByHandBook.attributes(title, assigns))
    |> Ash.create()
    |> Kati.Write.note("add a book by hand #{title}")
  end

  @doc """
  What the form holds, as `Kati.Books.Book`'s own attributes.

  The extent goes into **one** column, chosen by Edition — the resource's rule,
  quoted in this file's moduledoc — so switching a paperback to an audiobook
  can never leave a stale page count behind a runtime. Every optional field
  that was left blank arrives as `nil` rather than as `""` or `0`; see
  `text/1` and `number/1` for why each degrades that way. Asserted against real
  rows in `Kati.BooksByHandTest` rather than as a doctest, because a map's
  inspected key order is not a fact about this function.
  """
  @spec attributes(String.t(), map()) :: map()
  def attributes(title, assigns) do
    %{
      source: :manual,
      title: title,
      author: Kati.Screens.AddByHandBook.text(assigns.author),
      published_year: Kati.Screens.AddByHandBook.number(assigns.year),
      format: assigns.edition,
      isbn: Kati.Screens.AddByHandBook.text(assigns.isbn),
      status: assigns.status
    }
    |> Map.merge(Kati.Screens.AddByHandBook.extent(assigns.edition, assigns.length))
  end

  @doc """
  The extent column this edition means, or neither.

      iex> Kati.Screens.AddByHandBook.extent(:ebook, "380")
      %{page_count: 380}

      iex> Kati.Screens.AddByHandBook.extent(:audiobook, "680")
      %{duration_minutes: 680}

      iex> Kati.Screens.AddByHandBook.extent(:paperback, "")
      %{}
  """
  @spec extent(atom(), String.t()) :: map()
  def extent(format, typed) do
    case {format, Kati.Screens.AddByHandBook.number(typed)} do
      {_format, nil} -> %{}
      {:audiobook, minutes} -> %{duration_minutes: minutes}
      {_format, pages} -> %{page_count: pages}
    end
  end

  @doc """
  A typed line, or `nil` when nothing was typed.

  `nil` and not `""`: `Kati.Books.Book.author` is nullable on purpose and
  `Kati.Screens.Books.from_detail/1` degrades a missing author to the empty
  string at the point it is *drawn*. An empty string stored is a claim that the
  book has an author whose name is nothing.
  """
  @spec text(String.t() | nil) :: String.t() | nil
  def text(value) do
    case value |> to_string() |> String.trim() do
      "" -> nil
      trimmed -> trimmed
    end
  end

  @doc """
  A typed number, or `nil` when it is not one.

  `min: 1` on both extent columns, so a zero or a negative is `nil` rather than
  a write the resource will refuse — the field is an offer and a typo in an
  optional field must not cost the book.

      iex> Kati.Screens.AddByHandBook.number("380 pages")
      380

      iex> Kati.Screens.AddByHandBook.number("0")
      nil

      iex> Kati.Screens.AddByHandBook.number("")
      nil
  """
  @spec number(String.t() | nil) :: pos_integer() | nil
  def number(value) do
    case value |> to_string() |> String.trim() |> Integer.parse() do
      {number, _rest} when number > 0 -> number
      _other -> nil
    end
  end

  @doc "Take a Status chip's tap, if it names one of the three. `Kati.Screens.AddByHand.pick/2`'s rule, over this form's own list."
  @spec pick_status(Mob.Socket.t(), String.t()) :: Mob.Socket.t()
  def pick_status(socket, key),
    do: Kati.Screens.AddByHandBook.assign_key(socket, :status, @statuses, key)

  @doc "The same, for the three Edition chips."
  @spec pick_edition(Mob.Socket.t(), String.t()) :: Mob.Socket.t()
  def pick_edition(socket, key),
    do: Kati.Screens.AddByHandBook.assign_key(socket, :edition, @editions, key)

  @doc """
  Assign the value a chip's tag names, or leave the field alone.

  A list of KEYS and not of `{label, value}` pairs since the labels moved out of
  the module attributes and became translations. Matching on the value never
  needed the word, and asking for it here would run three `gettext/1` lookups to
  answer a tap that only ever compares atoms — `Kati.Screens.AddByHand.pick/2`
  is the same shape over its own `@statuses`.

  A tag Kati did not draw leaves the assign where it was rather than writing a
  value `Kati.Books.Book` would refuse at save time.
  """
  @spec assign_key(Mob.Socket.t(), atom(), [atom()], String.t()) :: Mob.Socket.t()
  def assign_key(socket, field, values, key) do
    case Enum.find(values, &(Atom.to_string(&1) == key)) do
      nil -> socket
      value -> Mob.Socket.assign(socket, field, value)
    end
  end
end
