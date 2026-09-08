defmodule Kati.Screens.Rating do
  @moduledoc """
  Screen 33 — Log a watch: the rating, the review, and the context.

  Built to `test/design/screens/33.html`. It carries its own dismissal —
  a `close` disc and a **Save** pill, not the pushed back pill — because it is
  a sheet you either commit or abandon, and a back arrow says neither. Screen
  06 is the precedent. No dock, so the frame closes at 40 rather than 132.

  The design's caption names what the screen is for: *"half stars, a 10-point
  alternative, a real review body with a spoiler toggle, and the context that
  makes a log worth keeping — where you were and who you were with."*

  ## The stars are glyphs, not characters

  The drawing prints the rating as literal text — `★★★★` at 30px, then a
  fifth `★` clipped to 50% width, and a scale toggle labelled `5★`. Plus
  Jakarta Sans carries no U+2605, so on the device those render as nothing at
  all: the defect screen 08 hit, and fixed the same way. Every star here is
  therefore the Material Symbols `star` glyph, which is definitely in Kati's
  subset, and the substitution costs the drawing nothing:
  `Kati.ScreenDesignLiteralTest` reads `★` and `☆` as that glyph before it
  compares, and finds the row in the rendered tree once whitespace is thrown
  away — the drawing writes the rating as one run where this screen draws a
  separate `Text` per star, which is the reason that tier exists at all. The
  three literals printed a few lines up are a leftover of the check that came
  before: they were put in this comment so a grep over the *source* would find
  them, and a test that reads the rendered tree has no use for a comment. They
  stay because they are still the clearest way to say what the drawing prints.

  ## The half star is outlined, not halved — the font has no half

  **The gap, stated:** Kati's icon subset carries `star` and nothing called
  `star_half`, and `Kati.Icons.glyph!/1` raises for a name the font does not
  have, so there is no half glyph to ask for. Closing this properly means
  adding `star_half` to the design's icon set, running `mix kati.gen.icons`,
  and re-running the pyftsubset step over the variable font — `lib/kati/icons.ex`
  and `priv/`, not this screen. Until then the half slot is the same `star`
  glyph at **FILL 0**: an outlined star in the accent, beside four filled ones
  and the printed 4.5. A fifth *filled* star would read as five, and rounding
  a rating up silently is the one thing a screen that exists to record ratings
  must not do.

  Cropping half a glyph — the drawing's own construction, a grey star with an
  orange one over it in a box half as wide — is not reachable from Elixir in
  this bridge. Every `Text` is built with `TextOverflow.Ellipsis` always on
  (`MobBridge.kt:2772`), and Compose coerces a child into its parent's
  constraints, so a 26sp glyph in a 13dp box is not cropped to half a star: it
  is *measured* at 13dp, becomes one unbreakable character too wide for its
  line, and is ellipsised away to nothing. `corner_radius` switches
  `Modifier.clip` on (`MobBridge.kt:3925`) but clip only governs painting, not
  measurement. The previous version fed the orange glyph through a horizontal
  `Scroll` — the one node here that measures its content unbounded — and still
  painted nothing on the device, which is what retired the construction: an
  effect no one can verify from this side of the bridge does not belong in a
  screen.

  The fifth star is therefore the same `Kati.UI.symbol/2` call as the other
  four, same size and family, so it shares their line box by construction
  rather than by a stacked `Box` whose height has to be guessed at.

  ## What is a component here, and what still is not

  Five of this screen's parts are now the vendored Chelekom component that
  names them, because five props landed upstream that they had been missing —
  `shadow`, `border_color`/`border_width`, `height` and per-axis padding:

    * `close_disc/1` — `Kati.Components.MishkaCloseButton`, filled, with
      `Kati.Theme.shadow_button()`. A floating disc is *defined* by its shadow;
      with no `shadow` prop the component could only draw a flat patch, which
      is why this was a hand-rolled `Box` until now.
    * `save_pill/0`, `tag/1`, `add_tag/0`, `rewatch/1` —
      `Kati.Components.MishkaPill`.

  **`MishkaChip` draws none of the four tags**, which is worth stating because
  a filter chip is the obvious guess. It has no `shadow`, and every tag here is
  a lifted `Kati.Theme.shadow_card_soft()` card; it has no `border_color` and no
  `border_width`, and *+ tag* is a ring with no fill. Both gaps are the same
  shape as the ones just closed on `MishkaPill`, and both belong upstream.

  **`MishkaSegmentedControl` cannot draw `scale_toggle/0`**, for two reasons
  that are independent of each other:

    1. **No gap between segments.** The drawing sets the two segments 3pt apart
       inside the track; the component lays its segments in a bare `Row` with
       nothing between them and offers no spacing prop. Flush segments are
       different pixels, not a different taste.
    2. **A segment's content is a string.** `5★` is a numeral *plus a Material
       Symbols glyph in the symbols face*, and an option carries only `id`,
       `label` and `disabled` — no trailing slot, no per-segment
       `font_family`. Handing the glyph in as the label would typeset it in
       Plus Jakarta Sans, which does not have it.

  ## The caret is the field's own now

  The review body used to end with the design's 2x16 orange text cursor, drawn
  as a `Box` on the line below — there is no inline node in this bridge, so a
  caret beside a wrapping `Text` is a sibling rather than a run, and the line
  below is where a cursor lands when a line ends exactly at its edge. It was a
  picture of a caret in front of nothing that could type.

  The body is a `<TextField>`, so the caret is real and the drawn one is gone.
  Two carets would have been one too many, and the drawn one is the one that
  cannot move.

  **What the field costs, stated:** `MobTextField` is `singleLine = true`
  (`MobBridge.kt:3543`) and takes no multiline prop, and it paints Material's
  own container rather than the cream this card is — the same two facts
  `Kati.Screens.Backup.passphrase_field/1` records. So a long review scrolls
  inside one line instead of wrapping into the paragraph the drawing shows.
  That is a real loss of fidelity and it is taken deliberately: a review nobody
  can type is not a review, and the alternative on offer was another picture.
  Both are one prop on the bridge away and belong there, not here.

  ## Which half of a write path this is: it reads a watch, and writes it back

  `Kati.Media.Watch` models this sheet column for column — rating, review,
  `contains_spoilers`, `rewatch_number`, `watched_on` beside `watched_at`,
  `service`, `place`, `companions`, `tags` — and its own moduledoc names screen
  33 four times over. So the question was not *whether* this screen belongs to
  that resource but *which direction*, and the answer is now **both**.

  **The drawing is a filled-in sheet, and only a stored watch can fill it.** The
  rating is set, the review is typed, the spoiler toggle is on, three context
  rows have values and three tags are attached. A sheet composing a *new* watch
  has none of that: it is five empty cards, which is not this drawing and not
  anything screen 27's empty state would call a state either. The only thing in
  the app that looks like this picture is a watch that already exists — so this
  screen reads the newest one and shows it, which is what reopening a log to
  edit it looks like.

  **So Save UPDATES that watch, and cannot create a second one.** A sheet that
  reopens a log and commits a new row would answer "I changed my mind about the
  rating" with two contradictory logs of one night, and screen 15's activity
  list would show both. `save_watch/1` therefore starts from the id the sheet
  mounted with, and `Kati.RatingWriteTest` pins the consequence directly:
  rate, save, rate again, save again, one row.

  **Every value the sheet draws is editable now.** Each star carries two tap
  targets — left half and right half, which is precisely what the drawing's own
  `TAP LEFT OR RIGHT OF CENTRE` promises — so the ten of them address
  `Kati.Media.Watch.rating`'s ten points one for one, and the review is a real
  field. This paragraph used to end *`contains_spoilers`, the three context
  rows and `:add_tag` are still drawn and still inert*, and each of those has
  since been given the control it was waiting for: the spoiler line toggles
  (`:toggle_spoilers`), the three rows disclose one at a time (#95), and the
  tag field opens on `:add_tag` and commits on `:commit_tag` (#96). Each is
  live only when the sheet has a row behind it — `writable?/1` — because a
  control over a drawn page would be editing nothing.

  ## What the tap sweep does with a Save that writes

  `Kati.ScreenTapSweepTest` taps **every** control **every** screen draws, in
  both locales, against the one shared SQLite file — the suite has no Ecto
  sandbox. The version of this moduledoc that predicted `:save` would start
  creating `Kati.Media.Watch` rows for every other sweep to render was right
  about the risk and wrong about the fix: no scratch database is needed, because
  a save that can only UPDATE has nothing to leave behind.

  With nothing logged — which is what the sweep sees, since every test that
  writes a watch empties the table on the way out — the sheet is the drawing,
  there is no id, and `save_watch/1` answers `{:error, :nothing_to_save}`.
  Refusing to write is the honest answer rather than a concession to the sweep:
  the values on screen belong to `Kati.Rating.Sample`, and committing them would
  file the drawing's own review under somebody's name. With a watch present the
  sweep writes back to that watch what it had just read from it.

  ## Where the watch comes from

  Nothing hands this screen an id — `Kati.Screens.Gallery` pushes it with no
  watch attached, exactly as it pushes `Kati.Screens.Film` with no film — so the
  referent is chosen here and stated: **the newest watch that carries a rating
  or a review**, which is the newest thing the user actually *logged* as opposed
  to *ticked*. `Kati.Media.Watch` is explicit that a tick and a log are one row
  shape at two levels of detail; a tick has no rating, no review and no context,
  so a sheet drawn from one would be five empty cards for a second reason.

  Three reads, never one per row: that watch, its durable row (loaded with it),
  and the one cache row that row names — by `{source, source_id}` as a **value
  pair**, so an evicted poster cannot take the user's own review down with it.

  With nothing logged there is no such watch and `Kati.Rating.Sample` is drawn
  instead, the values `test/design/screens/33.html` was captured from.
  FIDELITY's rule: *missing data is not a reason for a blank screen*. The Sample
  module stays exactly where it is; it is the fallback and the fixture, not a
  stage this screen has passed through.

  ### What no resource can express, and is therefore not drawn

    * **`2025` in the meta line.** The same gap `Kati.Screens.Film` records:
      `Kati.Media.CachedTitle.next_release_at` is the NEXT release, and reading
      it as a first-release year would print next Tuesday's date as a film's
      year. The line degrades to `1H 52M`, which is `runtime_minutes` and
      nothing else.
    * **`HALF STARS ON`, and the `5★`/`10pt` toggle.** Both are display
      preferences — which scale the user reads ratings on — and no resource
      holds one. `Kati.Media.Watch.rating` is the ten-point integer either way,
      and screen 35's settings are where a scale preference would live. So both
      stay the drawing's, on a real watch as on the fallback, and the note is
      taken from the one place that copy lives rather than written out a second
      time here.

      The second half of that same line, `TAP LEFT OR RIGHT OF CENTRE`, is not
      a preference and is no longer a claim: it is what `star_cell/3` draws, and
      the reason the ten targets are half-star wide rather than five stars wide.
  """
  use Mob.Screen
  import Mob.Sigil

  require Ash.Query

  alias Kati.Components.MishkaCloseButton
  alias Kati.Components.MishkaPill
  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Media.Watch
  alias Kati.Rating.Sample
  alias Kati.Theme.Palette
  alias Kati.UI.SettingsList
  alias Kati.Write

  @doc """
  The sheet, opened on a watch and holding its id.

  `watch` is the DRAFT from here on: the stars and the field write into it and
  Save commits it, so it starts as what was read and diverges as it is edited.
  `watch_id` is what makes the commit an update — it is the row the draft came
  out of, and `nil` when the draft is the drawing's and there is no row.

  The id is carried rather than re-derived at save time, and that is the whole
  of what stops a second write landing on a different watch: `newest_log/1`
  answers "the newest log" at the moment it is asked, and a sheet left open
  while something else is logged would otherwise commit to whichever row won
  that race.

  ## The id and the draft come from the same place, or neither does

  `draft_and_id/1` returns both together, and it is the only way to get an id.
  Reading the row and shaping it are two steps that can fail *independently*:
  `logged_record/0` can find a watch and `shape/1` can still answer `nil`,
  because `shaped/3` reads a zone and a cache row and its rescue exists for
  exactly that. When it does, the sheet falls back to `Kati.Rating.Sample` — and
  an id carried past that point would leave the drawing's values sitting on the
  socket with a real row's id beside them.

  Measured, by making `shape/1` raise: the sheet drew "Blue Hour", Save reported
  success, popped, and replaced the user's own rating and review with the
  fixture's. Silently, because a save that lands is *supposed* to close. That is
  the same rule `save_watch/1` states for the no-row case — the drawing is never
  committed — and it has to hold for both ways of arriving at the drawing, not
  just the empty-database one. `watch/0`'s gate says it for the render:
  *either every value on it is this watch's or every value is the drawing's*.
  The id is one of those values.

  ## Which title the sheet is a log of

  `:tracked_title_id` in the push's params names it — `Kati.Screens.Film`'s
  "Log a watch" row puts the film on screen there, through `params_for/1`.
  Without the key, which is the gallery's door and every sweep's, the sheet
  draws the newest log in the library: the one answer it has ever given.
  """
  def mount(params, _session, socket) do
    Mob.Theme.set(Kati.Theme.current())
    tracked_id = Map.get(params || %{}, :tracked_title_id)
    {draft, id} = draft_and_id(logged_record(tracked_id), tracked_id)

    {:ok,
     socket
     |> Mob.Socket.assign(:watch, draft)
     |> Mob.Socket.assign(:watch_id, id)
     # Kept, where it used to be looked up and thrown away. `save_watch/1`
     # could only ever UPDATE, so a film with nothing logged against it
     # answered `{:error, :nothing_to_save}` and there was no way in the app
     # to say you had watched a film at all — which took the rating, the
     # review, the Activity log and Your year's Films count with it.
     |> Mob.Socket.assign(:tracked_title_id, tracked_id)
     |> Mob.Socket.assign(:save_error, nil)}
  end

  # The draft and the id it may be committed under. `nil` for the id whenever
  # the draft is the drawing's, by either route: no logged watch at all, or one
  # that could not be shaped.
  # Nothing logged yet, but a film was NAMED: a blank sheet about that film.
  #
  # It used to answer the drawing here whatever it had been handed, and on a
  # device that meant pressing *Log a watch* on **Arrival** opened a sheet
  # about **Blue Hour** — its poster, its `2nd rewatch`, its review, its tags,
  # its `Watched on Sun 16 Aug`, its `With Jo`. Pressing Save then wrote all
  # of it against Arrival's id, which is the whole of what this app must not
  # do. Found on a Pixel 9a the first time a film could be logged at all.
  #
  # `blank_for/1` is the sheet in the state a first watch is actually in:
  # this title, this poster, this runtime, no stars, no review, no tags, and
  # no claim about a night. The drawing is still the answer when NOTHING was
  # named — the gallery pushes with no params, and board 33 is what it must
  # draw.
  defp draft_and_id(nil, tracked_id) when is_binary(tracked_id) do
    case blank_for(tracked_id) do
      nil -> {drawn_watch(), nil}
      blank -> {blank, nil}
    end
  end

  defp draft_and_id(nil, _none), do: {drawn_watch(), nil}

  defp draft_and_id(logged, _tracked_id) do
    case shape(logged) do
      nil -> {drawn_watch(), nil}
      shaped -> {shaped, logged.id}
    end
  end

  @doc """
  The watch this sheet draws: the user's newest log, or the drawing's.

  The gate is the whole sheet rather than each card, for the reason
  `Kati.Screens.Film.film/0` gives: a page whose review is the user's own and
  whose title is somebody else's film reads as entirely real. Either every value
  on it is this watch's or every value is the drawing's.

  `title_id` is the title the push named. Without one there is no subject and
  the answer is the drawing — see `newest_log/1`, which used to run the query
  unnarrowed and hand back the newest rated watch anywhere in the library.
  """
  @spec watch(String.t() | nil) :: map()
  def watch(title_id \\ nil), do: shaped_or_drawn(logged_record(title_id))

  @doc """
  Screen 33 exactly as it is drawn, from `Kati.Rating.Sample`.

  Kept in the fixture rather than inlined here: it is the frame's specification
  and the value a test compares a real render against, and two copies of the
  drawing's copy is how the two drift apart.
  """
  @spec drawn_watch() :: map()
  def drawn_watch, do: Sample.watch()

  @doc """
  The user's newest log, shaped for the markup, or `nil` when there is not one.

  `nil` is the ordinary answer on a fresh install and the one `watch/0` reads as
  "draw the drawing". A database that cannot be read at all answers `nil` too —
  `Ash.read!` on a device mid-migration raises, and a sheet that dies is
  strictly worse than a sheet showing the values it was drawn from.
  """
  @spec logged_watch() :: map() | nil
  def logged_watch do
    case logged_record() do
      nil -> nil
      logged -> shape(logged)
    end
  end

  @doc """
  The newest logged watch as a ROW, or `nil` — the same answer `logged_watch/0`
  gives, one step earlier.

  `mount/3` needs the row and not only its shape, because the id is what makes
  Save an update. Reading it once and shaping it here is what keeps that from
  being a second query with a second chance to disagree.

  The rescue is the one `logged_watch/0` carried: `Ash.read!` on a device
  mid-migration raises, and a sheet that dies is strictly worse than a sheet
  showing the values it was drawn from.

  `title_id` narrows it to that title's newest log. No id is the question this
  function was always asked, and it answers what it always did.
  """
  @spec logged_record(String.t() | nil) :: Watch.t() | nil
  def logged_record(title_id \\ nil) do
    newest_log(title_id)
  rescue
    _ -> nil
  end

  @doc """
  The params that name a film to this sheet.

  Here rather than at screen 08 so the key is spelled once, the way
  `Kati.Screens.MealEdit` spells `:meal_id` once for its two doors.
  `:tracked_title_id` and not `:id`, because the id is not this sheet's own
  subject — a sheet is about a `Kati.Media.Watch`, and this names the title it
  must be a watch OF — and because that is the spelling `Kati.Media.Watch`
  itself uses.

  A film with no tracked row — the drawing's — yields `%{}`, which is what
  `Mob.Socket.push_screen/3` defaults to and what every bare push already sends.

      iex> Kati.Screens.Rating.params_for(%{tracked_id: "abc"})
      %{tracked_title_id: "abc"}

      iex> Kati.Screens.Rating.params_for(Kati.Screens.Film.drawn_film())
      %{}
  """
  @spec params_for(map() | nil) :: map()
  def params_for(%{tracked_id: id}) when is_binary(id), do: %{tracked_title_id: id}
  def params_for(_film), do: %{}

  @doc """
  A film you have watched is a film you have finished.

  Nothing in the reachable app could set a title's status: the only writer was
  `Kati.Screens.DropSheet`, which is gallery-only and writes `:watching`. So
  the shelf's chips read `Not started 0` and `Finished 0` on every device that
  has ever existed, every tile's caption said *watching*, and a film logged as
  seen still sat under *Continue watching* — the section for things you have
  not finished.

  Only for a FILM. A series is finished when its last episode is ticked, which
  is a different fact and belongs with the tick that establishes it; logging a
  watch of one episode says nothing about the other nine.

  A failure here does not fail the watch. The log is the thing the person
  asked for and it is already written; a status that did not move is a wrong
  caption, and losing the log to fix a caption would be the worse trade.
  """
  @spec finish_title({:ok, struct()} | {:error, term()}, String.t()) ::
          {:ok, struct()} | {:error, term()}
  def finish_title({:ok, _watch} = written, tracked_id) do
    with {:ok, %TrackedTitle{kind: :movie} = tracked} <- Ash.get(TrackedTitle, tracked_id) do
      tracked
      |> Ash.Changeset.for_update(:update, %{status: :finished})
      |> Ash.update()
    end

    written
  rescue
    _error -> written
  end

  def finish_title(other, _tracked_id), do: other

  @doc """
  The sheet for a film with nothing logged against it yet.

  Every field the markup reads, answered about THIS title and about nothing
  else: the title, the poster and the runtime off the cache, and then absence
  — no rating, no review, no spoiler flag, no context rows, no tags, and no
  rewatch line, because a first watch is not a rewatch.

  `nil` when the id names no row, which sends `draft_and_id/2` back to the
  drawing — the same rule `Kati.Screens.BookDetail.shelved_book/1` states: a
  title deleted under you draws the drawing, never somebody else's.
  """
  @spec blank_for(String.t()) :: map() | nil
  def blank_for(tracked_id) when is_binary(tracked_id) do
    case Ash.get(TrackedTitle, tracked_id) do
      {:ok, %TrackedTitle{} = tracked} ->
        cached = cached_for(tracked)

        %{
          title: title_of(cached),
          seed: seed_of(tracked, cached),
          meta: runtime_label(cached),
          rewatch: nil,
          rating: nil,
          rating_note: Sample.watch().rating_note,
          spoilers: nil,
          review: "",
          characters: characters_label(nil),
          # A first watch is being logged for tonight, which is what *Log a
          # watch* means. The row reads `Today` rather than blank, because a
          # field with today's date already in it is what a person about to
          # confirm it wants to see.
          watched_on: Kati.Time.today(),
          watched_at: Kati.Time.now(),
          service: nil,
          companions: nil,
          context: [],
          tags: [],
          live?: true
        }

      _gone ->
        nil
    end
  rescue
    _error -> nil
  end

  defp shaped_or_drawn(nil), do: drawn_watch()
  defp shaped_or_drawn(logged), do: shape(logged) || drawn_watch()

  defp shape(logged) do
    shaped(logged.tracked_title, cached_for(logged.tracked_title), logged)
  rescue
    _ -> nil
  end

  # The newest thing the user logged rather than ticked — see the moduledoc for
  # why a tick cannot fill this sheet. `watched_at` first because that is the
  # night the log is about; `inserted_at` behind it so a watch recorded with no
  # instant ("I have seen this, I do not remember when") still orders by when it
  # was written down rather than arbitrarily.
  # A push that named nothing gets NOTHING, and the sheet falls to its drawing.
  #
  # It used to run the query unnarrowed, so a sheet opened without a subject
  # showed the newest rated watch anywhere in the library — somebody else's
  # film, with their stars and their review, and a Save that would then edit
  # that row. Six of the seven doors into this sheet push it bare
  # (MOVIES-AND-TV.md #68), and the gallery's is a seventh.
  #
  # `nil` is the sheet's own documented no-row state and is safe: `watch/0`
  # gates the whole page on it, and `save_watch/1` refuses to commit the
  # drawing. Screen 08's door passes `params_for/1` and is unaffected.
  defp newest_log(nil), do: nil

  defp newest_log(title_id) do
    Watch
    |> Ash.Query.filter(not is_nil(rating) or (not is_nil(review) and review != ""))
    |> of_title(title_id)
    |> Ash.Query.sort(watched_at: :desc, inserted_at: :desc)
    |> Ash.Query.load(:tracked_title)
    |> Ash.Query.limit(1)
    |> Ash.read!()
    |> List.first()
  end

  # The narrowing, as a second `filter` rather than a third term inside the
  # first one: chained filters are ANDed, so the `or` above keeps its own
  # parentheses instead of being re-nested around a new `and`.
  defp of_title(query, title_id), do: Ash.Query.filter(query, tracked_title_id == ^title_id)

  # One read, by the VALUE PAIR the durable half references the cache by. A
  # missing row is the evicted case and is ordinary — see `shaped/3`.
  defp cached_for(%TrackedTitle{source: source, source_id: source_id}) do
    CachedTitle
    |> Ash.Query.filter(source == ^source and source_id == ^source_id)
    |> Ash.read_one!()
  end

  @doc """
  One logged watch in the shape the markup reads, whatever is missing.

  `cached` may be `nil` and every column on the watch but `contains_spoilers` is
  nullable; each absence is an ordinary state of a log and none of them is
  allowed to invent a value:

    * `title` is the cache's, and `Untitled` when the cache row has gone — the
      answer `Kati.Screens.Film` and `Kati.Screens.Activity` both give, because
      the review survived the wipe and the poster did not.
    * `rating` is the ten-point integer halved, so `9` is `4.5` and the row
      draws four stars and a half. `nil` for an unrated log, which
      `stars/1` draws as five empty stars and `rating_label/1` prints as a dash:
      that is what *you have not rated this* looks like, and it is a real state
      of a review the user wrote without scoring.
    * `rewatch` is `nil` below `2`. `rewatch_number` is the user's own count and
      `1` means a first watch, which is not a rewatch — `Kati.Media.Watch` keeps
      the column precisely because counting rows would say "1st" to someone who
      saw the film twice before Kati existed.
    * `spoilers` is `nil` when the review does not carry them, and the toggle
      draws nothing rather than an inverted claim: `contains_spoilers` says a
      review has spoilers to hide, and its `false` says nothing is hidden.
    * `characters` is counted off the review here, where the fixture stores it —
      `Kati.Rating.Sample` says why the drawing's own 184 is stored rather than
      derived, and that reason is about the drawing, not about a real review.
    * the three context rows are always drawn and their `sub` may be `nil`,
      which `Kati.UI.SettingsList.body/2` renders as a title alone. An editor
      with a field not yet filled in is exactly what a log with no place is.
  """
  @spec shaped(TrackedTitle.t(), CachedTitle.t() | nil, Watch.t()) :: map()
  def shaped(tracked, cached, logged) do
    zone = Kati.Time.device_zone()

    %{
      title: title_of(cached),
      seed: seed_of(tracked, cached),
      meta: runtime_label(cached),
      rewatch: rewatch_label(logged.rewatch_number),
      rating: logged.rating && logged.rating / 2,
      # A display preference with no resource behind it — see the moduledoc.
      rating_note: Sample.watch().rating_note,
      spoilers: if(logged.contains_spoilers, do: "Spoilers hidden"),
      review: logged.review || "",
      characters: characters_label(logged.review),
      # The values the three context rows edit, beside the rows themselves.
      # MOVIES-AND-TV.md #95: the rows were three chevrons over three real
      # columns, and a chevron is a promise that a screen opens. Rendering
      # derives the rows from these, so an edit changes one place and the row
      # under it reads back what was set.
      watched_on: log_date(logged, zone),
      watched_at: logged.watched_at,
      service: presence(logged.service),
      companions: presence(logged.companions),
      context: context_rows(logged, zone),
      tags: tag_list(logged.tags),
      # This draft has somewhere to be committed, and the drawing's has not.
      # The controls #96 wired read it rather than each deciding again: a
      # spoiler flag or a tag set on `Kati.Rating.Sample` would be an edit to a
      # picture, and pressing Save would refuse it with `nothing_to_save` after
      # the reader had already typed.
      live?: true
    }
  end

  @doc """
  Whether this draft has a row behind it, or is the drawing.

      iex> Kati.Screens.Rating.writable?(Kati.Screens.Rating.drawn_watch())
      false
  """
  @spec writable?(map()) :: boolean()
  def writable?(draft), do: Map.get(draft, :live?, false) == true

  defp title_of(%CachedTitle{title: title}) when is_binary(title) and title != "", do: title
  defp title_of(_cached), do: "Untitled"

  # `Kati.Seeds` writes the design's own seed into `poster_path` and
  # `sample_source_id/1` is the other half of that convention, so a row whose
  # cache has been evicted can still find its picture. A real provider path is
  # one `Kati.Design.Images.poster/1` will not find, and `poster/1` already
  # draws the placeholder rectangle for that.
  defp seed_of(tracked, cached) do
    case cached do
      %CachedTitle{poster_path: path} when is_binary(path) and path != "" -> path
      _ -> Kati.Seeds.sample_seed(tracked.source_id)
    end
  end

  # `2025 · 1H 52M` minus the year, which nothing stores. An unknown runtime
  # leaves the line empty rather than spelling the absence as a dash.
  defp runtime_label(%CachedTitle{runtime_minutes: m}) when is_integer(m) and m > 0 do
    case {div(m, 60), rem(m, 60)} do
      {0, minutes} -> "#{minutes}M"
      {hours, 0} -> "#{hours}H"
      {hours, minutes} -> "#{hours}H #{minutes}M"
    end
  end

  defp runtime_label(_cached), do: ""

  defp rewatch_label(n) when is_integer(n) and n > 1, do: "#{ordinal(n)} rewatch"
  defp rewatch_label(_n), do: nil

  defp ordinal(n) do
    suffix =
      cond do
        rem(n, 100) in 11..13 -> "th"
        rem(n, 10) == 1 -> "st"
        rem(n, 10) == 2 -> "nd"
        rem(n, 10) == 3 -> "rd"
        true -> "th"
      end

    "#{n}#{suffix}"
  end

  defp characters_label(review) when is_binary(review) do
    case String.length(review) do
      1 -> "1 character"
      n -> "#{n} characters"
    end
  end

  defp characters_label(_review), do: "0 characters"

  # The three facts that make a log worth keeping later — when, where, and who
  # with — in the drawing's own order. Always three rows: this is an editor, and
  # a field with nothing in it is a field with nothing in it, not a row to hide.
  defp context_rows(logged, zone) do
    [
      %{icon: "event", title: "Watched on", sub: when_label(logged, zone)},
      %{icon: "tv", title: "Where", sub: where_label(logged)},
      %{icon: "group", title: "With", sub: presence(logged.companions)}
    ]
  end

  # `Sun 16 Aug · 21:40`, and `Sun 16 Aug` for a watch that carries a date and
  # no hour. The two columns are separate on purpose — `watched_on` is
  # date-valued and storing it as midnight moves it a day the moment the user
  # flies — so the date is taken from whichever holds one and the hour only
  # from the instant, which is the only half that has one.
  defp when_label(logged, zone) do
    date = log_date(logged, zone)
    hour = log_hour(logged, zone)

    case {date, hour} do
      {nil, _hour} -> nil
      {date, nil} -> Calendar.strftime(date, "%a %-d %b")
      {date, hour} -> Calendar.strftime(date, "%a %-d %b") <> " · " <> hour
    end
  end

  defp log_date(%Watch{watched_on: %Date{} = date}, _zone), do: date

  defp log_date(%Watch{watched_at: %DateTime{} = at}, zone),
    do: at |> Kati.Time.in_zone(zone) |> DateTime.to_date()

  defp log_date(%Watch{}, _zone), do: nil

  defp log_hour(%Watch{watched_at: %DateTime{} = at}, zone),
    do: at |> Kati.Time.in_zone(zone) |> Calendar.strftime("%H:%M")

  defp log_hour(%Watch{}, _zone), do: nil

  # `Lumen+ · living room`. Stored apart even though the drawing writes them as
  # one line, because one of them is a thing stats can group by and the other is
  # a room in a house — so either half can be absent and the line closes up.
  defp where_label(%Watch{service: service, place: place}) do
    [service, place]
    |> Enum.map(&presence/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" · ")
    |> presence()
  end

  # Names and tags are stored as typed, comma-separated: Kati has no people
  # table and no contacts permission, and inventing either to hold the word
  # "Jo" would be a larger privacy decision than this row is asking for.
  defp tag_list(tags) when is_binary(tags) do
    tags |> String.split(",") |> Enum.map(&String.trim/1) |> Enum.reject(&(&1 == ""))
  end

  defp tag_list(_tags), do: []

  defp presence(value) when is_binary(value) do
    case String.trim(value) do
      "" -> nil
      trimmed -> trimmed
    end
  end

  defp presence(_value), do: nil

  def render(assigns) do
    w = assigns.watch
    save_error = assigns[:save_error]

    ~MOB"""
    <Box
      fill_width={true}
      fill_height={true}
      background={:background}
      layout_direction={Kati.Locale.direction_prop()}
      font_family={Kati.Locale.face_prop()}
      accessibility_id={Kati.Screens.Identity.of(__MODULE__)}
    >
      <Scroll>
        <Column
          fill_width={true}
          padding_left={21}
          padding_right={21}
          padding_top={64}
          padding_bottom={40}
        >
          {Kati.Screens.Rating.header()}
          {Kati.Screens.Rating.save_notice(save_error)}
          {Kati.Screens.Rating.title_card(w)}
          {Kati.Screens.Rating.rating_card(w)}
          {Kati.Screens.Rating.review_card(w)}
          {Kati.Screens.Rating.context_card(w)}
          {Kati.Screens.Rating.tags(w)}
        </Column>
      </Scroll>
    </Box>
    """
  end

  @doc false
  def header do
    close = {self(), :close}
    save = {self(), :save}

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        {Kati.Screens.Rating.close_disc(close)}
        <Spacer weight={1.0} />
        <Text
          text="Log a watch"
          text_size={15}
          font_weight="bold"
          text_color={:on_surface}
          max_lines={1}
        />
        <Spacer weight={1.0} />
        {Kati.Screens.Rating.save_pill(save)}
      </Row>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  The dismissal disc: `Kati.Components.MishkaCloseButton` at the drawing's own
  numbers.

  A close button is what this is, so it is spelled as one rather than as a
  fourth hand-rolled 44pt Box. `variant: :filled` paints the fill and
  **`shadow` is what makes it float** — a filled disc with no shadow is a flat
  patch, and this design's disc is `Kati.Theme.shadow_button()`. Until this
  round the component had no `shadow` prop at all, which is exactly why the
  Box stayed hand-rolled.

  The glyph goes in as a **child**, not through `icon:`. The `icon` shorthand
  builds a `Text` with no `font_family`, so the ✕ it defaults to would be
  typeset in Plus Jakarta Sans — which carries no U+2716 — and `"close"` would
  be typeset as the word. `Kati.UI.symbol/2` keeps the Material Symbols face
  and keeps `Kati.Icons.glyph!/1`'s raise for a name outside the subset.

  ## Why the pixels do not move

  The component builds
  `%{type: :box, props: %{width: 44, height: 44, align: :center,
  corner_radius: 22.0, background: …, shadow: …, on_tap: …}}` — every number
  this wrote by hand. `align: :center` and `align="center"` reach the bridge as
  the same string (`Mob.Renderer.encode_native_value/1` writes an atom as its
  own name), and `corner_radius` is read with `floatProp`, so `22.0` and `22`
  are one radius.

  The one structural difference is that children are wrapped in a `Row`
  (`MishkaActionIcon.glyph/3`). That `Row` is inert here: `MobBridge.kt`'s row
  branch is `Row(modifier = m, verticalAlignment = rowAlignProp(props))` with
  no `fillMaxWidth`, so a propless Row hugs its single child on both axes and
  the enclosing Box centres the same rectangle it centred before.
  """
  def close_disc(tap) do
    MishkaCloseButton.close_button(
      %{
        size: 44,
        shape: :circle,
        variant: :filled,
        background: Palette.card(),
        shadow: Kati.Theme.shadow_button(),
        on_tap: tap
      },
      [Kati.UI.symbol("close", size: 21)]
    )
  end

  @doc """
  The commit: `Kati.Components.MishkaPill` at the drawing's 38pt ink pill.

  ## `padding: 0` is load-bearing

  `MishkaPill` always writes a `padding` key, defaulting to `:space_sm`, and
  the bridge resolves an unspecified edge **against that uniform** rather than
  against zero (`MobBridge.kt`: `fun pad(v) = (v ?: uniform ?: 0)`). So
  `padding_left`/`padding_right` alone would leave the drawing's 38pt pill
  sitting inside two rows of `:space_sm`. Pinning `padding: 0` is what makes
  the two horizontal edges the only padding the pill has, which is what the
  hand-rolled Row had.

  ## The fill inverts, it does not follow

  Save is the sheet's call to action, so it takes the pair the design draws for
  an ink-filled control: `Palette.ink_fill/0` under `Palette.on_ink/0`. Screen 28
  draws that pair — `#1A1917` + `#FBFAF8` becomes `#F7EFE4` + `#1A1917`, the fill
  swapping sides of the ramp rather than darkening with the page.
  `Kati.Theme.ink/0` was the fill before and takes no mode, so in dark the pill
  and its label would both have been near-black.
  """
  def save_pill(tap) do
    MishkaPill.pill(
      label: "Save",
      background: Palette.ink_fill(),
      color: Palette.on_ink(),
      height: 38,
      corner_radius: 19,
      padding: 0,
      padding_left: 16,
      padding_right: 16,
      text_size: 13,
      font_weight: :bold,
      align: :center,
      on_tap: tap
    )
  end

  @doc """
  What a save that did not land says, directly under the button that failed.

  Under rather than over, and that is not the placement
  `Kati.Screens.QuickAddExpense.save_notice/1` argues for — it puts the sentence
  immediately *above* its commit row, because an error anywhere else on a
  scrolling page can be off-screen at the moment it appears. The reasoning is
  the same here and it lands on the other side: this sheet's commit is the pill
  in the header, at the top of the scroll, so the line adjacent to it and
  reachable without scrolling is the one below.

  Nothing at all when there is nothing to say. A `Spacer` of zero rather than
  `nil`, because every branch of a `~MOB` interpolation has to be a node.
  """
  @spec save_notice(String.t() | nil) :: map()
  def save_notice(nil), do: ~MOB"<Spacer size={0} />"

  def save_notice(message) do
    ~MOB"""
    <Column fill_width={true}>
      <Text
        text={message}
        text_size={13}
        font_weight="semibold"
        line_height={1.45}
        text_color={Palette.red()}
      />
      <Spacer size={16} />
    </Column>
    """
  end

  @doc false
  def title_card(w) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        {Kati.Screens.Rating.poster(w)}
        <Spacer size={14} />
        <Column weight={1.0}>
          <Text
            text={w.title}
            text_size={19}
            font_weight="bold"
            letter_spacing={-0.025}
            line_height={1.2}
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={6} />
          <Text
            text={w.meta}
            font_family="mono"
            text_size={10.5}
            text_color={Palette.muted()}
            max_lines={1}
          />
          <Spacer size={9} />
          {Kati.Screens.Rating.rewatch(w.rewatch)}
        </Column>
      </Row>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  The rewatch badge: `Kati.Components.MishkaPill` around a glyph and a count.

  A pill's content slot takes nodes, so the `replay` glyph keeps the Material
  Symbols face `Kati.UI.symbol/2` gives it — `label:` would have built a `Text`
  with no `font_family` and typeset the ligature as the word.

  The content lands in a bare `<Row>`, where the hand-rolled version wrote
  `align="center"`. Those are the same row: `MobBridge.kt`'s `rowAlignProp/1`
  answers `Alignment.CenterVertically` for everything that is not `"top"` or
  `"bottom"` — including an absent `align` — so the 13pt glyph and the 11pt
  count share a centre line either way.

  The fill is `Palette.paper/0`, not `Palette.tab_well/0`. Both are `0xFFEFECE7`
  in light and this badge sits directly on the page, so paper is the reading
  that keeps the badge the same colour as its ground in *both* modes — the
  relationship the drawing has. `tab_well/0` is deliberately darker than the
  page and belongs to the dock's active tab, which this is not.
  """
  # A first watch is not a rewatch, so there is no badge to draw — see
  # `shaped/3` on why `rewatch_number` of 1 (or of nothing) answers `nil`. The
  # 9pt spacer above stays where it is: it belongs to the block, and taking it
  # away with the badge would move the meta line up on a real log.
  def rewatch(nil), do: ~MOB"<Spacer size={0} />"

  def rewatch(label) do
    text = ~MOB"""
    <Text
      text={label}
      text_size={11}
      font_weight="semibold"
      text_color={Palette.ink_soft()}
      max_lines={1}
    />
    """

    gap = ~MOB"<Spacer size={5} />"

    MishkaPill.pill(
      %{
        background: Palette.paper(),
        height: 24,
        corner_radius: 12,
        padding: 0,
        padding_left: 10,
        padding_right: 10,
        align: :center
      },
      [Kati.UI.symbol("replay", size: 13, color: Palette.sub()), gap, text]
    )
  end

  @doc false
  def poster(w) do
    case Sample.poster(w.seed) do
      nil ->
        ~MOB"<Box width={74} height={106} corner_radius={10} background={Palette.placeholder()} />"

      src ->
        ~MOB"""
        <Image src={src} width={74} height={106} corner_radius={10} content_mode="fill" />
        """
    end
  end

  @doc false
  def rating_card(w) do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={18}
      >
        <Row fill_width={true} align="center">
          <Text
            text={String.upcase("Rating")}
            font_family="mono"
            text_size={10.5}
            letter_spacing={0.16}
            text_color={Palette.eyebrow()}
            max_lines={1}
          />
          <Spacer weight={1.0} />
          {Kati.Screens.Rating.scale_toggle(Kati.Screens.Rating.writable?(w))}
        </Row>
        <Spacer size={14} />
        <Row fill_width={true} align="center">
          {Kati.Screens.Rating.stars(w.rating, true)}
          <Spacer size={12} />
          <Text
            text={Kati.Rating.Scale.label(w.rating, Map.get(w, :scale))}
            font_family="mono"
            text_size={14}
            font_weight="medium"
            text_color={:on_surface}
            max_lines={1}
          />
        </Row>
        <Spacer size={10} />
        <Text
          text={w.rating_note}
          font_family="mono"
          text_size={10.5}
          text_color={Palette.muted()}
          max_lines={1}
        />
      </Column>
      <Spacer size={14} />
    </Column>
    """
  end

  # The track is `Palette.paper/0`. It is `0xFFEFECE7` — the page colour — sunk
  # into a `Palette.card/0` card, so in dark it goes to `#121110` against the
  # card's `#1E1D1B` and stays the well it is. `Palette.tab_well/0` carries the
  # same light value and is the other reading, but it is the dock's active-tab
  # disc and is deliberately DARKER than the page; this is a trough, not a tab.
  @doc """
  The `5★` / `10pt` toggle, lit from the stored preference.

  MOVIES-AND-TV.md #96. It was drawn from `Kati.Rating.Sample.scales/0` with
  its first tile hardcoded `on` and no tap on either, and the moduledoc argued
  that was right because no resource holds a display preference. No Ash
  resource does and none should — see `Kati.Rating.Scale`, which keeps it where
  `Kati.Locale` keeps the locale.

  The tiles are built here rather than read from the fixture now, because the
  fixture cannot know which one is lit; their labels still come from it, so the
  drawing stays the source of the copy.
  """
  @spec scale_toggle(boolean()) :: map()
  def scale_toggle(live? \\ false) do
    active = Kati.Rating.Scale.current()

    tiles =
      Kati.Rating.Scale.supported()
      |> Enum.zip(Sample.scales())
      |> Enum.map(fn {scale, drawn} ->
        Kati.Screens.Rating.scale(%{drawn | on: scale == active}, live?)
      end)
      |> Enum.intersperse(Kati.Screens.Rating.scale_gap())

    ~MOB"""
    <Row background={Palette.paper()} corner_radius={11} padding={3} align="center">
      {tiles}
    </Row>
    """
  end

  @doc false
  def scale_gap, do: ~MOB"<Spacer size={3} />"

  # Both tiles keep their tap, the lit one included, for the reason screen 35's
  # status tiles and screen 34's order tiles do: pressing the scale you are
  # already on is how somebody checks which one that is, and a tile that goes
  # dead once chosen stops answering exactly when it is pressed to be sure.
  @doc false
  def scale(option, live? \\ false)

  def scale(%{on: true} = option, live?) do
    assigns = %{tap: if(live?, do: Kati.Screens.Rating.scale_tap(option.label))}

    ~MOB"""
    <Row
      height={24}
      corner_radius={8}
      background={Palette.card()}
      shadow="0 1 2 0 #1F1A1917"
      padding_left={10}
      padding_right={10}
      align="center"
      on_tap={@tap}
    >
      <Text
        text={option.label}
        text_size={10.5}
        font_weight="semibold"
        text_color={:on_surface}
        max_lines={1}
      />
      {Kati.Screens.Rating.scale_star(option.star, Palette.ink())}
    </Row>
    """
  end

  def scale(option, live?) do
    assigns = %{tap: if(live?, do: Kati.Screens.Rating.scale_tap(option.label))}

    ~MOB"""
    <Row
      height={24}
      corner_radius={8}
      padding_left={10}
      padding_right={10}
      align="center"
      on_tap={@tap}
    >
      <Text
        text={option.label}
        text_size={10.5}
        font_weight="semibold"
        text_color={Palette.eyebrow()}
        max_lines={1}
      />
      {Kati.Screens.Rating.scale_star(option.star, Palette.eyebrow())}
    </Row>
    """
  end

  @doc """
  A scale tile's tap, keyed by the label the drawing gives it.

      iex> {_pid, tag} = Kati.Screens.Rating.scale_tap("10pt")
      iex> tag
      :scale_10pt
  """
  @spec scale_tap(String.t()) :: {pid(), atom()}
  def scale_tap(label), do: {self(), String.to_atom("scale_" <> label)}

  @doc false
  @spec scale_from(String.t()) :: :stars | :points | nil
  def scale_from("5"), do: :stars
  def scale_from("10pt"), do: :points
  def scale_from(_other), do: nil

  @doc false
  def scale_star(false, _color), do: ~MOB"<Spacer size={0} />"

  # No gap and no wrapping Row: the drawing's badge is a single text run, `5★`,
  # and the 1dp Spacer that used to sit between them read as "5 ★". The pill's
  # own Row is already align="center", so the glyph centres against the numeral
  # without a second one.
  def scale_star(true, color), do: Kati.UI.symbol("star", size: 11, color: color, fill: true)

  @doc """
  The number beside the stars, in the scale the row draws.

  `4.5` prints as `4.5` and `4.0` as `4`, because a whole rating is a whole
  number on a five-star row and `.0` reads as a precision nobody claimed. An
  unrated log prints the em dash `Kati.Screens.Stats` uses for the same absence
  in `Avg ★` — the card is the user's own rating and is never hidden, so it says
  "not rated" rather than "0".

  On the ten-point scale the same nine prints `9`. `Kati.Rating.Scale` owns
  both readings and every screen that prints a rating routes through it, so the
  numeral beside an episode on 04 cannot disagree with the numeral on the sheet
  that wrote it.
  """
  @spec rating_label(number() | nil) :: String.t()
  defdelegate rating_label(value), to: Kati.Rating.Scale, as: :label

  @doc """
  The five-star row, tappable or not.

  Five empty stars for `nil`, which is what "you have not rated this" looks
  like — `Kati.Screens.Film.star_count/1` gives the same answer for the same
  reason.

  **`tappable?` defaults to false, and the default is the one that matters.**
  `Kati.Screens.RateEpisode` calls this function rather than redrawing the
  half-star crop, and screen 144 has no rating write of its own: taps drawn
  there would be ten controls answered by that screen's `handle_info(_msg, …)`
  catch-all, which is a dead control the compiler cannot see and
  `Kati.ScreenTapSweepTest` reports as inert. So the taps belong to the screen
  that asks for them, and the shared drawing stays a drawing.
  """
  @spec stars(number() | nil, boolean()) :: map()
  def stars(value, tappable? \\ false)

  def stars(nil, tappable?), do: stars(0, tappable?)

  def stars(value, tappable?) do
    full = trunc(value)
    half? = value - full >= 0.5

    cells =
      1..5
      |> Enum.map(fn i ->
        slot =
          cond do
            i <= full -> :full
            i == full + 1 and half? -> :half
            true -> :empty
          end

        Kati.Screens.Rating.star_cell(slot, i, tappable?)
      end)
      |> Enum.intersperse(Kati.Screens.Rating.star_gap())

    ~MOB"""
    <Row align="center">
      {cells}
    </Row>
    """
  end

  @doc """
  One star, with the two tap targets the drawing's own caption promises.

  `HALF STARS ON · TAP LEFT OR RIGHT OF CENTRE` is printed under this row, and
  until now it described nothing. It describes this: a transparent 13x26 `Box`
  over each half of the glyph, the left one carrying the odd point and the
  right one the even, so the five stars address `Kati.Media.Watch.rating`'s
  **1..10** one target per point. Five targets would have made the ten-point
  column reachable only at even values and quietly turned every half rating a
  user had already stored into an unreachable one.

  The targets are stacked over the glyph rather than replacing it, because a
  half star is already two glyphs in one `Box` (see `star/1`) and the tap
  geometry is not the paint geometry: the left target covers the left half of
  the star whether that half is filled, outlined or empty. A `Box` renders its
  children back to front and Compose hit-tests them front to back, so the
  targets sit last.

  No `background`, and it is not an oversight: `Modifier.clickable` makes a node
  hit-testable by its bounds, not by its pixels, so an unpainted target is a
  target. Painting one would put a rectangle over the star.

  ## `fill_width={false}` on the wrapper, and no width — Dynamic Type

  The obvious wrapper is `<Box width={26} height={26}>`, which is what
  `star(:half)` already ships. It is also a cap: a `Box` coerces its children
  into its own constraints, every `Text` in this bridge is built with
  `TextOverflow.Ellipsis`, and `text_size` is **sp** while `width` is **dp** —
  so at 235% Dynamic Type a 26sp glyph asks for ~61dp inside a 26dp box and is
  ellipsised away to nothing. That is the failure `Kati.DynamicTypeTest` is
  about, one step worse: not a truncated label, an absent star.

  So the wrapper carries no width at all and hugs instead — `fill_width={false}`
  is what makes a `Box` hug rather than fill (`K-17 box-hugs-when-told`;
  without it a widthless Box takes the whole row and the rating card's stars
  become five full-width rows). The glyph is then measured unbounded, exactly
  as it was before it had a wrapper, and the cell is as wide as the star is at
  whatever scale the phone is set to.

  What is left is a tap area that does not grow with it: the two 13dp targets
  stay 13dp, so at 235% they cover the leading half of a 61dp star rather than
  all of it. Degraded, not broken — the halves are still in the right order and
  still hit — and it is the honest end of what this bridge can express. Making
  the targets track the glyph needs Compose's `matchParentSize`, which no Mob
  prop reaches: `fill_width={true}` on the overlay would measure against the
  card, not against its sibling, and blow the hugging `Box` out to full width.
  """
  @spec star_cell(:full | :half | :empty, 1..5, boolean()) :: map()
  def star_cell(slot, _index, false), do: Kati.Screens.Rating.star(slot)

  def star_cell(slot, index, true) do
    glyph = Kati.Screens.Rating.star(slot)
    left = {self(), Kati.Screens.Rating.star_tag(index * 2 - 1)}
    right = {self(), Kati.Screens.Rating.star_tag(index * 2)}

    ~MOB"""
    <Box fill_width={false}>
      {glyph}
      <Row width={26} height={26}>
        <Box width={13} height={26} on_tap={left} />
        <Box width={13} height={26} on_tap={right} />
      </Row>
    </Box>
    """
  end

  @doc """
  The tap tag for one point of the ten-point scale.

  An ATOM, built the way `Kati.Screens.ImportSources.tag/1` builds its own and
  for the reason `Kati.ScreenTapSweepTest`'s last test gives: `Mob.Renderer`
  registers `{pid, atom}` and emits the atom as the control's
  `accessibility_id`, so a tag that is anything else is either inert or
  anonymous — and an anonymous control is one no device test and no screen
  reader can reach.

  Guarded on the resource's own constraint rather than on 1..5 doubled.
  `Kati.Media.Watch.rating` is `min: 1, max: 10`, so a tag outside it names a
  rating the store would reject, and finding that out at the changeset is
  finding out one screen too late.

      iex> Kati.Screens.Rating.star_tag(9)
      :star_9
  """
  @spec star_tag(1..10) :: atom()
  def star_tag(point) when point in 1..10,
    do: String.to_atom("star_" <> Integer.to_string(point))

  @doc """
  The ten-point rating a `star_*` tag names, or `nil` for a tag that is not one.

  `nil` rather than a raise: this screen's `handle_info/2` runs every tag the
  sheet draws through here, `:add_tag` included, and a tag that is not a star
  is an ordinary answer rather than an error.

      iex> Kati.Screens.Rating.point_of(:star_7)
      7
      iex> Kati.Screens.Rating.point_of(:add_tag)
      nil
  """
  @spec point_of(atom()) :: 1..10 | nil
  def point_of(tag) when is_atom(tag) do
    with "star_" <> digits <- Atom.to_string(tag),
         {point, ""} when point in 1..10 <- Integer.parse(digits) do
      point
    else
      _other -> nil
    end
  end

  @doc false
  def star_gap, do: ~MOB"<Spacer size={2} />"

  @doc false
  def star(:full), do: Kati.UI.symbol("star", size: 26, color: Palette.accent(), fill: true)
  def star(:empty), do: Kati.UI.symbol("star", size: 26, color: Palette.star_empty(), fill: true)

  # A real half star, drawn the way the design draws one: the empty star, with
  # a filled star painted over it and CUT at 50%.
  #
  # This used to be an outlined accent star, because the icon subset carries no
  # `star_half` and this bridge could not crop a glyph — a Box narrower than
  # the text ellipsises it away, since every Text is built with
  # TextOverflow.Ellipsis, and `corner_radius` clips painting only. Adding
  # `star_half` to the subset would have meant re-subsetting from a source
  # variable font that is not in this repo, for a glyph that is another glyph
  # cut in half.
  #
  # Fence K-16 gave the bridge `clip_width` instead, which clips the DRAW and
  # leaves measurement alone — so the two glyphs occupy one star's width, sit
  # in the same line box as their four neighbours, and 4.5 reads as four and a
  # half rather than as five.
  def star(:half) do
    ~MOB"""
    <Box width={26} height={26}>
      {Kati.UI.symbol("star", size: 26, color: Palette.star_empty(), fill: true)}
      <Box width={26} height={26} clip_width={0.5}>
        {Kati.UI.symbol("star", size: 26, color: Palette.accent(), fill: true)}
      </Box>
    </Box>
    """
  end

  # The one card on cream. Screen 08 does the same for its note, and for the
  # same reason: the user's own words are not metadata, so the palette warms up
  # around them.
  @doc false
  def review_card(w) do
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
          <Text
            text={String.upcase("Review")}
            font_family="mono"
            text_size={10.5}
            letter_spacing={0.16}
            text_color={Palette.cream_meta()}
            max_lines={1}
          />
          <Spacer weight={1.0} />
          {Kati.Screens.Rating.spoiler_toggle(w.spoilers, Kati.Screens.Rating.writable?(w))}
        </Row>
        <Spacer size={10} />
        {Kati.Screens.Rating.review_field(w.review)}
        <Spacer size={14} />
        <Box fill_width={true} height={1} background={Palette.cream_rule()} />
        <Spacer size={13} />
        <Row fill_width={true} align="center">
          <Text
            text={w.characters}
            font_family="mono"
            text_size={10.5}
            text_color={Palette.cream_meta()}
            max_lines={1}
          />
          <Spacer weight={1.0} />
          {Kati.UI.symbol("format_bold", size: 16, color: Palette.gold_icon())}
          <Spacer size={7} />
          {Kati.UI.symbol("format_italic", size: 16, color: Palette.gold_icon())}
          <Spacer size={7} />
          {Kati.UI.symbol("link", size: 16, color: Palette.gold_icon())}
        </Row>
      </Column>
      <Spacer size={14} />
    </Column>
    """
  end

  @doc """
  The review, in a field that can be typed into.

  It was a `<Text>` and a `<Box>` drawn to look like a caret — a picture of a
  focused input, on the one card in this design that exists to hold the user's
  own words. `Kati.Screens.AddTitle.field/1` records the belief that made that
  seem reasonable, and it was false: `<TextField>` is in the pinned Mob and
  `Kati.Screens.Backup` has used it for the passphrase all along.

  `accessibility_id` is not decoration. `Mob.Renderer` emits one automatically
  for an atom-tagged TAP, and a field has no tap tag — so without this the
  bridge's `K-35 test-tag` fence has nothing to hang a `testTag` on and no
  device test can address the field at all. `"review"` is what
  `android/app/src/androidTest` types into.

  `value` is passed back in rather than left to the field's own state, for the
  reason `Kati.Screens.Backup.field/4` gives: `MobTextField` re-keys its
  `remember` only when the string actually differs, so echoing back what was
  just typed is a no-op and the caret does not move.

  The placeholder is what an empty review card should say and the drawing never
  had to: every value in `Kati.Rating.Sample` is filled in, because the drawing
  is a sheet that has been written on.
  """
  @spec review_field(String.t()) :: map()
  def review_field(review) do
    change = {self(), :review}

    ~MOB"""
    <TextField
      value={review}
      placeholder="What did you make of it?"
      return_key="done"
      fill_width={true}
      text_size={14}
      accessibility_id="review"
      on_change={change}
    />
    """
  end

  @doc """
  The spoiler state of the review, or nothing at all.

  `Kati.Media.Watch.contains_spoilers` says a review has spoilers *to hide*, so
  its `false` is not a second state to draw — it is the absence of the first.
  Drawing `visibility_off` beside "no spoilers" would be the icon asserting the
  opposite of the sentence.

  The pair goes in a propless `<Row>`, which is inert: `MobBridge.kt` builds a
  row as `Row(modifier = m, verticalAlignment = rowAlignProp(props))` with no
  `fillMaxWidth`, and `rowAlignProp/1` answers `CenterVertically` for an absent
  `align` — so the glyph and the label share the same centre line and the same
  6pt gap they had as direct children of the eyebrow row.

  ## Both states now, and the off one is an invitation

  MOVIES-AND-TV.md #96. The badge said *Spoilers hidden* over a real column and
  could not be changed, and with `contains_spoilers` false it drew nothing —
  so a reader writing a review with a twist in it had no way to say so.

  The argument above still holds and decides the shape: the icon must not
  assert the opposite. It does not, because it does not change. `visibility_off`
  in the gold pair is a claim — *this review has spoilers to hide* — and the
  same glyph in the eyebrow colour beside *Mark spoilers* is an offer, which is
  what an unset toggle should look like. The glyph could not swap regardless:
  `Kati.Icons.glyph!/1` raises on `visibility`, which is not in Kati's subset.
  """
  @spec spoiler_toggle(String.t() | nil, boolean()) :: map()
  def spoiler_toggle(label, live? \\ false)

  def spoiler_toggle(nil, false), do: ~MOB"<Spacer size={0} />"

  def spoiler_toggle(nil, true) do
    assigns = %{tap: {self(), :toggle_spoilers}}

    ~MOB"""
    <Row on_tap={@tap}>
      {Kati.UI.symbol("visibility_off", size: 15, color: Palette.eyebrow())}
      <Spacer size={6} />
      <Text
        text="Mark spoilers"
        text_size={11}
        font_weight="semibold"
        text_color={Palette.eyebrow()}
        max_lines={1}
      />
    </Row>
    """
  end

  def spoiler_toggle(label, live?) do
    assigns = %{label: label, tap: if(live?, do: {self(), :toggle_spoilers})}

    ~MOB"""
    <Row on_tap={@tap}>
      {Kati.UI.symbol("visibility_off", size: 15, color: Palette.gold_icon())}
      <Spacer size={6} />
      <Text
        text={@label}
        text_size={11}
        font_weight="semibold"
        text_color={Palette.gold_text()}
        max_lines={1}
      />
    </Row>
    """
  end

  @doc false
  # *Watched on*, *Where* and *With* — three rows, and what each one opens.
  #
  # MOVIES-AND-TV.md #95. Each drew a chevron and carried no tap, and a chevron
  # is a promise that a screen opens. All three sit over real columns —
  # `watched_on` beside `watched_at`, `service`, `companions` — and none had a
  # writer.
  #
  # Three screens is not what they want. Each edit is one short answer, so each
  # opens **under its own row, inside the same card**, which is the shape `+ tag`
  # settled one card down: a page of chrome around a choice of four days is more
  # app than the choice is worth, and a reader logging a watch is answering three
  # questions at one sitting rather than visiting three places.
  #
  # One row is open at a time. Two open editors in a settings card is a card that
  # jumps under the thumb, and the reader is answering one question anyway.
  @spec context_card(map()) :: map()
  def context_card(w) do
    live? = Kati.Screens.Rating.writable?(w)
    rows = Kati.Screens.Rating.context_of(w)
    last = length(rows) - 1
    open = Map.get(w, :open_row)

    body =
      rows
      |> Enum.with_index()
      |> Enum.flat_map(fn {row, i} ->
        [
          SettingsList.row(
            SettingsList.icon_tile(row.icon),
            SettingsList.body(row.title, row.sub),
            SettingsList.chevron(),
            padding: 13,
            rule: i < last,
            on_tap: if(live?, do: {self(), row.tag})
          ),
          Kati.Screens.Rating.editor(row.key, w, open == row.key)
        ]
      end)

    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.card(body)}
      <Spacer size={14} />
    </Column>
    """
  end

  @doc """
  The three rows, read back off the draft rather than off the row.

  `shaped/3` still builds `:context` for the values it takes from the store,
  and this is what the card draws — the difference matters the moment an edit
  lands: the sub-line under *Where* has to say what was just chosen, and a row
  built once at mount cannot.
  """
  @spec context_of(map()) :: [map()]
  def context_of(w) do
    [
      %{
        key: :watched_on,
        tag: :open_watched_on,
        icon: "event",
        title: "Watched on",
        sub: Kati.Screens.Rating.day_label(w)
      },
      %{
        key: :where,
        tag: :open_where,
        icon: "tv",
        title: "Where",
        sub: Map.get(w, :service) || sub_of(w, "Where")
      },
      %{
        key: :with,
        tag: :open_with,
        icon: "group",
        title: "With",
        sub: Map.get(w, :companions) || sub_of(w, "With")
      }
    ]
  end

  # The drawing's own sub-line for a row the draft has no value for, so board
  # 33 keeps its `Lumen+ · Living room` and `Jo` while a real sheet reads the
  # watch. `nil` on a real sheet with nothing set, which is what an unanswered
  # question looks like.
  defp sub_of(w, title) do
    case Enum.find(Map.get(w, :context, []), &(&1.title == title)) do
      %{sub: sub} -> sub
      nil -> nil
    end
  end

  @doc """
  `Mon 7 Sep · 00:09`, off the draft.

  The hour comes from `watched_at` and the date from `watched_on`, which is the
  split `Kati.Media.Watch` keeps and `when_label/2` explains: storing a date as
  midnight moves it a day the moment the user flies. Choosing a different day
  therefore leaves the hour alone — the reader is correcting which night, not
  what time it was.
  """
  @spec day_label(map()) :: String.t() | nil
  def day_label(w) do
    zone = Kati.Time.device_zone()

    case {Map.get(w, :watched_on), Map.get(w, :watched_at)} do
      {nil, nil} ->
        sub_of(w, "Watched on")

      {nil, %DateTime{} = at} ->
        at |> Kati.Time.in_zone(zone) |> Calendar.strftime("%a %-d %b · %H:%M")

      {%Date{} = date, %DateTime{} = at} ->
        Calendar.strftime(date, "%a %-d %b") <>
          " · " <> (at |> Kati.Time.in_zone(zone) |> Calendar.strftime("%H:%M"))

      {%Date{} = date, _none} ->
        Calendar.strftime(date, "%a %-d %b")
    end
  end

  @doc false
  def editor(_key, _w, false), do: ~MOB"<Spacer size={0} />"

  def editor(:watched_on, w, true) do
    assigns = %{
      chips:
        Kati.Screens.Rating.recent_days()
        |> Enum.map(fn {label, date} ->
          Kati.Screens.Rating.choice(label, "day_" <> Date.to_iso8601(date), date == w.watched_on)
        end)
        |> Enum.intersperse(Kati.Screens.Rating.tag_gap())
    }

    ~MOB"""
    <Column fill_width={true} padding_bottom={13}>
      <Row fill_width={true} align="center">
        {@chips}
      </Row>
    </Column>
    """
  end

  def editor(:where, w, true) do
    assigns = %{
      chips:
        Kati.Screens.Rating.where_options(w)
        |> Enum.map(&Kati.Screens.Rating.choice(&1, "where_" <> &1, &1 == w.service))
        |> Enum.intersperse(Kati.Screens.Rating.tag_gap()),
      empty?: Kati.Screens.Rating.where_options(w) == []
    }

    ~MOB"""
    <Column fill_width={true} padding_bottom={13}>
      <Row fill_width={true} align="center">
        {@chips}
      </Row>
      {Kati.Screens.Rating.where_note(@empty?)}
    </Column>
    """
  end

  def editor(:with, w, true) do
    assigns = %{
      change: {self(), :with_draft},
      draft: Map.get(w, :with_draft) || Map.get(w, :companions) || "",
      commit: Kati.Screens.Rating.commit_pill("Done", :commit_with)
    }

    ~MOB"""
    <Column fill_width={true} padding_bottom={13}>
      <Row fill_width={true} align="center">
        <Box weight={1.0}>
          <TextField
            value={@draft}
            placeholder="Jo, Sam"
            return_key="done"
            fill_width={true}
            text_size={13}
            accessibility_id="with_draft"
            on_change={@change}
          />
        </Box>
        <Spacer size={8} />
        {@commit}
      </Row>
    </Column>
    """
  end

  @doc """
  Tonight and the three before it, which is every day a watch is logged on.

  Not a calendar. A person logging a watch is logging tonight's, or last
  night's if they went to bed first, and a month grid to answer that is a
  screen for a question nobody asked. A watch further back than this is one
  the sheet cannot date, and it says so by leaving the row as it found it.
  """
  @spec recent_days() :: [{String.t(), Date.t()}]
  def recent_days do
    today = Kati.Time.today()

    for offset <- 0..3 do
      date = Date.add(today, -offset)

      label =
        case offset do
          0 -> "Today"
          1 -> "Yesterday"
          _ -> Calendar.strftime(date, "%a %-d %b")
        end

      {label, date}
    end
  end

  @doc """
  Where this could have been watched: the reader's services, then their history.

  `Kati.Services.Service`'s `:subscribed` read is the list screen 92 keeps, so
  the answer is the reader's own — and the services they have named on past
  watches come after it, because a cinema and a friend's sofa are places a
  subscription list will never hold.
  """
  @spec where_options(map()) :: [String.t()]
  def where_options(w) do
    subscribed =
      Kati.Services.Service
      |> Ash.Query.for_read(:subscribed)
      |> Ash.read!()
      |> Enum.map(& &1.name)

    used =
      Watch
      |> Ash.read!()
      |> Enum.map(& &1.service)
      |> Enum.reject(&is_nil/1)

    (subscribed ++ used ++ List.wrap(Map.get(w, :service)))
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.uniq()
    |> Enum.take(6)
  rescue
    _error -> []
  end

  @doc false
  def where_note(false), do: ~MOB"<Spacer size={0} />"

  def where_note(true) do
    ~MOB"""
    <Text
      text="Add your services in Settings → My services, and they will be offered here."
      text_size={11}
      text_color={Palette.eyebrow()}
    />
    """
  end

  @doc false
  def choice(label, tag, on?) do
    MishkaPill.pill(
      label: label,
      background: if(on?, do: Palette.ink_fill(), else: Palette.paper()),
      color: if(on?, do: Palette.on_ink(), else: Palette.eyebrow()),
      height: 28,
      corner_radius: 14,
      padding: 0,
      padding_left: 12,
      padding_right: 12,
      text_size: 11.5,
      font_weight: :semibold,
      align: :center,
      on_tap: {self(), String.to_atom(tag)}
    )
  end

  @doc false
  def commit_pill(label, tag) do
    MishkaPill.pill(
      label: label,
      background: Palette.ink_fill(),
      color: Palette.on_ink(),
      height: 34,
      corner_radius: 17,
      padding: 0,
      padding_left: 15,
      padding_right: 15,
      text_size: 12,
      font_weight: :semibold,
      align: :center,
      on_tap: {self(), tag}
    )
  end

  # Row, not a wrapping field: the four chips measure ~315 inside the 360pt
  # content width, so the drawing's `flex-wrap` never actually wraps here.
  @doc """
  The tag row, and the field `+ tag` opens under it.

  MOVIES-AND-TV.md #96: `+ tag` was drawn with a tap that reached
  `handle_info({:tap, tag})`'s fall-through, so it was recorded in
  `Kati.ScreenTapSweepTest`'s `@inert_taps` as *a sheet that never opens*.
  `Kati.Media.Watch.tags` is a real list column with no writer anywhere.

  There is no sheet. A tag is one short word and a sheet to type it in is a
  page of chrome around a text field, so the field opens **here**, under the
  chips, with the tags this reader has used before beside it — which is what
  people actually do with tags: reuse the ones they have.

  Over the drawing the chips and `+ tag` stay pictures, because a tag typed
  onto `Kati.Rating.Sample` would be refused by Save after it had been typed.
  """
  @spec tags(map()) :: map()
  def tags(w) do
    live? = Kati.Screens.Rating.writable?(w)

    chips =
      (Enum.map(w.tags, &Kati.Screens.Rating.tag(&1, live?)) ++
         [Kati.Screens.Rating.add_tag(live?)])
      |> Enum.intersperse(Kati.Screens.Rating.tag_gap())

    assigns = %{chips: chips, field: Kati.Screens.Rating.tag_field(w)}

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        {@chips}
      </Row>
      {@field}
    </Column>
    """
  end

  @doc """
  The tag entry, drawn only while `+ tag` is open.

  `Kati.Screens.Rating.tag_draft/1` is `nil` until `+ tag` is pressed, which is
  what keeps the resting sheet exactly the drawing.
  """
  @spec tag_field(map()) :: map()
  def tag_field(w) do
    case Map.get(w, :tag_draft) do
      nil ->
        ~MOB"<Spacer size={0} />"

      draft ->
        assigns = %{
          change: {self(), :tag_draft},
          draft: draft,
          suggestions: Kati.Screens.Rating.suggestion_row(w)
        }

        ~MOB"""
        <Column fill_width={true}>
          <Spacer size={10} />
          <Row fill_width={true} align="center">
            <Box weight={1.0}>
              <TextField
                value={@draft}
                placeholder="rewatch, with Jo, rainy sunday…"
                return_key="done"
                fill_width={true}
                text_size={13}
                accessibility_id="tag_draft"
                on_change={@change}
              />
            </Box>
            <Spacer size={8} />
            {Kati.Screens.Rating.commit_tag()}
          </Row>
          {@suggestions}
        </Column>
        """
    end
  end

  @doc """
  The tags this reader has used before, minus the ones already on this watch.

  Read from `Kati.Media.Watch.tags` across the store rather than from a
  vocabulary resource, because there is no such resource and there does not
  need to be: the tags somebody uses ARE the tags on their watches.
  """
  @spec suggestion_row(map()) :: map()
  def suggestion_row(w) do
    case Kati.Screens.Rating.suggestions(w) do
      [] ->
        ~MOB"<Spacer size={0} />"

      words ->
        assigns = %{
          chips:
            words
            |> Enum.map(&Kati.Screens.Rating.suggestion(&1))
            |> Enum.intersperse(Kati.Screens.Rating.tag_gap())
        }

        ~MOB"""
        <Column fill_width={true}>
          <Spacer size={9} />
          <Row fill_width={true} align="center">
            {@chips}
          </Row>
        </Column>
        """
    end
  end

  @doc false
  @spec words_of(String.t() | nil) :: [String.t()]
  def words_of(tags) when is_binary(tags),
    do: tags |> String.split(",") |> Enum.map(&String.trim/1) |> Enum.reject(&(&1 == ""))

  def words_of(_none), do: []

  @doc false
  @spec suggestions(map()) :: [String.t()]
  def suggestions(w) do
    already = MapSet.new(Map.get(w, :tags, []))

    Watch
    |> Ash.read!()
    # `Kati.Media.Watch.tags` is one comma-separated STRING, not a list — the
    # same column `tag_list/1` splits on read, and the same shape
    # `stored_tags/1` writes.
    |> Enum.flat_map(&Kati.Screens.Rating.words_of(&1.tags))
    |> Enum.reject(&MapSet.member?(already, &1))
    |> Enum.frequencies()
    |> Enum.sort_by(fn {word, n} -> {-n, word} end)
    |> Enum.take(3)
    |> Enum.map(&elem(&1, 0))
  rescue
    _error -> []
  end

  @doc false
  def suggestion(label) do
    MishkaPill.pill(
      label: label,
      background: Palette.paper(),
      color: Palette.eyebrow(),
      height: 26,
      corner_radius: 13,
      padding: 0,
      padding_left: 11,
      padding_right: 11,
      text_size: 11,
      font_weight: :semibold,
      align: :center,
      on_tap: {self(), String.to_atom("use_tag_" <> label)}
    )
  end

  @doc false
  def commit_tag, do: Kati.Screens.Rating.commit_pill("Add", :commit_tag)

  @doc false
  def tag_gap, do: ~MOB"<Spacer size={7} />"

  @doc """
  One tag: `Kati.Components.MishkaPill`, not `Kati.Components.MishkaChip`.

  The port draws the line between them as *a chip is selected, a pill is
  removed*, and these are neither — they are tokens already attached to the
  watch. The deciding fact is narrower than that, though: **`MishkaChip` has no
  `shadow` prop**, and every tag here is a lifted `Kati.Theme.shadow_card_soft()`
  card. A chip cannot draw one, so a chip is not what this is.
  """
  def tag(label, live? \\ false) do
    MishkaPill.pill(
      label: label,
      # Tapping a tag removes it, which is the only gesture a token this size
      # can carry and the one every tag field in the world uses. Over the
      # drawing it carries none: `nil` is not tappable rather than broken.
      on_tap: if(live?, do: {self(), String.to_atom("drop_tag_" <> label)}),
      background: Palette.card(),
      color: Palette.ink_soft(),
      shadow: Kati.Theme.shadow_card_soft(),
      height: 30,
      corner_radius: 15,
      padding: 0,
      padding_left: 13,
      padding_right: 13,
      text_size: 12,
      font_weight: :semibold,
      align: :center
    )
  end

  @doc """
  The add affordance: the same pill with a ring instead of a fill.

  `background: :transparent` is the drawing's *no fill at all*, and it really is
  nothing: `Mob.Renderer` resolves `:transparent` to `0x00000000`, and a fully
  transparent `Modifier.background` paints no pixels. It has to be said out loud
  because a pill always writes a `background` key, defaulting to
  `:surface_raised`.

  Solid, not dashed: `Modifier.border` takes a width and a colour and no
  PathEffect, so the stitching does not survive. The weight and the alpha are
  the drawing's own — and `border_width` is read with `floatProp`, so the 1.5
  survives where an `intProp` would have truncated it to 1.

  `MishkaChip` is out for the second time here: no `border_color`, no
  `border_width`.
  """
  def add_tag(live? \\ false) do
    tap = if live?, do: {self(), :add_tag}

    MishkaPill.pill(
      label: "+ tag",
      background: :transparent,
      color: Palette.eyebrow(),
      border_color: Palette.border_strong(),
      border_width: 1.5,
      height: 30,
      corner_radius: 15,
      padding: 0,
      padding_left: 12,
      padding_right: 12,
      text_size: 12,
      font_weight: :semibold,
      align: :center,
      on_tap: tap
    )
  end

  def handle_info({:tap, :close}, socket), do: {:noreply, Kati.Screens.Resume.pop(socket)}

  # Commit the draft, or keep the sheet up and say why not.
  #
  # The failure branch is the whole of #85 in one clause. This handler used to
  # be `{:noreply, Kati.Screens.Resume.pop(socket)}` with no write behind it at
  # all, which is the extreme case of what that ticket found: the sheet closed
  # on a rating nothing had recorded, and closing is what a sheet does when it
  # has saved. A save that fails now leaves the sheet exactly as it was —
  # the rating you tapped, the review you typed — because the recovery is to
  # press Save again and the draft is the thing that has to survive for that to
  # be worth doing.
  def handle_info({:tap, :save}, socket) do
    case save_watch(socket.assigns) do
      {:ok, _watch} ->
        {:noreply,
         socket
         |> Mob.Socket.assign(:save_error, nil)
         |> Kati.Screens.Resume.pop()}

      error ->
        {:noreply, Mob.Socket.assign(socket, :save_error, Write.message(error))}
    end
  end

  # What was typed into the review, held as typed.
  #
  # `characters` moves with it, because the count under the field is a count of
  # what is in the field. `Kati.Rating.Sample` stores the drawing's own 184
  # against a body of a different length and says why — that is a fact about
  # the drawing, and the moment a person types, the number is about them
  # instead.
  def handle_info({:change, :review, typed}, socket) when is_binary(typed) do
    {:noreply,
     Mob.Socket.update(socket, :watch, fn w ->
       Map.merge(w, %{review: typed, characters: characters_label(typed)})
     end)}
  end

  # A star, half a star at a time.
  #
  # The draft carries the FIVE-point value because that is what `stars/2` and
  # `rating_label/1` read, and the tag carries the ten-point one because that
  # is what the column stores. Halving here and doubling in `save_watch/1`
  # keeps both conversions at the edges, where each is a single line, rather
  # than letting a screen invent a third scale in the middle.
  #
  # A tag that is not a star's — `:add_tag`, which is still drawn and still
  # opens nothing — falls through unchanged. Every drawn tag reaches a clause
  # either way, which is what `Kati.ScreenTapSweepTest` is checking.
  def handle_info({:tap, tag}, socket) when is_atom(tag) do
    case point_of(tag) do
      nil -> {:noreply, Kati.Screens.Rating.other_tap(socket, tag)}
      point -> {:noreply, Mob.Socket.update(socket, :watch, &Map.put(&1, :rating, point / 2))}
    end
  end

  # What the tag draft holds while `+ tag` is open. Held on the draft rather
  # than in its own assign so `render/1` reads one map, and so closing the
  # field is one `Map.delete`.
  def handle_info({:change, :tag_draft, typed}, socket) when is_binary(typed) do
    {:noreply, Mob.Socket.update(socket, :watch, &Map.put(&1, :tag_draft, typed))}
  end

  def handle_info({:change, :with_draft, typed}, socket) when is_binary(typed) do
    {:noreply, Mob.Socket.update(socket, :watch, &Map.put(&1, :with_draft, typed))}
  end

  def handle_info(_msg, socket), do: {:noreply, socket}

  @doc """
  The controls that are not stars: the scale, the spoiler flag, the tags.

  MOVIES-AND-TV.md #96 is the three of them together, and they land here rather
  than in three `handle_info/2` clauses because every one of them arrives as a
  tag built from a label — `:scale_10pt`, `:drop_tag_rewatch` — and pattern
  matching on a constructed atom is how a screen ends up with a clause nothing
  reaches.

  The scale is the odd one: it is a display preference rather than part of the
  draft, so it is written the moment it is pressed (`Kati.Rating.Scale`) and
  survives whether or not this sheet is saved. The other two are edits to the
  draft and go where every other edit on this sheet goes — into `:watch`, and
  onto the row only when Save says so.
  """
  @spec other_tap(Mob.Socket.t(), atom()) :: Mob.Socket.t()
  def other_tap(socket, tag) do
    case Atom.to_string(tag) do
      "scale_" <> label ->
        case Kati.Screens.Rating.scale_from(label) do
          nil -> socket
          scale -> tap_scale(socket, scale)
        end

      "drop_tag_" <> label ->
        edit(socket, &Map.put(&1, :tags, Enum.reject(&1.tags, fn t -> t == label end)))

      "use_tag_" <> label ->
        edit(socket, &add_tag_to(&1, label))

      "toggle_spoilers" ->
        edit(socket, &Map.put(&1, :spoilers, if(is_nil(&1.spoilers), do: "Spoilers hidden")))

      "add_tag" ->
        edit(socket, &Map.put(&1, :tag_draft, Map.get(&1, :tag_draft) || ""))

      "commit_tag" ->
        edit(socket, &add_tag_to(&1, Map.get(&1, :tag_draft)))

      # ── #95's three rows ───────────────────────────────────────────────────
      #
      # One open at a time, and pressing the row that is already open closes
      # it: the chevron is a disclosure and a disclosure that only opens is a
      # row you have to leave the screen to be rid of.
      "open_" <> row ->
        edit(socket, &toggle_row(&1, String.to_existing_atom(row)))

      "day_" <> iso ->
        edit(socket, &choose_day(&1, iso))

      "where_" <> service ->
        edit(socket, &choose_where(&1, service))

      "commit_with" ->
        edit(socket, &commit_with(&1))

      _other ->
        socket
    end
  end

  defp toggle_row(draft, row) do
    if Map.get(draft, :open_row) == row,
      do: Map.delete(draft, :open_row),
      else: Map.put(draft, :open_row, row)
  end

  # The DAY changes and the hour does not: the reader is correcting which
  # night, not what time it was. `Kati.Media.Watch` keeps the two in separate
  # columns for the reason `when_label/2` gives, and this is the edit that
  # needs them separate.
  defp choose_day(draft, iso) do
    case Date.from_iso8601(iso) do
      {:ok, date} -> draft |> Map.put(:watched_on, date) |> Map.delete(:open_row)
      _bad -> draft
    end
  end

  # Choosing the service already set clears it, which is the only way back to
  # "I would rather not say" once a chip has been pressed.
  defp choose_where(draft, service) do
    chosen = if Map.get(draft, :service) == service, do: nil, else: service

    draft |> Map.put(:service, chosen) |> Map.delete(:open_row)
  end

  # Stored as typed, comma-separated: Kati has no people table and no contacts
  # permission, and inventing either to hold the word "Jo" would be a larger
  # privacy decision than this row is asking for — `Kati.Media.Watch` says so
  # at the column. Blank means nobody, which is a real answer and not a
  # refusal to accept one.
  defp commit_with(draft) do
    names = String.trim(Map.get(draft, :with_draft) || "")

    draft
    |> Map.put(:companions, if(names == "", do: nil, else: names))
    |> Map.delete(:with_draft)
    |> Map.delete(:open_row)
  end

  # A scale change re-labels the numeral, and the draft is untouched: the value
  # is one stored integer read two ways, so nothing about this watch changed.
  defp tap_scale(socket, scale) do
    Kati.Rating.Scale.put(scale)
    # Onto the draft as well, and not as a decoration: `rating_card/1` labels
    # the numeral with `Map.get(w, :scale)`, so this is what redraws `4.5` as
    # `9`. Reading `Kati.Rating.Scale.current/0` inside the markup instead
    # would leave the socket identical after a tap that plainly changed the
    # screen — which is a control `Kati.ScreenTapSweepTest` reports as inert,
    # and it would be right to.
    Mob.Socket.update(socket, :watch, &Map.put(&1, :scale, scale))
  end

  # An edit only a draft with a row behind it may take. A tag added to the
  # drawing would be typed, drawn, and then refused by Save — which is the
  # `nothing_to_save` receipt landing after the work rather than instead of it.
  defp edit(socket, change) do
    if Kati.Screens.Rating.writable?(socket.assigns.watch),
      do: Mob.Socket.update(socket, :watch, change),
      else: socket
  end

  # Trimmed, deduplicated, and the field closes behind it. A blank commit
  # closes the field rather than adding `""` — pressing Add on an empty field
  # is how somebody changes their mind.
  defp add_tag_to(draft, word) do
    trimmed = String.trim(word || "")

    tags =
      if trimmed == "" or trimmed in draft.tags,
        do: draft.tags,
        else: draft.tags ++ [trimmed]

    draft |> Map.put(:tags, tags) |> Map.delete(:tag_draft)
  end

  @doc """
  Write the draft back onto the watch the sheet opened on.

  `Ash.update/1`, never `Ash.create/2`, and `watch_id` is what makes that
  possible: the sheet is an editor for an existing log, so a second row would be
  a second, contradicting account of one night — see the moduledoc.

  **With no id there is nothing to update, and that is the whole answer.** The
  draft on screen is then `Kati.Rating.Sample`'s and belongs to the drawing;
  committing it would file "Blue Hour" and a review nobody wrote under the
  user's own log. `{:error, :nothing_to_save}` is `Kati.Write`'s own term for
  it and `Kati.Write.message/1` already renders it as *"Nothing to save yet."*

  A blank review is stored as `nil` rather than `""`, because
  `Kati.Media.Watch.review` is nullable and a review of nothing but whitespace
  is not a review — `newest_log/1` filters on exactly that distinction, so
  storing the empty string would leave a sheet reopening on a log it also
  considers unlogged. What is not blank is stored **as typed**: trimming a
  person's own words is an edit, and this function is not entitled to one.
  """
  @spec save_watch(map()) :: {:ok, struct()} | {:error, term()}
  def save_watch(%{watch_id: nil, tracked_title_id: tracked_id, watch: w})
      when is_binary(tracked_id) do
    # The FIRST watch of a film, which nothing in the app could record. Screen
    # 08's *Log a watch* opens this sheet with the film's tracked id and the
    # sheet only ever knew how to update a row that already existed — so the
    # save refused, and a film could never be marked watched, rated, reviewed,
    # or counted by Your year. Reported against the store rather than the
    # screen: `grep -rn "Ash.create(Kati.Media.Watch" lib/` was empty.
    #
    # `watched_on` is today and `watched_at` is now, because this sheet is
    # reached from *Log a watch* — a claim about an evening that is happening.
    # A watch logged for some other night is a date field this sheet does not
    # draw; when it draws one, this is the line that reads it.
    # The named row is checked BEFORE anything is written, and that is not
    # defensiveness: `Kati.ScreenWriteTargetTest` refused the first version of
    # this clause because a sheet pushed with an id whose title has since been
    # deleted still created a watch — a row hanging off a title that is not
    # there, made by a page that was drawing its fixture at the time. The rule
    # that file states is *refuse when the named row is gone*, and this is that
    # refusal.
    case Ash.get(Kati.Media.TrackedTitle, tracked_id) do
      {:ok, _title} ->
        %{
          tracked_title_id: tracked_id,
          rating: ten_point(w.rating),
          review: stored_review(w.review),
          # The two columns #96 gave a writer. `contains_spoilers` is a boolean
          # and the draft carries the SENTENCE the badge draws, because that is
          # what `shaped/3` reads it back as — so the flag is the presence of
          # the sentence, in both directions.
          # `Map.get`, not a dot: a draft assembled by a caller that predates
          # #96 — every test that builds one by hand, and `blank_for/1`'s own
          # shape before it grew the keys — must go on meaning "no spoilers,
          # no tags" rather than raising inside a save.
          contains_spoilers: not is_nil(Map.get(w, :spoilers)),
          tags: stored_tags(Map.get(w, :tags)),
          service: Map.get(w, :service),
          companions: Map.get(w, :companions),
          # The night the reader said, and tonight when they did not — #95 gave
          # the row a writer, so this is no longer always "now".
          watched_on: Map.get(w, :watched_on) || Kati.Time.today(),
          watched_at: Kati.Time.now() |> DateTime.truncate(:second)
        }
        |> then(&Ash.create(Watch, &1))
        |> Kati.Screens.Rating.finish_title(tracked_id)
        |> Write.note("log a watch")

      _gone ->
        Write.note({:error, :nothing_to_save}, "log a watch")
    end
  end

  def save_watch(%{watch_id: nil}), do: Write.note({:error, :nothing_to_save}, "rate a watch")

  def save_watch(%{watch_id: id, watch: w}) do
    case Ash.get(Watch, id) do
      {:ok, record} ->
        record
        |> Ash.Changeset.for_update(:update, %{
          rating: ten_point(w.rating),
          review: stored_review(w.review),
          contains_spoilers: not is_nil(Map.get(w, :spoilers)),
          tags: stored_tags(Map.get(w, :tags)),
          service: Map.get(w, :service),
          companions: Map.get(w, :companions),
          watched_on: Map.get(w, :watched_on)
        })
        |> Ash.update()
        |> Write.note("rate a watch")

      error ->
        Write.note(error, "rate a watch")
    end
  end

  @doc """
  The ten-point integer a five-point display value stands for.

  `round/1` rather than `trunc/1`, and it costs nothing to be right about it:
  a half is exact in binary floating point, so `4.5 * 2` is `9.0` on the nose
  and both answer 9 — but a rating arriving as `6.999999` would truncate to 13
  points of ten, which is a value the column rejects and a bug that would show
  up as "that did not save" with no reason attached.

      iex> Kati.Screens.Rating.ten_point(4.5)
      9
      iex> Kati.Screens.Rating.ten_point(nil)
      nil
  """
  @spec ten_point(number() | nil) :: 1..10 | nil
  def ten_point(nil), do: nil
  def ten_point(value), do: round(value * 2)

  defp stored_review(review) when is_binary(review) do
    if String.trim(review) == "", do: nil, else: review
  end

  defp stored_review(_review), do: nil

  # `Kati.Media.Watch.tags` is one comma-separated string, not a list — the
  # column `tag_list/1` has always split on read. `nil` for no tags rather than
  # `""`, so an untagged watch is untagged rather than carrying an empty word.
  defp stored_tags([]), do: nil
  defp stored_tags(tags) when is_list(tags), do: Enum.join(tags, ", ")
  defp stored_tags(_tags), do: nil
end
