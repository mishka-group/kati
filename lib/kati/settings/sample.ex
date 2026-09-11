defmodule Kati.Settings.Sample do
  @moduledoc """
  Stand-in preferences, until a settings domain exists.

  Screen 24 is drawn full — every section switched on but Money, a sync badge
  that has an opinion about how fresh it is, a last backup with a date on it.
  A settings screen rendered against defaults would show five identical rows
  and none of the states the drawing specifies, so this supplies the shape the
  domain will supply later: a list of rows, each naming its **id**, its icon,
  its copy and its control.

  ## Why a row carries an id

  It did not, and the screen inferred one: `Kati.Screens.Settings` keyed its
  destination table on the DRAWN TITLE and built each tap tag as
  `String.to_atom("go_" <> title)`, which is how `:"go_Export everything"` — an
  atom with a space in it — came to cross into Kotlin and back. The section
  switches were worse: `flip_switch/2` did `String.downcase(title)` and looked
  the result up in `Kati.Sections.all/0`, and `String.downcase/1` on a Persian
  title is a no-op, so the moment the copy became `gettext(...)` every section
  would have refused to flip and every chevron would have vanished — silently,
  because `tap_for/1` answers `nil` for a title it does not recognise and
  `handle_tap/2` returns the socket unchanged on `:error`.

  That is mishka-group/kati#103's recurring defect — a label doubling as
  compared state — and an id is the answer to it: the one field on a row that
  is not copy, so the English screen and the Persian one name the same rows
  without a translation table between them. The five section rows take
  `Kati.Sections`' own ids, so the switch and the store agree by construction
  rather than by a downcase. The GLYPH is not that field, which
  `Kati.Screens.SettingsFa` keyed on and which nearly was the answer here:
  `info` is both *Version* and *Where this comes from*, and `grid_view` is
  *Widgets*, *Year cards* and *Every screen*.

  Copy is the drawing's own, down to the typographic apostrophe in
  "another tracker's backup". Marked clearly as a stand-in, because sample
  data that looks like real data is how a demo quietly becomes a lie.
  """

  @doc "The mono line under the title."
  @spec synced() :: String.t()
  def synced, do: "Synced 2 min ago"

  @doc "The account card: the design's own photograph, its counts and its sync state."
  @spec account() :: map()
  def account do
    %{
      seed: "face68",
      name: "Your Kati",
      meta: "1,204 ENTRIES · 4 SECTIONS",
      status: "Synced"
    }
  end

  @doc "Appearance — the one group whose first row carries a segmented control."
  @spec appearance() :: [map()]
  def appearance do
    [
      %{
        id: "theme",
        icon: "contrast",
        title: "Theme",
        sub: nil,
        control: {:segments, ["Auto", "Light", "Dark"], "Auto"}
      },
      %{
        id: "text_size",
        icon: "format_size",
        title: "Text size",
        sub: "Follows system · up to 235%",
        control: :chevron
      },
      %{
        id: "reduce_motion",
        icon: "motion_blur",
        title: "Reduce motion",
        sub: nil,
        control: {:switch, false}
      },
      %{
        id: "language",
        icon: "translate",
        title: "Language",
        sub: "English · فارسی",
        control: :chevron
      },
      %{
        id: "widgets",
        icon: "grid_view",
        title: "Widgets",
        sub: "Home and lock screen",
        control: :chevron
      }
    ]
  end

  @doc """
  Watching — the one group that decides what the rest of the app may claim.

  One row, and it sits between Appearance and Sections rather than under Data,
  because it is not a source of data — it is the question *what can I actually
  watch*, which everything in the media half of the app is downstream of.
  Screen 92 is where it goes.
  """
  @spec watching() :: [map()]
  def watching do
    [
      %{
        id: "my_services",
        icon: "subscriptions",
        title: "My services",
        sub: Kati.Settings.Sample.services_line(),
        control: :chevron
      }
    ]
  end

  @doc """
  The *My services* row's second line: the country, and how many services.

  `none yet` rather than `0 subscribed`, which is Home's own wording for the
  same fact one screen away and board 93's for it on the page this row opens.
  A zero is an answer; this is the absence of one, and the two read
  differently to somebody who has just installed the app.

      iex> Kati.Settings.Sample.services_line(:gb, 0)
      "United Kingdom · none yet"

      iex> Kati.Settings.Sample.services_line(:gb, 1)
      "United Kingdom · 1 subscribed"

      iex> Kati.Settings.Sample.services_line(:gb, 3)
      "United Kingdom · 3 subscribed"
  """
  @spec services_line() :: String.t()
  def services_line do
    services_line(
      Kati.Services.region_name(Kati.Services.region()),
      length(Kati.Screens.MyServices.subscribed())
    )
  end

  @doc false
  def services_line(:gb, count), do: services_line("United Kingdom", count)
  def services_line(region, 0), do: "#{region} · none yet"
  def services_line(region, count), do: "#{region} · #{count} subscribed"

  @doc """
  Sections — the growth mechanic made literal.

  Each row states which surfaces its section appears on, which is why the
  secondary line is not decoration: turning Music off removes a shelf, and the
  row says so before you touch it.
  """
  @spec sections() :: [map()]
  def sections do
    [
      %{
        id: "screen",
        icon: "movie",
        title: "Screen",
        sub: "Home card, calendar feed, shelf",
        control: {:switch, true}
      },
      %{
        id: "books",
        icon: "menu_book",
        title: "Books",
        sub: "Home card, shelf",
        control: {:switch, true}
      },
      %{
        id: "music",
        icon: "graphic_eq",
        title: "Music",
        sub: "Shelf only",
        control: {:switch, true}
      },
      %{
        id: "habits",
        icon: "bolt",
        title: "Habits",
        sub: "Calendar feed",
        control: {:switch, true}
      },
      %{
        id: "money",
        icon: "payments",
        title: "Money",
        sub: "Calendar feed",
        control: {:switch, false}
      },
      %{
        id: "reorder_sections",
        icon: "drag_indicator",
        title: "Reorder sections",
        sub: "Drag to change home order",
        control: :chevron
      }
    ]
  end

  @doc """
  Data — back up, restore, import, export, sync, and the one destructive row.

  ## The two backup rows come first, and the order is the argument

  Kati has no server by locked decision, so a backup is the only thing between
  a user and losing everything when a phone dies. The 23 August redraw puts
  **Back up everything** and **Restore a Kati backup** at the head of this
  group, above Import and Export, and that ordering is the design saying which
  of the five a person is most likely to be here for.

  ## Restore and Import are two rows because they are two acts

  *Your own file — merges or replaces* against *CSV, JSON, or another tracker's
  backup*. One is your data coming home and one is somebody else's data
  arriving, and #25 asks specifically that the two be visibly different rather
  than one row with two meanings. They route to different screens.

  `Export everything` stays alongside `Back up everything` rather than being
  folded into it: a backup is the restorable format and an export is the
  portable one, and screen 128 draws both as choices *within* the backup screen.
  The row here is the shortcut for someone who already knows which they want.
  """
  @spec data() :: [map()]
  def data do
    [
      %{
        id: "back_up",
        icon: "cloud_done",
        title: "Back up everything",
        sub: "Last backup 14 Aug · 214 MB",
        control: :chevron
      },
      %{
        id: "restore",
        icon: "upload_file",
        title: "Restore a Kati backup",
        sub: "Your own file — merges or replaces",
        control: :chevron
      },
      %{
        id: "import",
        icon: "download",
        title: "Import",
        sub: "CSV, JSON, or another tracker’s backup",
        control: :chevron
      },
      %{
        id: "export",
        icon: "upload",
        title: "Export everything",
        sub: "Last backup 14 Aug",
        control: :chevron
      },
      %{
        id: "sync",
        icon: "sync",
        title: "Sync",
        sub: "iCloud · this device + iPad",
        control: :chevron
      },
      %{
        id: "data_sources",
        icon: "dns",
        title: "Data sources",
        sub: "TVmaze, Open Library, MusicBrainz · 3 reachable",
        control: :chevron
      },
      # Board 267's own edit to this row: it was the only row in this group
      # "whose meaning cannot be read before tapping it", and a destructive row
      # is the last one that should be. The line is the board's.
      %{
        id: "clear_history",
        icon: "delete",
        title: "Clear watch history",
        sub: "Ticks, ratings and reviews — the shelves stay",
        control: :chevron
      }
    ]
  end

  @doc """
  Sources — where Kati's information comes from, as opposed to where it goes.

  Not in screen 24's drawing, which was drawn before 25, 32 and 36 existed and
  whose Data group is about moving a library in and out: import, export, sync,
  and the one destructive row. Reading the phone's calendars, watching for a
  premiere and noticing what is playing are the opposite direction, and filing
  them under Data would have made that group mean two things.

  The screens are drawn and finished; only the way in was missing, and the
  caption on 24 claims the screen is "everything the app can be told". #7 and
  #61 name this group *Data sources* and give it a screen of its own; when
  that lands, these three rows are what it inherits.
  """
  @spec sources() :: [map()]
  def sources do
    [
      %{
        id: "calendars",
        icon: "calendar_month",
        title: "Calendars",
        sub: "Which calendars Kati may read",
        control: :chevron
      },
      # MOVIES-AND-TV.md #1. Screen 05 had no English door at all: its only one
      # was Home's *New this week* hero, which is omitted unless a followed
      # title has an unticked episode from the last seven days — so a reader
      # with nothing out this week could not reach the page that would tell
      # them so. The Persian build reached it and the English one did not,
      # which `routes.txt` found empirically.
      #
      # **That row is gone, and screen 05 is on the shelf instead.** The owner's
      # ruling of 9 September: *Settings means toggles, text fields and
      # dropdowns — a page that only SHOWS things does not belong there.* 05 is
      # a feed; it hangs off `Kati.Screens.Library`'s ⋯ menu now, beside
      # `What fits?`, which is the same kind of destination. The Settings row
      # had been a stopgap for a page with no other door and was read here as
      # if it were a preference.
      #
      # Release watcher stays, and it is the half that was always the setting:
      # 25 is what Kati watches for, and 05 is what it found.
      %{
        id: "release_watcher",
        icon: "notifications_active",
        title: "Release watcher",
        sub: "Premieres, new episodes, price drops",
        control: :chevron
      },
      %{
        id: "auto_detect",
        icon: "sensors",
        title: "Auto-detect",
        sub: "Notice what you play",
        control: :chevron
      }
    ]
  end

  @doc "About — version, the privacy claim the app has to keep, and this phone."
  @spec about() :: [map()]
  def about do
    [
      %{
        id: "version",
        icon: "info",
        title: "Version",
        sub: "0.1 · mock build",
        control: :chevron
      },
      %{
        id: "privacy",
        icon: "shield",
        title: "Privacy",
        sub: "Nothing leaves the device",
        control: :chevron
      },
      %{
        id: "this_device",
        icon: "phone_iphone",
        title: "This device",
        sub: "Permissions and storage",
        control: :chevron
      },
      %{
        id: "attribution",
        icon: "info",
        title: "Where this comes from",
        sub: "Sources and licences",
        control: :chevron
      },
      # A reference sheet rather than a place in the app, filed under About for
      # the reason screen 27 is: it is the app describing itself. Screen 100's
      # own back pill says `Settings`, which is what puts it here — the design
      # names the parent and never redrew 24 to add the row, exactly as it did
      # for the three Sources rows above. The screen is drawn and finished;
      # only the way in was missing.
      %{
        id: "year_cards",
        icon: "grid_view",
        title: "Year cards",
        sub: "How a shared card is drawn",
        control: :chevron
      },
      # MOVIES-AND-TV.md #7. Screen 148's own moduledoc says it is "a reference
      # sheet pushed under Settings" and its back pill says `Settings`, and
      # nothing pushed it — it was gallery-only, exactly as Year cards above
      # was until its row existed. Same argument, same group: the app
      # describing itself. It is where the one distinction the app makes about
      # a shelf is written down — *Paused and Dropped are things a person
      # decided; Gone cold is something Kati noticed* — and the reader meets
      # all three without ever being told which is which.
      %{
        id: "dropping",
        icon: "do_not_disturb_on",
        title: "Dropping",
        sub: "Paused, dropped, and gone cold",
        control: :chevron
      },
      # MOVIES-AND-TV.md #8. 152's own back pill says `Settings` and nothing
      # pushed it. It is the argument for a feature and the feature exists now
      # — `Kati.Media.Anime` is its three rules and screen 03 grows the chip it
      # draws — so the board becomes what it always read as: the place the rule
      # is written down. Same group and same argument as Dropping above.
      %{
        id: "anime",
        icon: "auto_awesome",
        title: "Anime",
        sub: "What makes a title one",
        control: :chevron
      },
      # The gallery. It used to be behind Home's bell, which was scaffolding
      # from the round when 53 screens landed at once with no way in. They are
      # all reachable now, so the bell went back to meaning notifications and
      # this went where a page describing the app belongs.
      %{
        # `grid_view` rather than `apps`, which is not in Kati's icon subset —
        # the subset is generated from what the drawings use, and adding a
        # glyph for one settings row would mean a font rebuild for a row.
        id: "every_screen",
        icon: "grid_view",
        title: "Every screen",
        sub: "One list, for looking",
        control: :chevron
      }
    ]
  end
end
