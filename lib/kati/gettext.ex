defmodule Kati.Gettext do
  @moduledoc "Translation backend. English and Persian."
  use Gettext.Backend, otp_app: :kati, priv: "priv/gettext"
end
