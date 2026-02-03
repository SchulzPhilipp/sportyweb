defmodule SportywebWeb.AccounttypeLive.Index do
  use SportywebWeb, :live_view

  alias Sportyweb.Accounting
  alias Sportyweb.Accounting.Accounttype

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :accounttypes, Accounting.list_accounttypes())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Accounttype")
    |> assign(:accounttype, Accounting.get_accounttype!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Accounttype")
    |> assign(:accounttype, %Accounttype{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Accounttypes")
    |> assign(:accounttype, nil)
  end

  @impl true
  def handle_info({SportywebWeb.AccounttypeLive.FormComponent, {:saved, accounttype}}, socket) do
    {:noreply, stream_insert(socket, :accounttypes, accounttype)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    accounttype = Accounting.get_accounttype!(id)
    {:ok, _} = Accounting.delete_accounttype(accounttype)

    {:noreply, stream_delete(socket, :accounttypes, accounttype)}
  end
end
