defmodule Kati.Media.Detect.Near do
  @moduledoc """
  The titles an announced name is probably about, ranked.

  Exact matching decides what Kati may **tick**, and it is deliberately strict:
  `Se7en` and `Seven` are two films, and a wrong tick lands in a watch history
  nobody audits. That strictness is right for a machine acting alone and wrong
  as the last word to a person — a reader told *“Frieren.S01E05.1080p.WEB-DL”
  is not on your shelf* is being asked to do work Kati could have done.

  So this is the other half: when nothing matches exactly, Kati offers **the
  two or three titles it thinks it might be**, and the reader taps one. The
  ranking never ticks anything by itself. It only decides what to put in front
  of somebody, which is a decision that is allowed to be approximate.

  ## How the ranking works, in full

  A name is reduced to a bag of words — lower case, punctuation dropped,
  release noise removed (`1080p`, `x265`, `WEB-DL`, a bracketed fansub group,
  an `S01E05` marker and everything after it). That is `tokens/1`, and it is
  the same reduction on both sides.

  Two names are then scored on those bags:

    * **containment** — how much of the shorter bag the longer one holds.
      `frieren` inside `frieren beyond journeys end` is 1.0. This is what makes
      a short announced name find a long shelf title, which is the commonest
      real case.
    * **overlap** — the Jaccard ratio, which containment alone would ignore.
      It is what stops `the` matching everything: a one-word intersection out
      of nine distinct words is a poor result even at containment 1.0.

  The score is `containment * 0.7 + overlap * 0.3`, floored at `@floor`, and a
  match must additionally share at least one token of three characters or more
  — so `a`, `the` and `of` cannot carry a suggestion on their own.

  Weighted rather than either alone because they fail in opposite directions:
  containment says a single common word is a perfect match, overlap says a
  correct short name inside a long one is a poor one. The pair disagrees only
  where the answer is genuinely uncertain, which is where the reader is being
  asked anyway.

  ## Why not a string-distance library

  Levenshtein on whole titles scores `Frieren: Beyond Journey's End` against
  `Sousou no Frieren` terribly — they share one word and almost no characters —
  and that pair is precisely the case this exists for. Word-set scoring gets it
  right and is explainable to whoever reads this next, which a distance
  threshold is not.
  """

  alias Kati.Media.CachedTitle

  # Below this a suggestion is noise, and a card of noise is worse than a card
  # that admits it does not know.
  @floor 0.34

  # Words that carry no evidence either way, dropped from both sides.
  #
  # Both halves earn their place, measured on real pairs:
  #
  #   * without the STOPWORDS, `The Bear` scored 0.45 against `The Crown` —
  #     over the floor, on the strength of the word "the". Two unrelated shows
  #     suggested for each other is exactly the noise a card of guesses must
  #     not contain.
  #   * without them, `Sousou no Frieren` scored 0.28 against
  #     `Frieren: Beyond Journey's End` — UNDER the floor, so the one case
  #     anime readers actually hit produced no suggestion at all. Dropping
  #     `no` and the possessive `s` lifts it to 0.41.
  #
  # `no` is a real word in romaji titles and is dropped anyway: it is dropped
  # on BOTH sides, so it can never be the difference between two candidates —
  # it can only stop being the whole of a match.
  @stopwords ~w(the a an of and or no in on at to for with from le la les el)

  # What a release name carries that a title never does. Dropped from both
  # sides, so a shelf title that genuinely contained one would still match.
  @noise ~w(
    1080p 720p 480p 2160p 4k uhd hdr sdr x264 x265 h264 h265 hevc av1
    web webrip webdl bluray bdrip brrip hdtv dvdrip remux proper repack
    extended uncut aac ac3 dts ddp opus flac mp3 subs dub dubbed sub subbed
    multi dual audio season episode part ep
  )

  @doc """
  The best few titles this name might be, as `{tracked, cached, score}`.

  Empty when nothing clears the floor, which is a real answer: the card then
  offers *Add it* and *Not mine* and does not pretend to a guess.
  """
  @spec ranked(String.t(), [{struct(), struct() | nil}], pos_integer()) :: [
          {struct(), struct() | nil, float()}
        ]
  def ranked(heard, shelf, limit \\ 3) do
    wanted = Kati.Media.Detect.Near.tokens(heard)

    if wanted == [] do
      []
    else
      shelf
      |> Enum.map(fn {tracked, cached} ->
        {tracked, cached, Kati.Media.Detect.Near.best(wanted, tracked, cached)}
      end)
      |> Enum.filter(fn {_t, _c, score} -> score >= @floor end)
      |> Enum.sort_by(fn {_t, _c, score} -> score end, :desc)
      |> Enum.take(limit)
    end
  end

  @doc false
  @spec best([String.t()], struct(), struct() | nil) :: float()
  def best(wanted, tracked, cached) do
    case CachedTitle.names(cached) do
      [] -> [tracked.source_id]
      names -> names
    end
    |> Enum.map(&Kati.Media.Detect.Near.score(wanted, Kati.Media.Detect.Near.tokens(&1)))
    |> Enum.max(fn -> 0.0 end)
  end

  @doc """
  How alike two token bags are, between 0.0 and 1.0.

      iex> alias Kati.Media.Detect.Near
      iex> Near.score(Near.tokens("Frieren"), Near.tokens("Frieren: Beyond Journey's End"))
      0.77

      iex> alias Kati.Media.Detect.Near
      iex> Near.score(Near.tokens("The Bear"), Near.tokens("The Crown"))
      0.0

      iex> alias Kati.Media.Detect.Near
      iex> Near.score(Near.tokens("Dune"), Near.tokens("Dune"))
      1.0
  """
  @spec score([String.t()], [String.t()]) :: float()
  def score([], _other), do: 0.0
  def score(_wanted, []), do: 0.0

  def score(wanted, other) do
    a = MapSet.new(wanted)
    b = MapSet.new(other)
    shared = MapSet.intersection(a, b)

    # A one-letter word in common is a coincidence, not a match.
    if Enum.any?(shared, &(String.length(&1) >= 3)) do
      containment = MapSet.size(shared) / min(MapSet.size(a), MapSet.size(b))
      overlap = MapSet.size(shared) / MapSet.size(MapSet.union(a, b))

      Float.round(containment * 0.7 + overlap * 0.3, 2)
    else
      0.0
    end
  end

  @doc """
  A name as the words worth comparing.

      iex> Kati.Media.Detect.Near.tokens("Frieren.S01E05.1080p.WEB-DL.mkv")
      ["frieren"]

      iex> Kati.Media.Detect.Near.tokens("[SubsPlease] Sousou no Frieren - 05 (1080p)")
      ["sousou", "frieren"]

      iex> Kati.Media.Detect.Near.tokens("The Bear")
      ["bear"]

      iex> Kati.Media.Detect.Near.tokens("")
      []
  """
  @spec tokens(String.t() | nil) :: [String.t()]
  def tokens(name) when not is_binary(name), do: []

  def tokens(name) do
    name
    |> String.downcase()
    # A bracketed group is a release tag, never part of a title.
    |> String.replace(~r/[\[\(\{][^\]\)\}]*[\]\)\}]/u, " ")
    |> Kati.Media.Detect.unfile()
    |> String.replace(~r/[^\p{L}\p{N}]+/u, " ")
    |> String.split(" ", trim: true)
    |> Enum.reject(&(&1 in @noise or &1 in @stopwords))
    # A single character is a possessive left by `Journey's`, an initial, or a
    # separator — never evidence.
    |> Enum.reject(&(String.length(&1) < 2))
    # A bare number is an episode or a year far more often than a title, but a
    # title that is ONLY a number keeps it — `1917`, `2012`.
    |> then(fn words ->
      case Enum.reject(words, &String.match?(&1, ~r/^\d+$/)) do
        [] -> words
        kept -> kept
      end
    end)
    |> Enum.uniq()
  end
end
