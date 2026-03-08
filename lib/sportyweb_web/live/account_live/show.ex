defmodule SportywebWeb.AccountLive.Show do
  use SportywebWeb, :live_view

  alias Sportyweb.Accounting

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    account = Accounting.get_account!(id)

    {:ok, socket
      |> assign(:club_navigation_current_item, :accounts)
      |> assign(:account, account)
      |> assign(:club, account.club)
  }
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    # Preload Data from references
    account = Accounting.get_account!(id)

    {:noreply,
     socket
     |> assign(:page_title, "Konto: #{account.accountnumber}")
     |> assign(:account, account)
     |> assign(:club, account.club)}
  end

  defp display_money(money_struct) do
    case Money.to_string(money_struct) do
      {:ok, string} -> string
      _ -> "0,00 €"
    end
  end
end
