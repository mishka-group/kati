defmodule Kati.Import.Sample do
  use Gettext, backend: Kati.Gettext

  @moduledoc """
  Stand-in import data, until a real CSV reader exists.

  Screen 37 is drawn mid-job — step 3 of 4, five columns already matched, a
  count of what the write will do, and the first of six conflicts waiting for
  an answer. None of that can be shown against an empty database, and the
  screen's whole argument is that the user sees the consequences *before*
  anything is written, so the drawing's own numbers live here.

  Every string is the design's own copy from `test/design/screens/37.html`
  rather than invented sample text, so the screen can be compared with its
  drawing line for line. When the reader lands, this module is replaced by the
  parse result — the screen reads a map and does not care where it came from.

  `recognised/0` adds a second job for board 141 — a Goodreads export, one
  step earlier than screen 37's Trakt backup: the source has just been
  recognised and the mapping has not been opened yet. It is a different job on
  a different source, not screen 37's job renamed, so it gets its own function
  rather than a second call to `job/0` with a patched `file`.

  ## What folds to Persian here, and what stays Latin

  `Kati.Screens.Import`'s own list, read from the other end: the two screens
  draw this map and owe it the same treatment, and the line between the two
  halves is WHOSE WORDS a string is.

    * **Kati's words fold, and every figure in them is converted.** The
      `Import 412` pill, `418 ROWS · 9 COLUMNS`, the `· step 3 of 4` subtitle,
      `STEP 1 OF 4`, the three outcome labels and their counts, the field name
      on the right of every arrow, each row's note, the conflict's own line and
      its `1 of 6 · apply to all` are this module's sentences *about* a file.
      `Kati.Locale.number/1` on each numeral, because a Latin `418` on a Shamsi
      page is the thing that function exists to stop.
    * **The file's words do not fold.** `trakt-backup.csv`, the column names
      down the left of the mapping card — `watched_at`, `My Rating`,
      `Date Read` — and the first row's value under each are what the READER's
      file says. A msgid over any of them would translate somebody's
      spreadsheet. The headers are also read back:
      `Kati.Screens.ImportRecognised.sample_for/2` matches them through
      `Kati.Import.Mapping.field_for/1`, so a translated header would stop
      matching under `:fa` and only under `:fa`.

  Two strings sit on the boundary and both were decided against the drawing:

    * `(empty in 402 rows)` is drawn in the sample slot and is not a sample. An
      empty cell has no value, so the words under `show_notes` are Kati
      counting rows rather than quoting one, and they fold.
    * `Blue Hour` is in the fixture twice and folds once. The conflict card
      names a title already on the reader's shelf, and
      `Kati.Backup.SampleRestore.conflict/0` — which draws the same film for
      screen 129 and is meant to stay character for character with this one —
      has written it «ساعت آبی» since that board folded. The mapping row's
      `"Blue Hour"` is the first cell of the `title` column, quote marks and
      all, and stays exactly as the file typed it.

  The arrow between the two halves of a mapping row is neither: `icon` stays
  `arrow_forward`, and `Kati.Screens.Import.map_glyph/1` turns it around for a
  reader who reads the other way. Which direction forward is on a page is the
  screen's question, and its doc carries the argument.
  """

  @doc """
  The job screen 37 draws: a Trakt backup, three of four steps done.

  `columns` is the mapping table. `icon` is the glyph the drawing puts between
  the file's column and Kati's field — `arrow_forward` for a match, `block`
  for the one column that will be dropped — and `skipped?` greys the target so
  colour is not the only thing saying it will be ignored.
  """
  @spec job(atom()) :: map()
  def job(source \\ :trakt)

  def job(:trakt) do
    %{
      action: import_pill(),
      file: "trakt-backup.csv",
      subtitle: subtitle("trakt-backup.csv"),
      shape: shape(),
      steps: 4,
      step: 3,
      columns: columns(),
      outcome: outcome(),
      conflict: conflict()
    }
  end

  # The same job for the file screen 141 just counted.
  #
  # MOVIES-AND-TV.md #53. Screen 141 reads a Goodreads export — 418 rows, nine
  # columns, seven matched — and its *Check the mapping* row pushed screen 37,
  # which drew `trakt-backup.csv` and five columns of a film export. Two boards,
  # two fixtures, one chevron between them, and the second one contradicted
  # every number the first had just given.
  #
  # So 37 draws the file it was handed. `recognised_columns/0` is 141's own
  # nine, unchanged, and the rest of the job is 141's own header — the file
  # name, the shape, the step. What 37 adds is the sampled value beside each
  # row, which is the whole reason its board exists, and a Goodreads export has
  # those: they are the first row of the file 141 is describing.
  #
  # The conflict card is `conflict/0`'s, because a conflict is about two records
  # of the same thing and does not depend on which file they came from.
  def job(:goodreads) do
    %{
      action: import_pill(),
      file: "goodreads_library_export.csv",
      subtitle: subtitle("goodreads_library_export.csv"),
      shape: shape(),
      steps: 4,
      step: 3,
      columns: goodreads_columns(),
      outcome: outcome(),
      conflict: conflict()
    }
  end

  def job(_unknown), do: job(:trakt)

  @doc """
  Board 141's nine columns, with the sampled value screen 37 draws beside each.

  `recognised_columns/0` is the same list without the samples, because board
  141's rows never draw one — see its own doc. The values are the first row of
  `goodreads_library_export.csv`, which is what a sample IS: not an example of
  the shape, the reader's actual first record.

  Neither the keys nor the values take a msgid, in either script. The keys are
  the file's own header row, which `Kati.Screens.ImportRecognised.sample_for/2`
  matches back through `Kati.Import.Mapping.field_for/1`; the values are the
  reader's first record, and `date_line/1` reads `2026/03/14` to say *dates
  read as YYYY/MM/DD* and `scale_line/1` reads `8` to say which way the rating
  converts. Persian digits in either would leave both sentences describing a
  column this file does not have.
  """
  @spec goodreads_columns() :: [map()]
  def goodreads_columns do
    samples = %{
      "Title" => ~s("The Long Hollow"),
      "Author" => ~s("Ines Kaur"),
      "My Rating" => "8",
      "Date Read" => "2026/03/14",
      "Bookshelves" => ~s("read, coastal"),
      "My Review" => ~s("The estuary chapters…"),
      "Number of Pages" => "384",
      "Publisher" => ~s("Saltmarsh Press"),
      "Binding" => ~s("Paperback")
    }

    Enum.map(recognised_columns(), fn column ->
      Map.put(column, :sample, Map.get(samples, column.column, ""))
    end)
  end

  @doc """
  The five mapped columns, with the value the drawing samples from row 1.

  ## Why the field names are bare msgids and `Skip` is not

  `Title`, `Watched on`, `Rating`, `Kind` and the four board 141 adds are the
  names of KATI's fields, and `Kati.Import.Mapping`'s `@labels` is the same
  vocabulary for a file that was actually read — the two draw into the same
  slot on the same screen, so they want the same catalogue entry. A bare msgid
  is what gets them one; a context here would split the mapping table in two
  the day that module folds, and screen 37 would name one field two ways
  depending on whether the file was real.

  `skip_field/0` and `skipped_note/0` are the exception and carry their reason.
  """
  @spec columns() :: [map()]
  def columns do
    [
      %{
        column: "title",
        sample: ~s("Blue Hour"),
        icon: "arrow_forward",
        field: gettext("Title"),
        note: nil,
        skipped?: false
      },
      %{
        column: "watched_at",
        sample: "2026-08-12",
        icon: "arrow_forward",
        field: gettext("Watched on"),
        note: nil,
        skipped?: false
      },
      %{
        column: "rating",
        sample: "9",
        icon: "arrow_forward",
        field: gettext("Rating"),
        note: scale_note(),
        skipped?: false
      },
      %{
        column: "type",
        sample: "movie",
        icon: "arrow_forward",
        field: gettext("Kind"),
        note: nil,
        skipped?: false
      },
      %{
        column: "show_notes",
        # Not a sample. Every other row under this heading quotes the file's
        # first cell; this one says why there is nothing to quote, which makes
        # it Kati's sentence and not the reader's. `ngettext/4` because English
        # inflects the noun after the numeral and Persian does not — ۱ ردیف and
        # ۴۰۲ ردیف are both correct — so the Persian plural is the singular.
        sample:
          ngettext("(empty in %{n} row)", "(empty in %{n} rows)", 402, n: Kati.Locale.number(402)),
        icon: "block",
        field: skip_field(),
        note: skipped_note(),
        skipped?: true
      }
    ]
  end

  @doc """
  What the write will do, as three counts.

  Green for merged and red for conflicts, because those are the two outcomes
  a person actually has to think about; new rows are the boring majority and
  stay ink.

  The three labels are `Kati.Import.Job.outcome/1`'s own msgids, so the board
  and a real file say the same three words; the figures go through
  `Kati.Locale.number/1` for the same reason that module's do, and a Latin
  `384` on a Shamsi page is what that function exists to stop.

  Neither screen has to be told which face that leaves. Board 37 sets its
  counts in Plus Jakarta and asks `Kati.Locale.mono_face/1` only about the
  label; board 141 sets both in DM Mono and asks it about both — and it asks
  the STRING rather than the reader, so «ادغام» and ۳۸۴ take Vazirmatn while
  the English `MERGED` and `384` keep DM Mono, which has no Persian digit in it.
  """
  @spec outcome() :: [map()]
  def outcome do
    [
      %{value: Kati.Locale.number(384), label: gettext("New"), color: 0xFF1A1917},
      %{value: Kati.Locale.number(28), label: gettext("Merged"), color: 0xFF4E9A73},
      %{value: Kati.Locale.number(6), label: gettext("Conflicts"), color: 0xFFB4553C}
    ]
  end

  @doc """
  The conflict on top of the pile.

  One at a time, with `apply to all` offered underneath rather than as the
  default — six decisions is a short queue and a blanket answer to a question
  you have not read is how an import quietly destroys a rating.

  Every string here is already in the catalogue, and all four come from the one
  board this card was copied onto: `Kati.Backup.SampleRestore.conflict/0` is
  screen 129 drawing screen 37's conflict resolver verbatim, down to the film.
  Two copies of the same card that fold to two different Persians would be the
  drift that module's own doc says the copy exists to avoid, so this reuses its
  msgids rather than writing four more.

  The `★` survives into Persian on purpose. `kati_fa_400.ttf` has no U+2605 —
  which is why the two mapping notes below say their conversion in words — but
  this line is not drawn as one string: `Kati.Screens.Import.star_text/3`
  splits it at the star and draws that from Material Symbols, so the glyph
  comes out of a font that has it in both scripts.
  """
  @spec conflict() :: map()
  def conflict do
    %{
      title: gettext("Blue Hour"),
      seed: "bluehour58",
      line:
        gettext("Yours ★%{mine} · file says ★%{theirs}",
          mine: Kati.Locale.number(4),
          theirs: Kati.Locale.number(5)
        ),
      choices: [
        {:keep_mine, gettext("Keep mine"), true},
        {:take_file, gettext("Take file"), false},
        {:keep_both, gettext("Keep both"), false}
      ],
      progress:
        gettext("%{index} of %{total} · apply to all",
          index: Kati.Locale.number(1),
          total: Kati.Locale.number(6)
        )
    }
  end

  @doc """
  The job board 141 draws: a Goodreads export, the source just recognised.

  `progress` is the step meter's own five bars, three of them filled — the
  drawing's literal dot-line, kept as the booleans it paints rather than
  reduced to a fraction. It answers to nobody's `step`/`steps` pair: board
  141 draws it at three of five while the subtitle beside it reads `STEP 1 OF
  4`, and the two do not reconcile — see `Kati.Screens.ImportRecognised`'s
  moduledoc for why both are kept rather than one being quietly fixed.

  `outcome/0` is reused rather than repeated: the drawing gives this job the
  exact three counts and three colours screen 37's job already has — `384`
  new, `28` merged in green, `6` conflicts in red — so a second copy of the
  same three maps would be the literal without the honesty of naming the
  coincidence.

  `source` is `Goodreads` in both scripts. It is the name of somebody else's
  service, and board 127 draws `Lumen+` in Latin on a Persian page for the
  same reason: a real one comes off the file's own header vocabulary through
  `Kati.Import.Mapping.looks_like/1` and no msgid reaches it, so a fixture that
  transliterated would spell one service two ways.
  """
  @spec recognised() :: map()
  def recognised do
    %{
      action: import_pill(),
      source: "Goodreads",
      # `Kati.Screens.PlanImport`'s kicker, which is this exact line on a meal
      # plan's own four steps. One msgid for the one sentence.
      step_label: Kati.UI.ImportChrome.step_label(1, 4),
      progress: [true, true, true, false, false],
      file: "goodreads_library_export.csv",
      shape: shape(),
      matched: 7,
      total_columns: 9,
      skipped: 2,
      columns: recognised_columns(),
      outcome: outcome()
    }
  end

  @doc """
  The nine columns board 141's expanded mapping table draws.

  Same shape as `columns/0` — `icon`, `field`, `note`, `skipped?` — but this
  job's own set: nine columns rather than five, seven matched rather than
  four, and no `sample` value, because this board's row never draws one.

  The absence of `:sample` is load-bearing and not an omission:
  `Kati.Screens.ImportRecognised.sample_for/2` defaults a missing one to `""`,
  and `scale_line/1` and `date_line/1` both read that empty string as *draw the
  board's own sentence*. A `:sample` added here would make 141 describe a file
  it is not showing.
  """
  @spec recognised_columns() :: [map()]
  def recognised_columns do
    [
      %{
        column: "Title",
        note: nil,
        icon: "arrow_forward",
        field: gettext("Title"),
        skipped?: false
      },
      %{
        column: "Author",
        note: nil,
        icon: "arrow_forward",
        field: gettext("Author"),
        skipped?: false
      },
      %{
        column: "My Rating",
        note: scale_note(),
        icon: "arrow_forward",
        field: gettext("Rating"),
        skipped?: false
      },
      %{
        column: "Date Read",
        note: nil,
        icon: "arrow_forward",
        field: gettext("Finished on"),
        skipped?: false
      },
      %{
        column: "Bookshelves",
        note: shelf_note(),
        icon: "arrow_forward",
        field: gettext("Status"),
        skipped?: false
      },
      %{
        column: "My Review",
        note: nil,
        icon: "arrow_forward",
        field: gettext("Review"),
        skipped?: false
      },
      %{
        column: "Number of Pages",
        note: nil,
        icon: "arrow_forward",
        field: gettext("Length"),
        skipped?: false
      },
      %{
        column: "Publisher",
        note: skipped_note(),
        icon: "block",
        field: skip_field(),
        skipped?: true
      },
      %{
        column: "Binding",
        note: skipped_note(),
        icon: "block",
        field: skip_field(),
        skipped?: true
      }
    ]
  end

  # `Import 412` — the ink pill on both boards, and 412 is `384 + 28`: every
  # row this file would write, which is the count the press is a promise about.
  #
  # A context because `Import`, `Import a file` and `Import a plan` are all in
  # the catalogue already and a two-token msgid would be merged onto one of
  # them — `Kati.Screens.PlanImport.plan/0`'s own note, on the same pill over a
  # meal plan. Its count is meals and this one's is records, so the two keep
  # separate contexts and the same Persian word.
  defp import_pill do
    pgettext("the import action pill, with its record count", "Import %{n}",
      n: Kati.Locale.number(412)
    )
  end

  # `418 ROWS · 9 COLUMNS`, which is `Kati.Screens.ImportRecognised.words/1`'s
  # own sentence in an eyebrow's case.
  #
  # `Kati.UI.eyebrow_label/1` rather than a second msgid spelled in capitals:
  # `String.upcase/1` is a Latin operation and the Arabic script has no case, so
  # the drawing's shouting is applied on one side of the fold and the catalogue
  # keeps one entry for the one sentence. Both screens set this line with
  # `Kati.Locale.mono_face/1`, so `418 ROWS · 9 COLUMNS` keeps DM Mono and
  # «۴۱۸ ردیف · ۹ ستون» takes Vazirmatn, which has the digits DM Mono lacks.
  defp shape do
    Kati.UI.eyebrow_label(
      gettext("%{rows} rows · %{columns} columns",
        rows: Kati.Locale.number(418),
        columns: Kati.Locale.number(9)
      )
    )
  end

  # `trakt-backup.csv · step 3 of 4`, the line under screen 37's heading.
  #
  # `Kati.Locale.ltr/1` around the file name: it is a Latin run inside a
  # right-to-left sentence, and the bidi algorithm resolves the neutrals in
  # `goodreads_library_export.csv` against the paragraph rather than against the
  # run unless the isolate says otherwise. A no-op in Latin, so the board's own
  # line is unchanged.
  defp subtitle(file) do
    gettext("%{file} · step %{step} of %{steps}",
      file: Kati.Locale.ltr(file),
      step: Kati.Locale.number(3),
      steps: Kati.Locale.number(4)
    )
  end

  # `converts 10pt → 5★`, under the rating column on both boards.
  #
  # THE PERSIAN SAYS IT IN WORDS, AND THE FONT TABLE IS WHY.
  # `Kati.Screens.ImportRecognised.scale_line/1` carries the full argument for
  # its own `10pt → 5★`: `kati_fa_400.ttf` has neither U+2605 nor U+2192, so an
  # arrow and a star inside a Persian note are two characters handed to
  # Android's fallback face in the middle of a sentence set in Kati's. The mark
  # was never the fact — the conversion is, and Persian has words for both ends
  # of it. Same context as that module's three, because this is the fourth way
  # the app says one thing.
  defp scale_note do
    pgettext("rating conversion", "converts 10pt → 5★")
  end

  # `to-read → Wishlist`, under the Bookshelves column on board 141.
  #
  # The shelf name is interpolated rather than written into the msgid because
  # it is the FILE's word: `to-read` is what Goodreads puts in that cell, the
  # same thing the column headers are, and a translator handed it inside a
  # sentence would have no way to know it must not be touched.
  # `Kati.Locale.ltr/1` for the reason `subtitle/1` gives, and the arrow goes
  # for the reason `scale_note/0` gives.
  defp shelf_note do
    pgettext("how a shelf in the file maps to a list in Kati", "%{shelf} → Wishlist",
      shelf: Kati.Locale.ltr("to-read")
    )
  end

  # The right-hand side of a row for a column the import will not use, and the
  # note under it.
  #
  # A context on both, because the catalogue's plain `Skip` is «رد کن» — the
  # imperative on screen 112's dose card, *skip this one* — and its plain
  # `skipped` is «رد شد», a dose that already was. Neither is this: nothing has
  # happened to this column yet, nobody is being told to do anything, and
  # screen 37's whole argument is that nothing is written until the last step.
  defp skip_field do
    pgettext("the field a dropped column maps to", "Skip")
  end

  defp skipped_note do
    pgettext("a mapping row's note for a dropped column", "skipped")
  end
end
