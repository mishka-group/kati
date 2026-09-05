defmodule Kati.Sources do
  @moduledoc """
  Where Kati's posters, covers and facts come from, and which of them you have
  connected an account to.

  Not an Ash domain. Nothing here is a row the user created: the provider list
  is a constant of the build, the tokens live in `Kati.SecureStore`, and the
  cache figures are `Kati.Media.CachePolicy`'s. A resource would have been a
  table whose contents were decided by this file.

  ## Three tiers, and the third one is a decision rather than a limit

    * **Tier 0 — works out of the box.** TVmaze, Open Library, MusicBrainz. No
      key, no account, no setup. Screen 80 lists them with a last-reached time
      and nothing to press.
    * **Tier 1 — better artwork, optional key.** TMDB. Kati ships a key and it
      is public, because Kati is open source. That costs the user nothing —
      TMDB counts requests per IP address, not per key — and the screen says so
      rather than making a mystery of it.
    * **Tier 2 — connect an account.** ListenBrainz, Hardcover, TheTVDB.

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

  alias Kati.SecureStore

  @tier0 [
    %{
      id: :tvmaze,
      icon: "movie",
      name: "TV & film · TVmaze",
      supplies: "Air dates, episode lists"
    },
    %{
      id: :open_library,
      icon: "menu_book",
      name: "Books · Open Library",
      supplies: "Covers, editions, ISBNs"
    },
    %{
      id: :musicbrainz,
      icon: "graphic_eq",
      name: "Music · MusicBrainz",
      supplies: "Albums, artists, cover art"
    }
  ]

  @tier2 [
    %{
      id: :listenbrainz,
      icon: "graphic_eq",
      name: "ListenBrainz",
      supplies: "Scrobbles, listening history",
      why:
        "ListenBrainz needs your own token because it writes to your account, not Kati’s. " <>
          "Nothing is shared between users."
    },
    %{
      id: :hardcover,
      icon: "menu_book",
      name: "Hardcover",
      supplies: "Community book ratings",
      why:
        "Hardcover’s ratings are read with your own token, so your reading is not " <>
          "attributed to anyone else."
    },
    %{
      id: :thetvdb,
      icon: "tv",
      name: "TheTVDB",
      supplies: "Artwork, absolute ordering",
      why: "TheTVDB issues a per-user key you can revoke from your own account page."
    }
  ]

  # The providers that need a `client_secret` and are therefore not offered.
  # Kept as data rather than as prose, because "why is Trakt not here" is a
  # question somebody will ask of the code before they ask it of the screen.
  @refused [
    {:trakt, "needs a pasted client_secret"},
    {:simkl, "needs a pasted client_secret"},
    {:lastfm, "needs a pasted client_secret"}
  ]

  @doc "The providers that need no setup at all."
  @spec tier0() :: [map()]
  def tier0, do: @tier0

  @doc "The providers you can connect an account to."
  @spec tier2() :: [map()]
  def tier2, do: @tier2

  @doc "The providers deliberately not offered, each with the reason."
  @spec refused() :: [{atom(), String.t()}]
  def refused, do: @refused

  @doc """
  The TMDB key in force: `:kati` or `:own`.

  Stored in `Mob.State` and not in the secure store, because *which* key is not
  a secret — only the key itself is, and a user-supplied one goes to
  `Kati.SecureStore` under `tmdb`.
  """
  @spec tmdb_key() :: :kati | :own
  def tmdb_key do
    case Mob.State.get(:kati_tmdb_key) do
      :own -> :own
      _other -> :kati
    end
  end

  @doc "Choose which TMDB key to use."
  @spec put_tmdb_key(:kati | :own) :: :ok
  def put_tmdb_key(choice) when choice in [:kati, :own] do
    Mob.State.put(:kati_tmdb_key, choice)
    :ok
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
      "Tokens are held in this device’s secure store. Kati sends each one only to the " <>
        "service it belongs to. Kati never asks for a password — only for tokens you can " <>
        "revoke from the provider’s own site."
    else
      "Tokens sit unencrypted on this device, because the platform gives Kati no secure " <>
        "store yet. Kati sends each one only to the service it belongs to. Kati never asks " <>
        "for a password — only for tokens you can revoke from the provider’s own site."
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

  @doc "Forget every provider token on this device."
  @spec disconnect_all() :: :ok
  def disconnect_all do
    Enum.each(@tier2, fn %{id: id} -> SecureStore.delete(key_for(id)) end)
    SecureStore.delete("tmdb")
    :ok
  rescue
    _error -> :ok
  end
end
