defmodule Sportyweb.Repo.Migrations.CreateAccounttypes do
  use Ecto.Migration

  def change do
    create table(:accounttypes, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :accounttypename, :string, null: false
      add :accounttypecode, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:accounttypes, [:accounttypename])
  end
end
