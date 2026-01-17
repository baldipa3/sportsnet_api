defmodule SportsnetApi.Repo.Migrations.CreateCommentsEdits do
  use Ecto.Migration

  def change do
    create table(:comment_edits) do
      add :old_content, :text, null: false
      add :new_content, :text, null: false
      add :ip_address, :string, null: false

      add :user_id, references(:users, on_delete: :restrict), null: false
      add :comment_id, references(:comments, on_delete: :restrict), null: false

      timestamps(type: :utc_datetime, updated_at: false, deleted_at: false)
    end
  end
end
