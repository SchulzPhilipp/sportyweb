defmodule Sportyweb.Accounting.Accounttype do
  use Ecto.Schema
  import Ecto.Changeset

  alias Sportyweb.Accounting.Account

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "accounttypes" do
    has_many(:accounts, Account)

    field :accounttypename, :string
    field :accounttypecode, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(accounttype, attrs) do
    accounttype
    |> cast(attrs, [:accounttypename, :accounttypecode])
    |> validate_required([:accounttypename])
  end
end
