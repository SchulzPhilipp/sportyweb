defmodule SportywebWeb.Accounting.Journal.AccountingTransactionLive.Show do
  use SportywebWeb, :live_view

  alias Sportyweb.Accounting

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    accounting_transaction = Accounting.get_accounting_transaction!(id, [:club, :entries])
    {:ok,
    socket
      |> assign(:club_navigation_current_item, :journal)
      |> assign(:accounting_transaction, accounting_transaction)
      # Boolean status flags are assigned here so the template has them
      # available even before handle_params/3 completes its own assignment.
      |> assign(:posted?, accounting_transaction.status == :posted)
      |> assign(:voided?, accounting_transaction.status == :voided)
      |> assign(:deleted?, accounting_transaction.status == :deleted)
      |> assign(:club, accounting_transaction.club)
  }
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    accounting_transaction = Accounting.get_accounting_transaction!(id, [:club, entries: [:account]])
    {:noreply,
     socket
     |> assign(:page_title, "Buchung #{accounting_transaction.transaction_number}")
     |> assign(:accounting_transaction, accounting_transaction)
     # All four status flags are set here (including :pending, which mount/3
     # omits) because handle_params/3 is the authoritative assign source
     # after navigation and patch events.
     |> assign(:pending?, accounting_transaction.status == :pending)
     |> assign(:posted?, accounting_transaction.status == :posted)
     |> assign(:voided?, accounting_transaction.status == :voided)
     |> assign(:deleted?, accounting_transaction.status == :deleted)
     |> assign(:club, accounting_transaction.club)}
  end

  # Advances the transaction from :pending to :posted (permanently booked).
  # An unbalanced transaction (debits != credits) is rejected by the context
  # with an Ecto.Changeset error.
  @impl true
  def handle_event("post", _, socket) do
    case Accounting.post_accounting_transaction(socket.assigns.accounting_transaction) do
      {:ok, _accounting_transaction} ->
        {:noreply,
          socket
          |> put_flash(:info, "Buchung erfolgreich freigegeben")
          |> push_navigate(to: ~p"/clubs/#{socket.assigns.club.id}/journal")}
      {:error, :invalid_transition} ->
        {:noreply, put_flash(socket, :error, "Ungültiger Statusübergang")}
      {:error, %Ecto.Changeset{}} ->
        {:noreply, put_flash(socket, :error, "Buchung ist nicht ausgeglichen")}
    end
  end

  # Reverts a :pending transaction back to :draft, returning it to the
  # submitter for correction.
  @impl true
  def handle_event("revert_to_draft", _, socket) do
    case Accounting.revert_to_draft_accounting_transaction(socket.assigns.accounting_transaction) do
      {:ok, _accounting_transaction} ->
        {:noreply,
          socket
          |> put_flash(:info, "Buchung zur Überarbeitung zurückgegeben")
          |> push_navigate(to: ~p"/clubs/#{socket.assigns.club.id}/journal")}
      {:error, :invalid_transition} ->
        {:noreply, put_flash(socket, :error, "Ungültiger Statusübergang")}
    end
  end

  # Voids a posted transaction by creating a reversing entry in the context
  # layer. The transaction is re-fetched with full preloads here because
  # socket.assigns may hold a stale version that lacks the data the context
  # needs to build the reversal correctly.
  @impl true
  def handle_event("void", _, socket) do
    accounting_transaction = Accounting.get_accounting_transaction!(socket.assigns.accounting_transaction.id, [:club, :entries])

    case Accounting.void_accounting_transaction(accounting_transaction) do
      {:ok, _accounting_transaction} ->
        {:noreply,
          socket
          |> put_flash(:info, "Buchung erfolgreich storniert")
          |> push_navigate(to: ~p"/clubs/#{socket.assigns.club.id}/journal")}
      {:error, :invalid_transition} ->
        {:noreply, put_flash(socket, :error, "Ungültiger Statusübergang")}
    end
  end

  # Converts a Money struct to a human-readable string.
  # Falls back to "0,00 €" on error (should not occur in practice).
  defp display_money(money_struct) do
    case Money.to_string(money_struct) do
      {:ok, string} -> string
      _ -> "0,00 €"
    end
  end


  # Human-readable labels for transaction statuses and spheres, used in the template.
  # Keeping them here (rather than in the template) makes them reusable and testable independently.
  defp status_label(:draft),   do: "Entwurf"
  defp status_label(:pending), do: "Zur Prüfung"
  defp status_label(:posted),  do: "Gebucht"
  defp status_label(:voided),  do: "Storniert"
  defp status_label(:deleted), do: "Gelöscht"

  defp sphere_label(:ideal),  do: "Ideeller Bereich"
  defp sphere_label(:asset_management),  do: "Vermögensverwaltung"
  defp sphere_label(:purpose_related),  do: "Zweckbetrieb"
  defp sphere_label(:commercial),  do: "Wirtschaftlicher Geschäftsbetrieb"

end
