defmodule SportsnetApi.Repo.Migrations.AddDefaultSportIdToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :default_sport_id, references(:sports, on_delete: :nilify_all)
    end
  end
end
