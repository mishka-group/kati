defmodule Kati.Screens.SeriesMeta do
  @moduledoc """
  Screen 14 — a series in full, pushed under Library.

  Built to `.scratch/design/screens/14.html`. Where screen 04 answers *what do
  I watch next*, this one answers *what is this thing* — three ratings side by
  side, the synopsis, real cast, every way to watch including the user's own
  shelf, and the user's own tags last.

  The order is the argument. Ratings from three sources come first because they
  are what a stranger wants; the user's tags come last because they are what
  the user already knows. Nothing here is a modal or a tab: it is the same card
  rhythm as every other screen, just longer.

  ## Chrome

  Its own, not `Kati.Screens.Pushed`'s. The back pill floats over a 270pt still
  at 60pt with an overflow disc opposite it, the way screens 04 and 08 do —
  the pushed chrome sits on paper and has no partner button.

  A 150pt gradient lifts the paper back over the bottom of the still so the
  title is ink on paper rather than ink on a photograph. The drawing gives it
  three stops rather than two — opaque at 4%, 70% at 44%, gone at the top —
  so it is written out here rather than reusing `Kati.UI.paper_fade/1`, which
  is the two-stop version.

  ## Two places the drawing uses something the bridge has not got

    * `&starf; 4.5` is U+2605 followed by the value. Plus Jakarta Sans has no
      U+2605, so the star is the Material Symbols `star` glyph and only `4.5`
      is text. Same mark, different font — see screen 08, where the text
      version rendered as nothing at all.
    * `+ tag` is drawn with a **dashed** 1.5pt border. The bridge's border is
      solid, so this is a solid 1.5pt hairline at the same colour. The chip
      still reads as the empty slot it is, because the fill is absent rather
      than white.

  Tags `flex-wrap` in the drawing and nothing wraps here, so they are chunked
  three-then-two — which is where the browser breaks them at this width.
  """
  use Mob.Screen
  import Mob.Sigil

  alias Kati.Screens.SeriesMeta.Sample
  alias Kati.UI

  def mount(_params, _session, socket) do
    Mob.Theme.set(Kati.Theme.light())
    {:ok, Mob.Socket.assign(socket, :series, Sample.series())}
  end

  def render(assigns) do
    s = assigns.series

    ~MOB"""
    <Box fill_width={true} fill_height={true} background={:background} layout_direction={Kati.Locale.direction_prop()}>
      <Scroll>
        <Column fill_width={true}>
          {Kati.Screens.SeriesMeta.artwork(s)}
          <Column fill_width={true} padding_left={21} padding_right={21} padding_top={16} padding_bottom={40}>
            {Kati.Screens.SeriesMeta.ratings(s)}
            {Kati.Screens.SeriesMeta.synopsis(s)}
            {Kati.Screens.SeriesMeta.actions(s)}
            <Spacer size={26} />
            {UI.eyebrow("Cast")}
            {Kati.Screens.SeriesMeta.cast(s)}
            <Spacer size={26} />
            {UI.eyebrow("Where to watch")}
            {Kati.Screens.SeriesMeta.where(s)}
            <Spacer size={26} />
            {UI.eyebrow("Your tags")}
            {Kati.Screens.SeriesMeta.tags(s)}
          </Column>
        </Column>
      </Scroll>
      {Kati.Screens.SeriesMeta.chrome()}
    </Box>
    """
  end

  @doc false
  def artwork(s) do
    ~MOB"""
    <Box fill_width={true} height={270} background={0xFFDCD7CF}>
      {Kati.Screens.SeriesMeta.hero_art()}
      <Box fill_width={true} fill_height={true} align="bottom">
        <Box fill_width={true} height={150} gradient="to_top #FFEFECE7 4% #B3EFECE7 44% #00EFECE7" />
      </Box>
      <Box fill_width={true} fill_height={true} align="bottom">
        <Column fill_width={true} padding_left={21} padding_right={21} padding_bottom={4}>
          <Text
            text={s.title}
            text_size={28}
            font_weight="extrabold"
            letter_spacing={-0.035}
            line_height={1.05}
            text_color={:on_surface}
          />
          <Spacer size={8} />
          <Text text={s.meta} font_family="mono" text_size={11} text_color={0xFF6E6860} max_lines={1} />
        </Column>
      </Box>
    </Box>
    """
  end

  @doc false
  def hero_art do
    case Sample.hero_art() do
      nil ->
        ~MOB"<Spacer size={0} />"

      src ->
        ~MOB"""
        <Image src={src} fill_width={true} height={270} content_mode="fill" />
        """
    end
  end

  @doc false
  def chrome do
    back = {self(), :back}
    fill = Kati.Theme.card(:light)

    ~MOB"""
    <Box fill_width={true} fill_height={true} align="top">
      <Row fill_width={true} padding_left={21} padding_right={21} padding_top={60} align="center">
        <Row
          height={44}
          corner_radius={22}
          background={fill}
          shadow={Kati.Theme.shadow_button()}
          padding_left={12}
          padding_right={16}
          align="center"
          on_tap={back}
        >
          {Kati.UI.symbol("arrow_back_ios_new", size: 17)}
          <Spacer size={6} />
          <Text text="Library" text_size={13.5} font_weight="semibold" letter_spacing={-0.01} text_color={:on_surface} />
        </Row>
        <Spacer weight={1.0} />
        <Box width={44} height={44} corner_radius={22} background={fill} shadow={Kati.Theme.shadow_button()} align="center">
          {Kati.UI.symbol("more_horiz", size: 21)}
        </Box>
      </Row>
    </Box>
    """
  end

  @doc false
  def ratings(s) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        {s.ratings
         |> Enum.map(&Kati.Screens.SeriesMeta.rating_card/1)
         |> Enum.intersperse(Kati.Screens.SeriesMeta.rating_gap())}
      </Row>
      <Spacer size={16} />
    </Column>
    """
  end

  @doc false
  def rating_gap, do: ~MOB"<Spacer size={9} />"

  # Centred with weighted Spacers on both sides rather than text_align, because
  # text_align makes a Text fill its row in this bridge and the card is a
  # weighted column — the two together distort the row (screen 08's defect 2).
  @doc false
  def rating_card(r) do
    ~MOB"""
    <Box weight={1.0}>
      <Column
        fill_width={true}
        background={Kati.Theme.card(:light)}
        corner_radius={16}
        shadow={Kati.Theme.shadow_card_soft()}
        padding={12}
      >
        <Row fill_width={true} align="center">
          <Spacer weight={1.0} />
          <Text
            text={String.upcase(r.label)}
            font_family="mono"
            text_size={9.5}
            letter_spacing={0.12}
            text_color={0xFFA9A29A}
            max_lines={1}
          />
          <Spacer weight={1.0} />
        </Row>
        <Spacer size={6} />
        <Row fill_width={true} align="center">
          <Spacer weight={1.0} />
          {Kati.Screens.SeriesMeta.rating_star(r)}
          <Text text={r.value} text_size={17} font_weight="bold" text_color={r.color} max_lines={1} />
          <Spacer weight={1.0} />
        </Row>
      </Column>
    </Box>
    """
  end

  @doc false
  def rating_star(%{star?: false}), do: ~MOB"<Spacer size={0} />"

  def rating_star(r) do
    ~MOB"""
    <Row align="center">
      {Kati.UI.symbol("star", size: 15, color: r.color, fill: true)}
      <Spacer size={4} />
    </Row>
    """
  end

  # The drawing sets `more` inline at the end of the paragraph. Mob has no
  # inline span, so it follows on its own line in the design's own muted grey.
  # Recorded rather than hidden: it is the one place this screen is not the
  # drawing.
  @doc false
  def synopsis(s) do
    ~MOB"""
    <Column fill_width={true}>
      <Text text={s.synopsis} text_size={14} line_height={1.6} text_color={0xFF4A4238} />
      <Spacer size={2} />
      <Row align="center">
        <Text text={s.more} text_size={14} text_color={0xFFA0998F} max_lines={1} />
      </Row>
    </Column>
    """
  end

  @doc false
  def actions(s) do
    ~MOB"""
    <Column fill_width={true}>
      <Spacer size={16} />
      <Row fill_width={true} align="center">
        <Box weight={1.0}>
          <Row
            fill_width={true}
            height={48}
            corner_radius={20}
            background={Kati.Theme.ink()}
            shadow="0 12 24 -12 #D91A1917"
            align="center"
          >
            <Spacer weight={1.0} />
            {Kati.UI.symbol("play_arrow", size: 20, color: 0xFFFBFAF8, fill: true)}
            <Spacer size={8} />
            <Text text={s.trailer} text_size={13.5} font_weight="bold" text_color={0xFFFBFAF8} max_lines={1} />
            <Spacer weight={1.0} />
          </Row>
        </Box>
        <Spacer size={10} />
        {Kati.Screens.SeriesMeta.action_disc("bookmark")}
        <Spacer size={10} />
        {Kati.Screens.SeriesMeta.action_disc("label")}
      </Row>
    </Column>
    """
  end

  @doc false
  def action_disc(icon) do
    ~MOB"""
    <Box
      width={48}
      height={48}
      corner_radius={20}
      background={Kati.Theme.card(:light)}
      shadow={Kati.Theme.shadow_card_soft()}
      align="center"
    >
      {Kati.UI.symbol(icon, size: 20)}
    </Box>
    """
  end

  # Four across on weights rather than four declared 81s. The drawing says
  # `flex:1`, and 81 was only ever what that resolved to on the 402dp frame it
  # was drawn at: 81*4 + 12*3 = 360, the content width inside the 21pt gutters
  # *there*. On a 411dp device the column is 369 and the same four cells still
  # measured 360, leaving a 9dp gutter on the trailing edge that belonged to
  # nothing. The 12pt gaps are fixed so they come off the top; the weights
  # divide whatever is actually left.
  @doc false
  def cast(s) do
    ~MOB"""
    <Row fill_width={true} align="top">
      {s.cast
       |> Enum.map(&Kati.Screens.SeriesMeta.cast_member/1)
       |> Enum.intersperse(Kati.Screens.SeriesMeta.cast_gap())}
    </Row>
    """
  end

  @doc false
  def cast_gap, do: ~MOB"<Spacer size={12} />"

  @doc false
  def cast_member(c) do
    ~MOB"""
    <Column weight={1.0}>
      <Box fill_width={true} height={81} corner_radius={41} background={0xFFE4E0D9} shadow={Kati.Theme.shadow_card_soft()}>
        {Kati.Screens.SeriesMeta.portrait(c.seed)}
      </Box>
      <Spacer size={8} />
      <Text text={c.name} text_size={11} font_weight="semibold" line_height={1.3} text_color={:on_surface} text_align="center" />
      <Spacer size={2} />
      <Text text={c.role} font_family="mono" text_size={9.5} text_color={0xFFA9A29A} text_align="center" max_lines={1} />
    </Column>
    """
  end

  # The portrait tracks the cell, not the old 81. A Box aligns its child
  # top-START, so an 81pt image inside a cell that now measures 83 would leave
  # the placeholder's #E4E0D9 showing as a sliver down the trailing edge.
  # `content_mode="fill"` is ContentScale.Crop, so the face is cropped to the
  # frame rather than stretched into it.
  @doc false
  def portrait(seed) do
    case Sample.face(seed) do
      nil ->
        ~MOB"<Spacer size={0} />"

      src ->
        ~MOB"""
        <Image src={src} fill_width={true} height={81} corner_radius={41} content_mode="fill" />
        """
    end
  end

  @doc false
  def where(s) do
    last = length(s.where) - 1

    ~MOB"""
    <Column
      fill_width={true}
      background={Kati.Theme.card(:light)}
      corner_radius={20}
      shadow={Kati.Theme.shadow_card_soft()}
      padding_left={15}
      padding_right={15}
      padding_top={4}
      padding_bottom={4}
    >
      {s.where
       |> Enum.with_index()
       |> Enum.map(fn {row, i} -> Kati.Screens.SeriesMeta.where_row(row, i < last) end)}
    </Column>
    """
  end

  @doc false
  def where_row(row, rule?) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center" padding_top={13} padding_bottom={13}>
        <Box width={32} height={32} corner_radius={10} background={0xFFEFECE7} align="center">
          <Text text={row.badge} font_family="mono" text_size={13} text_color={:on_surface} max_lines={1} />
        </Box>
        <Spacer size={13} />
        <Column weight={1.0}>
          <Text text={row.name} text_size={13} font_weight="semibold" text_color={:on_surface} max_lines={1} />
          <Spacer size={2} />
          <Text text={row.line} text_size={11} text_color={0xFF8A8479} max_lines={1} />
        </Column>
        <Spacer size={13} />
        {Kati.Screens.SeriesMeta.price(row.price)}
      </Row>
      {Kati.Screens.SeriesMeta.hairline(rule?)}
    </Column>
    """
  end

  @doc false
  def price(nil), do: ~MOB"<Spacer size={0} />"

  def price(value) do
    ~MOB"""
    <Text text={value} font_family="mono" text_size={11} text_color={0xFFA9A29A} max_lines={1} />
    """
  end

  @doc false
  def hairline(false), do: ~MOB"<Spacer size={0} />"
  def hairline(true), do: ~MOB"<Box fill_width={true} height={1} background={0x121A1917} />"

  # Three then two, which is where the browser breaks these five labels at a
  # 360pt content width. The add-tag slot carries its own flag rather than
  # being recognised by its label, so a user tag reading "+ tag" would still be
  # drawn as a tag.
  @doc false
  def tags(s) do
    rows =
      (Enum.map(s.tags, &{&1, false}) ++ [{s.add_tag, true}])
      |> Enum.chunk_every(3)

    ~MOB"""
    <Column fill_width={true}>
      {Enum.map(rows, fn row -> Kati.Screens.SeriesMeta.tag_row(row) end)}
    </Column>
    """
  end

  @doc false
  def tag_row(row) do
    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="center">
        {row
         |> Enum.map(fn {label, add?} -> Kati.Screens.SeriesMeta.tag(label, add?) end)
         |> Enum.intersperse(Kati.Screens.SeriesMeta.tag_gap())}
      </Row>
      <Spacer size={7} />
    </Column>
    """
  end

  @doc false
  def tag_gap, do: ~MOB"<Spacer size={7} />"

  @doc false
  def tag(label, true) do
    ~MOB"""
    <Row
      height={30}
      corner_radius={15}
      border_color={0x2E1A1917}
      border_width={1.5}
      padding_left={12}
      padding_right={12}
      align="center"
    >
      <Text text={label} text_size={12} font_weight="semibold" text_color={0xFFA0998F} max_lines={1} />
    </Row>
    """
  end

  def tag(label, false) do
    ~MOB"""
    <Row
      height={30}
      corner_radius={15}
      background={Kati.Theme.card(:light)}
      shadow={Kati.Theme.shadow_card_soft()}
      padding_left={13}
      padding_right={13}
      align="center"
    >
      <Text text={label} text_size={12} font_weight="semibold" text_color={0xFF5C574F} max_lines={1} />
    </Row>
    """
  end

  def handle_info({:tap, :back}, socket), do: {:noreply, Mob.Socket.pop_screen(socket)}
  def handle_info(_msg, socket), do: {:noreply, socket}
end
