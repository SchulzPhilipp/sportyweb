defmodule SportywebWeb.Accounting.AccountingPeriodLive.Index do
  use SportywebWeb, :live_view

  alias Sportyweb.Accounting
  alias Sportyweb.Organization

  @impl true
  def mount(%{"club_id" => club_id}, _session, socket) do
    accounting_periods = Accounting.list_accounting_periods(club_id)

    {:ok,
    socket
    |> assign(:has_periods?, accounting_periods != [])
    |> assign(:club_navigation_current_item, :accounting_periods)
    |> stream(:accounting_periods, accounting_periods)}
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
    |> assign(:page_title, "Buchungsperioden")
    |> assign(:club, club)
  end

  defp format_date(nil), do: "—"
  defp format_date(%Date{} = date) do
    Calendar.strftime(date, "%d.%m.%Y")
  end

end
