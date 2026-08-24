defmodule Kati.NumberingScheme.Sample do
  @moduledoc """
  Stand-in copy for board 153, which explains a feature rather than one show.

  Every other screen this pattern was built for shows a resource: `show/0` in
  `Kati.SeriesSettings.Sample` is the specific title screen 35's settings
  belong to, sample only because `Kati.Media` cannot fill it in yet. This
  screen is different in kind, not just in progress. `Kati.Media.TrackedTitle`
  carries no numbering-scheme column at all — not "not built", *not asked
  for*, because the two cards below are not one show's current setting shown
  twice. `inherited/0` is the row a title with no override draws; `overridden/0`
  is the row a title whose default was wrong draws once corrected. A single
  show cannot be in both states at once, and the drawing does not claim it is
  — it draws the feature's two shapes side by side, the way the design system
  panel at the foot of this board draws Palette and Type and Rhythm as
  concepts rather than as one screen's colours. There is nothing here for a
  future `Kati.Media` migration to inherit, because there is no per-show fact
  being approximated: `%{icon: "pin", title: "Absolute", ...}` is not screen
  153's guess at a row that will one day read `title.numbering_scheme`, it is
  the whole of what the row says.

  Marked clearly rather than hidden all the same: sample data that looks like
  real data is how a demo quietly becomes a lie, whether or not a resource is
  ever coming for it.
  """

  @doc "The screen's own header."
  @spec header() :: map()
  def header do
    %{title: "Numbering", subtitle: "A DEFAULT THAT ANNOUNCES ITS OWN REASON"}
  end

  @doc """
  The un-touched row: a guess, with the reason attached.

  `sub` is the whole argument the board is making — "because this is anime" is
  not filler under the value, it is the fact that turns a guess into something
  the user can trust or correct on sight.
  """
  @spec inherited() :: map()
  def inherited do
    %{icon: "pin", title: "Absolute", sub: "because this is anime", action: "Override"}
  end

  @doc """
  The corrected row: a title the anime default got wrong.

  `sub` names both halves out loud — what the user set AND what the default
  would have picked — which is the same self-explaining move `inherited/0`
  makes, aimed the other way.
  """
  @spec overridden() :: map()
  def overridden do
    %{
      icon: "pin",
      title: "Seasons",
      sub: "you set this · anime default was Absolute",
      action: "Reset"
    }
  end

  @doc "The two labels the comparison card sets side by side, and its footnote."
  @spec comparison() :: map()
  def comparison do
    %{
      left: %{label: "Absolute", value: "E32"},
      right: %{label: "Seasons", value: "S2 E6"},
      note:
        "Same episode. Numbering changes only what is displayed — Kati always " <>
          "stores season and episode, so switching never loses a tick and never " <>
          "shows both at once."
    }
  end

  @doc """
  The MyAnimeList import tile.

  `does_not` exists because this tile is, per the board's own eyebrow, "the
  whole of a MAL user's onboarding" — the only integration those users get, so
  it has to say what does NOT come across as plainly as what does.
  """
  @spec mal() :: map()
  def mal do
    %{
      glyph: "M",
      title: "MyAnimeList",
      file: "animelist.xml",
      comes_across: "Titles, scores, watched counts, status, dates",
      numbering: "Set to Absolute — MAL exports are absolute",
      does_not: "Reviews, tags and your MAL friends",
      footnote:
        "XML is importer-only — there is no MAL sync. This tile is the whole of " <>
          "a MAL user’s onboarding, so it states both halves."
    }
  end
end
