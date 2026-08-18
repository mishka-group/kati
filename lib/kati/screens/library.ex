defmodule Kati.Screens.Library do
  @moduledoc """
  Screen 03 — the Library root.

  Shelf switcher, quick tiles, live filter tabs and a poster grid. The design's
  rule is that **sections add shelves, never tabs**: Books and Music appear in
  the switcher greyed until built, which is also how #60 scoped v1 to Screen
  only. Drawing them greyed is the design's own mechanism for "not yet", not a
  placeholder.
  """
  use Kati.Screens.Root, root: :library

  alias Kati.UI

  defp content(_assigns) do
    ~MOB"""
    <Scroll background={:background}>
      <Column background={:background} fill_width={true}>
        <Spacer size={52} />
        <Column padding_left={21} padding_right={21} fill_width={true}>
          <Text text="LIBRARY" text_size={11} text_color={:muted} letter_spacing={0.14} />
          <Spacer size={5} />
          <Text
            text="Screen"
            text_size={34}
            text_color={:on_surface}
            font_weight="bold"
            letter_spacing={-1.0}
          />
        </Column>
        <Spacer size={17} />
        {shelves()}
        <Spacer size={20} />
        {filters()}
        <Spacer size={22} />
        {grid()}
        <Spacer size={150} />
      </Column>
    </Scroll>
    """
  end

  # Books and Music are greyed rather than absent: the design's own way of
  # showing a section that exists but is not built (#60 keeps v1 to Screen).
  defp shelves do
    ~MOB"""
    <Scroll axis="horizontal">
      <Row>
        <Spacer size={21} />
        {UI.chip("Screen", :selected)}
        {UI.chip("Books", :disabled)}
        {UI.chip("Music", :disabled)}
      </Row>
    </Scroll>
    """
  end

  defp filters do
    ~MOB"""
    <Scroll axis="horizontal">
      <Row>
        <Spacer size={21} />
        {UI.chip("All 9", :selected)}
        {UI.chip("Watching 4", :unselected)}
        {UI.chip("Finished 3", :unselected)}
        {UI.chip("Wishlist 2", :unselected)}
      </Row>
    </Scroll>
    """
  end

  defp grid do
    ~MOB"""
    <Column padding_left={21} padding_right={21} fill_width={true}>
      <Row>
        {UI.poster("Severance", 0xFF3B4A52)}
        {UI.poster("Dune: Part Two", 0xFF6E5A43)}
        {UI.poster("Shōgun", 0xFF4A3B3B)}
      </Row>
      <Spacer size={13} />
      <Row>
        {UI.poster("The Bear", 0xFF3E4A3B)}
        {UI.poster("Poor Things", 0xFF5A3B52)}
        {UI.poster("Past Lives", 0xFF3B4352)}
      </Row>
    </Column>
    """
  end
end
