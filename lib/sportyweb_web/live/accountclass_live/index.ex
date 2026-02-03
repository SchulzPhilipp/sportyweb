defmodule SportywebWeb.AccountclassLive.Index do
  use SportywebWeb, :live_view

  alias Sportyweb.Accounting
  alias Sportyweb.Accounting.Accountclass

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :accountclasses, Accounting.list_accountclasses())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Accountclass")
    |> assign(:accountclass, Accounting.get_accountclass!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Accountclass")
    |> assign(:accountclass, %Accountclass{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Accountclasses")
    |> assign(:accountclass, nil)
  end

  @impl true
  def handle_info({SportywebWeb.AccountclassLive.FormComponent, {:saved, accountclass}}, socket) do
    {:noreply, stream_insert(socket, :accountclasses, accountclass)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    accountclass = Accounting.get_accountclass!(id)
    {:ok, _} = Accounting.delete_accountclass(accountclass)

    {:noreply, stream_delete(socket, :accountclasses, accountclass)}
  end
end
