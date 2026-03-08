defmodule Sportyweb.Repo.Migrations.CreateAccountclasses do
  use Ecto.Migration

  def change do
    create table(:accountclasses, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :accountclassnumber, :string, null: false
      add :accountclassname, :string, null: false

      add :club_id, references(:clubs, on_delete: :delete_all, type: :binary_id), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:accountclasses, [:club_id, :accountclassnumber, :accountclassname])
  end
end
