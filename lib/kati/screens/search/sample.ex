defmodule Kati.Screens.Search.Sample do
  @moduledoc """
  One query — `hollow` — matched across every section, until a real index
  exists.

  `.scratch/design/screens/19.html` is drawn mid-query with six hits split
  three ways, and the split is the whole point of the screen: a title, an
  episode, two calendar entries and a note about the same word are four
  different shapes, and the design keeps them four different shapes rather
  than flattening them into one list of rows. So the sample is grouped the way
  the drawing groups it, not as a flat result list.

  The counts on the chips are **derived**, not typed: `All` is the total and
  each section chip counts its own group, so the numbers cannot drift from the
  lists they describe.

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
  Filter chips, the counts computed from the groups themselves.

  `All` is selected, which is what makes the other three read as narrowing
  rather than as four peers.
  """
  @spec chips() :: [{String.t(), integer(), boolean()}]
  def chips do
    screen = length(titles())
    calendar = length(calendar())

    [
      {"All", screen + calendar + 1, true},
      {"Screen", screen, false},
      {"Calendar", calendar, false},
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
