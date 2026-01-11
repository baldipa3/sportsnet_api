defmodule SportsnetApi.Repo.Migrations.CreateLikes do
  use Ecto.Migration

  def change do
    create table(:likes) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :post_id, references(:posts, on_delete: :delete_all), null: true
      add :comment_id, references(:comments, on_delete: :delete_all), null: true

      timestamps(type: :utc_datetime)
    end

    create index(:likes, [:post_id])
    create index(:likes, [:comment_id])
    create index(:likes, [:user_id])
    create unique_index(:likes, [:user_id, :post_id],
      name: :likes_user_post_unique_index,
      where: "post_id IS NOT NULL")
    create unique_index(:likes, [:user_id, :comment_id],
      name: :likes_user_comment_unique_index,
      where: "comment_id IS NOT NULL")
  end
end
