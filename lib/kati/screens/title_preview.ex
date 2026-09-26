defmodule Kati.Screens.TitlePreview do
  @moduledoc """
  A TMDB title the reader does not keep, drawn on its own page before it is
  added (N55).

  Screen 19's *On TMDB* rows and screen 06's results opened nothing unless the
  title was already on the shelf, so the only way to learn what a search hit
  was about was to add it. Now the row body pushes screen 08 or 04 with

      %{preview: %{source: :tmdb, source_id: id, kind: :movie | :tv, title: t}, back: …}

  and the page draws the title from `Kati.Media.CachedTitle` alone: poster,
  title, year, runtime, genres, the overview, where to watch, and for a series
  its seasons and episodes read-only. Everything that is about the reader's own
  history — the rating card, the seen count, ticks, the ⋯ menu, *Mark next
  watched* — needs a `Kati.Media.TrackedTitle` and is not drawn. One ink pill,
  *Add to library*, is what makes it one.

  ## The cache is not the library

  `Kati.Media.Tmdb.fetch/2` writes the cached rows and nothing the reader
  decided, so previewing a title leaves no mark on the shelf, on Up next or in
  search's library hits — every one of those joins to a tracked row. The fetch
  runs in a task under `Kati.TaskSupervisor` and answers the screen with
  `{:title_preview, source_id, result}`, so a slow radio holds a *Loading* line
  on the page and never the mount. A title already cached draws at once.

  ## Adding

  `Kati.Screens.AddTitle.track/3`, screen 06's own write, as `:not_started`.
  The page then reloads as the tracked page in place, and the screen underneath
  re-reads on the way back (`Kati.Screens.Resume`), so the row it came from is
  ticked. A title that turns out to be tracked already — added elsewhere while
  this page was open — opens as the tracked page rather than being added twice.
  """
  use Gettext, backend: Kati.Gettext
  import Mob.Sigil

  require Ash.Query

  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Theme.Palette

  @typedoc "The preview on a title page's socket."
  @type t :: %{
          source: :tmdb,
          source_id: String.t(),
          kind: :movie | :tv,
          title: String.t() | nil,
          status: :loading | :ready | :error,
          reason: term(),
          save_error: String.t() | nil
        }

  @doc """
  The params that open `row` as a preview, pushed onto its own page.

  `back` is the English catalogue key the pill translates, as every push in the
  app hands it (`Kati.Screens.Pushed.back_label/2`).
  """
  @spec push(Mob.Socket.t(), map(), String.t()) :: Mob.Socket.t()
  def push(socket, row, back) do
    Mob.Socket.push_screen(
      socket,
      Kati.Search.OnTmdb.destination(row),
      Kati.Screens.TitlePreview.params(row, back)
    )
  end

  @doc """
  What a push to screen 08 or 04 carries for a TMDB row.

      iex> Kati.Screens.TitlePreview.params(%{source_id: "329865", kind: :movie, title: "Arrival"}, "Search")
      %{preview: %{source: :tmdb, source_id: "329865", kind: :movie, title: "Arrival"}, back: "Search"}
  """
  @spec params(map(), String.t()) :: map()
  def params(row, back) do
    %{
      preview: %{
        source: :tmdb,
        source_id: row.source_id,
        kind: row.kind,
        title: Map.get(row, :title)
      },
      back: back
    }
  end

  @doc """
  What a title page's params ask for.

    * `{:tracked, id}` — the preview names a title the reader already keeps,
      so the page is the ordinary one.
    * `{:preview, state}` — a title nobody keeps. Already cached, it is
      `:ready`; otherwise it is `:loading` and the fetch is under way, or
      `:error` straight away when there is no token to fetch with.
    * `:none` — no preview asked for, or one that names nothing usable.
  """
  @spec open(map() | nil) :: {:tracked, String.t()} | {:preview, t()} | :none
  def open(params) do
    case Map.get(params || %{}, :preview) do
      %{source: :tmdb, source_id: id, kind: kind} = asked
      when is_binary(id) and id != "" and kind in [:movie, :tv] ->
        case Kati.Screens.TitlePreview.tracked_id(:tmdb, id) do
          nil -> {:preview, Kati.Screens.TitlePreview.start(asked)}
          tracked -> {:tracked, tracked}
        end

      _nothing ->
        :none
    end
  end

  @doc false
  @spec start(map()) :: t()
  def start(asked) do
    state = %{
      source: :tmdb,
      source_id: asked.source_id,
      kind: asked.kind,
      title: text_or_nil(Map.get(asked, :title)),
      status: :loading,
      reason: nil,
      save_error: nil
    }

    cached = Kati.Screens.TitlePreview.cached(state)

    cond do
      cached && Kati.Screens.TitlePreview.artwork_ready?(cached) ->
        %{state | status: :ready}

      cached && Kati.Media.Tmdb.usable?() ->
        Kati.Screens.TitlePreview.fetch(self(), state)
        %{state | status: :ready}

      cached ->
        %{state | status: :ready}

      Kati.Media.Tmdb.usable?() ->
        Kati.Screens.TitlePreview.fetch(self(), state)
        state

      true ->
        %{state | status: :error, reason: :no_api_key}
    end
  end

  @doc """
  Download the poster a preview draws, the way adding a title does.

  `Kati.Media.Tmdb.fetch/2` writes the cached row and nothing else, and the
  page draws artwork only from a file on the phone — so a preview opened on a
  title nobody had added showed an empty hero (the Galaxy A55, 26 Sep).
  """
  @spec artwork(CachedTitle.t() | nil) :: :ok
  def artwork(%{poster_path: path}) when is_binary(path) do
    _downloaded = Kati.Media.Artwork.cache(path)
    :ok
  end

  def artwork(_none), do: :ok

  @doc false
  @spec artwork_ready?(CachedTitle.t()) :: boolean()
  def artwork_ready?(%{poster_path: path}) when is_binary(path),
    do: not is_nil(Kati.Media.Artwork.local(path))

  def artwork_ready?(_no_poster), do: true

  @doc "Whether a title page's assigns hold a preview rather than a tracked title."
  @spec previewing?(map()) :: boolean()
  def previewing?(assigns), do: is_map(Map.get(assigns, :preview))

  @doc "The tracked row's id for `{source, source_id}`, or `nil`."
  @spec tracked_id(atom(), String.t()) :: String.t() | nil
  def tracked_id(source, source_id) do
    TrackedTitle
    |> Ash.Query.filter(source == ^source and source_id == ^source_id)
    |> Ash.read!()
    |> Enum.map(& &1.id)
    |> List.first()
  rescue
    _error -> nil
  end

  @doc "The cached row a preview draws from, or `nil`."
  @spec cached(t()) :: CachedTitle.t() | nil
  def cached(%{source: source, source_id: source_id}) do
    CachedTitle
    |> Ash.Query.filter(source == ^source and source_id == ^source_id)
    |> Ash.read!()
    |> List.first()
  rescue
    _error -> nil
  end

  @doc """
  Fetch the title into the cache off the caller's process, answering `pid`
  with `{:title_preview, source_id, result}`.

  Supervised when `Kati.TaskSupervisor` is running and plainly spawned when it
  is not, for `Kati.Search.OnTmdb.fetch/3`'s reason.
  """
  @spec fetch(pid(), t()) :: :ok
  def fetch(pid, state) when is_pid(pid) do
    work = fn ->
      send(pid, {:title_preview, state.source_id, Kati.Screens.TitlePreview.fetched(state)})
    end

    try do
      Task.Supervisor.start_child(Kati.TaskSupervisor, work)
      :ok
    catch
      :exit, _reason ->
        spawn(work)
        :ok
    end
  end

  @doc false
  @spec fetched(t()) :: {:ok, map()} | {:error, term()}
  def fetched(state) do
    case Kati.Media.Tmdb.fetch(state.source_id, state.kind) do
      {:ok, _written} = found ->
        Kati.Screens.TitlePreview.artwork(Kati.Screens.TitlePreview.cached(state))
        found

      other ->
        other
    end
  rescue
    error -> {:error, {:network, error}}
  end

  @doc """
  The fetch coming back, put on the socket under `key` through `build`.

  Only for the preview still on the page: an answer for a title the reader has
  left is dropped. A page already drawn from the cache takes the answer as a
  redraw — its poster has just been downloaded — and keeps what it drew if
  the fetch failed.
  """
  @spec answered(Mob.Socket.t(), atom(), String.t(), term(), (CachedTitle.t() -> map())) ::
          Mob.Socket.t()
  def answered(socket, key, source_id, result, build) do
    case Map.get(socket.assigns, :preview) do
      %{source_id: ^source_id, status: :ready} = state ->
        case {result, Kati.Screens.TitlePreview.cached(state)} do
          {{:ok, _written}, %CachedTitle{} = row} -> Mob.Socket.assign(socket, key, build.(row))
          _kept -> socket
        end

      %{source_id: ^source_id, status: :loading} = state ->
        case {result, Kati.Screens.TitlePreview.cached(state)} do
          {{:ok, _written}, %CachedTitle{} = row} ->
            socket
            |> Mob.Socket.assign(:preview, %{state | status: :ready})
            |> Mob.Socket.assign(key, build.(row))

          {{:error, reason}, _row} ->
            Mob.Socket.assign(socket, :preview, %{state | status: :error, reason: reason})

          {_answer, nil} ->
            Mob.Socket.assign(socket, :preview, %{state | status: :error, reason: :not_found})
        end

      _other ->
        socket
    end
  end

  @doc """
  *Add to library*: the title tracked through screen 06's own write, and the
  page reloaded as the tracked page under `key` through `load`.

  A refusal stays on the preview as `Kati.Write.message/1`'s sentence, over
  the pill that was pressed.
  """
  @spec add(Mob.Socket.t(), atom(), (String.t() -> map())) :: Mob.Socket.t()
  def add(socket, key, load) do
    case Map.get(socket.assigns, :preview) do
      %{status: :ready} = state ->
        title = Map.get(Map.get(socket.assigns, key) || %{}, :title) || state.title || ""

        case Kati.Screens.TitlePreview.track(state, title) do
          {:ok, id} ->
            socket
            |> Mob.Socket.assign(:preview, nil)
            |> Mob.Socket.assign(:id, id)
            |> Mob.Socket.assign(key, load.(id))

          {:error, _reason} = error ->
            Mob.Socket.assign(socket, :preview, %{state | save_error: Kati.Write.message(error)})
        end

      _not_ready ->
        socket
    end
  end

  @doc false
  @spec track(t(), String.t()) :: {:ok, String.t()} | {:error, term()}
  def track(state, title) do
    case Kati.Screens.TitlePreview.tracked_id(state.source, state.source_id) do
      nil ->
        row = %{source: :tmdb, source_id: state.source_id, kind: state.kind}

        case Kati.Screens.AddTitle.track(title, row, :not_started) do
          {:ok, tracked} -> {:ok, tracked.id}
          error -> error
        end

      id ->
        {:ok, id}
    end
  end

  @doc """
  A return to a preview page: the ordinary page if the title was added from
  somewhere above it, and the preview as it was otherwise.
  """
  @spec resumed(Mob.Socket.t(), atom(), (String.t() -> map())) :: Mob.Socket.t()
  def resumed(socket, key, load) do
    state = socket.assigns.preview

    case Kati.Screens.TitlePreview.tracked_id(state.source, state.source_id) do
      nil ->
        socket

      id ->
        socket
        |> Mob.Socket.assign(:preview, nil)
        |> Mob.Socket.assign(:id, id)
        |> Mob.Socket.assign(key, load.(id))
    end
  end

  @doc """
  The ink pill that adds the title, with the refusal of an add that did not
  land above it — `Kati.UI.Sheet.commit/2`, the button screen 154 adds a title
  with.
  """
  @spec add_pill(String.t() | nil) :: map()
  def add_pill(save_error) do
    assigns = %{
      notice: Kati.UI.notice(save_error),
      pill: Kati.UI.Sheet.commit(gettext("Add to library"), :add_to_library)
    }

    ~MOB"""
    <Column fill_width={true}>
      {@notice}
      {@pill}
    </Column>
    """
  end

  @doc """
  The overview under its eyebrow, or nothing when TMDB gave none.

      iex> Kati.Screens.TitlePreview.overview(nil)
      []
  """
  @spec overview(String.t() | nil) :: map() | []
  def overview(nil), do: []
  def overview(""), do: []

  def overview(text) do
    assigns = %{text: text}

    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={22} />
      {Kati.UI.eyebrow(gettext("Overview"))}
      <Text
        text={@text}
        text_size={14}
        line_height={Kati.Locale.leading(1.55)}
        text_color={Palette.ink_soft()}
      />
    </Column>
    """
  end

  @doc """
  The floating chrome of a preview: the back pill alone. The ⋯ beside it on a
  tracked page holds nothing that can act on a title nobody keeps.
  """
  @spec chrome(String.t()) :: map()
  def chrome(back) do
    ~MOB"""
    <Box fill_width={true} fill_height={true} align="top">
      <Row fill_width={true} padding_left={21} padding_right={21} padding_top={60} align="center">
        {Kati.Screens.Film.back_control(back)}
      </Row>
    </Box>
    """
  end

  @doc """
  The page while the title is on its way, or when it could not be fetched:
  the name the row carried, and *Loading* or `Kati.Media.Tmdb.message/1`'s
  sentence. The back pill works in both.
  """
  @spec waiting(module(), t(), String.t()) :: map()
  def waiting(module, state, back) do
    assigns = %{
      identity: Kati.Screens.Identity.of(module),
      glyph: if(state.kind == :movie, do: "movie", else: "live_tv"),
      title: Kati.Screens.TitlePreview.heading(state),
      line: Kati.Screens.TitlePreview.status_line(state),
      back: back
    }

    ~MOB"""
    <Box
      fill_width={true}
      fill_height={true}
      background={:background}
      layout_direction={Kati.Locale.direction_prop()}
      font_family={Kati.Locale.face_prop()}
      accessibility_id={@identity}
    >
      <Column fill_width={true} padding_left={21} padding_right={21} padding_top={140}>
        {Kati.UI.symbol(@glyph, size: 28, color: Palette.sub())}
        <Spacer size={14} />
        <Text
          text={@title}
          text_size={22}
          font_weight="bold"
          line_height={1.25}
          text_color={:on_surface}
        />
        <Spacer size={12} />
        {@line}
      </Column>
      {Kati.Screens.TitlePreview.chrome(@back)}
    </Box>
    """
  end

  @doc false
  @spec heading(t()) :: String.t()
  def heading(%{title: title}) when is_binary(title), do: title
  def heading(_state), do: gettext("Untitled")

  @doc false
  @spec status_line(t()) :: map()
  def status_line(%{status: :error, reason: reason}),
    do: Kati.UI.notice(Kati.Media.Tmdb.message(reason))

  def status_line(_loading) do
    ~MOB"""
    <Text text={gettext("Loading from TMDB…")} text_size={13} text_color={Palette.sub()} />
    """
  end

  defp text_or_nil(text) when is_binary(text) and text != "", do: text
  defp text_or_nil(_other), do: nil
end
