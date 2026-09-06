defmodule Kati.Repo.Migrations.AddCachedTitleProviders do
  @moduledoc """
  Where a title can actually be watched.

  Screen 92 offers three availability rules — *Count rentals as available*,
  *Count purchases as available*, *Hide titles I can't watch* — and the third
  one prints the screens it empties: *Removes them from Discover, Up next and
  What fits tonight*. None of the three did anything, because nothing in Kati
  knew where a title streams (MOVIES-AND-TV.md #77). The rules were stored and
  consumed by nothing, which is worse than absent: a switch that remembers
  your answer and ignores it is a promise with a receipt.

  TMDB answers it. `/movie/{id}` and `/tv/{id}` both take
  `append_to_response=watch/providers`, so this costs no extra request — the
  fetch that already caches the title carries the providers home with it.

  A MAP, keyed by region, because that is the shape of the answer: JustWatch's
  data is per country, and screen 92's own note says telling somebody a film
  is on Lumen+ when it is only on Lumen+ in Canada is worse than telling them
  nothing. Storing one region's answer would make the country row a lie the
  first time somebody changed it.

      %{"GB" => %{"flatrate" => ["Netflix"], "rent" => ["Apple TV"], "buy" => []}}

  Names, not ids. A provider id is JustWatch's and means nothing to the reader
  or to `Kati.Services.Service`, which is keyed on the name a person typed —
  and matching *what you pay for* against *where this streams* is the whole
  point of the column.

  Nullable, and `nil` is not `%{}`: nothing fetched yet is a different fact
  from fetched and available nowhere, and only the second is worth telling
  somebody about.
  """
  use Ecto.Migration

  def up do
    alter table(:cached_titles) do
      add :providers, :map
      add :providers_checked_at, :utc_datetime
    end
  end

  def down do
    alter table(:cached_titles) do
      remove :providers
      remove :providers_checked_at
    end
  end
end
