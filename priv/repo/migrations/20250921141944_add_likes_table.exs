defmodule SportsnetApi.Repo.Migrations.AddLikesTable do
  use Ecto.Migration

  def change do
    create table(:likes) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :post_id, references(:posts, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:likes, [:user_id, :post_id], name: :likes_user_post_unique_index)
    create index(:likes, [:post_id])
    create index(:likes, [:user_id])
  end
end
