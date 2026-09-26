defmodule Kati.Net.Dns do
  @moduledoc """
  Resolve a host through the phone's own resolver, and forget what it said on
  the last network.

  `Mob.DNS.resolve/1` asks Android and seeds `:inet_db` with the answer, which
  is where Req, Finch and Mint look. It only ever ADDS: `:inet_db.add_host/2`
  appends, and a lookup returns every seeded address in the order they went
  in. So the address a filtering Wi-Fi handed out — a private sinkhole — stayed
  first after the reader switched to mobile data, every request still went to
  it, and the app said *This network is blocking TMDB* on a network that was
  not, until it was restarted. Found on the owner's Galaxy A55, 26 Sep.

  Each call asks afresh, and any address seeded for the host that the new
  answer does not include is removed.
  """

  @doc """
  The host's address now, with stale ones dropped. Off-device the NIF is
  absent and this answers `{:error, :nif_not_loaded}`, leaving the table alone.
  """
  @spec resolve(String.t()) :: {:ok, :inet.ip4_address()} | {:error, term()}
  def resolve(host) when is_binary(host) do
    name = String.to_charlist(host)
    before = Kati.Net.Dns.seeded(name)

    case Mob.DNS.resolve(name) do
      {:ok, address} = found ->
        Kati.Net.Dns.forget(before, address)
        found

      error ->
        error
    end
  end

  @doc "Remove each of `stale` from the host table, keeping `address`."
  @spec forget([:inet.ip4_address()], :inet.ip4_address()) :: :ok
  def forget(stale, address) do
    stale |> Enum.reject(&(&1 == address)) |> Enum.each(&:inet_db.del_host/1)
  end

  @doc """
  The addresses `:inet_db`'s host table holds for `name`.

      iex> Kati.Net.Dns.seeded(~c"kati-dns-doctest.invalid")
      []
  """
  @spec seeded(charlist()) :: [:inet.ip4_address()]
  def seeded(name) do
    case :inet_hosts.gethostbyname(name) do
      {:ok, {:hostent, _name, _aliases, :inet, 4, addresses}} -> addresses
      _none -> []
    end
  end
end
