defmodule Kati.Screens.YearShare do
  @moduledoc """
  Screen 98 — Your year, shared, pushed under Your year.

  The share disc on screen 07 finally does something. It has been drawn and
  inert since screen 07 landed, and `Kati.Screens.Stats.share_disc/0`'s own
  comment says why that was the honest state: *a disc that swallowed a tap
  silently would be worse than one that plainly does nothing.* This is what it
  was waiting for.

  ## Nothing about your year is uploaded to make a card

  The `info` row says it and the parenthetical is the proof rather than the
  reassurance: **Kati has no server that could receive it.** Every card is
  composed on the device, which is not a policy the app is keeping — it is the
  only thing the architecture permits.

  ## Only the field card carries the wordmark

  The design's caption: *it is the one people ask about, so it is the one that
  answers.* A wordmark on four cards is branding; a wordmark on the one card
  that provokes the question is an answer.

  ## `Share…` had a badge naming a fence that had already landed

  It read `WHEN FILE SHARING LANDS`, in the idiom screen 119 uses for its two
  unbuilt nutrition paths, and the control under it drew no `on_tap` — which is
  the right way to draw a control with nowhere to go, over a claim that had
  stopped being true. `K-20 file-transport` is `ACTION_SEND` behind a
  FileProvider URI, `Kati.Native.Files.share/2` has reached it since
  `Kati.Backup` needed a way off the phone, and `K-45 capture-screen` supplies
  the bytes. `Kati.Screens.YearCardsStates` had already written the sentence
  down: *"`Kati.Screens.YearShare`'s line about there being no way to hand a
  file out has been overtaken by that fence."*

  What was missing was the join, and it is the join **Save image** already is:
  capture, then hand over. `Kati.Native.Files.share_screen/1` is that, and
  until it was written `share/2` had no caller in `lib/` at all. The badge is
  not reworded, it is **not drawn** — a marker naming no fence is a marker the
  next reader believes.
  """

  use Kati.Screens.Pushed, back: "Stats"
  use Gettext, backend: Kati.Gettext

  alias Kati.Stats.ShareSample
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  @aspects [{:square, :aspect_square}, {:story, :aspect_story}]

  def load(socket) do
    socket
    |> Mob.Socket.assign(:scope, :all)
    |> Mob.Socket.assign(:aspect, :aspect_square)
    |> Mob.Socket.assign(:hide_private, false)
    |> Mob.Socket.assign(:save_error, nil)
    |> Mob.Socket.assign(:share, share())
  end

  # Both controls re-read the card, which is the whole of #103: they moved an
  # assign nothing looked at, so the chip relit and the card did not move.
  @doc false
  def restated(socket) do
    Mob.Socket.assign(
      socket,
      :share,
      Kati.Screens.YearShare.share(socket.assigns.scope, socket.assigns.hide_private)
    )
  end

  @doc """
  The card this page shares: the reader's year, or the drawing's.

  Every figure on it was `Kati.Stats.ShareSample`'s — `312h 40m`, `↑ 18%`, The
  Long Hollow, Blue Hour, The Cartographer, `JAN – AUG 2026` — on a device
  where screen 07 one tap earlier draws the reader's own year.
  A share card is the one page in the app whose whole
  purpose is to leave the device, so a fixture on it is a fixture somebody
  posts.

  Read through `Kati.Screens.Stats.figures/0` rather than a second query, so
  the two pages cannot disagree about the same year — which is the defect one
  layer down.
  """
  @spec share() :: map()
  def share(scope \\ :all, hide_private \\ false) do
    figures = Kati.Screens.Stats.figures()

    case figures[:year] do
      nil ->
        empty_share()

      year ->
        %{
          subtitle: figures[:range],
          hours: hours_face(year),
          top: top_titles(scope, hide_private),
          # Board 102 — *Your year, shared, dark* — drew
          # two card faces this one never previewed: the contribution field and
          # the genre bars. It is not a colourway: `Kati.Theme.Palette.mode/0`
          # reads the theme at render time, so 98 already draws dark on a dark
          # device, and what 102 actually held was two faces unreachable in
          # light. They are here now, and 102 is deleted.
          #
          # The reader's own, where 102's were `Kati.Stats.Sample`'s: screen 07
          # counts both — the grid is 26 weeks of the reader's watches and the
          # bars are their own genres (#45) — so a card saved from this page
          # carries their year rather than somebody else's.
          grid: figures[:grid],
          breakdown: Map.get(year, :breakdown, [])
        }
    end
  rescue
    # A read that raised is not a year worth sharing either. This answered
    # `drawn_share/0`, so a database Kati could not read became a card with
    # somebody else's hours on it — and this is the one page whose whole
    # purpose is to leave the device.
    _error -> empty_share()
  end

  @doc """
  `↑ 18%` beside the hours, or nothing at all — pointing the way the year went.

  `hours_face/1` has always answered `change: nil` for a first year — the
  comment beside it says so, and cites #47: *a first year has no last year, and
  `↑ 0%` is a claim*. The card drew it anyway, so a device with one year of
  history put a green up-arrow beside the four letters `nil`. Found on the
  Pixel_9a, which is the second time this round a `nil` has reached a `Text`
  and been rendered as its own name.

  The ARROW goes with it. It is not decoration around the number, it is the
  direction — an up-arrow beside nothing is a claim about a rise that has not
  been measured.

  And it points the way the year actually went. `hours_face/1` has computed
  `:direction` since the card stopped being a fixture (#79) and this function
  took `:change` alone, so the glyph was a literal `arrow_drop_up` in
  `Kati.Theme.Palette.green_text/0` whatever the figure beside it meant: screen
  07 drew a fallen year red and pointing down, and one tap later this card said
  the same `22%` in green pointing up. **That is the copy that leaves the
  phone** — `:save_image` captures this tree.

  Neither page prints a sign. `Kati.Screens.Stats`'s year takes `abs/1`, so the
  arrow is not a flourish on the figure; it is the only place the direction is
  written down, which is why dropping it inverted the claim in silence.

  `Kati.Screens.Stats.arrow/2` makes the choice for both pages, at this card's
  size. The glyph and the colour are one decision, and a second copy of it is
  how the two pages came to disagree about one year.
  """
  @spec change_pill(map()) :: map()
  def change_pill(%{change: nil}), do: ~MOB"<Spacer size={0} />"

  def change_pill(face) do
    falling? = Map.get(face, :direction) == :down

    assigns = %{
      change: face.change,
      arrow: Kati.Screens.Stats.arrow(%{rising?: not falling?}, size: 20, fill: false),
      ink: if(falling?, do: Palette.red(), else: Palette.green_text())
    }

    ~MOB"""
    <Row align="center">
      <Spacer size={10} />
      {@arrow}
      <Text text={@change} font_family={Kati.Locale.mono_face()} text_size={13} text_color={@ink} />
    </Row>
    """
  end

  @doc """
  A year with nothing counted, in the shape the card draws.

  What a reader who has watched nothing this year gets, in place of
  `drawn_share/0`'s. It matters more here than on most screens: a share card is
  built to be saved and sent, so an invented one does not merely mislead the
  person holding the phone — it travels.

  `hours: nil`, and the card draws screen 07's own empty sentence in its place
  (`nothing_counted/0`): `0` under *Time watched* is a measurement of a year
  that has not started being recorded. The subtitle is the year so far, the
  same range screen 07 heads its page with.
  """
  @spec empty_share() :: map()
  def empty_share,
    do: %{
      subtitle: Kati.Screens.Stats.range(Kati.Time.today()),
      hours: nil,
      top: [],
      grid: [],
      breakdown: []
    }

  @doc "The drawing's card, whole — the state board 98 was captured in."
  @spec drawn_share() :: map()
  def drawn_share,
    do: %{
      subtitle: ShareSample.subtitle(),
      hours: ShareSample.hours(),
      top: ShareSample.top_titles(),
      grid: Kati.Stats.Sample.contributions(),
      # Screen 07's own drawn bars, in `Kati.Screens.Stats.bar/1`'s shape —
      # board 102 held `{genre, hours}` pairs and its own arithmetic, which is
      # the second table the two boards would have drifted through.
      breakdown: Kati.Stats.Sample.year().breakdown
    }

  # Screen 07's own headline, change pill and year, in the shape this card
  # draws them. `change: nil` where 07 draws no pill — a first year has no last
  # year, and `↑ 0%` is a claim about a year that does not exist.
  #
  # The label is screen 07's own msgid rather than a second one. `Time watched`
  # is already in the catalogue twice — `Kati.Screens.Stats.hero/2` draws it and
  # `Kati.Stats.ShareSample.hours/0` carries it for the drawn card — and the two
  # branches of `share/2` have to name one figure one way: a device with history
  # reading زمان تماشا and a device without it reading something else would be
  # two cards claiming to be the same card.
  #
  # `year/0` rather than a second `Kati.Time.today().year`. This row's year and
  # the watermark on the two faces below it are the same year, and under `:fa`
  # they have to be the same CALENDAR: the subtitle two rows above already reads
  # فروردین تا مرداد ۱۴۰۵ — `Kati.Screens.Stats.range/1` converts it — so a
  # Gregorian `2026` here is a card disagreeing with its own heading.
  # `Kati.Screens.YearShareBooks.pages_face/0` met the same thing from the
  # other side and its comment is the long version.
  defp hours_face(year) do
    %{
      label: gettext("Time watched"),
      figure: year.time,
      direction: if(year.rising?, do: :up, else: :down),
      change: year.change,
      year: Kati.Screens.YearShare.year()
    }
  end

  @doc """
  The three titles this reader watched most of, by ticks and logs.

  `Kati.Media.Watch` grouped by `tracked_title_id`, which counts an episode
  tick and a film's watch as one each — the same unit screen 07's *Recently
  watched* is a list of. A title whose cache row has been evicted is dropped
  rather than drawn `Untitled` on a card that is about to be posted.
  """
  @spec top_titles() :: [map()]
  def top_titles(scope \\ :all, hide_private \\ false) do
    watches = Ash.read!(Kati.Media.Watch)
    tracked = Map.new(Ash.read!(Kati.Media.TrackedTitle), &{&1.id, &1})
    cached = Map.new(Ash.read!(Kati.Media.CachedTitle), &{{&1.source, &1.source_id}, &1})

    watches
    |> Enum.frequencies_by(& &1.tracked_title_id)
    |> Enum.sort_by(fn {id, n} -> {-n, id} end)
    |> Enum.map(fn {id, n} -> {Map.get(tracked, id), n} end)
    |> Enum.filter(&Kati.Screens.YearShare.shareable?(&1, scope, hide_private))
    |> Enum.take(3)
    |> Enum.with_index(1)
    |> Enum.flat_map(fn {{row, _n}, rank} -> title_row(rank, row, cached) end)
  rescue
    _error -> []
  end

  @doc """
  Whether a title belongs on the card as this reader has set it up.

  Two questions, and they were both being asked of nothing:
  the scope chips and the privacy switch moved assigns that nothing
  read, so both relit over an unchanged card.

    * **The scope.** `Screen` is films and series; the other chips name
      sections whose watches are not in `Kati.Media.Watch` at all, so they
      narrow to nothing and the card says so rather than showing the same
      three titles under a different word.
    * **Private.** `Kati.Media.TrackedTitle.private`, set from the title's own
      ⋯ menu. It hides a title from the CARD and from nothing else — the
      shelf, Up next and the year's numbers are unchanged, because a private
      title is still a title you watched.

      iex> Kati.Screens.YearShare.shareable?({%{kind: :movie, private: false}, 3}, :all, false)
      true

      iex> Kati.Screens.YearShare.shareable?({%{kind: :movie, private: true}, 3}, :all, true)
      false

      iex> Kati.Screens.YearShare.shareable?({%{kind: :movie, private: false}, 3}, :books, false)
      false

      iex> Kati.Screens.YearShare.shareable?({nil, 3}, :all, false)
      false
  """
  # `atom()` first, because that is what a chip's tap resolves to — `pick_scope/2`
  # matches the tapped key against `Kati.Stats.ShareSample.scopes/0` and assigns
  # the ATOM, and all four doctests below pass one. The spec said `String.t()`
  # alone, which contradicted every one of them; the string half is kept because
  # `in_scope?/2`'s last clause deliberately answers `false` for a scope it does
  # not know, whatever shape it arrives in, and that tolerance is asserted.
  @spec shareable?({map() | nil, integer()}, atom() | String.t(), boolean()) :: boolean()
  def shareable?({nil, _n}, _scope, _hide_private), do: false

  def shareable?({tracked, _n}, scope, hide_private) do
    not (hide_private and Map.get(tracked, :private, false)) and
      in_scope?(Map.get(tracked, :kind), scope)
  end

  defp in_scope?(_kind, :all), do: true
  defp in_scope?(kind, :screen), do: kind in [:movie, :tv, :anime]
  defp in_scope?(:book, :books), do: true
  defp in_scope?(:album, :music), do: true
  defp in_scope?(_kind, _scope), do: false

  defp title_row(_rank, nil, _cached), do: []

  # `Integer.to_string/1` and deliberately not `Kati.Locale.number/1`: the rank
  # in this map is the position, and it is converted to the reader's digits at
  # the one node that draws it — `rank_row/1`, which also draws
  # `Kati.Stats.ShareSample.top_titles/0`'s ASCII `1 2 3`. Converting here as
  # well would be the same decision in two places, and the second copy is the
  # one that goes stale.
  defp title_row(rank, tracked, cached) do
    case Map.get(cached, {tracked.source, tracked.source_id}) do
      %{title: title, poster_path: seed} when is_binary(title) ->
        [%{rank: Integer.to_string(rank), title: title, seed: seed}]

      _evicted ->
        []
    end
  end

  @doc false
  def content(assigns) do
    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {SettingsList.chrome(nil, 44)}
        {SettingsList.title(gettext("Your year, shared"), Kati.Screens.YearShare.shown(assigns).subtitle)}
        {Kati.Screens.YearShare.scopes(assigns.scope)}
        {Kati.Screens.YearShare.card(assigns.aspect, Kati.Screens.YearShare.shown(assigns))}
        {UI.eyebrow(gettext("Aspect"))}
        {Kati.UI.Segmented.plain(Kati.Screens.YearShare.aspects(), assigns.aspect)}
        <Spacer size={16} />
        {Kati.Screens.YearShare.privacy_row(assigns.hide_private)}
        <Spacer size={16} />
        {Kati.Screens.YearShare.actions()}
        {Kati.Screens.YearShare.refusal(Map.get(assigns, :save_error))}
        <Spacer size={16} />
        {Kati.Screens.YearShare.no_server_note()}
      </Column>
    </Scroll>
    """
  end

  @doc """
  The card this render draws: the one `load/1` read, or an empty year.

  Never the drawing's. `drawn_share/0` is what the design test installs as
  `:share`; a render that found no `:share` falls back to `empty_share/0`.
  """
  @spec shown(map()) :: map()
  def shown(assigns), do: assigns[:share] || Kati.Screens.YearShare.empty_share()

  @doc "Take a scope chip's tap, if it names one of the six."
  @spec pick_scope(Mob.Socket.t(), String.t()) :: Mob.Socket.t()
  def pick_scope(socket, key) do
    case Enum.find(Kati.Stats.ShareSample.scopes(), fn {k, _l} -> Atom.to_string(k) == key end) do
      {scope, _label} ->
        socket |> Mob.Socket.assign(:scope, scope) |> Kati.Screens.YearShare.restated()

      nil ->
        socket
    end
  end

  @doc """
  The two card shapes, as the segmented control takes them.

      iex> Kati.Screens.YearShare.aspects() |> Enum.map(&elem(&1, 0))
      ["Square", "Story"]

  The tag is the KEY and the word is drawn; `Kati.UI.Segmented.plain/2` takes
  `{label, tag}`, so the translation happens here rather than in the attribute.
  """
  @spec aspects() :: [{String.t(), atom()}]
  def aspects do
    Enum.map(@aspects, fn {key, tag} -> {Kati.Screens.YearShare.aspect_label(key), tag} end)
  end

  @doc false
  @spec aspect_label(atom()) :: String.t()
  def aspect_label(:story), do: gettext("Story")
  def aspect_label(_square), do: gettext("Square")

  @doc "The scope chips: which part of the year the card is about."
  @spec scopes(atom()) :: map()
  def scopes(active) do
    chips =
      ShareSample.scopes()
      |> Enum.map(fn {key, label} ->
        UI.chip(label,
          selected: key == active,
          on_toggle: String.to_atom("scope_" <> Atom.to_string(key))
        )
      end)
      |> Enum.intersperse(~MOB"<Spacer size={7} />")

    ~MOB"""
    <Column fill_width={true}>
      <Scroll axis="horizontal">
        <Row>
          {chips}
        </Row>
      </Scroll>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc """
  The card preview, at one of the two ratios — screen 100's `scale`, on this
  page: the hours face and the titles face, as they will be saved, or screen
  07's empty sentence when nothing has been counted.

  The Aspect segments used to set `:aspect` and nothing read it, so the preview
  the caption calls *as they will be saved* was one ratio whichever segment was
  lit. `scale/1` reads `Kati.Screens.YearCards`'s own two numbers — 1.0 and
  1.25 — rather than starting a second table: a Story preview that re-scaled by
  a different number from the file Story is cut at would be a preview of
  something else.

  `sized/2` returns the size UNCHANGED at 1.0 rather than multiplying by it.
  `10 * 1.0` is `10.0` where the drawing's tree carries `10`, and the square
  ratio is what every capture, every sweep and the gallery render.

  ## Three of these measurements are a script's rather than the design's

  `Kati.Screens.YearShareBooks.card/0` named this frame as the one that still
  wrote all three by hand — *"a disagreement between the two frames of the kind
  this module's own doc says is a bug, and it is one this side cannot fix from
  here"*. This side is here.

    * **The case.** The board sets the face label in sentence case and
      upper-cases it in CSS; `String.upcase/1` was this tree's half of that.
      The Arabic script has no case, so upcasing **زمان تماشا** returns it
      unchanged — a transform that reads in the source as though the label were
      being styled and does nothing at all. `Kati.UI.eyebrow_label/1` is the
      same upcasing in Latin and an honest no-op in Persian.
    * **The tracking.** `.14em` is a Latin small-caps effect and the negative
      display tracking is a Latin display effect; both pull Persian letters
      apart at their joins, and a word whose letters do not join is not one
      word. `Kati.Locale.tracking/1` answers the design's own number in Latin —
      `tracking(0.14)` IS `0.14` here, so the English card measures exactly as
      it was captured — and `0` in Persian.
    * **`max_lines={1}` on the figure.** `312h 40m` is ۳۱۲ ساعت ۴۰ دقیقه in
      Persian, which is four words where the drawing has two, at 34pt inside a
      252pt card. Nothing on a card may reflow — the proportion IS the spec,
      and this tree is what `:save_image` captures — so it has to ellipsize
      rather than grow the frame it is measured in. The wordmark is the one
      `letter_spacing` left hard-coded, for `Kati.Screens.YearCards`'s reason:
      it is Latin in both scripts, so zeroing its tracking would loosen a word
      that never needed it.
  """
  @spec card(atom(), map()) :: map()
  def card(_aspect, %{hours: nil}), do: Kati.Screens.YearShare.nothing_counted()

  def card(aspect, share) do
    scale = scale(aspect)

    assigns = %{
      hours: share.hours,
      top: share.top,
      grid: Map.get(share, :grid, []),
      breakdown: Map.get(share, :breakdown, []),
      label_size: sized(10, scale),
      figure_size: sized(34, scale),
      titles_size: sized(10, scale)
    }

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        padding={19}
        shadow={Kati.Theme.shadow_card()}
      >
        <Text
          text={Kati.UI.eyebrow_label(@hours.label)}
          font_family={Kati.Locale.mono_face()}
          text_size={@label_size}
          letter_spacing={Kati.Locale.tracking(0.14)}
          text_color={Palette.muted()}
        />
        <Spacer size={9} />
        <Row fill_width={true} align="bottom">
          <Text
            text={@hours.figure}
            text_size={@figure_size}
            font_weight="extrabold"
            letter_spacing={Kati.Locale.tracking(-0.035)}
            text_color={:on_surface}
            max_lines={1}
          />
          {Kati.Screens.YearShare.change_pill(@hours)}
          <Spacer weight={1.0} />
          <Text
            text={@hours.year}
            font_family={Kati.Locale.mono_face()}
            text_size={12}
            text_color={Palette.muted()}
          />
        </Row>
        {Kati.Screens.YearShare.top_face(@top, @titles_size)}
        {Kati.Screens.YearShare.field_face(@grid, @label_size)}
        {Kati.Screens.YearShare.hours_face_bars(@breakdown, @label_size)}
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  The card when this reader has watched nothing this year: screen 07's own
  empty headline and sentence, on the card's own ground.
  """
  @spec nothing_counted() :: map()
  def nothing_counted do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        padding={19}
        shadow={Kati.Theme.shadow_card()}
      >
        <Text
          text={gettext("Not much to show yet")}
          text_size={17}
          font_weight="bold"
          letter_spacing={Kati.Locale.tracking(-0.02)}
          text_color={:on_surface}
        />
        <Spacer size={9} />
        <Text
          text={gettext("Your year is counted from what you tick off. Mark one thing watched and this page starts filling itself.")}
          text_size={13}
          line_height={1.6}
          text_color={Palette.sub()}
        />
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  *Top titles*: its label, the posters and the ranked names — or nothing when
  the scope holds no title, because a label over an empty row is a heading for
  nothing.
  """
  @spec top_face([map()], number()) :: map()
  def top_face([], _titles_size), do: ~MOB"<Spacer size={0} />"

  def top_face(top, titles_size) do
    assigns = %{top: top, titles_size: titles_size}

    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={20} />
      <Text
        text={gettext("Top titles")}
        font_family={Kati.Locale.mono_face()}
        text_size={@titles_size}
        letter_spacing={Kati.Locale.tracking(0.14)}
        text_color={Palette.muted()}
      />
      <Spacer size={11} />
      {Kati.Screens.YearShare.posters(@top)}
      <Spacer size={13} />
      {Kati.Screens.YearShare.ranks(@top)}
    </Column>
    """
  end

  @doc """
  Board 102's contribution field, on this card and in this reader's own year.

  Dropped entirely when there is nothing to draw: a field
  of empty cells under a heading is a texture of a year nobody had.

  Row-major, which is not how a contribution grid is usually filled — and
  102's own doc gives the reason it stays: `Kati.UI.pixel_field/2` and
  `Kati.Screens.Stats` both fill this data row-major already, and on a card
  meant to be saved the field is a texture of a year rather than a calendar
  anybody points a Tuesday at.
  """
  @spec field_face([0..4], number()) :: map()
  def field_face([], _label_size), do: ~MOB"<Spacer size={0} />"

  def field_face(grid, label_size) do
    assigns = %{
      label_size: label_size,
      # Board 100's own two words for this face, and board 102's before it —
      # `Your year` over `26 WEEKS`. The first version of this invented
      # `Every day`, which is copy neither board contains.
      weeks: gettext("%{count} WEEKS", count: Kati.Locale.number(Kati.Screens.Stats.weeks())),
      year: Kati.Screens.YearShare.year(),
      rows:
        grid
        |> Enum.chunk_every(26)
        |> Enum.map(&Kati.Screens.YearShare.field_row/1)
        |> Enum.intersperse(Kati.Screens.Stats.cell_gap())
    }

    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={20} />
      <Text
        text={gettext("Your year")}
        font_family={Kati.Locale.mono_face()}
        text_size={@label_size}
        letter_spacing={Kati.Locale.tracking(0.14)}
        text_color={Palette.muted()}
      />
      <Spacer size={11} />
      <Column fill_width={true}>
        {@rows}
      </Column>
      <Spacer size={11} />
      <Row fill_width={true} align="center">
        <Text
          text={@weeks}
          font_family={Kati.Locale.mono_face()}
          text_size={@label_size}
          letter_spacing={Kati.Locale.tracking(0.14)}
          text_color={Palette.muted()}
        />
        <Spacer weight={1.0} />
        <Text
          text={@year}
          font_family={Kati.Locale.mono_face()}
          text_size={@label_size}
          text_color={Palette.muted()}
        />
        <Spacer size={9} />
        {Kati.Screens.YearShare.wordmark()}
      </Row>
    </Column>
    """
  end

  @doc """
  The year, which both faces carry and neither used to.

  Boards 325 and 326 draw it bottom-right on each — *"its placement is fixed
  here rather than inferred"*, because these are the one artefact of the app
  that leaves the app and a card with no year on it is a card nobody can date.

      iex> Kati.Screens.YearShare.year() =~ ~r/^\d{4}$/
      true

  **The reader's own calendar, not the phone's.** `Integer.to_string/1` on
  `Kati.Time.today().year` is the Gregorian number in Latin digits whatever the
  reader counts in, and this is the one figure on the card that dates the card
  — so under `:fa` it is ۱۴۰۵, beside a subtitle that already reads
  فروردین تا مرداد ۱۴۰۵. `Kati.Locale.year_of/1` is the half of the split that
  converts; `Kati.Locale.year/1` is the other half and is for a year printed on
  an object — a book's publication, a film's release — which is never
  converted. A card is neither: it is dated the day it was made, in the
  reader's own reckoning.

  `filename/0` keeps the Gregorian year and its own doc says why — a file name
  is not a line of copy, and the Kotlin half will only carry ASCII.
  """
  @spec year() :: String.t()
  def year, do: Kati.Locale.year_of(Kati.Time.today())

  @doc """
  `Kati` — and it goes on the field face and nowhere else.

  Board 100 states the rule in as many words: *only the field card carries the
  wordmark*, and board 98's own note gives the reason — *it is the one people
  ask about, so it is the one that answers*. A wordmark on every face would be
  a signature on a page nobody asked who wrote.

  Board 326 restates it from the other side, on the card that must NOT carry
  one: its own bottom row draws the year and stops. Two boards saying the same
  rule from both ends is what makes it checkable rather than remembered.

  **`Kati`, in both scripts, and no `gettext/1` around it.** Board 127 draws
  `Lumen+` in Latin on a Persian page for the same reason a name a thing calls
  itself is spelled one way — and this is the app's own name on the one
  artefact of the app that leaves it, so a card posted from a Persian phone and
  a card posted from an English one have to be signed identically. This is the
  wordmark and not the word: `Kati.Screens.WeekImage.message/1` writes کاتی in
  the middle of a Persian sentence, which is the same name doing a different
  job. It keeps its hard-coded `letter_spacing` for the same reason it keeps
  its letters — the run is Latin whatever the reader reads, and
  `Kati.Locale.tracking/1` would loosen it to `0` on a page it was drawn
  tight for.
  """
  @spec wordmark() :: map()
  def wordmark do
    ~MOB"""
    <Text
      text="Kati"
      text_size={12}
      font_weight="bold"
      letter_spacing={-0.01}
      text_color={Palette.muted()}
      max_lines={1}
    />
    """
  end

  @doc false
  def field_row(row) do
    assigns = %{
      cells:
        row
        |> Enum.map(&Kati.Screens.Stats.cell/1)
        |> Enum.intersperse(Kati.Screens.Stats.cell_gap())
    }

    ~MOB"""
    <Row>
      {@cells}
    </Row>
    """
  end

  @doc """
  Board 102's genre bars, on this card and out of this reader's own genres.

  The figures are real because screen 07's bars
  stopped being a fixture, and this reads the same list rather than starting a
  second one. Dropped when there is nothing to divide.
  """
  @spec hours_face_bars([term()], number()) :: map()
  def hours_face_bars([], _label_size), do: ~MOB"<Spacer size={0} />"

  def hours_face_bars(breakdown, label_size) do
    assigns = %{
      label_size: label_size,
      year: Kati.Screens.YearShare.year(),
      # `bar/1` and not `breakdown/1`: that one wraps the rows in their own
      # card, and here they are already inside one.
      bars: Enum.map(breakdown, &Kati.Screens.Stats.bar/1)
    }

    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={20} />
      <Text
        text={gettext("Where the hours went")}
        font_family={Kati.Locale.mono_face()}
        text_size={@label_size}
        letter_spacing={Kati.Locale.tracking(0.14)}
        text_color={Palette.muted()}
      />
      <Spacer size={11} />
      {@bars}
      <Spacer size={11} />
      <Row fill_width={true} align="center">
        <Spacer weight={1.0} />
        <Text
          text={@year}
          font_family={Kati.Locale.mono_face()}
          text_size={@label_size}
          text_color={Palette.muted()}
        />
      </Row>
    </Column>
    """
  end

  # The two ratios, and the number each multiplies the type by — the same table
  # `Kati.Screens.YearCards` cuts the files at (`@ratios`, year_cards.ex:45),
  # read here rather than copied as sizes. An aspect this page does not draw
  # takes the square, so a stale tag cannot silently re-scale the preview.
  defp scale(:aspect_story), do: 1.25
  defp scale(_square), do: 1.0

  # Identity at 1.0, deliberately. `10 * 1.0` is `10.0` and the drawing's tree
  # carries `10`; the square is the ratio every capture was taken at, so it has
  # to come out of here untouched rather than merely equal.
  defp sized(size, 1.0), do: size
  defp sized(size, scale), do: size * scale

  @doc false
  def posters(top) do
    tiles =
      top
      |> Enum.map(&Kati.Screens.YearShare.poster/1)
      |> Enum.intersperse(~MOB"<Spacer size={9} />")

    ~MOB"""
    <Row fill_width={true} align="top">
      {tiles}
    </Row>
    """
  end

  @doc false
  def poster(title) do
    case Kati.Design.Images.poster(title.seed) do
      nil ->
        ~MOB"""
        <Column weight={1.0}>
          <Box fill_width={true} height={92} corner_radius={8} background={Palette.placeholder()} />
        </Column>
        """

      src ->
        ~MOB"""
        <Column weight={1.0}>
          <Image src={src} fill_width={true} height={92} corner_radius={8} content_mode="fill" />
        </Column>
        """
    end
  end

  @doc false
  def ranks(top) do
    rows =
      top
      |> Enum.map(&Kati.Screens.YearShare.rank_row/1)
      |> Enum.intersperse(~MOB"<Spacer size={7} />")

    ~MOB"""
    <Column fill_width={true}>
      {rows}
    </Column>
    """
  end

  @doc """
  One ranked title: the position, then the name.

  The rank is converted here rather than where it is composed, because it
  arrives from two places — `title_row/3` counts the reader's own watches and
  `Kati.Stats.ShareSample.top_titles/0` carries the drawing's `1 2 3` — and
  `Kati.Screens.YearCards` draws the second of those through this same
  function, calling the typesetting of these rows *"this file's"* by name. One
  conversion at the one node that draws both is the only place that can be
  true for either.

  `Kati.Locale.number/1` and not `Integer.to_string/1`, which is the Latin
  digits whatever the reader counts in. The slot beside it is `mono_face/0` —
  Vazirmatn under `:fa`, which carries U+06F0–U+06F9 where `kati_mono.ttf`
  carries none of them — so the DM Mono exception `Kati.Locale.number/1`
  documents does not reach here: ۱ beside a Persian title, 1 beside a Latin
  one.

  The TITLE is not this file's to translate and not anybody's: it is a row out
  of `Kati.Media.CachedTitle`, which is what the provider called the thing.
  """
  @spec rank_row(map()) :: map()
  def rank_row(title) do
    assigns = %{rank: Kati.Locale.number(title.rank), title: title.title}

    ~MOB"""
    <Row fill_width={true} align="center">
      <Text
        text={@rank}
        font_family={Kati.Locale.mono_face()}
        text_size={11}
        text_color={Palette.tertiary()}
        width={16}
      />
      <Spacer size={9} />
      <Text
        text={@title}
        text_size={12.5}
        font_weight="semibold"
        text_color={:on_surface}
        max_lines={1}
      />
      <Spacer weight={1.0} />
    </Row>
    """
  end

  @doc """
  The one privacy control on the page.

  A switch rather than a chip, because it is not a scope — it changes what is
  *in* the card rather than what the card is about, and a control that looked
  like the six above it would be read as a seventh scope.
  """
  @spec privacy_row(boolean()) :: map()
  def privacy_row(on?) do
    SettingsList.card([
      SettingsList.row(
        SettingsList.icon_tile("visibility_off"),
        SettingsList.body(gettext("Hide titles I marked private"), nil),
        SettingsList.trailing(SettingsList.switch(on?)),
        on_tap: {self(), :toggle_private}
      )
    ])
  end

  @doc """
  Save, and the share that is waiting on a fence.

  `Save image` takes the ink because it is the one that works — and now it does
  work. It pushed `Kati.Screens.YearCards` and saved nothing until 6 September,
  while the note beside it said the capability was
  missing; it was not. `K-45 capture-screen` had shipped and screen 110 had
  been saving its own page with it. `Share…` still carries `WHEN FILE SHARING
  LANDS`, in the same idiom screen 119's unbuilt nutrition paths use, because
  that fence is real: a capture writes a file, and sending it somewhere needs
  an intent this bridge has no side for.
  """
  @spec actions() :: map()
  def actions do
    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        height={52}
        corner_radius={26}
        background={Palette.ink_fill()}
        align="center"
        on_tap={{self(), :save_image}}
      >
        <Spacer weight={1.0} />
        <Text
          text={gettext("Save image")}
          text_size={15}
          font_weight="bold"
          letter_spacing={Kati.Locale.tracking(-0.01)}
          text_color={Palette.on_ink()}
        />
        <Spacer weight={1.0} />
      </Row>
      <Spacer size={11} />
      <Row fill_width={true} align="center" on_tap={{self(), :share_image}}>
        <Spacer weight={1.0} />
        <Text
          text={gettext("Share…")}
          text_size={13.5}
          font_weight="semibold"
          text_color={Palette.ink_soft()}
        />
        <Spacer weight={1.0} />
      </Row>
    </Column>
    """
  end

  @doc "The sentence whose parenthetical is the proof, not the reassurance."
  @spec no_server_note() :: map()
  def no_server_note do
    SettingsList.note(
      "info",
      gettext(
        "Every card is drawn on this device. Nothing about your year is uploaded to make it — Kati has no server that could receive it."
      )
    )
  end

  @doc false
  def handle_tap(:toggle_private, socket) do
    socket = Mob.Socket.assign(socket, :hide_private, not socket.assigns.hide_private)
    {:noreply, Kati.Screens.YearShare.restated(socket)}
  end

  def handle_tap(aspect, socket) when aspect in [:aspect_square, :aspect_story],
    do: {:noreply, Mob.Socket.assign(socket, :aspect, aspect)}

  @doc """
  Save the card as a PNG, through the picker every other file in Kati uses.

  It used to push `Kati.Screens.YearCards` — the reference sheet about how a
  card is drawn — which is a page about the feature rather than the feature,
  and the button said *Save image* and saved
  none. The note beside it said the capability was missing; it was not. `K-45
  capture-screen` shipped and `Kati.Screens.WeekImage` has been saving its own
  page with it since. This is the same three lines.

  A refusal is drawn rather than swallowed, for that screen's reason: a save
  button that appears to work and silently does not is the defect screen 06's
  search taught this codebase to stop shipping.
  """
  def handle_tap(:save_image, socket) do
    case Kati.Native.Files.save_screen(Kati.Screens.YearShare.filename()) do
      :ok -> {:noreply, Mob.Socket.assign(socket, :save_error, nil)}
      {:error, why} -> {:noreply, Mob.Socket.assign(socket, :save_error, message(why))}
    end
  end

  # `Share…`'s other half, and the same shape: capture, hand over, report a
  # refusal in the band `Save image` already reports into. Both are `:ok` the
  # moment the system UI is open — the outcome arrives later as a message, and
  # neither control can wait for it.
  def handle_tap(:share_image, socket) do
    case Kati.Native.Files.share_screen(Kati.Screens.YearShare.filename()) do
      :ok -> {:noreply, Mob.Socket.assign(socket, :save_error, nil)}
      {:error, why} -> {:noreply, Mob.Socket.assign(socket, :save_error, message(why))}
    end
  end

  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "scope_" <> key ->
        {:noreply, Kati.Screens.YearShare.pick_scope(socket, key)}

      _other ->
        {:noreply, socket}
    end
  end

  @doc """
  The name the file is offered under: `kati-year-2026.png`.

  The year the card is about, so a folder with three of these in it can be
  read — `Kati.Screens.WeekImage.filename/0`'s own rule, with the range this
  page has instead of that one's week. ASCII and hyphenated, because the
  Kotlin half strips anything else out of a filename and a name that came back
  different from the one composed here would be a small lie in a folder
  listing.
  """
  @spec filename() :: String.t()
  def filename, do: "kati-year-" <> Integer.to_string(Kati.Time.today().year) <> ".png"

  @doc false
  def refusal(nil), do: ~MOB"<Spacer size={0} />"

  def refusal(message) do
    assigns = %{message: message}

    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={12} />
      {Kati.UI.notice(@message)}
    </Column>
    """
  end

  # One sentence per way this can fail, in `Kati.Write.message/1`'s register:
  # what happened, and whether anything was lost. Nothing ever is — the capture
  # writes to the cache and the picker is the only thing that writes anywhere
  # else — so every one of these ends by saying so. Screen 110's own five,
  # because the two buttons do the same thing and a reader who met both should
  # not meet two vocabularies.
  #
  # Screen 110's own five MSGIDS, then, character for character: these are
  # `Kati.Screens.WeekImage.message/1`'s exact strings, so the catalogue
  # already answers all five and the two screens cannot drift into two Persian
  # vocabularies for one refusal. A refusal is the one thing on this page that
  # is neither card and it follows the reader — a reader who cannot read the
  # sentence explaining why nothing was saved is in exactly the position
  # `handle_tap/2`'s doc says this whole branch exists to prevent.
  #
  # `کاتی` in the Persian rather than `Kati`, which is not the rule
  # `wordmark/0` keeps: the app's name is a WORD in a sentence here and a
  # wordmark in the footer of a card there, and the catalogue has written it
  # the first way since long before this screen asked.
  defp message(:no_activity), do: gettext("Kati is not on screen. Nothing was saved.")
  defp message(:nothing_drawn), do: gettext("There was nothing to capture. Nothing was saved.")
  defp message(:timeout), do: gettext("The page took too long to capture. Nothing was saved.")
  defp message(:no_bridge), do: gettext("Saving images does not work here yet.")
  defp message(_other), do: gettext("That did not save. The page is unchanged.")
end
