defmodule SportsnetApiWeb.Resolvers.SocialResolver do
  alias SportsnetApi.Social

  import Absinthe.Relay.Node
  import SportsnetApi.Helpers.ErrorHelpers

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

  @spec posts_by_city_and_sport(any(), any(), any()) :: {:error, binary()} | {:ok, any()}
  def posts_by_city_and_sport(_parent, args, _resolution) do
    posts = Social.fetch_posts_by_city_and_sport(args.city_slug, args.sport_slug)

    {:ok, posts}
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
