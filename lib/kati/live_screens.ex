defmodule Kati.LiveScreens do
  @moduledoc """
  Every screen process that is alive, so a change that every one of them shows
  can reach them before they are looked at again.

  Mob keeps each screen in its own process, and the ones under the top of the
  stack stay resident: a back tap paints the screen underneath from that
  process, as it last left it, and only then does `Kati.Screens.Resume`'s
  `:resumed` arrive. For a read that is a moment of the old number. For the
  language it was a moment of the old LANGUAGE (#112): `Gettext.put_locale/2`
  is per process, so the screen underneath still spoke the language it was
  mounted in, and drew in it, before anything told it otherwise.

  So a change of language is broadcast here as `{:kati, :locale_changed,
  locale}` the moment it is stored. `Kati.Screens.Root.rescue_kati/4` answers
  it for every macro screen: the locale is resolved into that process and the
  screen's own `:resumed` refresh runs, so text built at load time is rebuilt
  too. By the time a back tap paints it, it is already in the new language.

  A registry rather than asking Mob for its screens: `Mob.Router` keeps the
  list private. It lives here and under `Kati.Supervisor`, not among the
  screens, which `Kati.SupervisionRuleTest` forbids to register anything: a
  registry entry leaves with its process, so joining cannot make a screen
  outlive itself, and the registry is the supervised thing the rule asks for.
  """

  @registry __MODULE__

  @doc "The registry's child spec, for `Kati.Supervisor`."
  @spec child_spec(term()) :: Supervisor.child_spec()
  def child_spec(_arg), do: Registry.child_spec(keys: :unique, name: @registry)

  @doc """
  Count the calling screen as live. Idempotent, and a no-op where the registry
  is not running (host tests that mount a screen on its own).
  """
  @spec join() :: :ok
  def join do
    if Process.whereis(@registry), do: Registry.register(@registry, self(), nil)
    :ok
  end

  @doc "Send `message` to every live screen but the caller."
  @spec broadcast(term()) :: :ok
  def broadcast(message) do
    if Process.whereis(@registry) do
      for pid <- Registry.select(@registry, [{{:"$1", :_, :_}, [], [:"$1"]}]), pid != self() do
        send(pid, message)
      end
    end

    :ok
  end
end
