defmodule Kati.Backup.Sample do
  use Gettext, backend: Kati.Gettext

  @moduledoc """
  The fixed copy on screen 128 — what a backup holds, what it leaves out, and
  the three formats it can be written as.

  None of this is a reading. `Kati.Backup.Catalog` genuinely knows which
  tables exist and `Kati.Backup.export/0` could total them, but `128.html`
  does not draw a count — it draws six *categories* ("Every section", "Ratings,
  reviews, notes" …) and two named exclusions, which is a description of the
  format, not a fact about this device's data. `Kati.Backup.SampleRestore`
  makes the same call for screen 129 and gives the reason once for both: a
  coincidence of two screens naming the same six categories would be worth
  sharing a module over, but a *description of what the export format covers*
  is closer to the format's own moduledoc than to sample data, and lives here
  rather than being derived from `Kati.Backup.Catalog.tables/0` — the table
  names are `snake_case` internals (`watch_events`, `meal_logs`), and the
  drawing's nouns ("Sessions and habits") are a product sentence no catalog
  entry could be titlecased into.

  Only `formats/0` carries a `:tag` — the other two lists have nothing a tap
  changes, so nothing on them needs an atom to be selected by. That separation
  is also what made mishka-group/kati#103 safe to land here:
  `Kati.Screens.Backup.format_tap/2` and `.format_for/1` match a row on its
  `:tag` and never on its `title`, so a row still selects itself, and the
  "not built yet" notice still names the right format, once the words are
  Persian and the atom is the only thing that did not change.

  ## Where the Persian comes from, and why folding this was a lookup

  Not from here. `Kati.Screens.BackupDark` — the dark reference for this same
  board — already types every one of these strings through `gettext/1` in its
  own `travels/0`, `not_travels/0` and `formats/0`, so each msgid below was in
  the catalogue with its Persian before this module was touched. Nothing new
  was translated; the literals were simply pointed at entries that existed.

  `Kati.Screens.BackupLarge`'s moduledoc named the consequence of not having
  done this: *Everything (JSON)*, *Per-section CSV*, *The one that restores*
  and *For a spreadsheet or another app — does not restore* drew in Latin
  under `:fa` on 128 and 133 both, because both boards read `formats/0` and
  `formats/0` reached no catalogue at all. It also said the fix belonged in
  this module and nowhere else, rather than in the two screens retyping the
  copy — this is that fix, so that paragraph and the matching note on
  `Kati.Screens.BackupLarge.format_row/2` describe history now.

  What does not fold is the machine's own name for a thing: `JSON`, `CSV`,
  `.ics` and `TMDB` are spelled one way everywhere, and transliterating one
  would have the app disagree with the file it just wrote. `Kati` stays
  itself for `Kati.Services.Service`'s reason — a name a real service answers
  to cannot be spelled two ways on one page.
  """

  # THREE FUNCTIONS THAT MUST STAY THREE FUNCTIONS. Every list below now holds
  # `gettext/1` calls, and `gettext/1` inside a `@travels [...]` is evaluated at
  # COMPILE time: the list would freeze in whichever locale the compiler
  # happened to be in and every reader on every device would be handed that one.
  # `Kati.Screens.BackupDark` moved three module attributes to three `defp`s for
  # exactly this reason. This module was already the right shape — the shape is
  # load-bearing now rather than incidental, so nobody should tidy it back.

  @doc "What travels: the six categories `128.html` lists as included, in its own order."
  @spec travels() :: [map()]
  def travels do
    [
      %{
        icon: "check",
        title: gettext("Every section"),
        sub: gettext("Screen, Books, Music, Health")
      },
      %{
        icon: "check",
        title: gettext("Ratings, reviews, notes"),
        sub: gettext("With their dates")
      },
      %{
        icon: "check",
        title: gettext("Sessions and habits"),
        sub: gettext("Every tick, every streak")
      },
      %{icon: "check", title: gettext("Meals and plans"), sub: gettext("With their ingredients")},
      %{
        icon: "check",
        title: gettext("Calendar events Kati owns"),
        sub: gettext("Not your connected calendars")
      },
      # `Settings` is the sixth category's own noun and the name of the screen
      # 128 is pushed from, and one entry answers both: `Kati.Screens.Pushed`
      # and `Kati.Screens.Settings` already put that exact msgid in the
      # catalogue, so the back pill and this row cannot come out as two
      # different Persian words for one place.
      %{icon: "check", title: gettext("Settings"), sub: gettext("Language, units, sections")}
    ]
  end

  @doc """
  What does not travel, and why each one is left out on purpose.

  Both reasons are arguments, not apologies — a cache is cheap to rebuild and a
  token is device-bound — which is why the drawing gives each one a full
  sentence rather than a bare noun.
  """
  @spec stays() :: [map()]
  def stays do
    [
      # `TMDB` stays Latin inside the Persian sentence and takes no
      # `Kati.Locale.ltr/1`: four Latin letters are a STRONG run with no
      # neutral character beside them, and a strong run inside an RTL line
      # places itself correctly with no help. The isolates below are for the
      # runs that do have a neutral — a bracket, a leading full stop.
      %{
        icon: "block",
        title: gettext("Cached provider metadata"),
        sub: gettext("Re-fetchable, and capped at six months by TMDB’s terms anyway")
      },
      %{
        icon: "block",
        title: gettext("Connected tokens"),
        sub: gettext("Revocable, and meant to be re-entered on the new device")
      }
    ]
  end

  @doc """
  The three formats, safest-to-restore first — the drawing's own order and its
  own default.

  Only `:json` is real. `Kati.Backup.export_to_file/2` writes exactly this
  shape; there is no per-section CSV writer and no `.ics` writer anywhere in
  `Kati.Backup` or `Kati.Calendars`. Naming that here rather than pretending
  otherwise is what lets `Kati.Screens.Backup.save/1` answer honestly when
  either of the other two is chosen — see its moduledoc.
  """
  @spec formats() :: [map()]
  def formats do
    # THE FORMAT NAME COMES OUT OF ITS SENTENCE AND BACK IN THROUGH
    # `Kati.Locale.ltr/1`, and the interpolation is not a style choice — it is
    # what the msgid has to look like for the Persian to be drawable at all.
    #
    # `(JSON)` and `(.ics)` are handed over WHOLE, brackets included, rather
    # than wrapped around the word inside them. A bracket is a NEUTRAL
    # character in the bidi algorithm and it is MIRRORED: inside a Persian
    # line it resolves to the page's direction and renders as its opposite, so
    # `همه‌چیز (JSON)` draws as `همه‌چیز )JSON(`. Isolating `JSON` alone does not
    # help — the brackets would still be outside the isolate, still neutral,
    # still mirrored — so the isolate has to contain the punctuation it exists
    # to protect. The leading full stop of `.ics` in the reason sentence is the
    # same neutral, and without the isolate it lands on the far side of the run
    # as `ics.` mid-line.
    #
    # `Kati.Screens.BackupDark.format_title/1` carries the identical pair of
    # msgids and the long form of this argument. It is not called from here:
    # this is `Kati.Backup`, and a domain module reaching up into
    # `Kati.Screens` to name its own data would invert the one dependency
    # direction 128, 132 and 133 all rely on.
    [
      %{
        tag: :json,
        icon: "description",
        title: gettext("Everything %{format}", format: Kati.Locale.ltr("(JSON)")),
        sub: gettext("The one that restores")
      },
      # `Per-section CSV` needs no isolate and gets none: `CSV` is three Latin
      # letters with nothing neutral beside them.
      %{
        tag: :csv,
        icon: "upload_file",
        title: gettext("Per-section CSV"),
        sub: gettext("For a spreadsheet or another app — does not restore")
      },
      %{
        tag: :ics,
        icon: "calendar_month",
        title: gettext("Calendar %{format}", format: Kati.Locale.ltr("(.ics)")),
        sub:
          gettext("Because Kati owns a calendar and %{ext} is what a calendar is",
            ext: Kati.Locale.ltr(".ics")
          )
      }
    ]
  end

  @doc "The format chosen before anyone has touched the row set — the drawing's own check mark."
  @spec default_format() :: atom()
  def default_format, do: :json
end
