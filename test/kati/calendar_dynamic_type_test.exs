defmodule Kati.CalendarDynamicTypeTest do
  @moduledoc """
  The Calendar root at 235% Dynamic Type (#79), read off the rendered tree.

  Separate from `Kati.DynamicTypeTest`, which is async and asserts on source
  text: this one mounts, so it needs `Mob.State` and a theme, and it can prove
  the prop reaches the node rather than merely appearing in the file.

  ## The rule this screen settles

  Stated in `Kati.Screens.Calendar.day_strip/1` and asserted here, because 62
  screens will meet the same question:

    * **Content grows.** The day number is what the strip is for.
    * **Chrome whose size carries structure caps.** Seven cells across is a
      week; a 30pt pill is a pill. Growing either does not make it more
      readable, it makes it stop being what it is.
    * **A heading sharing a row with a control yields to it.** The control
      cannot shrink below its own label.
    * **A fixed size is never the answer.** `width={44}` on the day cell is
      what clipped the digits out of it in the first place.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Screens.Calendar

  setup do
    Kati.Theme.activate()
    {:ok, tree: mount_screen(Calendar)}
  end

  describe "content grows" do
    test "no day number is capped — the digits are why the cell flexes", %{tree: tree} do
      numbers =
        for node <- flatten(tree),
            node.type == :text,
            String.match?(to_string(node.props[:text] || ""), ~r/^\d{1,2}$/),
            node.props[:font_weight] == "bold",
            do: node.props

      refute numbers == [], "no day numbers found — this test is reading the wrong nodes"

      for props <- numbers do
        refute Map.has_key?(props, :max_font_scale),
               "a day number is capped. It is the content; the cell follows it."
      end
    end

    test "the cells flex rather than carrying a width", %{tree: tree} do
      # `width={44}` was the original defect: a Box with a numeric width does
      # not grow, so at 235% the digits were clipped out of it entirely,
      # leaving weekday abbreviations above empty space.
      cells =
        for node <- flatten(tree),
            node.type == :box,
            match?({_pid, tag} when is_atom(tag), node.props[:on_tap]),
            {_pid, tag} = node.props[:on_tap],
            String.starts_with?(Atom.to_string(tag), "day_"),
            do: node.props

      assert length(cells) == 7, "expected seven day cells, found #{length(cells)}"

      for props <- cells do
        assert props[:weight] == 1.0, "a day cell must flex"
        refute Map.has_key?(props, :width), "a fixed width is what clipped the digits"
      end
    end
  end

  describe "chrome caps" do
    test "every weekday abbreviation caps, so it stays inside its cell", %{tree: tree} do
      names =
        for node <- flatten(tree),
            node.type == :text,
            to_string(node.props[:text] || "") in ~w(Mon Tue Wed Thu Fri Sat Sun),
            do: node.props

      assert length(names) == 7, "expected seven weekday labels, found #{length(names)}"

      for props <- names do
        assert props[:max_font_scale],
               "uncapped, the abbreviation overflows the cell it labels — measured on a " <>
                 "Pixel 9a at 2.35, where Wed ran past its own rounded card"
      end
    end

    test "the Today pill's label caps, because the pill's height does not grow", %{tree: tree} do
      today = Enum.find(flatten(tree), &(&1.type == :text and &1.props[:text] == "Today"))

      assert today, "no Today pill found"
      assert today.props[:max_font_scale]
    end
  end

  describe "a heading yields to a control in its row" do
    test "the month name caps", %{tree: tree} do
      # At 235% "August 2026" took 727 of 1080 pixels and the pill — which hugs
      # its own label — was squeezed until its text ellipsised to "...". A pill
      # that says nothing is not a smaller control, it is a broken one.
      #
      # The app-wide sweep that capped every display title missed this one: it
      # keyed on `text_size={28}` and the month heading is 20.
      month =
        Enum.find(flatten(tree), fn node ->
          node.type == :text and
            String.match?(to_string(node.props[:text] || ""), ~r/^[A-Z][a-z]+ \d{4}$/)
        end)

      assert month, "no month heading found"

      assert month.props[:max_font_scale],
             "the month heading shares its row with the Today pill and must yield to it"
    end
  end

  describe "what is reachable rather than merely visible" do
    test "the filter row scrolls, so the last chip can still be tapped", %{tree: tree} do
      # Four chips at 235% are wider than the display. They no longer wrap
      # mid-word; what makes Money reachable is the scroll, and losing it would
      # look identical at 100%.
      scrolls =
        for node <- flatten(tree),
            node.type == :scroll,
            node.props[:axis] == "horizontal",
            do: node

      refute scrolls == [], "the chip row must scroll or the last filter cannot be tapped"
    end
  end
end
