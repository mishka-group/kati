defmodule Kati.Screens.AddToListFa do
  @moduledoc """
  انتخابگر فهرست — the Persian picker sheet.

  Board **337**, the mirror of 333. It exists because the two locales were
  teaching two different gestures for one action: board 289 said the
  «افزودن به فهرست» buttons on 69 and 76 *"land here too"* — on the Lists
  index — while 182 rules for English that the control opens a sheet **over the
  page you are on**, because a list is filled from a title. 337 settles it in
  Persian's favour of the sheet, and names the sentence on 289 that changes.

  ## The label

  337 also rules the string. Screens 69 and 76 carried «فهرست» — a noun, not an
  action, on a control that writes — and the longer «افزودن به فهرست» existed
  nowhere in the app. Both screens render the verb now, and the board says why:
  *«فهرست» یک اسم است، نه یک کار.*

  ## The failure line

  «اضافه نشد. چیزی نوشته نشد.» is the exact mirror of 182's sentence, and it is
  the FIRST Persian save-failure string in this app — `D-60`'s whole subject is
  that no Persian screen could say a save failed. Like 335's, it clears on the
  next tap or when the sheet closes, never on a timer.
  """
  use Mob.Screen

  import Mob.Sigil

  alias Kati.I18n.Digits
  alias Kati.Screens.AddToList
  alias Kati.Theme.Palette
  alias Kati.UI

  @impl true
  def mount(params, _session, socket) do
    Kati.Theme.activate()
    Kati.Locale.activate()

    members = AddToList.members(params)

    {:ok,
     socket
     |> Mob.Socket.assign(:members, members)
     |> Mob.Socket.assign(:subject, params && params[:title])
     |> Mob.Socket.assign(:lists, Kati.Lists.Shelf.made())
     |> Mob.Socket.assign(:kept, Kati.Lists.Shelf.kept())
     |> Mob.Socket.assign(:naming?, false)
     |> Mob.Socket.assign(:name, "")
     |> Mob.Socket.assign(:name_epoch, 0)
     |> Mob.Socket.assign(:failed, nil)
     |> Mob.Socket.assign(:error, nil)}
  end

  @impl true
  def render(assigns) do
    Kati.UI.Sheet.sheet(
      "انتخابگر فهرست",
      Kati.Screens.AddToListFa.content(assigns),
      Kati.Screens.Identity.of(__MODULE__),
      face: "fa"
    )
  end

  @doc false
  def content(%{lists: []} = assigns) do
    inner = %{naming: Kati.Screens.AddToListFa.naming(assigns)}
    assigns = inner

    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.BookDetailFa.fa("هنوز فهرستی ندارید", 14.5, :on_surface, weight: "bold", align: "center")}
      <Spacer size={7} />
      {Kati.Screens.BookDetailFa.fa("یکی بسازید تا همین حالا داخلش برود.", 12.5, Kati.Theme.Palette.sub(), align: "center", lines: 2)}
      <Spacer size={16} />
      {@naming}
      {Kati.Screens.AddToListFa.error_note(assigns)}
    </Column>
    """
  end

  def content(assigns) do
    inner = %{
      head: Kati.Screens.AddToListFa.header(assigns),
      rows: Kati.Screens.AddToListFa.rows(assigns),
      kept: Kati.Screens.AddToListFa.kept_rows(assigns),
      naming: Kati.Screens.AddToListFa.new_list(assigns)
    }

    assigns = inner

    ~MOB"""
    <Column fill_width={true}>
      {@head}
      {@rows}
      <Spacer size={14} />
      {@kept}
      <Spacer size={14} />
      {@naming}
      {Kati.Screens.AddToListFa.error_note(assigns)}
    </Column>
    """
  end

  @doc """
  The failure, where 335 hangs it and in the Persian words 337 writes.

  «اضافه نشد. چیزی نوشته نشد.» is the first Persian save-failure string in this
  app — `D-60`'s whole subject is that no Persian screen could say a save
  failed. It clears on the next tap or when the sheet closes, never on a timer.
  """
  @spec error_note(map()) :: term()
  def error_note(%{error: message}) when is_binary(message) do
    assigns = %{message: message}

    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={12} />
      <Row
        fill_width={true}
        corner_radius={18}
        background={Kati.Theme.Palette.red_wash()}
        padding={13}
        align="center"
      >
        {Kati.UI.symbol("error", size: 17, color: Kati.Theme.Palette.red())}
        <Spacer size={10} />
        {Kati.Screens.BookDetailFa.fa(@message, 12.5, Kati.Theme.Palette.red(), lines: 2)}
      </Row>
    </Column>
    """
  end

  def error_note(_none), do: ~MOB"<Spacer size={0} />"

  @doc false
  def header(%{subject: nil}), do: ~MOB"<Spacer size={0} />"

  def header(assigns) do
    inner = %{name: assigns.subject, count: Kati.Screens.AddToListFa.in_lists(assigns)}
    assigns = inner

    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.BookDetailFa.fa(@name, 13.5, :on_surface, weight: "semibold", align: "center")}
      <Spacer size={3} />
      {Kati.Screens.BookDetailFa.fa(@count, 11, Kati.Theme.Palette.meta(), align: "center")}
      <Spacer size={14} />
    </Column>
    """
  end

  @doc """
  در ۱ فهرست — board 334's second-open line, in Persian.

      iex> Kati.Screens.AddToListFa.in_lists(%{members: [{:book, "b"}], lists: []})
      "در هیچ فهرستی نیست"
  """
  @spec in_lists(map()) :: String.t()
  def in_lists(assigns) do
    case AddToList.holding(assigns) do
      0 -> "در هیچ فهرستی نیست"
      n -> "در " <> Digits.to_persian(n) <> " فهرست"
    end
  end

  @doc false
  def rows(assigns) do
    rows =
      assigns.lists
      |> Enum.with_index()
      |> Enum.map(fn {list, i} ->
        Kati.UI.SettingsList.row(
          Kati.UI.SettingsList.icon_tile("bookmarks"),
          Kati.Screens.AddToListFa.body(list, assigns.failed),
          AddToList.tick(AddToList.state(list, assigns.members)),
          rule: i < length(assigns.lists) - 1,
          on_tap: {self(), String.to_atom("toggle_" <> list.id)}
        )
      end)

    Kati.UI.SettingsList.card(rows)
  end

  @doc false
  def body(list, failed) do
    line =
      if failed == list.id,
        do: "اضافه نشد. چیزی نوشته نشد.",
        else: Kati.Screens.AddToListFa.count(list)

    assigns = %{title: list.title, line: line}

    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.BookDetailFa.fa(@title, 13.5, :on_surface, weight: "semibold")}
      <Spacer size={3} />
      {Kati.Screens.BookDetailFa.fa(@line, 11.5, Kati.Theme.Palette.sub())}
    </Column>
    """
  end

  @doc """
  ۱۴ عنوان · رتبه‌بندی‌شده.

      iex> Kati.Screens.AddToListFa.count(%{count: "3 titles", badge: nil})
      "۳ عنوان"

      iex> Kati.Screens.AddToListFa.count(%{count: "14 titles", badge: "ranked"})
      "۱۴ عنوان · رتبه‌بندی‌شده"
  """
  @spec count(map()) :: String.t()
  def count(list) do
    n = list.count |> String.split(" ") |> Elixir.List.first() |> Digits.to_persian()

    case Map.get(list, :badge) do
      "ranked" -> n <> " عنوان · رتبه‌بندی‌شده"
      "shared" -> n <> " عنوان · هم‌رسان"
      _plain -> n <> " عنوان"
    end
  end

  @doc false
  def kept_rows(assigns) do
    rows =
      assigns.kept
      |> Enum.with_index()
      |> Enum.map(fn {row, i} ->
        Kati.UI.SettingsList.row(
          Kati.UI.SettingsList.icon_tile(row.icon),
          Kati.Screens.AddToListFa.kept_body(row),
          UI.symbol("lock", size: 17, color: Palette.tertiary()),
          rule: i < length(assigns.kept) - 1
        )
      end)

    Kati.UI.SettingsList.card(rows)
  end

  @doc false
  def kept_body(row) do
    assigns = %{title: Kati.Screens.AddToListFa.kept_word(row.id)}

    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.BookDetailFa.fa(@title, 13.5, Kati.Theme.Palette.sub(), weight: "semibold")}
      <Spacer size={3} />
      {Kati.Screens.BookDetailFa.fa("کاتی پرش می‌کند — افزودنی نیست", 11.5, Kati.Theme.Palette.sub())}
    </Column>
    """
  end

  @doc """
      iex> Kati.Screens.AddToListFa.kept_word("kept:abandoned")
      "رهاشده"

      iex> Kati.Screens.AddToListFa.kept_word("kept:rewatches")
      "بازتماشا"
  """
  @spec kept_word(String.t()) :: String.t()
  def kept_word("kept:abandoned"), do: "رهاشده"
  def kept_word("kept:rewatches"), do: "بازتماشا"
  def kept_word(_other), do: "نگه‌داشته"

  @doc false
  def new_list(%{naming?: true} = assigns), do: Kati.Screens.AddToListFa.naming(assigns)

  def new_list(_resting) do
    ~MOB"""
    <Row
      fill_width={true}
      height={48}
      corner_radius={14}
      background={Palette.card()}
      padding_left={15}
      padding_right={15}
      align="center"
      on_tap={{self(), :new_list}}
      accessibility_id="new_list"
    >
      {Kati.UI.symbol("add", size: 18, color: Kati.Theme.Palette.sub())}
      <Spacer size={11} />
      {Kati.Screens.BookDetailFa.fa("فهرست تازه", 13.5, Kati.Theme.Palette.sub(), weight: "semibold")}
    </Row>
    """
  end

  @doc "بساز و اضافه کن — 335's one field, in Persian."
  @spec naming(map()) :: term()
  def naming(assigns) do
    inner = %{name: assigns.name, epoch: assigns.name_epoch}
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
        font_family="fa"
        placeholder="نام فهرست"
        return_key="done"
        weight={1.0}
        accessibility_id="list_name"
        on_change={{self(), :list_name}}
        on_submit={{self(), :save_list}}
        value_epoch={@epoch}
      />
      <Spacer size={10} />
      <Row
        height={34}
        corner_radius={17}
        background={Palette.ink_fill()}
        padding_left={14}
        padding_right={14}
        align="center"
        on_tap={{self(), :save_list}}
        accessibility_id="save_list"
      >
        {Kati.Screens.BookDetailFa.fa("بساز و اضافه کن", 12, Kati.Theme.Palette.on_ink(), weight: "bold")}
      </Row>
    </Row>
    """
  end

  @impl true
  def handle_info({:tap, :close}, socket), do: {:noreply, Kati.Screens.Resume.pop(socket)}

  def handle_info({:tap, :new_list}, socket) do
    {:noreply,
     socket
     |> Mob.Socket.assign(:naming?, true)
     |> Mob.Socket.assign(:name, "")
     |> Mob.Socket.assign(:name_epoch, socket.assigns.name_epoch + 1)}
  end

  def handle_info({:change, :list_name, typed}, socket) when is_binary(typed),
    do: {:noreply, Mob.Socket.assign(socket, :name, typed)}

  def handle_info({:tap, :save_list}, socket),
    do: {:noreply, Kati.Screens.AddToListFa.made(socket)}

  def handle_info({:submit, :save_list}, socket),
    do: {:noreply, Kati.Screens.AddToListFa.made(socket)}

  def handle_info({:tap, tag}, socket) when is_atom(tag) do
    case Atom.to_string(tag) do
      "toggle_" <> id -> {:noreply, AddToList.toggled(socket, id)}
      _other -> {:noreply, socket}
    end
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  @doc false
  @spec made(Mob.Socket.t()) :: Mob.Socket.t()
  def made(socket) do
    case Kati.Lists.Shelf.create(socket.assigns.name) do
      {:ok, list} ->
        socket |> Mob.Socket.assign(:error, nil) |> AddToList.fill(list)

      {:exists, list} ->
        socket
        |> Mob.Socket.assign(:error, "«" <> list.name <> "» از قبل هست — به همان اضافه شد.")
        |> AddToList.fill(list)

      {:error, :nothing_to_save} ->
        Mob.Socket.assign(socket, :error, "اول نامش را بنویسید.")

      {:error, _reason} ->
        Mob.Socket.assign(socket, :error, "ساخته نشد. چیزی نوشته نشد.")
    end
  end
end
