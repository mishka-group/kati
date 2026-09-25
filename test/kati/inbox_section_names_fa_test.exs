defmodule Kati.InboxSectionNamesFaTest do
  @moduledoc """
  The notification inbox names its sections in the reader's language (N21).

  ## The defect this exists for

  `Kati.Notifications.Inbox.domain_label/1` answered English literals, so the
  Persian inbox's *By section* card — under بر اساس بخش — listed Calendar,
  Screen, Habits, Meals, Health and Money. The same six words are Persian
  everywhere else in the app, and Settings' Sections group already draws three
  of them.

  ## What is asserted

    * each label, in Persian, written out here rather than read from the
      catalogue — a test that asks the code what to expect agrees with it;
    * that *Screen*, *Habits* and *Money* are the very words Settings' Sections
      rows say, so the inbox reuses those msgids rather than a second Persian;
    * the rendered page in Persian carries none of the six English names;
    * the *reminder* fallback title, which glued an English word onto the name.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Notifications.Inbox

  @persian %{
    calendar: "تقویم",
    tv: "نمایش",
    habits: "عادت‌ها",
    meals: "وعده‌ها",
    health: "سلامت",
    money: "مالی"
  }

  @english ~w(Calendar Screen Habits Meals Health Money)

  setup do
    installed = Mob.Theme.current()
    on_exit(fn -> Mob.Theme.set(installed) end)

    Kati.Locale.put(:en)
    :ok
  end

  test "every section's name is Persian under :fa" do
    for {domain, word} <- @persian do
      assert fa(fn -> Inbox.domain_label(domain) end) == word
    end
  end

  test "English is unchanged under :en" do
    assert Enum.map([:calendar, :tv, :habits, :meals, :health, :money], &Inbox.domain_label/1) ==
             @english
  end

  test "the inbox says the words Settings' Sections group says" do
    fa(fn ->
      titles = Map.new(Kati.Settings.Sample.sections(), &{&1.id, &1.title})

      assert Inbox.domain_label(:tv) == titles["screen"]
      assert Inbox.domain_label(:habits) == titles["habits"]
      assert Inbox.domain_label(:money) == titles["money"]
    end)
  end

  test "the Persian page draws no English section name" do
    texts = fa(fn -> texts(mount_screen(Kati.Screens.InboxNotifications)) end)

    assert "بر اساس بخش" in texts

    for word <- Map.values(@persian) do
      assert word in texts, "the By section card does not name #{word}"
    end

    for word <- @english do
      refute word in texts, "the Persian inbox still says #{word}"
    end
  end

  test "a reminder with no title of its own is named in the reader's language" do
    candidate = %Kati.Notifications.Candidate{
      id: "n21",
      domain: :meals,
      fire_at: ~U[2026-09-25 19:00:00Z]
    }

    assert Inbox.title(candidate) == "Meals reminder"
    assert fa(fn -> Inbox.title(candidate) end) == "یادآور وعده‌ها"
  end

  defp fa(fun) do
    Kati.Locale.put(:fa)

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
