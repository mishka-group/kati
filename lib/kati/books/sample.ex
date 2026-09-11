defmodule Kati.Books.Sample do
  use Gettext, backend: Kati.Gettext

  @moduledoc """
  Stand-in book data, until the Books domain exists.

  Screen 20 is screen 03 rebuilt from the identical parts — the design's own
  caption says so: *"only the aspect ratio, the progress unit (pages, not
  episodes) and the hero card change. Nothing was redesigned to get here."*
  So this module deliberately mirrors `Kati.Library.Sample`'s shape rather
  than inventing a second one: a list of maps with a `seed`, a fraction, and
  the line the tile prints under its cover.

  Two numbers are literals rather than derivations, because the drawing means
  them to be. The shelf says **64 books** while it draws six covers, and the
  chip says **All 64** — a shelf is a window onto a library, not the whole of
  it. Computing those from `books/0` would quietly turn 64 into 6 and lose the
  point.

  Marked clearly rather than hidden: sample data that looks like real data is
  how a demo becomes a lie.
  """

  # The design's own titles, and the picsum seed the export uses for each
  # cover, so the app shows the exact photograph the drawing shows.
  @books [
    %{title: "The Salt Almanac", seed: "bookaa1", progress: 0.56, line: "p.214/380"},
    %{title: "Estuary", seed: "bookbb2", progress: 0.36, line: "p.88/240"},
    %{title: "Field Notes", seed: "bookcc3", progress: 1.0, line: "finished"},
    %{title: "Marram Grass", seed: "bookdd4", progress: 0.0, line: "to read"},
    %{title: "Low Water", seed: "bookee5", progress: 1.0, line: "finished"},
    %{title: "The Warden", seed: "bookff6", progress: 0.0, line: "to read"}
  ]

  @doc "Every book on the shelf, in the order the grid draws them."
  @spec books() :: [map()]
  def books, do: @books

  @doc "The header's mono subtitle. A literal — see the moduledoc."
  @spec subtitle() :: String.t()
  def subtitle, do: "64 books · 2 reading"

  @doc """
  The one book being read right now, as the hero card draws it.

  `pace` is the design's own phrasing and its own capitals — it is copy, not a
  CSS `text-transform`, so it is stored as written rather than upcased at
  render.
  """
  @spec reading_now() :: map()
  def reading_now do
    %{
      label: "Reading now",
      title: "The Salt Almanac",
      author: "Ines Karvel",
      seed: "bookaa1",
      progress: 0.56,
      pace: "p. 214 / 380 · 23 MIN/DAY PACE"
    }
  end

  @doc """
  The filter chips, first one selected.

  Two carry counts and two do not, which is the drawing's own asymmetry:
  a count earns its place when it is small enough to be a fact you act on.
  """
  @spec chips() :: [{String.t(), String.t() | nil}]
  def chips do
    [
      {"All", "64"},
      {"Reading", "2"},
      {"Finished", nil},
      {"To read", nil}
    ]
  end

  @doc "Absolute path to a cover, or `nil` when that seed was never drawn."
  @spec cover(String.t()) :: String.t() | nil
  def cover(seed), do: Kati.Design.Images.poster(seed)

  @doc """
  Screen 66's book, as the drawing captured it.

  The fallback, in the sense `Kati.Library.Sample.film/0` is one for screen 08:
  what the detail screen shows when `Kati.Books.Book` holds nothing. Every value
  here is read off `test/design/screens/66.html`, including the two the
  drawing means as literals — the pace, which needs seven days of sessions to
  compute and has none here, and the community rating, which has no source at
  all and is drawn as an em dash on purpose.
  """
  @spec detail() :: map()
  def detail do
    %{
      # Translated, because board 72 draws this title — **سالنامه نمک** — and
      # mishka-group/kati#103 folded `Kati.Screens.LogProgressFa` into screen 70.
      # An author's name is a person's name and is transliterated rather than
      # translated, which board 69 does too: **اینس کارول**.
      title: gettext("The Salt Almanac"),
      author: gettext("Ines Karvel"),
      seed: "bookaa1",
      status: :reading,
      status_label: pgettext("book status", "Reading"),
      meta:
        gettext("%{year} · FABER · %{pp}",
          year: Kati.Locale.year(2024),
          pp:
            Kati.UI.eyebrow_label(ngettext("%{n} pp", "%{n} pp", 380, n: Kati.Locale.number(380)))
        ),
      progress: 0.56,
      progress_line:
        gettext("p. %{at} / %{of}", at: Kati.Locale.number(214), of: Kati.Locale.number(380)) <>
          " · " <>
          Kati.UI.eyebrow_label(gettext("%{n} min/day pace", n: Kati.Locale.number(23))),
      # The same two numbers `Kati.Screens.BookDetail.shaped/3` carries, and for
      # the reason its comment gives: screen 70 used to read them back out of
      # the sentence above with a regex, which matches nothing in Persian.
      current_page: 214,
      page_count: 380,
      rating: 9,
      rating_label: Kati.Locale.number("4.5"),
      community: nil,
      format: :paperback,
      extent_label: ngettext("%{n} page", "%{n} pages", 380, n: Kati.Locale.number(380)),
      isbn: "978–0–571–33915–2",
      owned: true,
      warning_count: 3,
      series_line:
        gettext("#%{n} of %{total} in %{series}",
          n: Kati.Locale.number(3),
          total: Kati.Locale.number(7),
          series: gettext("The Coastal Ledgers")
        ),
      series_next: gettext("Next: %{title}", title: gettext("Low Water")),
      lent_to: gettext("Lent to %{who}", who: gettext("Jo")),
      lent_due: gettext("Due %{date}", date: Kati.Locale.date(~D[2026-08-27], :short))
    }
  end

  @doc """
  The two entries in the cream card, in the order the drawing prints them.

  A quote and a note, which is the whole reason `Kati.Books.Note` has a `kind`:
  the first wears quotation marks and the second does not, and both anchor to a
  page.
  """
  @spec notes() :: [map()]
  def notes do
    [
      %{
        kind: :quote,
        body: gettext("The tide keeps its own ledger."),
        anchor: gettext("p. %{n}", n: Kati.Locale.number(148))
      },
      %{
        kind: :note,
        body: gettext("Re-read chapter seven before starting the second volume."),
        anchor: gettext("p. %{n}", n: Kati.Locale.number(206))
      }
    ]
  end

  @doc """
  The reading history band, newest first.

  Dates are the drawing's own and are deliberately not computed from the clock:
  this is the fixture, and a fixture whose dates move is a fixture that cannot
  be compared with the frame it was captured from.
  """
  @spec sessions() :: [map()]
  def sessions do
    [
      session(~D[2026-08-16], 168, 214, 38),
      session(~D[2026-08-14], 130, 168, 31),
      session(~D[2026-08-11], 94, 130, 29)
    ]
  end

  # One drawn sitting, composed rather than written out: the date is the
  # reader's calendar, the page numbers and the minutes are the reader's
  # numerals. It was three frozen strings apiece, which is why board 69's
  # mirror kept a second copy of all three rows.
  defp session(on, from, to, minutes) do
    %{
      date: Kati.UI.eyebrow_label(Kati.Locale.date(on, :short)),
      span:
        gettext("p. %{from} → %{to}",
          from: Kati.Locale.number(from),
          to: Kati.Locale.number(to)
        ),
      duration: gettext("%{n}m", n: Kati.Locale.number(minutes))
    }
  end

  @doc "The four status choices screen 66 offers, and the one that is on."
  @spec statuses() :: [{atom(), String.t()}]
  def statuses do
    [
      {:reading, pgettext("book status", "Reading")},
      {:finished, pgettext("book status", "Finished")},
      {:paused, pgettext("book status", "Paused")},
      {:did_not_finish, pgettext("book status", "Did not finish")}
    ]
  end

  @doc "The three edition formats, in the drawing's order."
  @spec formats() :: [{atom(), String.t()}]
  def formats do
    [
      {:paperback, gettext("Paperback")},
      {:ebook, gettext("Ebook")},
      {:audiobook, gettext("Audiobook")}
    ]
  end
end
