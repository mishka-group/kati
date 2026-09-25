defmodule Kati.Screens.NumberingScheme do
  @moduledoc """
  Screen 153 — how one show's episodes are numbered, and why.

  Pushed from the help disc beside screen 34's order strip, with the show it
  was opened for in `:title_id` (`params_for/1`). Everything on the page is
  that show's:

    * **The scheme and its reason.** `Kati.Media.Numbering.effective/1` over
      the tracked row. With nothing stored the row is *Inherited* and says why
      — *because this is anime*, or *because this is not anime*, which is
      `Kati.Media.Numbering.default/1`'s whole rule. With
      `Kati.Media.TrackedTitle.numbering` set it is *Overridden* and says *you
      set this*, naming the default it replaced. Nothing claims an override the
      column does not hold.
    * **Override and Reset.** The row's pill. *Override* stores the scheme the
      default is not; *Reset* clears the column. Both write through
      `Kati.Media.Numbering` and the page re-reads the row, so what it shows
      is what was saved. Screen 34 re-reads on the way back.
    * **What it changes.** One of this show's own episodes, numbered both ways
      — its absolute number beside its season and episode. The first episode
      whose two numbers differ is the one shown, because that is the case the
      comparison is about. A show with no episode that has an absolute number
      (`Kati.Media.Numbering.absolute_numbers/1`) draws no comparison at all.

  The scheme words are screen 34's tile words (`Kati.Screens.Season.
  order_title/1`), so the page and the strip it explains cannot call one
  choice two things.

  Opened without a show — or for one that is no longer in the library — the
  page says so and offers nothing to press.

  Board 153 also drew a MyAnimeList import tile (*animelist.xml*, scores and
  watched counts coming across). Kati's importer reads CSV only and maps none
  of those fields from a MyAnimeList export, so the tile described an
  integration that does not exist and is not drawn.

  No dock — this is a pushed screen — so the frame closes at 40, not 132.

  ## The mono slots ask the string

  `kicker/1` and `comparison_column/1` set their text with
  `Kati.Locale.mono_face/1` rather than `"mono"`: `kati_mono.ttf` carries no
  Persian glyph, so a label or a number in Persian digits is handed to
  Vazirmatn, and an ASCII one keeps DM Mono.

  ## The vertical rule in the comparison card is a declared height

  The drawing gets the rule's height from `align-items: stretch`, which has no
  Mob prop, and an unsized `Box` measures zero. The two columns — a 9.5pt
  kicker, a 7pt gap, a 17pt value — are declared at 40 for that reason.
  """
  use Kati.Screens.Pushed, back: "Series"
  use Gettext, backend: Kati.Gettext

  alias Kati.Media.CachedEpisode
  alias Kati.Media.Numbering
  alias Kati.Media.TrackedTitle
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  @doc """
  The push that opens this page for one show, from screen 34.

      iex> Kati.Screens.NumberingScheme.params_for("t1")
      %{back: "Episodes", title_id: "t1"}

      iex> Kati.Screens.NumberingScheme.params_for(nil)
      %{back: "Episodes"}
  """
  @spec params_for(String.t() | nil) :: map()
  def params_for(id) when is_binary(id), do: %{back: "Episodes", title_id: id}
  def params_for(_none), do: %{back: "Episodes"}

  @impl true
  def load(socket) do
    socket
    |> Mob.Socket.assign(:numbering, numbering(socket.assigns.params))
    |> Mob.Socket.assign(:save_error, nil)
  end

  @doc """
  The page's facts for the show `params` names, or `nil` when it names none
  that is tracked.
  """
  @spec numbering(map() | nil) :: map() | nil
  def numbering(params) do
    with id when is_binary(id) <- params && Map.get(params, :title_id),
         {:ok, %TrackedTitle{} = tracked} <- Ash.get(TrackedTitle, id) do
      facts(tracked)
    else
      _none -> nil
    end
  rescue
    _error -> nil
  end

  @doc "What the page draws about one tracked show."
  @spec facts(TrackedTitle.t()) :: map()
  def facts(%TrackedTitle{} = tracked) do
    cached = Kati.Media.Release.cached_for(tracked)

    %{
      tracked_id: tracked.id,
      name: (cached && cached.title) || gettext("Untitled"),
      scheme: Numbering.effective(tracked),
      default: Numbering.default(tracked),
      chosen?: Numbering.chosen?(tracked),
      anime?: Numbering.anime?(tracked),
      example: example(tracked)
    }
  end

  @doc """
  One of the show's episodes numbered both ways, or `nil`.

  The first in aired order whose absolute number differs from its number in
  the season, and failing that the first with an absolute number at all.
  """
  @spec example(TrackedTitle.t()) :: map() | nil
  def example(%TrackedTitle{} = tracked) do
    episodes = CachedEpisode.for_title(tracked.source, tracked.source_id)
    absolute = Numbering.absolute_numbers(episodes)

    placed =
      episodes
      |> CachedEpisode.in_order(:aired)
      |> Enum.filter(
        &(Map.has_key?(absolute, &1.source_id) and is_integer(&1.season_number) and
            is_integer(&1.episode_number))
      )

    case Enum.find(placed, &(Map.fetch!(absolute, &1.source_id) != &1.episode_number)) ||
           List.first(placed) do
      nil ->
        nil

      episode ->
        %{
          absolute: Map.fetch!(absolute, episode.source_id),
          season: episode.season_number,
          episode: episode.episode_number
        }
    end
  rescue
    _error -> nil
  end

  @impl true
  def handle_tap(:override_numbering, socket),
    do: {:noreply, write(socket, &Numbering.choose(&1, Numbering.other(Numbering.default(&1))))}

  def handle_tap(:reset_numbering, socket),
    do: {:noreply, write(socket, &Numbering.reset/1)}

  @doc """
  Apply one write to the show on the page, then re-read it.

  The row is the one the page drew — its `:tracked_id` — and a page drawing
  no show writes nothing.
  """
  @spec write(Mob.Socket.t(), (TrackedTitle.t() -> {:ok, term()} | {:error, term()})) ::
          Mob.Socket.t()
  def write(socket, change) do
    with %{tracked_id: id} <- socket.assigns.numbering,
         {:ok, tracked} <- Ash.get(TrackedTitle, id),
         {:ok, saved} <- change.(tracked) do
      socket
      |> Mob.Socket.assign(:numbering, facts(saved))
      |> Mob.Socket.assign(:save_error, nil)
    else
      nil ->
        socket

      {:error, reason} ->
        Mob.Socket.assign(socket, :save_error, Kati.Write.message({:error, reason}))
    end
  end

  @doc false
  def content(%{numbering: nil}) do
    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {SettingsList.chrome(nil, 44)}
        {SettingsList.title(Kati.Screens.NumberingScheme.heading(), "")}
        {SettingsList.note("info", Kati.Screens.NumberingScheme.no_show_note())}
      </Column>
    </Scroll>
    """
  end

  def content(assigns) do
    n = assigns.numbering

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {SettingsList.chrome(nil, 44)}
        {SettingsList.title(Kati.Screens.NumberingScheme.heading(), n.name)}
        {UI.eyebrow(Kati.Screens.NumberingScheme.state_eyebrow(n.chosen?))}
        {Kati.Screens.NumberingScheme.tile_card(n)}
        {Kati.Screens.NumberingScheme.refusal(Map.get(assigns, :save_error))}
        <Spacer size={11} />
        {SettingsList.note("info", Kati.Screens.NumberingScheme.rule_note())}
        {Kati.Screens.NumberingScheme.comparison(n)}
      </Column>
    </Scroll>
    """
  end

  @doc false
  def heading, do: pgettext("the screen that explains episode numbering", "Numbering")

  @doc false
  def no_show_note,
    do:
      gettext(
        "Open this from a show's episode list to see how that show is numbered " <>
          "and change it."
      )

  @doc false
  def rule_note,
    do:
      gettext(
        "Anime is numbered absolutely unless you change it, and everything else " <>
          "by season. A choice here applies to this show only."
      )

  @doc false
  def state_eyebrow(true), do: pgettext("a setting the reader changed", "Overridden")
  def state_eyebrow(false), do: pgettext("a setting nobody has changed", "Inherited")

  @doc """
  A scheme's name, in screen 34's words: *Aired* for seasons, *Absolute*.
  """
  @spec scheme_name(Numbering.scheme()) :: String.t()
  def scheme_name(scheme) do
    scheme
    |> Numbering.order()
    |> Kati.Screens.Season.order_label()
    |> Kati.Screens.Season.order_title()
  end

  @doc """
  Why the show is numbered the way it is.

      iex> Kati.Screens.NumberingScheme.reason(%{chosen?: false, anime?: true, default: :absolute})
      "because this is anime"

      iex> Kati.Screens.NumberingScheme.reason(%{chosen?: false, anime?: false, default: :seasons})
      "because this is not anime"
  """
  @spec reason(map()) :: String.t()
  def reason(%{chosen?: false, anime?: true}), do: gettext("because this is anime")
  def reason(%{chosen?: false, anime?: false}), do: gettext("because this is not anime")

  def reason(%{chosen?: true, anime?: true, default: default}),
    do: gettext("you set this · anime default was %{default}", default: scheme_name(default))

  def reason(%{chosen?: true, default: default}),
    do: gettext("you set this · the default here is %{default}", default: scheme_name(default))

  @doc "The show's scheme, its reason, and the pill that changes it."
  def tile_card(n) do
    {label, tag} =
      if n.chosen?,
        do:
          {pgettext("the pill that reverts an override to the inherited default", "Reset"),
           :reset_numbering},
        else:
          {pgettext("the pill that replaces an inherited default", "Override"),
           :override_numbering}

    SettingsList.card([
      SettingsList.row(
        SettingsList.icon_tile("pin"),
        SettingsList.body(scheme_name(n.scheme), reason(n), lines: 2),
        SettingsList.action_pill(label, {self(), tag}),
        padding: 13,
        rule: false
      )
    ])
  end

  @doc "A write the store refused, said under the row it failed to change."
  def refusal(nil), do: ~MOB"<Spacer size={0} />"

  def refusal(message) do
    assigns = %{message: message}

    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={11} />
      {Kati.UI.SettingsList.note("error", @message)}
    </Column>
    """
  end

  @doc """
  The comparison band — eyebrow, card — or nothing when no episode of the show
  has an absolute number.
  """
  def comparison(%{example: nil}), do: ~MOB"<Spacer size={0} />"

  def comparison(%{example: example}) do
    assigns = %{card: Kati.Screens.NumberingScheme.comparison_card(example)}

    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={20} />
      {UI.eyebrow(pgettext("what switching numbering affects", "What it changes"))}
      {@card}
    </Column>
    """
  end

  @doc """
  One episode, absolute beside season and episode, over one footnote.

  Not `SettingsList.card/1` — that recipe is 20pt radius over 4/15pt padding
  for a stack of rows, and this is a 22pt radius over 17pt padding holding a
  two-column comparison.
  """
  def comparison_card(example) do
    left = %{
      label: scheme_name(:absolute),
      value: pgettext("episode number", "E%{e}", e: Kati.Locale.number(example.absolute))
    }

    right = %{
      label: scheme_name(:seasons),
      value:
        gettext("S%{s} · E%{e}",
          s: Kati.Locale.number(example.season),
          e: Kati.Locale.number(example.episode)
        )
    }

    assigns = %{
      left: left,
      right: right,
      note:
        gettext(
          "Same episode. Numbering changes only what is displayed — Kati always " <>
            "stores season and episode, so switching never loses a tick and never " <>
            "shows both at once."
        )
    }

    ~MOB"""
    <Column
      fill_width={true}
      background={Kati.Theme.card(Palette.mode())}
      corner_radius={22}
      shadow={Kati.Theme.shadow_card_soft()}
      padding={17}
    >
      <Row fill_width={true} align="top">
        {Kati.Screens.NumberingScheme.comparison_column(@left)}
        <Spacer size={12} />
        <Box width={1} height={40} background={Palette.hairline_strong()} />
        <Spacer size={12} />
        {Kati.Screens.NumberingScheme.comparison_column(@right)}
      </Row>
      <Spacer size={13} />
      {SettingsList.hairline(true)}
      <Spacer size={13} />
      <Text
        text={@note}
        text_size={12.5}
        line_height={Kati.Locale.leading(1.65)}
        text_color={Palette.ink_soft()}
      />
    </Column>
    """
  end

  @doc false
  def comparison_column(%{label: label, value: value}) do
    ~MOB"""
    <Column weight={1.0}>
      {Kati.Screens.NumberingScheme.kicker(label)}
      <Spacer size={7} />
      <Text
        text={value}
        font_family={Kati.Locale.mono_face(value)}
        text_size={17}
        text_color={Palette.ink()}
        max_lines={1}
      />
    </Column>
    """
  end

  @doc """
  The 9.5pt uppercase label over each comparison value: `Kati.UI.eyebrow/2`'s
  inner recipe one size down, with its Persian adjustments — no upcasing,
  no tracking, half a point larger.
  """
  def kicker(text) do
    ~MOB"""
    <Text
      text={Kati.UI.eyebrow_label(text)}
      font_family={Kati.Locale.mono_face(text)}
      text_size={Kati.Locale.pick(9.5, 10)}
      font_weight={Kati.Locale.pick("normal", "semibold")}
      letter_spacing={Kati.Locale.tracking(0.1)}
      text_color={Palette.tertiary()}
      max_lines={1}
    />
    """
  end
end
