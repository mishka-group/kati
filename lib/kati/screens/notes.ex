defmodule Kati.Screens.Notes do
  @moduledoc """
  Screen 62 — Notes, pushed from Home's Sections row.

  The section existed and nothing behind it: `Kati.Sections` offered *Notes* in
  the first run, `Kati.Books.Note` had carried quotes and notes since the Books
  domain landed, and screen 66 drew them — but a book was the only way to see
  them, and nothing gathered them across books. A section with no page is a
  choice the app asked for and then did nothing with.

  ## One list, newest first

  Every quote and note the app holds, across every book, newest first. The
  order is `inserted_at` rather than any page or title: this is a page of things
  *you wrote*, and the useful order for that is when you wrote them.

  ## The book is on the card, and the card opens it

  A note without its book is a sentence with no subject, so each card carries
  the book's title and author, and tapping it opens that book — the screen
  where the note can be read in its chapter. There is no edit here for the same
  reason the book's own page has none: a quote belongs to the book, and the
  page it was copied from is what makes it a quote.

  ## Cream, as on screen 66

  The palette's one warm surface marks the reader's own words. Using the card
  fill here would make a page of the reader's writing look like a page of
  metadata — the design's own caption for screen 08 says why it does not.
  """

  use Kati.Screens.Pushed, back: "Home"
  use Gettext, backend: Kati.Gettext

  alias Kati.Books.Note
  alias Kati.Components.MishkaActionIcon
  alias Kati.Components.MishkaPill
  alias Kati.Theme.Palette

  @limit 200

  @impl true
  def load(socket) do
    socket
    |> Mob.Socket.assign(:notes, notes())
    |> Mob.Socket.assign(:confirming, nil)
    |> Mob.Socket.assign(:save_error, nil)
  end

  @doc """
  Every quote and note, newest first, shaped for the card.

  `Kati.Books.Note.display/1` is applied here rather than at load so a quote
  wears the reader's own quotation marks whatever script the page is drawn in.
  """
  @spec notes() :: [map()]
  def notes do
    Note
    |> Ash.Query.load(:book)
    |> Ash.Query.sort(inserted_at: :desc)
    |> Ash.Query.limit(@limit)
    |> Ash.read()
    |> case do
      {:ok, notes} -> Enum.map(notes, &shape/1)
      _other -> []
    end
  rescue
    _error -> []
  end

  defp shape(%Note{} = note) do
    %{
      id: note.id,
      body: Note.display(note),
      anchor: Note.anchor(note),
      book_id: note.book_id,
      book: book_line(note.book)
    }
  end

  defp book_line(nil), do: ""

  defp book_line(%{title: title, author: author}) when is_binary(author) and author != "",
    do: title <> " · " <> author

  defp book_line(%{title: title}), do: title

  @doc false
  def content(assigns) do
    notes = assigns.notes

    ~MOB"""
    <Box fill_width={true} fill_height={true}>
      <Scroll fill_height={true}>
        <Column
          fill_width={true}
          padding_left={21}
          padding_right={21}
          padding_top={64}
          padding_bottom={40}
        >
          {Kati.Screens.Notes.back_gap()}
          {Kati.Screens.Notes.header(notes)}
          {Kati.Screens.Notes.body(assigns)}
        </Column>
      </Scroll>
      {Kati.Screens.Notes.confirm_dialog(assigns)}
    </Box>
    """
  end

  @doc false
  def back_gap, do: ~MOB"<Spacer size={58} />"

  @doc false
  def header(notes) do
    subtitle = subtitle(notes)

    ~MOB"""
    <Column fill_width={true}>
      <Row fill_width={true} align="top">
        <Column weight={1.0}>
          <Text
            text={gettext("Notes")}
            text_size={28}
            max_font_scale={1.6}
            font_weight="bold"
            letter_spacing={Kati.Locale.tracking(-0.03)}
            text_color={:on_surface}
            max_lines={1}
          />
          <Spacer size={5} />
          <Text
            text={subtitle}
            font_family={Kati.Locale.mono_face(subtitle)}
            text_size={11}
            text_color={Palette.muted()}
            max_lines={1}
          />
        </Column>
        {Kati.Screens.Notes.disc()}
      </Row>
      <Spacer size={20} />
    </Column>
    """
  end

  @doc "The 44pt disc that opens the shelf, which is where a note is written."
  def disc do
    MishkaActionIcon.action_icon(
      [
        id: "notes_books",
        size: 44,
        shape: :circle,
        variant: :filled,
        background: Palette.card(),
        shadow: Kati.Theme.shadow_button(),
        on_tap: {self(), :open_books}
      ],
      [Kati.UI.symbol("add", size: 21)]
    )
  end

  @doc false
  def body(%{notes: []}), do: empty_state()

  def body(assigns) do
    ~MOB"""
    <Column fill_width={true}>
      {Kati.Screens.Notes.cards(assigns.notes)}
    </Column>
    """
  end

  defp empty_state do
    action = empty_action()

    ~MOB"""
    <MishkaEmptyState
      id="notes_empty"
      align={:left}
      title={gettext("No notes yet")}
      description={gettext("Open a book and write the first quote or note. Everything you write gathers here.")}
      title_size={18}
      title_weight={:bold}
      padding={0}
    >
      {action}
    </MishkaEmptyState>
    """
  end

  defp empty_action do
    MishkaPill.pill(
      id: "notes_open_books",
      label: gettext("Open Books"),
      background: Palette.green(),
      color: 0xFFFBFAF8,
      corner_radius: 15,
      height: 36,
      padding: 0,
      padding_left: 16,
      padding_right: 16,
      text_size: 13,
      font_weight: :semibold,
      align: :center,
      on_tap: {self(), :open_books}
    )
  end

  @doc false
  def cards(notes) do
    children =
      notes
      |> Enum.map(&card/1)
      |> Enum.intersperse(~MOB"<Spacer size={11} />")

    ~MOB"""
    <Column fill_width={true}>
      {children}
      <Spacer size={24} />
    </Column>
    """
  end

  @doc false
  def card(note) do
    ~MOB"""
    <MishkaCard
      id={"note_" <> note.id}
      background={Palette.cream()}
      corner_radius={20}
      shadow={Kati.Theme.shadow_card_soft()}
      padding={17}
      fill_width={true}
      on_tap={{self(), {:open_book, note.book_id}}}
      on_long_press={{self(), {:confirm_delete, note.id}}}
    >
      <Text
        text={note.body}
        text_size={14}
        line_height={Kati.Locale.leading(1.45)}
        text_color={Palette.cream_body()}
      />
      <Spacer size={7} />
      <Row fill_width={true} align="center">
        <Text
          text={note.anchor || ""}
          font_family={Kati.Locale.mono_face(note.anchor || "")}
          text_size={10.5}
          text_color={Palette.cream_meta()}
          max_lines={1}
        />
        <Spacer weight={1.0} />
        <Text text={note.book} text_size={10.5} text_color={Palette.cream_meta()} max_lines={1} />
      </Row>
    </MishkaCard>
    """
  end

  @doc "The header's mono line: how many notes, over how many books."
  @spec subtitle([map()]) :: String.t()
  def subtitle(notes) do
    books = notes |> Enum.map(& &1.book_id) |> Enum.uniq() |> length()

    ngettext("%{n} note", "%{n} notes", length(notes), n: Kati.Locale.number(length(notes))) <>
      " · " <>
      ngettext("%{n} book", "%{n} books", books, n: Kati.Locale.number(books))
  end

  @doc """
  The confirmation a held card opens.

  Deleting a note destroys the reader's own words with nothing to undo it, so it
  takes a second, explicit choice — the same alert dialog the habit card uses.
  """
  def confirm_dialog(assigns) do
    open? = Map.get(assigns, :confirming) != nil

    ~MOB"""
    <MishkaAlertDialog id="note_delete" open={open?} on_close={{self(), :cancel_delete}}>
      <MishkaDialogTitle text={gettext("Delete this note?")} />
      <MishkaDialogDescription
        text={gettext("It is your own writing and there is no copy of it anywhere else. This cannot be undone.")}
      />
      <MishkaAlertDialogAction
        text={gettext("Cancel")}
        id="note_delete_cancel"
        on_tap={{self(), :cancel_delete}}
      />
      <MishkaAlertDialogAction
        text={gettext("Delete")}
        id="note_delete_go"
        variant={:danger}
        on_tap={{self(), :confirm_delete}}
      />
    </MishkaAlertDialog>
    """
  end

  # ── What a tap changes ────────────────────────────────────────────────────

  @impl true
  def handle_tap(:open_books, socket),
    do: {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.Books)}

  def handle_tap({:open_book, book_id}, socket) do
    if is_binary(book_id),
      do:
        {:noreply, Mob.Socket.push_screen(socket, Kati.Screens.BookDetail, %{book_id: book_id})},
      else: {:noreply, socket}
  end

  def handle_tap({:confirm_delete, note_id}, socket),
    do: {:noreply, Mob.Socket.assign(socket, :confirming, note_id)}

  def handle_tap(:cancel_delete, socket),
    do: {:noreply, Mob.Socket.assign(socket, :confirming, nil)}

  def handle_tap(:confirm_delete, socket) do
    case socket.assigns.confirming do
      nil ->
        {:noreply, socket}

      note_id ->
        case delete(note_id) do
          :ok ->
            {:noreply,
             socket
             |> Mob.Socket.assign(:confirming, nil)
             |> Mob.Socket.assign(:notes, notes())}

          {:error, reason} ->
            {:noreply,
             socket
             |> Mob.Socket.assign(:confirming, nil)
             |> Mob.Socket.assign(:save_error, Kati.Write.message({:error, reason}))}
        end
    end
  end

  def handle_tap(_tag, socket), do: {:noreply, socket}

  defp delete(note_id) do
    with {:ok, note} <- Ash.get(Note, note_id),
         :ok <- note_destroy(note) do
      :ok
    end
  rescue
    error -> {:error, error}
  end

  defp note_destroy(note) do
    case Ash.destroy(note) do
      :ok -> :ok
      {:ok, _gone} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  def handle_info({:tap, :back}, socket), do: {:noreply, Kati.Screens.Resume.pop(socket)}

  def handle_info({:long_press, tag}, socket), do: handle_tap(tag, socket)

  def handle_info({:tap, tag}, socket) do
    Kati.Screens.Root.rescue_tap(__MODULE__, tag, socket)
  end

  def handle_info(_message, socket), do: {:noreply, socket}
end
