defmodule Sportyweb.Repo.Migrations.CreateAccountclasses do
  use Ecto.Migration

  def change do
    create table(:accountclasses, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :accountclassnumber, :string, null: false
      add :accountclassname, :string, null: false

      timestamps(type: :utc_datetime)
    end
  end
end
