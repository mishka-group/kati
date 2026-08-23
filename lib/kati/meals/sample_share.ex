defmodule Kati.Meals.SampleShare do
  @moduledoc """
  Sharing, importing and exporting a plan — screen 50, as data.

  A stand-in for the Meals domain. The copy is the design's own, from
  `.scratch/design/screens/50.html`.

  The screen's argument is that a plan is a **portable document**: a QR or a
  link hands it over, an explicit list says what travels with it, and history
  never leaves the device. `travels/0` is therefore a list of switches rather
  than a paragraph — the promise is checkable rather than claimed, and the one
  that is off is the one about you.

  ## The QR code

  Nine rows of nine, exactly the module pattern the export draws. It is a
  drawing of a QR code, not a scannable one — the real code is generated from
  the plan when the domain exists — so it lives here beside the other sample
  content rather than pretending to be an encoder.
  """

  @doc "Everything screen 50 shows, in the order it shows it."
  @spec share() :: map()
  def share do
    %{
      plan: "Cutting v3",
      subtitle: "share & transfer",
      qr: qr(),
      qr_title: "Scan to import this plan",
      qr_uri: "KATI://PLAN/CUTTING-V3 · SETTINGS ONLY",
      travels: travels(),
      shared_with: shared_with(),
      transfer: transfer()
    }
  end

  @doc """
  What the QR actually carries, which is not the plan.

  ## `SETTINGS ONLY`, and the board said `35 MEALS`

  A QR code holds a few kilobytes. *Cutting v3* is 35 slots, each naming a
  recipe with its ingredients and macros, and it does not fit — a library never
  will. The board's `KATI://PLAN/CUTTING-V3 · 35 MEALS` promises a payload the
  format cannot carry, and a QR that silently fails on a big plan is worse than
  one that never offered.

  So the code carries **the plan's shape and its settings** — its name, its
  five slot labels, its repeat rule, its reminder settings — and not the meals
  behind them. Someone who scans it gets the plan's skeleton and fills it with
  their own recipes, which is what a plan shared between two people is for
  anyway: the second person does not want the first person's salmon.

  ## And the whole-library path already exists

  `Kati.Screens.PlanShare`'s export row and screen 128's backup are where a big
  payload belongs, because a file has no size limit worth worrying about. Two
  mechanisms for two clearly different sizes of thing, rather than one
  mechanism that works until it does not.

  #71 asked whether the QR carries the payload or becomes a pairing token with
  a transfer channel that does not exist. This is the third answer: it carries
  a *small, whole, useful* thing, and says so on its own face.
  """
  @spec qr_scope() :: String.t()
  def qr_scope, do: "SETTINGS ONLY"

  @doc "The 9x9 module grid the design draws, one string per row, 1 = ink."
  @spec qr() :: [String.t()]
  def qr do
    [
      "111011110",
      "101011110",
      "101110000",
      "111110011",
      "001100110",
      "011001011",
      "111001110",
      "000011001",
      "101100111"
    ]
  end

  @doc """
  What travels with the plan, and the one thing that never does.

  Your history and notes are off and stay off. Drawing it as a switch that is
  simply not on would be a lie about what the app can do, so the design puts
  the promise in the sub-line — "Never shared" — and lets the switch state
  agree with it.
  """
  @spec travels() :: [map()]
  def travels do
    [
      %{
        icon: "restaurant",
        title: "Meals & recipes",
        sub: "All 35, with photos",
        on: true
      },
      %{
        icon: "monitor_heart",
        title: "Targets",
        sub: "2,100 kcal · macro split",
        on: true
      },
      %{
        icon: "notifications",
        title: "Reminder times",
        sub: "Recipient can change them",
        on: true
      },
      %{
        icon: "history",
        title: "Your history & notes",
        sub: "Never shared",
        on: false
      }
    ]
  end

  @doc """
  The two ways someone can hold your plan, which are not the same thing.

  Jo follows it and receives your edits, so she has a switch. Ada took a copy,
  which is a past event and cannot be revoked — so she has a glyph, not a
  control that would imply otherwise.
  """
  @spec shared_with() :: [map()]
  def shared_with do
    [
      %{
        seed: "face32",
        name: "Jo Mercer",
        sub: "Following · gets your edits",
        trail: {:toggle, true}
      },
      %{
        seed: "face45",
        name: "Ada Vance",
        sub: "Took a copy · 12 Aug",
        trail: {:icon, "content_copy"}
      }
    ]
  end

  @doc "Import accepts the same file export produces, which is the point."
  @spec transfer() :: [map()]
  def transfer do
    [
      %{icon: "qr_code_scanner", title: "Scan a plan", sub: "From a QR code or link"},
      %{icon: "upload_file", title: "Import a file", sub: "JSON, CSV, or a recipe URL"},
      %{icon: "download", title: "Export this plan", sub: "JSON · portable, human-readable"},
      %{icon: "picture_as_pdf", title: "Print the week", sub: "One page, fridge-sized"}
    ]
  end
end
