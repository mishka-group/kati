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

  ## Film is the default, and board 154 is not drawn in it

  Board 155 says so in as many words — *"Resting — empty, Film, nothing
  assumed"* — and 154's own caption explains why it shows the other one: it is
  drawn *"with Series chosen so the episode-count field is visible"*. A form
  that assumed Series would be assuming the answer to its own second question.

  So this screen loads as Film and `Kati.ScreenDesignLiteralTest`'s
  `drawn_state/0` puts it in 154's state for the comparison, which is the same
  arrangement screens 01, 02 and 03 use for a board drawn with rows in it.

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

  @kinds [{"Film", :movie, "movie"}, {"Series", :tv, "live_tv"}]
  @statuses ["Not started", "Watching", "Finished"]

  @impl true
  def load(socket) do
    Mob.Socket.assign(socket,
      title: "",
      kind: :movie,
      year: "",
      status: "Not started",
      episodes: "",
      save_error: nil
    )
  end

  @doc false
  def content(assigns) do
    # The board draws its back pill in the flow at 64; the macro floats one
    # at 54, 42 tall, so the content that follows starts at `content_top/0`
    # to clear it. Before this the column had no padding at all and the
    # form ran to the pixel with its heading under the pill.
    Kati.Screens.Pushed.page(~MOB"""
      <Column fill_width={true}>
        {Kati.Screens.AddByHand.heading()}
        {Kati.Screens.AddByHand.labelled("Title", Kati.Screens.AddByHand.field(:title, assigns.title, "e.g. The Long Hollow"))}
        {Kati.Screens.AddByHand.labelled("Kind", Kati.Screens.AddByHand.kinds(assigns.kind))}
        {Kati.Screens.AddByHand.labelled("Year", Kati.Screens.AddByHand.field(:year, assigns.year, "2024"), "optional")}
        {Kati.Screens.AddByHand.labelled("Status", Kati.Screens.AddByHand.statuses(assigns.status))}
        {Kati.Screens.AddByHand.episodes(assigns)}
        {Kati.Screens.AddByHand.error(assigns.save_error)}
        {Kati.UI.Sheet.commit("Add to library", :add)}
        <Spacer size={14} />
        {Kati.Screens.AddByHand.split_note("A hand-typed title carries", "no poster and no episode list", ". If Kati finds it later both arrive, and nothing you typed is overwritten.")}
      </Column>
    """, Kati.Screens.Pushed.content_top())
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

  @doc """
  This form in the reader's own script.

  Screen 89's row pushed the English one whatever the locale was, and
  `Kati.Screens.AddByHandFa` sat on `Kati.AppReachabilityTest`'s inventory with
  exactly that as its reason — the last Persian mirror in the app a person
  could not reach. Both callers go through here now, which is #93's third
  criterion answered for this screen: *Persian screens are reachable after
  onboarding, not only during it.*

  A function rather than an `if` at each call site, for the reason
  `Kati.Onboarding.screen_for_step/2` is one: two call sites deciding the same
  thing separately eventually disagree, and the disagreement shows up as a
  screen in the wrong language rather than as an error.
  """
  @spec for_locale() :: module()
  def for_locale do
    case Kati.Locale.current() do
      :fa -> Kati.Screens.AddByHandFa
      _en -> Kati.Screens.AddByHand
    end
  end

  @doc "A field under its own label, with the board's `optional` marker when it has one."
  @spec labelled(String.t(), map(), String.t() | nil) :: map()
  def labelled(label, body, marker \\ nil, face \\ "mono") do
    # Persian takes Vazirmatn at 11/600 with no tracking, which is
    # `Kati.Screens.Fa.eyebrow/1`'s recipe rather than this one with the family
    # swapped: DM Mono's 10.5 at .16em is a Latin small-caps effect and the
    # Arabic script has neither case nor a tradition of letter-spacing.
    persian? = face == "fa"
    assigns = %{label: label, body: body, marker: marker, face: face, persian?: persian?}

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        <Text
          text={@label}
          font_family={@face}
          text_size={if @persian?, do: 11, else: 10.5}
          font_weight={if @persian?, do: "semibold", else: "normal"}
          letter_spacing={if @persian?, do: 0, else: 0.16}
          text_color={Palette.muted()}
          max_lines={1}
        />
        <Spacer weight={1.0} />
        {Kati.Screens.AddByHand.marker(@marker, @face)}
      </Row>
      <Spacer size={8} />
      {@body}
      <Spacer size={18} />
    </Column>
    """
  end

  @doc false
  def marker(text, face \\ "sans")

  def marker(nil, _face), do: ~MOB"<Spacer size={0} />"

  def marker(text, face) do
    assigns = %{text: text, face: face}

    ~MOB"""
    <Text text={@text} font_family={@face} text_size={11.5} text_color={Palette.tertiary()} max_lines={1} />
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
  def kind_chip(label, icon, on?, face \\ "sans") do
    assigns = %{
      label: label,
      icon: icon,
      on?: on?,
      face: face,
      tap: {self(), String.to_atom("kind_" <> label)}
    }

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
        font_family={@face}
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
  def split_note(lead, emphasis, tail, face \\ "sans") do
    assigns = %{lead: lead, emphasis: emphasis, tail: tail, face: face}

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
        <Text text={@lead} font_family={@face} text_size={12} line_height={1.5} text_color={Palette.ink_soft()} />
        <Text
          text={@emphasis}
          font_family={@face}
          text_size={12}
          line_height={1.5}
          font_weight="semibold"
          text_color={Palette.ink()}
        />
        <Text text={@tail} font_family={@face} text_size={12} line_height={1.5} text_color={Palette.ink_soft()} />
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

  @doc """
  What was typed, in whichever of the three fields.

  Each `<TextField>` carries its own assign name as its change tag, so this is
  one clause rather than three — `field/3` builds the tag from the same atom it
  puts in `accessibility_id`, which is what lets a device test address the field
  it typed into.

  **The catch-all delegates to `super/2`.** `Kati.Screens.Pushed` marks
  `handle_info/2` overridable and defines four clauses on it, one of which
  routes every `{:tap, tag}` to `handle_tap/2`; replacing all four is how screen
  88 went unreachable earlier on this branch. This file was written with no
  change handler at all, so nothing typed ever reached the assign and Add
  refused every time — found by the device test, which is the only thing that
  could have found it.
  """
  @impl true
  def handle_info({:change, field, typed}, socket)
      when field in [:title, :year, :episodes] and is_binary(typed),
      do: {:noreply, Mob.Socket.assign(socket, field, typed)}

  def handle_info(message, socket), do: super(message, socket)

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
