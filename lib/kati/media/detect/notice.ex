defmodule Kati.Media.Detect.Notice do
  @moduledoc """
  Telling the reader that Kati heard something it could not place.

  A question nobody knows about is a question nobody answers. Auto-detect's
  whole failure mode is silent: it hears `Sousou no Frieren`, finds nothing on
  the shelf under that name, and puts a card on screen 36 — a settings page
  three taps down that nobody has a reason to open. The reader would find it
  weeks later, by which time they cannot remember what they were watching.

  So Kati says so, once per name, at the moment they have just finished
  watching the thing — which is the moment they can answer from memory, and the
  moment the card's suggestions are worth reading.

  ## One per name, and nothing else

  This is the only notification auto-detect sends. It does not announce a
  successful tick: a feature whose entire promise is *stop telling me things
  you already know* must not then tell you every time it works.

  `:tv` is the budget domain, because that is what it is about — it competes
  with release reminders for the same allowance rather than getting its own.

  Cancelled when the question is answered, wherever it is answered from: a
  notification about a card that is gone is a notification that wastes a tap.
  """

  alias Kati.Notifications.Candidate
  alias Kati.Notifications.Delivery

  @domain :tv

  @doc """
  Say that `heard` played and Kati could not place it.

  Answers `:ok` whatever happens, including on a build with no notification
  backend — a detector that crashed a media callback because a notification
  could not be posted would be worse than a silent queue.
  """
  @spec heard(String.t()) :: :ok
  def heard(title) when is_binary(title) do
    Candidate.absolute(
      Kati.Media.Detect.Notice.id(title),
      @domain,
      Kati.Time.now(),
      title: "What was that?",
      body:
        "Kati heard “#{title}” play and found nothing on your shelf. " <>
          "Tap to connect it to a title.",
      priority: :low,
      meta: %{"screen" => "auto_detect", "heard" => title}
    )
    |> Delivery.backend().arm()
    |> then(fn _outcome -> :ok end)
  rescue
    _error -> :ok
  end

  def heard(_other), do: :ok

  @doc "Take the notice down — the question has been answered."
  @spec answered(String.t()) :: :ok
  def answered(title) when is_binary(title) do
    _ = Delivery.backend().cancel(Kati.Media.Detect.Notice.id(title))
    :ok
  rescue
    _error -> :ok
  end

  def answered(_other), do: :ok

  @doc """
  One id per heard name, so a name heard twice does not notify twice.

  Hashed rather than interpolated: the id is a `SharedPreferences` key on the
  Kotlin side, and an announced name is arbitrary text from another app —
  including newlines, colons and emoji.

      iex> Kati.Media.Detect.Notice.id("Frieren") == Kati.Media.Detect.Notice.id("frieren ")
      true

      iex> Kati.Media.Detect.Notice.id("Frieren") == Kati.Media.Detect.Notice.id("Severance")
      false
  """
  @spec id(String.t()) :: String.t()
  def id(title) do
    digest =
      title
      |> Kati.Import.Job.name_key()
      |> then(&:crypto.hash(:sha256, &1))
      |> Base.encode16(case: :lower)
      |> binary_part(0, 16)

    "detect-heard-" <> digest
  end
end
