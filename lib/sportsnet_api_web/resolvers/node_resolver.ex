defmodule SportsnetApiWeb.Resolvers.NodeResolver do
  alias SportsnetApi.Repo
  alias SportsnetApi.Geography.{Country, City}
  alias SportsnetApi.Sports.Sport
  alias SportsnetApi.Accounts.User
  alias SportsnetApi.Social.{Media, Post}
  alias SportsnetApiWeb.Helpers.FeedId

  def resolve_node(%{type: :country, id: id}, _resolution) do
    {:ok, Repo.get(Country, id)}
  end

  def resolve_node(%{type: :city, id: id}, _resolution) do
    {:ok, Repo.get(City, id)}
  end

  def resolve_node(%{type: :sport, id: id}, _resolution) do
    {:ok, Repo.get(Sport, id)}
  end

  def resolve_node(%{type: :user, id: id}, _resolution) do
    {:ok, Repo.get(User, id)}
  end

  def resolve_node(%{type: :media, id: id}, _resolution) do
    {:ok, Repo.get(Media, id)}
  end

  def resolve_node(%{type: :post, id: id}, _resolution) do
    post = Post |> Repo.get(id) |> Repo.preload([:media, :comments])
    {:ok, post}
  end

  def resolve_node(%{type: :sport_city_feed, id: id}, _resolution) do
    case FeedId.decode_feed_id(id) do
      {:ok, {sport_id, city_id}} ->
        with sport when not is_nil(sport) <- Repo.get(Sport, sport_id),
             city when not is_nil(city) <- Repo.get(City, city_id) do
          {:ok, %{id: id, sport: sport, city: city}}
        else
          _ -> {:error, "Sport or City not found"}
        end
      {:error, _} ->
        {:error, "Invalid feed ID"}
    end
  end

  def resolve_node(_node, _resolution) do
    {:error, "Unknown node type"}
  end
end
