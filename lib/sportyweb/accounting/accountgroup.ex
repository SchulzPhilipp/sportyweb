defmodule Sportyweb.Accounting.Accountgroup do
  use Ecto.Schema
  import Ecto.Changeset

  alias Sportyweb.Accounting.Account
  alias Sportyweb.Organization.Club

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "accountgroups" do
    has_many(:accounts, Account)
    belongs_to(:club, Club)

    field :accountgroupname, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(accountgroup, attrs) do
    accountgroup
    |> cast(attrs, [:club_id, :accountgroupname])
    |> validate_required([:club_id, :accountgroupname])
    |> unique_constraint(:club_id, name: :accountgroups_club_id_accountgroupname_index)
  end
end
