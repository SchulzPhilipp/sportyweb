defmodule SportywebWeb.AccountclassLive.Show do
  use SportywebWeb, :live_view

  alias Sportyweb.Accounting

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    accountclass = Accounting.get_accountclass!(id)

    {:ok, socket
      |> assign(:club_navigation_current_item, :accountclasses)
      |> assign(:accountclass, accountclass)
      |> assign(:club, accountclass.club)
  }
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    accountclass = Accounting.get_accountclass!(id)

    {:noreply,
     socket
     |> assign(:page_title, "Kontenklasse #{accountclass.accountclassnumber}")
     |> assign(:accountclass, accountclass)
     |> assign(:club, accountclass.club)
    }
  end
end
