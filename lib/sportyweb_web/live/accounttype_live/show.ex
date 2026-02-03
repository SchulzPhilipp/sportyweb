defmodule SportywebWeb.AccounttypeLive.Show do
  use SportywebWeb, :live_view

  alias Sportyweb.Accounting

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:accounttype, Accounting.get_accounttype!(id))}
  end

  defp page_title(:show), do: "Show Accounttype"
  defp page_title(:edit), do: "Edit Accounttype"
end
