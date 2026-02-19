defmodule Sportyweb.Repo.Migrations.CreateAccountgroups do
  use Ecto.Migration

  def change do
    create table(:accountgroups, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :accountgroupname, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:accountgroups, [:accountgroupname])
  end
end
