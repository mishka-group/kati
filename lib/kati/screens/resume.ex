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

  # How long the courier waits for the screen that asked to be left to go.
  # Generous: it is bounded only so a screen that announced and then did not
  # navigate cannot leave a process parked for ever.
  @courier_ms 5_000

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
    message = {:kati, @topic, nil}

    if under_router?() do
      deliver_after_this_screen_dies(message)
    else
      send(self(), message)
    end

    :ok
  end

  # ── Delivery ──────────────────────────────────────────────────────────────
  #
  # `send(self(), …)` was the whole mechanism until mob 0.8.0, and the paragraph
  # above headed *Mob's own mechanism, not a fork of it* is the record of why it
  # worked: ONE `Mob.Screen` GenServer held `{module, socket, nav_history}` and
  # a pop swapped `module`, so a message queued to that process while it was
  # answering the back tap was dispatched to the screen underneath.
  #
  # **0.8.0 gave every screen its own process** (MOB-146/MOB-129: the popped-to
  # screen stays resident so returning to it diffs rather than re-mounts, and
  # `Mob.Router` tracks screens by pid). `self()` is now the screen being LEFT,
  # for its last few milliseconds, and nothing reaches the one underneath. The
  # failure is the original defect returning verbatim and just as quietly: add
  # a title on screen 06, press back, and screen 03 still says `0 titles`,
  # while switching roots at the dock shows it — which is exactly how this
  # looked before `Resume` existed. Found on a Pixel 9a on 11 September, during
  # the 0.7.20 → 0.8.1 upgrade; every host test still passed, because
  # `Mob.ScreenCase` runs a screen in the TEST process and `self()` is right
  # there.
  #
  # ## Where the message has to go instead
  #
  # `Mob.Router`'s catch-all `handle_info/2` forwards anything it does not
  # recognise to `state.current.pid` — so a message sent to the OWNER lands on
  # whichever screen is current when the owner reads it. That makes the whole
  # problem one of ordering, and the ordering is available without a timer:
  #
  #   1. the leaving screen's handler returns, and mob sends the owner
  #      `{:nav_action, {:pop}, self()}`;
  #   2. the owner applies it: `stop_screen/2` FIRST, which is a synchronous
  #      `GenServer.stop/3`, and only then `make_current/3` on the screen
  #      underneath.
  #
  # So the leaving screen's death happens INSIDE the owner's handling of the
  # pop. Anything sent to the owner at that moment queues behind the work in
  # progress and is read once the pop is complete — by which time
  # `state.current` is the screen that is now on top.
  #
  # A courier process waits for that death and sends. It is three lines and it
  # outlives nothing: it is created by one navigation, exits on the `:DOWN` it
  # is waiting for, and holds no state — which is why it does not offend
  # `Kati.SupervisionRuleTest`'s rule that a screen may not outlive itself. The
  # alternatives were worse: `Process.send_after/3` is a timer and the rule
  # names it, a `terminate/2` on Kati's macros would miss the screens that
  # `use Mob.Screen` directly, and monkey-patching `Mob.Screen` is the fork
  # this module exists to avoid.
  defp deliver_after_this_screen_dies(message) do
    owner = owner()
    screen = self()

    spawn(fn ->
      ref = Process.monitor(screen)

      receive do
        {:DOWN, ^ref, :process, ^screen, _reason} -> send(owner, message)
      after
        # The screen did not die, so no navigation happened and nothing is
        # waiting to be told. Exit rather than deliver: a `:resumed` that
        # arrives seconds later lands on whatever the reader has since opened.
        @courier_ms -> :ok
      end
    end)
  end

  # `:mob_screen` is `Mob.Router`'s registered name — it takes it in `init/1`
  # so the native layer can address the UI without holding a pid, and
  # `Kati.Screens.Root`'s own moduledoc already documents `send(:mob_screen,
  # {:kati, topic, payload})` as the way to push to whatever screen is up.
  # This is the same address, used from inside the app rather than from outside
  # it.
  #
  # NOT `$ancestors`. That was the first version and it is why this arrived
  # broken on the device while every host test passed: `proc_lib` records a
  # REGISTERED PARENT BY NAME, so the head of the list is the atom
  # `:mob_screen` and not a pid. A `when is_pid(owner)` guard therefore fell
  # through to its `self()` fallback, the courier sent the message back to the
  # dead screen's own pid, and the pop still did not refresh — the same
  # symptom, one layer down. Logged off the device to find it.
  defp owner do
    cond do
      # The device, and every `:render` router: `Mob.Router.init/1` takes the
      # name when render_mode is `:render`.
      is_pid(Process.whereis(:mob_screen)) -> :mob_screen
      # A `:no_render` router — `Mob.Router.start_link/3`, which is what a test
      # gets. It registers no name, so its pid is the head of `$ancestors`.
      true -> ancestor()
    end
  end

  defp ancestor do
    case Process.get(:"$ancestors") do
      [parent | _] when is_pid(parent) or is_atom(parent) -> parent
      _ -> self()
    end
  end

  # Whether this process IS a screen server, rather than a test process that
  # called `mount/3` directly. `Mob.ScreenCase` does the latter — it runs the
  # screen inline and reads the mailbox — so on the host `send(self(), …)` is
  # both correct and what every `Kati.ResumeTest` assertion is written against.
  defp under_router?, do: Process.get(:"$initial_call") == {Mob.Screen.Server, :init, 1}

  @doc """
  The topic, so a screen's `handle_kati/3` clause and this cannot drift apart.

      iex> Kati.Screens.Resume.topic()
      :resumed
  """
  @spec topic() :: atom()
  def topic, do: @topic
end
