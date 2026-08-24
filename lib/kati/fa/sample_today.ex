defmodule Kati.Fa.SampleToday do
  @moduledoc """
  Screen 59's day, as data — the Persian mirror of the meals Today screen.

  Same rule as `Kati.Library.Sample`: a stand-in, named as one, shaped like
  the domain that will replace it. Every string is the design's own, taken
  from `test/design/screens/59.html` rather than translated here, because
  a mirror screen exists to be compared with its drawing and invented copy
  makes that comparison meaningless.

  Numerals are Persian digits in the copy itself. They are **not** formatted at
  render time: `Kati.Cldr` can produce them, but the drawing is the reference
  for this pass and the domain that would supply real figures does not exist
  yet. When it does, these strings become numbers and the formatting moves to
  the boundary.
  """

  @doc "Everything screen 59 draws, in the order it draws it."
  @spec day() :: map()
  def day do
    %{
      back: "سلامت",
      title: "امروز",
      subtitle: "یکشنبه ۲۵ مرداد · ۵ وعده",
      plan: "کاهش وزن ۳",
      quick: quick(),
      calories: "امروز · ۱,۴۸۰ از ۲,۱۰۰ کالری",
      macros: macros(),
      remaining: "۶۲۰ باقی",
      meals: meals(),
      prep_label: "فردا — امشب آماده‌سازی لازم است",
      prep: %{
        title: "جو دوسر را خیس کنید، مرغ را از فریزر درآورید",
        sub: "دوشنبه ۵ وعده دارد · ۲ مورد آماده‌سازی"
      }
    }
  end

  @doc "The four quick tiles under the header."
  @spec quick() :: [{String.t(), String.t()}]
  def quick do
    [
      {"calendar_view_week", "هفته"},
      {"shopping_cart", "خرید"},
      {"monitoring", "تغذیه"},
      {"tune", "برنامه"}
    ]
  end

  @doc """
  The macro split, protein first.

  The design's caption is explicit that the bar fills right-to-left with
  protein leading, which is the same source order as the legend beside it —
  so the order here is the legend's order and the direction is the
  container's, not something each segment carries.
  """
  @spec macros() :: [map()]
  def macros do
    [
      %{label: "پروتئین", share: 0.31, color: 0xFF1A1917},
      %{label: "کربوهیدرات", share: 0.44, color: 0xFFB08E55},
      %{label: "چربی", share: 0.25, color: 0xFFE4D2B0}
    ]
  end

  @doc """
  Five meals in three states: three logged, one skipped, one still to come.

  `:next` is the only one that carries actions — the design gives exactly one
  row the raised card, the accent rule and the two buttons, because only one
  meal is the next thing you do.
  """
  @spec meals() :: [map()]
  def meals do
    [
      %{
        state: :eaten,
        time: "۰۷:۳۰",
        seed: "mealoats",
        label: "صبحانه",
        title: "جو دوسر شبانه با توت",
        sub: "۴۱۰ کالری"
      },
      %{
        state: :eaten,
        time: "۱۰:۳۰",
        seed: "mealyog",
        label: "میان‌وعده",
        title: "ماست یونانی و گردو",
        sub: "۱۸۰ کالری"
      },
      %{
        state: :eaten,
        time: "۱۳:۰۰",
        seed: "mealchick",
        label: "ناهار",
        title: "مرغ، کینوا و کلم",
        sub: "۵۴۰ کالری"
      },
      %{
        state: :skipped,
        time: "۱۶:۰۰",
        seed: nil,
        label: "میان‌وعده",
        title: "سیب و کره بادام",
        sub: "رد شد"
      },
      %{
        state: :next,
        time: "۱۹:۳۰",
        seed: "mealsalmon",
        label: "شام",
        title: "سالمون میسو، سبزیجات، برنج",
        sub: "۶۲۰ کالری",
        eat: "خوردم",
        swap: "جایگزین"
      }
    ]
  end
end
