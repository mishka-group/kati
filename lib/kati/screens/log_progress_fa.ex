defmodule Kati.Screens.LogProgressFa do
  @moduledoc """
  Screen 72 — ثبت پیشرفت, the Persian reading-session sheet.

  Screen 70 in the mirror, and the caption names three things that move and one
  that must not.

  ## What moves

    * **The sheet's close disc goes to the leading edge**, which in Persian is
      the right. `Kati.UI.Sheet.header/1` puts the disc first in a `Row` and
      the root declares `rtl`, so start-to-end layout puts it there without a
      second arrangement — the same mechanism that puts the Persian dock's home
      tab on the right.
    * **The segment order reverses**, for the same reason and by the same
      mechanism.
    * **Every string is Vazirmatn.** Plus Jakarta Sans has no Arabic-script
      glyphs at all, so a Persian label without `font_family="fa"` is a row of
      empty boxes rather than a fallback.

  ## What does not

  **The timer face does not flip.** `۰۰:۳۸:۱۲` reads left to right in both
  languages, because the direction of time is not the direction of reading. A
  mirrored elapsed-time readout would put the hours where the seconds belong,
  which is the one thing on this sheet that would be actively wrong rather than
  merely unfamiliar.

  The stepper column also stays symmetrical, so the mono numeral still aligns
  under itself when the value grows a digit.

  ## The copy is a proposal

  The caption says so: *all Persian copy was open; these strings are
  proposals.* `Kati.Books.SampleFa.sheet/0` holds them in one place for exactly
  that reason — when a native reader corrects one, it is corrected once.
  """

  use Mob.Screen
  import Mob.Sigil

  alias Kati.Books.SampleFa
  alias Kati.Theme.Palette
  alias Kati.UI

  def mount(params, _session, socket) do
    Kati.Theme.activate()

    {:ok,
     socket
     |> Mob.Socket.assign(:sheet, sheet(Map.get(params || %{}, :book_id)))
     |> Mob.Socket.assign(:unit, :unit_page)
     |> Mob.Socket.assign(:page, 260)}
  end

  @doc """
  The sheet this screen draws: the drawing's, with the named book's own fields
  over it.

  `nil` is the whole of today's behaviour and stays literally that —
  `Kati.Books.SampleFa.sheet/0` and nothing else — because screen 72 is compared
  against its drawing through `Kati.Screens.Gallery`, which pushes it with no
  params. An id that names no row answers the same, which is
  `Kati.Screens.BookDetail.shelved_book/1`'s rule: a book deleted under you
  draws the drawing, never somebody else's.

  A named book replaces exactly what `own/1` lists, and no more. The position
  line and the timer face stay the drawing's for the reason the moduledoc gives
  about the copy: shaping `ص. ۲۱۴ از ۳۸۰` out of a page count is Persian copy
  this board's caption calls a proposal, and it belongs beside the Gregorian
  shaping in `Kati.Books` rather than being invented on a screen.
  """
  @spec sheet(String.t() | nil) :: map()
  def sheet(nil), do: SampleFa.sheet()

  def sheet(id) when is_binary(id) do
    case Kati.Screens.BookDetail.shelved_book(id) do
      nil -> SampleFa.sheet()
      shelved -> Map.merge(SampleFa.sheet(), own(shelved))
    end
  end

  @doc """
  The parts of a shelved book that this sheet can say without translating them.

  `Kati.Screens.BookDetailFa.own/1`'s doctrine, and deliberately shorter: a
  title and a cover. Both are the user's own and neither is a word Kati wrote,
  so neither is touched. Everything else on the sheet is chrome and stays in the
  language the board is drawn in.
  """
  @spec own(map()) :: map()
  def own(shelved), do: %{book: shelved.title, seed: shelved.seed}

  def render(assigns) do
    s = assigns.sheet

    ~MOB"""
    <Box
      fill_width={true}
      fill_height={true}
      background={:background}
      layout_direction="rtl"
      accessibility_id={Kati.Screens.Identity.of(__MODULE__)}
    >
      <Box fill_width={true} fill_height={true} background={Kati.UI.Sheet.scrim()} />
      <Box fill_width={true} fill_height={true} align="bottom">
        <Box fill_width={true} height={40} background={Palette.paper()} />
        <Column
          fill_width={true}
          background={Palette.paper()}
          corner_radius={26}
          padding_left={21}
          padding_right={21}
          padding_top={18}
          padding_bottom={34}
        >
          {Kati.Screens.LogProgressFa.header(s.title)}
          {Kati.Screens.LogProgressFa.book_row(s)}
          {Kati.Screens.LogProgressFa.segments(s.units, assigns.unit)}
          <Spacer size={16} />
          {Kati.Screens.LogProgressFa.stepper(s, assigns.page)}
          <Spacer size={14} />
          {Kati.Screens.LogProgressFa.timer(s)}
          <Spacer size={14} />
          {Kati.Screens.LogProgressFa.timing(s)}
          <Spacer size={14} />
          {Kati.Screens.LogProgressFa.insight(s)}
          <Spacer size={14} />
          {Kati.Screens.LogProgressFa.commit(s.commit)}
        </Column>
      </Box>
    </Box>
    """
  end

  @doc """
  The sheet header: close disc, centred title, and the hole that centres it.

  `Kati.UI.Sheet.header/1`'s arrangement with a Persian `Text` — the shared one
  builds its own and would draw boxes. See `Kati.Screens.Fa`'s moduledoc: a
  component that builds its own `Text` cannot draw Persian.
  """
  @spec header(String.t()) :: map()
  def header(title) do
    assigns = %{title: title}

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        {Kati.UI.Sheet.close_disc()}
        <Box weight={1.0}>
          {Kati.Screens.BookDetailFa.fa(@title, 15, :on_surface, weight: "bold", align: "center")}
        </Box>
        <Box width={36} height={36} />
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc false
  def book_row(s) do
    # The drawing's cover seed is the DEFAULT rather than the value: a sheet
    # handed a book draws that book's cover, and a sheet handed nothing draws
    # `bookaa1`, which is what the board was captured with. Bound out here
    # rather than written inside the sigil so the fallback is one expression
    # and not a branch in the markup.
    assigns = %{s: s, cover: %{seed: Map.get(s, :seed, "bookaa1")}}

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        {Kati.Screens.LogProgress.cover(@cover)}
        <Spacer size={13} />
        <Column weight={1.0}>
          {Kati.Screens.BookDetailFa.fa(@s.book, 14.5, :on_surface, weight: "bold")}
          <Spacer size={5} />
          {Kati.Screens.BookDetailFa.fa(@s.position, 10.5, Palette.muted())}
        </Column>
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc """
  The three unit segments, in Persian.

  Hand-rolled rather than `Kati.UI.Segmented.plain/2` for the reason
  `Kati.Screens.BookDetailFa.chips/3` gives about chips: the shared control
  paints its own label, and a Persian label through that door is a row of
  boxes. Same geometry, own `Text`.
  """
  @spec segments([{String.t(), atom()}], atom()) :: map()
  def segments(units, selected) do
    segments =
      units
      |> Enum.map(fn {label, tag} ->
        Kati.Screens.LogProgressFa.segment(label, tag, tag == selected)
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

  @doc false
  def segment(label, tag, true) do
    assigns = %{label: label, tap: {self(), tag}}

    ~MOB"""
    <Box weight={1.0} on_tap={@tap}>
      <Row
        fill_width={true}
        height={34}
        corner_radius={12}
        background={Palette.card()}
        shadow="0 1 2 0 #0F1A1917"
        align="center"
      >
        <Spacer weight={1.0} />
        {Kati.Screens.BookDetailFa.fa(@label, 12.5, :on_surface, weight: "bold")}
        <Spacer weight={1.0} />
      </Row>
    </Box>
    """
  end

  def segment(label, tag, false) do
    assigns = %{label: label, tap: {self(), tag}}

    ~MOB"""
    <Box weight={1.0} on_tap={@tap}>
      <Row fill_width={true} height={34} align="center">
        <Spacer weight={1.0} />
        {Kati.Screens.BookDetailFa.fa(@label, 12.5, Palette.segment_idle(), weight: "semibold")}
        <Spacer weight={1.0} />
      </Row>
    </Box>
    """
  end

  @doc """
  Minus, the value, plus — and the column stays symmetrical.

  The caption asks for that by name: the two discs are the same size and sit at
  the same inset either side, so the mono numeral between them keeps its centre
  when it grows a digit. A stepper whose value drifted as it counted would be
  the one thing on the sheet that moved while you used it.
  """
  @spec stepper(map(), integer()) :: map()
  def stepper(s, page) do
    # The value is an integer here and a Persian numeral on the way out, so the
    # stepper counts in the language arithmetic is done in and prints in the
    # language the reader reads. `Kati.I18n.Digits.to_persian/1` is the one
    # conversion, and the fixture's `۲۶۰` is what it produces for 260.
    assigns = %{page: Kati.I18n.Digits.to_persian(page), label: s.unit_label}

    ~MOB"""
    <Row fill_width={true} align="center">
      {Kati.Screens.LogProgress.step_disc("remove", :step_down)}
      <Spacer size={11} />
      <Column
        weight={1.0}
        height={64}
        corner_radius={20}
        background={Palette.card()}
        shadow={Kati.Theme.shadow_card()}
        align="center"
      >
        <Spacer weight={1.0} />
        {Kati.Screens.BookDetailFa.fa(@page, 27, :on_surface, weight: "medium", align: "center")}
        <Spacer size={4} />
        {Kati.Screens.BookDetailFa.fa(@label, 9.5, Palette.muted(), align: "center")}
        <Spacer weight={1.0} />
      </Column>
      <Spacer size={11} />
      {Kati.Screens.LogProgress.step_disc("add", :step_up)}
    </Row>
    """
  end

  @doc """
  The running timer, and the one node on this screen that is not mirrored.

  `layout_direction="ltr"` on the face itself. `۰۰:۳۸:۱۲` is hours, minutes,
  seconds in that order in every language, and reversing it would put the hours
  where the seconds belong. The caption says so in as many words: *the timer
  face does not flip — elapsed time reads left-to-right in both languages,
  because direction of time is not direction of reading.*
  """
  @spec timer(map()) :: map()
  def timer(s) do
    assigns = %{elapsed: s.timer, stop: s.stop}

    ~MOB"""
    <Row
      fill_width={true}
      height={54}
      corner_radius={20}
      background={Palette.card()}
      shadow={Kati.Theme.shadow_card()}
      padding_left={16}
      padding_right={16}
      align="center"
    >
      <Box layout_direction="ltr">
        {Kati.Screens.BookDetailFa.fa(@elapsed, 19, :on_surface, weight: "medium")}
      </Box>
      <Spacer weight={1.0} />
      <Row
        height={32}
        corner_radius={16}
        background={Palette.ink_fill()}
        padding_left={14}
        padding_right={14}
        align="center"
        on_tap={{self(), :stop_timer}}
      >
        {Kati.Screens.BookDetailFa.fa(@stop, 12, Palette.on_ink(), weight: "bold")}
      </Row>
    </Row>
    """
  end

  @doc false
  def timing(s) do
    assigns = %{label: s.started_label, at: s.started_at}

    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={20}
      padding_left={15}
      padding_right={15}
      shadow={Kati.Theme.shadow_card()}
    >
      <Row fill_width={true} padding_top={13} padding_bottom={13} align="center">
        <Box width={30} height={30} corner_radius={9} background={Palette.paper()} align="center">
          {UI.symbol("schedule", size: 17, color: Palette.ink_soft())}
        </Box>
        <Spacer size={13} />
        <Box weight={1.0}>
          {Kati.Screens.BookDetailFa.fa(@label, 13.5, :on_surface, weight: "semibold")}
        </Box>
        {Kati.Screens.BookDetailFa.fa(@at, 12.5, Palette.ink_soft())}
      </Row>
    </Column>
    """
  end

  @doc """
  The cream line, built from five Persian runs.

  Five `Text` nodes rather than `Kati.UI.rich_text/1`: that helper merges its
  runs into one node and drops the per-run font, which on a Persian screen
  means one of the five decides the face for all of them.
  """
  @spec insight(map()) :: map()
  def insight(s) do
    assigns = %{s: s}

    ~MOB"""
    <Column fill_width={true} background={Palette.cream()} corner_radius={20} padding={15}>
      <Row fill_width={true} align="top">
        {UI.symbol("lightbulb", size: 18, color: Palette.gold_icon())}
        <Spacer size={11} />
        <Column weight={1.0}>
          <Row fill_width={true} align="center">
            {Kati.Screens.BookDetailFa.fa(@s.insight_lead, 13, Palette.cream_body())}
            <Spacer size={5} />
            {Kati.Screens.BookDetailFa.fa(@s.insight_pages, 13, Palette.cream_ink(), weight: "semibold")}
            <Spacer size={5} />
            {Kati.Screens.BookDetailFa.fa(@s.insight_middle, 13, Palette.cream_body())}
            <Spacer size={5} />
            {Kati.Screens.BookDetailFa.fa(@s.insight_minutes, 13, Palette.cream_ink(), weight: "semibold")}
            <Spacer weight={1.0} />
          </Row>
          <Spacer size={4} />
          {Kati.Screens.BookDetailFa.fa(@s.insight_tail, 13, Palette.cream_body(), lines: 2)}
        </Column>
      </Row>
    </Column>
    """
  end

  @doc false
  def commit(label) do
    assigns = %{label: label}

    ~MOB"""
    <Row
      fill_width={true}
      height={54}
      corner_radius={27}
      background={Palette.ink_fill()}
      align="center"
      on_tap={{self(), :save}}
    >
      <Spacer weight={1.0} />
      {Kati.Screens.BookDetailFa.fa(@label, 14.5, Palette.on_ink(), weight: "bold")}
      <Spacer weight={1.0} />
    </Row>
    """
  end

  def handle_info({:tap, :close}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}
  def handle_info({:tap, :save}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}

  def handle_info({:tap, unit}, socket) when unit in [:unit_page, :unit_percent, :unit_minutes],
    do: {:noreply, Mob.Socket.assign(socket, :unit, unit)}

  def handle_info({:tap, :step_up}, socket),
    do: {:noreply, Mob.Socket.assign(socket, :page, socket.assigns.page + 1)}

  def handle_info({:tap, :step_down}, socket),
    do: {:noreply, Mob.Socket.assign(socket, :page, max(socket.assigns.page - 1, 0))}

  def handle_info({:tap, _tag}, socket), do: {:noreply, socket}
  def handle_info(_message, socket), do: {:noreply, socket}
end
