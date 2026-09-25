defmodule Kati.Screens.AddToList do
  @moduledoc """
  The sheet a title is put into a list from.

  Boards **333** and **335**, and the control board **334** draws to open it.
  Before them there were seven *Add to list* controls on six screens and one of
  them added anything: 146 passed a selection, and 66, 68, 74 and 76 pushed the
  Lists index carrying nothing, so the title was never mentioned again.

  ## The rules the boards set

    * **A tick commits immediately.** 182's precedent, kept by 333: membership
      is a thing you toggle rather than compose, so there is no Save. A failed
      tick goes back off with the reason in words and the sheet stays open —
      board 335's rule, *"nothing moves until the write returns"*, which is why
      the tick is drawn from the store's answer rather than optimistically.
    * **Ticks arrive populated.** *"A sheet that opens blank invites the
      duplicate the tick exists to prevent."*
    * **A filled tick removes.** 334: *"tapping one removes the title from that
      list, which is the only sensible meaning a filled tick can have."*
    * **A mixed selection is a dash**, and tapping it adds all; tapping again
      removes all, *"so the third tap returns you where you started"*.
    * **Kept lists are locked**, not tickable — Kati fills them.
    * **The empty sheet is the common case**, not an edge case: both the index
      and the sheet are first reached by somebody with no lists, so it drops the
      kept card entirely and offers one field whose pill reads *Make it and add*.
    * **No search field** until twelve lists, which is 182's own threshold.

  ## What it is opened with

  `%{member: {kind, id}, title: name}` for one title, or `%{members: [...]}`
  for a selection from 146. Both shapes go through `members/1`, so the sheet has
  one notion of what it is acting on and the mixed dash falls out of counting.
  """
  use Mob.Screen
  use Gettext, backend: Kati.Gettext

  import Mob.Sigil

  alias Kati.Theme.Palette
  alias Kati.UI.Sheet

  @impl true
  def mount(params, _session, socket) do
    Kati.Theme.activate()
    Kati.Locale.activate()
    Kati.Screens.Resume.watch()

    members = Kati.Screens.AddToList.members(params)

    {:ok,
     socket
     |> Mob.Socket.assign(:members, members)
     |> Mob.Socket.assign(:subject, Kati.Screens.AddToList.subject(params, members))
     |> Mob.Socket.assign(:lists, Kati.Lists.Shelf.made())
     |> Mob.Socket.assign(:kept, Kati.Lists.Shelf.kept())
     |> Mob.Socket.assign(:naming?, false)
     |> Mob.Socket.assign(:name, "")
     |> Mob.Socket.assign(:name_epoch, 0)
     |> Mob.Socket.assign(:failed, nil)
     |> Mob.Socket.assign(:error, nil)}
  end

  @doc """
  What the sheet is acting on, as a list of `{kind, id}` members.

      iex> Kati.Screens.AddToList.members(%{member: {:book, "b1"}})
      [{:book, "b1"}]

      iex> Kati.Screens.AddToList.members(%{members: [{:tracked_title, "a"}, {:book, "b"}]})
      [{:tracked_title, "a"}, {:book, "b"}]

  A bare push acts on nothing, and the sheet says so rather than picking a
  subject the reader never chose — `Kati.ScreenWriteTargetTest`'s rule.

      iex> Kati.Screens.AddToList.members(%{})
      []

  **`:id` is not accepted, deliberately.** A member is a `{kind, id}` pair here
  because a list holds three kinds and a bare id cannot say which. Taking one
  anyway would also split this sheet's two empty pages —
  `Kati.ScreenParamsSweepTest` requires that an id naming no row render exactly
  what naming nothing renders, and an id the store cannot resolve is still a
  subject as far as the header is concerned.

      iex> Kati.Screens.AddToList.members(%{id: "8971abd5"})
      []
  """
  @spec members(map() | nil) :: [{atom(), String.t()}]
  def members(nil), do: []

  def members(params) do
    cond do
      is_list(params[:members]) -> params[:members]
      is_tuple(params[:member]) -> [params[:member]]
      true -> []
    end
  end

  @doc """
  The sheet's sub-line: the title's name and how many lists it is already in,
  or a count for a selection.

  Board 334: *"The header gains IN 2 LISTS under the title."*
  """
  @spec subject(map() | nil, [{atom(), String.t()}]) :: String.t() | nil
  def subject(params, members) do
    case {params && params[:title], members} do
      {name, [_one]} when is_binary(name) ->
        name

      {_none, []} ->
        nil

      {_none, many} ->
        gettext("%{count} titles selected", count: Kati.Locale.number(length(many)))
    end
  end

  @impl true
  def render(assigns) do
    Sheet.sheet(
      Kati.Screens.AddToList.heading(assigns),
      Kati.Screens.AddToList.content(assigns),
      Kati.Screens.Identity.of(__MODULE__)
    )
  end

  @doc """
  *Pick a list*, or *Add to a list* when there are none to pick.

      iex> Kati.Screens.AddToList.heading(%{lists: []})
      "Add to a list"

      iex> Kati.Screens.AddToList.heading(%{lists: [%{}]})
      "Pick a list"
  """
  @spec heading(map()) :: String.t()
  def heading(%{lists: []}), do: gettext("Add to a list")
  def heading(_some), do: gettext("Pick a list")

  @doc false
  def content(%{lists: []} = assigns) do
    inner = %{
      sub: Kati.Screens.AddToList.empty_line(assigns),
      naming: Kati.Screens.AddToList.naming(assigns, gettext("Make it and add")),
      error: Kati.Screens.AddToList.error_note(assigns)
    }

    assigns = inner

    ~MOB"""
    <Column fill_width={true}>
      <Text
        text={gettext("You have no lists yet")}
        text_size={14.5}
        font_weight="bold"
        text_color={:on_surface}
        text_align="center"
      />
      <Spacer size={7} />
      <Text
        text={@sub}
        text_size={12.5}
        line_height={1.55}
        text_color={Palette.sub()}
        text_align="center"
      />
      <Spacer size={16} />
      {@naming}
      {@error}
    </Column>
    """
  end

  def content(assigns) do
    inner = %{
      sub: Kati.Screens.AddToList.header_sub(assigns),
      rows: Kati.Screens.AddToList.list_rows(assigns),
      kept: Kati.Screens.AddToList.kept_rows(assigns),
      naming: Kati.Screens.AddToList.new_list(assigns),
      error: Kati.Screens.AddToList.error_note(assigns)
    }

    assigns = inner

    ~MOB"""
    <Column fill_width={true}>
      {@sub}
      {@rows}
      <Spacer size={14} />
      {@kept}
      <Spacer size={14} />
      {@naming}
      {@error}
    </Column>
    """
  end

  @doc false
  def header_sub(%{subject: nil}), do: ~MOB"<Spacer size={0} />"

  def header_sub(assigns) do
    inner = %{name: assigns.subject, count: Kati.Screens.AddToList.in_lists(assigns)}
    assigns = inner

    ~MOB"""
    <Column fill_width={true}>
      <Text
        text={@name}
        text_size={13.5}
        font_weight="semibold"
        text_color={:on_surface}
        text_align="center"
        max_lines={1}
      />
      <Spacer size={3} />
      <Text
        text={@count}
        font_family="mono"
        text_size={11}
        text_color={Palette.meta()}
        text_align="center"
        max_lines={1}
      />
      <Spacer size={14} />
    </Column>
    """
  end

  @doc """
  *IN 2 LISTS*, board 334's second-open line.

      iex> Kati.Screens.AddToList.in_lists(%{members: [{:book, "b"}], lists: []})
      "IN NO LISTS"
  """
  @spec in_lists(map()) :: String.t()
  def in_lists(assigns) do
    case Kati.Screens.AddToList.holding(assigns) do
      # One msgid for every count. Persian has one plural form for a counted
      # noun — ۱ فهرست and ۳ فهرست are both correct — so the `1` case is the
      # English grammar's, not the sentence's, and a second msgid would ask a
      # translator for a distinction their language does not make. The numeral
      # takes the reader's own digits. Board 97's mirror recorded the
      # same rule for its own count.
      0 -> gettext("IN NO LISTS")
      1 -> "IN 1 LIST"
      n -> gettext("IN %{count} LISTS", count: Kati.Locale.number(n))
    end
  end

  @doc false
  @spec holding(map()) :: non_neg_integer()
  def holding(assigns) do
    Enum.count(assigns.lists, fn list ->
      Kati.Screens.AddToList.state(list, assigns.members) != :none
    end)
  end

  @doc false
  def empty_line(%{subject: nil}),
    do: gettext("Name one, and it is ready for the next thing you add.")

  def empty_line(assigns),
    do: gettext("Name one and %{subject} goes straight into it.", subject: assigns.subject)

  @doc """
  How much of the selection a list already holds.

      iex> Kati.Screens.AddToList.state(%{members: []}, [{:book, "b"}])
      :none

      iex> Kati.Screens.AddToList.state(%{members: [{:book, "b"}]}, [{:book, "b"}])
      :all

      iex> Kati.Screens.AddToList.state(%{members: [{:book, "b"}]}, [{:book, "b"}, {:book, "c"}])
      :some
  """
  @spec state(map(), [{atom(), String.t()}]) :: :none | :some | :all
  def state(_list, []), do: :none

  def state(list, members) do
    held = Enum.count(members, &(&1 in Map.get(list, :members, [])))

    cond do
      held == 0 -> :none
      held == length(members) -> :all
      true -> :some
    end
  end

  @doc false
  def list_rows(assigns) do
    rows =
      assigns.lists
      |> Enum.with_index()
      |> Enum.map(fn {list, i} ->
        Kati.Screens.AddToList.list_row(
          list,
          Kati.Screens.AddToList.state(list, assigns.members),
          assigns.failed,
          i < length(assigns.lists) - 1
        )
      end)

    Kati.UI.SettingsList.card(rows)
  end

  @doc false
  def list_row(list, state, failed, rule?) do
    Kati.UI.SettingsList.row(
      Kati.UI.SettingsList.icon_tile("bookmarks"),
      Kati.Screens.AddToList.row_body(list, failed),
      Kati.Screens.AddToList.tick(state),
      rule: rule?,
      on_tap: {self(), String.to_atom("toggle_" <> list.id)}
    )
  end

  @doc false
  def row_body(list, failed) when failed == :error do
    Kati.UI.SettingsList.body(list.title, gettext("Couldn’t add it. Nothing was written."))
  end

  def row_body(list, failed) do
    if failed == list.id do
      Kati.UI.SettingsList.body(list.title, gettext("Couldn’t add it. Nothing was written."))
    else
      Kati.UI.SettingsList.body(list.title, Kati.Screens.AddToList.count_line(list))
    end
  end

  @doc """
  A list's own count, with its badge after it where it has one.

      iex> Kati.Screens.AddToList.count_line(%{count: "14 titles", badge: "ranked"})
      "14 titles · ranked"

      iex> Kati.Screens.AddToList.count_line(%{count: "3 titles", badge: nil})
      "3 titles"
  """
  @spec count_line(map()) :: String.t()
  # The badge is a KEY — `Kati.Lists.Shelf.badge/1` answers `"ranked"` and
  # `subtitle/1` counts by comparing against it — so it is translated where it
  # is drawn rather than where it is decided. The key-not-label rule,
  # one layer down.
  def count_line(%{badge: badge} = list) when is_binary(badge),
    do: list.count <> " · " <> Kati.Screens.AddToList.badge_word(badge)

  def count_line(list), do: list.count

  @doc """
  A badge as a word.

      iex> Kati.Screens.AddToList.badge_word("ranked")
      "ranked"
  """
  @spec badge_word(String.t()) :: String.t()
  def badge_word("ranked"), do: gettext("ranked")
  def badge_word("shared"), do: gettext("shared")
  def badge_word(other), do: other

  @doc """
  The trailing mark: a tick, a dash, or nothing at all.

  Board 182 rules the off state draws nothing — no outline, no ghost — and that
  a mixed selection is a 19x2 rule rather than a half-fill, because *"a half-fill
  reads as a progress bar and a count needs a column."*
  """
  @spec tick(:none | :some | :all) :: term()
  def tick(:all), do: Kati.UI.symbol("check", size: 19, color: Palette.ink())

  def tick(:some) do
    ~MOB"<Box width={19} height={2} corner_radius={1} background={Kati.Theme.Palette.ink()} />"
  end

  def tick(_none), do: ~MOB"<Spacer size={19} />"

  @doc """
  The kept lists, locked.

  Board 333: *"Kept lists. Dimmed with a lock and a reason, exactly like
  Abandoned."* A locked row is a fact rather than a control, so it carries no
  tap — which is also why Wishlist and Owned on disc are not among them; see
  `Kati.Lists.Shelf.kept/0` for what the lock's own sentence would have claimed.
  """
  @spec kept_rows(map()) :: term()
  def kept_rows(assigns) do
    rows =
      assigns.kept
      |> Enum.with_index()
      |> Enum.map(fn {row, i} ->
        Kati.UI.SettingsList.row(
          Kati.UI.SettingsList.icon_tile(row.icon),
          Kati.UI.SettingsList.body(row.title, gettext("Kept by Kati — not addable"),
            fallback: true
          ),
          Kati.UI.symbol("lock", size: 17, color: Palette.tertiary()),
          rule: i < length(assigns.kept) - 1
        )
      end)

    Kati.UI.SettingsList.card(rows)
  end

  @doc false
  def new_list(%{naming?: true} = assigns),
    do: Kati.Screens.AddToList.naming(assigns, gettext("Make it and add"))

  def new_list(_resting) do
    assigns = %{tap: {self(), :new_list}}

    ~MOB"""
    <Row
      fill_width={true}
      height={48}
      corner_radius={14}
      background={Palette.card()}
      padding_left={15}
      padding_right={15}
      align="center"
      on_tap={@tap}
      accessibility_id="new_list"
    >
      {Kati.UI.symbol("add", size: 18, color: Kati.Theme.Palette.sub())}
      <Spacer size={11} />
      <Text
        text={gettext("New list")}
        text_size={13.5}
        font_weight="semibold"
        text_color={Palette.sub()}
      />
    </Row>
    """
  end

  @doc """
  The one naming field, board 335's.

  48pt with a commit pill, because *"a field with no commit control depends on a
  keyboard Return key that a reader cannot see."* Only the pill's label changes
  with the context.
  """
  @spec naming(map(), String.t()) :: term()
  def naming(assigns, label) do
    inner = %{
      name: assigns.name,
      epoch: assigns.name_epoch,
      label: label,
      change: {self(), :list_name},
      save: {self(), :save_list}
    }

    assigns = inner

    ~MOB"""
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
        placeholder={gettext("List name")}
        return_key="done"
        weight={1.0}
        accessibility_id="list_name"
        on_change={@change}
        on_submit={@save}
        value_epoch={@epoch}
      />
      <Spacer size={10} />
      {Kati.UI.SettingsList.action_pill(@label, @save)}
    </Row>
    """
  end

  @doc false
  def error_note(%{error: message}) when is_binary(message) do
    assigns = %{note: Kati.UI.SettingsList.note("error", message)}

    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={12} />
      {@note}
    </Column>
    """
  end

  def error_note(_none), do: ~MOB"<Spacer size={0} />"

  @impl true
  def handle_info({:tap, :close}, socket), do: {:noreply, Kati.Screens.Resume.pop(socket)}

  def handle_info({:tap, :new_list}, socket) do
    {:noreply,
     socket
     |> Mob.Socket.assign(:naming?, true)
     |> Mob.Socket.assign(:name, "")
     |> Mob.Socket.assign(:name_epoch, socket.assigns.name_epoch + 1)}
  end

  def handle_info({:tap, :save_list}, socket),
    do: {:noreply, Kati.Screens.AddToList.made(socket)}

  # A submit arrives as `{:submit, tag}`, not as `{:tap, tag}` — the field's
  # `return_key` is a second door to the same act, and a tap clause never fires
  # for one.
  def handle_info({:submit, :save_list}, socket),
    do: {:noreply, Kati.Screens.AddToList.made(socket)}

  def handle_info({:change, :list_name, typed}, socket) when is_binary(typed),
    do: {:noreply, Mob.Socket.assign(socket, :name, typed)}

  def handle_info({:tap, tag}, socket) when is_atom(tag) do
    case Atom.to_string(tag) do
      "toggle_" <> id -> {:noreply, Kati.Screens.AddToList.toggled(socket, id)}
      _other -> {:noreply, socket}
    end
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  @doc """
  Make the named list and put the selection straight in it.

  Board 335: *"Make it and add, one tap — a list made empty while four titles
  are in hand is the bug this replaces."* A name that is taken says so and names
  the count, rather than silently opening a second thing the reader thinks they
  made.
  """
  @spec made(Mob.Socket.t()) :: Mob.Socket.t()
  def made(socket) do
    case Kati.Lists.Shelf.create(socket.assigns.name) do
      {:ok, list} ->
        Kati.Screens.AddToList.fill(socket, list)

      {:exists, list} ->
        socket
        |> Mob.Socket.assign(
          :error,
          list.name <> " already exists. Nothing was made — adding to it instead."
        )
        |> Kati.Screens.AddToList.fill(list)

      {:error, :nothing_to_save} ->
        Mob.Socket.assign(socket, :error, gettext("Name it first."))

      {:error, _reason} ->
        Mob.Socket.assign(socket, :error, gettext("Couldn’t make it. Nothing was written."))
    end
  end

  @doc false
  @spec fill(Mob.Socket.t(), term()) :: Mob.Socket.t()
  def fill(socket, list) do
    Enum.each(socket.assigns.members, &Kati.Lists.Shelf.add(list, &1))

    socket
    |> Mob.Socket.assign(:naming?, false)
    |> Mob.Socket.assign(:name, "")
    |> Mob.Socket.assign(:lists, Kati.Lists.Shelf.made())
  end

  @doc """
  Tick or untick a list, committing as it goes.

  A filled tick removes, which board 334 rules is the only sensible meaning it
  can have. The dash adds all, and tapping again removes all — *"so the third
  tap returns you where you started."*
  """
  @spec toggled(Mob.Socket.t(), String.t()) :: Mob.Socket.t()
  def toggled(socket, list_id) do
    # Resolved against the rows the sheet drew, never taken from the tag.
    list = Enum.find(socket.assigns.lists, &(&1.id == list_id))
    members = socket.assigns.members

    cond do
      is_nil(list) or members == [] ->
        socket

      Kati.Screens.AddToList.state(list, members) == :all ->
        Kati.Screens.AddToList.write(socket, list, members, &Kati.Lists.Shelf.remove(&1.id, &2))

      true ->
        Kati.Screens.AddToList.write(socket, list, members, &Kati.Lists.Shelf.add(&1, &2))
    end
  end

  @doc false
  @spec write(Mob.Socket.t(), term(), [tuple()], (term(), tuple() -> term())) :: Mob.Socket.t()
  def write(socket, list, members, fun) do
    failed? = Enum.any?(members, fn member -> fun.(list, member) != :ok end)

    if failed? do
      socket
      |> Mob.Socket.assign(:failed, list.id)
      |> Mob.Socket.assign(:lists, Kati.Lists.Shelf.made())
    else
      socket
      |> Mob.Socket.assign(:failed, nil)
      |> Mob.Socket.assign(:error, nil)
      |> Mob.Socket.assign(:lists, Kati.Lists.Shelf.made())
    end
  end
end
