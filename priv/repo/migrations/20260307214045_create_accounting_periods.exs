defmodule Sportyweb.Repo.Migrations.CreateAccountingPeriods do
  use Ecto.Migration

  def change do
    create table(:accounting_periods, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :starts_on, :date, null: false
      add :ends_on, :date, null: false
      add :transaction_counter, :integer, null: false, default: 0
      add :status, :string, null: false, default: "open"
      add :club_id, references(:clubs, on_delete: :delete_all, type: :binary_id), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:accounting_periods, [:club_id])
    create unique_index(:accounting_periods, [:club_id, :name])
  end
end
