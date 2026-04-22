defmodule SportywebWeb.Accounting.Ledger.AccountingTransactionLive.Show do
  use SportywebWeb, :live_view

  import SportywebWeb.PeriodNavigatorComponent

  alias Sportyweb.Accounting
  alias Sportyweb.Organization
  alias Sportyweb.Accounting.Account

  # Resolves the active accounting period before mount/3 runs and injects it
  # into socket.assigns as @active_period. Entry loading is period-scoped,
  # so this must be available before any database calls are made.
  on_mount {SportywebWeb.CommonHelper, :load_active_period}

  @impl true
  def mount(%{"club_id" => club_id, "account_id" => account_id}, _session, socket) do
    accounting_period = socket.assigns.active_period
    accounting_period_id = accounting_period && accounting_period.id
    club = Organization.get_club!(club_id)

    # When no active period exists, only the account metadata is loaded and
    # entries default to an empty list. This avoids a query with a nil
    # period_id while still allowing the page to render gracefully.
    %{account: account, entries: entries} =
      if accounting_period_id do
        Accounting.get_account_with_entries!(account_id, accounting_period_id)
      else
        %{account: Accounting.get_account!(account_id), entries: []}
      end

    {:ok,
     socket
     |> assign(:club_id, club_id)
     |> assign(:club, club)
     |> assign(:club_navigation_current_item, :ledger)
     |> assign(:account, account)
     |> assign(:entries, entries)
    }
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply,
     assign(socket, :page_title, socket.assigns.account.accountname)}
  end

  # Returns the debit portion of a balance, or zero if the balance is negative.
  defp soll_betrag(balance) do
    if Money.positive?(balance), do: balance, else: Money.new(:EUR, 0)
  end

  # Returns the absolute credit portion of a balance, or zero if positive.
  defp haben_betrag(balance) do
    if Money.negative?(balance), do: Money.abs(balance), else: Money.new(:EUR, 0)
  end

  # Renders a zero balance as an em dash rather than "0,00 EUR" to keep the
  # table visually uncluttered. Non-zero values are formatted by Money.to_string!/1.
  defp format_money(%Money{amount: amount} = money) do
    if Decimal.equal?(amount, Decimal.new(0)),
      do: "—",
      else: Money.to_string!(money)
  end

  # Computes the net balance of all entries for this account in the active
  # period. Positive result = debit surplus, negative = credit surplus.
  # Uses the signed amount directly, so no sign conversion is needed here.
  defp saldo(entries) do
    Enum.reduce(entries, Money.new(:EUR, 0), fn entry, acc ->
      Money.add!(acc, entry.amount)
    end)
  end

  # Human-readable labels for the four tax spheres.
  defp sphere_label(:ideal),  do: "Ideeller Bereich"
  defp sphere_label(:asset_management),  do: "Vermögensverwaltung"
  defp sphere_label(:purpose_related),  do: "Zweckbetrieb"
  defp sphere_label(:commercial),  do: "Wirtschaftlicher Geschäftsbetrieb"

end
