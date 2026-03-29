defmodule SportywebWeb.AccountingTransactionLive.NewEdit do
  use SportywebWeb, :live_view

  alias Sportyweb.Accounting
  alias Sportyweb.Accounting.AccountingTransaction
  alias Sportyweb.Organization

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.live_component
        module={SportywebWeb.AccountingTransactionLive.FormComponent}
        id={@accounting_transaction.id || :new}
        title={@page_title}
        action={@live_action}
        accounting_transaction={@accounting_transaction}
        navigate={
          if @accounting_transaction.id,
            do: ~p"/journal/#{@accounting_transaction}",
            else: ~p"/clubs/#{@club}/journal"
        }
      />
    </div>
    """
  end

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

  defp apply_action(socket, :edit, %{"id" => id}) do
    accounting_transaction = Sportyweb.Accounting.get_accounting_transaction!(id, [:club, entries: [:account]])

    entries =
      Enum.map(accounting_transaction.entries, fn entry ->
        %{entry | amount_input:
          entry.amount.amount
          |> Decimal.to_string()
        }
      end)

    accounting_transaction = %{accounting_transaction | entries: entries}

    voucher = accounting_transaction.voucher_number || ""

    page_title = case accounting_transaction.status do
      :pending -> "Buchung #{voucher} zur Prüfung"
      :posted -> "Buchung #{voucher} abgeschlossen"
      :voided -> "Buchung #{voucher} storniert"
      _ -> "Buchung #{voucher} bearbeiten"
    end

    socket
    |> assign(:page_title, page_title)
    |> assign(:accounting_transaction, accounting_transaction)
    |> assign(:club, accounting_transaction.club)

  end

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
