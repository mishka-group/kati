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

  alias Kati.Screens.CountryPickerFa
  alias Kati.Screens.MyServicesFa
  alias Kati.Services

  @prefix "fa-svc-test-"

  setup do
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

      assert socket.__mob__.nav_action == {:push, CountryPickerFa, %{}}
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

  describe "board 301's sheet" do
    test "marks Iran before any choice, and marks it without storing it" do
      assert CountryPickerFa.marked() == "IR"
      assert Services.chosen_region() == nil
    end

    test "and marks the reader's own country once there is one" do
      Services.put_region("NL")

      assert CountryPickerFa.marked() == "NL"
    end

    test "matches by Persian name, by English name and by code" do
      assert CountryPickerFa.matching("آلمان") == [{"DE", "آلمان"}]
      assert CountryPickerFa.matching("ger") == [{"DE", "آلمان"}]
      assert CountryPickerFa.matching("NL") == [{"NL", "هلند"}]
    end

    test "lists every country in Persian when nothing is typed" do
      assert length(CountryPickerFa.matching("")) == length(Services.countries())

      assert Enum.all?(CountryPickerFa.matching(""), fn {_code, name} ->
               String.match?(name, ~r/\p{Arabic}/u)
             end),
             "a country in the Persian sheet is still named in English"
    end

    test "counts what it filters, not JustWatch's 190" do
      seven = Kati.I18n.Digits.to_persian(length(Services.countries()))

      assert CountryPickerFa.placeholder() == "جست‌وجو در " <> seven <> " کشور"
      refute CountryPickerFa.placeholder() =~ "۱۹۰"
    end

    test "says so when a query matches nothing" do
      card = CountryPickerFa.nothing_card("زیمبابوه")

      assert find(card, :text, text: "کشوری پیدا نشد") != nil

      assert find(card, :text, text: "کاتی ۷ کشور دارد و هیچ‌کدام «زیمبابوه» نیست.") != nil
    end

    test "picking one stores it, which is what screen 97 then reads" do
      socket = mount_screen(CountryPickerFa).socket

      assert {:noreply, _socket} = CountryPickerFa.handle_info({:tap, :pick_FR}, socket)
      assert Services.chosen_region() == "FR"
      assert MyServicesFa.region() == "FR"
    end
  end
end
