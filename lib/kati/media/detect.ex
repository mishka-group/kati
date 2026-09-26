defmodule Kati.Media.Detect do
  @moduledoc """
  Noticing what you played, so you do not have to tell Kati twice.

  Screen 36 is the argument for this feature drawn in
  full — a master switch, per-source rows with tick counts, a *Now playing*
  card, a threshold, and a queue of matches it refused to guess at — and none
  of it had anything behind it. Its own moduledoc said so: *detection is a
  feature that has not been built, not a screen that has not been wired.*

  ## What the phone will tell us, and what it will not

  Android's answer to *what is this device playing* is
  `MediaSessionManager.getActiveSessions`, which takes the component of an
  enabled notification listener as its proof of consent — see
  `KatiMediaListener` and `K-46` in `native/LEDGER.md`. What comes back is the
  package, a title, a subtitle, a position and a duration.

  A title and a subtitle. Not a TMDB id, not a season, not an episode number:
  Netflix reports `Severance` and `Half Loop`, Plex reports `Severance - S1E2 -
  Half Loop`, and a browser reports whatever the page called itself. So
  matching is by NAME against the reader's own shelf, and everything this
  module refuses to do follows from that:

    * **it ticks nothing that is not already on your shelf.** A detector that
      added titles would turn a mistyped browser tab into a library entry.
    * **it ticks nothing it matched loosely.** A candidate has to match a shelf
      key exactly, case and whitespace aside — `Kati.Import.Job.name_key/1`'s
      rule, and for its reason: `Se7en` and `Seven` are two films.
    * **an ambiguous session becomes a question**, not a tick. That is the card
      board 36 is arranged around and the sentence it gives for it: *a wrong
      tick pollutes a watch history nobody audits.*

  ## One show has several names, and a file has none

  Exact matching against one name is too strict to be useful, and anime is
  where that shows first. A reader's shelf holds TMDB's name —
  `Frieren: Beyond Journey's End` — and Crunchyroll may announce
  `Sousou no Frieren`. Same show, no match, and a question the reader has to
  answer about something they plainly keep.

  So the shelf is keyed by **both** names Kati already has:
  `Kati.Media.CachedTitle.title` and `title_original`, which the TMDB ingest
  has been filling from `original_name` all along and nothing read.

  And a local player announces a FILE. VLC playing
  `Frieren.S01E05.1080p.WEB-DL.mkv` reports exactly that, which matches
  nothing. `candidates/1` therefore also offers a cleaned form of each name —
  extension dropped, dots and underscores turned into spaces, everything from
  an `S01E05` marker onwards cut off — and that cleaned form is matched
  **exactly** like any other. This is not fuzzy matching: it is a second
  spelling of the same string, and a candidate that still matches nothing is
  still a question.

  ## The threshold, and why it is a threshold

  A session is a tick when it passes `threshold/0` of its duration — 90% by
  default, which is board 36's own number. Not at the end, because nobody
  watches the credits; not at the start, because opening something is not
  watching it.

  A session with no duration cannot pass a percentage of it and is never a
  tick. Live television and a browser tab are both that, and both are things a
  reader would be angry to find in their history.

  ## Nothing here polls, and it must not

  Polling was the first shape and it cannot work. `sessions/0` answers what is
  playing **at this moment**, and the moment that matters is one Kati is not
  running for: you finish an episode, close Netflix, and the session is gone
  before Kati is next opened. A screen that polled would see nothing, every
  time, for the one case the whole feature exists for.

  So the listener records instead. `KatiMediaListener` is bound whenever the
  reader has enabled it, watches every session while it plays, and keeps the
  furthest point each one reached; `drain/0` reads that back and clears it.
  That is the shape `Kati.Background.Handoff` already uses for the periodic
  refresh worker, and for the same reason: work happens while the BEAM is dead
  and is read when the BEAM is next up.

  `Kati.App` drains at boot. `sweep/0` is the live half — what is playing right
  now — and screen 36 runs it when it opens, so a session in flight is caught
  too.
  """

  require Ash.Query

  alias Kati.Media.CachedTitle
  alias Kati.Media.TitleAlias
  alias Kati.Media.TrackedTitle
  alias Kati.Media.Watch
  alias Kati.Native.Bridge

  @default_threshold 90
  @kinds [:movie, :tv, :anime]

  @doc """
  Whether the reader has allowed Kati to see what is playing.

  `:granted`, `:denied`, or `:unavailable` on a build with no bridge — which is
  every host test, and is not the same as denied: nobody has refused anything.
  """
  @spec access() :: :granted | :denied | :unavailable
  def access do
    case Bridge.reply(:media_access, []) do
      {:ok, "ok:granted"} -> :granted
      {:ok, "ok:denied"} -> :denied
      _no_bridge -> :unavailable
    end
  end

  @doc """
  Whether detection is switched on. Off until somebody says otherwise.

  `Mob.State`, where `Kati.Locale` and `Kati.Rating.Scale` keep their own
  preferences: this is a setting about the app rather than a fact about a
  title, and it has to survive a restart or the master switch is the thing
  #100 called it.
  """
  @spec on?() :: boolean()
  def on? do
    Mob.State.get(:detect_enabled, false) == true
  rescue
    _no_state -> false
  end

  @doc "Turn detection on or off."
  @spec put(boolean()) :: :ok
  def put(on?) when is_boolean(on?) do
    Mob.State.put(:detect_enabled, on?)
    :ok
  rescue
    _no_state -> :ok
  end

  @doc """
  The percentage of a session that counts as watched.

  90 is board 36's own `Tick at 90%`. Stored so the row can change it, and
  clamped by `clamp/1` to something a person could mean.
  """
  @spec threshold() :: pos_integer()
  def threshold do
    Kati.Media.Detect.clamp(Mob.State.get(:detect_threshold, @default_threshold))
  rescue
    _no_state -> @default_threshold
  end

  @doc """
  A threshold a person could mean: below half is not watching it, and 100 is
  the credits.

      iex> Kati.Media.Detect.clamp(90)
      90

      iex> Kati.Media.Detect.clamp(5)
      50

      iex> Kati.Media.Detect.clamp(200)
      99
  """
  @spec clamp(term()) :: pos_integer()
  def clamp(percent) when is_integer(percent) and percent < 50, do: 50
  def clamp(percent) when is_integer(percent) and percent > 99, do: 99
  def clamp(percent) when is_integer(percent), do: percent
  def clamp(_other), do: @default_threshold

  @doc "Set the threshold. See `threshold/0`."
  @spec put_threshold(integer()) :: :ok
  def put_threshold(percent) when is_integer(percent) do
    Mob.State.put(:detect_threshold, Kati.Media.Detect.clamp(percent))
    :ok
  rescue
    _no_state -> :ok
  end

  @doc """
  Every media session the phone is running, shaped.

  `[]` when nothing is playing, when access has not been granted, and on a
  build with no bridge. Those are three different facts and `access/0` is what
  tells them apart — see the moduledoc.
  """
  @spec sessions() :: [map()]
  def sessions do
    with {:ok, "ok:" <> json} <- Bridge.reply(:now_playing, []),
         {:ok, list} when is_list(list) <- decode(json) do
      Enum.flat_map(list, &Kati.Media.Detect.session/1)
    else
      _nothing -> []
    end
  end

  @doc false
  @spec session(map()) :: [map()]
  def session(%{"title" => title} = raw) when is_binary(title) and title != "" do
    [
      %{
        app: Map.get(raw, "app", ""),
        title: title,
        subtitle: Map.get(raw, "subtitle", ""),
        # Where a TV app usually puts the SERIES name while `title` carries the
        # episode — Netflix and Plex both do. Without it the only name a series
        # announced was its episode's, which matches nothing on a shelf of
        # series.
        album: Map.get(raw, "album", ""),
        # App-private and never treated as anything else. See
        # `KatiMediaListener`: it is stable for one item inside one app, which
        # is what makes it a key an alias can be remembered against.
        media_id: Map.get(raw, "media_id", ""),
        duration_ms: Map.get(raw, "duration_ms", 0),
        position_ms: Map.get(raw, "position_ms", 0),
        playing?: Map.get(raw, "playing", false)
      }
    ]
  end

  def session(_unusable), do: []

  @doc """
  How far through a session is, as a percentage, or `nil` when it cannot say.

  `nil` for a session with no duration — live television, a browser tab, a
  stream — and that is the answer that keeps them out of a watch history:
  something with no end cannot be 90% of the way to it.

      iex> Kati.Media.Detect.progress(%{position_ms: 4_500_000, duration_ms: 5_000_000})
      90

      iex> Kati.Media.Detect.progress(%{position_ms: 100, duration_ms: 0})
      nil
  """
  @spec progress(map()) :: non_neg_integer() | nil
  def progress(%{duration_ms: duration}) when not is_integer(duration) or duration <= 0, do: nil

  def progress(%{position_ms: position, duration_ms: duration}) when is_integer(position) do
    div(position * 100, duration)
  end

  def progress(_unusable), do: nil

  @doc """
  What Kati would do about one session, right now.

    * `{:tick, tracked, episode_or_nil}` — it is yours, it is far enough
      through, and nothing has ticked it yet.
    * `{:ask, title}` — something is playing that Kati cannot place. Board 36's
      *Needs a decision* card is this, and it is the reason the card exists.
    * `:ignore` — not far enough through, already ticked, not playing, or with
      no duration to measure.

  Nothing is written. `apply/1` writes.
  """
  @spec verdict(map()) :: {:tick, struct(), String.t() | nil} | {:ask, String.t()} | :ignore
  def verdict(session) do
    cond do
      not Map.get(session, :playing?, false) ->
        :ignore

      is_nil(Kati.Media.Detect.progress(session)) ->
        :ignore

      Kati.Media.Detect.progress(session) < Kati.Media.Detect.threshold() ->
        :ignore

      true ->
        case Kati.Media.Detect.match(session) do
          nil -> {:ask, session.title}
          {tracked, episode} -> {:tick, tracked, episode}
        end
    end
  end

  @doc """
  The shelf row a session names, and the episode within it, or `nil`.

  Two names arrive and either may be the show: Netflix reports the series as
  the title and the episode as the subtitle, and a file-based player usually
  does the reverse. So both are tried against the shelf, and whichever matches
  is the title — the other is then the episode's name, which is what
  `episode_of/2` looks up.
  """
  @spec match(map()) :: {struct(), String.t() | nil} | nil
  def match(session) do
    shelf = Kati.Media.Detect.shelf()

    # What the reader has taught, before anything Kati works out for itself.
    # `Kati.Media.TitleAlias` is the answer to a question they have already
    # been asked once, and re-deriving over the top of it would be asking again.
    taught = Kati.Media.Detect.taught(session)

    if taught do
      {taught, Kati.Media.Detect.episode_of(taught, session.title)}
    else
      Kati.Media.Detect.derive(session, shelf)
    end
  end

  @doc false
  @spec taught(map()) :: struct() | nil
  def taught(session) do
    aliases = TitleAlias.all()

    [Map.get(session, :album), Map.get(session, :title), Map.get(session, :subtitle)]
    |> Enum.flat_map(&Kati.Media.Detect.candidates/1)
    |> Enum.find_value(&Map.get(aliases, &1))
    |> case do
      nil -> nil
      id -> Kati.Media.Detect.on_shelf(id)
    end
  end

  @doc false
  def on_shelf(id) do
    case Ash.get(TrackedTitle, id) do
      {:ok, %TrackedTitle{archived: false} = tracked} -> tracked
      _gone_or_hidden -> nil
    end
  rescue
    _error -> nil
  end

  @doc false
  @spec derive(map(), map()) :: {struct(), String.t() | nil} | nil
  def derive(session, shelf) do
    # The album first, and the order is the point: a TV app puts the SERIES
    # there and the episode in `title`, so asking the album first means a
    # series is recognised as itself rather than by whichever of its episodes
    # happens to be named on the shelf.
    from_album = Kati.Media.Detect.lookup(shelf, Map.get(session, :album))
    from_title = Kati.Media.Detect.lookup(shelf, session.title)
    from_subtitle = Kati.Media.Detect.lookup(shelf, session.subtitle)

    case {from_album, from_title, from_subtitle} do
      {%{} = tracked, _t, _s} ->
        {tracked, Kati.Media.Detect.episode_of(tracked, session.title)}

      {nil, %{} = tracked, _s} ->
        {tracked, Kati.Media.Detect.episode_of(tracked, session.subtitle)}

      {nil, nil, %{} = tracked} ->
        {tracked, Kati.Media.Detect.episode_of(tracked, session.title)}

      {nil, nil, nil} ->
        nil
    end
  end

  @doc false
  @spec lookup(map(), String.t() | nil) :: struct() | nil
  def lookup(shelf, name) do
    name
    |> Kati.Media.Detect.candidates()
    |> Enum.find_value(&Map.get(shelf, &1))
  end

  @doc """
  The spellings of one announced name worth looking up, in order.

  The name as given, then the same name with a player's file noise taken off.
  Both are matched exactly; this widens what counts as *the same string*, not
  what counts as a match.

      iex> Kati.Media.Detect.candidates("Severance")
      ["severance"]

      iex> Kati.Media.Detect.candidates("Frieren.S01E05.1080p.WEB-DL.mkv")
      ["frieren.s01e05.1080p.web-dl.mkv", "frieren"]

      iex> Kati.Media.Detect.candidates("Blade_Runner_2049.mp4")
      ["blade_runner_2049.mp4", "blade runner 2049"]

      iex> Kati.Media.Detect.candidates(nil)
      []
  """
  @spec candidates(String.t() | nil) :: [String.t()]
  def candidates(name) when not is_binary(name), do: []

  def candidates(name) do
    raw = Kati.Import.Job.name_key(name)

    if raw == "" do
      []
    else
      Enum.uniq([raw, Kati.Media.Detect.unfile(raw)]) |> Enum.reject(&(&1 == ""))
    end
  end

  @doc """
  A filename read as the name of the thing inside it.

  Only the three transformations a media filename actually needs, and each is
  reversible in the head of whoever reads the result: drop a known extension,
  turn separators into spaces, and stop at the episode marker — everything
  after `S01E05` is the release, not the show.

  Nothing here guesses. A name with none of those features comes back
  unchanged, which is why this can be matched as strictly as the raw one.
  """
  @spec unfile(String.t()) :: String.t()
  def unfile(name) do
    name
    |> String.replace(~r/\.(mkv|mp4|avi|mov|m4v|webm|ts|wmv|flv|mpg|mpeg)$/, "")
    |> String.replace(~r/[._]+/, " ")
    |> String.split(~r/\bs\d\d?e\d\d?\b/, parts: 2)
    |> List.first()
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
    |> String.trim("-")
    |> String.trim()
  end

  @doc """
  The `episode_source_id` of an episode of `tracked` with that name, or `nil`.

  `nil` is an ordinary answer twice over: a film has no episodes, and a series
  whose episode names Kati has never fetched cannot place one. Both tick the
  title rather than nothing, which is what a `Kati.Media.Watch` with no
  `episode_source_id` already means.
  """
  @spec episode_of(struct(), String.t() | nil) :: String.t() | nil
  def episode_of(_tracked, name) when not is_binary(name) or name == "", do: nil

  def episode_of(%TrackedTitle{kind: :movie}, _name), do: nil

  def episode_of(tracked, name) do
    wanted = Kati.Import.Job.name_key(name)

    tracked.source
    |> Kati.Media.CachedEpisode.for_title(tracked.source_id)
    |> Enum.find(&(is_binary(&1.title) and Kati.Import.Job.name_key(&1.title) == wanted))
    |> case do
      nil -> nil
      episode -> episode.source_id
    end
  rescue
    _error -> nil
  end

  @doc """
  Write what `verdict/1` decided, once.

  Answers `{:ok, :ticked}`, `{:ok, :already}`, `{:ok, :asked}` or `:ignored`.
  `:already` is what makes this safe to call on every poll: a session sits
  above the threshold for the whole of the last ten minutes of an episode, and
  a detector that wrote on each pass would write forty watches for one evening.
  """
  @spec apply(map()) :: {:ok, atom()} | :ignored
  def apply(session) do
    case Kati.Media.Detect.verdict(session) do
      :ignore ->
        :ignored

      {:ask, title} ->
        {:ok, Kati.Media.Detect.ask(title)}

      {:tick, tracked, episode} ->
        if Kati.Media.Detect.ticked_already?(tracked, episode),
          do: {:ok, :already},
          else: Kati.Media.Detect.tick(tracked, episode)
    end
  end

  @doc false
  def ticked_already?(tracked, nil) do
    Watch
    |> Ash.Query.filter(tracked_title_id == ^tracked.id and watched_on == ^Kati.Time.today())
    |> Ash.read!()
    |> Enum.any?()
  rescue
    _error -> true
  end

  def ticked_already?(tracked, episode) do
    Watch
    |> Ash.Query.filter(tracked_title_id == ^tracked.id and episode_source_id == ^episode)
    |> Ash.read!()
    |> Enum.any?()
  rescue
    _error -> true
  end

  @doc false
  def tick(tracked, episode) do
    Watch
    |> Ash.Changeset.for_create(:create, %{
      tracked_title_id: tracked.id,
      episode_source_id: episode,
      # The column this feature needed and the reason it has one: without
      # provenance, `41 EPISODES TICKED FOR YOU` cannot be counted and a tick
      # Kati made is indistinguishable from one the reader tapped.
      detected: true,
      watched_at: DateTime.truncate(Kati.Time.now(), :second),
      watched_on: Kati.Time.today()
    })
    |> Ash.create()
    |> Kati.Media.Detect.restate(tracked, episode)
    |> case do
      {:ok, _watch} -> {:ok, :ticked}
      {:error, _reason} -> :ignored
    end
  end

  @doc """
  Move the title's status the way a tick by hand does.

  A detected tick was a watch row and nothing else, so a show Kati ticked for
  you stayed *not started* on the shelf and a film it logged never finished.
  An episode goes through `Kati.Screens.Series.restate/1`, a film through
  `Kati.Screens.Rating.finish_title/2` — the same two calls screens 04 and 33
  make, so a detected tick and a tapped one leave the same shelf.
  """
  @spec restate({:ok, struct()} | {:error, term()}, map(), String.t() | nil) ::
          {:ok, struct()} | {:error, term()}
  def restate({:ok, _watch} = written, tracked, nil),
    do: Kati.Screens.Rating.finish_title(written, tracked.id)

  def restate({:ok, _watch} = written, tracked, _episode) do
    Kati.Screens.Series.restate(tracked.id)
    written
  end

  def restate(other, _tracked, _episode), do: other

  @doc """
  Remember a title Kati could not place, so screen 36 can ask about it.

  In `Mob.State` rather than a resource, and deliberately: an unplaced name is
  a question about a session that has already ended, not a record of anything.
  A resource for it would be a table of strings nobody had asked to keep.
  """
  @spec ask(String.t()) :: atom()
  def ask(title) do
    queue = Kati.Media.Detect.unsure()

    unless title in queue do
      Mob.State.put(:detect_unsure, Enum.take([title | queue], 5))
      # And say so, rather than waiting to be found. A question nobody knows
      # about is a question nobody answers, and the reader has just finished
      # watching the thing it is about — which is the moment they can answer it
      # from memory. `Kati.Media.Detect.Notice` is the one notification this
      # feature sends, and it sends one per name.
      _ = Kati.Media.Detect.Notice.heard(title)
    end

    :asked
  rescue
    _no_state -> :asked
  end

  @doc "The names Kati has heard and could not place, newest first."
  @spec unsure() :: [String.t()]
  def unsure do
    case Mob.State.get(:detect_unsure, []) do
      list when is_list(list) -> list
      _unset -> []
    end
  rescue
    _no_state -> []
  end

  @doc "Forget one unplaced name — the reader has answered it."
  @spec resolve(String.t()) :: :ok
  def resolve(title) do
    Mob.State.put(:detect_unsure, Enum.reject(Kati.Media.Detect.unsure(), &(&1 == title)))
    _ = Kati.Media.Detect.Notice.answered(title)
    :ok
  rescue
    _no_state -> :ok
  end

  @doc """
  Connect a name Kati could not place to a title on the shelf.

  The answer to *there is no shared id*: the reader points, once, and
  `Kati.Media.TitleAlias` remembers. From then on that name matches without a
  question.

  It also **ticks it**, and that is not a bonus — the queue only ever holds
  names that already passed the threshold, so a reader answering this has told
  Kati two things: what it was, and that they watched it.
  """
  @spec connect(String.t(), String.t()) :: {:ok, atom()} | {:error, term()}
  def connect(heard, tracked_title_id) do
    with {:ok, _alias} <- TitleAlias.learn(heard, tracked_title_id),
         %TrackedTitle{} = tracked <- Kati.Media.Detect.on_shelf(tracked_title_id) do
      :ok = Kati.Media.Detect.resolve(heard)

      if Kati.Media.Detect.ticked_already?(tracked, nil),
        do: {:ok, :already},
        else: Kati.Media.Detect.tick(tracked, nil)
    else
      nil -> {:error, :gone}
      error -> error
    end
  end

  @doc """
  How many ticks Kati made rather than the reader.

  `41 EPISODES TICKED FOR YOU`, counted. Board 36 printed that number over a
  column that did not exist until `20260907060000_add_watch_detected`.
  """
  @spec detected_count() :: non_neg_integer()
  def detected_count do
    Watch
    |> Ash.Query.filter(detected == true)
    |> Ash.read!()
    |> length()
  rescue
    _error -> 0
  end

  @doc """
  Look at what is playing and act on it. Answers what it did, per session.

  The whole loop, and the only function anything outside this module needs.
  Off, or unallowed, and it does nothing at all — which is what a master switch
  has to mean.
  """
  @spec sweep() :: [{String.t(), atom()}]
  def sweep do
    if Kati.Media.Detect.on?() and Kati.Media.Detect.access() == :granted do
      Enum.map(Kati.Media.Detect.sessions(), fn session ->
        case Kati.Media.Detect.apply(session) do
          {:ok, what} -> {session.title, what}
          :ignored -> {session.title, :ignored}
        end
      end)
    else
      []
    end
  end

  @doc """
  Everything the listener recorded while Kati was not running, applied.

  The half of this feature that catches the case it exists for. See the
  moduledoc: a session is gone by the time Kati is next opened, so what is
  acted on here is what `KatiMediaListener` wrote down as it happened.

  Off, or unallowed, and it drains nothing and clears nothing — a reader who
  turns detection off must not find that the last hour was ticked anyway the
  next time they open the app.
  """
  @spec drain() :: [{String.t(), atom()}]
  def drain do
    if Kati.Media.Detect.on?() and Kati.Media.Detect.access() == :granted do
      Enum.map(Kati.Media.Detect.recorded(), fn session ->
        case Kati.Media.Detect.apply(session) do
          {:ok, what} -> {session.title, what}
          :ignored -> {session.title, :ignored}
        end
      end)
    else
      []
    end
  end

  @doc """
  What the listener wrote down, shaped like a live session.

  A recorded entry is a live one plus a `seen_at`, so everything downstream —
  `progress/1`, `verdict/1`, `match/1` — reads it unchanged. `playing?` is
  forced true because a recording IS a play: the listener only writes a session
  it heard, and the last state before one is destroyed is often `paused`, which
  is the player letting go rather than the reader stopping.
  """
  @spec recorded() :: [map()]
  def recorded do
    with {:ok, "ok:" <> json} <- Bridge.reply(:drain_sessions, []),
         {:ok, list} when is_list(list) <- decode(json) do
      list
      |> Enum.flat_map(&Kati.Media.Detect.session/1)
      |> Enum.map(&Map.put(&1, :playing?, true))
    else
      _nothing -> []
    end
  end

  @doc """
  The titles a heard name is probably about, for the card to offer.

  `Kati.Media.Detect.Near` ranks them and this is the only caller: a ranking
  that is allowed to be approximate must never reach `verdict/1`, which decides
  what gets ticked without anyone looking. These are suggestions on a card
  somebody is reading.

  `[]` is an ordinary answer and the card handles it — *Add it* and *Not mine*
  stand alone, and Kati does not pretend to a guess it does not have.
  """
  @spec suggestions_for(String.t()) :: [%{title: String.t(), tracked_id: String.t()}]
  def suggestions_for(heard) do
    Kati.Media.Detect.Near.ranked(heard, Kati.Media.Detect.rows())
    |> Enum.map(fn {tracked, cached, _score} ->
      %{
        title: Kati.Screens.Library.name_of(cached),
        tracked_id: tracked.id
      }
    end)
  rescue
    _error -> []
  end

  @doc false
  @spec rows() :: [{struct(), struct() | nil}]
  def rows do
    tracked =
      Enum.flat_map(@kinds, fn kind ->
        TrackedTitle
        |> Ash.Query.for_read(:shelf, %{kind: kind})
        |> Ash.read!()
      end)

    cached = CachedTitle |> Ash.read!() |> Map.new(&{{&1.source, &1.source_id}, &1})

    Enum.map(tracked, &{&1, Map.get(cached, {&1.source, &1.source_id})})
  rescue
    _error -> []
  end

  @doc false
  @spec shelf() :: %{String.t() => struct()}
  def shelf do
    tracked =
      Enum.flat_map(@kinds, fn kind ->
        TrackedTitle
        |> Ash.Query.for_read(:shelf, %{kind: kind})
        |> Ash.read!()
      end)

    cached = CachedTitle |> Ash.read!() |> Map.new(&{{&1.source, &1.source_id}, &1})

    for row <- tracked,
        name <- Kati.Media.Detect.names_of(row, Map.get(cached, {row.source, row.source_id})),
        into: %{},
        do: {Kati.Import.Job.name_key(name), row}
  rescue
    _error -> %{}
  end

  @doc """
  Every name a shelf row answers to.

  TMDB's own two — `title` and `title_original` — because one show has several
  names and the reader's player may announce either. `title_original` has been
  filled from `original_name` since the ingest was written and nothing has ever
  read it; this is the reader who needed it.

  A row whose cache has been evicted answers to its `source_id`, which for a
  hand-added or imported title IS the name — see `Kati.Screens.AddByHand`.
  """
  @spec names_of(struct(), struct() | nil) :: [String.t()]
  def names_of(row, cached) do
    case CachedTitle.names(cached) do
      [] -> [row.source_id]
      names -> names
    end
  end

  defp decode(json) do
    case :json.decode(json) do
      list when is_list(list) -> {:ok, list}
      _other -> :error
    end
  rescue
    _error -> :error
  end
end
