defmodule SportywebWeb.AccountclassLiveTest do
  use SportywebWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Sportyweb.AccountingFixtures
  import Sportyweb.AccountsFixtures
  import Sportyweb.OrganizationFixtures
  import Sportyweb.RBAC.RoleFixtures
  import Sportyweb.RBAC.UserRoleFixtures

  @create_attrs %{
    accountclassnumber: "some accountclassnumber",
    accountclassname: "some accountclassname"
  }
  @update_attrs %{
    accountclassnumber: "some updated accountclassnumber",
    accountclassname: "some updated accountclassname"
  }
  @invalid_attrs %{accountclassnumber: nil, accountclassname: nil}

  setup do
    user = user_fixture()
    applicationrole = application_role_fixture()
    user_application_role_fixture(%{user_id: user.id, applicationrole_id: applicationrole.id})

    %{user: user}
  end

  defp create_accountclass(_) do
    accountclass = accountclass_fixture()
    %{accountclass: accountclass}
  end

  describe "Index" do
    setup [:create_accountclass]

    test "lists all accountclasses - default redirect", %{conn: conn, user: user} do
      {:error, _} = live(conn, ~p"/accountclasses")

      conn = conn |> log_in_user(user)

      {:ok, conn} =
        conn
        |> live(~p"/accountclasses")
        |> follow_redirect(conn, ~p"/clubs")

      assert conn.resp_body =~ "Vereinsübersicht"
    end


    test "lists all accountclasses", %{conn: conn, user: user, accountclass: accountclass} do
      {:error, _} = live(conn, ~p"/clubs/#{accountclass.club_id}/accounts")

      conn = conn |> log_in_user(user)

      {:ok, _index_live, html} = live(conn, ~p"/clubs/#{accountclass.club_id}/accountclasses")

      assert html =~ "Kontenklassen"
      assert html =~ accountclass.accountclassname
    end
end

describe "New/Edit" do
    setup [:create_accountclass]

    test "saves new accountclass", %{conn: conn, user: user} do
      club = club_fixture()

      {:error, _} = live(conn, ~p"/clubs/#{club}/accountclasses/new")

      conn = conn |> log_in_user(user)
      {:ok, new_live, html} = live(conn, ~p"/clubs/#{club}/accountclasses/new")

      assert html =~ "Kontenklasse erstellen"

      assert new_live
             |> form("#accountclass-form", accountclass: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        new_live
        |> form("#accountclass-form", accountclass: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, ~p"/clubs/#{club}/accountclasses")

      assert html =~ "Kontenklasse erfolgreich erstellt"
      assert html =~ "some accountclassname"
    end

    test "cancels save new accountclass", %{conn: conn, user: user} do
      club = club_fixture()

      conn = conn |> log_in_user(user)
      {:ok, new_live, _html} = live(conn, ~p"/clubs/#{club}/accountclasses/new")

      {:ok, _, _html} =
        new_live
        |> element("#accountclass-form a", "Abbrechen")
        |> render_click()
        |> follow_redirect(conn, ~p"/clubs/#{club}/accountclasses")
    end

    test "updates accountclass", %{conn: conn, user: user, accountclass: accountclass} do
      {:error, _} = live(conn, ~p"/accountclasses/#{accountclass}/edit")

      conn = conn |> log_in_user(user)
      {:ok, edit_live, html} = live(conn, ~p"/accountclasses/#{accountclass}/edit")

      assert html =~ "Kontenklasse bearbeiten"

      assert edit_live
             |> form("#accountclass-form", accountclass: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        edit_live
        |> form("#accountclass-form", accountclass: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, ~p"/accountclasses/#{accountclass}")

      assert html =~ "Kontenklasse erfolgreich aktualisiert"
      assert html =~ "some updated accountclassname"
    end

    test "cancels updates accountclass", %{conn: conn, user: user, accountclass: accountclass} do
      conn = conn |> log_in_user(user)
      {:ok, edit_live, _html} = live(conn, ~p"/accountclasses/#{accountclass}/edit")

      {:ok, _, _html} =
        edit_live
        |> element("#accountclass-form a", "Abbrechen")
        |> render_click()
        |> follow_redirect(conn, ~p"/accountclasses/#{accountclass}")
    end

    test "deletes accountclass", %{conn: conn, user: user, accountclass: accountclass} do
      {:error, _} = live(conn, ~p"/accountclasses/#{accountclass}/edit")

      conn = conn |> log_in_user(user)
      {:ok, edit_live, html} = live(conn, ~p"/accountclasses/#{accountclass}/edit")
      assert html =~ "Default Class"

      {:ok, _, html} =
        edit_live
        |> element("#accountclass-form button", "Löschen")
        |> render_click()
        |> follow_redirect(conn, ~p"/clubs/#{accountclass.club_id}/accountclasses")

      assert html =~ "Kontenklasse erfolgreich gelöscht"
      assert html =~ "Kontenklassen"
      refute html =~ "Default Class"
    end

    test "shows error when deleting accountclass with assigned accounts", %{conn: conn, user: user, accountclass: accountclass} do
      _account = account_fixture(%{club_id: accountclass.club_id, accountclass_id: accountclass.id})

      conn = conn |> log_in_user(user)
      {:ok, edit_live, _html} = live(conn, ~p"/accountclasses/#{accountclass}/edit")

      html =
        edit_live
        |> element("#accountclass-form button", "Löschen")
        |> render_click()

      assert html =~ "kann nicht gelöscht werden"
    end
  end

  describe "Show" do
    setup [:create_accountclass]

    test "displays accountclass", %{conn: conn, user: user, accountclass: accountclass} do
      {:error, _} = live(conn, ~p"/accountclasses/#{accountclass}")

      conn = conn |> log_in_user(user)
      {:ok, _show_live, html} = live(conn, ~p"/accountclasses/#{accountclass}")

      assert html =~ "Kontenklasse"
      assert html =~ accountclass.accountclassname
    end
  end

end
