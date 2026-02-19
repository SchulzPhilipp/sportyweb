defmodule SportywebWeb.AccountgroupLiveTest do
  use SportywebWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Sportyweb.AccountingFixtures
  import Sportyweb.AccountsFixtures
  import Sportyweb.OrganizationFixtures
  import Sportyweb.RBAC.RoleFixtures
  import Sportyweb.RBAC.UserRoleFixtures

  @create_attrs %{accountgroupname: "some another accountgroupname"}
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

    test "lists all accountgroups", %{conn: conn, user: user, accountgroup: accountgroup} do
      {:error, _} = live(conn, ~p"/accountgroups")

      conn = conn |> log_in_user(user)

      {:ok, _index_live, html} = live(conn, ~p"/accountgroups")

      assert html =~ "Listing Accountgroups"
      assert html =~ accountgroup.accountgroupname
    end

    test "saves new accountgroup", %{conn: conn, user: user} do
      {:error, _} = live(conn, ~p"/accountgroups")

      conn = conn |> log_in_user(user)

      # accountclass = Sportyweb.AccountingFixtures.accountclass_fixture()
      # accounttype = Sportyweb.AccountingFixtures.accounttype_fixture()

      # valid_attrs =
      # @create_attrs
      # |> Map.put(:accountclass_id, accountclass.id)
      # |> Map.put(:accounttype_id, accounttype.id)

      {:ok, index_live, _html} = live(conn, ~p"/accountgroups")

      assert index_live |> element("a", "New Accountgroup") |> render_click() =~
               "New Accountgroup"

      assert_patch(index_live, ~p"/accountgroups/new")

      assert index_live
             |> form("#accountgroup-form", accountgroup: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#accountgroup-form", accountgroup: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/accountgroups")

      html = render(index_live)
      assert html =~ "Accountgroup created successfully"
      assert html =~ "some another accountgroupname"
    end

    test "updates accountgroup in listing", %{conn: conn, user: user, accountgroup: accountgroup} do
      {:error, _} = live(conn, ~p"/accountgroups")

      conn = conn |> log_in_user(user)

      {:ok, index_live, _html} = live(conn, ~p"/accountgroups")

      assert index_live
             |> element("#accountgroups-#{accountgroup.id} a", "Edit")
             |> render_click() =~
               "Edit Accountgroup"

      assert_patch(index_live, ~p"/accountgroups/#{accountgroup}/edit")

      assert index_live
             |> form("#accountgroup-form", accountgroup: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#accountgroup-form", accountgroup: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/accountgroups")

      html = render(index_live)
      assert html =~ "Accountgroup updated successfully"
      assert html =~ "some updated accountgroupname"
    end

    test "deletes accountgroup in listing", %{conn: conn, user: user, accountgroup: accountgroup} do
      {:error, _} = live(conn, ~p"/accountgroups")

      conn = conn |> log_in_user(user)

      {:ok, index_live, _html} = live(conn, ~p"/accountgroups")

      assert index_live
             |> element("#accountgroups-#{accountgroup.id} a", "Delete")
             |> render_click()

      refute has_element?(index_live, "#accountgroups-#{accountgroup.id}")
    end
  end

  describe "Show" do
    setup [:create_accountgroup]

    test "displays accountgroup", %{conn: conn, user: user, accountgroup: accountgroup} do
      {:error, _} = live(conn, ~p"/accountgroups/#{accountgroup}")

      conn = conn |> log_in_user(user)

      {:ok, _show_live, html} = live(conn, ~p"/accountgroups/#{accountgroup}")

      assert html =~ "Show Accountgroup"
      assert html =~ accountgroup.accountgroupname
    end

    test "updates accountgroup within modal", %{
      conn: conn,
      user: user,
      accountgroup: accountgroup
    } do
      {:error, _} = live(conn, ~p"/accountgroups/#{accountgroup}")

      conn = conn |> log_in_user(user)
      {:ok, show_live, _html} = live(conn, ~p"/accountgroups/#{accountgroup}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Accountgroup"

      assert_patch(show_live, ~p"/accountgroups/#{accountgroup}/show/edit")

      assert show_live
             |> form("#accountgroup-form", accountgroup: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#accountgroup-form", accountgroup: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/accountgroups/#{accountgroup}")

      html = render(show_live)
      assert html =~ "Accountgroup updated successfully"
      assert html =~ "some updated accountgroupname"
    end
  end
end
