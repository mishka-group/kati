defmodule Kati.Screens.Pushed do
  use Gettext, backend: Kati.Gettext

  @moduledoc """
  A screen pushed over a root, rather than one of the four roots.

  Most of the design's screens are these: a back pill instead of the tab
  bar, and a title that names where back goes. Screen 09 is the reference —
  *"pushed screen under the Calendar root with a `‹ Calendar` back pill and
  no tab bar"*.

  Sibling to `Kati.Screens.Root`, and the split is deliberate: a root sets
  `:root` and draws the shell, a pushed screen must not draw the tab bar at
  all. Making that a parameter of one macro would let a screen quietly get
  it wrong; two macros cannot.

  Provides the same tap rescue as `Kati.Screens.Root` — Mob catches nothing,
  and a raise in a tap handler otherwise kills the screen process — plus a
  `back` tap wired to `Mob.Socket.pop_screen/1`.

  ## This macro defines no `handle_tap/2`, and must not

  A pushed screen that draws a tappable control and forgets `handle_tap/2` is
  reported by `Kati.Screens.Root.rescue_tap/3` as a `DEAD TAP` error naming
  the module and the tag. That report is the entire safety net for a class of
  defect nothing else can see: the button's *resting* pixels are correct, so
  the design comparison passes, the compiler is happy, and the build is green.

  Adding `def handle_tap(_tag, socket), do: {:noreply, socket}` here would
  silence it. It is a tempting one-liner — it removes an error from the log
  and makes the behaviour look intentional — and it is precisely wrong: the
  dead button stays dead, and the last thing that was telling anyone about it
  stops. `Kati.Screens.Root` had exactly that default and it had been hiding
  three broken screens. Do not bring it back on this side.
  """

  defmacro __using__(opts) do
    # `Keyword.fetch!` still, so `back:` cannot be forgotten — but the value may
    # be `nil`, which means "this board draws its own back control in the flow".
    # See `back_pill/1`.
    back_label = Keyword.fetch!(opts, :back)

    quote do
      use Mob.Screen
      import Mob.Sigil
      @behaviour Kati.Screens.Root

      @back_label unquote(back_label)

      def mount(params, _session, socket) do
        # The resolved palette, where this used to pin the light one — see the
        # note in `Kati.Screens.Root`'s macro, including why neither comment
        # spells the old call out. A push is the commonest navigation in the
        # app, so this was the single call that most often threw the user's
        # choice away.
        Kati.Theme.activate()
        Kati.Locale.activate()

        socket
        |> Mob.Socket.assign(:params, params)
        |> load()
        |> then(&{:ok, &1})
      end

      def load(socket), do: socket

      def render(assigns) do
        Kati.Screens.Pushed.chrome(
          @back_label &&
            Kati.Screens.Pushed.back_label(Map.get(assigns, :params), @back_label),
          content(assigns),
          Kati.Screens.Pushed.screen_name(__MODULE__)
        )
      end

      def handle_info({:tap, :back}, socket) do
        {:noreply, Kati.Screens.Resume.pop(socket)}
      end

      # Everything except `:back` is the screen's own control, so the screen
      # owns the answer. Nothing is defined here to stand in for it — see the
      # moduledoc on why a default no-op would be the worst possible fix.
      def handle_info({:tap, tag}, socket) do
        Kati.Screens.Root.rescue_tap(__MODULE__, tag, socket)
      end

      def handle_info({:kati, topic, payload}, socket) do
        Kati.Screens.Root.rescue_kati(__MODULE__, topic, payload, socket)
      end

      def handle_info(_message, socket), do: {:noreply, socket}

      defoverridable load: 1, handle_info: 2
    end
  end

  @doc """
  What the back pill says: where you came FROM, not where the screen assumes.

  The label was a compile-time constant per screen — `use Kati.Screens.Pushed,
  back: "Library"` — and the hand-rolled pages wrote the word into their own
  markup. So a film opened from Home's *Continue watching* offered to take you
  back to the Library, which is not where you were and, on a phone whose back
  gesture pops one screen, is not where the pill takes you either: the word and
  the behaviour disagreed.

  The pushing screen is the only thing that knows, so it says so — `%{back:
  "Home"}` alongside whatever else it carries — and this reads it with the
  screen's own declaration as the fallback. A screen pushed from the gallery,
  or by a test, or by anything that does not care, keeps exactly the label it
  had.

      iex> Kati.Screens.Pushed.back_label(%{back: "Home"}, "Library")
      "Home"

      iex> Kati.Screens.Pushed.back_label(%{}, "Library")
      "Library"

      iex> Kati.Screens.Pushed.back_label(nil, "Library")
      "Library"
  """
  @spec back_label(map() | nil, String.t()) :: String.t()
  def back_label(params, default) do
    case params && Map.get(params, :back) do
      label when is_binary(label) and label != "" -> translated(label)
      _absent -> translated(default)
    end
  end

  # mishka-group/kati#103. The pill says where the reader came FROM, and every
  # word it can say is one another screen wrote — `back: "Library"` at a `use`
  # site, or a `%{back: …}` on a push. Both are compile-time English, so a
  # folded screen would come out with a Persian page under an English pill.
  #
  # `Gettext.dgettext/3` rather than the macro: the macro extracts at compile
  # time from a literal, and this is a runtime value. An untranslated label
  # answers itself, so a screen whose word is not in the catalogue yet is
  # exactly as it was — which is what makes this safe to add before the other
  # nine mirrors fold.
  # The `back pill` CONTEXT first, then the plain lookup.
  #
  # A back pill is its own register, and one word proves it: screen 44's pill
  # says *Meals*, which board 60 draws as **وعده‌ها** — while the share sheet's
  # scope chip, also *Meals*, is **وعده**. One msgid cannot be both, and gettext
  # has the answer already: a context. So a screen whose pill needs its own word
  # gets a `msgctxt "back pill"` entry, and every other pill falls through to
  # the shared one rather than needing an entry per screen.
  #
  # `dpgettext/5` answers the msgid itself when the context has no entry, which
  # is exactly the signal to fall through.
  @doc """
  Every label a back pill can carry, written out so `mix gettext.extract` can
  see it.

  Nothing calls this. `translated/1` receives the label as a RUNTIME value —
  `use Kati.Screens.Pushed, back: "Settings"` puts it in an attribute, and a
  push can pass one as a param — so the extractor, which reads literal
  `gettext/1` call sites and nothing else, finds no msgid for any of them. It
  does not merely fail to add one: `mix gettext.extract --merge` **removes**
  the entries a previous run added by hand, translation and all. Five Persian
  back pills were lost exactly that way on 11 September and were noticed only
  because `Kati.ScreenDesignLiteralTest` compares boards 60 and 156 against the
  rendered tree.

  So the vocabulary is declared. A label added to a `back:` option and not
  added here is a pill that reads English in Persian — which is why
  `Kati.BackPillVocabularyTest` asserts the two lists are the same list.
  """
  @spec back_vocabulary() :: [String.t()]
  def back_vocabulary do
    [
      gettext("Activity"),
      gettext("Add title"),
      gettext("Album"),
      gettext("Artist"),
      gettext("Auto-detect"),
      gettext("Back"),
      gettext("Books"),
      gettext("Calendar"),
      gettext("Data sources"),
      gettext("Episode order"),
      gettext("Episodes"),
      gettext("Health"),
      gettext("Home"),
      gettext("Import"),
      gettext("Inbox"),
      gettext("Language"),
      gettext("Library"),
      gettext("List"),
      gettext("Lists"),
      gettext("Meals"),
      gettext("Medication"),
      gettext("Music"),
      gettext("My services"),
      gettext("Notifications"),
      gettext("Plans"),
      gettext("Recognised"),
      gettext("Search"),
      gettext("Series"),
      gettext("Settings"),
      gettext("Stats"),
      gettext("Up next"),
      gettext("What fits?"),
      gettext("Year cards")
    ] ++
      [
        # The one label that means two different things and needs a context:
        # screen 44's pill says وعده‌ها (*meals*, the plan) where the section
        # name is وعده (*meal*). See `translated/1`.
        pgettext("back pill", "Meals")
      ]
  end

  defp translated(label) do
    case Gettext.dpgettext(Kati.Gettext, "default", "back pill", label) do
      ^label -> Gettext.dgettext(Kati.Gettext, "default", label)
      translated -> translated
    end
  end

  @doc """
  How far down a pushed screen's content must start.

  The pill floats at 54 and is 42 tall, so anything a screen draws at the
  design's usual 64 lands underneath it. Screens that open with a title use
  this instead — measured, not guessed: 54 + 42 + 14 of breathing room.
  """
  @spec content_top() :: pos_integer()
  def content_top, do: 110

  @doc """
  A screen's name on the device, derived from its module.

  `Kati.Screens.HomeEmptyDark` becomes `home_empty_dark`. Derived rather than
  written by hand because 152 hand-written names is 152 chances to give two
  screens the same one, and the whole point of the stamp is that it says which
  screen you are on.
  """
  @spec screen_name(module()) :: String.t()
  def screen_name(module) do
    module
    |> Module.split()
    |> List.last()
    |> Macro.underscore()
  end

  @doc "The pushed-screen frame: a back pill over the content, no tab bar."
  def chrome(back_label, content, screen \\ nil) do
    direction = Kati.Locale.direction_prop()

    assigns = %{
      content: content,
      back_label: back_label,
      direction: direction,
      # See `Kati.Locale.face_prop/0`: the default face for every `Text` under
      # this frame, including the ones components build and no screen can mark.
      face: Kati.Locale.face_prop(),
      screen: screen && "screen:" <> screen
    }

    import Mob.Sigil

    ~MOB"""
    <Box
      fill_width={true}
      fill_height={true}
      background={:background}
      layout_direction={@direction}
      font_family={@face}
      accessibility_id={@screen}
    >
      {@content}
      {Kati.Screens.Pushed.back_pill(@back_label)}
    </Box>
    """
  end

  @doc """
  The scrolling body of a pushed screen: 21pt sides, 40 below, `top` above.

  `chrome/3` is the root `Box` and the floating pill, and nothing else — every
  screen inside it has been writing this same `Scroll` and padded `Column` by
  hand. Six written in one round did not, and what a device shows for one of
  those is content starting at the pixel: the first line hard against the left
  edge and the top of the page underneath the status bar.

  Nothing in the suite had an opinion about that, which is why
  `Kati.PushedFrameTest` now does.

  `top` is the one number that varies, and the two values are the two shapes a
  board draws:

    * **`content_top/0`** — the board draws a back pill. The macro floats one
      at 54, 42 tall, so content has to clear it. 154 and 155 are this shape.
    * **64** — the board draws no pill and puts its back control in the flow,
      which is what the five-step first run does. Those screens pass
      `back: nil` and get no floating pill to clear.
  """
  @spec page(map(), pos_integer()) :: map()
  def page(content, top \\ 64) do
    import Mob.Sigil
    assigns = %{content: content, top: top}

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={@top}
        padding_bottom={40}
      >
        {@content}
      </Column>
    </Scroll>
    """
  end

  @doc """
  Which way back points, which is not a thing `layout_direction` can answer.

  A container flips under RTL and a **glyph does not**: `arrow_back_ios_new` is
  a codepoint in a font, so `LocalLayoutDirection` mirrors the Row it sits in
  and leaves the arrow pointing the same way it was drawn. Every pushed screen
  in Persian therefore drew a chevron aimed at the edge the reader did NOT come
  from — the commonest RTL bug there is, and the one board 156's caption pins
  by name.

  The Persian mirrors have always known this: `Kati.Screens.Fa.pushed_frame/2`
  draws `arrow_forward_ios`, and `Kati.Screens.Fa.chrome/0` records the same
  trap for screen 69. What was missing is that the SHARED frame did not, so an
  English screen opened while the app is in Persian — which is every pushed
  page the mirrors do not cover, and after
  [#103](https://github.com/mishka-group/kati/issues/103) will be all of them —
  got the RTL layout and the LTR arrow.

  Not `rotate={180}` on the `Box`, which is how `Kati.Screens.ShelfFilters`
  turns its one sort arrow: `arrow_forward_ios` is a glyph Kati already ships
  (`Kati.Icons`), and turning a chevron that has a real mirrored twin would put
  its optical weight on the wrong side.

      iex> Kati.Screens.Pushed.glyph_for(:rtl)
      "arrow_forward_ios"

      iex> Kati.Screens.Pushed.glyph_for(:ltr)
      "arrow_back_ios_new"
  """
  @spec back_glyph() :: String.t()
  def back_glyph, do: glyph_for(Kati.Locale.direction(Kati.Locale.current()))

  @doc false
  @spec glyph_for(:rtl | :ltr) :: String.t()
  def glyph_for(:rtl), do: "arrow_forward_ios"
  def glyph_for(_ltr), do: "arrow_back_ios_new"

  @doc """
  The floating back pill, or nothing when the screen draws its own.

  `nil` is a real answer rather than a missing one. Boards 161, 162 and 163 put
  their back control **in the flow at the foot of the page** — `Back to
  language`, under the note — and draw no pill at the top at all. Floating one
  over them would be a second way back that the design did not draw, sitting on
  top of the step rail.
  """
  @spec back_pill(String.t() | nil) :: map()
  def back_pill(nil) do
    import Mob.Sigil
    ~MOB"<Spacer size={0} />"
  end

  def back_pill(label) do
    import Mob.Sigil
    tap = {self(), :back}
    # The card colour, not the 90%-opaque chrome fill: the drawings paint this
    # pill solid and give it the same lift as every other floating control.
    #
    # The mode comes from `Kati.Theme.Palette.mode/0` — which reads the theme
    # `Mob.Theme` is actually carrying — rather than from `Kati.Theme.mode/0`,
    # which re-resolves the stored preference. At RENDER time those two can
    # disagree (a preference stored without a re-activate), and the half of the
    # markup that resolves through `:on_surface` follows the installed theme
    # regardless. Asking the installed theme keeps one frame internally
    # consistent; `Kati.Theme.mode/0` is the mount-time question.
    assigns = %{label: label, tap: tap, chrome: Kati.Theme.card(Kati.Theme.Palette.mode())}

    # A Row, not a Box, and this was wrong on ~30 screens.
    #
    # `width={:wrap}` is not a thing: the bridge fills width whenever `width`
    # is not a NUMBER (MobBridge.kt:2673). So the pill spanned the entire
    # screen, clipped at the right edge, and painted its 90%-opaque fill over
    # whatever trailing control the screen drew — which is why those discs
    # looked pale grey rather than ink. A Row hugs its content.
    #
    # The outer Row keeps the pill left and leaves the rest of the width free,
    # so a screen's own trailing disc is untouched.
    ~MOB"""
    <Row fill_width={true} padding_left={21} padding_right={21} padding_top={64}>
      <Row
        height={44}
        background={@chrome}
        corner_radius={22}
        shadow={Kati.Theme.shadow_button()}
        padding_left={13}
        padding_right={16}
        align="center"
        on_tap={@tap}
      >
        {Kati.UI.symbol(Kati.Screens.Pushed.back_glyph(), size: 17)}
        <Spacer size={6} />
        <Text
          text={@label}
          text_size={13.5}
          font_weight="semibold"
          letter_spacing={-0.01}
          text_color={:on_surface}
        />
      </Row>
      <Spacer weight={1.0} />
    </Row>
    """
  end
end
