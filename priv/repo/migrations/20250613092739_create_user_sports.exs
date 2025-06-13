defmodule SportsnetApi.Repo.Migrations.CreateUserSports do
  use Ecto.Migration

  def change do
    create table("user_sports") do
      add :sport_id, references(:sports, on_delete: :delete_all)
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:user_sports, [:user_id, :sport_id])
    create index(:user_sports, [:sport_id])
  end
end
