defmodule Kati.Calendars do
  @moduledoc """
  The calendar domain — the spine every other section feeds into.

  Kati **owns** its events; external calendars are mirrored. The distinction is
  carried explicitly in `Kati.Calendars.Event.origin` so that a write path can
  never guess.
  """
  use Ash.Domain, validate_config_inclusion?: false

  resources do
    resource Kati.Calendars.Account
    resource Kati.Calendars.Calendar
    resource Kati.Calendars.Event
    resource Kati.Calendars.Override
  end
end
