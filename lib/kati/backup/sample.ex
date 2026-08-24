defmodule Kati.Backup.Sample do
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
  changes, so nothing on them needs an atom to be selected by.
  """

  @doc "What travels: the six categories `128.html` lists as included, in its own order."
  @spec travels() :: [map()]
  def travels do
    [
      %{icon: "check", title: "Every section", sub: "Screen, Books, Music, Health"},
      %{icon: "check", title: "Ratings, reviews, notes", sub: "With their dates"},
      %{icon: "check", title: "Sessions and habits", sub: "Every tick, every streak"},
      %{icon: "check", title: "Meals and plans", sub: "With their ingredients"},
      %{
        icon: "check",
        title: "Calendar events Kati owns",
        sub: "Not your connected calendars"
      },
      %{icon: "check", title: "Settings", sub: "Language, units, sections"}
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
      %{
        icon: "block",
        title: "Cached provider metadata",
        sub: "Re-fetchable, and capped at six months by TMDB’s terms anyway"
      },
      %{
        icon: "block",
        title: "Connected tokens",
        sub: "Revocable, and meant to be re-entered on the new device"
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
    [
      %{
        tag: :json,
        icon: "description",
        title: "Everything (JSON)",
        sub: "The one that restores"
      },
      %{
        tag: :csv,
        icon: "upload_file",
        title: "Per-section CSV",
        sub: "For a spreadsheet or another app — does not restore"
      },
      %{
        tag: :ics,
        icon: "calendar_month",
        title: "Calendar (.ics)",
        sub: "Because Kati owns a calendar and .ics is what a calendar is"
      }
    ]
  end

  @doc "The format chosen before anyone has touched the row set — the drawing's own check mark."
  @spec default_format() :: atom()
  def default_format, do: :json
end
