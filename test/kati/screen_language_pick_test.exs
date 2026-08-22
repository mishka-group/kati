defmodule Kati.ScreenLanguagePickTest do
  @moduledoc """
  Screen 53's ticked row is `Kati.Locale`, and the drawing has not moved.

  ## The defect this exists for

  `Kati.Onboarding.LanguageSample` froze `chosen: true` onto English. The
  container above it has always read `Kati.Locale.direction_prop()`, so an
  install already in Persian drew this screen right-to-left **with the tick
  still on English** — a language picker contradicting the language it was
  drawn in. Screen 54 has read the locale since it gained a write path, so the
  app's two pickers could disagree about the one setting they both show.

  Nothing about that is visible in a fresh-install capture, which is exactly
  why it needs a test: at `:en` — the default, and what `53.html` draws — the
  frozen answer and the read one are the same answer.

  ## What is asserted, and where each assertion ends

  Two halves, and they pull against each other on purpose:

    * **The drawing cannot move.** `an unset locale renders the same tree as a
      stored :en` is the whole-tree version of that promise, the same shape
      `Kati.SettingsThemeTest` uses for the theme trough. `62 captured frames
      are this app's baseline` applies here too.
    * **The tick is genuinely read.** Every assertion about `:fa` ends at a
      **freshly mounted screen** rather than at a re-render, because a value
      held in the assigns that drew it and a value read from the store look
      identical in one render and differ in the next.

  ## What this screen still does not do

  Choose. No option and no **Continue** carries an `on_tap`, and
  `no control on this screen writes the locale` pins that as the deliberate
  state `Kati.Screens.LanguagePick`'s moduledoc describes rather than a handler
  somebody forgot — so the day a flow lands and the write is wired, this test
  fails and is updated on purpose.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Onboarding.LanguageSample
  alias Kati.Screens.LanguagePick
  alias Kati.Theme.Palette

  # `Mob.Theme.set/1` is `Application.put_env/3` — one global for the whole run,
  # and mounting a screen installs a palette. Put back whatever was installed on
  # the way in, for the reason `Kati.SettingsThemeTest` gives: a palette left
  # behind here renders another file's screens in a mode whose numbers it does
  # not assert.
  setup do
    installed = Mob.Theme.current()
    on_exit(fn -> Mob.Theme.set(installed) end)
  end

  # The two rows the drawing draws, by the name each carries in its own script.
  @english "English"
  @persian "فارسی"

  # ── The mapping ─────────────────────────────────────────────────────────────

  test "an option names its locale by script, never by the word it displays" do
    assert LanguagePick.locale_of(%{script: :persian}) == :fa
    assert LanguagePick.locale_of(%{script: :latin}) == :en

    # The whole point of going through `script:`: neither name is English, and
    # the Persian row's name is not the string `"fa"` either.
    assert LanguagePick.locale_of(%{script: :latin, name: @persian}) == :en

    # An option from a build that grew a third script is not silently Persian.
    assert LanguagePick.locale_of(%{script: :arabic}) == :en
  end

  test "every option the drawing holds names a locale Kati actually ships" do
    for option <- LanguageSample.options() do
      assert LanguagePick.locale_of(option) in Kati.Locale.supported()
    end
  end

  # ── The answer ──────────────────────────────────────────────────────────────

  test "a locale never chosen ticks the row 53.html ticks" do
    assert Kati.Locale.current() == :en
    assert chosen_names(LanguagePick.pick()) == [@english]
  end

  test "storing a locale moves the tick, and storing it back moves it back" do
    :ok = Kati.Locale.put(:fa)
    assert chosen_names(LanguagePick.pick()) == [@persian]

    :ok = Kati.Locale.put(:en)
    assert chosen_names(LanguagePick.pick()) == [@english]
  end

  test "exactly one row is ticked, whatever the locale" do
    # A picker with none raised and a picker with two raised are both states no
    # drawing has, and `settle/2` reaches them from opposite directions — a
    # mapping that answers nothing, and one that answers everything.
    for locale <- Kati.Locale.supported() do
      :ok = Kati.Locale.put(locale)

      assert length(chosen_names(LanguagePick.pick())) == 1,
             "at #{locale} the picker does not raise exactly one row"
    end
  end

  test "only `chosen` moves — every other field is still the sample's" do
    for locale <- Kati.Locale.supported() do
      :ok = Kati.Locale.put(locale)

      drawn = LanguageSample.pick()
      read = LanguagePick.pick()

      assert Map.delete(read, :options) == Map.delete(drawn, :options),
             "reading the locale rewrote copy outside the options list"

      assert Enum.map(read.options, &Map.delete(&1, :chosen)) ==
               Enum.map(drawn.options, &Map.delete(&1, :chosen)),
             "reading the locale rewrote an option's script, badge, name or meta"
    end
  end

  # ── The resting frame ───────────────────────────────────────────────────────

  test "at rest the screen draws two option rows and inverts the one 53.html inverts" do
    view = mount_screen(LanguagePick)

    assert names(view) == [@english, @persian]
    assert inverted(view) == [@english]
  end

  test "an unset locale renders the same tree as a stored :en" do
    # The whole tree, not the two rows: this is the promise that reading a
    # setting at mount cannot move a pixel anywhere on the screen. Both copies
    # are rendered in this process, so any pid inside a prop matches.
    unset = tree(mount_screen(LanguagePick))
    :ok = Kati.Locale.put(:en)
    stored = tree(mount_screen(LanguagePick))

    assert unset == stored, "screen 53 renders differently for a locale never chosen"
  end

  test "the inverted row keeps the drawing's own fill and the other keeps the card" do
    view = mount_screen(LanguagePick)

    assert row(view, @english).props[:background] == Palette.ink_fill()
    assert row(view, @english).props[:shadow] == "0 14 28 -14 #E61A1917"
    assert row(view, @persian).props[:background] == Palette.card()

    for name <- [@english, @persian] do
      assert row(view, name).props[:height] == 76
      assert row(view, name).props[:corner_radius] == 22
    end
  end

  # ── Stored, not held in the render that drew it ─────────────────────────────

  test "a screen mounted after the locale changed inverts the other row" do
    view = mount_screen(LanguagePick)
    assert inverted(view) == [@english]

    :ok = Kati.Locale.put(:fa)

    # A second socket, which has never seen the write. This is the assertion the
    # frozen `chosen: true` could not pass.
    assert inverted(mount_screen(LanguagePick)) == [@persian]
  end

  test "the whole frame flips with the row, rather than the row flipping alone" do
    :ok = Kati.Locale.put(:fa)
    view = mount_screen(LanguagePick)

    assert inverted(view) == [@persian]

    # The contradiction this migration removes: the container has always read
    # the locale, so a Persian install drew an RTL frame around an English tick.
    assert frame(view).props[:layout_direction] == "rtl"
  end

  # ── The picker actually picks ───────────────────────────────────────────────

  # This section used to assert the opposite — that nothing on screen 53 was
  # tappable — and said so for a reason worth keeping: writing a locale from a
  # step 1 with no step 2 strands the reader in a flipped interface whose only
  # exit is a back button. `Kati.Onboarding` supplied the step 2, and on a
  # first run this screen is the stack root, so there is no back to strand
  # anyone with. That old test named itself as the thing to update.

  test "both options and Continue carry a tap" do
    :ok = Kati.Locale.put(:en)

    tags =
      mount_screen(LanguagePick)
      |> flatten()
      |> Enum.filter(&Map.has_key?(&1.props, :on_tap))
      |> Enum.map(& &1.props[:on_tap])
      |> Enum.map(fn {_pid, tag} -> tag end)

    for wanted <- [:choose_en, :choose_fa, :continue] do
      assert wanted in tags, "screen 53 draws no control tagged #{inspect(wanted)}"
    end
  end

  test "choosing فارسی writes the locale and re-ticks the picker" do
    :ok = Kati.Locale.put(:en)

    {:noreply, moved} =
      LanguagePick.handle_info({:tap, :choose_fa}, mount_socket(LanguagePick))

    assert Kati.Locale.current() == :fa

    assert Enum.map(moved.assigns.pick.options, & &1.chosen) == [false, true],
           "the tick still follows the old locale — pick/0 was not re-read"
  after
    Kati.Locale.put(:en)
  end

  test "choosing the locale already active leaves it alone" do
    :ok = Kati.Locale.put(:en)
    {:noreply, _} = LanguagePick.handle_info({:tap, :choose_en}, mount_socket(LanguagePick))
    assert Kati.Locale.current() == :en
  end

  test "Continue opens step two" do
    :ok = Kati.Locale.put(:en)

    {:noreply, moved} =
      LanguagePick.handle_info({:tap, :continue}, mount_socket(LanguagePick))

    assert moved.__mob__.nav_action == {:push, Kati.Screens.PickSections, %{}}
  end

  # `mount_screen/1` returns the rendered tree; the handlers need the socket.
  defp mount_socket(module) do
    {:ok, socket} = module.mount(%{}, %{}, %Mob.Socket{})
    socket
  end

  # ── Reading the picker out of a rendered screen ─────────────────────────────

  # The outermost node, which is where `Kati.Locale.direction_prop/0` lands.
  defp frame(view), do: view |> flatten() |> hd()

  # The two option rows, in drawn order. Both are the only 76pt rows on the
  # screen; asserted rather than assumed, so a third one appearing cannot make
  # every helper below quietly read a different control.
  defp rows(view) do
    found =
      view
      |> flatten()
      |> Enum.filter(&(&1.type == :row and &1.props[:height] == 76))

    assert length(found) == 2, "expected two option rows, found #{length(found)}"
    found
  end

  defp row(view, name) do
    Enum.find(rows(view), &(name in texts(&1))) ||
      flunk("no option row draws #{inspect(name)}")
  end

  # A row's name is the one string on it that is neither the two-glyph badge nor
  # the mono specification — matched by the drawn name rather than by position,
  # since the badge comes first in the row.
  defp names(view) do
    for r <- rows(view), name <- [@english, @persian], name in texts(r), do: name
  end

  # Inverted means chosen: the drawing puts the answer on ink and leaves the
  # other on card, the same inversion screen 49 gives the active plan.
  defp inverted(view) do
    for name <- names(view), row(view, name).props[:background] == Palette.ink_fill(), do: name
  end

  defp texts(node) do
    for child <- flatten(node), child.type == :text, do: child.props[:text]
  end

  defp chosen_names(pick) do
    for option <- pick.options, option.chosen, do: option.name
  end
end
