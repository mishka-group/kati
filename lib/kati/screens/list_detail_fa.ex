defmodule Kati.Screens.ListDetailFa do
  @moduledoc """
  یک فهرست — one list, in Persian.

  Board **336**. Until 7 September a Persian reader could open فهرست‌ها, tap any
  of its seven rows, and land on an English left-to-right page: board 289 drew
  the index and `Kati.Screens.ListDetail` was the only destination, with
  `use Kati.Screens.Pushed, back: "Lists"` and a `sub/1` that answered only
  `"Film"` or `"Series"`. There was no `ListDetailFa` at all.

  ## What is shared and what is not

  The READ is `Kati.Lists.Shelf.detail/1`'s, and that is deliberate — the same
  doctrine `Kati.Screens.AlbumDetailFa` states for a record: *one list, read
  once, presented twice.* What this screen supplies is the Persian half: the
  chrome, the digits, the kind words, and the two empty sentences 336 draws
  apart from each other.

  Every numeral goes through `Kati.I18n.Digits.to_persian/1`, and the rank column
  stays DM Mono and stays LEFT aligned — the mirror of the Latin board's right
  — so ۱۰ sits under ۱ without widening. 336's own annotation is the authority
  for both.
  """
  use Mob.Screen

  import Mob.Sigil

  alias Kati.I18n.Digits
  alias Kati.Screens.BookDetailFa, as: Fa
  alias Kati.Theme.Palette
  alias Kati.UI

  @impl true
  def mount(params, _session, socket) do
    Kati.Theme.activate()
    Kati.Locale.activate()

    {:ok,
     socket
     |> Mob.Socket.assign(:list, Kati.Lists.Shelf.detail(Map.get(params || %{}, :id)))
     |> Mob.Socket.assign(:confirming?, false)
     |> Mob.Socket.assign(:menu?, false)
     |> Mob.Socket.assign(:error, nil)}
  end

  @impl true
  def render(assigns) do
    Kati.Screens.Fa.pushed_frame(
      Kati.Screens.ListDetailFa.content(assigns),
      Kati.Screens.Identity.of(__MODULE__)
    )
  end

  @doc false
  def content(assigns) do
    inner = %{body: Kati.Screens.ListDetailFa.body(assigns)}
    assigns = inner

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {Kati.Screens.ListDetailFa.chrome()}
        {@body}
      </Column>
    </Scroll>
    """
  end

  @doc "فهرست‌ها — the back pill, pointing the way a Persian reader goes back."
  @spec chrome() :: map()
  def chrome do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Row
          height={44}
          corner_radius={22}
          background={Palette.card()}
          shadow={Kati.Theme.shadow_button()}
          padding_left={12}
          padding_right={16}
          align="center"
          on_tap={{self(), :back}}
        >
          {UI.symbol("arrow_forward_ios", size: 17)}
          <Spacer size={6} />
          {Fa.fa("فهرست‌ها", 13.5, :on_surface, weight: "semibold")}
        </Row>
        <Spacer weight={1.0} />
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc """
  رفته — که خالی نیست. Gone, which is not empty.

  336 mirrors 331's rule and its own annotation states the consequence: all
  seven of 289's rows reach here, and before this they reached an English page.
  """
  @spec body(map()) :: term()
  def body(%{list: nil}) do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={17}
      >
        <Row fill_width={true} align="center">
          <Spacer weight={1.0} />
          {UI.symbol("block", size: 21, color: Kati.Theme.Palette.tertiary())}
          <Spacer weight={1.0} />
        </Row>
        <Spacer size={11} />
        {Fa.fa("فهرستی اینجا نیست", 14.5, :on_surface, weight: "bold", align: "center")}
        <Spacer size={7} />
        {Fa.fa("حذف شده — شاید روی دستگاه دیگری.", 12.5, Kati.Theme.Palette.sub(),
          align: "center",
          lines: 2
        )}
        <Spacer size={16} />
        <Row fill_width={true} align="center">
          <Spacer weight={1.0} />
          <Row
            height={38}
            corner_radius={19}
            background={Palette.ink_fill()}
            padding_left={16}
            padding_right={16}
            align="center"
            on_tap={{self(), :open_lists}}
          >
            {Fa.fa("فهرست‌های شما", 12.5, Kati.Theme.Palette.on_ink(), weight: "bold")}
          </Row>
          <Spacer weight={1.0} />
        </Row>
      </Column>
    </Column>
    """
  end

  def body(%{confirming?: true, list: list}) do
    inner = %{
      title: "«" <> list.title <> "» حذف شود؟",
      changes: "فهرست و " <> Kati.Screens.ListDetailFa.count(list) <> " عضویتش.",
      keeps: "خود عنوان‌ها — با امتیاز و تاریخچه‌شان در قفسه می‌مانند."
    }

    assigns = inner

    ~MOB"""
    <Column fill_width={true}>
      <Column fill_width={true} background={Palette.cream()} corner_radius={22} padding={17}>
        <Row fill_width={true} align="center">
          {UI.symbol("error", size: 18, color: Kati.Theme.Palette.gold_icon())}
          <Spacer size={11} />
          {Fa.fa(@title, 15, Kati.Theme.Palette.cream_ink(), weight: "bold", lines: 2)}
        </Row>
        <Spacer size={13} />
        {Fa.fa("تغییر می‌کند:", 13, Kati.Theme.Palette.cream_ink(), weight: "semibold")}
        <Spacer size={4} />
        {Fa.fa(@changes, 13, Kati.Theme.Palette.cream_body(), lines: 3)}
        <Spacer size={9} />
        {Fa.fa("تغییر نمی‌کند:", 13, Kati.Theme.Palette.cream_ink(), weight: "semibold")}
        <Spacer size={4} />
        {Fa.fa(@keeps, 13, Kati.Theme.Palette.cream_body(), lines: 3)}
        <Spacer size={15} />
        <Row fill_width={true} align="center">
          <Row
            height={38}
            corner_radius={19}
            background={Palette.ink_fill()}
            padding_left={16}
            padding_right={16}
            align="center"
            on_tap={{self(), :delete_list}}
          >
            {Fa.fa("حذف فهرست", 12.5, Kati.Theme.Palette.on_ink(), weight: "bold")}
          </Row>
          <Spacer size={14} />
          <Box on_tap={{self(), :keep_list}}>
            {Fa.fa("بماند", 12.5, Kati.Theme.Palette.cream_sub(), weight: "semibold")}
          </Box>
          <Spacer weight={1.0} />
        </Row>
      </Column>
    </Column>
    """
  end

  def body(assigns) do
    list = assigns.list

    inner = %{
      title: list.title,
      count: Kati.Screens.ListDetailFa.meta(list),
      rows: Kati.Screens.ListDetailFa.rows(list),
      menu: Kati.Screens.ListDetailFa.menu(assigns)
    }

    assigns = inner

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        <Column weight={1.0}>
          {Kati.Screens.ListDetailFa.heading(@title)}
          <Spacer size={5} />
          {@count}
        </Column>
        <Spacer size={9} />
        {@menu}
      </Row>
      <Spacer size={20} />
      {@rows}
    </Column>
    """
  end

  @doc false
  def heading(title) do
    assigns = %{title: title}

    ~MOB"""
    <Text
      text={@title}
      font_family="fa"
      text_size={28}
      max_font_scale={1.6}
      font_weight="bold"
      letter_spacing={-0.03}
      text_color={:on_surface}
      max_lines={2}
    />
    """
  end

  @doc """
  ۱۴ عنوان · رتبه‌بندی‌شده — the count line, in Persian digits.

      iex> Kati.Screens.ListDetailFa.count(%{count: "14 titles"})
      "۱۴ عنوان"

      iex> Kati.Screens.ListDetailFa.count(%{count: "1 title"})
      "۱ عنوان"
  """
  @spec count(map()) :: String.t()
  def count(list) do
    n = list.count |> String.split(" ") |> Elixir.List.first()

    Digits.to_persian(n) <> " عنوان"
  end

  @doc false
  def meta(list) do
    line =
      if list.ranked?,
        do: Kati.Screens.ListDetailFa.count(list) <> " · رتبه‌بندی‌شده",
        else: Kati.Screens.ListDetailFa.count(list)

    assigns = %{line: line}

    ~MOB"""
    <Text
      text={@line}
      font_family="fa"
      text_size={11}
      text_color={Kati.Theme.Palette.meta()}
      max_lines={1}
    />
    """
  end

  @doc false
  def menu(%{list: %{kept?: true}}), do: ~MOB"<Spacer size={0} />"

  def menu(assigns) do
    Kati.UI.Menu.overflow(
      Kati.Screens.ListDetailFa.menu_disc(),
      assigns.menu?,
      [
        Kati.UI.Menu.item("ios_share", "هم‌رسانی", :share_list),
        Kati.UI.Menu.rule(),
        Kati.UI.Menu.item("delete", "حذف این فهرست", :confirm_delete, destructive: true)
      ],
      dismiss: :close_menu
    )
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
  The rows, or the empty sentence for the kind of list this is.

  336 draws the two apart for 331's reason: «افزودن به فهرست» is a lie on a
  shelf Kati fills, so a kept list's empty sentence names what fills it.
  """
  @spec rows(map()) :: term()
  def rows(%{titles: [], kept?: true}) do
    Kati.Screens.ListDetailFa.empty_card("چیزی رها نشده", "سریالی را رها کنید و همین‌جا می‌آید.")
  end

  def rows(%{titles: []}) do
    Kati.Screens.ListDetailFa.empty_card(
      "هنوز چیزی در آن نیست",
      "یک فیلم، کتاب یا آلبوم را باز کنید و «افزودن به فهرست» را بزنید."
    )
  end

  def rows(list) do
    inner = %{
      rows:
        list.titles
        |> Enum.with_index()
        |> Enum.map(fn {row, i} ->
          Kati.Screens.ListDetailFa.row(row, list.ranked?, i, i < length(list.titles) - 1)
        end)
    }

    assigns = inner

    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={20}
      shadow={Kati.Theme.shadow_card_soft()}
      padding_left={15}
      padding_right={15}
    >
      {@rows}
    </Column>
    """
  end

  @doc false
  def empty_card(title, body) do
    assigns = %{title: title, body: body}

    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={22}
      shadow={Kati.Theme.shadow_card_soft()}
      padding={17}
    >
      {Kati.Screens.BookDetailFa.fa(@title, 14.5, :on_surface, weight: "bold", align: "center")}
      <Spacer size={7} />
      {Kati.Screens.BookDetailFa.fa(@body, 12.5, Kati.Theme.Palette.sub(), align: "center", lines: 3)}
    </Column>
    """
  end

  @doc false
  def row(row, ranked?, index, rule?) do
    assigns = %{
      rank: if(ranked?, do: Digits.to_persian(index + 1)),
      art: Kati.Screens.ListDetail.art(row),
      title: row.title,
      sub: Kati.Screens.ListDetailFa.sub(row),
      trailing: if(ranked?, do: "drag_indicator", else: "chevron_left"),
      rule: rule?,
      tap: {self(), String.to_atom("open_title_" <> row.id)}
    }

    ~MOB"""
    <Column fill_width={true} on_tap={@tap}>
      <Row fill_width={true} align="center" padding_top={12} padding_bottom={12}>
        {Kati.Screens.ListDetailFa.rank(@rank)}
        {@art}
        <Spacer size={13} />
        <Column weight={1.0}>
          {Kati.Screens.BookDetailFa.fa(@title, 13.5, :on_surface, weight: "semibold")}
          <Spacer size={3} />
          {Kati.Screens.BookDetailFa.fa(@sub, 11.5, Kati.Theme.Palette.sub())}
        </Column>
        <Spacer size={12} />
        {UI.symbol(@trailing, size: 18, color: Kati.Theme.Palette.tertiary())}
      </Row>
      {Kati.UI.SettingsList.hairline(@rule)}
    </Column>
    """
  end

  @doc """
  The rank, LEFT aligned in a fixed 22pt column.

  336's annotation: *«ستون رتبه در DM Mono با ارقام فارسی می‌ماند و چپ‌چین است
  — آینه راست‌چین لاتین — پس ۱۰ زیر ۱ می‌نشیند.»* The mirror of board 331's
  right alignment, so a two-digit rank still sits under a one-digit one.
  """
  @spec rank(String.t() | nil) :: term()
  def rank(nil), do: ~MOB"<Spacer size={0} />"

  def rank(number) do
    assigns = %{number: number}

    ~MOB"""
    <Row align="center">
      <Row width={22} align="center">
        <Text
          text={@number}
          font_family="mono"
          text_size={12}
          text_color={Kati.Theme.Palette.muted()}
          max_lines={1}
        />
        <Spacer weight={1.0} />
      </Row>
      <Spacer size={10} />
    </Row>
    """
  end

  @doc """
  سریال · ۱۴۰۳ — the kind in Persian words, with the row's own fact after it.

      iex> Kati.Screens.ListDetailFa.sub(%{kind: :film, sub: "FILM · 2025"})
      "فیلم · ۲۰۲۵"

      iex> Kati.Screens.ListDetailFa.sub(%{kind: :book, sub: "BOOK · INES KARVEL"})
      "کتاب · Ines Karvel"

  A row the store could not name keeps 331's fallback, worded in Persian.

      iex> Kati.Screens.ListDetailFa.sub(%{kind: :series, sub: "SERIES · NO DETAILS YET"})
      "سریال · هنوز جزئیاتی نیست"
  """
  @spec sub(map()) :: String.t()
  def sub(row) do
    fact =
      row.sub
      |> String.split(" · ")
      |> Enum.drop(1)
      |> Enum.join(" · ")

    Kati.Screens.ListDetailFa.kind_word(row.kind) <> " · " <> Kati.Screens.ListDetailFa.fact(fact)
  end

  @doc false
  @spec fact(String.t()) :: String.t()
  def fact("NO DETAILS YET"), do: "هنوز جزئیاتی نیست"

  def fact(fact) do
    if fact =~ ~r/^\d+$/, do: Digits.to_persian(fact), else: Kati.I18n.Digits.fold(fact)
  end

  @doc """
  فیلم، سریال، کتاب، آلبوم.

      iex> Kati.Screens.ListDetailFa.kind_word(:album)
      "آلبوم"
  """
  @spec kind_word(atom()) :: String.t()
  def kind_word(:film), do: "فیلم"
  def kind_word(:book), do: "کتاب"
  def kind_word(:album), do: "آلبوم"
  def kind_word(_series), do: "سریال"

  @impl true
  def handle_info({:tap, :back}, socket), do: {:noreply, Kati.Screens.Resume.pop(socket)}

  def handle_info({:tap, :toggle_menu}, socket),
    do: {:noreply, Mob.Socket.assign(socket, :menu?, not socket.assigns.menu?)}

  def handle_info({:tap, :close_menu}, socket),
    do: {:noreply, Mob.Socket.assign(socket, :menu?, false)}

  def handle_info({:tap, :confirm_delete}, socket) do
    {:noreply,
     socket
     |> Mob.Socket.assign(:menu?, false)
     |> Mob.Socket.assign(:confirming?, true)}
  end

  def handle_info({:tap, :keep_list}, socket),
    do: {:noreply, Mob.Socket.assign(socket, :confirming?, false)}

  # Board 335's rule, one language over: nothing moves until the write returns,
  # so a failed delete does not pop.
  def handle_info({:tap, :delete_list}, socket) do
    case socket.assigns.list do
      nil ->
        {:noreply, socket}

      list ->
        case Kati.Lists.Shelf.delete(list.id) do
          :ok -> {:noreply, Kati.Screens.Resume.pop(socket)}
          {:error, _reason} -> {:noreply, Mob.Socket.assign(socket, :confirming?, false)}
        end
    end
  end

  def handle_info({:tap, :share_list}, socket) do
    list = socket.assigns.list

    {:noreply,
     socket
     |> Mob.Socket.assign(:menu?, false)
     |> then(fn s ->
       if list, do: Mob.Share.text(s, list.title), else: s
     end)}
  end

  def handle_info({:tap, :open_lists, _rest}, socket),
    do: {:noreply, Kati.Screens.Resume.pop(socket)}

  def handle_info({:tap, :open_lists}, socket),
    do: {:noreply, Kati.Screens.Resume.pop(socket)}

  def handle_info({:kati, :resumed, _payload}, socket) do
    id = socket.assigns.list && socket.assigns.list.id

    {:noreply, Mob.Socket.assign(socket, :list, Kati.Lists.Shelf.detail(id))}
  end

  def handle_info({:tap, tag}, socket) when is_atom(tag) do
    case Atom.to_string(tag) do
      "open_title_" <> id -> {:noreply, Kati.Screens.ListDetail.open(socket, id)}
      _other -> {:noreply, socket}
    end
  end

  def handle_info(_message, socket), do: {:noreply, socket}
end
