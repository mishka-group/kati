defmodule Kati.ScreenInboxEmptyTest do
  @moduledoc """
  Board 260 — screen 05 with nothing followed.

  A release inbox is the output of a watcher, and a device that follows
  nothing has no output. What it used to draw instead was `drawn_inbox/0`:
  `Kati.Library.Sample`'s **Out now** rows and this module's three frozen
  **Coming up** lines — *The Long Hollow — S2E6 · Lumen+ · 20:00*, *Vellum · In
  cinemas*, *Nightbirds — Season 2*. So the one page in Kati whose entire job
  is to say what is new opened, on a fresh install, on three things that were
  not.

  That is the audit's sentence about a different screen, and board
  260 is the design's answer to this one.

  ## The card became a sentence

  The board's own note, and the ruling this file holds: the watcher card pairs
  a count with `last checked 18:02` and `every 6h`, and *"setting the count to
  0 and keeping the meta line would put a live number beside two frozen ones in
  the same breath, which is how a demo quietly becomes a lie."*

  Both halves of that meta line are real now — board 314 built the store and
  `watcher_line/0` reads it — so the sentence is no longer true of the LINE. It
  is still true of the shape: with nothing followed there is no count to pair
  them with, and a card that reports a cadence for work with no subject is
  chrome pretending to be information. So the empty card is two sentences and a
  cog, and the cog survives because it is the only thing on this page pointing
  at screen 25.

  ## It offers, and the sentence says why the offer is what it is

  The ink action opens screen 06 rather than the shelf, and that is the board's
  own reasoning rather than a preference: this page is the watcher's output, so
  what fills it is putting a title into the followed set. The shelf is the
  quiet alternative underneath.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Media.CachedTitle
  alias Kati.Media.TrackedTitle
  alias Kati.Screens.Inbox

  @prefix "inbox-empty-"

  setup do
    on_exit(fn ->
      Kati.Repo.query!("DELETE FROM tracked_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
      Kati.Repo.query!("DELETE FROM cached_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
    end)

    :ok
  end

  describe "with nothing followed" do
    test "the read answers nothing, which is the gate" do
      refute Inbox.releases()
      assert Inbox.inbox().nothing_followed?
    end

    test "and none of the drawing's releases are on the page" do
      words = text(mount_screen(Inbox))

      for invented <- ["The Long Hollow", "Vellum", "Nightbirds"] do
        refute words =~ invented,
               "screen 05 drew #{invented} — a release out of the drawing that nobody follows"
      end
    end

    test "it says the watcher is running and has nothing to watch" do
      words = text(mount_screen(Inbox))

      assert words =~ "Nothing followed yet" or words =~ "NOTHING FOLLOWED YET"
      assert words =~ "The watcher is running"
      assert words =~ "It has nothing to watch yet. Follow a show and it starts here."
    end

    test "and the meta line is gone rather than reporting a cadence for nothing" do
      words = text(mount_screen(Inbox))

      # The board's note, held as a run: no `every 6h` and no `checked …`
      # beside a page with no count on it.
      refute words =~ "every 6h"
      refute words =~ "never checked"
      refute words =~ "Out now"
      refute words =~ "Coming up"
    end

    test "it offers the one door that fills the page, and names the other" do
      words = text(mount_screen(Inbox))

      assert words =~ "Nothing new, because nothing is followed"
      assert words =~ "This page is the watcher's output."
      assert words =~ "Add a title"
      assert words =~ "or open the shelf"
    end

    test "and both doors go where the board says" do
      socket = Mob.Socket.new(Inbox)

      # Screen 06, not the shelf: it is the only door that puts anything into
      # the followed set, which is what this page is the output of.
      {:noreply, added} = Inbox.handle_tap(:add_title, socket)
      assert {:push, Kati.Screens.AddTitle, _} = Map.get(added.__mob__, :nav_action)

      {:noreply, shelf} = Inbox.handle_tap(:open_shelf, socket)
      assert {:push, Kati.Screens.Library, _} = Map.get(shelf.__mob__, :nav_action)

      # The cog is the only thing on the empty page pointing at screen 25.
      {:noreply, watcher} = Inbox.handle_tap(:open_watcher, socket)
      assert {:push, Kati.Screens.ReleaseWatcher, _} = Map.get(watcher.__mob__, :nav_action)
    end

    test "Mark all is not drawn, because there is nothing to mark" do
      # Board 260 draws `Mark all` in its header, and it was drawn here without
      # a tap: a pill that looks pressable and does nothing (N52-C). With
      # nothing followed there is nothing to mark all OF, so it is gone.
      words = text(mount_screen(Inbox))

      refute words =~ "Mark all"
    end

    test "and the subtitle is gone, because it counted sections that are not drawn" do
      words = text(mount_screen(Inbox))

      refute words =~ "0 out now"
      refute words =~ "coming up"
    end
  end

  describe "once something IS followed" do
    test "the page stops being board 260 and becomes the inbox proper" do
      follow!()

      assert Inbox.releases(), "a followed title did not reach the read"
      refute Map.get(Inbox.inbox(), :nothing_followed?)

      words = text(mount_screen(Inbox))

      # The sections come back — this is what makes the empty branch a RESULT
      # rather than the only thing the screen can draw.
      # The eyebrows upcase, as every eyebrow in the app does.
      assert words =~ "OUT NOW"
      assert words =~ "COMING UP"
      refute words =~ "The watcher is running"
    end
  end

  defp follow!(title \\ "Estuary Nights") do
    Ash.create!(CachedTitle, %{
      source: :tmdb,
      source_id: @prefix <> title,
      kind: :tv,
      title: title,
      fetched_at: Kati.Time.now()
    })

    Ash.create!(TrackedTitle, %{
      source: :tmdb,
      source_id: @prefix <> title,
      kind: :tv,
      status: :watching
    })
  end
end
