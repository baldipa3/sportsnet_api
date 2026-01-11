defmodule SportsnetApiWeb.Resolvers.SocialResolver do
  @moduledoc """
  Resolvers for Social-related GraphQL queries and mutations.
  """

  alias SportsnetApi.Geography
  alias SportsnetApi.Social
  alias SportsnetApi.Sports
  alias SportsnetApi.Repo
  alias SportsnetApiWeb.Helpers.FeedId

  import Absinthe.Relay.Node
  import SportsnetApi.Helpers.ErrorHelpers
  import Ecto.Query

  # ==========================================================================
  # Posts
  # ==========================================================================

  def create_post(_parent, args, %{context: %{current_user: current_user}}) do
    files = Map.get(args, :media, [])

    with {:ok, %{type: :sport, id: sport_id_str}} <- from_global_id(args.sport_id, SportsnetApiWeb.Schema),
         {:ok, %{type: :city, id: city_id_str}} <- from_global_id(args.city_id, SportsnetApiWeb.Schema),
         city_id <- String.to_integer(city_id_str),
         sport_id <- String.to_integer(sport_id_str) do
      attrs =
        Map.merge(args, %{
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

  def edit_post(_parent, args, %{context: %{current_user: current_user, ip_address: ip_address}}) do
    with {:ok, %{type: :post, id: post_id_str}} <- from_global_id(args.id, SportsnetApiWeb.Schema),
         post_id <- String.to_integer(post_id_str) do
      Social.edit_post(post_id, args.caption, current_user, ip_address)
    end
  end

  def delete_post(_parent, args, %{context: %{current_user: current_user}}) do
    with {:ok, %{type: :post, id: post_id_str}} <- from_global_id(args.id, SportsnetApiWeb.Schema),
         post_id <- String.to_integer(post_id_str) do
      Social.delete_post(post_id, current_user)
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

  # ==========================================================================
  # Comments
  # ==========================================================================

  def create_comment(_parent, args, %{context: %{current_user: current_user}}) do
    with {:ok, %{type: :post, id: post_id_str}} <- from_global_id(args.post_id, SportsnetApiWeb.Schema),
         post_id <- String.to_integer(post_id_str),
         {parent_id, parent_type} <- resolve_parent_params(args),
         :ok <- (if parent_type == :comment, do: validate_reply_depth(parent_id), else: :ok) do
      attrs = %{
        content: args.content,
        user_id: current_user.id,
        post_id: post_id,
        parent_comment_id: (if parent_type == :comment, do: parent_id, else: nil)
      }

      case Social.create_comment(attrs) do
        {:ok, comment} ->
          comment = Repo.preload(comment, [:user])
          parent_node = fetch_parent_node(parent_type, parent_id, post_id)

          edge = %{
            node: comment,
            cursor: Base.encode64("comment:#{comment.id}")
          }

          {:ok, %{comment_edge: edge, parent: parent_node}}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:error, format_changeset_errors(changeset)}

        {:error, reason} ->
          {:error, reason}
      end
    else
      {:error, :max_depth_exceeded} ->
        {:error, "Replies cannot be nested more than one level deep"}

      {:error, _} ->
        {:error, "Invalid ID provided"}
    end
  end

  def comments_connection(post, args, _resolution) do
    query =
      from(c in SportsnetApi.Social.Comment,
        where: c.post_id == ^post.id,
        where: is_nil(c.parent_comment_id),
        where: is_nil(c.deleted_at),
        order_by: [desc: c.inserted_at],
        preload: [:user]
      )

    Absinthe.Relay.Connection.from_query(query, &SportsnetApi.Repo.all/1, args)
  end

  def replies_connection(comment, args, _resolution) do
    query =
      from(c in SportsnetApi.Social.Comment,
        where: c.parent_comment_id == ^comment.id,
        where: is_nil(c.deleted_at),
        order_by: [desc: c.inserted_at],
        preload: [:user]
      )

    Absinthe.Relay.Connection.from_query(query, &SportsnetApi.Repo.all/1, args)
  end

  # ==========================================================================
  # Likes & Feeds
  # ==========================================================================

  def like_post(_parent, args, %{context: %{current_user: current_user}}) do
    with {:ok, %{type: :post, id: post_id_str}} <- from_global_id(args.id, SportsnetApiWeb.Schema),
         post_id <- String.to_integer(post_id_str) do
      result =
        Social.like_post(%{
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

  def build_sport_city_feed(_parent, args, _resolution) do
    with {:ok, sport} <- Sports.get_sport_by_slug(args.sport_slug),
         {:ok, city} <- Geography.get_city_by_slug(args.city_slug) do
      virtual_id = FeedId.encode_feed_id(sport.id, city.id)
      {:ok, %{id: virtual_id, sport: sport, city: city}}
    end
  end

  # ==========================================================================
  # Private Helpers
  # ==========================================================================

  defp resolve_parent_params(%{parent_comment_id: pc_id}) when not is_nil(pc_id) do
    case from_global_id(pc_id, SportsnetApiWeb.Schema) do
      {:ok, %{type: :comment, id: id_str}} -> {String.to_integer(id_str), :comment}
      _ -> {nil, :error}
    end
  end

  defp resolve_parent_params(%{post_id: p_id}) do
    case from_global_id(p_id, SportsnetApiWeb.Schema) do
      {:ok, %{type: :post, id: id_str}} -> {String.to_integer(id_str), :post}
      _ -> {nil, :error}
    end
  end

  defp fetch_parent_node(:comment, id, _), do: Social.get_comment(id)
  defp fetch_parent_node(:post, id, _), do: Social.get_post(id)

  defp validate_reply_depth(parent_comment_id) do
    parent_comment = Repo.get!(Social.Comment, parent_comment_id)

    if is_nil(parent_comment.parent_comment_id) do
      :ok
    else
      {:error, :max_depth_exceeded}
    end
  end
end
