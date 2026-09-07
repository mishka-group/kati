defmodule Kati.Screens.ListDetail do
  @moduledoc """
  One list, and what is in it.

  Boards **330**, **331** and **332**, delivered 7 September against `D-65`.
  Before them this screen had no drawing at all and said so; it invented by
  borrowing, and the boards overruled most of what it borrowed.

  ## What the boards changed

    * **The row's trailing slot is a `chevron_right`**, or a `drag_indicator`
      on a ranked list. The red `Remove` pill that used to live there is gone —
      330: *"181 gave the row's trailing slot to a chevron and the ranked row's
      to a drag handle, and there is no third."*
    * **Remove is a long press.** The gesture 146 already owns for a shelf tile,
      on a list row: it swaps the trailing mark for a `Remove` pill and takes no
      confirmation, because *"one title, one tap, undo below. A dialog for one
      row is the thing 146 declined."*
    * **The list's own menu is behind a ⋯ disc** — Rename, Share, Delete this
      list. 330 ruled rename in, the third thing 181 named as undrawn.
    * **Delete confirms**, in 269's recipe widened
      (`Kati.UI.Destructive.confirm/1`), leading with what survives.
    * **A row is 38x54 at radius 7**, on the slot's own plate, and a square
      album cover is letterboxed inside it rather than cropped — board 332's
      whole claim is that the three titles sit on one baseline.
    * **Six states** that 181 did not draw, all reachable: gone, the named
      empty made list, the empty kept list with its own sentence, a row with no
      artwork, a row with no metadata, and rank 10+ beside a long title.

  ## What a ranked list is

  `Kati.Lists.Membership.position` is kept on every list, not only ranked ones
  — a list that becomes ranked should not have to invent an order it never
  recorded. The number is drawn only when the list says it is ranked, right
  aligned in a fixed 22pt column so `10` sits under `1` without widening.
  """
  use Kati.Screens.Pushed, back: "Lists"

  alias Kati.Components.MishkaPill
  alias Kati.Theme.Palette
  alias Kati.UI.Destructive
  alias Kati.UI.SettingsList

  @impl true
  def load(socket) do
    params = socket.assigns.params || %{}

    socket
    |> Mob.Socket.assign(:list, Kati.Lists.Shelf.detail(Map.get(params, :id)))
    |> Mob.Socket.assign(:menu?, false)
    |> Mob.Socket.assign(:confirming?, false)
    |> Mob.Socket.assign(:holding, nil)
    |> Mob.Socket.assign(:renaming?, false)
    |> Mob.Socket.assign(:name, "")
    |> Mob.Socket.assign(:name_epoch, 0)
    |> Mob.Socket.assign(:undo, nil)
    |> Mob.Socket.assign(:undo_member, nil)
    |> Mob.Socket.assign(:error, nil)
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
        {Kati.Screens.ListDetail.header(assigns)}
        {Kati.Screens.ListDetail.body(assigns)}
      </Column>
    </Scroll>
    """
  end

  @doc """
  The back pill, and the ⋯ disc a made list carries.

  A kept list has no menu: Kati fills it, so there is nothing to rename, nothing
  to share and nothing to delete — and a disc with an undrawn menu behind it is
  the new inert tap 181 refused.
  """
  @spec header(map()) :: term()
  def header(%{list: list} = assigns) when is_map(list) do
    if Map.get(list, :kept?) do
      SettingsList.chrome(nil, 44)
    else
      Kati.Screens.ListDetail.menu_row(assigns.menu?)
    end
  end

  def header(_none), do: SettingsList.chrome(nil, 44)

  @doc """
  The 44pt chrome row, with the ⋯ anchored at its right edge.

  The disc alone is the trigger — `Kati.UI.Anchored` measures the trigger to
  place the panel against it, so handing it the whole row would open the menu
  against the row's box and, on this bridge, collapse the row to the trigger's
  own width. `Kati.Screens.Series.more_disc/4` builds it the same way and for
  the same reason.
  """
  @spec menu_row(boolean()) :: term()
  def menu_row(menu?) do
    assigns = %{
      menu:
        Kati.UI.Menu.overflow(
          Kati.Screens.ListDetail.menu_disc(),
          menu?,
          [
            Kati.UI.Menu.item("edit", "Rename", :rename),
            Kati.UI.Menu.item("ios_share", "Share", :share_list),
            Kati.UI.Menu.rule(),
            Kati.UI.Menu.item("delete", "Delete this list", :confirm_delete, destructive: true)
          ],
          dismiss: :close_menu
        )
    }

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} height={44} align="center">
        <Spacer weight={1.0} />
        {@menu}
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc false
  def menu_disc do
    ~MOB"""
    <Box
      width={44}
      height={44}
      corner_radius={22}
      background={Palette.card()}
      shadow={Kati.Theme.shadow_button()}
      align="center"
      on_tap={{self(), :toggle_menu}}
      accessibility_id="toggle_menu"
    >
      {Kati.UI.symbol("more_horiz", size: 21)}
    </Box>
    """
  end

  @doc """
  The list, or the page for one that is not there.

  Board 331: *"Gone and empty are different facts and the code always drew them
  apart."* A gone list takes a pill back to the index rather than a back pill,
  because the page you came from no longer exists.
  """
  @spec body(map()) :: term()
  def body(%{list: nil}) do
    assigns = %{tap: {self(), :open_lists}}

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.eyebrow("Gone — not empty", dash: Kati.Theme.Palette.placeholder())}
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={17}
      >
        <Row fill_width={true} align="center">
          <Spacer weight={1.0} />
          {Kati.UI.symbol("block", size: 21, color: Kati.Theme.Palette.tertiary())}
          <Spacer weight={1.0} />
        </Row>
        <Spacer size={11} />
        <Text
          text="No list here"
          text_size={14.5}
          font_weight="bold"
          text_color={:on_surface}
          text_align="center"
        />
        <Spacer size={7} />
        <Text
          text="It was deleted, perhaps on another device."
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
    </Column>
    """
  end

  def body(%{confirming?: true, list: list}) do
    assigns = %{
      confirm:
        Destructive.confirm(
          eyebrow: "Deleting it",
          title: "Delete " <> list.title <> "?",
          changes: "the list and its " <> list.count <> ".",
          keeps:
            "the titles themselves — they stay on their shelves, with their " <>
              "ratings and history.",
          confirm: {"Delete the list", :delete_list},
          keep: {"Keep it", :keep_list}
        ),
      error: Kati.Screens.ListDetail.error_note(list)
    }

    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.title(list.title, list.count, nil, :name)}
      {@confirm}
      {@error}
    </Column>
    """
  end

  def body(assigns) do
    list = assigns.list

    inner = %{
      list: list,
      naming: Kati.Screens.ListDetail.naming(assigns),
      rows: Kati.Screens.ListDetail.rows(assigns),
      undo: Destructive.undo_bar(assigns.undo, :undo),
      error: Kati.Screens.ListDetail.error_note(assigns)
    }

    assigns = inner

    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.title(@list.title, @list.count, nil, :name)}
      {@naming}
      {@rows}
      {@error}
      {@undo}
    </Column>
    """
  end

  @doc """
  The rename field, or nothing.

  Board 335: one naming grammar, and it is the index's — a 48pt field with a
  `Make it` pill, because *"a field with no commit control depends on a keyboard
  Return key that a reader cannot see."* Renaming reuses it with its own verb.
  """
  @spec naming(map()) :: term()
  def naming(%{renaming?: true} = assigns) do
    assigns = %{
      name: assigns.name,
      epoch: assigns.name_epoch,
      change: {self(), :list_name},
      save: {self(), :save_name},
      cancel: {self(), :cancel_rename}
    }

    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        height={48}
        corner_radius={14}
        background={Palette.card()}
        shadow={Kati.Theme.shadow_card_soft()}
        padding_left={15}
        padding_right={15}
        align="center"
      >
        <TextField
          value={@name}
          placeholder="List name"
          return_key="done"
          weight={1.0}
          accessibility_id="list_name"
          on_change={@change}
          on_submit={@save}
          value_epoch={@epoch}
        />
        <Spacer size={10} />
        {Kati.UI.SettingsList.action_pill("Rename", @save)}
      </Row>
      <Spacer size={9} />
      <Text
        text="Cancel"
        text_size={12.5}
        font_weight="semibold"
        text_color={Palette.sub()}
        on_tap={@cancel}
        accessibility_id="cancel_rename"
      />
      <Spacer size={16} />
    </Column>
    """
  end

  def naming(_resting), do: ~MOB"<Spacer size={0} />"

  @doc """
  The failure, where board 335 hangs it: on the page, under what it failed to
  change, and cleared by the next action rather than by a timer.
  """
  @spec error_note(map()) :: term()
  def error_note(%{error: message}) when is_binary(message),
    do: SettingsList.note("error", message)

  def error_note(_none), do: ~MOB"<Spacer size={0} />"

  @doc """
  Every row, or the empty card for the kind of list this is.

  Board 331 draws two empties and they say different things, because *Add to
  list* is a lie on a shelf you cannot add to.
  """
  @spec rows(map()) :: term()
  def rows(%{list: %{titles: [], kept?: true} = list}) do
    assigns = %{title: list.empty_title, body: list.empty_body}

    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={22}
      shadow={Kati.Theme.shadow_card_soft()}
      padding={17}
    >
      <Text
        text={@title}
        text_size={14.5}
        font_weight="bold"
        text_color={:on_surface}
        text_align="center"
      />
      <Spacer size={7} />
      <Text
        text={@body}
        text_size={12.5}
        line_height={1.55}
        text_color={Palette.sub()}
        text_align="center"
      />
    </Column>
    """
  end

  def rows(%{list: %{titles: []}}) do
    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={22}
      shadow={Kati.Theme.shadow_card_soft()}
      padding={17}
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
        text="Open a film, book or album and tap Add to list."
        text_size={12.5}
        line_height={1.55}
        text_color={Palette.sub()}
        text_align="center"
      />
    </Column>
    """
  end

  def rows(%{list: list, holding: holding}) do
    assigns = %{
      rows:
        list.titles
        |> Enum.with_index()
        |> Enum.map(fn {row, i} ->
          Kati.Screens.ListDetail.title_row(
            row,
            list.ranked?,
            i,
            i < length(list.titles) - 1,
            holding == row.id,
            Map.get(list, :kept?, false)
          )
        end)
    }

    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.card(@rows)}
    </Column>
    """
  end

  @doc false
  def title_row(row, ranked?, index, rule?, holding?, kept?) do
    SettingsList.row(
      Kati.Screens.ListDetail.leading(row, ranked?, index),
      SettingsList.body(row.title, row.sub, fallback: not row.titled?),
      Kati.Screens.ListDetail.trailing(row, ranked?, holding?, kept?),
      rule: rule?,
      on_tap: {self(), String.to_atom("open_title_" <> row.id)},
      on_long_press: unless(kept?, do: {self(), String.to_atom("hold_" <> row.id)})
    )
  end

  @doc """
  The trailing mark: `Remove` while held, a drag handle on a ranked list, a
  chevron otherwise.
  """
  @spec trailing(map(), boolean(), boolean(), boolean()) :: term()
  def trailing(row, _ranked?, true, _kept?), do: Kati.Screens.ListDetail.remove_pill(row)

  def trailing(_row, true, _holding?, _kept?),
    do: Kati.UI.symbol("drag_indicator", size: 18, color: Palette.tertiary())

  def trailing(_row, _plain, _holding?, _kept?),
    do: Kati.UI.symbol("chevron_right", size: 18, color: Palette.tertiary())

  @doc false
  def leading(row, ranked?, index) do
    assigns = %{
      art: Kati.Screens.ListDetail.art(row),
      rank: if(ranked?, do: Integer.to_string(index + 1))
    }

    ~MOB"""
    <Row align="center">
      {Kati.Screens.ListDetail.rank(@rank)}
      {@art}
    </Row>
    """
  end

  @doc """
  The rank, right aligned in a fixed 22pt column.

  Board 331: *"the rank column is right-aligned at a fixed 22px, so 10 and 11
  sit under 1 without widening."*
  """
  @spec rank(String.t() | nil) :: term()
  def rank(nil), do: ~MOB"<Spacer size={0} />"

  def rank(number) do
    assigns = %{number: number}

    ~MOB"""
    <Row align="center">
      <Row width={22} align="center">
        <Spacer weight={1.0} />
        <Text
          text={@number}
          font_family="mono"
          text_size={12}
          text_color={Palette.muted()}
          max_lines={1}
        />
      </Row>
      <Spacer size={10} />
    </Row>
    """
  end

  @doc """
  One 38x54 slot, three fills.

  Board 332. A poster and a cover fill the slot; a square is 38x38 centred in
  it, with 8pt of the slot's own colour showing above and below — *"the
  letterbox bands are the slot's own colour, not a new one, so a square reads
  as art in a slot rather than art with a frame."*

  A member with no artwork falls back to its kind's glyph in the same slot,
  which board 331 draws for an evicted poster.
  """
  @spec art(map()) :: term()
  def art(row) do
    case row.seed && Kati.Design.Images.poster(row.seed) do
      nil -> Kati.Screens.ListDetail.kind_slot(row.kind)
      src -> Kati.Screens.ListDetail.filled_slot(src, row.art)
    end
  end

  @doc false
  def filled_slot(src, :square) do
    assigns = %{src: src}

    ~MOB"""
    <Column
      width={38}
      height={54}
      corner_radius={7}
      background={Palette.placeholder()}
      align="center"
    >
      <Spacer size={8} />
      <Image src={@src} width={38} height={38} corner_radius={4} content_mode="fill" />
      <Spacer size={8} />
    </Column>
    """
  end

  def filled_slot(src, _fills) do
    assigns = %{src: src}

    ~MOB"""
    <Box width={38} height={54} corner_radius={7} background={Palette.placeholder()}>
      <Image src={@src} width={38} height={54} corner_radius={7} content_mode="fill" />
    </Box>
    """
  end

  @doc false
  def kind_slot(kind) do
    assigns = %{glyph: Kati.Screens.ListDetail.kind_glyph(kind)}

    ~MOB"""
    <Box width={38} height={54} corner_radius={7} background={Palette.placeholder()} align="center">
      {Kati.UI.symbol(@glyph, size: 17, color: Kati.Theme.Palette.tertiary())}
    </Box>
    """
  end

  @doc """
  The glyph that stands in for a member's missing artwork.

      iex> Kati.Screens.ListDetail.kind_glyph(:book)
      "menu_book"

      iex> Kati.Screens.ListDetail.kind_glyph(:album)
      "album"

      iex> Kati.Screens.ListDetail.kind_glyph(:series)
      "movie"
  """
  @spec kind_glyph(atom()) :: String.t()
  def kind_glyph(:book), do: "menu_book"
  def kind_glyph(:album), do: "album"
  def kind_glyph(_screen), do: "movie"

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

  # Coming back from a title's own page: it may have been dropped, renamed by a
  # Kind swap, or archived. `Kati.Screens.Resume` announces it and this re-reads
  # the list it is holding.
  @impl true
  def handle_info({:kati, :resumed, _payload}, socket) do
    id = socket.assigns.list && socket.assigns.list.id

    {:noreply,
     socket
     |> Mob.Socket.assign(:list, Kati.Lists.Shelf.detail(id))
     |> Mob.Socket.assign(:holding, nil)}
  end

  def handle_info({:change, :list_name, typed}, socket) when is_binary(typed),
    do: {:noreply, Mob.Socket.assign(socket, :name, typed)}

  def handle_info(message, socket), do: super(message, socket)

  @impl true
  def handle_tap(:toggle_menu, socket),
    do: {:noreply, Mob.Socket.assign(socket, :menu?, not socket.assigns.menu?)}

  def handle_tap(:close_menu, socket), do: {:noreply, Mob.Socket.assign(socket, :menu?, false)}

  def handle_tap(:confirm_delete, socket) do
    {:noreply,
     socket
     |> Mob.Socket.assign(:menu?, false)
     |> Mob.Socket.assign(:confirming?, true)
     |> Mob.Socket.assign(:error, nil)}
  end

  def handle_tap(:keep_list, socket),
    do: {:noreply, Mob.Socket.assign(socket, :confirming?, false)}

  # Board 335: nothing moves until the write returns. A failed delete does NOT
  # pop — the reader is still on the list they tried to delete, which is the
  # whole point of the rule.
  def handle_tap(:delete_list, socket) do
    case socket.assigns.list do
      nil ->
        {:noreply, socket}

      list ->
        case Kati.Lists.Shelf.delete(list.id) do
          :ok ->
            {:noreply, Kati.Screens.Resume.pop(socket)}

          {:error, _reason} ->
            {:noreply,
             socket
             |> Mob.Socket.assign(:confirming?, false)
             |> Mob.Socket.assign(:error, "Couldn’t delete it. Nothing was written.")}
        end
    end
  end

  def handle_tap(:rename, socket) do
    {:noreply,
     socket
     |> Mob.Socket.assign(:menu?, false)
     |> Mob.Socket.assign(:renaming?, true)
     |> Mob.Socket.assign(:name, (socket.assigns.list && socket.assigns.list.title) || "")
     |> Mob.Socket.assign(:name_epoch, socket.assigns.name_epoch + 1)
     |> Mob.Socket.assign(:error, nil)}
  end

  def handle_tap(:cancel_rename, socket),
    do: {:noreply, Mob.Socket.assign(socket, :renaming?, false)}

  def handle_tap(:save_name, socket), do: {:noreply, Kati.Screens.ListDetail.renamed(socket)}

  def handle_tap(:share_list, socket) do
    list = socket.assigns.list

    {:noreply,
     socket
     |> Mob.Socket.assign(:menu?, false)
     |> then(fn s ->
       if list, do: Mob.Share.text(s, Kati.Screens.ListDetail.share_line(list)), else: s
     end)}
  end

  def handle_tap(:undo, socket), do: {:noreply, Kati.Screens.ListDetail.undone(socket)}

  def handle_tap(:open_lists, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Lists)}

  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "hold_" <> id ->
        {:noreply, Mob.Socket.assign(socket, :holding, id)}

      "remove_" <> id ->
        {:noreply, Kati.Screens.ListDetail.removed(socket, id)}

      "open_title_" <> id ->
        {:noreply, Kati.Screens.ListDetail.open(socket, id)}

      _other ->
        {:noreply, socket}
    end
  end

  @doc """
  The sentence a shared list carries out of the app.

      iex> Kati.Screens.ListDetail.share_line(%{title: "Best of 2026", count: "14 titles"})
      "Best of 2026 — 14 titles"
  """
  @spec share_line(map()) :: String.t()
  def share_line(list), do: list.title <> " — " <> list.count

  @doc """
  Rename, or say the name is taken.

  Board 335's duplicate case, on the rename side: the store answers `{:exists,
  clash}` and the page names the count rather than silently doing nothing.
  """
  @spec renamed(Mob.Socket.t()) :: Mob.Socket.t()
  def renamed(socket) do
    list = socket.assigns.list

    case list && Kati.Lists.Shelf.rename(list.id, socket.assigns.name) do
      nil ->
        socket

      {:ok, _renamed} ->
        socket
        |> Mob.Socket.assign(:renaming?, false)
        |> Mob.Socket.assign(:list, Kati.Lists.Shelf.detail(list.id))
        |> Mob.Socket.assign(:error, nil)

      {:exists, clash} ->
        Mob.Socket.assign(
          socket,
          :error,
          clash.name <> " already exists. Nothing was renamed — pick another name."
        )

      {:error, :nothing_to_save} ->
        Mob.Socket.assign(socket, :error, "Name it first.")

      {:error, _reason} ->
        Mob.Socket.assign(socket, :error, "Couldn’t rename it. Nothing was written.")
    end
  end

  @doc """
  Take a member out, and offer the undo board 330 draws.

  Board 335: the row never left until the write returned, so a failed remove has
  nothing to reappear.
  """
  @spec removed(Mob.Socket.t(), String.t()) :: Mob.Socket.t()
  def removed(socket, member_id) do
    list = socket.assigns.list

    # Resolved against the very rows the page drew, never taken from the tag.
    # `Kati.Screens.Library.open_tile/3` states the rule and
    # `Kati.ScreenWriteTargetTest` is what enforces it: a tag naming an id the
    # page is not holding is a write to a row the reader never saw.
    row = list && Enum.find(list.titles, &(&1.id == member_id))

    cond do
      is_nil(row) ->
        socket

      Kati.Lists.Shelf.remove(list.id, row.member) == :ok ->
        socket
        |> Mob.Socket.assign(:list, Kati.Lists.Shelf.detail(list.id))
        |> Mob.Socket.assign(:holding, nil)
        |> Mob.Socket.assign(:undo, "Removed " <> row.title)
        |> Mob.Socket.assign(:undo_member, row.member)
        |> Mob.Socket.assign(:error, nil)

      true ->
        socket
        |> Mob.Socket.assign(:holding, nil)
        |> Mob.Socket.assign(:error, "Couldn’t remove it. Nothing was written.")
    end
  end

  @doc "Put back what the undo bar names."
  @spec undone(Mob.Socket.t()) :: Mob.Socket.t()
  def undone(socket) do
    list = socket.assigns.list
    member = socket.assigns.undo_member

    if list && member do
      Kati.Lists.Shelf.add(%{id: list.id}, member)

      socket
      |> Mob.Socket.assign(:list, Kati.Lists.Shelf.detail(list.id))
      |> Mob.Socket.assign(:undo, nil)
      |> Mob.Socket.assign(:undo_member, nil)
    else
      Mob.Socket.assign(socket, :undo, nil)
    end
  end

  @doc """
  Open the member a row names, on the screen its kind belongs to.

  Resolved against the very list the rows were drawn from, which is
  `Kati.Screens.Library.open_tile/3`'s rule: the row knows which screen it
  opens, and a second query might answer with a different title.
  """
  @spec open(Mob.Socket.t(), String.t()) :: Mob.Socket.t()
  def open(socket, member_id) do
    row = socket.assigns.list && Enum.find(socket.assigns.list.titles, &(&1.id == member_id))

    case row do
      nil -> socket
      %{kind: :film} -> push(socket, Kati.Screens.Film, member_id)
      %{kind: :book} -> push(socket, Kati.Screens.BookDetail, member_id)
      %{kind: :album} -> push(socket, Kati.Screens.AlbumDetail, member_id)
      _series -> push(socket, Kati.Screens.Series, member_id)
    end
  end

  defp push(socket, module, id),
    do: Mob.Socket.push_screen(socket, module, %{id: id, back: "List"})
end
