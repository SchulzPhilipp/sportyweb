defmodule SportywebWeb.AccountLive.Show do
  use SportywebWeb, :live_view

  alias Sportyweb.Accounting

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    #Preload Data from references
    item = Sportyweb.Accounting.get_account!(id)
    |>Sportyweb.Repo.preload([:accountclass, :accountgroup, :accounttype])

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:account, item)
     |> assign(:item, item)
    }
  end

  defp page_title(:show), do: "Show Account"
  defp page_title(:edit), do: "Edit Account"
end
