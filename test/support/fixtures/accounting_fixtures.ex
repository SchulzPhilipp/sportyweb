defmodule Sportyweb.AccountingFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Sportyweb.Accounting` context.
  """

  import Sportyweb.LegalFixtures

  @doc """
  Generate a transaction.
  """
  def transaction_fixture(attrs \\ %{}) do
    contract = contract_fixture()

    {:ok, transaction} =
      attrs
      |> Enum.into(%{
        contract_id: contract.id,
        name: "some name",
        amount: Money.new(:EUR, 42),
        creation_date: ~D[2023-06-01],
        payment_date: ~D[2023-06-15]
      })
      |> Sportyweb.Accounting.create_transaction()

    transaction
  end

  @doc """
  Generate a accountclass.
  """
  def accountclass_fixture(attrs \\ %{}) do
    {:ok, accountclass} =
      attrs
      |> Enum.into(%{
        accountclassname: "some accountclassname",
        accountclassnumber: "0"
      })
      |> Sportyweb.Accounting.create_accountclass()

    accountclass
  end

  @doc """
  Generate a accountgroup.
  """
  def accountgroup_fixture(attrs \\ %{}) do
    {:ok, accountgroup} =
      attrs
      |> Enum.into(%{
        accountgroupname: "some accountgroupname",
        accountgroupnumber: "08"
      })
      |> Sportyweb.Accounting.create_accountgroup()

    accountgroup
  end

  @doc """
  Generate a accounttype.
  """
  def accounttype_fixture(attrs \\ %{}) do
    {:ok, accounttype} =
      attrs
      |> Enum.into(%{
        accounttypename: "some accounttypename"
      })
      |> Sportyweb.Accounting.create_accounttype()

    accounttype
  end

  @doc """
  Generate a account.
  """
  def account_fixture(attrs \\ %{}) do
    accountclass = accountclass_fixture()
    accountgroup = accountgroup_fixture()
    accounttype = accounttype_fixture()

    {:ok, account} =
      attrs
      |> Enum.into(%{
        accountclass_id: accountclass.id,
        accountgroup_id: accountgroup.id,
        accounttype_id: accounttype.id,
        accountbalance: Money.new(:EUR, 120),
        accountname: "some accountname",
        accountnumber: "0815"
      })
      |> Sportyweb.Accounting.create_account()

    account
  end

end
