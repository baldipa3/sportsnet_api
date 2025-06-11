defmodule SportsnetApi.Repo.Migrations.AddCityToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :city_id, references(:cities, on_delete: :restrict)
    end

    create index(:users, [:city_id])
  end
end
