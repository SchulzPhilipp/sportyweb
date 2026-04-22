defmodule SportywebWeb.Accounting.Journal.AccountingTransactionLive.Index do
  use SportywebWeb, :live_view

  import SportywebWeb.PeriodNavigatorComponent

  alias Sportyweb.Accounting
  alias Sportyweb.Organization

  on_mount {SportywebWeb.CommonHelper, :load_active_period}

  @impl true
  def mount(%{"club_id" => club_id}, _session, socket) do
    # Transactions are scoped to the active period rather than loading all
    # transactions for the club, keeping the list manageable and period-aware.
    accounting_transactions = load_transactions(club_id, socket.assigns.active_period)

    {:ok,
    socket
    # Precompute the empty-state flag once so the template does not need to
    # evaluate the list length on every render.
    |> assign(:has_transactions?, accounting_transactions != [])
    |> assign(:club_navigation_current_item, :journal)
    # Keep the full unfiltered list in assigns so that client-side status
    # filtering (handle_event "filter") can operate without a database round-trip.
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
    all = socket.assigns.all_accounting_transactions

    # Filter entirely in memory against the already-loaded list rather than
    # issuing a new database query for each status change.
    filtered =
      case filter do
        "all" -> all
        status -> Enum.filter(all, fn t -> Atom.to_string(t.status) == status end)
      end

    {:noreply,
      socket
      |> assign(:filter, filter)
      # reset: true replaces the existing stream, preventing stale entries from
      # remaining visible after a filter change.
      |> stream(:accounting_transactions, filtered, reset: true)}
  end

  # Guard clause: return an empty list when no active period exists yet,
  # avoiding a database call with a nil period_id.
  defp load_transactions(_club_id, nil), do: []
  defp load_transactions(club_id, period) do
    Accounting.list_accounting_transactions_for_period(club_id, period.id)
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
