defmodule Kati.Screens.ViewSwitcher do
  @moduledoc """
  Day / Week / Month / Agenda — the one switcher screens 16, 17 and 30 share.

  The drawing is literal about it: a `#E4E0D9` trough at radius 16 with 4pt of
  padding, four `flex:1` segments 34 tall at radius 12, and the selected one
  lifted onto card white with its own shallow shadow.

  ## Still hand-rolled, and the reason has moved

  It used to be that `flex:1`. The port's segments were **content-sized** — it
  dropped `weight` so the Android and iOS mappings would agree — and four labels
  of unequal length bunched against the leading edge instead of each taking an
  exact quarter. `segment_weight` closes that, and with it `segment_height`,
  `padding`, `segment_radius`, `track_padding`, `selected_shadow`,
  `selected_weight` and the four colours, every other number on this strip is
  now a prop. Rendered side by side, one difference is left:

      port:        Row[ seg seg seg seg ]
      this screen: Row[ seg gap seg gap seg gap seg ]

  **The port has no gap between segments, and no prop that adds one.** The
  drawing puts 4pt between them. Padding cannot stand in: `MobBridge`'s
  `nodeModifier` applies `background` *before* `padding`, so a segment's padding
  is inside its fill — widening the selected tile's white rectangle rather than
  separating it — and the prop is per-control anyway, so it would also inset the
  two outer edges and make the track 6 wider. `track_padding` only moves the
  whole strip in. And the segments cannot be interspersed by hand, because
  `expand/3` filters its children to `:mishka_segmented_control_option` and drops
  everything else, so a `<Spacer>` between two options never reaches the tree.

  With no gap, all four segment boundaries land at different x, the track is
  12pt narrower, and the selected tile — the only one with a fill — is drawn at
  the wrong width. That is a change of appearance, so the markup stays.

  What would close it upstream is one prop: a `segment_gap` the control
  intersperses as a `<Spacer>` between segments, defaulting to `0` so no
  existing strip moves.

  The labels stay with the screens rather than living here, so each screen
  file still contains every word its drawing contains.

  ## A label is a key, and the word is the reader's

  Each screen names its segments by their English key — `"Day"`, `"Week"`,
  `"Month"`, `"Agenda"` — and that key is what the tap tag is built from and
  what `screen/1` routes on. The word drawn is `label/1`'s, through gettext, so
  the strip reads روز · هفته · ماه · فهرست on a Persian page while the tags
  stay `view_Day` and friends. Building the tag out of the drawn word would
  have renamed every control under `:fa` and routed none of them.

  ## Tapping a segment

  Every segment except the selected one carries `on_tap: {self(), :view_<Label>}`.
  The selected one carries `nil` — it has nowhere to go, and a tap that does
  nothing is worse than no tap at all.

  The tag carries the label, so a fifth view would be a data change in the
  screen that draws the bar rather than a code change here.

  `self()` at render time is the **screen** process, so the message lands in
  the screen's `handle_info({:tap, tag}, socket)`. `Kati.Screens.Root`'s macro
  routes anything that is not a `root_*` tag to the screen's own
  `handle_tap/2`, whose default is a no-op — so a screen that draws this bar
  must delegate, in one line:

      @impl true
      def handle_tap(tag, socket), do: Kati.Screens.ViewSwitcher.handle_tap(tag, socket)

  `handle_tap/2` here swallows anything that is not a `view_*` tag, so a screen
  with taps of its own puts its own clauses above that line.
  """

  use Gettext, backend: Kati.Gettext
  import Mob.Sigil

  alias Kati.Theme.Palette

  # `0 1px 2px rgba(26,25,23,.06), 0 6px 12px -8px rgba(26,25,23,.4)`.
  # Shallower than the card recipe because the tile is lifted off a trough
  # rather than off paper.
  @selected_shadow "0 1 2 0 #0F1A1917 | 0 6 12 -8 #661A1917"

  @doc """
  The strip, given `[{label, selected?}]` in the order the design draws them.
  """
  @spec bar([{String.t(), boolean()}]) :: term()
  def bar(items) do
    segments =
      items
      |> Enum.map(fn {label, on?} -> segment(label, on?) end)
      |> Enum.intersperse(gap())

    ~MOB"""
    <Box fill_width={true} background={Palette.placeholder()} corner_radius={16} padding={4}>
      <Row fill_width={true} align="center">
        {segments}
      </Row>
    </Box>
    """
  end

  @doc false
  def gap, do: ~MOB"<Spacer size={4} />"

  @doc """
  The word a segment key is drawn as, in the reader's language.

      iex> Kati.Locale.as(:fa, fn -> Kati.Screens.ViewSwitcher.label("Week") end)
      "هفته"
  """
  @spec label(String.t()) :: String.t()
  def label("Day"), do: gettext("Day")
  def label("Week"), do: gettext("Week")
  def label("Month"), do: gettext("Month")
  def label("Agenda"), do: gettext("Agenda")
  def label(other), do: other

  @doc false
  def segment(key, on?) do
    # Bound to locals first: inside ~MOB an `@name` is an assign, never a
    # module attribute, so @selected_shadow would be read as assigns.selected_shadow.
    shadow = if on?, do: @selected_shadow, else: nil
    # The selected tile is lifted onto `card` — the surface meaning of
    # `0xFFFBFAF8`, not `on_ink`/`fab_glyph`/`on_media` — and the other three
    # segments draw nothing at all, which is `transparent` rather than an
    # omitted prop. The selected label is `ink` (text, not a fill), and the
    # unselected one is the token named for exactly this control.
    background = if on?, do: Palette.card(), else: Palette.transparent()
    color = if on?, do: Palette.ink(), else: Palette.segment_idle()
    weight = if on?, do: "bold", else: "semibold"
    # The view you are already in is not a destination.
    tap = if on?, do: nil, else: {self(), String.to_atom("view_" <> key)}
    label = label(key)

    ~MOB"""
    <Box
      weight={1.0}
      height={34}
      corner_radius={12}
      background={background}
      shadow={shadow}
      align="center"
      on_tap={tap}
    >
      <Text text={label} text_size={12.5} font_weight={weight} text_color={color} max_lines={1} />
    </Box>
    """
  end

  @doc """
  The screen a label names.

  Day is a pushed screen and the other three are calendar roots, but all four
  are reached the same way — pushed over whatever is below — because the
  Calendar root already reaches Month and Agenda with `push_screen/2` and back
  has to keep meaning "the schedule I came from".
  """
  @spec screen(String.t()) :: module() | nil
  def screen("Day"), do: Kati.Screens.Day
  def screen("Week"), do: Kati.Screens.Week
  def screen("Month"), do: Kati.Screens.MonthGrid
  def screen("Agenda"), do: Kati.Screens.Agenda
  def screen(_other), do: nil

  # The day the caller is showing, carried across the switch. A bare push meant
  # *Day* landed on `Kati.Screens.Day`'s no-params branch, which drew a fixture
  # rather than a date — so the one control whose whole job is "the same moment,
  # a different way" changed the moment too.
  #
  # A screen with no `:date` of its own carries the calendar's selected day, so
  # *Day* never lands on a date the reader did not pick. The three roots ignore
  # the param and read `Kati.Calendars.SelectedDate` themselves.
  defp carried(socket) do
    case Map.get(socket.assigns, :date) do
      %Date{} = date -> %{date: date}
      _none -> %{date: Kati.Calendars.SelectedDate.get()}
    end
  end

  @doc """
  Handles a `view_*` tap for any screen that draws the bar.

  Returns the socket untouched for every other tag, so a screen can delegate
  its whole `handle_tap/2` here once its own clauses have had their turn.
  """
  @spec handle_tap(atom(), term()) :: {:noreply, term()}
  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "view_" <> label ->
        case screen(label) do
          nil -> {:noreply, socket}
          module -> {:noreply, Mob.Socket.push_screen(socket, module, carried(socket))}
        end

      _other ->
        {:noreply, socket}
    end
  end
end
