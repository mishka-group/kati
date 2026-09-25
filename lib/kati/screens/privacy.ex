defmodule Kati.Screens.Privacy do
  @moduledoc """
  Privacy, pushed under Settings — what Kati keeps, and what leaves the phone.

  No board draws this page. Screen 24 draws a *Privacy* row under About
  with a chevron, and the row opened nothing: a privacy row that does nothing
  is worse than no row, and a store listing needs a privacy statement the app
  can point at. So the page is the settings list's own grammar — a title, two
  grouped cards, a closing note — and says only what the code makes true.

  ## Every sentence, and what makes it true

    * **No account, no server.** Kati has no sign-in, and nothing in `lib/`
      talks to a server of Kati's own. `Kati.Screens.Settings`' moduledoc
      records the account card that was removed for the same reason.
    * **No analytics.** No analytics, advertising or crash-reporting library is
      a dependency (`mix.exs`), and no module sends a count anywhere.
    * **One SQLite database.** `Kati.Repo` opens `kati.db` in `Mob.data_dir/0`,
      the app's private storage. Preferences — the locale, the theme, the
      sections — are `Mob.State`, beside it; downloaded posters are
      `Kati.Media.Artwork`'s, beside it too.
    * **TMDB, and only TMDB.** The app makes HTTP requests from two places:
      `Kati.Media.Tmdb`, to `api.themoviedb.org` with the token the reader
      pasted on screen 80, and `Kati.Media.Artwork`, to TMDB's image server for
      posters. `Kati.Sources`' moduledoc says the same — Open Library and
      MusicBrainz are named there and called nowhere. CalDAV has a transport,
      `Kati.Sync.Adapter.CalDAV.Transport`, and nothing in the app drives it:
      no screen adds a CalDAV account and nothing calls `Kati.Sync.Engine.sync/3`.
      The day something does, this page gains a row.
    * **Backups only when the reader makes one.** `Kati.Backup.Transport` is
      reached from the Save and Share buttons of `Kati.Screens.Backup` (and
      Save on its dark colourway, `Kati.Screens.BackupDark`) and from nowhere
      else, and the manifest sets `android:allowBackup="false"`, so Android's
      own backup does not copy the database either.
    * **Tokens.** The closing note is `Kati.Sources.token_note/0`, which states
      whether this device has a secure store rather than assuming one — on
      every Android build today it says the token sits unencrypted.

  A change to any of those facts has to change this page, which is why each is
  named here beside its sentence. `Kati.SettingsPrivacyTest` holds the page to
  the list of HTTP callers.

  ## Nothing here taps

  Every row is a statement. There is no switch to turn analytics off because
  there are none, and a control that changed nothing would be the kind of
  reassurance this page exists to refuse.
  """
  use Kati.Screens.Pushed, back: "Settings"
  use Gettext, backend: Kati.Gettext

  alias Kati.UI
  alias Kati.UI.SettingsList

  @doc "What stays on the phone: no account, no analytics, one database."
  @spec kept() :: [map()]
  def kept do
    [
      %{
        icon: "person",
        title: pgettext("privacy", "No account"),
        sub:
          gettext(
            "Kati has no sign-in and no server of its own. Nothing you enter is sent to the people who make it."
          )
      },
      %{
        icon: "visibility_off",
        title: pgettext("privacy", "No analytics"),
        sub:
          gettext(
            "No tracking, no advertising and no crash reports. Kati does not count what you do."
          )
      },
      %{
        icon: "phone_iphone",
        title: pgettext("privacy", "Your data"),
        sub:
          gettext(
            "One SQLite database in Kati’s private storage on this phone. Your settings and downloaded posters are kept beside it."
          )
      }
    ]
  end

  @doc "What leaves the phone, and where it goes."
  @spec leaves() :: [map()]
  def leaves do
    [
      %{
        icon: "public",
        title: pgettext("privacy", "Film and series data"),
        sub:
          gettext(
            "Searches and title details come from TMDB, using the token you gave Kati, and posters from TMDB’s image server. No other service is contacted."
          )
      },
      %{
        icon: "upload",
        title: pgettext("privacy", "Backups"),
        sub:
          gettext(
            "A backup leaves this phone only when you save or share one yourself. Android’s own backup is switched off for Kati."
          )
      }
    ]
  end

  @doc false
  def content(_assigns) do
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
        {SettingsList.title(gettext("Privacy"), gettext("What stays on this phone, and what leaves it"), nil, :name)}
        {UI.eyebrow(pgettext("eyebrow", "On this phone"))}
        {Kati.Screens.Privacy.group(Kati.Screens.Privacy.kept(), 22)}
        {UI.eyebrow(pgettext("eyebrow", "What leaves it"))}
        {Kati.Screens.Privacy.group(Kati.Screens.Privacy.leaves(), 22)}
        {SettingsList.note("lock", Kati.Sources.token_note())}
      </Column>
    </Scroll>
    """
  end

  @doc """
  One grouped card of statements. The second line wraps — these are sentences,
  not the one-line readings a settings row usually carries — which is the
  `lines:` option `Kati.UI.SettingsList.body/3` keeps for exactly this.
  """
  def group(rows, gap) do
    last = length(rows) - 1

    body =
      rows
      |> Enum.with_index()
      |> Enum.map(fn {row, i} ->
        SettingsList.row(
          SettingsList.icon_tile(row.icon),
          SettingsList.body(row.title, row.sub, lines: 4),
          nil,
          padding: 14,
          rule: i < last
        )
      end)

    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.card(body)}
      <Spacer size={gap} />
    </Column>
    """
  end
end
