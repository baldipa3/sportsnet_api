defmodule SportsnetApi.UserSports.UserSport do
  use Ecto.Schema

  schema "user_sports" do
    belongs_to :user, SportsnetApi.Accounts.User
    belongs_to :sport, SportsnetApi.Sports.Sport

    timestamps(type: :utc_datetime)
  end
end
