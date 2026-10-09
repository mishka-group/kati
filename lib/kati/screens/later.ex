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
