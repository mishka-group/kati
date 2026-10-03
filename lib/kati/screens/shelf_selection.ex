defmodule Kati.Screens.ShelfSelection do
  @moduledoc """
  Select titles on the shelf, and act on all of them at once (#120).

  Reached two ways: the Library's ⋯ *Select titles*, and a long press on any
  poster, which opens this with that title already selected.

  ## The page

    * a header with ✕, the count, and *Select all* / *Clear*;
    * the Library's own filter chips and poster grid
      (`Kati.Screens.Library.chips/2`, `Kati.Screens.Library.grid/2`), every
      tile carrying a selection mark (`Kati.Screens.Library.pick_mark/1`'s
      `:picked`), so a tap toggles and the mark says which way;
    * an action bar fixed under the grid: **Add to list**, **Status** and
      **Remove**, drawn quiet and inert while nothing is selected.

  It used to draw the design board's other moments around the live one: a
  still copy of the Library header, an *ONE SELECTED* bar with dead buttons
  under a *TWO SELECTED* live one, a frozen *Removed 4 titles* pill, and two
  notes explaining the board. All of that is gone; what is drawn is what is.

  ## Status

  *Status* opens a row of the five statuses and applies the one tapped to every
  selected title. It used to flip one title between finished and watching, so
  a paused show came back as watching and its real status was lost.

  ## Remove, and an Undo that keeps history

  Remove archives the selected rows rather than destroying them, so they leave
  the shelf at once and **Undo** puts them back exactly as they were, watches,
  ratings and lists included. The undo bar stays until the next Remove or ✕;
  then `finalize/1` destroys the rows for good. Their ids wait in `Mob.State`
  (`:pending_removals`) in between, and `finalize_pending/0` runs when the
  Library is back on top and at the next boot, so leaving by the system back
  gesture, or closing the app inside the window, still removes them. No timer:
  a screen holds none (`Kati.SupervisionRuleTest`).
  """
  use Mob.Screen
  use Gettext, backend: Kati.Gettext
  import Mob.Sigil

  alias Kati.Media.TrackedTitle
  alias Kati.Screens.Library
  alias Kati.Theme.Palette
  alias Kati.UI.SettingsList

  @pending_key :pending_removals
  @statuses [:not_started, :watching, :paused, :finished, :dropped]

  def mount(params, _session, socket) do
    Kati.Theme.activate()
    Kati.Locale.activate()
    Kati.Screens.ShelfSelection.finalize_pending()

    preselected =
      case Map.get(params, :selected) do
        id when is_binary(id) -> MapSet.new([id])
        _none -> MapSet.new()
      end

    {:ok,
     socket
     |> Mob.Socket.assign(:filter, :all)
     |> Mob.Socket.assign(:undo, nil)
     |> Mob.Socket.assign(:status_open?, false)
     |> Mob.Socket.assign(:save_error, nil)
     |> Kati.Screens.ShelfSelection.reread(preselected)}
  end

  @doc """
  The shelf again, keeping only the selected ids it still holds.
  """
  @spec reread(Mob.Socket.t(), MapSet.t()) :: Mob.Socket.t()
  def reread(socket, selected) do
    titles = Kati.Screens.ShelfSelection.shelf()
    ids = MapSet.new(titles, & &1.id)

    socket
    |> Mob.Socket.assign(:titles, titles)
    |> Mob.Socket.assign(:selected, MapSet.intersection(selected, ids))
  end

  @doc """
  The reader's shelf, in the Library's own shape; `[]` when it cannot be read.

  `Kati.Screens.Library.titles/0` is the one reader, so this grid and the
  Library's never disagree about what is on the shelf.
  """
  @spec shelf() :: [map()]
  def shelf do
    Enum.filter(Library.titles(), &is_binary(Map.get(&1, :id)))
  rescue
    _error -> []
  catch
    :exit, _reason -> []
  end

  @doc """
  The titles the chips leave showing, each marked selected or not.
  """
  @spec marked([map()], atom(), MapSet.t()) :: [map()]
  def marked(titles, filter, selected) do
    titles
    |> Library.visible(filter)
    |> Enum.map(&Map.put(&1, :picked, MapSet.member?(selected, &1.id)))
  end

  @doc """
  The header's count line.

      iex> Kati.Screens.ShelfSelection.count_line(0)
      "Tap titles to select them"
      iex> Kati.Screens.ShelfSelection.count_line(1)
      "1 selected"
      iex> Kati.Screens.ShelfSelection.count_line(12)
      "12 selected"
  """
  @spec count_line(non_neg_integer()) :: String.t()
  def count_line(0), do: gettext("Tap titles to select them")

  def count_line(n),
    do: ngettext("%{n} selected", "%{n} selected", n, n: Kati.Locale.number(n))

  @doc "A status as the chooser names it."
  @spec status_label(atom()) :: String.t()
  def status_label(:not_started), do: gettext("Not started")
  def status_label(:watching), do: gettext("Watching")
  def status_label(:paused), do: gettext("Paused")
  def status_label(:finished), do: gettext("Finished")
  def status_label(:dropped), do: gettext("Dropped")

  @doc false
  def statuses, do: @statuses

  def render(assigns) do
    shown = Kati.Screens.ShelfSelection.marked(assigns.titles, assigns.filter, assigns.selected)
    count = MapSet.size(assigns.selected)

    ~MOB"""
    <Box
      fill_width={true}
      fill_height={true}
      background={:background}
      layout_direction={Kati.Locale.direction_prop()}
      reduce_motion={Kati.Accessibility.motion_prop()}
      text_scale={Kati.Accessibility.scale_prop()}
      font_family={Kati.Locale.face_prop()}
      accessibility_id={Kati.Screens.Identity.of(__MODULE__)}
    >
      <Column fill_width={true} fill_height={true}>
        <Scroll weight={1.0}>
          <Column
            fill_width={true}
            padding_left={21}
            padding_right={21}
            padding_top={64}
            padding_bottom={24}
          >
            {Kati.Screens.ShelfSelection.header(count, shown)}
            {Library.chips(assigns.filter, assigns.titles)}
            {Kati.Screens.ShelfSelection.refusal(assigns.save_error)}
            {Kati.Screens.ShelfSelection.body(assigns.titles, assigns.filter, shown)}
          </Column>
        </Scroll>
        {Kati.Screens.ShelfSelection.undo_bar(assigns.undo)}
        {Kati.Screens.ShelfSelection.status_row(assigns.status_open?, count)}
        {Kati.Screens.ShelfSelection.action_bar(count)}
      </Column>
    </Box>
    """
  end

  @doc false
  def header(count, shown) do
    all? = shown != [] and Enum.all?(shown, & &1.picked)

    {label, tag} =
      if all?,
        do: {gettext("Clear"), :clear_selection},
        else: {gettext("Select all"), :select_all}

    line = Kati.Screens.ShelfSelection.count_line(count)
    assigns = %{label: label, tag: tag, line: line, any?: shown != []}

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} height={44} align="center">
        <Box
          width={44}
          height={44}
          corner_radius={22}
          background={Palette.card()}
          shadow={Kati.Theme.shadow_button()}
          align="center"
          on_tap={{self(), :close}}
          accessibility_label={gettext("Close")}
        >
          {Kati.UI.symbol("close", size: 21)}
        </Box>
        <Spacer weight={1.0} />
        {Kati.Screens.ShelfSelection.select_all(@any?, @label, @tag)}
      </Row>
      <Spacer size={16} />
      <Text
        text={gettext("Select titles")}
        text_size={28}
        max_font_scale={1.6}
        font_weight="bold"
        letter_spacing={Kati.Locale.tracking(-0.03)}
        text_color={:on_surface}
        max_lines={1}
      />
      <Spacer size={5} />
      <Text text={@line} text_size={12.5} text_color={Palette.sub()} />
      <Spacer size={18} />
    </Column>
    """
  end

  @doc false
  def select_all(false, _label, _tag), do: ~MOB"<Spacer size={0} />"

  def select_all(true, label, tag) do
    SettingsList.action_pill(label, {self(), tag})
  end

  @doc false
  def body([], _filter, _shown) do
    Library.nothing_card(
      gettext("Nothing on your shelf yet"),
      gettext("Search for a film or a series and add it, and you can select it here.")
    )
  end

  def body(_titles, filter, shown) do
    case shown do
      [] -> Library.nothing_here(filter)
      _some -> Library.tiles(Enum.chunk_every(shown, 3))
    end
  end

  @doc """
  The line that says the store refused, or nothing.
  """
  @spec refusal(String.t() | nil) :: map() | []
  def refusal(nil), do: []

  def refusal(message) do
    assigns = %{message: message}

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.notice(@message)}
      <Spacer size={14} />
    </Column>
    """
  end

  @doc """
  The bar a Remove leaves: how many went, and the Undo that brings them back.
  """
  def undo_bar(nil), do: []

  def undo_bar(%{ids: ids}) do
    message =
      ngettext("Removed %{n} title", "Removed %{n} titles", length(ids),
        n: Kati.Locale.number(length(ids))
      )

    assigns = %{message: message}

    ~MOB"""
    <Column fill_width={true} padding_left={16} padding_right={16} padding_bottom={8}>
      <Row
        fill_width={true}
        background={Palette.ink_fill()}
        corner_radius={20}
        padding_left={16}
        padding_right={8}
        padding_top={6}
        padding_bottom={6}
        align="center"
      >
        {Kati.UI.symbol("delete", size: 19, color: Palette.on_ink())}
        <Spacer size={12} />
        <Text
          text={@message}
          text_size={13}
          font_weight="semibold"
          text_color={Palette.on_ink()}
          weight={1.0}
          max_lines={2}
        />
        <Spacer size={8} />
        <Row height={44} padding_left={14} padding_right={14} align="center" on_tap={{self(), :undo}}>
          <Text
            text={gettext("Undo")}
            text_size={13}
            font_weight="bold"
            text_color={Palette.accent()}
            max_lines={1}
          />
        </Row>
      </Row>
    </Column>
    """
  end

  @doc """
  The five statuses, shown once *Status* is tapped; the one tapped applies to
  every selected title.
  """
  def status_row(false, _count), do: []
  def status_row(true, 0), do: []

  def status_row(true, _count) do
    chips =
      @statuses
      |> Enum.map(fn status ->
        tag = String.to_atom("set_status_" <> Atom.to_string(status))
        SettingsList.action_pill(Kati.Screens.ShelfSelection.status_label(status), {self(), tag})
      end)
      |> Enum.intersperse(~MOB"<Spacer size={8} />")

    ~MOB"""
    <Column fill_width={true} padding_left={16} padding_right={16} padding_bottom={8}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={20}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={12}
      >
        <Text
          text={gettext("Set status for the selected titles")}
          text_size={11.5}
          text_color={Palette.sub()}
        />
        <Spacer size={10} />
        <Scroll axis="horizontal">
          <Row align="center">
            {chips}
          </Row>
        </Scroll>
      </Column>
    </Column>
    """
  end

  @doc """
  Add to list, Status and Remove, as three equal buttons — quiet and with no
  tap while nothing is selected.
  """
  def action_bar(count) do
    live? = count > 0

    buttons =
      [
        {"bookmarks", gettext("Add to list"), :add_to_list, false},
        {"tune", gettext("Status"), :change_status, false},
        {"delete", gettext("Remove"), :remove_selected, true}
      ]
      |> Enum.map(fn {icon, label, tag, danger?} ->
        Kati.Screens.ShelfSelection.action(icon, label, live? && tag, danger?)
      end)
      |> Enum.intersperse(~MOB"<Spacer size={8} />")

    ~MOB"""
    <Column
      fill_width={true}
      padding_left={16}
      padding_right={16}
      padding_top={4}
      padding_bottom={12}
    >
      <Row
        fill_width={true}
        background={Palette.card()}
        corner_radius={24}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={8}
      >
        {buttons}
      </Row>
    </Column>
    """
  end

  @doc false
  def action(icon, label, false, _danger?) do
    assigns = %{icon: icon, label: label}

    ~MOB"""
    <Column weight={1.0} height={58} align="center" padding_top={8}>
      {Kati.UI.symbol(@icon, size: 21, color: Palette.chip_text_disabled())}
      <Spacer size={4} />
      <Text text={@label} text_size={11.5} text_color={Palette.chip_text_disabled()} max_lines={1} />
    </Column>
    """
  end

  def action(icon, label, tag, danger?) do
    ink = if danger?, do: Palette.red(), else: Palette.ink()
    assigns = %{icon: icon, label: label, ink: ink, tap: {self(), tag}}

    ~MOB"""
    <Column weight={1.0} height={58} align="center" padding_top={8} corner_radius={18} on_tap={@tap}>
      {Kati.UI.symbol(@icon, size: 21, color: @ink)}
      <Spacer size={4} />
      <Text text={@label} text_size={11.5} font_weight="semibold" text_color={@ink} max_lines={1} />
    </Column>
    """
  end

  # ── Taps ────────────────────────────────────────────────────────────────

  def handle_info({:tap, :close}, socket) do
    socket = Kati.Screens.ShelfSelection.finalize(socket)
    {:noreply, Kati.Screens.Resume.pop(socket)}
  end

  def handle_info({:tap, :select_all}, socket) do
    ids = MapSet.new(Library.visible(socket.assigns.titles, socket.assigns.filter), & &1.id)
    {:noreply, Mob.Socket.assign(socket, :selected, MapSet.union(socket.assigns.selected, ids))}
  end

  def handle_info({:tap, :clear_selection}, socket) do
    ids = MapSet.new(Library.visible(socket.assigns.titles, socket.assigns.filter), & &1.id)

    {:noreply,
     socket
     |> Mob.Socket.assign(:selected, MapSet.difference(socket.assigns.selected, ids))
     |> Mob.Socket.assign(:status_open?, false)}
  end

  def handle_info({:tap, :add_to_list}, socket) do
    members = Enum.map(MapSet.to_list(socket.assigns.selected), &{:tracked_title, &1})

    case members do
      [] -> {:noreply, socket}
      _some -> {:noreply, Kati.Lists.Door.open_many(socket, members)}
    end
  end

  def handle_info({:tap, :change_status}, socket) do
    {:noreply, Mob.Socket.assign(socket, :status_open?, not socket.assigns.status_open?)}
  end

  def handle_info({:tap, :remove_selected}, socket) do
    socket = Kati.Screens.ShelfSelection.finalize(socket)
    ids = MapSet.to_list(socket.assigns.selected)

    case Kati.Screens.ShelfSelection.archive(ids, true) do
      :ok ->
        Kati.Screens.ShelfSelection.remember_pending(ids)

        {:noreply,
         socket
         |> Mob.Socket.assign(:undo, %{ids: ids})
         |> Mob.Socket.assign(:status_open?, false)
         |> Mob.Socket.assign(:save_error, nil)
         |> Kati.Screens.ShelfSelection.reread(MapSet.new())}

      {:error, reason} ->
        {:noreply, Mob.Socket.assign(socket, :save_error, Kati.Write.message({:error, reason}))}
    end
  end

  def handle_info({:tap, :undo}, socket) do
    case socket.assigns.undo do
      %{ids: ids} ->
        case Kati.Screens.ShelfSelection.archive(ids, false) do
          :ok ->
            Kati.Screens.ShelfSelection.forget_pending(ids)

            {:noreply,
             socket
             |> Mob.Socket.assign(:undo, nil)
             |> Mob.Socket.assign(:save_error, nil)
             |> Kati.Screens.ShelfSelection.reread(MapSet.new(ids))}

          {:error, reason} ->
            {:noreply,
             Mob.Socket.assign(socket, :save_error, Kati.Write.message({:error, reason}))}
        end

      nil ->
        {:noreply, socket}
    end
  end

  def handle_info({:tap, tag}, socket) when is_atom(tag) do
    case Atom.to_string(tag) do
      "filter_" <> key ->
        {:noreply, Mob.Socket.assign(socket, :filter, String.to_existing_atom(key))}

      "set_status_" <> name ->
        case Enum.find(@statuses, &(Atom.to_string(&1) == name)) do
          nil -> {:noreply, socket}
          status -> {:noreply, Kati.Screens.ShelfSelection.apply_status(socket, status)}
        end

      "open_film_" <> id ->
        {:noreply, Kati.Screens.ShelfSelection.toggle(socket, id)}

      "open_series_" <> id ->
        {:noreply, Kati.Screens.ShelfSelection.toggle(socket, id)}

      _other ->
        {:noreply, socket}
    end
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  @doc false
  def toggle(socket, id) do
    selected = socket.assigns.selected

    updated =
      cond do
        not Enum.any?(socket.assigns.titles, &(&1.id == id)) -> selected
        MapSet.member?(selected, id) -> MapSet.delete(selected, id)
        true -> MapSet.put(selected, id)
      end

    Mob.Socket.assign(socket, :selected, updated)
  end

  @doc false
  def apply_status(socket, status) do
    ids = MapSet.to_list(socket.assigns.selected)

    case Kati.Screens.ShelfSelection.write_status(ids, status) do
      :ok ->
        socket
        |> Mob.Socket.assign(:status_open?, false)
        |> Mob.Socket.assign(:save_error, nil)
        |> Kati.Screens.ShelfSelection.reread(socket.assigns.selected)

      {:error, reason} ->
        Mob.Socket.assign(socket, :save_error, Kati.Write.message({:error, reason}))
    end
  end

  # ── Writes ──────────────────────────────────────────────────────────────

  @doc """
  Give every title in `ids` the one status, in the store.

  Through `Kati.Media.TrackedTitle`'s own `:update`, so the shelf re-sorts by
  `last_touched_at` the way it does after any other status change.
  """
  @spec write_status([String.t()], atom()) :: :ok | {:error, term()}
  def write_status(ids, status) when status in @statuses do
    Enum.reduce_while(ids, :ok, fn id, :ok ->
      with {:ok, row} <- Ash.get(TrackedTitle, id),
           {:ok, _row} <-
             row
             |> Ash.Changeset.for_update(:update, %{status: status})
             |> Ash.update()
             |> Kati.Write.note("change status from the shelf") do
        {:cont, :ok}
      else
        error -> {:halt, error}
      end
    end)
  rescue
    error -> {:error, error}
  end

  @doc """
  Archive (`true`) or restore (`false`) the rows in `ids`.

  Archived rows leave every shelf read at once and keep their history, which is
  what makes Undo exact.
  """
  @spec archive([String.t()], boolean()) :: :ok | {:error, term()}
  def archive(ids, archived?) do
    Enum.reduce_while(ids, :ok, fn id, :ok ->
      case Ash.get(TrackedTitle, id) do
        {:ok, row} ->
          row
          |> Ash.Changeset.for_update(:set_archived, %{archived: archived?})
          |> Ash.update()
          |> Kati.Write.note("remove from the shelf")
          |> case do
            {:ok, _row} -> {:cont, :ok}
            error -> {:halt, error}
          end

        _gone ->
          {:cont, :ok}
      end
    end)
  rescue
    error -> {:error, error}
  end

  @doc """
  End the undo window: destroy the archived rows for good, and forget them.
  """
  @spec finalize(Mob.Socket.t()) :: Mob.Socket.t()
  def finalize(socket) do
    case socket.assigns.undo do
      %{ids: ids} ->
        Kati.Screens.ShelfSelection.destroy(ids)
        Mob.Socket.assign(socket, :undo, nil)

      nil ->
        socket
    end
  end

  @doc """
  Destroy whatever an earlier Remove left archived and waiting — an app closed
  inside the undo window. Run at boot and on this screen's mount.
  """
  @spec finalize_pending() :: :ok
  def finalize_pending do
    case Mob.State.get(@pending_key, []) do
      [] -> :ok
      ids -> Kati.Screens.ShelfSelection.destroy(ids)
    end
  rescue
    _error -> :ok
  catch
    :exit, _reason -> :ok
  end

  @doc """
  Take archived rows off the device for good: watches, events, warnings,
  aliases and list memberships go with the row. A row that is no longer
  archived — restored by Undo, or by anything else — is left alone.
  """
  @spec destroy([String.t()]) :: :ok
  def destroy(ids) do
    Enum.each(ids, &Kati.Screens.ShelfSelection.destroy_one/1)
    forget_pending(ids)
  end

  @doc false
  def destroy_one(id) do
    case Ash.get(TrackedTitle, id) do
      {:ok, %{archived: true} = row} -> Ash.destroy(row)
      _restored_or_gone -> :ok
    end
  rescue
    _error -> :ok
  end

  @doc false
  def remember_pending(ids) do
    Mob.State.put(@pending_key, Enum.uniq(Mob.State.get(@pending_key, []) ++ ids))
  end

  @doc false
  def forget_pending(ids) do
    Mob.State.put(@pending_key, Mob.State.get(@pending_key, []) -- ids)
    :ok
  end
end
