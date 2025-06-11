defmodule SportsnetApi.Repo.Migrations.CreateSports do
  use Ecto.Migration

  def change do
    create table(:sports) do
      add :name, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:sports, [:name])
  end
end
