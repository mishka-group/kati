defmodule Kati.Books.SampleFa do
  @moduledoc """
  Screens 69, 72 and 176, as the drawings captured them.

  ## 176 joined on 5 September, and its hero is 69's book

  The Persian Books shelf draws a *Reading now* card, and `D-38`'s acceptance
  asks that **176's hero copy matches `detail/0` character for character, so 69
  and 176 tell one story**. `reading_now/0` therefore reads its title, author,
  cover seed, fraction and position line off `detail/0` rather than restating
  any of them: two literals of `ص. ۲۱۴ / ۳۸۰ · ۲۳ دقیقه در روز` is two places
  for the shelf and the detail page to disagree about one book.

  The shelf's own numbers are the drawing's and stay literals, exactly as
  `Kati.Books.Sample` keeps `64 books`: **۶۴ کتاب · ۲ در حال خواندن** over six
  covers, because a shelf is a window onto a library rather than the whole of
  it. `Kati.Screens.BooksFa` counts a real shelf instead and says so.

  ## The transliteration rule, stated once

  Screen 69's caption is precise about it: *the sample transliterates title and
  author — the user's own note text is never touched.* So `سالنامه نمک` and
  `اینس کارول` are the fixture's Persian names for a fixture's book, and the
  two notes are Persian because they are the fixture's notes. A real book keeps
  whatever it was called, and a real note keeps whatever was typed into it —
  nothing in `Kati.Books` translates anything.

  ## Dates are Shamsi, and the numbers are Persian digits

  `۱۴۰۳` is the publication year in the calendar this screen is drawn in, and
  the history band's `۲۵ مرداد` is the Shamsi rendering of the same day screen
  66 calls `16 AUG`. Both are the drawing's, frozen for the same reason every
  other fixture's dates are frozen: a fixture whose dates move cannot be
  compared with the frame it was captured from.

  ### And a real book's year is **not** ۱۴۰۳, which is the one asymmetry here

  `D-59` asked the question and screen 69 had to answer it to draw a book
  somebody typed: a book published in 2024 prints **۲۰۲۴** — the Gregorian year
  with its digits folded — and is never converted.
  `Kati.Screens.ArtistDetailFa` argues it in full for the same class of number
  and the argument is not repeated here: a Gregorian year straddles two Shamsi
  years because the year turns at Nowruz, `Kati.Calendar.Shamsi` converts
  *dates* and has no year-to-year function at all, and choosing one of ۱۴۰۲/۱۴۰۳
  means inventing a day inside a year nobody gave. Board 76 already draws a
  Gregorian release year in Persian digits (`کل اوستراند · ۲۰۲۵`) and screens 04
  and 58 keep their first-air ۲۰۲۴, so this is a drawn convention rather than a
  new one.

  So the drawing says ۱۴۰۳ and a real book says ۲۰۲۴, and both are right about
  what they are: this fixture is a drawing captured from an artboard whose
  author wrote a Shamsi year, and a stored `published_year` is an integer a
  publisher printed on an edition and screen 177 typed in ASCII. `D-55` is where
  that ratification belongs; until it lands, do not "fix" one of the two to
  match the other.
  """

  @doc """
  Screen 69's book, in Persian.

  ## `status`, `format` and `owned` arrived with `D-59`, and their absence was
  the defect

  `Kati.Books.Sample.detail/0` has carried all three since it was written, which
  is exactly why screen 66's status chips, format chips and ownership switch
  could read `b.status`, `b.format` and `b.owned` — while screen 69's asserted
  `:reading`, `:paperback` and `true` in its own markup. A page that asserts a
  fact in markup is a page a real book cannot correct, and on 5 September, when
  board 177 gave books their first writer, a title typed on a Pixel 9a opened
  under a lit *در حال خواندن* chip and an ownership switch turned on for an
  edition nobody said they had. The Persian fixture was the English fixture
  minus three keys, and the three missing keys were three of the lies. Nothing
  rendered changes: the same chip lights, the same format lights, the same
  switch is on.

  `warning_count` is the **integer** its English twin has always been, not the
  string `"۳"`. The fixture stores the number and the screen draws the digits,
  because the screen is the only thing that knows which digit table its face has
  — `kati_mono.ttf` carries none of U+06F0–U+06F9. Two types through one
  `warning_trailing/1` is how a `Text` ends up handed a bare `0` from a shelved
  book, and `Kati.Calendar.Shamsi.fa(3)` is this board's own `۳`.
  """
  @spec detail() :: map()
  def detail do
    %{
      title: "سالنامه نمک",
      author: "اینس کارول",
      seed: "bookaa1",
      status: :reading,
      status_label: "در حال خواندن",
      meta: "۱۴۰۳ · ۳۸۰ صفحه",
      progress: 0.56,
      progress_line: "ص. ۲۱۴ / ۳۸۰ · ۲۳ دقیقه در روز",
      rating: 9,
      rating_label: "4.5",
      format: :paperback,
      extent_label: "۳۸۰ صفحه",
      isbn: "978–0–571–33915–2",
      owned: true,
      warning_count: 3,
      series_line: "#۳ از ۷ — دفترهای ساحلی",
      series_next: "بعدی: آب کم",
      lent_to: "قرض داده به جو",
      lent_due: "موعد ۵ شهریور"
    }
  end

  @doc """
  Board 176's shelf, in the order the grid draws it.

  Six covers under the seeds `Kati.Books.Sample` already uses, so a Persian
  shelf and an English one show the same six photographs of the same six books
  — one library, one artwork set, two ways of writing the name, which is the
  rule `Kati.Screens.LibraryFa.Sample` states for the poster grid.

  The `line` is data on the row rather than a template, for
  `Kati.Screens.LibraryFa.Sample`'s reason: `ص. ۲۱۴ / ۳۸۰`, `تمام‌شده` and
  `شروع نشده` are three different sentences and not one with a hole in it.
  """
  @spec books() :: [map()]
  def books do
    [
      %{title: "سالنامه نمک", seed: "bookaa1", progress: 0.56, line: "ص. ۲۱۴ / ۳۸۰"},
      %{title: "خور", seed: "bookbb2", progress: 0.36, line: "ص. ۸۸ / ۲۴۰"},
      %{title: "یادداشت‌های میدانی", seed: "bookcc3", progress: 1.0, line: "تمام‌شده"},
      %{title: "علف مرام", seed: "bookdd4", progress: 0.0, line: "شروع نشده"},
      %{title: "آب کم", seed: "bookee5", progress: 1.0, line: "تمام‌شده"},
      %{title: "نگهبان", seed: "bookff6", progress: 0.0, line: "شروع نشده"}
    ]
  end

  @doc "Board 176's header: the root's title and the count line under it."
  @spec header() :: map()
  def header, do: %{title: "کتابخانه", subtitle: "۶۴ کتاب · ۲ در حال خواندن"}

  @doc """
  Board 176's three shelf segments, with کتاب‌ها lit.

  `Kati.Screens.LibraryFa.Sample.segments/0`'s three, one segment along: the
  same control, the same glyphs, the same words, and this is the shelf its
  second segment finally opens.
  """
  @spec segments() :: [map()]
  def segments do
    [
      %{icon: "movie", label: "نمایش", on?: false},
      %{icon: "menu_book", label: "کتاب‌ها", on?: true},
      %{icon: "graphic_eq", label: "موسیقی", on?: false}
    ]
  end

  @doc """
  Board 176's four count chips, first one selected.

  All four carry a number where screen 20's two do not, which is the Persian
  board's own asymmetry rather than a change of mind — 176 is 57's page, and
  57's chips all count.

  ***شروع نشده*** and not a second word for *to read*: `D-38` leaves the choice
  open and the board settles it in its own annotation — *the same word 156
  uses, one register, in both places* — so `Kati.Screens.LibraryFa.meta/1`, the
  status chip on 156 and this chip all say one thing.
  """
  @spec chips() :: [{String.t(), String.t()}]
  def chips do
    [
      {"همه", "۶۴"},
      {"در حال خواندن", "۲"},
      {"تمام‌شده", "۹"},
      {"شروع نشده", "۵۳"}
    ]
  end

  @doc """
  Board 176's Reading-now hero.

  Every value read off `detail/0` — see the moduledoc. `label` is the card's
  own eyebrow and is the same two words as the status, which is what the board
  draws.
  """
  @spec reading_now() :: map()
  def reading_now do
    book = detail()

    %{
      label: labels().reading_now,
      title: book.title,
      author: book.author,
      seed: book.seed,
      progress: book.progress,
      pace: book.progress_line
    }
  end

  @doc """
  Board 176's empty shelf: screen 27's shape, in Persian.

  A glyph, a title, one sentence — and the action is the `+` the sentence names
  rather than a second button, because the FAB is already on the page and a
  card that drew its own would be two doors to one form.

  The sentence is deliberately **not** the Goodreads import: 140 → 141 → 37 is
  drawn but `Kati.Screens.ImportRecognised` writes nothing, and pointing a
  brand-new empty state at it would promise a write that does not happen.
  """
  @spec empty() :: map()
  def empty do
    %{
      icon: "menu_book",
      title: "هنوز کتابی نیست",
      body:
        "اولین کتاب را با دکمه + اضافه کنید. کاتی جلد یا تعداد صفحه‌ای نمی‌سازد — همان چیزی می‌ماند که نوشته‌اید."
    }
  end

  @doc "The four status choices and the one that is on."
  @spec statuses() :: [{atom(), String.t()}]
  def statuses do
    [
      {:reading, "در حال خواندن"},
      {:finished, "تمام شد"},
      {:paused, "متوقف"},
      {:did_not_finish, "رهاشده"}
    ]
  end

  @doc "The three edition formats, in the drawing's order."
  @spec formats() :: [{atom(), String.t()}]
  def formats, do: [{:paperback, "شمیز"}, {:ebook, "الکترونیک"}, {:audiobook, "صوتی"}]

  @doc "The two entries in the cream card."
  @spec notes() :: [map()]
  def notes do
    [
      %{kind: :quote, body: "جزر و مد دفتر خودش را نگه می‌دارد.", anchor: "ص. ۱۴۸"},
      %{kind: :note, body: "فصل هفتم را قبل از جلد دوم دوباره بخوان.", anchor: "ص. ۲۰۶"}
    ]
  end

  @doc "The reading history band, newest first."
  @spec sessions() :: [map()]
  def sessions do
    [
      %{date: "۲۵ مرداد", span: "ص. ۱۶۸ → ۲۱۴", duration: "۳۸ دقیقه"},
      %{date: "۲۳ مرداد", span: "ص. ۱۳۰ → ۱۶۸", duration: "۳۱ دقیقه"},
      %{date: "۲۰ مرداد", span: "ص. ۹۴ → ۱۳۰", duration: "۲۹ دقیقه"}
    ]
  end

  @doc "The eyebrows screen 69 prints, in order."
  @spec eyebrows() :: %{atom() => String.t()}
  def eyebrows do
    %{
      status: "وضعیت",
      edition: "نسخه",
      warnings: "هشدار محتوا",
      notes: "یادداشت‌ها و نقل‌قول‌ها",
      series: "مجموعه و مالکیت",
      history: "تاریخچه خواندن"
    }
  end

  @doc "The rows and the action row's four labels."
  @spec labels() :: %{atom() => String.t()}
  def labels do
    %{
      back: "کتابخانه",
      yours: "شما",
      others: "دیگران",
      length: "تعداد صفحه",
      # Board 176's own name for the hero card — `176.html:31` calls it
      # «کارت «در حال خواندن»», the *Reading now* card — and it is the card's
      # SECTION word rather than the head book's status. The two coincide on
      # the fixture, whose head book is reading, and that coincidence is what
      # let `Kati.Screens.BooksFa.hero/1` briefly build this caption out of
      # `status_label/1`: a shelf with one unstarted book then captioned its
      # hero **شروع نشده** and printed the same two words again under the rail.
      # Screen 20 hard-codes *Reading now* for this reason; so does this.
      reading_now: "در حال خواندن",
      owned: "نسخه‌ای که دارم",
      warnings: "هشدارها",
      primary: "ثبت پیشرفت",
      finish: "تمام شد",
      rate: "امتیاز",
      list: "فهرست"
    }
  end

  @doc """
  Screen 72's sheet, in Persian.

  `timer` is the running face — `۰۰:۳۸:۱۲` — and the caption is explicit that
  **it does not flip**: elapsed time reads left to right in both languages,
  because the direction of time is not the direction of reading.
  """
  @spec sheet() :: map()
  def sheet do
    %{
      title: "ثبت پیشرفت",
      book: "سالنامه نمک",
      # The cover, which the drawing has always drawn and this map has never
      # named. `Kati.Screens.LogProgressFa.cover/1` reached it through a
      # `Map.get(s, :seed, "bookaa1")` default, so the fixture branch and the
      # named-book branch answered with different key sets — and that is the
      # shape `own/1`'s own doc calls load-bearing: *a key that goes missing is
      # a `KeyError` in the suite, where a key that goes missing from a MERGE
      # is the fixture's value on a device.* It is `detail/0`'s seed, because
      # 69 and 72 are one book.
      seed: "bookaa1",
      position: "ص. ۲۱۴ از ۳۸۰",
      page: "۲۶۰",
      unit_label: "اکنون در صفحه",
      units: [{"صفحه", :unit_page}, {"درصد", :unit_percent}, {"دقیقه", :unit_minutes}],
      timer: "۰۰:۳۸:۱۲",
      stop: "توقف",
      started_label: "شروع در",
      started_at: "۲۱:۰۲",
      insight_lead: "یعنی",
      insight_pages: "۴۶ صفحه",
      insight_middle: "در",
      insight_minutes: "۳۸ دقیقه",
      insight_tail: "— سریع‌ترین این هفته",
      commit: "ذخیره و توقف"
    }
  end
end
