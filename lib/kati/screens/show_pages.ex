defmodule Kati.Screens.ShowPages do
  @moduledoc """
  The ⋯ menu the per-show sub-pages carry, and where its rows go.

  Screens 34 and 35 each draw a ⋯ disc at the top right
  — the same glyph, in the same place, as screen 04's, where it opens a menu —
  and `Kati.UI.SettingsList.chrome/2` built a themed icon with no `on_tap`. It
  reached no handler, so `Kati.ScreenTapSweepTest` could not see it either: a
  dead control that nothing in the suite had an opinion about.

  Deleting it was the smaller fix and the worse one. Both screens are per-show
  pages reached through 04's ⋯, and from either of them the only way to the
  sibling page was back to 04 and open that menu again. So the disc opens the
  rows a reader on this page actually wants: **the other per-show pages**, this
  one left out.

  Three pages, and each screen offers the two it is not:

    * **14** *Show details* — `Kati.Screens.SeriesMeta`
    * **34** *Episode order* — `Kati.Screens.Season`
    * **35** *Show settings* — `Kati.Screens.SeriesSettings`

  04 is deliberately not among them. It is where the back pill goes, and a menu
  row that duplicates the back control is a second way to do the thing the user
  can already see how to do.

  ## Over the drawing there is no menu

  A page drawing the board has no show to open the sibling page over, so the
  disc is drawn without a tap rather than opening a menu whose every row would
  push a bare screen. That is the rule screen 35's status tiles and screen 34's
  order tiles both keep: a control that exists only over data is not drawn live
  over the picture of it.
  """

  alias Kati.UI.Menu
  alias Kati.UI.SettingsList

  # Glyph, label and destination for each per-show page, in the order 04's own
  # menu lists them — what the show IS, then how its episodes are numbered,
  # then what Kati does about it. One list rather than one per screen, so a
  # fourth page cannot be added to two menus and forgotten in the third.
  @pages [
    {Kati.Screens.SeriesMeta, "info", "Show details", :go_show_details},
    {Kati.Screens.Season, "checklist", "Episode order", :go_episode_order},
    {Kati.Screens.SeriesSettings, "tune", "Show settings", :go_show_settings}
  ]

  @doc """
  The header for a per-show sub-page: the ⋯ disc, and its menu when open.

  `tracked_id` is the show all the rows push over, and `nil` — the board —
  draws the disc as `Kati.UI.SettingsList.chrome/2` always did.
  """
  @spec chrome(module(), String.t() | nil, boolean()) :: map()
  def chrome(screen, tracked_id, open?)

  def chrome(_screen, nil, _open?), do: SettingsList.chrome("more_horiz", 44)

  def chrome(screen, tracked_id, open?) when is_binary(tracked_id) do
    import Mob.Sigil

    assigns = %{
      menu:
        Menu.overflow(
          SettingsList.disc("more_horiz", {self(), :toggle_menu}),
          open?,
          Kati.Screens.ShowPages.items(screen),
          dismiss: :close_menu
        )
    }

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} height={44} align="center">
        <Spacer weight={1.0} />
        {@menu}
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc """
  The rows one screen offers: every per-show page except its own.

      iex> Kati.Screens.ShowPages.items(Kati.Screens.Season) |> Enum.map(& &1.label)
      ["Show details", "Show settings"]

      iex> Kati.Screens.ShowPages.items(Kati.Screens.SeriesSettings) |> Enum.map(& &1.tag)
      [:go_show_details, :go_episode_order]
  """
  @spec items(module()) :: [map()]
  def items(screen) do
    for {module, glyph, label, tag} <- @pages,
        module != screen,
        do: Menu.item(glyph, label, tag)
  end

  @doc """
  Where one row goes, and what it carries.

  Every push names the show — `Kati.Screens.SeriesMeta.params_for/1` and its
  two siblings each spell their own key — plus the `back:` label the reader
  came from, which is `Kati.Screens.Pushed.back_label/2`'s whole point: the
  pill says where back GOES, and from here that is not always *Series*.
  """
  @spec push_for(atom(), String.t(), String.t()) :: {module(), map()} | nil
  def push_for(:go_show_details, tracked_id, back),
    do: {Kati.Screens.SeriesMeta, %{id: tracked_id, back: back}}

  def push_for(:go_episode_order, tracked_id, back),
    do: {Kati.Screens.Season, %{title_id: tracked_id, back: back}}

  def push_for(:go_show_settings, tracked_id, back),
    do: {Kati.Screens.SeriesSettings, %{tracked_id: tracked_id, back: back}}

  def push_for(_other, _tracked_id, _back), do: nil

  @doc """
  Answer one menu tag on a per-show page: open the sibling, or close the menu.

  The menu closes before the push for the reason `Kati.Screens.Series.pick/3`
  gives: this socket is what `Mob.Screen` saves onto the nav history, so a menu
  left open is a menu that reopens itself on every return.
  """
  @spec handle(Mob.Socket.t(), atom(), String.t() | nil, String.t()) ::
          {:handled, Mob.Socket.t()} | :unknown
  def handle(socket, :toggle_menu, _tracked_id, _back),
    do: {:handled, Mob.Socket.assign(socket, :menu?, not socket.assigns.menu?)}

  def handle(socket, :close_menu, _tracked_id, _back),
    do: {:handled, Mob.Socket.assign(socket, :menu?, false)}

  def handle(socket, tag, tracked_id, back) when is_binary(tracked_id) do
    case Kati.Screens.ShowPages.push_for(tag, tracked_id, back) do
      nil ->
        :unknown

      {module, params} ->
        socket
        |> Mob.Socket.assign(:menu?, false)
        |> Mob.Socket.push_screen(module, params)
        |> then(&{:handled, &1})
    end
  end

  def handle(_socket, _tag, _none, _back), do: :unknown
end
