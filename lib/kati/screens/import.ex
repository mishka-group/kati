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
  out in full. Nothing on this screen taps, either — the three conflict choices
  and the step meter are drawn, not offered — so there is no answer being
  forgotten, only one that cannot yet be asked for. What it needs is named
  above: a job resource holding the file, its column mapping, the counted
  outcome and a conflict queue, so that step 3 of 4 survives the screen popping.
  """
  use Kati.Screens.Pushed, back: "Settings"

  alias Kati.Components.MishkaSeparator
  alias Kati.Import.Sample
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
  else*, and gets `Kati.Import.Sample`, which is the state board 37 was
  captured in.

  A file that could not be read falls back to the drawing rather than to a
  blank page, and carries why on `:refusal` so the screen can say it.
  """
  @spec job_for(map()) :: map()
  def job_for(params) do
    path = Map.get(params, :path)
    name = Map.get(params, :name)

    with true <- is_binary(path) and is_binary(name),
         {:ok, job} <- Kati.Import.Job.read(path, name) do
      job
    else
      {:error, reason} ->
        Map.put(Sample.job(Map.get(params, :source) || :trakt), :refusal, reason)

      _no_file ->
        Sample.job(Map.get(params, :source) || :trakt)
    end
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
    said =
      [
        {tally.new, "added"},
        {tally.merged, "merged"},
        {tally.resolved, "conflicts settled"}
      ]
      |> Enum.filter(fn {n, _word} -> n > 0 end)
      |> Enum.map_join(" · ", fn {n, word} -> "#{n} #{word}" end)

    said = if said == "", do: "Nothing to import", else: said

    case tally.failed do
      0 -> said <> "."
      n -> said <> ". #{n} #{if n == 1, do: "row", else: "rows"} could not be written."
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
        {UI.eyebrow("Match columns")}
        {Kati.Screens.Import.mapping(job)}
        {UI.eyebrow("What will happen")}
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

  @doc false
  def title(job) do
    ~MOB"""
    <Column fill_width={true}>
      <Text
        text="Import"
        text_size={28}
        max_font_scale={1.6}
        font_weight="bold"
        letter_spacing={-0.03}
        text_color={:on_surface}
      />
      <Spacer size={5} />
      <Text
        text={job.subtitle}
        font_family="mono"
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
            font_family="mono"
            text_size={10.5}
            text_color={Palette.muted()}
            max_lines={1}
          />
        </Column>
        <Spacer size={13} />
        {Kati.UI.symbol("check_circle", size: 20, color: Kati.Theme.green(), fill: true)}
      </Row>
      <Spacer size={22} />
    </Column>
    """
  end

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

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_top={13} padding_bottom={13}>
        <Column weight={1.0}>
          <Text
            text={row.column}
            font_family="mono"
            text_size={11}
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={4} />
          <Text text={row.sample} text_size={10.5} text_color={Palette.tertiary()} max_lines={1} />
        </Column>
        <Spacer size={11} />
        {Kati.UI.symbol(row.icon, size: 15, color: Palette.rail_idle())}
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
          letter_spacing={-0.03}
          text_color={card.color}
          text_align="center"
        />
        <Spacer size={5} />
        <Text
          text={String.upcase(card.label)}
          font_family="mono"
          text_size={10}
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
      eyebrow: UI.eyebrow("Conflicts · keep which?"),
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

  The sample is a selection, not a recommendation — `[{"Keep mine", true},
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
  @spec choice({String.t(), boolean()}, boolean()) :: map()
  def choice({label, _primary?} = chip, live? \\ false) do
    Kati.UI.ImportChrome.choice(
      chip,
      if(live?, do: {self(), Kati.Screens.Import.answer_tag("answer_", label)})
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
    chosen = Enum.find(card.choices, fn {_label, on?} -> on? end)

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
      font_family="mono"
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

      iex> Kati.Screens.Import.answer_tag("answer_", "Take file")
      :answer_take_file
  """
  @spec answer_tag(String.t(), String.t()) :: atom()
  def answer_tag(prefix, label) do
    String.to_atom(prefix <> (label |> String.downcase() |> String.replace(" ", "_")))
  end

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
