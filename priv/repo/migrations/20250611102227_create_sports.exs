defmodule SportsnetApi.Repo.Migrations.CreateSports do
  use Ecto.Migration

  def change do
    create table(:sports) do
      add :name, :string, null: false
      add :code, :string, null: false

      timestamps(code: :utc_datetime)
    end

    create unique_index(:sports, [:name])
    create unique_index(:sports, [:code])
  end
end
