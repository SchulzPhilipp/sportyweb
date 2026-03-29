defmodule SportywebWeb.AccountingTransactionLive.Index do
  use SportywebWeb, :live_view

  alias Sportyweb.Accounting
  alias Sportyweb.Organization

  @impl true
  def mount(%{"club_id" => club_id}, _session, socket) do
    accounting_transactions = Accounting.list_accounting_transactions(club_id)

    {:ok,
    socket
    |> assign(:has_transactions?, accounting_transactions != [])
    |> assign(:club_navigation_current_item, :journal)
    |> assign(:all_accounting_transactions, accounting_transactions)
    |> assign(:filter, "all")
    |> stream(:accounting_transactions, accounting_transactions)}
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("filter", %{"filter" => filter}, socket) do
    club_id = socket.assigns.club.id
    all = Accounting.list_accounting_transactions(club_id)

    filtered =
      case filter do
        "all" -> all
        status -> Enum.filter(all, fn t -> Atom.to_string(t.status) == status end)
      end

    {:noreply,
      socket
      |> assign(:filter, filter)
      |> assign(:all_accounting_transactions, all)
      |> stream(:accounting_transactions, filtered, reset: true)}
  end

  defp apply_action(socket, :index_root, _params) do
    socket
    |> redirect(to: "/clubs")
  end

  defp apply_action(socket, :index, %{"club_id" => club_id}) do
    club = Organization.get_club!(club_id)

    socket
    |> assign(:page_title, "Journal")
    |> assign(:club, club)
  end

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
