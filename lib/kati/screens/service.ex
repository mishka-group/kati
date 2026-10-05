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

  ## Everything on it is edited where it is shown

  The price opens a field under its row, the renewal day a grid of days under
  its row, and *What you watch here* a list of the reader's titles to place on
  this service. A page that only pointed at another page to change a number,
  or stepped a day forward one tap at a time, was a page nobody could use.

  Placing a title (`TrackedTitle.watch_on`) is what makes a service *used*:
  `Kati.Subscriptions.usage_by_service/0` counts that title's watches here.
  For a service TMDB does not list it is the only way.

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

  alias Kati.Services.Service
  alias Kati.Theme.Palette
  alias Kati.UI.SettingsList

  @impl true
  def load(socket) do
    params = socket.assigns.params || %{}

    socket
    |> Mob.Socket.assign(:service, Kati.Screens.Service.find(Map.get(params, :name)))
    |> Mob.Socket.assign(:open, nil)
    |> Mob.Socket.assign(:draft_price, "")
    |> Mob.Socket.assign(:field_epoch, 0)
    |> Mob.Socket.assign(:notice, nil)
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
    inner = %{body: Kati.Screens.Service.body(assigns.service, assigns)}
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
  @spec body(Service.t() | nil, map()) :: term()
  def body(service, page \\ %{})

  def body(nil, _page) do
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

  def body(service, page) do
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
      pay: Kati.Screens.Service.pay_group(service, page),
      renewal: Kati.Screens.Service.renewal_group(service, page),
      watched: Kati.Screens.Service.watched_group(service, page),
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
      {SettingsList.eyebrow_muted(gettext("What you watch here"))}
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
  The price, and a field under it to change it.

  Typed as money (`10.99`), read by `Kati.Screens.MyServices.parse_price/1`,
  the same reader screen 92's card uses, so the two pages agree on what a
  price is.
  """
  @spec pay_group(Service.t(), map()) :: map()
  def pay_group(service, page \\ %{}) do
    SettingsList.card(
      [
        SettingsList.row(
          SettingsList.icon_tile("payments"),
          SettingsList.body(
            Kati.Screens.Service.price_line(service),
            gettext("Tap to change it")
          ),
          SettingsList.trailing(SettingsList.chevron()),
          rule: false,
          on_tap: {self(), :edit_price}
        )
      ] ++ Kati.Screens.Service.price_editor(service, page)
    )
  end

  @doc false
  def price_editor(service, %{open: :price} = page) do
    assigns = %{
      value: Kati.Screens.MyServices.price_text(service),
      epoch: Map.get(page, :field_epoch, 0),
      on_change: {self(), :service_price},
      save: Kati.Screens.MyServices.primary_button(gettext("Save"), :save_price),
      cancel: Kati.Screens.MyServices.quiet_button(gettext("Cancel"), :close, :on_surface),
      notice: Kati.Screens.MyServices.card_notice(Map.get(page, :notice))
    }

    field =
      ~MOB"""
      <TextField
        value={@value}
        placeholder={gettext("Price a month, like 10.99")}
        keyboard="decimal"
        return_key="done"
        weight={1.0}
        accessibility_id="service_price"
        on_change={@on_change}
        value_epoch={@epoch}
      />
      """

    assigns = Map.put(assigns, :row, Kati.Screens.MyServices.field_row("payments", field))

    [
      ~MOB"""
      <Column fill_width={true} padding_top={4} padding_bottom={14}>
        {@row}
        <Spacer size={12} />
        <Row fill_width={true} align="center">
          <Column weight={1.0}>
            {@save}
          </Column>
          <Spacer size={10} />
          {@cancel}
        </Row>
        {@notice}
      </Column>
      """
    ]
  end

  def price_editor(_service, _page), do: []

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
  @spec renewal_group(Service.t(), map()) :: map()
  def renewal_group(service, page \\ %{}) do
    SettingsList.card(
      [
        SettingsList.row(
          SettingsList.icon_tile("event_repeat"),
          SettingsList.body(
            Kati.Screens.Service.renewal_line(service),
            Kati.Screens.Service.renewal_sub(service)
          ),
          SettingsList.trailing(SettingsList.chevron()),
          on_tap: {self(), :pick_day}
        )
      ] ++
        Kati.Screens.Service.day_picker(service, page) ++
        [
          SettingsList.row(
            SettingsList.icon_tile("pause_circle"),
            SettingsList.body(
              # `pgettext/2`, because the catalogue already holds two other
              # `Paused`es — `book status` and `shelf status` — and this one is
              # the label on a SWITCH that stops a subscription.
              pgettext("service switch", "Paused"),
              gettext("Keeps its row, leaves the monthly total"),
              lines: 2
            ),
            SettingsList.trailing(SettingsList.switch(service.paused)),
            rule: false,
            on_tap: {self(), :toggle_paused}
          )
        ]
    )
  end

  @doc """
  Every day a month can renew on, as a grid under the renewal row, and a way
  to have none. The chosen day is filled.
  """
  def day_picker(service, %{open: :day}) do
    chosen = service.renews_on && service.renews_on.day

    weeks =
      1..31
      |> Enum.chunk_every(7)
      |> Enum.map(fn days ->
        cells = Enum.map(days, &Kati.Screens.Service.day_cell(&1, &1 == chosen))
        pad = List.duplicate(~MOB"<Spacer weight={1.0} />", 7 - length(days))
        assigns = %{cells: Enum.intersperse(cells ++ pad, ~MOB"<Spacer size={6} />")}

        ~MOB"""
        <Column fill_width={true}>
          <Row fill_width={true}>
            {@cells}
          </Row>
          <Spacer size={6} />
        </Column>
        """
      end)

    assigns = %{
      weeks: weeks,
      clear:
        Kati.Screens.MyServices.quiet_button(gettext("No renewal day"), :clear_day, :on_surface)
    }

    [
      ~MOB"""
      <Column fill_width={true} padding_top={4} padding_bottom={12}>
        {@weeks}
        <Spacer size={4} />
        <Row fill_width={true}>
          {@clear}
        </Row>
      </Column>
      """
    ]
  end

  def day_picker(_service, _page), do: []

  @doc false
  def day_cell(day, chosen?) do
    assigns = %{
      label: Kati.Locale.number(day),
      tag: {self(), String.to_atom("day_#{day}")},
      fill: if(chosen?, do: Palette.ink_fill(), else: Palette.paper()),
      ink: if(chosen?, do: Palette.on_ink(), else: :on_surface)
    }

    ~MOB"""
    <Box weight={1.0} height={36} corner_radius={10} background={@fill} align="center" on_tap={@tag}>
      <Text
        text={@label}
        text_size={13}
        font_weight="semibold"
        text_color={@ink}
        text_align="center"
      />
    </Box>
    """
  end

  @doc """
  The next date that falls on `day`: this month if it is still to come, the
  next month otherwise, and the month's last day for a month that is short.

      iex> Kati.Screens.Service.next_on(31, ~D[2026-02-10])
      ~D[2026-02-28]

      iex> Kati.Screens.Service.next_on(5, ~D[2026-10-20])
      ~D[2026-11-05]

      iex> Kati.Screens.Service.next_on(20, ~D[2026-10-20])
      ~D[2026-10-20]
  """
  @spec next_on(1..31, Date.t()) :: Date.t()
  def next_on(day, today) do
    this_month = on_day(today.year, today.month, day)

    if Date.compare(this_month, today) == :lt do
      next = Date.add(Date.end_of_month(today), 1)
      on_day(next.year, next.month, day)
    else
      this_month
    end
  end

  defp on_day(year, month, day),
    do: Date.new!(year, month, min(day, Calendar.ISO.days_in_month(year, month)))

  @doc false
  def renewal_line(%Service{renews_on: nil}), do: gettext("No renewal day yet")

  def renewal_line(%Service{renews_on: date}),
    do: gettext("Renews %{day}", day: Kati.Screens.Service.ordinal(date.day))

  @doc false
  def renewal_sub(%Service{renews_on: nil}), do: gettext("Tap to pick the day it comes out")
  def renewal_sub(%Service{}), do: gettext("Every month, on that day — tap to change it")

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
  `next_on/2` below lands it on a short month's last day — and that recurrence
  is a Gregorian one.
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
  What is watched on this service: how much this month, the titles placed
  here, and *Add a title* to place another.

  A count of watches and not hours: a watch records that an episode was
  watched, not for how long, and a title Kati has no runtime for still counts.
  """
  @spec watched_group(Service.t(), map()) :: map()
  def watched_group(service, page \\ %{}) do
    usage = Kati.Screens.Service.usage(service)
    placed = Kati.Screens.Service.placed_titles(service)

    rows =
      [
        SettingsList.row(
          SettingsList.icon_tile("movie"),
          SettingsList.body(
            Kati.Screens.Service.usage_line(usage),
            Kati.Screens.Service.usage_sub(placed),
            lines: 2
          ),
          nil
        )
      ] ++
        Enum.map(placed, &Kati.Screens.Service.placed_row/1) ++
        [
          SettingsList.row(
            SettingsList.icon_tile("add"),
            SettingsList.body(gettext("Add a title"), gettext("From your library")),
            SettingsList.trailing(SettingsList.chevron()),
            rule: false,
            on_tap: {self(), :pick_title}
          )
        ] ++ Kati.Screens.Service.title_picker(service, page)

    SettingsList.card(rows)
  end

  @doc false
  @spec usage(Service.t()) :: %{minutes: non_neg_integer(), watches: non_neg_integer()}
  def usage(%Service{name: name}) do
    folded = name |> String.trim() |> String.downcase()
    Map.get(Kati.Subscriptions.usage_by_service(), folded, %{minutes: 0, watches: 0})
  end

  @doc false
  def usage_line(%{watches: 0}), do: gettext("Nothing watched here this month")

  def usage_line(%{watches: n}),
    do: ngettext("%{n} watch this month", "%{n} watches this month", n, n: Kati.Locale.number(n))

  @doc false
  def usage_sub([]),
    do: gettext("Add the titles you watch here, and their watches count for this service")

  def usage_sub(_placed),
    do: gettext("Watches of the titles below count here")

  @doc """
  The reader's titles placed on this service, as `%{id, name}`, by name.
  """
  @spec placed_titles(Service.t()) :: [%{id: String.t(), name: String.t()}]
  def placed_titles(%Service{name: name}) do
    Kati.Media.TrackedTitle
    |> Ash.read!()
    |> Enum.filter(&(&1.watch_on == name))
    |> Enum.map(&Kati.Screens.Service.named/1)
    |> Enum.sort_by(&String.downcase(&1.name))
  rescue
    _error -> []
  end

  @doc false
  def named(tracked) do
    cached = Kati.Media.Release.cached_for(tracked)
    %{id: tracked.id, name: Kati.Screens.Library.name_of(cached || %{title: tracked.source_id})}
  end

  @doc false
  def placed_row(title) do
    SettingsList.row(
      nil,
      SettingsList.body(title.name, nil),
      SettingsList.action_pill(
        gettext("Remove"),
        {self(), String.to_atom("unplace_" <> title.id)}
      )
    )
  end

  @doc """
  The library titles not yet placed here, to tap one in. Archived titles are
  left out; a title placed on another service moves here.
  """
  def title_picker(service, %{open: :titles}) do
    candidates =
      Kati.Media.TrackedTitle
      |> Ash.read!()
      |> Enum.reject(
        &(&1.archived or &1.watch_on == service.name or &1.kind not in [:movie, :tv])
      )
      |> Enum.map(&Kati.Screens.Service.named/1)
      |> Enum.sort_by(&String.downcase(&1.name))

    case candidates do
      [] ->
        [
          SettingsList.note(
            "info",
            gettext("Every film and show in your library is already here.")
          )
        ]

      titles ->
        Enum.map(titles, fn title ->
          SettingsList.row(
            nil,
            SettingsList.body(title.name, nil),
            SettingsList.action_pill(
              gettext("Add"),
              {self(), String.to_atom("place_" <> title.id)}
            ),
            on_tap: {self(), String.to_atom("place_" <> title.id)}
          )
        end)
    end
  rescue
    _error -> []
  end

  def title_picker(_service, _page), do: []

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
  def handle_tap(:edit_price, socket), do: {:noreply, open(socket, :price)}
  def handle_tap(:pick_day, socket), do: {:noreply, open(socket, :day)}
  def handle_tap(:pick_title, socket), do: {:noreply, open(socket, :titles)}
  def handle_tap(:close, socket), do: {:noreply, open(socket, nil)}

  def handle_tap(:save_price, socket) do
    case Kati.Screens.MyServices.parse_price(socket.assigns.draft_price) do
      {:ok, pence} ->
        {:noreply, socket |> write(fn _ -> %{monthly_pence: pence} end) |> open(nil)}

      {:error, reason} ->
        {:noreply,
         Mob.Socket.assign(socket, :notice, {:error, Kati.Screens.MyServices.refusal(reason)})}
    end
  end

  def handle_tap(:clear_day, socket),
    do: {:noreply, socket |> write(fn _ -> %{renews_on: nil} end) |> open(nil)}

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

  def handle_tap(tag, socket) do
    case Atom.to_string(tag) do
      "day_" <> day ->
        day = String.to_integer(day)
        next = Kati.Screens.Service.next_on(day, Kati.Time.today())
        {:noreply, socket |> write(fn _ -> %{renews_on: next} end) |> open(nil)}

      "place_" <> id ->
        {:noreply, place(socket, id, socket.assigns.service && socket.assigns.service.name)}

      "unplace_" <> id ->
        {:noreply, place(socket, id, nil)}

      _other ->
        {:noreply, socket}
    end
  end

  # The price field's text, held and not drawn, so typing does not repaint.
  @impl true
  def handle_info({:change, :service_price, typed}, socket) when is_binary(typed),
    do: {:noreply, Mob.Socket.assign(socket, :draft_price, typed)}

  def handle_info(message, socket), do: super(message, socket)

  # One thing open under a row at a time; opening the price starts its draft
  # from the stored price.
  defp open(socket, what) do
    service = socket.assigns.service

    socket
    |> Mob.Socket.assign(:open, if(socket.assigns.open == what, do: nil, else: what))
    |> Mob.Socket.assign(:notice, nil)
    |> Mob.Socket.assign(
      :draft_price,
      (service && Kati.Screens.MyServices.price_text(service)) || ""
    )
    |> Mob.Socket.assign(:field_epoch, socket.assigns.field_epoch + 1)
  end

  defp place(socket, id, name) do
    with {:ok, tracked} <- Ash.get(Kati.Media.TrackedTitle, id),
         {:ok, _placed} <-
           tracked
           |> Ash.Changeset.for_update(:update, %{watch_on: name})
           |> Ash.update()
           |> Kati.Write.note("place a title on a service") do
      Mob.Socket.assign(socket, :service, Kati.Screens.Service.find(socket.assigns.service.name))
    else
      _refused -> socket
    end
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
