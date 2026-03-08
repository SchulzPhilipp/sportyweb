defmodule SportywebWeb.AccountgroupLive.NewEdit do
  use SportywebWeb, :live_view

  alias Sportyweb.Accounting
  alias Sportyweb.Accounting.Accountgroup
  alias Sportyweb.Organization

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.live_component
        module={SportywebWeb.AccountgroupLive.FormComponent}
        id={@accountgroup.id || :new}
        title={@page_title}
        action={@live_action}
        accountgroup={@accountgroup}
        navigate={
          if @accountgroup.id,
            do: ~p"/accountgroups/#{@accountgroup}",
            else: ~p"/clubs/#{@club}/accountgroups"
        }
      />
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket
    |> assign(:club_navigation_current_item, :accountgroups)
  }
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
  # Preload Data from references
    accountgroup = Sportyweb.Accounting.get_accountgroup!(id)

    socket
    |> assign(:page_title, "Kontengruppe bearbeiten")
    |> assign(:accountgroup, accountgroup)
    |> assign(:club, accountgroup.club)
  end

  defp apply_action(socket, :new, %{"club_id" => club_id}) do
    club = Organization.get_club!(club_id)

    socket
    |> assign(:page_title, "Kontengruppe erstellen")
    |> assign(:accountgroup, %Accountgroup{
      club_id: club.id,
      club: club})
    |> assign(:club, club)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    accountgroup = Accounting.get_accountgroup!(id)
    {:ok, _} = Accounting.delete_accountgroup(accountgroup)

    {:noreply,
     socket
     |> put_flash(:info, "Kontengruppe erfolgreich gelöscht")
     |> push_navigate(to: "/clubs/#{accountgroup.club_id}/accountgroups")}
  end
end
