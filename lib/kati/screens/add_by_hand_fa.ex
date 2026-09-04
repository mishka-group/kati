defmodule Kati.Screens.AddByHandFa do
  @moduledoc """
  Screen 156 — افزودن دستی, screen 154's form in the mirror.

  Built to `test/design/screens/156.html`. The same form as
  `Kati.Screens.AddByHand`, and what changes is not only the words.

  ## What the board's caption pins

    * **The back chevron is `arrow_forward_ios`.** Back is the way the reader
      came from, and in Persian that is the right edge — the commonest RTL bug
      there is, and `Kati.Screens.BookDetailFa` records the same trap for
      screen 69. `Kati.Screens.Fa.pushed_frame/2` owns it.
    * **The segmented trough reverses**, so فیلم sits at the leading right
      edge. A `Row` under `dir="rtl"` does that by itself; nothing here
      reverses a list by hand.
    * **Year and episode count keep DM Mono with Persian digits**, so the two
      numeric fields still align in a column the way the Latin ones do.
    * **The year is Shamsi.** `۱۴۰۳` and not `2024` — a Persian screen showing
      a Gregorian year is the same class of mistake as a mirrored screen
      keeping its left chevron, and this one is quieter because the digits
      still look right.

  ## What it does not own

  The write. `Kati.Screens.AddByHand.save/1` is the one path a hand-typed row
  takes in either script, so the two cannot disagree about what reaches
  `Kati.Media.TrackedTitle` — the same doctrine `Kati.Screens.LibraryFa` keeps
  by reading the shelf through screen 03's own function.
  """
  use Mob.Screen
  import Mob.Sigil

  alias Kati.Screens.AddByHand
  alias Kati.Screens.Fa
  alias Kati.Theme.Palette

  @kinds [{"فیلم", :movie, "movie"}, {"سریال", :tv, "live_tv"}]
  @statuses ["شروع نشده", "در حال تماشا", "تمام‌شده"]

  def mount(_params, _session, socket) do
    Kati.Theme.activate()

    {:ok,
     Mob.Socket.assign(socket,
       title: "گودال بلند",
       kind: :tv,
       year: "۱۴۰۳",
       status: "شروع نشده",
       episodes: "",
       save_error: nil
     )}
  end

  def render(assigns), do: Fa.pushed_frame(content(assigns), Kati.Screens.Identity.of(__MODULE__))

  @doc false
  def content(assigns) do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.AddByHandFa.back_pill()}
      {Kati.Screens.AddByHandFa.heading()}
      {AddByHand.labelled("عنوان", Kati.Screens.AddByHandFa.field(:title, assigns.title, "گودال بلند"))}
      {AddByHand.labelled("نوع", Kati.Screens.AddByHandFa.kinds(assigns.kind))}
      {AddByHand.labelled("سال", Kati.Screens.AddByHandFa.field(:year, assigns.year, "۱۴۰۳"), "اختیاری")}
      {AddByHand.labelled("وضعیت", Kati.Screens.AddByHandFa.statuses(assigns.status))}
      {AddByHand.labelled("تعداد قسمت‌ها", Kati.Screens.AddByHandFa.field(:episodes, assigns.episodes, "۷"), "اختیاری")}
      {Kati.UI.SettingsList.note("info", "بدون این عدد سریال ردیابی می‌شود اما نوار پیشرفتش مخرج ندارد — کاتی همین را صادقانه نشان می‌دهد.")}
      <Spacer size={18} />
      {Kati.UI.Sheet.commit("افزودن به کتابخانه", :add)}
      <Spacer size={14} />
      {AddByHand.split_note("عنوان دست‌نویس", "پوستر و فهرست قسمت ندارد", ". اگر کاتی بعداً آن را پیدا کند، هر دو می‌آیند و چیزی که نوشته‌اید دست‌نخورده می‌ماند.")}
    </Column>
    """
  end

  @doc """
  The back pill, pointing the way the reader came from.

  `arrow_forward_ios` and not `arrow_back_ios_new`: in Persian, back is the
  right edge. `Kati.Screens.BookDetailFa` records the same trap for screen 69,
  and it is the commonest RTL bug there is — the screen mirrors and the chevron
  does not, so it points at where the reader is going.
  """
  @spec back_pill() :: map()
  def back_pill do
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
          {Kati.UI.symbol("arrow_forward_ios", size: 17)}
          <Spacer size={6} />
          <Text text="افزودن عنوان" text_size={13.5} font_weight="semibold" text_color={:on_surface} />
        </Row>
        <Spacer weight={1.0} />
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc false
  def heading do
    ~MOB"""
    <Column fill_width={true}>
      <Text
        text="افزودن دستی"
        text_size={28}
        max_font_scale={1.6}
        font_weight="bold"
        letter_spacing={-0.03}
        text_color={:on_surface}
      />
      <Spacer size={7} />
      <Text
        text="برای چیزی که کاتی پیدا نکرد. عنوان تنها چیز لازم است."
        text_size={13}
        line_height={1.55}
        text_color={Palette.sub()}
      />
      <Spacer size={20} />
    </Column>
    """
  end

  @doc false
  def field(tag, value, placeholder) do
    assigns = %{value: value, placeholder: placeholder, on_change: {self(), tag}, id: Atom.to_string(tag)}

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
        value={@value}
        placeholder={@placeholder}
        return_key="done"
        weight={1.0}
        accessibility_id={@id}
        on_change={@on_change}
      />
    </Row>
    """
  end

  @doc false
  def kind_list, do: @kinds

  @doc false
  def status_list, do: @statuses

  @doc false
  def kinds(active) do
    ~MOB"""
    <Row fill_width={true} align="center">
      {Enum.map(Kati.Screens.AddByHandFa.kind_list(), fn {label, kind, icon} ->
        AddByHand.kind_chip(label, icon, kind == active)
      end)
      |> Enum.intersperse(AddByHand.gap())}
    </Row>
    """
  end

  @doc false
  def statuses(active) do
    ~MOB"""
    <Row fill_width={true} align="center">
      {Enum.map(Kati.Screens.AddByHandFa.status_list(), fn label ->
        AddByHand.status_chip(label, label == active)
      end)
      |> Enum.intersperse(AddByHand.gap())}
    </Row>
    """
  end

  def handle_info({:change, field, typed}, socket)
      when field in [:title, :year, :episodes] and is_binary(typed),
      do: {:noreply, Mob.Socket.assign(socket, field, typed)}

  def handle_info({:tap, :back}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}

  # The write is screen 154's, so a hand-typed row is the same row in either
  # script. `status_atom/1` maps the Persian labels rather than 154's, which is
  # the one thing the mirror has to own.
  def handle_info({:tap, :add}, socket) do
    {:noreply,
     socket
     |> Mob.Socket.assign(:status, Kati.Screens.AddByHandFa.status_english(socket.assigns.status))
     |> AddByHand.save()}
  end

  def handle_info({:tap, tag}, socket) do
    case Atom.to_string(tag) do
      "kind_فیلم" -> {:noreply, Mob.Socket.assign(socket, :kind, :movie)}
      "kind_سریال" -> {:noreply, Mob.Socket.assign(socket, :kind, :tv)}
      "status_" <> label -> {:noreply, Mob.Socket.assign(socket, :status, label)}
      _other -> Fa.dock_tap(tag, :library, socket)
    end
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  @doc "The Persian status label as the English one `Kati.Screens.AddByHand.save/1` maps."
  @spec status_english(String.t()) :: String.t()
  def status_english("در حال تماشا"), do: "Watching"
  def status_english("تمام‌شده"), do: "Finished"
  def status_english(_other), do: "Not started"
end
