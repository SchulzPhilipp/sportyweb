defmodule Sportyweb.Accounting.Accountgroup do
  use Ecto.Schema
  import Ecto.Changeset

  alias Sportyweb.Accounting.Account

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "accountgroups" do
    has_many(:accounts, Account)

    field :accountgroupname, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(accountgroup, attrs) do
    accountgroup
    |> cast(attrs, [:accountgroupname])
    |> validate_required([:accountgroupname])
    |> unique_constraint(:accountgroupname)
  end
end
