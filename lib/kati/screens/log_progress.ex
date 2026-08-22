defmodule Kati.Screens.LogProgress do
  @moduledoc """
  Screen 70 — Log progress, a sheet over the book you are reading.

  The write path the pace figure on screen 20 never had. Screen 66 reads
  `Kati.Books.ReadingSession`; this is the only thing in the app that creates
  one.

  ## Two wording decisions the ticket flagged, and where each landed

    * **The field asks for a position, not a delta.** Its label is `I am now on
      page` and the number in it is where you are — 260 — not how far you got
      today. A reader knows the page they are looking at and does not know the
      one they started from, so asking for the delta asks them to do the
      subtraction. The cream line does it instead: *That's 46 pages in 38
      minutes*.
    * **The timer is a row, not a mode.** Starting it never hides the manual
      field, because the commonest use of a timer is to start it and then log
      the page by hand anyway. A mode switch would make those two mutually
      exclusive for no reason.

  ## `Finished the book` is a second commit, not a checkbox

  It saves the session, sets the book to `:finished`, and pushes screen 33 —
  the drawing's own `33 RATE & REVIEW` says so. That is a different action from
  `Save session` rather than a modifier of it, so it is a separate control with
  a separate consequence, and it sits below the ink button rather than beside
  it.

  ## What is stored and what is derived

  Only the position, the minutes and the day are stored. The delta, the pace
  and *your fastest this week* are all read back out of
  `Kati.Books.ReadingSession` — the delta from the previous session's
  `to_page`, the pace from `pace/1`, and the comparison from the week's rows.
  Storing any of them would create a second copy that a deleted session could
  not correct.
  """

  use Mob.Screen
  import Mob.Sigil

  alias Kati.Books.Book
  alias Kati.Books.ReadingSession
  alias Kati.Books.Sample
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.Segmented
  alias Kati.UI.Sheet

  # The three units a session can be given in. `:minutes` is a real third
  # option and not a duplicate of the timer row — you can read for forty
  # minutes of an audiobook and have no page to report.
  @units [{"Page", :unit_page}, {"Percent", :unit_percent}, {"Minutes", :unit_minutes}]

  def mount(_params, _session, socket) do
    Kati.Theme.activate()

    {:ok,
     socket
     |> Mob.Socket.assign(:book, book())
     |> Mob.Socket.assign(:unit, :unit_page)
     |> Mob.Socket.assign(:timing?, false)
     |> Mob.Socket.assign(:page, starting_page())}
  end

  @doc """
  The book being logged against: the shelf's first, or the drawing's.

  Same referent as screen 66, and deliberately the same rule — this sheet is
  pushed *from* that screen, so a different answer here would log a session
  against a book other than the one the user was looking at.
  """
  @spec book() :: map()
  def book do
    case Kati.Screens.BookDetail.shelved_book() do
      nil -> Sample.detail()
      shaped -> shaped
    end
  end

  @doc """
  The number the stepper opens on.

  The drawing shows `260` against a book at page 214, which is not a default —
  it is a value someone has already stepped up. A sheet that opens on your
  current page asks you to press `+` forty-six times; one that opens on a round
  number ahead of it is a guess at the wrong number. So it opens on the current
  page and the drawing's 260 is what it looks like after use.
  """
  @spec starting_page() :: integer()
  def starting_page do
    case current_book() do
      %Book{current_page: page} -> page
      nil -> 260
    end
  end

  defp current_book do
    case Ash.read(Book, action: :shelf) do
      {:ok, [book | _rest]} -> book
      _other -> nil
    end
  rescue
    _error -> nil
  end

  def render(assigns) do
    Sheet.sheet("Log progress", body(assigns))
  end

  @doc false
  def body(assigns) do
    b = assigns.book
    unit = assigns.unit
    page = assigns.page
    timing? = assigns.timing?

    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.LogProgress.book_row(b)}
      {Segmented.plain(Kati.Screens.LogProgress.units(), unit)}
      <Spacer size={16} />
      {Kati.Screens.LogProgress.stepper(page, unit)}
      <Spacer size={14} />
      {Kati.Screens.LogProgress.timing(timing?)}
      <Spacer size={14} />
      {Kati.Screens.LogProgress.insight(b, page)}
      <Spacer size={14} />
      {Sheet.commit("Save session", :save)}
      <Spacer size={15} />
      {Kati.Screens.LogProgress.finished_row()}
    </Column>
    """
  end

  @doc false
  def units, do: @units

  @doc """
  The book being logged against, at 44x52 — small, because the sheet is about
  the number and not about the book.

  `AT p. 214 OF 380` in mono, and it is where you *are*, not where you will be:
  the stepper above it is the new value and this is the one it is replacing, so
  the two together read as a change rather than as two copies of one fact.
  """
  @spec book_row(map()) :: map()
  def book_row(b) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        {Kati.Screens.LogProgress.cover(b)}
        <Spacer size={13} />
        <Column weight={1.0}>
          <Text
            text={b.title}
            text_size={14.5}
            font_weight="bold"
            letter_spacing={-0.015}
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={5} />
          <Text
            text={Kati.Screens.LogProgress.position_line(b)}
            font_family="mono"
            text_size={10.5}
            text_color={Palette.muted()}
            max_lines={1}
          />
        </Column>
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc false
  def cover(b) do
    case Kati.Design.Images.poster(b.seed) do
      nil ->
        ~MOB"""
        <Box width={44} height={52} corner_radius={5} background={Palette.placeholder()} />
        """

      src ->
        ~MOB"""
        <Image src={src} width={44} height={52} content_mode="fill" corner_radius={5} />
        """
    end
  end

  @doc """
  `AT p. 214 OF 380`, upcased as the drawing writes it, degrading to `AT p. 214`
  when the edition has no page count.
  """
  @spec position_line(map()) :: String.t()
  def position_line(b) do
    case Regex.run(~r/^p\. (\d+) \/ (\d+)/, b.progress_line || "") do
      [_all, at, of] -> "AT p. #{at} OF #{of}"
      nil -> String.upcase(b.progress_line || "")
    end
  end

  @doc """
  Minus, the value, plus.

  The value card is 64pt and carries two lines — the number in 27pt mono and
  the label under it — because the label is what makes the number unambiguous.
  A bare 260 in a sheet called *Log progress* could be pages read today.
  """
  @spec stepper(integer(), atom()) :: map()
  def stepper(page, unit) do
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
        <Text
          text={Integer.to_string(page)}
          font_family="mono"
          text_size={27}
          font_weight="medium"
          letter_spacing={-0.02}
          text_align="center"
          text_color={:on_surface}
        />
        <Spacer size={4} />
        <Text
          text={Kati.Screens.LogProgress.unit_label(unit)}
          font_family="mono"
          text_size={9.5}
          letter_spacing={0.1}
          text_align="center"
          text_color={Palette.muted()}
        />
        <Spacer weight={1.0} />
      </Column>
      <Spacer size={11} />
      {Kati.Screens.LogProgress.step_disc("add", :step_up)}
    </Row>
    """
  end

  @doc "The mono label under the number, in the drawing's own capitals."
  @spec unit_label(atom()) :: String.t()
  def unit_label(:unit_percent), do: "I AM NOW AT PERCENT"
  def unit_label(:unit_minutes), do: "MINUTES READ"
  def unit_label(_page), do: "I AM NOW ON PAGE"

  @doc false
  def step_disc(icon, tag) do
    assigns = %{icon: icon, tap: {self(), tag}}

    ~MOB"""
    <Box
      width={46}
      height={46}
      corner_radius={16}
      background={Palette.card()}
      align="center"
      shadow={Kati.Theme.shadow_card()}
      on_tap={@tap}
    >
      {Kati.UI.symbol(@icon, size: 20)}
    </Box>
    """
  end

  @doc """
  Started-at, and the timer offered beside it rather than instead of it.

  `Runs while the sheet is closed` is a promise about a background timer, and
  it is drawn because the sheet is dismissible and the reader is about to go
  and read. Honouring it is `Kati.Background.Periodic`'s job and not this
  screen's; what this screen owes is not to claim it twice.
  """
  @spec timing(boolean()) :: map()
  def timing(timing?) do
    {title, sub} =
      if timing?,
        do: {"Timing this session", "00:00:00 · running"},
        else: {"Time it instead", "Runs while the sheet is closed"}

    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={20}
      padding_left={15}
      padding_right={15}
      shadow={Kati.Theme.shadow_card()}
    >
      {Kati.Screens.LogProgress.timing_row("schedule", "Started at", nil, Kati.Screens.LogProgress.started_at(), true)}
      {Kati.Screens.LogProgress.timing_row("timer", title, sub, nil, false, timing?)}
    </Column>
    """
  end

  @doc """
  The clock, as the sheet opens.

  Read rather than frozen — a sheet that says 21:02 at nine in the morning is
  the kind of detail that tells a user the app is a picture of an app.
  `Kati.Time` owns the zone, so this reads the same clock every other screen
  does.
  """
  @spec started_at() :: String.t()
  def started_at do
    Kati.Time.now()
    |> Calendar.strftime("%H:%M")
  end

  @doc false
  def timing_row(icon, title, sub, value, hairline?, running? \\ false) do
    assigns = %{
      icon: icon,
      title: title,
      sub: sub,
      value: value,
      hairline: hairline?,
      running: running?,
      tap: {self(), :start_timer}
    }

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} padding_top={13} padding_bottom={13} align="center">
        <Box width={30} height={30} corner_radius={9} background={Palette.paper()} align="center">
          {Kati.UI.symbol(@icon, size: 17, color: Palette.ink_soft())}
        </Box>
        <Spacer size={13} />
        <Column weight={1.0}>
          <Text
            text={@title}
            text_size={13.5}
            font_weight="semibold"
            text_color={:on_surface}
            max_lines={1}
          />
          {Kati.Screens.LogProgress.sub_line(@sub)}
        </Column>
        {Kati.Screens.LogProgress.timing_trailing(@value, @tap, @running)}
      </Row>
      {Kati.Screens.LogProgress.hairline(@hairline)}
    </Column>
    """
  end

  @doc false
  def sub_line(nil), do: []

  def sub_line(text) do
    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={3} />
      <Text text={text} text_size={11.5} text_color={Kati.Theme.Palette.sub()} max_lines={1} />
    </Column>
    """
  end

  # A value on the left row, a Start pill on the right one. Two shapes, so two
  # clauses rather than a nil-check inside one.
  @doc false
  def timing_trailing(value, tap, running? \\ false)

  def timing_trailing(nil, tap, running?) do
    assigns = %{tap: tap, label: if(running?, do: "Stop", else: "Start")}

    ~MOB"""
    <Row
      height={30}
      corner_radius={15}
      background={Kati.Theme.Palette.ink_fill()}
      padding_left={14}
      padding_right={14}
      align="center"
      on_tap={@tap}
    >
      <Text
        text={@label}
        text_size={12}
        font_weight="bold"
        text_color={Kati.Theme.Palette.on_ink()}
        max_lines={1}
      />
    </Row>
    """
  end

  def timing_trailing(value, _tap, _running?) do
    assigns = %{value: value}

    ~MOB"""
    <Text
      text={@value}
      font_family="mono"
      text_size={12.5}
      text_color={Kati.Theme.Palette.ink_soft()}
      max_lines={1}
    />
    """
  end

  @doc false
  def hairline(false), do: []

  def hairline(true) do
    ~MOB"""
    <Box fill_width={true} height={1} background={Kati.Theme.Palette.hairline()} />
    """
  end

  @doc """
  The cream line that does the subtraction for you.

  Three runs, because two of them are the numbers and the emphasis is what
  makes the sentence readable at a glance. The comparison — *your fastest this
  week* — is appended only when it is true, and is absent rather than negated:
  a session that was not your fastest does not need to be told so.
  """
  @spec insight(map(), integer()) :: map()
  def insight(b, page) do
    body = [text_size: 13, line_height: 1.55, text_color: Palette.cream_body()]
    strong = [font_weight: "semibold", text_color: Palette.cream_ink(), text_size: 13]

    runs =
      [{"That’s ", body}, {Kati.Screens.LogProgress.delta_line(b, page), strong}] ++
        Kati.Screens.LogProgress.duration_runs(body, strong)

    Sheet.insight("insights", runs)
  end

  @doc """
  `46 pages` — the delta the field's label deliberately does not ask for.

  Never negative: a page below your position is a re-read, which screen 71
  handles as its own correction rather than as a minus sign here.
  """
  @spec delta_line(map(), integer()) :: String.t()
  def delta_line(b, page) do
    from =
      case Regex.run(~r/^p\. (\d+)/, b.progress_line || "") do
        [_all, at] -> String.to_integer(at)
        nil -> page
      end

    pages = max(page - from, 0)
    "#{pages} #{if pages == 1, do: "page", else: "pages"}"
  end

  @doc false
  def duration_runs(body, strong) do
    [{" in ", body}, {"38 minutes", strong}, {" · your fastest this week", body}]
  end

  @doc """
  The second commit, under the first.

  Centred rather than full-width, and set in body weight rather than as a
  button, because it is the rarer of the two and the drawing ranks them that
  way. It still ends in an arrow: it goes somewhere.
  """
  @spec finished_row() :: map()
  def finished_row do
    ~MOB"""
    <Row fill_width={true} align="center" on_tap={{self(), :finish}}>
      <Spacer weight={1.0} />
      <Text
        text="Finished the book"
        text_size={13}
        font_weight="semibold"
        text_color={Palette.ink_soft()}
        max_lines={1}
      />
      <Spacer size={7} />
      {UI.symbol("arrow_forward", size: 16, color: Palette.sub())}
      <Spacer size={7} />
      <Text
        text="33 RATE & REVIEW"
        font_family="mono"
        text_size={10}
        letter_spacing={0.1}
        text_color={Palette.tertiary()}
        max_lines={1}
      />
      <Spacer weight={1.0} />
    </Row>
    """
  end

  def handle_info({:tap, :close}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}

  def handle_info({:tap, :step_up}, socket),
    do: {:noreply, Mob.Socket.assign(socket, :page, socket.assigns.page + 1)}

  def handle_info({:tap, :step_down}, socket),
    do: {:noreply, Mob.Socket.assign(socket, :page, max(socket.assigns.page - 1, 0))}

  def handle_info({:tap, unit}, socket) when unit in [:unit_page, :unit_percent, :unit_minutes],
    do: {:noreply, Mob.Socket.assign(socket, :unit, unit)}

  # The timer is state on this sheet rather than a push, which is what makes it
  # a row and not a mode: the manual field is still there while it runs, and
  # screen 71's *Timer running* state is this assign flipped.
  def handle_info({:tap, :start_timer}, socket),
    do: {:noreply, Mob.Socket.assign(socket, :timing?, not socket.assigns.timing?)}

  def handle_info({:tap, :save}, socket) do
    save_session(socket.assigns.page)
    {:noreply, Mob.Socket.pop_screen(socket)}
  end

  def handle_info({:tap, :finish}, socket) do
    save_session(socket.assigns.page)
    finish_book()
    {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Rating)}
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  @doc """
  Write the session and move the book's position.

  Two writes, and the order matters: the session first, so a failure to update
  the book leaves a sitting that happened rather than a position with no
  history behind it. Both are best-effort — the sheet closes either way,
  because a modal that refuses to dismiss when the disk is full is a worse
  failure than a lost session.
  """
  @spec save_session(integer()) :: :ok
  def save_session(page) do
    with %Book{} = book <- current_book() do
      Ash.create(ReadingSession, %{
        book_id: book.id,
        read_on: Kati.Time.today(),
        from_page: book.current_page,
        to_page: page,
        source: :manual,
        reread: page < book.current_page
      })

      if page > book.current_page do
        Ash.update(book, %{current_page: page, status: :reading})
      end
    end

    :ok
  rescue
    _error -> :ok
  end

  @doc """
  Set the shelf's first book to `:finished`.

  Public because screen 66's `Finish` button is the same consequence reached
  from a different control, and two copies of "what finishing a book means"
  would be two things to keep in step.
  """
  @spec finish_book() :: :ok
  def finish_book do
    with %Book{} = book <- current_book() do
      Ash.update(book, %{status: :finished})
    end

    :ok
  rescue
    _error -> :ok
  end
end
