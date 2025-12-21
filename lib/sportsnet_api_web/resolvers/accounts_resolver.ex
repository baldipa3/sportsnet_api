defmodule SportsnetApiWeb.Resolvers.AccountsResolver do
  alias SportsnetApi.Accounts
  alias SportsnetApi.Repo

  import Absinthe.Relay.Node
  import SportsnetApi.Helpers.ErrorHelpers

  def complete_user_onboarding(
        _parent,
        %{city_id: city_id, default_sport_id: default_sport_id},
        %{context: %{current_user: current_user}}
        ) do

    with {:ok, %{type: :city, id: city_id_str}} <- from_global_id(city_id, SportsnetApiWeb.Schema),
         {:ok, %{type: :sport, id: default_sport_id_str}} <- from_global_id(default_sport_id, SportsnetApiWeb.Schema),
         city_id <- String.to_integer(city_id_str),
         default_sport_id <- String.to_integer(default_sport_id_str) do

      case Accounts.complete_user_onboarding(current_user, city_id, default_sport_id) do
        {:ok, user} ->
          {:ok, Repo.preload(user, [:city, :default_sport])}
        {:error, %Ecto.Changeset{} = changeset} ->
          {:error, format_changeset_errors(changeset)}
      end
    end
  end

  def current_user(_parent, _args, %{context: %{current_user: user}}) do
    user = user |> Repo.preload([city: :country, default_sport: []])

    {:ok, user}
  end
end
