defmodule SportywebWeb.AccountLive.Index do
  use SportywebWeb, :live_view

  alias Sportyweb.Accounting
  alias Sportyweb.Accounting.Account

  @impl true
  def mount(_params, _session, socket) do
    accounts =
      Accounting.list_accounts()
      |> Sportyweb.Repo.preload([:accountclass, :accountgroup, :accounttype])

    {:ok, stream(socket, :accounts, accounts)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    # Preload Data from references
    account = Sportyweb.Accounting.get_account!(id)

    account
    |> Sportyweb.Repo.preload([:accountclass, :accountgroup, :accounttype])

    socket
    |> assign(:page_title, "Edit Account")
    |> assign(:account, account)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Account")
    |> assign(:account, %Account{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Accounts")
    |> assign(:account, nil)
  end

  @impl true
  def handle_info({SportywebWeb.AccountLive.FormComponent, {:saved, account}}, socket) do
    account = Sportyweb.Repo.preload(account, [:accountclass, :accountgroup, :accounttype])
    {:noreply, stream_insert(socket, :accounts, account)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    account = Accounting.get_account!(id)
    {:ok, _} = Accounting.delete_account(account)

    {:noreply, stream_delete(socket, :accounts, account)}
  end
end
