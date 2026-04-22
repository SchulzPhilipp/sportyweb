defmodule SportywebWeb.Accounting.Journal.AccountingTransactionLive.NewEdit do
  use SportywebWeb, :live_view

  alias Sportyweb.Accounting
  alias Sportyweb.Accounting.AccountingTransaction
  alias Sportyweb.Organization

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.live_component
        module={SportywebWeb.Accounting.Journal.AccountingTransactionLive.FormComponent}
        id={@accounting_transaction.id || :new}
        title={@page_title}
        action={@live_action}
        accounting_transaction={@accounting_transaction}
        active_period_id={@active_period && @active_period.id}
        club_id={@club.id}
        navigate={
          if @accounting_transaction.id,
            do: ~p"/journal/#{@accounting_transaction}",
            else: ~p"/clubs/#{@club}/journal"
        }
      />
    </div>
    """
  end

  # Resolves the active accounting period before mount/3 runs and injects it
  # into socket.assigns as @active_period.
  on_mount {SportywebWeb.CommonHelper, :load_active_period}

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket
    |> assign(:club_navigation_current_item, :journal)
  }
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  # Loads an existing transaction for editing, eagerly preloading :club and
  # :entries with their associated :account so the form can display account
  # names without additional queries.
  defp apply_action(socket, :edit, %{"id" => id}) do
    accounting_transaction = Sportyweb.Accounting.get_accounting_transaction!(id, [:club, entries: [:account]])

    # Convert each entry's Money amount to a plain decimal string so the
    # amount_input field (which expects a string) is correctly pre-populated.
    entries =
      Enum.map(accounting_transaction.entries, fn entry ->
        %{entry | amount_input:
          entry.amount.amount
          |> Decimal.to_string()
        }
      end)

    # The page title reflects the transaction's current status, giving the user
    # immediate context about what actions are available.
    accounting_transaction = %{accounting_transaction | entries: entries}
    transaction_number = accounting_transaction.transaction_number || ""
    page_title = case accounting_transaction.status do
      :pending -> "Buchung #{transaction_number} zur Prüfung"
      :posted -> "Buchung #{transaction_number} abgeschlossen"
      :voided -> "Buchung #{transaction_number} storniert"
      _ -> "Buchung #{transaction_number} bearbeiten"
    end

    socket
    |> assign(:page_title, page_title)
    |> assign(:accounting_transaction, accounting_transaction)
    |> assign(:club, accounting_transaction.club)

  end

  # Initialises a blank transaction struct for the :new action.
  # entries: [] is set explicitly so FormComponent can safely call
  # Enum.map on the entries field without a nil guard.
  defp apply_action(socket, :new, %{"club_id" => club_id}) do
    club = Organization.get_club!(club_id)

    socket
    |> assign(:page_title, "Buchung erstellen")
    |> assign(:accounting_transaction, %AccountingTransaction{
      club_id: club.id,
      club: club,
      entries: []
    })    |> assign(:club, club)
  end

  # Soft-deletes a draft transaction. Immutable transactions (posted, voided)
  # are rejected by the context with {:error, :immutable}.
  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    accounting_transaction = Accounting.get_accounting_transaction!(id)

    case Accounting.delete_accounting_transaction(accounting_transaction) do
      {:ok, _} ->
        {:noreply,
          socket
          |> put_flash(:info, "Buchung erfolgreich gelöscht")
          |> push_navigate(to: ~p"/clubs/#{accounting_transaction.club_id}/journal")}
      {:error, :immutable} ->
        {:noreply,
          socket
          |> put_flash(:error, "Diese Buchung kann nicht gelöscht werden.")}
    end
  end

  # Advances the transaction from :draft to :pending (submitted for review).
  @impl true
  def handle_event("submit", _, socket) do
    case Accounting.submit_accounting_transaction(socket.assigns.accounting_transaction) do
      {:ok, accounting_transaction} ->
        {:noreply,
          socket
          |> put_flash(:info, "Buchung zur Prüfung eingereicht")
          |> assign(:accounting_transaction, accounting_transaction)}
      {:error, :invalid_transition} ->
        {:noreply, put_flash(socket, :error, "Ungültiger Statusübergang")}
    end
  end

  # Advances the transaction from :pending to :posted (permanently booked).
  # An unbalanced transaction (debits != credits) is rejected by the context
  # with an Ecto.Changeset error.
  @impl true
  def handle_event("post", _, socket) do
    case Accounting.post_accounting_transaction(socket.assigns.accounting_transaction) do
      {:ok, accounting_transaction} ->
        {:noreply,
          socket
          |> put_flash(:info, "Buchung erfolgreich gebucht")
          |> assign(:accounting_transaction, accounting_transaction)}
      {:error, :invalid_transition} ->
        {:noreply, put_flash(socket, :error, "Ungültiger Statusübergang")}
      {:error, %Ecto.Changeset{}} ->
        {:noreply, put_flash(socket, :error, "Buchung ist nicht ausgeglichen")}
    end
  end

  # Voids a posted transaction by creating a reversing entry in the context
  # layer. Navigates back to the journal list afterwards because a voided
  # transaction can no longer be edited.
  @impl true
  def handle_event("void", _, socket) do
    case Accounting.void_accounting_transaction(socket.assigns.accounting_transaction) do
      {:ok, accounting_transaction} ->
        {:noreply,
          socket
          |> put_flash(:info, "Buchung erfolgreich storniert")
          |> push_navigate(to: ~p"/clubs/#{accounting_transaction.club_id}/journal")}
      {:error, :invalid_transition} ->
        {:noreply, put_flash(socket, :error, "Ungültiger Statusübergang")}
    end
  end

end
