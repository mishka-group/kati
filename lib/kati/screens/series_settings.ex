defmodule Kati.Screens.SeriesSettings do
  @moduledoc """
  Screen 35 — per-show settings, pushed under Series.

  Built to `test/design/screens/35.html`. Grouped lists in the usual card
  rhythm, over one thing that is not a list: the **Status** row, where
  watching / paused / dropped are three tiles of equal weight with one filled
  ink. The design's caption is explicit that this is the point — state as "a
  first-class choice rather than a swipe action" — so it is drawn as a choice
  and not as a switch with a hidden third value.

  No dock — this is a pushed screen — so the frame closes at 40, not 132.

  ## Three faces, decided by the push

  `show/1` reads `:tracked_id` off the push and answers one of three maps:

    * **A real show.** Every row is that show's own column or the reader's own
      device setting, and every row writes or opens something. See below.
    * **A show that has gone.** The id named a row that is no longer there —
      removed on screen 04 while this page sat under it, or a stale push. The
      page says so, in `Kati.Screens.Film.gone/2`'s sentence, and draws nothing
      that could write onto a row that is not there. It used to fall to the
      board, which put *Long Hollow*'s eleven rows in front of a reader who had
      just removed their own show.
    * **No show named at all.** The design fallback: board 35 whole, from
      `Kati.SeriesSettings.Sample`, with no tap on any tile or switch. Nothing
      in the app pushes this page bare — screen 04's ⋯ and
      `Kati.Screens.ShowPages` always name the show — so only the gallery, the
      sweeps and `Kati.ScreenDesignLiteralTest` see it.

  ## What a real show draws, and where each value comes from

    * **Status** — three tiles lit from `Kati.Media.TrackedTitle.status`, each
      writing its own value (`write/2`).
    * **Season pass** — two switches, `notify_new_episodes` and
      `hide_unwatched_titles`, each flipping its own column. Both have readers:
      the first is `Kati.Media.Release.alarm_at/3`'s per-show gate behind the
      bell's inbox, the second is screen 04's spoiler-safe episode names and
      screen 144's headline. The first one's sub-line says so when the global
      *New episodes* switch in the Release watcher has turned every show off.
    * **Region & availability** — the reader's country
      (`Kati.Services.chosen_region/0`) and the services they pay for
      (`Kati.Services.subscribed_names/0`), which are what decide what screen
      14's *Where to watch* says about this show. Each row opens the page that
      sets it — screen 94 and screen 92 — and `handle_kati/3` re-reads both
      when the reader comes back.

  ## What a real show does not draw, and why

  Board 35 draws four more rows and a whole group that have nothing behind
  them, and a row that shows a setting nothing stores or nothing reads is a
  picture of a setting:

    * *Auto-add new seasons* and *Put air dates on calendar* sit over
      `auto_add_new_seasons` and `add_air_dates_to_calendar`, which the store
      keeps and nothing in the app reads — seasons arrive with every cache
      refresh whatever the switch says, and no calendar feed draws air dates.
      A switch that flips a column nothing consults is a control that does
      nothing, so both rows are left off until something reads them.
    * *Watch for price drops* and *Preferred quality* have no column and no
      reader anywhere.
    * **This show** — reset, archive, remove. Removing is on screen 04's own ⋯
      behind a confirmation; reset has no writer; and archiving would take the
      show off `:shelf`, which every page under it reads through, so the page
      the reader came from would answer that the show had gone.

  The write rule is screen 34's: the control follows the store, so a switch
  moves only after `write/2`'s update answers.

  ## Words

  Chrome and the real rows' copy are this file's `gettext/1` calls. The board
  fallback's words are `Kati.SeriesSettings.Sample`'s, wrapped where they are
  declared; the two share msgids wherever they say the same thing, so a real
  show and the board cannot say different things in Persian. The show's own
  title is read out of the release cache and is not a msgid.

  `back: "Series"` stays the English label: `Kati.Screens.Pushed` translates a
  back-pill label at runtime through `Kati.Screens.Pushed.back_vocabulary/0`,
  which carries `Series` and `Show settings` both.
  """
  use Kati.Screens.Pushed, back: "Series"
  use Gettext, backend: Kati.Gettext

  alias Kati.Components.MishkaThemeIcon
  alias Kati.SeriesSettings.Sample
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  @pass_columns [:notify_new_episodes, :hide_unwatched_titles]

  @impl true
  def load(socket) do
    socket
    |> Mob.Socket.assign(:show, Kati.Screens.SeriesSettings.show(socket.assigns.params))
    |> Mob.Socket.assign(:menu?, false)
  end

  @doc """
  Coming back from the country picker, My services or a sibling page: read the
  show and the reader's region and services again, and close the ⋯.
  """
  @impl true
  def handle_kati(:resumed, _payload, socket) do
    {:noreply,
     socket
     |> Mob.Socket.assign(:show, Kati.Screens.SeriesSettings.show(socket.assigns.params))
     |> Mob.Socket.assign(:menu?, false)}
  end

  def handle_kati(_topic, _payload, socket), do: {:noreply, socket}

  @doc """
  The push screen 04's ⋯ sends: which show its *Show settings* row was over.

      iex> Kati.Screens.SeriesSettings.params_for(%{tracked_id: "abc"})
      %{tracked_id: "abc", back: "Series"}

      iex> Kati.Screens.SeriesSettings.params_for(%{})
      %{}
  """
  @spec params_for(map()) :: map()
  def params_for(%{tracked_id: id}) when is_binary(id), do: %{tracked_id: id, back: "Series"}
  def params_for(_row), do: %{}

  @doc """
  The show this page is about: the reader's, one that has gone, or none.

  See the moduledoc for the three faces. An id that names no row answers the
  empty page marked `gone?: true`, never the board.
  """
  @spec show(map() | nil) :: map()
  def show(params) do
    case Map.get(params || %{}, :tracked_id) do
      id when is_binary(id) ->
        case Kati.Screens.SeriesSettings.tracked(id) do
          nil -> Map.put(Kati.Screens.SeriesSettings.empty_show(), :gone?, true)
          tracked -> Kati.Screens.SeriesSettings.shaped(tracked)
        end

      _none ->
        Kati.Screens.SeriesSettings.empty_show()
    end
  end

  @doc """
  The page with no show on it: `shaped/1`'s keys, carrying nothing.

  `tracked: nil` is what sends every group to the board's own rows, which is
  the design fallback — see the moduledoc.
  """
  @spec empty_show() :: map()
  def empty_show do
    %{
      title: "",
      subtitle: gettext("show settings"),
      status_label: gettext("Status"),
      season_pass_label: gettext("Season pass"),
      region_label: nil,
      this_show_label: nil,
      region: nil,
      services: [],
      tracked: nil
    }
  end

  @doc false
  @spec tracked(String.t() | nil) :: struct() | nil
  def tracked(id) when is_binary(id) do
    case Ash.get(Kati.Media.TrackedTitle, id) do
      {:ok, tracked} -> tracked
      _gone -> nil
    end
  rescue
    _error -> nil
  end

  def tracked(_none), do: nil

  @doc """
  A real show, shaped for the page.

  The title is the release cache's, through `title_of/1`. `region` and
  `services` are the reader's own device settings, read here once rather than
  on every render, and read again by `handle_kati/3` on the way back from the
  pages that set them.
  """
  @spec shaped(struct()) :: map()
  def shaped(tracked) do
    %{
      title: Kati.Screens.SeriesSettings.title_of(tracked),
      subtitle: gettext("show settings"),
      status_label: gettext("Status"),
      season_pass_label: gettext("Season pass"),
      region_label: nil,
      this_show_label: nil,
      region: Kati.Services.chosen_region(),
      services: Kati.Services.subscribed_names(),
      tracked: tracked
    }
  end

  @doc """
  The show's name, out of the release cache through
  `Kati.Media.Release.cached_for/1` — the one place that stands in for the
  value-pair join between a tracked row and its cache row.

  A tracked row whose cache entry has been evicted still has settings worth
  changing, so it opens as *Untitled* rather than refusing to open. That word
  is Kati saying it does not know a name, so it is a msgid; a name out of
  somebody's library is not.
  """
  @spec title_of(struct()) :: String.t()
  def title_of(tracked) do
    case Kati.Media.Release.cached_for(tracked) do
      %{title: title} when is_binary(title) and title != "" -> title
      _evicted -> gettext("Untitled")
    end
  rescue
    _error -> gettext("Untitled")
  end

  @doc """
  The season pass: the board's four switches as pictures, or a real show's
  two live ones.

  Each live row's tap is on the whole 44pt row, the shape screen 25 settled,
  and is built from the column's own name so `change_for/2` can read it back.
  """
  @spec season_pass(map()) :: [map()]
  def season_pass(%{tracked: nil}), do: Sample.season_pass()

  def season_pass(%{tracked: t}) do
    [
      %{
        icon: "notifications",
        title: gettext("Tell me about episodes"),
        sub: Kati.Screens.SeriesSettings.notify_line(Kati.Settings.Watcher.new_episodes?()),
        control: {:switch, t.notify_new_episodes},
        tap: {self(), :pass_notify_new_episodes}
      },
      %{
        icon: "visibility_off",
        title: gettext("Hide unwatched titles"),
        sub: gettext("Spoiler-safe episode names"),
        control: {:switch, t.hide_unwatched_titles},
        tap: {self(), :pass_hide_unwatched_titles}
      }
    ]
  end

  @doc """
  What *Tell me about episodes* does, given the Release watcher's global
  *New episodes* switch.

      iex> Kati.Screens.SeriesSettings.notify_line(true)
      "Inbox only, no push"

      iex> Kati.Screens.SeriesSettings.notify_line(false)
      "New episodes is off in Release watcher"

  With the global switch off, `Kati.Notifications.Sources.Media.followed/0`
  arms nothing for any show, so this row's own switch has no effect until it is
  on again — and the sub-line says so rather than describing a reminder that
  will not come.
  """
  @spec notify_line(boolean()) :: String.t()
  def notify_line(true), do: gettext("Inbox only, no push")
  def notify_line(false), do: gettext("New episodes is off in Release watcher")

  @doc """
  The three status tiles, lit from the row rather than from the fixture.
  """
  @spec status_tiles(map()) :: [map()]
  def status_tiles(%{tracked: nil}), do: Sample.statuses()

  def status_tiles(%{tracked: t}) do
    Enum.map(Sample.statuses(), fn tile ->
      tile
      |> Map.put(:on, tile.status == t.status)
      |> Map.put(:tracked, t)
    end)
  end

  @doc """
  The page: the gone sentence, or the groups.
  """
  def content(%{show: %{gone?: true}}), do: Kati.Screens.SeriesSettings.gone_body()

  def content(assigns) do
    show = assigns.show

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {Kati.Screens.ShowPages.chrome(
          Kati.Screens.SeriesSettings,
          Kati.Screens.SeriesSettings.id_of(show),
          Map.get(assigns, :menu?, false)
        )}
        {SettingsList.title(show.title, show.subtitle, nil, :meta_tight)}
        {UI.eyebrow(show.status_label)}
        {Kati.Screens.SeriesSettings.statuses(Kati.Screens.SeriesSettings.status_tiles(show))}
        {UI.eyebrow(show.season_pass_label)}
        {Kati.Screens.SeriesSettings.group(Kati.Screens.SeriesSettings.season_pass(show))}
        {Kati.Screens.SeriesSettings.region_band(show)}
        {Kati.Screens.SeriesSettings.this_show_band(show)}
      </Column>
    </Scroll>
    """
  end

  @doc """
  The page for a push whose show has gone: one sentence under the back pill,
  and nothing that could write onto a row that is not there. The sentence is
  `Kati.Screens.Film.gone/2`'s, so the three pages that can find their show
  gone say it the same way.
  """
  @spec gone_body() :: map()
  def gone_body do
    ~MOB"""
    <Column fill_width={true} padding_left={21} padding_right={21} padding_top={140}>
      {Kati.UI.symbol("info", size: 28, color: Palette.sub())}
      <Spacer size={14} />
      <Text
        text={gettext("This title is no longer in your library")}
        text_size={22}
        font_weight="bold"
        line_height={1.25}
        text_color={:on_surface}
      />
    </Column>
    """
  end

  @doc """
  The tap on a status tile, or `nil` on the drawing.

  The already-lit tile keeps its tap: pressing *Watching* on a show that is
  already watching writes the same value, which is how somebody checks a state
  rather than changes it.
  """
  @spec status_tap(map()) :: {pid(), atom()} | nil
  def status_tap(%{tracked: %{}, status: status}),
    do: {self(), Kati.Screens.AddByHand.tag("status_", status)}

  def status_tap(_drawn), do: nil

  @doc """
  Flip one season-pass switch, or set the status.

  The screen follows the store — the control moves after the update answers —
  which is the rule screen 34's ticks keep: a control that moves first is
  showing a state the database does not hold. A row that has gone, or a tag
  this screen does not own, leaves the socket as it was.
  """
  @spec write(Mob.Socket.t(), atom()) :: Mob.Socket.t()
  def write(socket, tag) do
    show = socket.assigns.show

    with %{} = tracked <- Map.get(show, :tracked),
         {:ok, fresh} <- Ash.get(Kati.Media.TrackedTitle, tracked.id),
         {:ok, changes} <- Kati.Screens.SeriesSettings.change_for(tag, fresh),
         {:ok, updated} <- fresh |> Ash.Changeset.for_update(:update, changes) |> Ash.update() do
      Mob.Socket.assign(socket, :show, %{show | tracked: updated})
    else
      _refused -> socket
    end
  end

  @doc """
  What one tag changes, or `:error` for a tag this screen does not own.

      iex> Kati.Screens.SeriesSettings.change_for(:status_paused, %{})
      {:ok, %{status: :paused}}

      iex> Kati.Screens.SeriesSettings.change_for(:pass_hide_unwatched_titles, %{hide_unwatched_titles: false})
      {:ok, %{hide_unwatched_titles: true}}

      iex> Kati.Screens.SeriesSettings.change_for(:pass_auto_add_new_seasons, %{})
      :error

      iex> Kati.Screens.SeriesSettings.change_for(:something_else, %{})
      :error

  The column is looked up in the live list rather than made with
  `String.to_existing_atom/1`, so a tag naming a column this page does not draw
  answers `:error` instead of flipping it. The status is matched against the
  tile's `:status` atom, never its label, so the tag does not change with the
  language.
  """
  @spec change_for(atom(), map()) :: {:ok, map()} | :error
  def change_for(tag, tracked) do
    case Atom.to_string(tag) do
      "pass_" <> field ->
        case Enum.find(@pass_columns, &(Atom.to_string(&1) == field)) do
          nil -> :error
          key -> {:ok, %{key => not Map.fetch!(tracked, key)}}
        end

      "status_" <> key ->
        case Enum.find(Sample.statuses(), &(Atom.to_string(&1.status) == key)) do
          nil -> :error
          tile -> {:ok, %{status: tile.status}}
        end

      _other ->
        :error
    end
  end

  @impl true
  def handle_tap(:open_region, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.CountryPicker)}

  def handle_tap(:open_services, socket),
    do:
      {:noreply,
       Mob.Socket.push_screen(socket, Kati.Screens.MyServices, %{back: "Show settings"})}

  def handle_tap(tag, socket) do
    case Kati.Screens.ShowPages.handle(
           socket,
           tag,
           Kati.Screens.SeriesSettings.tracked_id(socket),
           "Show settings"
         ) do
      {:handled, moved} -> {:noreply, moved}
      :unknown -> {:noreply, Kati.Screens.SeriesSettings.write(socket, tag)}
    end
  end

  @doc false
  @spec id_of(map()) :: String.t() | nil
  def id_of(%{tracked: %{id: id}}), do: id
  def id_of(_drawn), do: nil

  @doc false
  @spec tracked_id(Mob.Socket.t()) :: String.t() | nil
  def tracked_id(socket) do
    case Map.get(socket.assigns.show, :tracked) do
      %{id: id} -> id
      _drawn -> nil
    end
  end

  @doc """
  *Region & availability*: the board's four rows, or a real show's two.

  Over a real show, `region_rows/1` — the reader's country and services, each
  opening the page that sets it.
  """
  @spec region_band(map()) :: map()
  def region_band(%{tracked: nil}) do
    assigns = %{
      eyebrow: UI.eyebrow(gettext("Region & availability")),
      group: Kati.Screens.SeriesSettings.group(Sample.region())
    }

    ~MOB"""
    <Column fill_width={true}>
      {@eyebrow}
      {@group}
    </Column>
    """
  end

  def region_band(show) do
    assigns = %{
      eyebrow: UI.eyebrow(gettext("Region & availability")),
      group: Kati.Screens.SeriesSettings.last_group(Kati.Screens.SeriesSettings.region_rows(show))
    }

    ~MOB"""
    <Column fill_width={true}>
      {@eyebrow}
      {@group}
    </Column>
    """
  end

  @doc """
  The two rows a real show draws under *Region & availability*.

  `region` is `Kati.Services.chosen_region/0` — `nil` when nobody has picked a
  country, which is drawn as screen 93's own *Pick your country* rather than as
  the `GB` `Kati.Services.region/0` assumes. `services` is the names of the
  services the reader pays for, in the order screen 92 keeps them, or screen
  96's *No subscriptions yet*.
  """
  @spec region_rows(map()) :: [map()]
  def region_rows(show) do
    [
      %{
        icon: "public",
        title: gettext("Region"),
        sub: Kati.Screens.SeriesSettings.region_line(Map.get(show, :region)),
        control: :chevron,
        tap: {self(), :open_region}
      },
      %{
        icon: "subscriptions",
        title: gettext("My services"),
        sub: Kati.Screens.SeriesSettings.services_line(Map.get(show, :services, [])),
        control: :chevron,
        tap: {self(), :open_services}
      }
    ]
  end

  @doc """
  The region row's second line.

      iex> Kati.Screens.SeriesSettings.region_line(nil)
      "Pick your country"

      iex> Kati.Screens.SeriesSettings.region_line("DE")
      "Germany"
  """
  @spec region_line(String.t() | nil) :: String.t()
  def region_line(code) when is_binary(code) and code != "", do: Kati.Services.region_name(code)
  def region_line(_unset), do: gettext("Pick your country")

  @doc """
  The services row's second line: the names, as the reader typed them, or
  screen 96's empty-ledger sentence.

      iex> Kati.Screens.SeriesSettings.services_line([])
      "No subscriptions yet"

  The names are isolated left-to-right with `Kati.Locale.ltr/1`, because a
  name ending in `+` beside a comma is all bidi-neutral punctuation that an
  RTL page would otherwise move to the wrong end.
  """
  @spec services_line([String.t()]) :: String.t()
  def services_line([]), do: gettext("No subscriptions yet")
  def services_line(names), do: Kati.Locale.ltr(Enum.join(names, ", "))

  @doc """
  *This show* — reset, archive, remove — on the board, and nothing over a real
  show. See the moduledoc for why none of the three is drawn there.
  """
  def this_show_band(%{tracked: nil}) do
    assigns = %{
      eyebrow: SettingsList.eyebrow_muted(gettext("This show")),
      group: Kati.Screens.SeriesSettings.last_group(Sample.this_show())
    }

    ~MOB"""
    <Column fill_width={true}>
      {@eyebrow}
      {@group}
    </Column>
    """
  end

  def this_show_band(_show), do: ~MOB"<Spacer size={0} />"

  @doc false
  def statuses(tiles_source) when is_list(tiles_source) do
    tiles =
      tiles_source
      |> Enum.map(&Kati.Screens.SeriesSettings.status/1)
      |> Enum.intersperse(Kati.Screens.SeriesSettings.status_gap())

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        {tiles}
      </Row>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def status_gap, do: ~MOB"<Spacer size={8} />"

  @doc """
  One status tile.

  The chosen tile carries a heavier, tighter shadow than the card recipe —
  `0 12px 24px -14px rgba(26,25,23,.9)` — so it reads as pressed into the
  paper. It is an ink-filled control, so it takes `Palette.ink_fill/0` under
  `Palette.on_ink/0`, the pair that inverts in dark rather than following the
  ground.

  The three tiles stay hand-rolled: each is a `Column` with a 21pt glyph above
  its label and its own layout weight, which no vendored segment, chip or pill
  can lay out.
  """
  def status(%{on: true} = s) do
    assigns = %{tap: Kati.Screens.SeriesSettings.status_tap(s)}

    ~MOB"""
    <Box weight={1.0} on_tap={@tap}>
      <Column
        fill_width={true}
        corner_radius={18}
        background={Palette.ink_fill()}
        shadow="0 12 24 -14 #E61A1917"
        padding_left={10}
        padding_right={10}
        padding_top={14}
        padding_bottom={14}
      >
        <Row fill_width={true} align="center">
          <Spacer weight={1.0} />
          {Kati.UI.symbol(s.icon, size: 21, color: Palette.on_ink())}
          <Spacer weight={1.0} />
        </Row>
        <Spacer size={8} />
        <Text
          text={s.label}
          text_size={12}
          font_weight="bold"
          text_color={Palette.on_ink()}
          text_align="center"
          max_lines={1}
        />
      </Column>
    </Box>
    """
  end

  def status(s) do
    assigns = %{tap: Kati.Screens.SeriesSettings.status_tap(s)}

    ~MOB"""
    <Box weight={1.0} on_tap={@tap}>
      <Column
        fill_width={true}
        corner_radius={18}
        background={Palette.card()}
        shadow={Kati.Theme.shadow_card_soft()}
        padding_left={10}
        padding_right={10}
        padding_top={14}
        padding_bottom={14}
      >
        <Row fill_width={true} align="center">
          <Spacer weight={1.0} />
          {Kati.UI.symbol(s.icon, size: 21, color: Palette.sub())}
          <Spacer weight={1.0} />
        </Row>
        <Spacer size={8} />
        <Text
          text={s.label}
          text_size={12}
          font_weight="bold"
          text_color={Palette.ink_soft()}
          text_align="center"
          max_lines={1}
        />
      </Column>
    </Box>
    """
  end

  @doc false
  def group(rows) do
    last = length(rows) - 1

    body =
      rows
      |> Enum.with_index()
      |> Enum.map(fn {row, i} -> Kati.Screens.SeriesSettings.row(row, i < last) end)

    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.card(body)}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc "The group that closes the frame, which carries no trailing gap."
  def last_group(rows) do
    last = length(rows) - 1

    body =
      rows
      |> Enum.with_index()
      |> Enum.map(fn {row, i} -> Kati.Screens.SeriesSettings.row(row, i < last) end)

    SettingsList.card(body)
  end

  @doc """
  One row. A board row carries no `:tap`, and `nil` is the answer
  `Kati.UI.SettingsList.row/4` already takes for "not tappable".
  """
  def row(%{danger: true} = row, rule?) do
    SettingsList.row(
      Kati.Screens.SeriesSettings.danger_tile(row.icon),
      Kati.Screens.SeriesSettings.danger_body(row.title),
      SettingsList.chevron(),
      padding: 13,
      rule: rule?
    )
  end

  def row(row, rule?) do
    SettingsList.row(
      SettingsList.icon_tile(row.icon),
      SettingsList.body(row.title, row.sub),
      Kati.Screens.SeriesSettings.control(row.control),
      padding: 13,
      rule: rule?,
      on_tap: Map.get(row, :tap)
    )
  end

  @doc false
  def control(:chevron), do: SettingsList.chevron()
  def control({:switch, on?}), do: SettingsList.switch(on?)

  @doc """
  The 30x30 tile at 10% red — the one destructive affordance on the board.

  `Kati.Components.MishkaThemeIcon`, the same component `Kati.UI.SettingsList`
  gives every other row, differing only in the colour it is handed.
  `variant: :filled` with an explicit ARGB, because the design says 10% and the
  light variant derives its own 19%. The glyph is a child rather than the
  `icon:` shorthand, whose `Text` carries no `font_family`.
  """
  def danger_tile(name) do
    MishkaThemeIcon.theme_icon(
      %{variant: :filled, color: Palette.red_wash(), size: 30, radius: 9},
      [Kati.UI.symbol(name, size: 17, color: Palette.red())]
    )
  end

  @doc false
  def danger_body(title) do
    ~MOB"""
    <Text
      text={title}
      text_size={13.5}
      font_weight="semibold"
      text_color={Palette.red()}
      max_lines={1}
    />
    """
  end
end
