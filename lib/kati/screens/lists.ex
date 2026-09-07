defmodule Kati.Screens.Lists do
  @moduledoc """
  Screen 12 — Lists, pushed under Library.

  Built to `test/design/screens/12.html`. Hand-made lists sit above the
  ones the app keeps, and the two are drawn as different objects rather than as
  one list with a divider: a made list shows three fanned posters, because what
  is in it is the point; a kept list shows an icon and a count, because it is a
  rule and its contents follow from the rule.

  ## The fanned stack

  The drawing overlaps three 38x54 tiles by 14pt with `margin-left:-14px`. Mob
  has no negative margin, so the fan is a `Box` of declared width with each
  tile pushed in by a `Row`'s `padding_left` — 0, 24, 48 — which reproduces the
  same geometry from the other side: 38 + 24 + 24 = 86, the width the drawing's
  three overlapped tiles occupy.

  Each tile's 2pt `#FBFAF8` ring is padding on a card-coloured box rather than
  a border, so the artwork is clipped by the inner radius and the ring stays
  crisp at the overlap.

  ## The one control

  The drawing gives this screen no chips, no segments and no switches — the
  only thing on it that can be pressed is the `add` disc, and on a screen
  called Lists that means *make a list*. So it does: a new hand-made list
  appears at the top of the made section, empty, and the header count goes up
  with it. Nothing is drawn that the design does not draw — the new row is the
  same made row, with no artwork in its stack and `0 titles` under its name,
  which is what an empty list looks like.

  The rows themselves are left untappable on purpose. Their chevrons point at a
  list-detail screen the design never draws and the app does not have, and
  `on_tap={nil}` — a row that does nothing and admits it — is better than a row
  that swallows a press.

  ## Why this screen still reads `Kati.Screens.Lists.Sample`

  Not a missing column this time — a missing **resource**. `Kati.Media` holds
  `Kati.Media.CachedTitle`, `Kati.Media.TrackedTitle` and `Kati.Media.Watch`,
  and that is the whole of it. Nothing in the app names a list, orders one, or
  records that a title is in one, so unlike screen 03 there is no query to
  write and no shape to fall back *from*.

  Precisely what this screen draws and no resource can express:

    * **the made lists themselves** — `Best of 2026`, `Rainy Sunday`,
      `Recommended by Jo`. A name, plus the `ranked` / `shared` badge, which is
      a list's own state and not a property of anything in it.
    * **membership** — which is both `14 titles` and the three posters in each
      fanned stack. A list-to-title join is the table that does not exist, and
      the stack is its first three rows' `Kati.Media.CachedTitle.poster_path`.
    * **`7 lists · 2 ranked`** — the count of lists, and of the ranked ones.
      The drawing means it to exceed the three cards on screen, so it is a
      count of the table rather than of the section.
    * **the kept lists** — `Wishlist`, `Rewatches`, `Abandoned`, `Owned on
      disc`, and their counts. Two of the four could be *inferred* today —
      `Abandoned` is `status: :dropped` on `Kati.Media.TrackedTitle`, and
      `Rewatches` is a `Kati.Media.Watch` carrying a `rewatch_number` — and
      neither is split out, because a card where two rows count the user's real
      library and two are frozen reads as fully real. `Wishlist` and `Owned on
      disc` are assertions the user makes and nothing stores.

  ## What this screen is still waiting for, and it is not a column

  MOVIES-AND-TV.md #106, and the half of it no code can close. Three surfaces
  the design does not draw:

    * **nowhere to name a list.** Board 12 has no text entry, so a list created
      as `New list` with no way to rename it is the same lie one step further
      in — which is why `Kati.Lists.List` is not written. A resource whose only
      writer has to invent its own copy is worse than none.
    * **no list picker.** Board 146's *Add to list* is the membership route the
      design DOES draw, and it needs somewhere to put the title.
    * **no list detail.** Every row here drew a `chevron_right` at a board that
      does not exist; the chevrons are gone rather than left pointing nowhere.

  Filed as [mishka-group/kati#99](https://github.com/mishka-group/kati/issues/99)
  with the schema those drawings would need, so design does not have to guess at
  what is cheap. The rule this follows is `Kati.Screens.ImportSources`'s, for
  its own repeated literal: guessing what was meant would be inventing copy the
  drawing does not contain, and three undrawn surfaces is three inventions.

  What HAS shipped is everything the store can answer: two of the four *Kept
  automatically* rows are the reader's own counts, the two that are assertions
  nothing holds are not drawn, and `+` says what it is waiting for instead of
  reporting a change nothing kept.
  """
  use Kati.Screens.Pushed, back: "Library"

  alias Kati.Components.MishkaPill
  alias Kati.Components.MishkaSeparator
  alias Kati.Components.MishkaThemeIcon
  alias Kati.Screens.Lists.Sample
  alias Kati.Theme.Palette
  alias Kati.UI

  @impl true
  def load(socket), do: Mob.Socket.assign(socket, :lists, Kati.Screens.Lists.lists())

  @doc """
  The page: the drawing's made lists, and the reader's own kept ones.

  MOVIES-AND-TV.md #106. Two of the four *Kept automatically* rows are one
  query each and were frozen at the drawing's numbers on every device —
  `Abandoned` is `status: :dropped` on `Kati.Media.TrackedTitle` and
  `Rewatches` is a `Kati.Media.Watch` carrying a `rewatch_number`. The other
  two are assertions nothing stores: `Wishlist` and `Owned on disc` are things
  a reader says about a title and no column holds, so they are not drawn rather
  than drawn frozen — a card where two rows count the reader's real library and
  two are somebody else's reads as fully real, which is the argument this
  screen's own moduledoc already makes and #75 settled one screen over.

  The made lists are still the fixture, and that is the half no code can fix:
  see the moduledoc's *what this screen is still waiting for*.
  """
  @spec lists() :: map()
  def lists do
    drawn = Sample.lists()

    %{drawn | kept: Kati.Screens.Lists.kept_rows()}
  end

  @doc """
  The two kept lists the store can actually answer, with the reader's counts.

  Both are `Kati.Media`'s own questions asked once. A count of nothing is still
  drawn — `Abandoned · 0` is a true answer about a shelf nobody has dropped
  anything from, unlike the drawing's `3`, and the row is what tells a reader
  the rule exists.
  """
  @spec kept_rows() :: [map()]
  def kept_rows do
    [
      %{
        icon: "replay",
        title: "Rewatches",
        count: Integer.to_string(Kati.Screens.Lists.rewatch_count())
      },
      %{
        icon: "do_not_disturb_on",
        title: "Abandoned",
        count: Integer.to_string(Kati.Screens.Lists.abandoned_count())
      }
    ]
  end

  @doc "How many watches the reader has marked as a rewatch."
  @spec rewatch_count() :: non_neg_integer()
  def rewatch_count do
    Kati.Media.Watch
    |> Ash.read!()
    |> Enum.count(&(is_integer(&1.rewatch_number) and &1.rewatch_number > 1))
  rescue
    _error -> 0
  end

  @doc "How many titles the reader has dropped."
  @spec abandoned_count() :: non_neg_integer()
  def abandoned_count do
    Kati.Media.TrackedTitle
    |> Ash.read!()
    |> Enum.count(&(&1.status == :dropped and not &1.archived))
  rescue
    _error -> 0
  end

  @doc false
  def content(assigns) do
    l = assigns.lists

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {Kati.Screens.Lists.pill_row()}
        {Kati.Screens.Lists.header(l)}
        {Kati.Screens.Lists.waiting(Map.get(assigns, :waiting?, false))}
        {Kati.Screens.Lists.made(l)}
        {UI.eyebrow("Kept automatically")}
        {Kati.Screens.Lists.kept(l)}
      </Column>
    </Scroll>
    """
  end

  # Kati.Screens.Pushed floats the back pill; the drawing gives it a 42pt row
  # with 16pt under it, so this reserves that height rather than redrawing it.
  @doc false
  def pill_row, do: ~MOB"<Spacer size={58} />"

  @doc false
  def header(l) do
    # No tap. MOVIES-AND-TV.md #106: this disc prepended a row literally titled
    # `New list` to the socket, which was lost on back, and pressing it twice
    # gave two identical rows — a control that reports a change nothing kept.
    #
    # Dropped rather than drawn dead is this app's rule everywhere else, and it
    # is not what happens here: the disc is the board's only control and a page
    # with none is a page nobody would press. What is dropped is the LIE. It
    # draws, it is nameable, and it says what it is waiting for — see
    # `handle_tap/2` and the moduledoc's own account of the missing resource.
    tap = {self(), :new_list}

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        <Column weight={1.0}>
          <Text
            text="Lists"
            text_size={28}
            max_font_scale={1.6}
            font_weight="bold"
            letter_spacing={-0.03}
            text_color={:on_surface}
          />
          <Spacer size={5} />
          <Text
            text={l.subtitle}
            font_family="mono"
            text_size={11}
            text_color={Palette.muted()}
            max_lines={1}
          />
        </Column>
        <Spacer size={9} />
        <Box
          width={44}
          height={44}
          corner_radius={22}
          background={Palette.card()}
          shadow={Kati.Theme.shadow_button()}
          align="center"
          on_tap={tap}
        >
          {Kati.UI.symbol("add", size: 21)}
        </Box>
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc false
  def made(l) do
    ~MOB"""
    <Column fill_width={true}>
      {Enum.map(l.made, fn row -> Kati.Screens.Lists.made_row(row) end)}
      <Spacer size={12} />
    </Column>
    """
  end

  @doc false
  def made_row(row) do
    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Palette.card()}
        corner_radius={20}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={13}
        align="center"
      >
        {Kati.Screens.Lists.stack(row.seeds)}
        <Spacer size={14} />
        <Column weight={1.0}>
          <Text
            text={row.title}
            text_size={14}
            font_weight="bold"
            letter_spacing={-0.015}
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={4} />
          <Text
            text={row.count}
            font_family="mono"
            text_size={10.5}
            text_color={Palette.muted()}
            max_lines={1}
          />
        </Column>
        <Spacer size={14} />
        {Kati.Screens.Lists.badge(row.badge)}
      </Row>
      <Spacer size={12} />
    </Column>
    """
  end

  # 38 + 24 + 24 = 86. The Box is the frame and each Row is the offset, because
  # a Box stacks its children at the top-start corner and a Row hugs, so
  # padding_left on the Row is the only thing that moves.
  @doc false
  def stack(seeds) do
    ~MOB"""
    <Box width={86} height={54}>
      {seeds |> Enum.with_index() |> Enum.map(fn {seed, i} -> Kati.Screens.Lists.tile(seed, i * 24) end)}
    </Box>
    """
  end

  # The 2pt ring is a centred 34x50 image inside a 38x54 card-coloured box, not
  # `padding={2}`. `nodeModifier` applies padding OUTSIDE the explicit size —
  # `Modifier.padding(2).width(38)` measures 42 — so padding here would grow
  # the tile and break the 86pt fan. Centring gives the same 2pt on all four
  # sides and keeps the tile the size the drawing gives it.
  @doc false
  def tile(seed, offset) do
    ~MOB"""
    <Row padding_left={offset}>
      <Box
        width={38}
        height={54}
        corner_radius={7}
        background={Palette.card()}
        shadow="0 3 8 -3 #801A1917"
        align="center"
      >
        {Kati.Screens.Lists.tile_art(seed)}
      </Box>
    </Row>
    """
  end

  @doc false
  def tile_art(seed) do
    case Sample.poster(seed) do
      nil ->
        ~MOB"<Box width={34} height={50} corner_radius={5} background={Palette.placeholder()} />"

      src ->
        ~MOB"""
        <Image src={src} width={34} height={50} corner_radius={5} content_mode="fill" />
        """
    end
  end

  # No badge means the list is neither ranked nor shared, and the drawing ends
  # that row with a chevron instead — the badge slot and the affordance slot
  # are the same slot.
  @doc false
  def badge(nil), do: Kati.UI.symbol("chevron_right", size: 19, color: Palette.rail_idle())

  def badge(label) do
    # Mishka's Pill. A pill and not a chip: `RANKED` / `SHARED` is a fact about
    # the list, with no selected state to carry and nothing to tap.
    #
    # The pixels are the Row's. `padding: 0` with `padding_left`/`padding_right`
    # at 9 gives the bridge the same 9/0 edges, and padding is applied before
    # size, so `height: 22` still measures 22. The pill's root is a `Box` that
    # passes `fill_width={false}`, so it hugs (K-17) as the Row did, around a
    # `Row` holding the label beside an empty `Row` where the ✕ would be —
    # zero-wide, and both hug — with `align: :center` centring the pair exactly
    # where `align="center"` centred the lone Text. `max_lines: 1` is the pill's
    # own default and is what this Text already carried.
    MishkaPill.pill(
      label: label,
      background: Palette.cream(),
      color: Palette.gold_text(),
      corner_radius: 11,
      height: 22,
      padding: 0,
      padding_left: 9,
      padding_right: 9,
      align: :center,
      text_size: 10,
      font_weight: :semibold
    )
  end

  @doc false
  def kept(l) do
    last = length(l.kept) - 1

    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={20}
      shadow={Kati.Theme.shadow_card_soft()}
      padding_left={15}
      padding_right={15}
      padding_top={4}
      padding_bottom={4}
    >
      {l.kept
       |> Enum.with_index()
       |> Enum.map(fn {row, i} -> Kati.Screens.Lists.kept_row(row, i < last) end)}
    </Column>
    """
  end

  @doc false
  def kept_row(row, rule?) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_top={14} padding_bottom={14}>
        {Kati.Screens.Lists.kept_icon(row.icon)}
        <Spacer size={13} />
        <Text
          text={row.title}
          text_size={13.5}
          font_weight="semibold"
          text_color={:on_surface}
          weight={1.0}
          max_lines={1}
        />
        <Spacer size={13} />
        <Text
          text={row.count}
          font_family="mono"
          text_size={11.5}
          text_color={Palette.muted()}
          max_lines={1}
        />
      </Row>
      {Kati.Screens.Lists.hairline(rule?)}
    </Column>
    """
  end

  @doc """
  A kept list's leading icon — Mishka's Theme Icon.

  "A themed container around exactly one icon" is the whole of what this Box
  was, so the component is a rename rather than a rewrite. With no `id` to tag
  and the glyph passed as a child, `theme_icon/2` emits one Box whose props map
  is the hand-rolled one key for key — `width: 30, height: 30, align: :center,
  corner_radius: 9, background: #EFECE7` — around the same `Kati.UI.symbol/2`
  Text. `variant: :filled` with a raw `color` is what puts the design's own
  value in the fill rather than one of Mishka's variant tokens, and the glyph
  keeps the colour it was handed, because a caller-supplied icon always does.

  That fill is `Kati.Theme.Palette.paper/0` rather than the literal now — the
  page colour, which is `#EFECE7` in light and reads as a recess punched into
  the card in dark.
  """
  @spec kept_icon(String.t()) :: map()
  def kept_icon(icon) do
    MishkaThemeIcon.theme_icon(
      [variant: :filled, color: Palette.paper(), size: 30, radius: 9],
      [Kati.UI.symbol(icon, size: 17, color: Palette.ink_soft())]
    )
  end

  # Mishka's Separator, at the design's own colour and thickness. `render:
  # :box` is not optional — the default `:divider` is Material 3's antialiased
  # drawLine, NOT the full-width 1dp coloured rectangle this comment used to
  # claim, and it softens the bottom pixel row of every rule in the kept card.
  # See `Kati.Screens.Film.hairline/1` for the measurement.
  @doc false
  def hairline(false), do: ~MOB"<Spacer size={0} />"

  def hairline(true),
    do: MishkaSeparator.separator(color: Palette.hairline(), thickness: 1, render: :box)

  @doc """
  What `+` can honestly do today, which is say why it cannot make a list.

  MOVIES-AND-TV.md #106. It used to prepend a row titled `New list` to this
  screen's assigns: lost the moment you went back, duplicated if you pressed
  twice, and holding nothing either way. A control that reports a change
  nothing kept is worse than one that reports none.

  What it needs is not a column but a **drawing**. `Kati.Lists.List` is a
  resource nobody has designed a name field for — board 12 draws no text entry
  anywhere, and a list created as `New list` with no way to rename it is the
  same lie one step further in. Board 146's *Add to list* is the membership
  route the design DOES draw and it needs a list picker, which is also not
  drawn. Filed as a design gap rather than guessed at here, which is the rule
  `Kati.Screens.ImportSources` states for its own repeated literal: guessing
  would be inventing copy the drawing does not contain.

  So the disc says that, in one line, where the row it used to invent went.
  """
  @impl true
  def handle_tap(:new_list, socket) do
    {:noreply, Mob.Socket.assign(socket, :waiting?, true)}
  end

  def handle_tap(_tag, socket), do: {:noreply, socket}

  @doc """
  The line `+` leaves behind, or nothing.

  `Kati.UI.SettingsList.note/2`'s `info`, which is what every other screen in
  this app uses to say *this is what would happen and here is why it cannot
  yet* — screens 37, 92 and 141 all carry one.
  """
  @spec waiting(boolean()) :: map()
  def waiting(true) do
    assigns = %{
      note:
        Kati.UI.SettingsList.note(
          "info",
          "A hand-made list needs a name, and there is nowhere to type one yet — " <>
            "board 12 draws no field. Titles go into a list from the shelf: select " <>
            "them and press Add to list."
        )
    }

    ~MOB"""
    <Column fill_width={true}>
      {@note}
      <Spacer size={18} />
    </Column>
    """
  end

  def waiting(_quiet), do: ~MOB"<Spacer size={0} />"

  @doc false
  @spec add_list(map()) :: map()
  def add_list(l) do
    row = %{title: "New list", count: "0 titles", badge: nil, seeds: []}

    %{l | made: [row | l.made], subtitle: bump(l.subtitle)}
  end

  # "7 lists · 2 ranked" is a sentence, not a pair of numbers, and only its
  # first number is a count of lists. Parsing the head and putting the rest
  # back keeps the drawing's own copy — including the ranked tally, which
  # adding an unranked list does not change.
  defp bump(subtitle) do
    case Integer.parse(subtitle) do
      {n, rest} -> Integer.to_string(n + 1) <> rest
      :error -> subtitle
    end
  end
end
