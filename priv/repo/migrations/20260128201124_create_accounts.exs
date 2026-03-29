defmodule Sportyweb.Repo.Migrations.CreateAccounts do
  use Ecto.Migration

  def change do
    create table(:accounts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :accountnumber, :string, null: false
      add :accountname, :string, null: false
      add :accountbalance, :money_with_currency, null: false

      add :accounttypecode, :string, null: false, default: "neutral"

      add :club_id, references(:clubs, on_delete: :delete_all, type: :binary_id), null: false
      add :accountclass_id, references(:accountclasses, on_delete: :restrict, type: :binary_id),
        null: false

      add :accountgroup_id, references(:accountgroups, on_delete: :restrict, type: :binary_id),
        null: false

      timestamps(type: :utc_datetime)
    end

    create index(:accounts, [:club_id])
    create index(:accounts, [:accountclass_id])
    create index(:accounts, [:accountgroup_id])

    create unique_index(:accounts, [:club_id, :accountnumber])

    create constraint(:accounts, "accounttypecode_valid_values",
      check: "accounttypecode IN ('aktiv', 'passiv', 'aufwand', 'ertrag', 'neutral')"
    )
  end
end
