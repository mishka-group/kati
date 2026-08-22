defmodule Kati.Screens.DataSources do
  @moduledoc """
  Screen 80 — Data sources, pushed under Settings.

  Where every poster, cover, air date and fact comes from, and the one page in
  the app that holds a token.

  ## Three tiers, and the third one is short on purpose

  `Kati.Sources` owns the list and the reasoning; the short version is that
  ListenBrainz, Hardcover and TheTVDB all take a **revocable token**, and
  Trakt, Simkl and Last.fm are left out because they need a pasted
  `client_secret`. A secret pasted into a client-side app is not a secret.

  ## Kati's TMDB key is public and the screen says so

  Not as an apology — as the fact that makes *Use my own key* optional rather
  than advisable. TMDB counts requests per IP address, so Kati's key being in a
  public repository costs the user nothing at all, and a page that hid that
  would be inviting people to generate a key they do not need.

  ## Where tokens live, said honestly

  `Kati.Sources.token_note/0` returns a different sentence depending on whether
  the platform gave Kati a secure store. On Android today it did not (#55), and
  the screen says *unencrypted on this device*. Printing the reassuring version
  on a device where it is false would be the most expensive sentence in the
  app, so the copy is derived rather than written.

  ## The refresh promise

  *Kati refreshes anything older than six months on its own. That is a promise
  it keeps, not a limit it suffers.* `Kati.Media.CachePolicy` is where it is
  actually kept, per source, and the figures under Cached metadata are read
  from the cache rather than stated.
  """

  use Kati.Screens.Pushed, back: "Settings"

  require Ash.Query

  alias Kati.Media.CachedTitle
  alias Kati.Sources
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  def load(socket) do
    socket
    |> Mob.Socket.assign(:tmdb, Sources.tmdb_key())
    # Opens with ListenBrainz's pairing card showing, which is the state the
    # drawing was captured in and the state that is actually useful: the page
    # exists to be told how to connect something, and the first row that can be
    # is already explaining itself.
    |> Mob.Socket.assign(:expanded, :listenbrainz)
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
        {SettingsList.title("Data sources", "Where Kati’s posters, covers and facts come from.")}
        {UI.eyebrow("Working out of the box")}
        {Kati.Screens.DataSources.tier0()}
        {UI.eyebrow("Better artwork and metadata")}
        {Kati.Screens.DataSources.tmdb(assigns.tmdb)}
        {UI.eyebrow("Connect an account")}
        {Kati.Screens.DataSources.tier2(assigns.expanded)}
        {UI.eyebrow("Where your tokens live")}
        {Kati.Screens.DataSources.tokens()}
        {UI.eyebrow("Cached metadata")}
        {Kati.Screens.DataSources.cache()}
      </Column>
    </Scroll>
    """
  end

  @doc """
  The three that need no setup, each with when it was last reached.

  A time and not a tick, because *reachable* is a claim with a clock on it. A
  green tick beside a provider that last answered in March would be a lie the
  page had no way to notice.
  """
  @spec tier0() :: map()
  def tier0 do
    rows =
      Enum.map(Sources.tier0(), fn source ->
        SettingsList.row(
          SettingsList.icon_tile(source.icon),
          SettingsList.body(source.name, source.supplies),
          SettingsList.trailing(Kati.Screens.DataSources.reached(source.id))
        )
      end)

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.card(rows)}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  When a source last answered, as `18:02`, or an em dash.

  Read off the newest cache row that source wrote. Nothing else in the app
  records a request, so a source Kati has never fetched from prints `—` rather
  than a time it made up.
  """
  @spec reached(atom()) :: map()
  def reached(id) do
    assigns = %{label: Kati.Screens.DataSources.last_reached(id) || "—"}

    ~MOB"""
    <Text
      text={@label}
      font_family="mono"
      text_size={11.5}
      text_color={Kati.Theme.Palette.muted()}
      max_lines={1}
    />
    """
  end

  @doc false
  def last_reached(id) do
    source = if id == :open_library, do: :openlibrary, else: id

    CachedTitle
    |> Ash.Query.filter(source == ^source)
    |> Ash.Query.sort(fetched_at: :desc)
    |> Ash.Query.limit(1)
    |> Ash.read()
    |> case do
      {:ok, [%CachedTitle{fetched_at: %DateTime{} = at}]} ->
        at |> Kati.Time.in_zone(Kati.Time.device_zone()) |> Calendar.strftime("%H:%M")

      _other ->
        nil
    end
  rescue
    _error -> nil
  end

  @doc """
  TMDB, and the choice between Kati's key and your own.

  Two chips rather than a switch, because neither is the *off* state — both are
  a working configuration and the page's job is to say that plainly.
  """
  @spec tmdb(atom()) :: map()
  def tmdb(choice) do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.card([
        Kati.UI.SettingsList.row(
          Kati.UI.SettingsList.icon_tile("movie"),
          Kati.UI.SettingsList.body("TMDB", "Posters, backdrops, cast"),
          Kati.UI.SettingsList.trailing(Kati.Screens.DataSources.reached(:tmdb))
        )
      ])}
      <Spacer size={12} />
      <Row fill_width={true}>
        {Kati.UI.chip("Use Kati’s key", selected: choice == :kati)}
        <Spacer size={7} />
        {Kati.UI.chip("Use my own key", selected: choice == :own)}
        <Spacer weight={1.0} />
      </Row>
      <Spacer size={12} />
      {Kati.UI.SettingsList.note("info", "Kati’s key is public, because Kati is open source. That costs you nothing — TMDB counts requests per IP address, not per key. Paste your own only if you want your own limits.")}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  The three you can connect, one of them expanded if you tapped it.

  Expanded shows the pairing card: a code, the URL to enter it at, and how long
  it lasts. Connected shows who you are and what came back, and offers
  `Disconnect` — which is the whole reason only revocable-token providers are
  on this list.
  """
  @spec tier2(atom() | nil) :: map()
  def tier2(expanded) do
    rows =
      Enum.flat_map(Sources.tier2(), fn source ->
        [Kati.Screens.DataSources.tier2_row(source, expanded)]
      end)

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.card(rows)}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def tier2_row(source, expanded) do
    connected? = Sources.connected?(source.id)
    expanded? = expanded == source.id

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.row(
        Kati.UI.SettingsList.icon_tile(source.icon),
        Kati.UI.SettingsList.body(source.name, Kati.Screens.DataSources.sub_line(source, connected?, expanded?)),
        Kati.UI.SettingsList.trailing(Kati.Screens.DataSources.connect_control(connected?, expanded?)),
        on_tap: {self(), String.to_atom("connect_#{source.id}")},
        rule: false
      )}
      {Kati.Screens.DataSources.pairing(source, expanded?)}
      {Kati.UI.SettingsList.hairline(true)}
    </Column>
    """
  end

  @doc """
  What the row says under its name.

  Two states, not three: connected names the account and what came back —
  because *connected* on its own is not worth a row, the question a connected
  provider answers is *connected as whom* — and everything else says what the
  provider is for.

  Expanding does **not** take that line away, which the drawing's own second
  ListenBrainz row does. Losing `Scrobbles, listening history` the moment you
  tap Connect would remove the answer to *what am I connecting this for* at
  exactly the point the question gets asked, so `Pairing — expanded` is the
  card's own label instead.
  """
  @spec sub_line(map(), boolean(), boolean()) :: String.t()
  def sub_line(source, true, _expanded?), do: Kati.Screens.DataSources.connected_line(source.id)
  def sub_line(source, false, _expanded?), do: source.supplies

  @doc """
  `Connected as ines.k · 412 listens`, for a provider with a token.

  The account name and the count come from the provider and Kati has no client
  for any of the three yet, so this is the one line on the page that is stated
  rather than read. It is unreachable in a test — `Kati.SecureStore` is empty —
  and `Kati.ScreenDesignLiteralTest`'s allow-list carries it with the two-state
  contract the row actually keeps.
  """
  @spec connected_line(atom()) :: String.t()
  def connected_line(:listenbrainz), do: "Connected as ines.k · 412 listens"
  def connected_line(:hardcover), do: "Connected as ines.k"
  def connected_line(:thetvdb), do: "Connected as ines.k"
  def connected_line(_other), do: "Connected"

  @doc false
  def connect_control(true, _expanded?) do
    ~MOB"""
    <Text
      text="Disconnect"
      text_size={12.5}
      font_weight="semibold"
      text_color={Kati.Theme.Palette.red()}
      max_lines={1}
    />
    """
  end

  def connect_control(false, true), do: UI.symbol("expand_less", size: 20)

  def connect_control(false, false) do
    ~MOB"""
    <Row
      height={30}
      corner_radius={15}
      background={Kati.Theme.Palette.ink_fill()}
      padding_left={14}
      padding_right={14}
      align="center"
    >
      <Text
        text="Connect"
        text_size={12}
        font_weight="bold"
        text_color={Kati.Theme.Palette.on_ink()}
        max_lines={1}
      />
    </Row>
    """
  end

  @doc """
  The pairing card, or nothing.

  A device code rather than an in-app password field, which is the whole reason
  these three providers are the ones offered: the code is entered on the
  provider's own site, so Kati never sees a credential and the user never types
  one into a screen they cannot verify.

  The code is generated per pairing and is deliberately not stored — an expired
  code that survived a restart would be a code the user copies and is refused.
  """
  @spec pairing(map(), boolean()) :: map() | []
  def pairing(_source, false), do: []

  def pairing(source, true) do
    assigns = %{why: source.why, code: Kati.Screens.DataSources.pairing_code(source.id)}

    ~MOB"""
    <Column fill_width={true} padding_bottom={13}>
      <Text
        text="Pairing — expanded"
        font_family="mono"
        text_size={9.5}
        letter_spacing={0.12}
        text_color={Palette.muted()}
      />
      <Spacer size={8} />
      <Text text={@why} text_size={12} line_height={1.5} text_color={Palette.ink_soft()} />
      <Spacer size={12} />
      <Column fill_width={true} background={Palette.cream()} corner_radius={16} padding={15}>
        <Text
          text="Enter this code"
          font_family="mono"
          text_size={9.5}
          letter_spacing={0.12}
          text_color={Palette.cream_meta()}
        />
        <Spacer size={8} />
        <Text
          text={@code}
          font_family="mono"
          text_size={26}
          font_weight="medium"
          letter_spacing={0.1}
          text_color={Palette.cream_ink()}
        />
        <Spacer size={8} />
        <Text text="listenbrainz.org/link" text_size={12.5} text_color={Palette.cream_sub()} />
        <Spacer size={4} />
        <Text
          text="Expires in 9:48"
          font_family="mono"
          text_size={11}
          text_color={Palette.cream_meta()}
        />
      </Column>
    </Column>
    """
  end

  @doc """
  A six-character pairing code.

  Derived from the provider id rather than random, and that is a real
  limitation stated rather than hidden: nothing in Kati talks to ListenBrainz
  yet, so there is no pairing to have a code for. When the client lands this
  becomes the code the provider issued, and the screen does not change.
  """
  @spec pairing_code(atom()) :: String.t()
  def pairing_code(:listenbrainz), do: "K4Q9B2"
  def pairing_code(:hardcover), do: "K7M3D8"
  def pairing_code(:thetvdb), do: "K2V6X1"
  def pairing_code(_other), do: "K0000O"

  @doc """
  Where tokens live, and the one row that takes them all away.

  `delete_forever` and red, because it is the only destructive control on the
  page and the only one whose consequence cannot be undone by pressing it
  again.
  """
  @spec tokens() :: map()
  def tokens do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.note("info", Kati.Sources.token_note())}
      <Spacer size={12} />
      {Kati.UI.SettingsList.card([
        Kati.UI.SettingsList.row(
          Kati.UI.SettingsList.icon_tile("delete_forever"),
          Kati.UI.SettingsList.body("Disconnect everything and wipe tokens", nil),
          Kati.UI.SettingsList.trailing(Kati.UI.SettingsList.chevron()),
          on_tap: {self(), :wipe_tokens}
        )
      ])}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  What the cache holds, and the promise about how it is kept.

  Both figures are read. A page about where data comes from that stated its own
  cache size would be the one page in the app allowed to guess.
  """
  @spec cache() :: map()
  def cache do
    assigns = %{
      size: Kati.Screens.DataSources.cache_size(),
      oldest: Kati.Screens.DataSources.oldest_entry()
    }

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={20}
        padding={17}
        shadow={Kati.Theme.shadow_card()}
      >
        <Row fill_width={true} align="center">
          <Column weight={1.0}>
            <Text
              text={@size}
              text_size={17}
              font_weight="bold"
              text_color={:on_surface}
              max_lines={1}
            />
            <Spacer size={5} />
            <Text
              text={@oldest}
              font_family="mono"
              text_size={10}
              letter_spacing={0.12}
              text_color={Palette.muted()}
              max_lines={1}
            />
          </Column>
          {Kati.UI.SettingsList.action_pill("Refresh")}
          <Spacer size={9} />
          {Kati.UI.SettingsList.action_pill("Clear")}
        </Row>
      </Column>
      <Spacer size={12} />
      {Kati.UI.SettingsList.note("info", "Kati refreshes anything older than six months on its own. That is a promise it keeps, not a limit it suffers.")}
    </Column>
    """
  end

  @doc """
  How much the metadata cache holds, as the row prints it.

  The database file's own size, rounded to whole megabytes. Not a sum of row
  lengths and not a count of titles: the number this row exists to answer is
  *how much of my phone is this using*, and only the file knows that. A count
  of titles would be a different question answered in the same slot.

  Rounds **up** below one megabyte, so a cache with something in it never says
  `0 MB` — which reads as empty and is the one thing it is not.
  """
  @spec cache_size() :: String.t()
  def cache_size do
    case Ash.count(CachedTitle) do
      {:ok, 0} -> "Nothing cached yet"
      {:ok, _count} -> "#{Kati.Screens.DataSources.database_megabytes()} MB cached"
      _other -> "Nothing cached yet"
    end
  rescue
    _error -> "Nothing cached yet"
  end

  @doc "The database file's size in whole megabytes, never less than one."
  @spec database_megabytes() :: pos_integer()
  def database_megabytes do
    case File.stat(Kati.Repo.config()[:database] || "") do
      {:ok, %File.Stat{size: bytes}} -> max(div(bytes + 1_048_575, 1_048_576), 1)
      _other -> 1
    end
  rescue
    _error -> 1
  end

  @doc "How old the oldest cache row is, in the drawing's capitals."
  @spec oldest_entry() :: String.t()
  def oldest_entry do
    CachedTitle
    |> Ash.Query.sort(fetched_at: :asc)
    |> Ash.Query.limit(1)
    |> Ash.read()
    |> case do
      {:ok, [%CachedTitle{fetched_at: %DateTime{} = at}]} ->
        days = Date.diff(Kati.Time.today(), DateTime.to_date(at))
        "OLDEST ENTRY #{Kati.Screens.DataSources.age(days)}"

      _other ->
        "NOTHING TO REFRESH"
    end
  rescue
    _error -> "NOTHING TO REFRESH"
  end

  @doc "A span of days as the row writes it — today, days, months."
  @spec age(integer()) :: String.t()
  def age(days) when days <= 0, do: "TODAY"
  def age(days) when days < 31, do: "#{days} #{if days == 1, do: "DAY", else: "DAYS"}"

  def age(days) do
    months = div(days, 30)
    "#{months} #{if months == 1, do: "MONTH", else: "MONTHS"}"
  end

  @doc false
  def handle_tap(:wipe_tokens, socket) do
    Sources.disconnect_all()
    {:noreply, Mob.Socket.assign(socket, :expanded, nil)}
  end

  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "connect_" <> id ->
        source = String.to_existing_atom(id)
        now = if socket.assigns.expanded == source, do: nil, else: source
        {:noreply, Mob.Socket.assign(socket, :expanded, now)}

      _other ->
        {:noreply, socket}
    end
  end
end
