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
  then `Bad time for it · Might come back`. `Enum.chunk_every(reason_table(), 4)`
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

  ## What this sheet says in Persian, and what it only typesets

  mishka-group/kati#103. Every string this file writes goes through
  `gettext/1` or `pgettext/2` here — the header, the position card, the six
  reason chips, both cards, both buttons and the undo pill — with `pgettext/2`
  wherever the copy is short enough for `mix gettext.merge` to fuzzy-match it
  onto a neighbour, which on a sheet made of buttons and chips is most of it.

  Three strings it draws and does not own, each named where it is drawn rather
  than left to be noticed:

    * `The Quiet Ones` and `GONE COLD · 4 MONTHS` come off
      `Kati.Screens.DropSheet.Sample`, which is board 149 typed once and is
      that module's to translate — the same split `Kati.Screens.DropStates`
      keeps with `Kati.Settings.DropStatesSample`, and for its reason: a msgid
      has to be a literal at its own call site, so wrapping the specimen from
      here would move the copy out of the specimen. A REAL title is a
      `Kati.Media.CachedTitle` row and is never translated at all.
    * the age inside that mark is `Kati.Screens.UpNext.age/1`'s bucket,
      borrowed rather than re-typed — see `duration_of/1`.
    * the refusal band's sentence is `Kati.Write.message/1`'s, and that module
      already speaks both languages.

  The typesetting is this file's either way, and it is the half that breaks
  silently rather than loudly:

    * `Kati.Locale.mono_face/1` on both mono slots. `kati_mono.ttf` carries no
      Persian glyph and none of U+06F0–U+06F9, so `ف۱ ق۳` set in it is handed
      to Android's own substitute face; the arity-1 form asks the STRING's
      script, so `S1 E3` and a Latin `GONE COLD · 4 MONTHS` keep DM Mono.
    * `Kati.UI.eyebrow_label/1` rather than `String.upcase/1` on *Stopping at*
      — the Arabic script has no case, so upper-casing **جای توقف** is a no-op
      that reads as a decision.
    * `Kati.Locale.tracking/1` on the card's `.14em` and on both tight
      headings: letter-spacing is a Latin effect and pulls Persian letters
      apart at their joins.
    * `Kati.Locale.number/1` on the season and the episode, which is what makes
      the position `ف۱ ق۳` rather than `ف1 ق3`.
    * `Kati.Locale.ltr/1` on the title inside the undo pill's sentence. A
      Latin name in a Persian sentence hands its own punctuation to the
      paragraph's direction — *Dune: Part Two* comes back with the colon on
      the wrong side of the name — and an isolate is Unicode's own answer.

  ## The reason that is written down is the one the reader read

  `reason_label/1` answers the six chips' own words, and under `:fa` those
  words are Persian. That is deliberate and it is what this module already
  said it was for — *"the words the reader read when they tapped it"* — and
  `Kati.Media.Event.reason` is free text precisely so it can hold a sentence.
  It does mean a drop made in one language keeps that language in the log
  after the reader switches; the alternative is a column of English shown to
  somebody who chose Persian, on a row that is their own history.

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
  use Gettext, backend: Kati.Gettext
  import Mob.Sigil
  require Ash.Query

  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Screens.DropSheet.Sample
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.Eyebrow
  alias Kati.UI.Sheet

  # The six reasons' keys, in the board's own order — the order
  # `Enum.chunk_every/2` below turns into the measured 4-then-2 wrap.
  #
  # The KEYS only. The labels were here too, in one `@reasons` attribute, and
  # they cannot stay: `gettext/1` inside a module attribute is evaluated when
  # the module is COMPILED, so the six words would freeze in whichever locale
  # the compiler happened to be in and every reader after that would get that
  # one. `reason_table/0` is the same six with their labels, evaluated per
  # call — which is per render, which is what a locale that changes while the
  # app is running needs. mishka-group/kati#103.
  @reason_keys [:lost_interest, :too_slow, :not_for_me, :too_long, :bad_time, :might_come_back]

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
  @reason_tags Enum.map(@reason_keys, fn key -> :"reason_#{key}" end)

  # The six, with the words the board draws on them.
  #
  # `pgettext/2` on all six rather than `gettext/1`, and one shared context
  # rather than six: every label here is two or three words, which is exactly
  # the length `mix gettext.merge`'s fuzzy matcher hands to whatever sentence
  # it half-resembles — *Too long* against `Kati.Screens.WeekImage`'s "The page
  # took too long to capture", say. The context is also the frame a translator
  # needs, because
  # none of the six is a sentence: they are the ends of *I dropped it because…*
  # and read as adjectives without that.
  defp reason_table do
    [
      {:lost_interest, pgettext("why a show was dropped", "Lost interest")},
      {:too_slow, pgettext("why a show was dropped", "Too slow")},
      {:not_for_me, pgettext("why a show was dropped", "Not for me")},
      {:too_long, pgettext("why a show was dropped", "Too long")},
      {:bad_time, pgettext("why a show was dropped", "Bad time for it")},
      {:might_come_back, pgettext("why a show was dropped", "Might come back")}
    ]
  end

  @impl true
  def mount(params, _session, socket) do
    Kati.Theme.activate()
    Kati.Locale.activate()
    Kati.Screens.Resume.watch()

    {:ok,
     socket
     |> Mob.Socket.assign(:sheet, sheet(Map.get(params || %{}, :title_id)))
     |> Mob.Socket.assign(:reason, nil)
     |> Mob.Socket.assign(:save_error, nil)
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
      nil -> empty_sheet()
      tracked -> from_tracked(tracked)
    end
  end

  @doc """
  The sheet with no thread on it.

  `from_tracked/1`'s seven keys carrying nothing. It is what a sheet opened
  over no row answers now, in place of `Kati.Screens.DropSheet.Sample.sheet/0` —
  *The Quiet Ones*, `GONE COLD · 4 MONTHS`, S1 E3, which is one person's shelf
  and was never this reader's.

  `tracked: nil` is the same sentinel it always was, and it is what
  `update_tracked/2` refuses on: a sheet with nothing to write to says so rather
  than announcing a drop it did not make.

  `kind: :tv` because `heading/1` reads it to choose between *Drop this show*
  and *Drop this film*, and one of the two has to be the word over an empty
  sheet. Empty strings where the value reaches a `Text` — a nil arrives on a
  device as the word `nil`.
  """
  @spec empty_sheet() :: map()
  def empty_sheet do
    %{
      tracked: nil,
      title: "",
      seed: nil,
      cold_label: "",
      kind: :tv,
      season: nil,
      episode: nil
    }
  end

  @doc """
  Board 149 exactly as it is drawn, from `Kati.Screens.DropSheet.Sample`.

  A test fixture and nothing else, the way `Kati.Screens.Film.drawn_film/0` is:
  `Kati.ScreenDesignLiteralTest` installs it so the sheet is still compared
  against its capture. Nothing a reader can reach calls it.
  """
  @spec drawn_sheet() :: map()
  def drawn_sheet, do: Sample.sheet()

  # One query either way — the filter is what this sheet is ABOUT (a thread
  # that has gone quiet and is still on the shelf), so a named id narrows that
  # set rather than replacing it. `archived == false` therefore still holds for
  # a named row: an id must not open a title the user has hidden.
  # Gone cold is derived — see `Kati.Media.Staleness`, and the moduledoc above
  # for what this used to read instead.
  defp gone_cold_title(title_id) do
    TrackedTitle
    |> Ash.Query.filter(archived == false and status in [:watching, :paused])
    |> Ash.Query.sort(last_touched_at: :desc)
    |> Ash.read!()
    |> Enum.filter(&cold_or_paused?/1)
    |> pick(title_id)
  rescue
    _ -> nil
  end

  # A title a NAMED push points at is taken whether or not Kati would have
  # called it cold: screen 04's *Drop this show* is a decision the reader is
  # making about the show in front of them, and refusing it because the show is
  # three months old rather than four would be the sheet arguing.
  defp cold_or_paused?(%TrackedTitle{status: :paused}), do: true
  defp cold_or_paused?(tracked), do: Kati.Media.Staleness.gone_cold?(tracked)

  defp pick(rows, nil), do: List.first(rows)

  # A named id is looked up in the WHOLE shelf, not in the cold slice — see
  # `cold_or_paused?/1`.
  defp pick(_rows, title_id) do
    TrackedTitle
    |> Ash.Query.filter(archived == false and id == ^title_id)
    |> Ash.read!()
    |> List.first()
  rescue
    _error -> nil
  end

  defp from_tracked(tracked) do
    cached = cached_for(tracked)

    %{
      tracked: tracked,
      title: title_of(cached),
      seed: seed_of(cached),
      cold_label: Kati.Screens.DropSheet.mark(tracked),
      # A film has no episode to have stopped after, so
      # it carries no position at all rather than a manufactured `S1 E1` — and
      # `position_card/1` draws nothing for it. Inventing a position would put
      # *after S1E1* on a two-hour film's own history.
      kind: tracked.kind,
      season: if(tracked.kind == :movie, do: nil, else: tracked.progress_season || 1),
      episode: if(tracked.kind == :movie, do: nil, else: tracked.progress_episode || 1)
    }
  end

  @doc """
  The mono line under the title: what Kati noticed, or what the reader decided,
  or nothing.

  It was `GONE COLD · %{age}` unconditionally, and `pick/2` looks a NAMED push
  up in the whole shelf rather than in the cold slice — so *Drop this show* on
  screen 04's ⋯ menu told a reader who started something this morning that it
  had **GONE COLD · TODAY**. Found by auditing screen 148 against this one.

  148's own moduledoc is the rule this restores, and it is the one distinction
  the app makes about a shelf: *Paused and Dropped are things a person decided;
  Gone cold is something Kati noticed.* Three answers, then:

    * cold by `Kati.Media.Staleness.gone_cold?/1` — Kati's own observation, so
      it is stated with the age that earned it;
    * `:paused` and not cold — the reader's own decision, stated back to them
      without Kati claiming to have noticed anything;
    * anything else — **nothing at all.** A show being watched normally has no
      mark, and the sheet is a question about it rather than a report on it.

  The age inside it is `Kati.Screens.UpNext`'s and stays Latin until that screen
  folds — see `duration_of/1` — so under `:fa` the mark reads **سردشده · 4
  MONTHS**, which is one word short of translated rather than a line of English.
  """
  @spec mark(struct()) :: String.t()
  def mark(tracked) do
    cond do
      Kati.Media.Staleness.gone_cold?(tracked) ->
        pgettext("the cold mark over the title being dropped", "GONE COLD · %{age}",
          age: duration_of(tracked.last_touched_at)
        )

      tracked.status == :paused ->
        pgettext("the paused mark over the title being dropped", "PAUSED · %{age}",
          age: duration_of(tracked.last_touched_at)
        )

      true ->
        ""
    end
  rescue
    _error -> ""
  end

  defp cached_for(tracked) do
    CachedTitle
    |> Ash.Query.filter(source == ^tracked.source and source_id == ^tracked.source_id)
    |> Ash.read!()
    |> List.first()
  rescue
    _ -> nil
  end

  # The msgid `Kati.Screens.Activity`, `Kati.Screens.Stats` and
  # `Kati.Screens.SeriesSettings` already draw for the same gap — **بی‌عنوان**
  # — rather than a second Persian word for a title Kati has no name for. The
  # title BESIDE these two clauses is a cache row and is never translated: a
  # show is called what it is called.
  defp title_of(nil), do: gettext("Untitled")
  defp title_of(%CachedTitle{title: nil}), do: gettext("Untitled")
  defp title_of(%CachedTitle{title: title}), do: title

  defp seed_of(nil), do: nil
  defp seed_of(%CachedTitle{poster_path: path}), do: path

  # `Kati.Screens.UpNext.age/1` is documented public for exactly this — "the
  # one string on this screen that no column contains" — and its buckets are
  # what this line wants too. The board's own words are "GONE COLD · 4 MONTHS,"
  # not "… 4 MONTHS AGO," so the one word `age/1` adds for its own sentence
  # comes back off for this one.
  #
  # mishka-group/kati#103: those nine buckets are `Kati.Screens.UpNext`'s copy
  # and are that screen's to translate. A msgid has to be a literal at its own
  # call site, so the only way to say *4 MONTHS* in Persian from here is to
  # re-type the whole table — and two answers to *how long ago* is exactly the
  # drift `age/1` was made public to prevent. It stays borrowed, and stays
  # Latin under `:fa` until `Kati.Screens.UpNext` folds. When it does, this
  # suffix strip stops matching — Persian has no " AGO" to remove — and the
  # mark reads *سردشده · ۴ ماه پیش*, which is a redundant word rather than a
  # wrong one, and is that screen's edit to make beside its own.
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

  @doc """
  Move it forward one episode.

  The pill only ever decremented, so a reader who went
  one too far had to close the sheet and open it again to get back — and
  closing the sheet is the one thing somebody mid-decision should not have to
  do to correct a typo.

  There is no ceiling to floor against, unlike `step_back/1`'s `S1 E1`. The
  cache would know how many episodes the season has, and reading it here would
  make the pill say *no* to a number the reader can see is right whenever the
  cache is behind the broadcast. The stopping point is the reader's claim
  about their own watching, so it is theirs to state.

      iex> Kati.Screens.DropSheet.step_forward(%{season: 1, episode: 3})
      %{season: 1, episode: 4}
  """
  @spec step_forward(map()) :: map()
  def step_forward(%{episode: e} = sheet) when is_integer(e), do: %{sheet | episode: e + 1}
  def step_forward(sheet), do: sheet

  @doc """
  Gone cold → Dropped: writes the corrected position, the new status, and why.

  The reason was assigned to this socket, drawn as a lit
  chip, and thrown away when the sheet closed — the one question in the app
  whose answer nothing could ever read back. `Kati.Media.Event` is where it
  goes now, with the position beside it, so screen 15 can draw *Dropped after
  S1E3 · too slow* out of a row rather than a fixture.

  The event is written only when the status write succeeded. An event log that
  records a change the store refused is worse than no log: it is a record of
  something that did not happen.
  """
  @spec commit_drop(Mob.Socket.t()) :: Mob.Socket.t()
  def commit_drop(socket) do
    sheet = socket.assigns.sheet

    socket
    |> written(sheet.tracked, %{
      status: :dropped,
      progress_season: sheet.season,
      progress_episode: sheet.episode
    })
    |> Kati.Screens.DropSheet.log(sheet.tracked, :dropped, %{
      season_number: sheet.season,
      episode_number: sheet.episode,
      reason: Kati.Screens.DropSheet.reason_label(Map.get(socket.assigns, :reason))
    })
  end

  @doc "Gone cold → Active: \"nothing — 'still on it' just clears it.\""
  @spec commit_keep(Mob.Socket.t()) :: Mob.Socket.t()
  def commit_keep(socket),
    do: written(socket, socket.assigns.sheet.tracked, %{status: :watching})

  @doc """
  Dropped → Active: the position was never touched, so it is already resumed at.

  Logged as `:resumed` rather than by deleting the drop. `Kati.Media.Event` is
  append-only and the point of it is that a title dropped in July and picked
  back up in September has two rows, not none — an undo that erased its own
  cause would put the log back where it started.
  """
  @spec commit_undo(Mob.Socket.t()) :: Mob.Socket.t()
  def commit_undo(socket) do
    socket
    |> written(socket.assigns.sheet.tracked, %{status: :watching})
    |> Kati.Screens.DropSheet.log(socket.assigns.sheet.tracked, :resumed, %{})
  end

  @doc """
  Append one event, if the write that caused it went through.

  `nil` tracked is the drawn sheet's own case, exactly as `update_tracked/1`
  reads it: board 149 has no row behind it by design, and logging an event
  about a drawing would put a fixture in the reader's own history.
  """
  @spec log(Mob.Socket.t(), term(), atom(), map()) :: Mob.Socket.t()
  def log(socket, tracked, kind, attrs) do
    if is_nil(Map.get(socket.assigns, :save_error)) do
      Kati.Media.Log.write(tracked, kind, attrs)
    end

    socket
  end

  @doc """
  A reason key as the words the reader read when they tapped it.

  Stored as the label rather than the key, because `Kati.Media.Event.reason` is
  free text — it has to hold *Something else* typed by hand — and a column
  holding `:too_slow` for one row and a sentence for the next is two columns
  wearing one name.

  Under `:fa` those words are Persian, which is the moduledoc's own section on
  this and not an accident of wrapping the chips: the log is the reader's own
  history and it is written in the language they were reading.

      iex> Kati.Screens.DropSheet.reason_label(:too_slow)
      "Too slow"

      iex> Kati.Screens.DropSheet.reason_label(nil)
      nil
  """
  @spec reason_label(atom() | nil) :: String.t() | nil
  def reason_label(nil), do: nil

  def reason_label(key) do
    Enum.find_value(reason_table(), fn {k, label} -> if k == key, do: label end)
  end

  @doc """
  Whether the write happened, on the socket.

  `update_tracked/2` used to answer `:ok` whatever became of the `Ash.update`
  — the result was discarded and a raise was rescued to `:ok` — so a refused
  drop and a successful one were the same thing to look at: the sheet flipped
  to its *Dropped* face and announced a change that had not been made.

  The result is kept now, and `refusal/1` draws it. The `rescue` stays, and it
  matters that it does: an `Ash.Changeset` error is a value and a raise is not,
  and a sheet that died inside a tap handler would take the screen process with
  it — see `Kati.Screens.Series.tick_result/2`, which is the same shape for the
  same reason.
  """
  @spec written(Mob.Socket.t(), term(), map()) :: Mob.Socket.t()
  def written(socket, tracked, attrs) do
    case update_tracked(tracked, attrs) do
      :ok ->
        Mob.Socket.assign(socket, :save_error, nil)

      {:error, reason} ->
        Mob.Socket.assign(socket, :save_error, Kati.Write.message({:error, reason}))
    end
  end

  # `nil` is a refusal now, and has to be. This clause answered `:ok`, so
  # `written/3` cleared `save_error`, `handle_info({:tap, :drop}, …)` read that
  # as success and flipped `dropped?` — the sheet said *Dropped* over a write
  # that never happened. `Kati.Media.Log.write(nil, _, _)` is `:ok` too, so
  # nothing anywhere had recorded it.
  #
  # The old reasoning — that saying *this did not save* over board 149 would be
  # an error message about a drawing — held only while the drawn sheet was
  # unreachable. It was not: screens 04 and 08 fell back to their own drawings,
  # and a drawn row carries no `tracked_id`, so `params_for/1` answered `%{}`
  # and a real ⋯ menu opened this sheet over nothing. Both now draw their own
  # empty page, and `empty_sheet/0` replaced the fixture here, so a nil row is
  # what it always meant literally: there is no title to drop.
  defp update_tracked(nil, _attrs), do: {:error, :not_tracked}

  defp update_tracked(tracked, attrs) do
    case Ash.update(tracked, attrs) do
      {:ok, _updated} -> :ok
      {:error, reason} -> {:error, reason}
    end
  rescue
    error -> {:error, error}
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
      font_family={Kati.Locale.face_prop()}
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
          {Sheet.header(Kati.Screens.DropSheet.heading(s))}
          {Kati.Screens.DropSheet.identity(s)}
          {Kati.Screens.DropSheet.position_card(s)}
          {Eyebrow.quiet(gettext("Why, if you like"))}
          {Kati.Screens.DropSheet.reasons(assigns.reason)}
          {Kati.Screens.DropSheet.info_card()}
          {Kati.Screens.DropSheet.keep_card(s)}
          {Kati.Screens.DropSheet.refusal(Map.get(assigns, :save_error))}
          {Kati.Screens.DropSheet.actions(s)}
          {Kati.Screens.DropSheet.trail(s, assigns.dropped?)}
        </Column>
      </Box>
    </Box>
    """
  end

  @doc """
  A drop the store refused, said out loud.

  Above the buttons and below the card they change, which is where screen 112
  puts its own. Every other write in this app that can fail now draws this
  band; this sheet was the last one that could not, and it is the one where
  the silence cost most — the reader was shown *Dropped* over a title that had
  not been.
  """
  @spec refusal(String.t() | nil) :: map()
  def refusal(nil), do: ~MOB"<Spacer size={0} />"

  def refusal(message) do
    assigns = %{message: message}

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.note("error", @message)}
      <Spacer size={14} />
    </Column>
    """
  end

  @doc """
  The poster, the title and the cold mark.

  Neither string is this screen's to translate — the title is a
  `Kati.Media.CachedTitle` row and the mark is built in `from_tracked/1` — but
  both are this screen's to typeset, and both can arrive in Persian:

    * `Kati.Locale.tracking/1` on the title's `-0.015em`. A Persian title is
      the same case as any other heading here — tightening a Latin face by a
      fraction of an em is a typographic tradition the Arabic script does not
      have, and Vazirmatn is not drawn for it.
    * `Kati.Locale.mono_face/1` on the mark, arity 1 so the STRING decides:
      `GONE COLD · 4 MONTHS` is pure Latin and keeps DM Mono, and
      **سردشده · 4 MONTHS** takes Vazirmatn at the same size rather than being
      handed to Android's own substitute face. `kati_mono.ttf` has no glyph
      for either half of that word.
  """
  @spec identity(map()) :: map()
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
            letter_spacing={Kati.Locale.tracking(-0.015)}
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={5} />
          <Text
            text={s.cold_label}
            font_family={Kati.Locale.mono_face(s.cold_label)}
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

  @doc """
  ` at S1 E3`, or nothing at all when there is no position.

  The film guard, and the half of it a device found: the header and the
  position card were the two obvious places a film differs, and the button and
  the undo pill build the same sentence out of the same two numbers. With them
  `nil` the button read **Drop at S E** and the pill **Dropped Dune at S E** —
  a position with the numbers missing, which is worse than no position.

  ## A phrase, and why the two sentences interpolate it rather than adding words

  `actions/1` and `undo_pill/2` each hold ONE msgid with a `%{at}` in it, and
  this is what goes in. That is deliberate: a phrase can be placed, and a word
  cannot. `Drop` + `at` + `S1 E3` bolted together left to right is an English
  sentence built out of three English facts, and the Persian for it puts the
  position before the verb — *رهاکردن در ف۱ ق۳* — which a translator can write
  only if the whole position arrives as one piece they are free to move.

  Keeping it one function is also what keeps #110 fixed in one place: the film
  guard is here, so a title with no position collapses both sentences rather
  than one of them.

  The leading space is added at the CALL SITE below and is not part of the
  msgid. `Kati.Screens.AnimeFilter` gives the reason for the same split: a
  msgid with a space on either end is a msgid a translator silently trims, and
  the trim shows up as two words run together on a page nobody reads twice.

      iex> Kati.Screens.DropSheet.at(%{season: 1, episode: 3})
      " at S1 E3"

      iex> Kati.Screens.DropSheet.at(%{season: nil, episode: nil})
      ""
  """
  @spec at(map()) :: String.t()
  def at(%{season: s, episode: e}) when is_integer(s) and is_integer(e) do
    " " <>
      pgettext("the position a drop is captured at, inside a sentence", "at S%{s} E%{e}",
        s: Kati.Locale.number(s),
        e: Kati.Locale.number(e)
      )
  end

  def at(_sheet), do: ""

  @doc """
  What this sheet is called, which is not the same word for a film.

  The sheet is series-shaped down to its header, so a
  film could not use it as drawn — the ledger's own note said *149 cannot be
  reused as drawn*. It can, once the two things that are actually about
  episodes come off it: this word, and the position card.

  Plain `gettext/1` on both, and `Drop this show` deliberately shares its msgid
  with `Kati.Screens.Series`'s own menu row — **رهاکردن این سریال** — rather
  than minting a contexted twin. An exact msgid always beats a fuzzy one, and
  a second Persian word for the one thing this sheet does would be the app
  disagreeing with the row that opened it.

      iex> Kati.Screens.DropSheet.heading(%{kind: :movie})
      "Drop this film"

      iex> Kati.Screens.DropSheet.heading(%{kind: :tv})
      "Drop this show"

      iex> Kati.Screens.DropSheet.heading(%{})
      "Drop this show"
  """
  @spec heading(map()) :: String.t()
  def heading(%{kind: :movie}), do: gettext("Drop this film")
  def heading(_sheet), do: gettext("Drop this show")

  @doc """
  Where the reader had got to — or nothing, on a film.

  A film has one position and it is *seen* or *not seen*, which the status
  already says. A card headed **Stopping at** over a blank would be a question
  with no answer, so it is dropped: a control with nothing behind it is not
  drawn dead.
  """
  @spec position_card(map()) :: map()
  def position_card(%{season: nil}), do: ~MOB"<Spacer size={0} />"
  def position_card(%{episode: nil}), do: ~MOB"<Spacer size={0} />"

  def position_card(s) do
    # `Kati.UI.eyebrow_label/1` rather than `String.upcase/1`: the Arabic
    # script has no case, so upper-casing **جای توقف** does nothing to it and
    # reads as a decision somebody made. `pgettext/2` because two words is
    # under the line where `mix gettext.merge` stops fuzzy-matching, and
    # because *stopping* alone is a word this app also uses about a timer.
    label = pgettext("the card holding the position a drop captures", "Stopping at")

    # The msgid `Kati.Screens.Stats` already draws — **ف%{s} ق%{e}**, ف for
    # فصل and ق for قسمت — so a position is spelled one way on every board
    # that names one. Plain `gettext/1` precisely BECAUSE the msgid exists: an
    # exact match always beats a fuzzy one, and a contexted twin here would be
    # a second Persian abbreviation for the same two nouns.
    #
    # `Kati.Locale.number/1` on both, and `mono_face/1` follows the result
    # rather than the reader: `S1 E3` is pure ASCII and stays in DM Mono at the
    # drawing's own 20pt, and `ف۱ ق۳` cannot — `kati_mono.ttf` carries neither
    # the letters nor U+06F0–U+06F9.
    position =
      gettext("S%{s} E%{e}",
        s: Kati.Locale.number(s.season),
        e: Kati.Locale.number(s.episode)
      )

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
            text={Kati.UI.eyebrow_label(label)}
            font_family={Kati.Locale.mono_face(label)}
            text_size={10}
            letter_spacing={Kati.Locale.tracking(0.14)}
            text_color={Palette.eyebrow()}
            max_lines={1}
          />
          <Spacer size={7} />
          <Text
            text={position}
            font_family={Kati.Locale.mono_face(position)}
            text_size={20}
            font_weight="medium"
            letter_spacing={Kati.Locale.tracking(-0.02)}
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

  @doc """
  Two discs, back and forward, where there was one pill that only went back.

  `Change` named neither direction and did one, so
  overshooting meant closing the sheet. Two discs say which way each goes
  before it is pressed, which one word never could.

  Each is `Kati.UI.symbol/2` at the same 30pt the pill was, so the row's height
  and the card's geometry are unchanged.
  """
  @spec change_pill() :: map()
  def change_pill do
    ~MOB"""
    <Row align="center">
      {Kati.Screens.DropSheet.step_disc("remove", :step_back)}
      <Spacer size={8} />
      {Kati.Screens.DropSheet.step_disc("add", :step_forward)}
    </Row>
    """
  end

  @doc false
  def step_disc(glyph, tag) do
    assigns = %{glyph: glyph, tap: {self(), tag}}

    ~MOB"""
    <Row
      width={30}
      height={30}
      corner_radius={15}
      background={Palette.paper()}
      align="center"
      on_tap={@tap}
    >
      <Spacer weight={1.0} />
      {Kati.UI.symbol(@glyph, size: 16, color: Palette.ink())}
      <Spacer weight={1.0} />
    </Row>
    """
  end

  @doc "A reason key as its tap tag — `:too_slow` becomes `:reason_too_slow`."
  @spec reason_tag(atom()) :: atom()
  def reason_tag(key) when is_atom(key), do: :"reason_#{key}"

  @doc "The reason a tap tag names, or `nil` when the tag is not one of the six."
  @spec reason_for(atom()) :: atom() | nil
  def reason_for(tag) when is_atom(tag) do
    # `@reason_keys` and not `reason_table/0`: a tap carries a key and answers
    # with a key, so looking the six labels up — which now means six catalogue
    # reads — to throw all six away would be work for nothing.
    Enum.find_value(@reason_keys, fn key ->
      if Kati.Screens.DropSheet.reason_tag(key) == tag, do: key
    end)
  end

  @doc "The six chips, chunked 4-then-2 — see the moduledoc for the measurement."
  @spec reasons(atom() | nil) :: map()
  def reasons(selected) do
    rows =
      reason_table()
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

  @doc """
  The dashed card: one tap, never mandatory.

  Three runs, three msgids, and the spaces between them are added at the call
  site rather than carried inside one — see `at/1` for why a msgid does not
  keep its own edges. The first two take `pgettext/2` because neither is long
  enough to be safe alone; the third is a whole sentence and needs nothing.

  `Kati.Locale.leading/1` rather than the drawing's flat 1.65: Vazirmatn's
  ascenders and the diacritics above them are not Plus Jakarta's, and this is
  the longest paragraph on the sheet. `base: true` stays where it was, on the
  first run, which is what keeps the paragraph body-weight when Persian
  changes which run is longest — `Kati.UI.rich_text/1` picks the longest
  otherwise, and that is a fact about English rather than about the sentence.
  """
  @spec info_card() :: map()
  def info_card do
    body = [
      text_size: 12.5,
      line_height: Kati.Locale.leading(1.65),
      text_color: Palette.ink_soft()
    ]

    strong = [
      text_size: 12.5,
      line_height: Kati.Locale.leading(1.65),
      font_weight: "semibold",
      text_color: :on_surface
    ]

    tail =
      gettext(
        "— a required reason is a reason people lie about. A drop with no chip is complete, not unfinished."
      )

    runs = [
      {pgettext("the drop sheet's info card, before its bolded run", "One tap,") <> " ",
       Keyword.put(body, :base, true)},
      {pgettext("the drop sheet's info card, its bolded run", "never mandatory"), strong},
      {" " <> tail, body}
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

  @doc """
  The cream-less card: keeping it clears Gone cold and nothing else.

  Same three-run shape as `info_card/0`, and the same argument for the spaces,
  for `base: true` and for `Kati.Locale.leading/1`.

  The middle run is the OTHER button's words, so it goes through
  `Kati.Locale.quoted/1` rather than carrying `“` and `”` inside its msgid.
  Persian quotes with the guillemets — **«نه، هنوز دنبالش هستم»** — and a
  reader meets `“…”` as a foreign mark; putting the marks outside the msgid
  also stops a translator having to decide, and stops two of the three ending
  up mismatched. `Kati.Books.Note.display/1` is the other caller and this is
  the same question about a different quotation.

  `Gone cold` inside the sentence is the app's own **سردشده**, the word
  `Kati.Screens.ShelfFilters` and `Kati.Screens.DropStates` already use for
  the status this button clears.
  """
  @spec keep_card(map()) :: map()
  def keep_card(sheet \\ %{cold_label: ""}) do
    body = [
      text_size: 12.5,
      line_height: Kati.Locale.leading(1.6),
      text_color: Palette.ink_soft()
    ]

    strong = [
      text_size: 12.5,
      line_height: Kati.Locale.leading(1.6),
      font_weight: "semibold",
      text_color: :on_surface
    ]

    still =
      Kati.Locale.quoted(
        pgettext("the keep card, quoting the button beside it", "No, I’m still on it")
      )

    runs = [
      {pgettext("the drop sheet's keep card, before its bolded run", "Or keep it —") <> " ",
       Keyword.put(body, :base, true)},
      {still, strong},
      {" " <> Kati.Screens.DropSheet.keep_effect(sheet), body}
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

  @doc """
  What *still on it* actually does, which depends on whether there is a mark to
  clear.

  The sentence was *"clears the Gone cold mark and changes nothing else"* on
  every sheet. Once `mark/1` stopped putting a cold mark on a show being watched
  normally, that left the card promising to clear something the reader could not
  see — which is the same defect as the mark itself, one sentence over: the page
  describing a state it is not in.

  So it is the app's own **سردشده** when the mark is there, and *changes nothing
  at all* when it is not, which is the honest reading of a button whose whole
  job on a fresh show is to close the sheet.
  """
  @spec keep_effect(map()) :: String.t()
  def keep_effect(%{cold_label: ""}),
    do: gettext("changes nothing at all.")

  def keep_effect(_sheet),
    do: gettext("clears the Gone cold mark and changes nothing else.")

  @doc """
  `Drop at S# E#` beside `Still on it` — the board's own two-button row.

  One msgid for the commit button, with the position interpolated into it —
  see `at/1` for why the position arrives as a phrase and not as words. Two
  msgids (one with the position, one without) would put the
  film guard in a second place, and the pill below would then need a
  third and a fourth.

  `pgettext/2` on both: *Drop* is one word, *Still on it* is three, and the
  catalogue already holds `Dropping`, `Dropped` and `Drop this show` for a
  merge to reach for.
  """
  @spec actions(map()) :: map()
  def actions(s) do
    at = Kati.Screens.DropSheet.at(s)
    label = pgettext("the drop sheet's own commit button", "Drop%{at}", at: at)

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
            text={pgettext("the second button on the drop sheet", "Still on it")}
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
      {Eyebrow.quiet(gettext("After you drop it"))}
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

  One msgid holding both the title and the position, rather than a verb with
  two things concatenated after it. Persian puts the verb last — *«…» در ف۱ ق۳
  رها شد* — so a sentence assembled left to right here could not be written in
  it at all; with both as bindings the msgstr places them where its own grammar
  wants them.

  `Kati.Locale.ltr/1` on the title because this is the one place a title sits
  INSIDE a sentence rather than on a line of its own. A full stop, a colon or a
  bracket is direction-neutral in the bidi algorithm and takes the paragraph's
  direction, so `Dune: Part Two` in a right-to-left sentence comes back with
  the colon against the wrong side of the name. An isolate is Unicode's own
  answer and needs nothing from the bridge.

  The `undo` glyph is NOT mirrored. `Kati.Locale.forward_glyph/0` exists for a
  picture that means *where the reader is going*, and this one means *take that
  back* — `Kati.Screens.ShelfSelection` and `Kati.Screens.MedicationDetail`
  both draw the same pill in both languages with the same glyph, and a third
  answer here would be this sheet disagreeing with the other two undo bars.
  """
  @spec undo_pill(map(), boolean()) :: map()
  def undo_pill(s, live?) do
    at = Kati.Screens.DropSheet.at(s)

    text =
      pgettext("the undo pill's sentence after a drop", "Dropped %{title}%{at}",
        title: Kati.Locale.ltr(s.title),
        at: at
      )

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
    # Plain `gettext/1`: `Undo` is one word, and normally that is exactly what
    # `pgettext/2` is for — but the msgid already exists and is already
    # **برگرداندن** on `Kati.Screens.ShelfSelection`'s own undo bar. An exact
    # match beats a fuzzy one, and every undo in this app should say the same
    # word. The same call `Kati.Screens.DropStates`'s `Finished` makes.
    ~MOB"""
    <Text
      text={gettext("Undo")}
      text_size={12.5}
      font_weight="bold"
      text_color={Palette.accent()}
      max_lines={1}
    />
    """
  end

  @impl true
  def handle_info({:tap, :close}, socket), do: {:noreply, Kati.Screens.Resume.pop(socket)}

  def handle_info({:tap, :step_forward}, socket) do
    {:noreply, Mob.Socket.update(socket, :sheet, &Kati.Screens.DropSheet.step_forward/1)}
  end

  def handle_info({:tap, :step_back}, socket) do
    {:noreply, Mob.Socket.update(socket, :sheet, &Kati.Screens.DropSheet.step_back/1)}
  end

  def handle_info({:tap, tag}, socket) when tag in @reason_tags do
    key = Kati.Screens.DropSheet.reason_for(tag)
    next = if socket.assigns.reason == key, do: nil, else: key
    {:noreply, Mob.Socket.assign(socket, :reason, next)}
  end

  # `dropped?` follows the WRITE, not the tap. Flipping the sheet to its
  # *Dropped* face over a refusal announces a change that was
  # not made, and it was the only thing this handler did with the result.
  def handle_info({:tap, :drop}, socket) do
    written = Kati.Screens.DropSheet.commit_drop(socket)

    {:noreply, Mob.Socket.assign(written, :dropped?, is_nil(written.assigns.save_error))}
  end

  # A refused *still on it* stays on the sheet to say so. Popping would take
  # the message with it and land the reader back on a page that had not
  # changed, with nothing to explain why.
  def handle_info({:tap, :keep}, socket) do
    written = Kati.Screens.DropSheet.commit_keep(socket)

    if written.assigns.save_error,
      do: {:noreply, written},
      else: {:noreply, Kati.Screens.Resume.pop(written)}
  end

  def handle_info({:tap, :undo}, socket) do
    written = Kati.Screens.DropSheet.commit_undo(socket)

    {:noreply, Mob.Socket.assign(written, :dropped?, not is_nil(written.assigns.save_error))}
  end

  def handle_info(_message, socket), do: {:noreply, socket}
end
