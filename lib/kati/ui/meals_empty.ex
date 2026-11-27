defmodule Kati.UI.MealsEmpty do
  @moduledoc """
  The card a meals screen draws when there is no plan to count.

  Every meals screen is a view of one plan: today's timeline, the week's grid,
  the nutrition figures, the shopping list. With no plan there is nothing to
  view, and until now each of those pages answered with the drawing's own plan —
  *Cutting v3*, a miso salmon dinner, `24 items` over three aisles — on a device
  that had never been given one. That is #91 in the one family where every
  figure is a claim about what the reader ate.

  So they answer this instead: one sentence saying where a plan comes from, and
  the one control that starts one. `Kati.Screens.PlanImport` is the only way a
  plan arrives today, so naming it is the whole of what the card can honestly
  offer.

  ## One card, four pages

  The title is the screen's, because *no plan yet* is the same fact said from
  four angles and the page's own heading already says which angle. The button
  is shared, and its tag with it: each screen maps `:open_plan_import` to the
  import page, so the tap means one thing wherever the card is drawn.
  """

  use Gettext, backend: Kati.Gettext

  import Mob.Sigil

  alias Kati.Theme.Palette
  alias Kati.UI

  @tag :open_plan_import

  @doc "The tag the button sends, and the one every host screen maps to the importer."
  @spec tag() :: atom()
  def tag, do: @tag

  @doc """
  The card.

      card(title: gettext("Today"))

  `title` is the page's own heading — *Today*, *Your week* — drawn above the
  sentence, so the empty page still says where the reader is.
  """
  @spec card(keyword()) :: map()
  def card(opts \\ []) do
    assigns = %{
      title: Keyword.get(opts, :title, gettext("Meals")),
      subtitle:
        Keyword.get(
          opts,
          :subtitle,
          Kati.UI.eyebrow_label(gettext("No plan yet"))
        ),
      tap: {self(), @tag}
    }

    ~MOB"""
    <Column fill_width={true}>
      <Text
        text={@title}
        text_size={28}
        max_font_scale={1.6}
        font_weight="bold"
        letter_spacing={-0.03}
        text_color={:on_surface}
      />
      <Spacer size={5} />
      <Text
        text={@subtitle}
        font_family={Kati.Locale.mono_face()}
        text_size={11}
        text_color={Palette.muted()}
        max_lines={1}
      />
      <Spacer size={18} />
      <Column
        fill_width={true}
        background={Palette.card()}
        corner_radius={22}
        padding={19}
        shadow={Kati.Theme.shadow_card()}
      >
        <Box
          width={44}
          height={44}
          background={Palette.placeholder()}
          corner_radius={14}
          align={:center}
        >
          {UI.symbol("restaurant", size: 22, color: Palette.sub())}
        </Box>
        <Spacer size={16} />
        <Text
          text={gettext("No plan yet")}
          text_size={18}
          font_weight="bold"
          text_color={:on_surface}
        />
        <Spacer size={7} />
        <Text
          text={gettext("Kati counts meals from a plan. Import one and today, the week and the shopping list fill in from it.")}
          text_size={13}
          line_height={Kati.Locale.leading(1.5)}
          text_color={Palette.sub()}
        />
        <Spacer size={16} />
        <Row
          fill_width={true}
          background={Palette.ink()}
          corner_radius={16}
          padding_top={13}
          padding_bottom={13}
          align="center"
          on_tap={@tap}
        >
          <Text
            text={gettext("Import a plan")}
            text_size={14}
            font_weight="semibold"
            text_color={Palette.paper()}
            text_align="center"
            fill_width={true}
          />
        </Row>
      </Column>
    </Column>
    """
  end
end
