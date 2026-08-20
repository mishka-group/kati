defmodule Kati.Screens.Inbox do
  @moduledoc """
  Screen 05 — the new releases inbox, pushed under Home.

  Built to `.scratch/design/screens/05.html`. Two lists that look different
  because they answer different questions: **Out now** is a card per title with
  its poster and a Watch button, because each row is something you can act on;
  **Coming up** is one card of dated rows, because it is a schedule and the
  dates are the spine.

  The watcher card at the top is the honest bit — it says how many titles are
  watched and when it last checked, so background work that runs every six
  hours is visible rather than assumed.
  """
  use Kati.Screens.Pushed, back: "Home"

  alias Kati.Library.Sample
  alias Kati.UI

  @impl true
  def load(socket), do: Mob.Socket.assign(socket, :inbox, Sample.inbox())

  @doc false
  def content(assigns) do
    inbox = assigns.inbox

    ~MOB"""
    <Scroll>
      <Column fill_width={true} padding_left={21} padding_right={21} padding_top={64} padding_bottom={40}>
        {Kati.Screens.Inbox.mark_all()}
        {Kati.Screens.Inbox.title(inbox)}
        {Kati.Screens.Inbox.watcher(inbox)}
        {UI.eyebrow("Out now · #{length(inbox.out_now)}")}
        {Kati.Screens.Inbox.out_now(inbox)}
        {Kati.UI.eyebrow("Coming up", dash: 0xFFC4BDB3, gap: 12)}
        {Kati.Screens.Inbox.coming_up()}
      </Column>
    </Scroll>
    """
  end

  # The back pill is drawn by Kati.Screens.Pushed; this row reserves its height
  # and carries the Mark all action opposite it. The height is the PILL's 44,
  # not the 36 of the control inside it — the drawing centres a 36 pill against
  # a 44 one, and a row that measured 36 pulled the title and everything under
  # it 8 up the frame.
  @doc false
  def mark_all do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} height={44} align="center">
        <Spacer weight={1.0} />
        <Row height={36} corner_radius={18} background={0xFFE4E0D9} padding_left={14} padding_right={14} align="center">
          <Text text="Mark all" text_size={12.5} font_weight="semibold" text_color={:on_surface} max_lines={1} />
        </Row>
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc """
  The three dated rows the drawing puts in the Coming up card.

  Stated here rather than taken from `Kati.Library.Sample`, whose list had
  drifted to a different three titles with a mono day/time where the design
  draws a bell. The drawing is the authority for this card: an air date that
  is already being watched for (a filled orange `notifications_active`) and
  two that are only listed (a hollow `notifications`).
  """
  @spec coming_up_rows() :: [map()]
  def coming_up_rows do
    [
      %{month: "AUG", day: "20", title: "The Long Hollow — S2E6", line: "Lumen+ · 20:00", armed: true},
      %{month: "SEP", day: "04", title: "Vellum", line: "In cinemas", armed: false},
      %{month: "SEP", day: "12", title: "Nightbirds — Season 2", line: "Full season drop", armed: false}
    ]
  end

  @doc false
  def title(inbox) do
    subtitle = "#{length(inbox.out_now)} out now · #{length(coming_up_rows())} coming up"

    ~MOB"""
    <Column fill_width={true}>
      <Text text="New releases" text_size={28} font_weight="bold" letter_spacing={-0.03} text_color={:on_surface} />
      <Spacer size={5} />
      <Text text={subtitle} font_family="mono" text_size={11} text_color={0xFFA9A29A} max_lines={1} />
      <Spacer size={20} />
    </Column>
    """
  end

  @doc false
  def watcher(inbox) do
    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={0xFFFBF1DE}
        corner_radius={20}
        padding_left={17}
        padding_right={17}
        padding_top={15}
        padding_bottom={15}
        align="center"
      >
        {Kati.UI.symbol("auto_awesome", size: 22, color: 0xFFC98A3E)}
        <Spacer size={12} />
        <Column weight={1.0}>
          <Text text={"Watching for #{inbox.watching} titles"} text_size={13.5} font_weight="bold" text_color={:on_surface} max_lines={1} />
          <Spacer size={4} />
          <Text text={inbox.last_checked} font_family="mono" text_size={10.5} text_color={0xFFB09A72} max_lines={1} />
        </Column>
        <Spacer size={12} />
        {Kati.UI.symbol("settings", size: 19, color: 0xFFC98A3E)}
      </Row>
      <Spacer size={26} />
    </Column>
    """
  end

  @doc false
  def out_now(inbox) do
    ~MOB"""
    <Column fill_width={true}>
      {inbox.out_now
       |> Enum.map(fn row -> Kati.Screens.Inbox.release_row(row) end)
       |> Enum.intersperse(Kati.Screens.Inbox.row_gap())}
      <Spacer size={26} />
    </Column>
    """
  end

  @doc false
  def release_row(row) do
    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Kati.Theme.card(:light)}
        corner_radius={18}
        shadow={Kati.Theme.shadow_card_soft()}
        padding_left={13}
        padding_right={13}
        padding_top={11}
        padding_bottom={11}
        align="center"
      >
        {Kati.Screens.Inbox.thumb(row)}
        <Spacer size={13} />
        <Column weight={1.0}>
          <Row fill_width={true} align="center">
            <Box width={6} height={6} corner_radius={3} background={row.dot} />
            <Spacer size={7} />
            <Text text={row.title} text_size={14} font_weight="bold" letter_spacing={-0.015} text_color={:on_surface} max_lines={1} />
          </Row>
          <Spacer size={5} />
          <Text text={row.line} text_size={12} text_color={0xFF5C574F} max_lines={1} />
          <Spacer size={4} />
          <Text text={row.meta} font_family="mono" text_size={10.5} text_color={0xFFB3ACA2} max_lines={1} />
        </Column>
        <Spacer size={13} />
        <Row height={32} corner_radius={16} background={Kati.Theme.ink()} padding_left={14} padding_right={14} align="center">
          <Text text="Watch" text_size={12} font_weight="semibold" text_color={0xFFFBFAF8} max_lines={1} />
        </Row>
      </Row>
    </Column>
    """
  end

  @doc false
  def row_gap, do: ~MOB"<Spacer size={9} />"

  @doc false
  def thumb(row) do
    case Kati.Library.Sample.poster(row[:seed]) do
      nil -> ~MOB"<Box width={44} height={62} corner_radius={9} background={0xFFE4E0D9} />"
      src -> ~MOB"""
        <Image src={src} width={44} height={62} corner_radius={9} content_mode="fill" />
        """
    end
  end

  @doc false
  def coming_up do
    rows = coming_up_rows()
    last = length(rows) - 1

    ~MOB"""
    <Column
      fill_width={true}
      background={Kati.Theme.card(:light)}
      corner_radius={20}
      shadow={Kati.Theme.shadow_card()}
      padding_left={15}
      padding_right={15}
      padding_top={4}
      padding_bottom={4}
    >
      {rows
       |> Enum.with_index()
       |> Enum.map(fn {row, i} -> Kati.Screens.Inbox.upcoming_row(row, i < last) end)}
    </Column>
    """
  end

  @doc false
  def upcoming_row(row, rule?) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_top={14} padding_bottom={14}>
        <Column width={42} align="center">
          <Text text={row.month} font_family="mono" text_size={10} letter_spacing={0.1} text_color={0xFFA9A29A} text_align="center" />
          <Text text={row.day} text_size={17} font_weight="bold" letter_spacing={-0.02} text_color={:on_surface} text_align="center" />
        </Column>
        <Spacer size={14} />
        <Column weight={1.0}>
          <Text text={row.title} text_size={13.5} font_weight="semibold" text_color={:on_surface} max_lines={1} />
          <Spacer size={3} />
          <Text text={row.line} text_size={11.5} text_color={0xFF8A8479} max_lines={1} />
        </Column>
        <Spacer size={14} />
        {Kati.Screens.Inbox.bell(row.armed)}
      </Row>
      {Kati.Screens.Inbox.hairline(rule?)}
    </Column>
    """
  end

  # Armed is the filled bell in accent; listed is the hollow one in #C4BDB3.
  @doc false
  def bell(true), do: Kati.UI.symbol("notifications_active", size: 19, color: 0xFFE8823C, fill: true)
  def bell(false), do: Kati.UI.symbol("notifications", size: 19, color: 0xFFC4BDB3)

  @doc false
  def hairline(false), do: ~MOB"<Spacer size={0} />"
  def hairline(true), do: ~MOB"<Box fill_width={true} height={1} background={0x121A1917} />"
end
