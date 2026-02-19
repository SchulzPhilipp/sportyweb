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

    test "lists all accountclasses", %{conn: conn, user: user, accountclass: accountclass} do
      {:error, _} = live(conn, ~p"/accountclasses")

      conn = conn |> log_in_user(user)

      {:ok, _index_live, html} = live(conn, ~p"/accountclasses")

      assert html =~ "Listing Accountclasses"
      assert html =~ accountclass.accountclassnumber
    end

    test "saves new accountclass", %{conn: conn, user: user} do
      {:error, _} = live(conn, ~p"/accountclasses")

      conn = conn |> log_in_user(user)

      {:ok, index_live, _html} = live(conn, ~p"/accountclasses")

      assert index_live |> element("a", "New Accountclass") |> render_click() =~
               "New Accountclass"

      assert_patch(index_live, ~p"/accountclasses/new")

      assert index_live
             |> form("#accountclass-form", accountclass: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#accountclass-form", accountclass: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/accountclasses")

      html = render(index_live)
      assert html =~ "Accountclass created successfully"
      assert html =~ "some accountclassnumber"
    end

    test "updates accountclass in listing", %{conn: conn, user: user, accountclass: accountclass} do
      {:error, _} = live(conn, ~p"/accountclasses")

      conn = conn |> log_in_user(user)

      {:ok, index_live, _html} = live(conn, ~p"/accountclasses")

      assert index_live
             |> element("#accountclasses-#{accountclass.id} a", "Edit")
             |> render_click() =~
               "Edit Accountclass"

      assert_patch(index_live, ~p"/accountclasses/#{accountclass}/edit")

      assert index_live
             |> form("#accountclass-form", accountclass: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#accountclass-form", accountclass: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/accountclasses")

      html = render(index_live)
      assert html =~ "Accountclass updated successfully"
      assert html =~ "some updated accountclassnumber"
    end

    test "deletes accountclass in listing", %{conn: conn, user: user, accountclass: accountclass} do
      {:error, _} = live(conn, ~p"/accountclasses")

      conn = conn |> log_in_user(user)

      {:ok, index_live, _html} = live(conn, ~p"/accountclasses")

      assert index_live
             |> element("#accountclasses-#{accountclass.id} a", "Delete")
             |> render_click()

      refute has_element?(index_live, "#accountclasses-#{accountclass.id}")
    end
  end

  describe "Show" do
    setup [:create_accountclass]

    test "displays accountclass", %{conn: conn, user: user, accountclass: accountclass} do
      {:error, _} = live(conn, ~p"/accountclasses/#{accountclass}")

      conn = conn |> log_in_user(user)

      {:ok, _show_live, html} = live(conn, ~p"/accountclasses/#{accountclass}")

      assert html =~ "Show Accountclass"
      assert html =~ accountclass.accountclassnumber
    end

    test "updates accountclass within modal", %{
      conn: conn,
      user: user,
      accountclass: accountclass
    } do
      {:error, _} = live(conn, ~p"/accountclasses/#{accountclass}")

      conn = conn |> log_in_user(user)

      {:ok, show_live, _html} = live(conn, ~p"/accountclasses/#{accountclass}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Accountclass"

      assert_patch(show_live, ~p"/accountclasses/#{accountclass}/show/edit")

      assert show_live
             |> form("#accountclass-form", accountclass: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#accountclass-form", accountclass: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/accountclasses/#{accountclass}")

      html = render(show_live)
      assert html =~ "Accountclass updated successfully"
      assert html =~ "some updated accountclassnumber"
    end
  end
end
