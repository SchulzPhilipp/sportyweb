defmodule SportywebWeb.Accounting.AccountingPeriodLive.NewEdit do
  use SportywebWeb, :live_view

  alias Sportyweb.Accounting
  alias Sportyweb.Accounting.AccountingPeriod
  alias Sportyweb.Organization

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.live_component
        module={SportywebWeb.Accounting.AccountingPeriodLive.FormComponent}
        id={@accounting_period.id || :new}
        title={@page_title}
        action={@live_action}
        accounting_period={@accounting_period}
        navigate={
          if @accounting_period.id,
            do: ~p"/accounting_periods/#{@accounting_period}",
            else: ~p"/clubs/#{@club}/accounting_periods"
        }
      />
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket
    |> assign(:club_navigation_current_item, :accounting_periods)
  }
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    accounting_period = Sportyweb.Accounting.get_accounting_period!(id)

    socket
    |> assign(:page_title, "Buchungsperiode bearbeiten")
    |> assign(:accounting_period, accounting_period)
    |> assign(:club, accounting_period.club)

  end

  defp apply_action(socket, :new, %{"club_id" => club_id}) do
    club = Organization.get_club!(club_id)

    socket
    |> assign(:page_title, "Buchungsperiode erstellen")
    |> assign(:accounting_period, %AccountingPeriod{
      club_id: club.id,
      club: club,
    })    |> assign(:club, club)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    accounting_period = Accounting.get_accounting_period!(id)
    {:ok, _} = Accounting.delete_accounting_period(accounting_period)

    {:noreply,
     socket
     |> put_flash(:info, "Buchungsperiode erfolgreich gelöscht")
     |> push_navigate(to: "/clubs/#{accounting_period.club_id}/accounting_periods")}
  end
end
