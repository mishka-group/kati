defmodule Kati.ScreenMyServicesFaTest do
  @moduledoc """
  Screen 97 with nothing set up, and the sheet its country row opens.

  Boards **324** and **301**. English has two modules for this — 92 live and 93
  as the empty specimen — and Persian has one page that has to be both, which
  is the arrangement `MOVIES-AND-TV.md` argues for everywhere else: *its five
  states are five things screen 92 must be able to BE*.

  Two things were not true of that page before 324:

    * **The country.** `region/0` read `Kati.Services.region/0` and rewrote its
      `"GB"` default to `"IR"`, so **ایران** was printed to every Persian
      reader whether or not they had chosen a country — and a reader who
      deliberately chose Britain saw Iran, which is board 301's closing
      sentence.
    * **The money row.** It drew `Kati.Services.Sample.monthly_total/0` — the
      drawing's ۴۶٫۴۷ £ — over a shelf with nothing on it.

  And one thing had never been true: the country row drew a chevron and carried
  no tap, because there was no Persian picker to push. Board 301 is that sheet.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Screens.CountryPicker
  alias Kati.Screens.MyServicesFa
  alias Kati.Services

  @prefix "fa-svc-test-"

  # Every assertion below is about the PERSIAN page, and since
  # mishka-group/kati#103 folded board 301 that is a locale rather than a
  # module: `Kati.Screens.CountryPicker` is the sheet in both scripts and
  # answers ایران, «آلمان» and `marked() == "IR"` only when asked in Persian.
  # No restore in `on_exit`: `Mob.ScreenCase` tears `Mob.State` down with the
  # test process, so a write there exits. The store is per-test anyway.
  setup do
    Kati.Locale.put(:fa)
    Kati.Locale.activate()

    on_exit(fn ->
      Kati.Repo.query!("DELETE FROM services WHERE name LIKE ?1", [@prefix <> "%"])
    end)

    :ok
  end

  describe "the country row, with no country chosen" do
    test "asks for one instead of naming one" do
      words = tree(mount_screen(MyServicesFa))

      assert find(words, :text, text: "کشورتان را انتخاب کنید") != nil
      assert find(words, :text, text: "تا این تنظیم نشود چیزی کار نمی‌کند") != nil
      assert find(words, :text, text: "ایران") == nil
    end

    test "and `region/0` says so rather than substituting a country" do
      assert MyServicesFa.region() == nil
    end

    test "and the row opens board 301's sheet" do
      assert {:noreply, socket} =
               MyServicesFa.handle_info({:tap, :pick_country}, mount_screen(MyServicesFa).socket)

      assert socket.__mob__.nav_action == {:push, CountryPicker, %{}}
    end
  end

  describe "the country row, once a country is chosen" do
    test "names it in Persian" do
      Services.put_region("DE")

      assert MyServicesFa.region() == "DE"
      assert find(tree(mount_screen(MyServicesFa)), :text, text: "آلمان") != nil
    end

    test "and a deliberately chosen Britain is Britain — board 301's closing sentence" do
      Services.put_region("GB")

      assert MyServicesFa.region() == "GB"
      assert find(tree(mount_screen(MyServicesFa)), :text, text: "بریتانیا") != nil
      assert find(tree(mount_screen(MyServicesFa)), :text, text: "ایران") == nil
    end
  end

  describe "the money row, with nothing subscribed" do
    test "says nothing has been totalled rather than totalling nothing" do
      words = tree(mount_screen(MyServicesFa))

      assert find(words, :text, text: "هنوز چیزی برای جمع‌زدن نیست") != nil
      assert find(words, :text, text: "اشتراک‌ها") != nil

      # The drawing's figure, which this row used to print over an empty shelf.
      refute inspect(words, limit: :infinity, printable_limit: :infinity) =~ "۴۶٫۴۷"
    end
  end

  describe "the money row, once something IS subscribed" do
    test "prints what this reader's services cost, not the drawing's ۴۶٫۴۷" do
      # The exact shape of MOVIES-AND-TV.md #76, one screen over: the count came
      # off `MyServices.listed/0` and the money did not, so a Persian reader
      # with one service of their own was told `۱ سرویس · ۴۶٫۴۷ £ در ماه`.
      Ash.create!(Services.Service, %{
        name: @prefix <> "کانال یک",
        tier: :subscribed,
        monthly_pence: 899,
        currency: "GBP"
      })

      words =
        inspect(tree(mount_screen(MyServicesFa)), limit: :infinity, printable_limit: :infinity)

      assert words =~ "۸٫۹۹",
             "the money row does not print this reader's own total"

      refute words =~ "۴۶٫۴۷",
             "the money row still prints the drawing's total beside a live count"
    end

    test "and the count beside it is the reader's own, in Persian digits" do
      for name <- ["یک", "دو"] do
        Ash.create!(Services.Service, %{
          name: @prefix <> name,
          tier: :subscribed,
          monthly_pence: 500,
          currency: "GBP"
        })
      end

      words = tree(mount_screen(MyServicesFa))

      assert find(words, :text, text: "۲ سرویس") != nil
      assert find(words, :text, text: "۱۰٫۰۰ £ در ماه") != nil
    end

    test "services with no price say so rather than borrowing a figure nobody entered" do
      Ash.create!(Services.Service, %{name: @prefix <> "بی‌قیمت", tier: :subscribed})

      words =
        inspect(tree(mount_screen(MyServicesFa)), limit: :infinity, printable_limit: :infinity)

      # `—` is the same answer screen 92 gives, and `amount/1` passes it through
      # untouched: it has no digits to convert and no currency symbol to move.
      assert words =~ "— در ماه"
      refute words =~ "۴۶٫۴۷"
    end
  end

  describe "board 301's sheet" do
    test "marks Iran before any choice, and marks it without storing it" do
      assert CountryPicker.marked() == "IR"
      assert Services.chosen_region() == nil
    end

    test "and marks the reader's own country once there is one" do
      Services.put_region("NL")

      assert CountryPicker.marked() == "NL"
    end

    test "matches by Persian name, by English name and by code" do
      assert CountryPicker.matching("آلمان") == [{"DE", "آلمان"}]
      assert CountryPicker.matching("ger") == [{"DE", "آلمان"}]
      assert CountryPicker.matching("NL") == [{"NL", "هلند"}]
    end

    test "lists every country in Persian when nothing is typed" do
      assert length(CountryPicker.matching("")) == length(Services.countries())

      assert Enum.all?(CountryPicker.matching(""), fn {_code, name} ->
               String.match?(name, ~r/\p{Arabic}/u)
             end),
             "a country in the Persian sheet is still named in English"
    end

    test "counts what it filters, not JustWatch's 190" do
      seven = Kati.I18n.Digits.to_persian(length(Services.countries()))

      assert CountryPicker.placeholder() == "جست‌وجو در " <> seven <> " کشور"
      refute CountryPicker.placeholder() =~ "۱۹۰"
    end

    test "says so when a query matches nothing" do
      card = CountryPicker.nothing_card("زیمبابوه")

      assert find(card, :text, text: "کشوری پیدا نشد") != nil

      assert find(card, :text, text: "کاتی ۷ کشور دارد و هیچ‌کدام «زیمبابوه» نیست.") != nil
    end

    test "picking one stores it, which is what screen 97 then reads" do
      socket = mount_screen(CountryPicker).socket

      assert {:noreply, _socket} = CountryPicker.handle_info({:tap, :pick_FR}, socket)
      assert Services.chosen_region() == "FR"
      assert MyServicesFa.region() == "FR"
    end
  end
end
