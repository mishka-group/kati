defmodule Kati.Retired do
  @moduledoc """
  What Kati has decided not to build yet, and why — in one place.

  Three surfaces ask the same question and each answered it alone: screen 42's
  grid has two dashed tiles (Sleep and Workouts), board 320 retires Hardcover on
  the data-sources page, and `Kati.Sources.refused/0` names three importers that
  need a pasted `client_secret`. All three drew *tap to see why* and none of
  them had a screen behind it.

  ## The shape of a reason

  Board 114 is explicit about what a retired tile owes the reader: **what it is,
  why not here, and no date.** The third is the load-bearing one — a date is a
  promise, and a promise nobody has made is worse than a plain no. So there is
  no `:when` field here and there is not going to be one.
  """

  @entries [
    %{
      id: :sleep,
      icon: "bedtime",
      name: "Sleep",
      what: "A nightly record — when you went down, when you woke, and how long that was.",
      why:
        "Kati would have to read it from the phone's own health store, and that is a " <>
          "permission this app has not asked for. Everything Kati holds today, you typed."
    },
    %{
      id: :workouts,
      icon: "fitness_center",
      name: "Workouts",
      what: "Sessions with a kind, a length and an effort against them.",
      why:
        "The same permission Sleep needs, and the same answer. A workout log you type " <>
          "by hand is a worse version of an app you already have."
    },
    %{
      id: :hardcover,
      icon: "menu_book",
      name: "Hardcover",
      what: "Community book ratings, read with a token of your own.",
      why:
        "Kati already has Open Library for covers and editions, and a second book " <>
          "source that needs an account is a setup step for a number you did not ask for."
    },
    %{
      id: :trakt,
      icon: "movie",
      name: "Trakt",
      what: "A live sync of what you are watching, both ways.",
      why:
        "It needs a client secret pasted into the app, which is a credential Kati " <>
          "would be holding on your behalf rather than one you can revoke at the source. " <>
          "The importer reads a Trakt export today, which needs none."
    },
    %{
      id: :simkl,
      icon: "live_tv",
      name: "Simkl",
      what: "The same live sync, from a different service.",
      why: "The same pasted client secret, and the same answer. The export imports."
    },
    %{
      id: :lastfm,
      icon: "graphic_eq",
      name: "Last.fm",
      what: "Scrobbles, as they happen.",
      why:
        "A pasted client secret again. ListenBrainz does the same job with a token " <>
          "you issue and can revoke yourself, which is why that one is offered and this " <>
          "one is not."
    }
  ]

  @doc """
  Everything with a decision already taken about it.

      iex> Kati.Retired.all() |> Enum.map(& &1.id) |> Enum.member?(:hardcover)
      true
  """
  @spec all() :: [map()]
  def all, do: @entries

  @doc """
  One, by id — or `nil`, which is what a push naming nothing gets.

      iex> Kati.Retired.find(:sleep).name
      "Sleep"

      iex> Kati.Retired.find(:nothing_here)
      nil
  """
  @spec find(atom() | String.t() | nil) :: map() | nil
  def find(nil), do: nil

  def find(id) when is_binary(id) do
    Enum.find(@entries, &(Atom.to_string(&1.id) == id))
  end

  def find(id) when is_atom(id), do: Enum.find(@entries, &(&1.id == id))

  @doc """
  Whether a name has a reason behind it, so a caller can decide whether to
  offer the tap at all.

      iex> Kati.Retired.known?("Hardcover")
      true

      iex> Kati.Retired.known?("ListenBrainz")
      false
  """
  @spec known?(String.t()) :: boolean()
  def known?(name), do: Enum.any?(@entries, &(&1.name == name))

  @doc """
  The id behind a name, for a screen that holds the name and not the id.

      iex> Kati.Retired.id_for("Hardcover")
      :hardcover
  """
  @spec id_for(String.t()) :: atom() | nil
  def id_for(name) do
    case Enum.find(@entries, &(&1.name == name)) do
      nil -> nil
      entry -> entry.id
    end
  end
end
