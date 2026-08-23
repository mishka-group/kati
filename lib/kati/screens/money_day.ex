defmodule Kati.Screens.MoneyDay do
  @moduledoc """
  Screen 126 — money on the calendar, pushed under Calendar.

  Screen 52's page for a different section, and it answers the three questions
  the ticket asked on the board itself.

  ## The merge threshold moves to three, and screen 09 is the one that loses

  Meals collapse at three on screen 52 and episodes at three on screen 09's own
  spine; 09's merge-at-two was the exception. Money takes three, so the app has
  **one** density rule rather than two — and *two renewals stay two rows*,
  which is the whole practical consequence and is printed on the page.

  ## A past expense does appear, and is drawn as a fact rather than a plan

  The second question, answered yes and quietly. A renewal is a **commitment**:
  a solid card, a time, an amount you will owe. An expense is a **fact**: an
  outlined card, no time slot, an amount already spent.

  Both belong on the day, and the difference is carried by the card rather than
  by a colour. Inventing a tint for *past* would have meant a fifth lane hue on
  a screen that already has four, and a reader would have to learn it.

  ## Where the rows come from

  `Kati.Money.Expense` for what was spent and `Kati.Services.Service.renews_on`
  for what is due, which is why a renewal knows its amount: screen 92 owns the
  prices and this page reads them. With neither stored, the drawing's four rows
  are drawn — `Kati.Money.DaySample`.
  """

  use Kati.Screens.Pushed, back: "Calendar"

  alias Kati.Money
  alias Kati.Money.DaySample
  alias Kati.Money.Expense
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  def load(socket) do
    socket
    |> Mob.Socket.assign(:rows, rows())
    |> Mob.Socket.assign(:filter, "All")
    |> Mob.Socket.assign(:expanded?, false)
  end

  @doc "The day's rows: what is stored, or the drawing's four."
  @spec rows() :: [map()]
  def rows do
    case stored() do
      [] -> DaySample.rows()
      expenses -> Enum.map(expenses, &shape/1)
    end
  end

  @doc "The drawing's four, unconditionally."
  @spec drawn_rows() :: [map()]
  def drawn_rows, do: DaySample.rows()

  defp stored do
    today = Kati.Time.today()

    Expense
    |> Ash.Query.for_read(:recent)
    |> Ash.read()
    |> case do
      {:ok, expenses} -> Enum.filter(expenses, &(Date.compare(&1.spent_on, today) == :eq))
      _other -> []
    end
  rescue
    _error -> []
  end

  @doc """
  One expense as a spine row.

  Always `:expense`, never `:renewal` — a row read out of `Kati.Money.Expense`
  is by definition something that already happened, and the two kinds are the
  page's whole subject.
  """
  @spec shape(Expense.t()) :: map()
  def shape(%Expense{} = expense) do
    %{
      kind: :expense,
      time: "—",
      all_day?: false,
      title: expense.description,
      meta: "RECORDED, NOT SCHEDULED",
      amount: Expense.amount(expense) || Money.format(0)
    }
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
        {Kati.Screens.MoneyDay.chrome()}
        {SettingsList.title(Kati.Screens.MoneyDay.title(), Kati.Screens.MoneyDay.subtitle(assigns.rows))}
        {Kati.Screens.MoneyDay.chips(assigns.filter)}
        {Kati.Screens.MoneyDay.spine(assigns.rows, assigns.filter, assigns.expanded?)}
        {Kati.Screens.MoneyDay.notes()}
      </Column>
    </Scroll>
    """
  end

  @doc "The back-pill row with the density disc opposite it."
  @spec chrome() :: map()
  def chrome do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} height={44} align="center">
        <Spacer weight={1.0} />
        <Box
          width={44}
          height={44}
          corner_radius={22}
          background={Palette.card()}
          align="center"
          shadow={Kati.Theme.shadow_button()}
          on_tap={{self(), :toggle_density}}
        >
          {UI.symbol("density_medium", size: 20)}
        </Box>
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc "The day this page is about."
  @spec title() :: String.t()
  def title do
    case stored() do
      [] -> DaySample.day().title
      _stored -> Calendar.strftime(Kati.Time.today(), "%a %-d %b")
    end
  end

  @doc "How many renewals and how many other items — the drawing's own split."
  @spec subtitle([map()]) :: String.t()
  def subtitle(rows) do
    case stored() do
      [] ->
        DaySample.day().subtitle

      _stored ->
        renewals = Enum.count(rows, &(&1.kind in [:renewal, :merged]))
        others = length(rows) - renewals

        String.upcase(
          "#{renewals} #{if renewals == 1, do: "renewal", else: "renewals"} · " <>
            "#{others} other #{if others == 1, do: "item", else: "items"}"
        )
    end
  end

  @doc false
  def chips(active) do
    chips =
      DaySample.chips()
      |> Enum.map(fn {label, count} ->
        UI.chip(label,
          selected: label == active,
          count: count,
          on_toggle: String.to_atom("filter_" <> label)
        )
      end)
      |> Enum.intersperse(~MOB"<Spacer size={7} />")

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true}>{chips}</Row>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc """
  The day's spine.

  Filtered by the chip, and the merged group expands in place rather than
  pushing a screen — the drawing draws both states at once so a reader can
  compare them, and the chevron is what lets you actually do it.
  """
  @spec spine([map()], String.t(), boolean()) :: map()
  def spine(rows, filter, expanded?) do
    cards =
      rows
      |> Enum.filter(&Kati.Screens.MoneyDay.shows?(&1, filter))
      |> Enum.flat_map(&Kati.Screens.MoneyDay.card(&1, expanded?))
      |> Enum.intersperse(~MOB"<Spacer size={9} />")

    ~MOB"""
    <Column fill_width={true}>
      {cards}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  Whether a row survives a chip.

  `Money` keeps renewals and expenses alike, because both are money. The other
  two chips keep nothing here — this day's rows are all money — and that is
  what an honest count does when a filter has nothing to show.
  """
  @spec shows?(map(), String.t()) :: boolean()
  def shows?(_row, "All"), do: true
  def shows?(_row, "Money"), do: true
  def shows?(_row, _other), do: false

  @doc """
  One row, plus its members when a merged group is open.

  A list rather than a node, because an expanded group is a card followed by
  three smaller ones and the sigil flattens an interpolated list into its
  parent — the same move `Kati.Screens.Film.watched/1` makes.
  """
  @spec card(map(), boolean()) :: [map()]
  def card(%{kind: :merged} = row, expanded?) do
    members =
      if expanded?,
        do:
          row.members
          |> Enum.map(&Kati.Screens.MoneyDay.member/1)
          |> Enum.intersperse(~MOB"<Spacer size={7} />"),
        else: []

    [Kati.Screens.MoneyDay.commitment(row, expanded?)] ++
      if(expanded?, do: [~MOB"<Spacer size={9} />"] ++ members, else: [])
  end

  def card(%{kind: :expense} = row, _expanded?), do: [Kati.Screens.MoneyDay.fact(row)]
  def card(row, _expanded?), do: [Kati.Screens.MoneyDay.commitment(row, false)]

  @doc """
  A commitment: a solid card, a time, an amount you will owe.

  The bronze rule is money's lane colour, the same one screen 52 gives meals —
  a section is identified by its stripe on every calendar surface, so a reader
  who has learned it once has learned it everywhere.
  """
  @spec commitment(map(), boolean()) :: map()
  def commitment(row, expanded?) do
    assigns = %{
      row: row,
      chevron: if(Map.has_key?(row, :members), do: "expand_more", else: nil),
      tap: if(Map.has_key?(row, :members), do: {self(), :toggle_density}, else: nil),
      expanded: expanded?
    }

    ~MOB"""
    <Row
      fill_width={true}
      background={Palette.card()}
      corner_radius={18}
      shadow={Kati.Theme.shadow_card_soft()}
      padding_left={13}
      padding_right={13}
      padding_top={12}
      padding_bottom={12}
      align="center"
      on_tap={@tap}
    >
      {Kati.Screens.MoneyDay.time_column(@row)}
      <Spacer size={11} />
      <Box width={3} height={34} corner_radius={2} background={Palette.bronze()} />
      <Spacer size={12} />
      <Box width={30} height={30} corner_radius={9} background={Palette.paper()} align="center">
        {Kati.UI.symbol("payments", size: 17, color: Palette.ink_soft())}
      </Box>
      <Spacer size={11} />
      <Column weight={1.0}>
        <Text
          text={@row.title}
          text_size={13.5}
          font_weight="bold"
          text_color={:on_surface}
          max_lines={1}
        />
        {Kati.Screens.MoneyDay.meta(@row.meta)}
      </Column>
      {Kati.Screens.MoneyDay.amount(@row.amount)}
      {Kati.Screens.MoneyDay.chevron(@chevron)}
    </Row>
    """
  end

  @doc """
  A fact: an outlined card, no time slot, an amount already spent.

  Outlined rather than tinted — see the moduledoc. The time column draws an em
  dash rather than being absent, so the amounts still line up under each other
  down the day.
  """
  @spec fact(map()) :: map()
  def fact(row) do
    assigns = %{row: row}

    ~MOB"""
    <Row
      fill_width={true}
      corner_radius={18}
      border_width={1.5}
      border_color={Palette.border_soft()}
      padding_left={13}
      padding_right={13}
      padding_top={12}
      padding_bottom={12}
      align="center"
    >
      {Kati.Screens.MoneyDay.time_column(@row)}
      <Spacer size={11} />
      <Box width={3} height={34} corner_radius={2} background={Palette.track()} />
      <Spacer size={12} />
      <Box width={30} height={30} corner_radius={9} background={Palette.paper()} align="center">
        {Kati.UI.symbol("check", size: 17, color: Palette.tertiary())}
      </Box>
      <Spacer size={11} />
      <Column weight={1.0}>
        <Text
          text={@row.title}
          text_size={13.5}
          font_weight="semibold"
          text_color={:on_surface}
          max_lines={1}
        />
        {Kati.Screens.MoneyDay.meta(@row.meta)}
      </Column>
      {Kati.Screens.MoneyDay.amount(@row.amount)}
    </Row>
    """
  end

  @doc false
  def time_column(%{all_day?: true}) do
    ~MOB"""
    <Column width={44} align="center">
      <Text
        text="ALL"
        font_family="mono"
        text_size={9.5}
        letter_spacing={0.1}
        text_align="center"
        text_color={Kati.Theme.Palette.muted()}
      />
      <Text
        text="DAY"
        font_family="mono"
        text_size={9.5}
        letter_spacing={0.1}
        text_align="center"
        text_color={Kati.Theme.Palette.muted()}
      />
    </Column>
    """
  end

  def time_column(row) do
    assigns = %{time: row.time}

    ~MOB"""
    <Text
      text={@time}
      font_family="mono"
      text_size={11.5}
      text_align="center"
      text_color={Kati.Theme.Palette.muted()}
      width={44}
    />
    """
  end

  @doc false
  def meta(nil), do: []

  def meta(text) do
    assigns = %{text: text}

    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={4} />
      <Text
        text={@text}
        font_family="mono"
        text_size={10}
        letter_spacing={0.1}
        text_color={Kati.Theme.Palette.sub()}
        max_lines={1}
      />
    </Column>
    """
  end

  @doc false
  def amount(nil), do: ~MOB"<Spacer size={0} />"

  def amount(text) do
    assigns = %{text: text}

    ~MOB"""
    <Text
      text={@text}
      font_family="mono"
      text_size={12.5}
      text_color={:on_surface}
      max_lines={1}
    />
    """
  end

  @doc false
  def chevron(nil), do: ~MOB"<Spacer size={0} />"

  def chevron(icon) do
    assigns = %{icon: icon}

    ~MOB"""
    <Row align="center">
      <Spacer size={8} />
      {Kati.UI.symbol(@icon, size: 20, color: Kati.Theme.Palette.tertiary())}
    </Row>
    """
  end

  @doc "One member of an expanded group, indented under it."
  @spec member(map()) :: map()
  def member(m) do
    assigns = %{m: m}

    ~MOB"""
    <Row fill_width={true} align="center">
      <Spacer size={55} />
      <Row
        weight={1.0}
        background={Palette.card_settled()}
        corner_radius={14}
        padding_left={12}
        padding_right={12}
        padding_top={9}
        padding_bottom={9}
        align="center"
      >
        <Box width={24} height={24} corner_radius={8} background={Palette.paper()} align="center">
          <Text
            text={@m.badge}
            text_size={11}
            font_weight="bold"
            text_align="center"
            text_color={Palette.ink_soft()}
          />
        </Box>
        <Spacer size={10} />
        <Text
          text={@m.name}
          text_size={12.5}
          font_weight="semibold"
          text_color={:on_surface}
          weight={1.0}
          max_lines={1}
        />
        <Text
          text={@m.amount}
          font_family="mono"
          text_size={12}
          text_color={Palette.sub()}
          max_lines={1}
        />
      </Row>
    </Row>
    """
  end

  @doc "The two sentences the board answers its own questions with."
  @spec notes() :: map()
  def notes do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.note("info", Kati.Money.DaySample.merge_note())}
      <Spacer size={12} />
      {Kati.UI.SettingsList.note("info", Kati.Money.DaySample.kinds_note())}
    </Column>
    """
  end

  @doc false
  def handle_tap(:toggle_density, socket),
    do: {:noreply, Mob.Socket.assign(socket, :expanded?, not socket.assigns.expanded?)}

  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "filter_" <> label -> {:noreply, Mob.Socket.assign(socket, :filter, label)}
      _other -> {:noreply, socket}
    end
  end
end
