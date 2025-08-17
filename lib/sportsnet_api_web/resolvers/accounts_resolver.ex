defmodule SportsnetApiWeb.Resolvers.AccountsResolver do
  alias SportsnetApi.Accounts

  import SportsnetApi.Helpers.ErrorHelpers

  def complete_user_onboarding(
        _parent,
        %{city_id: city_id, default_sport_id: default_sport_id},
        %{context: %{current_user: current_user}}
      ) do
    case Accounts.complete_user_onboarding(current_user, city_id, default_sport_id) do
      {:ok, user} ->
        {:ok, user}
      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, format_changeset_errors(changeset)}
    end
  end
end
