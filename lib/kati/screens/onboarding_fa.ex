defmodule Kati.Screens.OnboardingFa do
  @moduledoc """
  Screen 137 — راه‌اندازی, onboarding step three in Persian.

  Built to `test/design/reference/137.html`. Structurally this is
  `Kati.Screens.PickSections` (screen 26) read in Persian — the same shape of
  question: a step meter, a two-line heading, a blurb, a 2-across grid of six
  section tiles with two pre-chosen, and a commit button — because 137 draws
  that shape, not `Kati.Screens.Onboarding`'s welcome/telling/first-title
  stack. Only the module name is new: the design file's own caption calls
  this board "onboarding," and that is the name it keeps here.

  Chromeless like both English screens it descends from: no header, no back
  pill, no dock. The frame is `Kati.Screens.Fa.pushed_frame/1` — the direction
  only, nothing else — with the same `64 / 21 / 40` numbers `PickSections` and
  `Onboarding` both use for a screen whose only way out is drawn on the page
  itself.

  ## Five bars, three filled — not `PickSections.Sample`'s four and two

  `Kati.Screens.LanguagePick` (screen 53) already draws its own meter at five
  segments and calls itself "the first step of five." 137's meter is five
  segments, three filled. The Persian sequence counts the language choice as
  step one — English's four-step count never did — so this is step three:
  language, a step with no Persian board in this round yet, then this one.
  `Kati.Screens.OnboardingFa.Sample.steps/0` answers `{5, 3}` for that reason,
  not by mistake next to `PickSections.Sample.steps/0`'s `{4, 2}`.

  ## Two literal differences from `PickSections`, kept rather than smoothed

  The commit button carries no `arrow_forward` — 137 draws its ادامه pill as
  centred text alone, where 26.html draws Continue with a trailing arrow — so
  `cta/1` omits the glyph 26's `commit/1` includes. And the same button's drop
  shadow is `rgba(26,25,23,.5)` here against 26's own `.85`; `"0 14 28 -12
  #801A1917"` is 137's own alpha, not `PickSections.commit/1`'s `#D9`. Both are
  the drawing disagreeing with its English sibling, not this file disagreeing
  with the drawing.

  ## The badge lands at the mirrored corner for free

  137 positions the check badge with `top:14;left:14` against 26's
  `top:14;right:14` — the opposite physical corner, because English's tile
  puts its icon at the top-left (LTR content flow) and 137's puts it at the
  top-right (RTL content flow), and the badge always sits in the corner the
  icon is not in. `tile/2` below is `PickSections.tile/2`'s icon-row shape
  unchanged — icon, a weighted `Spacer`, then the badge — inside a root `Fa`
  declares `rtl`. A `Row` lays out start-to-end; start is the right under
  `rtl`, so the icon lands right and the badge lands left with no per-screen
  arithmetic, the same way `Kati.Screens.HomeFa`'s poster stack mirrors for
  free. `offset_x={2}` on the badge stays positive: `Kati.Screens.HomeFa`'s own
  moduledoc records that `Modifier.offset` is direction-aware, so the same "2pt
  further out" reads as 2pt more to the left here without the sign changing.

  ## The footnote is new copy, not a translated one

  Nothing on 26.html corresponds to the dashed info box: it is Persian's own
  addition, naming the three consequences a Persian install already carries —
  the week starting شنبه (Saturday), Shamsi dates, Persian digits — as
  following from the *language* choice on screen 53 rather than needing a
  setting of their own. `note/0` builds it with the same `Kati.Components.MishkaPill`
  outlined mode `Kati.UI.SettingsList.note/2` wraps and `Kati.Screens.Backup.footnote/0`
  already reaches past that wrapper for: one bold run (`شنبه`) inside a
  wrapping paragraph. `Kati.UI.rich_text/1`'s own moduledoc is explicit that
  the bridge has no `AnnotatedString` path, so the "bold" is an approximation —
  the whole paragraph renders in the longer, plain run's style, and the
  emphasis is silently dropped rather than orphaning a one-word line. That
  trade is `rich_text/1`'s, not a compromise made again here.

  ## Which taps are real, and which are honestly not

  The six tiles toggle for real: `Mob.Socket.update/3` flips membership in
  `:chosen`, `tile/2` redraws inverted or not, and `cta/1`'s own label counts
  what is actually chosen rather than repeating 137's frozen `۲`. Every tag a
  tile draws reaches a named `handle_info/2` clause — none of the six fall
  through to the catch-all.

  ادامه با X بخش draws no `on_tap` at all. There is no Persian step four in
  this round to push it to, `Kati.Screens.Onboarding` is English, and pushing
  an English screen from a Persian root is exactly the failure
  `Kati.Screens.HomeFa` leaves عادت‌ها inert to avoid: "a dead button reads as
  a bug where an untranslated screen reads as unfinished, which is the truth."
  `Kati.ScreenSweep.tap_tags/1` only collects nodes that carry `on_tap` in the
  first place, so a button drawn without one is not a tap answered by a
  catch-all — it is a control the sweep never asked about, which is the
  honest state of the fourth step today.

  The two footer links both do real, mismatch-free things. بازگردانی از
  پشتیبان pushes `Kati.Screens.RestoreFa` — screen 132, which did not exist
  when `PickSections.commit/1` settled for `Kati.Screens.Import` as "the wrong
  one of the two... until screen 129 is built." 129 is built and so is its
  Persian mirror, so this file reaches the right one directly instead of
  repeating a workaround whose reason is gone. One small, named cost survives
  the choice: `RestoreFa`'s back pill is pinned to `تنظیمات` by its own
  `use Kati.Screens.Pushed, back: "تنظیمات"`, because 132.html was drawn
  pushed under Settings — so a reader who follows this link back out sees a
  label naming the wrong parent for one frame before `Mob.Socket.pop_screen/1`
  lands them back here regardless of what the label said. بازگشت به خوش‌آمد
  is `pop_screen/1` for a plainer reason: there is no `WelcomeFa` for it to
  name, and a pushed screen going back needs no destination — only the stack
  it already sits on.
  """
  use Mob.Screen
  import Mob.Sigil

  alias Kati.I18n.Digits
  alias Kati.Screens.Fa
  alias Kati.Screens.OnboardingFa.Sample
  alias Kati.Theme.Palette
  alias Kati.UI

  def mount(_params, _session, socket) do
    Kati.Theme.activate()
    {:ok, Mob.Socket.assign(socket, :chosen, Sample.chosen())}
  end

  def render(assigns) do
    content = Kati.Screens.OnboardingFa.content(assigns.chosen)
    Fa.pushed_frame(content, Kati.Screens.Identity.of(__MODULE__))
  end

  def handle_info({:tap, tag}, socket) do
    case Atom.to_string(tag) do
      "section_" <> id ->
        {:noreply, Mob.Socket.update(socket, :chosen, &toggle(&1, id))}

      "restore_backup" ->
        {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.RestoreFa)}

      "back_to_welcome" ->
        {:noreply, Mob.Socket.pop_screen(socket)}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  defp toggle(chosen, id) do
    if MapSet.member?(chosen, id), do: MapSet.delete(chosen, id), else: MapSet.put(chosen, id)
  end

  @doc false
  def content(chosen) do
    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {Kati.Screens.OnboardingFa.intro()}
        {Kati.Screens.OnboardingFa.grid(chosen)}
        {Kati.Screens.OnboardingFa.cta(chosen)}
        {Kati.Screens.OnboardingFa.note()}
        {Kati.Screens.OnboardingFa.footer()}
      </Column>
    </Scroll>
    """
  end

  @doc false
  def intro do
    ~MOB"""
    <Column fill_width={true} padding_top={26}>
      {Kati.Screens.OnboardingFa.steps()}
      <Text
        text={Sample.heading()}
        font_family="fa"
        font_weight="extrabold"
        text_size={25}
        line_height={1.45}
        text_color={:on_surface}
      />
      <Spacer size={12} />
      <Text
        text={Sample.blurb()}
        font_family="fa"
        text_size={13.5}
        line_height={1.9}
        text_color={Palette.ink_soft()}
      />
      <Spacer size={18} />
    </Column>
    """
  end

  # Five segments, `done` of them filled. See the moduledoc for why this is
  # five where `PickSections.steps/0` is four.
  @doc false
  def steps do
    {total, done} = Sample.steps()

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        {1..total
         |> Enum.map(fn i -> Kati.Screens.OnboardingFa.step_bar(i <= done) end)
         |> Enum.intersperse(Kati.Screens.OnboardingFa.step_gap())}
      </Row>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def step_gap, do: ~MOB"<Spacer size={5} />"

  @doc false
  def step_bar(done?) do
    color = if done?, do: Palette.ink(), else: Palette.track_off()
    ~MOB"<Box weight={1.0} height={4} corner_radius={2} background={color} />"
  end

  @doc false
  def grid(chosen) do
    ~MOB"""
    <Column fill_width={true}>
      {Sample.sections()
       |> Enum.chunk_every(2)
       |> Enum.map(fn pair -> Kati.Screens.OnboardingFa.grid_row(pair, chosen) end)
       |> Enum.intersperse(Kati.Screens.OnboardingFa.tile_gap())}
      <Spacer size={18} />
    </Column>
    """
  end

  @doc false
  def tile_gap, do: ~MOB"<Spacer size={12} />"

  @doc false
  def grid_row(pair, chosen) do
    ~MOB"""
    <Row fill_width={true} align="top">
      {pair
       |> Enum.map(fn section ->
         Kati.Screens.OnboardingFa.tile(section, MapSet.member?(chosen, section.id))
       end)
       |> Enum.intersperse(Kati.Screens.OnboardingFa.tile_gap())}
    </Row>
    """
  end

  # A chosen tile inverts to ink with an orange check; an unchosen one is an
  # ordinary card. See the moduledoc for why the badge needs no rtl-specific
  # code to land at 137's own top-left.
  @doc false
  def tile(section, chosen?) do
    tap = {self(), String.to_atom("section_" <> section.id)}
    background = if chosen?, do: Palette.ink_fill(), else: Palette.card()
    shadow = if chosen?, do: "0 12 24 -14 #E61A1917", else: Kati.Theme.shadow_card_soft()
    ink = if chosen?, do: Palette.on_ink(), else: Palette.ink()
    sub = if chosen?, do: Palette.on_ink_count(), else: Palette.muted()

    ~MOB"""
    <Box weight={1.0}>
      <Column
        fill_width={true}
        background={background}
        corner_radius={20}
        shadow={shadow}
        padding={16}
        on_tap={tap}
      >
        <Row fill_width={true} align="top">
          {UI.symbol(section.icon, size: 24, color: ink)}
          <Spacer weight={1.0} />
          {Kati.Screens.OnboardingFa.badge(chosen?)}
        </Row>
        <Spacer size={14} />
        <Text
          text={section.label}
          font_family="fa"
          font_weight="bold"
          text_size={14.5}
          text_color={ink}
          max_lines={1}
        />
        <Spacer size={4} />
        <Text text={section.sub} font_family="fa" text_size={11.5} text_color={sub} max_lines={1} />
      </Column>
    </Box>
    """
  end

  @doc """
  The 22pt orange check on a chosen tile, `PickSections.badge/1` unchanged.

  `0xFFFBFAF8` stays a literal rather than a `Palette` token for the same
  reason it does on 26: the ground under it is the accent, a hue that does not
  move with the mode, and none of the four tokens carrying that value names "a
  glyph on a hue." `offset_x`/`offset_y` are the 2pt nudge a wrap-height tile
  has no fill-height frame to align an overlay against otherwise — see
  `PickSections.badge/1`'s own moduledoc for the full account.
  """
  def badge(false), do: ~MOB"<Spacer size={0} />"

  def badge(true) do
    ~MOB"""
    <Box
      width={22}
      height={22}
      offset_x={2}
      offset_y={-2}
      corner_radius={11}
      background={Kati.Theme.accent()}
      align="center"
    >
      {UI.symbol("check", size: 14, color: 0xFFFBFAF8)}
    </Box>
    """
  end

  # No trailing arrow and a lighter shadow than `PickSections.commit/1` — both
  # 137's own numbers. See the moduledoc. The label is computed, not the
  # drawing's frozen ۲: three chosen reads "ادامه با ۳ بخش" the moment a third
  # tile is tapped.
  @doc false
  def cta(chosen) do
    label = "ادامه با #{Digits.to_persian(MapSet.size(chosen))} بخش"

    ~MOB"""
    <Column fill_width={true}>
      <Box
        fill_width={true}
        height={54}
        corner_radius={27}
        background={Palette.ink_fill()}
        shadow="0 14 28 -12 #801A1917"
        align="center"
      >
        <Text
          text={label}
          font_family="fa"
          font_weight="bold"
          text_size={14}
          text_color={Palette.on_ink()}
          max_lines={1}
        />
      </Box>
      <Spacer size={14} />
    </Column>
    """
  end

  # The one bold word is `Kati.UI.rich_text/1`'s approximation, not a real
  # per-run style — see the moduledoc's account of what the bridge can do.
  @doc false
  def note do
    body = [
      text_size: 12.5,
      line_height: 1.85,
      text_color: Palette.ink_soft(),
      font_family: "fa"
    ]

    strong = [
      font_weight: "semibold",
      text_color: :on_surface,
      text_size: 12.5,
      line_height: 1.85,
      font_family: "fa"
    ]

    paragraph =
      UI.rich_text([
        {"هفته از ", body},
        {"شنبه", strong},
        {" شروع می‌شود، تاریخ‌ها شمسی و ارقام فارسی‌اند — همه از انتخاب زبان در گام یک می‌آیند، " <>
           "نه از تنظیمی جدا.", body}
      ])

    pill =
      Kati.Components.MishkaPill.pill(
        %{
          background: :none,
          corner_radius: 18,
          border_color: Palette.border(),
          border_width: 1.5,
          padding: 15,
          fill_width: true,
          content_align: :top,
          content_fill_width: true,
          leading: UI.symbol("info", size: 17, color: Palette.sub()),
          leading_gap: 11
        },
        [paragraph]
      )

    ~MOB"""
    <Column fill_width={true}>
      {pill}
      <Spacer size={20} />
    </Column>
    """
  end

  # `justify-content:space-between` on two auto-width groups, not the
  # two-weighted-spacer centring `PickSections.commit/1` draws for its single
  # restore link: 137 puts a link at each end of the row, so one weighted
  # `Spacer` between the two groups is the whole of the translation. Both taps
  # land on their `Row`, not their `Text`, for `PickSections.commit/1`'s own
  # reason: a tap on bare text alone would miss everywhere but the glyphs.
  @doc false
  def footer do
    back = {self(), :back_to_welcome}
    restore = {self(), :restore_backup}

    ~MOB"""
    <Row fill_width={true} align="center">
      <Row align="center" on_tap={back}>
        {UI.symbol("arrow_forward", size: 17, color: Palette.sub())}
        <Spacer size={7} />
        <Text
          text="بازگشت به خوش‌آمد"
          font_family="fa"
          font_weight="semibold"
          text_size={13}
          text_color={Palette.sub()}
          max_lines={1}
        />
      </Row>
      <Spacer weight={1.0} />
      <Row align="center" on_tap={restore}>
        <Text
          text="بازگردانی از پشتیبان"
          font_family="fa"
          font_weight="semibold"
          text_size={13}
          text_color={Palette.sub()}
          max_lines={1}
        />
      </Row>
    </Row>
    """
  end
end
