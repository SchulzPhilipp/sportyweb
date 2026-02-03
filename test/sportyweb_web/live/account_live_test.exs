defmodule SportywebWeb.AccountLiveTest do
  use SportywebWeb.ConnCase

  import Phoenix.LiveViewTest
  import Sportyweb.AccountingFixtures
  import Sportyweb.AccountsFixtures
  import Sportyweb.OrganizationFixtures
  import Sportyweb.RBAC.RoleFixtures
  import Sportyweb.RBAC.UserRoleFixtures

  @create_attrs %{accountnumber: "0815", accountname: "some accountname", accountbalance: "120.00"}
  @update_attrs %{accountnumber: "0816", accountname: "some updated accountname", accountbalance: "456.00"}
  @invalid_attrs %{accountnumber: nil, accountname: nil, accountbalance: nil, accountclass_id: nil, accountgroup_id: nil, accounttype_id: nil}

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

    test "lists all accounts", %{conn: conn, user: user, account: account} do
      {:error, _} = live(conn, ~p"/accounts")

      conn = conn |> log_in_user(user)

      {:ok, _index_live, html} = live(conn, ~p"/accounts")

      assert html =~ "Listing Accounts"
      assert html =~ account.accountnumber
    end

    test "saves new account", %{conn: conn, user: user} do
      {:error, _} = live(conn, ~p"/accounts")

      conn = conn |> log_in_user(user)

      #create references
      accountclass = Sportyweb.AccountingFixtures.accountclass_fixture()
      accountgroup = Sportyweb.AccountingFixtures.accountgroup_fixture()
      accounttype = Sportyweb.AccountingFixtures.accounttype_fixture()

      valid_attrs =
      @create_attrs
      |> Map.put(:accountclass_id, accountclass.id)
      |> Map.put(:accountgroup_id, accountgroup.id)
      |> Map.put(:accounttype_id, accounttype.id)

      {:ok, index_live, _html} = live(conn, ~p"/accounts")

      assert index_live |> element("a", "New Account") |> render_click() =~
               "New Account"

      assert_patch(index_live, ~p"/accounts/new")

      assert index_live
             |> form("#account-form", account: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

       assert index_live
             |> form("#account-form", account: valid_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/accounts")

      html = render(index_live)
      assert html =~ "Account created successfully"
      assert html =~ "0815"
    end

    test "updates account in listing", %{conn: conn, user: user, account: account} do
      {:error, _} = live(conn, ~p"/accounts")

      conn = conn |> log_in_user(user)

      #create references
      accountclass = Sportyweb.AccountingFixtures.accountclass_fixture()
      accountgroup = Sportyweb.AccountingFixtures.accountgroup_fixture()
      accounttype = Sportyweb.AccountingFixtures.accounttype_fixture()

      valid_attrs =
      @update_attrs
      |> Map.put(:accountclass_id, accountclass.id)
      |> Map.put(:accountgroup_id, accountgroup.id)
      |> Map.put(:accounttype_id, accounttype.id)

      {:ok, index_live, _html} = live(conn, ~p"/accounts")

      assert index_live |> element("#accounts-#{account.id} a", "Edit") |> render_click() =~
               "Edit Account"

      assert_patch(index_live, ~p"/accounts/#{account}/edit")

      assert index_live
             |> form("#account-form", account: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
            |> form("#account-form", account: valid_attrs)
            |> render_submit()


      assert_patch(index_live, ~p"/accounts")
      html = render(index_live)
      assert html =~ "Account updated successfully"
      assert html =~ "0816"

    end

    test "deletes account in listing", %{conn: conn, user: user, account: account} do
      {:error, _} = live(conn, ~p"/accounts")

      conn = conn |> log_in_user(user)

      {:ok, index_live, _html} = live(conn, ~p"/accounts")

      assert index_live |> element("#accounts-#{account.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#accounts-#{account.id}")
    end
  end

  describe "Show" do
    setup [:create_account]

    test "displays account", %{conn: conn, user: user, account: account} do
      {:error, _} = live(conn, ~p"/accounts/#{account}")

      conn = conn |> log_in_user(user)

      {:ok, _show_live, html} = live(conn, ~p"/accounts/#{account}")

      assert html =~ "Show Account"
      assert html =~ account.accountnumber
    end

    test "updates account within modal", %{conn: conn, user: user, account: account} do
      {:error, _} = live(conn, ~p"/accounts/#{account}")

      conn = conn |> log_in_user(user)

      #create references
      accountclass = Sportyweb.AccountingFixtures.accountclass_fixture()
      accountgroup = Sportyweb.AccountingFixtures.accountgroup_fixture()
      accounttype = Sportyweb.AccountingFixtures.accounttype_fixture()

      valid_attrs =
      @update_attrs
      |> Map.put(:accountclass_id, accountclass.id)
      |> Map.put(:accountgroup_id, accountgroup.id)
      |> Map.put(:accounttype_id, accounttype.id)

      {:ok, show_live, _html} = live(conn, ~p"/accounts/#{account}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Account"

      assert_patch(show_live, ~p"/accounts/#{account}/show/edit")

      assert show_live
             |> form("#account-form", account: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#account-form", account: valid_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/accounts/#{account}")

      html = render(show_live)
      assert html =~ "Account updated successfully"
      assert html =~ "0816"
    end
  end
end
