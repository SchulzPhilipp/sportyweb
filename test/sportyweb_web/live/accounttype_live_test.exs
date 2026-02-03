defmodule SportywebWeb.AccounttypeLiveTest do
  use SportywebWeb.ConnCase

  import Phoenix.LiveViewTest
  import Sportyweb.AccountingFixtures
  import Sportyweb.AccountsFixtures
  import Sportyweb.OrganizationFixtures
  import Sportyweb.RBAC.RoleFixtures
  import Sportyweb.RBAC.UserRoleFixtures

  @create_attrs %{accounttypename: "some accounttypename"}
  @update_attrs %{accounttypename: "some updated accounttypename"}
  @invalid_attrs %{accounttypename: nil}

  setup do
    user = user_fixture()
    applicationrole = application_role_fixture()
    user_application_role_fixture(%{user_id: user.id, applicationrole_id: applicationrole.id})

    %{user: user}
  end

  defp create_accounttype(_) do
    accounttype = accounttype_fixture()
    %{accounttype: accounttype}
  end

  describe "Index" do
    setup [:create_accounttype]

    test "lists all accounttypes", %{conn: conn, user: user, accounttype: accounttype} do
      {:error, _} = live(conn, ~p"/accounttypes")

      conn = conn |> log_in_user(user)

      {:ok, _index_live, html} = live(conn, ~p"/accounttypes")

      assert html =~ "Listing Accounttypes"
      assert html =~ accounttype.accounttypename
    end

    test "saves new accounttype", %{conn: conn, user: user} do
      {:error, _} = live(conn, ~p"/accounttypes")

      conn = conn |> log_in_user(user)

      {:ok, index_live, _html} = live(conn, ~p"/accounttypes")

      assert index_live |> element("a", "New Accounttype") |> render_click() =~
               "New Accounttype"

      assert_patch(index_live, ~p"/accounttypes/new")

      assert index_live
             |> form("#accounttype-form", accounttype: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#accounttype-form", accounttype: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/accounttypes")

      html = render(index_live)
      assert html =~ "Accounttype created successfully"
      assert html =~ "some accounttypename"
    end

    test "updates accounttype in listing", %{conn: conn, user: user, accounttype: accounttype} do
      {:error, _} = live(conn, ~p"/accounttypes")

      conn = conn |> log_in_user(user)

      {:ok, index_live, _html} = live(conn, ~p"/accounttypes")

      assert index_live |> element("#accounttypes-#{accounttype.id} a", "Edit") |> render_click() =~
               "Edit Accounttype"

      assert_patch(index_live, ~p"/accounttypes/#{accounttype}/edit")

      assert index_live
             |> form("#accounttype-form", accounttype: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#accounttype-form", accounttype: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/accounttypes")

      html = render(index_live)
      assert html =~ "Accounttype updated successfully"
      assert html =~ "some updated accounttypename"
    end

    test "deletes accounttype in listing", %{conn: conn, user: user, accounttype: accounttype} do
      {:error, _} = live(conn, ~p"/accounttypes")

      conn = conn |> log_in_user(user)

      {:ok, index_live, _html} = live(conn, ~p"/accounttypes")

      assert index_live |> element("#accounttypes-#{accounttype.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#accounttypes-#{accounttype.id}")
    end
  end

  describe "Show" do
    setup [:create_accounttype]

    test "displays accounttype", %{conn: conn, user: user, accounttype: accounttype} do
      {:error, _} = live(conn, ~p"/accounttypes/#{accounttype}")

      conn = conn |> log_in_user(user)

      {:ok, _show_live, html} = live(conn, ~p"/accounttypes/#{accounttype}")

      assert html =~ "Show Accounttype"
      assert html =~ accounttype.accounttypename
    end

    test "updates accounttype within modal", %{conn: conn, user: user, accounttype: accounttype} do
      {:error, _} = live(conn, ~p"/accounttypes/#{accounttype}")

      conn = conn |> log_in_user(user)

      {:ok, show_live, _html} = live(conn, ~p"/accounttypes/#{accounttype}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Accounttype"

      assert_patch(show_live, ~p"/accounttypes/#{accounttype}/show/edit")

      assert show_live
             |> form("#accounttype-form", accounttype: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#accounttype-form", accounttype: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/accounttypes/#{accounttype}")

      html = render(show_live)
      assert html =~ "Accounttype updated successfully"
      assert html =~ "some updated accounttypename"
    end
  end
end
