defmodule Kati.Screens.Search.Sample do
  @moduledoc """
  One query — `hollow` — matched across every section, until a real index
  exists.

  `test/design/screens/19.html` is drawn mid-query with six hits split
  three ways, and the split is the whole point of the screen: a title, an
  episode, two calendar entries and a note about the same word are four
  different shapes, and the design keeps them four different shapes rather
  than flattening them into one list of rows. So the sample is grouped the way
  the drawing groups it, not as a flat result list.

  The counts on the chips are **typed**, not derived — see `chips/0`. The
  export prints `Screen 3` above two drawn rows, and the number is what the
  query matched rather than what the group has room to show.

  When the index lands, delete this. The screen reads groups of maps and does
  not care who matched them.
  """

  @doc "Everything screen 19 draws, in the order it draws it."
  @spec results() :: map()
  def results do
    %{
      query: "hollow",
      titles: titles(),
      calendar: calendar(),
      note: note(),
      recent: recent()
    }
  end

  @doc """
  Filter chips, with the counts the export types.

  `6 / 3 / 2 / 1`, and the drawing means them: it prints **Screen 3** over two
  drawn rows, the same way the shelf on screen 20 says *64 books* over six
  covers. A chip counts what the query matched; the group under it shows the
  ones that fit above the fold. Deriving these from `titles/0` and `calendar/0`
  is the tempting move — it was what this function did — and it quietly turned
  the drawing's 6 and 3 into 5 and 2, which is a literal on the screen not
  matching its frame.

  When a real index lands these become counts of the whole result set, which is
  what they already claim to be. `Notes` is 1 in the drawing and 1 here.

  `All` is selected, which is what makes the other three read as narrowing
  rather than as four peers.
  """
  @spec chips() :: [{String.t(), integer(), boolean()}]
  def chips do
    [
      {"All", 6, true},
      {"Screen", 3, false},
      {"Calendar", 2, false},
      {"Notes", 1, false}
    ]
  end

  @doc "The Screen hits: a title and one of its episodes."
  @spec titles() :: [map()]
  def titles do
    [
      %{
        title: "The Long Hollow",
        sub: "Series · S2 · watching",
        seed: "hollow71"
      },
      %{
        title: "Hollow Season",
        sub: "Episode · S2E5 · watched 12 Aug",
        seed: "hollow71"
      }
    ]
  end

  @doc """
  The Calendar hits.

  Dates are stored as the drawing types them — `20 AUG`, mono and
  letter-spaced, with a leading zero on the second — because the column is
  44pt wide and a ragged `6 AUG` would not line up under `20 AUG`.
  """
  @spec calendar() :: [map()]
  def calendar do
    [
      %{date: "20 AUG", title: "The Long Hollow S2E6 airs", time: "20:00"},
      %{date: "06 AUG", title: "Hollow Season — watched", time: "21:12"}
    ]
  end

  @doc """
  The Notes hit, with the matched word carried separately.

  `inline_words` is how many words of `tail` share the first line with the
  highlight. The browser wraps this paragraph; `Row` does not, and no geometry
  comes back from `render/1` — so the break is declared here, at the point the
  drawing breaks, and `tail` keeps the sentence whole so nothing is lost when
  a real search highlights a different word.

  The eyebrow is stored in capitals because the drawing types it in capitals.
  """
  @spec note() :: map()
  def note do
    %{
      eyebrow: "NOTE · 6 AUG · THE LONG HOLLOW",
      lead: "…the",
      match: "hollow",
      tail: "is a character, not a place. Watch E1 again before S3.",
      inline_words: 6
    }
  end

  @doc """
  Recent searches, chunked into the rows the drawing's `flex-wrap` produces.

  Three then one, which is what 402pt gives at these widths — and worth
  keeping, because it is what says the field remembers more than fits.
  """
  @spec recent() :: [[String.t()]]
  def recent do
    [["dentist", "leaving soon", "ines karvel"], ["4 stars"]]
  end
end
