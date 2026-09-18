defmodule Kati.Screens.DataSourcesStates do
  @moduledoc """
  Screen 81 — the seven states of screen 80, on one sheet pushed under Settings.

  Screen 80 draws Data sources as it looks when everything answers. This is the
  board that draws it when things do not: a provider that could not be reached,
  a provider that is slowing Kati down on purpose, the device offline under
  both, a pasted key being checked, the same key refused, a cache close to its
  ceiling, and the confirmation that takes every token away. It is a reference
  sheet in screen 27's manner — pictures of a screen you go and look at, rather
  than something the app puts in front of you — and it carries a back pill for
  exactly that reason, as 27 and 67 do.

  Eight cards under six eyebrows, and the subtitle still says `seven states`.
  That is the drawing's arithmetic rather than a miscount: the ink bar at the
  bottom is not a state of Data sources. It is 27's rule — *every destructive
  action leaves an undo bar behind* — being kept, and it is
  `Kati.Screens.States.undo/1` unchanged, because 27's metrics and this
  drawing's are the same metrics to the point.

  One eyebrow keeps the orange dash. A provider failing is happening now, and
  orange means new/now. The other five name a condition rather than an event —
  a rate limit, a radio, a key, a cache, a question being asked — so they take
  27's grey dash.

  ## Everything both screens draw the same way is screen 80's

  The two provider rows are `Kati.UI.SettingsList.card/1` over
  `Kati.UI.SettingsList.row/4` with `icon_tile/1` and `body/3` — the same four
  calls `Kati.Screens.DataSources.tier0/0` makes — and the name and the glyph in
  each come out of `Kati.Sources.tier0/0` through `provider/1` rather than being
  typed here. `Retry` is `Kati.UI.SettingsList.action_pill/1`, which is the
  drawing's 30pt paper pill at radius 15 exactly. `OLDEST ENTRY 5 MONTHS` is
  spelled by `Kati.Screens.DataSources.age/1`, so a span of days is capitalised
  here the way screen 80 capitalises it and the two cannot drift.

  The rows keep 80's 30x30 tile rather than the board's 40x40, and that is not a
  concession made on this sheet. Screen 80's *own* drawing specifies 40 and
  screen 80 renders `Kati.UI.SettingsList.icon_tile/1`, which is the settings
  tree's one tile at 30. A states sheet that drew the board's number would
  report a difference between the two screens that the app does not have, and
  the tile is the shared helper's business to change — once, for all of them.

  Two bands are drawn here instead. The cache card is the board's own rather
  than `Kati.Screens.DataSources.cache/0`, because the two are not the same
  card: 80 gives the figure `Refresh` and `Clear` and no bar, and the board
  drops both pills for the bar that is the whole point of the state. And the
  offline badge is hand-rolled at radius 20 with 15 of padding, where
  `Kati.Screens.States.offline/1` draws 18 and 14/16 — 67 and 71 made the same
  choice on the same card for the same reason, and the sub-line here needs two
  lines where 27's fits in one.

  ## Nothing here reads a store

  27's argument, unchanged: each card is a picture of a state, not a report that
  the app is in it. `last checked 18:02` is the line that could be read —
  `Kati.Screens.DataSources.last_reached/1` returns exactly that string off the
  newest cache row a source wrote — and it is still not read, because the
  failure beside it never happened and dating a true clock against an invented
  incident is worse than the drawing. `61 MB cached` is the same refusal:
  `Kati.Screens.DataSources.cache_size/0` would answer with whatever this device
  holds, which is a cache nowhere near a ceiling, under an eyebrow promising one
  that is.

  `Kati.Sources.tier0/0` and `tier2/0` *are* read, and that is a different
  thing. They are module attributes naming what Kati can talk to; neither of
  them says that a request happened.

  ## The judgement the ticket left open, twice

  **The wipe confirmation is inline, and it leads with what survives.** Not a
  modal, which is the other obvious reading and the wrong one: a modal takes the
  page away at the moment the reader most wants to check what is on it, and the
  sentence this card leads with — *Your library, ratings and history are
  untouched — only the keys go* — is answering the question the destructive
  button raises, before it asks it. The red fill goes on `Wipe tokens` and the
  paper on `Keep them`, in that order, because the confirmation is being asked
  about the thing the reader has already reached for; putting the safe answer
  first would make them work out which side is which.

  `Three accounts` is written out rather than counted, and the count is real:
  `Kati.Sources.tier2/0` holds exactly three revocable-token providers, and
  `Kati.Sources.disconnect_all/0` is the call that empties them. It is stated
  because a specimen confirmation on a device where nothing is connected would
  count to zero and print *0 accounts disconnect* — a true figure attached to an
  event that cannot happen, which is the failure 27 names.

  **The bad-key line names the likely mistake, not the status code.** TMDB
  answers a bad token with a 401, and *401 Unauthorized* tells a reader who has
  just pasted something only that they pasted something wrong. What they
  actually did is nearly always one of two things: TMDB's own settings page
  offers an *API Key* and an *API Read Access Token* under one heading and the
  token is the one Kati wants, or the copy picked up a trailing space. So the
  line names both and says nothing about HTTP. The truncated key sits above it
  in mono and in red, so the thing being complained about is on screen next to
  the complaint.

  ## Rate-limited reads bronze, not red

  The frame's own note, and it is a claim about who is doing what. A red dot on
  the MusicBrainz row would say MusicBrainz is broken. It is not: MusicBrainz
  publishes a one-request-a-second limit and Kati is keeping to it, so the row
  is reporting Kati being polite. `Kati.Theme.Palette.gold_icon/0` is the hue
  this design gives something worth noticing that is not wrong — the same gold
  as the offline badge's cloud — and the sub-line says `slowing down`, present
  tense, instead of naming a failure. The trailing word is `normal`, which is
  the state of the *provider* while Kati throttles itself.

  Both provider rows pass `lines: 2` to `Kati.UI.SettingsList.body/3`. That is
  the exception the helper's own comment records: a settings row's second line
  is a label and should truncate, and these two carry the *reason*. `last
  checked 18:02 · couldn’t reach TVm` is a row that has deleted the only words
  on it worth reading.

  ## Where the bridge and the drawing disagree

    * **The shimmer in the checking field is flat.** The board fills the bar
      with `linear-gradient(90deg,#E7E3DC,#F1EEE9,#E7E3DC)` and the bridge's
      gradient parser is vertical only — `to_top` or `to_bottom` — so it is the
      flat `#E7E3DC` the gradient starts and ends on, which is
      `Kati.Theme.Palette.track/0`. 27 records the same thing about its own
      skeleton rows.
    * **The bold `API Read Access Token` is not bold.** `Kati.UI.rich_text/1`
      concatenates its runs and applies one style, because `MobText` takes a
      `String` and there is no `AnnotatedString` in the bridge. It is still
      written as runs rather than as one flat string: the emphasis is what the
      line means, and on the day the bridge grows a `runs` prop this call site
      is already right. The same flattening would take the footnote's `inline`,
      which is why that note goes through `Kati.UI.SettingsList.note/2` as plain
      text — runs there would buy nothing and hide the loss.
    * **The red ring around the refused key is the one inset shadow Compose
      reproduces exactly.** The board draws it `box-shadow: inset 0 0 0 1.5px`,
      which grows inward, and `Modifier.border` also draws inward. So it is
      `border_width={1.5}` and nothing is lost here — unlike screen 71's 2pt
      ring, which the board grows outward and Compose takes out of the card.
    * **`Kati.Theme.Palette.cream_body/0` on a white card.** The refusal
      paragraph is `#4A4238` and that token is the only one whose light value is
      `#4A4238`. The name is wrong here and the value is forced by the drawing,
      which is the discrepancy `Kati.UI.SettingsList.chevron/0` and screen 71
      both record; the cost in dark is that the sentence comes back a shade
      warm.

  ## Under `:fa` this is one screen and not two, and six choices follow

  mishka-group/kati#103 folded the 33 Persian mirrors away, so every sentence
  here reaches a Persian reader through `Kati.Gettext` and every figure through
  `Kati.Locale`. Six of those are decisions rather than mechanics:

    * **The frame's note stopped being `@note`.** `gettext/1` inside a module
      attribute is evaluated when the MODULE compiles, so the footnote would
      have frozen in whichever locale the compiler was in and been handed to
      every reader afterwards. It is `note_body/0` now, evaluated per render,
      which is the only moment `Kati.Locale.current/0` is known.
    * **`18:02` is a `Time` and not a string.** `Kati.Locale.time/1` answers
      ۱۸:۰۲ under `:fa`, and it is the same `~T[18:02:00]` screen 01's
      *last check %{at}* takes — so the two boards cannot disagree about the
      numerals. The bar's `3` and the cache's `61` are measurements and go
      through `Kati.Locale.number/1` the same way.
    * **`TVmaze` is interpolated, not translated.** A provider's name is what
      the service calls itself; `Kati.Sources.tier0/0` writes it in Latin in
      both scripts, and leaving it inside a msgid would invite a transliteration
      that spells one service two ways on one page. `Kati.Locale.ltr/1` isolates
      it so the `·` beside it stays on the correct edge — and the truncated key
      in the bad-key field takes the same call, because an ellipsis is a neutral
      character and an RTL page would lay it out in FRONT of the key.
    * **`API Read Access Token` and `API key` stay Latin inside the refusal.**
      Both name controls on TMDB's own settings page — the point of the sentence
      is to send the reader back to find one and not the other — so a Persian
      rendering would name labels that are not there. The catalogue's existing
      translation of screen 80's version of this refusal made the identical
      call. The field LABEL above them is Kati's own chrome over Kati's own
      field, and that one is translated.
    * **Every mono line asks `Kati.Locale.mono_face/1`.** `kati_mono.ttf`
      carries no Persian glyph, so a line left in `mono` is handed to Android's
      own substitute face and renders, correctly shaped, in a typeface that is
      not Kati's. `/1` rather than `/0` so the answer follows the string: the
      key specimen is ASCII and keeps DM Mono under both locales.
    * **`Three accounts` is a word and `3 accounts disconnected` is a figure.**
      The confirmation states its count for the reason above — a specimen on a
      device with nothing connected would otherwise count to zero — so the
      Persian spells it out too. The undo bar beneath it prints a number, so
      that one goes through `Kati.Locale.number/1` and reads ۳.

  ## Nothing on this sheet taps

  `Retry`, `Wipe tokens`, `Keep them` and `Undo` are drawn and not wired, so
  `Kati.Screens.Pushed` defines no `handle_tap/2` and none of them can report a
  dead tag. 67's reason, and it is sharper here than anywhere: `Wipe tokens` on
  the real screen calls `Kati.Sources.disconnect_all/0`, and a reference sheet
  whose specimen button emptied the secure store would be the most expensive
  control in the app.
  """

  use Kati.Screens.Pushed, back: "Settings"
  use Gettext, backend: Kati.Gettext

  alias Kati.Components.MishkaPill
  alias Kati.Components.MishkaProgress
  alias Kati.Screens.DataSources
  alias Kati.Screens.States
  alias Kati.Sources
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  @doc false
  @spec content(map()) :: map()
  def content(_assigns) do
    note = SettingsList.note("info", note_body())

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
        {SettingsList.title(gettext("Data sources"), gettext("seven states"), nil, :name)}
        {UI.eyebrow(gettext("Provider failing"))}
        {Kati.Screens.DataSourcesStates.failing()}
        {SettingsList.eyebrow_muted(gettext("Rate-limited — not an error"))}
        {Kati.Screens.DataSourcesStates.rate_limited()}
        {SettingsList.eyebrow_muted(pgettext("the device has no network", "Offline"))}
        {Kati.Screens.DataSourcesStates.offline()}
        {SettingsList.eyebrow_muted(gettext("Verifying a pasted key · bad key"))}
        {Kati.Screens.DataSourcesStates.key_checks()}
        {SettingsList.eyebrow_muted(gettext("Cache near the ceiling"))}
        {Kati.Screens.DataSourcesStates.cache_ceiling()}
        {SettingsList.eyebrow_muted(gettext("Wipe confirmation · after wiping"))}
        {Kati.Screens.DataSourcesStates.wipe()}
        {note}
      </Column>
    </Scroll>
    """
  end

  # THE FRAME'S NOTE IS A FUNCTION AND NOT `@note` ANY MORE.
  #
  # It was a module attribute, and `gettext/1` inside one is evaluated when the
  # MODULE is compiled: the sentence would freeze in whichever locale the
  # compiler happened to be in and every reader afterwards would get that one —
  # an English footnote under a Persian page, or the reverse, with nothing in
  # the render able to correct it. A function is evaluated per render, which is
  # the only moment `Kati.Locale.current/0` is known. mishka-group/kati#103.
  defp note_body do
    gettext(
      "Rate-limited reads bronze, not red — it is Kati being polite, not " <>
        "something breaking. The wipe confirmation is inline, not a modal: " <>
        "it says what survives before it asks."
    )
  end

  @doc """
  One of screen 80's out-of-the-box providers, by id.

  The name and the glyph are `Kati.Sources.tier0/0`'s, so `TV & film · TVmaze`
  and `movie` are literally the two values screen 80 draws rather than a copy of
  them. A sheet that retyped a provider's name would go stale the first time the
  list was edited, and would then report a difference between the two screens
  that does not exist.

  Reading that list is not reading a store: it is a module attribute naming what
  Kati can talk to, and it says nothing about whether a request was ever made.
  See the moduledoc for the lines this sheet does refuse to read.
  """
  @spec provider(atom()) :: map()
  def provider(id), do: Enum.find(Sources.tier0(), fn source -> source.id == id end)

  @doc """
  A provider that could not be reached, with `Retry` beside it.

  The clock moves. On screen 80 the time sits in the trailing slot and *is* the
  claim — `Kati.Screens.DataSources.reached/1` prints it there because
  *reachable* is a claim with a clock on it. When the reach fails, that slot is
  needed for the way out, so the time goes into the sentence and takes a verb
  with it: `last checked 18:02 · couldn’t reach TVmaze` says when Kati tried,
  where `18:02` alone under a red dot would still read as when it succeeded.
  """
  @spec failing() :: map()
  def failing do
    source = Kati.Screens.DataSourcesStates.provider(:tvmaze)

    # ONE MSGID, AND TWO THINGS TAKEN OUT OF IT.
    #
    # The clock is a rendered figure, so `18:02` goes through
    # `Kati.Locale.time/1` and reads ۱۸:۰۲ under `:fa` — screen 01's own
    # `last check %{at}` takes the same `~T[18:02:00]` the same way, so the two
    # boards cannot disagree about the numerals.
    #
    # The provider's name is interpolated rather than left sitting inside the
    # msgid. `TVmaze` is what the service calls itself, `Kati.Sources.tier0/0`
    # writes it in Latin in both scripts for that reason, and a translator
    # meeting it inside a sentence would be invited to transliterate it — which
    # would spell one service two ways on one page. `Kati.Locale.ltr/1` then
    # isolates the run so the `·` beside it resolves against the name rather
    # than against an RTL paragraph and jumps to the wrong edge.
    #
    # The `·` itself stays inside the msgid rather than joining two translated
    # halves, which is the call `Kati.Screens.BackupStates.recent/0` argues for:
    # a Persian reader meets the whole line as one phrase.
    sub =
      gettext("last checked %{at} · couldn’t reach %{provider}",
        at: Kati.Locale.time(~T[18:02:00]),
        provider: Kati.Locale.ltr("TVmaze")
      )

    row =
      SettingsList.row(
        SettingsList.icon_tile(source.icon),
        SettingsList.body(source.name, sub, lines: 2),
        Kati.Screens.DataSourcesStates.retry_control(),
        rule: false
      )

    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.card(row)}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  A red dot and the paper pill that does something about it.

  `Kati.UI.SettingsList.action_pill/1` is the drawing's pill to the point — 30
  tall at radius 15, paper, an 11.5pt semibold label — and it is the same
  control screen 27's error card offers, which is the whole reason a failure on
  this page looks like a failure anywhere else in the app.
  """
  @spec retry_control() :: map()
  def retry_control do
    ~MOB"""
    <Row align="center">
      {Kati.Screens.DataSourcesStates.dot(Kati.Theme.Palette.red())}
      <Spacer size={9} />
      {Kati.UI.SettingsList.action_pill(gettext("Retry"))}
    </Row>
    """
  end

  @doc """
  A provider Kati is deliberately going slowly against.

  Nothing to retry and nothing to fix, so the trailing slot carries a word
  instead of a control: `normal` is the state of the provider while Kati
  throttles *itself*. See the moduledoc for why the dot is bronze.
  """
  @spec rate_limited() :: map()
  def rate_limited do
    source = Kati.Screens.DataSourcesStates.provider(:musicbrainz)

    # `gettext/2` and not `ngettext/4`. One a second is MusicBrainz's PUBLISHED
    # limit rather than a count this line could ever draw twice, so there is no
    # second form for a plural to select — an `ngettext` here would invent a
    # sentence the app cannot reach. The figure still goes through
    # `Kati.Locale.number/1`: a Latin `1` sitting between Persian words is
    # exactly the digit a reader notices.
    sub = gettext("slowing down · %{n} request a second", n: Kati.Locale.number(1))

    row =
      SettingsList.row(
        SettingsList.icon_tile(source.icon),
        SettingsList.body(source.name, sub, lines: 2),
        Kati.Screens.DataSourcesStates.polite_control(),
        rule: false
      )

    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.card(row)}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  The bronze dot and the one word beside it.

  Mono at 10.5 and `Kati.Theme.Palette.muted/0`, which is the typography screen
  80 gives the trailing slot on every row it draws. Keeping it means the eye
  reads *this row is reporting the same kind of thing as the others*, and only
  the colour of the dot says which kind.
  """
  @spec polite_control() :: map()
  def polite_control do
    # `pgettext/2` for one word. A bare `normal` is exactly the size
    # `mix gettext.merge` fuzzy-matches against any sentence that happens to
    # contain it, and the context carries the distinction this whole card is
    # about: it is the PROVIDER that is normal, while Kati is the one slowing
    # down.
    word = pgettext("the provider’s own state while Kati throttles itself", "normal")

    # `kati_mono.ttf` carries no Persian glyph, so a hardcoded `mono` here would
    # hand `عادی` to Android's own substitute face — legible, in a typeface that
    # is not Kati's, beside a row set in Kati's. `mono_face/1` asks the STRING,
    # so the English word keeps DM Mono and the Persian one does not.
    assigns = %{word: word}

    ~MOB"""
    <Row align="center">
      {Kati.Screens.DataSourcesStates.dot(Kati.Theme.Palette.gold_icon())}
      <Spacer size={7} />
      <Text
        text={@word}
        font_family={Kati.Locale.mono_face(@word)}
        text_size={10.5}
        text_color={Kati.Theme.Palette.muted()}
        max_lines={1}
      />
    </Row>
    """
  end

  @doc """
  The 7pt status dot a provider row leads its trailing group with.

  Its colour is the entire message — red for a provider that did not answer,
  bronze for one Kati is queuing behind — so it takes the colour as an argument
  rather than a state name. There is no green one on this sheet: a provider that
  answered is screen 80, not a state of it.
  """
  @spec dot(pos_integer()) :: map()
  def dot(colour) do
    ~MOB"""
    <Box width={7} height={7} corner_radius={4} background={colour} />
    """
  end

  @doc """
  The offline badge, cream and flat.

  27's card at this screen's metrics — radius 20 and 15 of padding, where 27
  draws 18 and 14/16 — which is the arrangement 67 and 71 both landed on. No
  shadow, and that is 27's own distinction rather than an omission: a condition
  the app is in is not an object lifted off the page.

  The sentence is this screen's. 27 promises the ticks are safe and 71 promises
  the session saves; a page about where data comes from has to promise the thing
  a reader would actually fear, which is that a library assembled out of remote
  metadata stops working when the remote end does. It does not — every title,
  cover and fact already fetched is a local row — so the line says the library
  works *exactly as it did a minute ago* rather than offering a degraded mode.
  """
  @spec offline() :: map()
  def offline do
    # The badge's title and the eyebrow above it are ONE msgid on purpose: they
    # are the same word about the same condition, and two entries would let a
    # translator give the section and the card it introduces two different
    # words. `pgettext/2` because a bare `Offline` is one word — the context
    # names the radio rather than, say, a provider that is unreachable, which is
    # the card two states above this one.
    assigns = %{
      title: pgettext("the device has no network", "Offline"),
      line: gettext("Your library works exactly as it did a minute ago")
    }

    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        background={Palette.cream()}
        corner_radius={20}
        padding={15}
        align="center"
      >
        {UI.symbol("cloud_off", size: 20, color: Palette.gold_icon())}
        <Spacer size={12} />
        <Column weight={1.0}>
          <Text
            text={@title}
            text_size={13}
            font_weight="bold"
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={3} />
          <Text text={@line} text_size={11.5} text_color={Palette.cream_sub()} max_lines={2} />
        </Column>
      </Row>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  A pasted key being checked, and the same key refused.

  Two cards under one eyebrow, in the order the reader meets them, which is 67's
  arrangement for its own error/offline pair. The gap is 10 rather than the 22
  between states, because these are two moments of one thing rather than two
  things.
  """
  @spec key_checks() :: map()
  def key_checks do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.DataSourcesStates.checking()}
      <Spacer size={10} />
      {Kati.Screens.DataSourcesStates.bad_key()}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  The mono label over a key field.

  Set in sentence case here and upcased on the way out, which is
  `Kati.UI.eyebrow/2`'s arrangement and for the same reason: the drawing writes
  `API key` and spells the capitals with `text-transform`, so the source keeps
  the sentence and the tree gets the caps.
  """
  @spec key_label() :: map()
  def key_label do
    # `Kati.UI.eyebrow_label/1` rather than `String.upcase/1` — the same swap
    # `Kati.UI.eyebrow/2` made for the section labels. Arabic script has no case,
    # so upcasing a Persian label is a no-op that LOOKS like one: the line comes
    # out in the same letters it went in with, beside Latin labels that visibly
    # changed. `eyebrow_label/1` keeps the capitals in Latin and leaves the
    # Persian alone, which is what the drawing's `text-transform` does anyway.
    #
    # The label itself is Kati's own chrome over Kati's own field and is
    # translated. `API key` INSIDE the refusal sentence below is not: there it
    # names one of the two controls on TMDB's settings page, which is the whole
    # point of the sentence. Two different things that happen to share a name in
    # English, and only one of them is a word.
    label = Kati.UI.eyebrow_label(gettext("API key"))

    assigns = %{label: label}

    ~MOB"""
    <Column fill_width={true}>
      <Text
        text={@label}
        font_family={Kati.Locale.mono_face(@label)}
        text_size={10}
        letter_spacing={Kati.Locale.tracking(0.1)}
        text_color={Palette.muted()}
      />
      <Spacer size={9} />
    </Column>
    """
  end

  @doc """
  The key field while Kati is asking TMDB about it.

  A skeleton and never a spinner — 27's rule, and this is the smallest version
  of it in the app: one bar where the key was, and the word `checking` in the
  corner where the verdict is going to land. The field does not resize and the
  word does not move, so the answer replaces the wait rather than reflowing the
  card around it.

  The bar is flat rather than shimmering; see the moduledoc.
  """
  @spec checking() :: map()
  def checking do
    # `pgettext/2` for one word, and the context names the slot. The catalogue
    # already holds `never checked` and screen 01's `last check %{at}`, which
    # are exactly what `mix gettext.merge` would fuzzy-match a bare `checking`
    # against — and the answer that lands in this slot is a VERDICT, so the
    # wrong word here would be the one thing the card is about.
    word = pgettext("the verdict slot while a pasted key is being checked", "checking")

    assigns = %{word: word}

    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={20}
      padding={15}
      shadow={Kati.Theme.shadow_card_soft()}
    >
      {Kati.Screens.DataSourcesStates.key_label()}
      <Row
        fill_width={true}
        height={44}
        corner_radius={14}
        background={Palette.paper()}
        padding_left={14}
        padding_right={14}
        align="center"
      >
        <Box weight={1.0} height={11} corner_radius={6} background={Palette.track()} />
        <Spacer size={11} />
        <Text
          text={@word}
          font_family={Kati.Locale.mono_face(@word)}
          text_size={10.5}
          text_color={Palette.sub()}
          max_lines={1}
        />
      </Row>
    </Column>
    """
  end

  @doc """
  The key TMDB refused, and the sentence that says what to do about it.

  The field keeps its geometry and gains a ring, and the key inside it is set in
  the red it is being refused in — so the correction below has something to
  point at. It is truncated at sixteen characters and an ellipsis for the reason
  every credential in this app is: a key printed in full is a key a screenshot
  carries away, and the leading `eyJhbGciOiJIUzI1` is already enough to tell one
  paste from another.

  `Kati.UI.rich_text/1` rather than one string, because the emphasis on
  *API Read Access Token* is the sentence's whole payload — it names the control
  on TMDB's page the reader has to go back and find. The bridge flattens it;
  see the moduledoc.
  """
  @spec bad_key() :: map()
  def bad_key do
    body = [
      text_size: 12.5,
      line_height: Kati.Locale.leading(1.55),
      text_color: Palette.cream_body()
    ]

    strong = [text_size: 12.5, font_weight: "semibold", text_color: Palette.ink()]

    # THREE RUNS AND TWO MSGIDS.
    #
    # `API Read Access Token` is the middle run and it is not translated. It is
    # the name of a control on TMDB's own settings page — the thing the reader
    # has to go back and find — so a Persian rendering of it would send them
    # looking for a label that is not there. Screen 80's version of this same
    # refusal already sits in the catalogue keeping it, and `API key` in the
    # third run, in Latin for the same reason.
    #
    # Splitting a sentence across msgids is normally how a translation gets a
    # word order it cannot fix, and it is safe here for a reason worth writing
    # down: Persian is verb-final, so the object of *copied* lands before the
    # verb — which is exactly where the emphasis already is. The run boundaries
    # survive the fold without being resequenced, and `Kati.UI.rich_text/1`
    # flattens them today regardless (see the moduledoc).
    message =
      UI.rich_text([
        {gettext("TMDB didn’t accept this key. Check you copied the "), body},
        {"API Read Access Token", strong},
        {gettext(", not the API key, and that it has no trailing space."), body}
      ])

    # THE KEY KEEPS DM MONO AND GAINS AN ISOLATE.
    #
    # A JWT fragment is ASCII and `kati_mono.ttf` has every glyph it needs, in
    # both scripts, so `mono_face/1` would answer `mono` here and the hardcoded
    # name is the honest one. Its ELLIPSIS is the problem: `…` is a neutral
    # character in the Unicode bidi algorithm, so on an RTL page it resolves
    # against the paragraph and is laid out at the left edge — `…eyJhbGciOiJIUzI1`,
    # a truncation mark in front of the thing it truncates. `Kati.Locale.ltr/1`
    # isolates the run so the mark resolves against the key instead. Screen 83's
    # licence notices are where this was found.
    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={20}
      padding={15}
      shadow={Kati.Theme.shadow_card_soft()}
    >
      {Kati.Screens.DataSourcesStates.key_label()}
      <Row
        fill_width={true}
        height={44}
        corner_radius={14}
        background={Palette.paper()}
        border_width={1.5}
        border_color={Palette.red()}
        padding_left={14}
        padding_right={14}
        align="center"
      >
        <Text
          text={Kati.Locale.ltr("eyJhbGciOiJIUzI1…")}
          font_family="mono"
          text_size={12.5}
          text_color={Palette.red()}
          max_lines={1}
        />
      </Row>
      <Spacer size={12} />
      <Row fill_width={true} align="top">
        {UI.symbol("error", size: 17, color: Palette.red())}
        <Spacer size={10} />
        <Column weight={1.0}>
          {message}
        </Column>
      </Row>
    </Column>
    """
  end

  @doc """
  A cache close to the size it is allowed to reach.

  The board's card and not `Kati.Screens.DataSources.cache/0`: 80 gives the
  figure `Refresh` and `Clear` and no bar, and this state drops both pills for
  the bar, because what the reader needs to know here is *how full*, and two
  buttons beside a number answer a different question.

  Nothing is offered to press, and that is the state's argument rather than an
  omission. `auto-refresh soon` is screen 80's promise — *Kati refreshes
  anything older than six months on its own* — coming due, so a `Clear` button
  at this moment would invite someone to do by hand the one thing the app has
  already undertaken to do for them.

  `OLDEST ENTRY 5 MONTHS` is `Kati.Screens.DataSources.age/1` inside screen 80's
  own `Oldest entry %{age}`, so the capitals, the plural and the word order are
  80's rather than retyped — which is what stops this sheet drawing an English
  `OLDEST ENTRY` over a Persian span when `Kati.PersianFontTest` sweeps it. The
  figure it is given is stated for the reason the moduledoc gives: a real oldest
  entry read on this device would be honest about a cache that is not near any
  ceiling.
  """
  @spec cache_ceiling() :: map()
  def cache_ceiling do
    oldest =
      Kati.UI.eyebrow_label(gettext("Oldest entry %{age}", age: DataSources.age(150)))

    bar =
      MishkaProgress.progress(
        render: :box,
        value: 0.83,
        max: 1,
        height: 4,
        corner_radius: 2,
        color: Palette.gold_icon(),
        track_color: Palette.paper()
      )

    # The one line on this card that was still Latin. It is the page's own
    # promise coming due — *Kati refreshes anything older than six months on its
    # own* — rather than a figure, so it is a msgid, and its face follows the
    # string for the reason `mono_face/1` exists: DM Mono carries no Persian.
    soon = gettext("auto-refresh soon")

    assigns = %{oldest: oldest, bar: bar, soon: soon}

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={20}
        padding={15}
        shadow={Kati.Theme.shadow_card_soft()}
      >
        <Row fill_width={true} align="center">
          <Column weight={1.0}>
            <Text
              text={gettext("%{n} MB cached", n: Kati.Locale.number(61))}
              text_size={13.5}
              font_weight="semibold"
              text_color={:on_surface}
              max_lines={1}
            />
            <Spacer size={4} />
            <Text
              text={@oldest}
              font_family={Kati.Locale.mono_face(@oldest)}
              text_size={11}
              text_color={Palette.muted()}
              max_lines={1}
            />
          </Column>
          <Spacer size={12} />
          <Text
            text={@soon}
            font_family={Kati.Locale.mono_face(@soon)}
            text_size={11}
            text_color={Palette.sub()}
            max_lines={1}
          />
        </Row>
        <Spacer size={13} />
        {@bar}
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  The question, and the bar that answers it afterwards.

  Two cards ten apart, and the second one is 27's: `Kati.Screens.States.undo/1`
  with this page's noun in it, at 27's metrics, which are the board's here to
  the point. Drawing them together is the sheet's whole claim about the
  interaction — the confirmation is inline, so the undo bar arrives on the same
  page the question was asked on rather than behind a dismissed modal.
  """
  @spec wipe() :: map()
  def wipe do
    # `Kati.Sources.tier2/0` holds exactly three revocable-token providers, so
    # the three is real — and unlike the *Three accounts* in the question above
    # it, which is a word, this one is a FIGURE the bar prints. It goes through
    # `Kati.Locale.number/1` and reads ۳. `ngettext/4` rather than `gettext/2`
    # because English inflects the noun after it; Persian does not, so the two
    # Persian forms are the same sentence and that is not a mistake in the
    # catalogue.
    disconnected =
      ngettext(
        "%{n} account disconnected",
        "%{n} accounts disconnected",
        3,
        n: Kati.Locale.number(3)
      )

    # `Kati.Screens.States.undo/1` is borrowed unchanged and is another module's
    # file, so the two words it draws are handed to it from here — which is what
    # makes them this screen's to translate rather than 27's.
    undo = States.undo(%{icon: "undo", text: disconnected, action: gettext("Undo")})

    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.DataSourcesStates.confirm()}
      <Spacer size={10} />
      {undo}
      <Spacer size={22} />
    </Column>
    """
  end

  @doc """
  `Wipe all tokens?` — asked on the page, and answered before it is asked.

  The paragraph leads with the loss and then spends its second clause on what
  survives, which is the order the caption asks for: three accounts disconnect,
  and the library, the ratings and the history do not move. That is a true
  claim about the code and not reassurance — `Kati.Sources.disconnect_all/0`
  deletes secure-store entries and touches no resource — so the sentence can
  afford to be specific about which three nouns are safe.

  `Wipe tokens` takes the red fill and a weighted column so it spans; `Keep
  them` hugs its own label on paper. Ranking them by width rather than by
  colour alone is screen 71's arrangement for its three one-tap fixes, and it
  means the destructive answer is the one the thumb finds without the eye having
  to read a colour first.
  """
  @spec confirm() :: map()
  def confirm do
    wipe =
      Kati.Screens.DataSourcesStates.answer(
        gettext("Wipe tokens"),
        Palette.red(),
        Palette.on_ink(),
        :bold,
        true
      )

    keep =
      Kati.Screens.DataSourcesStates.answer(
        # `pgettext/2` for two words. The catalogue's register for a button is
        # the verbal noun — `ذخیره`, `جایگزینی`, `پاک‌کردن` — and a bare
        # `Keep them` gives a translator nothing to tell that from an
        # imperative; the context says this is the SAFE answer to a destructive
        # question, which is the only thing about it that has to survive.
        pgettext("the safe answer to the wipe confirmation", "Keep them"),
        Palette.paper(),
        Palette.ink_soft(),
        :semibold,
        false
      )

    # `Three accounts` is a WORD here and a figure in the undo bar below, and
    # that difference is the moduledoc's argument rather than an oversight: the
    # confirmation states the count because a specimen on a device with nothing
    # connected would otherwise count to zero and ask about an event that cannot
    # happen. A word does not go through `Kati.Locale.number/1`; the Persian
    # spells it out the same way.
    assigns = %{
      question: gettext("Wipe all tokens?"),
      paragraph:
        gettext(
          "Three accounts disconnect. Your library, ratings and history are " <>
            "untouched — only the keys go."
        )
    }

    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={20}
      padding={15}
      shadow={Kati.Theme.shadow_card_soft()}
    >
      <Row fill_width={true} align="top">
        {UI.symbol("error", size: 19, color: Palette.red())}
        <Spacer size={11} />
        <Column weight={1.0}>
          <Text
            text={@question}
            text_size={13.5}
            font_weight="bold"
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={6} />
          <Text
            text={@paragraph}
            text_size={12.5}
            line_height={Kati.Locale.leading(1.55)}
            text_color={Palette.ink_soft()}
          />
        </Column>
      </Row>
      <Spacer size={14} />
      <Row fill_width={true} align="center">
        <Column weight={1.0} fill_width={true}>
          {wipe}
        </Column>
        <Spacer size={8} />
        {keep}
      </Row>
    </Column>
    """
  end

  @doc """
  One of the confirmation's two answers, as a 40pt pill.

  `Kati.Components.MishkaPill` at the drawing's numbers — 40 tall at radius 20,
  16 of side padding, a 12.5pt label — with `padding: 0` doing the same work it
  does in `Kati.UI.SettingsList.action_pill/1`: the pill pads before it sizes,
  so without it the two edges this does not name would fall back to
  `:space_sm` and a 40pt pill would measure 40 plus two paddings.

  `fill?` is the drawing's `flex:1`. MishkaPill has no `weight` of its own — a
  weight is read off a child by the row above it — so the filling answer spans a
  weighted column instead, which is the arrangement `Kati.UI.even_row/2` and
  screen 71 both use for the same reason.

  The `tap` argument is how screen 80 reuses this pill for the LIVE
  confirmation. It defaults to `nil`, which is what a board wants — a specimen
  answer to a specimen question carries no action — and screen 80 passes
  `{self(), :wipe_confirm}` and `{self(), :wipe_cancel}`. One pill, drawn once:
  the alternative was a second copy of the drawing's numbers on the real screen,
  which is how two copies of a design drift apart.
  """
  @spec answer(String.t(), pos_integer(), pos_integer(), atom(), boolean(), tuple() | nil) ::
          map()
  def answer(label, background, color, weight, fill?, tap \\ nil) do
    MishkaPill.pill(
      label: label,
      background: background,
      color: color,
      corner_radius: 20,
      height: 40,
      padding: 0,
      padding_left: 16,
      padding_right: 16,
      text_size: 12.5,
      font_weight: weight,
      align: :center,
      fill_width: fill?,
      on_tap: tap
    )
  end
end
