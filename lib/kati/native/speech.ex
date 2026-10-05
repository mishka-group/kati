defmodule Kati.Native.Speech do
  @moduledoc """
  Dictation through the phone's own speech recognizer.

  Android's `RecognizerIntent` puts the system recognizer in front of the
  reader (`K-76 speech-listen`): Kati asks for no microphone permission and
  handles no audio, it is handed the words. The answer arrives later at the
  calling process as `{:kati_speech, …}`, which `decode/1` reads. iOS has the
  same capability in `SFSpeechRecognizer` and is not wired yet, so `listen/1`
  answers `{:error, :no_bridge}` there.
  """

  alias Kati.Native.Bridge

  @doc "Open the recognizer, in the reader's language, with `prompt` on it."
  @spec listen(String.t()) :: :ok | {:error, atom()}
  def listen(prompt) do
    payload = %{"language" => language(), "prompt" => prompt}

    case Bridge.reply(:speech_listen, [Bridge.encode(payload)]) do
      {:ok, reply} ->
        case Bridge.split(reply) do
          {:ok, _} -> :ok
          {:error, _reason} -> {:error, :unavailable}
        end

      {:error, :no_bridge} ->
        {:error, :no_bridge}

      {:error, _other} ->
        {:error, :unavailable}
    end
  end

  @doc """
  The recognizer's answer as a value.

      iex> Kati.Native.Speech.decode({:kati_speech, :heard, [%{text: "dentist tomorrow 3pm"}]})
      {:heard, "dentist tomorrow 3pm"}

      iex> Kati.Native.Speech.decode({:kati_speech, :cancelled})
      :cancelled

      iex> Kati.Native.Speech.decode({:kati_speech, :error, [%{reason: "unavailable"}]})
      {:error, :unavailable}
  """
  @spec decode(term()) :: {:heard, String.t()} | :cancelled | {:error, atom()} | :ignore
  def decode({:kati_speech, :heard, [item | _]}), do: {:heard, to_string(item[:text] || "")}
  def decode({:kati_speech, :cancelled}), do: :cancelled
  def decode({:kati_speech, :cancelled, _}), do: :cancelled
  def decode({:kati_speech, :error, _}), do: {:error, :unavailable}
  def decode(_other), do: :ignore

  @doc false
  def language do
    case Kati.Locale.current() do
      :fa -> "fa-IR"
      _ -> "en-US"
    end
  end
end
