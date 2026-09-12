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
  use Gettext, backend: Kati.Gettext

  alias Kati.Search
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  def load(socket) do
    socket
    |> Mob.Socket.assign(:scope, :all)
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
      Search.chip_keys()
      |> Enum.map(fn key ->
        label = Search.scope_label(key)

        # A scope with no group behind it is drawn DISABLED rather than
        # offered. `Kati.Search.narrowable/1` turned Music, Meals and Money
        # into `All` on the way to screen 19, so a reader picked a scope, ran
        # the search, and got everything — with nothing on either screen
        # saying the choice had been dropped. MOVIES-AND-TV.md #73, whose own
        # prescription is this: *grey the four unbuildable chips the way an
        # unavailable control is drawn, so the choice is never offered and then
        # discarded.*
        #
        # The chip stays on the row rather than being removed, because board 86
        # draws seven and the design's contract is wider than the executor on
        # purpose — `Kati.Search.built?/1` is the seam, and screen 88 is where
        # the whole contract is stated.
        built? = Search.built?(key)

        UI.chip(label,
          selected: key == active,
          disabled: not built?,
          # The KEY and not the label: a tag built from a drawn word is a
          # different atom in every language, and the handler then matches none
          # of them — `Kati.Search.built?/1` carries the same note.
          on_toggle: built? && String.to_atom("scope_" <> Atom.to_string(key))
        )
      end)
      |> Enum.intersperse(~MOB"<Spacer size={7} />")

    # Board 313's affordance, which screen 19 has carried since that board
    # landed and this row did not: *"a horizontal scroll with no affordance
    # hides half the scopes behind a gesture nobody knows is there."* The two
    # pages draw one control and 86 was the half without the mark
    # (MOVIES-AND-TV.md #34). `Kati.Screens.Search.chip_line/1` is the recipe
    # and it is called rather than copied, so the two cannot drift again.
    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.Search.chip_line(chips)}
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
  `Recent · last 8`, in the reader's own script and digits.

  The number was interpolated straight into the string, so the eyebrow on the
  Persian rendering of board 90 read **Recent · last 8** over a page of
  Persian — the Latin word and the Latin digit, in a run the bidi algorithm
  then flipped the separator inside. mishka-group/kati#103.
  """
  @spec recent_eyebrow() :: String.t()
  def recent_eyebrow,
    do: gettext("Recent · last %{n}", n: Kati.Locale.number(Search.recent_kept()))

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
      assigns = %{eyebrow: Kati.Screens.SearchIdle.recent_eyebrow()}

      ~MOB"""
      <Column fill_width={true}>
        {Kati.UI.eyebrow(@eyebrow)}
        {Kati.Screens.SearchTyping.nothing_yet()}
      </Column>
      """
    else
      assigns = %{rows: rows, eyebrow: Kati.Screens.SearchIdle.recent_eyebrow()}

      ~MOB"""
      <Column fill_width={true}>
        {Kati.UI.eyebrow(@eyebrow,
           trailing: gettext("Clear"),
           trailing_tap: {self(), :clear_recent}
         )}
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

  @doc """
  Two suggestions, drawn from what you have. Never more — see the moduledoc.

  And now actually drawn from it. `Kati.Search.suggestions/0` is board 86's
  own two — `what leaves this week`, `notes about the estuary` — under a
  caption that says they come from this reader's library, and they match
  nothing on any device but the one the board was captured on
  (MOVIES-AND-TV.md #72). `Kati.Search.Suggestions.for_reader/0` answers with
  the newest title on the shelf and the book the newest note is about, and
  falls back to the board's two on a device that has neither.
  """
  @spec suggestions() :: map()
  def suggestions, do: Kati.Screens.SearchIdle.try_group(Kati.Search.Suggestions.derived())

  @doc """
  Board 321's *Try* group with nothing to suggest from.

  **Present and worded, not absent** — 259's explicit choice for its
  by-section card, and 321 gives the reason: *"Absent would be quieter and
  would also hide that the group exists at all — a reader who never sees Try on
  day one has no idea it will fill."*

  What it replaces is worse than an empty card. `for_reader/1` fell back to
  board 86's own two suggestions on a device with nothing — *what leaves this
  week*, *notes about the estuary* — which match nothing anywhere but the
  machine the board was captured on. A suggestion that finds nothing is the
  defect MOVIES-AND-TV.md #72 was about, one turn further on.
  """
  @spec try_group([String.t()]) :: map()
  def try_group([]) do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.eyebrow("Try", dash: Palette.rail_idle())}
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
            {Kati.UI.symbol("auto_awesome", size: 21, color: Kati.Theme.Palette.rail_idle())}
          </Box>
          <Spacer weight={1.0} />
        </Row>
        <Spacer size={12} />
        <Text
          text="Nothing to suggest from yet"
          text_size={13.5}
          font_weight="bold"
          text_color={:on_surface}
          text_align="center"
        />
        <Spacer size={6} />
        <Text
          text="Try lines are built from what you keep. Add a title and they appear."
          text_size={12}
          line_height={1.55}
          text_color={Kati.Theme.Palette.sub()}
          text_align="center"
        />
        <Spacer size={4} />
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  def try_group(derived) do
    rows =
      derived
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

  # The search key on the keyboard, which is what finally connects the two
  # boards. A comment rather than a second `@doc`, because these are clauses of
  # one `handle_info/2` and the first clause already holds the doc.
  #
  # `look/1` has existed since this screen was built and nothing called it: the
  # field remembered what was typed and there was no way out of the page.
  #
  # **A submit is not a tap**, and that is the whole reason nothing caught it.
  # `mob_send_submit/1` sends `{:submit, tag}` where a tap sends `{:tap, tag}`,
  # so a `handle_tap/2` clause for this never fires and
  # `Kati.ScreenTapSweepTest` — which walks the `on_tap` tags a tree draws —
  # cannot see a keyboard action at all. Written as a `handle_tap` clause first,
  # and found by reading the NIF rather than by any test.
  def handle_info({:submit, :look}, socket),
    do: {:noreply, Kati.Screens.SearchIdle.look(socket)}

  # `Kati.Screens.Pushed` marks `handle_info/2` overridable and defines four
  # clauses on it, one of which routes every `{:tap, tag}` to `handle_tap/2`.
  # Defining one clause here replaces all four — so the Filters disc stopped
  # reaching its handler and screen 88 went unreachable, which is how the tap
  # sweep and the reachability inventory both found it in the same run.
  def handle_info(message, socket), do: super(message, socket)

  @doc """
  Carry both facts this page holds to the results screen.

  The query rode across in `Mob.State` because `push_screen/2` was believed to
  take a module and nothing else — the route `Kati.Locale` takes for a value
  that has to survive a screen boundary. It takes a params map, so the query is
  named in the push and the results page opens on what was actually typed here
  rather than on whatever `Kati.Search.hand_over/1` last wrote.

  The scope never rode at all: eight chips, and picking one moved an assign on
  this page and nothing else. `Kati.Search.narrowable/1`, applied on 19, is what
  decides which of the eight that page can honour.

  `hand_over/1` still runs. It is what a push naming no query falls back to, and
  this page is not the only door into 19.
  """
  @spec look(Mob.Socket.t()) :: Mob.Socket.t()
  def look(socket) do
    Search.hand_over(socket.assigns.query)
    Kati.Search.Recent.remember(socket.assigns.query)

    Mob.Socket.push_screen(socket, Kati.Screens.Search, %{
      query: socket.assigns.query,
      scope: socket.assigns.scope
    })
  end

  @doc """
  The query a tag was built from, found in the list it was built from.

  MOVIES-AND-TV.md #130. This used to undo `query_tag/2` by hand —
  `String.replace(line, "_", " ")` — which is not the inverse of anything.
  `sci_fi` is stored as typed by `Kati.Search.Recent.remember/1`, which "never
  translates — they are your words", tagged `:repeat_query_sci_fi`, and came
  back as `sci fi`: a different search, silently. `two  spaces` collapsed the
  same way.

  There is no inverse to write, because the mapping is not injective. So the
  tag is resolved against the rows that drew it, the way
  `Kati.Screens.Library.open_tile/3` resolves a poster tag — the list is right
  there in the assigns, and the row that made the tag is the row that answers
  it. Screen 19's own recent shelf never had this bug for the same reason: it
  carries the label whole.

      iex> Kati.Screens.SearchIdle.resolve("sci_fi", ["sci_fi", "sci fi"])
      "sci_fi"

      iex> Kati.Screens.SearchIdle.resolve("sci_fi", ["sci fi"])
      "sci fi"

      iex> Kati.Screens.SearchIdle.resolve("gone", [])
      "gone"
  """
  @spec resolve(String.t(), [String.t()]) :: String.t()
  def resolve(line, candidates) do
    Enum.find(candidates, String.replace(line, "_", " "), fn candidate ->
      Kati.Screens.SearchIdle.query_tag("q", candidate) == String.to_atom("q_" <> line)
    end)
  end

  @doc """
  Open the results page on `line`, a query read back out of a tap tag.

  The line is named in the push as well as written to `Mob.State`, which is the
  difference between the results page opening on this row and opening on
  whatever was handed over last. The lit scope rides with it — a person who
  narrowed to Calendar and then tapped a recent query meant both.
  """
  @spec open(Mob.Socket.t(), String.t(), [String.t()]) :: Mob.Socket.t()
  def open(socket, line, candidates) do
    query = Kati.Screens.SearchIdle.resolve(line, candidates)
    Search.hand_over(query)

    socket
    |> Mob.Socket.assign(:query, query)
    |> Mob.Socket.push_screen(Kati.Screens.Search, %{query: query, scope: socket.assigns.scope})
  end

  def handle_tap(:filters, socket),
    do:
      {:noreply,
       Mob.Socket.push_screen(socket, Kati.Screens.SearchSpec, %{
         # MOVIES-AND-TV.md #131: 88 is drawn with a `Settings` back pill and
         # this disc is its only door, so the pill named a screen the pop does
         # not land on. The push says where it came from, as every other push
         # in the app does.
         back: "Search"
       })}

  @doc """
  Forget the shelf, and redraw without it.

  Both halves, and the second is not tidiness: `Kati.Search.Recent` writes
  `Mob.State`, which is neither an assign nor a nav action — the blind spot
  `Kati.Screens.LanguagePick`'s two entries in `@inert_taps` exist for — so a
  clear that did not also move `:history` would look dead to every sweep AND
  leave eight rows on screen under a heading that says they are gone. The
  card gives way to board 87's *Nothing searched yet* on the next render,
  which is the state `recent/1` already draws for an empty history.
  """
  def handle_tap(:clear_recent, socket) do
    Kati.Search.Recent.forget!()
    {:noreply, Mob.Socket.assign(socket, :history, [])}
  end

  # `query_tag/2` answers a bare tag only for a row whose text is empty — the
  # drawing's own single-row states. There is no line to carry, so these two say
  # `""` rather than staying silent: silence is what lets the stale `Mob.State`
  # key answer, which is the defect the two prefixed clauses below were written
  # for.
  def handle_tap(:repeat_query, socket),
    do:
      {:noreply,
       Mob.Socket.push_screen(socket, Kati.Screens.Search, %{
         query: "",
         scope: socket.assigns.scope
       })}

  def handle_tap(:try_suggestion, socket),
    do:
      {:noreply,
       Mob.Socket.push_screen(socket, Kati.Screens.Search, %{
         query: "",
         scope: socket.assigns.scope
       })}

  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "scope_" <> key ->
        {:noreply, Mob.Socket.assign(socket, :scope, String.to_existing_atom(key))}

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
      # Each against the list that drew it — the shelf and the suggestions are
      # two lists and a tag belongs to exactly one of them.
      "repeat_query_" <> line ->
        {:noreply,
         Kati.Screens.SearchIdle.open(socket, line, Map.get(socket.assigns, :history, []))}

      "try_suggestion_" <> line ->
        {:noreply,
         Kati.Screens.SearchIdle.open(socket, line, Kati.Search.Suggestions.for_reader())}

      _other ->
        {:noreply, socket}
    end
  end
end
