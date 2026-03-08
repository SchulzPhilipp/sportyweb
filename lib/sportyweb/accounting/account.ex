defmodule Sportyweb.Accounting.Account do
  use Ecto.Schema
  import Ecto.Changeset
  import SportywebWeb.CommonValidations

  alias Sportyweb.Organization.Club
  alias Sportyweb.Accounting.Accountclass
  alias Sportyweb.Accounting.Accountgroup
  alias Sportyweb.Accounting.Accounttype

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "accounts" do
    belongs_to(:club, Club)
    belongs_to(:accountclass, Accountclass)
    belongs_to(:accountgroup, Accountgroup)

    field :accountnumber, :string
    field :accountname, :string
    field :accountbalance, Money.Ecto.Composite.Type, default_currency: :EUR

    field :accounttypecode, Ecto.Enum,
      values: [:aktiv, :passiv, :aufwand, :ertrag, :neutral]

    timestamps(type: :utc_datetime)
  end

  def accounttypecode_labels do
  %{
    aktiv:   "Aktivkonto",
    passiv:  "Passivkonto",
    aufwand: "Aufwandskonto",
    ertrag:  "Ertragskonto",
    neutral: "Neutralkonto"
  }
  end

  def accounttypecode_options do
    Enum.map(accounttypecode_labels(), fn {k, v} -> {v, k} end)
  end

  @doc false
  def changeset(account, attrs) do
    account
    |> cast(attrs, [
      :club_id,
      :accountclass_id,
      :accountgroup_id,
      :accountnumber,
      :accountname,
      :accounttypecode,
      :accountbalance
    ])
    |> validate_required([
      :club_id,
      :accountclass_id,
      :accountgroup_id,
      :accountnumber,
      :accountname,
      :accounttypecode,
      :accountbalance
    ])
    |> validate_length(:accountnumber, max: 8)
    |> validate_length(:accountname, max: 250)
    |> unique_constraint(:accountnumber, name: :accounts_club_id_accountnumber_index)
    |> check_constraint(:accounttypecode, name: :accounttypecode_valid_values)
  end
end
