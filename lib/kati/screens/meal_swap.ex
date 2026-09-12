defmodule Kati.Screens.MealSwap do
  @moduledoc """
  Screen 46 — swap a meal.

  Built to `test/design/screens/46.html`. The screen is an argument in
  three parts, top to bottom: what is being replaced, what could replace it
  and by how much it differs, and what the day looks like afterwards. The
  design's caption puts it plainly — *"A swap is only useful if it tells you
  what it costs"* — so the delta is never buried: it sits at the end of every
  candidate row, in green or red, before anything is committed.

  Its own close button rather than `Kati.Screens.Pushed`, for the same reason
  screen 06 has one: the drawing gives this screen a single dismissal, and the
  pushed chrome would draw a second one over the centred title. #45 has this
  becoming a native bottom sheet along with 06 and 18; until then it pushes,
  which is the same information in a different container.

  ## Where this diverges from the drawing

    * **The selected candidate's `outline: 2px solid` is a 2pt border.** It is
      `outline-offset:-2px` in the drawing, which is a border drawn inside the
      box — the same thing, said in CSS that does not disturb layout.
    * **The two footer buttons are sized by weight, not by content.** `Swap
      just today` is `flex:1` and `Every week` hugs its text at `padding:0
      18px`; nothing measures text here, so the hugging one is a Row with that
      padding and the flexible one takes the rest.

  No dock, so the frame ends at 40 rather than 132.

  ## The copy, in both scripts

  Every word on this page is `Kati.Meals.SampleSwap`'s — the fixture is a
  transcription of board 46 — and the fixture holds English literals. They are
  translated where they are **drawn**, through `copy/1`, rather than in the
  fixture: `Kati.Screens.MealReminders.copy/1` is the same function for the
  same reason, and `Kati.Screens.MealLibrary`'s moduledoc states the rule from
  the other side — the fixture's `Dinner 9` reads `شام ۹` without the fixture
  changing at all. It is the only arrangement available here anyway, since
  `Kati.Meals.SampleSwap` is drawn by this screen and owned by nobody on it.

  The two lines with **numbers** in them cannot go that way and are built in
  the reader's language where they are composed — `replaced_macros/1`,
  `candidate_macros/1` and `delta_label/1`, all reached from `swap/1`, which
  `mount/3` calls after `Kati.Locale.activate/0`. A number cannot be recovered
  from a finished sentence, so a line that interpolates one has to be
  translated at the point it is assembled. `copy/1` still carries a clause for
  each of the fixture's seven — four macro lines and three deltas — and every
  one of those clauses calls the same builder with the drawing's own figures,
  so the drawn page and a real one are one sentence with different numbers in
  it. `copy/1` is idempotent on its own output, which is what makes it safe to
  run over a row this screen built itself.
  """
  # Not `Kati.Screens.Pushed`: this screen dismisses with its own close
  # button, and the drawing has exactly one dismissal.
  use Mob.Screen
  use Gettext, backend: Kati.Gettext
  import Mob.Sigil

  alias Kati.Components.MishkaActionIcon
  alias Kati.Components.MishkaPill
  require Ash.Query

  alias Kati.Meals.Nutrition
  alias Kati.Meals.SampleSwap, as: Sample
  alias Kati.Theme
  alias Kati.Theme.Palette

  def mount(params, _session, socket) do
    Mob.Theme.set(Kati.Theme.current())
    # Resolves the stored locale into THIS process. `Gettext.put_locale/2`
    # snapshots into the calling process exactly as `Mob.Theme.set/1` does,
    # and a screen is its own process — see `Kati.Locale.activate/0`.
    Kati.Locale.activate()
    swap = Kati.Screens.MealSwap.swap(params)

    {:ok,
     socket
     |> Mob.Socket.assign(:candidates, swap.candidates)
     |> Mob.Socket.assign(:replacing, swap.replacing)
     |> Mob.Socket.assign(:slot_id, swap.slot_id)
     |> Mob.Socket.assign(:picked, swap.picked)}
  end

  @doc """
  The swap this screen is a swap OF when the push named nothing: the store's.

  Screen 43 hands the slot over the way screen 86 hands a query to 19 — a key
  in `Mob.State` — and this is the reader of that key. With no slot, or no
  plan, it is `Kati.Meals.SampleSwap`'s drawing, which is what the gallery
  shows and what the design sweeps compare against.
  """
  @spec swap() :: map()
  def swap, do: swap(%{})

  @doc """
  The swap this screen is a swap OF, given the push's own params.

  `%{slot_id: id}` is what screen 45's `swap_horiz` disc pushes — the meal that
  was on screen — rather than whatever `Mob.State` still held from an earlier
  tap somewhere else. Screen 43 still hands its slot over through the store, so
  a push that names nothing is exactly `handed_over/0`, and `swap/0` is that
  call unchanged.

  The two doors are ordered, and the order is the point: the push is written and
  read inside one navigation and cannot be stale, the store can.

  ## The candidates are the meal library, ranked by what the swap costs

  The design's caption is the specification: *"A swap is only useful if it
  tells you what it costs."* So a candidate is any other recipe you keep, and
  the delta is the difference in energy between it and the meal being replaced
  — computed here rather than typed, which is what makes the number true of the
  two rows it sits between.

  Ranked by absolute distance, nearest first, and capped at three because that
  is what the board draws. `BEST` goes on the first and only because it IS the
  closest; the drawing does not decorate the others.
  """
  @spec swap(map() | nil) :: map()
  def swap(params) do
    with slot_id when is_binary(slot_id) <- named(params),
         %{} = slot <- slot_for(slot_id),
         %Kati.Meals.Recipe{} = recipe <- slot.recipe do
      figures = Nutrition.scale(recipe_figures(recipe), slot.portion_milli)

      %{
        slot_id: slot.id,
        replacing: %{
          # The eyebrow as the SCREEN spells it, not as it is drawn — `copy/1`
          # at the render is where it becomes a word, which is the same split
          # `Kati.Screens.MealLibrary.shaped/2` makes for its slot name. A
          # fixed phrase is translated once, where it is drawn, and a real row
          # and a drawn one then reach the catalogue by the same door.
          label: "Replacing",
          title: recipe.title,
          macros: replaced_macros(figures),
          seed: recipe.photo_seed
        },
        candidates: candidates_for(recipe, figures),
        picked: nil
      }
    else
      _drawn ->
        %{
          slot_id: nil,
          replacing: Sample.replacing(),
          candidates: Sample.candidates(),
          picked: nil
        }
    end
  end

  @doc """
  The slot screen 43 handed over. See `swap/0`.

  `catch :exit` as well as `rescue`, and the difference is not academic.
  `Mob.State` is a GenServer: when it is not running, a call to it **exits**
  rather than raising, and `rescue` does not catch an exit. On the host that is
  a test whose harness has already torn the store down; on a device it is the
  window between the BEAM starting and `Mob.State` opening its table, which is
  a window a screen can be rendered in.
  """
  @spec handed_over() :: String.t() | nil
  def handed_over do
    case Mob.State.get(:kati_swap_slot) do
      id when is_binary(id) and id != "" -> id
      _nothing -> nil
    end
  rescue
    _error -> nil
  catch
    :exit, _reason -> nil
  end

  @doc "Put a slot where this screen will look for it. See `handed_over/0`."
  @spec hand_over(String.t()) :: :ok
  def hand_over(slot_id) do
    Mob.State.put(:kati_swap_slot, slot_id)
    :ok
  rescue
    _error -> :ok
  catch
    :exit, _reason -> :ok
  end

  @doc """
  The params that name a slot to this screen, from a screen 45 meal.

  Here rather than at screen 45 so `:slot_id` is spelled once on this side of
  the push, the way `Kati.Screens.MealEdit.params_for/1` spells `:meal_id` once
  on its own. A drawn meal has no slot id and yields `%{}`, which sends this
  screen back to `handed_over/0` — the door it has always had.
  """
  @spec params_for(map() | nil) :: map()
  def params_for(%{slot_id: id}) when is_binary(id) and id != "", do: %{slot_id: id}
  def params_for(_meal), do: %{}

  # The push's own slot, and the store only when the push named none. See
  # `swap/1` for why that order and not the other.
  defp named(params) do
    case Map.get(params || %{}, :slot_id) do
      id when is_binary(id) and id != "" -> id
      _none -> handed_over()
    end
  end

  defp slot_for(id) do
    Kati.Meals.MealPlanSlot
    |> Ash.Query.filter(id == ^id)
    |> Ash.Query.load(:recipe)
    |> Ash.read_one()
    |> case do
      {:ok, slot} -> slot
      _error -> nil
    end
  rescue
    _error -> nil
  end

  defp candidates_for(replacing, figures) do
    Kati.Meals.Recipe
    |> Ash.read!()
    |> Enum.reject(&(&1.id == replacing.id))
    |> Enum.map(fn recipe ->
      theirs = Nutrition.scale(recipe_figures(recipe), Nutrition.one_portion())
      {abs(theirs.kcal - figures.kcal), recipe, theirs}
    end)
    |> Enum.sort_by(&elem(&1, 0))
    |> Enum.take(3)
    |> Enum.with_index()
    |> Enum.map(fn {{_distance, recipe, theirs}, i} ->
      %{
        id: recipe.id,
        title: recipe.title,
        # `BEST` as the screen spells it, for `copy/1` to draw — see the
        # `:label` above, and `Kati.MealSwapTest`, which reads this key off the
        # socket and is asking which candidate is badged rather than what the
        # badge says.
        badge: if(i == 0, do: "BEST"),
        macros: candidate_macros(theirs),
        delta: delta_label(theirs.kcal - figures.kcal),
        delta_color: if(theirs.kcal <= figures.kcal, do: Sample.green(), else: Sample.red()),
        selected?: i == 0,
        seed: recipe.photo_seed
      }
    end)
  rescue
    _error -> []
  end

  # The drawing writes a signed number with a MINUS SIGN, not a hyphen — the
  # same character `Kati.Meals.SampleSwap` types, and the reason the two agree
  # is that this is where a real delta has to look like the drawn one.
  #
  # `%{count} kcal` is the meals screens' own entry rather than three new ones:
  # `Kati.Screens.Health`, `Kati.Screens.MealLibrary`, `Kati.Screens.MealsDay`
  # and `Kati.Screens.MealsToday` all draw a figure through it, and a delta is
  # a number of calories like any other. One page naming them کالری while
  # another named them something else is the disagreement a shared msgid
  # prevents.
  defp delta_label(0), do: pgettext("a swap that costs the day nothing", "same")

  defp delta_label(diff) when diff < 0,
    do: gettext("%{count} kcal", count: signed("−", abs(diff)))

  defp delta_label(diff), do: gettext("%{count} kcal", count: signed("+", diff))

  # The SIGN goes inside the interpolated value and through `Kati.Locale.ltr/1`,
  # which is the move `Kati.Screens.MealLibrary.kcal_line/2` makes for its `~`
  # and for the same reason. `+` and `−` are bidi-NEUTRAL: a bare one in front
  # of a figure on a Persian page takes the PARAGRAPH's direction and is laid
  # out at the far end of the number — `۱۵− کالری`, which reads as a mark
  # against the word rather than against the figure it qualifies. The isolate
  # resolves it against the digits instead, and is a no-op under `:en`, where
  # this still answers `−15 kcal` byte for byte.
  defp signed(sign, figure), do: Kati.Locale.ltr(sign <> Kati.Locale.number(figure))

  # The two macro lines the drawing writes, and they differ only in the case of
  # the unit: the card being replaced carries `620 KCAL · 52P 64C 17F` and a
  # candidate row `605 kcal · 48P 61C 16F`.
  #
  # Two msgids rather than one and a `String.downcase/1`, which is what stood
  # here. Case is a LATIN property — Persian has none, so both answer
  # `۶۲۰ کالری · ۵۲پ ۶۴ک ۱۷چ` and the second entry costs the translator
  # nothing — and downcasing the FINISHED line also lowercased the macro
  # letters, so a candidate built from a real recipe drew `48p 61c 16f` where
  # the board draws `48P 61C 16F`. The lowercase msgid is
  # `Kati.Screens.Plans.targets_line/1`'s own, shared rather than opened a
  # second time; its comment carries the argument for why the macro letters sit
  # INSIDE the msgid — board 294 writes ۱۶۸پ ۲۱۰ک ۷۰چ, the initials of
  # پروتئین، کربوهیدرات، چربی.
  defp replaced_macros(f),
    do: replaced_macros(f.kcal, grams(f.protein_mg), grams(f.carbs_mg), grams(f.fat_mg))

  defp replaced_macros(kcal, protein, carbs, fat) do
    gettext("%{kcal} KCAL · %{protein}P %{carbs}C %{fat}F",
      kcal: Kati.Locale.number(kcal),
      protein: Kati.Locale.number(protein),
      carbs: Kati.Locale.number(carbs),
      fat: Kati.Locale.number(fat)
    )
  end

  defp candidate_macros(f),
    do: candidate_macros(f.kcal, grams(f.protein_mg), grams(f.carbs_mg), grams(f.fat_mg))

  defp candidate_macros(kcal, protein, carbs, fat) do
    gettext("%{kcal} kcal · %{protein}P %{carbs}C %{fat}F",
      kcal: Kati.Locale.number(kcal),
      protein: Kati.Locale.number(protein),
      carbs: Kati.Locale.number(carbs),
      fat: Kati.Locale.number(fat)
    )
  end

  defp grams(mg), do: round(mg / 1000)

  defp recipe_figures(recipe) do
    Map.new(Nutrition.fields(), fn field -> {field, Map.fetch!(recipe, :"total_#{field}")} end)
  end

  def render(assigns) do
    candidates = assigns.candidates
    picked = assigns.picked
    # The meal this screen is a swap OF. `mount/3` has resolved it on to the
    # socket since the screen was written and the card never read it: it drew
    # `Kati.Meals.SampleSwap`'s salmon whatever the plan held, so a reader
    # swapping Tuesday's lunch was shown a dinner they had never planned, with
    # the real meal's own figures nowhere on the page. This is the call that
    # reads the assign.
    replacing = assigns.replacing
    effect_on_today = gettext("Effect on today")

    ~MOB"""
    <Box
      fill_width={true}
      fill_height={true}
      background={:background}
      layout_direction={Kati.Locale.direction_prop()}
      font_family={Kati.Locale.face_prop()}
      accessibility_id={Kati.Screens.Identity.of(__MODULE__)}
    >
      <Scroll>
        <Column
          fill_width={true}
          padding_left={21}
          padding_right={21}
          padding_top={64}
          padding_bottom={40}
        >
          {Kati.Screens.MealSwap.header()}
          {Kati.Screens.MealSwap.replacing(replacing)}
          {Kati.Screens.MealSwap.arrow()}
          {Kati.Screens.MealSwap.filters()}
          {Kati.Screens.MealSwap.candidates(candidates, picked)}
          {Kati.Screens.MealSwap.muted_eyebrow(effect_on_today)}
          {Kati.Screens.MealSwap.effect()}
          {Kati.Screens.MealSwap.commit()}
        </Column>
      </Scroll>
    </Box>
    """
  end

  # A 44pt spacer opposite the close button, so the title is centred against
  # the frame rather than against what is left of it.
  @doc false
  def header do
    heading = copy(Sample.heading())

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        {Kati.Screens.MealSwap.close_button()}
        <Spacer weight={1.0} />
        <Text
          text={heading}
          text_size={15}
          font_weight="bold"
          text_color={:on_surface}
          max_lines={1}
        />
        <Spacer weight={1.0} />
        <Spacer size={44} />
      </Row>
      <Spacer size={22} />
    </Column>
    """
  end

  # The screen's single dismissal, and `Kati.Components.MishkaActionIcon` is
  # the name for it: an icon-only button on a raised surface. It could not be
  # one until the component took a `shadow` — a floating disc is defined by its
  # shadow, and `#FBFAF8` on `#EFECE7` without one is nearly no disc at all.
  #
  # `shape: :circle` computes 44 / 2 = 22.0, the radius written here before,
  # and `variant: :filled` paints `background` and nothing more. The glyph is a
  # child rather than `icon:` because Kati's icons are Material Symbols through
  # `Kati.UI.symbol/2` — a `Text` in the `symbols` family — and a child is
  # wrapped in a `<Row>` that hugs it, inside a Box that already centred it.
  @doc false
  def close_button do
    MishkaActionIcon.action_icon(
      [
        size: 44,
        shape: :circle,
        variant: :filled,
        background: Palette.card(),
        shadow: Theme.shadow_button(),
        on_tap: :back
      ],
      [Kati.UI.symbol("close", size: 21)]
    )
  end

  @doc """
  The card at the top: the meal this swap is a swap OF.

  Takes the meal rather than reading the fixture, and the default is what it
  read before — the drawing, which is what `swap/1` assigns when there is no
  plan and no slot. With one, the argument is the real meal's own name and its
  own figures; drawing the fixture's salmon over a resolved slot was the page
  telling a reader their Tuesday lunch was a dinner they had never planned.

  `label`, `title` and `macros` all go through `copy/1`: on the drawn page they
  are `Kati.Meals.SampleSwap`'s English and become words there, and on a real
  one the first is this screen's own spelling of the eyebrow while the other
  two are already in the reader's language and fall through it unchanged.
  """
  def replacing(from \\ Sample.replacing()) do
    # The eyebrow asks the three questions `Kati.UI.eyebrow_label/1`'s doc
    # lists: upcasing is a Latin operation and a no-op on a script with no
    # case, `kati_mono.ttf` carries no Persian glyph, and `.14em` of tracking
    # breaks the joins between Persian letters. The 9.5pt size is NOT picked
    # up the way `Kati.UI.eyebrow/2` picks 10.5 up to 11: that half-point is
    # the SECTION eyebrow's, where Vazirmatn sits beside DM Mono at the same
    # optical weight, and the small label inside a card stays 9.5 in both
    # scripts everywhere the app draws one — `Kati.Screens.AlbumDetail`'s four
    # are the nearest neighbours.
    label = Kati.UI.eyebrow_label(copy(from.label))
    title = copy(from.title)
    macros = copy(from.macros)

    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Palette.card()}
        corner_radius={20}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={14}
        align="center"
      >
        {Kati.Screens.MealSwap.thumb(from.seed)}
        <Spacer size={13} />
        <Column weight={1.0}>
          <Text
            text={label}
            font_family={Kati.Locale.mono_face(label)}
            text_size={9.5}
            letter_spacing={Kati.Locale.tracking(0.14)}
            text_color={Palette.eyebrow()}
            max_lines={1}
          />
          <Spacer size={4} />
          <Text
            text={title}
            text_size={14}
            font_weight="bold"
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={4} />
          <Text
            text={macros}
            font_family={Kati.Locale.mono_face(macros)}
            text_size={10.5}
            text_color={Palette.muted()}
            max_lines={1}
          />
        </Column>
      </Row>
      <Spacer size={8} />
    </Column>
    """
  end

  @doc false
  def arrow do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Spacer weight={1.0} />
        {Kati.UI.symbol("arrow_downward", size: 20, color: Palette.rail_idle())}
        <Spacer weight={1.0} />
      </Row>
      <Spacer size={8} />
    </Column>
    """
  end

  @doc false
  def filters do
    # The chips are drawn, not applied — nothing sorts on them yet — so the
    # label is the whole of each one and `copy/1` is where all three become
    # words. The first is the one in force, which is the drawing's.
    [first | rest] = Enum.map(Sample.filters(), &copy/1)

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        {Kati.Screens.MealSwap.filter(first, true)}
        {Enum.map(rest, fn label -> Kati.Screens.MealSwap.filter(label, false) end)}
      </Row>
      <Spacer size={18} />
    </Column>
    """
  end

  # NOT `Kati.Components.MishkaChip`, and the reason is one prop.
  #
  # Everything else about these three now exists on the chip: `height: 32`,
  # `padding_x: 14` with `padding_y: 0`, `corner_radius: 16`, `text_size: 12.5`,
  # `font_weight: :semibold`, `max_lines: 1`, and — new this round, and the
  # thing that used to block it — `unchecked_color` and `unchecked_text_color`,
  # so the idle chip can be `#FBFAF8` on `#5C574F` rather than the theme's
  # `:surface_raised` on `:on_surface`.
  #
  # What the chip has no way to draw is the **shadow the idle chip carries**.
  # The drawing gives the unchosen two `0 1px 2px rgba(26,25,23,.04), 0 12px
  # 24px -18px rgba(26,25,23,.7)` — `Kati.Theme.shadow_card_soft/0` — and gives
  # the chosen one none, because ink on paper needs no lift. `chip/1` builds a
  # Box and puts `width`, `height`, `align` and `on_tap` on it; there is no
  # `shadow` among them and no slot to reach the root node through, so an
  # adopted chip would drop the lift from two of the three and flatten the row.
  # `MishkaPill` has `shadow` and `MishkaActionIcon` has `shadow`; the chip is
  # the one member of the family without it.
  #
  # That is the whole gap. `shadow` on `MishkaChip`, passed to the root Box the
  # way the pill passes it, and these become one call.
  # This screen writes `0xFF1A1917` in three places and they are not all the
  # same meaning. The chosen filter chip here, the `BEST` badge and the selected
  # candidate's 2pt ring are MARKS — ink used to pick something out on a card —
  # so they take `ink` and invert to `#F5F2EE`. `Swap just today` in `commit/0`
  # is the screen's call-to-action, so it takes `ink_fill` and inverts to the
  # warm `#F7EFE4` screen 28 gives the hero's pill. `on_ink` is the label on all
  # four, and is the palette's own name for a label that inverts WITH the fill
  # rather than following the ground.
  @doc false
  def filter(label, on?) do
    background = if on?, do: Palette.ink(), else: Palette.card()
    color = if on?, do: Palette.on_ink(), else: Palette.ink_soft()
    shadow = if on?, do: nil, else: Theme.shadow_card_soft()

    ~MOB"""
    <Row align="center">
      <Row
        height={32}
        corner_radius={16}
        background={background}
        shadow={shadow}
        padding_left={14}
        padding_right={14}
        align="center"
      >
        <Text text={label} text_size={12.5} font_weight="semibold" text_color={color} max_lines={1} />
      </Row>
      <Spacer size={7} />
    </Row>
    """
  end

  @doc false
  def candidates(candidates, picked \\ nil) do
    ~MOB"""
    <Column fill_width={true}>
      {candidates
       |> Enum.with_index()
       |> Enum.map(fn {row, i} -> Kati.Screens.MealSwap.candidate(row, i, picked) end)}
      <Spacer size={12} />
    </Column>
    """
  end

  @doc """
  One candidate, and the 2pt ring that says it is the one in force.

  The screen has assigned `:picked` and read it since it was written, and the
  doc on the two commit clauses further down this file says *"A tap picks a
  candidate first"* — no control ever sent one, so the ring could only sit where
  `candidates_for/2` put it, and `commit_swap/2` could only ever commit the
  first.

  `picked` is the INDEX rather than the recipe id, because
  `Kati.Meals.SampleSwap`'s three cards are a transcription of board 46 and
  carry no id at all; indexing is what keeps all three tappable on the drawn
  page, and it keeps the tag off `String.to_atom/1`-over-a-stored-id. With none
  picked the ring falls back to `selected?`, which is the drawing.
  """
  def candidate(row, index, picked \\ nil) do
    on? = if is_integer(picked), do: index == picked, else: row.selected?
    border = if on?, do: 2, else: 0
    tap = {self(), String.to_atom("pick_" <> Integer.to_string(index))}
    # Four `copy/1` calls and not one of them can be skipped: on the drawn page
    # all four are `Kati.Meals.SampleSwap`'s English. On a real row only the
    # badge is still a word to translate — `candidates_for/2` spells it `BEST`
    # for exactly this call — while the title is a recipe's own name and the
    # macro and delta lines were composed in the reader's language upstream, so
    # those three fall through `copy/1`'s last clause unchanged.
    title = copy(row.title)
    macros = copy(row.macros)
    delta = copy(row.delta)
    badge = copy(row.badge)

    ~MOB"""
    <Column fill_width={true} on_tap={tap}>
      <Row
        fill_width={true}
        background={Palette.card()}
        corner_radius={18}
        shadow={Kati.Theme.shadow_card_soft()}
        border_width={border}
        border_color={Palette.ink()}
        padding_left={13}
        padding_right={13}
        padding_top={12}
        padding_bottom={12}
        align="center"
      >
        {Kati.Screens.MealSwap.thumb(row.seed)}
        <Spacer size={13} />
        <Column weight={1.0}>
          <Row fill_width={true} align="center">
            <Text
              text={title}
              text_size={13.5}
              font_weight="bold"
              text_color={:on_surface}
              max_lines={1}
            />
            {Kati.Screens.MealSwap.badge(badge)}
          </Row>
          <Spacer size={4} />
          <Text
            text={macros}
            font_family={Kati.Locale.mono_face(macros)}
            text_size={10.5}
            text_color={Palette.muted()}
            max_lines={1}
          />
        </Column>
        <Spacer size={13} />
        <Text
          text={delta}
          font_family={Kati.Locale.mono_face(delta)}
          text_size={11}
          font_weight="medium"
          text_color={row.delta_color}
          max_lines={1}
        />
      </Row>
      <Spacer size={10} />
    </Column>
    """
  end

  # `BEST` is the drawing's own capitalisation — there is no text-transform on
  # it — so it is content rather than styling, and stays as written. That is
  # also why it is not `Kati.UI.eyebrow_label/1`'d on the way in: the caps are
  # the word, not a rule applied to it, and the Persian بهترین is the word with
  # no caps to apply. `copy/1` in `candidate/3` is where it becomes one.
  #
  # The token itself is `Kati.Components.MishkaPill`, which is precisely what a
  # pill is in this port: a compact label, no selected state, no tap. (The
  # filter chips above it are the other thing — see the note on `filter/2`.)
  #
  # Same pixels, one wrapper deeper. The hugging `Row` that carried the ink
  # fill, the 9 radius, 7 of horizontal padding and an 18 height becomes the
  # pill's root `Box fill_width={false}` carrying all four, around a `Row`
  # holding the `Text` and the empty `Row` its unused remove slot leaves — a
  # 0x0 node that adds nothing to the line.
  #
  # All four padding edges are named, so the component's `:space_sm` default
  # never reads: `nodeModifier/1` falls back to the uniform value only for a
  # missing edge. The vertical zeros pin the outer height at 18, because the
  # bridge pads before it sizes. `align: :center` stands in for the Row's
  # `align="center"` — horizontally the content box is exactly the Text's
  # width, so only the vertical half of it has anything to do.
  #
  # The pill takes its label as a STRING and builds the `Text` itself, so there
  # is no `font_family` for this screen to set on it — which is exactly the
  # case `K-48 locale-face-root` exists for: the family the root declares is
  # the one every unmarked `Text` under it resolves to, so بهترین is set in
  # Vazirmatn without the component knowing anything about scripts.
  @doc false
  def badge(nil), do: ~MOB"<Spacer size={0} />"

  def badge(label) do
    ~MOB"""
    <Row align="center">
      <Spacer size={7} />
      {Kati.Screens.MealSwap.badge_pill(label)}
    </Row>
    """
  end

  @doc false
  def badge_pill(label) do
    MishkaPill.pill(
      label: label,
      background: Palette.ink(),
      color: Palette.on_ink(),
      corner_radius: 9,
      height: 18,
      padding_left: 7,
      padding_right: 7,
      padding_top: 0,
      padding_bottom: 0,
      text_size: 9,
      font_weight: :bold,
      align: :center
    )
  end

  @doc false
  def thumb(seed) do
    case Kati.Design.Images.poster(seed) do
      nil ->
        ~MOB"<Box width={48} height={48} corner_radius={13} background={Palette.placeholder()} />"

      src ->
        ~MOB"""
        <Image src={src} width={48} height={48} corner_radius={13} content_mode="fill" />
        """
    end
  end

  # Kati.UI.eyebrow's dash is always the accent, and orange means new or now.
  # The effect on today is a consequence, not an event, so it takes #C4BDB3.
  #
  # Everything else about the label is `Kati.UI.eyebrow/2`'s, down to the two
  # values it picks by script — 11pt semibold in Persian where Latin takes 10.5
  # normal — and `Kati.Screens.Meal.muted_eyebrow/1` copies the same two for the
  # same reason. A section label that is a different size on this page from
  # every other page is the one difference a reader of either script cannot
  # help seeing, and the three type questions under it are the ones
  # `Kati.UI.Eyebrow.quiet/1`'s moduledoc lists: upcasing a script with no case
  # is a no-op that reads as a rule being applied, `kati_mono.ttf` carries no
  # Persian glyph, and `.16em` of tracking breaks the joins between Persian
  # letters.
  @doc false
  def muted_eyebrow(label) do
    text = Kati.UI.eyebrow_label(label)

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_left={2} padding_right={2}>
        <Box width={13} height={2} corner_radius={1} background={Palette.rail_idle()} />
        <Spacer size={9} />
        <Text
          text={text}
          font_family={Kati.Locale.mono_face(text)}
          text_size={Kati.Locale.pick(10.5, 11)}
          font_weight={Kati.Locale.pick("normal", "semibold")}
          letter_spacing={Kati.Locale.tracking(0.16)}
          text_color={Palette.eyebrow()}
        />
      </Row>
      <Spacer size={11} />
    </Column>
    """
  end

  @doc false
  def effect do
    effect = Sample.effect()
    label = copy(effect.label)
    verdict = copy(effect.verdict)

    # The two figures are the fixture's own and go through `Kati.Locale.number/1`
    # rather than the catalogue: `2,085` and `/ 2,100` are digits, a grouping
    # comma and a slash, and none of the three is a word to translate. The
    # digits convert and the comma does not — board 59 draws ۱,۴۸۰ with a Latin
    # comma — and the slash stays out of the catalogue for the reason
    # `Kati.Screens.Health.target_run/1` gives at length: it is punctuation
    # between two runs on one baseline, and ` / %{count}` is exactly the shape
    # `mix gettext.merge` fuzzy-matches onto anything. Nothing mirrors it
    # either; this is a `Row`, so `layout_direction` puts the target run to the
    # LEFT under `:fa` and the line still reads ۲,۰۸۵ / ۲,۱۰۰ from the right.
    total = Kati.Locale.number(effect.total)
    target = Kati.Locale.number(effect.target)

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={20}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={16}
      >
        <Row fill_width={true} align="center">
          <Text
            text={label}
            text_size={13}
            font_weight="semibold"
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer weight={1.0} />
          <Text
            text={total}
            font_family={Kati.Locale.mono_face(total)}
            text_size={12}
            text_color={Palette.ink_soft()}
            max_lines={1}
          />
          <Text
            text={target}
            font_family={Kati.Locale.mono_face(target)}
            text_size={12}
            text_color={Palette.rail_idle()}
            max_lines={1}
          />
        </Row>
        <Spacer size={12} />
        <Box fill_width={true} height={9} corner_radius={4.5} background={Palette.paper()}>
          <Row fill_width={true}>
            {Enum.map(effect.macros, fn {share, tone} -> Kati.Screens.MealSwap.segment(share, tone) end)}
          </Row>
        </Box>
        <Spacer size={12} />
        <Row fill_width={true} align="center">
          {Kati.UI.symbol("check_circle", size: 15, color: Palette.green(), fill: true)}
          <Spacer size={7} />
          <Text
            text={verdict}
            text_size={11.5}
            text_color={Palette.ink_soft()}
            weight={1.0}
            max_lines={1}
          />
        </Row>
      </Column>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc false
  def segment(share, tone) do
    ~MOB"""
    <Box weight={share} height={9} background={tone} />
    """
  end

  @doc false
  def commit do
    {drawn_once, drawn_forever} = Sample.commit()
    once = copy(drawn_once)
    forever = copy(drawn_forever)
    once_tap = {self(), :swap_once}
    forever_tap = {self(), :swap_forever}

    ~MOB"""
    <Row fill_width={true} align="center">
      <Box weight={1.0}>
        <Box
          fill_width={true}
          height={50}
          corner_radius={25}
          background={Palette.ink_fill()}
          align="center"
          on_tap={once_tap}
        >
          <Row fill_width={true} align="center">
            <Spacer weight={1.0} />
            <Text
              text={once}
              text_size={14}
              font_weight="bold"
              text_color={Palette.on_ink()}
              max_lines={1}
            />
            <Spacer weight={1.0} />
          </Row>
        </Box>
      </Box>
      <Spacer size={10} />
      <Row
        height={50}
        corner_radius={25}
        background={Palette.card()}
        shadow={Kati.Theme.shadow_card_soft()}
        padding_left={18}
        padding_right={18}
        align="center"
        on_tap={forever_tap}
      >
        <Text
          text={forever}
          text_size={13}
          font_weight="semibold"
          text_color={Palette.ink_soft()}
          max_lines={1}
        />
      </Row>
    </Row>
    """
  end

  # Board 46's copy, in the reader's language, at the one place each string is
  # drawn. `Kati.Screens.MealReminders.copy/1` is the same function for the same
  # reason: the words are `Kati.Meals.SampleSwap`'s and the fixture holds them
  # as English literals, so this is the door between the two.
  #
  # The order is the board's, top to bottom.
  defp copy("Swap dinner"), do: pgettext("the title of the meal-swap screen", "Swap dinner")

  defp copy("Replacing"),
    do: pgettext("the eyebrow over the meal being swapped out", "Replacing")

  # The meal titles are the catalogue's already — board 43's timeline and board
  # 44's plan draw the salmon, and `Kati.Meals.SamplePlan` and
  # `Kati.Meals.SampleToday` opened the entry between them. One meal named
  # سالمون میسو، سبزیجات، برنج on one page and something else on this one is
  # the disagreement a shared msgid prevents, so this reaches for the existing
  # one rather than writing a fourth.
  defp copy("Miso salmon, greens, rice"), do: gettext("Miso salmon, greens, rice")
  defp copy("620 KCAL · 52P 64C 17F"), do: replaced_macros(620, 52, 64, 17)

  # The three filters, and the context is shared because all three are one row
  # of chips. `Faster` alone is a single word that `mix gettext.merge` would
  # fuzzy-match onto anything, and `Recently eaten` is one letter of difference
  # from the shelf's `Recently added`, which is `pgettext/2` for exactly this
  # reason.
  defp copy("Closest macros"), do: pgettext("a swap-candidate filter", "Closest macros")
  defp copy("Faster"), do: pgettext("a swap-candidate filter", "Faster")
  defp copy("Recently eaten"), do: pgettext("a swap-candidate filter", "Recently eaten")

  defp copy("Cod, new potatoes, peas"), do: gettext("Cod, new potatoes, peas")
  defp copy("BEST"), do: pgettext("the badge on the closest swap candidate", "BEST")
  defp copy("605 kcal · 48P 61C 16F"), do: candidate_macros(605, 48, 61, 16)
  defp copy("−15 kcal"), do: delta_label(-15)

  defp copy("Tofu poke bowl"), do: gettext("Tofu poke bowl")
  defp copy("640 kcal · 38P 72C 19F"), do: candidate_macros(640, 38, 72, 19)
  defp copy("+20 kcal"), do: delta_label(20)

  defp copy("Steak, sweet potato"), do: gettext("Steak, sweet potato")
  defp copy("710 kcal · 55P 52C 30F"), do: candidate_macros(710, 55, 52, 30)
  defp copy("+90 kcal"), do: delta_label(90)

  defp copy("Daily total"), do: pgettext("the day's energy on the swap screen", "Daily total")

  defp copy("Still inside every target for today"),
    do: gettext("Still inside every target for today")

  defp copy("Swap just today"), do: gettext("Swap just today")

  # Two words, and the catalogue already holds `Every week, indefinitely` and
  # `Every week, %{count} weeks` for a merge to land this on. The context also
  # says which of the two commitments it is, which is the thing a translator
  # cannot see from a button label two words long.
  defp copy("Every week"), do: pgettext("the swap that repeats on the plan", "Every week")

  # A string this screen does not know, drawn as it is stored: a recipe's own
  # title, a line this screen composed in the reader's language already, or a
  # row added to `Kati.Meals.SampleSwap` tomorrow — none of which may take the
  # whole page down with a `FunctionClauseError`.
  # `Kati.Screens.MealReminders.copy/1` keeps the same last clause for the same
  # reason.
  defp copy(other), do: other

  def handle_info({:tap, :back}, socket), do: {:noreply, Kati.Screens.Resume.pop(socket)}

  @doc """
  The two commitments, which drew and committed nothing.

  The board's own words are the specification and so is
  `Kati.Meals.MealLog`'s: its moduledoc already says a `:planned` log "is what
  screen 46's *swap just today* writes". So the two buttons are two different
  writes rather than one write with a flag:

    * **Swap just today** logs the candidate as `:planned` against this slot.
      Today's plan changes and next week's does not, which is what "just today"
      means — and it is a claim about a day, so it belongs in the day's log.
    * **Every week** moves the slot itself onto the new recipe. The plan is
      what repeats, so a permanent swap is a change to the plan.

  A tap picks a candidate first; with none picked the first is the one in
  force, which is what the drawing shows selected. On the drawn screen — no
  plan, no slot — both are no-ops, because there is no slot to swap and the
  candidates are `Kati.Meals.SampleSwap`'s rather than rows.
  """
  def handle_info({:tap, :swap_once}, socket),
    do: {:noreply, Kati.Screens.MealSwap.commit_swap(socket, :once)}

  def handle_info({:tap, :swap_forever}, socket),
    do: {:noreply, Kati.Screens.MealSwap.commit_swap(socket, :forever)}

  # The three candidate cards, which drew a ring they could not move. AFTER the
  # three named clauses above and BEFORE the catch-all below, or it swallows
  # them: `:back`, `:swap_once` and `:swap_forever` are atoms too.
  def handle_info({:tap, tag}, socket) when is_atom(tag) do
    case Atom.to_string(tag) do
      "pick_" <> index ->
        {:noreply, Mob.Socket.assign(socket, :picked, String.to_integer(index))}

      _other ->
        {:noreply, socket}
    end
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  @doc false
  @spec commit_swap(Mob.Socket.t(), :once | :forever) :: Mob.Socket.t()
  def commit_swap(socket, how) do
    slot_id = socket.assigns[:slot_id]
    picked = Kati.Screens.MealSwap.picked(socket)

    if is_binary(slot_id) and picked do
      Kati.Screens.MealSwap.write(slot_id, picked, how)
      Kati.Screens.Resume.pop(socket)
    else
      socket
    end
  end

  @doc """
  The candidate in force: the one tapped, or the one the drawing selects.

  An INTEGER `:picked` is a position in the same `:candidates` this render drew
  from, which is what a card's `pick_N` tag carries and why — see
  `candidate/3`. The id branch is kept for a `:picked` that names a row, so a
  caller that hands this screen a recipe id still resolves; neither `swap/1`
  clause sets one today.
  """
  @spec picked(Mob.Socket.t()) :: map() | nil
  def picked(socket) do
    candidates = socket.assigns[:candidates] || []

    tapped =
      case socket.assigns[:picked] do
        index when is_integer(index) -> Enum.at(candidates, index)
        nil -> nil
        id -> Enum.find(candidates, &(&1[:id] && &1.id == id))
      end

    tapped || Enum.find(candidates, & &1[:selected?])
  end

  @doc false
  @spec write(String.t(), map(), :once | :forever) :: :ok
  def write(slot_id, picked, :once) do
    with %{} = slot <- slot_for(slot_id), true <- is_binary(picked[:id]) do
      Kati.Meals.MealLog
      |> Ash.Changeset.for_create(:log_recipe, %{
        recipe_id: picked.id,
        portion_milli: slot.portion_milli,
        logged_on: Kati.Time.today(),
        logged_at: Kati.Time.now() |> DateTime.truncate(:microsecond),
        state: :planned,
        meal_plan_id: slot.meal_plan_id,
        meal_plan_slot_id: slot.id,
        # The slot's own eyebrow and clock, off the slot this function already
        # RESOLVED. Without them screen 43 redrew the swapped meal with a blank
        # time gutter and no slot name — `timeline_rows/2` lays a log over the
        # slot it belongs to, so the log's blanks replaced the card's `Dinner`
        # and `19:30` — and then sorted it to the bottom of the day, because a
        # timeless row orders last. `Kati.Meals.MealLog.log_eaten/1` carries the
        # same two for the same reason; this is the third writer of
        # `:log_recipe` and the rule has to hold at all three or the timeline
        # keeps a hole one path wide.
        slot_name: slot.slot_name,
        slot_time: slot.slot_time
      })
      |> Ash.create()
      |> Kati.Write.note("swap today #{picked.title}")
    end

    :ok
  end

  def write(slot_id, picked, :forever) do
    with %{} = slot <- slot_for(slot_id), true <- is_binary(picked[:id]) do
      slot
      |> Ash.Changeset.for_update(:update, %{recipe_id: picked.id})
      |> Ash.update()
      |> Kati.Write.note("swap every week #{picked.title}")
    end

    :ok
  end
end
