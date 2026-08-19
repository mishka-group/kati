defmodule Kati.Fa.SampleWeek do
  @moduledoc """
  Screen 60's plan, as data — the Persian mirror of the weekly meals matrix.

  A stand-in, named as one, shaped like the domain that will replace it. Copy
  is the design's own, from `.scratch/design/screens/60.html`.

  ## The week starts on Saturday, and that is data, not styling

  The design's caption for this screen says the hard part plainly: mirroring
  alone would put Monday on the right and still be wrong, because the *sequence*
  restarts. So `days/0` is `ش ی د س چ پ ج` — Saturday first — and the cells in
  each meal's row are in that same order. Turning the container RTL then puts
  Saturday on the right, which is where a Persian reader begins.

  That is why the order lives here rather than in the screen: it is a property
  of the calendar, and the same list will come from the locale's week rules
  once `Kati.Calendars` grows them.
  """

  @doc "Everything screen 60 draws, in the order it draws it."
  @spec plan() :: map()
  def plan do
    %{
      back: "وعده‌ها",
      title: "کاهش وزن ۳",
      subtitle: "هر هفته تکرار می‌شود",
      segments: ["هفته", "روز", "خرید"],
      days: days(),
      today: 1,
      rows: rows(),
      legend: legend(),
      note: "ستون‌ها از راست شروع می‌شوند: شنبه اولین روز هفته است. " <>
              "در انگلیسی همین جدول از دوشنبه و از چپ آغاز می‌شود.",
      day_label: "یکشنبه · ۳ وعده",
      meals: meals()
    }
  end

  @doc "The seven day initials, Saturday first."
  @spec days() :: [String.t()]
  def days, do: ["ش", "ی", "د", "س", "چ", "پ", "ج"]

  @doc """
  The matrix itself: five meal slots across seven days.

  `:planned` is a cell with a meal in it, `:free` an empty slot the plan does
  not fill, `:open` the dashed one the plan has not decided yet, and `:today`
  the one cell drawn on ink with an accent dot — orange because it is now,
  which is the only thing orange ever means here.
  """
  @spec rows() :: [map()]
  def rows do
    [
      %{
        label: "صبحانه",
        time: "۰۷:۳۰",
        cells: [:planned, :planned, :planned, :planned, :planned, :planned, :planned]
      },
      %{
        label: "میان‌وعده",
        time: "۱۰:۳۰",
        cells: [:planned, :planned, :free, :planned, :free, :planned, :planned]
      },
      %{
        label: "ناهار",
        time: "۱۳:۰۰",
        cells: [:planned, :planned, :planned, :planned, :planned, :planned, :planned]
      },
      %{
        label: "میان‌وعده",
        time: "۱۶:۰۰",
        cells: [:open, :planned, :planned, :planned, :free, :planned, :planned]
      },
      %{
        label: "شام",
        time: "۱۹:۳۰",
        cells: [:today, :planned, :planned, :planned, :planned, :planned, :planned]
      }
    ]
  end

  @doc "The key under the matrix: what a filled, an accented and an open cell mean."
  @spec legend() :: [{atom(), String.t()}]
  def legend do
    [
      {:planned, "برنامه‌ریزی‌شده"},
      {:today, "امروز"},
      {:open, "آزاد"}
    ]
  end

  @doc "The three meals of the selected day, listed under the matrix."
  @spec meals() :: [map()]
  def meals do
    [
      %{
        seed: "mealbrunch",
        label: "صبحانه · ۱۰:۰۰",
        title: "تخم‌مرغ، نان خمیرمایه، آووکادو",
        calories: "۵۲۰"
      },
      %{
        seed: "mealapple",
        label: "میان‌وعده · ۱۶:۰۰",
        title: "سیب و کره بادام",
        calories: "۲۱۰"
      },
      %{
        seed: "mealsalmon",
        label: "شام · ۱۹:۳۰",
        title: "سالمون میسو، سبزیجات، برنج",
        calories: "۶۲۰"
      }
    ]
  end
end
