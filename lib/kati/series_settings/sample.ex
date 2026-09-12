defmodule Kati.SeriesSettings.Sample do
  @moduledoc """
  Stand-in per-show settings, until the Screen domain exists.

  Screen 35's caption states the decision this data encodes: *"explicit
  per-show state — watching, paused or dropped as a first-class choice rather
  than a swipe action, plus the season pass and the region that decides what
  'available' means."* So `statuses/0` is three peers with one selected, not a
  boolean with an escape hatch.

  Three groups, and the third is deliberately not a peer of the first two —
  screen 35 gives **This show** a grey dash where the others get the accent
  one, because reset, archive and remove are things you do *to* the show
  rather than settings the show carries. `Kati.UI.SettingsList.eyebrow_muted/1`
  is what draws that distinction, and it is a distinction, not a shade.

  Marked clearly rather than hidden: sample data that looks like real data is
  how a demo quietly becomes a lie.

  ## Most of board 35's words live here, and they are not the drawing's alone

  mishka-group/kati#103. `Kati.Screens.SeriesSettings` owns five strings, all
  of them chrome — the subtitle and the four eyebrows — and this module owns
  every other word on the page: the show's name, the three status labels, and
  the title and sub-line of all eleven rows.

  Four of those rows are not a picture. `Kati.Screens.SeriesSettings.season_pass/1`
  and `status_tiles/1` keep reading this file over a REAL show as well, because
  what a switch does does not change with whose show it is — so these msgids
  are most of what a reader with a library sees here too, not just what the
  gallery draws. They are wrapped where they are declared and not a second time
  in the screen: one msgid per string, wherever the string lives, and a screen
  that made its own copy of a fixture's copy would be two strings to keep in
  step.

  Every group is a FUNCTION and none of them is an attribute, which matters now
  that they hold `gettext/1`: a module attribute is evaluated at COMPILE time
  and would freeze eleven rows in whichever locale the compiler happened to be
  in.

  ## What stays Latin, and what only looks like it may

  `Lumen+`, `Orbit` and `Kino` are service names and stay out of the msgid
  altogether — a real service's name comes off `Kati.Services.Service`, where
  no msgid reaches it, so a fixture that transliterated one would spell the
  same service two ways one screen apart. Board 127 draws `Lumen+` in Latin on
  a Persian page for exactly that reason, and `4K HDR` is the same kind of
  mark: a format's name rather than a sentence about one.

  The figures are not. `5 of 7`, `3 of 12`, `S4` and the `£8` threshold all go
  through `Kati.Locale`, because a Persian page drawing Latin numerals is the
  half of this fold no audit catches — the sweep that found this screen's
  untranslated copy matches runs of four or more Latin LETTERS and cannot see
  a numeral at all.
  """

  use Gettext, backend: Kati.Gettext

  @doc "The show these settings belong to, as screen 35 draws it."
  @spec show() :: map()
  def show do
    %{
      # A name Kati READS is not a msgid — `Kati.Screens.SeriesSettings.title_of/1`
      # takes a real show's title out of the release cache and draws it
      # untranslated, because a name somebody's library holds is theirs. A name
      # Kati DREW is copy: `Kati.Library.Sample` writes the same invented nine
      # titles through `gettext/1`, so board 57 heads its shelf گودال بلند
      # where board 03 heads `The Long Hollow`, and the two are one msgid.
      title: gettext("The Long Hollow"),
      # The same five msgids the screen writes on the branch this fixture never
      # reaches — `shaped/1` for the first three, `region_band/1` and
      # `this_show_band/1` for the last two. One catalogue entry each, so the
      # drawn page and a real show cannot say different things in Persian.
      subtitle: gettext("show settings"),
      status_label: gettext("Status"),
      season_pass_label: gettext("Season pass"),
      region_label: gettext("Region & availability"),
      this_show_label: gettext("This show")
    }
  end

  @doc "Watching, paused or dropped — three peers, one chosen."
  @spec statuses() :: [map()]
  def statuses do
    # `pgettext("shelf status", …)` and not `gettext/1`. These three are the
    # shelf's own words for `Kati.Media.TrackedTitle.status` — the same three
    # `Kati.Screens.Series.status_label/1` writes onto screen 04's chip, and a
    # show cannot be رهاشده on the shelf and رها شد one push in. The context is
    # load-bearing for the third especially: the catalogue answers a bare
    # `Dropped` nowhere, and the activity log's `Dropped` is a verb about a
    # moment rather than the state a show is sitting in.
    #
    # `status` is the field the tap is built from — `status_tap/1` through
    # `Kati.Screens.AddByHand.tag/2` — and `label` is only ever drawn. That
    # split is the one #103 keeps finding the wrong way round: a tag built out
    # of the LABEL renames itself the moment the language does, and the tap
    # then matches nothing.
    [
      %{
        icon: "play_circle",
        label: pgettext("shelf status", "Watching"),
        status: :watching,
        on: true
      },
      %{
        icon: "pause_circle",
        label: pgettext("shelf status", "Paused"),
        status: :paused,
        on: false
      },
      %{
        icon: "do_not_disturb_on",
        label: pgettext("shelf status", "Dropped"),
        status: :dropped,
        on: false
      }
    ]
  end

  @doc "What the app does on its own once a show is followed."
  @spec season_pass() :: [map()]
  def season_pass do
    [
      %{
        icon: "featured_seasonal_and_gifts",
        title: gettext("Auto-add new seasons"),
        # `S4` is written into the msgid the way every other season line in the
        # app writes one — `Kati.Screens.ClearHistory`'s bookmark is
        # `S%{s} · E%{e}` — so a translation can put فصل in front of a numeral
        # in the reader's own digits instead of carrying a Latin `S4` across.
        # The sub-line survives over a real show (see the screen's moduledoc):
        # it says what the switch DOES rather than where this show is.
        sub: gettext("S%{n} will appear when announced", n: Kati.Locale.number(4)),
        control: {:switch, true}
      },
      %{
        icon: "notifications",
        title: gettext("Tell me about episodes"),
        sub: gettext("Inbox only, no push"),
        control: {:switch, true}
      },
      %{
        icon: "event",
        title: gettext("Put air dates on calendar"),
        # One msgid rather than `gettext("Personal")` joined to a colour word:
        # the line is a single clause about where the dates land, and a bare
        # `orange` would be a one-word entry for `mix gettext.merge` to fuzzy
        # -match onto any sentence that ends in the same letters. The calendar
        # it names is the one `Kati.Screens.Day.chip_label/1` draws as شخصی,
        # and this entry's Persian says شخصی for that reason — the agreement is
        # in the word chosen, not in a second call reaching across for it.
        sub: gettext("Personal · orange"),
        control: {:switch, true}
      },
      %{
        icon: "visibility_off",
        title: gettext("Hide unwatched titles"),
        sub: gettext("Spoiler-safe episode names"),
        control: {:switch, false}
      }
    ]
  end

  @doc "What decides whether a title counts as available at all."
  @spec region() :: [map()]
  def region do
    [
      %{
        icon: "public",
        title: gettext("Region"),
        sub: gettext("United Kingdom"),
        control: :chevron
      },
      %{
        icon: "subscriptions",
        title: gettext("My services"),
        # The three names stay Latin and stay OUT of the msgid — see the
        # moduledoc. `Kati.Locale.ltr/1` because the run carries a `+` and two
        # commas, all of them bidi-neutral: inside a Persian line they resolve
        # against the PAGE rather than against the run and land at the wrong
        # edge, which is what screen 83's licence notices did with their full
        # stops. The count is the reader's own numerals either way.
        sub:
          gettext("%{services} · %{n} of %{total}",
            services: Kati.Locale.ltr("Lumen+, Orbit, Kino"),
            n: Kati.Locale.number(3),
            total: Kati.Locale.number(12)
          ),
        control: :chevron
      },
      %{
        icon: "sell",
        title: gettext("Watch for price drops"),
        # `£8` is a THRESHOLD, not a price on an invoice, which is why board 35
        # writes it with no minor unit. Neither money formatter can render it:
        # `Kati.Services.Service.format/2` and `Kati.Money.display/2` both force
        # two decimals on purpose — *a price that renders as £9 beside one that
        # renders as £13.99 reads as an estimate* — and `£8.00` here would be
        # this file quietly rewriting the board's own line. So the figure is
        # composed instead: the digits through `Kati.Locale.number/1` and the
        # currency placed by the translation, which is board 127's shape for a
        # sum inside a SENTENCE (`۶۱٫۴۰ پوند`) rather than the symbol form the
        # ledger rows use.
        sub: gettext("Wishlist titles under £%{amount}", amount: Kati.Locale.number(8)),
        control: {:switch, true}
      },
      %{
        icon: "hd",
        title: gettext("Preferred quality"),
        # `4K HDR` rides inside the msgid rather than being interpolated
        # through `Kati.Locale.ltr/1`: the run holds no neutral character at
        # all — its space sits between two Latin letters and nothing trails it
        # — so there is nothing for an isolate to protect, and a
        # `%{format} where offered` msgid would be three words a merge could
        # fuzzy-match onto anything. The Persian keeps the mark as drawn.
        sub: gettext("4K HDR where offered"),
        control: :chevron
      }
    ]
  end

  @doc """
  Things done to the show rather than settings it carries.

  The last one is `danger: true`: the drawing tints its tile and its label
  `#B4553C` and gives it no second line, because there is nothing reassuring
  to say underneath it.
  """
  @spec this_show() :: [map()]
  def this_show do
    [
      %{
        icon: "replay",
        title: gettext("Reset progress"),
        # A frozen figure, and it stays one honestly: this whole group is
        # dropped over a real show — `Kati.Screens.SeriesSettings.this_show_band/1`
        # — so `5 of 7` is never shown to somebody whose season it would be
        # wrong about. That is what keeps it copy rather than a claim. It still
        # goes through `Kati.Locale.number/1`, because the board a Persian
        # reader lands on is this one, and `5 of 7` in Latin digits under a
        # Persian heading is the defect the letter-run audit cannot see.
        sub:
          gettext("Currently %{n} of %{total} in S%{season}",
            n: Kati.Locale.number(5),
            total: Kati.Locale.number(7),
            season: Kati.Locale.number(2)
          ),
        control: :chevron
      },
      %{
        icon: "archive",
        title: gettext("Archive"),
        sub: gettext("Keeps history, hides from shelf"),
        control: :chevron
      },
      %{icon: "delete", title: gettext("Remove from library"), control: :chevron, danger: true}
    ]
  end
end
