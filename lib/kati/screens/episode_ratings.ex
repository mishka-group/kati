defmodule Kati.Screens.EpisodeRatings do
  @moduledoc """
  Screen 143 — one season's episodes and the rating you gave each.

  Built to `test/design/reference/143.html`, the board that settled what the
  trailing rating column on an episode row looks like. That column has
  shipped: `Kati.Screens.Series` and `Kati.Screens.Season` draw it beside
  every aired episode and open screen 144 over the one you tapped. This page
  is the same column read on its own — the season, how many of its episodes
  you have rated, and each row with its verdict.

  ## Where the data comes from

  `Kati.Screens.Season.season/1`, the read screen 34 makes: the push names the
  show and the season (`:title_id`, `:season`), and a bare push is the newest
  series at its own bookmark. Every row, tick and rating is the reader's —
  `Kati.Media.CachedEpisode` for the running order and `Kati.Media.Watch` for
  the ticks and the ratings. A shelf with no series, a show with no episode
  list and an id that names nothing each draw one sentence and nothing to
  press.

  It used to draw the board itself: *The Long Hollow*, six invented episodes
  with invented ratings, a hint card about a long press Mob cannot perform and
  a memo about a gesture no screen has (N52-A).

  ## The column is a numeral and ONE star, never five

  The board's own caption: *"A numeral plus one star, in DM Mono, so the
  column aligns — nobody reads five small stars, they read a shape."*
  `rating_node/1` is that column, and `rating_label/1` the one place a rating
  becomes its numeral — `4.5`, `5`, never `5.0`. Both are what screens 04 and
  34 call, so the three pages cannot disagree about what a rating looks like.

  An aired episode you have not rated carries the hollow star screen 34 draws
  there — the door onto screen 144 — and one that has not aired carries
  nothing: there is no opinion to have yet.
  """

  use Kati.Screens.Pushed, back: "Library"
  use Gettext, backend: Kati.Gettext

  alias Kati.Theme
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  @impl true
  def load(socket), do: Mob.Socket.assign(socket, :season, season_for(socket))

  @doc """
  Coming back from screen 144, where a rating may have changed: read the season
  again.
  """
  @impl true
  def handle_kati(:resumed, _payload, socket),
    do: {:noreply, Mob.Socket.assign(socket, :season, season_for(socket))}

  def handle_kati(_topic, _payload, socket), do: {:noreply, socket}

  @impl true
  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "rate_" <> index -> {:noreply, Kati.Screens.Season.rate(socket, index)}
      _other -> {:noreply, socket}
    end
  end

  defp season_for(socket) do
    params = socket.assigns.params || %{}

    season =
      Kati.Screens.Season.season(%{
        title_id: Map.get(params, :title_id),
        season: Map.get(params, :season)
      })

    Map.put(season, :show, show_title(Map.get(season, :tracked_id)))
  end

  # The show's own name, out of the release cache — `Untitled` for a row whose
  # cache entry has gone, and nothing for a page with no show.
  defp show_title(id) when is_binary(id) do
    case Kati.Screens.SeriesSettings.tracked(id) do
      nil -> ""
      tracked -> Kati.Screens.SeriesSettings.title_of(tracked)
    end
  end

  defp show_title(_none), do: ""

  @doc """
  The params that open this page over one season of a show.

      iex> Kati.Screens.EpisodeRatings.params_for(%{tracked_id: "abc", current_season: "S2"})
      %{title_id: "abc", season: 2}

      iex> Kati.Screens.EpisodeRatings.params_for(%{})
      %{}
  """
  @spec params_for(map() | nil) :: map()
  defdelegate params_for(series), to: Kati.Screens.Season

  @doc """
  `3 of 8 rated` — how many of the season's episodes carry your verdict.

      iex> Kati.Screens.EpisodeRatings.rated_line([%{rating: 4.5}, %{rating: nil}])
      "1 of 2 rated"
  """
  @spec rated_line([map()]) :: String.t()
  def rated_line(episodes) do
    gettext("%{rated} of %{total} rated",
      rated: Kati.Locale.number(Enum.count(episodes, &is_number(Map.get(&1, :rating)))),
      total: Kati.Locale.number(length(episodes))
    )
  end

  @doc """
  `SEASON 2 · 3 OF 6 RATED` — which season, and how much of it you have rated.

      iex> Kati.Screens.EpisodeRatings.meta_line("Season 2", [%{rating: 4.5}, %{rating: nil}])
      "SEASON 2 · 1 OF 2 RATED"
  """
  @spec meta_line(String.t(), [map()]) :: String.t()
  def meta_line(season, episodes),
    do: UI.eyebrow_label(season <> " · " <> Kati.Screens.EpisodeRatings.rated_line(episodes))

  @doc false
  @spec content(map()) :: map()
  def content(%{season: %{gone?: true}}), do: Kati.Screens.SeriesSettings.gone_body()

  def content(%{season: %{none?: true} = s}) do
    assigns = %{
      line:
        if(Map.get(s, :tracked_id),
          do: Kati.Screens.Series.no_list_label(),
          else: gettext("No series in your library yet")
        )
    }

    ~MOB"""
    <Scroll>
      <Column fill_width={true} padding_left={21} padding_right={21} padding_top={110}>
        <Spacer size={30} />
        {Kati.UI.symbol("star", size: 28, color: Palette.sub())}
        <Spacer size={14} />
        <Text
          text={@line}
          text_size={22}
          font_weight="bold"
          line_height={1.25}
          text_color={:on_surface}
        />
      </Column>
    </Scroll>
    """
  end

  def content(assigns) do
    s = assigns.season

    rows =
      s.episodes
      |> Enum.with_index()
      |> Enum.map(fn {ep, i} -> Map.put(ep, :index, i) end)

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
        {Kati.Screens.EpisodeRatings.header(
          Map.get(s, :show, ""),
          Kati.Screens.EpisodeRatings.meta_line(s.title, s.episodes)
        )}
        {UI.eyebrow(gettext("Episodes"))}
        {Kati.Screens.EpisodeRatings.episode_list(rows)}
      </Column>
    </Scroll>
    """
  end

  @doc false
  def header(title, meta) do
    assigns = %{title: title, meta: meta}

    ~MOB"""
    <Column fill_width={true}>
      <Text
        text={@title}
        text_size={28}
        max_font_scale={1.6}
        font_weight="bold"
        letter_spacing={Kati.Locale.tracking(-0.03)}
        text_color={:on_surface}
        max_lines={1}
      />
      <Spacer size={6} />
      <Text
        text={@meta}
        font_family={Kati.Locale.mono_face(@meta)}
        text_size={11.5}
        text_color={Palette.muted()}
        max_lines={1}
      />
      <Spacer size={20} />
    </Column>
    """
  end

  @doc false
  def episode_list(rows) do
    ~MOB"""
    <Column fill_width={true}>
      {rows
       |> Enum.map(fn ep -> Kati.Screens.EpisodeRatings.episode_row(ep) end)
       |> Enum.intersperse(Kati.Screens.EpisodeRatings.episode_gap())}
    </Column>
    """
  end

  @doc false
  def episode_gap, do: ~MOB"<Spacer size={8} />"

  @doc """
  One episode: its number in the show's own order, its name and sub-line as
  screen 34 builds them, the rating column, and the tick.

  Both mono lines ask `Kati.Locale.mono_face/1` about their own string:
  `kati_mono.ttf` carries no Persian glyph, so `ق۱` in DM Mono is an empty box.
  """
  def episode_row(ep) do
    bg = if ep.watched, do: Palette.card_settled(), else: Palette.card()
    shadow = if ep.watched, do: nil, else: Theme.shadow_card_soft()
    title_color = if ep.watched, do: Palette.settled_ink(), else: :on_surface

    ~MOB"""
    <Row
      fill_width={true}
      background={bg}
      shadow={shadow}
      corner_radius={17}
      padding_left={15}
      padding_right={15}
      padding_top={13}
      padding_bottom={13}
      align="center"
    >
      <Column width={22}>
        <Text
          text={ep.number}
          font_family={Kati.Locale.mono_face(ep.number)}
          text_size={12}
          text_color={Palette.tertiary()}
          max_lines={1}
        />
      </Column>
      <Spacer size={13} />
      <Column weight={1.0}>
        <Text
          text={ep.title}
          text_size={14}
          font_weight="semibold"
          letter_spacing={Kati.Locale.tracking(-0.01)}
          text_color={title_color}
          max_lines={1}
        />
        <Spacer size={4} />
        <Text
          text={ep.sub}
          font_family={Kati.Locale.mono_face(ep.sub)}
          text_size={10.5}
          text_color={Palette.tertiary()}
          max_lines={1}
        />
      </Column>
      {Kati.Screens.Season.rating_column(ep)}
      <Spacer size={13} />
      {Kati.Screens.EpisodeRatings.check(ep.watched)}
    </Row>
    """
  end

  @doc """
  The rating column itself: a numeral and one star, or nothing at all.

  A list, not a `Column`: the sigil flattens an interpolated list into its
  parent, so a `nil` rating contributes zero nodes and the row's own 13pt gap
  closes straight from the title column to the check.
  """
  @spec rating_node(float() | nil) :: [map()]
  def rating_node(nil), do: []

  def rating_node(rating) do
    label = rating_label(rating)

    [
      ~MOB"<Spacer size={13} />",
      ~MOB"""
      <Row align="center">
        <Text
          text={label}
          font_family={Kati.Locale.mono_face(label)}
          text_size={12}
          text_color={Palette.meta()}
          max_lines={1}
        />
        <Spacer size={3} />
        {Kati.UI.symbol("star", size: 11, color: Palette.accent(), fill: true)}
      </Row>
      """
    ]
  end

  @doc """
  `4.5`, `5`, `3.5` — never `5.0` — or `9`, `10`, `7` on the ten-point scale
  screen 33 lets a reader choose. `Kati.Rating.Scale` is the one place a
  rating becomes text.
  """
  @spec rating_label(float()) :: String.t()
  defdelegate rating_label(rating), to: Kati.Rating.Scale, as: :label

  @doc """
  The 27pt check: ink-filled when watched, or a hairline ring otherwise.
  """
  @spec check(boolean()) :: map()
  def check(true) do
    ~MOB"""
    <Box width={27} height={27} corner_radius={14} background={Palette.ink_fill()} align="center">
      {Kati.UI.symbol("check", size: 16, color: Palette.on_ink())}
    </Box>
    """
  end

  def check(false) do
    ~MOB"""
    <Box
      width={27}
      height={27}
      corner_radius={14}
      border_width={1.5}
      border_color={Palette.border()}
      align="center"
    >
      {Kati.UI.symbol("check", size: 16, color: Palette.ink_invisible())}
    </Box>
    """
  end
end
