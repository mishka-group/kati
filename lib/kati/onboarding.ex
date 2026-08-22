defmodule Kati.Onboarding do
  @moduledoc """
  Whether the first-run sequence has been completed, and what to open first.

  ## Why this exists

  Screens 53, 26 and 38 are the first-run sequence, and all three were drawn,
  built and unreachable: `Kati.App.navigation/1` named `Kati.Screens.Home` as
  the stack root unconditionally, so a fresh install went straight to a home
  page for a library that does not exist yet. The three screens could only be
  seen from `Kati.Screens.Gallery`, which is a development scaffold.

  The order is the drawings' own. 53's caption calls it "the first thing the
  app asks, before anything else can be worded" — it has to come first,
  because it decides the writing direction every later screen is laid out in.
  26's caption says "four steps, and the second one is this". 38 draws the
  remaining steps, and its own moduledoc records that it renders steps 1, 3
  and 4 stacked because the drawing does.

  ## Why a flag rather than inferring it

  "Has the user finished onboarding" is not the same question as "is the
  database empty", and answering the second in place of the first is how a
  first run gets shown twice. Someone who picks two sections, declines to add
  a title and lands on Home has completed the sequence and has no rows; so has
  someone who later clears their watch history. Neither should be asked again.

  The flag lives in `Mob.State`, the same DETS-backed store the theme choice
  uses, so it survives a restart without needing a table of its own — and it
  is deliberately not in `kati.db`, because restoring a backup from another
  device must not be able to re-trigger a first run on this one.
  """

  @key :onboarding_complete

  @doc """
  Whether the first-run sequence has been completed.

  Defaults to `false`, so a store that has never been written — a fresh
  install — reports a first run rather than silently skipping it.
  """
  @spec complete?() :: boolean()
  def complete? do
    case Mob.State.get(@key, false) do
      true -> true
      _ -> false
    end
  end

  @doc "Records that the first-run sequence has been finished."
  @spec complete!() :: :ok
  def complete! do
    Mob.State.put(@key, true)
    :ok
  end

  @doc """
  Clears the flag, so the next launch runs onboarding again.

  Exists for the tests and for a future *Reset* row; nothing in the app calls
  it, and nothing should call it as a side effect of clearing data.
  """
  @spec reset!() :: :ok
  def reset! do
    Mob.State.put(@key, false)
    :ok
  end

  @doc """
  The screen `Kati.App.navigation/1` opens the stack on.

  On a first run that is screen 53; afterwards it is the shell root for the
  locale the user chose, which is `Kati.Screens.HomeFa` for `:fa` and
  `Kati.Screens.Home` for `:en`. Reading the locale here rather than always
  naming `Kati.Screens.Home` is what makes the choice made on 53 survive the
  app being closed.
  """
  @spec first_screen() :: module()
  def first_screen do
    if complete?(), do: shell_root(Kati.Locale.current()), else: Kati.Screens.LanguagePick
  end

  @doc "The root screen for a locale."
  @spec shell_root(atom()) :: module()
  def shell_root(:fa), do: Kati.Screens.HomeFa
  def shell_root(_), do: Kati.Screens.Home
end
