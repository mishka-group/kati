defmodule Kati.Settings.DetectMusicSample do
  @moduledoc """
  Stand-in auto-detect state, screen 150 — Auto-detect in music mode.

  `Kati.Settings.DetectSample` is screen 36's TV & film state and this is its
  music sibling, not a variant of it: the two boards share nothing but a
  subtitle line. TV counts episodes ticked at a watched fraction; music
  scrobbles at a fraction OR a floor (`50% or 4 min`, so a two-minute single
  and a nine-minute post-rock track both still count), matches an app by its
  media-session notification rather than by a connected box, and disambiguates
  by which release rather than which title. Sharing a Sample module would have
  meant one of the two domains borrowing the other's shape.

  ## Why this is Sample and not a resource, same as screen 36

  Detection has not been built for either domain. Specifically missing for
  music:

    * **A per-app allow-list.** `apps/0`'s four rows have nowhere to persist
      an on/off — there is no table naming Spotify, YouTube Music, Poweramp or
      "everything else" as sources, let alone one Kati has toggled.

    * **A now-playing session.** Same gap `Kati.Screens.AutoDetect`'s own
      moduledoc records for TV: `Kati.Media.Watch` ticks after a play
      finishes, never while one is running, and nothing else holds a session
      in flight. Music needs this even more urgently than TV does, because
      the elapsed time the bar draws — `1:58 / 4:12` — is read off a media
      session that updates every second, not off a row written once.

    * **The rules themselves.** `30 seconds` minimum length, repeats counting
      individually, speaker plays counting, a 45%-skip not counting — four
      numbers with no column to live in.

    * **The ambiguity queue.** The same "unsure match becomes a question"
      argument screen 36 makes for `decision/0`, transposed to records rather
      than episodes: `Kati.Music.Album` is not yet keyed by release the way a
      queued match would need — "the studio album, a live record and a
      compilation" are three different rows sharing one track title, and nothing
      resolves a play to one of the three today.

  Every value below is therefore written by hand rather than queried, exactly
  as `Kati.Settings.DetectSample` does for TV, and for the same reason: this is
  a screen that has been drawn, not a feature that has been built.
  """

  @doc "The mono line under the title. Counts both modes at once — it does not change with the tab."
  @spec subtitle() :: String.t()
  def subtitle, do: "3 SOURCES · 41 EPISODES, 128 TRACKS"

  @doc """
  What is playing, how far in, and when it will scrobble — the no-art state.

  No-art is the state the board draws first and gives the full card to,
  because a media-session notification carries artwork only when the app
  bothers to attach it, and most of the ones this list names do not always.
  `with_art/0` is the one demonstrating the alternative, not the other way
  round.
  """
  @spec now_playing() :: map()
  def now_playing do
    %{
      title: "Low Water",
      meta: "KELL OSTRAND · TIDAL WORKS",
      status: "Live",
      progress: 0.47,
      elapsed: "1:58 / 4:12",
      rule: "scrobbles at 50% or 4 min"
    }
  end

  @doc "The compact second card: what a now-playing row looks like when the session does carry art."
  @spec with_art() :: map()
  def with_art do
    %{seed: "albm1", eyebrow: "With art", caption: "When the media session carries it"}
  end

  @doc """
  The four rows of `Which apps` — three named exceptions and the catch-all
  under them, on by default for the three Kati has actually seen.
  """
  @spec apps() :: [map()]
  def apps do
    [
      %{
        initial: "S",
        title: "Spotify",
        sub: "Reads track, artist and album from its notification",
        on: true
      },
      %{
        initial: "Y",
        title: "YouTube Music",
        sub: "Same, and ignores anything under 30 seconds",
        on: true
      },
      %{initial: "P", title: "Poweramp", sub: "Reads local file tags", on: false},
      %{
        initial: "E",
        title: "Everything else",
        sub: "Any app that posts a media notification",
        on: false
      }
    ]
  end

  @doc "Music's four rules — a floor, two things that still count, one that does not."
  @spec rules() :: [map()]
  def rules do
    [
      %{
        icon: "timer",
        title: "Minimum track length",
        sub: "30 seconds",
        control: {:value, "30s"}
      },
      %{
        icon: "repeat",
        title: "Repeats in one session",
        sub: "Each play counts",
        control: {:switch, true}
      },
      %{
        icon: "cast",
        title: "Scrobble without headphones",
        sub: "Speaker plays count too",
        control: {:switch, true}
      },
      %{
        icon: "call_split",
        title: "A track skipped at 45%",
        sub: "Under the threshold — not counted",
        control: :none
      }
    ]
  end

  @doc "The queued question: one track, three releases, and Kati will not guess which one played."
  @spec decision() :: map()
  def decision do
    %{
      seed: "albm2",
      question: "Three albums have “Low Water”",
      sub: "Played 4:12 from Spotify, 20:14",
      options: ["Tidal Works", "Live at Rex", "Best of"],
      chosen: "Tidal Works"
    }
  end
end
