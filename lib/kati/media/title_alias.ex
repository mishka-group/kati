defmodule Kati.Media.TitleAlias do
  @moduledoc """
  A name the reader has told Kati is one of their titles.

  ## Why a table and not more cleverness

  Auto-detect matches what a player announces against the shelf **by name**,
  and it has to: Android's `MediaMetadata` carries `METADATA_KEY_MEDIA_ID`, but
  it is app-private — Netflix's `81234567` means nothing to Plex and nothing to
  TMDB — and no player publishes a TMDB or IMDb id. There is no shared key to
  join on.

  Name matching is widened as far as it honestly can be:

    * `Kati.Media.CachedTitle.names/1` — TMDB's own two, so
      `Sousou no Frieren` finds `Frieren: Beyond Journey's End`;
    * `Kati.Media.Detect.unfile/1` — a filename read as the name of the thing
      inside it, so VLC's `Frieren.S01E05.1080p.mkv` finds the same show;
    * the album key, where a TV app puts the series while `title` carries the
      episode.

  None of that will ever be complete, and the alternative to admitting it is
  fuzzy matching — which would tick the wrong title, silently, in a watch
  history nobody audits. So the last resort is to **ask**, once, and remember.

  ## Asked once

  Kati says *I heard “X” and could not find it on your shelf*, in a local
  notification so the reader does not have to be looking; they point at the
  title; this row is written. From then on that name matches without a
  question, however many times it plays.

  Unique on `heard`, because one announced name means one title — teaching a
  new answer replaces the old rather than leaving two. Normalised with
  `Kati.Import.Job.name_key/1`, which is the comparison every other name in
  this domain uses.

  ## It is the reader's, not a cache

  `on_delete: :delete_all` against `Kati.Media.TrackedTitle`: an alias for a
  title that is no longer on the shelf is an answer to a question nobody will
  ask again. Everything else about it is durable — it is in backups, and
  `Kati.Media.Cache.clear/0` does not touch it, because what somebody taught
  Kati is not something Kati fetched.
  """
  use Ash.Resource, domain: Kati.Media, data_layer: AshSqlite.DataLayer

  require Ash.Query

  sqlite do
    table "media_title_aliases"
    repo Kati.Repo

    custom_indexes do
      index [:heard], unique: true
    end
  end

  attributes do
    uuid_primary_key :id

    @doc "The announced name, normalised by `Kati.Import.Job.name_key/1`."
    attribute :heard, :string, allow_nil?: false, public?: true

    timestamps()
  end

  relationships do
    belongs_to :tracked_title, Kati.Media.TrackedTitle do
      allow_nil? false
      public? true
    end
  end

  actions do
    defaults [:read, :destroy, create: :*, update: :*]
  end

  # Teach Kati that this announced name is that title.
  #
  # Replaces any previous answer for the same name rather than adding a second:
  # a reader correcting themselves is answering the same question again.
  @spec learn(String.t(), String.t()) :: {:ok, t()} | {:error, term()}
  def learn(heard, tracked_title_id) when is_binary(heard) and is_binary(tracked_title_id) do
    key = Kati.Import.Job.name_key(heard)

    if key == "" do
      {:error, :nothing_heard}
    else
      _ = Kati.Media.TitleAlias.forget(key)

      __MODULE__
      |> Ash.Changeset.for_create(:create, %{heard: key, tracked_title_id: tracked_title_id})
      |> Ash.create()
    end
  end

  @doc "Drop the answer for one announced name."
  @spec forget(String.t()) :: :ok
  def forget(heard) when is_binary(heard) do
    __MODULE__
    |> Ash.Query.filter(heard == ^Kati.Import.Job.name_key(heard))
    |> Ash.read!()
    |> Enum.each(&Ash.destroy!/1)

    :ok
  rescue
    _error -> :ok
  end

  @doc """
  Every taught name, as `normalised heard name => tracked_title_id`.

  One read, because `Kati.Media.Detect.match/1` asks it for every session and a
  query per candidate would be a query per media event.
  """
  @spec all() :: %{String.t() => String.t()}
  def all do
    __MODULE__
    |> Ash.read!()
    |> Map.new(&{&1.heard, &1.tracked_title_id})
  rescue
    _error -> %{}
  end
end
