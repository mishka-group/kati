defmodule Kati.Screens.ImportRecognised do
  @moduledoc """
  Screen 141 — Import, source recognised, pushed under Settings.

  Built to `test/design/reference/141.html`. One step earlier than screen
  37: the file has been read and a source has been guessed, but nobody has
  looked at the mapping yet. The drawing's argument is proportion — a person
  who has not asked to see nine columns matched one by one should not be
  handed a table before they have even confirmed the guess is right, so the
  mapping opens collapsed to one line and the guess itself is offered a
  correction before anything else on the screen.

  ## The board draws the mapping twice, and so does the screen

  Board 141 lays the mapping card out twice, each under its own mono label —
  `Mapping — collapsed` after a grey dash, `Mapping — expanded` after an
  orange one — and its caption says why in one line: *expanded below so both
  states are comparable*. That is the same sentence, and the same two dash
  colours, that a dozen screens in this app already answer by drawing every
  state one under the other with a labelled divider between them
  (`Kati.Screens.EpisodeRatings` draws its episode list rated and unrated,
  `Kati.Screens.BackupStates` its card never-backed-up and stale). Grey is
  `Kati.UI.SettingsList.eyebrow_muted/1` — a footnote to the section above it —
  and orange is `Kati.UI.eyebrow/2`, new-or-now. Both labels are copy on the
  board and both are drawn.

  An earlier build of this screen read the two frames as a *spec caption*
  rather than copy and collapsed them into one disclosure: one card, an
  `:toggle_mapping` assign, `chevron_right` swapping for `expand_more`. That
  invented a control the board does not draw and hid nine rows of copy behind
  it, which is the failure `Kati.ScreenDesignLiteralTest` exists to catch — a
  section the drawing shows, built but never mounted, with every frame still
  looking right. The board's chevron is `chevron_right`, which everywhere else
  in this app means *this row opens a page*, not *this row unfolds*.

  So `mapping_collapsed/1` draws the resting card and `mapping_expanded/1` the
  open one, both always, and the summary row's tap does what its chevron
  promises: `:check_mapping` pushes `Kati.Screens.Import`, screen 37, which is
  this same mapping with a sampled value beside every row. Screen 140 already
  pushes here; this is the next step of the same flow, not a placeholder.

  ## `What will happen` keeps its footnote grey rather than screen 37's orange

  Screen 37 opens `UI.eyebrow("What will happen")` at the accent dash — the
  primary thing on that screen, three steps in, mapping already reviewed.
  Board 141 draws the same label at `#C4BDB3`, the grey `eyebrow_muted/1`
  reserves for a section that is a footnote to the one above it. That is the
  correct dash for step 1: the counts are a preview of what the still-collapsed
  mapping will do, not the thing this screen is asking the person to look at.

  ## The star the font turned out to have

  Board 141 draws ★ twice — `converts 10pt → 5★` under *My Rating*, and
  `10pt → 5★` inside the `auto_awesome` banner. Both are the character, in
  one `Text` each, and that contradicts screens 08, 15, 33 and 37, which all
  splice a Material Symbols `star` glyph into a `Row` because *Plus Jakarta
  Sans carries no U+2605*. **That is no longer true of the font this app
  ships**, and it is worth writing down where it can be re-checked:

      android/app/src/main/res/font/kati_sans_400.ttf
        cmap: U+2605 → glyph 981
        glyf: 1 contour, 10 on-curve points, bbox (36,-12)-(845,757)
              (191,-12) (286,281) (36,463) (345,463) (440,757)
              (536,463) (845,463) (595,281) (691,-12) (440,169)
        hmtx: advance 882/1000 upem

  Ten points alternating outer and inner radius about (440,372) is a
  five-pointed star, and it is in all five weights (400-800) with the advance
  scaling 882→938. `kati_mono` genuinely has no U+2605, which is why the
  mapping row's mono *column* is not where this note lives.

  The splice was never free, and this board is where the cost shows. A
  `Row` of [Text, glyph, Text] cannot wrap, so the banner's sentence — three
  lines at the card's width — could not have the mark at all: an earlier build
  of this screen wrote `5 stars` there and said the literal was unreachable.
  With the character it is one `Text`, it wraps, and it says what the board
  says. The mapping row's note gets the same treatment for consistency within
  the screen rather than necessity.

  **This is deliberately not a change to screens 08, 15, 33 or 37.** Those
  splice a *rating* — five glyphs in a row at 30px, one of them outlined for a
  half — which is a different problem from one mark inside a line of copy, and
  unifying them is a change that wants a device capture behind it rather than
  a font table. `Kati.Screens.ShelfFilters` already ships `4★ and up` as the
  character, so this screen is the second, not the first.

  ## `Not Goodreads? Change` pops the screen, honestly

  There is no source-picker screen or resource this can hand the guess back
  to — the note under `Kati.Import.Sample`'s moduledoc is still true, there is
  no reader and no job. `Mob.Socket.pop_screen/1` is the one real thing this
  tap can honestly do: return to whatever screen offered the file in the
  first place, which is where picking a different source actually happens.
  It is a genuine navigation change, not a placeholder dressed as one.

  No dock on a pushed screen, so the frame's bottom inset is 40 rather than
  132, same as screen 37.

  ## Why this screen is still on `Kati.Import.Sample`

  Same case screen 37 already makes in full: no reader and no job resource, so
  a screen drawn mid-flow has nothing behind it to read the file, the guess or
  the nine-column mapping from. `Kati.Import.Sample.recognised/0` is a second
  job beside `job/0` in the same module, not a new one, because both are the
  same stand-in for the same not-yet-real reader — and `recognised_columns/0`
  is what both mapping frames on this screen draw, so the two states cannot
  drift apart into two hand-written tables.

  ## Audited

  Two taps are drawn and both reach a handler that navigates: `Check the
  mapping` pushes screen 37, and `Not Goodreads? Change` pops back to whoever
  offered the file. Nothing else on the board is a control — the mapping
  table's rows describe a match, they do not offer one, and the three outcome
  cards are a count, not a button.

  **What neither tap can do yet is change the mapping.** The board's summary
  line ends `still editable` and screen 37 shows the same nine rows without a
  control on any of them, because there is no job resource to write a
  correction into: `Kati.Import.Sample` is a literal, so a person who decides
  *Publisher* should not be skipped has nowhere to say so. That is the same
  missing resource screen 37's own moduledoc names, and it is the one promise
  on this board the app does not keep.
  """

  use Kati.Screens.Pushed, back: "Settings"

  alias Kati.Components.MishkaPill
  alias Kati.Components.MishkaSeparator
  alias Kati.Components.MishkaThemeIcon
  alias Kati.Import.Sample
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  @impl true
  def load(socket) do
    params = socket.assigns.params || %{}

    socket
    |> Mob.Socket.assign(:job, Kati.Screens.ImportRecognised.job_for(params))
    |> Mob.Socket.assign(:file, {Map.get(params, :path), Map.get(params, :name)})
    |> Mob.Socket.assign(:result, nil)
  end

  @doc """
  The file this screen describes: the one that was picked, or the drawing's.

  Screen 140 opens the document picker and pushes the result here, so this is
  the first screen in the flow that has ever had a real file behind it. A push
  naming none — the gallery, a sweep — gets `Kati.Import.Sample.recognised/0`,
  which is the state board 141 was captured in.
  """
  @spec job_for(map()) :: map()
  def job_for(params) do
    path = Map.get(params, :path)
    name = Map.get(params, :name)
    picked = Map.get(params, :source)

    with true <- is_binary(path) and is_binary(name),
         {:ok, job} <- Kati.Import.Job.read(path, name) do
      job
      |> Kati.Import.Job.recognised()
      |> Map.put(:source, Kati.Screens.ImportRecognised.source_name(picked))
      |> Map.put(:mismatch, Kati.Screens.ImportRecognised.mismatch(job, picked))
    else
      # A file that could NOT be read is not the same as a push that named
      # none, and this is the whole of board 142's objection: a reader who
      # handed Kati a photo was shown somebody else's Goodreads export and
      # told it had 418 rows. So a refusal is its own small map rather than
      # the fixture with a note on top — there is no count to draw, no
      # mapping table to check and nothing to import, and a page that draws
      # them anyway is lying in nine places to apologise in one.
      {:error, reason} ->
        %{
          refusal: reason,
          refused_name: name,
          source: Kati.Screens.ImportRecognised.source_name(picked)
        }

      _no_file ->
        Sample.recognised()
    end
  end

  @doc """
  When the file disagrees with the tile the reader tapped, or `nil`.

  Board 142's first edge state — *wrong guess* — and the file itself is what
  knows: `Bookshelves` is Goodreads' column and nobody else's. The reader is
  told rather than corrected, because the mapping is by header and works
  either way; what a wrong tile actually costs them is a wrong expectation.

      iex> Kati.Screens.ImportRecognised.mismatch(%{looks_like: "goodreads"}, "letterboxd")
      {"Goodreads", true}

      iex> Kati.Screens.ImportRecognised.mismatch(%{looks_like: "letterboxd"}, "letterboxd")
      nil

      iex> Kati.Screens.ImportRecognised.mismatch(%{looks_like: nil}, "letterboxd")
      nil
  """
  @spec mismatch(map(), String.t() | atom()) :: {String.t(), boolean()} | nil
  def mismatch(job, picked) when is_atom(picked) and not is_nil(picked),
    do: Kati.Screens.ImportRecognised.mismatch(job, Atom.to_string(picked))

  def mismatch(job, picked) do
    case Map.get(job, :looks_like) do
      nil ->
        nil

      ^picked ->
        nil

      other ->
        # A films reader who has landed on a books export has made a different
        # mistake from one who picked the wrong film service, and the sentence
        # differs.
        {Kati.Screens.ImportRecognised.source_name(other),
         Kati.Import.Mapping.books?(other) != Kati.Import.Mapping.books?(picked)}
    end
  end

  @doc """
  Board 142's *wrong guess*, drawn over a file that still reads — or nothing.

  Gold `help`, not red `error`, and the board's own paragraph on the two
  glyphs says why: this is not a hard stop. The mapping is by column name, so
  a Letterboxd file picked under the Trakt tile imports exactly as well as it
  would have under its own. What the wrong tile actually cost the reader is an
  expectation, and an expectation is corrected with a sentence.
  """
  @spec mismatch_band(map()) :: map()
  def mismatch_band(job) do
    case Map.get(job, :mismatch) do
      nil ->
        ~MOB"<Spacer size={0} />"

      {looks_like, different_kind?} ->
        Kati.Screens.ImportRecognised.notice(
          "help",
          "This looks like a #{looks_like} export",
          Kati.Screens.ImportRecognised.mismatch_line(looks_like, different_kind?)
        )
    end
  end

  @doc """
  The whole page, when the file could not be read.

  Board 142's red `error` card with its `Pick again` pill live — the one
  control a refusal can honestly offer, and the one board 142 draws inert at
  `Kati.Screens.ImportStates.unrecognised/0`. `Something else` is named in the
  sentence rather than drawn beside it, exactly as the board names it: it is
  the picker's own manual-mapping tile, one pop away, not a second button
  competing here.
  """
  @spec refused(map()) :: map()
  def refused(job) do
    assigns = %{
      card:
        Kati.Screens.ImportRecognised.notice(
          "error",
          Kati.Screens.ImportRecognised.refusal_title(Map.get(job, :refusal)),
          Kati.Screens.ImportRecognised.refusal_body(
            Map.get(job, :refusal),
            Map.get(job, :refused_name)
          )
        ),
      source: Map.get(job, :source)
    }

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        <Spacer size={44} />
        <Text text={@source} text_size={26} font_weight="bold" text_color={:on_surface} />
        <Spacer size={18} />
        {@card}
      </Column>
    </Scroll>
    """
  end

  @doc false
  def mismatch_line(looks_like, true),
    do:
      "Its columns are #{Kati.Screens.ImportRecognised.possessive(looks_like)}. Kati maps by " <>
        "column name, so it will still read — but a books export has no watches in it."

  def mismatch_line(looks_like, false),
    do:
      "Its columns are #{Kati.Screens.ImportRecognised.possessive(looks_like)}. Kati maps by " <>
        "column name, so it will still read."

  @doc """
  A source's name, owning something — and `Goodreads` is why this is a function.

      iex> Kati.Screens.ImportRecognised.possessive("Letterboxd")
      "Letterboxd's"

      iex> Kati.Screens.ImportRecognised.possessive("Goodreads")
      "Goodreads'"
  """
  @spec possessive(String.t()) :: String.t()
  def possessive(name) do
    if String.ends_with?(name, "s"), do: name <> "'", else: name <> "'s"
  end

  @doc """
      iex> Kati.Screens.ImportRecognised.refusal_title(:unrecognised)
      "Kati could not read that file"
  """
  @spec refusal_title(atom()) :: String.t()
  def refusal_title(:unreadable), do: "That file could not be opened"
  def refusal_title(:empty), do: "That file is empty"
  def refusal_title(_unrecognised), do: "Kati could not read that file"

  @doc false
  def refusal_body(:unreadable, name),
    do:
      "#{Kati.Screens.ImportRecognised.said(name)} Nothing on this device has changed. " <>
        "Pick again, or choose Something else to map a file by hand."

  def refusal_body(:empty, name),
    do:
      "#{Kati.Screens.ImportRecognised.said(name)} It has no rows in it. " <>
        "Pick again, or choose Something else to map a file by hand."

  def refusal_body(_unrecognised, name),
    do:
      "#{Kati.Screens.ImportRecognised.said(name)} None of its column names is one Kati " <>
        "knows, so there is nothing it could safely put on your shelf. Pick again, or " <>
        "choose Something else to map it by hand."

  @doc false
  def said(name) when is_binary(name) and name != "", do: "You chose “#{name}”."
  def said(_none), do: ""

  @doc """
  Board 142's card, rebuilt around a real file's own words.

  Same geometry as `Kati.Screens.ImportStates.unrecognised/0` — card ground,
  22pt radius, 17pt padding, the glyph in its own column beside a bold line
  and a soft body — because the board is what a reader has already been shown
  this state in, and a flow that answers with a different-looking card reads
  as a different thing happening.

  Rebuilt rather than called, for `source_tile/3`'s reason on that board: the
  sheet's cards are literals about Goodreads and Letterboxd by name, and a
  live file is about whatever it turned out to be.
  """
  @spec notice(String.t(), String.t(), String.t()) :: map()
  def notice(tone, title, body) do
    assigns = %{
      title: title,
      body: body,
      glyph: tone,
      colour: Kati.Screens.ImportRecognised.tone(tone),
      # Only a refusal has somewhere to go. A wrong guess is already on the
      # page it belongs on: the file reads, and the way out of it is to keep
      # reading.
      pick_again: if(tone == "error", do: {self(), :change_source})
    }

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        padding={17}
        shadow={Kati.Theme.shadow_card_soft()}
      >
        <Row fill_width={true} align="top">
          {UI.symbol(@glyph, size: 19, color: @colour)}
          <Spacer size={11} />
          <Column weight={1.0}>
            <Text text={@title} text_size={13.5} font_weight="bold" text_color={:on_surface} />
            <Spacer size={6} />
            <Text text={@body} text_size={12.5} line_height={1.65} text_color={Palette.ink_soft()} />
          </Column>
        </Row>
        {Kati.Screens.ImportRecognised.pick_again(@pick_again)}
      </Column>
      <Spacer size={18} />
    </Column>
    """
  end

  @doc """
  `Pick again`, or nothing at all — never a pill that does nothing.

      iex> Kati.Screens.ImportRecognised.pick_again(nil)
      Kati.Screens.ImportRecognised.blank()
  """
  @spec pick_again(term()) :: map()
  def pick_again(nil), do: Kati.Screens.ImportRecognised.blank()

  def pick_again(tap) do
    assigns = %{tap: tap}

    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={14} />
      <Row fill_width={true} align="center">
        <Spacer weight={1.0} />
        {SettingsList.action_pill("Pick again", @tap)}
      </Row>
    </Column>
    """
  end

  @doc false
  def blank, do: ~MOB"<Spacer size={0} />"

  @doc """
  Red when Kati refused the file, gold when it merely disagrees with the tile.

      iex> Kati.Screens.ImportRecognised.tone("error") == Kati.Theme.Palette.red()
      true
  """
  @spec tone(String.t()) :: term()
  def tone("error"), do: Palette.red()
  def tone(_help), do: Palette.gold_icon()

  @doc """
  The source the reader said they were coming from, named as they would say it.

  *Read as a **Letterboxd** export* — the tile they pressed on screen 140, not
  the file name, which is what the first version of this read and made the line
  say *Read as a watched.csv export*.

  A file arriving by some other door names none, and the line then says what it
  can: the file itself.

  Screen 140's tiles carry their ids as ATOMS — `%{id: :goodreads, ...}` — and
  this read strings only, so every tile in the picker landed on the last
  clause and every real import was headed *CSV*. Both are answered now, at the
  door, because a source is a source whichever module spelled it.

      iex> Kati.Screens.ImportRecognised.source_name("myanimelist")
      "MyAnimeList"

      iex> Kati.Screens.ImportRecognised.source_name(:letterboxd)
      "Letterboxd"

      iex> Kati.Screens.ImportRecognised.source_name(nil)
      "CSV"
  """
  @spec source_name(String.t() | atom()) :: String.t()
  def source_name(id) when is_atom(id) and not is_nil(id),
    do: Kati.Screens.ImportRecognised.source_name(Atom.to_string(id))

  def source_name("letterboxd"), do: "Letterboxd"
  def source_name("trakt"), do: "Trakt"
  def source_name("myanimelist"), do: "MyAnimeList"
  def source_name("anilist"), do: "AniList"
  def source_name("goodreads"), do: "Goodreads"
  def source_name("storygraph"), do: "StoryGraph"
  def source_name(_none), do: "CSV"

  @doc false
  def content(%{job: %{refusal: _reason}} = assigns),
    do: Kati.Screens.ImportRecognised.refused(assigns.job)

  def content(assigns) do
    job = assigns.job

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {Kati.Screens.ImportRecognised.header(job)}
        {Kati.Screens.Import.result_notice(Map.get(assigns, :result))}
        {Kati.Screens.ImportRecognised.title(job)}
        {Kati.Screens.ImportRecognised.mismatch_band(job)}
        {Kati.Screens.ImportRecognised.steps(job)}
        {Kati.Screens.ImportRecognised.file_card(job)}
        {Kati.Screens.ImportRecognised.matched_note(job)}
        {UI.SettingsList.eyebrow_muted("Mapping — collapsed")}
        {Kati.Screens.ImportRecognised.mapping_collapsed(job)}
        {UI.eyebrow("Mapping — expanded")}
        {Kati.Screens.ImportRecognised.mapping_expanded(job)}
        {UI.SettingsList.eyebrow_muted("What will happen")}
        {Kati.Screens.ImportRecognised.outcome(job)}
      </Column>
    </Scroll>
    """
  end

  # Same 44pt reservation Import.header/1 draws for the same reason: the
  # pushed macro floats the back pill over this row, so the row only owns the
  # ink pill on the right.
  @doc """
  The ink `Import 412` pill, and the commit behind it.

  MOVIES-AND-TV.md #89: this is the commit action of the whole import flow and
  it carried no tap on either screen that draws it. Screen 37's was wired with
  #101; this one was not, and hand-drawing the pill here rather than calling
  the shared builder is how it was missed — an audit caught it.

  So it is `Kati.UI.ImportChrome.header/2` now, the same pill 37, 120 and 142
  draw, and pressing it commits the file this page is describing without
  making the reader walk through the mapping table first. The mapping is still
  one row down for anybody who wants to check it; this is the *I know what this
  file is* path.

  No tap over the board, for 37's reason: committing the drawing would file
  four hundred invented titles under the reader's own shelf.
  """
  @spec header(map()) :: map()
  def header(job) do
    Kati.UI.ImportChrome.header(
      job.action,
      if(Kati.Screens.ImportRecognised.live?(job), do: {self(), :commit})
    )
  end

  @doc """
  Whether this page is describing a real file or the board.

      iex> Kati.Screens.ImportRecognised.live?(Kati.Import.Sample.recognised())
      false
  """
  @spec live?(map()) :: boolean()
  def live?(job), do: is_map(Map.get(job, :job))

  @doc false
  def title(job) do
    ~MOB"""
    <Column fill_width={true}>
      <Text
        text={job.source}
        text_size={28}
        max_font_scale={1.6}
        font_weight="bold"
        letter_spacing={-0.03}
        text_color={:on_surface}
      />
      <Spacer size={6} />
      <Text
        text={job.step_label}
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
  The five-bar meter, three filled — `job.progress`'s own booleans, drawn
  literally rather than derived from a step/steps pair.

  It is worth saying plainly: the board draws this at three of five while
  `job.step_label` reads `STEP 1 OF 4`, and the two numbers do not agree with
  each other. That is the drawing's own inconsistency, not a transcription
  slip made building this screen — both are reproduced exactly as drawn
  rather than one being quietly changed to match the other.
  """
  def steps(job) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        {job.progress
         |> Enum.map(fn done? -> Kati.Screens.ImportRecognised.step_bar(done?) end)
         |> Enum.intersperse(Kati.Screens.ImportRecognised.step_gap())}
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc false
  def step_gap, do: ~MOB"<Spacer size={5} />"

  @doc false
  def step_bar(done?) do
    color = if done?, do: Palette.ink(), else: Palette.track_off()

    ~MOB"<Box weight={1.0} height={4} corner_radius={2} background={color} />"
  end

  @doc """
  The file card, extended with the source guess and its correction.

  Radius 22 and 17pt padding, not screen 37's 20/15 — a different card the
  board draws at its own numbers, not the same recipe copied wrong. The
  hairline and the `Read as a … export` row beneath it are this board's own
  addition: nothing screen 37 draws has a guess to correct.
  """
  def file_card(job) do
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
          {Kati.Screens.ImportRecognised.file_tile()}
          <Spacer size={13} />
          <Column weight={1.0}>
            <Text
              text={job.file}
              text_size={13.5}
              font_weight="bold"
              text_color={:on_surface}
              max_lines={1}
            />
            <Spacer size={4} />
            <Text
              text={job.shape}
              font_family="mono"
              text_size={10.5}
              text_color={Palette.muted()}
              max_lines={1}
            />
          </Column>
          <Spacer size={13} />
          {UI.symbol(Kati.Screens.ImportRecognised.shape_tone(Kati.Screens.ImportRecognised.shape(job)), size: 20, color: Kati.Screens.ImportRecognised.shape_colour(Kati.Screens.ImportRecognised.shape(job)), fill: true)}
        </Row>
        <Spacer size={14} />
        {MishkaSeparator.separator(color: Palette.hairline(), thickness: 1, render: :box)}
        <Spacer size={13} />
        {Kati.Screens.ImportRecognised.recognition(job)}
      </Column>
      <Spacer size={11} />
    </Column>
    """
  end

  @doc "The 38x38 paper tile the file card leads with — same recipe as screen 37's `file_tile/0`."
  def file_tile do
    MishkaThemeIcon.theme_icon(
      %{variant: :filled, color: Palette.paper(), size: 38, radius: 11},
      [UI.symbol("description", size: 20, color: Palette.ink_soft())]
    )
  end

  @doc """
  The recognition sentence, in whichever of its six shapes this file is in.

  Board **329**. One shape was drawn and six were written, and it is the
  sentence a reader trusts to know what they are about to import — so the board
  puts all six on one artboard in 262's four-panel idiom: *"same card, same
  glyph tile, same mono sub-line throughout — only the facts change."*

  Three tones carry the difference, and nothing else does:

    * **green** `check_circle` — recognised, and its possessive variant, used
      *"when the file name carries an account: ownership stated, not assumed."*
    * **bronze** `help` — *said* and *partial*. Said is Kati QUOTING the file's
      own header rather than vouching for it; partial is the right source and an
      old export.
    * **red** `error` — mismatch, which names what it found and imports nothing,
      and refused, which *"is not a source question at all — the file is
      broken."*

      iex> Kati.Screens.ImportRecognised.shape(%{source: "Goodreads", matched: 7, columns_count: 9})
      :recognised

      iex> Kati.Screens.ImportRecognised.shape(%{source: "Goodreads", refusal: :truncated})
      :refused

      iex> Kati.Screens.ImportRecognised.shape(%{source: "Goodreads", mismatch: {"Letterboxd", false}})
      :mismatch
  """
  @spec shape(map()) :: :refused | :mismatch | :partial | :said | :possessive | :recognised
  def shape(job) do
    cond do
      Map.get(job, :refusal) -> :refused
      Map.get(job, :mismatch) -> :mismatch
      Map.get(job, :missing_column) -> :partial
      Map.get(job, :claimed_by_header?) -> :said
      Map.get(job, :yours?) -> :possessive
      true -> :recognised
    end
  end

  @doc """
  The tone a shape carries — the only thing that differs between the six.

      iex> Kati.Screens.ImportRecognised.shape_tone(:possessive)
      "check_circle"

      iex> Kati.Screens.ImportRecognised.shape_tone(:partial)
      "help"

      iex> Kati.Screens.ImportRecognised.shape_tone(:mismatch)
      "error"
  """
  @spec shape_tone(atom()) :: String.t()
  def shape_tone(shape) when shape in [:recognised, :possessive], do: "check_circle"
  def shape_tone(shape) when shape in [:said, :partial], do: "help"
  def shape_tone(_red), do: "error"

  @doc """
  What each shape says, as `{headline, mono sub-line}`.

      iex> Kati.Screens.ImportRecognised.words(%{source: "Goodreads", matched: 7, columns_count: 9})
      {"Read as a Goodreads export", "7 of 9 columns matched"}

      iex> Kati.Screens.ImportRecognised.words(%{source: "Goodreads", yours?: true, rows: 418, columns_count: 9})
      {"Read as your Goodreads export", "418 rows · 9 columns"}
  """
  @spec words(map()) :: {String.t(), String.t()}
  def words(job) do
    source = Map.get(job, :source) || "file"

    case Kati.Screens.ImportRecognised.shape(job) do
      :refused ->
        {"Kati can’t read this file", Map.get(job, :refusal_detail) || "It ends part-way"}

      :mismatch ->
        {looks_like, _kind?} = Map.get(job, :mismatch)

        {"You picked #{source} — this looks like #{looks_like}",
         Map.get(job, :found_columns) || "Its columns are somebody else’s"}

      :partial ->
        {"A #{source} export, from before #{Map.get(job, :export_era) || "2019"}",
         "No #{Map.get(job, :missing_column)} column — everything else maps"}

      :said ->
        {"The file says #{source}", "Header row claims it — columns agree"}

      :possessive ->
        {"Read as your #{source} export",
         "#{Map.get(job, :rows) || 0} rows · #{Map.get(job, :columns_count) || 0} columns"}

      :recognised ->
        {"Read as a #{source} export",
         "#{Map.get(job, :matched) || 0} of #{Map.get(job, :columns_count) || 0} columns matched"}
    end
  end

  @doc """
  Whether *Not <source>? Change* rides on this shape.

  329: *"Change rides on the first three, because only those made a guess."* A
  refusal made none — the file is broken — and a mismatch has already named what
  it found, so offering to change the guess is offering to re-make one it just
  withdrew.

      iex> Kati.Screens.ImportRecognised.guessed?(:said)
      true

      iex> Kati.Screens.ImportRecognised.guessed?(:refused)
      false
  """
  @spec guessed?(atom()) :: boolean()
  def guessed?(shape), do: shape in [:recognised, :possessive, :said]

  @doc """
  Board 329's card: the headline, the mono sub-line, and *Change* where a guess
  was made.

  The glyph tile and the sub-line never move; only the facts and the tone do,
  which is the whole of 329's claim about this sentence.
  """
  @spec recognition(map()) :: map()
  def recognition(job) do
    shape = Kati.Screens.ImportRecognised.shape(job)
    {headline, sub} = Kati.Screens.ImportRecognised.words(job)

    assigns = %{
      headline: headline,
      sub: sub,
      pill:
        if(Kati.Screens.ImportRecognised.guessed?(shape),
          do: Kati.Screens.ImportRecognised.change_pill(Map.get(job, :source) || "this"),
          else: nil
        )
    }

    ~MOB"""
    <Row fill_width={true} align="center">
      <Column weight={1.0}>
        <Text
          text={@headline}
          text_size={12.5}
          text_color={Kati.Theme.Palette.ink_soft()}
          max_lines={2}
          line_height={1.4}
        />
        <Spacer size={4} />
        <Text
          text={@sub}
          font_family="mono"
          text_size={10.5}
          text_color={Kati.Theme.Palette.muted()}
          max_lines={1}
        />
      </Column>
      <Spacer size={11} />
      {@pill}
    </Row>
    """
  end

  @doc """
  Green, bronze or red — 329's three tones and nothing else.

      iex> Kati.Screens.ImportRecognised.shape_colour(:recognised) == Kati.Theme.Palette.green()
      true
  """
  @spec shape_colour(atom()) :: non_neg_integer()
  def shape_colour(shape) when shape in [:recognised, :possessive], do: Palette.green()
  def shape_colour(shape) when shape in [:said, :partial], do: Palette.gold_icon()
  def shape_colour(_red), do: Palette.red()

  @doc """
  `Read as a **Goodreads** export`, one bold run inside a running line.

  `Kati.UI.rich_text/1`: the bridge has no per-run styling, so the whole line
  takes one style — the regular run's, marked `base: true` because at this
  length editing the source name could otherwise flip which run is longest.
  """
  def source_line(source) do
    base = [text_size: 12.5, text_color: Palette.ink_soft()]

    UI.rich_text([
      {"Read as a ", [base: true] ++ base},
      {source, [font_weight: "semibold", text_color: :on_surface]},
      {" export", base}
    ])
  end

  @doc "The `Not <source>? Change` pill — screen `account.ex`'s `pill/1` recipe, with a real tap."
  def change_pill(source) do
    MishkaPill.pill(
      label: "Not #{source}? Change",
      background: Palette.paper(),
      color: :on_surface,
      corner_radius: 15,
      height: 30,
      padding: 0,
      padding_left: 12,
      padding_right: 12,
      text_size: 11.5,
      font_weight: :semibold,
      align: :center,
      max_lines: 1,
      on_tap: :change_source
    )
  end

  @doc """
  The `auto_awesome` note, cream card, one wrapping paragraph.

  `Kati.UI.rich_text/1` again, for the same reason `source_line/1` uses it: the
  bridge has no per-run styling, so a paragraph that must wrap is one `Text`.
  That is exactly why the `5★` in it is the character rather than a spliced
  glyph — see "The star the font turned out to have" in this module's doc.
  """
  def matched_note(job) do
    ~MOB"""
    <Column fill_width={true}>
      <Column fill_width={true} background={Palette.cream()} corner_radius={20} padding={16}>
        <Row fill_width={true} align="top">
          {UI.symbol("auto_awesome", size: 18, color: Palette.gold_icon())}
          <Spacer size={11} />
          <Column weight={1.0}>
            {Kati.Screens.ImportRecognised.note(job)}
          </Column>
        </Row>
      </Column>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  What Kati made of the file, counted rather than stated.

  The board's own sentence — *Kati matched 7 of 9 columns … Two columns are
  skipped* — was a literal, and over a real export it contradicted the counts
  in the card directly above it. Every number in it is now the file's own, and
  the clause about skipped columns is dropped when nothing was skipped: a
  sentence ending *Two columns are skipped* over a file where none were is the
  same defect one clause smaller.
  """
  @spec note(map()) :: map()
  def note(job) do
    body = [text_size: 12.5, line_height: 1.65, text_color: Palette.cream_body()]

    UI.rich_text(
      [
        {"Kati matched ", [base: true] ++ body},
        {"#{job.matched} of #{job.total_columns} columns", :semibold},
        {" and set the conversions: ", body},
        {Kati.Screens.ImportRecognised.scale_line(job), :semibold},
        {", and dates read as ", body},
        {Kati.Screens.ImportRecognised.date_line(job), :semibold},
        {".", body}
      ] ++ Kati.Screens.ImportRecognised.skipped_clause(job.skipped, body)
    )
  end

  @doc """
  Which way the rating column is being converted, or that none is.

  The board says `10pt → 5★` because the file it was captured from wrote ten
  points. `Kati.Import.Mapping.scale_of/2` reads the column, so this says what
  is actually happening to this file — and `no rating column` when there is
  nothing to convert, which is a true sentence where the drawing's would be a
  claim about a column the file does not have.
  """
  @spec scale_line(map()) :: String.t()
  def scale_line(job) do
    # `Map.get` with a default: board 141's own columns carry no `:sample` —
    # they are a mapping table, not a preview — and the drawing must keep its
    # sentence.
    case Kati.Screens.ImportRecognised.sample_for(job, "Rating") do
      nil -> "no rating column"
      "" -> "10pt → 5★"
      sample -> if String.contains?(sample, "."), do: "5★ → 10pt", else: "10pt → 5★"
    end
  end

  @doc false
  @spec sample_for(map(), String.t()) :: String.t() | nil
  def sample_for(job, field) do
    case Enum.find(job.columns, &(&1.field == field)) do
      nil -> nil
      column -> Map.get(column, :sample, "")
    end
  end

  @doc """
  The date format the file is being read in, from its own first row.

  `YYYY/MM/DD` on the board. Every shape `Kati.Import.Mapping.date/1` accepts
  is named here by what it looks like rather than by a parser flag, because
  this line is read by somebody checking that Kati understood their file.
  """
  @spec date_line(map()) :: String.t()
  def date_line(job) do
    case Kati.Screens.ImportRecognised.sample_for(job, "Watched on") do
      nil ->
        "no date column"

      sample ->
        cond do
          # `Regex.compile!` and not `~r{}`: the braces of a `{4}` quantifier
          # close the sigil. `Kati.QuickAdd.Parse` hit the same thing.
          String.match?(sample, Regex.compile!("^\\d\\d\\d\\d-")) -> "YYYY-MM-DD"
          String.match?(sample, Regex.compile!("^\\d\\d\\d\\d/")) -> "YYYY/MM/DD"
          String.match?(sample, Regex.compile!("^\\d\\d?/")) -> "DD/MM/YYYY"
          # The board's own, for the board's own columns: 141 draws a mapping
          # table with no sampled values, and its sentence says YYYY/MM/DD.
          sample == "" -> "YYYY/MM/DD"
          true -> "as written"
        end
    end
  end

  @doc false
  def skipped_clause(0, _body), do: []

  def skipped_clause(1, body), do: [{" One column is skipped.", body}]

  def skipped_clause(n, body), do: [{" #{n} columns are skipped.", body}]

  @doc """
  The mapping at rest: one row, the counts, and the chevron that opens it.

  `rule: false` because it is the only row in its card — the hairline in
  `Kati.UI.SettingsList.row/4` separates a row from the next one, and there is
  no next one. The sub-line is built from `job.matched` and `job.skipped`
  rather than written out, so the board's `7 matched · 2 skipped` and the nine
  rows `mapping_expanded/1` draws cannot disagree with each other.
  """
  def mapping_collapsed(job) do
    summary_row =
      SettingsList.row(
        SettingsList.icon_tile("checklist"),
        SettingsList.body(
          "Check the mapping",
          "#{job.matched} matched · #{job.skipped} skipped · still editable"
        ),
        SettingsList.chevron(),
        rule: false,
        on_tap: {self(), :check_mapping}
      )

    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.card([summary_row])}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  The mapping opened: every column in the file against the field it will write.

  The board draws no summary row above this frame and none is added — the two
  frames are the same control at rest and open, and a header repeated in both
  would read as two cards rather than two states of one. `rule?` is false on
  the last row for `mapping_collapsed/1`'s reason.
  """
  def mapping_expanded(job) do
    last = length(job.columns) - 1

    table_rows =
      job.columns
      |> Enum.with_index()
      |> Enum.map(fn {row, i} -> Kati.Screens.ImportRecognised.map_row(row, i < last) end)

    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.card(table_rows)}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def map_row(row, rule?) do
    field_color = if row.skipped?, do: Palette.tertiary(), else: Palette.ink()

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_top={11} padding_bottom={11}>
        <Column weight={1.0}>
          <Text
            text={row.column}
            font_family="mono"
            text_size={11}
            text_color={:on_surface}
            max_lines={1}
          />
          {Kati.Screens.ImportRecognised.map_note(row.note)}
        </Column>
        <Spacer size={11} />
        {UI.symbol(row.icon, size: 15, color: Palette.rail_idle())}
        <Spacer size={11} />
        <Column width={96}>
          <Text
            text={row.field}
            text_size={12.5}
            font_weight="semibold"
            text_color={field_color}
            text_align="right"
            max_lines={1}
          />
        </Column>
      </Row>
      {Kati.Screens.ImportRecognised.hairline(rule?)}
    </Column>
    """
  end

  @doc false
  def map_note(nil), do: ~MOB"<Spacer size={0} />"

  def map_note(note) do
    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={4} />
      {Kati.Screens.ImportRecognised.note_line(note)}
    </Column>
    """
  end

  @doc """
  A mapping row's own note — `converts 10pt → 5★`, `to-read → Wishlist`,
  `skipped` — at `Palette.eyebrow/0`, the drawing's `#A0998F` and not
  screen 37's `tertiary`.

  One `Text`, star and all. See "The star the font turned out to have" in this
  module's doc for why this does not split at the ★ the way screen 37's
  `star_text/3` does.
  """
  def note_line(text) do
    ~MOB"<Text text={text} text_size={10} text_color={Palette.eyebrow()} max_lines={1} />"
  end

  @doc """
  The `rgba(26,25,23,.07)` rule between two mapping rows — `render: :box`
  for the reason screen 37's own `hairline/1` gives in full: the default
  `:divider` primitive antialiases a 1dp rule unevenly at this device's pixel
  ratio, and `render: :box` draws a filled rect instead, every row at the
  drawing's flat 7% ink.
  """
  def hairline(false), do: ~MOB"<Spacer size={0} />"

  def hairline(true),
    do: MishkaSeparator.separator(color: Palette.hairline(), thickness: 1, render: :box)

  @doc """
  The three outcome cards — `job.outcome`, reused whole from
  `Kati.Import.Sample.outcome/0`, at this board's own type: mono, `medium`
  weight, 22/9.5pt, not screen 37's sans `extrabold` at 22/10.
  """
  def outcome(job) do
    ~MOB"""
    <Row fill_width={true} align="top">
      {job.outcome
       |> Enum.map(fn card -> Kati.Screens.ImportRecognised.outcome_card(card) end)
       |> Enum.intersperse(Kati.Screens.ImportRecognised.outcome_gap())}
    </Row>
    """
  end

  @doc false
  def outcome_gap, do: ~MOB"<Spacer size={10} />"

  @doc false
  def outcome_card(card) do
    ~MOB"""
    <Box weight={1.0}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={18}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={14}
      >
        <Text
          text={card.value}
          font_family="mono"
          text_size={22}
          font_weight="medium"
          letter_spacing={-0.03}
          text_color={card.color}
          text_align="center"
        />
        <Spacer size={5} />
        <Text
          text={String.upcase(card.label)}
          font_family="mono"
          text_size={9.5}
          letter_spacing={0.1}
          text_color={Palette.muted()}
          text_align="center"
          max_lines={1}
        />
      </Column>
    </Box>
    """
  end

  @doc """
  Which file this screen is about, for the screen its chevron opens.

  MOVIES-AND-TV.md #53: the row promised *the nine columns it just counted*
  and pushed screen 37 bare, which drew five columns of `trakt-backup.csv` —
  a different file, one tap later, contradicting every number on the page it
  was opened from.

  An atom rather than the job, because the push names WHICH file and the
  sample module answers with it. `Kati.Import.Sample.job/1` is where the two
  jobs live and the only place either is described.

      iex> Kati.Screens.ImportRecognised.source()
      :goodreads
  """
  @spec source() :: atom()
  def source, do: :goodreads

  @doc false
  @impl true
  def handle_tap(:check_mapping, socket) do
    {path, name} = Map.get(socket.assigns, :file, {nil, nil})

    {:noreply,
     Mob.Socket.push_screen(socket, Kati.Screens.Import, %{
       # The same file, not the same fixture. 141 and 37 drew two jobs and
       # contradicted each other about one export (#53); they are now two views
       # of one `Kati.Import.Job`, and the path is what carries it across.
       path: path,
       name: name,
       source: Kati.Screens.ImportRecognised.source(),
       back: "Recognised"
     })}
  end

  @doc """
  Commit from here, or hand the reader to 37 when there is something to answer.

  MOVIES-AND-TV.md #89. A file that disagrees with nothing on your shelf needs
  no mapping table read and no questions answered — this page has already said
  what it found, and one press is the whole of what a reader wants. A file that
  DOES conflict is the other case: `Kati.Import.Commit.run/2` reads silence as
  *keep mine*, which is the safe reading but not one to make on somebody's
  behalf without showing them, so the pill opens 37 where the queue can be
  answered.

  Neither branch commits the board: `live?/1` is what keeps the drawing's
  `Import 412` a picture.
  """
  def handle_tap(:commit, socket) do
    job = socket.assigns.job

    cond do
      not Kati.Screens.ImportRecognised.live?(job) ->
        {:noreply, socket}

      job.job.plan.conflicts != [] ->
        {path, name} = Map.get(socket.assigns, :file, {nil, nil})

        {:noreply,
         Mob.Socket.push_screen(socket, Kati.Screens.Import, %{
           path: path,
           name: name,
           source: Kati.Screens.ImportRecognised.source(),
           back: "Recognised"
         })}

      true ->
        {:ok, tally} = Kati.Import.Commit.run(job.job, %{})

        {:noreply, Mob.Socket.assign(socket, :result, Kati.Screens.Import.result_line(tally))}
    end
  end

  def handle_tap(:change_source, socket) do
    {:noreply, Kati.Screens.Resume.pop(socket)}
  end
end
