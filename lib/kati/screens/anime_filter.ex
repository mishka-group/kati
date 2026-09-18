defmodule Kati.Screens.AnimeFilter do
  @moduledoc """
  Screen 152 — Anime, pushed under Settings.

  Built to `test/design/reference/152.html`, which is not a filter sheet —
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

  The two captions that state the rule now read the same number: `10` was a
  literal in the muted eyebrow and in the info box, so the sample could move
  and leave both sentences behind, still saying ten over a row that had stopped
  promoting. Both take `%{n}` from `Sample.promote_threshold/0`, which is also
  how the numeral reaches a Persian reader as `۱۰` — `Kati.Locale.number/1`
  inside a sentence.

  ## A word is not a key

  Everything `Kati.Media.AnimeSample` hands over is English, and it stays
  English: it is `test/design/reference/152.html` written out, and it is what
  `anime_count/1` counts, what `type_card/1` and `tab_row/3` test to find the
  selected chip, and what `promote?/2`'s appended fourth chip is named. The
  word the reader sees comes out of `sample_text/1` instead, one layer later.

  The same goes for `:onboarding_pick`, which held the string `"Screen"` and
  was compared against a second copy of it in three places. Under `:fa` the
  tile would have drawn «نمایش» while the assign still held `"Screen"`, and the
  sub-choice under it would have kept working only because nothing had
  translated the comparison yet. It holds `:screen` and `:books` now.
  `Kati.Screens.Library.chip_counts/1` is where this app already paid for that
  lesson, in its own comment, about its own four chips.

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

  ## Two things `test/design/reference/152.html` draws that this cannot move

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
  use Gettext, backend: Kati.Gettext

  require Ash.Query

  alias Kati.Components.MishkaChip
  alias Kati.Components.MishkaToggle
  alias Kati.Media.AnimeSample, as: Sample
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  @impl true
  def load(socket) do
    tracked = tracked_titles()
    cached = cached_by_reference(tracked)
    counts = type_counts(tracked, cached)

    Mob.Socket.assign(socket, :anime, %{
      type_counts: counts,
      tab_counts: tab_counts(tracked),
      anime_count: anime_count(counts),
      threshold: Sample.promote_threshold(),
      rules: Sample.priority_rules(),
      misclassified: misclassified_guess(tracked, cached),
      marram_fixed?: false,
      onboarding_pick: :screen,
      watches_anime?: Enum.any?(tracked, &(&1.kind == :anime))
    })
  end

  @screen_kinds [:movie, :tv, :anime]

  defp tracked_titles do
    @screen_kinds
    |> Enum.flat_map(fn kind ->
      Kati.Media.TrackedTitle
      |> Ash.Query.for_read(:shelf, %{kind: kind})
      |> Ash.read!()
    end)
  rescue
    _error -> []
  end

  defp cached_by_reference(tracked) do
    ids = tracked |> Enum.map(& &1.source_id) |> Enum.uniq()

    Kati.Media.CachedTitle
    |> Ash.Query.filter(source_id in ^ids)
    |> Ash.read!()
    |> Map.new(&{{&1.source, &1.source_id}, &1})
  rescue
    _error -> %{}
  end

  defp type_counts(tracked, cached) do
    {anime, rest} = Enum.split_with(tracked, &(&1.kind == :anime))
    animation = Enum.count(rest, &animated?(cached_for(&1, cached)))

    [
      {"Anime", length(anime)},
      {"Live action", length(rest) - animation},
      {"Animation", animation}
    ]
  end

  defp animated?(%{genres: genres}), do: String.contains?(to_string(genres), "Animation")
  defp animated?(_cached), do: false

  defp tab_counts(tracked) do
    anime = Enum.filter(tracked, &(&1.kind == :anime))

    [
      {"All", length(anime)},
      {"Watching", Enum.count(anime, &(&1.status == :watching))},
      {"Finished", Enum.count(anime, &(&1.status == :finished))}
    ]
  end

  @doc false
  @spec misclassified() :: map() | nil
  def misclassified do
    tracked = tracked_titles()
    misclassified_guess(tracked, cached_by_reference(tracked))
  end

  defp misclassified_guess(tracked, cached) do
    tracked
    |> Enum.filter(&(&1.kind == :anime and is_nil(&1.anime_override)))
    |> Enum.sort_by(& &1.last_touched_at, {:desc, DateTime})
    |> List.first()
    |> guess(cached)
  end

  defp guess(nil, _cached), do: nil

  defp guess(track, cached) do
    case cached_for(track, cached) do
      nil ->
        nil

      title ->
        %{
          id: track.id,
          title: title.title,
          seed: title.source_id,
          note: guess_reason(track, title)
        }
    end
  end

  defp cached_for(track, cached), do: Map.get(cached, {track.source, track.source_id})

  defp guess_reason(track, cached) do
    cond do
      to_string(track.source) in ~w(jikan anilist) ->
        gettext("Imported from a file that marks everything in it anime")

      Kati.Media.Anime.provider_says?(cached) ->
        gettext("TMDB lists it as Animation, origin Japanese")

      true ->
        gettext("Tagged anime, and Kati cannot say why")
    end
  end

  # The Type card's own "Anime" count IS the tab row's fourth chip count —
  # one number, read once, rather than a second literal that could drift from
  # the first.
  #
  # `"Anime"` here is the sample's KEY, not a label: the word on the chip comes
  # from `sample_text/1` and changes with the reader, and this lookup must not.
  defp anime_count(type_counts) do
    {_key, count} = Enum.find(type_counts, {"Anime", 0}, fn {key, _} -> key == "Anime" end)
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

  @doc """
  The reader's own word for a string `Kati.Media.AnimeSample` hands over.

  The sample is the BOARD written out — `test/design/reference/152.html`'s own
  labels, in the board's own English — and it stays that way. What travels out
  of it is a **key**: `"Anime"` is what `anime_count/1` counts, what
  `type_card/1` compares against to decide which of the three chips is the
  selected one, and what `tab_row/3` appends when `promote?/2` says so. A key
  that translated itself would break all three the moment the reader chose
  Persian, and would break them silently — the chips would still draw and the
  counts would still be right.

  `Kati.Screens.Library.chip_counts/1` carries the long version of that
  argument in its own comment, because the shelf already paid for it: its four
  filters were one string doing both jobs, so the Persian shelf's filter was
  «همه» and every clause of `matching/2` fell through to `_all`. This is the
  same split one module further out — the sample keeps the key, and this is the
  only place that turns one into a word.

  A string with no clause of its own comes back untouched. A fourth type chip
  added to the sample tomorrow then draws in English rather than raising, which
  is the right failure for a design fixture to have: `mix gettext.extract` reads
  literal call sites and could not have a msgid for it either way.
  """
  @spec sample_text(String.t()) :: String.t()
  def sample_text("Anime"), do: gettext("Anime")

  # `pgettext/2` for the two type words the catalogue does not already hold.
  # `Animation` and `Anime` are one edit apart, and `mix gettext.merge` fuzzy-
  # matches a msgid that close to an existing entry — an untranslated
  # `Animation` would arrive carrying `انیمه`, marked fuzzy, on a card whose
  # whole subject is that the two are not the same thing.
  def sample_text("Live action"), do: pgettext("a title’s type", "Live action")
  def sample_text("Animation"), do: pgettext("a title’s type", "Animation")

  # The three tab-row keys are the shelf's own three, and they take the shelf's
  # own msgids rather than a second set: `Kati.Screens.Library.chip_counts/1`
  # already draws `All`, `Watching` and `Finished` over the same four-chip
  # shape, and one word written twice is one word that can be translated twice.
  def sample_text("All"), do: gettext("All")
  def sample_text("Watching"), do: gettext("Watching")
  def sample_text("Finished"), do: gettext("Finished")

  # `Marram` is `Kati.Library.Sample`'s own ninth title, not a fixture this
  # board invented, and the catalogue has carried its Persian since that sample
  # was folded. Reusing the msgid is what keeps one show from being spelled two
  # ways across two screens.
  def sample_text("Marram"), do: gettext("Marram")

  def sample_text("Your own tag"), do: gettext("Your own tag")
  def sample_text("Always wins — you know"), do: gettext("Always wins — you know")
  def sample_text("The import source"), do: gettext("The import source")
  def sample_text("The provider genre"), do: gettext("The provider genre")

  def sample_text("A MAL or AniList file marks everything in it"),
    do: gettext("A MAL or AniList file marks everything in it")

  # `TMDB` and its `Animation` stay Latin inside the sentence: that pair is the
  # name of a row in somebody else's genre table, not this app's word for a
  # type of title, and the chip two sections up already says `انیمیشن` for the
  # thing Kati means by it.
  def sample_text("TMDB’s Animation + Japanese origin"),
    do: gettext("TMDB’s Animation + Japanese origin")

  def sample_text("Tagged anime from a MAL import — it is live action"),
    do: gettext("Tagged anime from a MAL import — it is live action")

  def sample_text(other), do: other

  @doc false
  def content(assigns) do
    a = assigns.anime

    # `%{n}` in the two sentences that state the threshold, filled from
    # `a.threshold` rather than typed. The moduledoc's own rule — *the promoted
    # row the board draws is this function's output, not a second copy of it* —
    # applied to the words as well as to the chip: `10` was written into the
    # eyebrow and into the info box while `promote?/2` read the sample, so
    # dropping the sample below ten made the fourth chip disappear under two
    # captions that still said ten. It is also the only way the numeral reaches
    # a Persian reader as one: `Kati.Locale.number/1` inside a sentence, which
    # is the case that function exists for.
    n = Kati.Locale.number(a.threshold)

    placement_b = gettext("Placement B — promoted to the tab row at %{n} or more", n: n)

    both_ship =
      gettext(
        "Both ship. The sheet chip is permanent; the tab-row chip appears at %{n} or more anime titles — below that it costs a tab slot to filter four things. The threshold is a number, not a feeling.",
        n: n
      )

    # The eyebrow names the tile below it, so it takes the tile's own msgid
    # rather than a second copy of the word — translate one and both move.
    onboarding =
      gettext("Onboarding — a sub-choice under %{tile}, not a seventh tile",
        tile: gettext("Screen")
      )

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
        {SettingsList.title(gettext("Anime"), gettext("FOUR EDITS, ONE SENTENCE"))}
        {Kati.Screens.AnimeFilter.callout()}
        <Spacer size={20} />
        {UI.eyebrow(gettext("Placement A — in the filter sheet, always"))}
        {Kati.Screens.AnimeFilter.type_card(a.type_counts)}
        <Spacer size={11} />
        {SettingsList.eyebrow_muted(placement_b)}
        {Kati.Screens.AnimeFilter.tab_row(a.tab_counts, a.anime_count, a.threshold)}
        <Spacer size={20} />
        {SettingsList.note("info", both_ship)}
        <Spacer size={20} />
        {UI.eyebrow(gettext("What sets the flag — and what wins"))}
        {Kati.Screens.AnimeFilter.priority_card(a.rules)}
        <Spacer size={14} />
        {SettingsList.eyebrow_muted(gettext("The guess is wrong"))}
        {Kati.Screens.AnimeFilter.guess_card(a.misclassified, a.marram_fixed?)}
        <Spacer size={20} />
        {UI.eyebrow(onboarding)}
        {Kati.Screens.AnimeFilter.onboarding_card(a.onboarding_pick, a.watches_anime?)}
      </Column>
    </Scroll>
    """
  end

  # `Kati.UI.rich_text/1` for the one bolded word — see the moduledoc's "Two
  # things this cannot move". `type` is the LONGEST run only by accident of a
  # short sentence; it is not marked `base: true` because the surrounding
  # sentence is still the longer run either way and always will be.
  #
  # Three runs, three msgids, and the space between the first two is added at
  # the call site rather than carried inside one — `Kati.Screens.Backup` and
  # `Kati.Screens.AutoDetectMusic` both split a bolded sentence that way, and a
  # msgid with a trailing space is a msgid a translator silently trims.
  # The first two runs take `pgettext/2` because neither is long enough to be
  # safe on its own: *type* is one word, and *Anime is a* is three characters
  # of edit distance from the `Anime` the chip above it already holds.
  @doc false
  def callout do
    body = [
      text_size: 12.5,
      line_height: Kati.Locale.leading(1.65),
      text_color: Palette.cream_body()
    ]

    text =
      UI.rich_text([
        {pgettext("the anime callout, before its bolded word", "Anime is a") <> " ", body},
        {pgettext("the anime callout’s bolded word", "type"),
         Keyword.put(body, :font_weight, "bold")},
        {gettext(
           ", not a status and not a section. A seventh tile would create a shelf and split a user’s watching across two places for a property of a title."
         ), body}
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
    # The key decides which chip is checked, `sample_text/1` decides what it
    # says, and the two are never the same value — see that function's own doc.
    chips =
      counts
      |> Enum.map(fn {key, count} ->
        Kati.Screens.AnimeFilter.stat_chip(
          Kati.Screens.AnimeFilter.sample_text(key),
          count,
          key == "Anime"
        )
      end)
      |> Enum.intersperse(Kati.Screens.AnimeFilter.chip_gap())

    # The card's own mono eyebrow, and all three of its props had to move for
    # Persian rather than just the word:
    #
    #   * `Kati.UI.eyebrow_label/1` instead of `String.upcase/1`. Arabic script
    #     has no case, so upcasing «نوع» returns «نوع» — a no-op that still
    #     reads as one beside the Latin caps the rest of the page keeps.
    #   * `Kati.Locale.mono_face/0` instead of `"mono"`. `kati_mono.ttf` carries
    #     no Persian glyph at all, and a `Text` that names it hands the line to
    #     whatever face Android substitutes.
    #   * `Kati.Locale.tracking/1` instead of `0.14`. Tracking a Latin eyebrow
    #     opens it up; tracking Persian breaks the joins between the letters.
    #
    # `Kati.UI.eyebrow/2` already does all three for the eyebrows outside the
    # card — this is the one the board draws inside it.
    ~MOB"""
    <Column
      fill_width={true}
      background={Kati.Theme.card(Palette.mode())}
      corner_radius={20}
      shadow={Kati.Theme.shadow_card_soft()}
      padding={15}
    >
      <Text
        text={Kati.UI.eyebrow_label(pgettext("the Type card’s own label", "Type"))}
        font_family={Kati.Locale.mono_face()}
        text_size={10}
        letter_spacing={Kati.Locale.tracking(0.14)}
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
      |> Enum.map(fn {key, count} ->
        Kati.Screens.AnimeFilter.stat_chip(
          Kati.Screens.AnimeFilter.sample_text(key),
          count,
          key == "All"
        )
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

  # `Kati.Locale.number/1` first, then `Kati.Locale.mono_face/1` about the
  # RESULT — the same pair, in the same order, that
  # `Kati.Screens.Library.chip_count/2` uses on the other four-chip row, and for
  # the same reason: `kati_mono.ttf` carries none of U+06F0–U+06F9, so a Persian
  # numeral left in DM Mono draws as empty boxes. Asking the string rather than
  # the reader is what keeps `12` in DM Mono on an English page and `۱۲` in
  # Vazirmatn on a Persian one without a second branch here.
  @doc false
  def stat_chip_count(count, color) do
    assigns = %{count: Kati.Locale.number(count)}

    ~MOB"""
    <Text
      text={@count}
      font_family={Kati.Locale.mono_face(@count)}
      text_size={10}
      text_color={color}
      max_lines={1}
    />
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
      Kati.Screens.AnimeFilter.priority_row(
        n,
        Kati.Screens.AnimeFilter.sample_text(title),
        Kati.Screens.AnimeFilter.sample_text(sub),
        i < last
      )
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
          <Text
            text={sub}
            text_size={11.5}
            line_height={Kati.Locale.leading(1.5)}
            text_color={Palette.sub()}
          />
        </Column>
      </Row>
      {SettingsList.hairline(rule?)}
    </Column>
    """
  end

  # The rank in the badge is a numeral the reader reads, not a token — rule
  # ONE beats rule two — so it converts and its face follows the conversion,
  # exactly as `stat_chip_count/2`'s count does. Three digits at most, in a
  # 22pt circle: `۱` is no wider than `1`.
  @doc false
  def priority_badge(n) do
    assigns = %{n: Kati.Locale.number(n)}

    ~MOB"""
    <Box width={22} height={22} corner_radius={11} background={Palette.ink()} align="center">
      <Text
        text={@n}
        font_family={Kati.Locale.mono_face(@n)}
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
  def guess_card(nil, _fixed?), do: ~MOB"<Spacer size={0} />"

  def guess_card(item, fixed?) do
    tap = {self(), :fix_misclassified}

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
            text={Kati.Screens.AnimeFilter.sample_text(item.title)}
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

  # Both lines are held to two rendered lines by the `max_lines={2}` above, and
  # the Persian is written tight for it: the column between the 40pt poster and
  # the pill is about 180pt wide, which is where a faithful but longer sentence
  # would lose its tail to an ellipsis rather than wrap.
  @doc false
  def guess_sub(item, false), do: Kati.Screens.AnimeFilter.sample_text(item.note)
  def guess_sub(_item, true), do: gettext("Your tag: live action — overrides Kati's guess")

  # `pgettext/2` for both: two words and one, and `mix gettext.merge` fuzzy-
  # matches a msgid that short against any longer sentence that contains it —
  # the catalogue already holds several `Tagged`-shaped lines about a title.
  @doc false
  def guess_pill_label(false), do: pgettext("the override pill on a wrong guess", "Not anime")
  def guess_pill_label(true), do: pgettext("the override pill once it is set", "Tagged")

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

  # `pick` is an atom and the tile's label is a translation of it, which is the
  # split `load/1`'s own comment gives the reason for.
  # `Kati.Screens.PickSections.Sample.label/1` is the same shape on the screen
  # these two tiles are quoting — `{"screen", "movie"}` is an id and an icon,
  # and the word comes out of a lookup — so the msgids are that screen's rather
  # than a second pair: one section, one word, wherever it is drawn.
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
        {Kati.Screens.AnimeFilter.onboarding_tile(
          "movie",
          gettext("Screen"),
          pick == :screen,
          :pick_screen
        )}
        <Spacer size={11} />
        {Kati.Screens.AnimeFilter.onboarding_tile(
          "menu_book",
          gettext("Books"),
          pick == :books,
          :pick_books
        )}
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
  def subchoice_block(:screen, watches?) do
    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={14} />
      {Kati.Screens.AnimeFilter.anime_subchoice(watches?)}
    </Column>
    """
  end

  def subchoice_block(_pick, _watches?), do: ~MOB"<Spacer size={0} />"

  # The two episode codes are interpolated rather than written into the msgid,
  # and both go through `Kati.Locale.ltr/1`. `E32` and `S2 E6` are the numbering
  # itself — the thing the sentence is about — so a translator must not be given
  # the chance to edit them; and a Latin run carrying a full stop inside an RTL
  # paragraph has that stop resolved as right-to-left and laid out at the wrong
  # edge, which is the failure `Kati.Locale.ltr/1`'s own doc found on screen 83.
  # The isolate costs nothing in English: it is a no-op there.
  @doc false
  def anime_subchoice(watches?) do
    body = [
      text_size: 12,
      line_height: Kati.Locale.leading(1.55),
      text_color: Palette.ink_soft()
    ]

    example =
      gettext(" — %{absolute} rather than %{seasoned}.",
        absolute: Kati.Locale.ltr("E32"),
        seasoned: Kati.Locale.ltr("S2 E6")
      )

    note =
      UI.rich_text([
        {gettext("Kati will default those to") <> " ", body},
        {pgettext("the onboarding note’s bolded words", "absolute numbering"),
         Keyword.put(body, :font_weight, "bold")},
        {example, body}
      ])

    ~MOB"""
    <Column fill_width={true} background={Palette.paper()} corner_radius={16} padding={14}>
      <Text
        text={gettext("Do you watch anime?")}
        text_size={13}
        font_weight="bold"
        text_color={:on_surface}
      />
      <Spacer size={6} />
      {note}
      <Spacer size={12} />
      <Row fill_width={true} align="center">
        {Kati.Screens.AnimeFilter.yn_button(
          pgettext("answer to “Do you watch anime?”", "Yes"),
          watches?,
          :watches_yes
        )}
        <Spacer size={8} />
        {Kati.Screens.AnimeFilter.yn_button(
          pgettext("answer to “Do you watch anime?”", "No"),
          not watches?,
          :watches_no
        )}
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
  def handle_tap(:fix_misclassified, socket) do
    fixed? = not socket.assigns.anime.marram_fixed?
    override = if fixed?, do: false, else: nil

    case socket.assigns.anime.misclassified do
      %{id: id} ->
        with {:ok, track} <- Ash.get(Kati.Media.TrackedTitle, id) do
          Ash.update(track, %{anime_override: override})
        end

      nil ->
        :ok
    end

    {:noreply,
     Mob.Socket.assign(
       socket,
       :anime,
       Map.put(socket.assigns.anime, :marram_fixed?, fixed?)
     )}
  end

  def handle_tap(:pick_screen, socket) do
    {:noreply,
     Mob.Socket.assign(socket, :anime, Map.put(socket.assigns.anime, :onboarding_pick, :screen))}
  end

  def handle_tap(:pick_books, socket) do
    {:noreply,
     Mob.Socket.assign(socket, :anime, Map.put(socket.assigns.anime, :onboarding_pick, :books))}
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
