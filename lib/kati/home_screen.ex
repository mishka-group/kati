defmodule Kati.HomeScreen do
  @moduledoc """
  Placeholder root screen.

  Kati's real shell is four fixed roots behind a floating tab bar. This
  stands in until the foundation tickets land, and exists so the hardening
  work is verifiable on a device: if this renders, the BEAM booted, the
  migrations ran, and the CA bundle loaded.
  """
  use Mob.Screen

  alias Ecto.Adapters.SQL

  def mount(_params, _session, socket) do
    {:ok, Mob.Socket.assign(socket, :tls, :checking)}
  end

  def render(assigns) do
    ~MOB"""
    <Column background={:background} padding={:space_lg} fill_width={true}>
      <Spacer size={48} />
      <Text text="Kati" text_size={:xl} text_color={:on_surface} />
      <Spacer size={8} />
      <Text text="Foundation check" text_size={:sm} text_color={:muted} />
      <Spacer size={32} />
      <Text text={"CA bundle: " <> tls_label(assigns.tls)} text_size={:sm} text_color={:on_surface} />
      <Spacer size={8} />
      <Text text={"Database: " <> db_label()} text_size={:sm} text_color={:on_surface} />
    </Column>
    """
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  # Proves Mob.Certs.load_cacerts!/1 in App.on_start/0 actually populated the
  # trust store. Without it every HTTPS call on Android dies at the first
  # TLS connect, so this is the single most useful thing to see on screen.
  defp tls_label(_) do
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
end
