defmodule Kati.Screens.AddByHand do
  @moduledoc """
  Screen 154 — Add by hand. The form behind screen 89's *Can't find it?* row.

  Built to `test/design/screens/154.html`. Its own caption is the argument for
  building it before anything else on the board list: *until the catalogue
  lands, everything a search finds is invented — so this form is the only path
  from a fresh install to a library with anything in it.*

  Screen 89 has drawn that row since it was written and rendered it with **no
  `on_tap` at all**, because nothing existed to open. `Kati.Screens.AddTitle`'s
  moduledoc has carried the apology for a while; this is the destination.

  ## What it writes

  A `Kati.Media.TrackedTitle` with `source: :manual` and the typed title as its
  `source_id`, which is the shape `Kati.Screens.AddTitle.track/2` already
  writes for a row nobody could find. No `CachedTitle` is invented alongside
  it: a hand-typed title has no poster and no episode list, and the board says
  so in as many words rather than drawing a placeholder that implies one is
  coming.

  ## The two optional fields, and why the board marks them

  **Year** narrows nothing today. It is on the board because a person typing a
  title they could not find usually knows the year, and losing it would mean
  asking again when the catalogue arrives.

  **Total episodes** is the one that changes what the app can draw. Without it
  a series still tracks and its progress bar has no denominator — which
  `Kati.Screens.Library.fraction/1` already handles honestly by drawing an
  empty track rather than inventing a percentage. The board's own note says
  exactly that, so the field is an offer rather than a requirement.

  ## The refusal

  Save with no title refuses in words and writes nothing, which is
  `Kati.Write`'s contract and what `Kati.WriteContractTest` enforces on the
  host. Board 155 draws that state.
  """
  use Kati.Screens.Pushed, back: "Add title"

  alias Kati.Components.MishkaChip
  alias Kati.Theme.Palette
  alias Kati.UI.SettingsList

  @kinds [{"Film", :movie, "movie"}, {"Series", :tv, "live_tv"}]
  @statuses ["Not started", "Watching", "Finished"]

  @impl true
  def load(socket) do
    Mob.Socket.assign(socket,
      title: "",
      kind: :tv,
      year: "",
      status: "Not started",
      episodes: "",
      save_error: nil
    )
  end

  @doc false
  def content(assigns) do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.AddByHand.heading()}
      {Kati.Screens.AddByHand.labelled("Title", Kati.Screens.AddByHand.field(:title, assigns.title, "The Long Hollow"))}
      {Kati.Screens.AddByHand.labelled("Kind", Kati.Screens.AddByHand.kinds(assigns.kind))}
      {Kati.Screens.AddByHand.labelled("Year", Kati.Screens.AddByHand.field(:year, assigns.year, "2024"), "optional")}
      {Kati.Screens.AddByHand.labelled("Status", Kati.Screens.AddByHand.statuses(assigns.status))}
      {Kati.Screens.AddByHand.episodes(assigns)}
      {Kati.Screens.AddByHand.error(assigns.save_error)}
      {Kati.UI.Sheet.commit("Add to library", :add)}
      <Spacer size={14} />
      {Kati.Screens.AddByHand.split_note("A hand-typed title carries", "no poster and no episode list", ". If Kati finds it later both arrive, and nothing you typed is overwritten.")}
    </Column>
    """
  end

  @doc false
  def heading do
    ~MOB"""
    <Column fill_width={true}>
      <Text
        text="Add by hand"
        text_size={28}
        max_font_scale={1.6}
        font_weight="bold"
        letter_spacing={-0.03}
        text_color={:on_surface}
      />
      <Spacer size={7} />
      <Text
        text="For something Kati could not find. The title is the only thing it needs."
        text_size={13}
        line_height={1.55}
        text_color={Palette.sub()}
      />
      <Spacer size={20} />
    </Column>
    """
  end

  @doc "A field under its own label, with the board's `optional` marker when it has one."
  @spec labelled(String.t(), map(), String.t() | nil) :: map()
  def labelled(label, body, marker \\ nil) do
    assigns = %{label: label, body: body, marker: marker}

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Text
          text={@label}
          font_family="mono"
          text_size={10.5}
          letter_spacing={0.16}
          text_color={Palette.muted()}
          max_lines={1}
        />
        <Spacer weight={1.0} />
        {Kati.Screens.AddByHand.marker(@marker)}
      </Row>
      <Spacer size={8} />
      {@body}
      <Spacer size={18} />
    </Column>
    """
  end

  @doc false
  def marker(nil), do: ~MOB"<Spacer size={0} />"

  def marker(text) do
    assigns = %{text: text}

    ~MOB"""
    <Text text={@text} text_size={11.5} text_color={Palette.tertiary()} max_lines={1} />
    """
  end

  @doc false
  def field(tag, value, placeholder) do
    assigns = %{value: value, placeholder: placeholder, on_change: {self(), tag}, id: Atom.to_string(tag)}

    ~MOB"""
    <Row
      fill_width={true}
      height={48}
      corner_radius={14}
      background={Palette.card()}
      shadow={Kati.Theme.shadow_card_soft()}
      padding_left={15}
      padding_right={15}
      align="center"
    >
      <TextField
        value={@value}
        placeholder={@placeholder}
        return_key="done"
        weight={1.0}
        accessibility_id={@id}
        on_change={@on_change}
      />
    </Row>
    """
  end

  @doc "The two kinds, and the three statuses. Functions and not module attributes: inside `~MOB` an `@name` is an ASSIGN, which is the trap this file hit first."
  @spec kind_list() :: [{String.t(), atom(), String.t()}]
  def kind_list, do: @kinds

  @doc false
  @spec status_list() :: [String.t()]
  def status_list, do: @statuses

  @doc false
  def kinds(active) do
    ~MOB"""
    <Row fill_width={true} align="center">
      {Enum.map(Kati.Screens.AddByHand.kind_list(), fn {label, kind, icon} ->
        Kati.Screens.AddByHand.kind_chip(label, icon, kind == active)
      end)
      |> Enum.intersperse(Kati.Screens.AddByHand.gap())}
    </Row>
    """
  end

  @doc false
  def kind_chip(label, icon, on?) do
    assigns = %{label: label, icon: icon, on?: on?, tap: {self(), String.to_atom("kind_" <> label)}}

    ~MOB"""
    <Row
      height={38}
      corner_radius={19}
      background={if @on?, do: Palette.ink_fill(), else: Palette.card()}
      padding_left={14}
      padding_right={16}
      align="center"
      on_tap={@tap}
    >
      {Kati.UI.symbol(@icon, size: 17, color: if(@on?, do: Palette.on_ink(), else: Palette.ink_soft()))}
      <Spacer size={7} />
      <Text
        text={@label}
        text_size={12.5}
        font_weight="semibold"
        text_color={if @on?, do: Palette.on_ink(), else: Palette.ink_soft()}
        max_lines={1}
      />
    </Row>
    """
  end

  @doc false
  def statuses(active) do
    ~MOB"""
    <Row fill_width={true} align="center">
      {Enum.map(Kati.Screens.AddByHand.status_list(), fn label -> Kati.Screens.AddByHand.status_chip(label, label == active) end)
       |> Enum.intersperse(Kati.Screens.AddByHand.gap())}
    </Row>
    """
  end

  @doc false
  def status_chip(label, on?) do
    MishkaChip.chip(
      label: label,
      checked: on?,
      on_toggle: String.to_atom("status_" <> label),
      height: 32,
      padding_x: 15,
      padding_y: 0,
      corner_radius: 16,
      text_size: 12.5,
      font_weight: :semibold,
      max_lines: 1,
      color: Palette.ink_fill(),
      text_color: Palette.on_ink(),
      unchecked_color: Palette.card(),
      unchecked_text_color: Palette.ink_soft()
    )
  end

  @doc false
  def gap, do: ~MOB"<Spacer size={7} />"

  @doc """
  The episode field, and only for a series.

  A film has no episode total, so drawing the field for one would be asking a
  question with no answer. The board draws it under Series and the note under
  it says what leaving it empty costs.
  """
  @spec episodes(map()) :: map()
  def episodes(%{kind: :movie}), do: ~MOB"<Spacer size={0} />"

  def episodes(assigns) do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.AddByHand.labelled("Total episodes", Kati.Screens.AddByHand.field(:episodes, assigns.episodes, "7"), "optional")}
      {Kati.Screens.AddByHand.split_note("Without it a series still tracks, but its progress bar has", "no denominator", "— which the app already draws honestly.")}
      <Spacer size={18} />
    </Column>
    """
  end

  @doc """
  A note whose middle clause is the one that matters.

  Three `<Text>` nodes and not one sentence, because the board draws it that
  way — the emphasis falls on *no denominator* and *no poster and no episode
  list*, and `Kati.ScreenDesignLiteralTest` compares a drawing's lines against
  the tree's, so a single joined string is a different shape from the drawn
  one even when it reads the same.
  """
  @spec split_note(String.t(), String.t(), String.t()) :: map()
  def split_note(lead, emphasis, tail) do
    assigns = %{lead: lead, emphasis: emphasis, tail: tail}

    ~MOB"""
    <Row
      fill_width={true}
      background={Palette.cream()}
      corner_radius={16}
      padding={13}
      align="top"
    >
      {Kati.UI.symbol("info", size: 16, color: Palette.bronze())}
      <Spacer size={9} />
      <Column weight={1.0}>
        <Text text={@lead} text_size={12} line_height={1.5} text_color={Palette.ink_soft()} />
        <Text
          text={@emphasis}
          text_size={12}
          line_height={1.5}
          font_weight="semibold"
          text_color={Palette.ink()}
        />
        <Text text={@tail} text_size={12} line_height={1.5} text_color={Palette.ink_soft()} />
      </Column>
    </Row>
    """
  end

  @doc false
  def error(nil), do: ~MOB"<Spacer size={0} />"

  def error(message) do
    assigns = %{message: message}

    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.note("error", @message)}
      <Spacer size={14} />
    </Column>
    """
  end

  @impl true
  def handle_tap(:add, socket), do: {:noreply, Kati.Screens.AddByHand.save(socket)}

  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "kind_Film" -> {:noreply, Mob.Socket.assign(socket, :kind, :movie)}
      "kind_Series" -> {:noreply, Mob.Socket.assign(socket, :kind, :tv)}
      "status_" <> label -> {:noreply, Mob.Socket.assign(socket, :status, label)}
      _other -> {:noreply, socket}
    end
  end

  @doc """
  Write the row, or say why not.

  `source: :manual` and the title as `source_id`, which is what
  `Kati.Screens.AddTitle.track/2` writes for a title nobody could find — one
  shape for a hand-typed row, not two.
  """
  @spec save(Mob.Socket.t()) :: Mob.Socket.t()
  def save(socket) do
    title = String.trim(socket.assigns.title)

    if title == "" do
      Mob.Socket.assign(socket, :save_error, "A title is the one thing this needs.")
    else
      Kati.Media.TrackedTitle
      |> Ash.Changeset.for_create(:create, %{
        source: :manual,
        source_id: title,
        kind: socket.assigns.kind,
        status: Kati.Screens.AddByHand.status_atom(socket.assigns.status)
      })
      |> Ash.create()
      |> Kati.Write.note("add by hand #{title}")
      |> case do
        {:ok, _row} -> Mob.Socket.pop_screen(socket)
        {:error, _reason} = error -> Mob.Socket.assign(socket, :save_error, Kati.Write.message(error))
      end
    end
  end

  @doc false
  @spec status_atom(String.t()) :: atom()
  def status_atom("Watching"), do: :watching
  def status_atom("Finished"), do: :finished
  def status_atom(_other), do: :not_started
end
