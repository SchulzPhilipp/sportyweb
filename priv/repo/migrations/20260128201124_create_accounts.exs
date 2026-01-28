defmodule Sportyweb.Repo.Migrations.CreateAccounts do
  use Ecto.Migration

  def change do
    create table(:accounts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :accountnumber, :string, null: false
      add :accountname, :string, null: false
      add :accountbalance, :money_with_currency

      add :accountclass_id, references(:accountclasses, on_delete: :restrict, type: :binary_id), null: false
      add :accountgroup_id, references(:accountgroups, on_delete: :restrict, type: :binary_id), null: false
      add :accounttype_id, references(:accounttypes, on_delete: :restrict, type: :binary_id), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:accounts, [:accountclass_id])
    create index(:accounts, [:accountgroup_id])
    create index(:accounts, [:accounttype_id])

  end
end
