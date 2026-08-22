defmodule Kati.ScreenSweep do
  @moduledoc """
  Discovery and dispatch helpers shared by the two screen sweeps.

  `Kati.ScreenRenderSweepTest` mounts and renders every screen;
  `Kati.ScreenTapSweepTest` then taps everything those renders drew. Both need
  the same three answers, and each one has a wrong version that looks right:

    * **which modules are screens** — a hand-maintained list rots the day
      someone adds a screen, and a sweep that silently covers 40 of 63 screens
      is worse than no sweep. Derived from the compiled app instead.

    * **which taps a screen drew** — read off the rendered tree, so the sweep
      covers exactly the controls a user can see, and grows on its own when a
      screen grows a button.

    * **which callback a tap actually reaches** — see `root_behaviour?/1`.

  Loaded with `Code.require_file/2` rather than living in `test/support/*.ex`,
  because `mix.exs` has no `elixirc_paths` override for `:test` and adding one
  is not this file's business.
  """

  @doc """
  Every compiled module that is a screen: `Kati.Screens.*` exporting the
  `Mob.Screen` pair (`mount/3` and `render/1`).

  Read from the app's own module list, so a new screen file joins both sweeps
  the moment it compiles. The list also contains helpers that live under the
  same namespace but are not screens — `Kati.Screens.Root` and
  `Kati.Screens.Pushed` are macros, `Kati.Screens.Fa` and
  `Kati.Screens.ViewSwitcher` are shared chrome, `*.Sample` modules are
  fixtures — and the `mount/3` + `render/1` pair is what separates them.
  """
  @spec screens() :: [module()]
  def screens do
    _ = Application.load(:kati)

    (Application.spec(:kati, :modules) || [])
    |> Enum.filter(&screen?/1)
    |> Enum.sort()
  end

  @doc "Whether `module` is a Kati screen. See `screens/0`."
  @spec screen?(module()) :: boolean()
  def screen?(module) do
    String.starts_with?(Atom.to_string(module), "Elixir.Kati.Screens.") and
      Code.ensure_loaded?(module) and
      function_exported?(module, :mount, 3) and
      function_exported?(module, :render, 1)
  end

  @doc """
  Every behaviour `module` declares.

  `__info__(:attributes)` is a keyword list with **repeated** `:behaviour`
  keys — one entry per `@behaviour` — so `attributes[:behaviour]` and
  `Keyword.get/2` return only the FIRST one. Both `Kati.Screens.Root` and
  `Kati.Screens.Pushed` expand to `use Mob.Screen` before their own
  `@behaviour Kati.Screens.Root`, so the single-value lookup answers
  `Mob.Screen` for every screen in the app and the `Kati.Screens.Root` half of
  the classification vanishes. A sweep built on that reports a clean run over
  the wrong callback.
  """
  @spec behaviours(module()) :: [module()]
  def behaviours(module) do
    module.__info__(:attributes)
    |> Keyword.get_values(:behaviour)
    |> List.flatten()
  end

  @doc """
  Whether a tap on `module` is answered by `handle_tap/2`.

  True for the `Kati.Screens.Root` and `Kati.Screens.Pushed` macros, whose
  generated `handle_info({:tap, tag}, socket)` routes on to
  `Kati.Screens.Root.rescue_tap/3` and from there to the screen's
  `handle_tap/2`. False for a hand-rolled `use Mob.Screen` screen — those
  match taps in `handle_info/2` directly and define no `handle_tap/2` at all,
  so asking one for `handle_tap/2` produces an `UndefinedFunctionError` that
  says nothing about the screen.
  """
  @spec root_behaviour?(module()) :: boolean()
  def root_behaviour?(module), do: Kati.Screens.Root in behaviours(module)

  @doc """
  Tags the shell owns, which never reach the screen's own tap handler.

  `Kati.Screens.Root`'s macro answers `:fab` and `root_*` itself,
  `Kati.Screens.Pushed`'s answers `:back`, and the hand-rolled Persian mirrors
  answer the same set in their own `handle_info/2`. They are intercepted
  upstream of `handle_tap/2`, so a sweep that hands them to `handle_tap/2`
  reports a missing handler for a control that works.
  """
  @spec shell_tag?(atom()) :: boolean()
  def shell_tag?(tag) do
    tag in [:fab, :back] or String.starts_with?(Atom.to_string(tag), "root_")
  end

  @doc "Mount `module` with no params, as a fresh push of the screen."
  @spec mount(module()) :: {:ok, Mob.Socket.t()} | {:error, String.t()}
  def mount(module) do
    case safely(fn -> module.mount(%{}, %{}, Mob.Socket.new(module)) end) do
      {:ok, {:ok, %Mob.Socket{} = socket}} ->
        {:ok, socket}

      {:ok, other} ->
        {:error, "mount/3 returned #{inspect(other, limit: 3)} instead of {:ok, socket}"}

      {:error, message} ->
        {:error, message}
    end
  end

  @doc """
  Every distinct `on_tap` tag the tree draws, in the order it draws them.

  `on_tap` carries `{screen_pid, tag}`; `nil` means "not tappable" and is the
  one thing a control can carry that this must not collect — the selected
  segment of a switcher carries exactly that.
  """
  @spec tap_tags(map()) :: [atom()]
  def tap_tags(tree) do
    tree
    |> Mob.ScreenCase.flatten()
    |> Enum.flat_map(fn node ->
      case Map.get(node, :props) || %{} do
        %{on_tap: {pid, tag}} when is_pid(pid) and is_atom(tag) -> [tag]
        _ -> []
      end
    end)
    |> Enum.uniq()
  end

  @doc """
  Every node type Kati can actually draw.

  `Mob.ScreenCase.renderable_types/0` is mob's own set, read off
  `priv/tags/{ios,android}.txt`, and it is right for a stock bridge. Kati's is
  not stock: `K-18 anchored-node` adds a real `MobAnchored` to
  `MobBridge.kt`, which is what `Kati.UI.Menu` — and so every overflow menu in
  the app — is built on.

  Named once, here, so the exception is a fact about the bridge rather than a
  string repeated at each assertion. `Kati.ComponentPolicyTest` is what keeps
  it true: it fails if K-18 leaves the bridge.
  """
  @spec renderable_types() :: MapSet.t(atom())
  def renderable_types, do: MapSet.put(Mob.ScreenCase.renderable_types(), :anchored)

  @doc """
  Run `fun` with `locale` active, restoring the previous locale afterwards.

  Costly enough to be worth hoisting: `Kati.Locale` lives in `Mob.State`, which
  is a DETS table, so each switch is a `GenServer.call` and a disk write. Wrap
  a whole pass over the screens in one of these — never a single tap — or the
  sweep spends its time writing a two-atom setting to disk. `per_locale/2` is
  that shape.

  Restores the palette too — see `with_theme/1`. A pass mounts screens, and a
  mount installs a theme; both are globals this has to hand back.
  """
  @spec with_locale(:en | :fa, (-> result)) :: result when result: term()
  def with_locale(locale, fun) do
    previous = Kati.Locale.current()
    Kati.Locale.put(locale)

    try do
      with_theme(fun)
    after
      Kati.Locale.put(previous)
    end
  end

  @doc """
  Run `fun` and put back the palette that was installed when it started.

  `Mob.Theme.set/1` is `Application.put_env(:mob, :theme, …)` — **one global
  for the whole run**, and not one `Mob.ScreenCase` resets between tests the
  way it resets `Mob.State`.

  It is not the mounts that leak. Mounting all 63 screens ends light, because
  the last screen mounted resolves the stored choice and nothing in a sweep
  stores one. It is the **taps**. Screen 24 draws an Auto/Light/Dark control
  and screen 62 draws its Persian twin, a sweep dispatches every tag every
  screen drew, and `Kati.Screens.Settings.put_choice/1` does what a real tap
  does: stores the choice and calls `Kati.Theme.activate/0`. So a tap pass ends
  with `:theme_Dark` having installed `Kati.Theme.dark/0`, and the stored
  choice dies with the test while the palette does not.

  That is old, and until this round it was harmless: screen markup wrote
  `Kati.Theme.card(:light)` and `0xFFFBFAF8`, neither of which reads the
  installed theme, so nothing downstream could tell. Now that the screens name
  their colours through `Kati.Theme.Palette`, whose zero-arity tokens resolve
  against whatever palette is installed, the leak finally has a symptom — an
  order-dependent failure in a file that never mentions the theme.
  `Kati.MealsRoutesTest`'s "wiring the two new controls added a handler and no
  ink" was reading `Kati.Theme.card(:dark)` on roughly half the seeds.

  Restoring what was installed rather than forcing `Kati.Theme.light/0`: a
  caller that deliberately set a palette before the pass gets that one back,
  and a caller that set none is handed back Mob's neutral base, which
  `Kati.Theme.Palette.mode/0` reads as `:light`.

  The restore is at the end of the pass, never around a single mount or tap, so
  screens 28 and 29 still render in the dark palette their own `mount/3`
  installs and a tap on the theme control still repaints — this only stops the
  last one of those escaping the pass.
  """
  @spec with_theme((-> result)) :: result when result: term()
  def with_theme(fun) when is_function(fun, 0) do
    installed = Mob.Theme.current()

    try do
      fun.()
    after
      Mob.Theme.set(installed)
    end
  end

  @doc """
  Run `fun.(locale)` once per locale, with that locale active, and concatenate
  the lists it returns. One locale switch per pass.
  """
  @spec per_locale([:en | :fa], (:en | :fa -> [result])) :: [result] when result: term()
  def per_locale(locales, fun) do
    Enum.flat_map(locales, fn locale -> with_locale(locale, fn -> fun.(locale) end) end)
  end

  @doc """
  Call `fun`, turning any raise, throw or exit into `{:error, description}`.

  A sweep has to survive the first offender to report the rest of them, and a
  test that stops at screen 3 of 63 hides 60 screens' worth of answer.
  """
  @doc """
  Run `fun` with every database write it causes rolled back afterwards.

  **Every sweep that dispatches taps must go through this**, and the reason is
  a defect that took three files to notice.

  A sweep's whole method is to press every control every screen draws. Most
  controls navigate or set an assign; a few *commit* — screen 106's `Save
  goal`, screen 111's `Save reading`, screen 124's `Save the expense` — and
  those write a row and mean to. Unlike screens 70 and 73, whose saves no-op
  against an empty shelf, these need no prerequisite: a goal is a goal.

  The rows then outlive the sweep, and the screens that fall back to their
  drawing *only while their table is empty* — 104, 109, 111, 122 — stop drawing
  it. The failure lands on `Kati.ScreenDesignLiteralTest`, which never touched
  any of them, and only for the seeds that order the modules the wrong way
  round. Three separate sweeps build a push graph this way
  (`Kati.ScreenTapSweepTest`, `Kati.MealsRoutesTest`, `Kati.AppReachabilityTest`),
  so cleaning up in each one's `on_exit` is three chances to forget.

  A rolled-back transaction is exact where a `DELETE` list is a guess: it
  restores whatever was there, it needs no list of tables to maintain, and a
  sweep that starts writing to a new table is covered the day it does.
  `Kati.ScreenEmptyDatabaseTest.in_empty_database/1` uses the same shape for the
  mirror-image job.
  """
  @spec rolled_back((-> result)) :: result when result: term()
  def rolled_back(fun) when is_function(fun, 0) do
    {:error, {:rolled_back, result}} =
      Kati.Repo.transaction(fn -> Kati.Repo.rollback({:rolled_back, fun.()}) end)

    result
  end

  @spec safely((-> result)) :: {:ok, result} | {:error, String.t()} when result: term()
  def safely(fun) when is_function(fun, 0) do
    {:ok, fun.()}
  rescue
    error -> {:error, describe(:error, error, __STACKTRACE__)}
  catch
    kind, value -> {:error, describe(kind, value, __STACKTRACE__)}
  end

  # Long enough for a `KeyError`'s key and a `FunctionClauseError`'s name,
  # short enough that nine of them stay readable.
  @message_limit 300

  defp describe(kind, reason, stacktrace) do
    # Both halves of a formatted exception will happily print the arguments of
    # the failing call, and the second argument to `handle_tap/2` is a socket
    # holding the screen's entire sample dataset — several thousand characters
    # of assigns per offender. `format_banner/3` blames the stacktrace to get
    # them, so use the two-arity form; a stacktrace entry carries them in its
    # args list, so replace that with the arity before formatting.
    frames =
      stacktrace
      |> Enum.take(3)
      |> Enum.map_join("\n", &("         " <> Exception.format_stacktrace_entry(arity_only(&1))))

    kind
    |> Exception.format_banner(reason)
    |> String.trim_trailing()
    |> String.slice(0, @message_limit)
    |> Kernel.<>("\n" <> frames)
  end

  defp arity_only({module, fun, args, location}) when is_list(args),
    do: {module, fun, length(args), location}

  defp arity_only(entry), do: entry

  @doc """
  Render `module` in the locale that is active now, as `{:ok, socket, tree}`
  or `{:error, why}`.

  Does not switch the locale itself — see `with_locale/2` for why the switch
  belongs one loop further out.
  """
  @spec render(module()) :: {:ok, Mob.Socket.t(), term()} | {:error, String.t()}
  def render(module) do
    with {:ok, socket} <- mount(module),
         {:ok, tree} <- safely(fn -> module.render(socket.assigns) end) do
      {:ok, socket, tree}
    end
  end

  @doc """
  Every screen's mounted socket and the tags it drew, in `locale`.

  Screens that fail to mount or render contribute nothing —
  `Kati.ScreenRenderSweepTest` is what fails over those, and repeating its
  failure here would only bury the tap findings.
  """
  @spec drawn_taps(:en | :fa) :: %{module() => {Mob.Socket.t(), [atom()]}}
  def drawn_taps(locale) do
    # Memoised, because every tap check re-reads the same trees and mounting 63
    # screens twice over is the slow half of the sweep. `:persistent_term`
    # rather than the process dictionary or ETS: each ExUnit test runs in its
    # own process and `Mob.ScreenCase` restarts `Mob.State` around each one, so
    # a cache tied to either dies between the tests that share the work. The
    # trees only depend on code, which does not change inside a run.
    key = {__MODULE__, :drawn_taps, locale}

    case :persistent_term.get(key, :miss) do
      :miss ->
        taps = with_locale(locale, &draw_taps/0)
        :persistent_term.put(key, taps)
        taps

      taps ->
        taps
    end
  end

  defp draw_taps do
    for module <- screens(),
        {:ok, socket, tree} <- [render(module)],
        into: %{} do
      {module, {socket, tap_tags(tree)}}
    end
  end
end
