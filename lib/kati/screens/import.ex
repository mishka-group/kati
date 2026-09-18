defmodule Kati.Screens.Import do
  @moduledoc """
  Screen 37 — Import, pushed under Settings.

  Built to `test/design/screens/37.html`. The drawing's argument is that
  nothing is written until the person has seen what will happen: the file is
  acknowledged, every column is shown mapped to a field with a real value
  beside it, the write is summarised as three counts, and each conflict is
  answered on its own.

  Two details the drawing is specific about and which are easy to lose:

    * the dropped column is `block` + grey `Skip` + the word "skipped", so the
      fact that it will be ignored is said three ways and never by colour
      alone;
    * the conflict card sits on cream, the same warming the note gets on
      screen 08 — it marks the one place the screen is asking rather than
      telling.

  The stars in "converts 10pt → 5★" and "Yours ★4 · file says ★5" are drawn
  as text in the export, but Plus Jakarta Sans carries no U+2605 — screen 08
  proved that renders as nothing at all. So `star_text/3` keeps the design's
  literal string as the data and splits it at the star, rendering the Material
  Symbols `star` glyph in its place at the surrounding text's size and colour.

  No dock, so the frame's bottom inset is 40 rather than 132.

  ## Why this screen is still on `Kati.Import.Sample`

  There is no reader and no job. `lib/kati/import` holds that one sample module
  and nothing else, and no Ash resource models a file, a column mapping, an
  outcome count or a conflict queue. The screen is drawn *mid-job* — step 3 of
  4, five columns matched, one of six conflicts open — which is a state that
  has to be held between two renders, and there is nowhere to hold it: the
  answer to a conflict would be forgotten the moment the screen popped.

  `Kati.Backup.inspect_file/1` is the nearest existing thing and worth naming,
  because it already makes this screen's promise — it opens a file and reports
  what a restore would write *without writing it*, so a screen can never offer
  numbers the write would then refuse. It answers about Kati's own archives
  rather than a third party's CSV, so it is the shape to copy when the reader
  lands, not a call this screen can make today.

  ## Audited

  **Drawn copy with no stored state: every string is `Kati.Import.Sample` and
  no resource in the app holds an import job**, which the section above sets
  out in full.

  The controls are not pictures any more, which is the half of
  MOVIES-AND-TV.md #101 that could be answered without that resource. The
  three conflict choices carry `answer_` and `all_` tags and `answer/3` closes
  the card; the commit pill carries `:commit`. Each is live only when the job
  behind it is — `live?/1` — so the drawn frame still taps nothing, because
  there is nothing on it to answer about.

  What is still missing is the resource, and it is named above: a job holding
  the file, its column mapping, the counted outcome and a conflict queue, so
  that step 3 of 4 survives the screen popping.

  ## What stays Latin when this page folds to Persian

  mishka-group/kati#103, and the list is `Kati.Screens.ImportRecognised`'s own
  — the two screens draw the same job and owe it the same treatment:

    * **The file's own name, its own headers and the values sampled out of it.**
      `trakt-backup.csv`, the column names down the left of the mapping card
      and the first row's value under each are what the READER's file says, not
      what Kati says. A msgid over any of them would translate somebody's
      spreadsheet.
    * **Everything `Kati.Import.Job` and `Kati.Import.Sample` write.** The
      `Import 412` pill, `418 ROWS · 9 COLUMNS`, the `· step 3 of 4` subtitle,
      the three outcome labels, the field name on the right of each arrow, the
      conflict's own line and its `1 of 6 · apply to all` are those modules'
      strings and fold there, not here. What this screen owes them is a
      TYPEFACE and a CASE — `Kati.Locale.mono_face/1` asks each string what
      script it is in rather than asking the reader, because DM Mono carries no
      Persian glyph and half of them will never be Persian, and
      `Kati.UI.eyebrow_label/1` upcases on one side of the fold only.

  The third thing that is neither copy nor typeface is the arrow in the middle
  of a mapping row: `map_glyph/1` answers it, and its own doc carries the
  argument for why a mirrored row does not mirror the picture inside it.
  """
  use Kati.Screens.Pushed, back: "Settings"
  use Gettext, backend: Kati.Gettext

  alias Kati.Components.MishkaSeparator
  alias Kati.Theme.Palette
  alias Kati.UI

  # The file the caller named, and the board's own when nobody named one.
  #
  # Screen 141 reads a Goodreads export and its *Check the mapping* row used
  # to push this screen bare — so a reader who had just been told about nine
  # columns of `goodreads_library_export.csv` arrived at five columns of
  # `trakt-backup.csv`, and every number on the page they had just left was
  # contradicted by the page it opened (MOVIES-AND-TV.md #53). One chevron
  # apart, the same way screens 04 and 34 drew two different Season 2s (#40).
  #
  # A SOURCE, not the job itself: the push names which file, and
  # `Kati.Import.Sample` answers with it. That is the app's own convention —
  # `Kati.ScreenParamsSweepTest` is about screens reading an id out of their
  # params — and it is what a real import would pass too, once there is a job
  # resource to have an id.
  @impl true
  def load(socket) do
    params = socket.assigns.params || %{}

    socket
    |> Mob.Socket.assign(:job, Kati.Screens.Import.job_for(params))
    |> Mob.Socket.assign(:answers, %{})
    |> Mob.Socket.assign(:at, 0)
    |> Mob.Socket.assign(:result, nil)
  end

  @doc """
  The job this screen draws: the file it was handed, or the drawing's.

  A push carrying `:path` and `:name` is a file the reader actually picked, and
  `Kati.Import.Job.read/2` is what makes it a job — the rows, the columns
  mapped by their headers, and the plan counted against the shelf as it stands.

  A push carrying neither is the gallery, a sweep, or screen 140's *Something
  else*, and gets `empty_job/0`. It used to get `Kati.Import.Sample`, and that
  was a lie on a routed path rather than only in the gallery: *Something else*
  is a row a reader taps having picked no file at all, and what opened was a
  mapping table for `trakt-backup.csv` — five columns of somebody else's film
  export, under a plan promising 384 new records, 28 merged and 6 conflicts.
  `live?/1` kept the commit pill inert, so the numbers could not be acted on;
  they were still the only thing on the page.

  A file that could not be read gets the same empty job, carrying why on
  `:refusal` so the screen can say it — the refusal is the page's subject and
  the drawing's four hundred records were never part of the answer.
  """
  @spec job_for(map()) :: map()
  def job_for(params) do
    path = Map.get(params, :path)
    name = Map.get(params, :name)

    with true <- is_binary(path) and is_binary(name),
         {:ok, job} <- Kati.Import.Job.read(path, name) do
      job
    else
      {:error, reason} -> Map.put(empty_job(), :refusal, reason)
      _no_file -> empty_job()
    end
  end

  @doc """
  The wizard with no file behind it: its frame, its step meter, and nothing in
  any slot.

  Step **1** of four rather than the drawing's 3, because picking the file is
  the first step and it has not happened. No columns, no plan and no conflict,
  so `mapping/1`'s card draws one worded line and `outcome/1` and
  `conflicts_band/1` draw nothing at all.
  """
  @spec empty_job() :: map()
  def empty_job do
    %{
      action: pill_label(0),
      file: gettext("No file chosen"),
      subtitle:
        gettext("No file chosen · step %{step} of %{steps}",
          step: Kati.Locale.number(1),
          steps: Kati.Locale.number(4)
        ),
      shape:
        Kati.UI.eyebrow_label(
          gettext("%{rows} rows · %{columns} columns",
            rows: Kati.Locale.number(0),
            columns: Kati.Locale.number(0)
          )
        ),
      steps: 4,
      step: 1,
      columns: [],
      outcome: [],
      conflict: nil
    }
  end

  defp pill_label(count) do
    pgettext("the import action pill, with its record count", "Import %{n}",
      n: Kati.Locale.number(count)
    )
  end

  @doc """
  Whether this job can be committed: it came from a file, not from the board.

      iex> Kati.Screens.Import.live?(Kati.Import.Sample.job())
      false
  """
  @spec live?(map()) :: boolean()
  def live?(job), do: is_map(Map.get(job, :plan))

  @impl true
  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "answer_" <> answer ->
        {:noreply, Kati.Screens.Import.answer(socket, answer, :one)}

      "all_" <> answer ->
        {:noreply, Kati.Screens.Import.answer(socket, answer, :all)}

      "commit" ->
        {:noreply, Kati.Screens.Import.commit(socket)}

      _other ->
        {:noreply, socket}
    end
  end

  @doc """
  Answer the open conflict, for it alone or for the whole queue.

  Answering advances to the next one, which is what makes a queue of six a
  thing you get through rather than a thing you keep re-reading. *Apply to all*
  answers every conflict still unanswered and closes the card.
  """
  @spec answer(Mob.Socket.t(), String.t(), :one | :all) :: Mob.Socket.t()
  def answer(socket, label, scope) do
    job = socket.assigns.job

    with true <- Kati.Screens.Import.live?(job),
         choice when not is_nil(choice) <- Kati.Screens.Import.choice_atom(label),
         %{} = card <- job.conflict do
      answers =
        case scope do
          :one -> Map.put(socket.assigns.answers, card.watch_id, choice)
          :all -> Map.new(job.conflicts, &{&1.watch_id, choice})
        end

      at = if scope == :all, do: length(job.conflicts), else: card.index + 1

      socket
      |> Mob.Socket.assign(:answers, answers)
      |> Mob.Socket.assign(:at, at)
      |> Kati.Screens.Import.redraw_card()
    else
      _drawn -> socket
    end
  end

  @doc false
  def redraw_card(socket) do
    job = socket.assigns.job
    at = socket.assigns.at

    answered =
      job.conflicts |> Enum.at(at) |> then(&(&1 && Map.get(socket.assigns.answers, &1.watch_id)))

    Mob.Socket.assign(
      socket,
      :job,
      %{job | conflict: Kati.Import.Job.conflict_card(job.conflicts, at, answered)}
    )
  end

  @doc false
  @spec choice_atom(String.t()) :: atom() | nil
  def choice_atom("keep_mine"), do: :keep_mine
  def choice_atom("take_file"), do: :take_file
  def choice_atom("keep_both"), do: :keep_both
  def choice_atom(_other), do: nil

  @doc """
  Write the import, and say what it did.

  Refuses on the drawing, which is `Kati.Write`'s own `:nothing_to_save`: the
  board's `Import 412` describes a file nobody picked, and committing it would
  file four hundred invented films under the reader's own shelf.
  """
  @spec commit(Mob.Socket.t()) :: Mob.Socket.t()
  def commit(socket) do
    job = socket.assigns.job

    if Kati.Screens.Import.live?(job) do
      {:ok, tally} = Kati.Import.Commit.run(job, socket.assigns.answers)

      Mob.Socket.assign(socket, :result, Kati.Screens.Import.result_line(tally))
    else
      Mob.Socket.assign(socket, :result, Kati.Write.message({:error, :nothing_to_save}))
    end
  end

  @doc """
  What a finished import says.

      iex> Kati.Screens.Import.result_line(%{new: 384, merged: 28, resolved: 6, failed: 0})
      "384 added · 28 merged · 6 conflicts settled."

      iex> Kati.Screens.Import.result_line(%{new: 3, merged: 0, resolved: 0, failed: 2})
      "3 added. 2 rows could not be written."
  """
  @spec result_line(map()) :: String.t()
  def result_line(tally) do
    # A NUMBER AND ITS WORD ARE ONE MSGID, NOT A TABLE OF WORDS.
    #
    # This was `{count, word}` pairs joined by `"#{n} #{word}"`, and that shape
    # cannot be translated at all: a msgid has to be a literal at the call
    # site, so `gettext(word)` does not compile and a catalogue of three bare
    # words would give Persian no say in what order the number and the verb go
    # in. Each clause is its own sentence now, built whether or not it will be
    # shown — three catalogue lookups cost nothing against a write that has
    # just walked the whole file.
    #
    # `pgettext/2` on the two that do not inflect, because `%{n} added` is two
    # tokens and `mix gettext.merge` fuzzy-matches a msgid that short against
    # any sentence that resembles it; the context also keeps `%{n} merged`
    # clear of `Kati.Screens.Restore`'s bare `merged`, which is a fragment of a
    # different sentence and takes a different Persian word-form.
    said =
      [
        {tally.new, pgettext("import result", "%{n} added", n: Kati.Locale.number(tally.new))},
        {tally.merged,
         pgettext("import result", "%{n} merged", n: Kati.Locale.number(tally.merged))},
        # `ngettext/4` rather than a third `pgettext/2`: the English read `1
        # conflicts settled` whenever a single conflict was answered, which is
        # the one count of the three whose noun inflects. Persian does not
        # inflect a noun after a numeral, so its two forms are the same string.
        {tally.resolved,
         ngettext("%{n} conflict settled", "%{n} conflicts settled", tally.resolved,
           n: Kati.Locale.number(tally.resolved)
         )}
      ]
      |> Enum.filter(fn {n, _phrase} -> n > 0 end)
      |> Enum.map_join(" · ", fn {_n, phrase} -> phrase end)

    said = if said == "", do: pgettext("import result", "Nothing to import"), else: said

    case tally.failed do
      0 ->
        said <> "."

      n ->
        said <>
          ". " <>
          ngettext("%{n} row could not be written.", "%{n} rows could not be written.", n,
            n: Kati.Locale.number(n)
          )
    end
  end

  @doc false
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
        {Kati.Screens.Import.header(job)}
        {Kati.Screens.Import.result_notice(Map.get(assigns, :result))}
        {Kati.Screens.Import.title(job)}
        {Kati.Screens.Import.steps(job)}
        {Kati.Screens.Import.file_card(job)}
        {UI.eyebrow(gettext("Match columns"))}
        {Kati.Screens.Import.mapping(job)}
        {Kati.Screens.Import.outcome_eyebrow(job)}
        {Kati.Screens.Import.outcome(job)}
        {Kati.Screens.Import.conflicts_band(job)}
      </Column>
    </Scroll>
    """
  end

  # The 44pt height reserves the row the back pill floats in — the pill itself
  # is drawn by Kati.Screens.Pushed — so the ink action sits opposite it.
  @doc false
  def result_notice(nil), do: ~MOB"<Spacer size={0} />"

  def result_notice(message) do
    assigns = %{notice: Kati.UI.notice(message)}

    ~MOB"""
    <Column fill_width={true}>
      {@notice}
      <Spacer size={14} />
    </Column>
    """
  end

  @doc """
  The ink `Import 412` pill, and the commit behind it.

  MOVIES-AND-TV.md #101: this was the commit action of the whole flow and it
  carried no tap. It carries one now over a real file, and none over the board
  — `Kati.Screens.Import.live?/1` is the difference, and pressing the board's
  would file four hundred invented films under the reader's own shelf.

  The markup is `Kati.UI.ImportChrome.header/2`, which is where it moved when
  this module started reaching the database: three other screens draw the same
  pill and none of them reads anything.
  """
  @spec header(map()) :: map()
  def header(job) do
    Kati.UI.ImportChrome.header(
      job.action,
      if(Kati.Screens.Import.live?(job), do: {self(), :commit})
    )
  end

  # The heading and the mono line under it, and the two ask different
  # questions of the fold.
  #
  # The heading is this screen's own word, so it takes a msgid — and loses its
  # tracking with it. `Kati.Locale.tracking/1`: Vazirmatn is not drawn to be
  # tracked and negative spacing breaks the joins between Persian letters, so
  # the drawing's -0.03em tightens `Import` and does nothing to «درون‌ریزی».
  # `max_lines={1}` for the reason every other display heading in the app
  # carries one — a longer translated word wraps a 28pt line rather than
  # shrinking it.
  #
  # The subtitle is `Kati.Import.Job`'s string — a file name and ` · step 3 of
  # 4` — and that module folds on its own schedule, so the face is asked of the
  # STRING rather than hardcoded. `trakt-backup.csv · step 3 of 4` keeps DM
  # Mono, and the day it reads «trakt-backup.csv · گام ۳ از ۴» it takes
  # Vazirmatn instead of Android's substitute face. Board 141's `title/1` makes
  # the same call for the same job's `step_label`.
  @doc false
  def title(job) do
    ~MOB"""
    <Column fill_width={true}>
      <Text
        text={gettext("Import")}
        text_size={28}
        max_font_scale={1.6}
        font_weight="bold"
        letter_spacing={Kati.Locale.tracking(-0.03)}
        text_color={:on_surface}
        max_lines={1}
      />
      <Spacer size={5} />
      <Text
        text={job.subtitle}
        font_family={Kati.Locale.mono_face(job.subtitle)}
        text_size={11}
        text_color={Palette.muted()}
        max_lines={1}
      />
      <Spacer size={20} />
    </Column>
    """
  end

  @doc false
  def steps(job) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        {1..job.steps
         |> Enum.map(fn i -> Kati.Screens.Import.step_bar(i <= job.step) end)
         |> Enum.intersperse(Kati.Screens.Import.step_gap())}
      </Row>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  defdelegate step_gap(), to: Kati.UI.ImportChrome

  @doc false
  defdelegate step_bar(done?), to: Kati.UI.ImportChrome

  @doc false
  def file_card(job) do
    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Palette.card()}
        corner_radius={20}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={15}
        align="center"
      >
        {Kati.Screens.Import.file_tile()}
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
            font_family={Kati.Locale.mono_face(job.shape)}
            text_size={10.5}
            text_color={Palette.muted()}
            max_lines={1}
          />
        </Column>
        <Spacer size={13} />
        {Kati.Screens.Import.file_tick(job)}
      </Row>
      <Spacer size={22} />
    </Column>
    """
  end

  # The green tick means *this file was read*, so it cannot be drawn beside a
  # file that is not there.
  @doc false
  def file_tick(%{columns: []}), do: ~MOB"<Spacer size={0} />"

  def file_tick(_job),
    do: Kati.UI.symbol("check_circle", size: 20, color: Kati.Theme.green(), fill: true)

  @doc """
  The 38x38 paper tile the file card leads with, from
  `Kati.Components.MishkaThemeIcon` — "a themed container around exactly one
  icon", which is what this is. Larger than the settings rows' 30 and rounded
  to 11 rather than 9, both the drawing's own numbers, both props.

  `variant: :filled` with an explicit `color`, not `variant: :white` — the
  white variant paints the theme's `:surface`, which here is `#FBFAF8`, the
  card the tile sits on.

  The glyph is a child rather than the `icon` prop: that shorthand builds a
  `Text` with no `font_family`, so the ligature `"description"` would be
  typeset as the word rather than resolved to the Material Symbols glyph.

  With children and no `id`, `theme_icon/2` returns
  `%{type: :box, props: %{width: 38, height: 38, align: :center,
  corner_radius: 11, background: Palette.paper()}, children: [glyph]}` — node
  for
  node what the card wrote by hand.
  """
  defdelegate file_tile(), to: Kati.UI.ImportChrome

  @doc false
  def mapping(%{columns: []}) do
    assigns = %{
      line:
        UI.text(
          gettext("Pick a file and its columns will be listed here, one per row."),
          12.5,
          Palette.muted(),
          lines: 2
        )
    }

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={20}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={15}
      >
        {@line}
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  def mapping(job) do
    last = length(job.columns) - 1

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={20}
        shadow={Kati.Theme.shadow_card_soft()}
        padding_left={15}
        padding_right={15}
        padding_top={4}
        padding_bottom={4}
      >
        {job.columns
         |> Enum.with_index()
         |> Enum.map(fn {row, i} -> Kati.Screens.Import.map_row(row, i < last) end)}
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def map_row(row, rule?) do
    field_color = if row.skipped?, do: Palette.tertiary(), else: Palette.ink()

    # See `map_glyph/1`: the row mirrors under `rtl` and the arrow in it does
    # not, so it has to be asked which way forward is.
    icon = Kati.Screens.Import.map_glyph(row.icon)

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_top={13} padding_bottom={13}>
        <Column weight={1.0}>
          <Text
            text={row.column}
            font_family={Kati.Locale.mono_face(row.column)}
            text_size={11}
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={4} />
          <Text text={row.sample} text_size={10.5} text_color={Palette.tertiary()} max_lines={1} />
        </Column>
        <Spacer size={11} />
        {Kati.UI.symbol(icon, size: 15, color: Palette.rail_idle())}
        <Spacer size={11} />
        <Column width={106}>
          <Text
            text={row.field}
            text_size={12.5}
            font_weight="semibold"
            text_color={field_color}
            text_align="right"
            max_lines={1}
          />
          {Kati.Screens.Import.map_note(row)}
        </Column>
      </Row>
      {Kati.Screens.Import.hairline(rule?)}
    </Column>
    """
  end

  @doc """
  The glyph between the file's column and Kati's field, pointing the way the
  reader reads.

  AN ARROW IS A PICTURE, AND `layout_direction` MIRRORS NEITHER PICTURES NOR
  THE FONT THEY COME OUT OF.

  The row itself mirrors under `rtl` — the file's column moves to the right and
  Kati's field to the left — and an `arrow_forward` left alone in the middle of
  it would then be pointing back at the column it came from.
  `Kati.Locale.forward_glyph/0` is the answer `Kati.Screens.OnboardingWelcome`
  takes for the arrow on its primary pill, and the glyph in the middle of this
  row means the same word. `Kati.Screens.ImportRecognised.map_row/2` makes the
  identical mapping over the identical rows.

  Mapped here rather than in `Kati.Import.Mapping.columns/2`, which is where
  the name is written: that module decides whether a column maps at all —
  `arrow_forward` or `block` — and which way an arrow points on a page is this
  screen's question, not the mapper's. Every other glyph the mapping carries
  (`block` from `Kati.Import.Sample`, `close` from the real mapper) is not
  directional and passes through untouched.

      iex> Kati.Locale.as(:en, fn -> Kati.Screens.Import.map_glyph("arrow_forward") end)
      "arrow_forward"

      iex> Kati.Locale.as(:fa, fn -> Kati.Screens.Import.map_glyph("arrow_forward") end)
      "arrow_back"

      iex> Kati.Locale.as(:fa, fn -> Kati.Screens.Import.map_glyph("block") end)
      "block"
  """
  @spec map_glyph(String.t()) :: String.t()
  def map_glyph("arrow_forward"), do: Kati.Locale.forward_glyph()
  def map_glyph(other), do: other

  @doc false
  def map_note(%{note: nil}), do: ~MOB"<Spacer size={0} />"

  def map_note(row) do
    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={3} />
      <Row fill_width={true} align="center">
        <Spacer weight={1.0} />
        {Kati.Screens.Import.star_text(row.note, 10, Palette.eyebrow())}
      </Row>
    </Column>
    """
  end

  @doc """
  A line of text with the design's ★ rendered as the Material Symbols glyph.

  The export writes `&starf;` inline, which is U+2605 — a character the sans
  face does not carry. Keeping the whole string as the data and splitting it
  here means the copy stays the design's own while the glyph comes from the
  font that actually has it.

  **The `Row` is what makes this fold correctly, and it needs nothing added.**
  A sentence broken into three nodes normally breaks under `rtl`, because the
  pieces are then laid out by a container rather than by the bidi algorithm —
  but `K-12 rtl-root` provides `LocalLayoutDirection` at the root, so this
  `Row` reverses its own children and «شما ★۴ · فایل ★۵» comes out in the
  order it is written. The star is a glyph in the Material font, not a letter,
  and needs no mirroring of its own. Nothing here should be given an explicit
  direction: an isolate around the parts would pin them left-to-right and undo
  exactly the thing that is working.
  """
  def star_text(line, size, color) do
    parts = String.split(line, "★")

    ~MOB"""
    <Row align="center">
      {parts
       |> Enum.map(fn part -> Kati.Screens.Import.star_part(part, size, color) end)
       |> Enum.intersperse(Kati.Screens.Import.star_glyph(size, color))}
    </Row>
    """
  end

  @doc false
  def star_part(part, size, color) do
    ~MOB"""
    <Text text={part} text_size={size} text_color={color} max_lines={1} />
    """
  end

  @doc false
  def star_glyph(size, color), do: Kati.UI.symbol("star", size: size, color: color, fill: true)

  # A section heading over nothing, found on the emulator walking *Something
  # else* → screen 37: **WHAT WILL HAPPEN** sat above an empty row.
  #
  # Absent rather than worded, which is the opposite of what board 321 chose for
  # the search page's *Try* group — and the difference is whether the reader can
  # do anything about it. Try fills from a library they are building and a
  # reader who never sees the heading has no idea it will ever fill, so it says
  # so. This section fills the moment a file is picked, and the card directly
  # above it is already the sentence telling them to pick one. Two sentences
  # saying that, one of them under a heading promising a plan, is worse than one.
  @doc false
  def outcome_eyebrow(%{outcome: []}), do: ~MOB"<Spacer size={0} />"

  def outcome_eyebrow(_job), do: UI.eyebrow(gettext("What will happen"))

  @doc false
  def outcome(job) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        {job.outcome
         |> Enum.map(fn card -> Kati.Screens.Import.outcome_card(card) end)
         |> Enum.intersperse(Kati.Screens.Import.outcome_gap())}
      </Row>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  defdelegate outcome_gap(), to: Kati.UI.ImportChrome

  @doc false
  def outcome_card(card) do
    # `String.upcase/1` IS A NO-OP IN PERSIAN THAT READS AS ONE.
    #
    # Arabic script has no case, so upcasing `ادغام` returns `ادغام` — the
    # label arrives at the eyebrow's size and tracking with none of the
    # eyebrow's shouting, beside a Latin page where the same label is `MERGED`.
    # `Kati.UI.eyebrow_label/1` is the app's answer: upcase on one side of the
    # fold, leave alone on the other, and say so once.
    #
    # The label is `Kati.Import.Job.outcome/1`'s string and folds there; what
    # this screen decides is the case and the FACE. `mono_face/1` asks the
    # STRING rather than the reader, because the two paths answer differently:
    # `Kati.Import.Job` has translated its three, so a Persian reader over a
    # real file gets «ادغام» and needs Vazirmatn, while `Kati.Import.Sample`
    # has not, so the board's own `MERGED` is still ASCII and keeps DM Mono.
    # Asking the reader would set that one in a face it did not need.
    #
    # The figure above it takes no face at all and keeps none: board 37 sets
    # its counts in Plus Jakarta `extrabold` where board 141 sets the same
    # three in DM Mono, so the frame's own `font_family` is already the right
    # answer in both scripts and the digits are `Kati.Import.Job.outcome/1`'s
    # to convert. Its tracking still goes, for the reason `title/1` gives.
    label = Kati.UI.eyebrow_label(card.label)

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
          text_size={22}
          font_weight="extrabold"
          letter_spacing={Kati.Locale.tracking(-0.03)}
          text_color={card.color}
          text_align="center"
        />
        <Spacer size={5} />
        <Text
          text={label}
          font_family={Kati.Locale.mono_face(label)}
          text_size={10}
          letter_spacing={Kati.Locale.tracking(0.1)}
          text_color={Palette.muted()}
          text_align="center"
          max_lines={1}
        />
      </Column>
    </Box>
    """
  end

  @doc """
  *Conflicts · keep which?* and the card under it, or nothing at all.

  Nothing at all when the file disagrees with the shelf about nothing, which is
  every import into an empty library and most imports into a full one. The
  eyebrow goes with the card rather than standing over a gap — the rule this
  round keeps everywhere, and here it is also what stops the screen dying:
  `conflict/1` drew `job.conflict` unconditionally and `conflict_poster/1`
  raised a `BadMapError` on `nil`, which took the screen process with it and
  threw the reader back to Home. Found by importing a file that conflicted with
  nothing, which is the ordinary case.
  """
  @spec conflicts_band(map()) :: map()
  def conflicts_band(%{conflict: nil}), do: ~MOB"<Spacer size={0} />"

  def conflicts_band(job) do
    assigns = %{
      eyebrow: UI.eyebrow(gettext("Conflicts · keep which?")),
      card: Kati.Screens.Import.conflict(job)
    }

    ~MOB"""
    <Column fill_width={true}>
      {@eyebrow}
      {@card}
    </Column>
    """
  end

  @doc false
  def conflict(job) do
    c = job.conflict
    live? = Kati.Screens.Import.live?(job)

    ~MOB"""
    <Column fill_width={true} background={Palette.cream()} corner_radius={20} padding={15}>
      <Row fill_width={true} align="center">
        {Kati.Screens.Import.conflict_poster(c)}
        <Spacer size={12} />
        <Column weight={1.0}>
          <Text
            text={c.title}
            text_size={13}
            font_weight="bold"
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={3} />
          {Kati.Screens.Import.star_text(c.line, 11.5, Palette.cream_sub())}
        </Column>
      </Row>
      <Spacer size={12} />
      <Row fill_width={true} align="center">
        {c.choices
         |> Enum.map(fn choice -> Kati.Screens.Import.choice(choice, live?) end)
         |> Enum.intersperse(Kati.Screens.Import.choice_gap())}
      </Row>
      <Spacer size={12} />
      {Kati.Screens.Import.apply_to_all(c, live?)}
    </Column>
    """
  end

  @doc false
  defdelegate choice_gap(), to: Kati.UI.ImportChrome

  @doc """
  One answer to the conflict, tappable over a real file.

  `Kati.UI.ImportChrome.choice/2` draws it — screen 120 draws the same three
  pills over a plan import with no conflict queue, and takes them as pictures.

  ## How it is drawn

  One answer to the conflict: a 32pt pill, ink when it is the chosen one.

  The sample is a selection, not a recommendation — `[{:keep_mine, "Keep mine", true},
  {"Take file", false}, {"Keep both", false}]`, one true — so this is the same
  control screen 36 draws for its ambiguous match, and it is built the same way:
  `Kati.Components.MishkaToggle`, whose moduledoc's own showcase builds a
  segmented bar out of nothing but these props.

  ## Why not the chip, and why not the segmented control

  `Kati.Components.MishkaChip` is the closer name for a radio set and cannot be
  used: its root `Box` hardcodes `fill_width={false}` with no prop to override,
  so a chip always hugs its label. These three split the card's width by weight.

  `Kati.Components.MishkaSegmentedControl` is the wrong drawing. It renders one
  continuous track with the segments inside it; the design has no track, just
  three pills with 8pt of cream showing between them. The control has
  `track_padding` for the inset but nothing for a gap *between* segments, so its
  segments butt together and no prop opens that 8pt.

  ## The numbers

  Padding is applied before height and the toggle's `padding` default is
  `:space_sm`, so `height: 32` alone would measure 32 plus two paddings.
  `padding: 0` pins the outer 32. `border_width: 0` removes the component's
  default hairline — the bridge draws a border only when `borderColor != null &&
  borderWidth > 0f`, so the `border_color: :border` it still writes paints
  nothing.

  ## Why the pixels do not move

  The toggle exposes no `weight` — `@box_overrides` is `width height shadow` and
  the four paddings — so the weight moves out to a wrapper `Box`, which is the
  arrangement screen 36's `choice/2` already uses:

      <Box weight={1.0}>
        <Box fill_width={true} height={32} corner_radius={16}
             background={bg} align={:center} padding={0}
             border_color={:border} border_width={0}>
          <Text text={label} text_size={11.5} font_weight={:semibold}
                text_color={fg} max_lines={1} />
        </Box>
      </Box>

  against the single `<Box weight={1.0} height={32} corner_radius={16}
  background={bg} align="center">` it replaces.

  That wrapper is layout-neutral in both axes. Horizontally it takes the same
  weighted slot the old box took and then fills it — fence K-17's
  `hugs = boolProp(props, "fill_width") == false` is false for an absent prop,
  leaving `m.fillMaxWidth()` — and the toggle inside fills it in turn, because
  the same test is false for `fill_width={true}`. Vertically it declares no
  height, so it wraps its only child at 32, and the parent `Row`'s
  `align="center"` centres a 32pt box exactly where it centred the old one. Its
  `contentAlignment` is the default top-start, which cannot move a single child
  that already fills the width and sets the height.

  The rest is the same five props with the same five values, plus the three
  no-ops above. `nodeModifier` is one function for every node type, so the
  background, the radius and the height are applied by the same chain, and
  `align: :center` reaches the bridge as the same string `align="center"` did —
  `align` is in none of the renderer's token whitelists, so an unrecognised atom
  passes through and `:json.encode/1` writes an atom as its own name.

  The colour props map one for one onto the two branches: `color`/`text_color`
  are the pressed pair — `Palette.ink_fill/0` under `Palette.on_ink/0`,
  `#1A1917` / `#FBFAF8` in light — `background`/`label_color` the idle pair
  (`Palette.cream_raise/0`, 60% white on cream, and `Palette.cream_sub/0`,
  `#8A7B60`), and `pressed` picks between them exactly as the `if` did.
  """
  @spec choice({atom(), String.t(), boolean()}, boolean()) :: map()
  def choice({key, _label, _chosen?} = chip, live? \\ false) do
    Kati.UI.ImportChrome.choice(
      chip,
      if(live?, do: {self(), Kati.Screens.Import.answer_tag("answer_", key)})
    )
  end

  @doc """
  *1 of 6 · apply to all* — a control now, and it was a `Text`.

  MOVIES-AND-TV.md #101 counted it among this screen's pictures, and the
  fixture's own note said why it is offered underneath rather than as the
  default: six decisions is a short queue, and a blanket answer to a question
  you have not read is how an import quietly destroys a rating. So it applies
  **the answer you just gave**, and it is not tappable until you have given
  one — which is the difference between *apply to all* and *decide for me*.
  """
  @spec apply_to_all(map(), boolean()) :: map()
  def apply_to_all(card, live?) do
    chosen = Enum.find(card.choices, fn {_key, _label, on?} -> on? end)

    assigns = %{
      progress: card.progress,
      tap:
        if(live? and chosen,
          do: {self(), Kati.Screens.Import.answer_tag("all_", elem(chosen, 0))}
        )
    }

    ~MOB"""
    <Text
      text={@progress}
      font_family={Kati.Locale.mono_face()}
      text_size={10.5}
      text_color={Palette.cream_meta()}
      text_align="center"
      max_lines={1}
      on_tap={@tap}
    />
    """
  end

  @doc """
  The tag a choice sends, built from its own label.

      iex> Kati.Screens.Import.answer_tag("answer_", :take_file)
      :answer_take_file
  """
  @spec answer_tag(String.t(), atom()) :: atom()
  def answer_tag(prefix, key) when is_atom(key),
    do: String.to_atom(prefix <> Atom.to_string(key))

  @doc false
  def conflict_poster(c) do
    case Kati.Design.Images.poster(c.seed) do
      nil ->
        ~MOB"<Box width={34} height={48} corner_radius={7} background={Palette.placeholder()} />"

      src ->
        ~MOB"""
        <Image src={src} width={34} height={48} corner_radius={7} content_mode="fill" />
        """
    end
  end

  @doc """
  The `rgba(26,25,23,.07)` rule between two mapping rows.

  `Kati.Components.MishkaSeparator` is what a 1px rule between rows is, so the
  rule is its — and `render: :box` is not optional.

  ## Why `render: :box`

  The component's default is `:divider`, which the bridge maps to Material3's
  `HorizontalDivider`. That is not `Box(fillMaxWidth().height(t).background(c))`
  as this file previously claimed: it is an antialiased `drawLine`. At this
  device's 2.6875x a 1dp rule is handed a 3px canvas and a 2.6875px stroke
  centred in it, so the bottom pixel row lands at ~69% coverage — one full-width
  row 4-5/255 lighter than the two above it. The drawing specifies a 1px
  hairline at a flat 7% ink, and no combination of `color` and `thickness`
  reaches it, because the softness is in the primitive.

  `render: :box` swaps the primitive for a filled rect, where every row carries
  the full colour. The node becomes

      <Box fill_width={true} height={1} background={Palette.hairline()}>
        <Spacer size={1} />
      </Box>

  — `0x121A1917` in light, and `0x12F5F2EE` in dark, which is the one
  alpha-swap the design draws itself on screen 28.

  — Compose's own `Box(fillMaxWidth().height(1.dp).background(colour))`, which
  is the modifier chain this file wrote by hand before it adopted the component
  at all. The `Spacer` is an iOS workaround (`MobBox` drops a Box's `height`
  unless the Box also has a `width`); on Android the Box's `height` pins it and
  `MobSpacer` is a bare `Spacer(modifier.size(1.dp))` with no background, so it
  paints nothing.

  The drawing's 7% ink survives either way because the colour is an ARGB int:
  `color` is in the renderer's `@color_props` whitelist and an integer reaches
  `colorProp` untouched.

  `false` still answers a zero-sized `Spacer`: the last mapping row has no rule,
  and a component whose whole job is to draw a line cannot be asked to draw
  none.
  """
  def hairline(false), do: ~MOB"<Spacer size={0} />"

  def hairline(true),
    do: MishkaSeparator.separator(color: Palette.hairline(), thickness: 1, render: :box)
end
