defmodule Kati.Goals.Sample do
  use Gettext, backend: Kati.Gettext

  @moduledoc """
  Screens 104 and 106, as the drawings captured them.

  Three cards, one anatomy, and each in a different state — ahead, on pace,
  behind — because a goals page with three cards all doing well would be a
  drawing of a mood rather than of a screen.

  Every figure here is the drawing's own. The projections are stated rather
  than computed for the reason `Kati.Books.Sample` states its pace: a fixture
  whose numbers move with the clock cannot be compared with the frame it was
  captured from.
  """

  @doc "The three cards, in the order screen 104 draws them."
  @spec goals() :: [map()]
  def goals do
    [
      %{
        pace: :on_pace,
        pace_label: Kati.Screens.Goals.pace_label(:on_pace),
        title: gettext("%{count} books this year", count: Kati.Locale.number(52)),
        progress: 38,
        target: 52,
        fraction: 38 / 52,
        drift: nil,
        projection_lead: Kati.Screens.Goals.projection_lead_word(:on_pace_dated),
        projection:
          gettext("%{done} of %{total}",
            done: Kati.Locale.number(48),
            total: Kati.Locale.number(52)
          ),
        projection_tail: gettext("by"),
        projection_date: gettext("31 December"),
        counts:
          gettext(
            "Counts finished books only. A book you did not finish counts its pages toward the pages goal, not this one."
          )
      },
      %{
        pace: :ahead,
        pace_label: Kati.Screens.Goals.pace_label(:ahead),
        title: gettext("%{count} minutes read a month", count: Kati.Locale.number(600)),
        progress: 740,
        target: 600,
        fraction: 1.0,
        drift: Kati.Locale.number(23) <> gettext("%"),
        projection_lead: Kati.Screens.Goals.projection_lead_word(:past),
        projection: ngettext("%{n} day", "%{n} days", 9, n: Kati.Locale.number(9)),
        projection_tail: gettext("left in August."),
        projection_date: nil,
        counts:
          gettext("Counts timed sittings only — a session logged by page has no minutes to give.")
      },
      %{
        pace: :behind,
        pace_label: Kati.Screens.Goals.pace_label(:behind),
        title: gettext("%{count} films this year", count: Kati.Locale.number(120)),
        progress: 84,
        target: 120,
        fraction: 84 / 120,
        drift: Kati.Locale.number(11) <> gettext("%"),
        projection_lead: Kati.Screens.Goals.projection_lead_word(:on_pace_counted),
        projection:
          gettext("%{done} of %{total}",
            done: Kati.Locale.number(106),
            total: Kati.Locale.number(120)
          ),
        # `pgettext/2` and not `gettext(".")`: a bare full stop is a msgid no
        # translator can place, and `mix gettext.merge` fuzzy-matched it against
        # the first sentence in the catalogue that happened to end in one. The
        # context is what makes it placeable — and it is not punctuation in
        # Persian at all: board 108 ends this sentence with a verb, **می‌رسید.**
        projection_tail: Kati.Screens.Goals.projection_tail_word(),
        projection_date: nil,
        counts: gettext("Dropped shows keep the hours they earned. Nothing is taken back.")
      }
    ]
  end

  @doc "The header's mono subtitle."
  @spec subtitle() :: String.t()
  def subtitle do
    Kati.UI.eyebrow_label(
      gettext("%{count} active · %{span}",
        count: Kati.Locale.number(3),
        span:
          gettext("Jan – Dec %{year}",
            year: Kati.Locale.number(Kati.Locale.pick(2026, 1405))
          )
      )
    )
  end
end
