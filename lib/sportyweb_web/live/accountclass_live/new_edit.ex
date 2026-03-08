defmodule SportywebWeb.AccountclassLive.NewEdit do
  use SportywebWeb, :live_view

  alias Sportyweb.Accounting
  alias Sportyweb.Accounting.Accountclass
  alias Sportyweb.Organization

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.live_component
        module={SportywebWeb.AccountclassLive.FormComponent}
        id={@accountclass.id || :new}
        title={@page_title}
        action={@live_action}
        accountclass={@accountclass}
        navigate={
          if @accountclass.id,
            do: ~p"/accountclasses/#{@accountclass}",
            else: ~p"/clubs/#{@club}/accountclasses"
        }
      />
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket
    |> assign(:club_navigation_current_item, :accountclasses)
  }
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
  # Preload Data from references
    accountclass = Sportyweb.Accounting.get_accountclass!(id)

    socket
    |> assign(:page_title, "Kontenklasse bearbeiten")
    |> assign(:accountclass, accountclass)
    |> assign(:club, accountclass.club)
  end

  defp apply_action(socket, :new, %{"club_id" => club_id}) do
    club = Organization.get_club!(club_id)

    socket
    |> assign(:page_title, "Kontenklasse erstellen")
    |> assign(:accountclass, %Accountclass{
      club_id: club.id,
      club: club})
    |> assign(:club, club)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    accountclass = Accounting.get_accountclass!(id)
    {:ok, _} = Accounting.delete_accountclass(accountclass)

    {:noreply,
     socket
     |> put_flash(:info, "Kontenklasse erfolgreich gelöscht")
     |> push_navigate(to: "/clubs/#{accountclass.club_id}/accountclasses")}
  end
end
