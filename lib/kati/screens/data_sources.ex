defmodule Kati.Screens.DataSources do
  @moduledoc """
  Screen 80 — Data sources, pushed under Settings.

  Where every poster, cover, air date and fact comes from, and the one page in
  the app that holds a token.

  ## One source, because Kati calls one

  Board 80 draws three groups of providers: *Working out of the box* (TVmaze,
  Open Library, MusicBrainz), TMDB, and *Connect an account* (ListenBrainz,
  Hardcover, TheTVDB). Kati calls exactly one of them. `Kati.SecureStore`'s
  inventory records it: no code anywhere reaches the other six, so a page
  listing them as working, or offering to connect them, advertised sources the
  app never touches (N41). The page now draws TMDB — the source every film and
  series search does use — and nothing else under a provider heading.

  `Kati.Sources.tier0/0` and `tier2/0` keep the lists and the reasoning behind
  them — ListenBrainz, Hardcover and TheTVDB take a **revocable token**, and
  Trakt, Simkl and Last.fm are left out because they need a pasted
  `client_secret` — for the day a client for one of them lands; that is the
  day its row comes back here.

  ## The reader brings the TMDB key

  The owner's decision: *"all users must put their token there."* No build
  carries a TMDB key of its own — not a store release and not a development
  build — so there is nothing to choose between and no chips: the card is the
  reader's token field, or the saved card once one is stored, and that token
  is the only key `Kati.Media.Tmdb.key/0` ever sends. `Kati.SecureStore`'s
  moduledoc tables every credential and where it can go.

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
  use Gettext, backend: Kati.Gettext

  require Ash.Query

  alias Kati.Media.CachedTitle
  alias Kati.Sources
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  @impl true
  def load(socket) do
    socket
    |> Mob.Socket.assign(:token, "")
    |> Mob.Socket.assign(:token_epoch, 0)
    |> Mob.Socket.assign(:token_error, nil)
    |> Mob.Socket.assign(:token_saved?, Kati.Screens.DataSources.own_key_stored?())
    |> Mob.Socket.assign(:confirm_wipe?, false)
    |> Mob.Socket.assign(:editing?, false)
    |> Mob.Socket.assign(:confirm_clear?, false)
    |> Mob.Socket.assign(:wipe_notice, nil)
    |> Kati.Screens.DataSources.settle_store()
  end

  @doc """
  Read the token again once the first frame is out, when the secure store had
  not answered yet.

  Its native half binds a moment after the app starts, and a page opened in
  that moment — a relaunch that restores it, a deploy — read nothing once and
  kept it. The same one-message settle `Kati.Screens.Account.settle/2` makes
  for permissions: not a timer and not a loop; `:resumed` covers a longer gap.
  """
  @spec settle_store(Mob.Socket.t()) :: Mob.Socket.t()
  def settle_store(socket) do
    if Kati.Permissions.platform_answers?() and not Kati.SecureStore.available?(),
      do: send(self(), {:kati, :store_settle, nil})

    socket
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
        {SettingsList.title(gettext("Data sources"), gettext("Where Kati’s posters, covers and facts come from."), nil, :name)}
        {UI.eyebrow(gettext("Better artwork and metadata"))}
        {Kati.Screens.DataSources.tmdb(Map.get(assigns, :token, ""), Map.get(assigns, :token_saved?, false), Map.get(assigns, :token_error), Map.get(assigns, :token_epoch, 0), %{editing?: Map.get(assigns, :editing?, false), confirm_clear?: Map.get(assigns, :confirm_clear?, false)})}
        {UI.eyebrow(gettext("Where your tokens live"))}
        {Kati.Screens.DataSources.tokens(assigns)}
        {UI.eyebrow(gettext("Cached metadata"))}
        {Kati.Screens.DataSources.cache(Map.get(assigns, :cache_notice), Map.get(assigns, :refreshing?, false))}
      </Column>
    </Scroll>
    """
  end

  @doc """
  A provider's name over its sub-line, with the name in the face its script needs.

  `Kati.UI.SettingsList.body/3`'s shape, and it cannot draw these two words: it
  builds both `Text` nodes itself and leaves `font_family` off, which is right
  for every other settings row and wrong for this one. `TMDB` and `ListenBrainz`
  are a machine's names for itself and the drawings set them in DM Mono in both
  scripts; **فیلم و سریال · TVmaze** carries Persian, and DM Mono has no
  Arabic-script glyph, so it would draw the Persian half as empty boxes and the
  Latin half perfectly. `Kati.Locale.mono_face/1` decides by the script that is
  actually in the string — see its doc — so a provider added to `Kati.Sources`
  tomorrow is typeset correctly without anybody deciding again.

  Every number here is `body/3`'s: 13.5 over 11.5 with 3pt between them, ink
  over `sub`.
  """
  @spec body(String.t(), String.t()) :: map()
  def body(name, sub) do
    assigns = %{name: name, sub: sub, face: Kati.Locale.mono_face(name)}

    ~MOB"""
    <Column fill_width={true}>
      <Text
        text={@name}
        font_family={@face}
        text_size={13.5}
        font_weight="semibold"
        text_color={:on_surface}
        max_lines={1}
      />
      <Spacer size={3} />
      <Text
        text={@sub}
        text_size={11.5}
        line_height={Kati.Locale.leading(1.4)}
        text_color={Kati.Theme.Palette.sub()}
        max_lines={2}
      />
    </Column>
    """
  end

  # The words on the controls, as functions rather than literals in the markup:
  # `~MOB` is an uppercase sigil and interpolates nothing, so a `gettext/1` call
  # has to reach it through an assign or a function. These are the ones that
  # take no argument and would otherwise need an assign apiece.
  @doc false
  @spec save_label() :: String.t()
  def save_label, do: gettext("Save")

  @doc false
  @spec token_placeholder() :: String.t()
  def token_placeholder, do: gettext("Paste token")

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
      font_family={Kati.Locale.mono_face(@label)}
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
        at |> Kati.Time.in_zone(Kati.Time.device_zone()) |> Kati.Locale.time()

      _other ->
        nil
    end
  rescue
    _error -> nil
  end

  @doc """
  TMDB, and the reader's own token under it.

  No choice of key: the token field, or board 318's saved card once one is
  stored, is always drawn — see the moduledoc's *The reader brings the TMDB
  key*.
  """
  @spec tmdb(String.t(), boolean(), String.t() | nil, non_neg_integer()) :: map()
  def tmdb(token \\ "", saved? \\ false, error \\ nil, epoch \\ 0, state \\ %{}) do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.card([
        Kati.UI.SettingsList.row(
          Kati.UI.SettingsList.icon_tile("movie"),
          Kati.Screens.DataSources.body("TMDB", gettext("Posters, backdrops, cast")),
          Kati.UI.SettingsList.trailing(Kati.Screens.DataSources.reached(:tmdb))
        )
      ])}
      <Spacer size={12} />
      {Kati.Screens.DataSources.own_key(token, saved?, error, epoch, state)}
      <Spacer size={12} />
      {Kati.UI.SettingsList.note("info", gettext("Kati uses your own TMDB token, so searches are yours and nobody else’s. It is free: sign in at themoviedb.org, open Settings → API, and paste the API Read Access Token — the long one starting eyJ."))}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  Where the reader's token goes, and the only place it can.

  `Kati.Media.Tmdb.key/0` reads nothing else, so without a token here screen
  06 returns no results and draws a notice pointing back at THIS page. Board
  80 does not draw it — the board was drawn with a key of Kati's own chosen,
  and that key no longer exists.

  `Kati.SecureStore.available?/0` is checked before the field is offered rather
  than after a save fails, which is the rule that module states in its own
  words: *callers that hold credentials must check this before offering to
  connect an account, so the user is told the truth instead of discovering it
  when the first save fails.*
  """
  @spec own_key(String.t(), boolean(), String.t() | nil, non_neg_integer(), map()) :: map()
  def own_key(token, saved?, error, epoch, state \\ %{}) do
    editing? = Map.get(state, :editing?, false)

    cond do
      not Kati.SecureStore.available?() and not Kati.Permissions.platform_answers?() ->
        Kati.Screens.DataSources.no_keystore()

      saved? and Map.get(state, :confirm_clear?, false) ->
        Kati.Screens.DataSources.clear_confirm()

      saved? and not editing? and error == nil ->
        Kati.Screens.DataSources.key_in_use()

      true ->
        Kati.Screens.DataSources.key_field(token, error, epoch, saved? and editing?)
    end
  end

  @doc """
  What *Clear* asks before it takes the token off the phone — the app's own
  destructive confirmation (`Kati.UI.Destructive.confirm/1`), which board 269
  scoped to this screen among others.
  """
  @spec clear_confirm() :: map()
  def clear_confirm do
    Kati.UI.Destructive.confirm(
      eyebrow: gettext("Clear token"),
      title: gettext("Clear your TMDB token?"),
      changes: gettext("Kati stops searching TMDB on this phone until you add a token again."),
      keeps: gettext("Your library, ratings and the posters already saved stay as they are."),
      confirm: {gettext("Clear"), :clear_token_confirm},
      keep: {gettext("Cancel"), :clear_token_cancel}
    )
  end

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
          Kati.UI.SettingsList.body(gettext("Your key is in use"), @since),
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
          rule: true
        ),
        Kati.UI.SettingsList.row(
          Kati.UI.SettingsList.icon_tile("edit"),
          Kati.UI.SettingsList.body(gettext("Edit token")),
          Kati.UI.SettingsList.trailing(Kati.UI.SettingsList.chevron()),
          padding: 13,
          rule: true,
          on_tap: {self(), :edit_token}
        ),
        Kati.UI.SettingsList.row(
          Kati.UI.SettingsList.icon_tile("delete"),
          Kati.Screens.DataSources.clear_label(),
          Kati.UI.SettingsList.trailing(nil),
          padding: 13,
          rule: false,
          on_tap: {self(), :clear_token}
        )
      ])}
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

  def saved_line(nil), do: Kati.UI.eyebrow_label(gettext("Saved"))

  def saved_line(at) do
    # `String.upcase/1` was the capitalisation AND the join, and Persian has no
    # upper case — `Kati.UI.eyebrow_label/1` is the one that knows that. The
    # span comes from `Kati.Settings.Watcher.since/1`, which exists because this
    # line used to build it by String-replacing `"checked "` off the front of
    # `checked_line/2`'s answer — a sentence, and a sentence is translated.
    Kati.UI.eyebrow_label(gettext("Saved %{ago}", ago: Kati.Settings.Watcher.since(at)))
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
    # `Kati.Locale.ltr/1`, and the FACE read off the RAW string rather than off
    # the wrapped one — two decisions, and they pull in opposite directions.
    #
    # A masked token is `eyJhbGciOiJIUzI1… ••••`: a Latin run with an ellipsis,
    # a space and four bullets behind it, and all six of those trailing
    # characters are bidi-NEUTRAL. On board 318 under `:fa` the paragraph's own
    # direction is RTL, so the neutrals resolve right-to-left and the tail is
    # laid out at the LEFT edge — `•••• …eyJhbGciOiJIUzI1`, the mask drawn in
    # front of the thing it is masking. Same failure as board 85's licence
    # notices; `Kati.Locale.ltr/1`'s doc carries the long version.
    #
    # The face is asked BEFORE the wrap because `U+2066`/`U+2069` are not ASCII
    # and `Kati.Locale.mono_face/1` decides by the script actually in the
    # string. Asking it about the wrapped string would answer `fa` for a
    # pure-ASCII JWT and take DM Mono off every masked token under `:fa` — the
    # one line on this page that is a machine's string in both scripts.
    assigns = %{masked: Kati.Locale.ltr(masked), face: Kati.Locale.mono_face(masked)}

    ~MOB"""
    <Text
      text={@masked}
      font_family={@face}
      text_size={12.5}
      text_color={Kati.Theme.Palette.sub()}
      max_lines={1}
    />
    """
  end

  @doc "The *Clear token* row's title, in the page's destructive red."
  def clear_label do
    ~MOB"""
    <Text
      text={gettext("Clear token")}
      text_size={13.5}
      font_weight="semibold"
      text_color={Palette.red()}
      max_lines={1}
    />
    """
  end

  @doc """
  The field, empty or refused — board 318's other two states.

  The refusal is 318's own sentence, and it is the one a reader can act on:
  TMDB issues an **API key** and an **API Read Access Token** on the same page,
  and pasting the first where the second belongs is the commonest way this
  fails. A trailing space is the second.
  """
  @spec key_field(String.t(), String.t() | nil, non_neg_integer()) :: map()
  def key_field(token, error, epoch, cancel? \\ false) do
    assigns = %{
      token: token,
      error: error,
      epoch: epoch,
      cancel?: cancel?,
      on_change: {self(), :tmdb_token},
      save: {self(), :save_token}
    }

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.card([
        Kati.UI.SettingsList.row(
          Kati.UI.SettingsList.icon_tile("lock"),
          Kati.Screens.DataSources.token_field(@token, @on_change, @epoch),
          Kati.UI.SettingsList.trailing(if(@cancel?, do: nil, else: Kati.Screens.DataSources.save_pill(@save))),
          padding: 13,
          rule: false
        )
      ])}
      {Kati.Screens.DataSources.token_state(false, @error)}
      {Kati.Screens.DataSources.edit_actions(@cancel?, @save)}
    </Column>
    """
  end

  @doc """
  Editing a saved token: Cancel and Save side by side under the field, the
  secondary pill beside the primary one, so the way back is as plain as the
  way forward.
  """
  def edit_actions(false, _save), do: ~MOB"<Spacer size={0} />"

  def edit_actions(true, save) do
    ~MOB"""
    <Row fill_width={true} padding_top={12} align="center">
      <Spacer weight={1.0} />
      <Row
        height={32}
        corner_radius={16}
        background={Palette.card()}
        border_width={1}
        border_color={Palette.border()}
        padding_left={14}
        padding_right={14}
        align="center"
        on_tap={{self(), :edit_cancel}}
      >
        <Text
          text={gettext("Cancel")}
          text_size={12.5}
          font_weight="semibold"
          text_color={:on_surface}
          max_lines={1}
        />
      </Row>
      <Spacer size={8} />
      {Kati.Screens.DataSources.save_pill(save)}
    </Row>
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
      gettext(
        "This device has no keystore Kati can reach, so the token sits unencrypted on " <>
          "the filesystem like every other. Kati sends it only to TMDB, and you can " <>
          "revoke it from your TMDB account at any time."
      )
    )
  end

  @doc false
  def token_field(token, on_change, epoch) do
    assigns = %{token: token, on_change: on_change, epoch: epoch}

    ~MOB"""
    <TextField
      value={@token}
      placeholder={Kati.Screens.DataSources.token_placeholder()}
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
        text={Kati.Screens.DataSources.save_label()}
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
    do: ~MOB"""
    <Column fill_width={true} padding_top={10}>
      {Kati.UI.SettingsList.note("error", error)}
    </Column>
    """

  def token_state(true, _error),
    do:
      Kati.UI.SettingsList.note(
        "check_circle",
        gettext("A token of yours is stored. Kati searches with it.")
      )

  def token_state(_saved?, _error), do: ~MOB"<Spacer size={0} />"

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

  @doc "114's pill, and screen 88's — one mark for *named and not doing this*."
  @spec not_in_v1() :: map()
  def not_in_v1 do
    ~MOB"""
    <Row
      height={22}
      corner_radius={11}
      background={Palette.placeholder()}
      padding_left={9}
      padding_right={9}
      align="center"
    >
      <Text
        text={Kati.UI.eyebrow_label(gettext("Not in v1"))}
        font_family={Kati.Locale.mono_face()}
        text_size={9.5}
        letter_spacing={Kati.Locale.tracking(0.1)}
        text_color={Palette.rail_idle()}
        max_lines={1}
      />
    </Row>
    """
  end

  @doc """
  Board 81's inline wipe confirmation, live.

  Inline and not a modal, and leading with what survives before it asks — both
  are board 81's own judgements and its moduledoc carries the reasoning for
  each. The red fill goes on the destructive answer and the paper on the safe
  one, in that order, "because the confirmation is being asked about the thing
  the reader has already reached for; putting the safe answer first would make
  them work out which side is which."

  The count is the reader's own, where the board writes *Three accounts* as a
  word — see `Kati.Sources.connected_count/0` for why the board's argument for
  a word does not carry over to a live screen.
  """
  @spec wipe_confirm(boolean()) :: map()
  def wipe_confirm(false), do: ~MOB"<Spacer size={0} />"

  def wipe_confirm(true) do
    count = Sources.connected_count()

    assigns = %{
      question: gettext("Wipe all tokens?"),
      paragraph:
        ngettext(
          "%{n} account disconnects. Your library, ratings and history are untouched — only the keys go.",
          "%{n} accounts disconnect. Your library, ratings and history are untouched — only the keys go.",
          count,
          n: Kati.Locale.number(count)
        ),
      wipe:
        Kati.Screens.DataSourcesStates.answer(
          gettext("Wipe tokens"),
          Palette.red(),
          Palette.on_ink(),
          :bold,
          true,
          {self(), :wipe_confirm}
        ),
      keep:
        Kati.Screens.DataSourcesStates.answer(
          pgettext("the safe answer to the wipe confirmation", "Keep them"),
          Palette.paper(),
          Palette.ink_soft(),
          :semibold,
          false,
          {self(), :wipe_cancel}
        )
    }

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={20}
        padding={15}
        shadow={Kati.Theme.shadow_card_soft()}
      >
        <Row fill_width={true} align="top">
          {Kati.UI.symbol("error", size: 19, color: Palette.red())}
          <Spacer size={11} />
          <Column weight={1.0}>
            <Text
              text={@question}
              text_size={13.5}
              font_weight="bold"
              text_color={:on_surface}
              max_lines={1}
            />
            <Spacer size={6} />
            <Text
              text={@paragraph}
              text_size={12.5}
              line_height={Kati.Locale.leading(1.55)}
              text_color={Palette.ink_soft()}
            />
          </Column>
        </Row>
        <Spacer size={14} />
        <Row fill_width={true} align="center">
          <Column weight={1.0} fill_width={true}>
            {@wipe}
          </Column>
          <Spacer size={8} />
          {@keep}
        </Row>
      </Column>
      <Spacer size={12} />
    </Column>
    """
  end

  @doc "What the wipe did, once it has been done."
  @spec wipe_notice(String.t() | nil) :: map()
  def wipe_notice(nil), do: ~MOB"<Spacer size={0} />"

  def wipe_notice(message) do
    assigns = %{notice: Kati.UI.notice(message)}

    ~MOB"""
    <Column fill_width={true}>
      {@notice}
      <Spacer size={12} />
    </Column>
    """
  end

  @doc """
  Where tokens live, the one row that takes them all away, and the question it
  now asks first.

  `delete_forever` and red, because it is the only destructive control on the
  page and the only one whose consequence cannot be undone by pressing it
  again — which is exactly why it had no business doing it on the first tap.
  """
  @spec tokens(map()) :: map()
  def tokens(assigns \\ %{}) do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.note("info", Kati.Sources.token_note())}
      <Spacer size={12} />
      {Kati.Screens.DataSources.wipe_notice(Map.get(assigns, :wipe_notice))}
      {Kati.Screens.DataSources.wipe_confirm(Map.get(assigns, :confirm_wipe?, false))}
      {Kati.UI.SettingsList.card([
        Kati.UI.SettingsList.row(
          Kati.UI.SettingsList.icon_tile("delete_forever"),
          Kati.UI.SettingsList.body(gettext("Disconnect everything and wipe tokens"), nil),
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
      refresh: if(refreshing?, do: gettext("Refreshing…"), else: gettext("Refresh"))
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
              font_family={Kati.Locale.mono_face(@oldest)}
              text_size={10}
              letter_spacing={Kati.Locale.tracking(0.12)}
              text_color={Palette.muted()}
              max_lines={1}
            />
          </Column>
          {Kati.UI.SettingsList.action_pill(@refresh, {self(), :refresh_cache})}
          <Spacer size={9} />
          {Kati.UI.SettingsList.action_pill(gettext("Clear"), {self(), :clear_cache})}
        </Row>
        {@notice}
      </Column>
      <Spacer size={12} />
      {Kati.UI.SettingsList.note("info", gettext("Kati refreshes anything older than six months on its own. That is a promise it keeps, not a limit it suffers."))}
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
      {:ok, 0} ->
        Kati.Screens.DataSources.nothing_cached()

      {:ok, _count} ->
        gettext("%{n} MB cached",
          n: Kati.Locale.number(Kati.Screens.DataSources.database_megabytes())
        )

      _other ->
        Kati.Screens.DataSources.nothing_cached()
    end
  rescue
    _error -> Kati.Screens.DataSources.nothing_cached()
  end

  @doc false
  @spec nothing_cached() :: String.t()
  def nothing_cached, do: gettext("Nothing cached yet")

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
        # Both sides of the subtraction in the DEVICE's zone. `Kati.Time.today/0`
        # is already local and `fetched_at` is stored in UTC, so
        # `DateTime.to_date/1` on the raw row was taking a UTC date away from a
        # local one: in Tehran (UTC+03:30) a row written at 02:00 today is
        # 22:30 UTC yesterday, and the card said `OLDEST ENTRY 1 DAY` over a
        # cache filled minutes earlier. `last_reached/1` on this same page
        # already converts before it formats; this is that conversion, for the
        # same reason, on the figure the eyebrow states as the reader's own.
        local = Kati.Time.in_zone(at, Kati.Time.device_zone())
        days = Date.diff(Kati.Time.today(), DateTime.to_date(local))

        Kati.UI.eyebrow_label(
          gettext("Oldest entry %{age}", age: Kati.Screens.DataSources.age(days))
        )

      _other ->
        Kati.Screens.DataSources.nothing_to_refresh()
    end
  rescue
    _error -> Kati.Screens.DataSources.nothing_to_refresh()
  end

  @doc false
  @spec nothing_to_refresh() :: String.t()
  def nothing_to_refresh, do: Kati.UI.eyebrow_label(gettext("Nothing to refresh"))

  @doc """
  A span of days as the row writes it — today, days, months.

  `ngettext/5` rather than the `if days == 1` it was, and not for tidiness:
  Persian counts nouns in the singular — ۲ ماه, never ۲ ماه‌ها — so the branch
  the English sentence needs is one the Persian sentence must not have. That is
  a plural rule, which is what a PO file's `Plural-Forms` is for, and it is why
  the mirror could not reuse this function and had to keep its own.
  """
  @spec age(integer()) :: String.t()
  def age(days) when days <= 0, do: gettext("today")

  def age(days) when days < 31,
    do: ngettext("%{n} day", "%{n} days", days, n: Kati.Locale.number(days))

  def age(days) do
    months = div(days, 30)
    ngettext("%{n} month", "%{n} months", months, n: Kati.Locale.number(months))
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
        font_family={Kati.Locale.mono_face(@message)}
        text_size={10.5}
        letter_spacing={Kati.Locale.tracking(0.12)}
        text_color={Palette.muted()}
      />
    </Column>
    """
  end

  @doc """
  Empty the metadata cache.

  Nothing the reader made is in it — `Kati.Media.Cache`'s moduledoc gives the
  whole argument — so this needs no confirmation step: the shelf, the ticks and
  the ratings are all still there afterwards, and the posters come back on the
  next refresh.
  """
  @impl true
  def handle_tap(:clear_cache, socket) do
    notice =
      case Kati.Media.Cache.clear() do
        {:ok, 0} ->
          gettext("Nothing was cached.")

        {:ok, n} ->
          ngettext("Cleared %{n} cached row.", "Cleared %{n} cached rows.", n,
            n: Kati.Locale.number(n)
          )

        {:error, _reason} ->
          gettext("The cache could not be cleared.")
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
  # The row ASKS now. It used to call `Kati.Sources.disconnect_all/0` on the tap
  # itself: one press, every stored token gone — the reader's own TMDB key among
  # them — with no confirmation, no undo, and a chevron on the row promising a
  # page it never opened. It is the only destructive control on this screen and
  # its own `@doc` says so.
  #
  # Board 81 designs the answer and gives the reasoning: inline rather than
  # modal, because "a modal takes the page away at the moment the reader most
  # wants to check what is on it", and leading with what SURVIVES before it asks.
  #
  # A wipe with nothing to wipe is not asked about at all — `connected_count/0`
  # is zero and there is no event to confirm.
  def handle_tap(:wipe_tokens, socket) do
    case Sources.connected_count() do
      0 ->
        {:noreply,
         socket
         |> Mob.Socket.assign(:confirm_wipe?, false)
         |> Mob.Socket.assign(:wipe_notice, gettext("Nothing is connected."))}

      _some ->
        {:noreply,
         socket
         |> Mob.Socket.assign(:confirm_wipe?, true)
         |> Mob.Socket.assign(:wipe_notice, nil)}
    end
  end

  def handle_tap(:wipe_confirm, socket) do
    count = Sources.connected_count()
    Sources.disconnect_all()

    {:noreply,
     socket
     |> Mob.Socket.assign(:confirm_wipe?, false)
     |> Mob.Socket.assign(:token_saved?, Kati.Screens.DataSources.own_key_stored?())
     |> Mob.Socket.assign(
       :wipe_notice,
       ngettext(
         "%{n} account disconnected.",
         "%{n} accounts disconnected.",
         count,
         n: Kati.Locale.number(count)
       )
     )}
  end

  def handle_tap(:wipe_cancel, socket),
    do: {:noreply, Mob.Socket.assign(socket, :confirm_wipe?, false)}

  # Edit opens the field WITHOUT clearing the store: a reader who changes their
  # mind still has a working key. Clear asks first (`clear_confirm/0`).
  @impl true
  def handle_tap(:edit_token, socket) do
    {:noreply,
     socket
     |> Mob.Socket.assign(:editing?, true)
     |> Kati.Screens.DataSources.fresh_field()}
  end

  def handle_tap(:edit_cancel, socket) do
    {:noreply,
     socket
     |> Mob.Socket.assign(:editing?, false)
     |> Kati.Screens.DataSources.fresh_field()}
  end

  def handle_tap(:clear_token, socket),
    do: {:noreply, Mob.Socket.assign(socket, :confirm_clear?, true)}

  def handle_tap(:clear_token_cancel, socket),
    do: {:noreply, Mob.Socket.assign(socket, :confirm_clear?, false)}

  def handle_tap(:clear_token_confirm, socket) do
    case Kati.SecureStore.delete("tmdb") do
      :ok ->
        {:noreply,
         socket
         |> Mob.Socket.assign(:confirm_clear?, false)
         |> Mob.Socket.assign(:editing?, false)
         |> Mob.Socket.assign(:token_saved?, Kati.Screens.DataSources.own_key_stored?())
         |> Kati.Screens.DataSources.fresh_field()}

      {:error, _reason} ->
        {:noreply,
         socket
         |> Mob.Socket.assign(:confirm_clear?, false)
         |> Mob.Socket.assign(:token_error, gettext("Couldn’t remove it. Nothing changed."))}
    end
  end

  def handle_tap(:save_token, socket) do
    case String.trim(socket.assigns[:token] || "") do
      "" ->
        {:noreply, Mob.Socket.assign(socket, :token_error, gettext("Paste a token first."))}

      token ->
        {:noreply, Kati.Screens.DataSources.store_token(socket, token)}
    end
  end

  def handle_tap(_tag, socket), do: {:noreply, socket}

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

  @impl true
  def handle_kati(topic, _payload, socket) when topic in [:store_settle, :resumed],
    do:
      {:noreply,
       Mob.Socket.assign(
         socket,
         :token_saved?,
         Kati.Screens.DataSources.own_key_stored?()
       )}

  def handle_kati(_topic, _payload, socket), do: {:noreply, socket}

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
  def refresh_line({:ok, %{refreshed: 0, failed: 0}}),
    do: gettext("Nothing on the shelf to refresh.")

  def refresh_line({:ok, %{refreshed: n, failed: 0}}),
    do: ngettext("Refreshed %{n} title.", "Refreshed %{n} titles.", n, n: Kati.Locale.number(n))

  def refresh_line({:ok, %{refreshed: n, failed: f}}),
    do:
      ngettext("Refreshed %{n} title.", "Refreshed %{n} titles.", n, n: Kati.Locale.number(n)) <>
        " " <>
        ngettext("%{n} could not be reached.", "%{n} could not be reached.", f,
          n: Kati.Locale.number(f)
        )

  # `Kati.Media.Tmdb.message/1` already owns every sentence about a request
  # that could not be made, including the one about a key nobody has entered —
  # which is the failure this button meets most often and the one the reader
  # can actually do something about, two cards up this same page.
  def refresh_line({:error, reason}), do: Kati.Media.Tmdb.message(reason)

  @doc "An empty token field, redrawn, with no error under it."
  @spec fresh_field(Mob.Socket.t()) :: Mob.Socket.t()
  def fresh_field(socket) do
    socket
    |> Mob.Socket.assign(:token, "")
    |> Mob.Socket.assign(:token_epoch, Map.get(socket.assigns, :token_epoch, 0) + 1)
    |> Mob.Socket.assign(:token_error, nil)
  end

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
        |> Mob.Socket.assign(:editing?, false)
        |> Mob.Socket.assign(:token_error, nil)

      {:error, _reason} ->
        Mob.Socket.assign(
          socket,
          :token_error,
          # Board 318's sentence. `inspect(reason)` named a struct at a reader
          # who has pasted a string; the two commonest causes are the two named
          # here, and TMDB issues both on one page.
          gettext(
            "TMDB didn’t accept this. Check you copied the API Read Access Token " <>
              "and not the API key, and that it has no trailing space."
          )
        )
    end
  rescue
    _error -> Mob.Socket.assign(socket, :token_error, gettext("That did not save."))
  catch
    :exit, _reason -> Mob.Socket.assign(socket, :token_error, gettext("That did not save."))
  end
end
