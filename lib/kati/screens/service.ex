defmodule Kati.Screens.Service do
  @moduledoc """
  Board 302 — one service, and the two columns nothing in Kati could set.

  Screen 92 lists the reader's services and screen 23 adds them up. Neither
  could ever answer a question about **one** of them, and two columns on
  `Kati.Services.Service` were read across the app and written nowhere:

    * `paused` — `Kati.Screens.Subscriptions` greys a paused row and drops its
      rate, and `Kati.Notifications.Sources.Money` refuses to remind about a
      renewal for one. Both branches were unreachable.
    * `renews_on` — `Kati.Subscriptions.renewal/1` prints it, screen 47 puts it
      on the money day, and the notification source fires on it. Nothing set a
      date, so none of the three ever had one to work with.

  This page is the writer for both.

  ## It displays the price and does not own the editor

  Board 252's own note, and it is followed rather than reinterpreted: *"92's
  caption already says 'this screen owns these prices' and the editable-price
  field is its own ticket — this board is annotated as waiting on it rather
  than quietly answering it."* Screen 92's row-tap does own it (#119: tapping a
  service puts `Netflix 10.99` back in the field it was typed into), so the
  price here is a line and a pointer to the page that changes it. Two editors
  for one number is how two screens come to disagree about it.

  ## Three groups the boards draw and this page does not

  The rule `Kati.Screens.SeriesSettings` states and screen 14 settled: a group
  with no schema behind it is **dropped**, not drawn dead.

    * **Cost per watched hour.** Board 252 makes the case against itself: *"a
      watch records that an episode was watched, not for how long, and nothing
      maps a provider to a service."* `Kati.Media.Watch` has no duration
      column. The figure cannot be derived and is not printed.
    * **Hours watched.** The same absence, one line up.
    * **Shared with.** Board 302 draws `Jo Mercer` and a split. Kati has no
      people table and no contacts permission — `Kati.Screens.Rating`'s
      `commit_with/1` records the same finding about the same absence — so the
      group would be one invented name.

  What is left is what a service actually is on this device: a price, a renewal
  day, whether it is paused, what has been watched on it, and the way off the
  shelf.
  """

  # `back: "My services"` stays an English literal on purpose. The pill's word
  # is a RUNTIME value to `Kati.Screens.Pushed.back_label/2` — a `use` option
  # lands in a module attribute and a push can override it — so the extractor
  # never sees it here, and `Kati.Screens.Pushed.back_vocabulary/0` is where it
  # is declared for `mix gettext.extract`. It is already on that list, and its
  # Persian is already in the catalogue.
  use Kati.Screens.Pushed, back: "My services"
  use Gettext, backend: Kati.Gettext

  alias Kati.Media.Watch
  alias Kati.Services.Service
  alias Kati.Theme.Palette
  alias Kati.UI.SettingsList

  @impl true
  def load(socket) do
    params = socket.assigns.params || %{}

    Mob.Socket.assign(socket, :service, Kati.Screens.Service.find(Map.get(params, :name)))
  end

  @doc """
  The service this page is about, by the name that opened it.

  A bare push answers `nil` rather than the first service on the shelf.
  `Kati.ScreenWriteTargetTest`'s rule is the reason and it applies with force
  here: this page pauses things and takes them off a shelf, and a screen that
  picks its own subject would be doing that to a service the reader did not
  name.
  """
  @spec find(String.t() | nil) :: Service.t() | nil
  def find(name) when is_binary(name) do
    Service
    |> Ash.read!()
    |> Enum.find(&(&1.name == name))
  rescue
    _error -> nil
  end

  def find(_nothing), do: nil

  @doc false
  def content(assigns) do
    inner = %{body: Kati.Screens.Service.body(assigns.service)}
    assigns = inner

    ~MOB"""
    <Scroll>
      <Column
        fill_width={true}
        padding_left={21}
        padding_right={21}
        padding_top={64}
        padding_bottom={40}
      >
        {SettingsList.chrome(nil, 44)}
        {@body}
      </Column>
    </Scroll>
    """
  end

  @doc false
  @spec body(Service.t() | nil) :: term()
  def body(nil) do
    assigns = %{
      card:
        SettingsList.card([
          SettingsList.row(
            SettingsList.icon_tile("subscriptions"),
            SettingsList.body(
              # The same msgid screen 92's own title uses, so the row that
              # points at that page and the page it arrives at say one word.
              gettext("My services"),
              gettext("Every service you have told Kati about")
            ),
            SettingsList.trailing(SettingsList.chevron()),
            rule: false,
            on_tap: {self(), :edit_price}
          )
        ])
    }

    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.title(gettext("No service named"), gettext("Nothing to show"), nil, :name)}
      {SettingsList.note(
        "info",
        gettext(
          "This page is about one service, and the push that opened it named none. It does not pick one: a page that pauses a subscription and takes it off your shelf must be told which."
        )
      )}
      <Spacer size={16} />
      {SettingsList.eyebrow_muted(gettext("Where they are"))}
      {@card}
      <Spacer size={14} />
      {SettingsList.note(
        "history",
        gettext(
          "Open a service from there and this page is about that one — its price, the day it renews, whether it is paused, and what you have watched on it."
        )
      )}
    </Column>
    """
  end

  def body(service) do
    assigns = %{
      title:
        SettingsList.title(
          # The name is a REAL service off `Kati.Services.Service` and stays in
          # its own script — board 127 draws `Lumen+` in Latin on a Persian
          # page — but it is isolated, because several of them end in a
          # character the bidi algorithm calls neutral. `+` between a Latin run
          # and the end of an rtl paragraph resolves to the paragraph's
          # direction and is laid out at the LEFT of the word, so the 28pt
          # heading draws **+Lumen**. `Kati.Locale.ltr/1` is a no-op in English.
          Kati.Locale.ltr(service.name),
          Kati.Screens.Service.tier_line(service),
          nil,
          :name
        ),
      pay: Kati.Screens.Service.pay_group(service),
      renewal: Kati.Screens.Service.renewal_group(service),
      watched: Kati.Screens.Service.watched_group(service),
      danger: Kati.Screens.Service.danger_group(service)
    }

    ~MOB"""
    <Column fill_width={true}>
      {@title}
      {SettingsList.eyebrow_muted(gettext("What you pay"))}
      {@pay}
      <Spacer size={16} />
      {SettingsList.eyebrow_muted(gettext("Renewal"))}
      {@renewal}
      <Spacer size={16} />
      {SettingsList.eyebrow_muted(gettext("Watched here"))}
      {@watched}
      <Spacer size={16} />
      {@danger}
    </Column>
    """
  end

  @doc """
  The line under the name: which shelf this service sits on, and whether it is
  paused.

      iex> Kati.Screens.Service.tier_line(%Kati.Services.Service{tier: :subscribed, paused: false})
      "Subscribed"

      iex> Kati.Screens.Service.tier_line(%Kati.Services.Service{tier: :subscribed, paused: true})
      "Subscribed · paused"

  `Free with ads` and `Not mine` are screen 92's own msgids — the two words
  head its bands — so this line and that list cannot come to name the same
  shelf differently.
  """
  @spec tier_line(Service.t()) :: String.t()
  def tier_line(%Service{tier: tier, paused: paused?}) do
    word =
      case tier do
        :subscribed -> gettext("Subscribed")
        :free_with_ads -> gettext("Free with ads")
        _other -> gettext("Not mine")
      end

    # One msgid for the whole line rather than `word <> " · paused"`. A bare
    # `" · paused"` is a fragment with no sentence around it, and a language
    # that puts the state first — or that joins the two with something other
    # than a bullet — has nowhere to say so when the join is Elixir's `<>`.
    if paused?, do: gettext("%{tier} · paused", tier: word), else: word
  end

  @doc """
  The price, and a pointer to the page that owns it.

  Board 302's note about the field is kept even though the field is elsewhere:
  *"Price is stored in pence, so the field takes 899 and the card prints
  £8.99 — a decimal field would let a mis-typed dot cost a hundredfold."* The
  editor that takes it is screen 92's row, so the row here says so rather than
  drawing a second one.
  """
  @spec pay_group(Service.t()) :: map()
  def pay_group(service) do
    SettingsList.card([
      SettingsList.row(
        SettingsList.icon_tile("payments"),
        SettingsList.body(
          Kati.Screens.Service.price_line(service),
          gettext("Edit it where you typed it — My services")
        ),
        SettingsList.trailing(SettingsList.chevron()),
        rule: false,
        on_tap: {self(), :edit_price}
      )
    ])
  end

  @doc """
  What this costs a month, or that nobody has said.

      iex> Kati.Screens.Service.price_line(%Kati.Services.Service{monthly_pence: 899, currency: "GBP"})
      "£8.99 a month"

      iex> Kati.Screens.Service.price_line(%Kati.Services.Service{monthly_pence: nil})
      "No price yet"
  """
  @spec price_line(Service.t()) :: String.t()
  def price_line(%Service{monthly_pence: nil}), do: gettext("No price yet")

  def price_line(%Service{monthly_pence: pence, currency: currency}) do
    # `Service.format/2` rather than `Service.price/1`, and the swap is the
    # whole of the Persian case rather than a preference. `price/1` builds
    # `symbol(currency) <> figure` itself and asks the locale nothing, so a
    # Persian page drew `£8.99` in Latin digits with the sign leading, beside
    # sentences that were neither; `format/2` is the same arithmetic with the
    # locale's answer on top — `۸٫۹۹ £`, which is how board 97 writes money.
    # The two should be one function. `price/1` is read by `Kati.Subscriptions`
    # as well, so that fix belongs in `Kati.Services.Service` rather than here;
    # this screen takes the correct one meanwhile.
    #
    # `Kati.Locale.ltr/1` around the run for the reason
    # `Kati.Screens.Stats.money_line/0` records against the same msgid: a
    # currency mark is neutral to the bidi algorithm, so inside a Persian
    # sentence it resolves right-to-left and ends up on the wrong side of its
    # own figure. Same msgid as that line and as screen 92's total, so what a
    # month costs is worded once.
    gettext("%{total} a month", total: Kati.Locale.ltr(Service.format(pence, currency)))
  end

  @doc """
  The renewal day, and the switch that pauses the whole thing.

  `renews_on` is a **date** and the board words it as a day of the month —
  *"Every month, on the 18th"* — which is what `Kati.Subscriptions` and the
  notification source both read it as. So the control is the day, and the month
  moves with the calendar rather than being stored twice.
  """
  @spec renewal_group(Service.t()) :: map()
  def renewal_group(service) do
    SettingsList.card([
      SettingsList.row(
        SettingsList.icon_tile("event_repeat"),
        SettingsList.body(
          Kati.Screens.Service.renewal_line(service),
          Kati.Screens.Service.renewal_sub(service)
        ),
        SettingsList.trailing(SettingsList.chevron()),
        on_tap: {self(), :cycle_day}
      ),
      SettingsList.row(
        SettingsList.icon_tile("pause_circle"),
        SettingsList.body(
          # `pgettext/2`, because the catalogue already holds two other
          # `Paused`es — `book status` and `shelf status`, both of them a shelf
          # a title is sitting on — and this one is the label on a SWITCH that
          # stops a subscription. They happen to be the same word in Persian
          # today; a context is what keeps that a coincidence rather than a
          # constraint, and stops `mix gettext.merge` fuzzy-matching a one-word
          # msgid onto whichever of the three it met first.
          pgettext("service switch", "Paused"),
          gettext("Keeps its row, leaves the monthly total")
        ),
        SettingsList.trailing(SettingsList.switch(service.paused)),
        rule: false,
        on_tap: {self(), :toggle_paused}
      )
    ])
  end

  @doc false
  def renewal_line(%Service{renews_on: nil}), do: gettext("No renewal day yet")

  def renewal_line(%Service{renews_on: date}),
    do: gettext("Renews %{day}", day: Kati.Screens.Service.ordinal(date.day))

  @doc false
  def renewal_sub(%Service{renews_on: nil}), do: gettext("Tap to set the day it comes out")
  def renewal_sub(%Service{}), do: gettext("Every month, on that day")

  @doc """
  `1st`, `2nd`, `3rd`, `18th` — the form board 302 prints, in the reader's own
  numerals.

      iex> Kati.Screens.Service.ordinal(1)
      "1st"

      iex> Kati.Screens.Service.ordinal(18)
      "18th"

      iex> Kati.Screens.Service.ordinal(22)
      "22nd"

      iex> Kati.Locale.as(:fa, fn -> Kati.Screens.Service.ordinal(18) end)
      "۱۸"

  ## Persian gets the digits and no suffix

  `st`/`nd`/`rd`/`th` is a mark English writes on a numeral and Persian has no
  equivalent of: the ordinal is a whole word — هجدهم — and the day of a month
  is written as the bare number, `هر ماه، روز ۱۸`. Transliterating the suffix
  would put two letters on the end of a number that mean nothing.

  ## And the number is **not** converted to Shamsi

  The same rule `Kati.Locale.year/1` keeps, for a different reason with the
  same shape. `renews_on` is read everywhere as *the day of the month the money
  comes out* — `Kati.Subscriptions.renewal/1` prints it, screen 47 puts it on
  the money day, `Kati.Notifications.Sources.Money` fires on it, and
  `next_day/1` below wraps it at 28 — and that recurrence is a Gregorian one.
  `Kati.Locale.day_of_month/1` would answer the Shamsi day this month's
  renewal happens to land on, which is a different number next month: right
  once and wrong eleven times, and wrong in the way this fold keeps meeting,
  where the figure looks like the reader's own and is not.

  So the digits follow the reader and the calendar does not, and the honest
  reading of `تمدید روز ۱۸` is the one the English page gives too — the 18th of
  whatever month the bill falls in.
  """
  @spec ordinal(pos_integer()) :: String.t()
  def ordinal(day) do
    suffix =
      cond do
        rem(day, 100) in 11..13 -> "th"
        rem(day, 10) == 1 -> "st"
        rem(day, 10) == 2 -> "nd"
        rem(day, 10) == 3 -> "rd"
        true -> "th"
      end

    Kati.Locale.pick(Integer.to_string(day) <> suffix, Kati.Locale.number(day))
  end

  @doc """
  What has been watched on this service.

  A count of logs and of titles, and **not hours**: board 252 says why in its
  own words — *a watch records that an episode was watched, not for how long*.
  `Kati.Media.Watch.service` is the reader's own answer to *Where*, which is
  the one thing that does connect a night to a service.
  """
  @spec watched_group(Service.t()) :: map()
  def watched_group(service) do
    %{logs: logs, titles: titles} = Kati.Screens.Service.watched(service)

    SettingsList.card([
      SettingsList.row(
        SettingsList.icon_tile("movie"),
        SettingsList.body(
          Kati.Screens.Service.watched_line(titles),
          Kati.Screens.Service.watched_sub(logs)
        ),
        nil,
        rule: false
      )
    ])
  end

  @doc false
  @spec watched(Service.t()) :: %{logs: non_neg_integer(), titles: non_neg_integer()}
  def watched(%Service{name: name}) do
    rows =
      Watch
      |> Ash.read!()
      |> Enum.filter(&(&1.service == name))

    %{
      logs: length(rows),
      titles: rows |> Enum.map(& &1.tracked_title_id) |> Enum.uniq() |> length()
    }
  rescue
    _error -> %{logs: 0, titles: 0}
  end

  # The nought clause stays its own sentence: `0 titles on this service` is a
  # measurement and *Nothing logged here yet* is the answer board 302 wants at
  # that end, which is screen 93's argument about a total of zero — a figure
  # reads as an account that was added up and came to nothing.
  #
  # The other two fold into `ngettext/4`, which is not the same thing as the
  # two clauses they were: Persian does not inflect a noun after a numeral, so
  # its singular and plural are one string, and a language with three forms
  # gets three. The count goes in twice on purpose — as the integer gettext
  # picks the form with, and as `Kati.Locale.number/1` for the digits that are
  # actually drawn.
  @doc false
  def watched_line(0), do: gettext("Nothing logged here yet")

  def watched_line(n) do
    ngettext("%{n} title on this service", "%{n} titles on this service", n,
      n: Kati.Locale.number(n)
    )
  end

  @doc false
  def watched_sub(0),
    do: gettext("A watch says where it was watched — that is what counts one here")

  def watched_sub(n), do: ngettext("%{n} watch", "%{n} watches", n, n: Kati.Locale.number(n))

  @doc """
  Off the shelf, and what that does not take with it.

  Board 302's own sentence: *"It leaves the monthly total and stops counting as
  watchable from today. The 41 hours stay."* The logs are `Kati.Media.Watch`
  rows and this destroys a `Kati.Services.Service`, so they do — the same
  not-a-cascade rule `Kati.Media.History.clear/0` keeps one screen over.
  """
  @spec danger_group(Service.t()) :: map()
  def danger_group(service) do
    assigns = %{
      card:
        SettingsList.card([
          SettingsList.row(
            Kati.Components.MishkaThemeIcon.theme_icon(
              %{variant: :filled, color: Palette.paper(), size: 30, radius: 9},
              [Kati.UI.symbol("error", size: 17, color: Palette.red())]
            ),
            Kati.Screens.Service.remove_label(service),
            nil,
            rule: false,
            on_tap: {self(), :remove}
          )
        ])
    }

    ~MOB"""
    <Column fill_width={true}>
      {@card}
      <Spacer size={14} />
      {SettingsList.note(
        "info",
        gettext(
          "Removing it leaves the monthly total and stops it counting as somewhere you can watch. Every watch you logged here stays."
        )
      )}
    </Column>
    """
  end

  @doc false
  def remove_label(service) do
    # Interpolated rather than `"Remove " <> service.name`: a bare `Remove `
    # with a space on the end is not a sentence any catalogue can be asked to
    # translate, and Persian puts the verb where it puts it.
    #
    # `Kati.Locale.ltr/1` around the name for the reason the title gives — the
    # `+` on `Lumen+` is neutral to the bidi algorithm and jumps to the left of
    # its own word inside a Persian sentence — and the name itself stays Latin,
    # because it is a real service off `Kati.Services.Service` and no msgid
    # reaches it.
    assigns = %{text: gettext("Remove %{service}", service: Kati.Locale.ltr(service.name))}

    ~MOB"""
    <Text
      text={@text}
      text_size={13.5}
      font_weight="semibold"
      text_color={Palette.red()}
      max_lines={1}
    />
    """
  end

  @impl true
  def handle_tap(:edit_price, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.MyServices)}

  # The day of the month, one tap at a time through the days a month can have.
  # A picker is what a date wants and Kati has no date picker; a day is one
  # integer, and `Kati.Subscriptions` and the notification source both read
  # `renews_on` as *the day it comes out* rather than as an instant.
  def handle_tap(:cycle_day, socket), do: {:noreply, write(socket, &next_day/1)}

  def handle_tap(:toggle_paused, socket),
    do: {:noreply, write(socket, fn s -> %{paused: not s.paused} end)}

  def handle_tap(:remove, socket) do
    case socket.assigns.service do
      %Service{} = service ->
        case Ash.destroy(service) do
          answer when answer in [:ok] -> {:noreply, Kati.Screens.Resume.pop(socket)}
          {:ok, _row} -> {:noreply, Kati.Screens.Resume.pop(socket)}
          error -> {:noreply, refused(socket, error)}
        end

      _drawn ->
        {:noreply, socket}
    end
  end

  def handle_tap(_tag, socket), do: {:noreply, socket}

  defp next_day(%Service{renews_on: nil}) do
    today = Kati.Time.today()
    %{renews_on: today}
  end

  defp next_day(%Service{renews_on: date}) do
    # Wraps at 28 rather than at 31: a renewal on the 30th does not happen in
    # February, and a day nobody can be billed on is not a day to offer.
    day = if date.day >= 28, do: 1, else: date.day + 1
    %{renews_on: %{date | day: day}}
  end

  defp write(socket, change) do
    case socket.assigns.service do
      %Service{} = service ->
        service
        |> Ash.Changeset.for_update(:update, change.(service))
        |> Ash.update()
        |> case do
          {:ok, updated} -> Mob.Socket.assign(socket, :service, updated)
          error -> refused(socket, error)
        end

      _drawn ->
        socket
    end
  end

  defp refused(socket, error) do
    Kati.Write.note(error, "change a service")
    socket
  end
end
