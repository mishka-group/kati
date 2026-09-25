defmodule Kati.LanguageFollowsTest do
  @moduledoc """
  Screen 54's *Follows the language* rows state what the current locale does.

  They were frozen English — *Left to right · set by English*, *Gregorian ·
  Shamsi available*, *Latin 1234 · or Persian ۰۱۲۳*, *Monday · Saturday in
  فارسی* — at every locale, with the Persian catalogue flipping some of them.
  Each now reads the function the rest of the app acts on, and this file holds
  each row to that function under both locales. The expected lines are written
  out rather than asked of the code under test, which would agree with itself
  by construction.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Language.Page
  alias Kati.Screens.Language

  doctest Kati.Language.Page
  doctest Kati.Locale, only: [calendar: 0, numerals: 0]

  setup do
    installed = Mob.Theme.current()
    on_exit(fn -> Mob.Theme.set(installed) end)
    Kati.Locale.put(:en)
    :ok
  end

  @en [
    "Left to right · set by English",
    "Gregorian · set by English",
    "Latin 1234 · set by English",
    "Monday · set by English",
    "24-hour"
  ]

  @fa [
    "راست به چپ · از فارسی می‌آید",
    "شمسی · از فارسی می‌آید",
    "فارسی ۱۲۳۴ · از فارسی می‌آید",
    "شنبه · از فارسی می‌آید",
    "۲۴ ساعته"
  ]

  test "in English, each row states what English does" do
    assert Enum.map(Page.follows(), & &1.sub) == @en
  end

  test "in Persian, each row states what Persian does" do
    assert as(:fa, fn -> Enum.map(Page.follows(), & &1.sub) end) == @fa
  end

  test "the rows and the machinery they describe move together" do
    for {locale, direction, date, digits, day} <- [
          {:en, :ltr, "14 Aug", "1234", "Monday"},
          {:fa, :rtl, "۲۳ مرداد", "۱۲۳۴", "شنبه"}
        ] do
      as(locale, fn ->
        assert Kati.Locale.direction(Kati.Locale.current()) == direction
        assert Kati.Locale.date(~D[2026-08-14], :short) == date
        assert Kati.Locale.number(1234) == digits
        assert Kati.Locale.week_start() == day
        assert Kati.Locale.time(~T[21:40:00]) == Kati.Locale.number("21:40")
      end)
    end
  end

  test "both screens draw the lines, and neither draws the frozen copy" do
    en = texts(mount_screen(Language))
    fa = as(:fa, fn -> texts(mount_screen(Language)) end)

    for line <- @en, do: assert(line in en, "screen 54 in English does not draw #{line}")
    for line <- @fa, do: assert(line in fa, "screen 54 in Persian does not draw #{line}")

    for frozen <- [
          "Gregorian · Shamsi available",
          "Latin 1234 · or Persian ۰۱۲۳",
          "Monday · Saturday in فارسی"
        ] do
      refute frozen in en
    end

    refute "راست به چپ · از فارسی می‌آید" in en
    refute "Left to right · set by English" in fa
  end

  test "no Follows row taps or draws a chevron, and Time format is one of them" do
    none = Language.control_none()

    for locale <- [:en, :fa] do
      as(locale, fn ->
        for row <- Page.follows() do
          assert Language.tap(row) == nil, "#{row.title} carries a tap under #{locale}"
          refute Language.control(row.control, nil) == Kati.UI.SettingsList.chevron()
        end

        time = Enum.find(Page.follows(), &(&1.icon == "schedule"))
        assert Language.control(time.control, nil) == none
      end)
    end
  end

  test "the rows name the language by the name the picker prints" do
    assert Page.language_name(:en) == "English"
    assert Page.language_name(:fa) == "فارسی"

    assert Enum.map(Page.languages(), & &1.name) == ["English", "فارسی"]
  end

  test "the heading is read at render, so it follows a locale changed after mount" do
    view = mount_screen(Language)
    assert "Language" in texts(view)

    Kati.Locale.put(:fa)

    try do
      assert "زبان" in texts(view)
    after
      Kati.Locale.put(:en)
    end
  end

  test "Kati.Language.Sample is gone" do
    refute Code.ensure_loaded?(Kati.Language.Sample)
  end

  defp as(locale, fun) do
    Kati.Locale.put(locale)

    try do
      fun.()
    after
      Kati.Locale.put(:en)
    end
  end

  defp texts(view) do
    for node <- flatten(view),
        text = (Map.get(node, :props) || %{})[:text],
        is_binary(text),
        do: text
  end
end
