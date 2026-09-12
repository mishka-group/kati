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
  use Gettext, backend: Kati.Gettext

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
          {SettingsList.title(gettext("Clear watch history"), nil, nil, :name)}
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
      gettext(
        "Kati could not read your history just now, so it will not offer to clear it. " <>
          "Nothing has been changed. Open this again in a moment."
      )
    )
  end

  def body(counts, cleared) do
    # The two eyebrows are bound out of the sigil rather than called inside it,
    # for the reason `Kati.Screens.Backup.content/1` gives about its own pair: a
    # `~MOB` interpolation cannot be wrapped across lines the way an ordinary
    # call can, and both of these run past the formatter's column once the
    # label is a `gettext/1` call inside a `SettingsList.eyebrow_muted/1` call.
    #
    # `pgettext/2` on the second one. *What stays* is two words and it sits on
    # the same screen as *What goes, and what stays*, which is exactly the
    # shape `mix gettext.merge` fuzzy-matches: the short msgid would arrive
    # already filled in with the long one's Persian, marked `#, fuzzy`, in a
    # merge nobody reads line by line. The context is what keeps them apart.
    assigns = %{
      goes_eyebrow: gettext("What goes, and what stays"),
      stays_eyebrow: pgettext("board 267 eyebrow", "What stays"),
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
      {SettingsList.eyebrow_muted(@goes_eyebrow)}
      {@goes}
      <Spacer size={14} />
      {SettingsList.note("info", @counted_note)}
      <Spacer size={16} />
      {SettingsList.eyebrow_muted(@stays_eyebrow)}
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
      {counts.logs, gettext("times you logged something watched, read or played")},
      {counts.ratings, gettext("ratings on those logs")},
      {counts.reviews, gettext("reviews you wrote")},
      {counts.notes, gettext("notes about where and who with")}
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
    # The digits move to the reader's own numerals and THE FACE MOVES WITH THEM.
    # `kati_mono.ttf` carries none of U+06F0–U+06F9, so `۱٬۲۰۴` left on the
    # hardcoded `font_family="mono"` would be handed to Android's own fallback
    # and drawn in a typeface that is not Kati's, in a column beside figures
    # that were not — which is the pairing `Kati.PersianFontTest` states as
    # *Persian numerals are set in `fa` at the design's mono size*.
    #
    # `Kati.Locale.mono_face/1` rather than `/0` for the same reason
    # `Kati.Screens.AlbumDetail.track_row/1` uses it on a track number: it asks
    # the STRING, so an English page keeps DM Mono without a branch on locale.
    text = Kati.Locale.number(count)
    assigns = %{text: text, face: Kati.Locale.mono_face(text)}

    ~MOB"""
    <Box width={44} align="center">
      <Text text={@text} font_family={@face} text_size={15} text_color={:on_surface} max_lines={1} />
    </Box>
    """
  end

  @doc "The three things this does not touch, each of them another table."
  @spec stays() :: map()
  def stays do
    rows = [
      {gettext("Every shelf and every status"),
       gettext("watching, finished, dropped — they live on the title, not on a log")},
      {gettext("Reading sessions and listens"), gettext("their own tables, untouched by this")},
      {gettext("Your library, lists and wishlist"), gettext("nothing here is a log")}
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
    gettext(
      "Counted before the delete, never after — a report built from the delete's own row " <>
        "count would say nothing was deleted while it deleted everything. And reviews are " <>
        "named separately: a count of \"entries\" hides the fact that this deletes sentences " <>
        "a person wrote. No total across the four — there is no such noun in this app, and a " <>
        "destructive confirmation is the last screen that may print an invented one."
    )
  end

  @doc false
  def unticks_note do
    # `S2 · E5` is interpolated rather than typed into the sentence, and the
    # msgid it comes from is `Kati.Screens.Library.meta_for/4`'s own — this
    # note is QUOTING the shelf ("a shelf will read …"), so it has to quote the
    # string the shelf actually draws, which under `:fa` is `ف۲ · ق۵`. Typing
    # it in would have left the one Latin run in a Persian paragraph whose
    # middle dot the bidi algorithm then has to place, and it would have said
    # the shelf reads something the shelf does not.
    bookmark = gettext("S%{s} · E%{e}", s: Kati.Locale.number(2), e: Kati.Locale.number(5))

    gettext(
      "Every episode unticks. A tick is a log row, and series progress is counted from those " <>
        "rows rather than stored — so every progress ring returns to zero. Your bookmark " <>
        "survives: a shelf will read %{bookmark} beside a ring at nothing until you tick again.",
      bookmark: bookmark
    )
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

    # The destination's name is interpolated from `Kati.Screens.Backup`'s own
    # msgid rather than written out a second time. A row that says where it
    # goes has to keep saying what that screen is called, and two copies of
    # `Back up everything` are two things a translator can answer differently
    # — which would leave this row naming a screen the reader cannot find.
    backup_line =
      gettext("Offered, not taken — opens %{screen}", screen: gettext("Back up everything"))

    SettingsList.card([
      SettingsList.row(
        SettingsList.icon_tile("upload"),
        SettingsList.body(gettext("Keep a copy first"), backup_line),
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
    # Its own msgid, ellipsis and all, rather than the page title plus a `…`
    # bolted on: the two are the same words in English and the ellipsis is what
    # separates a heading from a control that opens something. A translator who
    # sees them as one string cannot make that distinction in the other script.
    assigns = %{label: gettext("Clear watch history…")}

    ~MOB"""
    <Text
      text={@label}
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
    # `ngettext/4` rather than the interpolation that stood here. `"Cleared
    # #{cleared} logs."` printed **Cleared 1 logs.** for the reader who had one
    # thing logged, on the one screen in the app where every word is being read
    # carefully because something has just been destroyed. Persian does not
    # inflect a noun after a numeral, so its two forms are the same sentence —
    # the plural exists for the English side of the pair.
    #
    # `Kati.Locale.number/1` on the figure: this one is inside a sentence and
    # takes the reader's numerals, unlike the four in `figure/1`, which are a
    # mono column and take their face with them.
    assigns = %{
      text:
        ngettext("Cleared %{n} log.", "Cleared %{n} logs.", cleared,
          n: Kati.Locale.number(cleared)
        )
    }

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
  @spec confirm(boolean(), map() | :error) :: map()
  # `is_map/1` on this clause so `:error` falls through to the resting one
  # instead of raising on `counts.logs`. `Kati.Media.History.counts/0` answers
  # the atom when the store cannot be read, and it is the same assign this
  # clause reads — `handle_tap(:clear, …)` writes a fresh `counts/0` into the
  # socket, so the shape can change under a screen that is already mounted.
  # Nothing reaches it today (the row that sets `confirming?` is only drawn by
  # the readable branch of `body/2`), and a confirmation that crashes rather
  # than closes is still not the failure to leave standing on this screen.
  def confirm(true, counts) when is_map(counts) do
    # `line_height` on the two sentences below is `Kati.Locale.leading/1` rather
    # than the flat 1.5 that was there. Vazirmatn's metrics are not Plus
    # Jakarta's — `Kati.Theme.fa_line_height/0` carries the argument — and both
    # of these wrap to two or three lines inside a 28pt-inset card, which is
    # where the difference is read rather than measured.
    assigns = %{
      heading:
        ngettext("Clear %{n} log?", "Clear %{n} logs?", counts.logs,
          n: Kati.Locale.number(counts.logs)
        ),
      changes: gettext("Changes: every tick, rating and review, and every progress ring."),
      keeps:
        gettext(
          "Does not change: your shelves, your lists, your reading sessions and your listens."
        )
    }

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
            text={@changes}
            text_size={12.5}
            line_height={Kati.Locale.leading(1.5)}
            text_color={Palette.sub()}
            text_align="center"
          />
          <Spacer size={7} />
          <Text
            text={@keeps}
            text_size={12.5}
            line_height={Kati.Locale.leading(1.5)}
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
    # Both labels are plain `gettext/1` and stay a pair. *Keep it* is already
    # `Kati.Screens.ListDetail`'s msgid for the same button on the same kind of
    # confirmation, so this screen reuses it rather than asking for a second
    # Persian word for the same answer; *Clear it* is its opposite number and
    # gets no context for the same reason — a destructive pair that a
    # translator meets apart is a pair that stops reading as one.
    assigns = %{clear: gettext("Clear it"), keep: gettext("Keep it")}

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
          text={@clear}
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
          text={@keep}
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
