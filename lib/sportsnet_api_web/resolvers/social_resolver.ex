defmodule SportsnetApiWeb.Resolvers.SocialResolver do
  alias SportsnetApi.Social

  import Absinthe.Relay.Node
  import SportsnetApi.Helpers.ErrorHelpers

  @spec create_post(
          any(),
          %{optional(:user_id) => nil | binary(), optional(any()) => any()},
          any()
        ) ::
          {:error, binary() | list()}
          | {:ok, SportsnetApi.Social.Post | nil | %{id: binary(), type: atom()}}
  def create_post(_parent, args, _resolution) do
    files = Map.get(args, :media, [])

    with  {:ok, %{type: :user, id: user_id_str}} <- from_global_id(args.user_id, SportsnetApiWeb.Schema),
          {:ok, %{type: :sport, id: sport_id_str}} <- from_global_id(args.sport_id, SportsnetApiWeb.Schema),
          {:ok, %{type: :city, id: city_id_str}} <- from_global_id(args.city_id, SportsnetApiWeb.Schema),
          user_id <- String.to_integer(user_id_str),
          city_id <- String.to_integer(city_id_str),
          sport_id <- String.to_integer(sport_id_str) do

      attrs = %{ args | user_id: user_id, city_id: city_id, sport_id: sport_id}

      case Social.create_post(attrs, files) do
        {:ok, post} ->
          {:ok, post}
        {:error, %Ecto.Changeset{} = changeset} ->
          {:error, format_changeset_errors(changeset)}
        {:error, reason} ->
          {:error, reason}
        end
    end
  end
end
