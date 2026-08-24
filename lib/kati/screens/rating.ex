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

  ## The caret sits on the next line

  The review body ends with the design's 2x16 orange text cursor. There is no
  inline node in this bridge — a `Box` beside a wrapping `Text` is a sibling,
  not a run — so the caret is drawn at the start of the line below the body,
  which is where a cursor lands when a line ends exactly at its edge. Recorded
  rather than faked with an offset that would drift with every font metric.

  ## Which half of a write path this is: it READS a watch, it does not write one

  `Kati.Media.Watch` models this sheet column for column — rating, review,
  `contains_spoilers`, `rewatch_number`, `watched_on` beside `watched_at`,
  `service`, `place`, `companions`, `tags` — and its own moduledoc names screen
  33 four times over. So the question was not *whether* this screen belongs to
  that resource but *which direction*, and the answer the screen itself gives is
  **read**.

  **The drawing is a filled-in sheet, and only a stored watch can fill it.** The
  rating is set, the review is typed, the spoiler toggle is on, three context
  rows have values and three tags are attached. A sheet composing a *new* watch
  has none of that: it is five empty cards, which is not this drawing and not
  anything screen 27's empty state would call a state either. The only thing in
  the app that looks like this picture is a watch that already exists — so this
  screen reads the newest one and shows it, which is what reopening a log to
  edit it looks like.

  **Nothing on this sheet can change a value, so there is nothing to save.**
  The whole screen draws exactly three tap targets — `close`, `save` and
  `+ tag`. The five stars carry no `on_tap`, the `5★`/`10pt` toggle carries
  none, the three context rows are `Kati.UI.SettingsList` rows with a chevron
  and no handler, and the review body is a `Text` with a drawn caret rather than
  a `TextField`. A `Save` wired today would write back, to the value, exactly
  what it had just read. What the write half needs first is those controls: a
  tap target per star (and per half), a real text field for the review, a picker
  behind each context row, and `:add_tag` doing something — after which
  `Kati.Media.Watch`'s `create: :*` and `update: :*` already accept every one of
  these columns and the changeset is a dozen lines.

  One consequence worth writing down before that lands:
  `Kati.ScreenTapSweepTest` taps **every** control **every** screen draws, in
  both locales, against the one shared SQLite file — the suite has no Ecto
  sandbox. The day `:save` writes, that sweep starts creating `Kati.Media.Watch`
  rows that every other sweep then renders. The fix is for the write to go
  through something the sweep can point at a scratch database, not for the sweep
  to skip the tag.

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
    * **`HALF STARS ON · TAP LEFT OR RIGHT OF CENTRE`, and the `5★`/`10pt`
      toggle.** Both are display preferences — which scale the user reads
      ratings on — and no resource holds one. `Kati.Media.Watch.rating` is the
      ten-point integer either way, and screen 35's settings are where a scale
      preference would live. So both stay the drawing's, on a real watch as on
      the fallback, and the note is taken from the one place that copy lives
      rather than written out a second time here.
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

  def mount(_params, _session, socket) do
    Mob.Theme.set(Kati.Theme.current())
    {:ok, Mob.Socket.assign(socket, :watch, watch())}
  end

  @doc """
  The watch this sheet draws: the user's newest log, or the drawing's.

  The gate is the whole sheet rather than each card, for the reason
  `Kati.Screens.Film.film/0` gives: a page whose review is the user's own and
  whose title is somebody else's film reads as entirely real. Either every value
  on it is this watch's or every value is the drawing's.
  """
  @spec watch() :: map()
  def watch, do: logged_watch() || drawn_watch()

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
    case newest_log() do
      nil -> nil
      logged -> shaped(logged.tracked_title, cached_for(logged.tracked_title), logged)
    end
  rescue
    _ -> nil
  end

  # The newest thing the user logged rather than ticked — see the moduledoc for
  # why a tick cannot fill this sheet. `watched_at` first because that is the
  # night the log is about; `inserted_at` behind it so a watch recorded with no
  # instant ("I have seen this, I do not remember when") still orders by when it
  # was written down rather than arbitrarily.
  defp newest_log do
    Watch
    |> Ash.Query.filter(not is_nil(rating) or (not is_nil(review) and review != ""))
    |> Ash.Query.sort(watched_at: :desc, inserted_at: :desc)
    |> Ash.Query.load(:tracked_title)
    |> Ash.Query.limit(1)
    |> Ash.read!()
    |> List.first()
  end

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
      context: context_rows(logged, zone),
      tags: tag_list(logged.tags)
    }
  end

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

    ~MOB"""
    <Box
      fill_width={true}
      fill_height={true}
      background={:background}
      layout_direction={Kati.Locale.direction_prop()}
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
          {Kati.Screens.Rating.scale_toggle()}
        </Row>
        <Spacer size={14} />
        <Row fill_width={true} align="center">
          {Kati.Screens.Rating.stars(w.rating)}
          <Spacer size={12} />
          <Text
            text={Kati.Screens.Rating.rating_label(w.rating)}
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
  @doc false
  def scale_toggle do
    tiles =
      Sample.scales()
      |> Enum.map(&Kati.Screens.Rating.scale/1)
      |> Enum.intersperse(Kati.Screens.Rating.scale_gap())

    ~MOB"""
    <Row background={Palette.paper()} corner_radius={11} padding={3} align="center">
      {tiles}
    </Row>
    """
  end

  @doc false
  def scale_gap, do: ~MOB"<Spacer size={3} />"

  @doc false
  def scale(%{on: true} = option) do
    ~MOB"""
    <Row
      height={24}
      corner_radius={8}
      background={Palette.card()}
      shadow="0 1 2 0 #1F1A1917"
      padding_left={10}
      padding_right={10}
      align="center"
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

  def scale(option) do
    ~MOB"""
    <Row height={24} corner_radius={8} padding_left={10} padding_right={10} align="center">
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
  """
  @spec rating_label(number() | nil) :: String.t()
  def rating_label(nil), do: "—"

  def rating_label(value) do
    whole = trunc(value)
    if value == whole, do: Integer.to_string(whole), else: "#{value}"
  end

  # Five empty stars, which is what "you have not rated this" looks like —
  # `Kati.Screens.Film.star_count/1` gives the same answer for the same reason.
  @doc false
  def stars(nil), do: stars(0)

  def stars(value) do
    full = trunc(value)
    half? = value - full >= 0.5

    slots =
      Enum.map(1..5, fn i ->
        cond do
          i <= full -> :full
          i == full + 1 and half? -> :half
          true -> :empty
        end
      end)

    ~MOB"""
    <Row align="center">
      {slots |> Enum.map(&Kati.Screens.Rating.star/1) |> Enum.intersperse(Kati.Screens.Rating.star_gap())}
    </Row>
    """
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
          {Kati.Screens.Rating.spoiler_toggle(w.spoilers)}
        </Row>
        <Spacer size={10} />
        <Text text={w.review} text_size={14} line_height={1.6} text_color={Palette.cream_body()} />
        <Row fill_width={true}>
          <Box width={2} height={16} background={Palette.accent()} />
        </Row>
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
  """
  def spoiler_toggle(nil), do: ~MOB"<Spacer size={0} />"

  def spoiler_toggle(label) do
    ~MOB"""
    <Row>
      {Kati.UI.symbol("visibility_off", size: 15, color: Palette.gold_icon())}
      <Spacer size={6} />
      <Text
        text={label}
        text_size={11}
        font_weight="semibold"
        text_color={Palette.gold_text()}
        max_lines={1}
      />
    </Row>
    """
  end

  @doc false
  def context_card(w) do
    rows = w.context
    last = length(rows) - 1

    body =
      rows
      |> Enum.with_index()
      |> Enum.map(fn {row, i} ->
        SettingsList.row(
          SettingsList.icon_tile(row.icon),
          SettingsList.body(row.title, row.sub),
          SettingsList.chevron(),
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

  # Row, not a wrapping field: the four chips measure ~315 inside the 360pt
  # content width, so the drawing's `flex-wrap` never actually wraps here.
  @doc false
  def tags(w) do
    chips =
      (Enum.map(w.tags, &Kati.Screens.Rating.tag/1) ++ [Kati.Screens.Rating.add_tag()])
      |> Enum.intersperse(Kati.Screens.Rating.tag_gap())

    ~MOB"""
    <Row fill_width={true} align="center">
      {chips}
    </Row>
    """
  end

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
  def tag(label) do
    MishkaPill.pill(
      label: label,
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
  def add_tag do
    tap = {self(), :add_tag}

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

  def handle_info({:tap, :close}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}
  def handle_info({:tap, :save}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}
  def handle_info(_msg, socket), do: {:noreply, socket}
end
