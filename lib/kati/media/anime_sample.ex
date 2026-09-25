defmodule Kati.Media.AnimeSample do
  @moduledoc """
  What is left of board 152's stand-in data, which is one design-test value
  and one forwarding call.

  Screen 152 reads the reader's own shelf for every count it draws, and the
  rules and threshold it states are `Kati.Media.Anime`'s. `misclassified/0` is
  the board's worked mistake — `Kati.Library.Sample`'s own Marram, tagged anime
  by a MAL import and actually live action — which the design tests install to
  compare the frame against its capture. No reader path draws it.
  """

  @doc """
  The Library's Anime-chip threshold. Real app behaviour, owned by
  `Kati.Media.Anime.promote_threshold/0`; kept here for the callers that
  still name this module.
  """
  @spec promote_threshold() :: pos_integer()
  defdelegate promote_threshold, to: Kati.Media.Anime

  @doc """
  The one case the guess gets wrong: `Kati.Library.Sample`'s own Marram,
  imported from MAL (rule 2) and actually live action — the case rule 1 exists
  to override. Design tests only.
  """
  @spec misclassified() :: %{title: String.t(), seed: String.t(), note: String.t()}
  def misclassified do
    %{
      title: "Marram",
      seed: "marram15",
      note: "Tagged anime from a MAL import — it is live action"
    }
  end
end
