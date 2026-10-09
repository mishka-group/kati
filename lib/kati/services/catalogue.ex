defmodule Kati.Services.Catalogue do
  @moduledoc """
  The streaming services TMDB lists for a region, kept on the device (#106).

  `Kati.Media.Tmdb.watch_provider_catalogue/1` is the request; this keeps its
  answer in `Mob.State` per region, for `Kati.Media.CachePolicy.catalogue_refresh_days/0`,
  and fetches the logos into `Kati.Media.Artwork` alongside so the list draws
  pictures rather than filling in. A region TMDB has no data for (Iran, for
  one: JustWatch does not cover it) answers `{:ok, []}`, and the page says so
  and keeps the typed-in path.
  """

  alias Kati.Media.CachePolicy

  @prefix "services:catalogue:"
  @logos 40

  @doc """
  The catalogue for `region`: the kept copy while it is fresh, otherwise asked
  of TMDB and kept. A failed request answers the kept copy if there is one,
  however old — a stale list beats none.
  """
  @spec fetch(String.t()) :: {:ok, [map()]} | {:error, term()}
  def fetch(region) when is_binary(region) do
    case kept(region) do
      {:fresh, rows} ->
        {:ok, rows}

      kept ->
        case Kati.Media.Tmdb.watch_provider_catalogue(region) do
          {:ok, rows} ->
            fetch_logos(rows)
            keep(region, rows)
            {:ok, rows}

          {:error, reason} ->
            case kept do
              {:stale, rows} -> {:ok, rows}
              :none -> {:error, reason}
            end
        end
    end
  end

  @doc """
  The catalogue row named `name` — the exact name, ignoring case — or `nil`,
  so a service added by name from a title's providers still gets its id.
  """
  @spec named([map()], String.t()) :: map() | nil
  def named(rows, name) when is_binary(name) do
    wanted = String.downcase(String.trim(name))
    Enum.find(rows, &(String.downcase(&1.name) == wanted))
  end

  defp kept(region) do
    case Mob.State.get(@prefix <> region) do
      %{at: at, rows: rows} when is_integer(at) and is_list(rows) ->
        age_days = div(System.os_time(:second) - at, 86_400)

        if age_days < CachePolicy.catalogue_refresh_days(),
          do: {:fresh, rows},
          else: {:stale, rows}

      _absent ->
        :none
    end
  rescue
    _error -> :none
  catch
    :exit, _reason -> :none
  end

  defp keep(region, rows) do
    Mob.State.put(@prefix <> region, %{at: System.os_time(:second), rows: rows})
  rescue
    _error -> :ok
  catch
    :exit, _reason -> :ok
  end

  defp fetch_logos(rows) do
    rows
    |> Enum.take(@logos)
    |> Enum.map(& &1.logo)
    |> Enum.filter(&is_binary/1)
    |> Task.async_stream(&safely(fn -> Kati.Media.Artwork.cache(&1) end),
      max_concurrency: 8,
      timeout: 15_000,
      on_timeout: :kill_task
    )
    |> Stream.run()
  end

  defp safely(fun) do
    fun.()
  rescue
    _error -> :error
  catch
    :exit, _reason -> :error
  end
end
