defmodule Kati.Screens.AddByHand do
  @moduledoc """
  Screen 154 — Add by hand. The form behind screen 89's *Can't find it?* row.

  Built to `test/design/screens/154.html`. Its own caption is the argument for
  building it before anything else on the board list: *until the catalogue
  lands, everything a search finds is invented — so this form is the only path
  from a fresh install to a library with anything in it.*

  Screen 89 has drawn that row since it was written and rendered it with **no
  `on_tap` at all**, because nothing existed to open. `Kati.Screens.AddTitle`'s
  moduledoc has carried the apology for a while; this is the destination.

  ## What it writes

  A `Kati.Media.TrackedTitle` with `source: :manual` and the typed title as its
  `source_id`, which is the shape `Kati.Screens.AddTitle.track/2` already
  writes for a row nobody could find. No `CachedTitle` is invented alongside
  it: a hand-typed title has no poster and no episode list, and the board says
  so in as many words rather than drawing a placeholder that implies one is
  coming.

  ## Film is the default, and board 154 is not drawn in it

  Board 155 says so in as many words — *"Resting — empty, Film, nothing
  assumed"* — and 154's own caption explains why it shows the other one: it is
  drawn *"with Series chosen so the episode-count field is visible"*. A form
  that assumed Series would be assuming the answer to its own second question.

  So this screen loads as Film and `Kati.ScreenDesignLiteralTest`'s
  `drawn_state/0` puts it in 154's state for the comparison, which is the same
  arrangement screens 01, 02 and 03 use for a board drawn with rows in it.

  ## The two optional fields, and why the board marks them

  **Year** narrows nothing today. It is on the board because a person typing a
  title they could not find usually knows the year, and losing it would mean
  asking again when the catalogue arrives.

  **Total episodes** is the one that changes what the app can draw. Without it
  a series still tracks and its progress bar has no denominator — which
  `Kati.Screens.Library.fraction/1` already handles honestly by drawing an
  empty track rather than inventing a percentage. The board's own note says
  exactly that, so the field is an offer rather than a requirement.

  ## The refusal

  Save with no title refuses in words and writes nothing, which is
  `Kati.Write`'s contract and what `Kati.WriteContractTest` enforces on the
  host. Board 155 draws that state.
  """
  use Kati.Screens.Pushed, back: "Add title"

  # The one-shot key `opened/2` leaves for the Library. See `hand_over/1`.
  @handover "add_by_hand:open"

  alias Kati.Components.MishkaChip
  alias Kati.Theme.Palette

  @kinds [{"Film", :movie, "movie"}, {"Series", :tv, "live_tv"}]
  @statuses [{"Not started", :not_started}, {"Watching", :watching}, {"Finished", :finished}]

  @impl true
  def load(socket) do
    Mob.Socket.assign(socket,
      title: "",
      kind: :movie,
      year: "",
      status: :not_started,
      episodes: "",
      save_error: nil
    )
  end

  @doc false
  def content(assigns) do
    # The board draws its back pill in the flow at 64; the macro floats one
    # at 54, 42 tall, so the content that follows starts at `content_top/0`
    # to clear it. Before this the column had no padding at all and the
    # form ran to the pixel with its heading under the pill.
    Kati.Screens.Pushed.page(
      ~MOB"""
      <Column fill_width={true}>
        {Kati.Screens.AddByHand.heading()}
        {Kati.Screens.AddByHand.labelled("Title", Kati.Screens.AddByHand.field(:title, assigns.title, "e.g. The Long Hollow", Kati.Screens.AddByHand.untitled?(assigns)))}
        {Kati.Screens.AddByHand.labelled("Kind", Kati.Screens.AddByHand.kinds(assigns.kind))}
        {Kati.Screens.AddByHand.labelled("Year", Kati.Screens.AddByHand.field(:year, assigns.year, "2024"), "optional")}
        {Kati.Screens.AddByHand.labelled("Status", Kati.Screens.AddByHand.statuses(assigns.status))}
        {Kati.Screens.AddByHand.episodes(assigns)}
        {Kati.Screens.AddByHand.error(assigns.save_error)}
        {Kati.UI.Sheet.commit("Add to library", :add)}
        <Spacer size={14} />
        {Kati.Screens.AddByHand.split_note("A hand-typed title carries", "no poster and no episode list", ". If Kati finds it later both arrive, and nothing you typed is overwritten.")}
      </Column>
      """,
      Kati.Screens.Pushed.content_top()
    )
  end

  @doc false
  def heading do
    ~MOB"""
    <Column fill_width={true}>
      <Text
        text="Add by hand"
        text_size={28}
        max_font_scale={1.6}
        font_weight="bold"
        letter_spacing={-0.03}
        text_color={:on_surface}
      />
      <Spacer size={7} />
      <Text
        text="For something Kati could not find. The title is the only thing it needs."
        text_size={13}
        line_height={1.55}
        text_color={Palette.sub()}
      />
      <Spacer size={20} />
    </Column>
    """
  end

  @doc """
  This form in the reader's own script.

  Screen 89's row pushed the English one whatever the locale was, and
  `Kati.Screens.AddByHandFa` sat on `Kati.AppReachabilityTest`'s inventory with
  exactly that as its reason — the last Persian mirror in the app a person
  could not reach. Both callers go through here now, which is #93's third
  criterion answered for this screen: *Persian screens are reachable after
  onboarding, not only during it.*

  A function rather than an `if` at each call site, for the reason
  `Kati.Onboarding.screen_for_step/2` is one: two call sites deciding the same
  thing separately eventually disagree, and the disagreement shows up as a
  screen in the wrong language rather than as an error.
  """
  @spec for_locale() :: module()
  def for_locale do
    case Kati.Locale.current() do
      :fa -> Kati.Screens.AddByHandFa
      _en -> Kati.Screens.AddByHand
    end
  end

  @doc "A field under its own label, with the board's `optional` marker when it has one."
  @spec labelled(String.t(), map(), String.t() | nil) :: map()
  def labelled(label, body, marker \\ nil, face \\ "mono") do
    # Persian takes Vazirmatn at 11/600 with no tracking, which is
    # `Kati.Screens.Fa.eyebrow/1`'s recipe rather than this one with the family
    # swapped: DM Mono's 10.5 at .16em is a Latin small-caps effect and the
    # Arabic script has neither case nor a tradition of letter-spacing.
    persian? = face == "fa"
    assigns = %{label: label, body: body, marker: marker, face: face, persian?: persian?}

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Text
          text={@label}
          font_family={@face}
          text_size={if @persian?, do: 11, else: 10.5}
          font_weight={if @persian?, do: "semibold", else: "normal"}
          letter_spacing={if @persian?, do: 0, else: 0.16}
          text_color={Palette.muted()}
          max_lines={1}
        />
        <Spacer weight={1.0} />
        {Kati.Screens.AddByHand.marker(@marker, @face)}
      </Row>
      <Spacer size={8} />
      {@body}
      <Spacer size={18} />
    </Column>
    """
  end

  @doc false
  def marker(text, face \\ "sans")

  def marker(nil, _face), do: ~MOB"<Spacer size={0} />"

  def marker(text, face) do
    assigns = %{text: text, face: face}

    ~MOB"""
    <Text
      text={@text}
      font_family={@face}
      text_size={11.5}
      text_color={Palette.tertiary()}
      max_lines={1}
    />
    """
  end

  @doc false
  def field(tag, value, placeholder, refused? \\ false) do
    assigns = %{
      value: value,
      placeholder: placeholder,
      on_change: {self(), tag},
      id: Atom.to_string(tag),
      # Board 155 draws a red inset ring on the field the refusal is ABOUT, and
      # this drew none — so a reader was told *a title is needed* over four
      # fields and had to work out which. MOVIES-AND-TV.md #128.
      #
      # Width 0 rather than a transparent border: a 1.5pt ring that is only
      # sometimes coloured would move the text by 1.5pt when it appeared.
      ring: if(refused?, do: Palette.red(), else: Palette.card()),
      ring_width: if(refused?, do: 1.5, else: 0)
    }

    ~MOB"""
    <Row
      fill_width={true}
      height={48}
      corner_radius={14}
      background={Palette.card()}
      border_color={@ring}
      border_width={@ring_width}
      shadow={Kati.Theme.shadow_card_soft()}
      padding_left={15}
      padding_right={15}
      align="center"
    >
      <TextField
        value={@value}
        placeholder={@placeholder}
        return_key="done"
        weight={1.0}
        accessibility_id={@id}
        on_change={@on_change}
      />
    </Row>
    """
  end

  @doc "The two kinds, and the three statuses. Functions and not module attributes: inside `~MOB` an `@name` is an ASSIGN, which is the trap this file hit first."
  @spec kind_list() :: [{String.t(), atom(), String.t()}]
  def kind_list, do: @kinds

  @doc false
  @spec status_list() :: [{String.t(), atom()}]
  def status_list, do: @statuses

  @doc false
  def kinds(active) do
    ~MOB"""
    <Row fill_width={true} align="center">
      {Enum.map(Kati.Screens.AddByHand.kind_list(), fn {label, kind, icon} ->
        Kati.Screens.AddByHand.kind_chip(label, icon, kind == active, kind)
      end)
      |> Enum.intersperse(Kati.Screens.AddByHand.gap())}
    </Row>
    """
  end

  @doc """
  One Kind chip.

  `kind` is the tap's name and `label` is only ever drawn. They were the same
  string until MOVIES-AND-TV.md #157: the tag was `kind_` <> the label, so the
  Persian form's control was `:kind_فیلم` — a name no device test can type, and
  a screen that renames its own controls when the language changes. The key is
  stable across every locale; the word is not.
  """
  @spec kind_chip(String.t(), String.t(), boolean(), atom(), String.t()) :: map()
  def kind_chip(label, icon, on?, kind, face \\ "sans") do
    assigns = %{
      label: label,
      icon: icon,
      on?: on?,
      face: face,
      tap: {self(), Kati.Screens.AddByHand.tag("kind_", kind)}
    }

    ~MOB"""
    <Row
      height={38}
      corner_radius={19}
      background={if @on?, do: Palette.ink_fill(), else: Palette.card()}
      padding_left={14}
      padding_right={16}
      align="center"
      on_tap={@tap}
    >
      {Kati.UI.symbol(@icon, size: 17, color: if(@on?, do: Palette.on_ink(), else: Palette.ink_soft()))}
      <Spacer size={7} />
      <Text
        text={@label}
        font_family={@face}
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
      {Enum.map(Kati.Screens.AddByHand.status_list(), fn {label, status} -> Kati.Screens.AddByHand.status_chip(label, status == active, status) end)
       |> Enum.intersperse(Kati.Screens.AddByHand.gap())}
    </Row>
    """
  end

  @doc false
  def status_chip(label, on?, status) do
    MishkaChip.chip(
      label: label,
      checked: on?,
      on_toggle: Kati.Screens.AddByHand.tag("status_", status),
      height: 32,
      padding_x: 15,
      padding_y: 0,
      corner_radius: 16,
      text_size: 12.5,
      font_weight: :semibold,
      max_lines: 1,
      color: Palette.ink_fill(),
      text_color: Palette.on_ink(),
      unchecked_color: Palette.card(),
      unchecked_text_color: Palette.ink_soft()
    )
  end

  @doc false
  def gap, do: ~MOB"<Spacer size={7} />"

  @doc """
  The episode field, and only for a series.

  A film has no episode total, so drawing the field for one would be asking a
  question with no answer. The board draws it under Series and the note under
  it says what leaving it empty costs.
  """
  @spec episodes(map()) :: map()
  def episodes(%{kind: :movie}), do: ~MOB"<Spacer size={0} />"

  def episodes(assigns) do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.AddByHand.labelled("Total episodes", Kati.Screens.AddByHand.field(:episodes, assigns.episodes, "7"), "optional")}
      {Kati.Screens.AddByHand.split_note("Without it a series still tracks, but its progress bar has", "no denominator", "— which the app already draws honestly.")}
      <Spacer size={18} />
    </Column>
    """
  end

  @doc """
  A note whose middle clause is the one that matters.

  Three `<Text>` nodes and not one sentence, because the board draws it that
  way — the emphasis falls on *no denominator* and *no poster and no episode
  list*, and `Kati.ScreenDesignLiteralTest` compares a drawing's lines against
  the tree's, so a single joined string is a different shape from the drawn
  one even when it reads the same.
  """
  @spec split_note(String.t(), String.t(), String.t()) :: map()
  def split_note(lead, emphasis, tail, face \\ "sans") do
    assigns = %{lead: lead, emphasis: emphasis, tail: tail, face: face}

    ~MOB"""
    <Row fill_width={true} background={Palette.cream()} corner_radius={16} padding={13} align="top">
      {Kati.UI.symbol("info", size: 16, color: Palette.bronze())}
      <Spacer size={9} />
      <Column weight={1.0}>
        <Text
          text={@lead}
          font_family={@face}
          text_size={12}
          line_height={1.5}
          text_color={Palette.ink_soft()}
        />
        <Text
          text={@emphasis}
          font_family={@face}
          text_size={12}
          line_height={1.5}
          font_weight="semibold"
          text_color={Palette.ink()}
        />
        <Text
          text={@tail}
          font_family={@face}
          text_size={12}
          line_height={1.5}
          text_color={Palette.ink_soft()}
        />
      </Column>
    </Row>
    """
  end

  @doc false
  def error(nil), do: ~MOB"<Spacer size={0} />"

  def error({title, body}) do
    assigns = %{title: title, body: body}

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        padding={17}
        shadow={Kati.Theme.shadow_card_soft()}
      >
        <Row fill_width={true} align="top">
          {Kati.UI.symbol("error", size: 19, color: Palette.red())}
          <Spacer size={11} />
          <Column weight={1.0}>
            <Text text={@title} text_size={13.5} font_weight="bold" text_color={:on_surface} />
            <Spacer size={6} />
            <Text text={@body} text_size={12.5} line_height={1.65} text_color={Palette.ink_soft()} />
          </Column>
        </Row>
      </Column>
      <Spacer size={14} />
    </Column>
    """
  end

  def error(message) when is_binary(message) do
    Kati.Screens.AddByHand.error({message, Kati.Screens.AddByHand.nothing_lost()})
  end

  @doc """
  Board 155's own reassurance, and the reason it is on every refusal.

  MOVIES-AND-TV.md #128: the empty-title refusal was one line where the board
  specifies two, and the missing half is the one that matters — a person whose
  save just failed does not know whether their other four answers survived it.
  The board says so outright, so every refusal on this form says it: a store
  error loses nothing either.

      iex> Kati.Screens.AddByHand.nothing_lost()
      "Nothing was written — this form is still open and your other answers are intact."
  """
  @spec nothing_lost() :: String.t()
  def nothing_lost,
    do: "Nothing was written — this form is still open and your other answers are intact."

  @doc """
  Whether the Title field is the one a standing refusal is about.

      iex> Kati.Screens.AddByHand.untitled?(%{save_error: {"A title is needed", "…"}})
      true

      iex> Kati.Screens.AddByHand.untitled?(%{save_error: nil})
      false
  """
  @spec untitled?(map()) :: boolean()
  def untitled?(assigns) do
    case Map.get(assigns, :save_error) do
      {"A title is needed", _body} -> true
      _other -> false
    end
  end

  @doc """
  What was typed, in whichever of the three fields.

  Each `<TextField>` carries its own assign name as its change tag, so this is
  one clause rather than three — `field/3` builds the tag from the same atom it
  puts in `accessibility_id`, which is what lets a device test address the field
  it typed into.

  **The catch-all delegates to `super/2`.** `Kati.Screens.Pushed` marks
  `handle_info/2` overridable and defines four clauses on it, one of which
  routes every `{:tap, tag}` to `handle_tap/2`; replacing all four is how screen
  88 went unreachable earlier on this branch. This file was written with no
  change handler at all, so nothing typed ever reached the assign and Add
  refused every time — found by the device test, which is the only thing that
  could have found it.
  """
  @impl true
  def handle_info({:change, field, typed}, socket)
      when field in [:title, :year, :episodes] and is_binary(typed),
      do: {:noreply, Mob.Socket.assign(socket, field, typed)}

  def handle_info(message, socket), do: super(message, socket)

  @impl true
  def handle_tap(:add, socket), do: {:noreply, Kati.Screens.AddByHand.save(socket)}

  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "kind_movie" -> {:noreply, Mob.Socket.assign(socket, :kind, :movie)}
      "kind_tv" -> {:noreply, Mob.Socket.assign(socket, :kind, :tv)}
      "status_" <> key -> {:noreply, Kati.Screens.AddByHand.pick(socket, key)}
      _other -> {:noreply, socket}
    end
  end

  @doc """
  Write the row, or say why not.

  `source: :manual` and the title as `source_id`, which is what
  `Kati.Screens.AddTitle.track/2` writes for a title nobody could find — one
  shape for a hand-typed row, not two.

  ## Two rows, and the second one is the name

  A `Kati.Media.TrackedTitle` holds what you DECIDED about a title — the kind,
  the status, how far in you are. It does not hold what the title IS, and that
  includes its name: the shelf reads the name off `Kati.Media.CachedTitle`, and
  `Kati.Screens.Library`'s own moduledoc says **a row with no cached title is
  dropped** — "a tile captioned `nil` is worse than a tile that is not there".

  So writing only the tracked row put a title in the library that the library
  did not draw, and that `Kati.Search.Query.run/1` could not find either, since
  it reads the cache too. The one path from a fresh install to a library with
  anything in it produced a row nobody could see. It survived every test here
  because they all counted `tracked_titles`, which was never the question.

  `Kati.Screens.AddTitle.cache/2` is the same call screen 06 makes for a title
  nobody could find, and it is idempotent for the reason its own docs give:
  removing a title deletes what you decided and keeps what the title is, so
  re-adding one you had removed must not collide.

  The cache row goes first. If it fails, nothing is written — a tracked row
  with no name is the state this is fixing, and it would be perverse to create
  one while handling the error that says we cannot.
  """
  @spec save(Mob.Socket.t()) :: Mob.Socket.t()
  def save(socket) do
    title = String.trim(socket.assigns.title)

    if title == "" do
      # Board 155's own two lines, which this said one of. The second is the
      # half that matters: somebody whose save just failed does not know
      # whether their other four answers survived it (#128).
      Mob.Socket.assign(
        socket,
        :save_error,
        {"A title is needed",
         "Kati cannot keep a thing with no name. " <> Kati.Screens.AddByHand.nothing_lost()}
      )
    else
      with nil <- Kati.Screens.AddByHand.already_kept(title),
           {:ok, _cached} <-
             Kati.Screens.AddTitle.cache(
               title,
               socket.assigns.kind,
               Kati.Screens.AddByHand.typed_facts(socket.assigns)
             ),
           {:ok, tracked} <- Kati.Screens.AddByHand.track(title, socket.assigns) do
        Kati.Screens.AddByHand.opened(socket, tracked)
      else
        error ->
          Mob.Socket.assign(socket, :save_error, Kati.Screens.AddByHand.refusal(error, title))
      end
    end
  end

  @doc """
  The shelf row already carrying this name, whatever source wrote it — or `nil`.

  MOVIES-AND-TV.md #113. The duplicate guard is the unique index on
  `[:source, :source_id]`, and a TMDB add writes `:tmdb` with a numeric id
  where a hand-typed one writes `:manual` with the title. They never collide,
  so the same film sat on the shelf twice: once from the search and once typed.

  Matched on the NAME, through `Kati.Media.CachedTitle.names/1` — TMDB's own
  two — and normalised the way every other name comparison in this app is
  (`Kati.Import.Job.name_key/1`: trimmed, case-folded, nothing else). So
  *the long hollow* finds `The Long Hollow`, and a reader who types the
  original title of a show they added under its English one is told.

  Only rows on the shelf. A cache row with no tracked row beside it is a title
  somebody looked up and did not keep, and typing that name is how they keep
  it.
  """
  @spec already_kept(String.t()) :: map() | nil
  def already_kept(title) do
    key = Kati.Import.Job.name_key(title)

    cached =
      Kati.Media.CachedTitle
      |> Ash.read!()
      |> Map.new(&{{&1.source, &1.source_id}, &1})

    [:movie, :tv, :anime]
    |> Enum.flat_map(fn kind ->
      Kati.Media.TrackedTitle
      |> Ash.Query.for_read(:shelf, %{kind: kind})
      |> Ash.read!()
    end)
    |> Enum.find(fn row ->
      cached
      |> Map.get({row.source, row.source_id})
      |> Kati.Media.CachedTitle.names()
      |> Enum.any?(&(Kati.Import.Job.name_key(&1) == key))
    end)
  rescue
    _error -> nil
  end

  @doc false
  @spec track(String.t(), map()) :: {:ok, term()} | {:error, term()}
  def track(title, assigns) do
    Kati.Media.TrackedTitle
    |> Ash.Changeset.for_create(:create, %{
      source: :manual,
      source_id: title,
      kind: assigns.kind,
      status: assigns.status
    })
    |> Ash.create()
    |> Kati.Screens.AddByHand.logged()
    |> Kati.Write.note("add by hand #{title}")
  end

  @doc """
  Record the add, and pass the result through unchanged.

  MOVIES-AND-TV.md #112: screen 15's `Added` chip matched nothing, because
  nothing recorded that a title arrived. Written on the way past rather than in
  the caller, so the one place that adds a hand-typed title is the one place
  that says so.
  """
  @spec logged({:ok, term()} | {:error, term()}) :: {:ok, term()} | {:error, term()}
  def logged({:ok, tracked} = result) do
    Kati.Media.Log.write(tracked, :added, %{from_status: nil})
    result
  end

  def logged(result), do: result

  @doc """
  What the form collected, in the shape the cache row stores it.

  Both fields were typed, held on the socket and then dropped: `create_cache/2`
  wrote five fields and neither was one of them. So a series added by hand had
  no `episode_count` — the denominator every progress bar in the app divides
  by, and the note under that very field promised it, in as many words:
  *without it a series still tracks, but its progress bar has no denominator*.
  And the Year went nowhere at all, because until this round
  `Kati.Media.CachedTitle` had no column for one. MOVIES-AND-TV.md #59.

  Both are parsed rather than trusted, and anything that is not a positive
  integer is simply absent — a form is a place people mistype, and a `nil` year
  is honest where a `0` is a claim. The episode field is drawn only for a
  series, so a film's is ignored even if something put a value there.

      iex> Kati.Screens.AddByHand.typed_facts(%{kind: :tv, episodes: "7", year: "2024"})
      %{episode_count: 7, first_release_year: 2024}

      iex> Kati.Screens.AddByHand.typed_facts(%{kind: :movie, episodes: "7", year: "1999"})
      %{first_release_year: 1999}

      iex> Kati.Screens.AddByHand.typed_facts(%{kind: :tv, episodes: "  ", year: "not a year"})
      %{}
  """
  @spec typed_facts(map()) :: map()
  def typed_facts(assigns) do
    %{}
    |> put_counted(:episode_count, episodes_typed(assigns))
    |> put_counted(:first_release_year, counted(Map.get(assigns, :year)))
  end

  defp episodes_typed(%{kind: :movie}), do: nil
  defp episodes_typed(assigns), do: counted(Map.get(assigns, :episodes))

  defp counted(value) do
    case Integer.parse(String.trim(value || "")) do
      {n, ""} when n > 0 -> n
      _unparsed -> nil
    end
  end

  defp put_counted(map, _key, nil), do: map
  defp put_counted(map, key, value), do: Map.put(map, key, value)

  @doc """
  Where a save goes: the title that was just written.

  It popped, which put the reader back on screen 06 — a search sheet showing
  four films they did not add. Board 155 rules that out in as many words:
  *straight to the new title's detail screen — 04 for a series, 08 for a film.
  Returning to 89 would leave the person on a search results page for a title
  they just finished typing; the detail screen is where the next thing they
  want to do lives.* MOVIES-AND-TV.md #28.

  `reset_to/3` rather than a push, because the two screens behind — 154 and 06
  — are both about typing a title that now exists, and a back tap onto either
  would be a step backwards through a job that is done.

  ## It resets to the LIBRARY, and the Library opens the title

  Resetting straight to the detail screen made a **pushed page the bottom of
  the nav stack**, and that is not a cosmetic difference. `Mob.Screen` answers
  `{:pop}` on an empty history by doing nothing at all, so the back pill —
  labelled `Library`, which there was no longer any way to reach — was inert;
  and its handler for the system back gesture is worse: `if nav_history == [],
  do: :mob_nif.exit_app()`. So a reader who added their first title by hand
  landed on a page whose own back control did nothing and whose OS back
  **closed Kati**, on the one path from a fresh install to a library with
  anything in it.

  The stack has to end in a root, so the reset lands on one: screen 03, which
  draws the dock and is where `back: "Library"` was already claiming to go.
  `Kati.Screens.Library.load/1` reads the id out of a one-shot `Mob.State` key
  and pushes the detail screen itself, which leaves the history as *[Library]*
  with the detail page on top — board 155's destination, reached in a way the
  back gesture can undo.

  `send(self(), …)` rather than a `push_screen/3` inside `load/1`: `Mob.Screen`
  takes an initial mount straight to `do_render/2` and never reads
  `nav_action`, so a push from a mount is silently discarded.
  `Kati.Screens.Root`'s own mount uses the same idiom for the first-run
  redirect and says so.
  """
  @spec opened(Mob.Socket.t(), term()) :: Mob.Socket.t()
  def opened(socket, tracked) do
    Kati.Screens.Resume.announce()
    Kati.Screens.AddByHand.hand_over(tracked)

    Mob.Socket.reset_to(socket, Kati.Screens.Library, %{})
  end

  @doc """
  The baton `opened/2` leaves for the Library: open this title next.

  A `Mob.State` key rather than a nav param because the two are on opposite
  sides of a `reset_to/3` — the Library is mounted by `Mob.Screen` from a fresh
  socket, and nothing a screen assigns survives that.

  One-shot by construction: `take/0` deletes as it reads, so a Library reached
  any other way afterwards opens nothing. That matters more than it looks —
  a baton left behind would re-open the same title every time the reader
  touched the Library tab.
  """
  @spec hand_over(term()) :: :ok
  def hand_over(tracked) do
    Mob.State.put(@handover, %{id: tracked.id, screen: detail_screen(tracked)})
    :ok
  rescue
    _error -> :ok
  catch
    :exit, _reason -> :ok
  end

  @doc "The baton, taken. `nil` when there is none, and never twice."
  @spec take() :: %{id: String.t(), screen: module()} | nil
  def take do
    case Mob.State.get(@handover) do
      %{id: id, screen: screen} when is_binary(id) and is_atom(screen) ->
        Mob.State.delete(@handover)
        %{id: id, screen: screen}

      _none ->
        nil
    end
  rescue
    _error -> nil
  catch
    :exit, _reason -> nil
  end

  defp detail_screen(%{kind: :movie}), do: Kati.Screens.Film
  defp detail_screen(_series), do: Kati.Screens.Series

  @doc """
  Why a write was refused, in words.

  Adding a title you already have is refused, and rightly — two rows for one
  title is not a state the shelf can draw. But the tracked row's uniqueness is
  a database constraint, and Ash reports it as *"Has already been taken"*,
  which is a sentence about a column. Someone who has just typed a name they
  already own needs to be told THAT, not to be shown the index that noticed.

  Everything else goes to `Kati.Write.message/1`, which is where the general
  cases and the untranslated-template guard live.
  """
  @spec refusal(term(), String.t()) :: String.t()
  def refusal({:error, %{errors: errors}} = error, title) do
    taken? =
      Enum.any?(errors, fn e ->
        e |> Map.get(:message, "") |> to_string() |> String.contains?("already been taken")
      end)

    if taken?,
      do: "“" <> title <> "” is already in your library.",
      else: Kati.Write.message(error)
  end

  # A shelf row, which is what `already_kept/1` answers with when the name is
  # taken. Two lines, as every refusal on this form is (#128) — and the second
  # one says what to do instead, because *you already have this* with no way
  # forward is a dead end on the one screen a reader reaches by not finding
  # something.
  def refusal(%Kati.Media.TrackedTitle{}, title),
    do:
      {"You already have this",
       "“#{title}” is on your shelf already, under a name Kati matched. " <>
         "Nothing was written — open it from your library to change what you keep about it."}

  def refusal(error, _title), do: Kati.Write.message(error)

  @doc """
  A control's name: a prefix and the stable key under it.

      iex> Kati.Screens.AddByHand.tag("kind_", :tv)
      :kind_tv

      iex> Kati.Screens.AddByHand.tag("status_", :not_started)
      :status_not_started

  Never the label. See `kind_chip/5`.
  """
  @spec tag(String.t(), atom()) :: atom()
  def tag(prefix, key), do: String.to_atom(prefix <> Atom.to_string(key))

  @doc """
  Take a Status chip's tap, if it names one of the three.

  A tag Kati did not draw leaves the assign alone rather than writing a status
  the resource would refuse at save time.
  """
  @spec pick(Mob.Socket.t(), String.t()) :: Mob.Socket.t()
  def pick(socket, key) do
    case Enum.find(@statuses, fn {_label, status} -> Atom.to_string(status) == key end) do
      {_label, status} -> Mob.Socket.assign(socket, :status, status)
      nil -> socket
    end
  end
end
