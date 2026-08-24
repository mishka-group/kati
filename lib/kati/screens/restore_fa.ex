defmodule Kati.Screens.RestoreFa do
  @moduledoc """
  Screen 132 — بازگردانی از پشتیبان, the Persian mirror of Restore from a
  backup, pushed under تنظیمات.

  Built to `.scratch/design/incoming/132.html`, screen 129's mirror the way
  `Kati.Screens.MoneyFa` is 127's: 129 is `Kati.Screens.Restore`, and it
  landed only just before this file did, which is why `pick_sections.ex`'s
  own comment still says *"until screen 129 is built"* — that comment is now
  stale by one commit, not wrong forever, and it is not this file's place to
  edit it.

  ## What is 129's and reused unchanged, because neither carries Persian text

  Font is the only test, per `Kati.Screens.Fa`'s moduledoc: a node that draws
  no `Text` cannot draw the wrong one.

    * `Kati.Screens.Restore.scan_tile/0`, `qr_pattern/0`, `qr_row/1`,
      `qr_module/1` and `qr_gap/0` — the 74pt QR-shaped tile is forty-nine
      coloured boxes and not one glyph, so 129's own reading of the drawing's
      grid is this drawing's too. `132.html`'s grid is the same 49 cells in
      the same order; a second transcription would only be a second chance to
      mistype one.
    * `Kati.Screens.Restore.divider/0` — the bare hairline between the safe
      path and the destructive one.
    * `Kati.Screens.PlanImport.conflict_tile/1` — the 40pt `poster_on_cream`
      tile under a `gold_icon` `star`, which 129 already took from
      `PlanImport` for the same reason: no artwork, so no poster.
    * `Kati.Screens.Import.outcome_gap/0` and `choice_gap/0` — bare `Spacer`s,
      10pt and 8pt.

  Everything else in `Kati.Screens.Restore` builds its own `Text` and leaves
  `font_family` off, which is every unstyled `Text` in the app and therefore a
  row of empty boxes for Persian — `count_card/1`, `merge_note/0`,
  `conflict_card/2`'s title and star line, `merge_button/1`,
  `replace_card/1` and `replace_button/0` are rebuilt here. `Kati.Screens.Import.choice/1`
  is the one exception worth naming: it does not merely lack the prop, it
  passes `label:` as a **string prop**, which `Kati.Components.MishkaToggle`
  only ever hands to a `Text` it builds itself — so the fix is not adding
  `font_family` to a call site, it is switching doors. `choice/1` here passes
  the Persian label as **children**, the slot `Kati.Screens.Fa`'s moduledoc
  says the component actually has.

  ## The figures are `Kati.Backup.SampleRestore`'s, not retyped

  `129`'s own moduledoc traces `384 / 28 / 6` and `Blue Hour` back through
  `Kati.Backup.SampleRestore` to `Kati.Import.Sample`'s screen-37 fixture, and
  says why neither screen reaches past `SampleRestore` for them: a coincidence
  of mockup copy between a CSV import and a whole-device restore is not a
  claim that the two are one event. This file reaches no further than 129
  does — `SampleRestore.counts/0`, `conflict/0` and `replace/0` are read here
  exactly as they are read there, and only the *words* beside the numbers are
  this file's own. `new_count/1` reads the New card's own value for the
  merge button for the identical reason 129's does: a button and a card
  typing the same figure twice is how they stop agreeing.

  `conflict/0`'s `title` is the one field `SampleRestore` has no Persian for
  — it is a fixture module shared with the English screen and holds one
  string per field, not one per locale. `ساعت آبی` is not invented for this
  screen: `Kati.Screens.MoneyFa`'s `@expenses` already carries the same title
  under the same English key, `"Blue Hour"`, for screen 127's own Kino row.
  Two mirrors giving one film the same Persian name is the whole point of a
  shared fixture; a third name here would be the drift `SampleRestore`'s own
  moduledoc exists to rule out.

  ## Where a literal survives untranslated

  `kati-backup-2026-08-14.json` is `SampleRestore.file/0`, and it is not run
  through anything: a filename is an identifier, the same class of string
  `Kati.Screens.MyServicesFa`'s moduledoc keeps Latin for a screen number —
  and `132.html` draws it in plain ASCII digits itself, which is the drawing
  agreeing before this file does.

  There is no date on this board to carry to Shamsi. The one thing shaped
  like a date is inside that filename, and a filename Kati's own
  `Kati.Backup.Transport` writes byte-for-byte is not a display date to
  convert — it is a name a person might type back into a file browser, and
  `2026-08-14` has to still be there when they do.

  ## The three literals 129 could not promote to a token, and neither can this

  129's own moduledoc has the arithmetic for all three — `Palette.hairline_strong/0`
  at 10% against the drawing's 12%, the scan tile's own `"0 6 16 -8 #7378501E"`
  against `shadow_hero/0`'s adjacent-but-different warm brown, and
  `0x66B4553C` against `Palette.red_ring/0`'s 30% where the drawing wants 40.
  `132.html` draws the identical three numbers — RTL does not change an
  alpha — so this file keeps 129's answers rather than re-deriving them.

  ## Persian's own numbers, where 129's do not carry over

  `132.html` sets every multi-line Persian paragraph on this board at
  **1.85** — the merge note, the scan card's second line, the replace card's
  body — against **1.65** and **1.6** for the same sentences in English on
  129. That is not this file rounding up; it is what the drawing itself sets,
  for the reason every Persian screen's moduledoc gives: Arabic-script
  letters carry dots above the baseline and descenders below it, and at a
  Latin paragraph's leading the dots of one line collide with the descenders
  of the line above. Nothing here carries tracking either — 129's -.03em
  title and its -.03em mono figures both drop it, because letter-spacing
  pulls the joins between Arabic-script letters apart, which is also why the
  hero total's own em-dash of tracking is dropped from every figure below it.

  ## The mirrored default the caption names

  `132.html`'s caption is explicit: *"the conflict resolver's three buttons
  reverse with the container, putting **مال من** at the leading right edge
  where **Keep mine** sits on the left in 129 — same default, mirrored
  position."* Nothing here reverses the three choices by hand. `choice/1` is
  called in the same reading order `SampleRestore.conflict/0.choices` gives —
  مال من, فایل, هر دو — and `Kati.Screens.Fa.pushed_frame/1`'s `layout_direction="rtl"`
  is what puts the first one at the right. A `Row` lays out start-to-end in
  either direction; only the direction changed hands.

  ## Every figure keeps DM Mono is, again, the one thing that cannot be done

  `count_card/1`'s `384`, `28` and `6` are 129's own DM Mono figures, and
  `kati_mono.ttf` carries zero of U+06F0–U+06F9 — `Kati.Screens.Fa`'s
  moduledoc has the count. So the three tiles, the merge button's total and
  the conflict card's `۱ از ۶ · برای همه` progress line are all set in `fa` at
  129's own sizes and colours, with the tracking dropped. The face is wrong
  and the glyphs are right, the same half of the same unwinnable trade every
  other Persian screen takes.

  ## The star line is built, not translated word for word

  `Kati.Screens.Import.star_text/3` splits `"Yours ★4 · file says ★5"` on its
  literal `★` and types the two halves in whatever font it is handed — which,
  handed none, is Plus Jakarta Sans, the font with no Persian digits either.
  `star_line/1` here does the same split on a **Persian** sentence it builds
  first: the two numbers are read off `SampleRestore.conflict/0.line` with a
  regex exactly the way `Kati.Screens.MoneyFa.subtitle/0` reads its two counts
  off English, so `شما ★۴ · فایل می‌گوید ★۵` cannot disagree with the English
  card's `4` and `5` even though neither screen retypes them.

  ## Audited: this board draws, and nothing on it writes

  129's own Audited section is the reason as much as the precedent: there is
  nowhere yet to hold a picked file, a counted outcome or an answered
  conflict alive across two renders, English or Persian, so answering a
  conflict here would be forgotten the moment the screen popped.
  `Kati.Screens.Backup` is where that staging is real — `choose_file`,
  `:mode`, `Kati.Backup.inspect_file/2` and `restore_file/2` — and this board
  is a second, redesigned face on the same promise, not the one the app
  ships from yet. So no control here carries a tap except the one every
  pushed screen needs: the file row's chevron, the scan card, the three
  choice pills, Merge and Replace are all drawn, none of them wired, and
  `handle_info/2` answers exactly one tag.
  """

  use Mob.Screen
  import Mob.Sigil

  alias Kati.Backup.SampleRestore
  alias Kati.Components.MishkaPill
  alias Kati.Components.MishkaToggle
  alias Kati.I18n.Digits
  alias Kati.Screens.BookDetailFa
  alias Kati.Screens.Fa
  alias Kati.Screens.Import
  alias Kati.Screens.PlanImport
  alias Kati.Screens.Restore
  alias Kati.Screens.StatsFa
  alias Kati.Theme
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  # Every word `SampleRestore` does not carry — it holds the figures, this
  # holds the sentences around them. `conflict_title` is the one exception
  # explained in the moduledoc: `Kati.Screens.MoneyFa.@expenses` already gives
  # "Blue Hour" this exact Persian name.
  @copy %{
    back: "تنظیمات",
    title: "بازگردانی از پشتیبان",
    subtitle: "تا آخرین گام چیزی نوشته نمی‌شود",
    choose_file: "انتخاب فایل",
    pick_file: "انتخاب فایل",
    scan_title: "اسکن از گوشی دیگر",
    scan_lead: "فقط",
    scan_strong: "تنظیمات و برنامه‌ها",
    scan_tail: "را می‌آورد — کد QR جا برای یک کتابخانه ندارد.",
    what_happens: "چه اتفاقی می‌افتد",
    new: "تازه",
    merged: "ادغام",
    conflicts: "تعارض",
    merge_lead: "این دستگاه داده دارد، پس فایل با آن",
    merge_strong: "ادغام",
    merge_tail: "می‌شود. تا پایان آخرین تعارض چیزی نوشته نمی‌شود.",
    conflicts_eyebrow: "تعارض‌ها · کدام بماند؟",
    conflict_title: "ساعت آبی",
    star_mine: "شما",
    star_file: "فایل می‌گوید",
    of: "از",
    apply_all: "برای همه",
    merge_prefix: "ادغام",
    merge_suffix: "مورد",
    start_clean: "یا از نو",
    replace_title: "جایگزینی همه‌چیز روی این دستگاه",
    replace_lead: "هر",
    replace_noun: "عنوان",
    replace_tail:
      "، همه یادداشت‌ها و جلسه‌ها حذف می‌شوند و فایل جای آن‌ها نوشته می‌شود. " <>
        "بعد از پایان، بازگشتی نیست.",
    replace_button: "جایگزین کن…"
  }

  # مال من / فایل / هر دو, in the reading order `SampleRestore.conflict/0`'s
  # own `choices` list gives — see the moduledoc on why that order and not a
  # reversed one is what mirrors 129's "Keep mine" default.
  @choice_labels ["مال من", "فایل", "هر دو"]

  @doc "Mount. Nothing here is per-instance state — see Audited in the moduledoc."
  @spec mount(map(), map(), Mob.Socket.t()) :: {:ok, Mob.Socket.t()}
  def mount(_params, _session, socket) do
    Kati.Theme.activate()
    {:ok, socket}
  end

  @doc """
  The page inside a root node that declares `rtl`.

  `Kati.Screens.Fa.pushed_frame/1` rather than `Kati.Screens.Restore`'s own
  `use Kati.Screens.Pushed, back: "Settings"`: that macro takes its direction
  from `Kati.Locale.direction_prop/0`, the app's own setting, and draws its
  back pill with `arrow_back_ios_new` beside a `Text` carrying no
  `font_family` — a left-pointing chevron beside a row of empty boxes.
  """
  @spec render(map()) :: map()
  def render(assigns), do: Fa.pushed_frame(content(assigns))

  @doc "The page, in the order 132 stacks it — 129's own order, unchanged."
  @spec content(map()) :: map()
  def content(_assigns) do
    job = SampleRestore

    # Bound to a local, and this is the trap `Kati.Screens.Gallery.content/1`
    # records in the same words: **inside `~MOB` an `@name` is an ASSIGN**, so
    # `@copy.choose_file` compiles to `assigns.copy.choose_file` and dies with
    # `key :copy not found in %{}` the first time the screen renders. The
    # module attribute has to be lifted out before the sigil.
    #
    # It does not fail at compile time and it does not fail in a unit test that
    # calls the builder functions directly — only a real render finds it, which
    # is what `Kati.TapHandleBudgetTest` did.
    copy = @copy

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {Kati.Screens.RestoreFa.chrome()}
        {Kati.Screens.RestoreFa.title()}
        {Fa.eyebrow(copy.choose_file)}
        {Kati.Screens.RestoreFa.file_row(job.file())}
        {Kati.Screens.RestoreFa.scan_card()}
        {Fa.eyebrow(copy.what_happens)}
        {Kati.Screens.RestoreFa.count_row(job.counts())}
        {Kati.Screens.RestoreFa.merge_note()}
        {Fa.eyebrow(copy.conflicts_eyebrow)}
        {Kati.Screens.RestoreFa.conflict_card(job.conflict())}
        {Kati.Screens.RestoreFa.merge_button(Restore.new_count(job.counts()))}
        {Restore.divider()}
        {StatsFa.quiet_eyebrow(copy.start_clean)}
        {Kati.Screens.RestoreFa.replace_card(job.replace())}
      </Column>
    </Scroll>
    """
  end

  # ── Chrome and headline ──────────────────────────────────────────────────────

  @doc """
  The back pill, with no trailing disc — `132.html` draws none, where
  `Kati.Screens.MoneyFa.chrome/0` draws a `more_horiz` one for 127's own menu.
  Hand-rolled for the reason every Persian mirror's chrome is: the shared
  pill types its parent's name in a font with no Persian glyphs.
  """
  @spec chrome() :: map()
  def chrome do
    word = BookDetailFa.fa(@copy.back, 13.5, :on_surface, weight: "semibold")
    chevron = UI.symbol("arrow_forward_ios", size: 17)

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Row
          height={44}
          corner_radius={22}
          background={Palette.card()}
          shadow={Theme.shadow_button()}
          padding_left={12}
          padding_right={16}
          align="center"
          on_tap={{self(), :back}}
        >
          {chevron}
          <Spacer size={6} />
          {word}
        </Row>
        <Spacer weight={1.0} />
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc """
  The 25pt headline over its warning line.

  Not 129's 28 at -.03em over an 11.5pt mono caps line: Persian tracking
  breaks the joins between Arabic-script letters, and `132.html` sets its own
  headline at 25 with no tracking, over a 12.5pt Vazirmatn sub in `muted` —
  the exact numbers `Kati.Screens.MoneyFa.title/0` gives for 127's own
  headline, because a warning that will not be read like the drawing's own
  emphasis is not read.
  """
  @spec title() :: map()
  def title do
    heading = BookDetailFa.fa(@copy.title, 25, :on_surface, weight: "bold")
    sub = BookDetailFa.fa(@copy.subtitle, 12.5, Palette.muted())

    ~MOB"""
    <Column fill_width={true}>
      {heading}
      <Spacer size={6} />
      {sub}
      <Spacer size={20} />
    </Column>
    """
  end

  # ── Choose a file ────────────────────────────────────────────────────────────

  @doc """
  The single-row card offering the picked file.

  `132.html` prints the same word — انتخاب فایل — for both this row's title
  and the eyebrow above it; that repetition is the drawing's own, not a typo
  this file corrects once. `chevron_left`, not `Kati.UI.SettingsList.chevron/0`'s
  `chevron_right`: a row that leads elsewhere leads in the reading direction,
  and in Persian that is leftward.
  """
  @spec file_row(String.t()) :: map()
  def file_row(name) do
    body = Kati.Screens.RestoreFa.file_body(name)
    trailing = UI.symbol("chevron_left", size: 18, color: Palette.rail_idle())
    row = SettingsList.row(SettingsList.icon_tile("upload_file"), body, trailing, rule: false)

    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.card([row])}
      <Spacer size={11} />
    </Column>
    """
  end

  @doc false
  def file_body(name) do
    title = BookDetailFa.fa(@copy.pick_file, 13.5, :on_surface, weight: "semibold")
    sub = BookDetailFa.fa(name, 11.5, Palette.sub())

    ~MOB"""
    <Column fill_width={true}>
      {title}
      <Spacer size={3} />
      {sub}
    </Column>
    """
  end

  @doc """
  The cream card offering a QR handoff, the tile itself borrowed whole from
  `Kati.Screens.Restore.scan_tile/0` — see the moduledoc.
  """
  @spec scan_card() :: map()
  def scan_card do
    title = BookDetailFa.fa(@copy.scan_title, 13.5, Palette.cream_ink(), weight: "bold")
    sub = Kati.Screens.RestoreFa.scan_sub()

    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Palette.cream()}
        corner_radius={20}
        padding={16}
        align="center"
      >
        {Restore.scan_tile()}
        <Spacer size={14} />
        <Column weight={1.0}>
          {title}
          <Spacer size={5} />
          {sub}
        </Column>
      </Row>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  `فقط تنظیمات و برنامه‌ها را می‌آورد — کد QR جا برای یک کتابخانه ندارد.`

  Set at **1.85**, against 129's 1.6 for the same sentence — see the
  moduledoc on why Persian's own leading is not English's rounded up.
  """
  @spec scan_sub() :: map()
  def scan_sub do
    body = [
      font_family: "fa",
      text_size: 11.5,
      line_height: 1.85,
      text_color: Palette.cream_sub()
    ]

    strong = [
      font_family: "fa",
      font_weight: "semibold",
      text_color: Palette.cream_ink()
    ]

    UI.rich_text([
      {@copy.scan_lead <> " ", body},
      {@copy.scan_strong, strong},
      {" " <> @copy.scan_tail, Keyword.put(body, :base, true)}
    ])
  end

  # ── What will happen ─────────────────────────────────────────────────────────

  @doc "The three count cards. See `count_card/1` for why they cannot be `Kati.Screens.PlanImport.count_card/1`."
  @spec count_row([map()]) :: map()
  def count_row(cards) do
    tiles =
      cards
      |> Enum.map(fn card -> Kati.Screens.RestoreFa.count_card(card) end)
      |> Enum.intersperse(Import.outcome_gap())

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        {tiles}
      </Row>
      <Spacer size={11} />
    </Column>
    """
  end

  @doc """
  One count tile: `129`'s own figure and tone, this file's own label and
  face. `card.tone` is `:ink`, `:green` or `:red` — `SampleRestore.counts/0`'s
  own atoms, read the same way `Kati.Screens.PlanImport.count_card/1` reads
  them so the two screens cannot disagree about which count means which
  colour, only about which font draws it.
  """
  @spec count_card(map()) :: map()
  def count_card(card) do
    color =
      case card.tone do
        :ink -> Palette.ink()
        :green -> Palette.green()
        :red -> Palette.red()
      end

    label = Kati.Screens.RestoreFa.count_label(card.label)
    value = Digits.to_persian(card.value)

    ~MOB"""
    <Box weight={1.0}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={18}
        shadow={Theme.shadow_card_soft()}
        padding={14}
      >
        <Text
          text={value}
          font_family="fa"
          text_size={22}
          font_weight="medium"
          text_color={color}
          text_align="center"
          max_lines={1}
        />
        <Spacer size={5} />
        <Text
          text={label}
          font_family="fa"
          font_weight="semibold"
          text_size={10.5}
          text_color={Palette.muted()}
          text_align="center"
          max_lines={1}
        />
      </Column>
    </Box>
    """
  end

  @doc false
  def count_label("New"), do: @copy.new
  def count_label("Merged"), do: @copy.merged
  def count_label("Conflicts"), do: @copy.conflicts

  @doc """
  The dashed-frame note. Not `Kati.UI.SettingsList.note/2` for the reason
  `Kati.Screens.Restore.merge_note/0`'s own doc gives — this board's 15pt
  padding and 17pt glyph are not that helper's 16 and 18, and the sentence
  needs a bold word mid-paragraph, which `note/2`'s plain-string `text`
  cannot carry.
  """
  @spec merge_note() :: map()
  def merge_note do
    body = [font_family: "fa", text_size: 12.5, line_height: 1.85, text_color: Palette.ink_soft()]
    strong = [font_family: "fa", font_weight: "semibold", text_color: :on_surface]

    sentence =
      UI.rich_text([
        {@copy.merge_lead <> " ", body},
        {@copy.merge_strong, strong},
        {" " <> @copy.merge_tail, Keyword.put(body, :base, true)}
      ])

    card =
      MishkaPill.pill(
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
        [sentence]
      )

    ~MOB"""
    <Column fill_width={true}>
      {card}
      <Spacer size={24} />
    </Column>
    """
  end

  # ── Conflicts · which stays? ─────────────────────────────────────────────────

  @doc """
  The open conflict, on cream. `Kati.Screens.PlanImport.conflict_tile/1`
  reused whole — it draws no text — everything beside it rebuilt.
  """
  @spec conflict_card(map()) :: map()
  def conflict_card(c) do
    title = BookDetailFa.fa(@copy.conflict_title, 13, :on_surface, weight: "bold")
    line = Kati.Screens.RestoreFa.star_line(c.line)

    choices =
      @choice_labels
      |> Enum.zip(c.choices)
      |> Enum.map(fn {label, {_english, primary?}} ->
        Kati.Screens.RestoreFa.choice(label, primary?)
      end)
      |> Enum.intersperse(Import.choice_gap())

    progress =
      BookDetailFa.fa(Kati.Screens.RestoreFa.progress(c.progress), 10.5, Palette.cream_meta(),
        align: "center"
      )

    ~MOB"""
    <Column fill_width={true}>
      <Column fill_width={true} background={Palette.cream()} corner_radius={20} padding={15}>
        <Row fill_width={true} align="center">
          {PlanImport.conflict_tile(c.icon)}
          <Spacer size={12} />
          <Column weight={1.0}>
            {title}
            <Spacer size={3} />
            {line}
          </Column>
        </Row>
        <Spacer size={13} />
        <Row fill_width={true} align="center">
          {choices}
        </Row>
        <Spacer size={12} />
        {progress}
      </Column>
      <Spacer size={24} />
    </Column>
    """
  end

  @doc """
  `شما ★۴ · فایل می‌گوید ★۵`, built rather than translated — see the
  moduledoc on why this is not `Kati.Screens.Import.star_text/3`.
  """
  @spec star_line(String.t()) :: map()
  def star_line(line) do
    [mine, file] = Regex.scan(~r/\d+/, line) |> List.flatten()

    text =
      @copy.star_mine <>
        " ★" <>
        Digits.to_persian(mine) <>
        " · " <> @copy.star_file <> " ★" <> Digits.to_persian(file)

    parts =
      text
      |> String.split("★")
      |> Enum.map(&Kati.Screens.RestoreFa.star_part/1)
      |> Enum.intersperse(Kati.Screens.RestoreFa.star_glyph())

    ~MOB"""
    <Row align="center">
      {parts}
    </Row>
    """
  end

  @doc false
  def star_part(part), do: BookDetailFa.fa(part, 11.5, Palette.cream_sub())

  @doc false
  def star_glyph, do: UI.symbol("star", size: 11.5, color: Palette.cream_sub(), fill: true)

  @doc "`۱ از ۶ · برای همه`, its two numbers read off `SampleRestore.conflict/0.progress` rather than retyped."
  @spec progress(String.t()) :: String.t()
  def progress(text) do
    [current, total] = Regex.scan(~r/\d+/, text) |> List.flatten()

    Digits.to_persian(current) <>
      " " <> @copy.of <> " " <> Digits.to_persian(total) <> " · " <> @copy.apply_all
  end

  @doc """
  One answer pill: `مال من`, `فایل` or `هر دو`, at 129's own geometry.

  `Kati.Components.MishkaToggle` takes the label as **children** here rather
  than as `label:` — see the moduledoc on why `Kati.Screens.Import.choice/1`
  cannot be called with a Persian string at all.
  """
  @spec choice(String.t(), boolean()) :: map()
  def choice(label, primary?) do
    colour = if primary?, do: Palette.on_ink(), else: Palette.cream_sub()
    text = BookDetailFa.fa(label, 11.5, colour, weight: "semibold")

    button =
      MishkaToggle.toggle(
        [
          pressed: primary?,
          color: Palette.ink_fill(),
          background: Palette.cream_raise(),
          corner_radius: 16,
          height: 32,
          padding: 0,
          border_width: 0,
          fill_width: true,
          align: :center
        ],
        [text]
      )

    ~MOB"""
    <Box weight={1.0}>
      {button}
    </Box>
    """
  end

  @doc "The single ink CTA. `new_count` is `Kati.Screens.Restore.new_count/1`'s reading, not a fourth typed `384`."
  @spec merge_button(String.t()) :: map()
  def merge_button(new_count) do
    label = @copy.merge_prefix <> " " <> Digits.to_persian(new_count) <> " " <> @copy.merge_suffix
    text = BookDetailFa.fa(label, 14, Palette.on_ink(), weight: "bold")

    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        height={54}
        corner_radius={27}
        background={Palette.ink_fill()}
        shadow="0 14 28 -12 #801A1917"
        align="center"
      >
        {text}
      </Row>
      <Spacer size={24} />
    </Column>
    """
  end

  # ── Or start clean ───────────────────────────────────────────────────────────

  @doc """
  The destructive card naming what Replace deletes.

  `r.count` is `SampleRestore.replace/0`'s own `"418"`, folded to Persian
  digits rather than retyped; `r.noun` — `"titles"` — is this file's own
  عنوان, because `SampleRestore` holds one string per field and not one per
  locale, exactly as `conflict/0.title` does not carry Persian either.
  """
  @spec replace_card(map()) :: map()
  def replace_card(r) do
    title = BookDetailFa.fa(@copy.replace_title, 13.5, Palette.red(), weight: "bold")
    button = Kati.Screens.RestoreFa.replace_button()

    text =
      @copy.replace_lead <>
        " " <> Digits.to_persian(r.count) <> " " <> @copy.replace_noun <> @copy.replace_tail

    body = ~MOB"""
    <Text
      text={text}
      font_family="fa"
      text_size={12.5}
      line_height={1.85}
      text_color={Palette.ink_soft()}
    />
    """

    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={22}
      shadow={Theme.shadow_card_soft()}
      padding={17}
    >
      <Row fill_width={true} align="top">
        {UI.symbol("error", size: 19, color: Palette.red())}
        <Spacer size={11} />
        <Column weight={1.0}>
          {title}
          <Spacer size={6} />
          {body}
        </Column>
      </Row>
      <Spacer size={14} />
      {button}
    </Column>
    """
  end

  @doc """
  The outlined red row, at `Kati.Screens.Restore.replace_button/0`'s own
  `0x66B4553C` — see 129's moduledoc for why that stays a literal rather than
  `Palette.red_ring/0`, which is 30% where the drawing wants 40.
  """
  @spec replace_button() :: map()
  def replace_button do
    text = BookDetailFa.fa(@copy.replace_button, 12.5, Palette.red(), weight: "bold")

    ~MOB"""
    <Row
      fill_width={true}
      height={44}
      corner_radius={22}
      border_color={Palette.red_ring_strong()}
      border_width={1.5}
      align="center"
    >
      {text}
    </Row>
    """
  end

  # ── The tap ─────────────────────────────────────────────────────────────────

  @doc "The one tap this board draws. See Audited in the moduledoc for why there is only one."
  @spec handle_info(term(), Mob.Socket.t()) :: {:noreply, Mob.Socket.t()}
  def handle_info({:tap, :back}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}
  def handle_info({:tap, _tag}, socket), do: {:noreply, socket}
  def handle_info(_message, socket), do: {:noreply, socket}
end
