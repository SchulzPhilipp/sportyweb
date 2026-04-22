defmodule SportywebWeb.Accounting.Ledger.AccountingTransactionLiveTest do
  use SportywebWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Sportyweb.AccountingFixtures
  import Sportyweb.AccountsFixtures
  import Sportyweb.OrganizationFixtures
  import Sportyweb.RBAC.RoleFixtures
  import Sportyweb.RBAC.UserRoleFixtures

  alias Sportyweb.Accounting

  setup do
    user = user_fixture()
    applicationrole = application_role_fixture()
    user_application_role_fixture(%{user_id: user.id, applicationrole_id: applicationrole.id})

    %{user: user}
  end

  defp create_accounting_transaction(_) do
    accounting_transaction = accounting_transaction_fixture()
    %{accounting_transaction: accounting_transaction}
  end

  defp create_balanced_posted_transaction() do
    club = club_fixture()
    period = accounting_period_fixture(club_id: club.id)
    account_a = account_fixture(%{club_id: club.id})
    account_b = account_fixture(%{club_id: club.id})

    {:ok, accounting_transaction} =
      Accounting.create_accounting_transaction(%{
        "club_id" => club.id,
        "accounting_period_id" => period.id,
        "document_date" => ~D[2026-01-31],
        "description" => "Test Buchung",
        "reference" => "REF-001",
        "status" => :draft
      })

    {:ok, _} =
      Accounting.create_entry(%{
        "club_id" => club.id,
        "accounting_transaction_id" => accounting_transaction.id,
        "account_id" => account_a.id,
        "amount" => Money.new(:EUR, "100"),
        "description" => "Soll"
      })

    {:ok, _} =
      Accounting.create_entry(%{
        "club_id" => club.id,
        "accounting_transaction_id" => accounting_transaction.id,
        "account_id" => account_b.id,
        "amount" => Money.new(:EUR, "-100"),
        "description" => "Haben"
      })

    accounting_transaction =
      Accounting.get_accounting_transaction!(accounting_transaction.id, [:club, :entries])

    {:ok, pending} = Accounting.submit_accounting_transaction(accounting_transaction)
    {:ok, posted} = Accounting.post_accounting_transaction(pending)

    {club, posted, account_a, account_b}
  end

  describe "Index" do
    setup [:create_accounting_transaction]

    test "lists all grouped accounts with balances - default redirect", %{conn: conn, user: user} do
      {:error, _} = live(conn, ~p"/ledger")

      conn = conn |> log_in_user(user)

      {:ok, _conn} =
        conn
        |> live(~p"/ledger")
        |> follow_redirect(conn, ~p"/clubs")
    end

    test "displays empty state without posted transactions", %{conn: conn, user: user, accounting_transaction: accounting_transaction} do

      {:error, _} = live(conn, ~p"/clubs/#{accounting_transaction.club_id}/ledger")

      conn = conn |> log_in_user(user)

      {:ok, _index_live, html} = live(conn, ~p"/clubs/#{accounting_transaction.club_id}/ledger")

      assert html =~ "Hauptbuch"
      assert html =~ "Bisher wurden noch keine Buchungen erstellt."
    end

    test "lists all grouped accounts with balances", %{conn: conn, user: user} do
      {club, _posted, account_a, account_b} = create_balanced_posted_transaction()

      {:error, _} = live(conn, ~p"/clubs/#{club}/ledger")

      conn = conn |> log_in_user(user)

      {:ok, _index_live, html} = live(conn, ~p"/clubs/#{club}/ledger")

      assert html =~ "Hauptbuch"
      assert html =~ "Kontonummer"
      assert html =~ "Soll"
      assert html =~ "Haben"
      assert html =~ account_a.accountnumber
      assert html =~ account_b.accountnumber
      refute html =~ "Bisher wurden noch keine Buchungen erstellt."
    end

  end

  describe "Show" do
    setup [:create_accounting_transaction]

    test "shows empty state when no entries exist for period", %{conn: conn, user: user} do
      club = club_fixture()
      _period = accounting_period_fixture(%{club_id: club.id})
      accountclass = accountclass_fixture(%{club_id: club.id})
      account = account_fixture(%{club_id: club.id, accountclass_id: accountclass.id})

      conn = log_in_user(conn, user)
      {:ok, _live, html} = live(conn, ~p"/clubs/#{club}/ledger/#{account}")

      assert html =~ account.accountname
      assert html =~ account.accountnumber
      assert html =~ "Keine Buchungen für dieses Konto vorhanden."
      refute html =~ "Saldo"
    end

    test "displays posted entries with debit/credit columns", %{conn: conn, user: user} do
      {club, _posted, account_a, _account_b} = create_balanced_posted_transaction()

      conn = log_in_user(conn, user)
      {:ok, _live, html} = live(conn, ~p"/clubs/#{club}/ledger/#{account_a}")

      assert html =~ account_a.accountname
      assert html =~ account_a.accountnumber
      # Tabellenstruktur
      assert html =~ "Belegdatum"
      assert html =~ "Buchungsnr."
      assert html =~ "Sphäre"
      assert html =~ "Soll"
      assert html =~ "Haben"
      # Saldo-Zeile
      assert html =~ "Saldo"
      # Betrag aus create_balanced_posted_transaction
      assert html =~ "100"
      # Sphere-Label aus der Fixture (:ideal)
      assert html =~ "Ideeller Bereich"
      # Zurück-Link
      assert html =~ "Zurück zum Hauptbuch"
      refute html =~ "Keine Buchungen für dieses Konto vorhanden."
    end

  end
end
