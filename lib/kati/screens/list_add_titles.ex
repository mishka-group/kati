defmodule Kati.Screens.ListAddTitles do
  @moduledoc """
  The drawer a list opens to take titles from the shelf (#114).

  A list could only be filled from the other end: open a film, tap *Add to
  list*, choose the list. From inside the list there was no way in. Its `+`
  opens this: a sheet over about seventy per cent of the screen holding the
  Library's own shelf — `Kati.Screens.Library.chips/2` and
  `Kati.Screens.Library.grid/2`, the same filter row and poster grid the shelf
  draws, not a second picture of them.

  ## A tap adds, and a second tap takes it back out

  Each poster carries `:in_list`, and `Kati.Screens.Library.pick_mark/1` draws
  it: a plus on a title the list does not hold, a tick on one it does. The
  grid's own tap tags are kept (`open_film_<id>`, `open_series_<id>`), so a tap
  here is answered as *toggle this title's place in the list* instead of *open
  its page*, and the write goes through `Kati.Lists.Shelf.add/2` and `remove/2`,
  the two calls the film page's *Add to list* already uses. A write that fails
  says so under the grid, and the tile keeps the mark it had.

  ## Height

  `Kati.UI.Sheet` hugs its content on purpose and declares no height. A shelf
  is as long as the reader's library, so this sheet takes a share of the
  screen instead: a `0.3` weight of scrim above a `0.7` weight of sheet, and
  the grid scrolls inside it. Tapping the scrim (`:close_scrim`) closes it, as
  the ✕ does.

  ## Coming back

  The ✕ pops through `Kati.Screens.Resume`, so the list behind re-reads and
  shows what was added the moment it is painted again.
  """

  use Mob.Screen
  use Gettext, backend: Kati.Gettext
  import Mob.Sigil

  alias Kati.Lists.Membership
  alias Kati.Lists.Shelf
  alias Kati.Screens.Library
  alias Kati.Theme.Palette
  alias Kati.UI.Sheet

  def mount(params, _session, socket) do
    Kati.Theme.activate()
    Kati.Locale.activate()
    Kati.Screens.Resume.watch()

    {:ok,
     socket
     |> Mob.Socket.assign(:list_id, Map.get(params, :id))
     |> Mob.Socket.assign(:list_name, Kati.Screens.ListAddTitles.list_name(Map.get(params, :id)))
     |> Mob.Socket.assign(:filter, :all)
     |> Mob.Socket.assign(:error, nil)
     |> Kati.Screens.ListAddTitles.reread()}
  end

  @doc """
  The shelf again, each title marked in or out of the list.
  """
  @spec reread(Mob.Socket.t()) :: Mob.Socket.t()
  def reread(socket) do
    held = Kati.Screens.ListAddTitles.held(socket.assigns.list_id)

    titles =
      Enum.map(Library.titles(), fn title ->
        Map.put(title, :in_list, MapSet.member?(held, title.id))
      end)

    Mob.Socket.assign(socket, :titles, titles)
  end

  @doc """
  The list's own name, read from the store rather than carried by the push, so
  an id that names nothing draws what no id draws.
  """
  @spec list_name(String.t() | nil) :: String.t() | nil
  def list_name(id) do
    case Shelf.detail(id) do
      %{title: name} when is_binary(name) -> name
      _gone -> nil
    end
  end

  @doc "The tracked titles a list holds, by id."
  @spec held(String.t() | nil) :: MapSet.t()
  def held(nil), do: MapSet.new()

  def held(list_id) do
    Membership
    |> Ash.Query.for_read(:for_list, %{list_id: list_id})
    |> Ash.read!()
    |> Enum.flat_map(fn row ->
      case Membership.member(row) do
        {:tracked_title, id} -> [id]
        _other -> []
      end
    end)
    |> MapSet.new()
  rescue
    _error -> MapSet.new()
  end

  def render(assigns) do
    ~MOB"""
    <Box
      fill_width={true}
      fill_height={true}
      background={:background}
      layout_direction={Kati.Locale.direction_prop()}
      font_family={Kati.Locale.face_prop()}
      accessibility_id={Kati.Screens.Identity.of(__MODULE__)}
    >
      <Box fill_width={true} fill_height={true} background={Sheet.scrim()} />
      <Column fill_width={true} fill_height={true}>
        <Box fill_width={true} weight={0.3} on_tap={{self(), :close_scrim}} />
        <Box fill_width={true} weight={0.7}>
          <Box fill_width={true} fill_height={true} align="bottom">
            <Box fill_width={true} height={40} background={Palette.paper()} />
          </Box>
          <Column
            fill_width={true}
            fill_height={true}
            background={Palette.paper()}
            corner_radius={26}
            padding_left={21}
            padding_right={21}
            padding_top={18}
          >
            {Sheet.header(Kati.Screens.ListAddTitles.heading(assigns.list_name))}
            <Spacer size={16} />
            {Library.chips(assigns.filter, assigns.titles)}
            <Scroll weight={1.0}>
              <Column fill_width={true} padding_bottom={34}>
                {Kati.Screens.ListAddTitles.error_line(assigns.error)}
                {Kati.Screens.ListAddTitles.shelf(assigns.filter, assigns.titles)}
              </Column>
            </Scroll>
          </Column>
        </Box>
      </Column>
    </Box>
    """
  end

  @doc false
  def heading(nil), do: gettext("Add titles")
  def heading(name), do: gettext("Add to %{list}", list: name)

  @doc false
  def shelf(_filter, []) do
    Library.nothing_card(
      gettext("Nothing on your shelf yet"),
      gettext("Search for a film or a series and add it, and it can go on a list from here.")
    )
  end

  def shelf(filter, titles), do: Library.grid(filter, titles)

  @doc false
  def error_line(nil), do: ~MOB"<Spacer size={0} />"

  def error_line(message) do
    assigns = %{message: message}

    ~MOB"""
    <Column fill_width={true}>
      <Text text={@message} text_size={12.5} text_color={Palette.red()} />
      <Spacer size={12} />
    </Column>
    """
  end

  # Two tags for one answer: the scrim and the ✕ are two nodes, and a tag is
  # an accessibility id, which two nodes must not share.
  def handle_info({:tap, tag}, socket) when tag in [:close, :close_scrim],
    do: {:noreply, Kati.Screens.Resume.pop(socket)}

  def handle_info({:tap, tag}, socket) when is_atom(tag) do
    case Atom.to_string(tag) do
      "filter_" <> key ->
        {:noreply, Mob.Socket.assign(socket, :filter, String.to_existing_atom(key))}

      "open_film_" <> id ->
        {:noreply, Kati.Screens.ListAddTitles.toggle(socket, id)}

      "open_series_" <> id ->
        {:noreply, Kati.Screens.ListAddTitles.toggle(socket, id)}

      _other ->
        {:noreply, socket}
    end
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  @doc """
  Put a title in the list, or take it out if it is already there.

  Nothing on the tile changes until the write answers, the rule
  `Kati.Lists.Shelf.remove/2` states for the list page: a mark that flipped
  before a failed write would be a list that disagrees with itself.
  """
  @spec toggle(Mob.Socket.t(), String.t()) :: Mob.Socket.t()
  def toggle(socket, id) do
    list_id = socket.assigns.list_id
    in? = Enum.any?(socket.assigns.titles, &(&1.id == id and &1.in_list))

    result =
      if in?,
        do: Shelf.remove(list_id, {:tracked_title, id}),
        else: Shelf.add(%{id: list_id}, {:tracked_title, id})

    case result do
      :ok ->
        socket
        |> Mob.Socket.assign(:error, nil)
        |> Kati.Screens.ListAddTitles.reread()

      {:error, _reason} ->
        Mob.Socket.assign(socket, :error, gettext("That did not save. Try again."))
    end
  end
end
