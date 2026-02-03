defmodule SportywebWeb.AccountgroupLive.Index do
  use SportywebWeb, :live_view

  alias Sportyweb.Accounting
  alias Sportyweb.Accounting.Accountgroup

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :accountgroups, Accounting.list_accountgroups())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Accountgroup")
    |> assign(:accountgroup, Accounting.get_accountgroup!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Accountgroup")
    |> assign(:accountgroup, %Accountgroup{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Accountgroups")
    |> assign(:accountgroup, nil)
  end

  @impl true
  def handle_info({SportywebWeb.AccountgroupLive.FormComponent, {:saved, accountgroup}}, socket) do
    {:noreply, stream_insert(socket, :accountgroups, accountgroup)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    accountgroup = Accounting.get_accountgroup!(id)
    {:ok, _} = Accounting.delete_accountgroup(accountgroup)

    {:noreply, stream_delete(socket, :accountgroups, accountgroup)}
  end
end
