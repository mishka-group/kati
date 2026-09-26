defmodule Kati.NetDnsTest do
  @moduledoc """
  A network switch does not leave the old answer in front (`Kati.Net.Dns`).

  `:inet_db.add_host/2` appends, so a sinkhole seeded on a filtering Wi-Fi
  stayed the first address after the phone moved to mobile data, and TMDB
  read as blocked until the app restarted.
  """
  use ExUnit.Case, async: false

  doctest Kati.Net.Dns

  @host ~c"kati-dns-test.invalid"

  setup do
    on_exit(fn -> Enum.each(Kati.Net.Dns.seeded(@host), &:inet_db.del_host/1) end)
    :inet_db.set_lookup([:file | List.delete(:inet_db.res_option(:lookup), :file)])
    :ok
  end

  test "the address seeded on the last network does not survive the next answer" do
    sinkhole = {10, 10, 34, 36}
    tmdb = {198, 20, 2, 61}

    :inet_db.add_host(sinkhole, [@host])
    before = Kati.Net.Dns.seeded(@host)
    :inet_db.add_host(tmdb, [@host])

    assert {:ok, {:hostent, _, _, :inet, 4, [^sinkhole, ^tmdb]}} = :inet.gethostbyname(@host),
           "the precondition: appending leaves the sinkhole first"

    Kati.Net.Dns.forget(before, tmdb)

    assert {:ok, {:hostent, _, _, :inet, 4, [^tmdb]}} = :inet.gethostbyname(@host)
  end

  test "an unchanged answer is kept" do
    tmdb = {198, 20, 2, 61}
    :inet_db.add_host(tmdb, [@host])

    Kati.Net.Dns.forget(Kati.Net.Dns.seeded(@host), tmdb)

    assert Kati.Net.Dns.seeded(@host) == [tmdb]
  end
end
