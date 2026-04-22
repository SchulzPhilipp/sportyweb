defmodule SportywebWeb.Accounting.AccountingPeriodLiveTest do
  use SportywebWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Sportyweb.AccountingFixtures
  import Sportyweb.AccountsFixtures
  import Sportyweb.OrganizationFixtures
  import Sportyweb.RBAC.RoleFixtures
  import Sportyweb.RBAC.UserRoleFixtures

  @create_attrs %{
    name: "2026",
    status: "open",
    starts_on: ~D[2026-01-01],
    ends_on: ~D[2026-12-31],
  }
  @update_attrs %{
    name: "2027",
    status: "open",
    starts_on: ~D[2027-01-01],
    ends_on: ~D[2027-12-31],
  }
  @invalid_attrs %{
    name: nil,
    status: nil,
    starts_on: nil,
    ends_on: nil,
  }

  setup do
    user = user_fixture()
    applicationrole = application_role_fixture()
    user_application_role_fixture(%{user_id: user.id, applicationrole_id: applicationrole.id})

    %{user: user}
  end

  defp create_accounting_period(_) do
    accounting_period = accounting_period_fixture()
    %{accounting_period: accounting_period}
  end

  describe "Index" do
    setup [:create_accounting_period]

    test "lists all accounts - default redirect", %{conn: conn, user: user} do
      {:error, _} = live(conn, ~p"/accounting_periods")

      conn = conn |> log_in_user(user)

      {:ok, _conn} =
        conn
        |> live(~p"/accounting_periods")
        |> follow_redirect(conn, ~p"/clubs")
    end

    test "lists all accounting_periods", %{conn: conn, user: user, accounting_period: accounting_period} do
      {:error, _} = live(conn, ~p"/clubs/#{accounting_period.club_id}/accounting_periods")

      conn = conn |> log_in_user(user)
      {:ok, _index_live, html} = live(conn, ~p"/clubs/#{accounting_period.club_id}/accounting_periods")

      assert html =~ "Buchungsperioden"
      assert html =~ accounting_period.name
    end
  end

  describe "New/Edit" do
    setup [:create_accounting_period]

    test "saves new accounting_period", %{conn: conn, user: user} do
      club = club_fixture()

      {:error, _} = live(conn, ~p"/clubs/#{club}/accounting_periods/new")

      conn = conn |> log_in_user(user)

      {:ok, new_live, html} = live(conn, ~p"/clubs/#{club}/accounting_periods/new")

      assert html =~ "Buchungsperiode erstellen"

      valid_attrs =
        @create_attrs
        |> Map.put(:club_id, club.id)

      assert new_live
        |> form("#accounting_period-form", accounting_period: Map.put(@invalid_attrs, :club_id, club.id))
        |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        new_live
        |> form("#accounting_period-form", accounting_period: valid_attrs)
        |> render_submit()
        |> follow_redirect(conn, ~p"/clubs/#{club}/accounting_periods")

      assert html =~ "Buchungsperiode erfolgreich erstellt"
      assert html =~ "2026"
    end

    test "cancels save new accounting_period", %{conn: conn, user: user} do
      club = club_fixture()

      conn = conn |> log_in_user(user)
      {:ok, new_live, _html} = live(conn, ~p"/clubs/#{club}/accounting_periods/new")

      {:ok, _, _html} =
        new_live
        |> element("#accounting_period-form a", "Abbrechen")
        |> render_click()
        |> follow_redirect(conn, ~p"/clubs/#{club}/accounting_periods")
    end

    test "updates accounting_period", %{conn: conn, user: user, accounting_period: accounting_period} do

      {:error, _} = live(conn, ~p"/accounting_periods/#{accounting_period}/edit")

      conn = conn |> log_in_user(user)

      {:ok, edit_live, html} = live(conn, ~p"/accounting_periods/#{accounting_period}/edit")

      assert html =~ "Buchungsperiode bearbeiten"

      valid_attrs =
        @update_attrs
        |> Map.put(:club_id, accounting_period.club_id)

        assert edit_live
          |> form("#accounting_period-form", accounting_period: Map.put(@invalid_attrs, :club_id, accounting_period.club_id))
          |> render_change() =~ "can&#39;t be blank"

      {:ok, _edit_live, html} =
        edit_live
        |> form("#accounting_period-form", accounting_period: valid_attrs)
        |> render_submit()
        |> follow_redirect(conn, ~p"/accounting_periods/#{accounting_period}")

      assert html =~ "Buchungsperiode erfolgreich aktualisiert"
      assert html =~ "2027"
    end

    test "cancels updates accounting period", %{conn: conn, user: user, accounting_period: accounting_period} do
      conn = conn |> log_in_user(user)
      {:ok, edit_live, _html} = live(conn, ~p"/accounting_periods/#{accounting_period}/edit")

      {:ok, _, _html} =
        edit_live
        |> element("#accounting_period-form a", "Abbrechen")
        |> render_click()
        |> follow_redirect(conn, ~p"/accounting_periods/#{accounting_period}")
    end

    test "deletes accounting_period", %{conn: conn, user: user, accounting_period: accounting_period} do
      {:error, _} = live(conn, ~p"/accounting_periods/#{accounting_period}/edit")

      conn = conn |> log_in_user(user)
      {:ok, edit_live, html} = live(conn, ~p"/accounting_periods/#{accounting_period}/edit")
      assert html =~ "2026"

      {:ok, _, html} =
        edit_live
        |> element("#accounting_period-form button", "Löschen")
        |> render_click()
        |> follow_redirect(conn, ~p"/clubs/#{accounting_period.club_id}/accounting_periods")

      assert html =~ "Buchungsperiode erfolgreich gelöscht"
      assert html =~ "Buchungsperioden"
      refute html =~ "2026"
    end
  end

  describe "Show" do
    setup [:create_accounting_period]

    test "displays accounting_period", %{conn: conn, user: user, accounting_period: accounting_period} do
      {:error, _} = live(conn, ~p"/accounting_periods/#{accounting_period}")

      conn = conn |> log_in_user(user)
      {:ok, _show_live, html} = live(conn, ~p"/accounting_periods/#{accounting_period}")

      assert html =~ "Buchungsperiode"
      assert html =~ accounting_period.name
    end

  end
end
