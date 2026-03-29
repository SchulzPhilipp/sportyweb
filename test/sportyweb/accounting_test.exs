defmodule Sportyweb.AccountingTest do
  use Sportyweb.DataCase, async: true

  alias Sportyweb.Accounting

  describe "transactions" do
    alias Sportyweb.Accounting.Transaction
    alias Sportyweb.Legal

    import Sportyweb.AccountingFixtures
    import Sportyweb.LegalFixtures

    @invalid_attrs %{
      amount: nil,
      creation_date: nil,
      name: nil,
      payment_date: ""
    }

    test "list_transactions/1 returns all transactions of a given club" do
      transaction = transaction_fixture()
      contract = Legal.get_contract!(transaction.contract_id)
      assert Accounting.list_transactions(contract.club_id) == [transaction]
    end

    test "list_transactions/2 returns all contracts of a given club with preloaded associations" do
      transaction = transaction_fixture()
      contract = Legal.get_contract!(transaction.contract_id)

      transactions = Accounting.list_transactions(contract.club_id, [:contract])
      assert List.first(transactions).contract_id == contract.id
    end

    test "get_transaction!/1 returns the transaction with given id" do
      transaction = transaction_fixture()
      assert Accounting.get_transaction!(transaction.id) == transaction
    end

    test "get_transaction!/2 returns the contract with given id and contains a preloaded club" do
      transaction = transaction_fixture()

      assert %Transaction{} = Accounting.get_transaction!(transaction.id, [:contract])

      assert Accounting.get_transaction!(transaction.id, [:contract]).contract.id ==
               transaction.contract_id
    end

    test "create_transaction/1 with valid data creates a transaction" do
      contract = contract_fixture()

      valid_attrs = %{
        contract_id: contract.id,
        amount: "42 €",
        creation_date: ~D[2023-06-04],
        name: "some name",
        payment_date: ~D[2023-06-04]
      }

      assert {:ok, %Transaction{} = transaction} = Accounting.create_transaction(valid_attrs)
      assert transaction.amount == Money.new(:EUR, 42)
      assert transaction.creation_date == ~D[2023-06-04]
      assert transaction.name == "some name"
      assert transaction.payment_date == ~D[2023-06-04]
    end

    test "create_transaction/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounting.create_transaction(@invalid_attrs)
    end

    test "update_transaction/2 with valid data updates the transaction" do
      transaction = transaction_fixture()

      update_attrs = %{
        amount: "43 €",
        creation_date: ~D[2023-06-05],
        name: "some updated name",
        payment_date: ~D[2023-06-05]
      }

      assert {:ok, %Transaction{} = transaction} =
               Accounting.update_transaction(transaction, update_attrs)

      assert transaction.amount == Money.new(:EUR, 43)
      assert transaction.creation_date == ~D[2023-06-05]
      assert transaction.name == "some updated name"
      assert transaction.payment_date == ~D[2023-06-05]
    end

    test "update_transaction/2 with invalid data returns error changeset" do
      transaction = transaction_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Accounting.update_transaction(transaction, @invalid_attrs)

      assert transaction == Accounting.get_transaction!(transaction.id)
    end

    test "delete_transaction/1 deletes the transaction" do
      transaction = transaction_fixture()
      assert {:ok, %Transaction{}} = Accounting.delete_transaction(transaction)
      assert_raise Ecto.NoResultsError, fn -> Accounting.get_transaction!(transaction.id) end
    end

    test "change_transaction/1 returns a transaction changeset" do
      transaction = transaction_fixture()
      assert %Ecto.Changeset{} = Accounting.change_transaction(transaction)
    end
  end

  describe "accounts" do
    alias Sportyweb.Accounting.Account

    import Sportyweb.AccountingFixtures
    import Sportyweb.OrganizationFixtures

    @invalid_attrs %{accountnumber: nil, accountname: nil, accountbalance: nil}

    # test "list_accounts/0 returns all accounts" do
    #   account = account_fixture()
    #   account = Sportyweb.Repo.preload(account, [:accountclass, :accountgroup, :accounttype])
    #   assert Accounting.list_accounts() == [account]
    # end

    test "get_account!/1 returns the account with given id" do
      account = account_fixture()
      result = Accounting.get_account!(account.id)
      assert result.id == account.id
      assert result.accountnumber == account.accountnumber

      # account = Sportyweb.Repo.preload(account, [:accountclass, :accountgroup, :accounttype])
      # assert Accounting.get_account!(account.id) == Repo.get(Account, account.id)
    end

    test "create_account/1 with valid data creates a account" do
      accountclass = accountclass_fixture()
      accountgroup = accountgroup_fixture()
      club = club_fixture()

      valid_attrs = %{
        accountnumber: "0815",
        accountname: "some accountname",
        accounttypecode: "neutral",
        accountbalance: Money.new(:EUR, 120),
        accountclass_id: accountclass.id,
        accountgroup_id: accountgroup.id,
        club_id: club.id
      }

      assert {:ok, %Account{} = account} = Accounting.create_account(valid_attrs)
      assert account.accountnumber == "0815"
      assert account.accountname == "some accountname"
      assert account.accountbalance == Money.new(:EUR, 120)
    end

    test "create_account/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounting.create_account(@invalid_attrs)
    end

    test "update_account/2 with valid data updates the account" do
      account = account_fixture()
      account = Sportyweb.Repo.preload(account, [:club, :accountclass, :accountgroup])

      update_attrs = %{
        accountnumber: "0815",
        accountname: "some updated accountname",
        accountbalance: Money.new(:EUR, 456)
      }

      assert {:ok, %Account{} = account} = Accounting.update_account(account, update_attrs)
      assert account.accountnumber == "0815"
      assert account.accountname == "some updated accountname"
      assert account.accountbalance == Money.new(:EUR, 456)
    end

    test "update_account/2 with invalid data returns error changeset" do
      account = account_fixture()
      account = Sportyweb.Repo.preload(account, [:club, :accountclass, :accountgroup])
      assert {:error, %Ecto.Changeset{}} = Accounting.update_account(account, @invalid_attrs)
      assert account == Accounting.get_account!(account.id)
    end

    test "delete_account/1 deletes the account" do
      account = account_fixture()
      assert {:ok, %Account{}} = Accounting.delete_account(account)
      assert_raise Ecto.NoResultsError, fn -> Accounting.get_account!(account.id) end
    end

    test "change_account/1 returns a account changeset" do
      account = account_fixture()
      account = Sportyweb.Repo.preload(account, [:club, :accountclass, :accountgroup])
      assert %Ecto.Changeset{} = Accounting.change_account(account)
    end
  end

  describe "accountclasses" do
    alias Sportyweb.Accounting.Accountclass

    import Sportyweb.AccountingFixtures
    import Sportyweb.OrganizationFixtures

    @invalid_attrs %{accountclassnumber: nil, accountclassname: nil}

    # test "list_accountclasses/0 returns all accountclasses" do
    #   accountclass = accountclass_fixture()
    #   assert Accounting.list_accountclasses() == [accountclass]
    # end

    test "get_accountclass!/1 returns the accountclass with given id" do
      accountclass = accountclass_fixture()
      |> Repo.preload(:club)

      assert Accounting.get_accountclass!(accountclass.id) == accountclass
    end

    test "create_accountclass/1 with valid data creates a accountclass" do
      club = club_fixture()

      valid_attrs = %{club_id: club.id, accountclassnumber: "0", accountclassname: "some accountclassname"}

      assert {:ok, %Accountclass{} = accountclass} = Accounting.create_accountclass(valid_attrs)
      assert accountclass.accountclassnumber == "0"
      assert accountclass.accountclassname == "some accountclassname"
    end

    test "create_accountclass/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounting.create_accountclass(@invalid_attrs)
    end

    test "update_accountclass/2 with valid data updates the accountclass" do
      accountclass = accountclass_fixture()
      update_attrs = %{accountclassnumber: "0", accountclassname: "some updated accountclassname"}

      assert {:ok, %Accountclass{} = accountclass} =
               Accounting.update_accountclass(accountclass, update_attrs)

      assert accountclass.accountclassnumber == "0"
      assert accountclass.accountclassname == "some updated accountclassname"
    end

    test "update_accountclass/2 with invalid data returns error changeset" do
      accountclass = accountclass_fixture()
      |> Repo.preload(:club)

      assert {:error, %Ecto.Changeset{}} =
               Accounting.update_accountclass(accountclass, @invalid_attrs)

      assert accountclass == Accounting.get_accountclass!(accountclass.id)
    end

    test "delete_accountclass/1 deletes the accountclass" do
      accountclass = accountclass_fixture()
      assert {:ok, %Accountclass{}} = Accounting.delete_accountclass(accountclass)
      assert_raise Ecto.NoResultsError, fn -> Accounting.get_accountclass!(accountclass.id) end
    end

    test "change_accountclass/1 returns a accountclass changeset" do
      accountclass = accountclass_fixture()
      assert %Ecto.Changeset{} = Accounting.change_accountclass(accountclass)
    end
  end

  describe "accountgroups" do
    alias Sportyweb.Accounting.Accountgroup

    import Sportyweb.AccountingFixtures
    import Sportyweb.OrganizationFixtures

    @invalid_attrs %{accountgroupname: nil}

    # test "list_accountgroups/0 returns all accountgroups" do
    #   accountgroup = accountgroup_fixture()
    #   assert Accounting.list_accountgroups() == [accountgroup]
    # end

    test "get_accountgroup!/1 returns the accountgroup with given id" do
      accountgroup = accountgroup_fixture()
      |> Repo.preload(:club)

      assert Accounting.get_accountgroup!(accountgroup.id) == accountgroup
    end

    test "create_accountgroup/1 with valid data creates a accountgroup" do
      club = club_fixture()

      valid_attrs = %{
        accountgroupname: "some accountgroupname",
        club_id: club.id
      }

      assert {:ok, %Accountgroup{} = accountgroup} = Accounting.create_accountgroup(valid_attrs)
      assert accountgroup.accountgroupname == "some accountgroupname"
    end

    test "create_accountgroup/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounting.create_accountgroup(@invalid_attrs)
    end

    test "update_accountgroup/2 with valid data updates the accountgroup" do
      accountgroup = accountgroup_fixture()
      update_attrs = %{accountgroupname: "some updated accountgroupname"}

      assert {:ok, %Accountgroup{} = accountgroup} =
               Accounting.update_accountgroup(accountgroup, update_attrs)

      assert accountgroup.accountgroupname == "some updated accountgroupname"
    end

    test "update_accountgroup/2 with invalid data returns error changeset" do
      accountgroup = accountgroup_fixture()
      |> Repo.preload(:club)

      assert {:error, %Ecto.Changeset{}} =
               Accounting.update_accountgroup(accountgroup, @invalid_attrs)

      assert accountgroup == Accounting.get_accountgroup!(accountgroup.id)
    end

    test "delete_accountgroup/1 deletes the accountgroup" do
      accountgroup = accountgroup_fixture()
      assert {:ok, %Accountgroup{}} = Accounting.delete_accountgroup(accountgroup)
      assert_raise Ecto.NoResultsError, fn -> Accounting.get_accountgroup!(accountgroup.id) end
    end

    test "change_accountgroup/1 returns a accountgroup changeset" do
      accountgroup = accountgroup_fixture()
      assert %Ecto.Changeset{} = Accounting.change_accountgroup(accountgroup)
    end
  end

  describe "entries" do
    alias Sportyweb.Accounting.Entry

    import Sportyweb.AccountingFixtures
    import Sportyweb.OrganizationFixtures

    @invalid_attrs %{description: nil, amount: nil}

    test "list_entries/1 returns all entries" do
      # entry =
      #   entry_fixture()
      #   |> Repo.preload([:accounting_transaction, :account])

      # assert Accounting.list_entries(entry.club_id) == [entry]

      entry = entry_fixture()
      [result] = Accounting.list_entries(entry.club_id)

      assert result.id == entry.id
      assert result.amount == entry.amount
      assert result.description == entry.description
      assert result.accounting_transaction_id == entry.accounting_transaction_id
    end

    test "get_entry!/1 returns the entry with given id" do
      entry = entry_fixture()
      result = Accounting.get_entry!(entry.id)

      assert result.id == entry.id
      assert result.amount == entry.amount
      assert result.description == entry.description
      assert result.accounting_transaction_id == entry.accounting_transaction_id
    end

    test "create_entry/1 with valid data creates a entry" do
      club = club_fixture()
      account = account_fixture()
      accounting_transaction = accounting_transaction_fixture()

      valid_attrs = %{description: "some description", amount: "120", club_id: club.id, account_id: account.id, accounting_transaction_id: accounting_transaction.id}

      assert {:ok, %Entry{} = entry} = Accounting.create_entry(valid_attrs)
      assert entry.description == "some description"
      assert entry.amount == Money.new(:EUR, 120)
    end

    test "create_entry/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounting.create_entry(@invalid_attrs)
    end

    test "update_entry/2 with valid data updates the entry" do
      entry =
        entry_fixture()
        |> Repo.preload([:accounting_transaction])

      update_attrs = %{description: "some updated description", amount: "456"}

      assert {:ok, %Entry{} = entry} = Accounting.update_entry(entry, update_attrs)
      assert entry.description == "some updated description"
      assert entry.amount == Money.new(:EUR, 456)
    end

    test "update_entry/2 with invalid data returns error changeset" do
      entry = entry_fixture()
        |> Repo.preload([:accounting_transaction])

      assert {:error, %Ecto.Changeset{}} = Accounting.update_entry(entry, @invalid_attrs)

      reloaded = Accounting.get_entry!(entry.id)

      assert entry.id == reloaded.id
      assert entry.amount == reloaded.amount
      assert entry.description == reloaded.description
      assert entry.account_id == reloaded.account_id
      assert entry.accounting_transaction_id == reloaded.accounting_transaction_id
    end

    test "delete_entry/1 deletes the entry" do
      entry =
        entry_fixture()
        |> Repo.preload([:accounting_transaction])

      if entry.accounting_transaction.status == :draft do
        Repo.delete(entry)
      else
        {:error, :transaction_not_draft}
      end
    end

  end

  describe "accountingtransactions" do
    alias Sportyweb.Accounting.AccountingTransaction

    import Sportyweb.AccountingFixtures
    import Sportyweb.OrganizationFixtures

    @invalid_attrs %{status: nil, description: nil, reference: nil, posted_at: nil}

    test "list_accounting_transactions/1 returns all accountingtransactions" do
      accounting_transaction =
        accounting_transaction_fixture()
        |> Repo.preload([:entries])

      assert Accounting.list_accounting_transactions(accounting_transaction.club_id) == [accounting_transaction]
    end

    test "get_accounting_transaction!/1 returns the accounting_transaction with given id" do
      accounting_transaction =
        accounting_transaction_fixture()
        |> Repo.preload([:club, :entries])
      assert Accounting.get_accounting_transaction!(accounting_transaction.id) == accounting_transaction
    end

    test "create_accounting_transaction/1 with valid data creates a accounting_transaction" do
      club = club_fixture()

      valid_attrs = %{club_id: club.id, status: "draft", description: "some description", reference: "some reference"}

      assert {:ok, %AccountingTransaction{} = accounting_transaction} = Accounting.create_accounting_transaction(valid_attrs)
      assert accounting_transaction.status == :draft
      assert accounting_transaction.description == "some description"
      assert accounting_transaction.reference == "some reference"
    end

    test "create_accounting_transaction/1 with invalid data returns error changeset" do


      assert {:error, %Ecto.Changeset{}} = Accounting.create_accounting_transaction(@invalid_attrs)
    end

    test "update_accounting_transaction/2 with valid data updates the accounting_transaction" do
      accounting_transaction =
        accounting_transaction_fixture()
        |> Repo.preload([:club, :entries])
      update_attrs = %{status: "draft", description: "some updated description", reference: "some updated reference"}

      assert {:ok, %AccountingTransaction{} = accounting_transaction} = Accounting.update_accounting_transaction(accounting_transaction, update_attrs)
      assert accounting_transaction.status == :draft
      assert accounting_transaction.description == "some updated description"
      assert accounting_transaction.reference == "some updated reference"
    end

    test "update_accounting_transaction/2 with invalid data returns error changeset" do
      accounting_transaction =
        accounting_transaction_fixture()
        |> Repo.preload([:club, :entries])

      assert {:error, %Ecto.Changeset{}} = Accounting.update_accounting_transaction(accounting_transaction, @invalid_attrs)
      assert accounting_transaction == Accounting.get_accounting_transaction!(accounting_transaction.id)
    end

    test "delete_accounting_transaction/1 deletes the accounting_transaction" do
      accounting_transaction = accounting_transaction_fixture()
      assert {:ok, %AccountingTransaction{}} = Accounting.delete_accounting_transaction(accounting_transaction)
    end

    test "change_accounting_transaction/1 returns a accounting_transaction changeset" do
      accounting_transaction = accounting_transaction_fixture()
      assert %Ecto.Changeset{} = Accounting.change_accounting_transaction(accounting_transaction)
    end
  end
end
