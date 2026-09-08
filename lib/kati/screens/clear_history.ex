defmodule Kati.Screens.ClearHistory do
  @moduledoc """
  Board 267 — Clear watch history, and what it does not clear.

  The destination of the one row in screen 24's Data group that opened nothing.
  That row is also the one board 267 says has no second line at all — *"the
  only row in its group whose meaning cannot be read before tapping it"* — and
  the edit the board asks for is that line, which screen 24 now carries.

  ## Three rules about numbers, and all three are the board's

    * **Counted before the delete, never after.** `Kati.Media.History.clear/0`
      returns the number it removed rather than asking the store afterwards,
      because a report built from the delete's own row count says nothing was
      deleted while it deletes everything.
    * **Reviews are named separately.** A count of "entries" hides the fact
      that this deletes sentences a person wrote, so they get their own line.
    * **No total across the four.** There is no such noun in this app, and a
      destructive confirmation is the last screen that may print an invented
      one. `counts/0` answers four figures and nothing adds them up.

  ## What stays is a list of other tables, not a promise

  Every line under *What stays* is a different resource — statuses live on
  `Kati.Media.TrackedTitle`, sessions on `Kati.Books.ReadingSession`, listens
  on `Kati.Music.Listen` — and `Kati.Media.History.clear/0` names one. The
  screen can make the promise because the code cannot break it.

  ## Every episode unticks, and the board calls that the surprise

  A tick IS a log row: `Kati.Screens.Series` counts progress from
  `Kati.Media.Watch` rather than storing it, so clearing the history returns
  every progress ring to zero. The bookmark survives — `progress_season` and
  `progress_episode` are columns and are not touched — so a shelf reads
  `S2 · E5` beside a ring at nothing until the reader ticks again. The screen
  says so, because nothing else in the app would.

  ## Two states, one screen

  The confirmation is an assign rather than a second module, which is what the
  board draws: the page, and the page with `Clear 1,204 logs?` over it. Board
  267 is a states board for that reason and stays in `test/design/incoming/`.
  """

  use Kati.Screens.Pushed, back: "Settings"

  alias Kati.Theme.Palette
  alias Kati.UI.SettingsList

  @impl true
  def load(socket) do
    socket
    |> Mob.Socket.assign(:counts, Kati.Media.History.counts())
    |> Mob.Socket.assign(:confirming?, false)
    |> Mob.Socket.assign(:cleared, nil)
  end

  @doc false
  def content(assigns) do
    inner = %{
      body: Kati.Screens.ClearHistory.body(assigns.counts, assigns[:cleared]),
      confirm: Kati.Screens.ClearHistory.confirm(assigns[:confirming?], assigns.counts)
    }

    assigns = inner

    ~MOB"""
    <Box fill_width={true} fill_height={true}>
      <Scroll>
        <Column
          fill_width={true}
          padding_left={21}
          padding_right={21}
          padding_top={64}
          padding_bottom={40}
        >
          {SettingsList.chrome(nil, 44)}
          {SettingsList.title("Clear watch history", nil, nil, :name)}
          {@body}
        </Column>
      </Scroll>
      {@confirm}
    </Box>
    """
  end

  @doc """
  The page, or the sentence a store that could not be read gets instead.

  `Kati.Media.History.counts/0` answers `:error` when the read fails, and this
  is the one screen where that must not be drawn as four zeroes: a
  confirmation offering to clear `0 logs` from a database it could not open
  would be asking permission for something it has not measured.
  """
  @spec body(map() | :error, non_neg_integer() | nil) :: term()
  def body(:error, _cleared) do
    SettingsList.note(
      "error",
      "Kati could not read your history just now, so it will not offer to clear it. " <>
        "Nothing has been changed. Open this again in a moment."
    )
  end

  def body(counts, cleared) do
    assigns = %{
      goes: Kati.Screens.ClearHistory.goes(counts),
      stays: Kati.Screens.ClearHistory.stays(),
      counted_note: Kati.Screens.ClearHistory.counted_note(),
      unticks: Kati.Screens.ClearHistory.unticks_note(),
      actions: Kati.Screens.ClearHistory.actions(counts),
      done: Kati.Screens.ClearHistory.done(cleared)
    }

    ~MOB"""
    <Column fill_width={true}>
      {@done}
      {SettingsList.eyebrow_muted("What goes, and what stays")}
      {@goes}
      <Spacer size={14} />
      {SettingsList.note("info", @counted_note)}
      <Spacer size={16} />
      {SettingsList.eyebrow_muted("What stays")}
      {@stays}
      <Spacer size={14} />
      {SettingsList.note("history", @unticks)}
      <Spacer size={16} />
      {@actions}
    </Column>
    """
  end

  @doc "The four figures, each on its own row and never added up."
  @spec goes(map()) :: map()
  def goes(counts) do
    rows = [
      {counts.logs, "times you logged something watched, read or played"},
      {counts.ratings, "ratings on those logs"},
      {counts.reviews, "reviews you wrote"},
      {counts.notes, "notes about where and who with"}
    ]

    last = length(rows) - 1

    SettingsList.card(
      rows
      |> Enum.with_index()
      |> Enum.map(fn {{count, line}, i} ->
        SettingsList.row(
          Kati.Screens.ClearHistory.figure(count),
          SettingsList.body(line),
          nil,
          rule: i != last
        )
      end)
    )
  end

  @doc false
  def figure(count) do
    assigns = %{text: Integer.to_string(count)}

    ~MOB"""
    <Box width={44} align="center">
      <Text text={@text} font_family="mono" text_size={15} text_color={:on_surface} max_lines={1} />
    </Box>
    """
  end

  @doc "The three things this does not touch, each of them another table."
  @spec stays() :: map()
  def stays do
    rows = [
      {"Every shelf and every status",
       "watching, finished, dropped — they live on the title, not on a log"},
      {"Reading sessions and listens", "their own tables, untouched by this"},
      {"Your library, lists and wishlist", "nothing here is a log"}
    ]

    last = length(rows) - 1

    SettingsList.card(
      rows
      |> Enum.with_index()
      |> Enum.map(fn {{title, sub}, i} ->
        SettingsList.row(
          SettingsList.icon_tile("check"),
          SettingsList.body(title, sub),
          nil,
          rule: i != last
        )
      end)
    )
  end

  @doc false
  def counted_note do
    "Counted before the delete, never after — a report built from the delete's own row " <>
      "count would say nothing was deleted while it deleted everything. And reviews are " <>
      "named separately: a count of \"entries\" hides the fact that this deletes sentences " <>
      "a person wrote. No total across the four — there is no such noun in this app, and a " <>
      "destructive confirmation is the last screen that may print an invented one."
  end

  @doc false
  def unticks_note do
    "Every episode unticks. A tick is a log row, and series progress is counted from those " <>
      "rows rather than stored — so every progress ring returns to zero. Your bookmark " <>
      "survives: a shelf will read S2 · E5 beside a ring at nothing until you tick again."
  end

  @doc """
  The two rows at the foot: a backup offered, and the destructive one.

  *Keep a copy first* is **offered, not taken** — the board's own words. It
  opens screen 128 and does nothing else, because a confirmation that silently
  backed up first would be deciding for the reader on the screen where that is
  least acceptable.

  The destructive row draws no tap when there is nothing to clear. A row that
  opens a confirmation about zero logs is a control with nowhere to go, which
  is the rule this repository keeps everywhere.
  """
  @spec actions(map()) :: map()
  def actions(counts) do
    clear_tap = if counts.logs > 0, do: {self(), :ask}

    SettingsList.card([
      SettingsList.row(
        SettingsList.icon_tile("upload"),
        SettingsList.body("Keep a copy first", "Offered, not taken — opens Back up everything"),
        SettingsList.trailing(SettingsList.chevron()),
        on_tap: {self(), :back_up}
      ),
      SettingsList.row(
        Kati.Screens.ClearHistory.danger_tile(),
        Kati.Screens.ClearHistory.danger_label(),
        nil,
        rule: false,
        on_tap: clear_tap
      )
    ])
  end

  @doc false
  def danger_tile do
    Kati.Components.MishkaThemeIcon.theme_icon(
      %{variant: :filled, color: Palette.paper(), size: 30, radius: 9},
      [Kati.UI.symbol("delete", size: 17, color: Palette.red())]
    )
  end

  @doc false
  def danger_label do
    ~MOB"""
    <Text
      text="Clear watch history…"
      text_size={13.5}
      font_weight="semibold"
      text_color={Palette.red()}
      max_lines={1}
    />
    """
  end

  @doc false
  def done(nil), do: ~MOB"<Spacer size={0} />"

  def done(cleared) do
    assigns = %{text: "Cleared #{cleared} logs."}

    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.note("check_circle", @text)}
      <Spacer size={16} />
    </Column>
    """
  end

  @doc """
  Board 267's confirmation, and it names the number rather than the noun.

  `Clear 1,204 logs?` on the drawing; this reader's own figure here. **Changes**
  and **Does not change** are two sentences rather than one paragraph, because
  the second is the reason the first is safe to agree to.
  """
  @spec confirm(boolean(), map()) :: map()
  def confirm(true, counts) do
    assigns = %{heading: "Clear #{counts.logs} logs?"}

    ~MOB"""
    <Box fill_width={true} fill_height={true} background={Kati.UI.Sheet.scrim()} align="center">
      <Column fill_width={true} padding_left={28} padding_right={28}>
        <Column
          fill_width={true}
          background={Palette.card()}
          corner_radius={22}
          padding={19}
          shadow={Kati.Theme.shadow_card()}
        >
          <Row fill_width={true} align="center">
            <Spacer weight={1.0} />
            {Kati.UI.symbol("error", size: 26, color: Palette.red())}
            <Spacer weight={1.0} />
          </Row>
          <Spacer size={11} />
          <Text
            text={@heading}
            text_size={16}
            font_weight="bold"
            text_color={:on_surface}
            text_align="center"
          />
          <Spacer size={11} />
          <Text
            text="Changes: every tick, rating and review, and every progress ring."
            text_size={12.5}
            line_height={1.5}
            text_color={Palette.sub()}
            text_align="center"
          />
          <Spacer size={7} />
          <Text
            text="Does not change: your shelves, your lists, your reading sessions and your listens."
            text_size={12.5}
            line_height={1.5}
            text_color={Palette.sub()}
            text_align="center"
          />
          <Spacer size={17} />
          {Kati.Screens.ClearHistory.confirm_buttons()}
        </Column>
      </Column>
    </Box>
    """
  end

  def confirm(_resting, _counts), do: ~MOB"<Spacer size={0} />"

  @doc false
  def confirm_buttons do
    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        height={46}
        corner_radius={23}
        background={Palette.red()}
        align="center"
        on_tap={{self(), :clear}}
      >
        <Spacer weight={1.0} />
        <Text
          text="Clear it"
          text_size={13.5}
          font_weight="bold"
          text_color={Palette.on_ink()}
          max_lines={1}
        />
        <Spacer weight={1.0} />
      </Row>
      <Spacer size={9} />
      <Row fill_width={true} height={44} align="center" on_tap={{self(), :keep}}>
        <Spacer weight={1.0} />
        <Text
          text="Keep it"
          text_size={13}
          font_weight="semibold"
          text_color={Palette.sub()}
          max_lines={1}
        />
        <Spacer weight={1.0} />
      </Row>
    </Column>
    """
  end

  @impl true
  def handle_tap(:ask, socket), do: {:noreply, Mob.Socket.assign(socket, :confirming?, true)}

  def handle_tap(:keep, socket), do: {:noreply, Mob.Socket.assign(socket, :confirming?, false)}

  def handle_tap(:back_up, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Backup)}

  # Re-reads rather than subtracting. The figures on the page were counted
  # before the delete — that is the board's first rule — and the page after it
  # is a different question with a different answer, so it is asked again.
  def handle_tap(:clear, socket) do
    case Kati.Media.History.clear() do
      {:ok, gone} ->
        {:noreply,
         socket
         |> Mob.Socket.assign(:confirming?, false)
         |> Mob.Socket.assign(:cleared, gone)
         |> Mob.Socket.assign(:counts, Kati.Media.History.counts())}

      {:error, _reason} ->
        {:noreply, Mob.Socket.assign(socket, :confirming?, false)}
    end
  end

  def handle_tap(_tag, socket), do: {:noreply, socket}
end
