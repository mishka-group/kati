defmodule Kati.Settings.DropStatesSample do
  @moduledoc """
  The copy screen 148 puts across five states and three media.

  Same reasoning as `Kati.Settings.StatesSample`, restated rather than
  cross-referenced because the two boards earn it independently: this is a
  reference sheet, not a screen with a domain behind it, so the "sample" here
  is the specimen itself. `Kati.Media.TrackedTitle.status` really does hold
  `:active` / `:paused` / `:gone_cold` / `:dropped` / `:finished`, but a sheet
  that draws all five at once, three media wide, unconditionally, cannot be
  the result of reading one row's status — there is no title that is
  simultaneously every state, and a sheet gated on which titles happen to
  exist today would show a different grid on every device. So every line
  below is real copy from `148.html`, typed once, not fetched.

  ## `S1 E3`, `p. 148 of 380`, `2 listens` are not measurements

  They read like they came off a real title because that is the entire point
  of the Dropped band: *never a bare "dropped"* is the rule the board draws,
  and a rule about always keeping a position needs a position in the
  specimen or it is not shown obeying its own rule.
  """

  @doc "Active — the ordinary in-progress line per medium."
  @spec active() :: [{String.t(), String.t()}]
  def active do
    [
      {"Show", "Watching · next up S2 E6"},
      {"Book", "Reading · p. 214 / 380"},
      {"Album", "In rotation · 11 plays"}
    ]
  end

  @doc "Paused — chosen, so the line says so rather than inferring it."
  @spec paused() :: [{String.t(), String.t()}]
  def paused do
    [
      {"Show", "Paused, deliberately"},
      {"Book", "Paused, deliberately"},
      {"Album", "Paused"}
    ]
  end

  @doc "Gone cold — observed, so the line names the gap rather than a choice."
  @spec gone_cold() :: [{String.t(), String.t()}]
  def gone_cold do
    [
      {"Show", "No activity for 4 months"},
      {"Book", "No session for 6 weeks"},
      {"Album", "No play for 3 months"}
    ]
  end

  @doc """
  The footnote under Gone cold, split at its three bold runs.

  Segmented rather than handed over as one string, so the screen can style
  the emphasis the way `Kati.Screens.Money.suggestion/1` already does for the
  same shape of sentence — a cream note with bold words inside a running
  paragraph, which `Kati.UI.rich_text/1` needs as separate runs because a
  single `Text` carries exactly one style.
  """
  @spec gone_cold_note() :: map()
  def gone_cold_note do
    %{
      lead: "Rendered at a ",
      bold_1: "lighter weight",
      mid_1: " throughout, because Kati inferred it. Dropping from here reads as ",
      bold_2: "accepting Kati’s suggestion",
      mid_2: " — and there is a ",
      bold_3: "“No, still on it”",
      tail: " answer, which the app previously had nowhere to give."
    }
  end

  @doc "Dropped — chosen, and always with the position that makes it useful later."
  @spec dropped() :: [{String.t(), String.t()}]
  def dropped do
    [
      {"Show", "Dropped at S1 E3"},
      {"Book", "Did not finish at p. 148 of 380 (39%)"},
      {"Album", "Dropped after 2 listens"}
    ]
  end

  @doc """
  The dashed footnote under Dropped, flattened to one string.

  `Kati.UI.SettingsList.note/2` is built for exactly this frame — an icon
  over one paragraph, border rather than fill — and it takes plain text, the
  same trade every other call site in the app makes for a footnote with an
  emphasised word inside it. The bold on *"Never a bare dropped"* and
  *percentage* does not survive; the sentence does.
  """
  @spec dropped_note() :: String.t()
  def dropped_note do
    "Never a bare “dropped”. The captured position is the single thing that " <>
      "makes this better than every incumbent, all of which throw it away. " <>
      "For a book the percentage is the useful part."
  end

  @doc "Finished — and Album's third row says there is no such thing for it."
  @spec finished() :: [{String.t(), String.t()}]
  def finished do
    [
      {"Show", "Season complete / series complete"},
      {"Book", "Finished 12 Aug"},
      {"Album", "Deliberately none"}
    ]
  end

  @doc "The dashed footnote under Finished, flattened the same way as `dropped_note/0`."
  @spec finished_note() :: String.t()
  def finished_note do
    "Album has no Finished state, on purpose: an album does not finish the " <>
      "way a series does. It goes Active → Paused → Gone cold → Dropped and " <>
      "back, and that is the whole of it."
  end

  @doc """
  The six transitions, and what each one captures on the way through.

  `from` and `to` are the state names either side of the arrow; `capture` is
  the board's own answer to *what does Kati write down when this happens*,
  which is the whole reason this band exists — the five state bands say what
  a title looks like at rest, this one says what changes hands at the
  border.
  """
  @spec transitions() :: [{String.t(), String.t(), String.t()}]
  def transitions do
    [
      {"Active", "Paused", "nothing — position already known"},
      {"Active", "Gone cold", "the date activity stopped"},
      {"Gone cold", "Active", "nothing — “still on it” just clears it"},
      {"Gone cold", "Dropped", "position + optional reason"},
      {"Active", "Dropped", "position + optional reason"},
      {"Dropped", "Active", "resumes at the captured position"}
    ]
  end

  @doc "The closing note, split at its two bold runs the same way as `gone_cold_note/0`."
  @spec resume_note() :: map()
  def resume_note do
    %{
      lead: "Picking a dropped title back up ",
      bold_1: "resumes at the captured position",
      mid: " — it was captured for a reason. Kati says where you were and offers ",
      bold_2: "start over",
      tail: " beside it."
    }
  end
end
