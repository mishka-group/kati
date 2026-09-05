defmodule Kati.Screens.AddByHandRecord do
  @moduledoc """
  Screen 178 — Add by hand, a record. The first thing in Kati that can put an
  album or an artist on the Music shelf.

  Built to `test/design/screens/178.html`. `D-39` opens with the sentence this
  screen exists to falsify: *the music domain is finished and unreachable*.
  `Kati.Music.Album`, `Artist`, `Track` and `Listen` are migrated, indexed and
  read by four screens, and until this file nothing anywhere in `lib/` wrote
  one — so screen 21 was permanently on `Kati.Music.Sample`, screen 74's rating
  tile printed a figure nothing could set, and screen 73's **Save listen**
  answered `{:error, :nothing_to_save}` on every device that has ever existed.

  ## Why this is not a Kind on screen 154

  `Kati.Screens.AddByHand` writes a `Kati.Media.CachedTitle` and a
  `Kati.Media.TrackedTitle`. Screen 21 reads `Kati.Music`, and the two cannot be
  made one write: `CachedTitle` has no byline column at all, and
  `Kati.Media.Watch` records that a title was watched, never that a record was
  played. So the Kind row is one control that reveals **two forms**, which is
  what board 178's own annotation says, and this is the second of them. Film,
  Series and Book are 154's domain and their chips push it.

  ## Artist is a Kind beside Album, not a field reached only through one

  `Kati.Music.Album`'s `belongs_to :artist` is `allow_nil? true`, so an
  album-only path would quietly accumulate records with nobody behind them —
  and screen 77 is a full detail page carrying `role`, `country` and
  `following`, three values an album form has nowhere to put. Following
  somebody whose records you do not own yet is a thing people do.

  Within the Album state the Artist field still creates one inline, so the
  common path stays one form: see `artist_for/1`, which reuses an artist whose
  name matches rather than filing a second person under one name.

  ## The Artist inset is a picture, and its chips carry no taps

  Board 178 draws the Album state live and the Artist state as an inset beside
  it, because that state drops three fields and gains two. This screen draws
  both, and the inset is drawn only while the live form is NOT in the Artist
  state — pick **Artist** and the inset's job has been taken over by the form
  above it.

  Nothing in the inset is tappable. `Kati.Screens.AddByHandStates.drawn_kinds/0`
  is the precedent and its own doc gives the reason in as many words: *a preview
  is not a control*. Reusing `kinds/1` there put live `kind_*` tags on a
  reference sheet that answered none of them, and here it would additionally
  give two nodes one `accessibility_id` — which `Kati.ScreenTapSweepTest`'s
  collision register exists to refuse.

  ## Where Tracks goes, and the column that does not exist

  **Tracks is a count, never eleven rows of `4:12`** — `Kati.Music.Track` marks
  `seconds` nullable and says why. There is no `track_count` column on
  `Kati.Music.Album` to put the count in, and adding one is not a free change:
  `Kati.Backup.Catalog.columns/1` is derived from the resource, so a new
  attribute moves `Kati.Backup.Catalog.fingerprint/0`, which is pinned in
  `Kati.BackupCatalogTest` against a schema version older backups are read
  under.

  So a typed count writes that many `Kati.Music.Track` rows, positioned 1..n,
  each titled `Track n`, with no seconds and no plays. That gives screen 74 the
  denominator its tracklist eyebrow has never had, and it is honest about what
  it knows: a position and nothing else. A real running order arrives with a
  provider, or with the second life board 178's caption leaves open for this
  field. Nothing is invented that a person did not type — a placeholder that
  says *track 7* claims only that the album has a seventh track, which is
  exactly what was typed.

  ## No Status row

  `Kati.Media.TrackedTitle`'s five statuses are watch statuses. An album is not
  watched and is never finished — `Kati.Music.Listen`'s own moduledoc settles
  it: *music gets no "finished" shortcut*. The row is removed rather than
  translated, and the board says so on its face.
  """
  use Kati.Screens.Pushed, back: "Add title"

  alias Kati.Music.Album
  alias Kati.Music.Artist
  alias Kati.Music.Track
  alias Kati.Screens.AddByHand
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  # `{label, kind, glyph}`, in the board's own order. A function rather than a
  # module attribute at the call site, for the trap `Kati.Screens.AddByHand`
  # records: inside `~MOB` an `@name` is an ASSIGN.
  @kinds [
    {"Film", :movie, "movie"},
    {"Series", :tv, "live_tv"},
    {"Book", :book, "menu_book"},
    {"Album", :album, "graphic_eq"},
    {"Artist", :artist, "mic"}
  ]

  @impl true
  def load(socket) do
    Mob.Socket.assign(socket,
      kind: :album,
      title: "",
      artist: "",
      released: "",
      tracks: "",
      first_heard: "",
      role: "",
      country: "",
      following: false,
      save_error: nil
    )
  end

  @doc false
  @spec kind_list() :: [{String.t(), atom(), String.t()}]
  def kind_list, do: @kinds

  @doc false
  def content(assigns) do
    Kati.Screens.Pushed.page(
      ~MOB"""
      <Column fill_width={true}>
        {Kati.Screens.AddByHandRecord.heading()}
        {AddByHand.labelled(Kati.Screens.AddByHandRecord.title_label(assigns.kind), Kati.Screens.AddByHandRecord.field(:title, assigns.title, Kati.Screens.AddByHandRecord.title_hint(assigns.kind)))}
        {AddByHand.labelled("Kind", Kati.Screens.AddByHandRecord.kinds(assigns.kind))}
        {Kati.Screens.AddByHandRecord.fields(assigns)}
        {Kati.Screens.AddByHandRecord.error(assigns.save_error)}
        {Kati.UI.Sheet.commit("Add to library", :add)}
        <Spacer size={14} />
        {Kati.Screens.AddByHandRecord.card_note()}
        {Kati.Screens.AddByHandRecord.artist_inset(assigns.kind)}
        {Kati.Screens.AddByHandRecord.decision_note()}
      </Column>
      """,
      Kati.Screens.Pushed.content_top()
    )
  end

  @doc """
  The board's own heading, at the board's own numbers.

  Not `Kati.Screens.AddByHand.heading/0`, and the difference is measured rather
  than a matter of taste: board 154 sets its subtitle at 13px over a 7px gap and
  board 178 sets it at 13.5 over 6. `Kati.ScreenTitleSubtitleTest` parses both
  out of the HTML and compares them with what the screen rendered, so sharing
  the function would fail on this screen for a difference the board really has.
  """
  @spec heading() :: map()
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
      <Spacer size={6} />
      <Text
        text="For something Kati could not find. The title is the only thing it needs."
        text_size={13.5}
        line_height={1.6}
        text_color={Palette.sub()}
      />
      <Spacer size={20} />
    </Column>
    """
  end

  @doc "The one required value, relabelled by Kind — `Album` under Album, `Name` under Artist."
  @spec title_label(atom()) :: String.t()
  def title_label(:artist), do: "Name"
  def title_label(_kind), do: "Album"

  @doc false
  @spec title_hint(atom()) :: String.t()
  def title_hint(:artist), do: "Kell Ostrand"
  def title_hint(_kind), do: "e.g. Tidal Works"

  @doc """
  A field, keyed on its own assign name.

  Copied from `Kati.Screens.AddByHand.field/3` rather than called, for one
  reason: the tag it builds must reach THIS screen's `handle_info/2`, and the
  `accessibility_id` must name this screen's field. Calling 154's would build
  `{self(), :title}` in this process — which is right — but would also tie this
  form's trough recipe to 154's, and 178 draws the same trough only because the
  two boards agree today.
  """
  @spec field(atom(), String.t(), String.t()) :: map()
  def field(tag, value, placeholder) do
    assigns = %{
      value: value,
      placeholder: placeholder,
      on_change: {self(), tag},
      id: Atom.to_string(tag)
    }

    ~MOB"""
    <Row
      fill_width={true}
      height={48}
      corner_radius={14}
      background={Palette.card()}
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

  @doc "The five Kind chips, live. This is the control that reveals everything below it."
  @spec kinds(atom()) :: map()
  def kinds(active) do
    ~MOB"""
    <Row fill_width={true} align="center">
      {Enum.map(Kati.Screens.AddByHandRecord.kind_list(), fn {label, kind, icon} ->
        AddByHand.kind_chip(label, icon, kind == active)
      end)
      |> Enum.intersperse(AddByHand.gap())}
    </Row>
    """
  end

  @doc """
  What the chosen Kind reveals: five fields for an album, four for an artist.

  Three of the album's fields drop and two arrive, which is what the inset's
  eyebrow says out loud.
  """
  @spec fields(map()) :: map()
  def fields(%{kind: :artist} = assigns) do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.AddByHandRecord.pair(assigns)}
      {Kati.Screens.AddByHandRecord.following_row(assigns.following, {self(), :toggle_following})}
      <Spacer size={18} />
    </Column>
    """
  end

  def fields(assigns) do
    ~MOB"""
    <Column fill_width={true}>
      {AddByHand.labelled("Artist", Kati.Screens.AddByHandRecord.field(:artist, assigns.artist, "Kell Ostrand"), "optional")}
      {AddByHand.labelled("Released", Kati.Screens.AddByHandRecord.field(:released, assigns.released, "2025"), "optional")}
      {AddByHand.labelled("Tracks", Kati.Screens.AddByHandRecord.field(:tracks, assigns.tracks, "11"), "optional")}
      {AddByHand.labelled("First heard", Kati.Screens.AddByHandRecord.field(:first_heard, assigns.first_heard, "3 Mar 2024"), "optional")}
    </Column>
    """
  end

  @doc "Role and Country, one row and two free-text fields — screen 77 prints them as `Composer · Iceland`."
  @spec pair(map()) :: map()
  def pair(assigns) do
    ~MOB"""
    <Row fill_width={true} align="top">
      <Column weight={1.0}>
        {AddByHand.labelled("Role", Kati.Screens.AddByHandRecord.field(:role, assigns.role, "Composer"), "optional")}
      </Column>
      <Spacer size={10} />
      <Column weight={1.0}>
        {AddByHand.labelled("Country", Kati.Screens.AddByHandRecord.field(:country, assigns.country, "Iceland"), "optional")}
      </Column>
    </Row>
    """
  end

  @doc """
  The same two labels with the values printed rather than typeable.

  The inset's own troughs. A `<TextField>` here would be a second field carrying
  the tag and the `accessibility_id` the live one carries, on a card that is a
  picture of a state — the same mistake in the same place `drawn_kinds/0`
  refuses for the chips.
  """
  @spec drawn_pair() :: map()
  def drawn_pair do
    ~MOB"""
    <Row fill_width={true} align="top">
      <Column weight={1.0}>
        {AddByHand.labelled("Role", Kati.Screens.AddByHandRecord.specimen("Composer"), "optional")}
      </Column>
      <Spacer size={10} />
      <Column weight={1.0}>
        {AddByHand.labelled("Country", Kati.Screens.AddByHandRecord.specimen("Iceland"), "optional")}
      </Column>
    </Row>
    """
  end

  @doc """
  The Following switch, and the sub-line that says exactly what it feeds.

  `Kati.Music.Artist`'s moduledoc is the reason the sub-line is not decoration:
  *premieres stay a separate opt-in so following an artist cannot silently turn
  on push*. The switch drives screen 21's releases band and one of screen 25's
  six alert types, and the row says so rather than leaving a person to find out
  which by being notified.

  `tap` is `nil` in the inset, which `Kati.ScreenTapSweepTest` documents as the
  one value a control can carry that means *not tappable* rather than *broken*.
  """
  @spec following_row(boolean(), {pid(), atom()} | nil) :: map()
  def following_row(on?, tap) do
    assigns = %{on?: on?, tap: tap}

    ~MOB"""
    <Row fill_width={true} align="center" padding_top={13} padding_bottom={13} on_tap={@tap}>
      {SettingsList.icon_tile("notifications")}
      <Spacer size={13} />
      <Column weight={1.0}>
        <Text text="Following" text_size={13.5} font_weight="semibold" text_color={:on_surface} />
        <Spacer size={3} />
        <Text
          text="Feeds 21’s releases band and one of 25’s alert types — no push"
          text_size={11.5}
          line_height={1.4}
          text_color={Palette.sub()}
        />
      </Column>
      <Spacer size={13} />
      {SettingsList.switch(@on?)}
    </Row>
    """
  end

  @doc false
  @spec error(String.t() | nil) :: map()
  def error(nil), do: ~MOB"<Spacer size={0} />"

  def error(message) do
    assigns = %{message: message}

    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.note("error", @message)}
      <Spacer size={14} />
    </Column>
    """
  end

  @doc """
  The quiet note under the button, in five runs.

  Five `<Text>` nodes and not one sentence, for the reason
  `Kati.Screens.AddByHand.split_note/4` gives: the board writes the emphasis as
  its own run, and `Kati.ScreenDesignLiteralTest` compares a drawing's lines
  against the tree's — so a single joined string is a different shape from the
  drawn one even when it reads the same.
  """
  @spec card_note() :: map()
  def card_note do
    ~MOB"""
    <Column fill_width={true}>
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
            text="A record typed by hand carries"
            text_size={12.5}
            line_height={1.65}
            text_color={Palette.ink_soft()}
          />
          <Text
            text="no art and no tracklist"
            text_size={12.5}
            line_height={1.65}
            font_weight="semibold"
            text_color={Palette.ink()}
          />
          <Text
            text="; both arrive if Kati finds it later."
            text_size={12.5}
            line_height={1.65}
            text_color={Palette.ink_soft()}
          />
          <Text
            text="No Status row"
            text_size={12.5}
            line_height={1.65}
            font_weight="semibold"
            text_color={Palette.ink()}
          />
          <Text
            text="— an album is not watched and is never finished, so the five watch statuses are removed rather than translated."
            text_size={12.5}
            line_height={1.65}
            text_color={Palette.ink_soft()}
          />
        </Column>
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc """
  The Artist state, drawn rather than lived — and only while the form is not
  already in it.

  See the moduledoc: nothing here carries a tap, so the chips and the switch are
  pictures of the state the chip row above opens.
  """
  @spec artist_inset(atom()) :: map()
  def artist_inset(:artist), do: ~MOB"<Spacer size={0} />"

  def artist_inset(_kind) do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.Eyebrow.quiet("Artist chosen — three fields drop, two arrive")}
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={17}
      >
        {Kati.Screens.AddByHandRecord.drawn_kinds()}
        <Spacer size={14} />
        {AddByHand.labelled("Name", Kati.Screens.AddByHandRecord.specimen("Kell Ostrand"))}
        {Kati.Screens.AddByHandRecord.drawn_pair()}
        {Kati.Screens.AddByHandRecord.following_row(false, nil)}
      </Column>
      <Spacer size={14} />
    </Column>
    """
  end

  @doc "The chip row as a picture, with Artist lit and no taps on any of it."
  @spec drawn_kinds() :: map()
  def drawn_kinds do
    ~MOB"""
    <Row fill_width={true} align="center">
      {Enum.map(Kati.Screens.AddByHandRecord.kind_list(), fn {label, kind, icon} ->
        Kati.Screens.AddByHandRecord.drawn_chip(label, icon, kind == :artist)
      end)
      |> Enum.intersperse(AddByHand.gap())}
    </Row>
    """
  end

  @doc false
  @spec drawn_chip(String.t(), String.t(), boolean()) :: map()
  def drawn_chip(label, icon, on?) do
    assigns = %{label: label, icon: icon, on?: on?}

    ~MOB"""
    <Row
      height={32}
      corner_radius={16}
      background={if @on?, do: Palette.ink_fill(), else: Palette.card()}
      padding_left={15}
      padding_right={15}
      align="center"
    >
      {UI.symbol(@icon, size: 15, color: if(@on?, do: Palette.on_ink(), else: Palette.sub()))}
      <Spacer size={6} />
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

  @doc "A field trough with a value printed in it and nothing to type into."
  @spec specimen(String.t()) :: map()
  def specimen(value) do
    assigns = %{value: value}

    ~MOB"""
    <Row
      fill_width={true}
      height={44}
      corner_radius={14}
      background={Palette.paper()}
      padding_left={13}
      padding_right={13}
      align="center"
    >
      <Text text={@value} text_size={14} text_color={:on_surface} max_lines={1} />
    </Row>
    """
  end

  @doc "The board's dashed annotation, in the six runs it is drawn in."
  @spec decision_note() :: map()
  def decision_note do
    ~MOB"""
    <Row
      fill_width={true}
      corner_radius={18}
      border_width={1.5}
      border_color={Palette.border()}
      padding={15}
      align="top"
    >
      {UI.symbol("info", size: 17, color: Palette.sub())}
      <Spacer size={11} />
      <Column weight={1.0}>
        <Text
          text="Artist is a Kind, not a field reached only through Album"
          text_size={12.5}
          line_height={1.65}
          font_weight="semibold"
          text_color={Palette.ink()}
        />
        <Text
          text="— the album’s artist is nullable, so an album-only path accumulates records with nobody behind them, and following somebody whose records you do not own yet is a thing people do. Within Album the Artist field still creates one inline, so the common path stays one form."
          text_size={12.5}
          line_height={1.65}
          text_color={Palette.ink_soft()}
        />
        <Text
          text="Tracks is a count"
          text_size={12.5}
          line_height={1.65}
          font_weight="semibold"
          text_color={Palette.ink()}
        />
        <Text
          text=", never eleven rows of 4:12 — a tracklist typed by hand often has names and no timings. First heard is"
          text_size={12.5}
          line_height={1.65}
          text_color={Palette.ink_soft()}
        />
        <Text
          text="stored, not derived"
          text_size={12.5}
          line_height={1.65}
          font_weight="semibold"
          text_color={Palette.ink()}
        />
        <Text
          text=": deriving it would report yesterday for a record somebody has had since 2011."
          text_size={12.5}
          line_height={1.65}
          text_color={Palette.ink_soft()}
        />
      </Column>
    </Row>
    """
  end

  @doc """
  What was typed, in whichever of the six fields.

  One clause rather than six: each `<TextField>` carries its own assign name as
  its change tag, which is the same atom `field/3` puts in `accessibility_id`.

  **The catch-all delegates to `super/2`** — `Kati.Screens.Pushed` marks
  `handle_info/2` overridable and defines four clauses on it, one of which
  routes every `{:tap, tag}` to `handle_tap/2`. Replacing all four is how screen
  88 went unreachable earlier on this branch.
  """
  @impl true
  def handle_info({:change, field, typed}, socket)
      when field in [:title, :artist, :released, :tracks, :first_heard, :role, :country] and
             is_binary(typed),
      do: {:noreply, Mob.Socket.assign(socket, field, typed)}

  def handle_info(message, socket), do: super(message, socket)

  @impl true
  def handle_tap(:add, socket), do: {:noreply, Kati.Screens.AddByHandRecord.save(socket)}

  def handle_tap(:toggle_following, socket),
    do: {:noreply, Mob.Socket.update(socket, :following, &(not &1))}

  # Album and Artist are this form's two states. Film, Series and Book belong to
  # a different write — see the moduledoc — so their chips open the form that
  # owns them rather than pretending this one can file a film.
  def handle_tap(:kind_Album, socket), do: {:noreply, Mob.Socket.assign(socket, :kind, :album)}
  def handle_tap(:kind_Artist, socket), do: {:noreply, Mob.Socket.assign(socket, :kind, :artist)}

  def handle_tap(tag, socket) when tag in [:kind_Film, :kind_Series, :kind_Book],
    do: {:noreply, Mob.Socket.push_screen(socket, AddByHand.for_locale())}

  def handle_tap(_tag, socket), do: {:noreply, socket}

  @doc """
  Write the row, or say why not.

  The refusal is board 155's shape and this form's noun: name what is missing,
  then say **nothing was written**. The button is never disabled, because a dead
  button explains nothing — `Kati.Write`'s contract and `Kati.WriteContractTest`
  hold that on the host.

  Nothing here re-reads a shelf. Every value written is one this page drew and
  the person typed, which is the narrow form rule 2 takes on a form: there is no
  row to act on, so there is no fresh query that could substitute one.
  """
  @spec save(Mob.Socket.t()) :: Mob.Socket.t()
  def save(socket) do
    typed = String.trim(socket.assigns.title)

    cond do
      typed == "" and socket.assigns.kind == :artist ->
        Mob.Socket.assign(socket, :save_error, refusal("A name is the one thing this needs."))

      typed == "" ->
        Mob.Socket.assign(
          socket,
          :save_error,
          refusal("An album title is the one thing this needs.")
        )

      true ->
        commit(socket, typed)
    end
  end

  defp commit(socket, typed) do
    case write(socket.assigns.kind, typed, socket.assigns) do
      {:ok, _record} -> Mob.Socket.pop_screen(socket)
      error -> Mob.Socket.assign(socket, :save_error, Kati.Write.message(error))
    end
  end

  # Board 155's two sentences: what is missing, then that nothing was written.
  defp refusal(what), do: what <> " Nothing was written."

  @doc """
  The write, one clause per Kind.

  An artist is one row. An album is up to three writes and they are ordered so
  that a failure leaves the least behind: the artist first (it may already
  exist), then the album that points at it, then the tracks that point at the
  album. A tracklist that cannot be written does not undo the album — the record
  is the thing the person asked for, and the count is the denominator.
  """
  @spec write(atom(), String.t(), map()) :: {:ok, struct()} | {:error, term()}
  def write(:artist, name, assigns) do
    Artist
    |> Ash.Changeset.for_create(:create, %{
      name: name,
      role: presence(assigns.role),
      country: presence(assigns.country),
      following: assigns.following,
      source: :manual,
      source_id: name
    })
    |> Ash.create()
    |> Kati.Write.note("add artist by hand #{name}")
  end

  def write(_album, title, assigns) do
    with {:ok, artist_id} <- artist_for(assigns.artist),
         {:ok, album} <- create_album(title, artist_id, assigns),
         {:ok, _tracks} <- create_tracks(album, assigns.tracks) do
      {:ok, album}
    end
    |> Kati.Write.note("add album by hand #{title}")
  end

  @doc """
  The artist behind a typed name: the one already stored, or a new one.

  **A typed name that matches nothing creates the artist**, and a typed name
  that matches one REUSES it — matched case-insensitively on the trimmed name,
  because *kell ostrand* and *Kell Ostrand* are one person and filing two rows
  would give screen 77 two pages and screen 21 two follow switches for them.

  Matched in Elixir over one read rather than by a filter, for the reason
  `Kati.Screens.AddTitle.cache/2` gives one domain over: there is no index on a
  case-folded name, and adding one to make a form's lookup prettier is a
  migration this ticket has no need of.

  An empty field answers `{:ok, nil}`. `Kati.Music.Album`'s `artist_id` is
  nullable and the form must not pretend otherwise.
  """
  @spec artist_for(String.t()) :: {:ok, String.t() | nil} | {:error, term()}
  def artist_for(typed) do
    case presence(typed) do
      nil ->
        {:ok, nil}

      name ->
        case existing_artist(name) do
          %Artist{id: id} -> {:ok, id}
          nil -> new_artist(name)
        end
    end
  end

  defp existing_artist(name) do
    folded = String.downcase(name)

    case Ash.read(Artist) do
      {:ok, artists} -> Enum.find(artists, &(String.downcase(&1.name) == folded))
      _other -> nil
    end
  rescue
    _error -> nil
  end

  defp new_artist(name) do
    Artist
    |> Ash.Changeset.for_create(:create, %{name: name, source: :manual, source_id: name})
    |> Ash.create()
    |> case do
      {:ok, artist} -> {:ok, artist.id}
      error -> error
    end
  end

  defp create_album(title, artist_id, assigns) do
    Album
    |> Ash.Changeset.for_create(:create, %{
      title: title,
      artist_id: artist_id,
      released_year: year(assigns.released),
      first_heard_on: Kati.Screens.AddByHandRecord.parse_date(assigns.first_heard),
      source: :manual,
      source_id: title
    })
    |> Ash.create()
  end

  # Nothing typed is no tracklist at all, which is a real state of a record
  # somebody has just remembered they own.
  defp create_tracks(_album, ""), do: {:ok, []}

  defp create_tracks(album, typed) do
    case count(typed) do
      nil ->
        {:ok, []}

      n ->
        Enum.reduce_while(1..n, {:ok, []}, fn position, {:ok, made} ->
          case create_track(album, position) do
            {:ok, track} -> {:cont, {:ok, [track | made]}}
            error -> {:halt, error}
          end
        end)
    end
  end

  defp create_track(album, position) do
    Track
    |> Ash.Changeset.for_create(:create, %{
      album_id: album.id,
      position: position,
      title: "Track #{position}"
    })
    |> Ash.create()
  end

  # A year is four digits or it is nothing. `1984` is a year; `nineteen
  # eighty-four` is a sentence, and storing `nil` for it is better than storing
  # a number nobody typed.
  defp year(typed) do
    case Integer.parse(String.trim(typed)) do
      {value, ""} when value > 0 and value < 3000 -> value
      _other -> nil
    end
  end

  # A count is a positive whole number, capped at the longest running order
  # anyone would type by hand. The cap is not taste: each track is a row, and a
  # slipped keystroke of `1100` would write eleven hundred of them.
  defp count(typed) do
    case Integer.parse(String.trim(typed)) do
      {value, ""} when value > 0 and value <= 200 -> value
      _other -> nil
    end
  end

  @doc """
  `3 Mar 2024`, or nothing.

  The board writes the date the way screen 74 prints it, so that is the form
  this parses; an ISO date is accepted too because a keyboard offers one and
  refusing it would be pedantry. Anything else is `nil` rather than a guess —
  `Kati.Music.Album.first_heard_on` is nullable and *stored, not derived*, so
  the honest answer to an unparseable date is that it was not recorded.

      iex> Kati.Screens.AddByHandRecord.parse_date("3 Mar 2024")
      ~D[2024-03-03]

      iex> Kati.Screens.AddByHandRecord.parse_date("2024-03-03")
      ~D[2024-03-03]

      iex> Kati.Screens.AddByHandRecord.parse_date("some time in the nineties")
      nil
  """
  @spec parse_date(String.t()) :: Date.t() | nil
  def parse_date(typed) do
    trimmed = String.trim(typed)

    case Date.from_iso8601(trimmed) do
      {:ok, date} -> date
      _error -> from_long(trimmed)
    end
  end

  @months ~w(jan feb mar apr may jun jul aug sep oct nov dec)

  defp from_long(text) do
    with [day, month, year] <- String.split(text, " ", trim: true),
         {day, ""} <- Integer.parse(day),
         index when is_integer(index) <-
           Enum.find_index(@months, &(&1 == month |> String.downcase() |> String.slice(0, 3))),
         {year, ""} <- Integer.parse(year),
         {:ok, date} <- Date.new(year, index + 1, day) do
      date
    else
      _other -> nil
    end
  end

  defp presence(value) when is_binary(value) do
    case String.trim(value) do
      "" -> nil
      trimmed -> trimmed
    end
  end

  defp presence(_value), do: nil
end
