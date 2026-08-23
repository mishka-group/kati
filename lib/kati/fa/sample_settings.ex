defmodule Kati.Fa.SampleSettings do
  @moduledoc """
  Screen 62's settings, as data — the Persian mirror of Settings.

  A stand-in, named as one. Copy is the design's own, from
  `.scratch/design/screens/62.html`.

  ## The trailing control is part of the row, not a style

  Each row carries what sits at its trailing edge: `:chevron` for a row that
  opens something, `{:text, label}` for one that names its own action,
  `{:toggle, on?}` for a switch, `{:segmented, options}` for a choice small
  enough to show in full. The design uses all four in one list and the
  difference is meaning, not decoration — a chevron promises another screen, a
  switch promises nothing else at all.
  """

  @doc "Everything screen 62 draws, in the order it draws it."
  @spec settings() :: map()
  def settings do
    %{
      back: "خانه",
      title: "تنظیمات",
      subtitle: "۲ دقیقه پیش همگام‌سازی شد",
      me: me(),
      sections: sections()
    }
  end

  @doc "The account card at the top: who this Kati belongs to, and its sync state."
  @spec me() :: map()
  def me do
    %{
      seed: "face68",
      name: "کاتی شما",
      meta: "۱,۲۰۴ مورد · ۴ بخش",
      sync: "همگام"
    }
  end

  @doc """
  The four sections, in order.

  `dash: :muted` on the last is the design's own distinction: the accent dash
  marks a section you set up, the grey one a section you only visit. Orange
  means new or now, and nothing under داده‌ها is either.
  """
  @spec sections() :: [map()]
  def sections do
    [
      %{
        label: "زبان و منطقه",
        dash: :accent,
        rows: [
          %{badge: "فا", title: "زبان", sub: "فارسی · راست به چپ", trailing: {:text, "تغییر"}},
          %{icon: "calendar_month", title: "تقویم", sub: "شمسی", trailing: :chevron},
          %{icon: "pin", title: "اعداد", sub: "فارسی ۱۲۳۴", trailing: :chevron},
          %{icon: "event", title: "شروع هفته", sub: "شنبه", trailing: :chevron}
        ]
      },
      %{
        label: "ظاهر",
        dash: :accent,
        rows: [
          %{
            icon: "contrast",
            title: "پوسته",
            sub: nil,
            trailing: {:segmented, ["خودکار", "روشن", "تیره"]}
          },
          %{icon: "format_size", title: "اندازه متن", sub: "پیروی از سیستم", trailing: :chevron},
          %{icon: "motion_blur", title: "کاهش حرکت", sub: nil, trailing: {:toggle, false}}
        ]
      },
      %{
        label: "بخش‌ها",
        dash: :accent,
        rows: [
          %{
            icon: "movie",
            title: "نمایش",
            sub: "کارت خانه، تقویم، قفسه",
            trailing: {:toggle, true}
          },
          %{
            icon: "menu_book",
            title: "کتاب‌ها",
            sub: "کارت خانه، قفسه",
            trailing: {:toggle, true}
          },
          %{
            icon: "restaurant",
            title: "وعده‌ها",
            sub: "کارت خانه، تقویم",
            trailing: {:toggle, true}
          },
          %{icon: "bolt", title: "عادت‌ها", sub: "تقویم", trailing: {:toggle, true}},
          %{icon: "payments", title: "مالی", sub: "تقویم", trailing: {:toggle, false}}
        ]
      },
      %{
        label: "داده‌ها",
        dash: :muted,
        rows: [
          %{
            icon: "download",
            title: "درون‌ریزی",
            sub: "CSV، JSON یا پشتیبان دیگر",
            trailing: :chevron
          },
          %{
            icon: "upload",
            title: "برون‌ریزی همه‌چیز",
            sub: "آخرین پشتیبان ۱۴ مرداد",
            trailing: :chevron
          },
          %{
            icon: "sync",
            title: "همگام‌سازی",
            sub: "آی‌کلاد · این دستگاه و آی‌پد",
            trailing: :chevron
          },
          # Screen 62 gained this row when 82 landed, the mirror of the one 24
          # gained for 80. `dns` rather than `database`, which is not in Kati's
          # icon subset — the same swap the English side made.
          # Screen 62's Watching row, the mirror of 24's. `subscriptions` is the
          # same glyph the English row uses.
          %{
            icon: "subscriptions",
            title: "سرویس‌های من",
            sub: "ایران · ۳ سرویس",
            trailing: :chevron
          },
          %{
            icon: "dns",
            title: "منابع داده",
            sub: "TVmaze، Open Library، MusicBrainz",
            trailing: :chevron
          },
          # The Persian mirror of 24's About row for screen 83.
          %{
            icon: "info",
            title: "منابع",
            sub: "پروانه‌ها و اعتبارها",
            trailing: :chevron
          }
        ]
      }
    ]
  end
end
