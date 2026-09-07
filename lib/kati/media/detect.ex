defmodule Kati.Media.Detect do
  @moduledoc """
  Noticing what you played, so you do not have to tell Kati twice.

  MOVIES-AND-TV.md #100. Screen 36 is the argument for this feature drawn in
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
    * **it ticks nothing it matched loosely.** The name has to match a shelf
      title exactly, case and whitespace aside — `Kati.Import.Job.name_key/1`'s
      rule, and for its reason: `Se7en` and `Seven` are two films.
    * **an ambiguous session becomes a question**, not a tick. That is the card
      board 36 is arranged around and the sentence it gives for it: *a wrong
      tick pollutes a watch history nobody audits.*

  ## The threshold, and why it is a threshold

  A session is a tick when it passes `threshold/0` of its duration — 90% by
  default, which is board 36's own number. Not at the end, because nobody
  watches the credits; not at the start, because opening something is not
  watching it.

  A session with no duration cannot pass a percentage of it and is never a
  tick. Live television and a browser tab are both that, and both are things a
  reader would be angry to find in their history.

  ## Nothing here polls

  This module is pure but for one bridge read. What calls it is screen 36 while
  it is open, and `Kati.Media.Detect.Sweep` on the periodic worker — a screen
  that polled would stop when it closed, which is every moment that matters.
  """

  require Ash.Query

  alias Kati.Media.CachedTitle
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
    title = Kati.Import.Job.name_key(session.title)
    subtitle = Kati.Import.Job.name_key(session.subtitle || "")

    case {Map.get(shelf, title), Map.get(shelf, subtitle)} do
      {%{} = tracked, _either} ->
        {tracked, Kati.Media.Detect.episode_of(tracked, session.subtitle)}

      {nil, %{} = tracked} ->
        {tracked, Kati.Media.Detect.episode_of(tracked, session.title)}

      {nil, nil} ->
        nil
    end
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
    |> case do
      {:ok, _watch} -> {:ok, :ticked}
      {:error, _reason} -> :ignored
    end
  end

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
    :ok
  rescue
    _no_state -> :ok
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

    Map.new(tracked, fn row ->
      name =
        case Map.get(cached, {row.source, row.source_id}) do
          %CachedTitle{title: title} when is_binary(title) and title != "" -> title
          _evicted -> row.source_id
        end

      {Kati.Import.Job.name_key(name), row}
    end)
  rescue
    _error -> %{}
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
