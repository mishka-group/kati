defmodule Kati.Screens.LibraryFa.Sample do
  @moduledoc """
  The library in Persian, as screen 57 draws it.

  Six titles rather than `Kati.Library.Sample`'s nine, in the drawing's own
  order and with the drawing's own progress — 71%, 37%, finished, finished,
  16%, not started — because those six exercise every state the poster grid
  has: part-watched, complete, and a wish-list title with an empty track.

  The names are transliterations, which the drawing's caption calls out as a
  choice: *"foreign titles are transliterated; the setting on 54 can show the
  original alongside."* So گودال بلند is The Long Hollow under the same
  `hollow71` photograph, not a different title — one library, one artwork set,
  two ways of writing the name.
  """

  @doc "The header: the root's title and the mono-slot subtitle beneath it."
  def header, do: %{title: "کتابخانه", subtitle: "۹ عنوان · ۴ در حال تماشا"}

  @doc """
  The three media segments. Books and Music stay greyed here as they are in
  screen 03 — the design's own way of showing a section that exists but is not
  built, and #60's scope decision besides.
  """
  def segments do
    [
      %{icon: "movie", label: "نمایش", on?: true},
      %{icon: "menu_book", label: "کتاب‌ها", on?: false},
      %{icon: "graphic_eq", label: "موسیقی", on?: false}
    ]
  end

  @doc "The three quick tiles. Discover carries no count."
  def quick_tiles do
    [
      %{icon: "playlist_play", label: "بعدی", count: "۱۲"},
      %{icon: "explore", label: "کشف", count: nil},
      %{icon: "bookmarks", label: "فهرست‌ها", count: "۷"}
    ]
  end

  @doc "Filter chips with their counts, the first one selected."
  def chips do
    [
      {"همه", "۹"},
      {"در حال تماشا", "۴"},
      {"تمام‌شده", "۳"},
      {"آرزو", "۲"}
    ]
  end

  @doc "The grid, in the order the drawing lays it out."
  def titles do
    [
      %{title: "گودال بلند", meta: "فصل ۲ · ۵ از ۷", progress: 0.71, seed: "hollow71"},
      %{title: "نمک و آهن", meta: "فصل ۱ · ۳ از ۸", progress: 0.37, seed: "saltiron33"},
      %{title: "پرندگان شب", meta: "تمام‌شده", progress: 1.0, seed: "nightbirds24"},
      %{title: "ساعت آبی", meta: "فیلم · ۲۰۲۵", progress: 1.0, seed: "bluehour58"},
      %{title: "بارش خاکستر", meta: "فصل ۳ · ۱ از ۶", progress: 0.16, seed: "ashfall42"},
      %{title: "بندر آرام", meta: "فهرست آرزو", progress: 0.0, seed: "harbour86"}
    ]
  end
end
