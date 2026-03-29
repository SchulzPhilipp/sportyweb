defmodule Sportyweb.Repo.Migrations.CreateAccountingtransactions do
  use Ecto.Migration

  def change do
    create table(:accounting_transactions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :description, :string, null: false
      add :voucher_number, :string, null: false
      add :reference, :string, null: true
      add :posted_at, :utc_datetime, null: true
      add :deleted_at, :utc_datetime, null: true
      add :status, :string, null: false, default: "draft"
      add :sphere, :string, null: false, default: "ideal"
      add :club_id, references(:clubs, on_delete: :delete_all, type: :binary_id), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:accounting_transactions, [:club_id])
    create unique_index(:accounting_transactions, [:club_id, :voucher_number])
  end
end
