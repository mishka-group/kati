defmodule Kati.OnboardingHonestTest do
  @moduledoc """
  The first run says only what the app does (N49).

  A fresh install walked on the emulator, 26 Sep, read the designers' notes
  aloud: *"Restore stays beneath the button in both scripts. RTL mirrors the
  grid…"* under Get started, *"…the band drawn on 136"* under the loudness
  question, *"Skipping lands on empty Home — 139."* under Finish setup. The
  loudness step offered a *Weekly digest* nothing sends, and dropped the
  reader's answer on Continue, so *Notify me* left push off. Choosing *Notify
  me* then opened a page redrawn from `Kati.Onboarding.Sample` with *Quietly*
  ticked. And the TMDB token block on the first-title step stayed up after the
  reader had chosen a key on the page it opened.
  """
  use Mob.ScreenCase, async: false

  doctest Kati.Screens.LoudnessPrompt

  alias Kati.Screens.LoudnessPrompt
  alias Kati.Screens.OnboardingFirstTitle
  alias Kati.Screens.OnboardingLoudness
  alias Kati.Screens.OnboardingWelcome
  alias Kati.Settings.Watcher

  @notes [
    "Restore stays beneath",
    "RTL mirrors",
    "band drawn",
    "Skipping lands",
    "Weekly digest"
  ]

  setup do
    Kati.Locale.put(:en)
    Kati.Onboarding.reset!()
    push = Watcher.loud?(:push)
    key = Kati.Sources.tmdb_key()
    token = System.get_env("TMDB_READ_TOKEN")

    on_exit(fn ->
      if token,
        do: System.put_env("TMDB_READ_TOKEN", token),
        else: System.delete_env("TMDB_READ_TOKEN")
    end)

    Process.put(:restore, {push, key})
    :ok
  end

  defp restore do
    {push, key} = Process.get(:restore)
    Watcher.put_loud(:push, push)
    Kati.Sources.put_tmdb_key(key)
  end

  defp mounted(module) do
    {:ok, socket} = module.mount(%{}, %{}, Mob.Socket.new(module))
    socket
  end

  defp drawn(module, socket \\ nil) do
    socket = socket || mounted(module)
    inspect(module.render(socket.assigns), limit: :infinity)
  end

  describe "no step reads a design note aloud" do
    for module <- [OnboardingWelcome, OnboardingLoudness, OnboardingFirstTitle, LoudnessPrompt] do
      test "#{inspect(module)}" do
        page = drawn(unquote(module))

        for note <- @notes do
          refute page =~ note, "#{inspect(unquote(module))} draws #{inspect(note)}"
        end

        restore()
      end
    end
  end

  describe "the loudness step" do
    test "offers the two answers the app keeps" do
      assert Enum.map(OnboardingLoudness.choice_list(), &elem(&1, 0)) == [:quiet, :notify]
    end

    test "Notify me is stored as the watcher's push switch" do
      Watcher.put_loud(:push, false)

      {:noreply, picked} =
        OnboardingLoudness.handle_tap(:choose_notify, mounted(OnboardingLoudness))

      assert picked.assigns.choice == :notify
      assert Watcher.loud?(:push)

      {:noreply, moved} = OnboardingLoudness.handle_tap(:next, picked)
      assert {:push, LoudnessPrompt, _params} = moved.__mob__.nav_action
      restore()
    end

    test "Quietly switches it back off and skips the permission step" do
      Watcher.put_loud(:push, true)

      {:noreply, picked} =
        OnboardingLoudness.handle_tap(:choose_quiet, mounted(OnboardingLoudness))

      {:noreply, moved} = OnboardingLoudness.handle_tap(:next, picked)

      refute Watcher.loud?(:push)
      assert {:push, OnboardingFirstTitle, _params} = moved.__mob__.nav_action
      restore()
    end

    test "opens on the answer already stored" do
      Watcher.put_loud(:push, true)
      assert mounted(OnboardingLoudness).assigns.choice == :notify

      Watcher.put_loud(:push, false)
      assert mounted(OnboardingLoudness).assigns.choice == :quiet
      restore()
    end

    test "the Quietly sentence is one line of text, not three" do
      page = drawn(OnboardingLoudness)

      assert page =~
               "Kati won’t ask for notification permission. Everything arrives in your inbox."

      restore()
    end
  end

  describe "the permission step" do
    test "does not draw the loudness question it came from" do
      page = drawn(LoudnessPrompt)

      refute page =~ "Quietly"
      refute page =~ "won’t ask"
      assert page =~ "One prompt, then never again"
      restore()
    end

    test "a refusal switches push back off and the run goes on" do
      Watcher.put_loud(:push, true)

      {:noreply, moved} =
        LoudnessPrompt.handle_info(
          {:permission, :notifications, :denied},
          mounted(LoudnessPrompt)
        )

      refute Watcher.loud?(:push)
      assert {:push, OnboardingFirstTitle, _params} = moved.__mob__.nav_action
      restore()
    end

    test "a grant keeps it on" do
      Watcher.put_loud(:push, true)

      {:noreply, _moved} =
        LoudnessPrompt.handle_info(
          {:permission, :notifications, :granted},
          mounted(LoudnessPrompt)
        )

      assert Watcher.loud?(:push)
      restore()
    end

    test "with no platform to ask, Continue goes straight on" do
      {:noreply, moved} = LoudnessPrompt.handle_tap(:continue, mounted(LoudnessPrompt))

      assert {:push, OnboardingFirstTitle, _params} = moved.__mob__.nav_action
      restore()
    end
  end

  describe "the first-title step" do
    test "re-reads the TMDB key when the reader comes back from screen 80" do
      Kati.Sources.put_tmdb_key(:own)
      System.delete_env("TMDB_READ_TOKEN")
      socket = mounted(OnboardingFirstTitle)

      refute socket.assigns.tmdb_ready
      assert drawn(OnboardingFirstTitle, socket) =~ "Add your TMDB token"

      Kati.Sources.put_tmdb_key(:kati)
      System.put_env("TMDB_READ_TOKEN", "test-token")

      {:noreply, back} = OnboardingFirstTitle.handle_kati(:resumed, nil, socket)

      assert back.assigns.tmdb_ready == true
      refute drawn(OnboardingFirstTitle, back) =~ "Add your TMDB token"

      restore()
    end
  end
end
