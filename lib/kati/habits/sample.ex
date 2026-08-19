defmodule Kati.Habits.Sample do
  @moduledoc """
  Stand-in habit data, until habits are real repeating calendar items.

  Screen 22's note is the design decision this module encodes: *"a habit is
  just a repeating calendar item that keeps a streak — no new visual language
  needed."* So a habit here is a name, a streak line, whether today is ticked,
  and seven day-states. Nothing about it is habit-specific except the streak.

  A day is one of four states rather than a boolean, because the drawing draws
  four and each says something different:

    * `:done` — hit, green, the calendar's own `#4E9A73`
    * `:partial` — hit, but on a streak that is only bronze, `#B08E55`
    * `:lapsed` — hit inside a broken streak, `#C4BDB3`
    * `:missed` — not hit, an empty `#E7E3DC` square

  The tone is a property of the *habit's* health, which is why the same tick
  is green in the first card and bronze in the third: it is the same act on a
  streak that is not yet worth much.
  """

  @doc "The header's mono subtitle."
  @spec subtitle() :: String.t()
  def subtitle, do: "4 active · 12-day best"

  @doc "The weekday ruler under every habit's week."
  @spec week_ruler() :: String.t()
  def week_ruler, do: "M T W T F S S"

  @doc "The four habits, in the order the drawing stacks them."
  @spec habits() :: [map()]
  def habits do
    [
      %{
        name: "Morning run",
        streak: "12 days",
        today: true,
        days: [:done, :done, :done, :done, :missed, :done, :done]
      },
      %{
        name: "Read 20 pages",
        streak: "5 days",
        today: true,
        days: [:done, :done, :missed, :done, :done, :done, :done]
      },
      %{
        name: "No screens after 23:00",
        streak: "2 days",
        today: false,
        days: [:partial, :missed, :partial, :partial, :missed, :missed, :partial]
      },
      %{
        name: "Water the plants",
        streak: "broken",
        today: false,
        days: [:missed, :lapsed, :missed, :missed, :lapsed, :missed, :missed]
      }
    ]
  end

  @doc "The colour a day square is drawn in."
  @spec day_tone(atom()) :: non_neg_integer()
  def day_tone(:done), do: 0xFF4E9A73
  def day_tone(:partial), do: 0xFFB08E55
  def day_tone(:lapsed), do: 0xFFC4BDB3
  def day_tone(:missed), do: 0xFFE7E3DC

  @doc "Whether a day square carries a tick at all."
  @spec ticked?(atom()) :: boolean()
  def ticked?(:missed), do: false
  def ticked?(_state), do: true

  @doc """
  Thirteen weeks of consistency, one 8pt cell per day, exactly as drawn.

  91 cells, written a week per line so the source can be checked against the
  drawing, and chunked into rows of **27** by the screen: `27*8 + 26*4 = 320`,
  which is where the export's `flex-wrap` breaks inside an 18pt-padded card.
  Mob has no wrap primitive, so the count is declared rather than measured —
  the same approach screen 07's contribution grid takes.
  """
  @spec consistency() :: [atom()]
  def consistency do
    ~w(
      full light full light mid full pale
      full pale mid pale mid mid mid
      light mid mid pale full full pale
      pale pale pale full mid pale full
      pale light light full mid pale mid
      full pale light pale full mid light
      full light mid light light mid full
      pale pale mid full mid mid light
      mid full full pale pale mid mid
      light full full full mid mid light
      light mid light mid full full pale
      pale mid mid light mid full full
      full mid light full mid mid light
    )a
  end

  @doc "The four tones of the consistency field, warmest for a full day."
  @spec cell_tone(atom()) :: non_neg_integer()
  def cell_tone(:full), do: 0xFF4E9A73
  def cell_tone(:mid), do: 0xFFB08E55
  def cell_tone(:light), do: 0xFFE4D2B0
  def cell_tone(:pale), do: 0xFFEFE3CB

  @doc "The two mono captions under the field."
  @spec consistency_caption() :: {String.t(), String.t()}
  def consistency_caption, do: {"May", "84% of days hit"}
end
