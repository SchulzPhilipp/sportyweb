defmodule Sportyweb.Repo.Migrations.CreateEntries do
  use Ecto.Migration

  def change do
    create table(:entries, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :amount, :money_with_currency, null: false
      add :description, :string, null: true

      add :club_id, references(:clubs, on_delete: :delete_all, type: :binary_id), null: false
      add :account_id, references(:accounts, on_delete: :restrict, type: :binary_id), null: false
      add :accounting_transaction_id, references(:accounting_transactions, on_delete: :delete_all, type: :binary_id), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:entries, [:club_id, :account_id, :accounting_transaction_id])
  end
end
