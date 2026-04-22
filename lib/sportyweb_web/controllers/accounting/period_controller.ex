defmodule SportywebWeb.Accounting.PeriodController do
  use SportywebWeb, :controller

  @doc """
  Stores the selected accounting period in the session and redirects the user
  back to the page they came from.

  Both `active_period_id` and `active_period_club_id` are written to the
  session so that `CommonHelper.on_mount/4` can validate that the stored
  period belongs to the club currently being viewed. If no referer header is
  present (e.g. direct API call or browser privacy settings), the user is
  redirected to the club's journal as a safe default.

  Only the path component of the referer URL is used for the redirect to
  avoid open redirect vulnerabilities from externally controlled header values.
  """
  def activate(conn, %{"club_id" => club_id, "period_id" => period_id}) do
    referer =
      conn
      |> get_req_header("referer")
      |> List.first()
      |> case do
        nil -> "/clubs/#{club_id}/journal"
        # Extract only the path to prevent redirecting to an external domain
        # if the referer header has been tampered with.
        url ->
          uri = URI.parse(url)
          uri.path
      end

    conn
    |> put_session(:active_period_id, period_id)
    |> put_session(:active_period_club_id, club_id)
    |> redirect(to: referer)
  end
end
