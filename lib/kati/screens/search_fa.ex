defmodule Kati.Screens.SearchFa do
  @moduledoc """
  Screen 90 — جست‌وجو, the Persian search, pushed under خانه.

  It mirrors two boards rather than one, and which half came from where is
  worth being exact about. The field, the hits and the recent shelf are screen
  19's page mid-query. The chip row is screen 86's — eight scopes in
  `Kati.Search`'s fixed order rather than 19's four — and it carries counts,
  which 86 withholds on open and 19 types by hand. So this is 19's page drawn
  against screen 88's contract, in Persian.

  ## The four things the caption pins

    * **A matched substring is weight and ink, never orange.** Screen 19 paints
      its match on a `Kati.Theme.Palette.accent_fill/0` patch and this board
      does not, and the reason is not typographic. Orange means *new* or *now*
      everywhere in this design; a substring that matched is neither, it is the
      thing you asked for. So the emphasis is the two properties the run
      already has: 700 against 600 in a row title, where the colour is ink
      either way, and `cream_ink` at 700 against `cream_body` in the note,
      where it is not. The caption says *exactly as in English*, so this is
      19's patch to drop rather than a Persian exception, and it is named here
      instead of being mirrored into a second orange.

      There is a Persian reason it could have failed and does not. Splitting a
      sentence into runs cuts the shaping between them, and in a cursive script
      a cut in the wrong place breaks a join and changes the letterforms. Every
      split this board asks for falls on a space (`گودال بلند`, `فصل گودال`) or
      on a non-joining character (`…گودال`), so not one join is broken. Had the
      match started mid-word this screen would have had to draw the whole line
      unemphasised and say so.

    * **The counts keep their rhythm and lose their face.** The caption asks for
      DM Mono with Persian digits, and `kati_mono.ttf` carries none of
      U+06F0–U+06F9 — `Kati.Screens.Fa`'s moduledoc has the finding and the
      standing trade that follows from it. A mono `۶` is an empty box, so the
      counts are Vazirmatn at the drawing's 10pt in the drawing's three
      colours. The rhythm survives the swap because it never came from the
      face: it comes from the chip's fixed 30 x radius-15 x 13pt-padding
      geometry and the 6pt gap before the number, all of which are the
      drawing's own.

    * **The two annotations are on-screen because a build has to be told.** The
      first is therefore *built* rather than typed —
      `Kati.Search.normalisation_table/0` supplies the four letters, so the
      promise printed on the page and the fold performed in the function cannot
      drift apart. That is the same move `Kati.Search`'s moduledoc makes for
      screen 88: the board renders the rule rather than restating it.

      The second annotation is not built, because there is nothing to build it
      from. Nothing in `Kati.Search.normalise/1` transliterates: a Latin query
      does not currently find a Persian title and a Persian query does not find
      a Latin one. It is drawn as a promise the build has *not* been told to
      keep yet, and saying that here is better than deriving it from a function
      that does something else.

    * **The recent shelf is never translated, which is exactly why it is typed
      here.** `Kati.Search.Sample.recent/0` holds `dentist`, `leaving soon` and
      `miso salmon`, and this board's three chips are those three concepts said
      in Persian — which a *drawing* has to do to be legible, and which the app
      must never do. Deriving these from the English shelf would be performing
      the one operation the rule forbids, so they are this file's own literals:
      the shelf of a reader who searches in Persian, not a translation of
      somebody else's.

  ## Why the frame is `Kati.Screens.Fa.pushed_frame/1`

  Two reasons, and either would be enough.

  `Kati.Screens.Pushed.chrome/2` takes its direction from `Kati.Locale`, the
  app *setting*, and the bridge reads `layout_direction` from the root node
  only — so a Persian mirror rendered while the app is still set to English
  would draw Persian copy in a left-to-right grid, which is the one thing these
  drawings exist to disprove. `Kati.Screens.AlbumDetailFa` records the same
  thing.

  On top of that, this board puts its back pill **in the flow**, at the top of
  the scroll, exactly as screen 19 does and for the reason 19 gives: the shared
  chrome floats a second, differently styled pill over the search field. So
  `chrome/0` here is 19's `back/0` with an `arrow_forward_ios` chevron and a
  Vazirmatn label, and not `Kati.Screens.BookDetailFa.chrome/0` either, whose
  label is pinned to کتابخانه.

  ## What survives from screen 86, and it is less than it looks

  Screen 86 has five public builders and this screen draws four of the same
  things, and yet not one of them can be called. Each is worth naming, because
  the pattern is the same every time and it is a typography failure rather than
  an RTL one:

    * `Kati.Screens.SearchIdle.field/0` draws a **resting** field with a
      placeholder and a `tune` disc; 90 draws a focused one with a query, a
      caret and a `cancel` glyph, and its `Text` carries no `font_family`.
    * `Kati.Screens.SearchIdle.chips/1` goes through `Kati.UI.chip/2`, and
      `MishkaChip` takes its label as a **prop** and paints it in the chip's own
      family while `expand/3` discards children — so a Persian label through
      that door is a row of empty boxes. `Kati.Screens.BookDetailFa.chips/3`
      records the same wall, and `Kati.Screens.Fa`'s moduledoc names a content
      slot on `MishkaChip` as the single upstream ask that would remove it.
    * `Kati.Screens.SearchIdle.recent/0` draws the shelf as `SettingsList`
      **rows**; 90 draws it as chips.
    * `Kati.Screens.SearchIdle.suggestions/0` has no counterpart at all — a
      board mid-query has answers rather than suggestions.
    * `Kati.Screens.SearchIdle.counts_note/0` is `Kati.UI.SettingsList.note/2`,
      a bordered frame over the page with the body in `ink_soft` at 1.55; 90's
      two annotations are **cream** cards at 1.85. Same component underneath —
      see `annotation/1` — at the other board's numbers.

  What *is* reused is everything that carries no text. `Kati.Screens.Search`'s
  `thumb/1` and `gap/0` are called unchanged, and 86's one structural decision —
  eight chips will not fit 402pt, so the row scrolls sideways — is taken with
  it. And the contract is reused rather than re-typed: the chip order is
  `Kati.Search.scopes/0`'s, so a scope added to the search cannot go missing
  from the Persian chip row without `scope_chips/0` raising.

  ## Where this disagrees with screen 19, and each time the frame wins

    * **The chips.** 19 draws four at 32 x radius 16 with 14pt padding; 90
      draws eight at 30 x radius 15 with 13, which is also 86's chip set.
    * **The counts.** 19's are typed and deliberately do not add up — its
      `Sample.chips/0` explains that a chip counts the matched set while the
      group shows what fits. Here they *do* add up: ۳ + ۱ + ۲ is ۶, so `همه`
      is summed in `all_count/0` rather than typed, and there is one literal
      fewer to drift. The per-scope counts stay typed for 19's reason — نمایش
      says ۳ over two drawn rows.
    * **The hit rows.** 19 pads 10 vertically and sets the title at 13.5 over a
      `sub` grey; 90 pads 11 and sets 13 over `muted`, and its chevron points
      `chevron_left` — a row that opens something opens it in the reading
      direction, which in Persian is leftward.
    * **The field shadow.** The drawing gives it one layer at .6 alpha, where
      `Kati.Theme.shadow_search/0` is that layer at .5 with a 1pt contact
      shadow under it. 19 writes the drawn value inline as a hex literal; this
      file takes the token, because the seven shadow strings in this app live
      in `Kati.Theme` and a screen writing its own is the drift. The part of a
      focused field that carries the meaning is the 2pt ink ring, and that is
      exact.

  ## Two labels that look like one and are not

  The chip says `یادداشت` and the group heading says `یادداشت‌ها` — the scope's
  name against the things found in it. The drawing distinguishes them and
  `@headings` keeps them apart, because collapsing both onto one literal would
  make the chip row read as a list of results rather than as a list of places
  to look.

  ## What the drawing prints that this cannot draw

    * **The bold letter runs inside the two annotations.** `ي`, `ی`, `ك` and
      `ک` are set at 700 in the drawing, inside a paragraph that wraps. A `Row`
      does not wrap and this bridge has no inline span, so the annotation is
      one `Text` and the four letters lose their weight. They are all still on
      screen; only the emphasis is gone. The row titles and the note keep
      theirs because those lines do not wrap.
    * **DM Mono on the counts and on the note's eyebrow**, and with it that
      eyebrow's `.14em` tracking. The face is the finding above. The tracking
      goes with it on purpose rather than by omission: `Kati.Screens.Fa` sets
      Persian tracking to 0 on every line, because letter-spacing a cursive
      script pulls the joins apart.
    * **`text-wrap:pretty`** on the annotation paragraphs, which has no
      counterpart in Compose's line breaker.

  ## The `54` in the second annotation is a board number and stays Latin

  It names `.scratch/design/pending/53.html`, drawn as screen 54 — Settings,
  language and region, which is `Kati.Screens.Language`, and whose *Title
  language · Show original titles alongside* row is the switch the sentence
  points at. It stays in Latin digits for `Kati.Screens.AlbumDetailFa`'s reason
  about the letter on an album square: it is a name, not a quantity, and names
  are not translated. Every other digit on this board is a count or a date and
  is Persian.
  """

  use Mob.Screen
  import Mob.Sigil

  alias Kati.Components.MishkaPill
  alias Kati.I18n.Digits
  alias Kati.Screens.BookDetailFa
  alias Kati.Screens.Fa
  alias Kati.Search
  alias Kati.Theme.Palette
  alias Kati.UI

  # The word in the field. Held once because it is also the emphasised run in
  # both hit titles and in the note, and a mirror whose highlight disagreed
  # with its own query would be drawing four things about three.
  @query "گودال"

  @back "خانه"

  # The eight chip labels, keyed by `Kati.Search`'s own scope atoms so the row
  # is built from the contract rather than parallel to it. `:all` is not a
  # scope — it is the absence of one — so it is the one key added here.
  @scope_labels %{
    all: "همه",
    screen: "نمایش",
    books: "کتاب",
    music: "موسیقی",
    calendar: "تقویم",
    meals: "وعده",
    money: "مالی",
    notes: "یادداشت"
  }

  # What the query matched, per scope. Typed for screen 19's reason: a count is
  # of the matched set and not of the rows that fit, which is why نمایش says ۳
  # over two drawn rows.
  @counts %{screen: 3, books: 1, music: 0, calendar: 0, meals: 0, money: 0, notes: 2}

  # The group headings, which are not the chip labels — see the moduledoc.
  @headings %{screen: "نمایش", notes: "یادداشت‌ها"}

  # The two hits, as runs. `lead` and `tail` carry their own spaces rather than
  # being separated by a `Spacer`, because one of the three joins on this board
  # (`…گودال`) has no space at all and a fixed gap would open one the drawing
  # does not have.
  @hits [
    %{
      lead: nil,
      tail: " بلند",
      sub: "سریال · فصل ۲ · در حال تماشا",
      seed: "hollow71"
    },
    %{
      lead: "فصل ",
      tail: nil,
      sub: "قسمت · ۲۵ مرداد دیده شد",
      seed: "hollow71"
    }
  ]

  @note %{
    eyebrow: "یادداشت · ۶ مرداد",
    lead: "…",
    tail: " یک شخصیت است، نه یک مکان."
  }

  # This reader's own queries, typed rather than derived — see the moduledoc on
  # why deriving them from `Kati.Search.Sample.recent/0` would be the one thing
  # the feature promises not to do.
  @recent ["دندان‌پزشک", "به‌زودی حذف", "سالمون میسو"]

  @transliteration "جست‌وجوی لاتین عنوان فارسی آوانویسی‌شده را پیدا می‌کند و برعکس " <>
                     "— همان چیزی که گزینه «نمایش عنوان اصلی» در 54 روشن می‌کند."

  @doc false
  def mount(_params, _session, socket) do
    Kati.Theme.activate()
    {:ok, Mob.Socket.assign(socket, scope: :all, recent: nil)}
  end

  @doc false
  def render(assigns), do: Fa.pushed_frame(content(assigns))

  @doc """
  The page, in the order 90 stacks it.

  Every gap is the drawing's own margin and each section owns the one below it,
  which is why nothing here writes a `Spacer` — a section that stops being
  drawn should take its own spacing with it rather than leaving a hole.
  """
  @spec content(map()) :: map()
  def content(assigns) do
    scope = assigns.scope
    recent = assigns.recent

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {Kati.Screens.SearchFa.chrome()}
        {Kati.Screens.SearchFa.field()}
        {Kati.Screens.SearchFa.chips(scope)}
        {Kati.Screens.SearchFa.hits()}
        {Kati.Screens.SearchFa.note()}
        {Kati.Screens.SearchFa.recent(recent)}
        {Kati.Screens.SearchFa.annotations()}
      </Column>
    </Scroll>
    """
  end

  @doc """
  The back pill, with the chevron pointing the way the reader came from.

  `arrow_forward_ios`, because back is where you came from and in Persian that
  is the right edge — the commonest RTL bug there is, and
  `Kati.Screens.BookDetailFa` records it for screen 69.

  The drawing's asymmetric `0 12px 0 16px` survives as `padding_left={12}` and
  `padding_right={16}`: the bridge maps those two props onto Compose's `start`
  and `end` (`MobBridge.kt:4512`), so under the `rtl` root the 12 lands on the
  chevron's side, which is what optically centres a glyph against text with no
  side bearing.
  """
  @spec chrome() :: map()
  def chrome do
    # The sigil expands `@back` only where a variable named `assigns` is in
    # scope, so a module attribute reaches a helper through one — the same
    # arrangement every other builder in this file uses.
    assigns = %{back: @back}

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Row
          height={44}
          corner_radius={22}
          background={Palette.card()}
          shadow={Kati.Theme.shadow_button()}
          padding_left={12}
          padding_right={16}
          align="center"
          on_tap={{self(), :back}}
        >
          {UI.symbol("arrow_forward_ios", size: 17)}
          <Spacer size={6} />
          {BookDetailFa.fa(@back, 13.5, :on_surface, weight: "semibold")}
        </Row>
        <Spacer weight={1.0} />
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc """
  The focused field: the ink ring, the query, the caret and the clear glyph.

  The 2pt ring is a `border`, not a shadow — `0 0 0 2px` spreads a colour with
  no blur and no offset, which is a border by another name — and it is the part
  of this control that says *focused*, so it is exact. The shadow under it is
  `Kati.Theme.shadow_search/0` rather than the drawing's own single layer; the
  moduledoc says why the token wins over a hex literal in a prop.

  The caret is drawn even though nothing can type into it. Mob has no text
  input at all (#45), so this is a picture of a field mid-query rather than a
  field — the same thing `Kati.Screens.SearchIdle` says about the keyboard on
  its own artboard.
  """
  @spec field() :: map()
  def field do
    assigns = %{query: @query}

    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        height={52}
        corner_radius={26}
        background={Palette.card()}
        border_width={2}
        border_color={Palette.ink()}
        shadow={Kati.Theme.shadow_search()}
        padding_left={18}
        padding_right={18}
        align="center"
      >
        {UI.symbol("search", size: 20)}
        <Spacer size={11} />
        {BookDetailFa.fa(@query, 14.5, :on_surface, weight: "medium")}
        <Spacer size={3} />
        <Box width={2} height={19} background={Palette.accent()} />
        <Spacer weight={1.0} />
        {Kati.Screens.SearchFa.clear()}
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc """
  The ✕ that empties the field, wrapped in a `Row` so it can be tapped.

  A `Row` and not a `Box`: the bridge fills a Box's width whenever `width` is
  not a number (`Kati.Screens.Pushed.back_pill/1` documents the ~30 screens
  that got this wrong), and this node sits after a `Spacer weight={1.0}` where
  filling would push the glyph off the end. A `Row` hugs its content, so the
  hit region is the glyph and nothing else moves.
  """
  @spec clear() :: map()
  def clear do
    ~MOB"""
    <Row align="center" on_tap={{self(), :clear}}>
      {Kati.UI.symbol("cancel", size: 19, color: Palette.rail_idle(), fill: true)}
    </Row>
    """
  end

  @doc """
  The eight scope chips, in `Kati.Search`'s fixed order, each with its count.

  The order is read from `Kati.Search.scopes/0` rather than listed again, so
  the promise screen 88 makes — *Screen · Books · Music · Calendar · Meals ·
  Money · Notes, always, whatever matched* — is one statement rather than two
  that have to agree. `Map.fetch!/2` is deliberate: a scope added to the search
  with no Persian label raises here instead of quietly vanishing from the row,
  which would leave the Persian reader with a shorter contract than the English
  one.
  """
  @spec scope_chips() :: [{atom(), String.t(), non_neg_integer()}]
  def scope_chips do
    scopes =
      Enum.map(Search.scopes(), fn {scope, _label, _fields} ->
        {scope, Map.fetch!(@scope_labels, scope), Map.fetch!(@counts, scope)}
      end)

    [{:all, Map.fetch!(@scope_labels, :all), all_count()} | scopes]
  end

  @doc """
  What `همه` counts, which is every other chip added up.

  Summed rather than typed, and that is a difference from screen 19 rather than
  a disagreement with it: 19's four counts deliberately do not add up, because
  it counts three groups out of a larger matched set. This board's do — ۳ + ۱ +
  ۲ is the ۶ the drawing prints — so the total is derived and cannot drift from
  the parts.
  """
  @spec all_count() :: non_neg_integer()
  def all_count, do: @counts |> Map.values() |> Enum.sum()

  @doc """
  The chip row, scrolling sideways.

  Eight chips do not fit 402pt and the drawing simply clips them
  (`overflow:hidden`); screen 86 answers the same overflow with a horizontal
  `Scroll`, and that is the decision reused here rather than re-argued. Under
  the `rtl` root the `Row` lays out start-to-end, so `همه` sits at the right
  edge and the row runs leftward — no list is reversed by hand.
  """
  @spec chips(atom()) :: map()
  def chips(active) do
    chips =
      scope_chips()
      |> Enum.map(fn {scope, label, count} ->
        Kati.Screens.SearchFa.chip(scope, label, count, scope == active)
      end)
      |> Enum.intersperse(Kati.Screens.Search.gap())

    ~MOB"""
    <Column fill_width={true}>
      <Scroll axis="horizontal">
        <Row>
          {chips}
        </Row>
      </Scroll>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  One counted chip, hand-rolled at the drawing's geometry.

  `Kati.UI.chip/2` cannot draw it: `MishkaChip` takes the label as a prop and
  paints it in the chip's own family, and `expand/3` discards children, so a
  Persian label through that door is a row of empty boxes rather than a
  fallback. `Kati.Screens.Fa`'s moduledoc names a content slot on that
  component as the single upstream ask that would let this go.

  Two of the drawing's three colour decisions are here. A count of nothing takes
  `rail_idle` where a real count takes `muted` — a zero is not a quantity, it is
  the absence of one, and the drawing greys it to say so. And the count inside
  the ink fill is `on_ink_count_soft`, the .65 alpha, not the .6 twin two other
  screens use. The third decision is the shadow, and it is `unlifted/1`'s.
  """
  @spec chip(atom(), String.t(), non_neg_integer(), boolean()) :: map()
  def chip(scope, label, count, on?) do
    assigns = %{
      label: label,
      count: Digits.to_persian(count),
      background: if(on?, do: Palette.ink_fill(), else: Palette.card()),
      colour: if(on?, do: Palette.on_ink(), else: Palette.ink_soft()),
      count_colour: Kati.Screens.SearchFa.count_colour(count, on?),
      tap: {self(), String.to_atom("scope_" <> Atom.to_string(scope))}
    }

    node = ~MOB"""
    <Row
      height={30}
      corner_radius={15}
      background={@background}
      shadow={Kati.Theme.shadow_card_soft()}
      padding_left={13}
      padding_right={13}
      align="center"
      on_tap={@tap}
    >
      {Kati.Screens.BookDetailFa.fa(@label, 12, @colour, weight: "semibold")}
      <Spacer size={6} />
      {Kati.Screens.BookDetailFa.fa(@count, 10, @count_colour)}
    </Row>
    """

    if on?, do: Kati.Screens.SearchFa.unlifted(node), else: node
  end

  @doc """
  The same chip with its shadow prop **removed**, which is what a selected chip
  is.

  The drawing gives the ink-filled chip no shadow and is right to: an ink pill
  is already the strongest mark on the page, and one that floats as well reads
  as two emphases where the design makes one.

  The prop has to be absent rather than `nil`, and that is the part worth
  recording. A `nil` prop is not dropped on its way to the wire —
  `Mob.Renderer`'s catch-all pair passes it through to `:json.encode/1`, which
  writes an atom as its own name, so `shadow: nil` reaches the bridge as the
  **string** `"nil"`. `Kati.Components.MishkaPill` records the same finding for
  `background`. It happens to look right today, because the bridge's shadow
  parser drops any layer it cannot split into five fields (`MobBridge.kt`,
  fence K-08), but that is a mercy rather than a contract. Deleting the key
  does not depend on it.
  """
  @spec unlifted(map()) :: map()
  def unlifted(node), do: %{node | props: Map.delete(node.props, :shadow)}

  @doc """
  Which of the drawing's three count greys a chip's number takes.

  Split out rather than inlined because it is the one place on this screen
  where a *value* changes a colour, and the rule deserves to be readable: on
  ink it is always the soft paper alpha, and on paper a zero recedes further
  than a count does.
  """
  @spec count_colour(non_neg_integer(), boolean()) :: term()
  def count_colour(_count, true), do: Palette.on_ink_count_soft()
  def count_colour(0, false), do: Palette.rail_idle()
  def count_colour(_count, false), do: Palette.muted()

  @doc """
  The نمایش group: its counted eyebrow and the two hit cards.

  The eyebrow takes the accent dash because it is the first group on the page,
  which is the positional rule `Kati.Screens.Search` states — orange means
  *this is the hit*, not *this is Screen*.
  `Kati.Screens.AlbumDetailFa.eyebrow/2` is the Persian eyebrow that already
  takes both dashes, so neither colour is re-typed here.
  """
  @spec hits() :: map()
  def hits do
    rows =
      @hits
      |> Enum.with_index()
      |> Enum.map(fn {hit, index} -> Kati.Screens.SearchFa.hit(hit, index) end)

    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.AlbumDetailFa.eyebrow(Kati.Screens.SearchFa.heading(:screen), :accent)}
      {rows}
      <Spacer size={13} />
    </Column>
    """
  end

  @doc """
  A group heading with its count: `نمایش · ۳`.

  Built from the same `@counts` map the chips read, so a heading cannot say a
  different number from the chip directly above it.
  """
  @spec heading(atom()) :: String.t()
  def heading(scope) do
    Map.fetch!(@headings, scope) <> " · " <> Digits.to_persian(Map.fetch!(@counts, scope))
  end

  @doc """
  One hit: poster, matched title, sub-line, chevron.

  `chevron_left`, because a row that opens something opens it in the reading
  direction and in Persian that is leftward — the back pill's chevron argued in
  the other direction. The poster is `Kati.Screens.Search.thumb/1` unchanged:
  it holds no text, which is the only reason a Persian screen can adopt it as
  it stands, and a poster does not mirror anyway.

  The 9pt gap between the two cards rides on the row rather than between them,
  so the last card carries a gap the group's own `Spacer` then completes to the
  drawing's 22.
  """
  @spec hit(map(), non_neg_integer()) :: map()
  def hit(hit, index) do
    assigns = %{hit: hit, tap: {self(), String.to_atom("hit_" <> Integer.to_string(index))}}

    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Palette.card()}
        corner_radius={18}
        shadow={Kati.Theme.shadow_card_soft()}
        padding_left={13}
        padding_right={13}
        padding_top={11}
        padding_bottom={11}
        align="center"
        on_tap={@tap}
      >
        {Kati.Screens.Search.thumb(@hit)}
        <Spacer size={12} />
        <Column weight={1.0}>
          {Kati.Screens.SearchFa.match_line(@hit, 13, :on_surface, :on_surface)}
          <Spacer size={4} />
          {Kati.Screens.BookDetailFa.fa(@hit.sub, 11.5, Palette.muted())}
        </Column>
        <Spacer size={12} />
        {Kati.UI.symbol("chevron_left", size: 18, color: Palette.rail_idle())}
      </Row>
      <Spacer size={9} />
    </Column>
    """
  end

  @doc """
  A line with the matched substring emphasised, as three runs at most.

  Weight and ink and never orange — see the moduledoc. `base` and `match` are
  separate arguments because in a hit title they are the same colour and only
  the weight moves, while on cream the match takes `cream_ink` out of
  `cream_body`; one argument would have forced the note to pretend its colour
  did not change.

  The runs are laid in a `Row` and carry their own spaces. There is no `Spacer`
  between them: `…گودال` has no space and a fixed gap would invent one, and
  `Kati.Screens.Search.note/1` opens exactly that 4pt gap in the English note
  because English never asked it the question.
  """
  @spec match_line(map(), number(), term(), term()) :: map()
  def match_line(line, size, base, match) do
    assigns = %{
      lead: line.lead,
      tail: line.tail,
      query: @query,
      size: size,
      base: base,
      match: match
    }

    ~MOB"""
    <Row align="center">
      {Kati.Screens.SearchFa.run(@lead, @size, @base, "semibold")}
      {Kati.Screens.BookDetailFa.fa(@query, @size, @match, weight: "bold")}
      {Kati.Screens.SearchFa.run(@tail, @size, @base, "semibold")}
    </Row>
    """
  end

  @doc """
  One unemphasised run of a matched line, or nothing at all.

  `nil` answers a zero-width `Spacer` — the way screen 74 spells absence — so a
  match at the start or the end of a line costs no node rather than an empty
  `Text` that still claims a line box.
  """
  @spec run(String.t() | nil, number(), term(), String.t()) :: map()
  def run(nil, _size, _colour, _weight), do: ~MOB"<Spacer size={0} />"

  def run(text, size, colour, weight),
    do: BookDetailFa.fa(text, size, colour, weight: weight)

  @doc """
  The یادداشت‌ها group: a grey eyebrow and one cream card.

  Cream is this design's ground for the user's own words, and it carries no
  shadow for screen 19's reason — lifting it would make the reader's own note
  compete with the hits above it. The dash is grey because a note about
  something is a footnote to it, and orange is reserved for new or now.

  The eyebrow inside the card is Vazirmatn where the drawing sets DM Mono, and
  loses the drawing's `.14em` with the face: `Kati.Screens.Fa` sets Persian
  tracking to 0 everywhere, because letter-spacing pulls a cursive script's
  joins apart.
  """
  @spec note() :: map()
  def note do
    assigns = %{note: @note}

    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.AlbumDetailFa.eyebrow(Kati.Screens.SearchFa.heading(:notes), :grey)}
      <Column fill_width={true} background={Palette.cream()} corner_radius={20} padding={16}>
        {Kati.Screens.BookDetailFa.fa(@note.eyebrow, 10, Palette.cream_meta())}
        <Spacer size={8} />
        {Kati.Screens.SearchFa.note_body(@note)}
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  The quoted sentence, with the match in `cream_ink` at 700.

  Its own function rather than a call to `Kati.Screens.BookDetailFa.fa/4`,
  because that helper pins `line_height` at 1.4 and this paragraph is set at
  **1.9**. Persian sets tall — Vazirmatn's descenders run under the line and its
  diacritics over it — so a Persian line at a Latin line's leading collides with
  itself, which is the same trade `Kati.Screens.AlbumDetailFa.note/1` records.
  """
  @spec note_body(map()) :: map()
  def note_body(note) do
    assigns = %{note: note, query: @query}

    ~MOB"""
    <Row fill_width={true} align="center">
      <Text
        text={@note.lead}
        font_family="fa"
        text_size={13}
        line_height={1.9}
        text_color={Palette.cream_body()}
        max_lines={1}
      />
      <Text
        text={@query}
        font_family="fa"
        text_size={13}
        font_weight="bold"
        line_height={1.9}
        text_color={Palette.cream_ink()}
        max_lines={1}
      />
      <Text
        text={@note.tail}
        font_family="fa"
        text_size={13}
        line_height={1.9}
        text_color={Palette.cream_body()}
        max_lines={1}
      />
    </Row>
    """
  end

  @doc """
  The اخیر shelf: a grey eyebrow and this reader's last three queries.

  Chunked into declared rows rather than left to wrap, because a `Row` does not
  wrap and no geometry comes back from `render/1` — the same reason
  `Kati.Screens.Search.Sample.recent/0` stores its shelf pre-chunked. Three fit
  402pt at these widths, so there is one row; a fourth query would be a second
  list in `recent_rows/0` and nothing else would change.
  """
  @spec recent(String.t() | nil) :: map()
  def recent(picked) do
    rows =
      Enum.map(recent_rows(), fn row ->
        Kati.Screens.SearchFa.recent_row(row, picked)
      end)

    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.AlbumDetailFa.eyebrow("اخیر", :grey)}
      {rows}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc "The recent queries, chunked into the rows the drawing's `flex-wrap` produces."
  @spec recent_rows() :: [[String.t()]]
  def recent_rows, do: [@recent]

  @doc "One row of the recent shelf, at the drawing's 7pt gap."
  @spec recent_row([String.t()], String.t() | nil) :: map()
  def recent_row(row, picked) do
    chips =
      row
      |> Enum.map(fn label ->
        Kati.Screens.SearchFa.recent_chip(label, label == picked)
      end)
      |> Enum.intersperse(Kati.Screens.Search.gap())

    ~MOB"""
    <Row fill_width={true} align="center">
      {chips}
    </Row>
    """
  end

  @doc """
  One recent query, with the clock that says where it came from.

  Screen 19's `recent_chip/2` geometry to the point — 30 tall at radius 15 on
  `card_settled`, 12 of side padding, a 14pt `history` glyph and a 12pt label —
  and hand-rolled only because the label is Persian and needs a face 19's
  unstyled `Text` does not set.

  Picking one fills it and stops there. It does not rewrite the field, for 19's
  reason: the hits below still describe گودال, and a field that said
  دندان‌پزشک over them would be the screen lying about its own results.

  The tap tag is built from the chip's **index**, not from its label. 19 builds
  `String.to_atom("recent_" <> label)`, and a recent query is by definition
  arbitrary text the user typed — turning it into an atom puts unbounded user
  input into a table that is never collected.
  """
  @spec recent_chip(String.t(), boolean()) :: map()
  def recent_chip(label, on?) do
    index = Enum.find_index(@recent, &(&1 == label))

    assigns = %{
      label: label,
      background: if(on?, do: Palette.ink_fill(), else: Palette.card_settled()),
      colour: if(on?, do: Palette.on_ink(), else: Palette.ink_soft()),
      glyph: if(on?, do: Palette.on_ink_count(), else: Palette.muted()),
      tap: {self(), String.to_atom("recent_" <> Integer.to_string(index))}
    }

    ~MOB"""
    <Row
      height={30}
      corner_radius={15}
      background={@background}
      padding_left={12}
      padding_right={12}
      align="center"
      on_tap={@tap}
    >
      {Kati.UI.symbol("history", size: 14, color: @glyph)}
      <Spacer size={6} />
      {Kati.Screens.BookDetailFa.fa(@label, 12, @colour)}
    </Row>
    """
  end

  @doc """
  The two annotations, 11 apart, at the foot of the page.

  They are the last thing on the board because they are addressed to whoever
  builds the search rather than to whoever uses it — the caption's own reading:
  *the part a build has to be told rather than shown.*
  """
  @spec annotations() :: map()
  def annotations do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.SearchFa.annotation(Kati.Screens.SearchFa.normalisation_note())}
      <Spacer size={11} />
      {Kati.Screens.SearchFa.annotation(Kati.Screens.SearchFa.transliteration_note())}
    </Column>
    """
  end

  @doc """
  What typing `ي` and `ك` finds, built from the table that does the folding.

  The two letter pairs come out of `Kati.Search.normalisation_table/0` rather
  than being typed here, so the promise on the page and the substitution in
  `Kati.Search.normalise/1` are one fact. The three clauses after them —
  half-space, harakat, Arabic and Persian digits — are the table's remaining
  rows said as a sentence rather than interpolated, because `ZWNJ`,
  `U+064B–0652` and `Arabic-Indic` are the names of rules and not things a
  reader can type.
  """
  @spec normalisation_note() :: String.t()
  def normalisation_note do
    [{ya, _, ye, _}, {kaf, _, keh, _} | _rest] = Search.normalisation_table()

    "نوشتن #{ya} واژه‌های با #{ye} را پیدا می‌کند، و #{kaf} واژه‌های با #{keh} را. " <>
      "نیم‌فاصله و اعراب نادیده گرفته می‌شوند و ارقام عربی و فارسی یکی شمرده می‌شوند."
  end

  @doc """
  The transliteration promise, which is typed because nothing performs it yet.

  `Kati.Search.normalise/1` folds letters, digits, half-spaces and harakat and
  transliterates nothing, so a Latin query does not currently find a Persian
  title and the reverse is equally untrue. Deriving this sentence from that
  function would attach a promise to a fold that does not make it. It is drawn
  as the board draws it and named here as outstanding.
  """
  @spec transliteration_note() :: String.t()
  def transliteration_note, do: @transliteration

  @doc """
  One cream annotation card: an `info` glyph on the first line of a paragraph.

  `Kati.Components.MishkaPill`, and it is one of the four components
  `Kati.Screens.Fa` clears for Persian — the paragraph goes in as **children**,
  so this file builds the `Text` and puts `font_family="fa"` on it rather than
  handing a Persian string to a component that would typeset it in Plus Jakarta
  Sans and draw a row of empty boxes.

  Structurally this is `Kati.UI.SettingsList.note/2` at the other board's
  numbers, and its doc carries the reasoning for the two props that make it
  possible: `content_align: :top` keeps the glyph on the paragraph's first line
  instead of floating it to the middle of the block, and
  `content_fill_width: true` gives the paragraph's own `weight` a row wide
  enough to divide. What differs is the frame — cream at radius 20, where 86's
  note is a 1.5pt border over the page — and the body, which is `cream_body` at
  1.85 rather than `ink_soft` at 1.55, because it is set on a warm ground and
  in a script that needs the leading.
  """
  @spec annotation(String.t()) :: map()
  def annotation(text) do
    MishkaPill.pill(
      %{
        background: Palette.cream(),
        corner_radius: 20,
        padding: 16,
        fill_width: true,
        content_align: :top,
        content_fill_width: true,
        leading: UI.symbol("info", size: 18, color: Palette.gold_icon()),
        leading_gap: 11
      },
      [Kati.Screens.SearchFa.annotation_text(text)]
    )
  end

  @doc """
  The annotation paragraph, which restates its own typography.

  `MishkaPill`'s `label` is pinned to one line — a one-line token is what a pill
  *is* — so a note that wraps has to come in as content and carry its size, its
  leading and its colour itself. The `weight={1.0}` is what
  `content_fill_width` exists to feed; without it the paragraph measures at its
  natural width and the card stops being full-bleed.

  This is also the one paragraph on the screen whose emphasis is lost: the
  drawing sets four letters inside it at 700, a `Row` does not wrap, and this
  bridge has no inline span, so the letters are here and their weight is not.
  """
  @spec annotation_text(String.t()) :: map()
  def annotation_text(text) do
    assigns = %{text: text}

    ~MOB"""
    <Text
      text={@text}
      font_family="fa"
      text_size={12.5}
      line_height={1.85}
      text_color={Palette.cream_body()}
      weight={1.0}
    />
    """
  end

  def handle_info({:tap, :back}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}

  # Clearing the field leaves the screen, and that is not a shortcut. There is
  # no text input on this bridge (#45), so an empty field is not a state this
  # page can be in — every pixel below the field is the answer to گودال. The
  # other reading, pushing `Kati.Screens.SearchIdle`, is worse than doing
  # nothing: it is the English screen, and there is no Persian idle board among
  # the 127, so tapping ✕ would change the app's language out from under the
  # reader — the failure `Kati.Screens.Fa` records for the آمار tab's stand-in.
  def handle_info({:tap, :clear}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}

  # One clause for every chip on the page, so a scope added to `Kati.Search` or
  # a fourth recent query is a change to the data and not to a handler. Each tag
  # is matched back against what this screen actually drew rather than converted
  # on trust, so a tag from anywhere else leaves the screen exactly as it was
  # instead of raising — Mob catches nothing in a tap handler.
  def handle_info({:tap, tag}, socket) do
    case Atom.to_string(tag) do
      "scope_" <> id ->
        {:noreply, Kati.Screens.SearchFa.select_scope(id, socket)}

      "recent_" <> index ->
        {:noreply, Kati.Screens.SearchFa.pick_recent(index, socket)}

      # Both hits are the same series in Persian — a title and one of its
      # episodes — so both open `Kati.Screens.SeriesFa` rather than its English
      # sibling. A mirror that pushed an LTR screen would change the reader's
      # language mid-navigation.
      "hit_" <> _index ->
        {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.SeriesFa)}

      _other ->
        {:noreply, socket}
    end
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  @doc """
  Narrow the page to one scope, or leave it alone for a tag that names none.

  The lookup goes through `scope_chips/0` rather than
  `String.to_existing_atom/1`, so the set of tags this accepts is exactly the
  set of chips it drew — a scope atom that exists elsewhere in the app is not a
  chip on this screen.
  """
  @spec select_scope(String.t(), map()) :: map()
  def select_scope(id, socket) do
    case Enum.find(scope_chips(), fn {scope, _label, _count} -> Atom.to_string(scope) == id end) do
      {scope, _label, _count} -> Mob.Socket.assign(socket, :scope, scope)
      nil -> socket
    end
  end

  @doc """
  Fill a recent chip, or empty the one already filled.

  A second tap puts it back, because the shelf is a shortcut and not a mode:
  there has to be a way out of it. The index is parsed rather than trusted, so a
  malformed tag returns the socket untouched instead of raising inside a tap
  handler, which Mob does not catch.
  """
  @spec pick_recent(String.t(), map()) :: map()
  def pick_recent(index, socket) do
    with {n, ""} <- Integer.parse(index),
         label when is_binary(label) <- Enum.at(@recent, n) do
      picked = if socket.assigns.recent == label, do: nil, else: label
      Mob.Socket.assign(socket, :recent, picked)
    else
      _other -> socket
    end
  end
end
