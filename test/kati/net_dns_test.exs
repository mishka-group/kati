defmodule Kati.NetDnsTest do
  @moduledoc """
  A network switch does not leave the old answer in front.

  On a filtering Wi-Fi the phone's resolver answered TMDB with a private
  sinkhole; after a move to mobile data the sinkhole stayed first in
  `:inet_db`, and TMDB read as blocked until the app restarted (Galaxy A55,
  26 Sep). Kati worked around it in `Kati.Net.Dns` until mob 0.9.4 made
  `Mob.DNS.resolve/1` replace a host's previous address itself (#110). These
  run the platform answer through Mob's own seeding with the NIF stood in.
  """
  use ExUnit.Case, async: false

  defmodule Phone do
    @moduledoc false
    def resolve_ipv4(host), do: {:ok, Map.fetch!(:persistent_term.get(__MODULE__), host)}
  end

  @host ~c"kati-dns-test.invalid"
  @other ~c"kati-dns-other.invalid"

  setup do
    lookup = :inet_db.res_option(:lookup)

    on_exit(fn ->
      for name <- [@host, @other],
          {:ok, {:hostent, _, _, _, _, ips}} <- [:inet_hosts.gethostbyname(name)],
          do: Enum.each(ips, &:inet_db.del_host/1)

      :inet_db.set_lookup(lookup)
      :persistent_term.erase(Phone)
    end)

    :ok
  end

  defp answer(answers), do: :persistent_term.put(Phone, answers)

  test "the address seeded on the last network does not survive the next answer" do
    answer(%{@host => {10, 10, 34, 36}})
    assert {:ok, {10, 10, 34, 36}} = Mob.DNS.resolve_with(Phone, "kati-dns-test.invalid")

    answer(%{@host => {198, 20, 2, 61}})
    assert {:ok, {198, 20, 2, 61}} = Mob.DNS.resolve_with(Phone, "kati-dns-test.invalid")

    assert {:ok, {:hostent, _, _, :inet, 4, [{198, 20, 2, 61}]}} = :inet.gethostbyname(@host)
  end

  test "two hosts a sinkhole answers alike both stay resolvable" do
    answer(%{@host => {0, 0, 0, 0}, @other => {0, 0, 0, 0}})

    assert {:ok, _} = Mob.DNS.resolve_with(Phone, "kati-dns-test.invalid")
    assert {:ok, _} = Mob.DNS.resolve_with(Phone, "kati-dns-other.invalid")

    assert {:ok, _} = :inet.gethostbyname(@host)
    assert {:ok, _} = :inet.gethostbyname(@other)
  end

  test "Kati asks Mob directly and keeps no host table of its own" do
    sources = Path.wildcard(Path.expand("../../lib/**/*.ex", __DIR__))

    for path <- sources, source = File.read!(path) do
      refute source =~ "Kati.Net.Dns", "#{path} still calls the removed workaround"
      refute source =~ ":inet_db.del_host", "#{path} edits :inet_db's hosts by hand"
    end
  end
end
