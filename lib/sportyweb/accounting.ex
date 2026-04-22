defmodule Sportyweb.Accounting do
  @moduledoc """
  The Accounting context.
  """

  import Ecto.Query, warn: false
  alias Sportyweb.Repo

  alias Sportyweb.Accounting.Transaction
  alias Sportyweb.Finance.Fee
  alias Sportyweb.Finance.Subsidy
  alias Sportyweb.Legal
  alias Sportyweb.Legal.Contract
  alias Sportyweb.Polymorphic.InternalEvent
  alias Sportyweb.Accounting.Account
  alias Sportyweb.Accounting.Accountclass
  alias Sportyweb.Accounting.Accountgroup

  @doc """
  Returns a clubs list of transactions.

  ## Examples

      iex> list_transactions(1)
      [%Transaction{}, ...]

  """
  def list_transactions(club_id) do
    query =
      from(
        t in Transaction,
        join: contract in assoc(t, :contract),
        join: contact in assoc(contract, :contact),
        join: club in assoc(contract, :club),
        where: club.id == ^club_id,
        order_by: [t.creation_date, t.name, contact.name]
      )

    Repo.all(query)
  end

  @doc """
  Returns a clubs list of transactions. Preloads associations.

  ## Examples

      iex> list_transactions(1, [:contract])
      [%Transaction{}, ...]

  """
  def list_transactions(club_id, preloads) do
    Repo.preload(list_transactions(club_id), preloads)
  end

  @doc """
  Gets a single transaction.

  Raises `Ecto.NoResultsError` if the Transaction does not exist.

  ## Examples

      iex> get_transaction!(123)
      %Transaction{}

      iex> get_transaction!(456)
      ** (Ecto.NoResultsError)

  """
  def get_transaction!(id), do: Repo.get!(Transaction, id)

  @doc """
  Gets a single transaction. Preloads associations.

  Raises `Ecto.NoResultsError` if the Transaction does not exist.

  ## Examples

      iex> get_transaction!(123, [:club])
      %Transaction{}

      iex> get_transaction!(456, [:club])
      ** (Ecto.NoResultsError)

  """
  def get_transaction!(id, preloads) do
    Transaction
    |> Repo.get!(id)
    |> Repo.preload(preloads)
  end

  @doc """
  Creates a transaction.

  ## Examples

      iex> create_transaction(%{field: value})
      {:ok, %Transaction{}}

      iex> create_transaction(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_transaction(attrs \\ %{}) do
    %Transaction{}
    |> Transaction.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a transaction.

  ## Examples

      iex> update_transaction(transaction, %{field: new_value})
      {:ok, %Transaction{}}

      iex> update_transaction(transaction, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_transaction(%Transaction{} = transaction, attrs) do
    transaction
    |> Transaction.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a transaction.

  ## Examples

      iex> delete_transaction(transaction)
      {:ok, %Transaction{}}

      iex> delete_transaction(transaction)
      {:error, %Ecto.Changeset{}}

  """
  def delete_transaction(%Transaction{} = transaction) do
    Repo.delete(transaction)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking transaction changes.

  ## Examples

      iex> change_transaction(transaction)
      %Ecto.Changeset{data: %Transaction{}}

  """
  def change_transaction(%Transaction{} = transaction, attrs \\ %{}) do
    Transaction.changeset(transaction, attrs)
  end

  @doc """
  Returns a tuple, consisting of a list of transaction data and the calculated sum of their amounts.
  """
  def forecast_transactions(
        type,
        [%Contract{} | _] = contracts,
        %Date{} = start_date,
        %Date{} = end_date
      ) do
    calculate_transactions_data(type, contracts, start_date, end_date)
  end

  # Fallback, when there is no list of contracts.
  def forecast_transactions(:fee, _, %Date{} = _start_date, %Date{} = _end_date) do
    {[], Money.new(:EUR, 0)}
  end

  def create_todays_transactions() do
    today = Date.utc_today()
    create_transactions(:fee, today)
    create_transactions(:subsidy, today)
  end

  @doc """
  Creates transactions (in the datase), based on a list of transaction data.
  Returns a tuple consisting of a list of transaction data and the calculated sum of their amounts.
  """
  def create_transactions(type, %Date{} = date) do
    # Make sure all referenced fees are update to date, regarding the ages of contacts.
    Sportyweb.Legal.update_contract_fees_for_aged_contacts()

    contracts =
      Legal.list_all_contracts([:contact, fee: [:internal_events, subsidy: :internal_events]])

    {transactions, transactions_amount_sum} =
      calculate_transactions_data(type, contracts, date, date)

    # Create a transaction (that is persistet in the database) with the generated transactions data.
    Enum.each(transactions, fn transaction ->
      create_transaction(transaction)

      # Update the contract to never calculate the amount_one_time of a referenced fee again.
      if is_nil(transaction.contract.first_billing_date) do
        Legal.update_contract(transaction.contract, %{first_billing_date: date})
      end
    end)

    {transactions, transactions_amount_sum}
  end

  # Returns a tuple consisting of a list of transaction data and the calculated sum of their amounts.
  defp calculate_transactions_data(
         type,
         [%Contract{} | _] = contracts,
         %Date{} = start_date,
         %Date{} = end_date
       ) do
    # Iterate over all days from start to end. It's possible that start_date == end_date.
    date_range = Date.range(start_date, end_date)

    # Calculating the occurrence_dates for each fee or subsidy and for the entire range of dates from start to end
    # only once via this function call and passing the result as a parameter to all subsequent functions, is much
    # faster than doing this calculation for every fee or subsidy and every day over and over again!
    occurrence_dates = calculate_occurrence_dates(type, contracts, start_date, end_date)

    transactions =
      date_range
      |> Enum.map(fn date ->
        calculate_transactions_data(type, contracts, occurrence_dates, date)
      end)
      |> List.flatten()

    filtered_transactions = remove_duplicate_one_time_transactions(transactions)
    filtered_transactions_amount_sum = calculate_transactions_amount_sum(transactions)
    {filtered_transactions, filtered_transactions_amount_sum}
  end

  # Calculates and returns a list of transaction data for fees of contracts for a certain date.
  defp calculate_transactions_data(
         :fee,
         [%Contract{} | _] = contracts,
         %{} = fees_occurrence_dates,
         %Date{} = date
       ) do
    contracts
    |> Enum.filter(fn contract ->
      if Contract.is_in_use?(contract, date) && Fee.is_in_use?(contract.fee, date) do
        Enum.any?(fees_occurrence_dates[contract.fee.id], fn occurrence_date ->
          Date.compare(date, occurrence_date) == :eq
        end)
      end
    end)
    |> Enum.map(fn contract ->
      # "Default" transaction for the base amount of the fee.
      transactions = [
        %{
          id: nil,
          contract_id: contract.id,
          contract: contract,
          name: "Gebühr: #{contract.fee.name} - Grundbetrag",
          amount: contract.fee.amount,
          creation_date: date,
          is_one_time: false
        }
      ]

      # Possible additional transaction for the one-time amount of the fee.
      if is_nil(contract.first_billing_date) do
        transaction = [
          %{
            id: nil,
            contract_id: contract.id,
            contract: contract,
            name: "Gebühr: #{contract.fee.name} - Einmalzahlung",
            amount: contract.fee.amount_one_time,
            creation_date: date,
            is_one_time: true
          }
        ]

        transactions ++ transaction
      else
        transactions
      end
    end)
  end

  # Calculates and returns a list of transaction data for subsides of contracts for a certain date.
  defp calculate_transactions_data(
         :subsidy,
         [%Contract{} | _] = contracts,
         %{} = subsidies_occurrence_dates,
         %Date{} = date
       ) do
    contracts
    |> Enum.filter(fn contract ->
      fee = contract.fee
      subsidy = fee.subsidy

      if subsidy && Contract.is_in_use?(contract, date) && Fee.is_in_use?(fee, date) &&
           Subsidy.is_in_use?(subsidy, date) do
        Enum.any?(subsidies_occurrence_dates[contract.fee.subsidy.id], fn occurrence_date ->
          Date.compare(date, occurrence_date) == :eq
        end)
      end
    end)
    |> Enum.map(fn contract ->
      %{
        id: nil,
        contract_id: contract.id,
        contract: contract,
        name: "Zuschuss: #{contract.fee.subsidy.name}",
        amount: contract.fee.subsidy.amount,
        creation_date: date,
        is_one_time: false
      }
    end)
  end

  # The calculate_transactions_data function might return multiple transactions based on the amount_one_time of a fee.
  # This is due to contract.first_billing_date (still) being nil - the contract has not yet been used for the creation
  # of any transactions. Then, the calculate_transactions_data function creates (on purpose, because the function is not
  # supposed to alter the contract!) multiple transactions which have to be reduced to just on with the following function.
  defp remove_duplicate_one_time_transactions(transactions) do
    filtered_transactions =
      Enum.reduce(transactions, {[], MapSet.new()}, fn transaction,
                                                       {filtered_transactions, seen_contract_ids} ->
        case transaction do
          %{is_one_time: true, contract_id: contract_id} ->
            if MapSet.member?(seen_contract_ids, contract_id) do
              {filtered_transactions, seen_contract_ids}
            else
              {filtered_transactions ++ [transaction], MapSet.put(seen_contract_ids, contract_id)}
            end

          %{is_one_time: false} ->
            {filtered_transactions ++ [transaction], seen_contract_ids}

          _ ->
            {filtered_transactions, seen_contract_ids}
        end
      end)

    filtered_transactions |> elem(0)
  end

  defp calculate_transactions_amount_sum(transactions) do
    Enum.reduce(transactions, Money.new(:EUR, 0), fn transaction, acc ->
      Money.add!(acc, transaction.amount)
    end)
  end

  # Calculates and returns a list of occurrences (dates) for fees of contracts in a range from start_date to end_date.
  defp calculate_occurrence_dates(
         :fee,
         [%Contract{} | _] = contracts,
         %Date{} = start_date,
         %Date{} = end_date
       ) do
    # Get a list of all fees, some of them might be used by multiple contracts.
    fees = Enum.map(contracts, fn contract -> contract.fee end)
    # Filter out possible duplicates.
    unique_fees = Enum.uniq_by(fees, fn fee -> fee.id end)

    # Create a map that has fee ids as keys and the list of occurrence_dates for each of those fees as value.
    unique_fees
    |> Enum.map(fn fee ->
      # There must be an internal event, let it fail otherwise!
      internal_event = Enum.at(fee.internal_events, 0)
      occurrence_dates = calculate_occurrence_dates(internal_event, start_date, end_date)
      {fee.id, occurrence_dates}
    end)
    |> Enum.into(%{})
  end

  # Calculates and returns a list of occurrences (dates) for subsidies of contracts in a range from start_date to end_date.
  defp calculate_occurrence_dates(
         :subsidy,
         [%Contract{} | _] = contracts,
         %Date{} = start_date,
         %Date{} = end_date
       ) do
    # Get a list of all subsidies, some of them might be nil or used by multiple contracts (via fees).
    subsidies =
      contracts
      # Filter out nil.
      |> Enum.filter(fn contract -> contract.fee.subsidy end)
      |> Enum.map(fn contract -> contract.fee.subsidy end)

    # Filter out possible duplicates.
    unique_subsidies = Enum.uniq_by(subsidies, fn subsidy -> subsidy.id end)

    # Create a map that has subsidy ids as keys and the list of occurrence_dates for each of those subsidies as value.
    unique_subsidies
    |> Enum.map(fn subsidy ->
      # There must be an internal event, let it fail otherwise!
      internal_event = Enum.at(subsidy.internal_events, 0)
      occurrence_dates = calculate_occurrence_dates(internal_event, start_date, end_date)
      {subsidy.id, occurrence_dates}
    end)
    |> Enum.into(%{})
  end

  # Calculates and returns a list of occurrences (dates) in a range from start_date to end_date
  # based on the data of an internal_event.
  defp calculate_occurrence_dates(
         %InternalEvent{} = internal_event,
         %Date{} = start_date,
         %Date{} = end_date
       ) do
    # "Cocktail", the date recurrence library in use doesn't natively support a yearly frequency.
    # Therefore, the interval might have to be converted from year to month via a multiplication by 12.
    interval =
      case internal_event.frequency do
        "month" -> internal_event.interval
        "year" -> internal_event.interval * 12
      end

    # The commission_date of the interal_event is the starting point for all subsequent recurring dates.
    # It has to be converted to NaiveDateTime because "Cocktail" requires it.
    time = ~T[00:00:00.000000]
    {:ok, commission_datetime} = NaiveDateTime.new(internal_event.commission_date, time)

    # To keep things fast, the generation/calculation of recurring dates should be limited to a minimum.
    # This can be achieved by setting the until_datetime based on different criteria/conditions.
    until_datetime =
      if internal_event.is_recurring do
        if internal_event.archive_date do
          day_before_archive_date = Date.add(internal_event.archive_date, -1)
          {:ok, until_datetime} = NaiveDateTime.new(day_before_archive_date, time)
          until_datetime
        else
          {:ok, end_datetime} = NaiveDateTime.new(end_date, time)
          end_datetime
        end
      else
        commission_datetime
      end

    # Calculate the occurrences of the recurring dates with "Cocktail".
    schedule = Cocktail.Schedule.new(commission_datetime)

    schedule =
      Cocktail.Schedule.add_recurrence_rule(schedule, :monthly,
        interval: interval,
        until: until_datetime
      )

    occurrences_stream = Cocktail.Schedule.occurrences(schedule)

    # Convert the occurrences to Date and filter them, so they only include dates in the range from start_date to end_date.
    # Convert the stream to a list at the end, to make it easier to work with.
    occurrences_stream
    |> Stream.map(&NaiveDateTime.to_date/1)
    |> Stream.filter(fn date ->
      Date.compare(date, start_date) != :lt && Date.compare(date, end_date) != :gt
    end)
    |> Enum.to_list()
  end

  alias Sportyweb.Accounting.Account

  @doc """
  Returns all accounts for a club, ordered by account number.

  Preloads `:accountclass` and `:accountgroup` by default. Pass a custom
  `preloads` list to override. The `opts` parameter is reserved for future
  filtering options.

  ## Examples

      iex> list_accounts(club_id)
      [%Account{}, ...]

      iex> list_accounts(club_id, [:accountclass])
      [%Account{}, ...]

  """
  def list_accounts(club_id, preloads \\ [:accountclass, :accountgroup]) do
      Account
      |> where([a], a.club_id == ^club_id)
      # Sort by account number at the database level to avoid in-memory sorting.
      |> order_by([a], asc: a.accountnumber)
      |> Repo.all()
      |> Repo.preload(preloads)
  end

  @doc """
  Gets a single account by ID. Preloads associations.

  Raises `Ecto.NoResultsError` if the Account does not exist.

  ## Examples

      iex> get_account!(123)
      %Account{}

      iex> get_account!(456)
      ** (Ecto.NoResultsError)

  """
  def get_account!(id, preloads \\ [:club, :accountclass, :accountgroup]) do
      Account
      |> Repo.get!(id)
      |> Repo.preload(preloads)
  end

  @doc """
  Creates an account.

  ## Examples

      iex> create_account(%{field: value})
      {:ok, %Account{}}

      iex> create_account(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_account(attrs \\ %{}) do
    %Account{}
    |> Account.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an account.

  ## Examples

      iex> update_account(account, %{field: new_value})
      {:ok, %Account{}}

      iex> update_account(account, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_account(%Account{} = account, attrs) do
    account
    |> Account.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an account.

  ## Examples

      iex> delete_account(account)
      {:ok, %Account{}}

      iex> delete_account(account)
      {:error, %Ecto.Changeset{}}

  """
  def delete_account(%Account{} = account) do
    Repo.delete(account)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking account changes.

  ## Examples

      iex> change_account(account)
      %Ecto.Changeset{data: %Account{}}

  """
  def change_account(%Account{} = account, attrs \\ %{}) do
    Account.changeset(account, attrs)
  end

  alias Sportyweb.Accounting.Accountclass

  @doc """
  Returns all account classes for a club, ordered by class number.

  ## Examples

      iex> list_accountclasses(club_id)
      [%Accountclass{}, ...]

  """
  def list_accountclasses(club_id, preloads \\ [:club]) do
    Accountclass
    |> where([a], a.club_id == ^club_id)
    |> order_by([a], a.accountclassnumber)
    |> Repo.all()
    |> Repo.preload(preloads)
  end

  @doc """
  Gets a single account class by ID. Preloads associations.

  Raises `Ecto.NoResultsError` if the Accountclass does not exist.

  ## Examples

      iex> get_accountclass!(123)
      %Accountclass{}

      iex> get_accountclass!(456)
      ** (Ecto.NoResultsError)

  """
  def get_accountclass!(id, preloads \\ [:club]) do
    Accountclass
    |> Repo.get!(id)
    |> Repo.preload(preloads)
  end

  @doc """
  Creates an accountclass.

  ## Examples

      iex> create_accountclass(%{field: value})
      {:ok, %Accountclass{}}

      iex> create_accountclass(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_accountclass(attrs \\ %{}) do
    %Accountclass{}
    |> Accountclass.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an accountclass.

  ## Examples

      iex> update_accountclass(accountclass, %{field: new_value})
      {:ok, %Accountclass{}}

      iex> update_accountclass(accountclass, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_accountclass(%Accountclass{} = accountclass, attrs) do
    accountclass
    |> Accountclass.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an accountclass.

  ## Examples

      iex> delete_accountclass(accountclass)
      {:ok, %Accountclass{}}

      iex> delete_accountclass(accountclass)
      {:error, %Ecto.Changeset{}}

  """
  def delete_accountclass(%Accountclass{} = accountclass) do
    Repo.delete(accountclass)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking accountclass changes.

  ## Examples

      iex> change_accountclass(accountclass)
      %Ecto.Changeset{data: %Accountclass{}}

  """
  def change_accountclass(%Accountclass{} = accountclass, attrs \\ %{}) do
    Accountclass.changeset(accountclass, attrs)
  end

  alias Sportyweb.Accounting.Accountgroup

  @doc """
  Returns all accountgroups for a club, ordered alphabetically by name.

  ## Examples

      iex> list_accountgroups(club_id)
      [%Accountgroup{}, ...]

  """
  def list_accountgroups(club_id, preloads \\ [:club]) do
    Accountgroup
    |> where([a], a.club_id == ^club_id)
    |> order_by([a], asc: a.accountgroupname)
    |> Repo.all()
    |> Repo.preload(preloads)
  end

  @doc """
  Gets a single accountgroup by ID. Preloads associations.

  Raises `Ecto.NoResultsError` if the Accountgroup does not exist.

  ## Examples

      iex> get_accountgroup!(123)
      %Accountgroup{}

      iex> get_accountgroup!(456)
      ** (Ecto.NoResultsError)

  """
  def get_accountgroup!(id, preloads \\ [:club]) do
    Accountgroup
    |> Repo.get!(id)
    |> Repo.preload(preloads)
  end

  @doc """
  Creates an accountgroup.

  ## Examples

      iex> create_accountgroup(%{field: value})
      {:ok, %Accountgroup{}}

      iex> create_accountgroup(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_accountgroup(attrs \\ %{}) do
    %Accountgroup{}
    |> Accountgroup.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an accountgroup.

  ## Examples

      iex> update_accountgroup(accountgroup, %{field: new_value})
      {:ok, %Accountgroup{}}

      iex> update_accountgroup(accountgroup, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_accountgroup(%Accountgroup{} = accountgroup, attrs) do
    accountgroup
    |> Accountgroup.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an accountgroup.

  ## Examples

      iex> delete_accountgroup(accountgroup)
      {:ok, %Accountgroup{}}

      iex> delete_accountgroup(accountgroup)
      {:error, %Ecto.Changeset{}}

  """
  def delete_accountgroup(%Accountgroup{} = accountgroup) do
    Repo.delete(accountgroup)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking accountgroup changes.

  ## Examples

      iex> change_accountgroup(accountgroup)
      %Ecto.Changeset{data: %Accountgroup{}}

  """

  def change_accountgroup(%Accountgroup{} = accountgroup, attrs \\ %{}) do
    Accountgroup.changeset(accountgroup, attrs)
  end

  alias Sportyweb.Accounting.AccountingPeriod

  @doc """
  Returns all accounting periods for a club, ordered chronologically.

  ## Examples

      iex> list_accounting_periods(club_id)
      [%AccountingPeriod{}, ...]

  """
  def list_accounting_periods(club_id) do
    AccountingPeriod
    |> where([p], p.club_id == ^club_id)
    |> preload(:club)
    |> order_by([p], asc: p.starts_on)
    |> Repo.all()
  end

  @doc """
  Gets a single accounting period by ID. Preloads associations.

  Raises `Ecto.NoResultsError` if the period does not exist.

  ## Examples

      iex> get_accounting_period!(123)
      %AccountingPeriod{}

      iex> get_accounting_period!(456)
      ** (Ecto.NoResultsError)

  """
  def get_accounting_period!(id, preloads \\ [:club]) do
    AccountingPeriod
    |> Repo.get!(id)
    |> Repo.preload(preloads)
  end

  @doc """
  Creates an accounting period.

  ## Examples

      iex> create_accounting_period(%{field: value})
      {:ok, %AccountingPeriod{}}

      iex> create_accounting_period(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_accounting_period(attrs) do
    %AccountingPeriod{}
    |> AccountingPeriod.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an accounting period.

  ## Examples

      iex> update_accounting_period(period, %{field: new_value})
      {:ok, %AccountingPeriod{}}

      iex> update_accounting_period(period, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_accounting_period(%AccountingPeriod{} = period, attrs) do
    period
    |> AccountingPeriod.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Returns the newest open or closing accounting period for a club, or `nil`
  if none exists.

  Used as the default fallback period when no active period has been selected
  in the session.

  ## Examples

      iex> get_newest_open_period(club_id)
      %AccountingPeriod{}

      iex> get_newest_open_period(club_id_with_no_periods)
      nil

  """
  def get_newest_open_period(club_id) do
    AccountingPeriod
    |> where([p], p.club_id == ^club_id and p.status in [:open, :closing])
    |> order_by([p], desc: p.starts_on)
    |> limit(1)
    |> Repo.one()
  end


  # @doc """
  # Gets a single accounting period by ID, returning `nil` if not found.

  # Unlike `get_accounting_period!/1`, this function does not raise on missing
  # records. Use it when the period may legitimately not exist (e.g. session
  # lookups after a period has been deleted).

  # ## Examples

  #     iex> get_accounting_period(123)
  #     %AccountingPeriod{}

  #     iex> get_accounting_period(456)
  #     nil

  # """
  # def get_accounting_period(id) do
  #   Repo.get(AccountingPeriod, id)
  # end

  @doc """
  Deletes an accounting period.

  ## Examples

      iex> delete_accounting_period(accounting_period)
      {:ok, %AccountingPeriod{}}

      iex> delete_accounting_period(accounting_period)
      {:error, %Ecto.Changeset{}}

  """
  def delete_accounting_period(%AccountingPeriod{} = accounting_period) do
    Repo.delete(accounting_period)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking accounting period changes.

  ## Examples

      iex> change_accounting_period(accounting_period)
      %Ecto.Changeset{data: %AccountingPeriod{}}

  """
  def change_accounting_period(%AccountingPeriod{} = accounting_period, attrs \\ %{}) do
    AccountingPeriod.changeset(accounting_period, attrs)
  end



  alias Sportyweb.Accounting.Entry

  @doc """
  Returns the list of entries for a given club.

  ## Examples

      iex> list_entries(club_id)
      [%Entry{}, ...]

  """
  def list_entries(club_id, preloads \\ [:account]) do
    Entry
    |> where([e], e.club_id == ^club_id)
    |> order_by([e], asc: e.amount)
    |> Repo.all()
    |> Repo.preload(preloads)
  end

  @doc """
  Gets a single entry by ID.

  Raises `Ecto.NoResultsError` if the entry does not exist.

  ## Examples

      iex> get_entry!(123)
      %Entry{}

      iex> get_entry!(456)
      ** (Ecto.NoResultsError)

  """
  def get_entry!(id, preloads \\ [:club, :account]) do
    Entry
    |> Repo.get!(id)
    |> Repo.preload(preloads)
  end

  @doc """
  Creates an entry.

  ## Examples

      iex> create_entry(%{field: value})
      {:ok, %Entry{}}

      iex> create_entry(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_entry(attrs \\ %{}) do
    %Entry{}
    |> Entry.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an entry of a transaction.

  Entries are immutable once the associated transaction has been posted or voided.
  Only entries of transactions with status `:draft` or `:pending` can be updated.

  Returns `{:error, :immutable}` if the transaction has already been posted or voided.

  ## Examples

      iex> update_entry(entry, %{amount: Money.new(100, :EUR)})
      {:ok, %Entry{}}

      iex> update_entry(entry, %{amount: Money.new(100, :EUR)})
      {:error, %Ecto.Changeset{}}

      iex> update_entry(posted_entry, %{amount: Money.new(100, :EUR)})
      {:error, :immutable}

  """
  def update_entry(%Entry{} = entry, attrs) do
    case entry.accounting_transaction.status do
      status when status in [:posted, :voided] ->
        {:error, :immutable}
      _ ->
        entry
        |> Entry.changeset(attrs)
        |> Repo.update()
    end
  end

  @doc """
  Deletes an entry of a transaction.

  Entries are immutable once the associated transaction has been posted or voided.
  Only entries of transactions with status `:draft` can be deleted.

  Returns `{:error, :immutable}` if the transaction is in status
  `:pending`, `:posted`, `:voided` or `:deleted`.

  ## Examples

      iex> delete_entry(entry)
      {:ok, %Entry{}}

      iex> delete_entry(entry)
      {:error, %Ecto.Changeset{}}

      iex> delete_entry(posted_entry)
      {:error, :immutable}

  """
  def delete_entry(%Entry{} = entry) do
    case entry.accounting_transaction.status do
      status when status in [:pending, :posted, :voided, :deleted] ->
        {:error, :immutable}
      _ ->
        Repo.delete(entry)
    end
  end

  alias Sportyweb.Accounting.AccountingTransaction

  @doc """
  Returns the list of accounting transactions for a given club.

  Transactions are ordered by insertion date in ascending order.
  Soft-deleted transactions (status `:deleted`) are included by default.

  ## Examples

      iex> list_accounting_transactions(club_id)
      [%AccountingTransaction{}, ...]

  """
  def list_accounting_transactions(club_id, preloads \\ [:entries]) do
    AccountingTransaction
    |> where([at], at.club_id == ^club_id)
    |> order_by([at], asc: at.inserted_at)
    |> Repo.all()
    |> Repo.preload(preloads)
  end

  @doc """
  Returns all accounting transactions for a club scoped to a specific
  accounting period.

  Results are ordered by document date and posting timestamp, matching the
  chronological order expected in a journal view.

  ## Examples

      iex> list_accounting_transactions_for_period(club_id, period_id)
      [%AccountingTransaction{}, ...]

  """
  def list_accounting_transactions_for_period(club_id, period_id, preloads \\ [:entries]) do
    AccountingTransaction
    |> where([at], at.club_id == ^club_id and at.accounting_period_id == ^period_id)
    |> order_by([at], asc: at.document_date, asc: at.posted_at)
    |> Repo.all()
    |> Repo.preload(preloads)
  end


  @doc """
  Gets a single accounting transaction by ID.

  Raises `Ecto.NoResultsError` if the accounting transaction does not exist.

  ## Examples

      iex> get_accounting_transaction!(123)
      %AccountingTransaction{}

      iex> get_accounting_transaction!(456)
      ** (Ecto.NoResultsError)

  """
  def get_accounting_transaction!(id, preloads \\ [:club, :entries]) do
    AccountingTransaction
    |> Repo.get!(id)
    |> Repo.preload(preloads)
  end

  @doc """
  Creates an accounting transaction.

  Automatically generates a sequential transaction number scoped to the
  accounting period (e.g. "2026-0001"). The counter is incremented atomically
  using a database-level update to prevent duplicates under concurrent inserts.

  ## Examples

      iex> create_accounting_transaction(%{field: value})
      {:ok, %AccountingTransaction{}}

      iex> create_accounting_transaction(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_accounting_transaction(attrs \\ %{}) do
    club_id = attrs[:club_id] || attrs["club_id"]
    period_id = attrs[:accounting_period_id] || attrs["accounting_period_id"]

    transaction_number =
      if is_nil(club_id) or is_nil(period_id) do
        nil
      else
        period = get_accounting_period!(period_id)
        generate_transaction_number(period)
      end

    # Preserve the key type of the incoming map (atom vs. string keys) to
    # avoid accidentally converting a string-keyed params map to atom keys.
    transaction_key = if is_map_key(attrs, "club_id"), do: "transaction_number", else: :transaction_number

    %AccountingTransaction{}
    |> AccountingTransaction.changeset(Map.put(attrs, transaction_key, transaction_number))
    |> Repo.insert()
  end

  # Atomically increments the period's transaction_counter and derives the
  # transaction number from the period's start year and the new counter value.
  # Using Repo.update_all with inc: ensures no two concurrent inserts get the
  # same counter value, even without an application-level lock.
  defp generate_transaction_number(%AccountingPeriod{} = period) do
    {1, [updated_period]} =
      AccountingPeriod
      |> where([p], p.id == ^period.id)
      |> select([p], p)
      |> Repo.update_all(inc: [transaction_counter: 1])

    year = updated_period.starts_on.year
    counter = updated_period.transaction_counter

    "#{year}-#{String.pad_leading(to_string(counter), 4, "0")}"
  end

  @doc """
  Updates an accounting transaction.

  Only transactions with status `:draft` or `:pending` can be fully updated.
  Returns `{:error, :immutable}` if the transaction is in any other status.

  ## Examples

      iex> update_accounting_transaction(accounting_transaction, %{field: new_value})
      {:ok, %AccountingTransaction{}}

      iex> update_accounting_transaction(accounting_transaction, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_accounting_transaction(%AccountingTransaction{status: status} = accounting_transaction, attrs)
      when status in [:draft, :pending] do
    accounting_transaction
      |> AccountingTransaction.changeset(attrs)
      |> Repo.update()
  end

  # Catch-all clause for all other statuses (posted, voided, deleted).
  def update_accounting_transaction(%AccountingTransaction{}), do: {:error, :immutable}

  @doc """
  Soft-deletes an accounting transaction with status `:draft`.

  To preserve transaction number continuity (§ 239 HGB), the transaction
  record is not physically deleted. Instead, all associated entries are
  removed and the transaction is marked with status `:deleted`, a
  `deleted_at` timestamp, and the description "Entwurf gelöscht".

  Both operations run inside a single database transaction to ensure
  consistency — either both succeed or neither is persisted.

  Returns `{:error, :immutable}` if the transaction is not in `:draft` status.

  ## Examples

      iex> delete_accounting_transaction(draft_accounting_transaction)
      {:ok, %AccountingTransaction{status: :deleted}}

      iex> delete_accounting_transaction(posted_accounting_transaction)
      {:error, :immutable}

  """
  def delete_accounting_transaction(%AccountingTransaction{status: status} = accounting_transaction)
      when status in [:draft] do
    accounting_transaction = Repo.preload(accounting_transaction, :entries)

      Repo.transaction(fn ->
      # Delete all entries first to satisfy foreign key constraints before
      # the transaction record itself is updated.
        Entry
        |> where([e], e.accounting_transaction_id == ^accounting_transaction.id)
        |> Repo.delete_all()

        # Transaction soft-deleten
        accounting_transaction
        |> Ecto.Changeset.change(%{
          deleted_at: DateTime.utc_now() |> DateTime.truncate(:second),
          description: "Entwurf gelöscht",
          status: :deleted
        })
        |> Repo.update!()
    end)

  end

  # Catch-all clause — only :draft transactions can be soft-deleted.
  def delete_accounting_transaction(%AccountingTransaction{}), do: {:error, :immutable}

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking accounting transaction changes.

  ## Examples

      iex> change_accounting_transaction(accounting_transaction)
      %Ecto.Changeset{data: %AccountingTransaction{}}

  """
  def change_accounting_transaction(%AccountingTransaction{} = accounting_transaction, attrs \\ %{}) do
    AccountingTransaction.changeset(accounting_transaction, attrs)
  end


  @doc """
  Transitions an accounting transaction from `:draft` to `:pending`.

  A transaction in `:pending` status is considered complete and awaits
  approval for posting. Only transactions with status `:draft` can be submitted.

  Returns `{:error, :invalid_transition}` if the transaction is not in `:draft` status.

  ## Examples

      iex> submit_accounting_transaction(draft_accounting_transaction)
      {:ok, %AccountingTransaction{status: :pending}}

      iex> submit_accounting_transaction(posted_accounting_transaction)
      {:error, :invalid_transition}

  """
  def submit_accounting_transaction(%AccountingTransaction{status: :draft} = accounting_transaction) do
    accounting_transaction = Repo.preload(accounting_transaction, :entries)

    accounting_transaction
    |> AccountingTransaction.pending_changeset()
    |> Repo.update()
  end

  def submit_accounting_transaction(%AccountingTransaction{}), do: {:error, :invalid_transition}

  @doc """
  Reverts an accounting transaction from `:pending` back to `:draft`.

  A transaction in `:pending` status can be reverted to `:draft` if
  corrections are required before resubmission. Only transactions with
  status `:pending` can be reverted.

  Returns `{:error, :invalid_transition}` if the transaction is not in `:pending` status.

  ## Examples

      iex> revert_to_draft_accounting_transaction(pending_accounting_transaction)
      {:ok, %AccountingTransaction{status: :draft}}

      iex> revert_to_draft_accounting_transaction(posted_accounting_transaction)
      {:error, :invalid_transition}

  """
  def revert_to_draft_accounting_transaction(%AccountingTransaction{status: :pending} = accounting_transaction) do
    accounting_transaction
    |> AccountingTransaction.draft_changeset()
    |> Repo.update()
  end

  def revert_to_draft_accounting_transaction(%AccountingTransaction{}), do: {:error, :invalid_transition}

  @doc """
  Transitions an accounting transaction from `:pending` to `:posted`.

  A posted transaction is immutable and its entries are reflected in the
  account balances. All associated entries must be balanced - the sum of
  all entry amounts must equal zero — before the transaction can be posted.

  Only transactions with status `:pending` can be posted.

  Returns `{:error, :invalid_transition}` if the transaction is not in `:pending` status.
  Returns `{:error, %Ecto.Changeset{}}` if the entries are not balanced.

  ## Examples

      iex> post_accounting_transaction(pending_accounting_transaction)
      {:ok, %AccountingTransaction{status: :posted}}

      iex> post_accounting_transaction(draft_accounting_transaction)
      {:error, :invalid_transition}

      iex> post_accounting_transaction(unbalanced_accounting_transaction)
      {:error, %Ecto.Changeset{}}

  """
  def post_accounting_transaction(%AccountingTransaction{status: :pending} = accounting_transaction) do
    accounting_transaction = Repo.preload(accounting_transaction, :entries)

    accounting_transaction
    |> AccountingTransaction.post_changeset()
    |> Repo.update()
  end

  def post_accounting_transaction(%AccountingTransaction{}), do: {:error, :invalid_transition}

  @doc """
  Transitions an accounting transaction from `:posted` to `:voided` and
  creates a corresponding reversal transaction.

  Voiding a posted transaction creates an offsetting reversal entry with
  negated amounts, preserving the audit trail.
  The original transaction is marked as `:voided` and the reversal
  transaction is immediately posted.

  Both operations run inside a single database transaction to ensure
  consistency — if either step fails, the entire operation is rolled back.

  Returns `{:error, :invalid_transition}` if the transaction is not in `:posted` status.
  Returns `{:error, changeset}` if the reversal transaction cannot be created.

  ## Examples

      iex> void_accounting_transaction(posted_accounting_transaction)
      {:ok, %AccountingTransaction{status: :voided}}

      iex> void_accounting_transaction(draft_accounting_transaction)
      {:error, :invalid_transition}

  """
  def void_accounting_transaction(%AccountingTransaction{status: :posted} = accounting_transaction) do

    Repo.transaction(fn ->
    case accounting_transaction
         |> AccountingTransaction.void_changeset()
         |> Repo.update() do
      {:ok, voided_transaction} ->
        reversal_attrs = %{
          "club_id" => accounting_transaction.club_id,
          "accounting_period_id" => accounting_transaction.accounting_period_id,
          "description" => "Storno: #{accounting_transaction.description}",
          "document_date" => Date.utc_today(),
          # Store the original transaction number as reference so the reversal
          # can be traced back to the transaction it offsets.
          "reference" => accounting_transaction.transaction_number,
          "status" => "posted",
          "posted_at" => DateTime.utc_now() |> DateTime.truncate(:second),
          "entries" => build_reversal_entries(accounting_transaction)
        }

        case create_reversal_transaction(reversal_attrs) do
          {:ok, _reversal} ->
            {:ok, voided_transaction}
          {:error, changeset} ->
            Repo.rollback(changeset)
        end

      {:error, changeset} ->
        Repo.rollback(changeset)
    end
  end)

  end

  def void_accounting_transaction(%AccountingTransaction{}), do: {:error, :invalid_transition}

  # Builds the entry map for a reversal transaction by negating all amounts
  # of the original transaction's entries. The index-keyed map format matches
  # what AccountingTransaction.reversal_changeset/1 expects.
  defp build_reversal_entries(accounting_transaction) do
    accounting_transaction.entries
    |> Enum.with_index()
    |> Enum.map(fn {entry, index} ->
      {
        "#{index}",
        %{
          "account_id" => entry.account_id,
          "club_id" => entry.club_id,
          "amount" => Money.negate!(entry.amount),
          "description" => entry.description
        }
      }
    end)
    |> Enum.into(%{})
  end

  # Creates a reversal transaction with its own sequential transaction number.
  # Uses reversal_changeset/1 instead of the standard changeset to bypass
  # validations that are not applicable to system-generated reversal entries.
  defp create_reversal_transaction(attrs) do

    accounting_period_id = Map.get(attrs, "accounting_period_id")
    period = get_accounting_period!(accounting_period_id)
    transaction_number = generate_transaction_number(period)

    _attrs_with_transaction = Map.put(attrs, "transaction_number", transaction_number)

    %AccountingTransaction{}
    |> AccountingTransaction.reversal_changeset(Map.put(attrs, "transaction_number", transaction_number))
    |> Repo.insert()
  end

  @doc """
  Returns accounts for a club grouped by Hauptgruppe (Bestandskonten,
  Erfolgskonten, Neutralkonten) and then by account class, for rendering
  the general ledger index view.

  When `accounting_period_id` is provided, only accounts with at least one
  posted or voided entry in that period are returned, and each account's
  `computed_balance` is set to the net balance for the period. Accounts with
  no entries in the period are excluded to keep the ledger view focused.

  When `accounting_period_id` is nil, all accounts are returned without
  balance data.

  ## Examples

      iex> list_accounts_grouped(club_id, period_id)
      [{:bestandskonten, [{%Accountclass{}, [%Account{}, ...]}, ...]}, ...]

      iex> list_accounts_grouped(club_id)
      [{:bestandskonten, [{%Accountclass{}, [%Account{}, ...]}, ...]}, ...]

  """
  def list_accounts_grouped(club_id, accounting_period_id \\ nil) do
  accounts =
    Account
    |> where([a], a.club_id == ^club_id)
    |> preload([:accountclass, :accountgroup])
    |> Repo.all()

  accounts =
    if accounting_period_id do
      balances = compute_balances(club_id, accounting_period_id)
      account_ids_with_entries = Map.keys(balances)

      accounts
      # Only include accounts that have at least one entry in the period.
      |> Enum.filter(fn account ->
        account.id in account_ids_with_entries
      end)
      |> Enum.map(fn account ->
        balance = Map.get(balances, account.id, Money.new(:EUR, 0))
        %{account | computed_balance: balance}
      end)
    else
      accounts
    end

    accounts
    |> Enum.group_by(&account_hauptgruppe/1)
    |> Enum.map(fn {hauptgruppe, accounts} ->
      klassen =
        accounts
        |> Enum.group_by(& &1.accountclass)
        |> Enum.sort_by(fn {ac, _} ->
          String.to_integer(ac.accountclassnumber)
        end)
      {hauptgruppe, klassen}
    end)
    # Sort Hauptgruppen in the order: Bestandskonten, Erfolgskonten,
    # Neutralkonten — matching the structure.
    |> Enum.sort_by(fn {hauptgruppe, _} ->
      case hauptgruppe do
        :bestandskonten -> 0
        :erfolgskonten  -> 1
        :neutralkonten  -> 2
      end
    end)

  end

  # Computes the net balance per account for a given club and period by
  # summing all entry amounts from posted and voided transactions.
  # Voided transactions are included because their reversal entries already
  # offset the original amounts — the net effect on balances is zero.
  defp compute_balances(club_id, accounting_period_id) do
    Entry
    |> join(:inner, [e], t in AccountingTransaction,
        on: e.accounting_transaction_id == t.id)
    |> where([e, t],
        t.club_id == ^club_id and
        t.status in [:posted, :voided] and
        t.accounting_period_id == ^accounting_period_id)
    |> Repo.all()
    |> Enum.group_by(& &1.account_id)
    |> Map.new(fn {account_id, entries} ->
      computed_balance =
        Enum.reduce(entries, Money.new(:EUR, 0), fn entry, acc ->
          Money.add!(acc, entry.amount)
        end)
      {account_id, computed_balance}
    end)
  end

  # Maps an account's type code to one of three Hauptgruppen
  # :aktiv / :passiv accounts are balance sheet accounts (Bestandskonten)
  # :aufwand / :ertrag are income statement accounts (Erfolgskonten)
  # everything else falls into Neutralkonten
  defp account_hauptgruppe(%Account{accounttypecode: code})
    when code in [:aktiv, :passiv],   do: :bestandskonten
  defp account_hauptgruppe(%Account{accounttypecode: code})
    when code in [:aufwand, :ertrag], do: :erfolgskonten
  defp account_hauptgruppe(_),        do: :neutralkonten

  @doc """
  Returns the human-readable label for a Hauptgruppe atom.

  ## Examples

      iex> hauptgruppe_label(:bestandskonten)
      "Bestandskonten"

  """
  def hauptgruppe_label(:bestandskonten), do: "Bestandskonten"
  def hauptgruppe_label(:erfolgskonten),  do: "Erfolgskonten"
  def hauptgruppe_label(:neutralkonten),  do: "Neutralkonten"

  @doc """
  Returns an account and all its posted or voided entries for a given period.

  Entries are ordered by document date and transaction number to reflect
  chronological posting order, matching the display in a T-account view.

  When `accounting_period_id` is nil, entries from all periods are returned as default.

  ## Examples

      iex> get_account_with_entries!(account_id, period_id)
      %{account: %Account{}, entries: [%Entry{}, ...]}

      iex> get_account_with_entries!(account_id)
      %{account: %Account{}, entries: [%Entry{}, ...]}

  """
  def get_account_with_entries!(account_id, accounting_period_id \\ nil) do
    entries =
      Entry
      |> join(:inner, [e], t in AccountingTransaction,
          on: e.accounting_transaction_id == t.id)
      |> where([e, t], e.account_id == ^account_id and t.status in [:posted, :voided])
      |> then(fn query ->
        if accounting_period_id do
          where(query, [e, t], t.accounting_period_id == ^accounting_period_id)
        else
          query
        end
      end)
      |> order_by([e, t], asc: t.document_date, asc: t.transaction_number)
      |> preload([e, t], [accounting_transaction: t])
      |> Repo.all()

    account =
      account_id
      |> then(&Repo.get!(Account, &1))
      |> Repo.preload([:accountclass, :accountgroup])

    %{account: account, entries: entries}
  end

end
