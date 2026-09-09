defmodule Kati.Onboarding do
  @moduledoc """
  Whether the first-run sequence has been completed, and what to open first.

  ## Why this exists

  Screens 53, 26 and 38 are the first-run sequence, and all three were drawn,
  built and unreachable: `Kati.App.navigation/1` named `Kati.Screens.Home` as
  the stack root unconditionally, so a fresh install went straight to a home
  page for a library that does not exist yet. The three screens could only be
  seen from `Kati.Screens.Gallery`, which is a development scaffold.

  The order is the drawings' own. 53's caption calls it "the first thing the
  app asks, before anything else can be worded" — it has to come first,
  because it decides the writing direction every later screen is laid out in.
  26's caption says "four steps, and the second one is this". 38 draws the
  remaining steps, and its own moduledoc records that it renders steps 1, 3
  and 4 stacked because the drawing does.

  ## Why a flag rather than inferring it

  "Has the user finished onboarding" is not the same question as "is the
  database empty", and answering the second in place of the first is how a
  first run gets shown twice. Someone who picks two sections, declines to add
  a title and lands on Home has completed the sequence and has no rows; so has
  someone who later clears their watch history. Neither should be asked again.

  The flag lives in `Mob.State`, the same DETS-backed store the theme choice
  uses, so it survives a restart without needing a table of its own — and it
  is deliberately not in `kati.db`, because restoring a backup from another
  device must not be able to re-trigger a first run on this one.
  """

  @key :onboarding_complete

  @doc """
  Whether the first-run sequence has been completed.

  Defaults to `false`, so a store that has never been written — a fresh
  install — reports a first run rather than silently skipping it.
  """
  @spec complete?() :: boolean()
  def complete? do
    case Mob.State.get(@key, false) do
      true -> true
      _ -> false
    end
  end

  @doc "Records that the first-run sequence has been finished."
  @spec complete!() :: :ok
  def complete! do
    Mob.State.put(@key, true)
    :ok
  end

  @doc """
  Clears the flag, so the next launch runs onboarding again.

  Exists for the tests and for a future *Reset* row; nothing in the app calls
  it, and nothing should call it as a side effect of clearing data.
  """
  @spec reset!() :: :ok
  def reset! do
    Mob.State.put(@key, false)
    forget_step!()
    :ok
  end

  @doc """
  The screen `Kati.App.navigation/1` opens the stack on.

  On a first run that is the step the run last REACHED — see `step/0` — and
  afterwards the shell root for the locale the user chose, which is
  `Kati.Screens.HomeFa` for `:fa` and `Kati.Screens.Home` for `:en`. Reading
  the locale here rather than always naming `Kati.Screens.Home` is what makes
  the choice made on 53 survive the app being closed.
  """
  @spec first_screen() :: module()
  def first_screen do
    if complete?(), do: shell_root(Kati.Locale.current()), else: screen_for_step(step())
  end

  @doc "The root screen for a locale."
  @spec shell_root(atom()) :: module()
  def shell_root(:fa), do: Kati.Screens.HomeFa
  def shell_root(_), do: Kati.Screens.Home

  @step_key :onboarding_step

  @steps [:language, :welcome, :sections, :loudness, :first_title]

  # `:finish` is what the three-step run recorded for its last step, and an
  # install interrupted on it is still out there. Mapped rather than kept in
  # `@steps`, so it resumes at the last step of the five rather than being
  # sent back to the language question — which is the one thing `step/0`
  # exists to prevent.
  @retired %{finish: :first_title}

  @doc """
  The first-run step this install last reached.

  ## Why the run is resumable at all

  A first run is the one part of the app a person cannot skip, and it is also
  the part they are most likely to be interrupted during — it happens in the
  first minute, on a new phone, usually while doing something else. Killed
  after picking a language and their sections, they used to come back to
  screen 53 and be asked both again. Answers already given were kept
  (`Kati.Locale.put/1` and `Kati.Sections.put/1` both write at the moment of
  the answer, not at the end), so the app had the answers and asked anyway,
  which is worse than not having them: it says the first thing you told it did
  not count.

  ## Why the step is recorded on ARRIVAL, not on departure

  Recording on departure answers "which step did you finish", and resuming
  from that lands on the step AFTER the one that was interrupted — skipping
  the one the person was actually looking at. Recording on arrival answers
  "which step were you on", which is the question a resume has to answer.

  Defaults to `:language`, so a store that has never been written — a fresh
  install — starts at the beginning rather than somewhere in the middle.
  """
  @spec step() :: atom()
  def step do
    case Mob.State.get(@step_key) do
      s when s in @steps -> s
      s when is_map_key(@retired, s) -> Map.fetch!(@retired, s)
      _never_recorded -> :language
    end
  end

  @doc """
  Record that the run has reached `step`.

  Never moves BACKWARDS. Screens mount for reasons other than a person walking
  forwards — the back gesture is one, and `Mob` remounting a screen is
  another — and a resume that could be dragged back a step by either would be
  a worse bug than no resume at all.
  """
  @spec reached!(atom()) :: :ok
  def reached!(step) when step in @steps do
    if position(step) > position(step()) do
      Mob.State.put(@step_key, step)
    end

    :ok
  end

  @doc """
  The screen a first-run step opens, in the locale the reader chose.

  ## This was deliberately NOT locale-aware, and the comment saying so was right

  Until 164, 165 and 166 were drawn, the Persian half of this table did not
  exist. Artboard 137 is named "onboarding" and reads like the mirror of 38;
  it is not — its own moduledoc says *"structurally this is
  `Kati.Screens.PickSections` (screen 26) read in Persian"*. Routing the last
  step there would have sent a Persian run back to the sections question and
  stranded it, because 137's ادامه pill carried **no `on_tap` at all**: there
  was no Persian step four to push it to, and *"a dead button reads as a bug
  where an untranslated screen reads as unfinished, which is the truth."*

  So a Persian run walked the English drawings for the middle of the sequence
  and it looked exactly as bad as that sounds — screen 38 mirrored, with
  `?How should we tell you` and `.add the rest whenever` punctuated on the
  wrong side. That is #91's fourth criterion, and this table is what closes
  it.

  ## Five steps, because 38 draws three panels in one scroll

  Screen 38 stacks the welcome, the loudness question and the first-title
  prompt in a single page — which is why `Kati.ScreenTapSweepTest` once found
  `finish` on two nodes at once, and why the flow map (134) has named the split
  as a build task since it was drawn. `D-33` delivered the six boards that
  split it, and the run is now five addressable steps in either script.

  137 finally sits where it belongs: it is Persian screen 26, so it is the
  Persian `:sections` step, and its pill has somewhere to go.
  """
  @spec screen_for_step(atom(), :en | :fa) :: module()
  def screen_for_step(step, locale \\ nil) do
    case {step, locale || Kati.Locale.current()} do
      {:welcome, :fa} -> Kati.Screens.OnboardingWelcomeFa
      {:welcome, _en} -> Kati.Screens.OnboardingWelcome
      {:sections, :fa} -> Kati.Screens.OnboardingFa
      {:sections, _en} -> Kati.Screens.PickSections
      {:loudness, :fa} -> Kati.Screens.OnboardingLoudnessFa
      {:loudness, _en} -> Kati.Screens.OnboardingLoudness
      {:first_title, :fa} -> Kati.Screens.OnboardingFirstTitleFa
      {:first_title, _en} -> Kati.Screens.OnboardingFirstTitle
      # The language question is the one step with no Persian mirror, and it
      # should not have one: screen 53 asks in both scripts at once, because
      # nobody who needs it can be assumed to read the other.
      {_language, _locale} -> Kati.Screens.LanguagePick
    end
  end

  defp position(step), do: Enum.find_index(@steps, &(&1 == step)) || 0

  @doc """
  Forget the recorded step, so the next run starts at the beginning.

  For `reset!/0` and for tests. `reset!/0` calls it, because a first run that
  is re-armed while still remembering it reached the last step would open on
  the last step and finish immediately.
  """
  @spec forget_step!() :: :ok
  def forget_step! do
    Mob.State.delete(@step_key)
    :ok
  end
end
