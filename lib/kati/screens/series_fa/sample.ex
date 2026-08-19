defmodule Kati.Screens.SeriesFa.Sample do
  @moduledoc """
  One series in Persian, as screen 58 draws it.

  The same title, season and artwork as `Kati.Library.Sample.series/0` — the
  Persian page is the English page in another language, not another show — but
  the episode list is the drawing's own: seven episodes, five watched, and two
  that have not aired, so all three row states are exercised.

  Episode numbers are strings rather than integers on purpose. They are drawn
  as ۱..۷, and `Kati.Calendar.Shamsi.fa/1` is what would produce them from an
  integer once the Screen domain supplies real ones; holding them as the text
  the drawing shows keeps the sample honest about being copy.
  """

  @doc "The series, its season, and the episodes of that season."
  def series do
    %{
      title: "گودال بلند",
      seed: "hollow71",
      meta: "۲۰۲۴ · درام · لومن‌پلاس · ۳ فصل",
      season: "فصل ۲",
      watched_line: "۵ از ۷ دیده شده",
      progress: 0.71,
      next_air: "قسمت بعد پنجشنبه ۲۹ مرداد، ساعت ۲۰:۰۰",
      action: "قسمت ۶ را دیده‌ام",
      back: "کتابخانه",
      seasons: [{"۱", false}, {"۲", true}, {"۳", false}],
      episodes: [
        %{n: "۱", title: "آب کم", sub: "۵۴ دقیقه", watched: true},
        %{n: "۲", title: "برداشت", sub: "۴۹ دقیقه", watched: true},
        %{n: "۳", title: "سیاه‌خار", sub: "۵۲ دقیقه", watched: true},
        %{n: "۴", title: "آنچه جزر باقی گذاشت", sub: "۵۱ دقیقه", watched: true},
        %{n: "۵", title: "فصل گودال", sub: "۴۷ دقیقه", watched: true},
        %{n: "۶", title: "پس‌کشند", sub: "پخش ۲۹ مرداد", watched: false},
        %{n: "۷", title: "گودال بلند", sub: "پخش ۵ شهریور", watched: false}
      ]
    }
  end
end
