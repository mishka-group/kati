defmodule Kati.Books do
  @moduledoc """
  Books: the one being read, what was read of it, and what was written about it.

  Screen 20 shelved books before this domain existed and read
  `Kati.Books.Sample` to do it. That was honest for a shelf — a cover and a
  fraction — and stops being honest the moment a cover tap lands somewhere,
  because screen 66 shows an ISBN, an edition, a lending due date and a
  reading history, and every one of those is a fact somebody entered rather
  than a picture.

  ## The split, and why it is not `Kati.Media`'s

  `Kati.Media` splits evictable from durable, because a poster can be re-fetched
  and a rating cannot. Books do not have that problem in the same shape: Open
  Library is the only source in view, it supplies a cover and a page count, and
  neither is worth a second table to make evictable. What books have instead is
  a **position that moves**, which films do not, and that is what shapes this:

    * `Kati.Books.Book` holds where you *are* — `current_page`, `status`, the
      edition you own. One row per book, rewritten as you read.
    * `Kati.Books.ReadingSession` holds how you *got* there — a dated span of
      pages and the minutes it took. Append-only; nothing rewrites one.
    * `Kati.Books.Note` holds what you wrote — a quote or a note, anchored to a
      page.

  The position is stored rather than derived from the sessions, and that is a
  deliberate loss of normalisation. A book you read for a year before Kati
  existed has a position and no sessions, and deriving `current_page` from an
  empty history would put you back on page one. Screen 67's *partial metadata*
  state is that case drawn.

  ## Pace

  `p. 214 / 380 · 23 min/day pace` is screen 20's line and screen 66 repeats it
  verbatim. `Kati.Books.ReadingSession.pace/1` owns the arithmetic, and screen
  70's own caption fixes it: *minutes read across the last seven calendar days
  ÷ 7, so a skipped night dilutes the figure rather than vanishing from it*.
  One definition, one module, both screens.
  """
  use Ash.Domain, validate_config_inclusion?: false

  resources do
    resource Kati.Books.Book
    resource Kati.Books.ReadingSession
    resource Kati.Books.Note
  end
end
