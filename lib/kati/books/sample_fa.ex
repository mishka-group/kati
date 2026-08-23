defmodule Kati.Books.SampleFa do
  @moduledoc """
  Screens 69 and 72, as the drawings captured them.

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
  """

  @doc "Screen 69's book, in Persian."
  @spec detail() :: map()
  def detail do
    %{
      title: "سالنامه نمک",
      author: "اینس کارول",
      seed: "bookaa1",
      status_label: "در حال خواندن",
      meta: "۱۴۰۳ · ۳۸۰ صفحه",
      progress: 0.56,
      progress_line: "ص. ۲۱۴ / ۳۸۰ · ۲۳ دقیقه در روز",
      rating: 9,
      rating_label: "4.5",
      extent_label: "۳۸۰ صفحه",
      isbn: "978–0–571–33915–2",
      warning_count: "۳",
      series_line: "#۳ از ۷ — دفترهای ساحلی",
      series_next: "بعدی: آب کم",
      lent_to: "قرض داده به جو",
      lent_due: "موعد ۵ شهریور"
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
