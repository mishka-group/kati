defmodule Kati.Screens.YearShare do
  @moduledoc """
  Screen 98 — Your year, shared, pushed under Your year.

  The share disc on screen 07 finally does something. It has been drawn and
  inert since screen 07 landed, and `Kati.Screens.Stats.share_disc/0`'s own
  comment says why that was the honest state: *a disc that swallowed a tap
  silently would be worse than one that plainly does nothing.* This is what it
  was waiting for.

  ## Nothing about your year is uploaded to make a card

  The `info` row says it and the parenthetical is the proof rather than the
  reassurance: **Kati has no server that could receive it.** Every card is
  composed on the device, which is not a policy the app is keeping — it is the
  only thing the architecture permits.

  ## Only the field card carries the wordmark

  The design's caption: *it is the one people ask about, so it is the one that
  answers.* A wordmark on four cards is branding; a wordmark on the one card
  that provokes the question is an answer.

  ## `Share…` is drawn and not built

  `WHEN FILE SHARING LANDS` sits under it, in the same idiom screen 119 uses
  for its two unbuilt nutrition paths. Kati has no share-sheet fence — nothing
  in `native/LEDGER.md` hands a file to the platform — so the control says what
  it is waiting for rather than failing quietly.
  """

  use Kati.Screens.Pushed, back: "Stats"

  alias Kati.Stats.ShareSample
  alias Kati.Theme.Palette
  alias Kati.UI
  alias Kati.UI.SettingsList

  @aspects [{"Square", :aspect_square}, {"Story", :aspect_story}]

  def load(socket) do
    socket
    |> Mob.Socket.assign(:scope, "All")
    |> Mob.Socket.assign(:aspect, :aspect_square)
    |> Mob.Socket.assign(:hide_private, false)
  end

  @doc false
  def content(assigns) do
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
        {SettingsList.title("Your year, shared", ShareSample.subtitle())}
        {Kati.Screens.YearShare.scopes(assigns.scope)}
        {Kati.Screens.YearShare.card(assigns.aspect)}
        {UI.eyebrow("Aspect")}
        {Kati.UI.Segmented.plain(Kati.Screens.YearShare.aspects(), assigns.aspect)}
        <Spacer size={16} />
        {Kati.Screens.YearShare.privacy_row(assigns.hide_private)}
        <Spacer size={16} />
        {Kati.Screens.YearShare.actions()}
        <Spacer size={16} />
        {Kati.Screens.YearShare.no_server_note()}
      </Column>
    </Scroll>
    """
  end

  @doc false
  def aspects, do: @aspects

  @doc "The scope chips: which part of the year the card is about."
  @spec scopes(String.t()) :: map()
  def scopes(active) do
    chips =
      ShareSample.scopes()
      |> Enum.map(fn scope ->
        UI.chip(scope, selected: scope == active, on_toggle: String.to_atom("scope_" <> scope))
      end)
      |> Enum.intersperse(~MOB"<Spacer size={7} />")

    ~MOB"""
    <Column fill_width={true}>
      <Scroll axis="horizontal">
        <Row>
          {chips}
        </Row>
      </Scroll>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc """
  The card preview: the hours face and the titles face, as they will be saved.

  Drawn on paper rather than on card, because the image's own ground is paper —
  a preview that sat on a different colour from the file would be a preview of
  something else.
  """
  @spec card() :: map()
  def card, do: card(:aspect_square)

  @doc """
  The preview at one of the two ratios — screen 100's `scale`, on this page.

  The Aspect segments used to set `:aspect` and nothing read it, so the preview
  the caption calls *as they will be saved* was one ratio whichever segment was
  lit. `scale/1` reads `Kati.Screens.YearCards`'s own two numbers — 1.0 and
  1.25 — rather than starting a second table: a Story preview that re-scaled by
  a different number from the file Story is cut at would be a preview of
  something else.

  `sized/2` returns the size UNCHANGED at 1.0 rather than multiplying by it.
  `10 * 1.0` is `10.0` where the drawing's tree carries `10`, and the square
  ratio is what every capture, every sweep and the gallery render.
  """
  @spec card(atom()) :: map()
  def card(aspect) do
    hours = ShareSample.hours()
    scale = scale(aspect)

    assigns = %{
      hours: hours,
      label_size: sized(10, scale),
      figure_size: sized(34, scale),
      titles_size: sized(10, scale)
    }

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        padding={19}
        shadow={Kati.Theme.shadow_card()}
      >
        <Text
          text={String.upcase(@hours.label)}
          font_family="mono"
          text_size={@label_size}
          letter_spacing={0.14}
          text_color={Palette.muted()}
        />
        <Spacer size={9} />
        <Row fill_width={true} align="bottom">
          <Text
            text={@hours.figure}
            text_size={@figure_size}
            font_weight="extrabold"
            letter_spacing={-0.035}
            text_color={:on_surface}
          />
          <Spacer size={10} />
          {Kati.UI.symbol("arrow_drop_up", size: 20, color: Palette.green_text())}
          <Text
            text={@hours.change}
            font_family="mono"
            text_size={13}
            text_color={Palette.green_text()}
          />
          <Spacer weight={1.0} />
          <Text text={@hours.year} font_family="mono" text_size={12} text_color={Palette.muted()} />
        </Row>
        <Spacer size={20} />
        <Text
          text="Top titles"
          font_family="mono"
          text_size={@titles_size}
          letter_spacing={0.14}
          text_color={Palette.muted()}
        />
        <Spacer size={11} />
        {Kati.Screens.YearShare.posters()}
        <Spacer size={13} />
        {Kati.Screens.YearShare.ranks()}
      </Column>
      <Spacer size={22} />
    </Column>
    """
  end

  # The two ratios, and the number each multiplies the type by — the same table
  # `Kati.Screens.YearCards` cuts the files at (`@ratios`, year_cards.ex:45),
  # read here rather than copied as sizes. An aspect this page does not draw
  # takes the square, so a stale tag cannot silently re-scale the preview.
  defp scale(:aspect_story), do: 1.25
  defp scale(_square), do: 1.0

  # Identity at 1.0, deliberately. `10 * 1.0` is `10.0` and the drawing's tree
  # carries `10`; the square is the ratio every capture was taken at, so it has
  # to come out of here untouched rather than merely equal.
  defp sized(size, 1.0), do: size
  defp sized(size, scale), do: size * scale

  @doc false
  def posters do
    tiles =
      ShareSample.top_titles()
      |> Enum.map(&Kati.Screens.YearShare.poster/1)
      |> Enum.intersperse(~MOB"<Spacer size={9} />")

    ~MOB"""
    <Row fill_width={true} align="top">
      {tiles}
    </Row>
    """
  end

  @doc false
  def poster(title) do
    case Kati.Design.Images.poster(title.seed) do
      nil ->
        ~MOB"""
        <Column weight={1.0}>
          <Box fill_width={true} height={92} corner_radius={8} background={Palette.placeholder()} />
        </Column>
        """

      src ->
        ~MOB"""
        <Column weight={1.0}>
          <Image src={src} fill_width={true} height={92} corner_radius={8} content_mode="fill" />
        </Column>
        """
    end
  end

  @doc false
  def ranks do
    rows =
      ShareSample.top_titles()
      |> Enum.map(&Kati.Screens.YearShare.rank_row/1)
      |> Enum.intersperse(~MOB"<Spacer size={7} />")

    ~MOB"""
    <Column fill_width={true}>
      {rows}
    </Column>
    """
  end

  @doc false
  def rank_row(title) do
    assigns = %{rank: title.rank, title: title.title}

    ~MOB"""
    <Row fill_width={true} align="center">
      <Text
        text={@rank}
        font_family="mono"
        text_size={11}
        text_color={Palette.tertiary()}
        width={16}
      />
      <Spacer size={9} />
      <Text
        text={@title}
        text_size={12.5}
        font_weight="semibold"
        text_color={:on_surface}
        max_lines={1}
      />
      <Spacer weight={1.0} />
    </Row>
    """
  end

  @doc """
  The one privacy control on the page.

  A switch rather than a chip, because it is not a scope — it changes what is
  *in* the card rather than what the card is about, and a control that looked
  like the six above it would be read as a seventh scope.
  """
  @spec privacy_row(boolean()) :: map()
  def privacy_row(on?) do
    SettingsList.card([
      SettingsList.row(
        SettingsList.icon_tile("visibility_off"),
        SettingsList.body("Hide titles I marked private", nil),
        SettingsList.trailing(SettingsList.switch(on?)),
        on_tap: {self(), :toggle_private}
      )
    ])
  end

  @doc """
  Save, and the share that is waiting on a fence.

  `Save image` takes the ink because it is the one that works. `Share…` carries
  `WHEN FILE SHARING LANDS` in the same idiom screen 119's unbuilt nutrition
  paths use, so *designed, not built* looks the same wherever it appears.
  """
  @spec actions() :: map()
  def actions do
    ~MOB"""
    <Column fill_width={true}>
      <Row
        fill_width={true}
        height={52}
        corner_radius={26}
        background={Palette.ink_fill()}
        align="center"
        on_tap={{self(), :save_image}}
      >
        <Spacer weight={1.0} />
        <Text
          text="Save image"
          text_size={15}
          font_weight="bold"
          letter_spacing={-0.01}
          text_color={Palette.on_ink()}
        />
        <Spacer weight={1.0} />
      </Row>
      <Spacer size={11} />
      <Row fill_width={true} align="center">
        <Spacer weight={1.0} />
        <Text text="Share…" text_size={13.5} font_weight="semibold" text_color={Palette.ink_soft()} />
        <Spacer size={9} />
        <Row
          height={22}
          corner_radius={11}
          background={Palette.track()}
          padding_left={9}
          padding_right={9}
          align="center"
        >
          <Text
            text="WHEN FILE SHARING LANDS"
            font_family="mono"
            text_size={9}
            letter_spacing={0.1}
            text_color={Palette.sub()}
            max_lines={1}
          />
        </Row>
        <Spacer weight={1.0} />
      </Row>
    </Column>
    """
  end

  @doc "The sentence whose parenthetical is the proof, not the reassurance."
  @spec no_server_note() :: map()
  def no_server_note do
    SettingsList.note(
      "info",
      "Every card is drawn on this device. Nothing about your year is uploaded to make " <>
        "it — Kati has no server that could receive it."
    )
  end

  @doc false
  def handle_tap(:toggle_private, socket),
    do: {:noreply, Mob.Socket.assign(socket, :hide_private, not socket.assigns.hide_private)}

  def handle_tap(aspect, socket) when aspect in [:aspect_square, :aspect_story],
    do: {:noreply, Mob.Socket.assign(socket, :aspect, aspect)}

  def handle_tap(:save_image, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.YearCards)}

  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "scope_" <> scope -> {:noreply, Mob.Socket.assign(socket, :scope, scope)}
      _other -> {:noreply, socket}
    end
  end
end
