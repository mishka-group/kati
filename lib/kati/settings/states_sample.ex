defmodule Kati.Settings.StatesSample do
  @moduledoc """
  The copy screen 27 puts in each of the states nobody designs.

  This is a reference sheet rather than a screen with a domain behind it, so
  the "sample" here is the specimen itself: the empty state's invitation, the
  three fading skeleton rows, the offline promise, the failed check, and the
  undo bar. Every one of them is real copy from the drawing, because the point
  of the sheet is the wording as much as the layout.

  ## The skeleton's opacities are baked, not applied

  The drawing fades its three rows to 1, .75 and .5. No Mob node carries an
  `opacity` prop, so each row's colours are composited against the `#EFECE7`
  paper here instead — the same pixels, arrived at arithmetically. The shadow
  alphas are scaled by the same factors, or the third row would sit on a
  shadow it has no body to cast.

  ## The specimen speaks both scripts, and the screen only typesets it

  mishka-group/kati#103. `Kati.Screens.States` owns seven strings — its title,
  its subtitle and the five band eyebrows. Every other word on screen 27 is
  this module's, and it is translated **here**: a msgid has to be a literal at
  its own call site, so wrapping these from the screen would move the copy out
  of the specimen, which is the one thing the specimen exists to hold.
  `Kati.Settings.DropStatesSample` makes the same split against screen 148 and
  states the argument at the same length.

  What stays the screen's is the TYPESETTING — both headings' tracking, both
  paragraphs' leading, the retired paragraph's `max_lines` — and that file says
  so. Nothing here needs a mono face or a directional glyph: the one mono line
  on the sheet is the subtitle, which the screen owns, and the undo glyph is
  deliberately not mirrored (`Kati.Screens.DropSheet.undo_pill/2` gives the
  reason — it means *take that back*, not *where you are going*).

  ## Most of these msgids already existed, which is what a reference sheet is for

  A sheet that quotes the states every other screen passes through should quote
  their WORDS, and eleven of the sixteen msgids below were in the catalogue
  before this file was folded: the empty state's four lines are
  `Kati.Screens.Library`'s own empty shelf, `Offline` is
  `Kati.Screens.DataSourcesStates`' badge under its `the device has no network`
  context, `Last success %{n}h ago` and `Retry` are
  `Kati.Screens.BookDetailStates`' failed check, `Dropped %{title}%{at}` and
  `Undo` are `Kati.Screens.DropSheet`'s undo pill, and `Not set up` and `Sleep`
  are what screens 42 and 114 call the tile reproduced in the retired band. An
  exact msgid always beats a fuzzy one, and a contexted twin on a sheet whose
  job is to be quoted would be the app saying the same thing twice in Persian.

  Five are new — the offline promise, the failed check's heading, the retired
  band's title and paragraph, and `The Quiet Ones`, which
  `Kati.Activity.Sample.earlier/0` calls too and the catalogue has not been
  re-extracted for yet. Every one of them is either long enough that
  `mix gettext.merge` has nothing to confuse it with or an exact title:
  the closest neighbour to any is `Couldn’t read this file` at .77 against
  `Couldn’t check for releases`, under the .8 fuzzy threshold.

  ## `6h ago` is a figure, and figures are the half gettext cannot do

  The hour is rendered, so it goes through `Kati.Locale.number/1` and the badge
  reads **آخرین موفقیت ۶ ساعت پیش** rather than keeping a Latin `6` between two
  Persian words. That does not turn the drawing into a report:
  `Kati.Screens.States`' moduledoc spends four paragraphs on why this figure is
  not read from `Kati.Calendars.Account.last_sync_at`, and the numeral being the
  reader's own changes none of it — the drawing owns the figure, the locale owns
  the digits.

  ## The undo bar borrows screen 149's sentence rather than writing a second one

  `Dropped %{title}%{at}` is `Kati.Screens.DropSheet.undo_pill/2`'s msgid, and
  board 27's bar is that same sentence with no position on it — which is exactly
  what `Kati.Screens.DropSheet.at/1` hands over for a title that has none. So
  English is the board's own *Dropped The Quiet Ones* either way, and Persian
  gets the verb last, **خاموشان رها شد**, which is a placement only the whole
  sentence in one msgid can make. The title is `Kati.Activity.Sample`'s msgid —
  the same show at the same seed (`quietones12`) — so the one title this app
  keeps for a *dropped* specimen stays one title in Persian too.

  No `Kati.Locale.ltr/1` around it. The isolate is for a Latin run inside a
  Persian sentence, and a translated title is not one: wrapping it would force
  LTR onto Persian words.
  """

  use Gettext, backend: Kati.Gettext

  # Bound once and drawn twice — the retired band's paragraph states the rule
  # and its example tile obeys it, and two calls would agree today and drift the
  # first time either is re-worded. The msgid is screen 42's own, already
  # **راه‌اندازی نشده**.
  defp not_set_up, do: gettext("Not set up")

  @doc "Empty — the state that has to sell the app rather than apologise."
  @spec empty() :: map()
  def empty do
    # All four are `Kati.Screens.Library`'s empty shelf, msgid for msgid, and
    # that is the whole point of the band: 27 draws the empty state the library
    # draws, so a reader who meets it on both pages meets the same four
    # sentences. Plain `gettext/1` on every one — each is already in the
    # catalogue under exactly this msgid, and an exact match beats a fuzzy one.
    %{
      icon: "movie",
      title: gettext("No titles yet"),
      body: gettext("Add one thing you are watching and the calendar starts filling itself."),
      action: gettext("Add a title"),
      secondary: gettext("or import a backup")
    }
  end

  @doc """
  The three skeleton rows, already composited against paper.

  `card` is `#FBFAF8` over `#EFECE7`, `bar` is `#E7E3DC` over the same, each at
  the row's own opacity; `shadow` is the design's two-layer card recipe with
  both alphas scaled to match.
  """
  @spec skeletons() :: [map()]
  def skeletons do
    [
      %{
        card: 0xFFFBFAF8,
        bar: 0xFFE7E3DC,
        shadow: "0 1 2 0 #0A1A1917 | 0 12 24 -18 #B31A1917"
      },
      %{
        card: 0xFFF8F7F4,
        bar: 0xFFE9E5DF,
        shadow: "0 1 2 0 #081A1917 | 0 12 24 -18 #861A1917"
      },
      %{
        card: 0xFFF5F3F0,
        bar: 0xFFEBE8E2,
        shadow: "0 1 2 0 #051A1917 | 0 12 24 -18 #591A1917"
      }
    ]
  end

  @doc "Offline — a promise about the ticks, not an apology for the network."
  @spec offline() :: map()
  def offline do
    # `Offline` is one word and `pgettext/2` for it, with
    # `Kati.Screens.DataSourcesStates.offline/0`'s context verbatim — quoting the
    # context is the point. Three cards across the app mean the same thing by it
    # (the radio is off, not a provider that cannot be reached), and one msgid is
    # what stops the sheet that DEFINES the badge from wording it differently
    # from the sheets that draw it.
    %{
      icon: "cloud_off",
      title: pgettext("the device has no network", "Offline"),
      sub: gettext("Ticks are saved and will sync later")
    }
  end

  @doc "A failed check, with the last success named and a way to try again."
  @spec error() :: map()
  def error do
    # The last-success line is `Kati.Screens.BookDetailStates.alerts/0`'s msgid,
    # hour and all: 27 is where that card was drawn first and the detail sheet
    # quotes it, so the two cannot be allowed to count hours in two different
    # sentences. The figure goes through `Kati.Locale.number/1` — see the
    # moduledoc for why that is typography and not a claim about the sync log.
    %{
      icon: "error",
      title: gettext("Couldn’t check for releases"),
      sub: gettext("Last success %{n}h ago", n: Kati.Locale.number(6)),
      action: gettext("Retry")
    }
  end

  @doc "The undo bar every destructive action puts up."
  @spec undo() :: map()
  def undo do
    # Screen 149's sentence with the position left out — see the moduledoc.
    # `at: ""` is not an interpolation bent to fit: it is exactly what
    # `Kati.Screens.DropSheet.at/1` returns for a title with no captured
    # position, and its doctest says so.
    text =
      pgettext("the undo pill's sentence after a drop", "Dropped %{title}%{at}",
        title: gettext("The Quiet Ones"),
        at: ""
      )

    # Plain `gettext/1` on `Undo`, which is normally what `pgettext/2` is for at
    # one word — but the msgid already exists and is already **برگرداندن** on
    # `Kati.Screens.ShelfSelection`'s bar and `Kati.Screens.DropSheet`'s pill.
    # The band this sits under is *Undo — every destructive action*, so the word
    # every destructive action puts up had better be the same word here.
    %{icon: "undo", text: text, action: gettext("Undo")}
  end

  @doc """
  The sixth band: a surface Kati draws and cannot open.

  The other five are states a screen passes through. This one is a state a
  *screen* is in, and it is here because #22 asked for the ritual that was
  missing — how a drawn surface gets downgraded to *not in v1* without the
  design losing coherence. Screen 42 invented the visual answer and used it
  once; naming it here is what makes it a pattern.

  `example` is the tile screen 42 draws for Sleep, reproduced rather than
  imported: this sheet is a reference, and a reference that reads a section
  list would report what the app happens to hold today instead of what the
  treatment looks like.
  """
  @spec retired() :: map()
  def retired do
    %{
      title: gettext("A surface Kati draws and cannot open"),
      # `Not set up` is interpolated rather than typed into the sentence, the
      # move `Kati.Settings.DropStatesSample.dropped_note/0` makes for its own
      # quoted state word: this paragraph states the rule and the tile under it
      # obeys the rule, so the two have to be the same string. Typed twice, the
      # paragraph could end up naming a status in words the tile does not use —
      # in one locale, silently, on a sheet where nothing is asserted against a
      # string. The English is unchanged either way.
      body:
        gettext(
          "It keeps its place, dashed rather than filled, and says %{status}. " <>
            "It never says coming soon — a date is a promise this version cannot " <>
            "keep. Tapping it opens one sheet that names what it is, why it is not " <>
            "here, and what Kati can do instead today.",
          status: not_set_up()
        ),
      # `Sleep` is DRAWN here and so it is translated, which is the opposite of
      # the `"Sleep"` in `Kati.Screens.States.handle_tap/2` — that one is a key
      # matched against the untranslated `name` on `Kati.Health.Sample.sections/0`
      # and stays Latin. The two are independent on purpose: the tile says
      # **خواب** to the reader while the push that opens screen 114 keeps the
      # word the lookup needs. `Kati.Retired`'s moduledoc has the long version of
      # *a label doubling as compared state*, which is the defect that split
      # them. mishka-group/kati#103.
      example: %{icon: "bedtime", name: gettext("Sleep"), status: not_set_up()}
    }
  end
end
