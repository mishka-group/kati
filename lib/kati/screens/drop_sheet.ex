defmodule Kati.Screens.DropSheet do
  @moduledoc """
  Screen 149 — Drop this show, a sheet over the title you have gone quiet on.

  Built to `test/design/reference/149.html`. The board's own caption names
  three things it is dropping at once: a captured **position** — never a bare
  "dropped" with no stopping point — an optional, one-tap **reason**, and a
  dark **undo** pill, because the app's activity log is append-only and this
  is that log's own trail.

  ## This is the live half of a pair; screen 148 is the reference half

  `Kati.Screens.DropStates` — screen 148, drawn one board earlier — is a
  sheet that draws all five statuses `Kati.Media.TrackedTitle` can carry, side
  by side, and states outright that it carries *no live tap*: "the
  resume-with-position flow the closing note describes... belong[s] to board
  149... which is a different screen." This is that screen, and its three
  controls are 148's own transition table, not a fresh design:

      Gone cold → Dropped   "position + optional reason"
      Gone cold → Active    "nothing — 'still on it' just clears it"
      Dropped   → Active    "resumes at the captured position"

  `Drop at S1 E3` is the first row, `Still on it` is the second, and `Undo`
  on the dark pill is the third — closing the loop 148 opened rather than
  inventing a fourth behaviour for a control 148 never drew.

  ## `:active` and `:gone_cold` are 148's vocabulary, not this resource's yet

  148's own `Kati.Settings.DropStatesSample` states plainly that
  `Kati.Media.TrackedTitle.status` "really does hold `:active` / `:paused` /
  `:gone_cold` / `:dropped` / `:finished`" — but that resource, read here
  rather than quoted, still constrains `status` to `:not_started, :watching,
  :paused, :finished, :dropped`. 148 is itself Sample-only and unwired ("Nothing
  here is read from `Kati.Media`"), so the five-way split is a drawn intention,
  not a shipped migration. `Kati.Screens.UpNext` — which *is* wired — already
  answers the gap the same way this screen does: its own moduledoc calls
  `:paused` "gone cold," full stop. So `gone_cold_title/0` below reads
  `status == :paused`, and every write this screen makes sets `:dropped` or
  `:watching` — the two current-enum values 148's `:dropped` and `:active`
  will rename to once the migration lands. Nothing here invents a third status
  or touches the resource to add one; that migration is a bigger change than
  one screen module.

  ## Not `Kati.UI.Sheet.sheet/2` — the board's own top radius, again

  Screen 144's own note applies unchanged: this board's sheet is
  `border-radius:22px 22px 0 0`, not the family's 26. `Kati.UI.Sheet.sheet/2`
  always draws 26, so `render/1` below reimplements its Box nesting — scrim,
  the 40pt paper strip under the sheet's rounded top (see that module's
  moduledoc for why the strip exists), the `22`-radius drawer — and calls
  `Kati.UI.Sheet.header/1` unchanged for the header, which this board draws at
  the family's own numbers: 36pt close disc, centred 15pt bold title, empty
  36pt hole. The board's `box-shadow:0 -20px 44px -20px rgba(26,25,23,.5)` is
  cast *upward*, onto the scrim; `Kati.Theme`'s shadow tokens are all downward
  casts and `Sheet.sheet/2` — seven screens' own precedent — draws no shadow
  on the sheet itself either, trusting the scrim alone. This one does the same.

  ## The chip row is chunked 4-then-2, measured rather than guessed

  `Kati.Screens.SeriesMeta`'s own note is the method: tags `flex-wrap` in the
  drawing and Mob's `Row` does not, so the break is wherever a browser
  actually wraps them at the frame's own width — not a character count. Six
  labels rendered at `test/design/reference/149.html`'s own `402px` frame
  break after `Too long`: `Lost interest · Too slow · Not for me · Too long`,
  then `Bad time for it · Might come back`. `Enum.chunk_every(@reasons, 4)`
  is that break, not a coincidence — six items in fours is two rows of 4 and
  2 on any input this short, which is what the measurement gave back.

  ## `Too slow` is drawn selected; the mount starts with none

  The board's own info card is explicit that a reason is optional — "a
  required reason is a reason people lie about" — and the selected `Too slow`
  chip is the drawing showing what a selected chip looks like, the same
  demonstrative reading `Kati.Screens.RateEpisode` gives a drawn state it does
  not adopt as the default. Starting `reason` at one of the six would make
  every visit to this sheet arrive with an opinion the person had not yet
  formed. `Kati.UI.chip/2` draws the selected/unselected pair exactly —
  `Palette.ink_fill()` under `Palette.on_ink()`, `Palette.card()` under
  `Palette.ink_soft()` — but carries no `shadow` prop at all, so the drawing's
  `0 1px 2px …, 0 12px 24px -18px …` lift on the six unselected chips is not
  reproduced. `Kati.Screens.ShelfFilters.facet_chip/4` — the only other place
  in the app that draws this exact chip at these exact numbers — accepted the
  same gap rather than hand-rolling a shadowed chip a second time.

  ## The two paragraphs lose their bold run, on purpose and not for the first time

  `Kati.UI.rich_text/1`'s own moduledoc: `MobText` takes one `color` and one
  `fontWeight` for the whole string, so "per-run styling is therefore not
  rendered" and every run collapses onto whichever one is marked `base: true`.
  Both paragraphs here — *"One tap, **never mandatory**…"* and *"Or keep it —
  **'No, I'm still on it'**…"* — are written as three runs each so the
  emphasis is one edit away from real the day `MobText` grows a `runs` prop,
  exactly the trade `Kati.Screens.RetiredTile.no_date/1` already made for the
  same reason.

  ## `Change` steps the captured position back by one episode, locally

  No episode-picker screen exists anywhere in this app yet — `Season 34` is a
  fixed board, not a title-scoped destination, and pushing there from this
  sheet would land on a different show entirely. So `Change` is answered
  in-place: `step_back/1` moves the sheet's own `season`/`episode` pair back
  one episode, flooring at `S1 E1` rather than wrapping, the same bounded
  local edit `Kati.Screens.LogProgress`'s manual field makes for a page
  number. It is not decoration — 148's own `dropped_note` names the reason:
  *"The captured position is the single thing that makes this better than
  every incumbent, all of which throw it away."* Whatever `Change` leaves the
  position at is exactly what `Drop at S# E#`'s label reads and exactly what
  `commit_drop/1` writes to `progress_season` / `progress_episode` — so a
  correction made here is not lost the moment the sheet closes.

  ## The reason chip has nowhere durable to go, and that is written down rather than hidden

  148's own transition table says a drop captures "position + optional
  reason," and the position half has a real column. The reason half does not:
  `Kati.Media.TrackedTitle` has no `drop_reason` attribute, and `Kati.Activity`
  — the append-only log both this board and 148 invoke — is Sample data with
  no writer anywhere in the app (`Kati.Activity.Sample`'s own moduledoc: "the
  shape here is the shape a real entry has to have," not a resource that
  exists yet). So `reason` lives in this screen's assigns for exactly as long
  as the sheet is open, tapped, shown selected, and then discarded when the
  drop commits — the same honest gap `Kati.Screens.SeriesSettings` names for
  its own four Media columns with no writer, rather than a silent no-op typed
  to look like a save.

  ## The undo pill is drawn in both moments, because the board's caption is a promise

  The export's single frame shows the action row **and** the dark undo pill
  together. That was first read as one frame holding two moments and answered
  by drawing only the first: `dropped?` started `false` and the pill was a
  `Spacer size={0}` until the tap. That reading gave away the thing the board
  is actually for. Its caption is not describing a layout — it is making a
  promise: *"nothing here is unrecoverable."* A promise that only becomes
  visible after the irreversible-feeling tap is not a promise, and the one
  person who needs it is the person still deciding.

  So the pill is drawn from the moment the sheet opens, and `dropped?` decides
  which of its two moments it is in:

    * **Before** — `Eyebrow.quiet("After you drop it")` sits over it, which is
      the same *present, but not now* grey `Kati.UI.Eyebrow`'s moduledoc
      describes, and the pill is a picture. Its `Undo` is drawn and not wired,
      for the reason `Kati.Screens.MyServicesStates` gives for its own: there
      is no drop yet to take back, and a control that answers to nothing is
      more honest as part of the picture than as a live button that shrugs.
    * **After** — the label goes, `Undo` becomes live, and what is left is the
      frame the board draws, to the pixel and with no copy the export does not
      contain.

  The label is the one string on this screen the drawing does not hold, and it
  is there so the pill's past tense is never a claim about a title nobody has
  dropped. `handle_info({:tap, :drop}, …)` persists the status and the
  (possibly corrected) position and flips `dropped?`; `handle_info({:tap,
  :undo}, …)` reverses the status write and flips it back, closing the loop
  without leaving the sheet — the undo trail 148 promises has to be readable
  *before* the sheet that offers it is gone, and now it is readable before the
  drop as well.

  ## Referent

  `gone_cold_title/1` reads the `status == :paused, archived == false` rows —
  `Kati.Screens.UpNext`'s own cold-section query, independently written
  here because this sheet needs the integer position that row's own `cold`
  formatter throws away — and takes the one the push NAMED, or the newest when
  the push named none. No such row falls back to `Kati.Screens.DropSheet.
  Sample.sheet/0` whole, the same all-or-nothing fallback
  `Kati.Screens.UpNext.queue/0` and `Kati.Screens.RateEpisode.sheet/0` both
  take, for the reason both give: a real position under the drawing's own
  title would be the one value on the sheet that is not what it claims to be.
  """

  use Mob.Screen
  import Mob.Sigil
  require Ash.Query

  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Screens.DropSheet.Sample
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.Eyebrow
  alias Kati.UI.Sheet

  # The six reasons, in the board's own order — the order `Enum.chunk_every/2`
  # below turns into the measured 4-then-2 wrap.
  @reasons [
    {:lost_interest, "Lost interest"},
    {:too_slow, "Too slow"},
    {:not_for_me, "Not for me"},
    {:too_long, "Too long"},
    {:bad_time, "Bad time for it"},
    {:might_come_back, "Might come back"}
  ]

  # The six chips' tap tags, as atoms.
  #
  # `{:reason, key}` was the obvious shape and is the wrong one:
  # `Mob.Renderer` emits an `accessibility_id` only for an atom tag, so a
  # tuple-tagged chip fires on the device and is nameless everywhere else —
  # invisible to `Kati.ScreenSweep`, to `Kati.AppReachabilityTest`'s push
  # graph, and to a screen reader. `Kati.Screens.ImportSources.tag/1` hit this
  # first and its `"source_" <> id` shape is what this copies.
  #
  # Built here rather than inline because `handle_info/2`'s reason clause has
  # to sit among five sibling clauses that match specific atoms, and a guard
  # is the only way to match *these six* without swallowing `:drop` and
  # `:keep` on the way past.
  @reason_tags Enum.map(@reasons, fn {key, _label} -> :"reason_#{key}" end)

  @impl true
  def mount(params, _session, socket) do
    Kati.Theme.activate()

    {:ok,
     socket
     |> Mob.Socket.assign(:sheet, sheet(Map.get(params || %{}, :title_id)))
     |> Mob.Socket.assign(:reason, nil)
     |> Mob.Socket.assign(:dropped?, false)}
  end

  @doc """
  The params that name a thread to this sheet.

  `:title_id` and not `:id`, for the reason `Kati.Screens.Season.params_for/1`
  gives: naming the noun is what tells a reader whose id it is holding.
  `%{tracked_id: id}` is the shape `Kati.Screens.Series`'s page already carries,
  and a row with no tracked id — every drawn fixture — yields `%{}` rather than
  `%{title_id: nil}`, so the bare branch stays the branch a nameless push takes.

      iex> Kati.Screens.DropSheet.params_for(%{tracked_id: "abc"})
      %{title_id: "abc"}

      iex> Kati.Screens.DropSheet.params_for(%{title: "The Quiet Ones"})
      %{}
  """
  @spec params_for(map() | nil) :: map()
  def params_for(%{tracked_id: id}) when is_binary(id), do: %{title_id: id}
  def params_for(_row), do: %{}

  @doc """
  The title this sheet drops: the one it was named, the newest gone-cold row,
  or the board's own.

  See the moduledoc's "Referent" section. Without the id every door into this
  sheet opened the same row — the newest paused one — however many gone-cold
  threads the store holds and whichever of them the door was on. That is the
  defect Phase 1 is named for, and on a sheet that WRITES it is worse than a
  dead control: it drops a title the user did not point at.

  An id that names no gone-cold row answers `nil` and falls back to the drawing
  rather than to the head of the list, which is the rule the whole phase keeps:
  a row dropped, resumed or never paused under you is not the same fact as an
  empty queue, and answering with a different real title is the swap this
  argument exists to prevent.
  """
  @spec sheet(String.t() | nil) :: map()
  def sheet(title_id \\ nil) do
    case gone_cold_title(title_id) do
      nil -> Sample.sheet()
      tracked -> from_tracked(tracked)
    end
  end

  # One query either way — the filter is what this sheet is ABOUT (a thread
  # that has gone quiet and is still on the shelf), so a named id narrows that
  # set rather than replacing it. `archived == false` therefore still holds for
  # a named row: an id must not open a title the user has hidden.
  defp gone_cold_title(title_id) do
    TrackedTitle
    |> Ash.Query.filter(archived == false and status == :paused)
    |> Ash.Query.sort(last_touched_at: :desc)
    |> Ash.read!()
    |> pick(title_id)
  rescue
    _ -> nil
  end

  defp pick(rows, nil), do: List.first(rows)
  defp pick(rows, title_id), do: Enum.find(rows, &(&1.id == title_id))

  defp from_tracked(tracked) do
    cached = cached_for(tracked)

    %{
      tracked: tracked,
      title: title_of(cached),
      seed: seed_of(cached),
      cold_label: "GONE COLD · " <> duration_of(tracked.last_touched_at),
      season: tracked.progress_season || 1,
      episode: tracked.progress_episode || 1
    }
  end

  defp cached_for(tracked) do
    CachedTitle
    |> Ash.Query.filter(source == ^tracked.source and source_id == ^tracked.source_id)
    |> Ash.read!()
    |> List.first()
  rescue
    _ -> nil
  end

  defp title_of(nil), do: "Untitled"
  defp title_of(%CachedTitle{title: nil}), do: "Untitled"
  defp title_of(%CachedTitle{title: title}), do: title

  defp seed_of(nil), do: nil
  defp seed_of(%CachedTitle{poster_path: path}), do: path

  # `Kati.Screens.UpNext.age/1` is documented public for exactly this — "the
  # one string on this screen that no column contains" — and its buckets are
  # what this line wants too. The board's own words are "GONE COLD · 4 MONTHS,"
  # not "… 4 MONTHS AGO," so the one word `age/1` adds for its own sentence
  # comes back off for this one.
  defp duration_of(at), do: String.replace_suffix(Kati.Screens.UpNext.age(at), " AGO", "")

  @doc """
  Move the captured stopping point back one episode, flooring at `S1 E1`.

  See the moduledoc's `Change` section for why this is a local edit rather
  than a push to a picker screen that does not exist.
  """
  @spec step_back(map()) :: map()
  def step_back(%{episode: e} = sheet) when is_integer(e) and e > 1,
    do: %{sheet | episode: e - 1}

  def step_back(%{season: s} = sheet) when is_integer(s) and s > 1,
    do: %{sheet | season: s - 1, episode: 1}

  def step_back(sheet), do: sheet

  @doc "Gone cold → Dropped: writes the corrected position and the new status."
  @spec commit_drop(Mob.Socket.t()) :: Mob.Socket.t()
  def commit_drop(socket) do
    sheet = socket.assigns.sheet

    update_tracked(sheet.tracked, %{
      status: :dropped,
      progress_season: sheet.season,
      progress_episode: sheet.episode
    })

    socket
  end

  @doc "Gone cold → Active: \"nothing — 'still on it' just clears it.\""
  @spec commit_keep(Mob.Socket.t()) :: Mob.Socket.t()
  def commit_keep(socket) do
    update_tracked(socket.assigns.sheet.tracked, %{status: :watching})
    socket
  end

  @doc "Dropped → Active: the position was never touched, so it is already resumed at."
  @spec commit_undo(Mob.Socket.t()) :: Mob.Socket.t()
  def commit_undo(socket) do
    update_tracked(socket.assigns.sheet.tracked, %{status: :watching})
    socket
  end

  # `nil` is the drawn fallback: nothing to write against, so the tap still
  # changes the sheet's own assigns and simply persists nothing durable.
  defp update_tracked(nil, _attrs), do: :ok

  defp update_tracked(tracked, attrs) do
    Ash.update(tracked, attrs)
    :ok
  rescue
    _ -> :ok
  end

  @impl true
  def render(assigns) do
    s = assigns.sheet

    ~MOB"""
    <Box
      fill_width={true}
      fill_height={true}
      background={:background}
      layout_direction={Kati.Locale.direction_prop()}
      accessibility_id={Kati.Screens.Identity.of(__MODULE__)}
    >
      <Box fill_width={true} fill_height={true} background={Kati.UI.Sheet.scrim()} />
      <Box fill_width={true} fill_height={true} align="bottom">
        <Box fill_width={true} height={40} background={Palette.paper()} />
        <Column
          fill_width={true}
          background={Palette.paper()}
          corner_radius={22}
          padding_left={21}
          padding_right={21}
          padding_top={18}
          padding_bottom={34}
        >
          {Sheet.header("Drop this show")}
          {Kati.Screens.DropSheet.identity(s)}
          {Kati.Screens.DropSheet.position_card(s)}
          {Eyebrow.quiet("Why, if you like")}
          {Kati.Screens.DropSheet.reasons(assigns.reason)}
          {Kati.Screens.DropSheet.info_card()}
          {Kati.Screens.DropSheet.keep_card()}
          {Kati.Screens.DropSheet.actions(s)}
          {Kati.Screens.DropSheet.trail(s, assigns.dropped?)}
        </Column>
      </Box>
    </Box>
    """
  end

  @doc false
  def identity(s) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        {Kati.Screens.DropSheet.poster(s.seed)}
        <Spacer size={13} />
        <Column weight={1.0}>
          <Text
            text={s.title}
            text_size={14.5}
            font_weight="bold"
            letter_spacing={-0.015}
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={5} />
          <Text
            text={s.cold_label}
            font_family="mono"
            text_size={10.5}
            text_color={Palette.muted()}
            max_lines={1}
          />
        </Column>
      </Row>
      <Spacer size={18} />
    </Column>
    """
  end

  @doc "The 44x62 poster, or the placeholder swatch when no seed resolves."
  @spec poster(String.t() | nil) :: map()
  def poster(nil),
    do: ~MOB"<Box width={44} height={62} corner_radius={9} background={Palette.placeholder()} />"

  def poster(seed) do
    case Kati.Design.Images.poster(seed) do
      nil ->
        ~MOB"<Box width={44} height={62} corner_radius={9} background={Palette.placeholder()} />"

      src ->
        ~MOB"""
        <Box width={44} height={62} corner_radius={9} background={Palette.placeholder()}>
          <Image src={src} width={44} height={62} corner_radius={9} content_mode="fill" />
        </Box>
        """
    end
  end

  @doc false
  def position_card(s) do
    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        padding={17}
        shadow={Kati.Theme.shadow_card_soft()}
        align="center"
      >
        <Column>
          <Text
            text={String.upcase("Stopping at")}
            font_family="mono"
            text_size={10}
            letter_spacing={0.14}
            text_color={Palette.eyebrow()}
            max_lines={1}
          />
          <Spacer size={7} />
          <Text
            text={"S#{s.season} E#{s.episode}"}
            font_family="mono"
            text_size={20}
            font_weight="medium"
            letter_spacing={-0.02}
            text_color={:on_surface}
            max_lines={1}
          />
        </Column>
        <Spacer weight={1.0} />
        {Kati.Screens.DropSheet.change_pill()}
      </Row>
      <Spacer size={14} />
    </Column>
    """
  end

  @doc false
  def change_pill do
    ~MOB"""
    <Row
      height={30}
      corner_radius={15}
      background={Palette.paper()}
      align="center"
      padding_left={12}
      padding_right={12}
      on_tap={{self(), :step_back}}
    >
      <Text
        text="Change"
        text_size={11.5}
        font_weight="semibold"
        text_color={:on_surface}
        max_lines={1}
      />
    </Row>
    """
  end

  @doc "A reason key as its tap tag — `:too_slow` becomes `:reason_too_slow`."
  @spec reason_tag(atom()) :: atom()
  def reason_tag(key) when is_atom(key), do: :"reason_#{key}"

  @doc "The reason a tap tag names, or `nil` when the tag is not one of the six."
  @spec reason_for(atom()) :: atom() | nil
  def reason_for(tag) when is_atom(tag) do
    Enum.find_value(@reasons, fn {key, _label} ->
      if Kati.Screens.DropSheet.reason_tag(key) == tag, do: key
    end)
  end

  @doc "The six chips, chunked 4-then-2 — see the moduledoc for the measurement."
  @spec reasons(atom() | nil) :: map()
  def reasons(selected) do
    rows =
      @reasons
      |> Enum.chunk_every(4)
      |> Enum.map(fn row -> Kati.Screens.DropSheet.reason_row(row, selected) end)
      |> Enum.intersperse(~MOB"<Box fill_width={true} height={7} />")

    ~MOB"""
    <Column fill_width={true}>
      {rows}
      <Spacer size={14} />
    </Column>
    """
  end

  @doc false
  def reason_row(items, selected) do
    chips =
      items
      |> Enum.map(fn {key, label} ->
        UI.chip(label,
          selected: selected == key,
          on_toggle: Kati.Screens.DropSheet.reason_tag(key)
        )
      end)
      |> Enum.intersperse(~MOB"<Spacer size={7} />")

    ~MOB"""
    <Row fill_width={true}>
      {chips}
    </Row>
    """
  end

  @doc "The dashed card: one tap, never mandatory."
  @spec info_card() :: map()
  def info_card do
    runs = [
      {"One tap, ",
       [text_size: 12.5, line_height: 1.65, text_color: Palette.ink_soft(), base: true]},
      {"never mandatory",
       [text_size: 12.5, line_height: 1.65, font_weight: "semibold", text_color: :on_surface]},
      {" — a required reason is a reason people lie about. A drop with no chip is complete, not unfinished.",
       [text_size: 12.5, line_height: 1.65, text_color: Palette.ink_soft()]}
    ]

    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        align="top"
        padding={15}
        corner_radius={18}
        border_width={1.5}
        border_color={Palette.border()}
      >
        {UI.symbol("info", size: 17, color: Palette.sub())}
        <Spacer size={11} />
        <Column weight={1.0}>
          {UI.rich_text(runs)}
        </Column>
      </Row>
      <Spacer size={14} />
    </Column>
    """
  end

  @doc "The cream-less card: keeping it clears Gone cold and nothing else."
  @spec keep_card() :: map()
  def keep_card do
    runs = [
      {"Or keep it — ",
       [text_size: 12.5, line_height: 1.6, text_color: Palette.ink_soft(), base: true]},
      {"“No, I’m still on it”",
       [text_size: 12.5, line_height: 1.6, font_weight: "semibold", text_color: :on_surface]},
      {" clears the Gone cold mark and changes nothing else.",
       [text_size: 12.5, line_height: 1.6, text_color: Palette.ink_soft()]}
    ]

    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Palette.card()}
        corner_radius={20}
        padding={15}
        shadow={Kati.Theme.shadow_card_soft()}
        align="center"
      >
        {UI.symbol("check_circle", size: 20, color: Palette.green(), fill: true)}
        <Spacer size={12} />
        <Column weight={1.0}>
          {UI.rich_text(runs)}
        </Column>
      </Row>
      <Spacer size={14} />
    </Column>
    """
  end

  @doc "`Drop at S# E#` beside `Still on it` — the board's own two-button row."
  @spec actions(map()) :: map()
  def actions(s) do
    label = "Drop at S#{s.season} E#{s.episode}"

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Row
          weight={1.0}
          height={54}
          corner_radius={27}
          background={Palette.ink_fill()}
          align="center"
          shadow="0 14 28 -12 #801A1917"
          on_tap={{self(), :drop}}
        >
          <Spacer weight={1.0} />
          <Text
            text={label}
            text_size={14.5}
            font_weight="bold"
            text_color={Palette.on_ink()}
            max_lines={1}
          />
          <Spacer weight={1.0} />
        </Row>
        <Spacer size={10} />
        <Row
          height={54}
          corner_radius={27}
          background={Palette.paper()}
          align="center"
          padding_left={18}
          padding_right={18}
          on_tap={{self(), :keep}}
        >
          <Text
            text="Still on it"
            text_size={13}
            font_weight="semibold"
            text_color={Palette.ink_soft()}
            max_lines={1}
          />
        </Row>
      </Row>
      <Spacer size={14} />
    </Column>
    """
  end

  @doc """
  The board's last band, in whichever of its two moments the sheet is in.

  `false` is the moment the export cannot show and the sheet spends most of its
  life in: the pill under a quiet label, promising the tap is reversible before
  the tap is asked for. `true` is the export itself — the same pill, the label
  gone, `Undo` live. See the moduledoc for why both are drawn.
  """
  @spec trail(map(), boolean()) :: map()
  def trail(s, false) do
    ~MOB"""
    <Column fill_width={true}>
      {Eyebrow.quiet("After you drop it")}
      {Kati.Screens.DropSheet.undo_pill(s, false)}
    </Column>
    """
  end

  def trail(s, true), do: Kati.Screens.DropSheet.undo_pill(s, true)

  @doc """
  The dark pill: the `undo` glyph, the sentence, and `Undo`.

  The boolean is whether `Undo` is live, not whether the pill is drawn — the
  pill is always drawn. It reads the sheet's own position rather than a
  remembered one, so `Change` and the pill never disagree about which episode
  the sentence is about.
  """
  @spec undo_pill(map(), boolean()) :: map()
  def undo_pill(s, live?) do
    text = "Dropped #{s.title} at S#{s.season} E#{s.episode}"

    ~MOB"""
    <Row
      fill_width={true}
      background={Palette.ink_fill()}
      corner_radius={20}
      padding_left={16}
      padding_right={16}
      padding_top={13}
      padding_bottom={13}
      align="center"
    >
      {UI.symbol("undo", size: 19, color: Palette.on_ink())}
      <Spacer size={12} />
      <Text
        text={text}
        text_size={13}
        font_weight="semibold"
        text_color={Palette.on_ink()}
        weight={1.0}
      />
      <Spacer size={12} />
      {Kati.Screens.DropSheet.undo_action(live?)}
    </Row>
    """
  end

  @doc """
  `Undo`, wired only once there is a drop to take back.

  Drawn identically either way — same 12.5pt bold accent the board sets it in —
  because the picture the pill paints before the tap is worthless if the word
  it promises is not the word that arrives.
  """
  @spec undo_action(boolean()) :: map()
  def undo_action(true) do
    ~MOB"""
    <Row align="center" on_tap={{self(), :undo}}>
      {Kati.Screens.DropSheet.undo_action(false)}
    </Row>
    """
  end

  def undo_action(false) do
    ~MOB"""
    <Text
      text="Undo"
      text_size={12.5}
      font_weight="bold"
      text_color={Palette.accent()}
      max_lines={1}
    />
    """
  end

  @impl true
  def handle_info({:tap, :close}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}

  def handle_info({:tap, :step_back}, socket) do
    {:noreply, Mob.Socket.update(socket, :sheet, &Kati.Screens.DropSheet.step_back/1)}
  end

  def handle_info({:tap, tag}, socket) when tag in @reason_tags do
    key = Kati.Screens.DropSheet.reason_for(tag)
    next = if socket.assigns.reason == key, do: nil, else: key
    {:noreply, Mob.Socket.assign(socket, :reason, next)}
  end

  def handle_info({:tap, :drop}, socket) do
    socket = Kati.Screens.DropSheet.commit_drop(socket)
    {:noreply, Mob.Socket.assign(socket, :dropped?, true)}
  end

  def handle_info({:tap, :keep}, socket) do
    socket = Kati.Screens.DropSheet.commit_keep(socket)
    {:noreply, Mob.Socket.pop_screen(socket)}
  end

  def handle_info({:tap, :undo}, socket) do
    socket = Kati.Screens.DropSheet.commit_undo(socket)
    {:noreply, Mob.Socket.assign(socket, :dropped?, false)}
  end

  def handle_info(_message, socket), do: {:noreply, socket}
end
