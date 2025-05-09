defmodule SportsnetApi.Repo do
  use Ecto.Repo,
    otp_app: :sportsnet_api,
    adapter: Ecto.Adapters.Postgres
end
