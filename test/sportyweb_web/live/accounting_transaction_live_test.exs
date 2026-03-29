defmodule SportywebWeb.AccountingTransactionLiveTest do
  use SportywebWeb.ConnCase

  import Phoenix.LiveViewTest
  import Sportyweb.AccountingFixtures
  import Sportyweb.AccountsFixtures
  import Sportyweb.OrganizationFixtures
  import Sportyweb.RBAC.RoleFixtures
  import Sportyweb.RBAC.UserRoleFixtures

  alias Sportyweb.Accounting

  @create_attrs %{description: "some description", reference: "some reference"}
  @update_attrs %{description: "some updated description", reference: "some updated reference"}
  @invalid_attrs %{description: nil, reference: nil}

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

  defp create_balanced_pending_transaction() do
  club = club_fixture()
  account_a = account_fixture(%{club_id: club.id})
  account_b = account_fixture(%{club_id: club.id})

  # Buchung anlegen
  {:ok, accounting_transaction} =
    Accounting.create_accounting_transaction(%{
      "club_id" => club.id,
      "description" => "Test Buchung",
      "reference" => "REF-001",
      "status" => :draft
    })

  # Ausgeglichene Entries anlegen (Soll = Haben)
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

    # Reload mit Entries
    accounting_transaction =
      Accounting.get_accounting_transaction!(accounting_transaction.id, [:club, :entries])

    {:ok, pending} = Accounting.submit_accounting_transaction(accounting_transaction)
    {club, pending}
  end

  describe "Index" do
    setup [:create_accounting_transaction]

    test "lists all accounting_transactions - default redirect", %{conn: conn, user: user} do
      {:error, _} = live(conn, ~p"/journal")

      conn = conn |> log_in_user(user)

      {:ok, _conn} =
        conn
        |> live(~p"/journal")
        |> follow_redirect(conn, ~p"/clubs")
    end

    test "lists all accounting_transactions", %{conn: conn, user: user, accounting_transaction: accounting_transaction} do
      {:error, _} = live(conn, ~p"/clubs/#{accounting_transaction.club_id}/journal")

      conn = conn |> log_in_user(user)
      {:ok, _index_live, html} = live(conn, ~p"/clubs/#{accounting_transaction.club_id}/journal")

      assert html =~ "Journal"
      assert html =~ accounting_transaction.description
    end
  end

  describe "New/Edit - without Entries" do
    setup [:create_accounting_transaction]

    test "saves new accounting_transaction", %{conn: conn, user: user} do
      club = club_fixture()

      {:error, _} = live(conn, ~p"/clubs/#{club}/journal/new")

      conn = conn |> log_in_user(user)

      {:ok, new_live, html} = live(conn, ~p"/clubs/#{club}/journal/new")

      assert html =~ "Buchung erstellen"

      assert new_live
             |> form("#accounting_transaction-form", accounting_transaction: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        new_live
        |> form("#accounting_transaction-form", accounting_transaction: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, ~p"/clubs/#{club}/journal")

      assert html =~ "Buchung erfolgreich erstellt"
      assert html =~ "some description"
    end

    test "cancels save new accounting transaction", %{conn: conn, user: user} do
      club = club_fixture()

      conn = conn |> log_in_user(user)
      {:ok, new_live, _html} = live(conn, ~p"/clubs/#{club}/journal/new")

      {:ok, _, _html} =
        new_live
        |> element("#accounting_transaction-form a", "Abbrechen")
        |> render_click()
        |> follow_redirect(conn, ~p"/clubs/#{club}/journal")
    end

    test "updates accounting_transaction", %{conn: conn, user: user, accounting_transaction: accounting_transaction} do
      {:error, _} = live(conn, ~p"/journal/#{accounting_transaction}/edit")

      conn = conn |> log_in_user(user)

      {:ok, edit_live, html} = live(conn, ~p"/journal/#{accounting_transaction}/edit")

      #Prüft, mittels Regex, ob der @title korrekt gesetzt wird
      assert html =~ ~r/Buchung \d{4}-\d{4} bearbeiten/

      assert edit_live
             |> form("#accounting_transaction-form", accounting_transaction: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _edit_live, html} =
        edit_live
        |> form("#accounting_transaction-form", accounting_transaction: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, ~p"/journal/#{accounting_transaction}")

      assert html =~ "Buchung erfolgreich aktualisiert"
      assert html =~ "some updated description"
    end

    test "deletes accounting_transaction", %{conn: conn, user: user, accounting_transaction: accounting_transaction} do
      {:error, _} = live(conn, ~p"/journal/#{accounting_transaction}/edit")

      conn = conn |> log_in_user(user)

      {:ok, edit_live, html} = live(conn, ~p"/journal/#{accounting_transaction}/edit")
      assert html =~"some description"

      {:ok, _, html} =
        edit_live
        |> element("#accounting_transaction-form button", "Löschen")
        |> render_click()
        |> follow_redirect(conn, ~p"/clubs/#{accounting_transaction.club_id}/journal")

      assert html =~ "Buchung erfolgreich gelöscht"
      assert html =~ "Journal"
      refute html =~ "some description"
    end
  end

describe "New/Edit - with Entries" do
  setup [:create_accounting_transaction]

  test "adds entry and saves accounting_transaction",
       %{conn: conn, user: user} do
    club = club_fixture()
    account_a = account_fixture(%{club_id: club.id, accountname: "Musterkonto"})
    _account_b = account_fixture(%{club_id: club.id, accountname: "Anderskonto"})

    conn = conn |> log_in_user(user)
    {:ok, new_live, _html} = live(conn, ~p"/clubs/#{club}/journal/new")

    # Buchungszeile hinzufügen
    html =
      new_live
      |> element("button", "+ Buchungszeile hinzufügen")
      |> render_click()

    # Prüfen ob Entry-Feld erscheint
    assert html =~ "Betrag"

    # Suche auslösen — Dropdown erscheint
    # Mindestens 2 Zeichen laut Implementierung (String.length(value) < 2)

    html =
      new_live
      |> element("[phx-keyup='search_account']")
      |> render_keyup(%{"index" => "0", "value" => "M"})

    # Dropdown sollte nicht erscheinen
    refute html =~ "Musterkonto"

    # Suche nach "Muster" — sollte nur account_a treffen
    html =
      new_live
      |> element("[phx-keyup='search_account']")
      |> render_keyup(%{"index" => "0", "value" => "Mus"})

    # Prüfen ob richtiges Suchergebnis erscheint
    assert html =~ "Musterkonto"
    refute html =~ "Anderskonto"

    # Konto aus Dropdown auswählen —
    # setzt Hidden-Field auf account.id
    new_live
    |> element("[phx-click='select_account'][phx-value-id='#{account_a.id}']")
    |> render_click()

    # Prüfen ob Suchfeld den Kontonamen zeigt
    assert html =~ "Musterkonto"

    # Prüfen ob Hidden-Field mit account_id gesetzt wurde
    assert html =~ account_a.id

    # Formular absenden
    {:ok, _, html} =
      new_live
      |> form("#accounting_transaction-form",
          accounting_transaction: Map.merge(@create_attrs, %{
            "entries" => %{
              "0" => %{
                "amount_input" => "100.00",
                "description" => "Test Buchungszeile"
              }
            }
          })
        )
      |> render_submit()
      |> follow_redirect(conn, ~p"/clubs/#{club}/journal")

    assert html =~ "Buchung erfolgreich erstellt"
  end

  test "removes entry from form",
       %{conn: conn, user: user} do
    club = club_fixture()

    conn = conn |> log_in_user(user)
    {:ok, new_live, _html} = live(conn, ~p"/clubs/#{club}/journal/new")

    # Buchungszeile hinzufügen
    html =
      new_live
      |> element("button", "+ Buchungszeile hinzufügen")
      |> render_click()

    assert html =~ "Betrag"

    # Buchungszeile entfernen über phx-click="remove_entry"
    html =
      new_live
      |> element("[phx-click='remove_entry']")
      |> render_click()

    # Eintrag ist verschwunden — Summe ausgeglichen
    assert html =~ "ausgeglichen"
    refute html =~ "Betrag"
  end

  test "displays entries in show view",
       %{conn: conn, user: user,
         accounting_transaction: accounting_transaction} do
    club_id = accounting_transaction.club_id
    account = account_fixture(%{club_id: club_id})

    # Entry direkt über Context anlegen
    {:ok, _entry} =
      Sportyweb.Accounting.create_entry(%{
        "club_id" => club_id,
        "accounting_transaction_id" => accounting_transaction.id,
        "account_id" => account.id,
        "amount" => Money.new(:EUR, "100"),
        "description" => "Test Buchungszeile"
      })

    conn = conn |> log_in_user(user)

    {:ok, _show_live, html} =
      live(conn, ~p"/journal/#{accounting_transaction}")

    assert html =~ "Test Buchungszeile"
    assert html =~ account.accountname
  end

  test "shows error for unbalanced entries",
    %{conn: conn, user: user} do
    club = club_fixture()
    account_a = account_fixture(%{club_id: club.id, accountname: "Musterkonto"})
    account_b = account_fixture(%{club_id: club.id, accountname: "Anderskonto"})

    conn = conn |> log_in_user(user)
    {:ok, new_live, _html} = live(conn, ~p"/clubs/#{club}/journal/new")

    # Zwei Buchungszeilen hinzufügen
    new_live
    |> element("button", "+ Buchungszeile hinzufügen")
    |> render_click()

    new_live
    |> element("button", "+ Buchungszeile hinzufügen")
    |> render_click()

    # Account 0 suchen und auswählen
    new_live
    |> element("[phx-keyup='search_account'][phx-value-index='0']")
    |> render_keyup(%{"index" => "0", "value" => "Mus"})

    new_live
    |> element("[phx-click='select_account'][phx-value-id='#{account_a.id}']")
    |> render_click()

    # Account 1 suchen und auswählen
    new_live
    |> element("[phx-keyup='search_account'][phx-value-index='1']")
    |> render_keyup(%{"index" => "1", "value" => "And"})

    new_live
    |> element("[phx-click='select_account'][phx-value-id='#{account_b.id}']")
    |> render_click()

    # Ungleiche Beträge eingeben
    html =
      new_live
      |> form("#accounting_transaction-form",
          accounting_transaction: %{
            "entries" => %{
              "0" => %{"amount_input" => "100.00"},
              "1" => %{"amount_input" => "50.00"}
            }
          }
        )
      |> render_change()

    # Prüfen ob Summe als nicht ausgeglichen angezeigt wird
    assert html =~ "nicht ausgeglichen"
  end

end

  describe "Show" do
    setup [:create_accounting_transaction]

    test "displays accounting_transaction", %{conn: conn, user: user, accounting_transaction: accounting_transaction} do
      {:error, _} = live(conn, ~p"/journal/#{accounting_transaction}")

      conn = conn |> log_in_user(user)

      {:ok, _show_live, html} = live(conn, ~p"/journal/#{accounting_transaction}")

      assert html =~ "Buchung zu #{accounting_transaction.voucher_number}"
      assert html =~ accounting_transaction.description
    end

    test "shows edit button only for draft transactions",
        %{conn: conn, user: user, accounting_transaction: accounting_transaction} do
      conn = log_in_user(conn, user)
      {:ok, _show_live, html} = live(conn, ~p"/journal/#{accounting_transaction}")

      # Draft — Bearbeiten-Button sichtbar
      assert html =~ "Buchung bearbeiten"

      # Posted — kein Bearbeiten-Button
      {:ok, pending} = Accounting.submit_accounting_transaction(accounting_transaction)
      {:ok, _show_live, html} = live(conn, ~p"/journal/#{pending}")
      refute html =~ "Buchung bearbeiten"
    end

    test "posts accounting_transaction (draft → posted)",
      %{conn: conn, user: user} do
      {_club, pending} = create_balanced_pending_transaction()

      conn = conn |> log_in_user(user)

      {:ok, show_live, html} = live(conn, ~p"/journal/#{pending}")

      assert html =~ "Buchung freigeben"

      {:ok, _, html} =
        show_live
        |> element("button", "Buchung freigeben")
        |> render_click()
        |> follow_redirect(conn, ~p"/clubs/#{pending.club_id}/journal")

      assert html =~ "Buchung erfolgreich freigegeben"
    end

    test "reverts accounting_transaction to draft",
        %{conn: conn, user: user} do
      {_club, pending} = create_balanced_pending_transaction()

      conn = log_in_user(conn, user)

      {:ok, show_live, html} = live(conn, ~p"/journal/#{pending}")

      assert html =~ "Buchung nicht freigeben"

      {:ok, _, html} =
        show_live
        |> element("button", "Buchung nicht freigeben")
        |> render_click()
        |> follow_redirect(conn, ~p"/clubs/#{pending.club_id}/journal")

      assert html =~ "Buchung zur Überarbeitung zurückgegeben"
    end

    test "voids accounting_transaction (posted → voided)",
        %{conn: conn, user: user} do
      {_club, pending} = create_balanced_pending_transaction()
      {:ok, posted} = Accounting.post_accounting_transaction(pending)

      conn = log_in_user(conn, user)
      {:ok, show_live, html} = live(conn, ~p"/journal/#{posted}")

      assert html =~ "Stornieren"

      {:ok, _, html} =
        show_live
        |> element("button", "Stornieren")
        |> render_click()
        |> follow_redirect(conn, ~p"/clubs/#{posted.club_id}/journal")

      assert html =~ "Buchung erfolgreich storniert"
    end

  end
end
