defmodule Kati.Screens.Stats do
  @moduledoc """
  Screen 07 — the Stats root, "Your year".

  Carries the 104-cell pixel field, which the design calls the shared visual
  for any section that accumulates over time. It is the clearest test of the
  no-wrap rule: 104 cells are laid out as declared rows of 13, because `Row`
  runs off the edge rather than flowing and nothing reports geometry back.
  """
  use Kati.Screens.Root, root: :stats

  alias Kati.UI

  # 104 cells: 8 rows of 13. Values are sample intensities 0..4.
  @field for i <- 1..104, do: rem(i * 7 + div(i, 5), 5)

  defp content(_assigns) do
    ~MOB"""
    <Scroll background={:background}>
      <Column background={:background} fill_width={true}>
        <Spacer size={52} />
        {headline()}
        <Spacer size={24} />
        {field()}
        <Spacer size={26} />
        {trio()}
        <Spacer size={26} />
        {genres()}
        <Spacer size={150} />
      </Column>
    </Scroll>
    """
  end

  defp headline do
    ~MOB"""
    <Column padding_left={21} padding_right={21} fill_width={true}>
      <Text text="YOUR YEAR" text_size={11} text_color={:muted} letter_spacing={0.14} />
      <Spacer size={5} />
      <Row align="center">
        <Text
          text="312h 40m"
          text_size={34}
          text_color={:on_surface}
          font_weight="bold"
          letter_spacing={-1.0}
        />
        <Spacer size={11} />
        <Box
          background={0xFFE8F0E8}
          corner_radius={22}
          padding_left={11}
          padding_right={11}
          padding_top={5}
          padding_bottom={5}
          width={62}
        >
          <Column align="center">
            <Text text="+18%" text_size={11} text_color={0xFF4E9A73} />
          </Column>
        </Box>
      </Row>
      <Spacer size={4} />
      <Text text="watched across 2026" text_size={12} text_color={:muted} />
    </Column>
    """
  end

  defp field do
    # Bound to a local first: inside ~MOB, `@name` means an assign, not a
    # module attribute, so `@field` would be read as `assigns.field`.
    cells = @field

    ~MOB"""
    <Column padding_left={21} padding_right={21} fill_width={true}>
      {Kati.UI.pixel_field(cells, 13)}
    </Column>
    """
  end

  defp trio do
    ~MOB"""
    <Column padding_left={21} padding_right={21} fill_width={true}>
      <Row>
        {UI.stat("84", "titles")}
        {UI.stat("19", "rewatches")}
        {UI.stat("4.1", "avg rating")}
      </Row>
    </Column>
    """
  end

  defp genres do
    ~MOB"""
    <Column padding_left={21} padding_right={21} fill_width={true}>
      {UI.section_title("BY GENRE")}
      {UI.bar("Drama", 168, 0xFF3B4A52)}
      {UI.bar("Sci-fi", 132, 0xFF6E5A43)}
      {UI.bar("Comedy", 96, 0xFF4E9A73)}
      {UI.bar("Thriller", 64, 0xFF4A3B3B)}
      {UI.bar("Docs", 38, 0xFFB08E55)}
    </Column>
    """
  end
end
