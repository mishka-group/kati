defmodule Kati.Screens.OnboardingFirstTitle do
  @moduledoc """
  Screen 163 — *Add your first title*, step 5 of five.

  The last step of the renumbering brief `D-33` asked for, and the one that
  makes #91's first criterion true: *a clean install walked end to end leaves a
  usable app, asserted by adding a title straight after*.

  ## A search, not a poster wall

  Board 163 draws four posters — *The Long Hollow*, *Ashfall*, *Marram*,
  *Nightbirds* — and the step used to offer exactly those. They are invented
  films: tapping one and pressing **Finish setup** put a title nobody can look
  up on the shelf, carrying a design photograph (`hollow71`) in
  `Kati.Media.CachedTitle.poster_path`, which Home, the Library and Up next
  then drew as though it were the film's own poster (N46).

  So the step is screen 06's search, in place: the same field, the same
  debounce (`Kati.Media.SearchDebounce`), the same `Kati.Media.Tmdb.search/1`
  rows and the same add disc, which writes through
  `Kati.Screens.AddTitle.add_at/2` — so a title added here is a TMDB title with
  TMDB's poster path, exactly as one added from the `+` button is. There is no
  list of suggestions before a keystroke, because `Kati.Media.Tmdb` has no
  trending call to fill one honestly; the empty field says what to do instead.

  The states a first run can be in are each drawn rather than implied:

    * **No TMDB token** — `Kati.UI.TmdbPrompt`'s block above the field, the
      door Home draws for the same state, opening screen 80.
    * **Offline, rate-limited, refused** — `Kati.Screens.AddTitle.search_notice/2`
      with `Kati.Media.Tmdb.message/1`'s sentence.
    * **Nothing found** — screen 06's card, and the by-hand row naming the
      query, which pushes screen 154: a title typed by hand has no poster at
      all rather than a borrowed one.

  ## What the board decides

  **Skip and Finish setup land on the same Home.** Board 139 sends a skip to
  the *Nothing chosen yet* page, but nobody reaches this step without having
  chosen sections, and that page's one action is *Choose sections* — it told
  a reader who had just answered that the answer did not register.
  `Kati.Screens.Home` draws 139 itself, only when no section is chosen and
  nothing is kept (`Kati.Screens.Home.nothing_kept?/1`). **Finish setup** adds
  nothing of its own: whatever the reader added is already on the shelf.
  """
  use Kati.Screens.Pushed, back: nil
  use Gettext, backend: Kati.Gettext

  # `back: nil` — the board draws no pill. Its back control is the row at
  # the foot of the page, "Back to loudness", which `back_row/1` builds. A
  # floating pill over this would be a second way back the design did not
  # draw, sitting on top of the step rail.

  alias Kati.Screens.AddTitle
  alias Kati.Screens.OnboardingWelcome
  alias Kati.Theme.Palette

  @doc """
  An empty search, and whether there is a TMDB token to search with.

  Nothing is added on mount and nothing is picked: the board draws a ticked
  tile, and reading that tick as a default is how a reader who pressed
  **Finish setup** without choosing used to be handed an invented film.
  """
  @impl true
  def load(socket) do
    Kati.Onboarding.reached!(:first_title)

    Mob.Socket.assign(socket,
      query: "",
      query_epoch: 0,
      results: [],
      searching?: false,
      search_error: nil,
      search_reason: nil,
      save_error: nil,
      tmdb_ready: Kati.Media.Tmdb.usable?()
    )
  end

  @doc false
  def content(assigns) do
    shown = AddTitle.positioned(assigns.results)

    assigns =
      assigns
      |> Map.put(:shown, shown)
      |> Map.put(:counted, Kati.Screens.OnboardingFirstTitle.count_label(assigns.query, shown))

    Kati.Screens.Pushed.page(~MOB"""
    <Column fill_width={true}>
      {OnboardingWelcome.rail(5)}
      <Text
        text={gettext("Add your first title")}
        text_size={28}
        max_font_scale={1.6}
        font_weight="bold"
        letter_spacing={-0.03}
        text_color={:on_surface}
      />
      <Spacer size={10} />
      <Text
        text={gettext("Pick something you are watching now — the calendar fills itself from there.")}
        text_size={13.5}
        line_height={1.55}
        text_color={Palette.ink_soft()}
      />
      <Spacer size={20} />
      {Kati.UI.TmdbPrompt.block(assigns.tmdb_ready)}
      {AddTitle.field(assigns.query, assigns.query_epoch)}
      {Kati.Screens.OnboardingFirstTitle.notice(assigns)}
      {AddTitle.save_notice(assigns.save_error)}
      {Kati.UI.eyebrow(assigns.counted)}
      {AddTitle.body(assigns.shown, assigns)}
      {AddTitle.by_hand(assigns.query)}
      <Spacer size={18} />
      {OnboardingWelcome.forward(gettext("Finish setup"), :finish)}
      <Spacer size={12} />
      <Box fill_width={true} on_tap={{self(), :skip}}>
        <Text
          text={gettext("Skip — I’ll add things later")}
          text_size={13}
          font_weight="semibold"
          text_color={Palette.sub()}
          text_align="center"
        />
      </Box>
      <Spacer size={18} />
      {OnboardingWelcome.back_row(gettext("Back to loudness"))}
    </Column>
    """)
  end

  @doc """
  The eyebrow over the results: `Search` before a query, the count after one.

  Screen 06's own rule and its own msgids — `Kati.Search.long_enough?/1` is
  the floor the search gates on, so the eyebrow cannot report a count for a
  search that was never made.

      iex> Kati.Locale.as(:en, fn -> Kati.Screens.OnboardingFirstTitle.count_label("", []) end)
      "Search"

      iex> Kati.Locale.as(:en, fn ->
      ...>   Kati.Screens.OnboardingFirstTitle.count_label("dark", [%{}, %{}])
      ...> end)
      "2 results"
  """
  @spec count_label(String.t(), [map()]) :: String.t()
  def count_label(query, shown) do
    if Kati.Search.long_enough?(query) do
      found = length(shown)
      ngettext("%{n} result", "%{n} results", found, n: Kati.Locale.number(found))
    else
      gettext("Search")
    end
  end

  @doc """
  Why the search came back with nothing, when there is a reason to give.

  `Kati.Screens.AddTitle.search_notice/2`, with one difference: a missing
  token is already answered by `Kati.UI.TmdbPrompt`'s block above the field,
  so the refusal is drawn as its sentence alone rather than with a second door
  to the same page.
  """
  @spec notice(map()) :: term()
  def notice(%{search_reason: :no_api_key, tmdb_ready: ready} = assigns) when ready != true,
    do: Kati.UI.notice(assigns.search_error)

  def notice(assigns), do: AddTitle.search_notice(assigns.search_error, assigns.search_reason)

  @doc """
  Coming back from screen 80: re-read whether a TMDB key is usable now.

  The token block is the door to that page, so the page it opens is the one
  place the answer can change — a reader who pasted a token or chose Kati's key
  there came back to a block still asking for one.
  """
  @impl true
  def handle_kati(:resumed, _payload, socket),
    do: {:noreply, Mob.Socket.assign(socket, :tmdb_ready, Kati.Media.Tmdb.usable?())}

  def handle_kati(_topic, _payload, socket), do: {:noreply, socket}

  @doc """
  The field and the debounce, answered by screen 06's own handlers.

  The field is `Kati.Screens.AddTitle.field/2`, so what it sends is what screen
  06 receives: `{:change, :title_query, typed}` on each keystroke and
  `{:search_ready, query}` from `Kati.Media.SearchDebounce` once the typing
  stops. Both are handed to `Kati.Screens.AddTitle.handle_info/2`, which only
  reads and writes the assigns `load/1` set up, so the floor, the stale-answer
  check and the failure sentence are one implementation rather than two.
  Everything else goes to `Kati.Screens.Pushed`'s clauses.
  """
  @impl true
  def handle_info({:change, :title_query, typed} = message, socket) when is_binary(typed),
    do: AddTitle.handle_info(message, socket)

  def handle_info({:search_ready, query} = message, socket) when is_binary(query),
    do: AddTitle.handle_info(message, socket)

  def handle_info(message, socket), do: super(message, socket)

  # Both ways out FINISH the run, and `reset_to/2` rather than `push_screen/2`
  # so Home is the bottom of the stack — pushing would leave the whole first
  # run underneath it and the back gesture would walk back into onboarding
  # that has just been completed. Screen 38 settled both points; this is the
  # last of the five steps it split into, so it inherits them.
  @impl true
  def handle_tap(:finish, socket) do
    Kati.Onboarding.complete!()
    {:noreply, Mob.Socket.reset_to(socket, Kati.Onboarding.shell_root(Kati.Locale.current()))}
  end

  # Skipping finishes setup too: it is a way past adding a title, not a way to
  # abandon the run, and someone who takes it has chosen a language and their
  # sections. See the moduledoc on why it no longer lands on board 139.
  def handle_tap(:skip, socket) do
    Kati.Onboarding.complete!()
    {:noreply, Mob.Socket.reset_to(socket, Kati.Onboarding.shell_root(Kati.Locale.current()))}
  end

  def handle_tap(:step_back, socket), do: {:noreply, Kati.Screens.Resume.pop(socket)}

  def handle_tap(tag, socket) when tag in [:add_tmdb_token, :open_data_sources],
    do: {:noreply, Kati.UI.TmdbPrompt.open(socket, "Back")}

  def handle_tap(tag, socket) when tag in [:clear_query, :add_by_hand],
    do: AddTitle.handle_info({:tap, tag}, socket)

  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "add_" <> position -> {:noreply, AddTitle.add_at(socket, position)}
      _other -> {:noreply, socket}
    end
  end
end
