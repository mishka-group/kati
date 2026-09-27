defmodule Kati.UI.TmdbPrompt do
  @moduledoc """
  The empty block Home draws when there is no TMDB token to search with.

  The owner's decision, 19 Sep: the reader brings their own TMDB token, and
  when there is none, *"show empty block on home for film and series and tell
  click to put your token."* The reader's own token is the only TMDB key the
  app has (`Kati.Media.Tmdb.key/0`), so on a fresh install every film and
  series search answers `{:error, :no_api_key}` until one is pasted. Without this, the first a reader
  heard of it was a search that came back empty — which reads as a catalogue
  with nothing in it, not as a setting they have not made yet.

  A door and not a wall: the block sits under the search field and the rest of
  Home works around it, because hand-typed titles, the calendar and every other
  section need no token at all. It disappears the moment a usable key exists —
  `Kati.Media.Tmdb.usable?/0`, read in the screen's own `load/1`.
  """
  use Gettext, backend: Kati.Gettext

  import Mob.Sigil

  @doc "Nothing when a key is usable; the block when it is not."
  @spec block(boolean() | nil) :: map()
  def block(true), do: ~MOB"<Spacer size={0} />"

  def block(_not_ready) do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.card([
        Kati.UI.SettingsList.row(
          Kati.UI.SettingsList.icon_tile("movie"),
          Kati.UI.SettingsList.body(
            gettext("Add your TMDB token"),
            gettext("Kati needs it to find films and series. Free, and takes a minute.")
          ),
          Kati.UI.SettingsList.trailing(Kati.UI.SettingsList.chevron()),
          rule: false,
          on_tap: {self(), :add_tmdb_token}
        )
      ])}
      <Spacer size={18} />
    </Column>
    """
  end

  @doc """
  The same door, under screen 19's AniList and TVmaze sections.

  With no token, search still answers — anime and series come from the two
  keyless catalogues (`Kati.Search.Keyless`) — so the card no longer says
  Kati *needs* the token to find anything. What it does say is the part that
  stays true: films are TMDB's. Same title, same tap, same destination as
  `block/1`.
  """
  @spec hint() :: map()
  def hint do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.UI.SettingsList.card([
        Kati.UI.SettingsList.row(
          Kati.UI.SettingsList.icon_tile("movie"),
          Kati.UI.SettingsList.body(
            gettext("Add your TMDB token"),
            gettext("Films and more series come from TMDB. Free, and takes a minute.")
          ),
          Kati.UI.SettingsList.trailing(Kati.UI.SettingsList.chevron()),
          rule: false,
          on_tap: {self(), :add_tmdb_token}
        )
      ])}
      <Spacer size={18} />
    </Column>
    """
  end

  @doc """
  The token form itself, on the page that needs it — or, once the reader has
  said they will do without, what doing without means.

  The owner's rule, 27 Sep: where a page needs TMDB and there is no token,
  the page suggests one and has the form right there — no trip to screen 80
  and no finding the way back. *Save* stores the token and the page fills in
  where it stands (`handle/2`, then the screen's own reload). *Skip* is an
  answer too, and the page says what it costs: films come from TMDB alone,
  while series and anime still come from AniList and TVmaze, with less
  detail. The skip is remembered (`skipped?/0`), so the form does not come
  back on every visit; *Add a token* under the note reopens it.

  `form` is `form_state/0`'s map on the caller's socket under `:tmdb_form`.
  """
  @spec inline(boolean() | nil, map() | nil, boolean()) :: map()
  def inline(ready?, form, skipped?)
  def inline(true, _form, _skipped?), do: ~MOB"<Spacer size={0} />"
  def inline(_ready?, _form, true), do: Kati.UI.TmdbPrompt.skipped_note()

  def inline(_ready?, form, _skipped?) do
    form = form || form_state()

    assigns = %{
      token: form.token,
      epoch: form.epoch,
      error: form.error,
      opened: Map.get(form, :opened),
      on_change: {self(), :inline_tmdb_token}
    }

    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Kati.Theme.Palette.card()}
        corner_radius={18}
        shadow={Kati.Theme.shadow_card_soft()}
        padding_left={16}
        padding_right={16}
        padding_top={16}
        padding_bottom={16}
      >
        <Row fill_width={true} align="top">
          {Kati.UI.SettingsList.icon_tile("movie")}
          <Spacer size={12} />
          <Column weight={1.0}>
            <Text
              text={gettext("Add your TMDB token")}
              text_size={14.5}
              font_weight="bold"
              text_color={:on_surface}
            />
            <Spacer size={4} />
            <Text
              text={gettext("Films come from TMDB, and it needs a token of your own. It is free: sign in at themoviedb.org, open Settings → API, and copy the API Read Access Token — the long one starting eyJ.")}
              text_size={12.5}
              line_height={Kati.Locale.leading(1.45)}
              text_color={Kati.Theme.Palette.sub()}
            />
          </Column>
        </Row>
        <Spacer size={14} />
        <Row
          fill_width={true}
          corner_radius={14}
          background={Kati.Theme.Palette.card()}
          border_width={1}
          border_color={Kati.Theme.Palette.border()}
          padding_left={4}
          padding_right={4}
          align="center"
        >
          <TextField
            value={@token}
            placeholder={Kati.Screens.DataSources.token_placeholder()}
            return_key="done"
            fill_width={true}
            accessibility_id="inline_tmdb_token"
            on_change={@on_change}
            value_epoch={@epoch}
          />
        </Row>
        {Kati.UI.TmdbPrompt.form_error(@error)}
        {Kati.UI.TmdbPrompt.opened_line(@opened)}
        <Spacer size={14} />
        <Row fill_width={true} align="center">
          {Kati.UI.TmdbPrompt.get_token_link()}
          <Spacer weight={1.0} />
          {Kati.UI.TmdbPrompt.skip_pill()}
          <Spacer size={8} />
          {Kati.Screens.DataSources.save_pill({self(), :inline_save_token})}
        </Row>
      </Column>
      <Spacer size={18} />
    </Column>
    """
  end

  @doc false
  def form_error(nil), do: ~MOB"<Spacer size={0} />"

  def form_error(error) when is_binary(error) do
    ~MOB"""
    <Column fill_width={true} padding_top={10}>
      {Kati.UI.SettingsList.note("error", error)}
    </Column>
    """
  end

  @doc """
  What the *Get a token* tap did: the page opened, so the reader knows to
  come back and paste; or it could not, with the address to type instead.
  """
  @spec opened_line(nil | :ok | :failed) :: map()
  def opened_line(nil), do: ~MOB"<Spacer size={0} />"

  def opened_line(:ok),
    do:
      opened_text(
        gettext(
          "TMDB’s API page is open in your browser. Copy the token there and paste it here."
        )
      )

  def opened_line(:failed),
    do:
      opened_text(
        gettext(
          "Couldn’t open the browser. Go to themoviedb.org/settings/api and copy the token."
        )
      )

  defp opened_text(text) do
    assigns = %{text: text}

    ~MOB"""
    <Column fill_width={true} padding_top={10}>
      <Text
        text={@text}
        text_size={12}
        line_height={Kati.Locale.leading(1.4)}
        text_color={Kati.Theme.Palette.sub()}
      />
    </Column>
    """
  end

  @doc false
  def get_token_link do
    ~MOB"""
    <Row height={32} align="center" on_tap={{self(), :get_tmdb_token}}>
      <Text
        text={gettext("Get a token")}
        text_size={12.5}
        font_weight="semibold"
        text_color={Kati.Theme.Palette.sub()}
        max_lines={1}
      />
      <Spacer size={2} />
      {Kati.UI.symbol("chevron_right", size: 16, color: Kati.Theme.Palette.sub())}
    </Row>
    """
  end

  @doc false
  def skip_pill do
    ~MOB"""
    <Row
      height={32}
      corner_radius={16}
      background={Kati.Theme.Palette.card()}
      border_width={1}
      border_color={Kati.Theme.Palette.border()}
      padding_left={14}
      padding_right={14}
      align="center"
      on_tap={{self(), :skip_tmdb_token}}
    >
      <Text
        text={gettext("Skip")}
        text_size={12.5}
        font_weight="semibold"
        text_color={:on_surface}
        max_lines={1}
      />
    </Row>
    """
  end

  @doc """
  What a page says once the reader skipped the token: what is missing, what
  still works, and the way back to the form.
  """
  @spec skipped_note() :: map()
  def skipped_note do
    ~MOB"""
    <Column fill_width={true}>
      <Column
        fill_width={true}
        background={Kati.Theme.Palette.card()}
        corner_radius={18}
        padding_left={16}
        padding_right={16}
        padding_top={14}
        padding_bottom={10}
      >
        <Row fill_width={true} align="top">
          {Kati.UI.symbol("info", size: 18, color: Kati.Theme.Palette.muted())}
          <Spacer size={10} />
          <Column weight={1.0}>
            <Text
              text={gettext("Without a TMDB token Kati can’t bring you films. Series and anime still come from AniList and TVmaze, with less detail.")}
              text_size={12.5}
              line_height={Kati.Locale.leading(1.45)}
              text_color={Kati.Theme.Palette.sub()}
            />
          </Column>
        </Row>
        <Row fill_width={true} height={36} align="center" on_tap={{self(), :tmdb_unskip}}>
          <Spacer size={28} />
          <Text
            text={gettext("Add a token")}
            text_size={12.5}
            font_weight="bold"
            text_color={:on_surface}
            max_lines={1}
          />
        </Row>
      </Column>
      <Spacer size={18} />
    </Column>
    """
  end

  @doc "An empty form."
  @spec form_state() :: map()
  def form_state, do: %{token: "", epoch: 0, error: nil, opened: nil}

  @skip_key :tmdb_prompt_skipped
  @token_page "https://www.themoviedb.org/settings/api"

  @doc "Whether the reader chose to do without a token. `false` when unreadable."
  @spec skipped?() :: boolean()
  def skipped? do
    Mob.State.get(@skip_key, false) == true
  rescue
    _error -> false
  catch
    :exit, _reason -> false
  end

  @doc """
  The form's own events, for a screen that draws `inline/3`: `{:ok, socket}`
  when the message was one of them, `:pass` otherwise.

  `reload` is the screen's own way to draw itself again with a token — Home's
  and Discover's `load/1` — run only after a save succeeds, so the page fills
  in where the reader already is.
  """
  @spec handle(term(), Mob.Socket.t(), (Mob.Socket.t() -> Mob.Socket.t())) ::
          {:ok, Mob.Socket.t()} | :pass
  def handle({:change, :inline_tmdb_token, typed}, socket, _reload) when is_binary(typed),
    do: {:ok, put_form(socket, %{form(socket) | token: typed})}

  def handle({:tap, :inline_save_token}, socket, reload) do
    form = form(socket)

    case String.trim(form.token) do
      "" ->
        {:ok, put_form(socket, %{form | error: gettext("Paste a token first.")})}

      token ->
        {:ok, save(socket, form, token, reload)}
    end
  end

  def handle({:tap, :skip_tmdb_token}, socket, _reload) do
    remember_skip(true)
    {:ok, Mob.Socket.assign(socket, :tmdb_skipped, true)}
  end

  def handle({:tap, :tmdb_unskip}, socket, _reload) do
    remember_skip(false)
    {:ok, Mob.Socket.assign(socket, :tmdb_skipped, false)}
  end

  def handle({:tap, :get_tmdb_token}, socket, _reload) do
    opened =
      case Kati.Native.Links.open(@token_page) do
        :ok -> :ok
        _failed -> :failed
      end

    {:ok, put_form(socket, Map.put(form(socket), :opened, opened))}
  end

  def handle(_message, _socket, _reload), do: :pass

  defp save(socket, form, token, reload) do
    case Kati.SecureStore.put("tmdb", token) do
      :ok ->
        Kati.Screens.DataSources.stamp_saved()

        socket
        |> put_form(%{form | token: "", epoch: form.epoch + 1, error: nil})
        |> Mob.Socket.assign(:tmdb_ready, true)
        |> reload.()

      {:error, _reason} ->
        put_form(socket, %{
          form
          | error:
              gettext(
                "TMDB didn’t accept this. Check you copied the API Read Access Token " <>
                  "and not the API key, and that it has no trailing space."
              )
        })
    end
  rescue
    _error -> put_form(socket, %{form | error: gettext("That did not save.")})
  catch
    :exit, _reason -> put_form(socket, %{form | error: gettext("That did not save.")})
  end

  defp remember_skip(value) do
    Mob.State.put(@skip_key, value)
  rescue
    _error -> :ok
  catch
    :exit, _reason -> :ok
  end

  defp form(socket), do: Map.get(socket.assigns, :tmdb_form) || form_state()
  defp put_form(socket, form), do: Mob.Socket.assign(socket, :tmdb_form, form)

  @doc """
  Where the block leads: screen 80, where the token field is.

  `back` is the word the pill on screen 80 says — the page it returns to.
  Without it the pill fell back to screen 80's own *Settings*, which is not
  where a reader who came from Home or the first run goes back to.
  """
  @spec open(Mob.Socket.t(), String.t()) :: Mob.Socket.t()
  def open(socket, back),
    do: Mob.Socket.push_screen(socket, Kati.Screens.DataSources, %{back: back})
end
