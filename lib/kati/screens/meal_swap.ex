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
  """
  # Not `Kati.Screens.Pushed`: this screen dismisses with its own close
  # button, and the drawing has exactly one dismissal.
  use Mob.Screen
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
          label: "Replacing",
          title: recipe.title,
          macros: macro_line(figures),
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
        badge: if(i == 0, do: "BEST"),
        macros: String.downcase(macro_line(theirs)),
        delta: delta_label(theirs.kcal - figures.kcal),
        delta_color: if(theirs.kcal <= figures.kcal, do: @green, else: @red),
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
  defp delta_label(0), do: "same"
  defp delta_label(diff) when diff < 0, do: "−#{abs(diff)} kcal"
  defp delta_label(diff), do: "+#{diff} kcal"

  defp macro_line(f) do
    "#{f.kcal} KCAL · #{grams(f.protein_mg)}P #{grams(f.carbs_mg)}C #{grams(f.fat_mg)}F"
  end

  defp grams(mg), do: round(mg / 1000)

  defp recipe_figures(recipe) do
    Map.new(Nutrition.fields(), fn field -> {field, Map.fetch!(recipe, :"total_#{field}")} end)
  end

  def render(assigns) do
    candidates = assigns.candidates

    ~MOB"""
    <Box
      fill_width={true}
      fill_height={true}
      background={:background}
      layout_direction={Kati.Locale.direction_prop()}
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
          {Kati.Screens.MealSwap.replacing()}
          {Kati.Screens.MealSwap.arrow()}
          {Kati.Screens.MealSwap.filters()}
          {Kati.Screens.MealSwap.candidates(candidates)}
          {Kati.Screens.MealSwap.muted_eyebrow("Effect on today")}
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
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        {Kati.Screens.MealSwap.close_button()}
        <Spacer weight={1.0} />
        <Text
          text={Kati.Meals.SampleSwap.heading()}
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

  @doc false
  def replacing do
    from = Sample.replacing()

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
            text={String.upcase(from.label)}
            font_family="mono"
            text_size={9.5}
            letter_spacing={0.14}
            text_color={Palette.eyebrow()}
            max_lines={1}
          />
          <Spacer size={4} />
          <Text
            text={from.title}
            text_size={14}
            font_weight="bold"
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={4} />
          <Text
            text={from.macros}
            font_family="mono"
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
    [first | rest] = Sample.filters()

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
  def candidates(candidates) do
    ~MOB"""
    <Column fill_width={true}>
      {Enum.map(candidates, fn row -> Kati.Screens.MealSwap.candidate(row) end)}
      <Spacer size={12} />
    </Column>
    """
  end

  @doc false
  def candidate(row) do
    border = if row.selected?, do: 2, else: 0

    ~MOB"""
    <Column fill_width={true}>
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
              text={row.title}
              text_size={13.5}
              font_weight="bold"
              text_color={:on_surface}
              max_lines={1}
            />
            {Kati.Screens.MealSwap.badge(row.badge)}
          </Row>
          <Spacer size={4} />
          <Text
            text={row.macros}
            font_family="mono"
            text_size={10.5}
            text_color={Palette.muted()}
            max_lines={1}
          />
        </Column>
        <Spacer size={13} />
        <Text
          text={row.delta}
          font_family="mono"
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
  # it — so it is content rather than styling, and stays as written.
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
  @doc false
  def muted_eyebrow(label) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_left={2} padding_right={2}>
        <Box width={13} height={2} corner_radius={1} background={Palette.rail_idle()} />
        <Spacer size={9} />
        <Text
          text={String.upcase(label)}
          font_family="mono"
          text_size={10.5}
          letter_spacing={0.16}
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
            text={effect.label}
            text_size={13}
            font_weight="semibold"
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer weight={1.0} />
          <Text
            text={effect.total}
            font_family="mono"
            text_size={12}
            text_color={Palette.ink_soft()}
            max_lines={1}
          />
          <Text
            text={effect.target}
            font_family="mono"
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
            text={effect.verdict}
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
    {once, forever} = Sample.commit()
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

  def handle_info({:tap, :back}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}

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

  @doc false
  @spec commit_swap(Mob.Socket.t(), :once | :forever) :: Mob.Socket.t()
  def commit_swap(socket, how) do
    slot_id = socket.assigns[:slot_id]
    picked = Kati.Screens.MealSwap.picked(socket)

    if is_binary(slot_id) and picked do
      Kati.Screens.MealSwap.write(slot_id, picked, how)
      Mob.Socket.pop_screen(socket)
    else
      socket
    end
  end

  @doc "The candidate in force: the one tapped, or the one the drawing selects."
  @spec picked(Mob.Socket.t()) :: map() | nil
  def picked(socket) do
    candidates = socket.assigns[:candidates] || []

    Enum.find(candidates, &(&1[:id] && &1.id == socket.assigns[:picked])) ||
      Enum.find(candidates, & &1[:selected?])
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
        meal_plan_slot_id: slot.id
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

  def handle_info(_message, socket), do: {:noreply, socket}
end
