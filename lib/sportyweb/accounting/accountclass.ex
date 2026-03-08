defmodule Sportyweb.Accounting.Accountclass do
  use Ecto.Schema
  import Ecto.Changeset

  alias Sportyweb.Accounting.Account
  alias Sportyweb.Organization.Club

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "accountclasses" do
    has_many(:accounts, Account)
    belongs_to(:club, Club)

    field :accountclassnumber, :string
    field :accountclassname, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(accountclass, attrs) do
    accountclass
    |> cast(attrs, [:club_id, :accountclassnumber, :accountclassname])
    |> validate_required([:club_id, :accountclassnumber, :accountclassname])
    |> unique_constraint(:club_id, name: :accountclasses_club_id_accountclassnumber_accountclassname_index)
  end
end
