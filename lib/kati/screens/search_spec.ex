defmodule Kati.Screens.SearchSpec do
  @moduledoc """
  Screen 88 — Scope & ranking, pushed under Settings.

  ## This board is a contract, and the screen renders it rather than restating it

  The design's own caption: *the annotation deliverable, drawn as its own board
  rather than margin notes — it is a contract the build reads, not a caption.*

  So every value on this page comes out of `Kati.Search`, which is the build's
  half of the same contract. The fields each scope searches, the four ranking
  tiers with their examples, the group order, the three-rows-per-group cap and
  the whole Persian normalisation table are read, not typed. A specification
  screen that held its own copy of the specification would be a second
  specification.

  ## The one field excluded by name

  Calendar searches event titles, locations and notes and **never invitee
  names**, and the board says why in one line: searching your calendar should
  not turn into searching your contacts. It is drawn in the excluded style
  rather than omitted, because a field that is missing and a field that is
  refused look identical in a list.

  ## Group order is fixed and the page says so

  *Always this order. A user learns where to look; relevance-sorted groups move
  the target every keystroke.* That sentence is the reason the group list on
  this page is a fixed rail rather than a sortable one.

  ## Three rows per group, and the second reason for it

  The board gives both: it keeps a result list readable, **and** it is what
  keeps a frame under 256 event handles — which is `Kati.TapHandleBudgetTest`'s
  ceiling and a real one, because a screen that exceeds it kills its own
  process.
  """

  use Kati.Screens.Pushed, back: "Settings"

  alias Kati.Search
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  def load(socket), do: socket

  @doc false
  def content(_assigns) do
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
        {SettingsList.title("Scope & ranking", "What each scope searches, and in what order", nil, :name)}
        {UI.eyebrow("Fields searched, per scope")}
        {Kati.Screens.SearchSpec.scopes()}
        {UI.eyebrow("Group order — fixed, not relevance-sorted")}
        {Kati.Screens.SearchSpec.group_order()}
        {UI.eyebrow("Within a group")}
        {Kati.Screens.SearchSpec.tiers()}
        {UI.eyebrow("Caps, emphasis, retention")}
        {Kati.Screens.SearchSpec.caps()}
        {UI.eyebrow("Persian normalisation")}
        {Kati.Screens.SearchSpec.normalisation()}
      </Column>
    </Scroll>
    """
  end

  @doc """
  One card per scope, its fields as chips.

  The `never invitee names` field draws in the refused style rather than being
  left out — see the moduledoc.
  """
  @spec scopes() :: map()
  def scopes do
    cards =
      Search.scopes()
      |> Enum.map(fn {_scope, label, fields} ->
        Kati.Screens.SearchSpec.scope_card(label, fields)
      end)
      |> Enum.intersperse(~MOB"<Spacer size={11} />")

    ~MOB"""
    <Column fill_width={true}>
      {cards}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def scope_card(label, fields) do
    rows =
      fields
      |> Enum.chunk_every(3)
      |> Enum.map(&Kati.Screens.SearchSpec.field_row/1)
      |> Enum.intersperse(~MOB"<Spacer size={7} />")

    assigns = %{label: label, rows: rows}

    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={20}
      padding={16}
      shadow={Kati.Theme.shadow_card()}
    >
      <Text
        text={@label}
        text_size={13.5}
        font_weight="bold"
        text_color={:on_surface}
        max_lines={1}
      />
      <Spacer size={11} />
      {@rows}
    </Column>
    """
  end

  @doc false
  def field_row(fields) do
    chips =
      fields
      |> Enum.map(&Kati.Screens.SearchSpec.field_chip/1)
      |> Enum.intersperse(~MOB"<Spacer size={6} />")

    ~MOB"""
    <Row fill_width={true} align="center">
      {chips}
      <Spacer weight={1.0} />
    </Row>
    """
  end

  @doc """
  One field, or one refusal.

  A refused field takes the tertiary ink and a strike, which is the treatment
  `Kati.UI.Segmented`'s disabled segment uses — one visual for *drawn and
  deliberately not doing this*, wherever it appears.
  """
  @spec field_chip(String.t()) :: map()
  def field_chip("never" <> _rest = field), do: Kati.Screens.SearchSpec.refused(field)

  def field_chip(field) do
    assigns = %{field: field}

    ~MOB"""
    <Row
      height={26}
      corner_radius={13}
      background={Palette.paper()}
      padding_left={10}
      padding_right={10}
      align="center"
    >
      <Text
        text={@field}
        font_family="mono"
        text_size={10.5}
        text_color={Palette.ink_soft()}
        max_lines={1}
      />
    </Row>
    """
  end

  @doc false
  def refused(field) do
    assigns = %{field: field}

    ~MOB"""
    <Row height={26} corner_radius={13} padding_left={10} padding_right={10} align="center">
      <Box>
        <Text
          text={@field}
          font_family="mono"
          text_size={10.5}
          text_color={Palette.track_off()}
          max_lines={1}
        />
        <Box fill_width={true} fill_height={true} align="center">
          <Box fill_width={true} height={1} background={Palette.track_off()} />
        </Box>
      </Box>
    </Row>
    """
  end

  @doc "The seven groups in the order every result list uses, and the sentence that fixes it."
  @spec group_order() :: map()
  def group_order do
    rows =
      Search.scopes()
      |> Enum.map(fn {_scope, label, _fields} ->
        SettingsList.row(
          nil,
          SettingsList.body(label, nil),
          SettingsList.trailing(SettingsList.chevron())
        )
      end)

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.card(rows)}
      <Spacer size={12} />
      {Kati.UI.SettingsList.note("info", "Always this order. A user learns where to look; relevance-sorted groups move the target every keystroke.")}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc "The four ranking tiers, numbered, each with the example the board prints."
  @spec tiers() :: map()
  def tiers do
    rows = Enum.map(Search.tiers(), &Kati.Screens.SearchSpec.tier_row/1)

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.card(rows)}
      <Spacer size={12} />
      <Text text="Ties break by recency." text_size={12.5} text_color={Palette.ink_soft()} />
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def tier_row({rank, name, example}) do
    assigns = %{rank: Integer.to_string(rank), example: example}

    SettingsList.row(
      ~MOB"""
      <Box width={26} height={26} corner_radius={13} background={Palette.paper()} align="center">
        <Text
          text={@rank}
          font_family="mono"
          text_size={11.5}
          text_align="center"
          text_color={Palette.ink_soft()}
        />
      </Box>
      """,
      SettingsList.body(name, nil),
      SettingsList.trailing(~MOB"""
      <Text
        text={@example}
        font_family="mono"
        text_size={10.5}
        text_color={Palette.muted()}
        max_lines={1}
      />
      """)
    )
  end

  @doc """
  The three numbers and one rule that keep a result list calm.

  `Never orange` is on the page rather than assumed: orange means new/now
  everywhere in this app, and a match is neither.
  """
  @spec caps() :: map()
  def caps do
    rows = [
      SettingsList.row(
        SettingsList.icon_tile("checklist"),
        SettingsList.body(
          # The board spells the number out — `Three rows per group` — because it
          # is a rule rather than a measurement, and a rule reads as prose. The
          # figure still comes from `Kati.Search`, so the word and the cap
          # cannot drift: `word/1` is the one place they meet.
          "#{Kati.Screens.SearchSpec.word(Search.rows_per_group())} rows per group",
          "Then a “See all 12 →” row — also what keeps a frame under 256 event handles",
          lines: 3
        ),
        SettingsList.trailing(nil)
      ),
      SettingsList.row(
        SettingsList.icon_tile("format_bold"),
        SettingsList.body(
          "Matches emphasise by weight",
          "600 → 700 and ink. Never orange — orange only means new/now",
          lines: 3
        ),
        SettingsList.trailing(nil)
      ),
      SettingsList.row(
        SettingsList.icon_tile("history"),
        SettingsList.body(
          "Recent keeps the last #{Search.recent_kept()}",
          "Never translated, they are your words",
          lines: 2
        ),
        SettingsList.trailing(nil)
      )
    ]

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.card(rows)}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  A small number as the word for it.

  Only the range a cap could plausibly sit in. Anything larger comes back as
  digits, because `twenty-seven rows per group` would be a sentence nobody
  wants to read and a cap nobody would set.
  """
  @spec word(integer()) :: String.t()
  def word(n) when n in 1..10,
    do:
      Enum.at(~w(one two three four five six seven eight nine ten), n - 1) |> String.capitalize()

  def word(n), do: Integer.to_string(n)

  @doc """
  The folding table, read from `Kati.Search.normalisation_table/0`.

  Read rather than typed for the reason the moduledoc gives: this board and the
  behaviour it specifies must be one thing, and a table transcribed into a
  screen is a table that can be wrong about the code beside it.
  """
  @spec normalisation() :: map()
  def normalisation do
    rows = Enum.map(Search.normalisation_table(), &Kati.Screens.SearchSpec.folding_row/1)

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.card(rows)}
      <Spacer size={12} />
      {Kati.UI.SettingsList.note("info", "Typing ي finds ی. Both spellings of every affected word resolve to one form before matching, so a query typed on an Arabic keyboard finds a title typed on a Persian one.")}
    </Column>
    """
  end

  @doc false
  def folding_row({from, from_code, to, to_code}) do
    assigns = %{from: from, from_code: from_code, to: to, to_code: to_code || ""}

    SettingsList.row(
      nil,
      ~MOB"""
      <Row fill_width={true} align="center">
        <Text text={@from} font_family="fa" text_size={14} text_color={:on_surface} width={54} />
        <Text text={@from_code} font_family="mono" text_size={10.5} text_color={Palette.muted()} />
        <Spacer size={10} />
        {Kati.UI.symbol("arrow_forward", size: 15, color: Palette.tertiary())}
        <Spacer size={10} />
        <Text text={@to} font_family="fa" text_size={14} text_color={:on_surface} />
        <Spacer weight={1.0} />
      </Row>
      """,
      SettingsList.trailing(~MOB"""
      <Text
        text={@to_code}
        font_family="mono"
        text_size={10.5}
        text_color={Palette.muted()}
        max_lines={1}
      />
      """)
    )
  end

  # A specification board has nothing to press. The group rows carry a chevron
  # because the board draws one — they are naming an order rather than offering
  # a destination, and screen 27's own rows are inert for the same reason.
  @doc false
  def handle_tap(_tag, socket), do: {:noreply, socket}
end
