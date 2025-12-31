defmodule SportsnetApiWeb.Resolvers.SocialResolver do
  alias SportsnetApi.Geography
  alias SportsnetApi.Social
  alias SportsnetApi.Sports
  alias SportsnetApi.Repo
  alias SportsnetApiWeb.Helpers.FeedId

  import Absinthe.Relay.Node
  import SportsnetApi.Helpers.ErrorHelpers
  import Ecto.Query

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
          post = Repo.preload(post, [:media, :comments, :user, :sport, :city])

          edge = %{
            node: post,
            cursor: Base.encode64("post:#{post.id}")
          }

          {:ok, %{post_edge: edge}}

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
      # Create a virtual ID from sport and city IDs
      virtual_id = FeedId.encode_feed_id(sport.id, city.id)

      {:ok, %{id: virtual_id, sport: sport, city: city}}
    end
  end

  def like_post(_parent, args,  %{context: %{current_user: current_user}}) do
    with  {:ok, %{type: :post, id: post_id_str}} <- from_global_id(args.id, SportsnetApiWeb.Schema),
          post_id <- String.to_integer(post_id_str) do

      result = Social.like_post(%{
        user_id: current_user.id,
        post_id: post_id,
        does_like: args.does_like
      })

      case result do
        {:ok, _like} ->
          case Social.get_post(post_id) do
            {:ok, post} -> {:ok, %{post: post}}
            {:error, _reason} -> {:error, "Post not found"}
          end
        {:error, changeset} ->
          {:error, changeset}
      end
    end
  end

  def posts_connection(%{sport: sport, city: city}, args, _resolution) do
    query =
      from(p in SportsnetApi.Social.Post,
        where: p.sport_id == ^sport.id and p.city_id == ^city.id,
        where: is_nil(p.deleted_at),
        order_by: [desc: p.inserted_at],
        preload: [:media, :comments, :user, :sport, :city]
      )

    Absinthe.Relay.Connection.from_query(query, &SportsnetApi.Repo.all/1, args)
  end

  def delete_post(_parent, args, %{context: %{current_user: current_user}}) do
    with {:ok, %{type: :post, id: post_id_str}} <- from_global_id(args.id, SportsnetApiWeb.Schema),
        post_id <- String.to_integer(post_id_str) do
      Social.delete_post(post_id, current_user)
    end
  end

  def edit_post(_parent, args, %{context: %{current_user: current_user, ip_address: ip_address}}) do
    with {:ok, %{type: :post, id: post_id_str}} <- from_global_id(args.id, SportsnetApiWeb.Schema),
        post_id <- String.to_integer(post_id_str) do
      Social.edit_post(post_id, args.caption, current_user, ip_address)
    end
  end
end
