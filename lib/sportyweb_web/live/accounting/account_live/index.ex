defmodule SportywebWeb.Accounting.AccountLive.Index do
  use SportywebWeb, :live_view

  alias Sportyweb.Accounting
  alias Sportyweb.Accounting.Account
  alias Sportyweb.Organization

  @impl true
  def mount(%{"club_id" => club_id}, _session, socket) do
    accounts = Accounting.list_accounts(club_id, [:accountclass, :accountgroup])
    accountclasses = Accounting.list_accountclasses(club_id, [:accounts])

    {:ok,
    socket
    |> assign(:has_accounts?, accounts != [])
    |> assign(:club_id, club_id)
    |> assign(:club_navigation_current_item, :accounts)
    |> assign(:accountclasses, accountclasses)
    |> assign(:search_query, "")
    |> assign(:search_results, [])
  }
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index_root, _params) do
    socket
    |> redirect(to: "/clubs")
  end

  defp apply_action(socket, :index, %{"club_id" => club_id}) do
    club = Organization.get_club!(club_id)

    socket
    |> assign(:page_title, "Kontenverwaltung")
    |> assign(:club, club)
  end

@impl true
def handle_event("search_accounts", %{"query" => query}, socket) do
  results =
    if String.trim(query) == "" do
      []
    else
      q = String.downcase(query)
      socket.assigns.accountclasses
      |> Enum.flat_map(& &1.accounts)
      |> Enum.filter(fn account ->
        String.contains?(String.downcase(account.accountname), q) ||
        String.contains?(account.accountnumber, q)
      end)
      |> Enum.sort_by(& &1.accountnumber)
    end

  {:noreply,
   socket
   |> assign(:search_query, query)
   |> assign(:search_results, results)}
end

end
