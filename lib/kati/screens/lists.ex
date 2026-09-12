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

  A made row opens the list it names — `made_row/1` carries
  `open_list_<id>` for any row with an id, and `nil` for one without, which is
  the drawn page. This section used to say the rows are *left untappable on
  purpose*, because their chevrons pointed at a list-detail screen the design
  had never drawn; board 331 drew it and `Kati.Screens.ListDetail` is it.

  ## What this screen reads

  Not a missing column and no longer a missing resource. `Kati.Lists.List`,
  `Kati.Lists.Membership` and `Kati.Lists.Shelf` are written, migrated and
  backed up; the membership table holds three nullable FKs, so a list holds a
  film, a series, a book or an album (board 332). This section used to say the
  resource *is not written* and that its chevrons pointed at a board that did
  not exist, and both were true when they were written.

  What the store answers now:

    * **the made lists themselves** — name, `ranked` and `shared` badges, and a
      `name_key` so two lists called `Rainy Sunday` are one list somebody made
      twice.
    * **membership** — the count and the fanned stack, which is the first three
      memberships' `Kati.Media.CachedTitle.poster_path` in the list's own
      order, so a ranked list fans its top three.
    * **`7 lists · 2 ranked`** — counted off the table.
    * **the kept lists** — `Rewatches` and `Abandoned` are one query each.
      `Wishlist` and `Owned on disc` are assertions a reader makes and no
      column holds, so they are not drawn rather than drawn frozen; board 12's
      own two frozen figures are on `DesignLiterals.retired_lines/0`.

  ## The three surfaces the design owed, and what came of them

  MOVIES-AND-TV.md #106 asked for three drawings, filed as
  [mishka-group/kati#99](https://github.com/mishka-group/kati/issues/99). The
  `D-65` wave delivered all three on 7 September and they are built:

    * **somewhere to name a list** — board 335's naming field, one grammar for
      creating and renaming, with one failure rule.
    * **a list picker** — board 333, `Kati.Screens.AddToList`, a sheet over the
      page you are on rather than a trip to the index.
    * **a list detail** — boards 330-332, `Kati.Screens.ListDetail`, with its ⋯
      menu, its long-press *Remove* and its undo bar.

  Each has a Persian mirror (336, 337). The chevrons that were removed for
  pointing nowhere point at 331 now.

  What HAS shipped is everything the store can answer: two of the four *Kept
  automatically* rows are the reader's own counts, the two that are assertions
  nothing holds are not drawn, and `+` says what it is waiting for instead of
  reporting a change nothing kept.
  """
  use Kati.Screens.Pushed, back: "Library"
  use Gettext, backend: Kati.Gettext

  alias Kati.Components.MishkaPill
  alias Kati.Components.MishkaSeparator
  alias Kati.Components.MishkaThemeIcon
  alias Kati.Screens.Lists.Sample
  alias Kati.Theme.Palette
  alias Kati.UI

  @impl true
  # No params. It read `:adding` — board 146's selection — until board 333 moved
  # that route onto `Kati.Screens.AddToList`, a sheet over the page you are on.
  def load(socket) do
    socket
    |> Mob.Socket.assign(:lists, Kati.Screens.Lists.lists())
    |> Mob.Socket.assign(:name, "")
    |> Mob.Socket.assign(:naming?, false)
    |> Mob.Socket.assign(:name_epoch, 0)
    |> Mob.Socket.assign(:save_error, nil)
  end

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
    page = Kati.Lists.Shelf.page()

    # Not the board. Screen 03 falls back to its drawing because a shelf has a
    # drawn empty state to fall back TO — board 27's card — and 12 has none, so
    # falling back here would show three lists nobody made to somebody who has
    # made none. That is the defect #75 fixed on screen 92 and #58 on screen
    # 15. `empty_card/0` is the state instead, and it says the one thing that
    # fixes it.
    page
  end

  @doc """
  The two kept lists the store can actually answer, with the reader's counts.

  Both are `Kati.Media`'s own questions asked once. A count of nothing is still
  drawn — `Abandoned · 0` is a true answer about a shelf nobody has dropped
  anything from, unlike the drawing's `3`, and the row is what tells a reader
  the rule exists.
  """
  @spec kept_rows() :: [map()]
  defdelegate kept_rows(), to: Kati.Lists.Shelf, as: :kept

  @doc "How many watches the reader has marked as a rewatch."
  @spec rewatch_count() :: non_neg_integer()
  defdelegate rewatch_count(), to: Kati.Lists.Shelf, as: :rewatches

  @doc "How many titles the reader has dropped."
  @spec abandoned_count() :: non_neg_integer()
  defdelegate abandoned_count(), to: Kati.Lists.Shelf, as: :abandoned

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
        {Kati.Screens.Lists.name_field(assigns)}
        {Kati.Screens.Lists.made(l)}
        {UI.eyebrow(gettext("Kept automatically"))}
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

    # The 28pt title is `Kati.Locale.tracking/1` rather than a flat `-0.03`, and
    # it carries `max_lines` where it carried none. Both are mishka-group/kati#103
    # rules and both are about the same word: `فهرست‌ها` is one Arabic-script
    # word, tracking prises apart the joins that make it one, and a heading with
    # no line cap wraps under the 44pt disc the moment the Persian runs longer
    # than the English. The subtitle beside it was already asking
    # `Kati.Locale.mono_face/0`, because `kati_mono.ttf` has no Persian glyph and
    # `7 lists · 2 ranked` comes off `Kati.Lists.Shelf.subtitle/1` translated.
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        <Column weight={1.0}>
          <Text
            text={gettext("Lists")}
            text_size={28}
            max_font_scale={1.6}
            font_weight="bold"
            letter_spacing={Kati.Locale.tracking(-0.03)}
            max_lines={1}
            text_color={:on_surface}
          />
          <Spacer size={5} />
          <Text
            text={l.subtitle}
            font_family={Kati.Locale.mono_face()}
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
  def made(%{made: []}) do
    # `:name_this_one`, not the disc's own `:new_list`: two nodes may not share
    # an `accessibility_id` — `onNodeWithTag` throws on the second match — and
    # both are drawn at once on an empty page. One action, two doors, two names.
    #
    # The copy comes in as assigns rather than inline in the sigil so the body
    # sentence can be wrapped and read: a sigil's contents are opaque to
    # `mix format`, so a `gettext/1` around a 90-character line stays one
    # 120-character line forever. The heading is deliberately the SAME msgid
    # `Kati.Lists.Shelf.subtitle/1` answers an empty shelf with — one card and
    # one header line saying one thing, and one entry in the catalogue.
    assigns = %{
      tap: {self(), :name_this_one},
      heading: gettext("No lists yet"),
      body:
        gettext(
          "A list is yours to name — press + and call it something. " <>
            "Titles go in from your shelf."
        )
    }

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={17}
        on_tap={@tap}
      >
        <Row fill_width={true} align="center">
          <Spacer weight={1.0} />
          <Box width={48} height={48} corner_radius={15} background={Palette.paper()} align="center">
            {UI.symbol("bookmarks", size: 22, color: Palette.rail_idle())}
          </Box>
          <Spacer weight={1.0} />
        </Row>
        <Spacer size={13} />
        <Text
          text={@heading}
          text_size={14.5}
          font_weight="bold"
          letter_spacing={Kati.Locale.tracking(-0.02)}
          text_color={:on_surface}
          text_align="center"
        />
        <Spacer size={7} />
        <Text
          text={@body}
          text_size={12.5}
          line_height={Kati.Locale.leading(1.55)}
          text_color={Palette.sub()}
          text_align="center"
        />
      </Column>
      <Spacer size={12} />
    </Column>
    """
  end

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
    # A row opens the list it names. It used to carry a second verb — arriving
    # from 146 with a selection in hand swapped every row from *open it* to *add
    # to it*, announced by a note and by nothing else — and board 333 retired
    # that: a title is put in a list from a SHEET over the page you are on, not
    # by a page whose rows quietly change meaning. `Kati.Screens.AddToList` is
    # where the selection goes now.
    #
    # `nil` over the board's own three, which belong to nobody: not tappable
    # rather than opening somebody else's.
    tap = if Map.get(row, :id), do: {self(), String.to_atom("open_list_" <> row.id)}

    assigns = %{tap: tap}

    # `Kati.Locale.tracking/1` on the name and not a flat `-0.015`. A list's name
    # is the one string on this page the READER wrote, so it is the one most
    # likely to be Persian whatever the interface language is — and tracking
    # prises apart the joins that make an Arabic-script word one word. The count
    # under it was already asking `Kati.Locale.mono_face/0`, which is the arity-0
    # one on purpose: `14 titles` is always in the reader's own script, so the
    # question is the READER's language and not this string's.
    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Palette.card()}
        corner_radius={20}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={13}
        align="center"
        on_tap={@tap}
      >
        {Kati.Screens.Lists.stack(row.seeds)}
        <Spacer size={14} />
        <Column weight={1.0}>
          <Text
            text={row.title}
            text_size={14}
            font_weight="bold"
            letter_spacing={Kati.Locale.tracking(-0.015)}
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={4} />
          <Text
            text={row.count}
            font_family={Kati.Locale.mono_face()}
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
  #
  # `Kati.Locale.forward_chevron/0` and not the literal `chevron_right`: this row
  # OPENS `Kati.Screens.ListDetail`, the chevron is the picture of that, and a
  # picture is the one thing `layout_direction` cannot mirror — Material Symbols
  # are text in a font. It points `chevron_left` under `:fa`, which reads wrong
  # in a diff and right on a phone.
  @doc false
  def badge(nil),
    do: Kati.UI.symbol(Kati.Locale.forward_chevron(), size: 19, color: Palette.rail_idle())

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
      label: Kati.Screens.Lists.badge_word(label),
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

  @doc """
  A badge as the word the pill prints.

      iex> Kati.Screens.Lists.badge_word("ranked")
      "ranked"

  **The pill was drawing a key.** `Kati.Lists.Shelf.badge/1` answers the strings
  `"ranked"` and `"shared"`, and they are identifiers rather than copy —
  `Kati.Lists.Shelf.subtitle/1` counts the ranked lists by comparing against
  `"ranked"`, so translating them at the source would make that comparison fail
  under `:fa` and report `0 ranked` on a shelf that has two. Board 12's badge
  therefore read `ranked` in Latin on a Persian page — and the `:fa` audit did
  not see it, because a badge is only drawn for a list somebody has made and the
  audit renders an empty store. A pill that draws a key is exactly the thing a
  sweep over rendered text cannot find.

  So the key is translated where it is DRAWN and not where it is decided, which
  is the rule `Kati.Screens.AddToList.count_line/1` already states one screen
  over. `badge_word/1` is deliberately a second copy of
  `Kati.Screens.AddToList.badge_word/1` rather than a call into it: an index and
  a sheet over some other page share a vocabulary, not a dependency, and both
  call sites point at the same two msgids either way.

  An unknown key answers itself, so a badge `Kati.Lists.Shelf` learns to emit
  tomorrow draws its own word rather than nothing.
  """
  @spec badge_word(String.t()) :: String.t()
  def badge_word("ranked"), do: gettext("ranked")
  def badge_word("shared"), do: gettext("shared")
  def badge_word(other), do: other

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
          font_family={Kati.Locale.mono_face()}
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
  The field `+` opens, where the list is named.

  Board 12 draws no text entry — it draws three lists that already have names —
  so this is a departure, made deliberately and recorded here: the alternative
  was a `+` that creates `New list` with no way to rename it, which is the same
  lie one step further in. `Kati.UI.SettingsList`'s own field geometry, so it is
  the app's field and not a new one.

  It appears on the press and not before, which is why the board is unchanged
  for a reader who has not pressed anything.
  """
  @spec name_field(map()) :: map()
  def name_field(assigns) do
    if Map.get(assigns, :naming?, false) do
      inner = %{
        name: Map.get(assigns, :name, ""),
        epoch: Map.get(assigns, :name_epoch, 0),
        on_change: {self(), :list_name},
        on_submit: {self(), :save_list},
        save: {self(), :save_list},
        placeholder: gettext("Name this list"),
        # `pgettext/2` for two words. `mix gettext.merge` fuzzy-matches a new
        # msgid against the catalogue, and `Make it and add` — board 333's own
        # pill, three words longer — is close enough to claim it and arrive
        # already translated to the wrong sentence. A context is the only thing
        # that makes the two entries separate rows rather than one guess.
        make: pgettext("make a list", "Make it"),
        error: Kati.UI.notice(Map.get(assigns, :save_error))
      }

      assigns = inner

      ~MOB"""
      <Column fill_width={true}>
        {@error}
        <Row fill_width={true} align="center">
          <Row
            weight={1.0}
            height={48}
            corner_radius={14}
            background={Kati.Theme.Palette.card()}
            shadow={Kati.Theme.shadow_card_soft()}
            padding_left={15}
            padding_right={15}
            align="center"
          >
            <TextField
              value={@name}
              placeholder={@placeholder}
              return_key="done"
              weight={1.0}
              accessibility_id="list_name"
              on_change={@on_change}
              on_submit={@on_submit}
              value_epoch={@epoch}
            />
          </Row>
          <Spacer size={9} />
          {Kati.UI.SettingsList.action_pill(@make, @save)}
        </Row>
        <Spacer size={18} />
      </Column>
      """
    else
      ~MOB"<Spacer size={0} />"
    end
  end

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
  def handle_tap(tag, socket) when tag in [:new_list, :name_this_one] do
    {:noreply,
     socket
     |> Mob.Socket.assign(:naming?, not Map.get(socket.assigns, :naming?, false))
     |> Mob.Socket.assign(:save_error, nil)}
  end

  # Make the list the field names, and put it on the page.
  #
  # Board 335 changed what a taken name does. `Kati.Lists.Shelf.create/1` used
  # to answer `{:ok, existing}` and write nothing, which was *indistinguishable
  # from making one*: a reader who thought they had two lists called `Rainy
  # Sunday` had no way to learn they had one. It answers `{:exists, list}` now
  # and the page says so, naming the count — *"It has 3 titles. Nothing was
  # made."*
  #
  # Every other refusal is the one every write in this app gives,
  # `Kati.Write.message/1`, so a store that cannot be reached says so instead of
  # looking like a press that missed.
  def handle_tap(:save_list, socket) do
    case Kati.Lists.Shelf.create(Map.get(socket.assigns, :name, "")) do
      {:ok, _list} ->
        {:noreply, Kati.Screens.Lists.named(socket)}

      {:exists, list} ->
        {:noreply,
         Mob.Socket.assign(
           socket,
           :save_error,
           Kati.Screens.Lists.taken_line(list)
         )}

      error ->
        {:noreply, Mob.Socket.assign(socket, :save_error, Kati.Write.message(error))}
    end
  end

  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "open_list_" <> id ->
        {:noreply,
         Mob.Socket.push_screen(socket, Kati.Screens.ListDetail, %{id: id, back: "Lists"})}

      _other ->
        {:noreply, socket}
    end
  end

  @doc """
  The sentence board 335 puts under a name that is already a list.

      iex> Kati.Screens.Lists.taken_line(%{name: "Rainy Sunday", id: nil})
      "Rainy Sunday already exists. Nothing was made — open it from the list above."

  One msgid with the name interpolated, where this was a concatenation. A
  sentence assembled with `<>` is a sentence whose word order is English's, and
  Persian puts the verb last — the catalogue cannot move a fragment it never
  sees. The name is the reader's own and goes in unwrapped, which is the same
  answer `Kati.Screens.ListDetail` gives for `Delete %{title}?`: a list called
  `Rainy Sunday` and one called `یکشنبه بارانی` are both names somebody typed,
  and neither is a Latin RUN inside a Persian sentence in the sense
  `Kati.Locale.ltr/1` exists for.
  """
  @spec taken_line(map()) :: String.t()
  def taken_line(list) do
    gettext("%{name} already exists. Nothing was made — open it from the list above.",
      name: list.name
    )
  end

  @doc false
  @spec named(Mob.Socket.t()) :: Mob.Socket.t()
  def named(socket) do
    socket
    |> Mob.Socket.assign(:lists, Kati.Screens.Lists.lists())
    |> Mob.Socket.assign(:name, "")
    # `K-46`: the bridge ignores a `value` for a field it has already drawn
    # unless the epoch moves.
    |> Mob.Socket.assign(:name_epoch, Map.get(socket.assigns, :name_epoch, 0) + 1)
    |> Mob.Socket.assign(:naming?, false)
    |> Mob.Socket.assign(:save_error, nil)
  end

  @doc false
  def blank, do: ~MOB"<Spacer size={0} />"

  @doc false
  @impl true
  def handle_info({:change, :list_name, typed}, socket) when is_binary(typed) do
    {:noreply,
     socket
     |> Mob.Socket.assign(:name, typed)
     |> Mob.Socket.assign(:save_error, nil)}
  end

  # The keyboard's own key. A submit is not a tap — `mob_send_submit/1` sends
  # `{:submit, tag}` — so `handle_tap/2` never sees it.
  def handle_info({:submit, :save_list}, socket),
    do: Kati.Screens.Lists.handle_tap(:save_list, socket)

  # Coming back from a list: the counts and the fans have moved, and the page
  # was still showing what it mounted with. `Kati.Screens.Resume` is what
  # announces it, and screens 08 and 02 answer the same message the same way.
  def handle_info({:kati, :resumed, _payload}, socket) do
    {:noreply, Mob.Socket.assign(socket, :lists, Kati.Screens.Lists.lists())}
  end

  def handle_info(message, socket), do: super(message, socket)

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
