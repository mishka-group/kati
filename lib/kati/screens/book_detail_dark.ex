defmodule Kati.Screens.BookDetailDark do
  @moduledoc """
  Screen 68 — screen 66's book, in the dark colourway.

  Built to `.scratch/design/pending/68.html`. It is the same page as
  `Kati.Screens.BookDetail`, in the sense screen 28 is the same page as screen
  01: same order of bands, same frame, same copy, and deliberately **not** an
  inversion. Every string, every icon name and every number on this screen is
  screen 66's, read through the same `Kati.Screens.BookDetail.book/0` — which
  that module made public for this screen by name, so the two cannot disagree
  about which book they are about, what page it is open at, or how many
  warnings it carries.

  ## What this file is allowed to own

  Three things, and they are the three the drawing's own caption names. Every
  other node on the page is a `Kati.Screens.BookDetail` call. The cover, the
  status lozenge, the progress bar, the stars, the two mono value cells, the
  warning count, the cream card and each history row are that module's
  functions rendering under a dark theme, unchanged and unwrapped.

    * **Lift.** A light card lifts with `Kati.Theme.shadow_card/0`; on
      `#121110` those layers are near-black on near-black and there is nothing
      to see. Dark lifts with `Kati.Theme.Palette.card_hairline/0` instead —
      the drawing's `inset 0 0 0 1px rgba(245,242,238,.06)`. That is the whole
      reason the containers are redrawn here rather than reused: `hero/1`,
      `rating_card/3`, `card/1` and `second/3` are their light counterparts
      with the shadow prop swapped for a border pair, and nothing else moved.
      The rule survives every new shape this page introduces — the cover hero,
      the two rating panels, the four grouped lists and the three action discs
      all carry it.
    * **Inversion.** The selected chip and the ink button both go to
      `#F5F2EE` on `#16150F`, because an ink fill on near-black paper is a
      control you cannot see. Those two values are exactly
      `Kati.Theme.Palette.fab_fill/0` and `Kati.Theme.Palette.fab_glyph/0`,
      whose light values are the same `#1A1917` and `#FBFAF8` that `ink_fill`
      and `on_ink` resolve to — so naming the other pair costs light mode
      nothing and is the only way to say the caption's numbers in tokens.
      `Kati.UI.chip/2` and `Kati.Screens.BookDetail.actions/1` both hardcode
      `ink_fill`/`on_ink`, which in dark is screen 28's *cream* CTA pill —
      `#F7EFE4` on `#1A1917`. That pill belongs to the hero on Home; this page
      draws paper, not cream, so `chip/3` and `actions/1` are written out here
      with the two colours changed and the rest of `Kati.UI.chip/2`'s prop list
      copied across, unselected colours included.
    * **The ring around the cover.** It stays, and it stays drawn in **card**
      colour rather than paper — which is what
      `Kati.Screens.BookDetail.cover/1` already does, so that function is
      reused verbatim and this bullet is a note about why nothing was changed.
      A 2pt paper ring would cut a `#121110` gap out of the card the cover sits
      on; a `#1E1D1B` ring reads as the cover's own lifted edge, which is the
      thing the drawing is showing.

  ## The one card dark does not lift

  The cream note card. The drawing gives it no ring and no shadow in either
  mode — `#FBF1DE` on paper, `#2A2622` on near-black — because cream is
  already doing the lifting: it is the only warm rectangle on the page and it
  marks the user's own words. So `Kati.Screens.BookDetail.notes_section/1` is
  reused whole, eyebrow and all, and the fact that it draws no border is not an
  omission here. Screen 28's cream hero *does* take an orange hairline; that
  one sits under a photograph stack and needs the edge. This one does not.

  ## Pinning the theme, and what it costs

  `Kati.Screens.Pushed`'s `mount/3` calls `Kati.Theme.activate/0`, which
  resolves the user's Auto / Light / Dark preference. This screen is drawn dark
  in a light-mode app — it is the reference for what a pushed detail screen
  looks like there — so `load/1` overrides that with
  `Mob.Theme.set(Kati.Theme.dark())`, the same single call screens 28 and 29
  make and the only switch there is: `Kati.Theme.Palette.mode/0` reads whatever
  theme is installed rather than storing a second answer.

  The cost is the one screens 28 and 29 already carry, stated rather than
  hidden. `Mob.Theme.set/1` is global, and popping back to Library does not
  remount Library, so the app stays dark until the next screen mounts and
  activates the preference again. That closes when dark stops being a separate
  page and becomes a mode `Kati.Shell` carries — the same fix
  `Kati.Screens.HomeDark` is waiting on — at which point this module and its
  four redrawn containers should disappear into their light twins.
  """

  use Kati.Screens.Pushed, back: "Library"

  alias Kati.Books.Sample
  alias Kati.Components.MishkaChip
  alias Kati.Screens.BookDetail
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  # Screen 66's three secondary actions, in the drawing's order. Restated here
  # rather than reached for through `Kati.Screens.BookDetail`, where the list is
  # a private module attribute; `Log progress` is absent from both copies for
  # the same reason, which is that `actions/1` draws the ink button itself.
  @secondary [
    {"check", "Finish", :finish},
    {"star", "Rate & review", :rate},
    {"bookmarks", "Add to list", :add_to_list}
  ]

  @spec load(Mob.Socket.t()) :: Mob.Socket.t()
  def load(socket) do
    Mob.Theme.set(Kati.Theme.dark())
    Mob.Socket.assign(socket, :book, BookDetail.book())
  end

  @doc false
  @spec content(map()) :: map()
  def content(assigns) do
    b = assigns.book

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
        {SettingsList.title(b.title, b.author, nil, :name)}
        {Kati.Screens.BookDetailDark.hero(b)}
        {Kati.Screens.BookDetailDark.ratings(b)}
        {UI.eyebrow("Status")}
        {Kati.Screens.BookDetailDark.statuses(b)}
        {UI.eyebrow("Edition")}
        {Kati.Screens.BookDetailDark.edition(b)}
        {UI.eyebrow("Content warnings")}
        {Kati.Screens.BookDetailDark.warnings(b)}
        {BookDetail.notes_section(b)}
        {Kati.Screens.BookDetailDark.series_section(b)}
        {Kati.Screens.BookDetailDark.history_section(b)}
        {Kati.Screens.BookDetailDark.actions(b)}
      </Column>
    </Scroll>
    """
  end

  @doc """
  The grouped list card: `SettingsList.card/1`'s geometry, lifted by a hairline.

  Radius 20, 15pt sides, 4pt top and bottom — the four numbers that module
  states, repeated here because the container is the one thing dark changes and
  `SettingsList.card/1` has no way to be told so. It paints
  `Kati.Theme.shadow_card_soft/0` unconditionally, which on this page is two
  near-black layers over a near-black ground: correct in light, and in dark a
  card with no edge at all. Everything that goes *inside* still comes from
  `Kati.UI.SettingsList` — the rows, the hairlines between them, the icon
  tiles, the switch and the chevron are all mode-aware already.
  """
  @spec card([term()]) :: map()
  def card(rows) do
    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={20}
      border_width={1}
      border_color={Palette.card_hairline()}
      padding_left={15}
      padding_right={15}
      padding_top={4}
      padding_bottom={4}
    >
      {rows}
    </Column>
    """
  end

  @doc """
  The hero card: cover beside status, edition facts, bar and pace.

  `Kati.Screens.BookDetail.hero/1` with the shadow swapped for the hairline.
  All four children are that module's — `cover/1`, `status_pill/2` and `bar/1`
  are reused because none of them changes: the ring is card colour in both
  modes, the green wash is a hue and holds at full strength on near-black, and
  the bar is the one orange on this page in either colourway.
  """
  @spec hero(map()) :: map()
  def hero(b) do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        border_width={1}
        border_color={Palette.card_hairline()}
        padding={17}
      >
        <Row fill_width={true}>
          {BookDetail.cover(b)}
          <Spacer size={15} />
          <Column weight={1.0}>
            {BookDetail.status_pill(b.status, b.status_label)}
            <Spacer size={11} />
            <Text
              text={b.meta}
              font_family="mono"
              text_size={11}
              text_color={Palette.muted()}
              max_lines={1}
            />
            {BookDetail.bar(b.progress)}
            <Spacer size={9} />
            <Text
              text={b.progress_line}
              font_family="mono"
              text_size={10.5}
              text_color={Palette.muted()}
              max_lines={1}
            />
          </Column>
        </Row>
      </Column>
      <Spacer size={11} />
    </Column>
    """
  end

  @doc """
  Two rating columns, `Yours` and `Community`, and no third.

  The em dash under `Community` is screen 66's decision and it survives the
  change of ground intact: there is no source for a community rating, and an
  absent column would say your opinion is the only one that exists. Dark does
  not get to revisit that; it only gets to say how the two panels lift.
  """
  @spec ratings(map()) :: map()
  def ratings(b) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        <Column weight={1.0}>
          {Kati.Screens.BookDetailDark.rating_card("Yours", b.rating, b.rating_label)}
        </Column>
        <Spacer size={10} />
        <Column weight={1.0}>
          {Kati.Screens.BookDetailDark.rating_card("Community", b.community, nil)}
        </Column>
      </Row>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  @spec rating_card(String.t(), integer() | nil, String.t() | nil) :: map()
  def rating_card(label, rating, value) do
    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={18}
      border_width={1}
      border_color={Palette.card_hairline()}
      padding={14}
    >
      <Text
        text={String.upcase(label)}
        font_family="mono"
        text_size={9.5}
        letter_spacing={0.12}
        text_color={Palette.muted()}
      />
      <Spacer size={9} />
      <Row fill_width={true} align="center">
        {BookDetail.stars(rating)}
        <Spacer size={9} />
        <Text
          text={value || "—"}
          font_family="mono"
          text_size={13}
          text_color={:on_surface}
          max_lines={1}
        />
      </Row>
    </Column>
    """
  end

  @doc """
  A filter chip whose selected state is paper rather than ink.

  `Kati.UI.chip/2`'s prop list with two values changed —
  `Kati.Theme.Palette.fab_fill/0` for the pill and
  `Kati.Theme.Palette.fab_glyph/0` for the label — and the unselected pair left
  exactly as that helper writes it, so an unselected chip on this page and on
  screen 66 are one node under two themes. The pair that had to move is the
  ink-filled one: see the moduledoc for why `ink_fill`/`on_ink` is the wrong
  inversion here and `fab_fill`/`fab_glyph` is the caption's own.

  `on_toggle` carries the tag straight through, so the chips write and are not
  a picture of chips; `Kati.Screens.BookDetail.chip_change/1` is the parser at
  the other end and there is only one of it.
  """
  @spec chip(String.t(), boolean(), atom()) :: map()
  def chip(label, selected?, tag) do
    MishkaChip.chip(
      label: label,
      checked: selected?,
      on_toggle: tag,
      color: Palette.fab_fill(),
      text_color: Palette.fab_glyph(),
      unchecked_color: Palette.card(),
      unchecked_text_color: Palette.ink_soft(),
      corner_radius: 16,
      height: 32,
      padding_x: 15,
      padding_y: 0,
      text_size: 12,
      max_lines: 1
    )
  end

  @doc """
  The four status choices, as first-class taps.

  Screen 66's band with screen 66's four labels and screen 66's writes. Only
  the selected pill's two colours differ, and a `Row` does not wrap, so the
  four chips share one row exactly as the drawing lays them out.
  """
  @spec statuses(map()) :: map()
  def statuses(b) do
    chips =
      Sample.statuses()
      |> Enum.map(fn {value, label} ->
        chip(label, value == b.status, String.to_atom("status_#{value}"))
      end)
      |> Enum.intersperse(~MOB"<Spacer size={7} />")

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true}>
        {chips}
      </Row>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  Format chips, the two facts that follow from the format, then the toggle.

  `Kati.Screens.BookDetail.value/1` and `mono/1` set the two right-hand cells,
  which is where the band's point lives: `380 pages` restates its unit, and an
  edition switched to audiobook would restate a different one. Neither cell
  cares what colour the page is, so neither is rewritten.
  """
  @spec edition(map()) :: map()
  def edition(b) do
    chips =
      Sample.formats()
      |> Enum.map(fn {value, label} ->
        chip(label, value == b.format, String.to_atom("format_#{value}"))
      end)
      |> Enum.intersperse(~MOB"<Spacer size={7} />")

    facts =
      card([
        SettingsList.row(
          nil,
          SettingsList.body("Length", nil),
          SettingsList.trailing(BookDetail.value(b.extent_label))
        ),
        SettingsList.row(
          nil,
          SettingsList.body("ISBN", nil),
          SettingsList.trailing(BookDetail.mono(b.isbn))
        )
      ])

    owned =
      card([
        SettingsList.row(
          SettingsList.icon_tile("inventory_2"),
          SettingsList.body("This is the edition I own", nil),
          SettingsList.trailing(SettingsList.switch(b.owned))
        )
      ])

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true}>
        {chips}
      </Row>
      <Spacer size={12} />
      {facts}
      <Spacer size={12} />
      {owned}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  The warnings block, closed.

  Closed on arrival in both colourways, and for the reason screen 66 gives: the
  point of a content warning is that you choose to look at it. The count and
  the `expand_more` chevron come from
  `Kati.Screens.BookDetail.warning_trailing/1`, which already answers `0` with
  `None recorded` and an `add`.
  """
  @spec warnings(map()) :: map()
  def warnings(b) do
    rows = [
      SettingsList.row(
        nil,
        SettingsList.body("Warnings", nil),
        SettingsList.trailing(BookDetail.warning_trailing(b.warning_count))
      )
    ]

    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.BookDetailDark.card(rows)}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  Series and ownership: two rows that push, or as few of them as are true.

  A book in no series and lent to nobody takes the whole band with it, exactly
  as it does in light — an empty card under a heading is a promise the app has
  not kept, and that is a statement about the app rather than about the ground
  it is drawn on.
  """
  @spec series_section(map()) :: map() | []
  def series_section(b) do
    rows =
      [
        b.series_line && series_row(b),
        b.lent_to && lending_row(b)
      ]
      |> Enum.reject(&is_nil/1)

    case rows do
      [] ->
        []

      rows ->
        ~MOB"""
        <Column fill_width={true}>
          {UI.eyebrow("Series and ownership")}
          {Kati.Screens.BookDetailDark.card(rows)}
          <Spacer size={24} />
        </Column>
        """
    end
  end

  defp series_row(b) do
    SettingsList.row(
      SettingsList.icon_tile("menu_book"),
      SettingsList.body(b.series_line, b.series_next),
      SettingsList.trailing(SettingsList.chevron()),
      on_tap: {self(), :open_series}
    )
  end

  defp lending_row(b) do
    SettingsList.row(
      SettingsList.icon_tile("inventory_2"),
      SettingsList.body(b.lent_to, b.lent_due),
      SettingsList.trailing(SettingsList.chevron()),
      on_tap: {self(), :open_lending}
    )
  end

  @doc """
  The history band, in screen 15's activity-row idiom.

  Every row is `Kati.Screens.BookDetail.session_row/1` — the date gutter, the
  rail, the span and the duration are all mode-aware tokens already — so what
  this adds is the card around them and nothing else. A book with no logged
  sitting draws no band, which is the same `[]` clause the light screen has.
  """
  @spec history_section(map()) :: map() | []
  def history_section(b) do
    case Map.get(b, :sessions, Sample.sessions()) do
      [] ->
        []

      sessions ->
        rows = Enum.map(sessions, &BookDetail.session_row/1)

        ~MOB"""
        <Column fill_width={true}>
          {UI.eyebrow("Reading history")}
          {Kati.Screens.BookDetailDark.card(rows)}
          <Spacer size={24} />
        </Column>
        """
    end
  end

  @doc """
  One ink button and three seconds — and in dark the ink button is paper.

  `#F5F2EE` filled with `#16150F`, which is `fab_fill`/`fab_glyph` and is the
  second of the two treatments the drawing's caption names. Everything else is
  screen 66's: the button relabels to `Start reading` for a book you have not
  opened rather than moving, because it is the same control at a different
  point in the same job, and the three seconds keep 08's circular treatment
  even though the drawing sets them as tiles — that divergence belongs to
  screen 66's caption and a twin does not get to settle it differently.
  """
  @spec actions(map()) :: map()
  def actions(b) do
    primary = if b.status == :not_started, do: "Start reading", else: "Log progress"

    seconds =
      @secondary
      |> Enum.map(fn {icon, label, tag} ->
        Kati.Screens.BookDetailDark.second(icon, label, tag)
      end)
      |> Enum.intersperse(~MOB"<Spacer size={10} />")

    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        height={52}
        corner_radius={26}
        background={Palette.fab_fill()}
        align="center"
        on_tap={{self(), :log_progress}}
      >
        <Spacer weight={1.0} />
        <Text
          text={primary}
          text_size={15}
          font_weight="bold"
          letter_spacing={-0.01}
          text_color={Palette.fab_glyph()}
        />
        <Spacer weight={1.0} />
      </Row>
      <Spacer size={12} />
      <Row fill_width={true}>
        {seconds}
      </Row>
    </Column>
    """
  end

  @doc false
  @spec second(String.t(), String.t(), atom()) :: map()
  def second(icon, label, tag) do
    ~MOB"""
    <Column weight={1.0} align="center" on_tap={{self(), tag}}>
      <Box
        width={44}
        height={44}
        corner_radius={22}
        background={Kati.Theme.Palette.card()}
        border_width={1}
        border_color={Kati.Theme.Palette.card_hairline()}
        align="center"
      >
        {Kati.UI.symbol(icon, size: 20)}
      </Box>
      <Spacer size={7} />
      <Text
        text={label}
        text_size={11.5}
        font_weight="semibold"
        text_color={Kati.Theme.Palette.sub()}
        max_lines={1}
      />
    </Column>
    """
  end

  @doc false
  @spec handle_tap(atom(), Mob.Socket.t()) :: {:noreply, Mob.Socket.t()}
  # Screen 66's push, and named the same way: the sheet is handed the id of the
  # book this page is drawing rather than left to re-read the shelf and take its
  # first row (#84). The dark page draws `BookDetail.book/0`, so it is the same
  # book and the same id.
  def handle_tap(:log_progress, socket),
    do:
      {:noreply,
       Mob.Socket.push_screen(
         socket,
         Kati.Screens.LogProgress,
         Kati.Screens.LogProgress.params_for(socket.assigns.book)
       )}

  def handle_tap(:rate, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Rating)}

  def handle_tap(:add_to_list, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Lists)}

  # `Finish` writes and then hands to the rating screen, which is the handover
  # screen 66 makes and the one screen 70 makes from the other direction. The
  # write itself lives in `Kati.Screens.LogProgress` so that three controls on
  # three screens cannot drift about what finishing a book means.
  # And it names the book, for the reason the push above it does. The comment
  # over this clause promises three controls that cannot drift about what
  # finishing a book means; finishing the shelf's head from a page drawing
  # something else is that drift, arriving through the argument rather than
  # through the write. `book[:id]` because the drawing has no id to read.
  def handle_tap(:finish, socket) do
    Kati.Screens.LogProgress.finish_book(socket.assigns.book[:id])
    {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Rating)}
  end

  # The series and lending rows are drawn, reachable and answered, and what
  # each would push is a screen the design has not drawn — the same standing
  # exception screen 66 records rather than leaving a tap dead.
  #
  # A chip write re-reads instead of assigning the chip's own value, because
  # the hero band is derived from the row: the bar, the pace line, the extent
  # and the meta line would all go on disagreeing with a chip that only moved
  # itself.
  def handle_tap(tag, socket) do
    case BookDetail.chip_change(tag) do
      nil ->
        {:noreply, socket}

      change ->
        BookDetail.apply_change(change)
        {:noreply, Mob.Socket.assign(socket, :book, BookDetail.book())}
    end
  end
end
