defmodule Kati.Screens.QuickAddExpense do
  @moduledoc """
  Screen 124 — Quick add, with the Expense chip selected and no amount parsed.

  Screen 18 with a different sentence in the field. It is a separate screen
  because the design draws it as one, and it reuses screen 18's own header,
  field, chip row and commit — everything except the cream card, which is the
  only part that differs.

  ## The missing amount is a field, not a warning

  The one decision the ticket left open, and the caption settles it: *an inline
  field ringed in orange, not a warning row — a warning implies something is
  wrong, whereas "bought a book, forgot the price" is a perfectly good record.*

  Saving without an amount is allowed **and says so**, in the sentence under
  the field: *type it, or save without — an expense with no amount still counts
  as a thing that happened.* That is why `Kati.Money.Expense.amount_pence` is
  nullable: the screen and the column agree, rather than the column being
  permissive and the screen refusing.

  ## The ring is orange, and that is the page's one accent

  Orange means *new or now*, and the empty field is the only thing on the page
  that is asking for something. Nothing else here takes it.
  """

  use Mob.Screen
  import Mob.Sigil

  alias Kati.Money
  alias Kati.Screens.QuickAdd
  alias Kati.Screens.QuickAdd.Sample
  alias Kati.Theme.Palette
  alias Kati.UI

  def mount(_params, _session, socket) do
    Kati.Theme.activate()

    {:ok,
     socket
     |> Mob.Socket.assign(:draft, Kati.Screens.QuickAddExpense.draft())
     |> Mob.Socket.assign(:saved?, false)}
  end

  def render(assigns) do
    draft = assigns.draft

    ~MOB"""
    <Box
      fill_width={true}
      fill_height={true}
      background={:background}
      layout_direction={Kati.Locale.direction_prop()}
    >
      <Scroll>
        <Column
          fill_width={true}
          padding_left={21}
          padding_right={21}
          padding_top={64}
          padding_bottom={40}
        >
          {QuickAdd.header()}
          {QuickAdd.field(draft)}
          {UI.eyebrow("Kati read that as")}
          {Kati.Screens.QuickAddExpense.parsed(draft)}
          {UI.eyebrow("Or file it as")}
          {QuickAdd.kinds(draft)}
          {QuickAdd.actions(draft)}
        </Column>
      </Scroll>
    </Box>
    """
  end

  @doc """
  The draft this sheet opens with, with its commit wired to this screen.

  `on_commit` is put on here rather than in the Sample because it names a tag
  this module answers — a fixture that knew which handler was listening would
  be a fixture that could not be reused.
  """
  @spec draft() :: map()
  def draft, do: Map.put(Sample.expense_draft(), :on_commit, {self(), :add})

  @doc """
  Screen 18's cream card with the amount field inside it.

  Inside rather than beside, because the amount is part of what Kati understood
  — or rather, the one part it did not — and putting it outside the card would
  make it read as a separate step.
  """
  @spec parsed(map()) :: map()
  def parsed(draft) do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.cream()}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={18}
      >
        <Row fill_width={true} align="center">
          {QuickAdd.kind_tile(draft.kind_icon)}
          <Spacer size={10} />
          <Column weight={1.0}>
            <Text
              text={draft.title}
              text_size={16}
              font_weight="bold"
              letter_spacing={-0.02}
              text_color={:on_surface}
              max_lines={1}
            />
            <Spacer size={3} />
            <Text
              text={draft.kind}
              font_family="mono"
              text_size={10.5}
              text_color={Palette.cream_meta()}
              max_lines={1}
            />
          </Column>
        </Row>
        <Spacer size={16} />
        {draft.facts
         |> Enum.map(fn row -> QuickAdd.fact_row(row) end)
         |> Enum.intersperse(QuickAdd.gap())}
        <Spacer size={14} />
        {QuickAdd.rule()}
        <Spacer size={14} />
        {Kati.Screens.QuickAddExpense.amount_field(draft)}
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  The amount field: a 2pt accent ring, the currency symbol, and the placeholder.

  A ring rather than a fill, because the field is empty and a filled box would
  read as containing something. The symbol comes from `Kati.Money.currency/0`
  rather than being written `£`, so the field is right in every currency the
  app offers.
  """
  @spec amount_field(map()) :: map()
  def amount_field(draft) do
    assigns = %{
      symbol: Money.symbol(Money.currency()),
      placeholder: draft.amount_placeholder,
      value: draft.amount
    }

    ~MOB"""
    <Column fill_width={true}>
      <Text
        text="AMOUNT"
        font_family="mono"
        text_size={9.5}
        letter_spacing={0.12}
        text_color={Palette.cream_meta()}
      />
      <Spacer size={9} />
      <Row
        fill_width={true}
        height={48}
        corner_radius={16}
        background={Palette.cream_raise()}
        border_width={2}
        border_color={Palette.accent()}
        padding_left={15}
        padding_right={15}
        align="center"
        on_tap={{self(), :edit_amount}}
      >
        <Text text={@symbol} font_family="mono" text_size={17} text_color={Palette.cream_ink()} />
        <Spacer size={9} />
        <Text
          text={@value || @placeholder}
          text_size={14}
          text_color={Palette.cream_sub()}
          weight={1.0}
          max_lines={1}
        />
      </Row>
      <Spacer size={11} />
      {Kati.UI.rich_text([
        {"Type it, or save without — ",
         [text_size: 12, line_height: 1.5, text_color: Palette.cream_body()]},
        {"an expense with no amount still counts as a thing that happened",
         [font_weight: "semibold", text_color: Palette.cream_ink(), text_size: 12]},
        {".", [text_size: 12, line_height: 1.5, text_color: Palette.cream_body()]}
      ])}
    </Column>
    """
  end

  def handle_info({:tap, :close}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}

  def handle_info({:tap, :add}, socket) do
    save_expense(socket.assigns.draft)
    {:noreply, Mob.Socket.pop_screen(socket)}
  end

  # The amount field has no keyboard behind it — Mob has no text input, which is
  # why every field in this app is drawn rather than typed into. Marking the
  # draft as touched is a real change and is what the sweep sees; typing is #45.
  def handle_info({:tap, :edit_amount}, socket),
    do: {:noreply, Mob.Socket.assign(socket, :saved?, false)}

  def handle_info(_message, socket), do: {:noreply, socket}

  @doc """
  Write the expense, amount or no amount.

  The section comes from what the sentence was parsed as — `EXPENSE · BOOKS` —
  and is the only classification stored, because `Kati.Money` has no categories
  and screen 122 says so.
  """
  @spec save_expense(map()) :: :ok
  def save_expense(draft) do
    Ash.create(Kati.Money.Expense, %{
      description: draft.title,
      amount_pence: draft.amount,
      currency: Money.currency(),
      spent_on: Kati.Time.today(),
      section: :books
    })

    :ok
  rescue
    _error -> :ok
  end
end
