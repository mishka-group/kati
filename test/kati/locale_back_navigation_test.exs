defmodule Kati.LocaleBackNavigationTest do
  @moduledoc """
  The screen underneath speaks the new language before a back tap paints it
  (#112).

  Mob keeps every screen under the top one alive in its own process, and a back
  tap paints it from there. `Gettext.put_locale/2` is per process, so Settings,
  mounted in English and left underneath the language picker, drew English for
  a moment after the reader chose فارسی and came back. Here Settings lives in
  its own process the same way, and the language changes from this one.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Screens.Settings

  setup do
    Kati.Locale.put(:en)
    start_supervised!(Kati.LiveScreens)
    on_exit(fn -> Mob.State.put(:locale, :en) end)
    :ok
  end

  # Settings mounted in English in a process of its own, as Mob runs it. It
  # answers `:render` with the strings it would paint.
  defp settings_underneath do
    test = self()

    pid =
      spawn_link(fn ->
        Kati.Locale.activate()
        {:ok, socket} = Settings.mount(%{}, %{}, Mob.Socket.new(Settings))
        send(test, :mounted)
        settings_loop(socket)
      end)

    assert_receive :mounted, 5_000
    pid
  end

  defp settings_loop(socket) do
    receive do
      {:render, from} ->
        send(from, {:painted, texts(Settings.render(socket.assigns))})
        settings_loop(socket)

      message ->
        {:noreply, socket} = Settings.handle_info(message, socket)
        settings_loop(socket)
    end
  end

  defp paint(pid) do
    send(pid, {:render, self()})
    assert_receive {:painted, texts}, 5_000
    texts
  end

  test "choosing فارسی reaches the screen underneath before it is painted again" do
    pid = settings_underneath()
    assert "Settings" in paint(pid)

    Kati.Locale.put(:fa)

    painted = paint(pid)

    assert "تنظیمات" in painted,
           "the screen underneath still drew #{inspect(Enum.take(painted, 3))}"

    refute "Settings" in painted

    # The rows are built at load, not at render: a new locale in the process
    # is not enough on its own, the screen has to rebuild them.
    assert "اندازه متن" in painted
    refute "Text size" in painted
    assert "کاتی شما" in painted, "the account card kept the name it was loaded with"
  end

  test "and back to English the same way" do
    Kati.Locale.put(:fa)
    pid = settings_underneath()
    assert "تنظیمات" in paint(pid)

    Kati.Locale.put(:en)

    assert "Settings" in paint(pid)
  end

  test "the screen making the change is not sent its own" do
    Kati.LiveScreens.join()
    Kati.Locale.put(:fa)
    refute_receive {:kati, :locale_changed, _}, 100
  end

  defp texts(tree) do
    tree
    |> List.wrap()
    |> Enum.flat_map(fn
      %{props: props, children: children} ->
        own = if is_binary(props[:text]), do: [props[:text]], else: []
        own ++ texts(children)

      %{children: children} ->
        texts(children)

      _other ->
        []
    end)
  end
end
