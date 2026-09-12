defmodule Kati.Screens.DiscoverFilters do
  @moduledoc """
  Board 169 — Sort & filter, a sheet over Discover.

  ## What this is not

  It is not board 169 built. It is board 169's **buildable half**, and the
  split is stated in `Kati.Discover.Filters`, control by control, with the
  reason each of the five omitted ones cannot be answered by any TMDB field.
  Board 169 stays in `test/design/incoming/` and is deliberately not registered
  in `Kati.Screens.Gallery`'s `@screens`, because registering it would make
  `Best match`, `90% and up`, `Unscored`, `Lumen+`, `Orbit`, `Only with news`
  and `showing 4 of 8` compulsory literals — which is to say it would force
  back precisely the invented figures this page exists to remove.
  `Kati.Screens.Service` is the precedent, and `@undrawn` is where a page with
  no artboard is declared so `@undesigned` cannot quietly mean *on no page*.

  ## The sheet's own honesty problem, and how it is settled

  Board 169 puts a count on eight chips and `showing 4 of 8` at the foot. A
  per-chip count is one HTTP request per chip; the board's own note says all
  of them come from Discover's sample. So no chip carries a badge.

  The footer is the interesting one. TMDB does report `total_results` for a
  query, so after Discover has asked, the size of the current selection is a
  real number — and it is passed in as a param. But it describes the choice
  that produced it and nothing else, so **the moment a chip moves it is
  dropped**: `count_line/2` compares the live choice against the one the sheet
  opened with and prints nothing when they differ. A stale total is exactly the
  plausible-looking figure `Kati.Screens.Discover`'s own moduledoc rules out;
  no total at all is honest, and the next answer brings a true one.

  ## Storing rather than committing

  Every tap writes through to `Kati.Discover.Filters.put/1` immediately, the
  way `Kati.Screens.ShelfFilters` does — there is no *Apply* on board 169 and
  the reader closing the sheet with the close disc must not lose what they
  chose. Screen 11 re-reads the choice on resume and re-asks.
  """

  use Mob.Screen
  use Gettext, backend: Kati.Gettext
  import Mob.Sigil

  alias Kati.Discover.Filters
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.Sheet
  alias Kati.UI.SettingsList

  @impl true
  def mount(params, _session, socket) do
    Kati.Theme.activate()
    Kati.Locale.activate()

    choice = Filters.current()

    {:ok,
     Mob.Socket.assign(socket,
       choice: choice,
       # What the total describes. See the moduledoc: it is dropped the moment
       # the choice moves away from this.
       opened_with: choice,
       total: total_param(params)
     )}
  end

  @impl true
  def render(assigns),
    do: Sheet.sheet(gettext("Sort & filter"), body(assigns), Kati.Screens.Identity.of(__MODULE__))

  @doc false
  def body(assigns) do
    choice = assigns.choice

    # Board 145's sheet says five of these words in the same five places, and
    # `Kati.Screens.ShelfFilters` translated them first — so this page reaches
    # for ITS msgids rather than minting a second set. Two sheets that disagree
    # in Persian about what *Filters* is called would be a difference the
    # English pair does not have.
    #
    # `pgettext/2` on the one-word eyebrows and on *Reset* in `footer/1`, for
    # the reason board 145 records: `mix gettext.merge` fuzzy-matches a msgid
    # that short against whatever it resembles, and a bare `Sort` sitting one
    # edit away from `Sort & filter` — the title of this very sheet — is
    # exactly the pair that arrives translated to the wrong one and marked
    # fuzzy. The Ranges eyebrow is a whole clause and needs no context.
    ~MOB"""
    <Column fill_width={true}>
      {UI.eyebrow(pgettext("sort & filter sheet section", "Sort"))}
      {Kati.Screens.DiscoverFilters.sort_card(choice)}
      <Spacer size={16} />
      {SettingsList.eyebrow_muted(gettext("Ranges — buckets, not sliders"))}
      {Kati.Screens.DiscoverFilters.rating_chips(choice)}
      <Spacer size={11} />
      {SettingsList.note("star", Kati.Screens.DiscoverFilters.rating_note())}
      <Spacer size={16} />
      {SettingsList.eyebrow_muted(pgettext("sort & filter sheet section", "Filters"))}
      {Kati.Screens.DiscoverFilters.kind_chips(choice)}
      <Spacer size={16} />
      {Kati.Screens.DiscoverFilters.footer(assigns)}
      <Spacer size={14} />
      {SettingsList.note("info", Kati.Screens.DiscoverFilters.note_text())}
    </Column>
    """
  end

  @doc """
  The sentence under the rating buckets, which is the whole reason the numbers
  are out of ten rather than percentages.
  """
  @spec rating_note() :: String.t()
  def rating_note do
    # The vote floor is INTERPOLATED rather than written into the sentence, so
    # the Persian reader is told ۲۰۰ and not 200 — a numeral inside a sentence
    # takes `Kati.Locale.number/1` here as it does everywhere else. The literal
    # restates `Kati.Discover.Filters`' own `@vote_floor`, which is private to
    # that module; the two are the same figure and must not drift, and the
    # sentence is the only place a reader ever sees it.
    #
    # `TMDB` stays Latin inside the Persian sentence. It is a service's name
    # for itself — `Kati.Services.Service` never translates one — and the
    # catalogue already writes it that way in nine other Persian strings.
    gettext(
      "TMDB's own average out of ten, from everyone who rated it — not a fit to your shelf. Only titles with %{n} or more votes are counted, so one perfect score cannot carry a film.",
      n: Kati.Locale.number(200)
    )
  end

  @doc """
  The note at the foot.

  It says where the answers come from and stops. An earlier version named the
  five controls board 169 draws that no TMDB field answers — *Leaving soonest*,
  *Unscored*, the two service chips — and `Kati.DiscoverFiltersTest` refused it,
  correctly: a reader who has never seen the board does not know those words,
  and a sheet that lists what it cannot do teaches them a vocabulary of absent
  features. The omissions are recorded in `Kati.Discover.Filters` and in
  MOVIES-AND-TV.md, which is where a reason belongs.
  """
  @spec note_text() :: String.t()
  def note_text do
    gettext(
      "These go to TMDB rather than to a recommender, so nothing here is scored against your own shelf."
    )
  end

  # ── Sort ─────────────────────────────────────────────────────────────────

  @doc "The three sort rows; the active one carries a check and its title in bold."
  @spec sort_card(map()) :: map()
  def sort_card(choice) do
    sorts = Filters.sorts()
    last = length(sorts) - 1

    rows =
      sorts
      |> Enum.with_index()
      |> Enum.map(fn {key, i} ->
        Kati.Screens.DiscoverFilters.sort_row(key, Map.get(choice, :sort), i != last)
      end)

    SettingsList.card(rows)
  end

  @doc false
  def sort_row(key, selected, rule?) do
    {label, sub} = Filters.sort_label(key)
    selected? = key == selected

    leading =
      if selected?,
        do: Kati.Screens.DiscoverFilters.tile("check", Palette.ink()),
        else: Kati.Screens.DiscoverFilters.tile("sort", Palette.ink_soft())

    SettingsList.row(
      leading,
      SettingsList.body(label, sub),
      nil,
      rule: rule?,
      on_tap: {self(), Kati.Screens.DiscoverFilters.tag("sort_", key)}
    )
  end

  # `SettingsList.icon_tile/1` always draws its glyph in `ink_soft`, which is
  # right for the two unselected rows and wrong for the active row's `check`.
  # `Kati.Screens.ShelfFilters.sort_icon_tile/2` made the same restatement for
  # the same reason, on the same control.
  @doc false
  def tile(icon, color) do
    Kati.Components.MishkaThemeIcon.theme_icon(
      %{variant: :filled, color: Kati.Theme.paper(Palette.mode()), size: 30, radius: 9},
      [UI.symbol(icon, size: 17, color: color)]
    )
  end

  # ── Chips ────────────────────────────────────────────────────────────────

  @doc "The three rating floors, lowest first."
  @spec rating_chips(map()) :: map()
  def rating_chips(choice) do
    Filters.ratings()
    |> Enum.map(fn key ->
      {Kati.Screens.DiscoverFilters.tag("rate_", key), Filters.rating_label(key),
       key == Map.get(choice, :rating)}
    end)
    |> Kati.Screens.DiscoverFilters.chip_row()
  end

  @doc "Film and Series, which are the two endpoints rather than two filters."
  @spec kind_chips(map()) :: map()
  def kind_chips(choice) do
    Filters.kinds()
    |> Enum.map(fn key ->
      {Kati.Screens.DiscoverFilters.tag("kind_", key), Filters.kind_label(key),
       key == Map.get(choice, :kind)}
    end)
    |> Kati.Screens.DiscoverFilters.chip_row()
  end

  @doc false
  def chip_row(chips) do
    drawn =
      chips
      |> Enum.map(fn {tag, label, on?} -> Kati.Screens.DiscoverFilters.chip(tag, label, on?) end)
      |> Enum.intersperse(~MOB"<Spacer size={7} />")

    ~MOB"""
    <Row fill_width={true} align="center">
      {drawn}
    </Row>
    """
  end

  @doc """
  One chip. No count badge — see the moduledoc.

  Built against `Kati.UI.chip/2`'s numbers by hand rather than through it,
  because `chip/2` takes a count and this control has none to give it.
  """
  @spec chip(atom(), String.t(), boolean()) :: map()
  def chip(tag, label, on?) do
    assigns = %{label: label, on?: on?, tap: {self(), tag}}

    ~MOB"""
    <Row
      height={32}
      corner_radius={16}
      background={if @on?, do: Palette.ink_fill(), else: Palette.card()}
      shadow={if @on?, do: nil, else: Kati.Theme.shadow_card_soft()}
      padding_left={15}
      padding_right={15}
      align="center"
      on_tap={@tap}
    >
      <Text
        text={@label}
        text_size={12.5}
        font_weight="semibold"
        text_color={if @on?, do: Palette.on_ink(), else: Palette.ink_soft()}
        max_lines={1}
      />
    </Row>
    """
  end

  # ── Footer ───────────────────────────────────────────────────────────────

  @doc false
  def footer(assigns) do
    assigns = %{line: Kati.Screens.DiscoverFilters.count_line(assigns.choice, assigns)}

    ~MOB"""
    <Box
      fill_width={true}
      background={Kati.Theme.card(Palette.mode())}
      corner_radius={20}
      padding={15}
      shadow={Kati.Theme.shadow_card_soft()}
    >
      <Row fill_width={true} align="center">
        {Kati.Screens.DiscoverFilters.count_text(@line)}
        <Spacer weight={1.0} />
        <Row align="center" on_tap={{self(), :reset}}>
          <Text
            text={pgettext("clears every filter on the sheet", "Reset")}
            text_size={12.5}
            font_weight="semibold"
            text_color={Palette.sub()}
            max_lines={1}
          />
        </Row>
      </Row>
    </Box>
    """
  end

  @doc false
  def count_text(nil), do: ~MOB"<Spacer size={0} />"

  def count_text(line) do
    # `Kati.Locale.mono_face/0` rather than a hardcoded `"mono"`: `kati_mono.ttf`
    # carries no Persian glyph and none of U+06F0–U+06F9 either, so a Persian
    # `۴,۲۱۳ عنوان` left in mono is handed to Android's substitute face whole —
    # the figure and the noun both. The line is the reader's own script all the
    # way through, a phrase rather than a bare figure, so it is `mono_face/0`
    # and not `mono_face/1`. `Kati.Screens.ShelfFilters.count_card/2` makes the
    # same call for the same line on board 145.
    ~MOB"""
    <Text
      text={line}
      font_family={Kati.Locale.mono_face()}
      text_size={13}
      text_color={:on_surface}
      max_lines={1}
    />
    """
  end

  @doc """
  How many titles the CURRENT selection holds, when that is known.

      iex> resting = Kati.Discover.Filters.resting()
      iex> Kati.Screens.DiscoverFilters.count_line(resting, %{opened_with: resting, total: 4213})
      "4,213 titles"

  And nothing at all once a chip has moved, because the figure describes the
  choice that produced it:

      iex> resting = Kati.Discover.Filters.resting()
      iex> moved = Kati.Discover.Filters.with_kind(resting, :tv)
      iex> Kati.Screens.DiscoverFilters.count_line(moved, %{opened_with: resting, total: 4213})
      nil

  Nor before Discover has ever answered:

      iex> resting = Kati.Discover.Filters.resting()
      iex> Kati.Screens.DiscoverFilters.count_line(resting, %{opened_with: resting, total: nil})
      nil
  """
  @spec count_line(map(), map()) :: String.t() | nil
  def count_line(choice, %{opened_with: choice, total: total})
      when is_integer(total) and total > 0 do
    # `thousands/1` groups and `Kati.Locale.number/1` then puts the digits into
    # the reader's own numerals — in that order, because the SEPARATOR is not
    # translated with them. CLDR's `fa` groups with U+066C and the drawings do
    # not: `test/design/screens/59.html` writes ۱,۴۸۰ with a Latin comma, which
    # is why `Kati.Locale.number/1` converts the decimal point and leaves
    # grouping alone. So the comma survives the crossing and the digits do not.
    #
    # `ngettext/4` and not a concatenation: `<> " titles"` froze the noun in
    # Latin and the word order with it, and Persian puts no plural mark on a
    # noun after a numeral — ۴,۲۱۳ عنوان, not عنوان‌ها.
    ngettext(
      "%{n} title",
      "%{n} titles",
      total,
      n: Kati.Locale.number(Kati.Screens.DiscoverFilters.thousands(total))
    )
  end

  def count_line(_choice, _assigns), do: nil

  @doc """
  A count with its thousands separated, which is how every other figure in the
  app is printed.

      iex> Kati.Screens.DiscoverFilters.thousands(4213)
      "4,213"

      iex> Kati.Screens.DiscoverFilters.thousands(42)
      "42"

  Latin digits in both scripts, deliberately: this groups and nothing else, and
  `count_line/2` hands the result to `Kati.Locale.number/1` for the numerals.
  The comma it inserts is kept even in Persian — see `count_line/2`.
  """
  @spec thousands(integer()) :: String.t()
  def thousands(n) do
    n
    |> Integer.to_string()
    |> String.graphemes()
    |> Enum.reverse()
    |> Enum.chunk_every(3)
    |> Enum.map_join(",", &Enum.join/1)
    |> String.reverse()
  end

  # ── Taps ─────────────────────────────────────────────────────────────────

  @doc """
  A control's name: the prefix and the stable key under it, never the label.

      iex> Kati.Screens.DiscoverFilters.tag("rate_", :r8)
      :rate_r8

  `Kati.Screens.AddByHand.tag/2`'s rule, and MOVIES-AND-TV.md #158 is why.
  """
  @spec tag(String.t(), atom()) :: atom()
  defdelegate tag(prefix, key), to: Kati.Screens.AddByHand

  @impl true
  def handle_info({:tap, :close}, socket), do: {:noreply, Kati.Screens.Resume.pop(socket)}

  def handle_info({:tap, :reset}, socket),
    do: {:noreply, Kati.Screens.DiscoverFilters.store(socket, Filters.resting())}

  def handle_info({:tap, tag}, socket) do
    choice = socket.assigns.choice

    moved =
      case Atom.to_string(tag) do
        "sort_" <> key -> Filters.with_sort(choice, Kati.Screens.DiscoverFilters.key(key))
        "rate_" <> key -> Filters.with_rating(choice, Kati.Screens.DiscoverFilters.key(key))
        "kind_" <> key -> Filters.with_kind(choice, Kati.Screens.DiscoverFilters.key(key))
        _other -> choice
      end

    {:noreply, Kati.Screens.DiscoverFilters.store(socket, moved)}
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  @doc """
  A tag's suffix back as the key it names, or `nil`.

      iex> Kati.Screens.DiscoverFilters.key("top_rated")
      :top_rated

      iex> Kati.Screens.DiscoverFilters.key("something nobody drew")
      nil

  `String.to_existing_atom/1` and not `String.to_atom/1`: a tap handler on a
  pushed screen that raises is a dead process and a bounce to Home, and every
  atom this can legitimately name already exists. `Kati.Screens.SeriesSettings`
  records the same reasoning for `pass_`.
  """
  @spec key(String.t()) :: atom() | nil
  def key(suffix) do
    String.to_existing_atom(suffix)
  rescue
    ArgumentError -> nil
  end

  @doc """
  Store a choice and put it on the socket. Both, always — the sheet has no
  *Apply*, so what is on screen and what screen 11 will re-read must not be
  able to differ.
  """
  @spec store(Mob.Socket.t(), map()) :: Mob.Socket.t()
  def store(socket, choice) do
    Filters.put(choice)
    Mob.Socket.assign(socket, :choice, choice)
  end

  defp total_param(params) when is_map(params) do
    case Map.get(params, :total) do
      n when is_integer(n) and n > 0 -> n
      _absent -> nil
    end
  end

  defp total_param(_none), do: nil
end
