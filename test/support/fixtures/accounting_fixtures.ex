defmodule Sportyweb.AccountingFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Sportyweb.Accounting` context.
  """

  import Sportyweb.LegalFixtures

  alias Sportyweb.Repo

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
    # Wir nehmen entweder die übergebene Nummer oder einen Standardwert
    number = attrs[:accountclassnumber] || "0"

    # Zuerst schauen wir nach, ob diese Klasse schon da ist
    case Sportyweb.Repo.get_by(Sportyweb.Accounting.Accountclass, accountclassnumber: number) do
      nil ->
        # Nur wenn sie fehlt, legen wir sie neu an
        {:ok, accountclass} =
          attrs
          |> Enum.into(%{
            accountclassnumber: number,
            accountclassname: "Default Class"
          })
          |> Sportyweb.Accounting.create_accountclass()

        accountclass

      existing ->
        # Wenn sie existiert, geben wir sie einfach zurück
        existing
    end

    # {:ok, accountclass} =
    #   attrs
    #   |> Enum.into(%{
    #     accountclassname: "some accountclassname",
    #     accountclassnumber: "0"
    #   })
    #   |> Sportyweb.Accounting.create_accountclass()

    # accountclass
  end

  @doc """
  Generate a accounttype.
  """
  def accounttype_fixture(attrs \\ %{}) do
    # Wir suchen nach dem Code (oder Namen), um Duplikate zu vermeiden
    code = attrs[:accounttypecode] || "ABK"

    case Sportyweb.Repo.get_by(Sportyweb.Accounting.Accounttype, accounttypecode: code) do
      nil ->
        {:ok, accounttype} =
          attrs
          |> Enum.into(%{
            accounttypecode: code,
            accounttypename: "some accounttypename-#{System.unique_integer([:positive])}"
          })
          |> Sportyweb.Accounting.create_accounttype()

        accounttype

      existing ->
        existing
    end

    #   {:ok, accounttype} =
    #     attrs
    #     |> Enum.into(%{
    #       accounttypename: "some accounttypename",
    #       accounttypecode: "ABK"
    #     })
    #     |> Sportyweb.Accounting.create_accounttype()

    #   accounttype
  end

  @doc """
  Generate a accountgroup.
  """
  def accountgroup_fixture(attrs \\ %{}) do
    name = attrs[:accountgroupname] || "Standard Gruppe"

    case Repo.get_by(Sportyweb.Accounting.Accountgroup, accountgroupname: name) do
      nil ->
        accountclass = attrs[:accountclass] || accountclass_fixture()
        accounttype = attrs[:accounttype] || accounttype_fixture()

        {:ok, accountgroup} =
          attrs
          |> Enum.into(%{
            accountgroupname: name,
            accountclass_id: accountclass.id,
            accounttype_id: accounttype.id
          })
          |> Sportyweb.Accounting.create_accountgroup()

        accountgroup

      existing ->
        existing
    end

    #   accountclass = accountclass_fixture()
    #   accounttype = accounttype_fixture()
    # {:ok, accountgroup} =
    #   attrs
    #   |> Enum.into(%{
    #     accountclass_id: accountclass.id,
    #     accounttype_id: accounttype.id,
    #     accountgroupname: "some accountgroupname"
    #   })
    #   |> Sportyweb.Accounting.create_accountgroup()

    # accountgroup
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
