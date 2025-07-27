defmodule SportsnetApi.Repo.Migrations.CreateCities do
  use Ecto.Migration

  def change do
    create table(:cities) do
      add :name, :string
      add :country_id, references(:countries, on_delete: :restrict), null: false
      add :slug, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:cities, [:country_id])
    create unique_index(:cities, [:name, :country_id])
    create unique_index(:cities, [:slug])
  end
end
