defmodule Kati.Screens.Library do
  @moduledoc "The Library root. Placeholder content until its own tickets land."
  use Kati.Screens.Root, root: :library

  defp content(_assigns) do
    ~MOB"""
    <Scroll background={:background}>
      <Column background={:background} padding={21} fill_width={true}>
        <Spacer size={64} />
        <Text text="Library" text_size={34} text_color={:on_surface} font_weight="bold" />
        <Spacer size={8} />
        <Text text="Root library" text_size={13} text_color={:muted} />
        <Spacer size={24} />
        {Kati.Screens.Library.card("Nothing here yet", "This root is drawn so the shell can be judged as a whole. Its own screens arrive with their tickets.")}
        <Spacer size={132} />
      </Column>
    </Scroll>
    """
  end

  @doc false
  def card(title, body) do
    ~MOB"""
    <Box background={:surface} corner_radius={20} padding={21} fill_width={true}>
      <Column fill_width={true}>
        <Text text={title} text_size={15} text_color={:on_surface} font_weight="semibold" />
        <Spacer size={9} />
        <Text text={body} text_size={13} text_color={:muted} line_height={1.5} />
      </Column>
    </Box>
    """
  end
end
