defmodule Kati.Screens.ImportSources do
  @moduledoc """
  Screen 140 — Import sources, pushed under Settings. Step 0 of the importer.

  Built to `test/design/reference/140.html`. Screen 37 (`Kati.Screens.Import`)
  is drawn *mid-job* — a file already read, columns already matched. This is
  what comes before it: a grid of every source Kati recognises, so the job on
  37 has a file to open at all. The drawing's own argument, from its caption,
  is that the commonest failure at this step is bringing the wrong file, and
  the fix is naming the file rather than the format — `"CSV export"` fits
  eleven different exports and stops nobody; `goodreads_library_export.csv`
  can only be one thing.

  ## Eleven sources, two of them not like the other nine

  `@commonest` is the six the grid draws — Goodreads, StoryGraph, Letterboxd,
  Trakt, MyAnimeList, AniList — each a card naming the exact file to bring. The
  four after them (Simkl, TV Time, Libib, Last.fm) collapse into one row,
  `more/0`, because ten equal cards is more grid than a 402pt board reads —
  the drawing's own second open choice.

  The other two are `kati_backup/0` and `something_else/0`, and the task this
  screen is built from is explicit that they **must not look like** the ten
  above: neither is a source Kati is importing *from* in the ordinary sense.

    * **A Kati backup** is the drawing's own words for *this is not import's
      job* — its sub-line says so outright: *"goes to Restore instead"*. It
      sits **above** the grid as its own single-row card, because it leaves
      this screen entirely rather than feeding the same pipeline the grid
      leads into.
    * **Something else** is the opposite kind of different: not a wrong turn
      but a real path with no recognition step, so it sits **below** a full
      rule under its own muted eyebrow — a footnote to the grid rather than a
      twelfth source in it.

  Both are drawn as the same single-row card shape the grid's "Five more
  sources" summary uses (`Kati.UI.SettingsList.card/1` + `row/4`), which is
  deliberately *not* the grid's own card: the ten real sources are six-plus-
  five identical tiles naming a file; these two are prose naming a decision.

  ## Why the step meter is redrawn rather than called

  `Kati.Screens.Import.step_bar/1` and `step_gap/0` are reused — same 4pt bar,
  same 5pt gap, same `Palette.ink()` / `Palette.track_off()` split. But the
  drawing puts the meter *above* the title here, where 37 puts it below, so the
  composing function has to be this screen's own — exactly the call
  `Kati.Screens.PlanImport.steps/1` already made for the same reason, down to
  the closing 20pt gap and the title's 11.5pt / 6pt kicker numbers, which this
  screen's own CSS also specifies (37's are 11 / 5). Five bars, one done, for
  *"STEP 0 OF 4"* — the fifth segment is the step this screen itself is.

  ## Why every tap pushes to a screen that is not quite about it

  There is no screen 141 in this codebase yet — the drawing's own next frame,
  *"Import — recognised"*, is a different board and out of scope here — so
  there is nowhere to send a tap that would show *this specific source,
  recognised*. Sending it nowhere was rejected instead: an un-wired tap on a
  row whose entire drawn affordance is a `chevron_right` is reported dead by
  the sweep, and would also just be a lie of a different kind — a picker that
  looks tappable and is not.

  So every real source — the six tiles and the five-more row alike — pushes to
  `Kati.Screens.Import`, the nearest step of the *same job* that is actually
  built. Its job is `Kati.Import.Sample`'s fixed Trakt fixture regardless of
  which tile sent you there, which is the same thing every sample-backed
  screen in this app already does — `Kati.Screens.Rating` does not vary by
  which title pushed it either. `Something else` pushes there too, and for it
  the destination is not an approximation: its own sub-line is *"Any CSV — map
  the columns yourself"*, which is what screen 37 shows.

  `A Kati backup` is the one tap that is not a stand-in. It pushes to
  `Kati.Screens.Backup`, which is where the drawing's own sub-line says it
  goes — restore, not import.

  ## The rule under "Five more sources", and why its colour is a literal

  `rgba(26,25,23,.12)` — 12% ink — is the "full rule" the design's own caption
  names, separating the grid-plus-five-more group above from *Not on the
  list* below. `Kati.Theme.Palette`'s ink-tint ladder is dense but not
  continuous: `hairline` 7%, `hairline_soft` 8%, `hairline_strong` 10%,
  `border_soft` 14%, `border` 16%, `border_strong` 18%, `border_stronger` 20%,
  `track_ink` 22%, `divider_heavy` 35% — and 12% sits in the one gap the ladder
  leaves, between `hairline_strong` and `border_soft`. Taking either neighbour
  would move this rule off the drawing's own value, and the module's own rule
  is that light must not move by a pixel over a value that is merely close.
  `full_rule_color/1` is the literal instead, `0x1F1A1917` in light — `rem(.12
  * 255) = 31 = 0x1F`, the same rounding `hairline`'s own 7% → `0x12` already
  uses — and `0x1FF5F2EE` in dark by the same alpha-keeps / ink-swaps rule
  `hairline` itself is built from. `render: :box` is still not optional for
  the reason `Kati.UI.SettingsList.hairline/1`'s own doc gives: the default
  `:divider` primitive antialiases a 1dp rule into a lighter last pixel row at
  this device's density, and a filled rect does not.

  ## One literal the drawing repeats, corrected by the drawing's own arithmetic

  *"Five more sources"* listed `Simkl · TV Time · Libib · Last.fm · AniList` —
  and AniList is already one of the six tiles above it. This module used to
  keep the repeat exactly as drawn, on the ground that guessing what was meant
  would be inventing copy; MOVIES-AND-TV.md #126 is the finding that it reads
  as a mistake to anybody looking at the grid.

  There is no guess to make. The drawing's own closing note counts eleven
  sources — six tiles plus four new names plus the Kati backup row — so the
  drawing says four here and its sub-line says five. It is **four** now, and
  the four names are the drawing's own minus the one it repeats. That is the
  same call `Kati.Screens.Season` made about its board's episode numbers: a
  drawing that contradicts itself is read at the place it is right.

  ## What the row opens, now that it opens something

  It pushed `Kati.Screens.Import` — the manual mapper, with no file. So the
  one row on this board that names four services took the reader to a column
  table about nothing. It opens the picker now, exactly as a tile does, and
  hands what comes back to screen 141 with no source named: the mapping is by
  column header (`Kati.Import.Mapping`), so a Simkl export reads without a tile
  to press, and `looks_like/1` tells the reader what it recognised. Naming no
  source is the honest push — Kati has not been told which of the four it is,
  and 141 says `CSV` rather than guessing.

  ## No Sample module

  `Kati.Import.Sample` holds screen 37's mid-job fixture because there is a
  real resource shape behind it — a file, a mapping, an outcome, a conflict
  queue — that simply has nowhere to live yet. This screen has no such gap:
  the eleven sources Kati recognises are a constant of the build, not a
  table that might be empty, so `@commonest` sits here the same way
  `Kati.Screens.MyServices`'s `@rules` and `Kati.Screens.Attribution`'s
  `@sources` sit in their own screens — a screen's file still holds every
  literal its drawing contains.
  """

  use Kati.Screens.Pushed, back: "Settings"

  alias Kati.Components.MishkaSeparator
  alias Kati.Components.MishkaThemeIcon
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  # The grid, in the drawing's own order — each a single mono capital, the
  # exact file Kati expects, and nothing about format. See the moduledoc for
  # why the sub-line is always a filename.
  @commonest [
    %{id: :goodreads, letter: "G", name: "Goodreads", file: "goodreads_library_export.csv"},
    %{id: :storygraph, letter: "S", name: "StoryGraph", file: "storygraph_export.csv"},
    %{id: :letterboxd, letter: "L", name: "Letterboxd", file: "letterboxd-export.zip"},
    %{id: :trakt, letter: "T", name: "Trakt", file: "trakt-export.json"},
    %{id: :myanimelist, letter: "M", name: "MyAnimeList", file: "animelist.xml"},
    %{id: :anilist, letter: "A", name: "AniList", file: "anilist-export.json"}
  ]

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
        {Kati.Screens.ImportSources.steps()}
        {Kati.Screens.ImportSources.title()}
        {Kati.Screens.ImportSources.kati_backup()}
        {UI.eyebrow("The six commonest")}
        {Kati.Screens.ImportSources.grid()}
        {Kati.Screens.ImportSources.more()}
        {Kati.Screens.ImportSources.full_rule()}
        {SettingsList.eyebrow_muted("Not on the list")}
        {Kati.Screens.ImportSources.something_else()}
        {SettingsList.note(
          "info",
          "The sub-line names the file, not the format — one rule for all eleven. " <>
            "“CSV export” is short and useless; goodreads_library_export.csv stops " <>
            "the commonest failure here, which is bringing the wrong file, before " <>
            "the picker even opens."
        )}
      </Column>
    </Scroll>
    """
  end

  @doc """
  Five bars, one done — `"STEP 0 OF 4"`. Above the title; see the moduledoc
  for why this cannot be `Kati.Screens.Import.steps/1` unchanged.
  """
  def steps do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        {1..5
         |> Enum.map(fn i -> Kati.UI.ImportChrome.step_bar(i <= 1) end)
         |> Enum.intersperse(Kati.UI.ImportChrome.step_gap())}
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc false
  def title do
    ~MOB"""
    <Column fill_width={true}>
      <Text
        text="Where are you coming from?"
        text_size={28}
        max_font_scale={1.6}
        font_weight="bold"
        letter_spacing={-0.03}
        text_color={:on_surface}
      />
      <Spacer size={6} />
      <Text
        text="STEP 0 OF 4 · PICK ONE AND KATI DOES THE MAPPING"
        font_family="mono"
        text_size={11.5}
        text_color={Palette.muted()}
        max_lines={1}
      />
      <Spacer size={20} />
    </Column>
    """
  end

  @doc """
  The one row that leaves this screen entirely. See the moduledoc for why it
  sits above the grid rather than inside it.
  """
  def kati_backup do
    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.card([
        SettingsList.row(
          SettingsList.icon_tile("cloud_done"),
          SettingsList.body("A Kati backup", "Your own .json — goes to Restore instead"),
          SettingsList.trailing(SettingsList.chevron()),
          rule: false,
          on_tap: {self(), :kati_backup}
        )
      ])}
      <Spacer size={16} />
    </Column>
    """
  end

  @doc "The six tiles, two to a row, 12pt of gap on both axes."
  def grid do
    rows =
      @commonest
      |> Enum.chunk_every(2)
      |> Enum.map(fn pair ->
        UI.even_row(Enum.map(pair, &Kati.Screens.ImportSources.source_tile/1),
          columns: 2,
          gap: 12
        )
      end)
      |> Enum.intersperse(Kati.Screens.ImportSources.grid_row_gap())

    ~MOB"""
    <Column fill_width={true}>
      {rows}
      <Spacer size={14} />
    </Column>
    """
  end

  @doc false
  def grid_row_gap, do: ~MOB"<Spacer size={12} />"

  @doc """
  One card of the grid: a 34pt paper tile carrying a mono letter, the source's
  name, and the exact file it expects — never the format.
  """
  def source_tile(source) do
    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={20}
      shadow={Kati.Theme.shadow_card_soft()}
      padding={15}
      on_tap={{self(), Kati.Screens.ImportSources.tag(source.id)}}
    >
      {Kati.Screens.ImportSources.source_letter(source.letter)}
      <Spacer size={12} />
      <Text
        text={source.name}
        text_size={13.5}
        font_weight="bold"
        letter_spacing={-0.01}
        text_color={:on_surface}
        max_lines={1}
      />
      <Spacer size={5} />
      <Text
        text={source.file}
        font_family="mono"
        text_size={10.5}
        line_height={1.5}
        text_color={Palette.sub()}
      />
    </Column>
    """
  end

  @doc """
  The 34x34 paper tile a grid card leads with — `Kati.Screens.Import.file_tile/0`'s
  own recipe, one size and one radius over, and a mono letter as the child
  instead of a Material Symbol.
  """
  def source_letter(letter) do
    MishkaThemeIcon.theme_icon(
      %{variant: :filled, color: Kati.Theme.paper(Palette.mode()), size: 34, radius: 11},
      [Kati.Screens.ImportSources.source_letter_text(letter)]
    )
  end

  @doc false
  def source_letter_text(letter) do
    ~MOB"""
    <Text text={letter} font_family="mono" text_size={14} text_color={Palette.ink()} max_lines={1} />
    """
  end

  @doc """
  The summary row, and the door behind it.

  Board 328: *"a count that matches its own names."* Both halves come from
  `Kati.Screens.MoreSources` now — the heading is counted from the list and the
  sub-line is joined from it — so the two cannot drift apart again, which is the
  defect 140 shipped and 278 reproduced.

  And the chevron opens the four. It used to push the manual column mapper with
  no file and no source, so the one row naming four services opened a mapping
  screen for none of them.
  """
  def more do
    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.card([
        SettingsList.row(
          SettingsList.icon_tile("more_horiz"),
          SettingsList.body(
            Kati.Screens.MoreSources.heading(),
            Kati.Screens.MoreSources.names()
          ),
          SettingsList.trailing(SettingsList.chevron()),
          rule: false,
          on_tap: {self(), :more_sources}
        )
      ])}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc "The 12% rule under the summary row. See the moduledoc for the literal."
  def full_rule do
    ~MOB"""
    <Column fill_width={true}>
      {MishkaSeparator.separator(
        color: Kati.Screens.ImportSources.full_rule_color(Palette.mode()),
        thickness: 1,
        render: :box
      )}
      <Spacer size={20} />
    </Column>
    """
  end

  @doc false
  def full_rule_color(_mode), do: Palette.rule_full()

  @doc """
  The footnote row: a real path, just one with no recognition step. Its own
  sub-line is why it pushes to `Kati.Screens.Import` rather than nowhere — see
  the moduledoc.
  """
  def something_else do
    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.card([
        SettingsList.row(
          SettingsList.icon_tile("edit_note"),
          SettingsList.body("Something else", "Any CSV — map the columns yourself"),
          SettingsList.trailing(SettingsList.chevron()),
          rule: false,
          on_tap: {self(), :something_else}
        )
      ])}
      <Spacer size={14} />
    </Column>
    """
  end

  @doc """
  A tile's tap tag, as an atom rather than a `{:source, id}` tuple.

  A tuple tag works — `Mob.Renderer` registers `{pid, tag}` for any `tag`, and
  `Mob.List` tags its rows `{:list, id, :select, index}`. What a tuple does not
  get is a name. Only the `is_atom(tag)` clause of that same function also emits
  `accessibility_id`, and that id is what reads a control from the outside:
  `Kati.ScreenSweep` collects `%{on_tap: {pid, tag}} when is_atom(tag)`, so
  tuple-tagged tiles are invisible to the tap sweep and to
  `Kati.AppReachabilityTest`'s push graph — eleven tiles that nothing could
  check, and eleven a screen reader could not name either.

  `"source_" <> id` is the shape screens 98 and 03 already use for the same
  problem — a tag per member of a drawn family — and `handle_tap/2` splits it
  back apart the way they do.
  """
  @spec tag(atom() | String.t()) :: atom()
  def tag(id) when is_atom(id), do: tag(Atom.to_string(id))
  def tag(id) when is_binary(id), do: String.to_atom("source_" <> id)

  @doc """
  A source tile opens the file picker, and remembers which tile it was.

  Until the importer existed these six tiles pushed a drawing, and which
  drawing was the whole of #52. There is a file now: the tile opens the system
  document picker, and the picked file is read into a
  `Kati.Import.Job` and handed to screen 37.

  The id is kept on the socket rather than in the push, and it decides only
  what to draw if the reader cancels or picks something unreadable — the
  mapping itself is by HEADER (`Kati.Import.Mapping`), because every one of
  these services lets you re-order the columns before export and a mapping by
  source would be right until somebody did.
  """
  @impl true
  def handle_tap(tag, socket) when is_atom(tag) do
    case Atom.to_string(tag) do
      "source_" <> id ->
        {:noreply, Kati.Screens.ImportSources.choose_file(socket, id)}

      _other ->
        handle_other(tag, socket)
    end
  end

  @doc """
  Open the system document picker, remembering which tile asked.

  Rescued for `Kati.Screens.Restore.choose/1`'s reason, which is the whole
  native boundary's: Kati runs one screen process, `Mob.Files.pick/2` reaches
  `:mob_nif.files_pick/1` directly, and an unbound NIF raising here would take
  the screen down rather than fail a button. A platform with no picker is told
  as much — and that platform includes every host test, which is why this shape
  and not a bare call.
  """
  @spec choose_file(Mob.Socket.t(), String.t()) :: Mob.Socket.t()
  def choose_file(socket, id) do
    socket
    |> Mob.Socket.assign(:source, id)
    |> Kati.Native.Files.pick(types: ["csv", "text/csv"])
  rescue
    # No picker bound: a host test, and any build without the NIF. The tile
    # then does what it did before there was an importer — it opens the board
    # of its own kind, which is #52's fix and is why `opens/1` is still here.
    # A film source does not open a page about books, with a file or without
    # one.
    _exception ->
      Mob.Socket.push_screen(socket, Kati.Screens.ImportSources.opens(id))
  end

  @doc """
  What the picker answered.

  A picked file goes to screen 37 with its path and its name; a cancel says so
  and changes nothing; anything else is reported in the words
  `Kati.Screens.Import` would have used, because the reader is owed the same
  sentence wherever the refusal happens.
  """
  @impl true
  def handle_info({:files, :picked, [item | _rest]}, socket) do
    {:noreply,
     Mob.Socket.push_screen(socket, Kati.Screens.ImportRecognised, %{
       # 141, not 37: the flow the boards draw is *here is what I found* and
       # then *check the mapping*, and skipping the first would put a reader in
       # front of a column table before they had been told what file it is.
       path: Kati.Screens.ImportSources.string(item[:path]),
       name: Kati.Screens.ImportSources.string(item[:name]),
       source: Map.get(socket.assigns, :source),
       back: "Import"
     })}
  end

  def handle_info({:files, :cancelled}, socket),
    do: {:noreply, Mob.Socket.assign(socket, :notice, "No file was chosen.")}

  def handle_info(message, socket), do: super(message, socket)

  @doc false
  def string(value) when is_binary(value), do: value
  def string(value) when is_list(value), do: List.to_string(value)
  def string(_other), do: ""

  @doc """
  Which recognised-job board a source's tile opens.

  The tag carried the id and `handle_tap/2` threw it away, so all six tiles
  pushed screen 141 — a **Goodreads** job, headed with a book's columns:
  *Author*, *Bookshelves*, *Number of Pages*. Four of the six sources in that
  grid are film and TV — Letterboxd, Trakt, MyAnimeList, AniList — and every
  one of them landed on a screen about books. MOVIES-AND-TV.md #52.

  There IS an import engine now — `Kati.Import.Job` — and a tile opens the
  picker rather than a board. This is what a tile falls back to when no picker
  is bound, which is every host test and any build without the NIF, and the
  distinction it draws is unchanged: a film source does not open a page about
  books. Screen 141 is a Goodreads export and screen 37
  is a Trakt one, so a books tile opens the books job and a films tile opens
  the films job. Neither claims to have read the file the reader picked, and
  neither did before — the difference is that a person importing Letterboxd is
  no longer shown somebody's bookshelves.

      iex> Kati.Screens.ImportSources.opens("letterboxd")
      Kati.Screens.Import

      iex> Kati.Screens.ImportSources.opens("goodreads")
      Kati.Screens.ImportRecognised

      iex> Kati.Screens.ImportSources.opens("something-nobody-drew")
      Kati.Screens.ImportRecognised
  """
  @spec opens(String.t()) :: module()
  # No source named is the *Four more sources* row (#126) and the host's own
  # rescue path, and both want the manual mapper: nothing has been said about
  # which service the file is from, so there is no guess for 141 to describe.
  def opens(nil), do: Kati.Screens.Import

  def opens(id) when id in ~w(letterboxd trakt myanimelist anilist),
    do: Kati.Screens.Import

  def opens(_id), do: Kati.Screens.ImportRecognised

  defp handle_other(tag, socket), do: fallback(tag, socket)

  # Board 328's screen, which is what this row always promised. It pushed the
  # manual mapper with no file and no source until 7 September, so the one row
  # naming four services opened a column table about nothing (#126).
  defp fallback(:more_sources, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.MoreSources)}

  defp fallback(:something_else, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Import)}

  defp fallback(:kati_backup, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Restore)}

  defp fallback(_tag, socket), do: {:noreply, socket}
end
