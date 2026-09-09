defmodule Kati.Screens.Discover do
  @moduledoc """
  Screen 11 — Discover, pushed under Library.

  Built to `test/design/screens/11.html`: a chip row, a three-poster rail
  of matches, a card of people you follow, and the titles about to leave a
  service.

  Two of the three sections are recommendations and one is a deadline, and the
  design marks the difference with the eyebrow dash rather than with a
  different layout. "Because you watched" and "People you follow" get the
  orange dash because something is new; "Leaving Lumen+ in 7 days" gets the
  grey one, because a thing disappearing is not a thing arriving. That is
  `Kati.UI.Eyebrow.quiet/1`.

  A person's row ends in an orange dot when they have news and a muted `check`
  when they do not — the same distinction, at row scale, and the reason the
  sample carries someone with nothing new.

  The rail is three posters with 12pt gutters, each taking an equal share of
  whatever is left. The drawing's 112pt is arithmetic for its own 402pt frame —
  112*3 + 12*2 = 360 — and a real 411dp device leaves ~370dp between the 21pt
  margins, so a fixed 112 stops ~9dp short and ragged. Weighting the three
  columns keeps the row exactly full at any width, which is what the drawing
  meant.

  ## What the chips select

  The chip row names the sections underneath it, so a chip keeps the section it
  names and drops the others. **"For you" is the whole feed**, which is what the
  drawing shows and therefore what the screen shows at rest — the default is
  read off the sample's own `selected` flag rather than typed here, so the
  resting screen cannot drift from the data.

  "Awards" names a section this feed does not carry, so it does not relabel one
  of the others as awards. Screen 03 makes the same trade with its Books and
  Music shelves: showing the emptiness honestly beats a chip that lies about
  what is behind it.

  Showing it honestly is `no_section/2`, and it had to be built:
  MOVIES-AND-TV.md #24 found that the chip emptied the page and drew NOTHING —
  a rail floating over blank paper, which reads as a broken screen rather than
  as an honest answer. On a device the rail is not drawn at all unless the feed
  has two sections, but the board's own fixture has four chips and a fresh
  install sees it.

  ## Schedule

  The button on a leaving row is that row's only control, so it has to change
  when it is used. Scheduled swaps the ink pill for the toned one screen 10
  gives a row that has stopped asking for anything, and says `Scheduled`.
  Tapping it again undoes it — nothing here writes to a store yet, so the
  screen owns the state and reversing it is the honest affordance.

  ## Why this screen still reads `Kati.Screens.Discover.Sample`

  Screen 03 moved onto `Kati.Media` (see `Kati.Screens.Library.shelf/0`) and
  screen 10 with it. This one did not, and it is the furthest of the four from
  being able to: the drawing's own caption says the feed is *"recommendations
  built only from your own history, plus people you follow"*, and Kati has
  neither a recommender nor a person. Every one of the three sections is a
  fact about the world outside the library, and `Kati.Media` holds only what a
  provider said about a title and what the user did with it.

  Precisely what this screen draws and no resource can currently express:

    * **the picks and their `94% match`** — a recommendation and its score.
      Nothing scores a title against a history, and there is no column to keep
      a score in. `Kati.Media.CachedTitle` is a projection of one provider
      record; a match is a statement about two.
    * **`People you follow`, and every part of a person's row** — the name,
      the role (`Director` / `Writer` / `Actor`), the credit count
      (`2 new projects`), and the trailing mark that says whether there is
      news. There is no person anywhere in the app, and that is a decision
      rather than an omission: `Kati.Media.Watch.companions` says so outright
      — *"Kati has no people table and no contacts permission, and inventing
      either to hold the word 'Jo' would be a larger privacy decision than the
      feature is asking for."* That column is also who you watched *with*,
      which is not who you follow.
    * **`Leaving Lumen+ in 7 days`, and the rows under it** — an availability
      window on a named service. There is no service resource and nothing
      stores when a title leaves one. `Kati.Media.Watch.service` is again a
      past fact about the user, not a catalogue.
    * **`Tuned to 128 titles`** — the size of the corpus the recommender is
      tuned to. `Ash.count!(Kati.Media.TrackedTitle)` is a *different* number
      wearing this one's caption, and on a seeded install it is nine.
    * **the `Leaving` chip's `5`** — a count of the section above.

  One line here *is* reachable today and is deliberately not split out:
  `Because you watched The Long Hollow` is the newest touched
  `Kati.Media.TrackedTitle` joined to its `Kati.Media.CachedTitle.title`. It
  stays frozen with the rest because it is the heading *over* the picks, and a
  real sentence above three invented posters claims more for them than drawing
  both from the sample does.
  """
  use Kati.Screens.Pushed, back: "Library"

  alias Kati.Components.MishkaAvatar
  alias Kati.Components.MishkaChip
  alias Kati.Components.MishkaScrollArea
  alias Kati.Components.MishkaSeparator
  alias Kati.Media.Recommendations
  alias Kati.Screens.Discover.Sample
  alias Kati.Theme.Palette
  alias Kati.UI

  @impl true
  def load(socket) do
    choice = Kati.Discover.Filters.current()
    feed = feed(choice)

    socket
    |> Mob.Socket.assign(
      filters: choice,
      # TMDB's `total_results` for the last answer, which is what board 169's
      # footer is given. `nil` until one arrives, and never inferred from the
      # twenty rows a page holds.
      total: nil,
      feed: feed,
      chip: Kati.Screens.Discover.default_chip(feed),
      # Always `[]` now, and kept as an assign rather than removed: it is what
      # `leaving_row/2` reads to draw the *Scheduled* state, and board 11 draws
      # both states. See `leaving_action/2` for why neither is tappable.
      scheduled: [],
      tune?: false,
      seed_id: Map.get(feed, :seed_id),
      add_error: nil
    )
    |> ask()
  end

  @doc """
  The feed: the reader's, or the drawing's.

  Screen 04's gate on a screen where it decides more than usual. An empty store
  — or a store whose newest title has no cache row behind it — has nothing to
  recommend FROM, so it gets `Kati.Screens.Discover.Sample.feed()` whole, which
  is the state board 11 was captured in.

  A store with a title in it gets a feed with one section: the picks, under the
  title they came from. The other two are `[]` and stay `[]`, because there is
  no person in this app and no offers resource — see the moduledoc, which lists
  what each would need. The chips go with the sections they name.

  `picks` starts empty on purpose. The request has not been made yet; `ask/1`
  makes it, and `handle_info/2` fills it in.
  """
  @spec feed() :: map()
  def feed, do: feed(Kati.Discover.Filters.current())

  @doc """
  The feed under a filter choice.

  Three states rather than two now. A narrowed sheet browses TMDB and needs
  nothing on the shelf, so it wins over both of the others — which is what
  makes board 169 worth having on a device that has tracked nothing: the page
  had exactly one honest thing to draw for that reader, and it was the drawing.
  """
  @spec feed(map()) :: map()
  def feed(choice) do
    cond do
      Kati.Discover.Filters.narrowed?(choice) ->
        browse_feed(choice)

      true ->
        case Recommendations.seed() do
          nil -> Sample.feed()
          {_tracked, cached} -> real_feed(cached)
        end
    end
  end

  @doc """
  A feed that came from board 169's sheet rather than from a title.

  `because` is the heading over the rail, and under a filter it is not a
  *because* at all — nothing was watched to produce it. It says what was asked
  instead, which `Kati.Screens.Discover.asked_line/1` builds out of the choice
  itself so the heading and the request cannot part company.
  """
  @spec browse_feed(map()) :: map()
  def browse_feed(choice) do
    %{
      subtitle: nil,
      chips: [%{label: "For you", count: nil, selected: true}],
      because: Kati.Screens.Discover.asked_line(choice),
      seed_id: nil,
      picks: [],
      asked?: true,
      picks_error: nil,
      people: [],
      leaving_label: nil,
      leaving: []
    }
  end

  @doc """
  What the rail's heading says under a filter — the question, not a premise.

      iex> Kati.Screens.Discover.asked_line(%{kind: :tv, sort: :popular, rating: nil})
      "Most popular series"

      iex> Kati.Screens.Discover.asked_line(%{kind: nil, sort: :newest, rating: :r8})
      "Newest films, 8.0 and up"

  Film when no kind is chosen, because `/discover` is one kind per request and
  `Kati.Discover.Filters.endpoint/1` resolves it to film — so the heading names
  what was actually asked rather than implying both were.
  """
  @spec asked_line(map()) :: String.t()
  def asked_line(choice) do
    noun = if Kati.Discover.Filters.endpoint(choice) == :tv, do: "series", else: "films"
    {sort, _sub} = Kati.Discover.Filters.sort_label(Map.get(choice, :sort))

    case Map.get(choice, :rating) do
      nil -> "#{sort} #{noun}"
      rating -> "#{sort} #{noun}, #{Kati.Discover.Filters.rating_label(rating)}"
    end
  end

  @doc false
  @spec real_feed(Kati.Media.CachedTitle.t()) :: map()
  def real_feed(cached) do
    %{
      # `Tuned to 128 titles` is the size of a corpus a recommender was tuned
      # to, and Kati runs no recommender. `Ash.count!` of the shelf would be a
      # different number wearing this one's caption. So the line is absent, and
      # `header/1` closes the gap.
      subtitle: nil,
      chips: [%{label: "For you", count: nil, selected: true}],
      because: Recommendations.because(cached.title),
      seed_id: cached.source_id,
      picks: [],
      asked?: true,
      picks_error: nil,
      people: [],
      leaving_label: nil,
      leaving: []
    }
  end

  @doc """
  A *Schedule* button's tap, which is always `nil`. See `leaving_action/2`.

      iex> Kati.Screens.Discover.schedule_tap(%{title: "Anything"})
      nil
  """
  @spec schedule_tap(map()) :: nil
  def schedule_tap(_row), do: nil

  @doc """
  Whether this page has a shelf to be tuned against.

  More than one title, and not the board's. One title is not a choice — the
  feed is already seeded on it — and the drawing has no shelf at all.

      iex> Kati.Screens.Discover.tunable?(Kati.Screens.Discover.Sample.feed())
      false
  """
  @spec tunable?(map()) :: boolean()
  def tunable?(feed) do
    is_binary(Map.get(feed, :seed_id)) and length(Recommendations.seedable()) > 1
  end

  @doc false
  def tune_panel(_feed, false), do: ~MOB"<Spacer size={0} />"

  def tune_panel(feed, true) do
    assigns = %{
      chips:
        Recommendations.seedable()
        |> Enum.map(fn {_tracked, cached} ->
          Kati.Screens.Discover.seed_chip(cached, cached.source_id == Map.get(feed, :seed_id))
        end)
        |> Enum.intersperse(~MOB"<Spacer size={7} />")
    }

    ~MOB"""
    <Column fill_width={true}>
      <Text
        text="PICKS FROM"
        font_family="mono"
        text_size={10.5}
        letter_spacing={0.16}
        text_color={Palette.eyebrow()}
        max_lines={1}
      />
      <Spacer size={9} />
      <Row fill_width={true} align="center">
        {@chips}
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

  # `MishkaPill`, not `MishkaChip`, and this cost a round: the chip takes no
  # `on_tap` and no per-edge padding, so it drew the label and silently dropped
  # both — a rail of titles that could not be pressed. `Kati.Screens.Rating`'s
  # tags are the same shape for the same reason.
  @doc false
  def seed_chip(cached, on?) do
    Kati.Components.MishkaPill.pill(
      label: cached.title,
      background: if(on?, do: Palette.ink_fill(), else: Palette.card()),
      color: if(on?, do: Palette.on_ink(), else: Palette.ink_soft()),
      shadow: Kati.Theme.shadow_card_soft(),
      height: 30,
      corner_radius: 15,
      padding: 0,
      padding_left: 13,
      padding_right: 13,
      text_size: 12,
      font_weight: :semibold,
      align: :center,
      on_tap: {self(), String.to_atom("seed_on_" <> cached.source_id)}
    )
  end

  @doc """
  Redraw the picks from a different title.

  The whole feed is rebuilt rather than the heading swapped, because *Because
  you watched X* and the posters under it are one answer: a heading naming a
  show over picks fetched for another is the substitution this app spends most
  of its moduledocs preventing. `picks` goes back to `[]` and `ask/1` makes the
  request again — the same shape a mount takes, which is what `handle_info/2`
  is already written to receive.
  """
  @spec reseed(Mob.Socket.t(), String.t()) :: Mob.Socket.t()
  def reseed(socket, source_id) do
    case Recommendations.seed(source_id) do
      nil ->
        socket

      {_tracked, cached} ->
        Recommendations.ask(self(), cached)

        socket
        |> Mob.Socket.assign(:feed, Kati.Screens.Discover.real_feed(cached))
        |> Mob.Socket.assign(:seed_id, cached.source_id)
        |> Mob.Socket.assign(:tune?, false)
        |> Mob.Socket.assign(:add_error, nil)
    end
  end

  # Nothing to ask about when the screen is drawing its board: the sample's
  # three picks are already there, and a request keyed on a title nobody
  # tracks has nothing to be keyed on.
  defp ask(socket) do
    choice = Map.get(socket.assigns, :filters, Kati.Discover.Filters.resting())

    if Kati.Discover.Filters.narrowed?(choice) do
      Recommendations.browse(self(), choice, Kati.Time.today())
      socket
    else
      case Recommendations.seed() do
        nil ->
          socket

        {_tracked, cached} ->
          Recommendations.ask(self(), cached)
          socket
      end
    end
  end

  @doc """
  Picks, when they arrive — or an answer about a title this page is not on.

  `seed_id` is compared rather than trusted, for `Kati.Media.SearchDebounce`'s
  reason: the reader can have touched something else and reopened this screen
  while a request was in flight, and a rail of recommendations for the wrong
  premise is exactly the defect this whole change is about.
  """
  @impl true
  def handle_info({:recommendations, seed_id, result}, socket) do
    feed = socket.assigns.feed

    if Map.get(feed, :seed_id) == seed_id do
      {:noreply, Mob.Socket.assign(socket, :feed, answered(feed, result))}
    else
      {:noreply, socket}
    end
  end

  # A browse, when it arrives. The choice is compared rather than trusted, for
  # the reason the clause above compares the seed: a chip can have moved while
  # the request was in flight, and a rail drawn under the wrong filter is the
  # same defect as one drawn under the wrong premise.
  def handle_info({:discover, choice, result}, socket) do
    if Map.get(socket.assigns, :filters) == choice do
      {:noreply,
       socket
       |> Mob.Socket.assign(:feed, Kati.Screens.Discover.browsed(socket.assigns.feed, result))
       |> Mob.Socket.assign(:total, Kati.Screens.Discover.total_of(result))}
    else
      {:noreply, socket}
    end
  end

  # `Kati.Screens.Pushed` marks `handle_info/2` overridable, so defining a
  # clause here replaces ALL of its clauses — the back pill, `rescue_tap/3` and
  # the `{:kati, …}` bridge among them. `super/2` is what hands the rest back,
  # and without it this screen's own chips would stop answering.
  def handle_info(message, socket), do: super(message, socket)

  @doc """
  Coming back from the sheet: re-read the choice, redraw, re-ask.

  The sheet writes every tap straight through to `Kati.Discover.Filters` — it
  has no *Apply* — so what has to happen here is a read rather than a message
  with a payload. `Kati.Screens.Library` does the same on the same topic for
  the same sheet-shaped reason.
  """
  @impl true
  def handle_kati(:resumed, _payload, socket) do
    choice = Kati.Discover.Filters.current()

    if choice == Map.get(socket.assigns, :filters) do
      {:noreply, socket}
    else
      feed = Kati.Screens.Discover.feed(choice)

      {:noreply,
       socket
       |> Mob.Socket.assign(
         filters: choice,
         feed: feed,
         chip: Kati.Screens.Discover.default_chip(feed),
         seed_id: Map.get(feed, :seed_id),
         total: nil
       )
       |> ask()}
    end
  end

  def handle_kati(_topic, _payload, socket), do: {:noreply, socket}

  @doc """
  The chip the data marks selected.

  Read rather than typed: the resting screen is compared against the drawing,
  and the drawing's selected chip lives in the sample. Taking it from there
  means the two cannot disagree.
  """
  @spec default_chip(map()) :: String.t()
  def default_chip(feed) do
    Enum.find_value(feed.chips, "For you", fn c -> if c.selected, do: c.label end)
  end

  @doc """
  Whether a section survives the selected chip.

  See the moduledoc: "For you" is everything, "People" and "Leaving" narrow to
  the section they name, and a chip naming a section this feed has none of
  keeps nothing.
  """
  @spec shows?(atom(), String.t()) :: boolean()
  def shows?(section, chip) do
    case chip do
      "For you" -> true
      "People" -> section == :people
      "Leaving" -> section == :leaving
      _ -> false
    end
  end

  @doc false
  def content(assigns) do
    f = assigns.feed
    chip = assigns.chip
    scheduled = assigns.scheduled

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {Kati.Screens.Discover.pill_row()}
        {Kati.Screens.Discover.header(f, Kati.Screens.Discover.tunable?(f), Map.get(assigns, :filters))}
        {Kati.Screens.Discover.tune_panel(f, Map.get(assigns, :tune?, false))}
        {Kati.Screens.Discover.chips(f, chip)}
        {Kati.Screens.Discover.add_error(Map.get(assigns, :add_error))}
        {Kati.Screens.Discover.because_section(f, chip)}
        {Kati.Screens.Discover.people_section(f, chip)}
        {Kati.Screens.Discover.leaving_section(f, chip, scheduled)}
        {Kati.Screens.Discover.no_section(f, chip)}
      </Column>
    </Scroll>
    """
  end

  # The drawing gives the back pill a row of its own — 42pt tall with 16pt
  # under it — before the title. Kati.Screens.Pushed floats the pill, so this
  # reserves the space it occupies rather than drawing a second one.
  @doc false
  def pill_row, do: ~MOB"<Spacer size={58} />"

  @doc """
  The `sort` disc that opens board 169's sheet, and nothing at all over a
  drawing.

  ## Why this is a SECOND disc, next to `tune`

  `Kati.Screens.Library`'s moduledoc settles the rule this looks like it
  breaks: *"a filter disc beside a sort disc opening the same sheet would be
  two doors into one room from one wall"*. These open two different rooms.
  `tune` answers **what the picks come from** — which of your own titles the
  feed is seeded on — and this answers **how they are sorted and narrowed**,
  which is a browse of TMDB and does not involve your shelf at all. One is a
  premise and the other is a query.

  `sort` and not `filter_list`: the glyph has to be one of the 140 in
  `Kati.Icons`, which is the subset the shipped font actually carries, and a
  name outside it raises rather than drawing a blank. It is also the same disc
  screen 03 uses to open the same kind of sheet, so the idiom is the app's own
  rather than this page's.

  It is lit when something is narrowing the feed, so a reader who set a filter
  and came back a day later can see that they did without opening the sheet —
  the state board 145's own disc does not carry and `Kati.Library.ShelfFilters`
  wanted.

  `nil` draws nothing: over the sample feed there is no live choice, and a
  control that exists only over data is not drawn live over a drawing of it —
  the rule the `tune` disc below records.
  """
  @spec filter_disc(map() | nil) :: map()
  def filter_disc(nil), do: ~MOB"<Spacer size={0} />"

  def filter_disc(choice) do
    assigns = %{on?: Kati.Discover.Filters.narrowed?(choice)}

    ~MOB"""
    <Row align="center">
      <Box
        width={44}
        height={44}
        corner_radius={22}
        background={if @on?, do: Palette.ink_fill(), else: Palette.card()}
        shadow={Kati.Theme.shadow_button()}
        align="center"
        on_tap={{self(), :open_filters}}
      >
        {Kati.UI.symbol("sort", size: 21, color: if(@on?, do: Palette.on_ink(), else: Palette.ink()))}
      </Box>
      <Spacer size={9} />
    </Row>
    """
  end

  @doc """
  The title, and the `tune` disc that decides what the picks come FROM.

  MOVIES-AND-TV.md #87: the disc was a plain `Box` with no tap at all.

  What a *tune* on a recommendation page can honestly do here is the question
  the page is already answering badly for you: `Kati.Media.Recommendations.seed/0`
  picks the newest title you touched, and *the last thing I opened* is not the
  same as *the thing I want more like*. So the disc opens the shelf and lets
  you say which — the reader's own titles, newest first, out of
  `Kati.Media.Recommendations.seedable/0`.

  Nothing else on this page is tunable, and the disc does not pretend
  otherwise: there is no recommender to weight, no genre model and no *more
  like this, less like that*. One question, the one the feed actually turns on.

  Over the board the disc is a picture, which is the rule this round keeps
  everywhere: a control that exists only over data is not drawn live over a
  drawing of it.
  """
  @spec header(map(), boolean(), map() | nil) :: map()
  def header(f, live? \\ false, choice \\ nil) do
    assigns = %{
      tap: if(live?, do: {self(), :open_tune}),
      filters: Kati.Screens.Discover.filter_disc(choice)
    }

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        <Column weight={1.0}>
          <Text
            text="Discover"
            text_size={28}
            max_font_scale={1.6}
            font_weight="bold"
            letter_spacing={-0.03}
            text_color={:on_surface}
          />
          {Kati.Screens.Discover.subtitle(f.subtitle)}
        </Column>
        <Spacer size={9} />
        {@filters}
        <Box
          width={44}
          height={44}
          corner_radius={22}
          background={Palette.card()}
          shadow={Kati.Theme.shadow_button()}
          align="center"
          on_tap={@tap}
        >
          {Kati.UI.symbol("tune", size: 21)}
        </Box>
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

  # Mishka's Scroll Area rather than a bare `<Scroll axis="horizontal">`: with
  # `orientation: :horizontal` and no bound asked for, `scroll_area/2` emits
  # that exact node — it only wraps the scroller in a Box when a height,
  # background, padding or radius is passed, and none is. Same node, same
  # pixels, and the chip rail now says what it is.
  @doc """
  The mono line under *Discover*, when there is one.

  The board's is `Tuned to 128 titles` — the size of the corpus a recommender
  was tuned to. Kati runs no recommender, and `Ash.count!` of the shelf is a
  different number wearing this one's caption. So a real feed has none and the
  5pt above it goes too, rather than leaving a gap where a claim used to be.
  """
  @spec subtitle(String.t() | nil) :: map()
  def subtitle(nil), do: ~MOB"<Spacer size={0} />"

  def subtitle(line) do
    assigns = %{line: line}

    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={5} />
      <Text
        text={@line}
        font_family="mono"
        text_size={11}
        text_color={Palette.muted()}
        max_lines={1}
      />
    </Column>
    """
  end

  @doc """
  The chip rail, when there is more than one section to choose between.

  A chip names a section, and a real feed has exactly one — the picks. A rail
  of one chip is a control with nothing to switch to, and *People*, *Leaving*
  and *Awards* over sections this device has none of are three more of the
  claims this screen is being cured of.
  """
  def chips(%{chips: chips}, _active) when length(chips) < 2,
    do: ~MOB"<Spacer size={0} />"

  def chips(f, active) do
    rail =
      ~MOB"""
      <Row align="center">
        {f.chips
         |> Enum.map(fn c -> Kati.Screens.Discover.chip(c, c.label == active) end)
         |> Enum.intersperse(Kati.Screens.Discover.chip_gap())}
      </Row>
      """

    scroller = MishkaScrollArea.scroll_area([orientation: :horizontal], [rail])

    ~MOB"""
    <Column fill_width={true}>
      {scroller}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def chip_gap, do: ~MOB"<Spacer size={7} />"

  @doc """
  One feed chip — Mishka's Chip.

  A chip is a label that carries a selected state and toggles it, which is this
  row exactly, so the only thing that ever kept it hand-rolled was that the
  component decided its own metrics and its own *unselected* colours. Both are
  props now, so the drawing's numbers — 32 tall, 16 of radius, 14 of side
  padding, a 12.5pt semibold label — are stated rather than approximated, and
  the unlit fill (`card`) and ink (`#5C574F`) are passed the same way the lit
  ones always were.

  Nothing moves. `padding_x: 14` with `padding_y: 0` reproduces the Row's
  14/0, and since the bridge pads before it sizes, `height: 32` is still 32 on
  screen. The chip is a hugging `Box` where this was a `Row` (K-17 makes
  `fill_width={false}` real), and a Box that hugs its content and centres it
  cannot move that content: the inner Row is exactly the width it is given.

  The count is still its own node rather than a string, so it keeps mono at
  10.5 in its own tone; `trailing_gap: 6` is the `Spacer` that used to sit
  inside it. A chip with **no** count now emits no trailing node at all,
  where it used to carry a `<Spacer size={0}>` — a zero-sized Spacer draws
  nothing, so the row is unchanged.
  """
  @spec chip(map(), boolean()) :: map()
  def chip(c, on?) do
    MishkaChip.chip(
      label: c.label,
      checked: on?,
      # The tag carries the label, so one handler serves every chip and a new
      # chip is a data change rather than a code change.
      on_toggle: String.to_atom("filter_" <> c.label),
      color: Palette.ink_fill(),
      text_color: Palette.on_ink(),
      unchecked_color: Palette.card(),
      unchecked_text_color: Palette.ink_soft(),
      height: 32,
      corner_radius: 16,
      padding_x: 14,
      padding_y: 0,
      text_size: 12.5,
      font_weight: :semibold,
      max_lines: 1,
      trailing_gap: 6,
      trailing: Kati.Screens.Discover.chip_count(c.count, on?)
    )
  end

  # The count rides at .6 of the label's own colour rather than a token of its
  # own, so it stays a shade of the chip it sits on in either state. `nil` is
  # no trailing slot rather than an empty one — the chip then builds the same
  # single-Text body it built before the slot existed.
  @doc false
  def chip_count(nil, _selected), do: nil

  def chip_count(count, selected) do
    fg = if selected, do: Palette.on_ink_count(), else: Palette.count_idle()

    ~MOB"""
    <Text text={count} font_family="mono" text_size={10.5} text_color={fg} max_lines={1} />
    """
  end

  # Each section is its eyebrow plus its body, kept together so that dropping
  # one drops its label with it — a heading over nothing is worse than no
  # heading. The wrapper Column stacks and fills like the frame it sits in, so
  # the visible section is drawn exactly where it was before.
  @doc false
  def because_section(f, chip) do
    if shows?(:because, chip) do
      ~MOB"""
      <Column fill_width={true}>
        {UI.eyebrow(f.because)}
        {Kati.Screens.Discover.picks_or_not(f)}
      </Column>
      """
    else
      ~MOB"<Spacer size={0} />"
    end
  end

  @doc """
  A refused add, said out loud.

  `Kati.Screens.AddTitle.add/2` sets `:save_error` and screen 06 draws it
  nowhere, which is the defect `D-60` is about in Persian and the same one in
  English. This screen writes through the same `track/2`, so it can fail the
  same ways — a TMDB detail call that 404s, a uniqueness constraint — and a
  poster that does not tick and says nothing is a tap the reader will make
  again.

  `Kati.UI.SettingsList.note/2` is the band screen 155 already uses for this.
  """
  @spec add_error(String.t() | nil) :: map()
  def add_error(nil), do: ~MOB"<Spacer size={0} />"

  def add_error(message) do
    assigns = %{message: message}

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.note("error", @message)}
      <Spacer size={14} />
    </Column>
    """
  end

  @doc """
  The rail, or what stands in its place.

  A real feed opens with `picks: []` and a request in flight, so there are two
  empty states rather than one and they mean opposite things: *asking* is a
  screen that will fill in, and *nothing* is an answer. Drawn apart, because a
  reader who is told there is nothing to suggest and then watches three posters
  appear has been told something false about their own library.

  `nothing` is the answer to every failure as well — no API key, no network, a
  provider that returned an empty list. On this screen they collapse honestly:
  there is nothing to show and the reader is not owed the reason a request
  failed on a page that is only ever a suggestion. `Kati.Screens.Settings` is
  where a missing key is a thing to act on.

  The card is board 87's, which board 19 already borrows for the same job — the
  44pt tinted tile, the bold line, the explanation under it. Only the glyph and
  the two sentences are this screen's.
  """
  @spec picks_or_not(map()) :: map()
  def picks_or_not(%{picks: [_ | _]} = f), do: rail(f)

  def picks_or_not(%{asked?: true}),
    do:
      nothing_card(
        "sync",
        "Looking for something",
        "Checking what goes with what you last watched."
      )

  # Three empty answers, three cards. A token nobody has entered is something
  # the reader can fix and is told where; a request that could not be made is
  # something to try again; and a provider that knows of nothing like this show
  # is neither, and is not dressed up as either.
  #
  # `explore` twice would have been the section's own glyph in every state, and
  # `explore_off` and `vpn_key_off` — the obvious pairs for it and for the
  # token card — are not in Kati's Material subset (`mix kati.gen.icons`), so
  # the three take glyphs that are.
  def picks_or_not(%{picks_error: :no_api_key}),
    do: nothing_card("lock", "No TMDB token yet", Kati.Media.Tmdb.message(:no_api_key))

  # Every other reason takes the client's own sentence — the wording of a
  # provider failure belongs with the provider, and `Kati.Media.Tmdb.message/1`
  # already words all seven for screen 06. A card here that said *could not be
  # reached* over a rate limit would be a second, worse copy of it.
  def picks_or_not(%{picks_error: reason}) when not is_nil(reason),
    do: nothing_card("cloud_off", "Could not look just now", Kati.Media.Tmdb.message(reason))

  def picks_or_not(_feed),
    do:
      nothing_card(
        "explore",
        "Nothing to suggest yet",
        "TMDB knows of nothing like it. Watch something else and this fills in."
      )

  @doc """
  The feed, with the answer folded in.

  `picks_error` is set on failure and cleared on success, so reopening the
  screen after a flight-mode spell does not leave the last failure's card
  under three fresh posters.
  """
  @spec answered(map(), {:ok, [map()]} | {:error, term()}) :: map()
  def answered(feed, {:ok, picks}),
    do: %{feed | picks: picks, asked?: false, picks_error: nil}

  def answered(feed, {:error, reason}),
    do: %{feed | picks: [], asked?: false, picks_error: reason}

  @doc """
  The same, for a browse — which answers a map rather than a list.

      iex> feed = Kati.Screens.Discover.browse_feed(%{kind: nil, sort: :newest, rating: nil})
      iex> browsed = Kati.Screens.Discover.browsed(feed, {:ok, %{picks: [%{title: "Vellum"}], total: 4213}})
      iex> {browsed.asked?, length(browsed.picks)}
      {false, 1}
  """
  @spec browsed(map(), {:ok, map()} | {:error, term()}) :: map()
  def browsed(feed, {:ok, %{picks: picks}}), do: answered(feed, {:ok, picks})
  def browsed(feed, {:error, reason}), do: answered(feed, {:error, reason})

  @doc """
  TMDB's own `total_results` for a browse, or nothing.

      iex> Kati.Screens.Discover.total_of({:ok, %{picks: [], total: 4213}})
      4213

      iex> Kati.Screens.Discover.total_of({:error, :rate_limited})
      nil

  Board 169's footer takes this and nothing else. A count of `picks` would be
  the page size — twenty — wearing the corpus's name.
  """
  @spec total_of({:ok, map()} | {:error, term()}) :: non_neg_integer() | nil
  def total_of({:ok, %{total: total}}) when is_integer(total) and total > 0, do: total
  def total_of(_other), do: nil

  @doc """
  A chip that names a section this feed does not carry, saying so.

  MOVIES-AND-TV.md #24. `shows?/2` answers `false` for every section under
  *Awards*, so all three vanished together and left the chip rail floating over
  a blank page — and the rail is drawn whenever the feed has more than one
  section, which the board's own fixture does. Screen 03's `nothing_here/1` is
  the same answer to the same question one screen over: a filter that matches
  nothing has to say so, or the reader is looking at a bug.

  Only when EVERY section is hidden. A chip that narrows to one real section is
  the control working, and this must not appear under it.
  """
  @spec no_section(map(), String.t()) :: map()
  def no_section(f, chip) do
    if Enum.any?([:because, :people, :leaving], &Kati.Screens.Discover.shows?(&1, chip)) do
      ~MOB"<Spacer size={0} />"
    else
      Kati.Screens.Discover.nothing_card(
        "auto_awesome",
        "Nothing under " <> chip,
        "Kati has no " <>
          String.downcase(chip) <>
          " to show from what you keep. " <>
          Kati.Screens.Discover.other_chips(f, chip)
      )
    end
  end

  @doc """
  The other chips, named, so the card points somewhere.

      iex> Kati.Screens.Discover.other_chips(%{chips: [%{label: "For you"}, %{label: "Awards"}]}, "Awards")
      "For you has picks."

      iex> Kati.Screens.Discover.other_chips(%{chips: [%{label: "Awards"}]}, "Awards")
      "Nothing else is offered either."
  """
  @spec other_chips(map(), String.t()) :: String.t()
  def other_chips(f, chip) do
    case f |> Map.get(:chips, []) |> Enum.map(& &1.label) |> Enum.reject(&(&1 == chip)) do
      [] -> "Nothing else is offered either."
      [one] -> one <> " has picks."
      many -> Enum.join(many, ", ") <> " have picks."
    end
  end

  @doc false
  def nothing_card(icon, title, body) do
    assigns = %{icon: icon, title: title, body: body}

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={20}
        padding={15}
        shadow={Kati.Theme.shadow_card_soft()}
      >
        <Spacer size={4} />
        <Row fill_width={true} align="center">
          <Spacer weight={1.0} />
          <Box width={44} height={44} corner_radius={14} background={Palette.paper()} align="center">
            {UI.symbol(@icon, size: 21, color: Palette.rail_idle())}
          </Box>
          <Spacer weight={1.0} />
        </Row>
        <Spacer size={12} />
        <Text
          text={@title}
          text_size={13.5}
          font_weight="bold"
          text_color={:on_surface}
          text_align="center"
        />
        <Spacer size={6} />
        <Text
          text={@body}
          text_size={12}
          line_height={1.55}
          text_color={Palette.sub()}
          text_align="center"
        />
        <Spacer size={4} />
      </Column>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def people_section(%{people: []}, _chip), do: ~MOB"<Spacer size={0} />"

  def people_section(f, chip) do
    if shows?(:people, chip) do
      ~MOB"""
      <Column fill_width={true}>
        {UI.eyebrow("People you follow")}
        {Kati.Screens.Discover.people(f)}
      </Column>
      """
    else
      ~MOB"<Spacer size={0} />"
    end
  end

  @doc false
  # MOVIES-AND-TV.md #120, band 11. Board 96's second band — *Nothing to leave
  # yet* — is a section screen 11 replaces, and 11 drew nothing at all instead.
  # The two absences are different and only one of them is the reader's to fix:
  # *nothing you pay for is dropping a title this month* is a fact about the
  # catalogue, and *you have not told Kati what you pay for* is a fact about the
  # account, with a button on it.
  #
  # `set_up?/0` could not answer `false` until #75 took the fixture fallback off
  # `Kati.Screens.MyServices.listed/0`; screen 96's own moduledoc named that as
  # the change these four bands were waiting on.
  #
  # Behind the chip, like the section it replaces: a reader who has narrowed to
  # *Because you watched* is not asking about leaving-soon at all.
  def leaving_section(%{leaving: []}, chip, _scheduled) do
    if shows?(:leaving, chip) and not Kati.Screens.NothingSetUpKnockOn.set_up?() do
      assigns = %{
        band:
          Kati.Screens.NothingSetUpKnockOn.prompt(
            "Nothing to leave yet",
            "Leaving-soon warnings need at least one subscribed service — there is " <>
              "nothing to count down from.",
            :my_services_leaving_soon
          )
      }

      ~MOB"""
      <Column fill_width={true}>
        {Kati.UI.Eyebrow.quiet("Leaving soon")}
        {@band}
      </Column>
      """
    else
      ~MOB"<Spacer size={0} />"
    end
  end

  def leaving_section(f, chip, scheduled) do
    if shows?(:leaving, chip) do
      ~MOB"""
      <Column fill_width={true}>
        {Kati.UI.Eyebrow.quiet(f.leaving_label)}
        {Kati.Screens.Discover.leaving(f, scheduled)}
      </Column>
      """
    else
      ~MOB"<Spacer size={0} />"
    end
  end

  @doc false
  def rail(f) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        {f.picks |> Enum.map(&Kati.Screens.Discover.pick/1) |> Enum.intersperse(Kati.Screens.Discover.rail_gap())}
      </Row>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def rail_gap, do: ~MOB"<Spacer size={12} />"

  # Weighted rather than 112 wide: three equal shares of the real content width
  # fill the row on any device, where a fixed 112 only fills the drawing's frame.
  @doc """
  One pick, which you can now add.

  Screen 11 was *the only page in the app that shows films you cannot open*:
  `pick/1` was pure layout, so three posters sat there and nothing happened.
  A recommendation you cannot act on is half a feature, and the act a
  recommendation asks for is **add it** — the same
  `Kati.Screens.AddTitle.track/2` a search hit goes through.

  The tap exists only on a pick that names a title: a real one carries the
  provider id the write needs, and the board's three carry nothing but a design
  seed. So `Kati.Library.Sample`'s picks stay untappable, board 11 renders the
  node it always rendered, and `Kati.ScreenTapSweepTest` — which runs against
  an EMPTY store, and therefore sees the board — is unchanged.

  That is also why the sweep cannot cover this tap. `Kati.DiscoverFeedTest`
  does, over a pick with an id on it.
  """
  def pick(p) do
    tap = Kati.Screens.Discover.pick_tap(p)

    ~MOB"""
    <Column weight={1.0}>
      <Box
        fill_width={true}
        height={158}
        corner_radius={13}
        background={Palette.placeholder()}
        shadow={Kati.Theme.shadow_card_soft()}
        on_tap={tap}
      >
        {Kati.Screens.Discover.poster(p.seed)}
        {Kati.Screens.Discover.added_mark(Map.get(p, :added, false))}
      </Box>
      <Spacer size={9} />
      <Text
        text={p.title}
        text_size={12.5}
        font_weight="bold"
        text_color={:on_surface}
        max_lines={1}
      />
      {Kati.Screens.Discover.match(p.match)}
    </Column>
    """
  end

  @doc """
  `94% match`, when something scored it.

  Nothing does. TMDB's `/recommendations` is a ranking and not a percentage,
  and a match is a statement about a title AGAINST one person's history —
  Kati runs no recommender and has no column to keep such a number in. So a
  real pick carries `nil` and the line is absent rather than rounded up from
  the position in the list. `Kati.Media.Recommendations` argues it at length.
  """
  @spec match(String.t() | nil) :: map()
  def match(nil), do: ~MOB"<Spacer size={0} />"

  def match(line) do
    assigns = %{line: line}

    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={3} />
      <Text
        text={@line}
        font_family="mono"
        text_size={10.5}
        text_color={Palette.accent()}
        max_lines={1}
      />
    </Column>
    """
  end

  @doc """
  The tag a pick answers to, or `nil` for one nothing can add.

  `nil` is the value `Kati.ScreenTapSweepTest` documents as *not tappable
  rather than broken*, and it is the honest answer for a fixture: the board's
  picks are three seeds and three captions, and there is no title behind them
  to put on a shelf.

      iex> Kati.Screens.Discover.pick_tag(%{title: "Emergence", source_id: "82708"})
      :add_82708

      iex> Kati.Screens.Discover.pick_tag(%{title: "Vellum", seed: "vellum97"})
      nil
  """
  @spec pick_tag(map()) :: atom() | nil
  def pick_tag(%{source_id: id}) when is_binary(id) and id != "",
    do: String.to_atom("add_" <> id)

  def pick_tag(_pick), do: nil

  @doc false
  def pick_tap(pick) do
    case pick_tag(pick) do
      nil -> nil
      tag -> {self(), tag}
    end
  end

  @doc """
  The tick over a poster that has just been added.

  Screen 06's answer at rail scale: the tap's only visible result is that the
  title is now on the shelf, which is a different screen, so the control has to
  say so where it was pressed. `Kati.Screens.Library` is where it turns up.
  """
  @spec added_mark(boolean()) :: map()
  def added_mark(false), do: ~MOB"<Spacer size={0} />"

  def added_mark(true) do
    ~MOB"""
    <Box fill_width={true} fill_height={true} align="top">
      <Row fill_width={true} padding={7} align="top">
        <Spacer weight={1.0} />
        <Box width={26} height={26} corner_radius={13} background={Palette.ink_fill()} align="center">
          {UI.symbol("check", size: 15, color: Palette.on_ink())}
        </Box>
      </Row>
    </Box>
    """
  end

  @doc false
  def poster(seed) do
    case Sample.image(seed) do
      nil ->
        ~MOB"<Spacer size={0} />"

      src ->
        ~MOB"""
        <Image src={src} fill_width={true} height={158} corner_radius={13} content_mode="fill" />
        """
    end
  end

  @doc false
  def people(f) do
    last = length(f.people) - 1

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={20}
        shadow={Kati.Theme.shadow_card_soft()}
        padding_left={15}
        padding_right={15}
        padding_top={4}
        padding_bottom={4}
      >
        {f.people
         |> Enum.with_index()
         |> Enum.map(fn {row, i} -> Kati.Screens.Discover.person_row(row, i < last) end)}
      </Column>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def person_row(p, rule?) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_top={13} padding_bottom={13}>
        {Kati.Screens.Discover.face(p.seed)}
        <Spacer size={13} />
        <Column weight={1.0}>
          <Text
            text={p.name}
            text_size={13.5}
            font_weight="semibold"
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={3} />
          <Text text={p.line} text_size={11.5} text_color={Palette.sub()} max_lines={1} />
        </Column>
        <Spacer size={13} />
        {Kati.Screens.Discover.person_mark(p.new?)}
      </Row>
      {Kati.Screens.Discover.hairline(rule?)}
    </Column>
    """
  end

  # Mishka's Avatar. A circular face with a fallback under it is exactly what
  # the component is, and it carries the seed-missing branch that used to be
  # written out here: `:circle` resolves to an exact `size / 2` radius, so 38pt
  # still rounds at 19.
  #
  # The pixels do not move in either state. With no image it draws the same
  # 38x38 disc in the same `#E4E0D9`, plus an empty initials Text that renders
  # nothing inside a box already sized to 38. With an image, the avatar stacks
  # `[fallback, image]` — and the design's photographs are opaque JPEGs at the
  # same 38x38 with the same radius, so the image covers the fallback exactly
  # rather than tinting it.
  @doc false
  def face(seed) do
    MishkaAvatar.avatar(src: Sample.image(seed), size: 38, background: Palette.placeholder())
  end

  @doc false
  def person_mark(true),
    do: ~MOB"<Box width={8} height={8} corner_radius={4} background={Palette.accent()} />"

  def person_mark(false), do: Kati.UI.symbol("check", size: 18, color: Palette.rail_idle())

  @doc false
  def leaving(f, scheduled) do
    ~MOB"""
    <Column fill_width={true}>
      {f.leaving |> Enum.map(fn row -> Kati.Screens.Discover.leaving_row(row, row.title in scheduled) end) |> Enum.intersperse(Kati.Screens.Discover.leaving_gap())}
    </Column>
    """
  end

  @doc false
  def leaving_gap, do: ~MOB"<Box fill_width={true} height={9} />"

  @doc false
  def leaving_row(row, done?) do
    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Palette.card()}
        corner_radius={18}
        shadow={Kati.Theme.shadow_card_soft()}
        padding_left={13}
        padding_right={13}
        padding_top={10}
        padding_bottom={10}
        align="center"
      >
        {Kati.Screens.Discover.thumb(row.seed)}
        <Spacer size={12} />
        <Column weight={1.0}>
          <Text
            text={row.title}
            text_size={13.5}
            font_weight="bold"
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={4} />
          <Text text={row.line} text_size={11.5} text_color={Palette.sub()} max_lines={1} />
        </Column>
        <Spacer size={12} />
        {Kati.Screens.Discover.leaving_action(row, done?)}
      </Row>
    </Column>
    """
  end

  @doc """
  *Schedule*, and *Scheduled* — both of them the board's, and neither tappable.

  MOVIES-AND-TV.md #87's second half: this was *the one working control on the
  page*, and what it did was toggle a socket assign that the next pop threw
  away. A button that changes and forgets is not a smaller version of one that
  works; it is the screen claiming a thing was scheduled.

  It cannot be more than that here. `leaving` is `[]` on every real feed —
  there is no offers resource and no window in which a title leaves a service,
  which the moduledoc lists among what this page would need — so this section
  exists only on board 11, over rows that name nothing. Nothing to schedule
  against, so nothing to press.

  Both states stay drawn, because the board draws both.
  """
  @spec leaving_action(map(), boolean()) :: map()
  def leaving_action(row, false) do
    tap = Kati.Screens.Discover.schedule_tap(row)

    ~MOB"""
    <Row
      height={30}
      corner_radius={15}
      background={Palette.ink_fill()}
      padding_left={13}
      padding_right={13}
      align="center"
      on_tap={tap}
    >
      <Text
        text={row.action}
        text_size={11.5}
        font_weight="semibold"
        text_color={Palette.on_ink()}
        max_lines={1}
      />
    </Row>
    """
  end

  def leaving_action(row, true) do
    tap = Kati.Screens.Discover.schedule_tap(row)

    ~MOB"""
    <Row
      height={30}
      corner_radius={15}
      background={Palette.placeholder()}
      padding_left={13}
      padding_right={13}
      align="center"
      on_tap={tap}
    >
      <Text
        text="Scheduled"
        text_size={11.5}
        font_weight="semibold"
        text_color={Palette.ink_soft()}
        max_lines={1}
      />
    </Row>
    """
  end

  @doc false
  def thumb(seed) do
    case Sample.image(seed) do
      nil ->
        ~MOB"<Box width={40} height={56} corner_radius={8} background={Palette.placeholder()} />"

      src ->
        ~MOB"""
        <Image src={src} width={40} height={56} corner_radius={8} content_mode="fill" />
        """
    end
  end

  # Mishka's Separator, at the design's own colour and thickness. `render:
  # :box` is not optional — the default `:divider` is Material 3's antialiased
  # drawLine and softens the bottom pixel row of every rule on this screen. See
  # `Kati.Screens.Film.hairline/1` for the measurement.
  @doc false
  def hairline(false), do: ~MOB"<Spacer size={0} />"

  def hairline(true),
    do: MishkaSeparator.separator(color: Palette.hairline(), thickness: 1, render: :box)

  @impl true
  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "filter_" <> label ->
        {:noreply, Mob.Socket.assign(socket, :chip, label)}

      "add_" <> source_id ->
        {:noreply, Kati.Screens.Discover.add(socket, source_id)}

      "open_tune" ->
        {:noreply, Mob.Socket.assign(socket, :tune?, not socket.assigns.tune?)}

      # The total travels WITH the push. Board 169's footer describes the
      # current selection, and the only place that number exists is the answer
      # this screen already holds — `Kati.Screens.DiscoverFilters.count_line/2`
      # drops it the moment a chip moves, so it can never go stale on the sheet.
      "open_filters" ->
        {:noreply,
         Mob.Socket.push_screen(socket, Kati.Screens.DiscoverFilters, %{
           total: Map.get(socket.assigns, :total)
         })}

      "seed_on_" <> source_id ->
        {:noreply, Kati.Screens.Discover.reseed(socket, source_id)}

      # Board 96's button, on the band this screen draws when nothing is set up
      # (#120). All four of the sheet's routes lead to one place.
      "my_services_" <> _band ->
        {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.MyServices)}

      _ ->
        {:noreply, socket}
    end
  end

  @doc """
  Add the pick that was tapped.

  Synchronous, which is `Kati.Screens.AddTitle.add/2`'s own choice and made for
  its reason: `track/2` fetches the seasons and the episodes as well as the row
  — nothing can be ticked before the episodes exist — and this is the moment
  the app knows a title is wanted and is allowed to be slow.

  A pick already on the shelf cannot be tapped twice into two rows: `added` is
  set on the pick, and a second tap finds it already true and does nothing.
  Untracking is deliberately NOT offered here the way screen 06 offers it — a
  discover rail is a list of things you do not have, and a title you just added
  leaves the rail on the next visit rather than becoming a toggle.
  """
  @spec add(Mob.Socket.t(), String.t()) :: Mob.Socket.t()
  def add(socket, source_id) do
    feed = socket.assigns.feed

    case Enum.find(feed.picks, &(Map.get(&1, :source_id) == source_id)) do
      nil -> socket
      %{added: true} -> socket
      pick -> written(socket, feed, pick)
    end
  end

  defp written(socket, feed, pick) do
    row = %{source: :tmdb, source_id: pick.source_id, kind: pick.kind}

    case Kati.Screens.AddTitle.track(pick.title, row) do
      {:ok, _tracked} ->
        Mob.Socket.assign(socket, :feed, %{feed | picks: mark(feed.picks, pick.source_id)})

      {:error, _reason} = error ->
        Mob.Socket.assign(socket, :add_error, Kati.Write.message(error))
    end
  end

  @doc """
  The picks with one of them ticked.

      iex> Kati.Screens.Discover.mark([%{source_id: "1", added: false}], "1")
      [%{source_id: "1", added: true}]

      iex> Kati.Screens.Discover.mark([%{source_id: "1", added: false}], "2")
      [%{source_id: "1", added: false}]
  """
  @spec mark([map()], String.t()) :: [map()]
  def mark(picks, source_id) do
    Enum.map(picks, fn p ->
      if Map.get(p, :source_id) == source_id, do: Map.put(p, :added, true), else: p
    end)
  end
end
