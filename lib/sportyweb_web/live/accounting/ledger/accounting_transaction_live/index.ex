defmodule SportywebWeb.Accounting.Ledger.AccountingTransactionLive.Index do
  use SportywebWeb, :live_view

  import SportywebWeb.PeriodNavigatorComponent

  alias Sportyweb.Accounting
  alias Sportyweb.Organization
  alias Sportyweb.Accounting.Account

  # Resolves the active accounting period before mount/3 runs and injects it
  # into socket.assigns as @active_period. Required here because account
  # balances are always scoped to a specific period.
  on_mount {SportywebWeb.CommonHelper, :load_active_period}

  @impl true
  def mount(%{"club_id" => club_id}, _session, socket) do
    # Accounts are grouped by account class (e.g. assets, liabilities) so the
    # template can render each class as a separate section without additional
    # sorting logic in the template itself.
    grouped_accounts = load_grouped_accounts(club_id, socket.assigns.active_period)

    {:ok,
     socket
     |> assign(:club_id, club_id)
     # Precompute the empty-state flag once to avoid evaluating the list in
     # the template on every render.
     |> assign(:has_transactions?, grouped_accounts != [])
     |> assign(:club_navigation_current_item, :ledger)
     |> assign(:grouped_accounts, grouped_accounts)}

  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  # Guard clause: return an empty list when no active period exists yet,
  # avoiding a database call with a nil period_id.
  defp load_grouped_accounts(_club_id, nil), do: []
  defp load_grouped_accounts(club_id, period) do
    Accounting.list_accounts_grouped(club_id, period.id)
  end

  defp apply_action(socket, :index_root, _params) do
    socket
    |> redirect(to: "/clubs")
  end

  defp apply_action(socket, :index, %{"club_id" => club_id}) do
    club = Organization.get_club!(club_id)

    socket
    |> assign(:page_title, "Hauptbuch")
    |> assign(:club, club)
  end

  # Returns the debit portion of a balance, or zero if the balance is negative.
  defp soll_betrag(balance) do
    if Money.positive?(balance), do: balance, else: Money.new(:EUR, 0)
  end

  # Returns the absolute credit portion of a balance, or zero if positive.
  defp haben_betrag(balance) do
    if Money.negative?(balance), do: Money.abs(balance), else: Money.new(:EUR, 0)
  end

  # Renders a zero balance as an em dash rather than "0,00 EUR" to keep the
  # table visually uncluttered. Non-zero values are formatted by Money.to_string!/1.
  defp format_money(%Money{amount: amount} = money) do
    if Decimal.equal?(amount, Decimal.new(0)),
      do: "—",
      else: Money.to_string!(money)
  end

end
