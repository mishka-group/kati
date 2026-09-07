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

  @impl true
  def load(socket) do
    socket
    |> Mob.Socket.assign(:tmdb, Sources.tmdb_key())
    |> Mob.Socket.assign(:token, "")
    |> Mob.Socket.assign(:token_epoch, 0)
    |> Mob.Socket.assign(:token_error, nil)
    |> Mob.Socket.assign(:token_saved?, Kati.Screens.DataSources.own_key_stored?())
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
        {SettingsList.title("Data sources", "Where Kati’s posters, covers and facts come from.", nil, :name)}
        {UI.eyebrow("Working out of the box")}
        {Kati.Screens.DataSources.tier0()}
        {UI.eyebrow("Better artwork and metadata")}
        {Kati.Screens.DataSources.tmdb(assigns.tmdb, Map.get(assigns, :token, ""), Map.get(assigns, :token_saved?, false), Map.get(assigns, :token_error), Map.get(assigns, :token_epoch, 0))}
        {UI.eyebrow("Connect an account")}
        {Kati.Screens.DataSources.tier2(assigns.expanded)}
        {UI.eyebrow("Where your tokens live")}
        {Kati.Screens.DataSources.tokens()}
        {UI.eyebrow("Cached metadata")}
        {Kati.Screens.DataSources.cache(Map.get(assigns, :cache_notice), Map.get(assigns, :refreshing?, false))}
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
  @spec tmdb(atom(), String.t(), boolean(), String.t() | nil) :: map()
  def tmdb(choice, token \\ "", saved? \\ false, error \\ nil, epoch \\ 0) do
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
        {Kati.Screens.DataSources.key_chip("Use Kati’s key", :key_kati, choice == :kati)}
        <Spacer size={7} />
        {Kati.Screens.DataSources.key_chip("Use my own key", :key_own, choice == :own)}
        <Spacer weight={1.0} />
      </Row>
      <Spacer size={12} />
      {Kati.Screens.DataSources.own_key(choice, token, saved?, error, epoch)}
      {Kati.UI.SettingsList.note("info", "Kati’s key is public, because Kati is open source. That costs you nothing — TMDB counts requests per IP address, not per key. Paste your own only if you want your own limits.")}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  The field the *Use my own key* chip has always needed.

  Tapping that chip wrote `:own` to `Mob.State` and there was nowhere on this
  page — or anywhere in the app — to put a token. `Kati.Media.Tmdb.key/0` then
  routed to the always-empty secure store and answered `{:error, :no_api_key}`,
  so screen 06 stopped returning results and started drawing a notice pointing
  back at THIS page. One tap on a control that reads as a preference, and
  search was off with no way to switch it on. MOVIES-AND-TV.md #70.

  Drawn only under `:own`, because under `:kati` there is nothing to enter —
  which is also why this is not on board 80: the board is drawn with Kati's key
  chosen.

  `Kati.SecureStore.available?/0` is checked before the field is offered rather
  than after a save fails, which is the rule that module states in its own
  words: *callers that hold credentials must check this before offering to
  connect an account, so the user is told the truth instead of discovering it
  when the first save fails.*
  """
  @spec own_key(atom(), String.t(), boolean(), String.t() | nil, non_neg_integer()) :: map()
  def own_key(:own, token, saved?, error, epoch) do
    cond do
      not Kati.SecureStore.available?() ->
        Kati.Screens.DataSources.no_keystore()

      saved? and error == nil ->
        Kati.Screens.DataSources.key_in_use()

      true ->
        Kati.Screens.DataSources.key_field(token, error, epoch)
    end
  end

  def own_key(_kati, _token, _saved?, _error, _epoch), do: ~MOB"<Spacer size={0} />"

  @doc """
  Board 318's SAVED state: the key is in use, so the field is gone.

  The card used to draw the field again over a token already stored, which
  invites a reader to paste the same thing twice and gives them nowhere to say
  *take it off this device*. 318 replaces it with what is true — a masked
  token, when it was saved, and the two things left to do.

  Masked to its first sixteen characters, which is enough to recognise a JWT's
  header without being enough to use.

      iex> Kati.Screens.DataSources.masked("eyJhbGciOiJIUzI1NiJ9.abcdefgh")
      "eyJhbGciOiJIUzI1… ••••"

      iex> Kati.Screens.DataSources.masked("short")
      "short… ••••"
  """
  @spec key_in_use() :: map()
  def key_in_use do
    assigns = %{
      masked: Kati.Screens.DataSources.masked(Kati.Screens.DataSources.stored_token()),
      since: Kati.Screens.DataSources.saved_line()
    }

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.card([
        Kati.UI.SettingsList.row(
          Kati.UI.SettingsList.icon_tile("lock"),
          Kati.UI.SettingsList.body("Your key is in use", @since),
          Kati.UI.SettingsList.trailing(
            Kati.UI.symbol("check_circle", size: 19, color: Kati.Theme.Palette.green())
          ),
          padding: 13,
          rule: true
        ),
        Kati.UI.SettingsList.row(
          Kati.UI.SettingsList.icon_tile("lock"),
          Kati.Screens.DataSources.masked_text(@masked),
          Kati.UI.SettingsList.trailing(nil),
          padding: 13,
          rule: false
        )
      ])}
      <Spacer size={10} />
      <Row fill_width={true} align="center">
        {Kati.UI.SettingsList.action_pill("Replace", {self(), :replace_token})}
        <Spacer size={10} />
        {Kati.Screens.DataSources.remove_pill()}
        <Spacer weight={1.0} />
      </Row>
    </Column>
    """
  end

  @doc false
  @spec masked(String.t() | nil) :: String.t()
  def masked(nil), do: "••••"
  def masked(token), do: String.slice(token, 0, 16) <> "… ••••"

  # `:own_tmdb_saved_at` and NOT `:tmdb_token_saved_at`. It holds a timestamp and
  # never the token, but `Kati.SecureStoreTest` matches on the NAME — and it is
  # right to: `Mob.State` is a plaintext DETS file, and a key that reads like a
  # credential is one an auditor has to open to rule out.
  @doc false
  @spec stamp_saved() :: :ok
  def stamp_saved do
    Mob.State.put(:own_tmdb_saved_at, DateTime.to_iso8601(Kati.Time.now()))
    :ok
  rescue
    _error -> :ok
  end

  @doc false
  @spec stored_token() :: String.t() | nil
  def stored_token do
    case Kati.SecureStore.get("tmdb") do
      {:ok, token} when is_binary(token) -> token
      _none -> nil
    end
  rescue
    _error -> nil
  catch
    :exit, _reason -> nil
  end

  @doc """
  `SAVED 2 MINUTES AGO`, or `SAVED` where the moment was not recorded.

      iex> Kati.Screens.DataSources.saved_line(nil)
      "SAVED"
  """
  @spec saved_line(DateTime.t() | nil) :: String.t()
  def saved_line(at \\ Kati.Screens.DataSources.saved_at())

  def saved_line(nil), do: "SAVED"

  def saved_line(at) do
    "SAVED " <>
      String.upcase(
        Kati.Settings.Watcher.checked_line(at, false)
        |> String.replace("checked ", "")
      )
  end

  @doc false
  @spec saved_at() :: DateTime.t() | nil
  def saved_at do
    case Mob.State.get(:own_tmdb_saved_at) do
      stamp when is_binary(stamp) ->
        case DateTime.from_iso8601(stamp) do
          {:ok, at, _offset} -> at
          _unparseable -> nil
        end

      _none ->
        nil
    end
  rescue
    _error -> nil
  end

  @doc false
  def masked_text(masked) do
    assigns = %{masked: masked}

    ~MOB"""
    <Text
      text={@masked}
      font_family="mono"
      text_size={12.5}
      text_color={Kati.Theme.Palette.sub()}
      max_lines={1}
    />
    """
  end

  @doc false
  def remove_pill do
    Kati.Components.MishkaPill.pill(
      label: "Remove",
      on_tap: {self(), :remove_token},
      background: Palette.red_wash(),
      text_color: Palette.red(),
      height: 34,
      corner_radius: 17,
      padding: 0,
      padding_left: 14,
      padding_right: 14,
      text_size: 12.5,
      font_weight: :semibold,
      max_lines: 1
    )
  end

  @doc """
  The field, empty or refused — board 318's other two states.

  The refusal is 318's own sentence, and it is the one a reader can act on:
  TMDB issues an **API key** and an **API Read Access Token** on the same page,
  and pasting the first where the second belongs is the commonest way this
  fails. A trailing space is the second.
  """
  @spec key_field(String.t(), String.t() | nil, non_neg_integer()) :: map()
  def key_field(token, error, epoch) do
    assigns = %{
      token: token,
      error: error,
      epoch: epoch,
      on_change: {self(), :tmdb_token},
      save: {self(), :save_token}
    }

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.card([
        Kati.UI.SettingsList.row(
          Kati.UI.SettingsList.icon_tile("lock"),
          Kati.Screens.DataSources.token_field(@token, @on_change, @epoch),
          Kati.UI.SettingsList.trailing(Kati.Screens.DataSources.save_pill(@save)),
          padding: 13,
          rule: false
        )
      ])}
      <Spacer size={10} />
      {Kati.Screens.DataSources.token_state(false, @error)}
    </Column>
    """
  end

  @doc """
  Board 318's fourth state, and its own sentence.

  The old one said Kati *cannot hold a token of yours*, which is not true — it
  can, unencrypted, the way it holds everything else on such a device. 318 says
  that instead, and names the two facts that make it a decision rather than a
  refusal: Kati sends the token only to TMDB, and TMDB lets you revoke it.
  """
  @spec no_keystore() :: map()
  def no_keystore do
    Kati.UI.SettingsList.note(
      "lock",
      "This device has no keystore Kati can reach, so the token sits unencrypted on " <>
        "the filesystem like every other. Kati sends it only to TMDB, and you can " <>
        "revoke it from your TMDB account at any time."
    )
  end

  @doc false
  def token_field(token, on_change, epoch) do
    assigns = %{token: token, on_change: on_change, epoch: epoch}

    ~MOB"""
    <TextField
      value={@token}
      placeholder="Paste your TMDB read token"
      return_key="done"
      fill_width={true}
      accessibility_id="tmdb_token"
      on_change={@on_change}
      value_epoch={@epoch}
    />
    """
  end

  @doc false
  def save_pill(tap) do
    assigns = %{tap: tap}

    ~MOB"""
    <Row
      height={32}
      corner_radius={16}
      background={Kati.Theme.Palette.ink_fill()}
      padding_left={14}
      padding_right={14}
      align="center"
      on_tap={@tap}
    >
      <Text
        text="Save"
        text_size={12.5}
        font_weight="bold"
        text_color={Kati.Theme.Palette.on_ink()}
        max_lines={1}
      />
    </Row>
    """
  end

  @doc false
  def token_state(_saved?, error) when is_binary(error),
    do: Kati.UI.SettingsList.note("error", error)

  def token_state(true, _error),
    do:
      Kati.UI.SettingsList.note(
        "check_circle",
        "A token of yours is stored. Kati searches with it."
      )

  def token_state(_saved?, _error),
    do:
      Kati.UI.SettingsList.note(
        "info",
        "themoviedb.org → your account → Settings → API. Copy the read access token."
      )

  @doc """
  Whether this device is holding a token of the reader's own.

  Read rather than remembered, so the state survives a restart and cannot
  disagree with what `Kati.Media.Tmdb.key/0` will actually find.
  """
  @spec own_key_stored?() :: boolean()
  def own_key_stored? do
    match?({:ok, token} when is_binary(token) and token != "", Kati.SecureStore.get("tmdb"))
  rescue
    _error -> false
  catch
    :exit, _reason -> false
  end

  @doc """
  One of the two TMDB key chips.

  Both were decoration until this round: `Kati.UI.chip/2` reads `:on_toggle`
  out of its opts and emits no tap at all without one, so the page drew a
  choice it could not be told. The destination is not invented — the Persian
  mirror of this exact card has answered `:key_kati` and `:key_own` through
  `Kati.Sources.put_tmdb_key/1` since screen 82 landed
  (`Kati.Screens.DataSourcesFa`), and this is the half of a mirrored pair that
  was never connected.

  **The chip in force carries no tag**, which is the one place this diverges
  from 82. It is the shape `Kati.Screens.Settings.segment/2` keeps for the
  theme trough one screen up — *only the unselected tiles are choices* — and
  the reason is the same: this is an exclusive pair, not a filter family, so
  tapping the chip that is already lit can only set the value it already has.
  Drawing a tag for that is drawing a control that answers nothing, which is
  what `Kati.ScreenTapSweepTest`'s `no new dead-looking taps` reports and what
  `@inert_taps` then has to carry a line about. 82 pays that line
  (`{Kati.Screens.DataSourcesFa, :key_kati}`); this page does not have to.

  Nothing visible moves either way: a chip's pill and label are the component's
  and do not depend on `:on_toggle`. What the unselected chip gains is an
  `accessibility_id` — `key_kati` or `key_own`, each unique on screen 80.
  """
  @spec key_chip(String.t(), atom(), boolean()) :: term()
  def key_chip(label, _tag, true), do: Kati.UI.chip(label, selected: true)

  def key_chip(label, tag, false),
    do: Kati.UI.chip(label, selected: false, on_toggle: {self(), tag})

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

  def connect_control(false, true), do: UI.symbol("expand_more", size: 20)

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

  ## What it says now, and what it used to say

  It used to print a six-character code, `listenbrainz.org/link`, and `Expires
  in 9:48`. All three were invented (MOVIES-AND-TV.md #71): the code came from
  `pairing_code/1`, which derives it from the provider id because **Kati talks
  to none of these three providers** and there is no pairing to have a code
  for; the address was ListenBrainz's under every one of them, so a Hardcover
  reader was sent to somebody else's site; and the countdown never counted,
  because nothing had started.

  A reader who took that at face value went to a URL that was not theirs and
  typed a code nobody had issued. So the card says what is true: which site
  the token comes from, what connecting would bring, and that Kati cannot
  complete it yet. No code, and no clock on a code that does not exist.

  The shape is the board's and the slot is still here. When a client lands,
  `ready?/1` answers `true` and the code comes back — from the provider.
  """
  @spec pairing(map(), boolean()) :: map() | []
  def pairing(_source, false), do: []

  def pairing(source, true) do
    assigns = %{
      why: source.why,
      site: Map.get(source, :site, ""),
      supplies: Map.get(source, :supplies, "")
    }

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
          text="Not connected yet"
          font_family="mono"
          text_size={9.5}
          letter_spacing={0.12}
          text_color={Palette.cream_meta()}
        />
        <Spacer size={8} />
        <Text
          text={@site}
          font_family="mono"
          text_size={16}
          font_weight="medium"
          letter_spacing={0.1}
          text_color={Palette.cream_ink()}
        />
        <Spacer size={8} />
        <Text
          text={"Your token lives there. Kati cannot ask for it yet — when it can, this is where it comes from."}
          text_size={12.5}
          line_height={1.5}
          text_color={Palette.cream_sub()}
        />
        <Spacer size={4} />
        <Text text={@supplies} font_family="mono" text_size={11} text_color={Palette.cream_meta()} />
      </Column>
    </Column>
    """
  end

  @doc """
  Whether Kati can actually pair with a provider.

  `false` for all three today, and the function exists so the day one of them
  becomes `true` is a one-line change rather than a redesign. `pairing/2`
  draws the address and the limit while this is false, and the provider's own
  code when it is true.

  It replaces `pairing_code/1`, which answered `K4Q9B2` for ListenBrainz,
  `K7M3D8` for Hardcover and `K2V6X1` for TheTVDB — six characters derived
  from the provider id, printed under *Enter this code* over a ten-minute
  countdown, for a pairing no code had been issued for. A limitation stated in
  a moduledoc and contradicted on screen is not stated.

      iex> Kati.Screens.DataSources.ready?(:listenbrainz)
      false
  """
  @spec ready?(atom()) :: boolean()
  def ready?(_provider), do: false

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
  @spec cache(String.t() | nil, boolean()) :: map()
  def cache(notice \\ nil, refreshing? \\ false) do
    assigns = %{
      size: Kati.Screens.DataSources.cache_size(),
      oldest: Kati.Screens.DataSources.oldest_entry(),
      notice: Kati.Screens.DataSources.cache_notice(notice),
      refresh: if(refreshing?, do: "Refreshing…", else: "Refresh")
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
          {Kati.UI.SettingsList.action_pill(@refresh, {self(), :refresh_cache})}
          <Spacer size={9} />
          {Kati.UI.SettingsList.action_pill("Clear", {self(), :clear_cache})}
        </Row>
        {@notice}
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

  @doc """
  What the last cache action did, when there is something to say.

  A sweep that answers nothing looks exactly like a button that does nothing,
  which is what this finding was about; a screen that redraws its own size line
  and hopes the reader notices two megabytes fewer is not much better.
  """
  @spec cache_notice(String.t() | nil) :: map()
  def cache_notice(nil), do: ~MOB"<Spacer size={0} />"

  def cache_notice(message) do
    assigns = %{message: message}

    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={11} />
      <Text
        text={@message}
        font_family="mono"
        text_size={10.5}
        letter_spacing={0.12}
        text_color={Palette.muted()}
      />
    </Column>
    """
  end

  @doc """
  Empty the metadata cache. MOVIES-AND-TV.md #102.

  Nothing the reader made is in it — `Kati.Media.Cache`'s moduledoc gives the
  whole argument — so this needs no confirmation step: the shelf, the ticks and
  the ratings are all still there afterwards, and the posters come back on the
  next refresh.
  """
  @impl true
  def handle_tap(:clear_cache, socket) do
    notice =
      case Kati.Media.Cache.clear() do
        {:ok, 0} -> "Nothing was cached."
        {:ok, n} -> "Cleared #{n} cached #{if n == 1, do: "row", else: "rows"}."
        {:error, _reason} -> "The cache could not be cleared."
      end

    {:noreply, Mob.Socket.assign(socket, :cache_notice, notice)}
  end

  # Re-read every tracked title from TMDB.
  #
  # Off this process — one round trip per season per show would stop the screen
  # drawing until TMDB answered — so the pill says *Refreshing…* and the answer
  # arrives as `{:cache_refreshed, result}`. See `Kati.Media.Cache`.
  def handle_tap(:refresh_cache, socket) do
    Kati.Media.Cache.ask(self())

    {:noreply,
     socket
     |> Mob.Socket.assign(:refreshing?, true)
     |> Mob.Socket.assign(:cache_notice, nil)}
  end

  @doc false
  def handle_tap(:wipe_tokens, socket) do
    Sources.disconnect_all()
    {:noreply, Mob.Socket.assign(socket, :expanded, nil)}
  end

  # Store first, then relight the chip — the same order screen 24's theme
  # trough keeps, and for the same reason: the chip and `Sources.tmdb_key/0`
  # are one fact drawn twice and must not be able to disagree. Byte for byte
  # what `Kati.Screens.DataSourcesFa` has answered since screen 82 landed.
  #
  # Both clauses stay even though `key_chip/3` only ever draws the tag for the
  # chip that is NOT in force. A handler that exists for a tag the resting
  # screen does not draw costs nothing; a tag drawn on some other state with no
  # handler behind it is the defect this whole round is about.
  def handle_tap(:key_kati, socket) do
    Sources.put_tmdb_key(:kati)
    {:noreply, Mob.Socket.assign(socket, :tmdb, :kati)}
  end

  def handle_tap(:key_own, socket) do
    Sources.put_tmdb_key(:own)

    {:noreply,
     socket
     |> Mob.Socket.assign(:tmdb, :own)
     |> Mob.Socket.assign(:token_saved?, Kati.Screens.DataSources.own_key_stored?())
     |> Mob.Socket.assign(:token_error, nil)}
  end

  # Board 318's two controls on the saved card. `Replace` puts the field back
  # WITHOUT clearing the store: a reader who opens it and changes their mind
  # still has a working key, which is the difference between replacing and
  # removing.
  @impl true
  def handle_tap(:replace_token, socket) do
    {:noreply,
     socket
     |> Mob.Socket.assign(:token_saved?, false)
     |> Mob.Socket.assign(:token, "")
     |> Mob.Socket.assign(:token_epoch, Map.get(socket.assigns, :token_epoch, 0) + 1)
     |> Mob.Socket.assign(:token_error, nil)}
  end

  def handle_tap(:remove_token, socket) do
    Kati.SecureStore.delete("tmdb")

    {:noreply,
     socket
     |> Mob.Socket.assign(:token_saved?, Kati.Screens.DataSources.own_key_stored?())
     |> Mob.Socket.assign(:token, "")
     |> Mob.Socket.assign(:token_epoch, Map.get(socket.assigns, :token_epoch, 0) + 1)
     |> Mob.Socket.assign(:token_error, nil)}
  rescue
    _error ->
      {:noreply, Mob.Socket.assign(socket, :token_error, "Couldn’t remove it. Nothing changed.")}
  end

  def handle_tap(:save_token, socket) do
    case String.trim(socket.assigns[:token] || "") do
      "" ->
        {:noreply, Mob.Socket.assign(socket, :token_error, "Paste a token first.")}

      token ->
        {:noreply, Kati.Screens.DataSources.store_token(socket, token)}
    end
  end

  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "connect_" <> id ->
        source = String.to_existing_atom(id)

        # One tag, two rows, because `tier2_row/2` puts it on every row whatever
        # its state — and the row's own trailing control already says which of
        # the two it is. A connected row draws `Disconnect`
        # (`connect_control/2`'s first clause), and expanding a pairing card
        # underneath it was the control doing the opposite of what it read:
        # there is nothing to pair, the token is already there. `tier2/1`'s doc
        # states the intent outright — connected "offers `Disconnect` — which is
        # the whole reason only revocable-token providers are on this list" —
        # and 80.html draws the word twice.
        #
        # Collapses to `nil` rather than leaving `:expanded` alone: the row is
        # about to redraw as a disconnected one, and leaving it expanded would
        # spring a pairing card open on a tap that meant to close an account.
        if Sources.connected?(source) do
          Sources.disconnect(source)
          {:noreply, Mob.Socket.assign(socket, :expanded, nil)}
        else
          now = if socket.assigns.expanded == source, do: nil, else: source
          {:noreply, Mob.Socket.assign(socket, :expanded, now)}
        end

      _other ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:change, :tmdb_token, typed}, socket) when is_binary(typed),
    do: {:noreply, Mob.Socket.assign(socket, :token, typed)}

  def handle_info({:cache_refreshed, result}, socket) do
    {:noreply,
     socket
     |> Mob.Socket.assign(:refreshing?, false)
     |> Mob.Socket.assign(:cache_notice, Kati.Screens.DataSources.refresh_line(result))}
  end

  def handle_info(message, socket), do: super(message, socket)

  @doc """
  What a finished refresh says.

      iex> Kati.Screens.DataSources.refresh_line({:ok, %{refreshed: 3, failed: 0}})
      "Refreshed 3 titles."

      iex> Kati.Screens.DataSources.refresh_line({:ok, %{refreshed: 2, failed: 1}})
      "Refreshed 2 titles. 1 could not be reached."

      iex> Kati.Screens.DataSources.refresh_line({:ok, %{refreshed: 0, failed: 0}})
      "Nothing on the shelf to refresh."
  """
  @spec refresh_line({:ok, map()} | {:error, term()}) :: String.t()
  def refresh_line({:ok, %{refreshed: 0, failed: 0}}), do: "Nothing on the shelf to refresh."

  def refresh_line({:ok, %{refreshed: n, failed: 0}}),
    do: "Refreshed #{n} #{if n == 1, do: "title", else: "titles"}."

  def refresh_line({:ok, %{refreshed: n, failed: f}}),
    do:
      "Refreshed #{n} #{if n == 1, do: "title", else: "titles"}. " <>
        "#{f} could not be reached."

  # `Kati.Media.Tmdb.message/1` already owns every sentence about a request
  # that could not be made, including the one about a key nobody has entered —
  # which is the failure this button meets most often and the one the reader
  # can actually do something about, two cards up this same page.
  def refresh_line({:error, reason}), do: Kati.Media.Tmdb.message(reason)

  @doc """
  Store the token, or say why it could not be.

  Trimmed, because a token pasted from a web page arrives with whitespace and
  a leading space is not a different token — it is the same token that will
  fail every request. Empty is a refusal rather than a silent no-op: somebody
  who presses Save on an empty field has done something and is owed an answer.
  """
  @spec store_token(Mob.Socket.t(), String.t()) :: Mob.Socket.t()
  def store_token(socket, token) do
    case Kati.SecureStore.put("tmdb", token) do
      :ok ->
        # Board 318's saved row says WHEN. Recorded here rather than derived,
        # because the keystore answers what it holds and not when it took it.
        Kati.Screens.DataSources.stamp_saved()

        socket
        |> Mob.Socket.assign(:token, "")
        # `K-46`: the bridge ignores a `value` for a field it has already drawn
        # unless `value_epoch` moves, so without this the token stays on screen
        # after it has been stored — the one string on this page that must not.
        |> Mob.Socket.assign(:token_epoch, Map.get(socket.assigns, :token_epoch, 0) + 1)
        |> Mob.Socket.assign(:token_saved?, true)
        |> Mob.Socket.assign(:token_error, nil)

      {:error, _reason} ->
        Mob.Socket.assign(
          socket,
          :token_error,
          # Board 318's sentence. `inspect(reason)` named a struct at a reader
          # who has pasted a string; the two commonest causes are the two named
          # here, and TMDB issues both on one page.
          "TMDB didn’t accept this. Check you copied the API Read Access Token " <>
            "and not the API key, and that it has no trailing space."
        )
    end
  rescue
    _error -> Mob.Socket.assign(socket, :token_error, "That did not save.")
  catch
    :exit, _reason -> Mob.Socket.assign(socket, :token_error, "That did not save.")
  end
end
