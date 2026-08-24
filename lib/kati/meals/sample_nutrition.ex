defmodule Kati.Meals.SampleNutrition do
  @moduledoc """
  Stand-in data for screen 47 — nutrition and adherence.

  The design's caption states the priority the screen is built around:
  *"Adherence is the number that matters, not calories — so it leads."* The
  cream hero carries the daily average because it is the headline, but the
  three count cards under it are what the week is judged on, and `Skipped` is
  the only figure drawn in red.

  Two shapes here are shared with other screens on purpose: the target line on
  every macro bar, and the pixel field, which is the same visual screens 07 and
  22 use — *"so a good week looks the same everywhere"*.

  Copy is taken from `test/design/screens/47.html` unchanged.
  """

  @doc "The mono line under the title."
  @spec plan_line() :: String.t()
  def plan_line, do: "Cutting v3 · week 6 of 12"

  @doc "The Week / Month / All segmented control, Week selected."
  @spec segments() :: [String.t()]
  def segments, do: ["Week", "Month", "All"]

  @doc """
  The cream hero: the week's daily average against its target.

  `average` and `unit` are two runs because the drawing sets them at 34 and 15
  on one baseline.
  """
  @spec hero() :: map()
  def hero do
    %{
      label: "Daily average",
      average: "2,040",
      unit: " kcal",
      target_label: "Target",
      target: "2,100"
    }
  end

  @doc """
  Seven days of calories, as bar heights against the hero's 64pt frame.

  The colours are three verdicts, not a gradient: ink is on target, `#D8D2C8`
  is under, `#B4553C` is over. Friday is the only red one, which is exactly
  what the insight at the bottom of the screen goes on to say.
  """
  @spec bars() :: [{String.t(), pos_integer(), non_neg_integer()}]
  def bars do
    [
      {"M", 51, 0xFF1A1917},
      {"T", 53, 0xFF1A1917},
      {"W", 47, 0xFFD8D2C8},
      {"T", 54, 0xFF1A1917},
      {"F", 60, 0xFFB4553C},
      {"S", 49, 0xFFD8D2C8},
      {"S", 37, 0xFFD8D2C8}
    ]
  end

  @doc "The three count cards. Only `Skipped` is drawn in red."
  @spec counts() :: [{String.t(), String.t(), non_neg_integer()}]
  def counts do
    [
      {"86%", "Adherence", 0xFF1A1917},
      {"30", "Meals hit", 0xFF1A1917},
      {"5", "Skipped", 0xFFB4553C}
    ]
  end

  @doc """
  Four macros against target.

  `fill` is the drawn width and `target` is the tick's position — 95% on every
  bar, which is the design's tolerance band rather than the target itself.
  Carbs are the one over: a full bar past the tick.
  """
  @spec macros() :: [map()]
  def macros do
    [
      %{name: "Protein", value: "155 / 168 g", fill: 0.92, tone: 0xFF1A1917},
      %{name: "Carbs", value: "219 / 210 g", fill: 1.0, tone: 0xFFB08E55},
      %{name: "Fat", value: "61 / 70 g", fill: 0.88, tone: 0xFFE4D2B0},
      %{name: "Fibre", value: "25 / 35 g", fill: 0.71, tone: 0xFF7C766D}
    ]
  end

  @doc "Where the target tick sits on every bar."
  @spec target_mark() :: float()
  def target_mark, do: 0.95

  @doc """
  Twelve weeks of days, as levels rather than colours.

  84 cells — the drawing's own count — wrapping at 27, which is what
  `12n - 4 <= 326` allows inside the card. Screen 22's field wraps at the same
  27 for the same reason.
  """
  @spec consistency() :: [0..3]
  def consistency do
    [
      0,
      2,
      1,
      2,
      1,
      0,
      3,
      2,
      3,
      2,
      1,
      0,
      3,
      3,
      1,
      2,
      0,
      0,
      3,
      0,
      3,
      0,
      0,
      0,
      0,
      2,
      0,
      3,
      2,
      3,
      1,
      2,
      3,
      0,
      2,
      2,
      3,
      0,
      2,
      2,
      0,
      1,
      1,
      3,
      1,
      2,
      1,
      2,
      2,
      0,
      1,
      2,
      3,
      3,
      2,
      3,
      2,
      0,
      1,
      3,
      2,
      1,
      1,
      1,
      1,
      2,
      2,
      0,
      1,
      1,
      1,
      2,
      3,
      3,
      1,
      3,
      3,
      2,
      2,
      1,
      2,
      2,
      2,
      1
    ]
  end

  @doc "The pixel field's four tones, warm rather than green."
  @spec tone(0..3) :: non_neg_integer()
  def tone(0), do: 0xFFEFE3CB
  def tone(1), do: 0xFFE4D2B0
  def tone(2), do: 0xFFB08E55
  def tone(_), do: 0xFF1A1917

  @doc "The two mono captions under the field."
  @spec field_caption() :: {String.t(), String.t()}
  def field_caption, do: {"Jun", "best run — 19 days"}

  @doc """
  What the data says.

  The drawing bolds `4 of 5 skips` inside the sentence. Mob has no inline run
  inside a `Text`, so the emphasis is lost and the sentence is not — which is
  the right way round.
  """
  @spec insight() :: String.t()
  def insight do
    "Friday is your weak day — 4 of 5 skips happen after 16:00 on a " <>
      "Friday. A lighter, faster dinner might hold better than the current one."
  end
end
