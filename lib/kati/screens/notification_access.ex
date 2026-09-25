defmodule Kati.Screens.NotificationAccess do
  @moduledoc """
  Screen 151 — Notification access, a reference sheet for the one permission
  unlike every other, pushed under Auto-detect.

  Reached from screen 36's *This phone* row — the Sources card's permission
  row, which reads the same grant through `Kati.Media.Detect.access/0` —
  so a reader who taps it is told what the permission is before being sent to
  the system screen that grants it. Back returns to Auto-detect.

  ## Why this cannot be screen 40's Notifications row with an extra line

  Every other permission in the app is a runtime dialog: Android raises it,
  the user taps a button, `Kati.Permissions` records the answer. Notification
  access has no dialog to raise. `NotificationListenerService` is *special
  access* — Android's own name for the handful of permissions granted only
  from a system settings screen — and it is special for a reason worth being
  blunt about: granting it hands an app **every notification on the device,
  messages included**, not just the ones from the apps a user meant to allow.
  A permission that can read a person's texts does not belong in a list next
  to "show me notifications", so it is not folded into 40's row and it does
  not get an Allow button, because there is nothing for Allow to do. The one
  action is `Open system settings`, and this sheet draws that fact rather
  than a shortened version of it.

  ## Four states, drawn once, exactly as `Kati.Screens.States` draws its own

  This is a *reference sheet*, in the same sense screen 27 is: a static
  specimen of every state one control can be in, stacked and labelled, rather
  than one screen that renders whichever state the phone happens to be in
  today. `Kati.Permissions` has a real `:notification_access` status the
  moment #26 lands and a live screen wants one; today the board asks for all
  four states side by side and that is what a specimen screen answers, not
  four `if` branches lucky enough to agree with what is on this phone during
  a screenshot.

  The four, in the board's own order — purpose, then scope, then the one
  action, is fixed and does not reorder by state:

    1. **Not granted.** Why Kati wants it, what it can see, `Open system
       settings`. The scope sentence is deliberately not softened: *every
       notification on the device, messages included* is Android's grant, and
       *Kati reads only media notifications and never stores anything else*
       is Kati's own promise about what it does with a grant that wide.
    2. **Revoked after being granted.** Different wording on purpose — it
       leads with what was kept (128 tracks, still on the phone) rather than
       with what stopped, because a user who turned this off did not also ask
       Kati to forget what it already logged.
    3. **Granted.** The plain settings row every other permission's Allow
       becomes once it has been — a live badge and nothing else to press.
    4. **What actually ships.** See below.

  ## The fourth state is not a fourth design — it is what state 3 becomes

  Play Protect blocks a sideloaded APK that declares
  `NOTIFICATION_LISTENER`, and Kati installs directly rather than through a
  store listing that could apply for the review exemption. So states 1–3 are
  the **design record** — correct, and correctly not reachable on this build
  — and the row that ships wears the retired treatment `Kati.Screens.States`
  already established for exactly this situation: dimmed rather than hidden,
  carrying a `NOT IN V1` badge, and pressable into `Kati.Screens.RetiredTile`
  so the tap answers *why* rather than doing nothing. `retired_row/0` reuses
  that tile's own numbers — 30pt paper-adjacent tile, `tertiary` title,
  `rail_idle` sub-line — because the shape of *drawn and not built* is one
  shape app-wide, not a second one invented for this permission.

  `Kati.Screens.RetiredTile.subject/1` has no entry keyed for this row, so the
  push falls back to its drawn subject the same way `Kati.Screens.States`
  falls back for every one of *its* six example tiles — see that screen's own
  `retired/1` doc. The half a static picture cannot show is *that tapping it
  goes somewhere*, and it does; the sheet's copy being about Sleep rather than
  about notification listeners is `Kati.Screens.RetiredTile`'s subject map to
  extend, not this screen's to fork.

  ## Two paragraphs lose their bold, and it is the same bridge gap every screen this round hits

  The scope sentence in state 1 and the kept-tracks sentence in state 2 each
  carry a bold clause inside a running paragraph. `Kati.UI.rich_text/1`
  concatenates every run into one `Text` and applies one style — the whole
  reason is in its own moduledoc — so both paragraphs wrap correctly and
  neither emphasis renders. The footnote's two bold terms
  (`NOTIFICATION_LISTENER`, *design record*) are lost the same way one level
  further down: `SettingsList.note/2` takes a plain string, not runs, so that
  paragraph goes in as one already-flattened sentence rather than through
  `rich_text/1` at all.

  ## The same three paragraphs are where mishka-group/kati#103 costs the most

  A `rich_text/1` run is a msgid, and a run is a fragment of a sentence rather
  than a sentence. Persian puts its verb last and negates with a prefix fused to
  it, so a clause cut around an English bold word does not survive being
  translated a clause at a time: the verb ends up at the head of the run after
  the emphasis, or the negation has nowhere to go at all.

  All three paragraphs here redistribute inside their own fragments rather than
  being merged into one msgid, because merging would delete the design record of
  *where the board bolds* — which is the only thing these run lists still carry
  once `rich_text/1` has flattened the style. `scope_paragraph/0`,
  `not_folded_runs/0` and `revoked_paragraph/0` each document their own move,
  and each names a `pgettext/2` context so a translator opening one fragment
  knows which others it has to be read beside.

  ## `0xFFF1EEE9` is a real third grey, not a rounding of `paper`

  The retired row's icon tile is filled `#F1EEE9` in the board — between
  `Palette.paper/0`'s `#EFECE7` and `Palette.card/0`'s `#FBFAF8`, and equal to
  neither. `Kati.Screens.States` hits the same literal for its skeleton
  shimmer and leaves it unnamed for the same reason: forcing it onto the
  nearest token would move that token's meaning to match one drawing, and the
  three greys are doing three different jobs on this board.

  ## Every control goes somewhere

  `Open system settings` (drawn twice — the state-1 button and the state-2
  pill) opens the notification-listener list through
  `Kati.Native.Links.settings/1`, the `K-44 open-settings` fence; when that
  refuses, the refusal is drawn under the title with `Kati.UI.notice/1`
  rather than swallowed. `Log by hand instead` pushes `Kati.Screens.LogListen`,
  and the retired row pushes `Kati.Screens.RetiredTile`. See `handle_tap/2`.
  """

  use Kati.Screens.Pushed, back: "Auto-detect"
  use Gettext, backend: Kati.Gettext

  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList
  alias Kati.UI.Sheet

  # *Granted* is ONE WORD and takes `pgettext/2` for it.
  #
  # `mix gettext.merge` fuzzy-matches a short new msgid against any longer one
  # that resembles it, and a bare permission state is exactly the shape that
  # goes wrong — `Kati.Screens.NotificationsHelp` already reached for the same
  # `"permission"` context for its *Allow* pill, so the two states of one
  # permission carry one context and cannot be handed each other's word.
  #
  # The English still reads GRANTED: `SettingsList.eyebrow_muted/1` upcases,
  # which is a no-op on the Persian and the right answer for both.
  @doc false
  def content(assigns) do
    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {SettingsList.chrome(nil, 44)}
        {SettingsList.title(gettext("Notification access"), gettext("THE ONE PERMISSION UNLIKE EVERY OTHER"))}
        {Kati.UI.notice(assigns[:link_error])}
        {UI.eyebrow(gettext("Not granted — purpose, then scope, then the action"))}
        {Kati.Screens.NotificationAccess.not_granted()}
        {SettingsList.eyebrow_muted(gettext("Revoked after being granted — different wording"))}
        {Kati.Screens.NotificationAccess.revoked()}
        {SettingsList.eyebrow_muted(pgettext("permission", "Granted"))}
        {Kati.Screens.NotificationAccess.granted()}
        {SettingsList.eyebrow_muted(gettext("What actually ships — retired"))}
        {Kati.Screens.NotificationAccess.retired()}
        {Kati.Screens.NotificationAccess.footnote()}
      </Column>
    </Scroll>
    """
  end

  @doc """
  State 1 — purpose, then scope, then the one action there is.

  Two cards, not one: the `sensors` card is *why Kati wants it* and *what it
  can see*, one hairline apart the way a permission's reason and its blast
  radius are two different claims; the cream card underneath is `Sheet.insight/2`
  — reused rather than rebuilt, because a card that *asserts something rather
  than collects something* is exactly what that helper is documented for, and
  this is the one place on the board that asserts a policy decision (this
  permission does not live in the ordinary Notifications row) rather than
  describing a state.

  The closing caption asks for `Kati.Locale.mono_face/0` rather than naming
  `"mono"`. It is a msgid, so under `:fa` it arrives as Persian, and
  `kati_mono.ttf` carries no Arabic-script glyph — set in it, دسترسی ویژه is
  handed to Android's own substitute face and renders in a typeface that is not
  Kati's, eleven points under a sentence that is. Arity 0 rather than 1 because
  the caption is always the reader's own words; `Kati.Screens.NotificationsHelp.status/2`
  carries the argument for when the arity-1 form is the right question instead.
  """
  @spec not_granted() :: map()
  def not_granted do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={17}
      >
        <Row fill_width={true} align="top">
          {Kati.Screens.NotificationAccess.why_tile()}
          <Spacer size={12} />
          <Column weight={1.0}>
            <Text
              text={gettext("Why Kati wants it")}
              text_size={14}
              font_weight="bold"
              letter_spacing={Kati.Locale.tracking(-0.015)}
              text_color={:on_surface}
            />
            <Spacer size={6} />
            <Text
              text={gettext("To see what your music apps are playing, so you do not have to log every track by hand.")}
              text_size={12.5}
              line_height={Kati.Locale.leading(1.65)}
              text_color={Palette.ink_soft()}
            />
          </Column>
        </Row>
        <Spacer size={14} />
        {SettingsList.hairline(true)}
        <Spacer size={14} />
        {Kati.Screens.NotificationAccess.scope_paragraph()}
        <Spacer size={15} />
        {Kati.Screens.NotificationAccess.open_settings_button()}
        <Spacer size={11} />
        <Text
          text={gettext("SPECIAL ACCESS · NO DIALOG TO RAISE")}
          font_family={Kati.Locale.mono_face()}
          text_size={10.5}
          text_color={Palette.muted()}
          text_align="center"
        />
      </Column>
      <Spacer size={14} />
      {Sheet.insight("lock", Kati.Screens.NotificationAccess.not_folded_runs())}
      <Spacer size={20} />
    </Column>
    """
  end

  @doc false
  def why_tile do
    Kati.Components.MishkaThemeIcon.theme_icon(
      %{variant: :filled, color: Palette.paper(), size: 36, radius: 12},
      [UI.symbol("sensors", size: 19, color: Palette.ink_soft())]
    )
  end

  @doc """
  *What it can see.* — the sentence with the widest blast radius on the page.

  `strong` marks Android's own grant (every notification, messages included)
  the same weight as the lead-in, because the board bolds both: what Kati is
  handed and that Kati is handed something wide are the same claim in two
  clauses. See the moduledoc for why the bold does not survive `rich_text/1`.

  ## The spaces moved out of the msgids, and one clause moved inside one

  A run's leading and trailing space is concatenation rather than copy, so it
  sits at the call site the way `Kati.Screens.AutoDetectMusic.apps_note/0`
  writes it — a msgid that ends in a space is a msgid a translator has to guess
  the width of.

  The harder half is that **Persian puts the verb last** and this sentence's
  verb is in the middle, before the bolded clause. Translating `Android grants
  this as access to` word for word would leave *می‌دهد* stranded at the head of
  the run after the emphasis. So the Persian of that run is a colon
  construction — *اندروید این اجازه را این‌طور می‌دهد: دسترسی به* — which carries
  its own verb and hands the bolded clause over intact. The msgid is still the
  board's English; only the shape of its translation differs, which is what a
  fragment msgid costs and why each one here is a whole clause rather than a
  phrase cut mid-thought.
  """
  @spec scope_paragraph() :: map()
  def scope_paragraph do
    body = [
      text_size: 12.5,
      line_height: Kati.Locale.leading(1.65),
      text_color: Palette.ink_soft()
    ]

    strong = [font_weight: "semibold", text_color: Palette.ink()]

    UI.rich_text([
      {gettext("What it can see.") <> " ", strong},
      {gettext("Android grants this as access to") <> " ", body},
      {gettext("every notification on the device, messages included"), strong},
      {". " <> gettext("Kati reads only media notifications and never stores anything else."),
       body ++ [base: true]}
    ])
  end

  @doc """
  The runs for the cream card's claim: this permission does not live in 40's list.

  ## `not` is a bolded word, and Persian has no bolded word to put there

  The board's emphasis is on the negation, and Persian negates with a prefix
  fused to a verb that stands at the end of the clause — *گنجانده نمی‌شود* —
  so there is no separable *not* for this run to hold. The Persian of that run
  is **هرگز**, the emphatic negator, which is a word of its own, sits exactly
  where the board puts the bold, and leaves the grammatical negation to the
  verb in the run after it. A literal *نه* would be a word the sentence around
  it does not need twice.

  Both short runs take `pgettext/2`: `"It is"` and `"not"` are the two- and
  one-word msgids `mix gettext.merge` fuzzy-matches against the first longer
  string that resembles them.

  The board number stays a number and is not interpolated through
  `Kati.Locale.number/1`. It is inside the sentence, so it converts with the
  rest of it — ۴۰ is written into the Persian the way ۱۸۹ and ۱۱۲ are written
  into screen 189's — and a `%{board}` binding would only hand a translator a
  figure they cannot read in place.
  """
  @spec not_folded_runs() :: [{String.t(), keyword()}]
  def not_folded_runs do
    body = [
      text_size: 12.5,
      line_height: Kati.Locale.leading(1.65),
      text_color: Palette.cream_body()
    ]

    strong = [font_weight: "semibold", text_color: Palette.ink()]

    [
      {pgettext("notification access, the cream card", "It is") <> " ", body},
      {pgettext("notification access, the cream card", "not"), strong},
      {" " <>
         gettext(
           "folded into the ordinary Notifications row on 40. A permission that can read every message in a person’s life does not belong in a list next to “show me notifications”."
         ), body ++ [base: true]}
    ]
  end

  @doc """
  The one action state 1 offers — not an Allow button, because there is
  nothing to raise. Full-width and ink-filled the way `Sheet.commit/2` ends a
  sheet, with an icon this board's button carries and that one does not.
  """
  @spec open_settings_button() :: map()
  def open_settings_button do
    ~MOB"""
    <Row
      fill_width={true}
      height={44}
      corner_radius={22}
      background={Palette.ink_fill()}
      align="center"
      on_tap={{self(), :open_settings}}
    >
      <Spacer weight={1.0} />
      {UI.symbol("settings", size: 17, color: Palette.on_ink())}
      <Spacer size={8} />
      <Text
        text={gettext("Open system settings")}
        text_size={12.5}
        font_weight="bold"
        text_color={Palette.on_ink()}
        max_lines={1}
      />
      <Spacer weight={1.0} />
    </Row>
    """
  end

  @doc """
  State 2 — revoked reads differently from never-granted, and leads with what
  was kept. `notifications_off` in `gold_icon` rather than `ink_soft`,
  because this card is a warning about a setting a user changed, not a
  neutral explainer.
  """
  @spec revoked() :: map()
  def revoked do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={17}
      >
        <Row fill_width={true} align="top">
          {UI.symbol("notifications_off", size: 19, color: Palette.gold_icon())}
          <Spacer size={11} />
          <Column weight={1.0}>
            <Text
              text={gettext("Turned off in system settings")}
              text_size={13.5}
              font_weight="bold"
              text_color={:on_surface}
            />
            <Spacer size={6} />
            {Kati.Screens.NotificationAccess.revoked_paragraph()}
          </Column>
        </Row>
        <Spacer size={14} />
        <Row align="center">
          <Column on_tap={{self(), :open_settings_revoked}}>
            {SettingsList.action_pill(gettext("Open system settings"))}
          </Column>
          <Spacer size={8} />
          <Column on_tap={{self(), :log_by_hand}}>
            {SettingsList.action_pill(gettext("Log by hand instead"))}
          </Column>
        </Row>
      </Column>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc """
  What was kept, then what stopped — in that order, per the moduledoc.

  ## The count is a specimen, and goes through `ngettext/4` anyway

  128 is the board's own figure rather than this phone's, and the moduledoc's
  argument for drawing four states instead of branching on one applies to the
  number inside a state as much as to the state.
  `Kati.Screens.BackupStates.stale/0` hands its three drawn counts to
  `ngettext/4` for the reason this one does: a specimen figure is still read by
  a reader, and a Persian one has to see ۱۲۸ آهنگ rather than `128 tracks`.
  The entry is the one `Kati.Screens.AlbumDetail` already owns, so nothing new
  reaches a translator; Persian does not inflect a noun after a numeral, which
  is why its plural msgstr is its singular.

  ## Four fragments, and the Persian redistributes across them

  The same shape `scope_paragraph/0` hits: Persian's verb comes last and this
  sentence puts *logged* second, so *while it was on* moves forward into the
  first run's Persian — *کاتی تا وقتی روشن بود* — and the verb moves back into
  the third, *ثبت کرده و*. Every msgid is still a clause of the board's own
  English. The shared `pgettext/2` context is what says so: a translator who
  opens one of these four has to read the other three, and the context is the
  only thing in the `.po` that can tell them that.
  """
  @spec revoked_paragraph() :: map()
  def revoked_paragraph do
    body = [
      text_size: 12.5,
      line_height: Kati.Locale.leading(1.65),
      text_color: Palette.ink_soft()
    ]

    strong = [font_weight: "semibold", text_color: Palette.ink()]

    UI.rich_text([
      {pgettext("notification access, the revoked card", "Kati logged") <> " ", body},
      {ngettext("%{n} track", "%{n} tracks", 128, n: Kati.Locale.number(128)), strong},
      {" " <> pgettext("notification access, the revoked card", "while it was on and") <> " ",
       body},
      {pgettext("notification access, the revoked card", "keeps all of them"), strong},
      {". " <> gettext("Nothing new is detected until it is turned back on."),
       body ++ [base: true]}
    ])
  end

  @doc """
  State 3 — the plain row every other permission's Allow becomes, once it has
  been. One row, so `rule: false` — there is nothing under it to rule off
  from.

  ## *Live* is the third thing in this app called Live and takes a context

  `Kati.Screens.AutoDetect`'s now-playing pill is **در حال پخش** and
  `Kati.Screens.Sync`'s account pill is **به‌روز**, and neither is what this one
  means: here the permission itself is switched on and listening, which is
  **فعال**. One English word, three Persian ones, which is exactly the case
  `pgettext/2` exists for — without a context the three collapse into whichever
  `mix gettext.merge` saw first and two rows of the app start lying.
  """
  @spec granted() :: map()
  def granted do
    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.card([
        SettingsList.row(
          SettingsList.icon_tile("sensors"),
          SettingsList.body(gettext("Notification access"), gettext("On · media notifications only")),
          SettingsList.status_pill(
            pgettext("notification access status pill", "Live"),
            Palette.green_text(),
            Palette.green_wash()
          ),
          rule: false
        )
      ])}
      <Spacer size={20} />
    </Column>
    """
  end

  @doc """
  State 4 — what actually ships. `Kati.Screens.States` already drew this
  treatment for its own six examples; this row is that treatment for one
  named permission instead of a specimen list, and the tap lands on the same
  `Kati.Screens.RetiredTile` for the same reason — see the moduledoc.

  Trailing is passed bare, not pre-wrapped in `SettingsList.trailing/1` —
  `row/4` applies that itself, and `RetiredTile`'s own moduledoc records what
  handing it an already-wrapped node costs.
  """
  @spec retired() :: map()
  def retired do
    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.card([
        SettingsList.row(
          Kati.Screens.NotificationAccess.retired_icon_tile(),
          Kati.Screens.NotificationAccess.retired_body(),
          Kati.Screens.NotificationAccess.not_in_v1_badge(),
          rule: false,
          on_tap: {self(), :open_retired}
        )
      ])}
      <Spacer size={14} />
    </Column>
    """
  end

  @doc false
  def retired_icon_tile do
    Kati.Components.MishkaThemeIcon.theme_icon(
      # LEFT AS A LITERAL — see the moduledoc. `0xFFF1EEE9` sits between
      # `paper` (`0xFFEFECE7`) and `card` (`0xFFFBFAF8`) and is neither; the
      # retired tile is the one surface on this board that is deliberately a
      # third, in-between grey.
      %{variant: :filled, color: Palette.tile_grey(), size: 30, radius: 9},
      [UI.symbol("sensors", size: 17, color: Palette.rail_idle())]
    )
  end

  @doc false
  def retired_body do
    ~MOB"""
    <Column fill_width={true}>
      <Text
        text={gettext("Notification access")}
        text_size={13.5}
        font_weight="semibold"
        text_color={Palette.tertiary()}
        max_lines={1}
      />
      <Spacer size={3} />
      <Text
        text={gettext("Not set up — tap to see why")}
        text_size={11.5}
        text_color={Palette.rail_idle()}
        max_lines={1}
      />
    </Column>
    """
  end

  @doc """
  The badge, in the recipe `Kati.Screens.DataSources.not_in_v1/0` already
  settled for the same token on the same treatment.

  The msgid is sentence case and `Kati.UI.eyebrow_label/1` does the shouting,
  because `String.upcase/1` is a Latin operation and the Persian — **در نسخه ۱
  نیست** — has no case to raise; the English still draws `NOT IN V1`. The face
  is `Kati.Locale.mono_face/0` rather than the literal `"mono"` for
  `not_granted/0`'s reason, and the tracking goes through
  `Kati.Locale.tracking/1` because `.06em` is a Latin small-caps effect that
  pulls Persian letters out of their joins. Only the sizes are this board's own
  — 9pt in a 22pt pill, where 80's is 9.5 in one of the same height.
  """
  def not_in_v1_badge do
    ~MOB"""
    <Row
      height={22}
      corner_radius={11}
      background={Palette.paper()}
      padding_left={8}
      padding_right={8}
      align="center"
    >
      <Text
        text={UI.eyebrow_label(gettext("Not in v1"))}
        font_family={Kati.Locale.mono_face()}
        text_size={9}
        letter_spacing={Kati.Locale.tracking(0.06)}
        text_color={Palette.sub()}
        max_lines={1}
      />
    </Row>
    """
  end

  @doc """
  The closing footnote: why the shipped app never shows states 1–3 at all.

  ## `NOTIFICATION_LISTENER` comes in as a binding so its comma stays put

  It is the one Latin run inside this paragraph with punctuation hard against
  it, and a full stop or comma is **neutral** in the Unicode bidirectional
  algorithm: on a Persian page it resolves to the paragraph's direction and
  lands at the wrong edge of the token. `Kati.Locale.ltr/1` is the isolate that
  stops it, and a binding is the only way to reach one word of a msgid — which
  is also why it is the only Latin run here that gets one. *Play Protect* and
  *APK* sit against spaces and Persian words, and a space is a neutral with
  nothing to reorder.

  Both stay Latin. They are Google's name for a service and Android's name for
  a file, and transliterating either would spell in Persian a thing the phone
  spells in Latin two screens away — the rule board 127 draws `Lumen+` under.
  """
  @spec footnote() :: map()
  def footnote do
    SettingsList.note(
      "info",
      gettext(
        "Play Protect blocks sideloaded APKs declaring %{listener}, and Kati installs directly. So the three states above are the design record, and the live row wears 114’s retired treatment — it keeps its place and explains itself rather than vanishing.",
        listener: Kati.Locale.ltr("NOTIFICATION_LISTENER")
      )
    )
  end

  @doc """
  `:open_retired` is the one tap on this board with somewhere real to go —
  see the moduledoc for why it falls back to `RetiredTile`'s drawn subject
  rather than a subject keyed for this permission.

  `"Sleep"` is a **key, not copy**, and stays English for that reason.
  `Kati.Screens.RetiredTile.subject/1` matches it against the untranslated
  names `Kati.Health.Sample.sections/0` stores, so a translated `"Sleep"` would
  miss the map under `:fa` and fall through to the sheet's default —
  indistinguishable, on screen, from a section nobody wrote copy for.
  `Kati.Screens.States` pushes the same string for the same reason and carries
  the long version of the note. mishka-group/kati#103.

  `:log_by_hand` goes to `Kati.Screens.LogListen`. That is not a consolation
  prize: this sheet gates *auto*-detecting a listen, so the alternative it
  offers is the same hand-logging screen `Kati.Screens.AlbumDetail` pushes for
  `Log a listen`. One way in, whichever way you arrived.

  Both `Open system settings` taps open the system notification-listener
  list, and a refusal — no bridge, or a phone that will not open it — is
  assigned to `:link_error` and drawn under the title, the way
  `Kati.Screens.NotificationsHelp` draws its own settings taps' refusals.
  """
  @spec handle_tap(atom(), Mob.Socket.t()) :: {:noreply, Mob.Socket.t()}
  def handle_tap(:open_retired, socket) do
    {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.RetiredTile, %{section: "Sleep"})}
  end

  def handle_tap(:log_by_hand, socket) do
    {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.LogListen)}
  end

  # Both *Open system settings* pills open the notification-listener screen.
  # A comment rather than a second `@doc`: these are clauses of one
  # `handle_tap/2` and the clause above already carries the doc.
  #
  # They were drawn, reachable and dead until `K-44 open-settings` was built:
  # `Kati.ScreenTapSweepTest` carried each with the same reason — *no fence in
  # `native/LEDGER.md` launches an Android settings intent* — and that was the
  # whole of what stood between them and the one screen this sheet exists to
  # send a reader to.
  #
  # Two tags for one destination, because #97 gave the revoked band's pill its
  # own name: both said *Open system settings* under one id and the two states
  # of this board were one node to `onNodeWithTag`. They do the same thing and
  # are meant to.
  #
  # Kati cannot grant the access and does not try — `Kati.Native.Links.settings/1`
  # opens the list and the reader turns it on. The refusal is drawn rather than
  # swallowed, for screen 06's reason.
  #
  def handle_tap(tag, socket) when tag in [:open_settings, :open_settings_revoked] do
    {:noreply, Kati.Screens.NotificationAccess.open_listener_settings(socket)}
  end

  def handle_tap(_tag, socket), do: {:noreply, socket}

  @doc false
  @spec open_listener_settings(Mob.Socket.t()) :: Mob.Socket.t()
  def open_listener_settings(socket) do
    case Kati.Native.Links.settings(:notification_listener) do
      :ok -> Mob.Socket.assign(socket, :link_error, nil)
      {:error, why} -> Mob.Socket.assign(socket, :link_error, Kati.Native.Links.message(why))
    end
  end
end
