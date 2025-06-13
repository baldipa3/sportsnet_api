defmodule SportsnetApi.Repo.Migrations.AddPrimarySportIdToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :primary_sport_id, references(:sports, on_delete: :nilify_all)
    end
  end
end
