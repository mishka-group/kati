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

  use Kati.Screens.Pushed, back: "My services"

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
            SettingsList.body("My services", "Every service you have told Kati about"),
            SettingsList.trailing(SettingsList.chevron()),
            rule: false,
            on_tap: {self(), :edit_price}
          )
        ])
    }

    ~MOB"""
    <Column fill_width={true}>
      {SettingsList.title("No service named", "Nothing to show", nil, :name)}
      {SettingsList.note(
        "info",
        "This page is about one service, and the push that opened it named none. It does not pick one: a page that pauses a subscription and takes it off your shelf must be told which."
      )}
      <Spacer size={16} />
      {SettingsList.eyebrow_muted("Where they are")}
      {@card}
      <Spacer size={14} />
      {SettingsList.note(
        "history",
        "Open a service from there and this page is about that one — its price, the day it renews, whether it is paused, and what you have watched on it."
      )}
    </Column>
    """
  end

  def body(service) do
    assigns = %{
      title:
        SettingsList.title(service.name, Kati.Screens.Service.tier_line(service), nil, :name),
      pay: Kati.Screens.Service.pay_group(service),
      renewal: Kati.Screens.Service.renewal_group(service),
      watched: Kati.Screens.Service.watched_group(service),
      danger: Kati.Screens.Service.danger_group(service)
    }

    ~MOB"""
    <Column fill_width={true}>
      {@title}
      {SettingsList.eyebrow_muted("What you pay")}
      {@pay}
      <Spacer size={16} />
      {SettingsList.eyebrow_muted("Renewal")}
      {@renewal}
      <Spacer size={16} />
      {SettingsList.eyebrow_muted("Watched here")}
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
  """
  @spec tier_line(Service.t()) :: String.t()
  def tier_line(%Service{tier: tier, paused: paused?}) do
    word =
      case tier do
        :subscribed -> "Subscribed"
        :free_with_ads -> "Free with ads"
        _other -> "Not mine"
      end

    if paused?, do: word <> " · paused", else: word
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
          "Edit it where you typed it — My services"
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
  def price_line(service) do
    case Service.price(service) do
      nil -> "No price yet"
      price -> price <> " a month"
    end
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
        SettingsList.body("Paused", "Keeps its row, leaves the monthly total"),
        SettingsList.trailing(SettingsList.switch(service.paused)),
        rule: false,
        on_tap: {self(), :toggle_paused}
      )
    ])
  end

  @doc false
  def renewal_line(%Service{renews_on: nil}), do: "No renewal day yet"

  def renewal_line(%Service{renews_on: date}),
    do: "Renews " <> Kati.Screens.Service.ordinal(date.day)

  @doc false
  def renewal_sub(%Service{renews_on: nil}), do: "Tap to set the day it comes out"
  def renewal_sub(%Service{}), do: "Every month, on that day"

  @doc """
  `1st`, `2nd`, `3rd`, `18th` — the form board 302 prints.

      iex> Kati.Screens.Service.ordinal(1)
      "1st"

      iex> Kati.Screens.Service.ordinal(18)
      "18th"

      iex> Kati.Screens.Service.ordinal(22)
      "22nd"
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

    Integer.to_string(day) <> suffix
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

  @doc false
  def watched_line(0), do: "Nothing logged here yet"
  def watched_line(1), do: "1 title on this service"
  def watched_line(n), do: "#{n} titles on this service"

  @doc false
  def watched_sub(0), do: "A watch says where it was watched — that is what counts one here"
  def watched_sub(1), do: "1 watch"
  def watched_sub(n), do: "#{n} watches"

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
        "Removing it leaves the monthly total and stops it counting as somewhere you can watch. Every watch you logged here stays."
      )}
    </Column>
    """
  end

  @doc false
  def remove_label(service) do
    assigns = %{text: "Remove " <> service.name}

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
