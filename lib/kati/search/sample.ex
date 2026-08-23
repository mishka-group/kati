defmodule Kati.Search.Sample do
  @moduledoc """
  Screens 86, 87 and 89, as the drawings captured them.

  The recent queries are the drawing's own and are **never translated** —
  screen 88 says so in its own row: *never translated, they are your words.*
  A fixture that localised them would be modelling the one thing the feature
  promises not to do.
  """

  @doc "The last eight queries, newest first. Five drawn."
  @spec recent() :: [String.t()]
  def recent, do: ["dentist", "leaving soon", "ines karvel", "4 stars", "miso salmon"]

  @doc """
  The two suggestions, and there are only ever two.

  Screen 86's caption: *Try suggestions ship, but only two, drawn from what you
  actually have.* Two, because a suggestion list long enough to browse is a
  second search — and drawn from your own library, because a suggestion for
  something you do not keep is an advert.
  """
  @spec suggestions() :: [String.t()]
  def suggestions, do: ["what leaves this week", "notes about the estuary"]

  @doc "The header's placeholder, generalised now that scope spans seven domains."
  @spec placeholder() :: String.t()
  def placeholder, do: "Search anything you keep"

  @doc "The sentence that explains why the chips carry no counts on open."
  @spec counts_note() :: String.t()
  def counts_note do
    "Counts stay off the chips until a query exists — eight zeroes on open would read as an " <>
      "empty app. Searching starts at 2 characters, or 1 for Persian, Arabic and CJK, where one " <>
      "character is a word. Keystrokes debounce at 180 ms, so one pause costs seven counted " <>
      "queries, not seven per letter."
  end
end
