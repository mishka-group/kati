defmodule Kati.Screens.HomeFa.Sample do
  @moduledoc """
  Home's content in Persian, at the evening screen 55 is drawn at.

  Every string is the drawing's own — the date, the greeting, the two titles,
  both timeline rows — because a mirror that says something different from the
  page it mirrors cannot be compared with it. The date is written out rather
  than computed for the same reason screens 28 and 29 pin their moment: this
  page is Home *held still* so the Persian grid can be judged.

  When the Screen domain and the clock take over, `Kati.Calendar.Shamsi`
  supplies the header line — `Shamsi.format(date, :long)` produces exactly
  `"یکشنبه ۲۵ مرداد ۱۴۰۵"`, Persian digits included — and this module goes.
  """

  @doc "The header: the Shamsi date and the greeting for that hour."
  def moment do
    %{date: "یکشنبه ۲۵ مرداد ۱۴۰۵", greeting: "عصر بخیر"}
  end

  @doc """
  The cream card: what is waiting, and when the watcher last looked.

  The headline breaks where the drawing breaks it — the design sets a `<br>`
  rather than letting 20px/1.45 wrap on its own — so the newline is content,
  not formatting.
  """
  def inbox do
    %{
      headline: "۳ قسمت تازه\nدر انتظار شماست",
      line: "یک قسمت ویژه · دو عنوان جمعه از لومن‌پلاس حذف می‌شوند",
      action: "باز کردن صندوق",
      checked: "۱۸:۰۲",
      seeds: ["ashfall42", "marram15", "harbour86"]
    }
  end

  @doc "Continue watching: two titles part-way through, with the drawing's own art."
  def continue do
    [
      %{title: "گودال بلند", meta: "فصل ۲ · قسمت ۶", progress: 0.62, seed: "hollow71"},
      %{title: "نمک و آهن", meta: "فصل ۱ · قسمت ۳", progress: 0.24, seed: "saltiron33"}
    ]
  end

  @doc "The three section tiles. Settings carries no dot and no second line."
  def sections do
    [
      %{icon: "restaurant", label: "وعده‌ها", meta: "شام ۱۹:۳۰", dot: 0xFFB08E55},
      %{icon: "bolt", label: "عادت‌ها", meta: "۲ مورد مانده", dot: 0xFF4E9A73},
      %{icon: "tune", label: "تنظیمات", meta: nil, dot: nil}
    ]
  end

  @doc """
  The rest of the evening.

  `now?` picks the rule colour, and orange still only ever means new or now —
  the 20:00 episode airs tonight, the weekly call does not.
  """
  def rest_of_today do
    [
      %{
        time: "۲۰:۰۰",
        title: "گودال بلند — فصل ۲ قسمت ۶",
        meta: "امشب پخش می‌شود · لومن‌پلاس",
        now?: true
      },
      %{
        time: "۲۱:۳۰",
        title: "تماس با مامان",
        meta: "هر هفته تکرار می‌شود",
        now?: false
      }
    ]
  end
end
