defmodule Kati.Screens.Resume do
  @moduledoc """
  Telling the screen underneath that it is about to be looked at again.

  ## The defect

  A popped-to screen never re-reads. `Mob.Screen`'s `{:pop}` restores the
  socket it saved on the way in (`deps/mob/lib/mob/screen.ex`, `apply_nav_action/3`)
  and `mount/3` does not run again, so **every write that ends in a back tap is
  invisible until you leave the stack**. Add a title on screen 06 and press
  back: the Library still says what it said. Tap a recommendation on screen 11
  and press back: seven titles, and the shelf shows six. Switch roots at the
  dock and it re-mounts, which is why this looks intermittent and is not.

  ## Mob's own mechanism, not a fork of it

  Mob has no resume callback and `deps/mob` is a hex dependency rather than a
  vendored file, so there is no `KATI-BEGIN` fence for it and forking it is not
  a thing to do quietly. It turns out not to be needed.

  `Mob.Screen`'s GenServer holds `{module, socket, nav_history, render_mode}`
  and dispatches each message to the module **currently** in that state
  (`forward_to_screen/2`). The navigation for a message is applied when its
  handler returns. So a message sent to `self()` while screen 11 is answering
  its back tap is still in the mailbox when the pop is applied, and is
  delivered to screen 03.

  That is not a trick: it is exactly what `Kati.Screens.Root`'s moduledoc
  describes `{:kati, topic, payload}` for — *addressing is by topic, not by
  identity*, sent to whichever screen happens to be alive, and the ones that do
  not care drop it. Here the screen that happens to be alive is, by
  construction, the one that is about to be shown.

  ## Opt-in, and why it must be

  Re-running `load/1` wholesale would be wrong. A screen's socket holds UI state
  as well as store state — screen 03's shelf tab and its status filter, screen
  11's chip, screen 04's chosen season — and a reader who filters to *Finished*,
  opens a title and comes back has not asked for the filter to go. So `:resumed`
  is a topic like any other: a screen implements `handle_kati/3` for it, refreshes
  what it read and keeps what the reader chose, and a screen that implements
  nothing behaves exactly as it did.

  ## What this is not

  It is not a fix for the two roots. `Kati.Screens.Home` and
  `Kati.Screens.Library` are reached through the dock as well as through a pop,
  and the dock already re-mounts. It is not a subscription either — nothing is
  registered, nothing outlives the message, and `Kati.SupervisionRuleTest`'s
  rule about screens not outliving themselves is untouched: this is one `send/2`
  to the process doing the sending.
  """

  @topic :resumed

  @doc """
  Pop, and tell whatever is underneath that it is coming back.

  Every back control in the app goes through here rather than through
  `Mob.Socket.pop_screen/1` directly, so the answer does not depend on whether
  the screen being left happens to have written anything — it usually cannot
  know. A read on the way back is a handful of local SQLite queries; a shelf
  that disagrees with the database is a bug report.

  The order matters and is the whole mechanism: the message is queued BEFORE
  the socket carrying `{:pop}` is returned, so it is dispatched after the pop
  has been applied and lands on the screen that is now on top.

  ## And the theme goes back with you

  `Kati.Theme.activate/0` first, and it is here for the same reason the read
  is: the screen being popped to is not remounted, so nothing else runs.

  Seven boards are drawn in the dark colourway — 28, 29, 68, 131, 157 and the
  two Persian ones — and each sets the dark palette in its own `load/1`.
  `Mob.Theme.set/1` is global and popping does not remount, so opening one
  left **the whole app dark** until some other pushed screen mounted and
  `Kati.Screens.Pushed`'s macro re-activated the preference. A reader who
  looked at screen 157 got a dark Settings, a dark Library and a dark Home,
  and nothing they could press to undo it (MOVIES-AND-TV.md #30).

  One call, at the one place every back control in the app already goes
  through, rather than seven screens each remembering to put it back. A screen
  whose own palette IS dark re-asserts it on `handle_kati(:resumed, …)` — the
  same hook it would use to re-read anything else.
  """
  @spec pop(Mob.Socket.t()) :: Mob.Socket.t()
  def pop(socket) do
    Kati.Theme.activate()
    Kati.Locale.activate()
    announce()
    Mob.Socket.pop_screen(socket)
  end

  @doc """
  Queue the message without popping.

  For a screen that navigates some other way — `reset_to/3`, a `pop_to` — and
  still wants whatever it lands on to re-read.
  """
  @spec announce() :: :ok
  def announce do
    send(self(), {:kati, @topic, nil})
    :ok
  end

  @doc """
  The topic, so a screen's `handle_kati/3` clause and this cannot drift apart.

      iex> Kati.Screens.Resume.topic()
      :resumed
  """
  @spec topic() :: atom()
  def topic, do: @topic
end
