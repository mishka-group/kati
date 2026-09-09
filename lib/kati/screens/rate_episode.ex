defmodule Kati.Screens.RateEpisode do
  @moduledoc """
  Screen 33 in its episode variant — rate the one you just watched, not the
  whole title.

  Built to `test/design/reference/144.html`. Episode 06's episode picker
  narrows a title to one row; this narrows `Kati.Screens.Rating` to one row
  the same way, scoped by `episode_source_id` rather than drawing the title's
  rating over again. The board's own caption calls it *"33's modal,
  episode-scoped"* and names three open items it settles: a rating **implies
  watched**, half-steps are the same clipped-glyph star `Kati.Screens.Rating`
  already draws, and the rewatch card is **collapsible** with the date and
  score always visible.

  ## Reused rather than redrawn

  Four things this board also draws are `Kati.Screens.Rating`'s own
  construction, called rather than copied, because a second copy is a second
  place the half-star crop can drift:

    * `stars/1` and `rating_label/1` — the four filled glyphs, the one clipped
      to 50%, and the `4.5`/`—` numeral. See that module's moduledoc for why
      every star is `Kati.UI.symbol("star", …)` and never the character `★`.
    * The caret. `w.review` ending in a `Box` on the line below rather than
      beside the text — there is no inline node on this bridge, so a cursor at
      the end of a line that fills its width draws on the next one. Recorded
      there once; this screen's `caret/0` is the same two lines.
    * `Kati.UI.Sheet.close_disc/0` and `.scrim/0` — this board's close disc is
      **36pt** with a **19pt** glyph, not screen 33's hand-set 44/21, and that
      is exactly `Kati.UI.Sheet`'s own disc: seven sheet screens already draw
      it at these numbers because a sheet's own top edge separates it from the
      page where a full screen's disc has to float alone.
    * `Kati.UI.Sheet.insight/2` — the cream `check_circle` card, gold icon,
      `Kati.UI.rich_text/1` paragraph. Built for exactly this shape.

  ## Why this is a sheet and screen 33 is not, even though both say "sheet"

  `test/design/screens/33.html` draws a **full page** — `padding:64px
  21px 40px` directly on the frame, no scrim, no rounded corner. `144.html`
  draws the other family: a `rgba(26,25,23,.42)` scrim, a paper drawer with
  `border-radius:22px 22px 0 0` and `18px 21px 34px` of padding, anchored to
  the bottom. That is `Kati.UI.Sheet`'s own recipe, used by seven screens
  already (`log_listen`, `log_weight`, `shelf_filters`, …), so this screen
  reads as a lighter, quicker action than logging a whole watch — which an
  episode rating is.

  It cannot call `Kati.UI.Sheet.sheet/2` wholesale, though. That function
  always draws `Kati.UI.Sheet.header/1` — a close disc, a centred title, and
  an empty 36pt hole where a trailing control would go — and commits with a
  full-width bar at the bottom (`Kati.UI.Sheet.commit/2`). This board puts
  **Save in the header**, beside the title, exactly where screen 33 puts it.
  So `render/1` below reimplements `sheet/2`'s own Box nesting — scrim, the
  40pt paper strip that hides the wedges a single `corner_radius` leaves at
  the rounded drawer's bottom two corners once it is trimmed to `22` instead
  of `26` — and calls `header/0` in place of `Sheet.header/1`. Everything that
  *is* shared — the scrim, the close disc, the insight card — is still a call
  into `Kati.UI.Sheet`, not a second copy of it.

  `corner_radius={22}`, not `Sheet`'s `26`: **reproduce the board's own
  number**, not the family's. The seven sheet screens agree with each other;
  this one draws its own top radius and gets it.

  ## The upward shadow this board draws and does not get

  `box-shadow:0 -20px 44px -20px rgba(26,25,23,.5)` — a shadow cast *above*
  the sheet, onto the scrim. `Kati.Theme`'s seven `shadow_*` tokens are all
  downward casts (`y` always positive), and `Kati.UI.Sheet.sheet/2` — the
  shipped, seven-screen-wide precedent for this exact drawer — draws **no**
  shadow on the sheet itself at all, trusting the scrim alone to separate it
  from the page. Rather than invent the one negative-`y` shadow value in this
  codebase and hope the bridge's shadow layer honours a direction CSS has and
  a native elevation API does not, this screen follows the family it belongs
  to: the scrim does the separating, same as on the other seven.

  ## The three states, and which two booleans they reduce to

  Nothing hands this screen an episode, the same as screen 33: `Kati.Screens.
  Gallery` pushes it with nothing attached, so the referent is chosen here —
  **the newest episode-level watch that carries a rating or a review**, the
  same rule `Kati.Screens.Rating.newest_log/0` applies at the title level,
  narrowed by `not is_nil(episode_source_id)`. Every other logged watch of
  that *same* episode — by `{tracked_title_id, episode_source_id}`, the pair
  `Kati.Media.Watch.for_episode` already reads by — is `history`, newest
  first. Two facts about `history` are the whole of the branching:

    * `rewatch? = length(history) > 1` — a second logged watch of one episode
      is what a rewatch *is*. The newest is what this sheet fills in; the one
      before it is what the cream card quotes.
    * `spoiler_safe? = tracked.hide_unwatched_titles and not rewatch?` — the
      preference `Kati.Media.TrackedTitle` has carried since screen 04 and
      `Kati.Screens.Series`'s own moduledoc says nothing reads yet: *"the
      drawing never shows that state, so nothing reads it yet."* This screen
      is that reader. It only masks a title the first time an episode is
      logged — by the second, the user has plainly already seen it, so hiding
      the name would be protecting them from something they already know.

  That gives exactly the board's three states from two flags. The *live*
  sheet is in exactly one of them at a time; the other two are drawn under it
  as the board's own labelled swatches, which is the next section:

    * **first time** — `spoiler_safe?` and `rewatch?` both false: the real
      episode title, the `check_circle` note, no cream card above the input.
    * **spoiler-safe** — `hide_unwatched_titles` on, no prior log: the same
      sheet, headline swapped to `Episode 6`.
    * **rewatch** — a prior log exists: the cream card surfaces it above the
      review, and the note is gone, because *"ticks it watched"* has nothing
      left to tell someone who has already logged this episode once.

  ## The two swatches under the sheet are drawn, not argued away

  Rows 20-29 of `144.html` hang two labelled panels below the info note, and
  each is a moment this sheet can be in and is not right now:

    * **Spoiler-safe variant** — the masked headline again, inside a `#FBFAF8`
      card under its own mono eyebrow with a `visibility_off` glyph opposite.
    * **Rewatch — your last verdict, above the input** — the cream card
      quoting the verdict before this one, under a `#C4BDB3` dash and grey
      uppercase mono, which is `Kati.UI.SettingsList.eyebrow_muted/1` pixel
      for pixel.

  An earlier reading of this module took the first panel for documentation
  *about* the drawing and declined to render it: the board's own summary calls
  it a substitution — *"spoiler-safe (episode title becomes `Episode 6`)"* —
  and `headline/2` already performs that substitution, so the panel looked
  like the drawing restating itself. That is the wrong half of the argument.
  The substitution being real is precisely what makes the swatch worth
  drawing — it is the only place a reader can see what the headline turns into
  — and declining it cost five lines of the board's copy and both of its
  remaining glyphs. `Kati.Screens.LogProgressStates` and
  `Kati.Screens.HealthEmptyStates` stack every moment their boards draw under
  `eyebrow_muted/1` labels rather than electing one and dropping the rest, and
  `Kati.ScreenDesignLiteralTest` refuses copy that is in a drawing and nowhere
  in a tree. So both swatches render, in the board's own order, under the
  board's own labels, below `info_note/1`.

  What fills them is **not** frozen, and that is where this differs from a
  states board. `spoiler_swatch/1` draws `masked_headline` — `S2 E6 · ` and
  `spoiler_title(episode)` for *this* sheet's own episode — so it says what
  the headline above it would say with `hide_unwatched_titles` on, rather than
  reciting the drawing's episode over somebody else's log. On the drawn sheet
  that value is `S2 E6 · Episode 6`, the board's own, because the sheet above
  it is the board's own too.

  The rewatch swatch has no live twin to derive from: a sheet that is not a
  rewatch has no earlier verdict, and quoting the drawing's `3 Mar 2024` under
  a real user's episode is exactly the mixing `sheet/0`'s all-or-nothing gate
  exists to prevent. So the cream card draws in exactly one of two places and
  never both — `rewatch_block/2` immediately above the input when the sheet
  **is** a rewatch, which is where the label's own words say the card belongs,
  and `rewatch_swatch/2` under the note quoting
  `Kati.Screens.RateEpisode.Sample.reference_verdict/0` when it is not. One
  card, one label, and `:toggle_verdict` live in either position.

  ## The collapse, and the glyph that stands in for one that is not shipped

  `Kati.Components.MishkaSpoiler` puts its control **under** the content, as a
  text link that relabels itself — wrong shape here, where the drawing keeps
  the date and score in a header that never moves and puts the toggle glyph
  *in* that header. `Kati.Components.MishkaCollapsible`'s trigger is closer —
  header first, region below — but its title slot is one plain string, and
  this header is `YOU, 3 MAR 2024 · ` mono, a **glyph** star (Plus Jakarta
  Sans has no `★`, same defect screen 08 and screen 33 both hit), then `4` —
  three runs a `title:` string cannot hold. `verdict_card/2` hand-rolls the
  same disclosure shape instead, on a whole-card `on_tap` the way
  `Kati.Screens.Calendar.airing/1` wires its own opening card.

  The chevron is `Kati.Screens.Calendar.chevron/1`'s own trick, reused rather
  than reinvented for the same reason: `expand_more` is in the 143-glyph
  subset and `expand_less` is not, and adding it would mean re-subsetting the
  variable font this repo does not carry, for a glyph that is `expand_more`
  turned over. Fence K-16 gave the bridge `rotate` for precisely this, so
  collapsed draws the plain glyph and expanded draws it in an 18pt `Box` at
  `rotate={180.0}`.

  Collapsed shows two lines of the quoted review (`max_lines={2}`) — long
  enough that this board's own one-sentence sample never visibly truncates,
  and short enough that the two-years-old review the caption warns about
  cannot push the input off screen the way an unbounded quote would.

  ## Where the review card gets its placeholder, and why the caret still lands

  There is no live text field on this bridge — `Kati.Screens.Rating`'s own
  moduledoc settles that: every `Text` renders, none of them accept input, and
  `Save` here pops the screen exactly as screen 33's does, without writing.
  So this sheet's own review is never something a user just typed; it is
  whatever the newest logged watch's `review` column already holds, which may
  be blank — a rating set with no words to go with it yet is an ordinary
  state, the same way `Kati.Screens.Rating.rating_label(nil)` treats an
  unset rating as ordinary rather than broken. Blank draws the board's own
  placeholder, `What did you make of it?`, at `Palette.tertiary()` — the
  drawing's own `#B3ACA2` — with `caret/0` beneath it either way, because the
  field is where the next word goes whether or not one exists yet.

  ## The info card is `Kati.UI.Sheet.insight/2`, one pixel narrower than drawn

  `padding:16px` in the board; `insight/2` pads `15`. The component is the
  exact shape this needs otherwise — cream, `check_circle`, gold icon, an
  `Kati.UI.rich_text/1` paragraph — and a second hand-rolled cream card one
  pixel wider than this one would be the thing `Kati.UI`'s own moduledoc warns
  against: two components doing the same job because neither quite matched.
  The bold span, `ticks it watched`, is the same known trade-off
  `Kati.UI.rich_text/1` documents for every screen that calls it: this bridge
  has no `AnnotatedString`, so the paragraph renders in ONE style — the
  longest run's, which here is the plain body copy — and the emphasis is
  silently dropped rather than orphaning a word onto its own line.

  ## Context rows carry no chevron, on purpose

  `Kati.Screens.Rating.context_card/1` always trails a chevron because every
  row there opens a picker eventually. This board draws none — three plain
  rows, the first alone carrying a mono `now` when the watched date is
  today's. `SettingsList.row/4`'s `trailing` is `nil` on the other two, which
  is the row with nothing to disclose, not a picker not yet wired.

  ## The number a cache eviction cannot take with it

  `Kati.Media.Watch` states the rule for the title-level case and this screen
  leans on the episode-level twin of it: `season_number`/`episode_number` are
  a **label snapshot**, written at log time and never read back as identity.
  `episode_number/2` therefore prefers `Kati.Media.CachedEpisode`'s own
  numbers when that row is still live, and falls back to the watch's own
  snapshot when it has been evicted — the same guarantee `Kati.Screens.Rating`
  gives the title's meta line, one level down.
  """

  use Mob.Screen
  import Mob.Sigil

  require Ash.Query

  alias Kati.Components.MishkaPill
  alias Kati.Media.CachedEpisode
  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Media.Watch
  alias Kati.Screens.RateEpisode.Sample
  alias Kati.Screens.Rating
  alias Kati.Theme.Palette
  alias Kati.UI.Sheet
  alias Kati.UI.SettingsList

  def mount(params, _session, socket) do
    Mob.Theme.set(Kati.Theme.current())

    {:ok,
     socket
     |> Mob.Socket.assign(:params, params)
     |> Mob.Socket.assign(:sheet, sheet(params))
     |> Mob.Socket.assign(:save_error, nil)
     |> Mob.Socket.assign(:verdict_expanded?, false)}
  end

  @doc """
  The live moment this sheet draws: the user's newest episode log, or the
  drawing's.

  The gate is the whole sheet, for the reason `Kati.Screens.Rating.watch/0`
  gives at the title level: a page whose review is the user's own and whose
  episode name is somebody else's reads as entirely real. Either every value
  here is this log's, or every value is the drawing's.
  """
  @spec sheet(map() | nil) :: map()
  def sheet(params \\ %{})

  def sheet(params) when is_map(params),
    do: asked_sheet(params) || logged_sheet() || drawn_sheet()

  def sheet(_params), do: logged_sheet() || drawn_sheet()

  @doc """
  The episode the pushing screen named, shaped for this sheet.

  The route into this screen is an episode's rating column on screen 04 — you
  open a series, you open a season, you tap the rating beside the episode you
  just watched — so the subject is the caller's, and `logged_sheet/0`'s
  "newest episode log anywhere" is the fallback for the one door that names
  nothing (the gallery).

  `nil` when the pair names no tracked row: a sheet opened over a title that
  has since been removed draws the drawing rather than half of somebody
  else's episode.
  """
  @spec asked_sheet(map()) :: map() | nil
  def asked_sheet(params) when is_map(params) do
    # `Map.get/2`, which is how every other screen in this app reads a push —
    # see `Kati.ScreenParamsSweepTest`, whose whole subject is that one
    # spelling is what lets a sweep find the keys a screen reads.
    tracked_id = Map.get(params, :tracked_id)
    episode_source_id = Map.get(params, :episode_source_id)

    if is_binary(tracked_id) and is_binary(episode_source_id),
      do: asked_sheet_for(tracked_id, episode_source_id)
  end

  def asked_sheet(_params), do: nil

  defp asked_sheet_for(tracked_id, episode_source_id) do
    case Ash.get(TrackedTitle, tracked_id) do
      {:ok, tracked} ->
        history = episode_history(tracked_id, episode_source_id)
        cached_title = cached_title_for(tracked)
        cached_episode = CachedEpisode.by_reference(tracked.source, episode_source_id)

        shaped(tracked, cached_title, cached_episode, history, episode_source_id)

      _gone ->
        nil
    end
  rescue
    _ -> nil
  end

  @doc """
  Screen 144 exactly as it is drawn, from `Kati.Screens.RateEpisode.Sample`.

  Kept in the fixture rather than inlined here, for the reason
  `Kati.Screens.Rating.drawn_watch/0` gives: it is the frame's specification,
  and two copies of the drawing's own copy is how they drift apart.
  """
  @spec drawn_sheet() :: map()
  def drawn_sheet, do: Sample.sheet()

  @doc """
  The user's newest episode log, shaped for the markup, or `nil`.

  `nil` is the ordinary answer on a fresh install, and the one `sheet/0` reads
  as "draw the drawing". `Ash.read!` mid-migration raises, and this sheet
  showing its own drawn values is strictly better than this sheet not
  rendering at all — see `Kati.Screens.Rating.logged_watch/0` for the same
  rescue, for the same reason.
  """
  @spec logged_sheet() :: map() | nil
  def logged_sheet do
    case newest_episode_log() do
      nil ->
        nil

      logged ->
        history =
          with_subject(
            episode_history(logged.tracked_title_id, logged.episode_source_id),
            logged
          )

        cached_title = cached_title_for(logged.tracked_title)

        cached_episode =
          CachedEpisode.by_reference(logged.tracked_title.source, logged.episode_source_id)

        shaped(
          logged.tracked_title,
          cached_title,
          cached_episode,
          history,
          logged.episode_source_id
        )
    end
  rescue
    _ -> nil
  end

  # The newest EPISODE-level log — see `Kati.Screens.Rating.newest_log/0` for
  # the title-level rule this narrows. `watched_at` first, `inserted_at`
  # behind it, for the reason given there: a log with no instant still orders
  # by when it was written down.
  #
  # A VERDICT first, and any tick behind it. The narrower query alone is what
  # made this sheet undrawable: it asks for an episode watch carrying a rating
  # or a review, and the app's only episode-level writer — `Kati.Screens.
  # Series.write_tick/2` — creates the row with neither, because a tick is not
  # a verdict. So on a phone with fifty ticked episodes the query answered
  # `nil` and the sheet drew The Long Hollow, on a screen whose whole purpose
  # is to put the FIRST rating on an episode you have just watched. The tick
  # is the subject; the rating is what this sheet adds to it.
  defp newest_episode_log do
    rated_episode_log() || ticked_episode_log()
  end

  defp rated_episode_log do
    Watch
    |> Ash.Query.filter(
      not is_nil(episode_source_id) and
        (not is_nil(rating) or (not is_nil(review) and review != ""))
    )
    |> Ash.Query.sort(watched_at: :desc, inserted_at: :desc)
    |> Ash.Query.load(:tracked_title)
    |> Ash.Query.limit(1)
    |> Ash.read!()
    |> List.first()
  end

  defp ticked_episode_log do
    Watch
    |> Ash.Query.filter(not is_nil(episode_source_id))
    |> Ash.Query.sort(watched_at: :desc, inserted_at: :desc)
    |> Ash.Query.load(:tracked_title)
    |> Ash.Query.limit(1)
    |> Ash.read!()
    |> List.first()
  end

  # Every LOGGED watch of this one episode, newest first — ticks with no
  # rating and no review are excluded, because they are not a verdict either
  # card on this sheet can quote. `for_episode` is the value-pair Watch
  # already reads episode ticks by; this adds the same rating-or-review gate
  # `newest_episode_log/0` uses so both queries agree on what counts as a log.
  defp episode_history(tracked_title_id, episode_source_id) do
    Watch
    |> Ash.Query.for_read(:for_episode, %{
      tracked_title_id: tracked_title_id,
      episode_source_id: episode_source_id
    })
    |> Ash.Query.filter(not is_nil(rating) or (not is_nil(review) and review != ""))
    |> Ash.Query.sort(watched_at: :desc, inserted_at: :desc)
    |> Ash.read!()
  end

  # The subject at the head of its own history.
  #
  # `episode_history/2` answers verdicts, and the subject may be a bare tick —
  # see `newest_episode_log/0`. `hd(history)` is what `shaped/4` fills the
  # sheet from, so the subject has to be in the list it is the head of, or the
  # sheet draws somebody else's rating over the episode you just watched (and,
  # on an episode with no verdicts at all, `hd/1` raises on `[]`).
  #
  # Prepended rather than sorted in: it is the newest by construction, both
  # queries order by the same two columns, and a tick made in the same second
  # as a verdict would otherwise be a coin toss.
  defp with_subject(history, subject) do
    if Enum.any?(history, &(&1.id == subject.id)), do: history, else: [subject | history]
  end

  # One read, by the VALUE PAIR the durable half references the cache by —
  # see `Kati.Screens.Rating.cached_for/1`.
  defp cached_title_for(%TrackedTitle{source: source, source_id: source_id}) do
    CachedTitle
    |> Ash.Query.filter(source == ^source and source_id == ^source_id)
    |> Ash.read_one!()
  end

  @doc """
  One logged episode watch, shaped for the markup — the season/episode
  number, the headline (masked when `spoiler_safe?`), the same headline masked
  whatever the preference says (`masked_headline`, which is what the
  spoiler-safe swatch draws), the rating, the review, the three context rows,
  and the quoted verdict before this one, if there is one.
  """
  @spec shaped(
          TrackedTitle.t(),
          CachedTitle.t() | nil,
          CachedEpisode.t() | nil,
          [Watch.t()],
          String.t() | nil
        ) :: map()
  def shaped(tracked, cached_title, cached_episode, history, episode_source_id \\ nil) do
    zone = Kati.Time.device_zone()
    today = Kati.Time.today()
    # `List.first/1` and not `hd/1`: an episode opened from its rating column
    # may never have been watched, and *"rating an unwatched episode ticks it
    # watched"* is this board's own note. So an empty history is the ordinary
    # first-rating case rather than an error.
    newest = List.first(history)

    rewatch? = length(history) > 1
    spoiler_safe? = tracked.hide_unwatched_titles and not rewatch?

    season = season_number(cached_episode, newest)
    episode = episode_number(cached_episode, newest)

    title =
      if spoiler_safe?, do: spoiler_title(episode), else: cached_episode_title(cached_episode)

    %{
      watch_id: newest && newest.id,
      # What Save writes when there is no row yet. The pair is the episode's
      # own identity everywhere else in this app — `Kati.Media.Watch.
      # for_episode` reads by it and `Kati.Screens.Series.write_tick/2` writes
      # by it — so a rating made before a tick creates exactly the row a tick
      # would have.
      tracked_title_id: tracked.id,
      episode_source_id: episode_source_id || (newest && newest.episode_source_id),
      season_number: season,
      episode_number: episode,
      headline: headline(episode_label(season, episode), title),
      masked_headline: headline(episode_label(season, episode), spoiler_title(episode)),
      show_title: show_title(cached_title),
      spoiler_safe?: spoiler_safe?,
      rewatch?: rewatch?,
      rating: newest && newest.rating && newest.rating / 2,
      review: (newest && newest.review) || "",
      context: context_rows(newest, zone, today),
      previous: if(rewatch?, do: previous_verdict(Enum.at(history, 1), zone), else: nil)
    }
  end

  defp show_title(%CachedTitle{title: title}) when is_binary(title) and title != "", do: title
  defp show_title(_cached), do: "Untitled"

  defp cached_episode_title(%CachedEpisode{title: title}) when is_binary(title) and title != "",
    do: title

  defp cached_episode_title(_cached), do: "Untitled"

  defp spoiler_title(n) when is_integer(n), do: "Episode #{n}"
  defp spoiler_title(_n), do: "Episode"

  defp season_number(%CachedEpisode{season_number: n}, _watch) when is_integer(n), do: n
  defp season_number(_cached, %Watch{season_number: n}) when is_integer(n), do: n
  defp season_number(_cached, _watch), do: nil

  defp episode_number(%CachedEpisode{episode_number: n}, _watch) when is_integer(n), do: n
  defp episode_number(_cached, %Watch{episode_number: n}) when is_integer(n), do: n
  defp episode_number(_cached, _watch), do: nil

  # "S2 E6", the same reduction `Kati.Screens.Inbox.episode_line/1` performs —
  # a number a source left blank has no label rather than a guessed one.
  defp episode_label(season, episode) when is_integer(season) and is_integer(episode),
    do: "S#{season} E#{episode}"

  defp episode_label(_season, episode) when is_integer(episode), do: "E#{episode}"
  defp episode_label(_season, _episode), do: nil

  defp headline(label, title), do: [label, title] |> Enum.reject(&is_nil/1) |> Enum.join(" · ")

  # The three facts that make a log worth keeping later, in the drawing's own
  # order — see `Kati.Screens.Rating.context_rows/2` for the title-level twin.
  # `trailing` is `"now"` on the one row whose date is today's, and `nil` on
  # the other two: this board draws no chevron here at all, so `nil` is "no
  # picker wired", not "a control missing its trailing icon".
  # An episode nobody has watched yet has no log to describe, so the three
  # context rows say nothing rather than saying today.
  defp context_rows(nil, _zone, _today) do
    [
      %{key: :watched_on, icon: "event", title: "Watched on", sub: nil, trailing: nil},
      %{key: :where, icon: "tv", title: "Where", sub: nil, trailing: nil},
      %{key: :with, icon: "group", title: "With", sub: nil, trailing: nil}
    ]
  end

  defp context_rows(watch, zone, today) do
    date = log_date(watch, zone)
    hour = log_hour(watch, zone)

    [
      %{
        key: :watched_on,
        icon: "event",
        title: "Watched on",
        sub: when_label(date, hour, today),
        trailing: if(date == today, do: "now")
      },
      %{key: :where, icon: "tv", title: "Where", sub: where_label(watch), trailing: nil},
      %{key: :with, icon: "group", title: "With", sub: presence(watch.companions), trailing: nil}
    ]
  end

  @doc """
  The three rows restated from the sheet's own drafts rather than from the row.

  `Kati.Screens.Rating.context_of/1` does exactly this one screen up and for
  the same reason: the sub-line under *Where* has to say what was just chosen,
  and a row built once at mount cannot. `context_rows/3` still builds the
  opening state; this is what the card draws from the second tap on.
  """
  @spec context_of(map()) :: [map()]
  def context_of(s) do
    today = Kati.Time.today()

    Enum.map(s.context, fn row ->
      case row.key do
        :watched_on ->
          case Map.get(s, :watched_on) do
            nil ->
              row

            date ->
              %{
                row
                | sub: Kati.Screens.RateEpisode.day_label(date, today),
                  trailing: if(date == today, do: "now")
              }
          end

        :where ->
          case Map.get(s, :service) do
            nil -> row
            service -> %{row | sub: service}
          end

        :with ->
          case Map.get(s, :companions) do
            nil -> row
            companions -> %{row | sub: presence(companions)}
          end
      end
    end)
  end

  @doc """
  What a chosen day reads as, which is `Kati.Screens.Rating.recent_days/0`'s
  own wording rather than a second spelling of it.

      iex> Kati.Screens.RateEpisode.day_label(~D[2026-09-08], ~D[2026-09-08])
      "Today"
  """
  @spec day_label(Date.t(), Date.t()) :: String.t()
  def day_label(date, today) do
    Enum.find_value(Kati.Screens.Rating.recent_days(), Calendar.strftime(date, "%a %-d %b"), fn
      {label, ^date} -> if date == today, do: label, else: label
      _other -> nil
    end)
  end

  # `Tonight · 21:40` for today's date, `Today` with no hour, and the
  # weekday form `Kati.Screens.Rating.when_label/2` uses otherwise — the
  # drawing's own word for "just now" rather than a date that reads as
  # historical the moment it stops being today.
  defp when_label(nil, _hour, _today), do: nil
  defp when_label(date, nil, today) when date == today, do: "Today"
  defp when_label(date, hour, today) when date == today, do: "Tonight · " <> hour
  defp when_label(date, nil, _today), do: Calendar.strftime(date, "%a %-d %b")
  defp when_label(date, hour, _today), do: Calendar.strftime(date, "%a %-d %b") <> " · " <> hour

  defp log_date(%Watch{watched_on: %Date{} = date}, _zone), do: date

  defp log_date(%Watch{watched_at: %DateTime{} = at}, zone),
    do: at |> Kati.Time.in_zone(zone) |> DateTime.to_date()

  defp log_date(%Watch{}, _zone), do: nil

  defp log_hour(%Watch{watched_at: %DateTime{} = at}, zone),
    do: at |> Kati.Time.in_zone(zone) |> Calendar.strftime("%H:%M")

  defp log_hour(%Watch{}, _zone), do: nil

  defp where_label(%Watch{service: service, place: place}) do
    [service, place]
    |> Enum.map(&presence/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" · ")
    |> presence()
  end

  defp presence(value) when is_binary(value) do
    case String.trim(value) do
      "" -> nil
      trimmed -> trimmed
    end
  end

  defp presence(_value), do: nil

  # The verdict the cream card quotes — the logged watch just before the
  # newest one, for this same episode. `date` is `nil`-safe: a watch recorded
  # with no instant and no date still has a rating and a review worth
  # quoting.
  defp previous_verdict(watch, zone) do
    %{
      date: previous_date_label(watch, zone),
      rating_label: Rating.rating_label(watch.rating && watch.rating / 2),
      review: watch.review || ""
    }
  end

  defp previous_date_label(watch, zone) do
    case log_date(watch, zone) do
      nil -> nil
      date -> Calendar.strftime(date, "%-d %b %Y")
    end
  end

  def render(assigns) do
    s = assigns.sheet
    expanded? = assigns.verdict_expanded?
    refusal = Kati.Screens.RateEpisode.refusal(Map.get(assigns, :save_error))

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
          {Kati.Screens.RateEpisode.header()}
          {Kati.Screens.RateEpisode.title_block(s)}
          {refusal}
          {Kati.Screens.RateEpisode.rating_card(s)}
          {Kati.Screens.RateEpisode.rewatch_block(s, expanded?)}
          {Kati.Screens.RateEpisode.review_card(s)}
          {Kati.Screens.RateEpisode.context_card(s, Map.get(assigns, :open_row))}
          {Kati.Screens.RateEpisode.info_note(s)}
          {Kati.Screens.RateEpisode.spoiler_swatch(s)}
          {Kati.Screens.RateEpisode.rewatch_swatch(s, expanded?)}
        </Column>
      </Box>
    </Box>
    """
  end

  @doc false
  def header do
    save = {self(), :save}

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        {Sheet.close_disc()}
        <Spacer weight={1.0} />
        <Text
          text="Rate this episode"
          text_size={15}
          font_weight="bold"
          text_color={:on_surface}
          max_lines={1}
        />
        <Spacer weight={1.0} />
        {Kati.Screens.RateEpisode.save_pill(save)}
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc """
  The commit pill, at this board's own 34pt — not screen 33's 38pt.

  `Kati.Components.MishkaPill`, the same call `Kati.Screens.Rating.save_pill/1`
  makes, with this drawing's own numbers: `height: 34`, `corner_radius: 17`,
  `14` of side padding, an `12.5pt` label. `padding: 0` is load-bearing for
  the reason given there — the pill always writes a `padding` key, and an
  unpinned vertical default would sit the drawing's 34pt pill inside two rows
  of `:space_sm`.
  """
  def save_pill(tap) do
    MishkaPill.pill(
      label: "Save",
      background: Palette.ink_fill(),
      color: Palette.on_ink(),
      height: 34,
      corner_radius: 17,
      padding: 0,
      padding_left: 14,
      padding_right: 14,
      text_size: 12.5,
      font_weight: :bold,
      align: :center,
      on_tap: tap
    )
  end

  @doc false
  def title_block(s) do
    ~MOB"""
    <Column fill_width={true}>
      <Text
        text={s.headline}
        text_size={19}
        font_weight="bold"
        letter_spacing={-0.025}
        text_color={:on_surface}
        text_align="center"
        max_lines={1}
      />
      <Spacer size={5} />
      <Text
        text={s.show_title}
        text_size={12.5}
        text_color={Palette.muted()}
        text_align="center"
        max_lines={1}
      />
      <Spacer size={18} />
    </Column>
    """
  end

  @doc """
  The rating card: `Kati.Screens.Rating.stars/1` and `.rating_label/1`,
  called rather than redrawn — see the moduledoc for why a second copy of the
  half-star crop is a second place for it to drift. `HALF STEPS` is a plain
  mono label here, not screen 33's `5★`/`10pt` `Kati.Components.
  MishkaSegmentedControl` toggle — this board draws no second scale, so there
  is no toggle to build.
  """
  def rating_card(s) do
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
          <Text
            text={String.upcase("Rating")}
            font_family="mono"
            text_size={10.5}
            letter_spacing={0.16}
            text_color={Palette.eyebrow()}
            max_lines={1}
          />
          <Spacer weight={1.0} />
          <Text
            text={String.upcase("Half steps")}
            font_family="mono"
            text_size={11}
            text_color={Palette.tertiary()}
            max_lines={1}
          />
        </Row>
        <Spacer size={13} />
        <Row fill_width={true} align="center">
          {Rating.stars(s.rating, Kati.Screens.RateEpisode.writable?(s))}
          <Spacer size={12} />
          <Text
            text={Rating.rating_label(s.rating)}
            font_family="mono"
            text_size={14}
            text_color={:on_surface}
            max_lines={1}
          />
        </Row>
      </Column>
      <Spacer size={12} />
    </Column>
    """
  end

  @doc """
  The rewatch reference, above the input — `nil` when this is not one.

  `SettingsList.eyebrow_muted/1` is the drawing's own recipe for the label
  above the card: a `#C4BDB3` dash and grey-eyebrow mono caps, which is
  exactly what `Rewatch — your last verdict, above the input` is drawn as.

  This is the card in its **live** position, which is what the label's own
  words describe. `rewatch_swatch/2` draws the same label and card under the
  note when this sheet is not a rewatch, and the two are mutually exclusive —
  see the moduledoc for why one card, in exactly one of the two places, is
  the whole of that rule.
  """
  def rewatch_block(%{rewatch?: false}, _expanded?), do: ~MOB"<Spacer size={0} />"

  def rewatch_block(%{previous: previous}, expanded?) do
    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.eyebrow_muted("Rewatch — your last verdict, above the input")}
      {Kati.Screens.RateEpisode.verdict_card(previous, expanded?)}
      <Spacer size={14} />
    </Column>
    """
  end

  @doc """
  The cream card itself — date and score always visible, the quoted review
  collapsed to two lines until tapped open.

  The whole card carries `on_tap`, the way `Kati.Screens.Calendar.airing/1`
  wires its own opening card, rather than only the header row: a collapsible
  region reads as one control, and a dead half of it is a tap the sweep would
  flag. See the moduledoc for why this is hand-rolled rather than
  `Kati.Components.MishkaCollapsible` — the header mixes a glyph into a run
  of mono text, which a `title:` string cannot hold.
  """
  def verdict_card(previous, expanded?) do
    tap = {self(), :toggle_verdict}

    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.cream()}
      corner_radius={20}
      padding={16}
      on_tap={tap}
    >
      <Row fill_width={true} align="center">
        {Kati.Screens.RateEpisode.verdict_meta(previous)}
        <Spacer weight={1.0} />
        {Kati.Screens.RateEpisode.verdict_chevron(expanded?)}
      </Row>
      <Spacer size={9} />
      <Text
        text={previous.review}
        text_size={13}
        line_height={1.65}
        text_color={Palette.cream_body()}
        max_lines={if(expanded?, do: nil, else: 2)}
      />
    </Column>
    """
  end

  # "YOU, 3 MAR 2024 · ★4" — three runs, because the star is a glyph and not
  # the character it looks like. No gap around it, for the reason
  # `Kati.Screens.Rating.scale_star/2` gives its own tight numeral+glyph pair:
  # a Spacer here would read as "· ★ 4" instead of "· ★4".
  #
  # `String.upcase/1` because the board sets this line
  # `text-transform:uppercase`, the same as every other letter-spaced mono
  # label on this sheet — `rating_card/1`'s, `review_card/1`'s,
  # `spoiler_swatch/1`'s and `SettingsList.eyebrow_muted/1`'s all upcase, and
  # a lowercase run at `0.14` tracking is the one that looks wrong. Only the
  # prefix carries letters; `rating_label` is a numeral or `—`.
  @doc false
  def verdict_meta(%{date: date, rating_label: label}) do
    prefix = if date, do: String.upcase("You, #{date} · "), else: String.upcase("You · ")

    ~MOB"""
    <Row align="center">
      <Text
        text={prefix}
        font_family="mono"
        text_size={10}
        letter_spacing={0.14}
        text_color={Palette.cream_meta()}
        max_lines={1}
      />
      {Kati.UI.symbol("star", size: 10, color: Palette.cream_meta(), fill: true)}
      <Text
        text={label}
        font_family="mono"
        text_size={10}
        letter_spacing={0.14}
        text_color={Palette.cream_meta()}
        max_lines={1}
      />
    </Row>
    """
  end

  # `Kati.Screens.Calendar.chevron/1`'s own construction, reused rather than
  # reinvented — see the moduledoc for why `expand_less` is not something to
  # add to the subset for this.
  @doc false
  def verdict_chevron(false),
    do: Kati.UI.symbol("expand_more", size: 17, color: Palette.gold_icon())

  def verdict_chevron(true) do
    ~MOB"""
    <Box width={17} height={17} rotate={180.0} align="center">
      {Kati.UI.symbol("expand_more", size: 17, color: Palette.gold_icon())}
    </Box>
    """
  end

  @doc """
  The review card: the drawing's placeholder when nothing is written yet, the
  logged review otherwise — either way ending in `caret/0`, `Kati.Screens.
  Rating`'s own construction for a cursor this bridge cannot draw inline.
  """
  def review_card(s) do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={17}
      >
        <Text
          text={String.upcase("Review")}
          font_family="mono"
          text_size={10.5}
          letter_spacing={0.16}
          text_color={Palette.eyebrow()}
          max_lines={1}
        />
        <Spacer size={9} />
        {Kati.Screens.RateEpisode.review_body(s.review)}
      </Column>
      <Spacer size={12} />
    </Column>
    """
  end

  @doc false
  def review_body(review) when review in [nil, ""] do
    ~MOB"""
    <Column fill_width={true}>
      <Text
        text="What did you make of it?"
        text_size={13.5}
        line_height={1.6}
        text_color={Palette.tertiary()}
      />
      {Kati.Screens.RateEpisode.caret()}
    </Column>
    """
  end

  def review_body(review) do
    ~MOB"""
    <Column fill_width={true}>
      <Text text={review} text_size={13.5} line_height={1.6} text_color={Palette.ink_soft()} />
      {Kati.Screens.RateEpisode.caret()}
    </Column>
    """
  end

  # There is no inline node on this bridge — a Box beside a wrapping Text is
  # a sibling, not a run — so the caret draws at the start of the line below
  # the body, which is where a cursor lands when the line above ends exactly
  # at its own edge. `Kati.Screens.Rating`'s own recording of the same gap.
  @doc false
  def caret do
    ~MOB"""
    <Row fill_width={true}>
      <Box width={2} height={16} background={Palette.accent()} />
    </Row>
    """
  end

  @doc """
  The three context rows, each of which opens under itself.

  ## Board 204, and the decision behind this

  Board 204 rules that screen 33 keeps three chevrons that PUSH and that this
  board *"gains the chevrons, keeps its now"* — three rows, three destinations.
  MOVIES-AND-TV.md #95 had settled the same question the opposite way one
  screen up, and #155 filed the disagreement as the owner's to settle rather
  than reversing a design a second time in silence.

  The owner settled it on 8 September: **disclose in place, on both screens.**
  So this gains what board 204 asked for and screen 33 already had — the rows
  are live, and they open a row of chips under themselves rather than a page.
  The reasoning is `Kati.Screens.Rating.context_card/1`'s and is board 201's
  own argument turned around: *"a person logging a watch is logging tonight's,
  or last night's"*, and a date you pick from four chips does not need a
  screen of its own.

  The mono `now` stays, which is the half of board 204 that was never in
  dispute.

  One row is open at a time, for the reason screen 33 gives: two open editors
  in one card is a card that jumps under the thumb, and the reader is
  answering one question anyway.
  """
  @spec context_card(map(), atom() | nil) :: map()
  def context_card(s, open \\ nil) do
    live? = Kati.Screens.RateEpisode.editable?(s)
    rows = Kati.Screens.RateEpisode.context_of(s)
    last = length(rows) - 1

    body =
      rows
      |> Enum.with_index()
      |> Enum.flat_map(fn {row, i} ->
        [
          SettingsList.row(
            SettingsList.icon_tile(row.icon),
            SettingsList.body(row.title, row.sub),
            Kati.Screens.RateEpisode.row_trailing(row.trailing),
            padding: 13,
            rule: i < last,
            on_tap: if(live?, do: {self(), Kati.Screens.RateEpisode.row_tag(row.key)})
          ),
          Kati.Screens.RateEpisode.editor(row.key, s, live? and open == row.key)
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
  Whether the three rows are controls at all.

  A sheet with no row behind it and nothing to create one is board 144 as a
  picture, and a picture's rows do not open — the rule this round keeps
  everywhere. Both live cases are editable: a watch that exists takes an
  update, and one Save will create means the drafts have somewhere to land.

      iex> Kati.Screens.RateEpisode.editable?(%{watch_id: "abc"})
      true

      iex> Kati.Screens.RateEpisode.editable?(%{watch_id: nil})
      false
  """
  @spec editable?(map()) :: boolean()
  def editable?(sheet) do
    is_binary(Map.get(sheet, :watch_id)) or Kati.Screens.RateEpisode.writable?(sheet)
  end

  @doc """
  A row's tap.

      iex> Kati.Screens.RateEpisode.row_tag(:watched_on)
      :row_watched_on

  Named for the key rather than the label, which MOVIES-AND-TV.md #158 is the
  argument for.
  """
  @spec row_tag(atom()) :: atom()
  def row_tag(key), do: Kati.Screens.AddByHand.tag("row_", key)

  @doc """
  What one row discloses when it is the open one.

  Screen 33's own controls, called rather than restated:
  `Kati.Screens.Rating.recent_days/0`, `where_options/1`, `no_service/0`,
  `choice/3` and `commit_pill/2`. Two sheets asking the same three questions
  with two sets of chips would drift within a release, and the drift would be
  invisible — both would look right on their own board.
  """
  @spec editor(atom(), map(), boolean()) :: map()
  def editor(_key, _sheet, false), do: ~MOB"<Spacer size={0} />"

  def editor(:watched_on, sheet, true) do
    chosen = Map.get(sheet, :watched_on)

    assigns = %{
      chips:
        Kati.Screens.Rating.recent_days()
        |> Enum.map(fn {label, date} ->
          Kati.Screens.Rating.choice(label, "day_" <> Date.to_iso8601(date), date == chosen)
        end)
        |> Enum.intersperse(Kati.Screens.Rating.tag_gap())
    }

    ~MOB"""
    <Column fill_width={true} padding_left={13} padding_right={13} padding_bottom={13}>
      <Row fill_width={true} align="center">
        {@chips}
      </Row>
    </Column>
    """
  end

  def editor(:where, sheet, true) do
    options = Kati.Screens.Rating.where_options(sheet)

    assigns = %{
      chips:
        (options ++ [Kati.Screens.Rating.no_service()])
        |> Enum.map(
          &Kati.Screens.Rating.choice(&1, "where_" <> &1, &1 == Map.get(sheet, :service))
        )
        |> Enum.intersperse(Kati.Screens.Rating.tag_gap()),
      empty?: options == []
    }

    ~MOB"""
    <Column fill_width={true} padding_left={13} padding_right={13} padding_bottom={13}>
      <Row fill_width={true} align="center">
        {@chips}
      </Row>
      {Kati.Screens.Rating.where_note(@empty?)}
    </Column>
    """
  end

  def editor(:with, sheet, true) do
    assigns = %{
      change: {self(), :with_draft},
      draft: Map.get(sheet, :with_draft) || Map.get(sheet, :companions) || "",
      commit: Kati.Screens.Rating.commit_pill("Done", :commit_with)
    }

    ~MOB"""
    <Column fill_width={true} padding_left={13} padding_right={13} padding_bottom={13}>
      <Row fill_width={true} align="center">
        <TextField
          value={@draft}
          placeholder="Jo, and whoever else"
          return_key="done"
          weight={1.0}
          accessibility_id="with_draft"
          on_change={@change}
        />
        <Spacer size={9} />
        {@commit}
      </Row>
    </Column>
    """
  end

  @doc false
  def row_trailing(nil), do: nil

  def row_trailing(text) do
    ~MOB"""
    <Text text={text} font_family="mono" text_size={11} text_color={Palette.meta()} max_lines={1} />
    """
  end

  @doc """
  `check_circle` — *rating an unwatched episode ticks it watched*. Gone the
  moment a prior log exists, because the episode has plainly already been
  watched once, and the note has nothing left to tell that user.
  """
  def info_note(%{rewatch?: true}), do: ~MOB"<Spacer size={0} />"

  def info_note(_s) do
    body = [text_size: 12.5, line_height: 1.65, text_color: Palette.cream_body()]

    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.RateEpisode.note(body)}
      <Spacer size={14} />
    </Column>
    """
  end

  @doc false
  def note(body) do
    Sheet.insight("check_circle", [
      {"Rating an unwatched episode ", body},
      {"ticks it watched",
       [text_size: 12.5, line_height: 1.65, text_color: Palette.cream_ink(), font_weight: "bold"]},
      {" — you cannot have an opinion about something you have not seen, and asking twice is a needless tap.",
       body}
    ])
  end

  @doc """
  The `Spoiler-safe variant` swatch: what the headline above turns into when
  `hide_unwatched_titles` is on.

  The board's own card — `#FBFAF8` at radius 20, 15pt padding, the card's soft
  lift — with the eyebrow and its `visibility_off` glyph on one row, then the
  masked headline and the show under it, both centred. The eyebrow is a
  **10pt** mono at `0.14` tracking, not the 10.5/`0.16` `rating_card/1` and
  `review_card/1` set: those two label live sections a user reads, this one
  labels a variant, and the drawing sets the two apart by exactly that step.
  So it is written here rather than borrowed from `Kati.UI.eyebrow/2`, which
  would also bring the accent dash this card does not draw.

  The headline is `masked_headline`, never a frozen string — see the
  moduledoc for why a swatch showing the drawing's episode over a live log
  would be the one value on this sheet that is not what it claims to be.

  Suppressed once `spoiler_safe?` is actually on, for the reason
  `rewatch_swatch/2` suppresses itself on a rewatch and `info_note/1` does the
  same: a swatch is a demonstration of a state, and demonstrating the state you
  are already in draws the masked headline twice — once live at the top of the
  sheet, once again in a card captioned as a variant of it. The board draws
  both swatches unconditionally because a board has no live state to collide
  with; a screen does.
  """
  def spoiler_swatch(%{spoiler_safe?: true}), do: ~MOB"<Spacer size={0} />"

  def spoiler_swatch(s) do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={20}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={15}
      >
        <Row fill_width={true} align="center">
          <Text
            text={String.upcase("Spoiler-safe variant")}
            font_family="mono"
            text_size={10}
            letter_spacing={0.14}
            text_color={Palette.eyebrow()}
            max_lines={1}
          />
          <Spacer weight={1.0} />
          {Kati.UI.symbol("visibility_off", size: 16, color: Palette.sub())}
        </Row>
        <Spacer size={11} />
        <Text
          text={s.masked_headline}
          text_size={17}
          font_weight="bold"
          letter_spacing={-0.02}
          text_color={:on_surface}
          text_align="center"
          max_lines={1}
        />
        <Spacer size={5} />
        <Text
          text={s.show_title}
          text_size={12}
          text_color={Palette.muted()}
          text_align="center"
          max_lines={1}
        />
      </Column>
      <Spacer size={14} />
    </Column>
    """
  end

  @doc """
  The rewatch swatch, under the note — drawn only when the live sheet is not
  itself a rewatch.

  When it is, `rewatch_block/2` has already drawn the same label and the same
  `verdict_card/2` above the input, which is where the label's own words put
  it, and a second cream card down here would be the same control twice. When
  it is not, there is no earlier verdict to quote and the board's own is what
  the swatch is for: `Kati.Screens.RateEpisode.Sample.reference_verdict/0`,
  the `You, 3 Mar 2024 · ★4` the drawing sets.

  It is the live `verdict_card/2`, not a still of one — the board's caption
  argues the card is **collapsible**, and a swatch that could not be opened
  would be documenting the half of that claim anyone can already see.
  """
  def rewatch_swatch(%{rewatch?: true}, _expanded?), do: ~MOB"<Spacer size={0} />"

  def rewatch_swatch(_s, expanded?) do
    previous = Sample.reference_verdict()

    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.eyebrow_muted("Rewatch — your last verdict, above the input")}
      {Kati.Screens.RateEpisode.verdict_card(previous, expanded?)}
    </Column>
    """
  end

  def handle_info({:tap, :close}, socket), do: {:noreply, Kati.Screens.Resume.pop(socket)}

  def handle_info({:tap, :save}, socket) do
    case Kati.Screens.RateEpisode.save_rating(socket.assigns.sheet) do
      {:ok, _watch} ->
        {:noreply, Kati.Screens.Resume.pop(socket)}

      :nothing_to_save ->
        {:noreply, Kati.Screens.Resume.pop(socket)}

      {:error, reason} ->
        {:noreply, Mob.Socket.assign(socket, :save_error, Kati.Write.message({:error, reason}))}
    end
  end

  # `with_draft` is typed rather than tapped, so it arrives as a change and not
  # as a tap. Screen 33 carries the same pair for the same field.
  def handle_info({:change, :with_draft, typed}, socket) when is_binary(typed),
    do: {:noreply, Kati.Screens.RateEpisode.draft(socket, :with_draft, typed)}

  def handle_info({:tap, :commit_with}, socket),
    do: {:noreply, Kati.Screens.RateEpisode.commit_with(socket)}

  def handle_info({:tap, :toggle_verdict}, socket) do
    {:noreply,
     Mob.Socket.assign(socket, :verdict_expanded?, not socket.assigns.verdict_expanded?)}
  end

  # A star, or one of the three disclosed rows. Every other tag this sheet
  # draws has its own clause above, so a tag that is none of these falls
  # through rather than being read as rating `nil`.
  def handle_info({:tap, tag}, socket) when is_atom(tag) do
    case Atom.to_string(tag) do
      "row_" <> key ->
        {:noreply, Kati.Screens.RateEpisode.disclose(socket, key)}

      "day_" <> iso ->
        {:noreply, Kati.Screens.RateEpisode.commit_day(socket, iso)}

      "where_" <> service ->
        {:noreply, Kati.Screens.RateEpisode.commit_where(socket, service)}

      _star ->
        case Rating.point_of(tag) do
          nil -> {:noreply, socket}
          point -> {:noreply, Kati.Screens.RateEpisode.pick(socket, point)}
        end
    end
  end

  def handle_info(_msg, socket), do: {:noreply, socket}

  @doc """
  Whether this sheet has a row to write a rating onto.

  The drawing has none — `Kati.Screens.RateEpisode.Sample.sheet/0` is four
  stars and a half over an episode of a series nobody is tracking — so its
  stars stay a picture. Drawing ten tap targets over them would make Save on
  a fresh install look like it did something, which is the exact defect this
  screen was reported for.

      iex> Kati.Screens.RateEpisode.writable?(%{watch_id: "abc"})
      true

      iex> Kati.Screens.RateEpisode.writable?(Kati.Screens.RateEpisode.Sample.sheet())
      false
  """
  @spec writable?(map()) :: boolean()
  def writable?(sheet) do
    is_binary(Map.get(sheet, :watch_id)) or
      (is_binary(Map.get(sheet, :tracked_title_id)) and
         is_binary(Map.get(sheet, :episode_source_id)))
  end

  @doc """
  Take a rating on the sheet, in the five-point display scale the stars draw.

  The assign only — the write happens on Save, the same order screen 33 uses,
  because a star is a thing you slide past on the way to the one you meant.

      iex> socket = Mob.Socket.assign(Mob.Socket.new(Kati.Screens.RateEpisode), :sheet, %{rating: nil})
      iex> Kati.Screens.RateEpisode.pick(socket, 9).assigns.sheet.rating
      4.5
  """
  @spec pick(Mob.Socket.t(), 1..10) :: Mob.Socket.t()
  def pick(socket, point) do
    sheet = %{socket.assigns.sheet | rating: point / 2}

    socket
    |> Mob.Socket.assign(:sheet, sheet)
    |> Mob.Socket.assign(:save_error, nil)
  end

  @doc """
  Open one context row, or close it by pressing the one already open.

  A key this sheet never drew closes whatever is open rather than raising —
  `Kati.Screens.SeriesSettings` records why a tap handler on a pushed screen
  must not: it is a dead process and a bounce to Home.
  """
  @spec disclose(Mob.Socket.t(), String.t()) :: Mob.Socket.t()
  def disclose(socket, key) do
    wanted =
      Enum.find([:watched_on, :where, :with], fn row -> Atom.to_string(row) == key end)

    open = if wanted && Map.get(socket.assigns, :open_row) != wanted, do: wanted

    Mob.Socket.assign(socket, :open_row, open)
  end

  @doc "Take a day chip. The row closes behind it, which is what one tap answering one question looks like."
  @spec commit_day(Mob.Socket.t(), String.t()) :: Mob.Socket.t()
  def commit_day(socket, iso) do
    case Date.from_iso8601(iso) do
      {:ok, date} ->
        socket
        |> Kati.Screens.RateEpisode.put(:watched_on, date)
        |> Mob.Socket.assign(:open_row, nil)

      _unparseable ->
        socket
    end
  end

  @doc """
  Take a service chip, or *Not on a service*, which stores nothing.

  `nil` rather than the words: a watch's `service` column holds a place, and
  the sentence saying there was none is a label rather than one.
  """
  @spec commit_where(Mob.Socket.t(), String.t()) :: Mob.Socket.t()
  def commit_where(socket, service) do
    value = if service == Kati.Screens.Rating.no_service(), do: nil, else: service

    socket
    |> Kati.Screens.RateEpisode.put(:service, value)
    |> Mob.Socket.assign(:open_row, nil)
  end

  @doc "Keep what was typed into the *With* field without committing it."
  @spec draft(Mob.Socket.t(), atom(), String.t()) :: Mob.Socket.t()
  def draft(socket, field, typed),
    do: Kati.Screens.RateEpisode.put(socket, field, typed)

  @doc "Commit the *With* draft. An empty field clears the row rather than storing a blank."
  @spec commit_with(Mob.Socket.t()) :: Mob.Socket.t()
  def commit_with(socket) do
    typed = socket.assigns.sheet |> Map.get(:with_draft, "") |> to_string() |> String.trim()

    socket
    |> Kati.Screens.RateEpisode.put(:companions, if(typed == "", do: nil, else: typed))
    |> Mob.Socket.assign(:open_row, nil)
  end

  @doc false
  @spec put(Mob.Socket.t(), atom(), term()) :: Mob.Socket.t()
  def put(socket, field, value) do
    socket
    |> Mob.Socket.assign(:sheet, Map.put(socket.assigns.sheet, field, value))
    |> Mob.Socket.assign(:save_error, nil)
  end

  @doc """
  Write the sheet's rating onto the episode watch it was opened over.

  `Kati.Screens.Rating.ten_point/1` for the scale, because the column is
  1..10 and the stars are five — the same conversion, called rather than
  repeated, for the reason the moduledoc gives about the half-star crop.

  `:nothing_to_save` rather than an error when there is no row: Save on the
  drawing closes the sheet, which is what a picture's button should do, and it
  is not a failure worth putting a red line under.
  """
  @spec save_rating(map()) :: {:ok, struct()} | {:error, term()} | :nothing_to_save
  def save_rating(sheet) do
    cond do
      is_binary(Map.get(sheet, :watch_id)) -> update_rating(sheet)
      writable?(sheet) -> create_rating(sheet)
      true -> :nothing_to_save
    end
  rescue
    error -> Kati.Write.note({:error, error}, "rate an episode")
  end

  defp update_rating(sheet) do
    case Ash.get(Watch, sheet.watch_id) do
      {:ok, record} ->
        record
        |> Ash.Changeset.for_update(
          :update,
          Map.merge(%{rating: Rating.ten_point(sheet.rating)}, context_changes(sheet))
        )
        |> Ash.update()
        |> Kati.Write.note("rate an episode")

      error ->
        Kati.Write.note(error, "rate an episode")
    end
  end

  # Only what the reader actually touched. A sheet whose rows were never opened
  # must not write `nil` over a service somebody set on screen 33 — the three
  # context keys are absent from the sheet until an editor commits one, which
  # is what makes "absent" and "cleared" different here.
  #
  # `watched_on` also moves `watched_at`, because the two are one fact: a row
  # dated yesterday whose timestamp says tonight would put the same watch on
  # two days depending on which column the reader is looking through.
  defp context_changes(sheet) do
    %{}
    |> put_if(sheet, :watched_on)
    |> put_if(sheet, :service)
    |> put_if(sheet, :companions)
    |> then(fn changes ->
      case Map.fetch(changes, :watched_on) do
        {:ok, %Date{} = date} -> Map.put(changes, :watched_at, midday(date))
        _absent -> changes
      end
    end)
  end

  defp put_if(changes, sheet, key) do
    case Map.fetch(sheet, key) do
      {:ok, value} -> Map.put(changes, key, value)
      :error -> changes
    end
  end

  # Midday rather than midnight: `Kati.Time.zone/0` can shift a midnight stamp
  # across the date line in either direction, and a watch logged "yesterday"
  # that reads as the day before is the defect this is here to avoid.
  defp midday(date) do
    date
    |> DateTime.new!(~T[12:00:00], "Etc/UTC")
    |> DateTime.truncate(:second)
  end

  # The first watch of this episode, made BY the rating. Board 144's own note
  # is the rule: *"Rating an unwatched episode ticks it watched — you cannot
  # have an opinion about something you have not seen, and asking twice is a
  # needless tap."* So this writes the row `Kati.Screens.Series.write_tick/2`
  # would have written, with the rating already on it, and then asks that
  # screen to restate the shelf — one tick more may be the tick that finishes
  # the series, and the status has to follow the ticks wherever they are made.
  defp create_rating(sheet) do
    %{
      tracked_title_id: sheet.tracked_title_id,
      episode_source_id: sheet.episode_source_id,
      season_number: Map.get(sheet, :season_number),
      episode_number: Map.get(sheet, :episode_number),
      rating: Rating.ten_point(sheet.rating),
      watched_at: Kati.Time.now(),
      watched_on: Kati.Time.today()
    }
    |> Map.merge(context_changes(sheet))
    |> then(&Ash.create(Watch, &1))
    |> case do
      {:ok, watch} ->
        Kati.Screens.Series.restate(sheet.tracked_title_id)
        {:ok, watch}

      error ->
        Kati.Write.note(error, "rate an episode")
    end
  end

  @doc """
  The red line under the header when a save was refused, or nothing.

  Same shape as `Kati.Screens.Season.refusal/1` and screen 04's — one recipe
  for "the store said no", so a user meets the same sentence wherever they
  meet it.
  """
  @spec refusal(String.t() | nil) :: map()
  def refusal(nil), do: ~MOB"<Spacer size={0} />"

  def refusal(message) do
    assigns = %{message: message}

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.notice(@message)}
      <Spacer size={12} />
    </Column>
    """
  end
end
