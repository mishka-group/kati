defmodule Kati.Screens.BookDetailFa do
  @moduledoc """
  Screen 69 — کتاب, the Persian book detail, pushed under کتابخانه.

  Screen 66's page in the mirror. What changes is not only the words.

  ## Four things the caption pins, and each is a real RTL trap

    * **The back chevron is `arrow_forward_ios`.** Back is the way the reader
      came from, and in Persian that is the right edge. A mirrored screen that
      keeps the left-pointing chevron is the commonest RTL bug there is, and
      `Kati.Screens.SeriesFa` records the same thing for screen 58.
    * **The progress bar fills from the right.** `Row` lays out start-to-end
      and the root declares `rtl`, so the fill lands at the right edge for
      free — but only because the rail is a Row rather than an absolutely
      positioned Box. Reproduced through the same
      `Kati.Components.MishkaProgress` call screen 66 uses, which is a Row.
    * **Cover artwork and stars hold their direction.** A photograph does not
      mirror, and a five-star row read right to left would put the filled
      stars on the wrong end of the scale. Both are drawn in the order screen
      66 draws them.
    * **Page figures and the ISBN stay in DM Mono with Persian digits so the
      columns still align.** `kati_mono.ttf` carries no Persian digits, which
      is why `Kati.Screens.Fa`'s own rule applies here too: anything numeric
      the design sets in mono is set in `fa` at the design's size and colour.
      The face is wrong and the glyphs are right, which is the better half of
      an unwinnable trade.

  ## The parent is 57, and it was inferred rather than drawn

  The caption says so: *parent inferred as 57 کتابخانه, the only RTL shelf
  drawn.* There is no Persian Books shelf in the 127, so the back pill names
  the shelf that exists.

  ## The transliteration rule

  `Kati.Books.SampleFa` holds it: the fixture's title and author are Persian
  because the fixture is Persian, and **the user's own note text is never
  touched**. Nothing in `Kati.Books` translates anything, and this screen reads
  the same rows screen 66 does when a book is shelved.
  """

  use Mob.Screen
  import Mob.Sigil

  alias Kati.Books.SampleFa
  alias Kati.Screens.Fa
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  def mount(_params, _session, socket) do
    Kati.Theme.activate()
    {:ok, Mob.Socket.assign(socket, :book, book())}
  end

  @doc """
  The book this screen is about: the shelf's, in Persian chrome, or the fixture.

  `Kati.Screens.SeriesFa`'s doctrine, applied to a book: *one series, read
  once, presented twice.* Screen 66's own reader answers, and what this screen
  supplies is the Persian half — the status word, the row labels, the eyebrows.
  What it does **not** supply is a translation: a shelved book keeps its own
  title, its own author and its own notes, because those are the user's and
  nothing in `Kati.Books` translates anything.

  With nothing shelved the whole page is `Kati.Books.SampleFa`, which is the
  fixture the frame was captured from — and where the title and author ARE
  Persian, because a Persian fixture's book is a Persian book.
  """
  @spec book() :: map()
  def book do
    case Kati.Screens.BookDetail.shelved_book() do
      nil -> SampleFa.detail()
      shelved -> Map.merge(SampleFa.detail(), Kati.Screens.BookDetailFa.own(shelved))
    end
  end

  @doc "The drawing's values, unconditionally."
  @spec drawn_book() :: map()
  def drawn_book, do: SampleFa.detail()

  @doc """
  The parts of a shelved book that are the user's rather than the chrome's.

  Deliberately short: a title, an author, a cover and an ISBN. Everything else
  on the page — the status word, the eyebrows, the row labels — is Kati's copy
  and stays in the language the screen is drawn in.
  """
  @spec own(map()) :: map()
  def own(shelved) do
    %{
      title: shelved.title,
      author: shelved.author || "",
      seed: shelved.seed,
      isbn: shelved.isbn || "—"
    }
  end

  def render(assigns), do: Fa.pushed_frame(content(assigns))

  @doc false
  def content(assigns) do
    b = assigns.book
    e = SampleFa.eyebrows()

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {Kati.Screens.BookDetailFa.chrome()}
        {Kati.Screens.BookDetailFa.title(b)}
        {Kati.Screens.BookDetailFa.hero(b)}
        {Kati.Screens.BookDetailFa.ratings(b)}
        {Fa.eyebrow(e.status)}
        {Kati.Screens.BookDetailFa.chips(SampleFa.statuses(), :reading, "status")}
        {Fa.eyebrow(e.edition)}
        {Kati.Screens.BookDetailFa.edition(b)}
        {Fa.eyebrow(e.warnings)}
        {Kati.Screens.BookDetailFa.warnings(b)}
        {Fa.eyebrow(e.notes)}
        {Kati.Screens.BookDetailFa.notes()}
        {Fa.eyebrow(e.series)}
        {Kati.Screens.BookDetailFa.series(b)}
        {Fa.eyebrow(e.history)}
        {Kati.Screens.BookDetailFa.history()}
        {Kati.Screens.BookDetailFa.actions()}
      </Column>
    </Scroll>
    """
  end

  @doc "The back pill, with the chevron pointing the way the reader came from."
  @spec chrome() :: map()
  def chrome do
    assigns = %{label: SampleFa.labels().back}

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
          {Kati.Screens.BookDetailFa.fa(@label, 13.5, :on_surface, weight: "semibold")}
        </Row>
        <Spacer weight={1.0} />
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc """
  A Persian `Text`, in Vazirmatn.

  Every string on this screen goes through here. Plus Jakarta Sans carries no
  Arabic-script glyphs at all, so a Persian label without `font_family="fa"` is
  a row of empty boxes rather than a fallback — `Kati.Screens.Fa`'s moduledoc
  checked the font and says so.

  ## `align` defaults to nothing, and defaulted to `"start"` for a long time

  `text_align` is not a free prop. `MobText` reads a present one as *this text
  is wider than its glyphs* and applies `fillMaxWidth()` — which is right for a
  centred title and catastrophic for a `Text` sitting in a `Row` next to
  anything else, because it takes the whole row and every weighted sibling
  measures zero. With `"start"` as the default, **every** Persian string in the
  app carried it, so every Persian row was one unlucky layout away from losing
  a column.

  Two did, and both only on a device: screen 127's service rows drew a badge, a
  price and a per-hour rate with **no service name**, and its one-off expense
  rows drew an amount and nothing else. In a `Column` the two behaviours are
  indistinguishable — a filled `Text` with `text_align="start"` and a hugging
  one both put their glyphs at the container's start edge — which is why this
  survived every screen sweep and every literal check: the strings were in the
  tree, at the right size, in the right colour, measured to nothing.

  So the default is `nil` and the prop is written only when a caller asks for
  it. Twelve callers do, and each of them wants what `text_align` means:
  `"center"` for a code or a stat, `"absolute_left"`/`"absolute_right"` for the
  handful of things the design says must not mirror.
  """
  @spec fa(String.t(), number(), term(), keyword()) :: map()
  def fa(text, size, colour, opts \\ []) do
    assigns = %{
      text: text,
      size: size,
      colour: colour,
      weight: Keyword.get(opts, :weight, "normal"),
      lines: Keyword.get(opts, :lines, 1),
      align: Keyword.get(opts, :align)
    }

    ~MOB"""
    <Text
      text={@text}
      font_family="fa"
      text_size={@size}
      font_weight={@weight}
      text_align={@align}
      text_color={@colour}
      max_lines={@lines}
      line_height={1.4}
    />
    """
  end

  @doc false
  def title(b) do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.BookDetailFa.fa(b.title, 25, :on_surface, weight: "bold", lines: 2)}
      <Spacer size={5} />
      {Kati.Screens.BookDetailFa.fa(b.author, 12.5, Palette.muted())}
      <Spacer size={20} />
    </Column>
    """
  end

  @doc "The hero card: cover, status pill, the mono facts and the rail."
  @spec hero(map()) :: map()
  def hero(b) do
    rail =
      Kati.Components.MishkaProgress.progress(
        render: :box,
        value: b.progress,
        max: 1,
        height: 2,
        corner_radius: 1,
        color: Palette.accent(),
        track_color: Palette.track_off()
      )

    assigns = %{b: b, rail: rail}

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        padding={17}
        shadow={Kati.Theme.shadow_card()}
      >
        <Row fill_width={true}>
          {Kati.Screens.BookDetail.cover(@b)}
          <Spacer size={15} />
          <Column weight={1.0}>
            {Kati.Screens.BookDetailFa.status_pill(@b.status_label)}
            <Spacer size={11} />
            {Kati.Screens.BookDetailFa.fa(@b.meta, 11, Palette.muted())}
            <Spacer size={13} />
            {@rail}
            <Spacer size={9} />
            {Kati.Screens.BookDetailFa.fa(@b.progress_line, 10.5, Palette.muted())}
          </Column>
        </Row>
      </Column>
      <Spacer size={11} />
    </Column>
    """
  end

  @doc false
  def status_pill(label) do
    assigns = %{label: label}

    ~MOB"""
    <Row
      height={24}
      corner_radius={12}
      background={Palette.green_wash()}
      padding_left={10}
      padding_right={10}
      align="center"
    >
      <Box width={5} height={5} corner_radius={3} background={Palette.green()} />
      <Spacer size={6} />
      {Kati.Screens.BookDetailFa.fa(@label, 11, Palette.green_text(), weight: "bold")}
    </Row>
    """
  end

  @doc """
  Two rating columns, and the stars hold their direction.

  Screen 66's `stars/1` unchanged: a five-star row read right to left would put
  the filled stars at the wrong end of the scale, and a rating is a quantity
  rather than a sentence.
  """
  @spec ratings(map()) :: map()
  def ratings(b) do
    l = SampleFa.labels()

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        <Column weight={1.0}>
          {Kati.Screens.BookDetailFa.rating_card(l.yours, b.rating, b.rating_label)}
        </Column>
        <Spacer size={10} />
        <Column weight={1.0}>
          {Kati.Screens.BookDetailFa.rating_card(l.others, nil, nil)}
        </Column>
      </Row>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def rating_card(label, rating, value) do
    assigns = %{label: label, rating: rating, value: value || "—"}

    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={18}
      padding={14}
      shadow={Kati.Theme.shadow_card()}
    >
      {Kati.Screens.BookDetailFa.fa(@label, 9.5, Palette.muted())}
      <Spacer size={9} />
      <Row fill_width={true} align="center">
        {Kati.Screens.BookDetail.stars(@rating)}
        <Spacer size={9} />
        {Kati.Screens.BookDetailFa.fa(@value, 13, :on_surface)}
      </Row>
    </Column>
    """
  end

  @doc """
  A row of chips, in Persian.

  `Kati.UI.chip/2` cannot draw these: `MishkaChip` takes its label as a prop
  and paints it in the chip's own family, and `expand/3` discards children — so
  a Persian label through that door is a row of boxes.
  `Kati.Screens.Fa`'s moduledoc names this as the single upstream ask, and
  until it lands the chips here are hand-rolled with the same geometry.
  """
  @spec chips([{atom(), String.t()}], atom(), String.t()) :: map()
  def chips(options, selected, prefix) do
    chips =
      options
      |> Enum.map(fn {value, label} ->
        Kati.Screens.BookDetailFa.chip(label, value == selected, "#{prefix}_#{value}")
      end)
      |> Enum.intersperse(~MOB"<Spacer size={7} />")

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true}>
        {chips}
      </Row>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def chip(label, on?, tag) do
    assigns = %{
      label: label,
      background: if(on?, do: Palette.ink_fill(), else: Palette.card()),
      colour: if(on?, do: Palette.on_ink(), else: Palette.ink_soft()),
      weight: if(on?, do: "bold", else: "semibold"),
      tap: {self(), String.to_atom(tag)}
    }

    ~MOB"""
    <Row
      height={32}
      corner_radius={16}
      background={@background}
      padding_left={15}
      padding_right={15}
      align="center"
      on_tap={@tap}
    >
      {Kati.Screens.BookDetailFa.fa(@label, 12, @colour, weight: @weight)}
    </Row>
    """
  end

  @doc false
  def edition(b) do
    l = SampleFa.labels()

    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.BookDetailFa.chips(SampleFa.formats(), :paperback, "format")}
      {Kati.UI.SettingsList.card([
        Kati.Screens.BookDetailFa.row(l.length, nil, b.extent_label, nil),
        Kati.Screens.BookDetailFa.row("ISBN", nil, b.isbn, nil)
      ])}
      <Spacer size={12} />
      {Kati.UI.SettingsList.card([
        Kati.Screens.BookDetailFa.row(l.owned, nil, nil, "inventory_2", trailing: Kati.UI.SettingsList.switch(true))
      ])}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  One list row, with its title and sub in Vazirmatn.

  `Kati.UI.SettingsList.row/4` supplies the geometry and the hairline; only the
  two `Text` nodes are this screen's, because those are the ones that carry
  Persian.
  """
  @spec row(String.t(), String.t() | nil, String.t() | nil, String.t() | nil, keyword()) :: map()
  def row(title, sub, value, icon, opts \\ []) do
    body =
      case sub do
        nil ->
          Kati.Screens.BookDetailFa.fa(title, 13.5, :on_surface, weight: "semibold")

        sub ->
          assigns = %{title: title, sub: sub}

          ~MOB"""
          <Column fill_width={true}>
            {Kati.Screens.BookDetailFa.fa(@title, 13.5, :on_surface, weight: "semibold")}
            <Spacer size={3} />
            {Kati.Screens.BookDetailFa.fa(@sub, 11.5, Palette.sub())}
          </Column>
          """
      end

    trailing =
      Keyword.get_lazy(opts, :trailing, fn ->
        if value, do: Kati.Screens.BookDetailFa.fa(value, 12.5, Palette.sub()), else: nil
      end)

    SettingsList.row(
      if(icon, do: SettingsList.icon_tile(icon), else: nil),
      body,
      SettingsList.trailing(trailing),
      on_tap: Keyword.get(opts, :on_tap)
    )
  end

  @doc false
  def warnings(b) do
    l = SampleFa.labels()

    assigns = %{count: b.warning_count}

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.card([
        Kati.UI.SettingsList.row(
          nil,
          Kati.Screens.BookDetailFa.fa(l.warnings, 13.5, :on_surface, weight: "semibold"),
          Kati.UI.SettingsList.trailing(Kati.Screens.BookDetailFa.warning_trailing(@count))
        )
      ])}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def warning_trailing(count) do
    assigns = %{count: count}

    ~MOB"""
    <Row align="center">
      {Kati.Screens.BookDetailFa.fa(@count, 12.5, Kati.Theme.Palette.sub())}
      <Spacer size={8} />
      {Kati.UI.symbol("expand_more", size: 20, color: Kati.Theme.Palette.tertiary())}
    </Row>
    """
  end

  @doc "The cream card. The user's own words, never translated — see the moduledoc."
  @spec notes() :: map()
  def notes do
    rows =
      SampleFa.notes()
      |> Enum.map(&Kati.Screens.BookDetailFa.note_row/1)
      |> Enum.intersperse(~MOB"<Spacer size={14} />")

    ~MOB"""
    <Column fill_width={true}>
      <Column fill_width={true} background={Palette.cream()} corner_radius={22} padding={17}>
        {rows}
      </Column>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def note_row(note) do
    body = if note.kind == :quote, do: "«" <> note.body <> "»", else: note.body
    assigns = %{body: body, anchor: note.anchor}

    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.BookDetailFa.fa(@body, 14, Kati.Theme.Palette.cream_body(), lines: 3)}
      <Spacer size={6} />
      {Kati.Screens.BookDetailFa.fa(@anchor, 10.5, Kati.Theme.Palette.cream_meta())}
    </Column>
    """
  end

  @doc """
  Series and ownership, with the chevron pointing the way a push goes.

  `chevron_left` and not `chevron_right`: a row that opens something opens it
  in the reading direction, and in Persian that is leftward. The same reasoning
  as the back pill's chevron, in the other direction.
  """
  @spec series(map()) :: map()
  def series(b) do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.card([
        Kati.Screens.BookDetailFa.row(b.series_line, b.series_next, nil, "menu_book",
          trailing: Kati.UI.symbol("chevron_left", size: 18, color: Palette.rail_idle()),
          on_tap: {self(), :open_series}
        ),
        Kati.Screens.BookDetailFa.row(b.lent_to, b.lent_due, nil, "inventory_2",
          trailing: Kati.UI.symbol("chevron_left", size: 18, color: Palette.rail_idle()),
          on_tap: {self(), :open_lending}
        )
      ])}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def history do
    rows = Enum.map(SampleFa.sessions(), &Kati.Screens.BookDetailFa.session_row/1)

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.card(rows)}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def session_row(session) do
    assigns = %{date: session.date, span: session.span, duration: session.duration}

    SettingsList.row(
      nil,
      ~MOB"""
      <Row fill_width={true} align="center">
        <Box width={72}>
          {Kati.Screens.BookDetailFa.fa(@date, 10.5, Kati.Theme.Palette.muted())}
        </Box>
        {Kati.Screens.BookDetailFa.fa(@span, 12.5, :on_surface)}
      </Row>
      """,
      SettingsList.trailing(Kati.Screens.BookDetailFa.fa(session.duration, 12, Palette.muted()))
    )
  end

  @doc false
  def actions do
    l = SampleFa.labels()

    seconds =
      [{"check", l.finish, :finish}, {"star", l.rate, :rate}, {"bookmarks", l.list, :add_to_list}]
      |> Enum.map(fn {icon, label, tag} -> Kati.Screens.BookDetailFa.second(icon, label, tag) end)
      |> Enum.intersperse(~MOB"<Spacer size={10} />")

    assigns = %{primary: l.primary, seconds: seconds}

    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        height={52}
        corner_radius={26}
        background={Palette.ink_fill()}
        align="center"
        on_tap={{self(), :log_progress}}
      >
        <Spacer weight={1.0} />
        {Kati.Screens.BookDetailFa.fa(@primary, 15, Palette.on_ink(), weight: "bold")}
        <Spacer weight={1.0} />
      </Row>
      <Spacer size={12} />
      <Row fill_width={true}>
        {@seconds}
      </Row>
    </Column>
    """
  end

  @doc false
  def second(icon, label, tag) do
    assigns = %{icon: icon, label: label, tap: {self(), tag}}

    ~MOB"""
    <Column weight={1.0} align="center" on_tap={@tap}>
      <Box
        width={44}
        height={44}
        corner_radius={22}
        background={Kati.Theme.Palette.card()}
        align="center"
        shadow={Kati.Theme.shadow_button()}
      >
        {Kati.UI.symbol(@icon, size: 20)}
      </Box>
      <Spacer size={7} />
      {Kati.Screens.BookDetailFa.fa(@label, 11.5, Kati.Theme.Palette.sub(),
        weight: "semibold",
        align: "center"
      )}
    </Column>
    """
  end

  def handle_info({:tap, :back}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}

  def handle_info({:tap, :log_progress}, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.LogProgressFa)}

  def handle_info({:tap, :rate}, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Rating)}

  def handle_info({:tap, _tag}, socket), do: {:noreply, socket}
  def handle_info(_message, socket), do: {:noreply, socket}
end
