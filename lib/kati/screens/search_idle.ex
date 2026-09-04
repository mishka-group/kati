defmodule Kati.Screens.SearchIdle do
  @moduledoc """
  Screen 86 — Search, idle. The tap-through from Home's search field.

  ## Four things the ticket left open, decided here

    * **The placeholder generalises.** `Search anything you keep`, because
      scope now spans seven domains and `Search films, shows, events…` names
      three of them.
    * **Counts are withheld while the query is empty.** The chips carry no
      numbers on open, and the page says why: *eight zeroes on open would read
      as an empty app.* A count of nothing is a true statement that looks like
      a failure.
    * **The minimum is two Latin characters and one for non-Latin scripts.**
      `Kati.Search.minimum/1` measures the *query* rather than the app's
      locale, because somebody reading Kati in English can still type a
      Persian title into it.
    * **Try suggestions ship, but only two**, and drawn from what you actually
      have. Two, because a suggestion list long enough to browse is a second
      search; from your own library, because a suggestion for something you do
      not keep is an advert.

  ## The keyboard on the artboard is the platform's

  The drawing shows it up, because that is the state this screen is documenting
  — you got here by tapping a field. Kati does not draw it: Mob has no text
  input at all (#45), and even when it does the keyboard will be the OS's. An
  app that drew its own would be drawing a control nobody can type on.

  `Kati.DesignLiterals` cuts the keyboard block before taking literals, the same
  way it cuts the caption, and says why where the rule lives.

  ## Why this is a different screen from 19

  Screen 19 is *Search everything* reached from the Library with results
  showing. This is the empty field the moment it opens. They are drawn as two
  boards and they are two states worth being able to look at separately —
  which is exactly what the second wave of drawings is for.
  """

  use Kati.Screens.Pushed, back: "Home"

  alias Kati.Search
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  def load(socket) do
    socket
    |> Mob.Socket.assign(:scope, "All")
    |> Mob.Socket.assign(:query, "")
    |> Mob.Socket.assign(:history, Kati.Search.Recent.all())
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
        {Kati.Screens.SearchIdle.field(assigns.query)}
        {Kati.Screens.SearchIdle.chips(assigns.scope)}
        {Kati.Screens.SearchIdle.recent(assigns.history)}
        {Kati.Screens.SearchIdle.suggestions()}
        {Kati.Screens.SearchIdle.counts_note()}
      </Column>
    </Scroll>
    """
  end

  @doc """
  The field, empty, with the filter disc beside it.

  Drawn as a resting field rather than a focused one: the ink ring screen 18
  gives a focused field is a claim that a caret is in it, and Mob has no caret
  to put there.
  """
  @spec field() :: map()
  def field(query \\ "") do
    assigns = %{query: query, on_change: {self(), :search_query}, on_submit: {self(), :look}}

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Row
          weight={1.0}
          height={52}
          corner_radius={26}
          background={Palette.card()}
          shadow={Kati.Theme.shadow_search()}
          padding_left={18}
          padding_right={18}
          align="center"
        >
          {UI.symbol("search", size: 20, color: Palette.tertiary())}
          <Spacer size={11} />
          <TextField
            value={@query}
            placeholder={Search.placeholder()}
            return_key="search"
            weight={1.0}
            accessibility_id="search_query"
            on_change={@on_change}
            on_submit={@on_submit}
          />
        </Row>
        <Spacer size={10} />
        <Box
          width={44}
          height={44}
          corner_radius={22}
          background={Palette.card()}
          align="center"
          shadow={Kati.Theme.shadow_button()}
          on_tap={{self(), :filters}}
        >
          {UI.symbol("tune", size: 20)}
        </Box>
      </Row>
      <Spacer size={18} />
    </Column>
    """
  end

  @doc """
  The eight scope chips, and not a number among them.

  See the moduledoc: a count of nothing is a true statement that looks like a
  failure, and eight of them on open would look like eight failures.
  """
  @spec chips(String.t()) :: map()
  def chips(active) do
    chips =
      Search.chip_labels()
      |> Enum.map(fn label ->
        UI.chip(label, selected: label == active, on_toggle: String.to_atom("scope_" <> label))
      end)
      |> Enum.intersperse(~MOB"<Spacer size={7} />")

    ~MOB"""
    <Column fill_width={true}>
      <Scroll axis="horizontal">
        <Row>
          {chips}
        </Row>
      </Scroll>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  One row's tag: which list it is in, and which line it is.

  Every recent query drew `:repeat_query` and every suggestion
  `:try_suggestion`, so each card was one `accessibility_id` repeated down its
  own rows and `onNodeWithTag` throws on the second match (#97). A row here IS
  its text — there is nothing else to be — so the text is the identity.

      iex> Kati.Screens.SearchIdle.query_tag("repeat_query", "the long hollow")
      :repeat_query_the_long_hollow

      iex> Kati.Screens.SearchIdle.query_tag("try_suggestion", "")
      :try_suggestion
  """
  @spec query_tag(String.t(), String.t()) :: atom()
  def query_tag(prefix, text) do
    case text |> to_string() |> String.trim() |> String.replace(" ", "_") do
      "" -> String.to_atom(prefix)
      line -> String.to_atom(prefix <> "_" <> line)
    end
  end

  @doc """
  The last eight queries, and the row that forgets them.

  `Clear` sits on the eyebrow rather than at the foot of the list, because a
  destructive control below eight rows is a control you reach by scrolling past
  the thing it destroys.
  """
  @spec recent([String.t()]) :: map()
  def recent(queries) do
    rows =
      queries
      |> Enum.map(fn query ->
        SettingsList.row(
          SettingsList.icon_tile("history"),
          SettingsList.body(query, nil),
          SettingsList.trailing(nil),
          on_tap: {self(), Kati.Screens.SearchIdle.query_tag("repeat_query", query)}
        )
      end)

    # An empty history is WORDED, not omitted, and board 87 is where that was
    # decided: `Kati.Screens.SearchTyping.nothing_yet/0` carries the reasoning
    # in full — "dropping the section entirely on a first run would make the
    # shelf appear from nowhere after the first search; stating that it is
    # empty and what will fill it keeps the shape of the screen constant."
    #
    # 86's own caption says the same in four words: *Recent is empty by
    # definition* on a first run. So the eyebrow stays and the card under it
    # explains itself.
    if rows == [] do
      assigns = %{kept: Search.recent_kept()}

      ~MOB"""
      <Column fill_width={true}>
        {Kati.UI.eyebrow("Recent · last #{@kept}")}
        {Kati.Screens.SearchTyping.nothing_yet()}
      </Column>
      """
    else
      assigns = %{rows: rows, kept: Search.recent_kept()}

      ~MOB"""
      <Column fill_width={true}>
        {Kati.UI.eyebrow("Recent · last #{@kept}", trailing: "Clear")}
        {Kati.UI.SettingsList.card(@rows)}
        <Spacer size={22} />
      </Column>
      """
    end
  end

  @doc """
  The five queries board 86 was captured with.

  Kept on the screen rather than in a fixture module, for the reason
  `Kati.Screens.Home.drawn_rows/0` is: it is the transcription the drawing was
  read from, and `Kati.ScreenDesignLiteralTest` installs it to compare the
  drawing against the drawing. What a device shows is
  `Kati.Search.Recent.all/0`, and `Kati.ScreenEmptyDatabaseTest` is what says
  so — that a store nobody has searched answers `[]` and not this.

  Never translated, in 88's own words: *they are your words*. So the Persian
  mirror draws the same five.
  """
  @spec drawn_recent() :: [String.t()]
  def drawn_recent, do: ["dentist", "leaving soon", "ines karvel", "4 stars", "miso salmon"]

  @doc "Two suggestions, drawn from what you have. Never more — see the moduledoc."
  @spec suggestions() :: map()
  def suggestions do
    rows =
      Search.suggestions()
      |> Enum.map(fn suggestion ->
        SettingsList.row(
          SettingsList.icon_tile("auto_awesome"),
          SettingsList.body(suggestion, nil),
          SettingsList.trailing(nil),
          on_tap: {self(), Kati.Screens.SearchIdle.query_tag("try_suggestion", suggestion)}
        )
      end)

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.eyebrow("Try", dash: Palette.rail_idle())}
      {Kati.UI.SettingsList.card(rows)}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc "The sentence that explains the three numbers this screen rests on."
  @spec counts_note() :: map()
  def counts_note, do: SettingsList.note("info", Search.counts_note())

  @doc """
  What was typed, and where it goes.

  The field was a resting `<Text>` — a drawing of a search box — on the belief
  that Mob had no text input. `Kati.Screens.AddTitle`'s own docs record that
  belief as false and costly: `<TextField>` is in the pinned Mob and
  `Kati.Screens.Backup` has used it for the passphrase all along.

  Held here rather than searched here. Screen 86 is the **idle** board and
  draws recent queries and suggestions; the results belong to screen 19, which
  is drawn mid-query. So this remembers what was typed and
  `Kati.Screens.SearchIdle.look/1` is what hands it on — the same division the
  three boards already draw.
  """
  def handle_info({:change, :search_query, typed}, socket) when is_binary(typed) do
    {:noreply, Mob.Socket.assign(socket, :query, typed)}
  end

  # `Kati.Screens.Pushed` marks `handle_info/2` overridable and defines four
  # clauses on it, one of which routes every `{:tap, tag}` to `handle_tap/2`.
  # Defining one clause here replaces all four — so the Filters disc stopped
  # reaching its handler and screen 88 went unreachable, which is how the tap
  # sweep and the reachability inventory both found it in the same run.
  def handle_info(message, socket), do: super(message, socket)

  @doc """
  Carry the query to the results screen.

  Through `Mob.State` rather than a push argument, because `push_screen/2`
  takes a module and nothing else — the same route `Kati.Locale` takes for a
  value that has to survive a screen boundary.
  """
  @spec look(Mob.Socket.t()) :: Mob.Socket.t()
  def look(socket) do
    Search.hand_over(socket.assigns.query)
    Kati.Search.Recent.remember(socket.assigns.query)
    Mob.Socket.push_screen(socket, Kati.Screens.Search)
  end

  @doc """
  Open the results page on `line`, a query read back out of a tap tag.

  `query_tag/2` replaces spaces with underscores so the tag is an atom a
  device test can type, so this puts them back. A round trip rather than a
  lookup because the shelf and the suggestions are two different lists and
  both arrive here.
  """
  @spec open(Mob.Socket.t(), String.t()) :: Mob.Socket.t()
  def open(socket, line) do
    query = String.replace(line, "_", " ")
    Search.hand_over(query)

    socket
    |> Mob.Socket.assign(:query, query)
    |> Mob.Socket.push_screen(Kati.Screens.Search)
  end

  def handle_tap(:filters, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.SearchSpec)}

  @doc """
  The search key on the keyboard, which is what finally connects the two boards.

  `look/1` has existed since this screen was built and nothing called it: the
  field remembered what was typed and there was no way out of the page. Board
  86's own field draws `return_key="search"`, so the key is the handover the
  design already specified — `Kati.ScreenTapSweepTest` never saw it, because a
  keyboard action is not a tap.
  """
  def handle_tap(:look, socket), do: {:noreply, Kati.Screens.SearchIdle.look(socket)}

  def handle_tap(:repeat_query, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Search)}

  def handle_tap(:try_suggestion, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Search)}

  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "scope_" <> label ->
        {:noreply, Mob.Socket.assign(socket, :scope, label)}

      # A recent query or a suggestion, by its own line — see `query_tag/2`.
      # Both open the search screen, which is what the two bare tags above did
      # and still do for the drawing's own single-row states.
      #
      # Answered inside this case rather than in a clause above it: a prefix
      # clause placed earlier shadows `:try_suggestion` and every scope chip.
      # Both carry their own line across, so the results page opens on the
      # query that was tapped rather than on whatever was last typed. Before
      # `Kati.Search.Query.run/1` existed there was nothing to carry it to and
      # both pushed bare; a shortcut that opens somebody else's results is
      # worse than one that does nothing.
      "repeat_query_" <> line ->
        {:noreply, Kati.Screens.SearchIdle.open(socket, line)}

      "try_suggestion_" <> line ->
        {:noreply, Kati.Screens.SearchIdle.open(socket, line)}

      _other ->
        {:noreply, socket}
    end
  end
end
