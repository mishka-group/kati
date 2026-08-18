defmodule Kati.Locale do
  @moduledoc """
  Kati's active locale and its writing direction.

  The locale is an **in-app setting**, not `Locale.getDefault()`. A Persian user
  on an English phone must still get Persian and RTL, and the two must never
  disagree — which is why the direction is derived from this value and passed
  down as a prop rather than read natively at the leaves.

  Stored in `Mob.State` (DETS, SIGKILL-safe) so it survives a restart.
  """

  @locales [:en, :fa]
  @default :en

  @doc "Every locale Kati ships. Machinery supports more; translations do not."
  def supported, do: @locales

  @doc "The active locale."
  @spec current() :: :en | :fa
  def current do
    case Mob.State.get(:locale, @default) do
      l when l in @locales -> l
      _ -> @default
    end
  end

  @doc "Set the active locale."
  @spec put(:en | :fa) :: :ok
  def put(locale) when locale in @locales do
    Mob.State.put(:locale, locale)
    :ok
  end

  @doc "Writing direction for a locale."
  @spec direction(atom()) :: :ltr | :rtl
  def direction(:fa), do: :rtl
  def direction(_), do: :ltr

  @doc "Writing direction of the active locale, as the string the bridge expects."
  @spec direction_prop() :: String.t()
  def direction_prop do
    case direction(current()) do
      :rtl -> "rtl"
      :ltr -> "ltr"
    end
  end

  @doc "The CLDR locale name for the active locale."
  @spec cldr_name() :: String.t()
  def cldr_name, do: Atom.to_string(current())
end
