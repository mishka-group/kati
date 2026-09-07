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

  ## `Share…` is drawn and not built

  `WHEN FILE SHARING LANDS` sits under it, in the same idiom screen 119 uses
  for its two unbuilt nutrition paths. Kati has no share-sheet fence — nothing
  in `native/LEDGER.md` hands a file to the platform — so the control says what
  it is waiting for rather than failing quietly.
  """

  use Kati.Screens.Pushed, back: "Stats"

  alias Kati.Stats.ShareSample
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  @aspects [{"Square", :aspect_square}, {"Story", :aspect_story}]

  def load(socket) do
    socket
    |> Mob.Socket.assign(:scope, "All")
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
  MOVIES-AND-TV.md #79. A share card is the one page in the app whose whole
  purpose is to leave the device, so a fixture on it is a fixture somebody
  posts.

  Read through `Kati.Screens.Stats.figures/0` rather than a second query, so
  the two pages cannot disagree about the same year — which is the defect one
  layer down.
  """
  @spec share() :: map()
  def share(scope \\ "All", hide_private \\ false) do
    figures = Kati.Screens.Stats.figures()

    case figures[:year] do
      nil ->
        drawn_share()

      year ->
        %{
          subtitle: figures[:range],
          hours: hours_face(year),
          top: top_titles(scope, hide_private),
          # MOVIES-AND-TV.md #3. Board 102 — *Your year, shared, dark* — drew
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
    _error -> drawn_share()
  end

  @doc """
  `↑ 18%` beside the hours, or nothing at all.

  `hours_face/1` has always answered `change: nil` for a first year — the
  comment beside it says so, and cites #47: *a first year has no last year, and
  `↑ 0%` is a claim*. The card drew it anyway, so a device with one year of
  history put a green up-arrow beside the four letters `nil`. Found on the
  Pixel_9a, which is the second time this round a `nil` has reached a `Text`
  and been rendered as its own name.

  The ARROW goes with it. It is not decoration around the number, it is the
  direction — an up-arrow beside nothing is a claim about a rise that has not
  been measured.
  """
  @spec change_pill(String.t() | nil) :: map()
  def change_pill(nil), do: ~MOB"<Spacer size={0} />"

  def change_pill(change) do
    assigns = %{change: change}

    ~MOB"""
    <Row align="center">
      <Spacer size={10} />
      {Kati.UI.symbol("arrow_drop_up", size: 20, color: Palette.green_text())}
      <Text text={@change} font_family="mono" text_size={13} text_color={Palette.green_text()} />
    </Row>
    """
  end

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
  # year, and `↑ 0%` is the claim MOVIES-AND-TV.md #47 was about.
  defp hours_face(year) do
    %{
      label: "Time watched",
      figure: year.time,
      direction: if(year.rising?, do: :up, else: :down),
      change: year.change,
      year: Integer.to_string(Kati.Time.today().year)
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
  def top_titles(scope \\ "All", hide_private \\ false) do
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

  Two questions, and they were both being asked of nothing (MOVIES-AND-TV.md
  #103): the scope chips and the privacy switch moved assigns that nothing
  read, so both relit over an unchanged card.

    * **The scope.** `Screen` is films and series; the other chips name
      sections whose watches are not in `Kati.Media.Watch` at all, so they
      narrow to nothing and the card says so rather than showing the same
      three titles under a different word.
    * **Private.** `Kati.Media.TrackedTitle.private`, set from the title's own
      ⋯ menu. It hides a title from the CARD and from nothing else — the
      shelf, Up next and the year's numbers are unchanged, because a private
      title is still a title you watched.

      iex> Kati.Screens.YearShare.shareable?({%{kind: :movie, private: false}, 3}, "All", false)
      true

      iex> Kati.Screens.YearShare.shareable?({%{kind: :movie, private: true}, 3}, "All", true)
      false

      iex> Kati.Screens.YearShare.shareable?({%{kind: :movie, private: false}, 3}, "Books", false)
      false

      iex> Kati.Screens.YearShare.shareable?({nil, 3}, "All", false)
      false
  """
  @spec shareable?({map() | nil, integer()}, String.t(), boolean()) :: boolean()
  def shareable?({nil, _n}, _scope, _hide_private), do: false

  def shareable?({tracked, _n}, scope, hide_private) do
    not (hide_private and Map.get(tracked, :private, false)) and
      in_scope?(Map.get(tracked, :kind), scope)
  end

  defp in_scope?(_kind, "All"), do: true
  defp in_scope?(kind, "Screen"), do: kind in [:movie, :tv, :anime]
  defp in_scope?(:book, "Books"), do: true
  defp in_scope?(:album, "Music"), do: true
  defp in_scope?(_kind, _scope), do: false

  defp title_row(_rank, nil, _cached), do: []

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
        {SettingsList.title("Your year, shared", Map.get(assigns, :share, Kati.Screens.YearShare.drawn_share()).subtitle)}
        {Kati.Screens.YearShare.scopes(assigns.scope)}
        {Kati.Screens.YearShare.card(assigns.aspect, Map.get(assigns, :share, Kati.Screens.YearShare.drawn_share()))}
        {UI.eyebrow("Aspect")}
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

  @doc false
  def aspects, do: @aspects

  @doc "The scope chips: which part of the year the card is about."
  @spec scopes(String.t()) :: map()
  def scopes(active) do
    chips =
      ShareSample.scopes()
      |> Enum.map(fn scope ->
        UI.chip(scope, selected: scope == active, on_toggle: String.to_atom("scope_" <> scope))
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
  The card preview: the hours face and the titles face, as they will be saved.

  Drawn on paper rather than on card, because the image's own ground is paper —
  a preview that sat on a different colour from the file would be a preview of
  something else.
  """
  @spec card() :: map()
  def card, do: card(:aspect_square)

  @doc """
  The preview at one of the two ratios — screen 100's `scale`, on this page.

  The Aspect segments used to set `:aspect` and nothing read it, so the preview
  the caption calls *as they will be saved* was one ratio whichever segment was
  lit. `scale/1` reads `Kati.Screens.YearCards`'s own two numbers — 1.0 and
  1.25 — rather than starting a second table: a Story preview that re-scaled by
  a different number from the file Story is cut at would be a preview of
  something else.

  `sized/2` returns the size UNCHANGED at 1.0 rather than multiplying by it.
  `10 * 1.0` is `10.0` where the drawing's tree carries `10`, and the square
  ratio is what every capture, every sweep and the gallery render.
  """
  @spec card(atom(), map()) :: map()
  def card(aspect, share \\ nil) do
    share = share || drawn_share()
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
          text={String.upcase(@hours.label)}
          font_family="mono"
          text_size={@label_size}
          letter_spacing={0.14}
          text_color={Palette.muted()}
        />
        <Spacer size={9} />
        <Row fill_width={true} align="bottom">
          <Text
            text={@hours.figure}
            text_size={@figure_size}
            font_weight="extrabold"
            letter_spacing={-0.035}
            text_color={:on_surface}
          />
          {Kati.Screens.YearShare.change_pill(@hours.change)}
          <Spacer weight={1.0} />
          <Text text={@hours.year} font_family="mono" text_size={12} text_color={Palette.muted()} />
        </Row>
        <Spacer size={20} />
        <Text
          text="Top titles"
          font_family="mono"
          text_size={@titles_size}
          letter_spacing={0.14}
          text_color={Palette.muted()}
        />
        <Spacer size={11} />
        {Kati.Screens.YearShare.posters(@top)}
        <Spacer size={13} />
        {Kati.Screens.YearShare.ranks(@top)}
        {Kati.Screens.YearShare.field_face(@grid, @label_size)}
        {Kati.Screens.YearShare.hours_face_bars(@breakdown, @label_size)}
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  Board 102's contribution field, on this card and in this reader's own year.

  MOVIES-AND-TV.md #3. Dropped entirely when there is nothing to draw: a field
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
        text="Every day"
        font_family="mono"
        text_size={@label_size}
        letter_spacing={0.14}
        text_color={Palette.muted()}
      />
      <Spacer size={11} />
      <Column fill_width={true}>
        {@rows}
      </Column>
    </Column>
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

  MOVIES-AND-TV.md #3, and #45 is why the figures are real: screen 07's bars
  stopped being a fixture, and this reads the same list rather than starting a
  second one. Dropped when there is nothing to divide.
  """
  @spec hours_face_bars([term()], number()) :: map()
  def hours_face_bars([], _label_size), do: ~MOB"<Spacer size={0} />"

  def hours_face_bars(breakdown, label_size) do
    assigns = %{
      label_size: label_size,
      # `bar/1` and not `breakdown/1`: that one wraps the rows in their own
      # card, and here they are already inside one.
      bars: Enum.map(breakdown, &Kati.Screens.Stats.bar/1)
    }

    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={20} />
      <Text
        text="Where the hours went"
        font_family="mono"
        text_size={@label_size}
        letter_spacing={0.14}
        text_color={Palette.muted()}
      />
      <Spacer size={11} />
      {@bars}
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
  def posters(top \\ ShareSample.top_titles()) do
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
  def ranks(top \\ ShareSample.top_titles()) do
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

  @doc false
  def rank_row(title) do
    assigns = %{rank: title.rank, title: title.title}

    ~MOB"""
    <Row fill_width={true} align="center">
      <Text
        text={@rank}
        font_family="mono"
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
        SettingsList.body("Hide titles I marked private", nil),
        SettingsList.trailing(SettingsList.switch(on?)),
        on_tap: {self(), :toggle_private}
      )
    ])
  end

  @doc """
  Save, and the share that is waiting on a fence.

  `Save image` takes the ink because it is the one that works — and now it does
  work. It pushed `Kati.Screens.YearCards` and saved nothing until 6 September
  (MOVIES-AND-TV.md #80), while the note beside it said the capability was
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
          text="Save image"
          text_size={15}
          font_weight="bold"
          letter_spacing={-0.01}
          text_color={Palette.on_ink()}
        />
        <Spacer weight={1.0} />
      </Row>
      <Spacer size={11} />
      <Row fill_width={true} align="center">
        <Spacer weight={1.0} />
        <Text text="Share…" text_size={13.5} font_weight="semibold" text_color={Palette.ink_soft()} />
        <Spacer size={9} />
        <Row
          height={22}
          corner_radius={11}
          background={Palette.track()}
          padding_left={9}
          padding_right={9}
          align="center"
        >
          <Text
            text="WHEN FILE SHARING LANDS"
            font_family="mono"
            text_size={9}
            letter_spacing={0.1}
            text_color={Palette.sub()}
            max_lines={1}
          />
        </Row>
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
      "Every card is drawn on this device. Nothing about your year is uploaded to make " <>
        "it — Kati has no server that could receive it."
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
  and MOVIES-AND-TV.md #80 is that the button said *Save image* and saved
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
  defp message(:no_activity), do: "Kati is not on screen. Nothing was saved."
  defp message(:nothing_drawn), do: "There was nothing to capture. Nothing was saved."
  defp message(:timeout), do: "The page took too long to capture. Nothing was saved."
  defp message(:no_bridge), do: "Saving images does not work here yet."
  defp message(_other), do: "That did not save. The page is unchanged."

  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "scope_" <> scope ->
        socket = Mob.Socket.assign(socket, :scope, scope)
        {:noreply, Kati.Screens.YearShare.restated(socket)}

      _other ->
        {:noreply, socket}
    end
  end
end
