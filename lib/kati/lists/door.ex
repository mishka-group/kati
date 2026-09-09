defmodule Kati.Lists.Door do
  @moduledoc """
  Opening the *Add to list* sheet, from wherever the reader is.

  Board **334**: *"Same slot, same glyph, same label on both — and on 66, 74 and
  76, whose controls currently push the index carrying nothing. One control, one
  gesture, four pages."*

  Before this there were seven such controls on six screens and one of them
  added anything. `open/3` is what makes the other six mean the same thing: the
  member the page is about goes with the push, so the sheet knows its subject
  and its ticks arrive populated.
  """

  @doc """
  Push the sheet over the page, carrying what it is about.

  `member` is `{kind, id}` — `Kati.Lists.Membership.member/1`'s own shape — and
  `title` is the name the sheet puts in its header. A page with no member to
  name pushes nothing at all rather than a sheet that would write to a row the
  reader never chose, which is `Kati.ScreenWriteTargetTest`'s rule.
  """
  @spec open(Mob.Socket.t(), {atom(), String.t()} | nil, String.t() | nil) :: Mob.Socket.t()
  def open(socket, nil, _title), do: socket

  def open(socket, {_kind, nil}, _title), do: socket

  def open(socket, member, title) do
    Mob.Socket.push_screen(socket, Kati.Screens.AddToList, %{member: member, title: title})
  end

  @doc """
  The same door, in Persian.

  Board 337 exists because 289 sent «افزودن به فهرست» to the Lists INDEX while
  182 ruled for English that it opens a sheet over the page you are on — *"the
  two locales teach two different gestures for one action"*, which is the
  failure 254 flags by name. Same act, same shape, one language over.
  """
  @spec open_fa(Mob.Socket.t(), {atom(), String.t()} | nil, String.t() | nil) :: Mob.Socket.t()
  def open_fa(socket, nil, _title), do: socket

  def open_fa(socket, {_kind, nil}, _title), do: socket

  def open_fa(socket, member, title),
    do: Mob.Socket.push_screen(socket, Kati.Screens.AddToListFa, %{member: member, title: title})

  @doc """
  Push the sheet over a selection, the way board 146's *Add to list* pill does.

  An empty selection pushes nothing: the pill is drawn live only when something
  is selected, and a sheet acting on nothing has no tick that could mean
  anything.
  """
  @spec open_many(Mob.Socket.t(), [{atom(), String.t()}]) :: Mob.Socket.t()
  def open_many(socket, []), do: socket

  def open_many(socket, members),
    do: Mob.Socket.push_screen(socket, Kati.Screens.AddToList, %{members: members})

  @doc """
  A tracked title's member tuple, from the shape a screen already holds.

      iex> Kati.Lists.Door.title_member(%{tracked_id: "abc"})
      {:tracked_title, "abc"}

      iex> Kati.Lists.Door.title_member(%{title: "Blue Hour"})
      nil
  """
  @spec title_member(map()) :: {atom(), String.t()} | nil
  def title_member(%{tracked_id: id}) when is_binary(id), do: {:tracked_title, id}
  def title_member(%{id: id}) when is_binary(id), do: {:tracked_title, id}
  def title_member(_drawn), do: nil
end
