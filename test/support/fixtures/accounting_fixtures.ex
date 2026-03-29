defmodule Sportyweb.AccountingFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Sportyweb.Accounting` context.
  """

  import Sportyweb.LegalFixtures
  import Sportyweb.OrganizationFixtures

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
    club = club_fixture()

    # Zuerst schauen wir nach, ob diese Klasse schon da ist
    case Sportyweb.Repo.get_by(Sportyweb.Accounting.Accountclass, club_id: club.id, accountclassnumber: number) do
      nil ->
        # Nur wenn sie fehlt, legen wir sie neu an
        {:ok, accountclass} =
          attrs
          |> Enum.into(%{
            accountclassnumber: number,
            accountclassname: "Default Class",
            club_id: club.id
          })
          |> Sportyweb.Accounting.create_accountclass()

        accountclass

      existing ->
        # Wenn sie existiert, geben wir sie einfach zurück
        existing
    end

  end

  @doc """
  Generate a accountgroup.
  """
  def accountgroup_fixture(attrs \\ %{}) do
    name = attrs[:accountgroupname] || "Standard Gruppe"
    club = club_fixture()

    case Repo.get_by(Sportyweb.Accounting.Accountgroup, club_id: club.id, accountgroupname: name) do
      nil ->

        {:ok, accountgroup} =
          attrs
          |> Enum.into(%{
            accountgroupname: name,
            club_id: club.id
          })
          |> Sportyweb.Accounting.create_accountgroup()

        accountgroup

      existing ->
        existing
    end

  end

  @doc """
  Generate a account.
  """
  def account_fixture(attrs \\ %{}) do
    club = club_fixture()
    accountclass = accountclass_fixture(%{club_id: club.id})
    accountgroup = accountgroup_fixture(%{club_id: club.id})

    random_accountnumber = Integer.to_string(:rand.uniform(90_000))

    {:ok, account} =
      attrs
      |> Enum.into(%{
        accountclass_id: accountclass.id,
        accountgroup_id: accountgroup.id,
        accounttypecode: "neutral",
        club_id: club.id,
        accountbalance: Money.new(:EUR, 120),
        accountname: "some accountname",
        accountnumber: random_accountnumber
      })
      |> Sportyweb.Accounting.create_account()

    account
  end

  @doc """
  Generate a entry.
  """
  def entry_fixture(attrs \\ %{}) do
    club = club_fixture()
    account = account_fixture(%{club_id: club.id})
    accounting_transaction = accounting_transaction_fixture(%{club_id: club.id})

    {:ok, entry} =
      attrs
      |> Enum.into(%{
        amount: "120",
        description: "some description",
        club_id: club.id,
        account_id: account.id,
        accounting_transaction_id: accounting_transaction.id
      })
      |> Sportyweb.Accounting.create_entry()

    entry
  end

  @doc """
  Generate a accounting_transaction.
  """
  def accounting_transaction_fixture(attrs \\ %{}) do
    club = club_fixture()

    {:ok, accounting_transaction} =
      attrs
      |> Enum.into(%{
        description: "some description",
        voucher_number: "2099-999",
        posted_at: ~U[2026-03-07 22:11:00Z],
        reference: "some reference",
        status: "draft",
        club_id: club.id
      })
      |> Sportyweb.Accounting.create_accounting_transaction()

    accounting_transaction
  end
end
