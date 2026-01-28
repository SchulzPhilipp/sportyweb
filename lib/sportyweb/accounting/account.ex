defmodule Sportyweb.Accounting.Account do
  use Ecto.Schema
  import Ecto.Changeset
  import SportywebWeb.CommonValidations

  alias Sportyweb.Accounting.Accountclass
  alias Sportyweb.Accounting.Accountgroup
  alias Sportyweb.Accounting.Accounttype

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "accounts" do
    belongs_to(:accountclass, Accountclass)
    belongs_to(:accountgroup, Accountgroup)
    belongs_to(:accounttype, Accounttype)

    field :accountnumber, :string
    field :accountname, :string
    field :accountbalance, Money.Ecto.Composite.Type, default_currency: :EUR

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(account, attrs) do
    account
    |> cast(attrs, [:accountclass_id, :accountgroup_id, :accounttype_id, :accountnumber, :accountname, :accountbalance])
    |> validate_required([:accountnumber, :accountname, :accountbalance])
    |> validate_length(:accountnumber, max: 8)
    |> validate_length(:accountname, max: 250)
    |> validate_currency(:accountbalance, :EUR)
  end
end
