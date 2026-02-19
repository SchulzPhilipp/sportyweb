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

    @invalid_attrs %{accountnumber: nil, accountname: nil, accountbalance: nil}

    test "list_accounts/0 returns all accounts" do
      account = account_fixture()
      account = Sportyweb.Repo.preload(account, [:accountclass, :accountgroup, :accounttype])
      assert Accounting.list_accounts() == [account]
    end

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
      accounttype = accounttype_fixture()

      valid_attrs = %{
        accountnumber: "0815",
        accountname: "some accountname",
        accountbalance: Money.new(:EUR, 120),
        accountclass_id: accountclass.id,
        accountgroup_id: accountgroup.id,
        accounttype_id: accounttype.id
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
      account = Sportyweb.Repo.preload(account, [:accountclass, :accountgroup, :accounttype])

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
      account = Sportyweb.Repo.preload(account, [:accountclass, :accountgroup, :accounttype])
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
      account = Sportyweb.Repo.preload(account, [:accountclass, :accountgroup, :accounttype])
      assert %Ecto.Changeset{} = Accounting.change_account(account)
    end
  end

  describe "accountclasses" do
    alias Sportyweb.Accounting.Accountclass

    import Sportyweb.AccountingFixtures

    @invalid_attrs %{accountclassnumber: nil, accountclassname: nil}

    test "list_accountclasses/0 returns all accountclasses" do
      accountclass = accountclass_fixture()
      assert Accounting.list_accountclasses() == [accountclass]
    end

    test "get_accountclass!/1 returns the accountclass with given id" do
      accountclass = accountclass_fixture()
      assert Accounting.get_accountclass!(accountclass.id) == accountclass
    end

    test "create_accountclass/1 with valid data creates a accountclass" do
      valid_attrs = %{accountclassnumber: "0", accountclassname: "some accountclassname"}

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

    @invalid_attrs %{accountgroupname: nil}

    test "list_accountgroups/0 returns all accountgroups" do
      accountgroup = accountgroup_fixture()
      assert Accounting.list_accountgroups() == [accountgroup]
    end

    test "get_accountgroup!/1 returns the accountgroup with given id" do
      accountgroup = accountgroup_fixture()
      assert Accounting.get_accountgroup!(accountgroup.id) == accountgroup
    end

    test "create_accountgroup/1 with valid data creates a accountgroup" do
      accountclass = accountclass_fixture()
      accounttype = accounttype_fixture()

      valid_attrs = %{
        accountgroupname: "some accountgroupname",
        accountclass_id: accountclass.id,
        accounttype_id: accounttype.id
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

  describe "accounttypes" do
    alias Sportyweb.Accounting.Accounttype

    import Sportyweb.AccountingFixtures

    @invalid_attrs %{accounttypename: nil}

    test "list_accounttypes/0 returns all accounttypes" do
      accounttype = accounttype_fixture()
      assert Accounting.list_accounttypes() == [accounttype]
    end

    test "get_accounttype!/1 returns the accounttype with given id" do
      accounttype = accounttype_fixture()
      assert Accounting.get_accounttype!(accounttype.id) == accounttype
    end

    test "create_accounttype/1 with valid data creates a accounttype" do
      valid_attrs = %{accounttypename: "some accounttypename", accounttypecode: "ABK"}

      assert {:ok, %Accounttype{} = accounttype} = Accounting.create_accounttype(valid_attrs)
      assert accounttype.accounttypename == "some accounttypename"
    end

    test "create_accounttype/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounting.create_accounttype(@invalid_attrs)
    end

    test "update_accounttype/2 with valid data updates the accounttype" do
      accounttype = accounttype_fixture()
      update_attrs = %{accounttypename: "some updated accounttypename", accounttypecode: "PBK"}

      assert {:ok, %Accounttype{} = accounttype} =
               Accounting.update_accounttype(accounttype, update_attrs)

      assert accounttype.accounttypename == "some updated accounttypename"
    end

    test "update_accounttype/2 with invalid data returns error changeset" do
      accounttype = accounttype_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Accounting.update_accounttype(accounttype, @invalid_attrs)

      assert accounttype == Accounting.get_accounttype!(accounttype.id)
    end

    test "delete_accounttype/1 deletes the accounttype" do
      accounttype = accounttype_fixture()
      assert {:ok, %Accounttype{}} = Accounting.delete_accounttype(accounttype)
      assert_raise Ecto.NoResultsError, fn -> Accounting.get_accounttype!(accounttype.id) end
    end

    test "change_accounttype/1 returns a accounttype changeset" do
      accounttype = accounttype_fixture()
      assert %Ecto.Changeset{} = Accounting.change_accounttype(accounttype)
    end
  end
end
