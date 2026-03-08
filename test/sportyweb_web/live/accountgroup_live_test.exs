defmodule SportywebWeb.AccountgroupLiveTest do
  use SportywebWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Sportyweb.AccountingFixtures
  import Sportyweb.AccountsFixtures
  import Sportyweb.OrganizationFixtures
  import Sportyweb.RBAC.RoleFixtures
  import Sportyweb.RBAC.UserRoleFixtures

  @create_attrs %{accountgroupname: "Standard Gruppe"}
  @update_attrs %{accountgroupname: "some updated accountgroupname"}
  @invalid_attrs %{accountgroupname: nil}

  setup do
    user = user_fixture()
    applicationrole = application_role_fixture()
    user_application_role_fixture(%{user_id: user.id, applicationrole_id: applicationrole.id})

    %{user: user}
  end

  defp create_accountgroup(_) do
    accountgroup = accountgroup_fixture()
    %{accountgroup: accountgroup}
  end

  describe "Index" do
    setup [:create_accountgroup]

    test "lists all accountgroups - default redirect", %{conn: conn, user: user} do
      {:error, _} = live(conn, ~p"/accountgroups")

      conn = conn |> log_in_user(user)

      {:ok, conn} =
        conn
        |> live(~p"/accountgroups")
        |> follow_redirect(conn, ~p"/clubs")

      assert conn.resp_body =~ "Vereinsübersicht"
    end

    test "lists all accountgroups", %{conn: conn, user: user, accountgroup: accountgroup} do
      {:error, _} = live(conn, ~p"/clubs/#{accountgroup.club_id}/accountgroups")

      conn = conn |> log_in_user(user)

      {:ok, _index_live, html} = live(conn, ~p"/clubs/#{accountgroup.club_id}/accountgroups")

      assert html =~ "Kontengruppen"
      assert html =~ accountgroup.accountgroupname
    end
end

describe "New/Edit" do
    setup [:create_accountgroup]

    test "saves new accountgroup", %{conn: conn, user: user} do
      club = club_fixture()

      {:error, _} = live(conn, ~p"/clubs/#{club}/accountgroups/new")

      conn = conn |> log_in_user(user)
      {:ok, new_live, html} = live(conn, ~p"/clubs/#{club}/accountgroups/new")

      assert html =~ "Kontengruppe erstellen"

      assert new_live
             |> form("#accountgroup-form", accountgroup: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        new_live
        |> form("#accountgroup-form", accountgroup: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, ~p"/clubs/#{club}/accountgroups")

      assert html =~ "Kontengruppe erfolgreich erstellt"
      assert html =~ "Standard Gruppe"
    end

    test "cancels save new accountgroup", %{conn: conn, user: user} do
      club = club_fixture()

      conn = conn |> log_in_user(user)
      {:ok, new_live, _html} = live(conn, ~p"/clubs/#{club}/accountgroups/new")

      {:ok, _, _html} =
        new_live
        |> element("#accountgroup-form a", "Abbrechen")
        |> render_click()
        |> follow_redirect(conn, ~p"/clubs/#{club}/accountgroups")
    end

    test "updates accountgroup", %{conn: conn, user: user, accountgroup: accountgroup} do
      {:error, _} = live(conn, ~p"/accountgroups/#{accountgroup}/edit")

      conn = conn |> log_in_user(user)
      {:ok, edit_live, html} = live(conn, ~p"/accountgroups/#{accountgroup}/edit")

      assert html =~ "Kontengruppe bearbeiten"

      assert edit_live
             |> form("#accountgroup-form", accountgroup: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        edit_live
        |> form("#accountgroup-form", accountgroup: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, ~p"/accountgroups/#{accountgroup}")

      assert html =~ "Kontengruppe erfolgreich aktualisiert"
      assert html =~ "some updated accountgroupname"
    end

    test "cancels updates accountgroup", %{conn: conn, user: user, accountgroup: accountgroup} do
      conn = conn |> log_in_user(user)
      {:ok, edit_live, _html} = live(conn, ~p"/accountgroups/#{accountgroup}/edit")

      {:ok, _, _html} =
        edit_live
        |> element("#accountgroup-form a", "Abbrechen")
        |> render_click()
        |> follow_redirect(conn, ~p"/accountgroups/#{accountgroup}")
    end

    test "deletes accountgroup", %{conn: conn, user: user, accountgroup: accountgroup} do
      {:error, _} = live(conn, ~p"/accountgroups/#{accountgroup}/edit")

      conn = conn |> log_in_user(user)
      {:ok, edit_live, html} = live(conn, ~p"/accountgroups/#{accountgroup}/edit")
      assert html =~ "Standard Gruppe"

      {:ok, _, html} =
        edit_live
        |> element("#accountgroup-form button", "Löschen")
        |> render_click()
        |> follow_redirect(conn, ~p"/clubs/#{accountgroup.club_id}/accountgroups")

      assert html =~ "Kontengruppe erfolgreich gelöscht"
      assert html =~ "Kontengruppen"
      refute html =~ "Standard Gruppe"
    end
  end

  describe "Show" do
    setup [:create_accountgroup]

    test "displays accountgroup", %{conn: conn, user: user, accountgroup: accountgroup} do
      {:error, _} = live(conn, ~p"/accountgroups/#{accountgroup}")

      conn = conn |> log_in_user(user)
      {:ok, _show_live, html} = live(conn, ~p"/accountgroups/#{accountgroup}")

      assert html =~ "Kontengruppe anzeigen"
      assert html =~ accountgroup.accountgroupname
    end
  end

end
