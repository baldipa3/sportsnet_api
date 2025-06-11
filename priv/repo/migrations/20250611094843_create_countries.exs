defmodule SportsnetApi.Repo.Migrations.CreateCountries do
  use Ecto.Migration

  def change do
    create table(:countries) do
      add :name, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:countries, [:name])
  end
end
