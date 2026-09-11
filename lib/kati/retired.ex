defmodule Kati.Retired do
  use Gettext, backend: Kati.Gettext

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

  ## Why the entries are a function and the ids are the key

  Two things changed when mishka-group/kati#103 folded screen 82, both of them
  the same change:

    * **`gettext/1` in a module attribute is evaluated at COMPILE time**, so an
      `@entries` holding translated copy freezes whichever locale the compiler
      happened to be in. The entries are built per call instead.

    * **`known?/1` and `id_for/1` took a NAME**, which is the defect this whole
      fold is about: a label doubling as compared state. `Kati.Retired.known?("Sleep")`
      answers `false` the moment *Sleep* is **خواب** on screen, and it answers
      it silently — the tile simply stops being tappable. Both take the id now,
      which is the thing that does not translate, and every caller already had
      one.
  """

  # Ids and glyphs: the half that is not copy, and the half a translation must
  # never reach. The order is the order screen 42's grid and screen 80's list
  # read them in.
  @entries [
    {:sleep, "bedtime"},
    {:workouts, "fitness_center"},
    {:hardcover, "menu_book"},
    {:trakt, "movie"},
    {:simkl, "live_tv"},
    {:lastfm, "graphic_eq"}
  ]

  @ids Enum.map(@entries, &elem(&1, 0))

  @doc """
  Everything with a decision already taken about it.

      iex> Kati.Retired.all() |> Enum.map(& &1.id) |> Enum.member?(:hardcover)
      true
  """
  @spec all() :: [map()]
  def all, do: Enum.map(@entries, fn {id, icon} -> entry(id, icon) end)

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
    Enum.find(all(), &(Atom.to_string(&1.id) == id))
  end

  def find(id) when is_atom(id), do: Enum.find(all(), &(&1.id == id))

  @doc """
  Whether an id has a reason behind it, so a caller can decide whether to
  offer the tap at all.

      iex> Kati.Retired.known?(:hardcover)
      true

      iex> Kati.Retired.known?(:listenbrainz)
      false

  The id and not the name. A name is drawn, and a drawn string is translated —
  see the moduledoc.
  """
  @spec known?(atom() | nil) :: boolean()
  def known?(id) when is_atom(id), do: id in @ids

  @doc """
  The params a caller threads to screen 114.

      iex> Kati.Retired.params_for(:hardcover)
      %{id: :hardcover}

      iex> Kati.Retired.params_for(:listenbrainz)
      %{}
  """
  @spec params_for(atom() | nil) :: map()
  def params_for(id) do
    if known?(id), do: %{id: id}, else: %{}
  end

  # One entry, with its copy asked for in the reader's own language at the
  # moment the page draws it.
  defp entry(:sleep, icon) do
    %{
      id: :sleep,
      icon: icon,
      name: gettext("Sleep"),
      what:
        gettext("A nightly record — when you went down, when you woke, and how long that was."),
      why:
        gettext(
          "Kati would have to read it from the phone's own health store, and that is a " <>
            "permission this app has not asked for. Everything Kati holds today, you typed."
        )
    }
  end

  defp entry(:workouts, icon) do
    %{
      id: :workouts,
      icon: icon,
      name: gettext("Workouts"),
      what: gettext("Sessions with a kind, a length and an effort against them."),
      why:
        gettext(
          "The same permission Sleep needs, and the same answer. A workout log you type " <>
            "by hand is a worse version of an app you already have."
        )
    }
  end

  defp entry(:hardcover, icon) do
    %{
      id: :hardcover,
      # A trade name, and board 320 settles it: the pill translates and the
      # provider's name does not.
      icon: icon,
      name: "Hardcover",
      what: gettext("Community book ratings, read with a token of your own."),
      why:
        gettext(
          "Kati already has Open Library for covers and editions, and a second book " <>
            "source that needs an account is a setup step for a number you did not ask for."
        )
    }
  end

  defp entry(:trakt, icon) do
    %{
      id: :trakt,
      icon: icon,
      name: "Trakt",
      what: gettext("A live sync of what you are watching, both ways."),
      why:
        gettext(
          "It needs a client secret pasted into the app, which is a credential Kati " <>
            "would be holding on your behalf rather than one you can revoke at the source. " <>
            "The importer reads a Trakt export today, which needs none."
        )
    }
  end

  defp entry(:simkl, icon) do
    %{
      id: :simkl,
      icon: icon,
      name: "Simkl",
      what: gettext("The same live sync, from a different service."),
      why: gettext("The same pasted client secret, and the same answer. The export imports.")
    }
  end

  defp entry(:lastfm, icon) do
    %{
      id: :lastfm,
      icon: icon,
      name: "Last.fm",
      what: gettext("Scrobbles, as they happen."),
      why:
        gettext(
          "A pasted client secret again. ListenBrainz does the same job with a token " <>
            "you issue and can revoke yourself, which is why that one is offered and this " <>
            "one is not."
        )
    }
  end
end
