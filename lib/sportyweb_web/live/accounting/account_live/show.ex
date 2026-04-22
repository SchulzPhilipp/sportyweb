defmodule SportywebWeb.Accounting.AccountLive.Show do
  use SportywebWeb, :live_view

  alias Sportyweb.Accounting

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    account = Accounting.get_account!(id, [:accountclass, :accountgroup, :club])

    {:ok, socket
      |> assign(:club_navigation_current_item, :accounts)
      |> assign(:account, account)
      |> assign(:club, account.club)
  }
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    account = Accounting.get_account!(id, [:accountclass, :accountgroup, :club])

    {:noreply,
     socket
     |> assign(:page_title, "Konto: #{account.accountnumber}")
     |> assign(:account, account)
     |> assign(:club, account.club)}
  end

end
