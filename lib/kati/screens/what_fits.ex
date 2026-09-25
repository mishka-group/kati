defmodule Kati.Screens.WhatFits do
  @moduledoc """
  Screen 13 — What fits?, pushed under Library.

  Built to `test/design/screens/13.html`: a cream card carrying the window
  of time you actually have, then the episodes and films that fit inside it, then the
  nearest thing that does not.

  Cream is doing the same job here as on Home and on screen 08 — it marks the
  one block that is *yours* rather than the library's. The window is an input,
  not a statistic, so its buttons sit on `rgba(255,255,255,.6)` wells inside the
  cream instead of on cards of their own.

  The last section is the honest half of the feature: the design labels it
  `Nothing else fits — nearest film is 1h 46m` under a **grey** dash, and draws
  the row flat on `#F4F1EC` with a `Tomorrow` button. Telling the user what was
  excluded, and offering to move it rather than hiding it, is why the screen is
  worth having; a filter that silently drops things is just a shorter list.

  The four mood chips hug their labels, which is what a chip is, so they are
  `Kati.Components.MishkaChip`.

  The five window buttons are `flex:1` in the drawing, so each is a
  `Box weight={1.0}` around a `fill_width` box, and they stay hand-rolled.
  They are chips by behaviour — one of them is selected — but `MishkaChip`
  hardcodes `fill_width={false}` on its root and offers no way to override it:
  its only sizing escape hatch is an exact `width`, which a `flex:1` row does
  not know. A `fill_width` prop on the chip, defaulting to `false` so no
  existing chip moves, is what this needs. `MishkaPill` has exactly that prop
  and would draw them, but its own docs send anything with a checked state to
  the chip, and a selected/unselected pair is precisely what these are.

  ## Where every row comes from

  The tracked shelf, and nothing else. `fitting/1` lists what the reader could
  start now and finish inside the window: each show's NEXT episode
  (`Kati.Media.NextEpisode.of/1` over the bookmark) when it has aired and its
  own `Kati.Media.CachedEpisode.runtime_minutes` fits, and each film not yet
  finished or dropped whose `Kati.Media.CachedTitle.runtime_minutes` fits —
  longest first. `nearest_over/1` is the shortest of those films that does NOT
  fit, measured against the chosen window. The clock is `Kati.Time`. A shelf
  with nothing on it says so (`fits_label/2`) rather than *nothing fits*.

  `Kati.Screens.WhatFits.Sample` is board 13's own evening and is reached only
  through `drawn_tonight/0`, which the design-literal test installs, and by
  screen 96, which borrows the window card as a reference drawing. No reader
  path draws it.

  ## What the board draws and this page does not

    * **The mood chips** — `Light`, `Tense`, `Long-form`. `Kati.Media.Watch.moods`
      is a real column and nothing writes it, so a chip over it narrows nothing
      and is not drawn; the overflow disc goes with it, having nothing to hold.
    * **The `Tomorrow` pill** on the over-budget row. Nothing records a
      deferral — see `defer_pill/1` — so the offer is not made.

  ## Board 310 — the third page screen 92's sentence names

  *Hide titles I can't watch* prints *Removes them from Discover, Up next and
  What fits tonight*, and the app had cut that to two pages. This was the
  missing one, and honestly so: while the list was a fixture, a switch that
  claimed to filter it would have been the promise the rule was reported for.

  `watchable/1` closes it, on `shelf/1` so both halves of the page are filtered
  by one rule — the episodes that fit and the film that does not. 310's own
  note is the argument for counting rather than remembering: *"Three, counted
  from the filter and not from memory."*
  """
  use Kati.Screens.Pushed, back: "Library"
  use Gettext, backend: Kati.Gettext

  alias Kati.Components.MishkaActionIcon
  alias Kati.Components.MishkaChip
  alias Kati.Components.MishkaPill
  alias Kati.Media.CachedEpisode
  alias Kati.Media.Release
  alias Kati.Media.TrackedTitle
  alias Kati.Screens.WhatFits.Sample
  alias Kati.Theme.Palette
  alias Kati.UI

  # The five windows the drawing offers, in minutes. `2h+` is a ceiling and not
  # a bound — everything fits in it — so it is the largest runtime this app is
  # ever going to see rather than 120.
  #
  # `20m` here is a KEY and never a word. It is the suffix of the tag
  # `window_20m`, which is what `Mob.Renderer` derives the node's
  # `accessibility_id` from and what `set_window/2` looks the window up by, so
  # it stays Latin ASCII in both scripts. The word the button says is
  # `window_word/1` — mishka-group/kati#103, where this table was drawn
  # straight and a Persian reader got `20m` under `۴۵ دقیقه`.
  @windows [{"20m", 20}, {"30m", 30}, {"45m", 45}, {"1h", 60}, {"2h+", 600}]
  @default_window 45

  # The kinds an episode can belong to, and the kind the over-budget row is.
  # `Kati.Screens.Season`'s own list, less nothing: a film has no episodes and
  # is exactly what the second half of this screen is about.
  @series_kinds [:tv, :anime]

  @impl true
  def load(socket) do
    socket
    |> Mob.Socket.assign(:window, @default_window)
    |> Mob.Socket.assign(:tonight, Kati.Screens.WhatFits.tonight(@default_window))
  end

  @impl true
  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "window_" <> label ->
        {:noreply, Kati.Screens.WhatFits.set_window(socket, label)}

      "open_" <> index ->
        {:noreply, Kati.Screens.WhatFits.open(socket, index)}

      # Board 96's button, on the band this screen draws when nothing is set
      # up (#120). All four of the sheet's routes lead to one place.
      "my_services_" <> _band ->
        {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.MyServices)}

      _other ->
        {:noreply, socket}
    end
  end

  @doc """
  Tonight, measured against a window: the reader's shelf, or `empty_tonight/1`.

  The board's caption is *"Set the window you actually
  have and the library filters itself"* and none of the eleven controls on the
  page carried a tap — `grep -n 'on_tap\|handle_tap'` returned nothing across
  424 lines — over a fixture that could not be filtered anyway.

  The list is `fitting/1` — each show's next aired episode and each unwatched
  film that fits, longest first, because the point of a window is to use it.
  The over-budget row is `nearest_over/1`, the nearest unwatched FILM that does
  not fit, which is the row the screen exists for — `Nothing else fits` is only
  worth saying about something.

  The fourth is still absent and is an axis rather than a value: **mood**.
  `Kati.Media.CachedTitle.genres` is a genre, which is a different claim about
  a title, and `Kati.Media.Watch.tags` is per-watch and written afterwards. So
  the chips are dropped over a real list rather than drawn dead — the rule
  screen 35 settled for a group with no schema — and the board keeps all four.
  """
  @spec tonight(pos_integer()) :: map()
  def tonight(minutes \\ @default_window) do
    Kati.Screens.WhatFits.real_tonight(minutes) ||
      Kati.Screens.WhatFits.empty_tonight(minutes)
  end

  @doc """
  The window with nothing that fits in it.

  `real_tonight/1` answers nil for two reasons and only one of them is "nothing
  fits": it is wrapped in a `rescue`, so a read that raised landed here too. It
  was `drawn_tonight/0` — the board's own evening, at *Sunday, 21:40* — so a
  reader with nothing on their shelf was handed four films to pick between, and
  a database Kati could not read was handed the same four.

  The clock and the window are the reader's own, because both are true of them
  whatever is on the shelf: `clock/0` reads the device and `window_label/1` is
  the length they chose. The lengths rail keeps its five buckets for the same
  reason screen 34 keeps its order strip — it is what can be ASKED, not an
  answer.
  """
  @spec empty_tonight(pos_integer()) :: map()
  def empty_tonight(minutes \\ @default_window) do
    %{
      now: Kati.Screens.WhatFits.clock(),
      window: Kati.Screens.WhatFits.window_label(minutes),
      lengths:
        Enum.map(@windows, fn {key, m} ->
          %{key: key, label: Kati.Screens.WhatFits.window_word(key), selected: m == minutes}
        end),
      moods: [],
      fits_label: Kati.Screens.WhatFits.fits_label([], Kati.Screens.WhatFits.shelf_empty?()),
      fits: [],
      over_label: nil,
      over: nil
    }
  end

  @doc "Screen 13 exactly as it is drawn."
  @spec drawn_tonight() :: map()
  def drawn_tonight, do: Sample.tonight()

  @doc false
  @spec real_tonight(pos_integer()) :: map() | nil
  def real_tonight(minutes) do
    fits = Kati.Screens.WhatFits.fitting(minutes)
    over = Kati.Screens.WhatFits.nearest_over(minutes)

    if fits == [] and is_nil(over) do
      nil
    else
      %{
        now: Kati.Screens.WhatFits.clock(),
        window: Kati.Screens.WhatFits.window_label(minutes),
        # The key and the word are two fields because they are two things —
        # see `@windows` and `window_word/1`.
        lengths:
          Enum.map(@windows, fn {key, m} ->
            %{key: key, label: Kati.Screens.WhatFits.window_word(key), selected: m == minutes}
          end),
        # `Kati.Media.Watch.moods` exists and is `[]` on every device, because
        # none of its five writers sets it — see `tonight/1`. A chip that
        # cannot narrow anything is dropped rather than drawn dead.
        moods: [],
        fits_label: Kati.Screens.WhatFits.fits_label(fits),
        fits: fits,
        # One msgid with the length in it rather than a sentence glued to a
        # figure: `#{over.length}` put a translated duration at the end of an
        # English clause, and Persian ends this sentence with the copula —
        # `نزدیک‌ترین فیلم ۱ ساعت ۴۶ دقیقه است` — which no interpolation at the
        # tail can reach.
        over_label:
          over && gettext("Nothing else fits — nearest film is %{length}", length: over.length),
        over: over
      }
    end
  rescue
    _error -> nil
  end

  @doc false
  def clock do
    now = Kati.Time.now() |> Kati.Time.in_zone(Kati.Time.device_zone())

    # `Calendar.strftime(now, "%A, %H:%M")` was the English day name and Latin
    # digits in both scripts: `%A` has no locale to consult — Elixir's default
    # calendar names its days in English — and `%H:%M` never converts numerals.
    # So a Persian reader's evening read `Sunday, 21:40` under a Persian title.
    #
    # The comma is the sentence's own punctuation and goes in the msgid, where
    # Persian can spell it `،`.
    gettext("%{day}, %{time}",
      day: Kati.Screens.WhatFits.weekday(now),
      time: Kati.Locale.time(now)
    )
  end

  @doc false
  # A weekday NAMED, with no day of the month beside it — the one shape
  # `Kati.Locale` has no helper for: `weekday_initial/1` is a chart axis's
  # single letter and `date/2`'s `:full` carries the day and the month as well.
  # So the pick is here, over the same two tables those two read, exactly as
  # `Kati.Screens.Meal`'s and `Kati.Screens.QuickAdd`'s own `weekday/1` do it.
  @spec weekday(DateTime.t()) :: String.t()
  def weekday(%DateTime{} = at) do
    date = DateTime.to_date(at)

    Kati.Locale.pick(
      Kati.Time.day_name(date),
      Kati.Calendar.Shamsi.weekday_name(Kati.Calendar.Shamsi.weekday_index(date))
    )
  end

  @doc """
  The window as the big number over the buttons.

      iex> Kati.Screens.WhatFits.window_label(45)
      "45 min"

      iex> Kati.Screens.WhatFits.window_label(60)
      "1 hr"

      iex> Kati.Screens.WhatFits.window_label(600)
      "2 hr+"

  Spelled out — `45 min`, not `45m` — because this is the 40pt display line and
  the compact form belongs to the buttons under it. `%{n} min` is the msgid
  `Kati.Screens.Series` and `Kati.Screens.Inbox` already write an episode's
  length with; a window and a runtime are measured in the same minute and two
  spellings of it is how two screens come to disagree.
  """
  @spec window_label(pos_integer()) :: String.t()
  # The ceiling takes a context: `%{n} hr+` is one character from `%{n} hr` and
  # `mix gettext.merge` would fuzzy-match it onto that entry, dropping the plus
  # — which is the whole of what this window means.
  def window_label(600),
    do: pgettext("the largest window, a ceiling", "%{n} hr+", n: Kati.Locale.number(2))

  def window_label(60), do: gettext("%{n} hr", n: Kati.Locale.number(1))
  def window_label(minutes), do: gettext("%{n} min", n: Kati.Locale.number(minutes))

  @doc """
  The word on a window button, which is **not** its key.

      iex> Kati.Screens.WhatFits.window_word("45m")
      "45m"

  `20m` was one string doing two jobs: `length_button/2` drew it and
  `handle_tap/2` parsed it back out of the tag `window_20m`. Translating the
  table would therefore have translated the tag — and with it the
  `accessibility_id` `Mob.Renderer` derives from it — so a Persian device would
  have had five nodes no device test could address. A key is what a control
  *is*; a label is what it *says*. They are two things now.

  The words are the app's own minute and hour msgids rather than five new ones:
  `Kati.Screens.Library.runtime_line/1` and `Kati.Screens.Season`'s episode
  runtime both spell a duration exactly this way already.
  """
  @spec window_word(String.t()) :: String.t()
  def window_word("20m"), do: gettext("%{n}m", n: Kati.Locale.number(20))
  def window_word("30m"), do: gettext("%{n}m", n: Kati.Locale.number(30))
  def window_word("45m"), do: gettext("%{n}m", n: Kati.Locale.number(45))
  def window_word("1h"), do: gettext("%{n}h", n: Kati.Locale.number(1))

  # The ceiling's own context again, and for the same fuzzy-match reason
  # `window_label/1` records.
  def window_word("2h+"),
    do: pgettext("the largest window, a ceiling", "%{n}h+", n: Kati.Locale.number(2))

  # A key nobody drew a word for answers itself rather than raising: the table
  # above is the only caller and a sixth window would be a code change, but a
  # screen that crashes over a button label is the wrong way to find that out.
  def window_word(key) when is_binary(key), do: key

  @doc """
  The eyebrow over the list: how many things fit, or why nothing does.

  The rows are episodes and films together, so the count names neither.
  `ngettext/4` because English moves the verb and Persian does not inflect a
  noun after a numeral. An empty window keeps a sentence of its own — `0 fit`
  is the plausible-looking zero screen 96's rule is about — and a shelf with
  nothing on it says THAT, because *nothing fits that window* would send the
  reader off to try another window over an empty shelf.
  """
  @spec fits_label([map()], boolean()) :: String.t()
  def fits_label(fits, shelf_empty? \\ false)
  def fits_label([], true), do: gettext("Nothing on your shelf to measure yet")
  def fits_label([], _shelf), do: gettext("Nothing fits that window")

  def fits_label(fits, _shelf) do
    n = length(fits)
    ngettext("%{n} fits tonight", "%{n} fit tonight", n, n: Kati.Locale.number(n))
  end

  @doc """
  Whether the reader has nothing on the screen shelf at all — no series, no
  anime, no film — before any availability rule is applied.
  """
  @spec shelf_empty?() :: boolean()
  def shelf_empty? do
    Enum.all?([:tv, :anime, :movie], fn kind ->
      TrackedTitle
      |> Ash.Query.for_read(:shelf, %{kind: kind})
      |> Ash.Query.limit(1)
      |> Ash.read!()
      |> Enum.empty?()
    end)
  rescue
    _error -> false
  end

  @doc """
  What the reader could start now and finish inside the window, longest first.

  Two kinds of row, both off the tracked shelf:

    * **a series' next episode** — `Kati.Media.NextEpisode.of/1`, the first
      cached episode after the bookmark, which is the one definition of *next*
      Home, Up next and the widget share — when it has aired
      (`Kati.Media.Release.airing/2`) and its own `CachedEpisode.runtime_minutes`
      fits. One row per show, because the episode after it is not what fits
      tonight: this one is. A dropped show offers nothing.
    * **a film** whose `Kati.Media.CachedTitle.runtime_minutes` fits and that
      the reader has not finished or dropped.

  Longest first because the point of a window is to fill it: a reader with 45
  minutes and a 41-minute episode wants the 41, not the 20. A runtime nobody
  knows is left out rather than assumed short.
  """
  @spec fitting(pos_integer()) :: [map()]
  def fitting(minutes) do
    now = Kati.Time.now()

    episodes =
      Kati.Screens.WhatFits.series()
      |> Enum.reject(fn {tracked, _cached} -> tracked.status == :dropped end)
      |> Enum.flat_map(fn {tracked, cached} ->
        case Kati.Screens.WhatFits.next_episode(tracked) do
          %CachedEpisode{runtime_minutes: m} = e when is_integer(m) and m > 0 and m <= minutes ->
            if Release.airing(Release.air(e), now) == :upcoming,
              do: [],
              else: [Kati.Screens.WhatFits.fit_of(e, tracked, cached)]

          _none ->
            []
        end
      end)

    films =
      Kati.Screens.WhatFits.films()
      |> Enum.flat_map(fn {tracked, cached} ->
        case cached && cached.runtime_minutes do
          m when is_integer(m) and m > 0 and m <= minutes ->
            [Kati.Screens.WhatFits.film_fit(tracked, cached, m)]

          _over_or_unknown ->
            []
        end
      end)

    Enum.sort_by(episodes ++ films, & &1.minutes, :desc)
  end

  @doc """
  The cached episode `Kati.Media.NextEpisode.of/1` names for a show, or `nil`
  when nothing is cached after the bookmark.
  """
  @spec next_episode(TrackedTitle.t()) :: CachedEpisode.t() | nil
  def next_episode(tracked) do
    case Kati.Media.NextEpisode.of(tracked) do
      {s, e} ->
        tracked.source
        |> CachedEpisode.for_title(tracked.source_id)
        |> Enum.find(&(&1.season_number == s and &1.episode_number == e and not &1.special))

      nil ->
        nil
    end
  rescue
    _error -> nil
  end

  @doc """
  One film that fits, as a row: its title, its poster, the word *Film* where an
  episode prints its place, and its own length.
  """
  @spec film_fit(TrackedTitle.t(), term(), pos_integer()) :: map()
  def film_fit(tracked, cached, minutes) do
    %{
      title: Kati.Screens.WhatFits.name_of(cached),
      seed: cached && cached.poster_path,
      meta: UI.eyebrow_label(gettext("Film")),
      run: Kati.Screens.WhatFits.hours(minutes),
      minutes: minutes,
      tracked_id: tracked.id
    }
  end

  @doc false
  def fit_of(episode, tracked, cached) do
    %{
      title: Kati.Screens.WhatFits.name_of(cached),
      seed: cached && cached.poster_path,
      meta: Kati.Screens.WhatFits.place(episode),
      # `Kati.Screens.Season`'s own msgid, which is `41m` in Latin and
      # `۴۱ دقیقه` in Persian: the minute's abbreviation is a Latin convention
      # and Persian writes the word out.
      run: gettext("%{n}m", n: Kati.Locale.number(episode.runtime_minutes)),
      minutes: episode.runtime_minutes,
      tracked_id: tracked.id
    }
  end

  @doc """
  `S3 · E2`, and each half dropped rather than faked.

  `Kati.Media.CachedEpisode` calls an invented placeholder *"a string a
  provider invented"*, and a special a source never placed has neither number.

  `ف۳ · ق۲` under `:fa`, and the prefix is an abbreviation of a WORD — فصل for
  a season, قسمت for an episode — so it is translated rather than kept as a
  Latin initial. Three clauses rather than a join, because a sentence assembled
  from pieces is one a translator cannot reorder: the pair is
  `Kati.Screens.Library`'s own `S%{s} · E%{e}` and the two halves are the
  contexts `Kati.Screens.Inbox` and `Kati.Screens.Season` already spell.

  The season alone takes a context of its own: `S` in this app also means a
  SPECIAL — `Kati.Screens.Season`'s `pgettext("special number", "S%{n}")` is
  `و%{n}` — and one msgid cannot be both.
  """
  @spec place(CachedEpisode.t()) :: String.t()
  def place(%{season_number: s, episode_number: e}) when is_integer(s) and is_integer(e),
    do: gettext("S%{s} · E%{e}", s: Kati.Locale.number(s), e: Kati.Locale.number(e))

  def place(%{season_number: s}) when is_integer(s),
    do: pgettext("season number", "S%{s}", s: Kati.Locale.number(s))

  def place(%{episode_number: e}) when is_integer(e),
    do: pgettext("episode number", "E%{e}", e: Kati.Locale.number(e))

  def place(_unplaced), do: ""

  @doc """
  The nearest film that does NOT fit, or nothing.

  Nearest over, because *nothing else fits* is a sentence about the thing you
  almost had time for. Only films still to be watched — `films/0` — and a film
  with no runtime cannot be measured and is not offered as the one you nearly
  fitted in.
  """
  @spec nearest_over(pos_integer()) :: map() | nil
  def nearest_over(minutes) do
    Kati.Screens.WhatFits.films()
    |> Enum.flat_map(fn {tracked, cached} ->
      case cached && cached.runtime_minutes do
        m when is_integer(m) and m > minutes -> [{tracked, cached, m}]
        _fits_or_unknown -> []
      end
    end)
    |> Enum.min_by(fn {_t, _c, m} -> m end, fn -> nil end)
    |> case do
      nil ->
        nil

      {tracked, cached, m} ->
        %{
          title: Kati.Screens.WhatFits.name_of(cached),
          seed: cached.poster_path,
          length: Kati.Screens.WhatFits.hours(m),
          # `String.upcase/1` is a LATIN operation — the Arabic script has no
          # case at all — so the raise goes through `Kati.UI.eyebrow_label/1`,
          # which is the one place this app asks whether the reader's script
          # has a raised form. English is byte-for-byte the drawing's
          # `1H 46M · 61 MIN OVER`; Persian is left unraised.
          #
          # The whole line is one msgid rather than a length glued to a tail,
          # for the reason `over_label` gives: `MIN OVER` was a literal at the
          # end of a Persian sentence.
          meta:
            Kati.UI.eyebrow_label(
              gettext("%{length} · %{n} min over",
                length: Kati.Screens.WhatFits.hours(m),
                n: Kati.Locale.number(m - minutes)
              )
            ),
          # No column records a deferral — see `defer_pill/1` — so the row has
          # its film and not the board's offer.
          action: nil,
          tracked_id: tracked.id
        }
    end
  end

  @doc """
  `1h 46m`, the way the drawing writes a film's length.

      iex> Kati.Screens.WhatFits.hours(106)
      "1h 46m"

      iex> Kati.Screens.WhatFits.hours(120)
      "2h"

  `Kati.Screens.Library.runtime_line/1`'s three msgids rather than three more
  of this app's own: a film's length is the same sentence on the shelf and in
  this row, and two spellings of it is how two screens come to disagree.
  Persian writes the units out — `۱ ساعت ۴۶ دقیقه` — so the digits convert with
  them and the string is no longer a Latin run that needs isolating.
  """
  @spec hours(pos_integer()) :: String.t()
  def hours(minutes) do
    case {div(minutes, 60), rem(minutes, 60)} do
      {0, m} ->
        gettext("%{n}m", n: Kati.Locale.number(m))

      {h, 0} ->
        gettext("%{n}h", n: Kati.Locale.number(h))

      {h, m} ->
        gettext("%{h}h %{m}m", h: Kati.Locale.number(h), m: Kati.Locale.number(m))
    end
  end

  @doc false
  def name_of(%{title: title}) when is_binary(title) and title != "", do: title
  def name_of(_evicted), do: gettext("Untitled")

  @doc false
  def series, do: Kati.Screens.WhatFits.shelf(@series_kinds)

  @doc """
  The films on the shelf still to be watched: a film finished or dropped is
  not something the reader is choosing tonight, whether it fits or not.
  """
  def films do
    Kati.Screens.WhatFits.shelf([:movie])
    |> Enum.reject(fn {tracked, _cached} -> tracked.status in [:finished, :dropped] end)
  end

  # Through `:shelf`, which is what keeps a title the reader hid out of every
  # list in the app — including this one.
  @doc false
  def shelf(kinds) do
    kinds
    |> Enum.flat_map(fn kind ->
      TrackedTitle
      |> Ash.Query.for_read(:shelf, %{kind: kind})
      |> Ash.read!()
    end)
    |> Enum.map(&{&1, Kati.Media.Release.cached_for(&1)})
    |> Kati.Screens.WhatFits.watchable()
  end

  @doc """
  The rows left once *Hide titles I can't watch* has been applied.

  Board 310 is what makes this exist. Screen 92's sentence names three pages —
  *Removes them from Discover, Up next and What fits tonight* — and the app
  had cut it to two, because when the rule was wired this screen read a
  fixture and *"a switch that claimed to filter it would be the same promise
  the rule was reported for in the first place."* That stopped being true when
  `fitting/1` and `nearest_over/1` started reading the shelf, and 310 counts
  the filter rather than remembering it: three, and the sentence goes back.

  `Kati.Screens.UpNext.watchable/1` one screen over, and the shape is the
  same on purpose — one read of the reader for the whole list, the switch's
  default is off, and `Kati.Media.Availability.hide?/3` hides only what is
  KNOWN to be unavailable, so a device with no provider data behaves exactly
  as it did before. The one difference is that this list already carries its
  cached row beside each tracked one, so there is no second query to batch.
  """
  @spec watchable([{TrackedTitle.t(), term()}]) :: [{TrackedTitle.t(), term()}]
  def watchable([]), do: []

  def watchable(rows) do
    reader = Kati.Services.availability()

    if reader.rules[:hide_unavailable] do
      Enum.reject(rows, fn {_tracked, cached} ->
        Kati.Media.Availability.hide?(
          Kati.Media.Availability.offers(cached, reader.region),
          reader.subscribed,
          reader.rules
        )
      end)
    else
      rows
    end
  rescue
    _error -> rows
  end

  @doc """
  Set the window, and re-filter.

  Re-read rather than re-filtered in place: the list, its count, and the
  over-budget row and its `61 MIN OVER` are four views of one window, and a
  screen that moved the buttons and left the rows is the thing this finding is.
  """
  # `key` rather than `label`: what comes back off the tag is `@windows`' Latin
  # key and never the word the button said — see `window_word/1`.
  @spec set_window(Mob.Socket.t(), String.t()) :: Mob.Socket.t()
  def set_window(socket, key) do
    case List.keyfind(@windows, key, 0) do
      nil ->
        socket

      {_key, minutes} ->
        socket
        |> Mob.Socket.assign(:window, minutes)
        |> Mob.Socket.assign(:tonight, Kati.Screens.WhatFits.tonight(minutes))
    end
  end

  @doc """
  Open the row that was pressed: its show, or its film.

  The row IS the answer to *what fits* — a list you cannot act on is a list you
  read and then go somewhere else to use — so the whole row is the target
  rather than a play disc the drawing does not draw.

  The `back:` both pushes carry stays the English `What fits?`. It is a lookup
  key rather than a drawn string — `Kati.Screens.Pushed.back_label/2` translates
  it at render time and `back_vocabulary/0` is where its msgid is declared, so
  a Persian word here would be a pill the catalogue cannot answer.
  """
  @spec open(Mob.Socket.t(), String.t()) :: Mob.Socket.t()
  def open(socket, index) do
    row = Kati.Screens.WhatFits.row_at(socket.assigns.tonight, index)
    tracked_id = row && Map.get(row, :tracked_id)

    case tracked_id && Ash.get(Kati.Media.TrackedTitle, tracked_id) do
      {:ok, %{kind: :movie}} ->
        Mob.Socket.push_screen(socket, Kati.Screens.Film, %{id: tracked_id, back: "What fits?"})

      {:ok, _series} ->
        Mob.Socket.push_screen(socket, Kati.Screens.Series, %{
          tracked_id: tracked_id,
          back: "What fits?"
        })

      _gone ->
        socket
    end
  rescue
    _error -> socket
  end

  @doc false
  def content(assigns) do
    t = assigns.tonight

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {Kati.Screens.WhatFits.more_row(t.moods != [])}
        {Kati.Screens.WhatFits.header(t)}
        {Kati.Screens.WhatFits.window(t, true)}
        {UI.eyebrow(t.fits_label)}
        {Kati.Screens.WhatFits.unfiltered(t)}
        {Kati.Screens.WhatFits.fits(t)}
        {Kati.Screens.WhatFits.over_eyebrow(t.over_label)}
        {Kati.Screens.WhatFits.over(t)}
      </Column>
    </Scroll>
    """
  end

  # The back pill is Kati.Screens.Pushed's, floating at the left. This row
  # reserves its height and carries the overflow disc opposite it.
  @doc """
  The row the back pill sits in, and the overflow disc opposite it.

  The disc is the board's. It was drawn without a tap — one of this
  screen's eleven pictures — and there is nothing behind
  it: everything this page can do is on it. The mood chips were the one thing
  an overflow could have held and they have no VALUES either —
  `Kati.Media.Watch.moods` exists and nothing writes it — so a disc here
  would be a second promise of the same missing axis.

  So it goes with them, and the row it sat in stays: `Kati.Screens.Pushed`
  floats the back pill, and this is what reserves the space it occupies.
  """
  @spec more_row(boolean()) :: map()
  def more_row(drawn? \\ true) do
    assigns = %{
      disc: if(drawn?, do: Kati.Screens.WhatFits.more_disc(), else: ~MOB"<Spacer size={0} />")
    }

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} height={44} align="center">
        <Spacer weight={1.0} />
        {@disc}
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc """
  The overflow disc — Mishka's Action Icon, now that it can float.

  A floating disc is defined by its shadow. `action_icon/2` painted a fill and
  stopped there, which reads as a flat patch of card colour rather than as a
  control sitting above the paper, so this disc stayed hand-rolled; `shadow`
  takes the design's `Kati.Theme.shadow_button()` string untouched and closes
  that gap.

  Same pixels. `shape: :circle` is an exact `size / 2`, so 44 rounds at 22 as
  the literal did; the fill, the shadow and the centring pass straight
  through; and the glyph is the same `Kati.UI.symbol/2` Text, now inside a Row
  that hugs it — a hugging Row centred in a Box puts its one child where the
  bare Text sat.
  """
  @spec more_disc() :: map()
  def more_disc do
    MishkaActionIcon.action_icon(
      [
        size: 44,
        shape: :circle,
        variant: :filled,
        background: Palette.card(),
        shadow: Kati.Theme.shadow_button()
      ],
      [Kati.UI.symbol("more_horiz", size: 21)]
    )
  end

  @doc false
  # The title's `-0.03` becomes `Kati.Locale.tracking/1` and gains a
  # `max_lines={1}`: tracking prises apart the joins that make Persian legible,
  # and `چه چیزی جا می‌شود؟` is four words where the English is two, so an
  # uncapped display heading had room to wrap where the drawing has one line.
  #
  # `t.now` is set in mono, and `kati_mono.ttf` carries no Persian glyph — so
  # the face asks the STRING rather than the reader: `Sunday, 21:40` off
  # `Kati.Screens.WhatFits.Sample` is pure ASCII and keeps DM Mono, and
  # `یک‌شنبه، ۲۱:۴۰` off `clock/0` takes Vazirmatn at the mono size.
  def header(t) do
    ~MOB"""
    <Column fill_width={true}>
      <Text
        text={gettext("What fits?")}
        text_size={28}
        max_font_scale={1.6}
        font_weight="bold"
        letter_spacing={Kati.Locale.tracking(-0.03)}
        text_color={:on_surface}
        max_lines={1}
      />
      <Spacer size={5} />
      <Text
        text={t.now}
        font_family={Kati.Locale.mono_face(t.now)}
        text_size={11}
        text_color={Palette.muted()}
        max_lines={1}
      />
      <Spacer size={20} />
    </Column>
    """
  end

  @doc """
  The cream card: the window, its five buttons, and the moods when there are any.

  `live?` because screen 93 draws this whole card off
  `Kati.Screens.WhatFits.Sample` and answers none of its tags. A shared drawing
  does not get to hand another screen a control it cannot answer — the rule
  `Kati.Screens.Rating.scale_toggle/1` and `Kati.Screens.QuickAdd.kinds/2` both
  state for the rows they lend.

  The `TIME YOU HAVE` line is `Kati.UI.eyebrow/2`'s recipe hand-rolled on
  cream, so it takes all four of that function's locale questions rather than
  the one the audit caught: `String.upcase/1` is a Latin operation and becomes
  `Kati.UI.eyebrow_label/1`, `kati_mono.ttf` has no Arabic glyph so the face
  becomes `Kati.Locale.mono_face/0`, `.16em` is a small-caps effect that breaks
  Persian's joins so the tracking becomes `Kati.Locale.tracking/1`, and
  Vazirmatn wants 11pt semibold where DM Mono wants 10.5 normal. All four are
  no-ops in Latin, so the cream card draws exactly as it did.
  """
  @spec window(map(), boolean()) :: map()
  def window(t, live? \\ false) do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.cream()}
        corner_radius={24}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={19}
      >
        <Text
          text={Kati.UI.eyebrow_label(gettext("Time you have"))}
          font_family={Kati.Locale.mono_face()}
          text_size={Kati.Locale.pick(10.5, 11)}
          font_weight={Kati.Locale.pick("normal", "semibold")}
          letter_spacing={Kati.Locale.tracking(0.16)}
          text_color={Palette.cream_meta()}
        />
        <Spacer size={8} />
        <Text
          text={t.window}
          text_size={40}
          font_weight="extrabold"
          letter_spacing={Kati.Locale.tracking(-0.04)}
          text_color={:on_surface}
          max_lines={1}
        />
        <Spacer size={16} />
        <Row fill_width={true} align="center">
          {t.lengths
           |> Enum.map(&Kati.Screens.WhatFits.length_button(&1, live?))
           |> Enum.intersperse(Kati.Screens.WhatFits.gap())}
        </Row>
        {Kati.Screens.WhatFits.mood_row(t.moods)}
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def gap, do: ~MOB"<Spacer size={6} />"

  @doc """
  The mood chips, or nothing at all.

  Nothing at all over a real list, and the reason is the one thing on this
  screen the schema still cannot say: `Kati.Media.CachedTitle.genres` is a
  genre, which is a different claim about a title, and `Kati.Media.Watch.tags`
  is per-watch and written after the fact. A chip that cannot narrow anything
  is dropped rather than drawn dead — screen 35's rule, one row smaller — and
  the whole row goes with it rather than leaving a gap where four chips were.

  The board keeps all four: it is a drawing of an evening this app cannot yet
  ask about.
  """
  @spec mood_row([map()]) :: map()
  def mood_row([]), do: ~MOB"<Spacer size={0} />"

  def mood_row(moods) do
    assigns = %{
      chips:
        moods
        |> Enum.map(&Kati.Screens.WhatFits.mood_chip/1)
        |> Enum.intersperse(Kati.Screens.WhatFits.gap())
    }

    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={10} />
      <Row fill_width={true} align="center">
        {@chips}
      </Row>
    </Column>
    """
  end

  # Both states keep their tap, the chosen one included: pressing the window you
  # are already in is how somebody checks which one that is, and a button that
  # goes dead once chosen stops answering exactly when it is pressed to be sure.
  # The rule screen 35's status tiles and screen 34's order tiles both keep.
  #
  # The TAG comes off the row's `:key` and the label off its `:label` — see
  # `window_word/1` for why those are two fields. `Map.get/3` rather than
  # `l.key`, because `Kati.Screens.WhatFits.Sample`'s rows carry only the pair
  # they always did and screen 96 draws them through `window/1` with `live?`
  # false, where no tag is built at all.
  @doc false
  def length_button(l, live? \\ false) do
    bg = if l.selected, do: Palette.ink_fill(), else: Palette.cream_raise()
    fg = if l.selected, do: Palette.on_ink(), else: Palette.cream_sub()

    assigns = %{
      tap: if(live?, do: {self(), String.to_atom("window_" <> Map.get(l, :key, l.label))})
    }

    ~MOB"""
    <Box weight={1.0} on_tap={@tap}>
      <Box fill_width={true} height={36} corner_radius={12} background={bg} align="center">
        <Text text={l.label} text_size={12.5} font_weight="semibold" text_color={fg} max_lines={1} />
      </Box>
    </Box>
    """
  end

  @doc """
  One mood chip — Mishka's Chip.

  A mood is picked, not pressed, so this is a chip and not a button: `checked`
  is the state and the four colours below are the two states' fills and inks.
  It could only become one now that the component takes the *unchecked* pair as
  props — a chip whose unselected state was a theme token could not draw
  `rgba(255,255,255,.6)` on cream, which is this screen's whole idea of a well.

  The chosen mood is `rgba(232,130,60,.18)` with a bronze label rather than
  solid ink: a mood is a preference, not a commitment, so the design gives it a
  tint where it gives the runtime a fill.

  Nothing moves. `padding_x: 11, padding_y: 0` is the Row's own 11/0, and the
  bridge pads before it sizes, so `height: 28` stays 28. The chip is a hugging
  `Box` around a hugging `Row` where this was one `Row`, which places a single
  centred Text at the identical offset.
  """
  @spec mood_chip(map()) :: map()
  def mood_chip(m) do
    MishkaChip.chip(
      label: m.label,
      checked: m.selected,
      color: Palette.accent_wash(),
      text_color: Palette.gold_text(),
      unchecked_color: Palette.cream_raise(),
      unchecked_text_color: Palette.cream_sub(),
      height: 28,
      corner_radius: 14,
      padding_x: 11,
      padding_y: 0,
      text_size: 11.5,
      font_weight: :semibold,
      max_lines: 1
    )
  end

  @doc false
  def fits(t) do
    ~MOB"""
    <Column fill_width={true}>
      {t.fits |> Enum.with_index() |> Enum.map(fn {row, i} -> Kati.Screens.WhatFits.fit_row(row, i) end)}
      <Spacer size={13} />
    </Column>
    """
  end

  @doc """
  Board 96's third band: the count is by TIME, and nothing filters it yet.

  The board's caption is the sharpest of its four —
  *it can still size your evening, it just cannot fill it yet* — and the band
  it draws is `11 episodes fit — 0 you can watch`. That is not an empty list:
  the window works, the shelf answers, and what is missing is any idea of which
  of them the reader can actually reach. Screen 92's third rule names this page
  among the three it empties and this page reads nothing at all, so the count
  above is unfiltered and says so rather than implying a shortlist.

  Above the list rather than instead of it, which is the whole of 96's argument
  — *each band is a single replaced section of a screen that already exists* —
  and the rows underneath are still worth having: they are what fits.

  Nothing at all once a service is set up. `set_up?/0` could not answer `false`
  until #75 took the fixture fallback off `Kati.Screens.MyServices.listed/0`.
  """
  @spec unfiltered(map()) :: map()
  def unfiltered(t) do
    if Kati.Screens.NothingSetUpKnockOn.set_up?() do
      ~MOB"<Spacer size={0} />"
    else
      Kati.Screens.NothingSetUpKnockOn.prompt(
        Kati.Screens.WhatFits.unfiltered_title(t),
        gettext(
          "Kati can size the gap but not fill it. Set up your services and this becomes a shortlist instead of a count."
        ),
        :my_services_what_fits
      )
    end
  end

  @doc """
  The band's own heading: how many fit, and how many of those you can reach.

  Board 96's msgid rather than `fits_label/1` glued to a second half.
  `t.fits_label <> " — 0 you can watch"` built one sentence out of two pieces,
  which under `:fa` came out as a translated count followed by an English tail
  and a Latin zero — and no translator can move a hole that is not in the
  msgid. Screen 96 draws this very band with this very sentence, so it is one
  entry and the two pages cannot come to word it differently.

  The empty window keeps `fits_label/1`'s own sentence instead. `0 episodes fit
  — 0 you can watch` is the plausible-looking zero screen 96's rule is about;
  *Nothing fits that window* is the honest form of the same fact.
  """
  @spec unfiltered_title(map()) :: String.t()
  def unfiltered_title(%{fits: []} = t), do: t.fits_label

  def unfiltered_title(t) do
    gettext("%{fit} fit tonight — %{watchable} you can watch",
      fit: Kati.Locale.number(length(t.fits)),
      watchable: Kati.Locale.number(0)
    )
  end

  @doc false
  # Both mono slots ask the STRING rather than the reader which face to take:
  # `ف۳ · ق۲` and `۴۱ دقیقه` have no glyph in `kati_mono.ttf` and would be
  # handed to Android's own substitute face, while a row off
  # `Kati.Screens.WhatFits.Sample` is still pure ASCII and keeps DM Mono.
  def fit_row(row, index \\ nil) do
    assigns = %{tap: Kati.Screens.WhatFits.row_tap(row, index)}

    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        on_tap={@tap}
        background={Palette.card()}
        corner_radius={18}
        shadow={Kati.Theme.shadow_card_soft()}
        padding_left={13}
        padding_right={13}
        padding_top={10}
        padding_bottom={10}
        align="center"
      >
        {Kati.Screens.WhatFits.thumb(row.seed)}
        <Spacer size={12} />
        <Column weight={1.0}>
          <Text
            text={row.title}
            text_size={13.5}
            font_weight="bold"
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={4} />
          <Text
            text={row.meta}
            font_family={Kati.Locale.mono_face(row.meta)}
            text_size={10.5}
            text_color={Palette.muted()}
            max_lines={1}
          />
        </Column>
        <Spacer size={12} />
        <Text
          text={row.run}
          font_family={Kati.Locale.mono_face(row.run)}
          text_size={12}
          font_weight="medium"
          text_color={:on_surface}
          max_lines={1}
        />
      </Row>
      <Spacer size={9} />
    </Column>
    """
  end

  @doc """
  The over-budget row, or nothing when everything the reader has fits.

  `Nothing else fits — nearest film is 1h 46m` is a sentence about a
  particular film, so with no film over the window there is no sentence and no
  row. The board always has one, which is what the board is a drawing of.
  """
  @spec over(map()) :: map()
  def over(%{over: nil}), do: ~MOB"<Spacer size={0} />"

  def over(t) do
    row = t.over
    assigns = %{tap: Kati.Screens.WhatFits.row_tap(row, :over)}

    ~MOB"""
    <Row
      fill_width={true}
      on_tap={@tap}
      background={Palette.card_settled()}
      corner_radius={18}
      padding_left={13}
      padding_right={13}
      padding_top={10}
      padding_bottom={10}
      align="center"
    >
      {Kati.Screens.WhatFits.thumb(row.seed)}
      <Spacer size={12} />
      <Column weight={1.0}>
        <Text
          text={row.title}
          text_size={13.5}
          font_weight="semibold"
          text_color={Palette.ink_soft()}
          max_lines={1}
        />
        <Spacer size={4} />
        <Text
          text={row.meta}
          font_family={Kati.Locale.mono_face(row.meta)}
          text_size={10.5}
          text_color={Palette.tertiary()}
          max_lines={1}
        />
      </Column>
      <Spacer size={12} />
      {Kati.Screens.WhatFits.defer_pill(row.action)}
    </Row>
    """
  end

  @doc """
  A row's tap: the show or the film it names, or `nil` on the board.

  The tag carries the row's POSITION and not the id it opens, and it has to:
  three unwatched episodes of one series is the ordinary case on this screen,
  and three nodes carrying `open_<tracked_id>` would be three siblings with the
  same `accessibility_id`. `onNodeWithTag` throws on the second match, so a
  device test could address none of them — the same reason
  `Kati.Screens.Season`'s episode rows carry an index.

      iex> Kati.Screens.WhatFits.row_tap(%{title: "Ashfall"}, 0)
      nil
  """
  @spec row_tap(map(), non_neg_integer() | :over | nil) :: {pid(), atom()} | nil
  def row_tap(%{tracked_id: id}, index) when is_binary(id) and not is_nil(index),
    do: {self(), String.to_atom("open_#{index}")}

  def row_tap(_drawn, _index), do: nil

  @doc false
  @spec row_at(map(), String.t()) :: map() | nil
  def row_at(tonight, "over"), do: Map.get(tonight, :over)

  def row_at(tonight, index) do
    case Integer.parse(index) do
      {i, ""} -> Enum.at(Map.get(tonight, :fits, []), i)
      _other -> nil
    end
  end

  @doc """
  The `Tomorrow` affordance on the over-budget row — Mishka's Pill.

  A pill, not a chip: it carries no selected state, it is the row's one offer.
  It reads as a label on a tinted lozenge, which is what a pill is.

  The pixels are the Row's. `padding: 0` with `padding_left`/`padding_right`
  at 12 gives the bridge exactly the 12/0 edges it had, and since padding is
  applied before height, `height: 30` measures 30 as it did. The pill is a
  hugging `Box` (its root passes `fill_width={false}`) wrapping a `Row` that
  holds the label and an empty `Row` where the ✕ would go; both hug, the empty
  one is zero-wide, and `align: :center` puts the pair where the Row's own
  `align="center"` put the Text. `max_lines: 1` is the pill's own default and
  is what this Text already carried.
  """
  @spec defer_pill(String.t() | nil) :: map()
  # `nil` over a real row, and it is the same rule as the mood chips one card
  # up: nothing records that a film was deferred to tomorrow — no column, no
  # resource, and `Kati.Calendars.Event` would be inventing an appointment
  # nobody made. So the offer is the board's and is not made over a real film.
  def defer_pill(nil), do: ~MOB"<Spacer size={0} />"

  def defer_pill(label) do
    MishkaPill.pill(
      label: label,
      background: Palette.placeholder(),
      color: Palette.ink_soft(),
      corner_radius: 15,
      height: 30,
      padding: 0,
      padding_left: 12,
      padding_right: 12,
      align: :center,
      text_size: 11.5,
      font_weight: :semibold
    )
  end

  @doc false
  def over_eyebrow(nil), do: ~MOB"<Spacer size={0} />"
  def over_eyebrow(label), do: Kati.UI.Eyebrow.quiet(label)

  @doc false
  # `Kati.Design.Images.poster/1` and not the fixture's own wrapper: it answers
  # for a design seed AND for a provider path — `Kati.Media.Artwork.remote?/1`
  # is what tells them apart — and routing a real `poster_path` through the
  # Sample module would be a lie about where the value came from. Screens 03,
  # 05 and 08 made the same move for the same reason.
  def thumb(seed) do
    case Kati.Design.Images.poster(seed) do
      nil ->
        ~MOB"<Box width={40} height={56} corner_radius={8} background={Palette.placeholder()} />"

      src ->
        ~MOB"""
        <Image src={src} width={40} height={56} corner_radius={8} content_mode="fill" />
        """
    end
  end
end
