defmodule Kati.Screens.ListDetail do
  @moduledoc """
  One hand-made list, and the titles in it.

  **This screen has no board.** Every row on screen 12 draws a `chevron_right`
  and the design never drew what it opens, so the chevrons were removed and
  MOVIES-AND-TV.md #106 was closed as a design gap
  ([#99](https://github.com/mishka-group/kati/issues/99)). The owner asked for
  the feature rather than the gap, so this is built — and where it had to
  invent, it invents by BORROWING rather than by designing:

    * the header is `Kati.UI.SettingsList.title/4`, screen 12's own.
    * a title row is `Kati.Screens.Library`'s poster tile geometry at list
      width — a 40x56 poster, the name, and what kind it is — which is the row
      screens 05, 10 and 15 all draw.
    * `Remove` is `Kati.Components.MishkaPill` in `Palette.red_wash/0` and
      `Palette.red/0`, which is board 146's own destructive pill.

  Nothing here is a new object. When 12's detail board is drawn, this screen
  changes to match it and the resource underneath does not move.

  ## What a ranked list is

  `Kati.Lists.Membership.position` is kept on every list, not only ranked ones
  — a list that becomes ranked should not have to invent an order it never
  recorded. The number is drawn only when the list says it is ranked, which is
  the badge board 12 already draws.
  """
  use Kati.Screens.Pushed, back: "Lists"

  alias Kati.Components.MishkaPill
  alias Kati.Theme.Palette
  alias Kati.UI.SettingsList

  @impl true
  def load(socket) do
    params = socket.assigns.params || %{}

    Mob.Socket.assign(socket, :list, Kati.Lists.Shelf.detail(Map.get(params, :id)))
  end

  @doc false
  def content(assigns) do
    list = assigns.list

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
        {Kati.Screens.ListDetail.body(list)}
      </Column>
    </Scroll>
    """
  end

  @doc """
  The list, or the sentence for one that is not there.

  A list deleted on another device is not the same fact as an empty one, which
  is `Kati.Screens.Film.tracked_film/1`'s rule for the identical question — so
  a missing list says so rather than drawing an empty list somebody still has.
  """
  @spec body(map() | nil) :: term()
  def body(nil) do
    assigns = %{tap: {self(), :open_lists}}

    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.title("No list here", "Nothing to show", nil, :name)}
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={17}
      >
        <Text
          text="This list is gone"
          text_size={14.5}
          font_weight="bold"
          text_color={:on_surface}
          text_align="center"
        />
        <Spacer size={7} />
        <Text
          text="It was deleted, or you have not made one yet. Nothing was lost from your shelf — a list holds titles, it does not own them."
          text_size={12.5}
          line_height={1.55}
          text_color={Palette.sub()}
          text_align="center"
        />
        <Spacer size={16} />
        <Row fill_width={true} align="center">
          <Spacer weight={1.0} />
          {SettingsList.action_pill("Your lists", @tap)}
          <Spacer weight={1.0} />
        </Row>
      </Column>
      <Spacer size={16} />
      {SettingsList.note("info", "A list is yours to name. Make one from Lists, then select titles on your shelf and press Add to list.")}
    </Column>
    """
  end

  def body(list) do
    assigns = %{
      list: list,
      rows: Kati.Screens.ListDetail.rows(list),
      delete: {self(), :delete_list}
    }

    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.title(@list.title, @list.count, nil, :name)}
      {@rows}
      <Spacer size={16} />
      <Row fill_width={true} align="center">
        <Spacer weight={1.0} />
        {Kati.Screens.ListDetail.delete_pill(@delete)}
      </Row>
    </Column>
    """
  end

  @doc """
  Every title in the list, or the card for a list with none in it.

  Screen 96's rule again — *say what is missing and offer the one thing that
  fixes it* — and the one thing is the shelf, which is where `Add to list`
  lives.
  """
  @spec rows(map()) :: term()
  def rows(%{titles: []}) do
    assigns = %{tap: {self(), :open_library}}

    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={22}
      shadow={Kati.Theme.shadow_card_soft()}
      padding={17}
      on_tap={@tap}
    >
      <Text
        text="Nothing in it yet"
        text_size={14.5}
        font_weight="bold"
        text_color={:on_surface}
        text_align="center"
      />
      <Spacer size={7} />
      <Text
        text="Select titles on your shelf and press Add to list."
        text_size={12.5}
        line_height={1.55}
        text_color={Palette.sub()}
        text_align="center"
      />
    </Column>
    """
  end

  def rows(list) do
    assigns = %{
      rows:
        list.titles
        |> Enum.with_index()
        |> Enum.map(fn {row, i} ->
          Kati.Screens.ListDetail.title_row(row, list.ranked?, i, i < length(list.titles) - 1)
        end)
    }

    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.card(@rows)}
    </Column>
    """
  end

  @doc false
  def title_row(row, ranked?, index, rule?) do
    SettingsList.row(
      Kati.Screens.ListDetail.leading(row, ranked?, index),
      SettingsList.body(row.title, Kati.Screens.ListDetail.sub(row)),
      Kati.Screens.ListDetail.remove_pill(row),
      rule: rule?,
      on_tap: {self(), String.to_atom("open_title_" <> row.id)}
    )
  end

  @doc """
  A poster, with its rank in front of it on a ranked list.

      iex> Kati.Screens.ListDetail.sub(%{kind: :film})
      "Film"

      iex> Kati.Screens.ListDetail.sub(%{kind: :series})
      "Series"
  """
  @spec sub(map()) :: String.t()
  def sub(%{kind: :film}), do: "Film"
  def sub(_series), do: "Series"

  @doc false
  def leading(row, ranked?, index) do
    assigns = %{
      poster: Kati.Screens.ListDetail.poster(row.seed),
      rank: if(ranked?, do: Integer.to_string(index + 1))
    }

    ~MOB"""
    <Row align="center">
      {Kati.Screens.ListDetail.rank(@rank)}
      {@poster}
    </Row>
    """
  end

  @doc false
  def rank(nil), do: ~MOB"<Spacer size={0} />"

  def rank(number) do
    assigns = %{number: number}

    ~MOB"""
    <Row align="center">
      <Text
        text={@number}
        font_family="mono"
        text_size={12}
        text_color={Palette.muted()}
        max_lines={1}
      />
      <Spacer size={10} />
    </Row>
    """
  end

  @doc false
  def poster(nil),
    do: ~MOB"<Box width={40} height={56} corner_radius={9} background={Palette.placeholder()} />"

  def poster(seed) do
    case Kati.Design.Images.poster(seed) do
      nil ->
        ~MOB"<Box width={40} height={56} corner_radius={9} background={Palette.placeholder()} />"

      src ->
        assigns = %{src: src}

        ~MOB"""
        <Box width={40} height={56} corner_radius={9} background={Palette.placeholder()}>
          <Image src={@src} width={40} height={56} corner_radius={9} content_mode="fill" />
        </Box>
        """
    end
  end

  @doc "Board 146's own destructive pill, at its own four numbers."
  @spec remove_pill(map()) :: map()
  def remove_pill(row) do
    MishkaPill.pill(
      label: "Remove",
      on_tap: {self(), String.to_atom("remove_" <> row.id)},
      background: Palette.red_wash(),
      text_color: Palette.red(),
      height: 30,
      corner_radius: 15,
      padding: 0,
      padding_left: 12,
      padding_right: 12,
      text_size: 11.5,
      font_weight: :semibold,
      max_lines: 1
    )
  end

  @doc false
  def delete_pill(tap) do
    MishkaPill.pill(
      label: "Delete this list",
      on_tap: tap,
      background: Palette.red_wash(),
      text_color: Palette.red(),
      height: 38,
      corner_radius: 19,
      padding: 0,
      padding_left: 16,
      padding_right: 16,
      text_size: 12.5,
      font_weight: :semibold,
      max_lines: 1
    )
  end

  # Coming back from a title's own page: it may have been dropped, renamed by a
  # Kind swap, or archived. `Kati.Screens.Resume` announces it and this re-reads
  # the list it is holding.
  @impl true
  def handle_info({:kati, :resumed, _payload}, socket) do
    id = socket.assigns.list && socket.assigns.list.id

    {:noreply, Mob.Socket.assign(socket, :list, Kati.Lists.Shelf.detail(id))}
  end

  def handle_info(message, socket), do: super(message, socket)

  @impl true
  def handle_tap(:delete_list, socket) do
    case socket.assigns.list do
      nil ->
        {:noreply, socket}

      list ->
        {:noreply,
         list.id
         |> Kati.Lists.Shelf.delete()
         |> then(fn :ok -> Kati.Screens.Resume.pop(socket) end)}
    end
  end

  def handle_tap(:open_lists, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Lists)}

  def handle_tap(:open_library, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Library)}

  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "remove_" <> id ->
        {:noreply, Kati.Screens.ListDetail.removed(socket, id)}

      "open_title_" <> id ->
        {:noreply, Kati.Screens.ListDetail.open(socket, id)}

      _other ->
        {:noreply, socket}
    end
  end

  @doc false
  @spec removed(Mob.Socket.t(), String.t()) :: Mob.Socket.t()
  def removed(socket, tracked_id) do
    list = socket.assigns.list

    # Resolved against the very rows the page drew, never taken from the tag.
    # `Kati.Screens.Library.open_tile/3` states the rule and
    # `Kati.ScreenWriteTargetTest` is what enforces it: a tag naming an id the
    # page is not holding is a write to a row the reader never saw.
    row = list && Enum.find(list.titles, &(&1.id == tracked_id))

    if row do
      Kati.Lists.Shelf.remove(list.id, row.id)
      Mob.Socket.assign(socket, :list, Kati.Lists.Shelf.detail(list.id))
    else
      socket
    end
  end

  @doc """
  Open the title a row names, on the screen its kind belongs to.

  Resolved against the very list the rows were drawn from, which is
  `Kati.Screens.Library.open_tile/3`'s rule: the row knows which screen it
  opens, and a second query might answer with a different title.
  """
  @spec open(Mob.Socket.t(), String.t()) :: Mob.Socket.t()
  def open(socket, tracked_id) do
    row = socket.assigns.list && Enum.find(socket.assigns.list.titles, &(&1.id == tracked_id))

    case row do
      nil ->
        socket

      %{kind: :film} ->
        Mob.Socket.push_screen(socket, Kati.Screens.Film, %{id: tracked_id, back: "List"})

      _series ->
        Mob.Socket.push_screen(socket, Kati.Screens.Series, %{id: tracked_id, back: "List"})
    end
  end
end
