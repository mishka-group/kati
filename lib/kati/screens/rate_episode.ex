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

  def mount(_params, _session, socket) do
    Mob.Theme.set(Kati.Theme.current())

    {:ok,
     socket
     |> Mob.Socket.assign(:sheet, sheet())
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
  @spec sheet() :: map()
  def sheet, do: logged_sheet() || drawn_sheet()

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
        history = episode_history(logged.tracked_title_id, logged.episode_source_id)
        cached_title = cached_title_for(logged.tracked_title)

        cached_episode =
          CachedEpisode.by_reference(logged.tracked_title.source, logged.episode_source_id)

        shaped(logged.tracked_title, cached_title, cached_episode, history)
    end
  rescue
    _ -> nil
  end

  # The newest EPISODE-level log — see `Kati.Screens.Rating.newest_log/0` for
  # the title-level rule this narrows. `watched_at` first, `inserted_at`
  # behind it, for the reason given there: a log with no instant still orders
  # by when it was written down.
  defp newest_episode_log do
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
  @spec shaped(TrackedTitle.t(), CachedTitle.t() | nil, CachedEpisode.t() | nil, [Watch.t()]) ::
          map()
  def shaped(tracked, cached_title, cached_episode, history) do
    zone = Kati.Time.device_zone()
    today = Kati.Time.today()
    newest = hd(history)

    rewatch? = length(history) > 1
    spoiler_safe? = tracked.hide_unwatched_titles and not rewatch?

    season = season_number(cached_episode, newest)
    episode = episode_number(cached_episode, newest)

    title =
      if spoiler_safe?, do: spoiler_title(episode), else: cached_episode_title(cached_episode)

    %{
      headline: headline(episode_label(season, episode), title),
      masked_headline: headline(episode_label(season, episode), spoiler_title(episode)),
      show_title: show_title(cached_title),
      spoiler_safe?: spoiler_safe?,
      rewatch?: rewatch?,
      rating: newest.rating && newest.rating / 2,
      review: newest.review || "",
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
  defp context_rows(watch, zone, today) do
    date = log_date(watch, zone)
    hour = log_hour(watch, zone)

    [
      %{
        icon: "event",
        title: "Watched on",
        sub: when_label(date, hour, today),
        trailing: if(date == today, do: "now")
      },
      %{icon: "tv", title: "Where", sub: where_label(watch), trailing: nil},
      %{icon: "group", title: "With", sub: presence(watch.companions), trailing: nil}
    ]
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
          {Kati.Screens.RateEpisode.header()}
          {Kati.Screens.RateEpisode.title_block(s)}
          {Kati.Screens.RateEpisode.rating_card(s)}
          {Kati.Screens.RateEpisode.rewatch_block(s, expanded?)}
          {Kati.Screens.RateEpisode.review_card(s)}
          {Kati.Screens.RateEpisode.context_card(s)}
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
          {Rating.stars(s.rating)}
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

  @doc "The three context rows: `SettingsList.card/1` and `.row/4`, no chevron."
  def context_card(s) do
    rows = s.context
    last = length(rows) - 1

    body =
      rows
      |> Enum.with_index()
      |> Enum.map(fn {row, i} ->
        SettingsList.row(
          SettingsList.icon_tile(row.icon),
          SettingsList.body(row.title, row.sub),
          Kati.Screens.RateEpisode.row_trailing(row.trailing),
          padding: 13,
          rule: i < last
        )
      end)

    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.card(body)}
      <Spacer size={14} />
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

  def handle_info({:tap, :close}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}
  def handle_info({:tap, :save}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}

  def handle_info({:tap, :toggle_verdict}, socket) do
    {:noreply,
     Mob.Socket.assign(socket, :verdict_expanded?, not socket.assigns.verdict_expanded?)}
  end

  def handle_info(_msg, socket), do: {:noreply, socket}
end
