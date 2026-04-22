defmodule SportywebWeb.CommonHelper do
  import Phoenix.Component

  alias Sportyweb.Accounting

  def format_boolean_field(field) do
    if !is_nil(field) && field do
      "Ja"
    else
      "Nein"
    end
  end

  def format_integer_field(field) do
    if !is_nil(field) && field do
      field
    else
      "-"
    end
  end

  def format_string_field(field) do
    if !is_nil(field) && is_binary(field) && String.trim(field) != "" do
      field
    else
      "-"
    end
  end

  @doc """
  Takes a date and returns a string that is formated as "day.month.year".
  If the date is nil, the function returns a string containg a hyphen.

  ## Examples

      iex> format_date_field_dmy(Date.utc_today())
      "01.01.2023"

      iex> format_date_field_dmy(nil)
      "-"

  """
  def format_date_field_dmy(date) do
    if !is_nil(date) && date do
      Calendar.strftime(date, "%d.%m.%Y")
    else
      "-"
    end
  end

  @doc """
  Takes a list of structs and returns a comma separated list of one attribute.
  If the list is empty, the function returns a string containg a hyphen.

  ## Examples

      iex> format_struct_list([%Club{name: "FCB"}, %Club{name: "FCN"}], :name)
      "FCB, FCN"

      iex> format_struct_list([], :name)
      "-"

  """
  def format_struct_list(list, attribute) do
    csv =
      list
      |> Enum.filter(fn element ->
        value = Map.get(element, attribute)
        !is_nil(value) && value != ""
      end)
      |> Enum.map_join(", ", fn element -> Map.get(element, attribute) end)

    if String.trim(csv) != "" do
      csv
    else
      "-"
    end
  end

  @doc """
  Takes a list of key-value lists and returns the correct key (usually a string) for the given value.
  If the value can't be found, the function returns a string containg a hyphen.

  ## Examples

      iex> get_key_for_value(Contact.get_valid_genders, "female")
      "Weiblich"

      iex> format_struct_list(Contact.get_valid_genders, "kangaroo")
      "-"

  """
  def get_key_for_value(data, value) do
    case Enum.find(data, fn element -> element[:value] == value end) do
      [{:key, key} | _] -> key
      _ -> "-"
    end
  end

  def on_mount(:load_active_period, %{"club_id" => club_id}, session, socket) do
    active_period_id = Map.get(session, "active_period_id")
    active_period_club_id = Map.get(session, "active_period_club_id")

    # The session-stored period is only reused if it belongs to the club being
    # viewed. If the user navigates to a different club, the session period is
    # stale and the newest open period for the new club is used instead.
    active_period =
      if active_period_id && active_period_club_id == club_id do
        active_period_id
        |> Accounting.get_accounting_period!()
        |> then(fn
          # The stored period may have been closed or deleted since it was
          # saved to the session; fall back to the newest open one in that case.
          nil -> Accounting.get_newest_open_period(club_id)
          period -> period
        end)
      else
        Accounting.get_newest_open_period(club_id)
      end

    all_periods = Accounting.list_accounting_periods(club_id)

    # Determine the position of the active period in the full list so the
    # PeriodNavigatorComponent can render prev/next navigation correctly.
    # Defaults to index 0 if the active period is not found (e.g. nil period).
    current_index =
      if active_period do
        Enum.find_index(all_periods, &(&1.id == active_period.id)) || 0
      else
        0
      end

    {:cont,
    socket
    |> assign(:active_period, active_period)
    |> assign(:all_periods, all_periods)
    |> assign(:period_index, current_index)}
  end

  # Fallback clause for routes without a club_id (e.g. global or admin routes).
  # Period navigation is not available here, so all_periods and period_index
  # are set to safe empty defaults.
  def on_mount(:load_active_period, _params, session, socket) do
    active_period_id = Map.get(session, "active_period_id")

    active_period =
      if active_period_id do
        Accounting.get_accounting_period!(active_period_id)
      end

    {:cont,
    socket
    |> assign(:active_period, active_period)
    |> assign(:all_periods, [])
    |> assign(:period_index, 0)}
  end


end
