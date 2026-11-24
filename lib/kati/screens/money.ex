defmodule Kati.Screens.Money do
  @moduledoc """
  Screen 122 — Money, pushed under Your year.

  Screen 23 widened to hold quick-add's expenses **without becoming a budgeting
  app**. The caption is explicit about what that means: no categories, no
  budget, no chart. Each expense names the section it belongs to, and that is
  the only classification there is — the same four sections the whole app runs
  on, reused rather than a second taxonomy invented for money.

  ## Cost per watched hour stays the loudest figure in each row

  Because it is the only number on the page Kati can compute and a bank cannot.
  A bank knows you paid Orbit £13.99; only Kati knows you watched six hours of
  it. `Kati.Money.per_hour/2` is where the two domains meet.

  A service you paid for and did not watch gets an em dash rather than a number:
  the figure is undefined, and printing anything numeric there would be
  inventing one.

  ## A paused service keeps its row and leaves the total

  Stated in the `info` line under the group, and it is the reason a paused
  service is not simply deleted — you are still deciding about it, and a row
  that vanished would take the decision with it.

  ## The suggestion is the only advice this app gives

  One sentence, about one service, with one saving, built from two figures Kati
  already has — and it offers to *remind* rather than to act. Nothing here
  cancels anything.
  """

  use Kati.Screens.Pushed, back: "Stats"
  use Gettext, backend: Kati.Gettext

  alias Kati.Money
  alias Kati.Money.Expense
  alias Kati.Money.Sample
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  def load(socket) do
    socket
    |> Mob.Socket.assign(:months, live_months())
    |> Mob.Socket.assign(:dismissed?, false)
  end

  @doc "The expense months: what is stored, or the drawing's two."
  @spec months() :: [map()]
  def months do
    case stored() do
      [] ->
        Sample.months()

      expenses ->
        months_from(expenses)
    end
  end

  defp months_from(expenses) do
    expenses
    |> Expense.by_month()
    |> Enum.map(fn {_label, total, rows} ->
      %{
        # The group's own DATE rather than the label `Expense.by_month/1`
        # hands back. That one is `Calendar.strftime(…, "%B")` — a
        # Gregorian month name in English, which stays English under `:fa`
        # — so a reader with real expenses got a group headed `August` on a
        # page whose drawn groups are headed `مرداد`. The catalogue answers
        # the drawn `August` with the SHAMSI month the date falls in, and
        # `Kati.Locale.month_name/2` is that same arithmetic done from a
        # date, so the two halves of screen 122 agree again.
        #
        # `hd(rows)` cannot raise: `by_month/1` builds every group by
        # grouping rows, so a group with no rows in it does not exist. Any
        # row will do — they all share the year and month that made the
        # group.
        label: Kati.Locale.month_name(hd(rows).spent_on, :long),
        # `display/1`, not `format/1`. `format/2` is CLDR's own shape and
        # leaves a `£` standing beside Persian numerals; `Kati.Money.display/2`
        # is board 127's — the figure, then the currency as a WORD,
        # `۶۱٫۴۰ پوند`. The drawn months already go through it in
        # `Kati.Money.Sample.months/0`, so this is the stored half catching
        # up rather than a new decision. `display/2` is `format/2` unchanged
        # in English, so nothing on board 122 moves.
        total: Money.display(total),
        direction: nil,
        delta: nil,
        rows:
          Enum.map(rows, fn expense ->
            %{
              name: expense.description,
              meta: Expense.meta(expense),
              amount: Expense.amount(expense) || "—"
            }
          end)
      }
    end)
  end

  @doc """
  The months the reader actually has, and nothing when they have none.

  `months/0` above still answers the drawing — that is what the empty-database
  gate reads, and what the board is compared with. The page must not: a reader
  with no expenses is not shown two months of somebody else's.
  """
  @spec live_months() :: [map()]
  def live_months do
    case stored() do
      [] -> []
      expenses -> months_from(expenses)
    end
  end

  @doc "The drawing's two months, unconditionally."
  @spec drawn_months() :: [map()]
  def drawn_months, do: Sample.months()

  @doc """
  The one-off band: the eyebrow and the months, or nothing at all.

  A heading over an empty list is worse than no heading — the reader is told
  there are expenses and then shown none.
  """
  def expenses_band(assigns) do
    case Map.get(assigns, :months) || Kati.Screens.Money.live_months() do
      [] ->
        ~MOB"<Spacer size={0} />"

      months ->
        ~MOB"""
        <Column fill_width={true}>
          {UI.eyebrow(Kati.UI.eyebrow_label(gettext("One-off expenses")))}
          {Kati.Screens.Money.expenses(months)}
        </Column>
        """
    end
  end

  defp stored do
    Expense
    |> Ash.Query.for_read(:recent)
    |> Ash.read()
    |> case do
      {:ok, expenses} -> expenses
      _other -> []
    end
  rescue
    _error -> []
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
        {SettingsList.chrome("more_horiz", 44)}
        {SettingsList.title(
          pgettext("screen title", "Money"),
          Map.get(assigns, :subtitle) || Kati.Screens.Money.subtitle()
        )}
        {Kati.Screens.Money.hero(Map.get(assigns, :monthly))}
        {UI.eyebrow(Kati.UI.eyebrow_label(gettext("Recurring commitments")))}
        {Kati.Screens.Money.recurring(assigns)}
        {Kati.Screens.Money.expenses_band(assigns)}
        {Kati.Screens.Money.suggestion(assigns)}
      </Column>
    </Scroll>
    """
  end

  @doc "The header's mono subtitle, carrying the real counts."
  @spec subtitle() :: String.t()
  def subtitle do
    services = length(Kati.Screens.MyServices.subscribed())

    case {stored(), services} do
      {expenses, services} ->
        today = Kati.Time.today()

        this_month =
          Enum.count(
            expenses,
            &(&1.spent_on.year == today.year and &1.spent_on.month == today.month)
          )

        Kati.UI.eyebrow_label(
          ngettext("%{n} service", "%{n} services", services, n: Kati.Locale.number(services)) <>
            " · " <>
            ngettext("%{n} expense this month", "%{n} expenses this month", this_month,
              n: Kati.Locale.number(this_month)
            )
        )
    end
  end

  @doc """
  The change line, or nothing when there is no price history to compare.

  Kati keeps one price per service and no history, so a live total has nothing
  honest to say about last month — `Kati.Subscriptions` makes the same call for
  screen 23's card, and the drawing's `Up £4.00 since March` is only ever the
  board's own.
  """
  def change_row(%{m: %{change_lead: nil}}), do: ~MOB"<Spacer size={0} />"

  def change_row(assigns) do
    ~MOB"""
    <Column>
      <Spacer size={11} />
      <Row fill_width={true} align="top">
        {Kati.UI.symbol("trending_up", size: 17, color: Palette.gold_icon())}
        <Spacer size={9} />
        <Column weight={1.0}>
          {Kati.UI.rich_text(@runs)}
        </Column>
      </Row>
    </Column>
    """
  end

  # The hero's figure: what the reader pays, or the drawing's when they have
  # told Kati about nothing.
  defp monthly_data do
    case Kati.Subscriptions.ledger() do
      %{monthly: %{total: total}} ->
        %{
          label: gettext("Every month"),
          total: total,
          change_lead: nil,
          change_amount: nil,
          change_rest: nil
        }

      _none ->
        %{
          label: gettext("Every month"),
          total: "—",
          change_lead: nil,
          change_amount: nil,
          change_rest: nil
        }
    end
  end

  @doc """
  The cream hero: the monthly total and what changed.

  Cream because it carries a claim — the palette's own definition — and this is
  the one card on the page that asserts something rather than listing it.

  ## The three things that change with the script

  The eyebrow's tracking, the total's tracking, and the paragraph's leading.
  Tracking prises apart the joins Arabic script is written with, so both
  `letter_spacing` values go through `Kati.Locale.tracking/1` — the same call
  screen 23 makes on the same card (`Kati.Screens.Subscriptions.monthly/1`) and
  screen 123 makes on its own (`Kati.Screens.MoneyStates`). The 34pt total also
  gains `max_lines={1}`: `£46.47` is six glyphs and `۴۶٫۴۷ پوند` is ten with a
  word in it, and a total that wrapped would push the change line out of the
  card. And Vazirmatn's line box is not Plus Jakarta's, so the wrapping
  paragraph takes `Kati.Locale.leading/1` rather than the drawing's flat 1.5 —
  `Kati.Theme.fa_line_height/0` is where that constant is argued.
  """
  @spec hero(map() | nil) :: map()
  def hero(monthly \\ nil) do
    m = monthly || monthly_data()

    # The lead and the rest both carry `body` and the amount is never the
    # longest of the three, so `Kati.UI.rich_text/1` resolves the paragraph's
    # style to `body` in either script — which is why the leading only has to
    # be right here.
    body = [
      text_size: 12.5,
      line_height: Kati.Locale.leading(1.5),
      text_color: Palette.cream_body()
    ]

    strong = [font_weight: "semibold", text_color: Palette.cream_ink(), text_size: 12.5]

    runs =
      case m.change_lead do
        nil ->
          []

        lead ->
          [
            {lead <> " ", body},
            {m.change_amount, strong},
            {" " <> m.change_rest, body}
          ]
      end

    assigns = %{m: m, runs: runs}

    ~MOB"""
    <Column fill_width={true}>
      <Column fill_width={true} background={Palette.cream()} corner_radius={22} padding={19}>
        <Text
          text={Kati.UI.eyebrow_label(@m.label)}
          font_family={Kati.Locale.mono_face()}
          text_size={10}
          letter_spacing={Kati.Locale.tracking(0.14)}
          text_color={Palette.cream_meta()}
        />
        <Spacer size={9} />
        <Text
          text={@m.total}
          text_size={34}
          font_weight="extrabold"
          letter_spacing={Kati.Locale.tracking(-0.035)}
          text_color={Palette.cream_ink()}
          max_lines={1}
        />
        {Kati.Screens.Money.change_row(assigns)}
      </Column>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  The subscriptions, each with the figure worth looking at.

  Read through `Kati.Subscriptions.ledger/0` — the same read screen 23 draws —
  rather than re-derived or taken from the drawing: screen 92 owns the prices,
  the hours come from what was watched, and three screens computing one number
  three ways is three chances to disagree. It answered four invented services
  on every device before; a reader with none saw a bill.

  The tags are indices, not names: `subscription_tag/1` builds an atom, and an
  atom per service someone typed is a leak with a nicer name.
  """
  @spec recurring(map()) :: map()
  def recurring(assigns \\ %{}) do
    case Map.get(assigns, :recurring) do
      nil ->
        case Kati.Subscriptions.ledger() do
          nil -> empty_recurring()
          %{services: services} -> live_recurring(services)
        end

      rows ->
        live_recurring(rows)
    end
  end

  defp live_recurring(services) do
    rows =
      services
      |> Enum.with_index()
      |> Enum.map(fn {service, index} ->
        service
        |> Map.put_new(:index, index)
        |> service_row()
      end)

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.card(rows)}
      <Spacer size={10} />
      {Kati.UI.SettingsList.note("info", gettext("Cost per watched hour is the figure worth looking at. Paused services keep their row and leave the total. Prices are owned by 92."))}
      <Spacer size={24} />
    </Column>
    """
  end

  defp empty_recurring do
    row =
      Kati.UI.SettingsList.row(
        nil,
        Kati.UI.SettingsList.body(
          gettext("No subscriptions yet"),
          gettext("Add what you pay for on My services — its prices are the ones read here.")
        ),
        nil,
        on_tap: {self(), :open_my_services}
      )

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.card([row])}
      <Spacer size={10} />
      {Kati.UI.SettingsList.note("info", gettext("Cost per watched hour is the figure worth looking at. Paused services keep their row and leave the total. Prices are owned by 92."))}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  The drawing's own card, as assigns — the fixture `Kati.ScreenDesignLiteralTest`
  installs so board 122 is still compared with itself.

  A device no longer reaches it: the recurring card reads the services the
  reader pays for, and a reader with none gets a sentence. `Kati.ScreenEmptyDatabaseTest`
  holds that half.
  """
  @spec drawn_state(map()) :: map()
  def drawn_state(assigns) do
    Map.merge(assigns, %{
      recurring: Sample.recurring(),
      months: Sample.months(),
      subtitle: Sample.subtitle(),
      monthly: Sample.monthly(),
      suggestion: Sample.suggestion()
    })
  end

  @doc """
  One subscription row's tag, built from the service's name.

  Every row of the ledger shared `:open_subscriptions`, so the card was one
  `accessibility_id` repeated and `onNodeWithTag` throws on the second match
  (#97). The name, because a service is what it is called — the same identity
  `Kati.Screens.MyServices.service_tag/1` uses for the same rows on screen 92.

      iex> Kati.Screens.Money.subscription_tag(%{name: "Orbit"})
      :open_subscriptions_Orbit

      iex> Kati.Screens.Money.subscription_tag(%{index: 1})
      :open_subscriptions_1

      iex> Kati.Screens.Money.subscription_tag(%{})
      :open_subscriptions
  """
  @spec subscription_tag(map()) :: atom()
  def subscription_tag(%{id: id}) when is_binary(id),
    do: String.to_atom("open_subscriptions_" <> id)

  def subscription_tag(%{index: index}) when is_integer(index),
    do: String.to_atom("open_subscriptions_" <> Integer.to_string(index))

  def subscription_tag(_service), do: :open_subscriptions

  @doc false
  def service_row(service) do
    SettingsList.row(
      Kati.Screens.MyServices.badge_tile(service.badge),
      SettingsList.body(service.name, service.line),
      SettingsList.trailing(Kati.Screens.Money.rate(service)),
      on_tap: {self(), Kati.Screens.Money.subscription_tag(service)}
    )
  end

  @doc """
  The price above, the rate below, right-aligned.

  The rate takes the colour of its own verdict — green when the service is
  earning its money, red-ish when it is not — and tertiary when there is no
  verdict to give, which is what an em dash means here.
  """
  @spec rate(map()) :: map()
  def rate(service) do
    colour =
      Map.get(service, :rate_tone) ||
        case Map.get(service, :good?) do
          true -> Palette.green_text()
          false -> Palette.red()
          nil -> Palette.tertiary()
        end

    assigns = %{
      price: Map.get(service, :price) || "—",
      rate: Map.get(service, :rate) || "—",
      colour: colour
    }

    ~MOB"""
    <Column align="trailing">
      <Text
        text={@price}
        font_family={Kati.Locale.mono_face()}
        text_size={12.5}
        text_color={Palette.sub()}
        max_lines={1}
      />
      <Spacer size={4} />
      <Text
        text={@rate}
        font_family={Kati.Locale.mono_face()}
        text_size={13}
        font_weight="medium"
        text_color={@colour}
        max_lines={1}
      />
    </Column>
    """
  end

  @doc "Expenses, grouped by month, each group with its total and its delta."
  @spec expenses([map()]) :: map()
  def expenses(months) do
    groups =
      months
      |> Enum.map(&Kati.Screens.Money.month_group/1)
      |> Enum.intersperse(~MOB"<Spacer size={16} />")

    ~MOB"""
    <Column fill_width={true}>
      {groups}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def month_group(month) do
    rows = Enum.map(month.rows, &Kati.Screens.Money.expense_row/1)

    # The group's eyebrow is a hand-rolled one — no dash, and a total on the
    # other end of the row — so it does not get `Kati.UI.eyebrow/2`'s
    # `Kati.Locale.tracking/1` for free the way the two section labels in
    # `content/1` do. It asks for it below. Same `.16em` and the same reason
    # screen 23 gives on its own month label: a fraction of an em taken out
    # between letters breaks the joins Persian is written with.
    assigns = %{month: month, rows: rows}

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_left={2} padding_right={2}>
        <Text
          text={Kati.UI.eyebrow_label(@month.label)}
          font_family={Kati.Locale.mono_face()}
          text_size={10.5}
          letter_spacing={Kati.Locale.tracking(0.16)}
          text_color={Palette.eyebrow()}
        />
        <Spacer weight={1.0} />
        <Text
          text={@month.total}
          font_family={Kati.Locale.mono_face()}
          text_size={12.5}
          text_color={:on_surface}
          max_lines={1}
        />
        {Kati.Screens.Money.delta(@month)}
      </Row>
      <Spacer size={11} />
      {Kati.UI.SettingsList.card(@rows)}
    </Column>
    """
  end

  @doc "The month-on-month change, or nothing for a month with nothing before it."
  @spec delta(map()) :: map() | []
  def delta(%{delta: nil}), do: []

  def delta(month) do
    icon = if month.direction == :up, do: "trending_up", else: "arrow_downward"
    colour = if month.direction == :up, do: Palette.red(), else: Palette.green_text()
    assigns = %{icon: icon, colour: colour, delta: month.delta}

    ~MOB"""
    <Row align="center">
      <Spacer size={9} />
      {Kati.UI.symbol(@icon, size: 16, color: @colour)}
      <Spacer size={4} />
      <Text
        text={@delta}
        font_family={Kati.Locale.mono_face()}
        text_size={11.5}
        text_color={@colour}
        max_lines={1}
      />
    </Row>
    """
  end

  @doc false
  def expense_row(expense) do
    SettingsList.row(
      nil,
      SettingsList.body(expense.name, expense.meta),
      SettingsList.trailing(Kati.Screens.Money.amount(expense.amount))
    )
  end

  @doc false
  def amount(text) do
    assigns = %{text: text}

    ~MOB"""
    <Text
      text={@text}
      font_family={Kati.Locale.mono_face()}
      text_size={12.5}
      text_color={Kati.Theme.Palette.sub()}
      max_lines={1}
    />
    """
  end

  @doc """
  The one piece of advice, or nothing once it is dismissed.

  It offers to remind rather than to act, and the reminder is the only thing it
  can do: Kati cannot cancel a subscription and would be lying if it implied
  otherwise.
  """
  @spec suggestion(boolean()) :: map() | []
  # The screen used to call this with the dismissed flag alone; keep the
  # arity honest for the callers and tests that still do.
  def suggestion(dismissed?) when is_boolean(dismissed?),
    do: suggestion(%{dismissed?: dismissed?})

  def suggestion(assigns) do
    case Map.get(assigns, :suggestion) do
      %{} = suggestion ->
        suggestion_card(suggestion)

      nil ->
        cond do
          Map.get(assigns, :dismissed?, false) ->
            []

          true ->
            case Kati.Subscriptions.ledger() do
              %{suggestion: %{} = suggestion} -> suggestion_card(suggestion)
              _none -> []
            end
        end
    end
  end

  # The ledger's own advice: one sentence and the two buttons. The drawing's
  # version below is four weighted runs around a bolded figure; a live sentence
  # has no runs to weight, and inventing some would be copy the reader's own
  # numbers did not produce.
  defp suggestion_card(%{body: body} = s) do
    label = Map.get(s, :confirm) || gettext("Remind me")
    dismiss = Map.get(s, :dismiss) || gettext("Dismiss")
    assigns = %{body: body, label: label, dismiss: dismiss}

    ~MOB"""
    <Column fill_width={true} background={Palette.cream()} corner_radius={22} padding={17}>
      <Row fill_width={true} align="top">
        {Kati.UI.symbol("lightbulb", size: 18, color: Palette.gold_icon())}
        <Spacer size={11} />
        <Text
          text={@body}
          text_size={13}
          line_height={Kati.Locale.leading(1.55)}
          text_color={Palette.cream_body()}
          weight={1.0}
        />
      </Row>
      <Spacer size={14} />
      <Row fill_width={true} align="center">
        <Row
          height={36}
          corner_radius={18}
          background={Palette.ink_fill()}
          padding_left={16}
          padding_right={16}
          align="center"
          on_tap={{self(), :remind_me}}
        >
          <Text
            text={@label}
            text_size={12.5}
            font_weight="bold"
            text_color={Palette.on_ink()}
            max_lines={1}
          />
        </Row>
        <Spacer size={14} />
        <Text
          text={@dismiss}
          text_size={12.5}
          font_weight="semibold"
          text_color={Palette.cream_sub()}
          on_tap={{self(), :dismiss}}
        />
        <Spacer weight={1.0} />
      </Row>
    </Column>
    """
  end

  defp suggestion_card(s) do
    # `Kati.Locale.leading/1` over the drawing's flat 1.55, for the reason
    # `Kati.Screens.Subscriptions.advice/2` spells out on the same card: this is
    # the longest wrapping paragraph on the page, and Vazirmatn's ascenders and
    # descenders are not Plus Jakarta's, so a leading measured against the Latin
    # card crowds the Persian one. The Latin number stays at the call site,
    # which is the point of the helper.
    body = [
      text_size: 13,
      line_height: Kati.Locale.leading(1.55),
      text_color: Palette.cream_body()
    ]

    strong = [font_weight: "semibold", text_color: Palette.cream_ink(), text_size: 13]

    assigns = %{
      action: s.action,
      runs: [
        {s.lead <> " ", body},
        {s.hours, strong},
        {" " <> s.middle <> " ", body},
        {s.titles, strong},
        {" " <> s.tail, body}
      ]
    }

    ~MOB"""
    <Column fill_width={true} background={Palette.cream()} corner_radius={22} padding={17}>
      <Row fill_width={true} align="top">
        {Kati.UI.symbol("lightbulb", size: 18, color: Palette.gold_icon())}
        <Spacer size={11} />
        <Column weight={1.0}>
          {Kati.UI.rich_text(@runs)}
        </Column>
      </Row>
      <Spacer size={14} />
      <Row fill_width={true} align="center">
        <Row
          height={36}
          corner_radius={18}
          background={Palette.ink_fill()}
          padding_left={16}
          padding_right={16}
          align="center"
          on_tap={{self(), :remind_me}}
        >
          <Text
            text={@action}
            text_size={12.5}
            font_weight="bold"
            text_color={Palette.on_ink()}
            max_lines={1}
          />
        </Row>
        <Spacer size={14} />
        <Text
          text={gettext("Dismiss")}
          text_size={12.5}
          font_weight="semibold"
          text_color={Palette.cream_sub()}
          on_tap={{self(), :dismiss}}
        />
        <Spacer weight={1.0} />
      </Row>
    </Column>
    """
  end

  @doc false
  def handle_tap(:open_subscriptions, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Subscriptions)}

  def handle_tap(:open_my_services, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.MyServices)}

  def handle_tap(:remind_me, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.ReleaseWatcher)}

  def handle_tap(:dismiss, socket),
    do: {:noreply, Mob.Socket.assign(socket, :dismissed?, true)}

  # Every ledger row, by its own service name — see `subscription_tag/1`. They
  # open the screen the bare tag opened: `Kati.Screens.Subscriptions` takes no
  # argument, so this is identity for the sake of being addressable rather than
  # for routing.
  #
  # Below the named clauses, above the catch-all: a prefix match placed before
  # them makes every one of them unreachable, silently.
  def handle_tap(tag, socket) when is_atom(tag) do
    if String.starts_with?(Atom.to_string(tag), "open_subscriptions_") do
      {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Subscriptions)}
    else
      {:noreply, socket}
    end
  end

  def handle_tap(_tag, socket), do: {:noreply, socket}
end
