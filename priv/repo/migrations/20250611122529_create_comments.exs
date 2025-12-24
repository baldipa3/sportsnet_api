defmodule SportsnetApi.Repo.Migrations.CreateComments do
  use Ecto.Migration

  def change do
    create table(:comments) do
      add :content, :text, null: false
      add :post_id, references(:posts, on_delete: :restrict), null: false
      add :user_id, references(:users, on_delete: :restrict), null: false
      add :deleted_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:comments, [:post_id])
    create index(:comments, [:user_id])
  end
end
