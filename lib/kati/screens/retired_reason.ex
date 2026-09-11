defmodule Kati.Screens.RetiredReason do
  @moduledoc """
  Why a thing Kati draws is not a thing Kati does — screen **114**.

  Three surfaces have drawn *tap to see why* with nothing behind it since they
  were written: screen 42's two dashed tiles, board 320's retired Hardcover row,
  and the three importers `Kati.Sources.refused/0` names.
  `Kati.Screens.HealthEmptyStates` records the gap in its own moduledoc — *"there
  is no module for it yet, so both lines are drawn and neither is wired"* — and
  this is that module.

  ## What it owes, and what it must not say

  Board 114's rule, restated by 320: **what it is, why not here, and no date.**
  The third is the load-bearing one. A date is a promise; a screen that says
  *coming soon* has made one on behalf of somebody who did not, and every reader
  who comes back to check is owed an apology the app cannot give. So there is no
  `:when` anywhere in `Kati.Retired` and no room on this page for one.

  ## Why one screen and not three

  The reason is the same shape whatever it is about, and three pages saying it
  three ways is how the wording drifts. `Kati.Retired` holds the entries and
  this holds the frame; the callers pass an id.
  """
  use Kati.Screens.Pushed, back: "Back"
  use Gettext, backend: Kati.Gettext

  alias Kati.Theme.Palette

  @impl true
  def load(socket) do
    params = socket.assigns.params || %{}

    Mob.Socket.assign(socket, :entry, Kati.Retired.find(Map.get(params, :id)))
  end

  @doc false
  def content(assigns) do
    inner = %{body: Kati.Screens.RetiredReason.body(assigns.entry)}
    assigns = inner

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {Kati.UI.SettingsList.chrome(nil, 44)}
        {@body}
      </Column>
    </Scroll>
    """
  end

  @doc """
  The reason, or the page for a push that named nothing.

  A bare push does NOT pick the first entry. `Kati.ScreenWriteTargetTest`'s rule
  applies even to a page that only reads: a screen which picks its own subject
  is a screen explaining something the reader did not ask about.
  """
  @spec body(map() | nil) :: term()
  def body(nil) do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.title(gettext("Not in this version"), gettext("Nothing named"), nil, :name)}
      {Kati.UI.SettingsList.note(
        "info",
        gettext("Open this from the thing you were asking about and Kati says why that one is not here.")
      )}
    </Column>
    """
  end

  def body(entry) do
    assigns = %{
      icon: entry.icon,
      name: entry.name,
      what: entry.what,
      why: entry.why
    }

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Box width={44} height={44} corner_radius={14} background={Palette.paper()} align="center">
          {Kati.UI.symbol(@icon, size: 21, color: Kati.Theme.Palette.rail_idle())}
        </Box>
        <Spacer size={13} />
        <Column weight={1.0}>
          <Text
            text={@name}
            text_size={22}
            max_font_scale={1.6}
            font_weight="bold"
            letter_spacing={Kati.Locale.tracking(-0.02)}
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={4} />
          <Text
            text={Kati.UI.eyebrow_label(gettext("Not in v1"))}
            font_family={Kati.Locale.mono_face()}
            text_size={10}
            letter_spacing={Kati.Locale.tracking(0.14)}
            text_color={Palette.muted()}
            max_lines={1}
          />
        </Column>
      </Row>
      <Spacer size={22} />
      {Kati.Screens.RetiredReason.clause(gettext("What it would be"), @what)}
      <Spacer size={14} />
      {Kati.Screens.RetiredReason.clause(gettext("Why it is not here"), @why)}
      <Spacer size={16} />
      {Kati.UI.SettingsList.note(
        "schedule",
        gettext("No date, deliberately. Kati would rather say no than make a promise nobody has kept.")
      )}
    </Column>
    """
  end

  @doc false
  def clause(label, body) do
    assigns = %{label: label, body: body}

    ~MOB"""
    <Column
      fill_width={true}
      background={Palette.card()}
      corner_radius={20}
      shadow={Kati.Theme.shadow_card_soft()}
      padding={17}
    >
      <Text
        text={Kati.UI.eyebrow_label(@label)}
        font_family={Kati.Locale.mono_face()}
        text_size={10}
        letter_spacing={Kati.Locale.tracking(0.14)}
        text_color={Palette.muted()}
        max_lines={1}
      />
      <Spacer size={9} />
      <Text
        text={@body}
        text_size={13}
        line_height={Kati.Locale.leading(1.6)}
        text_color={Palette.ink_soft()}
      />
    </Column>
    """
  end

  @doc """
  The params a caller threads to this screen.

      iex> Kati.Screens.RetiredReason.params_for(:hardcover)
      %{id: :hardcover}

      iex> Kati.Screens.RetiredReason.params_for(:listenbrainz)
      %{}

  The id and not the name, since mishka-group/kati#103: it took a NAME, and a
  name is a drawn string. `Kati.Retired`'s moduledoc has the argument.
  """
  @spec params_for(atom() | nil) :: map()
  defdelegate params_for(id), to: Kati.Retired
end
