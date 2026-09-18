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

  ## Every group is a function and none of them is an attribute

  `gettext/1` in a module attribute is evaluated at COMPILE time, so a table of
  translated rows freezes whichever locale the compiler happened to be in.
  These were already functions; the reason is recorded here because
  mishka-group/kati#103 folded `Kati.Fa.SampleSettings` into this module, and a
  reader reaching for an attribute is reaching for the bug.
  """

  use Gettext, backend: Kati.Gettext

  @doc """
  The mono line under the title.

  A stand-in with a number in it, so the number is `Kati.Locale.number/1`'s
  rather than a Latin `2` sitting in a Persian sentence — board 62 draws
  **۲ دقیقه پیش همگام‌سازی شد** and the digit is the half a translation cannot
  supply.
  """
  @spec synced() :: String.t()
  def synced, do: gettext("Synced %{n} min ago", n: Kati.Locale.number(2))

  @doc """
  The account card: the design's own photograph, its counts and its sync state.

  `entries` and not a `meta` STRING. It was `"1,204 ENTRIES · 4 SECTIONS"`, and
  `Kati.Screens.Settings.meta/2` kept the tally honest by running
  `Regex.replace(~r/\d+ SECTIONS/, …)` over it — a pattern that matches neither
  half of **۱,۲۰۴ مورد · ۴ بخش**: not the Persian digits, which are not `\d`,
  and not the word, which is translated. So the count would have silently
  stopped following the switches under it, which is the one thing that line
  exists to do. `Kati.Screens.Settings.meta/2` composes the line from the two
  numbers now.
  """
  @spec account() :: map()
  def account do
    %{
      seed: "face68",
      name: gettext("Your Kati"),
      entries: 1204,
      status: gettext("Synced")
    }
  end

  @doc "Appearance — the one group whose first row carries a segmented control."
  @spec appearance() :: [map()]
  def appearance do
    [
      %{
        id: "theme",
        icon: "contrast",
        title: gettext("Theme"),
        sub: nil,
        control: {:segments, Kati.Settings.Sample.theme_options(), gettext("Auto")}
      },
      %{
        id: "text_size",
        icon: "format_size",
        title: gettext("Text size"),
        sub: gettext("Follows system · up to %{n}%", n: Kati.Locale.number(235)),
        control: :chevron
      },
      %{
        id: "reduce_motion",
        icon: "motion_blur",
        title: gettext("Reduce motion"),
        sub: nil,
        control: {:switch, false}
      },
      %{
        id: "language",
        icon: "translate",
        title: gettext("Language"),
        sub: "English · فارسی",
        control: :chevron
      },
      %{
        id: "widgets",
        icon: "grid_view",
        title: gettext("Widgets"),
        sub: gettext("Home and lock screen"),
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
        title: gettext("My services"),
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
  def services_line(:gb, count), do: services_line(gettext("United Kingdom"), count)

  def services_line(region, 0),
    do: gettext("%{region} · none yet", region: region)

  def services_line(region, count),
    do:
      gettext("%{region} · %{subscribed}",
        region: region,
        subscribed:
          ngettext("%{n} subscribed", "%{n} subscribed", count, n: Kati.Locale.number(count))
      )

  @doc """
  The three words the theme trough offers, in the order both drawings draw them.

  A function and not a literal in the row above it, because
  `Kati.Screens.Settings.choice_at/1` and `label_for/2` read POSITIONS off this
  list: the tiles are Auto / Light / Dark in English and خودکار / روشن / تیره in
  Persian, and a tag built from the label would be a different atom in each.
  """
  @spec theme_options() :: [String.t()]
  def theme_options, do: [gettext("Auto"), gettext("Light"), gettext("Dark")]

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
        title: gettext("Screen"),
        sub: gettext("Home card, calendar feed, shelf"),
        control: {:switch, true}
      },
      %{
        id: "books",
        icon: "menu_book",
        title: gettext("Books"),
        sub: gettext("Home card, shelf"),
        control: {:switch, true}
      },
      %{
        id: "music",
        icon: "graphic_eq",
        title: gettext("Music"),
        sub: gettext("Shelf only"),
        control: {:switch, true}
      },
      %{
        id: "habits",
        icon: "bolt",
        title: gettext("Habits"),
        sub: gettext("Calendar feed"),
        control: {:switch, true}
      },
      %{
        id: "money",
        icon: "payments",
        title: gettext("Money"),
        sub: gettext("Calendar feed"),
        control: {:switch, false}
      },
      %{
        id: "reorder_sections",
        icon: "drag_indicator",
        title: gettext("Reorder sections"),
        sub: gettext("Drag to change home order"),
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
        title: gettext("Back up everything"),
        sub:
          gettext("Last backup %{date} · %{n} MB",
            date: Kati.Locale.date(~D[2026-08-14], :short),
            n: Kati.Locale.number(214)
          ),
        control: :chevron
      },
      %{
        id: "restore",
        icon: "upload_file",
        title: gettext("Restore a Kati backup"),
        sub: gettext("Your own file — merges or replaces"),
        control: :chevron
      },
      %{
        id: "import",
        icon: "download",
        title: gettext("Import"),
        sub: gettext("CSV, JSON, or another tracker’s backup"),
        control: :chevron
      },
      %{
        id: "export",
        icon: "upload",
        title: gettext("Export everything"),
        sub: gettext("Last backup %{date}", date: Kati.Locale.date(~D[2026-08-14], :short)),
        control: :chevron
      },
      %{
        id: "sync",
        icon: "sync",
        title: gettext("Sync"),
        sub: gettext("iCloud · this device + iPad"),
        control: :chevron
      },
      # The door the whole import flow had never had. `Kati.Screens.Gallery`'s
      # `@routed` list has claimed *Settings → Import* for screen 140 since #52,
      # and the claim retired 140 from the gallery listing — so the one page
      # that opens a CSV was filtered out of the only index that reached it
      # while nothing in Settings pushed it. Screens 37 and 141 sit behind it.
      #
      # The one other way in was `Kati.Screens.Restore`, which Home, Library and
      # `HomeEmpty` push only from their EMPTY-state footnotes: a reader with
      # anything at all on their shelf could not reach import or restore.
      #
      # In the Data group and above `data_sources`, because this group is where
      # a reader's own records come and go — back up, export, sync, clear — and
      # bringing a shelf in from another app is that question, not a question
      # about which catalogue Kati reads.
      %{
        id: "import_sources",
        icon: "upload_file",
        title: gettext("Import from another app"),
        sub: gettext("Trakt, Letterboxd, Goodreads, or any CSV"),
        control: :chevron
      },
      %{
        id: "data_sources",
        icon: "dns",
        title: gettext("Data sources"),
        sub:
          gettext("TVmaze, Open Library, MusicBrainz · %{n} reachable",
            n: Kati.Locale.number(3)
          ),
        control: :chevron
      },
      # Board 267's own edit to this row: it was the only row in this group
      # "whose meaning cannot be read before tapping it", and a destructive row
      # is the last one that should be. The line is the board's.
      %{
        id: "clear_history",
        icon: "delete",
        title: gettext("Clear watch history"),
        sub: gettext("Ticks, ratings and reviews — the shelves stay"),
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
        title: gettext("Calendars"),
        sub: gettext("Which calendars Kati may read"),
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
        title: gettext("Release watcher"),
        sub: gettext("Premieres, new episodes, price drops"),
        control: :chevron
      },
      %{
        id: "auto_detect",
        icon: "sensors",
        title: gettext("Auto-detect"),
        sub: gettext("Notice what you play"),
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
        title: gettext("Version"),
        sub: gettext("%{version} · mock build", version: Kati.Locale.number("0.1")),
        control: :chevron
      },
      %{
        id: "privacy",
        icon: "shield",
        title: gettext("Privacy"),
        sub: gettext("Nothing leaves the device"),
        control: :chevron
      },
      %{
        id: "this_device",
        icon: "phone_iphone",
        title: gettext("This device"),
        sub: gettext("Permissions and storage"),
        control: :chevron
      },
      %{
        id: "attribution",
        icon: "info",
        title: gettext("Where this comes from"),
        sub: gettext("Sources and licences"),
        control: :chevron
      }
      # (The `year_cards` row was here, and it was the argument's own weak point:
      # "a reference sheet rather than a place in the app, filed under About
      # because screen 100's back pill says `Settings`." A back pill naming a
      # parent is the DESIGN saying where the sheet was drawn from, not the app
      # promising a reader a page. Screen 100's own moduledoc calls itself "the
      # authoritative render spec... so that whatever eventually writes the PNG
      # has one page to be compared against" — every figure on it is a
      # specimen, correct for a spec and untrue of any reader. It stays in the
      # gallery, where a spec belongs.)
      # (`dropping` and `anime` were here, and they go the way `year_cards`
      # went one round earlier — the same argument, which was weak in the same
      # place. Both rows were justified by the sheets' own back pills saying
      # `Settings`, and a back pill names the parent a sheet was DRAWN from,
      # not the app promising a reader a page.
      #
      # What settles it is that both features now exist somewhere a reader
      # actually meets them, so the sheets are arguments for something already
      # built rather than the only place it is written down:
      #
      #   * The per-title anime override is `Kati.Screens.Series`' own ⋯ row —
      #     `toggle_anime`, writing `TrackedTitle.anime_override` — and the
      #     count is `Kati.Screens.Library.anime_chip/1`, a fifth shelf chip at
      #     ten titles or more. Board 152 argued for exactly those two and
      #     `Kati.Media.Anime` is its three rules.
      #   * Paused, dropped and gone cold are drawn on the shelf itself, and
      #     the decision between them is `Kati.Screens.DropSheet`, reached from
      #     a title's own ⋯ menu — which is where a reader is standing when the
      #     distinction matters.
      #
      # Both stay in the gallery, which is where a reference sheet belongs.)
    ]
  end
end
