defmodule SportsnetApi.Repo.Migrations.CreateMedia do
  use Ecto.Migration

  def up do
    execute "CREATE TYPE media_type AS ENUM ('image', 'video')"

    create table(:media) do
      add :media_type, :media_type, null: false
      add :url, :string, null: false
      add :position, :integer
      add :post_id, references(:posts, on_delete: :restrict)
      add :file_size, :integer
      add :filename, :string
      add :width, :integer
      add :height, :integer
      add :duration, :integer

      timestamps(type: :utc_datetime)
    end

    create unique_index(:media, [:url, :post_id])
    create index(:media, [:post_id, :position])
  end

  def down do
    drop table(:media)
    execute "DROP TYPE media_type"
  end
end
