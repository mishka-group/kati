defmodule Kati.Screens.OnboardingFirstTitle do
  @moduledoc """
  Screen 163 — *Add your first title*, step 5 of five.

  The last step of the renumbering brief `D-33` asked for, and the one that
  makes #91's first criterion true by construction: *a clean install walked
  end to end leaves a usable app, asserted by adding a title straight after*.
  A first run that ends here has added one.

  ## What the board decides

  **Skipping lands on the empty Home — screen 139**, and not on a half-set-up
  page. Skipping is a real answer, so it gets the state the app draws for
  having nothing, which is a page that says which parts still work.

  **Artwork never mirrors.** In the RTL twin only the tick moves to the
  leading corner; a poster is a photograph and a mirrored photograph is a
  different picture. `Kati.Screens.LibraryFa` records the same rule for the
  shelf.
  """
  use Kati.Screens.Pushed, back: nil

  # `back: nil` — the board draws no pill. Its back control is the row at
  # the foot of the page, "Back to loudness", which `back_row/1` builds. A
  # floating pill over this would be a second way back the design did not
  # draw, sitting on top of the step rail.

  alias Kati.Screens.OnboardingWelcome
  alias Kati.Theme.Palette
  alias Kati.UI.SettingsList

  @suggestions ["The Long Hollow", "Ashfall", "Marram", "Nightbirds"]

  @impl true
  def load(socket) do
    Kati.Onboarding.reached!(:first_title)
    Mob.Socket.assign(socket, :picked, "The Long Hollow")
  end

  @doc false
  def content(assigns) do
    Kati.Screens.Pushed.page(~MOB"""
      <Column fill_width={true}>
        {OnboardingWelcome.rail(5)}
        <Text text="Add your first title" text_size={28} max_font_scale={1.6} font_weight="bold" letter_spacing={-0.03} text_color={:on_surface} />
        <Spacer size={10} />
        <Text
          text="Pick something you are watching now — the calendar fills itself from there."
          text_size={13.5}
          line_height={1.55}
          text_color={Palette.ink_soft()}
        />
        <Spacer size={20} />
        {Kati.Screens.OnboardingFirstTitle.grid(assigns.picked)}
        <Spacer size={18} />
        {OnboardingWelcome.forward("Finish setup", :finish)}
        <Spacer size={12} />
        <Box fill_width={true} on_tap={{self(), :skip}}>
          <Text
            text="Skip — I’ll add things later"
            text_size={13}
            font_weight="semibold"
            text_color={Palette.sub()}
            text_align="center"
          />
        </Box>
        <Spacer size={18} />
        {SettingsList.note("info", "Skipping lands on empty Home — 139. Artwork never mirrors; only the tick moves to the leading corner.")}
        {OnboardingWelcome.back_row("Back to loudness")}
      </Column>
    """)
  end

  @doc false
  def suggestion_list, do: @suggestions

  @doc """
  The four suggestions, two to a row, as 2:3 posters.

  A grid rather than a list because that is what the board draws, and the
  shape carries the meaning: a poster wall is a thing you pick from by looking,
  which is the question this step asks. `aspect_ratio` holds the 2:3 on a
  device wider or narrower than the 402pt frame — the same lock
  `Kati.Screens.Library`'s shelf would want and does not have, because it
  predates the prop being noticed.
  """
  @spec grid(String.t()) :: map()
  def grid(picked) do
    [first, second, third, fourth] = @suggestions

    assigns = %{
      row_one: Kati.Screens.OnboardingFirstTitle.pair(first, second, picked),
      row_two: Kati.Screens.OnboardingFirstTitle.pair(third, fourth, picked)
    }

    ~MOB"""
    <Column fill_width={true}>
      {@row_one}
      <Spacer size={11} />
      {@row_two}
    </Column>
    """
  end

  @doc false
  def pair(left, right, picked) do
    assigns = %{
      left: Kati.Screens.OnboardingFirstTitle.tile(left, left == picked),
      right: Kati.Screens.OnboardingFirstTitle.tile(right, right == picked)
    }

    ~MOB"""
    <Row fill_width={true} align="top">
      {@left}
      <Spacer size={11} />
      {@right}
    </Row>
    """
  end

  @doc """
  One poster and its title.

  The selected one takes a 2.5pt ink outline and the accent tick in its
  **leading** corner — top-right here, top-left in the Persian twin, 166. That
  is the only thing that crosses in the mirror: the artwork itself never
  does, because a poster is a photograph and a mirrored photograph is a
  different picture.
  """
  @spec tile(String.t(), boolean()) :: map()
  def tile(title, on?) do
    assigns = %{
      title: title,
      on?: on?,
      tap: {self(), String.to_atom("pick_" <> String.replace(title, " ", "_"))}
    }

    ~MOB"""
    <Column weight={1.0} on_tap={@tap}>
      <Box
        fill_width={true}
        aspect_ratio={0.667}
        corner_radius={13}
        background={Palette.placeholder()}
        shadow={Kati.Theme.shadow_card_soft()}
        border_width={if @on?, do: 2.5, else: 0}
        border_color={Palette.ink()}
      >
        {Kati.Screens.OnboardingFirstTitle.tick(@on?)}
      </Box>
      <Spacer size={9} />
      <Text
        text={@title}
        text_size={12.5}
        font_weight="bold"
        text_color={:on_surface}
        max_lines={1}
      />
    </Column>
    """
  end

  @doc """
  The accent tick on the chosen poster, in the **trailing** top corner.

  `top_trailing` maps to Compose's `Alignment.TopEnd`, which is
  direction-aware, so one implementation lands it top-right in English and
  top-left in Persian — which is what 163 and 166 draw, `right:9px` and
  `left:9px` respectively.

  Board 163's own note says *"the leading corner"* and 166's caption says
  *"the trailing top-left corner, since leading in RTL is the right"*. The two
  drawings agree with the second: the tick is trailing in both. The note's
  wording is kept verbatim because it is the drawing's sentence and
  `Kati.ScreenDesignLiteralTest` compares it; this is the correction, recorded
  where someone reading the code would otherwise trust the copy over the
  measurement.
  """
  @spec tick(boolean()) :: map()
  def tick(false), do: ~MOB"<Spacer size={0} />"

  def tick(true) do
    ~MOB"""
    <Box fill_width={true} fill_height={true} align="top_trailing" padding={9}>
      <Box width={24} height={24} corner_radius={12} background={Kati.Theme.accent()} align="center">
        {Kati.UI.symbol("check", size: 15, color: Palette.on_ink())}
      </Box>
    </Box>
    """
  end

  @doc """
  Put the chosen title on the shelf.

  This screen's moduledoc claimed *a first run that ends here has added one*,
  and for the whole of #91 it had not: `:picked` was assigned by the tap, read
  by the grid to draw a tick, and dropped on the way out. A person chose a
  title, pressed **Finish setup**, and arrived at a Home with an empty library —
  the state screen 139 exists to describe, reached by the one path that is
  supposed to avoid it.

  Both rows, in the order screen 154 writes them: `Kati.Media.CachedTitle` is
  what search reads and what gives the shelf a name to draw, and
  `Kati.Media.TrackedTitle` is what puts it on the shelf at all. Writing only
  the first is what a device showed — the title was findable in search and
  absent from the Library.

  Here rather than in `Kati.Onboarding`, which is where first-run state
  otherwise lives, because that module is imported by a dozen screens and
  `Kati.ScreenEmptyDatabaseTest` derives *reaches the store* from the compiled
  import table: a write there makes every screen that asks whether onboarding
  is done answer yes to a question about reads. Screen 154 is the precedent for
  a screen that writes and reads nothing, and both are gated the same way.

  `:tv` and `:watching` are the board's own words rather than a guess. The page
  says *pick something you are watching now*, and *the calendar fills itself
  from there* is a claim about air dates, which is a series.

  A refusal is swallowed on purpose. There is one ordinary reason for one — the
  title is already tracked, which is what a second run through onboarding does —
  and trapping someone in setup over a row that already exists would be worse
  than the defect this fixes. `Kati.Write.note/2` has recorded it by then.
  """
  @spec shelve(String.t() | nil) :: :ok
  def shelve(title) when is_binary(title) do
    with {:ok, _cached} <- Kati.Screens.AddTitle.cache(title, :tv),
         {:ok, _tracked} <-
           Kati.Screens.AddByHand.track(title, %{kind: :tv, status: "Watching"}) do
      :ok
    else
      _refused -> :ok
    end
  end

  def shelve(_nothing), do: :ok

  # Both ways out FINISH the run, and `reset_to/2` rather than `push_screen/2`
  # so Home is the bottom of the stack — pushing would leave the whole first
  # run underneath it and the back gesture would walk back into onboarding
  # that has just been completed. Screen 38 settled both points; this is the
  # last of the five steps it split into, so it inherits them.
  @impl true
  def handle_tap(:finish, socket) do
    Kati.Screens.OnboardingFirstTitle.shelve(socket.assigns.picked)
    Kati.Onboarding.complete!()
    {:noreply, Mob.Socket.reset_to(socket, Kati.Screens.Home)}
  end

  # Skipping is a real answer, so it lands on the state the app draws for
  # having nothing — board 139, which states which parts still work. It
  # finishes setup too: the board offers it as a way past adding a title, not
  # as a way to abandon the run, and someone who takes it has still chosen a
  # language and their sections.
  def handle_tap(:skip, socket) do
    Kati.Onboarding.complete!()
    {:noreply, Mob.Socket.reset_to(socket, Kati.Screens.HomeEmpty)}
  end

  def handle_tap(:step_back, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}

  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "pick_" <> title -> {:noreply, Mob.Socket.assign(socket, :picked, String.replace(title, "_", " "))}
      _other -> {:noreply, socket}
    end
  end
end
