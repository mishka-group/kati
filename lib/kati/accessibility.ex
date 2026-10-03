defmodule Kati.Accessibility do
  @moduledoc """
  The three display choices screen 41 offers, stored and read app-wide.

    * **Reduce motion** — a page change cross-fades instead of sliding.
    * **Text size** — `:system`, `:large` or `:larger`, multiplied onto the
      phone's own text size, so Kati can be larger than the rest of the phone.
    * **Increase contrast** — the quiet greys and hairlines take the next step
      darker (lighter in dark), through `Kati.Theme.Palette`.

  ## How each one reaches the screen

  Motion and text size are the native side's to apply: Compose owns the slide
  and the density. Every screen's root node carries `reduce_motion` and
  `text_scale` (`motion_prop/0`, `scale_prop/0`), read by fence
  `K-72 display-root` in `MainActivity`, the same way `K-12` reads
  `layout_direction`. Android's own *Remove animations* reduces motion as well,
  whatever is stored here.

  Contrast is the BEAM's: a colour is a number in the tree, so
  `Kati.Theme.Palette` asks `contrast?/0` when it resolves a token.

  ## Storage

  `Mob.State`, as `Kati.Theme.Mode` and `Kati.Locale` keep theirs: a screen
  process dies on every root switch, so assigns cannot hold it. Reads go
  through `:persistent_term`, because the palette asks `contrast?/0` once per
  colour on every render and a `Mob.State` call is a GenServer round trip.
  `put_*` writes the store first and the cache second.
  """

  @motion_key :reduce_motion
  @scale_key :text_scale
  @contrast_key :high_contrast

  @scales [:system, :large, :larger]
  @factors %{system: 1.0, large: 1.15, larger: 1.3}

  @type scale :: :system | :large | :larger

  @doc "Every text size, in the order the control draws them."
  @spec scales() :: [scale()]
  def scales, do: @scales

  @doc """
  The multiplier a text size puts on the phone's own.

      iex> Kati.Accessibility.factor(:system)
      1.0
      iex> Kati.Accessibility.factor(:larger)
      1.3
  """
  @spec factor(scale()) :: float()
  def factor(scale) when scale in @scales, do: Map.fetch!(@factors, scale)

  @doc "Whether page changes cross-fade instead of sliding."
  @spec reduce_motion?() :: boolean()
  def reduce_motion?, do: cached(@motion_key, false) == true

  @doc "The stored text size; `:system` until one is chosen."
  @spec text_scale() :: scale()
  def text_scale do
    case cached(@scale_key, :system) do
      s when s in @scales -> s
      _other -> :system
    end
  end

  @doc "Whether the quiet greys and hairlines are drawn a step stronger."
  @spec contrast?() :: boolean()
  def contrast?, do: cached(@contrast_key, false) == true

  @doc "Store *Reduce motion*."
  @spec put_reduce_motion(boolean()) :: :ok
  def put_reduce_motion(on?) when is_boolean(on?), do: store(@motion_key, on?)

  @doc "Store a text size."
  @spec put_text_scale(scale()) :: :ok
  def put_text_scale(scale) when scale in @scales, do: store(@scale_key, scale)

  @doc "Store *Increase contrast*."
  @spec put_contrast(boolean()) :: :ok
  def put_contrast(on?) when is_boolean(on?), do: store(@contrast_key, on?)

  @doc """
  The root prop `K-72` reads for motion.

      iex> Kati.Accessibility.motion_prop(true)
      "reduce"
      iex> Kati.Accessibility.motion_prop(false)
      "full"
  """
  @spec motion_prop(boolean()) :: String.t()
  def motion_prop(on? \\ reduce_motion?())
  def motion_prop(true), do: "reduce"
  def motion_prop(false), do: "full"

  @doc "The root prop `K-72` reads for text size: the multiplier."
  @spec scale_prop(scale()) :: float()
  def scale_prop(scale \\ text_scale()), do: factor(scale)

  @doc """
  Forget the cached values, so the next read goes back to the store.

  For tests that write `Mob.State` directly, and for nothing else.
  """
  @spec forget() :: :ok
  def forget do
    Enum.each([@motion_key, @scale_key, @contrast_key], &:persistent_term.erase({__MODULE__, &1}))
    :ok
  end

  defp store(key, value) do
    Mob.State.put(key, value)
    :persistent_term.put({__MODULE__, key}, {Process.whereis(Mob.State), value})
    :ok
  end

  # Each cached value carries the `Mob.State` process it was read from. A
  # different process is a different store — a restart, or a test's fresh
  # throwaway one — and the value is read again rather than trusted.
  defp cached(key, default) do
    owner = Process.whereis(Mob.State)

    case :persistent_term.get({__MODULE__, key}, :unread) do
      {^owner, value} when owner != nil -> value
      _unread_or_stale -> read(key, default, owner)
    end
  end

  # Before `Mob.State` is up — a design board rendered on the host, a palette
  # test — there is no stored choice to read, and the default is the truthful
  # answer. It is not cached, so the first read once the store is up wins.
  defp read(_key, default, nil), do: default

  defp read(key, default, owner) do
    value = Mob.State.get(key, default)
    :persistent_term.put({__MODULE__, key}, {owner, value})
    value
  rescue
    _error -> default
  catch
    :exit, _reason -> default
  end
end
