defmodule Kati.TmdbBlockedTest do
  @moduledoc """
  A network that filters TMDB is named as that, not as a flaky connection.

  The owner's home Wi-Fi resolves `api.themoviedb.org` to `10.10.34.36`, a
  private sinkhole, where a public resolver answers TMDB's real `198.20.2.61`.
  The TLS handshake to the sinkhole is closed and the phone said *"Could not
  reach TMDB"* — which reads like a dropped connection or a missing key, and was
  neither. The same build and the same key returned 17 results the moment the
  emulator was given a resolver that does not filter.
  """

  use ExUnit.Case, async: true

  alias Kati.Media.Tmdb

  describe "sinkhole?/1" do
    test "private, loopback, link-local and unspecified addresses are sinkholes" do
      for address <- [
            {10, 10, 34, 36},
            {172, 16, 0, 1},
            {172, 31, 255, 255},
            {192, 168, 70, 1},
            {127, 0, 0, 1},
            {0, 0, 0, 0},
            {169, 254, 1, 1}
          ] do
        assert Tmdb.sinkhole?(address), "#{inspect(address)} was taken for a public server"
      end
    end

    test "a public address is not" do
      for address <- [{198, 20, 2, 61}, {8, 8, 8, 8}, {172, 15, 0, 1}, {172, 32, 0, 1}] do
        refute Tmdb.sinkhole?(address), "#{inspect(address)} was taken for a sinkhole"
      end
    end
  end

  describe "the reader is told what actually happened" do
    test "a blocked network gets its own sentence" do
      blocked = Tmdb.message(:blocked)

      assert blocked =~ "blocking TMDB"
      refute blocked == Tmdb.message({:network, :closed})

      # What they can do about it, since a block is not something waiting fixes.
      assert blocked =~ "mobile data"
    end

    test "and a genuinely unreachable TMDB keeps the sentence it had" do
      assert Tmdb.message({:network, :timeout}) =~ "Could not reach TMDB"
    end

    test "and neither is mistaken for a missing key" do
      refute Tmdb.message(:blocked) =~ "key"
      refute Tmdb.message({:network, :closed}) =~ "key"
    end
  end
end
