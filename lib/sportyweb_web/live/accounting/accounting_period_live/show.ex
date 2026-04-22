defmodule SportywebWeb.Accounting.AccountingPeriodLive.Show do
  use SportywebWeb, :live_view

  alias Sportyweb.Accounting

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    accounting_period = Accounting.get_accounting_period!(id)

    {:ok, socket
      |> assign(:club_navigation_current_item, :accounting_periods)
      |> assign(:accounting_period, accounting_period)
      |> assign(:club, accounting_period.club)
  }
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    accounting_period = Accounting.get_accounting_period!(id)

    {:noreply,
     socket
     |> assign(:page_title, "Buchungsperiode #{accounting_period.name}")
     |> assign(:accounting_period, accounting_period)
     |> assign(:club, accounting_period.club)
    }
  end

  defp format_date(nil), do: "—"
  defp format_date(%Date{} = date) do
    Calendar.strftime(date, "%d.%m.%Y")
  end

end
