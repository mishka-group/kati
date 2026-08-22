defmodule Kati.Music.Sample do
  @moduledoc """
  Stand-in music-shelf data, until the Screen domain grows a Music section.

  Screen 21 is deliberately the *same skeleton* as screen 03 — header, segmented
  control, sections — filled with a different medium, and the drawing's own note
  says why: *"the release watcher is section-agnostic"*. So the shapes here
  mirror `Kati.Library.Sample`'s: a list of works with artwork seeds, and a list
  of upcoming releases with a dot.

  `plays` is stored already capitalised because the export writes `41 PLAYS`
  into the markup rather than uppercasing it in CSS — unlike `This month`
  beside it, which is `text-transform:uppercase` and is upcased at render.
  """

  @doc "The header's mono subtitle."
  @spec subtitle() :: String.t()
  def subtitle, do: "418 albums · 61h this year"

  @doc "The three albums on repeat, in the order the row draws them."
  @spec albums() :: [map()]
  def albums do
    [
      %{seed: "albm1", title: "Tidal Works", artist: "Kell Ostrand", plays: "41 PLAYS"},
      %{seed: "albm2", title: "Low Country", artist: "Vesper Line", plays: "28 PLAYS"},
      %{seed: "albm3", title: "Nine Rooms", artist: "Aud Marne", plays: "19 PLAYS"}
    ]
  end

  @doc """
  This month's listening total, and the twenty daily bars under it.

  `{height, tone}` in dp, straight off the drawing: a 40pt field where the
  darker bronze marks the days above the run of ordinary ones. Heights are
  declared rather than derived from a percentage, because nothing measures the
  field back for us and the export's own numbers are the ground truth.
  """
  @spec listening() :: map()
  def listening do
    soft = 0xFFE4D2B0
    strong = 0xFFB08E55

    %{
      label: "This month",
      total: "9h 12m",
      window: "mostly 21:00–23:00",
      bars: [
        {17.6, soft},
        {30.8, soft},
        {13.2, soft},
        {39.6, strong},
        {26.4, soft},
        {35.2, strong},
        {22.0, soft},
        {8.8, soft},
        {30.8, soft},
        {39.6, strong},
        {17.6, soft},
        {26.4, soft},
        {35.2, strong},
        {13.2, soft},
        {22.0, soft},
        {30.8, soft},
        {39.6, strong},
        {26.4, soft},
        {17.6, soft},
        {35.2, strong}
      ]
    }
  end

  @doc "New records from followed artists — the same watcher that feeds screen 05."
  @spec releases() :: [map()]
  def releases do
    [
      %{seed: "albm4", artist: "Kell Ostrand", line: "Estuary Tapes · out Friday"},
      %{seed: "albm5", artist: "Vesper Line", line: "single · out now"}
    ]
  end

  @doc """
  Screen 74's album, as the drawing captured it.

  Drawn with **no art** on purpose — the design's own caption says Cover Art
  Archive coverage is patchy, so a paper square carrying the album initial is
  the default rendering rather than an error path. `art_seed` is therefore
  `nil` here and that is the fixture, not a gap in it.
  """
  @spec album() :: map()
  def album do
    %{
      title: "Tidal Works",
      initial: "T",
      artist: "Kell Ostrand",
      byline: "Kell Ostrand · 2025",
      art_seed: nil,
      artist_line: "4 albums · 61h listened",
      first_heard: "3 Mar 2024",
      last_played: "yesterday",
      rating: 9,
      rating_label: "4.5",
      plays_line: "41 plays · 4 this month",
      note:
        "Found this on a wet Tuesday in the studio. Played track three " <>
          "until it stopped meaning anything.",
      note_on: "3 MAR 2024"
    }
  end

  @doc """
  The tracklist, in running order — all eleven of them.

  Eleven, not the five screen 74's artboard prints and not the four screen 73's
  does. `Tracklist · 11 tracks` is the eyebrow's own claim and the insight line
  on 73 says `11 tracks · 47 minutes`, so eleven is what the album has and each
  artboard is showing as many rows as fitted. The six the drawings do not name
  are named here, because a tracklist with holes in it is not a tracklist.

  The arithmetic is pinned by the drawings from both ends: the durations sum to
  **47:00** and the play counts to **41**, which are the two figures screens 73
  and 74 print. `Kati.MusicTest` asserts both rather than trusting this comment.

  `today?` is the dot screen 74 calls *the only recency signal here*. Track 1
  carries it; the rest do not.

  `counted?` is screen 73's: a track already logged this calendar month, drawn
  pre-ticked so the `info` line under the list is literally true. The two tracks
  with no plays at all cannot be among them, which is the one place these two
  columns constrain each other.
  """
  @spec tracks() :: [map()]
  def tracks do
    [
      %{
        position: 1,
        title: "Low Water",
        duration: "4:12",
        plays: 9,
        today?: true,
        counted?: true
      },
      %{
        position: 2,
        title: "The Cull",
        duration: "3:48",
        plays: 7,
        today?: false,
        counted?: true
      },
      %{
        position: 3,
        title: "Blackthorn",
        duration: "5:02",
        plays: 12,
        today?: false,
        counted?: true
      },
      %{
        position: 4,
        title: "Hollow Season",
        duration: "4:31",
        plays: 4,
        today?: false,
        counted?: true
      },
      %{
        position: 5,
        title: "What the Tide Left",
        duration: "6:08",
        plays: 0,
        today?: false,
        counted?: false
      },
      %{
        position: 6,
        title: "Saltmarsh",
        duration: "3:41",
        plays: 3,
        today?: false,
        counted?: true
      },
      %{
        position: 7,
        title: "Kelp Line",
        duration: "4:05",
        plays: 2,
        today?: false,
        counted?: true
      },
      %{position: 8, title: "Bight", duration: "3:12", plays: 2, today?: false, counted?: true},
      %{
        position: 9,
        title: "The Long Reach",
        duration: "5:19",
        plays: 1,
        today?: false,
        counted?: true
      },
      %{
        position: 10,
        title: "Spring Tide",
        duration: "2:58",
        plays: 1,
        today?: false,
        counted?: true
      },
      %{position: 11, title: "Ledger", duration: "4:04", plays: 0, today?: false, counted?: false}
    ]
  end

  @doc "Screen 74's tracklist eyebrow. A literal — the shelf shows five of eleven."
  @spec tracklist_label() :: String.t()
  def tracklist_label, do: "Tracklist · 11 tracks"

  @doc """
  Screen 77's artist, as drawn.

  `following` is `true` in the drawing, which matters: the toggle is the single
  source of truth for screen 21's new-releases band, so the fixture has to show
  the state that band was captured in.
  """
  @spec artist() :: map()
  def artist do
    %{
      name: "Kell Ostrand",
      subtitle: "Composer · Iceland",
      photo_seed: "artist-kell",
      following: true,
      following_note: "Feeds 21’s new-releases band and 25’s alerts",
      hours: "61h",
      first_heard: "2024",
      album_count: "4"
    }
  end

  @doc "Screen 77's album rail and its plays-by-album chart, in one list."
  @spec artist_albums() :: [map()]
  def artist_albums do
    [
      %{title: "Tidal Works", year: 2025, plays: 41, line: "2025 · 41 plays", seed: nil},
      %{title: "Low Country", year: 2023, plays: 28, line: "2023 · 28 plays", seed: nil},
      %{title: "Nine Rooms", year: 2021, plays: 19, line: "2021 · 19 plays", seed: nil},
      %{title: "Estuary Tapes", year: nil, plays: 0, line: "Unheard", seed: nil}
    ]
  end

  @doc """
  The unheard release screen 77 puts orange on — the one place it appears.

  Two controls and they are not the same shape: `Remind me` arms something,
  `Dismiss` takes the card away. The design gives the first the ink and the
  second plain text, which is the ranking.
  """
  @spec unheard() :: map()
  def unheard do
    %{title: "Estuary Tapes", line: "Out Friday · you have not heard it"}
  end

  @doc """
  Ninety-one days of listening intensity — thirteen weeks, as the eyebrow says.

  Read cell for cell off `.scratch/design/screens/74.html` rather than
  generated, unlike `Kati.Stats.Sample.contributions/0`, and for a reason worth
  stating: this field is **compared against its own frame**. A generated field
  would be plausible and would not be the drawing, so the capture and the app
  would differ in ninety-one places nobody could triage.
  """
  @spec listen_field() :: [0..4]
  def listen_field do
    [
      0,
      3,
      2,
      3,
      2,
      0,
      4,
      3,
      3,
      3,
      1,
      1,
      4,
      4,
      1,
      3,
      0,
      0,
      3,
      0,
      4,
      0,
      0,
      0,
      1,
      3,
      1,
      4,
      3,
      4,
      2,
      3,
      4,
      0,
      3,
      3,
      3,
      1,
      2,
      2,
      1,
      1,
      1,
      3,
      1,
      3,
      2,
      3,
      3,
      1,
      1,
      3,
      3,
      4,
      2,
      4,
      3,
      1,
      1,
      4,
      2,
      2,
      1,
      2,
      1,
      2,
      3,
      1,
      2,
      1,
      1,
      3,
      4,
      3,
      1,
      4,
      4,
      2,
      3,
      2,
      2,
      2,
      3,
      1,
      1,
      3,
      4,
      2,
      2,
      4,
      4
    ]
  end

  @doc """
  The field's five tones, warm rather than green.

  Five, where screen 47's identical-looking field has four: this one adds
  `#D3B98A` between steps 1 and 3. Not a tidy-up waiting to happen — a listening
  field is denser than a nutrition streak and the extra step is what stops the
  middle of the range collapsing into one colour.
  """
  @spec tone(0..4) :: non_neg_integer()
  def tone(0), do: 0xFFEFE3CB
  def tone(1), do: 0xFFE4D2B0
  def tone(2), do: 0xFFD3B98A
  def tone(3), do: 0xFFB08E55
  def tone(_), do: 0xFF1A1917
end
