defmodule Sportyweb.Repo.Migrations.CreateAccountingtransactions do
  use Ecto.Migration

  def change do
    create table(:accounting_transactions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :description, :string, null: false
      add :transaction_number, :string, null: false
      add :document_date, :date, null: false
      add :reference, :string, null: true
      add :posted_at, :utc_datetime, null: true
      add :deleted_at, :utc_datetime, null: true
      add :status, :string, null: false, default: "draft"
      add :sphere, :string, null: false, default: "ideal"
      add :club_id, references(:clubs, on_delete: :delete_all, type: :binary_id), null: false
      add :accounting_period_id, references(:accounting_periods, on_delete: :restrict, type: :binary_id), null: true # null: true temporär für bestehende Transaktionen

      timestamps(type: :utc_datetime)
    end

    create index(:accounting_transactions, [:club_id])
    create unique_index(:accounting_transactions, [:club_id, :transaction_number])
  end
end
