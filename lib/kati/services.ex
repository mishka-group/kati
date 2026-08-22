defmodule Kati.Services do
  @moduledoc """
  The streaming services you pay for, the country you are in, and what
  "available" is allowed to mean.

  Screen 92's own caption states the job: *the screen that makes availability,
  leaving-soon and cost-per-watched-hour true rather than decorative.*

  ## One owner for a price, and it is stated on the screen

  Screen 23 lists subscriptions with a cost per watched hour, and until now it
  read `Kati.Subscriptions.Sample` for both the price and the rate. Screen 92
  says *this screen owns these prices; 23 reads them — edit here, and cost per
  watched hour follows*, and prints that sentence to the user. So the price is a
  column here, screen 23's fields are read-only, and neither screen has to
  guess which of them is authoritative.

  ## Region is not a preference, it is a precondition

  `Kati.Services.region/0` decides what `available` means, and screen 92 puts
  the reason in an `info` row rather than in a tooltip: *telling you a film is
  on Lumen+ when it is only on Lumen+ in Canada is worse than telling you
  nothing at all.* That is why the region row sits above the service list
  rather than in a `More` group — the list below it is meaningless without it.

  It lives in `Mob.State` beside the theme and the locale, for the reason
  `Kati.Locale` gives: a device-level choice with exactly one value, read on
  nearly every screen, and not worth a table.

  ## The three rules each carry their consequence

  `Count rentals as available`, `Count purchases as available` and `Hide titles
  I can't watch`. The third silently empties three other screens, which is
  precisely why its own sub-line names them — Discover, Up next and What fits
  tonight — and says what it does not touch.
  """

  use Ash.Domain, validate_config_inclusion?: false

  resources do
    resource Kati.Services.Service
  end

  @region_key :kati_region
  @rules_key :kati_availability_rules

  # ISO 3166-1 alpha-2, and the flag is derived from it rather than stored —
  # see `flag/1`. Ordered as screen 94 lists them: the current pick first is
  # the screen's job, not this list's.
  @countries [
    {"GB", "United Kingdom"},
    {"IR", "Iran"},
    {"US", "United States"},
    {"DE", "Germany"},
    {"FR", "France"},
    {"NL", "Netherlands"},
    {"AU", "Australia"}
  ]

  @default_rules %{rentals: true, purchases: false, hide_unavailable: false}

  @doc "Every country screen 94 offers, as `{code, name}`."
  @spec countries() :: [{String.t(), String.t()}]
  def countries, do: @countries

  @doc """
  The country Kati is answering *available* for. `\"GB\"` until somebody says
  otherwise, which is the region the drawings were captured in.
  """
  @spec region() :: String.t()
  def region do
    case Mob.State.get(@region_key) do
      code when is_binary(code) -> code
      _other -> "GB"
    end
  end

  @doc "Set the region. Screen 94's only side effect."
  @spec put_region(String.t()) :: :ok
  def put_region(code) when is_binary(code) do
    Mob.State.put(@region_key, code)
    :ok
  end

  @doc "The region's display name, or the code itself for one this list has not got."
  @spec region_name(String.t()) :: String.t()
  def region_name(code) do
    case Enum.find(@countries, fn {c, _name} -> c == code end) do
      {_code, name} -> name
      nil -> code
    end
  end

  @doc """
  The flag, as the two regional-indicator codepoints its letters map to.

  Derived rather than stored, because a flag emoji **is** the country code —
  `GB` is U+1F1EC U+1F1E7 — and a stored copy is a second thing to get wrong.
  Any two-letter code produces something; an unknown one produces the pair of
  letters as indicators, which renders as two boxed letters rather than as a
  wrong flag.
  """
  @spec flag(String.t()) :: String.t()
  def flag(<<a, b>>) when a in ?A..?Z and b in ?A..?Z do
    <<0x1F1E6 + (a - ?A)::utf8, 0x1F1E6 + (b - ?A)::utf8>>
  end

  def flag(code) when is_binary(code), do: code |> String.upcase() |> then(&flag_or(&1, code))

  defp flag_or(<<a, b>>, _fallback) when a in ?A..?Z and b in ?A..?Z, do: flag(<<a, b>>)
  defp flag_or(_upcased, fallback), do: fallback

  @doc "The three availability rules, as a map of booleans."
  @spec rules() :: %{rentals: boolean(), purchases: boolean(), hide_unavailable: boolean()}
  def rules do
    case Mob.State.get(@rules_key) do
      %{} = stored -> Map.merge(@default_rules, Map.take(stored, Map.keys(@default_rules)))
      _other -> @default_rules
    end
  end

  @doc "Flip one rule and store the set."
  @spec toggle_rule(atom()) :: :ok
  def toggle_rule(rule) when is_map_key(@default_rules, rule) do
    current = rules()
    Mob.State.put(@rules_key, Map.put(current, rule, not Map.fetch!(current, rule)))
    :ok
  end

  @doc "The default rules, for a device that has never opened screen 92."
  @spec default_rules() :: map()
  def default_rules, do: @default_rules
end
