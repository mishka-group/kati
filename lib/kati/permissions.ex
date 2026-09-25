defmodule Kati.Permissions do
  @moduledoc """
  What Kati is actually allowed to do, read rather than remembered.

  ## Why this exists

  `Mob.Permissions.request/2` raises the dialog and delivers
  `{:permission, capability, :granted | :denied}`. There is no matching read —
  nothing in Mob answers *is `:calendar` granted right now* — and screen 40's
  entire purpose is to state what Kati may do. Screen 40's own moduledoc had
  recorded the gap and drawn the trailing states as pictures because of it.

  A remembered answer is worse than none. A permission can be changed in system
  settings while Kati is backgrounded, which is the normal way permissions get
  revoked, so an app-local boolean copying the OS becomes a lie the moment it
  matters. Every read here goes to the platform.

  ## Four states, because Android's are not symmetric

    * `:granted`
    * `:unasked` — never requested, so an **Allow** button is the right control
    * `:denied` — refused once; asking again still shows the dialog
    * `:blocked` — refused permanently. `request/2` will not re-prompt, so the
      only honest affordance is a link to system settings

  Android cannot tell `:unasked` from `:blocked` on its own:
  `shouldShowRequestPermissionRationale` is false for both. The disambiguator
  is Kati's own record of having asked, kept in `Mob.State` — and note which
  way round that record is safe. Being wrong about *asked* shows an Allow
  button that opens settings instead; being wrong about *granted* would state
  a capability Kati does not have. Only the first is recoverable, so the record
  is consulted for exactly one thing and never for whether a permission is
  held.

  ## What is not here

  Install-time permissions — `INTERNET`, `VIBRATE`, `RECEIVE_BOOT_COMPLETED` —
  have no runtime state to read. They are granted by being declared, and a
  screen should state them as facts rather than draw a control that cannot do
  anything. See `Kati.Screens.Account`.
  """

  alias Kati.Native.Bridge

  @type capability :: :notifications | :calendar | :exact_alarms
  @type state :: :granted | :denied | :blocked | :unasked | :unknown

  @asked_key :permissions_asked

  @doc """
  Every capability screen 40 reports on, in the order it draws them.

  Exactly what `AndroidManifest.xml` declares and Kati uses — not the stock
  template's list. Camera, microphone, location and the media-library
  permissions are deliberately absent from the manifest (K-30, K-31), so a row
  for any of them would be asking about something Kati cannot do.
  """
  @spec runtime_capabilities() :: [capability()]
  def runtime_capabilities, do: [:notifications, :calendar, :exact_alarms]

  @doc """
  The platform's answer for `capability`, right now.

  `:unknown` when the native half is absent — on a host, or if the bridge
  method goes missing — or cannot answer yet, as on Android right after a hot
  deploy. Deliberately not folded into `:denied`: a screen can say "not
  available here" where it would otherwise offer an Allow button that cannot
  work. `platform_answers?/0` tells the two apart.
  """
  @spec status(capability()) :: state()
  def status(capability) when is_atom(capability) do
    case Bridge.reply(:permission_status, [Atom.to_string(capability)]) do
      {:ok, reply} -> decode(reply, capability)
      _ -> :unknown
    end
  end

  @doc """
  Whether this build runs somewhere that answers `status/1` at all.

  `true` on Android, the one platform whose build carries the bridge, and
  `false` on a host or on iOS, where `status/1` answers `:unknown` for good.
  The two `:unknown`s mean different things and a screen has to say different
  words for them: off Android it is a fact about the platform, and on Android
  it is a read that happened before the native half could answer — right after
  a hot deploy reloads the bridge's module, or while a restored screen mounts
  ahead of it (N17). The second is worth reading again; the first is not.

  Asked of `:mob_nif.platform/0`, which is not a bridge call and so answers
  the same whether or not the bridge is ready yet — and only once `:mob_nif`
  is loaded, which it is before any screen mounts on a phone and never is on a
  host. Calling it unloaded would retry the failing `on_load` on every row of
  every render, so `Code.loaded?/1` asks first without loading anything.
  """
  @spec platform_answers?() :: boolean()
  def platform_answers? do
    Code.loaded?(:mob_nif) and :mob_nif.platform() == :android
  rescue
    _error -> false
  end

  @doc """
  Records that Kati has asked for `capability`.

  Call it beside `Mob.Permissions.request/2`, not instead of it. Without this,
  a permanently denied permission reads as never-asked forever and the screen
  offers an Allow button that Android will silently refuse to act on.
  """
  @spec note_asked(capability()) :: :ok
  def note_asked(capability) when is_atom(capability) do
    Mob.State.put(@asked_key, Enum.uniq([capability | asked()]))
    :ok
  end

  @doc "Which capabilities Kati has asked for at least once."
  @spec asked() :: [capability()]
  def asked do
    case Mob.State.get(@asked_key, []) do
      list when is_list(list) -> list
      _ -> []
    end
  end

  @doc "Clears the asked record. For tests and for a future *Reset* row."
  @spec forget_asked!() :: :ok
  def forget_asked! do
    Mob.State.put(@asked_key, [])
    :ok
  end

  @doc """
  Whether a state should offer *Allow*, *Open settings*, or nothing.

  Pure, so a screen's control choice is testable without a device.
  """
  @spec affordance(state()) :: :allow | :settings | :none
  def affordance(:unasked), do: :allow
  def affordance(:denied), do: :allow
  def affordance(:blocked), do: :settings
  def affordance(_state), do: :none

  # ── Internals ──────────────────────────────────────────────────────────────

  defp decode(reply, capability) when is_binary(reply) do
    case Bridge.split(reply) do
      {:ok, "granted"} ->
        :granted

      {:ok, "denied:true"} ->
        # Android will show the dialog again, so Allow is a real control.
        :denied

      {:ok, "denied:false"} ->
        # Never asked, or refused permanently — Android reports both the same
        # way. Kati's own record is the only thing that separates them.
        if capability in asked(), do: :blocked, else: :unasked

      _ ->
        :unknown
    end
  end

  defp decode(_reply, _capability), do: :unknown
end
