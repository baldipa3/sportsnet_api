defmodule SportsnetApi.Repo.Migrations.CreatePostEdits do
  use Ecto.Migration

  def change do
    create table(:post_edits) do
      add :old_caption, :text, null: false
      add :new_caption, :text, null: false
      add :ip_address, :string, null: false

      add :user_id, references(:users, on_delete: :restrict), null: false
      add :post_id, references(:posts, on_delete: :restrict), null: false

      timestamps(type: :utc_datetime, updated_at: false, deleted_at: false)
    end
  end
end
