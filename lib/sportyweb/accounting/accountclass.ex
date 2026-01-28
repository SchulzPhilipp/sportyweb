defmodule Sportyweb.Accounting.Accountclass do
  use Ecto.Schema
  import Ecto.Changeset

  alias Sportyweb.Accounting.Account

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "accountclasses" do
    has_many(:accounts, Account)

    field :accountclassnumber, :string
    field :accountclassname, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(accountclass, attrs) do
    accountclass
    |> cast(attrs, [:accountclassnumber, :accountclassname])
    |> validate_required([:accountclassnumber, :accountclassname])
  end
end
