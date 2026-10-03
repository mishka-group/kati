defmodule Kati.Notifications.History do
  @moduledoc """
  What Kati has told the reader, kept so the Notifications screen can show it
  again, grouped by title (#125).

  Two ways in:

    * an alarm Kati armed (`remember_armed/1`) becomes history once its time
      has passed (`collect/1`) — the platform fired it while Kati may well
      have been closed, and this is how the screen learns it did;
    * the background worker's finds (`add_found/2`) — new episodes it saw and
      posted itself, drained from its run files at the next start.

  Kept in `Mob.State`: a short list of plain maps, newest first, capped at
  `@cap`. It is a record of notifications, not of the reader's data, so it is
  not in the database, the backup or the sync.
  """
  use Gettext, backend: Kati.Gettext

  alias Kati.Notifications.Candidate

  @armed_key :notification_armed
  @history_key :notification_history
  @cap 60

  @type entry :: %{
          id: String.t(),
          tracked_id: String.t() | nil,
          kind: String.t() | nil,
          title: String.t(),
          body: String.t(),
          at: integer(),
          read: boolean()
        }

  @doc "Remember armed candidates, so their firing can be told later."
  @spec remember_armed([Candidate.t()]) :: :ok
  def remember_armed(candidates) do
    added =
      Map.new(candidates, fn c ->
        {c.id,
         %{
           id: c.id,
           tracked_id: get_in(c.meta || %{}, [:tracked_id]),
           kind: c.meta |> Kati.Notifications.History.kind_of(),
           title: c.title || "",
           body: c.body || "",
           at: c.fire_at && DateTime.to_unix(c.fire_at)
         }}
      end)

    put(@armed_key, Map.merge(get(@armed_key, %{}), added))
  end

  @doc false
  def kind_of(%{kind: kind}) when kind in [:movie, "movie"], do: "movie"
  def kind_of(%{kind: kind}) when not is_nil(kind), do: "tv"
  def kind_of(_meta), do: nil

  @doc "Move every armed notification whose time has passed into the history."
  @spec collect(DateTime.t()) :: :ok
  def collect(now \\ Kati.Time.now()) do
    stamp = DateTime.to_unix(now)

    {fired, waiting} =
      get(@armed_key, %{})
      |> Map.values()
      |> Enum.split_with(&(is_integer(&1.at) and &1.at <= stamp))

    put(@armed_key, Map.new(waiting, &{&1.id, &1}))
    prepend(Enum.map(fired, &Map.put(&1, :read, false)))
  end

  @doc """
  Record what the background worker found: one entry per title, as it posted.
  """
  @spec add_found([map()], DateTime.t()) :: :ok
  def add_found(items, at) do
    items
    |> Enum.filter(&is_map/1)
    |> Enum.map(fn item ->
      %{
        id: "bg:" <> to_string(item["tracked_id"]) <> ":" <> to_string(item["key"]),
        tracked_id: item["tracked_id"],
        kind: item["kind"],
        title: item["title"] || "",
        body: item["body"] || "",
        at: DateTime.to_unix(at),
        read: false
      }
    end)
    |> prepend()
  end

  @doc "Every entry, newest first."
  @spec list() :: [entry()]
  def list, do: get(@history_key, [])

  @doc """
  The history by title: one group per title with how many updates it had and
  the newest one's words. Entries that name no title are their own group.
  """
  @spec grouped() :: [map()]
  def grouped do
    list()
    |> Enum.group_by(&(&1.tracked_id || &1.id))
    |> Enum.map(fn {_key, [newest | _] = entries} ->
      %{
        tracked_id: newest.tracked_id,
        kind: newest.kind,
        title: newest.title,
        body: newest.body,
        count: length(entries),
        at: newest.at,
        unread: Enum.count(entries, &(not &1.read))
      }
    end)
    |> Enum.sort_by(& &1.at, :desc)
  end

  @doc "How many entries the reader has not seen on the Notifications screen."
  @spec unread() :: non_neg_integer()
  def unread, do: Enum.count(list(), &(not &1.read))

  @doc "Mark everything read: the reader has opened the Notifications screen."
  @spec mark_read() :: :ok
  def mark_read, do: put(@history_key, Enum.map(list(), &Map.put(&1, :read, true)))

  @doc "Forget the history."
  @spec clear() :: :ok
  def clear, do: put(@history_key, [])

  @doc """
  A group's line: its newest words, or a count when there were several.

      iex> Kati.Notifications.History.line(%{count: 1, body: "New episode · S2E7"})
      "New episode · S2E7"
      iex> Kati.Notifications.History.line(%{count: 3, body: "New episode · S2E7"})
      "3 updates · New episode · S2E7"
  """
  @spec line(map()) :: String.t()
  def line(%{count: 1, body: body}), do: body

  def line(%{count: n, body: body}),
    do: gettext("%{n} updates · %{latest}", n: Kati.Locale.number(n), latest: body)

  defp prepend([]), do: :ok

  defp prepend(entries) do
    seen = MapSet.new(list(), & &1.id)
    fresh = Enum.reject(entries, &MapSet.member?(seen, &1.id))
    put(@history_key, Enum.take(Enum.sort_by(fresh, & &1.at, :desc) ++ list(), @cap))
  end

  defp get(key, default) do
    Mob.State.get(key, default)
  rescue
    _error -> default
  catch
    :exit, _reason -> default
  end

  defp put(key, value) do
    Mob.State.put(key, value)
    :ok
  rescue
    _error -> :ok
  catch
    :exit, _reason -> :ok
  end
end
