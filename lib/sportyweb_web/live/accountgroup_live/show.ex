defmodule SportywebWeb.AccountgroupLive.Show do
  use SportywebWeb, :live_view

  alias Sportyweb.Accounting

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    accountgroup = Accounting.get_accountgroup!(id)
    {:ok, socket
      |> assign(:club_navigation_current_item, :accountgroups)
      |> assign(:accountgroup, accountgroup)
      |> assign(:club, accountgroup.club)
  }
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    accountgroup = Accounting.get_accountgroup!(id)

    {:noreply,
     socket
     |> assign(:page_title, "Kontengruppe anzeigen")
     |> assign(:accountgroup, accountgroup)
     |> assign(:club, accountgroup.club)}
  end

end
