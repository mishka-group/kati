defmodule Kati.UI.ImportChrome do
  @moduledoc """
  The pieces four import screens draw the same way.

  Screens 37, 120, 140 and 142 share a header pill, a step meter and a file
  tile, and until now they shared them by calling into `Kati.Screens.Import`.
  That was fine while every one of them drew a fixture. It stopped being fine
  the round screen 37 learned to read a file: `Kati.ScreenEmptyDatabaseTest`
  derives *which screens reach the store* from each module's compiled import
  table and closes over it, so borrowing a `Box` from a module that now reaches
  Ash made three screens store readers that read nothing.

  A derived answer is only as good as what it derives from, and the honest fix
  is not to exempt the three — it is to stop the markup living in a module with
  a database behind it. Shared chrome belongs in `Kati.UI`, where the rest of
  this app's shared chrome is.

  The pixels do not move. Every function here is the body it had one file over.
  """

  use Gettext, backend: Kati.Gettext

  import Mob.Sigil

  alias Kati.Components.MishkaThemeIcon
  alias Kati.Components.MishkaToggle
  alias Kati.Theme.Palette

  @doc """
  The ink action pill, opposite the back pill `Kati.Screens.Pushed` floats.

  The 44pt row is what reserves the pill's space; the action sits at its
  trailing edge. `on_tap` is `nil` on three of the four screens that draw this,
  and `nil` is the ordinary answer — not tappable rather than broken.
  """
  @spec header(String.t(), {pid(), atom()} | nil) :: map()
  def header(label, on_tap \\ nil) do
    assigns = %{label: label, tap: on_tap}

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} height={44} align="center">
        <Spacer weight={1.0} />
        <Row
          height={38}
          corner_radius={19}
          background={Palette.ink_fill()}
          padding_left={16}
          padding_right={16}
          align="center"
          on_tap={@tap}
        >
          <Text
            text={@label}
            text_size={13}
            font_weight="bold"
            text_color={Palette.on_ink()}
            max_lines={1}
          />
        </Row>
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc """
  The step meter's mono kicker — `STEP 1 OF 4`, and «گام ۱ از ۴».

  Here rather than in either caller because there are two, and one of them had
  drifted. `Kati.Import.Sample.recognised/0` built it through `pgettext/2` and
  `Kati.Locale.number/1`; `Kati.Import.Job.recognised/1` — the one every REAL
  import goes through — hardcoded the bare string `"STEP 1 OF 4"`, so the
  fixture spoke Persian and the reader's own file did not.
  MOVIES-AND-TV.md `141 #12`.

  The numerals go through `Kati.Locale.number/1` for the reason the whole
  catalogue does: `1` and `4` are ۱ and ۴ to a Persian reader, and a kicker set
  in mono beside a meter is exactly where a Latin digit would show.
  """
  @spec step_label(pos_integer(), pos_integer()) :: String.t()
  def step_label(step, total) do
    pgettext("the step meter's kicker", "STEP %{step} OF %{total}",
      step: Kati.Locale.number(step),
      total: Kati.Locale.number(total)
    )
  end

  @doc """
  The ink action pill's word — `Import 412`, «ورود ۴۱۲».
  """
  @spec action_label(non_neg_integer()) :: String.t()
  def action_label(count) do
    pgettext("the import action pill, with its record count", "Import %{n}",
      n: Kati.Locale.number(count)
    )
  end

  @doc """
  `418 ROWS · 9 COLUMNS`, the mono line under a file's name.

  `Kati.UI.eyebrow_label/1` rather than a second msgid spelled in capitals:
  `String.upcase/1` is a Latin operation and the Arabic script has no case, so
  the drawing's shouting is applied on this side of the fold and the catalogue
  keeps one entry for the one sentence.
  """
  @spec shape_label(non_neg_integer(), non_neg_integer()) :: String.t()
  def shape_label(rows, columns) do
    Kati.UI.eyebrow_label(
      gettext("%{rows} rows · %{columns} columns",
        rows: Kati.Locale.number(rows),
        columns: Kati.Locale.number(columns)
      )
    )
  end

  @doc """
  `trakt-backup.csv · step 3 of 4`, the line under screen 37's heading.

  `Kati.Locale.ltr/1` around the file name: it is a Latin run inside a
  right-to-left sentence, and the bidi algorithm resolves the neutrals in
  `goodreads_library_export.csv` against the paragraph rather than against the
  run unless the isolate says so.
  """
  @spec subtitle_label(String.t(), pos_integer(), pos_integer()) :: String.t()
  def subtitle_label(file, step, steps) do
    gettext("%{file} · step %{step} of %{steps}",
      file: Kati.Locale.ltr(file),
      step: Kati.Locale.number(step),
      steps: Kati.Locale.number(steps)
    )
  end

  @doc "The 5pt gap between two step bars."
  @spec step_gap() :: map()
  def step_gap, do: ~MOB"<Spacer size={5} />"

  @doc "One bar of the step meter: ink when that step is done."
  @spec step_bar(boolean()) :: map()
  def step_bar(done?) do
    color = if done?, do: Palette.ink(), else: Palette.track_off()

    ~MOB"<Box weight={1.0} height={4} corner_radius={2} background={color} />"
  end

  @doc "The 8pt gap between two answer pills."
  @spec choice_gap() :: map()
  def choice_gap, do: ~MOB"<Spacer size={8} />"

  @doc "The 10pt gap between two outcome cards."
  @spec outcome_gap() :: map()
  def outcome_gap, do: ~MOB"<Spacer size={10} />"

  @doc """
  One answer to a conflict: a 32pt pill, ink when it is the chosen one.

  `Kati.Components.MishkaToggle`, whose own showcase builds a segmented bar out
  of nothing but these props — a chip cannot take the two colour pairs and a
  segmented control cannot take three independent labels.

  `on_tap` is `nil` unless the caller says otherwise, which is what keeps
  screen 120's three pills pictures: it draws the same control over a plan
  import that has no conflict queue to answer.
  """
  @spec choice({atom(), String.t(), boolean()}, {pid(), atom()} | nil) :: map()
  def choice(chip, on_tap \\ nil)

  def choice({_key, label, primary?}, on_tap) do
    assigns = %{
      button:
        MishkaToggle.toggle(
          label: label,
          pressed: primary?,
          on_tap: on_tap,
          color: Palette.ink_fill(),
          text_color: Palette.on_ink(),
          background: Palette.cream_raise(),
          label_color: Palette.cream_sub(),
          corner_radius: 16,
          height: 32,
          padding: 0,
          border_width: 0,
          fill_width: true,
          align: :center,
          text_size: 11.5,
          font_weight: :semibold,
          max_lines: 1
        )
    }

    ~MOB"""
    <Box weight={1.0}>
      {@button}
    </Box>
    """
  end

  @doc "The 38pt paper tile a file row leads with."
  @spec file_tile() :: map()
  def file_tile do
    MishkaThemeIcon.theme_icon(
      %{variant: :filled, color: Palette.paper(), size: 38, radius: 11},
      [Kati.UI.symbol("description", size: 20, color: Palette.ink_soft())]
    )
  end
end
