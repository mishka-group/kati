defmodule Kati.Screens.OnboardingFa.Sample do
  @moduledoc """
  The six sections board 137 offers, and the two it starts with chosen.

  This is `Kati.Screens.PickSections.Sample` read in Persian, not a second
  invention: same six ids in the same order, same two pre-chosen, because
  137.html draws نمایش and کتاب‌ها inverted to ink with a check exactly where
  26.html draws Screen and Books that way. The ids stay the English words —
  `"screen"`, `"books"` and so on — because nothing displays an id; it only
  has to round-trip through `String.to_atom("section_" <> id)` and back, and
  a Persian id buys the tap tag nothing a Latin one does not already give it.

  ## Why the step count disagrees with `PickSections.Sample.steps/0`

  That module answers `{4, 2}`. This one answers `{5, 3}`, and both are the
  drawing's own numbers, not a typo on either side. `Kati.Screens.LanguagePick`
  — screen 53, the step this whole sequence now opens on — already draws its
  meter at **five** segments and calls itself *"the first step of five"*; 137's
  own meter is five segments with three filled. The Persian sequence counts
  the language choice itself as step one, English's four-step meter never did,
  and 137 is the third step in that count — language, a step with no Persian
  board in this round, then this one. `PickSections.Sample.steps/0` is not
  wrong for what it draws; it is answering a question one step short of the
  one 137 asks.
  """

  @sections [
    %{id: "screen", icon: "movie", label: "نمایش", sub: "فیلم و سریال"},
    %{id: "books", icon: "menu_book", label: "کتاب‌ها", sub: "مطالعه"},
    %{id: "music", icon: "graphic_eq", label: "موسیقی", sub: "شنیدن"},
    %{id: "habits", icon: "bolt", label: "عادت‌ها", sub: "رشته‌ها"},
    %{id: "money", icon: "payments", label: "مالی", sub: "اشتراک‌ها"},
    %{id: "notes", icon: "edit_note", label: "یادداشت", sub: "دفترچه"}
  ]

  @doc "Every section Kati can keep, in the order the grid draws them."
  @spec sections() :: [map()]
  def sections, do: @sections

  @doc "The two the drawing arrives with already chosen."
  @spec chosen() :: MapSet.t()
  def chosen, do: MapSet.new(["screen", "books"])

  @doc "Onboarding progress: five steps, three done. See the moduledoc."
  @spec steps() :: {pos_integer(), pos_integer()}
  def steps, do: {5, 3}

  @doc "The heading, kept as the single string 137's own `<br>` makes of it."
  @spec heading() :: String.t()
  def heading, do: "کاتی چه چیزی را\nبرای شما نگه دارد؟"

  @doc "The line under the heading."
  @spec blurb() :: String.t()
  def blurb,
    do: "دو مورد را برای شروع انتخاب کنید. بقیه را هر وقت خواستید از تنظیمات اضافه کنید."
end
