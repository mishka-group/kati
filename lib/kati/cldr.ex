defmodule Kati.Cldr do
  @moduledoc """
  Kati's CLDR backend. English and Persian only.

  `data_dir: "cldr_data"` is load-bearing rather than cosmetic. By default
  ex_cldr writes the downloaded locale JSON into
  `Application.app_dir(:kati, "priv/cldr/locales")`, and Mob rsyncs the whole
  app `priv/` to the device — so the default would ship roughly 1.2 MB of
  compile-time-only JSON to every phone. `fa.json` alone is 620 KB.

  `precompile_transliterations: [{:latn, :arabext}]` matters because `fa`'s
  default number system **is** `arabext`: without precompiling the pair, every
  Persian number formats through a runtime transliteration path.
  """
  use Cldr,
    locales: ["en", "fa"],
    default_locale: "en",
    gettext: Kati.Gettext,
    providers: [Cldr.Number, Cldr.Calendar, Cldr.DateTime, Cldr.Message],
    precompile_transliterations: [{:latn, :arabext}],
    precompile_number_formats: ["#,##0", "#,##0.##", "#,##0.###"],
    data_dir: "cldr_data",
    otp_app: :kati
end
