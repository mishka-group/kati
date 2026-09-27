defmodule Kati.Sources do
  @moduledoc """
  Where Kati's posters, covers and facts come from, and which of them you have
  connected an account to.

  Not an Ash domain. Nothing here is a row the user created: the provider list
  is a constant of the build, the tokens live in `Kati.SecureStore`, and the
  cache figures are `Kati.Media.CachePolicy`'s. A resource would have been a
  table whose contents were decided by this file.

  ## Three tiers, and the third one is a decision rather than a limit

    * **Tier 0 — works out of the box.** No key, no account, no setup. The
      board names TVmaze, Open Library and MusicBrainz (`tier0/0`); screen 80
      lists only the ones Kati actually calls (`working/0`), because a row
      saying a source works is a claim about a source the app must touch
      (N41). A provider's row appears once its client exists.

      Two do: **AniList** (`Kati.Media.Anilist` — anime series and films) and
      **TVmaze** (`Kati.Media.Tvmaze` — series with their seasons and
      episodes). Screen 19 searches both whenever no TMDB token is saved
      (`Kati.Search.Keyless`), and a title added from either is fetched from
      it and cached under its own source.

      **Books and Music still need a free API chosen and wired — Open Library
      and MusicBrainz are named here and neither is called anywhere in `lib/`.**
      Kati's HTTP callers are `Kati.Media.Tmdb`, `Kati.Media.Anilist` and
      `Kati.Media.Tvmaze` (through `Kati.Media.Provider.request/3`), the image
      CDNs in `Kati.Media.Artwork`, and CalDAV. The two shelves that depend on
      the rest of this line are [mishka-group/kati#100](https://github.com/mishka-group/kati/issues/100)
      (Books) and [mishka-group/kati#101](https://github.com/mishka-group/kati/issues/101)
      (Music). Free and keyless is the requirement, not a preference: tier 0
      is defined by needing no account, so a provider that wants a key belongs
      in tier 1 or 2 and changes what screen 80 promises.
    * **Tier 1 — the reader's own key.** TMDB. No build ships a key, a
      development build included: every reader pastes their own read token on
      screen 80 and it goes to `Kati.SecureStore` under `tmdb`, which is the
      only TMDB key the app ever sends (`Kati.Media.Tmdb.key/0`). The owner's
      decision: *"all users must put their token there."* Every credential and
      where it can go is tabled in `Kati.SecureStore`'s moduledoc.
    * **Tier 2 — connect an account.** ListenBrainz, Hardcover, TheTVDB. Not
      drawn on screen 80 either, for tier 0's reason: Kati has no client for
      any of the three, so there is nothing a token would connect to.
      `connected_count/0` and `disconnect_all/0` still sweep their keys, so a
      token stored by an older build is still wiped by *Wipe tokens*.

  The tier-2 list is short on purpose and the design's caption gives the rule:
  *all three take revocable tokens; Trakt, Simkl and Last.fm are left out
  because they need a pasted `client_secret`.* A secret pasted into a
  client-side app is not a secret, and asking for one would be asking the user
  to do something Kati cannot make safe.

  ## What Kati will not ask for

  A password, ever. Only tokens the user can revoke from the provider's own
  site. Screen 80 prints that as a promise, and this module is where it is
  kept: there is no field anywhere in `Kati` that takes a provider password.

  ## Where tokens live, honestly

  `Kati.SecureStore` when the platform gives one, and unencrypted on the device
  when it does not — which today is every Android build (#55). The screen says
  which of those is true rather than implying the better one. `token_note/0` is
  that sentence, and it changes with `Kati.SecureStore.available?/0` rather
  than being copy somebody has to remember to update.
  """

  use Gettext, backend: Kati.Gettext

  alias Kati.SecureStore

  @doc """
  The providers that need no setup at all.

  A function and not an attribute: `gettext/1` inside a module attribute is
  evaluated at COMPILE time, so a table of translated names freezes whichever
  locale the compiler happened to be in. mishka-group/kati#103 — the same
  change `Kati.Retired` and `Kati.Screens.MyServices.rules/0` made.

  `name` carries a Kati word beside a trade name — *TV & film · TVmaze* is
  **فیلم و سریال · TVmaze** — so it translates and the trade name inside it
  does not. `supplies` is a plain description and translates whole.
  """
  @spec tier0() :: [map()]
  def tier0 do
    [
      %{
        id: :tvmaze,
        icon: "movie",
        name: gettext("TV & film · TVmaze"),
        supplies: gettext("Air dates, episode lists")
      },
      %{
        id: :open_library,
        icon: "menu_book",
        name: gettext("Books · Open Library"),
        supplies: gettext("Covers, editions, ISBNs")
      },
      %{
        id: :musicbrainz,
        icon: "graphic_eq",
        name: gettext("Music · MusicBrainz"),
        supplies: gettext("Albums, artists, cover art")
      }
    ]
  end

  @doc """
  The keyless providers Kati calls today, as screen 80 lists them under
  *Working out of the box*.

  Not a filter over `tier0/0`, whose lines are the board's: its TVmaze line
  says *TV & film*, and TVmaze has no films. These say what each client
  actually brings. `name` is the trade name alone and untranslated — screen 80
  sets it in DM Mono in both scripts (`Kati.Locale.mono_face/1`); `supplies`
  translates.

      iex> Enum.map(Kati.Sources.working(), & &1.id)
      [:anilist, :tvmaze]
  """
  @spec working() :: [map()]
  def working do
    [
      %{
        id: :anilist,
        icon: "auto_awesome",
        name: "AniList",
        supplies: gettext("Anime series and films, episode counts")
      },
      %{
        id: :tvmaze,
        icon: "live_tv",
        name: "TVmaze",
        supplies: gettext("Series, seasons, episodes, air dates")
      }
    ]
  end

  @doc """
  The providers you can connect an account to.

  `name` and `site` are untranslated on all three: a trade name and a URL are
  proper nouns, and screen 80 sets them in DM Mono in both scripts for exactly
  that reason — see `Kati.Locale.mono_face/1`.
  """
  @spec tier2() :: [map()]
  def tier2 do
    [
      %{
        id: :listenbrainz,
        icon: "graphic_eq",
        name: "ListenBrainz",
        supplies: gettext("Scrobbles, listening history"),
        # Where a reader goes to get their own token. One per provider, and it
        # was one for all three: screen 80's pairing card printed
        # `listenbrainz.org/link` under every code, so a Hardcover reader was
        # sent to somebody else's site.
        site: "listenbrainz.org/profile",
        why:
          gettext(
            "ListenBrainz needs your own token because it writes to your account, not Kati’s. " <>
              "Nothing is shared between users."
          )
      },
      %{
        id: :hardcover,
        icon: "menu_book",
        name: "Hardcover",
        supplies: gettext("Community book ratings"),
        site: "hardcover.app/account/api",
        why:
          gettext(
            "Hardcover’s ratings are read with your own token, so your reading is not " <>
              "attributed to anyone else."
          )
      },
      %{
        id: :thetvdb,
        icon: "tv",
        name: "TheTVDB",
        supplies: gettext("Artwork, absolute ordering"),
        site: "thetvdb.com/dashboard/account/apikey",
        why: gettext("TheTVDB issues a per-user key you can revoke from your own account page.")
      }
    ]
  end

  @doc """
  The providers deliberately not offered, each with the reason.

  Kept as data rather than as prose, because "why is Trakt not here" is a
  question somebody will ask of the code before they ask it of the screen.
  Nothing draws these strings — `Kati.Retired` holds the sentence screen 114
  shows — so they are not translated.
  """
  @spec refused() :: [{atom(), String.t()}]
  def refused do
    [
      {:trakt, "needs a pasted client_secret"},
      {:simkl, "needs a pasted client_secret"},
      {:lastfm, "needs a pasted client_secret"}
    ]
  end

  @doc """
  Whether a tier-2 provider has a token on this device.

  Asks `Kati.SecureStore` rather than keeping a second list, so a token wiped
  by the platform cannot leave a row saying *Connected*.
  """
  @spec connected?(atom()) :: boolean()
  def connected?(id) when is_atom(id) do
    match?({:ok, token} when is_binary(token) and token != "", SecureStore.get(key_for(id)))
  rescue
    _error -> false
  end

  @doc "The secure-store key a provider's token is filed under."
  @spec key_for(atom()) :: String.t()
  def key_for(id) when is_atom(id), do: "source_token_" <> Atom.to_string(id)

  @doc """
  The sentence screen 80 prints about where tokens live.

  Two versions, and which one is true is a property of the device rather than
  of the copy. Saying the reassuring one on a phone where it is false would be
  the single most expensive sentence in the app.
  """
  @spec token_note() :: String.t()
  def token_note do
    if SecureStore.available?() do
      gettext(
        "Tokens are held in this device’s secure store. Kati sends each one only to the " <>
          "service it belongs to. Kati never asks for a password — only for tokens you can " <>
          "revoke from the provider’s own site."
      )
    else
      gettext(
        "Tokens sit unencrypted on this device, because the platform gives Kati no secure " <>
          "store yet. Kati sends each one only to the service it belongs to. Kati never asks " <>
          "for a password — only for tokens you can revoke from the provider’s own site."
      )
    end
  end

  @doc """
  Forget one provider's token.

  What the `Disconnect` on a connected tier-2 row does, and the whole reason
  only revocable-token providers are on that list — see the moduledoc. Deleting
  the token IS the disconnection: `connected?/1` asks `Kati.SecureStore` rather
  than keeping a second list, so no row can still say *Connected* afterwards,
  and there is no second place for the two to drift apart.
  """
  @spec disconnect(atom()) :: :ok
  def disconnect(id) when is_atom(id) do
    SecureStore.delete(key_for(id))
    :ok
  rescue
    _error -> :ok
  end

  @doc """
  How many stored tokens `disconnect_all/0` would actually take away.

  Counted, not stated. Board 81 writes *Three accounts disconnect* as a WORD,
  and its moduledoc gives the reason — a specimen confirmation on a device with
  nothing connected *"would count to zero and print 0 accounts disconnect — a
  true figure attached to an event that cannot happen."* That argument is about
  a DRAWING. On the live screen the figure is the reader's own, and zero is not
  a problem to be avoided by rounding up to three: it is the answer that stops
  the row offering to destroy nothing.

  The reader's own TMDB key counts as one of them. It is the only token here
  they had to go and fetch, and losing it unannounced is the thing this whole
  confirmation exists to prevent.
  """
  @spec connected_count() :: non_neg_integer()
  def connected_count do
    tier2_count = Enum.count(tier2(), &connected?(&1.id))

    tmdb_count =
      case SecureStore.get("tmdb") do
        {:ok, token} when is_binary(token) and token != "" -> 1
        _none -> 0
      end

    tier2_count + tmdb_count
  rescue
    _error -> 0
  end

  @doc "Forget every provider token on this device."
  @spec disconnect_all() :: :ok
  def disconnect_all do
    Enum.each(tier2(), fn %{id: id} -> SecureStore.delete(key_for(id)) end)
    SecureStore.delete("tmdb")
    :ok
  rescue
    _error -> :ok
  end
end
