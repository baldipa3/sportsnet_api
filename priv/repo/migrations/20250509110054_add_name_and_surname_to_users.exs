defmodule SportsnetApi.Repo.Migrations.AddNameAndSurnameToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :name, :string
      add :surname, :string
    end
  end
end
