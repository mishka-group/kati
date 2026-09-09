defmodule Kati.Sections do
  @moduledoc """
  Which parts of Kati you asked for.

  The first run asks — *"Pick two. More later from 24."* — and until now threw
  the answer away with the socket. `Kati.Screens.PickSections` toggled a
  `MapSet` on an assign, the screen popped, and the app then showed every
  section to everybody. A question asked and discarded is worse than one never
  asked: it teaches someone their answer counts, once.

  ## Why this is `Mob.State` and not a resource

  The choice is a preference, not data. `Mob.State` is the DETS the app already
  keeps the locale and the theme in, it survives a restart, and it is readable
  before the repo is up — which matters, because the home screen decides what to
  draw before anything queries.

  ## The rule the design states

  Sections add shelves and feeds, never tabs, and turning one off removes it
  **everywhere at once** — the home card, the calendar feed and the shelf
  together. That is why this is one list read by every surface rather than a
  flag per screen: three flags drift, and the drift shows up as a section that
  is half off.

  ## Everything, when nothing has been said

  `all/0` is the answer before the first run has been walked, and deliberately
  not `[]`. An empty list would mean a brand-new install shows nothing at all,
  and a screen with no content is indistinguishable from a screen that is
  broken — which is the confusion this whole effort exists to end.
  """

  @key :kati_sections

  @known ~w(screen books music habits money notes)

  @doc "Every section Kati can keep, in the order the first run draws them."
  @spec all() :: [String.t()]
  def all, do: @known

  @doc """
  The sections this install keeps.

  Everything, until the first run says otherwise.
  """
  @spec chosen() :: [String.t()]
  def chosen do
    case Mob.State.get(@key) do
      list when is_list(list) and list != [] -> Enum.filter(@known, &(&1 in list))
      _nothing_yet -> all()
    end
  end

  @doc """
  Keep exactly these sections.

  Refuses an empty list. The first run's own rule is that Continue counts —
  *"Cannot continue with zero"* — and a store that accepted nothing would make
  that rule a matter of remembering to check it at every call site.
  """
  @spec put([String.t()]) :: :ok | {:error, :none_chosen}
  def put([]), do: {:error, :none_chosen}

  def put(ids) when is_list(ids) do
    case Enum.filter(@known, &(&1 in ids)) do
      [] -> {:error, :none_chosen}
      kept -> Mob.State.put(@key, kept) && :ok
    end
  end

  @doc """
  Whether the first run has answered this question yet.

  Distinct from `chosen/0` returning something, which it always does —
  everything, when nothing has been said. The first-run picker needs the other
  question: a person who has never answered should see the DESIGN's opening
  selection (`Kati.Screens.PickSections.Sample.chosen/0` — Screen and Books
  ticked), while a person coming back to a run they were interrupted during
  must see what THEY ticked. Seeding both from `chosen/0` would show a
  returning person every section ticked, which is not what they chose and not
  what the drawing opens on.
  """
  @spec answered?() :: boolean()
  def answered? do
    case Mob.State.get(@key) do
      list when is_list(list) and list != [] -> true
      _nothing_yet -> false
    end
  end

  @doc "Whether a section is kept."
  @spec on?(String.t()) :: boolean()
  def on?(id) when is_binary(id), do: id in chosen()

  @doc """
  Forget the choice, so the next read answers `all/0` again.

  For the first run and for tests. Not offered anywhere in the app: forgetting
  which sections someone keeps is not a thing they would ask for, and Settings
  turning them back on one at a time is.
  """
  @spec forget!() :: :ok
  def forget! do
    Mob.State.delete(@key)
    :ok
  end
end
