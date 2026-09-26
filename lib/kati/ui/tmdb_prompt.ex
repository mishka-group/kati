defmodule Kati.UI.TmdbPrompt do
  @moduledoc """
  The empty block Home draws when there is no TMDB token to search with.

  The owner's decision, 19 Sep: the reader brings their own TMDB token, and
  when there is none, *"show empty block on home for film and series and tell
  click to put your token."* `Kati.Sources.tmdb_key/0` now defaults to the
  reader's own key, so on a fresh install every film and series search answers
  `{:error, :no_api_key}` until one is pasted. Without this, the first a reader
  heard of it was a search that came back empty — which reads as a catalogue
  with nothing in it, not as a setting they have not made yet.

  A door and not a wall: the block sits under the search field and the rest of
  Home works around it, because hand-typed titles, the calendar and every other
  section need no token at all. It disappears the moment a usable key exists —
  `Kati.Media.Tmdb.usable?/0`, read in the screen's own `load/1`.
  """
  use Gettext, backend: Kati.Gettext

  import Mob.Sigil

  @doc "Nothing when a key is usable; the block when it is not."
  @spec block(boolean() | nil) :: map()
  def block(true), do: ~MOB"<Spacer size={0} />"

  def block(_not_ready) do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.card([
        Kati.UI.SettingsList.row(
          Kati.UI.SettingsList.icon_tile("movie"),
          Kati.UI.SettingsList.body(
            gettext("Add your TMDB token"),
            gettext("Kati needs it to find films and series. Free, and takes a minute.")
          ),
          Kati.UI.SettingsList.trailing(Kati.UI.SettingsList.chevron()),
          rule: false,
          on_tap: {self(), :add_tmdb_token}
        )
      ])}
      <Spacer size={18} />
    </Column>
    """
  end

  @doc """
  Where the block leads: screen 80, where the token field is.

  `back` is the word the pill on screen 80 says — the page it returns to.
  Without it the pill fell back to screen 80's own *Settings*, which is not
  where a reader who came from Home or the first run goes back to.
  """
  @spec open(Mob.Socket.t(), String.t()) :: Mob.Socket.t()
  def open(socket, back),
    do: Mob.Socket.push_screen(socket, Kati.Screens.DataSources, %{back: back})
end
