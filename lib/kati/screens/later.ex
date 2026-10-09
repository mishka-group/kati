defmodule Kati.Screens.Later do
  @moduledoc """
  The first frame of a page, before its slow half (#128).

  The slow half itself is `Mob.Socket.start_async/3` and `handle_async/3`
  (Mob 0.9.17), which a page calls directly: the task belongs to the page,
  stops with it, and a crash comes back as `{:exit, reason}` rather than a
  skeleton left up for ever. What lives here is what Mob does not have: the
  skeleton blocks, and `first/3` — for a page whose own `load/1` is the slow
  part and has to run in the page's process.

  `:screens_in_background` switched off (the host tests set it) makes
  `enabled?/0` false, and pages then read everything in `load/1` or `mount/3`
  the old way, so a test that mounts a screen sees it whole.
  """
  import Mob.Sigil

  alias Kati.Theme.Palette

  @doc "Whether pages load their slow half after the first frame."
  @spec enabled?() :: boolean()
  def enabled?, do: Application.get_env(:kati, :screens_in_background, true)

  @doc """
  A page's mount, for a page that opted in with `later: true`
  (`Kati.Screens.Root`, `Kati.Screens.Pushed`): paint skeleton blocks first and
  run the page's own `load/1` straight after, in the page's own process — so
  nothing a `load/1` does with `self()` changes — by sending it
  `{:kati, :load_now, nil}`, which `Kati.Screens.Root.rescue_kati/4` answers.
  Pages that load in a few milliseconds do not opt in: a skeleton for one
  frame is a flicker, not a kindness.
  """
  @spec first(Mob.Socket.t(), boolean(), (Mob.Socket.t() -> Mob.Socket.t())) :: Mob.Socket.t()
  def first(socket, true, load) do
    if enabled?() do
      send(self(), {:kati, :load_now, nil})
      Mob.Socket.assign(socket, :first_frame?, true)
    else
      load.(socket)
    end
  end

  def first(socket, false, load), do: load.(socket)

  @doc "The page's content, or its skeleton while `first/3` has not loaded it."
  @spec content(map(), (map() -> term())) :: term()
  def content(%{first_frame?: true}, _content), do: skeleton()
  def content(assigns, content), do: content.(assigns)

  @doc false
  def skeleton do
    ~MOB"""
    <Column fill_width={true} padding_left={21} padding_right={21} padding_top={64}>
      <Column fill_width={true} padding_top={10}>
        <Box width={170} height={30} corner_radius={10} background={Palette.card()} />
        <Spacer size={22} />
      </Column>
      {Kati.Screens.Later.blocks([150, 64, 64, 64, 64])}
    </Column>
    """
  end

  @doc """
  Quiet card-coloured blocks, one per height, where content is about to land.
  """
  @spec blocks([pos_integer()]) :: map()
  def blocks(heights) do
    assigns = %{blocks: Enum.map(heights, &Kati.Screens.Later.block/1)}

    ~MOB"""
    <Column fill_width={true}>
      {@blocks}
    </Column>
    """
  end

  @doc false
  def block(height) do
    assigns = %{height: height}

    ~MOB"""
    <Column fill_width={true}>
      <Box fill_width={true} height={@height} corner_radius={18} background={Palette.card()} />
      <Spacer size={10} />
    </Column>
    """
  end
end
