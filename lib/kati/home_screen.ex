defmodule Kati.HomeScreen do
  @moduledoc """
  Placeholder root screen, currently doubling as the Ash-on-device spike's
  readout.

  Kati's real shell is four fixed roots behind a floating tab bar. This stands
  in until the foundation tickets land, and exists so foundation work is
  verifiable on a device rather than only asserted on the host.
  """
  use Mob.Screen

  alias Ecto.Adapters.SQL

  @amount Decimal.new("1480.99")

  def mount(_params, _session, socket) do
    {:ok, Mob.Socket.assign(socket, :spike, run_spike())}
  end

  def render(assigns) do
    ~MOB"""
    <Scroll background={:background}>
      <Column background={:background} padding={:space_lg} fill_width={true}>
        <Spacer size={48} />
        <Text text="Kati" text_size={:xl} text_color={:on_surface} />
        <Spacer size={8} />
        <Text text="Foundation check" text_size={:sm} text_color={:muted} />
        <Spacer size={28} />
        {row("CA bundle", tls_label())}
        {row("Database", db_label())}
        {row("Tables", assigns.spike.tables)}
        {row("Decimal exact", assigns.spike.decimal)}
        {row("Datetime exact", assigns.spike.datetime)}
        {row("Rows", assigns.spike.count)}
        {row("First read", assigns.spike.first_read)}
        {row("Second read", assigns.spike.second_read)}
      </Column>
    </Scroll>
    """
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  defp row(label, value) do
    ~MOB"""
    <Column fill_width={true} padding={4}>
      <Text text={label} text_size={:sm} text_color={:muted} />
      <Text text={to_string(value)} text_size={:sm} text_color={:on_surface} />
      <Spacer size={6} />
    </Column>
    """
  end

  # Proves Mob.Certs.load_cacerts!/1 in App.on_start/0 populated the trust
  # store. Without it every HTTPS call on Android dies at the first TLS connect.
  defp tls_label do
    if Mob.Certs.loaded?(), do: "loaded", else: "MISSING"
  end

  defp db_label do
    case SQL.query(Kati.Repo, "SELECT 1", []) do
      {:ok, _} -> "connected"
      {:error, _} -> "unavailable"
    end
  rescue
    _ -> "unavailable"
  end

  # The Ash spike (#30). Writes one row carrying the two types Kati cannot
  # compromise on, reads it back, and asserts EXACT equality — decimal-to-float
  # coercion and microsecond truncation are the failure modes worth catching,
  # and both would pass an approximate check.
  defp run_spike do
    occurred = DateTime.utc_now() |> DateTime.truncate(:microsecond)

    {t1, created} =
      :timer.tc(fn ->
        Kati.Spike.Thing
        |> Ash.Changeset.for_create(:create, %{
          label: "spike",
          amount: @amount,
          occurred_at: occurred
        })
        |> Ash.create()
      end)

    {t2, read} = :timer.tc(fn -> Ash.read(Kati.Spike.Thing) end)

    case {created, read} do
      {{:ok, _}, {:ok, rows}} ->
        latest = Enum.max_by(rows, & &1.inserted_at, DateTime)

        %{
          tables: table_list(),
          decimal:
            if(Decimal.eq?(latest.amount, @amount),
              do: "yes #{latest.amount}",
              else: "NO #{latest.amount}"
            ),
          datetime:
            if(DateTime.compare(latest.occurred_at, occurred) == :eq,
              do: "yes #{latest.occurred_at.microsecond |> elem(0)}us",
              else: "NO #{latest.occurred_at}"
            ),
          count: length(rows),
          first_read: "#{div(t1, 1000)}ms",
          second_read: "#{div(t2, 1000)}ms"
        }

      {c, r} ->
        %{
          tables: table_list(),
          decimal: "create=#{inspect(elem(c, 0))} read=#{inspect(elem(r, 0))}",
          datetime: "-",
          count: 0,
          first_read: "#{div(t1, 1000)}ms",
          second_read: "#{div(t2, 1000)}ms"
        }
    end
  rescue
    e ->
      %{
        tables: "-",
        decimal: "raised: #{Exception.message(e)}",
        datetime: "-",
        count: 0,
        first_read: "-",
        second_read: "-"
      }
  end

  defp table_list do
    case SQL.query(
           Kati.Repo,
           "select name from sqlite_master where type='table' order by name",
           []
         ) do
      {:ok, %{rows: rows}} -> rows |> List.flatten() |> Enum.join(", ")
      _ -> "query failed"
    end
  rescue
    _ -> "-"
  end
end
