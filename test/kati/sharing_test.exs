defmodule Kati.SharingTest do
  @moduledoc """
  Share sends a title, its link and its poster, from a film, a show or an
  anime (#123).

  Films shared their name and nothing else, so a chat app had no link to build
  a preview from; shows and anime had no Share at all.
  """
  use Mob.ScreenCase, async: false

  alias Kati.Media.CachedTitle
  alias Kati.Media.Sharing
  alias Kati.Media.TrackedTitle

  doctest Kati.Media.Sharing

  @prefix "sharing-"

  setup do
    on_exit(fn ->
      Kati.Repo.query!("DELETE FROM tracked_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
      Kati.Repo.query!("DELETE FROM cached_titles WHERE source_id LIKE ?1", [@prefix <> "%"])
    end)
  end

  defp track!(suffix, title, kind, extra \\ %{}) do
    Ash.create!(
      CachedTitle,
      Map.merge(
        %{
          source: :tmdb,
          source_id: @prefix <> suffix,
          kind: kind,
          title: title,
          first_release_year: 2019,
          fetched_at: Kati.Time.now()
        },
        extra
      )
    )

    Ash.create!(TrackedTitle, %{
      source: :tmdb,
      source_id: @prefix <> suffix,
      kind: kind,
      status: :watching
    })
  end

  defp tags(view) do
    for %{props: %{on_tap: {_pid, tag}}} <- flatten(view), is_atom(tag), do: tag
  end

  test "a show's message names it, its year, where it streams and its link" do
    show =
      track!("dark", "Dark", :tv, %{
        providers: %{Kati.Services.region() => %{"flatrate" => ["Netflix"]}}
      })

    {message, _seed} = Sharing.for_title(show.id)

    assert message ==
             "Dark (2019)\nOn Netflix\nhttps://www.themoviedb.org/tv/" <> @prefix <> "dark"
  end

  test "an anime from AniList links to AniList" do
    assert Sharing.link(%{source: :anilist, source_id: "16498", kind: :anime}) ==
             "https://anilist.co/anime/16498"
  end

  test "an id that names nothing shares nothing" do
    assert Sharing.for_title(Ecto.UUID.generate()) == nil
    assert Sharing.for_title(nil) == nil
  end

  test "the series page draws Share, and pressing it is answered" do
    show = track!("severance", "Severance", :tv)
    view = mount_screen(Kati.Screens.Series, %{tracked_id: show.id})

    assert :share_title in tags(view)
    assert render_info(view, {:tap, :share_title})
  end

  test "an anime page draws it too" do
    anime = track!("frieren", "Frieren", :anime)
    view = mount_screen(Kati.Screens.Series, %{tracked_id: anime.id})

    assert :share_title in tags(view)
  end

  test "the film page carries its link for the message" do
    film = track!("dune", "Dune", :movie)
    view = mount_screen(Kati.Screens.Film, %{id: film.id})

    assert assigns(view).film.link == "https://www.themoviedb.org/movie/" <> @prefix <> "dune"
    assert render_info(view, {:tap, :share_film})
  end

  test "a poster goes as an image with the message as its caption (K-20)" do
    kt = File.read!("android/app/src/main/java/com/example/kati/MobBridge.kt")

    assert kt =~ ~s|val caption = args.optString("text", "")|
    assert kt =~ "putExtra(Intent.EXTRA_TEXT, caption)"
  end
end
