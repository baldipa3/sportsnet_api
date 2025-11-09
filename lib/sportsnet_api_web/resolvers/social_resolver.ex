defmodule SportsnetApiWeb.Resolvers.SocialResolver do
  alias SportsnetApi.Geography
  alias SportsnetApi.Social
  alias SportsnetApi.Sports

  import Absinthe.Relay.Node
  import SportsnetApi.Helpers.ErrorHelpers

  def create_post(_parent, args, %{context: %{current_user: current_user}}) do
    files = Map.get(args, :media, [])

    with  {:ok, %{type: :sport, id: sport_id_str}} <- from_global_id(args.sport_id, SportsnetApiWeb.Schema),
          {:ok, %{type: :city, id: city_id_str}} <- from_global_id(args.city_id, SportsnetApiWeb.Schema),
          city_id <- String.to_integer(city_id_str),
          sport_id <- String.to_integer(sport_id_str) do

      attrs = Map.merge(args, %{
        user_id: current_user.id,
        city_id: city_id,
        sport_id: sport_id
      })

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

  def posts_by_city_and_sport(_parent, args, _resolution) do
    with {:ok, sport} <- Sports.get_sport_by_slug(args.sport_slug),
         {:ok, city} <- Geography.get_city_by_slug(args.city_slug) do
      posts = Social.fetch_posts_by_city_and_sport(args.city_slug, args.sport_slug)
      {:ok, %{sport: sport, city: city, posts: posts}}
    end
  end

  def like_post(_parent, args,  %{context: %{current_user: current_user}}) do
    manage_post_likes(args, current_user, :like)
  end

  def unlike_post(_parent, args, %{context: %{current_user: current_user}}) do
    manage_post_likes(args, current_user, :unlike)
  end

  defp manage_post_likes(args, current_user, like_type) do
    with  {:ok, %{type: :post, id: post_id_str}} <- from_global_id(args.post_id, SportsnetApiWeb.Schema),
          post_id <- String.to_integer(post_id_str) do

      result = case like_type do
        :like -> Social.like_post(%{user_id: current_user.id, post_id: post_id})
        :unlike -> Social.unlike_post(current_user.id, post_id)
      end

      case result do
        {:ok, _like} -> {:ok, %{
          post_id: args.post_id,
          likes_count: Social.get_like_count(post_id)
        }}
        {:error, changeset} -> {:error, changeset}
      end
    end
  end
end
