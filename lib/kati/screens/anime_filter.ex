defmodule Kati.Screens.AnimeFilter do
  @moduledoc """
  Screen 152 — Anime, pushed under Settings.

  Built to `.scratch/design/incoming/152.html`, which is not a filter sheet —
  it is the argument for one. The board's own eyebrow says so: "FOUR EDITS,
  ONE SENTENCE". This screen draws the argument, in the board's own words, and
  wires the three controls it actually puts a finger on: the misclassified
  Marram card, and the two selectable pairs in Onboarding.

  ## Anime is not a new kind — the override is

  `Kati.Media.TrackedTitle` and `Kati.Media.CachedTitle` already constrain
  `:kind` to `[:movie, :tv, :anime, :book, :album]`, and
  `Kati.Screens.Library.shelf/0` already reads all three Screen kinds —
  `:movie`, `:tv` **and** `:anime` — into one shelf. Anime has been "a type,
  not a section" since that module was written; screen 03's grid just never
  surfaced it as one. What board 152 is actually proposing is three things
  with no column yet: a per-title override that beats every guess, a rule for
  what a fresh import decides before anyone overrides it, and the two
  placements — sheet chip, tab-row chip — that let a user see and act on the
  flag. `Kati.Media.AnimeSample` carries the board's own numbers for exactly
  that reason; see its moduledoc for the full account of what is real and what
  is not.

  ## The tab-row chip is computed, not drawn twice

  `promote?/2` reads the Anime count against `Kati.Media.AnimeSample`'s own
  threshold and only then appends the fourth chip to the tab row. The board's
  own info box states the rule in words — *"the tab-row chip appears at 10 or
  more anime titles"* — and the sample's `12` clears it, so the promoted row
  the board draws is this function's output, not a second copy of it typed
  into the markup a second time. Drop the sample below 10 and the fourth chip
  disappears on its own.

  ## Three taps, and why the rest of the board has none

  Every drawn tap has to change something (`Kati.Screens.Root`'s own rule —
  a tap answered by nothing is reported as dead by the sweep) — but not every
  drawn CONTROL is a tap. The Type-card chips, the tab-row chips and the three
  numbered priority rows are the board's own worked EXAMPLE of a state, the
  same way `Kati.Screens.AutoDetect`'s three toggled "options" illustrate a
  queued decision without being tappable themselves. Nothing there carries an
  `on_tap`, so `Kati.ScreenTapSweepTest` has nothing to flag.

  What the board draws as genuinely interactive — a choice with two visibly
  different states — gets a real handler:

    * **The "Not anime" pill** on the Marram card. Rule 1 says a user's own tag
      always wins; tapping the pill IS a user setting one, so it flips
      `:marram_fixed?` and the card's own copy changes to say so.
    * **Screen / Books**, the onboarding pair. Picking Books hides the sub-choice
      entirely — it is *"a sub-choice under Screen"*, the board's own words —
      rather than leaving it visible and wrong.
    * **Yes / No**, "Do you watch anime?" — the sub-choice itself, a real
      either/or rather than a picture of one.

  ## Two things `.scratch/design/incoming/152.html` draws that this cannot move

  `Kati.Components.MishkaChip` has no `shadow` prop — every unselected chip on
  the board carries `shadow_card_soft`'s own drop shadow and this file cannot
  put it there without hand-rolling the chip and losing the component. The
  same departure `Kati.UI.SettingsList`'s moduledoc already accepts for a
  dashed border it draws solid instead: the component is the one that changes
  when a bridge gains the prop, not this screen.

  `Kati.UI.rich_text/1` is the honest way to set the board's two bolded spans
  — "**type**" in the cream callout, "**absolute numbering**" in the
  onboarding note — but the bridge has no `AnnotatedString`, so both paragraphs
  render in ONE style (the longest run's), same as every other rich_text call
  site. The emphasis is in the source; it is not on the screen.

  ## Ordering

  Every gap between sections is the board's own margin, not a rounded number —
  `20` is what the board draws for a card that gets its own wrapper `div`, `11`
  is the eyebrow-to-card gap `Kati.UI.eyebrow/2` and
  `Kati.UI.SettingsList.eyebrow_muted/1` already bake in, and `14` is the one
  place the board draws something tighter (its own numbered card). One gap is
  NOT the board's: the Marram card carries no stated margin-bottom in the
  source at all — an omission, not a zero — and this screen closes it at `20`
  to match the rhythm of every other section rather than let two blocks touch.
  """
  use Kati.Screens.Pushed, back: "Settings"

  alias Kati.Components.MishkaChip
  alias Kati.Components.MishkaToggle
  alias Kati.Media.AnimeSample, as: Sample
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  @impl true
  def load(socket) do
    Mob.Socket.assign(socket, :anime, %{
      type_counts: Sample.type_counts(),
      tab_counts: Sample.tab_counts(),
      anime_count: anime_count(Sample.type_counts()),
      threshold: Sample.promote_threshold(),
      rules: Sample.priority_rules(),
      misclassified: Sample.misclassified(),
      marram_fixed?: false,
      onboarding_pick: "Screen",
      watches_anime?: true
    })
  end

  # The Type card's own "Anime" count IS the tab row's fourth chip count —
  # one number, read once, rather than a second literal that could drift from
  # the first.
  defp anime_count(type_counts) do
    {_label, count} = Enum.find(type_counts, {"Anime", 0}, fn {label, _} -> label == "Anime" end)
    count
  end

  @doc """
  Whether the Anime count clears the board's own tab-row threshold.

  A plain `>=`, named so the call site reads like the board's sentence: *"the
  tab-row chip appears at 10 or more anime titles"*. Kept a function rather
  than inlined so `Kati.Screens.AnimeFilter.tab_row/3` and this moduledoc's own
  claim about it cannot quietly drift apart.
  """
  @spec promote?(non_neg_integer(), pos_integer()) :: boolean()
  def promote?(count, threshold), do: count >= threshold

  @doc false
  def content(assigns) do
    a = assigns.anime

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {SettingsList.chrome(nil)}
        {SettingsList.title("Anime", "FOUR EDITS, ONE SENTENCE")}
        {Kati.Screens.AnimeFilter.callout()}
        <Spacer size={20} />
        {UI.eyebrow("Placement A — in the filter sheet, always")}
        {Kati.Screens.AnimeFilter.type_card(a.type_counts)}
        <Spacer size={11} />
        {SettingsList.eyebrow_muted("Placement B — promoted to the tab row at 10 or more")}
        {Kati.Screens.AnimeFilter.tab_row(a.tab_counts, a.anime_count, a.threshold)}
        <Spacer size={20} />
        {SettingsList.note(
          "info",
          "Both ship. The sheet chip is permanent; the tab-row chip appears at 10 or more anime titles — below that it costs a tab slot to filter four things. The threshold is a number, not a feeling."
        )}
        <Spacer size={20} />
        {UI.eyebrow("What sets the flag — and what wins")}
        {Kati.Screens.AnimeFilter.priority_card(a.rules)}
        <Spacer size={14} />
        {SettingsList.eyebrow_muted("The guess is wrong")}
        {Kati.Screens.AnimeFilter.guess_card(a.misclassified, a.marram_fixed?)}
        <Spacer size={20} />
        {UI.eyebrow("Onboarding — a sub-choice under Screen, not a seventh tile")}
        {Kati.Screens.AnimeFilter.onboarding_card(a.onboarding_pick, a.watches_anime?)}
      </Column>
    </Scroll>
    """
  end

  # `Kati.UI.rich_text/1` for the one bolded word — see the moduledoc's "Two
  # things this cannot move". `type` is the LONGEST run only by accident of a
  # short sentence; it is not marked `base: true` because the surrounding
  # sentence is still the longer run either way and always will be.
  @doc false
  def callout do
    body = [text_size: 12.5, line_height: 1.65, text_color: Palette.cream_body()]

    text =
      UI.rich_text([
        {"Anime is a ", body},
        {"type", Keyword.put(body, :font_weight, "bold")},
        {", not a status and not a section. A seventh tile would create a shelf and split a user’s watching across two places for a property of a title.",
         body}
      ])

    ~MOB"""
    <Column fill_width={true} background={Palette.cream()} corner_radius={20} padding={16}>
      <Row fill_width={true} align="top">
        {Kati.UI.symbol("call_split", size: 18, color: Palette.gold_icon())}
        <Spacer size={11} />
        <Column weight={1.0}>
          {text}
        </Column>
      </Row>
    </Column>
    """
  end

  @doc false
  def type_card(counts) do
    chips =
      counts
      |> Enum.map(fn {label, count} ->
        Kati.Screens.AnimeFilter.stat_chip(label, count, label == "Anime")
      end)
      |> Enum.intersperse(Kati.Screens.AnimeFilter.chip_gap())

    ~MOB"""
    <Column
      fill_width={true}
      background={Kati.Theme.card(Palette.mode())}
      corner_radius={20}
      shadow={Kati.Theme.shadow_card_soft()}
      padding={15}
    >
      <Text
        text={String.upcase("Type")}
        font_family="mono"
        text_size={10}
        letter_spacing={0.14}
        text_color={Palette.eyebrow()}
      />
      <Spacer size={11} />
      <Scroll axis="horizontal">
        <Row align="center">
          {chips}
        </Row>
      </Scroll>
    </Column>
    """
  end

  @doc """
  The tab row: the board's three always-shown chips, plus a fourth exactly
  when `promote?/2` says so.

  Unwrapped markup rather than `Kati.UI.SettingsList.card/1` — the board draws
  this row bare over the page, with no card behind it at all. The board clips
  it (`152.html:9`, `overflow:hidden`) on the assumption a real tab bar cannot
  scroll sideways; this one CAN — `Kati.Screens.Library.chips/2` sets that
  precedent for the same four-chip shape — so a label never loses its tail to
  a device narrower than the drawing's 402pt frame.
  """
  def tab_row(base_counts, anime_count, threshold) do
    counts =
      if Kati.Screens.AnimeFilter.promote?(anime_count, threshold),
        do: base_counts ++ [{"Anime", anime_count}],
        else: base_counts

    chips =
      counts
      |> Enum.map(fn {label, count} ->
        Kati.Screens.AnimeFilter.stat_chip(label, count, label == "All")
      end)
      |> Enum.intersperse(Kati.Screens.AnimeFilter.chip_gap())

    ~MOB"""
    <Scroll axis="horizontal">
      <Row align="center">
        {chips}
      </Row>
    </Scroll>
    """
  end

  # Shared by both placements — the board draws the same chip, pixel for pixel,
  # in the Type card and in the tab row. `count_fg` is NOT
  # `Kati.Screens.Library.chip/3`'s pair: the board sets the unselected count in
  # plain `muted()`, not `count_idle_soft()`'s alpha ramp — a different screen,
  # a different literal, checked against `152.html` rather than assumed from
  # 03's.
  @doc false
  def stat_chip(label, count, on?) do
    count_fg = if on?, do: Palette.on_ink_count_soft(), else: Palette.muted()

    MishkaChip.chip(
      label: label,
      checked: on?,
      trailing: Kati.Screens.AnimeFilter.stat_chip_count(count, count_fg),
      trailing_gap: 6,
      height: 32,
      padding_x: 15,
      padding_y: 0,
      corner_radius: 16,
      text_size: 12.5,
      font_weight: :semibold,
      max_lines: 1,
      color: Palette.ink_fill(),
      text_color: Palette.on_ink(),
      unchecked_color: Kati.Theme.card(Palette.mode()),
      unchecked_text_color: Palette.ink_soft()
    )
  end

  @doc false
  def stat_chip_count(count, color) do
    ~MOB"""
    <Text text={"#{count}"} font_family="mono" text_size={10} text_color={color} max_lines={1} />
    """
  end

  @doc false
  def chip_gap, do: ~MOB"<Spacer size={7} />"

  @doc false
  def priority_card(rules) do
    last = length(rules) - 1

    rules
    |> Enum.with_index()
    |> Enum.map(fn {{n, title, sub}, i} ->
      Kati.Screens.AnimeFilter.priority_row(n, title, sub, i < last)
    end)
    |> SettingsList.card()
  end

  # `align="top"` and a 12px gap — the board's own `align-items:flex-start` and
  # `gap:12px` — rather than `Kati.UI.SettingsList.row/4`, whose fixed 13px gap
  # and centred alignment are a different card's numbers (screens 24/25/32/36).
  @doc false
  def priority_row(n, title, sub, rule?) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top" padding_top={11} padding_bottom={11}>
        {Kati.Screens.AnimeFilter.priority_badge(n)}
        <Spacer size={12} />
        <Column weight={1.0}>
          <Text text={title} text_size={13} font_weight="semibold" text_color={:on_surface} />
          <Spacer size={4} />
          <Text text={sub} text_size={11.5} line_height={1.5} text_color={Palette.sub()} />
        </Column>
      </Row>
      {SettingsList.hairline(rule?)}
    </Column>
    """
  end

  @doc false
  def priority_badge(n) do
    ~MOB"""
    <Box width={22} height={22} corner_radius={11} background={Palette.ink()} align="center">
      <Text
        text={"#{n}"}
        font_family="mono"
        text_size={10.5}
        text_color={Palette.on_ink()}
        max_lines={1}
      />
    </Box>
    """
  end

  @doc """
  The one card the board draws as a worked mistake, and the one row on this
  screen where "your own tag always wins" (rule 1) is something you can
  actually do rather than just read about.
  """
  def guess_card(item, fixed?) do
    tap = {self(), :fix_marram}

    ~MOB"""
    <Column
      fill_width={true}
      background={Kati.Theme.card(Palette.mode())}
      corner_radius={22}
      shadow={Kati.Theme.shadow_card_soft()}
      padding={17}
    >
      <Row fill_width={true} align="center">
        {Kati.Screens.AnimeFilter.guess_poster(item.seed)}
        <Spacer size={12} />
        <Column weight={1.0}>
          <Text
            text={item.title}
            text_size={13}
            font_weight="bold"
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={4} />
          <Text
            text={Kati.Screens.AnimeFilter.guess_sub(item, fixed?)}
            text_size={11.5}
            text_color={Palette.sub()}
            max_lines={2}
          />
        </Column>
        <Spacer size={12} />
        <Box on_tap={tap} fill_width={false}>
          {SettingsList.action_pill(Kati.Screens.AnimeFilter.guess_pill_label(fixed?))}
        </Box>
      </Row>
    </Column>
    """
  end

  @doc false
  def guess_sub(item, false), do: item.note
  def guess_sub(_item, true), do: "Your tag: live action — overrides the MAL import"

  @doc false
  def guess_pill_label(false), do: "Not anime"
  def guess_pill_label(true), do: "Tagged"

  @doc false
  def guess_poster(seed) do
    case Kati.Design.Images.poster(seed) do
      nil ->
        ~MOB"""
        <Box width={40} height={56} corner_radius={8} background={Palette.placeholder()} />
        """

      src ->
        ~MOB"""
        <Image src={src} width={40} height={56} corner_radius={8} content_mode="fill" />
        """
    end
  end

  @doc false
  def onboarding_card(pick, watches?) do
    ~MOB"""
    <Column
      fill_width={true}
      background={Kati.Theme.card(Palette.mode())}
      corner_radius={22}
      shadow={Kati.Theme.shadow_card_soft()}
      padding={17}
    >
      <Row fill_width={true} align="top">
        {Kati.Screens.AnimeFilter.onboarding_tile("movie", "Screen", pick == "Screen", :pick_screen)}
        <Spacer size={11} />
        {Kati.Screens.AnimeFilter.onboarding_tile("menu_book", "Books", pick == "Books", :pick_books)}
      </Row>
      {Kati.Screens.AnimeFilter.subchoice_block(pick, watches?)}
    </Column>
    """
  end

  @doc false
  def onboarding_tile(icon, label, on?, tag) do
    bg = if on?, do: Palette.ink(), else: Kati.Theme.card(Palette.mode())
    fg = if on?, do: Palette.on_ink(), else: Palette.ink()
    # `0 12 24 -14 #E61A1917` is the board's own — `box-shadow:0 12px 24px
    # -14px rgba(26,25,23,.9)` (`.9 * 255 = 229.5`, `0xE6`) — and it matches no
    # `Kati.Theme` shadow: `shadow_card` and `shadow_button` both spread -18/-12
    # at lower alphas. Passed as a literal, the way `Kati.UI`'s switch thumb
    # already passes `"0 1 3 0 #4D1A1917"` rather than force-fit an existing
    # token.
    shadow = if on?, do: "0 12 24 -14 #E61A1917", else: Kati.Theme.shadow_card_soft()
    tap = {self(), tag}

    # A bare weighted `Box` outside, the styled card inside — `weight` divides
    # the Row's width off THIS wrapper, exactly the split
    # `Kati.Screens.Library.quick_tile/4` already uses for a tappable, weighted
    # card, rather than one node asked to both size itself in the Row and paint
    # its own background.
    ~MOB"""
    <Box weight={1.0} on_tap={tap}>
      <Column fill_width={true} background={bg} corner_radius={18} shadow={shadow} padding={14}>
        {Kati.UI.symbol(icon, size: 21, color: fg)}
        <Spacer size={12} />
        <Text text={label} text_size={14} font_weight="bold" text_color={fg} max_lines={1} />
      </Column>
    </Box>
    """
  end

  # "a sub-choice under Screen" — the board's own words — so picking Books
  # does not leave it showing and wrong; it stops existing on the frame at all,
  # the same way `Kati.Screens.Library.visible/3` empties the grid rather than
  # greying it for a shelf with nothing to show.
  @doc false
  def subchoice_block("Screen", watches?) do
    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={14} />
      {Kati.Screens.AnimeFilter.anime_subchoice(watches?)}
    </Column>
    """
  end

  def subchoice_block(_pick, _watches?), do: ~MOB"<Spacer size={0} />"

  @doc false
  def anime_subchoice(watches?) do
    body = [text_size: 12, line_height: 1.55, text_color: Palette.ink_soft()]

    note =
      UI.rich_text([
        {"Kati will default those to ", body},
        {"absolute numbering", Keyword.put(body, :font_weight, "bold")},
        {" — E32 rather than S2 E6.", body}
      ])

    ~MOB"""
    <Column fill_width={true} background={Palette.paper()} corner_radius={16} padding={14}>
      <Text text="Do you watch anime?" text_size={13} font_weight="bold" text_color={:on_surface} />
      <Spacer size={6} />
      {note}
      <Spacer size={12} />
      <Row fill_width={true} align="center">
        {Kati.Screens.AnimeFilter.yn_button("Yes", watches?, :watches_yes)}
        <Spacer size={8} />
        {Kati.Screens.AnimeFilter.yn_button("No", not watches?, :watches_no)}
      </Row>
    </Column>
    """
  end

  # `MishkaToggle`, styled to the board's own 36pt / radius-18 pressed pair —
  # `Kati.Screens.AutoDetect.choice/2`'s three answers are 34/17, a different
  # card's numbers, and unlike those three this pair is actually wired:
  # `on_change` is set, where AutoDetect's illustration deliberately leaves it
  # off (see that module's own doc on why).
  @doc false
  def yn_button(label, on?, tag) do
    button =
      MishkaToggle.toggle(
        label: label,
        pressed: on?,
        color: Palette.ink_fill(),
        text_color: Palette.on_ink(),
        background: Kati.Theme.card(Palette.mode()),
        label_color: Palette.ink_soft(),
        corner_radius: 18,
        height: 36,
        padding: 0,
        border_width: 0,
        fill_width: true,
        align: :center,
        text_size: 12.5,
        font_weight: :semibold,
        max_lines: 1,
        on_change: tag
      )

    ~MOB"""
    <Box weight={1.0}>
      {button}
    </Box>
    """
  end

  @impl true
  def handle_tap(:fix_marram, socket) do
    {:noreply,
     Mob.Socket.assign(
       socket,
       :anime,
       Map.update!(socket.assigns.anime, :marram_fixed?, &(not &1))
     )}
  end

  def handle_tap(:pick_screen, socket) do
    {:noreply,
     Mob.Socket.assign(socket, :anime, Map.put(socket.assigns.anime, :onboarding_pick, "Screen"))}
  end

  def handle_tap(:pick_books, socket) do
    {:noreply,
     Mob.Socket.assign(socket, :anime, Map.put(socket.assigns.anime, :onboarding_pick, "Books"))}
  end

  def handle_tap(:watches_yes, socket) do
    {:noreply,
     Mob.Socket.assign(socket, :anime, Map.put(socket.assigns.anime, :watches_anime?, true))}
  end

  def handle_tap(:watches_no, socket) do
    {:noreply,
     Mob.Socket.assign(socket, :anime, Map.put(socket.assigns.anime, :watches_anime?, false))}
  end
end
