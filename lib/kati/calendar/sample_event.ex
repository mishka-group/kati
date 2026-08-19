defmodule Kati.Calendar.SampleEvent do
  @moduledoc """
  Screen 31's event: Design review, opened for editing.

  The design's caption names what this screen is for: *"Every field the
  quick-add parser can fill, editable by hand — plus the recurrence rule,
  timezone behaviour when you travel, invitee replies, and three one-tap ways
  to resolve the clash."* So the fields are not a generic form; each one exists
  because the parser can produce it and therefore can get it wrong.

  The clash card is the part that has to stay honest. It states the overlap in
  minutes and offers three resolutions, one of which is "Keep both" — an
  overlap the user chose is not an error, and the screen must let them say so.

  Stand-in data until the Calendar domain lands, marked as such.
  """

  @doc "The event the screen edits."
  @spec event() :: map()
  def event do
    %{
      title: "Design review",
      sections: [{"Personal", false}, {"Work", true}],
      fields: fields(),
      clash: clash(),
      invitees: invitees()
    }
  end

  @doc """
  The detail rows. `trailing` says how each one is changed — a value, a switch,
  or a chevron into its own screen — because "1 hour before · at start" cannot
  be edited in place and "Timezone" does not need a screen at all.
  """
  @spec fields() :: [map()]
  def fields do
    [
      %{
        icon: "schedule",
        title: "Thu 20 Aug",
        sub: "09:30 – 10:30",
        trailing: {:value, "1h"}
      },
      %{
        icon: "public",
        title: "Timezone",
        sub: "Europe/London · follows travel",
        trailing: {:switch, true}
      },
      %{
        icon: "repeat",
        title: "Repeats",
        sub: "Every 2 weeks on Thursday",
        trailing: :chevron
      },
      %{
        icon: "notifications",
        title: "Alerts",
        sub: "1 hour before · at start",
        trailing: :chevron
      },
      %{
        icon: "place",
        title: "Location",
        sub: "Studio B, or a link",
        trailing: :chevron
      }
    ]
  end

  @doc "The overlap, and the three ways out of it."
  @spec clash() :: map()
  def clash do
    %{
      line: "Overlaps Standup by 15 min",
      actions: [
        {"Shift 15m later", :primary},
        {"Shorten to 45m", :primary},
        {"Keep both", :quiet}
      ]
    }
  end

  @doc """
  The guest list. A reply is a state with its own glyph — accepted is a filled
  green check, silence is a grey clock — so "no reply yet" reads as pending
  rather than declined.
  """
  @spec invitees() :: [map()]
  def invitees do
    [
      %{name: "Jo Mercer", sub: "accepted", seed: "face32", state: :accepted},
      %{name: "Tomas Rhee", sub: "no reply yet", seed: "face14", state: :waiting}
    ]
  end
end
