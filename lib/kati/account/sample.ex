defmodule Kati.Account.Sample do
  @moduledoc """
  Stand-in account, device and permission data for screen 40.

  Sign-in exists so sync works, so the account card says what the sign-in
  bought and nothing else. Every permission carries the sentence explaining
  what it is for, which is the design's rule rather than a nicety: a row that
  cannot say why it wants something should not be asking.

  Notifications sit in the drawn state the flow actually produces — **not yet
  asked** — because screen 38 makes the notification decision before any
  permission dialog is raised. Copy is the design's own, from
  `test/design/screens/40.html`.

  ## Every word screen 40 says is a msgid here, and none of it is one there

  `Kati.Screens.Account` draws this module's strings and deliberately wraps
  none of them. `storage.headline`, `storage.body`, `privacy_note` and every
  row's title and sub reach that screen as runtime **values**, and `gettext/1`
  needs a literal at the call site — so the msgids belong to the module that
  writes the words, which is this one. The screen owns the typography that
  carries them (`Kati.Locale.tracking/1`, `Kati.Locale.leading/1`,
  `Kati.Locale.forward_chevron/0`) and says so at each call.

  Three of the entries are the app's own rather than new: *Notifications*,
  *Calendars* and *Last backup* take msgids the catalogue already carries, and
  the Calendars purpose line is literally the one
  `Kati.Screens.Calendar.timeline/2` draws on its locked-out card — its comment
  there reads *"Screen 40's Calendars row, word for word"*, and word for word
  means one msgid rather than two that agree today.

  ## None of these lists may become a module attribute

  `gettext/1` in a module attribute is evaluated at COMPILE time and freezes
  whichever locale the compiler happened to be in, so a table of translated
  rows held in `@permissions` would ship one language to both readers. They
  were already functions; `Kati.Settings.Sample` records the same hazard for
  the same reason, and a reader reaching for an attribute here is reaching for
  that bug.
  """

  use Gettext, backend: Kati.Gettext

  @doc "Everything screen 40 shows, in the order it shows it."
  @spec account() :: map()
  def account do
    %{
      storage: storage(),
      permissions: permissions(),
      install: install_permissions(),
      # One literal rather than the `<>` of two this used to be: a msgid has to
      # be a literal at the call site, and `gettext("a" <> "b")` is an operator
      # call by the time the macro sees it —
      # `Kati.Screens.GoalStates.recount/0` had to make the same join for the
      # same reason.
      privacy_note:
        gettext(
          "Kati has no analytics and no server. There is nothing to switch off, and nothing that could be read if there were."
        ),
      data: data()
    }
  end

  @doc """
  Where the data is, what it weighs, and how it leaves.

  Replaces the account card. Screen 40 opened with *"Signed in with Apple ·
  relay address · no email shared"* above a list of syncing devices, and Kati
  has no account, no server and no second device to sync with — so the card
  states the model positively instead of listing an absence.

  There is a hard reason the *Move to a new phone* row cannot be soft:
  `android:allowBackup` is `false` and there is no server, so a user who loses
  this phone loses everything unless they have exported it themselves.
  """
  @spec storage() :: map()
  def storage do
    %{
      headline: gettext("Everything is in one file on this phone."),
      body:
        gettext(
          "There is no account, no sign-in and no server. Because there is no server, moving to a new phone means moving the file yourself."
        ),
      rows: [
        %{
          icon: "inventory_2",
          title: gettext("Storage used"),
          # Both figures go through `Kati.Locale.number/1` rather than being
          # spelled into the msgid: they are numerals inside a line the reader
          # reads, which is that function's own case, and a Persian page with a
          # Latin `214` in it is the exact defect mishka-group/kati#103 keeps
          # finding.
          #
          # The grouping comma stays Latin, which is `number/1`'s own decision
          # and not an oversight — it converts the decimal mark and leaves the
          # group alone because `test/design/screens/59.html` draws ۱,۴۸۰ with
          # this comma. So the string goes in already grouped and comes back
          # ۱,۲۰۶.
          #
          # 214 is deliberately the same figure `Kati.Settings.Sample.data/0`
          # puts on the row that pushes here, so the two screens agree about
          # one database by quoting one number.
          #
          # This would have to change if `Kati.Screens.Account.storage_row/1`'s
          # `mono_sub` ever reached a `font_family`: `kati_mono.ttf` carries no
          # U+06F0–U+06F9 at all, so a figure the design sets in DM Mono keeps
          # Latin digits in both scripts. Today that key is read by nothing and
          # the value is drawn in the reader's own face, so the reader's own
          # digits are right.
          value:
            gettext("%{n} MB · %{count} titles",
              n: Kati.Locale.number(214),
              count: Kati.Locale.number("1,206")
            )
        },
        # "Never" is the honest empty value and should read as a gentle warning
        # rather than an error — nothing has gone wrong, but nothing is safe
        # either.
        #
        # `pgettext/2` and not a bare msgid, which is the call
        # `Kati.Screens.Backup.status_frame/2` and `Kati.Screens.BackupStates`
        # already make for this exact word. The catalogue also holds *Never
        # backed up* and *never checked*, and `mix gettext.merge` fuzzy-matches
        # a msgid this short against either of them; the context says which
        # never this is — the answer to *when was the last backup* — so all
        # three places in the app that answer that question share one entry.
        %{
          icon: "upload",
          title: gettext("Last backup"),
          value: pgettext("last backup", "Never"),
          warn: true
        },
        %{icon: "phone_iphone", title: gettext("Move to a new phone"), value: nil, chevron: true}
      ]
    }
  end

  @doc """
  The permissions, each stating its purpose before anything is asked.

  Exactly what `AndroidManifest.xml` declares and Kati uses. The drawing's
  Photos, Microphone and Local network rows are gone: `READ_MEDIA_IMAGES`,
  `RECORD_AUDIO` and the Bluetooth permissions were never requested (K-30,
  K-31 removed the surfaces that would have needed them), so a row for any of
  them asks the user about something Kati cannot do.

  `capability` is what `Kati.Permissions.status/1` reads. The trailing control
  is decided from that answer at render time rather than stored here — a
  permission changes in system settings while Kati is backgrounded, which is
  the normal way it changes, so a copy kept in a sample would be a lie exactly
  when it matters.

  `capability` is also the only field on a row that is not copy, and that is
  what makes these rows safe to translate: `Kati.Screens.Account` keys its
  status lookup and its Allow tap on the atom, never on the drawn title. A
  screen that keyed on the title would match nothing at all under `:fa` —
  mishka-group/kati#103's recurring defect, and the one `Kati.Settings.Sample`
  had to grow ids to escape.
  """
  @spec permissions() :: [map()]
  def permissions do
    [
      %{
        icon: "notifications",
        title: gettext("Notifications"),
        capability: :notifications,
        sub: gettext("Only when you turn one on."),
        # Android 13 made this a runtime permission, and a denial is not fatal:
        # screen 25's inbox card is the degraded path, so the row says so
        # rather than leaving the user to discover it.
        denied_sub: gettext("Turned off. New episodes will still appear in your inbox.")
      },
      %{
        icon: "calendar_month",
        title: gettext("Calendars"),
        capability: :calendar,
        # READ_CALENDAR only. WRITE_CALENDAR is not declared, which is why
        # `Kati.Sync.Adapter.DeviceProvider` reports `writable: false` — so the
        # row promises reading and nothing else.
        #
        # The msgid is shared with `Kati.Screens.Calendar.timeline/2`, whose own
        # comment calls this row's sentence *word for word*. One entry, so the
        # promise a reader is given here and the one they are reminded of on the
        # empty calendar cannot drift apart in translation.
        sub: gettext("To show your appointments beside your episodes. Kati only reads them."),
        denied_sub: gettext("Turned off. Your episodes will show without your appointments.")
      },
      %{
        icon: "schedule",
        title: gettext("Alarms and reminders"),
        capability: :exact_alarms,
        # The time is interpolated rather than written into the msgid, and it is
        # ONE binding used twice on purpose: the whole point of the sentence is
        # that the two clock faces are the same number, and two bindings would
        # let a translation quietly make them different.
        #
        # `Kati.Locale.time/1` for the digits — 24-hour in both scripts, which is
        # the design's own choice and a setting of its own on screen 24, so only
        # the numerals move: ۲۱:۰۰.
        sub:
          gettext("So a reminder set for %{time} arrives at %{time}.",
            time: Kati.Locale.time(~T[21:00:00])
          ),
        denied_sub: gettext("Turned off. Reminders will arrive late, when the phone next wakes.")
      }
    ]
  end

  @doc """
  What Kati asks for by being installed, stated as fact.

  These have no runtime state to read and no dialog behind them — they are
  granted by being declared. Drawing a control for them would be a switch that
  cannot move, so the screen states them and moves on.
  """
  @spec install_permissions() :: [map()]
  def install_permissions do
    [
      %{
        icon: "public",
        # `pgettext/2` for the two one-word titles in this group. *Internet* and
        # *Vibrate* are a single word each, `mix gettext.merge` fuzzy-matches at
        # that length, and the context is the one `Kati.Screens.Account` already
        # writes beside them for the Allow pill and the Allowed state.
        #
        # The other five titles on this page stay bare, and for two different
        # reasons: *Notifications* and *Calendars* take msgids the app has
        # already translated once, and a contexted copy would be a second place
        # for one word to drift; *Alarms and reminders*, *Start at boot* and
        # *Move to a new phone* are long enough that nothing in the catalogue is
        # near enough to be fuzzy-matched against.
        title: pgettext("permission", "Internet"),
        sub: gettext("To look up what you are watching. Nothing about you is sent.")
      },
      %{
        icon: "history",
        title: gettext("Start at boot"),
        # *Alarms* is زنگ and *reminders* is یادآور throughout the app —
        # `Kati.Screens.NotificationsHelp` draws both words one row apart — and
        # this sentence is the only place they meet in one line, so it is the
        # one that would have shown a split if they had ever been translated
        # twice.
        sub:
          gettext(
            "Android drops pending alarms when the phone restarts. This puts your reminders back."
          )
      },
      %{
        icon: "notifications_active",
        title: pgettext("permission", "Vibrate"),
        sub: gettext("So a reminder can be felt, not just seen.")
      }
    ]
  end

  @doc "The two rows under Privacy: what leaves, and how to end it."
  @spec data() :: [map()]
  def data do
    [
      # No "Share anonymous usage" row. With no server it had nowhere to send
      # anything, so an off switch was a control over a thing that did not
      # exist — the privacy note says it in one sentence instead.
      %{
        icon: "delete_forever",
        # Bare msgids for two short lines, where the rule about anything under
        # three words normally reaches for `pgettext/2`. *Delete everything* is
        # the third of a family the app already writes bare — *Back up
        # everything* and *Export everything* on `Kati.Settings.Sample.data/0` —
        # and splitting one of the three off under a context is precisely how a
        # family drifts. *Cannot be undone* has no near neighbour in the
        # catalogue for a merge to match: the app's other statement of the same
        # fact is a whole sentence, *There is no undo once it finishes*.
        title: gettext("Delete everything"),
        sub: gettext("Cannot be undone")
      }
    ]
  end
end
