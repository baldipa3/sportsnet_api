defmodule SportsnetApi.Repo.Migrations.CreatePosts do
  use Ecto.Migration

  def change do
    create table(:posts) do
      add :caption, :text, null: false
      add :user_id, references(:users, on_delete: :restrict), null: false
      add :sport_id, references(:sports, on_delete: :restrict), null: false
      add :city_id, references(:cities, on_delete: :restrict), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:posts, [:user_id])
    create index(:posts, [:sport_id, :city_id])
  end
end
