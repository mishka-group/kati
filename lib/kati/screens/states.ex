defmodule Kati.Screens.States do
  @moduledoc """
  Screen 27 — States, a reference sheet pushed under Settings.

  Built to `test/design/screens/27.html`: the four states nobody designs,
  drawn once so every other screen can quote them. Empty invites rather than
  apologises; loading is a skeleton and never a spinner; offline promises the
  ticks are safe; and every destructive action leaves an undo bar behind.

  Two eyebrows carry the grey dash instead of the orange one — Offline and
  Undo are consequences of something going wrong, not things that are new or
  happening now, and orange means new/now.

  ## Two things the drawing does that the bridge cannot

    * **Opacity.** The skeleton rows fade to 1, .75 and .5. No node carries an
      opacity prop, so `Kati.Settings.StatesSample.skeletons/0` composites each
      row's colours against paper and scales its shadow alphas to match.
    * **A horizontal shimmer.** The design fills each skeleton bar with
      `linear-gradient(90deg, #E7E3DC, #F1EEE9, #E7E3DC)`. The bridge's
      gradient parser is vertical only — `to_top` or `to_bottom` — so the bars
      are the flat `#E7E3DC` the gradient starts and ends on.

  No dock — pushed screen — so the frame closes at 40, not 132.

  ## Nothing on this sheet is domain data, and that was checked rather than assumed

  Every other screen in this round moved onto `Kati.Media`, `Kati.Calendars` or
  `Kati.Meals`. This one has nothing to move, and the reason is structural
  rather than a gap in the domains: **a reference sheet draws all five states at
  once, unconditionally.** Each card is a picture of a state, not a report that
  the app is in it, so a value read from a resource would be a true number
  attached to an event that never happened.

  Four lines look like data. None of them is:

    * **`Last success 6h ago`** is the one that could be read.
      `Kati.Calendars.Account.last_sync_at` holds exactly that instant and
      `Kati.Sync.Engine` writes it **only on success**, so the figure exists and
      is trustworthy. It is still not read here, because the card above it —
      *Couldn't check for releases* — is drawn whether or not a check failed.
      Dating a real last success against an invented failure is worse than the
      drawing: it reads as a live incident report and is not one.
    * **`Dropped The Quiet Ones`** names a title nothing dropped.
      `Kati.Media.TrackedTitle.status` can be `:dropped`, and nothing anywhere
      records **when** a status changed — no tombstone, no audit row, no undo
      window. So there is no most-recent destructive action to name, and none
      that tapping `Undo` could take back.
    * **`Offline`** is a condition of the device. No resource stores it, and the
      badge is drawn on this sheet whether the radio is on or off.
    * **`No titles yet`** is the empty state, drawn here beside a full library on
      purpose. Gating it on `Kati.Media.TrackedTitle` being empty would show
      five states on a fresh install and four on every other device, which is
      the opposite of what a reference sheet is for.

  So this screen reads no store and has no fallback to keep: its Sample module
  is the specimen itself rather than a stand-in for data that has not arrived,
  which is why `Kati.Settings.StatesSample` says *the "sample" here is the
  specimen itself* in its own first paragraph. The one thing that would change
  this is a **live** states screen — the app showing its own current condition —
  and that is a different screen from the sheet the design draws.

  ## What this file translates, and what it only typesets

  mishka-group/kati#103. This screen owns seven strings — its title, its
  subtitle and the five band eyebrows — and those are `gettext/1` here. Every
  other word on the sheet is `Kati.Settings.StatesSample`'s: the empty state's
  four lines, the offline badge, the failed check with its last-success line,
  the undo bar, and the retired band's title, paragraph and example tile are
  copy typed once from `27.html` and owned by that module, so they are
  translated **there** and not here. A msgid has to be a literal at its own call
  site, so there is no way to wrap them from this file that would not also move
  the copy out of the specimen — which is the one thing the specimen exists to
  hold. `Kati.Screens.DropStates` makes the same split against
  `Kati.Settings.DropStatesSample`, and states the argument at the same length.

  What this file does own for that copy is its **typesetting**, and that is the
  half that breaks silently — the words arrive correct and the page is wrong:

    * `Kati.Locale.tracking/1` on both card headings' negative letter-spacing.
      Tightening by a fraction of an em is a Latin move; in the Arabic script it
      pulls letters apart at the joins that make a word one shape.
    * `Kati.Locale.leading/1` on both paragraphs. Vazirmatn's metrics are not
      Plus Jakarta's, so the design's own 1.55 and 1.6 set Persian too tight.
    * `Kati.Locale.pick/2` on the retired paragraph's `max_lines`. Six lines
      holds the English with one to spare; a Persian sentence that ran one line
      longer would drop the clause about what tapping the tile does, which is
      the half of the band a static picture cannot show.

  Nothing else on this sheet needs asking for. There is no number and no date
  this file renders, so neither `Kati.Locale.number/1` nor `date/2` is called
  here — the one figure that looks like a measurement, *Last success 6h ago*, is
  the specimen's, and the four paragraphs above say why it is not read from
  `Kati.Calendars.Account`. The one mono line is the subtitle, and
  `Kati.UI.SettingsList.subtitle/2` already asks `Kati.Locale.mono_face/0` for
  it, so `reference sheet` is handed over as words and typeset there. And there
  is no directional glyph: the dashed tile opens something but carries no
  chevron, and the empty state's primary action leads with `add`, which is the
  same shape in both directions.

  ## Two strings stay Latin because they are keys, not copy

    * `handle_tap/2` pushes `%{section: "Sleep"}`. That is matched against the
      untranslated names `Kati.Health.Sample.sections/0` stores, and
      `Kati.Screens.RetiredTile` draws its own translated label off the id it
      finds — see `Kati.Retired`'s moduledoc for the long version of *a label
      doubling as compared state*, which is the defect this fold is about.
    * `back: "Settings"` is the same shape of key.
      `Kati.Screens.Pushed.back_label/2` translates it at render time through a
      `msgctxt "back pill"` lookup, so the pill reads Persian without the word
      in this file moving.

  ## One defect this file can see and cannot fix

  `Kati.UI.SettingsList.eyebrow_muted/1` still writes `String.upcase(label)` and
  a hardcoded `letter_spacing={0.16}` where `Kati.UI.eyebrow/2` has since grown
  `Kati.UI.eyebrow_label/1` and `Kati.Locale.tracking/1`. Three of this sheet's
  five eyebrows go through the muted one, so under `:fa` they are set with the
  Latin small-caps tracking that breaks Arabic-script joins. The fix is one
  helper changed once, in that file, rather than a fork of the grey dash here.
  """
  use Kati.Screens.Pushed, back: "Settings"
  use Gettext, backend: Kati.Gettext

  alias Kati.Settings.StatesSample, as: Sample
  alias Kati.UI
  alias Kati.UI.SettingsList

  @impl true
  def load(socket) do
    Mob.Socket.assign(socket, :states, %{
      empty: Sample.empty(),
      skeletons: Sample.skeletons(),
      offline: Sample.offline(),
      error: Sample.error(),
      undo: Sample.undo(),
      retired: Sample.retired()
    })
  end

  @doc false
  def content(assigns) do
    s = assigns.states

    # The seven strings this screen owns, bound out here rather than written
    # inside the sigil's `{...}` — both compile, and this way the whole of what
    # the file translates reads as one list somebody can check against
    # `test/design/screens/27.html`. `Kati.Screens.DropStates.content/1` does the
    # same for the same reason.
    #
    # Three shapes of lookup, and the split is the fuzzy-matching rule rather
    # than taste:
    #
    #   * The five band eyebrows are plain `gettext/1`. Each is a phrase long
    #     enough that `mix gettext.merge` has nothing to confuse it with, and two
    #     of the five are already in the catalogue under exactly this msgid —
    #     `Kati.Screens.BookDetailStates` draws *Loading — skeleton, never a
    #     spinner* and `Kati.Screens.ShelfSelection` draws *Undo — every
    #     destructive action*, both quoting this sheet, which is what a reference
    #     sheet is for. An exact msgid always beats a fuzzy one, and a contexted
    #     twin here would mint a second Persian sentence for a band the app has
    #     already worded once.
    #   * `States` is `pgettext/2`, and it is the one that would have gone wrong
    #     quietly. It is a single word, there is no plain `States` in the
    #     catalogue, and there are five near neighbours — *Eight states*, *Two
    #     states*, *five states*, *six states*, *seven states* — every one of
    #     them a sibling reference board's title or subtitle. `gettext.merge`
    #     fuzzy-matches a msgid that short onto its neighbour, and a sheet headed
    #     **هفت حالت** is a wrong word no test here would catch, because nothing
    #     on this screen is asserted against a string. `msgctxt "screen title"`
    #     is the context `Kati.Screens.Money` and `Kati.Screens.Gallery` already
    #     use for exactly this.
    #   * `reference sheet` takes a context for the same reason at two words,
    #     and it is the mono line under the title rather than the title, so it
    #     gets its own rather than sharing one.
    #
    # `_band` on the five rather than the bare word: this module defines
    # `empty/1`, `offline/1`, `undo/1` and `retired/1`, and a variable that
    # shares a builder's name reads as that builder at a glance even though the
    # arities keep them apart.
    title = pgettext("screen title", "States")
    subtitle = pgettext("screen subtitle", "reference sheet")
    empty_band = gettext("Empty — nothing added yet")
    loading_band = gettext("Loading — skeleton, never a spinner")
    offline_band = gettext("Offline — the library still works")
    undo_band = gettext("Undo — every destructive action")
    retired_band = gettext("Not in this version — drawn, not built")

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {SettingsList.chrome("more_horiz")}
        {SettingsList.title(title, subtitle, nil, :meta_tight)}
        {UI.eyebrow(empty_band)}
        {Kati.Screens.States.empty(s.empty)}
        {UI.eyebrow(loading_band)}
        {Kati.Screens.States.skeletons(s.skeletons)}
        {SettingsList.eyebrow_muted(offline_band)}
        {Kati.Screens.States.offline(s.offline)}
        {Kati.Screens.States.error(s.error)}
        {SettingsList.eyebrow_muted(undo_band)}
        {Kati.Screens.States.undo(s.undo)}
        <Spacer size={26} />
        {SettingsList.eyebrow_muted(retired_band)}
        {Kati.Screens.States.retired(s.retired)}
      </Column>
    </Scroll>
    """
  end

  # The copy is `Kati.Settings.StatesSample.empty/0`'s and is translated there.
  # What changes here is the two props that are about the script rather than
  # about the words: the heading's `-0.02` tracking goes to zero under `:fa`
  # because tightening breaks the joins between Persian letters, and the body's
  # 1.55 leading goes to Vazirmatn's own. Neither number moves in English.
  @doc false
  def empty(e) do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={0xFFFBFAF8}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding_left={22}
        padding_right={22}
        padding_top={30}
        padding_bottom={30}
      >
        <Row fill_width={true} align="center">
          <Spacer weight={1.0} />
          <Box width={64} height={64} corner_radius={20} background={0xFFEFECE7} align="center">
            {Kati.UI.symbol(e.icon, size: 28, color: 0xFFC4BDB3)}
          </Box>
          <Spacer weight={1.0} />
        </Row>
        <Spacer size={18} />
        <Text
          text={e.title}
          text_size={17}
          font_weight="bold"
          letter_spacing={Kati.Locale.tracking(-0.02)}
          text_color={:on_surface}
          text_align="center"
        />
        <Spacer size={8} />
        <Text
          text={e.body}
          text_size={13}
          line_height={Kati.Locale.leading(1.55)}
          text_color={0xFF8A8479}
          text_align="center"
        />
        <Spacer size={18} />
        <Row
          fill_width={true}
          height={44}
          corner_radius={22}
          background={Kati.Theme.ink()}
          align="center"
        >
          <Spacer weight={1.0} />
          {Kati.UI.symbol("add", size: 18, color: 0xFFFBFAF8)}
          <Spacer size={7} />
          <Text
            text={e.action}
            text_size={13}
            font_weight="bold"
            text_color={0xFFFBFAF8}
            max_lines={1}
          />
          <Spacer weight={1.0} />
        </Row>
        <Spacer size={14} />
        <Text
          text={e.secondary}
          text_size={12.5}
          font_weight="semibold"
          text_color={0xFF8A8479}
          text_align="center"
        />
      </Column>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def skeletons(rows) do
    ~MOB"""
    <Column fill_width={true}>
      {Enum.map(rows, fn row -> Kati.Screens.States.skeleton(row) end)}
      <Spacer size={15} />
    </Column>
    """
  end

  # 11pt above and below, 13 each side, and a 9pt gap to the next — so the row
  # carries its own trailing spacer rather than the list interspersing one.
  @doc false
  def skeleton(row) do
    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={row.card}
        corner_radius={18}
        shadow={row.shadow}
        padding_left={13}
        padding_right={13}
        padding_top={11}
        padding_bottom={11}
        align="center"
      >
        <Box width={40} height={56} corner_radius={8} background={row.bar} />
        <Spacer size={12} />
        <Column weight={1.0}>
          <Box fill_width={true} height={11} corner_radius={6} background={row.bar} />
          <Spacer size={8} />
          <Row fill_width={true}>
            <Box weight={0.52} height={9} corner_radius={6} background={row.bar} />
            <Spacer weight={0.48} />
          </Row>
        </Column>
      </Row>
      <Spacer size={9} />
    </Column>
    """
  end

  # Cream, and flat. The offline badge is the one card on this sheet with no
  # shadow in the drawing: it is a condition the app is in, not an object
  # lifted off the paper.
  @doc false
  def offline(o) do
    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={0xFFFBF1DE}
        corner_radius={18}
        padding_left={16}
        padding_right={16}
        padding_top={14}
        padding_bottom={14}
        align="center"
      >
        {Kati.UI.symbol(o.icon, size: 20, color: 0xFFC98A3E)}
        <Spacer size={12} />
        <Column weight={1.0}>
          <Text
            text={o.title}
            text_size={13}
            font_weight="bold"
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={3} />
          <Text text={o.sub} text_size={11.5} text_color={0xFF8A7B60} max_lines={1} />
        </Column>
      </Row>
      <Spacer size={12} />
    </Column>
    """
  end

  @doc false
  def error(e) do
    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={0xFFFBFAF8}
        corner_radius={18}
        shadow={Kati.Theme.shadow_card_soft()}
        padding_left={16}
        padding_right={16}
        padding_top={14}
        padding_bottom={14}
        align="center"
      >
        {Kati.UI.symbol(e.icon, size: 20, color: Kati.Theme.red())}
        <Spacer size={12} />
        <Column weight={1.0}>
          <Text
            text={e.title}
            text_size={13}
            font_weight="bold"
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={3} />
          <Text text={e.sub} text_size={11.5} text_color={0xFF8A8479} max_lines={1} />
        </Column>
        <Spacer size={12} />
        {SettingsList.action_pill(e.action)}
      </Row>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def undo(u) do
    ~MOB"""
    <Row
      fill_width={true}
      background={Kati.Theme.ink()}
      corner_radius={20}
      padding_left={16}
      padding_right={16}
      padding_top={13}
      padding_bottom={13}
      align="center"
    >
      {Kati.UI.symbol(u.icon, size: 19, color: 0xFFFBFAF8)}
      <Spacer size={12} />
      <Text
        text={u.text}
        text_size={13}
        font_weight="semibold"
        text_color={0xFFFBFAF8}
        weight={1.0}
        max_lines={1}
      />
      <Spacer size={12} />
      <Text
        text={u.action}
        text_size={12.5}
        font_weight="bold"
        text_color={0xFFE8823C}
        max_lines={1}
      />
    </Row>
    """
  end

  @doc """
  The sixth band, and the one that is about a screen rather than about a state.

  Five bands above say what a screen does while it waits, fails or undoes. This
  one says what a screen does when it is **drawn and not built** — the ritual
  #22 named as missing. The rule is in words and then in a tile, because the
  words are what another screen has to follow and the tile is what a reader
  recognises.

  The tile is pressable and lands on `Kati.Screens.RetiredTile`, which is the
  half of the treatment a static picture cannot show: the answer to *what does
  tapping it do*. It is drawn here rather than borrowed from
  `Kati.Screens.Health.tile/1` on purpose — that builder reads a live section
  list, and a reference sheet that reported today's sections would stop being a
  reference the day one of them turned on.

  ## `max_lines` is 6 in English and 8 in Persian, and that is not a fudge

  The paragraph is the rule another screen has to follow, and its last clause —
  *tapping it opens one sheet that names what it is, why it is not here, and
  what Kati can do instead today* — is the half of the treatment the tile below
  cannot draw. Six lines holds the English with one to spare, which is why the
  cap was six; a Persian sentence one line longer would lose that clause
  silently, with no ellipsis on a line that is already the last. `pick/2` rather
  than a bigger number for both, so the English rendering is byte-identical to
  what the board was signed off against and only the script that needs the room
  gets it. mishka-group/kati#103.
  """
  @spec retired(map()) :: map()
  def retired(r) do
    ~MOB"""
    <Column
      fill_width={true}
      background={0xFFFBFAF8}
      corner_radius={22}
      shadow={Kati.Theme.shadow_card_soft()}
      padding={22}
    >
      <Text
        text={r.title}
        text_size={15}
        font_weight="bold"
        letter_spacing={Kati.Locale.tracking(-0.01)}
        text_color={:on_surface}
      />
      <Spacer size={8} />
      <Text
        text={r.body}
        text_size={13}
        line_height={Kati.Locale.leading(1.6)}
        text_color={0xFF8A8479}
        max_lines={Kati.Locale.pick(6, 8)}
      />
      <Spacer size={16} />
      {Kati.Screens.States.dashed_tile(r.example)}
    </Column>
    """
  end

  @doc """
  One dashed tile, in screen 42's geometry, carrying the tap that is the point.

  `border_width` and `border_color` rather than a fill: a tile that is drawn
  and not built has an outline where the others have a surface, which is the
  whole of how the grid says it without a word.
  """
  @spec dashed_tile(map()) :: map()
  def dashed_tile(example) do
    ~MOB"""
    <Column
      fill_width={true}
      corner_radius={20}
      border_width={1.5}
      border_color={Kati.Theme.Palette.border_soft()}
      padding={16}
      on_tap={{self(), :open_retired}}
    >
      <Row fill_width={true} align="center">
        {Kati.UI.symbol(example.icon, size: 22, color: Kati.Theme.Palette.tertiary())}
        <Spacer size={10} />
        <Text
          text={example.name}
          text_size={14}
          font_weight="semibold"
          text_color={Kati.Theme.Palette.tertiary()}
          weight={1.0}
          max_lines={1}
        />
        <Text
          text={example.status}
          text_size={11.5}
          text_color={Kati.Theme.Palette.tertiary()}
          max_lines={1}
        />
      </Row>
    </Column>
    """
  end

  # The tap the band exists to demonstrate. Pushed with the section the example
  # tile names, so the sheet that opens is the one screen 42 would have opened.
  #
  # `"Sleep"` is a KEY and stays Latin in both scripts. `Kati.Screens.RetiredTile`
  # matches it against the untranslated `name` on `Kati.Health.Sample.sections/0`
  # and then draws its own `label/1` off the id it finds, so the sheet's header
  # is Persian while the lookup that gets there is not. Translating this literal
  # would not produce a Persian header — it would produce a sheet with no
  # paragraph on it, which is the exact defect `Kati.Retired`'s moduledoc names:
  # a label doubling as compared state fails silently, because a miss is
  # indistinguishable from a section nobody wrote copy for. mishka-group/kati#103.
  @impl true
  def handle_tap(:open_retired, socket) do
    {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.RetiredTile, %{section: "Sleep"})}
  end
end
