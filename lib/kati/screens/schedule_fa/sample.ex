defmodule Kati.Screens.ScheduleFa.Sample do
  @moduledoc """
  The Persian schedule for یکشنبه ۲۵ مرداد, exactly as screen 56 draws it.

  ## The week is data, not a mirrored list

  The strip runs شنبه → جمعه. That is the drawing's own point — *"the Persian
  week begins on شنبه, so the day strip reorders — a change no amount of CSS
  mirroring would produce"* — and it is why the days live here as an ordered
  list rather than being derived by flipping the Gregorian one. The letters
  are `Kati.Calendar.Shamsi.weekday_short/1`'s, in its order, so when real
  dates arrive `Shamsi.month_grid/2` already returns weeks in this sequence
  and the strip does not change.

  Five items, five different shapes, because the drawing spends the whole page
  proving that a schedule row is not one row repeated: a done habit, a plain
  appointment, a reminder, a payment and the evening's episode all carry
  different chrome.
  """

  @doc "The header: the root's title and the Shamsi date with its item count."
  def header, do: %{title: "برنامه", subtitle: "یکشنبه ۲۵ مرداد · ۵ مورد"}

  @doc "Seven days, شنبه first. The selected one is card white, not ink."
  def days do
    [
      %{name: "ش", num: "۲۴", selected?: false},
      %{name: "ی", num: "۲۵", selected?: true},
      %{name: "د", num: "۲۶", selected?: false},
      %{name: "س", num: "۲۷", selected?: false},
      %{name: "چ", num: "۲۸", selected?: false},
      %{name: "پ", num: "۲۹", selected?: false},
      %{name: "ج", num: "۳۰", selected?: false}
    ]
  end

  @doc "The note under the strip, which says out loud why the week starts where it does."
  def week_note, do: "هفته از شنبه آغاز می‌شود"

  @doc "The filter chips, the first one selected."
  def chips, do: ["همه", "نمایش", "شخصی", "مالی"]

  @doc """
  The day's four ordinary rows.

  `tone` is the card: `:done` is the flat `#F4F1EC` state with no shadow,
  `:raised` is card white and lifted. `lead` is what sits at the row's start —
  a 3pt rule, a state circle, or a tinted glyph tile — and `trailing` is the
  one row that carries a result.
  """
  def events do
    [
      %{
        time: "۰۸:۰۰",
        tone: :done,
        lead: {:rule, 0xFF4E9A73},
        title: "دویدن صبحگاهی",
        meta: "عادت · ۱۲ روز پیاپی",
        trailing: {:icon, "check_circle", 0xFF4E9A73}
      },
      %{
        time: "۱۱:۰۰",
        tone: :raised,
        lead: {:rule, 0xFF1A1917},
        title: "دندان‌پزشک — کلینیک مارلو",
        meta: "۱۱:۰۰ – ۱۱:۴۵",
        trailing: nil
      },
      %{
        time: "۱۵:۰۰",
        tone: :done,
        lead: {:icon, "radio_button_unchecked"},
        title: "تمدید گذرنامه",
        meta: "یادآور",
        trailing: nil
      },
      %{
        time: "۱۸:۰۰",
        tone: :done,
        lead: {:badge, "payments"},
        title: "تمدید لومن‌پلاس",
        meta: "۸٫۹۹ پوند",
        trailing: nil
      }
    ]
  end

  @doc """
  The evening's episode, which the drawing gives its own card: a deeper
  shadow, the poster inline, and a cream pill saying why it matters.
  """
  def feature do
    %{
      time: "۲۰:۰۰",
      seed: "hollow71",
      title: "گودال بلند",
      meta: "فصل ۲ · قسمت ۶ · پس‌کشند",
      pill: "ویژه · لومن‌پلاس"
    }
  end
end
