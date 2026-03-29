defmodule SportywebWeb.AccountLiveTest do
  use SportywebWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Sportyweb.AccountingFixtures
  import Sportyweb.AccountsFixtures
  import Sportyweb.OrganizationFixtures
  import Sportyweb.RBAC.RoleFixtures
  import Sportyweb.RBAC.UserRoleFixtures

  @create_attrs %{
    accountnumber: "0815",
    accountname: "some accountname",
    accountbalance: "120.00",
    accounttypecode: "neutral"
  }
  @update_attrs %{
    accountnumber: "0816",
    accountname: "some updated accountname",
    accountbalance: "456.00",
    accounttypecode: "passiv"
  }
  @invalid_attrs %{
    accountnumber: nil,
    accountname: nil,
    accountbalance: nil,
    accountclass_id: nil,
    accountgroup_id: nil,
  }

  setup do
    user = user_fixture()
    applicationrole = application_role_fixture()
    user_application_role_fixture(%{user_id: user.id, applicationrole_id: applicationrole.id})

    %{user: user}
  end

  defp create_account(_) do
    account = account_fixture()
    %{account: account}
  end

  describe "Index" do
    setup [:create_account]

    test "lists all accounts - default redirect", %{conn: conn, user: user} do
      {:error, _} = live(conn, ~p"/accounts")

      conn = conn |> log_in_user(user)

      {:ok, _conn} =
        conn
        |> live(~p"/accounts")
        |> follow_redirect(conn, ~p"/clubs")
    end

    test "lists all accounts", %{conn: conn, user: user, account: account} do
      {:error, _} = live(conn, ~p"/clubs/#{account.club_id}/accounts")

      conn = conn |> log_in_user(user)
      {:ok, _index_live, html} = live(conn, ~p"/clubs/#{account.club_id}/accounts")

      assert html =~ "Kontenplan"
      assert html =~ account.accountname
    end
end

  describe "New/Edit" do
    setup [:create_account]

    test "saves new account", %{conn: conn, user: user} do
      club = club_fixture()
      accountclass = Sportyweb.AccountingFixtures.accountclass_fixture(%{club_id: club.id})
      accountgroup = Sportyweb.AccountingFixtures.accountgroup_fixture(%{club_id: club.id})

      random_accountnumber = Integer.to_string(:rand.uniform(90_000))

      {:error, _} = live(conn, ~p"/clubs/#{club}/accounts/new")

      conn = conn |> log_in_user(user)

      {:ok, new_live, html} = live(conn, ~p"/clubs/#{club}/accounts/new")

      assert html =~ "Konto erstellen"

      valid_attrs =
        @create_attrs
        |> Map.put(:accountnumber, random_accountnumber)
        |> Map.put(:accountclass_id, accountclass.id)
        |> Map.put(:accountgroup_id, accountgroup.id)
        |> Map.put(:club_id, club.id)

      assert new_live
             |> form("#account-form", account: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        new_live
        |> form("#account-form", account: valid_attrs)
        |> render_submit()
        |> follow_redirect(conn, ~p"/clubs/#{club}/accounts")

      assert html =~ "Konto erfolgreich erstellt"
      assert html =~ "some accountname"
    end

    test "cancels save new account", %{conn: conn, user: user} do
      club = club_fixture()

      conn = conn |> log_in_user(user)
      {:ok, new_live, _html} = live(conn, ~p"/clubs/#{club}/accounts/new")

      {:ok, _, _html} =
        new_live
        |> element("#account-form a", "Abbrechen")
        |> render_click()
        |> follow_redirect(conn, ~p"/clubs/#{club}/accounts")
    end

    test "updates account", %{conn: conn, user: user, account: account} do

      {:error, _} = live(conn, ~p"/accounts/#{account}/edit")

      conn = conn |> log_in_user(user)

      {:ok, edit_live, html} = live(conn, ~p"/accounts/#{account}/edit")

      assert html =~ "Konto bearbeiten"

      valid_attrs =
        @update_attrs
        |> Map.put(:accountclass_id, account.accountclass_id)
        |> Map.put(:accountgroup_id, account.accountgroup_id)
        |> Map.put(:club_id, account.club_id)

        assert edit_live
             |> form("#account-form", account: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _edit_live, html} =
        edit_live
        |> form("#account-form", account: valid_attrs)
        |> render_submit()
        |> follow_redirect(conn, ~p"/accounts/#{account}")

      assert html =~ "Konto erfolgreich aktualisiert"
      assert html =~ "some updated accountname"
    end

    test "cancels updates account", %{conn: conn, user: user, account: account} do
      conn = conn |> log_in_user(user)
      {:ok, edit_live, _html} = live(conn, ~p"/accounts/#{account}/edit")

      {:ok, _, _html} =
        edit_live
        |> element("#account-form a", "Abbrechen")
        |> render_click()
        |> follow_redirect(conn, ~p"/accounts/#{account}")
    end

    test "deletes account", %{conn: conn, user: user, account: account} do
      {:error, _} = live(conn, ~p"/accounts/#{account}/edit")

      conn = conn |> log_in_user(user)
      {:ok, edit_live, html} = live(conn, ~p"/accounts/#{account}/edit")
      assert html =~ "some accountname"

      {:ok, _, html} =
        edit_live
        |> element("#account-form button", "Löschen")
        |> render_click()
        |> follow_redirect(conn, ~p"/clubs/#{account.club_id}/accounts")

      assert html =~ "Konto erfolgreich gelöscht"
      assert html =~ "Kontenplan"
      refute html =~ "some accountname"
    end
  end

  describe "Show" do
    setup [:create_account]

    test "displays account", %{conn: conn, user: user, account: account} do
      {:error, _} = live(conn, ~p"/accounts/#{account}")

      conn = conn |> log_in_user(user)
      {:ok, _show_live, html} = live(conn, ~p"/accounts/#{account}")

      assert html =~ "Konto:"
      assert html =~ account.accountnumber
    end
  end
end
