defmodule Kati.UI.Sheet do
  @moduledoc """
  A modal anchored to the bottom edge, over a dimmed page.

  New with the second wave of drawings, and shared from the first one rather
  than the third: screens 70, 94, 106, 111, 119, 124 and 125 are all this
  shape, and the pixels are identical on every one of them — a
  `rgba(26,25,23,.42)` scrim, a paper sheet with a 26pt radius on its top two
  corners only, `18px 21px 34px` of padding, and a header row of *close disc ·
  centred title · a 36pt hole the same width as the disc*.

  ## Why the header keeps a hole instead of centring the title

  The title is centred **in the sheet**, not in the space left over beside the
  close button, and those are different positions. A `Spacer weight={1.0}` on
  each side of a hugging Text would centre it in the remainder and shift it
  8pt right of where every drawing puts it. So the trailing 36pt Box is real
  markup with nothing in it, exactly as the drawings write it, and the title
  takes the weight between two equal edges.

  ## Not `Kati.Screens.Pushed`, and not `Kati.Screens.Root`

  Both of those draw a full page. A sheet is a page you can see *through*, and
  the thing you see is the screen underneath — which Mob does not composite,
  because a pushed screen replaces the one below it. So the scrim is painted
  here as a flat fill over `:background` rather than as transparency, and the
  visual claim it makes ("the page is still there") is honest only because
  `close` pops straight back to it.

  ## Height

  The sheet hugs its content and sits at the bottom. Nothing here declares a
  height, and no sheet should: the drawings differ from 380pt to 610pt purely
  by what is in them, and a declared height is how a sheet acquires a gap under
  its last control on one screen and clips it on another.

  ## The 40pt strip under the sheet, which is not a spacer

  The drawings round the sheet's **top two corners only** — `border-radius:
  26px 26px 0 0`. The bridge takes one `corner_radius` and applies it to all
  four, so a sheet drawn the obvious way rounds its bottom corners too and
  lets two dark wedges of scrim through at the very bottom of the screen.

  Rather than add a native prop for it, a square paper Box sits behind the
  sheet's lowest 40pt and fills those wedges. It is drawn first and the sheet
  is drawn over it, so it is invisible everywhere except the two places the
  radius cuts away. Forty rather than twenty-six so the strip cannot go missing
  on a device whose density rounds the radius up.

  This is a real trade and worth naming: `corner_radius_top` would be about
  fifteen lines of Kotlin, and would then be a fence to carry. The strip costs
  one node, needs no rebuild, and is exactly as correct.
  """

  import Mob.Sigil

  alias Kati.Theme.Palette

  @doc """
  The whole sheet: scrim, sheet, header, and the caller's content beneath it.

  `title` is the centred label. `content` is a node or a list of nodes, already
  built. The close disc taps `:close`, which every sheet screen answers with
  `Mob.Socket.pop_screen/1` — named rather than passed, because a sheet whose
  close button does something other than close is not a sheet.
  """
  @spec sheet(String.t(), term()) :: map()
  def sheet(title, content, screen \\ nil) do
    assigns = %{title: title, content: content, screen: screen}

    ~MOB"""
    <Box
      fill_width={true}
      fill_height={true}
      background={:background}
      layout_direction={Kati.Locale.direction_prop()}
      accessibility_id={@screen}
    >
      <Box fill_width={true} fill_height={true} background={Kati.UI.Sheet.scrim()} />
      <Box fill_width={true} fill_height={true} align="bottom">
        <Box fill_width={true} height={40} background={Palette.paper()} />
        <Column
          fill_width={true}
          background={Palette.paper()}
          corner_radius={26}
          padding_left={21}
          padding_right={21}
          padding_top={18}
          padding_bottom={34}
        >
          {Kati.UI.Sheet.header(@title)}
          {@content}
        </Column>
      </Box>
    </Box>
    """
  end

  @doc """
  The scrim: ink at 42% over the page.

  The same value in both modes. A scrim is not a surface — it is the absence of
  one — and screen 68's dark treatment of this family keeps it, because a
  lighter veil on a darker page would dim less exactly where the page is
  already hard to separate from the sheet.
  """
  @spec scrim() :: integer()
  def scrim, do: 0x6B1A1917

  @doc """
  Close disc, centred title, and the hole that keeps the title centred.

  See the moduledoc for why the hole is markup rather than a weight.
  """
  @spec header(String.t()) :: map()
  def header(title) do
    assigns = %{title: title}

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        {Kati.UI.Sheet.close_disc()}
        <Text
          text={@title}
          weight={1.0}
          text_size={15}
          font_weight="bold"
          text_align="center"
          text_color={:on_surface}
          max_lines={1}
        />
        <Box width={36} height={36} />
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc """
  A 36pt disc carrying `close`, tapping `:close`.

  Smaller than screen 18's 44pt disc, and the difference is the drawings': a
  pushed sheet's header is 36 because the sheet's own top edge already
  separates it from the page, where screen 18 is a full page whose disc has to
  float on its own.
  """
  @spec close_disc() :: map()
  def close_disc do
    ~MOB"""
    <Box
      width={36}
      height={36}
      corner_radius={18}
      background={Palette.card()}
      align="center"
      shadow={Kati.Theme.shadow_button()}
      on_tap={{self(), :close}}
    >
      {Kati.UI.symbol("close", size: 19)}
    </Box>
    """
  end

  @doc """
  The ink commit button every sheet ends with.

  One per sheet, and the label is the sentence the sheet completes — `Save
  session`, `Add goal`, `Log weight`. Never `Done`, which says the sheet is
  finished rather than what it did.
  """
  @spec commit(String.t(), atom()) :: map()
  def commit(label, tag) do
    assigns = %{label: label, tag: tag}

    ~MOB"""
    <Row
      fill_width={true}
      height={54}
      corner_radius={27}
      background={Palette.ink_fill()}
      align="center"
      on_tap={{self(), @tag}}
    >
      <Spacer weight={1.0} />
      <Text
        text={@label}
        text_size={14.5}
        font_weight="bold"
        text_color={Palette.on_ink()}
        max_lines={1}
      />
      <Spacer weight={1.0} />
    </Row>
    """
  end

  @doc """
  The cream insight card sheets use to say what the entry means.

  Cream because it *carries a claim* — the palette's own definition of the
  colour — and this is the only card on a sheet that asserts something rather
  than collecting something. `insights` is the glyph on every one of them.
  """
  @spec insight(String.t(), [{String.t(), keyword() | atom()}]) :: map()
  def insight(icon, runs) do
    assigns = %{icon: icon, runs: runs}

    ~MOB"""
    <Column fill_width={true} background={Palette.cream()} corner_radius={20} padding={15}>
      <Row fill_width={true} align="top">
        {Kati.UI.symbol(@icon, size: 18, color: Palette.gold_icon())}
        <Spacer size={11} />
        <Column weight={1.0}>
          {Kati.UI.rich_text(@runs)}
        </Column>
      </Row>
    </Column>
    """
  end
end
