defmodule Kati.Screens.PlanShare do
  @moduledoc """
  Screen 50 — share, import & export a plan, pushed under Plans.

  Built to `test/design/screens/50.html`. A plan is a portable document:
  a QR code or a link hands it over, an explicit list states what travels with
  it, and history never leaves the device. Import accepts the same file export
  produces, which is the only reason the two live on one screen.

  The QR sits on cream — the palette's one warm surface, used here for the same
  reason screen 08 uses it for a note: this block is *yours to give away*
  rather than metadata about the plan.

  **Shared with** draws two different trailing controls on purpose. Following
  is revocable, so it is a switch; a copy someone already took is a past event,
  so it is a glyph. A switch there would imply a power the app does not have.

  All three lists are `Kati.UI.SettingsList`; the people rows pass their own
  body because the drawing sets a person at 13/11 rather than the settings
  family's 13.5/11.5, and their avatar is a 34pt circle rather than a tile.

  No dock, so the frame's bottom inset is 40 rather than 132.
  """
  use Kati.Screens.Pushed, back: "Plans"
  use Gettext, backend: Kati.Gettext

  alias Kati.Meals.SampleShare
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  # ── The figures the drawing froze into prose ──────────────────────────────
  #
  # `Kati.Meals.SampleShare` writes each of these INSIDE a sentence — `All 35,
  # with photos` and `not the 35 meals`, `2,100 kcal · macro split`, `Took a
  # copy · 12 Aug` — so `share/0` carries no field to read them from, and a
  # msgid that swallowed them would freeze Latin digits and a Gregorian month
  # inside the Persian string, where no translator can convert them without
  # freezing them again. Held here instead and rendered through `Kati.Locale`,
  # which is the one thing in the app that knows 12 August 2026 and
  # ۲۱ مرداد ۱۴۰۵ are the same day — a different CALENDAR rather than the same
  # date translated.
  #
  # `@meals` is held once rather than twice because the drawing spells it in
  # two different sentences and they must not drift. mishka-group/kati#103.
  @meals 35
  @kcal "2,100"
  @copy_taken ~D[2026-08-12]

  # The sentence `Kati.Meals.SampleShare.qr_body/0` builds, joined. A plain
  # string attribute rather than a `<>` in the function head, so the pattern is
  # one literal a reader can compare against the fixture by eye. It is data,
  # not a `gettext/1` call, so nothing about it is evaluated in the compiler's
  # locale — the trap that turns a translated table into whichever language
  # `mix compile` happened to be in.
  @carried_line "Carries the targets, meal times and reminder settings — not the 35 meals. The recipient gets an empty Cutting v3 to fill with their own."

  @impl true
  def load(socket), do: Mob.Socket.assign(socket, :share, SampleShare.share())

  @doc false
  def content(assigns) do
    share = assigns.share
    plan = Kati.Screens.PlanShare.plan_name(share.plan)
    subtitle = Kati.Screens.PlanShare.plan_subtitle(share.subtitle)

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
        {SettingsList.title(plan, subtitle, nil, :meta_tight)}
        {Kati.Screens.PlanShare.qr_card(share)}
        {UI.eyebrow(gettext("What travels with it"))}
        {Kati.Screens.PlanShare.travels(share.travels)}
        {SettingsList.eyebrow_muted(gettext("Shared with"))}
        {Kati.Screens.PlanShare.shared_with(share.shared_with)}
        {SettingsList.eyebrow_muted(gettext("Import & export"))}
        {Kati.Screens.PlanShare.transfer(share.transfer)}
      </Column>
    </Scroll>
    """
  end

  # ── Copy ──────────────────────────────────────────────────────────────────
  #
  # `Kati.Meals.SampleShare` holds this page's words and this screen may not
  # edit it, so every string is translated where it is DRAWN: the fixture is
  # matched on the English it ships and answered with the msgid for it.
  #
  # Two things make that safe rather than clever. Every function below ends in
  # a clause that answers whatever it was handed, so copy someone rewords draws
  # its new English instead of raising inside a render — the contract
  # `Kati.Screens.MealEdit.slot_label/1` and
  # `Kati.Screens.OnboardingFirstTitle.label_for/1` already keep — and if
  # `Kati.Meals.SampleShare` is ever folded itself, the Persian it starts
  # returning falls through that same clause untouched rather than being looked
  # up a second time.
  #
  # And the two row lists are matched on their ICON rather than their title,
  # for the reason `tile_tap/1` states further down: *the title is copy and
  # copy is translated; the icon is the row's identity*. A translated row keeps
  # the tap it had, and the two functions agree about which row they are on.
  #
  # mishka-group/kati#103.

  @doc """
  The plan's name.

  `gettext("Cutting v3")` is already the catalogue's — `Kati.Meals.SamplePlan`
  and `Kati.Meals.SampleToday` both spell it — so this reuses that entry rather
  than opening a second one. One plan with two names is the defect the
  provider-name rule exists to prevent, and it applies just as hard inside the
  app's own vocabulary.
  """
  @spec plan_name(String.t()) :: String.t()
  def plan_name("Cutting v3"), do: gettext("Cutting v3")
  def plan_name(other), do: other

  @doc """
  The meta line under the title.

  Lower case in the msgid because the drawing sets it lower case: it is a
  label under a heading, not a sentence. `Kati.UI.SettingsList.subtitle/2`
  already asks `Kati.Locale.mono_face/0` for the face, so the Persian is set in
  Vazirmatn rather than handed to DM Mono, which carries no Persian glyph.
  """
  @spec plan_subtitle(String.t()) :: String.t()
  def plan_subtitle("share & transfer"), do: gettext("share & transfer")
  def plan_subtitle(other), do: other

  @doc "The cream card's heading."
  @spec qr_title(String.t()) :: String.t()
  def qr_title("Scan to set up this plan"), do: gettext("Scan to set up this plan")
  def qr_title(other), do: other

  @doc """
  What the card says the code carries — board 316's sentence, in the reader's
  language.

  The meal count and the plan's name come OUT of the sentence and back in as
  interpolations. Both are things a Persian reader has to be able to read:
  `35` set in Latin digits on a Shamsi page is exactly what
  `Kati.Locale.number/1` exists to stop, and the plan's name is a msgid
  everywhere else in the app, so spelling it again inside a paragraph is how
  one plan ends up with two names.
  """
  @spec qr_body(map()) :: String.t()
  def qr_body(%{qr_body: @carried_line, plan: plan}) do
    gettext(
      "Carries the targets, meal times and reminder settings — not the %{n} meals. The recipient gets an empty %{plan} to fill with their own.",
      n: Kati.Locale.number(@meals),
      plan: Kati.Screens.PlanShare.plan_name(plan)
    )
  end

  def qr_body(%{qr_body: other}), do: other

  @doc """
  A **What travels with it** or **Import & export** row's title.

  One closed list rather than two, because `tile_rows/1` draws both and the
  eight icons are distinct across them.
  """
  @spec row_title(map()) :: String.t()
  def row_title(%{icon: "restaurant"}), do: gettext("Meals & recipes")
  def row_title(%{icon: "monitor_heart"}), do: gettext("Targets")
  def row_title(%{icon: "notifications"}), do: gettext("Reminder times")
  def row_title(%{icon: "history"}), do: gettext("Your history & notes")
  def row_title(%{icon: "qr_code_scanner"}), do: gettext("Scan a plan")
  def row_title(%{icon: "upload_file"}), do: gettext("Import a file")
  def row_title(%{icon: "download"}), do: gettext("Export this plan")
  def row_title(%{icon: "picture_as_pdf"}), do: gettext("Print the week")
  def row_title(%{title: title}), do: title

  @doc """
  The same row's sub-line.

  `JSON` and `CSV` stay in Latin inside the Persian sentence, which is what the
  catalogue already does — `CSV، JSON یا پشتیبان دیگر` — because a file format
  is a machine's name for itself and transliterating one would spell it two
  ways across the app.
  """
  @spec row_sub(map()) :: String.t()
  def row_sub(%{icon: "restaurant"}),
    do: gettext("All %{n}, with photos", n: Kati.Locale.number(@meals))

  # `2,100` groups with a LATIN comma in both scripts and converts its digits —
  # board 59 draws `۱,۴۸۰` — which is a thing `Kati.Locale.number/1` does and a
  # translator cannot do inside a msgstr without freezing the figure.
  def row_sub(%{icon: "monitor_heart"}),
    do: gettext("%{kcal} kcal · macro split", kcal: Kati.Locale.number(@kcal))

  def row_sub(%{icon: "notifications"}), do: gettext("Recipient can change them")

  # Two words, and `Never backed up` is already in the catalogue — near enough
  # that `mix gettext.merge` would offer it as a fuzzy match and a fuzzy entry
  # does not render. The context makes this its own entry, which is the whole
  # reason `pgettext/2` is the rule for anything this short.
  def row_sub(%{icon: "history"}),
    do: pgettext("what a shared plan leaves behind", "Never shared")

  def row_sub(%{icon: "qr_code_scanner"}), do: gettext("From a QR code or link")
  def row_sub(%{icon: "upload_file"}), do: gettext("JSON, CSV, or a recipe URL")
  def row_sub(%{icon: "download"}), do: gettext("JSON · portable, human-readable")
  def row_sub(%{icon: "picture_as_pdf"}), do: gettext("One page, fridge-sized")
  def row_sub(%{sub: sub}), do: sub

  @doc """
  What a **Shared with** row says under the name.

  Matched on the avatar seed rather than on the name, because the name is the
  one string on this row that is *not* copy — see `person_body/1`.
  """
  @spec person_sub(map()) :: String.t()
  def person_sub(%{seed: "face32"}), do: gettext("Following · gets your edits")

  # `12 Aug` arrived as frozen English and a Gregorian month, so a Persian
  # reader was shown a date from a calendar they do not keep — and a date is
  # the half of mishka-group/kati#103 gettext cannot do, because ۲۱ مرداد ۱۴۰۵
  # is not a formatting of 12 August 2026 but an arithmetic on it. The day is
  # the drawing's own; `@copy_taken` carries it because the fixture spelled it
  # into prose and left no field to read.
  def person_sub(%{seed: "face45"}),
    do: gettext("Took a copy · %{date}", date: Kati.Locale.date(@copy_taken, :short))

  def person_sub(%{sub: sub}), do: sub

  @doc false
  def qr_card(share) do
    # The mono URI line stays in Latin. `KATI://PLAN/CUTTING-V3` is a URI, and
    # the scope after it is `Kati.Meals.SampleShare.qr_scope/0`, which screen
    # 120 prints as well — *"two copies of one URI is how that claim quietly
    # stops being true"* — so this screen is not the place to take it apart.
    # Nothing is lost by leaving it: the sentence directly above says the same
    # thing in the reader's language, which is board 316's whole point.
    #
    # So the face is asked by SCRIPT rather than by reader. `mono_face/1`
    # answers `mono` for pure ASCII, which this is and which DM Mono has every
    # glyph for, and switches to Vazirmatn by itself the day the scope half is
    # folded. `mono_face/0` would move it to Vazirmatn for a Persian reader
    # today and lose the monospaced look of a machine-readable line for nothing.
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.cream()}
        corner_radius={24}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={20}
      >
        <Row fill_width={true} align="center">
          <Spacer weight={1.0} />
          {Kati.Screens.PlanShare.qr_plate(share.qr)}
          <Spacer weight={1.0} />
        </Row>
        <Spacer size={16} />
        <Text
          text={Kati.Screens.PlanShare.qr_title(share.qr_title)}
          text_size={15}
          font_weight="bold"
          text_color={:on_surface}
          text_align="center"
          max_lines={1}
        />
        <Spacer size={7} />
        <Text
          text={Kati.Screens.PlanShare.qr_body(share)}
          text_size={12.5}
          line_height={1.65}
          text_color={Palette.cream_sub()}
          text_align="center"
        />
        <Spacer size={10} />
        <Text
          text={share.qr_uri}
          font_family={Kati.Locale.mono_face(share.qr_uri)}
          text_size={10.5}
          text_color={Palette.cream_meta()}
          text_align="center"
          max_lines={1}
        />
        <Spacer size={16} />
        {Kati.Screens.PlanShare.qr_actions()}
        <Spacer size={9} />
        {Kati.Screens.PlanShare.whole_plan()}
      </Column>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc """
  Board 316's ink row: the route that DOES carry the meals.

  The card above it now says what the code cannot hold, and 316's rule is that
  saying so is only half of it — *"the ink button offers the route that does
  carry the meals — the file, which 128 already built."* So the row goes to
  screen 128, which is the only thing in this app that writes a file with the
  meals in it.

  It sits under `qr_actions/0` rather than replacing `Copy link`, because both
  of those are true about the code and neither stopped being an affordance;
  what was missing was an answer to *then how do I send the rest*.
  """
  @spec whole_plan() :: map()
  def whole_plan do
    ~MOB"""
    <Box
      fill_width={true}
      height={42}
      corner_radius={21}
      background={0xA6FFFFFF}
      align="center"
      on_tap={{self(), :send_whole_plan}}
    >
      <Row align="center">
        {Kati.UI.symbol("upload_file", size: 17, color: Palette.gold_text())}
        <Spacer size={7} />
        <Text
          text={gettext("Send the whole plan")}
          text_size={12.5}
          font_weight="semibold"
          text_color={Palette.cream_sub()}
          max_lines={1}
        />
      </Row>
    </Box>
    """
  end

  # 9 modules of 8pt with 2pt gaps is 88pt, centred inside a 120pt plate —
  # the drawing's own arithmetic, kept so the quiet zone stays 16pt on each
  # side rather than whatever a percentage would land on.
  #
  # ## Why the plate does not follow the mode
  #
  # `Palette.card(:light)` and `Palette.ink(:light)`, pinned, and they are the
  # only pinned colours on this screen. A QR code is a MACHINE-readable mark,
  # which puts it in the family `Kati.Theme.Palette` calls `:media` — "a colour
  # whose ground is a photograph ... a photograph does not get lighter when the
  # app does". Let the plate follow the mode and the code inverts: light
  # modules on a dark plate, which most readers will not decode, and the plate
  # itself (`#1E1D1B`) sinks BELOW the cream card it is supposed to lift off
  # (`#2A2622`), so the shadow reads as a hole. Light mode is untouched either
  # way — `Palette.card(:light)` is `0xFFFBFAF8` exactly, the value that was
  # written here before.
  @doc false
  def qr_plate(rows) do
    ~MOB"""
    <Box
      width={120}
      height={120}
      corner_radius={20}
      background={Palette.card(:light)}
      shadow="0 8 20 -10 #8078501E"
      align="center"
    >
      <Column>
        {rows
         |> Enum.map(fn row -> Kati.Screens.PlanShare.qr_row(row) end)
         |> Enum.intersperse(Kati.Screens.PlanShare.qr_gap())}
      </Column>
    </Box>
    """
  end

  @doc false
  def qr_gap, do: ~MOB"<Spacer size={2} />"

  @doc false
  def qr_row(row) do
    ~MOB"""
    <Row>
      {row
       |> String.graphemes()
       |> Enum.map(fn cell -> Kati.Screens.PlanShare.qr_module(cell) end)
       |> Enum.intersperse(Kati.Screens.PlanShare.qr_gap())}
    </Row>
    """
  end

  @doc false
  def qr_module("1") do
    ~MOB"<Box width={8} height={8} corner_radius={1} background={Palette.ink(:light)} />"
  end

  def qr_module(_light), do: ~MOB"<Box width={8} height={8} />"

  # `0xA6FFFFFF` is LEFT as a literal. It is `rgba(255,255,255,.65)` — a patch
  # raised a step off the cream card, which is exactly what
  # `Kati.Theme.Palette`'s `cream_raise/0` means — but `cream_raise` is
  # `0x99FFFFFF`, .60 rather than .65, and taking it would move light-mode
  # pixels by an alpha step. The only token whose LIGHT value is `0xA6FFFFFF`
  # is `lock_ink_65`, a `:media` colour that means "a lock-screen widget's
  # second line over the wallpaper" and is deliberately IDENTICAL in dark;
  # 65% white over the dark cream card is not what this pill wants. Neither
  # token fits, so the palette owns the answer, not this screen.
  @doc false
  def qr_actions do
    ~MOB"""
    <Row fill_width={true} align="center">
      <Box weight={1.0}>
        <Box
          fill_width={true}
          height={42}
          corner_radius={21}
          background={Palette.ink_fill()}
          align="center"
        >
          <Row align="center">
            {Kati.UI.symbol("link", size: 17, color: Palette.on_ink())}
            <Spacer size={7} />
            <Text
              text={gettext("Copy link")}
              text_size={12.5}
              font_weight="semibold"
              text_color={Palette.on_ink()}
              max_lines={1}
            />
          </Row>
        </Box>
      </Box>
      <Spacer size={9} />
      <Box weight={1.0}>
        <Box fill_width={true} height={42} corner_radius={21} background={0xA6FFFFFF} align="center">
          <Row align="center">
            {Kati.UI.symbol("ios_share", size: 17, color: Palette.gold_text())}
            <Spacer size={7} />
            <Text
              text={gettext("Share")}
              text_size={12.5}
              font_weight="semibold"
              text_color={Palette.cream_sub()}
              max_lines={1}
            />
          </Row>
        </Box>
      </Box>
    </Row>
    """
  end

  @doc false
  def travels(rows) do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.card(Kati.Screens.PlanShare.tile_rows(rows))}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc false
  def transfer(rows) do
    Kati.UI.SettingsList.card(Kati.Screens.PlanShare.tile_rows(rows))
  end

  # One row shape for both lists. A row that carries an `on` key is a promise
  # you can revoke, so it gets a switch; one that does not is a disclosure.
  #
  # **Print the week** is the one row here with somewhere to go.
  # `Kati.Screens.WeekImage` is screen 121, and 121's own caption says what it
  # is for: *the recommended replacement for a PDF that has no implementation
  # path*. This row drew `picture_as_pdf · One page, fridge-sized` and reached
  # nothing, because the thing it promised did not exist; it does now, and it is
  # a page rather than a PDF. The row's drawn pixels are unchanged — `on_tap` on
  # the wrapping `Column` adds no ink.
  @doc false
  def tile_rows(rows) do
    last = length(rows) - 1

    rows
    |> Enum.with_index()
    |> Enum.map(fn {row, i} ->
      SettingsList.row(
        SettingsList.icon_tile(row.icon),
        SettingsList.body(
          Kati.Screens.PlanShare.row_title(row),
          Kati.Screens.PlanShare.row_sub(row)
        ),
        Kati.Screens.PlanShare.tile_trail(row),
        rule: i < last,
        on_tap: Kati.Screens.PlanShare.tile_tap(row)
      )
    end)
  end

  @doc """
  The tap a transfer row carries, or `nil` for the rows that carry none.

  Matched on the icon rather than the title, because the title is copy and
  copy is translated; the icon is the row's identity. `nil` rather than a
  no-op tag on purpose — `Kati.ScreenTapSweepTest` reports a tag that reaches
  nothing, and a row that has nowhere to go should draw no tap at all.
  """
  @spec tile_tap(map()) :: {pid(), atom()} | nil
  def tile_tap(%{icon: "picture_as_pdf"}), do: {self(), :print_week}

  # Board 316's receiving side. *Scan a plan* drew a chevron and reached
  # nothing; screen 120 is where a scanned plan lands, and 316 is the board
  # that says what it lands AS — settings, and a row saying the meals are not
  # here.
  def tile_tap(%{icon: "qr_code_scanner"}), do: {self(), :scan_plan}
  def tile_tap(_row), do: nil

  @doc false
  def tile_trail(%{on: on?}), do: SettingsList.switch(on?)
  def tile_trail(_row), do: SettingsList.chevron()

  @doc false
  def shared_with(rows) do
    last = length(rows) - 1

    people =
      rows
      |> Enum.with_index()
      |> Enum.map(fn {row, i} ->
        SettingsList.row(
          Kati.Screens.PlanShare.avatar(row.seed),
          Kati.Screens.PlanShare.person_body(row),
          Kati.Screens.PlanShare.person_trail(row.trail),
          padding: 11,
          rule: i < last
        )
      end)

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.card(people)}
      <Spacer size={22} />
    </Column>
    """
  end

  # 13/11 rather than the settings family's 13.5/11.5 — a person is set a shade
  # smaller than a setting in this drawing.
  @doc false
  def person_body(row) do
    # `row.name` is the one string on this page that is never translated, and
    # not because nobody got to it: it is a CONTACT. Whoever you handed the
    # plan to is named by their own name in either script, the way a plan's
    # own notes are, and no `Kati.Meals.*` fixture spells a person into the
    # catalogue. `row.sub` beside it is copy the app wrote, so it is.
    ~MOB"""
    <Column fill_width={true}>
      <Text
        text={row.name}
        text_size={13}
        font_weight="semibold"
        text_color={:on_surface}
        max_lines={1}
      />
      <Spacer size={2} />
      <Text
        text={Kati.Screens.PlanShare.person_sub(row)}
        text_size={11}
        text_color={Palette.sub()}
        max_lines={1}
      />
    </Column>
    """
  end

  @doc """
  The 34pt circular face a **Shared with** row leads with.

  `Kati.Components.MishkaAvatar` rather than a hand-rolled `case`: this is an
  image with a fallback, which is the whole of what that component is, and it
  owns the one thing the `case` got slightly wrong — the fallback is *stacked
  under* the image rather than swapped for it, so a row that is waiting on a
  file still draws the drawing's `#E4E0D9` disc instead of bare paper.

  ## Why the pixels do not move

  `shape: :circle` resolves its radius as `size / 2` — 17.0, the number this
  wrote by hand, and `corner_radius` goes through `floatProp` so nothing is
  truncated. With a `src` the component returns a 34pt wrapper `Box` holding
  `[fallback, image]`: the wrapper carries only `corner_radius`, which
  `nodeModifier` turns into `Modifier.clip(RoundedCornerShape(17.dp))` over
  children that are already 34pt circles, so the clip is a no-op; and the
  image is the same node as before — 34x34, radius 17, `content_mode="fill"`
  — painted last and therefore on top. Without a `src` the fallback stands
  alone, at the same size, radius and `#E4E0D9` the old nil clause drew, plus
  an empty `initials` `Text` that is centred inside a fixed 34pt box and so
  measures nothing.

  `background` has to be passed: the component's default is `:surface_raised`,
  which in `Kati.Theme.light/0` is `#FBFAF8` — the card, not the placeholder.
  """
  def avatar(seed) do
    Kati.Components.MishkaAvatar.avatar(
      src: Kati.Design.Images.poster(seed),
      size: 34,
      shape: :circle,
      background: Palette.placeholder()
    )
  end

  @doc false
  def person_trail({:toggle, on?}), do: SettingsList.switch(on?)
  def person_trail({:icon, name}), do: Kati.UI.symbol(name, size: 17, color: Palette.rail_idle())
  # `handle_tap/2` rather than a `handle_info/2` clause: `Kati.Screens.Pushed`
  # already owns `handle_info/2` and its `:back` clause, and overriding it here
  # would take the back pill with it. `Kati.Screens.Root.rescue_tap/3` routes
  # every non-`:back` tag through here — the same shape `Kati.Screens.Plans`
  # uses for its own two.
  @impl true
  # Board 316. The file with the meals in it is screen 128's — *"the file,
  # which 128 already built"* — and it is the only file this app can produce.
  # A per-plan export has no writer, and a button that promised one would be
  # the promise this whole board is about removing.
  def handle_tap(:send_whole_plan, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Backup)}

  def handle_tap(:scan_plan, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.PlanImport, %{from: :code})}

  def handle_tap(:print_week, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.WeekImage)}
end
