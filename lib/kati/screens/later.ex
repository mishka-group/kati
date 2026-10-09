defmodule Kati.Screens.Later do
  @moduledoc """
  The slow half of a page, read after its first frame (#128).

  Mob has no `assign_async` yet. Its author's advice until the framework grows
  one: do the work in a task and send the answer to the screen. So a page
  draws what it can from a cheap read — a title, a header — with `blocks/1`
  where the rest goes, and `run/2` reads the rest under `Kati.TaskSupervisor`
  and sends `{:kati, :loaded, {key, value}}` back. `Kati.Screens.Root` and
  `Kati.Screens.Pushed` already route `{:kati, topic, payload}` to
  `handle_kati/3`, so a screen answers it there.

  `:screens_in_background` switched off (the host tests set it) makes
  `enabled?/0` false, and a screen then reads everything in `load/1` the old
  way, so a test that mounts a screen sees it whole.
  """
  import Mob.Sigil

  alias Kati.Theme.Palette

  @doc "Whether pages load their slow half after the first frame."
  @spec enabled?() :: boolean()
  def enabled?, do: Application.get_env(:kati, :screens_in_background, true)

  @doc """
  Run `work` off this screen's process and send its answer back as
  `{:kati, :loaded, {key, answer}}`.
  """
  @spec run(term(), (-> term())) :: :ok
  def run(key, work) when is_function(work, 0) do
    screen = self()
    job = fn -> send(screen, {:kati, :loaded, {key, work.()}}) end

    case Process.whereis(Kati.TaskSupervisor) do
      nil -> spawn(job)
      _supervisor -> Task.Supervisor.start_child(Kati.TaskSupervisor, job)
    end

    :ok
  end

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
