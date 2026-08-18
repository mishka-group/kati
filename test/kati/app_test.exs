defmodule Kati.AppTest do
  use ExUnit.Case, async: true

  describe "priv_path/1" do
    test "uses MOB_BEAMS_DIR when the device sets it" do
      System.put_env("MOB_BEAMS_DIR", "/data/user/0/com.example.kati/files/beams")
      on_exit(fn -> System.delete_env("MOB_BEAMS_DIR") end)

      assert Kati.App.priv_path("cacerts.pem") ==
               "/data/user/0/com.example.kati/files/beams/priv/cacerts.pem"
    end

    test "joins nested paths under priv" do
      System.put_env("MOB_BEAMS_DIR", "/beams")
      on_exit(fn -> System.delete_env("MOB_BEAMS_DIR") end)

      assert Kati.App.priv_path("repo/migrations") == "/beams/priv/repo/migrations"
    end

    test "falls back to app_dir off-device so host tooling works" do
      System.delete_env("MOB_BEAMS_DIR")
      path = Kati.App.priv_path("cacerts.pem")

      refute String.starts_with?(path, "/beams")
      assert String.ends_with?(path, "priv/cacerts.pem")
    end
  end
end
