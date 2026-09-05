defmodule Kati.Native.Links do
  @moduledoc """
  The one place Kati hands a URL to the phone.

  ## Fifteen controls were waiting on this

  Screens 83, 84 and 85 draw twelve source cards between them — TMDB,
  JustWatch, TVmaze, Open Library, MusicBrainz, ListenBrainz, and the notices
  row — and every one of them named a website and went nowhere. So did the
  three *Open system settings* pills on the battery and notification-listener
  sheets. `Kati.ScreenTapSweepTest` carried all fifteen on `@inert_taps` with
  the same sentence written against each: *Kati has no fence that opens an
  external link.* That sentence was true, and it was the only thing between
  those controls and working.

  ## Why a module rather than a call

  Because a link that cannot open has to say so. `Kati.Native.Bridge` answers
  `{:error, :no_bridge}` on a host, `"error:no_handler"` on a phone with no
  browser, and `"error:unsupported_scheme"` for anything that is not `http` or
  `https` — and a screen needs one sentence out of those, not three shapes.
  `message/1` is that sentence, and it is the reason this is not
  `Bridge.reply(:open_url, [url])` at fifteen call sites.

  The search field taught this: screen 06 composed a perfectly good sentence
  about a failed search and drew none of it, and the result was
  indistinguishable from a catalogue with nothing in it. A link that quietly
  does nothing is the same defect wearing a chevron.

  ## Only `http` and `https`, and the refusal is on both sides

  The Kotlin fence refuses any other scheme and so does `open/1`, which is
  deliberate duplication: the strings reaching here come from
  `Kati.Services.Attribution`'s own table today, and a table is one refactor
  away from being a cached API response. A bridge that opened any scheme would
  open `intent:` and `file:` with it.
  """

  alias Kati.Native.Bridge

  @type reason ::
          :no_bridge | :no_handler | :unsupported_scheme | :unparseable | :no_context | :failed

  @doc """
  Open `url` in whatever the phone opens links with.

  `:ok` once the intent is away — which is not the same as *the page loaded*,
  and nothing here can know that. Android hands the URL to another app and
  stops talking about it, the way `Kati.Native.Files.share/2` does and for the
  same reason its docs give.
  """
  @spec open(binary()) :: :ok | {:error, reason()}
  def open(url) when is_binary(url) do
    if http?(url) do
      case Bridge.reply(:open_url, [url]) do
        {:ok, "ok"} -> :ok
        {:ok, "error:" <> reason} -> {:error, reason(reason)}
        {:ok, _other} -> {:error, :failed}
        {:error, :no_bridge} -> {:error, :no_bridge}
        {:error, _other} -> {:error, :failed}
      end
    else
      {:error, :unsupported_scheme}
    end
  end

  def open(_other), do: {:error, :unsupported_scheme}

  @doc """
  Whether a string is a link this will carry — `http` or `https` and nothing
  else.

      iex> Kati.Native.Links.http?("https://www.themoviedb.org")
      true

      iex> Kati.Native.Links.http?("intent://evil")
      false

      iex> Kati.Native.Links.http?("")
      false
  """
  @spec http?(term()) :: boolean()
  def http?(url) when is_binary(url) do
    case URI.parse(url) do
      %URI{scheme: scheme, host: host} when scheme in ["http", "https"] ->
        is_binary(host) and host != ""

      _other ->
        false
    end
  end

  def http?(_other), do: false

  @doc """
  What to draw when a link did not open.

  One sentence per reason, in the register `Kati.Write.message/1` uses: what
  happened, and what the reader can do about it. `:no_bridge` is the host and
  the emulator-without-a-browser case both, and it says the honest thing
  rather than naming a bridge nobody outside this repo has heard of.

      iex> Kati.Native.Links.message(:no_handler)
      "No app on this phone opens links."

      iex> Kati.Native.Links.message(:unsupported_scheme)
      "That is not a web address."
  """
  @spec message(reason()) :: String.t()
  def message(:no_handler), do: "No app on this phone opens links."
  def message(:unsupported_scheme), do: "That is not a web address."
  def message(:unparseable), do: "That is not a web address."
  def message(:no_bridge), do: "Links do not open here yet."
  def message(:no_context), do: "Links do not open here yet."
  def message(_other), do: "That link did not open. Nothing else changed."

  defp reason("no_handler"), do: :no_handler
  defp reason("unsupported_scheme"), do: :unsupported_scheme
  defp reason("unparseable"), do: :unparseable
  defp reason("no_context"), do: :no_context
  defp reason(_other), do: :failed
end
