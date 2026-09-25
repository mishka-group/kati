defmodule Kati.Screens.Discover do
  @moduledoc """
  Screen 11 — Discover, pushed under Library.

  Built to `test/design/screens/11.html`, which draws four things: a rail of
  picks under *Because you watched …*, each with a match percentage; a card of
  people you follow; the titles about to leave a service; and a chip row to
  choose between them. This screen draws the one of those with a store behind
  it — the picks — and nothing else.

  ## What is real

    * **The picks** — `Kati.Media.Recommendations`: TMDB's recommendations for
      one title on the reader's own shelf, three of them, each with its own
      poster (`Kati.Design.Images.poster/1` over the provider's poster path,
      which answers the downloaded artwork or nothing). Tapping one adds it to
      the shelf through `Kati.Screens.AddTitle.track/2`.
    * **The heading** — `Kati.Media.Recommendations.because/1` over the title
      the picks came from.
    * **`tune`** — which of the reader's titles the picks are seeded on
      (`Kati.Media.Recommendations.seedable/0`).
    * **`sort`** — board 169's sheet, a browse of TMDB by kind, sort and
      rating (`Kati.Discover.Filters`), which needs nothing on the shelf. The
      push carries TMDB's `total_results` for the last browse, because this
      socket holds the only copy of it.

  ## What board 11 draws and this screen does not

    * **`94% match`** — a match is a statement about a title against one
      person's history. TMDB's recommendations are a ranking, not a score, and
      Kati runs no recommender and has no column for one.
    * **People you follow** — Kati has no person anywhere; `Kati.Media.Watch`'s
      `companions` records who you watched with, which is a different fact.
    * **Leaving soon** — an availability window on a service. Nothing stores
      what a service offers or when a title leaves it.
    * **`Tuned to 128 titles`** — the size of a recommender's corpus.
    * **The chip row** — with one section there is nothing to choose between.

  ## Empty

  A shelf with nothing to seed from — a fresh install, or one whose titles have
  no cached row — gets `empty_feed/0`: one card that says picks come from the
  shelf and how to get some. A seeded feed that is still waiting, that TMDB
  answered with nothing, or that could not be fetched each has its own card
  (`picks_or_not/1`).

  The rail's three posters take an equal weight each, so the row is exactly
  full at any device width rather than at the drawing's 402pt frame only.
  """
  use Kati.Screens.Pushed, back: "Library"
  use Gettext, backend: Kati.Gettext

  alias Kati.Media.Recommendations
  alias Kati.Theme.Palette
  alias Kati.UI

  @impl true
  def load(socket) do
    choice = Kati.Discover.Filters.current()
    feed = feed(choice)

    socket
    |> Mob.Socket.assign(
      filters: choice,
      total: nil,
      feed: feed,
      tune?: false,
      seed_id: Map.get(feed, :seed_id),
      add_error: nil
    )
    |> ask()
  end

  @doc """
  The feed under the reader's current filter choice.
  """
  @spec feed() :: map()
  def feed, do: feed(Kati.Discover.Filters.current())

  @doc """
  The feed under a filter choice.

  A narrowed sheet browses TMDB and needs nothing on the shelf, so it wins.
  Otherwise the picks are seeded on `Kati.Media.Recommendations.seed/0`, and a
  shelf with nothing to seed from answers `empty_feed/0`.

  `picks` starts empty: `ask/1` makes the request and `handle_info/2` fills it
  in. `total` — TMDB's `total_results` for a browse, which board 169's footer
  draws — is kept on the socket, not in the feed.
  """
  @spec feed(map()) :: map()
  def feed(choice) do
    if Kati.Discover.Filters.narrowed?(choice) do
      browse_feed(choice)
    else
      case Recommendations.seed() do
        nil -> empty_feed()
        {_tracked, cached} -> real_feed(cached)
      end
    end
  end

  @doc """
  The feed with nothing to recommend from.
  """
  @spec empty_feed() :: map()
  def empty_feed do
    %{
      because: nil,
      seed_id: nil,
      picks: [],
      asked?: false,
      picks_error: nil,
      empty_shelf?: true
    }
  end

  @doc """
  A feed that came from board 169's sheet rather than from a title. Its heading
  says what was asked — `asked_line/1` — because nothing was watched to
  produce it.
  """
  @spec browse_feed(map()) :: map()
  def browse_feed(choice) do
    %{
      because: Kati.Screens.Discover.asked_line(choice),
      seed_id: nil,
      picks: [],
      asked?: true,
      picks_error: nil,
      empty_shelf?: false
    }
  end

  @doc """
  A feed seeded on one title from the shelf.
  """
  @spec real_feed(Kati.Media.CachedTitle.t()) :: map()
  def real_feed(cached) do
    %{
      because: Recommendations.because(cached.title),
      seed_id: cached.source_id,
      picks: [],
      asked?: true,
      picks_error: nil,
      empty_shelf?: false
    }
  end

  @doc """
  What the rail's heading says under a filter — the question, not a premise.

      iex> Kati.Screens.Discover.asked_line(%{kind: :tv, sort: :popular, rating: nil})
      "Most popular series"

      iex> Kati.Screens.Discover.asked_line(%{kind: nil, sort: :newest, rating: :r8})
      "Newest films, 8.0 and up"

  Film when no kind is chosen, because `/discover` is one kind per request and
  `Kati.Discover.Filters.endpoint/1` resolves it to film. The nouns take a
  context because single words fuzzy-match in `mix gettext.merge`, and the
  whole line is a template so the word order and the list comma (U+060C in
  Persian) belong to the translator.
  """
  @spec asked_line(map()) :: String.t()
  def asked_line(choice) do
    noun =
      if Kati.Discover.Filters.endpoint(choice) == :tv,
        do: pgettext("discover heading", "series"),
        else: pgettext("discover heading", "films")

    {sort, _sub} = Kati.Discover.Filters.sort_label(Map.get(choice, :sort))

    case Map.get(choice, :rating) do
      nil ->
        pgettext("discover heading", "%{sort} %{noun}", sort: sort, noun: noun)

      rating ->
        pgettext("discover heading", "%{sort} %{noun}, %{rating}",
          sort: sort,
          noun: noun,
          rating: Kati.Discover.Filters.rating_label(rating)
        )
    end
  end

  @doc """
  Whether this page has a shelf to be tuned against: a seeded feed and more
  than one title to choose between.

      iex> Kati.Screens.Discover.tunable?(Kati.Screens.Discover.empty_feed())
      false
  """
  @spec tunable?(map()) :: boolean()
  def tunable?(feed) do
    is_binary(Map.get(feed, :seed_id)) and length(Recommendations.seedable()) > 1
  end

  @doc """
  The *Picks from* panel the `tune` disc opens: the reader's own titles, newest
  first, the one the feed is seeded on lit.

  The label is hand-rolled rather than `Kati.UI.eyebrow/2` because it carries
  no dash; it asks the same questions of the reader's script that function
  does — face, case, tracking and size.
  """
  @spec tune_panel(map(), boolean()) :: map()
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
        text={Kati.UI.eyebrow_label(gettext("Picks from"))}
        font_family={Kati.Locale.mono_face()}
        text_size={Kati.Locale.pick(10.5, 11)}
        font_weight={Kati.Locale.pick("normal", "semibold")}
        letter_spacing={Kati.Locale.tracking(0.16)}
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

  @doc """
  One title in the *Picks from* panel. `MishkaPill`, because `MishkaChip`
  takes no `on_tap`.
  """
  @spec seed_chip(Kati.Media.CachedTitle.t(), boolean()) :: map()
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

  The whole feed is rebuilt rather than the heading swapped, because the
  heading and the posters under it are one answer.
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
  Picks, when they arrive — or a browse, when it arrives.

  The seed and the filter choice are compared rather than trusted: the reader
  can have moved either while a request was in flight, and a rail drawn under
  the wrong premise is the defect this page exists to avoid. Every other
  message goes to `Kati.Screens.Pushed`'s own clauses through `super/2`.
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

  def handle_info(message, socket), do: super(message, socket)

  @doc """
  Coming back from the sheet: re-read the choice, redraw, re-ask. The sheet
  writes every tap straight through to `Kati.Discover.Filters`, so this is a
  read rather than a message with a payload.
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
         seed_id: Map.get(feed, :seed_id),
         total: nil
       )
       |> ask()}
    end
  end

  def handle_kati(_topic, _payload, socket), do: {:noreply, socket}

  @doc false
  def content(assigns) do
    f = assigns.feed

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
        {Kati.Screens.Discover.add_error(Map.get(assigns, :add_error))}
        {Kati.Screens.Discover.because_section(f)}
      </Column>
    </Scroll>
    """
  end

  @doc """
  The space the floating back pill occupies: 42pt with 16 under it.
  """
  @spec pill_row() :: map()
  def pill_row, do: ~MOB"<Spacer size={58} />"

  @doc """
  The `sort` disc that opens board 169's sheet, lit while a filter narrows the
  feed.

  A second disc beside `tune` because they open different rooms: `tune` says
  what the picks come from, `sort` is a browse of TMDB that does not involve
  the shelf at all. `nil` draws nothing.
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
  The title, the `sort` disc and the `tune` disc.

  `tune` is tappable only when there is more than one title to seed from
  (`tunable?/1`); with one, the feed is already seeded on it.
  """
  @spec header(map(), boolean(), map() | nil) :: map()
  def header(_f, live? \\ false, choice \\ nil) do
    assigns = %{
      tap: if(live?, do: {self(), :open_tune}),
      filters: Kati.Screens.Discover.filter_disc(choice)
    }

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        <Column weight={1.0}>
          <Text
            text={gettext("Discover")}
            text_size={28}
            max_font_scale={1.6}
            font_weight="bold"
            letter_spacing={Kati.Locale.tracking(-0.03)}
            text_color={:on_surface}
            max_lines={1}
          />
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

  @doc """
  The picks under their heading, or the card that stands in for both.

  An empty shelf has no heading to give — there is no title to say *because*
  of — so it draws its card alone.
  """
  @spec because_section(map()) :: map()
  def because_section(%{empty_shelf?: true}), do: Kati.Screens.Discover.empty_shelf()

  def because_section(f) do
    ~MOB"""
    <Column fill_width={true}>
      {UI.eyebrow(f.because)}
      {Kati.Screens.Discover.picks_or_not(f)}
    </Column>
    """
  end

  @doc """
  The page with nothing on the shelf to recommend from: what the picks are
  built from, and the two ways in — a title on the shelf, or a browse under
  the `sort` disc, which needs none.
  """
  @spec empty_shelf() :: map()
  def empty_shelf do
    nothing_card(
      "explore",
      gettext("Nothing to recommend from yet"),
      gettext(
        "Picks here are built from the films and series on your shelf. Add one, " <>
          "or browse TMDB with the sort button above."
      )
    )
  end

  @doc """
  A refused add, said out loud, in the band screen 155 uses for it.
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

  *Asking* is a screen that will fill in; the other three are answers. A token
  nobody has entered is something the reader can fix and is told where; a
  request that could not be made takes the provider's own sentence
  (`Kati.Media.Tmdb.message/1`); and a provider that knows of nothing like the
  title is neither.
  """
  @spec picks_or_not(map()) :: map()
  def picks_or_not(%{picks: [_ | _]} = f), do: rail(f)

  def picks_or_not(%{asked?: true}),
    do:
      nothing_card(
        "sync",
        gettext("Looking for something"),
        gettext("Checking what goes with what you last watched.")
      )

  def picks_or_not(%{picks_error: :no_api_key}),
    do: nothing_card("lock", gettext("No TMDB token yet"), Kati.Media.Tmdb.message(:no_api_key))

  def picks_or_not(%{picks_error: reason}) when not is_nil(reason),
    do:
      nothing_card(
        "cloud_off",
        gettext("Could not look just now"),
        Kati.Media.Tmdb.message(reason)
      )

  def picks_or_not(_feed),
    do:
      nothing_card(
        "explore",
        gettext("Nothing to suggest yet"),
        gettext("TMDB knows of nothing like it. Watch something else and this fills in.")
      )

  @doc """
  The feed, with the answer folded in. `picks_error` is set on failure and
  cleared on success.
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
  the page size wearing the corpus's name.
  """
  @spec total_of({:ok, map()} | {:error, term()}) :: non_neg_integer() | nil
  def total_of({:ok, %{total: total}}) when is_integer(total) and total > 0, do: total
  def total_of(_other), do: nil

  @doc """
  Board 87's empty card: a tinted tile, a bold line and the explanation under
  it. The body takes `Kati.Locale.leading/1` because it is a paragraph and
  Vazirmatn's metrics are not Plus Jakarta's.
  """
  @spec nothing_card(String.t(), String.t(), String.t()) :: map()
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
          line_height={Kati.Locale.leading(1.55)}
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

  @doc """
  One pick: its own poster, its title, and a tap that adds it to the shelf.

  The tap exists only on a pick that names a title — a real one carries the
  provider id the write needs (`pick_tag/1`).
  """
  @spec pick(map()) :: map()
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
    </Column>
    """
  end

  @doc """
  The tag a pick answers to, or `nil` for one nothing can add.

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
  The tick over a poster that has just been added — the tap's only visible
  result is on another screen, so the control says so where it was pressed.
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

  @doc """
  A pick's poster: the title's own artwork, or nothing over the placeholder.
  `Kati.Design.Images.poster/1` resolves a provider path through
  `Kati.Media.Artwork` and answers `nil` for one this device has not fetched.
  """
  @spec poster(String.t() | nil) :: map()
  def poster(seed) do
    case Kati.Design.Images.poster(seed) do
      nil ->
        ~MOB"<Spacer size={0} />"

      src ->
        ~MOB"""
        <Image src={src} fill_width={true} height={158} corner_radius={13} content_mode="fill" />
        """
    end
  end

  @impl true
  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "add_" <> source_id ->
        {:noreply, Kati.Screens.Discover.add(socket, source_id)}

      "open_tune" ->
        {:noreply, Mob.Socket.assign(socket, :tune?, not socket.assigns.tune?)}

      "open_filters" ->
        {:noreply,
         Mob.Socket.push_screen(socket, Kati.Screens.DiscoverFilters, %{
           total: Map.get(socket.assigns, :total)
         })}

      "seed_on_" <> source_id ->
        {:noreply, Kati.Screens.Discover.reseed(socket, source_id)}

      _ ->
        {:noreply, socket}
    end
  end

  @doc """
  Add the pick that was tapped, through `Kati.Screens.AddTitle.track/2` — the
  write a search hit goes through.

  Synchronous, for `Kati.Screens.AddTitle.add/2`'s reason: `track/2` fetches
  the seasons and the episodes as well as the row. A pick already added is not
  added twice, and a refusal is assigned to `:add_error` and drawn.
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
