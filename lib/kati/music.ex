defmodule Kati.Music do
  @moduledoc """
  Albums, the people who made them, and what you actually played.

  The third media domain, and the one that had to answer a question the other
  two did not: **what counts as having listened to something.** A film is
  watched once. An episode is ticked. An album is played on a wet Tuesday,
  three tracks of it, twice more that week, and screen 74's `41 plays · 4 this
  month` is the sum of all of it.

  ## Four resources, and why the tracklist is one of them

    * `Kati.Music.Artist` — a person or group, and the `following` switch that
      screen 77 calls *the single source of truth* for screen 21's new-releases
      band and one of screen 25's six alert types.
    * `Kati.Music.Album` — a release, its art, your rating and your note.
    * `Kati.Music.Track` — the tracklist, with a per-track play count.
    * `Kati.Music.Listen` — one sitting: when, how long, how many tracks.

  A tracklist could have been a column on the album — a JSON array of names and
  durations — and that is what it would be if nothing queried it. Screen 74
  queries it twice: the play count is per track, and the dot that marks *a
  track played today* is a per-track fact with a date behind it. A column would
  have to be rewritten whole to move one number.

  ## `plays` is stored on the track and derived on the album

  The opposite of the shape `Kati.Books` uses, and for the opposite reason. A
  book has one position and many sittings, so the position is the thing worth
  keeping. An album has many tracks and many sittings, and screen 74's `41
  plays` is a total — `Album.plays/1` sums the tracks rather than keeping a
  third copy that a corrected listen could not fix.

  What is *not* derived is `Track.plays`, because a play is not always a
  `Listen`: a scrobble import supplies per-track counts and no sittings at all,
  which is exactly what #62 is about. So the counts are real columns and the
  album's total is arithmetic over them.

  ## Nothing here fetches

  MusicBrainz supplies the metadata and Cover Art Archive the art, and screen
  80 is where their keys and their state live. This domain holds what came
  back and what the user did with it, and neither of those is a network call.
  """
  use Ash.Domain, validate_config_inclusion?: false

  resources do
    resource Kati.Music.Artist
    resource Kati.Music.Album
    resource Kati.Music.Track
    resource Kati.Music.Listen
  end
end
